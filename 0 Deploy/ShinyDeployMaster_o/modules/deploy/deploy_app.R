# modules/deploy/deploy_app.R  —  ShinyDeployMaster v2
# The heavy lifting lives in worker/deploy_worker.R (separate Rscript process).
# This module only: validates inputs, writes a JSON config, launches the
# worker, streams its output, and cleans up. No per-app package lists anywhere.

deploy_app_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("\U0001f680 Deploy App"),
        tags$h2("Deploy any uploaded Shiny app to shinyapps.io"),
        div(span(class = "hero-badge", "rsconnect"),
            span(class = "hero-badge", "Auto-installs missing packages"),
            span(class = "hero-badge", "Startup verified"))
    ),
    fluidRow(
      column(3, div(class = "metric-card", span(class = "metric-value", uiOutput(ns("status_auth"))),    span(class = "metric-label", "Authentication"))),
      column(3, div(class = "metric-card", span(class = "metric-value", uiOutput(ns("status_upload"))),  span(class = "metric-label", "App Uploaded"))),
      column(3, div(class = "metric-card", span(class = "metric-value", uiOutput(ns("status_deploy"))),  span(class = "metric-label", "Deploy Status"))),
      column(3, div(class = "metric-card", span(class = "metric-value", textOutput(ns("status_appname"))), span(class = "metric-label", "App Name")))
    ),
    br(),
    fluidRow(
      box(title = "\u2699\ufe0f Deployment Configuration", status = "primary", solidHeader = TRUE, width = 4,
          div(class = "section-heading-dark", "shinyapps.io App Name"),
          textInput(ns("app_name"), NULL, placeholder = "e.g. booksnetworksstrategysixs"),
          div(class = "tip-box", HTML(
            "4\u201363 characters: letters, numbers, <code>-</code> or <code>_</code>.<br>",
            "Use the <strong>existing</strong> name to update an app in place."
          )),
          br(),
          div(class = "section-heading-dark", "Options"),
          checkboxInput(ns("opt_force"), tagList(icon("redo"), " Update existing app if the name is taken"), value = TRUE),
          checkboxInput(ns("opt_dry"), tagList(icon("vial"), " Test only \u2014 build manifest, don't upload"), value = FALSE),
          checkboxInput(ns("opt_unresolved"), tagList(icon("exclamation-triangle"), " Deploy anyway if some packages can't be found"), value = FALSE),
          br(),
          actionButton(ns("btn_preflight"), tagList(icon("check-circle"), " Pre-flight Check"), class = "btn-info btn-block"),
          br(),
          uiOutput(ns("preflight_result")),
          br(),
          uiOutput(ns("deploy_btn_ui")),
          br(),
          actionButton(ns("btn_abort"), tagList(icon("stop-circle"), " Abort"), class = "btn-warning btn-block"),
          br(),
          actionButton(ns("btn_clear_console"), tagList(icon("trash"), " Clear Console"), class = "btn-block")
      ),
      box(title = "\U0001f5a5\ufe0f Live Deployment Console", status = "success", solidHeader = TRUE, width = 8,
          tags$div(
            id = ns("console_scroll"),
            style = paste0("background:#060D18;border-radius:10px;padding:16px 18px;",
                           "height:520px;overflow-y:auto;",
                           "font-family:'JetBrains Mono',monospace;font-size:12px;"),
            uiOutput(ns("console_output"))
          ),
          br(),
          fluidRow(
            column(6, div(class = "tip-box", HTML(
              "<strong style='color:#16A34A'>Green</strong>=ok &nbsp; <strong style='color:#DC2626'>Red</strong>=failure &nbsp; ",
              "<strong style='color:#CA8A04'>Yellow</strong>=warning &nbsp; <strong style='color:#EA580C'>Orange</strong>=step"
            ))),
            column(6, uiOutput(ns("deploy_complete_panel")))
          )
      )
    ),
    fluidRow(
      box(title = "\U0001f4cb Deployment Plan (no secrets)", status = "warning",
          solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          div(class = "code-box", style = "max-height:260px;overflow-y:auto;",
              verbatimTextOutput(ns("deploy_plan_preview"))))
    ),
    tags$script(HTML(sprintf(
      "Shiny.addCustomMessageHandler('scroll_console_%s', function(id) {
         var el = document.getElementById(id);
         if (el) el.scrollTop = el.scrollHeight;
       });", id
    )))
  )
}

