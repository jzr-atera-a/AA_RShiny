# R/utils_patterns.R
# Price chart + pattern identification for the Trades tab: the Step 1 and Step 2 pattern sets of the full app, judged
# with the course rules (LAT 1.2 Support & Resistance, 1.3 Trends & Trendlines, 1.3 Channels) and only where they matter
# for a decision now: at the right-hand end of the chart.
# Step 1:
#   Support & Resistance  : Support level, Resistance level
#   Trend lines           : Uptrend line, Downtrend line, Broken uptrend line, Broken downtrend line
#   Countertrend lines    : Broken countertrend line (uptrend continues / downtrend continues)
#   Channels              : Bullish (ascending) channel, Bearish (descending) channel
#   Candlesticks          : Shooting Star, Dark Cloud Cover, Inverted Hammer, Long-Legged Doji in a downtrend, Dragonfly Doji,
#                           Hammer at support, Bearish Engulfing, Piercing Pattern, Hanging Man
#   Breakout              : Marubozu breakout (bullish / bearish)
# Step 2:
#   Fibonacci             : retracement to 50% / 61.8% (trend resumes), 100% expansion target
#   Price patterns        : symmetrical / ascending / descending triangle, rising / falling wedge, bullish / bearish flag,
#                           pennant, double top, double bottom, head & shoulders, inverse head & shoulders
# Course rules applied: S/R needs 3+ bounces, more bounces than breaks and a bounce as the latest interaction; a trend line
# needs 3+ pivot touches; a channel is drawn parallel to a valid trend line and contains the price. Recency: candlesticks
# only on the last 5 candles; a broken line only if the break is recent and still holding; Step 2 patterns must reach the
# last part of the chart (still forming, or broken out in the last few candles).
# Detection is rule based (no AI): repeatable, explainable, free. Every candidate gets a score 0-100 from its quality,
# how recent it is and whether the following candles confirmed it; the best instance of each type is kept and the
# top 5 by score are offered on the chart.
# Decision rules (Pattern Rulebook v2: Dow Theory, Bulkowski, TrendSpider, Fidelity, Britannica; Oct 2026):
#   * only multi-candle structures that run up to the LAST candle are ranked: single-candle signals (candlesticks) and
#     anything finished earlier in the chart are left out (old levels still count as support / resistance);
#   * swings count only when significant (1.5 ATR); two lows / highs within 0.5 ATR are the same level;
#   * trend (Dow): starts with a higher low + a close above the previous high (mirror for down) and is followed from that
#     start to the last candle; a role-reversal level (old support now resistance) is the retest of a recent break;
#   * trend lines: 3+ touches, not steeper than 0.6 ATR per candle; triangles 5+ turning points; double tops: peaks within
#     1 ATR, a valley 3+ ATR deep, 4+ candles apart; head & shoulders: shoulders level and evenly spaced; flags: a pole of
#     4+ ATR, then 5-15 candles in a parallel channel (4 = forming);
#   * every pattern carries the level that cancels it (invalid) and its measured target, for the stop and the limit.

tr_pat_catalog <- data.frame(
  key = c("support", "resistance", "uptrend_line", "downtrend_line", "broken_uptrend", "broken_downtrend", "ctr_break_up", "ctr_break_down",
          "bull_channel", "bear_channel", "shooting_star", "dark_cloud", "inverted_hammer", "long_legged_doji", "dragonfly_doji",
          "hammer_support", "bearish_engulfing", "piercing", "hanging_man", "marubozu_bull", "marubozu_bear",
          "fib_retracement", "fib_expansion", "sym_triangle", "asc_triangle", "desc_triangle", "rising_wedge", "falling_wedge",
          "bull_flag", "bear_flag", "pennant", "double_top", "double_bottom", "head_shoulders", "inv_head_shoulders",
          "dow_up", "dow_down", "sup_to_res", "res_to_sup"),
  label = c("Support level", "Resistance level", "Uptrend line", "Downtrend line", "Broken uptrend line", "Broken downtrend line",
            "Broken countertrend line (uptrend continues)", "Broken countertrend line (downtrend continues)", "Bullish (ascending) channel",
            "Bearish (descending) channel", "Shooting Star", "Dark Cloud Cover", "Inverted Hammer", "Long-Legged Doji in a downtrend",
            "Dragonfly Doji", "Hammer at support", "Bearish Engulfing", "Piercing Pattern", "Hanging Man", "Bullish Marubozu breakout", "Bearish Marubozu breakout",
            "Fibonacci retracement", "Fibonacci 100% expansion", "Symmetrical triangle", "Ascending triangle", "Descending triangle", "Rising wedge", "Falling wedge",
            "Bullish flag", "Bearish flag", "Pennant", "Double top", "Double bottom", "Head & Shoulders", "Inverse Head & Shoulders",
            "Uptrend (Dow Theory)", "Downtrend (Dow Theory)", "Old support now resistance", "Old resistance now support"),
  group = c(rep("Support & Resistance", 2), rep("Trend lines", 4), rep("Countertrend lines", 2), rep("Channels", 2), rep("Candlesticks", 9), rep("Breakout", 2), rep("Fibonacci (Step 2)", 2), rep("Price patterns (Step 2)", 12), rep("Trend (Dow Theory)", 2), rep("Support & Resistance", 2)),
  bias = c("bullish", "bearish", "bullish", "bearish", "bearish", "bullish", "bullish", "bearish", "bullish", "bearish",
           "bearish", "bearish", "bullish", "bullish", "bullish", "bullish", "bearish", "bullish", "bearish", "bullish", "bearish",
           "trend", "trend", "trend", "bullish", "bearish", "bearish", "bullish", "bullish", "bearish", "trend", "bearish", "bullish", "bearish", "bullish",
           "bullish", "bearish", "bearish", "bullish"),
  stringsAsFactors = FALSE)

# ---- data: chart windows and candle sizes offered in the Trades tab
tr_pat_windows <- c("7 days (168 h)" = 168, "72 h" = 72, "48 h" = 48, "24 h" = 24, "12 h" = 12, "6 h" = 6, "3 h" = 3)
tr_pat_intervals <- c("3 hours" = 180, "2 hours" = 120, "1 hour" = 60, "30 min" = 30, "15 min" = 15, "10 min" = 10, "5 min" = 5)
# Yahoo serves 5m / 15m / 30m / 60m: 10 min is built from 5 min bars, 2 h and 3 h from 1 h bars
tr_pat_yahoo_plan <- function(minutes, hours) {
  base <- if (minutes %in% c(5, 10)) 5 else if (minutes %in% c(15, 30)) minutes else 60
  list(interval = paste0(base, "m"), base = base, range = if (hours <= 72) "5d" else "1mo")
}
tr_pat_aggregate <- function(b, minutes) {
  if (is.null(b) || !nrow(b)) return(b)
  key <- floor(as.numeric(b$time) / (minutes * 60))
  out <- do.call(rbind, lapply(split(seq_len(nrow(b)), key), function(ix) data.frame(time = as.POSIXct(key[ix[1]] * minutes * 60, origin = "1970-01-01", tz = "UTC"),
          open = b$open[ix[1]], high = max(b$high[ix]), low = min(b$low[ix]), close = b$close[max(ix)])))
  out <- out[order(out$time), , drop = FALSE]; rownames(out) <- NULL; out
}
# bars for an asset on the IG scale. ref_ig = an IG price for the latest bar (Morning Sheet current price / your entry / the
# price you typed); without it oil is x100 (IG quotes Brent and WTI in points). Returns list(bars, source, note) or stops.
tr_pat_bars <- function(asset, hours = 48, minutes = 15, ref_ig = NA, fetch = tr_yahoo_fetch, now = Sys.time()) {
  sym <- unname(tr_yahoo_symbols[toupper(asset)]); if (!length(sym) || is.na(sym)) stop("No Yahoo symbol for ", asset, ".")
  pl <- tr_pat_yahoo_plan(minutes, hours)
  p <- fetch(sym, pl$range, pl$interval); b <- p$bars
  b <- b[is.finite(b$open) & is.finite(b$high) & is.finite(b$low) & is.finite(b$close), , drop = FALSE]
  if (!nrow(b)) stop("Yahoo returned no prices for ", sym, ".")
  attr(b$time, "tzone") <- "UTC"
  if (minutes != pl$base) b <- tr_pat_aggregate(b, minutes)
  last <- max(b$time); b <- b[b$time > last - hours * 3600, , drop = FALSE]
  last_close <- utils::tail(b$close, 1)
  oil <- toupper(asset) %in% c("BRENT", "WTI")
  if (is.finite(ref_ig)) { k <- tr_scale_to(ref_ig, last_close); off <- ref_ig - last_close * k
    note <- sprintf("Yahoo %s, shifted so the last candle closes at your IG price %s", sym, format(ref_ig)) }
  else { k <- if (oil) 100 else 1; off <- 0; note <- sprintf("Yahoo %s%s (no IG price to align to: levels can differ from IG by a few points)", sym, if (oil) " x100" else "") }
  for (cn in c("open", "high", "low", "close")) b[[cn]] <- b[[cn]] * k + off
  list(bars = b, source = paste0("Yahoo ", sym), note = note, symbol = sym, scale = k, offset = off)
}

# ---- building blocks
tr_pat_atr <- function(b) { pc <- c(b$close[1], utils::head(b$close, -1))
  tr <- pmax(b$high - b$low, abs(b$high - pc), abs(b$low - pc)); m <- stats::median(tr[is.finite(tr)]); if (!is.finite(m) || m <= 0) mean(b$high - b$low) else m }
tr_pat_swings <- function(b, k, detrend = FALSE) {
  n <- nrow(b); hi <- lo <- logical(n); hh <- b$high; ll <- b$low
  if (detrend && n >= 6) {   # in a steady trend few raw highs/lows stand out: take them relative to the window's own trend
    x <- seq_len(n); f <- stats::fitted(stats::lm(b$close ~ x)); hh <- hh - f; ll <- ll - f }
  for (i in seq_len(n)) { a <- max(1, i - k); z <- min(n, i + k); if (z - i < k || i - a < k) next
    hi[i] <- hh[i] >= max(hh[a:z]); lo[i] <- ll[i] <= min(ll[a:z]) }
  list(hi = which(hi), lo = which(lo))
}
# trend-line anchors: a candle whose high (low) no neighbour exceeds once the local slope is taken out
tr_pat_swings_local <- function(b, k) {
  n <- nrow(b); m <- max(4, 2 * k); hi <- lo <- logical(n)
  for (i in seq_len(n)) { a <- max(1, i - k); z <- min(n, i + k); if (z - i < k || i - a < k) next
    wa <- max(1, i - m); wz <- min(n, i + m); y <- b$close[wa:wz]; xx <- seq_along(y); s_ <- unname(stats::coef(stats::lm(y ~ xx))[2])
    t <- a:z; hi[i] <- all(b$high[t] - s_ * (t - i) <= b$high[i] + 1e-9); lo[i] <- all(b$low[t] - s_ * (t - i) >= b$low[i] - 1e-9) }
  list(hi = which(hi), lo = which(lo))
}
tr_pat_swings_all <- function(b, k) { a <- tr_pat_swings(b, k); d <- tr_pat_swings(b, k, TRUE); l <- tr_pat_swings_local(b, k)
  list(hi = sort(unique(c(a$hi, d$hi, l$hi))), lo = sort(unique(c(a$lo, d$lo, l$lo)))) }
