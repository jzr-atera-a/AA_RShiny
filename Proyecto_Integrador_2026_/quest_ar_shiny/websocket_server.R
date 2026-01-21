# ==============================================================================
# STANDALONE WEBSOCKET SERVER FOR QUEST 3
# ==============================================================================
# Run this FIRST in one R session
# Then run the Shiny app in another R session
# ==============================================================================

library(httpuv)
library(jsonlite)

cat("\n================================================================\n")
cat("Quest 3 WebSocket Server\n")
cat("================================================================\n")

# Global state (shared with Shiny via file or global env)
controller_data <- new.env()
controller_data$connected <- FALSE
controller_data$total_commands <- 0
controller_data$last_data <- list()

# WebSocket handler
process_message <- function(data, ws) {
  msg_type <- data$type
  
  if (msg_type == "ping") {
    ws$send(toJSON(list(
      type = "pong",
      timestamp = as.numeric(Sys.time()) * 1000
    ), auto_unbox = TRUE))
    cat(".")  # Show activity
    
  } else if (msg_type == "controller_data") {
    controller_data$total_commands <- controller_data$total_commands + 1
    controller_data$last_data <- data
    
    # Save to temp file for Shiny to read
    saveRDS(list(
      connected = TRUE,
      total_commands = controller_data$total_commands,
      timestamp = Sys.time(),
      data = data
    ), file = "quest_data.rds")
    
    # Send acknowledgment
    ws$send(toJSON(list(
      type = "ack",
      commands_received = controller_data$total_commands,
      timestamp = as.numeric(Sys.time()) * 1000
    ), auto_unbox = TRUE))
    
    cat("+")  # Show data received
  }
}

# WebSocket app
ws_app <- list(
  call = function(req) {
    list(
      status = 200L,
      headers = list('Content-Type' = 'text/html'),
      body = "WebSocket Server Running"
    )
  },
  onWSOpen = function(ws) {
    cat("\n✓ Quest 3 CONNECTED!\n")
    controller_data$connected <- TRUE
    
    ws$send(toJSON(list(
      type = "welcome",
      message = "Connected to R WebSocket Server",
      timestamp = as.numeric(Sys.time()) * 1000
    ), auto_unbox = TRUE))
    
    ws$onMessage(function(binary, message) {
      tryCatch({
        data <- fromJSON(message)
        process_message(data, ws)
      }, error = function(e) {
        cat("\nError:", e$message, "\n")
      })
    })
    
    ws$onClose(function() {
      cat("\n✗ Quest 3 DISCONNECTED\n")
      controller_data$connected <- FALSE
    })
  }
)

# Start server
cat("\nStarting WebSocket server on port 8080...\n")

tryCatch({
  server <- startServer("0.0.0.0", 8080, ws_app)
  
  cat("✓ WebSocket server started successfully!\n")
  cat("================================================================\n")
  cat("\nServer is running. Waiting for Quest 3 to connect...\n")
  cat("(Press Ctrl+C or ESC to stop)\n\n")
  cat(". = ping received\n")
  cat("+ = data received\n\n")
  
  # Keep server running
  while(TRUE) {
    later::run_now(0.1)
    Sys.sleep(0.1)
  }
  
}, error = function(e) {
  cat("✗ ERROR:", e$message, "\n")
})