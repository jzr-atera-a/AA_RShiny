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
        
        h4("Configure Claude API for Schedule Generation"),
        p("Enter your Anthropic API credentials to enable AI-powered day schedule generation."),
        
        fluidRow(
          column(6,
                 textInput(ns("api_key"),
                           "API Key:",
                           value = "",
                           placeholder = "sk-ant-api03-..."),
                 
                 selectInput(ns("model"),
                             "Model:",
                             choices = c(
                               "Claude Sonnet 4.6 (Recommended)" = "claude-sonnet-4-6",
                               "Claude Opus 4.8 (Most Capable)" = "claude-opus-4-8",
                               "Claude Haiku 4.5 (Fastest)" = "claude-haiku-4-5-20251001"
                             ),
                             selected = "claude-sonnet-4-6"),
                 
                 numericInput(ns("max_tokens"),
                              "Max Tokens:",
                              value = 8000,
                              min = 1000,
                              max = 32000,
                              step = 1000),
                 
                 numericInput(ns("timeout"),
                              "Request Timeout (seconds):",
                              value = 180,
                              min = 60,
                              max = 600,
                              step = 30),
                 
                 div(class = "alert alert-info",
                     style = "margin-top: 10px;",
                     tags$strong("Timeout Info:"), br(),
                     "A single day with 6-10 stops usually takes 30-90 seconds.", br(),
                     "Default: 180 seconds (3 minutes).", br(),
                     "Increase if you get timeout errors.")
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
