# R/utils_cc_plan.R - course study-plan improvements (5 Nov 2026), used by the Trading Desk:
#  1. trading-plan rules checked on the deal ticket (plan template + the student's Rule of Five)
#  2. backtest of every pattern on the loaded chart, and an automatic trade blotter
#  3. higher time-frame trend (Dow structure on daily and 4-hour candles) on every scenario
#  4. today's releases (Morning Sheet) with a short meaning, and a news-window warning

# ---- 3. Dow trend: last two swing highs and lows (a swing = highest / lowest of k candles each side) ----------------
cc_dow_trend <- function(b, k = 3) {
  if (is.null(b) || nrow(b) < 2 * k + 6) return("unknown")
  h <- b$high; l <- b$low; n <- nrow(b); idx <- (k + 1):(n - k)
  sh <- idx[vapply(idx, function(i) h[i] == max(h[(i - k):(i + k)]), TRUE)]; sl <- idx[vapply(idx, function(i) l[i] == min(l[(i - k):(i + k)]), TRUE)]
  if (length(sh) < 2 || length(sl) < 2) return("unknown")
  hh <- h[utils::tail(sh, 2)]; ll <- l[utils::tail(sl, 2)]
  if (hh[2] > hh[1] && ll[2] > ll[1]) "UP" else if (hh[2] < hh[1] && ll[2] < ll[1]) "DOWN" else "RANGE"
}
# against = a higher time-frame trend points the other way
cc_trend_fit <- function(side, d, h4) { dir <- if (identical(side, "BUY")) "UP" else "DOWN"; opp <- if (dir == "UP") "DOWN" else "UP"
  if (d %in% opp || h4 %in% opp) "against" else if (d %in% dir || h4 %in% dir) "with" else "neutral" }

# ---- 4. releases: short meanings (general market knowledge, written by the app) and the news window --------------
cc_crib <- list(
  c("non.?farm|payroll|nfp", "US jobs report: strong jobs lift the dollar and yields; big surprises move everything."),
  c("\\bcpi\\b|consumer price", "Inflation: higher than forecast = rate-hike fears, stronger dollar, weaker stocks and gold."),
  c("\\bppi\\b|producer price", "Factory-gate inflation: an early hint for CPI."),
  c("pce", "The Fed's preferred inflation gauge."),
  c("fomc|fed.*(rate|decision)|interest rate decision|bank rate|boe|ecb", "Central-bank decision: the biggest volatility of the day; statement and press conference can reverse the first move."),
  c("retail sales", "Consumer spending: strong = growth and dollar up."),
  c("gdp", "Economic growth: big misses move indices and the currency."),
  c("ism|pmi", "Business surveys: above 50 = expansion; services PMI matters most for the US."),
  c("jobless|unemployment claims", "Weekly claims: rising claims = a weakening labour market."),
  c("jolts|job openings", "Job openings: labour-market tightness."),
  c("adp", "Private payrolls: a preview of the jobs report (often a poor one)."),
  c("michigan|consumer confidence|sentiment", "Consumer mood and inflation expectations."),
  c("crude|eia|api.*(stock|inventor)|inventor", "Oil inventories: a bigger draw than expected supports oil prices, a build weighs on them."),
  c("opec", "OPEC: production decisions move oil directly."))
cc_crib_meaning <- function(event) { for (x in cc_crib) if (grepl(x[1], event, ignore.case = TRUE)) return(x[2]); "" }
cc_is_high <- function(imp) grepl("high|3|★★★|\\*\\*\\*", imp %||% "", ignore.case = TRUE)
# today's releases (Morning Sheet 'todays_releases' lines) with UK time, meaning and whether they fall in the window
cc_news <- function(rel_text, now, hold_h = 10, pad_min = 30, day = as.Date(format(now, "%Y-%m-%d", tz = "Europe/London"))) {
  d <- tryCatch(tr_calendar_parse_text(rel_text), error = function(e) NULL)
  if (is.null(d) || !nrow(d)) return(data.frame(time = character(0), country = character(0), importance = character(0), event = character(0), meaning = character(0), at = as.POSIXct(character(0)), in_window = logical(0)))
  hm <- regmatches(d$time, regexpr("[0-9]{1,2}:[0-9]{2}", d$time)); at <- rep(as.POSIXct(NA), nrow(d))
  ok <- grepl("[0-9]{1,2}:[0-9]{2}", d$time); at[ok] <- as.POSIXct(paste(format(day), hm), tz = "Europe/London")
  d$meaning <- vapply(d$event, cc_crib_meaning, ""); d$at <- at
  d$in_window <- !is.na(at) & cc_is_high(d$importance) & at >= now - pad_min * 60 & at <= now + hold_h * 3600 + pad_min * 60
  d[order(d$at), c("time", "country", "importance", "event", "meaning", "at", "in_window")]
}

