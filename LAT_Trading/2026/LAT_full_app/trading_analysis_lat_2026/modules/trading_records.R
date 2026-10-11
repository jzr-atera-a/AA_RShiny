# modules/trading_records.R
# Trading Records: durable (BigQuery-backed) record-keeping for the 4-week trading period.
# Morning Sheet, trades (open / manage / partial exit / close), Blotter-style statistics,
# daily + weekly reviews, a versioned plan specification, and the schema.
# Storage + maths live in R/utils_trading_records.R. All content is entered by the user.

tr_or <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
tr_uk_now <- function() format(Sys.time(), "%H:%M", tz = "Europe/London")
tr_assets <- c("WTI", "NATGAS", "EURUSD", "USDJPY", "GBPUSD", "AUDUSD", "GOLD")
tr_pip_defaults <- c(WTI = 0.01, NATGAS = 0.001, EURUSD = 0.0001, USDJPY = 0.01, GBPUSD = 0.0001, AUDUSD = 0.0001, GOLD = 0.1)
tr_strategies <- c("Pivot Point Bounce" = "PIVOT_BOUNCE", "Holy Grail" = "HOLY_GRAIL", "Straddle" = "STRADDLE", "Other" = "OTHER")
tr_deviations <- c("Moved stop", "Exited early", "Held past target/stop plan", "Entered without full trigger",
                   "Ignored a signal", "Oversized / over risk cap", "Traded during stand-aside", "Other")

tr_lab <- function(x) tags$span(style = "color:#2c3e50; font-weight:600; font-size:12.5px;", x)
tr_h <- function(x) tags$h4(style = "color:#002C3C; font-weight:800; margin:6px 0 10px 0;", x)
tr_note <- function(...) tags$div(style = "font-size:12px; color:#64748b; margin:4px 0 10px 0; line-height:1.5;", ...)
tr_tile <- function(label, value, sub = NULL, colour = "#002C3C") {
  tags$div(style = "flex:1 1 150px; background:#ffffff; border:1px solid #e2e8f0; border-top:4px solid #008A82; border-radius:8px; padding:10px 12px; margin:0 8px 8px 0; min-width:140px;",
    tags$div(style = "font-size:11px; color:#64748b; text-transform:uppercase; letter-spacing:.4px;", label),
    tags$div(style = paste0("font-size:22px; font-weight:800; color:", colour, ";"), value),
    if (!is.null(sub)) tags$div(style = "font-size:11px; color:#64748b;", sub))
}
tr_fmt_pct <- function(x, d = 1) if (is.finite(x)) sprintf(paste0("%.", d, "f%%"), 100 * x) else "—"
tr_fmt_num <- function(x, d = 2) if (is.finite(x)) formatC(x, format = "f", digits = d, big.mark = ",") else "—"

