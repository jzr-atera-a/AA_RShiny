market_overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    conditionalPanel(
      condition = sprintf("output['%s'] != true", ns("dataLoaded")),
      fluidRow(
        box(title = "Market Overview", status = "warning", solidHeader = TRUE, width = 12,
            div(class = "data-warning",
                h4("No Data Loaded"),
                p("Please load data from the Database Connection tab to view market overview.")))
      )
    ),
    conditionalPanel(
      condition = sprintf("output['%s'] == true", ns("dataLoaded")),
      fluidRow(
        valueBoxOutput(ns("totalPairs"), width = 3),
        valueBoxOutput(ns("totalRecords"), width = 3),
        valueBoxOutput(ns("dateRange"), width = 3),
        valueBoxOutput(ns("avgPrice"), width = 3)
      ),
      fluidRow(
        box(title = "Price Overview", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("overviewPlot"), height = 400)))
      )
    )
  )
}
