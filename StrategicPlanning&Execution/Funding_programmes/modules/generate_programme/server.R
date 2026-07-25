# modules/generate_programme/server.R

generate_programme_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    programme_data <- reactiveVal("")
    category_react <- setup_category_cascade(input, output, session, api_manager)
    country_cityregion_react <- setup_country_cityregion_cascade(input, output, session, api_manager)
    
    observeEvent(input$generate, {
      
      cat("\n🖱️  [generate_programme] Find Programmes button clicked\n")
      
      if (!api_manager$claude_authenticated) {
        cat("❌ [generate_programme] Blocked: claude_authenticated is FALSE\n")
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }
      
      cat_val <- category_react()
      if (nchar(cat_val) == 0) {
        showNotification("Please select or enter a Category!", type = "error")
        return()
      }
      
      cc <- country_cityregion_react()
      if (nchar(cc$country) == 0) {
        showNotification("Please select or enter a Country!", type = "error")
        return()
      }
      
      cat("✓ [generate_programme] Category:", cat_val, "| Country:", cc$country, "| City/Region:", cc$city_region, "\n")
      
      shinyjs::show("loading_spinner")
      output$programme_text <- renderText({ "" })
      
      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })
      
      prompt <- tryCatch({
        generate_programme_prompt(
          category = cat_val,
          country = cc$country,
          city_region = cc$city_region,
          search_focus = input$search_focus,
          n_results = input$n_results
        )
      }, error = function(e) {
        cat("❌ [generate_programme] generate_programme_prompt() failed:", e$message, "\n")
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                   " Failed to build prompt: ", e$message)
        })
        NULL
      })
      
      if (is.null(prompt)) return()
      
      tryCatch({
        progress_msg("Connecting to Claude API...")
        Sys.sleep(0.3)
        progress_msg("Searching (this may take 30-90 seconds)...")
        
        cat("📡 [generate_programme] Calling api_manager$call_claude() now...\n")
        
        result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) {
            cat("   …", msg, "\n")
            progress_msg(msg)
          }
        )
        
        cat("✓ [generate_programme] call_claude() returned", nchar(result$text), "characters\n")
        
        # Force-overwrite category/country/city_region with the exact
        # values selected in the UI on every parsed record
        programme_text <- overwrite_programme_taxonomy(result$text, cat_val, cc$country, cc$city_region)
        
        programme_data(programme_text)
        output$programme_text <- renderText({ programme_text })
        
        truncation_note <- if (isTRUE(result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;",
                                        "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL
        
        output$status <- renderUI({
          tags$div(class = if (isTRUE(result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Programmes found!",
                   tags$br(),
                   tags$small(sprintf("Generated %d characters", nchar(programme_text))),
                   truncation_note)
        })
        
        shinyjs::hide("loading_spinner")
        showNotification("✓ Programmes found!", type = "message")
        
      }, error = function(e) {
        cat("❌ [generate_programme] call_claude() FAILED:", e$message, "\n")
        shinyjs::hide("loading_spinner")
        
        error_message <- e$message
        suggestion <- ""
        if (grepl("timeout", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Increase timeout in Claude API Config"
        } else if (grepl("network|peer|connection", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Check internet connection or try again in a moment"
        } else if (grepl("401|authentication", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        } else if (grepl("429|rate limit", error_message, ignore.case = TRUE)) {
          suggestion <- "💡 Try: Wait a few moments and try again"
        }
        
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Search Failed",
                   tags$br(),
                   tags$strong("Error: "), tags$small(error_message),
                   if (nchar(suggestion) > 0) tagList(tags$br(), tags$br(), tags$span(style = "color: #f39c12;", suggestion)) else NULL)
        })
        
        showNotification(paste("Error:", error_message), type = "error", duration = 15)
      })
    })
    
    observeEvent(input$copy_to_bulk, {
      if (nchar(programme_data()) > 0) {
        api_manager$set_pending_bulk_text(programme_data())
        updateTabItems(session$rootScope(), "sidebar_menu", selected = "bulk_import")
        showNotification("✓ Programmes copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No programmes to copy. Find some first.", type = "warning")
      }
    })
    
    observeEvent(input$parse_and_upload, {
      
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      
      if (nchar(programme_data()) == 0) {
        showNotification("No programmes to upload. Find some first.", type = "warning")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...")
      })
      
      tryCatch({
        parsed_df <- parse_programme_text(programme_data())
        rows_uploaded <- api_manager$bq_insert(parsed_df)
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
    
    output$download <- downloadHandler(
      filename = function() {
        paste0("programmes_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) {
        writeLines(programme_data(), file)
      }
    )
    
    output$programme_text <- renderText({ "" })
    output$status <- renderUI({ tags$div() })
    
    session$onSessionEnded(function() {})
  })
}
