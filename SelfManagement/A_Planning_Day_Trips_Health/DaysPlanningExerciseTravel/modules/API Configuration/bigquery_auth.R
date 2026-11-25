# modules/API Configuration/bigquery_auth.R
# ---- module ----------------------------------------------
# id:           bigquery_auth
# name:         BigQuery Authentication
# label:        BigQuery Setup
# icon:         database
# description:  Authenticate to Google BigQuery - one connection, three tables
# packages:     shiny, shinydashboard, bigrquery, jsonlite
# -----------------------------------------------------------

# ---- UI ----
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

        uiOutput(ns("auto_note")),
        h4("BigQuery Configuration"),
        p("Connect once to enable every suite: Day Planner, Diet Planner, Exercise Tracker and Events Scheduling."),

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
                     tags$tr(tags$td(tags$strong("Day Planner:")), tags$td(tags$code("day_scheduler, day_prep_steps, monthly_commitments"))),
                     tags$tr(tags$td(tags$strong("Diet Planner:")), tags$td(tags$code("diet_log"))),
                     tags$tr(tags$td(tags$strong("Exercise Tracker:")), tags$td(tags$code("exercise_log"))),
                     tags$tr(tags$td(tags$strong("Events Scheduling:")), tags$td(tags$code("city_events")))
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
                             choices = c("Day Planner" = "schedule", "Day Planner Prep Steps" = "prep",
                                         "Day Planner Commitments" = "commitments",
                                         "Diet Planner" = "diet",
                                         "Exercise Tracker" = "exercise", "Events Scheduling" = "events"))
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

# ---- Server ----
bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # where the current connection came from (local key folder / environment / by hand)
    output$auto_note <- renderUI({
      invalidateLater(3000); st <- cred_status()
      if (!is.null(st$bq)) cred_banner(!isTRUE(st$bq_failed), st$bq, " You can still load another key below.")
      else cred_banner(FALSE, cred_not_found_text("service-account .json key"))
    })

    observeEvent(input$authenticate, {

      if (trimws(input$project_id) == "" || trimws(input$dataset_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Project ID and Dataset ID")
        })
        return()
      }

      tryCatch({
        api_manager$set_bigquery_credentials(
          project_id = trimws(input$project_id),
          dataset_id = trimws(input$dataset_id)
        )

        if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
          api_manager$authenticate_bigquery(json_path = input$json_file$datapath)
        } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
          api_manager$authenticate_bigquery(json_text = input$json_text)
        } else {
          stop("Please provide credentials via file upload or text paste")
        }

        output$auth_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Successfully authenticated!",
                   tags$br(),
                   tags$small("Each tab group checks its own tables the first time you open it (see TABLES in the sidebar)."),
                   tags$br(),
                   tags$small("Project: ", api_manager$bq_project_id, "  Dataset: ", api_manager$bq_dataset_id))
        })

        # city_events' schema compatibility is checked when Events Scheduling is opened; show the result then
        output$events_schema_status <- renderUI({
          invalidateLater(3000)
          if (!isTRUE(api_manager$bq_units_ready[["events"]])) return(tags$div())
          if (is.null(api_manager$events_schema_warning)) {
            tags$div(class = "status-success", style = "margin-top: 10px;",
                     tags$i(class = "fa fa-check-circle"),
                     " city_events schema compatibility check passed")
          } else {
            tags$div(class = "status-warning", style = "margin-top: 10px;",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " city_events schema warning: ", api_manager$events_schema_warning)
          }
        })

        cred_set_status(bq = "Connected by hand in this tab.", bq_failed = FALSE)
        showNotification("✓ BigQuery connected. Tables are checked when you open each tab group.", type = "message")

      }, error = function(e) {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Authentication failed: ", tags$br(), tags$small(e$message))
        })
        output$events_schema_status <- renderUI({ tags$div() })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$test_query, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate first!", type = "error")
        output$test_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Please authenticate before testing")
        })
        return()
      }

      full_table <- switch(input$test_table_choice,
        schedule = api_manager$bq_full_table_schedule,
        prep     = api_manager$bq_full_table_prep,
        commitments = api_manager$bq_full_table_commitments,
        diet     = api_manager$bq_full_table_diet,
        exercise = api_manager$bq_full_table_exercise,
        events   = api_manager$bq_full_table_events,
        funding  = api_manager$bq_full_table_funding,
        gantt_tasks    = api_manager$bq_full_table_gantt_tasks,
        gantt_contacts = api_manager$bq_full_table_gantt_contacts,
        contacts       = api_manager$bq_full_table_contacts,
        communications = api_manager$bq_full_table_communications
      )

      output$test_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Running test query...")
      })

      tryCatch({
        test_query <- sprintf("SELECT * FROM `%s` LIMIT 5", full_table)
        test_data <- api_manager$bq_query(test_query)

        if (nrow(test_data) == 0) {
          output$test_status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
                     " Query successful but table is empty (0 rows)")
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(data.frame(Message = "Table is empty - no data to display"), options = list(dom = 't'), rownames = FALSE)
          })
        } else {
          output$test_status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Successfully retrieved %d rows from %s", nrow(test_data), full_table))
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(test_data, options = list(pageLength = 5, scrollX = TRUE, dom = 'Bfrtip'), rownames = FALSE)
          })
        }

        showNotification(sprintf("✓ Retrieved %d rows", nrow(test_data)), type = "message")

      }, error = function(e) {
        output$test_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Test query failed: ", tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$auth_status <- renderUI({ tags$div() })
    output$events_schema_status <- renderUI({ tags$div() })
    output$test_status <- renderUI({ tags$div() })
    output$test_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