deploy_app_server <- function(id, deploy_mgr) {
  moduleServer(id, function(input, output, session) {

    ns          <- session$ns
    deploy_proc <- reactiveVal(NULL)
    run_info    <- reactiveValues(cfg_file = NULL, cred_dir = NULL, dry = FALSE, url = NULL, exit = NULL)

    APP_NAME_RE <- "^[A-Za-z0-9_-]{4,63}$"
    app_name_val <- reactive(trimws(input$app_name %||% ""))
    app_name_ok  <- reactive(grepl(APP_NAME_RE, app_name_val()))
    app_dir_ok   <- function() !is.null(deploy_mgr$detected_app_dir) && dir.exists(deploy_mgr$detected_app_dir)

    # Pre-fill the app name from the uploaded zip (only if the box is empty)
    observe({
      deploy_mgr$debug_trigger()
      sug <- isolate(deploy_mgr$app_name)
      if (!is.null(sug) && !nzchar(isolate(input$app_name %||% "")))
        updateTextInput(session, "app_name", value = sug)
    })

    # ── Status tiles ───────────────────────────────────────────────────
    output$status_auth <- renderUI({
      deploy_mgr$debug_trigger()
      if (isTRUE(deploy_mgr$authenticated)) span(style = "color:#4ADE80;", "\u2713")
      else span(style = "color:#F87171;", "\u2717")
    })
    output$status_upload <- renderUI({
      deploy_mgr$debug_trigger()
      if (app_dir_ok()) span(style = "color:#4ADE80;", "\u2713") else span(style = "color:#F87171;", "\u2717")
    })
    output$status_deploy <- renderUI({
      deploy_mgr$status_trigger()
      switch(deploy_mgr$deploy_status,
        idle    = span(style = "color:#94A3B8;font-size:.9em;", "idle"),
        running = span(style = "color:#FCD34D;", "\u23f3"),
        success = span(style = "color:#4ADE80;", "\u2713"),
        error   = span(style = "color:#F87171;", "\u2717"),
        span(deploy_mgr$deploy_status))
    })
    output$status_appname <- renderText(if (nzchar(app_name_val())) app_name_val() else "\u2014")

    output$deploy_btn_ui <- renderUI({
      deploy_mgr$debug_trigger(); deploy_mgr$status_trigger()
      ready <- (isTRUE(deploy_mgr$authenticated) || isTRUE(input$opt_dry)) &&
               app_dir_ok() && app_name_ok() && deploy_mgr$deploy_status != "running"
      label <- if (isTRUE(input$opt_dry)) " Run Test Build" else " Deploy to shinyapps.io"
      if (ready)
        actionButton(ns("btn_deploy"), tagList(icon("rocket"), label), class = "btn-primary btn-lg btn-block")
      else
        tags$button(class = "btn btn-default btn-block disabled", style = "cursor:not-allowed;opacity:.5;",
                    icon("rocket"), label)
    })

    # ── Pre-flight: environment + package scan (read-only, fast) ───────
    observeEvent(input$btn_preflight, {
      checks <- list(
        auth = list(ok = isTRUE(deploy_mgr$authenticated),
                    msg = if (isTRUE(deploy_mgr$authenticated)) paste("Authenticated as:", deploy_mgr$account_name)
                          else "Not authenticated (only 'Test only' mode will run)"),
        app_dir = list(ok = app_dir_ok(),
                       msg = if (app_dir_ok()) paste("App dir:", basename(deploy_mgr$detected_app_dir)) else "No app uploaded"),
        app_name = list(ok = app_name_ok(),
                        msg = if (app_name_ok()) paste("App name:", app_name_val())
                              else "App name must be 4\u201363 chars: letters, numbers, - or _"),
        worker = list(ok = file.exists(SDM_WORKER), msg = paste("Worker script:", if (file.exists(SDM_WORKER)) "found" else "MISSING")),
        rsconnect = list(ok = requireNamespace("rsconnect", quietly = TRUE),
                         msg = paste("rsconnect", tryCatch(as.character(packageVersion("rsconnect")), error = function(e) "not found"))),
        renv = list(ok = requireNamespace("renv", quietly = TRUE),
                    msg = paste("renv", tryCatch(as.character(packageVersion("renv")), error = function(e) "not found")))
      )

      pkg_rows <- NULL
      if (app_dir_ok() && checks$renv$ok) {
        deps <- tryCatch(renv::dependencies(deploy_mgr$detected_app_dir, root = deploy_mgr$detected_app_dir,
                                            progress = FALSE, quiet = TRUE),
                         error = function(e) NULL)
        if (!is.null(deps)) {
          base <- c(rownames(installed.packages(priority = "base")), "R")
          direct <- sort(setdiff(unique(deps$Package), base))
          have <- vapply(direct, function(p) nzchar(system.file(package = p, lib.loc = c(SDM_LIB_DIR, .libPaths()))), logical(1))
          checks$packages <- list(ok = TRUE, msg = sprintf("%d packages used by the app; %d already here, %d will be installed at deploy time",
                                                           length(direct), sum(have), sum(!have)))
          pkg_rows <- div(style = "font-size:12px;margin-top:6px;",
            tags$strong("Detected packages: "),
            lapply(direct, function(p) span(
              style = paste0("display:inline-block;margin:2px;padding:1px 7px;border-radius:9px;",
                             if (have[[p]]) "background:#DCFCE7;color:#166534;" else "background:#FEF3C7;color:#92400E;"),
              p)),
            div(style = "color:#6B7280;margin-top:4px;", "Green = available now \u2022 Amber = installed automatically during deploy"))
        }
      }

      for (nm in names(checks))
        deploy_mgr$log("DEPLOY", paste0("[preflight] [", nm, "] ", checks[[nm]]$msg),
                       if (checks[[nm]]$ok) "success" else "warn")

      output$preflight_result <- renderUI({
        all_ok <- all(vapply(checks, `[[`, logical(1), "ok"))
        rows <- lapply(names(checks), function(nm) {
          ck <- checks[[nm]]
          div(style = "display:flex;gap:8px;margin:4px 0;",
              span(style = paste0("color:", if (ck$ok) "#4ADE80" else "#FCD34D", ";font-weight:700;min-width:16px;"),
                   if (ck$ok) "\u2713" else "\u26a0"),
              span(style = "font-size:12.5px;color:#374151;", ck$msg))
        })
        div(if (all_ok) div(class = "success-box", HTML("\u2705 <strong>All checks passed.</strong>"))
            else div(class = "warn-box", HTML("\u26a0 Some checks need attention.")),
            br(), do.call(tagList, rows), pkg_rows)
      })
    })

    build_config <- function(dry) {
      list(
        app_dir          = deploy_mgr$detected_app_dir,
        app_name         = app_name_val(),
        account          = deploy_mgr$account_name %||% "",
        server           = "shinyapps.io",
        force_update     = isTRUE(input$opt_force),
        allow_unresolved = isTRUE(input$opt_unresolved),
        dry_run          = dry,
        lib_dir          = SDM_LIB_DIR,
        install_repo     = Sys.getenv("SDM_INSTALL_REPO"),   # optional override
        manifest_repo    = if (nzchar(Sys.getenv("SDM_MANIFEST_REPO"))) Sys.getenv("SDM_MANIFEST_REPO")
                           else "https://cloud.r-project.org"
      )
    }

    output$deploy_plan_preview <- renderText({
      deploy_mgr$debug_trigger()
      if (!app_dir_ok() || !app_name_ok()) return("\u2014 Upload an app and enter a valid app name to preview \u2014")
      cfg <- build_config(isTRUE(input$opt_dry))
      paste0(
        "Worker : ", SDM_WORKER, "\n",
        "Rscript: ", file.path(R.home("bin"), "Rscript"), "\n",
        "Config :\n", jsonlite::toJSON(cfg, auto_unbox = TRUE, pretty = TRUE), "\n\n",
        "Credentials are passed as environment variables only and never written to this plan."
      )
    })

    # ── Launch ─────────────────────────────────────────────────────────
    cleanup_run <- function() {
      if (!is.null(run_info$cfg_file) && file.exists(run_info$cfg_file)) unlink(run_info$cfg_file)
      if (!is.null(run_info$cred_dir) && dir.exists(run_info$cred_dir)) unlink(run_info$cred_dir, recursive = TRUE)
      run_info$cfg_file <- NULL; run_info$cred_dir <- NULL
    }

    observeEvent(input$btn_deploy, {
      dry <- isTRUE(input$opt_dry)
      req(app_dir_ok(), app_name_ok(), dry || isTRUE(deploy_mgr$authenticated))
      if (!is.null(deploy_proc())) return()

      cfg_file <- tempfile("sdm_cfg_", fileext = ".json")
      cred_dir <- tempfile("sdm_cred_")          # isolates rsconnect's account store per run
      dir.create(cred_dir)
      jsonlite::write_json(build_config(dry), cfg_file, auto_unbox = TRUE)
      run_info$cfg_file <- cfg_file; run_info$cred_dir <- cred_dir
      run_info$dry <- dry; run_info$url <- NULL; run_info$exit <- NULL

      deploy_mgr$log("DEPLOY", if (dry) "Starting TEST build (no upload)..." else paste("Starting deployment of", app_name_val()), "cmd")
      deploy_mgr$set_status("running")

      tryCatch({
        proc <- processx::process$new(
          command = file.path(R.home("bin"), "Rscript"),   # same R as this app
          args    = c(SDM_WORKER, cfg_file),
          stdout  = "|",
          stderr  = "2>&1",                                # keep ordering with stdout
          env     = c("current",
                      RSDEPLOY_TOKEN    = deploy_mgr$account_token  %||% "",
                      RSDEPLOY_SECRET   = deploy_mgr$account_secret %||% "",
                      R_USER_CONFIG_DIR = cred_dir,
                      R_USER_DATA_DIR   = cred_dir)
        )
        deploy_proc(proc)
        deploy_mgr$log("DEPLOY", paste("Worker PID:", proc$get_pid()), "info")
      }, error = function(e) {
        deploy_mgr$log("DEPLOY", paste("Failed to start worker:", conditionMessage(e)), "error")
        deploy_mgr$set_status("error")
        cleanup_run()
        showNotification(paste("Launch error:", conditionMessage(e)), type = "error")
      })
    })

    classify <- function(l) {
      if (grepl("^\\[OK\\]", l)) "success"
      else if (grepl("^\\[WARN\\]", l)) "warn"
      else if (grepl("^\\[FAIL\\]|^Error|^\u2716|^x ", l)) "error"
      else if (grepl("^>>>|^\\[URL\\]", l)) "cmd"
      else if (grepl("^\u2714|^v ", l)) "success"
      else if (grepl("^Warning|^!", l)) "warn"
      else "info"
    }
    emit <- function(lines) {
      for (l in lines) {
        if (!nzchar(trimws(l))) next
        if (grepl("^\\[URL\\] ", l)) run_info$url <- sub("^\\[URL\\] ", "", l)
        deploy_mgr$log("DEPLOY", l, classify(l))
      }
    }

    # ── Stream output every 300 ms ─────────────────────────────────────
    observe({
      p <- deploy_proc()
      if (is.null(p)) return()
      invalidateLater(300, session)

      emit(tryCatch(p$read_output_lines(), error = function(e) character(0)))

      if (!p$is_alive()) {
        emit(tryCatch(p$read_all_output_lines(), error = function(e) character(0)))
        exit_code <- tryCatch(p$get_exit_status(), error = function(e) -1L)
        deploy_proc(NULL)
        cleanup_run()
        run_info$exit <- exit_code

        if (identical(exit_code, 0L) && isTRUE(run_info$dry)) {
          deploy_mgr$log("DEPLOY", "Test build passed \u2014 the manifest is complete. Untick 'Test only' to deploy.", "success")
          deploy_mgr$set_status("success")
          showNotification("\u2713 Test build passed", type = "message", duration = 8)
        } else if (identical(exit_code, 0L)) {
          deploy_mgr$log("DEPLOY", "Deployed and verified running \u2714", "success")
          deploy_mgr$set_status("success")
          deploy_mgr$cleanup_temp()
          showNotification("\u2713 App deployed and running!", type = "message", duration = 8)
        } else if (identical(exit_code, 3L)) {
          deploy_mgr$log("DEPLOY", "Uploaded, but the app FAILED TO START \u2014 see server log above.", "error")
          deploy_mgr$set_status("error")
          showNotification("\u2717 Deployed but failed to start", type = "error", duration = 10)
        } else {
          deploy_mgr$log("DEPLOY", paste("Deployment FAILED \u2014 exit code:", exit_code), "error")
          deploy_mgr$set_status("error")
          showNotification(paste("\u2717 Deployment failed (exit", exit_code, ")"), type = "error", duration = 10)
        }
      }
      session$sendCustomMessage(paste0("scroll_console_", id), ns("console_scroll"))
    })

    observeEvent(input$btn_abort, {
      p <- deploy_proc()
      if (!is.null(p) && p$is_alive()) {
        tryCatch(p$kill_tree(), error = function(e) p$kill())
        deploy_proc(NULL)
        cleanup_run()
        deploy_mgr$log("DEPLOY", "Deployment aborted by user.", "warn")
        deploy_mgr$set_status("idle")
        showNotification("Deployment aborted", type = "warning")
      } else {
        showNotification("No active deployment to abort", type = "message")
      }
    })

    session$onSessionEnded(function() {
      p <- isolate(deploy_proc())
      if (!is.null(p) && p$is_alive()) tryCatch(p$kill_tree(), error = function(e) p$kill())
      isolate(cleanup_run())
    })

    observeEvent(input$btn_clear_console, { deploy_mgr$clear_console() })

    output$console_output <- renderUI({
      deploy_mgr$console_trigger()
      lines <- deploy_mgr$console_lines
      if (length(lines) == 0)
        return(div(style = "color:#4B5563;padding:20px;", "\u25b6 Console output will stream here during deployment."))
      line_divs <- lapply(lines, function(raw) {
        entry <- tryCatch(jsonlite::fromJSON(raw, simplifyVector = FALSE),
                          error = function(e) list(ts = "?", tag = "?", msg = raw, type = "info", prefix = ">"))
        col <- switch(entry$type, success = "#4ADE80", error = "#F87171", warn = "#FCD34D", cmd = "#FB923C", "#94A3B8")
        tags$div(style = paste0("color:", col, ";line-height:1.65;"),
          tags$span(style = "color:#374151;font-size:10.5px;", paste0("[", entry$ts, "] ")),
          tags$span(style = paste0("color:", col, ";font-size:10.5px;margin-right:6px;"), paste0("[", entry$tag, "]")),
          tags$span(entry$prefix, " "),
          tags$span(style = "white-space:pre-wrap;", entry$msg))
      })
      do.call(tagList, line_divs)
    })

    output$deploy_complete_panel <- renderUI({
      deploy_mgr$status_trigger()
      url <- run_info$url %||% paste0("https://", deploy_mgr$account_name %||% "[account]", ".shinyapps.io/", app_name_val(), "/")
      switch(deploy_mgr$deploy_status,
        success = if (isTRUE(run_info$dry))
                    div(class = "success-box", HTML("\u2705 <strong>Test build passed.</strong> Ready to deploy."))
                  else
                    div(class = "success-box", HTML(paste0("\u2705 <strong>Deployed and running:</strong><br>",
                        "<a href='", htmltools::htmlEscape(url), "' target='_blank'>", htmltools::htmlEscape(url), "</a>"))),
        error = div(class = "warn-box", HTML(
          if (identical(run_info$exit, 3L)) "\u2717 <strong>Uploaded but failed to start.</strong> Server log is in the console."
          else "\u2717 <strong>Deployment failed.</strong> The red [FAIL] line in the console says why.")),
        running = div(class = "tip-box", HTML("\u23f3 <strong>In progress...</strong> First run installs missing packages (1\u20133 min).")),
        div()
      )
    })

    output$preflight_result <- renderUI({ div() })
  })
}
