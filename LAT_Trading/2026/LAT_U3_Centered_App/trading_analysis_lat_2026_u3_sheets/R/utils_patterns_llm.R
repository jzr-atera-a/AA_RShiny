# =============================================================================================
# Claude pattern scan for the Trades tab, box 3 ("Price chart & patterns").
#
# The app's own rules (utils_patterns.R) find a fixed set of structures. This file asks Claude to
# read the SAME candles and name every pattern in the full course catalogue (Steps 2 to 6): price
# structures, multi-candle candlesticks, moving averages, momentum, volatility, trend strength and
# the course strategies.
#
# Two rules, both from the student's brief:
#   * MULTI-CANDLE ONLY. Patterns that live on one candle (hammer, doji, shooting star, marubozu)
#     are never asked for and are refused on the way back in: they do not decide a side.
#   * The pattern must still be alive at the RIGHT-HAND EDGE: it has to run up to the last candles,
#     exactly like the app's own filter, so it bears on the trade being planned now.
#
# Indicators are computed HERE, in R, from the same bars and handed to Claude as numbers. Claude
# classifies; it never invents an RSI or a crossover. Every pattern comes back with the level that
# cancels it (the stop side) and its measured target (the limit side), so it feeds the same boxes
# the app's own patterns feed: the chart, the scenarios prompt and the record saved with the trade.
# =============================================================================================

