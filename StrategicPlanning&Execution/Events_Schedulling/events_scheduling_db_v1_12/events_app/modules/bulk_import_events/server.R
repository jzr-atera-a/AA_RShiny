# modules/bulk_import_events/server.R

bulk_import_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    # Receive text from scan_events via api_manager$pending_bulk_text
    observeEvent(api_manager$pending_bulk_text(), {
      incoming <- api_manager$pending_bulk_text()
      if (nchar(incoming) > 0) {
        cat("📥 [bulk_import_events] Received", nchar(incoming), "chars from scan_events\n")
        updateTextAreaInput(session, "events_text", value = incoming)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      if (trimws(input$events_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"), " Please paste events text to parse")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })

      tryCatch({
        df <- parse_events_text(input$events_text)
        parsed_data(df)

        output$parse_info <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d events in %s, %s",
                           nrow(df),
                           if (nrow(df) > 0) df$city[1] else "?",
                           if (nrow(df) > 0) df$country[1] else "?"))
        })

        output$preview_table <- DT::renderDataTable({
          show_cols <- c("event_name", "category", "subcategory", "event_date",
                         "event_time", "venue_name", "city", "price_range")
          show_cols <- intersect(show_cols, names(df))
          DT::datatable(df[, show_cols], options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d events!", nrow(df)))
        })
        showNotification(sprintf("✓ Parsed %d events!", nrow(df)), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(parsed_data())) {
        showNotification("Please parse the events first!", type = "error")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...")
      })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert(parsed_data())
        api_manager$trigger_state_update()

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d events! Visualizations updated.", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d events!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "events_text", value = "")
      parsed_data(NULL)
      output$parse_info    <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status        <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })

    output$status        <- renderUI({ tags$div() })
    output$parse_info    <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
