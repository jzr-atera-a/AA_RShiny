# Common utility functions
format_for_html <- function(text) {
  if (is.null(text) || is.na(text)) return("")
  gsub("\n", "<br>", text)
}

clean_for_sql <- function(text) {
  if (is.null(text) || is.na(text)) return("")
  gsub("'", "\\\\'", text)
}

truncate_text <- function(text, max_chars = 100) {
  if (is.null(text) || is.na(text)) return("")
  if (nchar(text) <= max_chars) return(text)
  paste0(substr(text, 1, max_chars), "...")
}

`%||%` <- function(x, y) if (is.null(x)) y else x