# ---- the full catalogue Claude must work through -------------------------------------------
# key | label | group | bias. Multi-candle only. "trend" bias = it follows the trend, no side of its own.
tr_pat_llm_catalog <- rbind(
  # ---- Step 2 and before: structure the app already knows (kept so Claude confirms or adds to them)
  data.frame(key = c("dow_up", "dow_down", "support", "resistance", "sup_to_res", "res_to_sup",
                     "uptrend_line", "downtrend_line", "broken_uptrend", "broken_downtrend",
                     "ctr_break_up", "ctr_break_down", "bull_channel", "bear_channel",
                     "sym_triangle", "asc_triangle", "desc_triangle", "rising_wedge", "falling_wedge",
                     "bull_flag", "bear_flag", "pennant", "double_top", "double_bottom",
                     "head_shoulders", "inv_head_shoulders", "fib_retracement", "fib_expansion"),
             label = c("Uptrend (Dow Theory)", "Downtrend (Dow Theory)", "Support level", "Resistance level",
                       "Old support now resistance", "Old resistance now support",
                       "Uptrend line", "Downtrend line", "Broken uptrend line", "Broken downtrend line",
                       "Broken countertrend line (uptrend continues)", "Broken countertrend line (downtrend continues)",
                       "Bullish (ascending) channel", "Bearish (descending) channel",
                       "Symmetrical triangle", "Ascending triangle", "Descending triangle", "Rising wedge", "Falling wedge",
                       "Bullish flag", "Bearish flag", "Pennant", "Double top", "Double bottom",
                       "Head & Shoulders", "Inverse Head & Shoulders", "Fibonacci retracement", "Fibonacci 100% expansion"),
             group = c(rep("Trend (Dow Theory)", 2), rep("Support & Resistance", 4), rep("Trend lines", 4),
                       rep("Countertrend lines", 2), rep("Channels", 2), rep("Price patterns", 12), rep("Fibonacci", 2)),
             bias = c("bullish", "bearish", "bullish", "bearish", "bearish", "bullish",
                      "bullish", "bearish", "bearish", "bullish", "bullish", "bearish", "bullish", "bearish",
                      "trend", "bullish", "bearish", "bearish", "bullish", "bullish", "bearish", "trend",
                      "bearish", "bullish", "bearish", "bullish", "trend", "trend"), stringsAsFactors = FALSE),

  # ---- further price structures (Steps 3 to 6)
  data.frame(key = c("triple_top", "triple_bottom", "rectangle_range", "cup_handle", "inv_cup_handle",
                     "rounding_bottom", "rounding_top", "diamond_top", "diamond_bottom",
                     "broadening_top", "broadening_bottom", "island_reversal_top", "island_reversal_bottom",
                     "measured_move_up", "measured_move_down", "abcd_bull", "abcd_bear",
                     "three_drives_up", "three_drives_down", "wolfe_bull", "wolfe_bear",
                     "elliott_impulse_up", "elliott_impulse_down", "elliott_correction",
                     "gap_breakaway_up", "gap_breakaway_down", "gap_runaway_up", "gap_runaway_down",
                     "gap_exhaustion_up", "gap_exhaustion_down", "spike_reversal_top", "spike_reversal_bottom",
                     "failed_breakout_up", "failed_breakout_down", "throwback", "pullback_to_breakout",
                     "round_number", "consolidation_squeeze"),
             label = c("Triple top", "Triple bottom", "Rectangle / trading range", "Cup and handle", "Inverted cup and handle",
                       "Rounding bottom (saucer)", "Rounding top", "Diamond top", "Diamond bottom",
                       "Broadening top (megaphone)", "Broadening bottom", "Island reversal top", "Island reversal bottom",
                       "Measured move up", "Measured move down", "Bullish AB=CD", "Bearish AB=CD",
                       "Three drives up (exhaustion)", "Three drives down (exhaustion)", "Bullish Wolfe wave", "Bearish Wolfe wave",
                       "Elliott impulse up (1-5)", "Elliott impulse down (1-5)", "Elliott ABC correction",
                       "Breakaway gap up", "Breakaway gap down", "Runaway (measuring) gap up", "Runaway (measuring) gap down",
                       "Exhaustion gap up", "Exhaustion gap down", "Spike reversal top", "Spike reversal bottom",
                       "Failed breakout (bull trap)", "Failed breakdown (bear trap)", "Throwback to a broken level",
                       "Pullback to the breakout level", "Round-number level", "Volatility squeeze / coil"),
             group = c(rep("Price patterns", 13), rep("Measured structures", 2), rep("Harmonic", 6),
                       rep("Elliott", 3), rep("Gaps", 6), rep("Reversal", 2), rep("Traps & retests", 4),
                       "Support & Resistance", "Volatility"),
             bias = c("bearish", "bullish", "trend", "bullish", "bearish", "bullish", "bearish", "bearish", "bullish",
                      "bearish", "bullish", "bearish", "bullish", "bullish", "bearish", "bullish", "bearish",
                      "bearish", "bullish", "bullish", "bearish", "bullish", "bearish", "trend",
                      "bullish", "bearish", "bullish", "bearish", "bearish", "bullish", "bearish", "bullish",
                      "bearish", "bullish", "trend", "trend", "trend", "trend"), stringsAsFactors = FALSE),

  # ---- multi-candle candlesticks (single candles are deliberately absent)
  data.frame(key = c("bullish_engulfing", "bearish_engulfing", "piercing", "dark_cloud",
                     "bullish_harami", "bearish_harami", "harami_cross", "morning_star", "evening_star",
                     "three_white_soldiers", "three_black_crows", "tweezer_top", "tweezer_bottom",
                     "rising_three_methods", "falling_three_methods", "three_inside_up", "three_inside_down",
                     "three_outside_up", "three_outside_down", "bullish_kicker", "bearish_kicker",
                     "stick_sandwich", "matching_low", "separating_lines_bull", "separating_lines_bear"),
             label = c("Bullish Engulfing", "Bearish Engulfing", "Piercing Pattern", "Dark Cloud Cover",
                       "Bullish Harami", "Bearish Harami", "Harami Cross", "Morning Star", "Evening Star",
                       "Three White Soldiers", "Three Black Crows", "Tweezer Top", "Tweezer Bottom",
                       "Rising Three Methods", "Falling Three Methods", "Three Inside Up", "Three Inside Down",
                       "Three Outside Up", "Three Outside Down", "Bullish Kicker", "Bearish Kicker",
                       "Stick Sandwich", "Matching Low", "Separating Lines (bullish)", "Separating Lines (bearish)"),
             group = "Candlesticks (multi-candle)",
             bias = c("bullish", "bearish", "bullish", "bearish", "bullish", "bearish", "trend", "bullish", "bearish",
                      "bullish", "bearish", "bearish", "bullish", "bullish", "bearish", "bullish", "bearish",
                      "bullish", "bearish", "bullish", "bearish", "bullish", "bullish", "bullish", "bearish"), stringsAsFactors = FALSE),

  # ---- moving averages (Steps 3 to 6)
  data.frame(key = c("golden_cross", "death_cross", "ma_pullback_bull", "ma_pullback_bear",
                     "ma_stack_bull", "ma_stack_bear", "ma_ribbon_squeeze", "price_ma_cross_up", "price_ma_cross_down",
                     "holy_grail_bull", "holy_grail_bear"),
             label = c("Golden cross (50 over 200)", "Death cross (50 under 200)", "Pullback to the moving average (uptrend)",
                       "Pullback to the moving average (downtrend)", "Moving averages stacked bullish", "Moving averages stacked bearish",
                       "Moving-average ribbon squeeze", "Price crossed above the moving average", "Price crossed below the moving average",
                       "Holy Grail long (ADX above 30, pullback to the 20 EMA)", "Holy Grail short (ADX above 30, pullback to the 20 EMA)"),
             group = "Moving averages",
             bias = c("bullish", "bearish", "bullish", "bearish", "bullish", "bearish", "trend", "bullish", "bearish",
                      "bullish", "bearish"), stringsAsFactors = FALSE),

  # ---- momentum (Steps 3 to 6)
  data.frame(key = c("macd_cross_up", "macd_cross_down", "macd_zero_up", "macd_zero_down",
                     "macd_div_bull", "macd_div_bear", "rsi_overbought", "rsi_oversold",
                     "rsi_div_bull", "rsi_div_bear", "rsi_failure_swing_bull", "rsi_failure_swing_bear",
                     "rsi_50_cross_up", "rsi_50_cross_down", "stoch_cross_up", "stoch_cross_down",
                     "stoch_div_bull", "stoch_div_bear", "momentum_exhaustion"),
             label = c("MACD crossed above its signal", "MACD crossed below its signal", "MACD crossed above zero", "MACD crossed below zero",
                       "Bullish MACD divergence", "Bearish MACD divergence", "RSI overbought", "RSI oversold",
                       "Bullish RSI divergence", "Bearish RSI divergence", "RSI bullish failure swing", "RSI bearish failure swing",
                       "RSI crossed above 50", "RSI crossed below 50", "Stochastic crossed up from oversold", "Stochastic crossed down from overbought",
                       "Bullish stochastic divergence", "Bearish stochastic divergence", "Momentum exhaustion against price"),
             group = "Momentum",
             bias = c("bullish", "bearish", "bullish", "bearish", "bullish", "bearish", "bearish", "bullish",
                      "bullish", "bearish", "bullish", "bearish", "bullish", "bearish", "bullish", "bearish",
                      "bullish", "bearish", "trend"), stringsAsFactors = FALSE),

  # ---- volatility and trend strength (Steps 3 to 6)
  data.frame(key = c("bb_squeeze", "bb_breakout_up", "bb_breakout_down", "bb_walk_up", "bb_walk_down",
                     "bb_reversion_up", "bb_reversion_down", "keltner_squeeze", "atr_expansion", "atr_contraction",
                     "adx_trend_strong", "adx_trend_weak", "di_cross_up", "di_cross_down"),
             label = c("Bollinger squeeze", "Bollinger breakout up", "Bollinger breakout down", "Walking the upper Bollinger band",
                       "Walking the lower Bollinger band", "Snap back from the lower band", "Snap back from the upper band",
                       "Keltner channel squeeze", "Volatility expanding (ATR rising)", "Volatility contracting (ATR falling)",
                       "ADX above 25: the trend is strong", "ADX below 20: no trend, range conditions",
                       "DI+ crossed above DI-", "DI- crossed above DI+"),
             group = c(rep("Volatility", 10), rep("Trend strength", 4)),
             bias = c("trend", "bullish", "bearish", "bullish", "bearish", "bullish", "bearish", "trend", "trend", "trend",
                      "trend", "trend", "bullish", "bearish"), stringsAsFactors = FALSE),

  # ---- the course strategies (Step 6 and the trading plan)
  data.frame(key = c("pivot_bounce_long", "pivot_bounce_short", "overnight_straddle_up", "overnight_straddle_down",
                     "opening_range_up", "opening_range_down"),
             label = c("Pivot point bounce (long)", "Pivot point bounce (short)", "Overnight-range straddle, upper side",
                       "Overnight-range straddle, lower side", "Opening-range breakout up", "Opening-range breakout down"),
             group = "Course strategies",
             bias = c("bullish", "bearish", "bullish", "bearish", "bullish", "bearish"), stringsAsFactors = FALSE))

