# modules/unit3_workbench.R
#
# "Unit 3 - Workbench" (earlier name: Live Plan Signals) - a live, data-driven implementation of the Task 1
# decision process, plus everything needed to run and log the real Task 2/3 work:
#   1. Assignment Instructions   - what the three tasks actually require, at a glance
#   2. How to Use This Tool      - step-by-step usage guide + full glossary
#   3. Live Signals              - the regime/trigger engine, every box explained in place
#   4. Trade Log & Performance   - full trade lifecycle logging + real Task 2 metrics,
#                                   computed from the student's own logged trades, not
#                                   illustrative data
#   5. Strategy Evaluation       - a SWOT builder pre-populated with evidence pulled
#                                   straight from the trade log, for Task 3
#
# As before: no asset/asset-class/resolution selector of its own - those live globally
# in the sidebar and are already wired into the shared data_manager. Every signal and
# every metric on this tab is computed from whatever is currently selected there.
#
# Signal-and-log design, unchanged: this tab flags a trigger and lets the student log it;
# it never places a trade. Task 2 explicitly requires evaluating deviations from the
# plan and explaining them psychologically (Unit 2, Task 1) - a fully automated executor
# would remove the very decision point that evaluation depends on.

# ===========================================================================
# PURE LOGIC - no Shiny reactivity, kept separate and testable on their own.
# ===========================================================================

# ---- Signal engine (unchanged logic from the first version) ----

# The signal logic lives in R/utils_unit3_rules.R (written from the LAT course material). This tab only
# adapts it to the sidebar selection and the card layout.

u3wb_is_fx <- function(asset_class, asset) {
  grepl("forex|fx|currenc", tolower(paste(asset_class, asset))) || grepl("=X$|^[A-Z]{6}$|/", as.character(asset))
}

# Sensible default pip size per instrument (the user can change it on the tab).
u3wb_default_pip <- function(asset) {
  a <- toupper(gsub("[^A-Za-z0-9]", "", as.character(asset)))
  if (grepl("JPY", a)) 0.01 else if (grepl("CL|WTI|OIL|BRENT|BZ", a)) 0.01 else if (grepl("NG|NATGAS|NATURAL", a)) 0.001 else 0.0001
}

# Straddle card logic: overnight range 22:00-06:00 London -> resting orders; then watch for a trigger.
u3wb_straddle <- function(data, resolution, pip, spread, buffer) {
  none <- function(msg, ...) c(list(ready = FALSE, watch = FALSE, available = FALSE, reason = msg), list(...))
  if (identical(resolution, "1d") || is.null(resolution) || !inherits(data$Date, "POSIXct"))
    return(none("The morning straddle needs an intraday resolution (5m, 15m or 30m). Switch Data Resolution in the sidebar."))
  lt <- as.POSIXlt(data$Date, tz = "Europe/London"); last_t <- lt[length(lt)]
  morning <- as.Date(last_t); hr_now <- last_t$hour + last_t$min / 60
  if (hr_now >= 22) morning <- morning + 1                         # evening: the range for tomorrow is forming
  rng <- u3r_overnight_range(data, morning)
  if (is.null(rng)) return(none("No overnight bars (22:00-06:00 London) found for this morning yet."))
  st <- u3r_straddle(rng$high, rng$low, spread = spread, buffer = buffer, pip = pip)
  if (is.null(st)) return(none("The overnight range is not valid."))
  # is this range tight compared with the last 10 nights? (the manual: no tight range, no straddle)
  prev <- vapply(1:10, function(k) { r <- u3r_overnight_range(data, morning - k); if (is.null(r)) NA_real_ else (r$high - r$low) / pip }, 0)
  prev <- prev[is.finite(prev)]
  tight <- if (length(prev) >= 3) st$range_pips <= stats::median(prev) else NA
  base <- list(available = TRUE, st = st, tight = tight, morning = morning)
  lvl <- sprintf("Buy stop %.5g, sell stop %.5g, risk %.1f pips, target = risk (RRR %.1f).", st$buy_entry, st$sell_entry, st$risk_pips, st$rrr)
  tnote <- if (isTRUE(tight)) " Range is no wider than the median of the last nights: a tighter range suits the straddle." else if (identical(tight, FALSE)) " Range is wider than the median of the last nights: the manual prefers a tight range." else ""
  if (hr_now < 6 && as.Date(last_t) == morning)
    return(c(list(ready = FALSE, watch = TRUE, reason = paste0("Overnight range still forming (until 06:00 London). So far ", sprintf("%.1f", st$range_pips), " pips. ", lvl)), base))
  post <- data[as.POSIXlt(data$Date, tz = "Europe/London") > as.POSIXlt(as.POSIXct(paste(morning, "06:00:00"), tz = "Europe/London")), , drop = FALSE]
  post <- post[as.Date(as.POSIXlt(post$Date, tz = "Europe/London")) == morning, , drop = FALSE]
  buy_hit <- nrow(post) && any(post$High >= st$buy_entry); sell_hit <- nrow(post) && any(post$Low <= st$sell_entry)
  if (buy_hit && sell_hit) return(c(list(ready = TRUE, watch = FALSE, direction = "Both", reason = paste0("Both legs have been reached today (whipsaw). ", lvl, " Decide in advance what you do if both fill: the manual warns it can double the loss.")), base))
  if (buy_hit) return(c(list(ready = TRUE, watch = FALSE, direction = "Long", stop = st$buy_stop, target = st$buy_target, reason = paste0("Buy stop reached. ", lvl, " Cancel the sell order (OCO) if you trade only the first break.")), base))
  if (sell_hit) return(c(list(ready = TRUE, watch = FALSE, direction = "Short", stop = st$sell_stop, target = st$sell_target, reason = paste0("Sell stop reached. ", lvl, " Cancel the buy order (OCO) if you trade only the first break.")), base))
  c(list(ready = FALSE, watch = TRUE, reason = paste0("Orders resting, no break yet. Range ", sprintf("%.1f", st$range_pips), " pips. ", lvl, tnote)), base)
}

# ---- Performance metrics, computed from the student's OWN closed trades ----
# (the only illustrative/synthetic content left anywhere in this tab is none - every
# number here comes from rows the student has logged and marked Closed.)

u3wb_compute_metrics <- function(log_df, starting_equity = 10000) {
  if (is.null(log_df) || nrow(log_df) == 0) return(list(ok = FALSE, reason = "No trades logged yet."))

  closed <- log_df[!is.na(log_df$Status) & log_df$Status == "Closed" &
                      !is.na(suppressWarnings(as.numeric(log_df$`Real R`))), , drop = FALSE]
  closed$`Real R` <- suppressWarnings(as.numeric(closed$`Real R`))
  closed$`Risk £` <- suppressWarnings(as.numeric(closed$`Risk £`))
  closed <- closed[!is.na(closed$`Real R`) & !is.na(closed$`Risk £`), , drop = FALSE]

  if (nrow(closed) == 0) {
    return(list(ok = FALSE, reason = "No CLOSED trades with a numeric Real R and Risk £ yet - fill these in on the Trade Log tab once a trade is finished."))
  }

  wins <- closed[closed$`Real R` > 0, , drop = FALSE]
  losses <- closed[closed$`Real R` <= 0, , drop = FALSE]

  win_rate <- nrow(wins) / nrow(closed) * 100
  avg_win_r <- if (nrow(wins) > 0) mean(wins$`Real R`) else NA
  avg_loss_r <- if (nrow(losses) > 0) mean(abs(losses$`Real R`)) else NA
  avg_rr <- if (!is.na(avg_win_r) && !is.na(avg_loss_r) && avg_loss_r > 0) avg_win_r / avg_loss_r else NA

  pnl <- closed$`Real R` * closed$`Risk £`
  total_return <- sum(pnl, na.rm = TRUE)
  total_return_pct <- total_return / starting_equity * 100

  equity <- starting_equity + cumsum(pnl)
  peak <- cummax(c(starting_equity, equity))[-1]
  dd_pct <- (equity - peak) / peak * 100
  max_dd <- suppressWarnings(min(dd_pct, na.rm = TRUE))
  if (!is.finite(max_dd)) max_dd <- 0

  ret_pct <- pnl / starting_equity * 100
  sharpe <- if (length(ret_pct) > 1 && stats::sd(ret_pct) > 0) mean(ret_pct) / stats::sd(ret_pct) else NA
  downside <- ret_pct[ret_pct < 0]
  sortino <- if (length(downside) > 1 && stats::sd(downside) > 0) mean(ret_pct) / stats::sd(downside) else NA

  followed <- suppressWarnings(as.character(closed$`Plan Followed`))
  adherence <- if (any(!is.na(followed) & followed != "")) {
    mean(followed == "Yes", na.rm = TRUE) * 100
  } else NA

  ord <- order(closed$Timestamp)
  list(
    ok = TRUE, n = nrow(closed), n_wins = nrow(wins), n_losses = nrow(losses),
    win_rate = win_rate, avg_rr = avg_rr, total_return = total_return, total_return_pct = total_return_pct,
    max_dd = max_dd, sharpe = sharpe, sortino = sortino, adherence = adherence,
    equity_df = data.frame(trade_n = seq_along(equity)[ord], equity = equity[ord],
                            label = closed$Asset[ord], stringsAsFactors = FALSE)
  )
}

