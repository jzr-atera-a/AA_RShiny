# modules/Exercise Tracker/muscle_map/ui.R

muscle_map_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Interactive muscle map", status = "primary", solidHeader = TRUE, width = 8,
          fluidRow(
            column(4, radioButtons(ns("view"), "View", choices = c("Front and back" = "both", "Front" = "front", "Back" = "back"), inline = TRUE)),
            column(5, selectInput(ns("mode"), "Colour by", width = "100%", choices = c(
              "Gaps this week (sets vs weekly target)" = "gaps", "Anatomy colours (book style)" = "anatomy",
              "Training volume, last 28 days" = "vol28", "A planned workout" = "session"))),
            column(3, checkboxInput(ns("names"), "Show muscle names", FALSE), actionButton(ns("reload"), "Reload", icon = icon("sync"), class = "btn-sm"))
          ),
          conditionalPanel(sprintf("input['%s'] == 'session'", ns("mode")), selectInput(ns("programme"), "Planned workout", choices = character(0), width = "100%")),
          uiOutput(ns("legend")),
          uiOutput(ns("figure")),
          p(tags$small("Click any muscle for its details. The figure is drawn from data (muscle ids and sets), so the same diagram can be regenerated from the stored specs."))
      ),
      box(title = "Selected muscle", status = "info", solidHeader = TRUE, width = 4, uiOutput(ns("details")))
    ),
    fluidRow(
      box(title = "What is missing this week", status = "warning", solidHeader = TRUE, width = 12, uiOutput(ns("gap_summary")), DT::dataTableOutput(ns("gap_tbl")))
    )
  )
}
