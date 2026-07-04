# modules/bigquery_auth/ui.R

bigquery_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication",
        status = "primary", solidHeader = TRUE, width = 12,

        h4("BigQuery Configuration"),
        p("Connect to your BigQuery dataset to store and retrieve city events."),

        div(class = "alert alert-info",
            tags$strong("Note:"),
            " Requires a Google Cloud service account with BigQuery permissions.",
            tags$br(),
            tags$strong("Schema:"), " The app will create the ", tags$code("city_events"),
            " table automatically if it does not exist."),

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
                 textInput(ns("project_id"), "Project ID:", value = "atera-2",           width = "100%"),
                 textInput(ns("dataset_id"), "Dataset ID:", value = "business_strategy", width = "100%"),
                 textInput(ns("table_id"),   "Table ID:",   value = "city_events",       width = "100%"),
                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "Table will store events with full location, date, category and ticket info.")
          )
        ),

        br(),
        fluidRow(
          column(6,
                 actionButton(ns("authenticate"), "Connect to BigQuery",
                              class = "btn-primary btn-lg", icon = icon("plug"),
                              style = "width: 100%;")
          ),
          column(6,
                 actionButton(ns("test_query"), "Test Query (Top 5 Events)",
                              class = "btn-info btn-lg", icon = icon("table"),
                              style = "width: 100%;")
          )
        ),

        hr(),
        h4("Connection Status"),
        htmlOutput(ns("auth_status")),

        hr(),
        h4("BigQuery Table Schema"),
        div(class = "alert alert-info",
            tags$strong("Table: atera-2.business_strategy.city_events"),
            tags$pre(style = "background:transparent; border:none; margin:0; font-size:0.85em;",
              "id            INTEGER     — Auto-incremented row ID\n",
              "created_at    TIMESTAMP   — Insert timestamp\n",
              "event_name    STRING      — Full name of the event\n",
              "organiser     STRING      — Promoter / organiser name\n",
              "city          STRING      — City (blank = global/top-N scan)\n",
              "country       STRING      — Country\n",
              "category      STRING      — Top-level: Music, Tech, Art, Food, ...\n",
              "subcategory   STRING      — Sub-level: Jazz, AI Conference, ...\n",
              "event_date    STRING      — ISO date YYYY-MM-DD\n",
              "event_time    STRING      — HH:MM or 'All Day'\n",
              "venue_name    STRING      — Venue name\n",
              "address       STRING      — Full street address\n",
              "latitude      STRING      — Decimal degrees or N/A\n",
              "longitude     STRING      — Decimal degrees or N/A\n",
              "description   STRING      — 80-150 word event description\n",
              "ticket_url    STRING      — Ticket purchase URL or N/A\n",
              "price_range   STRING      — e.g. Free, £10-£25, N/A\n",
              "source_url    STRING      — Source website or N/A\n",
              "scan_date     STRING      — Date this record was scanned\n",
              "extra_info    STRING      — Any additional context / notes"
            )
        ),

        hr(),
        h4("Test Query Results"),
        htmlOutput(ns("test_status")),
        DT::dataTableOutput(ns("test_table"))
      )
    )
  )
}
