# R/utils_cc_patterns.R
# Pattern engine of the "T Records C.C" tab. Every row of the pattern matrix (utils_cc_catalog.R) is found by a
# rule written here in R: same candles, same answer every time, no AI. What changed from the original tab's engine
# (R/utils_patterns.R, left untouched):
#   * ATR is Wilder ATR(14) (TTR::ATR), not the window's median range, so thresholds do not move with the window.
#   * Indicators are worked out on the window PLUS a warm-up history (EMA200 needs 200+ candles before the first one
#     shown); a reading without enough warm-up is reported as missing, never guessed.
#   * Every pattern is also found throughout the history, so each one carries its MEASURED record on this market and
#     candle size: how often price reached the target before the stop within your holding time (n shown).
#   * Regime gating: trend rows count only when ADX >= your trend threshold, range rows only when ADX <= your range
#     threshold. Families: one set-up counts once (five squeeze rows do not vote five times).
#   * Candle reversals need a prior move (context); gaps must be real gaps; history is read with no look-ahead
#     (a swing point is used only from the candle that confirmed it).
# Bars: data.frame(time UTC, open, high, low, close[, spread, volume]) oldest first, from Capital.com.

# ---- indicators ---------------------------------------------------------------------------------------------
cc_indicators <- function(b, kc_mult = 1.5) {
  n <- nrow(b); hlc <- cbind(b$high, b$low, b$close); cl <- b$close
  safe <- function(expr, cols = 1) tryCatch(expr, error = function(e) matrix(NA_real_, n, cols))
  ema <- function(k) if (n > k) as.numeric(TTR::EMA(cl, k)) else rep(NA_real_, n)
  atr <- if (n > 15) as.numeric(TTR::ATR(hlc, n = 14)[, "atr"]) else rep(NA_real_, n)
  bb <- if (n > 21) TTR::BBands(cl, n = 20, sd = 2) else matrix(NA_real_, n, 4, dimnames = list(NULL, c("dn", "mavg", "up", "pctB")))
  mc <- if (n > 35) TTR::MACD(cl, 12, 26, 9, maType = "EMA", percent = FALSE) else matrix(NA_real_, n, 2, dimnames = list(NULL, c("macd", "signal")))
  ad <- if (n > 30) TTR::ADX(hlc, n = 14) else matrix(NA_real_, n, 4, dimnames = list(NULL, c("DIp", "DIn", "DX", "ADX")))
  so <- if (n > 20) TTR::stoch(hlc, nFastK = 14, nFastD = 3, nSlowD = 3) else matrix(NA_real_, n, 3, dimnames = list(NULL, c("fastK", "fastD", "slowD")))
  e20 <- ema(20)
  d <- data.frame(atr = atr, ema20 = e20, ema50 = ema(50), ema200 = ema(200),
                  rsi = if (n > 15) as.numeric(TTR::RSI(cl, 14)) else NA_real_,
                  macd = as.numeric(mc[, "macd"]), macd_signal = as.numeric(mc[, "signal"]),
                  bb_dn = as.numeric(bb[, "dn"]), bb_mid = as.numeric(bb[, "mavg"]), bb_up = as.numeric(bb[, "up"]),
                  adx = as.numeric(ad[, "ADX"]), di_p = as.numeric(ad[, "DIp"]), di_n = as.numeric(ad[, "DIn"]),
                  stoch_k = 100 * as.numeric(so[, "fastD"]), stoch_d = 100 * as.numeric(so[, "slowD"]))
  d$macd_hist <- d$macd - d$macd_signal
  d$bb_width <- (d$bb_up - d$bb_dn) / d$bb_mid
  d$kc_up <- e20 + kc_mult * atr; d$kc_dn <- e20 - kc_mult * atr
  d
}

# ---- swing points: zig-zag with a reversal of thr (vector, per candle) ------------------------------------------
# idx = the swing candle, conf = the candle on which the reversal was complete (the swing is known from then on)
cc_zigzag <- function(h, l, thr) {
  n <- length(h); if (n < 3) return(data.frame(idx = integer(0), price = numeric(0), type = character(0), conf = integer(0)))
  I <- integer(0); P <- numeric(0); T <- character(0); C <- integer(0)
  dir <- 0L; hi <- 1L; lo <- 1L
  for (i in 2:n) {
    t <- thr[i]; if (!is.finite(t) || t <= 0) next
    if (dir >= 0L && h[i] > h[hi]) hi <- i
    if (dir <= 0L && l[i] < l[lo]) lo <- i
    if (dir == 0L) {
      if (hi < i && h[hi] - l[i] >= t) { I <- c(I, hi); P <- c(P, h[hi]); T <- c(T, "H"); C <- c(C, i); dir <- -1L; lo <- i }
      else if (lo < i && h[i] - l[lo] >= t) { I <- c(I, lo); P <- c(P, l[lo]); T <- c(T, "L"); C <- c(C, i); dir <- 1L; hi <- i }
    } else if (dir == 1L) {
      if (i > hi && h[hi] - l[i] >= t) { I <- c(I, hi); P <- c(P, h[hi]); T <- c(T, "H"); C <- c(C, i); dir <- -1L; lo <- i }
    } else {
      if (i > lo && h[i] - l[lo] >= t) { I <- c(I, lo); P <- c(P, l[lo]); T <- c(T, "L"); C <- c(C, i); dir <- 1L; hi <- i }
    }
  }
  data.frame(idx = I, price = P, type = T, conf = C, stringsAsFactors = FALSE)
}
# swing points known at candle e, plus the provisional extreme since the last one (prov = TRUE)
cc_pivots_at <- function(zz, e, h, l) {
  p <- zz[zz$conf <= e, , drop = FALSE]; p$prov <- rep(FALSE, nrow(p))
  if (nrow(p)) { last <- p[nrow(p), ]; rng <- if (last$idx < e) (last$idx + 1):e else integer(0)
    if (length(rng)) { if (last$type == "H") { j <- rng[which.min(l[rng])]; p <- rbind(p, data.frame(idx = j, price = l[j], type = "L", conf = e, prov = TRUE)) }
                       else { j <- rng[which.max(h[rng])]; p <- rbind(p, data.frame(idx = j, price = h[j], type = "H", conf = e, prov = TRUE)) } } }
  p
}

# ---- one found pattern --------------------------------------------------------------------------------------
# marks  = the key candles (swing points, touches) drawn as circles; by default the ends of its line segments
# shade0 = where the shaded area starts (a long-lived level is shaded only over its recent part)
cc_occ <- function(key, i0, i1, entry, invalid, target, note = "", level = NA_real_, lines = NULL, conf = 70, status = "forming",
                   atr_default = FALSE, dir = NA_integer_, sig = NULL, marks = NULL, shade0 = NULL) {
  if (is.null(marks) && !is.null(lines) && nrow(lines)) marks <- unique(as.integer(round(c(lines$x0, lines$x1))))
  list(key = key, i0 = as.integer(i0), i1 = as.integer(i1), entry = entry, invalid = invalid, target = target, note = note, level = level,
       lines = lines, conf = conf, status = status, atr_default = atr_default, dir = dir, sig = if (is.null(sig)) paste(key, i0) else sig,
       marks = marks, shade0 = if (is.null(shade0)) as.integer(i0) else as.integer(shade0))
}
cc_seg <- function(x0, y0, x1, y1, color = "#7c3aed", dash = "solid") data.frame(x0 = x0, y0 = y0, x1 = x1, y1 = y1, color = color, dash = dash, stringsAsFactors = FALSE)
cc_dir_of <- function(bias) if (identical(bias, "bullish")) 1L else if (identical(bias, "bearish")) -1L else NA_integer_

# ---- context: everything the detectors share --------------------------------------------------------------
# settings: adx_trend (25), adx_range (20), on_from "22:00", on_to "06:00", or_start "08:00", or_minutes 60, horizon (bars)
cc_ctx <- function(b, minutes = 15, settings = list(), daily = NULL) {
  b <- b[order(b$time), , drop = FALSE]; rownames(b) <- NULL
  n <- nrow(b); ind <- cc_indicators(b)
  a <- ind$atr; fv <- which(is.finite(a) & a > 0)
  if (!length(fv)) { a <- rep(max(stats::median(b$high - b$low, na.rm = TRUE), 1e-9), n) } else { a[seq_len(fv[1] - 1)] <- a[fv[1]]; a[!is.finite(a) | a <= 0] <- a[fv[1]] }
  ind$atr_f <- a
  tm <- as.numeric(b$time); gap <- c(Inf, diff(tm)); sess <- gap > 1.5 * minutes * 60
  s <- function(k, d) if (is.null(settings[[k]]) || (length(settings[[k]]) == 1 && is.na(settings[[k]]))) d else settings[[k]]
  list(b = b, n = n, o = b$open, h = b$high, l = b$low, c = b$close, a = a, ind = ind, minutes = minutes, sess = sess,
       uk = as.POSIXlt(b$time, tz = "Europe/London"), daily = daily,
       zz = cc_zigzag(b$high, b$low, 1.5 * a), zz1 = cc_zigzag(b$high, b$low, 1.0 * a),
       adx_trend = s("adx_trend", 25), adx_range = s("adx_range", 20), on_from = s("on_from", "22:00"), on_to = s("on_to", "06:00"),
       or_start = s("or_start", "08:00"), or_minutes = s("or_minutes", 60), horizon = s("horizon", 40), warm = s("warm", 1L),
       v2 = isTRUE(settings$v2))   # v2 = the improved rules (Pattern Matrix); the Trading Desk keeps v1 until switched
}
cc_lag <- function(x, k = 1) if (k <= 0) x else c(rep(NA, k), utils::head(x, -k))
cc_fill_dflt <- function(dir, entry, invalid, target, a) {   # ATR template when a pattern has no structure for a level
  atr_d <- FALSE
  if (!is.finite(invalid)) { invalid <- entry - dir * 1.5 * a; atr_d <- TRUE }
  if (!is.finite(target)) target <- entry + dir * 2 * abs(entry - invalid)
  list(invalid = invalid, target = target, atr_default = atr_d)
}
# nearest swing level beyond the entry in the trade's direction, known before candle i (else NA)
cc_next_level <- function(ctx, i, entry, dir, max_atr = 8) {
  p <- ctx$zz[ctx$zz$conf < i & ctx$zz$idx >= i - 300, , drop = FALSE]; a <- ctx$a[i]
  v <- if (dir > 0) p$price[p$type == "H" & p$price > entry + 0.5 * a] else p$price[p$type == "L" & p$price < entry - 0.5 * a]
  if (!length(v)) return(NA_real_); v <- if (dir > 0) min(v) else max(v)
  if (abs(v - entry) > max_atr * a) NA_real_ else v
}

# =========================================================================================================
# VECTOR DETECTORS: one pass over all candles; i1 = the candle the pattern completes on
# =========================================================================================================
cc_det_candles <- function(ctx) {
  o <- ctx$o; h <- ctx$h; l <- ctx$l; c <- ctx$c; a <- ctx$a; n <- ctx$n
  bd <- abs(c - o); rg <- pmax(h - l, 1e-12); up <- c > o; dn <- c < o
  L <- function(x, k = 1) cc_lag(x, k)
  pt <- (L(c, 1) - L(c, 11)) / L(a, 1)                 # prior trend at candle i (move before the pattern)
  pt2 <- L(pt, 1); pt3 <- L(pt, 2)                      # prior trend before a 2- / 3-candle pattern
  big1 <- L(bd) >= 0.6 * L(a)
  out <- list()
  add <- function(key, sel, k, dir, note) {               # k = number of candles in the pattern
    ix <- which(sel %in% TRUE); for (i in ix) { if (i < 12) next
      rng <- (i - k + 1):i; ent <- c[i]
      inv <- if (is.na(dir)) NA_real_ else if (dir > 0) min(l[rng]) - 0.1 * a[i] else max(h[rng]) + 0.1 * a[i]
      tg <- if (is.na(dir)) NA_real_ else cc_next_level(ctx, i, ent, dir)
      if (!is.na(dir)) { f <- cc_fill_dflt(dir, ent, inv, tg, a[i]); inv <- f$invalid; tg <- f$target }
      out[[length(out) + 1]] <<- cc_occ(key, i - k + 1, i, ent, inv, tg, note, dir = dir, conf = 60, marks = if (isTRUE(ctx$v2)) rng else NULL,
        lines = cc_seg(i - k + 1, if (is.na(dir) || dir > 0) min(l[rng]) else max(h[rng]), i, if (is.na(dir) || dir > 0) min(l[rng]) else max(h[rng]), "#7c3aed", "dot")) } }
  # 2-candle
  eng_b <- L(dn) & up & o <= L(c) & c >= L(o) & bd > L(bd)
  eng_s <- L(up) & dn & o >= L(c) & c <= L(o) & bd > L(bd)
  add("bull_engulfing", eng_b & pt2 <= -1, 2, 1L, "Up candle engulfs the down candle after a fall")
  add("bear_engulfing", eng_s & pt2 >= 1, 2, -1L, "Down candle engulfs the up candle after a rise")
  mid1 <- (L(o) + L(c)) / 2
  add("piercing", L(dn) & big1 & up & o <= L(c) & c > mid1 & c < L(o) & pt2 <= -1, 2, 1L, "Up candle closes above the midpoint of the down candle")
  add("dark_cloud", L(up) & big1 & dn & o >= L(c) & c < mid1 & c > L(o) & pt2 >= 1, 2, -1L, "Down candle closes below the midpoint of the up candle")
  har_b <- L(dn) & big1 & up & bd <= 0.5 * L(bd) & pmax(o, c) <= L(o) & pmin(o, c) >= L(c)
  har_s <- L(up) & big1 & dn & bd <= 0.5 * L(bd) & pmax(o, c) <= L(c) & pmin(o, c) >= L(o)
  add("bull_harami", har_b & pt2 <= -1, 2, 1L, "Small up candle inside a large down candle")
  add("bear_harami", har_s & pt2 >= 1, 2, -1L, "Small down candle inside a large up candle")
  inside_body <- pmax(o, c) <= pmax(L(o), L(c)) & pmin(o, c) >= pmin(L(o), L(c))
  add("harami_cross", big1 & bd <= 0.1 * rg & inside_body & (abs(pt2) >= 1), 2, NA_integer_, "Doji inside the previous large candle: indecision")
  add("tweezer_top", L(up) & dn & abs(h - L(h)) <= 0.1 * a & h >= zoo::rollapplyr(h, 10, max, fill = NA) - 1e-9 & pt2 >= 1, 2, -1L, "Two candles with the same high at a 10-candle high")
  add("tweezer_bottom", L(dn) & up & abs(l - L(l)) <= 0.1 * a & l <= zoo::rollapplyr(l, 10, min, fill = NA) + 1e-9 & pt2 <= -1, 2, 1L, "Two candles with the same low at a 10-candle low")
  add("bull_kicker", L(dn) & up & bd >= 0.5 * a & o >= L(o) & l >= L(o), 2, 1L, "Up candle opens above the prior open with no overlap")
  add("bear_kicker", L(up) & dn & bd >= 0.5 * a & o <= L(o) & h <= L(o), 2, -1L, "Down candle opens below the prior open with no overlap")
  add("matching_low", L(dn) & dn & abs(c - L(c)) <= 0.05 * a & pt2 <= -1, 2, 1L, "Two down candles closing at the same price")
  add("sep_lines_bull", L(dn) & up & bd >= 0.5 * a & abs(o - L(o)) <= 0.1 * a & pt2 >= 1, 2, 1L, "Up candle opens where the down candle opened, in an uptrend")
  add("sep_lines_bear", L(up) & dn & bd >= 0.5 * a & abs(o - L(o)) <= 0.1 * a & pt2 <= -1, 2, -1L, "Down candle opens where the up candle opened, in a downtrend")
  # 3-candle
  big2 <- L(bd, 2) >= 0.6 * L(a, 2); mid2 <- (L(o, 2) + L(c, 2)) / 2
  add("morning_star", L(dn, 2) & big2 & L(bd) <= 0.3 * L(bd, 2) & pmax(L(o), L(c)) <= L(c, 2) + 0.1 * a & up & c > mid2 & pt3 <= -1, 3, 1L, "Down candle, small candle below it, up candle back into the first body")
  add("evening_star", L(up, 2) & big2 & L(bd) <= 0.3 * L(bd, 2) & pmin(L(o), L(c)) >= L(c, 2) - 0.1 * a & dn & c < mid2 & pt3 >= 1, 3, -1L, "Up candle, small candle above it, down candle back into the first body")
  sold <- function(u, k) { x <- u & bd >= 0.5 * a; if (k == 0) x else L(x, k) }
  uw <- (h - pmax(o, c)) <= 0.3 * rg; lw <- (pmin(o, c) - l) <= 0.3 * rg
  add("three_white_soldiers", sold(up, 2) & sold(up, 1) & sold(up, 0) & L(c) > L(c, 2) & c > L(c) & L(o) >= L(o, 2) & L(o) <= L(c, 2) & o >= L(o) & o <= L(c) &
        uw & L(uw) & L(uw, 2) & pt3 <= 1, 3, 1L, "Three strong up candles, each opening inside the last body")
  add("three_black_crows", sold(dn, 2) & sold(dn, 1) & sold(dn, 0) & L(c) < L(c, 2) & c < L(c) & L(o) <= L(o, 2) & L(o) >= L(c, 2) & o <= L(o) & o >= L(c) &
        lw & L(lw) & L(lw, 2) & pt3 >= -1, 3, -1L, "Three strong down candles, each opening inside the last body")
  add("three_inside_up", L(har_b) & c > L(o, 2) & L(pt2) <= -1, 3, 1L, "Bullish harami, then a close above the first candle's open")
  add("three_inside_down", L(har_s) & c < L(o, 2) & L(pt2) >= 1, 3, -1L, "Bearish harami, then a close below the first candle's open")
  add("three_outside_up", L(eng_b) & c > L(c) & L(pt2) <= -1, 3, 1L, "Bullish engulfing, then a higher close")
  add("three_outside_down", L(eng_s) & c < L(c) & L(pt2) >= 1, 3, -1L, "Bearish engulfing, then a lower close")
  add("stick_sandwich", L(dn, 2) & L(up) & dn & abs(c - L(c, 2)) <= 0.1 * a & pt3 <= -1, 3, 1L, "Down, up, down with the two down closes level")
  # 5-candle continuation
  ins <- function(k) L(h, k) <= L(h, 4) & L(l, k) >= L(l, 4) & L(bd, k) <= 0.5 * L(bd, 4)
  pt5 <- L(pt, 4)
  add("rising_three", L(up, 4) & L(bd, 4) >= 1 * L(a, 4) & ins(3) & ins(2) & ins(1) & (L(dn, 3) + L(dn, 2) + L(dn, 1) >= 2) & up & c > L(c, 4) & pt5 > -1, 5, 1L, "Long up candle, three small ones inside it, then a higher close")
  add("falling_three", L(dn, 4) & L(bd, 4) >= 1 * L(a, 4) & ins(3) & ins(2) & ins(1) & (L(up, 3) + L(up, 2) + L(up, 1) >= 2) & dn & c < L(c, 4) & pt5 < 1, 5, -1L, "Long down candle, three small ones inside it, then a lower close")
  out
}

