risk_metrics_ui <- function(id) {
  ns <- NS(id)
  tagList(
    conditionalPanel(
      condition = sprintf("output['%s'] != true", ns("dataLoaded")),
      fluidRow(
        box(title = "Risk Metrics", status = "warning", solidHeader = TRUE, width = 12,
            div(class = "data-warning",
                h4("No Data Loaded"),
                p("Please load data from the Database Connection tab to view risk metrics.")))
      )
    ),
    conditionalPanel(
      condition = sprintf("output['%s'] == true", ns("dataLoaded")),
      fluidRow(
        valueBoxOutput(ns("varBox"), width = 4),
        valueBoxOutput(ns("maxDDBox"), width = 4),
        valueBoxOutput(ns("sharpeBox"), width = 4)
      ),
      fluidRow(
        box(title = "Drawdown Chart", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(plotlyOutput(ns("ddChart"), height = 400)))
      )
    )
  )
}