# ---- 1. plan check on the deal ticket: one row per rule (ok TRUE / FALSE / NA = not set) ---------------------------
cc_hm <- function(x) { x <- if (length(x)) as.character(x[1]) else ""; m <- regmatches(x, regexpr("^[0-9]{1,2}:[0-9]{2}$", trimws(x %||% ""))); if (length(m)) as.numeric(sub(":.*", "", m)) * 60 + as.numeric(sub(".*:", "", m)) else NA }
cc_n1 <- function(x) { x <- suppressWarnings(as.numeric(x)); if (length(x)) x[1] else NA_real_ }   # one number or NA (empty inputs are NULL)
cc_plan_check <- function(p) {
  for (k in c("max_day", "max_loss_pct", "ctr_extra", "rrr", "size", "plan_size", "balance", "pnl_today", "min_rrr", "n_today")) p[[k]] <- cc_n1(p[[k]])
  if (!is.finite(p$n_today)) p$n_today <- 0; if (!is.finite(p$pnl_today)) p$pnl_today <- 0; if (!is.finite(p$min_rrr)) p$min_rrr <- 1.5
  for (k in c("d", "h4", "fit", "from", "to", "markets", "epic")) p[[k]] <- if (length(p[[k]])) as.character(p[[k]][1]) else ""
  row <- function(rule, ok, detail) data.frame(rule = rule, ok = ok, detail = detail, stringsAsFactors = FALSE)
  out <- list()
  mk <- trimws(unlist(strsplit(p$markets %||% "", "[,;]"))); mk <- mk[nzchar(mk)]
  out[[1]] <- row("Market allowed by the plan", if (!length(mk)) NA else toupper(p$epic) %in% toupper(mk), if (!length(mk)) "no list set (any market)" else paste("allowed:", paste(mk, collapse = ", ")))
  a <- cc_hm(p$from); z <- cc_hm(p$to); t <- as.numeric(format(p$now, "%H", tz = "Europe/London")) * 60 + as.numeric(format(p$now, "%M", tz = "Europe/London"))
  if (isTRUE(p$any_hours)) out[[2]] <- row("Trading session (UK time)", NA, sprintf("any hour allowed (Setup); preferred %s-%s, now %s", p$from, p$to, format(p$now, "%H:%M", tz = "Europe/London"))) else
  out[[2]] <- row("Trading session (UK time)", if (is.na(a) || is.na(z)) NA else t >= a && t <= z, if (is.na(a) || is.na(z)) "no session set" else sprintf("plan %s-%s, now %s", p$from, p$to, format(p$now, "%H:%M", tz = "Europe/London")))
  mx <- p$max_day
  out[[3]] <- row("Deals per day", if (!is.finite(mx)) NA else p$n_today < mx, if (!is.finite(mx)) "no maximum set" else sprintf("%d opened today, plan maximum %d", p$n_today, as.integer(mx)))
  ml <- p$max_loss_pct; lim <- if (is.finite(ml) && is.finite(p$balance)) ml / 100 * p$balance else NA
  out[[4]] <- row("Daily loss limit", if (!is.finite(lim)) NA else -min(0, p$pnl_today) < lim, if (!is.finite(lim)) "no limit set" else sprintf("today %s, limit -%s", format(round(p$pnl_today, 2), nsmall = 2), format(round(lim, 2), nsmall = 2)))
  ctr <- identical(p$fit, "against"); need <- p$min_rrr + (if (is.finite(p$ctr_extra)) p$ctr_extra else 0.5)
  for (k in c("max_size", "stop_dist", "atr", "min_stop_atr")) p[[k]] <- cc_n1(p[[k]])
  base <- if (is.finite(p$max_size)) p$max_size else p$plan_size   # ****** half = half of the size YOU set, not of the plan-risk size
  half <- is.finite(base) && is.finite(p$size) && p$size <= 0.5 * base + 1e-9
  out[[5]] <- row("Higher time-frame trend (daily / 4-hour)", if (!ctr) TRUE else (is.finite(p$rrr) && p$rrr >= need - 1e-9) || half,
                  if (!ctr) sprintf("daily %s, 4-hour %s: %s the trend", p$d %||% "?", p$h4 %||% "?", if (identical(p$fit, "with")) "with" else "not against")
                  else sprintf("AGAINST the trend (daily %s, 4-hour %s): needs R:R %.2f or more, or half size (%s or less)", p$d, p$h4, need, if (is.finite(base)) format(round(0.5 * base, 2)) else "-"))
  nw <- p$news; hit <- if (is.null(nw) || !nrow(nw)) nw else nw[nw$in_window, , drop = FALSE]
  out[[6]] <- row("High-impact news in the holding time", if (is.null(nw)) NA else !nrow(hit), if (is.null(nw)) "no Morning Sheet releases for today" else if (!nrow(hit)) "none" else paste(sprintf("%s %s", hit$time, hit$event), collapse = "; "))
  out[[length(out) + 1]] <- row("Size not above the size you set ******", if (!is.finite(p$max_size) || !is.finite(p$size)) NA else p$size <= p$max_size + 1e-9,
    if (!is.finite(p$max_size)) "no size set in box 1" else sprintf("this deal %s, your size %s", format(round(p$size, 2)), format(round(p$max_size, 2))))
  ms <- if (is.finite(p$min_stop_atr)) p$min_stop_atr else NA_real_
  out[[length(out) + 1]] <- row("Stop far enough from the entry (x ATR) ******", if (!is.finite(ms) || ms <= 0 || !is.finite(p$stop_dist) || !is.finite(p$atr) || p$atr <= 0) NA else p$stop_dist >= ms * p$atr - 1e-9,
    if (!is.finite(ms) || ms <= 0) "no minimum set" else if (!is.finite(p$stop_dist) || !is.finite(p$atr)) "stop or ATR not known yet" else sprintf("stop %.3f from the entry = %.2f ATR; plan minimum %.2f ATR (ATR %.3f)", p$stop_dist, p$stop_dist / p$atr, ms, p$atr))
  # ********** today's Morning Sheet: your own morning reading of this market says no trade
  msr <- as.character(p$ms_regime %||% "")[1]
  out[[length(out) + 1]] <- row("Morning Sheet allows this market today **********", if (!nzchar(msr)) NA else !identical(msr, "UNCLEAR_NO_TRADE"),
    if (!nzchar(msr)) "no Morning Sheet reading for this market today" else if (identical(msr, "UNCLEAR_NO_TRADE")) "your Morning Sheet marks it UNCLEAR: no trade (2 of your last losses were taken against it)" else paste("Morning Sheet regime:", msr))
  # ********** risk in money in line with your own recent trades: one oversized loss cancels many wins
  ur <- cc_n1(p$usual_risk); rk <- cc_n1(p$risk_money)
  out[[length(out) + 1]] <- row("Risk in line with your recent trades **********", if (!is.finite(ur) || ur <= 0 || !is.finite(rk)) NA else rk <= 3 * ur + 1e-9 && rk >= ur / 3 - 1e-9,
    if (!is.finite(ur) || ur <= 0) "fewer than 3 recent trades to compare" else if (!is.finite(rk)) "risk not known yet" else sprintf("this trade risks %.2f; your recent trades risked about %.2f (median): %s", rk, ur,
      if (rk > 3 * ur) "more than 3 times as much, a loss here cancels several wins" else if (rk < ur / 3) "less than a third, a win here will not cover a usual loss" else "comparable"))
  mx <- cc_n1(p$max_stop_atr)   # ******** entry close to the set-up: the stop (beyond the level that cancels it) at most x ATR away; further = entering after the move
  out[[length(out) + 1]] <- row("Entry close to the set-up (stop at most x ATR) ********", if (!is.finite(mx) || mx <= 0 || !is.finite(p$stop_dist) || !is.finite(p$atr) || p$atr <= 0) NA else p$stop_dist <= mx * p$atr + 1e-9,
    if (!is.finite(mx) || mx <= 0) "no maximum set" else if (!is.finite(p$stop_dist) || !is.finite(p$atr)) "stop or ATR not known yet" else sprintf("stop %.3f away = %.2f ATR; plan maximum %.2f ATR%s", p$stop_dist, p$stop_dist / p$atr, mx, if (p$stop_dist > mx * p$atr) ": price has already moved away from the set-up level, wait for a pull-back" else ""))
  st <- p$setups %||% character(0); st <- st[nzchar(st)]
  out[[length(out) + 1]] <- row("Set-up allowed by the plan *", if (!length(st)) NA else (p$strategy %||% "") %in% st, if (!length(st)) "no list set (any set-up)" else sprintf("this deal: %s; allowed: %s", p$strategy_label %||% p$strategy %||% "-", paste(p$setup_labels %||% st, collapse = ", ")))
  mr <- cc_n1(p$max_loss_row); lr <- cc_n1(p$loss_row); if (!is.finite(lr)) lr <- 0
  out[[length(out) + 1]] <- row("Losses in a row today (psychology) **", if (!is.finite(mr)) NA else lr < mr, if (!is.finite(mr)) "no limit set" else sprintf("%d in a row now, plan: stop after %d", as.integer(lr), as.integer(mr)))
  cr <- cc_n1(p$corr_risk_pct); cap <- cc_n1(p$cap_pct)
  out[[length(out) + 1]] <- row("Correlated open risk (related markets) **", if (!is.finite(cr) || !is.finite(cap)) NA else cr <= cap + 1e-9,
                                if (!is.finite(cr) || !is.finite(cap)) "not measured (no related open position or no cap)" else sprintf("%.2f%% with this deal and correlated open positions (cap %.2f%%)%s", cr, cap, if (nzchar(p$corr_note %||% "")) paste0(": ", p$corr_note) else ""))
  rg <- if (length(p$regime)) as.character(p$regime[1]) else ""; out[[length(out) + 1]] <- row("Market regime (ADX) *****", if (!nzchar(rg)) NA else rg != "MIXED",
    if (!nzchar(rg)) "chart not loaded" else if (rg == "MIXED") "MIXED: ADX between your thresholds, your plan says no trade" else paste("regime", rg))
  r5 <- p$r5; out[[length(out) + 1]] <- row("Rule of Five time-frames (major trend) ****", if (is.null(r5)) NA else r5$ok, if (is.null(r5)) "chart not loaded" else r5$text)
  rules <- p$rules %||% character(0); ticks <- p$ticks %||% logical(0)
  for (i in seq_along(rules)) if (nzchar(trimws(rules[i]))) out[[length(out) + 1]] <- row(paste0("Plan point ", i, ": ", rules[i]), isTRUE(ticks[i]), if (isTRUE(ticks[i])) "ticked" else "not ticked")
  cc_plan_modes(do.call(rbind, out), p$modes)
}

