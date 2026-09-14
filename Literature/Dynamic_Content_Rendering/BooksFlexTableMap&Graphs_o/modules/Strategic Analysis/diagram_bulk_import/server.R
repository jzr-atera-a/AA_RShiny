# modules/Strategic Analysis/diagram_bulk_import/server.R

diagram_bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    # Receive text pushed from the Generate Diagram tab's "Copy to Bulk
    # Import" button (see APIManager$pending_bulk_text_diagram in R/utils_api.R)
    observeEvent(api_manager$pending_bulk_text_diagram(), {
      incoming_text <- api_manager$pending_bulk_text_diagram()
      if (nchar(incoming_text) > 0) {
        updateTextAreaInput(session, "diagram_text", value = incoming_text)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      if (trimws(input$diagram_text %||% "") == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste a generated diagram to parse")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })

      tryCatch({
        # diagram_type/category/topic/title come straight from the pasted
        # text's own metadata lines - diagram_id is app-generated from the
        # parsed topic once we know it, same convention as Generate
        # Diagram's own parse/upload path.
        df <- parse_diagram_text(input$diagram_text, diagram_id = "", is_template = FALSE, created_by = "manual_bulk_import")
        df$diagram_id <- generate_new_diagram_id(df$topic[1])

        parsed_data(df)

        output$parse_info <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d component row(s) for '%s' (Type: %s | Category: %s | Topic: %s)",
                           nrow(df), df$title[1], df$diagram_type[1], df$category[1], df$topic[1]))
        })

        output$preview_table <- DT::renderDataTable({
          DT::datatable(df[, c("component_type", "layout_role", "grid_row", "grid_col",
                                "sequence_order", "label_text", "items_packed")],
                       options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d component row(s)!", nrow(df)))
        })

        showNotification(sprintf("✓ Parsed %d component row(s)!", nrow(df)), type = "message")

      }, error = function(e) {
        parsed_data(NULL)
        output$parse_info <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parse issue: ", e$message)
        })
        output$preview_table <- DT::renderDataTable({})
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
      })
    })

    observeEvent(input$upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      df <- parsed_data()
      if (is.null(df) || nrow(df) == 0) { showNotification("Nothing parsed yet - click Parse Components first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...")
      })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_diagram(df)
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Uploaded %d component row(s)! Diagram ID: %s", rows_uploaded, df$diagram_id[1]))
        })
        showNotification(sprintf("✓ Uploaded %d component row(s)!", rows_uploaded), type = "message")
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "diagram_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({ tags$div() })
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })

    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
  })
}
