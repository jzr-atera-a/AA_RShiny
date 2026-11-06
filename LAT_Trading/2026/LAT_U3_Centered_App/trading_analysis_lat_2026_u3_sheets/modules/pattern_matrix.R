# modules/pattern_matrix.R - "Step-by-Step Practice": one sidebar item, six horizontal tabs (the course's Steps 1-6).
# Each tab is the course step (its sections and examples; every example that is a matrix pattern is drawn precisely and
# checked by the app's improved rules), followed by "Pattern identification": the matrix patterns taught in that step
# (all 141 across the six tabs), each on a simulated 15-minute example built from its definition.
# Examples are read from BigQuery (table pattern_examples, one query per course step). Only when BigQuery cannot be
# reached, or an example is not stored yet, is it built here and then saved to BigQuery (pm_get, R/utils_pm.R).

pm_course_titles <- c("Step 1: Support & resistance, trend lines, candles", "Step 2: Fibonacci & price patterns", "Step 3: Indicators",
                      "Step 4: Options & market cycles", "Step 5: Volume & market profile", "Step 6: Straddles, pivots, Holy Grail, ADX")

pm_section_ui <- function(ns, k) {
  keys <- pm_course_keys(k)
  if (!length(keys)) return(tags$div(style = "background:#f8fafc; border-radius:10px; padding:10px 14px; margin:14px 0; color:#475569;",
    tags$b("Pattern identification: "), "no chart pattern of the 141-pattern matrix belongs to this step (it is about ", if (k == 4) "options and market cycles" else "volume and market profile", ")."))
  cat_ <- cc_catalog[match(keys, cc_catalog$key), ]
  ch <- lapply(split(stats::setNames(keys, cat_$label), factor(cat_$group, levels = unique(cat_$group))), as.list)
  tags$div(style = "background:#ffffff; border:2px solid #6d28d9; border-radius:12px; padding:12px 16px; margin:16px 0;",
    tags$h3(style = "margin:0 0 4px 0; color:#4c1d95; font-weight:800;", sprintf("Pattern identification: the %d matrix patterns of this step", length(keys))),
    tags$div(style = "font-size:12.5px; color:#475569; margin-bottom:8px;",
      "Each pattern on a simulated 15-minute chart built from its definition: turning points on exact candles, lines through the real highs and lows, the confirming candle highlighted, entry / cancel / target. ",
      "Grey squares and dotted lines = what the app's improved rules found on the same candles."),
    fluidRow(
      column(4, selectInput(ns(paste0("pick", k)), "Pattern", ch, selected = keys[1], width = "100%")),
      column(2, tags$div(style = "margin-top:25px;", actionButton(ns(paste0("prev", k)), NULL, icon = icon("chevron-left")), actionButton(ns(paste0("next", k)), NULL, icon = icon("chevron-right")))),
      column(3, tags$div(style = "margin-top:30px;", checkboxInput(ns(paste0("det", k)), "Show what the app's rules found (grey)", TRUE))),
      column(3, tags$div(style = "margin-top:25px;", actionButton(ns(paste0("all", k)), sprintf("Check all %d patterns of this step", length(keys)), icon = icon("list-check"))))),
    uiOutput(ns(paste0("info", k))),
    plotly::plotlyOutput(ns(paste0("chart", k)), height = "560px"),
    uiOutput(ns(paste0("sum", k))), DT::DTOutput(ns(paste0("tbl", k)))) }

