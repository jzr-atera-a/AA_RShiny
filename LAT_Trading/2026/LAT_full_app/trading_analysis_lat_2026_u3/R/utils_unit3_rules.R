# =============================================================================================
# Unit 3 rules engine, written from the London Academy of Trading course material:
#   - The Holy Grail Trade (slides)            - Short Term Trader's Pivot Point System (slides)
#   - Reference Manual: Straddle Trade          - The Rule of Five (Week 7)
#   - How to Develop a Structured Trading Plan  - Trade Plan Template
# Pure functions (no Shiny). They flag conditions that the course rules describe; they never place
# a trade. Where the course says a step is subjective ("slow & corrective" retracement), the result
# says so and leaves that judgement to the trader.
# =============================================================================================

# ---- Pivot points (7 levels) -----------------------------------------------------------------
# PP = (H+L+C)/3 ; S1 = PP-(H-PP) ; R1 = PP-(L-PP) ; S2 = PP-(R1-S1) ; R2 = PP+(R1-S1)
# S3 = L-2(H-PP) ; R3 = H+2(PP-L)      (FX day closes 17:00 New York = 22:00 GMT in the course slides)
u3r_pivots <- function(h, l, c) {
  if (any(!is.finite(c(h, l, c)))) return(c(R3 = NA, R2 = NA, R1 = NA, PP = NA, S1 = NA, S2 = NA, S3 = NA))
  pp <- (h + l + c) / 3; s1 <- pp - (h - pp); r1 <- pp - (l - pp)
  c(R3 = h + 2 * (pp - l), R2 = pp + (r1 - s1), R1 = r1, PP = pp, S1 = s1, S2 = pp - (r1 - s1), S3 = l - 2 * (h - pp))
}

# Session label for each bar. FX: the trading day starts at 22:00 GMT (the previous day's close).
u3r_session_id <- function(date, fx = TRUE, start_hour_utc = 22) {
  if (inherits(date, "Date")) return(date)
  shift <- if (fx && start_hour_utc > 0) (24 - start_hour_utc) * 3600 else 0
  as.Date(format(date + shift, tz = "UTC"), tz = "UTC")
}

# High/low/close of the session before the one containing the last bar (daily data: the previous row).
u3r_prior_session <- function(data, fx = TRUE) {
  if (nrow(data) < 2) return(NULL)
  ids <- u3r_session_id(data$Date, fx)
  cur <- ids[length(ids)]; prev_ids <- ids[ids < cur]
  if (!length(prev_ids)) return(NULL)
  p <- data[ids == max(prev_ids), , drop = FALSE]
  list(high = max(p$High), low = min(p$Low), close = tail(p$Close, 1), session = max(prev_ids))
}

# ---- Regime (the plan rule: ADX > 30 trend, < 20 range, 20-30 no trade) ----------------------------
u3r_regime <- function(data, n = 14, trend_min = 30, range_max = 20) {
  if (!all(c("High", "Low", "Close") %in% names(data)) || nrow(data) < n * 2)
    return(list(ok = FALSE, adx = NA_real_, regime = "Insufficient data", di_pos = NA_real_, di_neg = NA_real_))
  a <- tryCatch(as.data.frame(TTR::ADX(data[, c("High", "Low", "Close")], n = n)), error = function(e) NULL)
  if (is.null(a) || !"ADX" %in% names(a)) return(list(ok = FALSE, adx = NA_real_, regime = "ADX unavailable", di_pos = NA_real_, di_neg = NA_real_))
  l <- tail(a, 1); v <- as.numeric(l$ADX)
  if (is.na(v)) return(list(ok = FALSE, adx = NA_real_, regime = "Warming up", di_pos = NA_real_, di_neg = NA_real_))
  list(ok = TRUE, adx = round(v, 1), di_pos = round(as.numeric(l$DIp), 1), di_neg = round(as.numeric(l$DIn), 1),
       regime = if (v > trend_min) "Trending" else if (v < range_max) "Range-bound" else "Unclear (no trade)")
}

