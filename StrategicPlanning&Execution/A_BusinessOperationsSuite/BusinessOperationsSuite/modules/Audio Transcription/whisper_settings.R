# modules/Audio Transcription/whisper_settings.R
# Subtab: Whisper API Settings

whisper_settings_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(title = "Whisper API Configuration", status = "warning", solidHeader = TRUE, width = 8,
        passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "sk-..."),
        selectInput(ns("model"), "Model:", choices = c("whisper-1"), selected = "whisper-1"),
        selectInput(ns("language"), "Language:",
                    choices = c("Auto-detect" = "", "English" = "en", "Spanish" = "es", "French" = "fr"),
                    selected = ""),
        br(),
        actionButton(ns("saveBtn"), "Save Settings", class = "btn-warning", style = "width: 100%;"),
        br(), br(),
        actionButton(ns("testBtn"), "Test Connection", class = "btn-info"),
        br(), br(),
        verbatimTextOutput(ns("status")))
  )
}

whisper_settings_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$saveBtn, {
      api_manager$set_whisper_credentials(api_key = input$apiKey, model = input$model, language = input$language)
      showNotification("Whisper settings saved!", type = "message")
    })

    observeEvent(input$testBtn, {
      api_manager$set_whisper_credentials(api_key = input$apiKey, model = input$model, language = input$language)
      result <- api_manager$test_whisper_connection()
      output$status <- renderText(result$message)
      if (result$success) showNotification("✓ Connection successful!", type = "message")
      else showNotification("✗ Connection failed!", type = "error")
    })

    output$status <- renderText("")
  })
}
