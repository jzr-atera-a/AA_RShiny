# R/utils_pm.R - Pattern Matrix (Steps 1-6): a simulated 15-minute example for every one of the 141 patterns, built
# from the pattern's textbook definition (exact turning points on exact candles), the truth geometry of that example
# (labelled points, lines through the real highs / lows, the confirming candle, entry / cancel / target), and a check
# against the app's rule engine (run with the improved rules, v2) on the same candles.
#
# Units: prices are built in "u" (0.20 USD on a Brent-like price of 100). Between turning points price moves about
# 0.25 u per candle, so the ATR(14) of an example is about 0.5 u; sizes below are chosen in those terms.

pm_u <- 0.20; pm_speed <- 0.25; pm_base <- 100
pm_t0 <- as.POSIXct("2026-10-12 00:00", tz = "UTC")   # a Monday (UK time = UTC until 25 Oct)

# ---- building candles -----------------------------------------------------------------------------------------
# anchors: data.frame(p = price in u (relative to pm_base), type = "H" (a high made exactly at p), "L" (a low exactly at p)
#   or "" (a close passing p), len = candles from the previous anchor (NA = from the price distance), lab = label shown)
# lead: candles before the first anchor (a quiet drift for the indicators' warm-up), drift = its total move in u
pm_anchor <- function(p, type = "", len = NA, lab = "") data.frame(p = p, type = type, len = len, lab = lab, stringsAsFactors = FALSE)
pm_build <- function(anchors, lead = 260, drift = 0, seed = 1, wick = 0.10, noise = 0.04, start = pm_t0) {
  set.seed(seed + getOption("pm.seed", 0)); A <- do.call(rbind, anchors)
  # closes: the lead-in drift, then straight legs between the anchors
  cl <- pm_base / pm_u + A$p[1] - drift + drift * seq_len(lead) / lead + stats::rnorm(lead, 0, noise) * c(rep(1, lead - 1), 0)
  pos <- integer(nrow(A)); pos[1] <- lead
  for (k in 2:nrow(A)) { len <- A$len[k]; if (!is.finite(len)) len <- max(2L, round(abs(A$p[k] - A$p[k - 1]) / pm_speed))
    seg <- A$p[k - 1] + (A$p[k] - A$p[k - 1]) * seq_len(len) / len + c(stats::rnorm(len - 1, 0, noise), 0)
    cl <- c(cl, pm_base / pm_u + seg); pos[k] <- length(cl) }
  n <- length(cl); op <- c(cl[1], cl[-n]); w1 <- stats::runif(n, 0.4, 1) * wick; w2 <- stats::runif(n, 0.4, 1) * wick
  hi <- pmax(op, cl) + w1; lo <- pmin(op, cl) - w2
  # the anchors: a high (low) exactly at p, its close just inside; nothing else between the neighbouring anchors goes beyond it
  for (k in seq_len(nrow(A))) { j <- pos[k]; P <- pm_base / pm_u + A$p[k]
    if (A$type[k] == "H") { cl[j] <- min(cl[j], P - 0.12); hi[j] <- P; if (j < n) op[j + 1] <- cl[j] }
    if (A$type[k] == "L") { cl[j] <- max(cl[j], P + 0.12); lo[j] <- P; if (j < n) op[j + 1] <- cl[j] } }
  hi <- pmax(hi, op, cl); lo <- pmin(lo, op, cl)
  for (k in seq_len(nrow(A))) { j <- pos[k]; P <- pm_base / pm_u + A$p[k]
    typed <- which(A$type %in% c("H", "L")); pv_ <- typed[typed < k]; nx_ <- typed[typed > k]   # the turning point is the extreme up to the neighbouring turning points
    a0 <- if (length(pv_)) pos[max(pv_)] + 1 else 1; a1 <- if (length(nx_)) pos[min(nx_)] - 1 else min(n, j + 12); rg <- setdiff(a0:a1, j)
    if (A$type[k] == "H" && length(rg)) { x <- hi[rg] > P - 0.03; hi[rg][x] <- P - 0.03; cl[rg] <- pmin(cl[rg], hi[rg]); op[rg] <- pmin(op[rg], hi[rg]) }
    if (A$type[k] == "L" && length(rg)) { x <- lo[rg] < P + 0.03; lo[rg][x] <- P + 0.03; cl[rg] <- pmax(cl[rg], lo[rg]); op[rg] <- pmax(op[rg], lo[rg]) } }
  b <- data.frame(time = start + (seq_len(n) - 1) * 900, open = op * pm_u, high = hi * pm_u, low = lo * pm_u, close = cl * pm_u)
  attr(b, "pos") <- pos; attr(b, "anchors") <- A; b
}
# extra candles given as rows (o, h, l, c) in u, relative to the last close; returns the bars with them appended
pm_append <- function(b, rows, gap = 0) {
  last <- utils::tail(b$close, 1) / pm_u; t <- utils::tail(b$time, 1)
  x <- data.frame(time = t + seq_len(nrow(rows)) * 900, open = (last + rows$o) * pm_u, high = (last + rows$h) * pm_u, low = (last + rows$l) * pm_u, close = (last + rows$c) * pm_u)
  out <- rbind(b[, c("time", "open", "high", "low", "close")], x); attributes(out)[c("pos", "anchors")] <- attributes(b)[c("pos", "anchors")]; out
}
pm_ohlc <- function(...) { r <- do.call(rbind, lapply(list(...), function(v) data.frame(o = v[1], h = v[2], l = v[3], c = v[4]))); r }

# ---- truth geometry ---------------------------------------------------------------------------------------------
# points: the labelled turning points (candle index, exact price); lines: segments through them (extended to `to`);
# event: the candle that completes / confirms it; entry / cancel / target from the definition
pm_truth <- function(b, key, points = NULL, lines = NULL, event = nrow(b), entry = utils::tail(b$close, 1), cancel = NA, target = NA, level = NA, span = NULL, note = "") {
  A <- attr(b, "anchors"); pos <- attr(b, "pos")
  pts <- if (!is.null(A)) data.frame(i = pos, price = ifelse(A$type == "H", b$high[pos], ifelse(A$type == "L", b$low[pos], b$close[pos])), type = A$type, lab = A$lab, stringsAsFactors = FALSE) else NULL
  if (!is.null(pts)) pts <- pts[nzchar(pts$lab), , drop = FALSE]
  if (!is.null(points)) pts <- points
  if (is.null(span)) span <- c(if (!is.null(pts) && nrow(pts)) min(pts$i) else event - 2, nrow(b))
  list(key = key, b = b, points = pts, lines = lines, event = event, view = NA, context = NULL, entry = entry, cancel = cancel, target = target, level = level, span = span, note = note)
}
pm_pt <- function(t, lab) { p <- t$points[t$points$lab == lab, , drop = FALSE]; c(p$i[1], p$price[1]) }
pm_ln <- function(p1, p2, to = NULL, col = "#7c3aed", dash = "solid", name = "") {   # a line through two points, optionally extended to candle `to`
  x1 <- if (is.null(to)) p2[1] else to; y1 <- p1[2] + (p2[2] - p1[2]) / (p2[1] - p1[1]) * (x1 - p1[1])
  data.frame(x0 = p1[1], y0 = p1[2], x1 = x1, y1 = y1, color = col, dash = dash, name = name, stringsAsFactors = FALSE) }
pm_hl <- function(x0, x1, y, col = "#64748b", dash = "dash", name = "") data.frame(x0 = x0, y0 = y, x1 = x1, y1 = y, color = col, dash = dash, name = name, stringsAsFactors = FALSE)

# ---- shared helpers for the examples -------------------------------------------------------------------------------
pm_A <- pm_anchor
pm_atr <- function(b) cc_ctx(b, 15)$a                       # the same Wilder ATR(14) as the engine
pm_first <- function(x) { w <- which(x); if (length(w)) w[1] else NA_integer_ }
pm_after <- function(b, from, test) { i <- from:nrow(b); i[pm_first(test(i))] }   # first candle from `from` passing test(i)
pm_cut <- function(b, upto) { x <- b[seq_len(upto), ]; attributes(x)[c("pos", "anchors")] <- attributes(b)[c("pos", "anchors")]; x }

# a line through two turning points as a function of the candle index
pm_lfun <- function(p1, p2) function(x) p1[2] + (p2[2] - p1[2]) / (p2[1] - p1[1]) * (x - p1[1])

# ---- STEP 2 ----------------------------------------------------------------------------------------------------
pm_ex <- list()
pm_ex$fib_retracement <- function(s = 1, r = 0.5) {   # s = 1: up leg A-B, pullback to the r retracement; s = -1: mirror
  nm <- c("0.382" = "38.2%", "0.5" = "50%", "0.618" = "61.8%")[[as.character(r)]]
  b <- pm_build(list(pm_A(0, if (s > 0) "L" else "H", NA, "A"), pm_A(s * 6, if (s > 0) "H" else "L", 22, "B"), pm_A(s * 6 * (1 - r), if (s > 0) "L" else "H", 12, nm), pm_A(s * (6 * (1 - r) + 0.5), "", 3)), drift = -s * 2)
  t0 <- pm_truth(b, "fib_retracement"); A <- pm_pt(t0, "A"); B <- pm_pt(t0, "B"); leg <- B[2] - A[2]; n <- nrow(b)
  lv <- B[2] - leg * c(0.382, 0.5, 0.618, 0.786)
  ln <- do.call(rbind, Map(function(v, nm_) pm_hl(A[1], n, v, "#b45309", "dot", nm_), lv, c("38.2%", "50%", "61.8%", "78.6%")))
  pm_truth(b, "fib_retracement", lines = rbind(pm_ln(A, B, col = cc_bias_col(if (s > 0) "bullish" else "bearish"), name = "Leg A-B"), ln), cancel = lv[4], target = B[2], level = B[2] - leg * r,
           note = sprintf("%s leg A-B of 6 u; the pullback holds at exactly %s and turns back in the trend's direction.", if (s > 0) "Up" else "Down", nm)) }
pm_ex$fib_expansion <- function(s = 1) {
  b <- pm_build(list(pm_A(0, if (s > 0) "L" else "H", NA, "A"), pm_A(s * 5, if (s > 0) "H" else "L", 20, "B"), pm_A(s * 2.5, if (s > 0) "L" else "H", 10, "C"), pm_A(s * 4.2, "", 7)), drift = -s * 2)
  t0 <- pm_truth(b, "fib_expansion"); A <- pm_pt(t0, "A"); B <- pm_pt(t0, "B"); C <- pm_pt(t0, "C"); leg <- B[2] - A[2]; n <- nrow(b)
  pm_truth(b, "fib_expansion", lines = rbind(pm_ln(A, B, col = "#b45309", name = "A-B"), pm_ln(B, C, col = "#b45309", name = "B-C"),
           pm_hl(C[1], n, C[2] + leg, "#b45309", "dash", "100% expansion"), pm_hl(C[1], n, C[2] + 1.272 * leg, "#b45309", "dot", "127.2%"), pm_hl(C[1], n, C[2] + 1.618 * leg, "#b45309", "dot", "161.8%")),
           cancel = C[2] - s * 0.2 * utils::tail(pm_atr(b), 1), target = C[2] + leg, level = C[2] + leg, note = "B-C retraces 50% of A-B; the next leg is projected 100% (127.2%, 161.8%) of A-B from C.") }
# triangles and wedges: the turning points sit exactly on two straight lines (upper through the highs, lower through the lows)
pm_tri <- function(key, up0, up_s, lo0, lo_s, last, prior = c("L", 0), drift = 0) {
  xs <- c(0, 10, 20, 30, 40, 50); ty <- rep(c("H", "L"), 3)
  pr <- ifelse(ty == "H", up0 + up_s * xs, lo0 + lo_s * xs); labs <- c("H1", "L1", "H2", "L2", "H3", "L3")
  an <- c(list(pm_A(as.numeric(prior[2]), prior[1], NA, "")), Map(function(p, t, l, k) pm_A(p, t, if (k == 1) NA else 10, l), pr, ty, labs, seq_along(pr)), list(pm_A(last, "", 4)))
  b <- pm_build(an, drift = drift); t0 <- pm_truth(b, key); n <- nrow(b)
  H <- t0$points[t0$points$type == "H", ]; L <- t0$points[t0$points$type == "L", ]
  fu <- pm_lfun(c(H$i[1], H$price[1]), c(H$i[3], H$price[3])); fl <- pm_lfun(c(L$i[1], L$price[1]), c(L$i[3], L$price[3]))
  x0 <- min(H$i[1], L$i[1]); w0 <- fu(x0) - fl(x0); a <- utils::tail(pm_atr(b), 1)   # the definition: target = breakout side + the starting height (wedges: back to where they began)
  dir <- switch(key, asc_triangle = 1, desc_triangle = -1, rising_wedge = -1, falling_wedge = 1, sym_triangle = if (drift < 0) -1 else 1)
  pm_truth(b, key, lines = rbind(data.frame(x0 = H$i[1], y0 = fu(H$i[1]), x1 = n, y1 = fu(n), color = "#7c3aed", dash = "solid", name = "Upper line (through the highs)", stringsAsFactors = FALSE),
                                 data.frame(x0 = L$i[1], y0 = fl(L$i[1]), x1 = n, y1 = fl(n), color = "#7c3aed", dash = "solid", name = "Lower line (through the lows)", stringsAsFactors = FALSE)),
           level = NA, note = sprintf("Three highs on one straight line (slope %+.2f u per candle) and three lows on another (%+.2f u per candle).", up_s, lo_s),
           cancel = if (dir > 0) fl(n) - 0.2 * a else fu(n) + 0.2 * a,
           target = if (grepl("wedge", key)) b$close[min(H$i[1], L$i[1])] else if (dir > 0) fu(n) + w0 else fl(n) - w0) }
pm_ex$sym_triangle <- function(ctx = 0) pm_tri("sym_triangle", 6, -0.04, 1, 0.03, 3.2, c("L", 3), drift = 3 * ctx)
pm_ex$asc_triangle <- function() pm_tri("asc_triangle", 5, 0, 1, 0.05, 4.3, c("L", 2))
pm_ex$desc_triangle <- function() pm_tri("desc_triangle", 6, -0.05, 2, 0, 2.6, c("H", 3))
pm_ex$rising_wedge <- function(ctx = 0) pm_tri("rising_wedge", 5, 0.03, 1, 0.08, 5.9, c("L", 2), drift = 3 * ctx)
pm_ex$falling_wedge <- function(ctx = 0) pm_tri("falling_wedge", 6, -0.08, 2, -0.03, 1.1, c("H", 3), drift = 3 * ctx)
# flags: a steep pole, then 12 candles drifting against it inside half of the pole
pm_flag <- function(key, side) { s <- side
  an <- list(pm_A(0, if (s > 0) "L" else "H", NA, "Pole start"), pm_A(s * 4, if (s > 0) "H" else "L", 7, "Pole end"))
  fl <- if (key == "pennant") s * c(3.0, 3.7, 3.3, 3.55) else s * c(3.3, 3.75, 3.0, 3.45)
  ty <- if (s > 0) c("L", "H", "L", "H") else c("H", "L", "H", "L")
  an <- c(an, Map(function(p, t) pm_A(p, t, 3, ""), fl, ty), list(pm_A(if (key == "pennant") s * 3.4 else s * 3.2, "", 2)))
  b <- pm_build(an, drift = -s * 1); t0 <- pm_truth(b, key); n <- nrow(b); P0 <- pm_pt(t0, "Pole start"); P1 <- pm_pt(t0, "Pole end")
  fx <- (P1[1] + 1):n; fh <- max(b$high[fx]); fln <- min(b$low[fx]); pole <- abs(P1[2] - P0[2])
  pm_truth(b, key, lines = rbind(pm_ln(P0, P1, col = "#0f766e", name = "Pole"), pm_hl(P1[1] + 1, n, fh, "#0f766e", "dot", "Flag high"), pm_hl(P1[1] + 1, n, fln, "#0f766e", "dot", "Flag low")),
           cancel = if (s > 0) fln - 0.2 * utils::tail(pm_atr(b), 1) else fh + 0.2 * utils::tail(pm_atr(b), 1), target = if (s > 0) fh + pole else fln - pole,
           note = sprintf("Pole of 4 u in 7 candles, then %d candles %s inside half of the pole.", length(fx), if (key == "pennant") "narrowing (lower highs, higher lows)" else "drifting against it")) }
pm_ex$bull_flag <- function() pm_flag("bull_flag", 1)
pm_ex$bear_flag <- function() pm_flag("bear_flag", -1)
pm_ex$pennant <- function(s = 1) pm_flag("pennant", s)
# double top / bottom: two equal extremes, a valley 3 u deep between them, then a close through the valley (neckline)
pm_double <- function(key, s) {
  b <- pm_build(list(pm_A(0, if (s > 0) "L" else "H", NA, ""), pm_A(s * 5, if (s > 0) "H" else "L", NA, if (s > 0) "Top 1" else "Bottom 1"),
                     pm_A(s * 2, if (s > 0) "L" else "H", NA, "Neckline"), pm_A(s * 5.05, if (s > 0) "H" else "L", NA, if (s > 0) "Top 2" else "Bottom 2"), pm_A(s * 1.3, "", 15)), drift = -s * 1)
  t0 <- pm_truth(b, key); n <- nrow(b); T1 <- t0$points[1, ]; NK <- pm_pt(t0, "Neckline"); T2 <- t0$points[3, ]; a <- utils::tail(pm_atr(b), 1)
  ev <- pm_after(b, T2$i + 1, function(i) if (s > 0) b$close[i] < NK[2] else b$close[i] > NK[2]); top <- if (s > 0) max(T1$price, T2$price) else min(T1$price, T2$price)
  pm_truth(b, key, lines = rbind(pm_ln(c(T1$i, T1$price), c(T2$i, T2$price), col = if (s > 0) "#dc2626" else "#16a34a", name = "The two extremes"), pm_hl(T1$i, n, NK[2], "#334155", "dash", "Neckline")),
           event = ev, cancel = top + s * 0.3 * a, target = NK[2] - (top - NK[2]), level = NK[2], note = "Two equal extremes 3 u from the neckline; confirmed by the close through the neckline (marked).") }
pm_ex$double_top <- function() pm_double("double_top", 1)
pm_ex$double_bottom <- function() pm_double("double_bottom", -1)
pm_hs <- function(key, s) {
  b <- pm_build(list(pm_A(0, if (s > 0) "L" else "H", NA, ""), pm_A(s * 6, if (s > 0) "H" else "L", NA, "Left shoulder"), pm_A(s * 3.5, if (s > 0) "L" else "H", NA, "N1"),
                     pm_A(s * 8, if (s > 0) "H" else "L", NA, "Head"), pm_A(s * 3.6, if (s > 0) "L" else "H", NA, "N2"), pm_A(s * 6, if (s > 0) "H" else "L", NA, "Right shoulder"),
                     pm_A(s * 2.4, "", 15)), drift = -s * 1)
  t0 <- pm_truth(b, key); n <- nrow(b); N1 <- pm_pt(t0, "N1"); N2 <- pm_pt(t0, "N2"); HD <- pm_pt(t0, "Head"); RS <- pm_pt(t0, "Right shoulder"); LS <- pm_pt(t0, "Left shoulder")
  nl <- pm_lfun(N1, N2); a <- utils::tail(pm_atr(b), 1)
  ev <- pm_after(b, RS[1] + 1, function(i) if (s > 0) b$close[i] < nl(i) else b$close[i] > nl(i))
  col <- if (s > 0) "#dc2626" else "#16a34a"
  pm_truth(b, key, lines = rbind(pm_ln(LS, HD, col = col), pm_ln(HD, RS, col = col), pm_ln(N1, N2, to = n, col = "#334155", dash = "dash", name = "Neckline")),
           event = ev, cancel = RS[2] + s * 0.3 * a, target = nl(n) - (HD[2] - nl(HD[1])), level = nl(n), note = "Head 2 u beyond equal shoulders; neckline through the two reactions; confirmed by the close through the neckline (marked).") }
pm_ex$head_shoulders <- function() pm_hs("head_shoulders", 1)
pm_ex$inv_head_shoulders <- function() pm_hs("inv_head_shoulders", -1)