# ******* Block / Warn / Off per rule (Setup). Only the rules in cc_plan_mode_rules can be changed; the money rules
# (daily loss, deals per day, size, open-risk cap) and your own plan points always block.
cc_plan_mode_rules <- c(ms = "Morning Sheet allows this market today", sizecons = "Risk in line with your recent trades", chase = "Entry close to the set-up", regime = "Market regime (ADX)", r5 = "Rule of Five time-frames", news = "High-impact news in the holding time",
                        session = "Trading session (UK time)", stopatr = "Stop far enough from the entry", setup = "Set-up allowed by the plan",
                        corr = "Correlated open risk", lossrow = "Losses in a row today", market = "Market allowed by the plan")
cc_plan_mode_choices <- c("Block (order refused)" = "block", "Warn (amber, order allowed)" = "warn", "Off (not checked)" = "off")
cc_plan_modes <- function(pc, modes = NULL) {
  if (is.null(pc) || !nrow(pc)) return(pc); pc$mode <- rep("block", nrow(pc))
  for (k in names(cc_plan_mode_rules)) { m <- tolower(as.character(modes[[k]] %||% "block")[1]); if (!m %in% c("warn", "off")) next
    i <- startsWith(pc$rule, cc_plan_mode_rules[[k]]); if (!any(i)) next
    pc$mode[i] <- m
    if (m == "off") { pc$detail[i] <- paste0("switched off in Setup (", pc$detail[i], ")"); pc$ok[i] <- NA } }
  pc
}
cc_plan_hard <- function(pc) if (is.null(pc) || !nrow(pc)) logical(0) else !is.na(pc$ok) & !pc$ok & (pc$mode %||% rep("block", nrow(pc))) == "block"
cc_plan_warn <- function(pc) if (is.null(pc) || !nrow(pc)) logical(0) else !is.na(pc$ok) & !pc$ok & (pc$mode %||% rep("block", nrow(pc))) == "warn"

