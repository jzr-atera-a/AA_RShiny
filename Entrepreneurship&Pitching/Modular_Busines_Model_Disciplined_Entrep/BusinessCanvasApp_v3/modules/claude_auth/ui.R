# Claude API Connection Module - UI

claude_auth_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Claude API Configuration", 
        status = "primary", 
        solidHeader = TRUE,
        width = 12,
        
        h4("Connect to Anthropic Claude API"),
        p("Enter your Claude API key to enable AI-powered features."),
        
        div(class = "alert alert-info",
            tags$strong("Get your API key from:"),
            tags$a(href = "https://console.anthropic.com/", target = "_blank", 
                   "Anthropic Console", style = "margin-left: 10px;")),
        
        fluidRow(
          column(6,
                 passwordInput(ns("api_key"), 
                               "Claude API Key:",
                               placeholder = "sk-ant-...",
                               width = "100%")
          ),
          column(6,
                 selectInput(ns("model_select"), 
                             "Claude Model:",
                             choices = c(
                               "Claude Sonnet 4 (Latest)" = "claude-sonnet-4-20250514",
                               "Claude Sonnet 3.5" = "claude-3-5-sonnet-20241022",
                               "Claude Opus 3" = "claude-3-opus-20240229"
                             ),
                             selected = "claude-sonnet-4-20250514",
                             width = "100%")
          )
        ),
        
        fluidRow(
          column(6,
                 numericInput(ns("max_tokens"), 
                              "Max Tokens:",
                              value = 4000,
                              min = 100,
                              max = 8000,
                              step = 100,
                              width = "100%")
          ),
          column(6,
                 numericInput(ns("timeout_seconds"), 
                              "Timeout (seconds):",
                              value = 180,
                              min = 30,
                              max = 600,
                              step = 30,
                              width = "100%")
          )
        ),
        
        br(),
        actionButton(ns("connect_claude"), 
                     "Connect to Claude", 
                     class = "btn-primary btn-lg",
                     icon = icon("plug"),
                     width = "200px"),
        
        br(), br(),
        htmlOutput(ns("connection_status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Test Claude API", 
        status = "info", 
        solidHeader = TRUE,
        width = 12,
        
        h5("Test your API connection:"),
        
        fluidRow(
          column(9,
                 textInput(ns("test_prompt"), 
                           "Test Prompt:",
                           value = "Say hello and confirm you are Claude!",
                           width = "100%")
          ),
          column(3,
                 br(),
                 actionButton(ns("test_claude"), 
                              "Test API", 
                              class = "btn-info btn-lg",
                              icon = icon("paper-plane"),
                              width = "100%")
          )
        ),
        
        br(),
        h5("Claude's Response:"),
        verbatimTextOutput(ns("test_output"))
      )
    )
  )
}
