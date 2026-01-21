# ============================================================================
# API UTILITIES - COMPLETE FIX v2
# CRITICAL FIX: Properly handle BOTH timeout and connecttimeout
# ============================================================================

APIManager <- R6::R6Class(
  "APIManager",
  public = list(
    whisper_api_key = NULL,
    chatgpt_api_key = NULL,
    chatgpt_model = "gpt-4o-mini",
    chatgpt_temperature = 0.7,
    chatgpt_max_tokens = 2000,
    whisper_language = "",
    transcriptions = NULL,
    
    initialize = function() {
      self$whisper_api_key <- ""
      self$chatgpt_api_key <- ""
      self$transcriptions <- data.frame(
        timestamp = character(),
        filename = character(),
        word_count = numeric(),
        processing_time = numeric(),
        file_size = numeric(),
        stringsAsFactors = FALSE
      )
      cat("✓ API Manager initialized\n")
    },
    
    set_whisper_key = function(key) {
      self$whisper_api_key <- trimws(key)
    },
    
    set_chatgpt_key = function(key) {
      self$chatgpt_api_key <- trimws(key)
    },
    
    set_chatgpt_config = function(model = NULL, temperature = NULL, max_tokens = NULL) {
      if (!is.null(model)) self$chatgpt_model <- model
      if (!is.null(temperature)) self$chatgpt_temperature <- temperature
      if (!is.null(max_tokens)) self$chatgpt_max_tokens <- max_tokens
    },
    
    test_connection = function(api_key) {
      tryCatch({
        url <- "https://api.openai.com/v1/models"
        response <- httr::GET(
          url, 
          httr::add_headers(Authorization = paste("Bearer", api_key)), 
          httr::timeout(10)
        )
        status <- httr::status_code(response)
        
        if (status == 200) {
          return(list(success = TRUE, message = "✓ API Connection Successful"))
        } else if (status == 401) {
          return(list(success = FALSE, message = "✗ Invalid API key"))
        } else {
          return(list(success = FALSE, message = paste("✗ HTTP", status)))
        }
      }, error = function(e) {
        return(list(success = FALSE, message = paste("✗ Error:", e$message)))
      })
    },
    
    # FIXED: Transcribe with BOTH timeout and connecttimeout
    transcribe_audio = function(file_path, use_timeout = FALSE, timeout_seconds = NULL) {
      if (nchar(trimws(self$whisper_api_key)) == 0) {
        stop("Whisper API key not set")
      }
      
      cat("🔧 Transcribe settings:\n")
      cat("   use_timeout:", use_timeout, "\n")
      cat("   timeout_seconds:", if(is.null(timeout_seconds)) "NULL" else timeout_seconds, "\n")
      flush.console()
      
      url <- "https://api.openai.com/v1/audio/transcriptions"
      body <- list(file = httr::upload_file(file_path), model = "whisper-1")
      
      if (!is.null(self$whisper_language) && nchar(self$whisper_language) > 0) {
        body$language <- self$whisper_language
      }
      
      # CRITICAL FIX: Set BOTH timeout and connecttimeout
      if (use_timeout && !is.null(timeout_seconds) && timeout_seconds > 0) {
        cat("   ⏱️  Using timeout:", timeout_seconds, "seconds\n")
        cat("   ⏱️  Connection timeout:", timeout_seconds, "seconds\n")
        flush.console()
        
        response <- httr::POST(
          url,
          httr::add_headers(Authorization = paste("Bearer", self$whisper_api_key)),
          body = body,
          encode = "multipart",
          httr::timeout(timeout_seconds),
          httr::config(connecttimeout = timeout_seconds)
        )
      } else {
        cat("   ♾️  No timeout - using 86400 seconds (24 hours)\n")
        cat("   ♾️  Connection timeout: 3600 seconds (1 hour)\n")
        flush.console()
        
        # Set very high timeouts to effectively disable them
        response <- httr::POST(
          url,
          httr::add_headers(Authorization = paste("Bearer", self$whisper_api_key)),
          body = body,
          encode = "multipart",
          httr::timeout(86400),        # 24 hours for total request
          httr::config(connecttimeout = 3600)  # 1 hour for SSL/TLS connection
        )
      }
      
      status <- httr::status_code(response)
      
      if (status != 200) {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        cat("   ❌ HTTP Status:", status, "\n")
        cat("   Error:", error_content, "\n")
        flush.console()
        
        if (status == 401) {
          stop("Authentication failed. Check your Whisper API key.")
        } else {
          stop(paste("API Error (Status", status, "):", error_content))
        }
      }
      
      content_result <- httr::content(response, "parsed", encoding = "UTF-8")
      
      if (is.null(content_result$text) || nchar(content_result$text) == 0) {
        cat("   ⚠ No speech detected\n")
        flush.console()
        return("No speech detected")
      }
      
      cat("   ✅ Transcription complete:", nchar(content_result$text), "characters\n")
      flush.console()
      
      return(content_result$text)
    },
    
    # FIXED: ChatGPT with BOTH timeout and connecttimeout
    chatgpt_complete = function(messages, use_timeout = FALSE, timeout_seconds = NULL) {
      if (nchar(trimws(self$chatgpt_api_key)) == 0) {
        stop("ChatGPT API key not set. Please configure in ChatGPT API Settings tab.")
      }
      
      cat("🔧 ChatGPT settings:\n")
      cat("   Model:", self$chatgpt_model, "\n")
      cat("   use_timeout:", use_timeout, "\n")
      cat("   timeout_seconds:", if(is.null(timeout_seconds)) "NULL" else timeout_seconds, "\n")
      flush.console()
      
      url <- "https://api.openai.com/v1/chat/completions"
      
      body <- list(
        model = self$chatgpt_model,
        messages = messages,
        max_tokens = self$chatgpt_max_tokens,
        temperature = self$chatgpt_temperature
      )
      
      json_body <- jsonlite::toJSON(body, auto_unbox = TRUE)
      
      cat("   Request size:", round(nchar(json_body)/1024, 1), "KB\n")
      flush.console()
      
      # CRITICAL FIX: Set BOTH timeout and connecttimeout
      if (use_timeout && !is.null(timeout_seconds) && timeout_seconds > 0) {
        cat("   ⏱️  Using timeout:", timeout_seconds, "seconds\n")
        cat("   ⏱️  Connection timeout:", timeout_seconds, "seconds\n")
        flush.console()
        
        response <- httr::POST(
          url,
          httr::add_headers(
            Authorization = paste("Bearer", self$chatgpt_api_key),
            `Content-Type` = "application/json"
          ),
          body = json_body,
          encode = "raw",
          httr::timeout(timeout_seconds),
          httr::config(connecttimeout = timeout_seconds)
        )
      } else {
        cat("   ♾️  No timeout - using 86400 seconds (24 hours)\n")
        cat("   ♾️  Connection timeout: 3600 seconds (1 hour)\n")
        flush.console()
        
        # Set very high timeouts to effectively disable them
        response <- httr::POST(
          url,
          httr::add_headers(
            Authorization = paste("Bearer", self$chatgpt_api_key),
            `Content-Type` = "application/json"
          ),
          body = json_body,
          encode = "raw",
          httr::timeout(86400),        # 24 hours for total request
          httr::config(connecttimeout = 3600)  # 1 hour for SSL/TLS connection
        )
      }
      
      cat("   📥 Response received\n")
      flush.console()
      
      status <- httr::status_code(response)
      
      if (status != 200) {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        cat("   ❌ HTTP Status:", status, "\n")
        cat("   Error:", error_content, "\n")
        flush.console()
        
        if (status == 401) {
          stop("Authentication failed. Check your ChatGPT API key in settings.")
        } else if (status == 429) {
          stop("Rate limit exceeded. Wait a few minutes and try again.")
        } else {
          stop(paste("API Error (Status", status, "):", error_content))
        }
      }
      
      content_result <- httr::content(response, "parsed", encoding = "UTF-8")
      
      if (is.null(content_result$choices) || length(content_result$choices) == 0) {
        cat("   ❌ No choices in response\n")
        flush.console()
        stop("No response content from ChatGPT")
      }
      
      summary_text <- content_result$choices[[1]]$message$content
      
      if (is.null(summary_text) || nchar(summary_text) == 0) {
        cat("   ❌ Empty response\n")
        flush.console()
        stop("Empty response from ChatGPT")
      }
      
      cat("   ✅ Summary extracted:", nchar(summary_text), "characters\n")
      flush.console()
      
      return(summary_text)
    }
  )
)