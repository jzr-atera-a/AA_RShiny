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
    claude_model = "claude-sonnet-4-6",
    claude_max_tokens = 16000,
    claude_timeout = 300,  # 5 minutes default timeout
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
    
    # ⭐ Cross-module data handoff: lets generate_summary push text into
    # bulk_import's textarea without either module knowing about the other's
    # internals. bulk_import observes this value and updates its own input
    # when it changes.
    pending_bulk_text = NULL,
    
    # Initialize
    initialize = function() {
      # Initialize reactive trigger - MUST be inside a reactive context
      self$state_trigger <- shiny::reactiveVal(0)
      self$pending_bulk_text <- shiny::reactiveVal("")
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
    
    # Push generated summary text to the Bulk Import module
    set_pending_bulk_text = function(text) {
      self$pending_bulk_text(text)
    },
    
    # ============================================================
    # CLAUDE API METHODS
    # ============================================================
    
    # Set Claude credentials
    set_claude_credentials = function(api_key, model = NULL, max_tokens = NULL, timeout = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model)) self$claude_model <- model
      if (!is.null(max_tokens)) self$claude_max_tokens <- max_tokens
      if (!is.null(timeout)) self$claude_timeout <- timeout
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
          status <- status_code(response)
          
          error_content <- tryCatch({
            content(response, "parsed", encoding = "UTF-8")
          }, error = function(e) {
            content(response, "text", encoding = "UTF-8")
          })
          
          cat("❌ [test_claude_connection] Non-200 response body:\n")
          cat("   ", utils::capture.output(str(error_content)), sep = "\n   ")
          
          detail <- if (is.list(error_content) && !is.null(error_content$error$message)) {
            error_content$error$message
          } else if (is.character(error_content)) {
            error_content
          } else {
            "(no error detail in response body)"
          }
          
          stop(sprintf("Status code: %d - %s", status, detail))
        }
      }, error = function(e) {
        self$claude_authenticated <- FALSE
        stop(paste("Connection failed:", e$message))
      })
    },
    
    # Call Claude API with comprehensive error handling
    call_claude = function(prompt, max_tokens = NULL, progress_callback = NULL) {
      cat("🔧 [APIManager$call_claude] Entered. claude_authenticated =", self$claude_authenticated, "\n")
      
      if (!self$claude_authenticated) {
        stop("Not authenticated to Claude API. Please save credentials first.")
      }
      
      if (is.null(self$claude_api_key) || nchar(self$claude_api_key) == 0) {
        stop("Claude API key is empty. Please configure credentials.")
      }
      
      tokens <- max_tokens %||% self$claude_max_tokens
      cat("🔧 [APIManager$call_claude] model =", self$claude_model,
          "| max_tokens =", tokens,
          "| timeout =", self$claude_timeout, "seconds\n")
      
      # Notify progress
      if (!is.null(progress_callback)) {
        progress_callback("Connecting to Claude API...")
      }
      
      tryCatch({
        cat("🔧 [APIManager$call_claude] Sending POST to https://api.anthropic.com/v1/messages ...\n")
        
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
          timeout(self$claude_timeout)  # Use configurable timeout
        )
        
        cat("🔧 [APIManager$call_claude] POST returned. HTTP status =", status_code(response), "\n")
        
        # Check for timeout specifically
        if (inherits(response, "error")) {
          stop("Request timeout - increase timeout setting in Claude API Config")
        }
        
        # Notify progress
        if (!is.null(progress_callback)) {
          progress_callback("Receiving response from Claude...")
        }
        
        status <- status_code(response)
        
        if (status != 200) {
          error_content <- tryCatch({
            content(response, "parsed", encoding = "UTF-8")
          }, error = function(e) {
            content(response, "text", encoding = "UTF-8")
          })
          
          cat("❌ [APIManager$call_claude] Non-200 response body:\n")
          cat("   ", utils::capture.output(str(error_content)), sep = "\n   ")
          
          error_msg <- if (is.list(error_content) && !is.null(error_content$error)) {
            paste0("API Error (", status, "): ", error_content$error$message)
          } else if (is.character(error_content)) {
            paste0("API Error (", status, "): ", error_content)
          } else {
            paste0("API Error: HTTP ", status)
          }
          
          # Specific error messages for common issues
          if (status == 401) {
            error_msg <- "Authentication failed: Invalid API key. Please check your credentials."
          } else if (status == 429) {
            error_msg <- "Rate limit exceeded: Too many requests. Please wait and try again."
          } else if (status == 500) {
            error_msg <- "Claude API server error: Please try again in a few moments."
          } else if (status == 529) {
            error_msg <- "Claude API is overloaded: Please try again in a few moments."
          }
          
          stop(error_msg)
        }
        
        # Notify progress
        if (!is.null(progress_callback)) {
          progress_callback("Parsing response...")
        }
        
        result <- content(response, "parsed", encoding = "UTF-8")
        
        if (is.null(result$content) || length(result$content) == 0) {
          cat("❌ [APIManager$call_claude] Parsed response has no $content -",
              "the request succeeded (HTTP 200) but the response body was unexpected.\n")
          stop("Claude API returned empty response. Please try again.")
        }
        
        # Notify completion
        if (!is.null(progress_callback)) {
          progress_callback("Complete!")
        }
        
        stop_reason <- result$stop_reason %||% "unknown"
        truncated <- identical(stop_reason, "max_tokens")
        
        cat("✅ [APIManager$call_claude] Success - stop_reason =", stop_reason,
            if (truncated) "(TRUNCATED - hit max_tokens limit!)" else "", "\n")
        
        return(list(
          text = result$content[[1]]$text,
          stop_reason = stop_reason,
          truncated = truncated
        ))
        
      }, error = function(e) {
        cat("❌ [APIManager$call_claude] Raw error before message rewrite:", e$message, "\n")
        
        # Enhanced error messages
        error_msg <- e$message
        
        if (grepl("Timeout", error_msg, ignore.case = TRUE) || 
            grepl("timeout", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Request timeout after ", self$claude_timeout, " seconds. ",
            "The request is taking longer than expected. ",
            "Try: (1) Increase timeout in Claude API Config, ",
            "(2) Reduce content length, or (3) Try again later."
          )
        } else if (grepl("peer", error_msg, ignore.case = TRUE) ||
                   grepl("SSL", error_msg, ignore.case = TRUE) ||
                   grepl("connection", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "Network connection error: ", error_msg, ". ",
            "This usually means: (1) Network connectivity issue, ",
            "(2) Firewall blocking the request, or ",
            "(3) Claude API temporary outage. Please check your connection and try again."
          )
        } else if (grepl("curl", error_msg, ignore.case = TRUE)) {
          error_msg <- paste0(
            "HTTP request error: ", error_msg, ". ",
            "Please check your internet connection and try again."
          )
        }
        
        stop(error_msg)
      })
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
    
    # Get distinct genre/topic/book/author combinations, used to build
    # the cascading Genre -> Topic -> Book dropdowns in generate_summary,
    # add_single, and visualizations.
    bq_get_taxonomy = function() {
      empty_result <- data.frame(genre = character(), topic = character(),
                                  book_name = character(), author = character(),
                                  stringsAsFactors = FALSE)
      
      if (!self$bq_authenticated) return(empty_result)
      
      query <- sprintf(
        "SELECT DISTINCT genre, topic, book_name, author FROM `%s` ORDER BY genre, topic, book_name",
        self$bq_full_table_id
      )
      
      tryCatch({
        self$bq_query(query)
      }, error = function(e) {
        cat("⚠️  [bq_get_taxonomy] Query failed:", e$message, "\n")
        empty_result
      })
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
