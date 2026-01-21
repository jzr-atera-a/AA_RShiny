library(httr)
library(jsonlite)
library(base64enc)

# Function to encode file to base64
encode_file <- function(file_path) {
  file_content <- readBin(file_path, "raw", file.info(file_path)$size)
  base64encode(file_content)
}

# Function to determine media type
get_media_type <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  if (ext %in% c("jpg", "jpeg")) {
    return("image/jpeg")
  } else if (ext == "pdf") {
    return("application/pdf")
  }
  return("image/jpeg")
}

# Function to call OpenAI API for receipt processing
call_openai_api <- function(file_path, filename, api_key) {
  if (is.null(api_key) || nchar(api_key) == 0) {
    return(list(error = "API key not set"))
  }
  
  # Encode file to base64
  base64_data <- encode_file(file_path)
  media_type <- get_media_type(filename)
  
  # OpenAI only supports images in vision API, not PDFs
  if (media_type == "application/pdf") {
    return(list(error = "PDF files are not supported with OpenAI Vision API. Please use JPG/JPEG images only."))
  }
  
  # Prepare API request for OpenAI
  api_url <- "https://api.openai.com/v1/chat/completions"
  
  body <- list(
    model = "gpt-4o",
    messages = list(
      list(
        role = "user",
        content = list(
          list(
            type = "image_url",
            image_url = list(
              url = paste0("data:", media_type, ";base64,", base64_data)
            )
          ),
          list(
            type = "text",
            text = paste0(
              "Please analyze this purchase receipt and extract the following information:\n\n",
              "1. Provider/Seller name\n",
              "2. Final amount paid - IMPORTANT: Return ONLY the numeric value without any currency symbols (£, $, etc.). Just the number like 18.34\n",
              "3. Date of payment (in YYYY-MM-DD format if possible)\n",
              "4. Description of items or services purchased (brief summary)\n\n",
              "Respond ONLY with a valid JSON object in this exact format:\n",
              "{\n",
              '  "provider": "Name of provider/seller",\n',
              '  "amount": 18.34,\n',
              '  "date": "2025-11-13",\n',
              '  "description": "Brief description of items/services"\n',
              "}\n\n",
              "CRITICAL: The amount field must be a NUMBER (like 18.34), NOT a string with currency symbol.\n",
              "DO NOT include any text outside the JSON object. ",
              "DO NOT use markdown code blocks or backticks. ",
              "Return ONLY the JSON object."
            )
          )
        )
      )
    ),
    max_tokens = 500
  )
  
  # Make API request
  response <- tryCatch({
    POST(
      url = api_url,
      add_headers(
        `Authorization` = paste("Bearer", api_key),
        `Content-Type` = "application/json"
      ),
      body = body,
      encode = "json",
      timeout(60)
    )
  }, error = function(e) {
    return(list(error = paste("API request failed:", e$message)))
  })
  
  if ("error" %in% names(response)) {
    return(response)
  }
  
  # Parse response
  if (status_code(response) == 200) {
    content <- content(response, "parsed")
    if (!is.null(content$choices) && length(content$choices) > 0) {
      response_text <- content$choices[[1]]$message$content
      
      # Clean up response text (remove markdown formatting if present)
      response_text <- gsub("```json\\s*", "", response_text)
      response_text <- gsub("```\\s*", "", response_text)
      response_text <- trimws(response_text)
      
      # Parse JSON
      tryCatch({
        parsed_data <- fromJSON(response_text)
        return(parsed_data)
      }, error = function(e) {
        return(list(error = paste("Failed to parse JSON response:", e$message, 
                                  "\nRaw response:", substr(response_text, 1, 200))))
      })
    } else {
      return(list(error = "API returned empty response"))
    }
  } else if (status_code(response) == 401) {
    return(list(error = "Authentication failed (401). Your API key is invalid. Check Settings tab."))
  } else if (status_code(response) == 429) {
    return(list(error = "Rate limit exceeded (429). Please wait a moment and try again."))
  } else if (status_code(response) == 400) {
    error_content <- tryCatch(content(response, "text", encoding = "UTF-8"), 
                              error = function(e) "Unknown error")
    return(list(error = paste("Bad request (400):", error_content)))
  } else {
    return(list(error = paste("API error: Status code", status_code(response))))
  }
}

# Function to test API connection
test_api_connection <- function(api_key) {
  if (is.null(api_key) || nchar(api_key) == 0) {
    return(list(success = FALSE, message = "Please enter and save your API key first."))
  }
  
  tryCatch({
    response <- POST(
      url = "https://api.openai.com/v1/chat/completions",
      add_headers(
        `Authorization` = paste("Bearer", api_key),
        `Content-Type` = "application/json"
      ),
      body = list(
        model = "gpt-4o",
        messages = list(
          list(
            role = "user",
            content = "Say 'API test successful' if you receive this message."
          )
        ),
        max_tokens = 10
      ),
      encode = "json",
      timeout(30)
    )
    
    if (status_code(response) == 200) {
      return(list(
        success = TRUE, 
        message = paste("✓ Success! API connection is working correctly. You can now process receipts.\n\nResponse received at:", 
                       format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      ))
    } else if (status_code(response) == 401) {
      return(list(
        success = FALSE,
        message = "✗ Authentication Failed (401): Your API key is invalid or has expired. Please check your key at https://platform.openai.com/api-keys"
      ))
    } else if (status_code(response) == 429) {
      return(list(
        success = FALSE,
        message = "✗ Rate Limit Exceeded (429): Too many requests. Please wait a moment and try again."
      ))
    } else {
      return(list(
        success = FALSE,
        message = paste("✗ Error: API returned status code:", status_code(response))
      ))
    }
  }, error = function(e) {
    return(list(
      success = FALSE,
      message = paste("✗ Connection Error: Could not connect to OpenAI API:", e$message)
    ))
  })
}