cc_det_gaps <- function(ctx) {
  o <- ctx$o; h <- ctx$h; l <- ctx$l; c <- ctx$c; a <- ctx$a; n <- ctx$n; out <- list()
  if (n < 20) return(out)
  gu <- c(FALSE, l[-1] > h[-n] | (ctx$sess[-1] & o[-1] > h[-n]))
  gd <- c(FALSE, h[-1] < l[-n] | (ctx$sess[-1] & o[-1] < l[-n]))
  for (g in which(gu | gd)) { if (g < 17) next
    up <- gu[g]; edge <- if (up) h[g - 1] else l[g - 1]; base <- (g - 15):(g - 1)
    move <- (c[g - 1] - c[g - 16]) / a[g - 1] * (if (up) 1 else -1)
    nxt <- if (g < n) (g + 1):min(n, g + 3) else integer(0)
    filled_at <- if (length(nxt)) nxt[which(if (up) c[nxt] < edge else c[nxt] > edge)] else integer(0)
    filled <- length(filled_at) > 0
    dir <- if (up) 1L else -1L; s <- if (up) "up" else "down"
    if (!filled && length(nxt) == 3 && diff(range(c(h[base], l[base]))) <= 3 * a[g] && (if (up) o[g] > max(h[base]) else o[g] < min(l[base]))) {
      i1 <- g + 3; ent <- c[i1]; inv <- edge - dir * 0.2 * a[g]; f <- cc_fill_dflt(dir, ent, inv, NA, a[i1])
      out[[length(out) + 1]] <- cc_occ(paste0("breakaway_gap_", s), g - 15, i1, ent, f$invalid, f$target, "Gap out of a tight base, not filled", level = edge, dir = dir,
                                       lines = cc_seg(g - 1, edge, i1, edge, "#0ea5e9", "dash")) }
    if (!filled && length(nxt) == 3 && move >= 3 && move < 5) {
      i1 <- g + 3; ent <- c[i1]; inv <- edge - dir * 0.2 * a[g]; tg <- ent + dir * abs(c[g - 1] - c[g - 16])
      out[[length(out) + 1]] <- cc_occ(paste0("runaway_gap_", s), g - 15, i1, ent, inv, tg, "Gap in the middle of an established move, not filled", level = edge, dir = dir,
                                       lines = cc_seg(g - 1, edge, i1, edge, "#0ea5e9", "dash")) }
    if (filled && move >= 5) {
      i1 <- filled_at[1]; d2 <- -dir; ent <- c[i1]; inv <- (if (up) max(h[g:i1]) else min(l[g:i1])) - d2 * 0.2 * a[i1]; f <- cc_fill_dflt(d2, ent, inv, NA, a[i1])
      out[[length(out) + 1]] <- cc_occ(paste0("exhaustion_gap_", s), g - 15, i1, ent, f$invalid, f$target, "Gap at the end of a long move, filled within 3 candles", level = edge, dir = d2,
                                       lines = cc_seg(g - 1, edge, i1, edge, "#0ea5e9", "dash")) }
  }
  # islands: a gap one way, 1-10 candles cut off, a gap the other way
  for (i in which(gd)) { for (j in max(2, i - 10):(i - 1)) if (gu[j]) { cl <- j:(i - 1); lo <- min(l[cl])
      if (lo > h[j - 1] && lo > h[i]) { ent <- c[i]; inv <- max(h[cl]) + 0.2 * a[i]; f <- cc_fill_dflt(-1L, ent, inv, NA, a[i])
        out[[length(out) + 1]] <- cc_occ("island_top", j, i, ent, f$invalid, f$target, sprintf("%d candle(s) cut off above two gaps", length(cl)), dir = -1L,
                                         lines = cc_seg(j, lo, i - 1, lo, "#0ea5e9", "dash")); break } } }
  for (i in which(gu)) { for (j in max(2, i - 10):(i - 1)) if (gd[j]) { cl <- j:(i - 1); hi <- max(h[cl])
      if (hi < l[j - 1] && hi < l[i]) { ent <- c[i]; inv <- min(l[cl]) - 0.2 * a[i]; f <- cc_fill_dflt(1L, ent, inv, NA, a[i])
        out[[length(out) + 1]] <- cc_occ("island_bottom", j, i, ent, f$invalid, f$target, sprintf("%d candle(s) cut off below two gaps", length(cl)), dir = 1L,
                                         lines = cc_seg(j, hi, i - 1, hi, "#0ea5e9", "dash")); break } } }
  out
}

cc_det_spikes <- function(ctx) {
  h <- ctx$h; l <- ctx$l; c <- ctx$c; a <- ctx$a; n <- ctx$n; out <- list(); if (n < 25) return(out)
  for (i in 23:n) { k <- i - 1; prev <- (k - 20):(k - 1); rg <- h[k] - l[k]; m <- (h[k] + l[k]) / 2
    if (h[k] >= max(h[prev]) + 0.5 * a[k] && rg >= 1.5 * a[k] && c[i] < m) { ent <- c[i]; f <- cc_fill_dflt(-1L, ent, h[k] + 0.2 * a[i], NA, a[i])
      out[[length(out) + 1]] <- cc_occ("spike_top", k, i, ent, f$invalid, f$target, "Sharp spike to a new high, reversed on the next candle", level = h[k], dir = -1L,
                                       lines = cc_seg(k, h[k], i, h[k], "#ef4444", "dot")) }
    if (l[k] <= min(l[prev]) - 0.5 * a[k] && rg >= 1.5 * a[k] && c[i] > m) { ent <- c[i]; f <- cc_fill_dflt(1L, ent, l[k] - 0.2 * a[i], NA, a[i])
      out[[length(out) + 1]] <- cc_occ("spike_bottom", k, i, ent, f$invalid, f$target, "Sharp spike to a new low, reversed on the next candle", level = l[k], dir = 1L,
                                       lines = cc_seg(k, l[k], i, l[k], "#16a34a", "dot")) } }
  out
}

cc_det_indicators <- function(ctx) {
  d <- ctx$ind; c <- ctx$c; h <- ctx$h; l <- ctx$l; o <- ctx$o; a <- ctx$a; n <- ctx$n; L <- cc_lag; out <- list()
  xup <- function(x, y) !is.na(x) & !is.na(L(x)) & !is.na(y) & !is.na(L(y)) & L(x) <= L(y) & x > y
  emit <- function(key, sel, dir, note, inv_fun = NULL, tg_fun = NULL, i0_back = 1, first_of_run = FALSE) {
    s0 <- sel %in% TRUE; s <- s0; if (first_of_run) s <- s & !(L(s) %in% TRUE)
    # v2: a state (squeeze, stacked averages, ...) still true on the last candle is reported there, from the start of its run
    if (isTRUE(ctx$v2) && first_of_run && isTRUE(s0[n]) && identical(cc_catalog$kind[match(key, cc_catalog$key)], "state")) {
      st0 <- max(which(s & seq_len(n) <= n)); ent <- c[n]; dr <- dir; inv <- NA_real_; tg <- NA_real_; ad <- FALSE
      if (!is.na(dr)) { f <- cc_fill_dflt(dr, ent, if (is.null(inv_fun)) NA_real_ else inv_fun(n), if (is.null(tg_fun)) NA_real_ else tg_fun(n), a[n]); inv <- f$invalid; tg <- f$target; ad <- f$atr_default }
      out[[length(out) + 1]] <<- cc_occ(key, st0, n, ent, inv, tg, paste0(note, sprintf(" (since %d candles)", n - st0 + 1)), dir = dr, atr_default = ad, conf = 70, sig = paste(key, "run", st0), marks = c(st0, n)) }
    for (i in which(s)) { if (i < 30) next
      ent <- c[i]; inv <- if (is.null(inv_fun)) NA_real_ else inv_fun(i); tg <- if (is.null(tg_fun)) NA_real_ else tg_fun(i)
      if (!is.na(dir)) { f <- cc_fill_dflt(dir, ent, inv, tg, a[i]); inv <- f$invalid; tg <- f$target; ad <- f$atr_default } else ad <- FALSE
      out[[length(out) + 1]] <<- cc_occ(key, max(1, i - i0_back), i, ent, inv, tg, note, dir = dir, atr_default = ad, conf = 70) } }
  e20 <- d$ema20; e50 <- d$ema50; e200 <- d$ema200
  emit("golden_cross", xup(e50, e200), 1L, "EMA50 crossed above EMA200")
  emit("death_cross", xup(e200, e50), -1L, "EMA50 crossed below EMA200")
  up_tr <- !is.na(e50) & c > e50 & e50 > L(e50, 10); dn_tr <- !is.na(e50) & c < e50 & e50 < L(e50, 10)
  touch_up <- (l <= e20 + 0.2 * a & c > e20) | (l <= e50 + 0.2 * a & c > e50)
  touch_dn <- (h >= e20 - 0.2 * a & c < e20) | (h >= e50 - 0.2 * a & c < e50)
  emit("ma_pullback_up", up_tr & touch_up, 1L, "Pullback to EMA20/50 holding in an uptrend", function(i) min(l[i], e50[i]) - 0.5 * a[i], function(i) cc_next_level(ctx, i, c[i], 1), first_of_run = TRUE)
  emit("ma_pullback_down", dn_tr & touch_dn, -1L, "Pullback to EMA20/50 holding in a downtrend", function(i) max(h[i], e50[i]) + 0.5 * a[i], function(i) cc_next_level(ctx, i, c[i], -1), first_of_run = TRUE)
  stk_b <- !is.na(e200) & e20 > e50 & e50 > e200 & e20 > L(e20, 5) & e50 > L(e50, 5) & e200 > L(e200, 5)
  stk_s <- !is.na(e200) & e20 < e50 & e50 < e200 & e20 < L(e20, 5) & e50 < L(e50, 5) & e200 < L(e200, 5)
  emit("ma_stack_bull", stk_b, 1L, "EMA20 > EMA50 > EMA200, all rising", first_of_run = TRUE)
  emit("ma_stack_bear", stk_s, -1L, "EMA20 < EMA50 < EMA200, all falling", first_of_run = TRUE)
  rib <- !is.na(e200) & (pmax(e20, e50, e200) - pmin(e20, e50, e200)) <= a & abs(e50 - L(e50, 10)) < 0.5 * a
  emit("ma_ribbon_squeeze", rib, NA_integer_, "EMA20/50/200 bunched and flat", first_of_run = TRUE)
  emit("price_x_ma_up", xup(c, e20) | xup(c, e50), 1L, "Close crossed above EMA20/50", function(i) min(l[max(1, i - 2):i]) - 0.2 * a[i])
  emit("price_x_ma_down", xup(e20, c) | xup(e50, c), -1L, "Close crossed below EMA20/50", function(i) max(h[max(1, i - 2):i]) + 0.2 * a[i])
  hg <- !is.na(d$adx) & d$adx >= 30 & d$adx > L(d$adx, 3)
  emit("holy_grail_long", hg & d$di_p > d$di_n & l <= e20 + 0.1 * a & c > e20, 1L, "ADX >= 30 rising, DI+ leads, pullback to EMA20 holding (entry above this candle's high)",
       function(i) l[i] - 0.2 * a[i], function(i) { v <- max(h[max(1, i - 20):i]); if (v > c[i] + 0.3 * a[i]) v else NA }, first_of_run = TRUE)
  emit("holy_grail_short", hg & d$di_n > d$di_p & h >= e20 - 0.1 * a & c < e20, -1L, "ADX >= 30 rising, DI- leads, pullback to EMA20 holding (entry below this candle's low)",
       function(i) h[i] + 0.2 * a[i], function(i) { v <- min(l[max(1, i - 20):i]); if (v < c[i] - 0.3 * a[i]) v else NA }, first_of_run = TRUE)
  emit("macd_x_signal_up", xup(d$macd, d$macd_signal), 1L, "MACD crossed above its signal")
  emit("macd_x_signal_down", xup(d$macd_signal, d$macd), -1L, "MACD crossed below its signal")
  z <- rep(0, n)
  emit("macd_x_zero_up", xup(d$macd, z), 1L, "MACD crossed above zero")
  emit("macd_x_zero_down", xup(z, d$macd), -1L, "MACD crossed below zero")
  emit("rsi_ob", d$rsi > 70, -1L, "RSI(14) above 70", first_of_run = TRUE)
  emit("rsi_os", d$rsi < 30, 1L, "RSI(14) below 30", first_of_run = TRUE)
  emit("rsi_x50_up", xup(d$rsi, rep(50, n)), 1L, "RSI crossed above 50")
  emit("rsi_x50_down", xup(rep(50, n), d$rsi), -1L, "RSI crossed below 50")
  emit("stoch_x_up_os", xup(d$stoch_k, d$stoch_d) & L(d$stoch_k) < 20 & L(d$stoch_d) < 20, 1L, "Slow %K crossed above %D below 20")
  emit("stoch_x_down_ob", xup(d$stoch_d, d$stoch_k) & L(d$stoch_k) > 80 & L(d$stoch_d) > 80, -1L, "Slow %K crossed below %D above 80")
  bbw <- d$bb_width; bbmin <- zoo::rollapplyr(bbw, 100, function(x) if (all(is.na(x))) NA else min(x, na.rm = TRUE), fill = NA, partial = TRUE)
  sq <- !is.na(bbw) & bbw <= 1.1 * bbmin
  emit("bb_squeeze", sq, NA_integer_, "Bollinger band width near its 100-candle low", first_of_run = TRUE)
  sq10 <- zoo::rollapplyr(sq, 11, function(x) any(utils::head(x, -1)), fill = FALSE, partial = TRUE)
  emit("bb_break_up", c > d$bb_up & sq10, 1L, "Close above the upper band after a squeeze", function(i) d$bb_mid[i], first_of_run = TRUE)
  emit("bb_break_down", c < d$bb_dn & sq10, -1L, "Close below the lower band after a squeeze", function(i) d$bb_mid[i], first_of_run = TRUE)
  nu <- !is.na(d$bb_up) & c >= d$bb_up - 0.2 * a; nd <- !is.na(d$bb_dn) & c <= d$bb_dn + 0.2 * a
  emit("bb_walk_up", nu & L(nu) & L(nu, 2), 1L, "Three closes riding the upper band", function(i) d$bb_mid[i], first_of_run = TRUE)
  emit("bb_walk_down", nd & L(nd) & L(nd, 2), -1L, "Three closes riding the lower band", function(i) d$bb_mid[i], first_of_run = TRUE)
  tl <- !is.na(d$bb_dn) & l <= d$bb_dn; tu <- !is.na(d$bb_up) & h >= d$bb_up
  tl3 <- tl | L(tl) | L(tl, 2); tu3 <- tu | L(tu) | L(tu, 2)
  emit("bb_snap_lower", tl3 & c > o & c >= d$bb_dn + 0.5 * (d$bb_mid - d$bb_dn), 1L, "Tagged the lower band, now back halfway to the middle", function(i) min(l[max(1, i - 2):i]) - 0.2 * a[i], function(i) d$bb_mid[i] + (d$bb_mid[i] - d$bb_dn[i]) * 0.5, first_of_run = TRUE)
  emit("bb_snap_upper", tu3 & c < o & c <= d$bb_up - 0.5 * (d$bb_up - d$bb_mid), -1L, "Tagged the upper band, now back halfway to the middle", function(i) max(h[max(1, i - 2):i]) + 0.2 * a[i], function(i) d$bb_mid[i] - (d$bb_up[i] - d$bb_mid[i]) * 0.5, first_of_run = TRUE)
  emit("keltner_squeeze", !is.na(d$kc_up) & d$bb_up < d$kc_up & d$bb_dn > d$kc_dn, NA_integer_, "Bollinger bands inside the Keltner channel", first_of_run = TRUE)
  at <- d$atr
  emit("atr_rising", !is.na(at) & at >= 1.15 * L(at, 10) & at > L(at) & L(at) > L(at, 2) & L(at, 2) > L(at, 3), NA_integer_, "ATR(14) up 15%+ in 10 candles", first_of_run = TRUE)
  emit("atr_falling", !is.na(at) & at <= 0.85 * L(at, 10) & at < L(at) & L(at) < L(at, 2) & L(at, 2) < L(at, 3), NA_integer_, "ATR(14) down 15%+ in 10 candles", first_of_run = TRUE)
  emit("adx_strong", d$adx >= ctx$adx_trend, NA_integer_, sprintf("ADX(14) at or above %s", ctx$adx_trend), first_of_run = TRUE)
  emit("adx_weak", d$adx <= ctx$adx_range, NA_integer_, sprintf("ADX(14) at or below %s", ctx$adx_range), first_of_run = TRUE)
  emit("di_x_up", xup(d$di_p, d$di_n), 1L, "DI+ crossed above DI-")
  emit("di_x_down", xup(d$di_n, d$di_p), -1L, "DI- crossed above DI+")
  # squeeze / coil from candle ranges
  rgv <- h - l; med <- zoo::rollapplyr(rgv, 50, stats::median, fill = NA, partial = TRUE)
  atmin <- zoo::rollapplyr(at, 30, function(x) if (all(is.na(x))) NA else min(x, na.rm = TRUE), fill = NA, partial = TRUE)
  small5 <- zoo::rollapplyr(rgv < 0.7 * med, 5, all, fill = FALSE)
  emit("vol_squeeze", !is.na(at) & at <= atmin + 1e-12 & small5, NA_integer_, "Candle ranges and ATR contracting into a coil", first_of_run = TRUE)
  # RSI failure swings (Wilder)
  r <- d$rsi
  for (i in 31:n) { if (!is.finite(r[i])) next
    w <- max(1, i - 30):(i - 1); rw <- r[w]; if (all(is.na(rw))) next
    lo <- which(rw < 30); if (length(lo)) { k <- w[max(lo)]; seg <- (k + 1):(i - 1)
      if (length(seg) >= 2) { pk <- seg[which.max(r[seg])]; X <- r[pk]; after <- if (pk < i - 1) (pk + 1):(i - 1) else integer(0)
        if (length(after) && X > 30 && all(r[after] > 30, na.rm = TRUE) && min(r[after], na.rm = TRUE) < X && r[i - 1] <= X && r[i] > X) {
          f <- cc_fill_dflt(1L, c[i], min(l[k:i]) - 0.2 * a[i], NA, a[i])
          out[[length(out) + 1]] <- cc_occ("rsi_fail_bull", k, i, c[i], f$invalid, f$target, sprintf("RSI dipped below 30, held above 30 on the pullback and broke %.1f", X), dir = 1L) } } }
    hi <- which(rw > 70); if (length(hi)) { k <- w[max(hi)]; seg <- (k + 1):(i - 1)
      if (length(seg) >= 2) { tr <- seg[which.min(r[seg])]; X <- r[tr]; after <- if (tr < i - 1) (tr + 1):(i - 1) else integer(0)
        if (length(after) && X < 70 && all(r[after] < 70, na.rm = TRUE) && max(r[after], na.rm = TRUE) > X && r[i - 1] >= X && r[i] < X) {
          f <- cc_fill_dflt(-1L, c[i], max(h[k:i]) + 0.2 * a[i], NA, a[i])
          out[[length(out) + 1]] <- cc_occ("rsi_fail_bear", k, i, c[i], f$invalid, f$target, sprintf("RSI rose above 70, stayed below 70 on the bounce and broke %.1f", X), dir = -1L) } } } }
  # momentum exhaustion
  hh <- zoo::rollapplyr(c, 20, max, fill = NA); ll <- zoo::rollapplyr(c, 20, min, fill = NA)
  for (i in 60:n) { if (!is.finite(hh[i])) next
    for (side in c(1, -1)) { at_ext <- if (side > 0) c[i] >= hh[i] - 1e-12 else c[i] <= ll[i] + 1e-12; if (!at_ext) next
      prev <- (i - 40):(i - 5); pi <- if (side > 0) prev[which.max(c[prev])] else prev[which.min(c[prev])]
      if ((side > 0 && c[i] <= c[pi]) || (side < 0 && c[i] >= c[pi])) next
      weak <- sum(c(side * (d$rsi[i] - d$rsi[pi]) < 0, side * (d$macd_hist[i] - d$macd_hist[pi]) < 0, side * (d$stoch_k[i] - d$stoch_k[pi]) < 0), na.rm = TRUE)
      if (weak >= 2) out[[length(out) + 1]] <- cc_occ("momentum_exhaustion", pi, i, c[i], NA, NA, sprintf("New 20-candle %s with %d of 3 momentum readings weaker than at the last one", if (side > 0) "high" else "low", weak), dir = NA_integer_) } }
  out
}