# single-candle names are refused on the way back in, whatever Claude calls them
tr_pat_llm_single <- c("hammer", "hanging_man", "doji", "long_legged_doji", "dragonfly_doji", "gravestone_doji",
                       "shooting_star", "inverted_hammer", "marubozu_bull", "marubozu_bear", "marubozu",
                       "spinning_top", "belt_hold", "high_wave")

# ---- indicators, computed here so Claude never has to invent a number ------------------------
tr_ind_ema <- function(x, n) { a <- 2 / (n + 1); out <- rep(NA_real_, length(x)); if (length(x) < n) return(out)
  out[n] <- mean(x[1:n]); for (i in (n + 1):length(x)) out[i] <- a * x[i] + (1 - a) * out[i - 1]; out }
tr_ind_sma <- function(x, n) vapply(seq_along(x), function(i) if (i < n) NA_real_ else mean(x[(i - n + 1):i]), 0)
tr_ind_wilder <- function(x, n) { out <- rep(NA_real_, length(x)); if (length(x) < n) return(out)
  out[n] <- mean(x[1:n], na.rm = TRUE); for (i in (n + 1):length(x)) out[i] <- (out[i - 1] * (n - 1) + x[i]) / n; out }
tr_ind_rsi <- function(close, n = 14) {
  d <- c(NA, diff(close)); up <- pmax(d, 0); dn <- pmax(-d, 0)
  au <- tr_ind_wilder(up[-1], n); ad <- tr_ind_wilder(dn[-1], n)
  rs <- au / ifelse(ad == 0, NA, ad); c(NA, ifelse(is.na(rs), 100, 100 - 100 / (1 + rs)))
}
tr_ind_macd <- function(close, f = 12, s = 26, g = 9) {
  ml <- tr_ind_ema(close, f) - tr_ind_ema(close, s)
  ok <- !is.na(ml); sig <- rep(NA_real_, length(ml))
  if (sum(ok) >= g) sig[ok] <- tr_ind_ema(ml[ok], g)
  list(macd = ml, signal = sig, hist = ml - sig)
}
tr_ind_atr <- function(b, n = 14) { pc <- c(b$close[1], utils::head(b$close, -1))
  tr_ind_wilder(pmax(b$high - b$low, abs(b$high - pc), abs(b$low - pc)), n) }
