# modules/API Configuration/bigquery_auth/server.R

bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

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
                   " ✓ Successfully authenticated! All three tables are ready:",
                   tags$br(),
                   tags$small("Day Planner: ", api_manager$bq_full_table_schedule),
                   tags$br(),
                   tags$small("Events Scheduling: ", api_manager$bq_full_table_events),
                   tags$br(),
                   tags$small("Funding Programmes: ", api_manager$bq_full_table_funding))
        })

        # Events' table is expected to pre-exist with real data - surface a
        # non-blocking warning if its actual columns don't cover everything
        # this app needs to write (see check_events_table_compatibility()).
        output$events_schema_status <- renderUI({
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

        showNotification("✓ BigQuery connected - all three suites ready!", type = "message")

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
