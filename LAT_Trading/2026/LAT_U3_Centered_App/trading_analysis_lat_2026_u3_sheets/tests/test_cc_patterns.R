# tests/test_cc_patterns.R - textbook shapes must be found by the T Records C.C pattern engine, and pure noise must
# not produce them at every candle. Run from the app folder:  Rscript tests/test_cc_patterns.R
suppressMessages({ library(TTR); library(zoo) })
`%||%` <- function(x, y) if (is.null(x)) y else x
source("R/utils_cc_catalog.R"); source("R/utils_cc_api.R"); source("R/utils_cc_patterns.R")
pass <- 0L; fail <- 0L
ok <- function(cond, what) { if (isTRUE(cond)) { pass <<- pass + 1L; cat("  ok  ", what, "\n") } else { fail <<- fail + 1L; cat("  FAIL", what, "\n") } }

t0 <- as.POSIXct("2026-10-01 00:00", tz = "UTC")
# candles from a path of closes: open = previous close, small wicks; deterministic noise
mk <- function(cl, wick = 0.04, start = t0, minutes = 15, seed = 7) { set.seed(seed); n <- length(cl)
  op <- c(cl[1], utils::head(cl, -1)); w1 <- wick * (0.6 + 0.8 * runif(n)); w2 <- wick * (0.6 + 0.8 * runif(n))
  data.frame(time = start + (0:(n - 1)) * minutes * 60, open = op, high = pmax(op, cl) + w1, low = pmin(op, cl) - w2, close = cl) }
path <- function(knots, lens, noise = 0.03, seed = 3) { set.seed(seed); out <- knots[1]
  for (k in seq_along(lens)) out <- c(out, seq(knots[k], knots[k + 1], length.out = lens[k] + 1)[-1])
  out + c(0, stats::filter(rnorm(length(out) - 1, 0, noise), 0.3, "recursive")) }
now_keys <- function(b, ...) { s <- cc_scan(b, 15, list(horizon = 30, ...), show_from = max(1, nrow(b) - 150), hist_step = 1); s$current_df$key }
ever_keys <- function(b, ...) { s <- cc_scan(b, 15, list(horizon = 30, ...), hist_step = 1); unique(s$hist$key) }
set_last <- function(b, rows) { for (k in seq_along(rows)) { r <- rows[[k]]; i <- nrow(b) - length(rows) + k
  b$open[i] <- r[1]; b$close[i] <- r[2]; b$high[i] <- max(r[1:2]) + (if (length(r) > 2) r[3] else 0.02); b$low[i] <- min(r[1:2]) - (if (length(r) > 3) r[4] else 0.02) }; b }

cat("Candles\n")
b <- mk(path(c(80, 74), 60, 0.02)); b <- rbind(b, b[rep(nrow(b), 2), ]); b$time <- t0 + (seq_len(nrow(b)) - 1) * 900
b <- set_last(b, list(c(74.10, 73.90), c(73.85, 74.30)))
ok("bull_engulfing" %in% now_keys(b), "bullish engulfing after a fall")
b2 <- mk(path(c(74, 80), 60, 0.02)); b2 <- rbind(b2, b2[rep(nrow(b2), 2), ]); b2$time <- t0 + (seq_len(nrow(b2)) - 1) * 900
b2 <- set_last(b2, list(c(79.90, 80.10), c(80.15, 79.70)))
ok("bear_engulfing" %in% now_keys(b2), "bearish engulfing after a rise")
ok(!("bull_engulfing" %in% now_keys(b2)), "no bullish engulfing at a top")
b3 <- mk(path(c(80, 74), 60, 0.02)); b3 <- rbind(b3, b3[rep(nrow(b3), 3), ]); b3$time <- t0 + (seq_len(nrow(b3)) - 1) * 900
b3 <- set_last(b3, list(c(74.40, 73.95), c(73.92, 73.90), c(73.95, 74.35)))
ok("morning_star" %in% now_keys(b3), "morning star")
b4 <- mk(rep(75, 60) + rnorm(60, 0, 0.02)); b4 <- rbind(b4, b4[rep(nrow(b4), 3), ]); b4$time <- t0 + (seq_len(nrow(b4)) - 1) * 900
b4 <- set_last(b4, list(c(75.00, 75.30), c(75.20, 75.50), c(75.40, 75.70)))
ok("three_white_soldiers" %in% now_keys(b4), "three white soldiers")
b5 <- mk(rep(75, 60) + rnorm(60, 0, 0.02)); b5 <- rbind(b5, b5[rep(nrow(b5), 2), ]); b5$time <- t0 + (seq_len(nrow(b5)) - 1) * 900
b5 <- set_last(b5, list(c(75.05, 74.80, 0.02, 0.02), c(75.10, 75.50, 0.02, 0.0)))
ok("bull_kicker" %in% now_keys(b5), "bullish kicker")

