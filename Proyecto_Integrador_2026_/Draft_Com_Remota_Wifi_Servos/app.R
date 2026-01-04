# robot_control_dashboard.R
# Dashboard de control para robot móvil - Versión con diseño personalizado

library(shiny)
library(httr)
library(jsonlite)
library(shinydashboard)

# ====== CONFIGURACIÓN ======
JETSON_IP <- "192.168.1.100"  # <-- CAMBIAR POR IP DE TU JETSON
JETSON_PORT <- "5000"
API_URL <- paste0("http://", JETSON_IP, ":", JETSON_PORT)

# ====== FUNCIONES DE API ======

obtener_status <- function() {
  tryCatch({
    response <- GET(paste0(API_URL, "/status"))
    if (status_code(response) == 200) {
      return(content(response, "parsed"))
    } else {
      return(list(conectado = FALSE, error = "No se pudo conectar"))
    }
  }, error = function(e) {
    return(list(conectado = FALSE, error = as.character(e)))
  })
}

enviar_comando <- function(endpoint, datos = list()) {
  tryCatch({
    response <- POST(
      paste0(API_URL, endpoint),
      body = datos,
      encode = "json",
      content_type_json()
    )
    return(content(response, "parsed"))
  }, error = function(e) {
    return(list(status = "error", message = as.character(e)))
  })
}

# ====== CSS PERSONALIZADO ======

custom_css <- "
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

/* Sliders */
.irs-bar {
  background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
  border-top: 1px solid #008A82 !important;
}

.irs-from, .irs-to, .irs-single {
  background: #00A39A !important;
}

.irs-handle {
  border: 3px solid #008A82 !important;
  background: white !important;
}

/* Buttons */
.btn-primary {
  background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0, 138, 130, 0.3) !important;
}

.btn-primary:hover {
  background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 138, 130, 0.4) !important;
}

