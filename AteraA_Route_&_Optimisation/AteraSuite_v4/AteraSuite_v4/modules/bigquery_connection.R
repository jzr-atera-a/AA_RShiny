# modules/bigquery_connection.R
# BigQuery Connection Module - Simplified for reactiveValues

bigquery_connection_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "BigQuery Authentication", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Connect to BigQuery"),
        p("Configure BigQuery connection for charging point data."),
        
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
        
        actionButton(ns("testBQConnection"), "Connect to BigQuery", 
                     class = "btn-primary", width = "48%"),
        actionButton(ns("clearAuth"), "Clear", 
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
      
      withProgress(message = 'Connecting...', value = 0, {
        
        incProgress(0.3, detail = "Authenticating")
        
        tryCatch({
          # Store credentials
          api_manager$bq_project_id <- input$projectId
          api_manager$bq_dataset_id <- input$datasetId
          api_manager$bq_table_id <- input$tableId
          
          incProgress(0.6, detail = "Loading data")
          
          # Simulate loading (replace with real BigQuery call)
          Sys.sleep(1)
          
          # Mock charging points data
          api_manager$charging_points <- data.frame(
            name = c("Charger 1", "Charger 2", "Charger 3"),
            lat = c(52.2, 52.3, 52.4),
            lon = c(0.1, 0.2, 0.3),
            stringsAsFactors = FALSE
          )
          
          incProgress(1, detail = "Complete")
          
          output$bqConnectionStatus <- renderUI({
            div(class = "connection-success",
                style = "background: #d4edda; padding: 10px; border-radius: 5px;",
                h5("✓ Connection Successful"),
                p(strong("Project:"), input$projectId),
                p("Ready to use charging point data"))
          })
          
          showNotification("BigQuery connected!", type = "message", duration = 5)
          
        }, error = function(e) {
          output$bqConnectionStatus <- renderUI({
            div(class = "connection-error",
                style = "background: #f8d7da; padding: 10px; border-radius: 5px;",
                h5("✗ Connection Failed"),
                p(strong("Error:"), e$message))
          })
          
          showNotification(paste("Failed:", e$message), type = "error", duration = 15)
        })
      })
    })
    
    observeEvent(input$clearAuth, {
      api_manager$bq_project_id <- NULL
      api_manager$bq_dataset_id <- NULL
      api_manager$bq_table_id <- NULL
      api_manager$charging_points <- NULL
      
      output$bqConnectionStatus <- renderUI({
        div(class = "connection-warning",
            style = "background: #fff3cd; padding: 10px; border-radius: 5px;",
            h5("Cleared"),
            p("Authentication cleared"))
      })
      
      showNotification("Authentication cleared", type = "message", duration = 3)
    })
    
    # Config info
    output$bqConfigInfo <- renderText({
      if (is.null(api_manager$bq_project_id)) {
        return("Not connected")
      }
      
      paste(
        paste("Project:", api_manager$bq_project_id),
        paste("Dataset:", api_manager$bq_dataset_id),
        paste("Table:", api_manager$bq_table_id),
        paste("Status: Connected ✓"),
        sep = "\n"
      )
    })
    
    # Data preview
    output$bqDataPreview <- renderText({
      if (is.null(api_manager$charging_points)) {
        return("No data loaded")
      }
      
      charging_points <- api_manager$charging_points
      
      if (nrow(charging_points) == 0) {
        return("No charging points found")
      }
      
      paste(
        paste("Charging Points:", format(nrow(charging_points), big.mark = ",")),
        paste("Columns:", ncol(charging_points)),
        paste("Preview:", paste(head(charging_points[[1]], 3), collapse = ", ")),
        sep = "\n"
      )
    })
    
  })
}
