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
      if (length(runs) > 0) {
        choices <- c(choices, setNames(runs, basename(runs)))
      }
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
      if (nchar(run_dir) == 0) return()
      state <- session_mgr$load_run_state(run_dir)
      if (!is.null(state$spec)) {
        updateTextAreaInput(session, "spec", value = state$spec)
        app_state$run_dir   <- run_dir
        app_state$plan      <- state$task_plan
        app_state$resuming  <- TRUE
        render_plan(state$task_plan)
        shinyjs::enable("runBtn")
        showNotification(paste("Session loaded:", basename(run_dir)), type = "message")
      }
    })

    # ── Plan button — calls Python planner inline ──────────────────────────
    observeEvent(input$planBtn, {
      spec <- trimws(input$spec)
      if (nchar(spec) == 0) {
        showNotification("Please enter a specification first.", type = "warning")
        return()
      }

      cfg <- session_mgr$config
      if (nchar(trimws(cfg$anthropic_api_key)) == 0) {
        showNotification("Set your Claude API key in Settings first.", type = "error")
        return()
      }

      output$planOutput <- renderUI({
        div(class = "info-box", icon("spinner"), " Agent 1 is analysing your spec...")
      })

      # Call Python planner synchronously (short call, ~5s)
      result <- tryCatch({
        py_script <- file.path(getwd(), "python", "planner.py")
        cfg_tmp   <- tempfile(fileext = ".json")
        jsonlite::write_json(
          list(spec = spec, api_key = cfg$anthropic_api_key,
               model = cfg$claude_model,
               context_dir = cfg$context_dir),
          cfg_tmp, auto_unbox = TRUE
        )
        out <- processx::run(
          python_bridge$python_path,
          args     = c(py_script, "--config", cfg_tmp),
          timeout  = 60,
          error_on_status = FALSE
        )
        file.remove(cfg_tmp)
        if (out$status == 0) {
          jsonlite::fromJSON(trimws(out$stdout), simplifyVector = FALSE)
        } else {
          list(error = out$stderr)
        }
      }, error = function(e) list(error = e$message))

      if (!is.null(result$error)) {
        output$planOutput <- renderUI({
          div(class = "info-box", icon("exclamation-triangle"),
              tags$b("Planning failed: "), result$error)
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
        pkgs <- paste(item$packages %||% character(0), collapse = ", ")
        tags$tr(
          tags$td(item$cell), tags$td(item$title), tags$td(pkgs), tags$td(badge)
        )
      })

      output$planOutput <- renderUI({
        tagList(
          tags$p(tags$b("Estimated cells: "), tags$span(class = "badge badge-primary", total)),
          tags$table(class = "plan-table",
            tags$thead(tags$tr(
              tags$th("#"), tags$th("Cell"), tags$th("Packages"), tags$th("Complexity")
            )),
            tags$tbody(rows)
          ),
          if (nchar(notes) > 0) div(class = "info-box", style = "margin-top:8px", icon("info-circle"), " ", notes)
        )
      })
    }

    # ── Run button — launch Python process ─────────────────────────────────
    observeEvent(input$runBtn, {
      spec <- trimws(input$spec)
      cfg  <- session_mgr$config

      if (nchar(spec) == 0) { showNotification("Spec is empty.", type = "warning"); return() }
      if (nchar(trimws(cfg$anthropic_api_key)) == 0) {
        showNotification("Set your Claude API key in Settings first.", type = "error"); return()
      }

      # Build run_dir
      if (isTRUE(app_state$resuming) && nchar(app_state$run_dir %||% "") > 0) {
        run_dir <- app_state$run_dir
        python_bridge$resume(run_dir, cfg$anthropic_api_key)
      } else {
        slug    <- gsub("[^a-z0-9]+", "-", tolower(substr(spec, 1, 40)))
        ts      <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
        run_dir <- file.path(cfg$runs_dir, paste0(ts, "_", slug))
        dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

        py_path <- trimws(cfg$python_env_path)
        python_bridge$launch(
          spec           = spec,
          run_dir        = run_dir,
          api_key        = cfg$anthropic_api_key,
          model          = cfg$claude_model,
          context_dir    = cfg$context_dir,
          max_cost       = cfg$max_cost_usd,
          max_tokens     = cfg$max_tokens,
          max_retries    = cfg$max_retries_per_cell,
          max_consec_fails = cfg$max_consec_fails,
          review_every   = cfg$review_every_cell,
          kernel_name    = cfg$kernel_name %||% "python3"
        )
      }

      app_state$run_dir  <- run_dir
      app_state$running  <- TRUE
      app_state$resuming <- FALSE

      # Persist last_run_dir
      cfg$last_run_dir <- run_dir
      session_mgr$save_config(cfg)

      showNotification("✓ Python process launched — go to Monitor tab.", type = "message")
    })

    # ── Run Info ───────────────────────────────────────────────────────────
    output$runInfo <- renderUI({
      rd <- app_state$run_dir %||% ""
      if (nchar(rd) == 0) return(div(class = "info-box", "No active run."))
      tagList(
        tags$p(tags$b("Run folder:"), br(), tags$code(style = "font-size:11px", rd)),
        tags$p(tags$b("Status: "),
               if (isTRUE(app_state$running)) tags$span(class = "badge badge-success", "Running")
               else tags$span(class = "badge badge-secondary", "Idle"))
      )
    })
  })
}
