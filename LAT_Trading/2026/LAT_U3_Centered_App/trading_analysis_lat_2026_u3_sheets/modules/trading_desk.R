# modules/trading_desk.R - one sidebar item for the daily work: Morning Sheet, market & patterns, plan & order,
# positions, journal + Individual Trade Sheet (Capital.com first), with the IG screenshot flow, Yahoo, statistics,
# exports and schemas in the same horizontal tabs. The four modules keep their own server logic and BigQuery tables
# (trading_* and cc_*); this file only arranges their screens and keeps the shared plan settings in step.

desk_steps <- c(g1 = "A. Morning Sheet", g2 = "B. Analyse & Place", g3 = "C. Review")
desk_essential <- c(unname(desk_steps), "D. Trade Log")

# ******** three screens for the daily work. Each piece of the former tabs 2-6 is shown once, as a card: the daily
# controls open, the rest folded under "More tools" in the same screen. Nothing is duplicated or moved.
desk_chunks <- list(
  ms = list(ms1 = 1:11, ms2 = 12:26, ms3 = 27:37, ms4 = 38:48, ms5 = 49:51),
  mk = list(mk1 = 1, mk2 = 2, mk3 = 3:7),
  po = list(po1 = 1, po2 = 2, po3 = 3, po4 = 4, po5 = 5, po6 = 6),
  ps = list(ps1 = 1:3, ps2 = 4:8, ps3 = 9:11, ps4 = 12:15),
  jn = list(jn1 = 1:3, jn2 = 4:14, jn3 = 15:19))

