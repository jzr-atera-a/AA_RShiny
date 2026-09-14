# modules/API Configuration/bigquery_auth/ui.R

bigquery_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("BigQuery Configuration - shared by all five suites"),
        p("Connect ONCE here. This authenticates Book Summary, Flex Table, Mind Map, Knowledge Graph, AND ",
          "Strategic Analysis together - they share the same project/dataset, but each has its own table, ",
          "all auto-created below."),

        div(class = "alert alert-info",
            tags$strong("Note:"),
            " This app requires a valid Google Cloud service account with BigQuery permissions.",
            tags$br(),
            tags$strong("Tables auto-created on connect (same project/dataset, one table per suite):"),
            tags$ul(
              tags$li(tags$strong("Book Summary:"), " book_summaries_test3"),
              tags$li(tags$strong("Flex Table:"), " flex_comparison_tables"),
              tags$li(tags$strong("Mind Map:"), " mindmap_nodes"),
              tags$li(tags$strong("Knowledge Graph:"), " knowledge_graph"),
              tags$li(tags$strong("Strategic Analysis:"), " strategy_diagrams")
            )),

        fluidRow(
          column(6,
                 h5("Upload Service Account JSON File:"),
                 fileInput(ns("json_file"), "Select JSON File:", accept = ".json", width = "100%"),

                 h5("Or paste JSON content:"),
                 textAreaInput(ns("json_text"), "JSON Content:", height = "150px", width = "100%",
                               placeholder = "Paste your service account JSON here...")
          ),
          column(6,
                 h5("BigQuery Project Configuration"),
                 textInput(ns("project_id"), "Project ID:", value = "atera-2", width = "100%"),
                 textInput(ns("dataset_id"), "Dataset ID:", value = "Wonderfulp_March", width = "100%"),

                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "All five tables live in this one project/dataset. Table names are fixed (shown above) ",
                   "since each suite's code targets its table by name directly.")
          )
        ),

        br(),
        fluidRow(
          column(6,
                 actionButton(ns("authenticate"), "Connect to BigQuery (all 5 tables)",
                              class = "btn-primary btn-lg", icon = icon("plug"), style = "width: 100%;")
          ),
          column(6,
                 selectInput(ns("test_table_choice"), "Table to test-query:",
                            choices = c("Book Summary" = "books", "Flex Table" = "flex", "Mind Map" = "mindmap",
                                        "Knowledge Graph" = "kg", "Strategic Analysis" = "diagram"))
          )
        ),
        actionButton(ns("test_query"), "Test Query (Top 5 Rows of selected table)",
                    class = "btn-info btn-lg", icon = icon("table"), style = "width: 100%;"),

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
