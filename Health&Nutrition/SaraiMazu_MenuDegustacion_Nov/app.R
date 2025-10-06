# Dashboard Gastronómico - Menú Degustación Ruta de la Seda
# Aplicación educativa interactiva para ciencias gastronómicas
# Basado en el trabajo de la Lic. Miriam Saraí Mazú Quintero

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(shinyWidgets)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Dashboard Gastronómico - Ruta de la Seda"),
  
  dashboardSidebar(
    # Control de Comensales
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
            "Presiona el botón para aplicar cambios")
    ),
    
    sidebarMenu(
      menuItem("Menú Degustación", tabName = "menu", icon = icon("utensils")),
      menuItem("Métodos de Cocción", tabName = "metodos", icon = icon("fire")),
      menuItem("Control HACCP", tabName = "haccp", icon = icon("thermometer")),
      menuItem("Recetas Estandarizadas", tabName = "recetas", icon = icon("book")),
      menuItem("Maridaje de Bebidas", tabName = "maridaje", icon = icon("wine-glass")),
      menuItem("Servicio al Comensal", tabName = "servicio", icon = icon("concierge-bell")),
      menuItem("Limpieza de Paladar", tabName = "limpieza", icon = icon("leaf")),
      menuItem("Bitácora de Control", tabName = "bitacora", icon = icon("clipboard-list"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .navbar {
          background-color: #FF8C00 !important;
        }
        .skin-blue .main-header .logo {
          background-color: #FF8C00 !important;
          color: #000000 !important;
        }
        .skin-blue .main-header .logo:hover {
          background-color: #FF7F00 !important;
        }
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
        .content-wrapper {
          background-color: #FFF8DC !important;
        }
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
        p { color: #2F4F4F !important; line-height: 1.6 !important; }
        strong { color: #B8860B !important; }
        li { color: #2F4F4F !important; margin-bottom: 5px !important; }
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
        .calorie-box {
          background-color: #FFE4B5 !important;
          border: 2px solid #FF8C00 !important;
          border-radius: 8px !important;
          padding: 20px;
          text-align: center;
        }
        .calorie-box h3 {
          color: #FF8C00 !important;
          margin-top: 0 !important;
        }
        .reference-box {
          background-color: #F5F5DC !important;
          border: 1px solid #DAA520 !important;
          border-radius: 5px !important;
          padding: 15px;
          font-size: 12px;
          line-height: 1.8 !important;
        }
        .reference-box p {
          margin-bottom: 8px !important;
        }
      "))
    ),
    
    tabItems(
      # Tab Menú Degustación
      tabItem(tabName = "menu",
              fluidRow(
                div(class = "intro-box",
                    h4("Odisea Culinaria: De Persia a Cantón"),
                    p("Un viaje gastronómico por la Ruta de la Seda. Menú degustación de 8 tiempos que combina preparaciones auténticas de cocina internacional, celebrando la diversidad culinaria desde Persia hasta Cantón."),
                    p(strong("Cortesía de la Licenciada Victoria Cruz"))
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
              ),
              fluidRow(
                box(width = 6, title = "Estimación Calórica Total del Menú", status = "warning",
                    div(class = "calorie-box",
                        htmlOutput("calorias_menu_total")
                    )
                ),
                box(width = 6, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_menu")
                    )
                )
              )
      ),
      
      # Tab Métodos de Cocción
      tabItem(tabName = "metodos",
              fluidRow(
                div(class = "intro-box",
                    h4("Glosario de Métodos de Cocción"),
                    p("Descripción detallada de los 8 métodos de cocción utilizados en el menú degustación, incluyendo temperaturas, tiempos y aplicaciones específicas según el patrimonio gastronómico internacional.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Métodos de Cocción Utilizados", status = "primary", solidHeader = TRUE,
                    selectInput("metodo_selected", "Seleccionar Método:",
                                choices = c("Vapor", "Sin cocción", "Hervido", "Fritura Profunda", 
                                            "Asado en Horno Tandoor", "Salteado Rápido", "Confitado", "Horneado"),
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
              ),
              fluidRow(
                box(width = 6, title = "Impacto Calórico por Método", status = "warning",
                    div(class = "calorie-box",
                        htmlOutput("calorias_metodos")
                    )
                ),
                box(width = 6, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_metodos")
                    )
                )
              )
      ),
      
      # Tab Control HACCP
      tabItem(tabName = "haccp",
              fluidRow(
                div(class = "intro-box",
                    h4("Control HACCP - Productos de Origen Animal"),
                    p("Sistema de Análisis de Peligros y Puntos Críticos de Control aplicado a los productos de origen animal del menú, garantizando la seguridad alimentaria según normativa vigente.")
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
                    div(style = "text-align: center; padding: 20px; background-color: #FFE4E1; border: 3px solid #DC143C; border-radius: 8px;",
                        h3("4°C - 60°C", style = "color: #DC143C;"),
                        p(strong("Zona de temperatura donde las bacterias se multiplican rápidamente.")),
                        p("Los alimentos NO deben permanecer en esta zona por más de 2 horas."),
                        hr(),
                        h5("Temperaturas Seguras:"),
                        p("• Refrigeración: 0°C - 4°C"),
                        p("• Congelación: -18°C o menos"),
                        p("• Alimentos Cocidos: 60°C o más"),
                        p("• Recalentamiento: 74°C")
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Códigos de Color para Tablas de Corte", status = "info",
                    fluidRow(
                      column(2, div(style = "background-color: #FFD700; color: black; padding: 10px; text-align: center; border-radius: 5px; border: 2px solid #B8860B;", strong("AMARILLO"), br(), "Aves")),
                      column(2, div(style = "background-color: red; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("ROJO"), br(), "Carnes Rojas")),
                      column(2, div(style = "background-color: blue; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("AZUL"), br(), "Pescados")),
                      column(2, div(style = "background-color: green; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("VERDE"), br(), "Vegetales")),
                      column(2, div(style = "background-color: white; color: black; padding: 10px; text-align: center; border-radius: 5px; border: 1px solid black;", strong("BLANCO"), br(), "Lácteos")),
                      column(2, div(style = "background-color: brown; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("CAFÉ"), br(), "Cocidos"))
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_haccp")
                    )
                )
              )
      ),
      
      # Tab Recetas Estandarizadas  
      tabItem(tabName = "recetas",
              fluidRow(
                div(class = "intro-box",
                    h4("Recetas Estandarizadas"),
                    p(paste("Recetas calculadas para", textOutput("num_comensales", inline = TRUE), "comensales. Las cantidades se ajustan automáticamente según el número de personas. Todas las recetas incluyen alérgenos y versiones alternativas."))
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
                    DT::dataTableOutput("ingredientes_table"),
                    hr(),
                    htmlOutput("alergenos_info")
                ),
                box(width = 6, title = "Procedimiento", status = "info",
                    verbatimTextOutput("procedimiento_text")
                )
              ),
              fluidRow(
                box(width = 6, title = "Estimación Calórica por Porción", status = "warning",
                    div(class = "calorie-box",
                        htmlOutput("calorias_receta")
                    )
                ),
                box(width = 6, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_recetas")
                    )
                )
              )
      ),
      
      # Tab Maridaje
      tabItem(tabName = "maridaje",
              fluidRow(
                div(class = "intro-box",
                    h4("Maridaje de Bebidas"),
                    p("Propuesta de maridaje con y sin alcohol para cada platillo del menú degustación, diseñadas para complementar y realzar los sabores de cada preparación, respetando las características organolépticas de cada platillo.")
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
              ),
              fluidRow(
                box(width = 6, title = "Contenido Calórico Estimado de Bebidas", status = "warning",
                    div(class = "calorie-box",
                        htmlOutput("calorias_maridaje")
                    )
                ),
                box(width = 6, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_maridaje")
                    )
                )
              )
      ),
      
      # Tab Servicio al Comensal
      tabItem(tabName = "servicio",
              fluidRow(
                div(class = "intro-box",
                    h4("Protocolo de Servicio"),
                    p("Checklist detallado del equipo de servicio y acompañantes necesarios para cada platillo, garantizando una presentación profesional y experiencia completa según estándares internacionales de servicio.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Ambientación Recomendada", status = "primary", solidHeader = TRUE,
                    fluidRow(
                      column(4,
                             h5(strong("Mantelería")),
                             p("Opción 1: Manteles de lino beige o crema para crear una base neutra."),
                             p("Opción 2: Combinar mantel neutro con camino de mesa de seda o brocado en burdeos, azul cobalto o dorado, evocando la Ruta de la Seda.")
                      ),
                      column(4,
                             h5(strong("Centro de Mesa")),
                             p("Opción 1: Jarrones pequeños con ramas de cerezo o flores de loto."),
                             p("Opción 2: Cuencos con especias enteras (anís estrella, clavos, canela) para aromas sutiles.")
                      ),
                      column(4,
                             h5(strong("Música Ambiente")),
                             p("Opción 1: Música instrumental tradicional (laúd, sitar, folclore chino)."),
                             p("Opción 2: Fusión de ritmos tradicionales con elementos modernos y electrónicos a volumen bajo.")
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
              ),
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_servicio")
                    )
                )
              )
      ),
      
      # Tab Limpieza de Paladar
      tabItem(tabName = "limpieza",
              fluidRow(
                div(class = "intro-box",
                    h4("Limpieza de Paladar - Sorbetes"),
                    p("Tres sorbetes estratégicamente ubicados en el menú para limpiar el paladar y preparar las papilas gustativas para el siguiente tiempo."),
                    p(strong("Nota: Los sorbetes no forman parte del menú degustación, son una atención por parte del Chef para apreciar mejor los platillos."))
                )
              ),
              fluidRow(
                box(width = 4, title = "Sorbete de Litchi y Rosa", status = "primary", solidHeader = TRUE,
                    h5(strong("Cuándo servir:")),
                    p("Entre Sopa de Lentejas Turca y Falafel de Garbanzos"),
                    h5(strong("Justificación:")),
                    p("El litchi ofrece un dulzor delicado y floral que, al combinarse con el sutil aroma de la rosa, neutraliza la cremosidad de la sopa y prepara para las especias del falafel."),
                    div(style = "background-color: #FFF8DC; border: 1px solid #DAA520; border-radius: 5px; padding: 10px; margin-top: 10px;",
                        h6(strong("Ingredientes (ajustados):")),
                        verbatimTextOutput("sorbete1_ingredientes")
                    )
                ),
                box(width = 4, title = "Sorbete de Limón y Albahaca", status = "primary", solidHeader = TRUE,
                    h5(strong("Cuándo servir:")),
                    p("Entre Pollo al Tandoori y Pescado al Wok"),
                    h5(strong("Justificación:")),
                    p("La acidez vibrante del limón corta la grasa del yogur del tandoori. La albahaca aporta una nota herbácea que refresca el paladar para la delicadeza del pescado."),
                    div(style = "background-color: #FFF8DC; border: 1px solid #DAA520; border-radius: 5px; padding: 10px; margin-top: 10px;",
                        h6(strong("Ingredientes (ajustados):")),
                        verbatimTextOutput("sorbete2_ingredientes")
                    )
                ),
                box(width = 4, title = "Sorbete de Jengibre y Té Verde", status = "primary", solidHeader = TRUE,
                    h5(strong("Cuándo servir:")),
                    p("Entre Pescado al Wok y los Postres"),
                    h5(strong("Justificación:")),
                    p("El jengibre es picante y estimula las papilas. El té verde con su ligera amargura ayuda a refrescar la boca, actuando como puente entre platos salados y dulces."),
                    div(style = "background-color: #FFF8DC; border: 1px solid #DAA520; border-radius: 5px; padding: 10px; margin-top: 10px;",
                        h6(strong("Ingredientes (ajustados):")),
                        verbatimTextOutput("sorbete3_ingredientes")
                    )
                )
              ),
              fluidRow(
                box(width = 6, title = "Contenido Calórico de Sorbetes", status = "warning",
                    div(class = "calorie-box",
                        htmlOutput("calorias_sorbetes")
                    )
                ),
                box(width = 6, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_limpieza")
                    )
                )
              )
      ),
      
      # Tab Bitácora de Control
      tabItem(tabName = "bitacora",
              fluidRow(
                div(class = "intro-box",
                    h4("Sistema de Bitácora de Control"),
                    p("Formato de registro para el control de productos de origen animal, garantizando trazabilidad y rotación FIFO (First In, First Out) según normativa de inocuidad alimentaria.")
                )
              ),
              fluidRow(
                box(width = 6, title = "Procedimiento de Recepción", status = "primary", solidHeader = TRUE,
                    h5(strong("Pasos de Recepción:")),
                    tags$ol(
                      tags$li("Verificar empaque íntegro y sin daños"),
                      tags$li("Comprobar etiqueta y fecha de caducidad"),
                      tags$li("Medir temperatura (0°C - 4°C para productos frescos)"),
                      tags$li("Rechazar si hay signos de descongelación"),
                      tags$li("Registrar en bitácora inmediatamente")
                    )
                ),
                box(width = 6, title = "Procedimiento de Almacenamiento", status = "primary", solidHeader = TRUE,
                    h5(strong("Pasos de Almacenamiento:")),
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
                      column(2, div(style = "background-color: #FFD700; color: black; padding: 10px; text-align: center; border-radius: 5px; border: 2px solid #B8860B;", strong("AMARILLO"), br(), "Aves")),
                      column(2, div(style = "background-color: red; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("ROJO"), br(), "Carnes Rojas")),
                      column(2, div(style = "background-color: blue; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("AZUL"), br(), "Pescados")),
                      column(2, div(style = "background-color: green; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("VERDE"), br(), "Vegetales")),
                      column(2, div(style = "background-color: white; color: black; padding: 10px; text-align: center; border-radius: 5px; border: 1px solid black;", strong("BLANCO"), br(), "Lácteos")),
                      column(2, div(style = "background-color: brown; color: white; padding: 10px; text-align: center; border-radius: 5px;", strong("CAFÉ"), br(), "Cocidos"))
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        htmlOutput("referencias_bitacora")
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
               "Salteado Rápido", "Confitado", "Horneado"),
    stringsAsFactors = FALSE
  )
  
  # Datos calóricos aproximados por platillo (por porción)
  calorias_platillos <- list(
    "Dumplings de Camarones" = 180,
    "Ensalada Shirazi" = 85,
    "Sopa de Lentejas Turca" = 220,
    "Falafel con Jocoque" = 320,
    "Pollo al Tandoori" = 380,
    "Pescado al Wok" = 280,
    "Lokma" = 250,
    "Kunafa" = 420
  )
  
  # Función para escalar ingredientes
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
  # Tab Menú - Gráfico de métodos
  output$metodos_chart <- renderPlotly({
    metodos <- table(menu_data$Metodo)
    
    p <- plot_ly(labels = names(metodos), values = as.numeric(metodos), type = 'pie',
                 marker = list(colors = c('#FF8C00', '#FFD700', '#DAA520', '#B8860B',
                                          '#F0E68C', '#FFFFE0', '#FFFACD', '#FFF8DC'))) %>%
      layout(title = "Distribución de Métodos de Cocción")
    p
  })
  
  # Tab Menú - Calorías totales
  output$calorias_menu_total <- renderUI({
    total_calorias <- sum(unlist(calorias_platillos))
    HTML(paste0(
      "<h3>", total_calorias, " kcal</h3>",
      "<p><strong>Calorías totales del menú completo por persona</strong></p>",
      "<hr>",
      "<p style='font-size: 14px;'>Para ", comensales_reactivo(), " comensales: <strong>", 
      total_calorias * comensales_reactivo(), " kcal totales</strong></p>",
      "<p style='font-size: 12px; color: #666;'>Nota: Valores aproximados calculados sin bebidas</p>"
    ))
  })
  
  # Tab Menú - Referencias
  output$referencias_menu <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>Montiel, A. (2021). <em>Patrimonio gastronómico y turismo cultural</em>. Santiago, Chile: Editorial Universitaria.</p>",
      "<p>Mendoza, L. (2019). <em>Técnicas culinarias fundamentales: Métodos de cocción</em>. Ciudad de México, México: Grupo Editorial Patria.</p>",
      "<p>The Culture Trip. (s.f.). Platillos tradicionales de Oriente Medio. Recuperado de https://theculturetrip.com/middle-east/articles/traditional-middle-eastern-dishes/</p>",
      "<p>Gastronomía y Cía. (s.f.). Recetas de la Ruta de la Seda. Recuperado de https://www.gastronomiaycia.com/recetas/ruta-de-la-seda/</p>"
    ))
  })
  
  # Tab Métodos - Descripción del método
  output$metodo_descripcion <- renderText({
    descripciones <- list(
      "Vapor" = "Cocción que utiliza el vapor de agua para transmitir calor a los alimentos. Se usa para preservar los nutrientes y la textura delicada de los ingredientes. Temperatura: 100°C. Tiempo: 5-15 minutos. Ideal para alimentos delicados como dumplings y vegetales.",
      
      "Sin cocción" = "Preparación de alimentos que no requiere el uso de calor, sino solo la combinación de ingredientes crudos. Mantiene propiedades nutricionales originales. Se utiliza principalmente para ensaladas frescas y ceviches.",
      
      "Hervido" = "Cocción por inmersión de un alimento en un líquido que se encuentra en punto de ebullición (100°C). Método tradicional para sopas y caldos. Tiempo: 20-45 minutos. Permite la transferencia de sabores y la creación de caldos ricos.",
      
      "Fritura Profunda" = "Cocción por inmersión de un alimento en una materia grasa caliente (180°C o más). Produce una corteza dorada y crujiente. Tiempo: 2-5 minutos. Requiere control estricto de temperatura para evitar absorción excesiva de grasa.",
      
      "Asado en Horno Tandoor" = "Técnica ancestral de cocción por calor seco, donde los alimentos se cocinan en un horno de arcilla cilíndrico. El calor se emite por convección y radiación. Temperatura: 200-300°C. Tiempo: 15-30 minutos. Característico de la cocina india.",
      
      "Salteado Rápido" = "Cocción de alimentos en un medio graso muy caliente y con movimientos rápidos y constantes en un wok o sartén. Tiempo: 3-8 minutos. Conserva textura y color. Técnica fundamental en la cocina asiática.",
      
      "Confitado" = "Técnica de conservación y cocción lenta, sumergiendo los alimentos en un medio graso a baja temperatura (entre 60°C y 90°C). Permite una cocción uniforme y tierna. Tiempo prolongado dependiendo del ingrediente.",
      
      "Horneado" = "Cocción por calor seco en un horno convencional. El calor se transfiere al alimento por convección y radiación. Temperatura: 150-200°C. Tiempo: 20-45 minutos según producto. Ideal para postres y gratinados."
    )
    descripciones[[input$metodo_selected]]
  })
  
  # Tab Métodos - Gráfico de temperaturas
  output$temperaturas_chart <- renderPlotly({
    temp_data <- data.frame(
      Metodo = c("Vapor", "Hervido", "Fritura", "Tandoor", "Salteado", "Horneado", "Confitado"),
      Temperatura = c(100, 100, 180, 250, 200, 180, 75),
      stringsAsFactors = FALSE
    )
    
    p <- plot_ly(temp_data, x = ~Metodo, y = ~Temperatura, type = 'bar',
                 marker = list(color = c('#FF6B35', '#F7931E', '#FFD23F', 
                                         '#06FFA5', '#4ECDC4', '#45B7D1', '#96CEB4'))) %>%
      layout(title = "Temperaturas de Cocción (°C)",
             xaxis = list(title = "Método de Cocción"),
             yaxis = list(title = "Temperatura (°C)"))
    p
  })
  
  # Tab Métodos - Gráfico de tiempos
  output$tiempos_chart <- renderPlotly({
    tiempo_data <- data.frame(
      Metodo = c("Vapor", "Hervido", "Fritura", "Tandoor", "Salteado", "Horneado", "Confitado"),
      Tiempo_Min = c(5, 20, 2, 15, 3, 20, 30),
      Tiempo_Max = c(15, 45, 5, 30, 8, 45, 120),
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
  
  # Tab Métodos - Calorías
  output$calorias_metodos <- renderUI({
    HTML(paste0(
      "<h4>Impacto Calórico de los Métodos</h4>",
      "<p><strong>Vapor:</strong> ~180 kcal (mínimo impacto)</p>",
      "<p><strong>Sin cocción:</strong> ~85 kcal (sin adición de grasa)</p>",
      "<p><strong>Hervido:</strong> ~220 kcal (depende del caldo)</p>",
      "<p><strong>Fritura Profunda:</strong> ~320 kcal (alta absorción de grasa)</p>",
      "<p><strong>Asado Tandoor:</strong> ~380 kcal (con marinado)</p>",
      "<p><strong>Salteado:</strong> ~280 kcal (uso moderado de aceite)</p>",
      "<p><strong>Confitado:</strong> ~250 kcal (cocción lenta en grasa)</p>",
      "<p><strong>Horneado:</strong> ~420 kcal (con ingredientes dulces)</p>"
    ))
  })
  
  # Tab Métodos - Referencias
  output$referencias_metodos <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>Mendoza, L. (2019). <em>Técnicas culinarias fundamentales: Métodos de cocción</em>. Ciudad de México, México: Grupo Editorial Patria.</p>",
      "<p>McGee, H. (2004). <em>On Food and Cooking: The Science and Lore of the Kitchen</em>. New York: Scribner.</p>",
      "<p>Larousse Gastronomique. (2009). <em>Larousse Gastronomique en español</em>. Barcelona: Larousse Editorial.</p>"
    ))
  })
  
  # Tab HACCP - Tabla de control
  output$haccp_table <- DT::renderDataTable({
    haccp_data <- data.frame(
      Producto = c("Pollo", "Pescado", "Camarones", "Huevo", "Lácteos", "Jocoque"),
      Temperatura_Coccion = c("74°C", "63°C", "63°C", "71°C", "72-74°C", "72-74°C"),
      Punto_Critico = c("Cocción", "Cocción", "Cocción", "Cocción", "Recepción y Cocción", "Recepción"),
      Justificacion = c(
        "Destruye Salmonella y Campylobacter",
        "Elimina parásitos (Anisakis) y bacterias (Vibrio)",
        "Elimina Vibrio parahaemolyticus",
        "Destruye Salmonella en huevos",
        "Pasteurización elimina Listeria y E. coli",
        "Pasteurización y refrigeración <4°C"
      ),
      stringsAsFactors = FALSE
    )
    DT::datatable(haccp_data, options = list(pageLength = 6, searching = FALSE, dom = 't'), rownames = FALSE)
  })
  
  # Tab HACCP - Gráfico temperaturas críticas
  output$temp_criticas_chart <- renderPlotly({
    temp_criticas <- data.frame(
      Producto = c("Pollo", "Pescado", "Camarones", "Huevo", "Lácteos"),
      Temperatura = c(74, 63, 63, 71, 73),
      Color = c('#DC143C', '#4169E1', '#FF6347', '#FFD700', '#F0E68C'),
      stringsAsFactors = FALSE
    )
    
    p <- plot_ly(temp_criticas, x = ~Producto, y = ~Temperatura, type = 'bar',
                 marker = list(color = ~Color)) %>%
      layout(title = "Temperaturas Internas Mínimas de Cocción",
             xaxis = list(title = "Producto"),
             yaxis = list(title = "Temperatura (°C)"),
             shapes = list(
               list(type = "line", x0 = -0.5, x1 = 4.5, y0 = 60, y1 = 60,
                    line = list(color = "red", dash = "dash", width = 2))
             ),
             annotations = list(
               list(x = 2, y = 65, text = "Zona de Seguridad: >60°C", 
                    showarrow = FALSE, font = list(color = "red", size = 14))
             ))
    p
  })
  
  # Tab HACCP - Referencias
  output$referencias_haccp <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>Palazuelos, J. (2020). <em>Inocuidad alimentaria y el sistema HACCP</em>. Ciudad de México, México: Trillas.</p>",
      "<p>FDA. (2017). <em>Food Code</em>. U.S. Food and Drug Administration. Recuperado de https://www.fda.gov/food/retail-food-protection/fda-food-code</p>",
      "<p>WHO. (2020). <em>Five Keys to Safer Food Manual</em>. World Health Organization. Geneva.</p>",
      "<p>Forsythe, S. J. (2010). <em>The Microbiology of Safe Food</em> (2nd ed.). Oxford: Wiley-Blackwell.</p>"
    ))
  })
  
  # Tab Recetas - Tabla de ingredientes CORREGIDA
  output$ingredientes_table <- DT::renderDataTable({
    ingredientes_db <- list(
      "Dumplings de Camarones" = data.frame(
        Ingrediente = c("Pasta wonton", "Camarones", "Jengibre", "Cebollín", "Salsa soya", "Aceite ajonjolí"),
        Cantidad_Base = c(4, 100, 2, 5, 5, 2),
        Unidad = c("uds", "g", "g", "g", "ml", "ml"),
        stringsAsFactors = FALSE
      ),
      "Ensalada Shirazi" = data.frame(
        Ingrediente = c("Pepino persa", "Tomate", "Cebolla morada", "Menta", "Limón", "Aceite oliva"),
        Cantidad_Base = c(1, 1, 20, 5, 15, 10),
        Unidad = c("unid", "unid", "g", "g", "ml", "ml"),
        stringsAsFactors = FALSE
      ),
      "Sopa de Lentejas Turca" = data.frame(
        Ingrediente = c("Lentejas rojas", "Cebolla", "Zanahoria", "Caldo", "Tomate concentrado", "Menta seca"),
        Cantidad_Base = c(50, 20, 20, 250, 5, 1),
        Unidad = c("g", "g", "g", "ml", "g", "g"),
        stringsAsFactors = FALSE
      ),
      "Falafel con Jocoque" = data.frame(
        Ingrediente = c("Garbanzos secos", "Cilantro y perejil", "Cebolla blanca", "Comino", "Ajo", "Jocoque"),
        Cantidad_Base = c(50, 15, 15, 2, 3, 30),
        Unidad = c("g", "g", "g", "g", "g", "g"),
        stringsAsFactors = FALSE
      ),
      "Pollo al Tandoori" = data.frame(
        Ingrediente = c("Muslo pollo", "Yogurt", "Garam masala", "Cúrcuma", "Comino", "Arroz basmati"),
        Cantidad_Base = c(200, 50, 3, 1, 1, 100),
        Unidad = c("g", "ml", "g", "g", "g", "g"),
        stringsAsFactors = FALSE
      ),
      "Pescado al Wok" = data.frame(
        Ingrediente = c("Filete tilapia", "Brócoli", "Zanahoria", "Pimiento", "Salsa soya", "Aceite vegetal"),
        Cantidad_Base = c(150, 50, 20, 20, 15, 10),
        Unidad = c("g", "g", "g", "g", "ml", "ml"),
        stringsAsFactors = FALSE
      ),
      "Lokma" = data.frame(
        Ingrediente = c("Harina trigo", "Levadura", "Agua tibia", "Miel", "Aceite freír"),
        Cantidad_Base = c(50, 2, 60, 30, 200),
        Unidad = c("g", "g", "ml", "ml", "ml"),
        stringsAsFactors = FALSE
      ),
      "Kunafa" = data.frame(
        Ingrediente = c("Fideos kunafa", "Mantequilla ghee", "Queso dulce", "Jarabe azúcar", "Pistachos"),
        Cantidad_Base = c(100, 50, 80, 50, 10),
        Unidad = c("g", "g", "g", "ml", "g"),
        stringsAsFactors = FALSE
      )
    )
    
    if (input$platillo_selected %in% names(ingredientes_db)) {
      ingredientes <- ingredientes_db[[input$platillo_selected]]
      
      # CORRECCIÓN: Pasar ambos argumentos a escalar_cantidad
      ingredientes$Cantidad_Ajustada <- sapply(ingredientes$Cantidad_Base, function(x) {
        escalar_cantidad(x, comensales_base = 1)
      })
      
      ingredientes$Cantidad_Final <- paste(ingredientes$Cantidad_Ajustada, ingredientes$Unidad)
      
      resultado <- data.frame(
        Ingrediente = ingredientes$Ingrediente,
        Cantidad = ingredientes$Cantidad_Final
      )
      
      DT::datatable(resultado, 
                    options = list(pageLength = 10, searching = FALSE, dom = 't'), 
                    rownames = FALSE)
    } else {
      DT::datatable(data.frame(Mensaje = "Seleccione un platillo"), 
                    options = list(searching = FALSE, dom = 't'), 
                    rownames = FALSE)
    }
  })
  
  # Tab Recetas - Información de alérgenos
  output$alergenos_info <- renderUI({
    alergenos_db <- list(
      "Dumplings de Camarones" = list(
        alergenos = "Gluten (masa), Crustáceos (camarón), Soya",
        alternativas = "Vegetariana/Vegana: Relleno de tofu y vegetales. Gluten Free: Masa de harina de arroz."
      ),
      "Ensalada Shirazi" = list(
        alergenos = "No contiene alérgenos comunes",
        alternativas = "Dairy Free: Aderezo sin lácteos (solo limón y aceite de oliva)."
      ),
      "Sopa de Lentejas Turca" = list(
        alergenos = "Leche (en algunas preparaciones)",
        alternativas = "Vegana/Dairy Free: Sin mantequilla o yogurt en el servicio."
      ),
      "Falafel con Jocoque" = list(
        alergenos = "Gluten (algunas harinas), Lácteos (jocoque)",
        alternativas = "Gluten Free: Harina de garbanzo 100%. Vegan/Dairy Free: Sustituir jocoque por salsa tahini."
      ),
      "Pollo al Tandoori" = list(
        alergenos = "Lácteos (yogur)",
        alternativas = "Vegetariana/Vegan: Coliflor o tofu marinados. Dairy Free: Adobo con leche de coco."
      ),
      "Pescado al Wok" = list(
        alergenos = "Pescado, Gluten (salsa de soya)",
        alternativas = "Vegetariana/Vegan: Trozos de jackfruit. Gluten Free: Salsa tamari o coco aminos."
      ),
      "Lokma" = list(
        alergenos = "Gluten, Huevo, Leche",
        alternativas = "Gluten Free: Harina de arroz. Vegan/Dairy Free: Sin huevo ni leche."
      ),
      "Kunafa" = list(
        alergenos = "Pistaches, Gluten (fideo), Ghee, Queso dulce",
        alternativas = "Gluten Free: Fideos de harina de tapioca o arroz. Vegan: Queso vegano y ghee vegetal."
      )
    )
    
    info <- alergenos_db[[input$platillo_selected]]
    if (!is.null(info)) {
      HTML(paste0(
        "<div style='background-color: #FFE4E1; border: 2px solid #DC143C; border-radius: 5px; padding: 10px; margin-top: 10px;'>",
        "<h5 style='color: #DC143C;'><strong>⚠️ Alérgenos:</strong></h5>",
        "<p>", info$alergenos, "</p>",
        "</div>",
        "<div style='background-color: #E0FFE0; border: 2px solid #228B22; border-radius: 5px; padding: 10px; margin-top: 10px;'>",
        "<h5 style='color: #228B22;'><strong>✓ Versiones Alternativas:</strong></h5>",
        "<p>", info$alternativas, "</p>",
        "</div>"
      ))
    }
  })
  
  # Tab Recetas - Procedimiento EXPANDIDO
  output$procedimiento_text <- renderText({
    procedimientos <- list(
      "Dumplings de Camarones" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación del Relleno:",
        "   Pique los camarones finamente. Mezcle con jengibre,",
        "   cebollín, salsa de soya, aceite de ajonjolí, sal y pimienta.",
        "",
        "2. Montaje del Dumpling:",
        "   Coloque una porción del relleno en el centro de cada",
        "   pasta wonton. Humedezca bordes con agua y doble",
        "   formando una bolsa, sellando los pliegues.",
        "",
        "3. Cocción y Seguridad:",
        "   Disponga los dumplings en vaporera. Cocine al vapor",
        "   5-7 minutos hasta que la pasta esté translúcida.",
        "   Evite contaminación cruzada entre crudos y cocidos.",
        "",
        paste("TIEMPO TOTAL:", 5 + comensales_reactivo(), "minutos"),
        "",
        "PUNTO CRÍTICO: Camarones deben alcanzar 63°C internos.",
        sep = "\n"
      ),
      
      "Ensalada Shirazi" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación de Vegetales:",
        "   Lave y seque todos los vegetales. Corte pepino,",
        "   tomate y cebolla en cubos pequeños uniformes.",
        "   Pique finamente las hojas de menta.",
        "",
        "2. Mezcla del Aderezo:",
        "   En tazón pequeño, combine jugo de limón, aceite",
        "   de oliva, sal y pimienta. Mezcle bien.",
        "",
        "3. Montaje:",
        "   Combine vegetales y menta en tazón grande.",
        "   Vierta aderezo y mezcle suavemente.",
        "   Sirva inmediatamente para preservar frescura.",
        "",
        paste("TIEMPO TOTAL:", 10 + (comensales_reactivo() * 2), "minutos"),
        "",
        "NOTA: Preparar con ingredientes muy frescos y lavados.",
        sep = "\n"
      ),
      
      "Sopa de Lentejas Turca" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Salteado de Aromáticos:",
        "   En una olla, derrita mantequilla y saltee cebolla",
        "   y zanahoria hasta que estén suaves.",
        "",
        "2. Hervido:",
        "   Agregue lentejas rojas, caldo y tomate concentrado.",
        "   Lleve a ebullición, reduzca fuego y cocine",
        "   20-25 minutos hasta que lentejas estén suaves.",
        "",
        "3. Puré:",
        "   Con licuadora de inmersión, triture hasta cremosa.",
        "   Sirva caliente con menta seca espolvoreada.",
        "",
        paste("TIEMPO TOTAL:", 30 + (comensales_reactivo() * 3), "minutos"),
        "",
        "ALMACENAMIENTO: Refrigerar máximo 3 días a 4°C.",
        sep = "\n"
      ),
      
      "Falafel con Jocoque" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación de Garbanzos:",
        "   Remoje garbanzos la noche anterior. Escurra",
        "   y seque antes de procesar. NO los cocine.",
        "",
        "2. Mezcla del Falafel:",
        "   Procese garbanzos, cilantro, perejil, cebolla,",
        "   ajo y comino hasta obtener mezcla gruesa.",
        "",
        "3. Formado y Cocción:",
        "   Forme bolitas o discos. Caliente aceite a 180°C.",
        "   Fría en tandas 3-5 minutos hasta dorados.",
        "   Use termómetro para control de temperatura.",
        "",
        "4. Servicio:",
        "   Retire y coloque sobre papel absorbente.",
        "   Sirva inmediatamente con jocoque o tahini.",
        "",
        paste("TIEMPO TOTAL:", 20 + (comensales_reactivo() * 2), "minutos (sin remojo)"),
        "",
        "PUNTO CRÍTICO: Aceite a 180°C constante.",
        sep = "\n"
      ),
      
      "Pollo al Tandoori" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación del Pollo:",
        "   Lave y seque muslos. Realice cortes superficiales",
        "   para que penetre la marinada. Evite contaminación",
        "   cruzada con otros alimentos.",
        "",
        "2. Elaboración de Marinada:",
        "   Combine yogurt, pasta ajo-jengibre, garam masala,",
        "   pimentón, cúrcuma, comino, sal, pimienta,",
        "   limón y aceite. Incorpore pollo y marine",
        "   mínimo 4 horas refrigerado.",
        "",
        "3. Cocción y Seguridad:",
        "   Precaliente horno 200°C. Hornee 25-30 minutos.",
        "   Verifique temperatura interna: DEBE alcanzar 74°C",
        "   para eliminar patógenos. Sirva inmediatamente.",
        "",
        paste("TIEMPO TOTAL:", 35 + (comensales_reactivo() * 3), "minutos (sin marinado)"),
        "",
        "PUNTO CRÍTICO: Temperatura interna 74°C obligatoria.",
        sep = "\n"
      ),
      
      "Pescado al Wok" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación:",
        "   Corte pescado en cubos y vegetales uniformes.",
        "   Seque pescado con papel toalla.",
        "",
        "2. Cocción y Seguridad:",
        "   Caliente aceite en wok a fuego alto.",
        "   Saltee ajo y jengibre 30 segundos.",
        "   Incorpore vegetales, cocine 2-3 minutos.",
        "   Agregue pescado y salsa soya, saltee 2-3 minutos.",
        "   ",
        "   Temperatura interna pescado: 63°C para seguridad.",
        "   Sirva inmediatamente.",
        "",
        paste("TIEMPO TOTAL:", 15 + comensales_reactivo(), "minutos"),
        "",
        "PUNTO CRÍTICO: Pescado a 63°C interno.",
        sep = "\n"
      ),
      
      "Lokma" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación de Masa:",
        "   Mezcle harina, levadura y agua tibia hasta",
        "   formar masa pegajosa. Cubra y deje reposar",
        "   en lugar cálido hasta duplicar tamaño.",
        "",
        "2. Confitado:",
        "   Caliente aceite a 80°C en olla a fuego bajo.",
        "   Con dos cucharas, forme bolitas y sumérjalas.",
        "   Confite 15-20 minutos hasta doradas por dentro.",
        "",
        "3. Finalización:",
        "   Suba temperatura a 180°C. Vuelva a sumergir",
        "   lokmas 1-2 minutos para corteza crujiente.",
        "   Escurra y bañe con jarabe caliente.",
        "",
        paste("TIEMPO TOTAL:", 15 + (comensales_reactivo() * 2), "minutos (sin reposo)"),
        "",
        "TÉCNICA: Dos temperaturas para textura perfecta.",
        sep = "\n"
      ),
      
      "Kunafa" = paste(
        "PROCEDIMIENTO PARA", comensales_reactivo(), "COMENSALES:",
        "",
        "1. Preparación de Base:",
        "   Desmenuzar fideos kunafa y mezcle con",
        "   mantequilla ghee derretida.",
        "",
        "2. Ensamblaje:",
        "   En molde, coloque mitad de fideos y presione.",
        "   Agregue capa de queso dulce.",
        "   Cubra con resto de fideos.",
        "",
        "3. Horneado:",
        "   Hornee a 180°C por 20-25 minutos hasta",
        "   superficie dorada.",
        "",
        "4. Finalización:",
        "   Al salir, vierta jarabe caliente sobre kunafa.",
        "   Deje reposar para absorción.",
        "   Decore con pistachos y sirva caliente.",
        "",
        paste("TIEMPO TOTAL:", 40 + (comensales_reactivo() * 2), "minutos"),
        "",
        "NOTA: Servir inmediatamente para textura óptima.",
        sep = "\n"
      )
    )
    
    if (input$platillo_selected %in% names(procedimientos)) {
      procedimientos[[input$platillo_selected]]
    } else {
      "Seleccione un platillo para ver el procedimiento."
    }
  })
  
  # Tab Recetas - Calorías por receta
  output$calorias_receta <- renderUI({
    calorias <- calorias_platillos[[input$platillo_selected]]
    if (!is.null(calorias)) {
      HTML(paste0(
        "<h3>", calorias, " kcal</h3>",
        "<p><strong>Por porción individual</strong></p>",
        "<hr>",
        "<p>Para ", comensales_reactivo(), " comensales:<br>",
        "<strong>", calorias * comensales_reactivo(), " kcal totales</strong></p>",
        "<p style='font-size: 11px; color: #666;'>Valores aproximados calculados con ingredientes base</p>"
      ))
    }
  })
  
  # Tab Recetas - Referencias
  output$referencias_recetas <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>The Spruce Eats. (s.f.). <em>Recetas tradicionales de la cocina tailandesa</em>. Recuperado de https://www.thespruceeats.com/thai-cuisine-recipes-4169528</p>",
      "<p>Roden, C. (2000). <em>The New Book of Middle Eastern Food</em>. New York: Alfred A. Knopf.</p>",
      "<p>Jaffrey, M. (2003). <em>Madhur Jaffrey's Indian Cooking</em>. London: BBC Books.</p>",
      "<p>Lin-Liu, J. (2013). <em>On the Noodle Road: From Beijing to Rome</em>. New York: Riverhead Books.</p>"
    ))
  })
  
  # Tab Maridaje - Tabla de maridajes
  output$maridaje_table <- DT::renderDataTable({
    maridaje_data <- data.frame(
      Platillo = menu_data$Platillo,
      Con_Alcohol = c("Cerveza Lager", "Sauvignon Blanc", "Vino Rosado", "Beaujolais", 
                      "Gewürztraminer", "Pinot Grigio", "Moscato d'Asti", "Oporto Blanco"),
      Sin_Alcohol = c("Té de jazmín", "Agua mineral con menta", "Ayran", "Agua de tamarindo",
                      "Lassi de mango", "Té verde con jengibre", "Café espresso", "Café turco"),
      Justificacion = c(
        "Lager ligera no opaca sabor delicado",
        "Notas cítricas complementan acidez",
        "Cuerpo ligero equilibra cremosidad",
        "Baja astringencia con especias",
        "Aromático resalta especias curry",
        "Ligero acompaña textura pescado",
        "Dulce complementa miel de buñuelos",
        "Robusto balancea dulzor intenso"
      ),
      stringsAsFactors = FALSE
    )
    DT::datatable(maridaje_data, options = list(pageLength = 8, searching = FALSE, dom = 't'), rownames = FALSE)
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
  
  # Tab Maridaje - Gráfico perfil de maridaje
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
  
  # Tab Maridaje - Calorías
  output$calorias_maridaje <- renderUI({
    HTML(paste0(
      "<h4>Calorías Aproximadas por Bebida</h4>",
      "<p><strong>Con Alcohol:</strong></p>",
      "<p>• Cerveza Lager (330ml): ~150 kcal</p>",
      "<p>• Copa vino blanco (150ml): ~120 kcal</p>",
      "<p>• Copa vino rosado (150ml): ~125 kcal</p>",
      "<p>• Copa vino tinto (150ml): ~130 kcal</p>",
      "<p>• Copa vino dulce (100ml): ~160 kcal</p>",
      "<hr>",
      "<p><strong>Sin Alcohol:</strong></p>",
      "<p>• Té (sin azúcar): ~0 kcal</p>",
      "<p>• Agua mineral: ~0 kcal</p>",
      "<p>• Ayran (200ml): ~60 kcal</p>",
      "<p>• Lassi (200ml): ~180 kcal</p>",
      "<p>• Café (sin azúcar): ~2 kcal</p>"
    ))
  })
  
  # Tab Maridaje - Referencias
  output$referencias_maridaje <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>Drinkware. (s.f.). <em>Maridaje de vinos y alimentos</em>. Recuperado de https://www.drinkware.com/maridajes/</p>",
      "<p>Food Republic. (s.f.). <em>Cómo maridar cerveza y comida</em>. Recuperado de https://www.foodrepublic.com/drinks/how-to-pair-beer-and-food/</p>",
      "<p>Serious Eats. (s.f.). <em>Guía de maridaje de café</em>. Recuperado de https://www.seriouseats.com/coffee-pairing-guide-5183424</p>",
      "<p>Harrington, R. J. (2008). <em>Food and Wine Pairing: A Sensory Experience</em>. New Jersey: Wiley.</p>"
    ))
  })
  
  # Tab Servicio - Tabla de checklist
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
                    options = list(pageLength = 5, searching = FALSE, dom = 't'), 
                    rownames = FALSE)
    } else {
      DT::datatable(data.frame(Mensaje = "Seleccione un platillo"), 
                    options = list(searching = FALSE, dom = 't'), 
                    rownames = FALSE)
    }
  })
  
  # Tab Servicio - Referencias
  output$referencias_servicio <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>Hostelería Digital. (2021). <em>Manual de atención al comensal</em>. Recuperado de https://www.hosteleriadigital.com/atencion-cliente</p>",
      "<p>Interiorismo Gastronómico. (2023). <em>La importancia de la ambientación en restaurantes</em>. Recuperado de https://www.interiorismogastronomico.com/ambientacion</p>",
      "<p>Restaurantes Magazine. (2022). <em>Guía para el montaje de mesas</em>. Recuperado de https://www.restaurantesmagazine.com/montaje-mesas</p>",
      "<p>Cousins, J., Foskett, D., & Gillespie, C. (2011). <em>Food and Beverage Management</em> (4th ed.). Essex: Pearson Education.</p>"
    ))
  })
  
  # Tab Limpieza - Ingredientes sorbetes
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
  
  # Tab Limpieza - Calorías sorbetes
  output$calorias_sorbetes <- renderUI({
    HTML(paste0(
      "<h4>Contenido Calórico de los Sorbetes</h4>",
      "<p><strong>Sorbete de Litchi y Rosa:</strong> ~120 kcal/porción</p>",
      "<p><strong>Sorbete de Limón y Albahaca:</strong> ~80 kcal/porción</p>",
      "<p><strong>Sorbete de Jengibre y Té Verde:</strong> ~85 kcal/porción</p>",
      "<hr>",
      "<p><strong>Total 3 sorbetes:</strong> ~285 kcal adicionales</p>",
      "<p style='font-size: 11px; color: #666;'>Los sorbetes son cortesía del Chef y no forman parte del conteo calórico principal del menú</p>"
    ))
  })
  
  # Tab Limpieza - Referencias
  output$referencias_limpieza <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>McGee, H. (2004). <em>On Food and Cooking: The Science and Lore of the Kitchen</em>. New York: Scribner.</p>",
      "<p>This, H. (2009). <em>Molecular Gastronomy: Exploring the Science of Flavor</em>. New York: Columbia University Press.</p>",
      "<p>Belitz, H. D., Grosch, W., & Schieberle, P. (2009). <em>Food Chemistry</em> (4th ed.). Berlin: Springer.</p>"
    ))
  })
  
  # Tab Bitácora - Tabla de registro
  output$bitacora_table <- DT::renderDataTable({
    bitacora_data <- data.frame(
      Producto = c("Pollo fresco", "Pescado tilapia", "Camarones", "Leche", "Huevo", "Yogur", "Queso", "Mantequilla"),
      Fecha_Entrada = c("2025-01-15", "2025-01-15", "2025-01-16", "", "", "", "", ""),
      Proveedor = c("Avícola San Juan", "Pescadería El Mar", "Mariscos García", "", "", "", "", ""),
      Cantidad = c("2 kg", "1.5 kg", "500 g", "", "", "", "", ""),
      Fecha_Caducidad = c("2025-01-18", "2025-01-17", "2025-01-18", "", "", "", "", ""),
      Temp_Recepcion = c("3°C", "2°C", "4°C", "", "", "", "", ""),
      Fecha_Salida = c("2025-01-16", "2025-01-16", "", "", "", "", "", ""),
      Notas = c("Lote A123", "Origen nacional", "Calibre mediano", "", "", "", "", ""),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(bitacora_data, 
                  options = list(pageLength = 10, searching = FALSE, dom = 't'),
                  editable = TRUE,
                  rownames = FALSE) %>%
      DT::formatStyle(columns = 1:8, 
                      backgroundColor = '#FFFACD',
                      border = '1px solid #DAA520')
  })
  
  # Tab Bitácora - Referencias
  output$referencias_bitacora <- renderUI({
    HTML(paste0(
      "<h5><strong>Referencias:</strong></h5>",
      "<p>Gómez, J. (2018). <em>Gestión y administración en la restauración</em>. Madrid, España: Ediciones Pirámide.</p>",
      "<p>Palazuelos, J. (2020). <em>Inocuidad alimentaria y el sistema HACCP</em>. Ciudad de México, México: Trillas.</p>",
      "<p>FDA. (2017). <em>Food Code</em>. U.S. Food and Drug Administration.</p>",
      "<p>Mitchell, R., Fraser, A., & Bearon, L. (2007). <em>Preventing Foodborne Illness in Food Service Establishments</em>. Journal of Environmental Health, 70(9), 27-35.</p>"
    ))
  })
}

# Ejecutar la aplicación
shinyApp(ui = ui, server = server)