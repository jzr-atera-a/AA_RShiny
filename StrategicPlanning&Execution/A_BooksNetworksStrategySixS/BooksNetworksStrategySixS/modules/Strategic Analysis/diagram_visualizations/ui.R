# modules/Strategic Analysis/diagram_visualizations/ui.R

diagram_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Diagram to View", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
            column(3, selectInput(ns("viz_domain"), "Domain: *", choices = NULL)),
            column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
            column(3, selectInput(ns("viz_diagram_id"), "Diagram: *", choices = NULL))
          ),
          fluidRow(
            column(8, actionButton(ns("view"), "Render Diagram", icon = icon("eye"),
                                   class = "btn-primary btn-lg", style = "width: 100%;")),
            column(4, actionButton(ns("refresh"), "Refresh List from BigQuery", icon = icon("sync"),
                                   class = "btn-default btn-lg", style = "width: 100%;"))
          ),
          p(style = "color: #7f8c8d; font-size: 12px; margin-top: 8px;",
            "The dropdowns automatically jump to the most recently uploaded diagram. If you don't see a ",
            "diagram you just uploaded, click Refresh List to force a fresh pull from BigQuery.")
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
