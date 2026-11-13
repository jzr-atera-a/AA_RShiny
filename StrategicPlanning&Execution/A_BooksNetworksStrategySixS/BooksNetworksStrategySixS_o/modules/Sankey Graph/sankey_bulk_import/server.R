# modules/Sankey Graph/sankey_bulk_import/server.R

sankey_bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_data <- reactiveVal(NULL)

    observeEvent(api_manager$pending_bulk_text_sankey(), {
      incoming_text <- api_manager$pending_bulk_text_sankey()
      if (nchar(incoming_text) > 0) {
        updateTextAreaInput(session, "sankey_text", value = incoming_text)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$parse, {
      if (trimws(input$sankey_text %||% "") == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste a generated Sankey to parse")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })

      tryCatch({
        df <- parse_sankey_text(input$sankey_text, sankey_id = "", is_template = FALSE, created_by = "manual_bulk_import")
        df$sankey_id <- generate_new_sankey_id(df$topic[1])

        parsed_data(df)

        node_count <- sum(df$row_kind == "node")
        link_count <- sum(df$row_kind == "link")

        output$parse_info <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d node(s) and %d link(s) for '%s' (%d columns | Category: %s | Domain: %s | Topic: %s)",
                           node_count, link_count, df$title[1], df$num_columns[1], df$category[1], df$domain[1], df$topic[1]))
        })

        output$preview_table <- DT::renderDataTable({
          DT::datatable(df[, c("row_kind", "component_ref", "column_index", "sequence_order",
                                "label_text", "source_ref", "target_ref", "value_numeric", "unit_label")],
                       options = list(pageLength = 12, scrollX = TRUE), rownames = FALSE)
        })

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d node(s) and %d link(s)!", node_count, link_count))
        })

        showNotification(sprintf("✓ Parsed %d node(s) and %d link(s)!", node_count, link_count), type = "message")

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
      if (is.null(df) || nrow(df) == 0) { showNotification("Nothing parsed yet - click Parse Rows first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...")
      })

      tryCatch({
        rows_uploaded <- api_manager$bq_insert_sankey(df)
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Uploaded %d row(s)! Sankey ID: %s", rows_uploaded, df$sankey_id[1]))
        })
        showNotification(sprintf("✓ Uploaded %d row(s)!", rows_uploaded), type = "message")
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clear, {
      updateTextAreaInput(session, "sankey_text", value = "")
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
