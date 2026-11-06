# modules/cc_trading_records.R
# Trade Journal > "T Records C.C": the Trading Records workflow rebuilt on the Capital.com DEMO API.
# The original "Trading Records (BigQuery)" tab (modules/trading_records.R) is not changed in any way.
# What this tab does differently (the improvements listed in claude/U3_Trades_Tab_Review_2026-11-01.md):
#   * prices, fills, times, positions and P/L come from the Capital.com API, not from screenshots or Yahoo;
#   * every pattern of the matrix is found by R rules (utils_cc_patterns.R) with its measured record on this market;
#     Claude's reading is optional, shown apart and never counted;
#   * scenarios give BUY / SELL as market, limit or stop orders with the budget for the size YOU choose, and no
#     probability; choosing one copies levels only: no text is ever written into your own-words boxes;
#   * one pre-trade flow; the trade record is created from the broker's confirmation (entry = the fill);
#   * the account currency, the instrument currency and the conversion between them are shown everywhere money is.

cc_rec_lab <- function(x) tags$span(style = "color:#2c3e50; font-weight:600; font-size:12.5px;", x)
cc_rec_note <- function(...) tags$div(style = "font-size:12px; color:#64748b; margin:4px 0 10px 0; line-height:1.5;", ...)
cc_rec_box <- function(n, title, ..., tint = "#f8fafc") tags$div(style = sprintf("background:%s; border:1px solid #dbe3ea; border-left:5px solid #0f766e; border-radius:8px; padding:10px 14px; margin:10px 0 14px 0; color:#2c3e50;", tint),
  tags$div(style = "display:flex; align-items:center; gap:9px; margin-bottom:6px;",
    tags$span(style = "display:inline-flex; align-items:center; justify-content:center; width:25px; height:25px; border-radius:50%; background:#0f766e; color:#fff; font-weight:800; font-size:13px; flex:0 0 25px;", n),
    tags$h4(style = "color:#002C3C; font-weight:800; margin:0; font-size:15.5px;", title)), ...)
cc_rec_tile <- function(label, value, sub = NULL, colour = "#002C3C") tags$div(style = "flex:1 1 150px; background:#fff; border:1px solid #e2e8f0; border-top:4px solid #0f766e; border-radius:8px; padding:10px 12px; margin:0 8px 8px 0; min-width:140px;",
  tags$div(style = "font-size:11px; color:#64748b; text-transform:uppercase; letter-spacing:.4px;", label), tags$div(style = paste0("font-size:20px; font-weight:800; color:", colour, ";"), value),
  if (!is.null(sub)) tags$div(style = "font-size:11px; color:#64748b;", sub))
cc_fmt <- function(x, d = 2) ifelse(is.finite(x), formatC(x, format = "f", digits = d, big.mark = ","), "-")
cc_money <- function(x, ccy, d = 2) ifelse(is.finite(x), paste(ccy %||% "", formatC(x, format = "f", digits = d, big.mark = ",")), "-")
cc_windows <- c("6 h" = 6, "12 h" = 12, "24 h" = 24, "48 h" = 48, "72 h" = 72, "5 days" = 120, "7 days" = 168)
cc_candles <- c("5 min" = "MINUTE_5", "15 min" = "MINUTE_15", "30 min" = "MINUTE_30", "1 hour" = "HOUR", "4 hours" = "HOUR_4")

cc_trading_records_ui <- function(id, parts = FALSE) {
  ns <- NS(id); ta <- function(i, l, r = 2) textAreaInput(ns(i), cc_rec_lab(l), rows = r, width = "100%")
  num <- function(i, l, v = NA, ...) numericInput(ns(i), cc_rec_lab(l), v, ...)
  tagList(
    tags$div(style = "background: linear-gradient(135deg, #0b3b3a 0%, #0f766e 100%); border-radius: 12px; padding: 16px 22px; margin-bottom: 14px; color:#fff;",
      tags$h3(style = "margin:0 0 6px 0; font-size:19px; font-weight:800; color:#fff;", "T Records C.C: trading records on the Capital.com demo account"),
      tags$div(style = "font-size:13px; color:#d1fae5; line-height:1.6;",
        "Prices, orders, fills and P/L come straight from the Capital.com API; records go to the cc_ tables in BigQuery. ",
        "Patterns are found by fixed rules with their measured record on this market. Your set-up, trigger, execution, reasons, exit explanation and lessons stay yours: the app never writes them. ",
        "The original Trading Records tab is unchanged.")),
    uiOutput(ns("status_bar")),
    desk_tabbox(parts, width = 12, id = ns("tabs"),
      # ------------------------------------------------------------------------------------------- 1 SETUP
      tabPanel("1. Connection & Setup",
        cc_rec_note("Capital.com is connected in API Configuration > Capital.com (credentials file). BigQuery as for the other tabs. Without BigQuery, records stay in this session and are queued: press Sync pending once it is connected."),
        actionButton(ns("ensure"), "Create / verify the cc_ tables", icon = icon("database"), class = "btn-primary", style = "color:#fff; font-weight:700;"),
        actionButton(ns("sync_pending"), "Sync pending records", icon = icon("cloud-arrow-up")),
        actionButton(ns("reload"), "Reload from BigQuery", icon = icon("rotate")), uiOutput(ns("setup_msg")),
        tags$div(class = "cc-dup", tags$h4("Period and plan (from your own Task 1 plan)"),
        fluidRow(column(3, textInput(ns("s_name"), cc_rec_lab("Your name"), "Jose F Zubizarreta")), column(3, textInput(ns("s_id"), cc_rec_lab("LAT student ID"), "D1005749")),
                 column(3, dateInput(ns("s_start"), cc_rec_lab("Period start"), as.Date("2026-10-12"))), column(3, dateInput(ns("s_end"), cc_rec_lab("Period end"), as.Date("2026-11-06")))),
        fluidRow(column(3, num("s_risk", "Risk per trade (% of balance)", 1, step = 0.25)), column(3, num("s_cap", "Combined open-risk cap (%)", 2, step = 0.25)),
                 column(3, num("s_minrrr", "Minimum reward : risk", 1.5, step = 0.25))),
        fluidRow(column(3, num("s_adx_t", "ADX at or above = trend", 25)), column(3, num("s_adx_r", "ADX at or below = range", 20)))),
        tags$h4("Capital.com analysis"),
        fluidRow(column(3, num("s_balance", "Opening balance (account currency; empty = from the account)", NA, min = 0)),
                 column(3, num("s_hold", "Expected holding time (hours): measures each pattern's record", 10, min = 0.5, step = 0.5)),
                 column(3, num("s_hist_days", "History used to measure the patterns (days)", 20, min = 3, max = 60))),
        fluidRow(column(3, textInput(ns("s_on_from"), cc_rec_lab("Overnight range from (UK)"), "22:00")), column(3, textInput(ns("s_on_to"), cc_rec_lab("Overnight range to (UK)"), "06:00")),
                 column(3, textInput(ns("s_or_start"), cc_rec_lab("Opening range starts (UK)"), "08:00")), column(3, num("s_or_min", "Opening range length (minutes)", 60, min = 5))),
        tags$div(style = "background:#fefce8; border:1px solid #fde047; border-radius:8px; padding:8px 12px; margin:10px 0;",
          tags$h4(style = "margin:0 0 4px 0; color:#111827; font-weight:800;", "Trading plan rules, checked on every deal *"),
          cc_rec_note("From your structured trading plan (course Week 4 and Weeks 7-8). Each rule set here is checked on the deal ticket in 4. Plan & Order; empty = not checked. ",
                      "A deal that breaks a rule can only be sent with a written reason, which is saved with the trade."),
          fluidRow(column(4, textInput(ns("s_pl_markets"), cc_rec_lab("Markets allowed (Capital.com epics, comma separated)"), "OIL_BRENT")),
                   column(2, textInput(ns("s_pl_from"), cc_rec_lab("Session from (UK)"), "07:00")), column(2, textInput(ns("s_pl_to"), cc_rec_lab("Session to (UK)"), "20:00")), column(2, checkboxInput(ns("s_pl_anyhours"), "Allow deals outside these hours (any hour, e.g. Asia / US sessions) *****", TRUE)),
                   column(2, num("s_pl_maxday", "Maximum deals per day", 3, min = 1)), column(2, num("s_pl_maxloss", "Daily loss limit (% of balance)", 2, min = 0, step = 0.25))),
          fluidRow(column(3, num("s_pl_ctr", "Counter-trend: extra R:R needed (or half size)", 0.5, min = 0, step = 0.25)),
                   column(3, num("s_pl_news", "News window: minutes before / after a high-impact release", 30, min = 0, step = 5)),
                   column(6, selectizeInput(ns("s_pl_setups"), cc_rec_lab("Set-ups allowed by the plan * (empty = any)"), cc_setup_choices, multiple = TRUE))),
          fluidRow(column(3, num("s_pl_lossrow", "Stop for the day after this many losses in a row **", 2, min = 1)),
                   column(3, num("s_pl_filt_atr", "Break filter: close beyond the level by (x ATR) **", 0.1, min = 0, step = 0.05)),
                   column(3, num("s_pl_filt_n", "Break filter: candles held beyond it **", 1, min = 1)),
                   column(3, textInput(ns("s_rel_epics"), cc_rec_lab("Related markets (epics) **"), "OIL_CRUDE, DXY"))),
          tags$div(style = "font-weight:700; margin-top:4px;", "Your plan points (five checks from your own plan; each becomes a tick box on the ticket). The course Rule of Five is about time-frames and is checked on its own ****"),
          fluidRow(lapply(1:5, function(i) column(ifelse(i <= 3, 4, 6), textInput(ns(paste0("s_pl_r", i)), cc_rec_lab(paste("Point", i)), "")))),
          downloadButton(ns("pl_doc"), "Download my Trading Plan (Word) *")),
        actionButton(ns("save_settings"), "Save settings", icon = icon("floppy-disk"), class = "btn-success", style = "color:#fff; font-weight:700;"), uiOutput(ns("settings_msg"))),

      # ------------------------------------------------------------------------------------------- 2 MARKET & PATTERNS
      tabPanel("2. Market & Patterns",
        cc_rec_box(1, "Market",
          fluidRow(column(4, textInput(ns("m_search"), cc_rec_lab("Search Capital.com markets"), "Brent")),
                   column(2, tags$div(style = "margin-top:25px;", actionButton(ns("m_find"), "Search", icon = icon("magnifying-glass")))),
                   column(6, selectInput(ns("m_epic"), cc_rec_lab("Market (epic)"), choices = c("(search first)" = ""), width = "100%"))),
          uiOutput(ns("m_facts"))),
        cc_rec_box(2, "Chart & every pattern of the matrix", tint = "#f5f3ff",
          fluidRow(column(3, selectInput(ns("c_window"), cc_rec_lab("Chart window"), cc_windows, selected = 48)), column(3, selectInput(ns("c_res"), cc_rec_lab("Candle size"), cc_candles, selected = "MINUTE_15")),
                   column(3, radioButtons(ns("c_src"), cc_rec_lab("Candles from"), c("Capital.com" = "CC", "Yahoo" = "YAHOO"), selected = "CC", inline = TRUE),
                          conditionalPanel(sprintf("input['%s'] == 'YAHOO'", ns("c_src")), textInput(ns("c_ysym"), cc_rec_lab("Yahoo symbol (empty = matched to the market)"), "", placeholder = "e.g. BZ=F"))),
                   column(3, tags$div(style = "margin-top:25px;", actionButton(ns("c_load"), "Load chart & find patterns", icon = icon("chart-line"), class = "btn-primary", style = "color:#fff; font-weight:700;")))),
          cc_rec_note("Candles are Capital.com mid prices (between bid and offer). Indicators use the window plus 250 earlier candles, so EMA200 is real. Each pattern is also found throughout the history set in Setup, ",
                      "so its record shows how often price reached its target before its stop within your holding time on THIS market and candle size. Records with fewer than 8 cases are shown but not trusted."),
          uiOutput(ns("c_info")),
          fluidRow(column(8, tags$div(style = "background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:6px 10px;",
                     tags$div(style = "display:flex; align-items:center; gap:8px; margin-bottom:4px;", tags$b("Patterns drawn on the chart"),
                              actionButton(ns("c_all"), "All", class = "btn-xs"), actionButton(ns("c_none"), "None", class = "btn-xs")),
                     uiOutput(ns("c_boxes")))),
                   column(2, selectInput(ns("c_panel"), cc_rec_lab("Lower panel"), c("Auto (from the patterns)" = "auto", "RSI" = "RSI", "MACD" = "MACD", "ADX / DI" = "ADX", "Stochastic" = "Stochastic", "None" = "none"))),
                   column(2, checkboxInput(ns("c_levels"), cc_rec_lab("Cancel / target lines"), TRUE))),
          uiOutput(ns("c_pick_note")),
          plotly::plotlyOutput(ns("c_chart"), height = "640px"),
          cc_rec_note("Each pattern: its candles shaded, its shape, markers on its first and last candle, a numbered label, and its cancel / target lines named at the right. The camera icon on the chart saves it as a picture."),
          tags$div(style = "background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px; padding:8px 12px; margin:8px 0;",
            tags$div(style = "font-weight:800; color:#14532d; margin-bottom:4px;", "Save this scan"),
            cc_rec_note("Saves to BigQuery (cc_scans): every candle used, the settings, the regime, every pattern alive with its shape, cancel and target, the indicators of the shown window and the measured records of all 141 patterns. A saved scan can be reopened and redrawn exactly as it was."),
            fluidRow(column(6, textInput(ns("c_save_note"), cc_rec_lab("Note (optional, your words)"), "", width = "100%")),
                     column(3, tags$div(style = "margin-top:25px;", actionButton(ns("c_save"), "Save scan \u2192 BigQuery", icon = icon("floppy-disk"), class = "btn-success", style = "color:#fff; font-weight:700;")))),
            uiOutput(ns("c_save_out")),
            tags$div(style = "margin-top:4px;", downloadButton(ns("c_dl_pat"), "Patterns (CSV)"), downloadButton(ns("c_dl_bars"), "Candles + indicators (CSV)"),
                     downloadButton(ns("c_dl_json"), "Whole scan (JSON)"), downloadButton(ns("c_dl_html"), "Interactive chart (HTML)")),
            fluidRow(column(8, selectInput(ns("c_saved"), cc_rec_lab("Saved scans"), c("(none yet)" = ""), width = "100%")),
                     column(4, tags$div(style = "margin-top:25px;", actionButton(ns("c_open"), "Open saved scan", icon = icon("folder-open")))))),
          tags$h4("Patterns alive at the last candle"), DT::DTOutput(ns("c_active")),
          tags$div(style = "background:#fff; border:1px solid #ddd6fe; border-radius:8px; padding:8px 12px; margin:10px 0;",
            cc_rec_note("Optional: Claude reads the same candles and the R indicators, says whether it agrees with each finding and names anything it thinks the rules missed. Its additions are listed apart, ",
                        "checked (they must reach the last 10 candles with the stop and target on the right sides) and never counted in the facts tally or the records. It is never asked for a side or a probability."),
            tags$div(style = "border:1px solid #e5e7eb; border-radius:8px; padding:6px 10px; margin:6px 0; background:#fafafa;",
              tags$div(style = "font-weight:800; color:#002C3C;", "Claude analysis: course checks to include ***"),
              cc_rec_note("Pattern identification is always on. Tick what Claude should add; each check shows the LAT week and topic it comes from. R computes the numbers, Claude says what they mean."),
              cc_course_check_ui(ns("c_course")),
              actionButton(ns("c_course_all"), "Tick all"), actionButton(ns("c_course_none"), "Clear")),
            actionButton(ns("c_claude"), "Ask Claude for a second reading", icon = icon("robot")), uiOutput(ns("c_claude_out"))),
          tags$details(tags$summary(style = "cursor:pointer; font-weight:800; color:#002C3C;", "All 141 patterns of the matrix: rule, found now?, record on this market"),
                       downloadButton(ns("c_cov_dl"), "Download (CSV)"), DT::DTOutput(ns("c_cov")))),
        cc_rec_box(3, "Profile levels: POC, value area and initial balance **", tint = "#f0f9ff",
          cc_rec_note("Course Week 5. From the previous UK session of the loaded candles (volume when Capital.com gives it, otherwise time at each price = market profile) and today's initial balance (the opening range set in Setup). ",
                      "Drawn on the chart as dotted lines; used in Plan & Order to show whether a stop or target sits at one of them."), uiOutput(ns("c_profile"))),
        cc_rec_box(4, "Related markets **", tint = "#f8fafc",
          cc_rec_note("Course Week 2 (relative value, types of risk). The markets in Setup, on the same candles: move over the loaded window and correlation with this market (last 100 candles). ",
                      "Open positions in strongly correlated markets are counted together against your open-risk cap in the Plan check. Relative value ****: the ratio of this market to the first related one against its own average."), uiOutput(ns("c_related"))),
        cc_rec_box(5, "Rule of Five: minor, base and major time-frames ****", tint = "#fefce8",
          cc_rec_note("Course Week 7 (The Rule of Five). The loaded candle is the base time-frame; the minor and major are the nearest Capital.com candles to the course table. Position with the major trend, time entries on the base and minor; when all three agree, avoid counter-trend deals. Checked on the deal ticket."),
          uiOutput(ns("c_r5"))),
        cc_rec_box(6, "Support, resistance, pivots and Fibonacci ****", tint = "#f0fdf4",
          cc_rec_note("Course Week 1 (support and resistance on higher time-frames), Week 6 (7 pivot levels of the short-term traders' pivot point system, from the previous day) and Week 2 (Fibonacci retracements of the last swing)."),
          uiOutput(ns("c_sr"))),
        cc_rec_box(7, "Oscillators: stochastics and RSI divergence ****", tint = "#faf5ff",
          cc_rec_note("Course Week 3. Slow stochastics (14, 3, 3) and a divergence test between price and RSI over the last 30 candles."), uiOutput(ns("c_osc")))),

      # ------------------------------------------------------------------------------------------- 3 PLAN & ORDER
      tabPanel("3. Plan & Order",
        cc_rec_box(1, "Your money: account, currency and open risk", tint = "#ecfeff", uiOutput(ns("p_money"))),
        cc_rec_box(2, "Scenarios: BUY or SELL at the market (a deal, active at once)", tint = "#eef6f5",
          fluidRow(column(3, num("p_size", "Size you want (Capital.com units)", NA, min = 0)),
                   column(3, num("p_rrr", "Minimum Reward:Risk for these trades", 1.5, min = 0.5, step = 0.1)),
                   column(3, uiOutput(ns("p_size_help"))),
                   column(3, tags$div(style = "margin-top:25px;", actionButton(ns("p_build"), "Work out the scenarios", icon = icon("calculator"), class = "btn-primary", style = "color:#fff; font-weight:700;")))),
          cc_rec_note("Levels come from the patterns alive now (stop beyond the level that cancels the strongest in-regime pattern on that side, target at its measured target), else from the ATR template, which is labelled. ",
                      "Stop and target are shown as prices and as their distance from the price now. Chance target first, measured: how often, in this market's candles, price moved the target distance before the stop distance within your holding time (n = cases). Money is in your account currency at today's Capital.com exchange rate."),
          uiOutput(ns("p_scen_msg")), checkboxInput(ns("p_show_bad"), "Also show the scenarios that break my plan (red, cannot be used) *****", FALSE), DT::DTOutput(ns("p_scen")),
          fluidRow(column(8, uiOutput(ns("p_pick_ui"))), column(4, tags$div(style = "margin-top:25px;", actionButton(ns("p_use"), "Copy these levels into the order ticket", icon = icon("arrow-down"), class = "btn-success", style = "color:#fff; font-weight:700;")))),
          tags$div(style = "margin-top:8px; background:#faf5ff; border:1px solid #e9d5ff; border-radius:8px; padding:8px 12px;",
            tags$div(style = "font-weight:800; color:#5b21b6;", "Claude's suggested trades"),
            cc_rec_note("Claude reads the price now, the last 40 candles, the patterns with their records, your plan and, by default, today's Morning Sheet from BigQuery. Its trades are added to the table above (From = Claude) with the same checks, both chances and the money."),
            fluidRow(column(8, uiOutput(ns("p_ms_ui"))), column(4, tags$div(style = "margin-top:22px;", actionButton(ns("p_ms_reload"), "Look again for today's sheet", icon = icon("rotate"))))),
            actionButton(ns("p_claude"), "Ask Claude for suggested trades", icon = icon("robot"), class = "btn-primary", style = "color:#fff; font-weight:700; background:#6d28d9; border-color:#6d28d9;"),
            uiOutput(ns("p_claude_out")))),
        cc_rec_box(3, "Today's releases and the news window *", tint = "#fefce8",
          cc_rec_note("From today's Morning Sheet (BigQuery), with a short meaning of each release. High-impact releases inside your holding time (plus the news window set in Setup) are flagged and checked on the deal ticket. ",
                      "Meanings are short general notes written by the app, not the course's US Macro Crib Sheet text."),
          uiOutput(ns("p_news"))),
        cc_rec_box(5, "Investment risks of this deal ****", tint = "#fef2f2",
          cc_rec_note("Course Week 2 (types of investment risk). Worked out from the ticket below as you change it: market, liquidity, gap / weekend, overnight financing, leverage, event and correlation risk."),
          uiOutput(ns("p_risk"))),
        cc_rec_box(4, "Order ticket (DEMO)", tint = "#fff7ed",
          cc_rec_note("Every trade is a DEAL at the market: it opens at once at the price of the moment you send it and shows in Capital.com's Trades (never a waiting order). ",
                      "If the price has moved since the ticket was filled, the stop and the target move with it, keeping their distances, so your Reward:Risk stays the same."),
          fluidRow(column(3, radioButtons(ns("o_dir"), cc_rec_lab("Direction"), c("Buy" = "BUY", "Sell" = "SELL"), inline = TRUE)),
                   column(3, num("o_size", "Size", NA, min = 0)), column(3, num("o_stop", "Stop loss level")), column(3, num("o_target", "Target (limit) level"))),
          fluidRow(column(3, selectInput(ns("o_purpose"), cc_rec_lab("Assessed or practice?"), c("Practice trade" = "PRACTICE", "Assessed trade" = "ASSESSED")))),
          fluidRow(column(3, selectInput(ns("o_strategy"), cc_rec_lab("Strategy / set-up"), cc_setup_choices)),
                   column(3, textInput(ns("o_chart"), cc_rec_lab("Chart period"), "15 Min")), column(3, num("o_hours", "Expected duration (hours)", NA, min = 0)),
                   column(3, sliderInput(ns("o_mood"), cc_rec_lab("Mood (1-5)"), 1, 5, 3, step = 1))),
          fluidRow(column(3, sliderInput(ns("o_conf"), cc_rec_lab("Confidence in this trade (1-5) **"), 1, 5, 3, step = 1))),
          tags$div(style = "background:#fff; border:1px dashed #f59e0b; border-radius:8px; padding:8px 12px; margin:6px 0;",
            tags$div(style = "font-weight:800; color:#92400e; margin-bottom:4px;", "Your own words (the app never fills these)"),
            ta("o_fund", "Set-up (fundamental)"), ta("o_tech", "Set-up (technical)", 3),
            fluidRow(column(6, ta("o_trigger", "Trigger")), column(6, ta("o_exec", "Execution"))),
            fluidRow(column(6, ta("o_stopwhy", "Reason for stop-loss placement")), column(6, ta("o_tgtwhy", "Reason for target placement")))),
          uiOutput(ns("o_checks")),
          tags$div(style = "background:#fefce8; border:1px solid #fde047; border-radius:8px; padding:8px 12px; margin:6px 0;",
            tags$div(style = "font-weight:800; color:#111827;", "Plan check *"), uiOutput(ns("o_plan")),
            textAreaInput(ns("o_break"), cc_rec_lab("Reason for breaking a rule (needed only if a rule above fails; saved with the trade)"), "", rows = 2, width = "100%")),
          checkboxInput(ns("o_c_incl"), cc_rec_lab("Include the C analysis in this trade's Individual Trade Sheet (you can change it later in the Journal)"), TRUE),
          checkboxInput(ns("o_ok"), cc_rec_lab("I have checked the direction, size, levels and the money at risk"), FALSE),
          actionButton(ns("o_send"), "Open the deal on the DEMO account", icon = icon("paper-plane"), class = "btn-danger", style = "color:#fff; font-weight:800;"),
          uiOutput(ns("o_result"))),
        cc_rec_box(6, "My deals recorded in BigQuery: open now, and closed today *****", tint = "#ecfdf5",
          cc_rec_note("Every deal sent with the button above is written to BigQuery (cc_trades) as OPEN. Press the button to ask Capital.com about them: a deal that has closed (stop, target or by hand) is updated in BigQuery as CLOSED with its exit, result and code, and shows in the Positions and Statistics tabs. The same check runs from the Positions tab."),
          actionButton(ns("o_check"), "Check my recorded deals on Capital.com and update BigQuery", icon = icon("rotate")), uiOutput(ns("o_check_out")), DT::DTOutput(ns("o_open_tbl")))),

      # ------------------------------------------------------------------------------------------- 4 POSITIONS & ORDERS
      tabPanel("4. Positions & Orders",
        fluidRow(column(4, actionButton(ns("sync"), "Sync with Capital.com now", icon = icon("arrows-rotate"), class = "btn-primary", style = "color:#fff; font-weight:700;")),
                 column(8, checkboxInput(ns("auto_sync"), cc_rec_lab("Re-read positions and orders every 60 seconds while this tab is open"), FALSE))),
        cc_rec_note("Sync reads positions, working orders, the activity history (one day per request, as the API requires) and the transactions (the money Capital.com booked, in your account currency), ",
                    "saves new rows to cc_activity / cc_transactions, and updates your trades: orders that filled, positions that closed (exit level, exit code, P/L), stops moved on the platform, and positions opened on the platform."),
        uiOutput(ns("sync_out")),
        tags$h4("Open positions"), DT::DTOutput(ns("pos_tbl")),
        tags$div(style = "background:#f0fdf4; border:1px solid #bbf7d0; border-radius:8px; padding:8px 12px; margin:8px 0;",
          tags$div(style = "font-weight:800; color:#111827;", "Trailing stop suggestion: Wilder's Parabolic SAR **"),
          cc_rec_note("Course Week 6. For each open trade, the Parabolic SAR on 15-minute candles; suggested only when it is a better stop than the current one. Copy it into 'New stop' below to apply it."),
          uiOutput(ns("pos_sar"))),
        fluidRow(column(4, selectInput(ns("pos_pick"), cc_rec_lab("Position"), c("(none)" = ""))), column(2, num("pos_stop", "New stop")), column(2, num("pos_tgt", "New target")),
                 column(4, tags$div(style = "margin-top:25px;", actionButton(ns("pos_update"), "Change stop / target", icon = icon("pen")), actionButton(ns("pos_close"), "Close position", icon = icon("xmark"), class = "btn-warning")))),
        textInput(ns("pos_why"), cc_rec_lab("Why (your words, saved with the change)"), "", width = "100%"),
        tags$h4("Closed trades (last 14 days): open the trade in 6. Journal & Trade Sheet for its sheet"), DT::DTOutput(ns("closed_tbl")),
        tags$div(style = "background:#fffbeb; border:1px solid #fde68a; border-radius:8px; padding:8px 12px; margin:8px 0;",
          tags$div(style = "font-weight:800; color:#111827;", "Post-trade reflection ****"),
          cc_rec_note("Course Week 4 (trading psychology). Your own words after a trade closes, saved with the trade (event REFLECTION). Statistics shows results by whether the plan was followed."),
          fluidRow(column(4, selectInput(ns("rf_pick"), cc_rec_lab("Closed trade"), c("(none)" = ""))), column(3, selectInput(ns("rf_plan"), cc_rec_lab("Did I follow my plan?"), c("Yes", "Partly", "No"))),
                   column(5, selectInput(ns("rf_feel"), cc_rec_lab("How I felt after"), c("Calm", "Satisfied", "Frustrated", "Anxious", "Want to win it back", "Overconfident")))),
          textAreaInput(ns("rf_lesson"), cc_rec_lab("What I learned / will do differently"), "", width = "100%", rows = 2),
          actionButton(ns("rf_save"), "Save reflection", icon = icon("floppy-disk")), uiOutput(ns("rf_out"))),
        tags$h4("Working orders"), DT::DTOutput(ns("ord_tbl")),
        fluidRow(column(4, selectInput(ns("ord_pick"), cc_rec_lab("Order"), c("(none)" = ""))), column(4, tags$div(style = "margin-top:25px;", actionButton(ns("ord_cancel"), "Cancel order", icon = icon("ban"))))),
        uiOutput(ns("act_out"))),

      # ------------------------------------------------------------------------------------------- 5 JOURNAL
      tabPanel("5. Journal",
        selectInput(ns("j_trade"), cc_rec_lab("Trade"), c("(no trades yet)" = ""), width = "100%"),
        uiOutput(ns("j_facts")),
        uiOutput(ns("j_summary")),
        fluidRow(column(3, selectInput(ns("j_purpose"), cc_rec_lab("Assessed or practice?"), c("Practice trade" = "PRACTICE", "Assessed trade" = "ASSESSED"))),
                 column(3, textInput(ns("j_chart"), cc_rec_lab("Chart period"), "")), column(3, num("j_hours", "Expected duration (hours)", NA)),
                 column(3, selectInput(ns("j_code"), cc_rec_lab("Exit code"), cc_exit_codes))),
        ta("j_fund", "Set-up (fundamental)"), ta("j_tech", "Set-up (technical)", 3),
        fluidRow(column(6, ta("j_trigger", "Trigger")), column(6, ta("j_exec", "Execution"))),
        fluidRow(column(6, ta("j_stopwhy", "Reason for stop-loss placement")), column(6, ta("j_tgtwhy", "Reason for target placement"))),
        fluidRow(column(6, ta("j_why", "Reason for exit (after the exit code)", 3)), column(6, ta("j_lessons", "Lessons learned", 3))),
        ta("j_analysis", "Overall analysis", 4),
        fluidRow(column(3, radioButtons(ns("j_followed"), cc_rec_lab("Did you follow your plan?"), c("Yes" = "Y", "No" = "N"), inline = TRUE)),
                 column(3, selectInput(ns("j_devtype"), cc_rec_lab("Deviation type"), c("", "Moved stop", "Exited early", "Held past target/stop plan", "Entered without full trigger", "Ignored a signal", "Oversized / over risk cap", "Traded during stand-aside", "Other"))),
                 column(6, ta("j_devnote", "What happened and why"))),
        fluidRow(column(3, sliderInput(ns("j_mood"), cc_rec_lab("Mood at exit (1-5)"), 1, 5, 3, step = 1))),
        tags$div(style = "background:#f5f3ff; border:1px solid #ddd6fe; border-radius:8px; padding:8px 12px; margin:10px 0;",
          tags$div(style = "font-weight:800; color:#4c1d95;", "C analysis (C = Claude)"),
          cc_rec_note("C compares the trade it recommended (the scenario chosen when the order was placed, with the chart and patterns saved then) with what actually happened. ",
                      "It goes at the bottom of the Individual Trade Sheet as context, only if the box is ticked. You can edit it; it is saved with 'Save my entries to BigQuery'."),
          uiOutput(ns("j_rec")),
          fluidRow(column(8, ta("j_c", "C analysis", 6)),
                   column(4, checkboxInput(ns("j_c_incl"), cc_rec_lab("Include the C analysis in the sheet"), TRUE),
                          uiOutput(ns("j_c_ms_ui")),
                          actionButton(ns("j_c_write"), "Write the C analysis", icon = icon("wand-magic-sparkles"), style = "background:#7c3aed; color:#fff; font-weight:700;"),
                          uiOutput(ns("j_c_msg"))))),
        tags$div(style = "background:#eef6f5; border:1px solid #b2e0db; border-radius:8px; padding:8px 12px; margin:10px 0;",
          tags$div(style = "font-weight:800; color:#0b3b3a;", "Save and Individual Trade Sheet (LAT template)"),
          uiOutput(ns("j_where_sheet")),
          tags$div(style = "display:flex; flex-wrap:wrap; gap:6px; align-items:center;",
            actionButton(ns("j_save"), "Save my entries to BigQuery", icon = icon("database"), class = "btn-success", style = "color:#fff; font-weight:700;"),
            actionButton(ns("j_drop"), "Save the sheet to Dropbox (Word + PDF)", icon = icon("dropbox"), class = "btn-primary", style = "color:#fff; font-weight:700;"),
            uiOutput(ns("j_dl_ui"), inline = TRUE)),
          uiOutput(ns("j_msg")), uiOutput(ns("j_sheet_out"))),
        tags$hr(), tags$h4("All trades"), cc_rec_note("The CSV goes to your browser's Downloads folder; it is a copy of cc_trades (latest version of each trade)."), downloadButton(ns("j_dl"), "Download trades (CSV)"), DT::DTOutput(ns("j_tbl"))),

      # ------------------------------------------------------------------------------------------- 6 STATISTICS
      tabPanel("6. Statistics",
        fluidRow(column(3, selectInput(ns("st_scope"), cc_rec_lab("Trades"), c("All" = "ALL", "Assessed only" = "ASSESSED", "Practice only" = "PRACTICE")))),
        uiOutput(ns("st_tiles")), plotly::plotlyOutput(ns("st_equity"), height = "300px"),
        fluidRow(column(4, tags$h4("By direction"), tableOutput(ns("st_dir"))), column(4, tags$h4("By exit code"), tableOutput(ns("st_code"))), column(4, tags$h4("By strategy"), tableOutput(ns("st_strat")))),
        tags$div(style = "background:#fdf4ff; border:1px solid #f5d0fe; border-radius:8px; padding:8px 12px; margin:8px 0;",
          tags$div(style = "font-weight:800; color:#111827;", "Psychology: results by mood and after a loss **"),
          cc_rec_note("Course Week 4 (trading psychology) and the attitude survey. Mood and confidence are recorded on the ticket; the post-trade reflection **** is saved from the Positions tab (the Journal's lessons box stays yours). The Plan check stops the day after the losses in a row set in Setup."),
          fluidRow(column(6, tags$b("By mood at entry"), tableOutput(ns("ps_mood"))), column(6, tags$b("After a win / after a loss"), tableOutput(ns("ps_after")))),
          fluidRow(column(6, tags$b("By plan followed (post-trade reflection) ****"), tableOutput(ns("ps_plan"))), column(6, tags$b("Trading biases in your trades ****"), tableOutput(ns("ps_bias"))))),
        tags$div(style = "background:#f0f9ff; border:1px solid #bae6fd; border-radius:8px; padding:8px 12px; margin:8px 0;",
          tags$div(style = "font-weight:800; color:#111827;", "Attitude survey ****"),
          cc_rec_note("Course Introduction (attitude survey) and Week 4. A self-assessment on the course's psychology themes: 1 = never, 5 = always. The statements are written by the app, not copied from the LAT form. Each save is kept so you can see the change over the period."),
          fluidRow(lapply(seq_along(cc_attitude_items), function(i) column(6, sliderInput(ns(paste0("at_", i)), cc_rec_lab(cc_attitude_items[i]), 1, 5, 3, step = 1, width = "100%")))),
          actionButton(ns("at_save"), "Save my answers", icon = icon("floppy-disk")), uiOutput(ns("at_out"))),
        tags$h4("Pattern records on the market last loaded (target before stop within your holding time)"),
        cc_rec_note("From tab 3 (Market & Patterns)'s history. Expectancy in R = average result per case where a target is worth its reward:risk and a stop is -1. Small samples mislead: n is shown."),
        DT::DTOutput(ns("st_pat"))),

      # ------------------------------------------------------------------------------------------- 7 CURRENCY
      tabPanel("7. Currency & Budget",
        uiOutput(ns("fx_explain")),
        tags$h4("Closed trades: P/L the app estimated vs the amount Capital.com booked"), DT::DTOutput(ns("fx_cmp")),
        tags$h4("Transactions as booked by Capital.com"), DT::DTOutput(ns("fx_tx")),
        tags$h4("Balance snapshots"), plotly::plotlyOutput(ns("fx_bal"), height = "260px")),

      # ------------------------------------------------------------------------------------------- 8 SCHEMA
      tabPanel("8. Schema & SQL",
        cc_rec_note("Seven append-only tables in the BigQuery dataset of API Configuration > BigQuery, each with a _current view (latest row per key). The IG tables are not touched."),
        downloadButton(ns("ddl_dl"), "Download SQL (.sql)"), verbatimTextOutput(ns("ddl"))),
      tabPanel("9. Backtest & Blotter *",
        cc_rec_box(1, "Backtest of every pattern on the loaded chart *", tint = "#f5f3ff",
          cc_rec_note("Course: LAT backtesting workbook. Uses the market, candles and history loaded in 3. Market & Patterns: every past case of each pattern, entered at its signal, ",
                      "with its own stop and target, counted as target first (+R:R) or stop first (-1R) within your holding time. Trade only what has a positive expectancy over 20 cases or more."),
          uiOutput(ns("bt_sum")),
          tags$div(style = "font-weight:800; margin-top:6px;", "By strategy *"), cc_rec_note("Course strategies (Pivot Point System, Holy Grail, Straddle / opening range) and each family of patterns, all cases together."),
          DT::DTOutput(ns("bt_fam")), tags$div(style = "font-weight:800; margin-top:6px;", "By pattern"), DT::DTOutput(ns("bt_tbl"))),
        cc_rec_box(2, "Trade blotter (from your synced trades) *", tint = "#ecfeff",
          cc_rec_note("Course: Trade Blotter (Weeks 9-12). Built automatically from cc_trades; R = result divided by the money at risk at the stop."),
          uiOutput(ns("bl_sum")), downloadButton(ns("bl_xlsx"), "Download the LAT Trade Blotter (Excel, course layout) *"), downloadButton(ns("bl_csv"), "Download the blotter (CSV)"), DT::DTOutput(ns("bl_tbl"))))
    )
  )
}