`%|na|%` <- function(a, b) if (is.null(a) || length(a) != 1 || is.na(a)) b else a
pattern_matrix_ui <- function(id) {
  ns <- NS(id)
  tabs <- lapply(1:6, function(k) tabPanel(pm_course_titles[k], value = paste0("step", k),
    get(paste0("weekly_activity_week", k, "_ui"))(paste0("weekly_activity_week", k)), pm_section_ui(ns, k)))
  tagList(
    tags$div(style = "background: linear-gradient(135deg, #1e1b4b 0%, #6d28d9 100%); border-radius: 12px; padding: 14px 20px; margin-bottom: 12px; color:#fff;",
      tags$h3(style = "margin:0 0 4px 0; font-size:19px; font-weight:800; color:#fff;", "Step-by-Step Practice: Steps 1 to 6"),
      tags$div(style = "font-size:13px; color:#ede9fe; line-height:1.6;",
        "The course steps with their examples. Every example that is one of the 141 matrix patterns is drawn precisely on simulated 15-minute candles and checked by the app's improved rules (the green line under it). ",
        "At the end of Steps 1, 2, 3 and 6: all the matrix patterns of that step, one by one. Simulated data only: nothing here changes your trades."),
      tags$div(style = "margin-top:8px; display:flex; flex-wrap:wrap; gap:8px; align-items:center;",
        actionButton(ns("store_all"), "Store all examples in BigQuery now", icon = icon("database"), style = "background:#fff; color:#4c1d95; font-weight:700;"),
        tags$div(style = "display:flex; gap:6px; align-items:center;",
          tags$div(style = "width:110px; margin-bottom:-15px;", passwordInput(ns("desc_code"), NULL, placeholder = "Code")),
          actionButton(ns("desc_unlock"), "Unlock", icon = icon("lock"), style = "background:#fff; color:#4c1d95; font-weight:700;"),
          uiOutput(ns("desc_btn"), inline = TRUE)),
        tags$span(style = "font-size:12.5px; color:#ede9fe;", uiOutput(ns("store_status"), inline = TRUE), tags$br(), uiOutput(ns("desc_status"), inline = TRUE)))),
    do.call(shinydashboard::tabBox, c(list(width = 12, id = ns("tabs")), tabs)))
}

