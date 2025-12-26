# R/utils_api.R
# APIManager R6 Class - Manages Claude API and BigQuery connections
# Uses reactive triggers for cross-module state updates
# =================================================================

library(R6)
library(httr)
library(jsonlite)
library(bigrquery)

APIManager <- R6::R6Class(
  "APIManager",
  
  public = list(
    # Claude API credentials
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-20250514",
    claude_max_tokens = 16000,
    claude_authenticated = FALSE,
    
    # BigQuery credentials
    bq_project_id = "atera-2",
    bq_dataset_id = "Wonderfulp_March",
    bq_table_id = "book_summaries_test3",
    bq_full_table_id = NULL,
    bq_authenticated = FALSE,
    bq_temp_file = NULL,
    
    # ⭐ CRITICAL: Reactive trigger for cross-module updates
    state_trigger = NULL,
    
    # Initialize
    initialize = function() {
      # Initialize reactive trigger - MUST be inside a reactive context
      self$state_trigger <- shiny::reactiveVal(0)
      self$bq_full_table_id <- paste0(self$bq_project_id, ".", 
                                       self$bq_dataset_id, ".", 
                                       self$bq_table_id)
      cat("🔌 API Manager initialized with reactive trigger\n")
    },
    
    # Trigger state update - fires reactive observers in all modules
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
      cat("🔔 State trigger fired:", current + 1, "\n")
    },
    
    # ============================================================
    # CLAUDE API METHODS
    # ============================================================
    
    # Set Claude credentials
    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model)) self$claude_model <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
    },
    
    # Test Claude connection
    test_claude_connection = function() {
      if (is.null(self$claude_api_key)) {
        stop("Claude API key not set")
      }
      
      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key" = self$claude_api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = toJSON(list(
            model = self$claude_model,
            max_tokens = 100,
            messages = list(
              list(role = "user", content = "Hello, test message.")
            )
          ), auto_unbox = TRUE),
          encode = "json",
          config = httr::config(timeout = 60)
        )
        
        if (status_code(response) == 200) {
          self$claude_authenticated <- TRUE
          self$trigger_state_update()
          return(TRUE)
        } else {
          stop(paste("Status code:", status_code(response)))
        }
      }, error = function(e) {
        self$claude_authenticated <- FALSE
        stop(paste("Connection failed:", e$message))
      })
    },
    
    # Call Claude API
    call_claude = function(prompt, max_tokens = NULL) {
      if (!self$claude_authenticated) {
        stop("Not authenticated to Claude API")
      }
      
      tokens <- max_tokens %||% self$claude_max_tokens
      
      response <- POST(
        url = "https://api.anthropic.com/v1/messages",
        add_headers(
          "x-api-key" = self$claude_api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = toJSON(list(
          model = self$claude_model,
          max_tokens = tokens,
          messages = list(list(role = "user", content = prompt))
        ), auto_unbox = TRUE),
        encode = "json",
        config = httr::config(timeout = 180)
      )
      
      if (status_code(response) != 200) {
        stop("API request failed: ", content(response, "text"))
      }
      
      result <- content(response, "parsed")
      return(result$content[[1]]$text)
    },
    
    # ============================================================
    # BIGQUERY METHODS
    # ============================================================
    
    # Set BigQuery credentials
    set_bigquery_credentials = function(project_id, dataset_id, table_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$bq_table_id <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
    },
    
    # Authenticate BigQuery
    authenticate_bigquery = function(json_path = NULL, json_text = NULL) {
      tryCatch({
        # Clear existing auth
        tryCatch({ bq_deauth() }, error = function(e) {})
        Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
        Sys.unsetenv("GCE_METADATA_HOST")
        
        if (!is.null(json_path)) {
          # JSON file upload
          json_content <- fromJSON(json_path)
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing <- setdiff(required_fields, names(json_content))
          if (length(missing) > 0) {
            stop("Missing JSON fields: ", paste(missing, collapse = ", "))
          }
          bq_auth(path = json_path, cache = FALSE)
          
        } else if (!is.null(json_text)) {
          # JSON text paste
          json_content <- fromJSON(json_text)
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing <- setdiff(required_fields, names(json_content))
          if (length(missing) > 0) {
            stop("Missing JSON fields: ", paste(missing, collapse = ", "))
          }
          temp_file <- tempfile(fileext = ".json")
          writeLines(json_text, temp_file)
          self$bq_temp_file <- temp_file
          bq_auth(path = temp_file, cache = FALSE)
          
        } else {
          stop("Provide JSON file path or text")
        }
        
        # Test connection
        datasets <- bq_project_datasets(self$bq_project_id)
        
        # Create table if not exists
        create_table_query <- sprintf("
          CREATE TABLE IF NOT EXISTS `%s` (
            id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
            book_name STRING,
            author STRING,
            genre STRING,
            topic STRING,
            chapter STRING,
            section STRING,
            main_details STRING,
            formula STRING,
            formula_explanation STRING,
            reference_url STRING,
            reference_description STRING,
            numeric_data STRING,
            numeric_data_description STRING
          )", self$bq_full_table_id)
        
        tryCatch({
          bq_project_query(self$bq_project_id, create_table_query)
        }, error = function(e) {})
        
        self$bq_authenticated <- TRUE
        self$trigger_state_update()  # ⭐ TRIGGER ALL MODULES
        
        return(TRUE)
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },
    
    # Query BigQuery
    bq_query = function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      
      job <- bq_project_query(self$bq_project_id, query)
      return(bq_table_download(job))
    },
    
    # Insert data to BigQuery
    bq_insert = function(data_frame, table_name = NULL) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      
      # Get next ID
      max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", 
                              self$bq_full_table_id)
      
      start_id <- tryCatch({
        result <- bq_project_query(self$bq_project_id, max_id_query)
        max_id_data <- bq_table_download(result)
        as.integer(max_id_data$max_id) + 1
      }, error = function(e) { 1 })
      
      # Add ID and timestamp
      data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
      data_frame$created_at <- Sys.time()
      
      # Ensure all columns exist
      required_cols <- c("id", "created_at", "book_name", "author", "genre", "topic",
                        "chapter", "section", "main_details", 
                        "formula", "formula_explanation",
                        "reference_url", "reference_description",
                        "numeric_data", "numeric_data_description")
      
      for (col in required_cols) {
        if (!col %in% names(data_frame)) {
          data_frame[[col]] <- ""
        }
      }
      
      # Reorder columns
      data_frame <- data_frame[, required_cols]
      
      # Upload
      table_name <- table_name %||% self$bq_table_id
      table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, table_name)
      bq_table_upload(table_ref, data_frame, 
                     create_disposition = "CREATE_IF_NEEDED",
                     write_disposition = "WRITE_APPEND")
      
      return(nrow(data_frame))
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
