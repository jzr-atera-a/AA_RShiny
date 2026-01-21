price_analysis_ui <- function(id) {
  ns <- NS(id)
  tagList(
    conditionalPanel(
      condition = sprintf("output['%s'] != true", ns("dataLoaded")),
      fluidRow(
        box(title = "Price Analysis", status = "warning", solidHeader = TRUE, width = 12,
            div(class = "data-warning",
                h4("No Data Loaded"),
                p("Please load data from the Database Connection tab to view price analysis.")))
      )
    ),
    conditionalPanel(
      condition = sprintf("output['%s'] == true", ns("dataLoaded")),
      fluidRow(
        box(title = "Price Chart", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("priceChart"), height = 500)))
      )
    )
  )
}
