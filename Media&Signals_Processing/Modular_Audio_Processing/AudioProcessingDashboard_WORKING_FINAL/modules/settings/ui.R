settings_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "OpenAI API Configuration",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "Enter API key..."),
        selectInput(ns("model"), "Whisper Model:", choices = c("whisper-1" = "whisper-1")),
        selectInput(ns("language"), "Language:", 
          choices = c("Auto" = "", "English" = "en", "Spanish" = "es", "French" = "fr")),
        actionButton(ns("saveSettings"), "Save Settings", class = "btn-warning"),
        br(), br(),
        actionButton(ns("testConnection"), "Test Connection", class = "btn-info", icon = icon("plug")),
        br(), br(),
        conditionalPanel(
          condition = paste0("output['", ns("connectionTested"), "']"),
          div(class = "reference-box",
            h5("API Status:"),
            verbatimTextOutput(ns("apiStatus"))
          )
        )
      ),
      box(
        title = "App Info",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        h4("Features:"),
        tags$ul(
          tags$li("Audio transcription"),
          tags$li("File conversion"),
          tags$li("File splitting"),
          tags$li("Bulk analysis")
        )
      )
    )
  )
}
