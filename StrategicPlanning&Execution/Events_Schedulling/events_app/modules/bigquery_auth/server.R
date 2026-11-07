# modules/bigquery_auth/server.R

bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$authenticate, {
      if (trimws(input$project_id) == "" || trimws(input$dataset_id) == "" || trimws(input$table_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"), " Please fill in all fields")
        })
        return()
      }

      tryCatch({
        api_manager$set_bigquery_credentials(
          project_id = trimws(input$project_id),
          dataset_id = trimws(input$dataset_id),
          table_id   = trimws(input$table_id)
        )

        auth_result <- if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
          api_manager$authenticate_bigquery(json_path = input$json_file$datapath)
        } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
          api_manager$authenticate_bigquery(json_text = input$json_text)
        } else {
          stop("Please provide credentials via file upload or text paste")
        }

        table_exists <- isTRUE(auth_result$table_exists)

        output$auth_status <- renderUI({
          if (table_exists) {
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"),
                     " Connected! Table found and ready.",
                     tags$br(),
                     tags$small("Project: ", api_manager$bq_project_id),
                     tags$br(),
                     tags$small("Table: ", api_manager$bq_full_table_id))
          } else {
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " Connected to project, but table was NOT found.",
                     tags$br(), tags$br(),
                     tags$strong("Next step: "),
                     "Run the provided SQL script in the BigQuery console to create ",
                     tags$code(api_manager$bq_full_table_id),
                     ", then click Connect again.",
                     tags$br(), tags$br(),
                     tags$small("Project: ", api_manager$bq_project_id),
                     tags$br(),
                     tags$small("Looking for: ", api_manager$bq_full_table_id))
          }
        })

        if (table_exists) {
          showNotification("✓ BigQuery connected — table found!", type = "message")
        } else {
          showNotification("⚠️  Connected but table not found — run SQL script first", type = "warning", duration = 15)
        }

      }, error = function(e) {
        output$auth_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Authentication failed: ",
                   tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$test_query, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate first!", type = "error")
        return()
      }

      output$test_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Running test query...")
      })

      tryCatch({
        data <- api_manager$bq_query(
          sprintf("SELECT event_name, city, event_date, category, venue_name FROM `%s` LIMIT 5",
                  api_manager$bq_full_table_id)
        )

        if (nrow(data) == 0) {
          output$test_status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     " Query successful — table is empty (0 rows)")
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(data.frame(Message = "Table is empty"),
                          options = list(dom = "t"), rownames = FALSE)
          })
        } else {
          output$test_status <- renderUI({
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"),
                     sprintf(" Retrieved %d rows", nrow(data)))
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(data, options = list(pageLength = 5, scrollX = TRUE, dom = "t"),
                          rownames = FALSE)
          })
        }
        showNotification(sprintf("✓ Retrieved %d rows", nrow(data)), type = "message")

      }, error = function(e) {
        output$test_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Test failed: ", tags$br(), tags$small(e$message))
        })
      })
    })

    output$auth_status <- renderUI({ tags$div() })
    output$test_status <- renderUI({ tags$div() })
    output$test_table  <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = "t"), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