# trend before bar i (exclusive): regression slope over L bars, in ATRs over the span: > 0.8 up, < -0.8 down
tr_pat_trend_at <- function(b, i, L, atr) {
  a <- max(1, i - L); if (i - a < 4) return(0)
  y <- b$close[a:(i - 1)]; x <- seq_along(y); s <- unname(stats::coef(stats::lm(y ~ x))[2] * length(y) / atr)
  net <- (y[length(y)] - y[1]) / atr; if (abs(net) > abs(s)) net else s
}
tr_pat_recency <- function(i, n) exp(-(n - i) / max(4, n / 4))   # 1 = the last candle
tr_pat_new <- function(key, score, idx, lines = NULL, marks = integer(0), note = "", status = "", level = NA_real_, mark_y = NULL, label = NULL, bias = NULL,
                       invalid = NA_real_, target = NA_real_) {
  cat_ <- tr_pat_catalog[tr_pat_catalog$key == key, ]
  list(key = key, label = if (is.null(label)) cat_$label else label, group = cat_$group, bias = if (is.null(bias)) cat_$bias else bias, score = max(0, score), idx = idx,
       lines = lines, marks = marks, mark_y = mark_y, note = note, status = status, level = level, invalid = invalid, target = target)
}
tr_pat_line <- function(x0, y0, x1, y1, color, dash = "solid", width = 2.5) data.frame(x0 = x0, y0 = y0, x1 = x1, y1 = y1, color = color, dash = dash, width = width, stringsAsFactors = FALSE)
tr_pat_fmt <- function(x) format(round(x, 1), nsmall = 1, big.mark = "")

# ---- Support & Resistance (LAT 1.2): 3+ bounces, more bounces than breaks, the latest interaction a bounce; between two
# bounces the price must clearly move away (1 ATR). A level never expires, so old bounces count; it must be near today's price.
tr_pat_sr <- function(b, sw, atr, k) {
  n <- nrow(b); last <- b$close[n]; tol <- 0.45 * atr; away <- 1.0 * atr; out <- list()
  cand <- c(b$high[sw$hi], b$low[sw$lo]); if (length(cand) < 3) return(out)
  hist_of <- function(level) {   # walk the chart: bounces (touch and turn back) and breaks (closes through), in order
    side <- 0; ev <- list(); armed <- TRUE; last_touch <- -99
    for (t in seq_len(n)) {
      d <- b$close[t] - level; s_ <- if (d > 0.3 * atr) 1 else if (d < -0.3 * atr) -1 else 0
      if (s_ != 0 && side != 0 && s_ != side) { ev[[length(ev) + 1]] <- c(t, 2); armed <- FALSE }           # break
      if (s_ != 0) side <- s_
      far <- if (side >= 0) b$low[t] - level else level - b$high[t]
      if (far >= away) armed <- TRUE
      touch <- if (side > 0) b$low[t] <= level + tol && b$close[t] >= level - 0.3 * atr else if (side < 0) b$high[t] >= level - tol && b$close[t] <= level + 0.3 * atr else FALSE
      if (touch && armed && t - last_touch > k) { ev[[length(ev) + 1]] <- c(t, 1); armed <- FALSE; last_touch <- t } }
    if (!length(ev)) return(NULL); e <- do.call(rbind, ev); list(bounce = e[e[, 2] == 1, 1], brk = e[e[, 2] == 2, 1], last = e[nrow(e), 2], side = side)
  }
  lv <- list()
  for (c0 in sort(unique(round(cand / (0.25 * atr))) * 0.25 * atr)) {
    if (abs(c0 - last) > 2 * atr) next                                                  # only levels near today's price
    h <- hist_of(c0); if (is.null(h) || length(h$bounce) < 3) next                       # rule 1: three or more bounces
    if (length(h$bounce) <= length(h$brk)) next                                         # rule 2: more bounces than breaks
    if (h$last != 1) next                                                               # rule 3: the latest interaction is a bounce
    side <- if (h$side > 0) "support" else "resistance"
    lv[[length(lv) + 1]] <- list(level = c0, idx = h$bounce, brk = h$brk, side = side) }
  if (!length(lv)) return(out)
  lv <- lv[order(-vapply(lv, function(z) length(z$idx), 0), vapply(lv, function(z) abs(z$level - last), 0))]; keep <- list()
  for (z in lv) if (!any(vapply(keep, function(q) abs(q$level - z$level) < 1.5 * tol, TRUE))) keep[[length(keep) + 1]] <- z
  for (L in keep) {
    nb <- length(L$idx); dist <- abs(last - L$level) / atr
    sc <- 20 + 8 * min(nb, 6) - 5 * length(L$brk) + 25 * tr_pat_recency(max(L$idx), n) + 15 * exp(-dist / 1.5)
    out[[length(out) + 1]] <- tr_pat_new(L$side, sc, L$idx, tr_pat_line(min(L$idx), L$level, n, L$level, if (L$side == "support") "#0284c7" else "#ea580c", "dash", 2.4),
      marks = L$idx, mark_y = rep(L$level, nb), level = L$level, status = sprintf("%d bounces, %d breaks", nb, length(L$brk)),
      invalid = L$level + (if (L$side == "support") -0.5 else 0.5) * atr,
      note = sprintf("%s at %s: %d bounces and %d breaks, the latest a bounce (candle %d of %d); price now %s ATR away", tools::toTitleCase(L$side), tr_pat_fmt(L$level),
                     nb, length(L$brk), max(L$idx), n, format(round(dist, 1)))) }
  out
}

# ---- Trend lines, broken trend lines, countertrend breaks, channels
# a line through swing lows (up) / highs (down): returns respected span, touches and the first decisive break
tr_pat_eval_line <- function(b, i, j, up, atr) {
  n <- nrow(b); slope <- if (up) (b$low[j] - b$low[i]) / (j - i) else (b$high[j] - b$high[i]) / (j - i)
  y0 <- if (up) b$low[i] else b$high[i]; at <- function(t) y0 + slope * (t - i)
  tol <- 0.3 * atr; xs <- i:n; ln <- at(xs)
  bad <- if (up) b$close[xs] < ln - tol else b$close[xs] > ln + tol
  brk <- if (any(bad)) xs[which(bad)[1]] else NA_integer_
  end <- if (is.na(brk)) n else brk - 1
  if (end < j) return(NULL)                                                     # broken before its second point
  seg <- i:end; ext <- if (up) b$low[seg] else b$high[seg]
  touches <- seg[abs(ext - at(seg)) <= 0.35 * atr]
  touches <- touches[c(TRUE, diff(touches) >= 2)]
  if (length(touches) > 1) {                                                    # separate touches: closes move 1 ATR+ away from the line in between
    keep <- touches[1]
    for (t in touches[-1]) { a0 <- keep[length(keep)]; if (t - a0 < 2) next; mid <- (a0 + 1):(t - 1); if (max(abs(b$close[mid] - at(mid))) >= 1.0 * atr) keep <- c(keep, t) }
    touches <- keep }
  list(i = i, j = j, slope = slope, at = at, brk = brk, end = end, touches = touches)
}
tr_pat_lines <- function(b, sw, atr) {
  n <- nrow(b); out <- list(); tot <- tr_pat_trend_at(b, n + 1, n, atr)        # whole-window trend
  for (up in c(TRUE, FALSE)) {
    piv <- if (up) sw$lo else sw$hi; piv <- utils::tail(piv, 40); best <- list(valid = NULL, broken = NULL, ctr = NULL); valids <- list()
    if (length(piv) < 2) next
    for (a in seq_along(piv)) for (c_ in seq_along(piv)) { if (c_ <= a) next
      i <- piv[a]; j <- piv[c_]; if (j - i < 3) next
      if (up && b$low[j] <= b$low[i]) next; if (!up && b$high[j] >= b$high[i]) next
      L <- tr_pat_eval_line(b, i, j, up, atr); if (is.null(L) || length(L$touches) < 3) next   # LAT 1.3: at least three pivot touches
      span <- L$end - L$i + 1; steep <- abs(L$slope) * span / atr
      if (steep < 1) next                                                       # (almost) flat: that is S/R, not a trend line
      if (abs(L$slope) > 0.6 * atr) next                                        # overly steep: not sustainable (TrendSpider)
      tq <- 10 * min(length(L$touches), 5) + 25 * min(1, span / (0.6 * n))
      if (is.na(L$brk)) {                                                       # still valid at the last candle (and not far from the price)
        if (abs(L$at(n) - b$close[n]) > 3 * atr) next
        sc <- tq + 25 * tr_pat_recency(max(L$touches), n) + 10
        valids[[length(valids) + 1]] <- c(L, sc = sc)
        if (is.null(best$valid) || sc > best$valid$sc) best$valid <- c(L, sc = sc)
      } else {
        after <- L$brk:n; beyond <- if (up) b$close[after] < L$at(after) - 0.3 * atr else b$close[after] > L$at(after) + 0.3 * atr
        decisive <- abs(b$close[L$brk] - L$at(L$brk)) >= 0.5 * atr || (length(after) >= 2 && all(beyond[1:2]))
        if (!decisive || mean(beyond) < 0.6) next
        if (L$brk < n - max(6, round(0.06 * n)) + 1) next                                       # an old break: not a decision for now
        if (if (up) b$close[n] >= L$at(n) else b$close[n] <= L$at(n)) next                      # price has gone back through: failed break
        short <- span <= 0.45 * n
        against <- (up && tot < -1) || (!up && tot > 1)                       # the line runs against the window's main trend
        if (short && against) {                                                # pullback line broken in the direction of the main trend
          sc <- tq + 30 * tr_pat_recency(L$brk, n) + 15
          if (is.null(best$ctr) || sc > best$ctr$sc) best$ctr <- c(L, sc = sc)
        } else if (!short || !against) {
          sc <- tq + 30 * tr_pat_recency(L$brk, n) + 10
          if (is.null(best$broken) || sc > best$broken$sc) best$broken <- c(L, sc = sc)
        }
      } }
    col <- if (up) "#0284c7" else "#ea580c"
    if (!is.null(v <- best$valid)) {
      out[[length(out) + 1]] <- tr_pat_new(if (up) "uptrend_line" else "downtrend_line", v$sc, v$touches, tr_pat_line(v$i, v$at(v$i), n, v$at(n), col), marks = v$touches, mark_y = v$at(v$touches),
        status = sprintf("%d touches, intact", length(v$touches)), level = v$at(n), invalid = v$at(n) + (if (up) -0.3 else 0.3) * atr,
        note = sprintf("%s through %d %s; at the last candle it is at %s", if (up) "Uptrend line" else "Downtrend line", length(v$touches), if (up) "rising swing lows" else "falling swing highs", tr_pat_fmt(v$at(n))))
    }
    # channel: a parallel line through the opposite extremes, touched 2+ times, containing the price (tried on the best 8 lines)
    bestch <- NULL
    for (v in utils::head(valids[order(-vapply(valids, function(z) z$sc, 0))], 8)) {
      seg <- v$i:n; opp <- if (up) b$high[seg] - v$at(seg) else v$at(seg) - b$low[seg]; w <- unname(stats::quantile(opp, 0.9))
      if (w < 1.5 * atr) next
      ch <- local({ vv <- v; ww <- w; function(t) vv$at(t) + (if (up) ww else -ww) })
      ext <- if (up) b$high[seg] else b$low[seg]; tch <- seg[abs(ext - ch(seg)) <= 0.6 * atr]; tch <- tch[c(TRUE, diff(tch) >= 2)]
      inside <- mean(b$close[seg] >= pmin(v$at(seg), ch(seg)) - 0.4 * atr & b$close[seg] <= pmax(v$at(seg), ch(seg)) + 0.4 * atr)
      if (length(tch) < 2 || inside < 0.9) next
      # LAT 1.3 Channels: the opposite side runs PARALLEL to the trend line (a converging side is a triangle / wedge, not a channel)
      opp <- if (up) sw$hi[sw$hi >= v$i] else sw$lo[sw$lo >= v$i]
      if (length(opp) >= 2) { so <- unname(stats::coef(stats::lm((if (up) b$high[opp] else b$low[opp]) ~ opp))[2]); ratio <- so / v$slope
        if (!is.finite(ratio) || ratio < 0.7 || ratio > 1.4) next }
      wd <- if (up) b$high[seg] - v$at(seg) else v$at(seg) - b$low[seg]; h1 <- seq_len(floor(length(seg) / 2))
      if (stats::median(wd[-h1]) < 0.6 * stats::median(wd[h1])) next                                  # the band narrows: not a channel
      sc <- 10 * min(length(v$touches) + length(tch), 7) + 20 * min(1, length(seg) / (0.5 * n)) + 25 * tr_pat_recency(max(c(v$touches, tch)), n)
      if (is.null(bestch) || sc > bestch$sc) bestch <- list(v = v, ch = ch, tch = tch, sc = sc) }
    if (!is.null(bestch)) { v <- bestch$v; ch <- bestch$ch; tch <- bestch$tch
      out[[length(out) + 1]] <- tr_pat_new(if (up) "bull_channel" else "bear_channel", bestch$sc, c(v$touches, tch),
        rbind(tr_pat_line(v$i, v$at(v$i), n, v$at(n), col), tr_pat_line(v$i, ch(v$i), n, ch(n), col, "dot")), marks = c(v$touches, tch), mark_y = c(v$at(v$touches), ch(tch)),
        status = sprintf("%d + %d touches", length(v$touches), length(tch)), level = ch(n), invalid = v$at(n) + (if (up) -0.3 else 0.3) * atr, target = ch(n),
        note = sprintf("%s channel: trend line %s and channel line %s at the last candle", if (up) "Ascending" else "Descending", tr_pat_fmt(v$at(n)), tr_pat_fmt(ch(n)))) }
    for (kind in c("broken", "ctr")) { v <- best[[kind]]; if (is.null(v)) next
      key <- if (kind == "broken") (if (up) "broken_uptrend" else "broken_downtrend") else (if (up) "ctr_break_down" else "ctr_break_up")
      out[[length(out) + 1]] <- tr_pat_new(key, v$sc, c(v$touches, v$brk), tr_pat_line(v$i, v$at(v$i), v$brk, v$at(v$brk), if (kind == "ctr") "#7c3aed" else col, if (kind == "ctr") "dash" else "solid"),
        marks = c(v$touches, v$brk), mark_y = c(v$at(v$touches), b$close[v$brk]), status = sprintf("broken %s", tr_pat_ago(v$brk, n)), level = v$at(v$brk), invalid = v$at(n),
        note = sprintf("%s (%d touches) closed through at %s, %s", if (kind == "ctr") (if (up) "Rising countertrend line in a downtrend" else "Falling countertrend line in an uptrend") else (if (up) "Uptrend line" else "Downtrend line"),
                       length(v$touches), tr_pat_fmt(b$close[v$brk]), tr_pat_ago(v$brk, n))) }
  }
  out
}

