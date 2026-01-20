# ==============================================================================
# SHINY DASHBOARD - READS DATA FROM WEBSOCKET SERVER
# ==============================================================================
# Run the websocket_server.R FIRST
# Then run this Shiny app
# ==============================================================================

library(shiny)
library(plotly)

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
                                  column(4, h4("Connection Status:"), uiOutput("connection_status")),
                                  column(4, h4("Total Commands:"), h3(textOutput("total_commands"), style = "color: #667eea;")),
                                  column(4, h4("Last Update:"), h3(textOutput("last_update"), style = "color: #667eea;"))
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
                  h4("Buttons:"),
                  fluidRow(
                    column(6, strong("Grip:"), uiOutput("c2_grip")),
                    column(6, strong("Trigger:"), uiOutput("c2_trigger"))
                  )
    ))
  ),
  
  fluidRow(column(12, wellPanel(style = "background: #2d3748; border: none; margin-top: 20px;",
                                h3("📱 How to Connect:"),
                                tags$ol(
                                  tags$li(strong("Run websocket_server.R first!"), " (In another R session)"),
                                  tags$li("Then run this Shiny app"),
                                  tags$li("Open browser on phone: http://10.5.0.2:8000/quest_ar_shiny_controller.html"),
                                  tags$li("Click 'Connect to R Shiny'"),
                                  tags$li("Move controllers and watch!")
                                )
  )))
)

# ==============================================================================
# SERVER
# ==============================================================================
server <- function(input, output, session) {
  
  # Read data from file created by WebSocket server
  quest_data <- reactiveFileReader(
    intervalMillis = 100,
    session = session,
    filePath = "quest_data.rds",
    readFunc = function(file) {
      if (file.exists(file)) {
        tryCatch({
          readRDS(file)
        }, error = function(e) {
          list(connected = FALSE, total_commands = 0, timestamp = Sys.time(), data = list())
        })
      } else {
        list(connected = FALSE, total_commands = 0, timestamp = Sys.time(), data = list())
      }
    }
  )
  
  output$connection_status <- renderUI({
    data <- quest_data()
    if (data$connected) {
      tags$h3("🟢 Connected", class = "status-connected")
    } else {
      tags$h3("🔴 Disconnected", class = "status-disconnected")
    }
  })
  
  output$total_commands <- renderText({
    data <- quest_data()
    format(data$total_commands, big.mark = ",")
  })
  
  output$last_update <- renderText({
    data <- quest_data()
    if (data$connected) {
      time_diff <- as.numeric(Sys.time() - data$timestamp)
      if (time_diff < 1) "Just now" else sprintf("%.1f sec ago", time_diff)
    } else {
      "Never"
    }
  })
  
  output$linear_velocity <- renderText({
    data <- quest_data()
    vel <- data$data$velocity$linear
    if (!is.null(vel)) sprintf("%+.2f", vel) else "+0.00"
  })
  
  output$angular_velocity <- renderText({
    data <- quest_data()
    vel <- data$data$velocity$angular
    if (!is.null(vel)) sprintf("%+.2f", vel) else "+0.00"
  })
  
  output$c1_pos_x <- renderText({
    data <- quest_data()
    pos <- data$data$controller1$position$x
    if (!is.null(pos)) sprintf("%.3f", pos) else "0.000"
  })
  
  output$c1_pos_y <- renderText({
    data <- quest_data()
    pos <- data$data$controller1$position$y
    if (!is.null(pos)) sprintf("%.3f", pos) else "0.000"
  })
  
  output$c1_pos_z <- renderText({
    data <- quest_data()
    pos <- data$data$controller1$position$z
    if (!is.null(pos)) sprintf("%.3f", pos) else "0.000"
  })
  
  output$c1_grip <- renderUI({
    data <- quest_data()
    grip <- data$data$controller1$grip
    if (!is.null(grip) && grip) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$c1_trigger <- renderUI({
    data <- quest_data()
    trigger <- data$data$controller1$trigger
    if (!is.null(trigger) && trigger) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$c2_pos_x <- renderText({
    data <- quest_data()
    pos <- data$data$controller2$position$x
    if (!is.null(pos)) sprintf("%.3f", pos) else "0.000"
  })
  
  output$c2_pos_y <- renderText({
    data <- quest_data()
    pos <- data$data$controller2$position$y
    if (!is.null(pos)) sprintf("%.3f", pos) else "0.000"
  })
  
  output$c2_pos_z <- renderText({
    data <- quest_data()
    pos <- data$data$controller2$position$z
    if (!is.null(pos)) sprintf("%.3f", pos) else "0.000"
  })
  
  output$c2_grip <- renderUI({
    data <- quest_data()
    grip <- data$data$controller2$grip
    if (!is.null(grip) && grip) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
  
  output$c2_trigger <- renderUI({
    data <- quest_data()
    trigger <- data$data$controller2$trigger
    if (!is.null(trigger) && trigger) {
      tags$span("🟢 PRESSED", style = "color: #48bb78; font-weight: bold;")
    } else {
      tags$span("⚫ Released", style = "color: #718096;")
    }
  })
}

# ==============================================================================
# RUN APP
# ==============================================================================
cat("\n================================================================\n")
cat("Starting Shiny Dashboard...\n")
cat("================================================================\n")
cat("Make sure websocket_server.R is running first!\n")
cat("================================================================\n\n")

shinyApp(ui = ui, server = server)