# ===========================================================================
# UI HELPERS
# ===========================================================================

u3wb_status_pill <- function(state) {
  spec <- switch(state,
    "ready" = list(bg = "#d5f5e3", fg = "#1e7a46", label = "READY"),
    "watch" = list(bg = "#fdebd0", fg = "#9c6b26", label = "WATCH"),
    list(bg = "#f2f3f4", fg = "#707b7c", label = "NO SIGNAL")
  )
  tags$span(spec$label, style = paste0(
    "display:inline-block; font-family:monospace; font-size:11px; font-weight:700; ",
    "padding:3px 10px; border-radius:10px; letter-spacing:.03em; background:", spec$bg, "; color:", spec$fg, ";"
  ))
}

u3wb_signal_card <- function(title, subtitle, state, reason_text, extra = NULL) {
  border_col <- switch(state, "ready" = "#1e7a46", "watch" = "#9c6b26", "#d5d8dc")
  tags$div(style = paste0("border:1px solid #dfe3e6; border-top:3px solid ", border_col,
                           "; border-radius:3px; padding:14px 16px; background:#fff; height:100%;"),
    tags$div(style = "display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:6px;",
      tags$div(tags$strong(title, style = "font-size:13.5px; color:#002C3C;"),
               tags$div(subtitle, style = "font-size:10.5px; color:#8a97a0; margin-top:2px;")),
      u3wb_status_pill(state)
    ),
    tags$p(reason_text, style = "font-size:12px; color:#4a5560; line-height:1.55; margin:8px 0 0 0;"),
    extra
  )
}

u3wb_signal_card_output <- function(ns, key) withSpinner(uiOutput(ns(paste0("card_", key))))

# Context/explanation strip - goes under a graph/metric box to answer "what is this and
# why does it matter for Unit 3" in place, rather than making the student go hunting.
u3wb_context <- function(...) {
  tags$div(style = paste0(
    "margin-top:10px; padding:10px 12px; background:#f4f8f7; border-left:3px solid #008A82; ",
    "border-radius:0 3px 3px 0; font-size:11.5px; color:#3d5a56; line-height:1.6;"
  ), ...)
}

# One metric tile for the Performance dashboard: big number + label + a one-line "why this
# matters for Task 2" note underneath, all in one visually scannable block.
u3wb_metric_tile <- function(label, value, sub, color = "#002C3C") {
  tags$div(style = "background:#fff; border:1px solid #e3e6e8; border-radius:3px; padding:14px 14px; height:100%;",
    tags$div(label, style = "font-size:10px; color:#8a97a0; text-transform:uppercase; letter-spacing:.04em; font-family:monospace;"),
    tags$div(value, style = paste0("font-family:monospace; font-size:22px; font-weight:700; color:", color, "; margin-top:6px;")),
    tags$div(sub, style = "font-size:10.5px; color:#8a97a0; margin-top:4px; line-height:1.4;")
  )
}

u3wb_glossary_df <- data.frame(
  Term = c("ADX (Average Directional Index)", "+DI / -DI", "Regime", "20-period EMA", "Pivot Point (PP)",
           "Pivot levels (S1-S3, R1-R3)", "Overnight range", "Candle 1", "R-multiple", "Risk %", "Win Rate", "Average R:R",
           "Sharpe Ratio (proxy)", "Sortino Ratio (proxy)", "Maximum Drawdown", "Plan Adherence Rate",
           "Process Failure", "Approved Exception"),
  Definition = c(
    "Wilder's (1978) measure of trend <em>strength</em> (0-100), regardless of direction. Your plan reads above 30 as a trend, below 20 as a range, and 20 to 30 as unclear (no trade). The course's Holy Grail needs the 14-period ADX above 30.",
    "Directional Indicators: +DI rising above -DI signals bullish pressure, and vice versa. Shown alongside ADX in the Regime box.",
    "This tool's read of current market character from ADX: <b>Trending</b> (above 30), <b>Range-bound</b> (below 20) or <b>Unclear (no trade)</b> (20 to 30). It decides which strategy is appropriate: Holy Grail in a trend, Pivot Point Bounce in a range.",
    "20-period <em>exponential</em> moving average of the close. The Holy Grail waits for a slow, corrective retracement to this line while the ADX turns down. (The course specifies an EMA, not a simple average.)",
    "(High + Low + Close) / 3 of the <em>prior</em> session. For FX the session closes at 5 pm New York, given in the course slides as 10 pm GMT. The main pivot the other levels are built around.",
    "The seven levels: PP, three supports and three resistances. S1 = PP - (H - PP), R1 = PP - (L - PP), S2/R2 = PP -/+ (R1 - S1), S3 = L - 2(H - PP), R3 = H + 2(PP - L). Price tends to pause or reverse at them.",
    "The high and low from 22:00 to 06:00 London time. For the morning straddle, add the spread to the high (charts are built from the bid); the buy stop sits 1 or 2 pips above it and the sell stop 1 or 2 pips below the low.",
    "In the Pivot Point Bounce, the candle after a pivot touch that fails to make a new high (sell) or new low (buy). A later break of Candle 1's low (sell) or high (buy) is the entry.",
    "A trade's outcome expressed as a multiple of the amount risked (1R = planned risk). A trade risking £100 that gains £200 is +2R.",
    "The fixed % of account equity risked per trade, set once as a plan rule (Task 1) rather than decided trade-by-trade (Kelly, 1956, applied fractionally).",
    "% of closed trades that were profitable. A plan can be profitable below 50% if Average R:R is high enough.",
    "Average winning R divided by average losing R (in magnitude). Read <em>together</em> with Win Rate, never alone.",
    "Mean return per trade / standard deviation of returns. Rewards consistency; penalises upside and downside volatility equally.",
    "Mean return per trade / standard deviation of <em>losing</em> trades only. The more appropriate ratio for a plan with asymmetric R-multiple targets (Sortino and van der Meer, 1991).",
    "The largest peak-to-trough decline in account equity over the period - compare directly against the drawdown limit in the Task 1 objective.",
    "% of closed trades where the pre-defined decision process and trigger rules were followed exactly, not overridden in the moment.",
    "A deviation caused by overriding a valid signal in the moment (e.g. widening a stop) - counts against the plan's own integrity.",
    "A deviation the plan explicitly allowed for in advance (e.g. standing aside for a scheduled release) - does not count against the plan."
  ), stringsAsFactors = FALSE
)

u3wb_keep <- function(guidance_only, panels) if (isTRUE(guidance_only)) panels[1:4] else panels

# ===========================================================================
# UI
# ===========================================================================

