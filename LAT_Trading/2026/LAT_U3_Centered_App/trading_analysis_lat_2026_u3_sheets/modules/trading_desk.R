# modules/trading_desk.R - one sidebar item for the daily work: Morning Sheet, market & patterns, plan & order,
# positions, journal + Individual Trade Sheet (Capital.com first), with the IG screenshot flow, Yahoo, statistics,
# exports and schemas in the same horizontal tabs. The four modules keep their own server logic and BigQuery tables
# (trading_* and cc_*); this file only arranges their screens and keeps the shared plan settings in step.

desk_essential <- c("2. Morning Sheet", "3. Market & Patterns", "4. Plan & Order", "5. Positions & Sync", "6. Journal & Trade Sheet")

trading_desk_ui <- function() {
  tr <- desk_parts(trading_records_ui("trading_records", parts = TRUE))
  cc <- desk_parts(cc_trading_records_ui("cc_records", parts = TRUE))
  body <- function(tp) tp$children
  sec <- function(title, ..., tint = "#f8fafc") tags$div(style = sprintf("background:%s; border:1px solid #e2e8f0; border-radius:10px; padding:10px 14px; margin:10px 0;", tint),
                                                       tags$div(style = "font-weight:800; color:#0b3b3a; font-size:15px; margin-bottom:6px;", title), ...)
  fold <- function(title, ...) tags$div(style = "overflow:hidden; margin-top:10px;", fluidRow(shinydashboard::box(width = 12, title = title, collapsible = TRUE, collapsed = TRUE, status = "info", solidHeader = FALSE, ...)))
  tab <- function(title, ..., value = title) tabPanel(title, ..., value = value)
  home <- function(key, ...) tags$div(class = "desk-home", `data-sec` = key, tags$div(class = "desk-sec", id = paste0("desk-sec-", key), ...))
  homes <- function(tp, map, ...) { ch <- body(tp); tagList(lapply(names(map), function(k) home(k, ch[map[[k]]], if (identical(k, names(map)[length(map)])) list(...)))) }
  sel <- function(suffix = "", li = "li") paste(sprintf('#trading_records-tabs > %s > a[data-value="%s"]%s', li, desk_essential, suffix), collapse = ", ")
  tagList(
    tags$style(HTML(paste0(sel(), " { background:#dcfce7 !important; color:#14532d !important; font-weight:700; }\n",
                           sel(":hover"), " { background:#bbf7d0 !important; }\n",
                           sel("", "li.active"), " { background:#86efac !important; color:#052e16 !important; }\n",
                           ".desk-hub .cc-dup { display:none; }"))),
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #0f766e 100%); border-radius: 12px; padding: 14px 20px; margin-bottom: 12px; color:#fff;",
      tags$h3(style = "margin:0 0 4px 0; font-size:19px; font-weight:800; color:#fff;", "Trading Desk: Morning Sheet, order on Capital.com, Individual Trade Sheet"),
      tags$div(style = "font-size:13px; color:#d1fae5; line-height:1.6;",
        "Every day, the ", tags$span(style = "background:#dcfce7; color:#14532d; border-radius:4px; padding:0 6px; font-weight:700;", "green tabs"), " in order: ",
        "2 Morning Sheet, 3 Market & Patterns, 4 Plan & Order (sent to the Capital.com demo), 5 Positions & Sync (picks up the close), 6 Journal & Trade Sheet. ",
        "Trades on IG are recorded from screenshots in tab 7. Your own words are never written by the app.")),
    tags$script(HTML(desk_move_js)),
    uiOutput("cc_records-status_bar"), uiOutput("trading_records-statusBar"),
    tags$div(class = "desk-hub", do.call(shinydashboard::tabBox, c(list(width = 12, id = "trading_records-tabs"), list(
      tab("Guided Desk ******", value = "Guided Desk", desk_guided_ui()),
      tab("1. Setup",
          sec("Plan, period, Dropbox and records (shared by every tab)", body(tr[[1]])),
          sec("Capital.com", tags$div(style = "font-size:12px; color:#475569; margin-bottom:6px;",
                                      "Your name, period, risk, cap, minimum R:R and ADX thresholds are taken from the plan settings above. The Capital.com key file is loaded in API Configuration > Capital.com."),
              uiOutput("desk_cc_plan"),
              body(cc[[1]]), tint = "#f0fdfa")),
      tab("2. Morning Sheet", homes(tr[[2]], desk_chunks$ms)),
      tab("3. Market & Patterns", homes(cc[[2]], desk_chunks$mk[1:3]),
          home("mk4", fold("Decision Panel (optional): Yahoo facts lined up with IG prices, your record, the calendar", trading_decision_ui("trading_decision")))),
      tab("4. Plan & Order", homes(cc[[3]], desk_chunks$po)),
      tab("5. Positions & Sync", homes(cc[[4]], desk_chunks$ps)),
      tab("6. Journal & Trade Sheet", homes(cc[[5]], desk_chunks$jn)),
      tab("7. IG / screenshot trades", value = "3. Trades",
          tags$div(style = "font-size:12.5px; color:#475569; margin:4px 0 8px 0;", "For trades placed on IG (or anywhere outside the app): plan, open and close them from screenshots. They are kept in trading_trades, apart from the Capital.com trades."),
          fold("Order Evidence: Claude reads your deal ticket, Positions and History screenshots", trading_evidence_ui("trading_evidence")),
          body(tr[[3]])),
      tab("8. Statistics", sec("Capital.com trades", body(cc[[6]]), tint = "#f0fdfa"), sec("IG trades (screenshots)", body(tr[[4]]))),
      tab("9. Exports (LAT files)", value = "5. Exports (LAT files)", body(tr[[5]])),
      tab("10. Currency & Budget", body(cc[[7]])),
      tab("11. Schema & SQL", sec("Capital.com tables (cc_)", body(cc[[8]])), sec("Trading Records tables (trading_)", body(tr[[6]]))),
      tab("12. Backtest & Blotter *", body(cc[[9]])))))))
}