# ---- 2. backtest of each pattern on the loaded chart (the scan's own history) and the trade blotter -----------------
cc_backtest <- function(scan) {
  h <- scan$hist; if (is.null(h) || !nrow(h)) return(NULL)
  h <- h[h$outcome %in% c("target", "stop"), , drop = FALSE]; if (!nrow(h)) return(NULL)
  h$r <- ifelse(h$outcome == "target", h$rr, -1); h <- h[order(h$i1), , drop = FALSE]
  one <- function(d) { eq <- cumsum(d$r); dd <- max(cummax(c(0, eq))[-1] - eq, 0)
    data.frame(n = nrow(d), wins = sum(d$outcome == "target"), win_pct = 100 * mean(d$outcome == "target"), exp_r = mean(d$r), total_r = sum(d$r), max_dd_r = dd, stringsAsFactors = FALSE) }
  out <- do.call(rbind, lapply(split(h, h$key), function(d) cbind(key = d$key[1], one(d))))
  m <- match(out$key, cc_catalog$key); out$pattern <- cc_catalog$label[m]; out$bias <- cc_catalog$bias[m]
  out$verdict <- ifelse(out$n < 20, "too few cases (under 20)", ifelse(out$exp_r > 0.05, "positive: tradeable", ifelse(out$exp_r < -0.05, "negative: avoid", "break-even")))
  out <- out[order(-(out$n >= 20), -out$exp_r), , drop = FALSE]
  attr(out, "all") <- one(h); out
}
cc_blotter <- function(trades) {
  t <- trades[!(trades$status %in% c("DUPLICATE")) & !is.na(trades$status), , drop = FALSE]; if (!nrow(t)) return(NULL)
  pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est)
  t0 <- ifelse(!is.na(t$entry_ts), as.numeric(t$entry_ts), as.numeric(t$placed_ts))
  b <- data.frame(Opened = format(as.POSIXct(t0, origin = "1970-01-01", tz = "UTC"), "%d/%m/%Y %H:%M", tz = "Europe/London"), Trade = t$trade_id, Market = t$market_name %||% t$epic,
                  Side = t$direction, Size = t$size, Entry = t$entry_level, Stop = t$stop_initial, Target = t$target_level, Exit = t$exit_level,
                  Closed = format(t$exit_ts, "%d/%m/%Y %H:%M", tz = "Europe/London"), `Exit code` = t$exit_code, Status = t$status,
                  `Risk (acc)` = round(t$risk_account, 2), `P/L (acc)` = round(pl, 2), R = round(ifelse(is.finite(pl) & is.finite(t$risk_account) & t$risk_account > 0, pl / t$risk_account, NA), 2),
                  check.names = FALSE, stringsAsFactors = FALSE)
  b <- b[order(t0), , drop = FALSE]; cl <- b$Status == "CLOSED" & is.finite(b$`P/L (acc)`)
  b$`Cumulative P/L` <- NA_real_; b$`Cumulative P/L`[cl] <- round(cumsum(b$`P/L (acc)`[cl]), 2); b
}
cc_blotter_summary <- function(b) { if (is.null(b)) return(NULL); c <- b[b$Status == "CLOSED" & is.finite(b$`P/L (acc)`), , drop = FALSE]; if (!nrow(c)) return(NULL)
  eq <- cumsum(c$`P/L (acc)`); list(n = nrow(c), wins = sum(c$`P/L (acc)` > 0), win_pct = 100 * mean(c$`P/L (acc)` > 0), net = sum(c$`P/L (acc)`),
       avg_win = if (any(c$`P/L (acc)` > 0)) mean(c$`P/L (acc)`[c$`P/L (acc)` > 0]) else NA, avg_loss = if (any(c$`P/L (acc)` <= 0)) mean(c$`P/L (acc)`[c$`P/L (acc)` <= 0]) else NA,
       exp_r = if (any(is.finite(c$R))) mean(c$R, na.rm = TRUE) else NA, max_dd = max(cummax(c(0, eq))[-1] - eq, 0)) }

