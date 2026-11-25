# core/debug_capture.R - mirrors every cat()/print() into an in-memory buffer
# that the Debug Console tab displays. Sourced first, before anything else.
# NOTE: textConnection(local =) must be TRUE/FALSE, never an environment.

.debug_log_max_lines <- 5000

if (!exists(".debug_log_conn", envir = .GlobalEnv) ||
    !isTRUE(tryCatch(isOpen(get(".debug_log_conn", envir = .GlobalEnv)), error = function(e) FALSE))) {
  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  assign(".debug_log_conn",
         textConnection("debug_log_buffer", open = "w", local = FALSE), envir = .GlobalEnv)
  sink(get(".debug_log_conn", envir = .GlobalEnv), type = "output", split = TRUE)
  cat("[Debug Console] Log capture initialized\n")
} else {
  cat("[Debug Console] Reusing existing log capture (already active this R session)\n")
}

get_debug_log_lines <- function() {
  raw <- tryCatch(get("debug_log_buffer", envir = .GlobalEnv), error = function(e) character(0))
  if (length(raw) > .debug_log_max_lines) raw <- utils::tail(raw, .debug_log_max_lines)
  raw
}

clear_debug_log <- function() {
  # The bound variable can't be reset in place, so swap in a fresh connection.
  sink(type = "output")
  close(get(".debug_log_conn", envir = .GlobalEnv))
  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  assign(".debug_log_conn",
         textConnection("debug_log_buffer", open = "w", local = FALSE), envir = .GlobalEnv)
  sink(get(".debug_log_conn", envir = .GlobalEnv), type = "output", split = TRUE)
  invisible(TRUE)
}
