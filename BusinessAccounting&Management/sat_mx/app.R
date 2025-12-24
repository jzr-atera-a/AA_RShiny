library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(lubridate)
library(openxlsx)

# UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Declaración SAT México"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Datos Personales", tabName = "datos", icon = icon("user")),
      menuItem("Ingresos por Nómina", tabName = "nomina", icon = icon("money-bill-wave")),
      menuItem("Liquidación", tabName = "liquidacion", icon = icon("hand-holding-usd")),
      menuItem("Reporte Final", tabName = "reporte", icon = icon("file-alt"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
      .skin-blue .main-header .navbar {
        background-color: #008A82 !important;
      }
      .skin-blue .main-header .logo {
        background-color: #002C3C !important;
      }
      .skin-blue .main-header .logo:hover {
        background-color: #008A82 !important;
      }
      .skin-blue .main-sidebar {
        background-color: #00A39A !important;
      }
      .skin-blue .sidebar-menu > li.header {
        background: #008A82 !important;
        color: white !important;
      }
      .skin-blue .sidebar-menu > li > a {
        color: white !important;
      }
      .skin-blue .sidebar-menu > li:hover > a,
      .skin-blue .sidebar-menu > li.active > a {
        background-color: #008A82 !important;
        color: white !important;
      }
      .content-wrapper, .right-side {
        background-color: #002C3C !important;
      }
      .box {
        background: #00A39A !important;
        border-top: none !important;
        color: white !important;
      }
      .box-header {
        background: #00A39A !important;
        color: white !important;
      }
      .box-body {
        background: white !important;
        color: #2c3e50 !important;
      }
      .box-title {
        color: white !important;
      }
      .metric-box {
        background: white;
        border-radius: 8px;
        padding: 15px;
        margin: 10px 0;
        border-left: 4px solid #00A39A;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        color: #2c3e50 !important;
      }
      .form-control {
        background-color: rgba(255,255,255,0.9) !important;
        border: 1px solid #bdc3c7 !important;
        color: #2c3e50 !important;
      }
      .form-control:focus {
        border-color: #008A82 !important;
        box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
      }
      .info-box {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 15px;
        margin: 20px 0;
        font-size: 0.9em;
        color: #495057;
      }
      .info-box h5 {
        color: #00A39A;
        margin-bottom: 10px;
        font-weight: bold;
      }
      .btn-primary {
        background-color: #008A82 !important;
        border-color: #008A82 !important;
      }
      .btn-primary:hover {
        background-color: #00A39A !important;
        border-color: #00A39A !important;
      }
      .btn-success {
        background-color: #4CAF50 !important;
        border-color: #4CAF50 !important;
      }
      .btn-success:hover {
        background-color: #45a049 !important;
        border-color: #45a049 !important;
      }
      .btn-warning {
        background-color: #ff9800 !important;
        border-color: #ff9800 !important;
        color: white !important;
      }
      .btn-warning:hover {
        background-color: #e68900 !important;
        border-color: #e68900 !important;
      }
      .small-box { 
        border-radius: 8px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      }
      .alert-success {
        background: #d4edda;
        color: #155724;
        border: 1px solid #c3e6cb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-danger {
        background: #f8d7da;
        color: #721c24;
        border: 1px solid #f5c6cb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-info {
        background: #d1ecf1;
        color: #0c5460;
        border: 1px solid #bee5eb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-warning {
        background: #fff3cd;
        color: #856404;
        border: 1px solid #ffeaa7;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      h4.box-title {
        font-weight: 600;
      }
      .help-section {
        background: white;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        color: #2c3e50;
      }
      .help-section h3 {
        color: #00A39A;
        margin-bottom: 15px;
      }
      .help-section ul {
        margin-left: 20px;
      }
      .help-section li {
        margin-bottom: 8px;
      }
      .instruction-box {
        background: #e3f2fd;
        border-left: 4px solid #2196F3;
        padding: 15px;
        border-radius: 4px;
        margin: 15px 0;
      }
      .instruction-box h5 {
        color: #1976D2;
        margin-bottom: 10px;
      }
      .status-badge {
        display: inline-block;
        padding: 5px 12px;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 600;
        margin-left: 10px;
      }
      .status-badge-success {
        background: #d4edda;
        color: #155724;
      }
      .status-badge-danger {
        background: #f8d7da;
        color: #721c24;
      }
      "))
    ),
    
    tabItems(
      # Tab 1: Datos Personales
      tabItem(
        tabName = "datos",
        fluidRow(
          box(
            title = "Información del Contribuyente",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(6,
                     textInput("rfc", "RFC:", placeholder = "XXXX000000XXX"),
                     textInput("nombre", "Nombre Completo:", placeholder = "Nombre(s)"),
                     textInput("apellido_paterno", "Apellido Paterno:"),
                     textInput("apellido_materno", "Apellido Materno:")
              ),
              column(6,
                     textInput("curp", "CURP:", placeholder = "18 caracteres"),
                     selectInput("regimen", "Régimen Fiscal:",
                                 choices = c("Seleccione..." = "",
                                             "Sueldos y Salarios" = "605",
                                             "Actividad Empresarial" = "612",
                                             "Arrendamiento" = "615")),
                     numericInput("ejercicio", "Ejercicio Fiscal:", 
                                  value = year(Sys.Date()), min = 2020, max = 2030),
                     selectInput("periodo", "Periodo:",
                                 choices = c("Anual" = "anual",
                                             "Enero" = "01", "Febrero" = "02",
                                             "Marzo" = "03", "Abril" = "04",
                                             "Mayo" = "05", "Junio" = "06",
                                             "Julio" = "07", "Agosto" = "08",
                                             "Septiembre" = "09", "Octubre" = "10",
                                             "Noviembre" = "11", "Diciembre" = "12"))
              )
            )
          ),
          box(
            title = "Ayuda e Instrucciones",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            collapsed = TRUE,
            
            div(class = "help-section",
                tags$h3(icon("question-circle"), " Cómo usar esta aplicación"),
                tags$ul(
                  tags$li(tags$strong("Paso 1:"), " Complete sus datos personales en esta pestaña"),
                  tags$li(tags$strong("Paso 2:"), " Capture todos sus ingresos de nómina en la siguiente pestaña"),
                  tags$li(tags$strong("Paso 3:"), " Si recibió liquidación, complete los datos correspondientes"),
                  tags$li(tags$strong("Paso 4:"), " Revise el resumen y descargue su reporte")
                ),
                div(class = "alert-info",
                    icon("exclamation-circle"), 
                    " Los cálculos se realizan automáticamente. Asegúrese de tener todos sus comprobantes fiscales a la mano."
                )
            )
          )
        )
      ),
      
      # Tab 2: Nómina
      tabItem(
        tabName = "nomina",
        fluidRow(
          box(
            title = "Ingresos por Nómina",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(4,
                     numericInput("salario_bruto", "Salario Bruto Mensual:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("aguinaldo", "Aguinaldo:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("prima_vacacional", "Prima Vacacional:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("ptu", "PTU (Participación de Utilidades):", 
                                  value = 0, min = 0, step = 100)
              ),
              column(4,
                     numericInput("bonos", "Bonos y Gratificaciones:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("vales_despensa", "Vales de Despensa:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("fondo_ahorro", "Fondo de Ahorro:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("otros_ingresos", "Otros Ingresos:", 
                                  value = 0, min = 0, step = 100)
              ),
              column(4,
                     h4("Deducciones Aplicadas"),
                     numericInput("isr_retenido", "ISR Retenido:", 
                                  value = 0, min = 0, step = 10),
                     numericInput("imss", "Cuota IMSS:", 
                                  value = 0, min = 0, step = 10),
                     numericInput("otras_deducciones", "Otras Deducciones:", 
                                  value = 0, min = 0, step = 10),
                     numericInput("infonavit", "Descuento Infonavit:", 
                                  value = 0, min = 0, step = 10)
              )
            ),
            hr(),
            fluidRow(
              column(12,
                     valueBoxOutput("total_ingresos_nomina", width = 4),
                     valueBoxOutput("total_deducciones_nomina", width = 4),
                     valueBoxOutput("ingreso_neto_nomina", width = 4)
              )
            )
          )
        )
      ),
      
      # Tab 3: Liquidación
      tabItem(
        tabName = "liquidacion",
        fluidRow(
          box(
            title = "Datos de Liquidación/Finiquito",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(4,
                     dateInput("fecha_ingreso", "Fecha de Ingreso:"),
                     dateInput("fecha_baja", "Fecha de Baja:", value = Sys.Date()),
                     numericInput("antiguedad_anos", "Años de Antigüedad:", 
                                  value = 0, min = 0, max = 50, step = 0.1),
                     numericInput("salario_diario", "Salario Diario Integrado:", 
                                  value = 0, min = 0, step = 1)
              ),
              column(4,
                     h4("Conceptos de Liquidación"),
                     numericInput("indemnizacion_3meses", "Indemnización (3 meses):", 
                                  value = 0, min = 0, step = 100),
                     numericInput("prima_antiguedad", "Prima de Antigüedad:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("dias_20_ano", "20 Días por Año:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("vacaciones_pendientes", "Vacaciones no Gozadas:", 
                                  value = 0, min = 0, step = 100)
              ),
              column(4,
                     numericInput("prima_vac_liq", "Prima Vacacional Proporcional:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("aguinaldo_liq", "Aguinaldo Proporcional:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("otros_conceptos_liq", "Otros Conceptos:", 
                                  value = 0, min = 0, step = 100),
                     numericInput("isr_retenido_liq", "ISR Retenido Liquidación:", 
                                  value = 0, min = 0, step = 10)
              )
            ),
            hr(),
            fluidRow(
              column(12,
                     valueBoxOutput("total_liquidacion", width = 4),
                     valueBoxOutput("monto_exento", width = 4),
                     valueBoxOutput("monto_gravado", width = 4)
              )
            ),
            hr(),
            fluidRow(
              column(12,
                     div(class = "info-box",
                         tags$h5(icon("info-circle"), " Información Importante sobre Liquidación"),
                         tags$ul(
                           tags$li("La indemnización es exenta hasta 90 veces la UMA (90 x $108.57 = $9,771.30 diarios en 2024)"),
                           tags$li("Prima de antigüedad: exenta hasta el equivalente de 90 veces la UMA"),
                           tags$li("El monto que exceda estos límites se considera gravado"),
                           tags$li("Aguinaldo y prima vacacional proporcionales son ingresos gravados")
                         )
                     )
              )
            )
          )
        )
      ),
      
      # Tab 4: Reporte
      tabItem(
        tabName = "reporte",
        fluidRow(
          box(
            title = "Resumen de Declaración",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(3,
                     valueBoxOutput("total_ingresos_anuales", width = 12)
              ),
              column(3,
                     valueBoxOutput("total_deducciones_anuales", width = 12)
              ),
              column(3,
                     valueBoxOutput("base_gravable", width = 12)
              ),
              column(3,
                     valueBoxOutput("isr_total_retenido", width = 12)
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Detalle de Ingresos y Deducciones",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            
            h4("Ingresos por Nómina"),
            DTOutput("tabla_nomina"),
            hr(),
            h4("Ingresos por Liquidación"),
            DTOutput("tabla_liquidacion"),
            hr(),
            h4("Deducciones Totales"),
            DTOutput("tabla_deducciones")
          )
        ),
        
        fluidRow(
          box(
            title = "Generar Reporte",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(6,
                     downloadButton("descargar_excel", "Descargar Reporte Excel", 
                                    class = "btn-primary btn-lg btn-block"),
                     br(), br(),
                     div(class = "instruction-box",
                         tags$h5(icon("file-excel"), " Archivo Excel"),
                         helpText("El reporte incluye todos los datos capturados organizados en múltiples hojas para su declaración ante el SAT")
                     )
              ),
              column(6,
                     downloadButton("descargar_pdf", "Descargar Reporte HTML", 
                                    class = "btn-success btn-lg btn-block"),
                     br(), br(),
                     div(class = "instruction-box",
                         tags$h5(icon("file-alt"), " Documento HTML"),
                         helpText("Documento imprimible con el resumen completo de su declaración")
                     )
              )
            )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Cálculos de Nómina
  total_ingresos_nom <- reactive({
    input$salario_bruto * 12 + input$aguinaldo + input$prima_vacacional + 
      input$ptu + input$bonos + input$vales_despensa + input$fondo_ahorro + 
      input$otros_ingresos
  })
  
  total_deducciones_nom <- reactive({
    input$isr_retenido + input$imss + input$otras_deducciones + input$infonavit
  })
  
  # Cálculos de Liquidación
  total_liq <- reactive({
    input$indemnizacion_3meses + input$prima_antiguedad + input$dias_20_ano +
      input$vacaciones_pendientes + input$prima_vac_liq + input$aguinaldo_liq +
      input$otros_conceptos_liq
  })
  
  # UMA 2024 (actualizar según el año)
  uma_diaria <- 108.57
  
  monto_exento_calc <- reactive({
    # La indemnización y prima de antigüedad son exentas hasta 90 UMAs
    limite_exento <- 90 * uma_diaria * 30 # aproximado mensual
    
    total_exentos <- input$indemnizacion_3meses + input$prima_antiguedad
    
    min(total_exentos, limite_exento)
  })
  
  monto_gravado_calc <- reactive({
    total_liq() - monto_exento_calc()
  })
  
  # Value Boxes - Nómina
  output$total_ingresos_nomina <- renderValueBox({
    valueBox(
      paste0("$", format(round(total_ingresos_nom(), 2), big.mark = ",", nsmall = 2)),
      "Total Ingresos Nómina",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })
  
  output$total_deducciones_nomina <- renderValueBox({
    valueBox(
      paste0("$", format(round(total_deducciones_nom(), 2), big.mark = ",", nsmall = 2)),
      "Total Deducciones Nómina",
      icon = icon("minus-circle"),
      color = "red"
    )
  })
  
  output$ingreso_neto_nomina <- renderValueBox({
    neto <- total_ingresos_nom() - total_deducciones_nom()
    valueBox(
      paste0("$", format(round(neto, 2), big.mark = ",", nsmall = 2)),
      "Ingreso Neto Nómina",
      icon = icon("wallet"),
      color = "blue"
    )
  })
  
  # Value Boxes - Liquidación
  output$total_liquidacion <- renderValueBox({
    valueBox(
      paste0("$", format(round(total_liq(), 2), big.mark = ",", nsmall = 2)),
      "Total Liquidación",
      icon = icon("hand-holding-usd"),
      color = "yellow"
    )
  })
  
  output$monto_exento <- renderValueBox({
    valueBox(
      paste0("$", format(round(monto_exento_calc(), 2), big.mark = ",", nsmall = 2)),
      "Monto Exento",
      icon = icon("shield-alt"),
      color = "green"
    )
  })
  
  output$monto_gravado <- renderValueBox({
    valueBox(
      paste0("$", format(round(monto_gravado_calc(), 2), big.mark = ",", nsmall = 2)),
      "Monto Gravado",
      icon = icon("file-invoice-dollar"),
      color = "orange"
    )
  })
  
  # Value Boxes - Resumen
  output$total_ingresos_anuales <- renderValueBox({
    total <- total_ingresos_nom() + total_liq()
    valueBox(
      paste0("$", format(round(total, 2), big.mark = ",", nsmall = 2)),
      "Total Ingresos Anuales",
      icon = icon("chart-line"),
      color = "green"
    )
  })
  
  output$total_deducciones_anuales <- renderValueBox({
    total <- total_deducciones_nom() + input$isr_retenido_liq
    valueBox(
      paste0("$", format(round(total, 2), big.mark = ",", nsmall = 2)),
      "Total Deducciones",
      icon = icon("minus-circle"),
      color = "red"
    )
  })
  
  output$base_gravable <- renderValueBox({
    base <- total_ingresos_nom() + monto_gravado_calc()
    valueBox(
      paste0("$", format(round(base, 2), big.mark = ",", nsmall = 2)),
      "Base Gravable",
      icon = icon("calculator"),
      color = "purple"
    )
  })
  
  output$isr_total_retenido <- renderValueBox({
    total <- input$isr_retenido + input$isr_retenido_liq
    valueBox(
      paste0("$", format(round(total, 2), big.mark = ",", nsmall = 2)),
      "ISR Total Retenido",
      icon = icon("receipt"),
      color = "navy"
    )
  })
  
  # Tablas
  output$tabla_nomina <- renderDT({
    df <- data.frame(
      Concepto = c("Salario Bruto Anual", "Aguinaldo", "Prima Vacacional", 
                   "PTU", "Bonos", "Vales Despensa", "Fondo Ahorro", "Otros"),
      Monto = c(input$salario_bruto * 12, input$aguinaldo, input$prima_vacacional,
                input$ptu, input$bonos, input$vales_despensa, input$fondo_ahorro,
                input$otros_ingresos)
    )
    df$Monto <- paste0("$", format(round(df$Monto, 2), big.mark = ",", nsmall = 2))
    
    datatable(df, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  output$tabla_liquidacion <- renderDT({
    df <- data.frame(
      Concepto = c("Indemnización", "Prima Antigüedad", "20 Días/Año", 
                   "Vacaciones", "Prima Vac. Prop.", "Aguinaldo Prop.", "Otros"),
      Monto = c(input$indemnizacion_3meses, input$prima_antiguedad, input$dias_20_ano,
                input$vacaciones_pendientes, input$prima_vac_liq, 
                input$aguinaldo_liq, input$otros_conceptos_liq),
      Status = c("Parcialmente Exento", "Parcialmente Exento", "Gravado",
                 "Gravado", "Gravado", "Gravado", "Gravado")
    )
    df$Monto <- paste0("$", format(round(df$Monto, 2), big.mark = ",", nsmall = 2))
    
    datatable(df, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  output$tabla_deducciones <- renderDT({
    df <- data.frame(
      Concepto = c("ISR Retenido Nómina", "IMSS", "Infonavit", 
                   "Otras Deducciones Nómina", "ISR Retenido Liquidación"),
      Monto = c(input$isr_retenido, input$imss, input$infonavit,
                input$otras_deducciones, input$isr_retenido_liq)
    )
    df$Monto <- paste0("$", format(round(df$Monto, 2), big.mark = ",", nsmall = 2))
    
    datatable(df, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  # Descargar Excel
  output$descargar_excel <- downloadHandler(
    filename = function() {
      paste0("Declaracion_SAT_", input$rfc, "_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      # Crear workbook
      wb <- createWorkbook()
      
      # Hoja 1: Datos Personales
      addWorksheet(wb, "Datos Personales")
      datos_personales <- data.frame(
        Campo = c("RFC", "Nombre", "CURP", "Régimen Fiscal", "Ejercicio", "Periodo"),
        Valor = c(input$rfc, 
                  paste(input$nombre, input$apellido_paterno, input$apellido_materno),
                  input$curp, input$regimen, input$ejercicio, input$periodo)
      )
      writeData(wb, "Datos Personales", datos_personales)
      
      # Hoja 2: Ingresos Nómina
      addWorksheet(wb, "Ingresos Nómina")
      nomina_data <- data.frame(
        Concepto = c("Salario Bruto Anual", "Aguinaldo", "Prima Vacacional", 
                     "PTU", "Bonos", "Vales Despensa", "Fondo Ahorro", "Otros", "TOTAL"),
        Monto = c(input$salario_bruto * 12, input$aguinaldo, input$prima_vacacional,
                  input$ptu, input$bonos, input$vales_despensa, input$fondo_ahorro,
                  input$otros_ingresos, total_ingresos_nom())
      )
      writeData(wb, "Ingresos Nómina", nomina_data)
      
      # Hoja 3: Liquidación
      addWorksheet(wb, "Liquidación")
      liq_data <- data.frame(
        Concepto = c("Indemnización", "Prima Antigüedad", "20 Días/Año", 
                     "Vacaciones", "Prima Vac. Prop.", "Aguinaldo Prop.", 
                     "Otros", "TOTAL", "Monto Exento", "Monto Gravado"),
        Monto = c(input$indemnizacion_3meses, input$prima_antiguedad, input$dias_20_ano,
                  input$vacaciones_pendientes, input$prima_vac_liq, 
                  input$aguinaldo_liq, input$otros_conceptos_liq,
                  total_liq(), monto_exento_calc(), monto_gravado_calc())
      )
      writeData(wb, "Liquidación", liq_data)
      
      # Hoja 4: Resumen
      addWorksheet(wb, "Resumen")
      resumen <- data.frame(
        Concepto = c("Total Ingresos Nómina", "Total Ingresos Liquidación",
                     "Total Ingresos Anuales", "Total Deducciones",
                     "Base Gravable", "ISR Total Retenido"),
        Monto = c(total_ingresos_nom(), total_liq(),
                  total_ingresos_nom() + total_liq(),
                  total_deducciones_nom() + input$isr_retenido_liq,
                  total_ingresos_nom() + monto_gravado_calc(),
                  input$isr_retenido + input$isr_retenido_liq)
      )
      writeData(wb, "Resumen", resumen)
      
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
  
  # Descargar PDF (placeholder - requiere paquetes adicionales)
  output$descargar_pdf <- downloadHandler(
    filename = function() {
      paste0("Declaracion_SAT_", input$rfc, "_", Sys.Date(), ".html")
    },
    content = function(file) {
      # Crear reporte HTML simple
      html_content <- paste0(
        "<!DOCTYPE html><html><head>",
        "<meta charset='UTF-8'>",
        "<style>",
        "body { font-family: Arial, sans-serif; margin: 40px; }",
        "h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }",
        "h2 { color: #34495e; margin-top: 30px; }",
        "table { width: 100%; border-collapse: collapse; margin: 20px 0; }",
        "th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }",
        "th { background-color: #3498db; color: white; }",
        "tr:nth-child(even) { background-color: #f2f2f2; }",
        ".total { font-weight: bold; background-color: #e8f4f8; }",
        "</style></head><body>",
        "<h1>Declaración de Impuestos - SAT México</h1>",
        "<h2>Datos del Contribuyente</h2>",
        "<p><strong>RFC:</strong> ", input$rfc, "</p>",
        "<p><strong>Nombre:</strong> ", input$nombre, " ", input$apellido_paterno, " ", input$apellido_materno, "</p>",
        "<p><strong>CURP:</strong> ", input$curp, "</p>",
        "<p><strong>Ejercicio Fiscal:</strong> ", input$ejercicio, "</p>",
        "<h2>Resumen de Ingresos</h2>",
        "<table>",
        "<tr><th>Concepto</th><th>Monto</th></tr>",
        "<tr><td>Total Ingresos Nómina</td><td>$", format(round(total_ingresos_nom(), 2), big.mark = ","), "</td></tr>",
        "<tr><td>Total Liquidación</td><td>$", format(round(total_liq(), 2), big.mark = ","), "</td></tr>",
        "<tr class='total'><td>Total Ingresos</td><td>$", format(round(total_ingresos_nom() + total_liq(), 2), big.mark = ","), "</td></tr>",
        "<tr><td>Total Deducciones</td><td>$", format(round(total_deducciones_nom() + input$isr_retenido_liq, 2), big.mark = ","), "</td></tr>",
        "<tr class='total'><td>Base Gravable</td><td>$", format(round(total_ingresos_nom() + monto_gravado_calc(), 2), big.mark = ","), "</td></tr>",
        "</table>",
        "<p style='margin-top: 40px; font-size: 12px; color: #7f8c8d;'>",
        "Documento generado el ", format(Sys.Date(), "%d/%m/%Y"),
        ". Este reporte es únicamente informativo y debe ser validado con su contador.</p>",
        "</body></html>"
      )
      
      writeLines(html_content, file)
    }
  )
}

# Run the app
shinyApp(ui = ui, server = server)