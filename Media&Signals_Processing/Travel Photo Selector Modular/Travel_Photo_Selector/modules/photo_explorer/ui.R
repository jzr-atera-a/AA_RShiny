photo_explorer_ui <- function(id) {
  ns <- NS(id)

  div(
    class = "explorer-tabs",
    tabsetPanel(
      id = ns("subtabs"), type = "tabs", selected = "elegir",

      # ------------------------------------------------------------------
      # Sub-tab 1 (opens by default): everything except the photo matrix
      # ------------------------------------------------------------------
      tabPanel(
        title = "1. Elegir viaje", value = "elegir", icon = icon("map"),
        div(
          class = "subtab-body",
          uiOutput(ns("stats")),
          fluidRow(
            column(
              width = 8,
              box(
                title = "Elija el viaje y cómo quiere ver las fotos",
                status = "primary", solidHeader = TRUE, width = NULL,
                fluidRow(
                  column(6, selectInput(ns("country"), "País:", choices = NULL, width = "100%")),
                  column(6, selectInput(ns("subfolder"), "Ciudad, región o evento:", choices = NULL, width = "100%"))
                ),
                uiOutput(ns("suggestBanner")),
                fluidRow(
                  column(
                    6,
                    radioButtons(
                      ns("layout"), "¿Cuántas fotos quiere ver en la pantalla?",
                      choices = c("4 fotos grandes (2 × 2)" = "2x2",
                                  "6 fotos medianas (3 × 2)" = "3x2",
                                  "9 fotos más chicas (3 × 3)" = "3x3"),
                      selected = "2x2"
                    )
                  ),
                  column(
                    6,
                    radioButtons(
                      ns("filter"), "Mostrar:",
                      choices = c("Todas las fotos" = "all", "Solo las que ya elegí" = "chosen",
                                  "Las que todavía no elijo" = "not"),
                      selected = "all"
                    )
                  )
                ),
                sliderInput(ns("photoSize"), "Tamaño de las fotos en la pantalla:",
                            min = 60, max = 100, value = 100, step = 5, post = " %", width = "100%"),
                div(class = "wm-hint", style = "margin: -8px 0 14px;",
                    "Si las fotos no caben en la ventana, bájelo. Se aplica al momento."),
                actionButton(ns("apply"), HTML("Ver fotos &#9654;"), class = "btn-success btn-big",
                             style = "width: 100%; font-size: 24px; padding: 16px;"),
                div(
                  class = "info-box-tpl how-to-strip",
                  HTML(paste0(
                    "<b style='color:#667eea;'>📝 ¿Cómo funciona?</b> ",
                    "Elija el país y el lugar, el tamaño de las fotos y presione <b>Ver fotos</b>. ",
                    "Ahí haga clic en una foto (o en <b>Elegir</b>) para marcarla; otra vez para quitarla. ",
                    "Todo se guarda solito."
                  ))
                )
              )
            ),
            column(
              width = 4,
              box(
                title = "Fotos sugeridas por lugar", status = "info", solidHeader = TRUE, width = NULL,
                uiOutput(ns("placeGuide"))
              )
            )
          )
        )
      ),

      # ------------------------------------------------------------------
      # Sub-tab 2: one summary line + the photo matrix
      # ------------------------------------------------------------------
      tabPanel(
        title = "2. Fotos", value = "fotos", icon = icon("images"),
        div(
          class = "subtab-body",
          box(
            width = NULL, status = "primary", solidHeader = FALSE,
            uiOutput(ns("matrixHeader")),
            uiOutput(ns("grid")),
            uiOutput(ns("pager"))
          )
        )
      )
    )
  )
}
