# modules/unit3_live_signals.R
#
# "Unit 3 - Live Plan Signals" - a live, data-driven implementation of the Task 1
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

u3_regime <- function(data, n = 14) {
  req_cols <- c("High", "Low", "Close")
  if (!all(req_cols %in% names(data)) || nrow(data) < (n * 2)) {
    return(list(ok = FALSE, adx = NA, regime = "Insufficient data", di_pos = NA, di_neg = NA))
  }
  adx_df <- tryCatch(as.data.frame(TTR::ADX(data[, req_cols], n = n)), error = function(e) NULL)
  if (is.null(adx_df) || !"ADX" %in% names(adx_df)) {
    return(list(ok = FALSE, adx = NA, regime = "ADX unavailable", di_pos = NA, di_neg = NA))
  }
  last <- tail(adx_df, 1)
  adx_val <- as.numeric(last$ADX)
  if (is.na(adx_val)) return(list(ok = FALSE, adx = NA, regime = "Warming up", di_pos = NA, di_neg = NA))

  regime <- if (adx_val > 30) "Trending" else if (adx_val < 20) "Range-bound" else "Transitional"
  list(ok = TRUE, adx = round(adx_val, 1), regime = regime,
       di_pos = round(as.numeric(last$DIp), 1), di_neg = round(as.numeric(last$DIn), 1))
}

u3_holy_grail <- function(data, ma_n = 20, adx_n = 14, pullback_pct = 0.35) {
  if (nrow(data) < max(ma_n, adx_n) + 6) {
    return(list(ready = FALSE, watch = FALSE, reason = "Not enough bars for a reliable 20-period MA / ADX read yet."))
  }
  reg <- u3_regime(data, adx_n)
  ma <- SMA(data$Close, n = ma_n)
  last_close <- tail(data$Close, 1)
  last_ma <- as.numeric(tail(ma, 1))
  slope <- as.numeric(tail(ma, 1)) - as.numeric(ma[length(ma) - 5])

  if (!reg$ok || is.na(last_ma) || is.na(slope)) {
    return(list(ready = FALSE, watch = FALSE, reason = "MA/ADX still warming up on this resolution."))
  }
  if (reg$regime != "Trending") {
    return(list(ready = FALSE, watch = FALSE, reason = paste0(
      "ADX(", adx_n, ") is ", reg$adx, " - not above 30, so this instrument is not in a Wilder-confirmed trend right now.")))
  }

  direction <- if (slope > 0) "Long" else "Short"
  dist_pct <- abs(last_close - last_ma) / last_ma * 100
  in_pullback_zone <- dist_pct <= pullback_pct

  if (in_pullback_zone) {
    list(ready = TRUE, watch = FALSE, direction = direction,
         reason = paste0("ADX ", reg$adx, " confirms a strong trend; price is ", round(dist_pct, 2),
                          "% from the ", ma_n, "-period MA, inside the pullback zone. ",
                          "Entry trigger: resumption of the ", tolower(direction), " move away from the MA."))
  } else {
    list(ready = FALSE, watch = TRUE, direction = direction,
         reason = paste0("ADX ", reg$adx, " confirms a ", tolower(direction), " trend, but price is ",
                          round(dist_pct, 2), "% away from the ", ma_n, "-period MA - wait for a pullback closer to the line."))
  }
}

u3_pivot_bounce <- function(data, adx_n = 14, tolerance_pct = 0.25) {
  if (nrow(data) < adx_n + 3) {
    return(list(ready = FALSE, watch = FALSE, reason = "Not enough bars yet."))
  }
  reg <- u3_regime(data, adx_n)
  prior <- data[nrow(data) - 1, ]
  last <- tail(data, 1)
  PP <- (prior$High + prior$Low + prior$Close) / 3
  R1 <- (2 * PP) - prior$Low
  S1 <- (2 * PP) - prior$High

  if (!reg$ok) return(list(ready = FALSE, watch = FALSE, reason = "ADX still warming up on this resolution."))
  if (reg$regime == "Trending") {
    return(list(ready = FALSE, watch = FALSE, reason = paste0(
      "ADX ", reg$adx, " - instrument is trending, not range-bound, so a pivot bounce is a lower-quality signal here (see Holy Grail instead).")))
  }

  near_s1 <- abs(last$Low - S1) / S1 * 100 <= tolerance_pct
  near_r1 <- abs(last$High - R1) / R1 * 100 <= tolerance_pct
  reversal_from_s1 <- near_s1 && last$Close > S1 && last$Close > (last$Low + (last$High - last$Low) * 0.5)
  reversal_from_r1 <- near_r1 && last$Close < R1 && last$Close < (last$Low + (last$High - last$Low) * 0.5)

  if (reversal_from_s1) {
    list(ready = TRUE, watch = FALSE, direction = "Long", level = "S1", pivot = PP, level_price = S1,
         reason = paste0("Price traded through S1 (", round(S1, 4), ") and the latest bar closed back above it, ",
                          "a reversal candle at support. Target: PP (", round(PP, 4), ")."))
  } else if (reversal_from_r1) {
    list(ready = TRUE, watch = FALSE, direction = "Short", level = "R1", pivot = PP, level_price = R1,
         reason = paste0("Price traded through R1 (", round(R1, 4), ") and the latest bar closed back below it, ",
                          "a reversal candle at resistance. Target: PP (", round(PP, 4), ")."))
  } else if (near_s1 || near_r1) {
    list(ready = FALSE, watch = TRUE, reason = paste0(
      "Price is close to ", if (near_s1) "S1" else "R1", " but the latest bar has not yet closed back through it - no reversal candle confirmed."))
  } else {
    list(ready = FALSE, watch = FALSE, reason = paste0(
      "Range-bound (ADX ", reg$adx, "), but price is not currently near S1 (", round(S1, 4), ") or R1 (", round(R1, 4), ")."))
  }
}