# ---- check: the app's rules (improved, v2) on the example ------------------------------------------------------------
pm_detect <- function(b) cc_scan(b, 15, list(v2 = TRUE, horizon = 40), show_from = max(1L, nrow(b) - 150L), hist_step = nrow(b))
pm_check <- function(key, ex = pm_ex[[key]]()) {
  b <- ex$b; tr <- ex
  s <- pm_detect(b); o <- Filter(function(z) identical(z$key, key), s$current); o <- if (length(o)) o[[1]] else NULL
  a <- utils::tail(s$ctx$a, 1); res <- list(key = key, found = !is.null(o), status = if (is.null(o)) NA else o$status)
  if (!is.null(o) && !is.null(tr$points) && nrow(tr$points) && length(o$marks)) {   # every truth turning point matched by a detected key candle (+-1)
    d <- vapply(tr$points$i, function(i) min(abs(o$marks - i)), 0); res$points_ok <- all(d <= 1); res$points_off <- max(d) } else res$points_ok <- NA
  if (!is.null(o) && is.finite(tr$level) && is.finite(o$level %||% NA)) res$level_off_atr <- abs(o$level - tr$level) / a
  kind <- cc_catalog$kind[match(key, cc_catalog$key)]   # signals (candles, indicators, strategies): the detected signal candle is the example's
  if (!is.null(o) && kind %in% c("candle", "indicator", "state", "strategy")) res$event_ok <- o$i1 == tr$event
  res$ok <- isTRUE(res$found) && !isFALSE(res$points_ok) && (is.null(res$level_off_atr) || res$level_off_atr <= 0.15) && !isFALSE(res$event_ok) && !isTRUE(tr$failed)
  res$scan <- s; res$occ <- o; res$truth <- tr; res$bars <- b; res
}

# ---- the chart of one example: the truth geometry drawn on the candles, the app's detection over it --------------------
pm_chart <- function(chk, show_detected = TRUE) {
  tr <- chk$truth; b <- chk$bars; n <- nrow(b); r <- cc_cat_row(tr$key); col <- cc_bias_col(r$bias)
  s0 <- max(1L, min(c(tr$span[1], tr$points$i, tr$event, n - 30L, tr$view), na.rm = TRUE) - 15L)
  if (identical(cc_catalog$kind[match(tr$key, cc_catalog$key)], "candle")) s0 <- max(1L, n - 24L)   # 2-5 candle patterns: the last 25 candles, so the candles are readable
  ix <- s0:n
  hover <- sprintf("Candle %d, %s UK<br>O %.3f H %.3f<br>L %.3f C %.3f", ix, format(b$time[ix], "%d/%m %H:%M", tz = "Europe/London"), b$open[ix], b$high[ix], b$low[ix], b$close[ix])
  p <- plotly::plot_ly(x = ix, type = "candlestick", open = b$open[ix], high = b$high[ix], low = b$low[ix], close = b$close[ix], text = hover, hoverinfo = "text", name = "Price",
                       increasing = list(line = list(color = "#16a34a")), decreasing = list(line = list(color = "#dc2626")), showlegend = FALSE)
  shapes <- list(); ann <- list(); xr <- c(s0 - 1, n + max(10, round(0.18 * length(ix))))
  a <- utils::tail(chk$scan$ctx$a, 1)
  # the span of the pattern
  sp <- c(max(s0, tr$span[1]), tr$span[2])
  shapes[[length(shapes) + 1]] <- list(type = "rect", xref = "x", yref = "paper", x0 = sp[1] - 0.5, x1 = sp[2] + 0.5, y0 = 0, y1 = 1, fillcolor = cc_alpha(col, 0.06), line = list(width = 0), layer = "below")
  # truth lines (through the exact highs / lows)
  if (!is.null(tr$lines) && nrow(tr$lines)) for (j in seq_len(nrow(tr$lines))) { z <- tr$lines[j, ]
    shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", yref = "y", x0 = z$x0, x1 = z$x1, y0 = z$y0, y1 = z$y1, line = list(color = z$color, dash = z$dash, width = 2.6))
    if (nzchar(z$name)) ann[[length(ann) + 1]] <- list(x = z$x1, y = z$y1, xref = "x", yref = "y", text = z$name, showarrow = FALSE, xanchor = "left", font = list(size = 10, color = z$color)) }
  # labelled turning points, exactly on the candle's high or low
  if (!is.null(tr$points) && nrow(tr$points)) {
    up <- tr$points$type != "L"
    p <- plotly::add_markers(p, x = tr$points$i, y = tr$points$price, inherit = FALSE, showlegend = FALSE, hoverinfo = "text",
                             text = sprintf("%s: candle %d, %s %.3f", tr$points$lab, tr$points$i, ifelse(tr$points$type == "L", "low", ifelse(tr$points$type == "H", "high", "close")), tr$points$price),
                             marker = list(symbol = "circle", size = 9, color = col, line = list(color = "#ffffff", width = 1.5)))
    for (k in seq_len(nrow(tr$points))) ann[[length(ann) + 1]] <- list(x = tr$points$i[k], y = tr$points$price[k], xref = "x", yref = "y", text = sprintf("<b>%s</b>", tr$points$lab[k]),
      showarrow = TRUE, arrowhead = 0, ax = 0, ay = if (up[k]) -22 else 22, font = list(size = 11, color = "#0f172a"), bgcolor = "rgba(255,255,255,0.85)") }
  # context points (e.g. the previous day's high / low / close behind the pivots): drawn, not part of the check
  if (!is.null(tr$context) && nrow(tr$context)) { cx <- tr$context
    p <- plotly::add_markers(p, x = cx$i, y = cx$price, inherit = FALSE, showlegend = FALSE, hoverinfo = "text", text = sprintf("%s %.3f", cx$lab, cx$price), marker = list(symbol = "diamond", size = 9, color = "#334155"))
    for (k in seq_len(nrow(cx))) ann[[length(ann) + 1]] <- list(x = cx$i[k], y = cx$price[k], xref = "x", yref = "y", text = cx$lab[k], showarrow = TRUE, arrowhead = 0, ax = 0, ay = if (cx$type[k] == "L") 20 else -20, font = list(size = 10, color = "#334155")) }
  # the candle that completes / confirms it
  if (is.finite(tr$event)) { shapes[[length(shapes) + 1]] <- list(type = "rect", xref = "x", yref = "paper", x0 = tr$event - 0.5, x1 = tr$event + 0.5, y0 = 0, y1 = 1, fillcolor = "rgba(250,204,21,0.25)", line = list(width = 0), layer = "below")
    ann[[length(ann) + 1]] <- list(x = tr$event, y = 1, xref = "x", yref = "paper", text = "completes here", showarrow = FALSE, yanchor = "bottom", font = list(size = 10, color = "#a16207")) }
  # entry / cancel / target from the definition
  for (lv in list(list(v = tr$entry, nm = "Entry", c = "#1d4ed8"), list(v = tr$cancel, nm = "Cancel", c = "#b91c1c"), list(v = tr$target, nm = "Target", c = "#15803d"))) { v <- as.numeric(lv$v %||% NA)
    if (!is.finite(v)) next
    shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", yref = "y", x0 = min(n, tr$event %||% n), x1 = xr[2], y0 = v, y1 = v, line = list(color = lv$c, dash = "dash", width = 1.6))
    ann[[length(ann) + 1]] <- list(x = xr[2], y = v, xref = "x", yref = "y", text = sprintf("%s %.3f", lv$nm, v), showarrow = FALSE, xanchor = "right", yanchor = "bottom", font = list(size = 10, color = lv$c)) }
  # after the signal: how the example plays out (course examples: target hit / failed)
  if (!is.null(chk$outcome)) { e0 <- chk$outcome$from
    shapes[[length(shapes) + 1]] <- list(type = "rect", xref = "x", yref = "paper", x0 = e0 + 0.5, x1 = n + 0.5, y0 = 0, y1 = 1, fillcolor = "rgba(148,163,184,0.10)", line = list(width = 0), layer = "below")
    ann[[length(ann) + 1]] <- list(x = n, y = b$close[n], xref = "x", yref = "y", text = sprintf("<b>%s</b>", chk$outcome$label), showarrow = TRUE, ax = -40, ay = -30,
                                   font = list(size = 11, color = chk$outcome$color), bgcolor = "rgba(255,255,255,0.9)", bordercolor = chk$outcome$color) }
  # what the app's rules found on the same candles (grey, dotted), and their key candles (open squares)
  o <- chk$occ
  if (show_detected && !is.null(o)) {
    if (!is.null(o$lines) && nrow(o$lines)) for (j in seq_len(nrow(o$lines))) { z <- o$lines[j, ]
      shapes[[length(shapes) + 1]] <- list(type = "line", xref = "x", yref = "y", x0 = z$x0, x1 = z$x1, y0 = z$y0, y1 = z$y1, line = list(color = "#475569", dash = "dot", width = 1.6)) }
    km <- unique(o$marks %||% integer(0)); km <- km[km >= s0 & km <= n]
    if (length(km)) { yy <- vapply(km, function(i) { cand <- c(b$high[i], b$low[i]); ref <- c(tr$points$price, o$level); ref <- ref[is.finite(ref)]
        if (!length(ref)) b$high[i] else cand[which.min(vapply(cand, function(v) min(abs(v - ref)), 0))] }, 0)
      p <- plotly::add_markers(p, x = km, y = yy, inherit = FALSE, showlegend = FALSE, hoverinfo = "text", text = sprintf("Found by the app's rules: candle %d", km),
                               marker = list(symbol = "square-open", size = 15, color = "#475569", line = list(width = 2))) } }
  d <- chk$scan$ctx$ind; ov <- tr$overlay %||% NA
  if (identical(ov, "ema")) for (m in list(c("ema20", "#2563eb", "EMA20"), c("ema50", "#f59e0b", "EMA50"), c("ema200", "#7c3aed", "EMA200")))
    p <- plotly::add_lines(p, x = ix, y = d[[m[1]]][ix], name = m[3], line = list(color = m[2], width = 1.3), inherit = FALSE, hoverinfo = "skip", showlegend = TRUE)
  if (ov %in% c("bb", "kc")) { for (m in list(c("bb_up", "Upper band"), c("bb_mid", "Middle band"), c("bb_dn", "Lower band")))
      p <- plotly::add_lines(p, x = ix, y = d[[m[1]]][ix], name = m[2], line = list(color = "#0ea5e9", width = 1.2, dash = if (m[1] == "bb_mid") "dot" else "solid"), inherit = FALSE, hoverinfo = "skip")
    if (identical(ov, "kc")) for (m in list(c("kc_up", "Keltner upper"), c("kc_dn", "Keltner lower")))
      p <- plotly::add_lines(p, x = ix, y = d[[m[1]]][ix], name = m[2], line = list(color = "#f97316", width = 1.2, dash = "dash"), inherit = FALSE, hoverinfo = "skip") }
  rng <- range(c(b$low[ix], b$high[ix], tr$cancel, tr$target), na.rm = TRUE); pad <- diff(rng) * 0.1
  tk <- unique(round(seq(s0, n, length.out = 8)))
  xa <- list(rangeslider = list(visible = FALSE), range = xr, tickvals = tk, ticktext = format(b$time[tk], "%d/%m %H:%M", tz = "Europe/London"), title = "")
  p <- plotly::layout(p, shapes = shapes, annotations = ann, margin = list(t = 30, r = 10, b = 40), xaxis = xa, yaxis = list(title = "Price", range = c(rng[1] - pad, rng[2] + pad)),
                      legend = list(orientation = "h", y = 1.08, x = 0))
  pn <- tr$panel %||% NA; if (is.na(pn)) return(p)
  # the indicator behind the signal, with its thresholds and the signal candle marked
  q <- plotly::plot_ly(); hl <- numeric(0); ev <- tr$event
  add <- function(q, col, nm, colr, dash = "solid") plotly::add_lines(q, x = ix, y = d[[col]][ix], name = nm, line = list(color = colr, width = 1.4, dash = dash))
  if (pn == "RSI") { q <- add(q, "rsi", "RSI(14)", "#7c3aed"); hl <- c(30, 50, 70); yv <- d$rsi[ev] }
  if (pn == "MACD") { q <- plotly::add_bars(q, x = ix, y = d$macd_hist[ix], name = "Histogram", marker = list(color = ifelse(d$macd_hist[ix] >= 0, "#86efac", "#fca5a5")))
    q <- add(q, "macd", "MACD", "#2563eb"); q <- add(q, "macd_signal", "Signal", "#f59e0b"); hl <- 0; yv <- d$macd[ev] }
  if (pn == "Stochastic") { q <- add(q, "stoch_k", "%K", "#2563eb"); q <- add(q, "stoch_d", "%D", "#f59e0b"); hl <- c(20, 80); yv <- d$stoch_k[ev] }
  if (pn == "ADX") { q <- add(q, "adx", "ADX", "#111827"); q <- add(q, "di_p", "DI+", "#16a34a"); q <- add(q, "di_n", "DI-", "#dc2626"); hl <- c(20, 25, 30); yv <- d$adx[ev] }
  if (pn == "ATR") { q <- add(q, "atr", "ATR(14)", "#0f766e"); yv <- d$atr[ev] }
  q <- plotly::add_markers(q, x = ev, y = yv, inherit = FALSE, showlegend = FALSE, marker = list(size = 11, color = col, symbol = "circle", line = list(color = "#fff", width = 1.5)), hoverinfo = "text", text = "Signal candle")
  # divergence: the indicator at the two price swings, joined
  if (!is.null(tr$points) && nrow(tr$points) == 2 && grepl("div", tr$key)) { yy <- switch(pn, RSI = d$rsi, MACD = d$macd, Stochastic = d$stoch_k)[tr$points$i]
    q <- plotly::add_trace(q, x = tr$points$i, y = yy, type = "scatter", mode = "lines+markers", inherit = FALSE, showlegend = FALSE, line = list(color = col, width = 2.4), marker = list(size = 9, color = col)) }
  q <- plotly::layout(q, shapes = lapply(hl, function(v) list(type = "line", xref = "x", yref = "y", x0 = xr[1], x1 = xr[2], y0 = v, y1 = v, line = list(color = "#94a3b8", dash = "dot", width = 1))),
                      yaxis = list(title = pn), xaxis = xa)
  plotly::subplot(p, q, nrows = 2, shareX = TRUE, heights = c(0.7, 0.3), titleY = TRUE, margin = 0.03)
}

# ---- STEP 1: trend & market structure -------------------------------------------------------------------------------
pm_lab_pts <- function(b, idx, labs, type) data.frame(i = idx, price = ifelse(type == "L", b$low[idx], b$high[idx]), type = type, lab = labs, stringsAsFactors = FALSE)
pm_dow <- function(key, s) {   # two higher highs and two higher lows (mirror for down)
  ty <- if (s > 0) c("L", "H", "L", "H", "L") else c("H", "L", "H", "L", "H"); pr <- s * c(0, 3, 1.5, 4.5, 3)
  lb <- if (s > 0) c("", "H1", "L1", "H2 (higher high)", "L2 (higher low)") else c("", "L1", "H1", "L2 (lower low)", "H2 (lower high)")
  b <- pm_build(c(Map(function(p, t, l) pm_A(p, t, NA, l), pr, ty, lb), list(pm_A(s * 4, "", 4))), drift = -s)
  t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b); H <- P[P$type == "H", ]; L <- P[P$type == "L", ]
  pm_truth(b, key, lines = rbind(pm_ln(c(H$i[1], H$price[1]), c(H$i[2], H$price[2]), col = cc_bias_col(if (s > 0) "bullish" else "bearish"), name = if (s > 0) "Higher high" else "Lower high"),
                                 pm_ln(c(L$i[1], L$price[1]), c(L$i[2], L$price[2]), col = cc_bias_col(if (s > 0) "bullish" else "bearish"), name = if (s > 0) "Higher low" else "Lower low")),
           cancel = if (s > 0) L$price[2] - 0.2 * utils::tail(pm_atr(b), 1) else H$price[2] + 0.2 * utils::tail(pm_atr(b), 1),
           note = "Two confirmed swing highs and two confirmed swing lows, each beyond the previous one by more than 0.1 ATR.") }
pm_ex$dow_up <- function() pm_dow("dow_up", 1)
pm_ex$dow_down <- function() pm_dow("dow_down", -1)
pm_level <- function(key, s) {   # three separate touches of one level, then price moving away (support: s = 1)
  ty <- if (s > 0) c("H", "L", "H", "L", "H", "L") else c("L", "H", "L", "H", "L", "H")
  pr <- s * c(3, 0, 2.5, 0.05, 2.6, 0); lb <- c("", "Touch 1", "", "Touch 2", "", "Touch 3")
  b <- pm_build(c(Map(function(p, t, l) pm_A(p, t, NA, l), pr, ty, lb), list(pm_A(s * 1.0, "", 5))), drift = s * 1)
  t0 <- pm_truth(b, key); P <- t0$points; lv <- mean(P$price); n <- nrow(b)
  pm_truth(b, key, lines = pm_hl(P$i[1], n, lv, cc_bias_col(if (s > 0) "bullish" else "bearish"), "dash", if (s > 0) "Support" else "Resistance"),
           level = lv, cancel = lv - s * 0.5 * utils::tail(pm_atr(b), 1), note = "Three separate swing lows (highs) within 0.05 u of one price; closes never went through it.") }
pm_ex$support <- function() pm_level("support", 1)
pm_ex$resistance <- function() pm_level("resistance", -1)
pm_role <- function(key, s) {   # s = -1: support broken, then retested from below (sup_to_res)
  if (s < 0) { ty <- c("H", "L", "H", "L", "H", "L", "H"); pr <- c(3, 0, 2, 0.05, 1.5, -2.5, -0.05); lb <- c("", "Support 1", "", "Support 2", "", "", "Retest") }
  else { ty <- c("L", "H", "L", "H", "L", "H", "L"); pr <- c(-3, 0, -2, -0.05, -1.5, 2.5, 0.05); lb <- c("", "Resistance 1", "", "Resistance 2", "", "", "Retest") }
  b <- pm_build(c(Map(function(p, t, l) pm_A(p, t, NA, l), pr, ty, lb), list(pm_A(s * 0.8, "", 4))), drift = 0)
  t0 <- pm_truth(b, key); P <- t0$points; lv <- mean(P$price[1:2]); n <- nrow(b); a <- utils::tail(pm_atr(b), 1)
  ev <- pm_after(b, P$i[2] + 1, function(i) if (s < 0) b$close[i] < lv - 0.3 * a else b$close[i] > lv + 0.3 * a)
  pm_truth(b, key, lines = pm_hl(P$i[1], n, lv, if (s < 0) "#dc2626" else "#16a34a", "dash", if (s < 0) "Old support, now resistance" else "Old resistance, now support"),
           level = lv, event = ev, cancel = lv - s * 0.5 * a, note = "Two touches make the level; a close through it (marked) breaks it; price comes back to it from the other side and is turned away.") }
pm_ex$sup_to_res <- function() pm_role("sup_to_res", -1)
pm_ex$res_to_sup <- function() pm_role("res_to_sup", 1)
# trend lines: three lows (highs) exactly on one rising (falling) line, 20 candles apart
pm_tline <- function(key, s, brk = FALSE) {
  slope <- 0.05; ty <- if (s > 0) c("L", "H", "L", "H", "L") else c("H", "L", "H", "L", "H")
  pr <- s * c(0, 2.2, 1, 3.2, 2); lb <- c("Touch 1", "", "Touch 2", "", "Touch 3")
  last <- if (!brk) list(pm_A(s * 3.6, "", 10)) else list(pm_A(s * 3.2, if (s > 0) "H" else "L", 6, ""), pm_A(s * 1.6, "", 8))
  b <- pm_build(c(list(pm_A(s * 1.5, if (s > 0) "H" else "L", NA, "")), Map(function(p, t, l) pm_A(p, t, 10, l), pr, ty, lb), last), drift = s * 0.5)
  t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b); f <- pm_lfun(c(P$i[1], P$price[1]), c(P$i[3], P$price[3])); a <- utils::tail(pm_atr(b), 1)
  ev <- if (brk) pm_after(b, P$i[3] + 1, function(i) if (s > 0) b$close[i] < f(i) - 0.35 * a else b$close[i] > f(i) + 0.35 * a) else n
  pm_truth(b, key, lines = data.frame(x0 = P$i[1], y0 = P$price[1], x1 = n, y1 = f(n), color = if (xor(s > 0, brk)) "#16a34a" else "#dc2626", dash = if (brk) "dash" else "solid",
                                      name = if (s > 0) "Uptrend line" else "Downtrend line", stringsAsFactors = FALSE),
           event = ev, level = f(n), cancel = if (!brk) f(n) - s * 0.5 * a else f(n) + s * 0.3 * a,
           note = if (brk) "A valid trend line (three touches) closed through by more than 0.35 ATR in the last candles: the trend it described is broken." else "Three swing lows (highs) exactly on one line; no close has gone through it.") }
