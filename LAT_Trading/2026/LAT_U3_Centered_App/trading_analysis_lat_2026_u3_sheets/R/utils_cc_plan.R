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
# ********************* the course's four theoretical set-ups (Week 6 Thursday recap) for each scenario: from its first pattern, else from its set-up
cc_scen_setup4 <- function(sc) { if (is.null(sc) || !NROW(sc)) return(character(0)); k <- if (is.null(sc$keys)) rep("", NROW(sc)) else ifelse(is.na(sc$keys), "", sub(",.*$", "", sc$keys))
  st <- cc_scen_setup(sc); by_key <- ifelse(nzchar(k), cc_setup4(k), NA_character_)
  t <- tolower(paste(if (is.null(sc$id)) "" else sc$id, if (is.null(sc$basis)) "" else sc$basis))
  from_words <- ifelse(grepl("profile|poc|value area|initial balance|volume node|single print|ledge", t), "Profiles", ifelse(grepl("range|bounce|pivot|band", t), "Sideways",
                ifelse(grepl("reversal|divergence|double|head|star|hammer|engulf|failed", t), "Reversal", "Trend")))
  ifelse(!is.na(by_key), by_key, ifelse(st == "PIVOT_BOUNCE", "Sideways", ifelse(st %in% c("HOLY_GRAIL", "STRADDLE", "ORB"), "Trend", from_words))) }
cc_setup_choices <- c("Pattern from the matrix" = "PATTERN", "Pivot Point Bounce" = "PIVOT_BOUNCE", "Holy Grail" = "HOLY_GRAIL", "Straddle" = "STRADDLE", "Opening-range breakout" = "ORB", "Other" = "OTHER")

# ******** the set-up of a scenario, from its pattern keys, name and reasons (rule, course and Claude scenarios alike)
cc_scen_setup <- function(sc) { if (is.null(sc) || !NROW(sc)) return(character(0)); g <- function(k) { v <- sc[[k]]; if (is.null(v)) rep("", NROW(sc)) else ifelse(is.na(v), "", as.character(v)) }
  t <- tolower(paste(g("keys"), g("id"), g("basis")))   # Claude rows: OTHER (their reasons may mention a pivot without being the set-up)
  ifelse(g("source") %in% "Claude", "OTHER", ifelse(grepl("pivot", t), "PIVOT_BOUNCE", ifelse(grepl("holy.?grail", t), "HOLY_GRAIL", ifelse(grepl("straddle", t), "STRADDLE",
    ifelse(grepl("(^|[^a-z])orb([^a-z_]|_up|_down|$)|opening.range", t), "ORB", "PATTERN"))))) }
cc_chart_label <- function(res) { x <- c(MINUTE = "1 Min", MINUTE_5 = "5 Min", MINUTE_15 = "15 Min", MINUTE_30 = "30 Min", HOUR = "1 Hour", HOUR_4 = "4 Hour", DAY = "Daily")[res]; if (is.na(x)) as.character(res) else unname(x) }

# ====================================================================================================
# (was R/utils_cc_course_full.R)
# **** Full course coverage: the remaining LAT topics as pure functions (no Shiny).
#  Rule of Five time-frames (Week 7), support / resistance, pivots and Fibonacci (Weeks 1-2, Week 6), candlesticks / trend lines /
#  chart patterns grouped by course topic (Weeks 1-2), stochastics and RSI divergence (Week 3), types of investment risk and
#  relative value (Week 2), trading biases (Week 4 psychology; Unit 2), attitude survey (Introduction), course coverage map.

# ---- Rule of Five: base = the loaded candle; minor and major = the nearest Capital.com candles to the course table ----
cc_r5_map <- data.frame(stringsAsFactors = FALSE,
  base  = c("MINUTE_5", "MINUTE_15", "MINUTE_30", "HOUR", "HOUR_4"),
  minor = c("MINUTE", "MINUTE", "MINUTE_5", "MINUTE_15", "HOUR"),
  major = c("MINUTE_30", "HOUR", "HOUR_4", "HOUR_4", "DAY"),
  course = c("5 minutes: minor 1 minute, major 30 minutes", "between 5 and 30 minutes: minor 1 minute, major about 1 hour",
             "30 minutes: minor 5 minutes, major 2-3 hours", "about 2 hours: minor 30 minutes, major 12 hours", "between 2 hours and 1 day: minor about 1 hour, major 1 day"))
cc_r5_frames <- function(base) { i <- match(base, cc_r5_map$base); if (is.na(i)) NULL else as.list(cc_r5_map[i, ]) }
cc_r5_days <- c(MINUTE = 1, MINUTE_5 = 3, MINUTE_15 = 6, MINUTE_30 = 10, HOUR = 20, HOUR_4 = 45, DAY = 200)
# trends: named character c(minor=, base=, major=) with "UP"/"DOWN"/"RANGE"/"unknown"; dir +1 buy / -1 sell / NA
cc_r5_verdict <- function(trends, dir = NA) {
  up <- function(x) grepl("UP", toupper(x)); dn <- function(x) grepl("DOWN", toupper(x)); t <- trends
  agree <- (all(up(t)) || all(dn(t))); maj <- if (up(t[["major"]])) 1 else if (dn(t[["major"]])) -1 else 0
  txt <- sprintf("minor %s, base %s, major %s", t[["minor"]], t[["base"]], t[["major"]])
  ok <- if (is.na(dir) || maj == 0) NA else dir == maj
  list(text = paste0(txt, if (agree) " - all three agree: trade only with them" else if (maj == 0) " - major has no clear trend" else sprintf(" - position with the major trend (%s)", if (maj > 0) "up" else "down")),
       agree = agree, major = maj, ok = ok) }