u3_opening_range <- function(data, resolution, opening_minutes = 30) {
  if (identical(resolution, "1d") || is.null(resolution)) {
    return(list(ready = FALSE, watch = FALSE, available = FALSE,
                reason = "Straddle timing needs an intraday resolution - switch Data Resolution in the sidebar to 1m/5m/15m/30m/60m."))
  }
  if (!"Date" %in% names(data) || !inherits(data$Date, c("POSIXct", "POSIXt"))) {
    return(list(ready = FALSE, watch = FALSE, available = FALSE, reason = "No intraday timestamps available."))
  }
  bar_mins <- suppressWarnings(as.numeric(gsub("[^0-9]", "", resolution)))
  if (is.na(bar_mins) || bar_mins <= 0) bar_mins <- 1
  n_bars <- max(1, round(opening_minutes / bar_mins))

  last_day <- as.Date(tail(data$Date, 1))
  today_data <- data[as.Date(data$Date) == last_day, ]
  if (nrow(today_data) < n_bars + 1) {
    return(list(ready = FALSE, watch = TRUE, available = TRUE,
                reason = paste0("Session in progress - need ", n_bars, " bars to fix the opening range, have ", nrow(today_data), ".")))
  }

  opening <- head(today_data, n_bars)
  rest <- today_data[(n_bars + 1):nrow(today_data), ]
  or_high <- max(opening$High); or_low <- min(opening$Low)
  last <- tail(rest, 1)

  if (nrow(rest) == 0) {
    return(list(ready = FALSE, watch = TRUE, available = TRUE, or_high = or_high, or_low = or_low,
                reason = paste0("Opening range fixed: ", round(or_low, 4), " - ", round(or_high, 4), ". Waiting for a break.")))
  }

  if (last$Close > or_high) {
    list(ready = TRUE, watch = FALSE, available = TRUE, direction = "Long", or_high = or_high, or_low = or_low,
         reason = paste0("Price closed above the opening range high (", round(or_high, 4), ") - confirmed upside break. ",
                          "MPO target: range height (", round(or_high - or_low, 4), ") projected from the break."))
  } else if (last$Close < or_low) {
    list(ready = TRUE, watch = FALSE, available = TRUE, direction = "Short", or_high = or_high, or_low = or_low,
         reason = paste0("Price closed below the opening range low (", round(or_low, 4), ") - confirmed downside break. ",
                          "MPO target: range height (", round(or_high - or_low, 4), ") projected from the break."))
  } else {
    list(ready = FALSE, watch = TRUE, available = TRUE, or_high = or_high, or_low = or_low,
         reason = paste0("Inside the opening range (", round(or_low, 4), " - ", round(or_high, 4), "). No break yet - resting orders either side, per the plan."))
  }
}

# ---- Performance metrics, computed from the student's OWN closed trades ----
# (the only illustrative/synthetic content left anywhere in this tab is none - every
# number here comes from rows the student has logged and marked Closed.)

