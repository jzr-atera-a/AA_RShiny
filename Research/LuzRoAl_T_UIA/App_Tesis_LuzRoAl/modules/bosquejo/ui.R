bosquejo_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("stats")),
    uiOutput(ns("temaBanner")),
    fluidRow(
      column(7,
        box(title = tagList(icon("sitemap"), " Mi bosquejo: la tesis a vista de pájaro"), status = "primary", solidHeader = TRUE, width = NULL,
            p(class = "lead-text", "El bosquejo es el plano de la casa: no tiene que estar perfecto, se va afinando. Todo se guarda solito."),
            uiOutput(ns("form")),
            uiOutput(ns("saveState"))),
        box(title = tagList(icon("layer-group"), " Capítulos"), status = "primary", solidHeader = TRUE, width = NULL,
            p(class = "lead-text", "Normalmente de 3 a 5 capítulos (sin contar introducción ni conclusiones). Estos nombres aparecen en la pestaña “Capítulos”."),
            uiOutput(ns("chapters")),
            actionButton(ns("addCh"), "Agregar un capítulo", class = "btn-success btn-big", icon = icon("plus"), style = "width: 100%;"))
      ),
      column(5,
        box(title = tagList(icon("robot"), " Ayuda de Claude"), status = "success", solidHeader = TRUE, width = NULL,
            div(class = "claude-actions",
                actionButton(ns("propose"), "Proponerme un bosquejo con mi tema", class = "btn-primary btn-big", icon = icon("magic")),
                actionButton(ns("review"), "Revisar mi bosquejo", class = "btn-success btn-big", icon = icon("search"))),
            ask_box_ui(ns, "ask", "Por ejemplo: ¿Mi pregunta está bien delimitada?", rows = 2)),
        uiOutput(ns("proposal")),
        box(title = "Comentarios de Claude", status = "info", solidHeader = TRUE, width = NULL, uiOutput(ns("feedback")))
      )
    )
  )
}
