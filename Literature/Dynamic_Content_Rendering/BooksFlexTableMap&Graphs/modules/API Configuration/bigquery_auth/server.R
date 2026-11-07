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
                   " ✓ Successfully authenticated! All six tables are ready:",
                   tags$br(),
                   tags$small("Book Summary: ", api_manager$bq_full_table_books),
                   tags$br(),
                   tags$small("Flex Table: ", api_manager$bq_full_table_flex),
                   tags$br(),
                   tags$small("Mind Map: ", api_manager$bq_full_table_mindmap),
                   tags$br(),
                   tags$small("Knowledge Graph: ", api_manager$bq_full_table_kg),
                   tags$br(),
                   tags$small("Strategic Analysis: ", api_manager$bq_full_table_diagram),
                   tags$br(),
                   tags$small("Six Sigma Analysis: ", api_manager$bq_full_table_sixsigma))
        })

        showNotification("✓ BigQuery connected - all six suites ready!", type = "message")

      }, error = function(e) {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Authentication failed: ", tags$br(), tags$small(e$message))
        })
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
        books = api_manager$bq_full_table_books,
        flex = api_manager$bq_full_table_flex,
        mindmap = api_manager$bq_full_table_mindmap,
        kg = api_manager$bq_full_table_kg,
        diagram = api_manager$bq_full_table_diagram,
        sixsigma = api_manager$bq_full_table_sixsigma
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
    output$test_status <- renderUI({ tags$div() })
    output$test_table <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