unit3_workbench_ui <- function(id, guidance_only = FALSE) {   # guidance_only: tabs 1-4 (the U3 app keeps records in BigQuery and has its own SWOT in the Report Builder)
  ns <- NS(id)

  tagList(
    fluidRow(
      do.call(tabBox, c(list(id = ns("subtabs"), width = 12, selected = if (guidance_only) "1. Assignment Instructions" else "5. Live Signals"), u3wb_keep(guidance_only, list(

        # ---------------------------------------------------------------
        tabPanel("1. Assignment Instructions", icon = icon("clipboard-list"),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "What Unit 3 actually requires",
              collapsible = TRUE, collapsed = FALSE,
            tags$p(paste0(
              "Unit 3 (40% of the diploma, 100 marks) asks for a structured 4-week trading plan, applied ",
              "for real, then evaluated honestly. This tab is built to support exactly that pipeline - the ",
              "Live Signals tab operationalises Task 1's decision process; the Trade Log tab captures Task 2's ",
              "evidence; the Strategy Evaluation tab structures Task 3."
            ), style = "font-size:13px; color:#4a5560; line-height:1.65;")
          ),
          fluidRow(
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Task 1 - 35 marks",
              collapsible = TRUE, collapsed = FALSE,
              tags$p(tags$b("Develop a structured 4-week trading plan."), style="font-size:12.5px; margin-bottom:6px;"),
              tags$ul(style = "font-size:12px; color:#4a5560; padding-left:18px; line-height:1.7;",
                tags$li("Asset justification"), tags$li("A single, measurable objective"),
                tags$li("Decision process (regime, strategy, confirmation)"),
                tags$li("Precise trigger events"), tags$li("Profit targets (MPO / fixed R)"),
                tags$li("Trade management rules, fixed before entry"))
            )),
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Task 2 - 45 marks",
              collapsible = TRUE, collapsed = FALSE,
              tags$p(tags$b("Evaluate performance over the period."), style="font-size:12.5px; margin-bottom:6px;"),
              tags$ul(style = "font-size:12px; color:#4a5560; padding-left:18px; line-height:1.7;",
                tags$li("How the chosen assets actually performed"),
                tags$li("Whether the plan's own rules were followed"),
                tags$li("Where they weren't, why - process failure vs. approved exception"),
                tags$li("Win rate, R:R, Sharpe/Sortino, max drawdown, plan adherence"))
            )),
            column(4, box(width = 12, status = "info", solidHeader = TRUE, title = "Task 3 - 20 marks",
              collapsible = TRUE, collapsed = FALSE,
              tags$p(tags$b("Evaluate the chosen strategy."), style="font-size:12.5px; margin-bottom:6px;"),
              tags$ul(style = "font-size:12px; color:#4a5560; padding-left:18px; line-height:1.7;",
                tags$li("Strengths - which rule(s) worked, and why"),
                tags$li("Weaknesses - a flawed rule vs. one that simply lost"),
                tags$li("Opportunities - concrete refinements"),
                tags$li("Threats - a regime change the plan isn't built for"))
            ))
          ),
          box(width = 12, status = "warning", solidHeader = FALSE,
            div(style = "display:flex; gap:14px; align-items:flex-start;",
              icon("circle-info", style = "font-size:20px; color:#e67e22; margin-top:2px;"),
              tags$p(paste0(
                "The full written model answer, worked example numbers, and Harvard references live on the ",
                "separate Unit 3 tab (under Unit Assignments in the sidebar). This tab is the ",
                "live tool that generates and logs your own real evidence for that write-up."
              ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
            )
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("2. Trading Plan Guide", icon = icon("clipboard-check"), u3wb_plan_guide_tab(ns)),
        tabPanel("3. Strategy Rules (LAT)", icon = icon("book-open"), u3wb_rules_tab(ns)),
        tabPanel("4. How to Use + Glossary", icon = icon("circle-question"),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Step-by-step usage guide",
              collapsible = TRUE, collapsed = FALSE,
            tags$ol(style = "font-size:12.5px; color:#4a5560; padding-left:20px; line-height:1.9;",
              tags$li(tags$b("Pick your instrument."), " Use the sidebar's Asset Class, Data Resolution and asset dropdowns - everything on this tab reads from that selection, live."),
              tags$li(tags$b("Read the regime."), " Open the Live Signals sub-tab and check the Step 1 box - ADX above 30 favours Holy Grail; below 20 favours Pivot Point Bounce."),
              tags$li(tags$b("Watch the three signal cards."), " Each shows READY, WATCH, or no signal, with the exact reason - mirroring your Task 1 trigger table."),
              tags$li(tags$b("Set your risk."), " Enter account equity and risk % in Step 3 - this is the £ figure that gets attached to anything you log."),
              tags$li(tags$b("Decide, then log."), " A READY card does not trade itself - you decide, then click the matching Log signal button on the Trade Log & Performance sub-tab."),
              tags$li(tags$b("Record the outcome."), " Once a logged trade is closed, double-click its row to fill in Status, Exit Price, Real R and Plan Followed - this is what turns a signal log into real Task 2 evidence."),
              tags$li(tags$b("Read the Performance dashboard."), " Metrics and the equity curve on the same sub-tab recalculate automatically from every row marked Closed."),
              tags$li(tags$b("Build your SWOT."), " The Strategy Evaluation sub-tab pulls your best/worst performing strategy straight from the log, so Task 3 is argued from evidence, not memory.")
            )
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Approaching Unit 3: what the tools do, and what is yours to do",
              collapsible = TRUE, collapsed = FALSE, u3ls_guidance_section()),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Glossary of terms used on this tab",
              collapsible = TRUE, collapsed = FALSE,
            ua_table(u3wb_glossary_df)
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("5. Live Signals", icon = icon("bolt"),
          box(width = 12, solidHeader = FALSE, status = "warning", collapsible = TRUE, collapsed = FALSE,
              title = "About this tab",
            div(style = "display:flex; align-items:flex-start; gap:14px;",
              icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
              tags$p(paste0(
                "Live version of the Task 1 decision process, computed from the asset, asset class and data ",
                "resolution currently selected in the sidebar - change any of those and every signal below ",
                "re-evaluates automatically. This tab flags a trigger; it never places a trade. Take the ",
                "decision yourself, then log it on the Trade Log tab."
              ), style = "font-size:13px; color:#5a3500; margin:0; line-height:1.6;")
            )
          ),
          fluidRow(
            box(title = "Step 1 - Regime Read", status = "primary", solidHeader = TRUE, width = 3,
              withSpinner(uiOutput(ns("regimeBox"))),
              u3wb_context(tags$b("What this is: "), "ADX(14) and its Wilder (1978) trend-strength reading. ",
                         tags$b("Why it matters: "), "it decides which Task 1 strategy is even appropriate right now - trading Holy Grail in a range, or Pivot Bounce in a trend, is exactly the mismatch Task 3's Threats should flag.")
            ),
            box(title = "Step 3 - Position Sizing", status = "primary", solidHeader = TRUE, width = 3,
              numericInput(ns("accountEquity"), "Account Equity (£)", value = 10000, min = 0, step = 100),
              sliderInput(ns("riskPct"), "Risk per trade (%)", min = 0.25, max = 3, value = 1, step = 0.25),
              uiOutput(ns("riskAmountBox")),
              u3wb_context(tags$b("What this is: "), "fixed-fractional position sizing. ",
                         tags$b("Why it matters: "), "Task 1 requires position sizing to be a fixed plan rule, not decided trade-by-trade (Kelly, 1956, applied conservatively) - this £ figure is what gets attached to every trade you log.")
            ),
            box(title = "Price vs. Signal Levels", status = "primary", solidHeader = TRUE, width = 6,
              withSpinner(plotlyOutput(ns("signalChart"), height = "300px")),
              u3wb_context(tags$b("What this shows: "), "Close price with the 20-period EMA, the seven pivot levels from the prior session (when they fall in the plotted range), and the morning straddle stops when available, plus ADX(14) below with the 30 (trend) and 20 (range) lines. ",
                         tags$b("Why it matters: "), "this is the visual confirmation Task 1's decision process asks for before treating a trigger as valid.")
            )
          ),
          fluidRow(style = "margin-bottom:18px;",
            column(4, u3wb_signal_card_output(ns, "hg")),
            column(4, u3wb_signal_card_output(ns, "pb")),
            column(4, u3wb_signal_card_output(ns, "or"))
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Straddle settings (morning straddle)", collapsible = TRUE, collapsed = TRUE,
            fluidRow(
              column(4, numericInput(ns("pipSize"), "Pip size (price units)", value = 0.0001, step = 0.0001)),
              column(4, numericInput(ns("spreadPips"), "Spread (pips)", value = 1, min = 0, step = 0.1)),
              column(4, numericInput(ns("bufferPips"), "Entry and stop buffer (pips)", value = 1, min = 0, step = 0.5))),
            u3wb_context("Pip size: 0.0001 for most FX pairs, 0.01 for JPY pairs and crude oil, 0.001 for natural gas on many platforms (check yours). ",
              "The manual adds the spread to the overnight high, uses a 1 or 2 pip buffer, and sets the target equal to the risk. Use the same buffer every time.")),
          u3wb_context(style = "margin:14px 0 0 0;",
            tags$b("Reading the three cards: "), "READY means every Task 1 trigger condition is satisfied right now. ",
            "WATCH means the regime is right but the precise trigger hasn't fired yet - worth monitoring, not yet actionable. ",
            "No badge means this strategy isn't suited to current conditions at all."
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("6. Trade Log & Performance", icon = icon("book"),
          box(width = 12, status = "warning", solidHeader = FALSE, title = "Keep your real records elsewhere",
            collapsible = TRUE, collapsed = FALSE,
            tags$p(style = "font-size:12.5px; color:#5a3500; margin:0; line-height:1.6;",
              "This log lives only in this browser session: it is lost if the app restarts or the page reloads. Download the CSV as you go. ",
              "For durable records (BigQuery) and the full Blotter-style statistics, use ", tags$b("Trade Journal \u2192 Trading Records"),
              ". Your Dropbox Morning Sheet, Individual Trade Sheet and Trade Blotter remain the primary records.")
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Session Log",
            div(style = "display:flex; gap:10px; flex-wrap:wrap; margin-bottom:12px;",
              actionButton(ns("logHG"), "Log Holy Grail signal", icon = icon("plus"), class = "btn-sm"),
              actionButton(ns("logPB"), "Log Pivot Bounce signal", icon = icon("plus"), class = "btn-sm"),
              actionButton(ns("logOR"), "Log Opening-Range signal", icon = icon("plus"), class = "btn-sm"),
              actionButton(ns("logManual"), "Log manual entry", icon = icon("pen"), class = "btn-sm btn-default"),
              downloadButton(ns("downloadLog"), "Download log (CSV)", class = "btn-sm btn-primary", style = "color:#ffffff; font-weight:700;"),
              actionButton(ns("clearLog"), "Clear log", icon = icon("trash"), class = "btn-sm btn-default")
            ),
            u3wb_context(
              tags$b("What this is: "), "your running Task 2 evidence base. Logging a signal creates a row with Status ",
              tags$code("Signal Only"), ". ", tags$b("What to do once you've actually traded it: "),
              "double-click the ", tags$b("Status"), " cell and change it to ", tags$code("Taken"), " or ", tags$code("Skipped"),
              "; once a taken trade is finished, set Status to ", tags$code("Closed"), " and fill in ",
              tags$b("Exit Price, Result, Real R"), " (as a decimal multiple, e.g. -1, 1.5, 2) and ",
              tags$b("Plan Followed"), " (", tags$code("Yes"), "/", tags$code("No"), "). ",
              tags$b("Why it matters: "), "the Performance dashboard below reads only rows marked ", tags$code("Closed"),
              " with a numeric Real R - this is what converts a list of signals into the Task 2 metrics your write-up needs."
            ),
            DT::dataTableOutput(ns("logTable"))
          ),

          box(width = 12, status = "primary", solidHeader = TRUE, title = "Performance Dashboard (from your logged, Closed trades)",
              collapsible = TRUE, collapsed = FALSE,
            uiOutput(ns("performanceArea"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("7. Strategy Evaluation (SWOT)", icon = icon("magnifying-glass-chart"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this tab",
            tags$p(paste0(
              "Task 3 asks for a structured evaluation, not a general narrative. The panel below pulls your ",
              "best- and worst-performing strategy straight from the Trade Log, so you can argue each SWOT ",
              "point from your own evidence rather than impression."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
          ),
          box(width = 12, status = "warning", solidHeader = FALSE, title = "Your own words",
            tags$p(style = "font-size:12.5px; color:#5a3500; margin:0; line-height:1.6;",
              "The app only shows numbers from your log and gives you empty boxes. It does not write, suggest or fill in any SWOT text. ",
              "The evaluation, and the reasons behind it, must be your own work. Check the London Academy of Trading's rules on tools and disclose honestly how you used this one.")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Evidence pulled from your Trade Log",
            uiOutput(ns("swotEvidence"))
          ),
          fluidRow(
            column(6,
              box(width = 12, status = "success", solidHeader = TRUE, title = "Strengths",
                textAreaInput(ns("swotS"), NULL, rows = 5, width = "100%",
                              placeholder = "Which rule produced the best risk-adjusted outcomes, and why?")),
              box(width = 12, status = "danger", solidHeader = TRUE, title = "Weaknesses",
                textAreaInput(ns("swotW"), NULL, rows = 5, width = "100%",
                              placeholder = "Which rule underperformed, or was most often the source of deviation? A flawed rule, or one that simply lost?"))
            ),
            column(6,
              box(width = 12, status = "warning", solidHeader = TRUE, title = "Opportunities",
                textAreaInput(ns("swotO"), NULL, rows = 5, width = "100%",
                              placeholder = "What refinement does the evidence above suggest - a tighter trigger, an added confirming indicator, a narrower asset universe?")),
              box(width = 12, status = "primary", solidHeader = TRUE, title = "Threats",
                textAreaInput(ns("swotT"), NULL, rows = 5, width = "100%",
                              placeholder = "What external regime change would undermine this plan going forward?"))
            )
          ),
          div(style = "margin-bottom:20px;",
            downloadButton(ns("downloadSwot"), "Download SWOT (text file)", class = "btn-primary", style = "color:#ffffff; font-weight:700;")
          )
        )
      ))))
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

unit3_workbench_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    tr_or_num <- function(x, d) { v <- suppressWarnings(as.numeric(x)); if (length(v) == 1 && is.finite(v)) v else d }

    # -- Live signal computation (Tab 3) --
    signals <- reactive({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% arrange(Date)
      req(nrow(data) >= 15)

      res <- data_manager$resolution %||% "1d"
      intraday <- inherits(data$Date, "POSIXct") && !identical(res, "1d")
      fx <- u3wb_is_fx(data_manager$current_asset_class, data_manager$current_asset)
      reg <- u3r_regime(data)
      prior <- u3r_prior_session(data, fx)
      lv <- if (is.null(prior)) NULL else u3r_pivots(prior$high, prior$low, prior$close)
      hg <- u3r_holy_grail(data)
      pb <- if (is.null(lv)) list(ready = FALSE, watch = FALSE, reason = "No prior session to build pivot levels from.")
            else if (!intraday) list(ready = FALSE, watch = FALSE, reason = "The bounce needs intraday bars (the course suggests 5-minute). Switch Data Resolution in the sidebar. Levels shown on the chart are from the prior day.")
            else {
              ids <- u3r_session_id(data$Date, fx); today <- data[ids == ids[length(ids)], , drop = FALSE]
              r <- u3r_pivot_bounce(if (nrow(today) >= 20) today else tail(data, 60), lv)
              if (isTRUE(reg$ok) && reg$regime != "Range-bound" && (isTRUE(r$ready) || isTRUE(r$watch))) {
                r$reason <- paste0("Plan rule: the bounce is used only when ADX is below 20 (now ", reg$adx, "). ", r$reason); r$ready <- FALSE; r$watch <- TRUE
              }
              r
            }
      pip <- tr_or_num(input$pipSize, u3wb_default_pip(data_manager$current_asset))
      list(data = data, regime = reg, hg = hg, pb = pb, levels = lv, fx = fx, intraday = intraday,
           or_sig = u3wb_straddle(data, res, pip, tr_or_num(input$spreadPips, 1), tr_or_num(input$bufferPips, 1)))
    })

    output$regimeBox <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL)
      if (is.null(s) || !s$regime$ok) {
        return(tags$p("Waiting for enough bars to compute ADX(14)...", style = "font-size:12px; color:#8a97a0;"))
      }
      reg <- s$regime
      col <- switch(reg$regime, "Trending" = "#1e7a46", "Range-bound" = "#2980b9", "#9c6b26")
      tagList(
        tags$div(style = paste0("font-family:monospace; font-size:28px; font-weight:700; color:", col, ";"), reg$adx),
        tags$div("ADX(14)", style = "font-size:10.5px; color:#8a97a0; margin-top:-4px;"),
        tags$div(reg$regime, style = paste0("margin-top:10px; font-weight:600; font-size:13px; color:", col, ";")),
        tags$div(paste0("+DI ", reg$di_pos, " / -DI ", reg$di_neg),
                 style = "font-size:11px; color:#8a97a0; margin-top:4px; font-family:monospace;"),
        tags$hr(style = "margin:10px 0;"),
        tags$div(data_manager$current_asset %||% "-", style = "font-size:12px; font-weight:600; color:#002C3C;"),
        tags$div(paste0(toupper(data_manager$current_asset_class %||% ""), " - ",
                         if ((data_manager$resolution %||% "1d") == "1d") "Daily" else data_manager$resolution),
                 style = "font-size:10.5px; color:#8a97a0;")
      )
    })

    output$riskAmountBox <- renderUI({
      req(input$accountEquity, input$riskPct)
      amt <- input$accountEquity * (input$riskPct / 100)
      tags$div(style = "margin-top:6px; padding:10px; background:#f4f6f7; border-radius:3px;",
        tags$div(paste0("£", format(round(amt, 2), big.mark = ",")),
                 style = "font-family:monospace; font-size:20px; font-weight:700; color:#002C3C;"),
        tags$div("at risk on the next signal logged", style = "font-size:10.5px; color:#8a97a0;")
      )
    })

    fmt <- function(x) if (is.null(x) || !is.finite(x)) "-" else format(signif(x, 6), nsmall = 0)
    levels_line <- function(...) { v <- list(...); tags$div(style = "font-size:11px; color:#3d5a56; margin-top:8px; font-family:monospace; line-height:1.6;",
      lapply(names(v), function(k) tags$div(paste0(k, ": ", fmt(v[[k]]))))) }
    output$card_hg <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      hg <- s$hg
      state <- if (isTRUE(hg$ready)) "ready" else if (isTRUE(hg$watch)) "watch" else "none"
      ex <- NULL
      if (!is.null(hg$checks)) ex <- tagList(
        tags$div(style = "margin-top:8px; font-size:11px; line-height:1.55; color:#3d5a56;",
          lapply(seq_len(nrow(hg$checks)), function(i) tags$div(
            tags$span(style = paste0("font-weight:700; color:", if (hg$checks$Met[i]) "#1e7a46" else "#9c6b26", ";"), if (hg$checks$Met[i]) "\u2713 " else "\u2022 "), hg$checks$Rule[i]))),
        if (isTRUE(hg$ready) || isTRUE(hg$watch)) levels_line(`Entry order (2-bar level)` = hg$entry, `Stop beyond retracement` = hg$stop_swing, `or beyond 20 EMA` = hg$stop_ema, `First target (previous extreme)` = hg$target))
      u3wb_signal_card("Holy Grail", "Trend, ADX > 30 and falling, pullback to 20 EMA, 2-bar entry", state, hg$reason, ex)
    })
    output$card_pb <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      pb <- s$pb
      state <- if (isTRUE(pb$ready)) "ready" else if (isTRUE(pb$watch)) "watch" else "none"
      ex <- if (!is.null(s$levels)) tagList(
        if (!is.null(pb$entry)) levels_line(`Entry (break of Candle 1)` = pb$entry, `Stop` = pb$stop, `Target (next pivot)` = pb$target),
        tags$div(style = "margin-top:8px; font-size:10.5px; color:#5b6b73; font-family:monospace;", paste(names(s$levels), vapply(s$levels, fmt, ""), collapse = "  ")))
      u3wb_signal_card("Pivot Point Bounce", "Touch a pivot, Candle 1 fails, Candle 1 breaks", state, pb$reason, ex)
    })
    output$card_or <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      or_sig <- s$or_sig
      state <- if (isTRUE(or_sig$ready)) "ready" else if (isTRUE(or_sig$watch)) "watch" else "none"
      ex <- if (!is.null(or_sig$st)) levels_line(`Buy stop` = or_sig$st$buy_entry, `Buy target` = or_sig$st$buy_target, `Sell stop` = or_sig$st$sell_entry, `Sell target` = or_sig$st$sell_target, `Risk (pips)` = or_sig$st$risk_pips)
      u3wb_signal_card("Morning / News Straddle", "Overnight range 22:00-06:00 London", state, or_sig$reason, ex)
    })

    output$signalChart <- renderPlotly({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      data <- tail(s$data, 120)
      ema <- as.numeric(TTR::EMA(s$data$Close, n = 20))[seq(nrow(s$data) - nrow(data) + 1, nrow(s$data))]
      adx_all <- tryCatch(as.data.frame(TTR::ADX(s$data[, c("High","Low","Close")], n = 14)), error = function(e) NULL)
      adx_df <- if (is.null(adx_all)) NULL else tail(adx_all, nrow(data))
      p1 <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines", name = "Close", line = list(color = "#002C3C", width = 1.6)) %>%
        add_trace(x = data$Date, y = ema, type = "scatter", mode = "lines", name = "EMA(20)", line = list(color = "#e67e22", width = 1.6, dash = "dot"))
      rngp <- range(c(data$Low, data$High), na.rm = TRUE); pad <- diff(rngp) * 0.4
      if (!is.null(s$levels)) for (nm in names(s$levels)) {
        v <- s$levels[[nm]]; if (is.finite(v) && v >= rngp[1] - pad && v <= rngp[2] + pad)
          p1 <- p1 %>% add_trace(x = range(data$Date), y = rep(v, 2), type = "scatter", mode = "lines", name = nm, line = list(color = if (nm == "PP") "#2980b9" else "#8e44ad", width = 1, dash = "dash"), hoverinfo = "name+y")
      }
      st <- s$or_sig$st
      if (!is.null(st)) p1 <- p1 %>% add_trace(x = range(data$Date), y = rep(st$buy_entry, 2), type = "scatter", mode = "lines", name = "Buy stop", line = list(color = "#1e7a46", width = 1, dash = "dashdot")) %>%
        add_trace(x = range(data$Date), y = rep(st$sell_entry, 2), type = "scatter", mode = "lines", name = "Sell stop", line = list(color = "#c0392b", width = 1, dash = "dashdot"))
      p1 <- p1 %>% layout(yaxis = list(title = "Price", range = list(rngp[1] - pad * 0.3, rngp[2] + pad * 0.3)), showlegend = TRUE, legend = list(orientation = "h", y = 1.18, font = list(size = 9)))
      if (!is.null(adx_df) && "ADX" %in% names(adx_df)) {
        p2 <- plot_ly(x = data$Date, y = as.numeric(adx_df$ADX), type = "scatter", mode = "lines", name = "ADX(14)", line = list(color = "#c0392b", width = 1.5)) %>%
          add_trace(x = range(data$Date), y = c(30, 30), mode = "lines", name = "Trend above 30", line = list(color = "#c0392b", width = 0.75, dash = "dot"), showlegend = FALSE) %>%
          add_trace(x = range(data$Date), y = c(20, 20), mode = "lines", name = "Range below 20", line = list(color = "#2980b9", width = 0.75, dash = "dot"), showlegend = FALSE) %>%
          layout(yaxis = list(title = "ADX", range = c(0, 60)))
        subplot(p1, p2, nrows = 2, heights = c(0.72, 0.28), shareX = TRUE, titleY = TRUE) %>% layout(plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 20))
      } else p1 %>% layout(plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 20))
    })

    # -- Session log (Tab 4) --
    empty_log <- function() data.frame(
      Timestamp = character(), Asset = character(), Class = character(), Resolution = character(),
      Strategy = character(), Direction = character(), Regime = character(), `Signal Price` = numeric(),
      `Suggested Stop` = numeric(), `Suggested Target` = numeric(), `Risk £` = numeric(),
      Status = character(), `Exit Price` = numeric(), `Exit Date` = character(), Result = character(),
      `Real R` = numeric(), `Plan Followed` = character(), `Deviation Type` = character(), Notes = character(),
      check.names = FALSE, stringsAsFactors = FALSE
    )
    session_log <- reactiveVal(empty_log())

    append_signal <- function(strategy, direction, notes, stop = NA_real_, target = NA_real_) {
      s <- tryCatch(signals(), error = function(e) NULL)
      if (is.null(s)) { showNotification("No data loaded yet.", type = "warning"); return() }
      one <- function(x, d = NA) { x <- suppressWarnings(x); if (is.null(x) || length(x) == 0) d else x[[1]] }
      onum <- function(x) { v <- suppressWarnings(as.numeric(one(x, NA_real_))); if (length(v) == 0) NA_real_ else v }
      ochr <- function(x, d = "") { v <- one(x, d); if (is.na(v)) d else as.character(v) }
      last_price <- onum(tail(s$data$Close, 1))
      strategy <- ochr(strategy); direction <- ochr(direction, "-"); notes <- ochr(notes)
      risk_amt <- (input$accountEquity %||% 0) * ((input$riskPct %||% 1) / 100)
      row <- data.frame(
        Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M"),
        Asset = ochr(data_manager$current_asset, "-"),
        Class = ochr(data_manager$current_asset_class, "-"),
        Resolution = ochr(data_manager$resolution, "1d"),
        Strategy = strategy, Direction = direction,
        Regime = paste0(ochr(s$regime$regime, "-"), " (ADX ", ochr(s$regime$adx, "-"), ")"),
        `Signal Price` = if (is.na(last_price)) NA_real_ else round(last_price, 4), `Suggested Stop` = onum(stop), `Suggested Target` = onum(target),
        `Risk £` = round(risk_amt, 2), Status = "Signal Only", `Exit Price` = NA, `Exit Date` = "",
        Result = "", `Real R` = NA, `Plan Followed` = "", `Deviation Type` = "", Notes = notes,
        check.names = FALSE, stringsAsFactors = FALSE
      )
      session_log(rbind(session_log(), row))
      showNotification(paste0(strategy, " signal logged - update Status once you act on it."), type = "message", duration = 3)
    }

    observeEvent(input$logHG, {
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      if (!isTRUE(s$hg$ready)) showNotification("Holy Grail is not READY right now - logged anyway as a watch note.", type = "warning")
      append_signal("Holy Grail", s$hg$direction, s$hg$reason, s$hg$stop_swing, s$hg$target)
    })
    observeEvent(input$logPB, {
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      if (!isTRUE(s$pb$ready)) showNotification("Pivot Bounce is not READY right now - logged anyway as a watch note.", type = "warning")
      append_signal("Pivot Point Bounce", s$pb$direction, s$pb$reason, s$pb$stop, s$pb$target)
    })
    observeEvent(input$logOR, {
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      if (!isTRUE(s$or_sig$ready)) showNotification("Opening-range break is not READY right now - logged anyway as a watch note.", type = "warning")
      append_signal("Morning/News Straddle", s$or_sig$direction, s$or_sig$reason, s$or_sig$stop, s$or_sig$target)
    })
    observeEvent(input$logManual, append_signal("Manual", NA, "Manually logged, not a rule-based trigger - note the reason in Notes."))

    observeEvent(input$clearLog, {
      session_log(empty_log())
      showNotification("Log cleared.", type = "message", duration = 2)
    })

    output$logTable <- DT::renderDataTable({
      DT::datatable(session_log(), rownames = FALSE, editable = TRUE,
                    options = list(dom = 'tp', pageLength = 8, ordering = FALSE, scrollX = TRUE))
    })
    log_proxy <- DT::dataTableProxy("logTable")
    observeEvent(input$logTable_cell_edit, {
      info <- input$logTable_cell_edit
      df <- session_log()
      df[info$row, info$col + 1] <- DT::coerceValue(info$value, df[info$row, info$col + 1])
      session_log(df)
      DT::replaceData(log_proxy, df, resetPaging = FALSE, rownames = FALSE)
    })

    output$downloadLog <- downloadHandler(
      filename = function() paste0("unit3_trade_log_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) write.csv(session_log(), file, row.names = FALSE)
    )

    # -- Performance dashboard (Tab 4) --
    metrics <- reactive({ u3wb_compute_metrics(session_log(), starting_equity = input$accountEquity %||% 10000) })

    output$performanceArea <- renderUI({
      m <- metrics()
      if (!isTRUE(m$ok)) {
        return(tags$p(m$reason %||% "No performance data yet - log a signal above, then mark it Closed once the trade is finished.",
                      style = "font-size:12.5px; color:#8a97a0; font-style:italic;"))
      }
      tagList(
        fluidRow(
          column(2, u3wb_metric_tile("Trades Closed", m$n, "logged & marked Closed")),
          column(2, u3wb_metric_tile("Win Rate", paste0(round(m$win_rate,1), "%"),
                                    paste0(m$n_wins, "W / ", m$n_losses, "L"),
                                    color = if (m$win_rate >= 50) "#1e7a46" else "#9c6b26")),
          column(2, u3wb_metric_tile("Avg R:R", if (is.na(m$avg_rr)) "-" else paste0(round(m$avg_rr,2), ":1"),
                                    "avg win R / avg loss R", color = "#002C3C")),
          column(2, u3wb_metric_tile("Total Return", paste0(if (m$total_return>=0) "+" else "", "£", round(m$total_return,2)),
                                    paste0(round(m$total_return_pct,2), "% of starting equity"),
                                    color = if (m$total_return>=0) "#1e7a46" else "#c0392b")),
          column(2, u3wb_metric_tile("Max Drawdown", paste0(round(m$max_dd,1), "%"), "peak-to-trough equity decline", color = "#c0392b")),
          column(2, u3wb_metric_tile("Plan Adherence", if (is.na(m$adherence)) "-" else paste0(round(m$adherence,1), "%"),
                                    "% of closed trades on-plan",
                                    color = if (!is.na(m$adherence) && m$adherence>=80) "#1e7a46" else "#9c6b26"))
        ),
        fluidRow(
          column(6, u3wb_metric_tile("Sharpe (proxy)", if (is.na(m$sharpe)) "-" else round(m$sharpe,2),
                                    "mean return / total volatility - penalises up and down moves equally")),
          column(6, u3wb_metric_tile("Sortino (proxy)", if (is.na(m$sortino)) "-" else round(m$sortino,2),
                                    "mean return / downside volatility only - the more appropriate figure for an asymmetric-target plan"))
        ),
        u3wb_context(style = "margin-top:14px;",
          tags$b("How to read this against Task 1: "), "compare Total Return and Max Drawdown directly against the objective ",
          "you set (e.g. positive return, drawdown under a fixed %), and Plan Adherence against your target adherence rate. ",
          "A Win Rate under 50% is not itself a problem if Avg R:R comfortably compensates for it."
        ),
        tags$div(style = "margin-top:16px;", withSpinner(plotlyOutput(session$ns("equityCurveChart"), height = "260px"))),
        u3wb_context(style = "margin-top:8px;",
          tags$b("What this is: "), "cumulative account equity across your Closed trades, in the order you logged them. ",
          tags$b("Why it matters: "), "this is the real equivalent of the illustrative equity curve on the Unit 3 Assignment tab - it's the chart Task 2 actually needs, built from your own trades rather than a worked example."
        )
      )
    })

    output$equityCurveChart <- renderPlotly({
      m <- metrics()
      req(isTRUE(m$ok))
      eq <- m$equity_df
      peak <- cummax(eq$equity)
      dd_idx <- which.min((eq$equity - peak) / peak)

      plot_ly(eq, x = ~trade_n, y = ~equity, type = "scatter", mode = "lines+markers",
              line = list(color = "#008A82", width = 2.5), fill = "tozeroy", fillcolor = "rgba(0,138,130,0.08)",
              marker = list(size = 5, color = "#008A82"), text = ~label, hoverinfo = "text+y",
              name = "Account Equity") %>%
        add_trace(x = eq$trade_n[dd_idx], y = eq$equity[dd_idx], type = "scatter", mode = "markers",
                  marker = list(size = 10, color = "#c0392b", symbol = "x"), name = "Max Drawdown point",
                  showlegend = FALSE) %>%
        layout(xaxis = list(title = "Closed trade #"), yaxis = list(title = "Account Equity (£)"),
               plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 20), showlegend = FALSE)
    })

    # -- Strategy Evaluation / SWOT (Tab 5) --
    output$swotEvidence <- renderUI({
      log <- session_log()
      closed <- log[!is.na(log$Status) & log$Status == "Closed" & !is.na(suppressWarnings(as.numeric(log$`Real R`))), , drop = FALSE]
      if (nrow(closed) == 0) {
        return(tags$p("No Closed trades logged yet - evidence will appear here once you have at least one.",
                      style = "font-size:12.5px; color:#8a97a0; font-style:italic;"))
      }
      closed$`Real R` <- suppressWarnings(as.numeric(closed$`Real R`))
      by_strategy <- closed %>%
        group_by(Strategy) %>%
        summarise(n = dplyr::n(), win_rate = mean(`Real R` > 0) * 100, total_r = sum(`Real R`), .groups = "drop") %>%
        arrange(desc(total_r))

      best <- by_strategy[1, ]
      worst <- by_strategy[nrow(by_strategy), ]
      n_deviations <- sum(!is.na(closed$`Plan Followed`) & closed$`Plan Followed` == "No")

      tagList(
        fluidRow(
          column(4, u3wb_metric_tile("Best strategy", best$Strategy, paste0(round(best$total_r,2), "R total - ", round(best$win_rate,0), "% win rate"), "#1e7a46")),
          column(4, u3wb_metric_tile("Weakest strategy", worst$Strategy, paste0(round(worst$total_r,2), "R total - ", round(worst$win_rate,0), "% win rate"), "#c0392b")),
          column(4, u3wb_metric_tile("Deviations logged", n_deviations, "closed trades marked Plan Followed = No", "#9c6b26"))
        ),
        tags$div(style = "margin-top:12px;", DT::datatable(by_strategy, rownames = FALSE,
                 options = list(dom = 't', paging = FALSE)) %>% DT::formatRound(c("win_rate","total_r"), 1))
      )
    })

    output$downloadSwot <- downloadHandler(
      filename = function() paste0("unit3_swot_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) {
        txt <- paste0(
          "UNIT 3 - TASK 3: STRATEGY EVALUATION (SWOT)\n",
          "Saved: ", format(Sys.time()), "\n\n",
          "STRENGTHS\n", input$swotS %||% "", "\n\n",
          "WEAKNESSES\n", input$swotW %||% "", "\n\n",
          "OPPORTUNITIES\n", input$swotO %||% "", "\n\n",
          "THREATS\n", input$swotT %||% "", "\n"
        )
        writeLines(txt, file)
      }
    )

    u3wb_guides_server(input, output, session)

    session$onSessionEnded(function() {})
  })
}