pm_ex$uptrend_line <- function() pm_tline("uptrend_line", 1)
pm_ex$downtrend_line <- function() pm_tline("downtrend_line", -1)
pm_ex$broken_uptrend <- function() pm_tline("broken_uptrend", 1, TRUE)
pm_ex$broken_downtrend <- function() pm_tline("broken_downtrend", -1, TRUE)
pm_ctr <- function(key, s) {   # a pullback against the main trend; the line through its two reaction extremes is broken
  ty <- if (s > 0) c("L", "H", "L", "H", "L") else c("H", "L", "H", "L", "H"); pr <- s * c(0, 4, 2.6, 3.5, 2.4); lb <- c("", "Pullback high 1", "", "Pullback high 2", "")
  if (s < 0) lb <- c("", "Pullback low 1", "", "Pullback low 2", "")
  b <- pm_build(c(Map(function(p, t, l) pm_A(p, t, NA, l), pr, ty, lb), list(pm_A(s * 3.7, "", 6))), drift = -s * 6, lead = 300)
  t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b); f <- pm_lfun(c(P$i[1], P$price[1]), c(P$i[2], P$price[2])); a <- utils::tail(pm_atr(b), 1)
  ev <- pm_after(b, P$i[2] + 1, function(i) if (s > 0) b$close[i] > f(i) + 0.1 * a else b$close[i] < f(i) - 0.1 * a)
  pm_truth(b, key, lines = data.frame(x0 = P$i[1], y0 = P$price[1], x1 = n, y1 = f(n), color = "#a855f7", dash = "dash", name = "Countertrend line", stringsAsFactors = FALSE),
           event = ev, note = "Main trend up (EMA50 rising, price above EMA200); the pullback's falling line through its two highs is closed through: the trend resumes.") }
pm_ex$ctr_break_up <- function() pm_ctr("ctr_break_up", 1)
pm_ex$ctr_break_down <- function() pm_ctr("ctr_break_down", -1)
pm_chan <- function(key, s) {   # lows on one line, highs on a parallel line 2.5 u away
  xs <- c(0, 10, 20, 30, 40, 50); ty <- if (s > 0) rep(c("L", "H"), 3) else rep(c("H", "L"), 3)
  pr <- s * (0.05 * xs + ifelse(seq_along(xs) %% 2 == 0, 2.5, 0)); lb <- if (s > 0) c("L1", "H1", "L2", "H2", "L3", "H3") else c("H1", "L1", "H2", "L2", "H3", "L3")
  b <- pm_build(c(list(pm_A(s * 1.5, if (s > 0) "H" else "L", NA, "")), Map(function(p, t, l, k) pm_A(p, t, if (k == 1) NA else 10, l), pr, ty, lb, seq_along(pr)), list(pm_A(s * (0.05 * 54 + 1.1), "", 4))), drift = 0)
  t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b); A <- P[P$type == (if (s > 0) "L" else "H"), ]; B <- P[P$type == (if (s > 0) "H" else "L"), ]
  f1 <- pm_lfun(c(A$i[1], A$price[1]), c(A$i[3], A$price[3])); f2 <- function(x) f1(x) + (B$price[1] - f1(B$i[1]))
  pm_truth(b, key, lines = rbind(data.frame(x0 = A$i[1], y0 = f1(A$i[1]), x1 = n, y1 = f1(n), color = cc_bias_col(if (s > 0) "bullish" else "bearish"), dash = "solid", name = "Trend line", stringsAsFactors = FALSE),
                                 data.frame(x0 = B$i[1], y0 = f2(B$i[1]), x1 = n, y1 = f2(n), color = cc_bias_col(if (s > 0) "bullish" else "bearish"), dash = "solid", name = "Parallel line", stringsAsFactors = FALSE)),
           cancel = f1(n) - s * 0.5 * utils::tail(pm_atr(b), 1), target = f2(n), note = "Three touches on the trend line and three on a parallel line 2.5 u away; price is inside.") }
pm_ex$bull_channel <- function() pm_chan("bull_channel", 1)
pm_ex$bear_channel <- function() pm_chan("bear_channel", -1)

# candle patterns: a clear prior trend (3 u in 12 candles), then the pattern's candles given exactly (o, h, l, c in u)
pm_candles <- function(key, prior, rows, labs, note) {
  b <- pm_build(list(pm_A(-prior * 3, if (prior > 0) "L" else "H", NA, ""), pm_A(0, "", 12)), drift = -prior * 1)
  b <- pm_append(b, rows); n <- nrow(b); k <- nrow(rows); idx <- (n - k + 1):n
  pts <- data.frame(i = idx, price = b$high[idx], type = "H", lab = labs, stringsAsFactors = FALSE)
  dr <- cc_dir_of(cc_catalog$bias[cc_catalog$key == key]); a <- utils::tail(pm_atr(b), 1)
  cn <- if (is.na(dr)) NA else if (dr > 0) min(b$low[idx]) - 0.1 * a else max(b$high[idx]) + 0.1 * a   # the definition's stop: beyond the pattern by 0.1 ATR
  pm_truth(b, key, points = pts, span = c(idx[1], n), cancel = cn, note = note) }
pm_R <- function(o, h, l, c) c(o, h, l, c)
pm_ex$bull_engulfing <- function() pm_candles("bull_engulfing", -1, pm_ohlc(pm_R(0, 0.05, -0.45, -0.4), pm_R(-0.45, 0.15, -0.5, 0.1)), c("1", "2"), "A down candle, then an up candle whose body covers it (opens at or below its close, closes at or above its open).")
pm_ex$bear_engulfing <- function() pm_candles("bear_engulfing", 1, pm_ohlc(pm_R(0, 0.45, -0.05, 0.4), pm_R(0.45, 0.5, -0.15, -0.1)), c("1", "2"), "An up candle, then a down candle whose body covers it.")
pm_ex$piercing <- function() pm_candles("piercing", -1, pm_ohlc(pm_R(0, 0.05, -0.65, -0.6), pm_R(-0.7, -0.15, -0.75, -0.2)), c("1", "2"), "A long down candle, then an up candle opening below its close and closing above its midpoint (but below its open).")
pm_ex$dark_cloud <- function() pm_candles("dark_cloud", 1, pm_ohlc(pm_R(0, 0.65, -0.05, 0.6), pm_R(0.7, 0.75, 0.15, 0.2)), c("1", "2"), "A long up candle, then a down candle opening above its close and closing below its midpoint.")
pm_ex$bull_harami <- function() pm_candles("bull_harami", -1, pm_ohlc(pm_R(0, 0.05, -0.85, -0.8), pm_R(-0.6, -0.3, -0.65, -0.35)), c("1", "2"), "A long down candle, then a small up candle whose body sits inside it.")
pm_ex$bear_harami <- function() pm_candles("bear_harami", 1, pm_ohlc(pm_R(0, 0.85, -0.05, 0.8), pm_R(0.6, 0.65, 0.3, 0.35)), c("1", "2"), "A long up candle, then a small down candle whose body sits inside it.")
pm_ex$harami_cross <- function() pm_candles("harami_cross", -1, pm_ohlc(pm_R(0, 0.05, -0.85, -0.8), pm_R(-0.4, -0.25, -0.55, -0.41)), c("1", "2"), "A long candle, then a doji (open = close) inside its body: indecision after a move.")
pm_ex$morning_star <- function() pm_candles("morning_star", -1, pm_ohlc(pm_R(0, 0.05, -0.85, -0.8), pm_R(-0.85, -0.8, -1.0, -0.9), pm_R(-0.88, -0.2, -0.92, -0.25)), c("1", "2", "3"), "Long down candle, a small candle below its close, then an up candle closing above the first one's midpoint.")
pm_ex$evening_star <- function() pm_candles("evening_star", 1, pm_ohlc(pm_R(0, 0.85, -0.05, 0.8), pm_R(0.85, 1.0, 0.8, 0.9), pm_R(0.88, 0.92, 0.2, 0.25)), c("1", "2", "3"), "Long up candle, a small candle above its close, then a down candle closing below the first one's midpoint.")
pm_ex$three_white_soldiers <- function() pm_candles("three_white_soldiers", -1, pm_ohlc(pm_R(0, 0.55, -0.05, 0.5), pm_R(0.3, 0.9, 0.25, 0.85), pm_R(0.65, 1.25, 0.6, 1.2)), c("1", "2", "3"), "Three long up candles, each opening inside the previous body and closing near its high.")
pm_ex$three_black_crows <- function() pm_candles("three_black_crows", 1, pm_ohlc(pm_R(0, 0.05, -0.55, -0.5), pm_R(-0.3, -0.25, -0.9, -0.85), pm_R(-0.65, -0.6, -1.25, -1.2)), c("1", "2", "3"), "Three long down candles, each opening inside the previous body and closing near its low.")
pm_ex$tweezer_top <- function() pm_candles("tweezer_top", 1, pm_ohlc(pm_R(0, 0.5, -0.05, 0.4), pm_R(0.4, 0.5, -0.05, 0.0)), c("1", "2"), "An up candle and a down candle with the same high, at the highest point of the last 10 candles.")
pm_ex$tweezer_bottom <- function() pm_candles("tweezer_bottom", -1, pm_ohlc(pm_R(0, 0.05, -0.5, -0.4), pm_R(-0.4, 0.05, -0.5, 0.0)), c("1", "2"), "A down candle and an up candle with the same low, at the lowest point of the last 10 candles.")
pm_ex$rising_three <- function() pm_candles("rising_three", 1, pm_ohlc(pm_R(0, 0.95, -0.05, 0.9), pm_R(0.85, 0.88, 0.65, 0.7), pm_R(0.7, 0.75, 0.5, 0.55), pm_R(0.55, 0.7, 0.5, 0.65), pm_R(0.65, 1.35, 0.6, 1.3)), c("1", "2", "3", "4", "5"), "A long up candle, three small candles inside its range (mostly down), then an up candle closing above the first.")
pm_ex$falling_three <- function() pm_candles("falling_three", -1, pm_ohlc(pm_R(0, 0.05, -0.95, -0.9), pm_R(-0.85, -0.65, -0.88, -0.7), pm_R(-0.7, -0.5, -0.75, -0.55), pm_R(-0.55, -0.5, -0.7, -0.65), pm_R(-0.65, -0.6, -1.35, -1.3)), c("1", "2", "3", "4", "5"), "A long down candle, three small candles inside its range (mostly up), then a down candle closing below the first.")
pm_ex$three_inside_up <- function() pm_candles("three_inside_up", -1, pm_ohlc(pm_R(0, 0.05, -0.85, -0.8), pm_R(-0.6, -0.3, -0.65, -0.35), pm_R(-0.35, 0.25, -0.4, 0.2)), c("1", "2", "3"), "A bullish harami, then a candle closing above the first candle's open.")
pm_ex$three_inside_down <- function() pm_candles("three_inside_down", 1, pm_ohlc(pm_R(0, 0.85, -0.05, 0.8), pm_R(0.6, 0.65, 0.3, 0.35), pm_R(0.35, 0.4, -0.25, -0.2)), c("1", "2", "3"), "A bearish harami, then a candle closing below the first candle's open.")
pm_ex$three_outside_up <- function() pm_candles("three_outside_up", -1, pm_ohlc(pm_R(0, 0.05, -0.45, -0.4), pm_R(-0.45, 0.15, -0.5, 0.1), pm_R(0.1, 0.5, 0.05, 0.45)), c("1", "2", "3"), "A bullish engulfing, then a higher close.")
pm_ex$three_outside_down <- function() pm_candles("three_outside_down", 1, pm_ohlc(pm_R(0, 0.45, -0.05, 0.4), pm_R(0.45, 0.5, -0.15, -0.1), pm_R(-0.1, -0.05, -0.5, -0.45)), c("1", "2", "3"), "A bearish engulfing, then a lower close.")
pm_ex$bull_kicker <- function() pm_candles("bull_kicker", -1, pm_ohlc(pm_R(0, 0.03, -0.45, -0.4), pm_R(0.15, 0.8, 0.12, 0.75)), c("1", "2"), "A down candle, then an up candle opening above its open with no overlap at all.")
pm_ex$bear_kicker <- function() pm_candles("bear_kicker", 1, pm_ohlc(pm_R(0, 0.45, -0.03, 0.4), pm_R(-0.15, -0.12, -0.8, -0.75)), c("1", "2"), "An up candle, then a down candle opening below its open with no overlap at all.")
pm_ex$stick_sandwich <- function() pm_candles("stick_sandwich", -1, pm_ohlc(pm_R(0, 0.05, -0.55, -0.5), pm_R(-0.45, -0.05, -0.5, -0.1), pm_R(-0.05, 0.0, -0.55, -0.5)), c("1", "2", "3"), "Down, up, down, with the two down candles closing at the same price.")
pm_ex$matching_low <- function() pm_candles("matching_low", -1, pm_ohlc(pm_R(0, 0.05, -0.55, -0.5), pm_R(-0.2, -0.15, -0.55, -0.5)), c("1", "2"), "Two down candles closing at the same price after a fall.")
pm_ex$sep_lines_bull <- function() pm_candles("sep_lines_bull", 1, pm_ohlc(pm_R(0, 0.03, -0.45, -0.4), pm_R(0.0, 0.55, -0.03, 0.5)), c("1", "2"), "In an uptrend, a down candle, then an up candle opening at the same price as its open.")
pm_ex$sep_lines_bear <- function() pm_candles("sep_lines_bear", -1, pm_ohlc(pm_R(0, 0.45, -0.03, 0.4), pm_R(0.0, 0.03, -0.55, -0.5)), c("1", "2"), "In a downtrend, an up candle, then a down candle opening at the same price as its open.")

# ---- STEP 3: more shapes, ranges, gaps, traps ------------------------------------------------------------------------
pm_seq <- function(pr, ty, lb, lens = NA) Map(function(p, t, l, n_) pm_A(p, t, n_, l), pr, ty, lb, rep_len(lens, length(pr)))
pm_triple <- function(key, s) {
  ty <- if (s > 0) c("L", "H", "L", "H", "L", "H") else c("H", "L", "H", "L", "H", "L"); pr <- s * c(0, 5, 2.5, 5.05, 2.6, 4.98)
  lb <- if (s > 0) c("", "Top 1", "Valley 1", "Top 2", "Valley 2", "Top 3") else c("", "Low 1", "Peak 1", "Low 2", "Peak 2", "Low 3")
  b <- pm_build(c(pm_seq(pr, ty, lb), list(pm_A(s * 1.8, "", 13))), drift = -s)
  t0 <- pm_truth(b, key); P <- t0$points; T3 <- P[P$lab %in% c("Top 3", "Low 3"), ]; V <- P[grepl("Valley|Peak", P$lab), ]; n <- nrow(b); a <- utils::tail(pm_atr(b), 1)
  nk <- if (s > 0) min(V$price) else max(V$price); X <- P[grepl("Top|Low", P$lab), ]; top <- if (s > 0) max(X$price) else min(X$price)
  ev <- pm_after(b, T3$i + 1, function(i) if (s > 0) b$close[i] < nk else b$close[i] > nk)
  pm_truth(b, key, lines = rbind(pm_hl(X$i[1], T3$i, mean(X$price), cc_bias_col(if (s > 0) "bearish" else "bullish"), "dash", if (s > 0) "Three tops" else "Three lows"), pm_hl(X$i[1], n, nk, "#334155", "dash", "Neckline")),
           event = ev, level = nk, cancel = top + s * 0.3 * a, target = nk - (top - nk), note = "Three extremes within 0.1 u of each other, valleys 2.4 u deep; confirmed by the close through the neckline.") }
pm_ex$triple_top <- function() pm_triple("triple_top", 1)
pm_ex$triple_bottom <- function() pm_triple("triple_bottom", -1)
pm_ex$rectangle <- function() {
  b <- pm_build(c(list(pm_A(4, "H", NA, "")), pm_seq(c(0, 3, 0.05, 3.05, 0, 2.95), c("L", "H", "L", "H", "L", "H"), c("Low 1", "High 1", "Low 2", "High 2", "Low 3", "High 3")), list(pm_A(1, "", 8))), drift = 1)
  t0 <- pm_truth(b, "rectangle"); P <- t0$points; n <- nrow(b); top <- stats::median(P$price[P$type == "H"]); bot <- stats::median(P$price[P$type == "L"]); a <- utils::tail(pm_atr(b), 1)
  pm_truth(b, "rectangle", lines = rbind(pm_hl(P$i[1], n, top, "#64748b", "solid", "Range top"), pm_hl(P$i[1], n, bot, "#64748b", "solid", "Range bottom")),
           cancel = bot - 0.5 * a, target = top, note = "Three highs and three lows each within 0.05 u of one level; price in the lower half, so the trade is from the bottom to the top.") }
pm_cup <- function(key, s) {
  tt <- seq(0, 1, length.out = 19)[-c(1, 19)]; cup <- s * (5 - 4 * sin(pi * tt))
  an <- c(list(pm_A(s * 2, if (s > 0) "L" else "H", NA, ""), pm_A(s * 5, if (s > 0) "H" else "L", NA, "Rim 1")),
          Map(function(p, k) pm_A(p, if (k == 9) (if (s > 0) "L" else "H") else "", 2, if (k == 9) "Cup bottom" else ""), cup, seq_along(cup)),
          list(pm_A(s * 5.02, if (s > 0) "H" else "L", 2, "Rim 2"), pm_A(s * 4.0, if (s > 0) "L" else "H", 4, "Handle"), pm_A(s * 4.5, "", 4)))
  b <- pm_build(an, drift = -s); t0 <- pm_truth(b, key); n <- nrow(b); R1 <- pm_pt(t0, "Rim 1"); R2 <- pm_pt(t0, "Rim 2"); HD <- pm_pt(t0, "Handle"); BT <- pm_pt(t0, "Cup bottom")
  rim <- if (s > 0) min(R1[2], R2[2]) else max(R1[2], R2[2]); depth <- s * (rim - BT[2]); a <- utils::tail(pm_atr(b), 1)
  pm_truth(b, key, lines = rbind(pm_hl(R1[1], n, rim, "#0ea5e9", "dash", "Rim"), pm_hl(R2[1], n, HD[2], "#0ea5e9", "dot", "Handle low")),
           level = rim, cancel = HD[2] - s * 0.2 * a, target = rim + s * depth, note = "A rounded cup 4 u deep between two equal rims, then a short handle that holds in the cup's upper half.") }
pm_ex$cup_handle <- function() pm_cup("cup_handle", 1)
pm_ex$inv_cup_handle <- function() pm_cup("inv_cup_handle", -1)
pm_round <- function(key, s) {   # closes on a parabola over 50 candles: 4 u deep, turning in the middle
  tt <- seq(2, 50, by = 2); y <- 4 * ((tt - 25) / 25)^2; if (s < 0) y <- -y
  an <- c(list(pm_A(if (s > 0) 4 else -4, "", NA, "Left lip")), Map(function(p, k) pm_A(p, if (tt[k] == 26) (if (s > 0) "L" else "H") else "", 2, if (tt[k] == 26) (if (s > 0) "Bottom" else "Top") else ""), y, seq_along(y)))
  an[[length(an)]]$lab <- "Right side"
  b <- pm_build(an, drift = 0, noise = 0.02); t0 <- pm_truth(b, key); n <- nrow(b); P <- attr(b, "pos")
  xs <- P; ys <- b$close[P]; ln <- do.call(rbind, lapply(seq_len(length(xs) - 1), function(k) data.frame(x0 = xs[k], y0 = ys[k], x1 = xs[k + 1], y1 = ys[k + 1], color = cc_bias_col(if (s > 0) "bullish" else "bearish"), dash = "dot", name = "", stringsAsFactors = FALSE)))
  t <- pm_truth(b, key, lines = ln, cancel = if (s > 0) min(b$low[P[1]:n]) - 0.2 * utils::tail(pm_atr(b), 1) else max(b$high[P[1]:n]) + 0.2 * utils::tail(pm_atr(b), 1), target = b$close[P[1]],
           note = "Closes follow a smooth curve (a parabola) 4 u deep over 50 candles, turning in the middle third; price is now rising (falling) out of it.")
  t$points$price <- b$close[t$points$i]; t$points$type <- ""; t }   # the rule fits the closes: the points sit on the curve through them
