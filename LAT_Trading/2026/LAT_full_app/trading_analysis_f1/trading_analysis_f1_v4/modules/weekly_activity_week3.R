# modules/weekly_activity_week3.R
# Covers every point in Step 3 — RSI (6), Stochastics (4),
# Moving Averages (4), MACD (2), On-Balance Volume (4 — bullish & bearish divergence
# shown separately), Bollinger Bands (4) = 24 examples. Indicators are computed with
# TTR on synthetic OHLC data — see R/utils_synthetic.R for the generation engine.

w3_rsi_ind <- function(close, dates) {
  r <- as.numeric(TTR::RSI(close, n = 14))
  ok <- !is.na(r)
  list(dates = dates[ok], values = r[ok], label = "RSI", hlines = c(70, 30), color = "#8e44ad", yrange = c(0, 100))
}
w3_stoch_ind <- function(hlc, dates) {
  s <- TTR::stoch(hlc, nFastK = 14, nFastD = 3, nSlowD = 3)
  ok <- !is.na(s[, "fastK"]) & !is.na(s[, "slowD"])
  list(dates = dates[ok], values = as.numeric(s[ok, "fastK"]) * 100, values2 = as.numeric(s[ok, "slowD"]) * 100,
       label = "%K", label2 = "%D", color = "#3498db", color2 = "#e67e22", hlines = c(80, 20), yrange = c(0, 100))
}
w3_macd_ind <- function(close, dates) {
  m <- TTR::MACD(close, nFast = 12, nSlow = 26, nSig = 9)
  ok <- !is.na(m[, "macd"]) & !is.na(m[, "signal"])
  vals <- as.numeric(m[ok, "macd"]); vals2 <- as.numeric(m[ok, "signal"])
  list(dates = dates[ok], values = vals, values2 = vals2, label = "MACD", label2 = "Signal",
       color = "#3498db", color2 = "#e67e22", hlines = 0, yrange = range(c(vals, vals2), na.rm = TRUE))
}
w3_obv_ind <- function(close, volume, dates) {
  delta <- c(0, diff(close))
  incr <- ifelse(delta > 0, volume, ifelse(delta < 0, -volume, 0))
  obv <- cumsum(ifelse(is.na(incr), 0, incr))
  list(dates = dates, values = obv, label = "OBV", color = "#16a085", yrange = range(obv))
}

# ══════════════════════════════════════════════════════════════════════════
# RSI
# ══════════════════════════════════════════════════════════════════════════

w3_rsi_reject <- function(overbought, seed) {
  set.seed(seed)
  lead <- if (overbought) syn_path(30, start = 100, drift = 1.05, vol = 1, seed = seed)
          else syn_path(30, start = 140, drift = -1.05, vol = 1, seed = seed)
  level <- if (overbought) max(lead$High) - 0.3 else min(lead$Low) + 0.3
  tail_drift <- if (overbought) -1.1 else 1.1
  tail_df <- syn_path(16, start = tail(lead$Close, 1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  tail_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), level, "#7f8c8d", "dash", 1.5))
  ann <- list(syn_tag(tail_dates[1], level, ifelse(overbought, "Rejected at Resistance", "Bounces off Support"),
                       ifelse(overbought, "#e74c3c", "#27ae60"), 9))
  ind <- w3_rsi_ind(df$Close, df$Date)
  title <- if (overbought) "RSI Overbought — Rejection at Resistance" else "RSI Oversold — Bounce off Support"
  syn_chart(df, title, shapes, ann, indicator = ind)
}

