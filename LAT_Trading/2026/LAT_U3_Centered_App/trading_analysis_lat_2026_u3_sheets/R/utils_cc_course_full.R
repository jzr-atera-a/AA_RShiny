# **** Full course coverage: the remaining LAT topics as pure functions (no Shiny).
#  Rule of Five time-frames (Week 7), support / resistance, pivots and Fibonacci (Weeks 1-2, Week 6), candlesticks / trend lines /
#  chart patterns grouped by course topic (Weeks 1-2), stochastics and RSI divergence (Week 3), types of investment risk and
#  relative value (Week 2), trading biases (Week 4 psychology; Unit 2), attitude survey (Introduction), course coverage map.

# ---- Rule of Five: base = the loaded candle; minor and major = the nearest Capital.com candles to the course table ----
cc_r5_map <- data.frame(stringsAsFactors = FALSE,
  base  = c("MINUTE_5", "MINUTE_15", "MINUTE_30", "HOUR", "HOUR_4"),
  minor = c("MINUTE", "MINUTE", "MINUTE_5", "MINUTE_15", "HOUR"),
  major = c("MINUTE_30", "HOUR", "HOUR_4", "HOUR_4", "DAY"),
  course = c("5 minutes: minor 1 minute, major 30 minutes", "between 5 and 30 minutes: minor 1 minute, major about 1 hour",
             "30 minutes: minor 5 minutes, major 2-3 hours", "about 2 hours: minor 30 minutes, major 12 hours", "between 2 hours and 1 day: minor about 1 hour, major 1 day"))
cc_r5_frames <- function(base) { i <- match(base, cc_r5_map$base); if (is.na(i)) NULL else as.list(cc_r5_map[i, ]) }
cc_r5_days <- c(MINUTE = 1, MINUTE_5 = 3, MINUTE_15 = 6, MINUTE_30 = 10, HOUR = 20, HOUR_4 = 45, DAY = 200)
# trends: named character c(minor=, base=, major=) with "UP"/"DOWN"/"RANGE"/"unknown"; dir +1 buy / -1 sell / NA
cc_r5_verdict <- function(trends, dir = NA) {
  up <- function(x) grepl("UP", toupper(x)); dn <- function(x) grepl("DOWN", toupper(x)); t <- trends
  agree <- (all(up(t)) || all(dn(t))); maj <- if (up(t[["major"]])) 1 else if (dn(t[["major"]])) -1 else 0
  txt <- sprintf("minor %s, base %s, major %s", t[["minor"]], t[["base"]], t[["major"]])
  ok <- if (is.na(dir) || maj == 0) NA else dir == maj
  list(text = paste0(txt, if (agree) " - all three agree: trade only with them" else if (maj == 0) " - major has no clear trend" else sprintf(" - position with the major trend (%s)", if (maj > 0) "up" else "down")),
       agree = agree, major = maj, ok = ok) }

# ---- Support / resistance on higher frames, pivots (7 levels) and Fibonacci --------------------------------------------
cc_sr_levels <- function(bd, price = NA) { if (is.null(bd) || nrow(bd) < 6) return(NULL)
  bd <- bd[order(bd$time), , drop = FALSE]; n <- nrow(bd); y <- bd[n - 1, ]; w <- bd[max(1, n - 5):(n - 1), , drop = FALSE]
  m <- bd[max(1, n - 22):(n - 1), , drop = FALSE]
  pv <- if (exists("u3r_pivots")) u3r_pivots(y$high, y$low, y$close) else { pp <- (y$high + y$low + y$close) / 3; c(R1 = 2 * pp - y$low, PP = pp, S1 = 2 * pp - y$high) }
  lv <- c(`Previous day high` = y$high, `Previous day low` = y$low, `Last 5 days high` = max(w$high), `Last 5 days low` = min(w$low),
          `Last month high` = max(m$high), `Last month low` = min(m$low), setNames(pv, paste("Pivot", names(pv))))
  d <- data.frame(level = names(lv), price = as.numeric(lv), stringsAsFactors = FALSE)
  if (is.finite(price)) { d$side <- ifelse(d$price > price, "resistance (above)", "support (below)"); d$dist <- d$price - price; d <- d[order(-d$price), , drop = FALSE] }
  d }