# ---- Support / resistance on higher frames, pivots (7 levels) and Fibonacci --------------------------------------------
cc_sr_levels <- function(bd, price = NA) { if (is.null(bd) || nrow(bd) < 6) return(NULL)
  bd <- bd[order(bd$time), , drop = FALSE]; n <- nrow(bd); y <- bd[n - 1, ]; w <- bd[max(1, n - 5):(n - 1), , drop = FALSE]
  m <- bd[max(1, n - 22):(n - 1), , drop = FALSE]
  pv <- if (exists("u3r_pivots")) u3r_pivots(y$high, y$low, y$close) else { pp <- (y$high + y$low + y$close) / 3; c(R1 = 2 * pp - y$low, PP = pp, S1 = 2 * pp - y$high) }
  lv <- c(`Previous day high` = y$high, `Previous day low` = y$low, `Last 5 days high` = max(w$high), `Last 5 days low` = min(w$low),
          `Last month high` = max(m$high), `Last month low` = min(m$low), setNames(pv, paste("Pivot", names(pv))))
  d <- data.frame(level = names(lv), price = as.numeric(lv), stringsAsFactors = FALSE)
  if (is.finite(price)) { d$side <- ifelse(d$price > price, "resistance (above)", "support (below)"); d$dist <- d$price - price; d <- d[order(-d$price), , drop = FALSE] }
  d }
cc_sr_near <- function(d, price) { if (is.null(d) || !is.finite(price)) return("")
  a <- d[d$price > price, , drop = FALSE]; b <- d[d$price <= price, , drop = FALSE]
  sprintf("nearest resistance %s at %s; nearest support %s at %s",
          if (nrow(a)) a$level[which.min(a$price)] else "-", if (nrow(a)) format(round(min(a$price), 4)) else "-",
          if (nrow(b)) b$level[which.max(b$price)] else "-", if (nrow(b)) format(round(max(b$price), 4)) else "-") }
cc_fib_levels <- function(ctx, look = 100) { n <- ctx$n; i <- max(1, n - look + 1):n; hi <- which.max(ctx$h[i]) + i[1] - 1; lo <- which.min(ctx$l[i]) + i[1] - 1
  H <- ctx$h[hi]; L <- ctx$l[lo]; if (!is.finite(H - L) || H <= L) return(NULL); up <- lo < hi   # the last swing went up when the low came first
  r <- c(0.236, 0.382, 0.5, 0.618, 0.786); lv <- if (up) H - r * (H - L) else L + r * (H - L)
  list(swing = if (up) "up" else "down", high = H, low = L, levels = setNames(lv, paste0(100 * r, "%"))) }
cc_fib_text <- function(f, price) { if (is.null(f)) return("no clear swing")
  k <- names(f$levels)[which.min(abs(f$levels - price))]
  sprintf("last swing %s from %s to %s; retracements %s; price nearest the %s level", f$swing, format(round(f$low, 4)), format(round(f$high, 4)),
          paste(sprintf("%s %s", names(f$levels), format(round(f$levels, 4))), collapse = ", "), k) }

# ---- patterns alive grouped by course topic -------------------------------------------------------------------------------
cc_topic_of_family <- function(f) {
  t <- c(candle_rev = "Japanese candlesticks (Week 1)", candle_run = "Japanese candlesticks (Week 1)", candle_cont = "Japanese candlesticks (Week 1)",
         trend_dow = "Trend lines, support and resistance (Week 1)", level_bounce = "Trend lines, support and resistance (Week 1)", role_reversal = "Trend lines, support and resistance (Week 1)",
         trendline = "Trend lines, support and resistance (Week 1)", trendline_break = "Trend lines, support and resistance (Week 1)", channel = "Trend lines, support and resistance (Week 1)",
         fib = "Fibonacci (Week 2)", harmonic = "Fibonacci (Week 2)", elliott = "Fibonacci (Week 2)")
  ifelse(f %in% names(t), t[f], ifelse(f %in% c("ma_cross_long", "ma_pullback", "ma_stack", "macd_cross", "divergence", "rsi_extreme", "rsi_swing", "rsi_mid", "stoch", "bb_break", "bb_walk", "bb_snap", "squeeze", "atr_trend"),
         "Indicator signals (Week 3)", ifelse(f %in% c("adx", "di_cross", "holy_grail", "pivot", "straddle", "orb"), "ADX / DMI and course strategies (Week 6)", "Chart patterns (Week 2)"))) }
cc_pattern_topics <- function(cur) { if (is.null(cur) || !nrow(cur)) return("no pattern alive at the last candle")
  fam <- cc_catalog$family[match(cur$key, cc_catalog$key)]; tp <- cc_topic_of_family(fam)
  sp <- split(cur$label, tp); paste(sprintf("%s: %s", names(sp), vapply(sp, function(x) paste(unique(x), collapse = ", "), "")), collapse = "; ") }

# ---- Week 3: stochastics and RSI divergence ------------------------------------------------------------------------------
cc_divergence <- function(ctx, look = 30) { d <- ctx$ind; n <- ctx$n; if (n < look + 5 || is.null(d$rsi)) return("not enough candles")
  a <- (n - look + 1):(n - look %/% 2); b <- (n - look %/% 2 + 1):n
  hh <- max(ctx$h[b]) > max(ctx$h[a]); ll <- min(ctx$l[b]) < min(ctx$l[a])
  rh <- max(d$rsi[b], na.rm = TRUE) < max(d$rsi[a], na.rm = TRUE); rl <- min(d$rsi[b], na.rm = TRUE) > min(d$rsi[a], na.rm = TRUE)
  if (hh && rh) "bearish RSI divergence (higher price high, lower RSI high)" else if (ll && rl) "bullish RSI divergence (lower price low, higher RSI low)" else "no RSI divergence in the last 30 candles" }