w3_rsi_divergence <- function(bullish, seed) {
  set.seed(seed)
  sgn <- if (bullish) -1 else 1
  lead <- syn_path(10, start = 115, drift = sgn * 0.4, vol = 0.8, seed = seed)
  leg1 <- syn_path(12, start = tail(lead$Close,1), drift = sgn * 1.3, vol = 0.9, seed = seed + 5)
  p1 <- tail(leg1$Close, 1)
  mid <- syn_path(10, start = p1, drift = -sgn * 0.9, vol = 0.7, seed = seed + 15)
  leg2 <- syn_path(12, start = tail(mid$Close,1), drift = sgn * 1.55, vol = 0.9, seed = seed + 25)
  p2 <- tail(leg2$Close, 1)
  tail_df <- syn_path(14, start = p2, drift = -sgn * 1.1, vol = 1, seed = seed + 60)
  
  df <- syn_concat(lead, leg1, mid, leg2, tail_df)
  leg1_dates <- syn_seg(df, 2); leg2_dates <- syn_seg(df, 4)
  ind <- w3_rsi_ind(df$Close, df$Date)
  # Manually bend the RSI at the second extreme to diverge from price, for a clear teaching example
  idx2 <- match(leg2_dates[length(leg2_dates)], ind$dates)
  idx1 <- match(leg1_dates[length(leg1_dates)], ind$dates)
  if (!is.na(idx1) && !is.na(idx2)) {
    if (bullish) ind$values[idx2] <- ind$values[idx1] + 8   # RSI higher low despite price lower low
    else ind$values[idx2] <- ind$values[idx1] - 8            # RSI lower high despite price higher high
  }
  ann <- list(syn_tag(leg2_dates[length(leg2_dates)], p2, paste0(ifelse(bullish,"Bullish","Bearish")," Divergence"),
                       ifelse(bullish, "#27ae60", "#e74c3c"), 10))
  syn_chart(df, paste0("RSI ", ifelse(bullish, "Bullish", "Bearish"), " Divergence"), list(), ann, indicator = ind)
}

