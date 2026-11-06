# modules/Exercise Tracker/muscle_log/server.R

muscle_log_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv <- reactiveValues(tbl = NULL, saved = FALSE, next_df = NULL, tver = 0L)   # tver: bump only when rows are added/replaced (not on cell edits)
    msg <- reactiveVal(NULL)
    set_msg <- function(ok, text) msg(list(ok = ok, text = text))
    safe_read <- function(key) tryCatch(api_manager$bq_muscle_read(key), error = function(e) { cat("[Muscle] could not read", key, ":", conditionMessage(e), "\n"); muscle_empty(key) })
    prog  <- reactive({ api_manager$tab_gate("muscle_log"); api_manager$muscle_tick(); safe_read("programmes") })
    logd  <- reactive({ api_manager$tab_gate("muscle_log"); api_manager$muscle_tick(); safe_read("log") })
    cat_r <- reactive({ api_manager$tab_gate("muscle_log"); api_manager$muscle_tick(); muscle_apply_targets(safe_read("targets")) })

    output$bq_note <- renderUI(if (!isTRUE(api_manager$bq_authenticated))
      div(class = "status-warning", icon("exclamation-triangle"), " BigQuery is not connected (API Configuration > BigQuery): saved workouts cannot be listed or logged."))

    observe({
      p <- prog(); if (!nrow(p)) return()
      k <- unique(p[, c("programme_id", "week_no", "day_no", "day_label", "option_key")])
      k <- k[order(-k$week_no, k$day_no), ]
      lab <- sprintf("Week %d | Day %d: %s | %s", k$week_no, k$day_no, k$day_label, MUSCLE_OPTION_SHORT[k$option_key])
      isolate(cur <- input$programme)
      updateSelectInput(session, "programme", choices = stats::setNames(k$programme_id, lab), selected = if (!is.null(cur) && nzchar(cur) && cur %in% k$programme_id) cur else k$programme_id[1])
    })

    load_programme <- function(pid) {
      p <- prog(); e <- p[p$programme_id == pid, , drop = FALSE]
      if (!nrow(e)) { set_msg(FALSE, "That workout is not saved yet."); return() }
      e <- e[order(e$exercise_order), ]
      rows <- lapply(seq_len(nrow(e)), function(i) data.frame(
        exercise_name = e$exercise_name[i], set_no = seq_len(e$sets[i]),
        target = sprintf("%d-%d reps @ RIR %d%s", e$rep_min[i], e$rep_max[i], e$target_rir[i], if (is.na(e$target_load_kg[i])) "" else sprintf(", %s kg", e$target_load_kg[i])),
        load_kg = e$target_load_kg[i], reps = NA_integer_, rir = NA_integer_, notes = "",
        primary_muscles = e$primary_muscles[i], secondary_muscles = e$secondary_muscles[i],
        programme_id = pid, week_no = e$week_no[i], day_no = e$day_no[i], option_key = e$option_key[i],
        rep_min = e$rep_min[i], rep_max = e$rep_max[i], stringsAsFactors = FALSE))
      rv$tbl <- do.call(rbind, rows); rv$saved <- FALSE; rv$next_df <- NULL; rv$tver <- rv$tver + 1L
      set_msg(TRUE, sprintf("Loaded: %s (%d sets).", e$day_label[1], nrow(rv$tbl)))
    }
    observeEvent(input$load, { req(input$programme); load_programme(input$programme) })
    observeEvent(api_manager$muscle_goto(), {
      g <- api_manager$muscle_goto(); req(g$programme_id)
      updateSelectInput(session, "programme", selected = g$programme_id)
      shiny::isolate({ if (g$programme_id %in% prog()$programme_id) load_programme(g$programme_id) })
    }, ignoreInit = TRUE)

    shown <- c("exercise_name", "set_no", "target", "load_kg", "reps", "rir", "notes")
    output$tbl <- DT::renderDataTable({
      rv$tver
      t <- shiny::isolate(rv$tbl)
      if (is.null(t) || !nrow(t)) return(DT::datatable(data.frame(Message = "Pick a saved workout and click 'Load workout'."), options = list(dom = "t"), rownames = FALSE))
      d <- t[, shown]; names(d) <- c("Exercise", "Set", "Target", "Load (kg)", "Reps", "RIR", "Notes")
      DT::datatable(d, rownames = FALSE, editable = list(target = "cell", disable = list(columns = 0:2)),
                    options = list(dom = "t", paging = FALSE, ordering = FALSE, scrollX = TRUE))
    })
    observeEvent(input$tbl_cell_edit, {
      ce <- input$tbl_cell_edit; i <- ce$row; col <- shown[ce$col + 1L]
      if (is.null(rv$tbl) || i > nrow(rv$tbl)) return()
      v <- ce$value
      rv$tbl[i, col] <- switch(col, load_kg = muscle_num(v, NA_real_), reps = as.integer(muscle_num(v, NA_real_)), rir = as.integer(muscle_num(v, NA_real_)), notes = as.character(v), rv$tbl[i, col])
    })

    observeEvent(input$free_add, {
      nm <- trimws(input$free_name %||% ""); m <- input$free_muscles
      if (!nzchar(nm) || !length(m)) { set_msg(FALSE, "Give the extra exercise a name and at least one muscle."); return() }
      start <- muscle_programme_start(prog()) %||% muscle_monday(input$date); wn <- muscle_week_no(input$date, start)
      n <- as.integer(max(1, min(8, input$free_sets %||% 3)))
      add <- data.frame(exercise_name = nm, set_no = seq_len(n), target = "extra", load_kg = NA_real_, reps = NA_integer_, rir = NA_integer_, notes = "",
                        primary_muscles = paste(m, collapse = ","), secondary_muscles = "", programme_id = "FREE", week_no = wn, day_no = NA_integer_,
                        option_key = "free", rep_min = 8L, rep_max = 12L, stringsAsFactors = FALSE)
      rv$tbl <- if (is.null(rv$tbl)) add else rbind(rv$tbl, add); rv$saved <- FALSE; rv$tver <- rv$tver + 1L
    })

    observeEvent(input$save, {
      t <- rv$tbl
      if (is.null(t) || !nrow(t)) { set_msg(FALSE, "Nothing to save. Load a workout first."); return() }
      if (isTRUE(rv$saved)) { set_msg(FALSE, "These sets were already saved. Load the workout again to log another session."); return() }
      if (!isTRUE(api_manager$bq_authenticated)) { set_msg(FALSE, "BigQuery is not connected (API Configuration > BigQuery)."); return() }
      ok <- !is.na(t$reps) & t$reps > 0
      if (!any(ok)) { set_msg(FALSE, "Enter the reps you did for at least one set."); return() }
      s <- t[ok, , drop = FALSE]
      out <- data.frame(workout_date = format(as.Date(input$date)), programme_id = s$programme_id, week_no = s$week_no, day_no = s$day_no, option_key = s$option_key,
                        exercise_name = s$exercise_name, primary_muscles = s$primary_muscles, secondary_muscles = s$secondary_muscles, set_no = s$set_no,
                        load_kg = s$load_kg, reps = s$reps, rir = s$rir, notes = s$notes, stringsAsFactors = FALSE)
      r <- tryCatch(api_manager$bq_muscle_insert("log", out), error = function(e) e)
      if (inherits(r, "error")) { set_msg(FALSE, paste("Saving failed:", conditionMessage(r))); return() }
      rv$saved <- TRUE
      # what to do next time
      deload_next <- muscle_block_week(max(s$week_no, na.rm = TRUE) + 1L) == 5L
      nx <- lapply(split(s, s$exercise_name), function(h) {
        h$workout_date <- format(as.Date(input$date))
        n <- muscle_next_load(h, h$rep_min[1], h$rep_max[1], 2L, any(muscle_split_ids(h$primary_muscles[1]) %in% c("quads", "hamstrings", "glutes", "calves")), FALSE)
        if (is.null(n)) data.frame(Exercise = h$exercise_name[1], `Next load (kg)` = NA_real_, `Next goal` = "bodyweight: add a rep or slow the tempo", check.names = FALSE)
        else data.frame(Exercise = h$exercise_name[1], `Next load (kg)` = n$load, `Next goal` = paste0(n$reps, " reps - ", n$reason), check.names = FALSE)
      })
      rv$next_df <- do.call(rbind, nx)
      api_manager$muscle_changed()
      set_msg(TRUE, sprintf("Saved %d sets to BigQuery (muscle_set_log).", r))
    })

    output$status <- renderUI({
      m <- msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top:10px;", icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text)
    })
    output$next_tbl <- DT::renderDataTable({
      d <- rv$next_df
      if (is.null(d)) d <- data.frame(Message = "Appears after you save a workout.")
      DT::datatable(d, rownames = FALSE, options = list(dom = "t", paging = FALSE))
    })
    output$week_map <- renderUI({
      start <- muscle_programme_start(prog()) %||% muscle_monday(input$date)
      wn <- muscle_week_no(input$date, start); cat <- cat_r()
      st <- muscle_week_status_df(cat, wn, muscle_done_sets(muscle_week_rows(logd(), wn)))
      miss <- st$name[st$status == "none"]
      tagList(p(tags$small(sprintf("Week %d (%s). Not trained yet: %s", wn, muscle_phase(wn), if (length(miss)) paste(miss, collapse = ", ") else "none - every muscle has work this week"))),
              HTML(muscle_svg(fills = stats::setNames(as.list(MUSCLE_STATUS[st$status]), st$id), view = "both")), HTML(muscle_legend_html("gaps")))
    })
    session$onSessionEnded(function() {})
  })
}
