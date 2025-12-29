library(openxlsx)

# Function to create safe filename
create_safe_filename <- function(text, max_length = NULL) {
  # Remove or replace unsafe characters
  safe_text <- gsub("[^a-zA-Z0-9 ]", "", text)
  safe_text <- gsub("\\s+", "_", safe_text)
  safe_text <- trimws(safe_text)
  
  # Limit length if specified
  if (!is.null(max_length) && nchar(safe_text) > max_length) {
    safe_text <- substr(safe_text, 1, max_length)
  }
  
  return(safe_text)
}

# Function to create renamed filename
create_renamed_filename <- function(provider, description, date, amount, original_ext) {
  # Clean provider name
  provider_clean <- create_safe_filename(provider, max_length = 50)
  if (provider_clean == "" || provider_clean == "N_A") provider_clean <- "Unknown"
  
  # Get first 40 characters of description for trains/accommodation, 20 for others
  desc_clean <- create_safe_filename(description, max_length = 40)
  if (desc_clean == "" || desc_clean == "N_A") desc_clean <- "NoDescription"
  
  # Format date as YYYYMMDD
  date_formatted <- gsub("-", "", date)
  if (nchar(date_formatted) != 8 || date_formatted == "N_A") {
    date_formatted <- format(Sys.Date(), "%Y%m%d")
  }
  
  # Format amount
  amount_formatted <- sprintf("%.2f", amount)
  
  # Combine: ProviderName_Description_YYYYMMDD_Amount.ext
  new_filename <- paste0(
    provider_clean, "_",
    desc_clean, "_",
    date_formatted, "_",
    amount_formatted,
    original_ext
  )
  
  return(new_filename)
}

# Function to get smart description for specific types
get_smart_description <- function(provider, description, api_key) {
  provider_lower <- tolower(provider)
  description_lower <- tolower(description)
  smart_description <- description
  
  # Check if it's train-related
  if (grepl("train|rail|railway|trainline", provider_lower) || 
      grepl("train|rail|railway", description_lower)) {
    # Ask OpenAI to extract just origin and destination
    train_prompt_body <- list(
      model = "gpt-4o",
      messages = list(
        list(
          role = "user",
          content = paste0(
            "From this train receipt description: '", description, 
            "'\n\nExtract ONLY the origin station and destination station.\n",
            "Format: OriginStation to DestinationStation\n",
            "Example: 'London Euston to Manchester Piccadilly'\n",
            "Keep station names clear and concise. Maximum 40 characters total.\n",
            "Return ONLY the formatted route, nothing else."
          )
        )
      ),
      max_tokens = 50
    )
    
    train_response <- tryCatch({
      httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          `Authorization` = paste("Bearer", api_key),
          `Content-Type` = "application/json"
        ),
        body = train_prompt_body,
        encode = "json",
        httr::timeout(30)
      )
    }, error = function(e) NULL)
    
    if (!is.null(train_response) && httr::status_code(train_response) == 200) {
      train_content <- httr::content(train_response, "parsed")
      if (!is.null(train_content$choices) && length(train_content$choices) > 0) {
        extracted_route <- trimws(train_content$choices[[1]]$message$content)
        if (nchar(extracted_route) > 0 && nchar(extracted_route) <= 60) {
          smart_description <- extracted_route
        }
      }
    }
  }
  
  # Check if it's accommodation-related
  if (grepl("booking\\.com|airbnb|hotel|hostel|accommodation", provider_lower) || 
      grepl("hotel|accommodation|stay|night", description_lower)) {
    # Try to extract city/location from description
    city_match <- gsub(".*?\\b(in|at)\\s+([A-Za-z\\s]+).*", "\\2", description, ignore.case = TRUE)
    if (city_match != description && nchar(city_match) > 0 && nchar(city_match) < 30) {
      smart_description <- city_match
    }
  }
  
  return(smart_description)
}

# Function to initialize folder browser volumes
get_folder_volumes <- function() {
  if (.Platform$OS.type == "windows") {
    volumes <- c(
      "C:" = "C:/",
      "D:" = "D:/",
      "E:" = "E:/",
      Home = fs::path_home(),
      shinyFiles::getVolumes()()
    )
  } else {
    volumes <- c(
      Root = "/",
      Home = fs::path_home(),
      shinyFiles::getVolumes()()
    )
  }
  return(volumes)
}
