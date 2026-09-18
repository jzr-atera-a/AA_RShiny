# modules/Six Sigma Analysis/sixsigma_visualizations/ui.R

sixsigma_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Six Sigma Diagram to View", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
            column(3, selectInput(ns("viz_domain"), "Domain: *", choices = NULL)),
            column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
            column(3, selectInput(ns("viz_diagram_id"), "Diagram: *", choices = NULL))
          ),
          actionButton(ns("view"), "Render Diagram", icon = icon("eye"),
                      class = "btn-primary btn-lg", style = "width: 100%;")
      )
    ),
    fluidRow(
      box(title = "Rendered Diagram", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("status")),
          export_controls_ui(ns, ns("export_target"), "sixsigma_diagram"),
          uiOutput(ns("diagram_output"))
      )
    )
  )
}
