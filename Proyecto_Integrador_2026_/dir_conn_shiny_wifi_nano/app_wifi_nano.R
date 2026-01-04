# ==============================================================================
# SERVO STEERING CONTROL - R SHINY DASHBOARD
# ==============================================================================
# WiFi-controlled servo via Jetson Nano
# Teal/Aqua gradient theme
# ==============================================================================

library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)

# ==============================================================================
# CONFIGURATION
# ==============================================================================
JETSON_IP <- "192.168.100.10"  # CHANGE THIS TO YOUR JETSON NANO'S IP ADDRESS
JETSON_PORT <- "5000"
BASE_URL <- paste0("http://", JETSON_IP, ":", JETSON_PORT)

# ==============================================================================
# UI DEFINITION
# ==============================================================================
ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(title = "Servo Steering Control"),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      menuItem("Control Panel", tabName = "control", icon = icon("gamepad")),
      menuItem("Connection Test", tabName = "test", icon = icon("wifi"))
    )
  ),
  
  # Body
  dashboardBody(
    # Custom CSS for teal/aqua gradient theme
    tags$head(
      tags$style(HTML("
        /* Teal/Aqua gradient background */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #008B8B 0%, #00CED1 50%, #48D1CC 100%);
        }
        
        /* Box styling */
        .box {
          border-radius: 10px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        /* Slider styling */
        .irs-bar {
          background: linear-gradient(to bottom, #008B8B 0%, #00CED1 100%);
          border-top: 1px solid #006666;
          border-bottom: 1px solid #006666;
        }
        
        .irs-bar-edge {
          background: #008B8B;
          border: 1px solid #006666;
        }
        
        .irs-single {
          background: #008B8B;
        }
        
        /* Button styling */
        .btn-primary {
          background: linear-gradient(to bottom, #008B8B 0%, #00CED1 100%);
          border-color: #006666;
          font-weight: bold;
        }
        
        .btn-primary:hover {
          background: linear-gradient(to bottom, #006666 0%, #008B8B 100%);
          border-color: #004444;
        }
        
        .btn-success {
          background: linear-gradient(to bottom, #2ECC71 0%, #27AE60 100%);
        }
        
        .btn-danger {
          background: linear-gradient(to bottom, #E74C3C 0%, #C0392B 100%);
        }
        
        /* Status box */
        .status-box {
          padding: 15px;
          border-radius: 8px;
          background: white;
          margin: 10px 0;
          font-family: 'Courier New', monospace;
        }
        
        /* Connection indicator */
        .connected {
          color: #27AE60;
          font-weight: bold;
        }
        
        .disconnected {
          color: #E74C3C;
          font-weight: bold;
        }
        
        /* Steering display */
        .steering-display {
          font-size: 48px;
          font-weight: bold;
          text-align: center;
          padding: 20px;
          background: white;
          border-radius: 10px;
          margin: 20px 0;
          color: #008B8B;
        }
        
        /* Command log */
        .command-log {
          background: #f8f9fa;
          padding: 10px;
          border-radius: 5px;
          max-height: 200px;
          overflow-y: auto;
          font-family: 'Courier New', monospace;
          font-size: 12px;
        }
      "))
    ),
    
    tabItems(
      # ==============================================================================
      # CONTROL PANEL TAB
      # ==============================================================================
      tabItem(tabName = "control",
              fluidRow(
                # Steering Control Box
                box(
                  title = "Servo Steering Control",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  
                  div(class = "steering-display",
                      textOutput("steeringDisplay")
                  ),
                  
                  sliderInput("servoAngle",
                              label = h4("Steering Position (Left ← Center → Right)"),
                              min = 0,
                              max = 180,
                              value = 90,
                              step = 1,
                              width = "100%"
                  ),
                  
                  fluidRow(
                    column(4,
                           actionButton("centerBtn", "CENTER (90°)", 
                                        class = "btn-primary btn-block", 
                                        style = "margin-top: 10px; padding: 15px; font-size: 16px;")
                    ),
                    column(4,
                           actionButton("leftBtn", "FULL LEFT (0°)", 
                                        class = "btn-info btn-block",
                                        style = "margin-top: 10px; padding: 15px; font-size: 16px;")
                    ),
                    column(4,
                           actionButton("rightBtn", "FULL RIGHT (180°)", 
                                        class = "btn-info btn-block",
                                        style = "margin-top: 10px; padding: 15px; font-size: 16px;")
                    )
                  ),
                  
                  hr(),
                  
                  actionButton("sendCommand", "SEND TO SERVO", 
                               class = "btn-success btn-lg btn-block",
                               style = "padding: 20px; font-size: 18px;")
                ),
                
                # Status Box
                box(
                  title = "System Status",
                  status = "info",
                  solidHeader = TRUE,
                  width = 4,
                  
                  h4("Connection Status:"),
                  uiOutput("connectionStatus"),
                  
                  hr(),
                  
                  h4("Last Command:"),
                  verbatimTextOutput("lastCommand"),
                  
                  h4("Response from Nano:"),
                  verbatimTextOutput("nanoResponse"),
                  
                  hr(),
                  
                  actionButton("refreshStatus", "Refresh Status", 
                               class = "btn-primary btn-block")
                )
              ),
              
              fluidRow(
                box(
                  title = "Command History Log",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 12,
                  collapsible = TRUE,
                  
                  div(class = "command-log",
                      verbatimTextOutput("commandLog")
                  )
                )
              )
      ),
      
      # ==============================================================================
      # CONNECTION TEST TAB
      # ==============================================================================
      tabItem(tabName = "test",
              fluidRow(
                box(
                  title = "WiFi Connection Test",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Jetson Nano Configuration:"),
                  textInput("jetsonIP", "Jetson IP Address:", value = JETSON_IP),
                  textInput("jetsonPort", "Port:", value = JETSON_PORT),
                  
                  hr(),
                  
                  actionButton("testConnection", "TEST CONNECTION", 
                               class = "btn-success btn-lg btn-block",
                               style = "padding: 15px; font-size: 16px;"),
                  
                  hr(),
                  
                  h4("Connection Test Result:"),
                  uiOutput("testResult")
                ),
                
                box(
                  title = "System Information",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  
                  h4("Architecture:"),
                  tags$ul(
                    tags$li("PC (R Shiny) → WiFi → Jetson Nano"),
                    tags$li("Jetson Nano → USB Serial → Arduino Mega"),
                    tags$li("Arduino Mega → PWM → Servo")
                  ),
                  
                  hr(),
                  
                  h4("Current Configuration:"),
                  verbatimTextOutput("currentConfig"),
                  
                  hr(),
                  
                  h4("Expected Servo Range:"),
                  tags$ul(
                    tags$li(strong("0°"), " = Full Left"),
                    tags$li(strong("90°"), " = Center (Neutral)"),
                    tags$li(strong("180°"), " = Full Right")
                  )
                )
              )
      )
    )
  )
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================
server <- function(input, output, session) {
  
  # Reactive values to store state
  values <- reactiveValues(
    commandLog = character(0),
    lastCommand = "None",
    nanoResponse = "No response yet",
    connected = FALSE
  )
  
  # ==============================================================================
  # STEERING DISPLAY
  # ==============================================================================
  output$steeringDisplay <- renderText({
    angle <- input$servoAngle
    
    if (angle < 45) {
      return(paste0("◄◄◄ LEFT ", angle, "°"))
    } else if (angle > 135) {
      return(paste0("RIGHT ", angle, "° ►►►"))
    } else if (angle >= 85 && angle <= 95) {
      return(paste0("■ CENTER ", angle, "° ■"))
    } else if (angle < 90) {
      return(paste0("◄ SLIGHT LEFT ", angle, "°"))
    } else {
      return(paste0("SLIGHT RIGHT ", angle, "° ►"))
    }
  })
  
  # ==============================================================================
  # BUTTON ACTIONS
  # ==============================================================================
  observeEvent(input$centerBtn, {
    updateSliderInput(session, "servoAngle", value = 90)
  })
  
  observeEvent(input$leftBtn, {
    updateSliderInput(session, "servoAngle", value = 0)
  })
  
  observeEvent(input$rightBtn, {
    updateSliderInput(session, "servoAngle", value = 180)
  })
  
  # ==============================================================================
  # SEND COMMAND TO JETSON NANO
  # ==============================================================================
  observeEvent(input$sendCommand, {
    angle <- input$servoAngle
    
    # Build API endpoint using user-entered IP (or default)
    current_ip <- input$jetsonIP
    current_port <- input$jetsonPort
    url <- paste0("http://", current_ip, ":", current_port, "/test")
    
    # Create JSON payload
    payload <- list(
      command = "SERVO",
      angle = angle,
      timestamp = as.numeric(Sys.time())
    )
    
    # Log command
    timestamp <- format(Sys.time(), "%H:%M:%S")
    logEntry <- paste0("[", timestamp, "] Sending: SERVO angle=", angle, "°")
    values$commandLog <- c(logEntry, values$commandLog)
    if (length(values$commandLog) > 20) {
      values$commandLog <- values$commandLog[1:20]
    }
    
    # Send HTTP POST request
    tryCatch({
      response <- POST(
        url,
        body = payload,
        encode = "json",
        timeout(5)
      )
      
      if (status_code(response) == 200) {
        content <- content(response, "parsed")
        values$lastCommand <- paste0("SERVO ", angle, "°")
        values$nanoResponse <- toJSON(content, pretty = TRUE, auto_unbox = TRUE)
        values$connected <- TRUE
        
        # Log success
        values$commandLog <- c(
          paste0("[", timestamp, "] ✓ SUCCESS: ", content$message),
          values$commandLog
        )
        
        showNotification("Command sent successfully!", type = "message")
      } else {
        values$nanoResponse <- paste("Error:", status_code(response))
        values$connected <- FALSE
        showNotification("Failed to send command", type = "error")
      }
    }, error = function(e) {
      values$nanoResponse <- paste("Connection Error:", e$message)
      values$connected <- FALSE
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # ==============================================================================
  # CONNECTION TEST
  # ==============================================================================
  observeEvent(input$testConnection, {
    # Update base URL if user changed it
    test_url <- paste0("http://", input$jetsonIP, ":", input$jetsonPort, "/ping")
    
    tryCatch({
      response <- GET(test_url, timeout(5))
      
      if (status_code(response) == 200) {
        content <- content(response, "parsed")
        values$connected <- TRUE
        showNotification("✓ Connection successful!", type = "message", duration = 5)
      } else {
        values$connected <- FALSE
        showNotification("✗ Connection failed!", type = "error", duration = 5)
      }
    }, error = function(e) {
      values$connected <- FALSE
      showNotification(paste("✗ Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # ==============================================================================
  # OUTPUTS
  # ==============================================================================
  output$connectionStatus <- renderUI({
    if (values$connected) {
      div(class = "connected", "● CONNECTED")
    } else {
      div(class = "disconnected", "● DISCONNECTED")
    }
  })
  
  output$lastCommand <- renderText({
    values$lastCommand
  })
  
  output$nanoResponse <- renderText({
    values$nanoResponse
  })
  
  output$commandLog <- renderText({
    paste(values$commandLog, collapse = "\n")
  })
  
  output$testResult <- renderUI({
    if (values$connected) {
      div(style = "color: green; font-weight: bold; font-size: 18px;",
          "✓ CONNECTION SUCCESSFUL",
          br(),
          "Jetson Nano is reachable via WiFi"
      )
    } else {
      div(style = "color: red; font-weight: bold; font-size: 18px;",
          "✗ CONNECTION FAILED",
          br(),
          "Cannot reach Jetson Nano. Check IP address and network."
      )
    }
  })
  
  output$currentConfig <- renderText({
    current_url <- paste0("http://", input$jetsonIP, ":", input$jetsonPort)
    paste0(
      "Jetson IP: ", current_url, "\n",
      "Status: ", ifelse(values$connected, "Connected", "Disconnected"), "\n",
      "Last command: ", values$lastCommand
    )
  })
  
  # Manual refresh only - auto-refresh disabled for stability
  observeEvent(input$refreshStatus, {
    # Use user-entered IP and port
    current_ip <- input$jetsonIP
    current_port <- input$jetsonPort
    status_url <- paste0("http://", current_ip, ":", current_port, "/status")
    
    tryCatch({
      response <- GET(status_url, timeout(5))
      if (status_code(response) == 200) {
        values$connected <- TRUE
        showNotification("Status refreshed", type = "message", duration = 2)
      } else {
        values$connected <- FALSE
      }
    }, error = function(e) {
      values$connected <- FALSE
      showNotification("Connection error", type = "warning", duration = 2)
    })
  })
}

# ==============================================================================
# RUN APPLICATION
# ==============================================================================
shinyApp(ui = ui, server = server)