trading_records_ui <- function(id) {
  ns <- NS(id)
  ta <- function(i, l, r = 2) textAreaInput(ns(i), tr_lab(l), rows = r, width = "100%")
  num <- function(i, l, v = NA, ...) numericInput(ns(i), tr_lab(l), v, ...)

  inst_row <- function(i, default_inst) {
    tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px;",
      fluidRow(
        column(3, selectizeInput(ns(paste0("ml", i, "_inst")), tr_lab("Instrument"), c("", tr_assets), selected = default_inst, options = list(create = TRUE))),
        column(3, num(paste0("ml", i, "_low"), "Overnight low")), column(3, num(paste0("ml", i, "_high"), "Overnight high")),
        column(3, num(paste0("ml", i, "_cur"), "Current price"))),
      fluidRow(
        column(3, textInput(ns(paste0("ml", i, "_time")), tr_lab("Time now (UK)"), tr_uk_now())),
        column(3, num(paste0("ml", i, "_adx"), "ADX(14)")),
        column(2, num(paste0("ml", i, "_ph"), "Prior high")), column(2, num(paste0("ml", i, "_pl"), "Prior low")),
        column(2, num(paste0("ml", i, "_pc"), "Prior close"))))
  }

  tagList(
    tags$div(style = "background: linear-gradient(135deg, #002C3C 0%, #008A82 100%); border-radius: 12px; padding: 18px 22px; margin-bottom: 16px; color: #ffffff;",
      tags$h3(style = "margin: 0 0 6px 0; font-size: 19px; font-weight: 800; color: #ffffff;", "Trading Records: durable records for the trading period"),
      tags$div(style = "font-size: 13px; color: #eafffb; line-height: 1.6;",
        "Your own morning sheets, trades, reviews and plan versions, stored in BigQuery so they survive restarts, plus Blotter-style statistics worked out from what you record. Everything here is entered by you; the app never creates or suggests trades or results.")),
    uiOutput(ns("statusBar")),

    tabBox(width = 12, id = ns("tabs"),
      # ---------------------------------------------------------------- 1 SETUP
      tabPanel("1. Connection & Setup",
        tr_h("Storage"),
        tr_note("Records are saved to BigQuery as soon as a connection exists (API Configuration → BigQuery → Connect). If it isn't connected, records are kept in this session only and queued; use Sync once connected. Session-only records are lost if the app restarts, so download a backup."),
        fluidRow(column(12,
          actionButton(ns("ensureTables"), "Create / verify tables", icon = icon("database"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
          actionButton(ns("syncPending"), "Sync pending records", icon = icon("cloud-arrow-up")),
          actionButton(ns("reload"), "Reload from BigQuery", icon = icon("rotate")),
          downloadButton(ns("dlBackup"), "Download session backup (.rds)"))),
        tags$br(), uiOutput(ns("setupMsg")),
        tr_h("Period settings"),
        fluidRow(
          column(3, textInput(ns("s_name"), tr_lab("Your name"), "")),
          column(3, num("s_balance", "Opening balance (GBP)", 10000, min = 0, step = 100)),
          column(3, dateInput(ns("s_start"), tr_lab("Period start"), as.Date("2026-10-12"))),
          column(3, dateInput(ns("s_end"), tr_lab("Period end"), as.Date("2026-11-06")))),
        actionButton(ns("saveSettings"), "Save settings", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;")),

      # ------------------------------------------------------- 2 MORNING SHEET
      tabPanel("2. Morning Sheet",
        tr_note("Same sections as your Morning Sheet template. Pivot points and the regime label are worked out when you save, from the prior-day high/low/close and ADX you enter. Saving the same date again creates a new version; the latest is used."),
        fluidRow(
          column(3, dateInput(ns("ms_date"), tr_lab("Date"), Sys.Date())),
          column(3, selectInput(ns("ms_load"), tr_lab("Load a saved sheet"), choices = c("(none)"))),
          column(3, tags$div(style = "margin-top:25px;", actionButton(ns("ms_loadBtn"), "Load", icon = icon("folder-open"))))),
        tr_h("Overnight markets"),
        fluidRow(column(3, num("ms_dow", "Dow Jones")), column(3, num("ms_dowc", "Dow change (%)")),
                 column(3, num("ms_nik", "Nikkei")), column(3, num("ms_nikc", "Nikkei change (%)"))),
        tr_h("Instruments"),
        inst_row(1, "WTI"), inst_row(2, "NATGAS"), inst_row(3, "EURUSD"), inst_row(4, ""),
        tr_h("News and calendar"),
        ta("ms_news", "Overnight news (your own notes)", 3),
        ta("ms_cal_o", "Economic calendar from overnight (paste)", 3),
        ta("ms_cal_t", "Today's data releases (paste)", 3),
        ta("ms_win", "Releases inside your trading window", 2),
        tr_h("Plan for the day"),
        ta("ms_regime", "Regime read per instrument", 2), ta("ms_setups", "Set-ups you will look for", 2),
        fluidRow(column(4, num("ms_risk", "Combined open risk now (% of equity)", 0, min = 0, step = 0.25)),
                 column(8, ta("ms_expo", "Exposure note (correlated markets)", 2))),
        checkboxInput(ns("ms_stand"), tr_lab("Standing aside today"), FALSE),
        conditionalPanel(sprintf("input['%s']", ns("ms_stand")), ta("ms_stand_why", "Reason for standing aside", 2)),
        actionButton(ns("ms_save"), "Save morning sheet", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tags$hr(), tr_h("Saved sheets"), DT::DTOutput(ns("ms_table"))),

      # ------------------------------------------------------------- 3 TRADES
      tabPanel("3. Trades",
        tr_h("A. Open a trade"),
        tr_note("Fill in at the time you enter, as in the top half of your Trade Sheet. Times are UK time. Sizing is your stake per pip; pip size is the price move that equals one pip on YOUR platform (defaults are only a guide)."),
        fluidRow(
          column(3, selectizeInput(ns("t_asset"), tr_lab("Asset"), tr_assets, options = list(create = TRUE))),
          column(3, selectInput(ns("t_strategy"), tr_lab("Strategy"), tr_strategies)),
          column(3, radioButtons(ns("t_dir"), tr_lab("Direction"), c("Buy" = "B", "Sell" = "S"), inline = TRUE)),
          column(3, textInput(ns("t_chart"), tr_lab("Chart period"), "15 Min"))),
        fluidRow(
          column(3, dateInput(ns("t_date"), tr_lab("Entry date"), Sys.Date())),
          column(3, textInput(ns("t_time"), tr_lab("Entry time (UK, HH:MM)"), tr_uk_now())),
          column(3, num("t_dur", "Expected duration (hours)", 2, min = 0)),
          column(3, num("t_pip", "Pip size (price units)", 0.01, min = 0))),
        fluidRow(
          column(3, num("t_stake", "Stake per pip (GBP)", 2, min = 0)),
          column(3, num("t_entry", "Entry price")), column(3, num("t_stop", "Stop loss")), column(3, num("t_target", "Target"))),
        fluidRow(
          column(3, num("t_adx", "ADX(14) at entry")),
          column(3, num("t_corr", "Other open risk in correlated markets (% equity)", 0, min = 0, step = 0.25)),
          column(3, sliderInput(ns("t_mood"), tr_lab("Mood at entry (1–5)"), 1, 5, 3, step = 1)),
          column(3, textInput(ns("t_parent"), tr_lab("Parent trade ID (only if this is a separate leg)"), ""))),
        ta("t_fund", "Set-up (fundamental)", 2), ta("t_tech", "Set-up (technical)", 3),
        fluidRow(column(6, ta("t_trigger", "Trigger", 2)), column(6, ta("t_exec", "Execution", 2))),
        fluidRow(column(6, ta("t_stopwhy", "Reason for stop-loss placement", 2)), column(6, ta("t_tgtwhy", "Reason for target placement", 2))),
        uiOutput(ns("t_preview")),
        actionButton(ns("t_save"), "Save open trade", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tags$hr(),

        tr_h("B. Manage, partially exit or close an open trade"),
        selectInput(ns("m_trade"), tr_lab("Open trade"), choices = c("(no open trades)" = "")),
        uiOutput(ns("m_summary")),
        radioButtons(ns("m_action"), tr_lab("What happened?"), inline = TRUE,
                     c("Moved stop" = "stop", "Partial exit" = "partial", "Closed" = "close", "Cancelled (never filled)" = "cancel")),
        fluidRow(column(3, dateInput(ns("m_date"), tr_lab("Date"), Sys.Date())),
                 column(3, textInput(ns("m_time"), tr_lab("Time (UK, HH:MM)"), tr_uk_now()))),
        conditionalPanel(sprintf("input['%s'] == 'stop'", ns("m_action")),
          fluidRow(column(3, num("m_newstop", "New stop price")),
                   column(3, radioButtons(ns("m_permitted"), tr_lab("Allowed by my written management rule?"), c("Yes" = "Y", "No" = "N"), inline = TRUE))),
          ta("m_stopwhy", "Why (with the chart you saved)", 2)),
        conditionalPanel(sprintf("input['%s'] == 'partial' || input['%s'] == 'close'", ns("m_action"), ns("m_action")),
          fluidRow(column(3, conditionalPanel(sprintf("input['%s'] == 'partial'", ns("m_action")), num("m_pstake", "Stake per pip closed (GBP)"))),
                   column(3, num("m_exit", "Exit price")),
                   column(3, num("m_pnl", "Net P/L from platform statement (GBP, optional)")),
                   column(3, radioButtons(ns("m_code"), tr_lab("Exit code"), c("S1 hit initial stop" = "S1", "S2+ hit trailing stop" = "S2+", "ME manual exit" = "ME", "T target hit" = "T")))),
          fluidRow(column(3, sliderInput(ns("m_mood"), tr_lab("Mood at exit (1–5)"), 1, 5, 3, step = 1)),
                   column(3, radioButtons(ns("m_followed"), tr_lab("Did you follow your plan on this trade?"), c("Yes" = "Y", "No" = "N"), inline = TRUE)),
                   column(6, conditionalPanel(sprintf("input['%s'] == 'N'", ns("m_followed")),
                     selectInput(ns("m_devtype"), tr_lab("Deviation type"), tr_deviations)))),
          conditionalPanel(sprintf("input['%s'] == 'N'", ns("m_followed")), ta("m_devnote", "What happened and why (be specific and honest)", 2)),
          fluidRow(column(6, ta("m_why", "Reason for exit", 2)), column(6, ta("m_lessons", "Lessons learned", 2)))),
        actionButton(ns("m_save"), "Save", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tags$hr(), tr_h("All trades"),
        downloadButton(ns("dlTrades"), "Download trades (CSV)"), tags$br(), tags$br(),
        DT::DTOutput(ns("tr_table"))),

      # ------------------------------------------------------------- 4 STATS
      tabPanel("4. Statistics",
        fluidRow(column(3, selectInput(ns("st_week"), tr_lab("Show"), c("Whole period" = "all", "Week 1" = "1", "Week 2" = "2", "Week 3" = "3", "Week 4" = "4")))),
        uiOutput(ns("st_tiles")),
        uiOutput(ns("st_caution")),
        fluidRow(column(6, plotly::plotlyOutput(ns("st_equity"), height = "300px")), column(6, plotly::plotlyOutput(ns("st_r"), height = "300px"))),
        fluidRow(column(6, tr_h("By strategy"), tableOutput(ns("st_strat"))), column(6, tr_h("By asset"), tableOutput(ns("st_asset")))),
        fluidRow(column(4, tr_h("By exit code"), tableOutput(ns("st_exit"))), column(4, tr_h("By weekday (entry)"), tableOutput(ns("st_wd"))),
                 column(4, tr_h("By entry time (UK)"), tableOutput(ns("st_hr")))),
        fluidRow(column(6, tr_h("Mood at entry vs Real R"), tableOutput(ns("st_mood")))),
        tr_note("Real R = net P/L divided by the money risked at the initial stop (negative for a loss). Planned RRR = reward pips / risk pips at entry. Sharpe and Sortino here are per trade, not annualised, and are not reliable on a small number of trades; the trade-by-trade review and adherence matter more.")),

      # ----------------------------------------------------------- 5 REVIEWS
      tabPanel("5. Reviews",
        tr_note("A short daily note and a Friday weekly review. The counts shown are worked out from your trades; edit if needed."),
        fluidRow(column(3, selectInput(ns("rv_type"), tr_lab("Type"), c("Weekly", "Daily"))),
                 column(3, dateInput(ns("rv_date"), tr_lab("Date"), Sys.Date())),
                 column(3, num("rv_n", "Trades taken (auto)", 0, min = 0)),
                 column(3, sliderInput(ns("rv_mood"), tr_lab("Overall mood (1–5)"), 1, 5, 3, step = 1))),
        uiOutput(ns("rv_auto")),
        ta("rv_worked", "What worked", 3), ta("rv_not", "What did not", 3), ta("rv_dev", "Deviations from the plan (summary)", 3),
        ta("rv_change", "Changes to make from next period (log them; do not edit the original spec)", 3),
        fluidRow(column(3, dateInput(ns("rv_eff"), tr_lab("Change effective from"), Sys.Date() + 1)),
                 column(3, checkboxInput(ns("rv_loss"), tr_lab("A daily/weekly loss limit was breached"), FALSE)),
                 column(3, checkboxInput(ns("rv_cap"), tr_lab("The combined-risk cap was breached"), FALSE))),
        actionButton(ns("rv_save"), "Save review", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tags$hr(), tr_h("Saved reviews"), DT::DTOutput(ns("rv_table"))),

      # ------------------------------------------------------------ 6 SPEC
      tabPanel("6. Plan Spec",
        tr_note("Write each rule once, then freeze it. Any later change is saved as a NEW version with a reason; earlier versions stay in the history."),
        selectInput(ns("sp_strategy"), tr_lab("Rule set"), c("Risk and regime (global)" = "GLOBAL", tr_strategies[1:3])),
        tr_note("The fields follow the LAT Trade Plan Template and S-T-E-M (Set-up, Trigger, Execution, Management). See Unit Assignments \u2192 Unit 3 \u2013 Workbench for what each section asks. Everything you write here is your own."),
        conditionalPanel(sprintf("input['%s'] != 'GLOBAL'", ns("sp_strategy")),
          ta("sp_setup", "Set-up: the conditions that must be in place before you look for an entry", 3),
          ta("sp_trigger", "Trigger: the event that tells you to act", 3),
          ta("sp_exec", "Execution: how you enter (time or price filter, order type, what counts as impulsive)", 3)),
        ta("sp_entry", "Entry rule (one-line summary)", 2), ta("sp_stop", "Stop loss placement and why", 2), ta("sp_target", "Target placement and why", 2), ta("sp_mgmt", "Trade management", 3),
        conditionalPanel(sprintf("input['%s'] == 'GLOBAL'", ns("sp_strategy")),
          ta("sp_obj", "Broad objectives", 2), ta("sp_ind", "Indicators used (exact settings; optional importance mark out of 10 for each)", 3),
          ta("sp_data", "Data sources (news and macro data)", 2),
          fluidRow(column(4, textInput(ns("sp_tfminor"), tr_lab("Minor timeframe"), "")), column(4, textInput(ns("sp_tfbase"), tr_lab("Base timeframe (your average holding period for winners)"), "")), column(4, textInput(ns("sp_tfmajor"), tr_lab("Major timeframe"), ""))),
          fluidRow(column(3, num("sp_mloss", "Monthly loss limit (%)", NA, step = 0.5)), column(3, num("sp_minrrr", "Minimum reward : risk", NA, step = 0.25))),
          fluidRow(column(3, num("sp_adx_t", "ADX above = trend", 30)), column(3, num("sp_adx_r", "ADX below = range", 20)),
                   column(3, num("sp_risk", "Risk per trade (% equity)", 1, step = 0.25)), column(3, num("sp_cap", "Combined open-risk cap (%)", 2, step = 0.25))),
          fluidRow(column(3, num("sp_maxpos", "Max open positions", 2)), column(3, num("sp_dloss", "Daily loss limit (%)", 2, step = 0.25)),
                   column(3, num("sp_wloss", "Weekly loss limit (%)", 4, step = 0.25))),
          selectInput(ns("sp_corr"), tr_lab("Correlated-markets rule"), c("Trade only the strongest setup", "Split risk across positions"))),
        ta("sp_reason", "Reason for this version (required after version 1)", 2),
        actionButton(ns("sp_save"), "Save as new version", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tags$hr(), tr_h("Spec history"), DT::DTOutput(ns("sp_table"))),

      # ---------------------------------------------------------- 7 SCHEMA
      tabPanel("7. Schema & SQL",
        tr_note("Nine append-only tables (including the screenshot evidence log and the platform statement rows) in the BigQuery dataset set under API Configuration. Each also gets a `_current` view that returns the latest row per key. Editing a record writes a new row; nothing is updated or deleted."),
        uiOutput(ns("schemaTables")), tr_h("DDL"), downloadButton(ns("dlDDL"), "Download SQL (.sql)"), tags$br(), tags$br(),
        verbatimTextOutput(ns("ddlText")))
    )
  )
}

# =============================================================================== SERVER
trading_records_server <- function(id, api_manager = NULL, store = NULL, quiet = FALSE, bus = NULL) {
  moduleServer(id, function(input, output, session) {
    if (is.null(store)) store <- tr_make_store(tr_bq_backend(api_manager))
    refresh <- reactiveVal(0); bump <- function() refresh(isolate(refresh()) + 1)
    msg <- function(text, type = "message") if (!quiet) showNotification(text, type = type, duration = 6)
    report <- function(res, what) {
      if (identical(res, "bigquery")) msg(paste(what, "saved to BigQuery."))
      else if (identical(res, "pending")) msg(paste(what, "saved in this session only (BigQuery not connected). Sync later."), "warning")
      else msg(paste(what, "- BigQuery write failed, kept in this session:", res), "error")
    }

    # ---- order-evidence integration (screenshots sent from the Order Evidence tab) ------------
    ev_open <- reactiveVal(NULL); ev_close <- reactiveVal(NULL)
    link_evidence <- function(ev_id, trade_id) {
      if (is.null(ev_id) || !nzchar(ev_id)) return(invisible())
      ev <- tr_read_current(store, "evidence"); r <- ev[ev$evidence_id == ev_id, , drop = FALSE]
      if (!nrow(r)) return(invisible())
      r <- r[1, ]; r$status <- "LINKED"; r$trade_id <- trade_id; r$record_version <- r$record_version + 1L
      store$write("evidence", r)
    }
    if (!is.null(bus)) observeEvent(bus$ts, {
      v <- bus$values; req(v)
      if (identical(bus$kind, "open")) {
        ev_open(bus$evidence_id)
        if (!is.na(tr_or(v$asset, NA))) updateSelectizeInput(session, "t_asset", choices = unique(c(tr_assets, v$asset)), selected = v$asset, options = list(create = TRUE))
        if (!is.na(tr_or(v$direction, NA))) updateRadioButtons(session, "t_dir", selected = v$direction)
        if (!is.na(tr_or(v$date, NA))) updateDateInput(session, "t_date", value = as.Date(v$date))
        if (!is.na(tr_or(v$time, NA))) updateTextInput(session, "t_time", value = v$time)
        if (is.finite(tr_num(v$entry))) updateNumericInput(session, "t_entry", value = v$entry)
        if (is.finite(tr_num(v$stop))) updateNumericInput(session, "t_stop", value = v$stop)
        if (is.finite(tr_num(v$limit))) updateNumericInput(session, "t_target", value = v$limit)
        if (is.finite(tr_num(v$size))) updateNumericInput(session, "t_stake", value = v$size)
        updateTabsetPanel(session, "tabs", selected = "3. Trades")
        msg("Entry details filled in from the screenshot. Check them, then write your own set-up, trigger and reasons before saving.")
      } else if (identical(bus$kind, "close")) {
        ev_close(bus$evidence_id)
        o <- open_trades(); hit <- o[o$asset == tr_or(v$asset, "") & (is.na(tr_or(v$direction, NA)) | o$direction == tr_or(v$direction, "")), , drop = FALSE]
        if (nrow(hit) >= 1) updateSelectInput(session, "m_trade", selected = hit$trade_id[which.max(hit$entry_ts)])
        updateRadioButtons(session, "m_action", selected = "close")
        if (is.finite(tr_num(v$exit))) updateNumericInput(session, "m_exit", value = v$exit)
        if (is.finite(tr_num(v$pnl))) updateNumericInput(session, "m_pnl", value = v$pnl)
        if (!is.na(tr_or(v$date, NA))) updateDateInput(session, "m_date", value = as.Date(v$date))
        if (!is.na(tr_or(v$time, NA))) updateTextInput(session, "m_time", value = v$time)
        updateTabsetPanel(session, "tabs", selected = "3. Trades")
        msg("Exit details filled in from the screenshot. Choose the trade if needed, then add your own reason for exit and lessons before saving.")
      }
    }, ignoreInit = TRUE)

    # connection watcher
    conn <- reactive({ invalidateLater(3000); store$connected() })
    last_conn <- reactiveVal(FALSE)
    observe({ cn <- conn(); if (cn && !isolate(last_conn())) { last_conn(TRUE); bump() } else if (!cn) last_conn(FALSE) })

    rd <- function(name) reactive({ refresh(); tr_read_current(store, name) })
    settings_df <- rd("settings"); spec_df <- rd("plan_spec"); sheets_df <- rd("morning_sheets")
    levels_df <- rd("morning_levels"); trades_df <- rd("trades"); events_df <- rd("trade_events"); reviews_df <- rd("reviews")

    sv <- reactive({ s <- settings_df(); setNames(as.list(s$setting_value), s$setting_key) })
    opening <- reactive(tr_or(tr_num(sv()$opening_balance), 10000))
    p_start <- reactive(tryCatch(as.Date(tr_or(sv()$period_start, "2026-10-12")), error = function(e) as.Date("2026-10-12")))
    global_spec <- reactive({ s <- spec_df(); g <- s[s$strategy == "GLOBAL", , drop = FALSE]; if (nrow(g)) g[which.max(g$spec_version), ] else NULL })
    adx_cfg <- reactive({ g <- global_spec(); c(tr_or(g$adx_trend_min, 30), tr_or(g$adx_range_max, 20)) })
    equity_now <- reactive({ t <- trades_df(); cl <- t[t$status == "CLOSED" & !is.na(t$net_pnl_gbp), ]; opening() + sum(cl$net_pnl_gbp) })

    # ---------------------------------------------------------------- status & setup
    output$statusBar <- renderUI({
      cn <- conn(); refresh(); pc <- store$pending_count()
      bg <- if (cn) "#15803d" else "#b45309"
      txt <- if (cn) "Connected to BigQuery: records are saved permanently." else "Not connected to BigQuery: records are kept in this session only."
      tags$div(style = paste0("background:", bg, "; color:#ffffff; border-radius:8px; padding:8px 14px; margin-bottom:12px; font-size:13px;"),
               txt, if (pc > 0) sprintf(" %d record(s) waiting to sync.", pc))
    })
    observeEvent(input$ensureTables, {
      tryCatch({ req(store$connected()); store$ensure(); msg("Tables and views are ready.") },
               error = function(e) msg(paste("Could not prepare tables:", conditionMessage(e)), "error"))
      if (!store$connected()) msg("Connect BigQuery first (API Configuration).", "warning")
    })
    observeEvent(input$syncPending, {
      tryCatch({ n <- store$sync(); bump(); msg(sprintf("Synced %d record(s) to BigQuery.", n)) },
               error = function(e) msg(paste("Sync failed:", conditionMessage(e)), "error"))
    })
    observeEvent(input$reload, { bump(); msg("Reloaded.") })
    output$dlBackup <- downloadHandler(filename = function() paste0("trading_records_session_", format(Sys.Date()), ".rds"),
                                       content = function(file) saveRDS(store$pending_data(), file))
    output$setupMsg <- renderUI(NULL)
    observeEvent(input$saveSettings, {
      df <- data.frame(setting_key = c("trader_name", "opening_balance", "period_start", "period_end"),
                       setting_value = c(input$s_name, as.character(input$s_balance), as.character(input$s_start), as.character(input$s_end)))
      report(store$write("settings", df), "Settings"); bump()
    })
    observeEvent(settings_df(), {   # restore saved settings into the form
      s <- sv()
      if (!is.null(s$trader_name)) updateTextInput(session, "s_name", value = s$trader_name)
      if (!is.null(s$opening_balance)) updateNumericInput(session, "s_balance", value = as.numeric(s$opening_balance))
      if (!is.null(s$period_start)) updateDateInput(session, "s_start", value = as.Date(s$period_start))
      if (!is.null(s$period_end)) updateDateInput(session, "s_end", value = as.Date(s$period_end))
    }, once = TRUE, ignoreInit = TRUE)

    # ---------------------------------------------------------------- morning sheet
    observe({
      s <- sheets_df(); ch <- if (nrow(s)) format(sort(s$sheet_date, decreasing = TRUE)) else character(0)
      updateSelectInput(session, "ms_load", choices = c("(none)", ch))
    })
    observeEvent(input$ms_save, {
      d <- input$ms_date; sid <- paste0("MS_", format(d))
      prev <- sheets_df(); rv <- if (sid %in% prev$sheet_id) prev$record_version[prev$sheet_id == sid][1] + 1L else 1L
      thr <- adx_cfg(); lv <- list()
      for (i in 1:4) {
        inst <- trimws(tr_or(input[[paste0("ml", i, "_inst")]], ""))
        if (!nzchar(inst)) next
        h <- tr_num(input[[paste0("ml", i, "_ph")]]); l <- tr_num(input[[paste0("ml", i, "_pl")]]); c_ <- tr_num(input[[paste0("ml", i, "_pc")]])
        pv <- tr_pivots(h, l, c_); adx <- tr_num(input[[paste0("ml", i, "_adx")]])
        lv[[length(lv) + 1]] <- data.frame(level_id = paste0(sid, "_", inst), sheet_id = sid, sheet_date = d, instrument = inst,
          overnight_low = tr_num(input[[paste0("ml", i, "_low")]]), overnight_high = tr_num(input[[paste0("ml", i, "_high")]]),
          current_price = tr_num(input[[paste0("ml", i, "_cur")]]), time_now_uk = input[[paste0("ml", i, "_time")]], adx14 = adx,
          regime_label = tr_regime(adx, thr[1], thr[2]), prior_high = h, prior_low = l, prior_close = c_,
          pivot_pp = pv$pp, pivot_r1 = pv$r1, pivot_s1 = pv$s1, pivot_r2 = pv$r2, pivot_s2 = pv$s2, pivot_r3 = pv$r3, pivot_s3 = pv$s3, stringsAsFactors = FALSE)
      }
      hdr <- data.frame(sheet_id = sid, record_version = rv, sheet_date = d, week_no = tr_week_no(d, p_start()),
        dow_price = tr_num(input$ms_dow), dow_change_pct = tr_num(input$ms_dowc), nikkei_price = tr_num(input$ms_nik), nikkei_change_pct = tr_num(input$ms_nikc),
        overnight_news = tr_blank_na(input$ms_news), overnight_calendar = tr_blank_na(input$ms_cal_o), todays_releases = tr_blank_na(input$ms_cal_t),
        releases_in_window = tr_blank_na(input$ms_win), regime_summary = tr_blank_na(input$ms_regime), planned_setups = tr_blank_na(input$ms_setups),
        exposure_note = tr_blank_na(input$ms_expo), combined_open_risk_pct = tr_num(input$ms_risk), stand_aside = isTRUE(input$ms_stand),
        stand_aside_reason = tr_blank_na(input$ms_stand_why), stringsAsFactors = FALSE)
      r1 <- store$write("morning_sheets", hdr)
      if (length(lv)) store$write("morning_levels", do.call(rbind, lv))
      report(r1, "Morning sheet"); bump()
    })
    observeEvent(input$ms_loadBtn, {
      req(input$ms_load != "(none)")
      s <- sheets_df(); h <- s[format(s$sheet_date) == input$ms_load, ][1, ]; req(nrow(h) == 1)
      updateDateInput(session, "ms_date", value = h$sheet_date)
      for (p in list(c("ms_dow", "dow_price"), c("ms_dowc", "dow_change_pct"), c("ms_nik", "nikkei_price"), c("ms_nikc", "nikkei_change_pct"), c("ms_risk", "combined_open_risk_pct")))
        updateNumericInput(session, p[1], value = h[[p[2]]])
      for (p in list(c("ms_news", "overnight_news"), c("ms_cal_o", "overnight_calendar"), c("ms_cal_t", "todays_releases"), c("ms_win", "releases_in_window"),
                     c("ms_regime", "regime_summary"), c("ms_setups", "planned_setups"), c("ms_expo", "exposure_note"), c("ms_stand_why", "stand_aside_reason")))
        updateTextAreaInput(session, p[1], value = tr_or(h[[p[2]]], ""))
      updateCheckboxInput(session, "ms_stand", value = isTRUE(h$stand_aside))
      lv <- levels_df(); lv <- lv[lv$sheet_id == h$sheet_id, ]
      for (i in 1:4) {
        if (i <= nrow(lv)) { r <- lv[i, ]
          updateSelectizeInput(session, paste0("ml", i, "_inst"), selected = r$instrument, choices = unique(c("", tr_assets, r$instrument)), options = list(create = TRUE))
          for (p in list(c("_low", "overnight_low"), c("_high", "overnight_high"), c("_cur", "current_price"), c("_adx", "adx14"), c("_ph", "prior_high"), c("_pl", "prior_low"), c("_pc", "prior_close")))
            updateNumericInput(session, paste0("ml", i, p[1]), value = r[[p[2]]])
          updateTextInput(session, paste0("ml", i, "_time"), value = tr_or(r$time_now_uk, ""))
        } else updateSelectizeInput(session, paste0("ml", i, "_inst"), selected = "")
      }
      msg("Sheet loaded. Saving again creates a new version.")
    })
    output$ms_table <- DT::renderDT({
      s <- sheets_df(); lv <- levels_df()
      if (!nrow(s)) return(DT::datatable(data.frame(Message = "No morning sheets saved yet."), rownames = FALSE, options = list(dom = "t")))
      s <- s[order(s$sheet_date, decreasing = TRUE), ]
      s$Instruments <- vapply(s$sheet_id, function(i) paste(lv$instrument[lv$sheet_id == i], collapse = ", "), "")
      DT::datatable(s[, c("sheet_date", "week_no", "Instruments", "stand_aside", "combined_open_risk_pct", "record_version")], rownames = FALSE,
                    options = list(pageLength = 10, scrollX = TRUE))
    })

    # ---------------------------------------------------------------- trades: open
    observeEvent(input$t_asset, { p <- tr_pip_defaults[input$t_asset]; if (!is.na(p)) updateNumericInput(session, "t_pip", value = unname(p)) }, ignoreInit = TRUE)
    t_entry_ts <- reactive(tr_parse_ts(input$t_date, tr_or(input$t_time, "")))
    t_calc <- reactive(tr_entry_calc(input$t_dir, tr_num(input$t_entry), tr_num(input$t_stop), tr_num(input$t_target), tr_num(input$t_pip), tr_num(input$t_stake)))
    output$t_preview <- renderUI({
      if (all(is.na(c(tr_num(input$t_entry), tr_num(input$t_stop), tr_num(input$t_target)))))
        return(tags$div(style = "color:#64748b; font-size:12.5px; margin-bottom:8px;", "Enter entry, stop and target to see risk, reward and RRR before you save."))
      if (all(is.na(c(tr_num(input$t_entry), tr_num(input$t_stop), tr_num(input$t_target)))))
        return(tags$div(style = "color:#64748b; font-size:12.5px; margin-bottom:8px;", "Enter entry, stop and target to see risk, reward and RRR before you save."))
      e <- t_calc(); errs <- tr_validate_entry(input$t_dir, tr_num(input$t_entry), tr_num(input$t_stop), tr_num(input$t_target),
                                              tr_num(input$t_pip), tr_num(input$t_stake), input$t_mood, t_entry_ts())
      if (length(errs)) return(tags$div(style = "color:#b45309; font-size:12.5px; margin-bottom:8px;", paste(errs, collapse = " ")))
      eq <- equity_now(); rp <- 100 * e$risk_gbp / eq; g <- global_spec(); warn <- character(0)
      if (!is.null(g) && is.finite(g$risk_pct) && rp > g$risk_pct + 1e-9) warn <- c(warn, sprintf("Risk %.2f%% is above your plan's %.2f%% per trade.", rp, g$risk_pct))
      tot <- rp + tr_or(tr_num(input$t_corr), 0)
      if (!is.null(g) && is.finite(g$combined_cap_pct) && tot > g$combined_cap_pct + 1e-9) warn <- c(warn, sprintf("Combined risk %.2f%% would exceed your %.2f%% cap.", tot, g$combined_cap_pct))
      if (!is.null(g) && is.finite(tr_num(g$min_rrr)) && is.finite(e$rrr) && e$rrr < g$min_rrr - 1e-9) warn <- c(warn, sprintf("Planned RRR %.2f is below your plan's minimum of %.2f.", e$rrr, g$min_rrr))
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px; font-size:13px; color:#2c3e50;",
        sprintf("Risk %.1f pips (GBP %.2f, %.2f%% of equity) | Reward %.1f pips | Planned RRR %.2f", e$risk_pips, e$risk_gbp, rp, e$reward_pips, e$rrr),
        if (length(warn)) tags$div(style = "color:#b91c1c; font-weight:600; margin-top:4px;", paste(warn, collapse = " ")))
    })
    observeEvent(input$t_save, {
      ts <- t_entry_ts(); en <- tr_num(input$t_entry); st <- tr_num(input$t_stop); tg <- tr_num(input$t_target); pip <- tr_num(input$t_pip); stake <- tr_num(input$t_stake)
      errs <- tr_validate_entry(input$t_dir, en, st, tg, pip, stake, input$t_mood, ts)
      if (length(errs)) { msg(paste(errs, collapse = " "), "error"); return() }
      e <- tr_entry_calc(input$t_dir, en, st, tg, pip, stake); asset <- toupper(trimws(input$t_asset))
      sp <- spec_df(); adx <- tr_num(input$t_adx); thr <- adx_cfg()
      row <- data.frame(trade_id = tr_id("T"), record_version = 1L, parent_trade_id = tr_blank_na(input$t_parent), status = "OPEN",
        week_no = tr_week_no(as.Date(format(ts, tz = "Europe/London")), p_start()), asset = asset, strategy = input$t_strategy, direction = input$t_dir,
        chart_period = input$t_chart, entry_ts = ts, expected_duration_hours = tr_num(input$t_dur), pip_size = pip, stake_per_pip_gbp = stake,
        entry_price = en, stop1 = st, target = tg, initial_risk_pips = e$risk_pips, initial_reward_pips = e$reward_pips, initial_rrr = e$rrr,
        initial_risk_gbp = e$risk_gbp, risk_pct_equity = 100 * e$risk_gbp / equity_now(), regime_adx = adx, regime_label = tr_regime(adx, thr[1], thr[2]),
        correlated_open_risk_pct = tr_num(input$t_corr), mood_entry = as.integer(input$t_mood), setup_fundamental = tr_blank_na(input$t_fund),
        setup_technical = tr_blank_na(input$t_tech), trigger_text = tr_blank_na(input$t_trigger), execution_text = tr_blank_na(input$t_exec),
        stop_reason = tr_blank_na(input$t_stopwhy), target_reason = tr_blank_na(input$t_tgtwhy),
        spec_version = if (nrow(sp)) max(sp$spec_version, na.rm = TRUE) else NA_integer_,
        trade_sheet_name = sprintf("%s - %s", asset, format(ts, "%d/%m/%Y %H:%M", tz = "Europe/London")),
        entry_source = if (is.null(ev_open())) "MANUAL" else "SCREENSHOT_VERIFIED", evidence_ids = if (is.null(ev_open())) NA_character_ else ev_open(),
        verified_by_user = if (is.null(ev_open())) NA else TRUE, stringsAsFactors = FALSE)
      report(store$write("trades", row), "Trade")
      if (!is.null(ev_open())) { link_evidence(ev_open(), row$trade_id); ev_open(NULL) }
      bump()
    })

    # ---------------------------------------------------------------- trades: manage
    open_trades <- reactive({ t <- trades_df(); t[t$status == "OPEN", , drop = FALSE] })
    trade_label <- function(t) sprintf("%s %s %s (%s)", t$asset, ifelse(t$direction == "B", "Buy", "Sell"), format(t$entry_ts, "%d/%m %H:%M", tz = "Europe/London"), t$trade_id)
    observe({
      o <- open_trades(); ch <- if (nrow(o)) setNames(o$trade_id, trade_label(o)) else c("(no open trades)" = "")
      updateSelectInput(session, "m_trade", choices = ch, selected = isolate(input$m_trade))
    })
    sel <- reactive({ o <- open_trades(); req(nzchar(input$m_trade)); r <- o[o$trade_id == input$m_trade, ]; req(nrow(r) == 1); r })
    output$m_summary <- renderUI({
      o <- open_trades(); if (!nrow(o) || !nzchar(tr_or(input$m_trade, ""))) return(NULL); r <- sel()
      stops <- na.omit(c(r$stop1, r$stop2, r$stop3, r$stop4))
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px; font-size:13px; color:#2c3e50;",
        sprintf("%s %s at %s | stake GBP %.2f/pip | stops so far: %s | target %s | risk GBP %.2f | planned RRR %.2f",
                r$asset, ifelse(r$direction == "B", "buy", "sell"), r$entry_price, r$stake_per_pip_gbp, paste(stops, collapse = " → "), r$target, r$initial_risk_gbp, r$initial_rrr))
    })
    observeEvent(input$m_save, {
      act <- input$m_action; r <- sel(); ts <- tr_parse_ts(input$m_date, tr_or(input$m_time, ""))
      if (is.na(ts)) { msg("The date/time is not valid (use HH:MM, UK time).", "error"); return() }
      nxt <- r; nxt$record_version <- r$record_version + 1L
      if (act == "stop") {
        ns_ <- tr_num(input$m_newstop); if (!is.finite(ns_)) { msg("Enter the new stop price.", "error"); return() }
        slot <- which(is.na(c(r$stop2, r$stop3, r$stop4)))[1]
        if (is.na(slot)) { msg("All four stop slots are used.", "error"); return() }
        cur <- tail(na.omit(c(r$stop1, r$stop2, r$stop3, r$stop4)), 1)
        nxt[[c("stop2", "stop3", "stop4")[slot]]] <- ns_
        ev <- data.frame(event_id = tr_id("E"), trade_id = r$trade_id, event_ts = ts, event_type = "STOP_MOVE", old_stop = cur, new_stop = ns_,
                         reason = tr_blank_na(input$m_stopwhy), permitted_by_spec = input$m_permitted == "Y", stringsAsFactors = FALSE)
        store$write("trade_events", ev); report(store$write("trades", nxt), "Stop move")
      } else if (act == "cancel") {
        nxt$status <- "CANCELLED"; report(store$write("trades", nxt), "Cancellation")
      } else {
        px <- tr_num(input$m_exit); if (!is.finite(px)) { msg("Enter the exit price.", "error"); return() }
        if (!is.na(r$entry_ts) && ts < r$entry_ts) { msg("Exit is before the entry time.", "error"); return() }
        followed <- input$m_followed == "Y"
        if (!followed && !nzchar(trimws(tr_or(input$m_devnote, "")))) { msg("Describe the deviation (what happened and why).", "error"); return() }
        fill <- function(row, stake, risk_gbp) {
          cc <- tr_close_calc(row$direction, row$entry_price, px, row$pip_size, stake, risk_gbp, tr_num(input$m_pnl))
          row$status <- "CLOSED"; row$exit_ts <- ts; row$exit_price <- px; row$exit_code <- input$m_code
          row$pips_result <- cc$pips; row$net_pnl_gbp <- cc$net; row$pnl_source <- cc$source; row$real_r <- cc$real_r
          row$duration_hours <- as.numeric(difftime(ts, row$entry_ts, units = "hours")); row$mood_exit <- as.integer(input$m_mood)
          row$plan_followed <- followed; row$deviation_type <- if (followed) NA_character_ else input$m_devtype
          row$deviation_note <- if (followed) NA_character_ else tr_blank_na(input$m_devnote)
          row$reason_for_exit <- tr_blank_na(input$m_why); row$lessons_learned <- tr_blank_na(input$m_lessons)
          if (!is.null(ev_close())) { row$evidence_ids <- paste(na.omit(c(row$evidence_ids, ev_close())), collapse = ","); row$verified_by_user <- TRUE }
          row }
        if (act == "close") {
          report(store$write("trades", fill(nxt, r$stake_per_pip_gbp, r$initial_risk_gbp)), "Closed trade")
          if (!is.null(ev_close())) { link_evidence(ev_close(), r$trade_id); ev_close(NULL) }
        } else {
          ps <- tr_num(input$m_pstake)
          if (!is.finite(ps) || ps <= 0 || ps >= r$stake_per_pip_gbp - 1e-12) { msg("Partial stake must be above zero and below the open stake. Use Closed to exit everything.", "error"); return() }
          child <- r; child$trade_id <- tr_id("T"); child$record_version <- 1L; child$parent_trade_id <- r$trade_id
          child$stake_per_pip_gbp <- ps; child$initial_risk_gbp <- r$initial_risk_pips * ps
          child$trade_sheet_name <- paste0(r$trade_sheet_name, " (partial)")
          child <- fill(child, ps, child$initial_risk_gbp)
          nxt$stake_per_pip_gbp <- r$stake_per_pip_gbp - ps; nxt$initial_risk_gbp <- r$initial_risk_pips * nxt$stake_per_pip_gbp
          store$write("trade_events", data.frame(event_id = tr_id("E"), trade_id = r$trade_id, event_ts = ts, event_type = "PARTIAL_EXIT",
            size_closed_per_pip = ps, price = px, reason = tr_blank_na(input$m_why), permitted_by_spec = followed, stringsAsFactors = FALSE))
          store$write("trades", child); report(store$write("trades", nxt), "Partial exit")
          if (!is.null(ev_close())) { link_evidence(ev_close(), child$trade_id); ev_close(NULL) }
        }
      }
      bump()
    })
    output$tr_table <- DT::renderDT({
      t <- trades_df()
      if (!nrow(t)) return(DT::datatable(data.frame(Message = "No trades saved yet."), rownames = FALSE, options = list(dom = "t")))
      t <- t[order(t$entry_ts, decreasing = TRUE), ]
      t$entry <- format(t$entry_ts, "%d/%m %H:%M", tz = "Europe/London"); t$exit <- format(t$exit_ts, "%d/%m %H:%M", tz = "Europe/London")
      DT::datatable(t[, c("trade_sheet_name", "status", "strategy", "direction", "entry_price", "stop1", "target", "initial_rrr", "exit_price", "exit_code",
                          "net_pnl_gbp", "real_r", "plan_followed", "week_no")], rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE)) |>
        DT::formatRound(c("initial_rrr", "net_pnl_gbp", "real_r"), 2)
    })
    output$dlTrades <- downloadHandler(filename = function() paste0("trading_trades_", format(Sys.Date()), ".csv"),
                                       content = function(file) write.csv(trades_df(), file, row.names = FALSE, na = ""))

    # ---------------------------------------------------------------- statistics
    stats <- reactive({
      t <- trades_df(); cl <- t[t$status == "CLOSED" & !is.na(t$net_pnl_gbp), , drop = FALSE]
      if (!identical(input$st_week, "all") && !is.null(input$st_week)) cl <- cl[!is.na(cl$week_no) & cl$week_no == as.integer(input$st_week), , drop = FALSE]
      tr_stats(cl, opening())
    })
    output$st_tiles <- renderUI({
      s <- stats(); if (is.null(s)) return(tags$div(style = "color:#2c3e50; padding:12px;", "No closed trades yet. Statistics appear as soon as you close a trade."))
      m <- s$summary
      tags$div(style = "display:flex; flex-wrap:wrap;",
        tr_tile("Trades", m$trades, sprintf("%d won · %d lost", m$wins, m$losses)), tr_tile("Win rate", tr_fmt_pct(m$win_rate)),
        tr_tile("Avg planned RRR", tr_fmt_num(m$avg_initial_rrr)), tr_tile("Avg Real R", tr_fmt_num(m$avg_real_r), "expectancy per trade, in R"),
        tr_tile("Net P/L", paste0("£", tr_fmt_num(m$total_pnl_gbp)), tr_fmt_pct(m$return_pct, 2), if (m$total_pnl_gbp >= 0) "#15803d" else "#b91c1c"),
        tr_tile("Max drawdown", tr_fmt_pct(m$max_drawdown_pct, 2), paste0("£", tr_fmt_num(m$max_drawdown_gbp))),
        tr_tile("Adherence", tr_fmt_pct(m$adherence_rate), sprintf("%d followed · %d deviations", m$followed, m$deviations)),
        tr_tile("Profit factor", tr_fmt_num(m$profit_factor)), tr_tile("Avg win / loss", paste0("£", tr_fmt_num(m$avg_win_gbp, 0), " / £", tr_fmt_num(m$avg_loss_gbp, 0))),
        tr_tile("Sharpe / Sortino", paste(tr_fmt_num(m$sharpe_per_trade), "/", tr_fmt_num(m$sortino_per_trade)), "per trade, secondary"))
    })
    output$st_caution <- renderUI({
      s <- stats(); if (is.null(s) || s$summary$trades >= 20) return(NULL)
      ua_callout(sprintf("Only %d closed trade(s): ratios and percentages move a lot with each new trade. Lean on the individual trade reviews, adherence and consistency.", s$summary$trades))
    })
    output$st_equity <- plotly::renderPlotly({
      s <- stats(); req(s); e <- s$equity
      plotly::plot_ly(e, x = ~trade_no, y = ~equity, type = "scatter", mode = "lines+markers", line = list(color = "#008A82"), name = "Equity") |>
        plotly::layout(title = list(text = "Equity by trade", font = list(size = 13)), xaxis = list(title = "Trade number", dtick = 1), yaxis = list(title = "GBP"))
    })
    output$st_r <- plotly::renderPlotly({
      s <- stats(); req(s); t <- s$trades; t$n <- seq_len(nrow(t))
      plotly::plot_ly(t, x = ~n, y = ~real_r, type = "bar", marker = list(color = ifelse(t$real_r >= 0, "#15803d", "#b91c1c")), name = "Real R") |>
        plotly::layout(title = list(text = "Real R by trade", font = list(size = 13)), xaxis = list(title = "Trade number", dtick = 1), yaxis = list(title = "R"))
    })
    fmt_tbl <- function(d) { if (is.null(d)) return(NULL); d$`Win rate` <- if ("Win rate" %in% names(d)) sprintf("%.0f%%", 100 * d$`Win rate`); d }
    tbl <- function(key, fix = TRUE) renderTable({ s <- stats(); req(s); d <- s[[key]]; if (fix && !is.null(d) && "Win rate" %in% names(d)) d$`Win rate` <- sprintf("%.0f%%", 100 * d$`Win rate`); d },
                                                  striped = TRUE, bordered = TRUE, spacing = "s", digits = 2)
    output$st_strat <- tbl("by_strategy"); output$st_asset <- tbl("by_asset"); output$st_exit <- tbl("by_exit")
    output$st_wd <- tbl("by_weekday", FALSE); output$st_hr <- tbl("by_hour", FALSE); output$st_mood <- tbl("by_mood", FALSE)

    # ---------------------------------------------------------------- reviews
    rv_auto_counts <- reactive({
      t <- trades_df(); d <- input$rv_date; req(d)
      local_d <- as.Date(format(t$entry_ts, tz = "Europe/London"))
      if (identical(input$rv_type, "Daily")) k <- !is.na(local_d) & local_d == d
      else { w <- tr_week_no(d, p_start()); k <- !is.na(t$week_no) & !is.na(w) & t$week_no == w }
      sub <- t[k & t$status != "CANCELLED", ]
      list(n = nrow(sub), followed = sum(sub$plan_followed %in% TRUE), dev = sum(sub$plan_followed %in% FALSE))
    })
    observe({ updateNumericInput(session, "rv_n", value = rv_auto_counts()$n) })
    output$rv_auto <- renderUI({ a <- rv_auto_counts(); tags$div(style = "font-size:12.5px; color:#2c3e50; margin-bottom:8px;",
      sprintf("From your trades: %d taken, %d followed the plan, %d deviated.", a$n, a$followed, a$dev)) })
    observeEvent(input$rv_save, {
      d <- input$rv_date; w <- tr_week_no(d, p_start()); rid <- paste0("RV_", input$rv_type, "_", format(d))
      prev <- reviews_df(); rv <- if (rid %in% prev$review_id) prev$record_version[prev$review_id == rid][1] + 1L else 1L
      row <- data.frame(review_id = rid, record_version = rv, review_date = d, review_type = toupper(input$rv_type), week_no = w,
        trades_taken = as.integer(input$rv_n), what_worked = tr_blank_na(input$rv_worked), what_did_not = tr_blank_na(input$rv_not),
        deviations_summary = tr_blank_na(input$rv_dev), changes_for_next_period = tr_blank_na(input$rv_change), change_effective_date = input$rv_eff,
        loss_limit_breached = isTRUE(input$rv_loss), exposure_cap_breached = isTRUE(input$rv_cap), overall_mood = as.integer(input$rv_mood), stringsAsFactors = FALSE)
      report(store$write("reviews", row), "Review"); bump()
    })
    output$rv_table <- DT::renderDT({
      r <- reviews_df()
      if (!nrow(r)) return(DT::datatable(data.frame(Message = "No reviews saved yet."), rownames = FALSE, options = list(dom = "t")))
      r <- r[order(r$review_date, decreasing = TRUE), ]
      DT::datatable(r[, c("review_date", "review_type", "week_no", "trades_taken", "what_worked", "what_did_not", "changes_for_next_period", "record_version")], rownames = FALSE, options = list(pageLength = 8, scrollX = TRUE))
    })

    # ---------------------------------------------------------------- plan spec
    observeEvent(input$sp_save, {
      s <- spec_df(); strat <- input$sp_strategy; prev <- s[s$strategy == strat, ]
      ver <- if (nrow(prev)) max(prev$spec_version) + 1L else 1L
      if (ver > 1 && !nzchar(trimws(tr_or(input$sp_reason, "")))) { msg("A reason is required for any change after version 1.", "error"); return() }
      g <- strat == "GLOBAL"
      row <- data.frame(spec_id = sprintf("%s_v%d", strat, ver), spec_version = ver, effective_date = Sys.Date(), strategy = strat,
        entry_rule = tr_blank_na(input$sp_entry), stop_rule = tr_blank_na(input$sp_stop), target_rule = tr_blank_na(input$sp_target), management_rule = tr_blank_na(input$sp_mgmt),
        adx_trend_min = if (g) tr_num(input$sp_adx_t) else NA_real_, adx_range_max = if (g) tr_num(input$sp_adx_r) else NA_real_,
        risk_pct = if (g) tr_num(input$sp_risk) else NA_real_, combined_cap_pct = if (g) tr_num(input$sp_cap) else NA_real_,
        correlated_rule = if (g) input$sp_corr else NA_character_, max_open_positions = if (g) as.integer(input$sp_maxpos) else NA_integer_,
        daily_loss_limit_pct = if (g) tr_num(input$sp_dloss) else NA_real_, weekly_loss_limit_pct = if (g) tr_num(input$sp_wloss) else NA_real_,
        change_reason = tr_blank_na(input$sp_reason),
        setup_rule = if (!g) tr_blank_na(input$sp_setup) else NA_character_, trigger_rule = if (!g) tr_blank_na(input$sp_trigger) else NA_character_,
        execution_rule = if (!g) tr_blank_na(input$sp_exec) else NA_character_,
        monthly_loss_limit_pct = if (g) tr_num(input$sp_mloss) else NA_real_, min_rrr = if (g) tr_num(input$sp_minrrr) else NA_real_,
        tf_minor = if (g) tr_blank_na(input$sp_tfminor) else NA_character_, tf_base = if (g) tr_blank_na(input$sp_tfbase) else NA_character_, tf_major = if (g) tr_blank_na(input$sp_tfmajor) else NA_character_,
        data_sources = if (g) tr_blank_na(input$sp_data) else NA_character_, objectives = if (g) tr_blank_na(input$sp_obj) else NA_character_,
        indicators = if (g) tr_blank_na(input$sp_ind) else NA_character_, stringsAsFactors = FALSE)
      report(store$write("plan_spec", row), sprintf("Spec %s v%d", strat, ver)); bump()
    })
    output$sp_table <- DT::renderDT({
      s <- spec_df()
      if (!nrow(s)) return(DT::datatable(data.frame(Message = "No spec saved yet."), rownames = FALSE, options = list(dom = "t")))
      s <- s[order(s$strategy, s$spec_version, decreasing = c(FALSE, TRUE), method = "radix"), ]
      DT::datatable(s[, c("spec_id", "effective_date", "setup_rule", "trigger_rule", "execution_rule", "entry_rule", "stop_rule", "target_rule", "management_rule", "adx_trend_min", "adx_range_max", "risk_pct", "combined_cap_pct", "change_reason")],
                    rownames = FALSE, options = list(pageLength = 8, scrollX = TRUE))
    })

    # ---------------------------------------------------------------- schema
    proj <- function() tr_or(tryCatch(api_manager$bq_project_id, error = function(e) NULL), "atera-2")
    dset <- function() tr_or(tryCatch(api_manager$bq_dataset_id, error = function(e) NULL), "business_strategy")
    output$schemaTables <- renderUI({
      tagList(lapply(names(tr_tables), function(n) { tb <- tr_tables[[n]]
        tags$details(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px; color:#2c3e50;",
          tags$summary(style = "font-weight:700; cursor:pointer;", sprintf("%s  (key: %s, %d columns)", tb$table, tb$key, length(tb$cols))),
          tags$div(style = "font-size:12px; line-height:1.6; margin-top:6px;", paste(sprintf("%s %s", names(tb$cols), tb$cols), collapse = " · ")))
      }))
    })
    ddl_text <- reactive(paste(paste0(tr_ddl(proj(), dset()), ";"), collapse = "\n\n"))
    output$ddlText <- renderText(ddl_text())
    output$dlDDL <- downloadHandler(filename = function() "trading_records_schema.sql", content = function(file) writeLines(ddl_text(), file))
  })
}
