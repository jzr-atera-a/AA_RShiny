# modules/deploy/deploy_app.R

deploy_app_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("\U0001f680 Deploy App"),
        tags$h2("Configure and launch deployment to shinyapps.io"),
        div(span(class="hero-badge","rsconnect"),
            span(class="hero-badge","renv.lock auto-generated"),
            span(class="hero-badge","Any app — any packages"))
    ),
    fluidRow(
      column(3, div(class="metric-card", span(class="metric-value", uiOutput(ns("status_auth"))),    span(class="metric-label","Authentication"))),
      column(3, div(class="metric-card", span(class="metric-value", uiOutput(ns("status_upload"))),  span(class="metric-label","App Uploaded"))),
      column(3, div(class="metric-card", span(class="metric-value", uiOutput(ns("status_deploy"))),  span(class="metric-label","Deploy Status"))),
      column(3, div(class="metric-card", span(class="metric-value", textOutput(ns("status_appname"))),span(class="metric-label","App Name")))
    ),
    br(),
    fluidRow(
      box(title="\u2699\ufe0f Deployment Configuration", status="primary", solidHeader=TRUE, width=4,
          div(class="section-heading-dark", "shinyapps.io App Name"),
          textInput(ns("app_name"), NULL, placeholder="e.g. trading_app_fixed"),
          div(class="tip-box", HTML(
            "URL slug: <code>https://[account].shinyapps.io/<strong>[name]</strong>/</code>"
          )),
          br(),
          div(class="section-heading-dark", "Options"),
          checkboxInput(ns("opt_force"), tagList(icon("redo")," Force Update (overwrite existing)"), value=TRUE),
          checkboxInput(ns("opt_lint"),  tagList(icon("search")," Lint before deployment"), value=FALSE),
          br(),
          actionButton(ns("btn_preflight"), tagList(icon("check-circle")," Pre-flight Check"), class="btn-info btn-block"),
          br(),
          uiOutput(ns("preflight_result")),
          br(),
          uiOutput(ns("deploy_btn_ui")),
          br(),
          actionButton(ns("btn_abort"),         tagList(icon("stop-circle")," Abort"),         class="btn-warning btn-block"),
          br(),
          actionButton(ns("btn_clear_console"), tagList(icon("trash")," Clear Console"),       class="btn-block")
      ),
      box(title="\U0001f5a5\ufe0f Live Deployment Console", status="success", solidHeader=TRUE, width=8,
          tags$div(
            id = ns("console_scroll"),
            style = paste0("background:#060D18;border-radius:10px;padding:16px 18px;",
                           "height:520px;overflow-y:auto;",
                           "font-family:'JetBrains Mono',monospace;font-size:12px;"),
            uiOutput(ns("console_output"))
          ),
          br(),
          fluidRow(
            column(6, div(class="tip-box", HTML(
              "<strong>Green</strong>=success &nbsp; <strong style='color:#F87171'>Red</strong>=error/stderr &nbsp; ",
              "<strong style='color:#FB923C'>Orange</strong>=deploy event"
            ))),
            column(6, uiOutput(ns("deploy_complete_panel")))
          )
      )
    ),
    fluidRow(
      box(title="\U0001f4cb Generated Deploy Script", status="warning",
          solidHeader=TRUE, width=12, collapsible=TRUE, collapsed=TRUE,
          div(class="code-box", style="max-height:260px;overflow-y:auto;",
              verbatimTextOutput(ns("deploy_script_preview"))))
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

    output$status_auth <- renderUI({
      deploy_mgr$debug_trigger()
      if (isTRUE(deploy_mgr$authenticated)) span(style="color:#4ADE80;","\u2713")
      else span(style="color:#F87171;","\u2717")
    })
    output$status_upload <- renderUI({
      deploy_mgr$debug_trigger()
      if (!is.null(deploy_mgr$detected_app_dir) && dir.exists(deploy_mgr$detected_app_dir))
        span(style="color:#4ADE80;","\u2713") else span(style="color:#F87171;","\u2717")
    })
    output$status_deploy <- renderUI({
      deploy_mgr$status_trigger()
      switch(deploy_mgr$deploy_status,
        idle    = span(style="color:#94A3B8;font-size:.9em;","idle"),
        running = span(style="color:#FCD34D;","\u23f3"),
        success = span(style="color:#4ADE80;","\u2713"),
        error   = span(style="color:#F87171;","\u2717"),
        span(deploy_mgr$deploy_status))
    })
    output$status_appname <- renderText({
      if (nchar(trimws(input$app_name %||% "")) > 0) trimws(input$app_name) else "\u2014"
    })

    output$deploy_btn_ui <- renderUI({
      deploy_mgr$debug_trigger(); deploy_mgr$status_trigger()
      ready <- isTRUE(deploy_mgr$authenticated) &&
               !is.null(deploy_mgr$detected_app_dir) &&
               dir.exists(deploy_mgr$detected_app_dir %||% "") &&
               nchar(trimws(input$app_name %||% "")) > 0 &&
               deploy_mgr$deploy_status != "running"
      if (ready)
        actionButton(ns("btn_deploy"), tagList(icon("rocket")," Deploy to shinyapps.io"),
                     class="btn-primary btn-lg btn-block")
      else
        tags$button(class="btn btn-default btn-block disabled",
                    style="cursor:not-allowed;opacity:.5;",
                    icon("rocket"), " Deploy to shinyapps.io")
    })

    observeEvent(input$btn_preflight, {
      checks <- list(
        auth      = list(ok=isTRUE(deploy_mgr$authenticated),
                         msg=if(isTRUE(deploy_mgr$authenticated))
                               paste("Authenticated as:",deploy_mgr$account_name)
                             else "Not authenticated"),
        app_dir   = list(ok=!is.null(deploy_mgr$detected_app_dir) &&
                              dir.exists(deploy_mgr$detected_app_dir %||% ""),
                         msg=if(!is.null(deploy_mgr$detected_app_dir) &&
                                dir.exists(deploy_mgr$detected_app_dir %||% ""))
                               paste("App dir:",deploy_mgr$detected_app_dir)
                             else "No app uploaded"),
        app_name  = list(ok=nchar(trimws(input$app_name %||% "")) > 0,
                         msg=if(nchar(trimws(input$app_name %||% "")) > 0)
                               paste("App name:",trimws(input$app_name))
                             else "App name required"),
        rsconnect = list(ok=requireNamespace("rsconnect",quietly=TRUE),
                         msg=paste("rsconnect",
                                   tryCatch(as.character(packageVersion("rsconnect")),
                                            error=function(e)"not found"))),
        processx  = list(ok=requireNamespace("processx",quietly=TRUE),
                         msg=paste("processx",
                                   tryCatch(as.character(packageVersion("processx")),
                                            error=function(e)"not found")))
      )
      for (nm in names(checks))
        deploy_mgr$log("DEPLOY",
                        paste0("[preflight] [",nm,"] ",checks[[nm]]$msg),
                        if(checks[[nm]]$ok) "success" else "warn")

      output$preflight_result <- renderUI({
        all_ok <- all(sapply(checks, `[[`, "ok"))
        rows <- lapply(names(checks), function(nm) {
          ck <- checks[[nm]]
          div(style="display:flex;gap:8px;margin:4px 0;",
              span(style=paste0("color:",if(ck$ok)"#4ADE80"else"#FCD34D",";font-weight:700;min-width:16px;"),
                   if(ck$ok)"\u2713"else"\u26a0"),
              span(style="font-size:12.5px;color:#374151;",ck$msg))
        })
        div(if(all_ok) div(class="success-box",HTML("\u2705 <strong>All checks passed.</strong>"))
            else        div(class="warn-box",   HTML("\u26a0 Some checks failed.")),
            br(), do.call(tagList, rows))
      })
    })

    # ══════════════════════════════════════════════════════════════════════
    # generate_renv_lock()
    # ══════════════════════════════════════════════════════════════════════
    # Builds a renv.lock from CRAN metadata for ANY app.
    # Key fix: Repositories uses data.frame so jsonlite serialises it as
    # a JSON array [{...}] — NOT an object {...}. The object form causes
    # rsconnect's parseRenvDependencies to crash with subscript out of bounds.
    # Requirements is populated from Depends/Imports/LinkingTo so rsconnect
    # can walk the dependency tree without hitting NULL access errors.
    # ══════════════════════════════════════════════════════════════════════
    generate_renv_lock <- function(app_dir) {

      BASE_PKGS <- c("base","stats","utils","methods","grDevices","graphics",
                     "datasets","tools","compiler","parallel","splines","grid",
                     "tcltk","translations","shiny")

      # 1. Scan R files for library()/require() calls
      r_files <- list.files(app_dir, recursive=TRUE, full.names=TRUE)
      r_files <- r_files[grepl("[.]R$", r_files, ignore.case=TRUE)]
      deploy_mgr$log("DEPLOY", paste("Scanning",length(r_files),"R files..."), "info")

      direct_pkgs <- unique(unlist(lapply(r_files, function(f) {
        tryCatch({
          lines <- readLines(f, warn=FALSE)
          hits  <- grep("library|require", lines, value=TRUE)
          m     <- regmatches(hits,
                    gregexpr("(?:library|require)\\s*\\(\\s*[\"']?(\\w[\\w.]*)\\s*[\"']?\\s*\\)",
                             hits, perl=TRUE))
          raw <- unlist(m)
          sub("(?:library|require)\\s*\\(\\s*[\"']?([\\w.]+).*","\\1",raw,perl=TRUE)
        }, error=function(e) character(0))
      })))
      direct_pkgs <- sort(setdiff(direct_pkgs[nchar(direct_pkgs)>1], BASE_PKGS))
      deploy_mgr$log("DEPLOY",
                      paste("Direct packages:", paste(direct_pkgs, collapse=", ")), "info")

      # 2. Query CRAN for package index
      deploy_mgr$log("DEPLOY", "Fetching CRAN package index...", "info")
      avail <- tryCatch(
        available.packages(
          repos  = "https://cloud.r-project.org",
          type   = "source",
          fields = c("Package","Version","Depends","Imports","LinkingTo")
        ),
        error=function(e) {
          deploy_mgr$log("DEPLOY", paste("CRAN query failed:", e$message), "error")
          NULL
        }
      )
      if (is.null(avail)) return(NULL)

      cran_pkgs <- direct_pkgs[direct_pkgs %in% rownames(avail)]
      off_cran  <- setdiff(direct_pkgs, cran_pkgs)
      if (length(off_cran)>0)
        deploy_mgr$log("DEPLOY",
                        paste("Not on CRAN (skipped):", paste(off_cran, collapse=", ")), "warn")

      # 3. Expand to full recursive dependency tree
      deploy_mgr$log("DEPLOY", "Expanding recursive dependency tree...", "info")
      dep_list <- tryCatch(
        tools::package_dependencies(cran_pkgs, db=avail, recursive=TRUE,
                                    which=c("Depends","Imports","LinkingTo")),
        error=function(e) list()
      )
      all_needed <- unique(c(cran_pkgs, unlist(dep_list, use.names=FALSE)))
      # Strict validation: only valid R package name patterns, on CRAN, no NA
      all_needed <- trimws(all_needed)
      all_needed <- all_needed[!is.na(all_needed)]
      all_needed <- all_needed[grepl("^[A-Za-z][A-Za-z0-9.]*$", all_needed)]
      all_needed <- sort(setdiff(all_needed, BASE_PKGS))
      all_needed <- all_needed[all_needed %in% rownames(avail)]

      deploy_mgr$log("DEPLOY",
        paste("Total packages for manifest:", length(all_needed),
              "(", length(cran_pkgs), "direct +",
              length(all_needed)-length(cran_pkgs), "transitive)"), "success")

      # 4. Write renv.lock
      lock_path <- file.path(app_dir, "renv.lock")
      existed   <- file.exists(lock_path)

      if (!existed && length(all_needed) > 0) {
        r_ver <- paste0(R.version$major,".",R.version$minor)

        # Helper: parse Depends/Imports/LinkingTo into a clean character vector
        parse_reqs <- function(pkg) {
          cols_present <- intersect(c("Depends","Imports","LinkingTo"), colnames(avail))
          raw <- paste(na.omit(avail[pkg, cols_present, drop=FALSE]), collapse=",")
          if (!nchar(trimws(raw))) return(character(0))
          parts <- trimws(strsplit(raw, "[,\n]+")[[1]])
          pkgs  <- trimws(sub("\\s*\\(.*","",parts))
          pkgs  <- pkgs[grepl("^[A-Za-z]", pkgs) & pkgs != "R" & nchar(pkgs)>0]
          unique(pkgs)
        }

        pkg_entries <- setNames(lapply(all_needed, function(pkg) {
          ver  <- avail[pkg, "Version"]
          reqs <- parse_reqs(pkg)
          # Requirements must be a character vector (not list, not NULL)
          # so rsconnect can safely iterate over it
          list(
            Package      = pkg,
            Version      = as.character(ver),
            Source       = "Repository",
            Repository   = "CRAN",
            Requirements = as.character(reqs)
          )
        }), all_needed)

        # KEY FIX: data.frame forces Repositories to serialise as JSON array
        # [{...}] not object {...} — the object form crashes parseRenvDependencies
        lock_obj <- list(
          R = list(
            Version      = r_ver,
            Repositories = data.frame(
              Name = "CRAN",
              URL  = "https://cloud.r-project.org",
              stringsAsFactors = FALSE
            )
          ),
          Packages = pkg_entries
        )

        tryCatch({
          jsonlite::write_json(lock_obj, lock_path, auto_unbox=TRUE, pretty=TRUE)
          deploy_mgr$log("DEPLOY",
            paste("renv.lock written —", length(all_needed),
                  "packages will be in the shinyapps.io manifest"), "success")
        }, error=function(e) {
          deploy_mgr$log("DEPLOY", paste("renv.lock write error:", e$message), "error")
        })
      } else if (existed) {
        deploy_mgr$log("DEPLOY", "Existing renv.lock preserved", "info")
      }

      list(path=lock_path, existed=existed, n=length(all_needed))
    }

    # ── Deploy script: credentials + deployApp only ────────────────────
    build_deploy_script <- function(app_dir, app_name, account_name,
                                    force_update, do_lint) {
      lint_block <- if (do_lint) paste0(
        'cat(">>> Linting...\\n")\n',
        'lr <- rsconnect::lint("', app_dir, '")\n',
        'if (length(lr) > 0) print(lr) else cat(">>> No lint issues.\\n")\n\n'
      ) else ""

      paste0(
        '# Auto-generated — ', format(Sys.time(),"%Y-%m-%d %H:%M:%S"), '\n',
        'library(rsconnect)\n',
        'rsconnect::setAccountInfo(\n',
        '  name   = "', account_name, '",\n',
        '  token  = Sys.getenv("RSDEPLOY_TOKEN"),\n',
        '  secret = Sys.getenv("RSDEPLOY_SECRET")\n',
        ')\n',
        'cat(">>> Credentials set. Account: ', account_name, '\\n")\n\n',
        lint_block,
        'cat(">>> Deploying ', app_name, '\\n")\n',
        'rsconnect::deployApp(\n',
        '  appDir         = "', app_dir, '",\n',
        '  appName        = "', app_name, '",\n',
        '  account        = "', account_name, '",\n',
        '  forceUpdate    = ', if(force_update)'TRUE'else'FALSE', ',\n',
        '  launch.browser = FALSE\n',
        ')\n',
        'cat(">>> Deployment complete.\\n")\n'
      )
    }

    output$deploy_script_preview <- renderText({
      tryCatch({
        req(deploy_mgr$authenticated, deploy_mgr$detected_app_dir)
        app_dir  <- deploy_mgr$detected_app_dir
        app_name <- trimws(input$app_name %||% "")
        req(nchar(app_name) > 0)
        build_deploy_script(app_dir, app_name, deploy_mgr$account_name,
                            isTRUE(input$opt_force), isTRUE(input$opt_lint))
      }, error=function(e)
        "— Configure auth, upload, and app name to preview —")
    })

    # ── Deploy handler ─────────────────────────────────────────────────
    observeEvent(input$btn_deploy, {
      req(deploy_mgr$authenticated,
          deploy_mgr$detected_app_dir,
          nchar(trimws(input$app_name %||% "")) > 0)

      app_dir  <- deploy_mgr$detected_app_dir
      app_name <- trimws(input$app_name)

      # Generate renv.lock in Shiny server — clean R, no subprocess, any app
      lock_info <- tryCatch(
        generate_renv_lock(app_dir),
        error=function(e) {
          deploy_mgr$log("DEPLOY", paste("renv.lock generation failed:", e$message), "error")
          NULL
        }
      )

      script <- tryCatch(
        build_deploy_script(app_dir, app_name, deploy_mgr$account_name,
                            isTRUE(input$opt_force), isTRUE(input$opt_lint)),
        error=function(e) {
          deploy_mgr$log("DEPLOY", paste("Script build failed:", e$message), "error")
          NULL
        }
      )
      req(script)

      script_file <- tempfile(fileext=".R")
      writeLines(script, script_file)
      deploy_mgr$log("DEPLOY", paste("Script written to:", script_file), "info")
      deploy_mgr$log("DEPLOY", "Launching Rscript subprocess...", "info")
      deploy_mgr$set_status("running")

      # Store lock path for cleanup after process exits
      session$userData$lock_path   <- if (!is.null(lock_info) && !lock_info$existed) lock_info$path else NULL

      tryCatch({
        proc <- processx::process$new(
          command = "Rscript",
          args    = c(script_file),
          stdout  = "|",
          stderr  = "|",
          env     = c("current",
                      RSDEPLOY_TOKEN  = deploy_mgr$account_token,
                      RSDEPLOY_SECRET = deploy_mgr$account_secret)
        )
        deploy_proc(proc)
        deploy_mgr$log("DEPLOY", paste("Subprocess PID:", proc$get_pid()), "info")
      }, error=function(e) {
        deploy_mgr$log("DEPLOY", paste("Failed to start subprocess:", e$message), "error")
        deploy_mgr$set_status("error")
        showNotification(paste("Launch error:", e$message), type="error")
        lp <- session$userData$lock_path
        if (!is.null(lp) && file.exists(lp)) file.remove(lp)
      })
    })

    # ── Stream output every 300ms ──────────────────────────────────────
    observe({
      p <- deploy_proc()
      if (is.null(p)) return()
      invalidateLater(300, session)

      out_raw <- tryCatch(p$read_output(), error=function(e)"")
      if (nchar(out_raw)>0) {
        for (l in strsplit(out_raw,"\n")[[1]]) {
          if (!nchar(trimws(l))) next
          type <- if (grepl("error|fail|exception",l,ignore.case=TRUE)) "error"
                  else if (grepl("warn",l,ignore.case=TRUE)) "warn"
                  else if (grepl("^>>>",l)) "cmd"
                  else "info"
          deploy_mgr$log("DEPLOY", l, type)
        }
      }
      err_raw <- tryCatch(p$read_error(), error=function(e)"")
      if (nchar(err_raw)>0) {
        for (l in strsplit(err_raw,"\n")[[1]]) {
          if (!nchar(trimws(l))) next
          # rsconnect progress lines come via stderr — label as info not error
          type <- if (grepl("^(Error|✗)",l)) "error"
                  else if (grepl("^(Warning|!)",l,ignore.case=TRUE)) "warn"
                  else "info"
          deploy_mgr$log("DEPLOY", paste("[stderr]",l), type)
        }
      }
      session$sendCustomMessage(paste0("scroll_console_",id), ns("console_scroll"))

      if (!p$is_alive()) {
        for (l in strsplit(paste0(tryCatch(p$read_output(),error=function(e)""),"\n",
                                  tryCatch(p$read_error(), error=function(e)"")),"\n")[[1]])
          if (nchar(trimws(l))) deploy_mgr$log("DEPLOY", l, "info")

        exit_code <- tryCatch(p$get_exit_status(), error=function(e) -1L)
        deploy_proc(NULL)

        # Cleanup renv.lock we created
        lp <- session$userData$lock_path
        if (!is.null(lp) && file.exists(lp)) {
          file.remove(lp)
          deploy_mgr$log("DEPLOY", "Temporary renv.lock removed.", "info")
          session$userData$lock_path <- NULL
        }

        if (identical(exit_code, 0L)) {
          deploy_mgr$log("DEPLOY","Deployment completed successfully \u2714","success")
          deploy_mgr$set_status("success")
          deploy_mgr$cleanup_temp()
          showNotification("\u2713 App deployed successfully!", type="message", duration=8)
        } else {
          deploy_mgr$log("DEPLOY",paste("Deployment FAILED \u2014 exit code:",exit_code),"error")
          deploy_mgr$set_status("error")
          showNotification(paste("\u2717 Deployment failed (exit",exit_code,")"),
                           type="error", duration=10)
        }
        session$sendCustomMessage(paste0("scroll_console_",id), ns("console_scroll"))
      }
    })

    observeEvent(input$btn_abort, {
      p <- deploy_proc()
      if (!is.null(p) && p$is_alive()) {
        p$kill(); deploy_proc(NULL)
        deploy_mgr$log("DEPLOY","Deployment aborted by user.","warn")
        deploy_mgr$set_status("idle")
        showNotification("Deployment aborted", type="warning")
      } else {
        showNotification("No active deployment to abort", type="message")
      }
    })

    observeEvent(input$btn_clear_console, { deploy_mgr$clear_console() })

    output$console_output <- renderUI({
      deploy_mgr$console_trigger()
      lines <- deploy_mgr$console_lines
      if (length(lines)==0)
        return(div(style="color:#4B5563;padding:20px;",
                   "\u25b6 Console output will stream here during deployment."))
      line_divs <- lapply(lines, function(raw) {
        entry <- tryCatch(jsonlite::fromJSON(raw, simplifyVector=FALSE),
                          error=function(e) list(ts="?",tag="?",msg=raw,type="info",prefix=">"))
        col <- switch(entry$type, success="#4ADE80", error="#F87171",
                                  warn="#FCD34D", cmd="#FB923C", "#94A3B8")
        tags$div(style=paste0("color:",col,";line-height:1.65;"),
          tags$span(style="color:#374151;font-size:10.5px;",paste0("[",entry$ts,"] ")),
          tags$span(style=paste0("color:",col,";font-size:10.5px;margin-right:6px;"),
                    paste0("[",entry$tag,"]")),
          tags$span(entry$prefix," "),
          tags$span(style="white-space:pre-wrap;",entry$msg))
      })
      do.call(tagList, line_divs)
    })

    output$deploy_complete_panel <- renderUI({
      deploy_mgr$status_trigger()
      switch(deploy_mgr$deploy_status,
        success = div(class="success-box", HTML(paste0(
          "\u2705 <strong>Deployed.</strong> Live at:<br>",
          "<code>https://",deploy_mgr$account_name %||% "[account]",
          ".shinyapps.io/",trimws(input$app_name %||% ""),"/</code>"))),
        error   = div(class="warn-box", HTML(
          "\u2717 <strong>Deployment failed.</strong> Check console and Debug tab.")),
        running = div(class="tip-box", HTML(
          "\u23f3 <strong>In progress...</strong> Streaming below.")),
        div()
      )
    })

    output$preflight_result <- renderUI({ div() })
  })
}