# ====================================================================================================
# (was modules/unit3_workbench_guides.R)
# modules/unit3_workbench_guides.R
# Reference/guidance content for the "Unit 3 - Workbench" tab, written from the London Academy of Trading
# course material (paraphrased and organised; read the originals for the full text):
#   Trade Plan Template; How to Develop a Structured Trading Plan; The Holy Grail Trade;
#   Short Term Trader's Pivot Point System; Reference Manual: Straddle Trade; The Rule of Five (Week 7).
# Nothing here is answer text for the assessed tasks: it explains the course rules, lists what each plan
# section asks for, and offers calculators. The plan itself, and every reason in it, is the student's own.

u3wb_gx <- function(...) tags$div(style = "font-size:12.5px; color:#2c3e50; line-height:1.7;", ...)
u3wb_gul <- function(...) tags$ul(style = "font-size:12.5px; color:#2c3e50; line-height:1.75; padding-left:20px; margin-bottom:6px;", ...)
u3wb_gbox <- function(title, ..., status = "primary", collapsed = FALSE) box(width = 12, status = status, solidHeader = TRUE, title = title, collapsible = TRUE, collapsed = collapsed, ...)
u3wb_gsrc <- function(...) tags$div(style = "font-size:11px; color:#64748b; margin-top:6px;", "Source: ", ...)

