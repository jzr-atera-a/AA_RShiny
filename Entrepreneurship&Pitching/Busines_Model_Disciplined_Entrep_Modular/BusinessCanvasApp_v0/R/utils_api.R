# R/utils_api.R
# R6 Class for API management (Claude and BigQuery)

library(R6)
library(httr)
library(jsonlite)

APIManager <- R6::R6Class(
  "APIManager",
  
  public = list(
    # API credentials storage
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-20250514",
    claude_connected = FALSE,
    
    # BigQuery credentials
    bq_authenticated = FALSE,
    bq_project_id = NULL,
    bq_dataset_id = NULL,
    bq_table_id = NULL,
    bq_full_table_id = NULL,
    bq_temp_file_path = NULL,
    
    # Initialize
    initialize = function() {
      cat("🔌 API Manager initialized\n")
    },
    
    # ===== CLAUDE API METHODS =====
    
    # Test Claude connection
    test_claude_connection = function(api_key) {
      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key" = api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = toJSON(list(
            model = self$claude_model,
            max_tokens = 10,
            messages = list(list(
              role = "user",
              content = "Hi"
            ))
          ), auto_unbox = TRUE),
          encode = "json"
        )
        
        return(status_code(response) == 200)
      }, error = function(e) {
        return(FALSE)
      })
    },
    
    # Set Claude credentials
    set_claude_credentials = function(api_key, model = "claude-sonnet-4-20250514") {
      if (self$test_claude_connection(api_key)) {
        self$claude_api_key <- api_key
        self$claude_model <- model
        self$claude_connected <- TRUE
        return(TRUE)
      } else {
        self$claude_connected <- FALSE
        return(FALSE)
      }
    },
    
    # Call Claude API
    call_claude = function(prompt, max_tokens = 4000) {
      if (!self$claude_connected) {
        stop("Claude API not connected. Please connect first.")
      }
      
      response <- POST(
        url = "https://api.anthropic.com/v1/messages",
        add_headers(
          "x-api-key" = self$claude_api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = toJSON(list(
          model = self$claude_model,
          max_tokens = max_tokens,
          messages = list(list(
            role = "user",
            content = prompt
          ))
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(120)
      )
      
      if (status_code(response) != 200) {
        stop("API request failed: ", content(response, "text"))
      }
      
      result <- content(response, "parsed")
      return(result$content[[1]]$text)
    },
    
    # Clear Claude credentials
    clear_claude_credentials = function() {
      self$claude_api_key <- NULL
      self$claude_connected <- FALSE
    },
    
    # ===== BIGQUERY METHODS =====
    
    # Test BigQuery connection
    test_bigquery_connection = function(project_id) {
      tryCatch({
        datasets <- bigrquery::bq_project_datasets(project_id)
        return(TRUE)
      }, error = function(e) {
        return(FALSE)
      })
    },
    
    # Set BigQuery credentials (from JSON file)
    set_bigquery_credentials_file = function(json_file_path, project_id, dataset_id, table_id) {
      tryCatch({
        # Clear existing auth
        bigrquery::bq_deauth()
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")
        
        # Validate JSON
        json_content <- jsonlite::fromJSON(json_file_path)
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        # Authenticate
        bigrquery::bq_auth(path = json_file_path, cache = FALSE)
        
        # Test connection
        if (self$test_bigquery_connection(project_id)) {
          self$bq_authenticated <- TRUE
          self$bq_project_id <- project_id
          self$bq_dataset_id <- dataset_id
          self$bq_table_id <- table_id
          self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
          
          return(TRUE)
        } else {
          stop("Connection test failed")
        }
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(e$message)
      })
    },
    
    # Set BigQuery credentials (from JSON text)
    set_bigquery_credentials_text = function(json_text, project_id, dataset_id, table_id) {
      tryCatch({
        # Clear existing auth
        bigrquery::bq_deauth()
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")
        
        # Validate JSON
        json_content <- jsonlite::fromJSON(json_text)
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        # Write to temp file
        temp_file <- tempfile(fileext = ".json")
        writeLines(json_text, temp_file)
        self$bq_temp_file_path <- temp_file
        
        # Authenticate
        bigrquery::bq_auth(path = temp_file, cache = FALSE)
        
        # Test connection
        if (self$test_bigquery_connection(project_id)) {
          self$bq_authenticated <- TRUE
          self$bq_project_id <- project_id
          self$bq_dataset_id <- dataset_id
          self$bq_table_id <- table_id
          self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
          
          return(TRUE)
        } else {
          stop("Connection test failed")
        }
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(e$message)
      })
    },
    
    # Query BigQuery
    query_bigquery = function(query) {
      if (!self$bq_authenticated) {
        stop("BigQuery not authenticated")
      }
      
      job <- bigrquery::bq_project_query(self$bq_project_id, query)
      result <- bigrquery::bq_table_download(job)
      return(result)
    },
    
    # Clear BigQuery credentials
    clear_bigquery_credentials = function() {
      self$bq_authenticated <- FALSE
      self$bq_project_id <- NULL
      self$bq_dataset_id <- NULL
      self$bq_table_id <- NULL
      self$bq_full_table_id <- NULL
      
      if (!is.null(self$bq_temp_file_path) && file.exists(self$bq_temp_file_path)) {
        unlink(self$bq_temp_file_path)
        self$bq_temp_file_path <- NULL
      }
    },
    
    # Clear all credentials
    clear_all_credentials = function() {
      self$clear_claude_credentials()
      self$clear_bigquery_credentials()
    },
    
    # Cleanup on destruction
    finalize = function() {
      self$clear_all_credentials()
    }
  )
)

cat("✔ API Manager class loaded\n")
