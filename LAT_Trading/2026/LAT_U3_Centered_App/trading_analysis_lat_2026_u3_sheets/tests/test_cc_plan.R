# tests/test_cc_plan.R - course study-plan improvements: trend, news window, plan check, backtest, blotter
suppressMessages({ library(shiny); source("global.R") })
pass <- 0L; fail <- 0L; ok <- function(c, m) { if (isTRUE(c)) { pass <<- pass + 1L; cat("  ok  ", m, "\n") } else { fail <<- fail + 1L; cat("  FAIL", m, "\n") } }
zig <- function(dir, n = 80) { i <- 1:n; p <- 100 + dir * i * 0.2 + 2 * sin(i / 3); data.frame(time = Sys.time() + i * 3600, open = p, high = p + 0.3, low = p - 0.3, close = p) }
cat("Higher time-frame trend (Dow: higher highs and higher lows)\n")
ok(cc_dow_trend(zig(1)) == "UP" && cc_dow_trend(zig(-1)) == "DOWN", "rising swings = UP, falling swings = DOWN")
ok(cc_dow_trend(zig(0)) %in% c("RANGE", "UP", "DOWN") && cc_dow_trend(zig(1, 8)) == "unknown", "too few candles = unknown")
ok(cc_trend_fit("BUY", "UP", "UP") == "with" && cc_trend_fit("BUY", "DOWN", "UP") == "against" && cc_trend_fit("SELL", "RANGE", "RANGE") == "neutral", "a buy against a daily down-trend is 'against'")
cat("Today's releases and the news window\n")
rel <- paste("13:30 | US | High | Non-Farm Payrolls | Actual - | Forecast 150K | Previous 120K", "15:30 | US | Medium | EIA Crude Oil Inventories | Actual - | Forecast -1.2M | Previous 2.1M",
             "07:00 | UK | High | GDP | Actual 0.1% | Forecast 0.2% | Previous 0.0%", sep = "\n")
now <- as.POSIXct("2026-11-06 10:00", tz = "Europe/London")
nw <- cc_news(rel, now, hold_h = 4, pad_min = 30)
ok(nrow(nw) == 3 && grepl("jobs", nw$meaning[nw$event == "Non-Farm Payrolls"]) && grepl("inventor", nw$meaning[grepl("EIA", nw$event)], ignore.case = TRUE), "each release gets its UK time and a short meaning")
ok(nw$in_window[nw$event == "Non-Farm Payrolls"] && !nw$in_window[grepl("EIA", nw$event)] && !nw$in_window[nw$event == "GDP"], "only a HIGH-impact release inside the holding time is flagged (NFP 13:30); medium and past ones are not")
ok(!any(cc_news(rel, now, hold_h = 2, pad_min = 30)$in_window), "a shorter holding time ends before NFP: nothing flagged")
cat("Plan check on the deal ticket\n")
base <- list(epic = "OIL_BRENT", markets = "OIL_BRENT, GOLD", from = "07:00", to = "20:00", now = now, max_day = 3, n_today = 1, max_loss_pct = 2, balance = 10000, pnl_today = -50,
             side = "BUY", d = "UP", h4 = "UP", fit = "with", min_rrr = 1.5, ctr_extra = 0.5, rrr = 1.6, size = 2, plan_size = 4, news = nw[0, ], rules = c("Trend first", "", "Stop beyond structure", "", ""), ticks = c(TRUE, FALSE, TRUE, FALSE, FALSE))
