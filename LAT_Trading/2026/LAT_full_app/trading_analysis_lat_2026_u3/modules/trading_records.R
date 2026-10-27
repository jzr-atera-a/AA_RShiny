# modules/trading_records.R
# Trading Records: durable (BigQuery-backed) record-keeping for the 4-week trading period.
# Morning Sheet, trades (open / manage / partial exit / close), Blotter-style statistics,
# and the schema. (Plan text, reviews and statement import are deliberately not stored here.)
# Storage + maths live in R/utils_trading_records.R. All content is entered by the user.

tr_or <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
tr_uk_now <- function() format(Sys.time(), "%H:%M", tz = "Europe/London")
tr_blank_choice <- function(extra = character(0)) c(list(`(blank)` = ""), tr_asset_choices(extra))
tr_contract_choices <- c("Not stated" = "", "Daily funded bet (DFB / Undated)" = "DFB", "Futures (dated)" = "FUTURES")
tr_account_choices <- c("Not stated" = "", "Spread bet" = "SPREAD_BET", "CFD" = "CFD")
tr_device_choices <- c("Typed by hand" = "MANUAL", "Mobile app screenshot" = "mobile", "Desktop website screenshot" = "desktop")
tr_purpose_choices <- c("Choose..." = "", "Assessed trade (Unit 3 trading period)" = "ASSESSED", "Practice trade (not assessed)" = "PRACTICE")
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
        column(3, selectizeInput(ns(paste0("ml", i, "_inst")), tr_lab("Instrument"), tr_blank_choice(default_inst), selected = default_inst, options = list(create = TRUE))),
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
        "Your own morning sheets and trades, stored in BigQuery so they survive restarts, plus Blotter-style statistics worked out from what you record. Everything here is entered by you; the app never creates or suggests trades or results.")),
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
          column(3, textInput(ns("s_name"), tr_lab("Your name"), "Jose F Zubizarreta")),
          column(3, textInput(ns("s_id"), tr_lab("LAT student ID"), "D1005749")),
          column(3, num("s_balance", "Opening balance (GBP)", 10000, min = 0, step = 100)),
          column(3, dateInput(ns("s_start"), tr_lab("Period start"), as.Date("2026-10-12")))),
        fluidRow(
          column(3, dateInput(ns("s_end"), tr_lab("Period end"), as.Date("2026-11-06")))),
        tr_note("Your plan numbers (from your own Task 1 plan). They are used for the regime label (ADX) and for warnings before you save a trade."),
        fluidRow(
          column(3, num("s_adx_t", "ADX above = trend", 30)), column(3, num("s_adx_r", "ADX below = range", 20)),
          column(3, num("s_risk", "Risk per trade (% equity)", 1, step = 0.25)), column(3, num("s_cap", "Combined open-risk cap (%)", 2, step = 0.25))),
        fluidRow(column(3, num("s_minrrr", "Minimum reward : risk (optional)", NA, step = 0.25))),
        tr_h("Dropbox (finished sheets AND your screenshots are kept here)"),
        tr_note("Folder = your Dropbox folder as it appears on the computer running the app (for example C:/Users/you/Dropbox/LAT/Unit3): use this on your desktop. Dropbox path = the same folder seen from inside Dropbox (for example /LAT/Unit3), used through the Dropbox API: needed when the app runs on a Posit / Shiny server, and it lets any computer fetch the screenshots again. The API needs DROPBOX_APP_KEY + DROPBOX_APP_SECRET + DROPBOX_REFRESH_TOKEN (recommended, never expires) or DROPBOX_ACCESS_TOKEN (expires after about 4 hours) in the environment; tokens are never stored in BigQuery. Screenshots go to the Screenshots subfolder; the evidence table keeps only their path."),
        uiOutput(ns("dbx_fixed")),
        fluidRow(column(6, textInput(ns("s_dbx"), tr_lab("Dropbox folder on this computer (screenshots, Blotter, Answer Sheet)"), tr_lat_base_local())),
                 column(6, textInput(ns("s_dbxapi"), tr_lab("Dropbox path (API upload)"), tr_lat_base_api()))),
        uiOutput(ns("dbx_status")),
        actionButton(ns("dbx_test"), "Test Dropbox (write a small file and read it back)", icon = icon("vial")), uiOutput(ns("dbx_test_out")), tags$br(),
        tr_h("Automation"),
        fluidRow(column(6, checkboxInput(ns("s_autosave"), tr_lab("Save the Word + PDF sheets (and the Blotter) to Dropbox automatically after every change"), TRUE)),
                 column(6, checkboxInput(ns("s_autochart"), tr_lab("When a trade has no entry / post-exit chart, draw one from Yahoo prices (labelled as such)"), TRUE))),
        textInput(ns("s_plan_dur"), tr_lab("Your plan: expected trade duration (hours) for each chart period, used when a trade has none"), "", width = "100%",
                  placeholder = "for example: 15 Min = 4; 1 Hour = 8; 4 Hour = 24; Daily = 48"),
        tr_note("The durations are your plan's numbers: nothing is applied until you type and save them here."),
        actionButton(ns("saveSettings"), "Save settings", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        tr_h("Complete past records"),
        tr_note("For every trading day from the period start to today: fills empty Morning Sheet cells from Yahoo (overnight low/high, prices, Dow, Nikkei; a day with no sheet gets one), and gives trades without an expected duration the one from your plan. A sheet already in your Dropbox folder is kept (never replaced by the back-fill); a new one is saved there. Your own text is never touched."),
        actionButton(ns("backfill"), "Complete past Morning Sheets and trades", icon = icon("clock-rotate-left")), uiOutput(ns("backfill_out"))),

      # ------------------------------------------------------- 2 MORNING SHEET
      tabPanel("2. Morning Sheet",
        tr_note("Same sections as your Morning Sheet template. Pivot points and the regime label are worked out when you save, from the prior-day high/low/close and ADX you enter. Saving the same date again creates a new version; the latest is used."),
        fluidRow(
          column(3, dateInput(ns("ms_date"), tr_lab("Date"), tr_london_today())),
          column(3, selectInput(ns("ms_load"), tr_lab("Load a saved sheet"), choices = c("(none)"))),
          column(3, tags$div(style = "margin-top:25px;", actionButton(ns("ms_loadBtn"), "Load", icon = icon("folder-open"))))),
        tr_h("Where should the market levels and the economic calendar come from?"),
        radioButtons(ns("ms_src"), NULL, inline = TRUE, choices = c("I will upload screenshots" = "shots", "Let Claude find it online (web search)" = "web")),
        tr_note("Either way Claude only fills in the boxes below. Check every value (against the screenshot, or against a second source for web results) before saving: web figures are approximate and are not read from your IG platform."),
        conditionalPanel(sprintf("input['%s'] == 'shots'", ns("ms_src")),
          fluidRow(column(6, fileInput(ns("ms_shots"), tr_lab("IG market screenshots (watchlist or charts, one or several)"), multiple = TRUE, accept = c("image/png", "image/jpeg", "image/webp", ".png", ".jpg", ".jpeg", ".webp"))),
                   column(3, tags$div(style = "margin-top:25px;", actionButton(ns("ms_read"), "Read levels with Claude", icon = icon("wand-magic-sparkles"), class = "btn-primary", style = "color:#ffffff; font-weight:700;")))),
          fluidRow(column(5, fileInput(ns("ms_cal_img_o"), tr_lab("Calendar screenshot(s): YESTERDAY / overnight"), multiple = TRUE, accept = c("image/png", "image/jpeg", "image/webp", ".png", ".jpg", ".jpeg", ".webp"))),
                   column(5, fileInput(ns("ms_cal_img_t"), tr_lab("Calendar screenshot(s): TODAY"), multiple = TRUE, accept = c("image/png", "image/jpeg", "image/webp", ".png", ".jpg", ".jpeg", ".webp"))),
                   column(2, tags$div(style = "margin-top:25px;", actionButton(ns("ms_cal_read"), "Read calendar", icon = icon("table"), class = "btn-primary", style = "color:#ffffff; font-weight:700;")))),
          tr_note("The same calendar pictures are attached to the exported Morning Sheet automatically (you can still add others in the Exports tab).")),
        conditionalPanel(sprintf("input['%s'] == 'web'", ns("ms_src")),
          tr_note("Claude searches the web for the date chosen above: market levels at about 07:00 UK, short overnight headlines, yesterday's calendar (with actual, forecast and previous) and today's calendar. This can take one to three minutes."),
          fluidRow(column(4, actionButton(ns("ms_web_mk"), "Find market levels + headlines", icon = icon("globe"), class = "btn-primary", style = "color:#ffffff; font-weight:700;")),
                   column(4, actionButton(ns("ms_web_cal"), "Find yesterday + today calendar", icon = icon("globe"), class = "btn-primary", style = "color:#ffffff; font-weight:700;")))),
        uiOutput(ns("ms_web_src")),
        tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin:6px 0 10px 0;",
          tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:2px;", "Overnight Low / High from Yahoo Finance (works with either option above)"),
          tr_note("Hourly bars from 21:00 UK yesterday to now (to 07:30 UK for an earlier date) for every instrument row below, plus the Dow (last US close) and the Nikkei (today's Tokyo session) with their change. Current prices read from your IG screenshots are kept: Yahoo values are rescaled to IG points where IG quotes in points (Brent 10793.9 = $107.94). No Claude call, no cost."),
          fluidRow(column(4, actionButton(ns("ms_yahoo"), "Fill Low / High from Yahoo", icon = icon("chart-line"), class = "btn-primary", style = "color:#ffffff; font-weight:700;")),
                   column(8, checkboxInput(ns("ms_yahoo_over"), tr_lab("Also overwrite current prices, Time now and Dow / Nikkei (use when you have no IG screenshot)"), FALSE))),
          uiOutput(ns("ms_yahoo_out"))),
        uiOutput(ns("ms_read_out")),
        tr_h("Overnight markets"),
        fluidRow(column(3, num("ms_dow", "Dow Jones price")), column(3, num("ms_dowc", "Dow change (%)")),
                 column(3, num("ms_nik", "Nikkei price")), column(3, num("ms_nikc", "Nikkei change (%)"))),
        fluidRow(column(3, tags$span()), column(3, num("ms_dowp", "Dow change (points, optional)")),
                 column(3, tags$span()), column(3, num("ms_nikp", "Nikkei change (points, optional)"))),
        tr_note("The template's Change column: type it as your platform shows it. If you enter the percentage and the points, both go on the exported sheet."),
        tr_h("Forex (rows as in the Morning Sheet template)"),
        inst_row(1, "EURUSD"), inst_row(2, "USDJPY"), inst_row(3, "GBPUSD"), inst_row(4, "AUDUSD"),
        tr_h("Commodities (rows as in the template)"),
        inst_row(5, "WTI"), inst_row(6, "GOLD"),
        tr_h("Extra rows: any other market you trade (for example Brent, natural gas, an index)"),
        inst_row(7, ""), inst_row(8, ""),
        tr_h("News and calendar"),
        ta("ms_news", "Overnight news (your own notes)", 3),
        tr_h("Economic calendar: yesterday (overnight)"), DT::DTOutput(ns("cal_tbl_o")),
        ta("ms_cal_o", "Economic calendar from overnight (filled by the buttons above, or paste/type)", 3),
        tr_h("Economic calendar: today"), DT::DTOutput(ns("cal_tbl_t")),
        ta("ms_cal_t", "Today's data releases (filled by the buttons above, or paste/type)", 3),
        ta("ms_win", "Releases inside your trading window", 2),
        tr_h("Plan for the day"),
        ta("ms_regime", "Regime read per instrument", 2), ta("ms_setups", "Set-ups you will look for", 2),
        fluidRow(column(4, num("ms_risk", "Combined open risk now (% of equity)", 0, min = 0, step = 0.25)),
                 column(8, ta("ms_expo", "Exposure note (correlated markets)", 2))),
        checkboxInput(ns("ms_stand"), tr_lab("Standing aside today"), FALSE),
        conditionalPanel(sprintf("input['%s']", ns("ms_stand")), ta("ms_stand_why", "Reason for standing aside", 2)),
        actionButton(ns("ms_save"), "Save morning sheet", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;"),
        actionButton(ns("ms_complete"), "Fill every empty cell and save", icon = icon("wand-magic-sparkles"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
        checkboxInput(ns("ms_web_fill"), tr_lab("When the news box or the calendar is empty, let Claude find them online (with sources; needs the Claude key)"), TRUE),
        uiOutput(ns("ms_complete_out")),
        tags$hr(), tr_h("Saved sheets"), DT::DTOutput(ns("ms_table"))),

      # ------------------------------------------------------------- 3 TRADES
      tabPanel("3. Trades",
        tr_h("A. Open a trade"),
        tr_note("Fill in at the time you enter, as in the top half of your Trade Sheet. Times are UK time. Sizing is your stake per pip; pip size is the price move that equals one pip on YOUR platform (defaults are only a guide)."),
        fluidRow(
          column(3, selectizeInput(ns("t_asset"), tr_lab("Asset"), tr_asset_choices(), selected = "BRENT", options = list(create = TRUE))),
          column(3, selectInput(ns("t_strategy"), tr_lab("Strategy"), tr_strategies)),
          column(3, radioButtons(ns("t_dir"), tr_lab("Direction"), c("Buy" = "B", "Sell" = "S"), inline = TRUE)),
          column(3, textInput(ns("t_chart"), tr_lab("Chart period"), "15 Min"))),
        fluidRow(
          column(3, dateInput(ns("t_date"), tr_lab("Entry date"), tr_london_today())),
          column(3, textInput(ns("t_time"), tr_lab("Entry time (UK, HH:MM)"), tr_uk_now()), checkboxInput(ns("t_time_est"), tr_lab("Time is an estimate (not read from IG)"), FALSE)),
          column(3, num("t_dur", "Expected duration (hours; empty = from your plan)", NA, min = 0)),
          column(3, selectInput(ns("t_basis"), tr_lab("Prices are quoted as"), tr_price_bases))),
        fluidRow(
          column(3, num("t_pip", "Pip size (price units)", 1, min = 0)),
          column(3, num("t_stake", "Stake per pip (GBP): the size in \u00a3 per point", 2, min = 0)),
          column(3, selectInput(ns("t_purpose"), tr_lab("Assessed or practice?"), tr_purpose_choices)),
          column(3, tags$div(style = "margin-top:22px;", uiOutput(ns("t_class_note"))))),
        fluidRow(
          column(3, num("t_entry", "Entry price")), column(3, num("t_stop", "Stop loss")), column(3, num("t_target", "Target"))),
        tags$details(open = NA, style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px; color:#2c3e50;",
          tags$summary(style = "font-weight:700; cursor:pointer;", "Platform details (filled from screenshots; check or type them)"),
          tags$div(style = "margin-top:8px;",
            fluidRow(column(3, selectInput(ns("t_class"), tr_lab("Asset class"), tr_asset_classes)), column(3, textInput(ns("t_market"), tr_lab("Market"), "")),
                     column(3, textInput(ns("t_rawname"), tr_lab("Market name on the platform"), "")), column(3, textInput(ns("t_dealref"), tr_lab("Deal reference"), ""))),
            fluidRow(column(3, selectInput(ns("t_contract"), tr_lab("Contract type"), tr_contract_choices)), column(3, selectInput(ns("t_acct"), tr_lab("Account type"), tr_account_choices, selected = "SPREAD_BET")),
                     column(3, selectInput(ns("t_device"), tr_lab("Where the entry came from"), tr_device_choices)), column(3, checkboxInput(ns("t_demo"), tr_lab("Demo account"), TRUE))),
            fluidRow(column(3, textInput(ns("t_unit"), tr_lab("Size unit"), "GBP per point")), column(3, num("t_spread", "Spread (points)")),
                     column(3, num("t_margin", "Margin (GBP)")), column(3, num("t_notional", "Notional value (GBP)"))),
            fluidRow(column(3, num("t_costs", "Indicative costs (GBP)"))),
            tr_note("Optional points-system scores for the Blotter (your own marks, only if your tutor's system uses them):"),
            fluidRow(column(2, num("t_s1", "Patterns (10)", NA, min = 0, max = 10)), column(2, num("t_s2", "S/R (10)", NA, min = 0, max = 10)), column(2, num("t_s3", "Candles (3)", NA, min = 0, max = 3)),
                     column(2, num("t_s4", "RSI (3)", NA, min = 0, max = 3)), column(2, num("t_s5", "Fibs (3)", NA, min = 0, max = 3))))),
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

        tr_h("B. Manage an open trade, or edit any trade (open or closed)"),
        selectInput(ns("m_trade"), tr_lab("Trade (open trades; closed trades too when you choose Edit)"), choices = c("(no open trades)" = "")),
        uiOutput(ns("m_summary")),
        radioButtons(ns("m_action"), tr_lab("What happened?"), inline = TRUE,
                     c("Edit trade" = "edit", "Moved stop" = "stop", "Partial exit" = "partial", "Closed" = "close", "Cancelled (never filled)" = "cancel"), selected = "stop"),
        conditionalPanel(sprintf("input['%s'] != 'edit'", ns("m_action")),
          fluidRow(column(3, dateInput(ns("m_date"), tr_lab("Date"), tr_london_today())),
                   column(3, textInput(ns("m_time"), tr_lab("Time (UK, HH:MM)"), tr_uk_now())))),
        conditionalPanel(sprintf("input['%s'] == 'edit'", ns("m_action")),
          tr_note("Correct or complete any trade, open or closed: entry time, prices, size, chart period, purpose, platform details, your own text and (closed trades) the exit. Risk, reward, RRR, pips, P/L, Real R and duration are worked out again. Saving adds a new version of the trade; nothing is overwritten."),
          fluidRow(column(3, dateInput(ns("e_date"), tr_lab("Entry date"), tr_london_today())), column(3, textInput(ns("e_time"), tr_lab("Entry time (UK, HH:MM)"), ""), checkboxInput(ns("e_time_est"), tr_lab("Time is an estimate"), FALSE)),
                   column(3, selectInput(ns("e_purpose"), tr_lab("Assessed or practice?"), tr_purpose_choices)), column(3, textInput(ns("e_dealref"), tr_lab("Deal reference"), ""))),
          fluidRow(column(3, selectInput(ns("e_contract"), tr_lab("Contract type"), tr_contract_choices)), column(3, num("e_spread", "Spread (points)")),
                   column(3, num("e_margin", "Margin (GBP)")), column(3, num("e_notional", "Notional value (GBP)"))),
          fluidRow(column(3, num("e_costs", "Indicative costs (GBP)")), column(3, textInput(ns("e_chart"), tr_lab("Chart period"), "")), column(3, num("e_dur", "Expected duration (hours)", NA, min = 0))),
          fluidRow(column(3, num("e_entry", "Entry price")), column(3, num("e_stop", "Initial stop")), column(3, num("e_target", "Target")), column(3, num("e_stake", "Stake per pip (GBP)"))),
          tags$details(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px; color:#2c3e50;",
            tags$summary(style = "font-weight:700; cursor:pointer;", "Exit details (closed trades only)"),
            fluidRow(column(3, dateInput(ns("e_xdate"), tr_lab("Exit date"), tr_london_today())), column(3, textInput(ns("e_xtime"), tr_lab("Exit time (UK, HH:MM)"), "")),
                     column(3, num("e_xprice", "Exit price")), column(3, num("e_xpnl", "Net P/L shown by the platform (GBP)"))),
            fluidRow(column(3, selectInput(ns("e_xcode"), tr_lab("Exit code"), c("S1 hit initial stop" = "S1", "S2+ hit trailing stop" = "S2+", "ME manual exit" = "ME", "T target hit" = "T")))),
            fluidRow(column(6, ta("e_why", "Reason for exit", 2)), column(6, ta("e_lessons", "Lessons learned", 2)))),
          ta("e_fund", "Set-up (fundamental)", 2), ta("e_tech", "Set-up (technical)", 3),
          fluidRow(column(6, ta("e_trigger", "Trigger", 2)), column(6, ta("e_exec", "Execution", 2))),
          fluidRow(column(6, ta("e_stopwhy", "Reason for stop-loss placement", 2)), column(6, ta("e_tgtwhy", "Reason for target placement", 2)))),
        conditionalPanel(sprintf("input['%s'] == 'stop'", ns("m_action")),
          fluidRow(column(3, num("m_newstop", "New stop price")),
                   column(3, radioButtons(ns("m_permitted"), tr_lab("Allowed by my written management rule?"), c("Yes" = "Y", "No" = "N"), inline = TRUE))),
          ta("m_stopwhy", "Why (with the chart you saved)", 2)),
        conditionalPanel(sprintf("input['%s'] == 'partial' || input['%s'] == 'close'", ns("m_action"), ns("m_action")),
          fluidRow(column(3, conditionalPanel(sprintf("input['%s'] == 'partial'", ns("m_action")), num("m_pstake", "Stake per pip closed (GBP)"))),
                   column(3, num("m_exit", "Exit price")),
                   column(3, num("m_pnl", "Net P/L shown by the platform (GBP, optional)")),
                   column(3, radioButtons(ns("m_code"), tr_lab("Exit code"), c("S1 hit initial stop" = "S1", "S2+ hit trailing stop" = "S2+", "ME manual exit" = "ME", "T target hit" = "T")))),
          conditionalPanel(sprintf("input['%s'] == 'ME'", ns("m_code")),
            radioButtons(ns("m_post"), tr_lab("After your manual exit, did the market reach your stop or your target? (from your post-exit chart)"), inline = TRUE,
                         c("Not checked / neither" = "", "It then hit my stop" = "stop", "It then hit my target" = "target"))),
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
        fluidRow(column(3, selectInput(ns("st_week"), tr_lab("Show"), c("Whole period" = "all", "Week 1" = "1", "Week 2" = "2", "Week 3" = "3", "Week 4" = "4"))),
                 column(3, selectInput(ns("st_scope"), tr_lab("Trades"), c("Assessed trades only" = "ASSESSED", "Practice trades only" = "PRACTICE", "All trades" = "ALL")))),
        uiOutput(ns("st_tiles")),
        uiOutput(ns("st_caution")),
        fluidRow(column(6, plotly::plotlyOutput(ns("st_equity"), height = "300px")), column(6, plotly::plotlyOutput(ns("st_r"), height = "300px"))),
        fluidRow(column(6, tr_h("By strategy"), tableOutput(ns("st_strat"))), column(6, tr_h("By asset"), tableOutput(ns("st_asset")))),
        fluidRow(column(4, tr_h("By exit code"), tableOutput(ns("st_exit"))), column(4, tr_h("By weekday (entry)"), tableOutput(ns("st_wd"))),
                 column(4, tr_h("By entry time (UK)"), tableOutput(ns("st_hr")))),
        fluidRow(column(6, tr_h("Mood at entry vs Real R"), tableOutput(ns("st_mood")))),
        tr_note("Real R = net P/L divided by the money risked at the initial stop (negative for a loss). Planned RRR = reward pips / risk pips at entry. Sharpe and Sortino here are per trade, not annualised, and are not reliable on a small number of trades; the trade-by-trade review and adherence matter more.")),

      # ---------------------------------------------------------- 5 EXPORTS
      tabPanel("5. Exports (LAT files)",
        tr_note("These files are filled from the records you saved, in the layout of your LAT documents. Nothing is written for you: text fields are exactly what you typed, and empty stays empty. Check your course rules about AI-assisted record keeping and describe it honestly in your submission."),
        fluidRow(column(4, selectInput(ns("ex_scope"), tr_lab("Trades to include"), c("Assessed trades only" = "ASSESSED", "Practice trades only" = "PRACTICE", "All trades" = "ALL")))),
        tr_h("Trade Blotter (Excel)"),
        tr_note("Same columns A to AK as the 'Trade Blotter' sheet. Copy the input columns into your LAT workbook, or use this file to check your own figures."),
        downloadButton(ns("dlBlotter"), "Download Blotter (.xlsx)"),
        tags$hr(), tr_h("Individual Trade Sheet (Word)"),
        selectInput(ns("ex_trade"), tr_lab("Trade"), choices = c("(no trades yet)" = "")),
        tr_note("Pictures are saved ONCE with the trade (Dropbox, path kept in the evidence table) and placed on the sheet every time you export, in this order: entry charts (each with its caption, for example 4 Hour, 1 Hour, 15 Min as in the LAT sample), the IG screenshots you linked in Order Evidence, each in-trade action followed by its own chart, the exit chart, then 'Post Exit'. Crop out account names and numbers."),
        tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px;",
          fluidRow(column(3, selectInput(ns("pic_slot"), tr_lab("Where on the sheet"), tr_picture_slots)),
                   column(3, selectizeInput(ns("pic_caption"), tr_lab("Caption (timeframe)"), c("(none)" = "", tr_picture_captions), options = list(create = TRUE))),
                   column(3, conditionalPanel(sprintf("input['%s'] == 'intrade'", ns("pic_slot")), selectInput(ns("pic_event"), tr_lab("For which action"), c("(general)" = "")))),
                   column(3, fileInput(ns("pic_files"), tr_lab("Picture(s)"), multiple = TRUE, accept = c("image/png", "image/jpeg", ".png", ".jpg", ".jpeg")))),
          actionButton(ns("pic_add"), "Save picture(s) to this trade", icon = icon("image"), class = "btn-primary", style = "color:#ffffff; font-weight:700;"),
          tags$div(style = "margin-top:8px;", DT::DTOutput(ns("pic_table"))),
          actionButton(ns("pic_remove"), "Remove selected picture(s)", icon = icon("trash"))),
        uiOutput(ns("trade_gaps")),
        tags$details(open = NA, style = "background:#eef6ff; border:1px solid #bfdbfe; border-radius:8px; padding:8px 12px; margin-bottom:10px; color:#1e3a5f;",
          tags$summary(style = "font-weight:800; cursor:pointer;", "Complete this sheet: the boxes only you can fill (saved as a new version of the trade)"),
          tr_note("Write in your own words: Unit 3 is assessed on your own judgement and is checked for AI-written text. The facts on the right come from your saved records (numbers only) to help you check what you write; do not paste them as your answer."),
          fluidRow(
            column(7,
              fluidRow(column(6, textInput(ns("x_chart"), tr_lab("Chart Period"), "")), column(6, numericInput(ns("x_dur"), tr_lab("Expected Trade Duration (hours)"), NA, min = 0))),
              textAreaInput(ns("x_fund"), tr_lab("Set-up (fundamental)"), rows = 3, width = "100%"), textAreaInput(ns("x_tech"), tr_lab("Set-up (technical)"), rows = 3, width = "100%"),
              fluidRow(column(6, textAreaInput(ns("x_trigger"), tr_lab("Trigger"), rows = 2, width = "100%")), column(6, textAreaInput(ns("x_exec"), tr_lab("Execution"), rows = 2, width = "100%"))),
              fluidRow(column(6, textAreaInput(ns("x_stopwhy"), tr_lab("Reason for Stop Loss placement"), rows = 2, width = "100%")), column(6, textAreaInput(ns("x_tgtwhy"), tr_lab("Reason for Target Limit placement"), rows = 2, width = "100%"))),
              fluidRow(column(6, textAreaInput(ns("x_why"), tr_lab("Reason for Exit (after the exit code)"), rows = 2, width = "100%")), column(6, textAreaInput(ns("x_lessons"), tr_lab("Lessons learned"), rows = 3, width = "100%"))),
              actionButton(ns("x_save"), "Save my text to this trade", icon = icon("floppy-disk"), class = "btn-success", style = "color:#ffffff; font-weight:700;")),
            column(5, uiOutput(ns("x_facts"))))),
        downloadButton(ns("dlTradeSheet"), "Download Trade Sheet (.docx)"), downloadButton(ns("dlTradeSheetPdf"), "Download Trade Sheet (PDF)"),
        actionButton(ns("sv_trade"), "Save Word + PDF to Dropbox", icon = icon("dropbox")),
        tags$hr(), tr_h("Morning Sheet (Word)"),
        selectInput(ns("ex_sheet"), tr_lab("Saved sheet"), choices = c("(no sheets yet)" = "")),
        tr_note("Filled into your LAT Morning Sheet template. The IG calendar screenshots you read on the Morning Sheet tab were saved with that date and are placed automatically under 'Economic Calendar from overnight' and 'Economic Calendar for today'. Pictures added here replace them for this export (and are saved too)."),
        fluidRow(column(6, fileInput(ns("cal_o"), tr_lab("Overnight calendar / news pictures"), multiple = TRUE, accept = c("image/png", "image/jpeg"))),
                 column(6, fileInput(ns("cal_t"), tr_lab("Today's calendar pictures"), multiple = TRUE, accept = c("image/png", "image/jpeg")))),
        uiOutput(ns("morning_gaps")),
        downloadButton(ns("dlMorning"), "Download Morning Sheet (.docx)"), downloadButton(ns("dlMorningPdf"), "Download Morning Sheet (PDF)"),
        actionButton(ns("sv_morning"), "Save Word + PDF to Dropbox", icon = icon("dropbox")),
        tr_note("PDF files are made from the Word file with LibreOffice, which must be installed on the computer running the app. Without it you still get the Word file; open it and use Save as PDF. Files are named like Morning_Sheet_20-10-2026 and Individual_Trade_Sheet_Brent_19-10-2026, and saved again with the same name when you re-export."),
        uiOutput(ns("sv_out")),
        tags$hr(), tr_h("Statistics (Excel)"),
        tr_note("Summary, by asset, strategy, exit code, weekday, entry time and mood, the equity series, the trade list and the deviations you wrote. Use it for the numbers in Tasks 2 and 3; the evaluation is yours to write."),
        downloadButton(ns("dlStatsX"), "Download statistics (.xlsx)")),

      # ---------------------------------------------------------- 6 SCHEMA
      tabPanel("6. Schema & SQL",
        tr_note("Six append-only tables (settings, morning sheets, morning levels, trades, trade events and the screenshot evidence log) in the BigQuery dataset set under API Configuration. Each also gets a `_current` view that returns the latest row per key. Editing a record writes a new row; nothing is updated or deleted."),
        uiOutput(ns("schemaTables")), tr_h("DDL"), downloadButton(ns("dlDDL"), "Download SQL (.sql)"), tags$br(), tags$br(),
        verbatimTextOutput(ns("ddlText")))
    )
  )
}

