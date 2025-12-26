# API Manager R6 Class
library(R6)
library(httr)

APIManager <- R6Class(
  "APIManager",
  public = list(
    claude_connected = FALSE,
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-20250514",
    bq_authenticated = FALSE,
    bq_project_id = NULL,
    bq_dataset_id = NULL,
    bq_table_id = NULL,
    bq_full_table_id = NULL,
    bq_temp_file_path = NULL,
    
    initialize = function() {
      cat("🔌 API Manager initialized\n")
    },
    
    set_claude_credentials = function(api_key) {
      self$claude_api_key <- api_key
      self$claude_connected <- TRUE
    },
    
    call_claude = function(prompt, max_tokens = 4000) {
      if (!self$claude_connected) stop("Claude API not connected")
      
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
          messages = list(list(role = "user", content = prompt))
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
    
    set_bigquery_credentials_text = function(json_text, temp_file) {
      self$bq_temp_file_path <- temp_file
    },
    
    set_bigquery_project = function(project_id, dataset_id, table_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$bq_table_id <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
      self$bq_authenticated <- TRUE
    },
    
    cleanup = function() {
      if (!is.null(self$bq_temp_file_path) && file.exists(self$bq_temp_file_path)) {
        unlink(self$bq_temp_file_path)
      }
    }
  )
)
