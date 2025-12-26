# modules/api_config/server.R
# Complete API Configuration Module Server - BigQuery + Claude

api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # ═══════════════════════════════════════════════════════
    # BIGQUERY AUTHENTICATION
    # ═══════════════════════════════════════════════════════
    
    observeEvent(input$bq_authenticate, {
      req(input$bq_json, input$bq_project_id, input$bq_dataset_id, input$bq_table_id)
      
      if (is.null(input$bq_json$datapath)) {
        output$bq_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Please upload a JSON key file")
        })
        return()
      }
      
      output$bq_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Authenticating to BigQuery...")
      })
      
      tryCatch({
        # Save credentials to API manager
        api_manager$set_bigquery_credentials(
          project_id = trimws(input$bq_project_id),
          dataset_id = trimws(input$bq_dataset_id),
          table_id = trimws(input$bq_table_id)
        )
        
        # Authenticate using JSON file
        api_manager$authenticate_bigquery(input$bq_json$datapath)
        
        output$bq_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ BigQuery authenticated successfully!",
                   br(),
                   tags$small("Project: ", input$bq_project_id),
                   br(),
                   tags$small("Dataset: ", input$bq_dataset_id),
                   br(),
                   tags$small("Table: ", input$bq_table_id))
        })
        
        showNotification(
          "✓ BigQuery connected! Other modules can now access data.",
          type = "message",
          duration = 5
        )
        
        # Update summary
        update_summary()
        
      }, error = function(e) {
        output$bq_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message,
                   br(), br(),
                   tags$strong("💡 Try:"),
                   tags$ul(
                     tags$li("Verify JSON file is valid"),
                     tags$li("Check Project ID is correct"),
                     tags$li("Ensure BigQuery API is enabled"),
                     tags$li("Verify service account has BigQuery permissions")
                   ))
        })
        
        showNotification(
          paste("BigQuery authentication failed:", e$message),
          type = "error",
          duration = 15
        )
      })
    })
    
    # Test BigQuery connection
    observeEvent(input$bq_test, {
      if (!api_manager$bq_authenticated) {
        output$bq_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please authenticate first")
        })
        return()
      }
      
      output$bq_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Testing BigQuery connection...")
      })
      
      tryCatch({
        # Try a simple query
        test_query <- sprintf(
          "SELECT COUNT(*) as row_count FROM `%s` LIMIT 1",
          api_manager$bq_full_table_id
        )
        
        result <- api_manager$bq_query(test_query)
        
        output$bq_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ BigQuery connection successful!",
                   br(),
                   tags$small("Table exists with ", result$row_count, " rows"))
        })
        
        showNotification("✓ BigQuery test successful", type = "message")
        
      }, error = function(e) {
        output$bq_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Connection test failed: ", e$message,
                   br(), br(),
                   tags$strong("💡 Try:"),
                   tags$ul(
                     tags$li("Verify table exists"),
                     tags$li("Check service account has read permissions"),
                     tags$li("Re-authenticate if needed")
                   ))
        })
      })
    })
    
    # ═══════════════════════════════════════════════════════
    # CLAUDE API CONFIGURATION
    # ═══════════════════════════════════════════════════════
    
    observeEvent(input$claude_save, {
      req(input$claude_api_key)
      
      if (trimws(input$claude_api_key) == "") {
        output$claude_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Please enter a Claude API key")
        })
        return()
      }
      
      tryCatch({
        # Save to API manager
        api_manager$set_claude_credentials(
          api_key = trimws(input$claude_api_key),
          model = input$claude_model,
          timeout = input$claude_timeout,
          max_tokens = input$claude_max_tokens
        )
        
        output$claude_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Claude API configured successfully!",
                   br(),
                   tags$small("Model: ", input$claude_model),
                   br(),
                   tags$small("Timeout: ", input$claude_timeout, " seconds"),
                   br(),
                   tags$small("Max Tokens: ", input$claude_max_tokens))
        })
        
        showNotification(
          "✓ Claude API configured! AI features now available.",
          type = "message",
          duration = 5
        )
        
        # Update summary
        update_summary()
        
      }, error = function(e) {
        output$claude_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
      })
    })
    
    # Test Claude connection
    observeEvent(input$claude_test, {
      if (is.null(api_manager$claude_api_key) || api_manager$claude_api_key == "") {
        output$claude_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please save configuration first")
        })
        return()
      }
      
      output$claude_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Testing Claude API connection...")
      })
      
      tryCatch({
        # Simple test message
        response <- api_manager$call_claude(
          prompt = "Respond with exactly: 'Connection test successful'",
          max_tokens = 50,
          progress_callback = NULL
        )
        
        output$claude_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Claude API connection successful!",
                   br(),
                   tags$small("Response received: ", nchar(response), " characters"))
        })
        
        showNotification("✓ Claude API test successful", type = "message")
        
      }, error = function(e) {
        output$claude_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Connection test failed: ", e$message)
        })
      })
    })
    
    # ═══════════════════════════════════════════════════════
    # CONFIGURATION SUMMARY
    # ═══════════════════════════════════════════════════════
    
    update_summary <- function() {
      output$config_summary <- renderUI({
        tagList(
          fluidRow(
            column(6,
              tags$h5(icon("database"), " BigQuery Status"),
              if (api_manager$bq_authenticated) {
                tags$div(
                  tags$p(tags$strong("Status:"), 
                        tags$span(class = "text-success", 
                                 icon("check-circle"), " Connected")),
                  tags$p(tags$strong("Project:"), " ", api_manager$bq_project_id),
                  tags$p(tags$strong("Dataset:"), " ", api_manager$bq_dataset_id),
                  tags$p(tags$strong("Table:"), " ", api_manager$bq_table_id),
                  tags$p(tags$strong("Full Path:"), 
                        tags$code(api_manager$bq_full_table_id))
                )
              } else {
                tags$div(
                  tags$p(tags$strong("Status:"), 
                        tags$span(class = "text-muted", 
                                 icon("times-circle"), " Not configured")),
                  tags$p("Upload JSON and authenticate above")
                )
              }
            ),
            column(6,
              tags$h5(icon("robot"), " Claude API Status"),
              if (!is.null(api_manager$claude_api_key) && api_manager$claude_api_key != "") {
                tags$div(
                  tags$p(tags$strong("Status:"), 
                        tags$span(class = "text-success", 
                                 icon("check-circle"), " Configured")),
                  tags$p(tags$strong("Model:"), " ", api_manager$claude_model),
                  tags$p(tags$strong("Timeout:"), " ", api_manager$claude_timeout, " seconds"),
                  tags$p(tags$strong("Max Tokens:"), " ", 
                        format(api_manager$claude_max_tokens, big.mark = ",")),
                  tags$p(tags$strong("API Key:"), " ", 
                        substr(api_manager$claude_api_key, 1, 15), "...")
                )
              } else {
                tags$div(
                  tags$p(tags$strong("Status:"), 
                        tags$span(class = "text-muted", 
                                 icon("times-circle"), " Not configured")),
                  tags$p("Enter API key and save configuration above")
                )
              }
            )
          ),
          
          hr(),
          
          tags$div(
            class = if (api_manager$bq_authenticated && 
                       !is.null(api_manager$claude_api_key)) {
              "alert alert-success"
            } else {
              "alert alert-warning"
            },
            tags$strong(icon("info-circle"), " Ready Status:"),
            tags$ul(
              tags$li(
                if (api_manager$bq_authenticated) {
                  tags$span(class = "text-success", icon("check"), " BigQuery ready")
                } else {
                  tags$span(class = "text-warning", icon("times"), " BigQuery not configured")
                }
              ),
              tags$li(
                if (!is.null(api_manager$claude_api_key) && api_manager$claude_api_key != "") {
                  tags$span(class = "text-success", icon("check"), " Claude API ready")
                } else {
                  tags$span(class = "text-warning", icon("times"), " Claude API not configured")
                }
              )
            ),
            if (api_manager$bq_authenticated && 
                !is.null(api_manager$claude_api_key) && api_manager$claude_api_key != "") {
              tags$p(tags$strong(icon("check-circle"), 
                                " All systems ready! You can now use other modules."))
            } else {
              tags$p(tags$strong(icon("exclamation-triangle"), 
                                " Complete configuration above to enable all features."))
            }
          )
        )
      })
    }
    
    # Initial summary
    update_summary()
    
    # Default status messages
    output$bq_status <- renderUI({
      tags$div(class = "alert alert-info",
               tags$i(class = "fa fa-info-circle"),
               " Upload JSON key file, enter project details, and click Authenticate")
    })
    
    output$claude_status <- renderUI({
      tags$div(class = "alert alert-info",
               tags$i(class = "fa fa-info-circle"),
               " Enter your Claude API key and click Save Configuration")
    })
    
    # ⭐ Watch for updates from other modules
    observe({
      api_manager$state_trigger()
      update_summary()
    })
  })
}
