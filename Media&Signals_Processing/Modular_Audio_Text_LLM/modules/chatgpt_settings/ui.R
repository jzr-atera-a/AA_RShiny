chatgpt_settings_ui <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    box(
      title = "ChatGPT API Configuration",
      status = "primary",
      solidHeader = TRUE,
      width = 8,
      
      passwordInput(ns("apiKey"), "OpenAI API Key:", placeholder = "sk-..."),
      selectInput(ns("model"), "Model:", 
                  choices = c("GPT-4o Mini" = "gpt-4o-mini", "GPT-4o" = "gpt-4o", "GPT-4" = "gpt-4"),
                  selected = "gpt-4o-mini"),
      numericInput(ns("temperature"), "Temperature:", value = 0.7, min = 0, max = 2, step = 0.1),
      numericInput(ns("maxTokens"), "Max Tokens:", value = 2000, min = 100, max = 8000, step = 100),
      br(),
      actionButton(ns("saveBtn"), "Save Settings", class = "btn-primary", style = "width: 100%;"),
      br(), br(),
      actionButton(ns("testBtn"), "Test Connection", class = "btn-info"),
      br(), br(),
      verbatimTextOutput(ns("status"))
    )
  )
}