# modules/bulk_import/server.R

bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    parsed_data <- reactiveVal(NULL)
    
    # Receive text pushed from the Generate Schedule tab's "Copy to Bulk
    # Import" button (see APIManager$pending_bulk_text in R/utils_api.R)
    observeEvent(api_manager$pending_bulk_text(), {
      incoming_text <- api_manager$pending_bulk_text()
      if (nchar(incoming_text) > 0) {
        cat("📥 [bulk_import] Received text from generate_schedule (", nchar(incoming_text), "chars )\n")
        updateTextAreaInput(session, "schedule_text", value = incoming_text)
      }
    }, ignoreInit = TRUE)
    
    # Parse schedule
    observeEvent(input$parse, {
      
      if (trimws(input$schedule_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste a schedule to parse")
        })
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Parsing...")
      })
      
      tryCatch({
        parsed_df <- parse_schedule_text(input$schedule_text)
        parsed_data(parsed_df)
        
        output$parse_info <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d rows for %s (%s)",
                           nrow(parsed_df), parsed_df$schedule_date[1], parsed_df$day_type[1]))
        })
        
        output$preview_table <- DT::renderDataTable({
          DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d rows!", nrow(parsed_df)))
        })
        
        showNotification(sprintf("✓ Parsed %d rows!", nrow(parsed_df)), type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Upload to BigQuery
    observeEvent(input$upload, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      if (is.null(parsed_data())) {
        showNotification("Please parse the schedule first!", type = "error")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Uploading...")
      })
      
      tryCatch({
        rows_uploaded <- api_manager$bq_insert(parsed_data())
        
        # ⭐ TRIGGER DATA REFRESH - notify other modules
        api_manager$trigger_state_update()
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d rows! Visualizations updated.", rows_uploaded))
        })
        
        showNotification(sprintf("✓ Uploaded %d rows!", rows_uploaded), type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Clear
    observeEvent(input$clear, {
      updateTextAreaInput(session, "schedule_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({
        tags$div(class = "status-info", "Cleared.")
      })
    })
    
    # Default outputs
    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    
    session$onSessionEnded(function() {})
  })
}