# divergences: two price swings (1 ATR zig-zag) within 40 candles, the second known (confirmed) in the last candles
cc_det_divergence <- function(ctx) {
  zz <- ctx$zz1; d <- ctx$ind; out <- list(); if (nrow(zz) < 2) return(out)
  ser <- list(macd = d$macd, rsi = d$rsi, stoch = d$stoch_k)
  for (tp in c("L", "H")) { p <- zz[zz$type == tp, , drop = FALSE]; if (nrow(p) < 2) next
    for (k in 2:nrow(p)) { p1 <- p[k - 1, ]; p2 <- p[k, ]; if (p2$idx - p1$idx > 40) next
      for (nm in names(ser)) { v <- ser[[nm]]; v1 <- v[p1$idx]; v2 <- v[p2$idx]; if (!is.finite(v1) || !is.finite(v2)) next
        i <- p2$conf; a <- ctx$a[i]; ent <- ctx$c[i]
        if (tp == "L" && p2$price < p1$price && v2 > v1) { f <- cc_fill_dflt(1L, ent, p2$price - 0.2 * a, cc_next_level(ctx, i, ent, 1), a)
          out[[length(out) + 1]] <- cc_occ(paste0(nm, "_div_bull"), p1$idx, i, ent, f$invalid, f$target, sprintf("Price lower low, %s higher low", toupper(nm)), dir = 1L,
                                           lines = cc_seg(p1$idx, p1$price, p2$idx, p2$price, "#16a34a", "dash")) }
        if (tp == "H" && p2$price > p1$price && v2 < v1) { f <- cc_fill_dflt(-1L, ent, p2$price + 0.2 * a, cc_next_level(ctx, i, ent, -1), a)
          out[[length(out) + 1]] <- cc_occ(paste0(nm, "_div_bear"), p1$idx, i, ent, f$invalid, f$target, sprintf("Price higher high, %s lower high", toupper(nm)), dir = -1L,
                                           lines = cc_seg(p1$idx, p1$price, p2$idx, p2$price, "#dc2626", "dash")) } } } }
  out
}

# course strategies: pivots, overnight range straddle, opening-range breakout (UK clock)
cc_det_strategies <- function(ctx) {
  b <- ctx$b; c <- ctx$c; h <- ctx$h; l <- ctx$l; a <- ctx$a; n <- ctx$n; out <- list()
  ukd <- as.Date(format(b$time, "%Y-%m-%d", tz = "Europe/London")); ukm <- ctx$uk$hour * 60 + ctx$uk$min
  hm <- function(s) { p <- as.integer(strsplit(s, ":")[[1]]); p[1] * 60 + p[2] }
  # previous day's H/L/C: Capital.com daily candles when given, else UK calendar days of these candles
  days <- sort(unique(ukd))
  dly <- if (!is.null(ctx$daily) && nrow(ctx$daily)) { dd <- ctx$daily; data.frame(d = as.Date(format(dd$time, "%Y-%m-%d", tz = "Europe/London")), h = dd$high, l = dd$low, c = dd$close) }
         else do.call(rbind, lapply(days, function(d) { ix <- which(ukd == d); data.frame(d = d, h = max(h[ix]), l = min(l[ix]), c = c[max(ix)]) }))
  piv_for <- function(d) { pr <- dly[dly$d < d, , drop = FALSE]; if (!nrow(pr)) return(NULL); r <- pr[nrow(pr), ]
    pp <- (r$h + r$l + r$c) / 3; list(PP = pp, R1 = 2 * pp - r$l, S1 = 2 * pp - r$h, R2 = pp + (r$h - r$l), S2 = pp - (r$h - r$l), R3 = r$h + 2 * (pp - r$l), S3 = r$l - 2 * (r$h - pp)) }
  pv_cache <- lapply(days, piv_for); names(pv_cache) <- as.character(days)
  last_long <- -Inf; last_short <- -Inf
  for (i in 6:n) { pv <- pv_cache[[as.character(ukd[i])]]; if (is.null(pv)) next; w <- (i - 4):i
    for (nm in c("PP", "S1", "S2")) { lv <- pv[[nm]]
      if (i - last_long > 5 && any(abs(l[w] - lv) <= 0.3 * a[i]) && min(l[w]) >= lv - 0.3 * a[i] && c[i] >= lv + 0.5 * a[i] && c[i - 1] < lv + 0.5 * a[i]) {
        abv <- unlist(pv[c("S2", "S1", "PP", "R1", "R2", "R3")]); tg <- abv[abv > c[i] + 0.2 * a[i]]; tg <- if (length(tg)) min(tg) else NA
        f <- cc_fill_dflt(1L, c[i], lv - 0.5 * a[i], tg, a[i]); last_long <- i
        out[[length(out) + 1]] <- cc_occ("pivot_bounce_long", i - 4, i, c[i], f$invalid, f$target, sprintf("Bounce off %s %.2f", nm, lv), level = lv, dir = 1L, marks = if (isTRUE(ctx$v2)) c(w[which.min(abs(l[w] - lv))], i) else NULL, lines = cc_seg(i - 4, lv, i, lv, "#64748b", "dot")) } }
    for (nm in c("PP", "R1", "R2")) { lv <- pv[[nm]]
      if (i - last_short > 5 && any(abs(h[w] - lv) <= 0.3 * a[i]) && max(h[w]) <= lv + 0.3 * a[i] && c[i] <= lv - 0.5 * a[i] && c[i - 1] > lv - 0.5 * a[i]) {
        blw <- unlist(pv[c("R2", "R1", "PP", "S1", "S2", "S3")]); tg <- blw[blw < c[i] - 0.2 * a[i]]; tg <- if (length(tg)) max(tg) else NA
        f <- cc_fill_dflt(-1L, c[i], lv + 0.5 * a[i], tg, a[i]); last_short <- i
        out[[length(out) + 1]] <- cc_occ("pivot_bounce_short", i - 4, i, c[i], f$invalid, f$target, sprintf("Rejected at %s %.2f", nm, lv), level = lv, dir = -1L, marks = if (isTRUE(ctx$v2)) c(w[which.min(abs(h[w] - lv))], i) else NULL, lines = cc_seg(i - 4, lv, i, lv, "#64748b", "dot")) } } }
  # overnight range: from on_from (previous evening) to on_to (this morning), UK
  f0 <- hm(ctx$on_from); t0 <- hm(ctx$on_to); o0 <- hm(ctx$or_start); om <- ctx$or_minutes
  for (d in as.list(days)) { d <- as.Date(d)
    on_ix <- which((ukd == d - 1 & ukm >= f0) | (ukd == d & ukm < t0)); if (length(on_ix) < 3) next
    onh <- max(h[on_ix]); onl <- min(l[on_ix]); rg <- onh - onl
    aft <- which(ukd == d & ukm >= t0)
    ku <- aft[c[aft] > onh][1]; kd <- aft[c[aft] < onl][1]
    onm <- if (isTRUE(ctx$v2)) c(on_ix[which.max(h[on_ix])], on_ix[which.min(l[on_ix])]) else NULL   # v2: the candles that made the range
    if (!is.na(ku)) out[[length(out) + 1]] <- cc_occ("on_straddle_up", min(on_ix), ku, c[ku], onl, onh + rg, sprintf("Close above the overnight high %.2f", onh), level = onh, dir = 1L, marks = if (is.null(onm)) NULL else c(onm, ku),
                                                    lines = rbind(cc_seg(min(on_ix), onh, ku, onh, "#0f766e", "dash"), cc_seg(min(on_ix), onl, ku, onl, "#0f766e", "dash")))
    if (!is.na(kd)) out[[length(out) + 1]] <- cc_occ("on_straddle_down", min(on_ix), kd, c[kd], onh, onl - rg, sprintf("Close below the overnight low %.2f", onl), level = onl, dir = -1L, marks = if (is.null(onm)) NULL else c(onm, kd),
                                                    lines = rbind(cc_seg(min(on_ix), onh, kd, onh, "#0f766e", "dash"), cc_seg(min(on_ix), onl, kd, onl, "#0f766e", "dash")))
    or_ix <- which(ukd == d & ukm >= o0 & ukm < o0 + om); if (length(or_ix) < 1) next
    orh <- max(h[or_ix]); orl <- min(l[or_ix]); org <- orh - orl; aft2 <- which(ukd == d & ukm >= o0 + om)
    ku <- aft2[c[aft2] > orh][1]; kd <- aft2[c[aft2] < orl][1]
    orm <- if (isTRUE(ctx$v2)) c(or_ix[which.max(h[or_ix])], or_ix[which.min(l[or_ix])]) else NULL
    if (!is.na(ku)) out[[length(out) + 1]] <- cc_occ("orb_up", min(or_ix), ku, c[ku], orl, orh + org, sprintf("Close above the opening-range high %.2f", orh), level = orh, dir = 1L, marks = if (is.null(orm)) NULL else c(orm, ku),
                                                    lines = rbind(cc_seg(min(or_ix), orh, ku, orh, "#a16207", "dash"), cc_seg(min(or_ix), orl, ku, orl, "#a16207", "dash")))
    if (!is.na(kd)) out[[length(out) + 1]] <- cc_occ("orb_down", min(or_ix), kd, c[kd], orh, orl - org, sprintf("Close below the opening-range low %.2f", orl), level = orl, dir = -1L, marks = if (is.null(orm)) NULL else c(orm, kd),
                                                    lines = rbind(cc_seg(min(or_ix), orh, kd, orh, "#a16207", "dash"), cc_seg(min(or_ix), orl, kd, orl, "#a16207", "dash")))
  }
  out
}

# =========================================================================================================
# PIVOT DETECTORS: run at candle e with only the swings known at e (no look-ahead). Each returns occurrences
# alive at e. For the history they are run at many e and de-duplicated by their anchor (sig).
# =========================================================================================================
cc_fitline <- function(x, y) { if (length(x) < 2) return(NULL); m <- stats::lm.fit(cbind(1, x), y); co <- m$coefficients
  list(a = co[1], b = co[2], res = max(abs(y - (co[1] + co[2] * x)))) }
