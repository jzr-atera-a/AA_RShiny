# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(jsonlite)
library(httr)

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
                  
                  h4("Service Account JSON Authentication"),
                  p("Use your working JSON credentials file:"),
                  
                  # Service Account JSON File
                  fileInput("json_file", 
                            "Upload Service Account JSON File:",
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
                               "Authenticate with JSON", 
                               class = "btn-primary btn-lg"),
                  
                  # Status Display
                  hr(),
                  h4("Connection Status"),
                  htmlOutput("auth_status")
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
                                placeholder = "SELECT \n  column1, \n  column2, \n  COUNT(*) as count\nFROM `project.dataset.table` \nGROUP BY column1, column2\nLIMIT 100;"),
                  
                  fluidRow(
                    column(4,
                           actionButton("run_query", 
                                        "Execute Query", 
                                        class = "btn-success btn-lg",
                                        icon = icon("play"))
                    ),
                    column(4,
                           actionButton("clear_query", 
                                        "Clear Query", 
                                        class = "btn-secondary",
                                        icon = icon("eraser"))
                    ),
                    column(4,
                           downloadButton("download_csv", 
                                          "Download CSV", 
                                          class = "btn-info")
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

# Helper function to execute BigQuery using service account
execute_bq_with_json <- function(project_id, query, json_path) {
  
  # Create temporary SQL file
  temp_sql <- tempfile(fileext = ".sql")
  writeLines(query, temp_sql)
  
  # Create temporary output file
  temp_output <- tempfile(fileext = ".csv")
  
  tryCatch({
    # Clear and set up clean authentication environment
    old_creds <- Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    old_config <- Sys.getenv("CLOUDSDK_CONFIG")
    
    Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = json_path)
    Sys.setenv(CLOUDSDK_CONFIG = "")
    
    # Activate service account first
    activate_cmd <- sprintf('gcloud auth activate-service-account --key-file=%s --quiet', 
                            shQuote(json_path))
    system(activate_cmd, ignore.stderr = TRUE)
    
    # Execute BigQuery command
    cmd <- sprintf(
      'bq query --use_legacy_sql=false --format=csv --max_rows=10000 --project_id=%s --quiet "%s"',
      shQuote(project_id),
      gsub('"', '\\"', gsub('\n', ' ', query))
    )
    
    # Execute the command
    output <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    
    # Restore original environment
    if (old_creds != "") {
      Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = old_creds)
    } else {
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
    }
    if (old_config != "") {
      Sys.setenv(CLOUDSDK_CONFIG = old_config)
    } else {
      Sys.unsetenv("CLOUDSDK_CONFIG")
    }
    
    if (length(output) > 0 && !any(grepl("ERROR", output))) {
      # Parse CSV output
      temp_csv <- tempfile(fileext = ".csv")
      writeLines(output, temp_csv)
      
      data <- tryCatch({
        read.csv(temp_csv, stringsAsFactors = FALSE)
      }, error = function(e) {
        # If CSV parsing fails, try to parse as simple data
        if (length(output) == 1 && output[1] != "") {
          data.frame(Result = output, stringsAsFactors = FALSE)
        } else {
          data.frame(Message = "Query executed but no readable data returned", stringsAsFactors = FALSE)
        }
      })
      
      unlink(temp_csv)
      return(data)
    } else {
      # Check for specific errors
      error_msg <- paste(output, collapse = " ")
      if (grepl("ERROR", error_msg)) {
        stop(error_msg)
      } else {
        stop("No data returned or command failed")
      }
    }
    
  }, error = function(e) {
    # Restore original environment on error
    if (exists("old_creds") && old_creds != "") {
      Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = old_creds)
    } else {
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
    }
    if (exists("old_config") && old_config != "") {
      Sys.setenv(CLOUDSDK_CONFIG = old_config)
    } else {
      Sys.unsetenv("CLOUDSDK_CONFIG")
    }
    
    unlink(c(temp_sql, temp_output))
    stop(paste("BigQuery execution failed:", e$message))
  })
}

# Test BigQuery connection with detailed error reporting
test_bq_connection <- function(project_id, json_path) {
  tryCatch({
    # Clear any existing gcloud authentication to force service account usage
    old_creds <- Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    old_config <- Sys.getenv("CLOUDSDK_CONFIG")
    
    # Set up clean environment for service account
    Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = json_path)
    # Clear gcloud config to prevent conflicts
    Sys.setenv(CLOUDSDK_CONFIG = "")
    
    # Test with explicit service account authentication
    # First, try to activate the service account explicitly
    activate_cmd <- sprintf('gcloud auth activate-service-account --key-file=%s --quiet', 
                            shQuote(json_path))
    
    activate_result <- tryCatch({
      system2("gcloud", args = c("auth", "activate-service-account", 
                                 paste0("--key-file=", json_path), "--quiet"), 
              stdout = TRUE, stderr = TRUE)
    }, error = function(e) {
      return(list(error = paste("Service account activation failed:", e$message)))
    })
    
    # Now test BigQuery access with the activated service account
    result <- tryCatch({
      system2("bq", args = c("ls", paste0("--project_id=", project_id), "--max_results=1"), 
              stdout = TRUE, stderr = TRUE)
    }, error = function(e) {
      return(list(error = paste("Command execution error:", e$message)))
    })
    
    # Restore original environment
    if (old_creds != "") {
      Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = old_creds)
    } else {
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
    }
    if (old_config != "") {
      Sys.setenv(CLOUDSDK_CONFIG = old_config)
    } else {
      Sys.unsetenv("CLOUDSDK_CONFIG")
    }
    
    # Check activation result first
    if (is.list(activate_result) && !is.null(activate_result$error)) {
      return(list(success = FALSE, error = activate_result$error))
    }
    
    # Check bq command results
    if (is.list(result) && !is.null(result$error)) {
      return(list(success = FALSE, error = result$error))
    } else if (length(result) > 0) {
      # Check for errors in output
      error_lines <- result[grepl("ERROR|Error|error|FAILED|Failed|failed|invalid_grant", result)]
      if (length(error_lines) > 0) {
        return(list(success = FALSE, error = paste(error_lines, collapse = "\n")))
      } else {
        return(list(success = TRUE, message = "Connection successful"))
      }
    } else {
      return(list(success = FALSE, error = "No output from bq command"))
    }
    
  }, error = function(e) {
    # Restore original environment on error
    if (exists("old_creds") && old_creds != "") {
      Sys.setenv(GOOGLE_APPLICATION_CREDENTIALS = old_creds)
    } else {
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
    }
    if (exists("old_config") && old_config != "") {
      Sys.setenv(CLOUDSDK_CONFIG = old_config)
    } else {
      Sys.unsetenv("CLOUDSDK_CONFIG")
    }
    return(list(success = FALSE, error = paste("Connection test failed:", e$message)))
  })
}

