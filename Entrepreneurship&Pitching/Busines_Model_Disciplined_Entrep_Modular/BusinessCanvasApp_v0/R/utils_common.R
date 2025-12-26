# R/utils_common.R
# Common utility functions used across modules

# Helper operator for default values
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Format text for HTML display
format_for_html <- function(text) {
  if (is.null(text) || is.na(text) || trimws(text) == "") {
    return("")
  }
  gsub("\n", "<br>", text)
}

# Clean text for SQL insertion (escape quotes)
clean_for_sql <- function(text) {
  if (is.null(text) || is.na(text)) {
    return("")
  }
  gsub("'", "\\\\'", text)
}

# Truncate text to max length
truncate_text <- function(text, max_length = 32) {
  if (is.null(text) || is.na(text)) {
    return("")
  }
  substr(trimws(text), 1, max_length)
}

# Generate unique ID for records
generate_record_id <- function(business_area, project, business_focus) {
  paste0(
    gsub("[^A-Za-z0-9]", "_", business_area), "_",
    gsub("[^A-Za-z0-9]", "_", project), "_",
    gsub("[^A-Za-z0-9]", "_", business_focus), "_",
    format(Sys.time(), "%Y%m%d%H%M%S")
  )
}

# Validate required fields
validate_required_fields <- function(...) {
  fields <- list(...)
  
  for (field in fields) {
    if (is.null(field) || trimws(field) == "") {
      return(FALSE)
    }
  }
  
  return(TRUE)
}

# Create status message HTML
create_status_html <- function(type = "info", message, icon = NULL, details = NULL) {
  # type: success, error, warning, info
  
  icon_map <- list(
    success = "check-circle",
    error = "times-circle",
    warning = "exclamation-triangle",
    info = "info-circle"
  )
  
  icon_class <- icon %||% icon_map[[type]] %||% "info-circle"
  
  html_parts <- c(
    sprintf('<div class="status-%s">', type),
    sprintf('<i class="fa fa-%s"></i> %s', icon_class, message)
  )
  
  if (!is.null(details)) {
    html_parts <- c(
      html_parts,
      "<br>",
      sprintf("<small>%s</small>", details)
    )
  }
  
  html_parts <- c(html_parts, "</div>")
  
  HTML(paste(html_parts, collapse = "\n"))
}

# Parse section from text using regex
parse_section <- function(text, section_name, case_insensitive = TRUE) {
  if (is.null(text) || trimws(text) == "") {
    return(NA_character_)
  }
  
  pattern <- if (case_insensitive) {
    sprintf("(?i)\\[%s\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)", section_name)
  } else {
    sprintf("\\[%s\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)", section_name)
  }
  
  match <- stringr::str_match(text, pattern)
  
  if (!is.na(match[1, 2])) {
    return(trimws(match[1, 2]))
  } else {
    return(NA_character_)
  }
}

# Check if all required sections are present
validate_sections <- function(text, required_sections) {
  missing_sections <- c()
  
  for (section in required_sections) {
    result <- parse_section(text, section)
    if (is.na(result)) {
      missing_sections <- c(missing_sections, section)
    }
  }
  
  if (length(missing_sections) > 0) {
    return(list(
      valid = FALSE,
      missing = missing_sections
    ))
  } else {
    return(list(
      valid = TRUE,
      missing = NULL
    ))
  }
}

cat("✔ Common utilities loaded\n")
