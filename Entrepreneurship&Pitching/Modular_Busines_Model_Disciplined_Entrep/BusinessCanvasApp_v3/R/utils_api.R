# API Manager R6 Class
library(R6)
library(httr)
library(jsonlite)

APIManager <- R6Class(
  "APIManager",
  public = list(
    claude_connected = FALSE,
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-20250514",
    claude_max_tokens = 4000,
    claude_timeout = 180,
    bq_authenticated = FALSE,
    bq_project_id = NULL,
    bq_dataset_id = NULL,
    bq_table_id = NULL,
    bq_full_table_id = NULL,
    bq_temp_file_path = NULL,
    bq_auth_trigger = NULL,  # REACTIVE VALUE FOR TRIGGERING UPDATES
    
    initialize = function() {
      cat("🔌 API Manager initialized\n")
      # Initialize reactive trigger
      self$bq_auth_trigger <- shiny::reactiveVal(0)
    },
    
    set_claude_credentials = function(api_key, max_tokens = 4000, timeout_seconds = 180) {
      self$claude_api_key <- api_key
      self$claude_max_tokens <- max_tokens
      self$claude_timeout <- timeout_seconds
      self$claude_connected <- TRUE
    },
    
    call_claude = function(prompt, max_tokens = NULL) {
      if (!self$claude_connected) stop("Claude API not connected")
      
      tokens_to_use <- if (!is.null(max_tokens)) max_tokens else self$claude_max_tokens
      
      response <- httr::POST(
        url = "https://api.anthropic.com/v1/messages",
        httr::add_headers(
          "x-api-key" = self$claude_api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = self$claude_model,
          max_tokens = tokens_to_use,
          messages = list(list(role = "user", content = prompt))
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(self$claude_timeout)
      )
      
      if (httr::status_code(response) != 200) {
        stop("API request failed: ", httr::content(response, "text"))
      }
      
      result <- httr::content(response, "parsed")
      return(result$content[[1]]$text)
    },
    
    set_bigquery_project = function(project_id, dataset_id, table_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$bq_table_id <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
    },
    
    set_bigquery_credentials_text = function(json_text, temp_file_path) {
      self$bq_temp_file_path <- temp_file_path
    },
    
    # CRITICAL: TRIGGER AUTH UPDATE - INCREMENTS REACTIVE VALUE
    trigger_auth_update = function() {
      current_value <- self$bq_auth_trigger()
      self$bq_auth_trigger(current_value + 1)
      cat("🔔 BigQuery auth trigger updated:", current_value + 1, "\n")
    },
    
    cleanup = function() {
      if (!is.null(self$bq_temp_file_path) && file.exists(self$bq_temp_file_path)) {
        unlink(self$bq_temp_file_path)
      }
    }
  )
)
