# modules/unit3_execution_plan.R
# Unit 3 - Execution Plan: a step-by-step operating guide for the 4-week trading period
# (Mon 12 Oct - Fri 6 Nov 2026), built around the Morning Sheet, Individual Trade Sheet and
# Trade Blotter documents.
#
# SCOPE: process guidance + two small trading utilities (position-size and combined-risk
# check) + a DST-aware EIA release timetable. It does NOT contain, generate or simulate any
# trades, results, or assignment text. Task 1/2/3 must be written by the student from the
# student's own plan and own records.

u3ep_start <- as.Date("2026-10-19")
u3ep_end   <- as.Date("2026-11-13")

tr_or_null <- function(x) if (is.null(x)) character(0) else x

# ---- pure helpers (unit-tested) ---------------------------------------------------------

# Phase of the period for a given date.
u3ep_phase <- function(d, start = u3ep_start, end = u3ep_end) {
  d <- as.Date(d)
  wd <- function(a, b) { if (b < a) 0L else sum(!format(seq(a, b, by = "day"), "%u") %in% c("6", "7")) }
  if (d < start) {
    return(list(phase = "before", week = NA_integer_, days_to_start = as.integer(start - d),
                trading_days_left = wd(start, end)))
  }
  if (d > end) return(list(phase = "after", week = NA_integer_, days_to_start = NA_integer_, trading_days_left = 0L))
  is_weekend <- format(d, "%u") %in% c("6", "7")
  list(phase = if (is_weekend) "weekend" else "trading",
       week = as.integer(floor(as.numeric(d - start) / 7)) + 1L,
       days_to_start = 0L,
       trading_days_left = wd(if (is_weekend) d + 1 else d, end))
}

# Weeks table (dates computed, not typed).
u3ep_weeks <- function(start = u3ep_start) {
  s <- start + 7 * (0:3)
  data.frame(Week = paste("Week", 1:4),
             Dates = paste(format(s, "%a %d %b"), "–", format(s + 4, "%a %d %b")),
             stringsAsFactors = FALSE)
}

# EIA weekly releases inside the period shown in UK local time (handles the UK/US clock
# changes: UK back on 25 Oct, US back on 1 Nov). Wed = petroleum status, Thu = nat gas storage;
# both nominally 10:30 US Eastern. Holiday shifts are NOT modelled - the UI says to verify.
u3ep_eia_schedule <- function(start = u3ep_start, end = u3ep_end) {
  days <- seq(start, end, by = "day")
  days <- days[format(days, "%u") %in% c("3", "4")]
  et <- as.POSIXct(paste(format(days), "10:30:00"), tz = "America/New_York")
  uk <- format(et, "%H:%M", tz = "Europe/London")
  data.frame(Date = format(days, "%a %d %b"),
             Release = ifelse(format(days, "%u") == "3", "EIA Weekly Petroleum Status", "EIA Natural Gas Storage"),
             `US Eastern` = "10:30",
             `UK time` = uk,
             `UK-US gap` = paste0(as.integer(format(et, "%H", tz = "Europe/London")) - 10L, "h"),
             check.names = FALSE, stringsAsFactors = FALSE)
}

# Position sizing from a fixed-risk rule. Returns NA-safe list.
u3ep_position_size <- function(equity, risk_pct, stop_pips, gbp_per_pip_per_lot = NA) {
  if (any(!is.finite(c(equity, risk_pct, stop_pips))) || equity <= 0 || risk_pct <= 0 || stop_pips <= 0)
    return(list(ok = FALSE, risk_gbp = NA, stake_per_pip = NA, lots = NA))
  risk_gbp <- equity * risk_pct / 100
  stake <- risk_gbp / stop_pips
  lots <- if (is.finite(gbp_per_pip_per_lot) && gbp_per_pip_per_lot > 0) stake / gbp_per_pip_per_lot else NA
  list(ok = TRUE, risk_gbp = risk_gbp, stake_per_pip = stake, lots = lots)
}

