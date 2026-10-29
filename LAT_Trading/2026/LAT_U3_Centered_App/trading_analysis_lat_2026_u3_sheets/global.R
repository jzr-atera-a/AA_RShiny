# global.R - LAT Unit 3 Trading Records (the Unit 3 subset of Trading Analysis F1)
# Constructs the shared managers. No IG API package: IG data comes from your screenshots (the IG API needs a live account).
# (No dynamic module loader/registry — app.R sources modules/*.R directly and
# wires up the sidebar/tabs/server calls explicitly, matching the simpler
# reference pattern.)

# ── Debug console capture ───────────────────────────────────────────────
# Mirrors everything written to stdout (every cat()/print() call — which
# covers all of this app's extensive [BigQuery]/[Claude]/[Trend Summary]/
# [Export]/etc. logging) into a growing in-memory buffer, WHILE STILL
# printing to the real R console exactly as before (split = TRUE, so
# nothing about normal Posit console debugging changes). The buffer backs
# the API Configuration -> Debug Console tab, so that log text can be
# selected and copied from a phone browser — which is painful to do from
# Posit Cloud's own console on mobile — instead of only being visible in
# the R console. Set up first, before any other source()/cat() calls, so
# it captures app startup too. Only stdout (type="output") is captured;
# warnings/messages go through a separate R stream (type="message") whose
# sink does not support split=TRUE reliably across R versions, and
# breaking that would hide real errors from the normal console, so it is
# deliberately left alone — this only mirrors cat()/print() output.
#
# NOTE: textConnection()'s `local` argument must be TRUE/FALSE here, not an
# environment object — this R installation's textConnection() implementation
# does `if (local) parent.frame() else .GlobalEnv` internally, which errors
# ("argument is not interpretable as logical") if given an environment
# directly, even though some R documentation describes environment support.
# Binding straight to .GlobalEnv (local = FALSE) sidesteps this entirely and
# works the same regardless of R version.
.debug_log_max_lines <- 5000  # cap to bound memory over a long-running session

# Guard against re-initializing on every runApp() call within the same
# persistent R session (global.R re-sources each time runApp() runs, and
# this app is routinely restarted this way during development without
# restarting R — an unguarded sink() would stack a new diversion on top of
# the previous one every time, degrading output over a long session).
# A log connection left open by an earlier run (for example after rm(list = ls()) or another app in the same R session)
# keeps 'debug_log_buffer' locked: find it and reuse it instead of failing with "cannot change value of locked binding".
.u3_find_log_conn <- function() {
  cs <- tryCatch(showConnections(all = TRUE), error = function(e) NULL); if (is.null(cs) || !nrow(cs)) return(NULL)
  hit <- which(cs[, "description"] == "debug_log_buffer" & cs[, "class"] == "textConnection" & cs[, "isopen"] == "opened")
  if (!length(hit)) return(NULL)
  tryCatch(getConnection(as.integer(rownames(cs)[hit[length(hit)]])), error = function(e) NULL)
}
if (!exists(".debug_log_conn", envir = .GlobalEnv) ||
    !isTRUE(tryCatch(isOpen(get(".debug_log_conn", envir = .GlobalEnv)), error = function(e) FALSE))) {
  old <- .u3_find_log_conn()
  if (!is.null(old)) {
    assign(".debug_log_conn", old, envir = .GlobalEnv)
    if (sink.number() == 0) sink(old, type = "output", split = TRUE)
    cat("\u2713 [Debug Console] Reusing the log capture left open by an earlier run\n")
  } else {
    if (exists("debug_log_buffer", envir = .GlobalEnv) && bindingIsLocked("debug_log_buffer", .GlobalEnv)) unlockBinding("debug_log_buffer", .GlobalEnv)
    assign("debug_log_buffer", character(0), envir = .GlobalEnv)
    assign(".debug_log_conn", textConnection("debug_log_buffer", open = "w", local = FALSE), envir = .GlobalEnv)
    sink(get(".debug_log_conn", envir = .GlobalEnv), type = "output", split = TRUE)
    cat("\u2713 [Debug Console] Log capture initialized\n")
  }
  rm(old)
} else {
  # Existing debug_log_buffer / .debug_log_conn in .GlobalEnv are still
  # valid and already wired to the active sink — leave them untouched.
  cat("\u2713 [Debug Console] Reusing existing log capture (already active this R session)\n")
}

# The log buffer belongs to the whole R session (other apps run in the same RStudio session write to it too):
# remember where THIS app started, and show only what came after.
assign(".u3_log_start", max(0L, length(tryCatch(get("debug_log_buffer", envir = .GlobalEnv), error = function(e) character(0))) - 2L), envir = .GlobalEnv)
get_debug_log_lines <- function() {
  raw <- tryCatch(get("debug_log_buffer", envir = .GlobalEnv), error = function(e) character(0))
  st <- tryCatch(get(".u3_log_start", envir = .GlobalEnv), error = function(e) 0L); if (st > length(raw)) st <- 0L
  raw <- raw[seq_len(length(raw)) > st]
  raw <- raw[!grepl("^\\s*[-/|\\\\]?\\s*$", raw)]   # progress spinners ("-", "/", "|", "\\") and blank lines
  if (length(raw) > .debug_log_max_lines) raw <- tail(raw, .debug_log_max_lines)
  raw
}
clear_debug_log <- function() {
  # textConnection's bound variable can't be reset in place without closing
  # and reopening the connection, so swap in a fresh one.
  if (sink.number() > 0) sink(type = "output")
  tryCatch(close(get(".debug_log_conn", envir = .GlobalEnv)), error = function(e) NULL)
  if (bindingIsLocked("debug_log_buffer", .GlobalEnv)) unlockBinding("debug_log_buffer", .GlobalEnv)
  assign("debug_log_buffer", character(0), envir = .GlobalEnv); assign(".u3_log_start", 0L, envir = .GlobalEnv)
  assign(".debug_log_conn", textConnection("debug_log_buffer", open = "w", local = FALSE), envir = .GlobalEnv)
  sink(get(".debug_log_conn", envir = .GlobalEnv), type = "output", split = TRUE)
  invisible(TRUE)
}

source("R/utils_data.R")
source("R/utils_academic.R")
source("R/utils_api_manager.R")
source("R/utils_trading_records.R")
source("R/utils_trading_exports.R")
source("R/utils_trading_templates.R")
source("R/utils_trading_calendar.R")
source("R/utils_trading_pipeline.R")
source("R/utils_trading_decision.R")
source("R/utils_calendar_sources.R")
source("R/utils_local_creds.R")
source("R/utils_trade_scenarios.R")
source("R/utils_patterns.R")
options(bigrquery.quiet = TRUE)   # no "Job complete / Billed" line for every BigQuery read; errors still show
source("R/utils_u3_report.R")
source("R/utils_unit3_rules.R")

data_manager <- DataManager$new()   # Yahoo prices for Live Signals (data_manager$ig stays NULL: no IG API)
api_manager <- ApiManager$new()

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("\u2713 LAT Unit 3 app: global configuration complete\n")
