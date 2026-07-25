# modules/generate_schedule/server.R

generate_schedule_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    schedule_data <- reactiveVal("")
    day_type_react <- setup_day_type_cascade(input, output, session, api_manager)
    country_city_react <- setup_country_city_cascade(input, output, session, api_manager)
    
    # Generate schedule
    observeEvent(input$generate, {
      
      cat("\n🖱️  [generate_schedule] Plan Schedule button clicked\n")
      
      if (!api_manager$claude_authenticated) {
        cat("❌ [generate_schedule] Blocked: api_manager$claude_authenticated is FALSE\n")
        cat("   -> Go to Claude API Config tab and click 'Test Connection' (not just 'Save Credentials')\n")
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }
      cat("✓ [generate_schedule] claude_authenticated = TRUE, model =", api_manager$claude_model, "\n")
      
      dt <- day_type_react()
      if (nchar(dt) == 0) {
        cat("❌ [generate_schedule] Blocked: day_type not resolved\n")
        showNotification("Please select or enter a Type of Day!", type = "error")
        return()
      }
      cat("✓ [generate_schedule] Date:", as.character(input$schedule_date), "| Day Type:", dt, "\n")
      
      is_travel <- identical(dt, "Travel")
      country <- "N/A"
      city <- "N/A"
      
      if (is_travel) {
        cc <- country_city_react()
        if (nchar(cc$country) == 0 || nchar(cc$city) == 0) {
          cat("❌ [generate_schedule] Blocked: country or city not resolved for a Travel day\n")
          showNotification("Please select or enter both Country and City for a Travel day!", type = "error")
          return()
        }
        country <- cc$country
        city <- cc$city
        cat("✓ [generate_schedule] Country:", country, "| City:", city, "\n")
      }
      
      shinyjs::show("loading_spinner")
      output$schedule_text <- renderText({ "" })
      
      # Progress tracking
      progress_msg <- reactiveVal("Initializing...")
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " ", progress_msg())
      })
      
      cat("⚙️  [generate_schedule] Building prompt...\n")
      prompt <- tryCatch({
        generate_schedule_prompt(
          schedule_date = as.character(input$schedule_date),
          day_type = dt,
          country = country,
          city = city,
          trip_details = input$trip_details
        )
      }, error = function(e) {
        cat("❌ [generate_schedule] generate_schedule_prompt() failed:", e$message, "\n")
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
        cat("❌ [generate_schedule] Aborting: prompt is NULL\n")
        return()
      }
      cat("✓ [generate_schedule] Prompt built (", nchar(prompt), "characters )\n")
      
      tryCatch({
        progress_msg("Building prompt...")
        Sys.sleep(0.3)
        
        progress_msg("Connecting to Claude API...")
        Sys.sleep(0.3)
        
        progress_msg("Sending request (this may take 30-90 seconds)...")
        
        cat("📡 [generate_schedule] Calling api_manager$call_claude() now...\n")
        
        # Call API with progress callback
        result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) {
            cat("   …", msg, "\n")
            progress_msg(msg)
          }
        )
        
        cat("✓ [generate_schedule] call_claude() returned", nchar(result$text), "characters\n")
        
        # Force-overwrite Claude's header lines with the exact values
        # selected/typed in the UI, guaranteeing no mismatch
        schedule_text <- overwrite_schedule_header(
          result$text, as.character(input$schedule_date), dt, country, city, input$trip_details
        )
        cat("✓ [generate_schedule] Header force-set to:", as.character(input$schedule_date), "/", dt, "\n")
        
        schedule_data(schedule_text)
        
        output$schedule_text <- renderText({ schedule_text })
        
        truncation_note <- if (isTRUE(result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;",
                                        "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL
        
        output$status <- renderUI({
          tags$div(class = if (isTRUE(result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Schedule planned successfully!",
                   tags$br(),
                   tags$small(sprintf("Generated %d characters", nchar(schedule_text))),
                   truncation_note)
        })
        
        shinyjs::hide("loading_spinner")
        showNotification("✓ Schedule planned successfully!", type = "message")
        
      }, error = function(e) {
        cat("❌ [generate_schedule] call_claude() FAILED:", e$message, "\n")
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
                   " Planning Failed",
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
      if (nchar(schedule_data()) > 0) {
        api_manager$set_pending_bulk_text(schedule_data())
        # session is namespaced to this module; rootScope() is needed to
        # update the sidebarMenu input, which lives outside any module
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
        showNotification("✓ Schedule copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No schedule to copy. Generate first.", type = "warning")
      }
    })
    
    # Parse and upload direct
    observeEvent(input$parse_and_upload, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      if (nchar(schedule_data()) == 0) {
        showNotification("No schedule to upload. Generate first.", type = "warning")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Parsing and uploading...")
      })
      
      tryCatch({
        parsed_df <- parse_schedule_text(schedule_data())
        rows_uploaded <- api_manager$bq_insert(parsed_df)
        
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
    
    # Download schedule
    output$download <- downloadHandler(
      filename = function() {
        paste0("schedule_", as.character(input$schedule_date), "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) {
        writeLines(schedule_data(), file)
      }
    )
    
    # Default outputs
    output$schedule_text <- renderText({ "" })
    output$status <- renderUI({ tags$div() })
    
    session$onSessionEnded(function() {})
  })
}
