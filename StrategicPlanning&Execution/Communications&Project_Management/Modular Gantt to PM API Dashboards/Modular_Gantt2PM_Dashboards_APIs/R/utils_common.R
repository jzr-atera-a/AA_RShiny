# R/utils_common.R
# Common utility functions
# ========================

# Helper operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Safe string conversion
safe_string <- function(x) {
  if (is.null(x) || is.na(x)) return("")
  as.character(x)
}

# Parse email from name format
parse_email <- function(assignee) {
  if (grepl("<.*@.*>", assignee)) {
    return(gsub(".*<(.*)>.*", "\\1", assignee))
  }
  return(assignee)
}

# Validate email format
is_valid_email <- function(email) {
  grepl("@", email) && grepl("\\.", email)
}

# Replace template placeholders
replace_placeholders <- function(template, data_row) {
  result <- template
  for (col in names(data_row)) {
    placeholder <- paste0("{", col, "}")
    value <- ifelse(is.na(data_row[[col]]), "", as.character(data_row[[col]]))
    result <- gsub(placeholder, value, result, fixed = TRUE)
  }
  return(result)
}
