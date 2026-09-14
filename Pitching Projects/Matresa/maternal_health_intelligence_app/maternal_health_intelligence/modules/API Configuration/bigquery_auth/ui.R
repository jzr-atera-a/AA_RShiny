# modules/API Configuration/bigquery_auth/ui.R
# Maternal Health Intelligence App - BigQuery authentication
# One table: atera-2.business_strategy.maternal_screening_log

bigquery_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google BigQuery Authentication", status = "primary",
        solidHeader = TRUE, width = 12,

        h4("Connect to BigQuery - Maternal Screening Log"),
        p("Authenticate once to enable the Data Log module (upload and browse driver records). ",
          "The Health Monitor and A/B Test modules work fully offline without a connection."),

        div(class = "alert alert-info",
          tags$strong("Target table:"),
          tags$code(" atera-2.business_strategy.maternal_screening_log"),
          tags$br(),
          "The table is created automatically if it does not already exist."
        ),

        fluidRow(
          column(6,
            h5("Upload Service Account JSON:"),
            fileInput(ns("json_file"), "Select JSON File:",
                      accept = ".json", width = "100%"),
            h5("Or paste JSON content:"),
            textAreaInput(ns("json_text"), "JSON Content:", height = "150px",
                          width = "100%",
                          placeholder = "Paste your service account JSON here...")
          ),
          column(6,
            h5("BigQuery Project Configuration"),
            textInput(ns("project_id"), "Project ID:",
                      value = "atera-2", width = "100%"),
            textInput(ns("dataset_id"), "Dataset ID:",
                      value = "business_strategy", width = "100%"),
            br(),
            tags$table(class = "table table-condensed",
              tags$tbody(
                tags$tr(
                  tags$td(tags$strong("Maternal Health table:")),
                  tags$td(tags$code("maternal_screening_log"))
                )
              )
            ),
            p(style = "color:#7f8c8d; font-size:12px;",
              "CREATE TABLE IF NOT EXISTS is run on connect. ",
              "Existing data is never altered or dropped.")
          )
        ),

        br(),
        fluidRow(
          column(5,
            actionButton(ns("authenticate"), "Connect to BigQuery",
              class = "btn-primary btn-lg", icon = icon("plug"),
              style = "width:100%;")
          ),
          column(4,
            selectInput(ns("test_table_choice"), "Test against:",
              choices = c("Driver Health Log" = "schedule"))
          ),
          column(3, br(),
            actionButton(ns("test_query"), "Run Test Query (top 5)",
              class = "btn-info btn-lg", icon = icon("table"),
              style = "width:100%;")
          )
        ),

        hr(),
        h4("Connection Status"),
        htmlOutput(ns("auth_status")),
        htmlOutput(ns("events_schema_status")),

        hr(),
        h4("Test Query Results"),
        htmlOutput(ns("test_status")),
        DT::dataTableOutput(ns("test_table"))
      )
    )
  )
}
