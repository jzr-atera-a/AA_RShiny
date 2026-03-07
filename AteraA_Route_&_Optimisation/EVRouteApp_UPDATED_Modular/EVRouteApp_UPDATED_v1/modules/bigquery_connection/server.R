# modules/bigquery_connection/server.R
# BigQuery Connection Module Server

bigquery_connection_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    # Test BigQuery connection
    observeEvent(input$testBQConnection, {
      if (is.null(input$jsonKey)) {
        output$bqConnectionStatus <- renderUI({
          div(class = "connection-error", 
              h5("❌ Authentication Failed"), 
              p("Please upload a JSON key file."))
        })
        return()
      }
      
      if (is.null(api_manager)) {
        output$bqConnectionStatus <- renderUI({
          div(class = "connection-error",
              h5("❌ Error"),
              p("API Manager not initialized"))
        })
        return()
      }
      
      withProgress(message = 'Authenticating with BigQuery...', value = 0, {
        
        incProgress(0.3, detail = "Verifying credentials")
        
        # Attempt authentication
        result <- api_manager$authenticate(
          json_key_path = input$jsonKey$datapath,
          project_id = input$projectId,
          dataset_id = input$datasetId,
          table_id = input$tableId
        )
        
        incProgress(0.6, detail = "Loading data")
        
        if (result$success) {
          incProgress(1, detail = "Complete")
          
          output$bqConnectionStatus <- renderUI({
            div(class = "connection-success",
                h5("✓ Connection Successful"),
                p(strong("Project:"), input$projectId),
                p(strong("Dataset:"), input$datasetId),
                p(strong("Table:"), input$tableId),
                p(result$message))
          })
          
          showNotification("BigQuery connection established!", 
                           type = "message", 
                           duration = 5)
        } else {
          output$bqConnectionStatus <- renderUI({
            div(class = "connection-error",
                h5("✗ Connection Failed"),
                p(strong("Error:"), result$message),
                hr(),
                h5("💡 Troubleshooting:"),
                tags$ul(
                  tags$li("Verify the JSON key file is valid"),
                  tags$li("Check project/dataset/table IDs are correct"),
                  tags$li("Ensure service account has BigQuery Data Viewer role"),
                  tags$li("Confirm internet connectivity")
                ))
          })
          
          showNotification(paste("Connection failed:", result$message), 
                           type = "error", 
                           duration = 15)
        }
      })
    })
    
    # Clear authentication
    observeEvent(input$clearAuth, {
      if (!is.null(api_manager)) {
        result <- api_manager$clear_auth()
        
        output$bqConnectionStatus <- renderUI({
          div(class = "connection-success",
              h5("✓ Authentication Cleared"),
              p("Please upload a new JSON key file to reconnect."))
        })
        
        showNotification("Authentication cleared", type = "message", duration = 3)
      }
    })
    
    # Watch for state updates (reactive trigger pattern)
    observe({
      api_manager$state_trigger()  # Watch for changes
      
      # Update config info
      output$bqConfigInfo <- renderText({
        if (is.null(api_manager) || !api_manager$bq_authenticated) {
          return("Not connected")
        }
        
        status <- api_manager$get_status()
        
        paste(
          paste("Project ID:", status$project_id),
          paste("Dataset:", status$dataset_id),
          paste("Table:", status$table_id),
          paste("Status: Connected ✓"),
          sep = "\n"
        )
      })
      
      # Update data preview
      output$bqDataPreview <- renderText({
        if (is.null(api_manager) || !api_manager$bq_authenticated) {
          return("No data loaded")
        }
        
        charging_points <- api_manager$get_charging_points()
        
        if (is.null(charging_points)) {
          return("No charging points loaded")
        }
        
        paste(
          paste("Total Charging Points:", format(nrow(charging_points), big.mark = ",")),
          paste("Columns:", ncol(charging_points)),
          paste("CRS:", st_crs(charging_points)$input),
          sep = "\n"
        )
      })
    })
  })
}