cc_lv <- function(ln, x) ln$a + ln$b * x

cc_clusters <- function(idx, price, tol, min_n) {   # greedy clustering of levels within tol
  if (!length(price)) return(list()); o <- order(price); idx <- idx[o]; price <- price[o]; out <- list(); s <- 1
  for (k in seq_along(price)) { if (k == length(price) || price[k + 1] - price[s] > tol) {
      m <- s:k; if (length(m) >= min_n) out[[length(out) + 1]] <- list(level = stats::median(price[m]), idx = sort(idx[m])); s <- k + 1 } }
  out
}

cc_det_pivot_at <- function(ctx, e) {
  h <- ctx$h; l <- ctx$l; c <- ctx$c; a <- ctx$a[e]; n_back <- 250
  pv <- cc_pivots_at(ctx$zz, e, h, l); pv <- pv[pv$idx >= e - n_back, , drop = FALSE]
  if (nrow(pv) < 3) return(list())
  pc <- pv[!pv$prov, , drop = FALSE]
  H <- pc[pc$type == "H", , drop = FALSE]; Lw <- pc[pc$type == "L", , drop = FALSE]
  out <- list(); add <- function(o) out[[length(out) + 1]] <<- o; ce <- c[e]
  # ---- Dow trend: the swing still running at the right edge counts (a new low below the last low IS a lower low)
  # the running swing counts only when it goes beyond the last swing of its kind (a new low below the last low); a small
  # bounce that has not made a new extreme is not yet a swing
  Hd <- pc[pc$type == "H", , drop = FALSE]; Ld <- pc[pc$type == "L", , drop = FALSE]; pr <- pv[pv$prov, , drop = FALSE]
  if (nrow(pr)) { if (pr$type == "L" && nrow(Ld) && pr$price < utils::tail(Ld$price, 1)) Ld <- rbind(Ld, pr)
                  if (pr$type == "H" && nrow(Hd) && pr$price > utils::tail(Hd$price, 1)) Hd <- rbind(Hd, pr) }
  if (nrow(Hd) >= 2 && nrow(Ld) >= 2) {
    h1 <- Hd$price[nrow(Hd) - 1]; h2 <- Hd$price[nrow(Hd)]; l1 <- Ld$price[nrow(Ld) - 1]; l2 <- Ld$price[nrow(Ld)]
    ih <- utils::tail(Hd$idx, 2); il <- utils::tail(Ld$idx, 2); i0 <- min(ih, il); sig <- paste(ih[1], il[1])
    mk <- sort(unique(c(ih, il))); runs <- if (any(c(utils::tail(Hd$prov, 1), utils::tail(Ld$prov, 1)) %in% TRUE)) " (the last swing is still running)" else ""
    if (l2 > l1 + 0.1 * a && ce > l2 && h2 >= h1 - 0.1 * a) { full <- h2 > h1 + 0.1 * a   # lower high + higher low = contraction, not a trend
      add(cc_occ("dow_up", i0, e, ce, l2 - 0.2 * a, max(h2, ce) + abs(h2 - l2), paste0(if (full) "Higher highs and higher lows" else "Higher lows, no new higher high yet (early)", runs),
                 dir = 1L, conf = if (full) 80 else 50, status = if (full) "confirmed" else "early", sig = paste("dow_up", sig), marks = mk,
                 lines = rbind(cc_seg(il[1], l1, il[2], l2, "#16a34a"), cc_seg(ih[1], h1, ih[2], h2, "#16a34a")))) }
    if (h2 < h1 - 0.1 * a && ce < h2 && l2 <= l1 + 0.1 * a) { full <- l2 < l1 - 0.1 * a
      add(cc_occ("dow_down", i0, e, ce, h2 + 0.2 * a, min(l2, ce) - abs(h2 - l2), paste0(if (full) "Lower highs and lower lows" else "Lower highs, no new lower low yet (early)", runs),
                 dir = -1L, conf = if (full) 80 else 50, status = if (full) "confirmed" else "early", sig = paste("dow_down", sig), marks = mk,
                 lines = rbind(cc_seg(il[1], l1, il[2], l2, "#dc2626"), cc_seg(ih[1], h1, ih[2], h2, "#dc2626")))) }
    # the first sign of a turn: price breaks the last swing low after a higher high (or the last swing high after a lower low)
    if (h2 > h1 + 0.1 * a && l2 < l1 - 0.1 * a && il[2] > ih[2] && ce < l1)
      add(cc_occ("dow_down", i0, e, ce, h2 + 0.2 * a, ce - abs(h2 - l1), paste0("Lower low after the last high: a down-trend may be starting (no lower high yet)", runs),
                 dir = -1L, conf = 45, status = "early", sig = paste("dow_down_turn", sig), marks = mk,
                 lines = rbind(cc_seg(ih[2], h2, il[2], l2, "#dc2626"), cc_seg(il[1], l1, e, l1, "#dc2626", "dash"))))
    if (l2 < l1 - 0.1 * a && h2 > h1 + 0.1 * a && ih[2] > il[2] && ce > h1)
      add(cc_occ("dow_up", i0, e, ce, l2 - 0.2 * a, ce + abs(h1 - l2), paste0("Higher high after the last low: an up-trend may be starting (no higher low yet)", runs),
                 dir = 1L, conf = 45, status = "early", sig = paste("dow_up_turn", sig), marks = mk,
                 lines = rbind(cc_seg(il[2], l2, ih[2], h2, "#16a34a"), cc_seg(ih[1], h1, e, h1, "#16a34a", "dash"))))
  }
  # ---- support / resistance (3+ touches) and role reversals
  sup <- Filter(function(k) min(diff(c(-99, k$idx))) >= 3, cc_clusters(Lw$idx, Lw$price, 0.5 * a, 3))
  res <- Filter(function(k) min(diff(c(-99, k$idx))) >= 3, cc_clusters(H$idx, H$price, 0.5 * a, 3))
  near_res <- function(px) { v <- vapply(res, function(k) k$level, 0); v <- v[v > px + 0.3 * a]; if (length(v)) min(v) else NA }
  near_sup <- function(px) { v <- vapply(sup, function(k) k$level, 0); v <- v[v < px - 0.3 * a]; if (length(v)) max(v) else NA }
  for (k in sup) { lv <- k$level; s <- k$idx[1]:e
    if (all(c[s] >= lv - 0.3 * a) && ce > lv && ce - lv <= 3 * a) { f <- cc_fill_dflt(1L, ce, lv - 0.5 * a, near_res(ce), a)
      add(cc_occ("support", k$idx[1], e, ce, f$invalid, f$target, sprintf("%d touches at %.2f", length(k$idx), lv), level = lv, dir = 1L, sig = paste("support", k$idx[1], round(lv / a)), marks = k$idx, shade0 = max(k$idx[1], utils::tail(k$idx, 1) - 5),
                 lines = cc_seg(k$idx[1], lv, e, lv, "#16a34a", "dash"))) } }
  for (k in res) { lv <- k$level; s <- k$idx[1]:e
    if (all(c[s] <= lv + 0.3 * a) && ce < lv && lv - ce <= 3 * a) { f <- cc_fill_dflt(-1L, ce, lv + 0.5 * a, near_sup(ce), a)
      add(cc_occ("resistance", k$idx[1], e, ce, f$invalid, f$target, sprintf("%d touches at %.2f", length(k$idx), lv), level = lv, dir = -1L, sig = paste("resistance", k$idx[1], round(lv / a)), marks = k$idx, shade0 = max(k$idx[1], utils::tail(k$idx, 1) - 5),
                 lines = cc_seg(k$idx[1], lv, e, lv, "#dc2626", "dash"))) } }
  pall <- pv
  for (k in cc_clusters(Lw$idx, Lw$price, 0.5 * a, 2)) { lv <- k$level; t <- max(k$idx); if (t >= e - 2) next
    br <- which(c[(t + 1):e] < lv - 0.3 * a); if (!length(br)) next; kb <- t + br[1]
    rt <- pall[pall$type == "H" & pall$idx > kb & pall$idx >= e - 9 & abs(pall$price - lv) <= 0.5 * a, , drop = FALSE]
    if (nrow(rt) && ce < lv) { f <- cc_fill_dflt(-1L, ce, lv + 0.5 * a, near_sup(ce), a)
      add(cc_occ("sup_to_res", k$idx[1], e, ce, f$invalid, f$target, sprintf("Support %.2f (%d touches) broken, now retested from below", lv, length(k$idx)), level = lv, dir = -1L, sig = paste("s2r", k$idx[1], kb), marks = c(k$idx, kb, rt$idx), shade0 = kb,
                 lines = cc_seg(k$idx[1], lv, e, lv, "#dc2626", "dash"))) } }
  for (k in cc_clusters(H$idx, H$price, 0.5 * a, 2)) { lv <- k$level; t <- max(k$idx); if (t >= e - 2) next
    br <- which(c[(t + 1):e] > lv + 0.3 * a); if (!length(br)) next; kb <- t + br[1]
    rt <- pall[pall$type == "L" & pall$idx > kb & pall$idx >= e - 9 & abs(pall$price - lv) <= 0.5 * a, , drop = FALSE]
    if (nrow(rt) && ce > lv) { f <- cc_fill_dflt(1L, ce, lv - 0.5 * a, near_res(ce), a)
      add(cc_occ("res_to_sup", k$idx[1], e, ce, f$invalid, f$target, sprintf("Resistance %.2f (%d touches) broken, now retested from above", lv, length(k$idx)), level = lv, dir = 1L, sig = paste("r2s", k$idx[1], kb), marks = c(k$idx, kb, rt$idx), shade0 = kb,
                 lines = cc_seg(k$idx[1], lv, e, lv, "#16a34a", "dash"))) } }
  # ---- trend lines, breaks, channels
  tl <- function(P, up) {   # best valid line through pivots P (rising lows if up, falling highs if not); returns list or NULL
    best <- NULL; m <- nrow(P); if (m < 3) return(NULL); cand <- max(1, m - 7):m
    for (i in cand) for (j in cand) { if (j <= i) next
      x1 <- P$idx[i]; x2 <- P$idx[j]; s <- (P$price[j] - P$price[i]) / (x2 - x1)
      if (up && !(s > 0 && s <= 0.6 * a)) next; if (!up && !(s < 0 && -s <= 0.6 * a)) next
      lnv <- function(x) P$price[i] + s * (x - x1)
      after <- P[P$idx >= x1, , drop = FALSE]; tch <- sum(abs(after$price - lnv(after$idx)) <= 0.35 * a)
      rng <- x1:e; viol <- if (up) which(c[rng] < lnv(rng) - 0.35 * a) else which(c[rng] > lnv(rng) + 0.35 * a)
      first_v <- if (length(viol)) rng[viol[1]] else NA_integer_
      cand_l <- list(x1 = x1, s = s, y1 = P$price[i], touches = tch, first_v = first_v, last_touch = x2,
                     lnv = local({ yy <- P$price[i]; ss <- s; xx <- x1; function(x) yy + ss * (x - xx) }))   # frozen: the loop variables change after this
      if (isTRUE(ctx$v2) && !is.na(first_v) && first_v < e - 4) next   # v2: a line broken long ago is not the trend line now
      if (tch >= 3 && (is.null(best) || tch > best$touches || (tch == best$touches && x2 > best$last_touch) ||
                       (isTRUE(ctx$v2) && tch == best$touches && x2 == best$last_touch && x1 > best$x1))) { cand_l$pts <- after$idx[abs(after$price - cand_l$lnv(after$idx)) <= 0.35 * a]; best <- cand_l } }
    best }
  ul <- tl(Lw, TRUE); dl <- tl(H, FALSE)
  if (!is.null(ul)) { lvE <- ul$lnv(e)
    if (is.na(ul$first_v) && ce > lvE) { f <- cc_fill_dflt(1L, ce, lvE - 0.5 * a, if (nrow(H)) { v <- max(utils::tail(H$price, 2)); if (v > ce + 0.3 * a) v else NA } else NA, a)
      add(cc_occ("uptrend_line", ul$x1, e, ce, f$invalid, f$target, sprintf("%d touches, slope %.2f ATR per candle", ul$touches, ul$s / a), level = lvE, dir = 1L, sig = paste("upl", ul$x1, round(ul$s / a * 100)), marks = if (isTRUE(ctx$v2)) ul$pts else NULL,
                 lines = cc_seg(ul$x1, ul$y1, e, lvE, "#16a34a"))) }
    if (!is.na(ul$first_v) && ul$first_v >= e - 4 && c[ul$first_v] < ul$lnv(ul$first_v) - 0.2 * a && ce < lvE) {
      tg <- if (nrow(Lw)) { v <- Lw$price[Lw$price < ce - 0.3 * a]; if (length(v)) max(v) else NA } else NA
      f <- cc_fill_dflt(-1L, ce, lvE + 0.3 * a, tg, a)
      add(cc_occ("broken_uptrend", ul$x1, e, ce, f$invalid, f$target, sprintf("Uptrend line (%d touches) closed through", ul$touches), level = lvE, dir = -1L, sig = paste("bupl", ul$x1, ul$first_v), marks = if (isTRUE(ctx$v2)) c(ul$pts, ul$first_v) else NULL,
                 lines = cc_seg(ul$x1, ul$y1, e, lvE, "#dc2626", "dash"))) } }
  if (!is.null(dl)) { lvE <- dl$lnv(e)
    if (is.na(dl$first_v) && ce < lvE) { f <- cc_fill_dflt(-1L, ce, lvE + 0.5 * a, if (nrow(Lw)) { v <- min(utils::tail(Lw$price, 2)); if (v < ce - 0.3 * a) v else NA } else NA, a)
      add(cc_occ("downtrend_line", dl$x1, e, ce, f$invalid, f$target, sprintf("%d touches, slope %.2f ATR per candle", dl$touches, dl$s / a), level = lvE, dir = -1L, sig = paste("dnl", dl$x1, round(dl$s / a * 100)), marks = if (isTRUE(ctx$v2)) dl$pts else NULL,
                 lines = cc_seg(dl$x1, dl$y1, e, lvE, "#dc2626"))) }
    if (!is.na(dl$first_v) && dl$first_v >= e - 4 && c[dl$first_v] > dl$lnv(dl$first_v) + 0.2 * a && ce > lvE) {
      tg <- if (nrow(H)) { v <- H$price[H$price > ce + 0.3 * a]; if (length(v)) min(v) else NA } else NA
      f <- cc_fill_dflt(1L, ce, lvE - 0.3 * a, tg, a)
      add(cc_occ("broken_downtrend", dl$x1, e, ce, f$invalid, f$target, sprintf("Downtrend line (%d touches) closed through", dl$touches), level = lvE, dir = 1L, sig = paste("bdnl", dl$x1, dl$first_v), marks = if (isTRUE(ctx$v2)) c(dl$pts, dl$first_v) else NULL,
                 lines = cc_seg(dl$x1, dl$y1, e, lvE, "#16a34a", "dash"))) } }
  chan <- function(ln, Q, up) { if (is.null(ln) || !is.na(ln$first_v) || nrow(Q) < 3) return(NULL)
    Q <- Q[Q$idx >= ln$x1, , drop = FALSE]; if (nrow(Q) < 3) return(NULL)
    dv <- Q$price - ln$lnv(Q$idx); D <- if (up) max(dv) else min(dv); if (abs(D) < 1.5 * a) return(NULL)
    tch <- sum(abs(dv - D) <= 0.5 * a); if (tch < 3) return(NULL); list(D = D, touches = tch, pts = Q$idx[abs(dv - D) <= 0.5 * a]) }
  ch <- chan(ul, H, TRUE)
  if (!is.null(ch)) { lo <- ul$lnv(e); hi <- lo + ch$D; if (ce >= lo && ce <= hi) { f <- cc_fill_dflt(1L, ce, lo - 0.5 * a, hi, a)
    add(cc_occ("bull_channel", ul$x1, e, ce, f$invalid, f$target, sprintf("Rising channel: %d + %d touches", ul$touches, ch$touches), dir = 1L, sig = paste("bch", ul$x1), marks = if (isTRUE(ctx$v2)) c(ul$pts, ch$pts) else NULL,
               lines = rbind(cc_seg(ul$x1, ul$y1, e, lo, "#16a34a"), cc_seg(ul$x1, ul$y1 + ch$D, e, hi, "#16a34a")))) } }
  ch <- chan(dl, Lw, FALSE)
  if (!is.null(ch)) { hi <- dl$lnv(e); lo <- hi + ch$D; if (ce <= hi && ce >= lo) { f <- cc_fill_dflt(-1L, ce, hi + 0.5 * a, lo, a)
    add(cc_occ("bear_channel", dl$x1, e, ce, f$invalid, f$target, sprintf("Falling channel: %d + %d touches", dl$touches, ch$touches), dir = -1L, sig = paste("dch", dl$x1), marks = if (isTRUE(ctx$v2)) c(dl$pts, ch$pts) else NULL,
               lines = rbind(cc_seg(dl$x1, dl$y1, e, hi, "#dc2626"), cc_seg(dl$x1, dl$y1 + ch$D, e, lo, "#dc2626")))) } }
  # ---- countertrend line breaks (trend resumes)
  e50 <- ctx$ind$ema50; e200 <- ctx$ind$ema200
  if (e > 60 && is.finite(e50[e]) && is.finite(e50[e - 10])) {
    upm <- e50[e] > e50[e - 10] && (!is.finite(e200[e]) || ce > e200[e]); dnm <- e50[e] < e50[e - 10] && (!is.finite(e200[e]) || ce < e200[e])
    for (side in c(1, -1)) { if ((side > 0 && !upm) || (side < 0 && !dnm)) next
      P <- if (side > 0) H[H$idx >= e - 40, , drop = FALSE] else Lw[Lw$idx >= e - 40, , drop = FALSE]; if (nrow(P) < 2) next
      p1 <- P[nrow(P) - 1, ]; p2 <- P[nrow(P), ]; s <- (p2$price - p1$price) / (p2$idx - p1$idx)
      if ((side > 0 && s >= 0) || (side < 0 && s <= 0)) next
      lnv <- function(x) p1$price + s * (x - p1$idx); rng <- (p2$idx + 1):e; if (p2$idx >= e) next
      br <- if (side > 0) which(c[rng] > lnv(rng) + 0.1 * a) else which(c[rng] < lnv(rng) - 0.1 * a); if (!length(br)) next
      kb <- rng[br[1]]; if (kb < e - 4) next
      ext <- if (side > 0) min(l[p1$idx:e]) else max(h[p1$idx:e])
      prv <- if (side > 0) H$price[H$idx < p1$idx & H$idx >= p1$idx - 60] else Lw$price[Lw$idx < p1$idx & Lw$idx >= p1$idx - 60]
      tg <- if (length(prv)) (if (side > 0) max(prv) else min(prv)) else NA; if (is.finite(tg) && side * (tg - ce) <= 0.3 * a) tg <- NA
      f <- cc_fill_dflt(side, ce, ext - side * 0.2 * a, tg, a)
      add(cc_occ(if (side > 0) "ctr_break_up" else "ctr_break_down", p1$idx, e, ce, f$invalid, f$target, "The pullback's countertrend line broke: the main trend resumes", dir = as.integer(side),
                 sig = paste("ctr", side, p1$idx, kb), marks = if (isTRUE(ctx$v2)) c(p1$idx, p2$idx, kb) else NULL, lines = cc_seg(p1$idx, p1$price, e, lnv(e), "#a855f7", "dash"))) } }
  # ---- Fibonacci
  fibAB <- if (nrow(pc) >= 2) list(pc[nrow(pc) - 1, ], pc[nrow(pc), ]) else NULL
  if (isTRUE(ctx$v2) && nrow(pc) >= 3) {   # v2: when the pullback's own low (high) is already a confirmed swing, the leg is the one before it
    A3 <- pc[nrow(pc) - 2, ]; B3 <- pc[nrow(pc) - 1, ]; C3 <- pc[nrow(pc), ]; lg <- B3$price - A3$price
    if (abs(lg) >= 3 * a && (B3$price - C3$price) / lg >= 0.3 && (B3$price - C3$price) / lg <= 0.7) fibAB <- list(A3, B3) }
  if (!is.null(fibAB)) { A <- fibAB[[1]]; B <- fibAB[[2]]; leg <- B$price - A$price
    if (abs(leg) >= 3 * a && e > B$idx) { dir <- if (leg > 0) 1L else -1L; lev <- B$price - leg * c(0.382, 0.5, 0.618); l786 <- B$price - leg * 0.786
      w <- max(B$idx + 1, e - 4):e; since <- (B$idx + 1):e
      if (isTRUE(ctx$v2)) w <- max(B$idx + 1, e - 9):e   # v2: the reaction within the last 10 candles
      tch <- vapply(lev, function(v) any(if (dir > 0) abs(l[w] - v) <= 0.3 * a else abs(h[w] - v) <= 0.3 * a), TRUE)
      okb <- if (dir > 0) all(c[since] > l786) else all(c[since] < l786)
      r <- (B$price - ce) / leg
      if (isTRUE(ctx$v2)) { ext <- if (dir > 0) min(l[w]) else max(h[w]); k_ <- which.min(abs(lev - ext)); tch <- seq_along(lev) == k_ & abs(lev[k_] - ext) <= 0.3 * a }   # v2: the level where price turned
      if (any(tch) && okb && r >= 0.30 && r <= 0.70) { nm <- c("38.2%", "50%", "61.8%")[which(tch)[1]]
        tci <- if (isTRUE(ctx$v2)) w[if (dir > 0) which.min(l[w]) else which.max(h[w])] else w[which.min(if (dir > 0) abs(l[w] - lev[which(tch)[1]]) else abs(h[w] - lev[which(tch)[1]]))]
        add(cc_occ("fib_retracement", A$idx, e, ce, l786, B$price, sprintf("Pullback reacting at the %s retracement of the last %s leg", nm, if (dir > 0) "up" else "down"),
                   level = lev[which(tch)[1]], dir = dir, sig = paste("fibr", A$idx, B$idx), marks = c(A$idx, B$idx, tci),
                   lines = do.call(rbind, lapply(c(lev, l786), function(v) cc_seg(A$idx, v, e, v, "#b45309", "dot"))))) } } }
  if (nrow(pc) >= 3) { A <- pc[nrow(pc) - 2, ]; B <- pc[nrow(pc) - 1, ]; C <- pc[nrow(pc), ]; leg <- B$price - A$price
    if (abs(leg) >= 3 * a && C$idx >= e - 40) { r <- (B$price - C$price) / leg; dir <- if (leg > 0) 1L else -1L; tg <- C$price + leg
      if (r >= 0.236 && r <= 0.786 && dir * (ce - C$price) > 0 && dir * (tg - ce) > 0) {
        add(cc_occ("fib_expansion", A$idx, e, ce, C$price - dir * 0.2 * a, tg, sprintf("100%% expansion target %.2f (127.2%% %.2f, 161.8%% %.2f)", tg, C$price + 1.272 * leg, C$price + 1.618 * leg),
                   level = tg, dir = dir, sig = paste("fibx", A$idx, C$idx), marks = c(A$idx, B$idx, C$idx),
                   lines = rbind(cc_seg(A$idx, A$price, B$idx, B$price, "#b45309"), cc_seg(B$idx, B$price, C$idx, C$price, "#b45309"), cc_seg(C$idx, tg, e, tg, "#b45309", "dash")))) } } }
  # ---- triangles and wedges (5+ turning points, fitted lines)
  best <- NULL
  pvt <- if (isTRUE(ctx$v2)) pc else pv   # v2: lines through confirmed turning points only (the running extreme still moves)
  thru <- function(x, y) { k <- length(x); b_ <- (y[k] - y[1]) / (x[k] - x[1]); list(a = y[1] - b_ * x[1], b = b_, res = max(abs(y - (y[1] + b_ * (x - x[1]))))) }
  for (k in 8:5) { if (nrow(pvt) < k) next; P <- utils::tail(pvt, k); if (min(P$idx) < e - 150) next
    PH <- P[P$type == "H", , drop = FALSE]; PL <- P[P$type == "L", , drop = FALSE]; if (nrow(PH) < 2 || nrow(PL) < 2) next
    lh <- if (isTRUE(ctx$v2)) thru(PH$idx, PH$price) else cc_fitline(PH$idx, PH$price); ll <- if (isTRUE(ctx$v2)) thru(PL$idx, PL$price) else cc_fitline(PL$idx, PL$price)
    if (lh$res > 0.5 * a || ll$res > 0.5 * a) next
    if (isTRUE(ctx$v2) && (any(h[min(P$idx):e] > cc_lv(lh, min(P$idx):e) + 0.5 * a & seq(min(P$idx), e) < e - 2) || any(l[min(P$idx):e] < cc_lv(ll, min(P$idx):e) - 0.5 * a & seq(min(P$idx), e) < e - 2))) next
    x0 <- min(P$idx); w0 <- cc_lv(lh, x0) - cc_lv(ll, x0); wE <- cc_lv(lh, e) - cc_lv(ll, e)
    if (!(w0 > 2 * a && wE > 0 && wE < 0.8 * w0)) next
    best <- list(P = P, lh = lh, ll = ll, x0 = x0, w0 = w0, wE = wE); break }
  if (!is.null(best)) { sh <- best$lh$b / a; sl <- best$ll$b / a; flat <- 0.03
    key <- if (sh < -flat && sl > flat) "sym_triangle" else if (abs(sh) <= flat && sl > flat) "asc_triangle" else if (abs(sl) <= flat && sh < -flat) "desc_triangle" else
           if (sh > flat && sl > flat && sl > sh) "rising_wedge" else if (sh < -flat && sl < -flat && sh < sl) "falling_wedge" else NA
    if (!is.na(key)) { up_l <- cc_lv(best$lh, e); lo_l <- cc_lv(best$ll, e)
      brk <- 0L; for (j in max(best$x0, e - 2):e) { if (c[j] > cc_lv(best$lh, j) + 0.2 * a) brk <- 1L; if (c[j] < cc_lv(best$ll, j) - 0.2 * a) brk <- -1L }
      inside <- ce <= up_l + 0.2 * a && ce >= lo_l - 0.2 * a
      if (inside || brk != 0L) {
        bias <- cc_catalog$bias[cc_catalog$key == key]; dir <- if (brk != 0L) brk else if (bias == "bullish") 1L else if (bias == "bearish") -1L else {
          pt <- (c[best$x0] - c[max(1, best$x0 - 15)]); if (pt >= 0) 1L else -1L }
        inv <- if (dir > 0) lo_l - 0.2 * a else up_l + 0.2 * a
        tg <- if (key %in% c("rising_wedge", "falling_wedge")) c[best$x0] else (if (dir > 0) up_l else lo_l) + dir * best$w0
        st <- if (brk != 0L) sprintf("broke %s", if (brk > 0) "up" else "down") else "forming"
        add(cc_occ(key, best$x0, e, ce, inv, tg, sprintf("%d turning points; upper slope %.2f, lower slope %.2f ATR per candle", nrow(best$P), sh, sl),
                   dir = dir, status = st, conf = if (brk != 0L) 75 else 60, sig = paste(key, best$x0), marks = if (isTRUE(ctx$v2)) best$P$idx else NULL,
                   lines = if (isTRUE(ctx$v2)) { xh <- min(best$P$idx[best$P$type == "H"]); xl <- min(best$P$idx[best$P$type == "L"])   # v2: each line from its own first turning point
                     rbind(cc_seg(xh, cc_lv(best$lh, xh), e, up_l, "#7c3aed"), cc_seg(xl, cc_lv(best$ll, xl), e, lo_l, "#7c3aed")) } else
                     rbind(cc_seg(best$x0, cc_lv(best$lh, best$x0), e, up_l, "#7c3aed"), cc_seg(best$x0, cc_lv(best$ll, best$x0), e, lo_l, "#7c3aed")))) } } }
  # ---- double / triple tops and bottoms, head & shoulders (last swing may be provisional)
  Hp <- pv[pv$type == "H", , drop = FALSE]; Lp <- pv[pv$type == "L", , drop = FALSE]
  if (nrow(Hp) >= 2) { p1 <- Hp[nrow(Hp) - 1, ]; p2 <- Hp[nrow(Hp), ]
    if (abs(p1$price - p2$price) <= a && p2$idx - p1$idx >= 4 && p2$idx >= e - 20) { v <- min(l[p1$idx:p2$idx]); top <- max(p1$price, p2$price)
      if (min(p1$price, p2$price) - v >= 3 * a && ce < top + 0.3 * a) { conf_b <- any(c[p2$idx:e] < v)
        vi <- p1$idx - 1L + which.min(l[p1$idx:p2$idx])
        add(cc_occ("double_top", p1$idx, e, ce, top + 0.3 * a, v - (top - v), sprintf("Two peaks %.2f / %.2f, neckline %.2f", p1$price, p2$price, v), level = v, dir = -1L,
                   status = if (conf_b) "confirmed" else "forming", conf = if (conf_b) 80 else 55, sig = paste("dt", p1$idx), marks = c(p1$idx, vi, p2$idx),
                   lines = rbind(cc_seg(p1$idx, p1$price, p2$idx, p2$price, "#dc2626"), cc_seg(p1$idx, v, e, v, "#dc2626", "dash")))) } } }
  if (nrow(Lp) >= 2) { p1 <- Lp[nrow(Lp) - 1, ]; p2 <- Lp[nrow(Lp), ]
    if (abs(p1$price - p2$price) <= a && p2$idx - p1$idx >= 4 && p2$idx >= e - 20) { v <- max(h[p1$idx:p2$idx]); bot <- min(p1$price, p2$price)
      if (v - max(p1$price, p2$price) >= 3 * a && ce > bot - 0.3 * a) { conf_b <- any(c[p2$idx:e] > v)
        vi <- p1$idx - 1L + which.max(h[p1$idx:p2$idx])
        add(cc_occ("double_bottom", p1$idx, e, ce, bot - 0.3 * a, v + (v - bot), sprintf("Two lows %.2f / %.2f, neckline %.2f", p1$price, p2$price, v), level = v, dir = 1L,
                   status = if (conf_b) "confirmed" else "forming", conf = if (conf_b) 80 else 55, sig = paste("db", p1$idx), marks = c(p1$idx, vi, p2$idx),
                   lines = rbind(cc_seg(p1$idx, p1$price, p2$idx, p2$price, "#16a34a"), cc_seg(p1$idx, v, e, v, "#16a34a", "dash")))) } } }
  if (nrow(Hp) >= 3 && nrow(Lp) >= 2) { P3 <- utils::tail(Hp, 3); mu <- mean(P3$price)
    vs <- vapply(1:2, function(k) min(l[P3$idx[k]:P3$idx[k + 1]]), 0)
    if (all(abs(P3$price - mu) <= 0.5 * a) && P3$idx[3] >= e - 20 && all(mu - vs >= 2 * a) && ce < max(P3$price) + 0.3 * a) { nk <- min(vs); top <- max(P3$price)
      vix <- vapply(1:2, function(k) P3$idx[k] - 1L + which.min(l[P3$idx[k]:P3$idx[k + 1]]), 0L)
      add(cc_occ("triple_top", P3$idx[1], e, ce, top + 0.3 * a, nk - (top - nk), sprintf("Three peaks near %.2f", mu), level = nk, dir = -1L, sig = paste("tt", P3$idx[1]), marks = if (isTRUE(ctx$v2)) sort(c(P3$idx, vix)) else NULL,
                 status = if (any(c[P3$idx[3]:e] < nk)) "confirmed" else "forming", lines = cc_seg(P3$idx[1], mu, e, mu, "#dc2626", "dash"))) } }
  if (nrow(Lp) >= 3 && nrow(Hp) >= 2) { P3 <- utils::tail(Lp, 3); mu <- mean(P3$price)
    vs <- vapply(1:2, function(k) max(h[P3$idx[k]:P3$idx[k + 1]]), 0)
    if (all(abs(P3$price - mu) <= 0.5 * a) && P3$idx[3] >= e - 20 && all(vs - mu >= 2 * a) && ce > min(P3$price) - 0.3 * a) { nk <- max(vs); bot <- min(P3$price)
      vix <- vapply(1:2, function(k) P3$idx[k] - 1L + which.max(h[P3$idx[k]:P3$idx[k + 1]]), 0L)
      add(cc_occ("triple_bottom", P3$idx[1], e, ce, bot - 0.3 * a, nk + (nk - bot), sprintf("Three lows near %.2f", mu), level = nk, dir = 1L, sig = paste("tb", P3$idx[1]), marks = if (isTRUE(ctx$v2)) sort(c(P3$idx, vix)) else NULL,
                 status = if (any(c[P3$idx[3]:e] > nk)) "confirmed" else "forming", lines = cc_seg(P3$idx[1], mu, e, mu, "#16a34a", "dash"))) } }
  hs <- function(P, top) { if (nrow(P) < 5) return(NULL); want <- if (top) c("H", "L", "H", "L", "H") else c("L", "H", "L", "H", "L")
    Q <- utils::tail(P, 5); if (!identical(Q$type, want) && nrow(P) >= 6) Q <- utils::tail(P, 6)[1:5, ]   # the right shoulder may be followed by a newer swing
    if (!identical(Q$type, want)) return(NULL); s1 <- Q$price[1]; hd <- Q$price[3]; s2 <- Q$price[5]; sg <- if (top) 1 else -1
    if (sg * (hd - s1) < a || sg * (hd - s2) < a || abs(s1 - s2) > 1.5 * a) return(NULL)
    sp <- (Q$idx[3] - Q$idx[1]) / max(1, Q$idx[5] - Q$idx[3]); if (sp < 0.5 || sp > 2) return(NULL)
    if (Q$idx[5] < e - 20) return(NULL); nl <- function(x) Q$price[2] + (Q$price[4] - Q$price[2]) / (Q$idx[4] - Q$idx[2]) * (x - Q$idx[2])
    list(Q = Q, nl = nl, hd = hd) }
  x <- hs(pv, TRUE)
  if (!is.null(x) && ce < x$Q$price[5] + 0.3 * a) { nE <- x$nl(e); cf <- any(vapply(x$Q$idx[5]:e, function(j) c[j] < x$nl(j), TRUE))
    add(cc_occ("head_shoulders", x$Q$idx[1], e, ce, x$Q$price[5] + 0.3 * a, nE - (x$hd - x$nl(x$Q$idx[3])), "Head above two level shoulders", level = nE, dir = -1L,
               status = if (cf) "confirmed" else "forming", conf = if (cf) 80 else 55, sig = paste("hs", x$Q$idx[1]), marks = x$Q$idx,
               lines = rbind(cc_seg(x$Q$idx[1], x$Q$price[1], x$Q$idx[3], x$Q$price[3], "#dc2626"), cc_seg(x$Q$idx[3], x$Q$price[3], x$Q$idx[5], x$Q$price[5], "#dc2626"),
                             cc_seg(x$Q$idx[2], x$Q$price[2], e, nE, "#dc2626", "dash")))) }
  x <- hs(pv, FALSE)
  if (!is.null(x) && ce > x$Q$price[5] - 0.3 * a) { nE <- x$nl(e); cf <- any(vapply(x$Q$idx[5]:e, function(j) c[j] > x$nl(j), TRUE))
    add(cc_occ("inv_head_shoulders", x$Q$idx[1], e, ce, x$Q$price[5] - 0.3 * a, nE + (x$nl(x$Q$idx[3]) - x$hd), "Head below two level shoulders", level = nE, dir = 1L,
               status = if (cf) "confirmed" else "forming", conf = if (cf) 80 else 55, sig = paste("ihs", x$Q$idx[1]), marks = x$Q$idx,
               lines = rbind(cc_seg(x$Q$idx[1], x$Q$price[1], x$Q$idx[3], x$Q$price[3], "#16a34a"), cc_seg(x$Q$idx[3], x$Q$price[3], x$Q$idx[5], x$Q$price[5], "#16a34a"),
                             cc_seg(x$Q$idx[2], x$Q$price[2], e, nE, "#16a34a", "dash")))) }
  # ---- rectangle
  rec_h <- utils::tail(H[H$idx >= e - 150, , drop = FALSE], 3); rec_l <- utils::tail(Lw[Lw$idx >= e - 150, , drop = FALSE], 3)
  if (nrow(rec_h) == 3 && nrow(rec_l) == 3) { top <- stats::median(rec_h$price); bot <- stats::median(rec_l$price); x0 <- min(rec_h$idx, rec_l$idx)
    if (all(abs(rec_h$price - top) <= 0.5 * a) && all(abs(rec_l$price - bot) <= 0.5 * a) && e - x0 >= 15 && top - bot >= 2 * a && ce < top + 0.2 * a && ce > bot - 0.2 * a) {
      dir <- if (ce < (top + bot) / 2) 1L else -1L
      add(cc_occ("rectangle", x0, e, ce, if (dir > 0) bot - 0.5 * a else top + 0.5 * a, if (dir > 0) top else bot, sprintf("Range %.2f-%.2f (price in the %s half)", bot, top, if (dir > 0) "lower" else "upper"),
                 dir = dir, sig = paste("rect", x0), marks = if (isTRUE(ctx$v2)) sort(c(rec_h$idx, rec_l$idx)) else NULL, lines = rbind(cc_seg(x0, top, e, top, "#64748b"), cc_seg(x0, bot, e, bot, "#64748b")))) } }
  # ---- cup and handle (and inverted)
  for (side in c(1, -1)) { R <- if (side > 0) H else Lw; if (nrow(R) < 2) next
    for (i2 in rev(seq_len(nrow(R)))[1:min(3, nrow(R))]) { r2 <- R[i2, ]; if (r2$idx < e - 15 || r2$idx > e - 3) next
      for (i1 in rev(seq_len(i2 - 1))) { r1 <- R[i1, ]; span <- r2$idx - r1$idx; if (span < 15 || span > 150) next
        if (abs(r1$price - r2$price) > a) next; cup <- r1$idx:r2$idx
        bot <- if (side > 0) min(l[cup]) else max(h[cup]); rim <- if (side > 0) min(r1$price, r2$price) else max(r1$price, r2$price); depth <- side * (rim - bot); if (depth < 3 * a) next
        low3 <- if (side > 0) sum(l[cup] <= bot + depth / 3) else sum(h[cup] >= bot - depth / 3); if (low3 < 0.3 * span) next
        hd <- (r2$idx + 1):e; if (length(hd) < 3 || length(hd) > 15) next
        hx <- if (side > 0) min(l[hd]) else max(h[hd]); if (side * (rim - hx) > depth / 3 || side * (hx - (bot + side * depth / 2)) < 0) next
        if (side * ((if (side > 0) max(h[hd]) else min(l[hd])) - rim) > 0.3 * a) next
        add(cc_occ(if (side > 0) "cup_handle" else "inv_cup_handle", r1$idx, e, ce, hx - side * 0.2 * a, rim + side * depth, sprintf("Rounded %s %.1f ATR deep with a %d-candle handle", if (side > 0) "cup" else "dome", depth / a, length(hd)),
                   level = rim, dir = as.integer(side), sig = paste("cup", side, r1$idx),
                   marks = if (isTRUE(ctx$v2)) c(r1$idx, cup[if (side > 0) which.min(l[cup]) else which.max(h[cup])], r2$idx, hd[if (side > 0) which.min(l[hd]) else which.max(h[hd])]) else NULL, lines = rbind(cc_seg(r1$idx, rim, r2$idx, rim, "#0ea5e9", "dash"), cc_seg(r2$idx, hx, e, hx, "#0ea5e9", "dot"))))
        break } } }
  # ---- rounding bottom / top: quadratic fit
  for (w in c(80, 50, 30)) { if (e - w < 1) next; ix <- (e - w + 1):e; t <- seq_len(w); y <- c[ix]
    fit <- stats::lm.fit(cbind(1, t, t^2), y); co <- fit$coefficients; if (any(!is.finite(co)) || co[3] == 0) next
    yh <- cbind(1, t, t^2) %*% co; r2 <- 1 - sum((y - yh)^2) / sum((y - mean(y))^2); vx <- -co[2] / (2 * co[3])
    if (!is.finite(r2) || r2 < 0.8 || vx < w / 3 || vx > 2 * w / 3) next
    vy <- co[1] + co[2] * vx + co[3] * vx^2; depth <- abs(max(yh[1], yh[w]) - vy) * 1; if (co[3] < 0) depth <- abs(vy - min(yh[1], yh[w]))
    if (depth < 3 * a) next
    curve <- function(col) { if (!isTRUE(ctx$v2)) return(cc_seg(ix[1], yh[1], ix[1] + round(vx), vy, col, "dot")); k_ <- seq(1, w, by = 2); if (utils::tail(k_, 1) != w) k_ <- c(k_, w)
      do.call(rbind, lapply(seq_len(length(k_) - 1), function(j) cc_seg(ix[k_[j]], yh[k_[j]], ix[k_[j + 1]], yh[k_[j + 1]], col, "dot"))) }   # v2: the whole fitted curve
    mk <- if (isTRUE(ctx$v2)) c(ix[1], ix[1] - 1L + round(vx), e) else NULL
    if (co[3] > 0 && ce > vy && ce > c[e - 3]) { add(cc_occ("rounding_bottom", ix[1], e, ce, min(l[ix]) - 0.2 * a, c[ix[1]], sprintf("Saucer over %d candles (R-squared %.2f)", w, r2), dir = 1L, sig = paste("rb", ix[1] %/% 10),
                       marks = mk, lines = curve("#16a34a"))); break }
    if (co[3] < 0 && ce < vy && ce < c[e - 3]) { add(cc_occ("rounding_top", ix[1], e, ce, max(h[ix]) + 0.2 * a, c[ix[1]], sprintf("Dome over %d candles (R-squared %.2f)", w, r2), dir = -1L, sig = paste("rt", ix[1] %/% 10),
                       marks = mk, lines = curve("#dc2626"))); break } }
  # ---- diamond (rare) and broadening
  for (w in c(60, 40)) { if (e - w < 20) next; x0 <- e - w + 1; mid <- x0 + w %/% 2
    P1 <- pc[pc$idx >= x0 & pc$idx < mid, , drop = FALSE]; P2 <- pc[pc$idx >= mid & pc$idx <= e, , drop = FALSE]
    sl <- function(P, t) { Q <- P[P$type == t, , drop = FALSE]; if (nrow(Q) < 2) NA else stats::coef(stats::lm(price ~ idx, Q))[2] }
    a1 <- sl(P1, "H"); b1 <- sl(P1, "L"); a2 <- sl(P2, "H"); b2 <- sl(P2, "L"); if (any(is.na(c(a1, b1, a2, b2)))) next
    if (a1 > 0 && b1 < 0 && a2 < 0 && b2 > 0) { wmax <- which.max(h[x0:e]) + x0 - 1; wmin <- which.min(l[x0:e]) + x0 - 1; ht <- max(h[x0:e]) - min(l[x0:e])
      prior <- c[x0] - c[max(1, x0 - 20)]
      PW <- rbind(P1, P2); dmk <- if (isTRUE(ctx$v2)) PW$idx else NULL
      dln <- function(col) { if (!isTRUE(ctx$v2)) return(NULL); o_ <- NULL
        for (t_ in c("H", "L")) { Q <- PW[PW$type == t_, , drop = FALSE]; k_ <- if (t_ == "H") which.max(Q$price) else which.min(Q$price)
          o_ <- rbind(o_, cc_seg(Q$idx[1], Q$price[1], Q$idx[k_], Q$price[k_], col), cc_seg(Q$idx[k_], Q$price[k_], utils::tail(Q$idx, 1), utils::tail(Q$price, 1), col)) }; o_ }   # v2: the diamond's four sides
      if (prior > 0 && wmax > x0 + w / 4 && wmax < e - w / 4) { add(cc_occ("diamond_top", x0, e, ce, max(h[x0:e]), ce - ht, "Widening then narrowing at a high", dir = -1L, conf = 35, sig = paste("dmt", x0 %/% 10), marks = dmk, lines = dln("#dc2626"))); break }
      if (prior < 0 && wmin > x0 + w / 4 && wmin < e - w / 4) { add(cc_occ("diamond_bottom", x0, e, ce, min(l[x0:e]), ce + ht, "Widening then narrowing at a low", dir = 1L, conf = 35, sig = paste("dmb", x0 %/% 10), marks = dmk, lines = dln("#16a34a"))); break } } }
  PB <- utils::tail(pv[pv$idx >= e - 150, , drop = FALSE], 6)
  if (nrow(PB) >= 5) { BH <- PB[PB$type == "H", , drop = FALSE]; BL <- PB[PB$type == "L", , drop = FALSE]
    if (nrow(BH) >= 2 && nrow(BL) >= 2 && all(diff(BH$price) > 0.2 * a) && all(diff(BL$price) < -0.2 * a)) { x0 <- min(PB$idx); prior <- c[x0] - c[max(1, x0 - 30)]
      if (prior > 0) add(cc_occ("broadening_top", x0, e, ce, max(BH$price) + 0.3 * a, min(BL$price), "Higher highs and lower lows after a rise", dir = -1L, conf = 45, sig = paste("bt", x0), marks = if (isTRUE(ctx$v2)) PB$idx else NULL,
                                lines = rbind(cc_seg(BH$idx[1], BH$price[1], utils::tail(BH$idx, 1), utils::tail(BH$price, 1), "#dc2626"), cc_seg(BL$idx[1], BL$price[1], utils::tail(BL$idx, 1), utils::tail(BL$price, 1), "#dc2626"))))
      if (prior < 0) add(cc_occ("broadening_bottom", x0, e, ce, min(BL$price) - 0.3 * a, max(BH$price), "Higher highs and lower lows after a fall", dir = 1L, conf = 45, sig = paste("bb", x0), marks = if (isTRUE(ctx$v2)) PB$idx else NULL,
                                lines = rbind(cc_seg(BH$idx[1], BH$price[1], utils::tail(BH$idx, 1), utils::tail(BH$price, 1), "#16a34a"), cc_seg(BL$idx[1], BL$price[1], utils::tail(BL$idx, 1), utils::tail(BL$price, 1), "#16a34a")))) } }
  # ---- measured move
  if (nrow(pc) >= 3) { A <- pc[nrow(pc) - 2, ]; B <- pc[nrow(pc) - 1, ]; C <- pc[nrow(pc), ]; leg <- B$price - A$price
    if (abs(leg) >= 3 * a && C$idx >= e - 30) { r <- (B$price - C$price) / leg; dir <- if (leg > 0) 1L else -1L; tg <- C$price + leg
      if (r >= 0.3 && r <= 0.7 && dir * (ce - C$price) > 0 && dir * (tg - ce) > 0)
        add(cc_occ(if (dir > 0) "measured_up" else "measured_down", A$idx, e, ce, C$price - dir * 0.2 * a, tg, sprintf("Second leg projected to %.2f (same length as the first)", tg), dir = dir,
                   sig = paste("mm", A$idx, C$idx), lines = rbind(cc_seg(A$idx, A$price, B$idx, B$price, "#0f766e"), cc_seg(C$idx, C$price, e, tg, "#0f766e", "dash")))) } }
  # ---- round numbers
  stp <- { x <- 2 * a; k <- 10^floor(log10(x)); m <- x / k; (if (m <= 1) 1 else if (m <= 2) 2 else if (m <= 5) 5 else 10) * k }
  lvl <- round(ce / stp) * stp; near <- pv[abs(pv$price - lvl) <= 0.3 * a, , drop = FALSE]
  if (nrow(near) >= 3 && abs(ce - lvl) <= 2 * a) { dir <- if (ce >= lvl) 1L else -1L
    add(cc_occ("round_number", min(near$idx), e, ce, lvl - dir * 0.5 * a, NA, sprintf("Price keeps reacting at the round number %s (%d swings)", format(lvl), nrow(near)), level = lvl,
               dir = NA_integer_, sig = paste("rn", lvl), marks = if (isTRUE(ctx$v2)) near$idx else NULL, lines = cc_seg(min(near$idx), lvl, e, lvl, "#a16207", "dot"))) }
  # ---- traps and retests at levels with 2+ swings
  lv2 <- c(lapply(cc_clusters(H$idx, H$price, 0.5 * a, 2), function(k) c(k, list(kind = "H"))), lapply(cc_clusters(Lw$idx, Lw$price, 0.5 * a, 2), function(k) c(k, list(kind = "L"))))
  for (k in lv2) { lv <- k$level; t <- max(k$idx); if (t >= e - 3) next; seg <- (t + 1):e
    if (k$kind == "H") { ab <- which(c[seg] > lv + 0.2 * a)
      if (length(ab)) { kb <- seg[ab[1]]; back <- if (kb < e) which(c[(kb + 1):min(e, kb + 3)] < lv) else integer(0)
        if (kb >= e - 5 && length(back) && ce < lv) { th <- max(h[kb:e]); f <- cc_fill_dflt(-1L, ce, th + 0.2 * a, NA, a)
          add(cc_occ("failed_breakout", k$idx[1], e, ce, f$invalid, f$target, sprintf("Broke above %.2f and fell back", lv), level = lv, dir = -1L, sig = paste("fbo", k$idx[1], kb), marks = if (isTRUE(ctx$v2)) c(k$idx, kb) else NULL, lines = cc_seg(k$idx[1], lv, e, lv, "#dc2626", "dash"))) } } }
    if (k$kind == "L") { bl <- which(c[seg] < lv - 0.2 * a)
      if (length(bl)) { kb <- seg[bl[1]]; back <- if (kb < e) which(c[(kb + 1):min(e, kb + 3)] > lv) else integer(0)
        if (kb >= e - 5 && length(back) && ce > lv) { tl2 <- min(l[kb:e]); f <- cc_fill_dflt(1L, ce, tl2 - 0.2 * a, NA, a)
          add(cc_occ("failed_breakdown", k$idx[1], e, ce, f$invalid, f$target, sprintf("Broke below %.2f and came back", lv), level = lv, dir = 1L, sig = paste("fbd", k$idx[1], kb), marks = if (isTRUE(ctx$v2)) c(k$idx, kb) else NULL, lines = cc_seg(k$idx[1], lv, e, lv, "#16a34a", "dash"))) } } }
    # retest: broken 3-20 candles ago, moved >= 1 ATR away, now back at the level from the new side
    for (dir in c(1L, -1L)) { brk <- if (dir > 0) which(c[seg] > lv + 0.3 * a) else which(c[seg] < lv - 0.3 * a); if (!length(brk)) next
      kb <- seg[brk[1]]; if (kb > e - 3 || kb < e - 20) next; after <- kb:e
      if (dir > 0 && (max(h[after]) - lv < a || any(c[after] < lv - 0.1 * a) || abs(l[e] - lv) > 0.3 * a)) next
      if (dir < 0 && (lv - min(l[after]) < a || any(c[after] > lv + 0.1 * a) || abs(h[e] - lv) > 0.3 * a)) next
      ext <- if (dir > 0) max(h[after]) else min(l[after])
      for (key in c("throwback", "pullback_breakout"))
        add(cc_occ(key, k$idx[1], e, ce, lv - dir * 0.5 * a, ext, sprintf("Back at the broken level %.2f from the %s side", lv, if (dir > 0) "upper" else "lower"), level = lv, dir = dir,
                   sig = paste(key, k$idx[1], kb), marks = if (isTRUE(ctx$v2)) c(k$idx, kb, e) else NULL, lines = cc_seg(k$idx[1], lv, e, lv, "#0ea5e9", "dash"))) } }
  # ---- harmonic & Elliott (swing sequences; the last swing may still be provisional)
  seqp <- function(k) if (nrow(pv) >= k) utils::tail(pv, k) else NULL
  Q <- seqp(4)
  if (!is.null(Q) && Q$idx[4] >= e - 10) { A <- Q$price[1]; B <- Q$price[2]; C <- Q$price[3]; D <- Q$price[4]; AB <- abs(A - B); BC <- abs(C - B); CD <- abs(C - D)
    if (AB > 2 * a && BC / AB >= 0.382 && BC / AB <= 0.886 && CD / AB >= 0.85 && CD / AB <= 1.15) {
      if (identical(Q$type, c("H", "L", "H", "L"))) add(cc_occ("abcd_bull", Q$idx[1], e, ce, D - 0.5 * a, D + 0.618 * (A - D), sprintf("CD = %.0f%% of AB, BC = %.0f%% retracement", 100 * CD / AB, 100 * BC / AB),
                                                          dir = 1L, sig = paste("abcd", Q$idx[1]), conf = 55, lines = cc_seg(Q$idx[-4], Q$price[-4], Q$idx[-1], Q$price[-1], "#0f766e")))
      if (identical(Q$type, c("L", "H", "L", "H"))) add(cc_occ("abcd_bear", Q$idx[1], e, ce, D + 0.5 * a, D - 0.618 * (D - A), sprintf("CD = %.0f%% of AB, BC = %.0f%% retracement", 100 * CD / AB, 100 * BC / AB),
                                                          dir = -1L, sig = paste("abcd", Q$idx[1]), conf = 55, lines = cc_seg(Q$idx[-4], Q$price[-4], Q$idx[-1], Q$price[-1], "#0f766e"))) } }
  Q <- seqp(6)
  if (!is.null(Q) && Q$idx[6] >= e - 10) { p <- Q$price
    if (identical(Q$type, c("L", "H", "L", "H", "L", "H")) && p[2] < p[4] && p[4] < p[6]) { d <- c(p[2] - p[1], p[4] - p[3], p[6] - p[5]); r <- c((p[2] - p[3]) / d[1], (p[4] - p[5]) / d[2])
      if (all(d > 1.5 * a) && all(d[-1] / d[-3] >= 0.7 & d[-1] / d[-3] <= 1.4) && all(r >= 0.5 & r <= 0.8))
        add(cc_occ("three_drives_up", Q$idx[1], e, ce, p[6] + 0.3 * a, p[5], "Three rising drives of similar size: exhaustion", dir = -1L, conf = 50, sig = paste("3du", Q$idx[1]),
                   lines = cc_seg(Q$idx[-6], p[-6], Q$idx[-1], p[-1], "#dc2626"))) }
    if (identical(Q$type, c("H", "L", "H", "L", "H", "L")) && p[2] > p[4] && p[4] > p[6]) { d <- c(p[1] - p[2], p[3] - p[4], p[5] - p[6]); r <- c((p[3] - p[2]) / d[1], (p[5] - p[4]) / d[2])
      if (all(d > 1.5 * a) && all(d[-1] / d[-3] >= 0.7 & d[-1] / d[-3] <= 1.4) && all(r >= 0.5 & r <= 0.8))
        add(cc_occ("three_drives_down", Q$idx[1], e, ce, p[6] - 0.3 * a, p[5], "Three falling drives of similar size: exhaustion", dir = 1L, conf = 50, sig = paste("3dd", Q$idx[1]),
                   lines = cc_seg(Q$idx[-6], p[-6], Q$idx[-1], p[-1], "#16a34a"))) } }
  Q <- seqp(5)
  if (!is.null(Q) && Q$idx[5] >= e - 10) { p <- Q$price; x <- Q$idx
    line <- function(i, j, at) p[i] + (p[j] - p[i]) / (x[j] - x[i]) * (at - x[i])
    if (identical(Q$type, c("L", "H", "L", "H", "L")) && p[3] < p[1] && p[4] < p[2] && p[4] > p[1] && p[5] < p[3] && p[5] < line(1, 3, x[5])) {
      s13 <- (p[3] - p[1]) / (x[3] - x[1]); s24 <- (p[4] - p[2]) / (x[4] - x[2])
      if (s24 < s13) add(cc_occ("wolfe_bull", x[1], e, ce, p[5] - 0.5 * a, line(1, 4, x[5] + (x[5] - x[4])), "Five swings in a converging wedge, point 5 below the 1-3 line", dir = 1L, conf = 45, marks = if (isTRUE(ctx$v2)) x else NULL,
                                sig = paste("wolfe", x[1]), lines = rbind(cc_seg(x[1], p[1], x[5], line(1, 3, x[5]), "#16a34a"), cc_seg(x[2], p[2], x[5], line(2, 4, x[5]), "#16a34a"), cc_seg(x[1], p[1], e, line(1, 4, e), "#16a34a", "dash")))) }
    if (identical(Q$type, c("H", "L", "H", "L", "H")) && p[3] > p[1] && p[4] > p[2] && p[4] < p[1] && p[5] > p[3] && p[5] > line(1, 3, x[5])) {
      s13 <- (p[3] - p[1]) / (x[3] - x[1]); s24 <- (p[4] - p[2]) / (x[4] - x[2])
      if (s24 > s13) add(cc_occ("wolfe_bear", x[1], e, ce, p[5] + 0.5 * a, line(1, 4, x[5] + (x[5] - x[4])), "Five swings in a converging wedge, point 5 above the 1-3 line", dir = -1L, conf = 45, marks = if (isTRUE(ctx$v2)) x else NULL,
                                sig = paste("wolfe", x[1]), lines = rbind(cc_seg(x[1], p[1], x[5], line(1, 3, x[5]), "#dc2626"), cc_seg(x[2], p[2], x[5], line(2, 4, x[5]), "#dc2626"), cc_seg(x[1], p[1], e, line(1, 4, e), "#dc2626", "dash")))) } }
  Q <- if (nrow(pc) >= 5) utils::tail(pc, 5) else NULL
  if (!is.null(Q) && Q$idx[5] >= e - 25) { p <- Q$price
    if (identical(Q$type, c("L", "H", "L", "H", "L")) && p[3] > p[1] && p[4] > p[2] && p[5] > p[2]) { w <- c(p[2] - p[1], p[4] - p[3])
      if (w[2] >= w[1] * 0.9 && ce > p[5] && ce < p[5] + w[1] + w[2])   # wave 3 not the shortest (wave 5 still forming), no overlap
        add(cc_occ("elliott_up", Q$idx[1], e, ce, p[5] - 0.2 * a, p[5] + w[1], "Waves 1-4 counted; price in wave 5", dir = 1L, conf = 40, sig = paste("ew", Q$idx[1]),
                   lines = cc_seg(Q$idx[-5], p[-5], Q$idx[-1], p[-1], "#0f766e"))) }
    if (identical(Q$type, c("H", "L", "H", "L", "H")) && p[3] < p[1] && p[4] < p[2] && p[5] < p[2]) { w <- c(p[1] - p[2], p[3] - p[4])
      if (w[2] >= w[1] * 0.9 && ce < p[5] && ce > p[5] - w[1] - w[2])
        add(cc_occ("elliott_down", Q$idx[1], e, ce, p[5] + 0.2 * a, p[5] - w[1], "Waves 1-4 counted; price in wave 5", dir = -1L, conf = 40, sig = paste("ew", Q$idx[1]),
                   lines = cc_seg(Q$idx[-5], p[-5], Q$idx[-1], p[-1], "#0f766e"))) } }
  Q <- seqp(5)
  if (!is.null(Q) && Q$idx[5] >= e - 10) { p <- Q$price; S <- p[1]; E <- p[2]; A <- p[3]; B <- p[4]; C <- p[5]; leg <- E - S
    if (abs(leg) >= 5 * a) { dA <- E - A; rB <- (B - A) / dA; rC <- (B - C) / dA
      if (sign(dA) == sign(leg) && rB >= 0.38 && rB <= 0.79 && rC >= 0.62 && rC <= 1.62 && sign(E - C) == sign(leg) && sign(A - C) == sign(leg)) { dir <- if (leg > 0) 1L else -1L
        add(cc_occ("elliott_abc", Q$idx[1], e, ce, C - dir * 0.3 * a, E, "A-B-C correction against the prior leg: the trend may resume", dir = dir, conf = 40, sig = paste("abc", Q$idx[2]), marks = if (isTRUE(ctx$v2)) Q$idx else NULL,
                   lines = cc_seg(Q$idx[2:4], p[2:4], Q$idx[3:5], p[3:5], "#0f766e"))) } } }
  # ---- flags and pennants
  for (p in (e - 16):(e - 5)) { if (p < 10) next
    for (side in c(1, -1)) { s0 <- (p - 8):p; ext <- if (side > 0) which.max(h[s0]) else which.min(l[s0]); if (s0[ext] != p) next
      st <- if (side > 0) s0[which.min(l[s0])] else s0[which.max(h[s0])]; if (st >= p) next
      pole <- if (side > 0) h[p] - l[st] else h[st] - l[p]; if (pole < 4 * a) next
      fl <- (p + 1):e; if (length(fl) < 5 || length(fl) > 15) next
      fh <- max(h[fl]); fln <- min(l[fl])
      if (side > 0 && (fh > h[p] + 0.2 * a || h[p] - fln > 0.5 * pole || fh - fln > 0.5 * pole)) next
      if (side < 0 && (fln < l[p] - 0.2 * a || fh - l[p] > 0.5 * pole || fh - fln > 0.5 * pole)) next
      slp <- stats::coef(stats::lm(c[fl] ~ fl))[2] / a
      hs_ <- stats::coef(stats::lm(h[fl] ~ fl))[2]; ls_ <- stats::coef(stats::lm(l[fl] ~ fl))[2]
      key <- if (hs_ < 0 && ls_ > 0) "pennant" else if (side > 0 && slp <= 0.05) "bull_flag" else if (side < 0 && slp >= -0.05) "bear_flag" else NA
      if (is.na(key)) next
      inv <- if (side > 0) fln - 0.2 * a else fh + 0.2 * a; tg <- if (side > 0) fh + pole else fln - pole
      if (side * (ce - inv) <= 0) next
      add(cc_occ(key, st, e, ce, inv, tg, sprintf("Pole %.1f ATR, %d-candle %s", pole / a, length(fl), if (key == "pennant") "pennant" else "flag"), dir = as.integer(side),
                 sig = paste(key, st), lines = rbind(cc_seg(st, if (side > 0) l[st] else h[st], p, if (side > 0) h[p] else l[p], "#0f766e"),
                                                    cc_seg(p + 1, fh, e, fh, "#0f766e", "dot"), cc_seg(p + 1, fln, e, fln, "#0f766e", "dot"))))
      break } }
  out
}

