# R/utils_log.R
# ─────────────────────────────────────────────────────────────────────
# One log for the whole app. Every entry goes to the R console AND to the
# Debug Console tab, in the same format:
#     [HH:MM:SS][TAG][type] message
# type: info | cmd | success | warn | error
# ─────────────────────────────────────────────────────────────────────

SDM_LOG <- new.env(parent = emptyenv())
SDM_LOG$entries <- character(0)

sdm_log <- function(tag, msg, type = "info") {
  ts   <- format(Sys.time(), "%H:%M:%S")
  msg  <- gsub("[\r\n]+", " | ", as.character(msg))
  line <- sprintf("[%s][%s][%s] %s", ts, toupper(tag), type, msg)
  cat(line, "\n", sep = "")
  flush(stdout())
  SDM_LOG$entries <- utils::tail(c(SDM_LOG$entries, line), 2000)
  invisible(line)
}

sdm_log_entries <- function() SDM_LOG$entries

sdm_log_clear <- function() {
  SDM_LOG$entries <- character(0)
  invisible(TRUE)
}
