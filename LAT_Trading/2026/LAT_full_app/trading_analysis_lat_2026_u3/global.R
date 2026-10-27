# global.R - Trading Analysis F1
# Minimal: constructs the shared R6 managers used across all modules.
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
if (!exists(".debug_log_conn", envir = .GlobalEnv) ||
    !isTRUE(tryCatch(isOpen(get(".debug_log_conn", envir = .GlobalEnv)), error = function(e) FALSE))) {

  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  .debug_log_conn <- textConnection("debug_log_buffer", open = "w", local = FALSE)
  sink(.debug_log_conn, type = "output", split = TRUE)
  cat("\u2713 [Debug Console] Log capture initialized\n")
} else {
  # Existing debug_log_buffer / .debug_log_conn in .GlobalEnv are still
  # valid and already wired to the active sink — leave them untouched.
  cat("\u2713 [Debug Console] Reusing existing log capture (already active this R session)\n")
}

get_debug_log_lines <- function() {
  raw <- tryCatch(get("debug_log_buffer", envir = .GlobalEnv), error = function(e) character(0))
  if (length(raw) > .debug_log_max_lines) raw <- tail(raw, .debug_log_max_lines)
  raw
}
clear_debug_log <- function() {
  # textConnection's bound variable can't be reset in place without closing
  # and reopening the connection, so swap in a fresh one.
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
source("R/utils_trading_records.R")
source("R/utils_trading_exports.R")
source("R/utils_trading_templates.R")
source("R/utils_trading_calendar.R")
source("R/utils_trading_pipeline.R")
source("R/utils_trading_decision.R")
source("R/utils_u3_report.R")
source("R/utils_unit3_rules.R")

# Initialize managers. ig_manager is linked onto data_manager so any module can
# reach it via data_manager$ig without every module server needing its own
# extra constructor argument.
data_manager <- DataManager$new()
ig_manager   <- IGSessionManager$new()
data_manager$ig <- ig_manager
api_manager <- ApiManager$new()

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("\u2713 Global configuration complete\n")