pm_ex$rounding_bottom <- function() pm_round("rounding_bottom", 1)
pm_ex$rounding_top <- function() pm_round("rounding_top", -1)
pm_diamond <- function(key, s) {   # widening in the first half, narrowing in the second, the extreme in the middle
  xs <- c(4, 11, 19, 27, 33, 41, 48, 55); ty <- if (s > 0) c("H", "L", "H", "L", "H", "L", "H", "L") else c("L", "H", "L", "H", "L", "H", "L", "H")
  pr <- s * c(3, 2, 4, 1, 4.6, 1.6, 3.8, 2.4); lb <- paste0(ifelse(ty == "H", "H", "L"), c(1, 1, 2, 2, 3, 3, 4, 4))
  lens <- c(NA, diff(xs)); an <- c(list(pm_A(s * 2.5, "", NA, "")), pm_seq(pr, ty, lb, c(4, lens[-1])), list(pm_A(s * 3.3, "", 4)))
  b <- pm_build(an, drift = s * 2); t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b)
  H <- P[P$type == "H", ]; L <- P[P$type == "L", ]; mx <- if (s > 0) which.max(H$price) else which.min(L$price)
  O <- if (s > 0) H else L; I <- if (s > 0) L else H; om <- if (s > 0) which.max(O$price) else which.min(O$price); im <- if (s > 0) which.min(I$price) else which.max(I$price)
  ln <- rbind(pm_ln(c(O$i[1], O$price[1]), c(O$i[om], O$price[om]), col = "#7c3aed"), pm_ln(c(O$i[om], O$price[om]), c(O$i[nrow(O)], O$price[nrow(O)]), col = "#7c3aed"),
              pm_ln(c(I$i[1], I$price[1]), c(I$i[im], I$price[im]), col = "#7c3aed"), pm_ln(c(I$i[im], I$price[im]), c(I$i[nrow(I)], I$price[nrow(I)]), col = "#7c3aed"))
  ht <- max(b$high[(n - 59):n]) - min(b$low[(n - 59):n])
  pm_truth(b, key, lines = ln, cancel = if (s > 0) max(b$high[(n - 59):n]) else min(b$low[(n - 59):n]), target = utils::tail(b$close, 1) - s * ht,
           note = "In the first half the highs rise and the lows fall (widening); in the second half the highs fall and the lows rise (narrowing); the extreme sits in the middle.") }
pm_ex$diamond_top <- function() pm_diamond("diamond_top", 1)
pm_ex$diamond_bottom <- function() pm_diamond("diamond_bottom", -1)
pm_broad <- function(key, s) {   # s = 1: broadening top after a rise
  ty <- if (s > 0) c("H", "L", "H", "L", "H") else c("L", "H", "L", "H", "L"); pr <- if (s > 0) c(3, 1.5, 3.8, 0.8, 4.6) else c(-3, -1.5, -3.8, -0.8, -4.6)
  lb <- if (s > 0) c("H1", "L1", "H2", "L2", "H3") else c("L1", "H1", "L2", "H2", "L3")
  b <- pm_build(c(pm_seq(pr, ty, lb), list(pm_A(if (s > 0) 0.0 else 0, if (s > 0) "L" else "H", 18, if (s > 0) "L3" else "H3"))), drift = s * 3)
  t0 <- pm_truth(b, key); P <- t0$points; H <- P[P$type == "H", ]; L <- P[P$type == "L", ]; n <- nrow(b)
  pm_truth(b, key, lines = rbind(pm_ln(c(H$i[1], H$price[1]), c(H$i[nrow(H)], H$price[nrow(H)]), col = "#7c3aed", name = "Rising highs"),
                                 pm_ln(c(L$i[1], L$price[1]), c(L$i[nrow(L)], L$price[nrow(L)]), col = "#7c3aed", name = "Falling lows")),
           cancel = if (s > 0) max(H$price) + 0.3 * utils::tail(pm_atr(b), 1) else min(L$price) - 0.3 * utils::tail(pm_atr(b), 1), target = if (s > 0) min(L$price) else max(H$price),
           note = "Each high above the last and each low below the last: a widening, unstable market after a long move.") }
pm_ex$broadening_top <- function() pm_broad("broadening_top", 1)
pm_ex$broadening_bottom <- function() pm_broad("broadening_bottom", -1)
pm_island <- function(key, s) {
  b <- pm_build(list(pm_A(-s * 3, if (s > 0) "L" else "H", NA, ""), pm_A(0, "", 12)), drift = -s)
  rows <- if (s > 0) pm_ohlc(pm_R(0.5, 0.8, 0.4, 0.7), pm_R(0.7, 0.9, 0.5, 0.6), pm_R(0.6, 0.75, 0.45, 0.5), pm_R(0.1, 0.3, -0.2, -0.1)) else pm_ohlc(pm_R(-0.5, -0.4, -0.8, -0.7), pm_R(-0.7, -0.5, -0.9, -0.6), pm_R(-0.6, -0.45, -0.75, -0.5), pm_R(-0.1, 0.2, -0.3, 0.1))
  b <- pm_append(b, rows); n <- nrow(b); idx <- (n - 3):n
  pts <- data.frame(i = c(n - 3, n), price = if (s > 0) c(b$low[n - 3], b$high[n]) else c(b$high[n - 3], b$low[n]), type = if (s > 0) c("L", "H") else c("H", "L"), lab = c("Gap 1", "Gap 2"), stringsAsFactors = FALSE)
  edge <- if (s > 0) min(b$low[(n - 3):(n - 1)]) else max(b$high[(n - 3):(n - 1)])
  pm_truth(b, key, points = pts, lines = pm_hl(n - 4, n, edge, "#0ea5e9", "dash", "Island edge"), span = c(n - 4, n), note = "A gap one way, three candles left alone above (below) both gaps, then a gap the other way.") }
pm_ex$island_top <- function() pm_island("island_top", 1)
pm_ex$island_bottom <- function() pm_island("island_bottom", -1)
pm_measured <- function(key, s) {
  b <- pm_build(c(pm_seq(s * c(0, 5, 2.5), if (s > 0) c("L", "H", "L") else c("H", "L", "H"), c("A", "B", "C")), list(pm_A(s * 4, "", 6))), drift = -s * 2)
  t0 <- pm_truth(b, key); A <- pm_pt(t0, "A"); B <- pm_pt(t0, "B"); C <- pm_pt(t0, "C"); n <- nrow(b); leg <- B[2] - A[2]
  pm_truth(b, key, lines = rbind(pm_ln(A, B, col = "#0f766e", name = "First leg"), pm_ln(C, c(C[1] + (B[1] - A[1]), C[2] + leg), col = "#0f766e", dash = "dash", name = "Second leg (projected)")),
           cancel = C[2] - s * 0.2 * utils::tail(pm_atr(b), 1), target = C[2] + leg, note = "A first leg, a 50% correction, and a second leg projected the same length from C.") }
pm_ex$measured_up <- function() pm_measured("measured_up", 1)
pm_ex$measured_down <- function() pm_measured("measured_down", -1)
pm_ex$round_number <- function() {   # three highs exactly at 100.40, then price just below it
  b <- pm_build(pm_seq(c(0, 2, 0.5, 2, 0.6, 2, 1.7), c("L", "H", "L", "H", "L", "H", ""), c("", "Touch 1", "", "Touch 2", "", "Touch 3", "")), drift = 1)
  t0 <- pm_truth(b, "round_number"); P <- t0$points; n <- nrow(b)
  pm_truth(b, "round_number", lines = pm_hl(P$i[1], n, 100.4, "#a16207", "dot", "Round number 100.40"), level = 100.4, note = "Three swing highs exactly at the round number 100.40; price is reacting just below it.") }
pm_ex$vol_squeeze <- function() {
  b <- pm_build(pm_seq(c(0, 3, 0.5, 2.5, 1, 1.5), c("L", "H", "L", "H", "L", ""), ""), drift = 0)
  rows <- do.call(rbind, lapply(1:24, function(k) data.frame(o = 0.01 * (-1)^k, h = 0.04, l = -0.04, c = -0.01 * (-1)^k)))
  b <- pm_append(b, rows); n <- nrow(b); rg <- b$high - b$low
  ctx <- cc_ctx(b, 15); at <- ctx$ind$atr; med <- zoo::rollapplyr(rg, 50, stats::median, fill = NA, partial = TRUE)   # the squeeze begins when ATR is at its 30-candle low with 5 small candles
  amin <- zoo::rollapplyr(at, 30, function(x) if (all(is.na(x))) NA else min(x, na.rm = TRUE), fill = NA, partial = TRUE); sm5 <- zoo::rollapplyr(rg < 0.7 * med, 5, all, fill = FALSE)
  on <- !is.na(at) & at <= amin + 1e-12 & sm5; st <- max(which(on & !c(FALSE, utils::head(on, -1))))
  pm_truth(b, "vol_squeeze", points = data.frame(i = c(n - 23, st), price = b$high[c(n - 23, st)], type = "H", lab = c("Coil starts", "Squeeze confirmed"), stringsAsFactors = FALSE)[2, ], span = c(n - 23, n),
           lines = rbind(pm_hl(n - 23, n, max(b$high[(n - 23):n]), "#64748b", "dot", "Coil high"), pm_hl(n - 23, n, min(b$low[(n - 23):n]), "#64748b", "dot", "Coil low")),
           note = "After normal swings, 24 candles with ranges a fraction of the usual: ATR at its 30-candle low.") }
pm_fail <- function(key, s) {   # s = -1: failed breakout above a double high
  if (s < 0) { pr <- c(1, 3, 1, 3.02, 1.8, 3.5); ty <- c("L", "H", "L", "H", "L", ""); lb <- c("", "Level 1", "", "Level 2", "", "") }
  else { pr <- c(-1, -3, -1, -3.02, -1.8, -3.5); ty <- c("H", "L", "H", "L", "H", ""); lb <- c("", "Level 1", "", "Level 2", "", "") }
  b <- pm_build(c(pm_seq(pr, ty, lb, c(NA, NA, NA, NA, NA, 7)), list(pm_A(if (s < 0) 2.5 else -2.5, "", 3))), drift = 0)
  t0 <- pm_truth(b, key); P <- t0$points; lv <- mean(P$price[1:2]); n <- nrow(b); a <- utils::tail(pm_atr(b), 1)
  ev <- pm_after(b, P$i[2] + 1, function(i) if (s < 0) b$close[i] > lv + 0.2 * a else b$close[i] < lv - 0.2 * a)
  pm_truth(b, key, lines = pm_hl(P$i[1], n, lv, if (s < 0) "#dc2626" else "#16a34a", "dash", "Level"), level = lv, event = ev,
           note = "A level touched twice is broken by a close beyond it (marked), and within three candles price closes back on the other side: a trap.") }
pm_ex$failed_breakout <- function() pm_fail("failed_breakout", -1)
pm_ex$failed_breakdown <- function() pm_fail("failed_breakdown", 1)
pm_retest <- function(key) {   # resistance broken upwards, price comes back to it from above
  b <- pm_build(pm_seq(c(1, 3, 1, 3, 2, 4.5, 3.02), c("L", "H", "L", "H", "L", "H", "L"), c("", "Level 1", "", "Level 2", "", "", "Back at the level")), drift = 0)
  t0 <- pm_truth(b, key); P <- t0$points; lv <- mean(P$price[1:2]); n <- nrow(b); a <- utils::tail(pm_atr(b), 1)
  ev <- pm_after(b, P$i[2] + 1, function(i) b$close[i] > lv + 0.3 * a)
  pm_truth(b, key, lines = pm_hl(P$i[1], n, lv, "#0ea5e9", "dash", "Broken level"), level = lv, event = n, cancel = lv - 0.5 * a, target = max(b$high[ev:n]),
           note = "A level touched twice, broken upwards (more than 1 ATR beyond), then revisited from above without a close back through it.") }
pm_ex$throwback <- function() pm_retest("throwback")
pm_ex$pullback_breakout <- function() pm_retest("pullback_breakout")
pm_gap <- function(key, s, kind) {
  if (kind == "breakaway") { b <- pm_build(list(pm_A(0, "", NA, ""), pm_A(0.05, "", 20)), drift = 0, noise = 0.02); rows <- if (s > 0) pm_ohlc(pm_R(0.5, 0.75, 0.45, 0.7), pm_R(0.7, 0.95, 0.65, 0.9), pm_R(0.9, 1.1, 0.8, 1.05), pm_R(1.05, 1.3, 1.0, 1.25)) else pm_ohlc(pm_R(-0.5, -0.45, -0.75, -0.7), pm_R(-0.7, -0.65, -0.95, -0.9), pm_R(-0.9, -0.8, -1.1, -1.05), pm_R(-1.05, -1.0, -1.3, -1.25)) }
  if (kind == "runaway") { b <- pm_build(list(pm_A(0, "", NA, ""), pm_A(s * 1.0, "", 20)), drift = -s * 0.5); rows <- if (s > 0) pm_ohlc(pm_R(0.3, 0.45, 0.25, 0.4), pm_R(0.4, 0.5, 0.35, 0.45), pm_R(0.45, 0.55, 0.4, 0.5), pm_R(0.5, 0.6, 0.45, 0.55)) else pm_ohlc(pm_R(-0.3, -0.25, -0.45, -0.4), pm_R(-0.4, -0.35, -0.5, -0.45), pm_R(-0.45, -0.4, -0.55, -0.5), pm_R(-0.5, -0.45, -0.6, -0.55)) }
  if (kind == "exhaustion") { b <- pm_build(list(pm_A(0, "", NA, ""), pm_A(s * 5, "", 20)), drift = 0); rows <- if (s > 0) pm_ohlc(pm_R(0.5, 0.8, 0.45, 0.6), pm_R(0.6, 0.65, -0.2, -0.15)) else pm_ohlc(pm_R(-0.5, -0.45, -0.8, -0.6), pm_R(-0.6, 0.2, -0.65, 0.15)) }
  e0 <- nrow(b); b <- pm_append(b, rows); n <- nrow(b); g <- e0 + 1
  edge <- if (s > 0) b$high[g - 1] else b$low[g - 1]
  pts <- data.frame(i = c(g - 1, g), price = if (s > 0) c(b$high[g - 1], b$low[g]) else c(b$low[g - 1], b$high[g]), type = if (s > 0) c("H", "L") else c("L", "H"), lab = c("Before", "Gap"), stringsAsFactors = FALSE)
  pm_truth(b, key, points = pts, lines = pm_hl(g - 1, n, edge, "#0ea5e9", "dash", "Gap edge"), span = c(g - 15, n), event = n,
           note = switch(kind, breakaway = "A gap out of a tight 15-candle base, not filled in the next 3 candles.", runaway = "A gap in the middle of a steady move (3-5 ATR in the 15 candles before), not filled.",
                         exhaustion = "A gap at the end of a long move (5+ ATR), filled within 3 candles: the move is exhausted.")) }
pm_ex$breakaway_gap_up <- function() pm_gap("breakaway_gap_up", 1, "breakaway")
pm_ex$breakaway_gap_down <- function() pm_gap("breakaway_gap_down", -1, "breakaway")
pm_ex$runaway_gap_up <- function() pm_gap("runaway_gap_up", 1, "runaway")
pm_ex$runaway_gap_down <- function() pm_gap("runaway_gap_down", -1, "runaway")
pm_ex$exhaustion_gap_up <- function() pm_gap("exhaustion_gap_up", 1, "exhaustion")
pm_ex$exhaustion_gap_down <- function() pm_gap("exhaustion_gap_down", -1, "exhaustion")
pm_spike <- function(key, s) {
  b <- pm_build(list(pm_A(-s * 2, "", NA, ""), pm_A(0, "", 20)), drift = 0)
  b <- pm_append(b, if (s > 0) pm_ohlc(pm_R(0, 1.3, -0.05, 0.3), pm_R(0.3, 0.35, -0.3, -0.25)) else pm_ohlc(pm_R(0, 0.05, -1.3, -0.3), pm_R(-0.3, 0.3, -0.35, 0.25))); n <- nrow(b)
  pts <- data.frame(i = n - 1, price = if (s > 0) b$high[n - 1] else b$low[n - 1], type = if (s > 0) "H" else "L", lab = "Spike", stringsAsFactors = FALSE)
  pm_truth(b, key, points = pts, lines = pm_hl(n - 1, n, pts$price, if (s > 0) "#ef4444" else "#16a34a", "dot", ""), span = c(n - 1, n), level = pts$price,
           note = "One candle spikes well beyond the last 20 candles (range 1.5+ ATR), the next closes back below its middle.") }
pm_ex$spike_top <- function() pm_spike("spike_top", 1)
pm_ex$spike_bottom <- function() pm_spike("spike_bottom", -1)

# ---- STEP 4: harmonic & Elliott ------------------------------------------------------------------------------------
pm_wave <- function(key, pr, ty, lb, tail_close = NA, last_len = NA, drift = 0, note = "", line_ix = NULL, s = 1) {
  an <- pm_seq(pr, ty, lb); if (is.finite(tail_close)) an <- c(an, list(pm_A(tail_close, "", last_len)))
  b <- pm_build(an, drift = drift); t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b)
  ln <- do.call(rbind, lapply(seq_len(nrow(P) - 1), function(k) pm_ln(c(P$i[k], P$price[k]), c(P$i[k + 1], P$price[k + 1]), col = "#0f766e")))
  list(b = b, P = P, n = n, ln = ln) }
pm_ex$abcd_bull <- function() { w <- pm_wave("abcd_bull", c(5, 2, 4, 1), c("H", "L", "H", "L"), c("A", "B", "C", "D"), drift = -1)
  P <- w$P; pm_truth(w$b, "abcd_bull", lines = w$ln, cancel = P$price[4] - 0.5 * utils::tail(pm_atr(w$b), 1), target = P$price[4] + 0.618 * (P$price[1] - P$price[4]), note = "AB = 3 u, BC retraces 67% of it, CD = AB: completes at D.") }
pm_ex$abcd_bear <- function() { w <- pm_wave("abcd_bear", c(-5, -2, -4, -1), c("L", "H", "L", "H"), c("A", "B", "C", "D"), drift = 1)
  P <- w$P; pm_truth(w$b, "abcd_bear", lines = w$ln, cancel = P$price[4] + 0.5 * utils::tail(pm_atr(w$b), 1), target = P$price[4] - 0.618 * (P$price[4] - P$price[1]), note = "Mirror: AB = 3 u, BC retraces 67%, CD = AB.") }
pm_ex$three_drives_up <- function() { w <- pm_wave("three_drives_up", c(0, 3, 1.2, 4.2, 2.4, 5.4), c("L", "H", "L", "H", "L", "H"), c("Start", "Drive 1", "", "Drive 2", "", "Drive 3"), drift = -1)
  P <- w$P; pm_truth(w$b, "three_drives_up", lines = w$ln, cancel = P$price[6] + 0.3 * utils::tail(pm_atr(w$b), 1), target = P$price[5], note = "Three rising drives of 3 u each, separated by 60% pullbacks: exhaustion.") }
