# modules/api_config/ui.R
# API Configuration UI
# ====================

api_config_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "OpenAI API Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p("Enter your OpenAI API key below. This key will be stored securely for the duration of your session."),
        p("You can obtain an API key from: ", 
          tags$a(href = "https://platform.openai.com/api-keys", 
                 target = "_blank", 
                 style = "color: #7ec8e3;",
                 "https://platform.openai.com/api-keys")),
        br(),
        passwordInput(ns("api_key"), "OpenAI API Key:", 
                      placeholder = "sk-...",
                      width = "100%"),
        selectInput(ns("gpt_model"), "Select LLM Model:",
                    choices = c("gpt-4" = "gpt-4",
                                "gpt-4-turbo" = "gpt-4-turbo",
                                "gpt-4o" = "gpt-4o",
                                "gpt-3.5-turbo" = "gpt-3.5-turbo"),
                    selected = "gpt-4",
                    width = "50%"),
        br(),
        actionButton(ns("save_api"), "Save API Key", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_api"), "Test API Connection", class = "btn-info", icon = icon("plug")),
        br(), br(),
        htmlOutput(ns("api_status")),
        br(),
        h4("Instructions:"),
        tags$ol(
          tags$li("Paste your OpenAI API key in the field above"),
          tags$li("Select your preferred LLM model"),
          tags$li("Click 'Save API Key' to store it for this session"),
          tags$li("Optionally click 'Test API Connection' to verify it works"),
          tags$li("Navigate to 'BigQuery Settings' tab to configure database connection")
        )
      )
    )
  )
}
