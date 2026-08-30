# modules/bigquery_auth/ui.R
# BigQuery Authentication UI
# ==========================

bigquery_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("BigQuery Configuration"),
        p("Connect to your BigQuery dataset to store and retrieve flexible comparison tables."),

        div(class = "alert alert-info",
            tags$strong("Note:"),
            " This app requires a valid Google Cloud service account with BigQuery permissions.",
            tags$br(),
            tags$strong("Default Configuration:"),
            " Project: atera-2, Dataset: Wonderfulp_March, Table: flex_comparison_tables",
            tags$br(),
            tags$strong("Schema:"),
            " id, created_at, source, category, topic, table_title, row_dimension_label, ",
            "column_dimension_label, row_index, columns_data (delimited, holds an ever-changing ",
            "number of columns), notes"),

        fluidRow(
          column(6,
                 h5("Upload Service Account JSON File:"),
                 fileInput(ns("json_file"),
                           "Select JSON File:",
                           accept = ".json",
                           width = "100%"),

                 h5("Or paste JSON content:"),
                 textAreaInput(ns("json_text"),
                               "JSON Content:",
                               height = "150px",
                               width = "100%",
                               placeholder = "Paste your service account JSON here...")
          ),
          column(6,
                 h5("BigQuery Project Configuration"),
                 textInput(ns("project_id"),
                           "Project ID:",
                           value = "atera-2",
                           width = "100%"),

                 textInput(ns("dataset_id"),
                           "Dataset ID:",
                           value = "Wonderfulp_March",
                           width = "100%"),

                 textInput(ns("table_id"),
                           "Table ID:",
                           value = "flex_comparison_tables",
                           width = "100%"),

                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "Table auto-created with the flexible-column schema if it doesn't exist.")
          )
        ),

        br(),
        fluidRow(
          column(6,
                 actionButton(ns("authenticate"),
                              "Connect to BigQuery",
                              class = "btn-primary btn-lg",
                              icon = icon("plug"),
                              style = "width: 100%;")
          ),
          column(6,
                 actionButton(ns("test_query"),
                              "Test Query (Top 5 Rows)",
                              class = "btn-info btn-lg",
                              icon = icon("table"),
                              style = "width: 100%;")
          )
        ),

        hr(),
        h4("Connection Status"),
        htmlOutput(ns("auth_status")),

        hr(),
        h4("Test Query Results"),
        htmlOutput(ns("test_status")),
        DT::dataTableOutput(ns("test_table"))
      )
    )
  )
}