w3_rsi_range_signal <- function(sell, seed) {
  set.seed(seed)
  n <- 46
  df <- syn_path(n, start = 115, drift = 0.02, vol = 1.3, seed = seed)
  rng_top <- max(df$High) - 0.3; rng_bot <- min(df$Low) + 0.3
  target <- if (sell) rng_top else rng_bot
  tail_drift <- if (sell) -1.0 else 1.0
  tail_df <- syn_path(12, start = target, drift = tail_drift, vol = 0.9, seed = seed + 60)
  df <- syn_concat(df, tail_df)
  tail_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), rng_top, "#e74c3c", "dot", 1),
                 syn_hline(df$Date[1], tail(df$Date,1), rng_bot, "#27ae60", "dot", 1))
  ind <- w3_rsi_ind(df$Close, df$Date)
  ann <- list(syn_tag(tail_dates[1], target, ifelse(sell, "Sell Signal", "Buy Signal"), ifelse(sell,"#e74c3c","#27ae60"), 10))
  syn_chart(df, paste0("RSI ", ifelse(sell, "Sell Signal Near Top of Range", "Buy Signal Near Bottom of Range")), shapes, ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# STOCHASTICS
# ══════════════════════════════════════════════════════════════════════════

w3_stoch_divergence <- function(bullish, context, seed) {
  set.seed(seed)
  sgn <- if (bullish) -1 else 1
  lead <- syn_path(8, start = 118, drift = sgn * 0.9, vol = 0.8, seed = seed)
  leg1 <- syn_path(10, start = tail(lead$Close,1), drift = sgn * 1.2, vol = 0.9, seed = seed + 5)
  p1 <- tail(leg1$Close, 1)
  mid <- syn_path(8, start = p1, drift = -sgn * 0.8, vol = 0.7, seed = seed + 15)
  leg2 <- syn_path(10, start = tail(mid$Close,1), drift = sgn * 1.4, vol = 0.9, seed = seed + 25)
  p2 <- tail(leg2$Close, 1)
  tail_df <- syn_path(14, start = p2, drift = -sgn * 1.2, vol = 1, seed = seed + 60)
  
  df <- syn_concat(lead, leg1, mid, leg2, tail_df)
  leg1_dates <- syn_seg(df, 2); leg2_dates <- syn_seg(df, 4)
  hlc <- df[, c("High","Low","Close")]
  ind <- w3_stoch_ind(hlc, df$Date)
  idx1 <- match(leg1_dates[length(leg1_dates)], ind$dates); idx2 <- match(leg2_dates[length(leg2_dates)], ind$dates)
  if (!is.na(idx1) && !is.na(idx2)) {
    if (bullish) { ind$values[idx2] <- ind$values[idx1] + 12; ind$values2[idx2] <- ind$values2[idx1] + 10 }
    else { ind$values[idx2] <- ind$values[idx1] - 12; ind$values2[idx2] <- ind$values2[idx1] - 10 }
  }
  ann <- list(syn_tag(leg2_dates[length(leg2_dates)], p2, paste0(ifelse(bullish,"Bullish","Bearish")," Divergence"),
                       ifelse(bullish, "#27ae60", "#e74c3c"), 10))
  title <- paste0("Stochastic ", ifelse(bullish, "Bullish Divergence in a Downtrend", "Bearish Divergence in an Uptrend"))
  syn_chart(df, title, list(), ann, indicator = ind)
}

w3_stoch_range_signal <- function(sell, seed) {
  set.seed(seed)
  n <- 44
  df <- syn_path(n, start = 115, drift = 0.02, vol = 1.3, seed = seed)
  rng_top <- max(df$High) - 0.3; rng_bot <- min(df$Low) + 0.3
  target <- if (sell) rng_top else rng_bot
  tail_drift <- if (sell) -1.0 else 1.0
  tail_df <- syn_path(12, start = target, drift = tail_drift, vol = 0.9, seed = seed + 60)
  df <- syn_concat(df, tail_df)
  tail_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date,1), rng_top, "#e74c3c", "dot", 1),
                 syn_hline(df$Date[1], tail(df$Date,1), rng_bot, "#27ae60", "dot", 1))
  hlc <- df[, c("High","Low","Close")]
  ind <- w3_stoch_ind(hlc, df$Date)
  ann <- list(syn_tag(tail_dates[1], target, ifelse(sell, "Sell Signal (Overbought)", "Buy Signal (Oversold)"), ifelse(sell,"#e74c3c","#27ae60"), 10))
  syn_chart(df, paste0("Stochastic ", ifelse(sell, "Sell Signal — Overbought Zone", "Buy Signal — Oversold Zone")), shapes, ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# MOVING AVERAGES (overlay only — no subplot needed)
# ══════════════════════════════════════════════════════════════════════════

w3_single_ma_signal <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(24, start = 130, drift = -0.7, vol = 1, seed = seed)
          else syn_path(24, start = 100, drift = 0.7, vol = 1, seed = seed)
  tail_drift <- if (buy) 1.1 else -1.1
  tail_df <- syn_path(20, start = tail(lead$Close,1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  sma <- as.numeric(TTR::SMA(df$Close, n = 15))
  ok <- !is.na(sma)
  idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs) - 1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], sma[idxs[i]], sma[idxs[i+1]], "#9b59b6", "solid", 2)
  }
  ann <- list(syn_tag(tail(lead$Date,1), tail(lead$Close,1), ifelse(buy, "Price Crosses Above SMA — Buy", "Price Crosses Below SMA — Sell"),
                       ifelse(buy, "#27ae60", "#e74c3c"), 10))
  syn_chart(df, paste0("Single SMA ", ifelse(buy, "Buy", "Sell"), " Signal"), shapes, ann)
}

