# modules/Strategic Analysis/diagram_browse/ui.R

diagram_browse_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Saved Diagrams (one row per diagram)", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, actionButton(ns("refresh"), "Refresh Data", class = "btn-primary", icon = icon("sync"))),
            column(3, downloadButton(ns("download_catalog"), "Download Catalog CSV", class = "btn-info")),
            column(6, p("Copy a Diagram ID below and paste it into the Visualizations tab to render it."))
          ),
          br(), htmlOutput(ns("status")), br(),
          DT::dataTableOutput(ns("catalog_table"))
      )
    ),
    fluidRow(
      box(title = "Raw Component Rows (strategy_diagrams table)", status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, textInput(ns("filter_diagram_id"), "Filter by Diagram ID (optional):")),
            column(4, numericInput(ns("max_rows"), "Max Rows to Display:", value = 500, min = 10, max = 5000, step = 10)),
            column(4, downloadButton(ns("download_components"), "Download Components CSV", class = "btn-info", style = "margin-top: 25px;"))
          ),
          DT::dataTableOutput(ns("component_table"))
      )
    )
  )
}