# ==== gaps of #1-#4 (5 Nov, round 2) ===================================================================================
# #3 Dow phase: trend of the last two swings and of the two before them
cc_dow_phase <- function(b, k = 3) {
  if (is.null(b) || nrow(b) < 2 * k + 10) return("unknown")
  now <- cc_dow_trend(b, k); prev <- cc_dow_trend(b[seq_len(max(2 * k + 6, floor(nrow(b) * 0.6))), , drop = FALSE], k)
  switch(now, UP = "Markup (up-trend)", DOWN = "Markdown (down-trend)",
         RANGE = if (prev == "DOWN") "Accumulation (range after a fall)" else if (prev == "UP") "Distribution (range after a rise)" else "Range", "unknown") }
# #2 LAT Trade Blotter (Excel, the course layout) from Capital.com trades: mapped to the LAT columns; points used as pips
cc_lat_blotter_trades <- function(t) {
  t <- t[t$status %in% "CLOSED" & !is.na(t$exit_ts), , drop = FALSE]; if (!nrow(t)) return(t)
  ent <- ifelse(is.finite(t$entry_level), t$entry_level, t$order_level); rp <- abs(ent - t$stop_initial)
  pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est)
  data.frame(asset = t$market_name %||% t$epic, entry_ts = t$entry_ts, mood_entry = t$mood_entry, direction = ifelse(t$direction == "BUY", "B", "S"),
             stake_per_pip_gbp = ifelse(rp > 0, t$risk_account / rp, NA), entry_price = ent, stop1 = t$stop_initial, initial_risk_pips = rp, target = t$target_level,
             initial_reward_pips = abs(t$target_level - ent), exit_price = t$exit_level, exit_ts = t$exit_ts, exit_code = t$exit_code, net_pnl_gbp = pl,
             pips_result = ifelse(t$direction == "BUY", 1, -1) * (t$exit_level - ent), pip_size = 1, status = "CLOSED", trade_sheet_name = t$trade_id, stringsAsFactors = FALSE)
}
# #4 the releases inside the holding time, as one line for the scenarios table
cc_news_line <- function(nw) { if (is.null(nw)) return("Morning Sheet not loaded"); h <- nw[nw$in_window, , drop = FALSE]
  if (!nrow(h)) "none" else paste(sprintf("%s %s: %s", h$time, h$event, ifelse(nzchar(h$meaning), h$meaning, "high impact")), collapse = " | ") }