# ---- Holy Grail ---------------------------------------------------------------------------------
# Rules from the slides: trade with the trend; 14-period ADX > 30; a slow and corrective retracement
# to the 20-period EXPONENTIAL moving average, accompanied by a downturn in the ADX; then enter with an
# order beyond the 2-bar high (buy) or 2-bar low (sell). Stop beyond the retracement extreme (or the
# 20 EMA); first target the previous swing extreme, or run the trade with a trailing stop at the 2-bar level.
u3r_holy_grail <- function(data, adx_n = 14, ema_n = 20, adx_min = 30, adx_turn_bars = 2, touch_atr = 0.25, swing_bars = 15) {
  need <- max(adx_n * 2, ema_n) + swing_bars
  if (nrow(data) < need) return(list(status = "NONE", ready = FALSE, watch = FALSE, direction = NA_character_, checks = NULL,
    reason = sprintf("Not enough bars yet (need about %d).", need)))
  a <- as.data.frame(TTR::ADX(data[, c("High", "Low", "Close")], n = adx_n))
  ema <- as.numeric(TTR::EMA(data$Close, n = ema_n)); atr <- as.numeric(TTR::ATR(data[, c("High", "Low", "Close")], n = adx_n)[, "atr"])
  n <- nrow(data); i <- n
  adx <- a$ADX[i]; dip <- a$DIp[i]; din <- a$DIn[i]
  if (any(is.na(c(adx, dip, din, ema[i], atr[i])))) return(list(status = "NONE", ready = FALSE, watch = FALSE, direction = NA_character_, checks = NULL, reason = "Indicators still warming up."))
  long <- dip > din; dir <- if (long) "Long" else "Short"
  adx_trend <- adx > adx_min
  adx_turn <- adx < a$ADX[i - adx_turn_bars]
  w <- (n - swing_bars + 1):n
  swing_ext <- if (long) max(data$High[w]) else min(data$Low[w])           # the momentum extreme before the retracement
  retr_ext  <- if (long) min(data$Low[tail(w, 5)]) else max(data$High[tail(w, 5)]) # the retracement extreme (last 5 bars)
  pulled_back <- abs(swing_ext - data$Close[i]) >= 0.5 * atr[i]
  touch_band <- touch_atr * atr[i]
  at_ema <- data$Low[i] <= ema[i] + touch_band && data$High[i] >= ema[i] - touch_band
  on_trend_side <- if (long) data$Close[i] >= ema[i] - touch_band else data$Close[i] <= ema[i] + touch_band
  # "slow & corrective" is a judgement call in the course; a rough proxy: no single bar of the pullback is impulsive (> 2 x ATR)
  pb_bars <- data[tail(w, 6), ]; impulsive <- any((pb_bars$High - pb_bars$Low) > 2 * atr[i])
  last2 <- tail(data, 2)
  entry <- if (long) max(last2$High) else min(last2$Low)
  stop_swing <- retr_ext; stop_ema <- ema[i]
  checks <- data.frame(
    Rule = c("Trend direction (DI+ vs DI-)", paste0(adx_n, "-period ADX above ", adx_min), "ADX turning down during the retracement",
             "Price has retraced from the recent extreme", paste0("Price at the ", ema_n, "-period EMA"), "Retracement looks slow and corrective (you confirm on the chart)"),
    Met = c(TRUE, adx_trend, adx_turn, pulled_back, at_ema, !impulsive),
    Detail = c(sprintf("DI+ %.1f / DI- %.1f: %s", dip, din, tolower(dir)), sprintf("ADX %.1f", adx),
               sprintf("ADX now %.1f vs %.1f %d bars ago", adx, a$ADX[i - adx_turn_bars], adx_turn_bars),
               sprintf("%.2f ATR from the recent %s", abs(swing_ext - data$Close[i]) / atr[i], if (long) "high" else "low"),
               sprintf("EMA %.5g, last bar range %.5g to %.5g", ema[i], data$Low[i], data$High[i]),
               if (impulsive) "A recent bar is impulsive (over 2 x ATR): the course says avoid impulsive pullbacks" else "No impulsive bar in the last 6 bars (still your judgement)"),
    stringsAsFactors = FALSE)
  ready <- adx_trend && adx_turn && pulled_back && at_ema && !impulsive
  watch <- !ready && adx_trend && (pulled_back || adx_turn)
  reason <- if (!adx_trend) sprintf("ADX is %.1f, not above %d: no Holy Grail trend.", adx, adx_min)
    else if (ready) sprintf("%s set-up: ADX %.1f and falling, price at the %d EMA after a retracement. Entry order %s the 2-bar %s at %.5g.", dir, adx, ema_n, if (long) "above" else "below", if (long) "high" else "low", entry)
    else sprintf("%s trend (ADX %.1f). Waiting for: %s.", dir, adx, paste(tolower(checks$Rule[!checks$Met]), collapse = "; "))
  list(status = if (ready) "READY" else if (watch) "WATCH" else "NONE", ready = ready, watch = watch, direction = dir, reason = reason, checks = checks,
       entry = entry, stop_swing = stop_swing, stop_ema = stop_ema, target = swing_ext, ema = ema[i], adx = adx, trail_note = "Trail the stop at the 2-bar low (sell: 2-bar high), or just beyond the 20 EMA.")
}

