# modules/claude_api_config/ui.R

claude_api_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Claude API Credentials",
        status = "primary", solidHeader = TRUE, width = 12,

        h4("Configure Claude API for AI Event Scanning"),
        p("Enter your Anthropic API credentials to enable AI-powered city event generation."),

        fluidRow(
          column(6,
                 textInput(ns("api_key"), "API Key:", value = "", placeholder = "sk-ant-api03-..."),

                 selectInput(ns("model"), "Model:",
                             choices = c(
                               "Claude Sonnet 4.6 (Recommended)" = "claude-sonnet-4-6",
                               "Claude Opus 4.8 (Most Capable)"  = "claude-opus-4-8",
                               "Claude Haiku 4.5 (Fastest)"      = "claude-haiku-4-5-20251001"
                             ),
                             selected = "claude-sonnet-4-6"),

                 numericInput(ns("max_tokens"), "Max Tokens:", value = 4000, min = 500, max = 16000, step = 500),
                 numericInput(ns("timeout"), "Request Timeout (seconds):", value = 60, min = 30, max = 300, step = 10),

                 div(class = "alert alert-info", style = "margin-top: 10px;",
                     tags$strong("Guidance:"), br(),
                     "5 events ≈ 500 tokens · 30 events ≈ 3,000 tokens.",
                     br(), "Keep max_tokens at 4,000 for most scans.",
                     br(), "60s timeout is sufficient for all scan sizes.")
          ),
          column(6,
                 h5("Actions:"),
                 actionButton(ns("test_connection"), "Test Connection",
                              icon = icon("plug"), class = "btn-info",
                              style = "width: 100%; margin-bottom: 10px;"),
                 actionButton(ns("save_credentials"), "Save Credentials",
                              icon = icon("save"), class = "btn-success",
                              style = "width: 100%;"),
                 hr(),
                 h5("Connection Status:"),
                 htmlOutput(ns("status"))
          )
        )
      )
    )
  )
}
