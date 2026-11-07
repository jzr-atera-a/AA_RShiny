whisper_settings_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Save settings
    observeEvent(input$saveBtn, {
      api_manager$set_whisper_credentials(
        api_key = input$apiKey,
        model = input$model,
        language = input$language
      )
      showNotification("Whisper settings saved!", type = "message")
    })
    
    # Test connection
    observeEvent(input$testBtn, {
      # First save the key
      api_manager$set_whisper_credentials(
        api_key = input$apiKey,
        model = input$model,
        language = input$language
      )
      
      # Then test it
      result <- api_manager$test_whisper_connection()
      
      output$status <- renderText(result$message)
      
      if (result$success) {
        showNotification("✓ Connection successful!", type = "message")
      } else {
        showNotification("✗ Connection failed!", type = "error")
      }
    })
    
    # Show status output when tested
    output$connectionTested <- reactive({
      !is.null(input$testBtn) && input$testBtn > 0
    })
    outputOptions(output, "connectionTested", suspendWhenHidden = FALSE)
  })
}
