# modules/Audio Transcription/chatgpt_settings.R
# Subtab: ChatGPT API Settings

chatgpt_settings_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(title = "ChatGPT API Configuration", status = "primary", solidHeader = TRUE, width = 8,
        passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "sk-..."),
        selectInput(ns("model"), "Model:",
                    choices = c("GPT-4o Mini" = "gpt-4o-mini", "GPT-4o" = "gpt-4o", "GPT-4" = "gpt-4"),
                    selected = "gpt-4o-mini"),
        numericInput(ns("temperature"), "Temperature:", value = 0.7, min = 0, max = 2, step = 0.1),
        numericInput(ns("maxTokens"), "Max Tokens:", value = 2000, min = 100, max = 8000, step = 100),
        br(),
        actionButton(ns("saveBtn"), "Save Settings", class = "btn-primary", style = "width: 100%;"),
        br(), br(),
        actionButton(ns("testBtn"), "Test Connection", class = "btn-info"),
        br(), br(),
        verbatimTextOutput(ns("status")))
  )
}

chatgpt_settings_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$saveBtn, {
      api_manager$set_chatgpt_credentials(api_key = input$apiKey, model = input$model)
      showNotification("ChatGPT settings saved!", type = "message")
    })

    observeEvent(input$testBtn, {
      api_manager$set_chatgpt_credentials(api_key = input$apiKey, model = input$model)
      result <- api_manager$test_chatgpt_connection()
      output$status <- renderText(result$message)
      if (result$success) showNotification("✓ Connection successful!", type = "message")
      else showNotification("✗ Connection failed!", type = "error")
    })

    output$status <- renderText("")
  })
}
