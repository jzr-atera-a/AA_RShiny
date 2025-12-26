# modules/bulk_import/server.R

bulk_import_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    parsed_data <- reactiveVal(NULL)
    
    # Parse summary
    observeEvent(input$parse, {
      
      if (trimws(input$summary_text) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please paste a summary to parse")
        })
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Parsing...")
      })
      
      tryCatch({
        parsed_df <- parse_summary_text(input$summary_text)
        parsed_data(parsed_df)
        
        output$parse_info <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully parsed %d entries from '%s' by %s",
                           nrow(parsed_df), parsed_df$book_name[1], parsed_df$author[1]))
        })
        
        output$preview_table <- DT::renderDataTable({
          DT::datatable(parsed_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Parsed %d entries!", nrow(parsed_df)))
        })
        
        showNotification(sprintf("✓ Parsed %d entries!", nrow(parsed_df)), type = "message")
        
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
        showNotification("Please parse the summary first!", type = "error")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Uploading...")
      })
      
      tryCatch({
        rows_uploaded <- api_manager$bq_insert(parsed_data())
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d rows!", rows_uploaded))
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
      updateTextAreaInput(session, "summary_text", value = "")
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
