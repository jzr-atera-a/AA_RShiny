# Claude API Connection Module - Server

claude_auth_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Connect to Claude API
    observeEvent(input$connect_claude, {
      
      # Validate API key
      if (is.null(input$api_key) || trimws(input$api_key) == "") {
        output$connection_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: Please provide a valid API key")
        })
        return()
      }
      
      if (!grepl("^sk-ant-", input$api_key)) {
        output$connection_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Warning: API key should start with 'sk-ant-'")
        })
      }
      
      # Show connecting status
      output$connection_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Connecting to Claude API...")
      })
      
      # Try to connect
      tryCatch({
        # Store credentials in API manager with max_tokens and timeout
        api_manager$set_claude_credentials(
          api_key = trimws(input$api_key),
          max_tokens = input$max_tokens,
          timeout_seconds = input$timeout_seconds
        )
        api_manager$claude_model <- input$model_select
        
        # Test the connection with a simple prompt
        test_response <- api_manager$call_claude(
          prompt = "Respond with exactly: 'Connection successful!'",
          max_tokens = 50
        )
        
        # Success
        output$connection_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully connected to Claude API!",
                   br(),
                   tags$small("Model: ", api_manager$claude_model),
                   br(),
                   tags$small("Max Tokens: ", api_manager$claude_max_tokens),
                   br(),
                   tags$small("Timeout: ", api_manager$claude_timeout, " seconds"),
                   br(),
                   tags$small("Status: Active and ready"))
        })
        
        showNotification("✓ Claude API connected successfully!", type = "message")
        
      }, error = function(e) {
        # Connection failed
        api_manager$claude_connected <- FALSE
        
        output$connection_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Connection failed: ",
                   br(),
                   tags$small(e$message),
                   br(), br(),
                   tags$small("Common issues:"),
                   tags$ul(
                     tags$li("Invalid API key"),
                     tags$li("API key doesn't have sufficient permissions"),
                     tags$li("Network connectivity issues"),
                     tags$li("API rate limits exceeded")
                   ))
        })
        
        showNotification(paste("Connection failed:", e$message), type = "error")
      })
    })
    
    # Test Claude API
    observeEvent(input$test_claude, {
      
      if (!api_manager$claude_connected) {
        output$test_output <- renderText({
          "⚠️ Error: Please connect to Claude API first using the button above."
        })
        showNotification("Please connect to Claude API first", type = "warning")
        return()
      }
      
      if (is.null(input$test_prompt) || trimws(input$test_prompt) == "") {
        output$test_output <- renderText({
          "⚠️ Error: Please enter a test prompt."
        })
        return()
      }
      
      # Show loading
      output$test_output <- renderText({
        "🔄 Sending request to Claude... Please wait."
      })
      
      # Call Claude API
      tryCatch({
        response <- api_manager$call_claude(
          prompt = input$test_prompt,
          max_tokens = 500
        )
        
        output$test_output <- renderText({
          paste0("✓ Claude's Response:\n\n", response)
        })
        
        showNotification("✓ Test successful!", type = "message")
        
      }, error = function(e) {
        output$test_output <- renderText({
          paste0("❌ API Error:\n\n", e$message)
        })
        showNotification(paste("Test failed:", e$message), type = "error")
      })
    })
    
    # Initialize display
    output$connection_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " Not connected. Enter your API key and click 'Connect to Claude'.")
    })
    
    output$test_output <- renderText({
      "Connect to Claude API first to test the connection."
    })
    
  })
}