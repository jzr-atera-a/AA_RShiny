# modules/Exercise Tracker/muscle_programme/server.R

muscle_programme_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(days = list(), start_loaded = FALSE)
    msg <- reactiveVal(NULL)
    set_msg <- function(ok, text) msg(list(ok = ok, text = text))

    safe_read <- function(key) tryCatch(api_manager$bq_muscle_read(key), error = function(e) {
      cat("[Muscle] could not read", key, ":", conditionMessage(e), "\n"); muscle_empty(key) })
    prog  <- reactive({ api_manager$tab_gate("muscle_programme"); api_manager$muscle_tick(); safe_read("programmes") })
    diag  <- reactive({ api_manager$tab_gate("muscle_programme"); api_manager$muscle_tick(); safe_read("diagrams") })
    logd  <- reactive({ api_manager$tab_gate("muscle_programme"); api_manager$muscle_tick(); safe_read("log") })
    cat_r <- reactive({ api_manager$tab_gate("muscle_programme"); api_manager$muscle_tick(); muscle_apply_targets(safe_read("targets")) })

    observeEvent(input$reload, {
      for (k in names(MUSCLE_TABLES)) tryCatch(api_manager$bq_muscle_read(k, force = TRUE), error = function(e) set_msg(FALSE, conditionMessage(e)))
      api_manager$muscle_changed()
    })

    output$claude_note <- renderUI({
      if (!isTRUE(api_manager$claude_authenticated))
        div(class = "status-warning", icon("exclamation-triangle"), " Claude is not connected. Open ", tags$strong("API Configuration > Claude API Config"), ". ",
            if (!isTRUE(api_manager$bq_authenticated)) "BigQuery is not connected either: plans can be made but not saved." else "")
      else if (!isTRUE(api_manager$bq_authenticated))
        div(class = "status-warning", icon("exclamation-triangle"), " BigQuery is not connected: plans can be generated but not saved or logged (API Configuration > BigQuery).")
    })

    # keep the saved programme start date
    observe({
      p <- prog()
      if (!rv$start_loaded && nrow(p) > 0) {
        s <- muscle_programme_start(p); if (!is.null(s)) updateDateInput(session, "start", value = s)
        rv$start_loaded <- TRUE
      }
    })

    split_def <- reactive(muscle_split(input$days %||% 4))
    observeEvent(split_def(), {
      sp <- split_def(); cur <- isolate(input$day_no)
      ch <- stats::setNames(as.character(seq_along(sp)), paste0("Day ", seq_along(sp), ": ", vapply(sp, function(x) x$label, "")))
      updateSelectInput(session, "day_no", choices = ch, selected = if (!is.null(cur) && cur %in% ch) cur else ch[1])
    })

    week_no <- reactive(muscle_week_no(input$plan_date %||% Sys.Date(), input$start %||% muscle_monday()))
    day_idx <- reactive(as.integer(input$day_no %||% 1))

    output$week_info <- renderUI({
      wn <- week_no(); sp <- split_def(); d <- min(day_idx(), length(sp))
      cat <- cat_r(); lw <- muscle_week_rows(logd(), wn)
      tt <- muscle_day_targets(sp, d, muscle_week_targets(wn, cat), muscle_done_sets(lw), unique(lw$day_no))
      div(class = "status-info", style = "margin: 8px 0;",
          icon("calendar-check"), sprintf(" Week %d (block %d, %s) | target %s reps in reserve | Day %d: %s", wn, muscle_block_no(wn), muscle_phase(wn),
                                          muscle_rir_for(wn), d, sp[[d]]$label),
          tags$br(), tags$small("Sets to cover today (weekly target shared across remaining days; missed work is made up): ",
                                paste0(muscle_name(names(tt)), " ", tt, collapse = " | ")))
    })

    # ---- rebuild a day from the saved tables ----
    from_saved <- function(wn, d) {
      p <- prog(); p <- p[!is.na(p$week_no) & p$week_no == wn & !is.na(p$day_no) & p$day_no == d, , drop = FALSE]
      if (!nrow(p)) return(NULL)
      dg <- diag(); opts <- list()
      for (k in unique(p$option_key)) {
        r <- p[p$option_key == k, , drop = FALSE]; r <- r[order(r$exercise_order), ]
        dd <- dg[dg$diagram_id == r$programme_id[1], , drop = FALSE]
        spec <- if (nrow(dd)) muscle_spec_read(tail(dd$spec_json, 1)) else NULL
        if (is.null(spec)) spec <- muscle_make_spec(r, r$option_title[1])
        opts[[k]] <- list(key = k, title = r$option_title[1], summary = "", exercises = r, spec = spec, notes = "")
      }
      list(day_no = d, day_label = p$day_label[1], week_no = wn, phase = p$phase[1], options = opts, warnings = character(0), saved = TRUE, targets = NULL)
    }
    cur <- reactive({
      d <- as.character(day_idx())
      x <- rv$days[[d]]
      if (!is.null(x) && identical(x$week_no, week_no())) x else from_saved(week_no(), day_idx())
    })

    # ---- generate ----
    gen_day <- function(d) {
      if (!isTRUE(api_manager$claude_authenticated)) stop("Claude is not connected (API Configuration > Claude API Config).")
      wn <- week_no(); sp <- split_def(); cat <- cat_r(); log <- logd()
      lw <- muscle_week_rows(log, wn)
      targets_today <- muscle_day_targets(sp, d, muscle_week_targets(wn, cat), muscle_done_sets(lw), unique(lw$day_no))
      p <- prog(); prev <- p[!is.na(p$week_no) & p$week_no == wn - 1L & !is.na(p$day_no) & p$day_no == d, , drop = FALSE]
      phase <- muscle_phase(wn); rir <- muscle_rir_for(wn)
      prompt <- muscle_day_prompt(sp[[d]]$label, d, wn, targets_today, rir, phase, input$injuries %||% "", input$level %||% "Intermediate",
                                  prev, muscle_last_perf(log), input$home_db %||% 20, input$gym_notes %||% "", input$home_notes %||% "", input$plan_date)
      cat(sprintf("[Muscle] planning week %d day %d (%s) - prompt %d chars\n", wn, d, sp[[d]]$label, nchar(prompt)))
      ans <- api_manager$call_claude(prompt, max_tokens = 12000)
      txt <- if (is.list(ans)) ans$text else as.character(ans)
      res <- muscle_parse_plan(txt, input$home_db %||% 20)
      if (!isTRUE(res$ok)) { cat("[Muscle] parse failed:", res$error, "\n[Muscle] raw answer starts:", substr(txt, 1, 400), "\n"); stop(res$error) }
      for (k in names(res$options)) {
        o <- res$options[[k]]
        o$exercises <- muscle_apply_progression(o$exercises, log, deload = muscle_block_week(wn) == 5L)
        o$spec <- muscle_make_spec(o$exercises, paste0(sp[[d]]$label, " - ", MUSCLE_OPTION_SHORT[[k]]), o$view, o$callouts)
        res$options[[k]] <- o
      }
      rv$days[[as.character(d)]] <- list(day_no = d, day_label = sp[[d]]$label, week_no = wn, phase = phase, options = res$options,
                                         warnings = res$warnings, saved = FALSE, targets = targets_today)
      invisible(res)
    }

    save_day <- function(d) {
      x <- rv$days[[as.character(d)]]
      if (is.null(x)) stop("Plan this day first.")
      if (!isTRUE(api_manager$bq_authenticated)) stop("BigQuery is not connected (API Configuration > BigQuery).")
      wn <- x$week_no; start <- format(as.Date(input$start))
      pr <- list(); dr <- list()
      for (k in names(x$options)) {
        o <- x$options[[k]]; pid <- sprintf("W%02d-D%d-%s", wn, d, k)
        e <- o$exercises
        pr[[k]] <- cbind(data.frame(programme_id = pid, programme_start = start, week_no = wn, block_week = muscle_block_week(wn), phase = x$phase,
                                    day_no = d, day_label = x$day_label, planned_date = format(as.Date(input$plan_date)), option_key = k,
                                    option_title = o$title, stringsAsFactors = FALSE), e,
                         injury_note = input$injuries %||% "", status = "planned", stringsAsFactors = FALSE)
        dr[[k]] <- data.frame(diagram_id = pid, programme_id = pid, week_no = wn, day_no = d, option_key = k, title = o$spec$title,
                              view = o$spec$view, spec_json = muscle_spec_json(o$spec), source = "claude", notes = o$summary, stringsAsFactors = FALSE)
      }
      ids <- sprintf("W%02d-D%d-%s", wn, d, names(MUSCLE_OPTIONS))
      api_manager$bq_muscle_delete("programmes", "programme_id", ids)
      api_manager$bq_muscle_delete("diagrams", "diagram_id", ids)
      n1 <- api_manager$bq_muscle_insert("programmes", do.call(rbind, pr))
      n2 <- api_manager$bq_muscle_insert("diagrams", do.call(rbind, dr))
      rv$days[[as.character(d)]]$saved <- TRUE
      api_manager$muscle_changed()
      c(n1, n2)
    }

    observeEvent(input$gen_day, {
      d <- day_idx(); set_msg(TRUE, "Claude is planning the three options... (about 30-90 seconds)")
      r <- tryCatch(withProgress(message = "Planning the day...", value = 0.4, gen_day(d)), error = function(e) e)
      if (inherits(r, "error")) { set_msg(FALSE, paste0("Planning failed: ", conditionMessage(r))); return() }
      set_msg(TRUE, "Plan ready. Review the three options, then save the day.")
      updateTabsetPanel(session, "opt_tabs", selected = "gym")
    })

    observeEvent(input$gen_week, {
      sp <- split_def(); n <- length(sp); ok <- 0L; errs <- character(0)
      withProgress(message = "Planning the week...", value = 0, {
        for (d in seq_len(n)) {
          incProgress(1 / n, detail = paste("Day", d, ":", sp[[d]]$label))
          r <- tryCatch({ gen_day(d); if (isTRUE(api_manager$bq_authenticated)) save_day(d); TRUE }, error = function(e) { errs <<- c(errs, paste0("Day ", d, ": ", conditionMessage(e))); FALSE })
          if (isTRUE(r)) ok <- ok + 1L
        }
      })
      set_msg(length(errs) == 0, sprintf("Week planned: %d of %d days%s.%s", ok, n, if (isTRUE(api_manager$bq_authenticated)) " (saved)" else " (not saved - BigQuery not connected)",
                                         if (length(errs)) paste0(" Problems: ", paste(errs, collapse = " | ")) else ""))
    })

    observeEvent(input$save, {
      r <- tryCatch(save_day(day_idx()), error = function(e) e)
      if (inherits(r, "error")) { set_msg(FALSE, conditionMessage(r)); return() }
      set_msg(TRUE, sprintf("Saved: %d exercise rows and %d diagram specs written to BigQuery (muscle_programmes, muscle_diagrams).", r[1], r[2]))
    })

    output$status <- renderUI({
      m <- msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top:10px;", icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text)
    })

    output$day_header <- renderUI({
      x <- cur()
      if (is.null(x)) return(p(class = "text-muted", "No plan for this day yet. Click 'Plan this day' (or 'Plan the whole week')."))
      tagList(h4(sprintf("Week %d - %s - Day %d: %s", x$week_no, x$phase, x$day_no, x$day_label), if (isTRUE(x$saved)) span(class = "label label-success", style = "margin-left:8px", "saved") else span(class = "label label-warning", style = "margin-left:8px", "not saved")),
              if (length(x$warnings)) div(class = "status-warning", icon("exclamation-triangle"), tags$ul(lapply(x$warnings, tags$li))))
    })

    render_option <- function(key) renderUI({
      x <- cur(); if (is.null(x)) return(NULL)
      o <- x$options[[key]]
      if (is.null(o)) return(p(class = "text-muted", "Claude did not return this option. Plan the day again."))
      e <- o$exercises
      rows <- lapply(seq_len(nrow(e)), function(i) tags$tr(
        tags$td(e$exercise_order[i]),
        tags$td(tags$strong(e$exercise_name[i]), tags$br(), tags$small(class = "text-muted", paste(c(e$equipment[i], e$machine_or_load[i])[nzchar(c(e$equipment[i], e$machine_or_load[i]))], collapse = " - "))),
        tags$td(paste(muscle_name(muscle_split_ids(e$primary_muscles[i])), collapse = ", "), if (nzchar(e$secondary_muscles[i])) tags$small(class = "text-muted", tags$br(), "+ ", paste(muscle_name(muscle_split_ids(e$secondary_muscles[i])), collapse = ", "))),
        tags$td(e$sets[i]), tags$td(sprintf("%d-%d", e$rep_min[i], e$rep_max[i])), tags$td(e$target_rir[i]),
        tags$td(if (is.na(e$target_load_kg[i])) "-" else tagList(e$target_load_kg[i], if (identical(e$load_source[i], "progression")) tags$span(class = "label label-info", style = "margin-left:4px", "progression"))),
        tags$td(e$rest_sec[i]), tags$td(tags$small(e$cues[i]))))
      done <- muscle_plan_sets(e); done <- done[done > 0]
      tg <- x$targets
      cov <- data.frame(Muscle = muscle_name(names(done)), `Planned sets` = unname(done),
                        `Day target` = vapply(names(done), function(m) if (!is.null(tg) && m %in% names(tg)) as.numeric(tg[[m]]) else NA_real_, 0), check.names = FALSE)
      cov <- cov[order(-cov$`Planned sets`), ]
      fluidRow(
        column(5, if (nzchar(o$summary)) p(tags$em(o$summary)), HTML(muscle_spec_svg(o$spec)), HTML(muscle_legend_html("session")),
               if (nzchar(o$notes)) p(tags$small(o$notes))),
        column(7, tags$table(class = "table table-striped table-condensed", style = "font-size:12.5px",
                             tags$thead(tags$tr(lapply(c("#", "Exercise", "Muscles", "Sets", "Reps", "RIR", "Load kg", "Rest s", "Cues"), tags$th))), tags$tbody(rows)),
               h5("Sets credited per muscle (primary 1, secondary 0.5)"),
               tags$table(class = "table table-condensed", style = "width:auto;font-size:12px", tags$thead(tags$tr(lapply(names(cov), tags$th))),
                          tags$tbody(lapply(seq_len(nrow(cov)), function(i) tags$tr(tags$td(cov[[1]][i]), tags$td(cov[[2]][i]), tags$td(if (is.na(cov[[3]][i])) "-" else cov[[3]][i]))))),
               actionButton(ns(paste0("start_", key)), "Do this workout (open Muscle Log)", icon = icon("clipboard-check"), class = "btn-success")))
    })
    output$opt_gym <- render_option("gym"); output$opt_bodyweight <- render_option("bodyweight"); output$opt_home <- render_option("home")

    for (k in names(MUSCLE_OPTIONS)) local({
      key <- k
      observeEvent(input[[paste0("start_", key)]], {
        x <- cur(); if (is.null(x)) return()
        if (!isTRUE(x$saved)) {
          r <- tryCatch(save_day(day_idx()), error = function(e) e)
          if (inherits(r, "error")) { set_msg(FALSE, paste0("Save the day first: ", conditionMessage(r))); return() }
        }
        api_manager$muscle_goto(list(programme_id = sprintf("W%02d-D%d-%s", x$week_no, x$day_no, key), stamp = Sys.time()))
        tryCatch(nav_goto(session, "muscle_log"), error = function(e) NULL)
      })
    })

    output$week_table <- DT::renderDataTable({
      p <- muscle_week_rows(prog(), week_no())
      if (!nrow(p)) return(DT::datatable(data.frame(Message = "Nothing saved for this week yet."), options = list(dom = "t"), rownames = FALSE))
      s <- do.call(rbind, lapply(split(p, p$day_no), function(r) data.frame(Day = r$day_no[1], Focus = r$day_label[1], `Planned date` = r$planned_date[1],
        Options = paste(unique(r$option_key), collapse = ", "), Exercises = length(unique(r$exercise_name)), `Total sets (gym)` = sum(r$sets[r$option_key == "gym"]), check.names = FALSE)))
      DT::datatable(s, options = list(dom = "t", pageLength = 10), rownames = FALSE)
    })

    session$onSessionEnded(function() {})
  })
}
