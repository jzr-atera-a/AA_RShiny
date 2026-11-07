# modules/API Settings/openai_base.R
# Shared OpenAI API base functions for Whisper and ChatGPT

# Utility: Calculate appropriate timeout based on file size
calculate_timeout <- function(file_size_mb, use_timeout = FALSE, timeout_seconds = NULL) {
  # If user specified a timeout and it's valid, use it
  if (use_timeout && !is.null(timeout_seconds) && is.numeric(timeout_seconds) && timeout_seconds > 0) {
    return(timeout_seconds)
  }

  # Otherwise, auto-calculate based on file size
  # Formula: 30 seconds per MB, min 60 seconds, max 600 seconds
  return(max(60, min(600, ceiling(file_size_mb * 30))))
}

# Utility: Categorize errors for retry logic
categorize_error <- function(error_message) {
  if (is.null(error_message)) return("unknown")

  error_lower <- tolower(error_message)

  if (grepl("timeout|timed out|connection reset|connection refused", error_lower)) {
    return("network")  # Retriable
  }
  if (grepl("429|rate limit", error_lower)) {
    return("rate_limit")  # Retriable with backoff
  }
  if (grepl("401|403|authentication|unauthorized|invalid", error_lower)) {
    return("auth")  # Not retriable
  }

  return("other")  # Unknown
}

# Utility: Exponential backoff calculation
exponential_backoff <- function(attempt_number) {
  # Returns delay in seconds: 1s, 2s, 4s, 8s...
  2^(attempt_number - 1)
}

