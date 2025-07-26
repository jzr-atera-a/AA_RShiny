# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(jsonlite)
library(bigrquery)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "BigQuery Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("GCP Authentication", tabName = "auth", icon = icon("key")),
      menuItem("Query Interface", tabName = "query", icon = icon("database"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .status-success {
          color: #28a745;
          font-weight: bold;
        }
        .status-error {
          color: #dc3545;
          font-weight: bold;
        }
        .status-info {
          color: #17a2b8;
          font-weight: bold;
        }
      "))
    ),
    
    tabItems(
      # First tab - GCP Authentication
      tabItem(tabName = "auth",
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
                      " This app uses bigrquery v1.4.0 for compatibility. Version managed via .Rprofile"),
                  
                  # Service Account JSON File
                  h5("Upload Service Account JSON File:"),
                  fileInput("json_file", 
                            "Select JSON File:",
                            accept = ".json",
                            width = "400px"),
                  
                  # Manual JSON Input (alternative)
                  h5("Or paste JSON content:"),
                  textAreaInput("json_text", 
                                "JSON Content:",
                                height = "150px",
                                width = "100%",
                                placeholder = "Paste your service account JSON here..."),
                  
                  # Project ID Input
                  h5("Google Cloud Project ID"),
                  textInput("project_id", 
                            "Project ID:",
                            placeholder = "your-gcp-project-id",
                            width = "400px"),
                  
                  # Authentication Button
                  br(),
                  actionButton("authenticate", 
                               "Connect to BigQuery", 
                               class = "btn-primary btn-lg"),
                  
                  # Status Display
                  hr(),
                  h4("Connection Status"),
                  htmlOutput("auth_status"),
                  
                  # Package Info
                  hr(),
                  h5("Package Information:"),
                  verbatimTextOutput("package_info")
                )
              )
      ),
      
      # Second tab - Query Interface
      tabItem(tabName = "query",
              fluidRow(
                box(
                  title = "SQL Query Editor", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h5("Enter your BigQuery SQL:"),
                  textAreaInput("sql_query", 
                                label = NULL,
                                height = "200px",
                                width = "100%",
                                placeholder = "SELECT \n  column1, \n  column2, \n  COUNT(*) as count\nFROM `project.dataset.table` \nGROUP BY column1, column2\nORDER BY count DESC\nLIMIT 100;"),
                  
                  fluidRow(
                    column(3,
                           actionButton("run_query", 
                                        "Execute Query", 
                                        class = "btn-success btn-lg",
                                        icon = icon("play"))
                    ),
                    column(3,
                           actionButton("clear_query", 
                                        "Clear Query", 
                                        class = "btn-secondary",
                                        icon = icon("eraser"))
                    ),
                    column(3,
                           downloadButton("download_csv", 
                                          "Download CSV", 
                                          class = "btn-info")
                    ),
                    column(3,
                           numericInput("max_rows", 
                                        "Max Rows:", 
                                        value = 1000, 
                                        min = 1, 
                                        max = 50000,
                                        step = 100)
                    )
                  ),
                  
                  br(),
                  htmlOutput("query_status")
                )
              ),
              
              fluidRow(
                box(
                  title = "Query Results", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  htmlOutput("results_info"),
                  br(),
                  DT::dataTableOutput("results_table")
                )
              )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  values <- reactiveValues(
    authenticated = FALSE,
    project_id = NULL,
    query_results = NULL,
    temp_file_path = NULL
  )
  
  # Display package information
  output$package_info <- renderText({
    paste0("bigrquery version: ", packageVersion("bigrquery"))
  })
  
  # Authentication
  observeEvent(input$authenticate, {
    
    tryCatch({
      # Validation
      if (is.null(input$project_id) || trimws(input$project_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Project ID")
        })
        return()
      }
      
      auth_successful <- FALSE
      auth_method <- ""
      
      # Method 1: JSON file upload
      if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
        
        # Validate JSON file
        json_content <- tryCatch({
          fromJSON(input$json_file$datapath)
        }, error = function(e) {
          stop("Invalid JSON file format: ", e$message)
        })
        
        # Check required fields
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        # Authenticate with bigrquery
        bq_auth(path = input$json_file$datapath)
        
        auth_successful <- TRUE
        auth_method <- "JSON file upload"
        
        # Method 2: Manual JSON input
      } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
        
        # Validate JSON format
        json_content <- tryCatch({
          fromJSON(input$json_text)
        }, error = function(e) {
          stop("Invalid JSON format in text input: ", e$message)
        })
        
        # Check required fields
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        # Create temporary file
        temp_file <- tempfile(fileext = ".json")
        writeLines(input$json_text, temp_file)
        values$temp_file_path <- temp_file
        
        # Authenticate with bigrquery
        bq_auth(path = temp_file)
        
        auth_successful <- TRUE
        auth_method <- "manual JSON input"
        
      } else {
        stop("Please provide authentication credentials using one of the available methods")
      }
      
      if (auth_successful) {
        values$project_id <- trimws(input$project_id)
        
        # Test the connection by trying to list datasets
        test_result <- tryCatch({
          datasets <- bq_project_datasets(values$project_id)
          TRUE
        }, error = function(e) {
          stop("Connection test failed: ", e$message)
        })
        
        if (test_result) {
          values$authenticated <- TRUE
          
          output$auth_status <- renderUI({
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"), 
                     paste(" Successfully authenticated via", auth_method),
                     br(),
                     tags$small("Project ID: ", values$project_id),
                     br(),
                     tags$small("Using bigrquery v", as.character(packageVersion("bigrquery"))))
          })
        }
      }
      
    }, error = function(e) {
      values$authenticated <- FALSE
      output$auth_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Authentication failed: ", 
                 tags$br(),
                 tags$small(e$message))
      })
    })
  })
  
  # Clear query functionality
  observeEvent(input$clear_query, {
    updateTextAreaInput(session, "sql_query", value = "")
  })
  
  # Query execution logic
  observeEvent(input$run_query, {
    
    # Check authentication
    if (!values$authenticated) {
      output$query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"), 
                 " Please authenticate first in the GCP Authentication tab")
      })
      return()
    }
    
    # Check if query is provided
    if (is.null(input$sql_query) || trimws(input$sql_query) == "") {
      output$query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"), 
                 " Please enter a SQL query")
      })
      return()
    }
    
    # Show loading status
    output$query_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Executing query... Please wait.")
    })
    
    tryCatch({
      # Execute BigQuery using bigrquery
      query_job <- bq_project_query(
        x = values$project_id,
        query = input$sql_query,
        use_legacy_sql = FALSE
      )
      
      # Download results with user-specified max_rows
      max_rows_value <- if(is.null(input$max_rows) || input$max_rows <= 0) 1000 else input$max_rows
      result_data <- bq_table_download(query_job, max_results = max_rows_value)
      values$query_results <- result_data
      
      # Success message
      output$query_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"), 
                 paste(" Query executed successfully! Retrieved", nrow(result_data), "rows."))
      })
      
    }, error = function(e) {
      output$query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Query failed: ",
                 tags$br(),
                 tags$small(e$message))
      })
      values$query_results <- NULL
    })
  })
  
  # Display results info
  output$results_info <- renderUI({
    if (!is.null(values$query_results)) {
      tags$p(
        tags$strong("Results: "), 
        nrow(values$query_results), " rows × ", 
        ncol(values$query_results), " columns",
        tags$br(),
        tags$small("Displaying up to ", input$max_rows, " rows")
      )
    }
  })
  
  # Display results table
  output$results_table <- DT::renderDataTable({
    if (!is.null(values$query_results)) {
      DT::datatable(
        values$query_results,
        options = list(
          scrollX = TRUE,
          scrollY = "400px",
          pageLength = 25,
          searching = TRUE,
          ordering = TRUE,
          lengthMenu = c(10, 25, 50, 100, -1),
          lengthChange = TRUE,
          info = TRUE,
          autoWidth = TRUE
        ),
        class = 'cell-border stripe hover compact',
        rownames = FALSE,
        filter = 'top'
      )
    }
  })
  
  # Download handler
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("bigquery_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      if (!is.null(values$query_results)) {
        write.csv(values$query_results, file, row.names = FALSE)
      }
    }
  )
  
  # Clean up temporary files when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$temp_file_path) && file.exists(values$temp_file_path)) {
      unlink(values$temp_file_path)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)