# ---------------------------------------------------------------- Tab: Trading Plan Guide
u3wb_plan_guide_tab <- function(ns) {
  tmpl <- data.frame(
    Section = c("Name", "Broad Objectives", "Risk Management", "Markets Traded", "Timeframes", "Data Sources", "Indicators Used",
                "Trade Setup", "Trigger", "Execution", "Target placement", "Stop loss placement", "Trade Management", "Pros and Cons"),
    `What the template asks you to write` = c(
      "Your name.",
      "What you aim to achieve by trading and by developing the strategy (the template's examples include sticking to a structured process and controlling emotions, and a monthly return range).",
      "Your risk limits: maximum risk per trade, daily, weekly and monthly, and a minimum reward-to-risk ratio.",
      "The assets you trade.",
      "Your average or target holding period for successful trades, and the chart timeframes you use.",
      "Where you source news and macro data.",
      "Each indicator, defined precisely (timeframe, period, what you look for). The template suggests rating each one out of 10 for importance.",
      "Your step-by-step process for finding a new trade, written separately for each strategy.",
      "The event that tells you to act.",
      "How you enter: time filters, price filters, what counts as an impulsive candle.",
      "Where you place targets and why; one target or several.",
      "Where you place the stop and why.",
      "What you do as the trade progresses: closing, trailing stops, manual exits, adding to winners, action before big news, overnight risk.",
      "What is easy or useful about the strategy so far, and what is hard to manage."),
    `Where this app helps` = c(
      "Trading Records &rarr; Connection &amp; Setup.",
      "Trading Records &rarr; Plan Spec (Objectives). Your own wording.",
      "Trading Records &rarr; Plan Spec (global): per trade, daily, weekly and monthly limits, combined cap, minimum RRR. Execution Plan has the position-size and combined-risk calculators.",
      "Morning Sheet instruments; Trading Records &rarr; Plan Spec.",
      "The Rule of Five table and selector on the Strategy Rules tab; Plan Spec timeframes.",
      "Plan Spec (Data sources); Economic Calendars group.",
      "Plan Spec (Indicators). The Strategy Rules tab states the exact settings the course uses for each strategy.",
      "Plan Spec per strategy (Set-up rule).",
      "Plan Spec per strategy (Trigger rule). The Live Signals tab flags when the course trigger conditions are met.",
      "Plan Spec per strategy (Execution rule). The straddle calculator shows entry buffers.",
      "Plan Spec per strategy (Target rule).",
      "Plan Spec per strategy (Stop rule).",
      "Plan Spec per strategy (Management rule); the Trades tab records every stop move and exit.",
      "Reviews tab (what worked, what did not). Your own judgement."),
    check.names = FALSE, stringsAsFactors = FALSE)
  tagList(
    u3wb_gbox("About this guide", status = "warning",
      u3wb_gx("The Trade Plan Template asks you to replace its worked examples with your own rules. This tab collects the course's guidance on building and keeping a plan, so that what you write in Trading Records and in your Task 1 plan is consistent with it. It does not write any part of your plan for you.")),
    u3wb_gbox("Trade Plan Template: section by section",
      ua_table(tmpl),
      u3wb_gsrc("Trade Plan Template (LAT). The template's example numbers (for instance 1% per trade, 2% daily, 5% weekly, 10% monthly, minimum reward-to-risk 1.0) are examples only: set limits that match your own plan.")),
    u3wb_gbox("S-T-E-M: the four parts of every trade",
      u3wb_gul(
        tags$li(tags$b("Set-up: "), "the conditions that must be in place before you look for an entry (regime, timeframe, indicator readings)."),
        tags$li(tags$b("Trigger: "), "the specific event that says act now (for example a Holy Grail 2-bar break, a pivot bounce break of Candle 1, a straddle order being hit)."),
        tags$li(tags$b("Execution: "), "how you enter once triggered: time filter, price filter, order type, and what counts as an impulsive candle."),
        tags$li(tags$b("Management: "), "what you do once in the trade: stop moves, trailing, partial exits, manual exits, action before news, overnight risk.")),
      u3wb_gsrc("How to Develop a Structured Trading Plan (LAT).")),
    u3wb_gbox("Plan building blocks from the course",
      u3wb_gul(
        tags$li(tags$b("Instruments and horizon: "), "decide what to trade and your time horizon, then develop a standard method for identifying trades."),
        tags$li(tags$b("Profit targets: "), "be realistic and honest. Unrealistic targets are never reached and only cause frustration."),
        tags$li(tags$b("Goals: "), "every business plan needs a goal; a trading career is a marathon. Enjoy bursts of profit but do not depend on them. Align goals with profit targets so you know where you should be after a month, a year or five years."),
        tags$li(tags$b("Risk limits: "), "before entering any trade know how many pips you will risk and how many dollars; keep the dollar risk consistent within a pre-set range. Only then calculate the size."),
        tags$li(tags$b("Position size (USD-based FX): "), "Trade size = $ risk x 10,000 / pip risk, and $ risk = trade size x pip risk / 10,000. Example from the slides: $800 risk with a 40-pip stop is a $200,000 trade; $100,000 with a 65-pip stop is $650 of risk. The calculator on the Strategy Rules tab does this."),
        tags$li(tags$b("Trade not going to plan: "), "never let a loser drift down to the stop. If you lose patience, either close manually at a small profit or loss, or move the stop aggressively toward the price."),
        tags$li(tags$b("Attitude: "), "after a winner ask whether you could have done better; after a loser take a lesson from it. Take something positive from every trade."),
        tags$li(tags$b("Review: "), "compare your execution with your strategy and goals. Are you following your rules? How are you tracking against weekly, monthly and yearly goals? The slides call this ten-minute review possibly the most useful ten minutes of your day.")),
      u3wb_gsrc("How to Develop a Structured Trading Plan (LAT).")),
    u3wb_gbox("When not to trade",
      u3wb_gx("Your state of mind affects performance. The course says to avoid trading when you are high (drink, medication, drugs), low (fed up, depressed), angry or tired. Your Morning Sheet has a stand-aside option for exactly this; record the reason in your own words."),
      u3wb_gsrc("How to Develop a Structured Trading Plan (LAT).")),
    u3wb_gbox("Straddle: points your tutor raised, and what the manual says",
      u3wb_gx("Define your straddle rules fully: the range you use, the distance of the resting orders, what happens if both sides fill, and how you allow for slippage and spread. The Reference Manual covers buffers (1 or 2 pips), the spread added to the overnight high, one-cancels-other orders, whipsaw, false breakouts and spread widening around news. See the Strategy Rules tab.")),
    u3wb_gbox("Correlated markets", collapsed = TRUE,
      u3wb_gx("Decide in advance how you treat setups that fire together in correlated markets (for example trade only the strongest, or split risk). Plan Spec has a field for this and the Execution Plan tab has a combined-risk calculator. The course material supplied does not prescribe a rule, so this is your own decision."))
  )
}