pm_ex$three_drives_down <- function() { w <- pm_wave("three_drives_down", c(0, -3, -1.2, -4.2, -2.4, -5.4), c("H", "L", "H", "L", "H", "L"), c("Start", "Drive 1", "", "Drive 2", "", "Drive 3"), drift = 1)
  P <- w$P; pm_truth(w$b, "three_drives_down", lines = w$ln, cancel = P$price[6] - 0.3 * utils::tail(pm_atr(w$b), 1), target = P$price[5], note = "Three falling drives of 3 u each, separated by 60% pullbacks: exhaustion.") }
pm_wolfe <- function(key, s) {
  pr <- s * c(2, 6, 1, 4, -0.5); ty <- if (s > 0) c("L", "H", "L", "H", "L") else c("H", "L", "H", "L", "H")
  b <- pm_build(c(list(pm_A(s * 4, if (s > 0) "H" else "L", NA, "")), pm_seq(pr, ty, c("1", "2", "3", "4", "5"), c(10, 10, 10, 10, 10))), drift = 0)
  t0 <- pm_truth(b, key); P <- t0$points; n <- nrow(b); p <- function(k) c(P$i[k], P$price[k])
  l14 <- pm_lfun(p(1), p(4)); x5 <- P$i[5]; x4 <- P$i[4]
  pm_truth(b, key, lines = rbind(pm_ln(p(1), p(3), to = x5, col = cc_bias_col(if (s > 0) "bullish" else "bearish"), name = "1-3"), pm_ln(p(2), p(4), to = x5, col = cc_bias_col(if (s > 0) "bullish" else "bearish"), name = "2-4"),
                                 pm_ln(p(1), p(4), to = x5 + (x5 - x4), col = "#64748b", dash = "dash", name = "1-4 target line")),
           cancel = P$price[5] - s * 0.5 * utils::tail(pm_atr(b), 1), target = l14(x5 + (x5 - x4)), note = "Five swings in a converging wedge; point 5 overshoots the 1-3 line; the target is the 1-4 line.") }
pm_ex$wolfe_bull <- function() pm_wolfe("wolfe_bull", 1)
pm_ex$wolfe_bear <- function() pm_wolfe("wolfe_bear", -1)
pm_elliott <- function(key, s) {
  w <- pm_wave(key, s * c(0, 3, 1.5, 6, 4), if (s > 0) c("L", "H", "L", "H", "L") else c("H", "L", "H", "L", "H"), c("0", "1", "2", "3", "4"), tail_close = s * 5.5, last_len = 6, drift = -s)
  P <- w$P; pm_truth(w$b, key, lines = w$ln, cancel = P$price[5] - s * 0.2 * utils::tail(pm_atr(w$b), 1), target = P$price[5] + (P$price[2] - P$price[1]),
                     note = "Wave 1 = 3 u, wave 2 retraces half, wave 3 = 4.5 u (not the shortest), wave 4 stays above wave 1's top; price is in wave 5.") }
pm_ex$elliott_up <- function() pm_elliott("elliott_up", 1)
pm_ex$elliott_down <- function() pm_elliott("elliott_down", -1)
pm_ex$elliott_abc <- function() { w <- pm_wave("elliott_abc", c(0, 6, 4, 5, 3.5), c("L", "H", "L", "H", "L"), c("Start", "End of the move", "A", "B", "C"), drift = -1)
  P <- w$P; pm_truth(w$b, "elliott_abc", lines = w$ln, cancel = P$price[5] - 0.3 * utils::tail(pm_atr(w$b), 1), target = P$price[2], note = "After a 6 u move up, an A-B-C correction: B retraces half of A, C goes beyond A.") }

# ---- STEP 5: indicators ------------------------------------------------------------------------------------------
# building blocks appended to a series (u, relative to the last close)
pm_leg <- function(b, delta, len, wick = 0.08, jitter = 0.02, seed = 7) { set.seed(seed + len)
  st <- delta / len; x <- cumsum(rep(st, len) + c(stats::rnorm(len - 1, 0, jitter), 0)); x <- x - (x[len] - delta) * seq_len(len) / len
  o <- c(0, utils::head(x, -1)); w1 <- stats::runif(len, 0.4, 1) * wick; w2 <- stats::runif(len, 0.4, 1) * wick
  pm_append(b, data.frame(o = o, h = pmax(o, x) + w1, l = pmin(o, x) - w2, c = x)) }
pm_quiet <- function(b, k, amp = 0.03) pm_append(b, data.frame(o = amp * 0.3 * (-1)^(1:k), h = amp, l = -amp, c = -amp * 0.3 * (-1)^(1:k)))
pm_wild <- function(b, k, amp = 0.8) pm_append(b, data.frame(o = 0, h = amp * ifelse(1:k %% 2 == 1, 1, 0.1), l = -amp * ifelse(1:k %% 2 == 1, 0.1, 1), c = amp * 0.5 * (-1)^(1:k + 1) * 0) )
pm_chop <- function(b, k, amp = 0.5, seed = 1) { for (j in seq_len(k %/% 3)) b <- pm_leg(b, amp * (-1)^j * (1 + 0.2 * sin(j)), 3, seed = seed + j); b }   # a sideways market: 3-candle swings up and down
pm_xup <- function(x, y) !is.na(x) & !is.na(cc_lag(x)) & !is.na(y) & !is.na(cc_lag(y)) & cc_lag(x) <= cc_lag(y) & x > y
pm_flat <- function(len = 300, seed = 3, drift = 0) pm_build(list(pm_A(0, "", NA, ""), pm_A(drift * 0.02, "", 2)), lead = len, drift = drift, seed = seed)
# build variant v, find the first candle from `from` meeting the definition, end the example on it
pm_ind <- function(key, build, cond, panel = NA, overlay = NA, note = "", variants = 1:4, pts = NULL, cancel = NULL, target = NULL) {
  for (v in variants) { r <- build(v); b <- r$b; from <- r$from; ctx <- cc_ctx(b, 15); cnd <- cond(ctx, b); i <- which(cnd %in% TRUE & seq_along(cnd) >= from)
    if (!length(i)) next; i <- i[1]; b <- pm_cut(b, i); ctx <- cc_ctx(b, 15)
    P <- if (is.null(pts)) data.frame(i = i, price = b$close[i], type = "", lab = "Signal", stringsAsFactors = FALSE) else pts(ctx, b, i)
    t <- pm_truth(b, key, points = P, event = i, span = c(min(P$i, i - 5), i), note = note,
                  cancel = if (is.null(cancel)) NA else cancel(ctx, b, i), target = if (is.null(target)) NA else target(ctx, b, i))
    t$panel <- panel; t$overlay <- overlay; t$variant <- v; return(t) }
  t <- pm_truth(r$b, key, note = paste(note, "(NO EXAMPLE FOUND)")); t$panel <- panel; t$overlay <- overlay; t$failed <- TRUE; t }
pm_trend_then <- function(s1, s2, v, lead = 300, len2 = 60) {   # lead drifting s1 (u in total), then a leg of s2 u over len2 candles
  b <- pm_build(list(pm_A(0, "", NA, ""), pm_A(s2, "", len2 + 10 * (v - 1))), lead = lead, drift = s1, seed = v); list(b = b, from = lead) }
pm_I <- function(ctx) ctx$ind
pm_ex$golden_cross <- function() pm_ind("golden_cross", function(v) pm_trend_then(-8, 10, v, len2 = 80), function(ctx, b) pm_xup(pm_I(ctx)$ema50, pm_I(ctx)$ema200), overlay = "ema", note = "A long fall, then a rise: EMA50 crosses above EMA200 on the marked candle.")
pm_ex$death_cross <- function() pm_ind("death_cross", function(v) pm_trend_then(8, -10, v, len2 = 80), function(ctx, b) pm_xup(pm_I(ctx)$ema200, pm_I(ctx)$ema50), overlay = "ema", note = "A long rise, then a fall: EMA50 crosses below EMA200.")
pm_pull <- function(s, v) { b <- pm_build(list(pm_A(0, "", NA, ""), pm_A(s * 2.5, if (s > 0) "H" else "L", 10), pm_A(s * (2.5 - 0.9 - 0.15 * v), if (s > 0) "L" else "H", 5, "Pullback"), pm_A(s * 3.2, "", 8)), lead = 300, drift = s * 6, seed = v); list(b = b, from = 300 + 10) }
pm_ex$ma_pullback_up <- function() pm_ind("ma_pullback_up", function(v) pm_pull(1, v), function(ctx, b) { d <- pm_I(ctx); a <- ctx$a; x <- !is.na(d$ema50) & b$close > d$ema50 & d$ema50 > cc_lag(d$ema50, 10) & ((b$low <= d$ema20 + 0.2 * a & b$close > d$ema20) | (b$low <= d$ema50 + 0.2 * a & b$close > d$ema50)); x & !(cc_lag(x) %in% TRUE) }, overlay = "ema", note = "In an uptrend (price above a rising EMA50) a pullback touches EMA20 and the candle closes back above it.")
pm_ex$ma_pullback_down <- function() pm_ind("ma_pullback_down", function(v) pm_pull(-1, v), function(ctx, b) { d <- pm_I(ctx); a <- ctx$a; x <- !is.na(d$ema50) & b$close < d$ema50 & d$ema50 < cc_lag(d$ema50, 10) & ((b$high >= d$ema20 - 0.2 * a & b$close < d$ema20) | (b$high >= d$ema50 - 0.2 * a & b$close < d$ema50)); x & !(cc_lag(x) %in% TRUE) }, overlay = "ema", note = "In a downtrend a rally touches EMA20 and the candle closes back below it.")
pm_ex$ma_stack_bull <- function() pm_ind("ma_stack_bull", function(v) pm_trend_then(-2, 8, v, len2 = 90), function(ctx, b) { d <- pm_I(ctx); x <- !is.na(d$ema200) & d$ema20 > d$ema50 & d$ema50 > d$ema200 & d$ema20 > cc_lag(d$ema20, 5) & d$ema50 > cc_lag(d$ema50, 5) & d$ema200 > cc_lag(d$ema200, 5); x & !(cc_lag(x) %in% TRUE) }, overlay = "ema", note = "EMA20 above EMA50 above EMA200, all three rising: the averages are stacked for an uptrend.")
pm_ex$ma_stack_bear <- function() pm_ind("ma_stack_bear", function(v) pm_trend_then(2, -8, v, len2 = 90), function(ctx, b) { d <- pm_I(ctx); x <- !is.na(d$ema200) & d$ema20 < d$ema50 & d$ema50 < d$ema200 & d$ema20 < cc_lag(d$ema20, 5) & d$ema50 < cc_lag(d$ema50, 5) & d$ema200 < cc_lag(d$ema200, 5); x & !(cc_lag(x) %in% TRUE) }, overlay = "ema", note = "EMA20 below EMA50 below EMA200, all three falling.")
pm_ex$ma_ribbon_squeeze <- function() pm_ind("ma_ribbon_squeeze", function(v) { b <- pm_flat(260, v); b <- pm_leg(b, 2.5, 20, seed = v); b <- pm_chop(b, 360, 0.5, seed = v); list(b = b, from = 300) },
  function(ctx, b) { d <- pm_I(ctx); x <- !is.na(d$ema200) & (pmax(d$ema20, d$ema50, d$ema200) - pmin(d$ema20, d$ema50, d$ema200)) <= ctx$a & abs(d$ema50 - cc_lag(d$ema50, 10)) < 0.5 * ctx$a; x & !(cc_lag(x) %in% TRUE) }, overlay = "ema", note = "EMA20, EMA50 and EMA200 bunched within 1 ATR and flat: no trend, energy building.")
pm_ex$price_x_ma_up <- function() pm_ind("price_x_ma_up", function(v) pm_trend_then(-4, 3, v, len2 = 20), function(ctx, b) pm_xup(b$close, pm_I(ctx)$ema20) | pm_xup(b$close, pm_I(ctx)$ema50), overlay = "ema", note = "The close crosses above EMA20 (or EMA50).")
pm_ex$price_x_ma_down <- function() pm_ind("price_x_ma_down", function(v) pm_trend_then(4, -3, v, len2 = 20), function(ctx, b) pm_xup(pm_I(ctx)$ema20, b$close) | pm_xup(pm_I(ctx)$ema50, b$close), overlay = "ema", note = "The close crosses below EMA20 (or EMA50).")
pm_hg <- function(s, v) {   # a strong trend, a 2-candle dip: the first halfway to EMA20, the second touches it exactly (low 0.05 ATR through) and closes back on the trend side
  b <- pm_flat(260, v); b <- pm_leg(b, s * (2 + 0.35 * v), 8 + v, seed = v)
  ctx <- cc_ctx(b, 15); n <- nrow(b); half <- ((ctx$ind$ema20[n] - b$close[n]) / pm_u) / 2
  b <- pm_append(b, if (s > 0) data.frame(o = 0, h = 0.04, l = half - 0.04, c = half) else data.frame(o = 0, h = half + 0.04, l = -0.04, c = half))
  ctx <- cc_ctx(b, 15); n <- nrow(b); a <- ctx$a[n]; d_ <- (ctx$ind$ema20[n] - b$close[n]) / pm_u; ex <- s * 0.05 * a / pm_u
  b <- pm_append(b, if (s > 0) data.frame(o = 0, h = 0.06, l = d_ - ex, c = 0.03) else data.frame(o = 0, h = d_ - ex, l = -0.06, c = -0.03)); list(b = b, from = nrow(b)) }
pm_ex$holy_grail_long <- function() pm_ind("holy_grail_long", function(v) pm_hg(1, v), function(ctx, b) { d <- pm_I(ctx); a <- ctx$a; x <- !is.na(d$adx) & d$adx >= 30 & d$adx > cc_lag(d$adx, 3) & d$di_p > d$di_n & b$low <= d$ema20 + 0.1 * a & b$close > d$ema20; x & !(cc_lag(x) %in% TRUE) }, panel = "ADX", overlay = "ema", variants = 1:12,
  note = "ADX at or above 30 and rising with DI+ above DI-: a strong uptrend; price pulls back to EMA20 and closes above it. Entry above this candle's high.", cancel = function(ctx, b, i) b$low[i] - 0.2 * ctx$a[i])
pm_ex$holy_grail_short <- function() pm_ind("holy_grail_short", function(v) pm_hg(-1, v), function(ctx, b) { d <- pm_I(ctx); a <- ctx$a; x <- !is.na(d$adx) & d$adx >= 30 & d$adx > cc_lag(d$adx, 3) & d$di_n > d$di_p & b$high >= d$ema20 - 0.1 * a & b$close < d$ema20; x & !(cc_lag(x) %in% TRUE) }, panel = "ADX", overlay = "ema", variants = 1:12,
  note = "ADX at or above 30 and rising with DI- above DI+: a strong downtrend; price rallies to EMA20 and closes below it. Entry below this candle's low.", cancel = function(ctx, b, i) b$high[i] + 0.2 * ctx$a[i])
pm_ex$macd_x_signal_up <- function() pm_ind("macd_x_signal_up", function(v) pm_trend_then(-5, 2, v, len2 = 20), function(ctx, b) pm_xup(pm_I(ctx)$macd, pm_I(ctx)$macd_signal), panel = "MACD", note = "The MACD line crosses above its signal line.")
pm_ex$macd_x_signal_down <- function() pm_ind("macd_x_signal_down", function(v) pm_trend_then(5, -2, v, len2 = 20), function(ctx, b) pm_xup(pm_I(ctx)$macd_signal, pm_I(ctx)$macd), panel = "MACD", note = "The MACD line crosses below its signal line.")
pm_ex$macd_x_zero_up <- function() pm_ind("macd_x_zero_up", function(v) pm_trend_then(-5, 4, v, len2 = 30), function(ctx, b) pm_xup(pm_I(ctx)$macd, rep(0, ctx$n)), panel = "MACD", note = "The MACD line crosses above zero.")
pm_ex$macd_x_zero_down <- function() pm_ind("macd_x_zero_down", function(v) pm_trend_then(5, -4, v, len2 = 30), function(ctx, b) pm_xup(rep(0, ctx$n), pm_I(ctx)$macd), panel = "MACD", note = "The MACD line crosses below zero.")
# divergences: a fast fall to low 1, a bounce, a slow drift to a lower low 2 (momentum weaker), then the turn that confirms low 2
pm_divb <- function(s, v) { b <- pm_flat(260, v); b <- pm_leg(b, -s * 4, 10, seed = v); b <- pm_leg(b, s * 2, 8, seed = v); b <- pm_leg(b, -s * 2.4, 18 + 6 * v, seed = v); b <- pm_leg(b, s * 1.4, 8, seed = v); list(b = b, from = nrow(b) - 12) }
pm_div_cond <- function(nm, s) function(ctx, b) { zz <- ctx$zz1; tp <- if (s > 0) "L" else "H"; p <- zz[zz$type == tp, , drop = FALSE]; out <- rep(FALSE, ctx$n); if (nrow(p) < 2) return(out)
  v <- switch(nm, macd = pm_I(ctx)$macd, rsi = pm_I(ctx)$rsi, stoch = pm_I(ctx)$stoch_k)
  for (k in 2:nrow(p)) { p1 <- p[k - 1, ]; p2 <- p[k, ]; if (p2$idx - p1$idx > 40) next
    if (s > 0 && p2$price < p1$price && isTRUE(v[p2$idx] > v[p1$idx])) out[p2$conf] <- TRUE
    if (s < 0 && p2$price > p1$price && isTRUE(v[p2$idx] < v[p1$idx])) out[p2$conf] <- TRUE }; out }
pm_div_pts <- function(s) function(ctx, b, i) { zz <- ctx$zz1; p <- zz[zz$type == (if (s > 0) "L" else "H") & zz$conf <= i, , drop = FALSE]; p <- utils::tail(p, 2)
  data.frame(i = p$idx, price = p$price, type = p$type, lab = if (s > 0) c("Low 1", "Low 2 (lower)") else c("High 1", "High 2 (higher)"), stringsAsFactors = FALSE) }
for (nm in c("macd", "rsi", "stoch")) local({ nm <- nm
  pm_ex[[paste0(nm, "_div_bull")]] <<- function() pm_ind(paste0(nm, "_div_bull"), function(v) pm_divb(1, v), pm_div_cond(nm, 1), panel = c(macd = "MACD", rsi = "RSI", stoch = "Stochastic")[[nm]], pts = pm_div_pts(1), variants = 1:6,
                                                           note = sprintf("Price makes a lower low but %s makes a higher low: selling momentum is fading. Signal when the second low is confirmed.", toupper(nm)))
  pm_ex[[paste0(nm, "_div_bear")]] <<- function() pm_ind(paste0(nm, "_div_bear"), function(v) pm_divb(-1, v), pm_div_cond(nm, -1), panel = c(macd = "MACD", rsi = "RSI", stoch = "Stochastic")[[nm]], pts = pm_div_pts(-1), variants = 1:6,
                                                           note = sprintf("Price makes a higher high but %s makes a lower high: buying momentum is fading.", toupper(nm))) })
pm_ex$rsi_ob <- function() pm_ind("rsi_ob", function(v) pm_trend_then(0, 5, v, len2 = 14), function(ctx, b) { x <- pm_I(ctx)$rsi > 70; x & !(cc_lag(x) %in% TRUE) }, panel = "RSI", note = "RSI(14) rises above 70: overbought.")
pm_ex$rsi_os <- function() pm_ind("rsi_os", function(v) pm_trend_then(0, -5, v, len2 = 14), function(ctx, b) { x <- pm_I(ctx)$rsi < 30; x & !(cc_lag(x) %in% TRUE) }, panel = "RSI", note = "RSI(14) falls below 30: oversold.")
pm_fail_cond <- function(s) function(ctx, b) { r <- pm_I(ctx)$rsi; out <- rep(FALSE, ctx$n)
  for (i in 31:ctx$n) { if (!is.finite(r[i])) next; w <- max(1, i - 30):(i - 1); ex <- if (s > 0) which(r[w] < 30) else which(r[w] > 70); if (!length(ex)) next
    k <- w[max(ex)]; seg <- (k + 1):(i - 1); if (length(seg) < 2 || k + 1 > i - 1) next; pk <- if (s > 0) seg[which.max(r[seg])] else seg[which.min(r[seg])]; X <- r[pk]
    af <- if (pk < i - 1) (pk + 1):(i - 1) else integer(0); if (!length(af)) next
    if (s > 0 && X > 30 && all(r[af] > 30) && min(r[af]) < X && r[i - 1] <= X && r[i] > X) out[i] <- TRUE
    if (s < 0 && X < 70 && all(r[af] < 70) && max(r[af]) > X && r[i - 1] >= X && r[i] < X) out[i] <- TRUE }; out }