# Combined open-risk check against a cap (all values in % of equity).
u3ep_exposure <- function(open_risks, new_risk, cap) {
  open_risks <- open_risks[is.finite(open_risks)]
  total <- sum(open_risks, na.rm = TRUE) + ifelse(is.finite(new_risk), new_risk, 0)
  list(total = total, cap = cap, headroom = cap - total, ok = total <= cap + 1e-9)
}

# ---- UI building blocks (inline styles so they read on the dark page) -------------------

u3ep_step <- function(num, title, ...) {
  tags$div(style = "background:#ffffff; border:1px solid #e2e8f0; border-left:5px solid #008A82; border-radius:10px; padding:16px 20px; margin-bottom:18px; box-shadow:0 1px 4px rgba(0,44,60,0.06);",
    tags$div(style = "display:flex; align-items:center; gap:10px; margin-bottom:10px; padding-bottom:8px; border-bottom:1px solid #e2e8f0;",
      tags$span(style = "background:#008A82; color:#ffffff; font-weight:800; border-radius:50%; min-width:28px; height:28px; display:inline-flex; align-items:center; justify-content:center; font-size:13px;", num),
      tags$span(style = "font-size:16px; font-weight:800; color:#002C3C;", title)),
    tags$div(style = "font-size:13.5px; line-height:1.75; color:#2c3e50;", ...))
}

u3ep_p  <- function(...) tags$p(style = "color:#2c3e50; margin:0 0 8px 0;", ...)
u3ep_li <- function(...) tags$li(style = "color:#2c3e50; margin-bottom:4px;", ...)
u3ep_lab <- function(x) tags$span(style = "color:#2c3e50; font-weight:600; font-size:12.5px;", x)

u3ep_check_group <- function(id, title, items) {
  tags$div(style = "background:#f6f8fb; border-radius:8px; padding:10px 14px; margin-bottom:10px;",
    tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:4px;", title),
    checkboxGroupInput(id, label = NULL, width = "100%",
      choiceNames  = lapply(items, function(x) tags$span(style = "color:#2c3e50; font-weight:400; font-size:13px;", x)),
      choiceValues = seq_along(items)))
}

u3ep_pre_items <- list(
  spec = c(
    "Pivot Point Bounce: written set-up, trigger (the course uses a touch of a pivot, then Candle 1 failing, then a break of Candle 1), execution, stop placement, target and management rules",
    "Holy Grail: written set-up and trigger (ADX above 30 and turning down, retracement to the 20-period EMA, 2-bar entry order), stop, target, management",
    "Straddle: range definition (morning straddle: overnight range 22:00-06:00 London; news straddle: the pre-release range), spread added to the high, buffer of 1-2 pips, one-cancels-other or both legs live, what happens if both sides fill, slippage / gap allowance, spread or volatility level at which you stand aside",
    "Regime rule written down: ADX(14) above 30 = trend, below 20 = range, 20-30 = no trade",
    "Risk per trade fixed (1-2% of equity) and the cap on COMBINED open risk across correlated markets",
    "Correlated-markets rule chosen: trade only the strongest setup, OR split risk across positions",
    "Maximum open positions, daily loss limit and weekly loss limit written down",
    "Spec dated and saved as a frozen file (any later change must be logged with date and reason)"),
  rec = c(
    "Trade Blotter: name, start date (12 Oct), opening balance and exit/mood codes completed on the Intro sheet",
    "Morning Sheet template adapted to your instruments (add natural gas; keep only the pairs you trade)",
    "Individual Trade Sheet template saved as a clean master copy",
    "Dropbox folders created: Morning Sheets / Trade Sheets / Blotter / Charts",
    "File-naming convention fixed, e.g. \"WTI - 14/10/2026 09:40\" for the trade sheet name used in the Blotter",
    "Screenshot routine tested (entry, each stop move or partial exit, exit)"),
  plat = c(
    "Real-time platform chosen and demo/live status recorded",
    "Instrument codes noted (WTI, natural gas, EUR/USD) with typical spreads and trading hours",
    "Timeframes chosen with the Rule of Five (base, major, minor); charts prepared for them (the course suggests 5-minute bars for the pivot bounce), daily for prior-session pivots",
    "ADX(14), 20-period EMA and the seven pivot levels added and checked against a known value (the course slides give a worked pivot example)",
    "Price alerts or reminders set for the pre-release ranges"),
  cal = c(
    "EIA release times for the four weeks confirmed (see timetable below, including the Columbus Day week)",
    "FOMC, US jobs report and other high-impact dates for the period marked in your diary",
    "UK/US clock-change weeks noted (25 Oct and 1 Nov)",
    "Economic Calendars tab loaded with the period's events as context"))

