# R/utils_common.R - Common Utility Functions
# Version 3.0

# Safe HTML generation - always converts to character
safe_html <- function(text) {
  as.character(text)
}

# Format number with commas
format_number <- function(num) {
  format(num, big.mark = ",", scientific = FALSE)
}

# SQL injection prevention
escape_sql <- function(text) {
  gsub("'", "''", as.character(text))
}

# Generate unique ID
generate_id <- function(prefix = "id") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", 
         sample(1000:9999, 1))
}

# Validate email
is_valid_email <- function(email) {
  grepl("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", email)
}

# Parse CSV safely
safe_read_csv <- function(file_path) {
  tryCatch({
    read.csv(file_path, stringsAsFactors = FALSE)
  }, error = function(e) {
    stop(paste("Failed to read CSV:", e$message))
  })
}

# Show notification with icon
show_status <- function(message, type = "info", duration = 5) {
  icon_map <- list(
    success = "check-circle",
    error = "times-circle",
    warning = "exclamation-triangle",
    info = "info-circle"
  )
  
  showNotification(
    ui = tagList(icon(icon_map[[type]] %||% "info-circle"), message),
    type = type,
    duration = duration
  )
}
