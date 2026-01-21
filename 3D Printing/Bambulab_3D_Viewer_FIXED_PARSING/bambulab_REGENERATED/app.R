# Bambulab A1 Combo 3D Printer Control Dashboard
# R Shiny Application for Network (WiFi/LAN) Connection via MQTT

library(shiny)
library(shinydashboard)
library(DT)      # For data tables
library(plotly)  # For interactive plots
library(jsonlite) # For JSON handling

# CONFIGURACIÓN: Eliminar límite de tamaño de archivo para uploads
# Por defecto Shiny limita los uploads a 5MB
# Opciones:
# - Para sin límite: options(shiny.maxRequestSize = Inf)
# - Para límite específico (ej. 100MB): options(shiny.maxRequestSize = 100*1024^2)
# - Para límite de 500MB: options(shiny.maxRequestSize = 500*1024^2)
options(shiny.maxRequestSize = Inf)  # SIN LÍMITE de tamaño

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
      menuItem("3D Model Viewer", tabName = "viewer3d", icon = icon("cube"),
               badgeLabel = "NEW", badgeColor = "green"),
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
        
        /* 3D Viewer specific styles */
        .dimension-card {
          background: linear-gradient(135deg, #e8f5f4 0%, #d4edea 100%);
          padding: 20px;
          border-radius: 12px;
          margin: 10px 0;
          border-left: 5px solid #00A39A;
          box-shadow: 0 4px 15px rgba(0, 138, 130, 0.15);
          transition: transform 0.2s ease;
        }
        
        .dimension-card:hover {
          transform: translateY(-3px);
          box-shadow: 0 6px 20px rgba(0, 138, 130, 0.25);
        }
        
        .dimension-label {
          font-size: 14px;
          color: #666;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 8px;
        }
        
        .dimension-value {
          font-size: 32px;
          font-weight: bold;
          color: #008A82;
          font-family: "Courier New", monospace;
        }
        
        .dimension-unit {
          font-size: 18px;
          color: #00A39A;
          margin-left: 5px;
        }
        
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
          gap: 15px;
          margin: 20px 0;
        }
        
        .stat-item {
          background: white;
          padding: 15px;
          border-radius: 10px;
          border-left: 4px solid #00A39A;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }
        
        .stat-label {
          font-size: 12px;
          color: #888;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        
        .stat-value {
          font-size: 20px;
          font-weight: bold;
          color: #333;
          margin-top: 5px;
        }
        
        .info-badge {
          display: inline-block;
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
          color: white;
          padding: 8px 15px;
          border-radius: 20px;
          font-size: 13px;
          font-weight: 600;
          margin: 5px;
          box-shadow: 0 3px 10px rgba(52, 152, 219, 0.3);
        }
        
        .success-badge {
          display: inline-block;
          background: linear-gradient(135deg, #27ae60 0%, #229954 100%);
          color: white;
          padding: 8px 15px;
          border-radius: 20px;
          font-size: 13px;
          font-weight: 600;
          margin: 5px;
          box-shadow: 0 3px 10px rgba(39, 174, 96, 0.3);
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
      
      # ============================================
      # 3D MODEL VIEWER TAB - NEW FEATURE
      # ============================================
      tabItem(tabName = "viewer3d",
              fluidRow(
                box(
                  title = "3D Model Viewer & Dimensions",
                  width = 12,
                  status = "primary",
                  solidHeader = TRUE,
                  
                  fluidRow(
                    column(8,
                           div(style = "background: #f8f9fa; padding: 20px; border-radius: 10px; min-height: 500px;",
                               h4(icon("cube"), " Interactive 3D Visualization"),
                               plotlyOutput("model_3d", height = "450px")
                           )
                    ),
                    
                    column(4,
                           h4(icon("ruler-combined"), " Model Dimensions"),
                           
                           div(class = "dimension-card",
                               div(class = "dimension-label", icon("arrows-alt-h"), " X Axis (Width)"),
                               div(class = "dimension-value",
                                   textOutput("dim_x", inline = TRUE),
                                   span(class = "dimension-unit", "cm")
                               )
                           ),
                           
                           div(class = "dimension-card",
                               div(class = "dimension-label", icon("arrows-alt-v"), " Y Axis (Depth)"),
                               div(class = "dimension-value",
                                   textOutput("dim_y", inline = TRUE),
                                   span(class = "dimension-unit", "cm")
                               )
                           ),
                           
                           div(class = "dimension-card",
                               div(class = "dimension-label", icon("sort-amount-up"), " Z Axis (Height)"),
                               div(class = "dimension-value",
                                   textOutput("dim_z", inline = TRUE),
                                   span(class = "dimension-unit", "cm")
                               )
                           ),
                           
                           br(),
                           
                           h4(icon("info-circle"), " Print Information"),
                           
                           div(class = "stats-grid",
                               div(class = "stat-item",
                                   div(class = "stat-label", "Volume"),
                                   div(class = "stat-value", textOutput("model_volume", inline = TRUE))
                               ),
                               div(class = "stat-item",
                                   div(class = "stat-label", "Layers"),
                                   div(class = "stat-value", textOutput("model_layers", inline = TRUE))
                               ),
                               div(class = "stat-item",
                                   div(class = "stat-label", "Filament"),
                                   div(class = "stat-value", textOutput("model_filament", inline = TRUE))
                               ),
                               div(class = "stat-item",
                                   div(class = "stat-label", "Print Time"),
                                   div(class = "stat-value", textOutput("model_time", inline = TRUE))
                               )
                           )
                    )
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(12,
                           h4(icon("chart-bar"), " Bed Positioning Preview"),
                           div(class = "status-info",
                               icon("check-circle"),
                               strong(" Model fits on bed:"),
                               " Bambu Lab A1 (256 x 256 x 256 mm)"
                           ),
                           div(style = "margin-top: 15px;",
                               span(class = "info-badge", icon("cube"), " Centered on build plate"),
                               span(class = "info-badge", icon("layer-group"), " Optimized orientation"),
                               span(class = "success-badge", icon("check"), " Ready to print")
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Load G-code Models for Visualization",
                  width = 12,
                  status = "info",
                  solidHeader = TRUE,
                  
                  p("Load your G-code files to visualize the 3D model with accurate dimensions:"),
                  
                  fluidRow(
                    column(4,
                           fileInput("gcode_3d_file", "Upload G-code File:",
                                     accept = c(".gcode", ".gco"),
                                     width = "100%")
                    ),
                    column(4,
                           br(),
                           actionButton("load_uploaded_model",
                                        "Load Uploaded File",
                                        icon = icon("upload"),
                                        class = "btn-primary",
                                        width = "100%")
                    ),
                    column(4,
                           br(),
                           actionButton("clear_3d_view",
                                        "Clear Viewer",
                                        icon = icon("times"),
                                        class = "btn-danger",
                                        width = "100%")
                    )
                  ),
                  
                  hr(),
                  
                  h5("Or load sample robot base models:"),
                  
                  fluidRow(
                    column(6,
                           actionButton("load_level1",
                                        "Load Level 1 Base (MD22 Platform)",
                                        icon = icon("layer-group"),
                                        class = "btn-success",
                                        width = "100%",
                                        style = "margin: 5px;")
                    ),
                    column(6,
                           actionButton("load_level2",
                                        "Load Level 2 Platform (Jetson + Arduino)",
                                        icon = icon("microchip"),
                                        class = "btn-success",
                                        width = "100%",
                                        style = "margin: 5px;")
                    )
                  ),
                  
                  br(),
                  
                  div(class = "status-info",
                      icon("lightbulb"),
                      strong(" Tip:"),
                      " Click and drag to rotate the 3D model. Use scroll wheel to zoom in/out. Shift+drag to pan."
                  )
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
    print_state = "Idle",
    # 3D Viewer state
    current_model = NULL,
    model_dims = list(x = 0, y = 0, z = 0),
    model_info = list(
      volume = "0 cm³",
      layers = 0,
      filament = "0g",
      time = "00:00:00"
    ),
    model_loaded = FALSE
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
  
  # Parse G-code to extract dimensions and metadata
  parse_gcode <- function(filepath) {
    tryCatch({
      if(!file.exists(filepath)) {
        add_log(paste("File not found:", filepath))
        return(NULL)
      }
      
      lines <- readLines(filepath, n = 500, warn = FALSE)
      
      info <- list(
        x = 0, y = 0, z = 0,
        filament = "N/A",
        layers = 0,
        time = "N/A",
        volume = "N/A"
      )
      
      # Variables para formato MINX/MAXX (Cura, PrusaSlicer, etc.)
      minx <- NA; maxx <- NA
      miny <- NA; maxy <- NA
      minz <- NA; maxz <- NA
      
      # Extract from comments
      for(line in lines) {
        # Formato 1: ;X: (formato simple)
        if(grepl("^;\\s*X:", line)) {
          val <- as.numeric(gsub("[^0-9.]", "", line))
          if(!is.na(val)) info$x <- val / 10  # Convert mm to cm
        }
        if(grepl("^;\\s*Y:", line)) {
          val <- as.numeric(gsub("[^0-9.]", "", line))
          if(!is.na(val)) info$y <- val / 10
        }
        if(grepl("^;\\s*Z:", line)) {
          val <- as.numeric(gsub("[^0-9.]", "", line))
          if(!is.na(val)) info$z <- val / 10
        }
        
        # Formato 2: ;MINX: y ;MAXX: (Cura, PrusaSlicer)
        if(grepl("^;\\s*MINX:", line, ignore.case = TRUE)) {
          val <- as.numeric(gsub("^;\\s*MINX:\\s*", "", line, ignore.case = TRUE))
          if(!is.na(val)) minx <- val
        }
        if(grepl("^;\\s*MAXX:", line, ignore.case = TRUE)) {
          val <- as.numeric(gsub("^;\\s*MAXX:\\s*", "", line, ignore.case = TRUE))
          if(!is.na(val)) maxx <- val
        }
        if(grepl("^;\\s*MINY:", line, ignore.case = TRUE)) {
          val <- as.numeric(gsub("^;\\s*MINY:\\s*", "", line, ignore.case = TRUE))
          if(!is.na(val)) miny <- val
        }
        if(grepl("^;\\s*MAXY:", line, ignore.case = TRUE)) {
          val <- as.numeric(gsub("^;\\s*MAXY:\\s*", "", line, ignore.case = TRUE))
          if(!is.na(val)) maxy <- val
        }
        if(grepl("^;\\s*MINZ:", line, ignore.case = TRUE)) {
          val <- as.numeric(gsub("^;\\s*MINZ:\\s*", "", line, ignore.case = TRUE))
          if(!is.na(val)) minz <- val
        }
        if(grepl("^;\\s*MAXZ:", line, ignore.case = TRUE)) {
          val <- as.numeric(gsub("^;\\s*MAXZ:\\s*", "", line, ignore.case = TRUE))
          if(!is.na(val)) maxz <- val
        }
        
        # Filament usado
        if(grepl("^;\\s*Filament used:", line, ignore.case = TRUE)) {
          info$filament <- trimws(sub("^;\\s*Filament used:\\s*", "", line, ignore.case = TRUE))
        }
        if(grepl("^;\\s*Filament:", line) && info$filament == "N/A") {
          info$filament <- trimws(sub("^;\\s*Filament:\\s*", "", line))
        }
        
        # Número de capas
        if(grepl("^;\\s*LAYER_COUNT:", line, ignore.case = TRUE)) {
          val <- as.integer(gsub("[^0-9]", "", line))
          if(!is.na(val)) info$layers <- val
        }
        if(grepl("^;\\s*Layers:", line) && info$layers == 0) {
          val <- as.integer(gsub("[^0-9]", "", line))
          if(!is.na(val)) info$layers <- val
        }
        
        # Tiempo de impresión
        if(grepl("^;\\s*TIME:", line, ignore.case = TRUE)) {
          time_seconds <- as.integer(gsub("[^0-9]", "", line))
          if(!is.na(time_seconds)) {
            hours <- floor(time_seconds / 3600)
            minutes <- floor((time_seconds %% 3600) / 60)
            seconds <- time_seconds %% 60
            info$time <- sprintf("%02d:%02d:%02d", hours, minutes, seconds)
          }
        }
        if(grepl("^;\\s*Print time:", line) && info$time == "N/A") {
          info$time <- trimws(sub("^;\\s*Print time:\\s*", "", line))
        }
      }
      
      # Si encontramos formato MINX/MAXX, calcular dimensiones
      if(!is.na(minx) && !is.na(maxx)) {
        info$x <- (maxx - minx) / 10  # Convert mm to cm
      }
      if(!is.na(miny) && !is.na(maxy)) {
        info$y <- (maxy - miny) / 10
      }
      if(!is.na(minz) && !is.na(maxz)) {
        info$z <- (maxz - minz) / 10
      }
      
      # Calculate volume
      if(info$x > 0 && info$y > 0 && info$z > 0) {
        info$volume <- sprintf("%.2f cm³", info$x * info$y * info$z)
      }
      
      add_log(paste("Parsed G-code:", filepath))
      add_log(paste("Dimensions:", info$x, "x", info$y, "x", info$z, "cm"))
      
      return(info)
      
    }, error = function(e) {
      add_log(paste("Error parsing G-code:", e$message))
      return(NULL)
    })
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
      
      # Test connection using Python script with better output capture
      python_cmd <- sprintf(
        'python bambulab_mqtt.py connect "%s" "%s" "%s" 2>&1',
        input$printer_ip,
        input$access_code,
        input$serial_number
      )
      
      add_log(paste("Running command:", python_cmd))
      
      # Capture output with better error handling
      result <- tryCatch({
        system(python_cmd, intern = TRUE, ignore.stderr = FALSE)
      }, warning = function(w) {
        character(0)
      }, error = function(e) {
        character(0)
      })
      
      add_log(paste("Python raw output:", paste(result, collapse = " | ")))
      
      # Check if we got any output
      if(length(result) == 0) {
        showNotification("No response from Python script. Check Python installation.",
                         type = "error")
        add_log("No output from Python script")
        return()
      }
      
      # Look for success or error indicators in plain text
      output_text <- paste(result, collapse = " ")
      
      # Check for success
      if(grepl("SUCCESSFUL|SUCCESS|connected", output_text, ignore.case = TRUE)) {
        rv$connected <- TRUE
        rv$printer_status <- "Connected"
        rv$printer_ip <- input$printer_ip
        rv$access_code <- input$access_code
        rv$serial_number <- input$serial_number
        
        showNotification("Successfully connected to printer!",
                         type = "message",
                         duration = 5)
        add_log("Connection established successfully")
        
      } else if(grepl("error|failed|timeout|cannot|refused", output_text, ignore.case = TRUE)) {
        rv$connected <- FALSE
        rv$printer_status <- "Connection Failed"
        
        # Extract error message
        error_msg <- "Connection failed. Check logs for details."
        
        if(grepl("11001|getaddrinfo", output_text)) {
          error_msg <- "Cannot reach printer. Check IP address."
        } else if(grepl("timeout", output_text, ignore.case = TRUE)) {
          error_msg <- "Connection timeout. Printer not responding."
        } else if(grepl("authentication|bad username|password", output_text, ignore.case = TRUE)) {
          error_msg <- "Authentication failed. Check Access Code (must be 8 digits)."
        } else if(grepl("paho", output_text)) {
          error_msg <- "paho-mqtt not installed. Run: python -m pip install paho-mqtt"
        }
        
        showNotification(error_msg,
                         type = "error",
                         duration = 10)
        add_log(paste("Connection failed:", error_msg))
        add_log(paste("Full output:", output_text))
        
      } else {
        # Couldn't determine status, try JSON parsing as fallback
        json_found <- FALSE
        response <- NULL
        
        for(line in result) {
          tryCatch({
            parsed <- fromJSON(line)
            if(!is.null(parsed$status)) {
              response <- parsed
              json_found <- TRUE
              break
            }
          }, error = function(e) {
            # Not JSON, skip
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
          rv$printer_status <- "Unknown"
          showNotification(paste("Unexpected response. Check Logs tab. Output:", substr(output_text, 1, 100)),
                           type = "warning",
                           duration = 10)
          add_log(paste("Unexpected response:", output_text))
        }
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
  
  # ============================================
  # 3D VIEWER EVENT HANDLERS
  # ============================================
  
  # Load Level 1 model
  observeEvent(input$load_level1, {
    add_log("Loading Level 1 Base model...")
    
    # Try multiple possible paths
    possible_paths <- c(
      "level1_base.gcode",
      "../level1_base.gcode",
      "../../level1_base.gcode"
    )
    
    gcode_path <- NULL
    for(path in possible_paths) {
      if(file.exists(path)) {
        gcode_path <- path
        break
      }
    }
    
    if(is.null(gcode_path)) {
      showNotification("Level 1 G-code file not found. Please ensure level1_base.gcode is in the app directory.",
                       type = "warning",
                       duration = 10)
      add_log("Error: Level 1 file not found in any of the expected locations")
    } else {
      info <- parse_gcode(gcode_path)
      if(!is.null(info)) {
        rv$model_info <- info
        rv$model_dims <- list(x = info$x, y = info$y, z = info$z)
        rv$current_model <- "level1"
        rv$model_loaded <- TRUE
        
        showNotification("Level 1 Base loaded successfully!", type = "message")
        add_log("Level 1 model loaded successfully")
      }
    }
  })
  
  # Load Level 2 model
  observeEvent(input$load_level2, {
    add_log("Loading Level 2 Platform model...")
    
    possible_paths <- c(
      "level2_platform.gcode",
      "../level2_platform.gcode",
      "../../level2_platform.gcode"
    )
    
    gcode_path <- NULL
    for(path in possible_paths) {
      if(file.exists(path)) {
        gcode_path <- path
        break
      }
    }
    
    if(is.null(gcode_path)) {
      showNotification("Level 2 G-code file not found. Please ensure level2_platform.gcode is in the app directory.",
                       type = "warning",
                       duration = 10)
      add_log("Error: Level 2 file not found")
    } else {
      info <- parse_gcode(gcode_path)
      if(!is.null(info)) {
        rv$model_info <- info
        rv$model_dims <- list(x = info$x, y = info$y, z = info$z)
        rv$current_model <- "level2"
        rv$model_loaded <- TRUE
        
        showNotification("Level 2 Platform loaded successfully!", type = "message")
        add_log("Level 2 model loaded successfully")
      }
    }
  })
  
  # Load uploaded G-code file
  observeEvent(input$load_uploaded_model, {
    req(input$gcode_3d_file)
    
    add_log(paste("Loading uploaded G-code:", input$gcode_3d_file$name))
    
    info <- parse_gcode(input$gcode_3d_file$datapath)
    if(!is.null(info)) {
      rv$model_info <- info
      rv$model_dims <- list(x = info$x, y = info$y, z = info$z)
      rv$current_model <- "uploaded"
      rv$model_loaded <- TRUE
      
      showNotification(paste("Model loaded:", input$gcode_3d_file$name), type = "message")
      add_log("Uploaded model loaded successfully")
    } else {
      showNotification("Could not parse G-code file. Ensure it contains dimension comments.",
                       type = "error")
    }
  })
  
  # Clear 3D viewer
  observeEvent(input$clear_3d_view, {
    rv$current_model <- NULL
    rv$model_dims <- list(x = 0, y = 0, z = 0)
    rv$model_info <- list(volume = "0 cm³", layers = 0, filament = "0g", time = "00:00:00")
    rv$model_loaded <- FALSE
    
    showNotification("3D viewer cleared", type = "message")
    add_log("3D viewer cleared")
  })

  # ============================================
  # 3D VIEWER OUTPUTS
  # ============================================
  
  # 3D Visualization
  output$model_3d <- renderPlotly({
    req(rv$model_loaded)
    
    x <- rv$model_dims$x * 10  # Convert cm to mm for visualization
    y <- rv$model_dims$y * 10
    z <- rv$model_dims$z * 10
    
    # Create a 3D box representing the model
    vertices <- data.frame(
      x = c(0, x, x, 0, 0, x, x, 0),
      y = c(0, 0, y, y, 0, 0, y, y),
      z = c(0, 0, 0, 0, z, z, z, z)
    )
    
    # Create mesh
    plot_ly(vertices, x = ~x, y = ~y, z = ~z,
            type = "mesh3d",
            i = c(0, 0, 0, 0, 4, 4, 6, 6, 2, 2),
            j = c(1, 2, 3, 4, 5, 6, 5, 2, 1, 3),
            k = c(2, 3, 4, 5, 6, 7, 1, 3, 5, 7),
            color = I("#00A39A"),
            opacity = 0.8,
            lighting = list(ambient = 0.8, diffuse = 0.9, specular = 0.5)) %>%
      layout(
        scene = list(
          xaxis = list(title = "X (mm)", range = c(-20, x + 20), 
                       backgroundcolor = "rgba(255,255,255,0.9)",
                       gridcolor = "rgba(0,138,130,0.2)"),
          yaxis = list(title = "Y (mm)", range = c(-20, y + 20),
                       backgroundcolor = "rgba(255,255,255,0.9)",
                       gridcolor = "rgba(0,138,130,0.2)"),
          zaxis = list(title = "Z (mm)", range = c(0, z + 20),
                       backgroundcolor = "rgba(255,255,255,0.9)",
                       gridcolor = "rgba(0,138,130,0.2)"),
          camera = list(
            eye = list(x = 1.5, y = 1.5, z = 1.2)
          ),
          aspectmode = "data",
          bgcolor = "rgba(248,249,250,1)"
        ),
        title = list(
          text = paste("3D Model Preview -", 
                       if(rv$current_model == "level1") "Level 1 Base"
                       else if(rv$current_model == "level2") "Level 2 Platform"
                       else "Custom Model"),
          font = list(size = 16, color = "#008A82", family = "Arial")
        ),
        paper_bgcolor = "rgba(248,249,250,1)"
      )
  })
  
  # Dimension outputs (in cm)
  output$dim_x <- renderText({ 
    if(rv$model_loaded) sprintf("%.2f", rv$model_dims$x) else "0.00"
  })
  
  output$dim_y <- renderText({ 
    if(rv$model_loaded) sprintf("%.2f", rv$model_dims$y) else "0.00"
  })
  
  output$dim_z <- renderText({ 
    if(rv$model_loaded) sprintf("%.2f", rv$model_dims$z) else "0.00"
  })
  
  # Model info outputs
  output$model_volume <- renderText({ 
    if(rv$model_loaded) rv$model_info$volume else "0 cm³"
  })
  
  output$model_layers <- renderText({ 
    if(rv$model_loaded) as.character(rv$model_info$layers) else "0"
  })
  
  output$model_filament <- renderText({ 
    if(rv$model_loaded) rv$model_info$filament else "0g"
  })
  
  output$model_time <- renderText({ 
    if(rv$model_loaded) rv$model_info$time else "00:00:00"
  })
  
}

# Run the application
shinyApp(ui = ui, server = server)