pm_fail_b <- function(s, v) { b <- pm_flat(260, v); b <- pm_leg(b, -s * 4, 10, seed = v); b <- pm_leg(b, s * 1.6, 5, seed = v); b <- pm_leg(b, -s * (0.5 + 0.1 * v), 3, seed = v); b <- pm_leg(b, s * 2, 6, seed = v); list(b = b, from = nrow(b) - 8) }
pm_ex$rsi_fail_bull <- function() pm_ind("rsi_fail_bull", function(v) pm_fail_b(1, v), pm_fail_cond(1), panel = "RSI", variants = 1:6, note = "RSI dips below 30, bounces, pulls back while staying above 30, then breaks above its bounce high (Wilder's failure swing).")
pm_ex$rsi_fail_bear <- function() pm_ind("rsi_fail_bear", function(v) pm_fail_b(-1, v), pm_fail_cond(-1), panel = "RSI", variants = 1:6, note = "RSI rises above 70, dips, rallies while staying below 70, then breaks below its dip low.")
pm_ex$rsi_x50_up <- function() pm_ind("rsi_x50_up", function(v) pm_trend_then(-3, 2, v, len2 = 15), function(ctx, b) pm_xup(pm_I(ctx)$rsi, rep(50, ctx$n)), panel = "RSI", note = "RSI(14) crosses above 50: momentum turns positive.")
pm_ex$rsi_x50_down <- function() pm_ind("rsi_x50_down", function(v) pm_trend_then(3, -2, v, len2 = 15), function(ctx, b) pm_xup(rep(50, ctx$n), pm_I(ctx)$rsi), panel = "RSI", note = "RSI(14) crosses below 50.")
pm_stx <- function(s, v) { b <- pm_flat(260, v); b <- pm_leg(b, -s * 3, 12, seed = v); b <- pm_leg(b, s * 1.5, 6, seed = v); list(b = b, from = nrow(b) - 8) }
pm_ex$stoch_x_up_os <- function() pm_ind("stoch_x_up_os", function(v) pm_stx(1, v), function(ctx, b) { d <- pm_I(ctx); pm_xup(d$stoch_k, d$stoch_d) & cc_lag(d$stoch_k) < 20 & cc_lag(d$stoch_d) < 20 }, panel = "Stochastic", note = "Slow %K crosses above %D while both are below 20 (oversold).")
pm_ex$stoch_x_down_ob <- function() pm_ind("stoch_x_down_ob", function(v) pm_stx(-1, v), function(ctx, b) { d <- pm_I(ctx); pm_xup(d$stoch_d, d$stoch_k) & cc_lag(d$stoch_k) > 80 & cc_lag(d$stoch_d) > 80 }, panel = "Stochastic", note = "Slow %K crosses below %D while both are above 80 (overbought).")
pm_ex$momentum_exhaustion <- function() pm_ind("momentum_exhaustion", function(v) { b <- pm_flat(260, v); b <- pm_leg(b, 4, 10, seed = v); b <- pm_leg(b, -1.6, 8, seed = v); b <- pm_leg(b, 2.0 + 0.1 * v, 20, seed = v); list(b = b, from = nrow(b) - 18) },
  function(ctx, b) { d <- pm_I(ctx); c <- b$close; hh <- zoo::rollapplyr(c, 20, max, fill = NA); out <- rep(FALSE, ctx$n)
    for (i in 60:ctx$n) { if (!is.finite(hh[i]) || c[i] < hh[i] - 1e-12) next; prev <- (i - 40):(i - 5); pi <- prev[which.max(c[prev])]; if (c[i] <= c[pi]) next
      if (sum(c(d$rsi[i] < d$rsi[pi], d$macd_hist[i] < d$macd_hist[pi], d$stoch_k[i] < d$stoch_k[pi]), na.rm = TRUE) >= 2) out[i] <- TRUE }; out }, panel = "RSI", variants = 1:6,
  pts = function(ctx, b, i) { prev <- (i - 40):(i - 5); pi <- prev[which.max(b$close[prev])]; data.frame(i = c(pi, i), price = b$close[c(pi, i)], type = "", lab = c("Earlier high", "New high, weaker momentum"), stringsAsFactors = FALSE) },
  note = "A new 20-candle closing high, but at least two of RSI, MACD histogram and Stochastic are weaker than at the previous high.")
pm_sq_b <- function(v, after = 0, s = 1) { b <- pm_flat(240, v); b <- pm_build(list(pm_A(0, "", NA, ""), pm_A(3, "H", 8), pm_A(0, "L", 8), pm_A(2.5, "H", 8), pm_A(0.5, "L", 8), pm_A(1.5, "", 6)), lead = 200, seed = v)
  b <- pm_quiet(b, 30 + 5 * v, 0.03); if (after) b <- pm_leg(b, s * after, 2, wick = 0.05, seed = v); list(b = b, from = nrow(b) - (if (after) 2 else 30 + 5 * v)) }
pm_ex$bb_squeeze <- function() pm_ind("bb_squeeze", function(v) pm_sq_b(v), function(ctx, b) { w <- pm_I(ctx)$bb_up - pm_I(ctx)$bb_dn; w <- w / pm_I(ctx)$bb_mid; mn <- zoo::rollapplyr(w, 100, function(x) if (all(is.na(x))) NA else min(x, na.rm = TRUE), fill = NA, partial = TRUE); x <- !is.na(w) & w <= 1.1 * mn; x & !(cc_lag(x) %in% TRUE) }, overlay = "bb", note = "The Bollinger band width falls to within 10% of its 100-candle low: a squeeze.")
pm_bbk <- function(s) function(ctx, b) { d <- pm_I(ctx); w <- (d$bb_up - d$bb_dn) / d$bb_mid; mn <- zoo::rollapplyr(w, 100, function(x) if (all(is.na(x))) NA else min(x, na.rm = TRUE), fill = NA, partial = TRUE)
  sq <- !is.na(w) & w <= 1.1 * mn; sq10 <- zoo::rollapplyr(sq, 11, function(x) any(utils::head(x, -1)), fill = FALSE, partial = TRUE); x <- (if (s > 0) b$close > d$bb_up else b$close < d$bb_dn) & sq10; x & !(cc_lag(x) %in% TRUE) }
pm_ex$bb_break_up <- function() pm_ind("bb_break_up", function(v) pm_sq_b(v, 0.6, 1), pm_bbk(1), overlay = "bb", note = "After a squeeze, a close above the upper Bollinger band.", cancel = function(ctx, b, i) pm_I(ctx)$bb_mid[i])
pm_ex$bb_break_down <- function() pm_ind("bb_break_down", function(v) pm_sq_b(v, 0.6, -1), pm_bbk(-1), overlay = "bb", note = "After a squeeze, a close below the lower Bollinger band.", cancel = function(ctx, b, i) pm_I(ctx)$bb_mid[i])
pm_walk <- function(s) function(ctx, b) { d <- pm_I(ctx); a <- ctx$a; nu <- if (s > 0) !is.na(d$bb_up) & b$close >= d$bb_up - 0.2 * a else !is.na(d$bb_dn) & b$close <= d$bb_dn + 0.2 * a; x <- nu & cc_lag(nu) & cc_lag(nu, 2); x & !(cc_lag(x) %in% TRUE) }
pm_ex$bb_walk_up <- function() pm_ind("bb_walk_up", function(v) { b <- pm_flat(260, v); b <- pm_leg(b, 4, 12, wick = 0.03, seed = v); list(b = b, from = 262) }, pm_walk(1), overlay = "bb", note = "Three closes in a row on (or within 0.2 ATR of) the upper band: a strong trend walking the band.")
pm_ex$bb_walk_down <- function() pm_ind("bb_walk_down", function(v) { b <- pm_flat(260, v); b <- pm_leg(b, -4, 12, wick = 0.03, seed = v); list(b = b, from = 262) }, pm_walk(-1), overlay = "bb", note = "Three closes in a row on the lower band.")
pm_snap <- function(s) function(ctx, b) { d <- pm_I(ctx); o <- b$open; c <- b$close
  if (s > 0) { t <- !is.na(d$bb_dn) & b$low <= d$bb_dn; t3 <- t | cc_lag(t) | cc_lag(t, 2); x <- t3 & c > o & c >= d$bb_dn + 0.5 * (d$bb_mid - d$bb_dn) } else { t <- !is.na(d$bb_up) & b$high >= d$bb_up; t3 <- t | cc_lag(t) | cc_lag(t, 2); x <- t3 & c < o & c <= d$bb_up - 0.5 * (d$bb_up - d$bb_mid) }
  x & !(cc_lag(x) %in% TRUE) }
pm_snap_b <- function(s, v) { b <- pm_flat(260, v); b <- pm_leg(b, -s * 2.2, 4, seed = v); b <- pm_leg(b, s * (1.0 + 0.2 * v), 2, seed = v); list(b = b, from = nrow(b) - 2) }
pm_ex$bb_snap_lower <- function() pm_ind("bb_snap_lower", function(v) pm_snap_b(1, v), pm_snap(1), overlay = "bb", note = "Price tags the lower band, then an up candle closes at least halfway back to the middle band.")
pm_ex$bb_snap_upper <- function() pm_ind("bb_snap_upper", function(v) pm_snap_b(-1, v), pm_snap(-1), overlay = "bb", note = "Price tags the upper band, then a down candle closes at least halfway back to the middle band.")
pm_ex$keltner_squeeze <- function() pm_ind("keltner_squeeze", function(v) pm_sq_b(v), function(ctx, b) { d <- pm_I(ctx); x <- !is.na(d$kc_up) & d$bb_up < d$kc_up & d$bb_dn > d$kc_dn; x & !(cc_lag(x) %in% TRUE) }, overlay = "kc", note = "The Bollinger bands move inside the Keltner channel (EMA20 +- 1.5 ATR).")
pm_ex$atr_rising <- function() pm_ind("atr_rising", function(v) { b <- pm_flat(280, v); b <- pm_quiet(b, 20, 0.04); for (k in 1:8) b <- pm_leg(b, 0.9 * (-1)^k, 2, wick = 0.15, seed = v + k); list(b = b, from = nrow(b) - 16) },
  function(ctx, b) { at <- pm_I(ctx)$atr; L <- cc_lag; x <- !is.na(at) & at >= 1.15 * L(at, 10) & at > L(at) & L(at) > L(at, 2) & L(at, 2) > L(at, 3); x & !(L(x) %in% TRUE) }, panel = "ATR", note = "ATR(14) up 15% or more in 10 candles and rising three candles in a row: volatility expanding.")
pm_ex$atr_falling <- function() pm_ind("atr_falling", function(v) { b <- pm_flat(260, v); for (k in 1:10) b <- pm_leg(b, 0.9 * (-1)^k, 2, wick = 0.15, seed = v + k); b <- pm_quiet(b, 30, 0.04); list(b = b, from = nrow(b) - 30) },
  function(ctx, b) { at <- pm_I(ctx)$atr; L <- cc_lag; x <- !is.na(at) & at <= 0.85 * L(at, 10) & at < L(at) & L(at) < L(at, 2) & L(at, 2) < L(at, 3); x & !(L(x) %in% TRUE) }, panel = "ATR", note = "ATR(14) down 15% or more in 10 candles and falling three candles in a row: volatility contracting.")
pm_ex$adx_strong <- function() pm_ind("adx_strong", function(v) { b <- pm_flat(280, v); b <- pm_leg(b, 6, 30, seed = v); list(b = b, from = 281) }, function(ctx, b) { x <- pm_I(ctx)$adx >= 25; x & !(cc_lag(x) %in% TRUE) }, panel = "ADX", note = "ADX(14) rises to 25 or more: a trend is in force.")
pm_ex$adx_weak <- function() pm_ind("adx_weak", function(v) { b <- pm_flat(240, v); b <- pm_leg(b, 6, 30, seed = v); b <- pm_chop(b, 90, 0.6, seed = v); list(b = b, from = 280) }, function(ctx, b) { x <- pm_I(ctx)$adx <= 20; x & !(cc_lag(x) %in% TRUE) }, panel = "ADX", note = "ADX(14) falls to 20 or less: no trend, range conditions.")
pm_ex$di_x_up <- function() pm_ind("di_x_up", function(v) pm_trend_then(-3, 3, v, len2 = 15), function(ctx, b) pm_xup(pm_I(ctx)$di_p, pm_I(ctx)$di_n), panel = "ADX", note = "DI+ crosses above DI-: directional movement turns up.")
pm_ex$di_x_down <- function() pm_ind("di_x_down", function(v) pm_trend_then(3, -3, v, len2 = 15), function(ctx, b) pm_xup(pm_I(ctx)$di_n, pm_I(ctx)$di_p), panel = "ADX", note = "DI- crosses above DI+: directional movement turns down.")

# ---- STEP 6: course strategies (UK clock; mid-October = BST, UTC+1) ---------------------------------------------------
pm_at <- function(anchors, last_uk, lead = 300, seed = 5, drift = 0) {   # build so that the last candle is at `last_uk` (UK time)
  b <- pm_build(anchors, lead = lead, seed = seed, drift = drift); end <- as.POSIXct(last_uk, tz = "Europe/London"); attr(end, "tzone") <- "UTC"
  b$time <- end - (rev(seq_len(nrow(b))) - 1) * 900; b }
pm_ukd <- function(b) as.Date(format(b$time, "%Y-%m-%d", tz = "Europe/London"))
pm_ukm <- function(b) { x <- as.POSIXlt(b$time, tz = "Europe/London"); x$hour * 60 + x$min }
pm_piv <- function(b, day) { ix <- which(pm_ukd(b) == day - 1); H <- max(b$high[ix]); L <- min(b$low[ix]); C <- b$close[max(ix)]; pp <- (H + L + C) / 3
  list(PP = pp, R1 = 2 * pp - L, S1 = 2 * pp - H, R2 = pp + (H - L), S2 = pp - (H - L), H = H, L = L, C = C) }
pm_pivot <- function(key, s) {
  # Tuesday 13 Oct: a clear day (up 4 u, back to 0.5 u, closes at 2 u); Wednesday: price walks to S1 (R1), touches it exactly, and turns
  b <- pm_at(list(pm_A(0, "", NA, ""), pm_A(s * 4, if (s > 0) "H" else "L", 30), pm_A(s * 0.5, if (s > 0) "L" else "H", 36), pm_A(s * 2, "", 30)), "2026-10-13 23:45", lead = 300)
  day <- as.Date("2026-10-14"); pv <- pm_piv(b, day); lv <- if (s > 0) pv$S1 else pv$R1
  d_ <- (lv - utils::tail(b$close, 1)) / pm_u; b <- pm_leg(b, d_ + s * 0.25, 16); a <- utils::tail(pm_atr(b), 1) / pm_u
  rel <- (lv / pm_u) - utils::tail(b$close, 1) / pm_u
  b <- pm_append(b, if (s > 0) data.frame(o = 0, h = 0.03, l = rel, c = rel + 0.1 * a) else data.frame(o = 0, h = rel, l = -0.03, c = rel - 0.1 * a))
  touch <- nrow(b); b <- pm_leg(b, s * 1.5 * a, 4); n0 <- nrow(b)
  ctx <- cc_ctx(b, 15); A <- ctx$a; cnd <- vapply(seq_len(n0), function(i) { if (i < touch) return(FALSE); w <- (i - 4):i
    if (s > 0) any(abs(b$low[w] - lv) <= 0.3 * A[i]) && min(b$low[w]) >= lv - 0.3 * A[i] && b$close[i] >= lv + 0.5 * A[i] && b$close[i - 1] < lv + 0.5 * A[i]
    else any(abs(b$high[w] - lv) <= 0.3 * A[i]) && max(b$high[w]) <= lv + 0.3 * A[i] && b$close[i] <= lv - 0.5 * A[i] && b$close[i - 1] > lv - 0.5 * A[i] }, TRUE)
  i <- which(cnd)[1]; b <- pm_cut(b, i); w0 <- min(which(pm_ukd(b) == day))
  lv_all <- unlist(pv[c("S2", "S1", "PP", "R1", "R2")]); tg <- if (s > 0) min(lv_all[lv_all > b$close[i] + 0.2 * A[i]]) else max(lv_all[lv_all < b$close[i] - 0.2 * A[i]])
  ln <- do.call(rbind, Map(function(v, nm) pm_hl(w0, i, v, if (nm == "PP") "#334155" else if (grepl("S", nm)) "#16a34a" else "#dc2626", "dot", nm), lv_all, names(lv_all)))
  t <- pm_truth(b, key, points = data.frame(i = touch, price = lv, type = if (s > 0) "L" else "H", lab = if (s > 0) "Touches S1" else "Touches R1", stringsAsFactors = FALSE), lines = ln, event = i,
           level = lv, span = c(w0, i), cancel = lv - s * 0.5 * A[i], target = tg,
           note = sprintf("Pivots from Tuesday's high %.3f, low %.3f, close %.3f. On Wednesday price touches %s exactly and closes 0.5 ATR back above (below) it.", pv$H, pv$L, pv$C, if (s > 0) "S1" else "R1"))
  td <- which(pm_ukd(b) == day - 1); t$view <- min(td)
  t$context <- data.frame(i = c(td[which.max(b$high[td])], td[which.min(b$low[td])], max(td)), price = c(pv$H, pv$L, pv$C), type = c("H", "L", ""), lab = c("Prev. day high", "Prev. day low", "Prev. day close"), stringsAsFactors = FALSE); t }
pm_ex$pivot_bounce_long <- function() pm_pivot("pivot_bounce_long", 1)
pm_ex$pivot_bounce_short <- function() pm_pivot("pivot_bounce_short", -1)
pm_straddle <- function(key, s) {   # overnight 22:00-06:00 UK: two highs and a low (two lows and a high); after 06:00 a close beyond the range
  b <- pm_at(list(pm_A(0.6, "", NA, ""), pm_A(1.5, "H", 8, "Overnight high"), pm_A(0, "L", 10, "Overnight low"), pm_A(1.4, "H", 8), pm_A(0.8, "", 6)), "2026-10-14 05:45", lead = 300)
  ukm <- pm_ukm(b); on <- which(pm_ukd(b) == as.Date("2026-10-13") & ukm >= 22 * 60 | pm_ukd(b) == as.Date("2026-10-14") & ukm < 6 * 60)
  onh <- max(b$high[on]); onl <- min(b$low[on]); b <- pm_leg(b, if (s > 0) 1.6 else -1.6, 8); ukm <- pm_ukm(b)
  i <- which(seq_len(nrow(b)) > max(on) & (if (s > 0) b$close > onh else b$close < onl))[1]; b <- pm_cut(b, i)
  pts <- data.frame(i = c(on[which.max(b$high[on])], on[which.min(b$low[on])]), price = c(onh, onl), type = c("H", "L"), lab = c("Overnight high", "Overnight low"), stringsAsFactors = FALSE)
  pm_truth(b, key, points = pts, lines = rbind(pm_hl(min(on), i, onh, "#0f766e", "dash", "Overnight high"), pm_hl(min(on), i, onl, "#0f766e", "dash", "Overnight low")), event = i,
           level = if (s > 0) onh else onl, span = c(min(on), i), cancel = if (s > 0) onl else onh, target = if (s > 0) onh + (onh - onl) else onl - (onh - onl),
           note = "The overnight range is 22:00 to 06:00 UK; the first close beyond it after 06:00 triggers the straddle side.") }
