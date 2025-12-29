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
                 target = "_blank", "https://platform.openai.com/api-keys")),
        br(),
        passwordInput(ns("api_key"), "OpenAI API Key:", 
                      placeholder = "sk-...",
                      width = "100%"),
        actionButton(ns("save_api"), "Save API Key", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_api"), "Test API Connection", class = "btn-info", icon = icon("plug")),
        br(), br(),
        uiOutput(ns("api_status")),
        br(),
        h4("Instructions:"),
        tags$ol(
          tags$li("Paste your OpenAI API key in the field above"),
          tags$li("Click 'Save API Key' to store it for this session"),
          tags$li("Optionally click 'Test API Connection' to verify it works"),
          tags$li("Navigate to 'Project Details' tab to start creating your application")
        ),
        br(),
        h4("Troubleshooting:"),
        tags$ul(
          tags$li("If you get DNS errors, check your internet connection"),
          tags$li("Ensure your firewall allows connections to api.openai.com"),
          tags$li("Verify your API key is valid and has sufficient credits"),
          tags$li("Try using a VPN if your region blocks OpenAI services")
        )
      )
    )
  )
}