# =========================================================================================================
# SCAN: everything, now and through the history, with measured outcomes
# =========================================================================================================
cc_occ_df <- function(lst) {
  if (!length(lst)) return(data.frame(key = character(0), i0 = integer(0), i1 = integer(0), entry = numeric(0), invalid = numeric(0), target = numeric(0),
                                      dir = integer(0), status = character(0), note = character(0), conf = numeric(0), atr_default = logical(0), sig = character(0), level = numeric(0)))
  data.frame(key = vapply(lst, `[[`, "", "key"), i0 = vapply(lst, `[[`, 0L, "i0"), i1 = vapply(lst, `[[`, 0L, "i1"),
             entry = vapply(lst, function(o) as.numeric(o$entry), 0), invalid = vapply(lst, function(o) as.numeric(o$invalid), 0), target = vapply(lst, function(o) as.numeric(o$target), 0),
             dir = vapply(lst, function(o) as.integer(o$dir), 0L), status = vapply(lst, `[[`, "", "status"), note = vapply(lst, `[[`, "", "note"),
             conf = vapply(lst, function(o) as.numeric(o$conf), 0), atr_default = vapply(lst, function(o) isTRUE(o$atr_default), TRUE), sig = vapply(lst, `[[`, "", "sig"),
             level = vapply(lst, function(o) as.numeric(o$level %||% NA)[1], 0), stringsAsFactors = FALSE)
}
# target first / stop first / still open within `horizon` candles after the signal (the same candle touching both = stop)
cc_outcomes <- function(df, ctx, horizon) {
  n <- ctx$n; h <- ctx$h; l <- ctx$l
  res <- vapply(seq_len(nrow(df)), function(k) { r <- df[k, ]; d <- r$dir
    if (is.na(d) || !is.finite(r$invalid) || !is.finite(r$target) || d * (r$target - r$entry) <= 0 || d * (r$entry - r$invalid) <= 0) return("n/a")
    if (r$i1 >= n) return("open"); w <- (r$i1 + 1):min(n, r$i1 + horizon)
    hs <- if (d > 0) l[w] <= r$invalid else h[w] >= r$invalid; ht <- if (d > 0) h[w] >= r$target else l[w] <= r$target
    fs <- which(hs)[1]; ft <- which(ht)[1]
    if (is.na(fs) && is.na(ft)) { if (r$i1 + horizon > n) "open" else "timeout" } else if (is.na(ft) || (!is.na(fs) && fs <= ft)) "stop" else "target" }, "")
  df$outcome <- res
  df$rr <- ifelse(is.finite(df$target) & is.finite(df$invalid), abs(df$target - df$entry) / pmax(abs(df$entry - df$invalid), 1e-12), NA_real_)
  df
}
cc_key_stats <- function(hist) {
  if (!nrow(hist)) return(data.frame(key = character(0), n = integer(0), targets = integer(0), stops = integer(0), timeouts = integer(0), win_pct = numeric(0), exp_r = numeric(0)))
  do.call(rbind, lapply(split(hist, hist$key), function(d) { t <- sum(d$outcome == "target"); s <- sum(d$outcome == "stop"); to <- sum(d$outcome == "timeout")
    res <- d[d$outcome %in% c("target", "stop"), , drop = FALSE]
    data.frame(key = d$key[1], n = nrow(d), targets = t, stops = s, timeouts = to, win_pct = if (t + s) 100 * t / (t + s) else NA_real_,
               exp_r = if (nrow(res)) mean(ifelse(res$outcome == "target", res$rr, -1)) else NA_real_, stringsAsFactors = FALSE) }))
}