cat("Structures\n")
dt <- mk(path(c(70, 75, 72, 75.05, 73.6), c(40, 25, 25, 12), 0.03))
k <- now_keys(dt); ok("double_top" %in% k, "double top")
db <- mk(path(c(80, 75, 78, 74.95, 76.4), c(40, 25, 25, 12), 0.03))
ok("double_bottom" %in% now_keys(db), "double bottom")
hs <- mk(path(c(70, 74, 72, 76, 72.1, 74.1, 71.5), c(40, 15, 15, 15, 15, 8), 0.02))
ok("head_shoulders" %in% now_keys(hs), "head & shoulders")
at <- mk(path(c(70, 75, 72, 75, 73, 75, 74, 74.95), c(30, 12, 12, 10, 10, 8, 5), 0.02))
ok("asc_triangle" %in% now_keys(at), "ascending triangle")
fl <- mk(path(c(70, 70.2, 74, 73.4), c(60, 6, 9), 0.02))
ok(any(c("bull_flag", "pennant") %in% now_keys(fl)), "bullish flag after a pole")
cu <- mk(path(c(70, 75, 72, 71.6, 72, 75, 74.3, 74.6), c(40, 15, 10, 10, 15, 5, 4), 0.02))
ok("cup_handle" %in% ever_keys(cu), "cup and handle (found while forming)")
up <- mk(path(c(70, 73, 71.5, 74.5, 73, 76, 75.4), c(30, 15, 12, 15, 12, 4), 0.02))
ok("dow_up" %in% now_keys(up), "Dow uptrend (higher highs, higher lows)")
ab <- mk(path(c(70, 76, 73, 75.5, 72.3), c(40, 18, 10, 12), 0.02))
ok("abcd_bull" %in% ever_keys(ab), "bullish AB=CD")

cat("Gaps\n")
g <- mk(rep(75, 60) + rnorm(60, 0, 0.02)); g <- rbind(g, g[rep(nrow(g), 4), ]); g$time <- t0 + (seq_len(nrow(g)) - 1) * 900
n <- nrow(g); g[n - 3, c("open", "high", "low", "close")] <- c(76.0, 76.4, 75.9, 76.3)
g[n - 2, c("open", "high", "low", "close")] <- c(76.3, 76.6, 76.2, 76.5); g[n - 1, c("open", "high", "low", "close")] <- c(76.5, 76.8, 76.4, 76.7)
g[n, c("open", "high", "low", "close")] <- c(76.7, 77.0, 76.6, 76.9)
ok("breakaway_gap_up" %in% ever_keys(g), "breakaway gap up out of a base")
isl <- mk(rep(75, 60) + rnorm(60, 0, 0.02)); isl <- rbind(isl, isl[rep(nrow(isl), 4), ]); isl$time <- t0 + (seq_len(nrow(isl)) - 1) * 900
n <- nrow(isl); isl[n - 3, 2:5] <- c(75.6, 75.8, 75.5, 75.7); isl[n - 2, 2:5] <- c(75.7, 75.9, 75.55, 75.8); isl[n - 1, 2:5] <- c(75.8, 75.85, 75.5, 75.6); isl[n, 2:5] <- c(74.9, 75.0, 74.7, 74.8)
ok("island_top" %in% now_keys(isl), "island reversal top")