# ==== #5-#10 (marked ** in the app) ===================================================================================
# #5 the course strategies found live on the chart (Pivot Point System, Holy Grail, Straddle / opening-range) as deals now
cc_course_keys <- c("pivot_bounce_long", "pivot_bounce_short", "holy_grail_long", "holy_grail_short", "on_straddle_up", "on_straddle_down", "orb_up", "orb_down")
cc_course_scenarios <- function(scan, bid, offer, min_stop_distance = NA, min_rrr = 1.5, d = 5, max_ago = 3) {
  cd <- scan$current_df; if (is.null(cd) || !nrow(cd)) return(NULL)
  x <- cd[cd$key %in% cc_course_keys & !is.na(cd$dir) & cd$candles_ago <= max_ago & is.finite(cd$invalid), , drop = FALSE]; if (!nrow(x)) return(NULL)
  a <- scan$ctx$a[scan$ctx$n]; out <- list()
  for (i in seq_len(nrow(x))) { r <- x[i, ]; dir <- r$dir; side <- if (dir > 0) "BUY" else "SELL"; px <- if (dir > 0) offer else bid; if (!is.finite(px)) next
    risk <- dir * (px - r$invalid); if (!is.finite(risk) || risk <= 0) next
    risk <- max(risk, 0.5 * a, if (is.finite(min_stop_distance)) 1.05 * min_stop_distance else 0) + 10^-d; stp <- px - dir * risk
    need <- px + dir * min_rrr * risk; tg <- if (is.finite(r$target) && dir * (r$target - need) >= 0) r$target else need
    up <- function(v) ceiling(v * 10^d - 1e-7) / 10^d; dn <- function(v) floor(v * 10^d + 1e-7) / 10^d
    out[[length(out) + 1]] <- data.frame(id = paste0("COURSE: ", r$label), side = side, type = "MARKET", entry = px, stop = if (dir > 0) up(stp) else dn(stp), target = if (dir > 0) up(tg) else dn(tg),
      note = sprintf("Course strategy found %d candle(s) ago (%s); stop beyond its cancel level %s; target %s", r$candles_ago, r$status, format(round(r$invalid, d)),
                     if (identical(tg, r$target)) "at the strategy's target" else sprintf("set to your minimum Reward:Risk %.2f", min_rrr)),
      basis = sprintf("%s (%s)", r$label, if (r$hist_n >= 8) sprintf("measured %.0f%% target-first, n=%d", r$hist_win, r$hist_n) else sprintf("only %d measured cases", r$hist_n)),
      keys = r$key, stringsAsFactors = FALSE) }
  if (length(out)) do.call(rbind, out) else NULL }
# #6 price / time filter for a break: the last n closes beyond the level by at least frac x ATR (NA = no level to test)
cc_break_filter <- function(ctx, level, dir, frac = 0.1, n_held = 1) {
  if (!is.finite(level) || is.na(dir)) return(NA); n <- ctx$n; k <- max(1L, as.integer(n_held)); w <- (n - k + 1):n
  all(dir * (ctx$c[w] - level) >= frac * ctx$a[n]) }