pattern_matrix_server <- function(id, data_manager = NULL, api_manager = NULL, pm_backend = getOption("pm.test_backend")) {   # option: tests only
  if (!is.null(pm_backend)) pm_store_use(pm_backend) else if (!is.null(api_manager) && is.null(pm_store$backend)) pm_store_use(pm_bq_backend(api_manager))
  for (k in 1:6) get(paste0("weekly_activity_week", k, "_server"))(paste0("weekly_activity_week", k), data_manager)
  moduleServer(id, function(input, output, session) {
    # examples built here (not yet in BigQuery) are saved in batches every few seconds, and when the session ends
    tick <- reactiveVal(0)
    observe({ invalidateLater(4000); if (length(pm_store$queue)) { pm_store_flush(); tick(isolate(tick()) + 1) } })
    session$onSessionEnded(function() try(pm_store_flush(), silent = TRUE))
    output$store_status <- renderUI({ invalidateLater(3000); tick(); pm_store_status() })
    desc_tick <- reactiveVal(0); session$userData$pm_desc_rv <- desc_tick   # charts' descriptions refresh once written
    output$desc_status <- renderUI({ invalidateLater(5000); desc_tick(); pm_desc_status() })
    claude_text <- function(prompt) { if (is.null(api_manager)) stop("Claude is not connected.")
      x <- api_manager$call_claude_vision(list(), prompt, system = "You write accurate, plain-English teaching text for a trading course. Reply with JSON only.", max_tokens = 8000); if (is.list(x)) x$text %||% "" else x }
    # 'Fill missing descriptions' (after the code): re-reads BigQuery, then asks Claude ONLY for the charts / patterns that have
    # no description yet; descriptions already in BigQuery are never touched
    unlocked <- reactiveVal(FALSE)
    observeEvent(input$desc_unlock, { ok <- pm_desc_code_ok(input$desc_code); unlocked(ok); updateTextInput(session, "desc_code", value = "")
      if (!ok) showNotification("Wrong code: 'Fill missing descriptions' stays locked.", type = "error", duration = 6) })
    output$desc_btn <- renderUI({ if (!unlocked()) return(tags$span(style = "font-size:12px; color:#ede9fe;", "Enter the code to unlock 'Fill missing descriptions'."))
      actionButton(session$ns("desc_write"), "Fill missing descriptions", icon = icon("pen"), style = "background:#fde68a; color:#78350f; font-weight:800;") })
    observeEvent(input$desc_write, { req(unlocked())
      pm_desc_load(force = TRUE); miss <- pm_desc_missing()   # what BigQuery holds now
      cat(sprintf("[PM] fill missing descriptions: %d of %d have none in BigQuery\n", length(miss), length(pm_all_desc_keys())))
      if (!length(miss)) { unlocked(FALSE); desc_tick(isolate(desc_tick()) + 1); showNotification("Every chart already has its description in BigQuery: nothing to fill.", type = "message", duration = 8); return() }
      res <- withProgress(message = sprintf("Claude is writing the %d missing description(s); existing ones are not touched...", length(miss)), value = 0,
        tryCatch(pm_desc_write(getOption("pm.test_claude") %||% claude_text, keys = miss, overwrite = FALSE, progress = function(i, n) setProgress(i / n, detail = sprintf("batch %d of %d", i, n)),
                               model = if (is.null(api_manager)) "" else api_manager$claude_model %||% ""), error = function(e) list(error = conditionMessage(e))))
      desc_tick(isolate(desc_tick()) + 1); unlocked(FALSE)
      showNotification(if (!is.null(res$error)) paste("Not written:", res$error) else sprintf("%d missing description(s) written to BigQuery; %d still missing.%s", res$done, res$missing,
                         if (length(res$problems)) paste(" Problems:", paste(res$problems, collapse = "; ")) else ""), type = if (!is.null(res$error) || res$missing) "warning" else "message", duration = 10) })
    observeEvent(input$store_all, { ex <- pm_all_examples()
      pm_store_prefetch(unique(vapply(ex, function(e) pm_example_id(e$key, e$args, e$seed, e$outcome), "")))   # what is stored already is not built again
      withProgress(message = "Storing in BigQuery every example that is not there yet...", value = 0, {
        for (j in seq_along(ex)) { e <- ex[[j]]; setProgress(j / length(ex), detail = e$course_id %|na|% e$key); pm_get(e$key, e$args, e$seed, e$outcome, course_id = e$course_id)
          if (j %% 25 == 0) pm_store_flush() }
        pm_store_flush() })
      showNotification(pm_store_status(), type = if (pm_store_on()) "message" else "warning", duration = 8); tick(isolate(tick()) + 1) })
    for (k in c(1, 2, 3, 6)) local({ k <- k; keys <- pm_course_keys(k); pk <- paste0("pick", k); done <- reactiveVal(NULL)
      cur <- reactive({ key <- input[[pk]] %||% keys[1]; pm_store_prefetch(vapply(keys, pm_example_id, ""))   # the step's patterns in one query, once
        withProgress(message = if (pm_will_load(pm_example_id(key))) "Loading the example from BigQuery..." else "Building the example (BigQuery not connected)...", value = 0.5, pm_get(key)) })
      observeEvent(input[[paste0("prev", k)]], { j <- match(input[[pk]], keys); updateSelectInput(session, pk, selected = keys[max(1, j - 1)]) })
      observeEvent(input[[paste0("next", k)]], { j <- match(input[[pk]], keys); updateSelectInput(session, pk, selected = keys[min(length(keys), j + 1)]) })
      output[[paste0("info", k)]] <- renderUI({ desc_tick(); r <- cur(); cr <- cc_catalog[cc_catalog$key == r$key, ]; tr <- r$truth; o <- r$occ; col <- cc_bias_col(cr$bias)
        badge <- function(t, bg) tags$span(style = sprintf("background:%s; color:#fff; border-radius:4px; padding:1px 7px; margin-right:6px; font-size:12px; font-weight:700;", bg), t)
        tags$div(style = "background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:10px 14px; margin:6px 0;",
          tags$div(style = "font-size:17px; font-weight:800; color:#0f172a;", cr$label, tags$span(style = "margin-left:10px;", badge(tools::toTitleCase(cr$bias), col), badge(cr$group, "#64748b"),
                   badge(sprintf("regime: %s", cr$regime), "#94a3b8"), badge(if (isTRUE(r$ok)) "PASS" else "FAIL", if (isTRUE(r$ok)) "#15803d" else "#b91c1c"))),
          fluidRow(
            column(7, { d <- pm_desc_get(r$key); if (!is.null(d) && nzchar(d)) tags$div(style = "font-size:13px; margin-top:6px; line-height:1.55;", tags$b("What it is: "), d) },
                      tags$div(style = "font-size:13px; margin-top:6px;", tags$b("Definition (the rule the app applies): "), cr$rule),
                      tags$div(style = "font-size:13px; margin-top:4px;", tags$b("This example: "), tr$note)),
            column(5, tags$div(style = "font-size:12.5px; margin-top:6px; background:#fff; border-radius:8px; padding:6px 10px;",
              tags$b("What the app's improved rules found on these candles"),
              tags$ul(style = "margin:4px 0 0 0; padding-left:18px;",
                tags$li(if (isTRUE(r$found)) sprintf("Found: %s (status %s)", o$note %||% cr$label, r$status) else "Not found"),
                if (!is.null(r$points_ok) && !is.na(r$points_ok)) tags$li(sprintf("Labelled turning points matched: %s (largest difference %d candle)", if (isTRUE(r$points_ok)) "all" else "NOT all", as.integer(r$points_off %||% 0))),
                if (!is.null(r$level_off_atr)) tags$li(sprintf("Level: %.3f found vs %.3f defined (%.2f ATR apart)", o$level, tr$level, r$level_off_atr)),
                if (!is.null(r$event_ok)) tags$li(sprintf("Signal candle: %s", if (isTRUE(r$event_ok)) "the exact candle" else "NOT the same candle")),
                if (isTRUE(r$found) && is.finite(o$invalid %||% NA)) tags$li(sprintf("Their entry %.3f, cancel %.3f%s, target %s", o$entry, o$invalid, if (isTRUE(o$atr_default)) " (ATR template)" else "", if (is.finite(o$target %||% NA)) sprintf("%.3f", o$target) else "-"))))))) })
      output[[paste0("chart", k)]] <- plotly::renderPlotly({ r <- cur(); pm_chart(r, show_detected = isTRUE(input[[paste0("det", k)]])) })
      observeEvent(input[[paste0("all", k)]], {
        pm_store_prefetch(vapply(keys, pm_example_id, ""))   # one query for the whole step
        res <- withProgress(message = sprintf(if (pm_store_on()) "Loading the %d patterns of this step from BigQuery..." else "Building and checking the %d patterns of this step (BigQuery not connected)...", length(keys)), value = 0, {
          out <- list(); for (j in seq_along(keys)) { setProgress(j / length(keys), detail = keys[j]); out[[keys[j]]] <- pm_get(keys[j]) }; out })
        done(res) })
      output[[paste0("sum", k)]] <- renderUI({ r <- done(); if (is.null(r)) return(NULL); ok <- sum(vapply(r, function(x) isTRUE(x$ok), TRUE))
        tags$div(style = sprintf("margin:12px 0 6px 0; padding:8px 12px; border-radius:8px; font-weight:700; background:%s; color:%s;", if (ok == length(r)) "#dcfce7" else "#fee2e2", if (ok == length(r)) "#14532d" else "#991b1b"),
                 sprintf("%d of %d patterns of this step found exactly by the app's improved rules (click a row to show it).", ok, length(r))) })
      output[[paste0("tbl", k)]] <- DT::renderDT({ r <- done(); req(r); sm <- pm_summary(r, keys)
        dt <- DT::datatable(sm[, c("Pattern", "Bias", "Group", "Found by the rules", "Key candles", "Level", "Signal candle", "Status", "Result")], rownames = FALSE, selection = "single",
                            options = list(dom = "t", pageLength = 60, scrollX = TRUE))
        DT::formatStyle(dt, "Result", target = "row", backgroundColor = DT::styleEqual(c("PASS", "FAIL"), c("#f0fdf4", "#fee2e2"))) })
      observeEvent(input[[paste0("tbl", k, "_rows_selected")]], { j <- input[[paste0("tbl", k, "_rows_selected")]]; if (length(j)) updateSelectInput(session, pk, selected = keys[j]) })
    })
  })
}