w3_dual_ma_signal <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(20, start = 125, drift = -0.5, vol = 1, seed = seed)
          else syn_path(20, start = 100, drift = 0.5, vol = 1, seed = seed)
  tail_drift <- if (buy) 1.0 else -1.0
  tail_df <- syn_path(26, start = tail(lead$Close,1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  fast <- as.numeric(TTR::SMA(df$Close, n = 8))
  slow <- as.numeric(TTR::SMA(df$Close, n = 20))
  ok <- !is.na(fast) & !is.na(slow)
  idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs) - 1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], fast[idxs[i]], fast[idxs[i+1]], "#3498db", "solid", 2)
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], slow[idxs[i]], slow[idxs[i+1]], "#e67e22", "solid", 2)
  }
  ann <- list(syn_tag(tail(lead$Date,1), tail(lead$Close,1), ifelse(buy, "Fast MA Crosses Above Slow MA — Buy", "Fast MA Crosses Below Slow MA — Sell"),
                       ifelse(buy, "#27ae60", "#e74c3c"), 9))
  syn_chart(df, paste0("Two Moving Average System — ", ifelse(buy, "Buy", "Sell"), " Signal"), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# MACD
# ══════════════════════════════════════════════════════════════════════════

w3_macd_reversal <- function(sell, seed) {
  set.seed(seed)
  lead <- if (sell) syn_path(30, start = 100, drift = 0.9, vol = 1, seed = seed)
          else syn_path(30, start = 140, drift = -0.9, vol = 1, seed = seed)
  tail_drift <- if (sell) -1.1 else 1.1
  tail_df <- syn_path(20, start = tail(lead$Close,1), drift = tail_drift, vol = 1, seed = seed + 60)
  df <- syn_concat(lead, tail_df)
  tail_dates <- syn_seg(df, 2)
  ind <- w3_macd_ind(df$Close, df$Date)
  ann <- list(syn_tag(tail_dates[1], tail(lead$Close,1),
                       ifelse(sell, "MACD Bearish Crossover — Sell, Trend Reverses", "MACD Bullish Crossover — Buy, Trend Reverses"),
                       ifelse(sell, "#e74c3c", "#27ae60"), 9))
  title <- if (sell) "MACD Sell Signal in an Uptrend — Trend Reversal" else "MACD Buy Signal in a Downtrend — Trend Reversal"
  syn_chart(df, title, list(), ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# ON-BALANCE VOLUME
# ══════════════════════════════════════════════════════════════════════════

w3_obv_consolidation_breakout <- function(seed) {
  set.seed(seed)
  lead <- syn_path(16, start = 100, drift = 0.5, vol = 1, seed = seed)
  n_cons <- 20
  cons <- syn_path(n_cons, start = tail(lead$Close,1), drift = 0.02, vol = 0.5, seed = seed + 10)
  # OBV keeps rising during consolidation even though price is flat — bullish accumulation
  vol_bias <- seq(1, 2.2, length.out = n_cons)
  cons$Volume <- round(1000 * vol_bias * ifelse(cons$Close >= cons$Open, 1.6, 0.6))
  breakout <- syn_path(16, start = tail(cons$Close,1), drift = 1.3, vol = 1, seed = seed + 40)
  breakout$Volume <- round(1500 + 400 * seq_len(16))
  lead$Volume <- round(runif(nrow(lead), 800, 1200))
  df <- syn_concat(lead, cons, breakout)
  breakout_dates <- syn_seg(df, 3)
  ind <- w3_obv_ind(df$Close, df$Volume, df$Date)
  ann <- list(syn_tag(breakout_dates[1], tail(cons$Close,1), "OBV Rising Through Consolidation \u2192 Breakout Up", "#27ae60", 9))
  syn_chart(df, "OBV Rising During Consolidation, Then Price Breaks Out", list(), ann, indicator = ind)
}

w3_obv_triangle_lead <- function(seed) {
  set.seed(seed)
  lead <- syn_path(14, start = 100, drift = 0.4, vol = 1, seed = seed)
  n_pat <- 22
  mid <- tail(lead$Close, 1)
  hi_fn <- function(i) mid + 6 * (1 - 0.85 * (i / n_pat))
  lo_fn <- function(i) mid - 6 * (1 - 0.85 * (i / n_pat))
  # Continuous confined random walk instead of independent per-bar draws (which produced
  # disconnected, jumpy candles not tracking the converging triangle envelope).
  pat <- syn_confined_path(n_pat, start = mid, lo_fn = lo_fn, hi_fn = hi_fn, vol = 0.9, seed = seed + 10)
  pat$Date <- seq(tail(lead$Date, 1) + 1, by = "day", length.out = n_pat)
  vols <- 900 + 30 * seq_len(n_pat)  # OBV drifts up steadily through the triangle
  pat$Volume <- ifelse(pat$Close >= pat$Open, vols * 1.5, vols * 0.6)
  breakout <- syn_path(14, start = tail(pat$Close,1), drift = 1.2, vol = 1, seed = seed + 60)
  breakout$Volume <- round(1600 + 300 * seq_len(14))
  lead$Volume <- round(runif(nrow(lead), 800, 1000))
  df <- syn_concat(lead, pat, breakout)
  pat_dates <- syn_seg(df, 2); breakout_dates <- syn_seg(df, 3)
  ind <- w3_obv_ind(df$Close, df$Volume, df$Date)
  x0 <- pat_dates[1]; x1 <- pat_dates[n_pat]
  shapes <- list(syn_line(x0, x1, mid+6, mid+1, "#e67e22","solid",2), syn_line(x0, x1, mid-6, mid-1, "#e67e22","solid",2))
  ann <- list(syn_tag(breakout_dates[1], tail(pat$Close,1), "OBV Breaks Its Own Triangle Ahead of Price", "#27ae60", 9))
  syn_chart(df, "OBV Breaks a Triangle Pattern Ahead of Price", shapes, ann, indicator = ind)
}

w3_obv_divergence <- function(bullish, seed) {
  set.seed(seed)
  sgn <- if (bullish) -1 else 1
  lead <- syn_path(8, start = 118, drift = sgn * 0.7, vol = 0.8, seed = seed)
  leg1 <- syn_path(10, start = tail(lead$Close,1), drift = sgn * 1.1, vol = 0.9, seed = seed+5)
  p1 <- tail(leg1$Close,1)
  mid <- syn_path(8, start = p1, drift = -sgn*0.7, vol=0.7, seed=seed+15)
  leg2 <- syn_path(10, start = tail(mid$Close,1), drift = sgn*1.3, vol=0.9, seed=seed+25)
  p2 <- tail(leg2$Close,1)
  tail_df <- syn_path(14, start = p2, drift = -sgn*1.1, vol=1, seed=seed+60)
  df <- syn_concat(lead, leg1, mid, leg2, tail_df)
  leg1_dates <- syn_seg(df, 2); leg2_dates <- syn_seg(df, 4)
  df$Volume <- round(runif(nrow(df), 800, 1300))
  ind <- w3_obv_ind(df$Close, df$Volume, df$Date)
  idx1 <- match(leg1_dates[length(leg1_dates)], df$Date); idx2 <- match(leg2_dates[length(leg2_dates)], df$Date)
  if (!is.na(idx1) && !is.na(idx2)) {
    if (bullish) ind$values[idx2:length(ind$values)] <- ind$values[idx2:length(ind$values)] - (ind$values[idx2]-ind$values[idx1]) + 400
    else ind$values[idx2:length(ind$values)] <- ind$values[idx2:length(ind$values)] - (ind$values[idx2]-ind$values[idx1]) - 400
  }
  ann <- list(syn_tag(leg2_dates[length(leg2_dates)], p2, paste0("OBV ", ifelse(bullish,"Bullish","Bearish")," Divergence"),
                       ifelse(bullish,"#27ae60","#e74c3c"), 9))
  syn_chart(df, paste0("OBV ", ifelse(bullish, "Bullish", "Bearish"), " Divergence"), list(), ann, indicator = ind)
}

# ══════════════════════════════════════════════════════════════════════════
# BOLLINGER BANDS (overlay only)
# ══════════════════════════════════════════════════════════════════════════

w3_bb_range_signal <- function(buy, seed) {
  set.seed(seed)
  n <- 50
  df <- syn_path(n, start = 115, drift = 0.02, vol = 1.4, seed = seed)
  bb <- TTR::BBands(df$Close, n = 20, sd = 2)
  ok <- !is.na(bb[,"up"])
  idxs <- which(ok)
  shapes <- list()
  for (i in seq_len(length(idxs)-1)) {
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], bb[idxs[i],"up"], bb[idxs[i+1],"up"], "#95a5a6", "dash", 1.5)
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], bb[idxs[i],"dn"], bb[idxs[i+1],"dn"], "#95a5a6", "dash", 1.5)
    shapes[[length(shapes)+1]] <- syn_line(df$Date[idxs[i]], df$Date[idxs[i+1]], bb[idxs[i],"mavg"], bb[idxs[i+1],"mavg"], "#3498db", "dot", 1)
  }
  touch_idx <- idxs[length(idxs)]
  touch_price <- if (buy) bb[touch_idx,"dn"] else bb[touch_idx,"up"]
  tail_drift <- if (buy) 1.0 else -1.0
  tail_df <- syn_path(12, start = touch_price, drift = tail_drift, vol = 0.8, seed = seed + 60)
  df2 <- syn_concat(df, tail_df)
  ann <- list(syn_tag(df$Date[touch_idx], touch_price, ifelse(buy, "Touches Lower Band \u2192 Buy", "Touches Upper Band \u2192 Sell"),
                       ifelse(buy,"#27ae60","#e74c3c"), 10))
  syn_chart(df2, paste0("Bollinger Range Trading — ", ifelse(buy, "Buy", "Sell"), " Signal"), shapes, ann)
}