# show_from = first candle shown (earlier candles are warm-up / history)
cc_scan <- function(b, minutes = 15, settings = list(), daily = NULL, show_from = 1L, hist_step = NULL, progress = NULL) {
  ctx <- cc_ctx(b, minutes, settings, daily); n <- ctx$n
  if (n < 40) stop("Only ", n, " candles: at least 40 are needed (choose a longer history or a smaller candle).")
  vec <- c(cc_det_candles(ctx), cc_det_gaps(ctx), cc_det_spikes(ctx), cc_det_indicators(ctx), cc_det_divergence(ctx), cc_det_strategies(ctx))
  if (!is.null(progress)) progress(0.4)
  # pivot detectors through the history (sampled) and at the last candle
  step <- if (is.null(hist_step)) max(1L, as.integer(floor((n - 60) / 220))) else hist_step
  es <- unique(c(seq(min(60L, n), n, by = step), n)); piv <- list(); seen <- character(0); last_list <- list()
  # structures are looked for on two swing scales: clear swings (1.5 ATR) and smaller ones (1 ATR), as chart readers
  # do (the original tab's engine also anchors lines on small turns). A shape found only on the small scale gets a lower
  # confidence; one found on both is kept once (same key, best instance).
  ctx_s <- ctx; ctx_s$zz <- ctx$zz1
  piv_at <- function(e) { a <- cc_det_pivot_at(ctx, e); b <- lapply(cc_det_pivot_at(ctx_s, e), function(o) { o$conf <- o$conf - 10; o$sig <- paste0(o$sig, "~s"); o$note <- paste0(o$note, " (smaller swings)"); o })
    fam <- function(k) cc_catalog$family[match(k, cc_catalog$key)]
    have <- vapply(a, `[[`, "", "key")   # the clear swings win: a smaller-swing shape of the same family (e.g. an up-trend
    c(a, Filter(function(o) !(o$key %in% have) && !(fam(o$key) %in% fam(have)), b)) }   # inside a bigger down-trend) is left out
  for (e in es) { r <- tryCatch(piv_at(e), error = function(err) { cat("[C.C patterns] at candle", e, ":", conditionMessage(err), "\n"); list() })
    if (e == n) last_list <- r
    for (o in r) if (!(o$sig %in% seen)) { seen <- c(seen, o$sig); piv[[length(piv) + 1]] <- o } }
  if (!is.null(progress)) progress(0.8)
  all_occ <- c(vec, piv)
  hist <- cc_outcomes(cc_occ_df(all_occ), ctx, ctx$horizon)
  stats <- cc_key_stats(hist[hist$outcome != "n/a", , drop = FALSE])
  # NOW: vector signals in their recency window and not cancelled since; pivot patterns alive at the last candle
  cur <- list()
  for (o in vec) { rec <- cc_catalog$recency[cc_catalog$key == o$key]; if (!length(rec)) next
    if (o$i1 < n - rec + 1) next
    if (!is.na(o$dir) && o$i1 < n && is.finite(o$invalid)) { w <- (o$i1 + 1):n
      if (any(if (o$dir > 0) ctx$c[w] < o$invalid else ctx$c[w] > o$invalid)) next
      if (is.finite(o$target) && any(if (o$dir > 0) ctx$h[w] >= o$target else ctx$l[w] <= o$target)) next }
    cur[[length(cur) + 1]] <- o }
  cur <- c(cur, last_list)
  # state rows must hold on the LAST candle (not just have started recently)
  d <- ctx$ind; L1 <- n
  state_now <- list(ma_stack_bull = isTRUE(d$ema20[L1] > d$ema50[L1] && d$ema50[L1] > d$ema200[L1]), ma_stack_bear = isTRUE(d$ema20[L1] < d$ema50[L1] && d$ema50[L1] < d$ema200[L1]),
                    rsi_ob = isTRUE(d$rsi[L1] > 70), rsi_os = isTRUE(d$rsi[L1] < 30), adx_strong = isTRUE(d$adx[L1] >= ctx$adx_trend), adx_weak = isTRUE(d$adx[L1] <= ctx$adx_range),
                    keltner_squeeze = isTRUE(d$bb_up[L1] < d$kc_up[L1] && d$bb_dn[L1] > d$kc_dn[L1]))
  cur <- Filter(function(o) is.null(state_now[[o$key]]) || isTRUE(state_now[[o$key]]), cur)
  for (k in names(state_now)) if (isTRUE(state_now[[k]]) && !any(vapply(cur, function(o) o$key == k, TRUE))) {   # state still true but started long ago
    dr <- cc_dir_of(cc_catalog$bias[cc_catalog$key == k]); f <- if (is.na(dr)) list(invalid = NA, target = NA, atr_default = FALSE) else cc_fill_dflt(dr, ctx$c[n], NA, NA, ctx$a[n])
    cur[[length(cur) + 1]] <- cc_occ(k, n, n, ctx$c[n], f$invalid, f$target, "Still true on the last candle", dir = dr, atr_default = f$atr_default) }
  # status at the right edge, the same for every pattern (as the original tab's rules): the closes AFTER the candle that
  # completed it, against that candle's close, in ATR in the pattern's direction:
  #   >= +0.3 confirmed | <= -0.3 failed (dropped: it is no longer a reason) | otherwise pending (0-1 candle after) or forming
  # Patterns whose own rule already says confirmed / early / broke keep it.
  cur <- lapply(cur, function(o) {
    if (identical(cc_catalog$kind[match(o$key, cc_catalog$key)], "state")) { o$status <- "active"; return(o) }   # a condition true on the last candle
    if (o$status %in% c("confirmed", "early") || grepl("^broke", o$status) || is.na(o$dir)) return(o)
    after <- if (o$i1 < n) (o$i1 + 1):n else integer(0)
    if (!length(after)) { o$status <- "pending (completed on the last candle)"; return(o) }
    mv <- (mean(ctx$c[after[seq_len(min(4, length(after)))]]) - ctx$c[o$i1]) / ctx$a[o$i1] * o$dir
    o$status <- if (mv >= 0.3) "confirmed" else if (mv <= -0.3) "failed" else if (length(after) < 2) "pending" else "forming"
    o$conf <- o$conf + if (o$status == "confirmed") 15 else 0; o })
  cur <- Filter(function(o) o$status != "failed", cur)
  # best instance per key
  if (length(cur)) { sc <- vapply(cur, function(o) o$i1 * 1000 + o$conf, 0); cur <- cur[order(-sc)]; cur <- cur[!duplicated(vapply(cur, `[[`, "", "key"))] }
  # regime
  adx_n <- d$adx[n]; regime <- if (!is.finite(adx_n)) "UNKNOWN" else if (adx_n >= ctx$adx_trend) "TREND" else if (adx_n <= ctx$adx_range) "RANGE" else "MIXED"
  cur_df <- cc_occ_df(cur)
  if (nrow(cur_df)) {
    m <- match(cur_df$key, cc_catalog$key)
    cur_df$label <- cc_catalog$label[m]; cur_df$step <- cc_catalog$step[m]; cur_df$bias <- cc_catalog$bias[m]; cur_df$family <- cc_catalog$family[m]
    cur_df$regime_tag <- cc_catalog$regime[m]; cur_df$kind <- cc_catalog$kind[m]
    cur_df$in_regime <- cur_df$regime_tag == "any" | (cur_df$regime_tag == "trend" & regime == "TREND") | (cur_df$regime_tag == "range" & regime == "RANGE")
    st <- stats[match(cur_df$key, stats$key), , drop = FALSE]
    cur_df$hist_n <- ifelse(is.na(st$n), 0L, st$targets + st$stops); cur_df$hist_win <- st$win_pct; cur_df$hist_exp_r <- st$exp_r
    cur_df$candles_ago <- n - cur_df$i1
    cur_df$dir_eff <- ifelse(is.na(cur_df$dir), NA_integer_, cur_df$dir)
    # strength 0-100, strongest first: measured record on this market (shrunk towards 50% when the sample is small),
    # expectancy in R, in the current regime or not, status, and the rule's own confidence
    st_ <- stats[match(cur_df$key, stats$key), , drop = FALSE]
    tg <- ifelse(is.na(st_$targets), 0, st_$targets); sp <- ifelse(is.na(st_$stops), 0, st_$stops)
    win_s <- (tg + 5) / (tg + sp + 10)                                   # 5 imaginary wins + 5 losses: n=1 cannot look like 100%
    ex <- ifelse(is.finite(cur_df$hist_exp_r), pmax(-1, pmin(1, cur_df$hist_exp_r)), 0) * pmin(1, (tg + sp) / 20)
    stat_w <- ifelse(cur_df$status == "confirmed", 1, ifelse(cur_df$status == "active", 0.8, ifelse(grepl("^pending|^early", cur_df$status), 0.6, 0.4)))
    cur_df$strength <- round(100 * pmax(0, pmin(1, 0.55 * win_s + 0.15 * (ex + 1) / 2 + 0.15 * stat_w + 0.10 * ifelse(cur_df$in_regime, 1, 0) + 0.05 * pmin(1, cur_df$conf / 100))))
    cur_df$strength[is.na(cur_df$dir)] <- pmin(cur_df$strength[is.na(cur_df$dir)], 50)   # context rows (no side) never top the list
    cur_df <- cur_df[order(-cur_df$strength, cur_df$step), , drop = FALSE]
  }
  list(ctx = ctx, n = n, show_from = show_from, regime = regime, adx = adx_n, current = cur, current_df = cur_df, hist = hist, stats = stats,
       tally = cc_tally(cur_df), at = Sys.time())
}