.btn-success {
  background: linear-gradient(135deg, #27ae60 0%, #229954 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
  box-shadow: 0 4px 15px rgba(39, 174, 96, 0.3) !important;
}

.btn-success:hover {
  background: linear-gradient(135deg, #229954 0%, #1e8449 100%) !important;
  transform: translateY(-2px);
}

.btn-info {
  background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
  box-shadow: 0 4px 15px rgba(52, 152, 219, 0.3) !important;
}

.btn-info:hover {
  background: linear-gradient(135deg, #2980b9 0%, #21618c 100%) !important;
  transform: translateY(-2px);
}

.btn-danger {
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
  box-shadow: 0 4px 15px rgba(231, 76, 60, 0.3) !important;
}

.btn-danger:hover {
  background: linear-gradient(135deg, #c0392b 0%, #a93226 100%) !important;
  transform: translateY(-2px);
}

.btn-warning {
  background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
  box-shadow: 0 4px 15px rgba(243, 156, 18, 0.3) !important;
}

.btn-warning:hover {
  background: linear-gradient(135deg, #e67e22 0%, #d35400 100%) !important;
  transform: translateY(-2px);
}

/* Large control buttons */
.btn-lg {
  padding: 12px 24px !important;
  font-size: 16px !important;
  min-width: 160px;
  transition: all 0.3s ease;
}

/* Value boxes */
.small-box {
  border-radius: 12px !important;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
  transition: transform 0.2s ease;
}

.small-box:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2) !important;
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

.small-box.bg-red { 
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
}

/* Info boxes */
.info-box {
  border-radius: 12px !important;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1) !important;
  background: white !important;
  transition: transform 0.2s ease;
}

.info-box:hover {
  transform: translateY(-2px);
}

.info-box-icon {
  border-radius: 12px 0 0 12px !important;
}

/* Dimension cards */
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
  font-family: 'Courier New', monospace;
}

.dimension-unit {
  font-size: 18px;
  color: #00A39A;
  margin-left: 5px;
}

/* Stats grid */
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
  transition: transform 0.2s ease;
}

.stat-item:hover {
  transform: translateY(-2px);
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

/* Badges */
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

.warning-badge {
  display: inline-block;
  background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
  color: white;
  padding: 8px 15px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
  margin: 5px;
  box-shadow: 0 3px 10px rgba(243, 156, 18, 0.3);
}

.danger-badge {
  display: inline-block;
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
  color: white;
  padding: 8px 15px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
  margin: 5px;
  box-shadow: 0 3px 10px rgba(231, 76, 60, 0.3);
}

/* Control panel styling */
.control-panel {
  background: white;
  padding: 25px;
  border-radius: 12px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.control-section {
  margin: 20px 0;
}

.control-section-title {
  color: #008A82;
  font-weight: 600;
  font-size: 18px;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 2px solid #00A39A;
}

/* Response output */
.response-output {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  padding: 15px;
  border-radius: 8px;
  border-left: 4px solid #008A82;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  max-height: 300px;
  overflow-y: auto;
}

/* Direction buttons grid */
.direction-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  grid-template-rows: auto auto auto;
  gap: 10px;
  max-width: 500px;
  margin: 20px auto;
}

.dir-forward { grid-column: 2; grid-row: 1; }
.dir-left { grid-column: 1; grid-row: 2; }
.dir-stop { grid-column: 2; grid-row: 2; }
.dir-right { grid-column: 3; grid-row: 2; }
.dir-backward { grid-column: 2; grid-row: 3; }

/* Animations */
@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

.active-control {
  animation: pulse 1s infinite;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #008A82 0%, #00A39A 100%);
  border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #006b63 0%, #007d75 100%);
}
"

# ====== UI ======

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = tags$span(
      icon("robot"),
      "Control Robot Móvil"
    )
  ),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("🎮 Control Manual", tabName = "control", icon = icon("gamepad")),
      menuItem("📊 Estado & Métricas", tabName = "status", icon = icon("chart-line")),
      menuItem("⚙️ Configuración", tabName = "config", icon = icon("cog"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML(custom_css))
    ),
    
    tabItems(
      # ====== TAB: CONTROL MANUAL ======
      tabItem(
        tabName = "control",
        
        fluidRow(
          # Control de Movimiento
          box(
            title = tags$span(icon("arrows-alt"), " Control de Movimiento"),
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            div(class = "control-panel",
                div(class = "direction-grid",
                    div(class = "dir-forward",
                        actionButton("btn_forward", 
                                     HTML("<i class='fa fa-arrow-up'></i><br>ADELANTE"), 
                                     class = "btn-lg btn-success",
                                     style = "width: 100%; height: 80px;")
                    ),
                    div(class = "dir-left",
                        actionButton("btn_left", 
                                     HTML("<i class='fa fa-arrow-left'></i><br>IZQUIERDA"), 
                                     class = "btn-lg btn-info",
                                     style = "width: 100%; height: 80px;")
                    ),
                    div(class = "dir-stop",
                        actionButton("btn_stop", 
                                     HTML("<i class='fa fa-stop'></i><br>DETENER"), 
                                     class = "btn-lg btn-danger",
                                     style = "width: 100%; height: 80px;")
                    ),
                    div(class = "dir-right",
                        actionButton("btn_right", 
                                     HTML("<i class='fa fa-arrow-right'></i><br>DERECHA"), 
                                     class = "btn-lg btn-info",
                                     style = "width: 100%; height: 80px;")
                    ),
                    div(class = "dir-backward",
                        actionButton("btn_backward", 
                                     HTML("<i class='fa fa-arrow-down'></i><br>ATRÁS"), 
                                     class = "btn-lg btn-warning",
                                     style = "width: 100%; height: 80px;")
                    )
                ),
                
                hr(),
                
                div(class = "control-section",
                    div(class = "control-section-title", "⚡ Velocidad de Movimiento"),
                    sliderInput("velocidad", 
                                label = NULL,
                                min = 0, 
                                max = 180, 
                                value = 100, 
                                step = 5,
                                width = "100%")
                )
            )
          ),
          
          # Control de Cabeza y Brazo
          box(
            title = tags$span(icon("sliders-h"), " Servos Auxiliares"),
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            div(class = "control-panel",
                div(class = "control-section",
                    div(class = "control-section-title", 
                        HTML("<i class='fa fa-video'></i> Control de Cabeza/Sensor")),
                    sliderInput("angulo_cabeza", 
                                label = "Ángulo (0-180°):",
                                min = 0, 
                                max = 180, 
                                value = 90, 
                                step = 5,
                                width = "100%"),
                    actionButton("btn_move_head", 
                                 HTML("<i class='fa fa-sync-alt'></i> Mover Cabeza"), 
                                 class = "btn-primary btn-block")
                ),
                
                hr(),
                
                div(class = "control-section",
                    div(class = "control-section-title", 
                        HTML("<i class='fa fa-hand-paper'></i> Control de Brazo/Garra")),
                    sliderInput("angulo_brazo", 
                                label = "Ángulo (0-180°):",
                                min = 0, 
                                max = 180, 
                                value = 90, 
                                step = 5,
                                width = "100%"),
                    actionButton("btn_move_arm", 
                                 HTML("<i class='fa fa-sync-alt'></i> Mover Brazo"), 
                                 class = "btn-primary btn-block")
                )
            )
          )
        ),
        
        # Respuesta del Sistema
        fluidRow(
          box(
            title = tags$span(icon("terminal"), " Respuesta del Sistema"),
            status = "success",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            
            div(class = "response-output",
                verbatimTextOutput("response_output")
            )
          )
        )
      ),
      
      # ====== TAB: ESTADO ======
      tabItem(
        tabName = "status",
        
        # Value Boxes
        fluidRow(
          valueBoxOutput("status_conexion", width = 3),
          valueBoxOutput("velocidad_actual", width = 3),
          valueBoxOutput("ultimo_comando", width = 3),
          valueBoxOutput("timestamp", width = 3)
        ),
        
        # Estado detallado
        fluidRow(
          box(
            title = tags$span(icon("info-circle"), " Estado del Robot"),
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            div(class = "stats-grid",
                div(class = "stat-item",
                    div(class = "stat-label", "Motor Izquierdo"),
                    div(class = "stat-value", textOutput("vel_izq_display"))
                ),
                div(class = "stat-item",
                    div(class = "stat-label", "Motor Derecho"),
                    div(class = "stat-value", textOutput("vel_der_display"))
                ),
                div(class = "stat-item",
                    div(class = "stat-label", "Posición Cabeza"),
                    div(class = "stat-value", textOutput("pos_cabeza_display"))
                ),
                div(class = "stat-item",
                    div(class = "stat-label", "Posición Brazo"),
                    div(class = "stat-value", textOutput("pos_brazo_display"))
                )
            )
          ),
          
          box(
            title = tags$span(icon("code"), " Estado Completo (JSON)"),
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            div(class = "response-output",
                verbatimTextOutput("status_completo")
            )
          )
        ),
        
        fluidRow(
          box(
            title = tags$span(icon("history"), " Historial de Comandos"),
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            actionButton("btn_refresh", 
                         HTML("<i class='fa fa-sync'></i> Actualizar Estado"), 
                         class = "btn-success"),
            
            hr(),
            
            div(style = "margin-top: 15px;",
                uiOutput("command_history")
            )
          )
        )
      ),
      
      # ====== TAB: CONFIGURACIÓN ======
      tabItem(
        tabName = "config",
        
        fluidRow(
          box(
            title = tags$span(icon("network-wired"), " Configuración de Conexión"),
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            
            div(class = "control-panel",
                textInput("config_ip", 
                          "IP del Jetson Nano:", 
                          value = JETSON_IP,
                          placeholder = "192.168.1.100"),
                
                textInput("config_port", 
                          "Puerto:", 
                          value = JETSON_PORT,
                          placeholder = "5000"),
                
                actionButton("btn_test_connection", 
                             HTML("<i class='fa fa-plug'></i> Probar Conexión"), 
                             class = "btn-info btn-block"),
                
                hr(),
                
                div(id = "connection_result",
                    uiOutput("connection_status_ui")
                )
            )
          ),
          
          box(
            title = tags$span(icon("book"), " Endpoints Disponibles"),
            status = "info",
            solidHeader = TRUE,
            width = 6,
            
            div(class = "control-panel",
                h4(style = "color: #008A82; font-weight: 600;", "API REST Endpoints:"),
                
                tags$div(class = "info-badge", "/status"),
                tags$div(class = "success-badge", "/forward"),
                tags$div(class = "success-badge", "/backward"),
                tags$div(class = "info-badge", "/turn_left"),
                tags$div(class = "info-badge", "/turn_right"),
                tags$div(class = "danger-badge", "/stop"),
                tags$div(class = "warning-badge", "/head"),
                tags$div(class = "warning-badge", "/arm"),
                tags$div(class = "success-badge", "/move"),
                tags$div(class = "info-badge", "/command"),
                
                hr(),
                
                p(strong("URL Base:"), code(textOutput("api_url_display", inline = TRUE))),
                p(strong("Método:"), code("POST (JSON)")),
                p(strong("Formato:"), code('{"speed": 100}'))
            )
          )
        ),
        
        fluidRow(
          box(
            title = tags$span(icon("question-circle"), " Información del Sistema"),
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            div(class = "control-panel",
                h4(style = "color: #008A82;", "Arquitectura del Sistema:"),
                
                tags$pre(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #008A82;",
                         '┌─────────────────┐
│   PC/Laptop     │
│   R Shiny App   │ ← Tú estás aquí
└────────┬────────┘
         │ HTTP/JSON via WiFi
         ▼
┌─────────────────┐
│  Jetson Nano    │
│  Flask API      │
│  IP: ', JETSON_IP, '
└────────┬────────┘
         │ USB Serial
         ▼
┌─────────────────┐
│  Arduino Mega   │
│  Control Servos │
└────────┬────────┘
         │ PWM
         ▼
┌─────────────────┐
│  Robot Móvil    │
│  Servos         │
└─────────────────┘'
                ),
                
                hr(),
                
                div(class = "stats-grid",
                    div(class = "dimension-card",
                        div(class = "dimension-label", "Versión"),
                        div(class = "dimension-value", "1.0", 
                            tags$span(class = "dimension-unit", "beta"))
                    ),
                    div(class = "dimension-card",
                        div(class = "dimension-label", "Protocolo"),
                        div(class = "dimension-value", "REST", 
                            tags$span(class = "dimension-unit", "API"))
                    ),
                    div(class = "dimension-card",
                        div(class = "dimension-label", "Latencia"),
                        div(class = "dimension-value", "~50", 
                            tags$span(class = "dimension-unit", "ms"))
                    )
                )
            )
          )
        )
      )
    )
  )
)