cc_sr_near <- function(d, price) { if (is.null(d) || !is.finite(price)) return("")
  a <- d[d$price > price, , drop = FALSE]; b <- d[d$price <= price, , drop = FALSE]
  sprintf("nearest resistance %s at %s; nearest support %s at %s",
          if (nrow(a)) a$level[which.min(a$price)] else "-", if (nrow(a)) format(round(min(a$price), 4)) else "-",
          if (nrow(b)) b$level[which.max(b$price)] else "-", if (nrow(b)) format(round(max(b$price), 4)) else "-") }
cc_fib_levels <- function(ctx, look = 100) { n <- ctx$n; i <- max(1, n - look + 1):n; hi <- which.max(ctx$h[i]) + i[1] - 1; lo <- which.min(ctx$l[i]) + i[1] - 1
  H <- ctx$h[hi]; L <- ctx$l[lo]; if (!is.finite(H - L) || H <= L) return(NULL); up <- lo < hi   # the last swing went up when the low came first
  r <- c(0.236, 0.382, 0.5, 0.618, 0.786); lv <- if (up) H - r * (H - L) else L + r * (H - L)
  list(swing = if (up) "up" else "down", high = H, low = L, levels = setNames(lv, paste0(100 * r, "%"))) }
cc_fib_text <- function(f, price) { if (is.null(f)) return("no clear swing")
  k <- names(f$levels)[which.min(abs(f$levels - price))]
  sprintf("last swing %s from %s to %s; retracements %s; price nearest the %s level", f$swing, format(round(f$low, 4)), format(round(f$high, 4)),
          paste(sprintf("%s %s", names(f$levels), format(round(f$levels, 4))), collapse = ", "), k) }

# ---- patterns alive grouped by course topic -------------------------------------------------------------------------------
cc_topic_of_family <- function(f) {
  t <- c(candle_rev = "Japanese candlesticks (Week 1)", candle_run = "Japanese candlesticks (Week 1)", candle_cont = "Japanese candlesticks (Week 1)",
         trend_dow = "Trend lines, support and resistance (Week 1)", level_bounce = "Trend lines, support and resistance (Week 1)", role_reversal = "Trend lines, support and resistance (Week 1)",
         trendline = "Trend lines, support and resistance (Week 1)", trendline_break = "Trend lines, support and resistance (Week 1)", channel = "Trend lines, support and resistance (Week 1)",
         fib = "Fibonacci (Week 2)", harmonic = "Fibonacci (Week 2)", elliott = "Fibonacci (Week 2)")
  ifelse(f %in% names(t), t[f], ifelse(f %in% c("ma_cross_long", "ma_pullback", "ma_stack", "macd_cross", "divergence", "rsi_extreme", "rsi_swing", "rsi_mid", "stoch", "bb_break", "bb_walk", "bb_snap", "squeeze", "atr_trend"),
         "Indicator signals (Week 3)", ifelse(f %in% c("adx", "di_cross", "holy_grail", "pivot", "straddle", "orb"), "ADX / DMI and course strategies (Week 6)", "Chart patterns (Week 2)"))) }
cc_pattern_topics <- function(cur) { if (is.null(cur) || !nrow(cur)) return("no pattern alive at the last candle")
  fam <- cc_catalog$family[match(cur$key, cc_catalog$key)]; tp <- cc_topic_of_family(fam)
  sp <- split(cur$label, tp); paste(sprintf("%s: %s", names(sp), vapply(sp, function(x) paste(unique(x), collapse = ", "), "")), collapse = "; ") }

# ---- Week 3: stochastics and RSI divergence ------------------------------------------------------------------------------
cc_divergence <- function(ctx, look = 30) { d <- ctx$ind; n <- ctx$n; if (n < look + 5 || is.null(d$rsi)) return("not enough candles")
  a <- (n - look + 1):(n - look %/% 2); b <- (n - look %/% 2 + 1):n
  hh <- max(ctx$h[b]) > max(ctx$h[a]); ll <- min(ctx$l[b]) < min(ctx$l[a])
  rh <- max(d$rsi[b], na.rm = TRUE) < max(d$rsi[a], na.rm = TRUE); rl <- min(d$rsi[b], na.rm = TRUE) > min(d$rsi[a], na.rm = TRUE)
  if (hh && rh) "bearish RSI divergence (higher price high, lower RSI high)" else if (ll && rl) "bullish RSI divergence (lower price low, higher RSI low)" else "no RSI divergence in the last 30 candles" }
