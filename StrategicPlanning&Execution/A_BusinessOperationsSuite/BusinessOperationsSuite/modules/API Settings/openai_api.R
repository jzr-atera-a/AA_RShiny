# modules/API Settings/openai_api.R
# Unified OpenAI API Settings for BOTH Whisper (transcription) and ChatGPT (summarization)
# Single API key handles both services

openai_api_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "OpenAI API Key", status = "warning", solidHeader = TRUE, width = 12,
          h5("One API Key for Both Whisper & ChatGPT"),
          passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "sk-..."),
          p(em("Get your API key from https://platform.openai.com/api-keys - Use for Whisper transcription and ChatGPT summaries"),
            style = "color: #666; font-size: 12px;"),
          fluidRow(
            column(6, actionButton(ns("saveBtn"), "Save API Key", class = "btn-primary btn-block")),
            column(6, actionButton(ns("testBtn"), "Test Connection", class = "btn-info btn-block"))
          ),
          br(),
          verbatimTextOutput(ns("connectionStatus"))
      )
    ),
    fluidRow(
      box(title = "Whisper Transcription Settings", status = "primary", solidHeader = TRUE, width = 6,
          selectInput(ns("whisperModel"), "Model:",
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
                        "Chinese (Traditional)" = "zh-TW",
                        "Japanese" = "ja"
                      ),
                      selected = "en")
      ),
      box(title = "ChatGPT Summary Settings", status = "info", solidHeader = TRUE, width = 6,
          selectInput(ns("chatgptModel"), "Model:",
                      choices = c(
                        "GPT-4o (Recommended)" = "gpt-4o",
                        "GPT-4o-mini (Fast, Cheap)" = "gpt-4o-mini",
                        "GPT-4-Turbo" = "gpt-4-turbo",
                        "GPT-4" = "gpt-4"
                      ),
                      selected = "gpt-4o-mini"),
          sliderInput(ns("temperature"), "Temperature (Creativity):",
                      min = 0, max = 2, value = 0.7, step = 0.1),
          numericInput(ns("maxTokens"), "Max Tokens (Response Length):",
                       value = 1800, min = 100, max = 8000, step = 100)
      )
    ),
    fluidRow(
      box(title = "Status", status = "success", solidHeader = TRUE, width = 12,
          verbatimTextOutput(ns("settingsStatus"))
      )
    )
  )
}

openai_api_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    values <- reactiveValues(
      status = "No API key configured",
      whisper_ok = FALSE,
      chatgpt_ok = FALSE
    )

    # Save API Key
    observeEvent(input$saveBtn, {
      api_key <- trimws(input$apiKey)
      if (nchar(api_key) == 0) {
        values$status <- "❌ Error: API key cannot be empty"
        return()
      }

      # Set credentials in the APIManager
      api_manager$set_whisper_credentials(
        api_key = api_key,
        model = input$whisperModel,
        language = input$language
      )

      api_manager$set_chatgpt_credentials(
        api_key = api_key,
        model = input$chatgptModel,
        temperature = input$temperature,
        max_tokens = input$maxTokens
      )

      values$status <- "✅ API credentials saved. Click 'Test Connection' to verify."
      showNotification("✅ API key saved successfully!", type = "message", duration = 3)
    })

    # Test Connection
    observeEvent(input$testBtn, {
      api_key <- trimws(input$apiKey)
      if (nchar(api_key) == 0) {
        values$status <- "❌ Error: Please enter API key first"
        return()
      }

      values$status <- "🔄 Testing connections..."

      # Make sure the key/settings being tested are the ones on screen
      api_manager$set_whisper_credentials(api_key = api_key, model = input$whisperModel, language = input$language)
      api_manager$set_chatgpt_credentials(api_key = api_key, model = input$chatgptModel,
                                          temperature = input$temperature, max_tokens = input$maxTokens)

      tryCatch({
        # Test Whisper connection
        whisper_test <- api_manager$test_whisper_connection()
        values$whisper_ok <- whisper_test$success
        whisper_msg <- if (whisper_test$success)
          "✅ Whisper API: Working"
        else
          paste("❌ Whisper API:", whisper_test$message)

        # Test ChatGPT connection
        chatgpt_test <- api_manager$test_chatgpt_connection()
        values$chatgpt_ok <- chatgpt_test$success
        chatgpt_msg <- if (chatgpt_test$success)
          "✅ ChatGPT API: Working"
        else
          paste("❌ ChatGPT API:", chatgpt_test$message)

        if (values$whisper_ok && values$chatgpt_ok) {
          values$status <- paste(whisper_msg, "\n", chatgpt_msg, "\n\n✅ Both APIs configured and working!")
          showNotification("✅ Both APIs working!", type = "message", duration = 5)
        } else {
          values$status <- paste(whisper_msg, "\n", chatgpt_msg, "\n\n⚠️ Some APIs not working - check key and service status")
          showNotification("⚠️ Some connection issues - see details above", type = "warning", duration = 5)
        }
      }, error = function(e) {
        values$status <- paste("❌ Error testing connection:", e$message)
        showNotification(paste("Error:", substr(e$message, 1, 100)), type = "error", duration = 5)
      })
    })

    output$connectionStatus <- renderText({
      values$status
    })

    output$settingsStatus <- renderText({
      if (!values$whisper_ok && !values$chatgpt_ok) {
        "ℹ️ No API key configured yet. Enter your key and click 'Save API Key' then 'Test Connection'."
      } else if (values$whisper_ok && values$chatgpt_ok) {
        "✅ Both Whisper and ChatGPT APIs are configured and ready to use.\n\nAudio Transcription will now work correctly for transcription and summarization."
      } else if (values$whisper_ok) {
        "✅ Whisper API ready. ⚠️ ChatGPT not working - summaries won't work."
      } else if (values$chatgpt_ok) {
        "⚠️ Whisper API not working - transcription won't work. ✅ ChatGPT ready."
      } else {
        "❌ APIs not tested yet."
      }
    })
  })
}