cat("Indicators\n")
gc <- mk(path(c(80, 70, 78), c(400, 300), 0.02))
ok("golden_cross" %in% ever_keys(gc), "golden cross after enough warm-up")
short <- mk(path(c(80, 70, 78), c(80, 60), 0.02))
ok(!("golden_cross" %in% ever_keys(short)), "no golden cross without 200 candles of warm-up")
os <- mk(path(c(80, 72), 60, 0.01))
ok("rsi_os" %in% now_keys(os), "RSI oversold in a steady fall")
s_os <- cc_scan(os, 15, list(horizon = 30), hist_step = 5); r <- s_os$current_df[s_os$current_df$key == "rsi_os", ]
ok(nrow(r) == 1 && !r$in_regime[1], "RSI oversold is out of regime in a strong trend (range row)")
ok(nrow(r) == 1 && isTRUE(r$atr_default[1]), "RSI oversold uses the labelled ATR stop/target template")
hg <- mk(path(c(70, 78, 77.4), c(60, 5), 0.01))
d <- cc_indicators(hg); ok(is.finite(d$adx[nrow(hg)]) && d$adx[nrow(hg)] > 30, "ADX above 30 in a strong rise (Holy Grail input)")
ok(isTRUE(d$di_p[nrow(hg)] > d$di_n[nrow(hg)]), "DI+ leads in a rise (Holy Grail needs direction from DI, not ADX)")

cat("Course strategies (UK clock)\n")
st <- as.POSIXct("2026-10-14 21:00", tz = "Europe/London"); attr(st, "tzone") <- "UTC"
cl <- c(rep(75, 36) + rnorm(36, 0, 0.03), rep(75.1, 4), seq(75.2, 75.9, length.out = 10))
orb <- mk(cl, 0.03, start = st)
k <- now_keys(orb); ok("orb_up" %in% k || "on_straddle_up" %in% k, "opening-range / overnight-range breakout up")

cat("Noise\n")
set.seed(11); rw <- 75 * exp(cumsum(rnorm(1200, 0, 0.0012)))
s_rw <- cc_scan(mk(rw, 0.03), 15, list(horizon = 30))
per <- table(s_rw$hist$key) / 1200
ok(all(per < 0.25), sprintf("no pattern fires on more than 1 candle in 4 of random noise (max %.2f)", max(per)))
cv <- cc_coverage(s_rw); ok(nrow(cv) == 141, "coverage table lists all 141 matrix rows")
ok(all(c("Win %", "Expectancy (R)", "Rule") %in% names(cv)), "coverage table shows the measured record and the rule")
o <- s_rw$hist[s_rw$hist$outcome %in% c("target", "stop"), ]
ok(all(o$dir * (o$target - o$entry) > 0 & o$dir * (o$entry - o$invalid) > 0), "every measured case has its stop and target on the correct sides")

cat("Drawn shapes\n")
set.seed(9); n <- 1200; pp <- 109 * exp(cumsum(rnorm(n, 0, 0.0015))); bb <- data.frame(time = t0 + (0:(n - 1)) * 900, open = c(109, head(pp, -1)), close = pp)
bb$high <- pmax(bb$open, bb$close) + 0.05; bb$low <- pmin(bb$open, bb$close) - 0.05
sb <- cc_scan(bb, 15, list(), hist_step = 3); ctx <- cc_ctx(bb, 15)
es <- seq(80, n, 25); sl <- numeric(0)
for (e in es) for (o in cc_det_pivot_at(ctx, e)) if (o$key %in% c("uptrend_line", "downtrend_line")) sl <- c(sl, (o$lines$y1[1] - o$lines$y0[1]) * (if (o$key == "uptrend_line") 1 else -1))
ok(length(sl) > 0 && all(sl > 0), sprintf("trend lines are drawn in their own direction (%d checked)", length(sl)))
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
