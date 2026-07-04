# modules/generate_summary/server.R

generate_summary_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    summary_data <- reactiveVal("")
    genre_topic <- setup_genre_topic_cascade(input, output, session, api_manager)
    
    # Generate summary
    observeEvent(input$generate, {
      
      cat("\n🖱️  [generate_summary] Generate button clicked\n")
      
      if (!api_manager$claude_authenticated) {
        cat("❌ [generate_summary] Blocked: api_manager$claude_authenticated is FALSE\n")
        cat("   -> Go to Claude API Config tab and click 'Test Connection' (not just 'Save Credentials')\n")
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }
      cat("✓ [generate_summary] claude_authenticated = TRUE, model =", api_manager$claude_model, "\n")
      
      if (nchar(input$book_title) == 0 || nchar(input$book_author) == 0) {
        cat("❌ [generate_summary] Blocked: book_title or book_author is empty\n")
        showNotification("Please enter both book title and author!", type = "error")
        return()
      }
      cat("✓ [generate_summary] Title:", input$book_title, "| Author:", input$book_author, "\n")
      
      gt <- genre_topic()
      if (nchar(gt$genre) == 0 || nchar(gt$topic) == 0) {
        cat("❌ [generate_summary] Blocked: genre or topic not resolved (genre='", gt$genre,
            "', topic='", gt$topic, "')\n")
        showNotification("Please select or enter both Genre and Topic!", type = "error")
        return()
      }
      cat("✓ [generate_summary] Genre:", gt$genre, "| Topic:", gt$topic, "\n")
      
      shinyjs::show("loading_spinner")
      output$summary_text <- renderText({ "" })
      
      # Progress tracking
      progress_msg <- reactiveVal("Initializing...")
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " ", progress_msg())
      })
      
      cat("⚙️  [generate_summary] Building prompt... (include_math =", input$include_math, ")\n")
      prompt <- tryCatch({
        generate_summary_prompt(
          book_title = input$book_title,
          author = input$book_author,
          genre = gt$genre,
          topic = gt$topic,
          include_math = input$include_math
        )
      }, error = function(e) {
        cat("❌ [generate_summary] generate_summary_prompt() failed:", e$message, "\n")
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Failed to build prompt: ", e$message)
        })
        showNotification(paste("Error building prompt:", e$message), type = "error", duration = 10)
        NULL
      })
      
      if (is.null(prompt)) {
        cat("❌ [generate_summary] Aborting: prompt is NULL\n")
        return()
      }
      cat("✓ [generate_summary] Prompt built (", nchar(prompt), "characters )\n")
      
      tryCatch({
        progress_msg("Building prompt...")
        Sys.sleep(0.3)
        
        progress_msg("Connecting to Claude API...")
        Sys.sleep(0.3)
        
        progress_msg("Sending request (this may take 1-3 minutes for long summaries)...")
        
        cat("📡 [generate_summary] Calling api_manager$call_claude() now...\n")
        
        # Call API with progress callback
        api_result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) {
            cat("   …", msg, "\n")
            progress_msg(msg)
          }
        )
        
        summary_text <- api_result$text
        
        cat("✓ [generate_summary] call_claude() returned", nchar(summary_text), "characters",
            "| stop_reason =", api_result$stop_reason, "\n")
        
        # Force-overwrite the entire metadata header with the exact known
        # values, guaranteeing no mismatch regardless of however Claude
        # formatted (or mis-formatted) its own header lines
        summary_text <- overwrite_metadata_header(
          summary_text, input$book_title, input$book_author, gt$genre, gt$topic
        )
        cat("✓ [generate_summary] Metadata header force-set to:",
            input$book_title, "/", input$book_author, "/", gt$genre, "/", gt$topic, "\n")
        
        if (!isTRUE(input$include_math)) {
          summary_text <- blank_math_fields(summary_text)
          cat("✓ [generate_summary] Math fields force-blanked (include_math unchecked)\n")
        }
        
        summary_data(summary_text)
        
        output$summary_text <- renderText({ summary_text })
        
        truncation_warning <- if (isTRUE(api_result$truncated)) {
          tagList(
            tags$br(), tags$br(),
            tags$span(style = "color: #e67e22; font-weight: bold;",
                      "⚠️ Warning: this response was cut off because it hit the Max Tokens limit. ",
                      "It is likely incomplete (missing later chapters or a cut-off final entry). ",
                      "Increase Max Tokens in Claude API Config and regenerate.")
          )
        } else {
          NULL
        }
        
        output$status <- renderUI({
          tags$div(class = if (isTRUE(api_result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(api_result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   if (isTRUE(api_result$truncated)) " Summary generated, but truncated" else " ✓ Summary generated successfully!",
                   tags$br(),
                   tags$small(sprintf("Generated %d characters", nchar(summary_text))),
                   truncation_warning)
        })
        
        shinyjs::hide("loading_spinner")
        
        if (isTRUE(api_result$truncated)) {
          showNotification(
            "⚠️ Response was cut off (max_tokens reached) - the summary is likely incomplete. Increase Max Tokens and regenerate.",
            type = "warning", duration = 20
          )
        } else {
          showNotification("✓ Summary generated successfully!", type = "message")
        }
        
      }, error = function(e) {
        cat("❌ [generate_summary] call_claude() FAILED:", e$message, "\n")
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
        api_manager$set_pending_bulk_text(summary_data())
        # session is namespaced to this module; rootScope() is needed to
        # update the sidebarMenu input, which lives outside any module
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
        showNotification("✓ Summary copied to Bulk Import tab!", type = "message")
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