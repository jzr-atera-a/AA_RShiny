bigquery_auth_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    output$package_info <- renderText({
      paste0("bigrquery version: ", packageVersion("bigrquery"))
    })
    
    observeEvent(input$authenticate, {
      
      tryCatch({
        if (is.null(input$project_id) || trimws(input$project_id) == "") {
          output$auth_status <- renderUI({
            tags$div(class = "status-error", 
                     tags$i(class = "fa fa-times-circle"), 
                     " Error: Please provide a valid Project ID")
          })
          return()
        }
        
        if (is.null(input$dataset_id) || trimws(input$dataset_id) == "") {
          output$auth_status <- renderUI({
            tags$div(class = "status-error", 
                     tags$i(class = "fa fa-times-circle"), 
                     " Error: Please provide a valid Dataset ID")
          })
          return()
        }
        
        if (is.null(input$table_id) || trimws(input$table_id) == "") {
          output$auth_status <- renderUI({
            tags$div(class = "status-error", 
                     tags$i(class = "fa fa-times-circle"), 
                     " Error: Please provide a valid Table ID")
          })
          return()
        }
        
        auth_successful <- FALSE
        auth_method <- ""
        
        tryCatch({
          bigrquery::bq_deauth()
        }, error = function(e) {})
        
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")
        
        if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
          
          json_content <- tryCatch({
            jsonlite::fromJSON(input$json_file$datapath)
          }, error = function(e) {
            stop("Invalid JSON file format: ", e$message)
          })
          
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing_fields <- setdiff(required_fields, names(json_content))
          if (length(missing_fields) > 0) {
            stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
          }
          
          bigrquery::bq_auth(path = input$json_file$datapath, cache = FALSE)
          auth_successful <- TRUE
          auth_method <- "JSON file upload"
          
        } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
          
          json_content <- tryCatch({
            jsonlite::fromJSON(input$json_text)
          }, error = function(e) {
            stop("Invalid JSON format in text input: ", e$message)
          })
          
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing_fields <- setdiff(required_fields, names(json_content))
          if (length(missing_fields) > 0) {
            stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
          }
          
          temp_file <- tempfile(fileext = ".json")
          writeLines(input$json_text, temp_file)
          
          api_manager$set_bigquery_credentials_text(input$json_text, temp_file)
          
          bigrquery::bq_auth(path = temp_file, cache = FALSE)
          auth_successful <- TRUE
          auth_method <- "manual JSON input"
          
        } else {
          stop("Please provide authentication credentials using one of the available methods")
        }
        
        if (auth_successful) {
          api_manager$set_bigquery_project(
            project_id = trimws(input$project_id),
            dataset_id = trimws(input$dataset_id),
            table_id = trimws(input$table_id)
          )
          
          test_result <- tryCatch({
            datasets <- bigrquery::bq_project_datasets(api_manager$bq_project_id)
            TRUE
          }, error = function(e) {
            stop("Connection test failed: ", e$message)
          })
          
          if (test_result) {
            create_table_query <- sprintf("
              CREATE TABLE IF NOT EXISTS `%s` (
                canvas_id STRING NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
                business_area STRING,
                project STRING,
                business_focus STRING,
                key_partners STRING,
                key_activities STRING,
                key_resources STRING,
                value_propositions STRING,
                customer_relationships STRING,
                channels STRING,
                customer_segments STRING,
                cost_structure STRING,
                revenue_streams STRING
              )", api_manager$bq_full_table_id)
            
            tryCatch({
              bigrquery::bq_project_query(api_manager$bq_project_id, create_table_query)
            }, error = function(e) {})
            
            # Mark as authenticated
            api_manager$bq_authenticated <- TRUE
            
            # CRITICAL: TRIGGER AUTH REACTIVE TO UPDATE DROPDOWNS
            api_manager$trigger_auth_update()
            
            output$auth_status <- renderUI({
              tags$div(class = "status-success",
                       tags$i(class = "fa fa-check-circle"), 
                       paste(" Successfully authenticated via", auth_method),
                       br(),
                       tags$small("Project ID: ", api_manager$bq_project_id),
                       br(),
                       tags$small("Dataset ID: ", api_manager$bq_dataset_id),
                       br(),
                       tags$small("Table ID: ", api_manager$bq_table_id),
                       br(),
                       tags$small("Full Table Path: ", api_manager$bq_full_table_id))
            })
            
            showNotification("✓ BigQuery connection established!", type = "message")
          }
        }
        
      }, error = function(e) {
        api_manager$bq_authenticated <- FALSE
        output$auth_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), 
                   " Authentication failed: ", 
                   tags$br(),
                   tags$small(e$message))
        })
        showNotification(paste("Authentication failed:", e$message), type = "error")
      })
    })
    
  })
}
