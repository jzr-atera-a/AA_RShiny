# modules/bigquery_connection/ui.R
# BigQuery Connection Module UI

bigquery_connection_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "BigQuery Authentication", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 6,
        
        h4("Upload Service Account Key"),
        p("Please upload your Google Cloud service account JSON key file to authenticate with BigQuery."),
        
        fileInput(ns("jsonKey"), "Select JSON Key File:",
                  accept = c(".json"),
                  buttonLabel = "Browse...",
                  placeholder = "No file selected"),
        
        textInput(ns("projectId"), "Google Cloud Project ID:", 
                  value = "atera-2",
                  placeholder = "Enter your GCP project ID"),
        
        textInput(ns("datasetId"), "Dataset ID:", 
                  value = "EVs_Infrastructure",
                  placeholder = "Enter dataset ID"),
        
        textInput(ns("tableId"), "Table ID:", 
                  value = "Charge_Points_UK_EVs",
                  placeholder = "Enter table ID"),
        
        br(),
        
        actionButton(ns("testBQConnection"), "Test Connection", 
                     class = "btn-primary", width = "48%"),
        actionButton(ns("clearAuth"), "Clear Authentication", 
                     class = "btn-warning", width = "48%"),
        
        br(), br(),
        uiOutput(ns("bqConnectionStatus"))
      ),
      
      box(
        title = "Connection Information", 
        status = "info", 
        solidHeader = TRUE, 
        width = 6,
        
        h5("Setup Instructions:"),
        tags$ol(
          tags$li("Create a service account in Google Cloud Console"),
          tags$li("Download the JSON key file"),
          tags$li("Grant BigQuery Data Viewer role to the service account"),
          tags$li("Upload the JSON key file using the button above"),
          tags$li("Enter your project, dataset, and table information")
        ),
        
        br(),
        h5("Current Configuration:"),
        verbatimTextOutput(ns("bqConfigInfo")),
        
        br(),
        h5("Data Preview:"),
        verbatimTextOutput(ns("bqDataPreview"))
      )
    )
  )
}
