# R/utils.R - small helpers shared by every module

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x

now_ts <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

new_id <- function(prefix = "id") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", paste(sample(c(letters, 0:9), 5, TRUE), collapse = ""))
}

is_true <- function(x) isTRUE(tolower(as.character(x %||% "")) %in% c("true", "1", "yes", "y"))

blank <- function(x) is.null(x) || length(x) == 0 || is.na(x[1]) || !nzchar(trimws(as.character(x[1])))

# One SQL escape for BigQuery (GoogleSQL uses backslash escapes, not doubled quotes).
# From the Modular RShiny improvement guide: every replacement is fixed = TRUE.
safe_sql_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("'", "\\'", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x <- gsub("\r\n", "\n", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x
}

safe_error_text <- function(e) paste(conditionMessage(e), collapse = " ")

# An empty data frame with the columns of a table
empty_table <- function(tab) {
  cols <- SCHEMAS[[tab]]
  as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols), stringsAsFactors = FALSE)
}

# Make sure a data frame has exactly the schema columns, as text, in order
conform <- function(df, tab) {
  cols <- SCHEMAS[[tab]]
  if (is.null(df) || !is.data.frame(df)) df <- empty_table(tab)
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  for (c in setdiff(cols, names(df))) df[[c]] <- if (nrow(df)) rep("", nrow(df)) else character(0)
  df <- df[, cols, drop = FALSE]
  for (c in cols) {
    x <- df[[c]]
    # numbers as plain text (900000, not 9e+05)
    v <- if (is.numeric(x)) ifelse(is.na(x), "", trimws(formatC(x, format = "fg", digits = 15))) else as.character(x)
    v[is.na(v)] <- ""; df[[c]] <- v
  }
  rownames(df) <- NULL
  df
}

# Latest row per key wins (append-only tables such as settings and priorities)
latest_by <- function(df, keys, time_col = "updated_at") {
  if (!nrow(df)) return(df)
  df <- df[order(df[[time_col]]), , drop = FALSE]
  k <- do.call(paste, c(df[keys], sep = "\r"))
  df[!duplicated(k, fromLast = TRUE), , drop = FALSE]
}

# ---- debug log: a ring buffer shown in Admin > Activity ---------------------------------
.debug <- new.env(parent = emptyenv())
.debug$lines <- character(0)
log_debug <- function(...) {
  line <- paste0("[", format(Sys.time(), "%H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n")
  .debug$lines <- utils::tail(c(.debug$lines, line), 400)
  invisible(line)
}

# ---- small UI pieces ------------------------------------------------------------------
note <- function(kind = c("ok", "warn", "bad", "info"), ...) {
  kind <- match.arg(kind)
  div(class = paste("note", kind), ...)
}

card <- function(title = NULL, ..., class = "") {
  div(class = paste("cp-card", class),
      if (!is.null(title)) h4(class = "cp-card-title", title),
      ...)
}

status_pill <- function(ok, yes = "Connected", no = "Not set up") {
  span(class = paste("pill", if (isTRUE(ok)) "pill-ok" else "pill-off"), if (isTRUE(ok)) yes else no)
}

example_badge <- function() span(class = "pill pill-example", "Example")

# ---- optional packages ---------------------------------------------------------------------
has_pkg <- function(p) requireNamespace(p, quietly = TRUE)
PKG_NEEDED_FOR <- list(officer = "Word (.docx) download and reading .docx files", pdftools = "reading PDF files",
                       readxl = "Excel Gantt upload", writexl = "the Excel Gantt template",
                       flextable = "flextable styling of analysis tables (a plain styled table is used instead)")
need_pkg <- function(p) if (!has_pkg(p))
  stop("The R package '", p, "' is not installed, so ", PKG_NEEDED_FOR[[p]], " is not available. Ask an admin to run install.R.", call. = FALSE)