cc_stoch_text <- function(ctx) { d <- ctx$ind; n <- ctx$n; k <- d$stoch_k[n]; dd <- d$stoch_d[n]; if (!is.finite(k)) return("stochastics: NA")
  sprintf("slow stochastics %%K %.0f, %%D %.0f (%s%s)", k, dd, if (k > 80) "overbought" else if (k < 20) "oversold" else "middle", if (is.finite(dd)) if (k > dd) ", %K above %D" else ", %K below %D" else "") }

# ---- Week 2: types of investment risk for one deal -------------------------------------------------------------------------
# t: list(dir, entry, stop, size_exposure (instrument ccy ~ account), risk_amt, spread, atr, hold_h, balance, news_hits, corr_note, now)
cc_risk_types <- function(t) { g <- function(x, d = NA) if (is.null(x) || !length(x) || !is.finite(x[1])) d else x[1]
  now <- t$now %||% Sys.time(); hold <- g(t$hold_h, 4); end <- now + hold * 3600
  lt <- function(x) as.POSIXlt(x, tz = "Europe/London"); ln <- lt(now); le <- lt(end)
  over22 <- as.Date(le) > as.Date(ln) || (le$hour >= 22 && ln$hour < 22)
  wkend <- ln$wday == 5 && (le$wday != 5 || le$hour >= 22) || ln$wday == 6 || (as.numeric(difftime(end, now, units = "days")) >= (6 - ln$wday))
  sp <- g(t$spread); at <- g(t$atr); stp <- abs(g(t$entry) - g(t$stop)); lev <- g(t$exposure) / g(t$balance)
  row <- function(r, lvl, d) data.frame(risk = r, level = lvl, detail = d, stringsAsFactors = FALSE)
  rbind(
    row("Market (price) risk", if (!is.finite(stp) || !is.finite(at)) "-" else if (stp < 0.5 * at) "high" else "normal",
        if (is.finite(stp) && is.finite(at)) sprintf("stop %.4g away = %.1f ATR; risk %s", stp, stp / at, if (is.finite(g(t$risk_amt))) sprintf("%.2f", t$risk_amt) else "-") else "set the stop"),
    row("Liquidity (spread) risk", if (!is.finite(sp) || !is.finite(at)) "-" else if (sp > 0.2 * at) "high" else "low",
        if (is.finite(sp) && is.finite(at)) sprintf("spread %.4g = %.0f%% of one ATR", sp, 100 * sp / at) else "spread not known"),
    row("Gap / weekend risk", if (isTRUE(wkend)) "high" else "low", if (isTRUE(wkend)) "the holding time reaches the weekend close: the price can gap past the stop" else "closed before the weekend"),
    row("Overnight (financing) risk", if (isTRUE(over22)) "cost" else "none", if (isTRUE(over22)) "held past 22:00 UK: overnight funding is charged on CFDs" else "closed the same day"),
    row("Leverage (margin) risk", if (!is.finite(lev)) "-" else if (lev > 5) "high" else if (lev > 2) "medium" else "low", if (is.finite(lev)) sprintf("exposure %.1f x the balance", lev) else "exposure not known"),
    row("Event (news) risk", if (nzchar(t$news_hits %||% "") && !(t$news_hits %in% c("none", "Morning Sheet not loaded"))) "high" else "low", t$news_hits %||% "-"),
    row("Correlation risk", if (nzchar(t$corr_note %||% "")) "high" else "low", if (nzchar(t$corr_note %||% "")) paste("same risk already open:", t$corr_note) else "no correlated open position")) }
cc_risk_text <- function(r) if (is.null(r)) "" else paste(sprintf("%s %s (%s)", r$risk, r$level, r$detail), collapse = "; ")

# ---- Week 2: relative value (spread between two related markets) ---------------------------------------------------------
cc_spread_z <- function(a, b, n = 100) { if (is.null(a) || is.null(b)) return(NULL)
  m <- merge(data.frame(time = a$time, x = a$close), data.frame(time = b$time, y = b$close), by = "time"); m <- utils::tail(m, n)
  if (nrow(m) < 20 || any(m$x <= 0 | m$y <= 0)) return(NULL); s <- log(m$x / m$y); if (!is.finite(stats::sd(s)) || stats::sd(s) < 1e-12) return(NULL); z <- (utils::tail(s, 1) - mean(s)) / stats::sd(s)
  list(z = z, ratio = utils::tail(m$x / m$y, 1), mean_ratio = exp(mean(s)), n = nrow(m),
       text = sprintf("ratio %.4f vs its %d-candle mean %.4f, z = %+.2f (%s)", utils::tail(m$x / m$y, 1), nrow(m), exp(mean(s)), z,
                      if (z > 2) "this market rich vs the other: relative-value sell" else if (z < -2) "this market cheap vs the other: relative-value buy" else "inside its normal range")) }

