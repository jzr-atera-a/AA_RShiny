# modules/claude_auth/server.R
# Claude API Connection Server Logic

claude_auth_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Connection button handler
    observeEvent(input$connect_claude, {
      if (is.null(input$claude_api_key) || trimws(input$claude_api_key) == "") {
        output$claude_status <- renderUI({
          create_status_html("error", "Please provide an API key")
        })
        return()
      }
      
      # Attempt to connect
      output$claude_status <- renderUI({
        create_status_html("info", "Testing connection...", icon = "spinner fa-spin")
      })
      
      tryCatch({
        success <- api_manager$set_claude_credentials(input$claude_api_key)
        
        if (success) {
          output$claude_status <- renderUI({
            create_status_html(
              "success", 
              "Successfully connected to Claude API!",
              details = "Model: Claude Sonnet 4"
            )
          })
          
          showNotification("✓ Claude API connection established!", type = "message")
        } else {
          stop("API key validation failed")
        }
        
      }, error = function(e) {
        output$claude_status <- renderUI({
          create_status_html(
            "error",
            "Connection failed. Please check your API key.",
            details = "Make sure your API key is valid and has the correct permissions."
          )
        })
        
        showNotification("Claude API connection failed", type = "error")
      })
    })
    
    # Initialize with info message
    output$claude_status <- renderUI({
      create_status_html("info", "Not connected. Please enter your API key above.")
    })
  })
}