# ---- Pivot Point Bounce -------------------------------------------------------------------------
# Course rule (5-minute bars suggested): price moves to touch a pivot; a later candle fails to make a new
# high (Candle 1); a later candle breaks Candle 1's low => SELL, target the next lower pivot, stop above the
# most recent high. Buy is the mirror image. Run on intraday data with the levels from the prior session.
u3r_pivot_bounce <- function(data, levels, lookback = 30, touch_atr = 0.15) {
  n <- nrow(data)
  if (n < 20 || any(!is.finite(levels))) return(list(status = "NONE", ready = FALSE, watch = FALSE, direction = NA_character_, reason = "Not enough intraday bars or no pivot levels."))
  atr <- as.numeric(TTR::ATR(data[, c("High", "Low", "Close")], n = 14)[, "atr"]); tol <- touch_atr * atr[n]
  if (!is.finite(tol)) return(list(status = "NONE", ready = FALSE, watch = FALSE, direction = NA_character_, reason = "ATR still warming up."))
  best <- NULL
  for (t in seq(max(2, n - lookback), n)) for (nm in names(levels)) {
    L <- levels[[nm]]
    if (!(data$Low[t] <= L + tol && data$High[t] >= L - tol)) next
    came_from_below <- data$Close[t - 1] < L; dir <- if (came_from_below) "Short" else "Long"
    c1 <- NA_integer_
    if (t < n) for (k in (t + 1):n) {
      failed <- if (dir == "Short") data$High[k] < data$High[t] else data$Low[k] > data$Low[t]
      if (failed) { c1 <- k; break }
    }
    if (is.na(c1)) next
    brk <- NA_integer_
    if (c1 < n) for (k in (c1 + 1):n) { if (if (dir == "Short") data$Low[k] < data$Low[c1] else data$High[k] > data$High[c1]) { brk <- k; break } }
    cand <- list(level = nm, price = L, dir = dir, touch = t, c1 = c1, brk = brk)
    if (is.null(best) || t > best$touch) best <- cand
  }
  if (is.null(best)) return(list(status = "NONE", ready = FALSE, watch = FALSE, direction = NA_character_, reason = "No pivot touch followed by a Candle 1 in the recent bars."))
  d <- best$dir; entry <- if (d == "Short") data$Low[best$c1] else data$High[best$c1]
  upto <- if (is.na(best$brk)) n else best$brk
  stop <- if (d == "Short") max(data$High[best$touch:upto]) else min(data$Low[best$touch:upto])
  lv <- sort(levels); target <- if (d == "Short") { x <- lv[lv < entry]; if (length(x)) max(x) else NA_real_ } else { x <- lv[lv > entry]; if (length(x)) min(x) else NA_real_ }
  ready <- !is.na(best$brk) && best$brk >= n - 2
  list(status = if (ready) "READY" else if (is.na(best$brk)) "WATCH" else "NONE", ready = ready, watch = is.na(best$brk), direction = d, level = best$level, level_price = best$price,
       entry = entry, stop = stop, target = target, candle1_time = data$Date[best$c1],
       reason = if (ready) sprintf("%s signal at %s: price touched %s (%.5g), Candle 1 failed to extend, then broke its %s. Entry %.5g, stop %.5g, target %s.", d, "now", best$level, best$price, if (d == "Short") "low" else "high", entry, stop, if (is.na(target)) "(no further pivot)" else sprintf("%.5g (next pivot)", target))
         else if (is.na(best$brk)) sprintf("Candle 1 formed after a touch of %s (%.5g). A break of its %s at %.5g would trigger a %s.", best$level, best$price, if (d == "Short") "low" else "high", entry, tolower(d))
         else "Last setup already triggered earlier; waiting for a new touch.")
}