# Facts tally: one vote per family and side, only rows in regime, with a direction, and not context rows.
# Weight = measured win rate on this market when 8+ resolved cases exist, else 0.5. Never a recommendation.
cc_tally <- function(cur_df) {
  if (is.null(cur_df) || !nrow(cur_df)) return(list(bull = 0, bear = 0, n_bull = 0L, n_bear = 0L, text = "No pattern is active at the last candle."))
  d <- cur_df[cur_df$in_regime & !is.na(cur_df$dir) & cur_df$kind != "state", , drop = FALSE]
  if (!nrow(d)) return(list(bull = 0, bear = 0, n_bull = 0L, n_bear = 0L, text = "Active patterns are context only (no side) or outside the current regime."))
  d$w <- ifelse(d$hist_n >= 8 & is.finite(d$hist_win), d$hist_win / 100, 0.5)
  d <- d[order(-d$w), , drop = FALSE]; d <- d[!duplicated(paste(d$family, d$dir)), , drop = FALSE]
  bu <- sum(d$w[d$dir > 0]); be <- sum(d$w[d$dir < 0])
  list(bull = bu, bear = be, n_bull = sum(d$dir > 0), n_bear = sum(d$dir < 0),
       text = sprintf("In regime: %d bullish famil%s (weight %.2f) and %d bearish famil%s (weight %.2f). Weights are the measured win rates on this market where 8+ cases exist, else 0.5.",
                      sum(d$dir > 0), if (sum(d$dir > 0) == 1) "y" else "ies", bu, sum(d$dir < 0), if (sum(d$dir < 0) == 1) "y" else "ies", be))
}