u3_compute_metrics <- function(log_df, starting_equity = 10000) {
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


# ---- Document generation: populate the real uploaded Word templates ----
# Requires the `officer` package (install.packages("officer")) and the two official
# templates copied into a "templates" folder next to app.R:
#   templates/Morning_Sheet_Template.docx
#   templates/Trade_Sheet_-_Template.docx
# Tested against the real templates: cursor_reach() finds a unique anchor string in
# the template, body_remove() deletes that whole table/paragraph, body_add_table()/
# body_add_par() inserts the populated replacement in the same spot - every other
# paragraph, table, and instruction in the original template is left untouched.
# NOTE: cursor_reach()'s keyword is a regex - anchors here are chosen to avoid
# regex metacharacters (e.g. "Set-up" rather than "Set-up (fundamental)", since
# unescaped parentheses are a regex group, not literal characters).

u3_docx_replace_table <- function(doc, keyword, value_df, header = FALSE) {
  doc <- officer::cursor_reach(doc, keyword = keyword)
  doc <- officer::body_remove(doc)
  officer::body_add_table(doc, value = value_df, style = "Table Grid", pos = "after", header = header)
}

u3_docx_insert_par_after <- function(doc, keyword, text) {
  doc <- officer::cursor_reach(doc, keyword = keyword)
  officer::body_add_par(doc, text, pos = "after", style = "Normal")
}

u3_keyword_safe <- function(x, fallback = "NA") {
  x <- gsub("[^A-Za-z0-9]+", "", as.character(x %||% ""))
  if (is.na(x) || nchar(x) == 0) fallback else x
}

# f: list with name, date, dow_price, dow_change, nikkei_price, nikkei_change,
#    fx_df (4 rows EUR-USD/USD-JPY/GBP-USD/AUD-USD, cols Low/High/Current/Time),
#    comm_df (2 rows WTI Crude/Gold, cols Low/High/Current/Time),
#    overnight_news, today_releases
u3_build_morning_sheet_docx <- function(template_path, out_path, f) {
  doc <- officer::read_docx(template_path)

  doc <- u3_docx_replace_table(doc, "Name:", data.frame(
    a = c("Name:", "", "Date:"), b = c(f$name, "", f$date), stringsAsFactors = FALSE))

  doc <- u3_docx_replace_table(doc, "Dow Jones", data.frame(
    a = c("Overnight", "Dow Jones", "Nikkei"),
    b = c("Price", f$dow_price, f$nikkei_price),
    c = c("Change", f$dow_change, f$nikkei_change), stringsAsFactors = FALSE))

  fx <- f$fx_df
  doc <- u3_docx_replace_table(doc, "EUR-USD", data.frame(
    a = c("Overnight", rownames(fx)), b = c("Low", fx$Low), c = c("High", fx$High),
    d = c("Current Price", fx$Current), e = c("Time Now", fx$Time), stringsAsFactors = FALSE))

  cm <- f$comm_df
  doc <- u3_docx_replace_table(doc, "WTI Crude", data.frame(
    a = c("Overnight", rownames(cm)), b = c("Low", cm$Low), c = c("High", cm$High),
    d = c("Current Price", cm$Current), e = c("Time Now", cm$Time), stringsAsFactors = FALSE))

  doc <- u3_docx_insert_par_after(doc, "Overnight news", f$overnight_news %||% "")
  doc <- u3_docx_insert_par_after(doc, "Data Releases", f$today_releases %||% "")

  print(doc, target = out_path)
  out_path
}

# f: list with all Trade Sheet fields (see server code for the exact names used)
u3_build_trade_sheet_docx <- function(template_path, out_path, f) {
  doc <- officer::read_docx(template_path)

  doc <- u3_docx_replace_table(doc, "Name:",
           data.frame(a = "Name:", b = f$name %||% "", stringsAsFactors = FALSE))

  doc <- u3_docx_replace_table(doc, "Chart Period", data.frame(
    a = c("Chart Period", "Expected Trade Duration", "Initial Risk", "Initial Reward", "Initial RRR"),
    b = c(f$chart_period, f$expected_duration, f$initial_risk, f$initial_reward, f$initial_rrr),
    stringsAsFactors = FALSE))

  doc <- u3_docx_replace_table(doc, "Stop Loss", data.frame(
    a = c("Date", f$entry_date), b = c("Time", f$entry_time), c = c("B/S", f$entry_bs),
    d = c("Asset", f$entry_asset), e = c("Lot Size", f$entry_lots), f2 = c("Price", f$entry_price),
    g = c("Stop Loss", f$entry_stop), h = c("Target", f$entry_target), stringsAsFactors = FALSE))

  doc <- u3_docx_replace_table(doc, "Set-up", data.frame(
    a = c("Set-up (fundamental)", "Set-up (technical)", "Trigger", "Execution",
          "Reason for Stop Loss placement", "Reason for Target Limit placement"),
    b = c(f$setup_fundamental, f$setup_technical, f$trigger, f$execution, f$reason_stop, f$reason_target),
    stringsAsFactors = FALSE))

  if (nzchar(f$in_trade_mgmt %||% "")) {
    doc <- u3_docx_insert_par_after(doc, "In-trade Management:", f$in_trade_mgmt)
  }

  exit_df <- f$exit_df
  hdr <- data.frame(a = "Date", b = "Time", c = "B/S", d = "Asset", e = "Lot Size",
                     f2 = "Entry Price", g = "Exit Price", h = "Pips", i = "\u00a3",
                     stringsAsFactors = FALSE)
  dur <- data.frame(a = paste0("Actual Trade Duration: ", f$actual_duration %||% ""),
                     b = "", c = "", d = "", e = "", f2 = "", g = "", h = "", i = "",
                     stringsAsFactors = FALSE)
  body_rows <- exit_df
  names(body_rows) <- names(hdr)
  doc <- u3_docx_replace_table(doc, "Actual Trade Duration",
           rbind(dur, setNames(hdr, names(hdr)), body_rows), header = FALSE)

  doc <- u3_docx_replace_table(doc, "Lessons learned", data.frame(
    a = c("Reason for Exit", "Lessons learned"),
    b = c(f$reason_exit, f$lessons_learned), stringsAsFactors = FALSE))

  print(doc, target = out_path)
  out_path
}

# ===========================================================================
# UI HELPERS
# ===========================================================================

u3_status_pill <- function(state) {
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

u3_signal_card <- function(title, subtitle, state, reason_text, extra = NULL) {
  border_col <- switch(state, "ready" = "#1e7a46", "watch" = "#9c6b26", "#d5d8dc")
  tags$div(style = paste0("border:1px solid #dfe3e6; border-top:3px solid ", border_col,
                           "; border-radius:3px; padding:14px 16px; background:#fff; height:100%;"),
    tags$div(style = "display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:6px;",
      tags$div(tags$strong(title, style = "font-size:13.5px; color:#002C3C;"),
               tags$div(subtitle, style = "font-size:10.5px; color:#8a97a0; margin-top:2px;")),
      u3_status_pill(state)
    ),
    tags$p(reason_text, style = "font-size:12px; color:#4a5560; line-height:1.55; margin:8px 0 0 0;"),
    extra
  )
}

u3_signal_card_output <- function(ns, key) withSpinner(uiOutput(ns(paste0("card_", key))))

# Context/explanation strip - goes under a graph/metric box to answer "what is this and
# why does it matter for Unit 3" in place, rather than making the student go hunting.
u3_context <- function(...) {
  tags$div(style = paste0(
    "margin-top:10px; padding:10px 12px; background:#f4f8f7; border-left:3px solid #008A82; ",
    "border-radius:0 3px 3px 0; font-size:11.5px; color:#3d5a56; line-height:1.6;"
  ), ...)
}

# One metric tile for the Performance dashboard: big number + label + a one-line "why this
# matters for Task 2" note underneath, all in one visually scannable block.
u3_metric_tile <- function(label, value, sub, color = "#002C3C") {
  tags$div(style = "background:#fff; border:1px solid #e3e6e8; border-radius:3px; padding:14px 14px; height:100%;",
    tags$div(label, style = "font-size:10px; color:#8a97a0; text-transform:uppercase; letter-spacing:.04em; font-family:monospace;"),
    tags$div(value, style = paste0("font-family:monospace; font-size:22px; font-weight:700; color:", color, "; margin-top:6px;")),
    tags$div(sub, style = "font-size:10.5px; color:#8a97a0; margin-top:4px; line-height:1.4;")
  )
}

u3_glossary_df <- data.frame(
  Term = c("ADX (Average Directional Index)", "+DI / -DI", "Regime", "20-period MA", "Pivot Point (PP)",
           "S1 / R1", "Opening Range", "MPO", "R-multiple", "Risk %", "Win Rate", "Average R:R",
           "Sharpe Ratio (proxy)", "Sortino Ratio (proxy)", "Maximum Drawdown", "Plan Adherence Rate",
           "Process Failure", "Approved Exception"),
  Definition = c(
    "Wilder's (1978) measure of trend <em>strength</em> (0-100), regardless of direction. This tab reads &gt;30 as a confirmed trend, &lt;20 as range-bound.",
    "Directional Indicators: +DI rising above -DI signals bullish pressure, and vice versa. Shown alongside ADX in the Regime box.",
    "This tool's read of current market character - <b>Trending</b>, <b>Range-bound</b>, or <b>Transitional</b> - which decides whether Holy Grail or Pivot Point Bounce is the appropriate strategy right now.",
    "A 20-bar Simple Moving Average of Close. The Holy Grail strategy waits for a pullback to this line within a confirmed trend.",
    "(High + Low + Close) / 3 of the <em>prior</em> completed session - the base level pivot point strategies bounce around.",
    "First support (S1) and resistance (R1) levels derived from PP - the levels the Pivot Point Bounce strategy trades reversals from.",
    "The high/low range of the first ~30 minutes of a session. A confirmed close beyond it is the Morning/News Straddle's entry trigger.",
    "Measured Price Objective - the target implied by a pattern's own geometry (e.g. the opening range's height projected from the breakout).",
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

# ===========================================================================
# UI
# ===========================================================================

unit3_live_signals_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      tabBox(id = ns("subtabs"), width = 12, selected = "3. Live Signals",

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
        tabPanel("2. How to Use + Glossary", icon = icon("circle-question"),
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
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Glossary of terms used on this tab",
              collapsible = TRUE, collapsed = FALSE,
            ua_table(u3_glossary_df)
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("3. Live Signals", icon = icon("bolt"),
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
              u3_context(tags$b("What this is: "), "ADX(14) and its Wilder (1978) trend-strength reading. ",
                         tags$b("Why it matters: "), "it decides which Task 1 strategy is even appropriate right now - trading Holy Grail in a range, or Pivot Bounce in a trend, is exactly the mismatch Task 3's Threats should flag.")
            ),
            box(title = "Step 3 - Position Sizing", status = "primary", solidHeader = TRUE, width = 3,
              numericInput(ns("accountEquity"), "Account Equity (£)", value = 10000, min = 0, step = 100),
              sliderInput(ns("riskPct"), "Risk per trade (%)", min = 0.25, max = 3, value = 1, step = 0.25),
              uiOutput(ns("riskAmountBox")),
              u3_context(tags$b("What this is: "), "fixed-fractional position sizing. ",
                         tags$b("Why it matters: "), "Task 1 requires position sizing to be a fixed plan rule, not decided trade-by-trade (Kelly, 1956, applied conservatively) - this £ figure is what gets attached to every trade you log.")
            ),
            box(title = "Price vs. Signal Levels", status = "primary", solidHeader = TRUE, width = 6,
              withSpinner(plotlyOutput(ns("signalChart"), height = "300px")),
              u3_context(tags$b("What this shows: "), "Close price with the 20-period MA and, when a Pivot Bounce set-up is nearby, the PP/S1/R1 levels, plus ADX(14) as a lower panel with the trend-confirmation threshold marked. ",
                         tags$b("Why it matters: "), "this is the visual confirmation Task 1's decision process asks for before treating a trigger as valid.")
            )
          ),
          fluidRow(
            column(4, u3_signal_card_output(ns, "hg")),
            column(4, u3_signal_card_output(ns, "pb")),
            column(4, u3_signal_card_output(ns, "or"))
          ),
          u3_context(style = "margin:14px 0 0 0;",
            tags$b("Reading the three cards: "), "READY means every Task 1 trigger condition is satisfied right now. ",
            "WATCH means the regime is right but the precise trigger hasn't fired yet - worth monitoring, not yet actionable. ",
            "No badge means this strategy isn't suited to current conditions at all."
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("4. Trade Log & Performance", icon = icon("book"),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Session Log",
            div(style = "display:flex; gap:10px; flex-wrap:wrap; margin-bottom:12px;",
              actionButton(ns("logHG"), "Log Holy Grail signal", icon = icon("plus"), class = "btn-sm"),
              actionButton(ns("logPB"), "Log Pivot Bounce signal", icon = icon("plus"), class = "btn-sm"),
              actionButton(ns("logOR"), "Log Opening-Range signal", icon = icon("plus"), class = "btn-sm"),
              actionButton(ns("logManual"), "Log manual entry", icon = icon("pen"), class = "btn-sm btn-default"),
              downloadButton(ns("downloadLog"), "Download log (CSV)", class = "btn-sm btn-primary"),
              actionButton(ns("clearLog"), "Clear log", icon = icon("trash"), class = "btn-sm btn-default")
            ),
            u3_context(
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
        tabPanel("5. Strategy Evaluation (SWOT)", icon = icon("magnifying-glass-chart"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this tab",
            tags$p(paste0(
              "Task 3 asks for a structured evaluation, not a general narrative. The panel below pulls your ",
              "best- and worst-performing strategy straight from the Trade Log, so you can argue each SWOT ",
              "point from your own evidence rather than impression."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
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
            downloadButton(ns("downloadSwot"), "Download SWOT (text file)", class = "btn-primary")
          )
        ),
        # ---------------------------------------------------------------
        tabPanel("6. Morning Sheet", icon = icon("sun"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this tab",
            tags$p(paste0(
              "Builds the real Morning Sheet template (overnight markets and today's macro data), ",
              "one to be completed and saved every trading day per the assignment's Key Reminders. ",
              "Fill in the fields, check the preview matches what you expect, then save \u2014 the file is ",
              "written straight into your Dropbox Morning Sheets folder with today's date in the name."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Save location",
              collapsible = TRUE, collapsed = TRUE,
            textInput(ns("morningSheetFolder"), "Dropbox folder for Morning Sheets", width = "100%",
              value = "C:/Users/jfz00/Dropbox/London Academy of Trading/Jose-F_Zubizarreta/Morning Sheets"),
            textInput(ns("templateFolder"), "Folder containing the two template .docx files", width = "100%",
              value = "templates"),
            u3_context("Copy ", tags$code("Morning_Sheet_Template.docx"), " and ",
                       tags$code("Trade_Sheet_-_Template.docx"), " into that templates folder once \u2014 ",
                       "the app reads them fresh each time it saves, it never modifies your originals.")
          ),
          fluidRow(
            box(width = 12, status = "info", solidHeader = TRUE, title = "Fields",
              fluidRow(
                column(6, textInput(ns("msName"), "Name", value = "")),
                column(6, dateInput(ns("msDate"), "Date", value = Sys.Date()))
              ),
              tags$h5("Overnight Indices", style = "margin-top:6px;"),
              fluidRow(
                column(3, textInput(ns("msDowPrice"), "Dow Jones price")),
                column(3, textInput(ns("msDowChange"), "Dow Jones change")),
                column(3, textInput(ns("msNikkeiPrice"), "Nikkei price")),
                column(3, textInput(ns("msNikkeiChange"), "Nikkei change"))
              ),
              tags$h5("FX \u2014 overnight Low / High / Current / Time", style = "margin-top:6px;"),
              tags$p("Double-click a cell to edit.", style = "font-size:11px; color:#8a97a0;"),
              DT::dataTableOutput(ns("msFxTable")),
              tags$h5("Commodities \u2014 overnight Low / High / Current / Time", style = "margin-top:14px;"),
              DT::dataTableOutput(ns("msCommTable")),
              fluidRow(style = "margin-top:14px;",
                column(6, textAreaInput(ns("msOvernightNews"), "Overnight news", rows = 3, width = "100%")),
                column(6, textAreaInput(ns("msTodayReleases"), "Today's Data Releases", rows = 3, width = "100%"))
              )
            )
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Preview \u2014 this is what will be saved",
            uiOutput(ns("msPreview"))
          ),
          div(style = "margin-bottom:20px; display:flex; align-items:center; gap:14px;",
            actionButton(ns("saveMorningSheet"), "Save Morning Sheet to Dropbox", icon = icon("floppy-disk"), class = "btn-primary"),
            uiOutput(ns("msSaveStatus"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("7. Individual Trade Sheet", icon = icon("file-signature"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this tab",
            tags$p(paste0(
              "Builds the real Individual Trade Sheet template \u2014 one required per trade opened, per the ",
              "assignment's Key Reminders, with Lessons Learned being the section that matters most. Optionally ",
              "pull the entry details straight from a trade you've already logged on the Trade Log tab, then ",
              "fill in the reasoning fields, check the preview, and save."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Save location",
              collapsible = TRUE, collapsed = TRUE,
            textInput(ns("tradeSheetFolder"), "Dropbox folder for Individual Trade Sheets", width = "100%",
              value = "C:/Users/jfz00/Dropbox/London Academy of Trading/Jose-F_Zubizarreta/Individual Trade Sheets")
          ),
          fluidRow(
            box(width = 12, status = "info", solidHeader = TRUE, title = "Pull from a logged trade (optional)",
              uiOutput(ns("tsPullSelector")),
              actionButton(ns("tsPullBtn"), "Pull selected trade into the fields below", icon = icon("arrow-down"), class = "btn-sm")
            )
          ),
          fluidRow(
            box(width = 12, status = "info", solidHeader = TRUE, title = "Trade Entry",
              fluidRow(
                column(6, textInput(ns("tsName"), "Name", value = "")),
                column(6, textInput(ns("tsChartPeriod"), "Chart Period", placeholder = "e.g. 15m / 1H / Daily"))
              ),
              fluidRow(
                column(4, textInput(ns("tsExpectedDuration"), "Expected Trade Duration")),
                column(4, textInput(ns("tsInitialRisk"), "Initial Risk")),
                column(4, textInput(ns("tsInitialReward"), "Initial Reward"))
              ),
              textInput(ns("tsInitialRRR"), "Initial RRR", placeholder = "e.g. 1:2.5"),
              fluidRow(
                column(2, dateInput(ns("tsEntryDate"), "Date")),
                column(2, textInput(ns("tsEntryTime"), "Time")),
                column(2, selectInput(ns("tsEntryBS"), "B/S", choices = c("Long","Short"))),
                column(2, textInput(ns("tsEntryAsset"), "Asset")),
                column(2, textInput(ns("tsEntryLots"), "Lot Size")),
                column(2, textInput(ns("tsEntryPrice"), "Price"))
              ),
              fluidRow(
                column(6, textInput(ns("tsEntryStop"), "Stop Loss")),
                column(6, textInput(ns("tsEntryTarget"), "Target"))
              ),
              fluidRow(
                column(6, textAreaInput(ns("tsSetupFundamental"), "Set-up (fundamental)", rows = 2, width = "100%")),
                column(6, textAreaInput(ns("tsSetupTechnical"), "Set-up (technical)", rows = 2, width = "100%"))
              ),
              fluidRow(
                column(6, textAreaInput(ns("tsTrigger"), "Trigger", rows = 2, width = "100%")),
                column(6, textAreaInput(ns("tsExecution"), "Execution", rows = 2, width = "100%"))
              ),
              fluidRow(
                column(6, textAreaInput(ns("tsReasonStop"), "Reason for Stop Loss placement", rows = 2, width = "100%")),
                column(6, textAreaInput(ns("tsReasonTarget"), "Reason for Target Limit placement", rows = 2, width = "100%"))
              )
            )
          ),
          fluidRow(
            box(width = 12, status = "info", solidHeader = TRUE, title = "In-Trade Management",
              tags$p("If you cut part of your position and/or move your stop loss, explain here.",
                     style = "font-size:11.5px; color:#666;"),
              textAreaInput(ns("tsInTradeMgmt"), NULL, rows = 3, width = "100%")
            )
          ),
          fluidRow(
            box(width = 12, status = "info", solidHeader = TRUE, title = "Trade Exit",
              textInput(ns("tsActualDuration"), "Actual Trade Duration"),
              tags$p("Double-click a cell to edit. Add a row per partial exit.", style = "font-size:11px; color:#8a97a0;"),
              DT::dataTableOutput(ns("tsExitTable")),
              actionButton(ns("tsAddExitRow"), "Add Exit Row", icon = icon("plus"), class = "btn-sm", style="margin-top:8px;"),
              fluidRow(style = "margin-top:14px;",
                column(6, textAreaInput(ns("tsReasonExit"), "Reason for Exit", rows = 2, width = "100%")),
                column(6, textAreaInput(ns("tsLessonsLearned"), "Lessons Learned", rows = 2, width = "100%"))
              )
            )
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Preview \u2014 this is what will be saved",
            uiOutput(ns("tsPreview"))
          ),
          div(style = "margin-bottom:20px; display:flex; align-items:center; gap:14px;",
            actionButton(ns("saveTradeSheet"), "Save Trade Sheet to Dropbox", icon = icon("floppy-disk"), class = "btn-primary"),
            uiOutput(ns("tsSaveStatus"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("8. Strategy Summary", icon = icon("layer-group"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this tab",
            tags$p(paste0(
              "A plain-language recap of the exact plan configuration currently active \u2014 the asset, the ",
              "fixed parameters behind each strategy, and today's live signal state \u2014 useful to paste into ",
              "the Task 1 write-up or to sanity-check before a session."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Current configuration",
            uiOutput(ns("strategySummary"))
          ),
          div(style = "margin-bottom:20px;",
            downloadButton(ns("downloadStrategySummary"), "Download Strategy Summary (text file)", class = "btn-primary")
          )
        )

      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

unit3_live_signals_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {

    # -- Live signal computation (Tab 3) --
    signals <- reactive({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% arrange(Date)
      req(nrow(data) >= 15)

      list(
        data = data,
        regime = u3_regime(data),
        hg = u3_holy_grail(data),
        pb = u3_pivot_bounce(data),
        or_sig = u3_opening_range(data, data_manager$resolution)
      )
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

    output$card_hg <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      hg <- s$hg
      state <- if (isTRUE(hg$ready)) "ready" else if (isTRUE(hg$watch)) "watch" else "none"
      u3_signal_card("Holy Grail", "Trend pullback - ADX > 30", state, hg$reason)
    })
    output$card_pb <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      pb <- s$pb
      state <- if (isTRUE(pb$ready)) "ready" else if (isTRUE(pb$watch)) "watch" else "none"
      u3_signal_card("Pivot Point Bounce", "Range reversal - ADX < 30", state, pb$reason)
    })
    output$card_or <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      or_sig <- s$or_sig
      state <- if (isTRUE(or_sig$ready)) "ready" else if (isTRUE(or_sig$watch)) "watch" else "none"
      u3_signal_card("Morning / News Straddle", "Opening-range break", state, or_sig$reason)
    })

    output$signalChart <- renderPlotly({
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      data <- tail(s$data, 120)
      ma <- SMA(data$Close, n = min(20, nrow(data) - 1))
      adx_df <- tryCatch(as.data.frame(TTR::ADX(data[, c("High","Low","Close")], n = 14)), error = function(e) NULL)

      p1 <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                    name = "Close", line = list(color = "#002C3C", width = 1.6))
      p1 <- p1 %>% add_trace(x = data$Date, y = as.numeric(ma), type = "scatter", mode = "lines",
                              name = "MA(20)", line = list(color = "#e67e22", width = 1.6, dash = "dot"))
      if (!is.null(s$pb$pivot)) {
        p1 <- p1 %>%
          add_trace(x = range(data$Date), y = rep(s$pb$pivot, 2), type = "scatter", mode = "lines",
                     name = "PP", line = list(color = "#2980b9", width = 1, dash = "dash")) %>%
          add_trace(x = range(data$Date), y = rep(s$pb$level_price, 2), type = "scatter", mode = "lines",
                     name = s$pb$level, line = list(color = "#8e44ad", width = 1, dash = "dash"))
      }
      p1 <- p1 %>% layout(yaxis = list(title = "Price"), showlegend = TRUE,
                          legend = list(orientation = "h", y = 1.15, font = list(size = 9)))

      if (!is.null(adx_df) && "ADX" %in% names(adx_df)) {
        p2 <- plot_ly(x = data$Date, y = as.numeric(adx_df$ADX), type = "scatter", mode = "lines",
                     name = "ADX(14)", line = list(color = "#c0392b", width = 1.5)) %>%
          add_trace(x = range(data$Date), y = c(30, 30), mode = "lines", name = "Trend threshold",
                    line = list(color = "#c0392b", width = 0.75, dash = "dot"), showlegend = FALSE) %>%
          layout(yaxis = list(title = "ADX", range = c(0, 60)))
        subplot(p1, p2, nrows = 2, heights = c(0.72, 0.28), shareX = TRUE, titleY = TRUE) %>%
          layout(plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 20))
      } else {
        p1 %>% layout(plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 20))
      }
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

    append_signal <- function(strategy, direction, notes) {
      s <- tryCatch(signals(), error = function(e) NULL)
      if (is.null(s)) { showNotification("No data loaded yet.", type = "warning"); return() }
      last_price <- tail(s$data$Close, 1)
      risk_amt <- (input$accountEquity %||% 0) * ((input$riskPct %||% 1) / 100)
      row <- data.frame(
        Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M"),
        Asset = data_manager$current_asset %||% "-",
        Class = data_manager$current_asset_class %||% "-",
        Resolution = data_manager$resolution %||% "1d",
        Strategy = strategy, Direction = direction %||% "-",
        Regime = paste0(s$regime$regime, " (ADX ", s$regime$adx, ")"),
        `Signal Price` = round(last_price, 4), `Suggested Stop` = NA, `Suggested Target` = NA,
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
      append_signal("Holy Grail", s$hg$direction, s$hg$reason)
    })
    observeEvent(input$logPB, {
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      if (!isTRUE(s$pb$ready)) showNotification("Pivot Bounce is not READY right now - logged anyway as a watch note.", type = "warning")
      append_signal("Pivot Point Bounce", s$pb$direction, s$pb$reason)
    })
    observeEvent(input$logOR, {
      s <- tryCatch(signals(), error = function(e) NULL); req(s)
      if (!isTRUE(s$or_sig$ready)) showNotification("Opening-range break is not READY right now - logged anyway as a watch note.", type = "warning")
      append_signal("Morning/News Straddle", s$or_sig$direction, s$or_sig$reason)
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
    metrics <- reactive({ u3_compute_metrics(session_log(), starting_equity = input$accountEquity %||% 10000) })

    output$performanceArea <- renderUI({
      m <- metrics()
      if (!isTRUE(m$ok)) {
        return(tags$p(m$reason %||% "No performance data yet - log a signal above, then mark it Closed once the trade is finished.",
                      style = "font-size:12.5px; color:#8a97a0; font-style:italic;"))
      }
      tagList(
        fluidRow(
          column(2, u3_metric_tile("Trades Closed", m$n, "logged & marked Closed")),
          column(2, u3_metric_tile("Win Rate", paste0(round(m$win_rate,1), "%"),
                                    paste0(m$n_wins, "W / ", m$n_losses, "L"),
                                    color = if (m$win_rate >= 50) "#1e7a46" else "#9c6b26")),
          column(2, u3_metric_tile("Avg R:R", if (is.na(m$avg_rr)) "-" else paste0(round(m$avg_rr,2), ":1"),
                                    "avg win R / avg loss R", color = "#002C3C")),
          column(2, u3_metric_tile("Total Return", paste0(if (m$total_return>=0) "+" else "", "£", round(m$total_return,2)),
                                    paste0(round(m$total_return_pct,2), "% of starting equity"),
                                    color = if (m$total_return>=0) "#1e7a46" else "#c0392b")),
          column(2, u3_metric_tile("Max Drawdown", paste0(round(m$max_dd,1), "%"), "peak-to-trough equity decline", color = "#c0392b")),
          column(2, u3_metric_tile("Plan Adherence", if (is.na(m$adherence)) "-" else paste0(round(m$adherence,1), "%"),
                                    "% of closed trades on-plan",
                                    color = if (!is.na(m$adherence) && m$adherence>=80) "#1e7a46" else "#9c6b26"))
        ),
        fluidRow(
          column(6, u3_metric_tile("Sharpe (proxy)", if (is.na(m$sharpe)) "-" else round(m$sharpe,2),
                                    "mean return / total volatility - penalises up and down moves equally")),
          column(6, u3_metric_tile("Sortino (proxy)", if (is.na(m$sortino)) "-" else round(m$sortino,2),
                                    "mean return / downside volatility only - the more appropriate figure for an asymmetric-target plan"))
        ),
        u3_context(style = "margin-top:14px;",
          tags$b("How to read this against Task 1: "), "compare Total Return and Max Drawdown directly against the objective ",
          "you set (e.g. positive return, drawdown under a fixed %), and Plan Adherence against your target adherence rate. ",
          "A Win Rate under 50% is not itself a problem if Avg R:R comfortably compensates for it."
        ),
        tags$div(style = "margin-top:16px;", withSpinner(plotlyOutput(session$ns("equityCurveChart"), height = "260px"))),
        u3_context(style = "margin-top:8px;",
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
          column(4, u3_metric_tile("Best strategy", best$Strategy, paste0(round(best$total_r,2), "R total - ", round(best$win_rate,0), "% win rate"), "#1e7a46")),
          column(4, u3_metric_tile("Weakest strategy", worst$Strategy, paste0(round(worst$total_r,2), "R total - ", round(worst$win_rate,0), "% win rate"), "#c0392b")),
          column(4, u3_metric_tile("Deviations logged", n_deviations, "closed trades marked Plan Followed = No", "#9c6b26"))
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
          "Generated: ", format(Sys.time()), "\n\n",
          "STRENGTHS\n", input$swotS %||% "", "\n\n",
          "WEAKNESSES\n", input$swotW %||% "", "\n\n",
          "OPPORTUNITIES\n", input$swotO %||% "", "\n\n",
          "THREATS\n", input$swotT %||% "", "\n"
        )
        writeLines(txt, file)
      }
    )

    # ===================================================================
    # Tab 6: Morning Sheet
    # ===================================================================
    ms_fx <- reactiveVal(data.frame(
      Low = c(NA_real_, NA_real_, NA_real_, NA_real_), High = c(NA_real_, NA_real_, NA_real_, NA_real_),
      Current = c(NA_real_, NA_real_, NA_real_, NA_real_), Time = rep("", 4),
      row.names = c("EUR-USD", "USD-JPY", "GBP-USD", "AUD-USD"), check.names = FALSE, stringsAsFactors = FALSE
    ))
    ms_comm <- reactiveVal(data.frame(
      Low = c(NA_real_, NA_real_), High = c(NA_real_, NA_real_), Current = c(NA_real_, NA_real_), Time = rep("", 2),
      row.names = c("WTI Crude", "Gold"), check.names = FALSE, stringsAsFactors = FALSE
    ))

    output$msFxTable <- DT::renderDataTable({
      DT::datatable(ms_fx(), editable = TRUE, options = list(dom = 't', paging = FALSE, ordering = FALSE))
    })
    ms_fx_proxy <- DT::dataTableProxy("msFxTable")
    observeEvent(input$msFxTable_cell_edit, {
      info <- input$msFxTable_cell_edit
      df <- ms_fx()
      df[info$row, info$col] <- DT::coerceValue(info$value, df[info$row, info$col])
      ms_fx(df)
      DT::replaceData(ms_fx_proxy, df, resetPaging = FALSE)
    })

    output$msCommTable <- DT::renderDataTable({
      DT::datatable(ms_comm(), editable = TRUE, options = list(dom = 't', paging = FALSE, ordering = FALSE))
    })
    ms_comm_proxy <- DT::dataTableProxy("msCommTable")
    observeEvent(input$msCommTable_cell_edit, {
      info <- input$msCommTable_cell_edit
      df <- ms_comm()
      df[info$row, info$col] <- DT::coerceValue(info$value, df[info$row, info$col])
      ms_comm(df)
      DT::replaceData(ms_comm_proxy, df, resetPaging = FALSE)
    })

    ms_fields <- reactive({
      list(name = input$msName %||% "", date = format(input$msDate %||% Sys.Date(), "%Y-%m-%d"),
           dow_price = input$msDowPrice %||% "", dow_change = input$msDowChange %||% "",
           nikkei_price = input$msNikkeiPrice %||% "", nikkei_change = input$msNikkeiChange %||% "",
           fx_df = ms_fx(), comm_df = ms_comm(),
           overnight_news = input$msOvernightNews %||% "", today_releases = input$msTodayReleases %||% "")
    })

    output$msPreview <- renderUI({
      f <- ms_fields()
      tagList(
        tags$table(class = "ua-table",
          tags$tr(tags$td(tags$b("Name")), tags$td(f$name)),
          tags$tr(tags$td(tags$b("Date")), tags$td(f$date)),
          tags$tr(tags$td(tags$b("Dow Jones")), tags$td(paste(f$dow_price, f$dow_change))),
          tags$tr(tags$td(tags$b("Nikkei")), tags$td(paste(f$nikkei_price, f$nikkei_change)))
        ),
        tags$p(tags$b("FX"), style="margin-top:10px;"), ua_table(cbind(Pair = rownames(f$fx_df), f$fx_df)),
        tags$p(tags$b("Commodities"), style="margin-top:10px;"), ua_table(cbind(Asset = rownames(f$comm_df), f$comm_df)),
        tags$p(tags$b("Overnight news"), style="margin-top:10px;"), tags$p(f$overnight_news),
        tags$p(tags$b("Today's Data Releases")), tags$p(f$today_releases)
      )
    })

    observeEvent(input$saveMorningSheet, {
      f <- ms_fields()
      template_path <- file.path(input$templateFolder %||% "templates", "Morning_Sheet_Template.docx")
      out_folder <- input$morningSheetFolder
      if (!file.exists(template_path)) {
        output$msSaveStatus <- renderUI(tags$span(paste("Template not found at", template_path), style = "color:#c0392b; font-size:12px;"))
        return()
      }
      ok <- tryCatch({ dir.create(out_folder, recursive = TRUE, showWarnings = FALSE); TRUE }, error = function(e) FALSE)
      keyword1 <- u3_keyword_safe(data_manager$current_asset %||% "Asset")
      keyword2 <- u3_keyword_safe(f$dow_change != "" && grepl("-", f$dow_change), "Overview")
      fname <- paste0("Morning_Sheet_", f$date, "_", keyword1, ".docx")
      out_path <- file.path(out_folder, fname)
      result <- tryCatch({
        u3_build_morning_sheet_docx(template_path, out_path, f)
        list(ok = TRUE, path = out_path)
      }, error = function(e) list(ok = FALSE, msg = conditionMessage(e)))
      output$msSaveStatus <- renderUI({
        if (isTRUE(result$ok)) {
          tags$span(paste("Saved:", result$path), style = "color:#1e7a46; font-size:12px; font-family:monospace;")
        } else {
          tags$span(paste("Save failed:", result$msg), style = "color:#c0392b; font-size:12px;")
        }
      })
    })

    # ===================================================================
    # Tab 7: Individual Trade Sheet
    # ===================================================================
    empty_exit_rows <- function() data.frame(
      Date = "", Time = "", `B/S` = "", Asset = "", `Lot Size` = "", `Entry Price` = "",
      `Exit Price` = "", Pips = "", `£` = "", check.names = FALSE, stringsAsFactors = FALSE
    )
    ts_exit_rows <- reactiveVal(empty_exit_rows())

    output$tsPullSelector <- renderUI({
      log <- session_log()
      if (nrow(log) == 0) return(tags$p("No trades logged yet on the Trade Log tab.", style = "font-size:12px; color:#8a97a0; font-style:italic;"))
      choices <- setNames(seq_len(nrow(log)), paste(log$Timestamp, log$Asset, log$Strategy, sep = " \u00b7 "))
      selectInput(session$ns("tsPullChoice"), NULL, choices = choices, width = "100%")
    })

    observeEvent(input$tsPullBtn, {
      req(input$tsPullChoice)
      row <- session_log()[as.integer(input$tsPullChoice), ]
      updateTextInput(session, "tsEntryAsset", value = row$Asset)
      updateTextInput(session, "tsChartPeriod", value = row$Resolution)
      updateDateInput(session, "tsEntryDate", value = as.Date(substr(row$Timestamp, 1, 10)))
      updateTextInput(session, "tsEntryTime", value = substr(row$Timestamp, 12, 16))
      updateSelectInput(session, "tsEntryBS", selected = if (identical(row$Direction, "Short")) "Short" else "Long")
      updateTextInput(session, "tsEntryPrice", value = as.character(row$`Signal Price`))
      updateTextInput(session, "tsTrigger", value = row$Regime %||% "")
      updateTextInput(session, "tsSetupTechnical", value = row$Notes %||% "")
      if (!is.na(suppressWarnings(as.numeric(row$`Exit Price`)))) {
        er <- empty_exit_rows()
        er[1, ] <- list(row$Timestamp, "", row$Direction %||% "", row$Asset, "", as.character(row$`Signal Price`),
                         as.character(row$`Exit Price`), "", as.character(row$`Risk £` * (suppressWarnings(as.numeric(row$`Real R`)) %||% 0)))
        ts_exit_rows(er)
      }
      showNotification("Pulled trade into the fields below.", type = "message", duration = 2)
    })

    output$tsExitTable <- DT::renderDataTable({
      DT::datatable(ts_exit_rows(), rownames = FALSE, editable = TRUE, options = list(dom = 't', paging = FALSE, ordering = FALSE))
    })
    ts_exit_proxy <- DT::dataTableProxy("tsExitTable")
    observeEvent(input$tsExitTable_cell_edit, {
      info <- input$tsExitTable_cell_edit
      df <- ts_exit_rows()
      df[info$row, info$col + 1] <- DT::coerceValue(info$value, df[info$row, info$col + 1])
      ts_exit_rows(df)
      DT::replaceData(ts_exit_proxy, df, resetPaging = FALSE, rownames = FALSE)
    })
    observeEvent(input$tsAddExitRow, {
      df <- ts_exit_rows()
      df[nrow(df) + 1, ] <- ""
      ts_exit_rows(df)
    })

    ts_fields <- reactive({
      exit_df <- ts_exit_rows()
      names(exit_df) <- c("a","b","c","d","e","f2","g","h","i")
      list(name = input$tsName %||% "", chart_period = input$tsChartPeriod %||% "",
           expected_duration = input$tsExpectedDuration %||% "", initial_risk = input$tsInitialRisk %||% "",
           initial_reward = input$tsInitialReward %||% "", initial_rrr = input$tsInitialRRR %||% "",
           entry_date = format(input$tsEntryDate %||% Sys.Date(), "%Y-%m-%d"), entry_time = input$tsEntryTime %||% "",
           entry_bs = input$tsEntryBS %||% "", entry_asset = input$tsEntryAsset %||% "",
           entry_lots = input$tsEntryLots %||% "", entry_price = input$tsEntryPrice %||% "",
           entry_stop = input$tsEntryStop %||% "", entry_target = input$tsEntryTarget %||% "",
           setup_fundamental = input$tsSetupFundamental %||% "", setup_technical = input$tsSetupTechnical %||% "",
           trigger = input$tsTrigger %||% "", execution = input$tsExecution %||% "",
           reason_stop = input$tsReasonStop %||% "", reason_target = input$tsReasonTarget %||% "",
           in_trade_mgmt = input$tsInTradeMgmt %||% "", actual_duration = input$tsActualDuration %||% "",
           exit_df = exit_df, reason_exit = input$tsReasonExit %||% "", lessons_learned = input$tsLessonsLearned %||% "")
    })

    output$tsPreview <- renderUI({
      f <- ts_fields()
      tagList(
        ua_table(data.frame(Field = c("Name","Chart Period","Expected Duration","Initial Risk","Initial Reward","Initial RRR"),
                             Value = c(f$name, f$chart_period, f$expected_duration, f$initial_risk, f$initial_reward, f$initial_rrr))),
        tags$p(tags$b("Entry"), style="margin-top:10px;"),
        ua_table(data.frame(Date=f$entry_date, Time=f$entry_time, `B/S`=f$entry_bs, Asset=f$entry_asset,
                             Lots=f$entry_lots, Price=f$entry_price, Stop=f$entry_stop, Target=f$entry_target, check.names=FALSE)),
        tags$p(tags$b("Reasoning"), style="margin-top:10px;"),
        ua_table(data.frame(Field = c("Set-up (fundamental)","Set-up (technical)","Trigger","Execution","Reason for Stop","Reason for Target"),
                             Value = c(f$setup_fundamental, f$setup_technical, f$trigger, f$execution, f$reason_stop, f$reason_target))),
        if (nzchar(f$in_trade_mgmt)) tagList(tags$p(tags$b("In-Trade Management"), style="margin-top:10px;"), tags$p(f$in_trade_mgmt)),
        tags$p(tags$b("Exit"), style="margin-top:10px;"),
        DT::datatable(f$exit_df, rownames = FALSE, options = list(dom = 't', paging = FALSE)),
        ua_table(data.frame(Field = c("Reason for Exit","Lessons Learned"), Value = c(f$reason_exit, f$lessons_learned)))
      )
    })

    observeEvent(input$saveTradeSheet, {
      f <- ts_fields()
      template_path <- file.path(input$templateFolder %||% "templates", "Trade_Sheet_-_Template.docx")
      out_folder <- input$tradeSheetFolder
      if (!file.exists(template_path)) {
        output$tsSaveStatus <- renderUI(tags$span(paste("Template not found at", template_path), style = "color:#c0392b; font-size:12px;"))
        return()
      }
      dir.create(out_folder, recursive = TRUE, showWarnings = FALSE)
      keyword1 <- u3_keyword_safe(f$entry_asset, "Asset")
      keyword2 <- u3_keyword_safe(f$entry_bs, "Trade")
      fname <- paste0("Trade_Sheet_", f$entry_date, "_", keyword1, "_", keyword2, ".docx")
      out_path <- file.path(out_folder, fname)
      result <- tryCatch({
        u3_build_trade_sheet_docx(template_path, out_path, f)
        list(ok = TRUE, path = out_path)
      }, error = function(e) list(ok = FALSE, msg = conditionMessage(e)))
      output$tsSaveStatus <- renderUI({
        if (isTRUE(result$ok)) {
          tags$span(paste("Saved:", result$path), style = "color:#1e7a46; font-size:12px; font-family:monospace;")
        } else {
          tags$span(paste("Save failed:", result$msg), style = "color:#c0392b; font-size:12px;")
        }
      })
    })

    # ===================================================================
    # Tab 8: Strategy Summary
    # ===================================================================
    output$strategySummary <- renderUI({
      s <- tryCatch(signals(), error = function(e) NULL)
      tagList(
        ua_table(data.frame(
          Parameter = c("Asset class", "Asset", "Data resolution", "Account equity", "Risk per trade",
                         "Holy Grail trend threshold", "Holy Grail MA period", "Pivot Bounce ADX ceiling",
                         "Opening range window"),
          Value = c(data_manager$current_asset_class %||% "-", data_manager$current_asset %||% "-",
                     data_manager$resolution %||% "1d", paste0("\u00a3", input$accountEquity %||% 10000),
                     paste0(input$riskPct %||% 1, "%"), "ADX > 30", "20-period SMA", "ADX < 30", "First 30 minutes")
        )),
        tags$p(tags$b("Live signal state"), style="margin-top:12px;"),
        if (!is.null(s) && s$regime$ok) {
          ua_table(data.frame(
            Signal = c("Regime", "Holy Grail", "Pivot Point Bounce", "Opening Range"),
            State = c(paste0(s$regime$regime, " (ADX ", s$regime$adx, ")"),
                       if (isTRUE(s$hg$ready)) "READY" else if (isTRUE(s$hg$watch)) "WATCH" else "No signal",
                       if (isTRUE(s$pb$ready)) "READY" else if (isTRUE(s$pb$watch)) "WATCH" else "No signal",
                       if (isTRUE(s$or_sig$ready)) "READY" else if (isTRUE(s$or_sig$watch)) "WATCH" else "No signal")
          ))
        } else {
          tags$p("Not enough data loaded yet to read live signals.", style = "font-size:12px; color:#8a97a0; font-style:italic;")
        }
      )
    })

    output$downloadStrategySummary <- downloadHandler(
      filename = function() paste0("unit3_strategy_summary_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) {
        s <- tryCatch(signals(), error = function(e) NULL)
        txt <- paste0(
          "UNIT 3 - STRATEGY SUMMARY\n", "Generated: ", format(Sys.time()), "\n\n",
          "Asset class: ", data_manager$current_asset_class %||% "-", "\n",
          "Asset: ", data_manager$current_asset %||% "-", "\n",
          "Resolution: ", data_manager$resolution %||% "1d", "\n",
          "Account equity: £", input$accountEquity %||% 10000, "\n",
          "Risk per trade: ", input$riskPct %||% 1, "%\n\n",
          "Fixed strategy parameters:\n",
          "- Holy Grail: ADX(14) > 30, 20-period SMA pullback\n",
          "- Pivot Point Bounce: ADX(14) < 30, reversal at prior-session S1/R1\n",
          "- Morning/News Straddle: first 30 minutes opening range break\n\n",
          if (!is.null(s) && s$regime$ok) paste0(
            "Live signal state at generation time:\n",
            "- Regime: ", s$regime$regime, " (ADX ", s$regime$adx, ")\n",
            "- Holy Grail: ", if (isTRUE(s$hg$ready)) "READY" else if (isTRUE(s$hg$watch)) "WATCH" else "No signal", "\n",
            "- Pivot Point Bounce: ", if (isTRUE(s$pb$ready)) "READY" else if (isTRUE(s$pb$watch)) "WATCH" else "No signal", "\n"
          ) else "Live signal state: not enough data loaded.\n"
        )
        writeLines(txt, file)
      }
    )

    session$onSessionEnded(function() {})
  })
}