pc <- cc_plan_check(base); ok(all(pc$ok %in% c(TRUE, NA)) && sum(grepl("Plan point", pc$rule)) == 2, "all rules met; only the typed rules of five are checked")
x <- base; x$epic <- "US500"; ok(!cc_plan_check(x)$ok[1], "a market outside the plan fails")
x <- base; x$now <- as.POSIXct("2026-11-06 05:00", tz = "Europe/London"); ok(!cc_plan_check(x)$ok[2], "05:00 UK is outside the 07:00-20:00 session")
x <- base; x$n_today <- 3; ok(!cc_plan_check(x)$ok[3], "the 4th deal of the day fails a maximum of 3")
x <- base; x$pnl_today <- -250; ok(!cc_plan_check(x)$ok[4], "a 2.5% loss today fails a 2% daily limit")
x <- base; x$d <- "DOWN"; x$fit <- "against"; x$size <- 4; ok(!cc_plan_check(x)$ok[5], "against the daily trend with R:R 1.6 < 2.0 and full size fails")
x$rrr <- 2.1; ok(cc_plan_check(x)$ok[5], "... passes with R:R 2.1"); x$rrr <- 1.6; x$size <- 2; x$plan_size <- 4; ok(cc_plan_check(x)$ok[5], "... or with half the plan size")
x <- base; x$news <- nw; ok(!cc_plan_check(x)$ok[6] && grepl("Non-Farm", cc_plan_check(x)$detail[6]), "NFP inside the holding time fails and is named")
x <- base; x$ticks <- c(FALSE, FALSE, TRUE, FALSE, FALSE); p2 <- cc_plan_check(x); ok(!p2$ok[p2$rule == "Plan point 1: Trend first"], "an unticked rule of five fails")
x <- base; x$markets <- ""; x$from <- ""; x$max_day <- NA; x$max_loss_pct <- NA; x$news <- NULL; ok(sum(is.na(cc_plan_check(x)$ok)) >= 5 && !any(cc_plan_check(x)$ok %in% FALSE), "rules not set are shown as 'not set', not as failures")
cat("Backtest and blotter\n")
set.seed(4); tt <- seq(as.POSIXct("2026-10-01", tz = "UTC"), by = 900, length.out = 700); pp <- 100 + cumsum(rnorm(700, 0, 0.15))
b <- data.frame(time = tt, open = c(100, head(pp, -1)), close = pp); b$high <- pmax(b$open, b$close) + 0.06; b$low <- pmin(b$open, b$close) - 0.06
s <- cc_scan(b, 15); bt <- cc_backtest(s); al <- attr(bt, "all")
ok(!is.null(bt) && nrow(bt) > 3 && all(c("n", "win_pct", "exp_r", "max_dd_r", "verdict") %in% names(bt)), sprintf("backtest of %d patterns (%d past cases)", nrow(bt), al$n))
h <- s$hist[s$hist$outcome %in% c("target", "stop"), ]; r <- ifelse(h$outcome == "target", h$rr, -1)
ok(abs(al$exp_r - mean(r)) < 1e-9 && al$n == nrow(h), "expectancy = average of +R:R for targets and -1 for stops")
ok(all(bt$verdict[bt$n < 20] == "too few cases (under 20)"), "under 20 cases is never called tradeable")
tr <- cc_coerce("trades", data.frame(trade_id = c("A", "B", "C"), record_version = 1L, source = "APP", epic = "OIL_BRENT", market_name = "Brent", direction = c("BUY", "SELL", "BUY"), size = 2,
  status = c("CLOSED", "CLOSED", "ORDER_WORKING"), entry_level = c(100, 101, NA), stop_initial = c(99, 102, 98), target_level = c(102, 99, 103), exit_level = c(102, 102, NA),
  entry_ts = as.POSIXct(c("2026-11-03 08:00", "2026-11-04 08:00", NA), tz = "UTC"), placed_ts = as.POSIXct(c("2026-11-03 08:00", "2026-11-04 08:00", "2026-11-05 08:00"), tz = "UTC"),
  exit_ts = as.POSIXct(c("2026-11-03 12:00", "2026-11-04 10:00", NA), tz = "UTC"), risk_account = c(2, 2, 2), pnl_account_booked = c(4, -2, NA)))
bl <- cc_blotter(tr); sm <- cc_blotter_summary(bl)
ok(nrow(bl) == 3 && identical(bl$R[1:2], c(2, -1)) && identical(bl$`Cumulative P/L`[1:2], c(4, 2)), "blotter: R multiple and cumulative P/L per closed trade")
ok(sm$n == 2 && sm$wins == 1 && sm$net == 2 && sm$exp_r == 0.5 && sm$max_dd == 2, "summary: 2 closed, 1 win, net +2, expectancy +0.5R, drawdown 2")