tr_ind_adx <- function(b, n = 14) {
  up <- c(NA, diff(b$high)); dn <- c(NA, -diff(b$low))
  pdm <- ifelse(!is.na(up) & up > dn & up > 0, up, 0); ndm <- ifelse(!is.na(dn) & dn > up & dn > 0, dn, 0)
  pc <- c(b$close[1], utils::head(b$close, -1))
  tr <- pmax(b$high - b$low, abs(b$high - pc), abs(b$low - pc))
  atr <- tr_ind_wilder(tr, n); pdi <- 100 * tr_ind_wilder(pdm, n) / atr; ndi <- 100 * tr_ind_wilder(ndm, n) / atr
  dx <- 100 * abs(pdi - ndi) / (pi_sum <- ifelse((pdi + ndi) == 0, NA, pdi + ndi))
  ok <- !is.na(dx); adx <- rep(NA_real_, length(dx)); if (sum(ok) >= n) adx[ok] <- tr_ind_wilder(dx[ok], n)
  list(adx = adx, di_plus = pdi, di_minus = ndi)
}
tr_ind_stoch <- function(b, n = 14, d = 3) {
  k <- vapply(seq_len(nrow(b)), function(i) { if (i < n) return(NA_real_)
    w <- (i - n + 1):i; hh <- max(b$high[w]); ll <- min(b$low[w])
    if (hh == ll) 50 else 100 * (b$close[i] - ll) / (hh - ll) }, 0)
  list(k = k, d = tr_ind_sma(k, d))
}
# every indicator the catalogue can refer to, as columns on the bars
tr_pat_indicators <- function(b) {
  cl <- b$close; m <- tr_ind_macd(cl); ad <- tr_ind_adx(b); st <- tr_ind_stoch(b)
  sd20 <- vapply(seq_along(cl), function(i) if (i < 20) NA_real_ else stats::sd(cl[(i - 19):i]), 0)
  mid <- tr_ind_sma(cl, 20); atr <- tr_ind_atr(b)
  data.frame(ema20 = tr_ind_ema(cl, 20), ema50 = tr_ind_ema(cl, 50), ema200 = tr_ind_ema(cl, 200),
             sma20 = mid, rsi14 = tr_ind_rsi(cl), macd = m$macd, macd_signal = m$signal, macd_hist = m$hist,
             bb_upper = mid + 2 * sd20, bb_lower = mid - 2 * sd20, bb_width = 4 * sd20,
             kelt_upper = mid + 2 * atr, kelt_lower = mid - 2 * atr,
             adx14 = ad$adx, di_plus = ad$di_plus, di_minus = ad$di_minus,
             stoch_k = st$k, stoch_d = st$d, atr14 = atr)
}
# the indicator block that goes in the prompt: the last `rows` candles, plus where each one stands now
tr_pat_ind_text <- function(b, ind, rows = 40) {
  n <- nrow(b); i0 <- max(1, n - rows + 1); ix <- i0:n
  f <- function(x, d = 1) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
  tab <- paste(c("time_uk,close,ema20,ema50,ema200,rsi14,macd,macd_signal,adx14,di_plus,di_minus,stoch_k,bb_upper,bb_lower",
    sprintf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s", format(b$time[ix], "%d/%m %H:%M", tz = "Europe/London"),
            f(b$close[ix]), f(ind$ema20[ix]), f(ind$ema50[ix]), f(ind$ema200[ix]), f(ind$rsi14[ix], 0),
            f(ind$macd[ix], 2), f(ind$macd_signal[ix], 2), f(ind$adx14[ix], 0), f(ind$di_plus[ix], 0), f(ind$di_minus[ix], 0),
            f(ind$stoch_k[ix], 0), f(ind$bb_upper[ix]), f(ind$bb_lower[ix]))), collapse = "\n")
  L <- function(x) x[n]
  now <- sprintf(paste("At the LAST candle: close %s | EMA20 %s | EMA50 %s | EMA200 %s | RSI14 %s | MACD %s vs signal %s (histogram %s) |",
                       "ADX14 %s (DI+ %s, DI- %s) | Stochastic %%K %s, %%D %s | Bollinger %s to %s (width %s) | Keltner %s to %s | ATR14 %s"),
                 f(L(b$close)), f(L(ind$ema20)), f(L(ind$ema50)), f(L(ind$ema200)), f(L(ind$rsi14), 0),
                 f(L(ind$macd), 2), f(L(ind$macd_signal), 2), f(L(ind$macd_hist), 2), f(L(ind$adx14), 0),
                 f(L(ind$di_plus), 0), f(L(ind$di_minus), 0), f(L(ind$stoch_k), 0), f(L(ind$stoch_d), 0),
                 f(L(ind$bb_upper)), f(L(ind$bb_lower)), f(L(ind$bb_width)), f(L(ind$kelt_upper)), f(L(ind$kelt_lower)), f(L(ind$atr14)))
  paste0(tab, "\n\n", now)
}

