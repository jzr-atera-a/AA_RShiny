settings_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    values <- reactiveValues(tested = FALSE, status = "")
    
    observeEvent(input$saveSettings, {
      req(input$apiKey)
      api_manager$set_credentials(input$apiKey, input$model, input$language)
      values$tested <- FALSE
      showNotification("Settings saved!", type = "message")
    })
    
    observeEvent(input$testConnection, {
      req(input$apiKey)
      api_manager$set_credentials(input$apiKey, input$model, input$language)
      result <- api_manager$test_connection()
      values$tested <- TRUE
      values$status <- result$message
      showNotification(if(result$success) "Success!" else "Failed", 
                      type = if(result$success) "message" else "error")
    })
    
    output$connectionTested <- reactive({ values$tested })
    outputOptions(output, 'connectionTested', suspendWhenHidden = FALSE)
    output$apiStatus <- renderText({ values$status })
  })
}
