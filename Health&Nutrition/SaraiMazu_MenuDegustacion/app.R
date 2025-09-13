# Dashboard Gastronómico - Menú Degustación Ruta de la Seda
# Aplicación educativa interactiva para ciencias gastronómicas
# Por Miriam Sarai Mazu Q.

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(shinyWidgets)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "M.Sarai Mazu - 10082"),
  
  dashboardSidebar(
    
    
    sidebarMenu(
      menuItem("Menú Degustación", tabName = "menu", icon = icon("utensils")),
      menuItem("Métodos de Cocción", tabName = "metodos", icon = icon("fire")),
      menuItem("Control HACCP", tabName = "haccp", icon = icon("thermometer")),
      menuItem("Recetas Estandarizadas", tabName = "recetas", icon = icon("book")),
      menuItem("Maridaje de Bebidas", tabName = "maridaje", icon = icon("wine-glass")),
      menuItem("Servicio al Comensal", tabName = "servicio", icon = icon("concierge-bell")),
      menuItem("Limpieza de Paladar", tabName = "limpieza", icon = icon("leaf")),
      menuItem("Bitácora de Control", tabName = "bitacora", icon = icon("clipboard-list"))
    ),
    # Control de Comensales ACTUALIZADO CON NOTA DE TABS AFECTADAS
    div(style = "padding: 15px; background-color: #FFF8DC; margin: 10px; border-radius: 8px; border: 2px solid #DAA520;",
        h4("Control de Porciones", style = "color: #000000; text-align: center; margin-bottom: 15px;"),
        numericInput("comensales", 
                     label = div(style = "color: #000000;", icon("users"), " Número de Comensales:"), 
                     value = 4, 
                     min = 1, 
                     max = 10, 
                     step = 1,
                     width = "100%"),
        actionButton("actualizar_porciones", "Actualizar Cantidades", 
                     class = "btn btn-warning", 
                     style = "width: 100%; margin-top: 10px; color: #000000; font-weight: bold;"),
        div(style = "text-align: center; color: #000000; font-size: 12px; margin-top: 10px;",
            "Presiona el botón para aplicar cambios"),
        
        # NOTA AGREGADA SOBRE TABS AFECTADAS
        div(style = "margin-top: 15px; padding: 10px; background-color: #F0E68C; border-radius: 5px; border: 1px solid #DAA520;",
            h6("📊 Tabs Afectadas por Ajuste de Porciones:", style = "color: #B8860B; margin-bottom: 8px; font-weight: bold;"),
            tags$ul(style = "margin: 0; padding-left: 15px; color: #000000; font-size: 11px;",
                    tags$li("Recetas Estandarizadas - Cantidades de ingredientes"),
                    tags$li("Limpieza de Paladar - Ingredientes de sorbetes"),
                    tags$li("Procedimientos - Tiempos de cocción ajustados")
            )
        ),
        
        div(style = "text-align: center; color: #8B4513; font-size: 10px; margin-top: 8px; font-style: italic;",
            "Los cálculos se multiplican automáticamente por el número seleccionado")
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Estilo del header */
        .skin-blue .main-header .navbar {
          background-color: #FF8C00 !important;
        }
        .skin-blue .main-header .logo {
          background-color: #FF8C00 !important;
          color: #000000 !important;
          border-bottom: 0 solid transparent;
        }
        .skin-blue .main-header .logo:hover {
          background-color: #FF7F00 !important;
        }
        
        /* Estilo del sidebar */
        .skin-blue .main-sidebar {
          background-color: #B8860B !important;
        }
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background-color: #FFD700 !important;
          color: #000000 !important;
          font-weight: bold;
        }
        .skin-blue .main-sidebar .sidebar .sidebar-menu a {
          color: #000000 !important;
        }
        .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
          background-color: #DAA520 !important;
          color: #000000 !important;
        }
        
        /* Estilo del contenido */
        .content-wrapper {
          background-color: #FFF8DC !important;
        }
        
        /* Estilo de las cajas */
        .box {
          background-color: #FFFFE0 !important;
          border: 2px solid #DAA520 !important;
          border-radius: 8px !important;
          box-shadow: 0 4px 8px rgba(218, 165, 32, 0.3) !important;
        }
        .box.box-primary {
          border-top-color: #FF8C00 !important;
          border-top-width: 4px !important;
        }
        .box.box-primary .box-header {
          color: #000000 !important;
          background: linear-gradient(135deg, #FF8C00, #FFD700) !important;
          border-radius: 6px 6px 0 0 !important;
          border-bottom: 2px solid #DAA520 !important;
        }
        .box-body {
          background-color: #FFFACD !important;
          color: #333333 !important;
          padding: 20px !important;
        }
        
        /* Estilo del texto */
        p { color: #2F4F4F !important; line-height: 1.6 !important; }
        strong { color: #B8860B !important; }
        li { color: #2F4F4F !important; margin-bottom: 5px !important; }
        
        /* Caja de introducción */
        .intro-box { 
          background-color: #F0E68C !important; 
          border: 1px solid #DAA520 !important;
          border-radius: 5px !important;
          padding: 15px; 
          margin-bottom: 20px; 
          border-left: 4px solid #B8860B; 
        }
        .intro-box h4 { color: #B8860B !important; margin-top: 0 !important; }
        .intro-box p { color: #2F4F4F !important; margin-bottom: 0 !important; }
        
        /* Tabla de ingredientes */
        .ingredientes-table {
          background-color: #FFFACD !important;
          border: 1px solid #DAA520 !important;
          border-radius: 5px !important;
          padding: 10px;
          margin: 10px 0;
        }
      "))
    ),
    
    tabItems(
      # Tab Menú Degustación
      tabItem(tabName = "menu",
              fluidRow(
                div(class = "intro-box",
                    h4("Menú Degustación - Odisea Culinaria: De Persia a Cantón"),
                    p("Un viaje gastronómico por la Ruta de la Seda. Menú degustación de 8 tiempos que combina preparaciones auténticas de cocina internacional, desde los sabores persas hasta la delicadeza cantonesa.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Menú Degustación Completo", status = "primary", solidHeader = TRUE,
                    DT::dataTableOutput("menu_table")
                )
              ),
              fluidRow(
                box(width = 6, title = "Distribución por Países", status = "info",
                    plotlyOutput("paises_chart")
                ),
                box(width = 6, title = "Métodos de Cocción", status = "info",
                    plotlyOutput("metodos_chart")
                )
              )
      ),
      
      # Tab Métodos de Cocción
      tabItem(tabName = "metodos",
              fluidRow(
                div(class = "intro-box",
                    h4("Glosario de Métodos de Cocción"),
                    p("Descripción detallada de los 8 métodos de cocción utilizados en el menú degustación, incluyendo temperaturas, tiempos y aplicaciones específicas.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Métodos de Cocción Utilizados", status = "primary", solidHeader = TRUE,
                    selectInput("metodo_selected", "Seleccionar Método:",
                                choices = c("Vapor", "Sin cocción", "Hervido", "Fritura Profunda", 
                                            "Asado en Horno Tandoor", "Salteado Rápido", "Horneado"),
                                selected = "Vapor"),
                    verbatimTextOutput("metodo_descripcion")
                )
              ),
              fluidRow(
                box(width = 6, title = "Temperaturas de Cocción", status = "info",
                    plotlyOutput("temperaturas_chart")
                ),
                box(width = 6, title = "Tiempos de Cocción", status = "info",
                    plotlyOutput("tiempos_chart")
                )
              )
      ),
      
      # Tab Control HACCP
      tabItem(tabName = "haccp",
              fluidRow(
                div(class = "intro-box",
                    h4("Control HACCP - Productos de Origen Animal"),
                    p("Sistema de Análisis de Peligros y Puntos Críticos de Control aplicado a los productos de origen animal del menú, garantizando la seguridad alimentaria.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Cuadro de Control HACCP", status = "primary", solidHeader = TRUE,
                    DT::dataTableOutput("haccp_table")
                )
              ),
              fluidRow(
                box(width = 6, title = "Temperaturas Críticas", status = "info",
                    plotlyOutput("temp_criticas_chart")
                ),
                box(width = 6, title = "Zona de Peligro", status = "warning",
                    div(style = "text-align: center; padding: 20px;",
                        h3("4°C - 60°C", style = "color: #DC143C;"),
                        p("Zona de temperatura donde las bacterias se multiplican rápidamente."),
                        p("Los alimentos NO deben permanecer en esta zona por más de 2 horas.")
                    )
                )
              )
      ),
      
      # Tab Recetas Estandarizadas  
      tabItem(tabName = "recetas",
              fluidRow(
                div(class = "intro-box",
                    h4("Recetas Estandarizadas"),
                    p(paste("Recetas calculadas para", textOutput("num_comensales", inline = TRUE), "comensales. Las cantidades se ajustan automáticamente según el número de personas."))
                )
              ),
              fluidRow(
                box(width = 12, title = "Seleccionar Platillo", status = "primary", solidHeader = TRUE,
                    selectInput("platillo_selected", "Platillo:",
                                choices = c("Dumplings de Camarones", "Ensalada Shirazi", "Sopa de Lentejas Turca",
                                            "Falafel con Jocoque", "Pollo al Tandoori", "Pescado al Wok",
                                            "Lokma", "Kunafa"),
                                selected = "Dumplings de Camarones")
                )
              ),
              fluidRow(
                box(width = 6, title = "Ingredientes Calculados", status = "info",
                    DT::dataTableOutput("ingredientes_table")
                ),
                box(width = 6, title = "Procedimiento", status = "info",
                    verbatimTextOutput("procedimiento_text")
                )
              )
      ),
      
      # Tab Maridaje
      tabItem(tabName = "maridaje",
              fluidRow(
                div(class = "intro-box",
                    h4("Maridaje de Bebidas"),
                    p("Propuesta de maridaje con y sin alcohol para cada platillo del menú degustación, diseñadas para complementar y realzar los sabores de cada preparación.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Maridajes por Platillo", status = "primary", solidHeader = TRUE,
                    DT::dataTableOutput("maridaje_table")
                )
              ),
              fluidRow(
                box(width = 6, title = "Tipos de Bebidas", status = "info",
                    plotlyOutput("bebidas_chart")
                ),
                box(width = 6, title = "Perfil de Maridaje", status = "info",
                    plotlyOutput("maridaje_chart")
                )
              )
      ),
      
      # Tab Servicio al Comensal CORREGIDO
      tabItem(tabName = "servicio",
              fluidRow(
                div(class = "intro-box",
                    h4("Protocolo de Servicio"),
                    p("Checklist detallado del equipo de servicio y acompañantes necesarios para cada platillo, garantizando una presentación profesional y experiencia completa.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Ambientación Recomendada", status = "primary", solidHeader = TRUE,
                    fluidRow(
                      column(4,
                             h5("Mantelería"),
                             p("Manteles de lino beige o crema con caminos de mesa en brocado dorado o burdeos.")
                      ),
                      column(4,
                             h5("Centro de Mesa"),
                             p("Cuencos con especias enteras: anís estrella, clavos de olor, canela para aromas sutiles.")
                      ),
                      column(4,
                             h5("Música Ambiente"),
                             p("Fusión de ritmos tradicionales de Medio Oriente, India y Asia con elementos modernos.")
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Checklist de Servicio", status = "info",
                    selectInput("servicio_platillo", "Seleccionar Platillo:",
                                choices = c("Dumplings de Camarones", "Ensalada Shirazi", "Sopa de Lentejas Turca",
                                            "Falafel con Jocoque", "Pollo al Tandoori", "Pescado al Wok",
                                            "Lokma", "Kunafa"),
                                selected = "Dumplings de Camarones"),
                    DT::dataTableOutput("servicio_table")
                )
              )
      ),
      
      # Tab Limpieza de Paladar
      tabItem(tabName = "limpieza",
              fluidRow(
                div(class = "intro-box",
                    h4("Limpieza de Paladar - Sorbetes"),
                    p("Tres sorbetes estratégicamente ubicados en el menú para limpiar el paladar y preparar las papilas gustativas para el siguiente tiempo.")
                )
              ),
              fluidRow(
                box(width = 4, title = "Sorbete de Litchi y Rosa", status = "primary", solidHeader = TRUE,
                    h5("Cuándo servir:"),
                    p("Entre Sopa de Lentejas Turca y Falafel de Garbanzos"),
                    h5("Justificación:"),
                    p("Dulzor delicado y floral que neutraliza la cremosidad de la sopa y prepara para las especias del falafel."),
                    div(class = "ingredientes-table",
                        h6("Ingredientes (ajustado):"),
                        verbatimTextOutput("sorbete1_ingredientes")
                    )
                ),
                box(width = 4, title = "Sorbete de Limón y Albahaca", status = "primary", solidHeader = TRUE,
                    h5("Cuándo servir:"),
                    p("Entre Pollo al Tandoori y Pescado al Wok"),
                    h5("Justificación:"),
                    p("Acidez vibrante que corta la grasa del yogur y prepara el paladar para la delicadeza del pescado."),
                    div(class = "ingredientes-table",
                        h6("Ingredientes (ajustado):"),
                        verbatimTextOutput("sorbete2_ingredientes")
                    )
                ),
                box(width = 4, title = "Sorbete de Jengibre y Té Verde", status = "primary", solidHeader = TRUE,
                    h5("Cuándo servir:"),
                    p("Entre Pescado al Wok y los Postres"),
                    h5("Justificación:"),
                    p("Sabor picante que estimula las papilas y prepara la transición de salado a dulce."),
                    div(class = "ingredientes-table",
                        h6("Ingredientes (ajustado):"),
                        verbatimTextOutput("sorbete3_ingredientes")
                    )
                )
              )
      ),
      
      # Tab Bitácora de Control
      tabItem(tabName = "bitacora",
              fluidRow(
                div(class = "intro-box",
                    h4("Sistema de Bitácora de Control"),
                    p("Formato de registro para el control de productos de origen animal, garantizando trazabilidad y rotación FIFO (First In, First Out).")
                )
              ),
              fluidRow(
                box(width = 6, title = "Procedimiento de Recepción", status = "primary", solidHeader = TRUE,
                    h5("Pasos de Recepción:"),
                    tags$ol(
                      tags$li("Verificar empaque íntegro y sin daños"),
                      tags$li("Comprobar etiqueta y fecha de caducidad"),
                      tags$li("Medir temperatura (0°C - 4°C para productos frescos)"),
                      tags$li("Rechazar si hay signos de descongelación"),
                      tags$li("Registrar en bitácora inmediatamente")
                    )
                ),
                box(width = 6, title = "Procedimiento de Almacenamiento", status = "primary", solidHeader = TRUE,
                    h5("Pasos de Almacenamiento:"),
                    tags$ol(
                      tags$li("Llevar a refrigeración de inmediato"),
                      tags$li("Etiquetar con fecha de entrada y caducidad"),
                      tags$li("Aplicar método FIFO"),
                      tags$li("Almacenar en recipientes separados"),
                      tags$li("Productos crudos en estantes inferiores")
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Formato de Bitácora", status = "info",
                    DT::dataTableOutput("bitacora_table")
                )
              ),
              fluidRow(
                box(width = 12, title = "Códigos de Colores para Tablas", status = "warning",
                    fluidRow(
                      column(2, div(style = "background-color: red; color: white; padding: 10px; text-align: center; border-radius: 5px;", "ROJO\nCarne Cruda")),
                      column(2, div(style = "background-color: yellow; color: black; padding: 10px; text-align: center; border-radius: 5px;", "AMARILLO\nCarne Cocida")),
                      column(2, div(style = "background-color: blue; color: white; padding: 10px; text-align: center; border-radius: 5px;", "AZUL\nPescados")),
                      column(2, div(style = "background-color: green; color: white; padding: 10px; text-align: center; border-radius: 5px;", "VERDE\nVegetales")),
                      column(2, div(style = "background-color: white; color: black; padding: 10px; text-align: center; border-radius: 5px; border: 1px solid black;", "BLANCO\nLácteos")),
                      column(2, div(style = "background-color: brown; color: white; padding: 10px; text-align: center; border-radius: 5px;", "CAFÉ\nAlimentos Cocidos"))
                    )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive value para controlar actualizaciones
  comensales_reactivo <- reactiveVal(4)
  
  # Observer para el botón de actualizar
  observeEvent(input$actualizar_porciones, {
    comensales_reactivo(input$comensales)
    showNotification(paste("Cantidades actualizadas para", input$comensales, "comensales"), 
                     type = "message", duration = 3)
  })
  
  # Datos del menú
  menu_data <- data.frame(
    Tiempo = 1:8,
    Platillo = c("Dumplings de Camarones", "Ensalada Shirazi", "Sopa de Lentejas Turca",
                 "Falafel con Jocoque", "Pollo al Tandoori", "Pescado al Wok", "Lokma", "Kunafa"),
    Origen = c("China/Cantón", "Irán/Shiraz", "Turquía/Anatolia", "Egipto/Oriente Medio",
               "India/Punyab", "Tailandia/Chiang Mai", "Turquía/Esmirna", "Arabia Saudita"),
    Metodo = c("Vapor", "Sin cocción", "Hervido", "Fritura Profunda", "Asado Tandoor", 
               "Salteado Rápido", "Fritura Profunda", "Horneado"),
    stringsAsFactors = FALSE
  )
  
  # Función para escalar ingredientes CORREGIDA
  escalar_cantidad <- function(cantidad_base, comensales_base = 1) {
    factor <- comensales_reactivo() / comensales_base
    return(round(cantidad_base * factor, 2))
  }
  
  # Render número de comensales
  output$num_comensales <- renderText({
    comensales_reactivo()
  })
  
  # Tab Menú - Tabla del menú
  output$menu_table <- DT::renderDataTable({
    DT::datatable(menu_data, 
                  options = list(pageLength = 8, searching = FALSE, paging = FALSE),
                  rownames = FALSE)
  })
  
  # Tab Menú - Gráfico de países
  output$paises_chart <- renderPlotly({
    paises <- c("China", "Irán", "Turquía", "Egipto", "India", "Tailandia", "Arabia Saudita")
    conteo <- c(1, 1, 2, 1, 1, 1, 1)
    
    p <- plot_ly(x = paises, y = conteo, type = 'bar',
                 marker = list(color = c('#FF6B35', '#F7931E', '#FFD23F', '#06FFA5', 
                                         '#4ECDC4', '#45B7D1', '#96CEB4'))) %>%
      layout(title = "Distribución de Platillos por País",
             xaxis = list(title = "País de Origen"),
             yaxis = list(title = "Número de Platillos"))
    p
  })
  
  # Tab Menú - Gráfico de métodos
  output$metodos_chart <- renderPlotly({
    metodos <- table(menu_data$Metodo)
    
    p <- plot_ly(labels = names(metodos), values = as.numeric(metodos), type = 'pie',
                 marker = list(colors = c('#FF8C00', '#FFD700', '#DAA520', '#B8860B',
                                          '#F0E68C', '#FFFFE0', '#FFFACD'))) %>%
      layout(title = "Distribución de Métodos de Cocción")
    p
  })
  
  # Tab Métodos - Descripción del método
  output$metodo_descripcion <- renderText({
    descripciones <- list(
      "Vapor" = "Cocción que utiliza el vapor de agua para transmitir calor. Preserva nutrientes y textura delicada. Temperatura: 100°C. Tiempo: 5-15 minutos.",
      "Sin cocción" = "Preparación sin uso de calor, combinando ingredientes crudos. Mantiene propiedades nutricionales originales.",
      "Hervido" = "Cocción por inmersión en líquido a 100°C. Método tradicional para sopas y caldos. Tiempo: 20-45 minutos.",
      "Fritura Profunda" = "Cocción en aceite a 180°C. Crea corteza crujiente y dorada. Tiempo: 2-5 minutos. Requiere control estricto de temperatura.",
      "Asado en Horno Tandoor" = "Cocción ancestral en horno de arcilla a 200-300°C. Calor por convección y radiación. Tiempo: 15-30 minutos.",
      "Salteado Rápido" = "Cocción rápida en wok con aceite muy caliente. Movimientos constantes. Tiempo: 3-8 minutos. Conserva textura y color.",
      "Horneado" = "Cocción por calor seco en horno convencional. Temperatura: 150-200°C. Tiempo: 20-45 minutos según producto."
    )
    descripciones[[input$metodo_selected]]
  })
  
  # Tab HACCP - Tabla de control
  output$haccp_table <- DT::renderDataTable({
    haccp_data <- data.frame(
      Producto = c("Pollo", "Pescado", "Camarones"),
      Temperatura_Coccion = c("74°C", "63°C", "63°C"),
      Punto_Critico = c("Cocción", "Cocción", "Cocción"),
      Justificacion = c("Elimina Salmonella y Campylobacter", 
                        "Destruye parásitos como Anisakis y Vibrio",
                        "Elimina Vibrio parahaemolyticus"),
      stringsAsFactors = FALSE
    )
    DT::datatable(haccp_data, options = list(pageLength = 5, searching = FALSE))
  })
  
  # Tab Recetas - Tabla de ingredientes CORREGIDA
  output$ingredientes_table <- DT::renderDataTable({
    # Base de datos completa de ingredientes
    ingredientes_db <- list(
      "Dumplings de Camarones" = data.frame(
        Ingrediente = c("Pasta wonton", "Camarones", "Jengibre", "Cebollín", "Salsa soya", "Aceite ajonjolí"),
        Cantidad_Base = c(4, 100, 2, 5, 5, 2),
        Unidad = c("uds", "g", "g", "g", "ml", "ml")
      ),
      "Ensalada Shirazi" = data.frame(
        Ingrediente = c("Pepino persa", "Tomate", "Cebolla morada", "Menta", "Limón", "Aceite oliva"),
        Cantidad_Base = c(1, 1, 20, 5, 15, 10),
        Unidad = c("unid", "unid", "g", "g", "ml", "ml")
      ),
      "Sopa de Lentejas Turca" = data.frame(
        Ingrediente = c("Lentejas rojas", "Cebolla", "Zanahoria", "Caldo pollo", "Tomate concentrado"),
        Cantidad_Base = c(50, 20, 20, 250, 5),
        Unidad = c("g", "g", "g", "ml", "g")
      ),
      "Falafel con Jocoque" = data.frame(
        Ingrediente = c("Garbanzos secos", "Cilantro y perejil", "Cebolla blanca", "Comino", "Ajo", "Jocoque"),
        Cantidad_Base = c(50, 15, 15, 2, 3, 30),
        Unidad = c("g", "g", "g", "g", "g", "g")
      ),
      "Pollo al Tandoori" = data.frame(
        Ingrediente = c("Muslo pollo", "Yogurt", "Garam masala", "Cúrcuma", "Comino", "Arroz basmati"),
        Cantidad_Base = c(200, 50, 3, 1, 1, 100),
        Unidad = c("g", "ml", "g", "g", "g", "g")
      ),
      "Pescado al Wok" = data.frame(
        Ingrediente = c("Filete tilapia", "Brócoli", "Zanahoria", "Pimiento", "Salsa soya", "Aceite vegetal"),
        Cantidad_Base = c(150, 50, 20, 20, 15, 10),
        Unidad = c("g", "g", "g", "g", "ml", "ml")
      ),
      "Lokma" = data.frame(
        Ingrediente = c("Harina trigo", "Levadura", "Agua tibia", "Miel", "Aceite para freír"),
        Cantidad_Base = c(50, 2, 60, 30, 200),
        Unidad = c("g", "g", "ml", "ml", "ml")
      ),
      "Kunafa" = data.frame(
        Ingrediente = c("Fideos kunafa", "Mantequilla ghee", "Queso dulce", "Jarabe azúcar", "Pistachos"),
        Cantidad_Base = c(100, 50, 80, 50, 10),
        Unidad = c("g", "g", "g", "ml", "g")
      )
    )
    
    if (input$platillo_selected %in% names(ingredientes_db)) {
      ingredientes <- ingredientes_db[[input$platillo_selected]]
      ingredientes$Cantidad_Ajustada <- sapply(ingredientes$Cantidad_Base, escalar_cantidad)
      ingredientes$Cantidad_Final <- paste(ingredientes$Cantidad_Ajustada, ingredientes$Unidad)
      
      resultado <- data.frame(
        Ingrediente = ingredientes$Ingrediente,
        Cantidad = ingredientes$Cantidad_Final
      )
      
      DT::datatable(resultado, options = list(pageLength = 10, searching = FALSE), rownames = FALSE)
    }
  })
  
  # Tab Maridaje - Tabla de maridajes
  output$maridaje_table <- DT::renderDataTable({
    maridaje_data <- data.frame(
      Platillo = menu_data$Platillo,
      Con_Alcohol = c("Cerveza Lager", "Sauvignon Blanc", "Vino Rosado", "Beaujolais", 
                      "Gewürztraminer", "Pinot Grigio", "Moscato d'Asti", "Oporto Blanco"),
      Sin_Alcohol = c("Té de jazmín", "Agua mineral con menta", "Ayran", "Agua de tamarindo",
                      "Lassi de mango", "Té verde con jengibre", "Café espresso", "Café turco"),
      stringsAsFactors = FALSE
    )
    DT::datatable(maridaje_data, options = list(pageLength = 8, searching = FALSE), rownames = FALSE)
  })
  
  # Tab Servicio - Tabla de checklist CORREGIDA COMPLETAMENTE
  output$servicio_table <- DT::renderDataTable({
    servicio_data <- list(
      "Dumplings de Camarones" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Plato pequeño o tazón hondo", "Tenedor, cuchillo aperitivo, cuchara", 
                        "Copa cerveza o vino blanco, taza té", "Salsa soya, jengibre encurtido, chile"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Ensalada Shirazi" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Plato ensalada o tazón pequeño", "Tenedor de ensalada", 
                        "Copa vino blanco, vaso agua mineral", "No requiere acompañantes"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Sopa de Lentejas Turca" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Tazón sopa hondo", "Cuchara de sopa", 
                        "Copa vino rosado, vaso para Ayran", "Pan pita, rodajas de limón"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Falafel con Jocoque" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Plato plano", "Tenedor de mesa", 
                        "Copa vino tinto o vaso", "Jocoque extra, salsa tahini"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Pollo al Tandoori" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Plato principal", "Tenedor y cuchillo de mesa", 
                        "Copa vino blanco, vaso Lassi", "Arroz basmati, pan naan"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Pescado al Wok" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Tazón o plato hondo", "Palillos chinos, tenedor", 
                        "Copa vino blanco o vaso", "Arroz blanco, rodajas limón"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Lokma" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Plato postre pequeño", "Tenedor de postre", 
                        "Copa vino postre o café espresso", "Jarabe extra para bañar"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      ),
      "Kunafa" = data.frame(
        Elemento = c("Loza", "Plaqué", "Copas/Vasos", "Acompañantes"),
        Descripcion = c("Plato postre pequeño", "Tenedor postre o cuchara", 
                        "Copa vino postre o café turco", "Pistachos extra"),
        Verificado = c("☐", "☐", "☐", "☐"),
        stringsAsFactors = FALSE
      )
    )
    
    if (input$servicio_platillo %in% names(servicio_data)) {
      DT::datatable(servicio_data[[input$servicio_platillo]], 
                    options = list(pageLength = 5, searching = FALSE), 
                    rownames = FALSE)
    } else {
      # Tabla vacía por defecto
      data.frame(Mensaje = "Seleccione un platillo para ver el checklist")
    }
  })
  
  # Tab Limpieza - Ingredientes sorbetes CORREGIDOS
  output$sorbete1_ingredientes <- renderText({
    litchi <- escalar_cantidad(150)
    rosa <- escalar_cantidad(10)
    azucar <- escalar_cantidad(50)
    agua <- escalar_cantidad(200)
    limon <- escalar_cantidad(15)
    
    paste(
      paste("Litchi:", litchi, "g"),
      paste("Agua de rosas:", rosa, "ml"),
      paste("Azúcar:", azucar, "g"),
      paste("Agua:", agua, "ml"),
      paste("Limón:", limon, "ml"),
      sep = "\n"
    )
  })
  
  output$sorbete2_ingredientes <- renderText({
    agua <- escalar_cantidad(200)
    azucar <- escalar_cantidad(30)
    limon <- escalar_cantidad(50)
    albahaca <- escalar_cantidad(15)
    
    paste(
      paste("Agua:", agua, "ml"),
      paste("Azúcar:", azucar, "g"),
      paste("Limón:", limon, "ml"),
      paste("Albahaca:", albahaca, "g"),
      sep = "\n"
    )
  })
  
  output$sorbete3_ingredientes <- renderText({
    agua <- escalar_cantidad(200)
    azucar <- escalar_cantidad(30)
    jengibre <- escalar_cantidad(10)
    te <- escalar_cantidad(100)
    
    paste(
      paste("Agua:", agua, "ml"),
      paste("Azúcar:", azucar, "g"),
      paste("Jengibre:", jengibre, "g"),
      paste("Té verde:", te, "ml"),
      sep = "\n"
    )
  })
  
  # Tab Bitácora - Tabla de registro
  output$bitacora_table <- DT::renderDataTable({
    bitacora_data <- data.frame(
      Producto = c("Pollo fresco", "Pescado tilapia", "Camarones", ""),
      Fecha_Entrada = c("2025-01-15", "2025-01-15", "2025-01-16", ""),
      Proveedor = c("Avícola San Juan", "Pescadería El Mar", "Mariscos García", ""),
      Cantidad = c("2 kg", "1.5 kg", "500 g", ""),
      Fecha_Caducidad = c("2025-01-18", "2025-01-17", "2025-01-18", ""),
      Temp_Recepcion = c("3°C", "2°C", "4°C", ""),
      Fecha_Salida = c("2025-01-16", "2025-01-16", "", ""),
      Notas = c("Lote A123", "Origen nacional", "Calibre mediano", ""),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(bitacora_data, 
                  options = list(pageLength = 10, searching = FALSE),
                  editable = TRUE,
                  rownames = FALSE) %>%
      DT::formatStyle(columns = 1:8, 
                      backgroundColor = '#FFFACD',
                      border = '1px solid #DAA520')
  })
  
  # Tab Métodos - Gráfico de temperaturas
  output$temperaturas_chart <- renderPlotly({
    temp_data <- data.frame(
      Metodo = c("Vapor", "Hervido", "Fritura", "Tandoor", "Salteado", "Horneado"),
      Temperatura = c(100, 100, 180, 250, 200, 180),
      stringsAsFactors = FALSE
    )
    
    p <- plot_ly(temp_data, x = ~Metodo, y = ~Temperatura, type = 'bar',
                 marker = list(color = c('#FF6B35', '#F7931E', '#FFD23F', 
                                         '#06FFA5', '#4ECDC4', '#45B7D1'))) %>%
      layout(title = "Temperaturas de Cocción (°C)",
             xaxis = list(title = "Método de Cocción"),
             yaxis = list(title = "Temperatura (°C)"))
    p
  })
  
  # Tab Métodos - Gráfico de tiempos
  output$tiempos_chart <- renderPlotly({
    tiempo_data <- data.frame(
      Metodo = c("Vapor", "Hervido", "Fritura", "Tandoor", "Salteado", "Horneado"),
      Tiempo_Min = c(5, 20, 2, 15, 3, 20),
      Tiempo_Max = c(15, 45, 5, 30, 8, 45),
      stringsAsFactors = FALSE
    )
    
    p <- plot_ly(tiempo_data, x = ~Metodo, y = ~Tiempo_Min, type = 'bar', 
                 name = 'Tiempo Mínimo',
                 marker = list(color = '#FFD700')) %>%
      add_trace(y = ~Tiempo_Max, name = 'Tiempo Máximo',
                marker = list(color = '#FF8C00')) %>%
      layout(title = "Rangos de Tiempo de Cocción",
             xaxis = list(title = "Método de Cocción"),
             yaxis = list(title = "Tiempo (minutos)"),
             barmode = 'group')
    p
  })
  
  # Tab HACCP - Gráfico temperaturas críticas CORREGIDO
  output$temp_criticas_chart <- renderPlotly({
    temp_criticas <- data.frame(
      Producto = c("Pollo", "Pescado", "Camarones"),
      Temperatura = c(74, 63, 63),
      Color = c('#DC143C', '#4169E1', '#FF6347'),
      stringsAsFactors = FALSE
    )
    
    p <- plot_ly(temp_criticas, x = ~Producto, y = ~Temperatura, type = 'bar',
                 marker = list(color = ~Color)) %>%
      layout(title = "Temperaturas Internas Mínimas de Cocción",
             xaxis = list(title = "Producto"),
             yaxis = list(title = "Temperatura (°C)"),
             shapes = list(
               list(type = "line", x0 = -0.5, x1 = 2.5, y0 = 60, y1 = 60,
                    line = list(color = "red", dash = "dash", width = 2))
             ),
             annotations = list(
               list(x = 1, y = 65, text = "Zona de Seguridad: >60°C", 
                    showarrow = FALSE, font = list(color = "red"))
             ))
    p
  })
  
  # Tab Maridaje - Gráfico tipos de bebidas
  output$bebidas_chart <- renderPlotly({
    bebidas_tipos <- c("Vinos", "Cervezas", "Tés", "Bebidas Fermentadas", "Cafés", "Aguas Saborizadas")
    cantidad <- c(4, 1, 2, 2, 2, 1)
    
    p <- plot_ly(labels = bebidas_tipos, values = cantidad, type = 'pie',
                 marker = list(colors = c('#8B0000', '#DAA520', '#228B22', 
                                          '#4682B4', '#8B4513', '#87CEEB'))) %>%
      layout(title = "Distribución de Tipos de Bebidas en Maridajes")
    p
  })
  
  # Tab Maridaje - Gráfico perfil de maridaje CORREGIDO COMPLETAMENTE
  output$maridaje_chart <- renderPlotly({
    perfil_data <- data.frame(
      theta = c("Acidez", "Dulzor", "Cuerpo", "Intensidad", "Frescura"),
      Con_Alcohol = c(6, 4, 7, 8, 5),
      Sin_Alcohol = c(7, 6, 4, 6, 9),
      stringsAsFactors = FALSE
    )
    
    p <- plot_ly(
      type = 'scatterpolar',
      r = perfil_data$Con_Alcohol,
      theta = perfil_data$theta,
      fill = 'toself',
      name = 'Con Alcohol',
      line = list(color = '#8B0000'),
      fillcolor = 'rgba(139,0,0,0.3)'
    ) %>%
      add_trace(
        r = perfil_data$Sin_Alcohol,
        theta = perfil_data$theta,
        fill = 'toself',
        name = 'Sin Alcohol',
        line = list(color = '#228B22'),
        fillcolor = 'rgba(34,139,34,0.3)'
      ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0, 10)
          )
        ),
        showlegend = TRUE,
        title = "Perfil Sensorial de Maridajes"
      )
    
    p
  })
  
  # Tab Recetas - Procedimiento EXPANDIDO
  output$procedimiento_text <- renderText({
    procedimientos <- list(
      "Dumplings de Camarones" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Picar camarones finamente",
        "2. Mezclar con jengibre, cebollín y condimentos",
        "3. Colocar relleno en pasta wonton",
        "4. Sellar bordes con agua",
        "5. Cocer al vapor 5-7 minutos",
        "6. Servir caliente con salsa de soya",
        paste("TIEMPO TOTAL:", 5 + comensales_reactivo(), "minutos"),
        sep = "\n"
      ),
      
      "Ensalada Shirazi" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Lavar y secar vegetales",
        "2. Cortar pepino, tomate y cebolla en cubos pequeños",
        "3. Picar menta finamente",
        "4. Preparar vinagreta con limón y aceite",
        "5. Mezclar todos los ingredientes",
        "6. Servir inmediatamente",
        paste("TIEMPO TOTAL:", 10 + (comensales_reactivo() * 2), "minutos"),
        sep = "\n"
      ),
      
      "Sopa de Lentejas Turca" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Saltear cebolla y zanahoria",
        "2. Agregar lentejas y caldo",
        "3. Añadir tomate concentrado",
        "4. Cocinar 20-25 minutos",
        "5. Triturar hasta obtener textura cremosa",
        "6. Servir caliente con menta seca",
        paste("TIEMPO TOTAL:", 30 + (comensales_reactivo() * 3), "minutos"),
        sep = "\n"
      ),
      
      "Falafel con Jocoque" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Remojar garbanzos toda la noche",
        "2. Procesar con hierbas y especias",
        "3. Formar bolitas o discos",
        "4. Freír en aceite a 180°C por 3-5 minutos",
        "5. Escurrir en papel absorbente",
        "6. Servir con jocoque",
        paste("TIEMPO TOTAL:", 20 + (comensales_reactivo() * 2), "minutos (sin remojo)"),
        sep = "\n"
      ),
      
      "Pollo al Tandoori" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Hacer cortes en el pollo",
        "2. Marinar con yogurt y especias mínimo 4 horas",
        "3. Precalentar horno a 200°C",
        "4. Hornear 25-30 minutos",
        "5. Verificar temperatura interna 74°C",
        "6. Servir con arroz basmati",
        paste("TIEMPO TOTAL:", 35 + (comensales_reactivo() * 3), "minutos (sin marinado)"),
        sep = "\n"
      ),
      
      "Pescado al Wok" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Cortar pescado y vegetales uniformemente",
        "2. Calentar wok a fuego alto",
        "3. Saltear ajo y jengibre 30 segundos",
        "4. Agregar vegetales, cocinar 2-3 minutos",
        "5. Añadir pescado y salsa de soya",
        "6. Cocinar hasta pescado opaco",
        paste("TIEMPO TOTAL:", 15 + comensales_reactivo(), "minutos"),
        sep = "\n"
      ),
      
      "Lokma" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Mezclar harina, levadura y agua tibia",
        "2. Dejar reposar masa 1 hora en lugar cálido",
        "3. Calentar aceite a 175-180°C",
        "4. Formar bolitas con masa",
        "5. Freír hasta dorado",
        "6. Sumergir en jarabe de miel",
        paste("TIEMPO TOTAL:", 15 + (comensales_reactivo() * 2), "minutos (sin reposo)"),
        sep = "\n"
      ),
      
      "Kunafa" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "1. Desmenuzar fideos kunafa",
        "2. Mezclar con mantequilla derretida",
        "3. Colocar mitad en molde, agregar queso",
        "4. Cubrir con resto de fideos",
        "5. Hornear a 180°C por 20-25 minutos",
        "6. Bañar con jarabe caliente",
        paste("TIEMPO TOTAL:", 40 + (comensales_reactivo() * 2), "minutos"),
        sep = "\n"
      )
    )
    
    if (input$platillo_selected %in% names(procedimientos)) {
      procedimientos[[input$platillo_selected]]
    } else {
      "Seleccione un platillo para ver el procedimiento."
    }
  })
}

# Ejecutar la aplicación
shinyApp(ui = ui, server = server)