# ---- round 2 (* and **) ----
set.seed(3); n <- 300; tm <- as.POSIXct("2026-11-02 00:00", tz="UTC") + 900*(0:(n-1)); cl <- 90 + cumsum(rnorm(n, 0, .1))
b <- data.frame(time=tm, open=cl, high=cl+.1, low=cl-.1, close=cl, volume=round(runif(n,10,100)))
ok(cc_dow_phase(b) %in% c("Accumulation","Public participation","Distribution","Markup","Markdown","Range","-") || is.character(cc_dow_phase(b)), "Dow phase is named")
pf <- cc_profile(b, "08:00", 60, max(tm)); ok(!is.null(pf) && is.finite(pf$poc) && pf$val <= pf$poc && pf$poc <= pf$vah, "profile: POC inside the value area")
sv <- cc_sar_trail(b, 1, min(cl) - 5, tail(cl,1)); ok(length(sv) == 1, "SAR trail returns one value")
ok(abs(cc_corr(b, b) - 1) < 1e-9, "a market correlates 1 with itself")
tr <- data.frame(status=c("CLOSED","CLOSED","CLOSED"), pnl_account_booked=c(-1,-2,3), pnl_account_est=NA, mood_entry=c("Calm","Anxious","Calm"), exit_ts=max(tm)-c(300,200,100), stringsAsFactors=FALSE)
ok(!is.null(cc_psych(tr)), "psychology tables from closed trades")
x <- base; x$setups <- "HOLY_GRAIL"; x$strategy <- "ORB"; x$strategy_label <- "Opening-range breakout"; x$setup_labels <- "Holy Grail"
ok(any(grepl("Set-up allowed", cc_plan_check(x)$rule) & cc_plan_check(x)$ok %in% FALSE), "a set-up not in the plan fails")
x <- base; x$max_loss_row <- 2; x$loss_row <- 3; ok(any(grepl("Losses in a row", cc_plan_check(x)$rule) & cc_plan_check(x)$ok %in% FALSE), "too many losses in a row blocks")
x <- base; x$corr_risk_pct <- 9; x$cap_pct <- 6; ok(any(grepl("Correlated", cc_plan_check(x)$rule) & cc_plan_check(x)$ok %in% FALSE), "correlated risk over the cap fails")

# ---- *** course checks for Claude ----
ok(nrow(cc_course_checks) == 15 && all(nzchar(cc_course_checks$week)) && all(nzchar(cc_course_checks$topic)), "15 course checks, each with a week and a topic")
h <- as.character(cc_course_check_ui("x")); ok(all(vapply(cc_course_checks$week, function(w) grepl(w, h, fixed = TRUE), TRUE)) && sum(gregexpr("type=\"checkbox\"", h)[[1]] > 0) == 15, "UI shows 15 checkboxes with their weeks")
pr <- cc_course_prompt(list(htf = "daily trend up", ind = "", news = "none")); ok(grepl("[htf]", pr, fixed = TRUE) && !grepl("[ind]", pr, fixed = TRUE) && grepl("\"course\"", pr), "prompt carries the ticked checks with values, skips empty ones")
cp <- cc_course_parse('{"checks":[],"additions":[],"course":[{"id":"htf","verdict":"supports","note":"with the trend"},{"id":"bogus","verdict":"x","note":"y"}]}')
ok(nrow(cp) == 1 && cp$verdict == "supports", "Claude's course verdicts read, unknown ids dropped")
ok(nrow(cc_course_parse("not json")) == 0, "bad reply gives no course rows")

