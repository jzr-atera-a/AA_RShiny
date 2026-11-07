# API Manager R6 Class
APIManager <- R6::R6Class(
  "APIManager",
  
  public = list(
    whisper_api_key = "",
    whisper_model = "whisper-1",
    whisper_language = "",
    chatgpt_api_key = "",
    chatgpt_model = "gpt-4o-mini",
    transcriptions = data.frame(
      timestamp = character(),
      filename = character(),
      word_count = numeric(),
      processing_time = numeric(),
      file_size = numeric(),
      stringsAsFactors = FALSE
    ),
    
    initialize = function() {
      invisible(self)
    },
    
    set_whisper_credentials = function(api_key, model = "whisper-1", language = "") {
      self$whisper_api_key <- api_key
      self$whisper_model <- model
      self$whisper_language <- language
      invisible(self)
    },
    
    set_chatgpt_credentials = function(api_key, model = "gpt-4o-mini") {
      self$chatgpt_api_key <- api_key
      self$chatgpt_model <- model
      invisible(self)
    },
    
    test_whisper_connection = function() {
      if (nchar(trimws(self$whisper_api_key)) == 0) {
        return(list(success = FALSE, message = "API key not set"))
      }
      
      tryCatch({
        url <- "https://api.openai.com/v1/models"
        response <- httr::GET(
          url,
          httr::add_headers(Authorization = paste("Bearer", self$whisper_api_key)),
          httr::timeout(10)
        )
        
        if (httr::status_code(response) == 200) {
          list(success = TRUE, message = "✓ API connection successful!")
        } else {
          list(success = FALSE, message = paste("✗ HTTP Error:", httr::status_code(response)))
        }
      }, error = function(e) {
        list(success = FALSE, message = paste("✗ Connection failed:", e$message))
      })
    },
    
    test_chatgpt_connection = function() {
      if (nchar(trimws(self$chatgpt_api_key)) == 0) {
        return(list(success = FALSE, message = "API key not set"))
      }
      
      tryCatch({
        url <- "https://api.openai.com/v1/models"
        response <- httr::GET(
          url,
          httr::add_headers(Authorization = paste("Bearer", self$chatgpt_api_key)),
          httr::timeout(10)
        )
        
        if (httr::status_code(response) == 200) {
          list(success = TRUE, message = "✓ API connection successful!")
        } else {
          list(success = FALSE, message = paste("✗ HTTP Error:", httr::status_code(response)))
        }
      }, error = function(e) {
        list(success = FALSE, message = paste("✗ Connection failed:", e$message))
      })
    },
    
    transcribe_audio = function(file_path, use_timeout = FALSE, timeout_seconds = NULL) {
      if (nchar(trimws(self$whisper_api_key)) == 0) {
        stop("Whisper API key not set")
      }
      
      file_size_mb <- file.size(file_path) / (1024^2)
      cat("🔧 Transcription request:\n")
      cat("   File size:", round(file_size_mb, 2), "MB\n")
      cat("   Use timeout:", use_timeout, "\n")
      cat("   Timeout:", if(is.null(timeout_seconds)) "NULL" else timeout_seconds, "seconds\n")
      flush.console()
      
      # OpenAI limit is 25MB
      if (file_size_mb > 25) {
        stop("File too large. OpenAI Whisper API limit is 25MB. Current file: ", 
             round(file_size_mb, 2), "MB")
      }
      
      url <- "https://api.openai.com/v1/audio/transcriptions"
      body <- list(file = httr::upload_file(file_path), model = "whisper-1")
      
      if (!is.null(self$whisper_language) && nchar(self$whisper_language) > 0) {
        body$language <- self$whisper_language
      }
      
      # ENHANCED: Retry logic with exponential backoff
      max_retries <- 3
      retry_count <- 0
      last_error <- NULL
      
      while (retry_count < max_retries) {
        tryCatch({
          cat("   🔄 Attempt", retry_count + 1, "of", max_retries, "\n")
          flush.console()
          
          # Set timeout based on file size and user preference
          if (use_timeout && !is.null(timeout_seconds) && timeout_seconds > 0) {
            actual_timeout <- timeout_seconds
          } else {
            # Auto-calculate timeout based on file size (30 sec per MB, min 60, max 600)
            actual_timeout <- max(60, min(600, ceiling(file_size_mb * 30)))
          }
          
          cat("   ⏱️  Timeout set to:", actual_timeout, "seconds\n")
          flush.console()
          
          response <- httr::POST(
            url,
            httr::add_headers(Authorization = paste("Bearer", self$whisper_api_key)),
            body = body,
            encode = "multipart",
            httr::timeout(actual_timeout),
            httr::config(
              connecttimeout = 60,  # 60 seconds for initial connection
              ssl_verifypeer = TRUE,
              http_version = 2  # Use HTTP/2 for better performance
            )
          )
          
          status <- httr::status_code(response)
          
          if (status == 200) {
            content <- httr::content(response, "parsed")
            transcription <- content$text
            cat("   ✅ Success:", nchar(transcription), "characters\n")
            flush.console()
            return(transcription)
          } else {
            error_content <- httr::content(response, "text", encoding = "UTF-8")
            error_msg <- paste("HTTP", status, ":", error_content)
            
            if (status == 401) {
              stop("❌ Authentication failed. Check your API key.")
            } else if (status == 413) {
              stop("❌ File too large for API (max 25MB)")
            } else if (status == 429) {
              cat("   ⚠️  Rate limit hit, waiting before retry...\n")
              Sys.sleep(2^retry_count)  # Exponential backoff
              retry_count <- retry_count + 1
              last_error <- error_msg
              next
            } else {
              stop(error_msg)
            }
          }
        }, error = function(e) {
          error_message <- e$message
          
          # Check for specific network errors
          if (grepl("Connection was reset|Timeout|timed out|peer|SSL", error_message, ignore.case = TRUE)) {
            cat("   ⚠️  Network error:", error_message, "\n")
            cat("   ⏳ Waiting", 2^retry_count, "seconds before retry...\n")
            flush.console()
            
            Sys.sleep(2^retry_count)  # Exponential backoff: 1s, 2s, 4s
            retry_count <- retry_count + 1
            last_error <- error_message
          } else {
            # Non-network error, fail immediately
            stop(error_message)
          }
        })
      }
      
      # If we get here, all retries failed
      stop("❌ Transcription failed after ", max_retries, " attempts. Last error: ", last_error)
    },
    
    analyze_text = function(text, max_words = 500, custom_prompt = NULL, timeout_seconds = NULL) {
      if (nchar(trimws(self$chatgpt_api_key)) == 0) {
        stop("ChatGPT API key not set")
      }
      
      # Prepare the prompt
      if (!is.null(custom_prompt) && nchar(trimws(custom_prompt)) > 0) {
        system_prompt <- custom_prompt
      } else {
        system_prompt <- paste0(
          "Summarize the following text in no more than ", max_words, 
          " words. Focus on the key points and main ideas."
        )
      }
      
      url <- "https://api.openai.com/v1/chat/completions"
      body <- list(
        model = self$chatgpt_model,
        messages = list(
          list(role = "system", content = system_prompt),
          list(role = "user", content = text)
        ),
        max_tokens = max_words * 2
      )
      
      timeout_val <- if (!is.null(timeout_seconds)) timeout_seconds else 180
      
      response <- httr::POST(
        url,
        httr::add_headers(
          Authorization = paste("Bearer", self$chatgpt_api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        encode = "raw",
        httr::timeout(timeout_val)
      )
      
      status <- httr::status_code(response)
      
      if (status != 200) {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        stop("API Error ", status, ": ", error_content)
      }
      
      content <- httr::content(response, "parsed")
      summary <- content$choices[[1]]$message$content
      
      return(summary)
    }
  )
)
