# R/utils_common.R
# Minimal shared generic helpers, carried over from the DriveSafe Suite
# template (the legacy Day Planner / Events / Funding cascade helpers were
# not relevant to this app and have been stripped).

safe_sql_escape <- function(x) {
  gsub("'", "\\'", x, fixed = TRUE)
}

has_real_value <- function(x) {
  if (is.null(x) || is.na(x)) return(FALSE)
  trimmed <- trimws(as.character(x))
  if (nchar(trimmed) == 0) return(FALSE)
  if (tolower(trimmed) %in% c("n/a", "na")) return(FALSE)
  TRUE
}

`%||%` <- function(x, y) if (is.null(x)) y else x
