# modules/bigquery_connection.R
# BigQuery Connection Module - Single File (UI + Server)

bigquery_connection_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "BigQuery Authentication", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Upload Service Account Key"),
        p("Upload Google Cloud service account JSON key to connect to BigQuery charging infrastructure."),
        
        fileInput(ns("jsonKey"), "Select JSON Key File:",
                  accept = c(".json"),
                  buttonLabel = "Browse...",
                  placeholder = "No file selected"),
        
        textInput(ns("projectId"), "Project ID:", 
                  value = "atera-2",
                  placeholder = "GCP project ID"),
        
        textInput(ns("datasetId"), "Dataset ID:", 
                  value = "EVs_Infrastructure",
                  placeholder = "Dataset ID"),
        
        textInput(ns("tableId"), "Table ID:", 
                  value = "Charge_Points_UK_EVs",
                  placeholder = "Table ID"),
        
        br(),
        
        actionButton(ns("testBQConnection"), "Test Connection", 
                     class = "btn-primary", width = "48%"),
        actionButton(ns("clearAuth"), "Clear Authentication", 
                     class = "btn-warning", width = "48%"),
        
        br(), br(),
        uiOutput(ns("bqConnectionStatus"))
      ),
      
      box(
        title = "Connection Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        
        h5("Current Configuration:"),
        verbatimTextOutput(ns("bqConfigInfo")),
        
        br(),
        h5("Data Preview:"),
        verbatimTextOutput(ns("bqDataPreview"))
      )
    )
  )
}

bigquery_connection_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$testBQConnection, {
      if (is.null(input$jsonKey)) {
        output$bqConnectionStatus <- renderUI({
          div(class = "connection-error", 
              h5("❌ Authentication Failed"), 
              p("Please upload a JSON key file."))
        })
        return()
      }
      
      withProgress(message = 'Authenticating...', value = 0, {
        
        incProgress(0.3, detail = "Verifying credentials")
        
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
                p(result$message))
          })
          
          showNotification("BigQuery connected!", type = "message", duration = 5)
        } else {
          output$bqConnectionStatus <- renderUI({
            div(class = "connection-error",
                h5("✗ Connection Failed"),
                p(strong("Error:"), result$message))
          })
          
          showNotification(paste("Failed:", result$message), type = "error", duration = 15)
        }
      })
    })
    
    observeEvent(input$clearAuth, {
      result <- api_manager$clear_auth()
      
      output$bqConnectionStatus <- renderUI({
        div(class = "connection-success",
            h5("✓ Cleared"),
            p("Upload new JSON key to reconnect."))
      })
      
      showNotification("Authentication cleared", type = "message", duration = 3)
    })
    
    observe({
      api_manager$state_trigger()
      
      output$bqConfigInfo <- renderText({
        if (!api_manager$bq_authenticated) {
          return("Not connected")
        }
        
        status <- api_manager$get_status()
        paste(
          paste("Project:", status$project_id),
          paste("Dataset:", status$dataset_id),
          paste("Table:", status$table_id),
          paste("Status: Connected ✓"),
          sep = "\n"
        )
      })
      
      output$bqDataPreview <- renderText({
        if (!api_manager$bq_authenticated) {
          return("No data loaded")
        }
        
        charging_points <- api_manager$get_charging_points()
        
        if (is.null(charging_points)) {
          return("No charging points")
        }
        
        paste(
          paste("Charging Points:", format(nrow(charging_points), big.mark = ",")),
          paste("Columns:", ncol(charging_points)),
          paste("CRS:", st_crs(charging_points)$input),
          sep = "\n"
        )
      })
    })
  })
}