# #7 profile of the previous UK session (volume when Capital.com gives it, else time at price = market profile TPO)
#    POC, value area (70%) high / low, and today's initial balance (opening range, e.g. 08:00-09:00 UK)
cc_profile <- function(b, or_start = "08:00", or_minutes = 60, now = Sys.time()) {
  if (is.null(b) || nrow(b) < 20) return(NULL)
  day <- as.Date(format(b$time, "%Y-%m-%d", tz = "Europe/London")); today <- as.Date(format(now, "%Y-%m-%d", tz = "Europe/London"))
  prev <- max(day[day < today], na.rm = TRUE); if (!is.finite(prev)) return(NULL); p <- b[day == prev, , drop = FALSE]; if (nrow(p) < 5) return(NULL)
  step <- max(stats::median(p$high - p$low, na.rm = TRUE) / 4, 1e-6); bins <- seq(floor(min(p$low) / step) * step, ceiling(max(p$high) / step) * step, by = step)
  vol <- if (!is.null(p$volume) && sum(p$volume, na.rm = TRUE) > 0) p$volume else rep(1, nrow(p)); src <- if (identical(vol, rep(1, nrow(p)))) "time at price (TPO)" else "volume"
  w <- vapply(bins, function(x) sum(vol[p$low <= x & p$high >= x] / pmax(1, round((p$high[p$low <= x & p$high >= x] - p$low[p$low <= x & p$high >= x]) / step) + 1)), 0)
  pi <- which.max(w); inc <- pi; tot <- sum(w); lo <- pi; hi <- pi
  while (sum(w[lo:hi]) < 0.7 * tot && (lo > 1 || hi < length(w))) { up <- if (hi < length(w)) w[hi + 1] else -1; dnn <- if (lo > 1) w[lo - 1] else -1; if (up >= dnn) hi <- hi + 1 else lo <- lo - 1 }
  t <- b[day == today, , drop = FALSE]; ib <- c(NA, NA)
  if (nrow(t)) { st <- as.POSIXct(paste(format(today), or_start), tz = "Europe/London"); w2 <- t$time >= st & t$time < st + or_minutes * 60
    if (any(w2)) ib <- c(max(t$high[w2]), min(t$low[w2])) }
  list(day = prev, poc = bins[pi], vah = bins[hi], val = bins[lo], ib_hi = ib[1], ib_lo = ib[2], source = src) }
cc_profile_near <- function(pf, stop, target, a) { if (is.null(pf)) return("-")
  lv <- c(POC = pf$poc, VAH = pf$vah, VAL = pf$val, `IB high` = pf$ib_hi, `IB low` = pf$ib_lo); lv <- lv[is.finite(lv)]; if (!length(lv)) return("-")
  near <- function(x) { d <- abs(lv - x); k <- which.min(d); if (d[k] <= a) sprintf("%s %s", names(lv)[k], format(round(lv[k], 4))) else "none within 1 ATR" }
  sprintf("stop near %s; target near %s", near(stop), near(target)) }
# #8 confluence of independent signals on the last candle: trend, momentum, volatility, volume
cc_confluence <- function(ctx, dir) { d <- ctx$ind; n <- ctx$n; c <- ctx$c[n]; s <- function(x) if (is.finite(x)) x else NA
  tr <- s(dir * (d$ema20[n] - d$ema50[n])); di <- s(dir * (d$di_p[n] - d$di_n[n]))
  trend <- if (is.na(tr)) NA else tr > 0 && (is.na(di) || di > 0)
  mom <- { m <- s(dir * d$macd_hist[n]); r <- s(dir * (d$rsi[n] - 50)); if (is.na(m) && is.na(r)) NA else isTRUE(m > 0 || is.na(m)) && isTRUE(r > 0 || is.na(r)) }
  vola <- { m <- s(dir * (c - d$bb_mid[n])); if (is.na(m)) NA else m > 0 }
  volu <- { v <- ctx$b$volume; if (is.null(v) || sum(v, na.rm = TRUE) <= 0 || n < 12) NA else { obv <- cumsum(sign(c(0, diff(ctx$c))) * v); dir * (obv[n] - obv[n - 10]) > 0 } }
  k <- c(Trend = trend, Momentum = mom, Volatility = vola, Volume = volu); have <- k[!is.na(k)]
  list(score = sum(have), of = length(have), text = sprintf("%d/%d (%s)", sum(have), length(have), paste(sprintf("%s %s", names(k), ifelse(is.na(k), "n/a", ifelse(k, "yes", "no"))), collapse = ", "))) }
