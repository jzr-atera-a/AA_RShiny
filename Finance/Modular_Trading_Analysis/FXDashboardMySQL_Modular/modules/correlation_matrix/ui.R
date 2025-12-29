correlation_matrix_ui <- function(id) {
  ns <- NS(id)
  tagList(
    conditionalPanel(
      condition = sprintf("output['%s'] != true", ns("dataLoaded")),
      fluidRow(
        box(title = "Correlation Matrix", status = "warning", solidHeader = TRUE, width = 12,
            div(class = "data-warning",
                h4("No Data Loaded or Wrong Data Type"),
                p("Please load DAILY data from the Database Connection tab to view correlation matrix."),
                p("Note: Correlation analysis requires multiple currency pairs in daily format.")))
      )
    ),
    conditionalPanel(
      condition = sprintf("output['%s'] == true", ns("dataLoaded")),
      fluidRow(
        box(title = "Correlation Heatmap", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("corrHeatmap"), height = 500)))
      )
    )
  )
}