cc_stoch_text <- function(ctx) { d <- ctx$ind; n <- ctx$n; k <- d$stoch_k[n]; dd <- d$stoch_d[n]; if (!is.finite(k)) return("stochastics: NA")
  sprintf("slow stochastics %%K %.0f, %%D %.0f (%s%s)", k, dd, if (k > 80) "overbought" else if (k < 20) "oversold" else "middle", if (is.finite(dd)) if (k > dd) ", %K above %D" else ", %K below %D" else "") }

# ---- Week 2: types of investment risk for one deal -------------------------------------------------------------------------
# t: list(dir, entry, stop, size_exposure (instrument ccy ~ account), risk_amt, spread, atr, hold_h, balance, news_hits, corr_note, now)
cc_risk_types <- function(t) { g <- function(x, d = NA) if (is.null(x) || !length(x) || !is.finite(x[1])) d else x[1]
  now <- t$now %||% Sys.time(); hold <- g(t$hold_h, 4); end <- now + hold * 3600
  lt <- function(x) as.POSIXlt(x, tz = "Europe/London"); ln <- lt(now); le <- lt(end)
  over22 <- as.Date(le) > as.Date(ln) || (le$hour >= 22 && ln$hour < 22)
  wkend <- ln$wday == 5 && (le$wday != 5 || le$hour >= 22) || ln$wday == 6 || (as.numeric(difftime(end, now, units = "days")) >= (6 - ln$wday))
  sp <- g(t$spread); at <- g(t$atr); stp <- abs(g(t$entry) - g(t$stop)); lev <- g(t$exposure) / g(t$balance)
  row <- function(r, lvl, d) data.frame(risk = r, level = lvl, detail = d, stringsAsFactors = FALSE)
  rbind(
    row("Market (price) risk", if (!is.finite(stp) || !is.finite(at)) "-" else if (stp < 0.5 * at) "high" else "normal",
        if (is.finite(stp) && is.finite(at)) sprintf("stop %.4g away = %.1f ATR; risk %s", stp, stp / at, if (is.finite(g(t$risk_amt))) sprintf("%.2f", t$risk_amt) else "-") else "set the stop"),
    row("Liquidity (spread) risk", if (!is.finite(sp) || !is.finite(at)) "-" else if (sp > 0.2 * at) "high" else "low",
        if (is.finite(sp) && is.finite(at)) sprintf("spread %.4g = %.0f%% of one ATR", sp, 100 * sp / at) else "spread not known"),
    row("Gap / weekend risk", if (isTRUE(wkend)) "high" else "low", if (isTRUE(wkend)) "the holding time reaches the weekend close: the price can gap past the stop" else "closed before the weekend"),
    row("Overnight (financing) risk", if (isTRUE(over22)) "cost" else "none", if (isTRUE(over22)) "held past 22:00 UK: overnight funding is charged on CFDs" else "closed the same day"),
    row("Leverage (margin) risk", if (!is.finite(lev)) "-" else if (lev > 5) "high" else if (lev > 2) "medium" else "low", if (is.finite(lev)) sprintf("exposure %.1f x the balance", lev) else "exposure not known"),
    row("Event (news) risk", if (nzchar(t$news_hits %||% "") && !(t$news_hits %in% c("none", "Morning Sheet not loaded"))) "high" else "low", t$news_hits %||% "-"),
    row("Correlation risk", if (nzchar(t$corr_note %||% "")) "high" else "low", if (nzchar(t$corr_note %||% "")) paste("same risk already open:", t$corr_note) else "no correlated open position")) }
cc_risk_text <- function(r) if (is.null(r)) "" else paste(sprintf("%s %s (%s)", r$risk, r$level, r$detail), collapse = "; ")

# ---- Week 2: relative value (spread between two related markets) ---------------------------------------------------------
cc_spread_z <- function(a, b, n = 100) { if (is.null(a) || is.null(b)) return(NULL)
  m <- merge(data.frame(time = a$time, x = a$close), data.frame(time = b$time, y = b$close), by = "time"); m <- utils::tail(m, n)
  if (nrow(m) < 20 || any(m$x <= 0 | m$y <= 0)) return(NULL); s <- log(m$x / m$y); if (!is.finite(stats::sd(s)) || stats::sd(s) < 1e-12) return(NULL); z <- (utils::tail(s, 1) - mean(s)) / stats::sd(s)
  list(z = z, ratio = utils::tail(m$x / m$y, 1), mean_ratio = exp(mean(s)), n = nrow(m),
       text = sprintf("ratio %.4f vs its %d-candle mean %.4f, z = %+.2f (%s)", utils::tail(m$x / m$y, 1), nrow(m), exp(mean(s)), z,
                      if (z > 2) "this market rich vs the other: relative-value sell" else if (z < -2) "this market cheap vs the other: relative-value buy" else "inside its normal range")) }

