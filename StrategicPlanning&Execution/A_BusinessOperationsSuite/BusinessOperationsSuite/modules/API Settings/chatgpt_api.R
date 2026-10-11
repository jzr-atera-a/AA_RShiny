# modules/API Settings/chatgpt_api.R
# Subtab: ChatGPT API Settings
# MOVED FROM: Audio Transcription/chatgpt_settings.R
# FIXED: Uses openai_base.R for proper error handling and timeout logic

chatgpt_api_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(title = "ChatGPT API Configuration", status = "primary", solidHeader = TRUE, width = 8,
        h5("API Credentials"),
        passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "sk-..."),
        p(em("Get your API key from https://platform.openai.com/api-keys"), style = "color: #666; font-size: 12px;"),

        h5("Model Settings"),
        selectInput(ns("model"), "Model:",
                    choices = c(
                      "GPT-4o" = "gpt-4o",
                      "GPT-4o Mini" = "gpt-4o-mini",
                      "GPT-4 Turbo" = "gpt-4-turbo",
                      "GPT-4" = "gpt-4"
                    ),
                    selected = "gpt-4o-mini"),

        h5("Generation Parameters"),
        fluidRow(
          column(6,
            numericInput(ns("temperature"), "Temperature:",
                        value = 0.7, min = 0, max = 2, step = 0.1)
          ),
          column(6,
            numericInput(ns("maxTokens"), "Max Tokens:",
                        value = 2000, min = 100, max = 8000, step = 100)
          )
        ),

        p(em("Temperature: 0 = deterministic, 1 = balanced, 2 = creative"),
          style = "color: #666; font-size: 11px;"),

        br(),
        h5("Actions"),
        fluidRow(
          column(6, actionButton(ns("saveBtn"), "Save Settings", class = "btn-primary", style = "width: 100%;")),
          column(6, actionButton(ns("testBtn"), "Test Connection", class = "btn-info", style = "width: 100%;"))
        ),
        br(),

        h5("Status"),
        verbatimTextOutput(ns("status")))
  )
}

chatgpt_api_server <- function(id, openai_api_manager) {
  moduleServer(id, function(input, output, session) {

    # Save credentials
    observeEvent(input$saveBtn, {
      if (nchar(trimws(input$apiKey)) == 0) {
        output$status <- renderText("⚠️ API Key is required")
        showNotification("Please enter your OpenAI API key", type = "warning")
        return()
      }

      # Validate parameters
      if (input$temperature < 0 || input$temperature > 2) {
        output$status <- renderText("⚠️ Temperature must be between 0 and 2")
        showNotification("Invalid temperature value", type = "warning")
        return()
      }

      if (input$maxTokens < 100 || input$maxTokens > 8000) {
        output$status <- renderText("⚠️ Max tokens must be between 100 and 8000")
        showNotification("Invalid max tokens value", type = "warning")
        return()
      }

      tryCatch({
        openai_api_manager$set_chatgpt_credentials(
          api_key = input$apiKey,
          model = input$model,
          temperature = input$temperature,
          max_tokens = input$maxTokens
        )

        output$status <- renderText(paste(
          "✅ ChatGPT settings saved successfully\n\n",
          "Model: ", input$model, "\n",
          "Temperature: ", input$temperature, "\n",
          "Max Tokens: ", input$maxTokens, "\n\n",
          "Ready to use in Audio Transcription > Summary tab"
        ))

        showNotification("ChatGPT settings saved!", type = "message")

      }, error = function(e) {
        output$status <- renderText(paste("❌ Error:", e$message))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # Test connection
    observeEvent(input$testBtn, {
      if (nchar(trimws(input$apiKey)) == 0) {
        output$status <- renderText("⚠️ API Key is required for testing")
        showNotification("Please enter your OpenAI API key first", type = "warning")
        return()
      }

      tryCatch({
        output$status <- renderText("🔄 Testing connection...")

        # Update credentials temporarily for testing
        openai_api_manager$set_chatgpt_credentials(
          api_key = input$apiKey,
          model = input$model,
          temperature = input$temperature,
          max_tokens = input$maxTokens
        )

        # Test connection
        result <- openai_api_manager$test_chatgpt_connection()

        output$status <- renderText(paste(
          result$message, "\n\n",
          if (result$success) {
            "✓ Connection verified\n✓ API key is valid\n✓ Ready to analyze text"
          } else {
            "Troubleshooting:\n• Check API key is correct\n• Verify account has API access\n• Check OpenAI status page"
          }
        ))

        if (result$success) {
          showNotification("Connection successful!", type = "message")
        } else {
          showNotification("Connection failed. Check credentials.", type = "error")
        }

      }, error = function(e) {
        output$status <- renderText(paste("❌ Test failed:", e$message))
        showNotification(paste("Test error:", e$message), type = "error")
      })
    })

    # Initialize status
    output$status <- renderText(paste(
      "ℹ️ Configure your OpenAI API key above\n\n",
      "Steps:\n1. Enter your API key\n2. Set model and parameters\n3. Click 'Save Settings'\n4. Click 'Test Connection'\n5. Use in Audio Transcription tabs"
    ))
  })
}