# keep the Capital.com copies of the shared plan settings equal to the Trading Records ones (one place to type them)
trading_desk_server <- function(input, session, output = NULL, cc_store = NULL, records_store = NULL, now_fn = Sys.time) {
  if (!is.null(output)) desk_guided_server(input, output, cc_store, records_store, now_fn)
  if (!is.null(output)) output$desk_cc_plan <- renderUI({ g <- function(k) input[[paste0("cc_records-", k)]]; f <- function(v, sfx = "") if (is.null(v) || (length(v) == 1 && is.na(v))) "not set" else paste0(v, sfx)
    tags$div(style = "font-size:12.5px; background:#fff; border:1px dashed #0f766e; border-radius:8px; padding:6px 10px; margin-bottom:8px;",
      tags$b("Used now by tabs 3 to 6: "), sprintf("risk %s per trade, open-risk cap %s, minimum R:R %s (orders below it are refused), trend ADX at or above %s, range at or below %s.",
                                                    f(g("s_risk"), "%"), f(g("s_cap"), "%"), f(g("s_minrrr")), f(g("s_adx_t")), f(g("s_adx_r")))) })
  pairs <- list(s_name = "text", s_id = "text", s_start = "date", s_end = "date", s_risk = "num", s_cap = "num", s_minrrr = "num", s_adx_t = "num", s_adx_r = "num")
  for (k in names(pairs)) local({ key <- k; kind <- pairs[[k]]
    observeEvent(input[[paste0("trading_records-", key)]], {
      v <- input[[paste0("trading_records-", key)]]; id <- paste0("cc_records-", key)
      if (is.null(v) || (length(v) == 1 && (is.na(v) || identical(v, "")))) return()   # an empty plan value leaves the Capital.com value (shown in the line above)
      switch(kind, text = updateTextInput(session, id, value = v), date = updateDateInput(session, id, value = v), num = updateNumericInput(session, id, value = v))
    }, ignoreNULL = TRUE, ignoreInit = FALSE) })
}

# ---- Guided Desk ****** : the same panels as tabs 2-6, arranged as three steps -------------------------------------
# Each panel of tabs 2-6 is cut into pieces (desk_chunks). A piece lives once in the page (one set of inputs, outputs,
# Capital.com session and BigQuery rows); the script moves it into whichever place is on screen: its card in the
# Guided Desk, or its own numbered tab. Nothing is duplicated and every piece has a place in both views.
desk_chunks <- list(
  ms = list(ms1 = 1:11, ms2 = 12:26, ms3 = 27:37, ms4 = 38:48, ms5 = 49:51),
  mk = list(mk1 = 1, mk2 = 2, mk3 = 3:7),
  po = list(po1 = 1, po2 = 2, po3 = 3, po4 = 4, po5 = 5, po6 = 6),
  ps = list(ps1 = 1:3, ps2 = 4:8, ps3 = 9:11, ps4 = 12:15),
  jn = list(jn1 = 1:3, jn2 = 4:14, jn3 = 15:19))