# ---- Week 4 psychology / Unit 2 biases from your own trades ---------------------------------------------------------------
cc_bias_checks <- function(tr, events = NULL) { t <- tr[tr$status %in% "CLOSED" & !is.na(tr$exit_ts) & !is.na(tr$entry_ts), , drop = FALSE]
  if (nrow(t) < 2) return(NULL); t <- t[order(t$exit_ts), , drop = FALSE]
  pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est); w <- pl > 0; hold <- as.numeric(difftime(t$exit_ts, t$entry_ts, units = "hours"))
  row <- function(b, flag, d) data.frame(bias = b, flag = flag, detail = d, stringsAsFactors = FALSE)
  disp <- if (any(w) && any(!w)) mean(hold[!w]) > 1.5 * mean(hold[w]) else NA
  sz <- t$size; aw <- sz[-1][utils::head(w, -1)]; al <- sz[-1][!utils::head(w, -1)]
  over <- if (length(aw) && length(al)) mean(aw) > 1.3 * mean(al) else NA
  gap <- as.numeric(difftime(t$entry_ts[-1], t$exit_ts[-nrow(t)], units = "mins")); rev <- sum(gap < 30 & !utils::head(w, -1), na.rm = TRUE)
  widened <- sum(is.finite(t$stop_initial) & is.finite(t$stop_level) & ifelse(t$direction == "BUY", t$stop_level < t$stop_initial, t$stop_level > t$stop_initial))
  rbind(
    row("Disposition effect (cut winners, run losers)", if (is.na(disp)) "-" else if (disp) "yes" else "no",
        if (any(w) && any(!w)) sprintf("losers held %.1f h on average, winners %.1f h", mean(hold[!w]), mean(hold[w])) else "needs both wins and losses"),
    row("Overconfidence (bigger size after a win)", if (is.na(over)) "-" else if (over) "yes" else "no",
        if (length(aw) && length(al)) sprintf("average size after a win %.2f, after a loss %.2f", mean(aw), mean(al)) else "needs trades after both"),
    row("Revenge trading (new deal < 30 min after a loss)", if (rev > 0) "yes" else "no", sprintf("%d time(s)", rev)),
    row("Loss aversion (stop moved further away)", if (widened > 0) "yes" else "no", sprintf("%d trade(s) with the stop widened", widened))) }

# ---- Attitude survey (Introduction): self-assessment on the course's themes. Statements written by the app, not the LAT form. ----
cc_attitude_items <- c(
  "I follow my trading plan even after a loss", "I accept a small loss quickly when the stop is hit", "I do not move my stop further away to avoid a loss",
  "I size every trade from the plan, not from how sure I feel", "I can sit out when there is no set-up", "I do not trade to win back a loss",
  "I take profits at my target instead of closing early from fear", "I review each trade honestly, wins and losses", "I stay calm when a trade goes against me",
  "I trade the higher time-frame trend, not my opinion")
cc_attitude_score <- function(x) { x <- as.numeric(x); if (!length(x) || all(is.na(x))) return(NULL); s <- sum(x, na.rm = TRUE); mx <- 5 * sum(!is.na(x))
  list(score = s, max = mx, pct = round(100 * s / mx), band = if (s / mx >= 0.8) "disciplined" else if (s / mx >= 0.6) "developing" else "at risk: review the psychology lecture",
       weakest = cc_attitude_items[which(x == min(x, na.rm = TRUE))]) }

