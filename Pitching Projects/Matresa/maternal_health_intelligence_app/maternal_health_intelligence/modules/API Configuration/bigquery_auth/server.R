# modules/API Configuration/bigquery_auth/server.R
# Maternal Health Intelligence App - BigQuery auth server

bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$authenticate, {
      if (trimws(input$project_id) == "" || trimws(input$dataset_id) == "") {
        output$auth_status <- renderUI({
          div(class = "status-error",
            icon("exclamation-triangle"),
            " Please fill in Project ID and Dataset ID.")
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
          stop("Please provide credentials via file upload or JSON paste.")
        }

        output$auth_status <- renderUI({
          div(class = "status-success",
            icon("check-circle"),
            tags$strong(" Connected! Table ready:"),
            tags$br(),
            tags$small(icon("database"), " ", api_manager$bq_full_table_driver)
          )
        })

        output$events_schema_status <- renderUI({ div() })
        showNotification("BigQuery connected - DriveSafe ready!", type = "message")

      }, error = function(e) {
        output$auth_status <- renderUI({
          div(class = "status-error",
            icon("times-circle"),
            " Authentication failed:", tags$br(),
            tags$small(e$message))
        })
        output$events_schema_status <- renderUI({ div() })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$test_query, {
      if (!api_manager$bq_authenticated) {
        output$test_status <- renderUI({
          div(class = "status-error", icon("times-circle"),
              " Please authenticate first.")
        })
        return()
      }

      output$test_status <- renderUI({
        div(class = "status-info", icon("spinner"), " Running test query...")
      })

      tryCatch({
        q    <- sprintf("SELECT * FROM `%s` LIMIT 5", api_manager$bq_full_table_driver)
        dat  <- api_manager$bq_query(q)

        if (nrow(dat) == 0) {
          output$test_status <- renderUI({
            div(class = "status-warning", icon("exclamation-triangle"),
                " Query succeeded but maternal_screening_log is empty (no rows yet).")
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(data.frame(Message = "Table is empty. Generate and upload data first."),
                          options = list(dom = "t"), rownames = FALSE)
          })
        } else {
          output$test_status <- renderUI({
            div(class = "status-success", icon("check-circle"),
                sprintf(" Retrieved %d row(s) from maternal_screening_log.", nrow(dat)))
          })
          output$test_table <- DT::renderDataTable({
            DT::datatable(dat,
              options = list(pageLength = 5, scrollX = TRUE, dom = "Bfrtip"),
              rownames = FALSE)
          })
        }
        showNotification(sprintf("Test query: %d row(s) returned.", nrow(dat)), type = "message")

      }, error = function(e) {
        output$test_status <- renderUI({
          div(class = "status-error", icon("times-circle"),
              " Test failed:", tags$br(), tags$small(e$message))
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # Default empty renders
    output$auth_status         <- renderUI({ div() })
    output$events_schema_status <- renderUI({ div() })
    output$test_status          <- renderUI({ div() })
    output$test_table           <- DT::renderDataTable({
      DT::datatable(data.frame(), options = list(dom = "t"), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