# ---- Candlesticks and Marubozu breakouts
tr_pat_confirm <- function(b, i, bull, last_idx = i, atr = tr_pat_atr(b)) {   # the average of the next (up to) 4 closes vs the signal close, in ATRs
  n <- nrow(b); if (last_idx >= n) return("pending (last candle)")
  nx <- b$close[(last_idx + 1):min(n, last_idx + 4)]; mv <- (mean(nx) - b$close[last_idx]) / atr * (if (bull) 1 else -1)
  if (mv >= 0.3) "confirmed" else if (mv <= -0.3) "failed" else if (length(nx) < 4) "pending" else "not confirmed"
}
tr_pat_candles <- function(b, sw, atr, supports = numeric(0), breaks = NULL) {
  n <- nrow(b); out <- list(); L <- max(5, min(12, round(n / 6))); best <- list()
  o <- b$open; h <- b$high; l <- b$low; c_ <- b$close; rng <- h - l; body <- abs(c_ - o); upw <- h - pmax(o, c_); low <- pmin(o, c_) - l
  add <- function(key, i, q, bull, last_idx = i, extra = "") {
    if (last_idx < n - 4) return(invisible())                                                   # candlestick signals count on the last 5 candles only
    st <- tr_pat_confirm(b, i, bull, last_idx, atr)
    sb <- switch(sub(" .*", "", st), confirmed = 25, pending = 12, failed = -10, 4)
    sc <- q + sb + 35 * tr_pat_recency(last_idx, n)
    if (is.null(best[[key]]) || sc > best[[key]]$score) best[[key]] <<- tr_pat_new(key, sc, i:last_idx, NULL, marks = i:last_idx, status = st,
      level = if (bull) min(l[i:last_idx]) else max(h[i:last_idx]),
      note = sprintf("%s %s (%s)%s", tr_pat_catalog$label[tr_pat_catalog$key == key], tr_pat_ago(last_idx, n), st, extra))
  }
  for (i in seq_len(n)) {
    if (i < max(6, n - 5) || rng[i] <= 0) next
    tr <- tr_pat_trend_at(b, i, L, atr); tr2 <- tr_pat_trend_at(b, i, 2 * L, atr)   # the move into the candle, short and longer view
    upc <- tr > 0.8 || tr2 > 1.2; dnc <- tr < -0.8 || tr2 < -1.2
    w4 <- max(1, i - 4):(i - 1); rec_hi <- h[i] >= max(h[w4]) - 1.0 * atr; rec_lo <- l[i] <= min(l[w4]) + 1.0 * atr
    small <- body[i] <= 0.4 * rng[i]; big <- rng[i] >= 0.8 * atr
    # one-candle shapes
    if (small && big && upw[i] >= 2 * body[i] && upw[i] >= 0.55 * rng[i] && low[i] <= 0.15 * rng[i]) {
      if (upc && rec_hi) add("shooting_star", i, 30 + 10 * min(3, upw[i] / max(body[i], 0.05 * atr)) / 3, FALSE)
      NULL }
    if (dnc && rec_lo && big && body[i] <= 0.45 * rng[i] && upw[i] >= body[i] && upw[i] >= 0.4 * rng[i] && low[i] <= 0.12 * rng[i])   # Step 1 draws it with a shorter upper wick
      add("inverted_hammer", i, 24 + 10 * min(2, upw[i] / max(body[i], 0.05 * atr)) / 2, TRUE)
    if (small && big && low[i] >= 2 * body[i] && low[i] >= 0.55 * rng[i] && upw[i] <= 0.15 * rng[i]) {
      if (upc && rec_hi) add("hanging_man", i, 28, FALSE)
      near_sup <- (length(supports) && any(abs(l[i] - supports) <= 0.6 * atr)) || any(abs(l[i] - l[sw$lo[sw$lo < i - 1]]) <= 0.4 * atr)
      if ((dnc && rec_lo) || (near_sup && l[i] <= min(l[max(1, i - L):(i - 1)]) + 0.5 * atr)) add("hammer_support", i, 26 + if (near_sup) 10 else 0, TRUE, extra = if (near_sup) ", on a support level" else ", at the low of a fall") }
    if (body[i] <= 0.1 * rng[i] && big) {
      if (low[i] >= 0.65 * rng[i] && upw[i] <= 0.12 * rng[i]) add("dragonfly_doji", i, 26 + if (dnc) 8 else 0, TRUE)
      if (rng[i] >= 1.2 * atr && upw[i] >= 0.3 * rng[i] && low[i] >= 0.3 * rng[i] && dnc) add("long_legged_doji", i, 30, TRUE) }
    # two-candle patterns (signal on candle i-1 .. i)
    p <- i - 1; trp <- tr_pat_trend_at(b, p, L, atr); pa <- max(1, p - 3)
    upctx <- trp > 0.8 || c_[p] > c_[max(1, p - 1)]; dnctx <- trp < -0.8 || c_[p] < c_[max(1, p - 1)]   # a trend, or at least a push into the signal
    pen <- function(main) if (main) 0 else 12
    if (upctx && c_[p] > o[p] && c_[i] < o[i] && o[i] >= c_[p] - 0.1 * atr && c_[i] <= o[p] && body[i] > body[p] && body[p] >= 0.3 * atr)
      add("bearish_engulfing", p, 32 + 8 * min(2, body[i] / body[p]) / 2 - pen(trp > 0.8), FALSE, last_idx = i)
    mid <- (o[p] + c_[p]) / 2
    if (upctx && c_[p] > o[p] && body[p] >= 0.8 * atr && c_[i] < o[i] && o[i] >= c_[p] - 0.05 * atr && c_[i] < mid && c_[i] > o[p])
      add("dark_cloud", p, 32 - pen(trp > 0.8), FALSE, last_idx = i)
    if (dnctx && c_[p] < o[p] && body[p] >= 0.8 * atr && c_[i] > o[i] && o[i] <= c_[p] + 0.05 * atr && c_[i] > mid && c_[i] < o[p])
      add("piercing", p, 32 - pen(trp < -0.8), TRUE, last_idx = i)
    # Marubozu breakout: a full-body candle closing through the recent range
    if (body[i] >= 0.85 * rng[i] && rng[i] >= 1.2 * atr && i > L) {
      sh <- sw$hi[sw$hi < i - 1]; sl <- sw$lo[sw$lo < i - 1]
      lvh <- if (length(sh)) h[max(sh)] else max(h[max(1, i - 2 * L):(i - 1)]); lvl <- if (length(sl)) l[max(sl)] else min(l[max(1, i - 2 * L):(i - 1)])
      if (c_[i] > o[i] && c_[i] > lvh) add("marubozu_bull", i, 34, TRUE, extra = sprintf(", closing above the last swing high %s", tr_pat_fmt(lvh)))
      if (c_[i] < o[i] && c_[i] < lvl) add("marubozu_bear", i, 34, FALSE, extra = sprintf(", closing below the last swing low %s", tr_pat_fmt(lvl)))
      if (!is.null(breaks) && nrow(breaks)) { bk <- breaks[breaks$i - i >= -1 & breaks$i - i <= 3, , drop = FALSE]   # or it is the candle that broke a trend line
        if (c_[i] > o[i] && any(bk$dir == "up") && !(c_[i] > lvh)) add("marubozu_bull", i, 32, TRUE, extra = ", breaking a trend line")
        if (c_[i] < o[i] && any(bk$dir == "down") && !(c_[i] < lvl)) add("marubozu_bear", i, 32, FALSE, extra = ", breaking a trend line") } }
  }
  unname(best)
}

tr_pat_top_n <- 5
# Step 2 shapes (and channels) built on the same stretch of candles describe ONE structure: keep the better one
tr_pat_shape_keys <- c("sym_triangle", "asc_triangle", "desc_triangle", "rising_wedge", "falling_wedge", "bull_flag", "bear_flag", "pennant",
                       "double_top", "double_bottom", "head_shoulders", "inv_head_shoulders", "bull_channel", "bear_channel",
                       "broken_uptrend", "broken_downtrend")
tr_pat_shape_rank <- c(head_shoulders = 1, inv_head_shoulders = 1, double_top = 2, double_bottom = 2, sym_triangle = 3, asc_triangle = 3, desc_triangle = 3,
                       rising_wedge = 3, falling_wedge = 3, bull_flag = 4, bear_flag = 4, pennant = 4, bull_channel = 5, bear_channel = 5,
                       broken_uptrend = 6, broken_downtrend = 6)   # a broken line inside a shape is the shape's breakout
