# Menú Degustación - Sistema Integral de Gestión Gastronómica
# Aplicación para gestión completa de menú, costos, calidad y operaciones
# Basado en el Menú "Ruta de la Seda"

library(shiny)
library(shinydashboard)
library(DT)
library(shinyWidgets)
library(ggplot2)
library(plotly)

# Definir UI
ui <- dashboardPage(
  dashboardHeader(title = "Menú Degustación - Ruta de la Seda"),
  
  dashboardSidebar(
    div(
      style = "padding: 20px 15px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin-bottom: 10px; border-radius: 8px; margin: 10px;",
      h3("Sarai Mazu", style = "color: #ffffff; margin: 0; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
      p("Metodología", style = "color: #e0e7ff; margin: 5px 0 0 0; font-size: 12px;")
    ),
    sidebarMenu(
      menuItem("Menú Degustación", tabName = "menu", icon = icon("utensils")),
      menuItem("Recetas Estandarizadas", tabName = "recetas", icon = icon("book")),
      menuItem("Costos y Rentabilidad", tabName = "costos", icon = icon("calculator")),
      menuItem("Control HACCP", tabName = "haccp", icon = icon("shield-alt")),
      menuItem("Planeación Estratégica", tabName = "planeacion", icon = icon("chess")),
      menuItem("Control de Desviaciones", tabName = "control", icon = icon("clipboard-check")),
      menuItem("Mejora Continua", tabName = "mejora", icon = icon("sync-alt")),
      menuItem("Bitácoras", tabName = "bitacoras", icon = icon("list-alt"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Paleta de colores */
        :root {
          --deep-blue: #0a1128;
          --dark-blue: #1e3c72;
          --medium-blue: #2a5298;
          --bright-blue: #4a90e2;
          --light-blue: #7ec8e3;
          --purple-dark: #3d1f4f;
          --purple-medium: #5e2e6c;
          --purple-light: #764ba2;
        }
        
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
          border-bottom: 3px solid #7ec8e3;
        }
        
        .skin-blue .main-header .logo {
          background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
          border-right: 2px solid #4a90e2;
        }
        
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
          box-shadow: 4px 0 15px rgba(10, 17, 40, 0.5);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          font-weight: bold;
          border-left: 4px solid #7ec8e3;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a {
          color: #e0e7ff !important;
          transition: all 0.3s ease;
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          color: #ffffff !important;
          border-left: 4px solid #7ec8e3;
          transform: translateX(5px);
        }
        
        .content-wrapper {
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
        }
        
        .box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(74, 144, 226, 0.3) !important;
          transition: all 0.3s ease;
        }
        
        .box:hover {
          box-shadow: 0 12px 35px rgba(74, 144, 226, 0.5) !important;
          transform: translateY(-2px);
        }
        
        .box.box-primary .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #4a90e2 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-info .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-success .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-warning .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box-body {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important;
          color: #e0e7ff !important;
          padding: 20px !important;
          border-radius: 0 0 10px 10px;
        }
        
        p { 
          color: #c7d2fe !important; 
          line-height: 1.7 !important; 
        }
        
        strong { 
          color: #7ec8e3 !important; 
          font-weight: 600;
        }
        
        h3, h4, h5, h6 {
          color: #ffffff !important;
        }
        
        .form-control {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 8px;
        }
        
        .btn {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border: none !important;
          border-radius: 8px;
          padding: 10px 20px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn:hover {
          background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(118, 75, 162, 0.4);
        }
        
        .info-box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(74, 144, 226, 0.3);
        }
        
        .info-box-icon {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .info-box-text {
          color: #e0e7ff !important;
        }
        
        .info-box-number {
          color: #7ec8e3 !important;
          font-weight: bold;
        }
        
        .value-box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
          border: 2px solid #4a90e2;
          border-radius: 8px;
          padding: 20px;
          margin: 10px 0;
          text-align: center;
        }
        
        .value-box h3 {
          color: #7ec8e3 !important;
          margin: 0;
          font-size: 32px;
        }
        
        .value-box p {
          color: #c7d2fe !important;
          margin: 5px 0 0 0;
        }
        
        .menu-card {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%);
          border: 2px solid #4a90e2;
          border-radius: 8px;
          padding: 20px;
          margin: 15px 0;
          transition: all 0.3s ease;
        }
        
        .menu-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 10px 30px rgba(74, 144, 226, 0.5);
        }
        
        .platillo-title {
          color: #7ec8e3 !important;
          font-size: 20px;
          font-weight: bold;
          border-bottom: 2px solid #4a90e2;
          padding-bottom: 10px;
          margin-bottom: 15px;
        }
        
        .reference-box {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%);
          border: 2px solid #667eea;
          border-radius: 8px;
          padding: 15px;
          margin-top: 20px;
        }
        
        .reference-box h5 {
          color: #7ec8e3 !important;
          border-bottom: 1px solid #4a90e2;
          padding-bottom: 8px;
          margin-bottom: 12px;
        }
        
        .reference-item {
          color: #c7d2fe !important;
          font-size: 13px;
          line-height: 1.6;
          margin-bottom: 8px;
          padding-left: 15px;
          text-indent: -15px;
        }
        
        table.dataTable {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable thead th {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border-bottom: 2px solid #4a90e2 !important;
        }
        
        table.dataTable tbody tr {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable tbody tr:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        .diagram-box {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%);
          border: 2px solid #667eea;
          border-radius: 8px;
          padding: 20px;
          margin: 15px 0;
          text-align: center;
        }
        
        .proceso-step {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 8px;
          padding: 15px;
          margin: 10px;
          display: inline-block;
          min-width: 150px;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .arrow {
          color: #7ec8e3 !important;
          font-size: 24px;
          margin: 0 10px;
        }
        
        ::-webkit-scrollbar {
          width: 12px;
        }
        
        ::-webkit-scrollbar-track {
          background: #0a1128;
        }
        
        ::-webkit-scrollbar-thumb {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%);
          border-radius: 6px;
        }
      "))
    ),
    
    tabItems(
      # TAB 1: MENÚ DEGUSTACIÓN
      tabItem(tabName = "menu",
              fluidRow(
                box(width = 12, title = "Odisea Culinaria... De Persia a Cantón", 
                    status = "primary", solidHeader = TRUE,
                    h4("Un Recorrido por la Ruta de la Seda"),
                    h5("Menú Degustación de 8 Tiempos")
                )
              ),
              
              fluidRow(
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "1. Dumplings de Camarones"),
                           p(strong("Origen:"), " China / Cantón"),
                           p(strong("Método:"), " Vapor"),
                           p(strong("Descripción:"), " Un bocado delicado, vaporizado a la perfección."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Cerveza tipo Lager"),
                           p(strong("Maridaje sin alcohol:"), " Té de jazmín")
                       )
                ),
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "2. Ensalada Shirazi"),
                           p(strong("Origen:"), " Irán / Shiraz"),
                           p(strong("Método:"), " Corte y Mezcla (sin cocción)"),
                           p(strong("Descripción:"), " Frescura persa en cada bocado."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Sauvignon Blanc"),
                           p(strong("Maridaje sin alcohol:"), " Agua mineral con limón y menta")
                       )
                )
              ),
              
              fluidRow(
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "3. Sopa de Lentejas Turca"),
                           p(strong("Origen:"), " Turquía / Anatolia"),
                           p(strong("Método:"), " Hervido / Fervoroso"),
                           p(strong("Descripción:"), " Un abrazo cálido desde Anatolia."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Vino rosado seco"),
                           p(strong("Maridaje sin alcohol:"), " Ayran")
                       )
                ),
                column(6,
                       box(width = 12, title = "Limpieza de Paladar", status = "info",
                           h5("Sorbete de Litchi y Rosa"),
                           p("Dulce respiro para las papilas.")
                       )
                )
              ),
              
              fluidRow(
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "4. Falafel de Garbanzos"),
                           p(strong("Origen:"), " Egipto / Oriente Medio"),
                           p(strong("Método:"), " Fritura Profunda"),
                           p(strong("Descripción:"), " Crujientes tesoros del Medio Oriente."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Vino tinto ligero (Beaujolais)"),
                           p(strong("Maridaje sin alcohol:"), " Agua de tamarindo")
                       )
                ),
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "5. Pollo al Tandoori"),
                           p(strong("Origen:"), " India / Punjab"),
                           p(strong("Método:"), " Asado en Horno Tandoor"),
                           p(strong("Descripción:"), " Intensidad aromática, directamente del horno."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Gewürztraminer"),
                           p(strong("Maridaje sin alcohol:"), " Lassi de mango")
                       )
                )
              ),
              
              fluidRow(
                column(6,
                       box(width = 12, title = "Limpieza de Paladar", status = "info",
                           h5("Sorbete de Limón y Albahaca"),
                           p("Acidez refrescante para seguir el viaje.")
                       )
                ),
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "6. Pescado al Wok"),
                           p(strong("Origen:"), " Tailandia / Chiang Mai"),
                           p(strong("Método:"), " Salteado / Fritura Rápida"),
                           p(strong("Descripción:"), " Rapidez y frescura en un salteado perfecto."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Pinot Grigio"),
                           p(strong("Maridaje sin alcohol:"), " Té verde helado con jengibre")
                       )
                )
              ),
              
              fluidRow(
                column(6,
                       box(width = 12, title = "Limpieza de Paladar", status = "info",
                           h5("Sorbete de Jengibre y Té Verde"),
                           p("Preparando el paladar para la dulzura.")
                       )
                ),
                column(6,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "7. Lokma"),
                           p(strong("Origen:"), " Turquía / Esmirna"),
                           p(strong("Método:"), " Confitado"),
                           p(strong("Descripción:"), " Un bocado crujiente y dulce."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Moscato d'Asti"),
                           p(strong("Maridaje sin alcohol:"), " Café espresso")
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       div(class = "menu-card",
                           h4(class = "platillo-title", "8. Kunafa"),
                           p(strong("Origen:"), " Arabia Saudita / Oriente Medio"),
                           p(strong("Método:"), " Horneado"),
                           p(strong("Descripción:"), " Un final dorado y memorable."),
                           hr(),
                           p(strong("Maridaje con alcohol:"), " Oporto blanco"),
                           p(strong("Maridaje sin alcohol:"), " Café turco")
                       )
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Montiel, A. (2021). ", em("Patrimonio gastronómico y turismo cultural."), 
                            " Santiago: Editorial Universitaria."
                        ),
                        div(class = "reference-item",
                            "The Culture Trip (2024). ", em("Traditional Middle Eastern dishes."), 
                            " Disponible en: https://theculturetrip.com/middle-east/articles/traditional-middle-eastern-dishes/ [Accedido: 4 Nov 2025]."
                        ),
                        div(class = "reference-item",
                            "The Spruce Eats (2024). ", em("Thai cuisine recipes."), 
                            " Disponible en: https://www.thespruceeats.com/thai-cuisine-recipes-4169528 [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      ),
      
      # TAB 2: RECETAS ESTANDARIZADAS
      tabItem(tabName = "recetas",
              fluidRow(
                box(width = 12, title = "Recetas Estandarizadas", 
                    status = "primary", solidHeader = TRUE,
                    selectInput("select_platillo", "Seleccionar Platillo:",
                                choices = c("Dumplings de Camarones",
                                            "Ensalada Shirazi",
                                            "Sopa de Lentejas Turca",
                                            "Falafel de Garbanzos",
                                            "Pollo al Tandoori",
                                            "Pescado al Wok",
                                            "Lokma",
                                            "Kunafa")),
                    numericInput("num_porciones", "Número de Porciones:", 
                                 value = 4, min = 1, max = 10, step = 1)
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Ingredientes", status = "info",
                    DT::dataTableOutput("tabla_ingredientes")
                ),
                box(width = 6, title = "Procedimiento", status = "success",
                    uiOutput("procedimiento_text")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Información Nutricional y Alérgenos", status = "warning",
                    uiOutput("info_alergenos")
                ),
                box(width = 6, title = "Puntos Críticos de Control", status = "warning",
                    uiOutput("puntos_criticos")
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Mendoza, L. (2019). ", em("Técnicas culinarias fundamentales: Métodos de cocción."), 
                            " Ciudad de México: Grupo Editorial Patria."
                        ),
                        div(class = "reference-item",
                            "Gastronomía y Cía (2024). ", em("Recetas de la Ruta de la Seda."), 
                            " Disponible en: https://www.gastronomiaycia.com/ [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      ),
      
      # TAB 3: COSTOS Y RENTABILIDAD
      tabItem(tabName = "costos",
              fluidRow(
                valueBoxOutput("box_costo_total", width = 4),
                valueBoxOutput("box_precio_sugerido", width = 4),
                valueBoxOutput("box_margen", width = 4)
              ),
              
              fluidRow(
                box(width = 12, title = "Cálculo de Costos por Platillo", 
                    status = "primary", solidHeader = TRUE,
                    selectInput("select_platillo_costo", "Seleccionar Platillo:",
                                choices = c("Dumplings de Camarones",
                                            "Ensalada Shirazi",
                                            "Sopa de Lentejas Turca",
                                            "Falafel de Garbanzos",
                                            "Pollo al Tandoori",
                                            "Pescado al Wok",
                                            "Lokma",
                                            "Kunafa",
                                            "Menú Completo (8 tiempos)"))
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Desglose de Costos", status = "info",
                    plotlyOutput("grafico_costos", height = "400px")
                ),
                box(width = 6, title = "Análisis de Rentabilidad", status = "success",
                    plotlyOutput("grafico_rentabilidad", height = "400px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Tabla Detallada de Costos", status = "warning",
                    DT::dataTableOutput("tabla_costos_detalle")
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Costo de Alimentos y Bebidas (CYB)", status = "info",
                    div(class = "value-box",
                        h3("$850.00"),
                        p("Costo Primo Total")
                    ),
                    hr(),
                    p(strong("Materia Prima:"), " $650.00"),
                    p(strong("Bebidas (Maridaje):"), " $200.00"),
                    p(strong("Food Cost %:"), " 32%")
                ),
                box(width = 4, title = "Gastos de Operación", status = "warning",
                    div(class = "value-box",
                        h3("$520.00"),
                        p("Gastos Operativos")
                    ),
                    hr(),
                    p(strong("Nómina:"), " $300.00"),
                    p(strong("Renta:"), " $150.00"),
                    p(strong("Servicios:"), " $70.00")
                ),
                box(width = 4, title = "Precio de Venta Sugerido", status = "success",
                    div(class = "value-box",
                        h3("$2,650.00"),
                        p("Por Menú Degustación")
                    ),
                    hr(),
                    p(strong("Margen Bruto:"), " 68%"),
                    p(strong("Utilidad:"), " $1,280.00"),
                    p(strong("ROI:"), " 93%")
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Gómez, J. (2018). ", em("Gestión y administración en la restauración."), 
                            " Madrid: Ediciones Pirámide."
                        ),
                        div(class = "reference-item",
                            "National Restaurant Association (2024). ", em("Restaurant Operations Report."), 
                            " Disponible en: https://restaurant.org/ [Accedido: 4 Nov 2025]."
                        ),
                        div(class = "reference-item",
                            "Cornell University School of Hotel Administration (2024). ", em("Food Cost Management."), 
                            " Disponible en: https://sha.cornell.edu/ [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      ),
      
      # TAB 4: CONTROL HACCP
      tabItem(tabName = "haccp",
              fluidRow(
                box(width = 12, title = "Sistema HACCP - Análisis de Peligros y Puntos Críticos de Control", 
                    status = "primary", solidHeader = TRUE,
                    p("El sistema HACCP es fundamental para garantizar la inocuidad alimentaria en todas las etapas de preparación del menú.")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Temperaturas Críticas de Cocción", status = "warning",
                    DT::dataTableOutput("tabla_haccp")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Diagrama de Flujo HACCP", status = "info",
                    div(class = "diagram-box",
                        div(class = "proceso-step", "1. RECEPCIÓN"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "2. ALMACENAMIENTO"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "3. PREPARACIÓN"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "4. COCCIÓN (PCC)"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "5. SERVICIO"),
                        br(), br(),
                        p(strong("PCC = Punto Crítico de Control"), style = "color: #7ec8e3;")
                    )
                ),
                box(width = 6, title = "Medidas Preventivas", status = "success",
                    h5("Control de Temperaturas", style = "color: #7ec8e3;"),
                    p("• Zona de Peligro: 4°C - 60°C"),
                    p("• Refrigeración: 0°C - 4°C"),
                    p("• Congelación: -18°C o menos"),
                    p("• Servicio Caliente: 60°C o más"),
                    hr(),
                    h5("Prevención de Contaminación Cruzada", style = "color: #7ec8e3;"),
                    p("• Tablas de corte por colores"),
                    p("• Separación de alimentos crudos y cocidos"),
                    p("• Higiene de manos constante"),
                    p("• Desinfección de superficies")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Código de Colores para Tablas de Corte", status = "info",
                    fluidRow(
                      column(2, div(style = "background: #f1c40f; padding: 20px; border-radius: 8px; text-align: center;",
                                    p("AMARILLO", style = "color: #000;"),
                                    p("Aves", style = "color: #000; font-size: 12px;"))),
                      column(2, div(style = "background: #e74c3c; padding: 20px; border-radius: 8px; text-align: center;",
                                    p("ROJO"),
                                    p("Carnes", style = "font-size: 12px;"))),
                      column(2, div(style = "background: #3498db; padding: 20px; border-radius: 8px; text-align: center;",
                                    p("AZUL"),
                                    p("Pescados", style = "font-size: 12px;"))),
                      column(2, div(style = "background: #2ecc71; padding: 20px; border-radius: 8px; text-align: center;",
                                    p("VERDE"),
                                    p("Verduras", style = "font-size: 12px;"))),
                      column(2, div(style = "background: #ecf0f1; padding: 20px; border-radius: 8px; text-align: center;",
                                    p("BLANCO", style = "color: #000;"),
                                    p("Lácteos", style = "color: #000; font-size: 12px;"))),
                      column(2, div(style = "background: #8b4513; padding: 20px; border-radius: 8px; text-align: center;",
                                    p("CAFÉ"),
                                    p("Cocidos", style = "font-size: 12px;")))
                    )
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Palazuelos, J. (2020). ", em("Inocuidad alimentaria y el sistema HACCP."), 
                            " Ciudad de México: Trillas."
                        ),
                        div(class = "reference-item",
                            "FDA - Food and Drug Administration (2024). ", em("HACCP Principles & Application Guidelines."), 
                            " Disponible en: https://www.fda.gov/food/hazard-analysis-critical-control-point-haccp [Accedido: 4 Nov 2025]."
                        ),
                        div(class = "reference-item",
                            "Codex Alimentarius Commission (2024). ", em("General Principles of Food Hygiene."), 
                            " Disponible en: https://www.fao.org/fao-who-codexalimentarius/ [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      ),
      
      # TAB 5: PLANEACIÓN ESTRATÉGICA
      tabItem(tabName = "planeacion",
              fluidRow(
                box(width = 12, title = "Planeación Estratégica", 
                    status = "primary", solidHeader = TRUE,
                    div(class = "diagram-box",
                        div(class = "proceso-step", "VISIÓN"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "MISIÓN"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "VALORES"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "ESTRATEGIAS"),
                        div(class = "arrow", "↓"),
                        div(class = "proceso-step", "OBJETIVOS SMART")
                    )
                )
              ),
              
              fluidRow(
                box(width = 4, title = "Misión", status = "info",
                    p("Ofrecer experiencias gastronómicas auténticas e innovadoras que celebren el patrimonio culinario de la Ruta de la Seda, garantizando la más alta calidad, seguridad alimentaria y excelencia en el servicio.")
                ),
                box(width = 4, title = "Visión", status = "success",
                    p("Ser el restaurante referente en cocina internacional de México, reconocido por nuestra autenticidad, innovación y compromiso con la excelencia operativa y la satisfacción del cliente.")
                ),
                box(width = 4, title = "Valores", status = "warning",
                    p(strong("• Calidad:"), " Ingredientes frescos y preparación impecable"),
                    p(strong("• Seguridad:"), " Cumplimiento riguroso de normas HACCP"),
                    p(strong("• Autenticidad:"), " Respeto por las tradiciones culinarias"),
                    p(strong("• Innovación:"), " Mejora continua en procesos"),
                    p(strong("• Excelencia:"), " Servicio al cliente superior")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Estrategias Clave", status = "primary",
                    fluidRow(
                      column(6,
                             h5("1. Diferenciación por Calidad y Seguridad", style = "color: #7ec8e3;"),
                             p("• Implementación completa del sistema HACCP"),
                             p("• Certificaciones de calidad y seguridad alimentaria"),
                             p("• Capacitación continua del personal"),
                             p("• Auditorías internas mensuales"),
                             hr(),
                             h5("2. Excelencia en Servicio al Cliente", style = "color: #7ec8e3;"),
                             p("• Experiencia gastronómica memorable"),
                             p("• Atención personalizada"),
                             p("• Programa de fidelización"),
                             p("• Retroalimentación y mejora continua")
                      ),
                      column(6,
                             h5("3. Optimización Operativa", style = "color: #7ec8e3;"),
                             p("• Estandarización de recetas y procesos"),
                             p("• Control riguroso de costos"),
                             p("• Sistema de bitácoras digitales"),
                             p("• Reducción de merma y desperdicios"),
                             hr(),
                             h5("4. Innovación y Sostenibilidad", style = "color: #7ec8e3;"),
                             p("• Menús estacionales y rotativos"),
                             p("• Proveedores locales y sostenibles"),
                             p("• Reducción de huella ambiental"),
                             p("• Responsabilidad social")
                      )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Objetivos SMART", status = "success",
                    DT::dataTableOutput("tabla_objetivos_smart")
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Kaplan, R.S. y Norton, D.P. (2015). ", em("The Balanced Scorecard: Translating Strategy into Action."), 
                            " Boston: Harvard Business Press."
                        ),
                        div(class = "reference-item",
                            "Porter, M.E. (2008). ", em("Competitive Strategy: Techniques for Analyzing Industries and Competitors."), 
                            " New York: Free Press."
                        ),
                        div(class = "reference-item",
                            "Doran, G.T. (1981). 'There's a S.M.A.R.T. way to write management's goals and objectives', ", 
                            em("Management Review,"), " 70(11), pp. 35-36."
                        )
                    )
                )
              )
      ),
      
      # TAB 6: CONTROL DE DESVIACIONES
      tabItem(tabName = "control",
              fluidRow(
                box(width = 12, title = "Sistema de Control de Desviaciones", 
                    status = "primary", solidHeader = TRUE,
                    div(class = "diagram-box",
                        h4("Loop de Control", style = "color: #7ec8e3;"),
                        br(),
                        div(class = "proceso-step", "MEDIR"),
                        div(class = "arrow", "→"),
                        div(class = "proceso-step", "COMPARAR"),
                        div(class = "arrow", "→"),
                        div(class = "proceso-step", "ANALIZAR"),
                        div(class = "arrow", "→"),
                        div(class = "proceso-step", "CORREGIR"),
                        br(), br(),
                        div(class = "arrow", style = "font-size: 36px;", "↻"),
                        br(),
                        p("Ciclo continuo de mejora", style = "color: #c7d2fe;")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Checklist de Recepción", status = "info",
                    h5("Control de Calidad en Recepción", style = "color: #7ec8e3;"),
                    checkboxInput("check_temp", "Verificar temperatura del producto", FALSE),
                    checkboxInput("check_empaque", "Revisar integridad del empaque", FALSE),
                    checkboxInput("check_etiqueta", "Verificar etiqueta y fecha de caducidad", FALSE),
                    checkboxInput("check_proveedor", "Confirmar proveedor autorizado", FALSE),
                    checkboxInput("check_cantidad", "Verificar cantidad recibida", FALSE),
                    checkboxInput("check_calidad", "Inspección visual de calidad", FALSE),
                    hr(),
                    actionButton("guardar_recepcion", "Guardar Registro", 
                                 class = "btn btn-success", style = "width: 100%;")
                ),
                box(width = 6, title = "Checklist de Servicio", status = "warning",
                    h5("Protocolo de Servicio al Cliente", style = "color: #7ec8e3;"),
                    checkboxInput("check_mise", "Mise en place completo", FALSE),
                    checkboxInput("check_temp_servicio", "Temperatura de servicio correcta", FALSE),
                    checkboxInput("check_presentacion", "Presentación del platillo", FALSE),
                    checkboxInput("check_limpieza", "Limpieza de plato y cristalería", FALSE),
                    checkboxInput("check_maridaje", "Bebida de maridaje lista", FALSE),
                    checkboxInput("check_timing", "Timing correcto entre platillos", FALSE),
                    hr(),
                    actionButton("guardar_servicio", "Guardar Registro", 
                                 class = "btn btn-success", style = "width: 100%;")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Acciones Correctivas Comunes", status = "success",
                    fluidRow(
                      column(6,
                             h5("Desviación: Temperatura Incorrecta en Recepción", style = "color: #7ec8e3;"),
                             p(strong("Acción Inmediata:"), " Rechazar el producto"),
                             p(strong("Registro:"), " Documentar en bitácora de recepción"),
                             p(strong("Seguimiento:"), " Contactar al proveedor"),
                             p(strong("Prevención:"), " Revisar acuerdos de calidad con proveedor"),
                             hr(),
                             h5("Desviación: Temperatura de Cocción Insuficiente", style = "color: #7ec8e3;"),
                             p(strong("Acción Inmediata:"), " Continuar cocción hasta temperatura segura"),
                             p(strong("Registro:"), " Documentar el incidente"),
                             p(strong("Seguimiento:"), " Calibrar termómetros"),
                             p(strong("Prevención:"), " Capacitación en uso de termómetros")
                      ),
                      column(6,
                             h5("Desviación: Merma Excesiva", style = "color: #7ec8e3;"),
                             p(strong("Acción Inmediata:"), " Analizar causa raíz"),
                             p(strong("Registro:"), " Cuantificar pérdida económica"),
                             p(strong("Seguimiento:"), " Ajustar procedimientos de preparación"),
                             p(strong("Prevención:"), " Capacitación en técnicas de aprovechamiento"),
                             hr(),
                             h5("Desviación: Queja del Cliente", style = "color: #7ec8e3;"),
                             p(strong("Acción Inmediata:"), " Atender y documentar queja"),
                             p(strong("Registro:"), " Registrar en sistema de quejas"),
                             p(strong("Seguimiento:"), " Análisis y plan de acción"),
                             p(strong("Prevención:"), " Implementar mejoras identificadas")
                      )
                    )
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Deming, W.E. (2000). ", em("Out of the Crisis."), 
                            " Cambridge: MIT Press."
                        ),
                        div(class = "reference-item",
                            "ISO 22000 (2018). ", em("Food Safety Management Systems - Requirements for any organization in the food chain."), 
                            " Geneva: International Organization for Standardization."
                        ),
                        div(class = "reference-item",
                            "ServSafe (2024). ", em("Manager Certification Program."), 
                            " Disponible en: https://www.servsafe.com/ [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      ),
      
      # TAB 7: MEJORA CONTINUA
      tabItem(tabName = "mejora",
              fluidRow(
                box(width = 12, title = "Ciclo PDCA - Plan, Do, Check, Act", 
                    status = "primary", solidHeader = TRUE,
                    div(class = "diagram-box",
                        h4("Ciclo de Mejora Continua (Deming)", style = "color: #7ec8e3;"),
                        br(),
                        fluidRow(
                          column(3, div(class = "proceso-step", 
                                        h5("PLANIFICAR", style = "margin: 0;"),
                                        p("Identificar", style = "font-size: 12px; margin: 5px 0 0 0;"))),
                          column(3, div(class = "proceso-step", 
                                        h5("HACER", style = "margin: 0;"),
                                        p("Implementar", style = "font-size: 12px; margin: 5px 0 0 0;"))),
                          column(3, div(class = "proceso-step", 
                                        h5("VERIFICAR", style = "margin: 0;"),
                                        p("Monitorear", style = "font-size: 12px; margin: 5px 0 0 0;"))),
                          column(3, div(class = "proceso-step", 
                                        h5("ACTUAR", style = "margin: 0;"),
                                        p("Estandarizar", style = "font-size: 12px; margin: 5px 0 0 0;")))
                        ),
                        br(),
                        div(class = "arrow", style = "font-size: 48px;", "↻"),
                        br(),
                        p("Repetir el ciclo continuamente", style = "color: #c7d2fe; font-size: 14px;")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Plan (Planificar)", status = "info",
                    h5("Identificar Oportunidades de Mejora", style = "color: #7ec8e3;"),
                    p(strong("• Análisis de datos:"), " Revisar bitácoras y registros"),
                    p(strong("• Retroalimentación:"), " Escuchar al equipo y clientes"),
                    p(strong("• Benchmarking:"), " Comparar con mejores prácticas"),
                    p(strong("• Definir objetivos:"), " Establecer metas SMART"),
                    hr(),
                    h5("Ejemplo Práctico", style = "color: #7ec8e3;"),
                    p("Objetivo: Reducir la merma de ingredientes en un 15% en 3 meses mediante mejor control de porciones y técnicas de aprovechamiento.")
                ),
                box(width = 6, title = "Do (Hacer)", status = "success",
                    h5("Implementar el Plan de Acción", style = "color: #7ec8e3;"),
                    p(strong("• Capacitación:"), " Entrenar al personal en nuevos procedimientos"),
                    p(strong("• Recursos:"), " Proveer herramientas necesarias"),
                    p(strong("• Comunicación:"), " Explicar claramente los cambios"),
                    p(strong("• Piloto:"), " Comenzar con prueba controlada"),
                    hr(),
                    h5("Ejemplo Práctico", style = "color: #7ec8e3;"),
                    p("Implementar pesaje preciso de porciones, capacitar en técnicas de corte optimizado y utilizar restos en caldos base.")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Check (Verificar)", status = "warning",
                    h5("Monitorear y Medir Resultados", style = "color: #7ec8e3;"),
                    p(strong("• Indicadores:"), " Medir KPIs definidos"),
                    p(strong("• Registro:"), " Documentar avances y obstáculos"),
                    p(strong("• Comparación:"), " Contrastar con objetivos iniciales"),
                    p(strong("• Análisis:"), " Identificar causa raíz de desviaciones"),
                    hr(),
                    h5("Ejemplo Práctico", style = "color: #7ec8e3;"),
                    p("Después de 1 mes, la merma se redujo 8%. Analizar: ¿Es suficiente? ¿Qué ajustes se necesitan?")
                ),
                box(width = 6, title = "Act (Actuar)", status = "primary",
                    h5("Estandarizar y Mejorar", style = "color: #7ec8e3;"),
                    p(strong("• Si funciona:"), " Estandarizar el proceso"),
                    p(strong("• Documentar:"), " Actualizar manuales y procedimientos"),
                    p(strong("• Capacitar:"), " Extender mejora a todo el equipo"),
                    p(strong("• Si no funciona:"), " Ajustar el plan y repetir ciclo"),
                    hr(),
                    h5("Ejemplo Práctico", style = "color: #7ec8e3;"),
                    p("Actualizar recetas estandarizadas con nuevas técnicas. Continuar monitoreando hacia el objetivo del 15%.")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Programa de Capacitación", status = "info",
                    h4("Plan Anual de Capacitación por Área", style = "color: #7ec8e3;"),
                    br(),
                    fluidRow(
                      column(6,
                             h5("Personal de Cocina", style = "color: #7ec8e3; border-bottom: 2px solid #4a90e2; padding-bottom: 5px;"),
                             p(strong("Trimestre 1:"), " Sistema HACCP y Puntos Críticos"),
                             p(strong("Trimestre 2:"), " Técnicas de cocción avanzadas"),
                             p(strong("Trimestre 3:"), " Reducción de merma y aprovechamiento"),
                             p(strong("Trimestre 4:"), " Innovación y creatividad culinaria"),
                             hr(),
                             h5("Personal de Servicio", style = "color: #7ec8e3; border-bottom: 2px solid #4a90e2; padding-bottom: 5px;"),
                             p(strong("Trimestre 1:"), " Excelencia en servicio al cliente"),
                             p(strong("Trimestre 2:"), " Maridaje y conocimiento de bebidas"),
                             p(strong("Trimestre 3:"), " Manejo de quejas y situaciones difíciles"),
                             p(strong("Trimestre 4:"), " Ventas sugestivas y upselling")
                      ),
                      column(6,
                             h5("Personal Administrativo", style = "color: #7ec8e3; border-bottom: 2px solid #4a90e2; padding-bottom: 5px;"),
                             p(strong("Trimestre 1:"), " Control de costos y rentabilidad"),
                             p(strong("Trimestre 2:"), " Gestión de inventarios y proveedores"),
                             p(strong("Trimestre 3:"), " Análisis de datos y KPIs"),
                             p(strong("Trimestre 4:"), " Planeación estratégica"),
                             hr(),
                             h5("Todo el Personal", style = "color: #7ec8e3; border-bottom: 2px solid #4a90e2; padding-bottom: 5px;"),
                             p(strong("Mensual:"), " Cultura de seguridad alimentaria"),
                             p(strong("Mensual:"), " Trabajo en equipo y comunicación"),
                             p(strong("Trimestral:"), " Simulacros de emergencia"),
                             p(strong("Anual:"), " Actualización en normativas")
                      )
                    )
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "Deming, W.E. (2000). ", em("The New Economics for Industry, Government, Education."), 
                            " Cambridge: MIT Press."
                        ),
                        div(class = "reference-item",
                            "Imai, M. (2012). ", em("Gemba Kaizen: A Commonsense Approach to a Continuous Improvement Strategy."), 
                            " 2nd edn. New York: McGraw-Hill."
                        ),
                        div(class = "reference-item",
                            "American Society for Quality (2024). ", em("Quality Resources: PDCA Cycle."), 
                            " Disponible en: https://asq.org/quality-resources/pdca-cycle [Accedido: 4 Nov 2025]."
                        ),
                        div(class = "reference-item",
                            "Culinary Institute of America (2024). ", em("Professional Development Programs."), 
                            " Disponible en: https://www.ciachef.edu/ [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      ),
      
      # TAB 8: BITÁCORAS
      tabItem(tabName = "bitacoras",
              fluidRow(
                box(width = 12, title = "Sistema de Bitácoras y Registros", 
                    status = "primary", solidHeader = TRUE,
                    p("Registro sistemático de operaciones para garantizar trazabilidad y control de calidad.")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bitácora de Recepción de Productos", status = "info",
                    dateInput("fecha_recepcion", "Fecha:", value = Sys.Date()),
                    selectInput("producto_recepcion", "Producto:",
                                choices = c("Pollo", "Pescado", "Camarones", "Leche", 
                                            "Huevo", "Yogur", "Queso", "Verduras")),
                    textInput("proveedor_recepcion", "Proveedor:"),
                    textInput("lote_recepcion", "Lote:"),
                    dateInput("caducidad_recepcion", "Fecha de Caducidad:"),
                    numericInput("cantidad_recepcion", "Cantidad:", value = 0),
                    numericInput("temp_recepcion", "Temperatura de Recepción (°C):", value = 4),
                    selectInput("cumple_recepcion", "¿Cumple con estándares?",
                                choices = c("Sí", "No")),
                    textAreaInput("observaciones_recepcion", "Observaciones:", 
                                  rows = 3),
                    actionButton("guardar_bitacora", "Guardar Registro", 
                                 class = "btn btn-success", style = "width: 100%;"),
                    hr(),
                    h5("Registros Recientes", style = "color: #7ec8e3;"),
                    DT::dataTableOutput("tabla_bitacora")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Estadísticas de Recepción", status = "success",
                    plotlyOutput("grafico_recepciones", height = "300px")
                ),
                box(width = 6, title = "Control de Cumplimiento", status = "warning",
                    plotlyOutput("grafico_cumplimiento", height = "300px")
                )
              ),
              
              # Referencias
              fluidRow(
                box(width = 12, title = "Referencias Bibliográficas", status = "info",
                    div(class = "reference-box",
                        h5("Fuentes Consultadas - Estilo Harvard"),
                        div(class = "reference-item",
                            "FDA - Food and Drug Administration (2024). ", em("Food Code 2022: Chapter 4 - Equipment, Utensils, and Linens."), 
                            " Disponible en: https://www.fda.gov/food/fda-food-code [Accedido: 4 Nov 2025]."
                        ),
                        div(class = "reference-item",
                            "ISO 9001 (2015). ", em("Quality Management Systems - Requirements."), 
                            " Geneva: International Organization for Standardization."
                        ),
                        div(class = "reference-item",
                            "USDA - United States Department of Agriculture (2024). ", em("Food Safety and Inspection Service: Record Keeping."), 
                            " Disponible en: https://www.fsis.usda.gov/ [Accedido: 4 Nov 2025]."
                        )
                    )
                )
              )
      )
    )
  )
)

# Definir Server
server <- function(input, output, session) {
  
  # Datos de ejemplo para recetas
  recetas_data <- reactive({
    platillo <- input$select_platillo
    porciones <- input$num_porciones
    
    # Base de datos simplificada (ajustar según porciones)
    factor <- porciones / 4
    
    if (platillo == "Dumplings de Camarones") {
      data.frame(
        Ingrediente = c("Pasta wonton", "Camarones", "Jengibre", "Cebollín", "Salsa de soya", "Aceite ajonjolí"),
        Cantidad = c(16 * factor, 400 * factor, 8 * factor, 20 * factor, 20 * factor, 8 * factor),
        Unidad = c("uds", "g", "g", "g", "ml", "ml"),
        stringsAsFactors = FALSE
      )
    } else if (platillo == "Pollo al Tandoori") {
      data.frame(
        Ingrediente = c("Muslo de pollo", "Yogurt", "Ajo y jengibre", "Garam Masala", "Cúrcuma", "Comino"),
        Cantidad = c(800 * factor, 200 * factor, 20 * factor, 12 * factor, 4 * factor, 4 * factor),
        Unidad = c("g", "ml", "g", "g", "g", "g"),
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        Ingrediente = c("Ingrediente 1", "Ingrediente 2", "Ingrediente 3"),
        Cantidad = c(100 * factor, 50 * factor, 25 * factor),
        Unidad = c("g", "ml", "g"),
        stringsAsFactors = FALSE
      )
    }
  })
  
  output$tabla_ingredientes <- DT::renderDataTable({
    DT::datatable(recetas_data(), 
                  options = list(pageLength = 10, dom = 't'),
                  rownames = FALSE)
  })
  
  output$procedimiento_text <- renderUI({
    platillo <- input$select_platillo
    
    if (platillo == "Dumplings de Camarones") {
      div(
        h5("Procedimiento de Elaboración", style = "color: #7ec8e3;"),
        p(strong("1. Preparación del Relleno:"), " Picar camarones finamente. Mezclar con jengibre, cebollín, salsa de soya y aceite."),
        p(strong("2. Montaje:"), " Colocar relleno en centro de cada pasta. Humedecer bordes y sellar."),
        p(strong("3. Cocción al Vapor:"), " Cocinar 5-7 minutos hasta que la pasta esté translúcida."),
        p(strong("4. Servicio:"), " Servir inmediatamente con salsa de soya.")
      )
    } else if (platillo == "Pollo al Tandoori") {
      div(
        h5("Procedimiento de Elaboración", style = "color: #7ec8e3;"),
        p(strong("1. Marinada:"), " Mezclar yogurt con especias. Marinar pollo mínimo 4 horas."),
        p(strong("2. Cocción:"), " Hornear a 200°C por 25-30 minutos."),
        p(strong("3. Control:"), " Verificar temperatura interna de 74°C."),
        p(strong("4. Servicio:"), " Acompañar con arroz basmati y pan naan.")
      )
    } else {
      div(
        h5("Procedimiento de Elaboración", style = "color: #7ec8e3;"),
        p("Procedimiento específico según el platillo seleccionado.")
      )
    }
  })
  
  output$info_alergenos <- renderUI({
    div(
      h5("Alérgenos", style = "color: #7ec8e3;"),
      p(strong("Gluten:"), " Presente en masa wonton"),
      p(strong("Crustáceos:"), " Camarones"),
      p(strong("Soya:"), " Salsa de soya"),
      hr(),
      h5("Alternativas", style = "color: #7ec8e3;"),
      p(strong("Sin gluten:"), " Usar masa de harina de arroz"),
      p(strong("Vegetariana:"), " Relleno de tofu y vegetales")
    )
  })
  
  output$puntos_criticos <- renderUI({
    div(
      h5("Puntos Críticos HACCP", style = "color: #7ec8e3;"),
      p(strong("PCC:"), " Cocción al vapor"),
      p(strong("Temperatura:"), " Camarones deben alcanzar 63°C"),
      p(strong("Tiempo:"), " Mínimo 5 minutos"),
      p(strong("Verificación:"), " Usar termómetro de alimentos"),
      hr(),
      p(strong("Acción correctiva:"), " Si temperatura < 63°C, continuar cocción hasta alcanzar temperatura segura")
    )
  })
  
  # Costos y Rentabilidad
  output$box_costo_total <- renderValueBox({
    valueBox(
      value = "$850.00",
      subtitle = "Costo Total por Menú",
      icon = icon("dollar-sign"),
      color = "blue"
    )
  })
  
  output$box_precio_sugerido <- renderValueBox({
    valueBox(
      value = "$2,650.00",
      subtitle = "Precio de Venta Sugerido",
      icon = icon("tag"),
      color = "green"
    )
  })
  
  output$box_margen <- renderValueBox({
    valueBox(
      value = "68%",
      subtitle = "Margen de Utilidad",
      icon = icon("chart-line"),
      color = "purple"
    )
  })
  
  output$grafico_costos <- renderPlotly({
    df <- data.frame(
      Categoria = c("Materia Prima", "Bebidas", "Mano de Obra", "Gastos Fijos"),
      Monto = c(650, 200, 300, 220)
    )
    
    plot_ly(df, labels = ~Categoria, values = ~Monto, type = 'pie',
            marker = list(colors = c('#667eea', '#764ba2', '#4a90e2', '#7ec8e3'))) %>%
      layout(title = "Distribución de Costos",
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#e0e7ff'))
  })
  
  output$grafico_rentabilidad <- renderPlotly({
    df <- data.frame(
      Concepto = c("Costo Total", "Precio Venta", "Utilidad"),
      Monto = c(850, 2650, 1800)
    )
    
    plot_ly(df, x = ~Concepto, y = ~Monto, type = 'bar',
            marker = list(color = c('#e74c3c', '#2ecc71', '#667eea'))) %>%
      layout(title = "Análisis de Rentabilidad",
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#e0e7ff'),
             yaxis = list(title = "Monto ($MXN)"))
  })
  
  output$tabla_costos_detalle <- DT::renderDataTable({
    df <- data.frame(
      Platillo = c("Dumplings", "Ensalada Shirazi", "Sopa Lentejas", "Falafel", 
                   "Pollo Tandoori", "Pescado Wok", "Lokma", "Kunafa"),
      Costo_MP = c(65, 35, 45, 55, 120, 95, 40, 75),
      Costo_Total = c(85, 50, 60, 75, 155, 125, 55, 95),
      Precio_Venta = c(280, 180, 210, 250, 480, 420, 190, 290),
      Margen = c("70%", "72%", "71%", "70%", "68%", "70%", "71%", "67%"),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(df, 
                  options = list(pageLength = 10),
                  rownames = FALSE,
                  colnames = c("Platillo", "Costo M.P.", "Costo Total", 
                               "Precio Venta", "Margen %"))
  })
  
  # HACCP
  output$tabla_haccp <- DT::renderDataTable({
    df <- data.frame(
      Producto = c("Pollo", "Pescado", "Camarones", "Huevo", "Lácteos"),
      Temp_Coccion = c("74°C", "63°C", "63°C", "71°C", "72-74°C"),
      PCC = c("Cocción", "Cocción", "Cocción", "Cocción", "Recepción"),
      Justificacion = c(
        "Elimina Salmonella y Campylobacter",
        "Destruye parásitos y bacterias",
        "Elimina Vibrio parahaemolyticus",
        "Elimina Salmonella",
        "Pasteurización elimina patógenos"
      ),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(df, 
                  options = list(pageLength = 10),
                  rownames = FALSE,
                  colnames = c("Producto", "Temp. Cocción", "PCC", "Justificación"))
  })
  
  # Objetivos SMART
  output$tabla_objetivos_smart <- DT::renderDataTable({
    df <- data.frame(
      Objetivo = c(
        "Reducir merma en 15%",
        "Aumentar satisfacción cliente a 95%",
        "Certificación HACCP en 6 meses",
        "Reducir tiempo servicio a 2.5 min/platillo",
        "Capacitar 100% personal trimestral"
      ),
      Especifico = c("Sí", "Sí", "Sí", "Sí", "Sí"),
      Medible = c("Sí", "Sí", "Sí", "Sí", "Sí"),
      Alcanzable = c("Sí", "Sí", "Sí", "Sí", "Sí"),
      Relevante = c("Sí", "Sí", "Sí", "Sí", "Sí"),
      Tiempo = c("3 meses", "6 meses", "6 meses", "2 meses", "3 meses"),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(df, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  rownames = FALSE)
  })
  
  # Bitácoras
  bitacora_data <- reactiveValues(
    registros = data.frame(
      Fecha = as.Date(character()),
      Producto = character(),
      Proveedor = character(),
      Lote = character(),
      Cantidad = numeric(),
      Temperatura = numeric(),
      Cumple = character(),
      stringsAsFactors = FALSE
    )
  )
  
  observeEvent(input$guardar_bitacora, {
    nuevo_registro <- data.frame(
      Fecha = input$fecha_recepcion,
      Producto = input$producto_recepcion,
      Proveedor = input$proveedor_recepcion,
      Lote = input$lote_recepcion,
      Cantidad = input$cantidad_recepcion,
      Temperatura = input$temp_recepcion,
      Cumple = input$cumple_recepcion,
      stringsAsFactors = FALSE
    )
    
    bitacora_data$registros <- rbind(bitacora_data$registros, nuevo_registro)
    
    showNotification("Registro guardado exitosamente", type = "message")
  })
  
  output$tabla_bitacora <- DT::renderDataTable({
    DT::datatable(bitacora_data$registros, 
                  options = list(pageLength = 5, order = list(list(0, 'desc'))),
                  rownames = FALSE)
  })
  
  output$grafico_recepciones <- renderPlotly({
    if (nrow(bitacora_data$registros) == 0) {
      return(NULL)
    }
    
    df_agg <- aggregate(Cantidad ~ Producto, data = bitacora_data$registros, FUN = sum)
    
    plot_ly(df_agg, x = ~Producto, y = ~Cantidad, type = 'bar',
            marker = list(color = '#667eea')) %>%
      layout(title = "Recepciones por Producto",
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#e0e7ff'))
  })
  
  output$grafico_cumplimiento <- renderPlotly({
    if (nrow(bitacora_data$registros) == 0) {
      return(NULL)
    }
    
    df_cumple <- table(bitacora_data$registros$Cumple)
    df_cumple <- data.frame(
      Cumple = names(df_cumple),
      Cantidad = as.numeric(df_cumple)
    )
    
    plot_ly(df_cumple, labels = ~Cumple, values = ~Cantidad, type = 'pie',
            marker = list(colors = c('#e74c3c', '#2ecc71'))) %>%
      layout(title = "Cumplimiento de Estándares",
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#e0e7ff'))
  })
}

# Ejecutar la aplicación
shinyApp(ui = ui, server = server)