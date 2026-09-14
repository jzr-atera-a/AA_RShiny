# modules/Strategic Analysis/diagram_visualizations/ui.R

diagram_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Diagram to View", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(8, selectInput(ns("diagram_select"), "Diagram:", choices = c("Loading..." = ""), width = "100%")),
            column(4, actionButton(ns("view"), "Render Diagram", icon = icon("eye"),
                                   class = "btn-primary btn-lg", style = "width: 100%; margin-top: 25px;"))
          )
      )
    ),
    fluidRow(
      box(title = "Rendered Diagram", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("status")),
          uiOutput(ns("diagram_output"))
      )
    )
  )
}