tr_pat_dedupe <- function(all) {   # when two shapes cover the same candles, the more specific one wins (H&S > double > triangle/wedge > flag > channel)
  is_sh <- vapply(all, function(p) p$key %in% tr_pat_shape_keys, TRUE); sh <- all[is_sh]
  if (length(sh) < 2) return(all)
  sh <- sh[order(tr_pat_shape_rank[vapply(sh, function(p) p$key, "")], -vapply(sh, function(p) p$score, 0))]; keep <- list()
  for (p in sh) { r <- range(p$idx); clash <- FALSE
    for (q in keep) { r2 <- range(q$idx); ov <- max(0, min(r[2], r2[2]) - max(r[1], r2[1])); un <- max(r[2], r2[2]) - min(r[1], r2[1])
      if (un > 0 && ov / un >= 0.6) { clash <- TRUE; break } }
    if (!clash) keep[[length(keep) + 1]] <- p }
  out <- c(all[!is_sh], keep); out[order(-vapply(out, function(p) p$score, 0))]
}
# ---- Trend by Dow Theory on significant swings (zigzag of 1.5 ATR): an uptrend starts with a higher low followed by a
# close above the previous high, and ends (a downtrend starts) with a lower high followed by a close below the previous
# low. Reported from the swing where the current trend began to the last candle.
tr_pat_dow <- function(b, atr) {
  n <- nrow(b); zz <- tr_pat_zigzag(b, 1.5 * atr); zz <- zz[zz$final, , drop = FALSE]; m <- nrow(zz); if (m < 4) return(list()); eq <- 0.5 * atr   # completed swings only
  first_close <- function(from, lvl, dir) { if (from >= n) return(NA_integer_); t <- (from + 1):n; h <- if (dir > 0) b$close[t] > lvl else b$close[t] < lvl; if (any(h)) t[which(h)[1]] else NA_integer_ }
  ev <- list()
  for (k in 3:m) { cur <- zz[k, ]; prv <- zz[k - 2, ]; mid <- zz[k - 1, ]
    if (cur$type == "L" && cur$p > prv$p + eq) { t <- first_close(cur$i, mid$p, 1); if (!is.na(t)) ev[[length(ev) + 1]] <- data.frame(t = t, dir = 1, origin = k - 2, k = k) }
    if (cur$type == "H" && cur$p < prv$p - eq) { t <- first_close(cur$i, mid$p, -1); if (!is.na(t)) ev[[length(ev) + 1]] <- data.frame(t = t, dir = -1, origin = k - 2, k = k) } }
  if (!length(ev)) return(list()); ev <- do.call(rbind, ev); ev <- ev[order(ev$t, ev$k), ]
  # walk the events: a new trend starts only when the direction changes; the trend start is the swing it began from
  dir <- 0; org <- NA; trig <- NA
  for (r in seq_len(nrow(ev))) if (ev$dir[r] != dir) { dir <- ev$dir[r]; org <- ev$origin[r]; trig <- ev$t[r] }
  up <- dir > 0; P <- zz[org:m, ]; o <- P[1, ]
  hs <- P[P$type == "H", ]; ls <- P[P$type == "L", ]
  cnt <- function(x, up_) { if (nrow(x) < 2) return(0L); d <- diff(x$p); as.integer(sum(if (up_) d > eq else d < -eq)) }
  nh <- cnt(hs, up); nl <- cnt(ls, up); conf <- nh >= 2 && nl >= 2
  # the level that cancels it: the last higher low (up) / lower high (down); the level that confirms more: the last extreme
  inv <- if (up) utils::tail(ls$p[ls$i >= o$i & ls$i != o$i], 1) else utils::tail(hs$p[hs$i >= o$i & hs$i != o$i], 1)
  if (!length(inv) || !is.finite(inv)) inv <- if (up) min(b$low[trig:n]) else max(b$high[trig:n])
  ext <- if (up) max(b$high[o$i:n]) else min(b$low[o$i:n])
  if (if (up) b$close[n] < inv else b$close[n] > inv) return(list())                    # already cancelled at the last candle
  col <- if (up) "#16a34a" else "#dc2626"; pts <- rbind(P[, c("i", "p")], data.frame(i = n, p = b$close[n]))
  lines <- do.call(rbind, lapply(seq_len(nrow(pts) - 1), function(r) tr_pat_line(pts$i[r], pts$p[r], pts$i[r + 1], pts$p[r + 1], col, "dot", 1.6)))
  lines <- rbind(lines, tr_pat_line(trig, inv, n, inv, "#64748b", "dash", 1.4))
  sc <- 50 + (if (conf) 18 else 6) + 4 * min(3, nh + nl) + 10 * min(1, (n - o$i) / (0.25 * n))
  word <- if (up) "higher" else "lower"
  tr_pat_new(if (up) "dow_up" else "dow_down", sc, c(o$i, P$i, n), lines, marks = P$i, mark_y = P$p, level = inv, invalid = inv, target = ext,
    label = sprintf("%s (Dow Theory)%s", if (up) "Uptrend" else "Downtrend", if (conf) "" else ", early: not confirmed"),
    status = sprintf("since %s: %d %s high(s), %d %s low(s)", tr_pat_ago(o$i, n), nh, word, nl, word),
    note = sprintf("Began at the swing %s %s (%s); turned at %s, the first close %s the previous swing %s; %d %s high(s) and %d %s low(s) so far (2 + 2 confirm it).",
                   if (up) "low" else "high", tr_pat_fmt(o$p), tr_pat_ago(o$i, n), tr_pat_ago(trig, n), if (up) "above" else "below", if (up) "high" else "low",
                   nh, word, nl, word))
}
# ---- Role reversal (LAT 1.2): a level that held 3+ times, broken recently, now retested from the other side
tr_pat_flip <- function(b, atr, k) {
  n <- nrow(b); last <- b$close[n]; RB <- max(8, round(0.12 * n)); tol <- 0.45 * atr; sw <- tr_pat_swings(b, 1); out <- list()
  cand <- sort(unique(round(c(b$high[sw$hi], b$low[sw$lo]) / (0.25 * atr)) * 0.25 * atr)); best <- NULL
  for (lv in cand) { if (abs(lv - last) > 1.0 * atr) next
    side <- 0; armed <- TRUE; lt <- -99; bo <- integer(0); bside <- 0; brk <- NA; pend <- NA
    for (t in seq_len(n)) {
      if (!is.na(brk)) break                                                              # after the break: judged below (retest vs failed break)
      d <- b$close[t] - lv; s_ <- if (d > 0.3 * atr) 1 else if (d < -0.3 * atr) -1 else 0
      if (s_ != 0 && side != 0 && s_ != side) { pend <- NA; if (length(bo) >= 3) { brk <- t; bside <- side; next } else bo <- integer(0); armed <- FALSE }
      if (s_ != 0) side <- s_
      far <- if (side >= 0) b$high[t] - lv else lv - b$low[t]
      if (far >= atr) { armed <- TRUE; if (!is.na(pend)) { bo <- c(bo, pend); pend <- NA } }   # a touch counts once the price has travelled 1 ATR away again
      touch <- if (side > 0) b$low[t] <= lv + tol && b$close[t] >= lv - 0.3 * atr else if (side < 0) b$high[t] >= lv - tol && b$close[t] <= lv + 0.3 * atr else FALSE
      if (touch && armed && is.na(pend) && t - lt > k) { pend <- t; armed <- FALSE; lt <- t } }
    if (is.na(brk) || brk < n - RB || length(bo) < 3) next
    now_side <- if (bside > 0) -1 else 1                                                  # held from above (support) -> now below it
    aft <- b$close[brk:n]
    if ((now_side < 0 && any(aft > lv + 0.5 * atr)) || (now_side > 0 && any(aft < lv - 0.5 * atr))) next   # closed back through: the break failed
    sc <- 52 + 6 * min(length(bo), 5) + 15 * tr_pat_recency(brk, n) + 10 * exp(-abs(last - lv) / atr)
    if (is.null(best) || sc > best$sc) best <- list(lv = lv, bo = bo, brk = brk, now_side = now_side, sc = sc) }
  if (is.null(best)) return(out)
  res <- best$now_side < 0; lv <- best$lv; col <- if (res) "#ea580c" else "#0284c7"
  list(tr_pat_new(if (res) "sup_to_res" else "res_to_sup", best$sc, c(best$bo, best$brk, n), rbind(tr_pat_line(min(best$bo), lv, n, lv, col, "dash", 2.4)),
    marks = best$bo, mark_y = rep(lv, length(best$bo)), level = lv, invalid = lv + (if (res) 0.6 else -0.6) * atr,
    status = sprintf("%d bounces, broken %s, retest now", length(best$bo), tr_pat_ago(best$brk, n)),
    note = sprintf("%s at %s held %d times, broke %s; price %s is retesting it from %s", if (res) "Support" else "Resistance", tr_pat_fmt(lv), length(best$bo),
                   tr_pat_ago(best$brk, n), tr_pat_fmt(last), if (res) "below" else "above")))
}
# does a pattern run up to the last candle? (a line reaching it, or a candle at the right edge)
tr_pat_reaches_end <- function(p, n) (!is.null(p$lines) && any(p$lines$x1 >= n)) || max(p$idx) >= n
# lines that stop at a recent breakout are continued (dotted) to the right edge
tr_pat_extend_keys <- c("broken_uptrend", "broken_downtrend", "ctr_break_up", "ctr_break_down", "sym_triangle", "asc_triangle", "desc_triangle", "rising_wedge", "falling_wedge",
                        "bull_flag", "bear_flag", "pennant")
