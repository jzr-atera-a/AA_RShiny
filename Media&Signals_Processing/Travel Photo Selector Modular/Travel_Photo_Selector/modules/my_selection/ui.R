my_selection_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(
      width = 4,
      box(
        title = "Mi pedido hasta ahora",
        status = "primary",
        solidHeader = TRUE,
        width = NULL,
        uiOutput(ns("summary")),
        br(),
        downloadButton(ns("downloadList"), "Descargar mi lista (CSV)", class = "btn-success btn-big",
                       style = "width: 100%;")
      ),
      box(
        title = "Información",
        status = "info",
        solidHeader = TRUE,
        width = NULL,
        div(
          class = "info-box-tpl",
          h4(style = "margin-top: 0; color: #667eea;", "💡 Para que sepa"),
          tags$ul(
            tags$li("Todo lo que marque se guarda al momento."),
            tags$li("Si cierra el programa, sus fotos elegidas seguirán aquí la próxima vez."),
            tags$li(HTML("Para quitar una foto, haga clic en su botón verde <b>Elegida</b>."))
          )
        )
      )
    ),
    column(
      width = 8,
      box(
        title = "Ver las fotos que elegí",
        status = "primary",
        solidHeader = TRUE,
        width = NULL,
        selectInput(ns("country"), "País:", choices = NULL, width = "100%"),
        uiOutput(ns("gallery"))
      )
    )
  )
}