# =============================================================================== SERVER
trading_records_server <- function(id, api_manager = NULL, store = NULL, quiet = FALSE, bus = NULL, vision_fn = NULL, text_fn = NULL,
                                   pictures = NULL, yahoo_fn = NULL, image_store_fn = NULL) {
  moduleServer(id, function(input, output, session) {
    if (is.null(store)) store <- tr_make_store(tr_bq_backend(api_manager))
    refresh <- reactiveVal(0); bump <- function() refresh(isolate(refresh()) + 1)
    msg <- function(text, type = "message") if (!quiet) showNotification(text, type = type, duration = 6)
    report <- function(res, what) {
      if (identical(res, "bigquery")) msg(paste(what, "saved to BigQuery."))
      else if (identical(res, "pending")) msg(paste(what, "saved in this session only (BigQuery not connected). Sync later."), "warning")
      else msg(paste(what, "- BigQuery write failed, kept in this session:", res), "error")
    }

    # The UI is built once when the app starts, so its default dates and clocks go stale if the app stays open:
    # refresh them for every new session.
    local({
      today <- tr_london_today(); now <- tr_uk_now()
      for (i in 1:8) updateTextInput(session, paste0("ml", i, "_time"), value = now)
      for (d in c("ms_date", "t_date", "m_date", "e_date", "e_xdate")) updateDateInput(session, d, value = today)
      for (t in c("t_time", "m_time")) updateTextInput(session, t, value = now)
    })

    # ---- order-evidence integration (screenshots sent from the Order Evidence tab) ------------
    ev_open <- reactiveVal(character(0)); ev_close <- reactiveVal(NULL)
    edit_pending <- reactiveVal(NULL); act_fix <- reactiveVal(NULL)   # Activity screen -> open that trade in Edit with the time it shows
    link_evidence <- function(ev_id, trade_id) {
      if (is.null(ev_id) || !nzchar(ev_id)) return(invisible())
      ev <- tr_read_current(store, "evidence"); r <- ev[ev$evidence_id == ev_id, , drop = FALSE]
      if (!nrow(r)) return(invisible())
      r <- r[1, ]; r$status <- "LINKED"; r$trade_id <- trade_id; r$record_version <- r$record_version + 1L
      store$write("evidence", r)
    }
    link_all <- function(ids, trade_id) for (i in ids) link_evidence(i, trade_id)
    if (!is.null(bus)) observeEvent(bus$ts, {
      v <- bus$values; req(v)
      if (identical(bus$kind, "open") && identical(tr_or(v$screen, ""), "activity") && !is.na(tr_or(v$time, NA))) {
        # IG History > Activity shows when a position was opened: use it to correct the time of a trade already saved
        al <- trades_df(); al <- al[al$status %in% c("OPEN", "CLOSED") & is.na(al$parent_trade_id), , drop = FALSE]
        tid <- tr_match_open_trade(al, v)
        if (!is.na(tid)) {
          edit_pending(tid); updateRadioButtons(session, "m_action", selected = "edit"); updateSelectInput(session, "m_trade", selected = tid)
          act_fix(list(date = v$date, time = v$time)); link_all(bus$evidence_id, tid)
          updateTabsetPanel(session, "tabs", selected = "3. Trades")
          msg(sprintf("Activity screen: opening time %s for %s. The trade is open in 'Edit trade' with this time: check it and press Save.", v$time, tid))
          return()
        }
      }
      if (identical(bus$kind, "open")) {
        ev_open(unique(c(ev_open(), bus$evidence_id)))
        if (!is.na(tr_or(v$asset, NA))) updateSelectizeInput(session, "t_asset", choices = tr_asset_choices(v$asset), selected = v$asset, options = list(create = TRUE))
        fill_txt <- function(id, val) if (!is.null(val) && length(val) == 1 && !is.na(val) && nzchar(as.character(val))) updateTextInput(session, id, value = as.character(val))
        fill_sel <- function(id, val) if (!is.null(val) && length(val) == 1 && !is.na(val) && nzchar(as.character(val))) updateSelectInput(session, id, selected = as.character(val))
        fill_num <- function(id, val) if (is.finite(tr_num(val))) updateNumericInput(session, id, value = tr_num(val))
        if (isTRUE(v$per_point)) updateSelectInput(session, "t_basis", selected = "ig")
        fill_sel("t_contract", v$contract); fill_sel("t_acct", v$account_type); fill_sel("t_device", tr_or(v$source, NA)); fill_sel("t_class", v$asset_class)
        fill_txt("t_market", v$market); fill_txt("t_rawname", v$asset_raw); fill_txt("t_dealref", v$deal_ref)
        if (isTRUE(v$per_point)) fill_txt("t_unit", "GBP per point") else fill_txt("t_unit", v$size_unit)
        if (!is.na(tr_or(v$demo, NA))) updateCheckboxInput(session, "t_demo", value = isTRUE(v$demo))
        fill_num("t_spread", v$spread); fill_num("t_margin", v$margin); fill_num("t_notional", v$notional); fill_num("t_costs", v$costs)
        if (!is.na(tr_or(v$direction, NA))) updateRadioButtons(session, "t_dir", selected = v$direction)
        if (!is.na(tr_or(v$date, NA))) updateDateInput(session, "t_date", value = as.Date(v$date))
        if (!is.na(tr_or(v$time, NA))) { updateTextInput(session, "t_time", value = v$time); updateCheckboxInput(session, "t_time_est", value = FALSE) }
        else updateTextInput(session, "t_time", value = "")   # no clock on the screen: left EMPTY (never "now"); read IG History > Activity or type it
        if (is.finite(tr_num(v$entry))) updateNumericInput(session, "t_entry", value = v$entry)
        if (is.finite(tr_num(v$stop))) updateNumericInput(session, "t_stop", value = v$stop)
        if (is.finite(tr_num(v$limit))) updateNumericInput(session, "t_target", value = v$limit)
        if (is.finite(tr_num(v$size))) updateNumericInput(session, "t_stake", value = v$size)
        updateTabsetPanel(session, "tabs", selected = "3. Trades")
        msg(paste0("Entry details filled in from the screenshot", if (is.na(tr_or(v$time, NA))) ". The screen shows no time of day, so Entry time is EMPTY: read IG History > Activity in Order Evidence, or type it (tick 'Time is an estimate' if you are not sure)" else "", ". Check them, then write your own set-up, trigger and reasons before saving."), if (is.na(tr_or(v$time, NA))) "warning" else "message")
      } else if (identical(bus$kind, "close")) {
        ev_close(bus$evidence_id)
        tid <- tr_match_open_trade(open_trades(), v)   # asset + direction + opening price + size (deal ref when shown)
        updateRadioButtons(session, "m_action", selected = "close")
        if (!is.na(tid)) updateSelectInput(session, "m_trade", selected = tid)
        else msg("No open trade matches this closed row (market, opening price and size). Choose the trade yourself.", "warning")
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
    settings_df <- rd("settings"); sheets_df <- rd("morning_sheets")
    levels_df <- rd("morning_levels"); trades_df <- rd("trades"); events_df <- rd("trade_events"); evidence_df <- rd("evidence")

    # ---- picture store (Dropbox folder on this computer and/or the Dropbox API; session cache always) -------------
    dbx_local <- reactive(tr_or(input$s_dbx, tr_or(sv()$dropbox_dir, tr_lat_base_local())))
    dbx_api <- reactive(tr_or(input$s_dbxapi, tr_or(sv()$dropbox_api_path, tr_lat_base_api())))
    autosave_on <- reactive(if (is.null(input$s_autosave)) !identical(sv()$autosave, "FALSE") else isTRUE(input$s_autosave))
    autochart_on <- reactive(if (is.null(input$s_autochart)) !identical(sv()$autochart, "FALSE") else isTRUE(input$s_autochart))
    plan_txt <- reactive(tr_or(sv()$plan_durations, ""))   # only what you SAVED counts as your plan
    output$dbx_fixed <- renderUI({ m <- tr_sheet_targets("morning"); t <- tr_sheet_targets("trade")
      tags$div(style = "font-size:12.5px; background:#ecfdf5; border:1px solid #a7f3d0; border-radius:8px; padding:8px 12px; margin-bottom:10px; color:#065f46;",
        tags$b("The sheets are always saved here (fixed):"),
        tags$div("Morning Sheets: ", tags$code(if (nzchar(m$local)) m$local else paste0("(no Dropbox at ", tr_lat_root_local(), " on this computer)")), " and Dropbox ", tags$code(m$api)),
        tags$div("Individual Trade Sheets: ", tags$code(if (nzchar(t$local)) t$local else paste0("(no Dropbox at ", tr_lat_root_local(), " on this computer)")), " and Dropbox ", tags$code(t$api)),
        tags$div(style = "color:#64748b;", "A file that is replaced is first copied to the '_previous versions' subfolder. The API path needs a 'Full Dropbox' app token.")) })
    session_cache <- file.path(tempdir(), "lat_pictures")
    pic_store <- reactive({ loc <- dbx_local(); api <- dbx_api(); f <- if (is.null(image_store_fn)) tr_image_store else image_store_fn; f(loc, api, cache = session_cache) })
    observe({ st <- pic_store(); if (!is.null(pictures)) pictures$store <- st })   # shared with Order Evidence
    output$dbx_status <- renderUI({
      st <- pic_store(); srv <- tr_is_server(); tok <- nzchar(tryCatch(tr_dropbox_token(), error = function(e) ""))
      line <- function(ok, txt) tags$div(style = paste0("color:", if (ok) "#15803d" else "#b45309", ";"), paste0(if (ok) "✓ " else "! ", txt))
      tags$div(style = "font-size:12.5px; background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px;",
        line(TRUE, if (srv) "Running on a server (Posit / Shiny Server): the Dropbox API path is used; a folder on this machine is ignored." else "Running on this computer (desktop)."),
        if (!srv) line(nzchar(st$local()), if (nzchar(st$local())) paste("Dropbox folder:", st$local()) else "No Dropbox folder set."),
        line(nzchar(st$api()) && tok, if (!nzchar(st$api())) "No Dropbox API path set." else if (tok) paste("Dropbox API path:", st$api(), "(token found)") else paste("Dropbox API path:", st$api(), "- but no token in the environment (DROPBOX_REFRESH_TOKEN + APP_KEY + APP_SECRET, or DROPBOX_ACCESS_TOKEN)")),
        if (!st$durable()) line(FALSE, "Screenshots are kept for this session only until a Dropbox folder or API path works."))
    })

    sv <- reactive({ s <- settings_df(); setNames(as.list(s$setting_value), s$setting_key) })
    opening <- reactive(tr_or(tr_num(sv()$opening_balance), 10000))
    p_start <- reactive(tryCatch(as.Date(tr_or(sv()$period_start, "2026-10-12")), error = function(e) as.Date("2026-10-12")))
    # plan numbers come from the Setup tab (saved in trading_settings)
    adx_cfg <- reactive({ c(tr_or(tr_num(sv()$adx_trend_min), 30), tr_or(tr_num(sv()$adx_range_max), 20)) })
    limits <- reactive(list(risk_pct = tr_num(sv()$risk_pct), cap_pct = tr_num(sv()$combined_cap_pct), min_rrr = tr_num(sv()$min_rrr)))
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
      df <- data.frame(setting_key = c("trader_name", "student_id", "opening_balance", "period_start", "period_end", "adx_trend_min", "adx_range_max", "risk_pct", "combined_cap_pct", "min_rrr", "dropbox_dir", "dropbox_api_path", "autosave", "autochart", "plan_durations"),
                       setting_value = c(as.character(tr_or(input$s_name, NA)), as.character(tr_or(input$s_id, NA)), as.character(tr_or(input$s_balance, NA)), as.character(tr_or(input$s_start, NA)), as.character(tr_or(input$s_end, NA)),
                                         as.character(tr_or(input$s_adx_t, NA)), as.character(tr_or(input$s_adx_r, NA)), as.character(tr_or(input$s_risk, NA)),
                                         as.character(tr_or(input$s_cap, NA)), as.character(tr_or(input$s_minrrr, NA)), as.character(tr_or(input$s_dbx, NA)), as.character(tr_or(input$s_dbxapi, NA)),
                                         as.character(isTRUE(input$s_autosave)), as.character(isTRUE(input$s_autochart)), as.character(tr_or(input$s_plan_dur, NA))),
                       stringsAsFactors = FALSE)
      if (is.null(input$s_autosave)) df <- df[df$setting_key != "autosave", , drop = FALSE]
      if (is.null(input$s_autochart)) df <- df[df$setting_key != "autochart", , drop = FALSE]
      df <- df[!is.na(df$setting_value) & nzchar(df$setting_value) & df$setting_value != "NA", , drop = FALSE]
      report(store$write("settings", df), "Settings"); bump()
    })
    observeEvent(settings_df(), {   # restore saved settings into the form
      s <- sv()
      if (!is.null(s$trader_name)) updateTextInput(session, "s_name", value = s$trader_name)
      if (!is.null(s$student_id)) updateTextInput(session, "s_id", value = s$student_id)
      if (!is.null(s$dropbox_dir)) updateTextInput(session, "s_dbx", value = s$dropbox_dir)
      if (!is.null(s$dropbox_api_path)) updateTextInput(session, "s_dbxapi", value = s$dropbox_api_path)
      if (!is.null(s$autosave)) updateCheckboxInput(session, "s_autosave", value = identical(s$autosave, "TRUE"))
      if (!is.null(s$autochart)) updateCheckboxInput(session, "s_autochart", value = identical(s$autochart, "TRUE"))
      if (!is.null(s$plan_durations)) updateTextInput(session, "s_plan_dur", value = s$plan_durations)
      if (!is.null(s$opening_balance)) updateNumericInput(session, "s_balance", value = as.numeric(s$opening_balance))
      if (!is.null(s$period_start)) updateDateInput(session, "s_start", value = as.Date(s$period_start))
      if (!is.null(s$period_end)) updateDateInput(session, "s_end", value = as.Date(s$period_end))
      for (p in list(c("adx_trend_min", "s_adx_t"), c("adx_range_max", "s_adx_r"), c("risk_pct", "s_risk"), c("combined_cap_pct", "s_cap"), c("min_rrr", "s_minrrr")))
        if (!is.null(s[[p[1]]]) && is.finite(tr_num(s[[p[1]]]))) updateNumericInput(session, p[2], value = tr_num(s[[p[1]]]))
    }, once = TRUE, ignoreInit = TRUE)

    # ---------------------------------------------------------------- morning sheet
    observe({
      s <- sheets_df(); ch <- if (nrow(s)) format(sort(s$sheet_date, decreasing = TRUE)) else character(0)
      updateSelectInput(session, "ms_load", choices = c("(none)", ch))
    })
    # the Morning Sheet in the form -> list(hdr, lv) (rows left completely empty are not kept)
    ms_collect <- function() {
      d <- as.Date(input$ms_date); sid <- paste0("MS_", format(d))
      prev <- sheets_df(); rv <- if (sid %in% prev$sheet_id) prev$record_version[prev$sheet_id == sid][1] + 1L else 1L
      thr <- adx_cfg(); lv <- list()
      for (i in 1:8) {
        inst <- toupper(trimws(tr_or(input[[paste0("ml", i, "_inst")]], "")))
        if (!nzchar(inst)) next
        vals <- vapply(c("_low", "_high", "_cur", "_adx", "_ph", "_pl", "_pc"), function(z) tr_num(input[[paste0("ml", i, z)]]), 0)
        if (all(is.na(vals))) next   # a template row you left empty is not saved
        h <- tr_num(input[[paste0("ml", i, "_ph")]]); l <- tr_num(input[[paste0("ml", i, "_pl")]]); c_ <- tr_num(input[[paste0("ml", i, "_pc")]])
        pv <- tr_pivots(h, l, c_); adx <- tr_num(input[[paste0("ml", i, "_adx")]])
        lv[[length(lv) + 1]] <- data.frame(level_id = paste0(sid, "_", inst), sheet_id = sid, sheet_date = d, instrument = inst,
          overnight_low = tr_num(input[[paste0("ml", i, "_low")]]), overnight_high = tr_num(input[[paste0("ml", i, "_high")]]),
          current_price = tr_num(input[[paste0("ml", i, "_cur")]]), time_now_uk = tr_or(input[[paste0("ml", i, "_time")]], NA_character_), adx14 = adx,
          regime_label = tr_regime(adx, thr[1], thr[2]), prior_high = h, prior_low = l, prior_close = c_,
          pivot_pp = pv$pp, pivot_r1 = pv$r1, pivot_s1 = pv$s1, pivot_r2 = pv$r2, pivot_s2 = pv$s2, pivot_r3 = pv$r3, pivot_s3 = pv$s3, stringsAsFactors = FALSE)
      }
      hdr <- data.frame(sheet_id = sid, record_version = rv, sheet_date = d, week_no = tr_week_no(d, p_start()),
        dow_price = tr_num(input$ms_dow), dow_change_pct = tr_num(input$ms_dowc), nikkei_price = tr_num(input$ms_nik), nikkei_change_pct = tr_num(input$ms_nikc),
        dow_change_pts = tr_num(input$ms_dowp), nikkei_change_pts = tr_num(input$ms_nikp), trader_name = tr_blank_na(input$s_name),
        overnight_news = tr_blank_na(input$ms_news), overnight_calendar = tr_blank_na(input$ms_cal_o), todays_releases = tr_blank_na(input$ms_cal_t),
        releases_in_window = tr_blank_na(input$ms_win), regime_summary = tr_blank_na(input$ms_regime), planned_setups = tr_blank_na(input$ms_setups),
        exposure_note = tr_blank_na(input$ms_expo), combined_open_risk_pct = tr_num(input$ms_risk), stand_aside = isTRUE(input$ms_stand),
        stand_aside_reason = tr_blank_na(input$ms_stand_why), stringsAsFactors = FALSE)
      list(hdr = hdr, lv = if (length(lv)) do.call(rbind, lv) else NULL)
    }
    ms_write <- function(hdr, lv) {
      r1 <- store$write("morning_sheets", hdr)
      if (!is.null(lv) && nrow(lv)) store$write("morning_levels", lv)
      queue_save("morning", format(hdr$sheet_date)); r1
    }
    observeEvent(input$ms_save, { x <- ms_collect(); report(ms_write(x$hdr, x$lv), "Morning sheet"); bump() })
    # one click: Yahoo fills every empty number; Claude (optional) fills an empty news box / calendar with sourced text; then save
    ms_complete_res <- reactiveVal(NULL)
    observeEvent(input$ms_complete, {
      x <- ms_collect(); d <- x$hdr$sheet_date; sid <- x$hdr$sheet_id; lv <- x$lv; notes <- character(0)
      ref <- if (!is.null(lv)) setNames(lv$current_price, lv$instrument) else numeric(0)
      withProgress(message = "Completing the Morning Sheet...", value = 0.2, {
        y <- tryCatch(tr_yahoo_morning(unique(c(tr_morning_codes, if (!is.null(lv)) lv$instrument)), d, now = Sys.time(), ref = ref, fetch = if (is.null(yahoo_fn)) tr_yahoo_fetch else yahoo_fn),
                      error = function(e) { notes <<- c(notes, paste("Yahoo:", conditionMessage(e))); NULL })
        if (!is.null(y)) { f <- tr_morning_fill(x$hdr, lv, y, sid, d); x$hdr <- f$hdr; lv <- f$lv
          notes <- c(notes, if (length(f$filled)) paste("From Yahoo:", paste(f$filled, collapse = ", ")) else "Yahoo: nothing was empty.", if (length(y$problems)) paste("Yahoo problems:", paste(y$problems, collapse = "; "))) }
        web_ok <- isTRUE(input$ms_web_fill) && (!is.null(text_fn_in) || isTRUE(tryCatch(api_manager$claude_authenticated, error = function(e) FALSE)))
        if (web_ok && is.na(x$hdr$overnight_news)) { incProgress(0.3, detail = "headlines")
          p <- ask_web(tr_morning_web_prompt(d), "Overnight headlines"); hl <- if (is.null(p)) character(0) else tr_web_headlines(p$headlines)
          if (length(hl)) { x$hdr$overnight_news <- paste(c(paste0("Found online (unverified), ", format(d, "%d/%m/%Y"), ":"), paste("-", hl)), collapse = "\n"); notes <- c(notes, sprintf("Claude: %d headline(s) with sources added.", length(hl))) } }
        ncal <- sum(tr_pictures_for(evidence_df(), sid)$slot %in% c("calendar_o", "calendar_t")) + length(pths("ms_cal_img_o")) + length(pths("ms_cal_img_t"))
        if (web_ok && ncal == 0) {
          if (is.na(x$hdr$overnight_calendar)) { incProgress(0.2, detail = "yesterday's calendar"); py <- ask_web(tr_calendar_web_prompt(d - 1, "yesterday"), "Yesterday's calendar")
            if (!is.null(py) && nrow(cd <- tr_calendar_df(py))) { x$hdr$overnight_calendar <- tr_calendar_text(cd); notes <- c(notes, sprintf("Claude: yesterday's calendar, %d events.", nrow(cd))) } }
          if (is.na(x$hdr$todays_releases)) { incProgress(0.2, detail = "today's calendar"); pt <- ask_web(tr_calendar_web_prompt(d, "today"), "Today's calendar")
            if (!is.null(pt) && nrow(cd <- tr_calendar_df(pt))) { x$hdr$todays_releases <- tr_calendar_text(cd); notes <- c(notes, sprintf("Claude: today's calendar, %d events.", nrow(cd))) } }
        }
      })
      report(ms_write(x$hdr, lv), "Morning sheet"); bump(); load_sheet(sid); ms_complete_res(notes)
    })
    output$ms_complete_out <- renderUI({ n <- ms_complete_res(); if (is.null(n)) return(NULL)
      tags$div(style = "font-size:12.5px; background:#f6f8fb; border-radius:8px; padding:8px 12px; margin:6px 0;", lapply(n, tags$div)) })
    observeEvent(input$ms_loadBtn, { req(input$ms_load != "(none)"); load_sheet(paste0("MS_", input$ms_load)) })
    load_sheet <- function(sid) {
      s <- tr_read_current(store, "morning_sheets"); h <- s[s$sheet_id == sid, , drop = FALSE]; if (nrow(h) != 1) return(invisible())
      updateDateInput(session, "ms_date", value = h$sheet_date)
      for (p in list(c("ms_dow", "dow_price"), c("ms_dowc", "dow_change_pct"), c("ms_nik", "nikkei_price"), c("ms_nikc", "nikkei_change_pct"), c("ms_dowp", "dow_change_pts"), c("ms_nikp", "nikkei_change_pts"), c("ms_risk", "combined_open_risk_pct")))
        updateNumericInput(session, p[1], value = h[[p[2]]])
      for (p in list(c("ms_news", "overnight_news"), c("ms_cal_o", "overnight_calendar"), c("ms_cal_t", "todays_releases"), c("ms_win", "releases_in_window"),
                     c("ms_regime", "regime_summary"), c("ms_setups", "planned_setups"), c("ms_expo", "exposure_note"), c("ms_stand_why", "stand_aside_reason")))
        updateTextAreaInput(session, p[1], value = tr_or(h[[p[2]]], ""))
      updateCheckboxInput(session, "ms_stand", value = isTRUE(h$stand_aside))
      lv <- tr_read_current(store, "morning_levels"); lv <- lv[lv$sheet_id == h$sheet_id, ]
      defaults <- c("EURUSD", "USDJPY", "GBPUSD", "AUDUSD", "WTI", "GOLD", "", "")
      for (i in 1:8) {
        r <- lv[lv$instrument == defaults[i], ]; r <- if (nrow(r) && nzchar(defaults[i])) r[1, ] else NULL
        if (is.null(r) && i > 6) { rest <- lv[!lv$instrument %in% defaults[1:6], ]; if (i - 6 <= nrow(rest)) r <- rest[i - 6, ] }
        if (!is.null(r)) {
          updateSelectizeInput(session, paste0("ml", i, "_inst"), selected = r$instrument, choices = tr_blank_choice(r$instrument), options = list(create = TRUE))
          for (p in list(c("_low", "overnight_low"), c("_high", "overnight_high"), c("_cur", "current_price"), c("_adx", "adx14"), c("_ph", "prior_high"), c("_pl", "prior_low"), c("_pc", "prior_close")))
            updateNumericInput(session, paste0("ml", i, p[1]), value = r[[p[2]]])
          updateTextInput(session, paste0("ml", i, "_time"), value = tr_or(r$time_now_uk, ""))
        } else {
          updateSelectizeInput(session, paste0("ml", i, "_inst"), selected = defaults[i], choices = tr_blank_choice(defaults[i]), options = list(create = TRUE))
          for (z in c("_low", "_high", "_cur", "_adx", "_ph", "_pl", "_pc")) updateNumericInput(session, paste0("ml", i, z), value = NA)
        }
      }
      msg("Sheet loaded. Saving again creates a new version.")
    }
    output$ms_table <- DT::renderDT({
      s <- sheets_df(); lv <- levels_df()
      if (!nrow(s)) return(DT::datatable(data.frame(Message = "No morning sheets saved yet."), rownames = FALSE, options = list(dom = "t")))
      s <- s[order(s$sheet_date, decreasing = TRUE), ]
      s$Instruments <- vapply(s$sheet_id, function(i) paste(lv$instrument[lv$sheet_id == i], collapse = ", "), "")
      DT::datatable(s[, c("sheet_date", "week_no", "Instruments", "stand_aside", "combined_open_risk_pct", "record_version")], rownames = FALSE,
                    options = list(pageLength = 10, scrollX = TRUE))
    })

    # ---------------------------------------------------------------- trades: open
    set_pip <- function() { p <- tr_pip_for(input$t_asset, tr_or(input$t_basis, "ig")); if (is.finite(p)) updateNumericInput(session, "t_pip", value = p) }
    observeEvent(list(input$t_asset, input$t_basis), set_pip(), ignoreInit = TRUE)
    observeEvent(input$t_asset, {
      a <- toupper(trimws(tr_or(input$t_asset, ""))); cl <- tr_asset_class(a); mk <- tr_market_of(a)
      if (!is.na(cl)) updateSelectInput(session, "t_class", selected = cl)
      if (!is.na(mk)) updateTextInput(session, "t_market", value = mk)
    }, ignoreInit = FALSE)
    output$t_class_note <- renderUI({
      a <- toupper(trimws(tr_or(input$t_asset, ""))); i <- tr_instrument(a)
      tags$div(style = "font-size:12px; color:#64748b; line-height:1.4;", if (is.null(i)) "Not in the list: choose its asset class under Platform details." else sprintf("%s | %s | %s", i$label, i$asset_class, i$market))
    })
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
      eq <- equity_now(); rp <- 100 * e$risk_gbp / eq; g <- limits(); warn <- character(0)
      if (is.finite(g$risk_pct) && rp > g$risk_pct + 1e-9) warn <- c(warn, sprintf("Risk %.2f%% is above your plan's %.2f%% per trade.", rp, g$risk_pct))
      tot <- rp + tr_or(tr_num(input$t_corr), 0)
      if (is.finite(g$cap_pct) && tot > g$cap_pct + 1e-9) warn <- c(warn, sprintf("Combined risk %.2f%% would exceed your %.2f%% cap.", tot, g$cap_pct))
      if (is.finite(g$min_rrr) && is.finite(e$rrr) && e$rrr < g$min_rrr - 1e-9) warn <- c(warn, sprintf("Planned RRR %.2f is below your plan's minimum of %.2f.", e$rrr, g$min_rrr))
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px; font-size:13px; color:#2c3e50;",
        sprintf("Risk %.1f pips (GBP %.2f, %.2f%% of equity) | Reward %.1f pips | Planned RRR %.2f", e$risk_pips, e$risk_gbp, rp, e$reward_pips, e$rrr),
        if (length(warn)) tags$div(style = "color:#b91c1c; font-weight:600; margin-top:4px;", paste(warn, collapse = " ")))
    })
    observeEvent(input$t_save, {
      ts <- t_entry_ts(); en <- tr_num(input$t_entry); st <- tr_num(input$t_stop); tg <- tr_num(input$t_target); pip <- tr_num(input$t_pip); stake <- tr_num(input$t_stake)
      errs <- tr_validate_entry(input$t_dir, en, st, tg, pip, stake, input$t_mood, ts)
      if (!nzchar(tr_or(input$t_purpose, ""))) errs <- c(errs, "Choose whether this is an assessed trade or a practice trade.")
      if (length(errs)) { msg(paste(errs, collapse = " "), "error"); return() }
      e <- tr_entry_calc(input$t_dir, en, st, tg, pip, stake); asset <- toupper(trimws(input$t_asset))
      sc <- function(id) { v <- tr_num(input[[id]]); if (is.finite(v)) as.integer(v) else NA_integer_ }
      adx <- tr_num(input$t_adx); thr <- adx_cfg()
      row <- data.frame(trade_id = tr_id("T"), record_version = 1L, parent_trade_id = tr_blank_na(input$t_parent), status = "OPEN",
        week_no = tr_week_no(as.Date(format(ts, tz = "Europe/London")), p_start()), asset = asset, strategy = input$t_strategy, direction = input$t_dir,
        chart_period = input$t_chart, entry_ts = ts, expected_duration_hours = { d0 <- tr_num(input$t_dur); if (is.finite(d0)) d0 else tr_plan_duration(input$t_chart, plan_txt()) }, pip_size = pip, stake_per_pip_gbp = stake,
        entry_price = en, stop1 = st, target = tg, initial_risk_pips = e$risk_pips, initial_reward_pips = e$reward_pips, initial_rrr = e$rrr,
        initial_risk_gbp = e$risk_gbp, risk_pct_equity = 100 * e$risk_gbp / equity_now(), regime_adx = adx, regime_label = tr_regime(adx, thr[1], thr[2]),
        correlated_open_risk_pct = tr_num(input$t_corr), mood_entry = as.integer(input$t_mood), setup_fundamental = tr_blank_na(input$t_fund),
        setup_technical = tr_blank_na(input$t_tech), trigger_text = tr_blank_na(input$t_trigger), execution_text = tr_blank_na(input$t_exec),
        stop_reason = tr_blank_na(input$t_stopwhy), target_reason = tr_blank_na(input$t_tgtwhy),
        trade_sheet_name = sprintf("%s - %s", asset, format(ts, "%d/%m/%Y %H:%M", tz = "Europe/London")),
        notes = if (isTRUE(input$t_time_est)) "TIME_ASSUMED" else NA_character_,
        entry_source = if (!length(ev_open())) "MANUAL" else "SCREENSHOT_VERIFIED", evidence_ids = if (!length(ev_open())) NA_character_ else paste(ev_open(), collapse = ","),
        verified_by_user = if (!length(ev_open())) NA else TRUE,
        asset_class = tr_blank_na(input$t_class), market = tr_blank_na(input$t_market), market_name_raw = tr_blank_na(input$t_rawname),
        contract_type = tr_blank_na(input$t_contract), account_type = tr_blank_na(input$t_acct), is_demo = isTRUE(input$t_demo),
        source_device = tr_blank_na(input$t_device), deal_reference = tr_blank_na(input$t_dealref), size_unit = tr_blank_na(input$t_unit),
        price_basis = tr_blank_na(input$t_basis), spread_pts = tr_num(input$t_spread), margin_gbp = tr_num(input$t_margin),
        notional_gbp = tr_num(input$t_notional), costs_gbp = tr_num(input$t_costs), trade_purpose = input$t_purpose,
        charts_dropbox_path = NA_character_,
        score_patterns = sc("t_s1"), score_sr = sc("t_s2"), score_candles = sc("t_s3"), score_rsi = sc("t_s4"), score_fibs = sc("t_s5"), stringsAsFactors = FALSE)
      # a decision saved earlier in the Decision Panel (same market and side, same day, entry close by): your own pre-trade words
      # fill this trade's EMPTY boxes and the decision is linked to the trade
      dm <- if (exists("tr_dec_match", mode = "function")) tryCatch(tr_dec_match(tr_dec_from_evidence(evidence_df()), asset, input$t_dir, en, ts), error = function(e) NULL) else NULL
      d0 <- if (!is.null(dm)) tr_dec_get(evidence_df(), dm$decision_id) else NULL
      if (!is.null(d0)) row <- tr_dec_fill_trade(row, d0)
      report(store$write("trades", row), "Trade")
      if (!is.null(d0)) { tryCatch(tr_dec_link(store, d0, row$trade_id, fill = FALSE), error = function(e) cat("[Records] decision link failed:", conditionMessage(e), "\n"))
        msg(sprintf("Linked to your decision saved at %s UK: its words fill the empty boxes.", substr(tr_or(d0$first_saved_uk, ""), 12, 16))) }
      if (length(ev_open())) { link_all(ev_open(), row$trade_id); ev_open(character(0)) }
      queue_save("trade", row$trade_id)
      bump()
    })

    # ---------------------------------------------------------------- trades: manage / edit
    open_trades <- reactive({ t <- trades_df(); t[t$status == "OPEN", , drop = FALSE] })
    all_trades <- reactive({ t <- trades_df(); t[t$status %in% c("OPEN", "CLOSED") & is.na(t$parent_trade_id), , drop = FALSE] })
    manage_pool <- reactive(if (identical(input$m_action, "edit")) all_trades() else open_trades())
    trade_label <- function(t) sprintf("%s %s %s%s (%s)", t$asset, ifelse(t$direction == "B", "Buy", "Sell"), format(t$entry_ts, "%d/%m %H:%M", tz = "Europe/London"),
                                       ifelse(t$status == "CLOSED", " [closed]", ""), t$trade_id)
    observe({
      o <- manage_pool(); o <- o[order(o$entry_ts, decreasing = TRUE), , drop = FALSE]
      ch <- if (nrow(o)) setNames(o$trade_id, trade_label(o)) else c("(no open trades)" = "")
      want <- tr_or(edit_pending(), isolate(input$m_trade)); edit_pending(NULL)
      updateSelectInput(session, "m_trade", choices = ch, selected = if (!is.null(want) && want %in% o$trade_id) want else NULL)
    })
    sel <- reactive({ o <- manage_pool(); req(nzchar(tr_or(input$m_trade, ""))); r <- o[o$trade_id == input$m_trade, ]; req(nrow(r) == 1); r })
    output$m_summary <- renderUI({
      o <- manage_pool(); if (!nrow(o) || !nzchar(tr_or(input$m_trade, ""))) return(NULL); r <- tryCatch(sel(), error = function(e) NULL); if (is.null(r)) return(NULL)
      stops <- na.omit(c(r$stop1, r$stop2, r$stop3, r$stop4))
      tags$div(style = "background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:8px; font-size:13px; color:#2c3e50;",
        sprintf("%s %s at %s | stake GBP %.2f/pip | stops so far: %s | target %s | risk GBP %.2f | planned RRR %.2f%s",
                r$asset, ifelse(r$direction == "B", "buy", "sell"), r$entry_price, r$stake_per_pip_gbp, paste(stops, collapse = " → "), r$target, r$initial_risk_gbp, r$initial_rrr,
                if (identical(r$status, "CLOSED")) sprintf(" | CLOSED %s at %s, %s pips, GBP %.2f", format(r$exit_ts, "%d/%m %H:%M", tz = "Europe/London"), r$exit_price, format(round(r$pips_result, 1)), r$net_pnl_gbp) else ""),
        if (isTRUE(grepl("TIME_ASSUMED", tr_or(r$notes, "")))) tags$div(style = "color:#b91c1c; font-weight:700;", "Entry time is marked as an estimate: confirm it from IG History > Activity."),
        { did <- regmatches(tr_or(r$notes, ""), regexpr("DECISION:[A-Za-z0-9_]+", tr_or(r$notes, "")))
          d0 <- if (length(did) && exists("tr_dec_get", mode = "function")) tryCatch(tr_dec_get(evidence_df(), sub("^DECISION:", "", did)), error = function(e) NULL) else NULL
          if (!is.null(d0)) tags$div(style = "margin-top:4px; color:#334155;", sprintf("Decision saved at %s UK. ", substr(tr_or(d0$first_saved_uk, ""), 12, 16)),
            if (length(d0$facts$warnings)) tags$span(style = "color:#b91c1c;", paste("Warnings shown then:", paste(d0$facts$warnings, collapse = " | "))) else "No plan warnings were shown then.") })
    })
    # edit: load the selected trade's current values into the form
    observeEvent(list(input$m_trade, input$m_action, act_fix()), {
      if (!identical(input$m_action, "edit") || !nzchar(tr_or(input$m_trade, ""))) return()
      r <- tryCatch(sel(), error = function(e) NULL); if (is.null(r)) return()
      tx <- function(v) if (is.null(v) || is.na(v)) "" else as.character(v)
      nm <- function(v) if (is.null(v) || !is.finite(v)) NA else v
      loc <- format(r$entry_ts, "%Y-%m-%d", tz = "Europe/London")
      updateDateInput(session, "e_date", value = as.Date(loc)); updateTextInput(session, "e_time", value = format(r$entry_ts, "%H:%M", tz = "Europe/London"))
      updateCheckboxInput(session, "e_time_est", value = isTRUE(grepl("TIME_ASSUMED", tr_or(r$notes, ""))))
      updateSelectInput(session, "e_purpose", selected = tx(r$trade_purpose)); updateSelectInput(session, "e_contract", selected = tx(r$contract_type))
      updateTextInput(session, "e_dealref", value = tx(r$deal_reference)); updateTextInput(session, "e_chart", value = tx(r$chart_period))
      for (p in list(c("e_spread", "spread_pts"), c("e_margin", "margin_gbp"), c("e_notional", "notional_gbp"), c("e_costs", "costs_gbp"), c("e_dur", "expected_duration_hours"),
                     c("e_entry", "entry_price"), c("e_stop", "stop1"), c("e_target", "target"), c("e_stake", "stake_per_pip_gbp"), c("e_xprice", "exit_price")))
        updateNumericInput(session, p[1], value = nm(r[[p[2]]]))
      updateNumericInput(session, "e_xpnl", value = if (identical(r$pnl_source, "PLATFORM")) nm(r$net_pnl_gbp) else NA)
      if (!is.na(r$exit_ts)) { updateDateInput(session, "e_xdate", value = as.Date(format(r$exit_ts, "%Y-%m-%d", tz = "Europe/London"))); updateTextInput(session, "e_xtime", value = format(r$exit_ts, "%H:%M", tz = "Europe/London")) }
      else updateTextInput(session, "e_xtime", value = "")
      if (!is.na(r$exit_code)) updateSelectInput(session, "e_xcode", selected = r$exit_code)
      for (p in list(c("e_fund", "setup_fundamental"), c("e_tech", "setup_technical"), c("e_trigger", "trigger_text"), c("e_exec", "execution_text"),
                     c("e_stopwhy", "stop_reason"), c("e_tgtwhy", "target_reason"), c("e_why", "reason_for_exit"), c("e_lessons", "lessons_learned")))
        updateTextAreaInput(session, p[1], value = tx(r[[p[2]]]))
      fx <- isolate(act_fix())   # a time read from IG History > Activity replaces the saved one
      if (!is.null(fx)) { if (!is.na(tr_or(fx$date, NA))) updateDateInput(session, "e_date", value = as.Date(fx$date)); updateTextInput(session, "e_time", value = fx$time); updateCheckboxInput(session, "e_time_est", value = FALSE); act_fix(NULL) }
    })
    save_edit <- function() {
      r <- sel(); ts2 <- tr_parse_ts(input$e_date, tr_or(input$e_time, ""))
      if (is.na(ts2)) { msg("The entry date/time is not valid (use HH:MM, UK time).", "error"); return() }
      if (!nzchar(tr_or(input$e_purpose, ""))) { msg("Choose whether this is an assessed trade or a practice trade.", "error"); return() }
      keep <- function(id, old) { v <- tr_num(input[[id]]); if (is.finite(v)) v else old }
      en <- keep("e_entry", r$entry_price); st <- keep("e_stop", r$stop1); tg <- keep("e_target", r$target); sk <- keep("e_stake", r$stake_per_pip_gbp)
      errs <- tr_validate_entry(r$direction, en, st, tg, r$pip_size, sk, NA, ts2); if (length(errs)) { msg(paste(errs, collapse = " "), "error"); return() }
      calc <- tr_entry_calc(r$direction, en, st, tg, r$pip_size, sk)
      nxt <- r; nxt$record_version <- r$record_version + 1L
      nxt$entry_ts <- ts2; nxt$week_no <- tr_week_no(as.Date(format(ts2, tz = "Europe/London")), p_start())
      nxt$trade_sheet_name <- sprintf("%s - %s", r$asset, format(ts2, "%d/%m/%Y %H:%M", tz = "Europe/London"))
      nxt$entry_price <- en; nxt$stop1 <- st; nxt$target <- tg; nxt$stake_per_pip_gbp <- sk
      nxt$initial_risk_pips <- calc$risk_pips; nxt$initial_reward_pips <- calc$reward_pips; nxt$initial_rrr <- calc$rrr; nxt$initial_risk_gbp <- calc$risk_gbp
      if (is.finite(r$risk_pct_equity) && is.finite(r$initial_risk_gbp) && r$initial_risk_gbp > 0) nxt$risk_pct_equity <- r$risk_pct_equity * calc$risk_gbp / r$initial_risk_gbp
      nxt$chart_period <- tr_blank_na(input$e_chart); nxt$expected_duration_hours <- tr_num(input$e_dur)
      nts <- trimws(gsub("TIME_ASSUMED;? ?", "", tr_or(r$notes, ""))); if (isTRUE(input$e_time_est)) nts <- paste(c("TIME_ASSUMED", if (nzchar(nts)) nts), collapse = "; ")
      nxt$notes <- if (nzchar(nts)) nts else NA_character_
      nxt$trade_purpose <- input$e_purpose; nxt$contract_type <- tr_blank_na(input$e_contract); nxt$deal_reference <- tr_blank_na(input$e_dealref)
      nxt$spread_pts <- tr_num(input$e_spread); nxt$margin_gbp <- tr_num(input$e_margin); nxt$notional_gbp <- tr_num(input$e_notional); nxt$costs_gbp <- tr_num(input$e_costs)
      nxt$setup_fundamental <- tr_blank_na(input$e_fund); nxt$setup_technical <- tr_blank_na(input$e_tech); nxt$trigger_text <- tr_blank_na(input$e_trigger)
      nxt$execution_text <- tr_blank_na(input$e_exec); nxt$stop_reason <- tr_blank_na(input$e_stopwhy); nxt$target_reason <- tr_blank_na(input$e_tgtwhy)
      if (identical(r$status, "CLOSED")) {
        xts <- if (nzchar(trimws(tr_or(input$e_xtime, "")))) tr_parse_ts(input$e_xdate, input$e_xtime) else r$exit_ts
        if (is.na(xts)) { msg("The exit date/time is not valid (use HH:MM, UK time).", "error"); return() }
        if (xts < ts2) { msg("Exit is before the entry time.", "error"); return() }
        xp <- keep("e_xprice", r$exit_price)
        cc <- tr_close_calc(r$direction, en, xp, r$pip_size, sk, calc$risk_gbp, tr_num(input$e_xpnl))
        nxt$exit_ts <- xts; nxt$exit_price <- xp; nxt$exit_code <- tr_or(input$e_xcode, r$exit_code)
        nxt$pips_result <- cc$pips; nxt$net_pnl_gbp <- cc$net; nxt$pnl_source <- cc$source; nxt$real_r <- cc$real_r
        nxt$duration_hours <- as.numeric(difftime(xts, ts2, units = "hours"))
        nxt$reason_for_exit <- tr_blank_na(input$e_why); nxt$lessons_learned <- tr_blank_na(input$e_lessons)
      }
      report(store$write("trades", nxt), "Trade changes"); queue_save("trade", r$trade_id)
      # partial-exit legs share the entry: keep their entry time and duration in step
      kids <- trades_df(); kids <- kids[!is.na(kids$parent_trade_id) & kids$parent_trade_id == r$trade_id, , drop = FALSE]
      for (k in seq_len(nrow(kids))) { c1 <- kids[k, ]; c1$record_version <- c1$record_version + 1L; c1$entry_ts <- ts2
        if (!is.na(c1$exit_ts)) c1$duration_hours <- as.numeric(difftime(c1$exit_ts, ts2, units = "hours")); store$write("trades", c1) }
      bump()
    }
    observeEvent(input$m_save, {
      if (identical(input$m_action, "edit")) { save_edit(); return() }
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
        store$write("trade_events", ev); report(store$write("trades", nxt), "Stop move"); queue_save("trade", r$trade_id)
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
          me <- identical(input$m_code, "ME"); pf <- tr_or(input$m_post, "")
          row$me_then_hit_stop <- if (me) identical(pf, "stop") else NA; row$me_then_hit_target <- if (me) identical(pf, "target") else NA
          if (!is.null(ev_close())) { row$evidence_ids <- paste(na.omit(c(row$evidence_ids, ev_close())), collapse = ","); row$verified_by_user <- TRUE }
          row }
        if (act == "close") {
          report(store$write("trades", fill(nxt, r$stake_per_pip_gbp, r$initial_risk_gbp)), "Closed trade"); queue_save("trade", r$trade_id)
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
          store$write("trades", child); report(store$write("trades", nxt), "Partial exit"); queue_save("trade", r$trade_id)
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
      t$purpose <- ifelse(is.na(t$trade_purpose) | !nzchar(t$trade_purpose), "ASSESSED", t$trade_purpose)
      DT::datatable(t[, c("trade_sheet_name", "purpose", "status", "asset_class", "contract_type", "strategy", "direction", "entry_price", "stop1", "target", "initial_rrr", "exit_price", "exit_code",
                          "net_pnl_gbp", "real_r", "plan_followed", "week_no")], rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE)) |>
        DT::formatRound(c("initial_rrr", "net_pnl_gbp", "real_r"), 2)
    })
    output$dlTrades <- downloadHandler(filename = function() paste0("trading_trades_", format(Sys.Date()), ".csv"),
                                       content = function(file) write.csv(trades_df(), file, row.names = FALSE, na = ""))

    # ---------------------------------------------------------------- statistics
    stats <- reactive({
      t <- tr_scope_filter(trades_df(), tr_or(input$st_scope, "ASSESSED")); cl <- t[t$status == "CLOSED" & !is.na(t$net_pnl_gbp), , drop = FALSE]
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

    # ---------------------------------------------------------------- exports
    ex_trades <- reactive(tr_scope_filter(trades_df(), tr_or(input$ex_scope, "ASSESSED")))
    observe({
      t <- ex_trades(); t <- t[t$status %in% c("OPEN", "CLOSED") & is.na(t$parent_trade_id), , drop = FALSE]
      ch <- if (nrow(t)) { t <- t[order(t$entry_ts, decreasing = TRUE), ]; setNames(t$trade_id, paste0(t$trade_sheet_name, " [", t$status, "]")) } else c("(no trades yet)" = "")
      updateSelectInput(session, "ex_trade", choices = ch, selected = isolate(input$ex_trade))
    })
    observe({
      s <- sheets_df(); ch <- if (nrow(s)) setNames(format(sort(s$sheet_date, decreasing = TRUE)), format(sort(s$sheet_date, decreasing = TRUE), "%d/%m/%Y")) else c("(no sheets yet)" = "")
      updateSelectInput(session, "ex_sheet", choices = ch, selected = isolate(input$ex_sheet))
    })
    trader <- reactive(tr_or(input$s_name, tr_or(sv()$trader_name, "")))
    trader_label <- reactive({ n <- trader(); i <- tr_or(input$s_id, tr_or(sv()$student_id, "")); if (nzchar(i)) paste0(n, " (", i, ")") else n })
    output$dlBlotter <- downloadHandler(filename = function() paste0("trade_blotter_", format(Sys.Date()), ".xlsx"),
      content = function(file) tr_write_blotter(ex_trades(), file, trader()))
    output$dlStatsX <- downloadHandler(filename = function() paste0("trading_statistics_", format(Sys.Date()), ".xlsx"),
      content = function(file) tr_stats_xlsx(ex_trades(), opening(), file, trader()))
    pths <- function(id) { f <- input[[id]]; if (is.null(f) || !NROW(f)) character(0) else f$datapath }
    morning_day <- function() tryCatch(as.Date(input$ex_sheet), error = function(e) tr_london_today())
    # save pictures as evidence rows (kind "picture"), skipping a file already saved for the same owner and slot
    save_pictures <- function(paths, names, owner, slot, caption = NA_character_, day = tr_london_today()) {
      if (!length(paths)) return(0L)
      have <- evidence_df(); have <- have[!is.na(have$trade_id) & have$trade_id == owner & !(have$status %in% "DISCARDED") & !is.na(have$screen_type) & have$screen_type == slot, , drop = FALSE]
      n <- 0L
      for (i in seq_along(paths)) {
        md5 <- unname(tools::md5sum(paths[i])); if (md5 %in% have$file_md5) next
        id <- tr_id("EV"); put <- pic_store()$put(paths[i], tr_picture_rel(id, names[i], day))
        store$write("evidence", tr_picture_row(id, owner, slot, if (is.null(caption) || !nzchar(tr_or(caption, ""))) NA_character_ else caption, put$path, names[i],
                                               md5 = md5, size = file.size(paths[i]), mime = tr_media_type(names[i])))
        n <- n + 1L
      }
      if (n) bump(); n
    }
    # stored pictures of a trade / sheet, with local file paths (downloaded from Dropbox when needed)
    pictures_of <- function(owner) {
      pf <- tr_pictures_for(evidence_df(), owner); if (!nrow(pf)) return(cbind(pf, path = character(0)))
      pf$path <- vapply(pf$dropbox_path, function(p) pic_store()$get(p), ""); miss <- is.na(pf$path)
      if (any(miss)) msg(sprintf("%d saved picture(s) could not be found (for example a session-only picture after a restart): %s", sum(miss), paste(pf$file_name[miss], collapse = ", ")), "warning")
      pf[!miss, , drop = FALSE]
    }
    morning_cal <- function(sid, slot, upload_id, tab_id, use_inputs = TRUE) {   # Exports upload > Morning-tab upload (this session) > pictures saved with the sheet
      if (use_inputs) { p <- pths(upload_id); if (length(p)) return(p); p <- pths(tab_id); if (length(p)) return(p) }
      pf <- pictures_of(sid); pf$path[pf$slot == slot]
    }
    build_morning <- function(file, day = input$ex_sheet, use_inputs = TRUE) {
      s <- tr_read_current(store, "morning_sheets"); h <- s[format(s$sheet_date) == tr_or(as.character(day), ""), , drop = FALSE]
      if (!nrow(h)) stop("Choose a saved morning sheet first.")
      h <- h[1, ]; lv <- tr_read_current(store, "morning_levels"); lv <- lv[lv$sheet_id == h$sheet_id, , drop = FALSE]
      if (use_inputs) for (u in list(c("cal_o", "calendar_o"), c("cal_t", "calendar_t"))) { f <- input[[u[1]]]; if (!is.null(f) && NROW(f)) save_pictures(f$datapath, f$name, h$sheet_id, u[2], NA, h$sheet_date) }
      same_day <- identical(format(as.Date(tr_or(input$ms_date, NA))), format(h$sheet_date))   # Morning-tab uploads belong to the date shown there
      tr_morning_docx(h, lv, trader_label(), file, cal_o = morning_cal(h$sheet_id, "calendar_o", "cal_o", "ms_cal_img_o", use_inputs && same_day),
                      cal_t = morning_cal(h$sheet_id, "calendar_t", "cal_t", "ms_cal_img_t", use_inputs && same_day))
    }
    trade_row <- function(tid = input$ex_trade) { t <- trades_df(); t[t$trade_id == tr_or(tid, ""), , drop = FALSE] }
    trade_name <- function(ext, tid = input$ex_trade) {
      t <- tr_read_current(store, "trades"); r <- t[t$trade_id == tr_or(tid, ""), , drop = FALSE]; if (nrow(r) != 1) return(paste0("Individual_Trade_Sheet.", ext))
      day <- format(r$entry_ts, "%Y-%m-%d", tz = "Europe/London"); nm <- tr_trade_filename(r$asset, day, ext)
      t <- t[t$status %in% c("OPEN", "CLOSED") & is.na(t$parent_trade_id), , drop = FALSE]
      same <- t[t$asset == r$asset & format(t$entry_ts, "%Y-%m-%d", tz = "Europe/London") == day, , drop = FALSE]
      if (nrow(same) > 1) nm <- sub(paste0("\\.", ext, "$"), paste0("_", format(r$entry_ts, "%H%M", tz = "Europe/London"), ".", ext), nm)   # two trades in one market on one day: add the time
      nm
    }
    chart_cache <- file.path(tempdir(), paste0("lat_charts_", session$token))
    build_trade <- function(file, tid = input$ex_trade) {
      t <- tr_read_current(store, "trades"); tid <- tr_or(tid, ""); tr1 <- t[t$trade_id == tid, , drop = FALSE]
      if (nrow(tr1) != 1) stop("Choose a trade first.")
      legs <- t[(t$trade_id == tid | (!is.na(t$parent_trade_id) & t$parent_trade_id == tid)) & t$status == "CLOSED", , drop = FALSE]
      ev <- tr_read_current(store, "trade_events"); ev <- ev[ev$trade_id == tid, , drop = FALSE]; ev <- ev[order(ev$event_ts), , drop = FALSE]
      if (!is.finite(tr1$expected_duration_hours)) tr1$expected_duration_hours <- tr_plan_duration(tr1$chart_period, plan_txt())   # printed from your plan
      pics <- pictures_of(tid)
      if (isTRUE(autochart_on())) {   # empty chart slots: a chart drawn from Yahoo prices, labelled as such
        dir.create(chart_cache, showWarnings = FALSE)
        add <- function(kind) { g <- tryCatch(tr_trade_chart_png(tr1, legs, ev, kind, file.path(chart_cache, sprintf("%s_%s_v%s.png", tid, kind, tr1$record_version)),
                                                                  fetch = if (is.null(yahoo_fn)) tr_yahoo_fetch else yahoo_fn), error = function(e) NULL)
          if (!is.null(g)) pics <<- rbind(pics, data.frame(slot = kind, event_id = NA_character_, caption = g$caption, dropbox_path = NA_character_, file_name = basename(g$file), evidence_id = NA_character_, path = g$file, stringsAsFactors = FALSE)) }
        if (!any(pics$slot == "entry")) add("entry")
        if (identical(tr1$status, "CLOSED") && !any(pics$slot %in% c("exit", "post_exit"))) add("post_exit")
      }
      tr_trade_sheet_docx(tr1, legs, ev, trader_label(), pics, file)
    }
    # ---- automatic saving: every change queues its sheet; the queue is worked through after the change is stored
    autosave_q <- reactiveVal(list())
    queue_save <- function(kind, id) { if (!isTRUE(isolate(autosave_on())) || is.null(id) || !nzchar(id)) return(invisible()); q <- isolate(autosave_q()); autosave_q(c(q, list(list(kind = kind, id = id)))) }
    save_built <- function(builder, name, kind, keep_existing = FALSE) {
      r <- tryCatch(pdf_of(builder, name), error = function(e) { cat("[Records] sheet not built:", conditionMessage(e), "\n"); NULL })
      if (is.null(r)) return(data.frame(file = name, where = "", ok = FALSE, note = "the sheet could not be built (see the Debug Console)", stringsAsFactors = FALSE))
      res <- tr_save_sheet(c(r$docx, r$pdf), kind, keep_existing = keep_existing)
      if (is.na(r$pdf)) res <- rbind(res, data.frame(file = sub("\\.docx$", ".pdf", name), where = "", ok = FALSE, note = "PDF not made: LibreOffice was not found on this computer", stringsAsFactors = FALSE))
      res
    }
    save_blotter <- function() {
      f <- file.path(tempfile("blotter_"), "Trade_Blotter.xlsx"); dir.create(dirname(f))
      ok <- tryCatch({ tr_write_blotter(tr_scope_filter(tr_read_current(store, "trades"), "ASSESSED"), f, trader()); TRUE }, error = function(e) FALSE)
      if (ok) tr_save_sheet(f, "other") else NULL
    }
    observeEvent(autosave_q(), {
      q <- autosave_q(); if (!length(q)) return(); autosave_q(list())
      q <- q[!duplicated(vapply(q, function(z) paste(z$kind, z$id), ""))]; out <- list()
      withProgress(message = "Saving the sheets to Dropbox...", value = 0.3, {
        for (z in q) out[[length(out) + 1]] <- tryCatch(if (z$kind == "morning") save_built(function(f) build_morning(f, z$id, use_inputs = TRUE), tr_morning_filename(z$id), "morning")
                                                          else save_built(function(f) build_trade(f, z$id), trade_name("docx", z$id), "trade"),
                                                          error = function(e) data.frame(file = paste(z$kind, z$id), where = "", ok = FALSE, note = conditionMessage(e), stringsAsFactors = FALSE))
        if (any(vapply(q, function(z) z$kind == "trade", TRUE))) out[[length(out) + 1]] <- tryCatch(save_blotter(), error = function(e) NULL)
      })
      res <- do.call(rbind, out); if (is.null(res)) return(); sv_res(res)
      msg(if (all(res$ok)) paste("Saved to Dropbox:", paste(unique(res$file), collapse = ", ")) else "Some sheets were not saved to Dropbox: see Exports.", if (all(res$ok)) "message" else "warning")
    }, ignoreInit = TRUE)
    # ---- back-fill past days (Setup)
    backfill_res <- reactiveVal(NULL)
    observeEvent(input$backfill, {
      days <- seq(p_start(), min(tr_london_today(), tr_or(as.Date(tr_or(sv()$period_end, NA)), tr_london_today())), by = "day"); days <- days[!format(days, "%u") %in% c("6", "7")]
      fetch <- tr_fetch_cached(if (is.null(yahoo_fn)) tr_yahoo_fetch else yahoo_fn); out <- list(); saves <- list()
      sh_all <- tr_read_current(store, "morning_sheets"); lv_all <- tr_read_current(store, "morning_levels")
      withProgress(message = "Completing past records...", value = 0, {
        for (d in as.list(days)) { incProgress(1 / (length(days) + 1), detail = format(d, "%d/%m"))
          sid <- paste0("MS_", format(d)); h <- sh_all[sh_all$sheet_id == sid, , drop = FALSE]; is_new <- !nrow(h)
          h <- if (is_new) tr_coerce("morning_sheets", data.frame(sheet_id = sid, record_version = 1L, sheet_date = d, week_no = tr_week_no(d, p_start()), trader_name = tr_blank_na(trader()))) else { h <- h[1, ]; h$record_version <- h$record_version + 1L; h }
          lv <- lv_all[lv_all$sheet_id == sid, , drop = FALSE]
          y <- tryCatch(tr_yahoo_morning(unique(c(tr_morning_codes, lv$instrument)), d, now = Sys.time(), ref = setNames(lv$current_price, lv$instrument), fetch = fetch), error = function(e) NULL)
          if (is.null(y)) { out[[length(out) + 1]] <- data.frame(Date = format(d, "%d/%m/%Y"), Result = "Yahoo not reachable", stringsAsFactors = FALSE); next }
          f <- tr_morning_fill(h, lv, y, sid, d)
          if (!length(f$filled) && !is_new) { out[[length(out) + 1]] <- data.frame(Date = format(d, "%d/%m/%Y"), Result = "nothing empty that Yahoo can fill", stringsAsFactors = FALSE); next }
          store$write("morning_sheets", f$hdr); if (nrow(f$lv)) store$write("morning_levels", f$lv)
          saves[[length(saves) + 1]] <- format(d)
          out[[length(out) + 1]] <- data.frame(Date = format(d, "%d/%m/%Y"), Result = paste0(if (is_new) "new sheet; " else "", length(f$filled), " value(s) filled"), stringsAsFactors = FALSE)
        }
        t <- tr_read_current(store, "trades"); t <- t[t$status %in% c("OPEN", "CLOSED") & is.na(t$parent_trade_id) & !is.finite(t$expected_duration_hours), , drop = FALSE]; nd <- 0L
        for (i in seq_len(nrow(t))) { dd <- tr_plan_duration(t$chart_period[i], plan_txt()); if (!is.finite(dd)) next
          r <- t[i, ]; r$record_version <- r$record_version + 1L; r$expected_duration_hours <- dd; store$write("trades", r); nd <- nd + 1L; queue_save("trade", r$trade_id) }
        out[[length(out) + 1]] <- data.frame(Date = "Trades", Result = if (nchar(plan_txt())) sprintf("%d trade(s) given the expected duration from your plan", nd) else "no plan durations saved in Setup: expected durations left as they are", stringsAsFactors = FALSE)
        bump()
        if (isTRUE(autosave_on())) for (d in saves) { r <- save_built(function(f) build_morning(f, d, use_inputs = FALSE), tr_morning_filename(d), "morning", keep_existing = TRUE)
          out[[length(out) + 1]] <- data.frame(Date = format(as.Date(d), "%d/%m/%Y"), Result = paste("Dropbox:", paste(unique(r$note), collapse = "; ")), stringsAsFactors = FALSE) }
      })
      backfill_res(do.call(rbind, out))
    })
    output$backfill_out <- renderUI({ d <- backfill_res(); if (is.null(d)) return(NULL); tags$div(style = "margin-top:8px;", renderTable(d)) })
    # ---- complete this sheet: load / save the student's own boxes (+ chart period and expected duration)
    observeEvent(list(input$ex_trade, trades_df()), {
      r <- trade_row(); if (nrow(r) != 1) return()
      t <- trades_df(); kids <- t[!is.na(t$parent_trade_id) & t$parent_trade_id == r$trade_id & t$status == "CLOSED", , drop = FALSE]
      last <- if (nrow(kids) && !identical(r$status, "CLOSED")) kids[which.max(kids$exit_ts), ] else r
      tx <- function(v) if (is.null(v) || !length(v) || is.na(v)) "" else as.character(v)
      updateTextInput(session, "x_chart", value = tx(r$chart_period)); updateNumericInput(session, "x_dur", value = if (is.finite(r$expected_duration_hours)) r$expected_duration_hours else NA)
      for (p in list(c("x_fund", "setup_fundamental"), c("x_tech", "setup_technical"), c("x_trigger", "trigger_text"), c("x_exec", "execution_text"), c("x_stopwhy", "stop_reason"), c("x_tgtwhy", "target_reason")))
        updateTextAreaInput(session, p[1], value = tx(r[[p[2]]]))
      updateTextAreaInput(session, "x_why", value = tx(last$reason_for_exit)); updateTextAreaInput(session, "x_lessons", value = tx(last$lessons_learned))
    }, ignoreInit = TRUE)
    observeEvent(input$x_save, {
      r <- trade_row(); if (nrow(r) != 1) { msg("Choose the trade first.", "warning"); return() }
      nxt <- r; nxt$record_version <- r$record_version + 1L
      nxt$chart_period <- tr_blank_na(input$x_chart); nxt$expected_duration_hours <- { d0 <- tr_num(input$x_dur); if (is.finite(d0)) d0 else tr_plan_duration(input$x_chart, plan_txt()) }
      nxt$setup_fundamental <- tr_blank_na(input$x_fund); nxt$setup_technical <- tr_blank_na(input$x_tech); nxt$trigger_text <- tr_blank_na(input$x_trigger)
      nxt$execution_text <- tr_blank_na(input$x_exec); nxt$stop_reason <- tr_blank_na(input$x_stopwhy); nxt$target_reason <- tr_blank_na(input$x_tgtwhy)
      t <- trades_df(); kids <- t[!is.na(t$parent_trade_id) & t$parent_trade_id == r$trade_id & t$status == "CLOSED", , drop = FALSE]
      if (identical(r$status, "CLOSED") || !nrow(kids)) { nxt$reason_for_exit <- tr_blank_na(input$x_why); nxt$lessons_learned <- tr_blank_na(input$x_lessons) }
      report(store$write("trades", nxt), "Your text"); queue_save("trade", r$trade_id)
      if (nrow(kids) && !identical(r$status, "CLOSED")) {   # the sheet takes Reason for exit / Lessons from the last closed leg
        k <- kids[which.max(kids$exit_ts), ]; k$record_version <- k$record_version + 1L; k$reason_for_exit <- tr_blank_na(input$x_why); k$lessons_learned <- tr_blank_na(input$x_lessons); store$write("trades", k) }
      bump()
    })
    output$x_facts <- renderUI({
      r <- trade_row(); if (nrow(r) != 1) return(NULL); t <- trades_df()
      legs <- t[(t$trade_id == r$trade_id | (!is.na(t$parent_trade_id) & t$parent_trade_id == r$trade_id)) & t$status == "CLOSED", , drop = FALSE]
      ev <- events_df(); ev <- ev[ev$trade_id == r$trade_id, , drop = FALSE]; ev <- ev[order(ev$event_ts), , drop = FALSE]
      sid <- paste0("MS_", format(r$entry_ts, "%Y-%m-%d", tz = "Europe/London"))
      lv <- levels_df(); lv <- lv[lv$sheet_id == sid, , drop = FALSE]; sh <- sheets_df(); sh <- sh[sh$sheet_id == sid, , drop = FALSE]
      fx <- tryCatch(tr_trade_facts(r, legs, ev, lv, sh), error = function(e) paste("Facts not available:", conditionMessage(e)))
      tags$div(style = "font-size:12.5px; background:#ffffff; border:1px solid #e2e8f0; border-radius:8px; padding:8px 12px; line-height:1.55;",
        tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:4px;", "Facts from your records (for checking, not for pasting)"),
        tags$ul(style = "padding-left:18px; margin:0;", lapply(fx, tags$li)),
        if (!nrow(sh)) tags$div(style = "color:#64748b; margin-top:4px;", "No Morning Sheet saved for that date, so no overnight range, pivots or calendar."))
    })
    # ---- Dropbox test: write a small file, drop the session copy, read it back
    dbx_test_res <- reactiveVal(NULL)
    observeEvent(input$dbx_test, {
      st <- pic_store(); f <- tempfile(fileext = ".txt"); writeLines(paste("LAT U3 Dropbox test", format(Sys.time())), f)
      rel <- paste0("Screenshots/_test/dropbox_test_", format(Sys.time(), "%H%M%S"), ".txt")
      put <- tryCatch(st$put(f, rel), error = function(e) list(path = NA, where = character(0), err = conditionMessage(e)))
      unlink(file.path(session_cache, rel))
      back <- if (!is.na(put$path)) tryCatch(st$get(put$path), error = function(e) NA_character_) else NA_character_
      ok <- !is.na(back) && identical(readLines(back, warn = FALSE), readLines(f, warn = FALSE))
      dbx_test_res(list(ok = ok, where = put$where, path = put$path, err = put$err))
    })
    output$dbx_test_out <- renderUI({ r <- dbx_test_res(); if (is.null(r)) return(NULL)
      tags$div(style = paste0("font-size:12.5px; margin:6px 0; color:", if (r$ok && length(r$where)) "#15803d" else "#b91c1c", ";"),
        if (r$ok && length(r$where)) paste0("✓ Written to ", paste(c(folder = "the Dropbox folder", api = "Dropbox (API)")[r$where], collapse = " and "), " and read back: ", r$path)
        else paste0("✗ Not stored in Dropbox", if (!is.null(r$err)) paste0(": ", r$err) else if (startsWith(tr_or(r$path, ""), "session:")) ": only the session copy exists. Check the folder / API path and the token, and see the Debug Console." else "")) })

    # ---- pictures of the selected trade
    observe({   # in-trade actions of the selected trade, for tying a chart to one of them
      ev <- events_df(); tid <- tr_or(input$ex_trade, ""); ev <- ev[ev$trade_id == tid, , drop = FALSE]; ev <- ev[order(ev$event_ts), , drop = FALSE]
      ch <- c("(general)" = "")
      if (nrow(ev)) ch <- c(ch, setNames(ev$event_id, sprintf("%s %s: %s", format(ev$event_ts, "%d/%m %H:%M", tz = "Europe/London"),
                                                               ifelse(ev$event_type == "STOP_MOVE", "stop moved", "partial exit"), ifelse(ev$event_type == "STOP_MOVE", paste("to", ev$new_stop), paste("at", ev$price)))))
      updateSelectInput(session, "pic_event", choices = ch)
    })
    observeEvent(input$pic_add, {
      tid <- tr_or(input$ex_trade, ""); if (!nzchar(tid)) { msg("Choose the trade first.", "warning"); return() }
      f <- input$pic_files; if (is.null(f) || !NROW(f)) { msg("Choose the picture file(s) first.", "warning"); return() }
      slot <- tr_or(input$pic_slot, "entry"); if (identical(slot, "intrade") && nzchar(tr_or(input$pic_event, ""))) slot <- paste0("intrade:", input$pic_event)
      r <- trade_row(); day <- if (nrow(r)) as.Date(format(r$entry_ts, "%Y-%m-%d", tz = "Europe/London")) else tr_london_today()
      cap <- tr_or(input$pic_caption, ""); if (!nzchar(cap) && identical(slot, "entry") && nrow(r)) cap <- tr_or(r$chart_period, "")   # default caption: the chart period
      n <- save_pictures(f$datapath, f$name, tid, slot, if (nzchar(cap)) cap else NA, day); if (n) queue_save("trade", tid)
      msg(if (n) sprintf("%d picture(s) saved with the trade%s.", n, if (pic_store()$durable()) " (Dropbox)" else " (this session only: set Dropbox in Setup)") else "Those pictures were already saved for this place on the sheet.", if (n) "message" else "warning")
    })
    pic_rows <- reactive({ tr_pictures_for(evidence_df(), tr_or(input$ex_trade, "")) })
    output$pic_table <- DT::renderDT({
      pf <- pic_rows()
      if (!nrow(pf)) return(DT::datatable(data.frame(Note = "No pictures saved for this trade yet."), rownames = FALSE, options = list(dom = "t")))
      lab <- c(entry = "Entry chart", entry_platform = "Entry (IG screenshot)", intrade = "In-trade", exit = "Exit", post_exit = "Post exit", other = "Other")
      DT::datatable(data.frame(Where = unname(lab[pf$slot]), Caption = ifelse(is.na(pf$caption), "", pf$caption), File = pf$file_name,
                               Stored = ifelse(startsWith(pf$dropbox_path, "session:"), "this session only", "Dropbox"), stringsAsFactors = FALSE),
                    rownames = FALSE, selection = "multiple", options = list(dom = "t", pageLength = 50, ordering = FALSE))
    })
    observeEvent(input$pic_remove, {
      pf <- pic_rows(); ix <- input$pic_table_rows_selected; if (!length(ix) || !nrow(pf)) { msg("Select the picture(s) in the table first.", "warning"); return() }
      ev <- evidence_df()
      for (id in pf$evidence_id[ix]) { r <- ev[ev$evidence_id == id, , drop = FALSE][1, ]
        if (identical(r$kind, "picture")) { r$status <- "DISCARDED" } else { r$status <- "CONFIRMED"; r$trade_id <- NA_character_ }   # a platform screenshot is unlinked, not deleted
        r$record_version <- r$record_version + 1L; store$write("evidence", r) }
      bump(); queue_save("trade", tr_or(input$ex_trade, "")); msg(sprintf("%d picture(s) removed from the sheet.", length(ix)))
    })
    gap_box <- function(g, title) {
      if (is.null(g) || !nrow(g)) return(tags$div(style = "color:#15803d; font-size:12.5px; margin:6px 0;", paste("✓", title, "complete: every box will be filled.")))
      col <- c(missing = "#b91c1c", assumed = "#b45309", yours = "#1d4ed8"); lab <- c(missing = "Missing", assumed = "Assumed", yours = "Yours to write")
      tags$div(style = "font-size:12.5px; background:#fff7ed; border:1px solid #fed7aa; border-radius:8px; padding:8px 12px; margin:8px 0; color:#2c3e50;",
        tags$div(style = "font-weight:800; margin-bottom:4px;", paste(title, ": check before you export (the export still works)")),
        lapply(seq_len(nrow(g)), function(i) tags$div(tags$span(style = paste0("font-weight:700; color:", col[[g$level[i]]], ";"), paste0(lab[[g$level[i]]], ": ")), g$field[i], if (nzchar(g$note[i])) paste0(". ", g$note[i]) else "")))
    }
    output$trade_gaps <- renderUI({
      r <- trade_row(); if (nrow(r) != 1) return(NULL); t <- trades_df()
      legs <- t[(t$trade_id == r$trade_id | (!is.na(t$parent_trade_id) & t$parent_trade_id == r$trade_id)) & t$status == "CLOSED", , drop = FALSE]
      gap_box(tr_trade_gaps(r, legs, pic_rows()), "Trade Sheet")
    })
    output$morning_gaps <- renderUI({
      s <- sheets_df(); h <- s[format(s$sheet_date) == tr_or(input$ex_sheet, ""), , drop = FALSE]; if (!nrow(h)) return(NULL); h <- h[1, ]
      lv <- levels_df(); lv <- lv[lv$sheet_id == h$sheet_id, , drop = FALSE]
      ncal <- sum(tr_pictures_for(evidence_df(), h$sheet_id)$slot %in% c("calendar_o", "calendar_t")) + length(pths("ms_cal_img_o")) + length(pths("ms_cal_img_t"))
      gap_box(tr_morning_gaps(h, lv, ncal), "Morning Sheet")
    })
    pdf_of <- function(builder, name) {   # build the Word file under its final name in a temp folder, then convert
      d <- tempfile("sheet_"); dir.create(d); f <- file.path(d, name); builder(f); p <- tr_docx_to_pdf(f, d); list(docx = f, pdf = p)
    }
    output$dlMorning <- downloadHandler(filename = function() tr_morning_filename(morning_day()), content = function(file) build_morning(file))
    output$dlTradeSheet <- downloadHandler(filename = function() trade_name("docx"), content = function(file) build_trade(file))
    output$dlMorningPdf <- downloadHandler(filename = function() tr_morning_filename(morning_day(), "pdf"),
      content = function(file) { r <- pdf_of(build_morning, tr_morning_filename(morning_day())); if (is.na(r$pdf)) stop("PDF conversion needs LibreOffice on this computer. Download the Word file and use Save as PDF."); file.copy(r$pdf, file, overwrite = TRUE) })
    output$dlTradeSheetPdf <- downloadHandler(filename = function() trade_name("pdf"),
      content = function(file) { r <- pdf_of(build_trade, trade_name("docx")); if (is.na(r$pdf)) stop("PDF conversion needs LibreOffice on this computer. Download the Word file and use Save as PDF."); file.copy(r$pdf, file, overwrite = TRUE) })
    sv_res <- reactiveVal(NULL)
    save_dbx <- function(builder, name, kind) {
      res <- save_built(builder, name, kind)
      sv_res(res); msg(if (all(res$ok)) "Saved." else "Some files were not saved: see the list below.", if (all(res$ok)) "message" else "warning")
    }
    observeEvent(input$sv_morning, save_dbx(function(f) build_morning(f), tr_morning_filename(morning_day()), "morning"))
    observeEvent(input$sv_trade, { save_dbx(function(f) build_trade(f), trade_name("docx"), "trade"); b <- save_blotter(); if (!is.null(b)) sv_res(rbind(sv_res(), b)) })
    output$sv_out <- renderUI({ r <- sv_res(); if (is.null(r)) return(NULL)
      tags$div(style = "font-size:12.5px; background:#f6f8fb; border-radius:8px; padding:8px 12px; margin:8px 0; color:#2c3e50;",
               lapply(seq_len(nrow(r)), function(i) tags$div(paste0(if (r$ok[i]) "✓ " else "✗ ", r$file[i], if (nzchar(r$where[i])) paste0(" → ", r$where[i]) else "", ": ", r$note[i])))) })

    # ---------------------------------------------------------------- morning sheet: read levels from IG screenshots
    if (is.null(vision_fn)) vision_fn <- function(images, prompt) api_manager$call_claude_vision(images, prompt)
    ms_read_df <- reactiveVal(NULL)
    apply_markets <- function(all) {
      fin <- function(v) if (is.finite(v)) v else NA
      for (k in seq_len(nrow(all))) { r <- all[k, ]
        if (identical(r$code, "DOW")) { updateNumericInput(session, "ms_dow", value = fin(r$cur)); updateNumericInput(session, "ms_dowc", value = fin(r$chg_pct)); updateNumericInput(session, "ms_dowp", value = fin(r$chg_pts)) }
        else if (identical(r$code, "JP225")) { updateNumericInput(session, "ms_nik", value = fin(r$cur)); updateNumericInput(session, "ms_nikc", value = fin(r$chg_pct)); updateNumericInput(session, "ms_nikp", value = fin(r$chg_pts)) }
        else {
          slots <- vapply(1:8, function(i) tr_or(input[[paste0("ml", i, "_inst")]], ""), "")
          i <- which(toupper(slots) == r$code)[1]
          if (is.na(i)) i <- which(!nzchar(slots) & !(seq_along(slots) %in% which(toupper(slots) %in% all$code)))[1]
          if (is.na(i)) { msg(paste0("No free row for ", r$name, ". Clear one of the extra rows first."), "warning"); next }
          updateSelectizeInput(session, paste0("ml", i, "_inst"), choices = tr_blank_choice(r$code), selected = r$code, options = list(create = TRUE))
          updateNumericInput(session, paste0("ml", i, "_low"), value = fin(r$low)); updateNumericInput(session, paste0("ml", i, "_high"), value = fin(r$high)); updateNumericInput(session, paste0("ml", i, "_cur"), value = fin(r$cur))
          if (!is.na(r$time)) updateTextInput(session, paste0("ml", i, "_time"), value = r$time)
        }
      }
      ms_read_df(all)
    }
    observeEvent(input$ms_read, {
      f <- input$ms_shots; if (is.null(f) || !NROW(f)) { msg("Select one or more screenshots first.", "warning"); return() }
      parts <- list()
      withProgress(message = "Reading the screenshots with Claude...", value = 0, {
        for (i in seq_len(nrow(f))) {
          incProgress(1 / nrow(f), detail = f$name[i])
          img <- tryCatch(tr_read_image(f$datapath[i], f$name[i]), error = function(e) { msg(paste0(f$name[i], ": ", conditionMessage(e)), "error"); NULL }); if (is.null(img)) next
          res <- tryCatch(vision_fn(list(list(media_type = img$media_type, data = img$data)), tr_morning_vision_prompt()),
                          error = function(e) { cat("[Records] Claude call failed:", conditionMessage(e), "\n"); msg(paste0(f$name[i], ": Claude could not read the image: ", conditionMessage(e)), "error"); NULL }); if (is.null(res)) next
          parsed <- tr_parse_vision_json(res$text)
          if (is.null(parsed)) { msg(paste0(f$name[i], ": the reply could not be read as values. Try a clearer screenshot."), "error"); next }
          parts[[length(parts) + 1]] <- tr_morning_assign(parsed)
        }
      })
      tryCatch(save_pictures(f$datapath, f$name, paste0("MS_", format(day_sel())), "market", NA, day_sel()), error = function(e) cat("[Records] market screenshots not stored:", conditionMessage(e), "\n"))
      parts <- Filter(function(d) NROW(d) > 0, parts)
      if (!length(parts)) { msg("No market prices were read.", "warning"); return() }
      all <- do.call(rbind, parts); all <- all[!duplicated(all$code, fromLast = TRUE), , drop = FALSE]
      apply_markets(all); msg(sprintf("%d market(s) read. Compare every value with the screenshot before saving.", nrow(all)))
    })
    output$ms_read_out <- renderUI({
      d <- ms_read_df(); if (is.null(d) || !nrow(d)) return(NULL)
      f <- function(v) ifelse(is.finite(v), format(v, trim = TRUE), "")
      tags$div(style = "font-size:12.5px; background:#f6f8fb; border-radius:8px; padding:8px 12px; margin-bottom:10px; color:#2c3e50;",
        tags$div(style = "font-weight:800; color:#002C3C; margin-bottom:4px;", "Read from the screenshots"),
        lapply(seq_len(nrow(d)), function(i) { r <- d[i, ]
          tags$div(paste0(r$name, " (", r$code, "): low ", f(r$low), ", high ", f(r$high), ", price ", f(r$cur), if (is.finite(r$chg_pct)) paste0(", change ", format(r$chg_pct), "%") else "", if (!is.na(r$time)) paste0(", time ", r$time) else "",
                          if (identical(r$basis, "candle")) "  [low/high are from one candle, not the overnight range: check]" else "")) }))
    })

    # ---------------------------------------------------------------- morning sheet: web search + calendar
    text_fn_in <- text_fn
    if (is.null(text_fn)) text_fn <- function(prompt) api_manager$call_claude_web(prompt, max_tokens = 6000, enable_web_search = TRUE,
                                                                                 system = "You are a careful market-data researcher. Report only values you found in a source, with that source. Never estimate.")
    web_src <- reactiveVal(NULL)   # data.frame(what, url, title) of the last web searches
    output$ms_web_src <- renderUI({
      d <- web_src(); if (is.null(d) || !nrow(d)) return(NULL)
      tags$details(style = "font-size:12px; background:#f6f8fb; border-radius:8px; padding:8px 12px; margin:6px 0; color:#2c3e50;",
        tags$summary(style = "font-weight:700; cursor:pointer;", sprintf("Web sources used (%d): open them to check the values", nrow(d))),
        lapply(seq_len(nrow(d)), function(i) tags$div(paste0(d$what[i], ": "), tags$a(href = d$url[i], target = "_blank", if (nzchar(d$title[i])) d$title[i] else d$url[i]))))
    })
    cal_o_df <- reactiveVal(NULL); cal_t_df <- reactiveVal(NULL)
    day_sel <- reactive({ d <- input$ms_date; if (is.null(d) || is.na(d)) tr_london_today() else as.Date(d) })
    ask_web <- function(prompt, what) {
      res <- tryCatch(text_fn(prompt), error = function(e) { cat("[Records] web search failed:", conditionMessage(e), "\n"); msg(paste0(what, ": Claude could not complete the search: ", conditionMessage(e)), "error"); NULL })
      if (is.null(res)) return(NULL)
      if (is.list(res) && is.data.frame(res$sources) && nrow(res$sources)) {
        web_src(rbind(web_src(), data.frame(what = what, url = res$sources$url, title = res$sources$title, stringsAsFactors = FALSE)))
        # kept in the evidence table (kind web_sources) so the References list of the report can cite them
        tryCatch(store$write("evidence", data.frame(evidence_id = tr_id("EV"), record_version = 1L, kind = "web_sources", status = "CONFIRMED", trade_id = paste0("MS_", format(day_sel())),
                                                    model = tr_or(res$model, NA_character_), extracted_json = as.character(jsonlite::toJSON(res$sources, auto_unbox = TRUE)), user_notes = what,
                                                    input_tokens = as.integer(tr_or(res$usage$input_tokens, NA)), output_tokens = as.integer(tr_or(res$usage$output_tokens, NA)), stringsAsFactors = FALSE)),
                 error = function(e) cat("[Records] web sources not saved:", conditionMessage(e), "\n"))
      }
      p <- tr_parse_vision_json(if (is.list(res)) res$text else res)
      if (is.null(p)) { msg(paste0(what, ": the reply could not be read. Try again."), "error"); return(NULL) }
      p
    }
    set_cal <- function(which, df, label) {
      if (which == "o") { cal_o_df(df); updateTextAreaInput(session, "ms_cal_o", value = tr_calendar_text(df)) } else { cal_t_df(df); updateTextAreaInput(session, "ms_cal_t", value = tr_calendar_text(df)) }
      msg(sprintf("%s calendar: %d event(s). Check them against the source before saving.", label, nrow(df)), if (nrow(df)) "message" else "warning")
    }
    observeEvent(input$ms_web_mk, {
      d <- day_sel()
      withProgress(message = "Claude is searching the web for market levels...", value = 0.3, {
        p <- ask_web(tr_morning_web_prompt(d), "Market levels"); if (is.null(p)) return()
        all <- tr_morning_assign(p); if (!NROW(all)) { msg("No market levels were found. Try again, or use screenshots.", "warning"); return() }
        apply_markets(all)
        hl <- tr_web_headlines(p$headlines); hl <- hl[!is.na(hl) & nzchar(hl)]
        if (length(hl)) {   # your own notes stay first; the web lines are added under them, labelled
          mine <- trimws(gsub("(?s)\\n?Found online \\(unverified\\).*$", "", tr_or(input$ms_news, ""), perl = TRUE))
          src <- unique(c(unlist(p$sources), if (is.data.frame(web_src())) head(web_src()$url, 3)))
          updateTextAreaInput(session, "ms_news", value = paste(c(if (nzchar(mine)) mine, paste0("Found online (unverified), ", format(d, "%d/%m/%Y"), ":"), paste("-", hl),
                                                                 paste0("Note: levels and headlines found online, not read from the IG platform. Sources: ", paste(src, collapse = ", "))), collapse = "\n"))
        }
        msg(sprintf("%d market(s) found online. They are approximate: compare with your IG platform before saving.", nrow(all)))
      })
    })
    observeEvent(input$ms_web_cal, {
      d <- day_sel()
      withProgress(message = "Claude is searching the web for the calendar...", value = 0, {
        incProgress(0.1, detail = "yesterday"); py <- ask_web(tr_calendar_web_prompt(d - 1, "yesterday"), "Yesterday's calendar")
        if (!is.null(py)) set_cal("o", tr_calendar_df(py), "Yesterday's")
        incProgress(0.5, detail = "today"); pt <- ask_web(tr_calendar_web_prompt(d, "today"), "Today's calendar")
        if (!is.null(pt)) set_cal("t", tr_calendar_df(pt), "Today's")
      })
    })
    observeEvent(input$ms_cal_read, {
      one <- function(f, which, label) {
        if (is.null(f) || !NROW(f)) return(invisible())
        parts <- list()
        for (i in seq_len(nrow(f))) {
          img <- tryCatch(tr_read_image(f$datapath[i], f$name[i]), error = function(e) { msg(paste0(f$name[i], ": ", conditionMessage(e)), "error"); NULL }); if (is.null(img)) next
          res <- tryCatch(vision_fn(list(list(media_type = img$media_type, data = img$data)), tr_calendar_vision_prompt()),
                          error = function(e) { msg(paste0(f$name[i], ": Claude could not read the image: ", conditionMessage(e)), "error"); NULL }); if (is.null(res)) next
          p <- tr_parse_vision_json(res$text); if (is.null(p)) { msg(paste0(f$name[i], ": the reply could not be read."), "error"); next }
          parts[[length(parts) + 1]] <- tr_calendar_df(p)
        }
        parts <- Filter(function(x) NROW(x) > 0, parts); if (length(parts)) set_cal(which, do.call(rbind, parts), label)
      }
      if (is.null(input$ms_cal_img_o) && is.null(input$ms_cal_img_t)) { msg("Select the calendar screenshot(s) first.", "warning"); return() }
      sid <- paste0("MS_", format(day_sel()))   # keep the pictures with this date's sheet, so the export finds them later (any computer)
      for (u in list(c("ms_cal_img_o", "calendar_o"), c("ms_cal_img_t", "calendar_t"))) { f <- input[[u[1]]]
        if (!is.null(f) && NROW(f)) tryCatch(save_pictures(f$datapath, f$name, sid, u[2], NA, day_sel()), error = function(e) cat("[Records] calendar pictures not stored:", conditionMessage(e), "\n")) }
      withProgress(message = "Reading the calendar screenshots with Claude...", value = 0.3, { one(input$ms_cal_img_o, "o", "Yesterday's"); one(input$ms_cal_img_t, "t", "Today's") })
    })
    # ---------------------------------------------------------------- morning sheet: overnight low / high from Yahoo
    ms_yahoo_res <- reactiveVal(NULL)
    observeEvent(input$ms_yahoo, {
      slots <- vapply(1:8, function(i) toupper(tr_or(input[[paste0("ml", i, "_inst")]], "")), "")
      ref <- setNames(vapply(1:8, function(i) tr_num(input[[paste0("ml", i, "_cur")]]), 0), slots); ref <- ref[nzchar(names(ref))]
      over <- isTRUE(input$ms_yahoo_over); fin <- function(v) if (is.finite(v)) v else NA
      y <- withProgress(message = "Fetching hourly prices from Yahoo Finance...", value = 0.4,
                        tryCatch(tr_yahoo_morning(slots[nzchar(slots)], day_sel(), now = Sys.time(), ref = ref, fetch = if (is.null(yahoo_fn)) tr_yahoo_fetch else yahoo_fn),
                                 error = function(e) { msg(paste("Yahoo:", conditionMessage(e)), "error"); NULL }))
      if (is.null(y)) return()
      rows <- y$rows; n <- 0L
      if (!is.null(rows)) for (k in seq_len(nrow(rows))) { r <- rows[k, ]; i <- which(slots == r$code)[1]; if (is.na(i)) next
        updateNumericInput(session, paste0("ml", i, "_low"), value = fin(r$low)); updateNumericInput(session, paste0("ml", i, "_high"), value = fin(r$high))
        if (over || !is.finite(tr_num(input[[paste0("ml", i, "_cur")]]))) { updateNumericInput(session, paste0("ml", i, "_cur"), value = fin(r$cur)); updateTextInput(session, paste0("ml", i, "_time"), value = r$time) }
        n <- n + 1L }
      set_idx <- function(x, p, pc, pp) if (!is.null(x) && (over || !is.finite(tr_num(input[[p]])))) {
        updateNumericInput(session, p, value = fin(x$price)); updateNumericInput(session, pc, value = fin(round(x$chg_pct, 2))); updateNumericInput(session, pp, value = fin(round(x$chg_pts, 2))) }
      set_idx(y$dow, "ms_dow", "ms_dowc", "ms_dowp"); set_idx(y$nikkei, "ms_nik", "ms_nikc", "ms_nikp")
      ms_yahoo_res(y)
      msg(sprintf("Yahoo: low/high filled for %d instrument(s)%s.", n, if (length(y$problems)) sprintf("; %d problem(s), see the list", length(y$problems)) else ""), if (length(y$problems)) "warning" else "message")
    })
    output$ms_yahoo_out <- renderUI({
      y <- ms_yahoo_res(); if (is.null(y)) return(NULL); r <- y$rows
      f <- function(v) ifelse(is.finite(v), format(signif(v, 7), trim = TRUE), "")
      tags$div(style = "font-size:12px; color:#2c3e50; margin-top:4px;",
        tags$div(paste("Window:", y$window)),
        if (!is.null(r)) lapply(seq_len(nrow(r)), function(i) tags$div(sprintf("%s: low %s, high %s, last %s at %s (%s%s)", tr_asset_label(r$code[i]), f(r$low[i]), f(r$high[i]), f(r$cur[i]), r$time[i], r$source[i],
                                                                       if (r$scale[i] != 1) sprintf(", x%s to match IG points", format(r$scale[i])) else ""))),
        if (!is.null(y$dow)) tags$div(sprintf("Dow Jones: %s (%+.2f, %+.2f%%), US session %s", f(y$dow$price), y$dow$chg_pts, y$dow$chg_pct, y$dow$session)),
        if (!is.null(y$nikkei)) tags$div(sprintf("Nikkei 225: %s (%+.2f, %+.2f%%), Tokyo session %s", f(y$nikkei$price), y$nikkei$chg_pts, y$nikkei$chg_pct, y$nikkei$session)),
        lapply(y$problems, function(p) tags$div(style = "color:#b45309;", paste("!", p))))
    })

    # the tables follow the text boxes (so a loaded sheet or a hand edit shows too)
    cal_show <- function(txt) { d <- tr_calendar_parse_text(txt); if (!nrow(d)) NULL else setNames(d, c("Time", "Country", "Importance", "Event", "Actual", "Forecast", "Previous")) }
    cal_dt <- function(txt) { d <- cal_show(txt); if (is.null(d)) return(DT::datatable(data.frame(Note = "No calendar yet: use the buttons above, or paste lines in the box below."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(d, rownames = FALSE, options = list(dom = "t", pageLength = 60, ordering = FALSE)) |> DT::formatStyle("Importance", color = DT::styleEqual(c("High", "Medium", "Low"), c("#c0392b", "#b9770e", "#7f8c8d")), fontWeight = "bold") }
    output$cal_tbl_o <- DT::renderDT(cal_dt(input$ms_cal_o)); output$cal_tbl_t <- DT::renderDT(cal_dt(input$ms_cal_t))

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
