# modules/bq_config/server.R
# BigQuery Configuration Server Logic
# ====================================

bq_config_server <- function(id, contact_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Save BigQuery Settings
    observeEvent(input$save_bq, {
      contact_manager$set_bigquery_credentials(
        project = trimws(input$bq_project),
        dataset = trimws(input$bq_dataset),
        table = trimws(input$bq_table),
        comm_table = trimws(input$bq_comm_table),
        credentials = if(!is.null(input$bq_key_file)) input$bq_key_file$datapath else NULL
      )
      
      output$bq_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " BigQuery settings saved!",
                 tags$br(),
                 tags$small("Project: ", contact_manager$bq_project),
                 tags$br(),
                 tags$small("Dataset: ", contact_manager$bq_dataset))
      })
      
      showNotification("BigQuery settings saved!", type = "message", duration = 3)
    })
    
    # Test BigQuery Connection
    observeEvent(input$test_bq, {
      if (input$bq_auth_method == "json_key" && is.null(input$bq_key_file)) {
        showNotification("Please upload a JSON key file!", type = "error", duration = 3)
        return()
      }
      
      showNotification("Testing BigQuery connection...", type = "message", duration = NULL, id = "test_bq")
      
      tryCatch({
        if (!is.null(input$bq_key_file)) {
          contact_manager$authenticate_bigquery(json_path = input$bq_key_file$datapath)
        }
        
        contact_manager$test_bigquery_connection()
        
        removeNotification(id = "test_bq")
        
        output$bq_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " BigQuery connection successful!",
                   tags$br(),
                   tags$small(nrow(contact_manager$contacts_data), " contacts loaded"))
        })
        
        showNotification("BigQuery connection successful!", type = "message", duration = 5)
        
      }, error = function(e) {
        removeNotification(id = "test_bq")
        
        output$bq_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Connection failed: ", e$message)
        })
        
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Create Tables
    observeEvent(input$create_table_bq, {
      showNotification("Creating BigQuery tables...", type = "message", duration = NULL, id = "create_bq")
      
      tryCatch({
        if (!is.null(input$bq_key_file)) {
          contact_manager$authenticate_bigquery(json_path = input$bq_key_file$datapath)
        }
        
        contact_manager$create_bigquery_tables()
        
        removeNotification(id = "create_bq")
        
        output$bq_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Tables created successfully!")
        })
        
        showNotification("Tables created successfully!", type = "message", duration = 5)
        
      }, error = function(e) {
        removeNotification(id = "create_bq")
        output$bq_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Default output
    output$bq_status <- renderUI({ tags$div() })
  })
}