desk_move_js <- "
(function(){
  function onScreen(x){ return $(x).parents('.tab-pane').not('.active').length === 0 && $(x).closest('.tab-content, .desk-hub').length > 0; }
  function place(){
    $('.desk-slot, .desk-home').each(function(){
      if (!onScreen(this)) return;
      var el = document.getElementById('desk-sec-' + $(this).data('sec'));
      if (el && el.parentNode !== this) { this.appendChild(el); $(el).trigger('shown'); }
    });
    $(window).trigger('resize');
  }
  $(document).on('shown.bs.tab', function(){ setTimeout(place, 0); });
  $(document).on('shiny:connected', function(){ setTimeout(place, 300); });
  $(document).on('click', '.desk-go', function(e){ e.preventDefault(); $('a[data-value=\"' + $(this).data('go') + '\"]').tab('show'); window.scrollTo({top: 0, behavior: 'smooth'}); });
})();"

desk_css <- "
.gd-intro{font-size:13px;color:#334155;margin:6px 0 4px}
.gd-steps{display:flex;gap:8px;margin:8px 0 4px}
.gd-step{flex:1;display:flex;align-items:center;gap:8px;padding:8px 12px;border-radius:10px;font-weight:700;text-decoration:none!important;border:1px solid}
.gd-step .n{width:24px;height:24px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;color:#fff;font-size:12px}
.gd-step.done{background:#f0fdf4;border-color:#86efac;color:#14532d}.gd-step.done .n{background:#16a34a}
.gd-step.todo{background:#fffbeb;border-color:#fcd34d;color:#78350f}.gd-step.todo .n{background:#d97706}
.gd-step.on{box-shadow:0 0 0 2px #0f766e}
#desk_guided{display:none}
.gd-head{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;background:linear-gradient(135deg,#f0fdfa,#fff);border:1px solid #99f6e4;border-radius:12px;padding:12px 16px;margin:10px 0}
.gd-head h4{margin:0 0 2px;font-size:16px;font-weight:800;color:#0b3b3a}.gd-head .sub{font-size:12.5px;color:#475569}
.gd-status{font-size:13px;font-weight:700;margin-top:6px}.gd-status.done{color:#166534}.gd-status.todo{color:#92400e}
.gd-card{background:#fff;border:1px solid #e2e8f0;border-left:4px solid #0f766e;border-radius:10px;padding:10px 14px;margin:10px 0}
.gd-card>.t{display:flex;align-items:center;gap:8px;font-weight:800;color:#0b3b3a;font-size:14.5px}
.gd-card>.t .k{background:#0f766e;color:#fff;border-radius:6px;padding:0 7px;font-size:12px}
.gd-card>.p{font-size:12.5px;color:#64748b;margin:2px 0 6px}
.gd-more{background:#f8fafc;border:1px dashed #cbd5e1;border-radius:10px;margin:10px 0}
.gd-more>summary{cursor:pointer;padding:8px 14px;font-weight:700;color:#334155}
.gd-more>div{padding:0 14px 10px}
.gd-links a{margin:2px 4px 2px 0}
.gd-nav{display:flex;justify-content:space-between;margin:12px 0 4px}"

desk_steps <- c(g1 = "1. Morning Sheet", g2 = "2. Analyse & Recommend", g3 = "3. After the Trade")

# what is done today, read from the saved rows (pure: tested in tests/test_desk_guided.R)
desk_guided_status <- function(ms = NULL, sugg = NULL, trades = NULL, now = Sys.time()) {
  day <- as.Date(format(now, "%Y-%m-%d", tz = "Europe/London"))
  ukd <- function(x) as.Date(format(as.POSIXct(x, tz = "UTC"), "%Y-%m-%d", tz = "Europe/London"))
  n0 <- function(d) !is.null(d) && NROW(d) > 0
  hm <- function(x) format(as.POSIXct(x, tz = "UTC"), "%H:%M", tz = "Europe/London")
  msd <- if (n0(ms) && "sheet_date" %in% names(ms)) ms[which(as.Date(ms$sheet_date) == day), , drop = FALSE] else NULL
  sg <- if (n0(sugg) && "saved_at" %in% names(sugg)) sugg[which(ukd(sugg$saved_at) == day), , drop = FALSE] else NULL
  tr <- if (n0(trades)) trades[!(trades$status %in% "DUPLICATE"), , drop = FALSE] else NULL
  td <- if (n0(tr)) tr[which(ukd(tr$placed_ts %||% tr$saved_at) == day | ukd(tr$exit_ts) == day), , drop = FALSE] else NULL
  op <- if (n0(tr)) sum(tr$status %in% c("OPEN", "WORKING", "PENDING")) else 0L
  cl <- if (n0(td)) td[td$status %in% "CLOSED", , drop = FALSE] else NULL
  txt <- if (n0(cl)) paste0(ifelse(is.na(cl$lessons %||% NA), "", cl$lessons %||% ""), ifelse(is.na(cl$analysis %||% NA), "", cl$analysis %||% "")) else character(0)
  rev <- sum(nzchar(trimws(txt)))
  pnl <- if (n0(cl) && "pnl_account_booked" %in% names(cl)) sum(cl$pnl_account_booked, na.rm = TRUE) else NA_real_
  list(day = day,
       g1 = list(done = NROW(msd) > 0, text = if (NROW(msd)) paste0("Today's Morning Sheet is saved", if ("saved_at" %in% names(msd)) paste0(" (", hm(tail(msd$saved_at, 1)), " UK)") else "", ".") else "No Morning Sheet saved for today yet."),
       g2 = list(done = NROW(sg) > 0, text = if (NROW(sg)) sprintf("%d recommendation(s) today; the last one (%s UK) %s the Morning Sheet and %s past trades.", NROW(sg), hm(tail(sg$saved_at, 1)),
                   if (isTRUE(tail(sg$morning_sheet_used, 1))) "used" else "did not use", if (isTRUE(tail(sg$history_asked %||% NA, 1))) "included" else "left out") else "No recommendation asked today yet."),
       g3 = list(done = NROW(cl) > 0 && rev >= NROW(cl), open = op, closed = NROW(cl), reviewed = rev,
                 text = paste0(sprintf("%d open, %d closed today, %d of the closed ones reviewed in the Journal", op, NROW(cl), rev),
                               if (is.finite(pnl) && NROW(cl)) sprintf("; booked today %+.2f", pnl) else "", ".")))
}

desk_guided_ui <- function() {
  slot <- function(k) tags$div(class = "desk-slot", `data-sec` = k)
  card <- function(n, title, purpose, keys) tags$div(class = "gd-card", tags$div(class = "t", tags$span(class = "k", n), title), tags$div(class = "p", purpose), lapply(keys, slot))
  more <- function(title, keys, links = NULL) tags$details(class = "gd-more", tags$summary(icon("toolbox"), " More tools: ", title),
    tags$div(lapply(keys, slot), if (length(links)) tags$div(class = "gd-links", tags$div(style = "font-size:12.5px; color:#475569; margin:6px 0 4px;", "Also in the numbered tabs:"),
      lapply(names(links), function(l) tags$a(href = "#", class = "desk-go btn btn-xs btn-default", `data-go` = links[[l]], l)))))
  step <- function(g, title, sub, ..., prev = NULL, nxt = NULL) tabPanel(desk_steps[[g]], value = desk_steps[[g]],
    tags$div(class = "gd-head", tags$div(tags$h4(title), tags$div(class = "sub", sub), uiOutput(paste0("desk_", g)))), ...,
    tags$div(class = "gd-nav", if (!is.null(prev)) tags$a(href = "#", class = "desk-go btn btn-default", `data-go` = prev, "← ", prev) else tags$span(),
             if (!is.null(nxt)) tags$a(href = "#", class = "desk-go btn btn-success", `data-go` = nxt, "Next: ", nxt, " →")))
  tagList(tags$style(HTML(desk_css)),
    tags$div(class = "gd-intro", "Three steps a day. Each card is the same panel as in the numbered tabs (same data and buttons, saved to the same BigQuery tables), so you can work here or there. Your own words are never written by the app."),
    uiOutput("desk_progress"),
    do.call(tabsetPanel, list(id = "desk_guided", type = "pills",
      step("g1", "Step 1: the Morning Sheet", "Pull the overnight levels, the calendar and the news from every source, check them, plan the day and save (BigQuery and Dropbox).",
        card("A", "Pull the data from every source", "Choose where the levels and the calendar come from (Yahoo, the web, screenshots), then read them in.", "ms1"),
        card("B", "Check the levels and the news", "Overnight markets, forex, commodities, your extra markets, the news and the economic calendar.", c("ms2", "ms3")),
        card("C", "Plan the day and save", "Regime, setups and risk for today; stand aside if needed. Save the sheet: the Claude API reads it in step 2.", "ms4"),
        more("saved sheets", "ms5", c("1. Setup (plan, Dropbox, tables)" = "1. Setup")), nxt = desk_steps[["g2"]]),
      step("g2", "Step 2: charts, trends and the recommendation", "Load the prices (Capital.com, Yahoo when needed), read the trend and the patterns, choose what the Claude API reads, then check the plan and place the DEMO order.",
        card("A", "Market, chart and trend", "Find the market, load the candles, see the trend, the indicators and every pattern of the matrix; save the scan.", c("mk1", "mk2")),
        card("B", "Scenarios and the recommendation", "Tick what the Claude API reads (the Morning Sheet, your past trades from BigQuery, the other options) and ask for the recommendation.", "po2"),
        card("C", "Check and place the order (DEMO)", "Your money, the news window, the risks of this deal and the ticket: an order that breaks the plan is refused.", c("po1", "po3", "po4", "po5")),
        more("further analysis and my deals", c("mk3", "mk4", "po6"), c("10. Currency & Budget" = "10. Currency & Budget", "12. Backtest & Blotter" = "12. Backtest & Blotter *")),
        prev = desk_steps[["g1"]], nxt = desk_steps[["g3"]]),
      step("g3", "Step 3: analyse the finished trade", "Pick up the close from Capital.com, read the platform's analysis, write your review and save it to BigQuery and the Individual Trade Sheet to Dropbox.",
        card("A", "While it runs, and the close", "Re-read positions and orders; move the stop to break-even while it runs; closed trades of the last 14 days.", c("ps1", "ps2", "ps3")),
        card("B", "The trade and the platform's analysis", "Pick the trade: its facts, the result and the summary.", "jn1"),
        card("C", "Your review: save to BigQuery and Dropbox", "Your own words, plan followed or not, mood; save the record, then save the sheet (Word + PDF) to Dropbox.", "jn2"),
        more("working orders, all trades, statistics and exports", c("ps4", "jn3"), c("8. Statistics" = "8. Statistics", "9. Exports (LAT files)" = "5. Exports (LAT files)",
             "7. IG / screenshot trades" = "3. Trades", "11. Schema & SQL" = "11. Schema & SQL")),
        prev = desk_steps[["g2"]]))))
}

desk_guided_server <- function(input, output, cc_store = NULL, records_store = NULL, now_fn = Sys.time) {
  rd <- function(st, nm, f = function(s, n) s$current(n)) if (is.null(st)) NULL else tryCatch(f(st, nm), error = function(e) NULL)
  status <- reactive({
    if (!identical(input[["trading_records-tabs"]], "Guided Desk")) req(FALSE)
    invalidateLater(60000)
    desk_guided_status(ms = rd(records_store, "morning_sheets", function(s, n) tr_read_current(s, n)),
                       sugg = rd(cc_store, "claude_suggestions"), trades = rd(cc_store, "trades"), now = now_fn())
  })
  cls <- function(x) if (isTRUE(x$done)) "done" else "todo"
  for (k in names(desk_steps)) local({ key <- k; output[[paste0("desk_", key)]] <- renderUI({ x <- status()[[key]]
    tags$div(class = paste("gd-status", cls(x)), icon(if (isTRUE(x$done)) "circle-check" else "circle-exclamation"), " ", x$text) }) })
  output$desk_progress <- renderUI({ s <- status(); cur <- input$desk_guided %||% desk_steps[[1]]
    tags$div(class = "gd-steps", lapply(seq_along(desk_steps), function(i) { k <- names(desk_steps)[i]
      tags$a(href = "#", class = paste("desk-go gd-step", cls(s[[k]]), if (identical(cur, desk_steps[[k]])) "on"), `data-go` = desk_steps[[k]],
             tags$span(class = "n", if (isTRUE(s[[k]]$done)) "✓" else i), sub("^[0-9]\\. ", "", desk_steps[[k]])) })) })
}