# ---- Week 4 psychology / Unit 2 biases from your own trades ---------------------------------------------------------------
cc_bias_checks <- function(tr, events = NULL) { t <- tr[tr$status %in% "CLOSED" & !is.na(tr$exit_ts) & !is.na(tr$entry_ts), , drop = FALSE]
  if (nrow(t) < 2) return(NULL); t <- t[order(t$exit_ts), , drop = FALSE]
  pl <- ifelse(is.finite(t$pnl_account_booked), t$pnl_account_booked, t$pnl_account_est); w <- pl > 0; hold <- as.numeric(difftime(t$exit_ts, t$entry_ts, units = "hours"))
  row <- function(b, flag, d) data.frame(bias = b, flag = flag, detail = d, stringsAsFactors = FALSE)
  disp <- if (any(w) && any(!w)) mean(hold[!w]) > 1.5 * mean(hold[w]) else NA
  sz <- t$size; aw <- sz[-1][utils::head(w, -1)]; al <- sz[-1][!utils::head(w, -1)]
  over <- if (length(aw) && length(al)) mean(aw) > 1.3 * mean(al) else NA
  gap <- as.numeric(difftime(t$entry_ts[-1], t$exit_ts[-nrow(t)], units = "mins")); rev <- sum(gap < 30 & !utils::head(w, -1), na.rm = TRUE)
  widened <- sum(is.finite(t$stop_initial) & is.finite(t$stop_level) & ifelse(t$direction == "BUY", t$stop_level < t$stop_initial, t$stop_level > t$stop_initial))
  rbind(
    row("Disposition effect (cut winners, run losers)", if (is.na(disp)) "-" else if (disp) "yes" else "no",
        if (any(w) && any(!w)) sprintf("losers held %.1f h on average, winners %.1f h", mean(hold[!w]), mean(hold[w])) else "needs both wins and losses"),
    row("Overconfidence (bigger size after a win)", if (is.na(over)) "-" else if (over) "yes" else "no",
        if (length(aw) && length(al)) sprintf("average size after a win %.2f, after a loss %.2f", mean(aw), mean(al)) else "needs trades after both"),
    row("Revenge trading (new deal < 30 min after a loss)", if (rev > 0) "yes" else "no", sprintf("%d time(s)", rev)),
    row("Loss aversion (stop moved further away)", if (widened > 0) "yes" else "no", sprintf("%d trade(s) with the stop widened", widened))) }

# ---- Attitude survey (Introduction): self-assessment on the course's themes. Statements written by the app, not the LAT form. ----
cc_attitude_items <- c(
  "I follow my trading plan even after a loss", "I accept a small loss quickly when the stop is hit", "I do not move my stop further away to avoid a loss",
  "I size every trade from the plan, not from how sure I feel", "I can sit out when there is no set-up", "I do not trade to win back a loss",
  "I take profits at my target instead of closing early from fear", "I review each trade honestly, wins and losses", "I stay calm when a trade goes against me",
  "I trade the higher time-frame trend, not my opinion")
cc_attitude_score <- function(x) { x <- as.numeric(x); if (!length(x) || all(is.na(x))) return(NULL); s <- sum(x, na.rm = TRUE); mx <- 5 * sum(!is.na(x))
  list(score = s, max = mx, pct = round(100 * s / mx), band = if (s / mx >= 0.8) "disciplined" else if (s / mx >= 0.6) "developing" else "at risk: review the psychology lecture",
       weakest = cc_attitude_items[which(x == min(x, na.rm = TRUE))]) }