u3ep_pre_total <- sum(lengths(u3ep_pre_items))

# ---- UI ---------------------------------------------------------------------------------

unit3_execution_plan_ui <- function(id) {
  ns <- NS(id)
  tbl <- function(df) ua_table(df)

  tagList(
    ua_intro("Unit 3", "Execution Plan — Step by Step", "40%", "Task 1: 1,225 · Task 2: 1,575 · Task 3: 700 words",
             "Operating guide for your four-week trading period: Monday 12 October to Friday 6 November 2026. It shows what to prepare, what to record every day, how to review every week, and how your own records feed the three tasks."),

    ua_callout(tags$strong("Your work, your records. "),
      "This tab is a process guide plus two small trading calculators. It does not contain trades, results or answer text. Task 1 comes from the plan you write and freeze; Task 2 and Task 3 come from your own trades and notes. Any illustrative or simulated draft with invented trades must not be reused in a submission."),

    uiOutput(ns("statusBox")),

    u3ep_step("1", "The period at a glance",
      u3ep_p("Four weeks is the minimum, so there is no spare week. Treat missed days as a recorded fact, not something to catch up on."),
      tableOutput(ns("weeksTable")),
      tags$ul(
        u3ep_li(tags$b("Week 1 — bed in the process: "), "only fully triggered set-ups; every field of every document completed on the day."),
        u3ep_li(tags$b("Week 2 — measure: "), "compare planned R with Real R on each trade; check combined exposure daily."),
        u3ep_li(tags$b("Week 3 — hold discipline: "), "losing runs are when rules get broken; log every deviation honestly."),
        u3ep_li(tags$b("Week 4 — close out: "), "no size increases to “make up”; finish all trade sheets; start collecting evidence.")
      )),

    u3ep_step("2", "Before the first trade (finish by Sunday 11 Oct)",
      u3ep_p("Tick items as you complete them. Ticks are saved to your records (BigQuery) when connected, and otherwise last only for this session, so keep your own copy as well."),
      uiOutput(ns("preProgress")),
      u3ep_check_group(ns("chk_spec"), "A. Strategy specification — write once, then freeze", u3ep_pre_items$spec),
      u3ep_check_group(ns("chk_rec"),  "B. Records setup", u3ep_pre_items$rec),
      u3ep_check_group(ns("chk_plat"), "C. Platform and charts", u3ep_pre_items$plat),
      u3ep_check_group(ns("chk_cal"),  "D. Calendar and timing", u3ep_pre_items$cal),
      ua_callout(tags$strong("Why the straddle needs the most detail. "),
        "Around news releases spreads widen and price can gap past a resting order, so the fill can be worse than the level you set. Define in advance how far from the range your orders sit, how you treat a gap, what you do when one side fills, and when you will not place it at all.")),

    u3ep_step("3", "Every trading day — the routine",
      ua_callout(tags$strong("Where to save it. "), "Use Trade Journal \u2192 Trading Records (BigQuery) for the Morning Sheet, each trade, reviews and your plan versions. It saves permanently once BigQuery is connected and works out the Blotter statistics for you. Keep the Word/Excel documents in Dropbox as your formal copies."),
      tbl(data.frame(
        Step = c("1. Before your first trade", "2. Regime read", "3. Check exposure", "4. Wait for the trigger",
                 "5. Enter and record", "6. Manage", "7. Exit and record", "8. End of day"),
        Action = c(
          "Complete the <b>Morning Sheet</b>: overnight prices and changes, news, and today's release calendar. Note which releases fall inside your trading window.",
          "Read ADX(14) on each instrument. Above 30: trend (Holy Grail). Below 20: range (Pivot Point Bounce). 20–30: no trade. A scheduled high-impact release: the straddle is possible, but the Reference Manual warns about whipsaw and spread widening.",
          "Count open risk across correlated markets. Use the exposure check below. If a new trade would breach your cap, trade only the strongest setup or skip.",
          "Compare actual price action to the written trigger. No trigger, no trade. Decide the stop and target before entering.",
          "Place the trade with its stop and target. Fill in the top half of the <b>Trade Sheet</b> (set-up, trigger, execution, reasons for stop and target) and take the entry screenshots.",
          "Any stop move or partial exit needs a note and a new chart image saying why. Check it against your written management rule first.",
          "Complete the exit table, reason for exit, lessons learned and exit chart. If you exited in stages, record each as its own line.",
          "Add the trade to the <b>Blotter</b> (mood 1–5, stops, exit code, plan followed yes/no). Save everything to Dropbox before you stop."),
        stringsAsFactors = FALSE))),

    u3ep_step("4", "Decision guide — regime to set-up",
      tbl(data.frame(
        `ADX(14)` = c("Above 30", "Below 20", "20 to 30", "Scheduled high-impact release"),
        Reading = c("Trending", "Range-bound", "Unclear", "Event-driven volatility"),
        `Set-up considered` = c("Holy Grail: slow, corrective pullback to the 20-period EMA with the ADX turning down, then an order beyond the 2-bar high or low", "Pivot Point Bounce: touch of a pivot, Candle 1 fails to extend, break of Candle 1 (target the next pivot)", "No trade", "Straddle: resting orders either side of the range (overnight range in the morning, pre-release range for news)"),
        check.names = FALSE, stringsAsFactors = FALSE)),
      ua_callout(tags$strong("Course rules and the signal tabs. "),
        "Unit 3 \u2013 Workbench \u2192 Strategy Rules (LAT) sets out the Holy Grail, pivot point and straddle rules from the course material, with calculators. The Live Signals tabs now apply those rules and your 30/20 ADX thresholds, with 20 to 30 shown as no trade. They flag conditions only; the decision and the order are yours.")),

    u3ep_step("5", "The three documents — what goes where",
      tags$h5(style = "color:#002C3C; font-weight:800;", "Morning Sheet (daily, before trading)"),
      tbl(data.frame(
        Section = c("Overnight markets", "Currency / commodity ranges", "Fundamental news", "Economic calendar (overnight)", "Today's data releases"),
        What = c("Dow and Nikkei with change.", "Low, high, current price and time for each instrument you trade (add natural gas).", "The overnight news that matters for your instruments, in your own words.", "Paste the overnight events.", "Paste today's events; mark the ones inside your trading window."),
        stringsAsFactors = FALSE)),
      tags$h5(style = "color:#002C3C; font-weight:800; margin-top:14px;", "Individual Trade Sheet (one per trade)"),
      tbl(data.frame(
        Field = c("Chart period, expected duration", "Initial risk / reward / RRR", "Set-up (fundamental)", "Set-up (technical)", "Trigger", "Execution", "Reason for stop / target", "In-trade management", "Exit table", "Reason for exit, lessons learned"),
        `What good looks like` = c("Decided before entry.", "Pips to stop, pips to target, ratio. Fixed at entry.", "Why the macro or supply/demand picture supports the direction.", "Multi-timeframe reasoning (daily, hourly, entry timeframe), referring to levels on the charts.", "The exact event that made you enter.", "How you got in (order type, filter).", "The technical level each is tied to, not a round number.", "Every stop move or partial exit, with reason and an updated chart.", "One line per exit stage.", "What the market did next and what you would change."),
        check.names = FALSE, stringsAsFactors = FALSE)),
      tags$h5(style = "color:#002C3C; font-weight:800; margin-top:14px;", "Trade Blotter (official tracking)"),
      tbl(data.frame(
        Item = c("Do not type in grey cells", "Mood (1–5)", "Exit codes", "Initial RRR vs Actual RRR", "Net P/L, running P/L", "Trade sheet name", "Per-sheet statistics"),
        Meaning = c("They are formulas; typing over them breaks the statistics.", "1 extremely unhappy/stressed, 3 neutral, 5 extremely happy, calm and confident. Record it at the time.", "S1 hit initial stop · S2+ hit a trailing stop · ME manual exit · T target hit.", "Planned ratio at entry compared with what the trade actually delivered (Real R).", "Fill from your platform statement, not from memory.", "Must match the saved Trade Sheet file name.", "Equity Curve, PnL, RRR, Asset Based and Other Stats sheets fill from the Blotter. Copy the formulas down as the sheet notes."))),
      u3ep_p("Blotter formulas may need to be dragged down to include new rows; follow the notes on each sheet.")),

    u3ep_step("6", "Calculators — position size and combined risk",
      fluidRow(
        column(6, tags$div(style = "background:#f6f8fb; border-radius:8px; padding:12px 14px;",
          tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:6px;", "Position size from a fixed-risk rule"),
          numericInput(ns("equity"), u3ep_lab("Account equity (£)"), 10000, min = 0, step = 100),
          numericInput(ns("riskPct"), u3ep_lab("Risk per trade (% of equity)"), 1, min = 0, step = 0.25),
          numericInput(ns("stopPips"), u3ep_lab("Stop distance (pips or points)"), 20, min = 0, step = 1),
          numericInput(ns("pipLot"), u3ep_lab("£ per pip per 1.0 lot (optional)"), NA, min = 0),
          uiOutput(ns("sizeOut")))),
        column(6, tags$div(style = "background:#f6f8fb; border-radius:8px; padding:12px 14px;",
          tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:6px;", "Combined risk across correlated markets"),
          numericInput(ns("cap"), u3ep_lab("Cap on combined open risk (% of equity)"), 2, min = 0, step = 0.25),
          numericInput(ns("open1"), u3ep_lab("Open position 1 risk (%)"), 0, min = 0, step = 0.25),
          numericInput(ns("open2"), u3ep_lab("Open position 2 risk (%)"), 0, min = 0, step = 0.25),
          numericInput(ns("newRisk"), u3ep_lab("New trade risk (%)"), 1, min = 0, step = 0.25),
          uiOutput(ns("expoOut"))))),
      u3ep_p("Stake per pip = risk £ ÷ stop distance. The stop is set by the set-up first; the size follows from it, never the reverse.")),

    u3ep_step("7", "Release timetable for the period (UK time)",
      u3ep_p("Weekly EIA releases, converted from US Eastern time so the clock changes are handled. Monday 12 October is a US federal holiday, and EIA usually delays that week's petroleum report by a day. Confirm each date on EIA's own schedule before relying on it."),
      tableOutput(ns("eiaTable"))),

    u3ep_step("8", "Every Friday — weekly review",
      tags$ol(
        u3ep_li("Open the Blotter statistics: win rate, average RRR (planned and actual), maximum drawdown, adherence, per-asset and per-strategy results."),
        u3ep_li("Re-read every trade sheet from the week against your frozen specification. Mark each trade as followed or not followed."),
        u3ep_li("For each deviation write what happened, why, and whether it was a lapse or a reasoned decision. Be specific."),
        u3ep_li("Check combined-risk compliance and the loss limits."),
        u3ep_li("Record anything you want to change in a dated change log and apply it only from the next week, with the reason. Do not edit the original spec."),
        u3ep_li("Back up Dropbox.")),
      u3ep_p("With only a few weeks of trades, Sharpe and Sortino are a secondary line; the weight is on individual trade reviews, consistency and adherence.")),

    u3ep_step("9", "After Friday 6 November — turning records into your write-up",
      tbl(data.frame(
        Task = c("Task 1 (1,225 words)", "Task 2 (1,575 words)", "Task 3 (700 words)"),
        `Evidence to gather` = c(
          "Your frozen specification and dated change log; the asset justification you actually used; objective, decision process, triggers, targets and management exactly as written before 12 Oct.",
          "Blotter statistics and equity curve; trade sheets for key trades; the adherence record and your deviation notes; asset-by-asset results against what you expected.",
          "Per-strategy results from the Blotter; your own examples of where each set-up worked and failed; the conditions at the time."),
        `How to use it` = c("Describe the plan as it was before trading, not as it turned out.", "Evaluate honestly, including departures from the plan and their causes.", "Judge your use of the strategy over this period, and say what you would change."),
        check.names = FALSE, stringsAsFactors = FALSE)),
      tags$ul(
        u3ep_li("Charts: use the Blotter equity curve and screenshots from the trade sheets."),
        u3ep_li("Write each task in your own words, count the words and enter the count at the head of each task."),
        u3ep_li("Cite your sources in Harvard style and complete the learner statement honestly.")))
    ,

    u3ep_step("10", "Common ways this goes wrong",
      tags$ul(
        u3ep_li("Filling documents in afterwards. Records written later lose the reasoning you actually had."),
        u3ep_li("Changing the spec mid-period without logging it, which makes the adherence figure meaningless."),
        u3ep_li("Typing over grey Blotter cells, or letting the trade sheet name drift from the Blotter entry."),
        u3ep_li("Sizing from the account instead of from the stop distance."),
        u3ep_li("Stacking correlated positions that together exceed your risk cap."),
        u3ep_li("Hiding bad trades. A lapse recorded honestly is better evidence than a clean record that isn't true.")))
  )
}

