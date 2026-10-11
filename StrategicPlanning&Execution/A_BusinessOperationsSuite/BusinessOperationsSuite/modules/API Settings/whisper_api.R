# modules/API Settings/whisper_api.R
# Subtab: Whisper API Settings
# MOVED FROM: Audio Transcription/whisper_settings.R
# FIXED: Uses openai_base.R for proper error handling and timeout logic

whisper_api_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(title = "Whisper API Configuration", status = "warning", solidHeader = TRUE, width = 8,
        h5("API Credentials"),
        passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "sk-..."),
        p(em("Get your API key from https://platform.openai.com/api-keys"), style = "color: #666; font-size: 12px;"),

        h5("Model Settings"),
        selectInput(ns("model"), "Model:",
                    choices = c("Whisper-1" = "whisper-1"),
                    selected = "whisper-1"),
        selectInput(ns("language"), "Language (Optional):",
                    choices = c(
                      "Auto-detect" = "",
                      "English" = "en",
                      "Spanish" = "es",
                      "French" = "fr",
                      "German" = "de",
                      "Italian" = "it",
                      "Portuguese" = "pt",
                      "Dutch" = "nl",
                      "Russian" = "ru",
                      "Chinese (Simplified)" = "zh",
                      "Japanese" = "ja",
                      "Korean" = "ko"
                    ),
                    selected = ""),

        br(),
        h5("Actions"),
        fluidRow(
          column(6, actionButton(ns("saveBtn"), "Save Settings", class = "btn-warning", style = "width: 100%;")),
          column(6, actionButton(ns("testBtn"), "Test Connection", class = "btn-info", style = "width: 100%;"))
        ),
        br(),

        h5("Status"),
        verbatimTextOutput(ns("status")))
  )
}

whisper_api_server <- function(id, openai_api_manager) {
  moduleServer(id, function(input, output, session) {

    # Save credentials
    observeEvent(input$saveBtn, {
      if (nchar(trimws(input$apiKey)) == 0) {
        output$status <- renderText("⚠️ API Key is required")
        showNotification("Please enter your OpenAI API key", type = "warning")
        return()
      }

      tryCatch({
        openai_api_manager$set_whisper_credentials(
          api_key = input$apiKey,
          model = input$model,
          language = input$language
        )

        output$status <- renderText(paste(
          "✅ Whisper settings saved successfully\n\n",
          "Model: ", input$model, "\n",
          "Language: ", if (nchar(input$language) > 0) input$language else "Auto-detect", "\n\n",
          "Ready to use in Audio Transcription tab"
        ))

        showNotification("Whisper settings saved!", type = "message")

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
        openai_api_manager$set_whisper_credentials(
          api_key = input$apiKey,
          model = input$model,
          language = input$language
        )

        # Test connection
        result <- openai_api_manager$test_whisper_connection()

        output$status <- renderText(paste(
          result$message, "\n\n",
          if (result$success) {
            "✓ Connection verified\n✓ API key is valid\n✓ Ready to transcribe audio"
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
      "Steps:\n1. Enter your API key\n2. Click 'Save Settings'\n3. Click 'Test Connection'\n4. Use in Audio Transcription tab"
    ))
  })
}
