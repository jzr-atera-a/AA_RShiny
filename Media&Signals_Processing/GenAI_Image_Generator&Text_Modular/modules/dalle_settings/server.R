dalle_settings_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$saveBtn, {
      api_manager$set_dalle_key(input$apiKey)
      api_manager$set_dalle_config(
        model = input$model,
        quality = input$quality,
        style = input$style
      )
      showNotification("DALL-E settings saved!", type = "message")
    })
    
    observeEvent(input$testBtn, {
      result <- api_manager$test_connection(input$apiKey)
      output$status <- renderText(result$message)
      
      if (result$success) {
        api_manager$set_dalle_key(input$apiKey)
        showNotification("Connection successful!", type = "message")
      } else {
        showNotification("Connection failed!", type = "error")
      }
    })
  })
}
