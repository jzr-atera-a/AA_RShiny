db_connection_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Database Connection Settings", status = "primary", solidHeader = TRUE, width = 6,
          textInput(ns("host"), "Host:", value = "127.0.0.1"),
          numericInput(ns("port"), "Port:", value = 3306),
          textInput(ns("dbname"), "Database:", value = "fx_database"),
          textInput(ns("username"), "Username:", value = "root"),
          passwordInput(ns("password"), "Password:"),
          br(),
          actionButton(ns("testConnection"), "Test Connection", class = "btn-primary"),
          br(), br(),
          uiOutput(ns("connectionStatus"))),
      box(title = "Data Source", status = "info", solidHeader = TRUE, width = 6,
          conditionalPanel(
            condition = sprintf("output['%s'] == true", ns("connectionValid")),
            selectInput(ns("sourceTable"), "Data Source:",
                       choices = list("Daily" = "fx_spot_prices_daily", "Intraday" = "fx_spot_prices")),
            br(),
            actionButton(ns("loadData"), "Load Data", class = "btn-success", style = "width: 100%;"),
            br(), br(),
            uiOutput(ns("dataStatus"))))
    ),
    conditionalPanel(
      condition = sprintf("output['%s'] == true", ns("dataLoaded")),
      fluidRow(
        box(title = "Data Preview", status = "primary", solidHeader = TRUE, width = 12,
            withSpinner(DT::dataTableOutput(ns("dataPreview"))))
      )
    )
  )
}