cc_trading_records_server <- function(id, client, api_manager = NULL, store = NULL, vision_fn = NULL, fetch_bars = NULL, now_fn = Sys.time, morning_fn = NULL, yahoo_fn = NULL) {
  moduleServer(id, function(input, output, session) {
    `%||%` <- function(x, y) if (is.null(x) || !length(x) || (length(x) == 1 && is.na(x))) y else x   # NA counts as missing here
    if (is.null(store)) store <- cc_make_store(cc_bq_backend(api_manager))
    missing_vision <- is.null(vision_fn)
    if (is.null(vision_fn)) vision_fn <- function(prompt) api_manager$call_claude_vision(list(), prompt, system = "You check chart analysis. Reply with JSON only.")
    # the C analysis is prose, not JSON: same Claude connection, its own instruction (tests pass their own vision_fn)
    c_fn <- if (!is.null(api_manager) && missing_vision) function(prompt) api_manager$call_claude_vision(list(), prompt, system = "You are C, a trading coach in a trading-education app. Reply in plain English prose only, no JSON, no headings.") else vision_fn
    if (is.null(fetch_bars)) fetch_bars <- function(epic, res, from, to) cc_fetch_bars(client, epic, res, from, to)
    if (is.null(yahoo_fn)) yahoo_fn <- function(symbol, range, interval) tr_yahoo_fetch(symbol, range, interval)
    bump <- reactiveVal(0); touch <- function() bump(isolate(bump()) + 1)
    note <- function(txt, type = "message") showNotification(txt, type = type, duration = 6)
    ready <- function() { if (!client$connected()) { note("Connect Capital.com first (API Configuration > Capital.com).", "warning"); FALSE } else TRUE }
    tbl <- function(name) { bump(); tryCatch(store$current(name), error = function(e) cc_coerce(name, NULL)) }
    trades <- reactive(tbl("trades"))

    # ---- settings ----------------------------------------------------------------------------------------------
    settings_df <- reactive(tbl("settings"))
    pl_txt <- c("s_pl_markets", "s_pl_from", "s_pl_to", paste0("s_pl_r", 1:5), "s_rel_epics", "s_pl_anyhours"); pl_num <- c("s_pl_maxday", "s_pl_maxloss", "s_pl_ctr", "s_pl_news", "s_pl_lossrow", "s_pl_filt_atr", "s_pl_filt_n")
    sv <- function(k, d = NA) { s <- settings_df(); v <- s$setting_value[s$setting_key == k]; if (length(v) && !is.na(v[1])) v[1] else d }
    observe({ s <- settings_df(); if (!nrow(s)) return()
      v <- sv("rec_s_pl_anyhours"); if (!is.na(v)) updateCheckboxInput(session, "s_pl_anyhours", value = toupper(v) %in% c("TRUE", "1"))
      for (k in c("s_name", "s_id", "s_on_from", "s_on_to", "s_or_start", setdiff(pl_txt, "s_pl_anyhours"))) { v <- sv(paste0("rec_", k)); if (!is.na(v)) updateTextInput(session, k, value = v) }
      for (k in c("s_balance", "s_risk", "s_cap", "s_minrrr", "s_adx_t", "s_adx_r", "s_hold", "s_hist_days", "s_or_min", pl_num)) { v <- suppressWarnings(as.numeric(sv(paste0("rec_", k)))); if (is.finite(v)) updateNumericInput(session, k, value = v) }
      for (k in c("s_start", "s_end")) { v <- sv(paste0("rec_", k)); if (!is.na(v)) updateDateInput(session, k, value = as.Date(v)) }
      v <- sv("cc_default_search"); if (!is.na(v)) updateTextInput(session, "m_search", value = v)
      v <- sv("rec_s_pl_setups"); if (!is.na(v)) updateSelectizeInput(session, "s_pl_setups", selected = strsplit(v, ",", fixed = TRUE)[[1]])
      v <- sv("rec_c_course"); if (!is.na(v)) updateCheckboxGroupInput(session, "c_course", selected = strsplit(v, ",", fixed = TRUE)[[1]]); course_loaded(TRUE) })
    course_loaded <- reactiveVal(FALSE)
    observeEvent(input$save_settings, {
      ks <- c("s_name", "s_id", "s_start", "s_end", "s_balance", "s_risk", "s_cap", "s_minrrr", "s_adx_t", "s_adx_r", "s_hold", "s_hist_days", "s_on_from", "s_on_to", "s_or_start", "s_or_min", pl_txt, pl_num)
      df <- data.frame(setting_key = paste0("rec_", ks), setting_value = vapply(ks, function(k) { v <- input[[k]]; if (is.null(v) || !length(v)) NA_character_ else as.character(v) }, ""), stringsAsFactors = FALSE)
      df <- rbind(df, data.frame(setting_key = "rec_s_pl_setups", setting_value = paste(input$s_pl_setups %||% character(0), collapse = ","), stringsAsFactors = FALSE))
      w <- store$write("settings", df); touch(); output$settings_msg <- renderUI(tags$div(style = "color:#16a34a; margin-top:6px;", icon("check"), " Settings saved (", w, ")."))
    })
    plan <- reactive(list(risk = input$s_risk, cap = input$s_cap, min_rrr = input$s_minrrr, adx_t = input$s_adx_t, adx_r = input$s_adx_r, hold = input$s_hold))
    observeEvent(input$ensure, { r <- tryCatch({ store$ensure(); "The cc_ tables and their _current views are ready." }, error = function(e) paste("Failed:", conditionMessage(e)))
      output$setup_msg <- renderUI(tags$div(style = "margin-top:6px;", r)) })
    observeEvent(input$sync_pending, { r <- tryCatch(sprintf("%d row(s) written to BigQuery.", store$sync()), error = function(e) conditionMessage(e)); touch(); output$setup_msg <- renderUI(tags$div(style = "margin-top:6px;", r)) })
    observeEvent(input$reload, { store$invalidate(); touch(); note("Reloaded from BigQuery.") })
    output$status_bar <- renderUI({ invalidateLater(5000); bump(); s <- client$status()
      chip <- function(ok, txt) tags$span(style = sprintf("display:inline-block; padding:3px 10px; border-radius:999px; margin-right:6px; font-size:12px; font-weight:700; background:%s; color:%s;",
                                                           if (ok) "#dcfce7" else "#fee2e2", if (ok) "#166534" else "#991b1b"), txt)
      tags$div(style = "margin-bottom:8px;", chip(s$connected, if (s$connected) sprintf("Capital.com %s connected, account %s (%s)", toupper(s$environment), s$account_id, s$currency) else "Capital.com not connected"),
               chip(store$connected(), if (store$connected()) "BigQuery connected" else "BigQuery not connected: records kept in this session"),
               if (store$pending_count()) chip(FALSE, sprintf("%d record(s) waiting for BigQuery", store$pending_count()))) })

    # ---- account & currency ------------------------------------------------------------------------------------
    acct <- reactiveVal(NULL)
    read_account <- function() { if (!client$connected()) return(NULL)
      a <- tryCatch(cc_accounts_df(client$accounts()), error = function(e) { note(conditionMessage(e), "error"); NULL }); if (is.null(a) || !nrow(a)) return(NULL)
      r <- a[a$account_id %in% (client$account_id() %||% a$account_id[1]), , drop = FALSE]; if (!nrow(r)) r <- a[1, , drop = FALSE]
      r <- r[1, ]; r$read_at <- now_fn(); acct(r)   # read_at changes every time, so the tiles always redraw
      cat(sprintf("[C.C] balance read: %s %s, available %s\n", r$currency, format(r$balance, nsmall = 2), format(r$available, nsmall = 2))); r }
    fx_cache <- new.env(parent = emptyenv())
    fx_info <- function(from, to) { if (is.na(from) || is.na(to)) return(list(rate = NA_real_, how = "currency unknown"))
      k <- paste(from, to); hit <- if (exists(k, envir = fx_cache)) get(k, envir = fx_cache) else NULL
      if (!is.null(hit) && as.numeric(difftime(now_fn(), hit$time, units = "mins")) < 10) return(hit)
      v <- cc_fx_rate(client, from, to); assign(k, v, envir = fx_cache); v }

    # ---- market search & facts ---------------------------------------------------------------------------------
    mkt <- reactiveVal(NULL)
    observeEvent(input$m_find, { if (!ready()) return()
      m <- tryCatch(client$search_markets(input$m_search), error = function(e) { note(conditionMessage(e), "error"); list() })
      if (!length(m)) { updateSelectInput(session, "m_epic", choices = c("(nothing found)" = "")); return() }
      ch <- setNames(vapply(m, function(z) cc_chr(z$epic), ""), vapply(m, function(z) sprintf("%s  [%s, %s]", cc_chr(z$instrumentName), cc_chr(z$epic), cc_chr(z$instrumentType)), ""))
      pref <- sv("cc_default_epic"); updateSelectInput(session, "m_epic", choices = ch, selected = if (!is.na(pref) && pref %in% ch) pref else ch[1]) })
    observeEvent(input$m_epic, { ep <- input$m_epic; if (!nzchar(ep %||% "") || !client$connected()) return()
      f <- tryCatch(cc_market_facts(client$market(ep)), error = function(e) { note(conditionMessage(e), "error"); NULL }); mkt(f); read_account() }, ignoreInit = TRUE)
    output$m_facts <- renderUI({ f <- mkt(); if (is.null(f)) return(cc_rec_note("Search, then choose the market. Its contract details come from Capital.com."))
      a <- acct(); acc_ccy <- if (is.null(a)) NA else a$currency; fx <- fx_info(f$currency, acc_ccy)
      spr <- f$offer - f$bid
      tags$div(style = "display:flex; flex-wrap:wrap;",
        cc_rec_tile("Market", f$name %||% f$epic, sprintf("%s | %s | %s", f$epic, f$type %||% "-", f$status %||% "-")),
        cc_rec_tile("Bid / Offer", sprintf("%s / %s", cc_fmt(f$bid, 3), cc_fmt(f$offer, 3)), sprintf("Spread %s", cc_fmt(spr, 3))),
        cc_rec_tile("Quoted in", f$currency %||% "?", sprintf("Your account is in %s", acc_ccy %||% "?")),
        cc_rec_tile("Exchange rate", if (is.finite(fx$rate)) sprintf("1 %s = %s %s", f$currency, cc_fmt(fx$rate, 5), acc_ccy) else "—", fx$how),
        cc_rec_tile("Contract", sprintf("lot %s", cc_fmt(f$lot_size, 2)), sprintf("unit %s | min size %s | min stop distance %s", f$unit %||% "-", cc_fmt(f$min_size, 2), cc_fmt(f$min_stop_distance, 3))),
        cc_rec_tile("Margin", if (is.finite(f$margin_factor)) paste(cc_fmt(f$margin_factor, 2), f$margin_unit %||% "") else "not given", "from Capital.com's market details")) })

    # ---- chart & patterns --------------------------------------------------------------------------------------
    scan <- reactiveVal(NULL); scan_meta <- reactiveVal(NULL)
    observeEvent(input$c_load, { if (!ready()) return(); f <- mkt(); if (is.null(f)) { note("Choose the market first.", "warning"); return() }
      res <- input$c_res; mins <- cc_res_minutes[[res]]; win_h <- as.numeric(input$c_window); hist_d <- max(3, tr_num0(input$s_hist_days, 20))
      to <- now_fn(); from <- to - max(hist_d * 86400, (win_h * 60 / mins + 260) * mins * 60)
      out <- withProgress(message = "Reading Capital.com prices and finding patterns...", value = 0.1, tryCatch({
        yahoo <- identical(input$c_src, "YAHOO"); ysym <- NA_character_; yshift <- 0
        if (yahoo) { ysym <- trimws(input$c_ysym %||% ""); if (!nzchar(ysym)) ysym <- cc_yahoo_symbol(f$epic, f$name)
          if (is.na(ysym)) stop("No Yahoo symbol is known for ", f$epic, ": type one (e.g. BZ=F for Brent).")
          yb <- cc_yahoo_bars(yahoo_fn, ysym, res, hist_d); mid <- mean(c(f$bid, f$offer)); yshift <- if (is.finite(mid)) mid - utils::tail(yb$close, 1) else 0
          b <- yb; b[c("open", "high", "low", "close")] <- b[c("open", "high", "low", "close")] + yshift
          note(sprintf("Yahoo %s candles, shifted by %+.3f so the last close matches Capital.com's price now: patterns are found on Yahoo's shape, orders use Capital.com's prices.", ysym, yshift), "message") }
        else b <- fetch_bars(f$epic, res, from, to)
        if (length(attr(b, "refused"))) note(sprintf("Capital.com did not accept part of the date range; %d candles were read (from %s UK).", nrow(b), format(min(b$time), "%d/%m %H:%M", tz = "Europe/London")), "warning")
        if (nrow(b) < 60) stop("Capital.com returned only ", nrow(b), " candles for this market and candle size.")
        dly <- tryCatch(cc_prices_to_bars(client$prices(f$epic, "DAY", max = 15)), error = function(e) NULL); daily_last(dly)
        if (nrow(b) < 60) stop("Only ", nrow(b), " candles were read.")
        setProgress(0.3); sf <- max(1L, nrow(b) - as.integer(round(win_h * 60 / mins)) + 1L)
        sc <- cc_scan(b, mins, list(adx_trend = input$s_adx_t, adx_range = input$s_adx_r, horizon = max(4L, as.integer(round(tr_num0(input$s_hold, 10) * 60 / mins))),
                                    on_from = input$s_on_from, on_to = input$s_on_to, or_start = input$s_or_start, or_minutes = tr_num0(input$s_or_min, 60)),
                      daily = dly, show_from = sf, progress = function(v) setProgress(0.3 + 0.6 * v))
        list(scan = sc, meta = list(epic = f$epic, name = f$name, res = res, mins = mins, window = win_h, bars = nrow(b), source = if (yahoo) sprintf("Yahoo %s (shifted %+.3f)", ysym, yshift) else "Capital.com", from = min(b$time), to = max(b$time), loaded_at = format(now_fn(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))) },
        error = function(e) { note(conditionMessage(e), "error"); NULL }))
      if (is.null(out)) return(); scan(out$scan); scan_meta(out$meta)
      refresh_pick(out$scan); c_saved_msg(NULL)   # every pattern alive is ticked (drawn); untick any you do not want
      cat(sprintf("[C.C] %s %s (%s): %d candles, %d patterns alive, regime %s\n", f$epic, res, out$meta$source, out$meta$bars, nrow(out$scan$current_df), out$scan$regime)) })
    # one checkbox per pattern alive, numbered as on the chart, with its bias colour, status and record; all ticked on load
    chosen <- reactiveVal(character(0))
    refresh_pick <- function(sc, first = FALSE, all = TRUE) chosen(if (nrow(sc$current_df)) sc$current_df$key else character(0))
    output$c_boxes <- renderUI({ s <- scan(); if (is.null(s)) return(tags$div(style = "font-size:12px; color:#64748b;", "Load the chart first."))
      cd <- s$current_df; if (!nrow(cd)) return(tags$div(style = "font-size:12px; color:#64748b;", "No pattern alive at the last candle."))
      lab <- lapply(seq_len(nrow(cd)), function(k) { col <- cc_bias_col(cd$bias[k])
        tags$span(tags$span(style = sprintf("display:inline-block; min-width:74px; font-weight:800; color:#fff; background:%s; border-radius:4px; padding:0 5px; margin-right:6px; text-align:center;",
                                     if (cd$strength[k] >= 60) "#15803d" else if (cd$strength[k] >= 45) "#ca8a04" else "#94a3b8"), sprintf("Strength %d", cd$strength[k])),
                  tags$b(style = sprintf("color:%s;", col), sprintf("%d. %s", k, cd$label[k])),
                  tags$span(style = "color:#475569;", sprintf(" | %s | %s | Step %d%s%s", cd$bias[k], cd$status[k], cd$step[k], if (cd$in_regime[k]) "" else " | outside regime",
                    if (cd$hist_n[k] >= 1) sprintf(" | target first %s%%, n=%d", ifelse(is.finite(cd$hist_win[k]), round(cd$hist_win[k]), "-"), cd$hist_n[k]) else ""))) })
      tagList(tags$div(style = "font-size:11.5px; color:#64748b; margin-bottom:3px;", "Strongest first. Strength 0-100 = measured record on this market (small samples pulled towards 50%), expectancy in R, in regime or not, status. Context rows with no side stay at 50 or below."),
      checkboxGroupInput(session$ns("c_pick"), NULL, choiceNames = lab, choiceValues = cd$key, selected = isolate(chosen()), width = "100%")) })
    observeEvent(input$c_pick, chosen(input$c_pick %||% character(0)), ignoreNULL = FALSE, ignoreInit = TRUE)
    observeEvent(input$c_all, { s <- scan(); if (is.null(s)) return(); chosen(s$current_df$key); updateCheckboxGroupInput(session, "c_pick", selected = s$current_df$key) })
    observeEvent(input$c_none, { chosen(character(0)); updateCheckboxGroupInput(session, "c_pick", selected = character(0)) })
    picks <- reactive({ s <- scan(); if (is.null(s)) return(list()); ks <- chosen()
      Filter(Negate(is.null), lapply(which(s$current_df$key %in% ks), function(i) { k <- s$current_df$key[i]; o <- Filter(function(z) z$key == k, s$current)
        if (length(o)) { o <- o[[1]]; o$num <- i; o } else NULL })) })   # num = its number in the list, the same on the chart
    pick <- reactive({ p <- picks(); if (length(p)) p[[1]] else NULL })
    output$c_info <- renderUI({ s <- scan(); m <- scan_meta(); if (is.null(s)) return(cc_rec_note("Press 'Load chart & find patterns'."))
      col <- switch(s$regime, TREND = "#1d4ed8", RANGE = "#a16207", "#475569")
      tagList(cc_rec_note(sprintf("%s: %d candles of %s from %s to %s UK (the last %s shown; the rest is warm-up and history for the records).", m$name %||% m$epic, m$bars, names(cc_candles)[cc_candles == m$res],
                                  format(m$from, "%d/%m %H:%M", tz = "Europe/London"), format(m$to, "%d/%m %H:%M", tz = "Europe/London"), names(cc_windows)[cc_windows == m$window])),
        tags$div(style = sprintf("border-left:4px solid %s; background:#fff; padding:6px 10px; margin-bottom:6px; font-size:13px;", col),
          tags$b(sprintf("Regime: %s", s$regime)), sprintf(" (ADX(14) %s; trend at or above %s, range at or below %s). ", cc_fmt(s$adx, 1), input$s_adx_t, input$s_adx_r),
          if (s$regime == "MIXED") "Between your thresholds: by your plan, no trend and no range trade. " else "", s$tally$text)) })
    output$c_pick_note <- renderUI({ ps <- picks(); if (!length(ps)) return(NULL)
      tags$div(style = "font-size:12.5px; margin:4px 0 6px 0; display:flex; flex-wrap:wrap; gap:8px;", lapply(seq_along(ps), function(k) { p <- ps[[k]]; r <- cc_cat_row(p$key); col <- cc_bias_col(r$bias)
        tags$div(style = sprintf("flex:1 1 300px; border-left:4px solid %s; background:#fff; padding:4px 8px;", col),
          tags$b(style = sprintf("color:%s;", col), sprintf("%d. %s", k, r$label)), sprintf(" [Step %d, %s, %s]. ", r$step, r$bias, p$status), p$note, ".",
          tags$div(sprintf("Cancels beyond %s%s | target %s", cc_fmt(p$invalid, 3), if (isTRUE(p$atr_default)) " (ATR template)" else "", cc_fmt(p$target, 3))),
          tags$div(style = "color:#64748b;", tags$b("Rule: "), r$rule)) })) })
    output$c_chart <- plotly::renderPlotly({ s <- scan(); if (is.null(s)) return(plotly::plotly_empty(type = "scatter", mode = "markers"))
      m <- scan_meta(); g <- cc_chart(s, picks(), title = chart_title(), panel = input$c_panel %||% "auto", show_levels = isTRUE(input$c_levels %||% TRUE))
      pf <- prof(); if (is.null(pf)) return(g)   # ** profile levels as dotted lines
      lv <- c(POC = pf$poc, VAH = pf$vah, VAL = pf$val, `IB high` = pf$ib_hi, `IB low` = pf$ib_lo); lv <- lv[is.finite(lv)]
      x0 <- min(s$ctx$b$time[s$show_from:s$n]); x1 <- max(s$ctx$b$time)
      new <- lapply(names(lv), function(k) list(type = "line", xref = "x", yref = "y", x0 = x0, x1 = x1, y0 = lv[[k]], y1 = lv[[k]], line = list(dash = "dot", width = 1, color = if (startsWith(k, "IB")) "#0369a1" else "#7c3aed")))
      lab <- lapply(names(lv), function(k) list(x = x1, y = lv[[k]], xref = "x", yref = "y", text = k, showarrow = FALSE, xanchor = "left", font = list(size = 10, color = "#7c3aed")))
      g$x$layout$shapes <- c(g$x$layout$shapes, new); g$x$layout$annotations <- c(g$x$layout$annotations, lab)
      g })
    chart_title <- function() { m <- scan_meta(); sprintf("%s, %s candles (Capital.com mid prices)%s", m$name %||% m$epic, names(cc_candles)[cc_candles == m$res],
                                                          if (isTRUE(m$restored)) sprintf(" | saved scan of %s UK", format(m$to, "%d/%m %H:%M", tz = "Europe/London")) else "") }
    # ---- save / reopen / download the scan
    c_saved_msg <- reactiveVal(NULL); daily_last <- reactiveVal(NULL)
    scan_settings <- function() list(adx_trend = input$s_adx_t, adx_range = input$s_adx_r, horizon = max(4L, as.integer(round(tr_num0(input$s_hold, 10) * 60 / (scan_meta()$mins %||% 15)))),
                                     on_from = input$s_on_from, on_to = input$s_on_to, or_start = input$s_or_start, or_minutes = tr_num0(input$s_or_min, 60))
    payload <- function() { s <- scan(); m <- scan_meta(); cc_scan_payload(s, m[setdiff(names(m), "restored")], if (isTRUE(m$restored)) m$settings else scan_settings(), daily_last()) }
    save_scan <- function(trade_id = NA_character_, note = "") { s <- scan(); m <- scan_meta(); if (is.null(s)) return(NA_character_); id <- cc_id("SC"); pl <- payload(); pl$note <- note
      cur <- s$current_df[, intersect(names(s$current_df), c("key", "label", "step", "bias", "status", "dir", "entry", "invalid", "target", "in_regime", "candles_ago", "hist_n", "hist_win", "hist_exp_r", "note"))]
      w <- store$write("scans", data.frame(scan_id = id, trade_id = trade_id, epic = m$epic, resolution = m$res, n_candles = s$n, last_candle_utc = max(s$ctx$b$time), regime = s$regime, adx = s$adx,
                                          current_json = cc_json(cur), bars_json = cc_json(pl)))
      cat(sprintf("[C.C] scan %s saved (%s): %d candles, %d patterns\n", id, w, s$n, nrow(s$current_df))); touch(); attr(id, "where") <- w; id }
    observeEvent(input$c_save, { if (is.null(scan())) { note("Load a chart first.", "warning"); return() }
      id <- tryCatch(save_scan(note = input$c_save_note %||% ""), error = function(e) { c_saved_msg(list(FALSE, conditionMessage(e))); NULL })
      if (!is.null(id)) c_saved_msg(list(TRUE, sprintf("Saved as %s (%s) at %s UK.", id, attr(id, "where"), format(now_fn(), "%H:%M:%S", tz = "Europe/London")))) })
    output$c_save_out <- renderUI({ m <- c_saved_msg(); if (is.null(m)) return(NULL); tags$div(style = sprintf("font-weight:700; color:%s;", if (m[[1]]) "#166534" else "#b91c1c"), m[[2]]) })
    observe({ x <- tbl("scans"); if (!nrow(x)) { updateSelectInput(session, "c_saved", choices = c("(none yet)" = "")); return() }
      x <- x[order(x$saved_at, decreasing = TRUE), , drop = FALSE]
      updateSelectInput(session, "c_saved", choices = setNames(x$scan_id, sprintf("%s | %s %s | last candle %s UK | %s, %d patterns%s", format(x$saved_at, "%d/%m %H:%M", tz = "Europe/London"), x$epic, x$resolution,
        format(x$last_candle_utc, "%d/%m %H:%M", tz = "Europe/London"), x$regime, vapply(x$current_json, function(j) tryCatch(NROW(jsonlite::fromJSON(j)), error = function(e) 0L), 0L),
        ifelse(is.na(x$trade_id), "", paste(" | trade", x$trade_id))))) })
    observeEvent(input$c_open, { x <- tbl("scans"); r <- x[x$scan_id == (input$c_saved %||% ""), , drop = FALSE]; if (!nrow(r)) return()
      out <- withProgress(message = "Redrawing the saved scan...", value = 0.5, tryCatch(cc_scan_restore(r$bars_json[1]), error = function(e) { note(conditionMessage(e), "error"); NULL }))
      if (is.null(out)) return(); m <- out$meta; m$restored <- TRUE; m$settings <- out$saved$settings; m$to <- max(out$scan$ctx$b$time)
      scan(out$scan); scan_meta(m); refresh_pick(out$scan, all = TRUE)
      c_saved_msg(list(TRUE, sprintf("Showing saved scan %s exactly as saved (view only: 'Load chart & find patterns' brings back live prices).", r$scan_id[1]))) })
    dl_name <- function(what, ext) { m <- scan_meta(); sprintf("cc_scan_%s_%s_%s_%s.%s", m$epic %||% "market", m$res %||% "", format(m$to %||% Sys.time(), "%Y%m%d_%H%M", tz = "Europe/London"), what, ext) }
    output$c_dl_pat <- downloadHandler(filename = function() dl_name("patterns", "csv"), content = function(f) { s <- scan(); req(s)
      d <- s$current_df; d$label <- d$label; utils::write.csv(d, f, row.names = FALSE) })
    output$c_dl_bars <- downloadHandler(filename = function() dl_name("candles_indicators", "csv"), content = function(f) { s <- scan(); req(s); ix <- s$show_from:s$n
      utils::write.csv(cbind(time_utc = format(s$ctx$b$time[ix], "%Y-%m-%d %H:%M"), time_uk = format(s$ctx$b$time[ix], "%Y-%m-%d %H:%M", tz = "Europe/London"),
                             s$ctx$b[ix, c("open", "high", "low", "close")], s$ctx$ind[ix, ]), f, row.names = FALSE) })
    output$c_dl_json <- downloadHandler(filename = function() dl_name("scan", "json"), content = function(f) { req(scan()); writeLines(cc_json(payload()), f) })
    output$c_dl_html <- downloadHandler(filename = function() dl_name("chart", "html"), content = function(f) { s <- scan(); req(s)
      w <- cc_chart(s, picks(), title = chart_title(), panel = input$c_panel %||% "auto", show_levels = isTRUE(input$c_levels %||% TRUE))
      ok <- tryCatch({ htmlwidgets::saveWidget(w, f, selfcontained = TRUE); TRUE }, error = function(e) FALSE)
      if (!ok) { d <- tempfile(); dir.create(d); htmlwidgets::saveWidget(w, file.path(d, "chart.html"), selfcontained = FALSE); file.copy(file.path(d, "chart.html"), f, overwrite = TRUE) } })
    output$c_active <- DT::renderDT({ s <- scan(); if (is.null(s) || !nrow(s$current_df)) return(DT::datatable(data.frame(Note = "No pattern alive at the last candle."), rownames = FALSE, options = list(dom = "t")))
      d <- s$current_df
      x <- data.frame(Step = d$step, Pattern = d$label, Bias = d$bias, Status = d$status, `Candles ago` = d$candles_ago, `In regime` = ifelse(d$in_regime, "yes", "no"),
                      `Cancels beyond` = round(d$invalid, 4), Target = round(d$target, 4), `ATR template` = ifelse(d$atr_default, "yes", ""),
                      `Record n` = d$hist_n, `Target first %` = round(d$hist_win), `Expectancy R` = round(d$hist_exp_r, 2), Note = d$note, check.names = FALSE)
      DT::datatable(x, rownames = FALSE, options = list(pageLength = 25, scrollX = TRUE, dom = "tp")) })
    cov <- reactive({ s <- scan(); if (is.null(s)) NULL else cc_coverage(s) })
    output$c_cov <- DT::renderDT({ x <- cov(); if (is.null(x)) return(NULL); DT::datatable(x, rownames = FALSE, options = list(pageLength = 20, scrollX = TRUE)) })
    output$c_cov_dl <- downloadHandler(filename = function() sprintf("cc_pattern_coverage_%s.csv", format(Sys.Date())), content = function(f) utils::write.csv(cov(), f, row.names = FALSE))
    claude_read <- reactiveVal(NULL)
    # ***** save everything Claude generates to BigQuery (or queue it until BigQuery is connected)
    save_reading <- function(r, s, m, tx) tryCatch({ rid <- cc_id("CR"); ck <- r$checks; ad <- r$additions; cs <- r$course %||% data.frame(id = character()); cf <- r$course_facts %||% list()
      vc <- tolower(ck$verdict %||% character(0))
      store$write("claude_readings", data.frame(reading_id = rid, source = "app", trade_id = NA_character_, epic = m$epic, market_name = m$name %||% m$epic, resolution = m$res,
        last_candle_utc = max(s$ctx$b$time), last_close = s$ctx$c[s$ctx$n], checks_ticked = paste(names(cf), collapse = ","), n_agree = sum(vc == "agree"), n_doubt = sum(vc == "doubt"),
        n_disagree = sum(vc == "disagree"), n_added = nrow(ad), n_refused = as.integer(r$refused %||% 0L), n_course = nrow(cs), reply_text = tx %||% "", facts_json = cc_json(cf), note = "", stringsAsFactors = FALSE))
      L <- list(); add <- function(...) L[[length(L) + 1]] <<- data.frame(..., stringsAsFactors = FALSE)
      for (k in seq_len(nrow(ck))) add(section = "FINDING", item_key = ck$key[k], item_label = cc_catalog$label[match(ck$key[k], cc_catalog$key)] %||% ck$key[k], week = NA, topic = NA, r_values = NA,
                                       verdict = ck$verdict[k], note = ck$reason[k], bias = NA, cancel_level = NA_real_, target_level = NA_real_)
      for (k in seq_len(nrow(ad))) add(section = "CLAUDE_ONLY", item_key = ad$key[k], item_label = ad$label[k], week = NA, topic = NA, r_values = NA, verdict = "not counted", note = ad$note[k],
                                       bias = ad$bias[k], cancel_level = as.numeric(ad$invalid[k]), target_level = as.numeric(ad$target[k]))
      for (id in names(cf)) { i <- match(id, cc_course_checks$id); j <- match(id, cs$id)
        add(section = "COURSE_CHECK", item_key = id, item_label = cc_course_checks$label[i], week = cc_course_checks$week[i], topic = cc_course_checks$topic[i],
            r_values = if (nzchar(cf[[id]])) cf[[id]] else "not available", verdict = if (is.na(j)) "no answer" else cs$verdict[j], note = if (is.na(j)) "" else cs$note[j], bias = NA, cancel_level = NA_real_, target_level = NA_real_) }
      if (length(L)) { x <- do.call(rbind, L); x$line_id <- paste0(rid, "_", sprintf("%03d", seq_len(nrow(x)))); x$reading_id <- rid; x$line_no <- seq_len(nrow(x)); w <- store$write("claude_reading_lines", x) } else w <- "none"
      cat(sprintf("[C.C] Claude reading %s saved (%d lines, %s)\n", rid, length(L), w)); list(id = rid, where = w) }, error = function(e) { cat("[C.C] Claude reading NOT saved:", conditionMessage(e), "\n"); list(id = NA, where = paste("not saved:", conditionMessage(e))) })
    save_scenarios <- function(sc, type) tryCatch({ if (is.null(sc) || !nrow(sc)) return(invisible()); bid <- cc_id("SB"); f <- mkt()
      g <- function(k) if (k %in% names(sc)) sc[[k]] else rep(NA, nrow(sc))
      store$write("scenarios", data.frame(row_id = paste0(bid, "_", seq_len(nrow(sc))), build_id = bid, build_type = type, epic = f$epic %||% NA_character_, source = g("source"), scenario_id = g("id"),
        side = g("side"), entry = g("entry"), stop = g("stop"), target = g("target"), rrr = g("rrr"), size = tr_num0(input$p_size, NA), risk_account = g("risk_acc"), reward_account = g("reward_acc"),
        blocked = g("blocked"), plan = g("plan"), checks = g("checks"), trend = paste(g("htf_d"), g("htf_h4"), g("htf_phase"), sep = " / "), confluence = g("confl"), news = g("news"),
        claude_p = g("claude_p"), meas_p = g("meas_p"), note = g("note"), stringsAsFactors = FALSE)) }, error = function(e) cat("[C.C] scenarios NOT saved:", conditionMessage(e), "\n"))
    observeEvent(input$c_course_all, updateCheckboxGroupInput(session, "c_course", selected = cc_course_checks$id))
    observeEvent(input$c_course_none, updateCheckboxGroupInput(session, "c_course", selected = character()))
    observeEvent(input$c_course, { if (!course_loaded()) return(); store$write("settings", data.frame(setting_key = "rec_c_course", setting_value = paste(input$c_course %||% character(0), collapse = ","), stringsAsFactors = FALSE)) }, ignoreInit = TRUE, ignoreNULL = FALSE)
    # *** facts for each ticked course check, all computed in R
    course_facts <- function(s, m) { ids <- input$c_course; if (!length(ids)) return(list()); ctx <- s$ctx; n <- ctx$n; d <- ctx$ind; f4 <- function(x) if (length(x) && is.finite(x)) format(round(x, 4)) else "NA"
      cur <- s$current_df; dirs <- if (!is.null(cur) && nrow(cur)) unique(na.omit(cc_dir_of(cc_catalog$bias[match(cur$key, cc_catalog$key)]))) else integer()
      one <- function(id) tryCatch(switch(id,
        htf = { t <- htf(m$epic); sprintf("daily trend %s, 4-hour trend %s, Dow phase / market cycle %s", t$d, t$h4, t$phase) },
        ind = { osc <- paste0(cc_stoch_text(ctx), "; ", cc_divergence(ctx)); ob <- if (!is.null(ctx$b$volume) && any(is.finite(ctx$b$volume))) { o <- TTR::OBV(ctx$c, ctx$b$volume); sprintf("OBV change over 20 candles %+.0f", o[n] - o[max(1, n - 20)]) } else "OBV: no volume"
          sprintf("close %s; EMA20 %s, EMA50 %s, EMA200 %s; RSI14 %s; MACD hist %s; Bollinger %s / %s / %s (width %s); %s", f4(ctx$c[n]), f4(d$ema20[n]), f4(d$ema50[n]), f4(d$ema200[n]), f4(d$rsi[n]), f4(d$macd_hist[n]), f4(d$bb_dn[n]), f4(d$bb_mid[n]), f4(d$bb_up[n]), f4(d$bb_width[n]), ob) |> paste0("; ", osc) },
        adx = { sar <- tryCatch(as.numeric(TTR::SAR(cbind(ctx$h, ctx$l)))[n], error = function(e) NA)
          sprintf("ADX14 %s (3 candles ago %s), DI+ %s, DI- %s; Parabolic SAR %s (%s the price)", f4(d$adx[n]), f4(d$adx[max(1, n - 3)]), f4(d$di_p[n]), f4(d$di_n[n]), f4(sar), if (is.finite(sar) && sar < ctx$c[n]) "below" else "above") },
        prof = { p <- prof(); if (is.null(p)) "" else sprintf("previous session POC %s, value area %s to %s (%s); initial balance today %s to %s", f4(p$poc), f4(p$val), f4(p$vah), p$source, f4(p$ib_lo), f4(p$ib_hi)) },
        filt = { fr <- tr_num0(input$s_pl_filt_atr, 0.1); k <- tr_num0(input$s_pl_filt_n, 1)
          if (is.null(cur) || !nrow(cur) || !"level" %in% names(cur)) "no breakout level among the patterns" else {
            x <- cur[is.finite(cur$level), , drop = FALSE]; if (!nrow(x)) "no breakout level among the patterns" else
            paste(sprintf("%s level %s: %s (filter %s ATR, %s candle(s))", x$key, f4(x$level), vapply(seq_len(nrow(x)), function(i) { v <- cc_break_filter(ctx, x$level[i], cc_dir_of(cc_catalog$bias[match(x$key[i], cc_catalog$key)]), fr, k); if (is.na(v)) "n/a" else if (v) "passes" else "fails" }, ""), fr, k), collapse = "; ") } },
        strat = { k <- if (is.null(cur)) character() else intersect(cur$key, cc_course_keys); if (length(k)) paste("course set-ups alive now:", paste(k, collapse = ", ")) else "no course set-up (Pivot Point Bounce, Holy Grail, Straddle, opening range) alive now" },
        news = cc_news_line(news()),
        rel = { r <- related(); v <- relv(); if (is.null(r) || !nrow(r)) "" else paste0(paste(sprintf("%s move %s%%, correlation %s", r$epic, ifelse(is.finite(r$move), sprintf("%+.2f", r$move), "NA"), ifelse(is.finite(r$corr), sprintf("%.2f", r$corr), "NA")), collapse = "; "),
          if (is.null(v)) "" else paste0("; relative value vs ", v$epic, ": ", v$text)) },
        plan = { st <- if (length(input$s_pl_setups)) paste(names(cc_setup_choices)[match(input$s_pl_setups, cc_setup_choices)], collapse = ", ") else "any"
          rl <- plan_rules(); sprintf("set-ups allowed: %s; minimum R:R %s; session %s-%s UK; plan points: %s", st, input$s_minrrr, input$s_pl_from %||% "-", input$s_pl_to %||% "-", if (any(nzchar(rl))) paste(rl[nzchar(rl)], collapse = " / ") else "not set") },
        r5 = { r <- r5(); if (is.null(r)) "" else paste0(r$text, sprintf(" (minor %s, base %s, major %s candles)", r$minor, r$base, r$major)) },
        sr = { px <- ctx$c[n]; d <- tryCatch(srl(), error = function(e) NULL); fb <- tryCatch(cc_fib_text(fibl(), px), error = function(e) paste("not worked out:", conditionMessage(e)))
          paste0(if (is.null(d)) "daily candles not available for support / resistance and pivots" else paste0(cc_sr_near(d, px), "; ", paste(sprintf("%s %s", d$level, f4(d$price)), collapse = ", ")), "; Fibonacci: ", fb) },
        cand = cc_pattern_topics(cur),
        risk = { r <- risk_tbl(); if (is.null(r)) "ticket not filled (needs the stop and the size)" else cc_risk_text(r) },
        trader = { tr <- trades(); a <- attitude(); b <- cc_bias_checks(tr); sc <- if (is.null(a)) NULL else tryCatch(cc_attitude_score(jsonlite::fromJSON(utils::tail(a$response_json, 1))$answers), error = function(e) NULL)
          sprintf("mood now %s/5 (1 very poor, 3 neutral, 5 very good), confidence %s/5; losses in a row today %d; biases flagged: %s; attitude survey %s", input$o_mood %||% "-", input$o_conf %||% "-", cc_losses_in_row(tr, now_fn()),
                  if (is.null(b)) "not enough trades" else { y <- b$bias[b$flag == "yes"]; if (length(y)) paste(y, collapse = ", ") else "none" }, if (is.null(sc)) "not answered" else sprintf("%d%% (%s)", sc$pct, sc$band)) },
        record = { b <- bt(); if (is.null(b) || is.null(cur) || !nrow(cur)) "" else { x <- b[b$key %in% cur$key, , drop = FALSE]; if (!nrow(x)) "no measured case of these patterns on this market"
          else paste(sprintf("%s: %d cases, win %.0f%%, expectancy %+.2fR", x$key, x$n, as.numeric(x$win_pct), x$exp_r), collapse = "; ") } },
        ""), error = function(e) "")
      out <- lapply(ids, one); names(out) <- ids; out }
    observeEvent(input$c_claude, { s <- scan(); m <- scan_meta(); if (is.null(s)) { note("Load the chart first.", "warning"); return() }
      cat("[C.C] Claude second reading with", length(input$c_course), "course check(s)\n")
      r <- withProgress(message = "Claude is reading the same candles...", value = 0.5, tryCatch({
        cf <- course_facts(s, m); res <- vision_fn(paste0(cc_claude_prompt(s, m$name %||% m$epic, names(cc_candles)[cc_candles == m$res]), cc_course_prompt(cf))); tx <- if (is.list(res)) res$text else res
        out <- cc_claude_parse(tx, s); out$course <- cc_course_parse(tx); out$course_facts <- cf; out$saved <- save_reading(out, s, m, tx); out },
        error = function(e) { cat("[C.C] Claude reading failed:", conditionMessage(e), "\n"); note(conditionMessage(e), "error"); NULL })); claude_read(r) })
    output$c_claude_out <- renderUI({ r <- claude_read(); if (is.null(r)) return(NULL)
      tagList(
        if (nrow(r$checks)) tags$div(tags$b("On the rule findings:"), tags$ul(lapply(seq_len(nrow(r$checks)), function(k) tags$li(sprintf("%s: %s. %s", r$checks$key[k], r$checks$verdict[k], r$checks$reason[k]))))),
        tags$div(style = "margin-top:4px;", tags$b("Claude only (not confirmed by the rules, not counted):"),
          if (nrow(r$additions)) tags$ul(lapply(seq_len(nrow(r$additions)), function(k) tags$li(sprintf("%s (%s): %s. Cancels beyond %s, target %s.", r$additions$label[k], r$additions$bias[k], r$additions$note[k],
                                                                                                           cc_fmt(r$additions$invalid[k], 3), cc_fmt(r$additions$target[k], 3))))) else " none."),
        tags$div(style = sprintf("font-weight:700; color:%s;", if (isTRUE(r$saved$where %in% c("bigquery"))) "#166534" else "#b45309"),
          if (identical(r$saved$where, "bigquery")) sprintf("Saved to BigQuery (cc_claude_readings / cc_claude_reading_lines, reading %s). *****", r$saved$id)
          else if (identical(r$saved$where, "pending")) sprintf("Kept as reading %s; it is uploaded to BigQuery when BigQuery is connected. *****", r$saved$id) else paste("Reading", r$saved$where %||% "not saved")),
        if (r$refused) tags$div(style = "color:#b45309;", sprintf("%d addition(s) refused: not in the last 10 candles, not in the catalogue, or a stop / target on the wrong side.", r$refused)),
        if (length(r$course_facts)) { cs <- r$course %||% data.frame(id = character()); ids <- names(r$course_facts)
          tags$div(style = "margin-top:6px;", tags$b("Course checks ***"), tags$table(class = "table table-condensed", style = "font-size:13px;",
            tags$tr(tags$th("Check"), tags$th("Week and topic"), tags$th("R values"), tags$th("Claude")),
            lapply(ids, function(id) { k <- match(id, cc_course_checks$id); j <- match(id, cs$id); v <- if (is.na(j)) "" else cs$verdict[j]
              tags$tr(tags$td(cc_course_checks$label[k]), tags$td(paste(cc_course_checks$week[k], "\u00b7", cc_course_checks$topic[k])), tags$td(style = "font-size:12px;", if (nzchar(r$course_facts[[id]])) r$course_facts[[id]] else "not available"),
                      tags$td(style = switch(v, supports = "color:#166534;", against = "color:#b91c1c;", ""), if (is.na(j)) "no answer" else paste0(v, ": ", cs$note[j]))) }))) }) })

    # ---- plan: money, scenarios, ticket ------------------------------------------------------------------------
    open_risk <- reactive({ t <- trades(); if (is.null(t) || !nrow(t)) return(0); o <- t[t$status %in% c("OPEN", "ORDER_WORKING"), , drop = FALSE]
      sum(o$risk_account, na.rm = TRUE) })
    output$p_money <- renderUI({ bump(); a <- acct(); f <- mkt()
      if (is.null(a)) return(tagList(cc_rec_note("Connect Capital.com and choose a market on tab 3 (Market & Patterns)."), actionButton(session$ns("p_refresh"), "Read the account", icon = icon("rotate"))))
      fx <- if (is.null(f)) list(rate = NA, how = "choose a market") else fx_info(f$currency, a$currency); sz <- tr_num0(input$p_size, NA)
      vpp <- if (!is.null(f) && is.finite(sz)) cc_value_per_point(sz, f$lot_size) else NA
      tagList(tags$div(style = "display:flex; flex-wrap:wrap;",
        cc_rec_tile("Balance", cc_money(a$balance, a$currency), sprintf("account %s", a$account_id)), cc_rec_tile("Available", cc_money(a$available, a$currency), "for new margin"),
        cc_rec_tile("Open P/L", cc_money(a$profit_loss, a$currency), "as Capital.com shows it"), cc_rec_tile("Open risk (to stops)", cc_money(open_risk(), a$currency), "from your records"),
        cc_rec_tile("Market currency", if (is.null(f)) "—" else f$currency, if (is.null(f)) "" else fx$how),
        cc_rec_tile("1 point at your size", if (is.finite(vpp)) sprintf("%s = %s", cc_money(vpp, f$currency, 3), cc_money(vpp * fx$rate, a$currency, 3)) else "—", "size x lot size, then converted")),
        tags$div(actionButton(session$ns("p_refresh"), "Refresh balance", icon = icon("rotate")),
                 tags$span(style = "font-size:12px; color:#166534; margin-left:8px; font-weight:700;", sprintf("Read from Capital.com at %s UK", format(a$read_at, "%H:%M:%S", tz = "Europe/London"))))) })
    observeEvent(input$p_refresh, { if (is.null(read_account())) note("The balance could not be read: is Capital.com connected?", "error") else note("Balance refreshed from Capital.com."); touch() })
    output$p_size_help <- renderUI({ f <- mkt(); if (is.null(f)) return(NULL)
      tags$div(style = "font-size:12px; color:#475569; margin-top:20px;", sprintf("Minimum %s. Units as Capital.com counts them for %s (lot size %s).", cc_fmt(f$min_size, 2), f$name %||% f$epic, cc_fmt(f$lot_size, 2))) })
    scen <- reactiveVal(NULL); scen_msg <- reactiveVal(NULL)
    # the minimum Reward:Risk for the scenarios and the ticket: box 2's value, which starts at your strategy's (Setup) and can be changed
    last_plan_rrr <- reactiveVal(NA_real_)
    observeEvent(input$s_minrrr, { v <- tr_num0(input$s_minrrr, NA); cur <- tr_num0(input$p_rrr, NA)
      if (is.finite(v) && (!is.finite(cur) || isTRUE(all.equal(cur, last_plan_rrr())) || isTRUE(all.equal(cur, 1.5)))) updateNumericInput(session, "p_rrr", value = v)
      last_plan_rrr(v) }, ignoreNULL = TRUE)
    rrr_min <- function() { v <- tr_num0(input$p_rrr, NA); if (is.finite(v) && v > 0) v else tr_num0(input$s_minrrr, NA) }
    hold_h <- function() { s <- scan(); m <- scan_meta()$mins %||% 15; if (is.null(s)) NA_real_ else s$ctx$horizon * m / 60 }
    # money, checks and the measured chance for a set of scenario rows (rule-based or Claude's)
    add_facts <- function(sc, f2, a, sz) { s <- scan(); d <- cc_px_decimals(f2); fx <- fx_info(f2$currency, a$currency)
      sc$entry <- cc_round_px(sc$entry, d); sc$stop <- cc_round_px(sc$stop, d); sc$target <- cc_round_px(sc$target, d)
      sc$now_px <- ifelse(sc$side == "BUY", f2$offer, f2$bid)
      bud <- lapply(seq_len(nrow(sc)), function(k) cc_budget(sc$side[k], sc$entry[k], sc$stop[k], sc$target[k], sz, f2$lot_size, fx$rate, a$balance, a$available,
                                                            f2$margin_factor, f2$margin_unit, f2$offer - f2$bid, open_risk(), input$s_risk, input$s_cap, rrr_min(), f2$min_size, f2$min_stop_distance))
      g <- function(k) vapply(bud, function(b) as.numeric(b[[k]] %||% NA), 0)
      sc$risk_acc <- g("risk_account"); sc$reward_acc <- g("reward_account"); sc$risk_pct <- g("risk_pct"); sc$rrr <- g("rrr")
      sc$bal_stop <- g("balance_if_stop"); sc$bal_target <- g("balance_if_target"); sc$margin <- g("margin_account"); sc$size_plan <- g("size_for_plan")
      mr <- rrr_min()
      errs <- lapply(seq_len(nrow(sc)), function(k) { e <- c(bud[[k]]$errors, cc_order_problems(sc$side[k], "MARKET", NA, sc$stop[k], sc$target[k], f2$bid, f2$offer, f2$min_stop_distance))
        if (is.finite(mr) && is.finite(sc$rrr[k]) && sc$rrr[k] < mr - 1e-6) e <- c(e, sprintf("R:R %.2f is below your minimum %.2f.", sc$rrr[k], mr)); unique(e) })
      sc$checks <- vapply(seq_len(nrow(sc)), function(k) paste(c(errs[[k]], bud[[k]]$warnings), collapse = " "), ""); sc$blocked <- vapply(errs, function(e) length(e) > 0, TRUE)
      H <- if (!is.null(s)) s$ctx$horizon else 40L
      pr <- lapply(seq_len(nrow(sc)), function(k) if (is.null(s)) list(p = NA, n = 0L, undecided = NA) else
        cc_touch_prob(s$ctx$h, s$ctx$l, s$ctx$c, if (sc$side[k] == "BUY") 1 else -1, abs(sc$entry[k] - sc$stop[k]), abs(sc$target[k] - sc$entry[k]), H))
      sc$meas_p <- vapply(pr, function(x) as.numeric(x$p), 0); sc$meas_n <- vapply(pr, function(x) as.integer(x$n), 0L); sc$meas_und <- vapply(pr, function(x) as.numeric(x$undecided), 0)
      attr(sc, "ccy") <- a$currency; attr(sc, "d") <- d; attr(sc, "at") <- now_fn(); sc }
    # ---- course improvements: higher time-frame trend, today's news, plan check (R/utils_cc_plan.R) --------------
    htf_cache <- new.env(parent = emptyenv())
    htf <- function(epic) { k <- epic; x <- htf_cache[[k]]; if (!is.null(x) && difftime(now_fn(), x$at, units = "mins") < 30) return(x)
      g <- function(res, days) tryCatch(cc_dow_trend(fetch_bars(epic, res, now_fn() - days * 86400, now_fn())), error = function(e) { cat("[C.C] trend", res, ":", conditionMessage(e), "\n"); "unknown" })
      bd <- tryCatch(fetch_bars(epic, "DAY", now_fn() - 200 * 86400, now_fn()), error = function(e) NULL)
      x <- list(d = if (is.null(bd)) "unknown" else cc_dow_trend(bd), h4 = g("HOUR_4", 45), phase = if (is.null(bd)) "unknown" else cc_dow_phase(bd), at = now_fn()); assign(k, x, envir = htf_cache)
      cat(sprintf("[C.C] higher time-frame trend %s: daily %s, 4-hour %s\n", epic, x$d, x$h4)); x }
    add_htf <- function(sc, epic) { if (is.null(sc) || !nrow(sc)) return(sc); t <- htf(epic); a <- attributes(sc)[c("ccy", "d", "at")]
      sc$htf_d <- t$d; sc$htf_h4 <- t$h4; sc$htf_phase <- t$phase %||% "unknown"; sc$fit <- vapply(sc$side, cc_trend_fit, "", d = t$d, h4 = t$h4)
      s <- scan(); pf <- tryCatch(prof(), error = function(e) NULL); a1 <- if (is.null(s)) NA else s$ctx$a[s$ctx$n]
      sc$confl <- if (is.null(s)) "-" else vapply(sc$side, function(sd) cc_confluence(s$ctx, if (sd == "BUY") 1 else -1)$text, "")
      sc$prof <- vapply(seq_len(nrow(sc)), function(k) cc_profile_near(pf, sc$stop[k], sc$target[k], a1), "")
      sc$news <- cc_news_line(tryCatch(news(), error = function(e) NULL))
      sc <- scen_plan(sc)
      for (k in names(a)) attr(sc, k) <- a[[k]]; sc }
    # ***** every scenario is checked against the trading plan, exactly as the ticket will be: a scenario that breaks a rule is blocked
    #       (the counter-trend rule is the exception: Use scenario halves the size, which is what the plan allows)
    scen_strategy <- function(sc) { k <- sc$keys %||% rep("", nrow(sc))
      ifelse(sc$source == "Rules", "PATTERN", ifelse(grepl("pivot", k), "PIVOT_BOUNCE", ifelse(grepl("holy_grail", k), "HOLY_GRAIL", ifelse(grepl("straddle", k), "STRADDLE",
             ifelse(grepl("orb", k), "ORB", ifelse(sc$source == "Claude", "OTHER", "PATTERN")))))) }
    scen_plan <- function(sc) { f <- mkt(); a <- acct(); if (is.null(f) || is.null(a) || !nrow(sc)) return(sc); st <- scen_strategy(sc); sz <- tr_num0(input$p_size, NA)
      res <- lapply(seq_len(nrow(sc)), function(k) tryCatch({ cr <- corr_risk(list(risk_pct = sc$risk_pct[k] %||% NA), f, a)
        pc <- cc_plan_check(plan_args(sc$side[k], sc$rrr[k], sz, sc$size_plan[k] %||% NA, st[k], f, a, cr)); bad <- pc[!is.na(pc$ok) & !pc$ok, , drop = FALSE]
        hard <- bad[!grepl("^Higher time-frame trend", bad$rule), , drop = FALSE]; list(bad = bad$rule, hard = hard$rule) }, error = function(e) list(bad = character(0), hard = character(0))))
      sc$plan <- vapply(res, function(x) if (!length(x$bad)) "OK" else paste0(if (length(x$hard)) "BREAKS: " else "half size: ", paste(x$bad, collapse = "; ")), "")
      hb <- vapply(res, function(x) length(x$hard) > 0, TRUE)
      sc$checks <- ifelse(hb, trimws(paste(sc$checks %||% "", "Breaks your plan:", vapply(res, function(x) paste(x$hard, collapse = "; "), ""))), sc$checks %||% "")
      sc$blocked <- (sc$blocked %||% rep(FALSE, nrow(sc))) | hb; sc }
    news_ms <- reactive({ invalidateLater(15 * 60 * 1000); day <- as.Date(format(now_fn(), "%Y-%m-%d", tz = "Europe/London")); tryCatch(morning_fn(day), error = function(e) list(ok = FALSE, why = conditionMessage(e))) })
    news <- reactive({ invalidateLater(60 * 1000); m <- news_ms(); if (!isTRUE(m$ok)) return(NULL)
      cc_news(m$releases %||% "", now_fn(), if (is.finite(hold_h())) hold_h() else tr_num0(input$s_hold, 10), tr_num0(input$s_pl_news, 30)) })
    output$p_news <- renderUI({ m <- news_ms(); n <- news()
      if (!isTRUE(m$ok)) return(tags$div(style = "color:#92400e; font-weight:700;", icon("circle-xmark"), " Today's Morning Sheet is NOT loaded: ", m$why %||% "not available", " (no release check)."))
      if (is.null(n) || !nrow(n)) return(tags$div(style = "color:#166534;", icon("check"), " Today's Morning Sheet is loaded; it lists no releases for today."))
      tagList(tags$div(style = if (any(n$in_window)) "color:#b91c1c; font-weight:800;" else "color:#166534; font-weight:700;",
                       if (any(n$in_window)) paste0("High-impact release in your holding time: ", paste(sprintf("%s %s", n$time[n$in_window], n$event[n$in_window]), collapse = "; "), ". The ticket will flag it.")
                       else "No high-impact release in your holding time."),
              tags$table(class = "table table-condensed", style = "font-size:12.5px; margin-top:4px;",
                tags$tr(tags$th("UK time"), tags$th("Country"), tags$th("Impact"), tags$th("Release"), tags$th("What it means"), tags$th("In your window?")),
                lapply(seq_len(nrow(n)), function(i) tags$tr(style = if (n$in_window[i]) "background:#fee2e2;" else "", tags$td(n$time[i]), tags$td(n$country[i]), tags$td(n$importance[i]),
                                                             tags$td(n$event[i]), tags$td(n$meaning[i]), tags$td(if (n$in_window[i]) "YES" else "")))))
    })
    deals_today <- reactive({ t <- trades(); d0 <- format(now_fn(), "%Y-%m-%d", tz = "Europe/London")
      td <- t[!is.na(t$placed_ts) & format(t$placed_ts, "%Y-%m-%d", tz = "Europe/London") == d0 & !(t$status %in% c("REJECTED", "DUPLICATE")), , drop = FALSE]
      cl <- t[t$status %in% "CLOSED" & !is.na(t$exit_ts) & format(t$exit_ts, "%Y-%m-%d", tz = "Europe/London") == d0, , drop = FALSE]
      pl <- ifelse(is.finite(cl$pnl_account_booked), cl$pnl_account_booked, cl$pnl_account_est)
      list(n = nrow(td), pnl = sum(pl, na.rm = TRUE)) })
    plan_rules <- reactive(vapply(1:5, function(i) trimws(input[[paste0("s_pl_r", i)]] %||% ""), ""))
    # #10 correlated open risk: open trades in related markets whose correlation with this one is 0.7 or more, same effective side
    corr_risk <- function(t, f, a) { rl <- related(); tr <- trades(); op <- tr[tr$status %in% "OPEN" & is.finite(tr$risk_account), , drop = FALSE]
      me <- if (is.finite(t$risk_pct %||% NA)) t$risk_pct else NA
      if (is.null(rl) || !nrow(rl) || !nrow(op) || !is.finite(a$balance %||% NA)) return(list(pct = me, note = ""))
      hit <- merge(op, rl[abs(rl$corr) >= 0.7, , drop = FALSE], by = "epic"); if (!nrow(hit)) return(list(pct = me, note = ""))
      same <- (hit$direction == (input$o_dir %||% "BUY")) == (hit$corr > 0); hit <- hit[same, , drop = FALSE]; if (!nrow(hit)) return(list(pct = me, note = ""))
      list(pct = sum(c(me, 100 * hit$risk_account / a$balance), na.rm = TRUE), note = paste(sprintf("%s %s (corr %.2f)", hit$epic, hit$direction, hit$corr), collapse = ", ")) }
    # one builder for the plan check: the ticket and every scenario (*****) are judged by the same rules
    plan_args <- function(side, rrr, size, plan_size, strategy, f, a, cr, rl = character(0), ticks = logical(0)) { tr <- htf(f$epic); dt <- deals_today()
      list(epic = f$epic, markets = input$s_pl_markets, from = input$s_pl_from, to = input$s_pl_to, any_hours = isTRUE(input$s_pl_anyhours), now = now_fn(), max_day = input$s_pl_maxday, n_today = dt$n,
        max_loss_pct = input$s_pl_maxloss, balance = a$balance %||% NA, pnl_today = dt$pnl, side = side, d = tr$d, h4 = tr$h4, fit = cc_trend_fit(side, tr$d, tr$h4),
        min_rrr = rrr_min(), ctr_extra = tr_num0(input$s_pl_ctr, 0.5), rrr = rrr, size = size, plan_size = plan_size, news = news(), rules = rl, ticks = ticks,
        setups = input$s_pl_setups, strategy = strategy, strategy_label = names(cc_setup_choices)[match(strategy, cc_setup_choices)],
        setup_labels = names(cc_setup_choices)[match(input$s_pl_setups, cc_setup_choices)], max_loss_row = input$s_pl_lossrow, loss_row = cc_losses_in_row(trades(), now_fn()),
        corr_risk_pct = cr$pct, cap_pct = input$s_cap, corr_note = cr$note, regime = tryCatch(scan()$regime %||% "", error = function(e) ""),
        r5 = tryCatch({ r <- r5(); if (is.null(r)) NULL else list(ok = if (is.na(r$major) || r$major == 0) NA else (if (identical(side, "BUY")) 1 else -1) == r$major, text = r$text) }, error = function(e) NULL)) }
    plan_chk <- reactive({ t <- ticket(); f <- mkt(); a <- acct(); if (is.null(f)) return(NULL); cr <- corr_risk(t, f, a)
      tr <- htf(f$epic); dt <- deals_today(); rl <- plan_rules()
      cc_plan_check(list(epic = f$epic, markets = input$s_pl_markets, from = input$s_pl_from, to = input$s_pl_to, any_hours = isTRUE(input$s_pl_anyhours), now = now_fn(), max_day = input$s_pl_maxday, n_today = dt$n,
        max_loss_pct = input$s_pl_maxloss, balance = a$balance %||% NA, pnl_today = dt$pnl, side = input$o_dir, d = tr$d, h4 = tr$h4, fit = cc_trend_fit(input$o_dir, tr$d, tr$h4),
        min_rrr = rrr_min(), ctr_extra = tr_num0(input$s_pl_ctr, 0.5), rrr = t$rrr %||% NA, size = tr_num0(input$o_size, NA), plan_size = t$size_for_plan %||% NA,
        news = news(), rules = rl, ticks = vapply(seq_along(rl), function(i) isTRUE(input[[paste0("o_r", i)]]), TRUE),
        setups = input$s_pl_setups, strategy = input$o_strategy, strategy_label = names(cc_setup_choices)[match(input$o_strategy, cc_setup_choices)],
        setup_labels = names(cc_setup_choices)[match(input$s_pl_setups, cc_setup_choices)],
        max_loss_row = input$s_pl_lossrow, loss_row = cc_losses_in_row(trades(), now_fn()),
        corr_risk_pct = cr$pct, cap_pct = input$s_cap, corr_note = cr$note, regime = tryCatch(scan()$regime %||% "", error = function(e) ""),
        r5 = tryCatch({ r <- r5(); if (is.null(r)) NULL else list(ok = if (is.na(r$major) || r$major == 0) NA else (if (identical(input$o_dir %||% "BUY", "BUY")) 1 else -1) == r$major, text = r$text) }, error = function(e) NULL))) })
    output$o_plan <- renderUI({ rl <- plan_rules(); pc <- plan_chk()
      ticks <- lapply(which(nzchar(rl)), function(i) checkboxInput(session$ns(paste0("o_r", i)), cc_rec_lab(paste0("Plan point ", i, ": ", rl[i])), isolate(input[[paste0("o_r", i)]]) %||% FALSE))
      tagList(if (!any(nzchar(rl))) tags$div(style = "font-size:12px; color:#64748b;", "Type your plan points in 1. Setup to get its tick boxes here."), ticks,
        if (is.null(pc)) tags$div(style = "font-size:12px; color:#64748b;", "Load the market first.") else
        tags$ul(style = "margin:4px 0; font-size:12.5px;", lapply(seq_len(nrow(pc)), function(i) tags$li(style = sprintf("color:%s;", if (isTRUE(pc$ok[i])) "#166534" else if (isFALSE(pc$ok[i])) "#b91c1c" else "#64748b"),
          if (isTRUE(pc$ok[i])) icon("check") else if (isFALSE(pc$ok[i])) icon("xmark") else icon("minus"), " ", tags$b(pc$rule[i]), ": ", pc$detail[i])))) })
    # ---- 9. Backtest & Blotter ------------------------------------------------------------------------------------
    bt <- reactive({ s <- scan(); if (is.null(s)) NULL else cc_backtest(s) })
    output$bt_sum <- renderUI({ s <- scan(); b <- bt(); m <- scan_meta()
      if (is.null(s)) return(cc_rec_note("Load a chart in 3. Market & Patterns first: the backtest uses its market, candles and history."))
      if (is.null(b)) return(cc_rec_note("No past case with a target and a stop was found on this chart."))
      al <- attr(b, "all"); ok <- b[b$n >= 20 & b$exp_r > 0.05, , drop = FALSE]
      tags$div(style = "font-size:13px; margin:4px 0;", tags$b(sprintf("%s, %s candles, %d candles of history: ", m$epic %||% "", m$res %||% "", s$n)),
        sprintf("%d past cases, %d targets first (%.0f%%), expectancy %+.2f R per trade, worst run %.1f R. ", al$n, al$wins, al$win_pct, al$exp_r, al$max_dd_r),
        tags$span(style = sprintf("font-weight:800; color:%s;", if (nrow(ok)) "#166534" else "#b91c1c"),
                  if (nrow(ok)) paste0("Tradeable on this market (positive over 20+ cases): ", paste(ok$pattern, collapse = ", "), ".") else "No pattern has a positive expectancy over 20 cases or more on this market.")) })
    output$bt_tbl <- DT::renderDT({ b <- bt(); if (is.null(b)) return(NULL)
      x <- data.frame(Pattern = b$pattern, Bias = b$bias, Cases = b$n, `Target first` = b$wins, `Win %` = round(b$win_pct), `Expectancy (R per trade)` = round(b$exp_r, 2),
                      `Total R` = round(b$total_r, 1), `Worst run (R)` = round(b$max_dd_r, 1), Verdict = b$verdict, check.names = FALSE)
      DT::formatStyle(DT::datatable(x, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE)), "Verdict",
                      color = DT::styleEqual(c("positive: tradeable", "negative: avoid"), c("#166534", "#b91c1c")), fontWeight = "bold") })
    blot <- reactive(cc_blotter(trades()))
    output$bl_sum <- renderUI({ b <- blot(); sm <- cc_blotter_summary(b); if (is.null(sm)) return(cc_rec_note("No closed trade yet."))
      cy <- acct()$currency %||% "GBP"
      tags$div(style = "font-size:13px; margin:4px 0;", sprintf("%d closed trades: %d wins (%.0f%%), net %s, average win %s, average loss %s, expectancy %s R, largest drawdown %s.",
        sm$n, sm$wins, sm$win_pct, cc_money(sm$net, cy), cc_money(sm$avg_win, cy), cc_money(sm$avg_loss, cy), if (is.finite(sm$exp_r)) sprintf("%+.2f", sm$exp_r) else "-", cc_money(sm$max_dd, cy))) })
    output$bl_tbl <- DT::renderDT({ b <- blot(); if (is.null(b)) return(NULL); DT::datatable(b, rownames = FALSE, options = list(pageLength = 20, scrollX = TRUE, order = list(list(0, "desc")))) })
    output$bl_csv <- downloadHandler(filename = function() paste0("LAT_trade_blotter_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(f) { b <- blot(); utils::write.csv(if (is.null(b)) data.frame(Note = "No trades yet") else b, f, row.names = FALSE) }, contentType = "text/csv")
    # ---- #7 profile levels (previous session POC / value area, today's initial balance) ------------------------------
    prof <- reactive({ s <- scan(); if (is.null(s)) return(NULL); tryCatch(cc_profile(s$ctx$b, input$s_or_start %||% "08:00", tr_num0(input$s_or_min, 60), now_fn()), error = function(e) NULL) })
    output$c_profile <- renderUI({ p <- prof(); if (is.null(scan())) return(cc_rec_note("Load the chart first."))
      if (is.null(p)) return(cc_rec_note("Not enough candles of a previous session in the loaded history."))
      f <- function(x) if (is.finite(x)) format(round(x, 4)) else "-"
      tags$table(class = "table table-condensed", style = "font-size:13px; max-width:720px;",
        tags$tr(tags$th("Level"), tags$th("Price"), tags$th("What it is")),
        tags$tr(tags$td("POC"), tags$td(f(p$poc)), tags$td(sprintf("Point of control of %s: the price with the most %s", format(p$day, "%d/%m"), p$source))),
        tags$tr(tags$td("Value area high"), tags$td(f(p$vah)), tags$td("Top of the 70% value area")), tags$tr(tags$td("Value area low"), tags$td(f(p$val)), tags$td("Bottom of the 70% value area")),
        tags$tr(tags$td("Initial balance high / low"), tags$td(paste(f(p$ib_hi), "/", f(p$ib_lo))), tags$td(if (is.finite(p$ib_hi)) "Today's opening range (Setup)" else "Not formed yet today"))) })
    # ---- #10 related markets ---------------------------------------------------------------------------------------
    related <- reactive({ s <- scan(); m <- scan_meta(); if (is.null(s) || is.null(m)) return(NULL)
      eps <- setdiff(trimws(unlist(strsplit(input$s_rel_epics %||% "", "[,;]"))), c("", m$epic)); if (!length(eps)) return(NULL)
      do.call(rbind, lapply(eps, function(e) { b <- tryCatch(fetch_bars(e, m$res, min(s$ctx$b$time), max(s$ctx$b$time)), error = function(x) NULL)
        if (is.null(b) || nrow(b) < 2) return(data.frame(epic = e, move = NA_real_, corr = NA_real_, note = "no candles (check the epic)", stringsAsFactors = FALSE))
        data.frame(epic = e, move = 100 * (utils::tail(b$close, 1) / b$close[1] - 1), corr = cc_corr(s$ctx$b, b), note = "", stringsAsFactors = FALSE) })) })
    output$c_related <- renderUI({ r <- related(); if (is.null(scan())) return(cc_rec_note("Load the chart first.")); if (is.null(r)) return(cc_rec_note("No related market set in Setup."))
      m <- scan_meta(); me <- 100 * (utils::tail(scan()$ctx$c, 1) / scan()$ctx$c[1] - 1)
      tags$table(class = "table table-condensed", style = "font-size:13px; max-width:720px;", tags$tr(tags$th("Market"), tags$th("Move over the loaded window"), tags$th("Correlation with this market"), tags$th("")),
        tags$tr(tags$td(tags$b(m$epic)), tags$td(sprintf("%+.2f%%", me)), tags$td("-"), tags$td("this market")),
        lapply(seq_len(nrow(r)), function(i) tags$tr(tags$td(r$epic[i]), tags$td(if (is.finite(r$move[i])) sprintf("%+.2f%%", r$move[i]) else "-"),
          tags$td(if (is.finite(r$corr[i])) sprintf("%.2f%s", r$corr[i], if (abs(r$corr[i]) >= 0.7) " (strong: risk counted together)" else "") else "-"), tags$td(r$note[i]))),
        if (!is.null(v <- relv())) tags$tr(tags$td(colspan = 4, tags$b(sprintf("Relative value **** %s / %s: ", m$epic, v$epic)), v$text))) })
    # ---- #8 Parabolic SAR trailing stops for open trades -----------------------------------------------------------------
    output$pos_sar <- renderUI({ tr <- trades(); op <- tr[tr$status %in% "OPEN", , drop = FALSE]; if (!nrow(op)) return(cc_rec_note("No open trade."))
      rows <- lapply(seq_len(nrow(op)), function(i) { r <- op[i, ]; b <- tryCatch(fetch_bars(r$epic, "MINUTE_15", now_fn() - 3 * 86400, now_fn()), error = function(e) NULL)
        dir <- if (r$direction == "BUY") 1 else -1; px <- if (is.null(b)) NA else utils::tail(b$close, 1); sar <- cc_sar_trail(b, dir, r$stop_level, px)
        tags$tr(tags$td(r$trade_id), tags$td(r$direction), tags$td(format(r$stop_level)), tags$td(if (is.finite(px)) format(round(px, 4)) else "-"),
                tags$td(style = if (is.finite(sar)) "color:#166534; font-weight:700;" else "", if (is.finite(sar)) sprintf("move the stop to %s", format(round(sar, 4))) else "keep the current stop")) })
      tags$table(class = "table table-condensed", style = "font-size:13px;", tags$tr(tags$th("Trade"), tags$th("Side"), tags$th("Stop now"), tags$th("Price"), tags$th("SAR suggestion")), rows) })
    # ---- #9 psychology tables -------------------------------------------------------------------------------------------
    psy <- reactive(cc_psych(trades()))
    output$ps_mood <- renderTable({ p <- psy(); if (is.null(p)) data.frame(Note = "No closed trade yet.") else p$mood })
    output$ps_after <- renderTable({ p <- psy(); if (is.null(p)) data.frame(Note = "No closed trade yet.") else p$after })
    # ---- * backtest by strategy / family, LAT blotter (Excel), Trading Plan (Word) ------------------------------------------
    output$bt_fam <- DT::renderDT({ s <- scan(); if (is.null(s) || is.null(s$hist)) return(NULL); h <- s$hist[s$hist$outcome %in% c("target", "stop"), , drop = FALSE]; if (!nrow(h)) return(NULL)
      h$family <- cc_catalog$family[match(h$key, cc_catalog$key)]; h$group <- ifelse(h$key %in% cc_course_keys, paste0("COURSE: ", c(pivot = "Pivot Point System", holy_grail = "Holy Grail", straddle = "Straddle (overnight range)", orb = "Opening-range breakout")[h$family]), h$family)
      h$r <- ifelse(h$outcome == "target", h$rr, -1); h <- h[order(h$i1), , drop = FALSE]
      x <- do.call(rbind, lapply(split(h, h$group), function(d) { eq <- cumsum(d$r); data.frame(Strategy = d$group[1], Cases = nrow(d), `Win %` = round(100 * mean(d$outcome == "target")),
        `Expectancy (R)` = round(mean(d$r), 2), `Worst run (R)` = round(max(cummax(c(0, eq))[-1] - eq, 0), 1),
        Verdict = if (nrow(d) < 20) "too few cases (under 20)" else if (mean(d$r) > 0.05) "positive: tradeable" else if (mean(d$r) < -0.05) "negative: avoid" else "break-even", check.names = FALSE) }))
      x <- x[order(!startsWith(x$Strategy, "COURSE"), -x$`Expectancy (R)`), ]; DT::datatable(x, rownames = FALSE, options = list(pageLength = 12, dom = "tp")) })
    output$bl_xlsx <- downloadHandler(filename = function() paste0("LAT_Trade_Blotter_CapitalCom_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(f) tr_write_blotter(cc_lat_blotter_trades(trades()), f, input$s_name %||% ""),
      contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    output$pl_doc <- downloadHandler(filename = function() paste0("My_Trading_Plan_", format(Sys.Date(), "%Y%m%d"), ".docx"),
      content = function(f) { d <- officer::read_docx(); add <- function(x, st = "Normal") d <<- officer::body_add_par(d, x, style = st)
        add("My Structured Trading Plan", "heading 1"); add(sprintf("%s (%s), period %s to %s", input$s_name %||% "", input$s_id %||% "", format(input$s_start), format(input$s_end)))
        add("Markets and sessions", "heading 2"); add(paste("Markets:", input$s_pl_markets %||% "any")); add(sprintf("Session (UK): %s to %s", input$s_pl_from %||% "-", input$s_pl_to %||% "-"))
        add("Set-ups", "heading 2"); add(paste("Allowed:", if (length(input$s_pl_setups)) paste(names(cc_setup_choices)[match(input$s_pl_setups, cc_setup_choices)], collapse = ", ") else "any"))
        add(sprintf("Break filter: close %s ATR beyond the level, held %s candle(s).", input$s_pl_filt_atr %||% "-", input$s_pl_filt_n %||% "-"))
        add("Risk", "heading 2"); add(sprintf("Risk per trade %s%% of balance; open-risk cap %s%%; minimum Reward:Risk %s.", input$s_risk, input$s_cap, input$s_minrrr))
        add(sprintf("Maximum %s deals per day; daily loss limit %s%%; stop for the day after %s losses in a row.", input$s_pl_maxday %||% "-", input$s_pl_maxloss %||% "-", input$s_pl_lossrow %||% "-"))
        add(sprintf("Against the daily / 4-hour trend: R:R %s more, or half size.", input$s_pl_ctr %||% "-")); add(sprintf("No new deal %s minutes around a high-impact release in the holding time.", input$s_pl_news %||% "-"))
        add("Rule of Five (time-frames)", "heading 2"); r <- tryCatch(r5(), error = function(e) NULL)
        add(if (is.null(r)) "Base = the chart candle; minor and major from the course table." else sprintf("Base %s, minor %s, major %s. %s", r$base, r$minor, r$major, r$text))
        add("My plan points", "heading 2"); rl <- plan_rules(); for (i in which(nzchar(rl))) add(sprintf("%d. %s", i, rl[i])); if (!any(nzchar(rl))) add("(not typed yet in Setup)")
        add("Every deal is checked against these rules on the deal ticket; breaking one needs a written reason, saved with the trade.")
        print(d, target = f) }, contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    # ==== **** full course coverage ===================================================================================
    bars_cache <- new.env()
    cbars <- function(epic, res, days) { k <- paste(epic, res); x <- bars_cache[[k]]; if (!is.null(x) && difftime(now_fn(), x$at, units = "mins") < 30) return(x$b)
      b <- tryCatch(fetch_bars(epic, res, now_fn() - days * 86400, now_fn()), error = function(e) { cat("[C.C] candles", epic, res, ":", conditionMessage(e), "\n"); NULL })
      assign(k, list(b = b, at = now_fn()), envir = bars_cache); b }
    # Rule of Five (Week 7)
    r5 <- reactive({ s <- scan(); m <- scan_meta(); if (is.null(s) || is.null(m)) return(NULL); fr <- cc_r5_frames(m$res); if (is.null(fr)) return(NULL)
      tr <- function(res) { b <- cbars(m$epic, res, cc_r5_days[[res]]); if (is.null(b) || nrow(b) < 30) "unknown" else cc_dow_trend(b) }
      t <- c(minor = tr(fr$minor), base = cc_dow_trend(s$ctx$b), major = tr(fr$major)); c(fr, list(trends = t), cc_r5_verdict(t)) })
    output$c_r5 <- renderUI({ if (is.null(scan())) return(cc_rec_note("Load the chart first.")); r <- r5(); if (is.null(r)) return(cc_rec_note("No Rule of Five frames for this candle."))
      lab <- function(x) names(cc_candles)[match(x, cc_candles)] %||% x
      tagList(tags$table(class = "table table-condensed", style = "font-size:13px; max-width:620px;", tags$tr(tags$th("Time-frame"), tags$th("Capital.com candle"), tags$th("Trend (Dow highs / lows)")),
          tags$tr(tags$td("Minor (timing)"), tags$td(r$minor), tags$td(r$trends[["minor"]])), tags$tr(tags$td(tags$b("Base (your chart)")), tags$td(r$base), tags$td(r$trends[["base"]])),
          tags$tr(tags$td("Major (bigger trend)"), tags$td(r$major), tags$td(r$trends[["major"]]))),
        tags$div(style = paste0("font-weight:700; color:", if (isTRUE(r$agree)) "#166534" else "#334155", ";"), r$text), cc_rec_note(paste("Course table for this base:", r$course))) })
    # Support / resistance, pivots, Fibonacci (Weeks 1, 2, 6)
    srl <- reactive({ s <- scan(); m <- scan_meta(); if (is.null(s) || is.null(m)) return(NULL); cc_sr_levels(cbars(m$epic, "DAY", 60), s$ctx$c[s$ctx$n]) })
    fibl <- reactive({ s <- scan(); if (is.null(s)) NULL else cc_fib_levels(s$ctx) })
    output$c_sr <- renderUI({ s <- scan(); if (is.null(s)) return(cc_rec_note("Load the chart first.")); d <- srl(); f <- fibl(); px <- s$ctx$c[s$ctx$n]
      tagList(if (is.null(d)) cc_rec_note("Daily candles not available for this market.") else tagList(tags$div(style = "font-weight:700;", cc_sr_near(d, px)),
          tags$table(class = "table table-condensed", style = "font-size:12px; max-width:620px;", tags$tr(tags$th("Level"), tags$th("Price"), tags$th("Side"), tags$th("Distance")),
            lapply(seq_len(nrow(d)), function(i) tags$tr(tags$td(d$level[i]), tags$td(format(round(d$price[i], 4))), tags$td(d$side[i]), tags$td(sprintf("%+.4g", d$dist[i])))))),
        tags$div(style = "margin-top:4px;", tags$b("Fibonacci: "), cc_fib_text(f, px))) })
    output$c_osc <- renderUI({ s <- scan(); if (is.null(s)) return(cc_rec_note("Load the chart first.")); tags$ul(tags$li(cc_stoch_text(s$ctx)), tags$li(cc_divergence(s$ctx))) })
    # relative value spread with the first related market
    relv <- reactive({ s <- scan(); m <- scan_meta(); r <- related(); if (is.null(s) || is.null(r) || !nrow(r)) return(NULL); e <- r$epic[is.finite(r$corr)][1]; if (is.na(e)) return(NULL)
      b <- cbars(e, m$res, max(1, as.numeric(difftime(max(s$ctx$b$time), min(s$ctx$b$time), units = "days")))); z <- cc_spread_z(s$ctx$b, b); if (is.null(z)) NULL else c(z, list(epic = e)) })
    # Investment risks (Week 2)
    risk_tbl <- reactive({ t <- ticket(); f <- mkt(); a <- acct(); s <- scan(); if (is.null(f) || is.null(a) || is.null(t$risk_account)) return(NULL)
      cr <- tryCatch(corr_risk(t, f, a), error = function(e) list(note = "")); mf <- f$margin_factor %||% NA
      expo <- if (is.finite(t$margin_account %||% NA) && is.finite(mf) && mf > 0 && identical(f$margin_unit, "PERCENTAGE")) t$margin_account * 100 / mf else NA
      cc_risk_types(list(entry = if (identical(input$o_dir %||% "BUY", "BUY")) f$offer else f$bid, stop = tr_num0(input$o_stop, NA), risk_amt = t$risk_account, spread = f$offer - f$bid,
                         atr = if (is.null(s)) NA else s$ctx$a[s$ctx$n], hold_h = hold_h(), balance = a$balance, exposure = expo, news_hits = cc_news_line(news()), corr_note = cr$note, now = now_fn())) })
    output$p_risk <- renderUI({ r <- risk_tbl(); if (is.null(r)) return(cc_rec_note("Choose the market, read the account and fill the ticket (stop and size)."))
      col <- function(l) switch(l, high = "#b91c1c", medium = "#b45309", cost = "#b45309", "#166534")
      tags$table(class = "table table-condensed", style = "font-size:13px;", tags$tr(tags$th("Risk"), tags$th("Level"), tags$th("Why")),
        lapply(seq_len(nrow(r)), function(i) tags$tr(tags$td(r$risk[i]), tags$td(style = paste0("font-weight:700; color:", col(r$level[i]), ";"), r$level[i]), tags$td(r$detail[i])))) })
    # Post-trade reflection, biases, attitude survey (Week 4, Introduction)
    events_t <- reactive(tbl("events"))
    observe({ t <- trades(); c0 <- t[t$status %in% "CLOSED", , drop = FALSE]; c0 <- c0[order(c0$exit_ts, decreasing = TRUE), , drop = FALSE]
      updateSelectInput(session, "rf_pick", choices = if (nrow(c0)) setNames(c0$trade_id, sprintf("%s %s %s, closed %s", c0$trade_id, c0$direction, c0$epic, format(c0$exit_ts, "%d/%m %H:%M", tz = "Europe/London"))) else c("(none)" = "")) })
    observeEvent(input$rf_save, { id <- input$rf_pick; if (!nzchar(id %||% "")) { note("Choose a closed trade.", "warning"); return() }
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = id, event_type = "REFLECTION", note = sprintf("Plan followed: %s; felt: %s; lesson: %s", input$rf_plan, input$rf_feel, input$rf_lesson),
                                       response_json = cc_json(list(plan = input$rf_plan, feel = input$rf_feel, lesson = input$rf_lesson)), stringsAsFactors = FALSE)); touch()
      output$rf_out <- renderUI(tags$div(style = "color:#16a34a;", icon("check"), " Reflection saved with ", id, "."))
      updateTextAreaInput(session, "rf_lesson", value = "") })
    refl <- reactive({ e <- events_t(); e <- e[e$event_type %in% "REFLECTION", , drop = FALSE]; if (!nrow(e)) return(NULL)
      e <- e[order(e$saved_at), , drop = FALSE]; e <- e[!duplicated(e$trade_id, fromLast = TRUE), , drop = FALSE]
      e$plan <- vapply(e$response_json, function(j) tryCatch(jsonlite::fromJSON(j)$plan %||% NA_character_, error = function(x) NA_character_), ""); e })
    output$ps_plan <- renderTable({ r <- refl(); t <- trades(); if (is.null(r)) return(data.frame(Note = "No reflection saved yet (Positions tab)."))
      t <- t[t$status %in% "CLOSED", , drop = FALSE]; t$plan <- r$plan[match(t$trade_id, r$trade_id)]; t <- t[!is.na(t$plan), , drop = FALSE]; if (!nrow(t)) return(data.frame(Note = "No reflection on a closed trade."))
      pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est)
      do.call(rbind, lapply(split(seq_len(nrow(t)), t$plan), function(i) data.frame(`Plan followed` = t$plan[i[1]], Trades = length(i), `Win %` = round(100 * mean(pl[i] > 0)), `Net P/L` = round(sum(pl[i], na.rm = TRUE), 2), check.names = FALSE))) })
    output$ps_bias <- renderTable({ b <- cc_bias_checks(trades()); if (is.null(b)) data.frame(Note = "Needs at least 2 closed trades.") else setNames(b, c("Bias", "In your trades?", "Detail")) })
    attitude <- reactive({ e <- events_t(); e <- e[e$event_type %in% "ATTITUDE", , drop = FALSE]; if (!nrow(e)) return(NULL); e[order(e$saved_at), , drop = FALSE] })
    observeEvent(input$at_save, { x <- vapply(seq_along(cc_attitude_items), function(i) as.numeric(input[[paste0("at_", i)]] %||% NA), 0); sc <- cc_attitude_score(x)
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = NA_character_, event_type = "ATTITUDE", note = sprintf("Attitude survey %d / %d (%d%%): %s", sc$score, sc$max, sc$pct, sc$band),
                                       response_json = cc_json(list(answers = x, score = sc$score, pct = sc$pct)), stringsAsFactors = FALSE)); touch() })
    output$at_out <- renderUI({ a <- attitude(); if (is.null(a)) return(cc_rec_note("Not answered yet."))
      last <- tryCatch(jsonlite::fromJSON(utils::tail(a$response_json, 1)), error = function(e) NULL); sc <- if (is.null(last)) NULL else cc_attitude_score(last$answers)
      tagList(if (!is.null(sc)) tags$div(style = "font-weight:700;", sprintf("Latest: %d / %d (%d%%), %s.", sc$score, sc$max, sc$pct, sc$band), tags$br(), tags$span(style = "font-weight:400;", "Weakest: ", paste(sc$weakest, collapse = "; "))),
        if (nrow(a) > 1) tags$div(style = "font-size:12px; color:#475569;", "History: ", paste(sprintf("%s %s", format(a$saved_at, "%d/%m", tz = "Europe/London"), sub("Attitude survey ([0-9]+ / [0-9]+).*", "\\1", a$note)), collapse = " | "))) })
    observeEvent(input$p_build, { s <- scan(); f <- mkt(); a <- acct() %||% read_account()
      fail <- function(t) { scen_msg(list(FALSE, t)); note(t, "warning") }
      if (is.null(s) || is.null(f)) { fail("Load the market and its chart on tab 3 (Market & Patterns) first."); return() }
      if (isTRUE(scan_meta()$restored)) { fail("Tab 2 shows a saved scan: press 'Load chart & find patterns' for live prices first."); return() }
      if (is.null(a)) { fail("The account could not be read from Capital.com (see the log)."); return() }
      sz <- tr_num0(input$p_size, NA); if (!is.finite(sz) || sz <= 0) { fail("Type the size you want first."); return() }
      res <- tryCatch({
        f2 <- tryCatch(cc_market_facts(client$market(f$epic)), error = function(e) f); mkt(f2)   # fresh bid / offer
        flt <- list(frac = tr_num0(input$s_pl_filt_atr, 0.1), n = tr_num0(input$s_pl_filt_n, 1))
        sc <- cc_scenarios(s, f2$bid, f2$offer, f2$min_stop_distance, rrr_min(), cc_px_decimals(f2), filt = flt); sc$source <- "Rules"
        cs <- cc_course_scenarios(s, f2$bid, f2$offer, f2$min_stop_distance, rrr_min(), cc_px_decimals(f2))   # #5 course strategies found live
        if (!is.null(cs)) { cs$source <- "Course **"; sc <- rbind(sc[, names(cs)], cs) }
        sc$note <- paste0(sc$note, sprintf("; break filter **: close %.2f ATR beyond the level for %d candle(s)", flt$frac, as.integer(flt$n)))
        sc$claude_p <- NA_real_; sc$horizon_h <- NA_real_
        add_facts(sc, f2, a, sz) }, error = function(e) { cat("[C.C] scenarios failed:", conditionMessage(e), "\n"); fail(paste("The scenarios could not be worked out:", conditionMessage(e))); NULL })
      if (is.null(res)) return(); res <- add_htf(res, f$epic); scen(res); claude_info(NULL); save_scenarios(res, "BUILD")
      d <- attr(res, "d")
      scen_msg(list(TRUE, sprintf("%d market scenarios (deals) worked out at %s UK for size %s and a minimum Reward:Risk of %s, from the price then (bid %s / offer %s). Each is sent at the price of the moment you press Send; its stop and target keep their distances, so its R:R stays. %d blocked by a check.",
                                  nrow(res), format(now_fn(), "%H:%M:%S", tz = "Europe/London"), sz, cc_fmt(rrr_min(), 2), cc_fmt_px(mkt()$bid, d), cc_fmt_px(mkt()$offer, d), sum(res$blocked))))
      cat(sprintf("[C.C] scenarios: size %s, %d of %d blocked\n", sz, sum(res$blocked), nrow(res))) })
    scen_view <- reactive({ sc <- scen(); if (is.null(sc) || isTRUE(input$p_show_bad)) return(sc); a <- attributes(sc)[c("ccy", "d", "at")]; x <- sc[!sc$blocked, , drop = FALSE]; for (k in names(a)) attr(x, k) <- a[[k]]; x })
    output$p_scen <- DT::renderDT({ sc <- scen_view(); if (!is.null(sc) && !nrow(sc)) return(DT::datatable(data.frame(Note = "No scenario fits your trading plan right now (see the red line above). Tick 'Also show the scenarios that break my plan' to see them and why."), rownames = FALSE, options = list(dom = "t")))
      if (is.null(sc)) return(DT::datatable(data.frame(Note = "Type a size and press 'Work out the scenarios'."), rownames = FALSE, options = list(dom = "t")))
      cy <- attr(sc, "ccy"); d <- attr(sc, "d") %||% 4; hh <- hold_h()
      x <- data.frame(From = sc$source, Scenario = sc$id, `Price now` = cc_fmt_px(sc$now_px, d),
                      Entry = cc_fmt_px(sc$entry, d), `Entry vs now` = "at the price (deal)",
                      Stop = cc_fmt_px(sc$stop, d), `Stop vs now` = cc_vs_now(sc$stop, sc$now_px, d), Target = cc_fmt_px(sc$target, d), `Target vs now` = cc_vs_now(sc$target, sc$now_px, d),
                      `R:R` = round(sc$rrr, 2), `Plan *****` = sc$plan %||% "-", `Trend daily / 4h *` = if (is.null(sc$htf_d)) "-" else paste0(sc$htf_d, " / ", sc$htf_h4, "; phase: ", sc$htf_phase %||% "-"),
                      `With the trend? *` = if (is.null(sc$fit)) "-" else ifelse(sc$fit == "against", sprintf("AGAINST: needs R:R %.2f+ or half size", rrr_min() + tr_num0(input$s_pl_ctr, 0.5)), sc$fit),
                      `Confluence **` = sc$confl %||% "-", `Profile levels **` = sc$prof %||% "-", `News in holding time *` = sc$news %||% "-",
                      `Chance target first: measured` = cc_prob_text(sc$meas_p, sc$meas_n, sc$meas_und, round(hh, 1)),
                      `Chance: Claude's estimate` = ifelse(is.finite(sc$claude_p), sprintf("%.0f%% (estimate, not measured)", sc$claude_p), "-"),
                      `Risk` = cc_money(sc$risk_acc, cy), `% of balance` = round(sc$risk_pct, 2), Reward = cc_money(sc$reward_acc, cy),
                      `Balance if stop` = cc_money(sc$bal_stop, cy), `Balance if target` = cc_money(sc$bal_target, cy), Margin = cc_money(sc$margin, cy),
                      `Size for your plan risk` = round(sc$size_plan, 2), Checks = sc$checks, How = sc$note, `Patterns / reasons` = sc$basis, check.names = FALSE)
      dt <- DT::datatable(x, rownames = FALSE, options = list(dom = "t", scrollX = TRUE, pageLength = 12))
      # colour blocked rows only when there are some: an empty styleEqual() writes broken JavaScript and the table never draws
      if (any(sc$blocked)) dt <- DT::formatStyle(dt, "Scenario", target = "row", backgroundColor = DT::styleEqual(sc$id[sc$blocked], rep("#fee2e2", sum(sc$blocked))))
      if (any(sc$source == "Claude")) dt <- DT::formatStyle(dt, "From", backgroundColor = DT::styleEqual("Claude", "#ede9fe"))
      dt })
    output$p_scen_msg <- renderUI({ m <- scen_msg(); sc <- scen(); if (is.null(m)) return(NULL)
      common <- if (is.null(sc) || !nrow(sc) || is.null(sc$plan)) character(0) else Reduce(intersect, lapply(sc$plan, function(x) if (startsWith(x, "BREAKS: ")) strsplit(sub("^BREAKS: ", "", x), "; ", fixed = TRUE)[[1]] else character(0)))
      common <- common[!grepl("^Higher time-frame", common)]
      tagList(tags$div(style = sprintf("margin:6px 0; font-weight:700; color:%s;", if (m[[1]]) "#166534" else "#b91c1c"), m[[2]]),
        if (!is.null(sc) && nrow(sc)) { ok <- sum(!sc$blocked)
          tags$div(style = sprintf("margin:6px 0; padding:6px 10px; border-radius:8px; font-weight:700; background:%s; color:%s;", if (ok) "#dcfce7" else "#fee2e2", if (ok) "#166534" else "#991b1b"),
            if (ok) sprintf("%d of %d scenario(s) fit your trading plan (Plan ***** = OK or half size). Only these can be sent.", ok, nrow(sc))
            else paste0("No scenario fits your trading plan right now, so none can be sent", if (length(common)) paste0(": every one breaks ", paste(common, collapse = "; ")) else "", ". Wait until the rule is met (for example the session opens or the news window passes) and work them out again.")) }) })
    output$p_pick_ui <- renderUI({ sc <- scen(); if (is.null(sc)) return(NULL); sc <- sc[!sc$blocked, , drop = FALSE]; if (!nrow(sc)) return(cc_rec_note("No scenario that fits your plan to choose.")); radioButtons(session$ns("p_pick"), cc_rec_lab("Your choice (only scenarios that fit your plan)"), setNames(sc$id, sc$id), selected = character(0), inline = TRUE) })
    observeEvent(input$p_use, { sc <- scen(); k <- match(input$p_pick, sc$id); if (is.null(sc) || is.na(k)) { note("Choose a scenario first.", "warning"); return() }
      if (isTRUE(sc$blocked[k])) { note(paste("This scenario breaks your plan or a check:", sc$checks[k]), "error"); return() }
      r <- sc[k, ]; d <- attr(sc, "d") %||% 5; updateRadioButtons(session, "o_dir", selected = r$side); updateNumericInput(session, "o_stop", value = round(r$stop, d))
      updateNumericInput(session, "o_target", value = round(r$target, d))
      need <- rrr_min() + tr_num0(input$s_pl_ctr, 0.5); half <- identical(r$fit, "against") && is.finite(r$rrr) && r$rrr < need - 1e-9
      updateNumericInput(session, "o_size", value = if (half) max(r$size_plan %||% input$p_size, 0) * 0.5 else input$p_size)   # * counter-trend: sized down automatically
      if (half) note(sprintf("Against the higher time-frame trend with R:R %.2f (< %.2f): the size was set to HALF your plan size.", r$rrr, need), "warning")
      if (is.finite(r$horizon_h %||% NA)) updateNumericInput(session, "o_hours", value = r$horizon_h)
      note(sprintf("%s levels copied into the order ticket.%s Your reasoning boxes are left for you.", r$id, if (r$blocked) " It is blocked by a check: see Checks." else "")) })

    # ---- Claude's suggested trades: Capital.com data + patterns + (by default) today's Morning Sheet from BigQuery
    if (is.null(morning_fn)) morning_fn <- function(day) {
      if (is.null(api_manager) || !isTRUE(api_manager$bq_authenticated)) return(list(ok = FALSE, why = "BigQuery is not connected."))
      st <- tr_make_store(tr_bq_backend(api_manager)); sh <- tr_read_current(st, "morning_sheets")
      has <- !is.null(sh) && nrow(sh) && any(!is.na(sh$sheet_date) & as.Date(sh$sheet_date) == day)
      if (!has) return(list(ok = FALSE, why = sprintf("No Morning Sheet for %s in BigQuery.", format(day, "%d/%m/%Y")), missing = TRUE))
      ms <- tryCatch(cc_morning_sheet(sh, tryCatch(tr_read_current(st, "morning_levels"), error = function(e) NULL), day),
                     error = function(e) { cat("[C.C] Morning Sheet found but not read:", conditionMessage(e), "\n"); list(error = conditionMessage(e)) })
      if (!is.null(ms$error)) list(ok = FALSE, why = sprintf("Today's Morning Sheet IS in BigQuery but the app could not read it (%s). Please report this.", ms$error), missing = FALSE)
      else c(list(ok = TRUE), ms) }
    ms_today <- reactiveVal(NULL)
    load_ms <- function() { day <- as.Date(format(now_fn(), "%Y-%m-%d", tz = "Europe/London"))
      r <- tryCatch(morning_fn(day), error = function(e) list(ok = FALSE, why = paste("Could not read it:", conditionMessage(e)), missing = FALSE))
      cat("[C.C] Morning Sheet of", format(day), ":", if (isTRUE(r$ok)) "found" else r$why, "\n"); ms_today(r); r }
    observeEvent(input$p_ms_reload, load_ms())
    output$p_ms_ui <- renderUI({ r <- ms_today(); if (is.null(r)) r <- isolate(load_ms())
      if (isTRUE(r$ok)) tagList(radioButtons(session$ns("p_ms_use"), cc_rec_lab("Include today's Morning Sheet"), c("Yes" = "yes", "No" = "no"), selected = isolate(input$p_ms_use) %||% "yes", inline = TRUE),
                                tags$div(style = "font-size:12px; color:#166534;", icon("check"), sprintf(" Today's Morning Sheet found in BigQuery (saved %s UK).", format(r$saved_at, "%H:%M", tz = "Europe/London"))))
      else tagList(radioButtons(session$ns("p_ms_use"), cc_rec_lab("Include today's Morning Sheet"), c("Not available" = "no"), selected = "no", inline = TRUE),
                   tags$div(style = "font-size:12px; color:#b45309; font-weight:700;", icon("triangle-exclamation"), " ", r$why,
                            if (isTRUE(r$missing)) " This option is not available until you make today's sheet (2. Morning Sheet), then press 'Look again'. Your plan expects one before any trade." else "")) })
    claude_info <- reactiveVal(NULL)
    observeEvent(input$p_claude, { sc <- scen(); s <- scan(); f <- mkt(); a <- acct()
      if (is.null(sc) || is.null(s) || is.null(f) || is.null(a)) { note("Work out the scenarios first (it reads the price now).", "warning"); return() }
      asked <- identical(input$p_ms_use, "yes"); r <- if (asked) tryCatch(ms_today() %||% load_ms(), error = function(e) list(ok = FALSE, why = conditionMessage(e))) else NULL
      use <- asked && isTRUE(r$ok); t0 <- Sys.time(); p <- ""; tx <- ""
      res <- tryCatch({
        f2 <- tryCatch(cc_market_facts(client$market(f$epic)), error = function(e) f); mkt(f2)
        pcs <- lapply(c("BUY", "SELL"), function(sd) tryCatch(cbind(side = sd, cc_plan_check(plan_args(sd, NA, tr_num0(input$p_size, NA), NA, "OTHER", f2, a, list(pct = NA, note = ""))), stringsAsFactors = FALSE), error = function(e) NULL))
        pc <- do.call(rbind, pcs); pc <- if (is.null(pc)) NULL else pc[!grepl("^(Deals per day|Daily loss|Correlated|Plan point)", pc$rule) | pc$side == "BUY", , drop = FALSE]
        rules_text <- if (is.null(pc)) "" else paste(sprintf("- [%s] %s: %s (%s)", pc$side, pc$rule, ifelse(is.na(pc$ok), "not set / no limit", ifelse(pc$ok, "OK now", "FAILS now")), pc$detail), collapse = "\n")
        plan <- list(min_rrr = rrr_min(), risk_pct = input$s_risk, hold_h = round(hold_h(), 1), rules_text = rules_text)
        rules <- sc[sc$source != "Claude", , drop = FALSE]
        p <- cc_suggest_prompt(s, f2, rules, plan, if (use) r$text else NULL, now_fn())
        cat(sprintf("[C.C] asking Claude for suggested trades %s (prompt %d characters)\n", if (use) "WITH the Morning Sheet" else "without the Morning Sheet", nchar(p)))
        x <- withProgress(message = sprintf("Claude is working out suggested trades%s...", if (use) " with the Morning Sheet" else ""), value = 0.5, vision_fn(p))
        tx <- if (is.list(x)) x$text else x; out <- cc_suggest_parse(tx, f2, rrr_min())
        if (!isTRUE(out$ok)) stop(out$error)
        if (!is.null(out$estimates)) rules$claude_p <- out$estimates$claude_p[match(rules$id, out$estimates$id)]
        sz <- tr_num0(input$p_size, NA); cl <- if (!is.null(out$rows) && nrow(out$rows)) add_facts(out$rows, f2, a, sz) else NULL
        rules <- add_facts(rules, f2, a, sz)
        keep <- intersect(names(rules), if (is.null(cl)) names(rules) else names(cl)); all <- rbind(rules[, keep, drop = FALSE], if (!is.null(cl)) cl[, keep, drop = FALSE])
        for (k in c("ccy", "d", "at")) attr(all, k) <- attr(rules, k); all <- add_htf(all, f2$epic); scen(all); save_scenarios(all, if (use) "CLAUDE_WITH_MS" else "CLAUDE")
        cl2 <- all[all$source == "Claude", , drop = FALSE]
        list(ok = TRUE, text = out$summary, stand = out$stand_aside %||% "", n = nrow(cl2), fit = sum(!cl2$blocked), used = use, rows = cl2)
      }, error = function(e) list(ok = FALSE, text = conditionMessage(e), used = use, n = 0L, fit = 0L))
      res$asked <- asked; res$ms_why <- if (asked && !use) (r$why %||% "not found for today") else ""; res$secs <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
      claude_info(res)
      w <- tryCatch(store$write("claude_suggestions", data.frame(call_id = cc_id("CS"), epic = f$epic, morning_sheet_asked = asked, morning_sheet_used = isTRUE(res$used),
        morning_sheet_note = res$ms_why, ok = isTRUE(res$ok), seconds = res$secs, n_suggested = as.integer(res$n %||% 0L), n_fit_plan = as.integer(res$fit %||% 0L), summary = if (isTRUE(res$ok)) res$text else "",
        stand_aside_reason = res$stand %||% "", error = if (isTRUE(res$ok)) "" else res$text, prompt_chars = nchar(p), rows_json = if (is.null(res$rows)) "[]" else cc_json(res$rows[, intersect(c("id", "side", "entry", "stop", "target", "rrr", "claude_p", "blocked", "plan", "note"), names(res$rows))]),
        reply_text = tx, stringsAsFactors = FALSE)), error = function(e) paste("not saved:", conditionMessage(e)))
      cat(sprintf("[C.C] Claude suggestions: ok=%s, %s trade(s), %s fit the plan, %.1fs, Morning Sheet %s; saved: %s\n", isTRUE(res$ok), res$n %||% 0, res$fit %||% 0, res$secs,
                  if (isTRUE(res$used)) "used" else if (asked) paste("NOT loaded:", res$ms_why) else "not asked", w)) })
    output$p_claude_out <- renderUI({ r <- claude_info(); if (is.null(r)) return(NULL)
      ms <- if (isTRUE(r$asked) && !isTRUE(r$used)) tags$div(style = "color:#b45309; font-weight:700;", "Morning Sheet asked for but NOT loaded (", r$ms_why, "): Claude worked without it.") else NULL
      if (!isTRUE(r$ok)) return(tags$div(style = "color:#b91c1c; font-weight:700; margin-top:6px;", ms, "Claude could not suggest trades: ", r$text, sprintf(" (after %.0f s). The call is saved in cc_claude_suggestions.", r$secs %||% NA)))
      if (!isTRUE(r$n > 0)) return(tags$div(style = "font-size:12.5px; margin-top:6px; background:#fef3c7; border:1px solid #fcd34d; border-radius:8px; padding:6px 10px;", ms,
        tags$b(sprintf("Claude suggests NO trade now %s. ", if (isTRUE(r$used)) "using today's Morning Sheet" else "without the Morning Sheet")),
        if (nzchar(r$stand %||% "")) tags$span(tags$b("Stand aside: "), r$stand, " "), r$text, tags$div(style = "color:#64748b;", sprintf("Answer in %.0f s; saved in cc_claude_suggestions.", r$secs %||% NA))))
      tags$div(style = "font-size:12.5px; margin-top:6px; background:#f5f3ff; border:1px solid #ddd6fe; border-radius:8px; padding:6px 10px;",
        ms, tags$b(sprintf("Claude suggested %d trade(s) %s; %d fit your plan (rows marked Claude in the table). ", r$n, if (isTRUE(r$used)) "using today's Morning Sheet" else "WITHOUT the Morning Sheet", r$fit)),
        r$text, tags$div(style = "color:#64748b; margin-top:3px;", "Claude's chance is an estimate; the measured chance comes from Capital.com's own candles. Nothing Claude writes is copied into your reasoning boxes.")) })

    ticket <- reactive({ f <- mkt(); a <- acct(); sz <- tr_num0(input$o_size, NA); type <- "MARKET"   # deals only: never a working order
      entry <- if (is.null(f)) NA else if (input$o_dir == "BUY") f$offer else f$bid
      if (is.null(f) || is.null(a)) return(list(errors = "Choose the market (tab 3 (Market & Patterns)) and read the account first.", warnings = character(0)))
      fx <- fx_info(f$currency, a$currency)
      b <- cc_budget(input$o_dir, entry, tr_num0(input$o_stop, NA), tr_num0(input$o_target, NA), sz, f$lot_size, fx$rate, a$balance, a$available, f$margin_factor, f$margin_unit,
                     f$offer - f$bid, open_risk(), input$s_risk, input$s_cap, rrr_min(), f$min_size, f$min_stop_distance)
      b$errors <- c(b$errors, cc_order_problems(input$o_dir, "MARKET", NA, tr_num0(input$o_stop, NA), tr_num0(input$o_target, NA), f$bid, f$offer, f$min_stop_distance))
      if (!isTRUE(client$is_demo())) b$errors <- c(b$errors, "The connection is not the DEMO environment: this app does not send orders.")
      mr <- rrr_min()   # the minimum reward:risk (box 2) is a rule, not a warning: the deal is blocked below it
      if (is.finite(mr) && is.finite(b$rrr) && b$rrr < mr - 1e-6) { b$warnings <- setdiff(b$warnings, grep("Reward:risk", b$warnings, value = TRUE))
        b$errors <- c(b$errors, sprintf("Reward:risk %.2f is below your minimum %.2f: move the target or the stop (box 2 sets the minimum; your strategy's is in Setup).", b$rrr, mr)) }
      b$errors <- unique(b$errors)
      s <- scan(); if (!is.null(s) && s$regime == "MIXED") b$warnings <- c(b$warnings, "Regime is MIXED (ADX between your thresholds): your plan says no trade.")
      d <- cc_px_decimals(f); stp <- tr_num0(input$o_stop, NA)
      if (!is.null(s) && is.finite(stp) && is.finite(entry)) { atr <- s$ctx$a[s$n]; sd <- abs(entry - stp)
        if (is.finite(atr) && atr > 0 && sd < 0.5 * atr) b$warnings <- c(b$warnings, sprintf("The stop is only %s from the entry (%.2f x ATR %s): ordinary %s-minute swings may hit it.", cc_fmt_px(sd, d), sd / atr, cc_fmt_px(atr, d), s$ctx$minutes)) }
      for (k in c("o_stop", "o_target")) { v <- tr_num0(input[[k]], NA); if (is.finite(v) && abs(v - round(v, d)) > 1e-9) b$warnings <- c(b$warnings, sprintf("%s has more than %d decimals: it will be sent as %s.", c(o_stop = "The stop", o_target = "The target")[[k]], d, cc_fmt_px(round(v, d), d))) }
      c(b, list(entry = entry, ccy = a$currency, fx = fx, d = d, now = if (input$o_dir == "BUY") f$offer else f$bid)) })
    output$o_checks <- renderUI({ t <- ticket()
      tagList(if (is.finite(t$risk_account %||% NA)) tags$div(style = "background:#fff; border-radius:8px; padding:8px 12px; margin:6px 0; font-size:13px;",
                sprintf("Price now %s | entry %s | stop %s (%s from now) | target %s (%s from now) | risk %s points = %s (%s%% of balance) | reward %s | R:R %s | balance if stopped %s, if target %s | margin %s",
                        cc_fmt_px(t$now, t$d), cc_fmt_px(t$entry, t$d), cc_fmt_px(tr_num0(input$o_stop, NA), t$d), cc_vs_now(tr_num0(input$o_stop, NA), t$now, t$d),
                        cc_fmt_px(tr_num0(input$o_target, NA), t$d), cc_vs_now(tr_num0(input$o_target, NA), t$now, t$d), cc_fmt(t$risk_points, 4), cc_money(t$risk_account, t$ccy), cc_fmt(t$risk_pct, 2), cc_money(t$reward_account, t$ccy), cc_fmt(t$rrr, 2),
                        cc_money(t$balance_if_stop, t$ccy), cc_money(t$balance_if_target, t$ccy), cc_money(t$margin_account, t$ccy))),
        if (length(t$errors)) tags$div(style = "color:#b91c1c; font-weight:700;", icon("circle-xmark"), " ", paste(t$errors, collapse = " ")),
        if (length(t$warnings)) tags$div(style = "color:#b45309;", icon("triangle-exclamation"), " ", paste(t$warnings, collapse = " "))) })
    observeEvent(input$o_send, { t <- ticket()
      if (length(t$errors)) { note(paste(t$errors, collapse = " "), "error"); return() }
      if (!isTRUE(input$o_ok)) { note("Tick the box to confirm you have checked the order.", "warning"); return() }
      pc <- plan_chk(); bad <- if (is.null(pc)) character(0) else pc$rule[!is.na(pc$ok) & !pc$ok]
      if (length(bad) && !nzchar(trimws(input$o_break %||% ""))) { note(paste0("This deal breaks your plan (", paste(bad, collapse = "; "), "). Write the reason in 'Reason for breaking a rule' to send it anyway."), "error"); return() }
      f <- mkt(); showModal(modalDialog(title = "Open this deal on the Capital.com DEMO account?",
        tags$p(sprintf("%s %s of %s at the market (a deal, active at once), stop %s, target %s, Reward:Risk %s.", input$o_dir, input$o_size, f$name %||% f$epic, input$o_stop, input$o_target, cc_fmt(t$rrr, 2))),
        tags$p(sprintf("Money at risk to the stop: %s (%s%% of your balance).", cc_money(t$risk_account, t$ccy), cc_fmt(t$risk_pct, 2))),
        if (length(t$warnings)) tags$p(style = "color:#b45309;", paste(t$warnings, collapse = " ")),
        footer = tagList(modalButton("No, go back"), actionButton(session$ns("o_confirm"), "Yes, send it", class = "btn-danger")))) })
    observeEvent(input$o_confirm, { removeModal(); f0 <- mkt(); a <- acct(); t <- ticket(); s <- scan()
      gt <- NA_real_
      # the price of this moment (the ticket may be minutes old), and every price rounded to the market's decimals
      f <- tryCatch(cc_market_facts(client$market(f0$epic)), error = function(e) f0); if (!is.finite(f$bid %||% NA)) f <- f0; mkt(f)
      d <- cc_px_decimals(f); typ <- "MARKET"; lvl <- NA_real_
      stp <- cc_round_px(tr_num0(input$o_stop, NA), d); tgt <- cc_round_px(tr_num0(input$o_target, NA), d); shift_note <- ""
      if (typ == "MARKET") { now_px <- if (input$o_dir == "BUY") f$offer else f$bid; sh <- cc_shift_levels(t$entry, now_px, stp, tgt, d)
        if (is.finite(sh$shift) && abs(sh$shift) >= 10^-d / 2) {
          shift_note <- sprintf(" The price moved %s%s since the ticket was worked out (%s to %s), so the stop (%s) and the target (%s) moved with it, keeping their distances.",
                                if (sh$shift > 0) "+" else "-", cc_fmt_px(abs(sh$shift), d), cc_fmt_px(t$entry, d), cc_fmt_px(now_px, d), cc_fmt_px(sh$stop, d), cc_fmt_px(sh$target, d))
          stp <- sh$stop; tgt <- sh$target } }
      prob <- cc_order_problems(input$o_dir, typ, lvl, stp, tgt, f$bid, f$offer, f$min_stop_distance)
      if (length(prob)) { cat("[C.C] order not sent:", paste(prob, collapse = " "), "\n"); note(paste(prob, collapse = " "), "error")
        output$o_result <- renderUI(tags$div(style = "margin-top:8px; font-weight:700; color:#b91c1c;", "Not sent (nothing reached Capital.com): ", paste(prob, collapse = " "),
                                             sprintf(" Price now: bid %s / offer %s.", cc_fmt_px(f$bid, d), cc_fmt_px(f$offer, d)))); return() }
      cat(sprintf("[C.C] sending %s %s size %s %s: entry %s, stop %s, target %s (%d decimals)%s\n", input$o_dir, typ, input$o_size, f$epic, if (typ == "MARKET") "at the market" else cc_fmt_px(lvl, d),
                  cc_fmt_px(stp, d), cc_fmt_px(tgt, d), d, if (nzchar(shift_note)) sprintf(", shifted %s", cc_fmt_px(sh$shift, d)) else ""))
      res <- tryCatch(client$open_position(f$epic, input$o_dir, input$o_size, stp, tgt),   # a deal (position), never a working order
                      error = function(e) list(dealStatus = "ERROR", reason = conditionMessage(e)))
      if (!identical(toupper(res$dealStatus %||% ""), "ACCEPTED")) { res$reason <- cc_explain_error(res$reason %||% res$dealStatus); cat("[C.C] order not accepted:", res$reason, "\n") }
      accepted <- identical(toupper(res$dealStatus %||% ""), "ACCEPTED"); tid <- cc_id("CC"); scan_id <- NA_character_
      if (!is.null(s)) scan_id <- tryCatch(as.character(save_scan(trade_id = tid, note = "chart at order")), error = function(e) { cat("[C.C] scan not saved:", conditionMessage(e), "\n"); NA_character_ })
      row <- data.frame(trade_id = tid, record_version = 1L, source = "APP", environment = client$environment(), account_id = a$account_id, account_currency = a$currency,
        epic = f$epic, market_name = f$name, instrument_currency = f$currency, direction = input$o_dir, size = input$o_size, lot_size = f$lot_size, order_type = "MARKET",
        order_level = if (TRUE) NA else lvl, good_till = if (is.finite(gt)) now_fn() + gt * 3600 else NA, deal_reference = res$dealReference %||% NA,
        # market order: deal_id = the POSITION's id (as the positions list shows it), order_deal_id = the confirmation's id
        order_deal_id = res$dealId %||% NA, deal_id = if (TRUE) res$position_deal_id %||% res$dealId %||% NA else NA,
        status = if (!accepted) "REJECTED" else if (TRUE) "OPEN" else "ORDER_WORKING", placed_ts = now_fn(),
        entry_ts = if (accepted && TRUE) cc_ts(res$date) else NA, entry_level = if (accepted && TRUE) cc_num(res$level) else NA,
        stop_initial = stp, stop_level = stp, target_level = tgt, fx_rate = t$fx$rate, risk_account = t$risk_account, reward_account = t$reward_account,
        purpose = input$o_purpose, strategy = input$o_strategy, chart_period = input$o_chart, expected_hours = tr_num0(input$o_hours, NA),
        setup_fund = input$o_fund, setup_tech = input$o_tech, trigger_text = input$o_trigger, execution_text = input$o_exec, stop_reason = input$o_stopwhy, target_reason = input$o_tgtwhy,
        mood_entry = input$o_mood, scan_id = scan_id, scenario_json = cc_scenario_snapshot(scen(), input$p_pick, isTRUE(input$o_c_incl), claude_info(), hold_h()),
        warnings = paste(t$warnings, collapse = " "), notes = if (accepted) NA else paste("Not accepted:", res$reason %||% res$dealStatus), stringsAsFactors = FALSE)
      if (accepted && TRUE && is.finite(row$entry_level)) {   # the money at risk from the real fill
        b2 <- cc_budget(input$o_dir, row$entry_level, stp, tgt, input$o_size, f$lot_size, t$fx$rate, a$balance, a$available)
        row$risk_account <- b2$risk_account; row$reward_account <- b2$reward_account }
      saved_where <- store$write("trades", row)
      cat(sprintf("[C.C] trade %s recorded (%s) as %s\n", tid, saved_where, row$status))
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = tid, event_type = "ORDER_MARKET", deal_reference = row$deal_reference, deal_id = res$dealId %||% NA,
                                       deal_status = res$dealStatus %||% NA, level = cc_num(res$level), stop_level = stp, target_level = tgt,
                                       request_json = cc_json(res$request %||% list()), response_json = cc_json(res[setdiff(names(res), "request")]), note = res$reason %||% NA))
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = tid, event_type = "PRE_TRADE", note = sprintf("Mood %s, confidence %s (1-5)", input$o_mood, input$o_conf %||% NA),
                                       response_json = cc_json(list(mood = input$o_mood, confidence = input$o_conf)), stringsAsFactors = FALSE))
      pc <- isolate(plan_chk()); if (!is.null(pc)) { bad <- pc[!is.na(pc$ok) & !pc$ok, , drop = FALSE]
        store$write("events", data.frame(event_id = cc_id("EV"), trade_id = tid, event_type = "PLAN_CHECK",
          note = paste0(if (nrow(bad)) paste0("Rules broken: ", paste(bad$rule, collapse = "; "), ". Reason: ", trimws(input$o_break %||% "")) else "All plan rules met.",
                        " | ", paste(sprintf("%s: %s", pc$rule, ifelse(is.na(pc$ok), "not set", ifelse(pc$ok, "ok", "BROKEN"))), collapse = "; ")), stringsAsFactors = FALSE)) }
      touch(); read_account(); updateCheckboxInput(session, "o_ok", value = FALSE)
      output$o_result <- renderUI(tags$div(style = sprintf("margin-top:8px; font-weight:700; color:%s;", if (accepted) "#166534" else "#b91c1c"),
        if (accepted) sprintf("Deal opened on Capital.com (it is in Trades now): %s, deal %s%s. Stop %s, target %s. Saved as %s.%s", res$dealStatus, res$dealId %||% "-", if (TRUE) sprintf(", filled at %s", cc_fmt_px(cc_num(res$level), d)) else sprintf(", %s at %s", tolower(typ), cc_fmt_px(lvl, d)),
                              cc_fmt_px(stp, d), cc_fmt_px(tgt, d), tid, paste0(shift_note, if (identical(saved_where, "bigquery")) " Recorded in BigQuery (cc_trades) as OPEN. *****" else " Recorded; it is uploaded to BigQuery (cc_trades) when BigQuery is connected. *****"))
        else sprintf("Not accepted: %s Saved as %s with status REJECTED.", res$reason %||% res$dealStatus, tid)))
      note(if (accepted) "Deal opened." else "Deal not accepted.", if (accepted) "message" else "error") })

    # ---- positions, orders, sync -------------------------------------------------------------------------------
    live <- reactiveVal(list(pos = data.frame(), ord = data.frame(), at = NULL))
    read_live <- function() { if (!client$connected()) return(invisible(NULL))
      p <- tryCatch(cc_positions_df(client$positions()), error = function(e) { note(conditionMessage(e), "error"); data.frame() })
      o <- tryCatch(cc_orders_df(client$working_orders()), error = function(e) data.frame()); live(list(pos = p, ord = o, at = now_fn())); invisible(TRUE) }
    output$closed_tbl <- DT::renderDT({ t <- trades(); t <- t[t$status %in% "CLOSED", , drop = FALSE]
      if (nrow(t)) t <- t[is.na(t$exit_ts) | t$exit_ts >= now_fn() - 14 * 86400, , drop = FALSE]
      if (!nrow(t)) return(DT::datatable(data.frame(Note = "No closed trades in the last 14 days (press Sync)."), rownames = FALSE, options = list(dom = "t")))
      t <- t[order(t$exit_ts, decreasing = TRUE), , drop = FALSE]
      pnl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est)
      d <- data.frame(Trade = t$trade_id, Market = t$market_name %||% t$epic, Side = t$direction, Size = t$size, Entry = t$entry_level,
                      Exit = ifelse(is.finite(t$exit_level) & t$exit_level > 0, format(t$exit_level), "not known yet"),
                      Closed = format(t$exit_ts, "%d %b %H:%M", tz = "Europe/London"), `Exit code` = t$exit_code,
                      Result = sprintf("%s%s", cc_money(pnl, t$account_currency), ifelse(is.finite(t$pnl_account_booked), " (booked)", " (estimate)")), check.names = FALSE)
      DT::datatable(d, rownames = FALSE, options = list(dom = "t", pageLength = 20)) })
    do_sync <- function() { if (!ready()) return(); read_live(); a <- read_account(); lv <- live()
      tr <- trades(); last <- if (nrow(tr)) suppressWarnings(max(c(tr$placed_ts, tr$entry_ts), na.rm = TRUE)) else -Inf
      from <- max(now_fn() - 7 * 86400, if (is.finite(as.numeric(last))) last - 86400 else now_fn() - 2 * 86400)
      act <- tryCatch(cc_activity_df(cc_activity_range(client, from, now_fn())), error = function(e) { note(paste("Activity:", conditionMessage(e)), "warning"); data.frame() })
      tx <- tryCatch(cc_transactions_df(cc_transactions_range(client, from, now_fn())), error = function(e) { note(paste("Transactions:", conditionMessage(e)), "warning"); data.frame() })
      if (nrow(act)) { act$row_id <- paste(act$deal_id, act$date_utc, act$type, act$status); old <- tbl("activity"); new <- act[!(act$row_id %in% old$row_id), , drop = FALSE]; if (nrow(new)) store$write("activity", new) }
      if (nrow(tx)) { tx$row_id <- paste(tx$reference, tx$date_utc, tx$type, tx$amount); old <- tbl("transactions"); new <- tx[!(tx$row_id %in% old$row_id), , drop = FALSE]; if (nrow(new)) store$write("transactions", new) }
      if (!is.null(a)) store$write("account", data.frame(snap_id = cc_id("AC"), account_id = a$account_id, currency = a$currency, balance = a$balance, deposit = a$deposit, profit_loss = a$profit_loss, available = a$available))
      # everything earlier syncs saved + what was just read (transactions: Capital.com gives only the last 24 hours)
      both <- function(old, new) { if (!nrow(new)) return(old); if (!nrow(old)) return(new); cm <- intersect(names(old), names(new))
        x <- rbind(old[, cm, drop = FALSE], new[, cm, drop = FALSE]); x[!duplicated(x$row_id, fromLast = TRUE), , drop = FALSE] }
      act <- both(tbl("activity"), act); tx <- both(tbl("transactions"), tx)
      rc <- cc_reconcile(tr, lv$pos, lv$ord, act, tx, account_currency = a$currency %||% NA, fx_fun = function(ccy) fx_info(ccy, a$currency %||% NA)$rate, now = now_fn())
      if (!is.null(rc$updated)) { up <- rc$updated; if (!is.null(a)) up$balance_after[up$status == "CLOSED" & is.na(up$balance_after)] <- a$balance; store$write("trades", up) }
      if (!is.null(rc$new)) store$write("trades", rc$new); if (!is.null(rc$events)) store$write("events", rc$events)
      touch(); output$sync_out <- renderUI(tags$div(style = "font-size:12.5px; margin:6px 0;", tags$b(sprintf("Synced at %s UK. ", format(now_fn(), "%H:%M:%S", tz = "Europe/London"))),
        if (length(rc$messages)) tags$ul(lapply(rc$messages, tags$li)) else "No changes needed.", tags$div(style = "margin-top:4px;", cc_trades_state(tbl("trades"))))) }
    # ***** recorded deals in Plan & Order: open ones from BigQuery, closed today; the check runs the same sync as Positions
    output$o_open_tbl <- DT::renderDT({ tr <- trades(); now <- now_fn(); day <- format(now, "%Y-%m-%d", tz = "Europe/London")
      x <- tr[tr$status %in% c("OPEN", "ORDER_WORKING") | (tr$status %in% "CLOSED" & format(tr$exit_ts, "%Y-%m-%d", tz = "Europe/London") %in% day), , drop = FALSE]
      if (!nrow(x)) return(DT::datatable(data.frame(Note = "No deal recorded as open, and none closed today."), rownames = FALSE, options = list(dom = "t")))
      x <- x[order(x$status != "OPEN", -as.numeric(x$placed_ts)), , drop = FALSE]; pl <- ifelse(is.finite(x$pnl_account_booked), x$pnl_account_booked, x$pnl_account_est)
      DT::datatable(data.frame(Trade = x$trade_id, Status = x$status, Market = x$epic, Side = x$direction, Size = x$size, `Opened (UK)` = format(x$entry_ts, "%d/%m %H:%M", tz = "Europe/London"),
        Entry = x$entry_level, Stop = x$stop_level, Target = x$target_level, `Closed (UK)` = ifelse(is.na(x$exit_ts), "", format(x$exit_ts, "%d/%m %H:%M", tz = "Europe/London")),
        Exit = x$exit_level, Code = x$exit_code, `Result (acct ccy)` = round(pl, 2), `Deal id` = x$deal_id, check.names = FALSE),
        rownames = FALSE, options = list(dom = "t", pageLength = 20, scrollX = TRUE)) })
    observeEvent(input$o_check, { cat("[C.C] Check recorded deals pressed\n"); tryCatch({ if (!isTRUE(ready())) stop("Capital.com is not connected (API Configuration)."); do_sync(); output$o_check_out <- renderUI(tags$div(style = "color:#166534; font-weight:700; margin:6px 0;",
        icon("check"), sprintf(" Checked on Capital.com at %s UK; BigQuery updated. Details in the Positions tab.", format(now_fn(), "%H:%M:%S", tz = "Europe/London")))) },
      error = function(e) output$o_check_out <- renderUI(tags$div(style = "color:#b91c1c; font-weight:700;", "Check failed: ", conditionMessage(e)))) })
    observeEvent(input$sync, { cat("[C.C] Sync pressed\n"); tryCatch(do_sync(), error = function(e) { cat("[C.C] Sync failed:", conditionMessage(e), "\n")
      output$sync_out <- renderUI(tags$div(style = "color:#b91c1c; font-weight:700;", "Sync failed: ", conditionMessage(e))) }) })
    # records check once per session, as soon as BigQuery is there: no Capital.com needed (uses the saved history)
    checked <- reactiveVal(FALSE)
    observe({ if (checked()) return(); if (!isTRUE(tryCatch(store$connected(), error = function(e) FALSE))) { invalidateLater(3000); return() }
      checked(TRUE)
      rc <- tryCatch(cc_repair_records(tbl("trades"), tbl("activity"), tbl("transactions")), error = function(e) { cat("[C.C] records check failed:", conditionMessage(e), "\n"); NULL })
      if (is.null(rc)) return()
      if (!is.null(rc$updated)) store$write("trades", rc$updated); if (!is.null(rc$events)) store$write("events", rc$events)
      cat("[C.C] records check:", if (length(rc$messages)) paste(rc$messages, collapse = " | ") else "all trades consistent", "\n")
      if (length(rc$messages)) { touch(); note(paste(rc$messages, collapse = " "), "message")
        output$sync_out <- renderUI(tags$div(style = "font-size:12.5px; margin:6px 0;", tags$b("Records check (from the saved history): "), tags$ul(lapply(rc$messages, tags$li)))) } })
    observe({ if (!isTRUE(input$auto_sync)) return(); invalidateLater(60000); isolate(if (client$connected()) read_live()) })
    output$pos_tbl <- DT::renderDT({ p <- live()$pos; if (!nrow(p)) return(DT::datatable(data.frame(Note = "No open positions (press Sync)."), rownames = FALSE, options = list(dom = "t")))
      a <- acct(); cy <- a$currency %||% ""; fx <- vapply(p$currency, function(z) fx_info(z, cy)$rate, 0)
      DT::datatable(data.frame(Market = p$name, Epic = p$epic, Direction = p$direction, Size = p$size, Entry = p$level, Stop = p$stop_level, Target = p$profit_level,
                               `Open P/L` = cc_money(p$upl, p$currency), `Open P/L (account)` = cc_money(p$upl * fx, cy), Opened = p$created_utc, `Deal ID` = p$deal_id, check.names = FALSE),
                    rownames = FALSE, options = list(dom = "t", scrollX = TRUE)) })
    observe({ p <- live()$pos; updateSelectInput(session, "pos_pick", choices = if (nrow(p)) setNames(p$deal_id, sprintf("%s %s %s @ %s", p$direction, p$size, p$epic, p$level)) else c("(none)" = "")) })
    output$ord_tbl <- DT::renderDT({ o <- live()$ord; if (!nrow(o)) return(DT::datatable(data.frame(Note = "No working orders."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(o[, c("name", "epic", "direction", "type", "size", "level", "stop_distance", "profit_distance", "good_till", "deal_id")], rownames = FALSE, options = list(dom = "t", scrollX = TRUE)) })
    observe({ o <- live()$ord; updateSelectInput(session, "ord_pick", choices = if (nrow(o)) setNames(o$deal_id, sprintf("%s %s %s %s @ %s", o$type, o$direction, o$size, o$epic, o$level)) else c("(none)" = "")) })
    trade_of <- function(deal_id) { t <- trades(); if (!nrow(t)) return(NULL); t <- t[!(t$status %in% "DUPLICATE"), , drop = FALSE]
      r <- t[t$deal_id %in% deal_id | t$order_deal_id %in% deal_id, , drop = FALSE]; if (nrow(r)) r[1, ] else NULL }
    new_version <- function(r, ...) { ch <- list(...); for (k in names(ch)) r[[k]] <- ch[[k]]; r$record_version <- (if (is.na(r$record_version)) 0L else r$record_version) + 1L; store$write("trades", r) }
    act_msg <- function(txt, ok = TRUE) output$act_out <- renderUI(tags$div(style = sprintf("margin-top:8px; font-weight:700; color:%s;", if (ok) "#166534" else "#b91c1c"), txt))
    observeEvent(input$pos_update, { id <- input$pos_pick; if (!nzchar(id %||% "")) return()
      res <- tryCatch(client$update_position(id, tr_num0(input$pos_stop, NA), tr_num0(input$pos_tgt, NA)), error = function(e) list(dealStatus = "ERROR", reason = conditionMessage(e)))
      ok <- identical(toupper(res$dealStatus %||% ""), "ACCEPTED"); r <- trade_of(id)
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = if (is.null(r)) NA else r$trade_id, event_type = "LEVELS_CHANGED", deal_id = id, deal_status = res$dealStatus %||% NA,
                                       stop_level = tr_num0(input$pos_stop, NA), target_level = tr_num0(input$pos_tgt, NA), request_json = cc_json(res$request %||% list()), note = input$pos_why))
      if (ok && !is.null(r)) new_version(r, stop_level = if (is.finite(tr_num0(input$pos_stop, NA))) input$pos_stop else r$stop_level, target_level = if (is.finite(tr_num0(input$pos_tgt, NA))) input$pos_tgt else r$target_level)
      read_live(); touch(); act_msg(if (ok) "Stop / target changed." else paste("Not accepted:", res$reason %||% res$dealStatus), ok) })
    observeEvent(input$pos_close, { id <- input$pos_pick; if (!nzchar(id %||% "")) return()
      showModal(modalDialog(title = "Close this position on the DEMO account?", footer = tagList(modalButton("No"), actionButton(session$ns("pos_close_ok"), "Yes, close it", class = "btn-warning")))) })
    observeEvent(input$pos_close_ok, { removeModal(); id <- input$pos_pick
      res <- tryCatch(client$close_position(id), error = function(e) list(dealStatus = "ERROR", reason = conditionMessage(e))); ok <- identical(toupper(res$dealStatus %||% ""), "ACCEPTED"); r <- trade_of(id)
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = if (is.null(r)) NA else r$trade_id, event_type = "CLOSE_REQUESTED", deal_id = id, deal_status = res$dealStatus %||% NA, level = cc_num(res$level), note = input$pos_why))
      if (ok && !is.null(r)) { xl <- cc_num(res$level); d <- if (toupper(r$direction) == "BUY") 1 else -1; pnl_i <- d * (xl - r$entry_level) * cc_value_per_point(r$size, r$lot_size)
        fx <- fx_info(r$instrument_currency, r$account_currency)$rate
        new_version(r, status = "CLOSED", exit_level = xl, exit_ts = now_fn(), pnl_instrument = pnl_i, fx_rate = fx, pnl_account_est = pnl_i * fx, exit_code = "ME") }
      read_live(); touch(); act_msg(if (ok) sprintf("Closed at %s (exit code ME: closed by hand). Sync later to add the amount Capital.com booked.", cc_fmt(cc_num(res$level), 4)) else paste("Not accepted:", res$reason %||% res$dealStatus), ok) })
    observeEvent(input$ord_cancel, { id <- input$ord_pick; if (!nzchar(id %||% "")) return()
      res <- tryCatch(client$cancel_working_order(id), error = function(e) list(dealStatus = "ERROR", reason = conditionMessage(e))); ok <- identical(toupper(res$dealStatus %||% ""), "ACCEPTED"); r <- trade_of(id)
      store$write("events", data.frame(event_id = cc_id("EV"), trade_id = if (is.null(r)) NA else r$trade_id, event_type = "ORDER_CANCELLED", deal_id = id, deal_status = res$dealStatus %||% NA, note = input$pos_why))
      if (ok && !is.null(r)) new_version(r, status = "CANCELLED")
      read_live(); touch(); act_msg(if (ok) "Order cancelled." else paste("Not accepted:", res$reason %||% res$dealStatus), ok) })

    # ---- journal -----------------------------------------------------------------------------------------------
    observe({ t <- trades(); if (!nrow(t)) { updateSelectInput(session, "j_trade", choices = c("(no trades yet)" = "")); return() }
      t <- t[order(t$placed_ts, t$entry_ts, decreasing = TRUE, na.last = TRUE), , drop = FALSE]
      cur <- isolate(input$j_trade)
      updateSelectInput(session, "j_trade", choices = setNames(t$trade_id, sprintf("%s | %s %s %s | %s | %s", t$trade_id, t$direction, t$size, t$market_name %||% t$epic, t$status,
                                                                                    format(t$entry_ts, "%d/%m %H:%M", tz = "Europe/London"))), selected = if (!is.null(cur) && cur %in% t$trade_id) cur else t$trade_id[1]) })
    jrow <- reactive({ t <- trades(); id <- input$j_trade %||% ""; if (!nzchar(id) || !nrow(t)) NULL else t[t$trade_id == id, , drop = FALSE][1, ] })
    observeEvent(input$j_trade, { r <- jrow(); if (is.null(r)) return()
      for (p in list(c("j_fund", "setup_fund"), c("j_tech", "setup_tech"), c("j_trigger", "trigger_text"), c("j_exec", "execution_text"), c("j_stopwhy", "stop_reason"), c("j_tgtwhy", "target_reason"),
                     c("j_why", "exit_reason"), c("j_lessons", "lessons"), c("j_analysis", "analysis"), c("j_devnote", "deviation_note")))
        updateTextAreaInput(session, p[1], value = if (is.na(r[[p[2]]])) "" else r[[p[2]]])
      updateSelectInput(session, "j_purpose", selected = r$purpose %||% "PRACTICE"); updateTextInput(session, "j_chart", value = if (is.na(r$chart_period)) "" else r$chart_period)
      updateNumericInput(session, "j_hours", value = r$expected_hours); updateSelectInput(session, "j_code", selected = if (is.na(r$exit_code)) "" else r$exit_code)
      updateRadioButtons(session, "j_followed", selected = if (is.na(r$plan_followed)) "Y" else r$plan_followed); updateSelectInput(session, "j_devtype", selected = if (is.na(r$deviation_type)) "" else r$deviation_type)
      if (!is.na(r$mood_exit)) updateSliderInput(session, "j_mood", value = r$mood_exit) })
    output$j_facts <- renderUI({ r <- jrow(); if (is.null(r)) return(NULL); cy <- r$account_currency %||% ""; ic <- r$instrument_currency %||% ""
      pnl <- if (is.finite(r$pnl_account_booked)) r$pnl_account_booked else r$pnl_account_est
      tags$div(style = "display:flex; flex-wrap:wrap;",
        cc_rec_tile("Trade", sprintf("%s %s", r$direction, r$size), sprintf("%s | %s order | %s", r$market_name %||% r$epic, r$order_type, r$status)),
        cc_rec_tile("Entry", cc_fmt(r$entry_level, 4), format(r$entry_ts, "%d/%m/%Y %H:%M UK", tz = "Europe/London")),
        cc_rec_tile("Stop / Target", sprintf("%s / %s", cc_fmt(r$stop_level, 4), cc_fmt(r$target_level, 4)), sprintf("initial stop %s", cc_fmt(r$stop_initial, 4))),
        cc_rec_tile("Exit", cc_fmt(r$exit_level, 4), if (is.na(r$exit_ts)) "open" else format(r$exit_ts, "%d/%m/%Y %H:%M UK", tz = "Europe/London")),
        cc_rec_tile("P/L", cc_money(pnl, cy), sprintf("%s in %s; %s", cc_money(r$pnl_instrument, ic), ic, if (is.finite(r$pnl_account_booked)) "as booked by Capital.com" else "estimated at the day's rate")),
        cc_rec_tile("Risk at entry", cc_money(r$risk_account, cy), sprintf("exit code %s", if (is.na(r$exit_code)) "-" else r$exit_code))) })
    # ---- closed trade: full data (times, slippage, result in points / currency / R, best and worst while open)
    j_bars <- reactive({ r <- jrow(); if (is.null(r) || !identical(r$status, "CLOSED") || !client$connected()) return(NULL)
      t0 <- r$entry_ts; t1 <- r$exit_ts; if (is.na(t0)) return(NULL); if (is.na(t1)) t1 <- t0 + 3600
      span <- as.numeric(difftime(t1, t0, units = "mins")); res <- if (span <= 600) "MINUTE" else if (span <= 3000) "MINUTE_5" else "MINUTE_15"
      tryCatch(cc_fetch_bars(client, r$epic, res, t0 - 2 * 3600, min(now_fn(), t1 + 3 * 3600)), error = function(e) { cat("[C.C] candles for the trade:", conditionMessage(e), "\n"); NULL }) })
    j_sum <- reactive({ r <- jrow(); if (is.null(r) || !identical(r$status, "CLOSED")) return(NULL); cc_trade_summary(r, j_bars(), tbl("activity")) })
    output$j_summary <- renderUI({ sm <- j_sum(); if (is.null(sm)) return(NULL)
      tags$div(style = "background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:8px 12px; margin:6px 0; font-size:13px;",
        tags$b("Trade data (from Capital.com)"), tags$ul(style = "margin:4px 0 0 0;", lapply(cc_summary_lines(sm), tags$li))) })
    # ---- the Individual Trade Sheet: built from what is on screen, on demand (download, Dropbox) ------------------
    j_scan <- reactive({ r <- jrow(); if (is.null(r)) return(NULL); sc <- tbl("scans")
      sc <- sc[sc$trade_id %in% r$trade_id | (!is.na(r$scan_id) & sc$scan_id %in% r$scan_id), , drop = FALSE]; if (nrow(sc)) sc[nrow(sc), , drop = FALSE] else NULL })
    j_scen <- reactive({ r <- jrow(); if (is.null(r)) NULL else cc_scenario_read(r$scenario_json) })
    j_pats <- reactive({ sc <- j_scan(); if (is.null(sc)) NULL else cc_scan_patterns(sc$current_json) })
    c_latest <- function(tid) { e <- tbl("events"); e <- e[e$trade_id %in% tid & e$event_type %in% "C_ANALYSIS", , drop = FALSE]
      if (!nrow(e)) return(NULL); e <- e[order(e$saved_at), , drop = FALSE]; e[nrow(e), , drop = FALSE] }
    j_status_line <- function(r) { dd <- suppressWarnings(as.numeric(j_scen()$d)); cc_fmt <- function(x, k) cc_fmt_px(x, if (is.finite(dd)) dd else 3); switch(r$status %||% "",
      ORDER_WORKING = sprintf("Status: the %s order at %s has not been filled yet (placed %s UK). Nothing was bought or sold, so no money has been made or lost.", tolower(r$order_type), cc_fmt(r$order_level, 4), format(r$placed_ts, "%d/%m/%Y %H:%M", tz = "Europe/London")),
      CANCELLED = sprintf("Status: the %s order at %s was cancelled before it was filled. No trade took place.", tolower(r$order_type), cc_fmt(r$order_level, 4)),
      EXPIRED = sprintf("Status: the %s order at %s expired without being filled. No trade took place.", tolower(r$order_type), cc_fmt(r$order_level, 4)),
      REJECTED = sprintf("Status: Capital.com did not accept the order. %s", r$notes %||% ""),
      OPEN = "Status: the trade is still open; the exit part of the sheet is not filled yet.", "") }
    build_sheet <- function(want_pdf = FALSE) { r <- jrow(); if (is.null(r)) stop("Choose a trade first.")
      r <- as.data.frame(utils::modifyList(as.list(r), j_form(r)), stringsAsFactors = FALSE)   # the sheet always uses what is on screen
      closed <- identical(r$status, "CLOSED"); sm <- if (closed) j_sum() else NULL
      dir <- file.path(tempdir(), paste0(r$trade_id, "_", format(Sys.time(), "%H%M%OS3"))); dir.create(dir, showWarnings = FALSE, recursive = TRUE); pics <- list(); f1 <- NA_character_
      sc <- j_scan()
      if (!is.null(sc)) { rs <- tryCatch(cc_scan_restore(sc$bars_json), error = function(e) NULL)
        if (!is.null(rs)) { s0 <- rs$scan; ix <- s0$show_from:s0$n; bb <- s0$ctx$b[ix, ]
          sh <- lapply(s0$current, function(o) { if (!is.null(o$lines)) { o$lines$x0 <- o$lines$x0 - s0$show_from + 1; o$lines$x1 <- o$lines$x1 - s0$show_from + 1
              o$lines <- o$lines[o$lines$x1 >= 1, , drop = FALSE]; o$lines$x0 <- pmax(1, o$lines$x0) }; o })
          f1 <- file.path(dir, "order_chart.png")
          cc_chart_png(bb, f1, sprintf("%s when the order was placed, %s candles, patterns drawn", r$market_name %||% r$epic, names(cc_candles)[cc_candles == sc$resolution] %||% ""),
                       entry = if (is.finite(r$entry_level)) r$entry_level else r$order_level, stop = r$stop_initial, target = r$target_level, patterns = sh,
                       caption = paste("Own work: Capital.com prices; patterns found by the app's rules:", paste(s0$current_df$label, collapse = ", ")))
          pics[[length(pics) + 1]] <- data.frame(slot = "entry", event_id = NA, caption = if (nzchar(r$chart_period %||% "")) r$chart_period else "Entry chart", path = f1, stringsAsFactors = FALSE) } }
      if (closed) { b <- j_bars(); if (!is.null(b) && nrow(b)) { f2 <- file.path(dir, "exit_chart.png")
        cc_chart_png(b, f2, sprintf("%s: the trade, from 2 hours before entry to 3 hours after exit", r$market_name %||% r$epic), entry = r$entry_level, stop = r$stop_initial,
                     target = r$target_level, exit = r$exit_level, t_open = sm$open_ts, t_close = sm$close_ts, caption = "Own work: Capital.com prices (mid). Shaded: the trade was open.")
        pics[[length(pics) + 1]] <- data.frame(slot = "exit", event_id = NA, caption = "Exit and post-exit", path = f2, stringsAsFactors = FALSE) } }
      ctx <- cc_context_items(j_scen(), j_pats(), input$j_c %||% "", isTRUE(input$j_c_incl), f1, if (closed) "" else j_status_line(r))
      day <- as.Date(format(if (closed) sm$open_ts %||% r$entry_ts else r$placed_ts, "%Y-%m-%d", tz = "Europe/London"))
      docx <- file.path(dir, tr_trade_filename(r$market_name %||% r$epic, if (is.na(day)) Sys.Date() else day))
      cc_trade_sheet(r, sm, input$s_name %||% "", if (length(pics)) do.call(rbind, pics) else list(), docx, context = ctx)
      pdf <- if (want_pdf) tryCatch(tr_docx_to_pdf(docx), error = function(e) NA_character_) else NA_character_
      cat("[C.C] trade sheet built:", basename(docx), if (want_pdf) (if (!is.na(pdf)) "+ PDF" else "(no PDF: LibreOffice not found)") else "", "\n")
      list(docx = docx, pdf = pdf, trade_id = r$trade_id) }
    j_fname <- function(ext) { r <- jrow(); if (is.null(r)) return(paste0("trade_sheet.", ext))
      day <- as.Date(format(if (!is.na(r$entry_ts)) r$entry_ts else r$placed_ts, "%Y-%m-%d", tz = "Europe/London"))
      sub("\\.docx$", paste0(".", ext), tr_trade_filename(r$market_name %||% r$epic, if (is.na(day)) Sys.Date() else day)) }
    has_pdf <- !is.na(tryCatch(tr_find_soffice(), error = function(e) NA_character_))
    output$j_dl_ui <- renderUI({ if (is.null(jrow())) return(tags$span(style = "color:#64748b;", "Choose a trade above to download its sheet."))
      tagList(downloadButton(session$ns("j_dl_docx"), "Download Word", icon = icon("file-word")),
              if (has_pdf) downloadButton(session$ns("j_dl_pdf"), "Download PDF", icon = icon("file-pdf"))
              else tags$span(style = "color:#b45309; font-size:12px; margin-left:6px;", "PDF: LibreOffice is not installed on this PC (download the Word file and use Save as PDF).")) })
    dl_fail <- function(e) { cat("[C.C] trade sheet download failed:", conditionMessage(e), "\n"); showNotification(paste("The sheet could not be built:", conditionMessage(e)), type = "error", duration = 10); stop(e) }
    output$j_dl_docx <- downloadHandler(filename = function() j_fname("docx"),
      content = function(f) tryCatch({ x <- withProgress(message = "Building the Individual Trade Sheet (Word)...", value = 0.5, build_sheet(FALSE)); file.copy(x$docx, f, overwrite = TRUE) }, error = dl_fail),
      contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    output$j_dl_pdf <- downloadHandler(filename = function() j_fname("pdf"),
      content = function(f) tryCatch({ x <- withProgress(message = "Building the Individual Trade Sheet (PDF)...", value = 0.5, build_sheet(TRUE))
        if (is.na(x$pdf)) stop("LibreOffice could not convert the Word file to PDF."); file.copy(x$pdf, f, overwrite = TRUE) }, error = dl_fail),
      contentType = "application/pdf")
    observeEvent(input$j_drop, { if (is.null(jrow())) return()
      out <- withProgress(message = "Writing the sheet to Dropbox...", value = 0.4, tryCatch({ x <- build_sheet(TRUE)
        x$saved <- tr_save_sheet(c(x$docx, x$pdf), "trade"); x }, error = function(e) { cat("[C.C] Dropbox save failed:", conditionMessage(e), "\n"); list(error = conditionMessage(e)) }))
      output$j_sheet_out <- renderUI({ if (!is.null(out$error)) return(tags$div(style = "color:#b91c1c; font-weight:700; margin-top:6px;", "Not saved to Dropbox: ", out$error))
        sv <- out$saved; ok <- !is.null(sv) && nrow(sv) && any(sv$ok)
        tags$div(style = "margin-top:6px; font-size:12.5px;", tags$div(style = sprintf("font-weight:700; color:%s;", if (ok) "#166534" else "#b91c1c"),
            sprintf("%s %s%s", if (ok) "Saved to Dropbox:" else "Not saved to Dropbox:", basename(out$docx), if (!is.na(out$pdf)) " and the PDF" else " (no PDF: LibreOffice is not installed)")),
          if (!is.null(sv) && nrow(sv)) tags$ul(lapply(seq_len(nrow(sv)), function(k) tags$li(sprintf("%s: %s %s", sv$file[k], if (isTRUE(sv$ok[k])) "saved to" else "not saved", paste(sv$where[k], sv$note[k]))))) else NULL) }) })
    # ---- C analysis ---------------------------------------------------------------------------------------------
    observeEvent(input$j_trade, { r <- jrow(); if (is.null(r)) return(); e <- c_latest(r$trade_id)
      updateTextAreaInput(session, "j_c", value = if (is.null(e) || is.na(e$note)) "" else e$note)
      inc <- if (!is.null(e)) isTRUE(tryCatch(jsonlite::fromJSON(e$response_json)$include, error = function(x) TRUE)) else isTRUE(cc_scenario_read(r$scenario_json)$include_c)
      updateCheckboxInput(session, "j_c_incl", value = inc) }, priority = -1)
    output$j_rec <- renderUI({ r <- jrow(); if (is.null(r)) return(NULL); sl <- cc_scenario_lines(j_scen()); p <- j_pats()
      tags$div(style = "background:#fff; border:1px solid #e9d5ff; border-radius:6px; padding:6px 10px; margin:6px 0; font-size:12.5px;",
        tags$b("Recommended trade saved with the order"),
        if (length(sl)) tags$ul(style = "margin:2px 0;", lapply(sl, tags$li)) else tags$div("No scenario was chosen in the app for this order (or it was placed before scenarios were saved in full)."),
        tags$div(sprintf("Chart at the order: %s. Patterns on it: %s.", if (is.null(j_scan())) "not saved" else "saved", if (is.null(p)) "none" else paste(p$Pattern, collapse = ", "))),
        { st <- j_status_line(r); if (nzchar(st)) tags$div(style = "color:#92400e;", st) }) })
    # the Morning Sheet of the day the order was placed (BigQuery), for the C analysis
    j_ms <- reactive({ r <- jrow(); if (is.null(r)) return(NULL)
      tryCatch({ t0 <- if (!is.na(r$placed_ts %||% NA)) r$placed_ts else r$entry_ts; day <- as.Date(format(t0, "%Y-%m-%d", tz = "Europe/London"))
        x <- tryCatch(morning_fn(day), error = function(e) list(ok = FALSE, why = paste("could not be read:", conditionMessage(e))))
        if (!is.list(x)) x <- list(ok = FALSE, why = "could not be read"); x$day <- day
        cat("[C.C] Morning Sheet of", format(day), "for the C analysis:", if (isTRUE(x$ok)) "loaded" else x$why, "\n"); x },
        error = function(e) list(ok = FALSE, why = paste("could not be read:", conditionMessage(e)), day = NA)) })
    # the tick box itself says whether the sheet of that day was loaded from BigQuery
    output$j_c_ms_ui <- renderUI({ x <- j_ms(); if (is.null(x)) return(NULL); dd <- if (inherits(x$day, "Date")) format(x$day, "%d/%m/%Y") else "the trade's day"
      if (isTRUE(x$ok)) tags$div(style = "background:#f0fdf4; border:1px solid #86efac; border-radius:6px; padding:2px 8px; margin:4px 0;",
        checkboxInput(session$ns("j_c_ms"), tags$span(style = "color:#166534; font-weight:700;", icon("check"),
          sprintf(" C uses the Morning Sheet of %s: LOADED from BigQuery%s", dd, if (!is.null(x$saved_at)) sprintf(" (saved %s UK)", format(x$saved_at, "%H:%M", tz = "Europe/London")) else "")),
          value = isolate(input$j_c_ms) %||% TRUE))
      else tags$div(style = "background:#fffbeb; border:1px solid #fcd34d; border-radius:6px; padding:6px 8px; margin:4px 0; font-size:12.5px; color:#92400e; font-weight:700;",
        icon("circle-xmark"), sprintf(" Morning Sheet of %s NOT loaded: %s. C writes without it (save that day's Morning Sheet in 2. Morning Sheet to include it).",
                                      dd, sub("\\.$", "", sub("^No Morning Sheet for [0-9/]+ in BigQuery", "there is none in BigQuery for that day", x$why %||% "not available")))) })
    c_msg <- reactiveVal(NULL)
    output$j_c_msg <- renderUI({ m <- c_msg(); if (is.null(m)) return(NULL); tags$div(style = sprintf("margin-top:6px; font-weight:700; color:%s;", if (m[[1]]) "#166534" else "#b91c1c"), m[[2]]) })
    observeEvent(input$j_c_write, { r <- jrow(); if (is.null(r)) return()
      r <- as.data.frame(utils::modifyList(as.list(r), j_form(r)), stringsAsFactors = FALSE)
      ms <- j_ms(); use_ms <- isTRUE(ms$ok) && !isFALSE(input$j_c_ms); p <- cc_c_prompt(r, if (identical(r$status, "CLOSED")) j_sum() else NULL, j_scen(), j_pats(), if (use_ms) ms$text else NULL)
      out <- withProgress(message = "C is writing the analysis...", value = 0.5, tryCatch({ x <- c_fn(p); trimws(if (is.list(x)) x$text else x) }, error = function(e) structure(conditionMessage(e), class = "err")))
      if (inherits(out, "err") || !nzchar(out %||% "")) { c_msg(list(FALSE, paste("C could not write it:", if (inherits(out, "err")) unclass(out) else "empty answer"))); return() }
      updateTextAreaInput(session, "j_c", value = out); c_msg(list(TRUE, paste0("Written", if (use_ms) " with the Morning Sheet" else " without the Morning Sheet", ". Read it, edit if you want, then 'Save my entries to BigQuery' to keep it.")))
      cat("[C.C] C analysis written for", r$trade_id, "\n") })
    j_form <- function(r) list(purpose = input$j_purpose, chart_period = input$j_chart, expected_hours = tr_num0(input$j_hours, NA), exit_code = if (nzchar(input$j_code %||% "")) input$j_code else r$exit_code,
                  setup_fund = input$j_fund, setup_tech = input$j_tech, trigger_text = input$j_trigger, execution_text = input$j_exec, stop_reason = input$j_stopwhy, target_reason = input$j_tgtwhy,
                  exit_reason = input$j_why, lessons = input$j_lessons, analysis = input$j_analysis, plan_followed = input$j_followed, deviation_type = input$j_devtype,
                  deviation_note = input$j_devnote, mood_exit = input$j_mood)
    # saves the form when anything differs from the saved trade; returns the version now saved (or NULL when nothing changed)
    j_store <- function(r) { f <- j_form(r); same <- vapply(names(f), function(k) { a <- f[[k]]; b <- r[[k]]
        a <- if (is.null(a) || (length(a) == 1 && is.na(a))) "" else as.character(a); b <- if (is.null(b) || (length(b) == 1 && is.na(b))) "" else as.character(b); identical(trimws(a), trimws(b)) }, TRUE)
      if (all(same)) return(NULL); do.call(new_version, c(list(r), f)); touch(); (if (is.na(r$record_version)) 0L else r$record_version) + 1L }
    observeEvent(input$j_save, { r <- jrow(); if (is.null(r)) return(); v <- j_store(r)
      e <- c_latest(r$trade_id); ctext <- trimws(input$j_c %||% ""); inc <- isTRUE(input$j_c_incl)
      old_t <- if (is.null(e) || is.na(e$note)) "" else trimws(e$note); old_i <- if (is.null(e)) NA else isTRUE(tryCatch(jsonlite::fromJSON(e$response_json)$include, error = function(x) TRUE))
      c_saved <- FALSE
      if (!identical(ctext, old_t) || (nzchar(ctext) && !identical(inc, old_i))) {
        store$write("events", data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "C_ANALYSIS", note = ctext, response_json = cc_json(list(include = inc)), stringsAsFactors = FALSE)); touch(); c_saved <- TRUE }
      output$j_msg <- renderUI(tags$div(style = "color:#16a34a; margin-top:6px; font-weight:700;", icon("check"),
        if (is.null(v) && !c_saved) " Nothing changed since the last save." else paste0(
          if (!is.null(v)) sprintf(" Saved to BigQuery (cc_trades), %s version %d; earlier versions kept.", r$trade_id, v) else "",
          if (c_saved) " C analysis saved (cc_events, C_ANALYSIS)." else "", " ", format(Sys.time(), "%H:%M:%S")))) })
    output$j_where_sheet <- renderUI({ tg <- tryCatch(tr_sheet_targets("trade"), error = function(e) list(local = "", api = "")); tok <- nzchar(tryCatch(tr_dropbox_token(), error = function(e) ""))
      cc_rec_note("Each button does one thing. The sheet is built from what is on screen when you press it (LAT fields, Capital.com's data, the charts, and at the bottom the context: chart and patterns at the order, the recommended trade, and the C analysis if ticked). ",
        "Orders that were never filled get a sheet that says so.",
        tags$ul(style = "margin:2px 0;",
          tags$li(tags$b("Save my entries to BigQuery: "), "your boxes above to cc_trades (new version, earlier kept) and the C analysis to cc_events. No file is written."),
          tags$li(tags$b("Save the sheet to Dropbox: "), "writes Word + PDF to ", if (nzchar(tg$local)) tags$code(tg$local) else "no folder on this PC (the LAT Dropbox folder was not found)",
                  if (tok) tagList(" and uploads to ", tags$code(tg$api)) else " (Dropbox upload off: no token set)", ". Nothing is saved to BigQuery."),
          tags$li(tags$b("Download Word / Download PDF: "), "builds the sheet and downloads it straight away; nothing is saved anywhere else."))) })
    output$j_tbl <- DT::renderDT({ t <- trades(); if (!nrow(t)) return(NULL)
      DT::datatable(t[order(t$placed_ts, decreasing = TRUE), c("trade_id", "status", "purpose", "market_name", "direction", "size", "order_type", "entry_level", "stop_initial", "target_level", "exit_level", "exit_code",
                                                              "pnl_instrument", "instrument_currency", "pnl_account_est", "pnl_account_booked", "account_currency", "record_version")], rownames = FALSE, options = list(scrollX = TRUE, pageLength = 15)) })
    output$j_dl <- downloadHandler(filename = function() sprintf("cc_trades_%s.csv", format(Sys.Date())), content = function(f) utils::write.csv(trades(), f, row.names = FALSE))

    # ---- statistics ----------------------------------------------------------------------------------------------
    stats <- reactive({ t <- trades(); if (!nrow(t)) return(NULL); scope <- input$st_scope %||% "ALL"; if (scope != "ALL") t <- t[t$purpose %in% scope, , drop = FALSE]
      ob <- tr_num0(input$s_balance, NA); if (!is.finite(ob) && !is.null(acct())) ob <- NA; cc_trade_stats(t, ob) })
    output$st_tiles <- renderUI({ s <- stats(); if (is.null(s)) return(cc_rec_note("No closed trades yet.")); cy <- s$trades$account_currency[1]
      tags$div(style = "display:flex; flex-wrap:wrap;", cc_rec_tile("Closed trades", s$n), cc_rec_tile("Win rate", sprintf("%.0f%%", 100 * s$wins / max(1, s$wins + s$losses)), sprintf("%d won, %d lost", s$wins, s$losses)),
        cc_rec_tile("Net P/L", cc_money(s$net, cy), "booked where known, else estimated"), cc_rec_tile("Average R", cc_fmt(s$avg_r, 2), "result / initial risk"),
        cc_rec_tile("Average win / loss", sprintf("%s / %s", cc_fmt(s$avg_win), cc_fmt(s$avg_loss)), cy)) })
    output$st_equity <- plotly::renderPlotly({ s <- stats(); if (is.null(s)) return(plotly::plotly_empty(type = "scatter", mode = "markers"))
      plotly::layout(plotly::plot_ly(x = seq_along(s$equity), y = s$equity, type = "scatter", mode = "lines+markers", line = list(color = "#0f766e")), title = list(text = "Equity by closed trade", font = list(size = 13)),
                     xaxis = list(title = "Trade", dtick = 1), yaxis = list(title = s$trades$account_currency[1] %||% "")) })
    grp <- function(by) { s <- stats(); if (is.null(s)) return(NULL); d <- s$trades; g <- d[[by]]; g[is.na(g) | !nzchar(g)] <- "(not set)"
      do.call(rbind, lapply(split(d, g), function(x) data.frame(Group = x[[by]][1] %||% "(not set)", Trades = nrow(x), Won = sum(x$pnl > 0, na.rm = TRUE), Net = round(sum(x$pnl, na.rm = TRUE), 2), `Avg R` = round(mean(x$real_r, na.rm = TRUE), 2), check.names = FALSE))) }
    output$st_dir <- renderTable(grp("direction")); output$st_code <- renderTable(grp("exit_code")); output$st_strat <- renderTable(grp("strategy"))
    output$st_pat <- DT::renderDT({ s <- scan(); if (is.null(s) || !nrow(s$stats)) return(DT::datatable(data.frame(Note = "Load a chart on tab 3 (Market & Patterns) to measure the patterns."), rownames = FALSE, options = list(dom = "t")))
      x <- merge(s$stats, cc_catalog[, c("key", "label", "step", "bias", "regime")], by = "key"); x <- x[order(-(x$targets + x$stops)), ]
      DT::datatable(data.frame(Step = x$step, Pattern = x$label, Bias = x$bias, Regime = x$regime, Found = x$n, `Target first` = x$targets, `Stop first` = x$stops, `Neither in time` = x$timeouts,
                               `Target first %` = round(x$win_pct), `Expectancy R` = round(x$exp_r, 2), check.names = FALSE), rownames = FALSE, options = list(pageLength = 20, scrollX = TRUE)) })

    # ---- currency & budget explanation ----------------------------------------------------------------------------
    output$fx_explain <- renderUI({ bump(); a <- acct(); f <- mkt(); cy <- a$currency %||% "your account currency"; ic <- f$currency %||% "the market's currency"
      fx <- if (!is.null(a) && !is.null(f)) fx_info(f$currency, a$currency) else list(rate = NA, how = "connect and choose a market")
      ex_size <- tr_num0(input$p_size, 1); vpp <- if (!is.null(f)) cc_value_per_point(ex_size, f$lot_size) else NA
      tags$div(style = "background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:12px 14px; font-size:13px; line-height:1.7;",
        tags$h4(style = "margin-top:0;", "How money is converted"),
        tags$ol(
          tags$li(sprintf("Your Capital.com account is kept in %s. The balance, the margin available and every amount booked to the account are in %s.", cy, cy)),
          tags$li(sprintf("Each market has its own quote currency: %s is priced in %s. A position's profit or loss is first made in %s: size x price change x lot size.", f$name %||% "the chosen market", ic, ic)),
          tags$li(sprintf("Capital.com converts that amount into %s when it books it (and shows open P/L converted on the platform). Its own conversion rate and any conversion charge apply: ", cy),
                  tags$b("the app does not know the exact charge"), ", so it shows the amount Capital.com actually booked (from the transactions history) next to its own estimate. The table below compares them."),
          tags$li(sprintf("The app's estimate uses Capital.com's own FX market, mid price, refreshed every 10 minutes: %s.", fx$how)),
          tags$li("Before a trade, the risk and reward are worked out in the market's currency and converted with that rate, so 'balance if stopped' and 'balance if target' are in your account currency. ",
                  "Spread is paid when you open (you buy at the offer and sell at the bid); funding for positions held overnight is charged separately by Capital.com and appears in the transactions.")),
        if (is.finite(vpp)) tags$div(style = "background:#ecfeff; border-radius:8px; padding:8px 10px;", tags$b("Worked example: "),
          sprintf("size %s of %s: a move of 1.00 in price = %s = %s at %s.", ex_size, f$name %||% f$epic, cc_money(vpp, ic, 3), cc_money(vpp * fx$rate, cy, 3), if (is.finite(fx$rate)) sprintf("1 %s = %.5f %s", ic, fx$rate, cy) else "an unknown rate"))) })
    output$fx_cmp <- DT::renderDT({ t <- trades(); t <- t[t$status %in% "CLOSED", , drop = FALSE]; if (!nrow(t)) return(DT::datatable(data.frame(Note = "No closed trades yet."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(data.frame(Trade = t$trade_id, Market = t$market_name, `P/L (market currency)` = cc_money(t$pnl_instrument, t$instrument_currency), `Rate used` = round(t$fx_rate, 5),
                               `Estimate (account)` = cc_money(t$pnl_account_est, t$account_currency), `Booked by Capital.com` = cc_money(t$pnl_account_booked, t$account_currency),
                               `Difference` = cc_money(t$pnl_account_booked - t$pnl_account_est, t$account_currency),
                               `Difference %` = ifelse(is.finite(t$pnl_account_booked) & abs(t$pnl_account_est) > 0, round(100 * (t$pnl_account_booked - t$pnl_account_est) / abs(t$pnl_account_est), 2), NA), check.names = FALSE),
                    rownames = FALSE, options = list(dom = "tp", scrollX = TRUE)) })
    output$fx_tx <- DT::renderDT({ x <- tbl("transactions"); if (!nrow(x)) return(DT::datatable(data.frame(Note = "Press Sync on tab 5 (Positions & Sync) to read the transactions."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(x[order(x$date_utc, decreasing = TRUE), c("date_utc", "instrument", "type", "amount", "currency", "reference", "note")], rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE)) })
    output$fx_bal <- plotly::renderPlotly({ x <- tbl("account"); if (!nrow(x)) return(plotly::plotly_empty(type = "scatter", mode = "markers")); x <- x[order(x$saved_at), ]
      plotly::layout(plotly::plot_ly(x = x$saved_at, y = x$balance, type = "scatter", mode = "lines+markers", name = "Balance"), yaxis = list(title = x$currency[1]), xaxis = list(title = "")) })

    # ---- schema ---------------------------------------------------------------------------------------------------
    ddl_text <- reactive({ pj <- if (is.null(api_manager)) "<project>" else api_manager$bq_project_id %||% "<project>"; ds <- if (is.null(api_manager)) "<dataset>" else api_manager$bq_dataset_id %||% "<dataset>"
      paste(c(cc_ddl(pj, ds), if (exists("pm_ddl")) c("-- Step-by-Step Practice: the simulated pattern examples (created by the app when first used)", pm_ddl(pj, ds), "-- and their 4-8 line descriptions", pm_desc_ddl(pj, ds))), collapse = ";\n\n") })
    output$ddl <- renderText(ddl_text())
    output$ddl_dl <- downloadHandler(filename = "cc_tables.sql", content = function(f) writeLines(ddl_text(), f))
    invisible(list(scan = scan, trades = trades))
  })
}
tr_num0 <- function(x, d = NA_real_) { v <- suppressWarnings(as.numeric(if (is.null(x) || !length(x)) NA else x[1])); if (is.finite(v)) v else d }
