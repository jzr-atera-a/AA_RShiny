# ==============================================================================
# R SHINY APP - QUEST 3 AR CONTROLLER DASHBOARD (SIMPLIFIED)
# ==============================================================================

library(shiny)
library(httpuv)
library(jsonlite)
library(plotly)

# ==============================================================================
# GLOBAL STATE
# ==============================================================================
controller_data <- reactiveValues(
  connected = FALSE,
  last_update = Sys.time(),
  controller1_position = list(x = 0, y = 0, z = 0),
  controller1_rotation = list(x = 0, y = 0, z = 0),
  controller1_grip = FALSE,
  controller1_trigger = FALSE,
  controller2_position = list(x = 0, y = 0, z = 0),
  controller2_rotation = list(x = 0, y = 0, z = 0),
  controller2_grip = FALSE,
  controller2_trigger = FALSE,
  linear_velocity = 0,
  angular_velocity = 0,
  total_commands = 0,
  position_history = data.frame(time = numeric(), x = numeric(), y = numeric(), z = numeric()),
  velocity_history = data.frame(time = numeric(), linear = numeric(), angular = numeric())
)

ws_connections <- list()

# ==============================================================================
# WEBSOCKET HANDLER
# ==============================================================================
process_quest_message <- function(data, ws) {
  msg_type <- data$type
  
  if (msg_type == "ping") {
    ws$send(toJSON(list(type = "pong", timestamp = as.numeric(Sys.time()) * 1000), auto_unbox = TRUE))
    
  } else if (msg_type == "controller_data") {
    controller_data$last_update <- Sys.time()
    controller_data$total_commands <- controller_data$total_commands + 1
    
    if (!is.null(data$controller1)) {
      controller_data$controller1_position <- data$controller1$position
      controller_data$controller1_rotation <- data$controller1$rotation
      controller_data$controller1_grip <- data$controller1$grip
      controller_data$controller1_trigger <- data$controller1$trigger
    }
    
    if (!is.null(data$controller2)) {
      controller_data$controller2_position <- data$controller2$position
      controller_data$controller2_rotation <- data$controller2$rotation
      controller_data$controller2_grip <- data$controller2$grip
      controller_data$controller2_trigger <- data$controller2$trigger
    }
    
    if (!is.null(data$velocity)) {
      controller_data$linear_velocity <- data$velocity$linear
      controller_data$angular_velocity <- data$velocity$angular
      
      new_velocity <- data.frame(
        time = as.numeric(Sys.time()),
        linear = data$velocity$linear,
        angular = data$velocity$angular
      )
      controller_data$velocity_history <- rbind(
        tail(controller_data$velocity_history, 99),
        new_velocity
      )
    }
    
    if (!is.null(data$controller1$position)) {
      new_position <- data.frame(
        time = as.numeric(Sys.time()),
        x = data$controller1$position$x,
        y = data$controller1$position$y,
        z = data$controller1$position$z
      )
      controller_data$position_history <- rbind(
        tail(controller_data$position_history, 99),
        new_position
      )
    }
    
    ws$send(toJSON(list(
      type = "ack",
      commands_received = controller_data$total_commands,
      timestamp = as.numeric(Sys.time()) * 1000
    ), auto_unbox = TRUE))
  }
}