# ---- the full course coverage map: every topic, where it is in the app ------------------------------------------------------------
cc_course_coverage <- data.frame(stringsAsFactors = FALSE, check.names = FALSE, matrix(ncol = 4, byrow = TRUE, c(
  "Introduction", "Economic Calendar walkthrough", "Plan & Order box 3 (releases, news window); plan check; Claude check 'News'", "full",
  "Introduction", "US Macro Crib Sheet", "Meaning next to each release and scenario; Claude check 'News' (meanings written by the app, not the LAT sheet text)", "partial: course text not in the app",
  "Introduction", "Attitude Survey", "Statistics: Attitude survey **** (self-assessment on the course themes, history kept); Claude check 'Trader state'", "full (app statements)",
  "Introduction; Weeks 9-12", "Backtesting workbook", "12. Backtest & Blotter: by strategy and by pattern; Claude check 'Measured record'", "full",
  "Introduction; Weeks 9-12", "Trade Blotter", "12. Backtest & Blotter: LAT layout Excel export", "full",
  "Week 1 (Step 1)", "Support and resistance (daily / weekly / monthly)", "Market & Patterns: Support, resistance, pivots, Fibonacci ****; Claude check 'Support / resistance'", "full",
  "Week 1 (Step 1)", "Trend lines, channels, countertrend lines", "Pattern matrix (trend lines, channels, breaks); Claude check 'Patterns by course topic'", "full",
  "Week 1 (Step 1)", "Japanese candlesticks", "Pattern matrix candle patterns; Step 1 examples; Claude check 'Patterns by course topic'", "full",
  "Week 2 (Step 2)", "Fibonacci retracements", "Fibonacci levels of the last swing ****; fib patterns; Claude check 'Support / resistance'", "full",
  "Week 2 (Step 2)", "Chart (price) patterns", "Pattern matrix (141 patterns); Step 2-3 examples", "full",
  "Week 2", "Time-frame analysis", "Daily / 4-hour trend on every scenario; Rule of Five ****; Claude check 'Higher time-frame'", "full",
  "Week 2", "Price / time filters", "Setup break filter; applied to scenarios; Claude check 'Breakout filter'", "full",
  "Week 2", "Types of investment risk", "Plan & Order: Investment risks of this deal ****; Claude check 'Investment risks'", "full",
  "Week 2", "Relative value trading", "Related markets: ratio z-score ****; Claude check 'Related markets'", "full",
  "Week 3 (Step 3)", "Moving averages, MACD", "Indicators on the chart; confluence score; Claude check 'Indicators'", "full",
  "Week 3 (Step 3)", "Oscillators: RSI, stochastics, divergence", "Indicator panel; stochastics and RSI divergence ****; Claude check 'Indicators'", "full",
  "Week 3 (Step 3)", "Bollinger bands, OBV", "Indicators; confluence (volatility, volume); Claude check 'Indicators'", "full",
  "Week 4 (Step 4)", "Bull / bear market cycle, Dow Theory", "Dow phase on every scenario; Claude check 'Higher time-frame'", "full",
  "Week 4 (Step 4)", "Options trading and payouts", "Step 4 practice tab (payoff diagrams); not used on Capital.com CFD deals", "reference only: not a CFD chart topic",
  "Week 4", "Trading psychology", "Mood / confidence on the ticket; results by mood; biases ****; reflection ****; losses-in-a-row block", "full",
  "Week 4", "Structured trading plan", "Setup plan rules; plan check on the ticket; Word export", "full",
  "Week 5 (Step 5)", "Volume profile, POC, value area", "Market & Patterns box 3; chart lines; Claude check 'Profile levels'", "full",
  "Week 5 (Step 5)", "Market profile, initial balance", "Market & Patterns box 3 (TPO when no volume; IB from the opening range)", "full",
  "Week 6 (Step 6)", "ADX and DMI", "Indicators; Holy Grail; confluence; Claude check 'ADX / SAR'", "full",
  "Week 6 (Step 6)", "Parabolic SAR", "Positions: SAR trailing stop; Claude check 'ADX / SAR'", "full",
  "Week 6; Weeks 7-8", "Short-term traders' pivot point system", "Course scanner rows; 7 pivot levels ****; Claude check 'Course strategies'", "full",
  "Week 6; Weeks 7-8", "The Holy Grail trade", "Course scanner rows; Claude check 'Course strategies'", "full",
  "Week 6; Weeks 7-8", "Straddle trade (and Morning Straddle)", "Course scanner rows; Step 6 examples; Claude check 'Course strategies'", "full",
  "Weeks 7-8", "Trade Plan Template", "Setup plan rules; Word export 'My Trading Plan'", "full",
  "Week 7", "The Rule of Five (time-frames)", "Market & Patterns: Rule of Five ****; plan check; Claude check 'Rule of Five'", "full",
  "Weeks 7-8", "LAT position sizing", "Ticket size from risk % and stop; plan check", "full",
  "Weeks 9-12", "Assessment trading (Morning Sheet, Trade Sheet)", "Journal & Trade Sheet tab; Morning Sheet in BigQuery", "full",
  "Other course units", "Bond markets, yield curves, futures, broker set-up, career module", "Not part of chart analysis on Capital.com; not built", "not applicable")))
names(cc_course_coverage) <- c("Week", "Topic", "Where in the app", "Status")