# ---- Straddle (Reference Manual) ----------------------------------------------------------------
# Morning FX straddle: overnight range 22:00-06:00 London. Add the spread to the overnight high (the chart is
# built from the bid). Buy stop = high(ask) + entry buffer; sell stop = low - entry buffer; each leg's stop is the
# other leg's entry; target = risk (RRR 1.0 as standard). Buffers are 1-2 pips. Risk = range + both buffers.
u3r_straddle <- function(high_bid, low_bid, spread = 0, buffer = 1, pip = 0.0001, rrr = 1) {
  if (any(!is.finite(c(high_bid, low_bid))) || high_bid <= low_bid) return(NULL)
  buf <- buffer * pip; h_ask <- high_bid + spread * pip
  buy <- h_ask + buf; sell <- low_bid - buf
  risk <- buy - sell
  list(high_ask = h_ask, low = low_bid, range_pips = (h_ask - low_bid) / pip,
       buy_entry = buy, buy_stop = sell, buy_target = buy + rrr * risk,
       sell_entry = sell, sell_stop = buy, sell_target = sell - rrr * risk,
       risk_pips = risk / pip, rrr = rrr)
}

# Overnight range (22:00-06:00 London time) leading into the morning of `morning_date` (default: latest bar's day).
u3r_overnight_range <- function(data, morning_date = NULL, tz = "Europe/London", from = 22, to = 6) {
  if (!inherits(data$Date, "POSIXct")) return(NULL)
  lt <- as.POSIXlt(data$Date, tz = tz); hr <- lt$hour + lt$min / 60
  if (is.null(morning_date)) morning_date <- as.Date(lt[length(lt)])
  d <- as.Date(lt)
  in_night <- (d == morning_date - 1 & hr >= from) | (d == morning_date & hr < to)
  # a Friday-night / weekend gap simply yields no bars on a non-trading morning
  if (!any(in_night)) return(NULL)
  s <- data[in_night, ]
  list(high = max(s$High), low = min(s$Low), bars = nrow(s), morning = morning_date)
}

# ---- Position size, LAT method for USD-based FX --------------------------------------------------
u3r_trade_size_usd <- function(risk_usd, pip_risk) risk_usd * 10000 / pip_risk
u3r_risk_usd       <- function(trade_size, pip_risk) trade_size * pip_risk / 10000

# ---- Rule of Five (timeframes) -------------------------------------------------------------------
u3r_rule_of_five <- data.frame(
  Minor = c("1 minute", "5 minutes", "30 minutes", "4 hours", "1 day", "1 week"),
  Base  = c("5 minutes", "30 minutes", "2 hours", "1 day", "1 week", "1 month"),
  Major = c("30 minutes", "2-3 hours", "12 hours", "1 week", "1 month", "6 months"), stringsAsFactors = FALSE)