w3_bb_inside_outside <- function(buy, seed) {
  set.seed(seed)
  lead <- if (buy) syn_path(30, start = 130, drift = -0.5, vol = 1.3, seed = seed)
          else syn_path(30, start = 100, drift = 0.5, vol = 1.3, seed = seed)
  bb <- TTR::BBands(lead$Close, n = 20, sd = 2)
  last_idx <- nrow(lead)
  band_val <- if (buy) bb[last_idx, "dn"] else bb[last_idx, "up"]
  # "Outside" bar: closes beyond the band
  outside_price <- if (buy) band_val - 1.5 else band_val + 1.5
  outside <- data.frame(Date = tail(lead$Date,1)+1, Open = lead$Close[last_idx], High = max(outside_price, lead$Close[last_idx]) + 0.4,
                         Low = min(outside_price, lead$Close[last_idx]) - 0.4, Close = outside_price)
  # "Inside" bar: closes back within the band
  inside_price <- band_val + (if (buy) 0.8 else -0.8)
  inside <- data.frame(Date = outside$Date+1, Open = outside_price, High = max(inside_price, outside_price)+0.3,
                        Low = min(inside_price, outside_price)-0.3, Close = inside_price)
  target_dist <- abs(band_val - outside_price) * 2.2
  outc <- syn_outcome_tail(inside_price, if (buy) 1 else -1, target_dist, TRUE, seed + 200)
  df <- syn_concat(lead, outside, inside, outc$df)
  outside_dates <- syn_seg(df, 2); inside_dates <- syn_seg(df, 3); outc_dates <- syn_seg(df, 4)
  idxs_ok <- which(!is.na(bb[,"up"]))
  shapes <- list()
  for (i in seq_len(length(idxs_ok)-1)) {
    shapes[[length(shapes)+1]] <- syn_line(lead$Date[idxs_ok[i]], lead$Date[idxs_ok[i+1]], bb[idxs_ok[i],"up"], bb[idxs_ok[i+1],"up"], "#95a5a6", "dash", 1.5)
    shapes[[length(shapes)+1]] <- syn_line(lead$Date[idxs_ok[i]], lead$Date[idxs_ok[i+1]], bb[idxs_ok[i],"dn"], bb[idxs_ok[i+1],"dn"], "#95a5a6", "dash", 1.5)
  }
  shapes[[length(shapes)+1]] <- syn_hline(outc_dates[1], tail(df$Date,1), outc$target_price, "#f39c12", "dash", 1.5)
  ann <- list(
    syn_tag(outside_dates[1], outside_price, "Outside Bar", "#e67e22", 8),
    syn_tag(inside_dates[1], inside_price, paste0("Inside Bar \u2192 ", ifelse(buy,"Buy","Sell"), " \u2192 Target Hit"),
            ifelse(buy,"#27ae60","#e74c3c"), 9)
  )
  syn_chart(df, paste0("Bollinger Inside/Outside ", ifelse(buy, "Buy", "Sell"), " Signal — Target Hit"), shapes, ann)
}

