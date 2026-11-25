# Run: Rscript tests/test_ml.R
`%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_records.R", "R/utils_cc_markets.R", "R/utils_cc_advice.R", "R/utils_ml.R")) source(f)
pass <- 0; fail <- 0; ok <- function(c, m) { if (isTRUE(c)) { pass <<- pass + 1; cat("  ok  ", m, "\n") } else { fail <<- fail + 1; cat("  FAIL", m, "\n") } }
# labels by hand: ATR 1, stop 1.5, target 2.25
cl <- c(100, 100, 100, 100, 100); h <- c(100, 101, 102.3, 100, 100); l <- c(100, 99.9, 99.8, 98.4, 100)
lb <- ml_labels(h, l, cl, rep(1, 5), 1.5, 1.5, 3L); ok(lb$buy[1] == 1 && lb$sell[1] == 0, "labels: target 2.25 above is reached before the stop (BUY 1, SELL stopped 0)")
ok(is.na(lb$buy[4]) && lb$buy[2] == 1, "labels: an unfinished case at the end is left out")
lb2 <- ml_labels(c(100, 102.3), c(100, 98.4), c(100, 100), c(1, 1), 1.5, 1.5, 3L); ok(lb2$buy[1] == 0, "labels: stop and target in one candle count as the stop")
# boosting learns a planted rule and does not learn noise
set.seed(3); n <- 1500; X <- data.frame(a = rnorm(n), b = rnorm(n), c = rnorm(n)); y <- as.numeric(X$a > 0.3 & X$b < 0.5 | runif(n) < 0.1)
m <- ml_gbm_fit(X[1:1000, ], y[1:1000], ntree = 40); p <- ml_gbm_predict(m, X[1001:n, ]); ok(ml_auc(p, y[1001:n]) > 0.85 && names(m$importance)[1] %in% c("a", "b"), sprintf("boosted trees learn a planted rule out of sample (AUC %.2f)", ml_auc(p, y[1001:n])))
yn <- rbinom(n, 1, 0.4); mn <- ml_gbm_fit(X[1:1000, ], yn[1:1000], ntree = 40); an <- ml_auc(ml_gbm_predict(mn, X[1001:n, ]), yn[1001:n]); ok(abs(an - 0.5) < 0.08, sprintf("boosted trees find nothing in noise (AUC %.2f)", an))
ok(all(p >= 0 & p <= 100), "chances are between 0 and 100")
# hidden Markov model separates a calm and a wild regime, with forward-only probabilities
st <- rep(c(1, 2, 1, 2), each = 300); o <- cbind(rnorm(1200, 0, ifelse(st == 1, 0.5, 2)), ifelse(st == 1, -1, 1) + rnorm(1200, 0, 0.4), rnorm(1200))
hm <- ml_hmm_fit(o, k = 2); g <- ml_hmm_filter(hm, o); cls <- max.col(g); acc <- max(mean(cls == st), mean(cls != st)); ok(acc > 0.9 && all(abs(rowSums(g) - 1) < 1e-8), sprintf("the hidden Markov model recovers two regimes (%.0f%% of candles)", 100 * acc))
g2 <- ml_hmm_filter(hm, o[1:600, ]); ok(max(abs(g2 - g[1:600, ])) < 1e-10, "state probabilities at a candle do not use later candles")
# Kalman trend filter: finds a planted slope, is causal
set.seed(5); yk <- c(cumsum(rep(0.05, 400)), 20 - cumsum(rep(0.05, 400))) + rnorm(800, 0, 0.3); kf <- ml_kalman(yk, upto = 500)
ok(mean(kf$t[150:390] > 2) > 0.9 && mean(kf$t[550:790] < -2) > 0.9, "Kalman filter: a planted up-trend then down-trend is read as clear UP then clear DOWN")
kf2 <- ml_kalman(yk[1:500], par = kf$par); ok(max(abs(kf2$t - kf$t[1:500])) < 1e-9, "Kalman filter: the value at a candle does not use later candles")
bp <- ml_bin_pred(kf$t, as.numeric(c(0, diff(yk)) > 0), 100:500, 501:800); ok(length(bp) == 300 && all(bp >= 0 & bp <= 100), "trend strength is turned into a chance from the training candles only")
# GARCH: recovers persistence, forecasts more movement after a shock
set.seed(9); ng <- 4000; rg <- numeric(ng); s2 <- 1e-6; for (t in 2:ng) { s2 <- 1e-7 + 0.1 * rg[t - 1]^2 + 0.85 * s2; rg[t] <- rnorm(1, 0, sqrt(s2)) }
gf <- ml_garch_fit(rg); ok(abs(gf$persistence - 0.95) < 0.04 && gf$a > 0.04 && gf$a < 0.18, sprintf("GARCH: simulated persistence 0.95 recovered (%.3f, alpha %.2f)", gf$persistence, gf$a))
sdg <- ml_garch_sd(gf, rg, 20); big <- abs(rg) > quantile(abs(rg), 0.95); ok(mean(sdg[big]) > 1.2 * mean(sdg[!big]) && all(is.finite(sdg) & sdg > 0), "GARCH: a larger move is forecast after a shock")
# neural network: learns a planted rule, not noise
mnn <- ml_nn_fit(X[1:1000, ], y[1:1000]); pnn <- ml_nn_predict(mnn, X[1001:n, ]); ok(ml_auc(pnn, y[1001:n]) > 0.8 && all(pnn >= 0 & pnn <= 100), sprintf("neural network learns a planted rule out of sample (AUC %.2f)", ml_auc(pnn, y[1001:n])))
ann <- ml_auc(ml_nn_predict(ml_nn_fit(X[1:1000, ], yn[1:1000]), X[1001:n, ]), yn[1001:n]); ok(abs(ann - 0.5) < 0.08, sprintf("neural network finds nothing in noise (AUC %.2f)", ann))
# stacked ensemble: trusts the good forecaster, not the random one
PS <- list(good = 100 * plogis(3 * (y - 0.5) + rnorm(n)), bad = runif(n, 0, 100)); sm <- ml_stack_fit(PS, y, 1:1000, c("good", "bad")); sw <- ml_stack_weights(sm, PS, 1:1000, c("good", "bad"))
ok(sw[["good"]] > 5 * abs(sw[["bad"]]) && ml_auc(ml_stack_predict(sm, PS, 1001:n, c("good", "bad")), y[1001:n]) > 0.8 && is.null(ml_stack_fit(PS, y, 1:50, c("good", "bad"))), "stacked ensemble: weight goes to the forecaster that works; too few cases = no ensemble")
# structural breaks: a planted change of volatility is found near its place; none in a steady series
set.seed(11); rb <- c(rnorm(900, 0, 0.001), rnorm(700, 0, 0.003)); bk <- ml_breaks(rb); ok(length(bk) >= 1 && min(abs(bk - 900)) < 40, sprintf("structural breaks: a planted change at candle 900 is found (at %s)", paste(bk, collapse = ", ")))
ok(length(ml_breaks(rnorm(1600, 0, 0.001))) == 0, "structural breaks: none found in a steady series")
# the whole run on synthetic candles with two related markets
set.seed(7); N <- 1600; tm <- as.POSIXct("2026-09-01 00:00", tz = "UTC") + (1:N) * 900; r <- rnorm(N, 0, 0.1) + 0.03 * sin((1:N) / 40); c0 <- 90 + cumsum(r)
bars <- data.frame(time = tm, open = c(90, c0[-N]), close = c0); bars$high <- pmax(bars$open, bars$close) + abs(rnorm(N, 0, 0.05)); bars$low <- pmin(bars$open, bars$close) - abs(rnorm(N, 0, 0.05))
relb <- bars; relb$close <- 80 + cumsum(0.5 * r + rnorm(N, 0, 0.05))
x <- ml_features(bars, list(OIL_CRUDE = relb)); ok(all(c("rsi", "adx", "pv_pp", "rel_OILCRUDE_r4") %in% names(x)) && nrow(x) == N, "features: indicators, pivots of the day before and the related market")
b2 <- bars; b2[1201:N, c("open", "high", "low", "close")] <- b2[1201:N, c("open", "high", "low", "close")] + 5; x2 <- ml_features(b2, list(OIL_CRUDE = relb))
ok(isTRUE(all.equal(x[1:1200, ], x2[1:1200, ], check.attributes = FALSE)), "features at a candle do not change when later candles change (no look-ahead)")
msgs <- character(0); run <- ml_run(bars, list(OIL_CRUDE = relb), rrr = 1.5, horizon = 20L, folds = 3L, spread = 0.02, ntree = 15L, progress = function(v, m) msgs <<- c(msgs, m))
ok(nrow(run$metrics) == 12 && identical(unname(run$models[c("nn", "both", "stk")]), c("Neural network", "Average of the four", "Stacked ensemble")) && all(c("verdict", "auc", "picked_r") %in% names(run$metrics)) && run$tested > 500, sprintf("run: 4 forecasting models, their average and the stacked ensemble, BUY and SELL, %d candles tested out of sample", run$tested))
ok(all(is.na(run$pred$buy$both[1:700])) && all(unlist(run$now) >= 0 & unlist(run$now) <= 100, na.rm = TRUE), "run: no forecast inside the first training period; forecast now for both sides and models")
ok(nrow(run$strategies) == 4 && all(grepl("TRADE|HALF|LEAVE|NOT ENOUGH", run$strategies$advice)) && length(msgs) >= 6, "run: advice per course strategy, progress messages")
fa <- run$factor; ok(!is.null(fa) && fa$r2 > 20 && fa$loadings[["own"]] > 0 && abs(sum(fa$explained) - 100) < 1e-6, sprintf("latent factor model: the related market shares %.0f%% of the moves", fa$r2))
ok(is.null(ml_factor(bars, list())), "latent factor model: no related market = no factor")
ok(sum(is.finite(run$pred$buy$stk)) < sum(is.finite(run$pred$buy$both)) && all(is.na(run$pred$buy$stk[run$fold %in% 1])) && length(run$stack_weights$buy) == 4, "stacked ensemble is tested only on blocks after the first (it learns from earlier tested blocks)")
ok(!is.null(ml_roc(run$pred$buy$gbm, run$pred$buy$y)) && !is.null(run$breaks) && length(run$close) == N, "run: ROC points, breaks and prices for the charts")
gv <- run$garch; ok(!is.null(gv) && gv$move > 0 && gv$p_stop > gv$p_target && gv$p_target >= 0 && gv$p_stop <= 100 && is.finite(gv$cor_atr) && is.finite(run$trend$t) && length(run$now$buy) == 6 && all(is.finite(run$now$buy[c("gbm", "hmm", "kal", "nn", "both")])), "run: GARCH gives the likely move and the chance of reaching stop and target; Kalman gives the trend now; three forecasts per side")
ok(run$cost_r > 0 && all(run$metrics$verdict %in% c("EDGE", "WEAK EDGE (not proven)", "NO EDGE", "TOO FEW CASES")), "run: the spread is charged; every model has a verdict")
ok(inherits(tryCatch(ml_run(bars[1:300, ]), error = function(e) e), "error"), "run: too few candles is refused with a message")
tr <- data.frame(epic = "OIL_BRENT", status = "CLOSED", entry_ts = tm[c(1300, 100)], direction = c("BUY", "SELL"), entry_level = c(90, 90), exit_level = c(91, 90.5), stop_initial = c(89.5, 90.5), stringsAsFactors = FALSE)
tc <- ml_trades_check(tr, run, "OIL_BRENT"); ok(nrow(tc) == 2 && tc$result_r[1] == 2 && tc$result_r[2] == -1 && grepl("%", tc$models_chance[1]) && grepl("outside", tc$models_chance[2]), "your trades: the models' out-of-sample chance at entry against the result in R")
ok("ml_runs" %in% names(cc_tables) && grepl("cc_ml_runs", paste(cc_ddl("p", "d"), collapse = " ")), "the cc_ml_runs table is created with the others")
# ***************** triple barrier, independent cases, risk statistics, size, slippage
l3 <- ml_labels(c(100, 100.5, 100.6, 100.4), c(100, 99.9, 100.1, 100.2), c(100, 100.3, 100.5, 100.3), rep(1, 4), 1.5, 1.5, 3L)
ok(l3$buy_exit[1] == "time" && abs(l3$buy_r[1] - 0.2) < 1e-9 && l3$buy[1] == 0 && lb$buy_exit[1] == "target" && lb$buy_r[1] == 1.5 && lb$sell_r[1] == -1, "triple barrier: target +R:R, stop -1 R, time-out closed at the last close (+0.2 R)")
ok(identical(ml_thin(c(1, 5, 21, 22, 60), 20), c(1, 21, 60)) && length(ml_thin(integer(0), 5)) == 0, "independent cases: picked cases are kept one holding time apart")
rs <- ml_risk_stats(c(1.5, -1, -1, 1.5, 1.5, -1)); ok(rs$trades == 6 && abs(rs$total - 1.5) < 1e-9 && rs$max_dd == 2 && rs$dd_now == 1 && rs$worst_streak == 2 && abs(rs$profit_factor - 1.5) < 1e-9 && abs(rs$sortino - 0.25 / sqrt(0.5)) < 1e-9 && abs(rs$sharpe - 0.25 / sd(c(1.5, -1, -1, 1.5, 1.5, -1))) < 1e-9,
   "risk statistics by hand: total, maximum drawdown 2 R, drawdown now, losing streak, profit factor, Sharpe, Sortino")
mm <- ml_measure(c(rep(60, 100), rep(20, 100)), c(rep(c(1, 1, 0), length.out = 100), rep(0, 100)), rep(40, 200), 1.5, 0.05, r = c(rep(c(1.5, 1.5, -1), length.out = 100), rep(-1, 100)), horizon = 10L)
ok(mm$picked == 100 && mm$independent == 10 && mm$verdict == "TOO FEW CASES" && abs(mm$picked_r - (mean(rep(c(1.5, 1.5, -1), length.out = 100)) - 0.05)) < 0.006, "verdict: 100 overlapping picks count as 10 independent cases; R per trade uses the real exits minus the costs")
z1 <- ml_size(55, 1.5, "EDGE"); z2 <- ml_size(55, 1.5, "EDGE", vol_ratio = 2, dd_now = 4); z3 <- ml_size(55, 1.5, "NO EDGE"); z4 <- ml_size(38, 1.5, "EDGE"); z5 <- ml_size(42, 1.5, "EDGE")
ok(z1$risk == 2 && grepl("capped", z1$why) && abs(z2$risk - 25 * ((0.55 * 2.5 - 1) / 1.5) / 4) < 0.006 && grepl("halved", z2$why) && z3$risk == 0 && z4$risk == 0 && z5$risk < 1 && grepl("below your plan minimum", z5$why),
   "size: quarter Kelly, capped at the plan maximum, cut for volatility, halved in a drawdown, zero without a proven edge")
tt <- data.frame(trade_id = c("a", "b", "c"), status = c("CLOSED", "CLOSED", "OPEN"), direction = c("BUY", "SELL", "BUY"), epic = "OIL_BRENT", order_level = c(90, 91, 90), entry_level = c(90.02, 90.99, 90), stop_initial = c(89.52, 91.49, 89.5),
  target_level = c(90.77, 90.24, 91), exit_level = c(89.50, 90.24, NA), exit_code = c("SL", "T", NA), entry_ts = as.POSIXct("2026-11-10 10:00", tz = "UTC") + c(0, 86400, 172800), exit_ts = as.POSIXct("2026-11-10 12:00", tz = "UTC") + c(0, 86400, NA), stringsAsFactors = FALSE)
sl <- ml_own_slippage(tt); ow <- ml_own_r(tt); ok(abs(sl$points - (0.01 + 0.01)) < 1e-9 && sl$n == 5 && ml_own_slippage(NULL)$points == 0, "your slippage: average adverse points at entry plus at exit, from the Trade Log")
ok(nrow(ow) == 2 && abs(ow$r[1] + 1.04) < 1e-9 && abs(ow$r[2] - 1.5) < 1e-9 && abs(ow$planned_rr[1] - 1.5) < 1e-9 && grepl("^2026-W46", ow$week[1]), "your closed trades as R with the planned R:R and the week")
# tuning, Shapley values, meta-labelling in the run
r2 <- ml_run(bars, list(OIL_CRUDE = relb), rrr = 1.5, horizon = 20L, folds = 3L, spread = 0.02, slip = 0.03, tune = TRUE, ntree = 15L)
ok(abs(r2$cost_r - 2.5 * run$cost_r) < 1e-9 && r2$cost_slip_r > 0 && all(r2$metrics$independent <= r2$metrics$picked), "run: your slippage is charged on top of the spread; independent cases counted")
ok(!is.null(r2$tuned$buy) && sum(r2$tuned$buy$table$chosen) == 2 && nrow(r2$tuned$buy$table) == 7 && length(run$tuned) == 0, "tuning: one setting chosen for the boosted trees and one for the neural network, on the first training window only")
sh <- r2$shap$buy; ok(!is.null(sh) && length(sh$values) == length(r2$features) && abs(sum(sh$values) - (sh$pred - sh$base)) < 1e-6, sprintf("Shapley values add up exactly to the forecast minus the average (%.1f = %.1f - %.1f)", sum(sh$values), sh$pred, sh$base))
set.seed(2); Xs <- data.frame(a = rnorm(600), b = rnorm(600), c = rnorm(600)); ys <- as.numeric(Xs$a > 0); ms <- ml_gbm_fit(Xs, ys, ntree = 30); s1 <- ml_shap(ms, Xs, data.frame(a = 2, b = 0, c = 0))
ok(names(s1$values)[1] == "a" && s1$values[["a"]] > 20 && abs(s1$values[["c"]]) < 5, "Shapley values: the feature that drives the outcome gets the credit")
me <- r2$meta; ok(!is.null(me) && nrow(me$table) == 3 && me$table$signals[1] == me$table$signals[2] + me$table$signals[3] && me$verdict %in% c("THE FILTER HELPS", "NO HELP SHOWN", "TOO FEW SIGNALS"), sprintf("meta-labelling: %d tested signals split into take and skip, with a verdict (%s)", me$table$signals[1], me$verdict))
ok(nrow(r2$exits) == 2 && all(abs(r2$exits$target + r2$exits$stop + r2$exits$time - 100) < 0.2) && all(c("sharpe", "sortino", "max_dd") %in% names(r2$metrics)), "run: exits by target, stop and time; Sharpe, Sortino and drawdown per model")
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