# R6 Class: OpenAI API Manager
OpenAIAPIManager <- R6::R6Class(
  "OpenAIAPIManager",
  private = list(
    whisper_api_key = "",
    whisper_model = "whisper-1",
    whisper_language = "",
    chatgpt_api_key = "",
    chatgpt_model = "gpt-4o-mini",
    chatgpt_temperature = 0.7,
    chatgpt_max_tokens = 2000
  ),
  public = list(
    # Initialize
    initialize = function() {
      private$whisper_api_key <- ""
      private$whisper_model <- "whisper-1"
      private$whisper_language <- ""
      private$chatgpt_api_key <- ""
      private$chatgpt_model <- "gpt-4o-mini"
      private$chatgpt_temperature <- 0.7
      private$chatgpt_max_tokens <- 2000
    },

    # Whisper API Methods
    set_whisper_credentials = function(api_key, model = "whisper-1", language = "") {
      private$whisper_api_key <- trimws(api_key)
      private$whisper_model <- model
      private$whisper_language <- language
      cat(sprintf("[OpenAI] Whisper credentials updated\n"))
    },

    get_whisper_api_key = function() {
      return(private$whisper_api_key)
    },

    test_whisper_connection = function() {
      if (nchar(private$whisper_api_key) == 0) {
        return(list(success = FALSE, message = "❌ No Whisper API key configured"))
      }

      tryCatch({
        # Test with a simple HTTP request to OpenAI API
        response <- httr::HEAD(
          url = "https://api.openai.com/v1/models",
          httr::add_headers(Authorization = paste("Bearer", private$whisper_api_key)),
          httr::timeout(10),
          httr::config(ssl_verifypeer = TRUE)
        )

        if (httr::status_code(response) == 200) {
          return(list(success = TRUE, message = "✅ Whisper API connection successful"))
        } else {
          error_msg <- sprintf("HTTP %d: %s", httr::status_code(response), httr::http_status(response)$message)
          return(list(success = FALSE, message = paste("❌ Connection failed -", error_msg)))
        }
      }, error = function(e) {
        return(list(success = FALSE, message = paste("❌ Connection error:", e$message)))
      })
    },

    # ChatGPT API Methods
    set_chatgpt_credentials = function(api_key, model = "gpt-4o-mini", temperature = 0.7, max_tokens = 2000) {
      private$chatgpt_api_key <- trimws(api_key)
      private$chatgpt_model <- model
      private$chatgpt_temperature <- temperature
      private$chatgpt_max_tokens <- max_tokens
      cat(sprintf("[OpenAI] ChatGPT credentials updated\n"))
    },

    get_chatgpt_api_key = function() {
      return(private$chatgpt_api_key)
    },

    test_chatgpt_connection = function() {
      if (nchar(private$chatgpt_api_key) == 0) {
        return(list(success = FALSE, message = "❌ No ChatGPT API key configured"))
      }

      tryCatch({
        # Test with a simple HTTP request to OpenAI API
        response <- httr::HEAD(
          url = "https://api.openai.com/v1/models",
          httr::add_headers(Authorization = paste("Bearer", private$chatgpt_api_key)),
          httr::timeout(10),
          httr::config(ssl_verifypeer = TRUE)
        )

        if (httr::status_code(response) == 200) {
          return(list(success = TRUE, message = "✅ ChatGPT API connection successful"))
        } else {
          error_msg <- sprintf("HTTP %d: %s", httr::status_code(response), httr::http_status(response)$message)
          return(list(success = FALSE, message = paste("❌ Connection failed -", error_msg)))
        }
      }, error = function(e) {
        return(list(success = FALSE, message = paste("❌ Connection error:", e$message)))
      })
    },

    # Transcribe audio with retry logic and proper timeout
    transcribe_audio = function(file_path, use_timeout = FALSE, timeout_seconds = NULL, max_retries = 3) {
      if (nchar(private$whisper_api_key) == 0) {
        stop("Whisper API key not configured. Please configure it in API Settings > Whisper API Settings")
      }

      # Validate file exists
      if (!file.exists(file_path)) {
        stop(sprintf("File not found: %s", file_path))
      }

      # Get file size for timeout calculation
      file_size_mb <- file.size(file_path) / (1024^2)

      # Calculate timeout
      actual_timeout <- calculate_timeout(file_size_mb, use_timeout, timeout_seconds)

      cat(sprintf("[Whisper] Starting transcription: %s (%.2f MB, timeout: %d sec)\n",
                  basename(file_path), file_size_mb, actual_timeout))

      # Retry loop with exponential backoff
      for (attempt in 1:max_retries) {
        tryCatch({
          cat(sprintf("[Whisper] Attempt %d/%d\n", attempt, max_retries))

          # Make API call
          response <- httr::POST(
            url = "https://api.openai.com/v1/audio/transcriptions",
            httr::add_headers(Authorization = paste("Bearer", private$whisper_api_key)),
            body = list(
              file = httr::upload_file(file_path),
              model = private$whisper_model,
              language = if (nchar(private$whisper_language) > 0) private$whisper_language else NULL
            ),
            encode = "multipart",
            httr::timeout(actual_timeout),
            httr::config(
              connecttimeout = 60,
              ssl_verifypeer = TRUE,
              http_version = 2
            )
          )

          # Handle response
          status <- httr::status_code(response)

          if (status == 200) {
            # Success
            content <- httr::content(response, as = "text")
            result <- jsonlite::fromJSON(content)
            cat(sprintf("[Whisper] Transcription successful\n"))
            return(result$text)
          } else if (status == 429) {
            # Rate limited - retry with backoff
            wait_time <- exponential_backoff(attempt)
            cat(sprintf("[Whisper] Rate limited. Waiting %d seconds before retry...\n", wait_time))
            Sys.sleep(wait_time)
            next
          } else {
            # Other HTTP error
            error_detail <- httr::http_status(response)$message
            stop(sprintf("API Error (HTTP %d): %s", status, error_detail))
          }

        }, error = function(e) {
          error_msg <- e$message
          error_type <- categorize_error(error_msg)

          cat(sprintf("[Whisper] Error (Type: %s): %s\n", error_type, error_msg))

          # Network/timeout errors: retry with backoff
          if (error_type %in% c("network", "rate_limit") && attempt < max_retries) {
            wait_time <- exponential_backoff(attempt)
            cat(sprintf("[Whisper] Retriable error. Waiting %d seconds...\n", wait_time))
            Sys.sleep(wait_time)
            # Continue to next attempt
          } else if (attempt == max_retries) {
            # Max retries exceeded
            stop(sprintf("Transcription failed after %d attempts: %s", max_retries, error_msg))
          } else {
            # Fatal error
            stop(sprintf("Transcription failed (not retriable): %s", error_msg))
          }
        })
      }

      stop("Transcription failed: max retries exceeded")
    },

    # Analyze text with ChatGPT with retry logic
    analyze_text = function(text, prompt = NULL, use_timeout = FALSE, timeout_seconds = NULL, max_retries = 3) {
      if (nchar(private$chatgpt_api_key) == 0) {
        stop("ChatGPT API key not configured. Please configure it in API Settings > ChatGPT API Settings")
      }

      # Calculate timeout (estimate: 100 words = 10 seconds)
      word_count <- length(strsplit(trimws(text), "\\s+")[[1]])
      estimated_mb <- word_count / 100000  # Rough estimate
      actual_timeout <- calculate_timeout(estimated_mb, use_timeout, timeout_seconds)

      # Build prompt
      full_prompt <- if (!is.null(prompt)) prompt else "Please summarize and analyze the following text:"

      cat(sprintf("[ChatGPT] Starting analysis (%d words, timeout: %d sec)\n", word_count, actual_timeout))

      # Retry loop
      for (attempt in 1:max_retries) {
        tryCatch({
          cat(sprintf("[ChatGPT] Attempt %d/%d\n", attempt, max_retries))

          # Make API call
          payload <- list(
            model = private$chatgpt_model,
            messages = list(
              list(role = "user", content = paste(full_prompt, "\n\n", text))
            ),
            temperature = private$chatgpt_temperature,
            max_tokens = private$chatgpt_max_tokens
          )

          response <- httr::POST(
            url = "https://api.openai.com/v1/chat/completions",
            httr::add_headers(Authorization = paste("Bearer", private$chatgpt_api_key)),
            httr::content_type("application/json"),
            body = jsonlite::toJSON(payload, auto_unbox = TRUE),
            httr::timeout(actual_timeout),
            httr::config(
              connecttimeout = 60,
              ssl_verifypeer = TRUE,
              http_version = 2
            )
          )

          # Handle response
          status <- httr::status_code(response)

          if (status == 200) {
            # Success
            content <- httr::content(response, as = "text")
            result <- jsonlite::fromJSON(content)
            cat(sprintf("[ChatGPT] Analysis successful\n"))
            return(result$choices[[1]]$message$content)
          } else if (status == 429) {
            # Rate limited
            wait_time <- exponential_backoff(attempt)
            cat(sprintf("[ChatGPT] Rate limited. Waiting %d seconds...\n", wait_time))
            Sys.sleep(wait_time)
            next
          } else {
            # Other HTTP error
            error_detail <- httr::http_status(response)$message
            stop(sprintf("API Error (HTTP %d): %s", status, error_detail))
          }

        }, error = function(e) {
          error_msg <- e$message
          error_type <- categorize_error(error_msg)

          cat(sprintf("[ChatGPT] Error (Type: %s): %s\n", error_type, error_msg))

          # Retry logic
          if (error_type %in% c("network", "rate_limit") && attempt < max_retries) {
            wait_time <- exponential_backoff(attempt)
            cat(sprintf("[ChatGPT] Retriable error. Waiting %d seconds...\n", wait_time))
            Sys.sleep(wait_time)
          } else if (attempt == max_retries) {
            stop(sprintf("Analysis failed after %d attempts: %s", max_retries, error_msg))
          } else {
            stop(sprintf("Analysis failed (not retriable): %s", error_msg))
          }
        })
      }

      stop("Analysis failed: max retries exceeded")
    }
  )
)
