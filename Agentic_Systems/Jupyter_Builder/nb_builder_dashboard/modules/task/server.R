# ============================================================================
# TASK MODULE - SERVER
# ============================================================================

task_server <- function(id, session_mgr, python_bridge, app_state, session) {
  moduleServer(id, function(input, output, session) {

    # ── Populate session dropdown on load ──────────────────────────────────
    observe({
      runs_dir <- session_mgr$get("runs_dir", "runs")
      runs     <- session_mgr$list_runs(runs_dir)
      choices  <- c("— new run —" = "")
      if (length(runs) > 0) choices <- c(choices, setNames(runs, basename(runs)))
      updateSelectInput(session, "loadSession", choices = choices)
    })

    # ── Load spec from file ────────────────────────────────────────────────
    observeEvent(input$specFile, {
      req(input$specFile)
      txt <- paste(readLines(input$specFile$datapath, warn = FALSE), collapse = "\n")
      updateTextAreaInput(session, "spec", value = txt)
    })

    # ── Load spec from existing run ────────────────────────────────────────
    observeEvent(input$loadSession, {
      run_dir <- input$loadSession
      if (!nzchar(run_dir)) return()
      state <- session_mgr$load_run_state(run_dir)
      if (!is.null(state$spec)) {
        updateTextAreaInput(session, "spec", value = state$spec)
        app_state$run_dir  <- run_dir
        app_state$plan     <- state$task_plan
        app_state$resuming <- TRUE
        render_plan(state$task_plan)
        shinyjs::enable("runBtn")
        showNotification(paste("Session loaded:", basename(run_dir)), type = "message")
      }
    })

    # ── Plan button ────────────────────────────────────────────────────────
    observeEvent(input$planBtn, {
      spec <- trimws(input$spec)
      if (!nzchar(spec)) { showNotification("Please enter a specification.", type = "warning"); return() }
      cfg <- session_mgr$config
      if (!nzchar(trimws(cfg$anthropic_api_key %||% ""))) {
        showNotification("Set your Claude API key in Settings first.", type = "error"); return()
      }

      # Check context dir exists — files are loaded IN FULL by Python, no truncation
      ctx_dir <- cfg$context_dir %||% ""
      if (nzchar(ctx_dir) && dir.exists(ctx_dir)) {
        files <- list.files(ctx_dir, full.names = TRUE)
        total_chars <- sum(sapply(files, function(f) {
          tryCatch(nchar(paste(readLines(f, warn = FALSE), collapse = "\n")), error = function(e) 0)
        }))
        cat("  Context dir:", ctx_dir, "— total chars:", format(total_chars, big.mark=","), "\n")
      }

      output$planOutput <- renderUI({
        div(class = "info-box", icon("spinner"), " Agent 1 is analysing your spec...")
      })

      result <- tryCatch({
        py_script <- file.path(getwd(), "python", "planner.py")
        cfg_tmp   <- tempfile(fileext = ".json")
        jsonlite::write_json(
          list(spec        = spec,
               api_key     = cfg$anthropic_api_key,
               model       = cfg$claude_model %||% "claude-opus-4-5",
               context_dir = cfg$context_dir %||% ""),
          cfg_tmp, auto_unbox = TRUE
        )
        # Timeout 600s — allows up to ~5 rate-limit retries (60+120+240s waits)
        out <- processx::run(python_bridge$python_path,
                             args = c(py_script, "--config", cfg_tmp),
                             timeout = 600, error_on_status = FALSE)
        file.remove(cfg_tmp)
        # Log stderr (progress/retry messages) to R console
        if (nzchar(trimws(out$stderr))) cat(out$stderr)
        # stdout is always the JSON plan (or {"error":"..."})
        stdout_clean <- trimws(out$stdout)
        if (!nzchar(stdout_clean)) {
          list(error = paste("Planner produced no output.", trimws(out$stderr)))
        } else {
          parsed <- tryCatch(
            jsonlite::fromJSON(stdout_clean, simplifyVector = FALSE),
            error = function(e) list(error = paste("JSON parse error:", e$message,
                                                    "— stdout:", substr(stdout_clean, 1, 300)))
          )
          parsed
        }
      }, error = function(e) list(error = e$message))

      # result$error can come from {"error":"..."} in JSON or from tryCatch
      err_msg <- result$error %||% ""
      if (nzchar(trimws(err_msg))) {
        output$planOutput <- renderUI({
          div(class = "info-box", icon("exclamation-triangle"),
              tags$b("Planning failed: "), tags$br(),
              tags$code(style="font-size:11px; white-space:pre-wrap;", err_msg))
        })
        return()
      }

      app_state$plan <- result
      render_plan(result)
      shinyjs::enable("runBtn")
    })

    # ── Helper: render plan table ──────────────────────────────────────────
    render_plan <- function(plan) {
      if (is.null(plan) || length(plan) == 0) return()
      outline <- plan$outline %||% list()
      total   <- plan$total_cells_estimate %||% length(outline)
      notes   <- plan$context_notes %||% ""

      rows <- lapply(outline, function(item) {
        cplx  <- item$complexity %||% "low"
        badge <- switch(cplx,
          "low"    = tags$span(class = "badge-low",    "low"),
          "medium" = tags$span(class = "badge-medium", "medium"),
          "high"   = tags$span(class = "badge-high",   "high"),
          tags$span(cplx)
        )
        pkgs_list <- item$packages %||% character(0)
        pkgs_html <- if (length(pkgs_list) == 0) {
          tags$span(class = "text-muted", "\u2014")
        } else {
          tags$span(style = "font-size:11px; line-height:2;",
            lapply(pkgs_list, function(p) tagList(tags$code(p), tags$br()))
          )
        }
        tags$tr(
          tags$td(style = "width:36px; text-align:center; vertical-align:top; padding-top:10px;", item$cell),
          tags$td(style = "white-space:normal; vertical-align:top; padding-top:10px; font-weight:500;", item$title),
          tags$td(style = "white-space:normal; vertical-align:top; padding-top:8px;", pkgs_html),
          tags$td(style = "width:80px; vertical-align:top; padding-top:10px; text-align:center;", badge)
        )
      })

      output$planOutput <- renderUI({
        tagList(
          tags$p(tags$b("Estimated cells: "),
                 tags$span(class = "badge badge-primary", style = "font-size:14px;", total)),
          tags$div(style = "overflow-x:auto;",
            tags$table(class = "plan-table",
              tags$thead(tags$tr(
                tags$th("#"), tags$th("Cell"), tags$th("Packages"), tags$th("Complexity")
              )),
              tags$tbody(rows)
            )
          ),
          if (nzchar(notes))
            div(class = "info-box", style = "margin-top:10px;", icon("info-circle"), " ", notes)
        )
      })
    }

    # ── Run button — launch Python process ─────────────────────────────────
    observeEvent(input$runBtn, ignoreInit = TRUE, {
      # ── GUARD: prevent double-launch ──────────────────────────────────────
      if (python_bridge$is_running()) {
        showNotification(
          "A run is already in progress. Stop it in the Monitor tab first.",
          type = "warning"
        )
        return()
      }

      spec <- trimws(input$spec)
      cfg  <- session_mgr$config

      if (!nzchar(spec))                          { showNotification("Spec is empty.", type = "warning"); return() }
      if (!nzchar(trimws(cfg$anthropic_api_key %||% ""))) {
        showNotification("Set your Claude API key in Settings first.", type = "error"); return()
      }

      # Disable buttons immediately to prevent double-click
      shinyjs::disable("runBtn")
      shinyjs::disable("planBtn")

      if (isTRUE(app_state$resuming) && nzchar(app_state$run_dir %||% "")) {
        run_dir <- app_state$run_dir
        python_bridge$resume(run_dir, cfg$anthropic_api_key)
      } else {
        slug    <- gsub("[^a-z0-9]+", "-", tolower(substr(spec, 1, 40)))
        ts      <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
        run_dir <- file.path(cfg$runs_dir, paste0(ts, "_", slug))
        dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

        python_bridge$launch(
          spec             = spec,
          run_dir          = run_dir,
          api_key          = cfg$anthropic_api_key,
          model            = cfg$claude_model %||% "claude-opus-4-5",
          context_dir      = cfg$context_dir %||% "",
          max_cost         = as.numeric(cfg$max_cost_usd %||% 2.0),
          max_tokens       = as.numeric(cfg$max_tokens %||% 200000),
          max_retries      = as.integer(cfg$max_retries_per_cell %||% 3),
          max_consec_fails = as.integer(cfg$max_consec_fails %||% 3),
          review_every     = as.logical(cfg$review_every_cell %||% FALSE),
          kernel_name      = cfg$kernel_name %||% "python3"
        )
      }

      app_state$run_dir  <- run_dir
      app_state$running  <- TRUE
      app_state$resuming <- FALSE

      cfg$last_run_dir <- run_dir
      session_mgr$save_config(cfg)

      showNotification(
        paste0("\u2713 Run started (PID ", python_bridge$get_pid(), ") \u2014 go to Monitor tab."),
        type = "message", duration = 5
      )
    })

    # ── Re-enable buttons when run finishes ───────────────────────────────
    observe({
      if (!isTRUE(app_state$running)) {
        shinyjs::enable("planBtn")
        shinyjs::enable("runBtn")
      }
    })

    # ── Run Info ───────────────────────────────────────────────────────────
    output$runInfo <- renderUI({
      rd  <- app_state$run_dir %||% ""
      pid <- tryCatch(python_bridge$get_pid(), error = function(e) NA)
      tagList(
        if (nzchar(rd)) {
          tags$p(tags$b("Run folder:"), br(),
                 tags$code(style = "font-size:10px; word-break:break-all;", rd))
        } else {
          div(class = "info-box", "No active run.")
        },
        tags$p(
          tags$b("Status: "),
          if (isTRUE(app_state$running))
            tags$span(class = "badge badge-success", "Running")
          else
            tags$span(class = "badge badge-secondary", "Idle")
        ),
        if (!is.na(pid))
          tags$p(tags$b("PID: "), tags$code(as.character(pid)))
      )
    })
  })
}
