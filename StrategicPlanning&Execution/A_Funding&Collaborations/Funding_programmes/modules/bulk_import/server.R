# modules/bulk_import/server.R

bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    parsed_data <- reactiveVal(NULL)
    
    observeEvent(api_manager$pending_bulk_text(), {
      incoming_text <- api_manager$pending_bulk_text()
      if (nchar(incoming_text) > 0) {
        cat("📥 [bulk_import] Received text from generate_programme (", nchar(incoming_text), "chars )\n")
        updateTextAreaInput(session, "programme_text", value = incoming_text)
      }
    }, ignoreInit = TRUE)
    
    observeEvent(input$parse, {
      
      if (trimws(input$programme_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste programme data to parse")
        })
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing...")
      })
      
      tryCatch({
        parsed_df <- parse_programme_text(input$programme_text)
        parsed_data(parsed_df)
        
        output$parse_info <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d programme(s)", nrow(parsed_df)))
        })
        
        output$preview_table <- DT::renderDataTable({
          DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d programme(s)!", nrow(parsed_df)))
        })
        
        showNotification(sprintf("✓ Parsed %d programme(s)!", nrow(parsed_df)), type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
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
        showNotification("Please parse the programme data first!", type = "error")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Uploading...")
      })
      
      tryCatch({
        rows_uploaded <- api_manager$bq_insert(parsed_data())
        api_manager$trigger_state_update()
        
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d programme(s)! Visualizations updated.", rows_uploaded))
        })
        
        showNotification(sprintf("✓ Uploaded %d programme(s)!", rows_uploaded), type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    observeEvent(input$clear, {
      updateTextAreaInput(session, "programme_text", value = "")
      parsed_data(NULL)
      output$parse_info <- renderUI({})
      output$preview_table <- DT::renderDataTable({})
      output$status <- renderUI({ tags$div(class = "status-info", "Cleared.") })
    })
    
    output$status <- renderUI({ tags$div() })
    output$parse_info <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    
    session$onSessionEnded(function() {})
  })
}