# ---- the full course coverage map: every topic, where it is in the app ------------------------------------------------------------
cc_course_coverage <- data.frame(stringsAsFactors = FALSE, check.names = FALSE, matrix(ncol = 4, byrow = TRUE, c(
  "Introduction", "Economic Calendar walkthrough", "Plan & Order box 3 (releases, news window); plan check; Claude check 'News'", "full",
  "Introduction", "US Macro Crib Sheet", "Meaning next to each release and scenario; Claude check 'News' (meanings written by the app, not the LAT sheet text)", "partial: course text not in the app",
  "Introduction", "Attitude Survey", "Statistics: Attitude survey **** (self-assessment on the course themes, history kept); Claude check 'Trader state'", "full (app statements)",
  "Introduction; Weeks 9-12", "Backtesting workbook", "12. Backtest & Blotter: by strategy and by pattern; Claude check 'Measured record'", "full",
  "Introduction; Weeks 9-12", "Trade Blotter", "12. Backtest & Blotter: LAT layout Excel export", "full",
  "Week 1 (Step 1)", "Support and resistance (daily / weekly / monthly)", "Market & Patterns: Support, resistance, pivots, Fibonacci ****; Claude check 'Support / resistance'", "full",
  "Week 1 (Step 1)", "Trend lines, channels, countertrend lines", "Pattern matrix (trend lines, channels, breaks); Claude check 'Patterns by course topic'", "full",
  "Week 1 (Step 1)", "Japanese candlesticks", "Pattern matrix candle patterns; Step 1 examples; Claude check 'Patterns by course topic'", "full",
  "Week 2 (Step 2)", "Fibonacci retracements", "Fibonacci levels of the last swing ****; fib patterns; Claude check 'Support / resistance'", "full",
  "Week 2 (Step 2)", "Chart (price) patterns", "Pattern matrix (141 patterns); Step 2-3 examples", "full",
  "Week 2", "Time-frame analysis", "Daily / 4-hour trend on every scenario; Rule of Five ****; Claude check 'Higher time-frame'", "full",
  "Week 2", "Price / time filters", "Setup break filter; applied to scenarios; Claude check 'Breakout filter'", "full",
  "Week 2", "Types of investment risk", "Plan & Order: Investment risks of this deal ****; Claude check 'Investment risks'", "full",
  "Week 2", "Relative value trading", "Related markets: ratio z-score ****; Claude check 'Related markets'", "full",
  "Week 3 (Step 3)", "Moving averages, MACD", "Indicators on the chart; confluence score; Claude check 'Indicators'", "full",
  "Week 3 (Step 3)", "Oscillators: RSI, stochastics, divergence", "Indicator panel; stochastics and RSI divergence ****; Claude check 'Indicators'", "full",
  "Week 3 (Step 3)", "Bollinger bands, OBV", "Indicators; confluence (volatility, volume); Claude check 'Indicators'", "full",
  "Week 4 (Step 4)", "Bull / bear market cycle, Dow Theory", "Dow phase on every scenario; Claude check 'Higher time-frame'", "full",
  "Week 4 (Step 4)", "Options trading and payouts", "Step 4 practice tab (payoff diagrams); not used on Capital.com CFD deals", "reference only: not a CFD chart topic",
  "Week 4", "Trading psychology", "Mood / confidence on the ticket; results by mood; biases ****; reflection ****; losses-in-a-row block", "full",
  "Week 4", "Structured trading plan", "Setup plan rules; plan check on the ticket; Word export", "full",
  "Week 5 (Step 5)", "Volume profile, POC, value area", "Market & Patterns box 3; chart lines; Claude check 'Profile levels'", "full",
  "Week 5 (Step 5)", "Market profile, initial balance", "Market & Patterns box 3 (TPO when no volume; IB from the opening range)", "full",
  "Week 6 (Step 6)", "ADX and DMI", "Indicators; Holy Grail; confluence; Claude check 'ADX / SAR'", "full",
  "Week 6 (Step 6)", "Parabolic SAR", "Positions: SAR trailing stop; Claude check 'ADX / SAR'", "full",
  "Week 6; Weeks 7-8", "Short-term traders' pivot point system", "Course scanner rows; 7 pivot levels ****; Claude check 'Course strategies'", "full",
  "Week 6; Weeks 7-8", "The Holy Grail trade", "Course scanner rows; Claude check 'Course strategies'", "full",
  "Week 6; Weeks 7-8", "Straddle trade (and Morning Straddle)", "Course scanner rows; Step 6 examples; Claude check 'Course strategies'", "full",
  "Weeks 7-8", "Trade Plan Template", "Setup plan rules; Word export 'My Trading Plan'", "full",
  "Week 7", "The Rule of Five (time-frames)", "Market & Patterns: Rule of Five ****; plan check; Claude check 'Rule of Five'", "full",
  "Weeks 7-8", "LAT position sizing", "Ticket size from risk % and stop; plan check", "full",
  "Weeks 9-12", "Assessment trading (Morning Sheet, Trade Sheet)", "Journal & Trade Sheet tab; Morning Sheet in BigQuery", "full",
  "Week 1 (activity sheet)", "Single candles: hammer at support, inverted hammer, shooting star, hanging man, dragonfly and long-legged doji, marubozu breakouts of levels and trend lines", "Live chart: group 'Single candles' *********************; measured records; Claude reading", "full",
  "Week 2 (activity sheet)", "Fibonacci 50 / 61.8% pullback with the trend (with trend-line confluence) and the 100% expansion target", "Live chart: group 'Fibonacci' *********************", "full",
  "Week 2 (activity sheet)", "Price patterns: one hit its measured (MPO) target, one failed", "Measured record of every pattern (target first, stop first, time-out); practice examples with hit / miss tails", "full",
  "Week 3 (activity sheet)", "Bollinger range trading and inside / outside signals; RSI and stochastic signals at the range edges; MACD at a primary level with reversal; two moving average system", "Live chart: groups 'Bollinger strategies', 'RSI', 'Stochastic', 'MACD', 'Moving averages' *********************", "full",
  "Week 3 (activity sheet)", "On-Balance Volume (OBV)", "Needs traded volume, which Capital.com CFD prices do not have", "not applicable on Capital.com",
  "Week 4 (activity sheet)", "Options premiums, strikes, payouts; straddle with options", "Step 4 practice tab (payoff diagrams)", "reference only",
  "Week 5 (activity sheet)", "P / b-shaped days, inside and thin days, double distribution, low / high volume node bounces, POC / VAH / VAL respected, single prints, ledges, IB breaks and retests, 3+ level confluence", "Live chart: groups 'Volume profile', 'Market profile', 'Initial balance' on time-at-price profiles of each UK day *********************", "full (time-at-price, no traded volume)",
  "Week 6 (activity sheet)", "ADX above 30 / below 25, ADX falling in a pullback, DMI signals with ADX confirming", "Live chart: group 'ADX / DMI' *********************; plan thresholds in Setup", "full",
  "Week 6 Thursday (schedule)", "The four theoretical set-ups: Profiles, Trend, Reversal, Sideways", "Column 'Course set-up (Week 6)' on every scenario; Claude prompt; Trade Sheet technical box *********************", "full",
  "Weeks 7-8 (schedule)", "Trade plan development and check-up", "Setup: Trade plan check-up (17 items against the Trade Plan Template, Rule of Five and your written plan) *********************", "full",
  "Weeks 9-12 (schedule)", "End of week assessed trading review (Fridays)", "E: End-of-week review, saved to BigQuery and Dropbox 'Weekly Reviews' *********************", "full",
  "Other course units", "Bond markets, yield curves, futures, broker set-up, career module", "Not part of chart analysis on Capital.com; not built", "not applicable")))
names(cc_course_coverage) <- c("Week", "Topic", "Where in the app", "Status")

