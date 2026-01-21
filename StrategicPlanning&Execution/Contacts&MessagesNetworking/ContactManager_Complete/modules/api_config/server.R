# modules/api_config/server.R
# API Configuration Server Logic
# ===============================

api_config_server <- function(id, contact_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Save API Key
    observeEvent(input$save_api, {
      if (nchar(trimws(input$api_key)) > 0) {
        contact_manager$set_api_credentials(
          api_key = trimws(input$api_key),
          model = input$gpt_model
        )
        
        output$api_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " API Key saved successfully! Model: ", input$gpt_model)
        })
        
        showNotification("API Key saved successfully!", 
                         type = "message", 
                         duration = 3)
      } else {
        output$api_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-circle"),
                   " Please enter a valid API key.")
        })
        showNotification("Please enter a valid API key", 
                         type = "error", 
                         duration = 3)
      }
    })
    
    # Test API Connection
    observeEvent(input$test_api, {
      if (!contact_manager$api_authenticated) {
        showNotification("Please save your API key first!", 
                         type = "error", 
                         duration = 3)
        return()
      }
      
      showNotification("Testing API connection...", 
                       type = "message", 
                       duration = NULL, 
                       id = "test_api")
      
      tryCatch({
        contact_manager$test_api_connection()
        
        removeNotification(id = "test_api")
        
        output$api_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " API connection successful! Model: ", contact_manager$gpt_model)
        })
        showNotification("API connection successful!", type = "message", duration = 5)
        
      }, error = function(e) {
        removeNotification(id = "test_api")
        output$api_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-circle"),
                   " Connection error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
    
    # Default output
    output$api_status <- renderUI({ tags$div() })
  })
}
