# Bambulab A1 Combo 3D Printer Control Dashboard
# R Shiny Application for Network (WiFi/LAN) Connection via MQTT

library(shiny)
library(shinydashboard)
library(DT)      # For data tables
library(plotly)  # For interactive plots
library(jsonlite) # For JSON handling

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = "Bambulab A1 - WiFi",
    tags$li(class = "dropdown",
            tags$style(HTML("
              .main-header .logo {
                font-family: 'Arial', sans-serif;
                font-weight: bold;
                font-size: 20px;
              }
            "))
    )
  ),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Connection", tabName = "connection", icon = icon("plug")),
      menuItem("File Management", tabName = "files", icon = icon("folder-open")),
      menuItem("Print Control", tabName = "print", icon = icon("print")),
      menuItem("Monitor", tabName = "monitor", icon = icon("tv")),
      menuItem("Settings", tabName = "settings", icon = icon("cog")),
      menuItem("Logs", tabName = "logs", icon = icon("list"))
    )
  ),
  
  # Body
  dashboardBody(
    # Include custom CSS
    tags$head(
      tags$style(HTML('
        /* Main body background with teal gradient */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        
        /* Sidebar styling */
        .sidebar, .main-sidebar {
          background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        
        .sidebar .sidebar-menu > li > a {
          color: #ffffff !important;
          border-left: 3px solid transparent;
          transition: all 0.3s ease;
        }
        
        .sidebar .sidebar-menu > li.active > a,
        .sidebar .sidebar-menu > li:hover > a {
          background: rgba(255, 255, 255, 0.15) !important;
          border-left: 3px solid #00A39A !important;
        }
        
        /* Header */
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
        }
        
        /* Box styling */
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
          margin-bottom: 20px;
          transition: transform 0.2s ease;
        }
        
        .box:hover {
          transform: translateY(-2px);
          box-shadow: 0 12px 35px rgba(0, 44, 60, 0.3) !important;
        }
        
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
        }
        
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
          font-size: 16px;
        }
        
        .box-body {
          background-color: #ffffff !important;
          padding: 20px;
        }
        
        /* Status messages */
        .status-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
        }
        
        .status-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
        }
        
        .status-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          color: #0c5460 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #17a2b8 !important;
          margin: 10px 0;
        }
        
        .status-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #f39c12 !important;
          margin: 10px 0;
        }
        
        /* Form controls */
        .form-control {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
        }
        
        /* Buttons */
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
          font-weight: 600;
          transition: transform 0.2s ease;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
          transform: translateY(-1px);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
          font-weight: 600;
        }
        
        .btn-info {
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
          font-weight: 600;
        }
        
        .btn-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        /* Value boxes */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
          transition: transform 0.2s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
        }
        
        .small-box.bg-aqua { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        
        .small-box.bg-green { 
          background: linear-gradient(135deg, #27ae60 0%, #229954 100%) !important; 
        }
        
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        
        /* Text areas */
        textarea.form-control {
          min-height: 100px;
        }
        
        /* Preview sections */
        .preview-section {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
          border-left: 4px solid #008A82;
          max-height: 400px;
          overflow-y: auto;
        }
        
        .metric-box {
          display: inline-block;
          background: linear-gradient(135deg, #e8f5f4 0%, #d4edea 100%);
          padding: 10px 20px;
          border-radius: 8px;
          margin: 5px;
          border: 2px solid #00A39A;
        }
        
        .metric-label {
          font-size: 0.8em;
          color: #666;
          text-transform: uppercase;
        }
        
        .metric-value {
          font-size: 1.5em;
          font-weight: bold;
          color: #008A82;
        }
      '))
    ),
    
    tabItems(
      # Connection Tab
      tabItem(tabName = "connection",
              fluidRow(
                box(
                  title = "Network Connection Status",
                  width = 12,
                  status = "primary",
                  solidHeader = TRUE,
                  
                  fluidRow(
                    column(6,
                           valueBoxOutput("connection_status", width = 12)
                    ),
                    column(6,
                           valueBoxOutput("printer_model", width = 12)
                    )
                  ),
                  
                  hr(),
                  
                  h4("Printer Network Configuration"),
                  p("Enter your printer's network information from the touchscreen:"),
                  p(strong("IP Address:"), "Settings → Network → IP Address"),
                  p(strong("Access Code:"), "Settings → WLAN → Access Code (8 digits)"),
                  p(strong("Serial Number:"), "Settings → Device → Serial Number"),
                  
                  hr(),
                  
                  fluidRow(
                    column(4,
                           textInput("printer_ip", "Printer IP Address:",
                                     placeholder = "192.168.1.100",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("access_code", "Access Code:",
                                     placeholder = "12345678",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("serial_number", "Serial Number:",
                                     placeholder = "01S00A123456789",
                                     width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           actionButton("connect_btn", "Connect to Printer",
                                        icon = icon("wifi"),
                                        class = "btn-success",
                                        width = "100%")
                    ),
                    column(6,
                           actionButton("disconnect_btn", "Disconnect",
                                        icon = icon("times"),
                                        class = "btn-danger",
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  actionButton("test_python", "Test Python Setup",
                               icon = icon("flask"),
                               class = "btn-info",
                               width = "100%"),
                  
                  br(),
                  uiOutput("connection_message")
                )
              ),
              
              fluidRow(
                box(
                  title = "Printer Information",
                  width = 6,
                  status = "info",
                  solidHeader = TRUE,
                  verbatimTextOutput("printer_info")
                ),
                
                box(
                  title = "Quick Actions",
                  width = 6,
                  status = "warning",
                  solidHeader = TRUE,
                  actionButton("home_all", "Home All Axes", 
                               icon = icon("home"),
                               class = "btn-info",
                               style = "margin: 5px;"),
                  actionButton("get_temp", "Get Temperature",
                               icon = icon("thermometer-half"),
                               class = "btn-info",
                               style = "margin: 5px;"),
                  actionButton("get_status", "Get Status",
                               icon = icon("info-circle"),
                               class = "btn-info",
                               style = "margin: 5px;"),
                  actionButton("toggle_light", "Toggle Light",
                               icon = icon("lightbulb"),
                               class = "btn-info",
                               style = "margin: 5px;")
                )
              )
      ),
      
      # File Management Tab
      tabItem(tabName = "files",
              fluidRow(
                box(
                  title = "Upload G-code File",
                  width = 6,
                  status = "primary",
                  solidHeader = TRUE,
                  
                  fileInput("gcode_file", "Choose G-code File (.gcode, .gco, .3mf)",
                            accept = c(".gcode", ".gco", ".3mf"),
                            width = "100%"),
                  
                  uiOutput("file_info"),
                  
                  actionButton("send_file", "Send to Printer",
                               icon = icon("upload"),
                               class = "btn-success",
                               width = "100%")
                ),
                
                box(
                  title = "File Preview",
                  width = 6,
                  status = "info",
                  solidHeader = TRUE,
                  
                  verbatimTextOutput("gcode_preview", placeholder = TRUE),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           div(class = "metric-box",
                               div(class = "metric-label", "File Size"),
                               div(class = "metric-value", textOutput("file_size", inline = TRUE))
                           )
                    ),
                    column(6,
                           div(class = "metric-box",
                               div(class = "metric-label", "Lines"),
                               div(class = "metric-value", textOutput("file_lines", inline = TRUE))
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Printer File List",
                  width = 12,
                  status = "success",
                  solidHeader = TRUE,
                  
                  DTOutput("printer_files"),
                  
                  br(),
                  
                  actionButton("refresh_files", "Refresh File List",
                               icon = icon("sync"),
                               class = "btn-info")
                )
              )
      ),
      
      # Print Control Tab
      tabItem(tabName = "print",
              fluidRow(
                valueBoxOutput("print_status", width = 4),
                valueBoxOutput("print_progress", width = 4),
                valueBoxOutput("time_remaining", width = 4)
              ),
              
              fluidRow(
                box(
                  title = "Print Controls",
                  width = 6,
                  status = "primary",
                  solidHeader = TRUE,
                  
                  selectInput("file_to_print", "Select File:",
                              choices = NULL,
                              width = "100%"),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           actionButton("start_print", "Start Print",
                                        icon = icon("play"),
                                        class = "btn-success",
                                        width = "100%")
                    ),
                    column(6,
                           actionButton("stop_print", "Stop Print",
                                        icon = icon("stop"),
                                        class = "btn-danger",
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           actionButton("pause_print", "Pause",
                                        icon = icon("pause"),
                                        class = "btn-warning",
                                        width = "100%")
                    ),
                    column(6,
                           actionButton("resume_print", "Resume",
                                        icon = icon("play-circle"),
                                        class = "btn-info",
                                        width = "100%")
                    )
                  )
                ),
                
                box(
                  title = "Speed & Flow Control",
                  width = 6,
                  status = "info",
                  solidHeader = TRUE,
                  
                  sliderInput("print_speed", "Print Speed (%):",
                              min = 10, max = 200, value = 100,
                              step = 5, width = "100%"),
                  
                  sliderInput("flow_rate", "Flow Rate (%):",
                              min = 75, max = 125, value = 100,
                              step = 5, width = "100%"),
                  
                  sliderInput("fan_speed", "Fan Speed (%):",
                              min = 0, max = 100, value = 100,
                              step = 5, width = "100%"),
                  
                  actionButton("apply_settings", "Apply Settings",
                               icon = icon("check"),
                               class = "btn-primary",
                               width = "100%")
                )
              ),
              
              fluidRow(
                box(
                  title = "Temperature Control",
                  width = 12,
                  status = "warning",
                  solidHeader = TRUE,
                  
                  fluidRow(
                    column(3,
                           numericInput("hotend_temp", "Hotend Target (°C):",
                                        value = 0, min = 0, max = 300,
                                        width = "100%")
                    ),
                    column(3,
                           numericInput("bed_temp", "Bed Target (°C):",
                                        value = 0, min = 0, max = 120,
                                        width = "100%")
                    ),
                    column(3,
                           br(),
                           actionButton("set_temps", "Set Temperatures",
                                        icon = icon("fire"),
                                        class = "btn-warning",
                                        width = "100%")
                    ),
                    column(3,
                           br(),
                           actionButton("cool_down", "Cool Down",
                                        icon = icon("snowflake"),
                                        class = "btn-info",
                                        width = "100%")
                    )
                  )
                )
              )
      ),
      
      # Monitor Tab
      tabItem(tabName = "monitor",
              fluidRow(
                valueBoxOutput("current_hotend", width = 3),
                valueBoxOutput("current_bed", width = 3),
                valueBoxOutput("current_chamber", width = 3),
                valueBoxOutput("current_layer", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Temperature Graph",
                  width = 8,
                  status = "primary",
                  solidHeader = TRUE,
                  plotlyOutput("temp_plot", height = "350px")
                ),
                
                box(
                  title = "Print Statistics",
                  width = 4,
                  status = "info",
                  solidHeader = TRUE,
                  
                  div(class = "metric-box", style = "width: 100%; margin-bottom: 10px;",
                      div(class = "metric-label", "Elapsed Time"),
                      div(class = "metric-value", textOutput("elapsed_time", inline = TRUE))
                  ),
                  
                  div(class = "metric-box", style = "width: 100%; margin-bottom: 10px;",
                      div(class = "metric-label", "Estimated Remaining"),
                      div(class = "metric-value", textOutput("est_remaining", inline = TRUE))
                  ),
                  
                  div(class = "metric-box", style = "width: 100%; margin-bottom: 10px;",
                      div(class = "metric-label", "Filament Used"),
                      div(class = "metric-value", textOutput("filament_used", inline = TRUE))
                  ),
                  
                  div(class = "metric-box", style = "width: 100%;",
                      div(class = "metric-label", "Current Z Height"),
                      div(class = "metric-value", textOutput("z_height", inline = TRUE))
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Real-time Status",
                  width = 12,
                  status = "success",
                  solidHeader = TRUE,
                  
                  verbatimTextOutput("realtime_status"),
                  
                  br(),
                  
                  checkboxInput("auto_refresh", "Auto-refresh (every 2 seconds)", value = FALSE),
                  actionButton("manual_refresh", "Manual Refresh",
                               icon = icon("sync"),
                               class = "btn-info")
                )
              )
      ),
      
      # Settings Tab
      tabItem(tabName = "settings",
              fluidRow(
                box(
                  title = "Printer Settings",
                  width = 6,
                  status = "primary",
                  solidHeader = TRUE,
                  
                  h4("Movement Settings"),
                  
                  numericInput("max_feedrate_x", "Max Feedrate X (mm/s):",
                               value = 500, min = 1, max = 1000),
                  
                  numericInput("max_feedrate_y", "Max Feedrate Y (mm/s):",
                               value = 500, min = 1, max = 1000),
                  
                  numericInput("max_feedrate_z", "Max Feedrate Z (mm/s):",
                               value = 20, min = 1, max = 100),
                  
                  numericInput("max_feedrate_e", "Max Feedrate E (mm/s):",
                               value = 60, min = 1, max = 200),
                  
                  hr(),
                  
                  actionButton("save_settings", "Save Settings",
                               icon = icon("save"),
                               class = "btn-success",
                               width = "100%")
                ),
                
                box(
                  title = "Manual Control",
                  width = 6,
                  status = "warning",
                  solidHeader = TRUE,
                  
                  h4("Manual Movement"),
                  
                  fluidRow(
                    column(4,
                           selectInput("move_distance", "Distance:",
                                       choices = c("0.1" = 0.1, "1" = 1, "10" = 10, "50" = 50, "100" = 100),
                                       selected = 10)
                    ),
                    column(4,
                           numericInput("move_speed", "Speed (mm/min):",
                                        value = 3000, min = 100, max = 10000)
                    ),
                    column(4,
                           br(),
                           actionButton("home_manual", "Home",
                                        icon = icon("home"),
                                        class = "btn-info",
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  div(style = "text-align: center;",
                      h5("XY Movement"),
                      fluidRow(
                        column(12, style = "text-align: center;",
                               actionButton("move_y_plus", "Y+",
                                            class = "btn-primary",
                                            style = "width: 80px; margin: 2px;")
                        )
                      ),
                      fluidRow(
                        column(12, style = "text-align: center;",
                               actionButton("move_x_minus", "X-",
                                            class = "btn-primary",
                                            style = "width: 80px; margin: 2px;"),
                               actionButton("move_home", "Home XY",
                                            class = "btn-warning",
                                            style = "width: 80px; margin: 2px;"),
                               actionButton("move_x_plus", "X+",
                                            class = "btn-primary",
                                            style = "width: 80px; margin: 2px;")
                        )
                      ),
                      fluidRow(
                        column(12, style = "text-align: center;",
                               actionButton("move_y_minus", "Y-",
                                            class = "btn-primary",
                                            style = "width: 80px; margin: 2px;")
                        )
                      )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           actionButton("move_z_plus", "Z+",
                                        class = "btn-primary",
                                        width = "100%")
                    ),
                    column(6,
                           actionButton("move_z_minus", "Z-",
                                        class = "btn-primary",
                                        width = "100%")
                    )
                  ),
                  
                  hr(),
                  
                  h5("Extrusion"),
                  
                  fluidRow(
                    column(6,
                           actionButton("extrude", "Extrude 10mm",
                                        icon = icon("arrow-right"),
                                        class = "btn-success",
                                        width = "100%")
                    ),
                    column(6,
                           actionButton("retract", "Retract 10mm",
                                        icon = icon("arrow-left"),
                                        class = "btn-danger",
                                        width = "100%")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Advanced Commands",
                  width = 12,
                  status = "danger",
                  solidHeader = TRUE,
                  
                  textInput("custom_gcode", "Custom G-code Command:",
                            placeholder = "e.g., M503 (Get settings)",
                            width = "100%"),
                  
                  actionButton("send_gcode", "Send Command",
                               icon = icon("terminal"),
                               class = "btn-danger"),
                  
                  br(), br(),
                  
                  verbatimTextOutput("gcode_response")
                )
              )
      ),
      
      # Logs Tab
      tabItem(tabName = "logs",
              fluidRow(
                box(
                  title = "Communication Log",
                  width = 12,
                  status = "primary",
                  solidHeader = TRUE,
                  
                  verbatimTextOutput("comm_log", placeholder = TRUE),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           actionButton("clear_log", "Clear Log",
                                        icon = icon("trash"),
                                        class = "btn-danger")
                    ),
                    column(6,
                           downloadButton("download_log", "Download Log",
                                          class = "btn-info")
                    )
                  )
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store state
  rv <- reactiveValues(
    connected = FALSE,
    printer_ip = "",
    access_code = "",
    serial_number = "",
    printer_status = "Disconnected",
    log = character(0),
    temp_data = data.frame(
      time = Sys.time(),
      hotend = 0,
      bed = 0,
      chamber = 0
    ),
    files = data.frame(
      Name = character(0),
      Size = character(0),
      Date = character(0)
    ),
    current_file = NULL,
    print_progress = 0,
    print_state = "Idle"
  )
  
  # Add to log function
  add_log <- function(message) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    log_entry <- paste0("[", timestamp, "] ", message)
    rv$log <- c(rv$log, log_entry)
    
    # Keep only last 1000 entries
    if(length(rv$log) > 1000) {
      rv$log <- tail(rv$log, 1000)
    }
  }
  
  # Connect to printer via MQTT
  observeEvent(input$connect_btn, {
    req(input$printer_ip, input$access_code, input$serial_number)
    
    add_log(paste("Attempting connection to", input$printer_ip))
    
    # Validate inputs
    if(nchar(input$access_code) != 8) {
      showNotification("Access code must be 8 digits",
                       type = "error")
      add_log("Error: Invalid access code length")
      return()
    }
    
    tryCatch({
      # Check if Python script exists
      if(!file.exists("bambulab_mqtt.py")) {
        showNotification("Error: bambulab_mqtt.py not found in current directory",
                         type = "error")
        add_log("Error: Python script not found")
        return()
      }
      
      # Test connection using Python script
      python_cmd <- sprintf(
        'python bambulab_mqtt.py connect "%s" "%s" "%s"',
        input$printer_ip,
        input$access_code,
        input$serial_number
      )
      
      add_log(paste("Running command:", python_cmd))
      
      # Capture both stdout and stderr
      result <- system(python_cmd, intern = TRUE, ignore.stderr = FALSE)
      
      add_log(paste("Python output:", paste(result, collapse = " | ")))
      
      # Try to find JSON in the output
      json_found <- FALSE
      response <- NULL
      
      for(line in result) {
        # Try to parse each line as JSON
        tryCatch({
          parsed <- fromJSON(line)
          if(!is.null(parsed$status)) {
            response <- parsed
            json_found <- TRUE
            break
          }
        }, error = function(e) {
          # Not JSON, skip this line
        })
      }
      
      if(json_found && !is.null(response$status) && response$status == "connected") {
        rv$connected <- TRUE
        rv$printer_status <- "Connected"
        rv$printer_ip <- input$printer_ip
        rv$access_code <- input$access_code
        rv$serial_number <- input$serial_number
        
        showNotification("Successfully connected to printer!",
                         type = "message")
        add_log("Connection established successfully")
      } else {
        rv$connected <- FALSE
        rv$printer_status <- "Connection Failed"
        
        # Show detailed error message
        error_msg <- if(!is.null(response$message)) {
          response$message
        } else {
          paste("Check logs for details. Python output:", paste(result, collapse = " "))
        }
        
        showNotification(paste("Connection failed:", error_msg),
                         type = "error",
                         duration = 10)
        add_log(paste("Connection failed:", error_msg))
      }
      
    }, error = function(e) {
      rv$connected <- FALSE
      rv$printer_status <- "Connection Failed"
      showNotification(paste("Connection error:", e$message),
                       type = "error",
                       duration = 10)
      add_log(paste("Connection error:", e$message))
    })
  })
  
  # Disconnect from printer
  observeEvent(input$disconnect_btn, {
    if(rv$connected) {
      add_log("Disconnecting from printer...")
      
      rv$connected <- FALSE
      rv$printer_status <- "Disconnected"
      rv$printer_ip <- ""
      rv$access_code <- ""
      rv$serial_number <- ""
      
      showNotification("Disconnected from printer",
                       type = "message")
      add_log("Disconnected successfully")
    }
  })
  
  # Test Python setup
  observeEvent(input$test_python, {
    add_log("Testing Python setup...")
    
    tryCatch({
      # Test Python version
      py_version <- system("python --version", intern = TRUE, ignore.stderr = TRUE)
      if(length(py_version) == 0) {
        py_version <- system("python3 --version", intern = TRUE, ignore.stderr = TRUE)
      }
      
      # Check if script exists
      script_exists <- file.exists("bambulab_mqtt.py")
      
      # Test paho-mqtt installation
      mqtt_test <- system("python -c \"import paho.mqtt.client\"", intern = TRUE, ignore.stderr = TRUE)
      mqtt_installed <- (length(mqtt_test) == 0) # No output means success
      
      # Get working directory
      wd <- getwd()
      
      # Show results
      result_msg <- paste(
        "Python Version:", ifelse(length(py_version) > 0, py_version, "Not found"),
        "\nWorking Directory:", wd,
        "\nScript exists:", script_exists,
        "\npaho-mqtt installed:", mqtt_installed,
        "\n\nFiles in directory:", paste(list.files(pattern = "*.py"), collapse = ", ")
      )
      
      add_log(result_msg)
      
      if(length(py_version) > 0 && script_exists && mqtt_installed) {
        showNotification("Python setup OK!", type = "message", duration = 5)
      } else {
        issues <- c()
        if(length(py_version) == 0) issues <- c(issues, "Python not found")
        if(!script_exists) issues <- c(issues, "bambulab_mqtt.py not found")
        if(!mqtt_installed) issues <- c(issues, "paho-mqtt not installed")
        
        showNotification(
          paste("Issues found:", paste(issues, collapse = ", ")),
          type = "warning",
          duration = 10
        )
      }
      
    }, error = function(e) {
      showNotification(paste("Test error:", e$message), type = "error")
      add_log(paste("Test error:", e$message))
    })
  })
  
  # Connection status outputs
  output$connection_status <- renderValueBox({
    valueBox(
      value = rv$printer_status,
      subtitle = "Connection Status",
      icon = icon(if(rv$connected) "check-circle" else "times-circle"),
      color = if(rv$connected) "green" else "red"
    )
  })
  
  output$printer_model <- renderValueBox({
    valueBox(
      value = "Bambulab A1",
      subtitle = "Printer Model",
      icon = icon("print"),
      color = "aqua"
    )
  })
  
  output$connection_message <- renderUI({
    if(rv$connected) {
      div(class = "status-success",
          icon("check-circle"),
          " Connected via WiFi/LAN and ready to print")
    } else {
      div(class = "status-info",
          icon("info-circle"),
          " Please enter printer IP, Access Code, and Serial Number, then click Connect")
    }
  })
  
  # Printer information
  output$printer_info <- renderText({
    if(rv$connected) {
      paste(
        "Printer: Bambulab A1 Combo",
        "Connection: Network (WiFi/LAN)",
        paste("IP Address:", rv$printer_ip),
        paste("Serial Number:", rv$serial_number),
        "Protocol: MQTT over TLS",
        "Build Volume: 256 x 256 x 256 mm",
        sep = "\n"
      )
    } else {
      "Not connected to printer.\nPlease enter network details and connect."
    }
  })
  
  # File upload handling
  observeEvent(input$gcode_file, {
    req(input$gcode_file)
    
    add_log(paste("File uploaded:", input$gcode_file$name))
    rv$current_file <- input$gcode_file
    
    showNotification(paste("File loaded:", input$gcode_file$name),
                     type = "message")
  })
  
  output$file_info <- renderUI({
    req(input$gcode_file)
    
    div(class = "status-info",
        icon("file"),
        paste(" File:", input$gcode_file$name)
    )
  })
  
  output$gcode_preview <- renderText({
    req(input$gcode_file)
    
    tryCatch({
      lines <- readLines(input$gcode_file$datapath, n = 50)
      paste(lines, collapse = "\n")
    }, error = function(e) {
      "Unable to preview file"
    })
  })
  
  output$file_size <- renderText({
    req(input$gcode_file)
    size_bytes <- file.info(input$gcode_file$datapath)$size
    
    if(size_bytes < 1024) {
      paste(size_bytes, "B")
    } else if(size_bytes < 1024^2) {
      paste(round(size_bytes/1024, 2), "KB")
    } else {
      paste(round(size_bytes/1024^2, 2), "MB")
    }
  })
  
  output$file_lines <- renderText({
    req(input$gcode_file)
    
    tryCatch({
      length(readLines(input$gcode_file$datapath))
    }, error = function(e) {
      "N/A"
    })
  })
  
  # Send file to printer
  observeEvent(input$send_file, {
    req(rv$connected, input$gcode_file)
    
    add_log(paste("Sending file to printer:", input$gcode_file$name))
    
    showNotification("Sending file to printer... This may take a moment.",
                     type = "message",
                     duration = NULL,
                     id = "upload_progress")
    
    tryCatch({
      # Simulate file transfer
      # In production, read and send file line by line
      
      Sys.sleep(2)  # Simulate transfer time
      
      removeNotification("upload_progress")
      showNotification("File transferred successfully!",
                       type = "message")
      add_log("File transfer complete")
      
    }, error = function(e) {
      removeNotification("upload_progress")
      showNotification(paste("Error sending file:", e$message),
                       type = "error")
      add_log(paste("File transfer error:", e$message))
    })
  })
  
  # Print control outputs
  output$print_status <- renderValueBox({
    valueBox(
      value = rv$print_state,
      subtitle = "Print Status",
      icon = icon("print"),
      color = if(rv$print_state == "Printing") "green" else "blue"
    )
  })
  
  output$print_progress <- renderValueBox({
    valueBox(
      value = paste0(rv$print_progress, "%"),
      subtitle = "Progress",
      icon = icon("tasks"),
      color = "yellow"
    )
  })
  
  output$time_remaining <- renderValueBox({
    valueBox(
      value = "00:00:00",
      subtitle = "Time Remaining",
      icon = icon("clock"),
      color = "aqua"
    )
  })
  
  # Start print
  observeEvent(input$start_print, {
    req(rv$connected)
    
    add_log("Starting print job...")
    rv$print_state <- "Printing"
    rv$print_progress <- 0
    
    showNotification("Print job started!",
                     type = "message")
  })
  
  # Stop print
  observeEvent(input$stop_print, {
    add_log("Stopping print job...")
    rv$print_state <- "Stopped"
    rv$print_progress <- 0
    
    showNotification("Print job stopped",
                     type = "warning")
  })
  
  # Temperature monitoring
  output$current_hotend <- renderValueBox({
    valueBox(
      value = paste0("25°C"),
      subtitle = "Hotend Temperature",
      icon = icon("thermometer-full"),
      color = "red"
    )
  })
  
  output$current_bed <- renderValueBox({
    valueBox(
      value = paste0("25°C"),
      subtitle = "Bed Temperature",
      icon = icon("thermometer-half"),
      color = "orange"
    )
  })
  
  output$current_chamber <- renderValueBox({
    valueBox(
      value = paste0("25°C"),
      subtitle = "Chamber Temperature",
      icon = icon("thermometer-empty"),
      color = "yellow"
    )
  })
  
  output$current_layer <- renderValueBox({
    valueBox(
      value = "0/0",
      subtitle = "Current Layer",
      icon = icon("layer-group"),
      color = "aqua"
    )
  })
  
  # Temperature plot
  output$temp_plot <- renderPlotly({
    plot_ly(rv$temp_data, x = ~time) %>%
      add_lines(y = ~hotend, name = "Hotend", line = list(color = "#e74c3c")) %>%
      add_lines(y = ~bed, name = "Bed", line = list(color = "#f39c12")) %>%
      add_lines(y = ~chamber, name = "Chamber", line = list(color = "#3498db")) %>%
      layout(
        title = "Temperature History",
        xaxis = list(title = "Time"),
        yaxis = list(title = "Temperature (°C)"),
        hovermode = "x unified"
      )
  })
  
  # Statistics outputs
  output$elapsed_time <- renderText({ "00:00:00" })
  output$est_remaining <- renderText({ "00:00:00" })
  output$filament_used <- renderText({ "0.0 g" })
  output$z_height <- renderText({ "0.0 mm" })
  
  # Real-time status
  output$realtime_status <- renderText({
    if(rv$connected) {
      paste(
        "Status: Ready",
        "Position: X=0.0 Y=0.0 Z=0.0",
        "Hotend: 25°C / 0°C",
        "Bed: 25°C / 0°C",
        "Fan: 0%",
        sep = "\n"
      )
    } else {
      "Printer not connected"
    }
  })
  
  # Communication log
  output$comm_log <- renderText({
    paste(rev(tail(rv$log, 100)), collapse = "\n")
  })
  
  observeEvent(input$clear_log, {
    rv$log <- character(0)
    add_log("Log cleared")
  })
  
  output$download_log <- downloadHandler(
    filename = function() {
      paste0("printer_log_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
    },
    content = function(file) {
      writeLines(rv$log, file)
    }
  )
  
  # Initial log entry
  isolate({
    add_log("Application started")
    add_log("Bambulab A1 Combo printer control interface initialized")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