# ====================================================================================================
# (was R/utils_cc_course_checks.R)
# *** Course checks Claude adds to its chart reading (beside the pattern identification). Each names its LAT week and topic.
cc_course_checks <- data.frame(stringsAsFactors = FALSE, matrix(ncol = 5, byrow = TRUE, c(
  "htf",    "Higher time-frame trend, Dow phase and bull / bear cycle", "Week 2, Week 4", "Time-frame Analysis, Dow Theory, market cycle", "Daily and 4-hour trend, phase, with or against",
  "r5",     "Rule of Five time-frames ****", "Week 7", "The Rule of Five", "Minor, base and major trend agree or not",
  "sr",     "Support / resistance, pivots and Fibonacci ****", "Week 1, Week 2, Week 6", "Support and Resistance, Fibonacci, Pivot Points", "Nearest levels above and below the price",
  "cand",   "Patterns by course topic: candlesticks, trend lines, chart patterns ****", "Week 1, Week 2", "Japanese Candlesticks, Trend Lines, Price Patterns", "What each pattern alive means, by topic",
  "ind",    "Indicators: MAs, MACD, RSI, stochastics, divergence, Bollinger, OBV", "Week 3", "Technical indicators and oscillators", "Momentum, volatility and volume read",
  "adx",    "ADX/DMI trend strength and Parabolic SAR stop", "Week 6", "ADX and DMI, Parabolic SAR", "Is the trend strong; where to trail",
  "prof",   "POC, value area and initial balance", "Week 5", "Volume Profile, Market Profile", "Levels as stop and target anchors",
  "filt",   "Price/time breakout filter", "Week 2", "Price/Time Filters", "Is the break real or a false break",
  "strat",  "Course strategies: Pivot, Holy Grail, Straddle", "Week 6, Weeks 7-8", "Course strategies", "Does any course set-up fire now",
  "news",   "News in the holding time", "Introduction", "Economic Calendar, US Macro Crib Sheet", "Releases and what they mean for this market",
  "rel",    "Related markets, correlation and relative value", "Week 2", "Relative Value Trading", "Brent vs WTI, dollar index, ratio z-score",
  "risk",   "Types of investment risk for this deal ****", "Week 2", "Types of Investment Risk", "Market, liquidity, gap, overnight, leverage, event, correlation",
  "plan",   "Fit with my trading plan", "Week 4, Weeks 7-8", "Structured Trading Plan, Trade Plan Template", "Set-up allowed, minimum R:R, session, plan points",
  "record", "Measured record of this set-up", "Weeks 9-12", "Backtesting workbook", "Win % and expectancy from the backtest",
  "trader", "Trader state: psychology, biases, attitude survey ****", "Week 4, Introduction", "Trading Psychology, Attitude Survey", "Mood, losses in a row, biases, survey score")))
names(cc_course_checks) <- c("id", "label", "week", "topic", "desc")
cc_course_checks$default <- cc_course_checks$id %in% c("htf", "r5", "sr", "ind", "prof", "news", "risk")

cc_course_check_ui <- function(id_checkbox, selected = cc_course_checks$id[cc_course_checks$default]) {
  lab <- lapply(seq_len(nrow(cc_course_checks)), function(i) { r <- cc_course_checks[i, ]
    htmltools::tags$span(htmltools::tags$b(r$label), htmltools::tags$br(),
      htmltools::tags$span(style = "display:inline-block; font-size:11px; background:#dbeafe; color:#1e3a8a; padding:1px 7px; border-radius:6px; margin:2px 0;", paste(r$week, "·", r$topic)),
      htmltools::tags$br(), htmltools::tags$span(style = "font-size:12px; color:#555;", r$desc)) })
  shiny::checkboxGroupInput(id_checkbox, NULL, choiceNames = lab, choiceValues = cc_course_checks$id, selected = selected, width = "100%") }

# facts: named list id -> text computed in R. Builds the prompt part Claude must answer in "course".
cc_course_prompt <- function(facts) { facts <- facts[nzchar(unlist(facts))]; if (!length(facts)) return("")
  r <- cc_course_checks[match(names(facts), cc_course_checks$id), ]
  paste0("\n\nCOURSE CHECKS (LAT course; values computed in R, use them, do not invent numbers):\n",
         paste(sprintf("- [%s] %s (%s, %s): %s", r$id, r$label, r$week, r$topic, unlist(facts)), collapse = "\n"),
         "\nFor EACH course check above, add to your JSON a \"course\" array item {\"id\":\"...\",\"verdict\":\"supports|against|neutral\",\"note\":\"one or two plain sentences on what it means for the patterns found\"}.") }

cc_course_parse <- function(txt) { j <- tryCatch({ s <- sub("^[^{]*", "", txt); s <- sub("[^}]*$", "", s); jsonlite::fromJSON(s, simplifyVector = FALSE) }, error = function(e) NULL)
  if (is.null(j) || !length(j$course)) return(data.frame(id = character(), verdict = character(), note = character()))
  x <- do.call(rbind, lapply(j$course, function(z) data.frame(id = as.character(z$id %||% ""), verdict = as.character(z$verdict %||% ""), note = as.character(z$note %||% ""), stringsAsFactors = FALSE)))
  x[x$id %in% cc_course_checks$id, , drop = FALSE] }