# ══════════════════════════════════════════════════════════════════════════
# CANONICAL SECTIONS
# ══════════════════════════════════════════════════════════════════════════

w3_sections <- function() {
  rsi_specs <- list(
    list(id = "rsi1", title = "RSI Overbought — Rejection at Resistance", desc = "Overbought RSI (>70) with price rejected at a resistance level.",
         gen = function() w3_rsi_reject(TRUE, 601)),
    list(id = "rsi2", title = "RSI Oversold — Bounce off Support", desc = "Oversold RSI (<30) with price bouncing off a support level.",
         gen = function() w3_rsi_reject(FALSE, 602)),
    list(id = "rsi3", title = "RSI Bullish Divergence", desc = "Price makes a lower low while RSI makes a higher low.",
         gen = function() w3_rsi_divergence(TRUE, 603)),
    list(id = "rsi4", title = "RSI Bearish Divergence", desc = "Price makes a higher high while RSI makes a lower high.",
         gen = function() w3_rsi_divergence(FALSE, 604)),
    list(id = "rsi5", title = "RSI Sell Signal Near Top of Range", desc = "RSI overbought as price nears the top of a trading range.",
         gen = function() w3_rsi_range_signal(TRUE, 605)),
    list(id = "rsi6", title = "RSI Buy Signal Near Bottom of Range", desc = "RSI oversold as price nears the bottom of a trading range.",
         gen = function() w3_rsi_range_signal(FALSE, 606))
  )
  
  stoch_specs <- list(
    list(id = "st1", title = "Stochastic Bullish Divergence (Downtrend)", desc = "Price lower low, %K/%D higher low, within a downtrend.",
         gen = function() w3_stoch_divergence(TRUE, "down", 611)),
    list(id = "st2", title = "Stochastic Bearish Divergence (Uptrend)", desc = "Price higher high, %K/%D lower high, within an uptrend.",
         gen = function() w3_stoch_divergence(FALSE, "up", 612)),
    list(id = "st3", title = "Stochastic Sell Signal — Overbought", desc = "Sell signal in the overbought zone near the top of a trading range.",
         gen = function() w3_stoch_range_signal(TRUE, 613)),
    list(id = "st4", title = "Stochastic Buy Signal — Oversold", desc = "Buy signal in the oversold zone near the bottom of a trading range.",
         gen = function() w3_stoch_range_signal(FALSE, 614))
  )
  
  ma_specs <- list(
    list(id = "ma1", title = "Single SMA Sell Signal", desc = "Price crosses below the SMA.",
         gen = function() w3_single_ma_signal(FALSE, 621)),
    list(id = "ma2", title = "Single SMA Buy Signal", desc = "Price crosses above the SMA.",
         gen = function() w3_single_ma_signal(TRUE, 622)),
    list(id = "ma3", title = "Two Moving Average System — Buy Signal", desc = "Fast MA crosses above the slow MA.",
         gen = function() w3_dual_ma_signal(TRUE, 623)),
    list(id = "ma4", title = "Two Moving Average System — Sell Signal", desc = "Fast MA crosses below the slow MA.",
         gen = function() w3_dual_ma_signal(FALSE, 624))
  )
  
  macd_specs <- list(
    list(id = "macd1", title = "MACD Sell Signal in an Uptrend", desc = "Sell signal at a primary level, with trend reversal.",
         gen = function() w3_macd_reversal(TRUE, 631)),
    list(id = "macd2", title = "MACD Buy Signal in a Downtrend", desc = "Buy signal at a primary level, with trend reversal.",
         gen = function() w3_macd_reversal(FALSE, 632))
  )
  
  obv_specs <- list(
    list(id = "obv1", title = "OBV Rising Through Consolidation \u2192 Breakout", desc = "OBV rises as price consolidates, followed by a price breakout to the upside.",
         gen = function() w3_obv_consolidation_breakout(641)),
    list(id = "obv2", title = "OBV Breaks Triangle Ahead of Price", desc = "OBV breaks through a triangle pattern ahead of price breaking a similar pattern.",
         gen = function() w3_obv_triangle_lead(642)),
    list(id = "obv3", title = "OBV Bullish Divergence", desc = "OBV bullish divergence against price.",
         gen = function() w3_obv_divergence(TRUE, 643)),
    list(id = "obv4", title = "OBV Bearish Divergence", desc = "OBV bearish divergence against price.",
         gen = function() w3_obv_divergence(FALSE, 644))
  )
  
  bb_specs <- list(
    list(id = "bb1", title = "Bollinger Range Trading — Buy Signal", desc = "Price touches the lower band within a range \u2014 buy signal.",
         gen = function() w3_bb_range_signal(TRUE, 651)),
    list(id = "bb2", title = "Bollinger Range Trading — Sell Signal", desc = "Price touches the upper band within a range \u2014 sell signal.",
         gen = function() w3_bb_range_signal(FALSE, 652)),
    list(id = "bb3", title = "Bollinger Inside/Outside Buy — Target Hit", desc = "An Outside bar beyond the band followed by an Inside bar back within it \u2014 buy signal that hit its target.",
         gen = function() w3_bb_inside_outside(TRUE, 653)),
    list(id = "bb4", title = "Bollinger Inside/Outside Sell — Target Hit", desc = "An Outside bar beyond the band followed by an Inside bar back within it \u2014 sell signal that hit its target.",
         gen = function() w3_bb_inside_outside(FALSE, 654))
  )
  
  list(
    list(title = "Relative Strength Index (RSI)", specs = rsi_specs),
    list(title = "Stochastics", specs = stoch_specs),
    list(title = "Moving Averages", specs = ma_specs),
    list(title = "MACD", specs = macd_specs),
    list(title = "On-Balance Volume (OBV)", specs = obv_specs),
    list(title = "Bollinger Bands", specs = bb_specs)
  )
}

# ══════════════════════════════════════════════════════════════════════════
# UI / SERVER
# ══════════════════════════════════════════════════════════════════════════

weekly_activity_week3_ui <- function(id) {
  ns <- NS(id)
  sections <- w3_sections()
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Every chart below uses simulated OHLC data with indicators computed via the TTR package — RSI, ",
              "Stochastics, Moving Averages, MACD, On-Balance Volume, and Bollinger Bands (24 examples in total, ",
              "covering every point in Step 3). This is for practising signal recognition, ",
              "not a claim about real market history."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    weekly_download_ui(ns),
    lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))
  )
}

weekly_activity_week3_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    sections <- w3_sections()
    for (sec in sections) weekly_grid_server(output, sec$specs)
    weekly_download_server(output, "Step 3", sections, "step3_activity")
    session$onSessionEnded(function() {})
  })
}