desk_css <- "
.gd-steps{display:flex;gap:8px;margin:8px 0 4px}
.gd-step{flex:1;display:flex;align-items:center;gap:8px;padding:8px 12px;border-radius:10px;font-weight:700;text-decoration:none!important;border:1px solid}
.gd-step .n{width:24px;height:24px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;color:#fff;font-size:12px}
.gd-step.done{background:#f0fdf4;border-color:#86efac;color:#14532d}.gd-step.done .n{background:#16a34a}
.gd-step.todo{background:#fffbeb;border-color:#fcd34d;color:#78350f}.gd-step.todo .n{background:#d97706}
.gd-step.on{box-shadow:0 0 0 2px #0f766e}
.gd-head{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;background:linear-gradient(135deg,#f0fdfa,#fff);border:1px solid #99f6e4;border-radius:12px;padding:10px 16px;margin:10px 0}
.gd-head h4{margin:0 0 2px;font-size:16px;font-weight:800;color:#0b3b3a}.gd-head .sub{font-size:12.5px;color:#475569}
.gd-status{font-size:13px;font-weight:700;margin-top:4px}.gd-status.done{color:#166534}.gd-status.todo{color:#92400e}
.gd-card{background:#fff;border:1px solid #e2e8f0;border-left:4px solid #0f766e;border-radius:10px;padding:10px 14px;margin:10px 0}
.gd-card>.t{display:flex;align-items:center;gap:8px;font-weight:800;color:#0b3b3a;font-size:14.5px}
.gd-card>.t .k{background:#0f766e;color:#fff;border-radius:6px;padding:0 7px;font-size:12px}
.gd-card>.p{font-size:12.5px;color:#64748b;margin:2px 0 6px}
.gd-more{background:#f8fafc;border:1px dashed #cbd5e1;border-radius:10px;margin:10px 0}
.gd-more>summary{cursor:pointer;padding:8px 14px;font-weight:700;color:#334155}
.gd-more>div{padding:0 14px 10px}
.gd-nav{display:flex;justify-content:space-between;margin:12px 0 4px}"
desk_js <- "$(document).on('click', '.desk-go', function(e){ e.preventDefault(); $('a[data-value=\"' + $(this).data('go') + '\"]').tab('show'); window.scrollTo({top: 0, behavior: 'smooth'}); });"

trading_desk_ui <- function() {
  tr <- desk_parts(trading_records_ui("trading_records", parts = TRUE))
  cc <- desk_parts(cc_trading_records_ui("cc_records", parts = TRUE))
  body <- function(tp) tp$children
  sec <- function(title, ..., tint = "#f8fafc") tags$div(style = sprintf("background:%s; border:1px solid #e2e8f0; border-radius:10px; padding:10px 14px; margin:10px 0;", tint),
                                                       tags$div(style = "font-weight:800; color:#0b3b3a; font-size:15px; margin-bottom:6px;", title), ...)
  tab <- function(title, ..., value = title) tabPanel(title, ..., value = value)
  P <- list(); for (g in names(desk_chunks)) { src <- body(switch(g, ms = tr[[2]], mk = cc[[2]], po = cc[[3]], ps = cc[[4]], jn = cc[[5]]))
    for (k in names(desk_chunks[[g]])) P[[k]] <- tags$div(class = "desk-sec", id = paste0("desk-sec-", k), src[desk_chunks[[g]][[k]]]) }
  P$mk4 <- tags$div(class = "desk-sec", id = "desk-sec-mk4", tags$div(style = "font-weight:800; margin:4px 0;", "Decision Panel: Yahoo facts lined up with the prices, your record, the calendar"), trading_decision_ui("trading_decision"))
  card <- function(n, title, purpose, keys) tags$div(class = "gd-card", tags$div(class = "t", tags$span(class = "k", n), title), tags$div(class = "p", purpose), P[keys])
  more <- function(title, keys) tags$details(class = "gd-more", tags$summary(icon("toolbox"), " More tools: ", title), tags$div(P[keys]))
  step <- function(g, title, sub, ..., prev = NULL, nxt = NULL) tab(desk_steps[[g]],
    tags$div(class = "gd-head", tags$div(tags$h4(title), tags$div(class = "sub", sub), uiOutput(paste0("desk_", g)))), ...,
    tags$div(class = "gd-nav", if (!is.null(prev)) tags$a(href = "#", class = "desk-go btn btn-default", `data-go` = prev, "\u2190 ", prev) else tags$span(),
             if (!is.null(nxt)) tags$a(href = "#", class = "desk-go btn btn-success", `data-go` = nxt, "Next: ", nxt, " \u2192")))
  sel <- function(suffix = "", li = "li") paste(sprintf('#trading_records-tabs > %s > a[data-value="%s"]%s', li, desk_essential, suffix), collapse = ", ")
  tagList(
    tags$style(HTML(paste0(desk_css, "\n", sel(), " { background:#dcfce7 !important; color:#14532d !important; font-weight:700; }\n",
                           sel(":hover"), " { background:#bbf7d0 !important; }\n", sel("", "li.active"), " { background:#86efac !important; color:#052e16 !important; }\n",
                           ".desk-hub .cc-dup { display:none; }"))),
    tags$script(HTML(desk_js)),
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #0f766e 100%); border-radius: 12px; padding: 12px 20px; margin-bottom: 10px; color:#fff;",
      tags$h3(style = "margin:0 0 4px 0; font-size:19px; font-weight:800; color:#fff;", "Trading Desk"),
      tags$div(style = "font-size:13px; color:#d1fae5; line-height:1.6;", "Three screens a day, in order: A Morning Sheet, B Analyse & Place (one button: chart, patterns, scenarios and the Claude API with the Morning Sheet; choose a scenario and the ticket fills itself), C Review. D Trade Log lists every deal and order saved. Your own words are never written by the app.")),
    uiOutput("cc_records-status_bar"), uiOutput("trading_records-statusBar"), uiOutput("desk_progress"),
    tags$div(class = "desk-hub", do.call(shinydashboard::tabBox, c(list(width = 12, id = "trading_records-tabs"), list(
      step("g1", "A. The Morning Sheet", "Pull the overnight levels, the calendar and the news, check them, plan the day and save (BigQuery and Dropbox). The Claude API reads it in B.",
        card("1", "Pull the data from every source", "Choose where the levels and the calendar come from, then read them in.", "ms1"),
        card("2", "Check the levels and the news", "Overnight markets, forex, commodities, your extra markets, the news and the economic calendar.", c("ms2", "ms3")),
        card("3", "Plan the day and save", "Regime, set-ups and risk for today; stand aside if needed. Save the sheet.", "ms4"),
        more("saved sheets", "ms5"), nxt = desk_steps[["g2"]]),
      step("g2", "B. Analyse and place the trade", "Find the market and press Analyse once: chart, trend, patterns, the scenarios under your plan and the Claude API's analysis (with today's Morning Sheet). Choose a scenario: the ticket fills itself. Check and send (DEMO).",
        card("1", "Market, chart, trend and analysis", "One button does it all; tick past trades in card 2 if you want them read too.", c("mk1", "mk2")),
        card("2", "Scenarios and the recommendation", "Ranked under your plan; choosing one fills the ticket (direction, stop, target, size from your risk, set-up, chart, hours, Assessed).", "po2"),
        card("3", "Ticket: check and send (DEMO)", "The plan check is listed; a deal that breaks a blocking rule is refused.", "po5"),
        more("money, news window, risks, profile, oscillators, Decision Panel, my deals", c("po1", "po3", "po4", "mk3", "mk4", "po6")),
        prev = desk_steps[["g1"]], nxt = desk_steps[["g3"]]),
      step("g3", "C. Review the trade", "Positions are re-read from Capital.com (break-even here while it runs); the closed trade gets the platform's analysis and your review, saved to BigQuery, and its sheet to Dropbox.",
        card("1", "While it runs, and the close", "Sync, open positions (Stop to break-even), closed trades.", c("ps1", "ps2", "ps3")),
        card("2", "The trade and the platform's analysis", "Pick the trade: facts, result and summary.", "jn1"),
        card("3", "Your review: save to BigQuery and Dropbox", "Your own words, plan followed or not, then the Individual Trade Sheet (Word + PDF) to Dropbox.", "jn2"),
        more("working orders, all trades", c("ps4", "jn3")), prev = desk_steps[["g2"]], nxt = "D. Trade Log"),
      tab("D. Trade Log", body(cc[[9]])),
      tab("E. Statistics & Backtest", sec("Capital.com trades", body(cc[[6]]), tint = "#f0fdfa"), sec("Backtest & blotter", body(cc[[10]])), sec("IG trades (screenshots)", body(tr[[4]]))),
      tab("F. IG / screenshot trades", value = "3. Trades",
          tags$div(style = "font-size:12.5px; color:#475569; margin:4px 0 8px 0;", "For trades placed on IG (or anywhere outside the app): plan, open and close them from screenshots. They are kept in trading_trades, apart from the Capital.com trades."),
          tags$details(class = "gd-more", tags$summary("Order Evidence: Claude reads your deal ticket, Positions and History screenshots"), tags$div(trading_evidence_ui("trading_evidence"))),
          body(tr[[3]])),
      tab("G. Exports (LAT files)", value = "5. Exports (LAT files)", body(tr[[5]])),
      tab("Setup",
          sec("Plan, period, Dropbox and records (shared by every tab)", body(tr[[1]])),
          sec("Capital.com", tags$div(style = "font-size:12px; color:#475569; margin-bottom:6px;",
                                      "Your name, period, risk, cap, minimum R:R and ADX thresholds are taken from the plan settings above. The Capital.com key file is loaded in API Configuration > Capital.com."),
              uiOutput("desk_cc_plan"), body(cc[[1]]), tint = "#f0fdfa"),
          tags$details(class = "gd-more", tags$summary("Currency & budget"), tags$div(body(cc[[7]]))),
          tags$details(class = "gd-more", tags$summary("Schema & SQL"), tags$div(sec("Capital.com tables (cc_)", body(cc[[8]])), sec("Trading Records tables (trading_)", body(tr[[6]]))))))))))
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

# ---- step status ********: what is done today, shown at the top of A / B / C -------------------------------------
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

desk_guided_server <- function(input, output, cc_store = NULL, records_store = NULL, now_fn = Sys.time) {
  rd <- function(st, nm, f = function(s, n) s$current(n)) if (is.null(st)) NULL else tryCatch(f(st, nm), error = function(e) NULL)
  status <- reactive({
    if (!(input[["trading_records-tabs"]] %||% desk_steps[[1]]) %in% desk_steps) req(FALSE)
    invalidateLater(60000)
    desk_guided_status(ms = rd(records_store, "morning_sheets", function(s, n) tr_read_current(s, n)),
                       sugg = rd(cc_store, "claude_suggestions"), trades = rd(cc_store, "trades"), now = now_fn())
  })
  cls <- function(x) if (isTRUE(x$done)) "done" else "todo"
  for (k in names(desk_steps)) local({ key <- k; output[[paste0("desk_", key)]] <- renderUI({ x <- status()[[key]]
    tags$div(class = paste("gd-status", cls(x)), icon(if (isTRUE(x$done)) "circle-check" else "circle-exclamation"), " ", x$text) }) })
  output$desk_progress <- renderUI({ s <- status(); cur <- input[["trading_records-tabs"]] %||% desk_steps[[1]]
    tags$div(class = "gd-steps", lapply(seq_along(desk_steps), function(i) { k <- names(desk_steps)[i]
      tags$a(href = "#", class = paste("desk-go gd-step", cls(s[[k]]), if (identical(cur, desk_steps[[k]])) "on"), `data-go` = desk_steps[[k]],
             tags$span(class = "n", if (isTRUE(s[[k]]$done)) "✓" else i), sub("^[0-9]\\. ", "", desk_steps[[k]])) })) })
}