# #8 Parabolic SAR trailing stop for an open position: suggested only if it is better than the current stop
cc_sar_trail <- function(b, dir, cur_stop, price) { if (is.null(b) || nrow(b) < 20) return(NA_real_)
  sar <- tryCatch(as.numeric(TTR::SAR(cbind(b$high, b$low)))[nrow(b)], error = function(e) NA_real_); if (!is.finite(sar)) return(NA_real_)
  if (dir * (price - sar) <= 0) return(NA_real_); if (is.finite(cur_stop) && dir * (sar - cur_stop) <= 0) return(NA_real_); sar }
# #9 psychology: results by mood and right after a loss; losses in a row today
cc_psych <- function(trades) { t <- trades[trades$status %in% "CLOSED" & !is.na(trades$exit_ts), , drop = FALSE]; if (!nrow(t)) return(NULL)
  t <- t[order(t$exit_ts), , drop = FALSE]; pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est); win <- pl > 0
  by <- function(g) { g <- as.character(g); g[is.na(g)] <- "not recorded"; do.call(rbind, lapply(split(seq_along(g), g), function(i) data.frame(Group = g[i[1]], Trades = length(i), `Win %` = round(100 * mean(win[i])), `Net P/L` = round(sum(pl[i], na.rm = TRUE), 2), check.names = FALSE))) }
  after <- c("first trade", ifelse(utils::head(win, -1), "after a win", "after a loss"))
  list(mood = by(paste("Mood", t$mood_entry)), after = by(after)) }
cc_losses_in_row <- function(trades, now = Sys.time()) { d0 <- format(now, "%Y-%m-%d", tz = "Europe/London")
  t <- trades[trades$status %in% "CLOSED" & !is.na(trades$exit_ts) & format(trades$exit_ts, "%Y-%m-%d", tz = "Europe/London") == d0, , drop = FALSE]; if (!nrow(t)) return(0L)
  pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est)[order(t$exit_ts)]; r <- rev(pl <= 0); if (!length(r) || !r[1]) 0L else as.integer(which(c(!r, TRUE))[1] - 1) }
# #10 correlation of two markets' candle returns (aligned on time, last 100)
cc_corr <- function(a, b) { if (is.null(a) || is.null(b) || nrow(a) < 20 || nrow(b) < 20) return(NA_real_)
  m <- merge(data.frame(time = a$time, x = a$close), data.frame(time = b$time, y = b$close), by = "time"); if (nrow(m) < 20) return(NA_real_)
  m <- utils::tail(m[order(m$time), ], 101); stats::cor(diff(log(m$x)), diff(log(m$y)), use = "complete.obs") }
cc_setup_choices <- c("Pattern from the matrix" = "PATTERN", "Pivot Point Bounce" = "PIVOT_BOUNCE", "Holy Grail" = "HOLY_GRAIL", "Straddle" = "STRADDLE", "Opening-range breakout" = "ORB", "Other" = "OTHER")

# ******** the set-up of a scenario, from its pattern keys, name and reasons (rule, course and Claude scenarios alike)
cc_scen_setup <- function(sc) { if (is.null(sc) || !NROW(sc)) return(character(0)); g <- function(k) { v <- sc[[k]]; if (is.null(v)) rep("", NROW(sc)) else ifelse(is.na(v), "", as.character(v)) }
  t <- tolower(paste(g("keys"), g("id"), g("basis")))   # Claude rows: OTHER (their reasons may mention a pivot without being the set-up)
  ifelse(g("source") %in% "Claude", "OTHER", ifelse(grepl("pivot", t), "PIVOT_BOUNCE", ifelse(grepl("holy.?grail", t), "HOLY_GRAIL", ifelse(grepl("straddle", t), "STRADDLE",
    ifelse(grepl("(^|[^a-z])orb([^a-z_]|_up|_down|$)|opening.range", t), "ORB", "PATTERN"))))) }
cc_chart_label <- function(res) { x <- c(MINUTE = "1 Min", MINUTE_5 = "5 Min", MINUTE_15 = "15 Min", MINUTE_30 = "30 Min", HOUR = "1 Hour", HOUR_4 = "4 Hour", DAY = "Daily")[res]; if (is.na(x)) as.character(res) else unname(x) }
