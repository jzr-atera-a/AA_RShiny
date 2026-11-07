# global.R - Energy & Trading Analytics Suite
# Selection of main tabs from Trading Analysis F1, plus a new "External
# Sources" group (Satellite Data map). Same shared-manager pattern as the
# source app: one DataManager, one ApiManager, plus debug-log capture.

# ── Debug console capture ───────────────────────────────────────────────
# See modules/debug_console.R for the tab this backs. Mirrors stdout
# (cat()/print()) into an in-memory buffer while still printing normally,
# so log text can be copied from a mobile browser. local = FALSE is
# deliberate - some R installations' textConnection() implementation
# errors ("argument is not interpretable as logical") if `local` is given
# an environment instead of TRUE/FALSE.
.debug_log_max_lines <- 5000

if (!exists(".debug_log_conn", envir = .GlobalEnv) ||
    !isTRUE(tryCatch(isOpen(get(".debug_log_conn", envir = .GlobalEnv)), error = function(e) FALSE))) {

  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  .debug_log_conn <- textConnection("debug_log_buffer", open = "w", local = FALSE)
  sink(.debug_log_conn, type = "output", split = TRUE)
  cat("\u2713 [Debug Console] Log capture initialized\n")
} else {
  cat("\u2713 [Debug Console] Reusing existing log capture (already active this R session)\n")
}

get_debug_log_lines <- function() {
  raw <- tryCatch(get("debug_log_buffer", envir = .GlobalEnv), error = function(e) character(0))
  if (length(raw) > .debug_log_max_lines) raw <- tail(raw, .debug_log_max_lines)
  raw
}
clear_debug_log <- function() {
  sink(type = "output")
  close(.debug_log_conn)
  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  .debug_log_conn <<- textConnection("debug_log_buffer", open = "w", local = FALSE)
  sink(.debug_log_conn, type = "output", split = TRUE)
  invisible(TRUE)
}

source("R/utils_data.R")
source("R/utils_ig.R")
source("R/utils_synthetic.R")
source("R/utils_academic.R")
source("R/utils_api_manager.R")

# Initialize managers.
data_manager <- DataManager$new()
ig_manager   <- IGSessionManager$new()
data_manager$ig <- ig_manager
api_manager <- ApiManager$new()

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("\u2713 Global configuration complete\n")