pm_ex$on_straddle_up <- function() pm_straddle("on_straddle_up", 1)
pm_ex$on_straddle_down <- function() pm_straddle("on_straddle_down", -1)
pm_orb <- function(key, s) {   # opening range 08:00-09:00 UK, then the first close beyond it
  b <- pm_at(list(pm_A(0, "", NA, ""), pm_A(0.3, "", 4)), "2026-10-14 07:45", lead = 300)
  b <- pm_append(b, pm_ohlc(pm_R(0, 0.5, -0.1, 0.4), pm_R(0.4, 0.6, 0.1, 0.2), pm_R(0.2, 0.3, -0.3, -0.2), pm_R(-0.2, 0.2, -0.35, 0.1)))
  ukm <- pm_ukm(b); or <- which(pm_ukd(b) == as.Date("2026-10-14") & ukm >= 480 & ukm < 540); orh <- max(b$high[or]); orl <- min(b$low[or])
  b <- pm_leg(b, if (s > 0) 1.2 else -1.2, 6); i <- which(seq_len(nrow(b)) > max(or) & (if (s > 0) b$close > orh else b$close < orl))[1]; b <- pm_cut(b, i)
  pts <- data.frame(i = c(or[which.max(b$high[or])], or[which.min(b$low[or])]), price = c(orh, orl), type = c("H", "L"), lab = c("Range high", "Range low"), stringsAsFactors = FALSE)
  pm_truth(b, key, points = pts, lines = rbind(pm_hl(min(or), i, orh, "#a16207", "dash", "Opening-range high"), pm_hl(min(or), i, orl, "#a16207", "dash", "Opening-range low")), event = i,
           level = if (s > 0) orh else orl, span = c(min(or), i), cancel = if (s > 0) orl else orh, target = if (s > 0) orh + (orh - orl) else orl - (orh - orl),
           note = "The opening range is the first hour from 08:00 UK; the first close beyond it after 09:00 is the breakout.") }
pm_ex$orb_up <- function() pm_orb("orb_up", 1)
pm_ex$orb_down <- function() pm_orb("orb_down", -1)


# ---- stored results: every example with its check, light enough to ship with the app ----------------------------------
pm_light <- function(r) { r$truth$b <- NULL; r$scan <- list(ctx = list(a = r$scan$ctx$a, ind = r$scan$ctx$ind), regime = r$scan$regime); r }
pm_run <- function(keys = cc_catalog$key, progress = NULL) {
  out <- list(); for (j in seq_along(keys)) { k <- keys[j]; if (!is.null(progress)) progress(j / length(keys), k)
    out[[k]] <- tryCatch(pm_light(pm_check(k)), error = function(e) list(key = k, ok = FALSE, found = FALSE, error = conditionMessage(e))) }
  attr(out, "at") <- Sys.time(); out }
pm_summary <- function(res, keys = names(res)) {
  do.call(rbind, lapply(keys, function(k) { r <- res[[k]]; cr <- cc_catalog[cc_catalog$key == k, ]
    data.frame(step = cr$step, key = k, Pattern = cr$label, Bias = cr$bias, Group = cr$group,
               `Found by the rules` = if (isTRUE(r$found)) "yes" else "NO",
               `Key candles` = if (is.null(r$points_ok) || is.na(r$points_ok)) "-" else if (isTRUE(r$points_ok)) sprintf("all matched (max %d off)", as.integer(r$points_off %||% 0)) else sprintf("NOT matched (%d off)", as.integer(r$points_off %||% 0)),
               Level = if (is.null(r$level_off_atr)) "-" else sprintf("%.2f ATR off", r$level_off_atr),
               `Signal candle` = if (is.null(r$event_ok)) "-" else if (isTRUE(r$event_ok)) "exact" else "NOT exact",
               Status = r$status %||% "-", Result = if (isTRUE(r$ok)) "PASS" else "FAIL", check.names = FALSE, stringsAsFactors = FALSE) })) }


# ---- the course's Step 1-6 tabs: their examples drawn precisely, and the 141 patterns split by course step ----------
# course step -> matrix patterns taught there (all 141 exactly once)
pm_course_keys <- function(step) { k <- cc_catalog$key; g <- cc_catalog$group; st <- cc_catalog$step
  s6 <- c(k[st == 6], "holy_grail_long", "holy_grail_short", "adx_strong", "adx_weak", "di_x_up", "di_x_down")
  s1 <- c(k[st == 1], "failed_breakout", "failed_breakdown", "throwback", "pullback_breakout", "round_number")
  s3 <- c(setdiff(k[st == 5], s6), "vol_squeeze")
  s2 <- setdiff(k, c(s1, s3, s6))
  switch(as.character(step), "1" = s1, "2" = s2, "3" = s3, "6" = s6, character(0)) }
# course example id -> the precise example (key, generator arguments, seed variant, what happens after the signal)
pm_course_map <- local({ m <- list(); A <- function(id, key, args = list(), seed = 0, outcome = NULL) m[[id]] <<- list(key = key, args = args, seed = seed, outcome = outcome)
  A("tl1", "uptrend_line"); A("tl2", "uptrend_line", seed = 3); A("tl3", "downtrend_line"); A("tl4", "downtrend_line", seed = 3)
  A("tl5", "broken_uptrend"); A("tl6", "broken_downtrend"); A("tl7", "ctr_break_up"); A("tl8", "ctr_break_down"); A("tl9", "bull_channel"); A("tl10", "bear_channel")
  for (cd in list(c("dark_cloud", "dark_cloud"), c("bearish_engulfing", "bear_engulfing"), c("piercing", "piercing"))) {
    A(paste0("cs_", cd[1], "_c"), cd[2], outcome = "hit"); A(paste0("cs_", cd[1], "_f"), cd[2], seed = 5, outcome = "miss") }
  A("fib1", "fib_retracement", list(s = -1, r = 0.5)); A("fib2", "fib_retracement", list(s = -1, r = 0.618)); A("fib3", "fib_retracement", list(s = 1, r = 0.5)); A("fib4", "fib_retracement", list(s = 1, r = 0.618))
  A("fib5", "fib_expansion", list(s = -1)); A("fib6", "fib_expansion", list(s = -1), seed = 3); A("fib7", "fib_expansion", list(s = 1)); A("fib8", "fib_expansion", list(s = 1), seed = 3)
  for (pd in list(list("pp_symdown", "sym_triangle", list(ctx = -1)), list("pp_symup", "sym_triangle", list(ctx = 1)), list("pp_asc", "asc_triangle", list()),
                  list("pp_ihs", "inv_head_shoulders", list()), list("pp_dtop", "double_top", list()), list("pp_bearflag", "bear_flag", list()), list("pp_bullflag", "bull_flag", list()),
                  list("pp_pennant", "pennant", list(s = -1)), list("pp_rwdown", "rising_wedge", list(ctx = -1)), list("pp_rwup", "rising_wedge", list(ctx = 1)),
                  list("pp_fwdown", "falling_wedge", list(ctx = -1)), list("pp_fwup", "falling_wedge", list(ctx = 1)), list("pp_hs", "head_shoulders", list()), list("pp_dbot", "double_bottom", list()))) {
    A(paste0(pd[[1]], "_hit"), pd[[2]], pd[[3]], outcome = "hit"); A(paste0(pd[[1]], "_miss"), pd[[2]], pd[[3]], seed = 5, outcome = "miss") }
  A("rsi1", "rsi_ob"); A("rsi2", "rsi_os"); A("rsi3", "rsi_div_bull"); A("rsi4", "rsi_div_bear"); A("st1", "stoch_div_bull"); A("st2", "stoch_div_bear")
  A("st3", "stoch_x_down_ob"); A("st4", "stoch_x_up_os"); A("ma1", "price_x_ma_down"); A("ma2", "price_x_ma_up"); A("ma3", "golden_cross"); A("ma4", "death_cross")
  A("macd1", "macd_x_signal_down"); A("macd2", "macd_x_signal_up"); A("bb1", "bb_snap_lower"); A("bb2", "bb_snap_upper")
  A("sd_morn_down", "on_straddle_down", outcome = "hit"); A("sd_morn_up", "on_straddle_up", outcome = "hit"); A("pp_long", "pivot_bounce_long", outcome = "hit"); A("pp_short", "pivot_bounce_short", outcome = "hit")
  A("hg_long", "holy_grail_long"); A("hg_short", "holy_grail_short"); A("dmi_buy", "di_x_up"); A("dmi_sell", "di_x_down")
  m })
# one example (a matrix pattern, or a course variant of it), checked; kept for the session
pm_mem <- new.env(parent = emptyenv())
pm_example_id <- function(key, args = list(), seed = 0, outcome = NULL) paste(key, paste(names(args), unlist(args), collapse = ","), seed, outcome %||% "", sep = "|")
# 1. this session's memory  2. BigQuery (pattern_examples, read a whole course step at once)  3. generate, then queue it for BigQuery
pm_get <- function(key, args = list(), seed = 0, outcome = NULL, course_id = NA_character_) {
  id <- pm_example_id(key, args, seed, outcome)
  if (!is.null(pm_mem[[id]])) return(pm_mem[[id]])
  r <- pm_store_fetch(id, key)
  if (is.null(r)) { r <- pm_generate(key, args, seed, outcome); attr(r, "source") <- "generated"
    pm_store_queue(id, key, args, seed, outcome, course_id, r) }
  pm_mem[[id]] <- r; r }
pm_generate <- function(key, args = list(), seed = 0, outcome = NULL) {
  old <- options(pm.seed = seed); on.exit(options(old))
  ex <- do.call(pm_ex[[key]], args); r <- pm_light(pm_check(key, ex))
  if (!is.null(outcome)) {   # what happens after the signal: to the target (hit) or back through the cancel level (miss / failed)
    o <- r$occ; tg <- if (is.finite(r$truth$target %||% NA)) r$truth$target else o$target; cn <- if (is.finite(r$truth$cancel %||% NA)) r$truth$cancel else o$invalid
    en <- utils::tail(r$bars$close, 1); dir <- sign(tg - en); if (!is.finite(dir) || dir == 0) dir <- sign(en - cn)
    b <- r$bars; e0 <- nrow(b)
    if (identical(outcome, "hit")) { b <- pm_leg(b, (tg - en) / pm_u * 1.08 + dir * 0.1, 12, seed = 9) ; lab <- "Target reached"; colr <- "#15803d" }
    else { half <- 0.4 * (tg - en) / pm_u; b <- pm_leg(b, half, 4, seed = 9); b <- pm_leg(b, (cn - utils::tail(b$close, 1)) / pm_u - dir * 0.5, 7, seed = 10); lab <- "Failed: back through the cancel level"; colr <- "#b91c1c" }
    r$bars <- b; r$outcome <- list(from = e0, label = lab, color = colr) }
  r }
pm_course_get <- function(id) { m <- pm_course_map[[id]]; if (is.null(m)) NULL else pm_get(m$key, m$args, m$seed, m$outcome, course_id = id) }
# the same example as a course chart spec (for the PDF export of the Step tabs)
pm_to_syn <- function(r, title) { b <- r$bars; tr <- r$truth; tm <- b$time
  df <- data.frame(Date = tm, Open = b$open, High = b$high, Low = b$low, Close = b$close)
  sh <- list(); if (!is.null(tr$lines) && nrow(tr$lines)) for (j in seq_len(nrow(tr$lines))) { z <- tr$lines[j, ]; sh[[length(sh) + 1]] <- syn_line(tm[z$x0], tm[min(nrow(b), round(z$x1))], z$y0, z$y1, z$color, z$dash) }
  for (lv in list(list(tr$target, "#15803d"), list(tr$cancel, "#b91c1c"))) if (is.finite(lv[[1]] %||% NA)) sh[[length(sh) + 1]] <- syn_hline(tm[tr$event], tm[nrow(b)], lv[[1]], lv[[2]], "dash")
  an <- if (!is.null(tr$points) && nrow(tr$points)) lapply(seq_len(nrow(tr$points)), function(k) syn_label(tm[tr$points$i[k]], tr$points$price[k], tr$points$lab[k])) else list()
  syn_chart(df, title, shapes = sh, annotations = an) }
pm_result_line <- function(r) { cr <- cc_catalog[cc_catalog$key == r$key, ]
  sprintf("%s %s by the app's improved rules%s%s.", if (isTRUE(r$ok)) "\u2713" else "\u2717", if (isTRUE(r$found)) "Found" else "NOT found",
          if (isTRUE(r$points_ok)) sprintf(", every turning point on its candle") else "", if (isTRUE(r$event_ok)) ", signal on the exact candle" else "") }


# ---- BigQuery store of the examples: table pattern_examples in the app's dataset -------------------------------------
# One row per example (each of the 141 matrix patterns, and each course variant: seed / arguments / hit-or-miss tail).
# Readable columns describe the chart and the pattern; payload_b64 is the exact checked example (R serialize, gzip, base64),
# so the chart drawn from BigQuery is identical to a freshly generated one. Rows are tied to gen_version (a fingerprint of
# the generator and the rules): when either changes, old rows are ignored and the examples are rebuilt and saved again.
pm_table <- "pattern_examples"
pm_cols <- c(row_id = "STRING", saved_at = "TIMESTAMP", gen_version = "STRING", example_id = "STRING", pattern_key = "STRING", pattern_label = "STRING",
             catalog_step = "INT64", course_step = "INT64", course_id = "STRING", bias = "STRING", pattern_group = "STRING", seed = "INT64", args_json = "STRING",
             outcome = "STRING", timeframe = "STRING", n_candles = "INT64", first_candle_utc = "TIMESTAMP", last_candle_utc = "TIMESTAMP", signal_candle = "INT64",
             signal_time_utc = "TIMESTAMP", entry = "FLOAT64", cancel_level = "FLOAT64", target = "FLOAT64", found = "BOOL", points_ok = "BOOL", points_off = "INT64",
             level_off_atr = "FLOAT64", event_ok = "BOOL", check_ok = "BOOL", status = "STRING", regime = "STRING",
             candles_json = "STRING", truth_json = "STRING", detection_json = "STRING", outcome_json = "STRING", payload_b64 = "STRING")
# FIXED version of the stored examples. Raise it by hand ONLY when the simulated examples or the rules' results change
# (tests/test_pm.R compares every example with tests/pm_reference.tsv and fails if they changed while this stayed the same).
# "v2-4373e267122a" is the tag of the 189 rows already saved in BigQuery on 4 Nov 2026: a new zip reuses them.
pm_gen_version <- "v2-4373e267122a"
pm_ddl <- function(project, dataset) sprintf("CREATE TABLE IF NOT EXISTS `%s.%s.%s` (\n%s\n)\nCLUSTER BY gen_version, course_step, example_id", project, dataset, pm_table,
                                             paste(sprintf("  %s %s", names(pm_cols), pm_cols), collapse = ",\n"))
pm_key_step <- function(key) { for (k in c(1, 2, 3, 6)) if (key %in% pm_course_keys(k)) return(as.integer(k)); NA_integer_ }
pm_pack <- function(r) { attr(r, "source") <- NULL; jsonlite::base64_enc(memCompress(serialize(r, NULL, xdr = TRUE), "gzip")) }
pm_unpack <- function(b64) unserialize(memDecompress(jsonlite::base64_dec(b64), "gzip"))
pm_ts <- function(x) { x <- as.POSIXct(x, tz = "UTC"); x }
# the row for one example
pm_row <- function(id, key, args, seed, outcome, course_id, r) {
  cr <- cc_catalog[cc_catalog$key == key, ][1, ]; b <- r$bars; tr <- r$truth; ev <- tr$event %||% NA_integer_; js <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA, force = TRUE))
  num <- function(x) { x <- suppressWarnings(as.numeric(x %||% NA)); if (length(x) && is.finite(x[1])) x[1] else NA_real_ }
  data.frame(row_id = paste(pm_gen_version, id, sep = "#"), gen_version = pm_gen_version, example_id = id, pattern_key = key, pattern_label = cr$label,
    catalog_step = as.integer(cr$step), course_step = pm_key_step(key), course_id = course_id %||% NA_character_, bias = cr$bias, pattern_group = cr$group,
    seed = as.integer(seed), args_json = js(args), outcome = outcome %||% NA_character_, timeframe = "15 min (simulated)", n_candles = nrow(b),
    first_candle_utc = pm_ts(b$time[1]), last_candle_utc = pm_ts(b$time[nrow(b)]), signal_candle = as.integer(ev),
    signal_time_utc = if (is.finite(ev) && ev <= nrow(b)) pm_ts(b$time[ev]) else pm_ts(NA), entry = num(tr$entry %||% r$occ$entry), cancel_level = num(tr$cancel %||% r$occ$invalid),
    target = num(tr$target %||% r$occ$target), found = isTRUE(r$found), points_ok = isTRUE(r$points_ok), points_off = as.integer(num(r$points_off)),
    level_off_atr = num(r$level_off_atr), event_ok = isTRUE(r$event_ok), check_ok = isTRUE(r$ok), status = as.character(r$status %||% NA), regime = as.character(r$scan$regime %||% NA),
    candles_json = js(list(time = format(b$time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), open = b$open, high = b$high, low = b$low, close = b$close)),
    truth_json = js(tr[intersect(names(tr), c("points", "lines", "levels", "event", "entry", "cancel", "target", "dir", "note", "panel", "context"))]),
    detection_json = js(list(status = r$status, occ = if (is.null(r$occ)) NULL else r$occ[intersect(names(r$occ), c("key", "label", "status", "dir", "entry", "invalid", "target", "marks", "lines", "levels", "sig"))])),
    outcome_json = js(r$outcome), payload_b64 = pm_pack(r), stringsAsFactors = FALSE)
}
# backends: BigQuery through the app's API manager, or an in-memory stand-in (tests, and "BigQuery not connected")
pm_bq_backend <- function(api) list(
  connected = function() isTRUE(api$bq_authenticated) && requireNamespace("bigrquery", quietly = TRUE),
  ensure = function() { bigrquery::bq_project_query(api$bq_project_id, pm_ddl(api$bq_project_id, api$bq_dataset_id)); invisible(TRUE) },
  read_ids = function(ids, ver) { inl <- paste(sprintf("'%s'", gsub("'", "", ids)), collapse = ", ")
    q <- sprintf(paste0("SELECT example_id, payload_b64 FROM `%s.%s.%s` WHERE gen_version = '%s' AND example_id IN (%s) ",
                        "QUALIFY ROW_NUMBER() OVER (PARTITION BY example_id ORDER BY saved_at DESC) = 1"), api$bq_project_id, api$bq_dataset_id, pm_table, ver, inl)
    as.data.frame(bigrquery::bq_table_download(bigrquery::bq_project_query(api$bq_project_id, q))) },
  write = function(df) { ref <- bigrquery::bq_table(api$bq_project_id, api$bq_dataset_id, pm_table)
    bigrquery::bq_table_upload(ref, df, create_disposition = "CREATE_NEVER", write_disposition = "WRITE_APPEND"); invisible(nrow(df)) },   # the table is made first by ensure()
  desc_ensure = function() { bigrquery::bq_project_query(api$bq_project_id, pm_desc_ddl(api$bq_project_id, api$bq_dataset_id)); invisible(TRUE) },
  desc_read = function(ver) { q <- sprintf(paste0("SELECT pattern_key, description FROM `%s.%s.%s` WHERE desc_version = '%s' ",
                                                  "QUALIFY ROW_NUMBER() OVER (PARTITION BY pattern_key ORDER BY saved_at DESC) = 1"), api$bq_project_id, api$bq_dataset_id, pm_desc_table, ver)
    as.data.frame(bigrquery::bq_table_download(bigrquery::bq_project_query(api$bq_project_id, q))) },
  desc_delete = function(keys, ver) { bigrquery::bq_project_query(api$bq_project_id, sprintf("DELETE FROM `%s.%s.%s` WHERE desc_version = '%s' AND pattern_key IN (%s)",
      api$bq_project_id, api$bq_dataset_id, pm_desc_table, ver, paste(sprintf("'%s'", gsub("'", "", keys)), collapse = ", "))); invisible(TRUE) },
  desc_write = function(df) { bigrquery::bq_table_upload(bigrquery::bq_table(api$bq_project_id, api$bq_dataset_id, pm_desc_table), df[, names(pm_desc_cols)],
                                                        create_disposition = "CREATE_NEVER", write_disposition = "WRITE_APPEND"); invisible(nrow(df)) })