# ==============================================================================
# UI
# ==============================================================================
ui <- fluidPage(
  theme = bslib::bs_theme(version = 4, bootswatch = "darkly"),
  
  tags$head(tags$style(HTML("
    .metric-box { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 10px; color: white; text-align: center; margin-bottom: 20px; }
    .metric-value { font-size: 36px; font-weight: bold; margin: 10px 0; }
    .metric-label { font-size: 14px; opacity: 0.9; }
    .controller-box { background: #2d3748; padding: 15px; border-radius: 8px; margin-bottom: 15px; }
    .status-connected { color: #48bb78; font-weight: bold; }
    .status-disconnected { color: #f56565; font-weight: bold; }
  "))),
  
  titlePanel(div(
    h2("🎮 Meta Quest 3 AR Controller Dashboard", style = "margin: 0;"),
    h4("Real-time Controller Metrics", style = "margin-top: 5px; opacity: 0.8;")
  )),
  
  fluidRow(column(12, wellPanel(style = "background: #1a202c; border: none;",
                                fluidRow(
                                  column(3, h4("Connection Status:"), uiOutput("connection_status")),
                                  column(3, h4("Total Commands:"), h3(textOutput("total_commands"), style = "color: #667eea;")),
                                  column(3, h4("Last Update:"), h3(textOutput("last_update"), style = "color: #667eea;")),
                                  column(3, h4("Server Info:"), verbatimTextOutput("server_info", placeholder = FALSE))
                                )
  ))),
  
  fluidRow(
    column(6, div(class = "metric-box",
                  div(class = "metric-label", "LINEAR VELOCITY"),
                  div(class = "metric-value", textOutput("linear_velocity")),
                  div("Forward/Backward Movement")
    )),
    column(6, div(class = "metric-box",
                  div(class = "metric-label", "ANGULAR VELOCITY"),
                  div(class = "metric-value", textOutput("angular_velocity")),
                  div("Rotation Left/Right")
    ))
  ),
  
  fluidRow(
    column(6, div(class = "controller-box",
                  h3("🎮 Controller 1 (Right)", style = "color: #00ffff;"),
                  h4("Position:"),
                  fluidRow(
                    column(4, strong("X:"), textOutput("c1_pos_x", inline = TRUE)),
                    column(4, strong("Y:"), textOutput("c1_pos_y", inline = TRUE)),
                    column(4, strong("Z:"), textOutput("c1_pos_z", inline = TRUE))
                  ),
                  h4("Rotation (degrees):"),
                  fluidRow(
                    column(4, strong("X:"), textOutput("c1_rot_x", inline = TRUE)),
                    column(4, strong("Y:"), textOutput("c1_rot_y", inline = TRUE)),
                    column(4, strong("Z:"), textOutput("c1_rot_z", inline = TRUE))
                  ),
                  h4("Buttons:"),
                  fluidRow(
                    column(6, strong("Grip:"), uiOutput("c1_grip")),
                    column(6, strong("Trigger:"), uiOutput("c1_trigger"))
                  )
    )),
    column(6, div(class = "controller-box",
                  h3("🎮 Controller 2 (Left)", style = "color: #00ffff;"),
                  h4("Position:"),
                  fluidRow(
                    column(4, strong("X:"), textOutput("c2_pos_x", inline = TRUE)),
                    column(4, strong("Y:"), textOutput("c2_pos_y", inline = TRUE)),
                    column(4, strong("Z:"), textOutput("c2_pos_z", inline = TRUE))
                  ),
                  h4("Rotation (degrees):"),
                  fluidRow(
                    column(4, strong("X:"), textOutput("c2_rot_x", inline = TRUE)),
                    column(4, strong("Y:"), textOutput("c2_rot_y", inline = TRUE)),
                    column(4, strong("Z:"), textOutput("c2_rot_z", inline = TRUE))
                  ),
                  h4("Buttons:"),
                  fluidRow(
                    column(6, strong("Grip:"), uiOutput("c2_grip")),
                    column(6, strong("Trigger:"), uiOutput("c2_trigger"))
                  )
    ))
  ),
  
  fluidRow(
    column(6, h3("Position Tracking (Controller 1)"), plotlyOutput("position_plot", height = "300px")),
    column(6, h3("Velocity Over Time"), plotlyOutput("velocity_plot", height = "300px"))
  ),
  
  fluidRow(column(12, wellPanel(style = "background: #2d3748; border: none; margin-top: 20px;",
                                h3("📱 How to Connect:"),
                                tags$ol(
                                  tags$li("Open browser on phone/Quest 3"),
                                  tags$li(HTML("Go to: <code>http://&lt;YOUR_IP&gt;:8000/quest_ar_shiny_controller.html</code>")),
                                  tags$li("Click 'Connect to R Shiny'"),
                                  tags$li("Watch metrics update!")
                                ),
                                h4("Your Computer IP:"), verbatimTextOutput("computer_ip")
  )))
)

# ==============================================================================
# SERVER
# ==============================================================================
server <- function(input, output, session) {
  
  get_local_ip <- function() {
    tryCatch({
      if (Sys.info()["sysname"] == "Windows") {
        ip <- system("ipconfig", intern = TRUE)
        ip_line <- grep("IPv4", ip, value = TRUE)[1]
        trimws(gsub(".*: ", "", ip_line))
      } else {
        trimws(strsplit(system("hostname -I", intern = TRUE), " ")[[1]][1])
      }
    }, error = function(e) "Unable to detect")
  }
  
  output$computer_ip <- renderText({ get_local_ip() })
  output$server_info <- renderText({ sprintf("WebSocket: 8080\nYour IP: %s", get_local_ip()) })
  
  output$connection_status <- renderUI({
    invalidateLater(1000, session)
    if (controller_data$connected) {
      tags$h3("🟢 Connected", class = "status-connected")
    } else {
      tags$h3("🔴 Disconnected", class = "status-disconnected")
    }
  })
  
  output$total_commands <- renderText({
    invalidateLater(500, session)
    format(controller_data$total_commands, big.mark = ",")
  })
  
  output$last_update <- renderText({
    invalidateLater(100, session)
    if (controller_data$connected) {
      time_diff <- as.numeric(Sys.time() - controller_data$last_update)
      if (time_diff < 1) "Just now" else sprintf("%.1f sec ago", time_diff)
    } else {
      "Never"
    }
  })
  
  output$linear_velocity <- renderText({
    invalidateLater(50, session)
    sprintf("%+.2f", controller_data$linear_velocity)
  })
  
  output$angular_velocity <- renderText({
    invalidateLater(50, session)
    sprintf("%+.2f", controller_data$angular_velocity)
  })
  
  output$c1_pos_x <- renderText({ invalidateLater(50, session); sprintf("%.3f", controller_data$controller1_position$x) })
  output$c1_pos_y <- renderText({ invalidateLater(50, session); sprintf("%.3f", controller_data$controller1_position$y) })
  output$c1_pos_z <- renderText({ invalidateLater(50, session); sprintf("%.3f", controller_data$controller1_position$z) })
  output$c1_rot_x <- renderText({ invalidateLater(50, session); sprintf("%.1f°", controller_data$controller1_rotation$x * 180 / pi) })
  output$c1_rot_y <- renderText({ invalidateLater(50, session); sprintf("%.1f°", controller_data$controller1_rotation$y * 180 / pi) })
  output$c1_rot_z <- renderText({ invalidateLater(50, session); sprintf("%.1f°", controller_data$controller1_rotation$z * 180 / pi) })
  
  output$c1_grip <- renderUI({
    invalidateLater(50, session)
    if (controller_data$controller1_grip) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$c1_trigger <- renderUI({
    invalidateLater(50, session)
    if (controller_data$controller1_trigger) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$c2_pos_x <- renderText({ invalidateLater(50, session); sprintf("%.3f", controller_data$controller2_position$x) })
  output$c2_pos_y <- renderText({ invalidateLater(50, session); sprintf("%.3f", controller_data$controller2_position$y) })
  output$c2_pos_z <- renderText({ invalidateLater(50, session); sprintf("%.3f", controller_data$controller2_position$z) })
  output$c2_rot_x <- renderText({ invalidateLater(50, session); sprintf("%.1f°", controller_data$controller2_rotation$x * 180 / pi) })
  output$c2_rot_y <- renderText({ invalidateLater(50, session); sprintf("%.1f°", controller_data$controller2_rotation$y * 180 / pi) })
  output$c2_rot_z <- renderText({ invalidateLater(50, session); sprintf("%.1f°", controller_data$controller2_rotation$z * 180 / pi) })
  
  output$c2_grip <- renderUI({
    invalidateLater(50, session)
    if (controller_data$controller2_grip) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$c2_trigger <- renderUI({
    invalidateLater(50, session)
    if (controller_data$controller2_trigger) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$position_plot <- renderPlotly({
    invalidateLater(200, session)
    if (nrow(controller_data$position_history) > 0) {
      df <- controller_data$position_history
      plot_ly(df) %>%
        add_trace(x = ~time, y = ~x, name = "X", type = "scatter", mode = "lines", line = list(color = "#ff6b6b")) %>%
        add_trace(x = ~time, y = ~y, name = "Y", type = "scatter", mode = "lines", line = list(color = "#4ecdc4")) %>%
        add_trace(x = ~time, y = ~z, name = "Z", type = "scatter", mode = "lines", line = list(color = "#ffe66d")) %>%
        layout(xaxis = list(title = "Time", showgrid = FALSE), yaxis = list(title = "Position", showgrid = TRUE),
               plot_bgcolor = "#1a202c", paper_bgcolor = "#2d3748", font = list(color = "white"),
               legend = list(x = 0.1, y = 1), margin = list(l = 50, r = 20, t = 20, b = 50))
    } else {
      plot_ly() %>% layout(title = "Waiting for data...", plot_bgcolor = "#1a202c", paper_bgcolor = "#2d3748", font = list(color = "white"))
    }
  })
  
  output$velocity_plot <- renderPlotly({
    invalidateLater(200, session)
    if (nrow(controller_data$velocity_history) > 0) {
      df <- controller_data$velocity_history
      plot_ly(df) %>%
        add_trace(x = ~time, y = ~linear, name = "Linear", type = "scatter", mode = "lines", line = list(color = "#00ff00")) %>%
        add_trace(x = ~time, y = ~angular, name = "Angular", type = "scatter", mode = "lines", line = list(color = "#00ffff")) %>%
        layout(xaxis = list(title = "Time", showgrid = FALSE), yaxis = list(title = "Velocity", range = c(-1.5, 1.5), showgrid = TRUE),
               plot_bgcolor = "#1a202c", paper_bgcolor = "#2d3748", font = list(color = "white"),
               legend = list(x = 0.1, y = 1), margin = list(l = 50, r = 20, t = 20, b = 50))
    } else {
      plot_ly() %>% layout(title = "Waiting for data...", plot_bgcolor = "#1a202c", paper_bgcolor = "#2d3748", font = list(color = "white"))
    }
  })
}

# ==============================================================================
# START WEBSOCKET SERVER
# ==============================================================================
cat("\n================================================================\n")
cat("Starting WebSocket Server on port 8080...\n")
cat("================================================================\n")

ws_app <- list(
  call = function(req) {
    list(status = 200L, headers = list('Content-Type' = 'text/html'), body = "WebSocket OK")
  },
  onWSOpen = function(ws) {
    cat("✓ Quest 3 connected!\n")
    controller_data$connected <- TRUE
    ws$send(toJSON(list(type = "welcome", message = "Connected!", timestamp = as.numeric(Sys.time()) * 1000), auto_unbox = TRUE))
    
    ws$onMessage(function(binary, message) {
      tryCatch({
        data <- fromJSON(message)
        process_quest_message(data, ws)
      }, error = function(e) cat("Error:", e$message, "\n"))
    })
    
    ws$onClose(function() {
      cat("✗ Quest 3 disconnected\n")
      controller_data$connected <- FALSE
    })
  }
)

# Start WebSocket server
tryCatch({
  ws_server <- startServer("0.0.0.0", 8080, ws_app)
  cat("✓ WebSocket server started successfully!\n")
  cat("================================================================\n\n")
}, error = function(e) {
  cat("✗ ERROR starting WebSocket server:", e$message, "\n")
  cat("================================================================\n\n")
})

# ==============================================================================
# RUN SHINY APP
# ==============================================================================
shinyApp(ui = ui, server = server, options = list(port = 4838))