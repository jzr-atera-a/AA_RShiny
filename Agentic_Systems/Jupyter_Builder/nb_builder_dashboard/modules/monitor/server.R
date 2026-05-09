# ============================================================================
# MONITOR MODULE - SERVER
# Polls progress.json + run.log every 2s, drives all live UI
# ============================================================================

monitor_server <- function(id, session_mgr, python_bridge, app_state, session) {
  moduleServer(id, function(input, output, session) {

    # ── Local reactive state ───────────────────────────────────────────────
    local_state <- reactiveValues(
      paused     = FALSE,
      log_lines  = character(0),
      checkpoint = NULL   # NULL or list(explanation, code, risk)
    )

    # ── Polling timer ──────────────────────────────────────────────────────
    poll_timer <- reactiveTimer(2000)   # 2-second poll

    observe({
      poll_timer()
      rd <- app_state$run_dir %||% ""
      if (nchar(rd) == 0) return()

      progress <- session_mgr$load_progress(rd)
      log_text  <- session_mgr$load_log(rd, tail_n = 300)

      # Update log pane
      if (nchar(log_text) > 0) {
        local_state$log_lines <- strsplit(log_text, "\n")[[1]]
        shinyjs::html("termLog", color_log(log_text), add = FALSE)
        shinyjs::runjs(
          paste0("var el = document.getElementById('", session$ns("termLog"), "');",
                 "if(el) el.scrollTop = el.scrollHeight;")
        )
      }

      if (is.null(progress)) return()

      # ── Progress bar ─────────────────────────────────────────────────────
      cur   <- progress$cell_current %||% 0
      total <- progress$plan_total   %||% 1
      pct   <- round(min(100, cur / max(total, 1) * 100))
      shinyjs::runjs(paste0(
        "var pb = document.getElementById('", session$ns("progressBar"), "');",
        "if(pb){ pb.style.width='", pct, "%';",
        "        pb.setAttribute('aria-valuenow','", pct, "'); }"
      ))

      # ── Process alive / done ──────────────────────────────────────────────
      is_alive <- python_bridge$is_running()
      app_state$running <- is_alive

      if (is_alive && !local_state$paused) {
        shinyjs::enable("pauseBtn"); shinyjs::enable("stopBtn")
        shinyjs::disable("continueBtn")
      } else if (local_state$paused) {
        shinyjs::enable("continueBtn"); shinyjs::enable("stopBtn")
        shinyjs::disable("pauseBtn")
      } else {
        shinyjs::disable("pauseBtn"); shinyjs::disable("continueBtn"); shinyjs::disable("stopBtn")
        if (progress$status %||% "" == "done") {
          showNotification("✓ Notebook build complete!", type = "message")
        }
      }

      # ── Stats cards ──────────────────────────────────────────────────────
      stats <- progress$stats %||% list()
      approved <- stats$cells_approved  %||% 0
      skipped  <- stats$cells_skipped   %||% 0
      retries  <- stats$retries_total   %||% 0
      cost     <- stats$total_cost_usd  %||% 0
      tokens   <- (stats$total_input_tokens %||% 0) + (stats$total_output_tokens %||% 0)

      cost_color  <- if (cost  > 0.8) "red"   else if (cost  > 0.3) "amber" else "green"
      token_color <- if (tokens > 150000) "red" else if (tokens > 80000) "amber" else "green"

      output$statCellsApproved <- renderUI(stat_card("Approved",     approved,       "green",      "cells"))
      output$statCellsTotal    <- renderUI(stat_card("Planned Total", total,          "",           "cells"))
      output$statRetries       <- renderUI(stat_card("Retries",       retries,        "",           "total"))
      output$statCost          <- renderUI(stat_card("Cost (USD)",    sprintf("$%.4f", cost), cost_color, ""))
      output$statTokens        <- renderUI(stat_card("Tokens",        format(tokens, big.mark=","), token_color, ""))
      output$statSkipped       <- renderUI(stat_card("Skipped",       skipped,        if(skipped>0)"red" else "", "cells"))

      # ── Progress label ────────────────────────────────────────────────────
      current_agent <- progress$current_agent %||% "idle"
      status_msg    <- progress$message       %||% ""
      output$progressLabel <- renderUI({
        tags$div(style = "margin-bottom:4px; font-size:12px;",
          tags$b(sprintf("Cell %d / %d", cur, total)), " — ", status_msg
        )
      })

      output$agentBadge <- renderUI({
        cls <- switch(current_agent,
          "writer"   = "agent-badge badge-writer",
          "verifier" = "agent-badge badge-verifier",
          "kernel"   = "agent-badge badge-kernel",
          "human"    = "agent-badge badge-human",
          "agent-badge badge-idle"
        )
        span(class = cls, icon_for(current_agent), " ", current_agent)
      })

      # ── Human checkpoint ──────────────────────────────────────────────────
      cp <- progress$checkpoint
      if (!is.null(cp) && identical(cp$waiting, TRUE)) {
        local_state$checkpoint <- cp
        output$checkpointActive <- reactive(TRUE)
        outputOptions(output, "checkpointActive", suspendWhenHidden = FALSE)
        output$checkpointContent <- renderUI({
          tagList(
            tags$p(tags$b("Cell explanation: "), cp$explanation %||% ""),
            tags$p(tags$span(class = paste0("badge-", tolower(cp$risk %||% "low")),
                   "Risk: ", cp$risk %||% "low")),
            tags$pre(cp$code %||% "")
          )
        })
      } else {
        local_state$checkpoint <- NULL
        output$checkpointActive <- reactive(FALSE)
        outputOptions(output, "checkpointActive", suspendWhenHidden = FALSE)
      }
    })

    # ── Checkpoint: False by default ──────────────────────────────────────
    output$checkpointActive <- reactive(FALSE)
    outputOptions(output, "checkpointActive", suspendWhenHidden = FALSE)

    # ── Pause ─────────────────────────────────────────────────────────────
    observeEvent(input$pauseBtn, {
      rd <- app_state$run_dir %||% ""; if (nchar(rd) == 0) return()
      session_mgr$send_command(rd, "pause")
      local_state$paused <- TRUE
      shinyjs::disable("pauseBtn"); shinyjs::enable("continueBtn")
      showNotification("⏸ Paused (will take effect after current step).", type = "warning")
    })

    # ── Continue ──────────────────────────────────────────────────────────
    observeEvent(input$continueBtn, {
      rd <- app_state$run_dir %||% ""; if (nchar(rd) == 0) return()
      session_mgr$send_command(rd, "run")
      local_state$paused <- FALSE
      shinyjs::enable("pauseBtn"); shinyjs::disable("continueBtn")
      showNotification("▶ Resuming...", type = "message")
    })

    # ── Stop ──────────────────────────────────────────────────────────────
    observeEvent(input$stopBtn, {
      rd <- app_state$run_dir %||% ""; if (nchar(rd) == 0) return()
      session_mgr$send_command(rd, "stop")
      Sys.sleep(1)
      python_bridge$stop_process()
      app_state$running <- FALSE
      local_state$paused <- FALSE
      shinyjs::disable("pauseBtn"); shinyjs::disable("continueBtn"); shinyjs::disable("stopBtn")
      showNotification("⏹ Run stopped.", type = "warning")
    })

    # ── Checkpoint responses ──────────────────────────────────────────────
    observeEvent(input$cpAccept, {
      rd <- app_state$run_dir %||% ""; if (nchar(rd) == 0) return()
      session_mgr$send_command(rd, "checkpoint_accept")
      showNotification("✓ Cell accepted.", type = "message")
    })
    observeEvent(input$cpSkip, {
      rd <- app_state$run_dir %||% ""; if (nchar(rd) == 0) return()
      session_mgr$send_command(rd, "checkpoint_skip")
      showNotification("⏭ Cell skipped.", type = "warning")
    })
    observeEvent(input$cpAbort, {
      rd <- app_state$run_dir %||% ""; if (nchar(rd) == 0) return()
      session_mgr$send_command(rd, "stop")
      Sys.sleep(1)
      python_bridge$stop_process()
      app_state$running <- FALSE
      showNotification("⏹ Run aborted.", type = "error")
    })

    # ── Clear log display ─────────────────────────────────────────────────
    observeEvent(input$clearLog, {
      local_state$log_lines <- character(0)
      shinyjs::html("termLog", "Display cleared.", add = FALSE)
    })

    # ── Helpers ───────────────────────────────────────────────────────────

    stat_card <- function(label, value, color = "", sub = "") {
      val_class <- paste("stat-value", color)
      div(class = "stat-card",
        div(class = "stat-label", label),
        div(class = val_class, as.character(value)),
        if (nchar(sub) > 0) div(class = "stat-sub", sub)
      )
    }

    icon_for <- function(agent) {
      switch(agent,
        "writer"   = icon("pencil-alt"),
        "verifier" = icon("check-double"),
        "kernel"   = icon("terminal"),
        "human"    = icon("user"),
        icon("circle")
      )
    }

    color_log <- function(text) {
      # Simple ANSI-free coloring for terminal pane
      text <- gsub("&", "&amp;", text)
      text <- gsub("<", "&lt;",  text)
      text <- gsub(">", "&gt;",  text)
      text <- gsub("\n", "<br>", text)
      text <- gsub("(Agent 1[^<]*)", "<span class='log-agent1'>\\1</span>", text)
      text <- gsub("(Agent 2[^<]*)", "<span class='log-agent2'>\\1</span>", text)
      text <- gsub("([✓✅][^<]*)", "<span class='log-success'>\\1</span>", text)
      text <- gsub("([✗❌][^<]*)", "<span class='log-error'>\\1</span>",   text)
      text <- gsub("([⚠⏸][^<]*)", "<span class='log-warning'>\\1</span>", text)
      text <- gsub("(⚙[^<]*)",    "<span class='log-kernel'>\\1</span>",  text)
      text
    }
  })
}
