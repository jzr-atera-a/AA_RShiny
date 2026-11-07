# =============================================================================
# Aplicación R Shiny de la tesis:
#   "Integración progresiva de elementos de microelectrónica y robótica en un
#    sistema de navegación autónoma con Realidad Aumentada"
#   José Francisco Zubizarreta Rodríguez — Colegio y Proyectos en
#   Microelectrónica, S.C. (CPM), Ciudad de México, 2026
#
# Ejecución:  shiny::runApp("CPM_Tesis_Shiny")   (o abrir app.R en RStudio)
# Paquetes:   shiny, shinydashboard, plotly, DT, jsonlite
# =============================================================================

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)

.entorno_app <- environment()
for (f in c("datos.R", "calculos.R", "utilidades.R", "tab_inicio_cap1.R", "tab_cap2.R", "tab_cap3.R", "tab_cap4.R",
            "tab_cap5.R", "tab_cap6.R", "tab_cap7_lab.R", "tab_cap8_extra.R", "tab_apendices.R")) {
  source(file.path("modulos", f), local = .entorno_app, encoding = "UTF-8")
}

GEO <- cargar_geojson("data/m25_londres.geojson")
EJEMPLO_CSV <- read.csv("data/ejemplo_seguimiento_simulado.csv")
LISTADOS <- jsonlite::fromJSON("data/listados.json")       # 36 listados de los apéndices C a F

ui <- dashboardPage(
  title = "App CPM · Navegación autónoma con RA",
  skin = "blue",
  dashboardHeader(title = span(icon("robot"), " App CPM"), titleWidth = 260,
                  tags$li(class = "dropdown", span(class = "titulo-barra hidden-xs",
                          "Microelectrónica y robótica en un sistema de navegación autónoma con Realidad Aumentada"))),
  dashboardSidebar(width = 260,
    div(class = "logo-sidebar", tags$img(src = "img/logo_cpm.png", alt = "Colegio y Proyectos en Microelectrónica, S.C.")),
    sidebarMenu(id = "menu",
      menuItem("Inicio", tabName = "inicio", icon = icon("house")),
      tags$li(class = "header", "CAPÍTULOS"),
      menuItem("1. Introducción", tabName = "cap1", icon = icon("flag")),
      menuItem("2. Marco teórico", tabName = "cap2", icon = icon("book")),
      menuItem("3. Arquitectura y mecánica", tabName = "cap3", icon = icon("sitemap")),
      menuItem("4. Etapas 1–2: PIC", tabName = "cap4", icon = icon("microchip")),
      menuItem("5. Etapas 3–4: Arduino y Jetson", tabName = "cap5", icon = icon("server")),
      menuItem("6. Software, gemelo y RA", tabName = "cap6", icon = icon("vr-cardboard")),
      menuItem("7. Seguimiento y validación", tabName = "cap7", icon = icon("route")),
      menuItem("8. Conclusiones", tabName = "cap8", icon = icon("flag-checkered")),
      tags$li(class = "header", "HERRAMIENTAS"),
      menuItem("Laboratorio de seguimiento", tabName = "lab", icon = icon("flask")),
      menuItem("Análisis de pruebas en R", tabName = "analisis", icon = icon("chart-line")),
      menuItem("Plan de estudios CPM", tabName = "plan", icon = icon("graduation-cap")),
      tags$li(class = "header", "REFERENCIAS"),
      menuItem("Bibliografía", tabName = "biblio", icon = icon("bookmark")),
      menuItem("Apéndices técnicos (A, C–F)", tabName = "apendices", icon = icon("code")),
      menuItem("Anexos (B, G, nomenclatura)", tabName = "anexos", icon = icon("folder-open"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Source+Sans+3:wght@400;600;700&family=JetBrains+Mono&display=swap"),
      tags$link(rel = "stylesheet", type = "text/css", href = "estilo.css"),
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css"),
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      # Volver a componer las ecuaciones al cambiar de pestaña
      tags$script(HTML("$(document).on('shown.bs.tab', function(){ if (window.MathJax && MathJax.Hub) MathJax.Hub.Queue(['Typeset', MathJax.Hub]); });"))
    ),
    withMathJax(),
    tabItems(ui_inicio(), ui_cap1(), ui_cap2(), ui_cap3(), ui_cap4(), ui_cap5(), ui_cap6(), ui_cap7(), ui_cap8(),
             ui_lab(), ui_analisis(), ui_plan(), ui_biblio(), ui_apendices(), ui_anexos())
  )
)

server <- function(input, output, session) {
  server_cap1(input, output, session)
  server_cap2(input, output, session)
  server_cap3(input, output, session)
  server_cap4(input, output, session)
  server_cap5(input, output, session)
  server_cap6(input, output, session, GEO)
  server_cap7_lab(input, output, session, GEO, EJEMPLO_CSV)
  server_cap8_extra(input, output, session)
  server_apendices(input, output, session, LISTADOS)
}

shinyApp(ui = ui, server = server)