# ---- Server -----------------------------------------------------------------------------

unit3_execution_plan_server <- function(id, store = NULL) {
  moduleServer(id, function(input, output, session) {

    # ---- persistence of checklist ticks and calculator defaults (optional) -------------------
    # When a records store is supplied (see R/utils_trading_records.R) the ticks and the
    # equity / risk / cap values are saved to the settings table and restored on the next visit
    # as soon as BigQuery is connected (or immediately for session-queued values).
    chk_ids <- c(chk_spec = "u3ep_chk_spec", chk_rec = "u3ep_chk_rec", chk_plat = "u3ep_chk_plat", chk_cal = "u3ep_chk_cal")
    num_ids <- c(equity = "u3ep_equity", riskPct = "u3ep_riskPct", cap = "u3ep_cap")
    last_saved <- new.env(parent = emptyenv())
    save_kv <- function(key, value) {
      value <- paste(value, collapse = ",")
      if (identical(last_saved[[key]], value)) return(invisible())
      last_saved[[key]] <- value
      try(store$write("settings", data.frame(setting_key = key, setting_value = value, stringsAsFactors = FALSE)), silent = TRUE)
    }
    if (!is.null(store)) {
      restore <- function() {
        s <- tryCatch(tr_read_current(store, "settings"), error = function(e) NULL)
        if (is.null(s) || !nrow(s)) return()
        v <- setNames(as.list(s$setting_value), s$setting_key)
        for (inp in names(chk_ids)) { k <- chk_ids[[inp]]
          if (!is.null(v[[k]])) { sel <- if (is.na(v[[k]]) || !nzchar(v[[k]])) character(0) else strsplit(v[[k]], ",")[[1]]
            last_saved[[k]] <- v[[k]]; updateCheckboxGroupInput(session, inp, selected = sel) } }
        for (inp in names(num_ids)) { k <- num_ids[[inp]]
          if (!is.null(v[[k]]) && is.finite(suppressWarnings(as.numeric(v[[k]])))) { last_saved[[k]] <- v[[k]]; updateNumericInput(session, inp, value = as.numeric(v[[k]])) } }
      }
      was_connected <- reactiveVal(FALSE)
      observe({ invalidateLater(3000); cn <- store$connected()
        if (cn && !isolate(was_connected())) { was_connected(TRUE); restore() } else if (!cn) was_connected(FALSE) })
      observeEvent(TRUE, restore(), once = TRUE)
      for (inp in names(chk_ids)) local({ i <- inp; k <- chk_ids[[inp]]
        d <- debounce(reactive(input[[i]]), 1200)
        observeEvent(d(), save_kv(k, as.character(tr_or_null(d()))), ignoreInit = TRUE, ignoreNULL = FALSE) })
      for (inp in names(num_ids)) local({ i <- inp; k <- num_ids[[inp]]
        d <- debounce(reactive(input[[i]]), 1200)
        observeEvent(d(), { if (is.finite(tr_num(d()))) save_kv(k, as.character(d())) }, ignoreInit = TRUE) })
    }

    output$statusBox <- renderUI({
      ph <- u3ep_phase(Sys.Date())
      msg <- switch(ph$phase,
        before  = sprintf("Trading period starts in %d day%s (Monday 12 October). %d trading days in the period.",
                          ph$days_to_start, ifelse(ph$days_to_start == 1, "", "s"), ph$trading_days_left),
        trading = sprintf("Week %d of 4. %d trading day%s left including today.", ph$week, ph$trading_days_left, ifelse(ph$trading_days_left == 1, "", "s")),
        weekend = sprintf("Weekend of week %d. Do your weekly review and prepare for Monday. %d trading days left.", ph$week, ph$trading_days_left),
        after   = "The trading period has ended. Move to step 9 and assemble your evidence.")
      tags$div(style = "background:#002C3C; color:#ffffff; border-radius:10px; padding:12px 18px; margin-bottom:16px; font-size:14px;",
               tags$strong("Where you are: "), msg)
    })

    output$weeksTable <- renderTable(u3ep_weeks(), striped = TRUE, bordered = TRUE, spacing = "s")

    output$preProgress <- renderUI({
      done <- sum(lengths(list(input$chk_spec, input$chk_rec, input$chk_plat, input$chk_cal)))
      pct <- round(100 * done / u3ep_pre_total)
      tags$div(style = "margin-bottom:10px;",
        tags$div(style = "font-size:12px; color:#2c3e50; margin-bottom:3px;", sprintf("%d of %d items done (%d%%)", done, u3ep_pre_total, pct)),
        tags$div(style = "background:#e2e8f0; border-radius:6px; height:10px; overflow:hidden;",
                 tags$div(style = sprintf("background:#008A82; width:%d%%; height:10px;", pct))))
    })

    output$sizeOut <- renderUI({
      r <- u3ep_position_size(input$equity, input$riskPct, input$stopPips, input$pipLot)
      if (!r$ok) return(tags$div(style = "color:#b45309; font-size:12.5px;", "Enter equity, risk % and stop distance above zero."))
      tags$div(style = "color:#2c3e50; font-size:13px; line-height:1.7;",
        tags$div(sprintf("Money at risk: £%.2f", r$risk_gbp)),
        tags$div(sprintf("Stake per pip: £%.2f", r$stake_per_pip)),
        if (is.finite(r$lots)) tags$div(sprintf("Lots: %.2f", r$lots)))
    })

    output$expoOut <- renderUI({
      r <- u3ep_exposure(c(input$open1, input$open2), input$newRisk, input$cap)
      col <- if (r$ok) "#15803d" else "#b91c1c"
      tags$div(style = paste0("font-size:13px; line-height:1.7; color:", col, "; font-weight:600;"),
        tags$div(sprintf("Combined risk if taken: %.2f%% of equity (cap %.2f%%)", r$total, r$cap)),
        tags$div(if (r$ok) sprintf("Within the cap. Headroom %.2f%%.", r$headroom)
                 else sprintf("Over the cap by %.2f%%. Trade the strongest setup only, or reduce size.", -r$headroom)))
    })

    output$eiaTable <- renderTable(u3ep_eia_schedule(), striped = TRUE, bordered = TRUE, spacing = "s")
  })
}
