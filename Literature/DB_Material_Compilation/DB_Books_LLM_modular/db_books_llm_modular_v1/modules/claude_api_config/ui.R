# modules/claude_api_config/ui.R
# Claude API Configuration UI

claude_api_config_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Claude API Credentials",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("Configure Claude API for Summary Generation"),
        p("Enter your Anthropic API credentials to enable AI-powered book summary generation."),
        
        fluidRow(
          column(6,
                 textInput(ns("api_key"),
                           "API Key:",
                           value = "",
                           placeholder = "sk-ant-api03-..."),
                 
                 selectInput(ns("model"),
                             "Model:",
                             choices = c(
                               "Claude Sonnet 4.5 (Recommended)" = "claude-sonnet-4-20250514",
                               "Claude Sonnet 3.5" = "claude-3-5-sonnet-20241022",
                               "Claude Opus 3" = "claude-3-opus-20240229"
                             ),
                             selected = "claude-sonnet-4-20250514"),
                 
                 numericInput(ns("max_tokens"),
                              "Max Tokens:",
                              value = 16000,
                              min = 1000,
                              max = 32000,
                              step = 1000)
          ),
          column(6,
                 h5("Actions:"),
                 actionButton(ns("test_connection"),
                              "Test Connection",
                              icon = icon("plug"),
                              class = "btn-info",
                              style = "width: 100%; margin-bottom: 10px;"),
                 
                 actionButton(ns("save_credentials"),
                              "Save Credentials",
                              icon = icon("save"),
                              class = "btn-success",
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
