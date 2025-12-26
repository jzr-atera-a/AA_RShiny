# BigQuery Authentication Module - UI
# Handles GCP authentication via service account JSON

bigquery_auth_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication", 
        status = "primary", 
        solidHeader = TRUE,
        width = 12,
        
        h4("BigQuery Authentication"),
        p("Use your service account credentials to connect to BigQuery."),
        div(class = "alert alert-info",
            tags$strong("Note:"), 
            " This app clears default VM credentials to use your JSON file."),
        
        fluidRow(
          column(6,
                 h5("Upload Service Account JSON File:"),
                 fileInput(ns("json_file"), 
                           "Select JSON File:",
                           accept = ".json",
                           width = "100%"),
                 
                 h5("Or paste JSON content:"),
                 textAreaInput(ns("json_text"), 
                               "JSON Content:",
                               height = "150px",
                               width = "100%",
                               placeholder = "Paste your service account JSON here...")
          ),
          column(6,
                 h5("BigQuery Project Configuration"),
                 textInput(ns("project_id"), 
                           "Project ID:",
                           placeholder = "your-gcp-project-id",
                           value = "atera-2",
                           width = "100%"),
                 
                 textInput(ns("dataset_id"), 
                           "Dataset ID:",
                           placeholder = "your_dataset_id",
                           value = "business_strategy",
                           width = "100%"),
                 
                 textInput(ns("table_id"), 
                           "Table ID:",
                           placeholder = "table_name",
                           value = "business_model_canvas",
                           width = "100%"),
                 
                 p(style = "color: #7f8c8d; font-size: 12px;", 
                   "The table will be created automatically if it doesn't exist.")
          )
        ),
        
        br(),
        actionButton(ns("authenticate"), 
                     "Connect to BigQuery", 
                     class = "btn-primary btn-lg",
                     icon = icon("plug")),
        
        hr(),
        h4("Connection Status"),
        htmlOutput(ns("auth_status")),
        
        hr(),
        h5("Package Information:"),
        verbatimTextOutput(ns("package_info"))
      )
    )
  )
}