# ====== SERVER ======

server <- function(input, output, session) {
  
  # Variables reactivas
  ultima_respuesta <- reactiveVal("")
  command_history_list <- reactiveVal(list())
  
  # Función para agregar al historial
  add_to_history <- function(comando, respuesta) {
    history <- command_history_list()
    timestamp <- format(Sys.time(), "%H:%M:%S")
    
    new_entry <- list(
      timestamp = timestamp,
      comando = comando,
      respuesta = respuesta
    )
    
    history <- c(list(new_entry), history)
    if (length(history) > 10) history <- history[1:10]
    
    command_history_list(history)
  }
  
  # ====== BOTONES DE MOVIMIENTO ======
  
  observeEvent(input$btn_forward, {
    resultado <- enviar_comando("/forward", list(speed = input$velocidad))
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("ADELANTE", paste("Velocidad:", input$velocidad))
  })
  
  observeEvent(input$btn_backward, {
    resultado <- enviar_comando("/backward", list(speed = input$velocidad))
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("ATRÁS", paste("Velocidad:", input$velocidad))
  })
  
  observeEvent(input$btn_left, {
    resultado <- enviar_comando("/turn_left", list(speed = input$velocidad))
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("GIRAR IZQUIERDA", paste("Velocidad:", input$velocidad))
  })
  
  observeEvent(input$btn_right, {
    resultado <- enviar_comando("/turn_right", list(speed = input$velocidad))
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("GIRAR DERECHA", paste("Velocidad:", input$velocidad))
  })
  
  observeEvent(input$btn_stop, {
    resultado <- enviar_comando("/stop")
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("DETENER", "Robot detenido")
  })
  
  # ====== CONTROL DE CABEZA Y BRAZO ======
  
  observeEvent(input$btn_move_head, {
    resultado <- enviar_comando("/head", list(angle = input$angulo_cabeza))
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("MOVER CABEZA", paste("Ángulo:", input$angulo_cabeza, "°"))
  })
  
  observeEvent(input$btn_move_arm, {
    resultado <- enviar_comando("/arm", list(angle = input$angulo_brazo))
    ultima_respuesta(toJSON(resultado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("MOVER BRAZO", paste("Ángulo:", input$angulo_brazo, "°"))
  })
  
  # ====== TEST DE CONEXIÓN ======
  
  observeEvent(input$btn_test_connection, {
    tryCatch({
      test_url <- paste0("http://", input$config_ip, ":", input$config_port, "/status")
      response <- GET(test_url)
      
      if (status_code(response) == 200) {
        showNotification("✅ Conexión exitosa!", type = "message", duration = 3)
        add_to_history("TEST CONEXIÓN", "Exitoso")
      } else {
        showNotification("❌ Error de conexión", type = "error", duration = 3)
        add_to_history("TEST CONEXIÓN", "Fallido")
      }
    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
      add_to_history("TEST CONEXIÓN", paste("Error:", e$message))
    })
  })
  
  # ====== OUTPUTS ======
  
  output$response_output <- renderText({
    if (ultima_respuesta() == "") {
      "Esperando comandos..."
    } else {
      ultima_respuesta()
    }
  })
  
  # Estado del robot (auto-refresh cada 2 segundos)
  estado_robot <- reactivePoll(2000, session,
                               checkFunc = function() { Sys.time() },
                               valueFunc = function() { obtener_status() }
  )
  
  # Value Boxes
  output$status_conexion <- renderValueBox({
    estado <- estado_robot()
    valueBox(
      if(estado$conectado) "CONECTADO" else "DESCONECTADO",
      "Estado de Conexión",
      icon = icon(if(estado$conectado) "wifi" else "wifi"),
      color = if(estado$conectado) "aqua" else "red"
    )
  })
  
  output$velocidad_actual <- renderValueBox({
    estado <- estado_robot()
    vel_promedio <- round((as.numeric(estado$velocidad_izq) + as.numeric(estado$velocidad_der)) / 2)
    valueBox(
      vel_promedio,
      "Velocidad Promedio",
      icon = icon("tachometer-alt"),
      color = "blue"
    )
  })
  
  output$ultimo_comando <- renderValueBox({
    estado <- estado_robot()
    valueBox(
      estado$ultimo_comando,
      "Último Comando",
      icon = icon("terminal"),
      color = "green"
    )
  })
  
  output$timestamp <- renderValueBox({
    estado <- estado_robot()
    valueBox(
      if(!is.null(estado$timestamp)) {
        format(as.POSIXct(estado$timestamp, origin = "1970-01-01"), "%H:%M:%S")
      } else {
        "N/A"
      },
      "Última Actualización",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  # Displays individuales
  output$vel_izq_display <- renderText({
    estado <- estado_robot()
    paste0(estado$velocidad_izq, "°")
  })
  
  output$vel_der_display <- renderText({
    estado <- estado_robot()
    paste0(estado$velocidad_der, "°")
  })
  
  output$pos_cabeza_display <- renderText({
    estado <- estado_robot()
    paste0(estado$posicion_cabeza, "°")
  })
  
  output$pos_brazo_display <- renderText({
    estado <- estado_robot()
    paste0(estado$posicion_brazo, "°")
  })
  
  output$status_completo <- renderText({
    estado <- estado_robot()
    toJSON(estado, auto_unbox = TRUE, pretty = TRUE)
  })
  
  output$api_url_display <- renderText({
    paste0("http://", input$config_ip, ":", input$config_port)
  })
  
  # Historial de comandos
  output$command_history <- renderUI({
    history <- command_history_list()
    
    if (length(history) == 0) {
      return(div(class = "status-info", "No hay comandos en el historial"))
    }
    
    lapply(history, function(entry) {
      div(class = "status-success",
          strong(entry$timestamp), " - ",
          tags$span(class = "info-badge", entry$comando),
          br(),
          entry$respuesta
      )
    })
  })
  
  # Status de conexión UI
  output$connection_status_ui <- renderUI({
    estado <- estado_robot()
    
    if (estado$conectado) {
      div(class = "status-success",
          icon("check-circle"),
          strong(" Robot Conectado"),
          br(),
          "Comunicación establecida correctamente"
      )
    } else {
      div(class = "status-error",
          icon("exclamation-triangle"),
          strong(" Robot Desconectado"),
          br(),
          "Verifica la IP y que el servidor API esté corriendo"
      )
    }
  })
  
  observeEvent(input$btn_refresh, {
    estado <- obtener_status()
    ultima_respuesta(toJSON(estado, auto_unbox = TRUE, pretty = TRUE))
    add_to_history("ACTUALIZAR ESTADO", "Estado actualizado manualmente")
  })
}

# ====== EJECUTAR APP ======
shinyApp(ui = ui, server = server)