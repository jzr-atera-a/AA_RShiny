claude_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$save, {
      if (nchar(trimws(input$claude_key)) > 0) {
        api_manager$set_claude_credentials(trimws(input$claude_key), input$model)
        
        output$status <- renderUI({
          div(class = "api-status-success",
              icon("check-circle"), " Claude API saved! Model: ", input$model)
        })
        
        showNotification("Claude API Key saved successfully!", 
                         type = "message", 
                         duration = 3)
      } else {
        output$status <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), " Please enter a valid Claude API key.")
        })
        showNotification("Please enter a valid Claude API key", 
                         type = "error", 
                         duration = 3)
      }
    })
    
    observeEvent(input$test, {
      if (!api_manager$claude_authenticated || is.null(api_manager$claude_api_key)) {
        showNotification("Please save your Claude API key first!", 
                         type = "error", 
                         duration = 3)
        return()
      }
      
      showNotification("Testing Claude API connection...", 
                       type = "message", 
                       duration = NULL, 
                       id = "test_claude")
      
      test_result <- tryCatch({
        api_manager$test_claude_connection()
        
        removeNotification(id = "test_claude")
        
        output$status <- renderUI({
          div(class = "api-status-success",
              icon("check-circle"), " Claude API connection successful! Model: ", api_manager$claude_model, " is working correctly.")
        })
        showNotification("Claude API connection successful!", 
                         type = "message", 
                         duration = 5)
        TRUE
      }, error = function(e) {
        removeNotification(id = "test_claude")
        
        output$status <- renderUI({
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
