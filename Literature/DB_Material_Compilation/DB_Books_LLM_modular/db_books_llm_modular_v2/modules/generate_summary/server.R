# modules/generate_summary/server.R

generate_summary_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    summary_data <- reactiveVal("")
    
    # Generate summary
    observeEvent(input$generate, {
      
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }
      
      if (nchar(input$book_title) == 0 || nchar(input$book_author) == 0) {
        showNotification("Please enter both book title and author!", type = "error")
        return()
      }
      
      shinyjs::show("loading_spinner")
      output$summary_text <- renderText({ "" })
      
      # Progress tracking
      progress_msg <- reactiveVal("Initializing...")
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " ", progress_msg())
      })
      
      prompt <- generate_summary_prompt(
        book_title = input$book_title,
        author = input$book_author,
        genre = input$book_genre,
        topic = input$book_topic
      )
      
      tryCatch({
        progress_msg("Building prompt...")
        Sys.sleep(0.3)
        
        progress_msg("Connecting to Claude API...")
        Sys.sleep(0.3)
        
        progress_msg("Sending request (this may take 1-3 minutes for long summaries)...")
        
        # Call API with progress callback
        summary_text <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) {
            progress_msg(msg)
          }
        )
        
        summary_data(summary_text)
        
        output$summary_text <- renderText({ summary_text })
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Summary generated successfully!",
                   tags$br(),
                   tags$small(sprintf("Generated %d characters", nchar(summary_text))))
        })
        
        shinyjs::hide("loading_spinner")
        showNotification("✓ Summary generated successfully!", type = "message")
        
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        
        error_message <- e$message
        
        # Provide helpful suggestions based on error type
        suggestion <- ""
        if (grepl("timeout", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Increase timeout in Claude API Config (recommended: 300-600 seconds)"
        } else if (grepl("network|peer|connection", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Check internet connection, firewall settings, or try again in a moment"
        } else if (grepl("401|authentication", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        } else if (grepl("429|rate limit", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Wait a few moments and try again"
        }
        
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Generation Failed",
                   tags$br(),
                   tags$strong("Error: "), tags$small(error_message),
                   if (nchar(suggestion) > 0) {
                     tagList(tags$br(), tags$br(), tags$span(style = "color: #f39c12;", suggestion))
                   } else {
                     NULL
                   })
        })
        
        showNotification(
          paste("Error:", error_message), 
          type = "error", 
          duration = 15
        )
      })
    })
    
    # Copy to bulk import
    observeEvent(input$copy_to_bulk, {
      if (nchar(summary_data()) > 0) {
        # This would update the bulk import tab
        showNotification("Feature requires cross-module communication - use Parse & Upload instead", type = "info")
      } else {
        showNotification("No summary to copy. Generate first.", type = "warning")
      }
    })
    
    # Parse and upload direct
    observeEvent(input$parse_and_upload, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      if (nchar(summary_data()) == 0) {
        showNotification("No summary to upload. Generate first.", type = "warning")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Parsing and uploading...")
      })
      
      tryCatch({
        parsed_df <- parse_summary_text(summary_data())
        rows_uploaded <- api_manager$bq_insert(parsed_df)
        
        # ⭐ TRIGGER DATA REFRESH - notify other modules
        api_manager$trigger_state_update()
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d entries! Visualizations updated.", rows_uploaded))
        })
        
        showNotification(sprintf("✓ Uploaded %d entries!", rows_uploaded), type = "message")
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # Download summary
    output$download <- downloadHandler(
      filename = function() {
        paste0(gsub(" ", "_", input$book_title), "_summary_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) {
        writeLines(summary_data(), file)
      }
    )
    
    # Default outputs
    output$summary_text <- renderText({ "" })
    output$status <- renderUI({ tags$div() })
    
    session$onSessionEnded(function() {})
  })
}