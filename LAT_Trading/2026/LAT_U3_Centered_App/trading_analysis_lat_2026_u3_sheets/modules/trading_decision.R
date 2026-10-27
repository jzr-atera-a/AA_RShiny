# modules/trading_decision.R
# Pre-Trade Decision Panel + Decision Journal.
# The app supplies FACTS (levels, noise, regime, calendar, risk at the IG minimum size, your own track record); you supply
# the judgement in your own words. Nothing here suggests a direction, a level or wording. A saved decision is a
# contemporaneous record: it is never edited silently (an amendment needs a note and the earlier version stays in BigQuery).
#
# Decisions are kept in trading_evidence (no new tables): kind "decision_snapshot" (status PLANNED -> LINKED / EXPIRED /
# CANCELLED) or "no_trade" (status NO_TRADE); confirmed_json holds the decision and the facts shown when it was saved.

trading_decision_ui <- function(id) {
  ns <- NS(id)
  box_txt <- function(key, label, help) tagList(
    textAreaInput(ns(paste0("d_", key)), label, rows = 3, width = "100%", placeholder = help),
    uiOutput(ns(paste0("f_", key))))
  tagList(
    tags$style(HTML("
      .dp-badge{display:inline-block;font-size:11px;padding:1px 8px;border-radius:10px;background:#e2e8f0;color:#334155;margin-left:6px;font-weight:400}
      .dp-badge.warn{background:#fef3c7;color:#92400e}.dp-badge.ok{background:#dcfce7;color:#166534}
      .dp-card{background:#ffffff;border:1px solid #e2e8f0;border-radius:10px;padding:10px 12px;margin-bottom:10px;min-height:120px}
      .dp-card h5{margin:0 0 6px 0;font-weight:700;font-size:13px;color:#0f172a}
      .dp-card .big{font-size:20px;font-weight:700;color:#0f172a}
      .dp-card .sub{font-size:12px;color:#475569;line-height:1.45}
      .dp-facts{font-size:12px;color:#334155;background:#f8fafc;border-left:3px solid #94a3b8;padding:5px 9px;margin:-6px 0 10px 0;line-height:1.5}
      .dp-warn{background:#fef2f2;border:1px solid #fecaca;color:#991b1b;border-radius:8px;padding:8px 12px;font-size:12.5px;margin-bottom:8px}
      .dp-gap{background:#fffbeb;border:1px solid #fde68a;color:#92400e;border-radius:8px;padding:8px 12px;font-size:12.5px;margin-bottom:8px}
      .dp-ok{background:#ecfdf5;border:1px solid #a7f3d0;color:#065f46;border-radius:8px;padding:8px 12px;font-size:12.5px;margin-bottom:8px}")),
    uiOutput(ns("status")),
    tabsetPanel(id = ns("tabs"),
      tabPanel("1. Before the trade",
        fluidRow(
          box(width = 12, title = "Market now", status = "primary", solidHeader = TRUE,
            fluidRow(
              column(2, selectInput(ns("asset"), "Market", choices = names(tr_yahoo_symbols), selected = "BRENT")),
              column(2, numericInput(ns("ig_price"), "IG price now (Mid)", value = NA, step = 0.1)),
              column(2, numericInput(ns("spread"), "IG spread (pts)", value = NA, step = 0.1)),
              column(3, fileInput(ns("ticket"), "Or read them from an IG ticket screenshot", accept = c("image/png", "image/jpeg"))),
              column(3, tags$div(style = "margin-top:25px;", actionButton(ns("refresh"), "Refresh prices", icon = icon("rotate")),
                                 actionButton(ns("reload"), "Reload records from BigQuery (read only)", icon = icon("database"))))),
            uiOutput(ns("price_src")))),
        fluidRow(column(12, uiOutput(ns("cards")))),
        fluidRow(
          box(width = 7, title = "15-minute chart with the reference levels", status = "primary", plotly::plotlyOutput(ns("chart"), height = "430px")),
          box(width = 5, title = "Reference levels (IG points)", status = "primary", DT::DTOutput(ns("levels_tbl")))),
        fluidRow(
          box(width = 12, title = "My decision (your own words: the app never suggests a trade)", status = "warning", solidHeader = TRUE,
            fluidRow(
              column(2, radioButtons(ns("dir"), "Decision", choices = c("Buy" = "B", "Sell" = "S", "No trade" = "N"), selected = character(0))),
              column(2, selectInput(ns("otype"), "Order type", choices = c("Market (deal now)" = "market", "Limit entry (better price)" = "limit", "Stop entry (worse price)" = "stop"))),
              column(2, numericInput(ns("entry"), "Entry", value = NA, step = 0.1), textInput(ns("expiry"), "Good till (HH:MM UK, orders)", value = "")),
              column(2, numericInput(ns("stop"), "Stop", value = NA, step = 0.1), numericInput(ns("target"), "Target (limit)", value = NA, step = 0.1)),
              column(2, numericInput(ns("size"), "Size (£ per point)", value = NA, step = 0.1), numericInput(ns("min_size"), "IG minimum size", value = 1, step = 0.1)),
              column(2, selectInput(ns("chart"), "Chart period used", choices = c("", "5 Min", "15 Min", "1 Hour", "4 Hour", "Daily")),
                        numericInput(ns("dur"), "Expected duration (hours)", value = NA, step = 0.5))),
            uiOutput(ns("plan_facts")),
            conditionalPanel(sprintf("input['%s'] == 'N'", ns("dir")),
              textAreaInput(ns("d_no_trade_reason"), "Why no trade (your own words)", rows = 3, width = "100%")),
            conditionalPanel(sprintf("input['%s'] != 'N'", ns("dir")),
              fluidRow(
                column(6, box_txt("setup_fundamental", "Set-up: fundamental", "What in the news / calendar matters for this trade, in your words."),
                          box_txt("setup_technical", "Set-up: technical", "What you see on the chart: regime, levels, pattern."),
                          box_txt("trigger_text", "Trigger", "What must happen before you enter.")),
                column(6, box_txt("execution_text", "Execution", "How you enter: order type, size, timing."),
                          box_txt("stop_reason", "Reason for Stop Loss placement", "Why the stop is where it is."),
                          box_txt("target_reason", "Reason for Target Limit placement", "Why the target is where it is.")))),
            fluidRow(
              column(6, fileInput(ns("pic_chart"), "Chart screenshot you used (optional, crop out account names / IDs)", accept = c("image/png", "image/jpeg")),
                        textInput(ns("pic_caption"), "Its caption", value = "")),
              column(6, uiOutput(ns("pics_now")))),
            uiOutput(ns("warn")), uiOutput(ns("gaps")),
            actionButton(ns("save"), "Save decision snapshot → BigQuery only", icon = icon("lock"), class = "btn-primary"),
            tags$span(style = "font-size:12px; color:#64748b; margin-left:10px;", "Saved with the time and the facts shown above. It cannot be changed later without an amendment note.")))),
      tabPanel("2. Decision journal",
        fluidRow(box(width = 12, title = "Saved decisions", status = "primary", DT::DTOutput(ns("dec_tbl")))),
        fluidRow(
          box(width = 6, title = "Selected decision", status = "primary", uiOutput(ns("dec_view"))),
          box(width = 6, title = "What happened to it", status = "warning",
            actionButton(ns("check_order"), "Check the order against prices", icon = icon("magnifying-glass")),
            uiOutput(ns("order_out")),
            tags$hr(),
            selectInput(ns("link_trade"), "It filled: link it to this trade", choices = c("(choose)" = "")),
            actionButton(ns("link"), "Link to trade (copies your pre-trade words into the trade's empty boxes) → BigQuery", icon = icon("link")),
            tags$hr(),
            textAreaInput(ns("expire_note"), "It did not fill: anything to add (your own words, optional)", rows = 2, width = "100%"),
            actionButton(ns("expire"), "Mark expired → BigQuery + save 'order not filled' Trade Sheet Word + PDF → Dropbox", icon = icon("file-word")),
            tags$hr(),
            textAreaInput(ns("amend_note"), "Amend or cancel: say why (required)", rows = 2, width = "100%"),
            actionButton(ns("amend"), "Save the form above as an amendment → BigQuery only", icon = icon("pen")),
            actionButton(ns("cancel"), "Cancel this decision → BigQuery", icon = icon("ban"))))),
      tabPanel("3. Track record & follow-through",
        fluidRow(box(width = 12, title = "Your closed trades, grouped (facts from your records)", status = "primary", uiOutput(ns("track_head")), DT::DTOutput(ns("track_tbl")))),
        fluidRow(box(width = 12, title = "After each exit: did price reach the target or the stop? (Yahoo bars aligned to each trade's own IG prices)", status = "primary",
                     DT::DTOutput(ns("follow_tbl")))))
    )
  )
}

trading_decision_server <- function(id, api_manager = NULL, store = NULL, bus = NULL, quiet = FALSE, vision_fn = NULL, yahoo_fn = NULL,
                                    pictures = NULL, now_fn = Sys.time) {
  moduleServer(id, function(input, output, session) {
    if (is.null(store)) store <- tr_make_store(tr_bq_backend(api_manager))
    if (is.null(vision_fn)) vision_fn <- function(images, prompt) api_manager$call_claude_vision(images, prompt)
    msg <- function(text, type = "message") if (!isTRUE(quiet)) showNotification(text, type = type, duration = 7)
    refresh <- reactiveVal(0); bump <- function() refresh(isolate(refresh()) + 1)
    observeEvent(input$reload, bump())
    rd <- function(name) reactive({ refresh(); if (!is.null(bus)) bus$ts; tr_read_current(store, name) })
    settings_df <- rd("settings"); sheets_df <- rd("morning_sheets"); mlevels_df <- rd("morning_levels"); trades_df <- rd("trades"); evidence_df <- rd("evidence")
    sv <- reactive({ s <- settings_df(); setNames(as.list(s$setting_value), s$setting_key) })
    num <- function(x) suppressWarnings(as.numeric(if (is.null(x) || !length(x)) NA else x))
    f1 <- function(x) tr_ntrim(round(x, 1))
    rv <- reactiveValues(pics = list(), ticket = NULL, order = NULL)
    pic_store <- function() { s <- if (!is.null(pictures)) pictures$store else NULL; if (is.null(s)) { if (is.null(rv$fallback)) rv$fallback <- tr_image_store(); s <- rv$fallback }; s }

    # ---- prices -------------------------------------------------------------------------------
    fetcher <- reactive({ input$refresh; tr_fetch_cached(if (is.null(yahoo_fn)) tr_yahoo_fetch else yahoo_fn) })
    now <- reactive({ input$refresh; now_fn() })
    asset <- reactive(toupper(tr_or(input$asset, "BRENT")))
    sym <- reactive(unname(tr_yahoo_symbols[asset()]))
    get_bars <- function(range, iv) { s <- sym(); if (is.na(s)) return(NULL)
      for (rg in unique(c(range, "1mo", "5d"))) {   # Yahoo answers HTTP 422 for some range / interval pairs: fall back to a shorter range
        p <- tryCatch(fetcher()(s, rg, iv), error = function(e) { cat("[Decision] Yahoo", s, rg, iv, ":", conditionMessage(e), "\n"); NULL })
        if (!is.null(p) && NROW(p$bars)) return(p) }
      NULL }
    raw15 <- reactive(get_bars("1mo", "15m")); raw60 <- reactive(get_bars("3mo", "60m")); rawd <- reactive(get_bars("6mo", "1d"))
    ig_price <- reactive(num(input$ig_price))
    al15 <- reactive({ p <- raw15(); if (is.null(p) || !nrow(p$bars)) NULL else tr_dec_align(p, ig_price(), asset()) })
    al60 <- reactive({ a <- al15(); if (is.null(a)) NULL else tr_dec_align_with(raw60(), a$k, a$off) })
    ald <- reactive({ a <- al15(); if (is.null(a)) NULL else tr_dec_align_with(rawd(), a$k, a$off) })
    today <- reactive(as.Date(format(now(), "%Y-%m-%d", tz = "Europe/London")))
    sheet_row <- reactive({ s <- sheets_df(); s <- s[s$sheet_id == paste0("MS_", format(today())), , drop = FALSE]; if (nrow(s)) s[1, ] else NULL })
    sheet_lv <- reactive({ l <- mlevels_df(); l[l$sheet_id == paste0("MS_", format(today())) & toupper(l$instrument) == asset(), , drop = FALSE] })
    levels <- reactive({ a <- al15(); comp <- if (is.null(a)) NULL else tr_dec_levels(a$bars, ald(), now(), today()); tr_dec_merge_levels(comp, tr_dec_sheet_levels(sheet_lv())) })
    noise <- reactive({ a <- al15(); tr_dec_noise(if (is.null(a)) NULL else a$bars) })
    thr <- reactive(c(tr_or(num(sv()$adx_trend_min), 30), tr_or(num(sv()$adx_range_max), 20)))
    reg15 <- reactive({ a <- al15(); tr_dec_regime(if (is.null(a)) NULL else a$bars, 14, thr()[1], thr()[2]) })
    reg60 <- reactive({ a <- al60(); tr_dec_regime(if (is.null(a)) NULL else a$bars, 14, thr()[1], thr()[2]) })
    price_now <- reactive({ p <- ig_price(); if (is.finite(p)) p else { a <- al15(); if (is.null(a)) NA_real_ else utils::tail(a$bars$close, 1) } })

    # ---- the decision in the form ---------------------------------------------------------------
    hold_hours <- reactive({ h <- num(input$dur); if (is.finite(h)) h else tr_or(tr_plan_duration(tr_or(input$chart, ""), tr_or(sv()$plan_durations, "")), 4) })
    form <- reactive({
      e <- num(input$entry); s <- num(input$stop); t <- num(input$target); dir <- tr_or(input$dir, "")
      sg <- if (identical(dir, "S")) -1 else 1
      d <- list(asset = asset(), direction = dir, order_type = input$otype,
                entry_type_label = switch(tr_or(input$otype, "market"), limit = if (identical(dir, "S")) "sell-limit" else "buy-limit", stop = if (identical(dir, "S")) "sell-stop" else "buy-stop", "market order"),
                entry = e, stop = s, target = t, size = num(input$size), min_size = num(input$min_size), spread = num(input$spread), ig_price = ig_price(),
                expiry_uk = trimws(tr_or(input$expiry, "")), chart_period = tr_blank_na(input$chart), expected_duration_hours = num(input$dur),
                stop_pts = if (is.finite(e) && is.finite(s)) (e - s) * sg else NA_real_, target_pts = if (is.finite(e) && is.finite(t)) (t - e) * sg else NA_real_,
                no_trade_reason = tr_blank_na(input$d_no_trade_reason))
      for (k in tr_dec_text_fields) d[[k]] <- tr_blank_na(input[[paste0("d_", k)]])
      d
    })
    cal <- reactive({ sh <- sheet_row(); n <- now()
      tr_dec_calendar(if (is.null(sh)) NA else sh$todays_releases, if (is.null(sh)) NA else sh$overnight_calendar, n, n, n + hold_hours() * 3600) })
    clock <- reactive(tr_dec_clock(now(), now() + hold_hours() * 3600))
    ctx <- reactive(list(price = price_now(), levels = levels(), noise = noise(), regime15 = reg15(), regime60 = reg60(), cal = cal(), clock = clock(), sheet = sheet_row()))
    facts <- reactive(tr_dec_box_facts(ctx(), form()))
    equity <- reactive({ t <- trades_df(); cl <- t[t$status == "CLOSED" & !is.na(t$net_pnl_gbp), , drop = FALSE]; tr_or(num(sv()$opening_balance), 10000) + sum(cl$net_pnl_gbp) })
    open_risk <- reactive({ t <- trades_df(); o <- t[t$status == "OPEN" & is.na(t$parent_trade_id), , drop = FALSE]; if (!nrow(o)) 0 else sum(o$initial_risk_gbp, na.rm = TRUE) })
    risk <- reactive({ d <- form(); if (!is.finite(d$stop_pts) || !is.finite(d$target_pts) || d$stop_pts <= 0) return(NULL)
      tr_dec_risk(d$stop_pts, d$target_pts, d$size, tr_or(d$min_size, 1), equity(), num(sv()$risk_pct), num(sv()$combined_cap_pct), num(sv()$min_rrr), open_risk(), d$spread) })
    stats <- reactive({ d <- form(); a <- al15(); if (is.null(a) || !is.finite(d$stop_pts) || !is.finite(d$target_pts) || !(d$direction %in% c("B", "S"))) return(NULL)
      tr_dec_stop_stats(a$bars, d$direction, d$stop_pts, d$target_pts, hold_bars = max(1, round(hold_hours() * 4)), sessions = 20) })
    warnings <- reactive({
      d <- form(); w <- character(0); r <- risk()
      if (!is.null(r)) w <- c(w, r$warnings, if (is.finite(r$spread_share_stop) && r$spread_share_stop > 0.2) sprintf("The spread is %.0f%% of the stop distance.", 100 * r$spread_share_stop))
      if (d$direction %in% c("B", "S")) {
        if (all(is.finite(c(d$entry, d$stop))) && (d$entry - d$stop) * (if (d$direction == "S") -1 else 1) <= 0) w <- c(w, "The stop is on the wrong side of the entry for this direction.")
        if (all(is.finite(c(d$entry, d$target))) && (d$target - d$entry) * (if (d$direction == "S") -1 else 1) <= 0) w <- c(w, "The target is on the wrong side of the entry for this direction.")
        g <- reg15(); if (grepl("^MIXED", tr_or(g$label, ""))) w <- c(w, sprintf("15-min ADX %.1f is between your thresholds (%g and %g): your plan says no trade in a mixed regime.", g$adx, thr()[2], thr()[1]))
        ev <- cal()$events; if (!is.null(ev) && nrow(ev) && any(ev$in_window & ev$importance == "High")) w <- c(w, sprintf("High-importance release(s) inside your holding window: %s.", paste(sprintf("%s %s", ev$time[ev$in_window & ev$importance == "High"], ev$event[ev$in_window & ev$importance == "High"]), collapse = "; ")))
        w <- c(w, tr_dec_text_checks(d$direction, d$stop, d$target, d$stop_reason, d$target_reason))
        if (any(grepl("^Friday|after the Friday", clock()$lines))) w <- c(w, clock()$lines[grepl("^Friday|after the Friday", clock()$lines)])
        if (is.finite(d$size) && is.finite(d$min_size) && d$size < d$min_size) w <- unique(c(w, sprintf("Size %s is below IG's minimum of %s per point.", format(d$size), format(d$min_size))))
      }
      sh <- sheet_row(); if (!is.null(sh) && isTRUE(as.logical(sh$stand_aside))) w <- c(w, "Your Morning Sheet for today says stand aside.")
      unique(w)
    })
    gaps <- reactive({ d <- form(); if (!(d$direction %in% c("B", "S", "N"))) return(c("Decision (Buy, Sell or No trade)", if (!is.finite(d$ig_price)) "IG price (levels are not aligned to IG without it)")); g <- tr_dec_gaps(d)
      if (d$direction %in% c("B", "S")) { if (!is.finite(d$entry)) g <- c(g, "Entry"); if (!is.finite(d$stop)) g <- c(g, "Stop"); if (!is.finite(d$target)) g <- c(g, "Target") }
      if (!is.finite(d$ig_price)) g <- unique(c(g[!grepl("^IG price", g)], "IG price (levels are not aligned to IG without it)"))
      g })

    # ---- IG ticket screenshot -> IG price, spread, size, minimum size ------------------------------------
    observeEvent(input$ticket, {
      f <- input$ticket; req(f)
      img <- tryCatch(tr_read_image(f$datapath, f$name), error = function(e) { msg(conditionMessage(e), "error"); NULL }); if (is.null(img)) return()
      res <- tryCatch(vision_fn(list(list(media_type = img$media_type, data = img$data)), tr_vision_prompt("ticket", "desktop")), error = function(e) { msg(paste("Claude could not read the image:", conditionMessage(e)), "error"); NULL })
      parsed <- if (is.null(res)) NULL else tr_parse_vision_json(res$text); if (is.null(parsed)) { if (!is.null(res)) msg("Claude's reply could not be read: type the values instead.", "error"); return() }
      e <- tr_normalise_extraction(parsed, "ticket"); rv$ticket <- list(values = e, quote_time = e$quote_time, read_at = format(now_fn(), "%H:%M", tz = "Europe/London"))
      mid <- if (is.finite(e$sell) && is.finite(e$buy)) (e$sell + e$buy) / 2 else e$current
      if (is.finite(mid)) updateNumericInput(session, "ig_price", value = round(mid, 2))
      if (is.finite(e$spread)) updateNumericInput(session, "spread", value = round(e$spread, 2))
      if (is.finite(e$size)) updateNumericInput(session, "size", value = e$size)
      if (is.finite(tr_or(e$min_size, NA))) updateNumericInput(session, "min_size", value = e$min_size)
      if (!is.na(e$asset) && e$asset %in% names(tr_yahoo_symbols)) updateSelectInput(session, "asset", selected = e$asset)
      if (is.finite(e$stop)) updateNumericInput(session, "stop", value = e$stop)
      if (is.finite(e$limit)) updateNumericInput(session, "target", value = e$limit)
      path <- tryCatch(pic_store()$put(f$datapath, tr_picture_rel(tr_id("PIC"), f$name, today()))$path, error = function(e) NA_character_)
      rv$pics[["entry_platform"]] <- list(slot = "entry_platform", path = path, name = f$name, md5 = img$md5, mime = img$media_type, size = img$bytes,
        caption = sprintf("IG deal ticket for %s%s. Source: IG trading platform (demo account), screenshot by the author.", tr_asset_label(asset()), if (!is.na(e$quote_time)) paste0(", quote time ", e$quote_time, " UK") else ""))
      msg(sprintf("Read from the ticket: Sell %s, Buy %s%s. Check them.", tr_or(f1(e$sell), "-"), tr_or(f1(e$buy), "-"), if (is.finite(tr_or(e$min_size, NA))) paste0(", minimum size ", e$min_size) else ""))
    })
    observeEvent(input$pic_chart, {
      f <- input$pic_chart; req(f)
      path <- tryCatch(pic_store()$put(f$datapath, tr_picture_rel(tr_id("PIC"), f$name, today()))$path, error = function(e) { msg(conditionMessage(e), "error"); NA_character_ })
      rv$pics[["entry"]] <- list(slot = "entry", path = path, name = f$name, md5 = NA_character_, mime = NA_character_, size = NA_integer_, caption = tr_blank_na(input$pic_caption))
    })
    output$pics_now <- renderUI({ p <- rv$pics; if (!length(p)) return(tags$div(style = "font-size:12px; color:#64748b; margin-top:25px;", "No screenshots attached to this decision yet."))
      tags$div(style = "font-size:12px; margin-top:25px;", tags$b("Attached to this decision: "), paste(vapply(p, function(x) sprintf("%s (%s)", x$name, x$slot), ""), collapse = ", ")) })

    # ---- outputs: header and cards ---------------------------------------------------------------------
    output$status <- renderUI({
      bq <- store$connected(); sh <- sheet_row()
      pill <- function(ok, t) tags$span(style = paste0("display:inline-block; margin:0 8px 8px 0; padding:3px 10px; border-radius:12px; font-size:12px; color:#ffffff; background:", if (ok) "#15803d" else "#b45309"), t)
      tags$div(pill(bq, if (bq) "BigQuery connected" else "BigQuery not connected: decisions kept in this session only"),
               pill(!is.null(sh), if (is.null(sh)) sprintf("No Morning Sheet for %s yet", format(today(), "%d/%m/%Y")) else sprintf("Morning Sheet %s loaded", format(today(), "%d/%m/%Y"))),
               pill(is.finite(ig_price()), if (is.finite(ig_price())) "Levels aligned to your IG price" else "Type the IG price (or read a ticket) to align the levels"),
               tags$span(style = "display:inline-block; margin:0 8px 8px 0; padding:3px 10px; border-radius:12px; font-size:12px; color:#0f172a; background:#e2e8f0;", sprintf("UK time %s", format(now(), "%a %d/%m %H:%M", tz = "Europe/London"))))
    })
    output$price_src <- renderUI({
      a <- al15(); if (is.null(a)) return(tags$div(class = "dp-gap", sprintf("No Yahoo prices for %s right now (%s). Type the levels from IG yourself.", asset(), tr_or(sym(), "no symbol"))))
      last <- format(a$last_time + 900, "%H:%M", tz = "Europe/London")
      tags$div(style = "font-size:12.5px; color:#334155;",
        if (a$aligned) tags$span(sprintf("Yahoo %s bars (to %s UK) scaled x%g and shifted %+.1f pts so the last close equals your IG price %s.", sym(), last, a$k, a$off, f1(ig_price())), tags$span(class = "dp-badge ok", tr_dec_badge[["yahoo_aligned"]]))
        else tags$span(sprintf("Yahoo %s bars (to %s UK) scaled x%g only.", sym(), last, a$k), tags$span(class = "dp-badge warn", tr_dec_badge[["yahoo_raw"]])),
        if (!is.null(rv$ticket)) tags$span(class = "dp-badge", sprintf("IG ticket read at %s", rv$ticket$read_at)),
        if (nrow(sheet_lv())) tags$span(class = "dp-badge", "session, pivot and overnight levels from your Morning Sheet"))
    })
    card <- function(title, big, sub, badge) column(3, tags$div(class = "dp-card", tags$h5(title, tags$span(class = "dp-badge", badge)), tags$div(class = "big", big), tags$div(class = "sub", HTML(paste(sub, collapse = "<br>")))))
    output$cards <- renderUI({
      n <- noise(); g <- reg15(); g6 <- reg60(); c0 <- cal(); ck <- clock(); px <- price_now(); nb <- tr_dec_nearest(levels(), px)
      ev <- c0$events; trk <- track()
      fluidRow(
        card("Where price is", if (is.finite(px)) f1(px) else "-",
             c(if (!is.null(nb$above)) sprintf("Above: %s %s (+%s)", nb$above$name, f1(nb$above$level), f1(nb$above$level - px)) else "No level above",
               if (!is.null(nb$below)) sprintf("Below: %s %s (-%s)", nb$below$name, f1(nb$below$level), f1(px - nb$below$level)) else "No level below"),
             if (is.finite(ig_price())) "IG" else "Yahoo"),
        card("Noise (how far price moves)", if (is.finite(n$range3h)) paste(f1(n$range3h), "pts / 3h") else "-",
             c(sprintf("15-min ATR(14): %s pts", tr_or(f1(n$atr15), "-")), sprintf("Average day range: %s pts (%d sessions)", tr_or(f1(n$day_range), "-"), n$days)), "computed"),
        card("Regime (your ADX thresholds)", tr_or(g$label, "-"),
             c(sprintf("15-min ADX %s; %s", tr_or(f1(g$adx), "-"), tr_or(g$direction, "")), sprintf("1-hour ADX %s: %s", tr_or(f1(g6$adx), "-"), tr_or(g6$label, "-")),
               sprintf("Trend above %g, range below %g", thr()[1], thr()[2])), "computed"),
        card("Calendar and clock", if (!is.null(c0$next_high)) sprintf("%s in %d min", c0$next_high$time, round(c0$minutes_to_next_high)) else "No high release ahead",
             c(if (!is.null(c0$next_high)) paste(c0$next_high$country, c0$next_high$event), if (!is.null(ev) && nrow(ev)) sprintf("%d event(s) today, %d in your %s-hour window", nrow(ev), sum(ev$in_window), f1(hold_hours())) else "No calendar on today's Morning Sheet", ck$lines),
             "Morning Sheet"),
        if (!is.null(trk)) column(12, tags$div(class = "dp-card", style = "min-height:0;", tags$h5("Your own record so far", tags$span(class = "dp-badge", tr_dec_badge[["records"]])),
          tags$div(class = "sub", sprintf("%d closed trade(s), %d won, net £%.2f; average win £%s, average loss £%s. Grouped figures in tab 3.", trk$n, trk$wins, trk$net,
                                          tr_or(sprintf("%.2f", trk$avg_win), "-"), tr_or(sprintf("%.2f", trk$avg_loss), "-"))))))
    })
    output$levels_tbl <- DT::renderDT({
      lv <- levels(); px <- price_now()
      if (is.null(lv) || !nrow(lv)) return(DT::datatable(data.frame(Message = "No levels yet."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(data.frame(Level = lv$name, Price = round(lv$level, 1), `Distance (pts)` = if (is.finite(px)) round(lv$level - px, 1) else NA, From = lv$group, check.names = FALSE),
                    rownames = FALSE, options = list(dom = "t", pageLength = 40, scrollY = "360px", ordering = FALSE))
    })
    output$chart <- plotly::renderPlotly({
      a <- al15(); if (is.null(a)) return(plotly::plotly_empty(type = "scatter", mode = "markers"))
      b <- utils::tail(a$bars, 4 * 24); b$uk <- format(b$time, "%Y-%m-%d %H:%M", tz = "Europe/London")
      p <- plotly::plot_ly(b, x = ~uk, type = "candlestick", open = ~open, high = ~high, low = ~low, close = ~close, name = "15 min")
      lv <- levels(); rng <- range(c(b$low, b$high)); shapes <- list(); ann <- list()
      if (!is.null(lv) && nrow(lv)) { lv <- lv[lv$level >= rng[1] - diff(rng) * 0.3 & lv$level <= rng[2] + diff(rng) * 0.3, , drop = FALSE]
        for (i in seq_len(nrow(lv))) { shapes[[length(shapes) + 1]] <- list(type = "line", xref = "paper", x0 = 0, x1 = 1, y0 = lv$level[i], y1 = lv$level[i], line = list(color = "#94a3b8", width = 1, dash = "dot"))
          ann[[length(ann) + 1]] <- list(xref = "paper", x = 1, xanchor = "right", y = lv$level[i], text = substr(lv$name[i], 1, 32), showarrow = FALSE, font = list(size = 9, color = "#475569")) } }
      d <- form()
      for (z in list(list(d$entry, "#1d4ed8", "Entry"), list(d$stop, "#b91c1c", "Stop"), list(d$target, "#15803d", "Target"))) if (is.finite(z[[1]])) {
        shapes[[length(shapes) + 1]] <- list(type = "line", xref = "paper", x0 = 0, x1 = 1, y0 = z[[1]], y1 = z[[1]], line = list(color = z[[2]], width = 2))
        ann[[length(ann) + 1]] <- list(xref = "paper", x = 0, xanchor = "left", y = z[[1]], text = paste(z[[3]], f1(z[[1]])), showarrow = FALSE, font = list(size = 10, color = z[[2]])) }
      plotly::layout(p, shapes = shapes, annotations = ann, xaxis = list(rangeslider = list(visible = FALSE), title = "UK time", type = "category", nticks = 8), yaxis = list(title = "IG points"),
                     margin = list(l = 50, r = 10, t = 10, b = 40), showlegend = FALSE)
    })

    # ---- outputs: facts beside the form ---------------------------------------------------------------
    for (k in tr_dec_text_fields) local({ kk <- k
      output[[paste0("f_", kk)]] <- renderUI({ x <- facts()[[kk]]; if (!length(x)) return(NULL); tags$div(class = "dp-facts", HTML(paste(htmltools::htmlEscape(x), collapse = "<br>"))) }) })
    output$plan_facts <- renderUI({
      d <- form(); r <- risk(); st <- stats(); ms <- tr_or(d$min_size, 1)
      if (is.null(r)) return(tags$div(style = "font-size:12.5px; color:#64748b; margin-bottom:8px;", "Enter entry, stop and target to see the risk at the size you can trade, and how often stops and targets of these sizes were touched recently."))
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px; font-size:12.5px; color:#1e293b; line-height:1.6;",
        tags$div(sprintf("Stop %s pts, target %s pts, RRR %.2f. At £%s per point: risk £%.2f (%.2f%% of equity £%.0f), reward £%.2f. Open risk with this trade: %.2f%%.",
                         f1(d$stop_pts), f1(d$target_pts), r$rrr, format(r$size), r$risk_gbp, r$risk_pct, equity(), r$reward_gbp, r$combined_pct)),
        if (is.finite(r$max_stop_at_plan)) tags$div(sprintf("Largest stop your plan's %s%% allows at £%s per point: %s pts. Stop needed here: %s pts.", tr_or(sv()$risk_pct, "?"), format(max(r$size, ms)), f1(r$max_stop_at_plan), f1(d$stop_pts))),
        if (!is.null(st)) tags$div(sprintf("Last %d sessions, from every 15-min close (n = %d): a %s-pt adverse move happened within %s hours %.0f%% of the time; a %s-pt favourable move came first %.0f%% of the time. This describes recent movement, not this set-up.",
                                           st$sessions, st$n, f1(d$stop_pts), f1(st$hold_hours), 100 * st$stop_touched, f1(d$target_pts), 100 * st$target_first)) else NULL,
        tags$span(class = "dp-badge", "computed"))
    })
    output$warn <- renderUI({ w <- warnings(); if (!length(w)) return(NULL); tags$div(class = "dp-warn", tags$b("Check against your plan: "), tags$ul(style = "margin:4px 0 0 0;", lapply(w, tags$li))) })
    output$gaps <- renderUI({ g <- gaps(); if (!length(g)) return(tags$div(class = "dp-ok", "Every part of the decision is filled in."))
      tags$div(class = "dp-gap", tags$b("Still missing (you can save anyway; the gaps are recorded): "), paste(g, collapse = "; ")) })

    # ---- save ----------------------------------------------------------------------------------------------
    snapshot <- function(d) {
      a <- isolate(al15()); lv <- isolate(levels()); n <- isolate(noise()); r <- isolate(risk()); st <- isolate(stats())
      d$facts <- list(levels = if (is.null(lv)) NULL else data.frame(name = lv$name, level = round(lv$level, 2), group = lv$group),
                      align = if (is.null(a)) NULL else list(k = a$k, off = a$off, aligned = a$aligned, last_bar_uk = format(a$last_time + 900, "%Y-%m-%d %H:%M", tz = "Europe/London"), symbol = isolate(sym())),
                      noise = n[c("atr15", "range3h", "day_range", "days")], regime15 = isolate(reg15())[c("adx", "label")], regime60 = isolate(reg60())[c("adx", "label")],
                      risk = if (is.null(r)) NULL else r[c("size", "risk_gbp", "risk_pct", "combined_pct", "rrr", "max_stop_at_plan")], stop_stats = st,
                      boxes = isolate(facts()), clock = isolate(clock())$lines, warnings = isolate(warnings()), gaps = isolate(gaps()),
                      ticket = if (is.null(rv$ticket)) NULL else rv$ticket$values[c("sell", "buy", "spread", "size", "min_size", "stop", "limit", "quote_time")])
      d$k <- if (is.null(a)) NA else a$k; d$off <- if (is.null(a)) NA else a$off
      d
    }
    write_pics <- function(owner) for (p in rv$pics) if (!is.na(tr_or(p$path, NA)))
      store$write("evidence", tr_picture_row(tr_id("EV"), owner, p$slot, p$caption, p$path, p$name, p$md5, p$size, p$mime))
    observeEvent(input$save, {
      d <- form(); if (!(d$direction %in% c("B", "S", "N"))) { msg("Choose Buy, Sell or No trade first.", "error"); return() }
      t0 <- now_fn(); id <- tr_id("DEC")
      d$decision_id <- id; d$saved_at_uk <- format(t0, "%Y-%m-%d %H:%M", tz = "Europe/London"); d$first_saved_uk <- d$saved_at_uk
      d$order_time <- d$saved_at_uk; d$sheet_id <- paste0("MS_", format(today()))
      d <- snapshot(d)
      res <- store$write("evidence", tr_dec_ev_row(id, 1L, if (d$direction == "N") "NO_TRADE" else "PLANNED", d))
      write_pics(id); rv$pics <- list(); bump()
      msg(sprintf("Decision saved at %s UK (%s)%s.", format(t0, "%H:%M", tz = "Europe/London"), id, if (identical(res, "pending")) ", in this session only until BigQuery is connected" else ""))
    })

    # ---- journal -------------------------------------------------------------------------------------------
    decisions <- reactive(tr_dec_from_evidence(evidence_df()))
    output$dec_tbl <- DT::renderDT({
      d <- decisions(); if (!nrow(d)) return(DT::datatable(data.frame(Message = "No decisions saved yet."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(data.frame(Saved = d$first_saved_uk, Market = d$asset, Decision = c(B = "Buy", S = "Sell", N = "No trade")[d$direction], Order = d$order_type,
                               Entry = d$entry, Stop = d$stop, Target = d$target, Size = d$size, `Good till` = d$expiry, Status = d$status, Trade = d$trade_id,
                               Warnings = d$warnings, Version = d$record_version, ID = d$decision_id, check.names = FALSE),
                    rownames = FALSE, selection = "single", options = list(dom = "tp", pageLength = 10, scrollX = TRUE))
    })
    sel_id <- reactive({ i <- input$dec_tbl_rows_selected; d <- decisions(); if (is.null(i) || !length(i) || i > nrow(d)) NULL else d$decision_id[i] })
    sel_dec <- reactive({ id <- sel_id(); if (is.null(id)) NULL else tr_dec_get(evidence_df(), id) })
    output$dec_view <- renderUI({
      d <- sel_dec(); if (is.null(d)) return(tags$div(style = "color:#64748b; font-size:12.5px;", "Select a decision in the table."))
      row <- function(l, v) if (!is.null(v) && length(v) && !all(is.na(v)) && nzchar(paste(v, collapse = ""))) tags$div(style = "margin-bottom:6px;", tags$b(l, ": "), paste(v, collapse = " "))
      tags$div(style = "font-size:12.5px; line-height:1.5;",
        row("Saved", sprintf("%s UK (version %s, status %s)", d$first_saved_uk, d$record_version, d$status)),
        row("Decision", sprintf("%s %s %s, entry %s, stop %s, target %s, size %s%s", c(B = "Buy", S = "Sell", N = "No trade")[[tr_or(d$direction, "N")]], d$asset, tr_or(d$entry_type_label, ""),
                                tr_or(d$entry, "-"), tr_or(d$stop, "-"), tr_or(d$target, "-"), tr_or(d$size, "-"), if (nzchar(tr_or(d$expiry_uk, ""))) paste(", good till", d$expiry_uk) else "")),
        row("IG price when saved", d$ig_price), row("Why no trade", d$no_trade_reason),
        row("Set-up (fundamental)", d$setup_fundamental), row("Set-up (technical)", d$setup_technical), row("Trigger", d$trigger_text), row("Execution", d$execution_text),
        row("Reason for stop", d$stop_reason), row("Reason for target", d$target_reason),
        if (length(d$facts$warnings)) tags$div(class = "dp-warn", tags$b("Warnings shown when saved: "), paste(d$facts$warnings, collapse = " | ")),
        if (length(d$facts$gaps)) tags$div(class = "dp-gap", tags$b("Missing when saved: "), paste(d$facts$gaps, collapse = "; ")),
        if (length(d$amendments)) tags$div(class = "dp-gap", tags$b("Amendments: "), paste(sprintf("%s: %s", d$amendments$at, d$amendments$note), collapse = " | ")))
    })
    observe({ t <- trades_df(); t <- t[t$status %in% c("OPEN", "CLOSED") & is.na(t$parent_trade_id), , drop = FALSE]; t <- t[order(t$entry_ts, decreasing = TRUE), , drop = FALSE]
      updateSelectInput(session, "link_trade", choices = c("(choose)" = "", setNames(t$trade_id, sprintf("%s %s %s at %s (%s)", t$asset, ifelse(t$direction == "B", "Buy", "Sell"),
                                                                                                     format(t$entry_ts, "%d/%m %H:%M", tz = "Europe/London"), t$entry_price, t$trade_id)))) })
    bars_for <- function(d) { p <- raw15(); if (is.null(p) || !is.finite(num(d$k))) NULL else tr_dec_align_with(p, num(d$k), num(d$off))$bars }
    order_times <- function(d) { placed <- as.POSIXct(tr_or(d$order_time, d$first_saved_uk), tz = "Europe/London", format = "%Y-%m-%d %H:%M")
      ex <- if (grepl("^\\d{1,2}:\\d{2}$", tr_or(d$expiry_uk, ""))) as.POSIXct(paste(format(placed, "%Y-%m-%d", tz = "Europe/London"), d$expiry_uk), tz = "Europe/London") else as.POSIXct(NA)
      list(placed = placed, expiry = ex) }
    observeEvent(input$check_order, {
      d <- sel_dec(); if (is.null(d) || !(d$direction %in% c("B", "S"))) { msg("Select a Buy or Sell decision first.", "warning"); return() }
      if (identical(d$order_type, "market")) { rv$order <- list(status = "MARKET", lines = "A market order fills at once: link it to the trade."); return() }
      tm <- order_times(d); b <- bars_for(d)
      rv$order <- tr_dec_order_outcome(b, d$direction, d$order_type, num(d$entry), tm$placed, tm$expiry, tr_or(num(d$spread), 0) / 2, now = now_fn())
      if (!is.null(rv$order) && identical(rv$order$status, "EXPIRED")) rv$order$lines <- c(rv$order$lines, tr_dec_after(b, tm$expiry, min(now_fn(), tm$expiry + 5 * 3600)))
    })
    output$order_out <- renderUI({ o <- rv$order; if (is.null(o)) return(NULL)
      tags$div(class = if (identical(o$status, "EXPIRED")) "dp-gap" else "dp-ok", style = "margin-top:8px;", tags$b(o$status, ": "), paste(o$lines, collapse = " "),
               tags$div(class = "dp-badge", tr_dec_badge[["yahoo_aligned"]])) })
    new_version <- function(d, status, trade_id = NA_character_, notes = NA_character_) {
      store$write("evidence", tr_dec_ev_row(d$decision_id, as.integer(d$record_version) + 1L, status, d[setdiff(names(d), c("status", "record_version"))], trade_id, notes)); bump() }
    observeEvent(input$link, {
      d <- sel_dec(); tid <- tr_or(input$link_trade, ""); if (is.null(d) || !nzchar(tid)) { msg("Select a decision and a trade.", "warning"); return() }
      tr_dec_link(store, d, tid); bump(); msg(sprintf("Decision linked to %s. Your pre-trade words fill the trade's empty boxes.", tid))
    })
    observeEvent(input$cancel, {
      d <- sel_dec(); note <- trimws(tr_or(input$amend_note, "")); if (is.null(d)) return()
      if (!nzchar(note)) { msg("Say why you cancel it (amend / cancel box).", "error"); return() }
      d$amendments <- rbind(as.data.frame(tr_or(d$amendments, data.frame(at = character(0), note = character(0)))), data.frame(at = format(now_fn(), "%Y-%m-%d %H:%M", tz = "Europe/London"), note = paste("Cancelled:", note)))
      new_version(d, "CANCELLED", notes = note); msg("Decision marked cancelled (the saved version is kept).")
    })
    observeEvent(input$amend, {
      d0 <- sel_dec(); note <- trimws(tr_or(input$amend_note, "")); if (is.null(d0)) { msg("Select the decision to amend.", "warning"); return() }
      if (!nzchar(note)) { msg("An amendment needs a note saying what changed and why.", "error"); return() }
      d <- form(); d$decision_id <- d0$decision_id; d$record_version <- d0$record_version; d$first_saved_uk <- d0$first_saved_uk; d$order_time <- tr_or(d0$order_time, d0$first_saved_uk)
      d$saved_at_uk <- format(now_fn(), "%Y-%m-%d %H:%M", tz = "Europe/London"); d$sheet_id <- d0$sheet_id
      prev <- d0[c("saved_at_uk", tr_dec_text_fields, "entry", "stop", "target", "size")]; prev <- lapply(prev, function(x) tr_or(x, NA))
      d$history <- c(tr_or(d0$history, list()), list(prev))
      d$amendments <- rbind(as.data.frame(tr_or(d0$amendments, data.frame(at = character(0), note = character(0)))), data.frame(at = d$saved_at_uk, note = note))
      d <- snapshot(d); new_version(d, if (d$direction == "N") "NO_TRADE" else tr_or(d0$status, "PLANNED"), tr_or(d0$trade_id, NA), note)
      msg("Amendment saved as a new version; the first version stays in the record.")
    })
    observeEvent(input$expire, {
      d <- sel_dec(); if (is.null(d) || !(d$direction %in% c("B", "S"))) { msg("Select a Buy or Sell order first.", "warning"); return() }
      tm <- order_times(d); b <- bars_for(d)
      o <- tr_dec_order_outcome(b, d$direction, d$order_type, num(d$entry), tm$placed, tm$expiry, tr_or(num(d$spread), 0) / 2, now = now_fn())
      lines <- c(sprintf("%s order at %s (size £%s per point, stop %s, limit %s), placed %s UK%s.", tools::toTitleCase(tr_or(d$entry_type_label, "order")), tr_ntrim(num(d$entry)), format(num(d$size)),
                         tr_ntrim(num(d$stop)), tr_ntrim(num(d$target)), format(tm$placed, "%H:%M", tz = "Europe/London"), if (!is.na(tm$expiry)) paste(", good till", format(tm$expiry, "%d/%m/%Y %H:%M", tz = "Europe/London")) else ""),
                 if (!is.null(o)) o$lines, if (!is.null(b) && !is.na(tm$expiry)) tr_dec_after(b, tm$expiry, min(now_fn(), tm$expiry + 5 * 3600)),
                 "No stop moves or partial exits: no position existed.", tr_blank_na(input$expire_note))
      lines <- lines[!is.na(lines) & nzchar(lines)]
      if (!is.null(o) && identical(o$status, "FILLED_LIKELY")) msg("The prices suggest this order may have filled: check IG History before marking it expired.", "warning")
      pics <- tr_pictures_for(evidence_df(), d$decision_id); pics <- data.frame(slot = pics$slot, event_id = NA_character_, caption = pics$caption,
                                                                                  path = vapply(pics$dropbox_path, function(p) tryCatch(pic_store()$get(p), error = function(e) NA_character_), ""), stringsAsFactors = FALSE)
      ch <- if (!is.null(b)) tr_dec_order_chart_png(b, d, tm$placed, tm$expiry) else NULL
      if (!is.null(ch) && !("entry" %in% pics$slot)) pics <- rbind(data.frame(slot = "entry", event_id = NA_character_, caption = ch$caption, path = ch$file, stringsAsFactors = FALSE), pics)
      pics <- pics[!is.na(pics$path) & file.exists(pics$path), , drop = FALSE]
      day <- as.Date(format(tm$placed, "%Y-%m-%d", tz = "Europe/London")); out <- file.path(tempdir(), tr_dec_nofill_filename(d$asset, day))
      name <- sprintf("%s (%s)", tr_or(sv()$trader_name, ""), tr_or(sv()$student_id, ""))
      ok <- tryCatch({ tr_no_fill_sheet_docx(d, name, pics, out, lines); TRUE }, error = function(e) { msg(paste("Could not build the sheet:", conditionMessage(e)), "error"); FALSE })
      if (!ok) return()
      pdf <- tryCatch(tr_docx_to_pdf(out), error = function(e) NA_character_)
      sv_res <- tryCatch(tr_save_sheet(c(out, pdf), "trade"), error = function(e) { msg(paste("Saving to Dropbox failed:", conditionMessage(e)), "error"); NULL })
      d$no_fill_lines <- lines; new_version(d, "EXPIRED")
      rv$order <- list(status = "EXPIRED", lines = c(sprintf("Saved %s%s.", basename(out), if (!is.na(pdf)) " and the PDF" else " (no PDF: LibreOffice not found)"),
                                                    if (!is.null(sv_res) && nrow(sv_res)) sprintf("%s -> %s", sv_res$file, sv_res$where)))
      msg(sprintf("Order marked expired; %s saved to Individual Trade Sheets.", basename(out)))
    })

    # ---- track record and follow-through ------------------------------------------------------------------
    closed <- reactive({ t <- trades_df(); t[t$status == "CLOSED" & is.na(t$parent_trade_id) & toupper(t$asset) == asset(), , drop = FALSE] })
    track <- reactive({ c0 <- closed(); if (!nrow(c0)) NULL else tr_dec_track(c0, raw15(), tr_or(al15()$k, tr_dec_default_scale(asset()))) })
    output$track_head <- renderUI({ t <- track(); if (is.null(t)) return(tags$div(style = "color:#64748b;", sprintf("No closed %s trades yet.", asset())))
      tags$div(style = "font-size:12.5px; margin-bottom:6px;", sprintf("%d closed %s trade(s): %d won, net £%.2f.", t$n, asset(), t$wins, t$net)) })
    output$track_tbl <- DT::renderDT({ t <- track(); if (is.null(t)) return(NULL)
      DT::datatable(t$by, rownames = FALSE, options = list(dom = "t", pageLength = 50, ordering = FALSE)) })
    output$follow_tbl <- DT::renderDT({
      c0 <- closed(); if (!nrow(c0)) return(DT::datatable(data.frame(Message = "No closed trades yet."), rownames = FALSE, options = list(dom = "t")))
      k <- tr_or(al15()$k, tr_dec_default_scale(asset())); p <- raw15()
      rows <- lapply(seq_len(nrow(c0)), function(i) { r <- c0[i, ]; f <- tr_dec_follow(r, p, k, now = now_fn())
        yn <- function(x) if (is.null(x) || is.na(x)) "-" else if (isTRUE(x)) "yes" else "no"
        data.frame(Trade = r$trade_id, Entry = format(r$entry_ts, "%d/%m %H:%M", tz = "Europe/London"), Side = ifelse(r$direction == "B", "Buy", "Sell"), Exit = tr_or(r$exit_code, "-"),
                   `Best in trade (pts)` = if (is.null(f)) NA else round(f$mfe, 1), `Worst in trade (pts)` = if (is.null(f)) NA else round(f$mae, 1),
                   `Hours checked after exit` = if (is.null(f)) NA else round(f$after_hours, 1), `Reached target after exit` = yn(f$reached_target),
                   `Reached stop after exit` = yn(f$reached_stop), `Stopped, then target` = yn(f$stopped_then_target), check.names = FALSE, stringsAsFactors = FALSE) })
      DT::datatable(do.call(rbind, rows), rownames = FALSE, options = list(dom = "tp", pageLength = 15, scrollX = TRUE))
    })
    invisible(list(decisions = decisions))
  })
}
