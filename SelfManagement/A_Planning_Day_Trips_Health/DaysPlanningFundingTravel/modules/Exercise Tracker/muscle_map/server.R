# modules/Exercise Tracker/muscle_map/server.R

muscle_map_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    sel <- reactiveVal(NULL)
    safe_read <- function(key) tryCatch(api_manager$bq_muscle_read(key), error = function(e) { cat("[Muscle] could not read", key, ":", conditionMessage(e), "\n"); muscle_empty(key) })
    prog  <- reactive({ api_manager$tab_gate("muscle_map"); api_manager$muscle_tick(); safe_read("programmes") })
    diag  <- reactive({ api_manager$tab_gate("muscle_map"); api_manager$muscle_tick(); safe_read("diagrams") })
    logd  <- reactive({ api_manager$tab_gate("muscle_map"); api_manager$muscle_tick(); safe_read("log") })
    cat_r <- reactive({ api_manager$tab_gate("muscle_map"); api_manager$muscle_tick(); muscle_apply_targets(safe_read("targets")) })
    observeEvent(input$reload, { for (k in names(MUSCLE_TABLES)) tryCatch(api_manager$bq_muscle_read(k, force = TRUE), error = function(e) NULL); api_manager$muscle_changed() })

    week_no <- reactive({ s <- muscle_programme_start(prog()) %||% muscle_monday(); muscle_week_no(Sys.Date(), s) })
    status_df <- reactive(muscle_week_status_df(cat_r(), week_no(), muscle_done_sets(muscle_week_rows(logd(), week_no()))))

    observe({
      d <- diag(); if (!nrow(d)) return()
      d <- d[order(-d$week_no, d$day_no), ]
      updateSelectInput(session, "programme", choices = stats::setNames(d$diagram_id, d$title), selected = d$diagram_id[1])
    })

    observeEvent(input$muscle_click, { sel(input$muscle_click) })

    sets28 <- reactive({
      l <- logd(); if (!nrow(l)) return(stats::setNames(numeric(length(MUSCLE_IDS)), MUSCLE_IDS))
      l <- l[as.Date(l$workout_date) >= Sys.Date() - 28, , drop = FALSE]; muscle_done_sets(l)
    })

    fills <- reactive({
      m <- input$mode %||% "gaps"
      if (m == "gaps") { st <- status_df(); stats::setNames(as.list(MUSCLE_STATUS[st$status]), st$id) }
      else if (m == "vol28") {
        v <- sets28(); mx <- max(v, 1); pal <- grDevices::colorRampPalette(c("#cfd8dc", "#ffe082", "#ff9800", "#d84315", "#7f0000"))(100)
        stats::setNames(lapply(names(v), function(i) if (v[[i]] <= 0) "#cfd8dc" else pal[max(1, min(100, round(100 * v[[i]] / mx)))]), names(v))
      } else if (m == "session") {
        d <- diag(); d <- d[d$diagram_id == (input$programme %||% ""), , drop = FALSE]
        if (nrow(d)) muscle_spec_fills(muscle_spec_read(tail(d$spec_json, 1))) else list()
      } else list()
    })

    output$legend <- renderUI({
      m <- input$mode %||% "gaps"
      if (m == "gaps") HTML(muscle_legend_html("gaps")) else if (m == "session") HTML(muscle_legend_html("session"))
      else if (m == "vol28") HTML('<div style="font-size:12px;margin:6px 0">Light = little, dark red = most credited sets in the last 28 days (grey = none)</div>')
    })

    output$figure <- renderUI({
      f <- fills(); m <- input$mode %||% "gaps"
      HTML(muscle_svg(fills = f, view = input$view %||% "both", selected = sel(), click_input = ns("muscle_click"),
                      dim_others = (m == "session"), show_names = isTRUE(input$names)))
    })

    output$details <- renderUI({
      id <- sel()
      if (is.null(id) || !id %in% MUSCLE_IDS) return(p(class = "text-muted", "Click a muscle on the diagram."))
      cat <- cat_r(); row <- cat[cat$id == id, ]; st <- status_df(); st <- st[st$id == id, ]
      parts <- unique(MUSCLE_BODY_PARTS$part[MUSCLE_BODY_PARTS$muscle == id])
      l <- logd(); hit <- if (nrow(l)) l[vapply(seq_len(nrow(l)), function(i) id %in% c(muscle_split_ids(l$primary_muscles[i]), muscle_split_ids(l$secondary_muscles[i])), NA), , drop = FALSE] else l
      last <- if (nrow(hit)) max(as.character(hit$workout_date)) else NA
      best <- NULL
      if (nrow(hit)) {
        h2 <- hit[!is.na(hit$load_kg) & !is.na(hit$reps), , drop = FALSE]
        if (nrow(h2)) { h2$e1 <- muscle_e1rm(h2$load_kg, h2$reps); b <- h2[order(-h2$e1), ]; b <- b[!duplicated(tolower(b$exercise_name)), ]; best <- utils::head(b, 4) }
      }
      p <- prog(); lib <- if (nrow(p)) unique(p$exercise_name[vapply(seq_len(nrow(p)), function(i) id %in% muscle_split_ids(p$primary_muscles[i]), NA)]) else character(0)
      tagList(
        h4(style = paste0("color:", row$color), row$name), tags$small(class = "text-muted", paste("Group:", row$group)),
        tags$p(tags$strong("Anatomy: "), paste(parts, collapse = "; ")),
        tags$p(tags$strong("This week: "), sprintf("%s of %s sets (%s)", round(st$done, 1), st$target, MUSCLE_STATUS_LABEL[[st$status]]),
               tags$br(), tags$strong("Weekly range: "), sprintf("%d - %d sets (min effective - max recoverable)", row$mev, row$mrv),
               tags$br(), tags$strong("Last trained: "), if (is.na(last)) "never logged" else last,
               tags$br(), tags$strong("Credited sets, last 28 days: "), round(sets28()[[id]], 1)),
        if (!is.null(best) && nrow(best)) tagList(tags$strong("Best lifts (estimated 1RM)"), tags$ul(lapply(seq_len(nrow(best)), function(i) tags$li(sprintf("%s: %s kg x %d (e1RM %.1f kg)", best$exercise_name[i], best$load_kg[i], best$reps[i], best$e1[i]))))),
        if (length(lib)) tagList(tags$strong("Exercises used for it in your programmes"), tags$ul(lapply(utils::head(lib, 10), tags$li))))
    })

    output$gap_summary <- renderUI({
      st <- status_df(); wn <- week_no()
      none <- st$name[st$status == "none"]; low <- st$name[st$status == "low"]
      tagList(p(sprintf("Week %d (%s). Targets rise each build week and drop in the deload week.", wn, muscle_phase(wn))),
              if (length(none)) div(class = "status-error", icon("times-circle"), tags$strong(" Not trained yet: "), paste(none, collapse = ", ")),
              if (length(low)) div(class = "status-warning", style = "margin-top:6px", icon("exclamation-triangle"), tags$strong(" Under target: "), paste(low, collapse = ", ")),
              if (!length(none) && !length(low)) div(class = "status-success", icon("check-circle"), " Every muscle is on target."))
    })
    output$gap_tbl <- DT::renderDataTable({
      st <- status_df(); st$remaining <- pmax(0, st$target - st$done); st$status <- MUSCLE_STATUS_LABEL[st$status]
      d <- st[order(-st$remaining), c("name", "group", "done", "target", "remaining", "status")]; names(d) <- c("Muscle", "Group", "Sets done", "Weekly target", "Still to do", "Status")
      DT::datatable(d, rownames = FALSE, options = list(pageLength = 30, dom = "ft"))
    })
    session$onSessionEnded(function() {})
  })
}