# ---------------------------------------------------------------- Tab: Strategy Rules (LAT)
u3wb_rules_tab <- function(ns) {
  tagList(
    u3wb_gbox("About this tab", status = "warning",
      u3wb_gx("The rules below are the course's, paraphrased. Live Signals applies them exactly as written, except where the course says a step is subjective (marked as your judgement). Compare with the original slides and the manual before you freeze your own plan.")),
    u3wb_gbox("Holy Grail (Linda Bradford Raschke, as taught by LAT)",
      u3wb_gx(tags$b("Idea: "), "a pullback from a recent momentum high will probably retest that high; the slides put the chance that a top is in place at around 10%. Trade only in the direction of the prevailing trend."),
      u3wb_gul(
        tags$li(tags$b("Sell rules: "), "(1) be in a downtrend; (2) 14-period ADX above 30; (3) a slow and corrective retracement to the 20-period ", tags$b("exponential"), " moving average, accompanied by a downturn in the ADX. The slides stress that you do not want an impulsive pullback; a rising wedge, triangle or flag is what you look for."),
        tags$li(tags$b("Entry (the subjective part): "), "sell into the retracement with half the position, or sell the break below the price pattern, or place a sell order below the 2-bar low once price reaches the 20 EMA."),
        tags$li(tags$b("Stop: "), "just above the retracement high (trailing just above the 2-bar high), or above the 20 EMA. If the 20 EMA fails to stop the rebound the set-up has failed: exit quickly."),
        tags$li(tags$b("Target: "), "the previous low, or run the trade with a trailing stop."),
        tags$li(tags$b("Buy rules (mirror): "), "ADX above 30, retracement to the 20 EMA with the ADX turning down, a buy order above the 2-bar high, a stop below the new 2-bar low (trailing at the 2-bar low) or just below the 20 EMA.")),
      u3wb_gx("You know early that you are wrong (the 20 EMA breaks, or price makes a new high in a downtrend), so cut quickly: the pattern is common and another will come."),
      u3wb_gsrc("The Holy Grail Trade (LAT slides).")),
    u3wb_gbox("Pivot points (floor-trader levels)",
      u3wb_gx("Seven levels from yesterday's high, low and close: the main pivot (PP), three supports and three resistances. For FX the close is taken at 5 pm New York, which the slides give as 10 pm GMT. They are predictive, not lagging, and many traders watch them, so markets often pause or reverse there, especially on the first approach in each direction."),
      ua_table(data.frame(Level = c("PP", "S1 / R1", "S2 / R2", "S3 / R3"),
        Formula = c("(H + L + C) / 3", "S1 = PP - (H - PP);  R1 = PP - (L - PP)", "S2 = PP - (R1 - S1);  R2 = PP + (R1 - S1)", "S3 = L - 2(H - PP);  R3 = H + 2(PP - L)"), stringsAsFactors = FALSE)),
      u3wb_gul(
        tags$li(tags$b("Bounce system (5-minute bars suggested, best when the market is active): "), "for a sell, price rises to touch a pivot; a later candle fails to make a new high (Candle 1); a later candle breaks the low of Candle 1. That generates the sell, with the next lower pivot as the target and the stop above the most recent high. A buy is the mirror image. If the bounce is insufficient and the entry level is not hit, do nothing."),
        tags$li(tags$b("Breakout system: "), "if price opens above PP and builds an early range, expect an upward break; the slides note this gives poor risk-to-reward but a high probability of short-term success. Targets are the next pivot levels."),
        tags$li(tags$b("Running trend days: "), "days when R3 or S3 is broken. Follow the move to the close at least, and consider holding overnight."),
        tags$li(tags$b("Confirmation: "), "the signal is the break or bounce off a pivot; moving averages, MACD, RSI or stochastics are used only to confirm.")),
      u3wb_gsrc("Short Term Trader's Pivot Point System (LAT slides). The slides' worked example (H 1.5438, L 1.5332, C 1.5413) gives PP 1.5394, R1 1.5457, R2 1.5500, R3 1.5563, S1 1.5351, S2 1.5288, S3 1.5245; this app reproduces it.")),
    u3wb_gbox("Straddle trade (Reference Manual)",
      u3wb_gx("A short-term breakout strategy: one buy stop order and one sell stop order either side of a tight range. It is not directional. It assumes that a break out of a recent range means one side has taken control, at least for a while. Duration runs from seconds to a few hours."),
      u3wb_gul(
        tags$li(tags$b("When to use: "), "early morning when the market wakes up (EUR/USD, GBP/USD and EUR/GBP historically best); around a significant news release; as price approaches the edges of a tight range."),
        tags$li(tags$b("Morning set-up: "), "(1) find the overnight high and low, 22:00 to 06:00 London time. Charts are built from the bid, so add the spread to the overnight high to get the highest ask. (2) Buy stop 1 or 2 pips above that high. (3) Its stop at the sell order's level, 1 or 2 pips below the overnight low. (4) Risk in pips = overnight range + buy buffer + stop buffer. (5) Target = risk, so the standard reward-to-risk is 1.0. (6) Mirror for the sell leg. Keep the buffer consistent."),
        tags$li(tags$b("Worked example from the manual: "), "high 1.18587 bid plus a 1-pip spread = 1.18597; low 1.18368; range 22.9 pips; risk 22.9 + 1 + 1 = 24.9 pips (the manual rounds this to 24). The calculator below reproduces it."),
        tags$li(tags$b("Management options: "), "take only the first trade and cancel the other (one-cancels-other, if your broker allows it; otherwise cancel by hand), or keep both live, which can recoup a first loss but can also double it."),
        tags$li(tags$b("Edge: "), "it relies on a hit rate above 50%, not a high reward-to-risk. You may tilt the ratio, for example a target of 1.5 times the stop, or a bigger target in the direction of a longer trend."),
        tags$li(tags$b("Drawbacks the manual lists: "), "whipsaw (mostly just after announcements; narrower targets are one option), false breakouts (time or price filters, applied the same way every time; waiting several minutes can miss the move), spread widening around news (a spread wider than the range can trigger entry and stop together; the only sure fix is not to straddle big news), and a low reward-to-risk."),
        tags$li(tags$b("When not to use: "), "no clear tight range; no obvious trigger level; volatility already high so orders fire before the event; or you already have a good idea of direction (use a simple buy or sell order). Check how your broker quotes prices around releases; some freeze or widen quotes.")),
      u3wb_gsrc("Reference Manual: Straddle Trade (LAT).")),
    u3wb_gbox("Rule of Five (choosing timeframes)",
      u3wb_gx("Markets move in different directions on different timeframes. Start from your average holding period for successful trades; that is your base timeframe (losing trades should be shorter). Then pick a major and a minor timeframe. The table is a guide, not a rule. Position yourself with the major trend and avoid counter-trend trades when all timeframes agree. Trigger entries and exits on the base timeframe, use the major timeframe for the bigger trend and the minor one for timing and confirmation."),
      selectInput(ns("r5_base"), tags$span(style = "color:#2c3e50; font-weight:600;", "Your base timeframe"), choices = u3r_rule_of_five$Base, selected = "2 hours", width = "260px"),
      uiOutput(ns("r5_out")),
      ua_table(u3r_rule_of_five),
      u3wb_gsrc("The Rule of Five, Week 7 (LAT).")),
    u3wb_gbox("Calculators",
      fluidRow(
        column(4, tags$h5(style = "color:#002C3C; font-weight:800;", "Pivot levels"),
          numericInput(ns("pv_h"), "Prior high", NA, step = 0.0001), numericInput(ns("pv_l"), "Prior low", NA, step = 0.0001), numericInput(ns("pv_c"), "Prior close", NA, step = 0.0001),
          uiOutput(ns("pv_out"))),
        column(4, tags$h5(style = "color:#002C3C; font-weight:800;", "Straddle levels"),
          numericInput(ns("sd_h"), "Range high (bid chart)", NA, step = 0.0001), numericInput(ns("sd_l"), "Range low (bid chart)", NA, step = 0.0001),
          fluidRow(column(4, numericInput(ns("sd_spread"), "Spread (pips)", 1, step = 0.1)), column(4, numericInput(ns("sd_buffer"), "Buffer (pips)", 1, step = 0.5)), column(4, numericInput(ns("sd_pip"), "Pip size", 0.0001, step = 0.0001))),
          numericInput(ns("sd_rrr"), "Reward : risk", 1, step = 0.25),
          actionButton(ns("sd_example"), "Load the manual's example", class = "btn-sm btn-default"),
          uiOutput(ns("sd_out"))),
        column(4, tags$h5(style = "color:#002C3C; font-weight:800;", "Trade size (USD-based FX, LAT method)"),
          numericInput(ns("ls_risk"), "$ you will risk", NA, step = 10), numericInput(ns("ls_pips"), "Stop distance (pips)", NA, step = 1),
          uiOutput(ns("ls_out")), tags$hr(),
          numericInput(ns("ls_size"), "Or: trade size ($ units)", NA, step = 1000), numericInput(ns("ls_pips2"), "Stop distance (pips)", NA, step = 1),
          uiOutput(ns("ls_out2")))),
      u3wb_gx(style = "color:#64748b; font-size:11.5px;", "Spread-bet platforms size in pounds per point: the same risk gives stake per pip = risk in pounds / stop pips. The Execution Plan tab has that version."))
  )
}

