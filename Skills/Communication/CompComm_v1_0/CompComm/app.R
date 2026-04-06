# app.R - Compelling Communication @ Atera Analytics
# Based on Simon Hall, Cambridge University Press

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  COMPELLING COMMUNICATION @ ATERA ANALYTICS v1.0  ║\n")
cat("╚════════════════════════════════════════════════════╝\n\n")

source("global.R")

module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

log_error <- function(error_msg) {
  error_log <- file.path(getwd(), "app_error.log")
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0(timestamp, " - ERROR: ", error_msg, "\n")
  tryCatch({
    write(log_entry, file = error_log, append = TRUE)
    cat("Error logged to:", error_log, "\n")
  }, error = function(e) {
    cat("Could not write to log file\n")
  })
}

app <- shinyApp(
  ui = create_ui(module_loader),

  server = function(input, output, session) {

    tryCatch({
      create_server(module_loader)
      cat("✓ Server initialized successfully\n")
    }, error = function(e) {
      cat("Error initializing server:", e$message, "\n")
      log_error(paste("Server initialization failed:", e$message))
    })

    session$onSessionEnded(function() {
      gc(verbose = FALSE)
      cat("✓ Session ended:", format(Sys.time()), "\n")
    })

    cat("✓ Session started:", session$token, "\n")
  },

  options = list(
    port           = getOption("shiny.port", 3839),
    host           = getOption("shiny.host", "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  ),

  enableBookmarking = "url"
)

app
