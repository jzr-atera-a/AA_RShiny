# modules/claude_auth/ui.R
# Claude API Connection UI

claude_auth_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Claude API Connection", 
        status = "primary", 
        solidHeader = TRUE,
        width = 12,
        
        h4("Connect to Claude API"),
        p("Provide your Anthropic API key to enable AI-powered content generation."),
        div(class = "alert alert-info",
            tags$strong("Note:"), 
            " Your API key will be stored securely for this session only. Get your API key from ", 
            tags$a(href = "https://console.anthropic.com/", target = "_blank", "Anthropic Console")),
        
        fluidRow(
          column(8,
                 passwordInput(ns("claude_api_key"), 
                               "Anthropic API Key:",
                               placeholder = "sk-ant-api...",
                               width = "100%")
          ),
          column(4,
                 br(),
                 actionButton(ns("connect_claude"), 
                              "Connect to Claude", 
                              class = "btn-primary btn-lg",
                              icon = icon("plug"),
                              width = "100%")
          )
        ),
        
        hr(),
        h4("Connection Status"),
        htmlOutput(ns("claude_status")),
        
        hr(),
        h5("How it works:"),
        tags$ul(
          tags$li("Provide your business details and description"),
          tags$li("Claude generates structured content based on proven frameworks"),
          tags$li("Review and edit the generated content"),
          tags$li("Save to BigQuery for visualization and management")
        )
      )
    )
  )
}