# ********************* Weeks 7-8: trade plan check-up against the course's Trade Plan Template and Rule of Five ---------------
# x = named list of the Setup values (input ids without the "s_" prefix). Status: OK / CHECK (set, but outside what the course or
# your written plan says) / MISSING (not set).
cc_plan_checkup <- function(x) {
  v <- function(k) { y <- x[[k]]; if (is.null(y) || !length(y) || all(is.na(y)) || (is.character(y) && !any(nzchar(y)))) NULL else y }
  num <- function(k) { y <- suppressWarnings(as.numeric(v(k))); if (length(y) && is.finite(y[1])) y[1] else NA_real_ }
  row <- function(sec, item, val, status, why) data.frame(Section = sec, Item = item, Setting = val, Status = status, Why = why, stringsAsFactors = FALSE)
  st <- function(ok, set = TRUE) if (!set) "MISSING" else if (isTRUE(ok)) "OK" else "CHECK"
  rules <- vapply(1:5, function(i) { y <- v(paste0("pl_r", i)); if (is.null(y)) "" else as.character(y[1]) }, ""); nr <- sum(nzchar(trimws(rules)))
  setups <- v("pl_setups"); risk <- num("risk"); rr <- num("minrrr"); at <- num("adx_t"); ar <- num("adx_r"); sa <- num("pl_stopatr"); smx <- num("pl_stopatr_max")
  rbind(
    row("1. Markets", "Markets you trade", paste(v("pl_markets") %||% "-", collapse = ", "), st(TRUE, !is.null(v("pl_markets"))), "The template asks which markets and why; your plan names WTI, natural gas and EUR/USD."),
    row("2. Time-frames (Rule of Five)", "Chart period and the higher time-frames", "15-minute chart checked against 1-hour, 4-hour and daily (Rule of Five box)", "OK", "Week 7: trade the base time-frame in the direction of the major one."),
    row("3. Regime", "ADX trend / range thresholds", sprintf("trend %s, range %s", at %||% "-", ar %||% "-"), st(is.finite(at) && is.finite(ar) && at > ar && at >= 25 && ar <= 25, is.finite(at) && is.finite(ar)), "Week 6: ADX above 30 trending, below 25 sideways; your plan uses 30 / 20."),
    row("4. Set-ups", "Set-ups allowed", if (is.null(setups)) "any" else paste(names(cc_setup_choices)[match(setups, cc_setup_choices)], collapse = ", "),
        if (is.null(setups)) "MISSING" else if ("STRADDLE" %in% setups) "CHECK" else "OK", if ("STRADDLE" %in% setups) "The straddle needs resting orders either side; this app sends deals at the market only, so place straddles yourself or remove them from the plan." else "Name the set-ups you trade (Holy Grail, Pivot Point Bounce...)."),
    row("5. Entry triggers", "Plan points 1-5 (your exact triggers)", sprintf("%d of 5 written", nr), st(nr >= 3, nr > 0), "Each set-up needs a precise trigger you check against price before entering."),
    row("6. Stop", "Minimum and maximum stop in ATR", sprintf("min %s, max %s ATR", sa %||% "-", smx %||% "-"), st(is.finite(sa) && sa >= 1, is.finite(sa)), "Your plan: a stop of at least 1 ATR, beyond the level that cancels the set-up."),
    row("7. Target", "Minimum Reward:Risk", if (is.finite(rr)) format(rr) else "-", st(is.finite(rr) && rr >= 1.5, is.finite(rr)), "Your plan: at least 1.5; Week 6 straddles: morning 1:1, news 2:1."),
    row("8. Size", "Risk per trade (% of equity)", if (is.finite(risk)) paste0(risk, "%") else "-", st(is.finite(risk) && risk >= 1 && risk <= 2, is.finite(risk)), "Your plan: 1 to 2% fixed in advance."),
    row("8. Size", "Total open risk cap (%)", paste0(num("cap") %||% "-", "%"), st(TRUE, is.finite(num("cap"))), "Correlated markets (Brent, WTI, gas) count together."),
    row("9. Money rules", "Daily loss limit", paste0(num("pl_maxloss") %||% "-"), st(TRUE, is.finite(num("pl_maxloss"))), "Stops trading for the day after this loss."),
    row("9. Money rules", "Deals per day", paste0(num("pl_maxday") %||% "-"), st(TRUE, is.finite(num("pl_maxday"))), "Avoids over-trading."),
    row("9. Money rules", "Losses in a row before stopping", paste0(num("pl_lossrow") %||% "-"), st(TRUE, is.finite(num("pl_lossrow"))), "Week 4 psychology: stop after a run of losses."),
    row("10. News", "No entry this many minutes around high-impact releases", paste0(num("pl_news") %||% "-"), st(TRUE, is.finite(num("pl_news"))), "EIA reports and central-bank speakers move oil and FX sharply."),
    row("11. Counter-trend", "Extra R:R (or half size) against the higher time-frame", paste0(num("pl_ctr") %||% "-"), st(TRUE, is.finite(num("pl_ctr"))), "Week 2 time-frame analysis and Week 4 Dow Theory."),
    row("12. Trading hours", "Hours you trade", if (isTRUE(as.logical(v("pl_anyhours")))) "any hour" else paste(v("pl_from") %||% "-", "to", v("pl_to") %||% "-"), st(TRUE, isTRUE(as.logical(v("pl_anyhours"))) || !is.null(v("pl_from"))), "Matches the trading window of your Morning Sheet."),
    row("13. Holding time", "Expected holding time (hours)", paste0(num("hold") %||% "-"), st(TRUE, is.finite(num("hold"))), "Needed for the Trade Sheet and the measured records."),
    row("14. Review", "Morning Sheet daily, Trade Sheet per trade, end-of-week review on Fridays", "the app's one-click Morning Sheet, Review screen and E. end-of-week review", "OK", "Weeks 9-12: assessed trading reviewed every Friday.")) }