# candles for the prompt, numbered so Claude can point at them. Returns the text, how many rows it
# shows, and how many were cut off the front (needed to map a candle number back to a bars row).
tr_pat_bars_text_n <- function(b, max_rows = 150) {
  n <- nrow(b); i0 <- max(1L, n - max_rows + 1L); ix <- i0:n
  list(text = paste(sprintf("%d,%s,%s,%s,%s,%s", seq_along(ix), format(b$time[ix], "%d/%m %H:%M", tz = "Europe/London"),
                            round(b$open[ix], 1), round(b$high[ix], 1), round(b$low[ix], 1), round(b$close[ix], 1)), collapse = "\n"),
       n_rows = length(ix), offset = i0 - 1L)
}

# ---- the prompt ------------------------------------------------------------------------------
tr_pat_llm_cat_text <- function(cat_ = tr_pat_llm_catalog) {
  paste(vapply(split(cat_, factor(cat_$group, levels = unique(cat_$group))), function(g)
    sprintf("%s: %s", g$group[1], paste(sprintf("%s = %s", g$key, g$label), collapse = "; ")), ""), collapse = "\n")
}
tr_pat_llm_prompt <- function(asset, candle_label, bars_text, ind_text, app_summary, atr, n_rows, as_of_uk = "") {
  paste0(
    "You are a technical analyst marking up a price chart for a trading student on an IG spread-bet account. Prices are IG points.\n\n",
    "CHART: ", asset, ", ", candle_label, " candles", if (nzchar(as_of_uk)) paste0(", as it stood at ", as_of_uk, " UK") else "", ".\n",
    "The candles are numbered 1 to ", n_rows, " below, oldest first. Candle ", n_rows, " is the LAST (right-hand edge). ",
    "The median candle range (ATR) is ", round(atr, 1), " points.\n\n",
    "CANDLES (candle_no,time_uk,open,high,low,close):\n", bars_text, "\n\n",
    "INDICATORS, already calculated from these same candles. Use these numbers; never estimate your own:\n", ind_text, "\n\n",
    "The app's own rule-based scan already reported:\n", app_summary, "\n\n",
    "YOUR TASK. Work through the whole catalogue below and report EVERY pattern you can actually see.\n",
    "Catalogue (key = name):\n", tr_pat_llm_cat_text(), "\n\n",
    "RULES, all compulsory:\n",
    "1. MULTI-CANDLE ONLY. Never report a pattern that lives on a single candle (hammer, doji, shooting star, marubozu, spinning top): they do not decide a side. Every pattern you report must span at least 3 candles, except a 2-candle candlestick pattern (engulfing, piercing, dark cloud, harami, tweezer, kicker, separating lines), which is allowed.\n",
    "2. IT MUST STILL BE ALIVE AT THE RIGHT-HAND EDGE. Only report a pattern whose last candle is within the final 10 candles (", max(1, n_rows - 9), " to ", n_rows, "). A pattern that finished long ago does not bear on the trade and must be left out.\n",
    "3. Use only the keys in the catalogue. If what you see is not in it, leave it out.\n",
    "4. Report a pattern once, at its best instance. Do not repeat a key.\n",
    "5. Every pattern needs the level that CANCELS it (`invalid`, the stop side) and its measured TARGET (`target`, the limit side), in IG points, taken from the structure itself (the neckline, the pole, the measured move, the band, the moving average). Use null only when the pattern genuinely has no such level.\n",
    "6. Be honest. `confidence` is 0-100: use under 50 for something forming or arguable, over 80 only for a textbook example. Report nothing you cannot point at in the numbers. An empty list is a valid answer.\n",
    "7. `status` is \"forming\", \"confirmed\" or \"broken\". `from_candle` and `to_candle` are candle numbers from the list above.\n",
    "8. `note` is one plain sentence saying what you see and where, in the student's own words, without jargon stacking.\n\n",
    "Reply with JSON only, no other text:\n",
    '{"patterns":[{"key":"<catalogue key>","status":"forming|confirmed|broken","bias":"bullish|bearish|trend",',
    '"from_candle":0,"to_candle":0,"level":0,"invalid":0,"target":0,"confidence":0,"note":"<one sentence>"}],',
    '"chart_read":"<2 sentences: the trend, where price sits, and what the indicators agree on>"}')
}

