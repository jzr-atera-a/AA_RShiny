# ============================================================================
# API MANAGER - R6 CLASS
# ============================================================================
# 
# Manages OpenAI API connections for Whisper transcription and ChatGPT analysis
#
# ============================================================================

library(R6)
library(httr)
library(jsonlite)

APIManager <- R6Class(
  "APIManager",
  
  public = list(
    api_key = "",
    model = "whisper-1",
    language = "",
    
    # Initialize
    initialize = function() {
      message("✓ API Manager initialized")
    },
    
    # Set API credentials
    set_credentials = function(api_key, model = "whisper-1", language = "") {
      self$api_key <- trimws(api_key)
      self$model <- model
      self$language <- language
    },
    
    # Test OpenAI API connection
    test_connection = function() {
      tryCatch({
        url <- "https://api.openai.com/v1/models"
        
        response <- GET(
          url,
          add_headers(Authorization = paste("Bearer", self$api_key)),
          timeout(10)
        )
        
        status <- status_code(response)
        
        if (status == 200) {
          content_result <- content(response, "parsed")
          model_ids <- sapply(content_result$data, function(x) x$id)
          whisper_available <- any(grepl("whisper", model_ids, ignore.case = TRUE))
          
          return(list(
            success = TRUE,
            message = paste(
              "✓ API Connection Successful\n",
              "✓ Authentication Valid\n",
              "✓ Models Accessible:", length(model_ids), "models found\n",
              if(whisper_available) "✓ Whisper Models Available" else "⚠ Whisper Models Not Found"
            )
          ))
        } else if (status == 401) {
          return(list(
            success = FALSE,
            message = "✗ Authentication Failed\nInvalid API key."
          ))
        } else if (status == 429) {
          return(list(
            success = FALSE,
            message = "✗ Rate Limit Exceeded"
          ))
        } else {
          return(list(
            success = FALSE,
            message = paste("✗ Connection Failed\nHTTP Status:", status)
          ))
        }
      }, error = function(e) {
        return(list(
          success = FALSE,
          message = paste("✗ Connection Error\n", e$message)
        ))
      })
    },
    
    # Transcribe audio using Whisper API
    transcribe_audio = function(file_path, timeout_seconds = 180) {
      if (nchar(self$api_key) == 0) {
        stop("API key is required.")
      }
      
      if (!file.exists(file_path)) {
        stop("Audio file not found.")
      }
      
      url <- "https://api.openai.com/v1/audio/transcriptions"
      
      body <- list(
        file = upload_file(file_path),
        model = self$model
      )
      
      # Add language if specified
      if (nchar(self$language) > 0) {
        body$language <- self$language
      }
      
      response <- POST(
        url,
        add_headers(Authorization = paste("Bearer", self$api_key)),
        body = body,
        encode = "multipart",
        httr::timeout(timeout_seconds)
      )
      
      status <- status_code(response)
      
      if (status != 200) {
        error_content <- content(response, "text", encoding = "UTF-8")
        if (status == 401) {
          stop("Authentication failed. Check your API key.")
        } else if (status == 413) {
          stop("File too large. Maximum size is 25MB.")
        } else {
          stop(paste("API Error (Status", status, "):", error_content))
        }
      }
      
      content_result <- content(response, "parsed", encoding = "UTF-8")
      transcription_text <- content_result$text
      
      if (is.null(transcription_text) || length(transcription_text) == 0) {
        return("No speech detected in audio file.")
      }
      
      return(transcription_text)
    },
    
    # Analyze text using ChatGPT
    analyze_text = function(combined_text, max_words = 500, custom_prompt = "Summarize the following text:", timeout_seconds = 180) {
      if (nchar(self$api_key) == 0) {
        stop("API key is required.")
      }
      
      url <- "https://api.openai.com/v1/chat/completions"
      
      system_message <- paste0(
        "You are a helpful assistant that summarizes and analyzes text. ",
        "Provide a comprehensive summary limited to approximately ", max_words, " words."
      )
      
      user_message <- paste0(
        custom_prompt, "\n\n",
        "Text to analyze:\n\n",
        combined_text
      )
      
      body <- list(
        model = "gpt-4o-mini",
        messages = list(
          list(role = "system", content = system_message),
          list(role = "user", content = user_message)
        ),
        max_tokens = max_words * 2,
        temperature = 0.7
      )
      
      response <- POST(
        url,
        add_headers(
          Authorization = paste("Bearer", self$api_key),
          `Content-Type` = "application/json"
        ),
        body = toJSON(body, auto_unbox = TRUE),
        encode = "raw",
        httr::timeout(timeout_seconds)
      )
      
      status <- status_code(response)
      
      if (status != 200) {
        error_content <- content(response, "text", encoding = "UTF-8")
        if (status == 401) {
          stop("Authentication failed. Check your API key.")
        } else if (status == 429) {
          stop("Rate limit exceeded. Please wait and try again.")
        } else {
          stop(paste("API Error (Status", status, "):", error_content))
        }
      }
      
      content_result <- content(response, "parsed", encoding = "UTF-8")
      
      if (is.null(content_result$choices) || length(content_result$choices) == 0) {
        stop("No response from ChatGPT")
      }
      
      summary_text <- content_result$choices[[1]]$message$content
      return(summary_text)
    }
  )
)