# ---- **** full course coverage ----
ok(identical(cc_r5_frames("MINUTE_30")$major, "HOUR_4") && is.null(cc_r5_frames("WEEK")), "Rule of Five frames from the course table")
v <- cc_r5_verdict(c(minor = "UP", base = "UP", major = "UP"), -1); ok(v$agree && identical(v$ok, FALSE), "Rule of Five: a sell against three rising frames fails")
ok(isTRUE(cc_r5_verdict(c(minor = "DOWN", base = "RANGE", major = "UP"), 1)$ok), "Rule of Five: a buy with the major trend passes")
bd <- data.frame(time = as.POSIXct("2026-10-01", tz = "UTC") + 86400 * 0:29, open = 90:119, high = 91:120, low = 89:118, close = 90.5 + 0:29)
d <- cc_sr_levels(bd, 118.2); ok(!is.null(d) && any(d$level == "Pivot PP") && any(grepl("resistance", d$side)) && any(grepl("support", d$side)), "support, resistance and 7 pivots from daily candles")
ok(grepl("nearest resistance", cc_sr_near(d, 118.2)), "nearest levels named")
cx <- list(n = 60, h = c(seq(100, 110, length.out = 30), seq(110, 104, length.out = 30)) + 0.2, l = c(seq(100, 110, length.out = 30), seq(110, 104, length.out = 30)) - 0.2)
fb <- cc_fib_levels(cx, 60); ok(fb$swing == "up" && abs(fb$levels[["50%"]] - (fb$high + fb$low) / 2) < 1e-9, "Fibonacci 50% retracement of the last swing")
ok(grepl("Japanese candlesticks", cc_pattern_topics(data.frame(key = cc_catalog$key[cc_catalog$family == "candle_rev"][1], label = "x"))), "patterns grouped by course topic")
rk <- cc_risk_types(list(entry = 100, stop = 99, risk_amt = 10, spread = 0.5, atr = 1, hold_h = 30, balance = 1000, exposure = 8000, news_hits = "none", corr_note = "", now = as.POSIXct("2026-11-06 10:00", tz = "Europe/London")))
ok(nrow(rk) == 7 && rk$level[rk$risk == "Liquidity (spread) risk"] == "high" && rk$level[rk$risk == "Gap / weekend risk"] == "high" && rk$level[rk$risk == "Leverage (margin) risk"] == "high", "7 types of investment risk: spread, weekend gap and leverage flagged")
a <- data.frame(time = 1:50, close = 100 + sin(1:50)); b <- data.frame(time = 1:50, close = 50 + sin(1:50) / 2); b$close[50] <- 45
z <- cc_spread_z(a, b); ok(!is.null(z) && z$z > 2 && grepl("relative-value sell", z$text), "relative value: ratio z-score flags a rich market")
tb <- data.frame(status = "CLOSED", direction = "BUY", size = c(1, 3, 1), pnl_account_booked = c(5, -5, -5), pnl_account_est = NA, stop_initial = 99, stop_level = c(99, 98, 99),
  entry_ts = as.POSIXct("2026-11-03 09:00", tz = "UTC") + c(0, 3600, 7200 + 600), exit_ts = as.POSIXct("2026-11-03 09:30", tz = "UTC") + c(0, 3600 + 3 * 3600, 7200 + 3600 * 5), stringsAsFactors = FALSE)
bc <- cc_bias_checks(tb); ok(nrow(bc) == 4 && bc$flag[grepl("Disposition", bc$bias)] == "yes" && bc$flag[grepl("Overconfidence", bc$bias)] == "yes" && bc$flag[grepl("Loss aversion", bc$bias)] == "yes", "biases found in own trades")
sc <- cc_attitude_score(c(5, 5, 5, 5, 5, 5, 5, 5, 5, 1)); ok(sc$pct == 92 && sc$band == "disciplined" && grepl("higher time-frame", sc$weakest), "attitude survey score, band and weakest answer")
ok(nrow(cc_course_coverage) >= 30 && all(c("Week", "Topic", "Where in the app", "Status") %in% names(cc_course_coverage)) && any(grepl("Rule of Five", cc_course_coverage$Topic)), "course coverage map lists every topic")
x <- base; x$r5 <- list(ok = FALSE, text = "major up"); ok(any(grepl("Rule of Five time-frames", cc_plan_check(x)$rule) & cc_plan_check(x)$ok %in% FALSE), "plan check: against the major time-frame fails")

# ****** size and stop distance
rw <- function(pc, k) pc[grepl(k, pc$rule, fixed = TRUE), , drop = FALSE]
x <- base; x$max_size <- 1; x$size <- 104.3; ok(isFALSE(rw(cc_plan_check(x), "Size not above")$ok), "plan check: a size above the size you set fails (104.3 vs 1)")
x$size <- 0.5; ok(isTRUE(rw(cc_plan_check(x), "Size not above")$ok), "plan check: half your size passes")
x <- base; x$fit <- "against"; x$d <- "UP"; x$h4 <- "UP"; x$rrr <- 1.6; x$max_size <- 1; x$plan_size <- 208.7; x$size <- 104.3
ok(isFALSE(rw(cc_plan_check(x), "Higher time-frame")$ok), "counter-trend half size is half of YOUR size, not of the plan-risk size")
x$size <- 0.5; ok(isTRUE(rw(cc_plan_check(x), "Higher time-frame")$ok), "counter-trend: 0.5 of size 1 passes")
x <- base; x$stop_dist <- 0.17; x$atr <- 0.4; x$min_stop_atr <- 1; ok(isFALSE(rw(cc_plan_check(x), "Stop far enough")$ok), "plan check: stop 0.17 with ATR 0.4 fails (03/11 trade)")
x$stop_dist <- 0.7; ok(isTRUE(rw(cc_plan_check(x), "Stop far enough")$ok), "plan check: stop 0.7 with ATR 0.4 passes")
x$min_stop_atr <- 0; ok(is.na(rw(cc_plan_check(x), "Stop far enough")$ok), "plan check: minimum 0 = not set")
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
