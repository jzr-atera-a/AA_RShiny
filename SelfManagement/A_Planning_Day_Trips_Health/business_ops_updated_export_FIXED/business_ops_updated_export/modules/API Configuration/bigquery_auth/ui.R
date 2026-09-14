# modules/API Configuration/bigquery_auth/ui.R
# One BigQuery connection, three tables (Day Planner, Events, Funding)

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
        p("Connect once to enable all three suites: Day Planner, Events Scheduling, and Funding Programmes."),

        div(class = "alert alert-info",
            tags$strong("Note:"),
            " This app requires a valid Google Cloud service account with BigQuery permissions.",
            tags$br(),
            tags$strong("Default Configuration:"),
            " Project: atera-2, Dataset: business_strategy"),

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
                 textInput(ns("dataset_id"), "Dataset ID:", value = "business_strategy", width = "100%"),

                 tags$table(class = "table table-condensed", style = "margin-top: 10px;",
                   tags$tbody(
                     tags$tr(tags$td(tags$strong("Day Planner:")), tags$td(tags$code("day_scheduler"))),
                     tags$tr(tags$td(tags$strong("Diet Planner:")), tags$td(tags$code("diet_log"))),
                     tags$tr(tags$td(tags$strong("Exercise Tracker:")), tags$td(tags$code("exercise_log"))),
                     tags$tr(tags$td(tags$strong("Events Scheduling:")), tags$td(tags$code("city_events"))),
                     tags$tr(tags$td(tags$strong("Funding Programmes:")), tags$td(tags$code("funding_programmes"))),
                     tags$tr(tags$td(tags$strong("Gantt to Tickets:")), tags$td(tags$code("gantt_tasks, gantt_contacts"))),
                     tags$tr(tags$td(tags$strong("Contact Manager:")), tags$td(tags$code("business_contacts, contact_communications")))
                   )
                 ),
                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "Table names are fixed per suite. Connecting creates any that don't exist yet",
                   " (CREATE TABLE IF NOT EXISTS - never alters or drops an existing table).")
          )
        ),

        br(),
        fluidRow(
          column(5,
                 actionButton(ns("authenticate"), "Connect to BigQuery",
                              class = "btn-primary btn-lg", icon = icon("plug"), style = "width: 100%;")
          ),
          column(4,
                 selectInput(ns("test_table_choice"), "Table to test:",
                             choices = c("Day Planner" = "schedule", "Diet Planner" = "diet",
                                         "Exercise Tracker" = "exercise", "Events Scheduling" = "events",
                                         "Funding Programmes" = "funding", "Gantt Tasks" = "gantt_tasks",
                                         "Gantt Contacts" = "gantt_contacts", "Business Contacts" = "contacts",
                                         "Contact Communications" = "communications"))
          ),
          column(3,
                 br(),
                 actionButton(ns("test_query"), "Test Query (top 5 rows)",
                              class = "btn-info btn-lg", icon = icon("table"), style = "width: 100%;")
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
