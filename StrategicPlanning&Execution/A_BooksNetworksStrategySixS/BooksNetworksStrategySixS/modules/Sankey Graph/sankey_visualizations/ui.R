# modules/Sankey Graph/sankey_visualizations/ui.R

sankey_visualizations_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Select a Sankey Graph to View", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
            column(3, selectInput(ns("viz_domain"), "Domain (Sector): *", choices = NULL)),
            column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
            column(3, selectInput(ns("viz_sankey_id"), "Sankey (Title): *", choices = NULL))
          ),
          fluidRow(
            column(8, actionButton(ns("view"), "Render Sankey", icon = icon("eye"),
                                   class = "btn-primary btn-lg", style = "width: 100%;")),
            column(4, actionButton(ns("refresh"), "Refresh List from BigQuery", icon = icon("sync"),
                                   class = "btn-default btn-lg", style = "width: 100%;"))
          ),
          p(style = "color: #7f8c8d; font-size: 12px; margin-top: 8px;",
            "The dropdowns automatically jump to the most recently uploaded Sankey. If you don't see one you ",
            "just uploaded, click Refresh List to force a fresh pull from BigQuery.")
      )
    ),
    fluidRow(
      box(title = "Rendered Sankey", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("status")),
          uiOutput(ns("sankey_output"))
      )
    )
  )
}
