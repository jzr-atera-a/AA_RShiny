api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$save_api, {
      if (nchar(trimws(input$api_key)) > 0) {
        api_manager$set_openai_credentials(trimws(input$api_key))
        
        output$api_status <- renderUI({
          div(class = "api-status-success",
              icon("check-circle"), " API Key saved successfully! You can now use all tabs.")
        })
        
        showNotification("API Key saved successfully!", 
                         type = "message", 
                         duration = 3)
      } else {
        output$api_status <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), " Please enter a valid API key.")
        })
        showNotification("Please enter a valid API key", 
                         type = "error", 
                         duration = 3)
      }
    })
    
    observeEvent(input$test_api, {
      if (!api_manager$openai_authenticated || is.null(api_manager$openai_api_key)) {
        showNotification("Please save your API key first!", 
                         type = "error", 
                         duration = 3)
        return()
      }
      
      showNotification("Testing API connection...", 
                       type = "message", 
                       duration = NULL, 
                       id = "test_api")
      
      test_result <- tryCatch({
        api_manager$test_openai_connection()
        
        removeNotification(id = "test_api")
        
        output$api_status <- renderUI({
          div(class = "api-status-success",
              icon("check-circle"), " API connection successful! Your key is working correctly.")
        })
        showNotification("API connection successful!", 
                         type = "message", 
                         duration = 5)
        TRUE
      }, error = function(e) {
        removeNotification(id = "test_api")
        
        output$api_status <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), " Connection error: ", e$message)
        })
        
        showNotification(paste("Error:", e$message), 
                         type = "error", 
                         duration = 10)
        FALSE
      })
    })
  })
}