# catalogue coverage table: every matrix row, found now or not, and its record on this market
cc_coverage <- function(scan) {
  cat_ <- cc_catalog; st <- scan$stats; cd <- scan$current_df
  m <- match(cat_$key, st$key)
  found <- table(factor(scan$hist$key, levels = cat_$key))
  data.frame(Step = cat_$step, Pattern = cat_$label, Bias = cat_$bias, Regime = cat_$regime,
             `Active now` = ifelse(cat_$key %in% (if (is.null(cd) || !nrow(cd)) character(0) else cd$key), "YES", ""),
             `Found in history` = as.integer(found[cat_$key]), `Target first` = ifelse(is.na(st$targets[m]), 0L, st$targets[m]),
             `Stop first` = ifelse(is.na(st$stops[m]), 0L, st$stops[m]), `Win %` = round(st$win_pct[m], 0), `Expectancy (R)` = round(st$exp_r[m], 2),
             Rule = cat_$rule, check.names = FALSE, stringsAsFactors = FALSE)
}

# ---- Claude's second reading (optional): it may confirm/question the R findings and name catalogue patterns R missed.
# Its additions are shown apart, labelled "Claude only (not confirmed by the rules)", never counted in the tally or stats,
# and refused when they do not reach the last 10 candles or their stop/target sit on the wrong side of the price.
cc_claude_prompt <- function(scan, label, candle_label, max_rows = 150) {
  ctx <- scan$ctx; n <- ctx$n; i0 <- max(1, n - max_rows + 1); ix <- i0:n; d <- ctx$ind
  f <- function(x) ifelse(is.finite(x), formatC(x, format = "f", digits = 4), "NA")
  bars <- paste(sprintf("%d,%s,%s,%s,%s,%s", ix - i0 + 1, format(ctx$b$time[ix], "%d/%m %H:%M", tz = "Europe/London"), f(ctx$o[ix]), f(ctx$h[ix]), f(ctx$l[ix]), f(ctx$c[ix])), collapse = "\n")
  indt <- paste(sprintf("%d,%s,%s,%s,%s,%s,%s,%s", ix - i0 + 1, f(d$ema20[ix]), f(d$ema50[ix]), f(d$ema200[ix]), f(d$rsi[ix]), f(d$macd_hist[ix]), f(d$adx[ix]), f(d$atr[ix])), collapse = "\n")
  found <- if (nrow(scan$current_df)) paste(sprintf("- %s (%s, %s): %s; stop side %s, target %s", scan$current_df$key, scan$current_df$label, scan$current_df$status, scan$current_df$note,
                                                   f(scan$current_df$invalid), f(scan$current_df$target)), collapse = "\n") else "(none)"
  paste0("You check a rule-based chart scan for a trading student. Market: ", label, ", ", candle_label, " candles from Capital.com (mid prices). Candle ", n - i0 + 1, " is the last.\n\n",
         "CANDLES (no,time_uk,open,high,low,close):\n", bars, "\n\nINDICATORS computed in R (no,ema20,ema50,ema200,rsi14,macd_hist,adx14,atr14):\n", indt,
         "\n\nThe R rules found these patterns alive at the last candle:\n", found, "\n\nCATALOGUE keys you may use:\n", paste(sprintf("%s = %s", cc_catalog$key, cc_catalog$label), collapse = "; "),
         "\n\nTASK: (1) For each R finding, say 'agree' or 'doubt' with one short reason. (2) List any catalogue pattern R missed that is alive in the last 10 candles, with candle numbers, the level that cancels it and its target taken from the structure. Use the indicator numbers given; do not estimate your own. Do not suggest a trade, a side, or a probability. An empty list is a valid answer.\n",
         'Reply with JSON only: {"checks":[{"key":"...","verdict":"agree|doubt","reason":"..."}],"additions":[{"key":"...","from_candle":0,"to_candle":0,"invalid":0,"target":0,"note":"..."}]}')
}
cc_claude_parse <- function(txt, scan, max_rows = 150) {
  j <- tryCatch({ s <- sub("^[^{]*", "", txt); s <- sub("[^}]*$", "", s); jsonlite::fromJSON(s, simplifyVector = FALSE) }, error = function(e) NULL)
  if (is.null(j)) return(list(checks = data.frame(), additions = data.frame(), refused = 0L))
  n <- scan$n; i0 <- max(1, n - max_rows + 1); last <- scan$ctx$c[n]
  ck <- if (length(j$checks)) do.call(rbind, lapply(j$checks, function(z) data.frame(key = cc_chr(z$key), verdict = cc_chr(z$verdict), reason = cc_chr(z$reason), stringsAsFactors = FALSE))) else data.frame()
  adds <- list(); refused <- 0L
  for (z in j$additions %||% list()) { key <- cc_chr(z$key); row <- cc_catalog[cc_catalog$key == key, , drop = FALSE]
    t1 <- cc_num(z$to_candle) + i0 - 1; inv <- cc_num(z$invalid); tg <- cc_num(z$target); dr <- cc_dir_of(row$bias[1])
    ok <- nrow(row) == 1 && is.finite(t1) && t1 >= n - 9 && t1 <= n && (is.na(dr) || ((!is.finite(inv) || dr * (last - inv) > 0) && (!is.finite(tg) || dr * (tg - last) > 0)))
    if (!ok) { refused <- refused + 1L; next }
    adds[[length(adds) + 1]] <- data.frame(key = key, label = row$label, bias = row$bias, from = cc_num(z$from_candle) + i0 - 1, to = t1, invalid = inv, target = tg, note = cc_chr(z$note), stringsAsFactors = FALSE) }
  list(checks = ck, additions = if (length(adds)) do.call(rbind, adds) else data.frame(), refused = refused)
}