# Check if bq CLI is available
check_bq_cli <- function() {
  result <- tryCatch({
    system("bq version", intern = TRUE, ignore.stderr = TRUE)
  }, error = function(e) {
    return(NULL)
  })
  
  return(!is.null(result) && length(result) > 0)
}

# Define Server Logic
server <- function(input, output, session) {
  
  values <- reactiveValues(
    authenticated = FALSE,
    project_id = NULL,
    query_results = NULL,
    json_path = NULL
  )
  
  # Authentication
  observeEvent(input$authenticate, {
    
    if (is.null(input$project_id) || trimws(input$project_id) == "") {
      output$auth_status <- renderUI({
        tags$div(class = "status-error", 
                 tags$i(class = "fa fa-times-circle"), 
                 " Error: Please provide a Project ID")
      })
      return()
    }
    
    # Check if bq CLI is available
    if (!check_bq_cli()) {
      output$auth_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Error: Google Cloud SDK 'bq' command not found.",
                 tags$br(),
                 "Please install Google Cloud SDK: https://cloud.google.com/sdk/docs/install")
      })
      return()
    }
    
    json_path <- NULL
    
    # Get JSON credentials
    if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
      json_path <- input$json_file$datapath
    } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
      # Create temporary file from pasted JSON
      temp_json <- tempfile(fileext = ".json")
      writeLines(input$json_text, temp_json)
      json_path <- temp_json
    } else {
      output$auth_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Error: Please provide JSON credentials")
      })
      return()
    }
    
    # Validate JSON format
    tryCatch({
      json_content <- fromJSON(json_path)
      required_fields <- c("type", "project_id", "private_key", "client_email")
      missing_fields <- setdiff(required_fields, names(json_content))
      if (length(missing_fields) > 0) {
        stop(paste("Missing required fields:", paste(missing_fields, collapse = ", ")))
      }
    }, error = function(e) {
      output$auth_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Error: Invalid JSON format - ", e$message)
      })
      return()
    })
    
    values$project_id <- trimws(input$project_id)
    values$json_path <- json_path
    
    # Test connection
    output$auth_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Testing BigQuery connection...")
    })
    
    connection_result <- test_bq_connection(values$project_id, json_path)
    
    if (connection_result$success) {
      values$authenticated <- TRUE
      output$auth_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"), 
                 " Successfully authenticated with BigQuery!",
                 tags$br(),
                 tags$small("Project ID: ", values$project_id),
                 tags$br(),
                 tags$small("Using service account credentials"))
      })
    } else {
      values$authenticated <- FALSE
      output$auth_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Authentication failed:",
                 tags$br(),
                 tags$small("Error details: ", connection_result$error),
                 tags$br(),
                 tags$br(),
                 "Please check:",
                 tags$br(),
                 "• JSON file is valid service account key",
                 tags$br(), 
                 "• Project ID is correct",
                 tags$br(),
                 "• Service account has BigQuery permissions",
                 tags$br(),
                 "• Google Cloud SDK is properly installed")
      })
    }
  })
  
  # Clear query
  observeEvent(input$clear_query, {
    updateTextAreaInput(session, "sql_query", value = "")
  })
  
  # Execute query
  observeEvent(input$run_query, {
    
    if (!values$authenticated) {
      output$query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"), 
                 " Please authenticate first")
      })
      return()
    }
    
    if (is.null(input$sql_query) || trimws(input$sql_query) == "") {
      output$query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"), 
                 " Please enter a SQL query")
      })
      return()
    }
    
    output$query_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Executing query...")
    })
    
    tryCatch({
      result_data <- execute_bq_with_json(values$project_id, input$sql_query, values$json_path)
      values$query_results <- result_data
      
      output$query_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"), 
                 " Query executed successfully!")
      })
      
    }, error = function(e) {
      output$query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Query failed: ", e$message)
      })
      values$query_results <- NULL
    })
  })
  
  # Results info
  output$results_info <- renderUI({
    if (!is.null(values$query_results)) {
      tags$p(
        tags$strong("Results: "), 
        nrow(values$query_results), " rows × ", 
        ncol(values$query_results), " columns"
      )
    }
  })
  
  # Results table
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
          lengthMenu = c(10, 25, 50, 100)
        ),
        class = 'cell-border stripe hover compact',
        rownames = FALSE
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
  
  # Clean up temporary files
  session$onSessionEnded(function() {
    if (!is.null(values$json_path) && grepl("tmp", values$json_path)) {
      if (file.exists(values$json_path)) {
        unlink(values$json_path)
      }
    }
  })
}

shinyApp(ui = ui, server = server)