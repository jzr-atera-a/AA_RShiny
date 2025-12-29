technical_indicators_ui <- function(id) {
  ns <- NS(id)
  tagList(
    conditionalPanel(
      condition = sprintf("output['%s'] != true", ns("dataLoaded")),
      fluidRow(
        box(title = "Technical Indicators", status = "warning", solidHeader = TRUE, width = 12,
            div(class = "data-warning",
                h4("No Data Loaded"),
                p("Please load data from the Database Connection tab to view technical indicators.")))
      )
    ),
    conditionalPanel(
      condition = sprintf("output['%s'] == true", ns("dataLoaded")),
      fluidRow(
        box(title = "Settings", status = "primary", solidHeader = TRUE, width = 3,
            numericInput(ns("sma_period"), "SMA Period:", value = 20, min = 5, max = 200)),
        box(title = "Price with SMA", status = "info", solidHeader = TRUE, width = 9,
            withSpinner(plotlyOutput(ns("technicalChart"), height = 400)))
      )
    )
  )
}
