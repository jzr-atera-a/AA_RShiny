claude_config_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Claude (Anthropic) API Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p("Enter your Claude API key below. This key will be stored securely for the duration of your session."),
        p("You can obtain an API key from: ", 
          tags$a(href = "https://console.anthropic.com/", 
                 target = "_blank", "https://console.anthropic.com/")),
        br(),
        passwordInput(ns("claude_key"), "Claude API Key:", 
                      placeholder = "sk-ant-...",
                      width = "100%"),
        selectInput(ns("model"), "Select Claude Model:",
                    choices = c(
                      "Claude 3 Haiku - Fast & Affordable" = "claude-3-haiku-20240307",
                      "Claude 3 Sonnet - Balanced" = "claude-3-sonnet-20240229",
                      "Claude 3 Opus - Most Capable" = "claude-3-opus-20240229"
                    ),
                    selected = "claude-3-haiku-20240307"),
        actionButton(ns("save"), "Save Claude API Key", class = "btn-success", icon = icon("save")),
        actionButton(ns("test"), "Test Claude Connection", class = "btn-info", icon = icon("plug")),
        br(), br(),
        uiOutput(ns("status")),
        br(),
        h4("Instructions:"),
        tags$ol(
          tags$li("Paste your Claude API key in the field above"),
          tags$li("Select your preferred Claude model"),
          tags$li("Click 'Save Claude API Key' to store it for this session"),
          tags$li("Optionally click 'Test Claude Connection' to verify it works"),
          tags$li("Navigate to 'Claude Diagrams' tab to generate diagrams")
        ),
        br(),
        h4("About Claude Models:"),
        tags$ul(
          tags$li(tags$strong("Claude 3 Opus:"), " Most capable model, best for complex tasks requiring deep reasoning."),
          tags$li(tags$strong("Claude 3 Sonnet:"), " Good balance of performance and speed."),
          tags$li(tags$strong("Claude 3 Haiku:"), " Fastest and most affordable, good for simple tasks.")
        ),
        br(),
        h4("Troubleshooting:"),
        tags$ul(
          tags$li("Ensure your API key starts with 'sk-ant-'"),
          tags$li("Check your API key has sufficient credits at console.anthropic.com"),
          tags$li("Verify your firewall allows connections to api.anthropic.com"),
          tags$li("Claude API has different rate limits than OpenAI")
        )
      )
    )
  )
}
