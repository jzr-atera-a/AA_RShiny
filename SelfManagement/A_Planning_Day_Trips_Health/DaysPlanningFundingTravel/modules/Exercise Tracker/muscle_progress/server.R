# modules/Exercise Tracker/muscle_progress/server.R

muscle_progress_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    msg <- reactiveVal(NULL)
    safe_read <- function(key) tryCatch(api_manager$bq_muscle_read(key), error = function(e) { cat("[Muscle] could not read", key, ":", conditionMessage(e), "\n"); muscle_empty(key) })
    prog  <- reactive({ api_manager$tab_gate("muscle_progress"); api_manager$muscle_tick(); safe_read("programmes") })
    logd  <- reactive({ api_manager$tab_gate("muscle_progress"); api_manager$muscle_tick(); l <- safe_read("log"); if (nrow(l)) l$workout_date <- as.character(l$workout_date); l })
    cat_r <- reactive({ api_manager$tab_gate("muscle_progress"); api_manager$muscle_tick(); muscle_apply_targets(safe_read("targets")) })
    edit  <- reactiveVal(NULL)
    observeEvent(input$reload, { for (k in names(MUSCLE_TABLES)) tryCatch(api_manager$bq_muscle_read(k, force = TRUE), error = function(e) NULL); api_manager$muscle_changed() })

    week_no <- reactive({ s <- muscle_programme_start(prog()) %||% muscle_monday(); muscle_week_no(Sys.Date(), s) })

    output$headline <- renderUI({
      wn <- week_no(); l <- logd()
      div(class = "status-info", style = "margin:8px 0", icon("calendar-check"),
          sprintf(" Week %d - %s - target RIR %d. %d sets logged in total.", wn, muscle_phase(wn), muscle_rir_for(wn), if (nrow(l)) sum(!is.na(l$reps) & l$reps > 0) else 0L))
    })

    weekly <- reactive({  # credited sets per week x group
      l <- logd(); l <- l[!is.na(l$reps) & l$reps > 0 & !is.na(l$week_no), , drop = FALSE]
      if (!nrow(l)) return(NULL)
      do.call(rbind, lapply(split(l, l$week_no), function(w) {
        d <- muscle_done_sets(w); data.frame(week = w$week_no[1], group = MUSCLE_CAT$group, sets = as.numeric(d[MUSCLE_CAT$id]), stringsAsFactors = FALSE)
      }))
    })
    output$vol_plot <- plotly::renderPlotly({
      w <- weekly(); shiny::validate(shiny::need(!is.null(w), "Log some workouts (Muscle Log) to see weekly volume."))
      a <- stats::aggregate(sets ~ week + group, w, sum)
      plotly::plot_ly(a, x = ~paste("Wk", week), y = ~sets, color = ~group, type = "bar") |>
        plotly::layout(barmode = "stack", title = "Credited sets per week by muscle group", xaxis = list(title = "", categoryorder = "array", categoryarray = unique(paste("Wk", a$week))), yaxis = list(title = "Sets"))
    })
    output$target_plot <- plotly::renderPlotly({
      wn <- week_no(); st <- muscle_week_status_df(cat_r(), wn, muscle_done_sets(muscle_week_rows(logd(), wn)))
      st <- st[order(st$group, st$name), ]; st$name <- factor(st$name, levels = rev(st$name))
      plotly::plot_ly(st, y = ~name, x = ~target, type = "bar", orientation = "h", name = "Target", marker = list(color = "#cfd8dc")) |>
        plotly::add_trace(x = ~done, name = "Done", marker = list(color = unname(MUSCLE_STATUS[st$status]))) |>
        plotly::layout(barmode = "overlay", xaxis = list(title = sprintf("Sets (week %d, %s)", wn, muscle_phase(wn))), yaxis = list(title = ""))
    })
    output$wow_tbl <- DT::renderDataTable({
      l <- logd(); l <- l[!is.na(l$reps) & l$reps > 0 & !is.na(l$week_no), , drop = FALSE]
      if (!nrow(l)) return(DT::datatable(data.frame(Message = "No logged sets yet."), options = list(dom = "t"), rownames = FALSE))
      d <- do.call(rbind, lapply(split(l, l$week_no), function(w) data.frame(Week = w$week_no[1], Phase = muscle_phase(w$week_no[1]), Sets = nrow(w),
        `Tonnage (kg x reps)` = round(sum(w$load_kg * w$reps, na.rm = TRUE)), `Avg RIR` = round(mean(w$rir, na.rm = TRUE), 1), Sessions = length(unique(w$workout_date)), check.names = FALSE)))
      d$`Sets vs last week` <- c(NA, diff(d$Sets)); d$`Tonnage vs last week` <- c(NA, diff(d$`Tonnage (kg x reps)`))
      DT::datatable(d, rownames = FALSE, options = list(dom = "t", pageLength = 20))
    })

    observe({ l <- logd(); if (nrow(l)) updateSelectInput(session, "exercise", choices = sort(unique(l$exercise_name))) })
    lift <- reactive({
      l <- logd(); req(nrow(l), input$exercise)
      h <- l[tolower(l$exercise_name) == tolower(input$exercise) & !is.na(l$reps) & l$reps > 0, , drop = FALSE]; req(nrow(h))
      h$e1 <- muscle_e1rm(h$load_kg, h$reps)
      do.call(rbind, lapply(split(h, h$workout_date), function(d) { b <- d[which.max(replace(d$e1, is.na(d$e1), -1)), ]
        data.frame(Date = d$workout_date[1], `Top load (kg)` = suppressWarnings(max(d$load_kg, na.rm = TRUE)), `Best set` = sprintf("%s x %d", b$load_kg, b$reps),
                   e1RM = round(b$e1, 1), Sets = nrow(d), `Volume (kg x reps)` = round(sum(d$load_kg * d$reps, na.rm = TRUE)), check.names = FALSE) }))
    })
    output$lift_plot <- plotly::renderPlotly({
      d <- lift(); shiny::validate(shiny::need(any(is.finite(d$`Top load (kg)`)), "This exercise has no loads (bodyweight)."))
      plotly::plot_ly(d, x = ~Date, y = ~e1RM, type = "scatter", mode = "lines+markers", name = "Estimated 1RM") |>
        plotly::add_trace(y = ~`Top load (kg)`, name = "Top load", mode = "lines+markers") |> plotly::layout(yaxis = list(title = "kg"))
    })
    output$lift_tbl <- DT::renderDataTable(DT::datatable(lift(), rownames = FALSE, options = list(dom = "t", pageLength = 20)))

    observe({ api_manager$tab_gate("muscle_progress"); edit(muscle_apply_targets(safe_read("targets"))[, c("id", "name", "group", "mev", "mrv")]) })
    output$targets_tbl <- DT::renderDataTable({
      d <- edit(); req(d); names(d) <- c("id", "Muscle", "Group", "MEV (min sets)", "MRV (max sets)")
      DT::datatable(d[, -1], rownames = FALSE, editable = list(target = "cell", disable = list(columns = 0:1)), options = list(dom = "t", paging = FALSE))
    })
    observeEvent(input$targets_tbl_cell_edit, {
      ce <- input$targets_tbl_cell_edit; d <- edit(); col <- c("name", "group", "mev", "mrv")[ce$col + 1L]
      if (col %in% c("mev", "mrv")) { v <- as.integer(muscle_num(ce$value, NA)); if (!is.na(v) && v >= 0 && v <= 40) { d[ce$row, col] <- v; if (d$mrv[ce$row] < d$mev[ce$row]) d$mrv[ce$row] <- d$mev[ce$row]; edit(d) } }
    })
    observeEvent(input$reset_targets, { edit(MUSCLE_CAT[, c("id", "name", "group", "mev", "mrv")]); msg(list(ok = TRUE, text = "Defaults restored (not saved yet).")) })
    observeEvent(input$save_targets, {
      d <- edit(); if (!isTRUE(api_manager$bq_authenticated)) { msg(list(ok = FALSE, text = "BigQuery is not connected.")); return() }
      r <- tryCatch({ api_manager$bq_muscle_insert("targets", data.frame(muscle_id = d$id, mev = d$mev, mrv = d$mrv, stringsAsFactors = FALSE)); api_manager$muscle_changed() }, error = function(e) e)
      msg(if (inherits(r, "error")) list(ok = FALSE, text = conditionMessage(r)) else list(ok = TRUE, text = "Targets saved to muscle_targets."))
    })
    output$status <- renderUI({ m <- msg(); if (is.null(m)) return(NULL); div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top:8px", " ", m$text) })
    output$ramp_tbl <- DT::renderDataTable({
      d <- edit(); req(d); cat <- MUSCLE_CAT; cat$mev <- d$mev; cat$mrv <- d$mrv
      r <- data.frame(Muscle = cat$name, do.call(cbind, lapply(1:5, function(w) muscle_week_targets(w, cat))), check.names = FALSE)
      names(r) <- c("Muscle", "Wk1 (RIR 4)", "Wk2 (RIR 3)", "Wk3 (RIR 2)", "Wk4 (RIR 1)", "Wk5 deload")
      DT::datatable(r, rownames = FALSE, options = list(dom = "t", paging = FALSE))
    })
    session$onSessionEnded(function() {})
  })
}
