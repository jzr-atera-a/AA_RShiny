# R/utils_api.R - API Manager with Reactive Triggers
# Version 3.0 - COMPLETE

library(R6)
library(httr)

APIManager <- R6Class(
  "APIManager",
  public = list(
    # Authentication state
    authenticated = FALSE,
    
    # ⭐ Reactive trigger for cross-module communication
    state_trigger = NULL,
    
    # BigQuery fields
    bq_authenticated = FALSE,
    bq_project_id = NULL,
    bq_dataset_id = NULL,
    bq_table_id = NULL,
    bq_full_table_id = NULL,
    
    # External API fields (Claude, OpenAI, etc.)
    api_key = NULL,
    api_timeout = 300,
    
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
      cat("🔌 API Manager initialized with reactive trigger\n")
    },
    
    # ⭐ CRITICAL: Trigger all watching modules
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
      cat("🔔 State updated - notifying modules (", current + 1, ")\n")
    },
    
    # ==== BigQuery Methods ====
    
    set_bigquery_credentials = function(project_id, dataset_id, table_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$bq_table_id <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
    },
    
    authenticate_bigquery = function(json_path) {
      tryCatch({
        bigrquery::bq_auth(path = json_path, cache = FALSE)
        datasets <- bigrquery::bq_project_datasets(self$bq_project_id)
        
        self$bq_authenticated <- TRUE
        self$authenticated <- TRUE
        self$trigger_state_update()
        
        return(TRUE)
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },
    
    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      
      job <- bigrquery::bq_project_query(self$bq_project_id, query)
      return(bigrquery::bq_table_download(job))
    },
    
    bq_insert = function(data_frame, table_name = NULL) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      
      table_name <- table_name %||% self$bq_table_id
      table_ref <- bigrquery::bq_table(self$bq_project_id, self$bq_dataset_id, table_name)
      
      bigrquery::bq_table_upload(table_ref, data_frame, 
                                  fields = NULL, 
                                  write_disposition = "WRITE_APPEND")
      
      # ⭐ CRITICAL: Trigger refresh after write
      self$trigger_state_update()
      
      return(nrow(data_frame))
    },
    
    # ==== Claude API Methods ====
    
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-20250514",
    claude_timeout = 300,
    claude_max_tokens = 4096,
    
    set_claude_credentials = function(api_key, model = NULL, timeout = NULL, max_tokens = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model)) self$claude_model <- model
      if (!is.null(timeout)) self$claude_timeout <- timeout
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      self$authenticated <- TRUE
      self$trigger_state_update()
    },
    
    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL) {
      if (is.null(self$claude_api_key) || self$claude_api_key == "") {
        stop("Claude API key not set. Please configure in API Config tab.")
      }
      
      max_tokens_to_use <- max_tokens %||% self$claude_max_tokens
      
      if (!is.null(progress_callback)) {
        progress_callback("Connecting to Claude API...")
      }
      
      tryCatch({
        response <- httr::POST(
          url = "https://api.anthropic.com/v1/messages",
          httr::add_headers(
            "x-api-key" = self$claude_api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = jsonlite::toJSON(list(
            model = self$claude_model,
            max_tokens = max_tokens_to_use,
            messages = list(list(role = "user", content = prompt))
          ), auto_unbox = TRUE),
          encode = "json",
          timeout(self$claude_timeout)
        )
        
        if (httr::status_code(response) != 200) {
          error_msg <- paste("Claude API request failed with status", httr::status_code(response))
          
          if (httr::status_code(response) == 401) {
            error_msg <- paste0(error_msg, "\n\n💡 Try: Re-enter API credentials in API Config tab")
          } else if (httr::status_code(response) == 429) {
            error_msg <- paste0(error_msg, "\n\n💡 Try: Wait a few minutes (rate limit exceeded)")
          } else if (httr::status_code(response) == 400) {
            error_msg <- paste0(error_msg, "\n\n💡 Try: Check prompt format or reduce max_tokens")
          }
          
          stop(error_msg)
        }
        
        if (!is.null(progress_callback)) {
          progress_callback("Parsing Claude response...")
        }
        
        result <- httr::content(response, "parsed")
        
        if (!is.null(progress_callback)) {
          progress_callback("Complete!")
        }
        
        # Extract text from response
        if (!is.null(result$content) && length(result$content) > 0) {
          return(result$content[[1]]$text)
        } else {
          stop("Unexpected response format from Claude API")
        }
        
      }, error = function(e) {
        error_msg <- e$message
        
        if (grepl("timeout", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            error_msg,
            "\n\n💡 Try: Increase timeout in API Config (recommended: 400-600 seconds)"
          )
        } else if (grepl("network|peer|connection", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            error_msg,
            "\n\n💡 Try: Check internet connection, firewall, or try again"
          )
        }
        
        stop(error_msg)
      })
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