# ---- the reply -> pattern objects the chart box already understands --------------------------
# `offset` = how many candles were cut off the front of the prompt (prompt candle 1 = bars row offset + 1)
tr_pat_llm_parse <- function(txt, b, atr = NA, offset = 0L, cat_ = tr_pat_llm_catalog) {
  j <- tryCatch(tr_parse_vision_json(txt), error = function(e) NULL)
  if (is.null(j) || !length(j$patterns)) return(structure(list(), chart_read = if (is.null(j)) "" else tr_or(j$chart_read, "")))
  n <- nrow(b)
  num <- function(x) { v <- suppressWarnings(as.numeric(if (is.null(x) || !length(x)) NA else x[1])); if (length(v)) v else NA_real_ }
  chr <- function(x) if (is.null(x) || !length(x)) "" else as.character(x[1])
  out <- list()
  for (z in j$patterns) {
    key <- chr(z$key); if (!nzchar(key)) next
    if (key %in% tr_pat_llm_single) next                                  # single-candle: refused whatever it is called
    cr <- cat_[cat_$key == key, , drop = FALSE]; if (!nrow(cr)) next      # not in the catalogue: left out
    i0 <- as.integer(num(z$from_candle)) + offset; i1 <- as.integer(num(z$to_candle)) + offset
    if (!is.finite(i0)) i0 <- n; if (!is.finite(i1)) i1 <- n
    i0 <- max(1L, min(n, i0)); i1 <- max(1L, min(n, i1)); if (i1 < i0) { tmp <- i0; i0 <- i1; i1 <- tmp }
    if (i1 < n - 9) next                                                   # must still reach the right-hand edge
    if (i1 - i0 < 1) next                                                  # one candle only: refused
    conf <- num(z$confidence); conf <- if (is.finite(conf)) max(0, min(100, conf)) else 50
    bias <- chr(z$bias); if (!bias %in% c("bullish", "bearish", "trend")) bias <- cr$bias[1]
    st <- chr(z$status); if (!st %in% c("forming", "confirmed", "broken")) st <- "forming"
    lvl <- num(z$level); inv <- num(z$invalid); tgt <- num(z$target)
    lines <- data.frame(x0 = i0, y0 = if (is.finite(lvl)) lvl else b$close[i0], x1 = i1,
                        y1 = if (is.finite(lvl)) lvl else b$close[i1],
                        color = "#7c3aed", dash = "dot", width = 1.6, stringsAsFactors = FALSE)
    out[[length(out) + 1]] <- list(key = key, label = cr$label[1], group = cr$group[1], bias = bias,
      score = as.integer(round(conf)), status = st,
      note = paste0(chr(z$note), if (is.finite(conf)) sprintf(" (Claude, confidence %d%%)", as.integer(round(conf))) else " (Claude)"),
      idx = i0:i1, marks = c(i0, i1), mark_y = c(b$low[i0], b$high[i1]), lines = lines,
      level = lvl, invalid = inv, target = tgt, source = "claude")
  }
  if (length(out)) { o <- order(-vapply(out, function(p) p$score, 0)); out <- out[o]
    out <- out[!duplicated(vapply(out, function(p) p$key, ""))] }
  structure(out, chart_read = tr_or(j$chart_read, ""))
}

# Claude's patterns joined to the app's own: the app's rule-based ones keep their place, Claude's
# are added after them, and a key the app already found is not duplicated.
tr_pat_llm_merge <- function(app_top, llm_top) {
  have <- vapply(app_top, function(p) p$key, "")
  add <- Filter(function(p) !(p$key %in% have), llm_top)
  c(app_top, add)
}
