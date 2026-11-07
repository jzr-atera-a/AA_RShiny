# ============================================================================
# MONITOR MODULE - SERVER
# Polls progress.json + run.log every 2s, drives all live UI
# Fixes: multibyte crash, repeated notifications, stale run on new session
# ============================================================================

monitor_server <- function(id, session_mgr, python_bridge, app_state, session) {
  moduleServer(id, function(input, output, session) {

    # ── Local reactive state ───────────────────────────────────────────────
    local_state <- reactiveValues(
      paused        = FALSE,
      checkpoint    = NULL,
      notified_done = FALSE,   # guard: show "complete" notification only once
      last_run_dir  = ""       # detect when run_dir changes → reset notified flag
    )

    # ── Reset notification guard when a new run is started ─────────────────
    observeEvent(app_state$run_dir, {
      local_state$notified_done <- FALSE
      local_state$last_run_dir  <- app_state$run_dir %||% ""
      local_state$paused        <- FALSE
    })

    # ── Polling timer ──────────────────────────────────────────────────────
    poll_timer <- reactiveTimer(2000)

    observe({
      poll_timer()

      # Wrap everything — a bad log line must never crash the observer
      tryCatch({

        rd <- app_state$run_dir %||% ""
        if (!nzchar(rd)) return()          # nzchar is safer than nchar() > 0

        # ── Log pane ──────────────────────────────────────────────────────
        log_text <- tryCatch({
          raw <- session_mgr$load_log(rd, tail_n = 300)
          # Sanitize: convert any non-UTF8 bytes to "?" before regex runs
          iconv(raw, from = "", to = "UTF-8", sub = "?")
        }, error = function(e) "")

        if (!is.na(log_text) && nzchar(log_text)) {
          shinyjs::html("termLog", color_log(log_text), add = FALSE)
          shinyjs::runjs(paste0(
            "var el=document.getElementById('", session$ns("termLog"), "');",
            "if(el) el.scrollTop=el.scrollHeight;"
          ))
        }

        # ── Progress JSON ─────────────────────────────────────────────────
        progress <- session_mgr$load_progress(rd)
        if (is.null(progress)) return()

        cur   <- as.integer(progress$cell_current %||% 0)
        total <- as.integer(progress$plan_total   %||% 1)
        pct   <- round(min(100, cur / max(total, 1) * 100))

        shinyjs::runjs(paste0(
          "var pb=document.getElementById('", session$ns("progressBar"), "');",
          "if(pb){pb.style.width='", pct, "%';",
          "pb.setAttribute('aria-valuenow','", pct, "');}"
        ))

        # ── Process state → button enable/disable ─────────────────────────
        is_alive <- python_bridge$is_running()
        # Update app_state — task tab observes this to re-enable its buttons
        if (app_state$running != is_alive) app_state$running <- is_alive

        if (is_alive && !local_state$paused) {
          shinyjs::enable("pauseBtn")
          shinyjs::disable("continueBtn")
          shinyjs::enable("stopBtn")
        } else if (local_state$paused) {
          shinyjs::disable("pauseBtn")
          shinyjs::enable("continueBtn")
          shinyjs::enable("stopBtn")
        } else {
          shinyjs::disable("pauseBtn")
          shinyjs::disable("continueBtn")
          shinyjs::disable("stopBtn")
        }

        # ── "Done" / error notification — fire ONCE per run ─────────────
        status <- progress$status %||% ""
        if (!is_alive && !local_state$notified_done) {
          local_state$notified_done <- TRUE
          if (status == "done") {
            showNotification(
              paste0("\u2713 Notebook complete! (",
                     progress$stats$cells_approved %||% 0, " cells approved)"),
              type = "message", duration = 10
            )
          } else if (status != "") {
            # Process died without "done" — likely an error
            showNotification(
              paste0("\u26a0 Python process ended: ", status,
                     " — check Live Log for details."),
              type = "error", duration = 15
            )
          }
        }

        # ── Stats cards ───────────────────────────────────────────────────
        stats   <- progress$stats %||% list()
        approved <- as.numeric(stats$cells_approved       %||% 0)
        skipped  <- as.numeric(stats$cells_skipped        %||% 0)
        retries  <- as.numeric(stats$retries_total        %||% 0)
        cost     <- as.numeric(stats$total_cost_usd       %||% 0)
        tokens   <- as.numeric(stats$total_input_tokens   %||% 0) +
                    as.numeric(stats$total_output_tokens   %||% 0)

        cost_color  <- if (cost   > 0.8)   "red" else if (cost   > 0.3) "amber" else "green"
        token_color <- if (tokens > 150000) "red" else if (tokens > 80000) "amber" else "green"

        output$statCellsApproved <- renderUI(stat_card("Approved",     approved, "green", "cells"))
        output$statCellsTotal    <- renderUI(stat_card("Planned Total", total,    "",      "cells"))
        output$statRetries       <- renderUI(stat_card("Retries",       retries,  "",      "total"))
        output$statCost          <- renderUI(stat_card("Cost (USD)",    sprintf("$%.4f", cost), cost_color, ""))
        output$statTokens        <- renderUI(stat_card("Tokens",        format(tokens, big.mark=","), token_color, ""))
        output$statSkipped       <- renderUI(stat_card("Skipped",       skipped, if (skipped > 0) "red" else "", "cells"))

        # ── Progress label + agent badge ──────────────────────────────────
        current_agent <- progress$current_agent %||% "idle"
        status_msg    <- progress$message       %||% ""

        output$progressLabel <- renderUI({
          tags$div(style = "margin-bottom:4px; font-size:12px;",
            tags$b(sprintf("Cell %d / %d", cur, total)), " \u2014 ",
            tags$span(style = "color:#667eea;", status_msg)
          )
        })

        output$agentBadge <- renderUI({
          cls <- switch(current_agent,
            writer   = "agent-badge badge-writer",
            verifier = "agent-badge badge-verifier",
            kernel   = "agent-badge badge-kernel",
            human    = "agent-badge badge-human",
            "agent-badge badge-idle"
          )
          span(class = cls, icon_for(current_agent), " ", current_agent)
        })

        # ── Human checkpoint ──────────────────────────────────────────────
        cp <- progress$checkpoint
        if (!is.null(cp) && identical(cp$waiting, TRUE)) {
          local_state$checkpoint <- cp
          output$checkpointActive <- reactive(TRUE)
          outputOptions(output, "checkpointActive", suspendWhenHidden = FALSE)
          output$checkpointContent <- renderUI({
            tagList(
              tags$p(tags$b("Explanation: "), cp$explanation %||% ""),
              tags$p(tags$span(
                class = paste0("badge-", tolower(cp$risk %||% "low")),
                "Risk: ", toupper(cp$risk %||% "low")
              )),
              tags$pre(style = "max-height:200px;overflow-y:auto;",
                       cp$code %||% "")
            )
          })
        } else {
          local_state$checkpoint <- NULL
          output$checkpointActive <- reactive(FALSE)
          outputOptions(output, "checkpointActive", suspendWhenHidden = FALSE)
        }

      }, error = function(e) {
        # Log to R console but never crash the observer
        cat("[Monitor poll error]", conditionMessage(e), "\n")
      })
    })

    # ── Checkpoint default ────────────────────────────────────────────────
    output$checkpointActive <- reactive(FALSE)
    outputOptions(output, "checkpointActive", suspendWhenHidden = FALSE)

    # ── Pause ─────────────────────────────────────────────────────────────
    observeEvent(input$pauseBtn, {
      rd <- app_state$run_dir %||% ""
      if (!nzchar(rd)) return()
      session_mgr$send_command(rd, "pause")
      local_state$paused <- TRUE
      shinyjs::disable("pauseBtn")
      shinyjs::enable("continueBtn")
      showNotification("\u23f8 Paused — takes effect after current step.", type = "warning")
    })

    # ── Continue ──────────────────────────────────────────────────────────
    observeEvent(input$continueBtn, {
      rd <- app_state$run_dir %||% ""
      if (!nzchar(rd)) return()
      session_mgr$send_command(rd, "run")
      local_state$paused <- FALSE
      shinyjs::enable("pauseBtn")
      shinyjs::disable("continueBtn")
      showNotification("\u25b6 Resuming...", type = "message")
    })

    # ── Stop ──────────────────────────────────────────────────────────────
    observeEvent(input$stopBtn, {
      rd <- app_state$run_dir %||% ""
      if (!nzchar(rd)) return()
      session_mgr$send_command(rd, "stop")
      Sys.sleep(0.5)
      python_bridge$stop_process()
      app_state$running <- FALSE
      local_state$paused <- FALSE
      shinyjs::disable("pauseBtn")
      shinyjs::disable("continueBtn")
      shinyjs::disable("stopBtn")
      showNotification("\u23f9 Run stopped.", type = "warning")
    })

    # ── Checkpoint responses ──────────────────────────────────────────────
    observeEvent(input$cpAccept, {
      rd <- app_state$run_dir %||% ""
      if (!nzchar(rd)) return()
      session_mgr$send_command(rd, "checkpoint_accept")
      showNotification("\u2713 Cell accepted.", type = "message")
    })
    observeEvent(input$cpSkip, {
      rd <- app_state$run_dir %||% ""
      if (!nzchar(rd)) return()
      session_mgr$send_command(rd, "checkpoint_skip")
      showNotification("\u23ed Cell skipped.", type = "warning")
    })
    observeEvent(input$cpAbort, {
      rd <- app_state$run_dir %||% ""
      if (!nzchar(rd)) return()
      session_mgr$send_command(rd, "stop")
      Sys.sleep(0.5)
      python_bridge$stop_process()
      app_state$running <- FALSE
      showNotification("\u23f9 Run aborted.", type = "error")
    })

    # ── Clear log ─────────────────────────────────────────────────────────
    observeEvent(input$clearLog, {
      shinyjs::html("termLog", "[display cleared]", add = FALSE)
    })

    # ── Helpers ───────────────────────────────────────────────────────────

    stat_card <- function(label, value, color = "", sub = "") {
      val_class <- trimws(paste("stat-value", color))
      div(class = "stat-card",
        div(class = "stat-label", label),
        div(class = val_class, as.character(value)),
        if (nzchar(sub)) div(class = "stat-sub", sub)
      )
    }

    icon_for <- function(agent) {
      switch(agent,
        writer   = icon("pencil-alt"),
        verifier = icon("check-double"),
        kernel   = icon("terminal"),
        human    = icon("user"),
        icon("circle")
      )
    }

    color_log <- function(text) {
      # Sanitize encoding — must happen before any regex
      text <- tryCatch(
        iconv(text, from = "", to = "UTF-8", sub = "?"),
        error = function(e) text
      )
      if (is.na(text) || !nzchar(text)) return("")

      text <- gsub("&",  "&amp;", text, fixed = TRUE)
      text <- gsub("<",  "&lt;",  text, fixed = TRUE)
      text <- gsub(">",  "&gt;",  text, fixed = TRUE)
      text <- gsub("\n", "<br>",  text, fixed = TRUE)

      # Colour by keyword (use plain ASCII markers only — safer on Windows)
      text <- gsub("(Agent 1[^<]{0,120})", "<span class='log-agent1'>\\1</span>", text)
      text <- gsub("(Agent 2[^<]{0,120})", "<span class='log-agent2'>\\1</span>", text)
      text <- gsub("(\\[\\d+:\\d+:\\d+\\] i )", "<span class='log-dim'>\\1</span>",  text)
      text <- gsub("(COMPLETE[^<]{0,80})",      "<span class='log-success'>\\1</span>", text)
      text <- gsub("(Cost limit[^<]{0,80})",    "<span class='log-warning'>\\1</span>", text)
      text <- gsub("(ERROR[^<]{0,80})",         "<span class='log-error'>\\1</span>",   text)
      text <- gsub("(WARNING[^<]{0,80})",       "<span class='log-warning'>\\1</span>", text)
      text
    }
  })
}
