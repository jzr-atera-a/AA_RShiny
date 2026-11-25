# ============================================================================
# PÁGINAS FIJAS: acceso, panel, mis casas, reportes, historial, configuración
# ============================================================================

pantalla_acceso <- function() {
  conditionalPanel("!output.logueado",
    div(class = "login-wrap",
      div(class = "login-card",
        div(class = "login-brand", div(class = "login-logo", icon("house-chimney")),
            h1("Casas en Renta"), p("Mantenimiento, gastos, rentas e inspecciones de sus propiedades")),
        tabsetPanel(id = "login_tab", type = "pills",
          tabPanel("Administrador", value = "admin",
            div(class = "login-form",
                textInput("email", "Su correo electrónico", placeholder = "nombre@correo.com", width = "100%"),
                p(class = "login-help", "Use el correo que aprobó el dueño."),
                actionButton("btn_admin", "Entrar", icon = icon("arrow-right-to-bracket"), class = "btn-primary btn-block btn-login"))),
          tabPanel("Dueño", value = "dueno",
            div(class = "login-form",
                passwordInput("pin", "Clave del dueño", width = "100%"),
                p(class = "login-help", "Acceso completo: casas, contratos, administradores y reportes."),
                actionButton("btn_dueno", "Entrar como dueño", icon = icon("key"), class = "btn-primary btn-block btn-login")))),
        div(class = "login-foot", paste("Versión", APP_VERSION)))))
}

pagina_inicio <- function() {
  tabItem(tabName = "inicio",
    uiOutput("inicio_head"),
    uiOutput("inicio_kpis"),
    fluidRow(
      column(7, tarjeta("Gastos de los últimos 12 meses", icono = "chart-column", plotOutput("pl_gastos_mes", height = "290px"))),
      column(5, tarjeta("Pendientes y alertas", icono = "bell", class = "card-alerts", uiOutput("inicio_alertas")))),
    fluidRow(
      column(6, tarjeta("Rentas: esperadas vs. cobradas", icono = "money-bill-trend-up", plotOutput("pl_rentas", height = "260px"))),
      column(6, tarjeta("Gastos por categoría (este año)", icono = "chart-bar", plotOutput("pl_categorias", height = "260px")))),
    uiOutput("inicio_casas"),
    uiOutput("inicio_actividad"))
}

pagina_mis_casas <- function() {
  tabItem(tabName = "mis_casas",
    encabezado("Mis casas", "Las casas que usted administra, su periodo, el inquilino y lo pendiente de cada una.", "house-user"),
    uiOutput("casas_cards_admin"))
}

pagina_reportes <- function() {
  tabItem(tabName = "reportes",
    encabezado("Reportes y Excel", "Totales por casa: gastos, rentas cobradas y balance. Descargue todo en un archivo de Excel.", "file-excel",
               downloadButton("rep_excel", "Descargar Excel", class = "btn-success btn-lg-app")),
    div(class = "card",
      div(class = "toolbar",
        div(class = "tb-item", uiOutput("rep_casa_ui")),
        div(class = "tb-item", selectInput("rep_per", "Periodo", choices = c(PERIODOS[-1], "Todo" = "todo", "Personalizado" = "otro"),
                                           selected = "anio", width = "190px")),
        conditionalPanel("input.rep_per == 'otro'", div(class = "tb-item",
          dateRangeInput("rep_rango", "Desde / hasta", start = as.Date(format(hoy(), "%Y-01-01")), end = hoy(),
                         language = "es", format = "dd/mm/yyyy", separator = "a", width = "260px"))))),
    uiOutput("rep_kpis"),
    tarjeta("Resumen por casa", icono = "table", DT::DTOutput("rep_tabla")),
    tarjeta("Gastos por categoría", icono = "tags", DT::DTOutput("rep_categorias")))
}

pagina_historial <- function() {
  tabItem(tabName = "historial",
    encabezado("Historial de cambios", "Quién creó, editó o eliminó cada registro, cuándo y qué valores cambiaron.", "clock-rotate-left"),
    div(class = "card",
      div(class = "toolbar",
        div(class = "tb-item", uiOutput("his_usuario_ui")),
        div(class = "tb-item", selectInput("his_accion", "Acción", choices = c("Todas" = "", "Crear", "Editar", "Eliminar", "Realizado", "Entrar"), width = "160px")),
        div(class = "tb-item", selectInput("his_per", "Periodo", choices = PERIODOS, selected = "3m", width = "190px"))),
      DT::DTOutput("his_tabla")))
}

pagina_config <- function() {
  tabItem(tabName = "config",
    encabezado("Configuración", "Google Drive para los recibos, respaldos de la información y datos de la app.", "gear"),
    fluidRow(
      column(6, tarjeta("Google Drive para los comprobantes", icono = "cloud-arrow-up",
        uiOutput("cfg_estado"),
        textInput("cfg_folder", "ID de la carpeta de Drive", width = "100%", placeholder = "La parte final del enlace de la carpeta"),
        textInput("cfg_sa", "Archivo de la cuenta de servicio (en la carpeta secrets)", width = "100%", placeholder = "cuenta-servicio.json"),
        actionButton("cfg_guardar", "Guardar", icon = icon("check"), class = "btn-primary"),
        tags$details(class = "how", tags$summary("¿Cómo se configura?"),
          tags$ol(tags$li("En Google Cloud cree una cuenta de servicio y active la API de Google Drive."),
                  tags$li("Descargue su llave JSON y póngala en la carpeta secrets de la app."),
                  tags$li("En Drive cree una carpeta y compártala con el correo de la cuenta de servicio como editor."),
                  tags$li("Copie el ID de la carpeta (lo que va después de /folders/ en el enlace) y guárdelo aquí."))))),
      column(6, tarjeta("Respaldo de la información", icono = "shield-halved",
        p("Descargue un respaldo con todo: casas, contratos, administradores, gastos, rentas, órdenes, inspecciones e historial."),
        downloadButton("cfg_respaldo", "Descargar respaldo", class = "btn-primary"),
        hr(),
        p(tags$b("Restaurar un respaldo."), "Reemplaza la información actual por la del archivo. Antes se guarda una copia automática."),
        fileInput("cfg_restaurar_f", NULL, accept = ".json", buttonLabel = "Elegir respaldo…", placeholder = "archivo .json", width = "100%"),
        actionButton("cfg_restaurar", "Restaurar", icon = icon("rotate-left"), class = "btn-danger")),
        tarjeta("Acerca de la app", icono = "circle-info", uiOutput("cfg_info")))))
}
