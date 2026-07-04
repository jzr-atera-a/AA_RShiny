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
                               "Claude Sonnet 4.6 (Recommended)" = "claude-sonnet-4-6",
                               "Claude Opus 4.8 (Most Capable)" = "claude-opus-4-8",
                               "Claude Haiku 4.5 (Fastest)" = "claude-haiku-4-5-20251001"
                             ),
                             selected = "claude-sonnet-4-6"),
                 
                 numericInput(ns("max_tokens"),
                              "Max Tokens:",
                              value = 16000,
                              min = 1000,
                              max = 64000,
                              step = 1000),
                 
                 numericInput(ns("timeout"),
                              "Request Timeout (seconds):",
                              value = 300,
                              min = 60,
                              max = 1800,
                              step = 30),
                 
                 div(class = "alert alert-info",
                     style = "margin-top: 10px;",
                     tags$strong("Timeout & Max Tokens Info:"), br(),
                     "Longer or multi-chapter summaries may need both a higher timeout and a higher Max Tokens value.", br(),
                     "Defaults: 300 sec timeout, 16,000 max tokens.", br(),
                     "Increase timeout if you get timeout errors.", br(),
                     "Increase Max Tokens if the generated summary is missing its later chapters or the status shows a truncation warning - that means the response hit the Max Tokens ceiling before finishing, not a timeout. ",
                     "Sonnet 4.6's exact per-response ceiling isn't identical across all sources; 64,000 here is set conservatively below the lowest figure reported, so raising this slider as high as it goes should be safe.")
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
