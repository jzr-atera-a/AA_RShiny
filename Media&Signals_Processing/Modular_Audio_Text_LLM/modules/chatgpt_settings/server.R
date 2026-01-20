chatgpt_settings_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$saveBtn, {
      api_manager$set_chatgpt_key(input$apiKey)
      api_manager$set_chatgpt_config(input$model, input$temperature, input$maxTokens)
      showNotification("ChatGPT settings saved!", type = "message")
    })
    
    observeEvent(input$testBtn, {
      result <- api_manager$test_connection(input$apiKey)
      output$status <- renderText(result$message)
      if (result$success) {
        api_manager$set_chatgpt_key(input$apiKey)
        showNotification("Connection successful!", type = "message")
      } else {
        showNotification("Connection failed!", type = "error")
      }
    })
  })
}