# ********************* Weeks 9-12: end-of-week assessed trading review -------------------------------------------------------------
cc_week_review <- function(trades, from, to, ms_days = character(0), sheet_ids = character(0)) {
  t <- trades; if (is.null(t) || !nrow(t)) t <- data.frame(); tz <- "Europe/London"
  if (nrow(t)) { when <- as.POSIXct(t$entry_ts %||% t$placed_ts, tz = "UTC"); d <- as.Date(format(when, "%Y-%m-%d", tz = tz)); t <- t[!is.na(d) & d >= from & d <= to & !(t$status %in% c("DUPLICATE", "CANCELLED", "REJECTED")), , drop = FALSE] }
  cl <- if (nrow(t)) t[t$status %in% "CLOSED", , drop = FALSE] else t
  num <- function(d, k) if (k %in% names(d)) suppressWarnings(as.numeric(d[[k]])) else rep(NA_real_, nrow(d))
  sg <- if (nrow(cl)) ifelse(toupper(cl$direction) %in% "BUY", 1, -1) else numeric(0); stp <- num(cl, "stop_initial"); risk <- abs(num(cl, "entry_level") - stp)
  r <- sg * (num(cl, "exit_level") - num(cl, "entry_level")) / risk; prr <- abs(num(cl, "target_level") - num(cl, "entry_level")) / risk
  ok <- is.finite(r); k <- if (any(ok)) ml_risk_stats(r[ok]) else NULL
  pf <- if (nrow(t) && "plan_followed" %in% names(t)) toupper(substr(t$plan_followed, 1, 1)) else character(0); pf <- pf[pf %in% c("Y", "N")]
  pl <- num(cl, "pl_account"); if (!any(is.finite(pl))) pl <- num(cl, "profit_loss")
  stats <- list(trades = nrow(t), closed = nrow(cl), open = sum(t$status %in% "OPEN"), win_pct = k$win_pct %||% NA_real_, avg_rr_planned = if (any(is.finite(prr))) mean(prr[is.finite(prr)]) else NA_real_,
    break_even = if (any(is.finite(prr))) 100 / (1 + mean(prr[is.finite(prr)])) else NA_real_, total_r = k$total %||% NA_real_, r_per_trade = k$expectancy %||% NA_real_, sharpe = k$sharpe %||% NA_real_, sortino = k$sortino %||% NA_real_,
    max_dd = k$max_dd %||% NA_real_, money = if (any(is.finite(pl))) sum(pl, na.rm = TRUE) else NA_real_, followed_pct = if (length(pf)) 100 * mean(pf == "Y") else NA_real_, followed_n = length(pf),
    morning_sheets = length(unique(ms_days)), trade_sheets = length(unique(sheet_ids)), trading_days = length(unique(format(as.POSIXct(t$entry_ts %||% t$placed_ts, tz = "UTC"), "%Y-%m-%d", tz = tz))))
  g <- function(k) if (k %in% names(cl)) as.character(cl[[k]]) else rep("", nrow(cl))
  tab <- if (nrow(cl)) data.frame(Date = format(as.POSIXct(cl$entry_ts, tz = "UTC"), "%a %d/%m %H:%M", tz = tz), Market = g("market_name"), Side = g("direction"), Strategy = g("strategy"), `Planned R:R` = round(prr, 2), `Result (R)` = round(r, 2),
                                    `Plan followed` = g("plan_followed"), Deviation = trimws(paste(g("deviation_type"), g("deviation_note"))), Lesson = g("lessons"), check.names = FALSE, stringsAsFactors = FALSE) else NULL
  by_strat <- if (nrow(cl) && any(ok)) do.call(rbind, lapply(split(which(ok), g("strategy")[ok]), function(i) data.frame(Strategy = g("strategy")[i[1]], Trades = length(i), `Win %` = round(100 * mean(r[i] > 0)), `Total R` = round(sum(r[i]), 2), check.names = FALSE))) else NULL
  cls <- if (nrow(cl) && exists("cc_class_of", mode = "function")) vapply(seq_len(nrow(cl)), function(i) cc_class_labels[[cc_class_of(if (exists("cc_watch_info", mode = "function")) cc_watch_info(g("epic")[i])$type %||% NA else NA, g("epic")[i], g("market_name")[i])]], "") else character(0)
  by_class <- if (nrow(cl) && any(ok) && length(cls)) do.call(rbind, lapply(split(which(ok), cls[ok]), function(i) data.frame(`Asset class` = cls[i[1]], Markets = paste(unique(g("market_name")[i]), collapse = ", "), Trades = length(i),
    `Win %` = round(100 * mean(r[i] > 0)), `Total R` = round(sum(r[i]), 2), check.names = FALSE))) else NULL
  list(from = from, to = to, stats = stats, trades = tab, by_strategy = by_strat, by_class = by_class) }
cc_week_review_lines <- function(w) { s <- w$stats; f <- function(v, d = 2) if (is.null(v) || !is.finite(v)) "-" else formatC(v, format = "f", digits = d)
  c(sprintf("Week %s to %s: %d trade(s), %d closed, %d still open, on %d trading day(s).", format(w$from, "%d/%m/%Y"), format(w$to, "%d/%m/%Y"), s$trades, s$closed, s$open, s$trading_days),
    sprintf("Win rate %s%% against a break-even of %s%% at the average planned Reward:Risk of %s.", f(s$win_pct, 0), f(s$break_even, 0), f(s$avg_rr_planned)),
    sprintf("Result %s R in total (%s R per trade); money %s.", f(s$total_r), f(s$r_per_trade), f(s$money)),
    sprintf("Sharpe %s and Sortino %s per trade; maximum drawdown %s R.", f(s$sharpe), f(s$sortino), f(s$max_dd)),
    sprintf("Plan followed in %s%% of the %d trade(s) with an answer.", f(s$followed_pct, 0), s$followed_n),
    sprintf("Evidence: %d Morning Sheet(s) and %d Individual Trade Sheet(s) saved this week.", s$morning_sheets, s$trade_sheets),
    if (s$closed < 30) "With fewer than 30 closed trades these figures describe the week; they are not yet evidence of skill." else NULL) }
cc_week_review_docx <- function(w, name, file, summary = NULL) {
  doc <- officer::read_docx(); doc <- officer::body_add_par(doc, "End of Week Assessed Trading Review", style = "heading 1")
  doc <- officer::body_add_par(doc, sprintf("%s - %s to %s", name %||% "", format(w$from, "%d/%m/%Y"), format(w$to, "%d/%m/%Y")))
  for (l in cc_week_review_lines(w)) doc <- officer::body_add_par(doc, l, style = "Normal")
  if (!is.null(w$by_strategy)) { doc <- officer::body_add_par(doc, "By strategy", style = "heading 2"); doc <- officer::body_add_table(doc, w$by_strategy, style = "table_template") }
  if (!is.null(w$by_class)) { doc <- officer::body_add_par(doc, "By asset class", style = "heading 2"); doc <- officer::body_add_table(doc, w$by_class, style = "table_template") }
  if (!is.null(w$trades)) { doc <- officer::body_add_par(doc, "Trades", style = "heading 2"); doc <- officer::body_add_table(doc, w$trades, style = "table_template") }
  if (length(summary) && any(nzchar(summary))) { doc <- officer::body_add_par(doc, "What worked, what did not, next week", style = "heading 2"); for (l in summary) doc <- officer::body_add_par(doc, l, style = "Normal") }
  print(doc, target = file); file }