tr_pat_extend <- function(p, n) {
  L <- p$lines; if (is.null(L) || !nrow(L) || !(p$key %in% tr_pat_extend_keys)) return(p)
  main <- which(L$x1 < n & L$x1 > L$x0 & !(L$color %in% c("#f59e0b", "#94a3b8", "#64748b")))
  if (!length(main)) return(p)
  ext <- do.call(rbind, lapply(main, function(r) { s_ <- (L$y1[r] - L$y0[r]) / (L$x1[r] - L$x0[r]); tr_pat_line(L$x1[r], L$y1[r], n, L$y1[r] + s_ * (n - L$x1[r]), L$color[r], "dot", 1.4) }))
  if (length(main) == 2 && nrow(ext) == 2 && (ext$y1[1] - ext$y1[2]) * (ext$y0[1] - ext$y0[2]) < 0) return(p)   # the two lines would cross: leave them
  p$lines <- rbind(L, ext); p
}
tr_pat_single <- c("shooting_star", "dark_cloud", "inverted_hammer", "long_legged_doji", "dragonfly_doji", "hammer_support", "bearish_engulfing", "piercing", "hanging_man", "marubozu_bull", "marubozu_bear")
# ---- everything, ranked. Returns list(all, top = first 5, atr, n, decision)
tr_pat_detect <- function(b) {
  n <- nrow(b); if (n < 12) stop("Only ", n, " candles: choose a longer window or a shorter candle size (12 or more needed).")
  atr <- tr_pat_atr(b); k <- if (n <= 60) 2 else if (n <= 250) 3 else 4
  sr <- tr_pat_sr(b, tr_pat_swings(b, 1), atr, k)
  swa <- tr_pat_swings_all(b, k); s1 <- tr_pat_swings(b, 1)                            # anchors: clear swings + any 1-candle turn (a line's 2nd point is often a small one)
  ln <- tr_pat_lines(b, list(hi = sort(unique(c(swa$hi, s1$hi))), lo = sort(unique(c(swa$lo, s1$lo)))), atr)
  safe <- function(f, what) tryCatch(f(), error = function(e) { cat("[Chart]", what, "skipped:", conditionMessage(e), "\n"); list() })
  dw <- safe(function() { x <- tr_pat_dow(b, atr); if (length(x) && !is.null(x$key)) list(x) else x }, "Dow trend")
  all <- c(dw, safe(function() tr_pat_flip(b, atr, k), "Role reversal"), sr, ln, safe(function() tr_pat_step2(b, atr), "Step 2 patterns"))
  all <- lapply(all, tr_pat_extend, n = n)
  # only multi-candle structures that reach the last candle (single candles and finished patterns are left out)
  all <- Filter(function(p) !(p$key %in% tr_pat_single) && tr_pat_reaches_end(p, n) && diff(range(c(p$idx, if (!is.null(p$lines)) p$lines$x0))) >= 5, all)
  if (!length(all)) return(list(all = list(), top = list(), atr = atr, n = n, decision = tr_pat_decision(list(), b, atr)))
  sc <- vapply(all, function(p) p$score, 0)
  all <- all[order(-sc)]; all <- all[!duplicated(vapply(all, function(p) p$key, ""))]   # best instance of each type
  all <- tr_pat_dedupe(all)                                                              # one price structure = one slot
  # a channel contains its own trend line: show the channel only
  for (pr in list(c("bull_channel", "uptrend_line"), c("bear_channel", "downtrend_line"))) if (any(vapply(all, function(p) p$key == pr[1], TRUE))) all <- Filter(function(p) p$key != pr[2], all)
  # a role-reversal level replaces a plain level at the same price
  fl <- Filter(function(p) p$key %in% c("sup_to_res", "res_to_sup"), all)
  if (length(fl)) all <- Filter(function(p) !(p$key %in% c("support", "resistance") && abs(p$level - fl[[1]]$level) < 0.6 * atr), all)
  # scale: raw points -> 0-99, keeping the order and the gaps (no pile-up at 100)
  all <- lapply(all, function(p) { p$raw <- p$score; p$score <- as.integer(round(99 * (1 - exp(-p$raw / 60)))); p })
  top <- utils::head(all, tr_pat_top_n)
  dwk <- which(vapply(all, function(p) p$key %in% c("dow_up", "dow_down"), TRUE))          # the trend (Dow) is the frame for the rest: always shown
  if (length(dwk) && dwk[1] > tr_pat_top_n) top <- c(utils::head(all, tr_pat_top_n - 1), all[dwk[1]])
  list(all = all, top = top, atr = atr, n = n, decision = tr_pat_decision(top, b, atr))
}
# score-weighted vote of the top patterns + the nearest levels that cancel / target each side
tr_pat_decision <- function(pats, b, atr) {
  n <- nrow(b); last <- b$close[n]
  if (!length(pats)) return(list(side = "NONE", text = "No multi-candle pattern reaches the last candle: no chart basis for a trade.", bull = 0, bear = 0))
  w <- vapply(pats, function(p) p$score, 0); bias <- vapply(pats, function(p) p$bias, "")
  bu <- sum(w[bias == "bullish"]); be <- sum(w[bias == "bearish"]); tot <- sum(w)
  side <- if (be >= 0.6 * tot && be > bu) "SELL" else if (bu >= 0.6 * tot && bu > be) "BUY" else "NONE"
  pick <- pats[bias == (if (side == "SELL") "bearish" else "bullish")]
  inv <- vapply(pick, function(p) as.numeric(p$invalid), 0); tg <- vapply(pick, function(p) as.numeric(p$target), 0)
  sgn <- if (side == "SELL") 1 else -1
  inv <- inv[is.finite(inv) & sgn * (inv - last) > 0]; tg <- tg[is.finite(tg) & sgn * (last - tg) > 0]
  stop_ref <- if (length(inv)) (if (side == "SELL") min(inv) else max(inv)) else NA
  tgt_ref <- if (length(tg)) (if (side == "SELL") max(tg) else min(tg)) else NA
  txt <- sprintf("%s: %d of %d patterns bearish, %d bullish (score-weighted %d%% bearish / %d%% bullish).", if (side == "NONE") "NO CLEAR SIDE" else paste(side, "bias"),
                 sum(bias == "bearish"), length(pats), sum(bias == "bullish"), round(100 * be / tot), round(100 * bu / tot))
  if (side != "NONE") txt <- paste0(txt, sprintf(" Nearest cancelling level %s (stop beyond it); nearest pattern target %s.", if (is.finite(stop_ref)) tr_pat_fmt(stop_ref) else "-", if (is.finite(tgt_ref)) tr_pat_fmt(tgt_ref) else "-"))
  list(side = side, text = txt, bull = bu, bear = be, stop_ref = stop_ref, target_ref = tgt_ref)
}
# text for Claude / the evidence table
tr_pat_summary <- function(pats, b) {
  if (!length(pats)) return("No pattern found.")
  tm <- function(i) format(b$time[i], "%d/%m %H:%M", tz = "Europe/London")
  paste(vapply(seq_along(pats), function(k) { p <- pats[[k]]
    lv <- paste0(if (is.finite(p$invalid %||% NA)) sprintf("; cancelled beyond %s", tr_pat_fmt(p$invalid)) else "", if (is.finite(p$target %||% NA)) sprintf("; target %s", tr_pat_fmt(p$target)) else "")
    sprintf("%d. %s [%s, %s bias] score %d, %s: %s%s (candles %s to %s UK)", k, p$label, p$group, p$bias, p$score, p$status, p$note, lv, tm(min(p$idx)), tm(n_end(p, b))) }, ""), collapse = "\n")
}
n_end <- function(p, b) max(c(p$idx, if (!is.null(p$lines)) p$lines$x1), na.rm = TRUE) |> min(nrow(b))
tr_pat_bars_text <- function(b, max_rows = 120) {
  if (nrow(b) > max_rows) b <- utils::tail(b, max_rows)
  paste(c("time_uk,open,high,low,close", sprintf("%s,%s,%s,%s,%s", format(b$time, "%d/%m %H:%M", tz = "Europe/London"),
        round(b$open, 1), round(b$high, 1), round(b$low, 1), round(b$close, 1))), collapse = "\n")
}

