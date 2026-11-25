# ============================================================================
# CASAS EN RENTA · Mantenimiento, gastos, rentas e inspecciones · v2.0.0
# Dueño (clave) · administradores (correo aprobado) · comprobantes a Google Drive
# ============================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(DT)
  library(jsonlite)
  library(writexl)
  library(ggplot2)
})

for (f in c("datos.R", "logica.R", "componentes.R", "crud.R", "entidades.R", "paginas.R", "servidor.R"))
  source(file.path("codigo", f), encoding = "UTF-8", local = FALSE)

options(shiny.maxRequestSize = 25 * 1024^2)
addResourcePath("comprobantes", RECIBOS_DIR)

ui <- dashboardPage(
  skin = "purple",
  title = "Casas en Renta",
  dashboardHeader(
    title = span(class = "brand", icon("house-chimney"), "Casas en Renta"),
    titleWidth = 260,
    tags$li(class = "dropdown", uiOutput("user_pill"))
  ),
  dashboardSidebar(
    width = 260,
    sidebarMenuOutput("menu"),
    div(class = "side-foot", paste("v", APP_VERSION))
  ),
  dashboardBody(
    tags$head(
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap"),
      tags$link(rel = "stylesheet", type = "text/css", href = "estilos.css"),
      tags$script(src = "app.js")
    ),
    pantalla_acceso(),
    do.call(tabItems, c(
      list(pagina_inicio(), pagina_mis_casas()),
      lapply(unname(ENTIDADES), crud_page),
      list(pagina_reportes(), pagina_historial(), pagina_config())))
  )
)

server <- function(input, output, session) {
  rol <- reactiveVal(NULL)       # "dueno" | "admin" | NULL
  em  <- reactiveVal("")
  db  <- reactiveVal(0)          # sube cada vez que cambian los datos

  ctx <- reactive({
    db(); r <- rol()
    if (is.null(r)) return(list(rol = NULL))
    casas_all <- read_tbl("casas")
    list(rol = r, email = em(), usuario = if (r == "dueno") "Dueño" else em(),
         casas_all = casas_all, casas = if (r == "dueno") casas_all else admin_casas(em()))
  })
  st <- list(ctx = ctx, db = db, bump = function() db(isolate(db()) + 1), prev_id = reactiveVal(NULL))

  output$logueado <- reactive(!is.null(rol()))
  outputOptions(output, "logueado", suspendWhenHidden = FALSE)

  # ---------------- Acceso
  entrar <- function(r, e = "") {
    rol(r); em(e)
    log_change(if (r == "dueno") "Dueño" else e, "Entrar", "Sesión", "", "Inició sesión")
    session$onFlushed(function() updateTabItems(session, "tabs", "inicio"), once = TRUE)
  }
  observeEvent(input$btn_dueno, {
    if (identical(trimws(input$pin %||% ""), OWNER_PIN)) entrar("dueno")
    else showNotification("La clave no es correcta.", type = "error")
  })
  observeEvent(input$btn_admin, {
    e <- tolower(trimws(input$email %||% ""))
    if (nzchar(e) && e %in% tolower(trimws(read_tbl("admins")$email))) entrar("admin", e)
    else showNotification("Ese correo no está aprobado. Pida al dueño que lo agregue en «Administradores».", type = "error", duration = 8)
  })
  observeEvent(input$salir, session$reload())

  output$menu <- renderMenu({ r <- rol(); req(r); if (r == "dueno") menu_dueno() else menu_admin() })
  output$user_pill <- renderUI({
    r <- rol(); req(r)
    div(class = "user-pill",
        span(class = "avatar", icon(if (r == "dueno") "crown" else "user-tie")),
        span(class = "who", if (r == "dueno") "Dueño" else em()),
        actionLink("salir", tagList(icon("right-from-bracket"), span(class = "hide-sm", "Salir")), class = "logout"))
  })

  for (sp in ENTIDADES) crud_server(sp, input, output, session, st)
  servidor_paginas(input, output, session, st)
}

shinyApp(ui, server)
