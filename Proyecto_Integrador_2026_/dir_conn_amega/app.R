# Servo Control - Continuous Mode
library(shiny)
library(httr)
library(jsonlite)

API_URL <- "http://127.0.0.1:5000"

# ====== UI ======
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%);
        min-height: 100vh;
        padding: 20px;
      }
      
      .main-panel {
        background: white;
        border-radius: 15px;
        padding: 30px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        max-width: 600px;
        margin: 50px auto;
      }
      
      h2 {
        color: #008A82;
        text-align: center;
        margin-bottom: 30px;
      }
      
      .status-box {
        background: linear-gradient(135deg, #e8f5f4 0%, #d4edea 100%);
        padding: 15px;
        border-radius: 10px;
        margin: 20px 0;
        border-left: 5px solid #00A39A;
      }
      
      .status-connected {
        background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%);
        border-left: 5px solid #27ae60;
      }
      
      .status-disconnected {
        background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%);
        border-left: 5px solid #e74c3c;
      }
      
      .btn-primary {
        background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
        border: none !important;
        border-radius: 8px !important;
        color: white !important;
        font-weight: 600;
        padding: 10px 20px;
        width: 100%;
        margin: 5px 0;
      }
      
      .btn-primary:hover {
        background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
        transform: translateY(-2px);
      }
      
      .btn-success {
        background: linear-gradient(135deg, #27ae60 0%, #229954 100%) !important;
        border: none !important;
        border-radius: 8px !important;
        color: white !important;
        font-weight: 600;
        width: 100%;
      }
      
      .btn-warning {
        background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
        border: none !important;
        border-radius: 8px !important;
        color: white !important;
        font-weight: 600;
        width: 100%;
      }
      
      .btn-danger {
        background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
        border: none !important;
        border-radius: 8px !important;
        color: white !important;
        font-weight: 600;
        width: 100%;
      }
      
      .btn-info {
        background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
        border: none !important;
        border-radius: 8px !important;
        color: white !important;
        font-weight: 600;
        width: 100%;
      }
      
      .control-group {
        margin: 20px 0;
      }
      
      .angle-display {
        font-size: 48px;
        font-weight: bold;
        color: #008A82;
        text-align: center;
        margin: 20px 0;
      }
      
      .mode-badge {
        display: inline-block;
        background: linear-gradient(135deg, #27ae60 0%, #229954 100%);
        color: white;
        padding: 8px 15px;
        border-radius: 20px;
        font-size: 13px;
        font-weight: 600;
        margin: 10px 0;
      }
      
      .irs-bar {
        background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
      }
      
      .irs-from, .irs-to, .irs-single {
        background: #00A39A !important;
      }
      
      .server-warning {
        background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
        padding: 15px;
        border-radius: 10px;
        border-left: 5px solid #f39c12;
        margin-bottom: 20px;
      }
    "))
  ),
  
  div(class = "main-panel",
      h2("🎮 Control de Servo - Modo Continuo"),
      
      div(class = "server-warning",
          strong("⚠️ IMPORTANTE:"),
          br(),
          "Asegúrate de ejecutar ", code("python servo_server.py"), " primero"
      ),
      
      div(class = "control-group",
          textInput("port", "Puerto COM:", value = "COM11", placeholder = "COM11"),
          actionButton("btn_connect", "🔌 Conectar", class = "btn-primary"),
          actionButton("btn_disconnect", "⏹️ Desconectar", class = "btn-danger")
      ),
      
      hr(),
      
      uiOutput("connection_status_box"),
      
      hr(),
      
      div(class = "control-group",
          fluidRow(
            column(8,
                   h4("Control Continuo:", style = "color: #008A82;")
            ),
            column(4, align = "right",
                   actionButton("btn_toggle_mode", "▶️ Iniciar Loop", class = "btn-success")
            )
          ),
          
          uiOutput("mode_status"),
          
          div(class = "angle-display",
              textOutput("current_angle")
          ),
          
          sliderInput("angle", 
                      label = "Mover servo en tiempo real:",
                      min = 0, 
                      max = 180, 
                      value = 90, 
                      step = 1,
                      width = "100%")
      ),
      
      hr(),
      
      div(class = "control-group",
          h4("Posiciones Rápidas:", style = "color: #008A82;"),
          fluidRow(
            column(4, actionButton("btn_left", "⬅️ Izquierda (50°)", class = "btn-warning")),
            column(4, actionButton("btn_center", "⏺️ Centro (90°)", class = "btn-primary")),
            column(4, actionButton("btn_right", "➡️ Derecha (130°)", class = "btn-warning"))
          )
      ),
      
      hr(),
      
      div(class = "status-box",
          h4("📡 Estado:"),
          fluidRow(
            column(6,
                   strong("Comandos enviados:"),
                   br(),
                   textOutput("command_count")
            ),
            column(6,
                   strong("Último mensaje:"),
                   br(),
                   textOutput("last_status")
            )
          )
      )
  )
)

