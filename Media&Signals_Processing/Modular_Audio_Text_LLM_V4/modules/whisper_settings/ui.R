whisper_settings_ui <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    box(
      title = "Whisper API Configuration",
      status = "warning",
      solidHeader = TRUE,
      width = 8,
      
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
      verbatimTextOutput(ns("status"))
    )
  )
}