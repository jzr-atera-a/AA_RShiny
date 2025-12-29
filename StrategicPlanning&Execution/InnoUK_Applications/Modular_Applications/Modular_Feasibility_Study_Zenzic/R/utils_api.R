# R/utils_api.R - Complete API Manager
library(R6)
library(httr)
library(jsonlite)

APIManager <- R6::R6Class("APIManager",
  public = list(
    openai_api_key = NULL,
    openai_authenticated = FALSE,
    claude_api_key = NULL,
    claude_model = "claude-3-haiku-20240307",
    claude_authenticated = FALSE,
    state_trigger = NULL,
    
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
    },
    
    # OpenAI Methods
    set_openai_credentials = function(api_key) {
      self$openai_api_key <- api_key
      self$openai_authenticated <- TRUE
      self$state_trigger(self$state_trigger() + 1)
    },
    
    test_openai_connection = function() {
      response <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers(
          "Authorization" = paste("Bearer", self$openai_api_key),
          "Content-Type" = "application/json"
        ),
        body = toJSON(list(
          model = "gpt-3.5-turbo",
          messages = list(list(role = "user", content = "test")),
          max_tokens = 50
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(60),
        config(ssl_verifypeer = TRUE)
      )
      
      if (status_code(response) == 200) {
        self$openai_authenticated <- TRUE
        return(TRUE)
      }
      stop(paste("Connection failed. Status:", status_code(response)))
    },
    
    call_openai = function(prompt, word_limit, section_name = "") {
      if (!self$openai_authenticated || is.null(self$openai_api_key)) {
        stop("Please configure and save your API key first!")
      }
      
      response <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers(
          "Authorization" = paste("Bearer", self$openai_api_key),
          "Content-Type" = "application/json"
        ),
        body = toJSON(list(
          model = "gpt-4",
          messages = list(
            list(
              role = "system",
              content = "You are a professional grant proposal writer with expertise in creating compelling, innovative project descriptions. Write clear, concise, and persuasive content that highlights innovation and aligns with funding requirements."
            ),
            list(role = "user", content = prompt)
          ),
          max_tokens = as.integer(word_limit * 2),
          temperature = 0.7
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(240),
        config(ssl_verifypeer = TRUE)
      )
      
      if (status_code(response) == 200) {
        result <- content(response, "parsed")
        return(trimws(result$choices[[1]]$message$content))
      } else {
        error_content <- content(response, "text", encoding = "UTF-8")
        stop(paste("API Error:", substr(error_content, 1, 200)))
      }
    },
    
    # Claude Methods
    set_claude_credentials = function(api_key, model = NULL) {
      self$claude_api_key <- api_key
      if (!is.null(model)) self$claude_model <- model
      self$claude_authenticated <- TRUE
      self$state_trigger(self$state_trigger() + 1)
    },
    
    test_claude_connection = function() {
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
          messages = list(list(role = "user", content = "test"))
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(30)
      )
      
      if (status_code(response) == 200) {
        self$claude_authenticated <- TRUE
        return(TRUE)
      }
      stop(paste("Claude connection failed. Status:", status_code(response)))
    },
    
    call_claude = function(messages, max_tokens = 4096) {
      if (!self$claude_authenticated || is.null(self$claude_api_key)) {
        stop("Please configure Claude API key first!")
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
          temperature = 0.7,
          messages = messages
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(240),
        config(ssl_verifypeer = TRUE)
      )
      
      if (status_code(response) == 200) {
        result <- content(response, "parsed")
        return(trimws(result$content[[1]]$text))
      } else {
        error_content <- content(response, "text", encoding = "UTF-8")
        stop(paste("Claude API Error:", substr(error_content, 1, 200)))
      }
    }
  )
)
