# R/live_log.R
#
# Shared helpers for long-running jobs in the Audio Transcription tabs.
#
# WHY THIS EXISTS
# Shiny only sends output updates to the browser AFTER an observer finishes.
# A single observeEvent() that loops over 5 audio segments (or 5 Whisper calls)
# therefore shows nothing until the very end, and the whole app is frozen
# meanwhile. The fix used here is the standard Shiny pattern: break the job
# into small steps and run ONE step per observer execution, rescheduling the
# next step with invalidateLater(). Between steps Shiny flushes the log to the
# browser, so the user sees every line as it happens, and other clicks/tabs
# are serviced between steps.
#
#   live_log_output(ns("log"))               # UI: terminal-style log box
#   log <- create_live_log(session, "log", "[Converter]")
#   log$add("message")                       # app log + RStudio console
#   job <- create_step_job(session)
#   job$start(step_fn, on_error, on_done)    # step_fn() returns TRUE when done

live_log_output <- function(outputId, height = "380px") {
  tagList(
    singleton(tags$head(
      tags$style(HTML(sprintf("
        pre.live-log {
          height: %s; overflow-y: auto; margin: 0;
          background-color: #1e1e1e !important; color: #00ff66 !important;
          font-family: Consolas, 'Courier New', monospace; font-size: 12px;
          line-height: 1.45; padding: 10px; border: 1px solid #333; border-radius: 4px;
          white-space: pre-wrap; word-wrap: break-word;
        }", height))),
      tags$script(HTML("
        // Lines are pushed straight from the server (session$sendCustomMessage),
        // which is delivered immediately - not held back until the job ends.
        Shiny.addCustomMessageHandler('live-log', function(m) {
          var el = document.getElementById(m.id);
          if (!el) return;
          if (m.clear) { el.textContent = ''; }
          if (m.lines) {
            el.textContent += (el.textContent.length ? '\\n' : '') + [].concat(m.lines).join('\\n');
          }
          el.scrollTop = el.scrollHeight;
        });
      "))
    )),
    tags$pre(id = outputId, class = "live-log")
  )
}

create_live_log <- function(session, output_id, console_tag = "") {
  target <- session$ns(output_id)

  add <- function(..., timestamp = TRUE) {
    msg <- paste0(...)
    line <- if (timestamp && nzchar(msg)) sprintf("[%s] %s", format(Sys.time(), "%H:%M:%S"), msg) else msg
    session$sendCustomMessage("live-log", list(id = target, lines = line))
    # Mirror to the RStudio console immediately
    cat(console_tag, if (nzchar(console_tag)) " " else "", line, "\n", sep = "")
    flush.console()
    invisible(line)
  }

  list(
    add = add,
    raw = function(...) add(..., timestamp = FALSE),
    clear = function() session$sendCustomMessage("live-log", list(id = target, clear = TRUE))
  )
}

# Runs a job one step at a time so the UI updates between steps.
# step_fn(): does ONE unit of work, returns TRUE when the whole job is finished.
create_step_job <- function(session = getDefaultReactiveDomain(), delay_ms = 60) {
  state <- new.env()
  state$active <- FALSE
  state$warmup <- FALSE
  kick <- reactiveVal(0)

  observe({
    kick()
    if (!isTRUE(state$active)) return()

    # First pass only schedules the work, so the "starting..." lines written by
    # the button handler reach the browser before the first heavy step runs.
    if (isTRUE(state$warmup)) {
      state$warmup <- FALSE
      invalidateLater(delay_ms, session)
      return()
    }

    finished <- tryCatch(isTRUE(state$step_fn()), error = function(e) {
      tryCatch(state$on_error(e), error = function(e2) message("[StepJob] on_error failed: ", conditionMessage(e2)))
      TRUE
    })

    if (finished) {
      state$active <- FALSE
      tryCatch(state$on_done(), error = function(e) message("[StepJob] on_done failed: ", conditionMessage(e)))
    } else {
      invalidateLater(delay_ms, session)
    }
  })

  list(
    start = function(step_fn, on_error = function(e) NULL, on_done = function() NULL) {
      if (isTRUE(state$active)) return(FALSE)
      state$step_fn <- step_fn
      state$on_error <- on_error
      state$on_done <- on_done
      state$active <- TRUE
      state$warmup <- TRUE
      kick(isolate(kick()) + 1)
      TRUE
    },
    is_running = function() isTRUE(state$active)
  )
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

fmt_hms <- function(seconds) {
  seconds <- max(0, round(seconds))
  sprintf("%02d:%02d:%02d", seconds %/% 3600, (seconds %% 3600) %/% 60, seconds %% 60)
}