# ====== SERVER ======
server <- function(input, output, session) {
  
  # Reactive values
  current_angle_val <- reactiveVal(90)
  is_connected_val <- reactiveVal(FALSE)
  continuous_mode <- reactiveVal(FALSE)
  command_count_val <- reactiveVal(0)
  last_status_val <- reactiveVal("Esperando conexión...")
  last_sent_angle <- reactiveVal(90)
  
  # Conectar
  observeEvent(input$btn_connect, {
    tryCatch({
      response <- POST(
        paste0(API_URL, "/connect"),
        body = toJSON(list(port = input$port), auto_unbox = TRUE),
        encode = "raw",
        add_headers("Content-Type" = "application/json"),
        timeout(5)
      )
      
      result <- content(response, as = "parsed", type = "application/json")
      
      if (!is.null(result$connected) && result$connected == TRUE) {
        is_connected_val(TRUE)
        showNotification("✅ Conectado al Arduino", type = "message", duration = 3)
        last_status_val("Conectado exitosamente")
      } else {
        showNotification("❌ Error al conectar. Verifica el puerto COM.", type = "error", duration = 5)
        last_status_val(paste("Error:", result$message))
      }
    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
      last_status_val(paste("Error de conexión:", e$message))
    })
  })
  
  # Desconectar
  observeEvent(input$btn_disconnect, {
    tryCatch({
      continuous_mode(FALSE)
      response <- POST(
        paste0(API_URL, "/disconnect"),
        encode = "json",
        timeout(5)
      )
      
      is_connected_val(FALSE)
      showNotification("🔌 Desconectado", type = "message", duration = 3)
      last_status_val("Desconectado")
    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Toggle continuous mode
  observeEvent(input$btn_toggle_mode, {
    if (continuous_mode()) {
      continuous_mode(FALSE)
      updateActionButton(session, "btn_toggle_mode", 
                         label = "▶️ Iniciar Loop", 
                         icon = icon("play"))
      last_status_val("Modo continuo detenido")
    } else {
      if (!is_connected_val()) {
        showNotification("⚠️ Conecta primero al Arduino", type = "warning", duration = 3)
        return()
      }
      continuous_mode(TRUE)
      updateActionButton(session, "btn_toggle_mode", 
                         label = "⏸️ Detener Loop", 
                         icon = icon("pause"))
      last_status_val("Modo continuo activo")
    }
  })
  
  # Función para enviar ángulo
  send_angle_to_arduino <- function(angle) {
    if (!is_connected_val()) {
      return(FALSE)
    }
    
    tryCatch({
      response <- POST(
        paste0(API_URL, "/angle"),
        body = toJSON(list(angle = angle), auto_unbox = TRUE),
        encode = "raw",
        add_headers("Content-Type" = "application/json"),
        timeout(1)
      )
      
      result <- content(response, as = "parsed", type = "application/json")
      
      if (result$status == "success") {
        current_angle_val(angle)
        last_sent_angle(angle)
        command_count_val(command_count_val() + 1)
        return(TRUE)
      }
      return(FALSE)
    }, error = function(e) {
      return(FALSE)
    })
  }
  
  # Continuous loop - 4 times per second (250ms)
  observe({
    if (continuous_mode() && is_connected_val()) {
      invalidateLater(250, session)  # 4 times per second
      
      target_angle <- input$angle
      
      # Only send if angle changed
      if (target_angle != last_sent_angle()) {
        send_angle_to_arduino(target_angle)
        last_status_val(paste("Enviando:", target_angle, "°"))
      }
    }
  })
  
  # Botones rápidos
  observeEvent(input$btn_left, {
    updateSliderInput(session, "angle", value = 50)
  })
  
  observeEvent(input$btn_center, {
    updateSliderInput(session, "angle", value = 90)
  })
  
  observeEvent(input$btn_right, {
    updateSliderInput(session, "angle", value = 130)
  })
  
  # Auto-refresh connection status
  observe({
    invalidateLater(2000, session)
    
    if (!continuous_mode()) {  # Don't interfere with continuous mode
      tryCatch({
        response <- GET(paste0(API_URL, "/status"), timeout(1))
        result <- content(response, as = "parsed", type = "application/json")
        
        if (!is.null(result$connected)) {
          is_connected_val(result$connected)
        }
      }, error = function(e) {
        # Silently fail
      })
    }
  })
  
  # Outputs
  output$connection_status_box <- renderUI({
    if (is_connected_val()) {
      div(class = "status-box status-connected",
          h4("✅ Estado: CONECTADO"),
          p(paste("Puerto:", input$port))
      )
    } else {
      div(class = "status-box status-disconnected",
          h4("❌ Estado: DESCONECTADO"),
          p("Haz clic en 'Conectar' para iniciar")
      )
    }
  })
  
  output$mode_status <- renderUI({
    if (continuous_mode()) {
      div(
        span(class = "mode-badge", "🔄 Modo Continuo ACTIVO - 4Hz")
      )
    } else {
      div(
        p(style = "color: #666; font-size: 14px;", 
          "El servo seguirá el slider en tiempo real cuando el loop esté activo")
      )
    }
  })
  
  output$current_angle <- renderText({
    paste0(current_angle_val(), "°")
  })
  
  output$command_count <- renderText({
    paste0(command_count_val(), " comandos")
  })
  
  output$last_status <- renderText({
    last_status_val()
  })
}

# ====== RUN APP ======
shinyApp(ui = ui, server = server)