pm_mem_backend <- function(up = TRUE) { db <- new.env(parent = emptyenv()); db$rows <- NULL; db$reads <- 0L; db$writes <- 0L; db$up <- up
  list(connected = function() isTRUE(db$up), ensure = function() invisible(TRUE), db = db,
       read_ids = function(ids, ver) { if (!isTRUE(db$up)) stop("not connected"); db$reads <- db$reads + 1L; db$last_ids <- ids; x <- db$rows
         if (is.null(x)) return(data.frame(example_id = character(0), payload_b64 = character(0))); x <- x[x$gen_version == ver & x$example_id %in% ids, , drop = FALSE]
         x <- x[order(x$saved_at, decreasing = TRUE), , drop = FALSE]; x[!duplicated(x$example_id), c("example_id", "payload_b64"), drop = FALSE] },
       write = function(df) { if (!isTRUE(db$up)) stop("not connected"); db$writes <- db$writes + 1L; db$rows <- rbind(db$rows, df); invisible(nrow(df)) },
       desc_ensure = function() invisible(TRUE),
       desc_read = function(ver) { if (!isTRUE(db$up)) stop("not connected"); db$desc_reads <- (db$desc_reads %||% 0L) + 1L; x <- db$desc
         if (is.null(x)) return(data.frame(pattern_key = character(0), description = character(0))); x <- x[x$desc_version == ver, , drop = FALSE]
         x <- x[order(x$saved_at, decreasing = TRUE), , drop = FALSE]; x[!duplicated(x$pattern_key), c("pattern_key", "description"), drop = FALSE] },
       desc_delete = function(keys, ver) { if (!isTRUE(db$up)) stop("not connected"); db$deletes <- (db$deletes %||% 0L) + 1L
         if (!is.null(db$desc)) db$desc <- db$desc[!(db$desc$desc_version == ver & db$desc$pattern_key %in% keys), , drop = FALSE]; invisible(TRUE) },
       desc_write = function(df) { if (!isTRUE(db$up)) stop("not connected"); db$desc <- rbind(db$desc, df); invisible(nrow(df)) }) }
# the store used by pm_get(): set once by the app (pm_store_use); with no backend everything is generated as before
pm_store <- new.env(parent = emptyenv()); pm_store$backend <- NULL; pm_store$rows <- new.env(parent = emptyenv()); pm_store$tried <- character(0)
pm_store$queue <- list(); pm_store$ensured <- FALSE; pm_store$stats <- c(bigquery = 0L, generated = 0L, saved = 0L, failed = 0L); pm_store$last_error <- NA_character_
pm_store_use <- function(backend) { if (exists("pm_desc")) { pm_desc$text <- list(); pm_desc$loaded <- FALSE; pm_desc$ensured <- FALSE }; pm_store$backend <- backend; pm_store$rows <- new.env(parent = emptyenv()); pm_store$tried <- character(0); pm_store$queue <- list()
  pm_store$ensured <- FALSE; pm_store$stats[] <- 0L; pm_store$last_error <- NA_character_; invisible(TRUE) }
pm_store_on <- function() { b <- pm_store$backend; !is.null(b) && isTRUE(tryCatch(b$connected(), error = function(e) FALSE)) }
pm_store_ensure <- function() { if (pm_store$ensured) return(TRUE)
  ok <- tryCatch({ pm_store$backend$ensure(); TRUE }, error = function(e) { pm_store$last_error <- conditionMessage(e); cat("[PM] table check failed:", conditionMessage(e), "\n"); FALSE })
  pm_store$ensured <- ok; ok }
# fetch the given examples in ONE query (only those not read or tried yet this session); used when charts come into view
pm_store_prefetch <- function(ids) { ids <- unique(ids[!is.na(ids)]); ids <- ids[!ids %in% pm_store$tried]
  if (!length(ids) || !pm_store_on() || !pm_store_ensure()) return(invisible(0L))
  t0 <- Sys.time(); x <- tryCatch(pm_store$backend$read_ids(ids, pm_gen_version), error = function(e) { pm_store$last_error <- conditionMessage(e); cat("[PM] BigQuery read failed:", conditionMessage(e), "\n"); NULL })
  if (is.null(x)) return(invisible(0L))   # not marked as tried: the next view tries again
  pm_store$tried <- c(pm_store$tried, ids); if (nrow(x)) for (j in seq_len(nrow(x))) assign(x$example_id[j], x$payload_b64[j], envir = pm_store$rows)
  cat(sprintf("[PM] %d of %d example(s) loaded from BigQuery in %.1f s (%s)\n", nrow(x), length(ids), as.numeric(difftime(Sys.time(), t0, units = "secs")), pm_gen_version)); invisible(nrow(x)) }
pm_store_has <- function(id) exists(id, envir = pm_store$rows, inherits = FALSE)
pm_store_fetch <- function(id, key) { if (!pm_store_on()) return(NULL)
  if (!pm_store_has(id)) pm_store_prefetch(id); b64 <- if (pm_store_has(id)) get(id, envir = pm_store$rows) else NULL
  if (is.null(b64)) return(NULL)
  r <- tryCatch(pm_unpack(b64), error = function(e) { cat("[PM] stored example unreadable, rebuilding:", id, "\n"); NULL }); if (is.null(r)) return(NULL)
  pm_store$stats["bigquery"] <- pm_store$stats["bigquery"] + 1L; attr(r, "source") <- "bigquery"; r }
# will this example come from memory / BigQuery (TRUE) or have to be built here (FALSE)? for the progress messages
pm_will_load <- function(id) !is.null(pm_mem[[id]]) || pm_store_on()
pm_course_example_id <- function(cid) { m <- pm_course_map[[cid]]; if (is.null(m)) NA_character_ else pm_example_id(m$key, m$args, m$seed, m$outcome) }
pm_store_queue <- function(id, key, args, seed, outcome, course_id, r) { pm_store$stats["generated"] <- pm_store$stats["generated"] + 1L
  if (is.null(pm_store$backend)) return(invisible(FALSE))
  pm_store$queue[[id]] <- tryCatch(pm_row(id, key, args, seed, outcome, course_id, r), error = function(e) { cat("[PM] row not built:", conditionMessage(e), "\n"); NULL }); invisible(TRUE) }
# send what was generated (one upload for many rows); kept for the next try when BigQuery cannot be reached
pm_store_flush <- function() { q <- Filter(Negate(is.null), pm_store$queue); if (!length(q) || !pm_store_on() || !pm_store_ensure()) return(invisible(0L))
  df <- do.call(rbind, q); df$saved_at <- pm_ts(Sys.time()); df <- df[, names(pm_cols)]
  ok <- tryCatch({ pm_store$backend$write(df); TRUE }, error = function(e) { pm_store$last_error <- conditionMessage(e); cat("[PM] BigQuery write failed (kept for the next try):", conditionMessage(e), "\n"); FALSE })
  if (ok) { pm_store$queue[names(q)] <- NULL; for (j in seq_len(nrow(df))) assign(df$example_id[j], df$payload_b64[j], envir = pm_store$rows)
    pm_store$stats["saved"] <- pm_store$stats["saved"] + nrow(df); cat(sprintf("[PM] %d example(s) saved to BigQuery %s\n", nrow(df), pm_table)) }
  else pm_store$stats["failed"] <- pm_store$stats["failed"] + 1L
  invisible(if (ok) nrow(df) else 0L) }
pm_store_status <- function() { st <- pm_store$stats; q <- length(Filter(Negate(is.null), pm_store$queue))
  if (is.null(pm_store$backend)) return("Examples are generated in the app (no BigQuery store set).")
  if (!pm_store_on()) return(sprintf("BigQuery is not connected: examples are generated in the app (%d this session).", st[["generated"]]))
  sprintf("Examples from BigQuery table %s (%s): %d read from BigQuery, %d generated%s, %d saved to BigQuery%s.", pm_table, pm_gen_version, st[["bigquery"]], st[["generated"]],
          if (q) sprintf(" (%d waiting to be saved)", q) else "", st[["saved"]], if (!is.na(pm_store$last_error) && st[["failed"]]) paste0("; last error: ", pm_store$last_error) else "") }
# every example the app shows (141 patterns + the course variants)
pm_all_examples <- function() { a <- lapply(cc_catalog$key, function(k) list(key = k, args = list(), seed = 0, outcome = NULL, course_id = NA_character_))
  b <- lapply(names(pm_course_map), function(id) { m <- pm_course_map[[id]]; list(key = m$key, args = m$args, seed = m$seed, outcome = m$outcome, course_id = id) }); c(a, b) }

# a fingerprint of what an example shows (candles, turning points, lines, signal, check), for the regression test
pm_fingerprint <- function(r) { rd <- function(x) formatC(round(as.numeric(x), 6), format = "f", digits = 6)
  tr <- r$truth; parts <- c(rd(unlist(r$bars[, c("open", "high", "low", "close")])), if (!is.null(tr$points) && nrow(tr$points)) c(tr$points$i, rd(tr$points$price), tr$points$lab),
    if (!is.null(tr$lines) && nrow(tr$lines)) rd(unlist(tr$lines[, c("x0", "x1", "y0", "y1")])), tr$event, rd(c(tr$entry %||% NA, tr$cancel %||% NA, tr$target %||% NA)),
    isTRUE(r$found), isTRUE(r$ok), r$status %||% "", if (!is.null(r$outcome)) c(r$outcome$from, r$outcome$label))
  tf <- tempfile(); on.exit(unlink(tf)); writeLines(paste(parts, collapse = "|"), tf); unname(tools::md5sum(tf)) }

# ---- descriptions, 4-8 lines, kept in BigQuery (table pattern_descriptions) ------------------------------------------
# ONE PER CHART: every course chart of Steps 1-6 has its own (key "chart:<id>", written from that chart's title, caption,
# pattern and outcome shown), and each of the 141 matrix patterns has one for the pattern section (key = pattern key).
# Written by Claude with "Fill missing descriptions" (code-protected): it re-reads BigQuery and asks only for the keys that
# have no description; existing rows are never touched. Read with one small query per session.
pm_desc_table <- "pattern_descriptions"
pm_desc_version <- "d1"
pm_desc_cols <- c(row_id = "STRING", saved_at = "TIMESTAMP", desc_version = "STRING", pattern_key = "STRING", pattern_label = "STRING", catalog_step = "INT64",
                  course_step = "INT64", description = "STRING", model = "STRING")
pm_desc_ddl <- function(project, dataset) sprintf("CREATE TABLE IF NOT EXISTS `%s.%s.%s` (\n%s\n)\nCLUSTER BY desc_version, pattern_key", project, dataset, pm_desc_table,
                                                  paste(sprintf("  %s %s", names(pm_desc_cols), pm_desc_cols), collapse = ",\n"))
pm_dash <- function(x) gsub("\xe2\x80\x94", "-", x, fixed = TRUE, useBytes = TRUE)   # em dash -> " - ", byte-safe in any locale
pm_charts <- new.env(parent = emptyenv())   # every course chart: key "chart:<id>" -> what it shows (registered by the step tabs)
pm_chart_add <- function(spec, week) { k <- paste0("chart:", spec$id)
  if (is.null(pm_charts[[k]])) { m <- if (exists("pm_course_map")) pm_course_map[[spec$id]] else NULL; cr <- if (is.null(m)) NULL else cc_catalog[cc_catalog$key == m$key, ][1, ]
    assign(k, list(title = pm_dash(spec$title), caption = spec$desc %||% "", week = suppressWarnings(as.integer(week)),
                   pattern = if (is.null(cr)) NA_character_ else cr$label, rule = if (is.null(cr)) NA_character_ else cr$rule, bias = if (is.null(cr)) NA_character_ else cr$bias,
                   outcome = if (is.null(m) || is.null(m$outcome)) NA_character_ else m$outcome), envir = pm_charts) }
  k }
pm_all_desc_keys <- function() c(sort(ls(pm_charts)), cc_catalog$key)
pm_desc_label <- function(k) if (startsWith(k, "chart:")) pm_charts[[k]]$title %||% k else cc_catalog$label[cc_catalog$key == k][1]
pm_desc <- new.env(parent = emptyenv()); pm_desc$text <- list(); pm_desc$loaded <- FALSE; pm_desc$ensured <- FALSE; pm_desc$error <- NA_character_
pm_desc_backend <- function() { b <- pm_store$backend; if (is.null(b) || is.null(b$desc_read)) NULL else b }
pm_desc_load <- function(force = FALSE) { if (pm_desc$loaded && !force) return(invisible(length(pm_desc$text)))
  b <- pm_desc_backend(); if (is.null(b) || !pm_store_on()) return(invisible(0L))
  if (!pm_desc$ensured) pm_desc$ensured <- isTRUE(tryCatch({ b$desc_ensure(); TRUE }, error = function(e) { pm_desc$error <- conditionMessage(e); FALSE }))
  t0 <- Sys.time(); x <- tryCatch(b$desc_read(pm_desc_version), error = function(e) { pm_desc$error <- conditionMessage(e); cat("[PM] descriptions read failed:", conditionMessage(e), "\n"); NULL })
  if (is.null(x)) return(invisible(0L)); pm_desc$loaded <- TRUE; pm_desc$text <- list()
  for (j in seq_len(nrow(x))) pm_desc$text[[x$pattern_key[j]]] <- x$description[j]
  cat(sprintf("[PM] %d description(s) read from BigQuery in %.1f s\n", nrow(x), as.numeric(difftime(Sys.time(), t0, units = "secs")))); invisible(nrow(x)) }
pm_desc_get <- function(key) { pm_desc_load(); pm_desc$text[[key]] }
pm_desc_missing <- function() { pm_desc_load(); setdiff(pm_all_desc_keys(), names(pm_desc$text)) }
# what Claude is asked: the facts of each chart, so each text is about THAT chart (its title, caption and outcome)
pm_desc_prompt <- function(keys) {
  items <- paste(vapply(keys, function(k) { if (startsWith(k, "chart:")) { t <- pm_charts[[k]]
      return(sprintf("- key: %s | chart title: %s | course step %s | course caption: %s%s%s", k, t$title, t$week, t$caption,
                     if (!is.na(t$pattern)) sprintf(" | pattern: %s (%s; app's rule: %s)", t$pattern, t$bias, t$rule) else "",
                     if (!is.na(t$outcome)) sprintf(" | outcome shown on this chart: %s", if (t$outcome == "hit") "the target was reached" else "it failed (the cancel level was hit before the target)") else "")) }
    cr <- cc_catalog[cc_catalog$key == k, ][1, ]; sprintf("- key: %s | pattern (general description) | name: %s | bias: %s | group: %s | works in: %s regime | app's rule: %s", k, cr$label, cr$bias, cr$group, cr$regime, cr$rule) }, ""), collapse = "\n")
  paste0("You write the teaching text shown under each chart in a trading course app (simulated 15-minute charts; CFDs such as Brent oil, gold, indices, FX). ",
         "For EACH key below write one description of 4 to 8 lines (70-130 words), plain English, no markdown, no bullet symbols, no headings. ",
         "For a 'chart:' key the text must be about THAT chart specifically, following its title and caption: what this chart shows and how the set-up forms on it, ",
         "what confirms it and what cancels it, where entry, stop and target go, and WHY the outcome shown happened (target reached, failed, confirmed, continuation, retrace...) and the lesson from it. ",
         "Two charts with similar titles (e.g. 'Hit Target' and 'Failed to Reach Target', or 'Ex. 1' and 'Ex. 2') must get clearly different texts that match their own outcome. ",
         "For a pattern key write the general description of the pattern (what it is, what it says about buyers and sellers, confirmation, entry / stop / target, one caution). ",
         "Be accurate; do not invent statistics or success rates.\n\nItems:\n", items,
         "\n\nReply with JSON only: {\"descriptions\":[{\"key\":\"<key>\",\"text\":\"<description>\"}, ...]} with every key above exactly once.")
}
pm_desc_parse <- function(txt, keys) { txt <- if (is.list(txt)) txt$text %||% "" else txt %||% ""
  j <- regmatches(txt, regexpr("\\{[\\s\\S]*\\}", txt, perl = TRUE)); if (!length(j)) return(NULL)
  x <- tryCatch(jsonlite::fromJSON(j)$descriptions, error = function(e) NULL); if (!is.data.frame(x) || !all(c("key", "text") %in% names(x))) return(NULL)
  x <- x[x$key %in% keys & nchar(trimws(x$text)) >= 200, , drop = FALSE]; x$text <- trimws(gsub("[*#`]", "", x$text)); x[!duplicated(x$key), c("key", "text")] }
# write descriptions in batches of 15. overwrite = TRUE rewrites ALL of them: each batch deletes its keys' old rows in
# BigQuery, then uploads the new rows (so the table holds one row per key). progress(i, n) is optional.
pm_desc_write <- function(claude_fn, keys = NULL, batch = 10, progress = function(i, n) NULL, model = "", overwrite = FALSE) {
  b <- pm_desc_backend(); if (is.null(b) || !pm_store_on()) stop("BigQuery is not connected: the descriptions can only be kept in BigQuery.")
  if (!pm_desc$ensured) { b$desc_ensure(); pm_desc$ensured <- TRUE }
  if (is.null(keys)) keys <- if (overwrite) pm_all_desc_keys() else pm_desc_missing()
  groups <- split(keys, ceiling(seq_along(keys) / batch)); done <- 0L; fails <- character(0)
  for (g in seq_along(groups)) { ks <- groups[[g]]; progress(g, length(groups))
    x <- tryCatch(pm_desc_parse(claude_fn(pm_desc_prompt(ks)), ks), error = function(e) { fails <<- c(fails, conditionMessage(e)); NULL })
    if (is.null(x) || !nrow(x)) { fails <- c(fails, sprintf("batch %d: no usable answer", g)); next }
    st <- vapply(x$key, function(k) if (startsWith(k, "chart:")) NA_integer_ else as.integer(cc_catalog$step[cc_catalog$key == k][1]), 1L)
    cs <- vapply(x$key, function(k) if (startsWith(k, "chart:")) pm_charts[[k]]$week %||% NA_integer_ else pm_key_step(k), 1L)
    df <- data.frame(row_id = paste(pm_desc_version, x$key, sep = "#"), saved_at = as.POSIXct(Sys.time(), tz = "UTC"), desc_version = pm_desc_version, pattern_key = x$key,
                     pattern_label = vapply(x$key, pm_desc_label, ""), catalog_step = st, course_step = cs, description = x$text, model = model, stringsAsFactors = FALSE)
    ok <- tryCatch({ if (overwrite && !is.null(b$desc_delete)) b$desc_delete(x$key, pm_desc_version); b$desc_write(df); TRUE }, error = function(e) { fails <<- c(fails, conditionMessage(e)); FALSE })
    if (ok) { for (i in seq_len(nrow(x))) pm_desc$text[[x$key[i]]] <- x$text[i]; done <- done + nrow(x) } }
  cat(sprintf("[PM] %d description(s) %s by Claude in BigQuery%s\n", done, if (overwrite) "overwritten" else "written", if (length(fails)) paste0("; problems: ", paste(unique(fails), collapse = " | ")) else ""))
  list(done = done, missing = length(setdiff(pm_all_desc_keys(), names(pm_desc$text))), problems = unique(fails)) }
pm_desc_status <- function() { if (!pm_store_on()) return("Descriptions: BigQuery is not connected (pattern charts show their rule).")
  all <- pm_all_desc_keys(); nc <- sum(startsWith(all, "chart:")); n <- length(intersect(names(pm_desc$text), all))
  sprintf("Descriptions in BigQuery: %d of %d (%d course charts, each its own, + %d patterns).", n, length(all), nc, nrow(cc_catalog)) }
pm_desc_code_ok <- function(code) identical(trimws(code %||% ""), "718")   # unlocks 'Fill missing descriptions'
# the box under a chart (key "chart:<id>") or in the pattern section (pattern key)
pm_desc_box <- function(key) { tags <- shiny::tags; tagList <- shiny::tagList; d <- pm_desc_get(key)
  tags$div(style = "font-size:12.5px; line-height:1.55; margin-top:6px; padding:8px 10px; background:#f8fafc; border-left:4px solid #6d28d9; border-radius:6px; color:#1e293b;",
           tags$b(pm_desc_label(key), ": "), if (!is.null(d) && nzchar(d)) d else if (startsWith(key, "chart:")) tags$i("This chart's own description is not in BigQuery yet ('Fill missing descriptions' at the top of this page).")
           else tagList(tags$i("Rule the app applies: "), cc_catalog$rule[cc_catalog$key == key][1])) }