# ---------------------------------------------------------------- server pieces (call inside the module server)
u3wb_guides_server <- function(input, output, session) {
  cell <- function(txt, val) tags$div(style = "display:flex; justify-content:space-between; font-family:monospace; font-size:12px; padding:2px 0; border-bottom:1px solid #eef2f6; color:#2c3e50;", tags$span(txt), tags$span(val))
  output$pv_out <- renderUI({
    v <- c(input$pv_h, input$pv_l, input$pv_c); if (length(v) < 3 || any(!is.finite(v)) || input$pv_h < input$pv_l) return(tags$div(style = "color:#64748b; font-size:12px;", "Enter the prior session's high, low and close."))
    p <- u3r_pivots(input$pv_h, input$pv_l, input$pv_c); tags$div(style = "margin-top:6px;", lapply(names(p), function(n) cell(n, format(round(p[[n]], 5), nsmall = 4))))
  })
  observeEvent(input$sd_example, { updateNumericInput(session, "sd_h", value = 1.18587); updateNumericInput(session, "sd_l", value = 1.18368); updateNumericInput(session, "sd_spread", value = 1); updateNumericInput(session, "sd_buffer", value = 1); updateNumericInput(session, "sd_pip", value = 0.0001); updateNumericInput(session, "sd_rrr", value = 1) })
  output$sd_out <- renderUI({
    pip <- if (is.finite(input$sd_pip) && input$sd_pip > 0) input$sd_pip else NA
    st <- if (is.na(pip)) NULL else u3r_straddle(input$sd_h, input$sd_l, spread = input$sd_spread, buffer = input$sd_buffer, pip = pip, rrr = if (is.finite(input$sd_rrr)) input$sd_rrr else 1)
    if (is.null(st)) return(tags$div(style = "color:#64748b; font-size:12px; margin-top:8px;", "Enter the range high and low (the high must be above the low)."))
    f <- function(x) format(round(x, 5), nsmall = 4)
    tags$div(style = "margin-top:8px;", cell("Range incl. spread (pips)", sprintf("%.1f", st$range_pips)), cell("Risk (pips)", sprintf("%.1f", st$risk_pips)),
      cell("Buy stop", f(st$buy_entry)), cell("  stop loss", f(st$buy_stop)), cell("  target", f(st$buy_target)),
      cell("Sell stop", f(st$sell_entry)), cell("  stop loss", f(st$sell_stop)), cell("  target", f(st$sell_target)),
      tags$div(style = "font-size:11px; color:#64748b; margin-top:6px;", "Each leg's stop is the other leg's entry. Check the spread your platform quotes; around news it can exceed the whole range."))
  })
  output$ls_out <- renderUI({
    if (!is.finite(input$ls_risk) || !is.finite(input$ls_pips) || input$ls_pips <= 0) return(NULL)
    tags$div(style = "margin-top:6px; font-family:monospace; font-size:13px; color:#002C3C; font-weight:700;", sprintf("Trade size = $%s", formatC(u3r_trade_size_usd(input$ls_risk, input$ls_pips), format = "f", digits = 0, big.mark = ",")))
  })
  output$ls_out2 <- renderUI({
    if (!is.finite(input$ls_size) || !is.finite(input$ls_pips2)) return(NULL)
    tags$div(style = "margin-top:6px; font-family:monospace; font-size:13px; color:#002C3C; font-weight:700;", sprintf("$ risk = $%s", formatC(u3r_risk_usd(input$ls_size, input$ls_pips2), format = "f", digits = 2, big.mark = ",")))
  })
  output$r5_out <- renderUI({
    r <- u3r_rule_of_five[u3r_rule_of_five$Base == input$r5_base, ]; req(nrow(r) == 1)
    tags$div(style = "margin:6px 0 10px 0; padding:8px 12px; background:#f4f8f7; border-left:3px solid #008A82; font-size:12.5px; color:#2c3e50;",
      sprintf("Minor (timing and confirmation): %s. Base (trigger entries and exits): %s. Major (the bigger trend): %s.", r$Minor, r$Base, r$Major))
  })
}
