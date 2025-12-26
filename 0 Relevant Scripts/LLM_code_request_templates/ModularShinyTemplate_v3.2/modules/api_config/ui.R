# modules/api_config/ui.R
# Complete API Configuration Module UI - BigQuery + Claude

api_config_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # BigQuery Configuration
    fluidRow(
      box(
        title = "BigQuery Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4(icon("database"), " Google BigQuery Setup"),
        p("Configure your BigQuery connection to access and store data."),
        
        fluidRow(
          column(6,
            fileInput(ns("bq_json"),
                     "Service Account JSON:",
                     accept = c(".json"),
                     buttonLabel = "Browse...",
                     placeholder = "No file selected"),
            
            textInput(ns("bq_project_id"),
                     "Project ID:",
                     placeholder = "your-gcp-project-id"),
            
            textInput(ns("bq_dataset_id"),
                     "Dataset ID:",
                     placeholder = "your_dataset"),
            
            textInput(ns("bq_table_id"),
                     "Table ID:",
                     placeholder = "your_table")
          ),
          column(6,
            div(class = "alert alert-info",
                style = "margin-top: 25px;",
                tags$strong(icon("info-circle"), " How to get credentials:"),
                tags$ol(
                  tags$li("Go to Google Cloud Console"),
                  tags$li("Create a service account"),
                  tags$li("Download JSON key file"),
                  tags$li("Enable BigQuery API"),
                  tags$li("Grant service account BigQuery permissions")
                ),
                tags$a(href = "https://cloud.google.com/bigquery/docs/authentication",
                      target = "_blank",
                      "Full documentation →"))
          )
        ),
        
        hr(),
        
        actionButton(ns("bq_authenticate"),
                    "Authenticate BigQuery",
                    class = "btn-success",
                    icon = icon("key")),
        
        actionButton(ns("bq_test"),
                    "Test BigQuery Connection",
                    class = "btn-info",
                    icon = icon("plug")),
        
        br(), br(),
        
        htmlOutput(ns("bq_status"))
      )
    ),
    
    # Claude API Configuration
    fluidRow(
      box(
        title = "Claude API Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4(icon("robot"), " Anthropic Claude API Setup"),
        p("Configure your Claude API connection for AI-powered features."),
        
        fluidRow(
          column(6,
            textInput(ns("claude_api_key"),
                     "Claude API Key:",
                     placeholder = "sk-ant-..."),
            
            selectInput(ns("claude_model"),
                       "Model:",
                       choices = c(
                         "Claude Sonnet 4" = "claude-sonnet-4-20250514",
                         "Claude Sonnet 3.5" = "claude-3-5-sonnet-20241022",
                         "Claude Opus 3" = "claude-3-opus-20240229",
                         "Claude Haiku 3.5" = "claude-3-5-haiku-20241022"
                       ),
                       selected = "claude-sonnet-4-20250514"),
            
            numericInput(ns("claude_timeout"),
                        "Request Timeout (seconds):",
                        value = 300,
                        min = 60,
                        max = 600,
                        step = 30),
            
            numericInput(ns("claude_max_tokens"),
                        "Max Tokens:",
                        value = 4096,
                        min = 1024,
                        max = 8192,
                        step = 1024)
          ),
          column(6,
            div(class = "alert alert-info",
                style = "margin-top: 25px;",
                tags$strong(icon("info-circle"), " Timeout Guide:"),
                tags$ul(
                  tags$li("Short requests: 60-120 seconds"),
                  tags$li("Medium requests: 180-300 seconds"),
                  tags$li("Long requests: 400-600 seconds")
                ),
                tags$hr(),
                tags$strong(icon("key"), " Get API Key:"),
                tags$br(),
                tags$a(href = "https://console.anthropic.com/",
                      target = "_blank",
                      "Anthropic Console →"))
          )
        ),
        
        hr(),
        
        actionButton(ns("claude_save"),
                    "Save Claude Configuration",
                    class = "btn-success",
                    icon = icon("save")),
        
        actionButton(ns("claude_test"),
                    "Test Claude Connection",
                    class = "btn-info",
                    icon = icon("plug")),
        
        br(), br(),
        
        htmlOutput(ns("claude_status"))
      )
    ),
    
    # Overall Configuration Status
    fluidRow(
      box(
        title = "Configuration Summary",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        
        htmlOutput(ns("config_summary"))
      )
    )
  )
}