# ---- drawing: interactive (plotly) and a PNG for the Trade Sheet. levels: data.frame(name, price, color, dash)
tr_pat_plotly <- function(b, pat = NULL, levels = NULL, vlines = NULL, title = NULL) {
  x <- seq_len(nrow(b)) - 1; uk <- format(b$time, "%d/%m %H:%M", tz = "Europe/London")
  p <- plotly::plot_ly(x = x, type = "candlestick", open = b$open, high = b$high, low = b$low, close = b$close, text = uk, hoverinfo = "text+y", name = "Price",
                       increasing = list(line = list(color = "#16a34a")), decreasing = list(line = list(color = "#dc2626")))
  shapes <- list(); ann <- list()
  if (!is.null(levels) && nrow(levels)) for (r in seq_len(nrow(levels))) {
    shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", x0 = 0, x1 = max(x), y0 = levels$price[r], y1 = levels$price[r], line = list(color = levels$color[r], dash = levels$dash[r], width = 1.3))
    ann[[length(ann) + 1]] <- list(x = max(x), y = levels$price[r], text = levels$name[r], xanchor = "left", showarrow = FALSE, font = list(size = 10, color = levels$color[r])) }
  if (!is.null(vlines) && length(vlines)) for (k in seq_along(vlines)) {
    shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", yref = "paper", x0 = vlines[k] - 1, x1 = vlines[k] - 1, y0 = 0, y1 = 1, line = list(color = "#f59e0b", dash = "dot", width = 1))
    ann[[length(ann) + 1]] <- list(x = vlines[k] - 1, y = 1.0, yref = "paper", text = sub(" .*$", "", names(vlines)[k]), showarrow = FALSE, font = list(size = 9, color = "#b45309"), xanchor = "center", yanchor = "bottom") }
  if (!is.null(vlines) && length(vlines)) p <- plotly::add_markers(p, x = unname(vlines) - 1, y = rep(max(b$high), length(vlines)), text = names(vlines), hoverinfo = "text",
                                                                  marker = list(symbol = "diamond", size = 9, color = "#f59e0b"), name = "Releases", inherit = FALSE)
  if (!is.null(pat)) {
    if (!is.null(pat$lines)) for (r in seq_len(nrow(pat$lines))) { L <- pat$lines[r, ]
      shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", x0 = L$x0 - 1, x1 = L$x1 - 1, y0 = L$y0, y1 = L$y1, line = list(color = L$color, dash = L$dash, width = L$width)) }
    if (length(pat$marks)) {
      if (!is.null(pat$mark_y)) p <- plotly::add_markers(p, x = pat$marks - 1, y = pat$mark_y, marker = list(symbol = "circle-open", size = 12, color = "#7c3aed", line = list(width = 2.5)), name = pat$label, hoverinfo = "name", inherit = FALSE)
      else { m <- unique(pat$marks); off <- 0.015 * diff(range(b$low, b$high))
        p <- plotly::add_markers(p, x = m - 1, y = if (pat$bias == "bullish") b$low[m] - off else b$high[m] + off,
                                 marker = list(symbol = if (pat$bias == "bullish") "triangle-up" else "triangle-down", size = 12, color = "#7c3aed"), name = pat$label, hoverinfo = "name", inherit = FALSE) } }
    nx <- max(x); x0 <- max(0, nx - max(6, round(0.15 * length(x))))                     # the decision levels, at the right-hand edge
    for (lv in list(list(v = pat$invalid, t = "cancels", c = "#dc2626"), list(v = pat$target, t = "target", c = "#16a34a"))) if (is.finite(lv$v %||% NA)) {
      shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", x0 = x0, x1 = nx + 2, y0 = lv$v, y1 = lv$v, line = list(color = lv$c, dash = "dash", width = 1.8))
      ann[[length(ann) + 1]] <- list(x = x0, y = lv$v, text = sprintf("%s %s", lv$t, tr_pat_fmt(lv$v)), xanchor = "right", showarrow = FALSE, font = list(size = 10, color = lv$c), bgcolor = "rgba(255,255,255,0.8)") }   # left of the segment: no clash with the level names on the right
    ann[[length(ann) + 1]] <- list(x = 0, y = 1.06, xref = "paper", yref = "paper", xanchor = "left", showarrow = FALSE, text = sprintf("<b>%s</b> (%s, score %d)", pat$label, pat$status, pat$score), font = list(size = 12, color = "#4c1d95")) }
  if (!is.null(title)) ann[[length(ann) + 1]] <- list(x = 0, y = 1.13, xref = "paper", yref = "paper", xanchor = "left", showarrow = FALSE, text = sprintf("<b>%s</b>", title), font = list(size = 14, color = "#0f172a"))
  step <- max(1, round(length(x) / 8)); tv <- x[seq(1, length(x), by = step)]
  plotly::layout(p, shapes = shapes, annotations = ann, showlegend = FALSE, margin = list(r = 90, t = if (is.null(title)) 40 else 62),
                 xaxis = list(rangeslider = list(visible = FALSE), tickvals = tv, ticktext = uk[tv + 1], title = "UK time", range = c(-1, max(x) + 3)), yaxis = list(title = "IG points"))
}
tr_pat_png <- function(b, pat = NULL, levels = NULL, file = tempfile(fileext = ".png"), caption = "") {
  grDevices::png(file, width = 1400, height = 760, res = 130); on.exit(grDevices::dev.off())
  n <- nrow(b); x <- seq_len(n); yl <- range(c(b$low, b$high, if (!is.null(levels)) levels$price), na.rm = TRUE); yl <- yl + c(-1, 1) * diff(yl) * 0.04
  graphics::par(mar = c(4.2, 4.6, 3, 7.5))
  graphics::plot(NA, xlim = c(0.5, n + 0.5), ylim = yl, xaxt = "n", xlab = "UK time", ylab = "Price (IG points)", main = caption, cex.main = 0.85)
  step <- max(1, round(n / 8)); at <- seq(1, n, by = step); graphics::axis(1, at = at, labels = format(b$time[at], "%d/%m %H:%M", tz = "Europe/London"), cex.axis = 0.75)
  graphics::grid(nx = NA, ny = NULL, col = "#e5e7eb")
  up <- b$close >= b$open; col <- ifelse(up, "#16a34a", "#dc2626"); w <- 0.35
  graphics::segments(x, b$low, x, b$high, col = "#475569"); graphics::rect(x - w, pmin(b$open, b$close), x + w, pmax(b$open, b$close), col = col, border = col)
  if (!is.null(levels) && nrow(levels)) for (r in seq_len(nrow(levels))) {
    graphics::abline(h = levels$price[r], col = levels$color[r], lty = if (levels$dash[r] == "solid") 1 else 2, lwd = 1.3)
    graphics::mtext(levels$name[r], side = 4, at = levels$price[r], las = 1, cex = 0.6, col = levels$color[r], line = 0.3) }
  if (!is.null(pat)) {
    if (!is.null(pat$lines)) for (r in seq_len(nrow(pat$lines))) { L <- pat$lines[r, ]
      graphics::segments(L$x0, L$y0, L$x1, L$y1, col = L$color, lwd = 2.4, lty = if (L$dash == "solid") 1 else if (L$dash == "dot") 3 else 2) }
    if (length(pat$marks)) {
      if (!is.null(pat$mark_y)) graphics::points(pat$marks, pat$mark_y, pch = 1, col = "#7c3aed", cex = 1.6, lwd = 2.2)
      else { m <- unique(pat$marks); off <- diff(yl) * 0.02
        graphics::points(m, if (pat$bias == "bullish") b$low[m] - off else b$high[m] + off, pch = if (pat$bias == "bullish") 24 else 25, bg = "#7c3aed", col = "#7c3aed", cex = 1.1) } }
    x0 <- max(1, n - max(6, round(0.15 * n)))
    for (lv in list(list(v = pat$invalid, t = "cancels", c = "#dc2626"), list(v = pat$target, t = "target", c = "#16a34a"))) if (is.finite(lv$v %||% NA) && lv$v >= yl[1] && lv$v <= yl[2]) {
      graphics::segments(x0, lv$v, n + 0.5, lv$v, col = lv$c, lty = 2, lwd = 1.8)
      graphics::text(x0, lv$v, sprintf("%s %s", lv$t, tr_pat_fmt(lv$v)), pos = if (identical(lv$t, "cancels") == (pat$bias != "bullish")) 3 else 1, cex = 0.62, col = lv$c, offset = 0.25) }   # inside the plot: no clash with the level names on the right
    graphics::mtext(sprintf("%s (%s)", pat$label, pat$status), side = 3, adj = 0, line = 0.2, cex = 0.75, col = "#4c1d95") }
  invisible(file)
}

# =============================================================================================
# Step 2: Fibonacci and price patterns, read from the last turning points (zigzag of swing highs / lows)
# =============================================================================================
tr_pat_ago <- function(i, n) { a <- n - i; if (a <= 0) "on the last candle" else if (a == 1) "1 candle ago" else sprintf("%d candles ago", a) }
tr_pat_zigzag <- function(b, thr) {
  n <- nrow(b); piv <- list(); add <- function(i, ty) piv[[length(piv) + 1]] <<- data.frame(i = i, p = if (ty == "H") b$high[i] else b$low[i], type = ty, final = TRUE)
  dir <- 0; hi_i <- lo_i <- ei <- 1
  for (t in seq_len(n)[-1]) {
    if (dir == 0) { if (b$high[t] > b$high[hi_i]) hi_i <- t; if (b$low[t] < b$low[lo_i]) lo_i <- t
      if (b$high[hi_i] - b$low[lo_i] >= thr) { if (hi_i > lo_i) { add(lo_i, "L"); dir <- 1; ei <- hi_i } else { add(hi_i, "H"); dir <- -1; ei <- lo_i } } }
    else if (dir == 1) { if (b$high[t] >= b$high[ei]) ei <- t else if (b$high[ei] - b$low[t] >= thr) { add(ei, "H"); dir <- -1; ei <- t } }
    else { if (b$low[t] <= b$low[ei]) ei <- t else if (b$high[t] - b$low[ei] >= thr) { add(ei, "L"); dir <- 1; ei <- t } } }
  if (dir != 0) { add(ei, if (dir == 1) "H" else "L"); piv[[length(piv)]]$final <- FALSE }   # the leg still running at the last candle
  if (!length(piv)) return(data.frame(i = integer(0), p = numeric(0), type = character(0), final = logical(0)))
  do.call(rbind, piv)
}
# a line through two points, as a function of the candle index
tr_pat_fn2 <- function(x0, y0, x1, y1) { s_ <- (y1 - y0) / (x1 - x0); function(t) y0 + s_ * (t - x0) }
# first close beyond a line after `from` (dir +1 above / -1 below) by 0.3 ATR; NA if none
tr_pat_break_at <- function(b, f, from, dir, atr) { n <- nrow(b); if (from >= n) return(NA_integer_); t <- (from + 1):n
  hit <- if (dir > 0) b$close[t] > f(t) + 0.3 * atr else b$close[t] < f(t) - 0.3 * atr; if (any(hit)) t[which(hit)[1]] else NA_integer_ }

tr_pat_step2 <- function(b, atr) {
  out <- list(); rng <- diff(range(c(b$low, b$high)))
  # three sensitivities: small swings (triangles, wedges, flags) to large ones (Fibonacci legs, tops and bottoms)
  for (mult in c(0.8, 1.2, 1.7)) { zz <- tr_pat_zigzag(b, max(mult * atr, 0.03 * rng)); if (nrow(zz) >= 3) out <- c(out, tr_pat_step2_zz(b, atr, zz)) }
  out <- c(out, tr_pat_flags(b, atr))
  out
}
tr_pat_step2_zz <- function(b, atr, zz) {
  n <- nrow(b); out <- list(); R <- max(8, round(0.25 * n)); RB <- max(5, round(0.08 * n)); last <- b$close[n]; m <- nrow(zz)
  tgt_line <- function(from, y) tr_pat_line(from, y, n, y, "#f59e0b", "dash", 1.6)
  ctx <- function(i) tr_pat_trend_at(b, i, max(6, min(20, round(n / 5))), atr)
  # ---- Fibonacci: leg A = P0 -> P1, pullback P2 (the last turning points, P2 possibly still forming)
  for (k in max(1, m - 3):(m - 2)) { if (k < 1) next
    P0 <- zz[k, ]; P1 <- zz[k + 1, ]; P2 <- zz[k + 2, ]; A <- P1$p - P0$p; if (abs(A) < 4 * atr) next
    up <- A > 0; r <- (P1$p - P2$p) / A
    if (P2$i >= n - R && r >= 0.42 && r <= 0.70) {                                       # retracement to 50 % / 61.8 %
      lvl <- if (abs(r - 0.5) <= abs(r - 0.618)) 0.5 else 0.618; fibp <- P1$p - lvl * A
      resumed <- if (up) last > P2$p + 0.5 * atr else last < P2$p - 0.5 * atr
      if (if (up) last < P2$p - 0.3 * atr else last > P2$p + 0.3 * atr) next              # price went on through the level: no bounce
      st <- if (resumed) sprintf("bounced off %s%% %s, %s resuming", lvl * 100, tr_pat_ago(P2$i, n), if (up) "uptrend" else "downtrend") else sprintf("at the %s%% level now", lvl * 100)
      lines <- do.call(rbind, lapply(c(0, 0.236, 0.382, 0.5, 0.618, 0.786, 1), function(l) tr_pat_line(P0$i, P1$p - l * A, n, P1$p - l * A, if (abs(l - lvl) < 1e-6) "#f59e0b" else "#94a3b8", if (abs(l - lvl) < 1e-6) "solid" else "dot", if (abs(l - lvl) < 1e-6) 2.2 else 1)))
      lines <- rbind(lines, tr_pat_line(P0$i, P0$p, P1$i, P1$p, if (up) "#0284c7" else "#ea580c", "solid", 2))
      sc <- 40 + 15 * max(0, 1 - abs(r - lvl) / 0.08) + 25 * tr_pat_recency(P2$i, n) + (if (resumed) 15 else 8)
      out[[length(out) + 1]] <- tr_pat_new("fib_retracement", sc, c(P0$i, P1$i, P2$i, n), lines, marks = P2$i, mark_y = P2$p, level = fibp, status = st,
        invalid = P1$p - 0.786 * A, target = P1$p,
        label = sprintf("Fibonacci retracement to %s%% (%s)", lvl * 100, if (up) "uptrend" else "downtrend"), bias = if (up) "bullish" else "bearish",
        note = sprintf("%s leg %s to %s; pullback to %s = %s%% (level %s)", if (up) "Up" else "Down", tr_pat_fmt(P0$p), tr_pat_fmt(P1$p), tr_pat_fmt(P2$p), round(100 * r), tr_pat_fmt(fibp)))
    }
    if (r >= 0.236 && r <= 0.786 && (if (up) last > P2$p + atr else last < P2$p - atr) && P2$i >= n - max(R, round(0.4 * n))) {   # 100 % expansion of leg A from P2
      T_ <- P2$p + A; prog <- (last - P2$p) / A; hit <- if (up) max(b$high[P2$i:n]) >= T_ else min(b$low[P2$i:n]) <= T_
      lines <- rbind(tr_pat_line(P0$i, P0$p, P1$i, P1$p, "#94a3b8", "solid", 1.6), tr_pat_line(P1$i, P1$p, P2$i, P2$p, "#94a3b8", "dot", 1.4),
                     tr_pat_line(P2$i, P2$p, n, P2$p, "#94a3b8", "dot", 1), tgt_line(P2$i, T_))
      sc <- 36 + 20 * min(1, max(0, prog)) + 20 * tr_pat_recency(P2$i, n) + (if (hit) -10 else 8)   # a reached target is history, an open one is a plan
      out[[length(out) + 1]] <- tr_pat_new("fib_expansion", sc, c(P0$i, P1$i, P2$i, n), lines, marks = c(P0$i, P1$i, P2$i), mark_y = c(P0$p, P1$p, P2$p), level = T_, invalid = P2$p, target = T_,
        status = if (hit) "target reached" else sprintf("%d%% of the way to the target", round(100 * prog)), bias = if (up) "bullish" else "bearish",
        label = sprintf("Fibonacci 100%% expansion (%s), target %s", if (up) "up" else "down", tr_pat_fmt(T_)),
        note = sprintf("Leg %s to %s (%s) projected from the %s turning point: target %s", tr_pat_fmt(P0$p), tr_pat_fmt(P1$p), tr_pat_fmt(abs(A)), tr_pat_fmt(P2$p), tr_pat_fmt(T_)))
    } }
  # shapes are built from COMPLETED turning points only: the leg still running at the last candle is what breaks out of them
  zz <- zz[zz$final, , drop = FALSE]; m <- nrow(zz); if (m < 3) return(out)
  # ---- Double top / bottom: T1 N T2, the second top / bottom in the last part of the chart
  for (k in max(1, m - 4):(m - 2)) { if (k < 1) next
    a <- zz[k, ]; mid <- zz[k + 1, ]; c2 <- zz[k + 2, ]; if (a$type != c2$type) next
    top <- a$type == "H"; h <- abs(max(a$p, c2$p) * (if (top) 1 else 0) + min(a$p, c2$p) * (if (top) 0 else 1) - mid$p)
    if (h < 3 * atr || c2$i < n - R) next                                               # a real valley between the two (Bulkowski; 3 ATR intraday)
    if (abs(c2$p - a$p) > 1.0 * atr || c2$i - a$i < 4) next                             # level peaks (within 1 ATR), distinct (4+ candles apart)
    if ((top && ctx(a$i) < 0.3) || (!top && ctx(a$i) > -0.3)) next                    # a double top ends a rise, a double bottom a fall
    neck <- mid$p; f <- function(t) rep(neck, length(t)); bk <- tr_pat_break_at(b, f, c2$i, if (top) -1 else 1, atr)
    if (!is.na(bk) && (bk < n - RB || (if (top) last > neck else last < neck))) next   # old or failed neckline break
    if (is.na(bk) && (if (top) last < neck else last > neck)) next
    if (if (top) max(b$close[c2$i:n]) > max(a$p, c2$p) + 0.3 * atr else min(b$close[c2$i:n]) < min(a$p, c2$p) - 0.3 * atr) next   # tops / bottoms taken out: invalid
    T_ <- if (top) neck - h else neck + h
    lines <- rbind(tr_pat_line(a$i, (a$p + c2$p) / 2, c2$i, (a$p + c2$p) / 2, "#7c3aed", "dot", 1.6), tr_pat_line(mid$i, neck, if (is.na(bk)) n else bk, neck, "#7c3aed", "solid", 2.2), tgt_line(if (is.na(bk)) c2$i else bk, T_))
    sc <- 42 + 10 * min(1, h / (5 * atr)) + 25 * tr_pat_recency(if (is.na(bk)) c2$i else bk, n) + (if (!is.na(bk)) 18 else 5)
    out[[length(out) + 1]] <- tr_pat_new(if (top) "double_top" else "double_bottom", sc, c(a$i, mid$i, c2$i, if (!is.na(bk)) bk, n), lines, marks = c(a$i, c2$i), mark_y = c(a$p, c2$p), level = neck,
      invalid = if (top) max(a$p, c2$p) + 0.3 * atr else min(a$p, c2$p) - 0.3 * atr, target = T_,
      status = if (is.na(bk)) "forming: neckline not broken yet" else sprintf("neckline broken %s", tr_pat_ago(bk, n)),
      note = sprintf("%s at %s / %s, neckline %s, target %s", if (top) "Tops" else "Bottoms", tr_pat_fmt(a$p), tr_pat_fmt(c2$p), tr_pat_fmt(neck), tr_pat_fmt(T_))) }
  # ---- Head & shoulders (regular and inverse): S1 N1 H N2 S2
  if (m >= 5) for (k in max(1, m - 6):(m - 4)) { if (k < 1) next
    s1 <- zz[k, ]; n1 <- zz[k + 1, ]; hd <- zz[k + 2, ]; n2 <- zz[k + 3, ]; s2 <- zz[k + 4, ]
    reg <- s1$type == "H"; sg <- if (reg) 1 else -1; if (s2$i < n - R) next
    if (sg * hd$p - max(sg * s1$p, sg * s2$p) < 0.25 * atr) next                        # the head goes beyond both shoulders
    neckf <- tr_pat_fn2(n1$i, n1$p, n2$i, n2$p); hh <- sg * (hd$p - neckf(hd$i)); if (hh < 2.5 * atr) next
    if (abs(s1$p - s2$p) > max(1.0 * atr, 0.25 * hh)) next                               # shoulders at about the same price
    tsym <- (hd$i - s1$i) / max(1, s2$i - hd$i); if (tsym < 0.5 || tsym > 2) next        # and evenly spaced around the head
    bk <- tr_pat_break_at(b, neckf, s2$i, -sg, atr)
    if (!is.na(bk) && (bk < n - RB || sg * (last - neckf(n)) > 0)) next
    if (is.na(bk) && sg * (last - neckf(n)) < 0) next
    if ((if (reg) max(b$close[s2$i:n]) - hd$p else hd$p - min(b$close[s2$i:n])) > 0.3 * atr) next   # price went beyond the head: invalid
    T_ <- neckf(if (is.na(bk)) n else bk) - sg * hh
    ex <- if (is.na(bk)) n else bk
    lines <- rbind(tr_pat_line(n1$i, n1$p, n, neckf(n), "#7c3aed", "solid", 2.2), tgt_line(if (is.na(bk)) s2$i else bk, T_))
    sc <- 45 + 10 * min(1, hh / (5 * atr)) + 25 * tr_pat_recency(if (is.na(bk)) s2$i else bk, n) + (if (!is.na(bk)) 18 else 5)
    out[[length(out) + 1]] <- tr_pat_new(if (reg) "head_shoulders" else "inv_head_shoulders", sc, c(s1$i, n1$i, hd$i, n2$i, s2$i, if (!is.na(bk)) bk, n), lines,
      invalid = s2$p + sg * 0.3 * atr, target = T_,
      marks = c(s1$i, hd$i, s2$i), mark_y = c(s1$p, hd$p, s2$p), level = neckf(n),
      status = if (is.na(bk)) "forming: neckline not broken yet" else sprintf("neckline broken %s", tr_pat_ago(bk, n)),
      note = sprintf("Shoulders %s / %s, head %s, neckline now %s, target %s", tr_pat_fmt(s1$p), tr_pat_fmt(s2$p), tr_pat_fmt(hd$p), tr_pat_fmt(neckf(n)), tr_pat_fmt(T_))) }
  # ---- Triangles and wedges: turning points squeezed between two converging lines. The last 4-7 turning points set the
  # lines; earlier turning points that still sit on the same lines are added (looking back through the whole chart), so the
  # pattern starts where the price really began to respect them. Lines stop at the breakout candle (or at their meeting point).
  fitl <- function(P) { if (nrow(P) < 2) return(NULL); cf <- stats::coef(stats::lm(P$p ~ P$i)); c(cf[1], cf[2]) }
  why <- function(x) if (isTRUE(getOption("tr.pat.debug"))) cat("[tw]", x, "\n")
  for (eo in 0:2) for (cnt in 5:7) { if (m - eo < cnt) next   # one line 3 touches, the other 2: 5 turning points (Bulkowski)
    z <- zz[(m - eo - cnt + 1):(m - eo), ]; H <- z[z$type == "H", ]; L <- z[z$type == "L", ]; if (nrow(H) < 2 || nrow(L) < 2) next
    cu <- fitl(H); cl <- fitl(L); uf <- function(t) cu[1] + cu[2] * t; lf <- function(t) cl[1] + cl[2] * t
    j <- m - eo - cnt                                                                       # look back for earlier turning points on the same lines
    while (j >= 1) { pj <- zz[j, ]; w <- uf(pj$i) - lf(pj$i); if (w <= 0) break
      if (abs(pj$p - (if (pj$type == "H") uf(pj$i) else lf(pj$i))) > 0.2 * w) break
      sg <- pj$i:min(z$i); if (mean(b$close[sg] <= uf(sg) + 0.4 * atr & b$close[sg] >= lf(sg) - 0.4 * atr) < 0.8) break
      z <- rbind(pj, z); j <- j - 1 }
    H <- z[z$type == "H", ]; L <- z[z$type == "L", ]; cu <- fitl(H); cl <- fitl(L)
    s0 <- min(z$i); e0 <- max(z$i); span <- e0 - s0
    if (span < max(10, round(0.12 * n)) || e0 < n - R) { why(sprintf("span %d / e0 %d", span, e0)); next }                                 # long enough, and reaching the last part of the chart
    if (max(diff(z$i)) > 0.7 * span) { why("gap"); next }                                                   # turning points spread along the pattern
    w0 <- uf(s0) - lf(s0); w1 <- uf(e0) - lf(e0); if (w0 < 2.5 * atr || w1 <= 0.15 * w0 || w1 > 0.65 * w0) { why(sprintf("width %.1f -> %.1f (atr %.1f)", w0, w1, atr)); next }
    xa <- if (abs(cu[2] - cl[2]) > 1e-9) (cl[1] - cu[1]) / (cu[2] - cl[2]) else Inf         # where the lines meet
    if (xa <= e0 + 1) { why("apex passed"); next }
    if (any(abs(H$p - uf(H$i)) > 0.3 * (uf(H$i) - lf(H$i))) || any(abs(L$p - lf(L$i)) > 0.3 * (uf(L$i) - lf(L$i)))) { why("pivot off its line"); next }   # every turning point on its line (no lone wick)
    seg <- s0:e0; inside <- mean(b$close[seg] <= uf(seg) + 0.4 * atr & b$close[seg] >= lf(seg) - 0.4 * atr); if (inside < 0.85) { why(sprintf("inside %.2f", inside)); next }
    du <- uf(e0) - uf(s0); dl <- lf(e0) - lf(s0); flat <- max(0.6 * atr, 0.12 * w0)
    key <- if (abs(du) <= flat && dl > flat) "asc_triangle" else if (abs(dl) <= flat && du < -flat) "desc_triangle" else if (du < -flat && dl > flat) "sym_triangle"
           else if (du > flat && dl > flat && dl > du) "rising_wedge" else if (du < -flat && dl < -flat && du < dl) "falling_wedge" else NA
    if (is.na(key)) { why(sprintf("shape? du %.1f dl %.1f flat %.1f", du, dl, flat)); next }
    upx <- tr_pat_break_at(b, uf, e0, 1, atr); dnx <- tr_pat_break_at(b, lf, e0, -1, atr)
    bk <- suppressWarnings(min(c(upx, dnx), na.rm = TRUE)); bk <- if (is.finite(bk)) as.integer(bk) else NA_integer_
    dirb <- if (is.na(bk)) 0 else if (!is.na(upx) && upx == bk) 1 else -1
    if (!is.na(bk) && (bk < n - RB || (dirb > 0 && last < uf(bk)) || (dirb < 0 && last > lf(bk)))) { why(sprintf("break %d old/failed", bk)); next }   # old, or price back inside: no longer a decision
    if (is.na(bk) && (last > uf(n) + 0.4 * atr || last < lf(n) - 0.4 * atr || n >= xa)) { why("outside / apex"); next }
    lead <- ctx(s0)
    usual <- switch(key, asc_triangle = 1, desc_triangle = -1, rising_wedge = -1, falling_wedge = 1, sym_triangle = if (lead > 0.8) 1 else if (lead < -0.8) -1 else 0)
    lab <- tr_pat_catalog$label[tr_pat_catalog$key == key]
    if (key %in% c("sym_triangle", "rising_wedge", "falling_wedge")) lab <- sprintf("%s in %s", lab, if (lead > 0.8) "an uptrend" else if (lead < -0.8) "a downtrend" else "a range")
    against <- dirb != 0 && usual != 0 && dirb != usual
    if (against) lab <- paste0(lab, ", failed (broke against the usual direction)")
    bias <- if (dirb > 0) "bullish" else if (dirb < 0) "bearish" else if (usual > 0) "bullish" else if (usual < 0) "bearish" else "trend"
    endx <- min(if (is.na(bk)) n else bk, floor(xa))
    T_ <- if (dirb > 0) b$close[bk] + w0 else if (dirb < 0) b$close[bk] - w0 else NA
    lines <- rbind(tr_pat_line(s0, uf(s0), endx, uf(endx), "#7c3aed", "solid", 2.2), tr_pat_line(s0, lf(s0), endx, lf(endx), "#7c3aed", "solid", 2.2), if (is.finite(T_)) tgt_line(bk, T_))
    sc <- 40 + 2.5 * min(nrow(z), 8) + 10 * (1 - w1 / w0) + 8 * min(1, span / (0.3 * n)) + 22 * tr_pat_recency(if (is.na(bk)) e0 else bk, n) + (if (!is.na(bk)) 12 else 5) - (if (against) 18 else 0)
    out[[length(out) + 1]] <- tr_pat_new(key, sc, c(z$i, if (!is.na(bk)) bk, n), lines, marks = z$i, mark_y = z$p, level = if (dirb > 0) uf(endx) else lf(endx), label = lab, bias = bias,
      invalid = if (dirb > 0) lf(endx) else if (dirb < 0) uf(endx) else if (usual > 0) lf(n) else if (usual < 0) uf(n) else NA, target = T_,
      status = if (is.na(bk)) sprintf("forming, %d turning points since %s", nrow(z), tr_pat_ago(s0, n)) else sprintf("broke %s %s", if (dirb > 0) "up" else "down", tr_pat_ago(bk, n)),
      note = sprintf("%d turning points from %s; lines %s %s (top) and %s (bottom)%s", nrow(z), tr_pat_ago(s0, n), if (is.na(bk)) "now at" else "at the breakout:", tr_pat_fmt(uf(endx)), tr_pat_fmt(lf(endx)),
                     if (is.finite(T_)) sprintf(", measured target %s (pattern height %s)", tr_pat_fmt(T_), tr_pat_fmt(w0)) else "")) }
  out
}
# ---- Flags and pennant: a sharp pole, then a short consolidation reaching the last candles (or just broken out of)
tr_pat_flags <- function(b, atr) {
  n <- nrow(b); RB <- max(5, round(0.08 * n)); bestf <- list()
  for (ce in max(8, n - 4):n) for (e in max(5, ce - 15):(ce - 4)) for (pl in 3:12) { s0 <- e - pl; if (s0 < 1) next
    pole <- if (b$close[e] >= b$open[s0 + 1]) b$high[e] - b$low[s0 + 1] else b$low[e] - b$high[s0 + 1]   # pole = extreme to extreme
    if (abs(pole) < 4 * atr || abs(pole) / (e - s0) < 0.8 * atr) next                  # a steep pole: 0.8 ATR+ per candle (Britannica / Bulkowski)
    pc <- b$close[(s0 + 1):e]; ctr <- if (pole > 0) max(cummax(pc) - pc) else max(pc - cummin(pc))
    if (ctr > 0.25 * abs(pole)) next                                                     # and straight: no pullback over 25% (closes) inside it
    up <- pole > 0; if ((up && b$high[e] < max(b$high[s0:e]) - 0.5 * atr) || (!up && b$low[e] > min(b$low[s0:e]) + 0.5 * atr)) next
    cs <- (e + 1):ce; if (length(cs) < 4) next
    if (max(b$high[cs]) - min(b$low[cs]) > 0.6 * abs(pole)) next
    if ((up && min(b$low[cs]) < b$close[e] - 0.6 * abs(pole)) || (!up && max(b$high[cs]) > b$close[e] + 0.6 * abs(pole))) next
    # the price must stall after the pole: no new extreme beyond the pole's end, little net progress, a sideways / counter drift
    if ((up && max(b$high[cs]) > b$high[e] + 0.15 * abs(pole)) || (!up && min(b$low[cs]) < b$low[e] - 0.15 * abs(pole))) next
    if (abs(b$close[ce] - b$close[e]) > 0.35 * abs(pole) || (up && b$close[ce] > b$close[e] + 0.1 * abs(pole)) || (!up && b$close[ce] < b$close[e] - 0.1 * abs(pole))) next
    xx <- cs; uh <- stats::coef(stats::lm(b$high[cs] ~ xx)); ul <- stats::coef(stats::lm(b$low[cs] ~ xx))
    uf <- function(t) uh[1] + uh[2] * t; lf <- function(t) ul[1] + ul[2] * t
    w0 <- uf(cs[1]) - lf(cs[1]); w1 <- uf(ce) - lf(ce); if (w0 <= 0 || w1 <= 0) next
    inside <- mean(b$close[cs] <= uf(cs) + 0.3 * atr & b$close[cs] >= lf(cs) - 0.3 * atr); if (inside < 0.85) next
    slope <- (uh[2] + ul[2]) / 2 * length(cs) / atr
    pen <- w1 < 0.65 * w0; if (w1 > 1.6 * w0) next                                      # a widening pause is not a flag
    key <- if (pen) "pennant" else if (up && slope <= 0.5) "bull_flag" else if (!up && slope >= -0.5) "bear_flag" else NA
    if (is.na(key)) next
    bk <- tr_pat_break_at(b, if (up) uf else lf, ce, if (up) 1 else -1, atr)
    if (!is.na(bk) && (bk < n - RB || (up && b$close[n] < uf(n)) || (!up && b$close[n] > lf(n)))) next
    if (is.na(bk) && (b$close[n] > uf(n) + 0.4 * atr || b$close[n] < lf(n) - 0.4 * atr)) next
    T_ <- (if (is.na(bk)) (if (up) uf(n) else lf(n)) else b$close[bk]) + 0.95 * pole      # pole height from the breakout
    sc <- 44 + 10 * min(1, abs(pole) / (8 * atr)) + 5 * inside + 20 * tr_pat_recency(if (is.na(bk)) n else bk, n) + (if (!is.na(bk)) 15 else 5) - (if (length(cs) < 5) 8 else 0)
    if (is.null(bestf[[key]]) || sc > bestf[[key]]$sc) bestf[[key]] <- list(key = key, up = up, s0 = s0, e = e, cs = cs, ce = ce, uf = uf, lf = lf, bk = bk, T_ = T_, pole = pole, sc = sc) }
  lapply(unname(bestf), function(f) {
  lines <- rbind(tr_pat_line(f$s0 + 1, if (f$up) b$low[f$s0 + 1] else b$high[f$s0 + 1], f$e, if (f$up) b$high[f$e] else b$low[f$e], "#94a3b8", "solid", 2), tr_pat_line(f$cs[1], f$uf(f$cs[1]), if (is.na(f$bk)) n else f$bk, f$uf(if (is.na(f$bk)) n else f$bk), "#0284c7", "solid", 2.2),
                 tr_pat_line(f$cs[1], f$lf(f$cs[1]), if (is.na(f$bk)) n else f$bk, f$lf(if (is.na(f$bk)) n else f$bk), "#0284c7", "solid", 2.2), tr_pat_line(if (is.na(f$bk)) n else f$bk, f$T_, n, f$T_, "#f59e0b", "dash", 1.6))
  tr_pat_new(f$key, f$sc, c(f$s0, f$e, f$ce, n), lines, marks = c(f$s0 + 1, f$e), mark_y = c(if (f$up) b$low[f$s0 + 1] else b$high[f$s0 + 1], if (f$up) b$high[f$e] else b$low[f$e]), level = f$T_,
    invalid = (if (f$up) f$lf(n) else f$uf(n)) + (if (f$up) -0.3 else 0.3) * atr, target = f$T_,
    label = if (f$key == "pennant") sprintf("%s pennant", if (f$up) "Bullish" else "Bearish") else NULL, bias = if (f$up) "bullish" else "bearish",
    status = if (is.na(f$bk)) (if (length(f$cs) < 5) sprintf("forming: %d of the 5 pause candles needed, no breakout yet", length(f$cs)) else "no breakout yet") else sprintf("broke out %s", tr_pat_ago(f$bk, n)),
    note = sprintf("Pole %s points (%s to %s), %d-candle pause, channel now %s to %s, target %s", tr_pat_fmt(abs(f$pole)), tr_pat_fmt(if (f$up) b$low[f$s0 + 1] else b$high[f$s0 + 1]),
                   tr_pat_fmt(if (f$up) b$high[f$e] else b$low[f$e]), length(f$cs), tr_pat_fmt(f$lf(n)), tr_pat_fmt(f$uf(n)), tr_pat_fmt(f$T_))) })
}

# =============================================================================================
# Saving and restoring a chart with its patterns (trading_evidence, kind "patterns", column extracted_json)
# The candles are stored with the patterns, so the same chart can be redrawn later without Yahoo.
# =============================================================================================
tr_pat_pack <- function(r, shown = "") {
  b <- r$bars; d <- r$det
  pk <- function(p) list(key = p$key, label = p$label, group = p$group, bias = p$bias, score = p$score, status = p$status, note = p$note,
                         level = unname(p$level), invalid = unname(p$invalid %||% NA), target = unname(p$target %||% NA), idx = p$idx, marks = p$marks,
                         mark_y = if (is.null(p$mark_y)) NULL else round(p$mark_y, 2), lines = if (is.null(p$lines)) NULL else transform(p$lines, y0 = round(y0, 2), y1 = round(y1, 2)),
                         from_uk = format(b$time[max(1, min(p$idx))], "%Y-%m-%d %H:%M", tz = "Europe/London"),
                         to_uk = format(b$time[min(nrow(b), max(p$idx))], "%Y-%m-%d %H:%M", tz = "Europe/London"))
  list(format = 2L, asset = r$asset, source = r$source, symbol = r$symbol %||% "", alignment = r$note, window_hours = r$hours, candle_minutes = r$mins,
       candles = nrow(b), last_candle_uk = format(max(b$time), "%Y-%m-%d %H:%M", tz = "Europe/London"), shown = shown, atr = round(d$atr, 3),
       decision = d$decision, top = lapply(d$top, pk),
       bars = list(t = format(b$time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), o = round(b$open, 2), h = round(b$high, 2), l = round(b$low, 2), c = round(b$close, 2)))
}
tr_pat_pack_json <- function(r, shown = "") as.character(jsonlite::toJSON(tr_pat_pack(r, shown), auto_unbox = TRUE, digits = NA, na = "null", null = "null"))
# extracted_json -> the same structure the chart box uses (list(bars, det, asset, hours, mins, note, ...)); NULL if no candles were saved
tr_pat_unpack <- function(js) {
  j <- tryCatch(jsonlite::fromJSON(js, simplifyVector = TRUE, simplifyDataFrame = TRUE), error = function(e) NULL)
  if (is.null(j) || is.null(j$bars) || !length(j$bars$t)) return(NULL)
  b <- data.frame(time = as.POSIXct(j$bars$t, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), open = as.numeric(j$bars$o), high = as.numeric(j$bars$h), low = as.numeric(j$bars$l), close = as.numeric(j$bars$c))
  num <- function(x) if (is.null(x) || !length(x)) NA_real_ else suppressWarnings(as.numeric(x[1]))
  tp <- j$top; top <- list()
  if (is.data.frame(tp) && nrow(tp)) for (k in seq_len(nrow(tp))) {
    g <- function(f) { v <- tp[[f]]; if (is.null(v)) NULL else if (is.list(v)) v[[k]] else v[k] }
    ln <- g("lines"); if (!is.null(ln) && (!is.data.frame(ln) || !nrow(ln))) ln <- NULL
    my <- g("mark_y"); if (!is.null(my) && !length(my)) my <- NULL
    top[[k]] <- list(key = g("key"), label = g("label"), group = g("group"), bias = g("bias"), score = as.integer(g("score")), status = g("status"), note = g("note"),
                     level = num(g("level")), invalid = num(g("invalid")), target = num(g("target")), idx = as.integer(unlist(g("idx"))), marks = as.integer(unlist(g("marks"))),
                     mark_y = if (is.null(my)) NULL else as.numeric(unlist(my)), lines = ln) }
  dec <- j$decision; if (!is.null(dec)) dec <- lapply(dec, function(v) if (is.null(v) || !length(v)) NA else v)
  list(bars = b, det = list(all = top, top = top, atr = num(j$atr), n = nrow(b), decision = dec), asset = j$asset, hours = num(j$window_hours), mins = num(j$candle_minutes),
       note = j$alignment %||% "", source = j$source %||% "", symbol = j$symbol %||% "", shown = j$shown %||% "", last_candle_uk = j$last_candle_uk %||% "")
}
