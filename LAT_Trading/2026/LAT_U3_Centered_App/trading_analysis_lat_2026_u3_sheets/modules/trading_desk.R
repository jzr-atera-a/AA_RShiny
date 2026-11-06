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
    uiOutput("cc_records-status_bar"), uiOutput("trading_records-statusBar"),
    tags$div(class = "desk-hub", do.call(shinydashboard::tabBox, c(list(width = 12, id = "trading_records-tabs"), list(
      tab("1. Setup",
          sec("Plan, period, Dropbox and records (shared by every tab)", body(tr[[1]])),
          sec("Capital.com", tags$div(style = "font-size:12px; color:#475569; margin-bottom:6px;",
                                      "Your name, period, risk, cap, minimum R:R and ADX thresholds are taken from the plan settings above. The Capital.com key file is loaded in API Configuration > Capital.com."),
              uiOutput("desk_cc_plan"),
              body(cc[[1]]), tint = "#f0fdfa")),
      tab("2. Morning Sheet", body(tr[[2]])),
      tab("3. Market & Patterns", body(cc[[2]]),
          fold("Decision Panel (optional): Yahoo facts lined up with IG prices, your record, the calendar", trading_decision_ui("trading_decision"))),
      tab("4. Plan & Order", body(cc[[3]])),
      tab("5. Positions & Sync", body(cc[[4]])),
      tab("6. Journal & Trade Sheet", body(cc[[5]])),
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
trading_desk_server <- function(input, session, output = NULL) {
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
