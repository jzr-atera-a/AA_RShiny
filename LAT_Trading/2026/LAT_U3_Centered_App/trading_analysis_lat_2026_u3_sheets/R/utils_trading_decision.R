# R/utils_trading_decision.R
# Pre-trade Decision Panel: the FACTS a student needs before deciding a trade, computed from prices, the Morning Sheet
# and the records. Plain R, testable without Shiny. Nothing here writes a reason, a suggestion or a trade idea:
# every function returns numbers, levels, flags or neutral factual lines ("stop is 15 pts below S1").
#
# Prices: the IG API needs a live account, so bars come from Yahoo (BZ=F for Brent) and are ALIGNED to the IG price
# the student reads from the IG ticket / watchlist (IG Brent runs 1.5-2.5% away from the futures price). Every card
# says where its numbers came from (source badge) and when.

if (!exists("tr_or", mode = "function")) tr_or <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
if (!exists("%||%", mode = "function")) `%||%` <- function(a, b) if (is.null(a)) b else a

tr_dec_badge <- c(screenshot = "read from your IG screenshot", typed = "typed by you", yahoo_aligned = "Yahoo bars aligned to your IG price (approximate)",
                  yahoo_raw = "Yahoo bars NOT aligned to IG (no IG price given)", sheet = "from your Morning Sheet", records = "from your trade records",
                  computed = "computed", rules = "fixed rules")

tr_dec_utc <- function(x) { x <- as.POSIXct(x); attr(x, "tzone") <- "UTC"; x }   # one time zone in comparisons (no tzone warnings)
tr_dec_default_scale <- function(asset) if (toupper(asset) %in% c("BRENT", "WTI")) 100 else 1
# Align Yahoo bars to the IG price: scale (IG points) then shift so the last Yahoo close equals the IG price.
tr_dec_align <- function(p, ig_price = NA_real_, asset = "BRENT") {
  b <- p$bars; if (is.null(b) || !nrow(b)) return(NULL)
  last <- utils::tail(b$close, 1)
  k <- if (is.finite(ig_price)) { k0 <- tr_scale_to(ig_price, last); if (k0 == 1 && abs(log10(ig_price / last)) > 0.3) tr_dec_default_scale(asset) else k0 } else tr_dec_default_scale(asset)
  off <- if (is.finite(ig_price)) ig_price - last * k else 0
  for (cn in c("open", "high", "low", "close")) b[[cn]] <- b[[cn]] * k + off
  list(bars = b, k = k, off = off, aligned = is.finite(ig_price), last_time = utils::tail(b$time, 1), tz = p$tz %||% "UTC")
}
tr_dec_align_with <- function(p, k, off) { if (is.null(p)) return(NULL); b <- p$bars; for (cn in c("open", "high", "low", "close")) b[[cn]] <- b[[cn]] * k + off; list(bars = b, k = k, off = off, tz = p$tz %||% "UTC") }

# ---- noise ---------------------------------------------------------------------------------
tr_dec_atr <- function(b, n = 14) {
  if (is.null(b) || nrow(b) < n + 1) return(NA_real_)
  pc <- c(NA, utils::head(b$close, -1)); tr <- pmax(b$high - b$low, abs(b$high - pc), abs(b$low - pc), na.rm = TRUE)
  mean(utils::tail(tr, n))
}
tr_dec_uk_date <- function(t) as.Date(format(t, "%Y-%m-%d", tz = "Europe/London"))
# typical 3-hour range (median of rolling 12 x 15-min windows) and mean day range over the last `days` UK sessions
tr_dec_noise <- function(b15, days = 5, window_bars = 12) {
  if (is.null(b15) || !nrow(b15)) return(list(atr15 = NA_real_, range3h = NA_real_, day_range = NA_real_, days = 0L))
  d <- tr_dec_uk_date(b15$time); keep <- utils::tail(sort(unique(d)), days); dr <- numeric(0); r3 <- numeric(0)
  for (k in keep) { x <- b15[d == k, , drop = FALSE]; if (nrow(x) < 4) next
    dr <- c(dr, max(x$high) - min(x$low))
    if (nrow(x) >= window_bars) for (i in seq_len(nrow(x) - window_bars + 1)) { w <- x[i:(i + window_bars - 1), ]; r3 <- c(r3, max(w$high) - min(w$low)) } }
  list(atr15 = tr_dec_atr(b15, 14), range3h = if (length(r3)) stats::median(r3) else NA_real_, day_range = if (length(dr)) mean(dr) else NA_real_,
       day_ranges = dr, days = length(dr))
}

# ---- regime --------------------------------------------------------------------------------
tr_dec_regime <- function(b, n = 14, trend_min = 30, range_max = 20) {
  if (is.null(b) || nrow(b) < 2 * n + 2) return(list(adx = NA_real_, dip = NA_real_, din = NA_real_, label = "not available", bars = if (is.null(b)) 0L else nrow(b)))
  x <- tryCatch(TTR::ADX(cbind(b$high, b$low, b$close), n = n), error = function(e) NULL); if (is.null(x)) return(list(adx = NA_real_, dip = NA_real_, din = NA_real_, label = "not available", bars = nrow(b)))
  last <- utils::tail(stats::na.omit(as.data.frame(x)), 1)
  adx <- last$ADX; lab <- tr_regime(adx, trend_min, range_max)
  list(adx = adx, dip = last$DIp, din = last$DIn, bars = nrow(b),
       label = switch(tr_or(lab, "NA"), TREND = "TREND", RANGE = "RANGE", UNCLEAR_NO_TRADE = "MIXED (between your thresholds: no trade by your plan)", "not available"),
       direction = if (last$DIp > last$DIn) "+DI above -DI (up pressure)" else "-DI above +DI (down pressure)")
}

# ---- levels ----------------------------------------------------------------------------------
# fractal swing points: a high (low) that is the highest (lowest) of the k bars either side
tr_dec_swings <- function(b, k = 3) {
  n <- nrow(b); if (is.null(b) || n < 2 * k + 1) return(data.frame(time = as.POSIXct(character(0), tz = "UTC"), price = numeric(0), type = character(0)))
  hi <- vapply((k + 1):(n - k), function(i) b$high[i] >= max(b$high[(i - k):(i + k)]), TRUE)
  lo <- vapply((k + 1):(n - k), function(i) b$low[i] <= min(b$low[(i - k):(i + k)]), TRUE)
  idx <- (k + 1):(n - k)
  rbind(data.frame(time = b$time[idx[hi]], price = b$high[idx[hi]], type = rep("swing high", sum(hi))),
        data.frame(time = b$time[idx[lo]], price = b$low[idx[lo]], type = rep("swing low", sum(lo))))
}
# All reference levels (already on the IG scale): previous session H/L/C, pivots, overnight H/L, 24-hour spike high/low,
# recent swing highs/lows. daily: aligned daily bars. Returns data.frame(name, level, time, group).
tr_dec_levels <- function(b15, daily = NULL, now = Sys.time(), day = tr_dec_uk_date(now)) {
  now <- tr_dec_utc(now); out <- list(); add <- function(name, level, time = as.POSIXct(NA), group) if (length(level) && is.finite(level)) out[[length(out) + 1]] <<- data.frame(name = name, level = level, time = as.POSIXct(time), group = group, stringsAsFactors = FALSE)
  if (!is.null(daily) && nrow(daily$bars) >= 2) {
    db <- daily$bars; dd <- as.Date(format(db$time, tz = daily$tz %||% "UTC")); prev <- db[dd < as.Date(day), , drop = FALSE]
    if (nrow(prev)) { r <- utils::tail(prev, 1); add("Previous session high", r$high, r$time, "session"); add("Previous session low", r$low, r$time, "session"); add("Previous session close", r$close, r$time, "session")
      pv <- tr_pivots(r$high, r$low, r$close); for (nm in c("pp", "r1", "r2", "r3", "s1", "s2", "s3")) add(toupper(nm), pv[[nm]], r$time, "pivot") }
  }
  if (!is.null(b15) && nrow(b15)) {
    w <- tr_overnight_window(day, now); o <- tr_overnight_from_bars(b15, w$from, w$to, 15)
    if (!is.null(o)) { add("Overnight high (21:00 UK to now)", o$high, NA, "overnight"); add("Overnight low (21:00 UK to now)", o$low, NA, "overnight") }
    t_end <- min(as.numeric(now), as.numeric(max(b15$time)) + 900)        # the last 24 hours of TRADING (a weekend is skipped)
    l24 <- b15[as.numeric(b15$time) >= t_end - 24 * 3600 & b15$time <= now, , drop = FALSE]
    if (nrow(l24)) { ih <- which.max(l24$high); il <- which.min(l24$low)
      add("24-hour spike high", l24$high[ih], l24$time[ih], "spike"); add("24-hour spike low", l24$low[il], l24$time[il], "spike")
      sw <- tr_dec_swings(l24, 3); px <- utils::tail(l24$close, 1)
      sw <- sw[order(sw$type, -as.numeric(sw$time)), , drop = FALSE]; sw <- sw[!duplicated(paste(sw$type, round(sw$price / 3))), , drop = FALSE]   # one swing per ~3-pt band
      hs <- sw[sw$type == "swing high" & sw$price > px, , drop = FALSE]; hs <- hs[order(hs$price), , drop = FALSE]
      ls <- sw[sw$type == "swing low" & sw$price < px, , drop = FALSE]; ls <- ls[order(-ls$price), , drop = FALSE]
      for (i in seq_len(min(3, nrow(hs)))) add(sprintf("Swing high %s", format(hs$time[i], "%d/%m %H:%M", tz = "Europe/London")), hs$price[i], hs$time[i], "swing")
      for (i in seq_len(min(3, nrow(ls)))) add(sprintf("Swing low %s", format(ls$time[i], "%d/%m %H:%M", tz = "Europe/London")), ls$price[i], ls$time[i], "swing") }
  }
  if (!length(out)) return(data.frame(name = character(0), level = numeric(0), time = as.POSIXct(character(0)), group = character(0)))
  d <- do.call(rbind, out); d <- d[order(-d$level), , drop = FALSE]
  # levels within half a point of each other are one level with several names
  cl <- cumsum(c(TRUE, abs(diff(d$level)) >= 0.5))
  m <- do.call(rbind, lapply(split(seq_len(nrow(d)), cl), function(ix) { r <- d[ix[1], , drop = FALSE]; r$name <- paste(unique(d$name[ix]), collapse = " = "); r }))
  rownames(m) <- NULL; m
}
# nearest level above and below a price (at least `min_gap` points away)
tr_dec_nearest <- function(levels, price, min_gap = 0) {
  if (is.null(levels) || !nrow(levels) || !is.finite(price)) return(list(above = NULL, below = NULL))
  a <- levels[levels$level > price + min_gap, , drop = FALSE]; b <- levels[levels$level < price - min_gap, , drop = FALSE]
  list(above = if (nrow(a)) a[which.min(a$level), ] else NULL, below = if (nrow(b)) b[which.max(b$level), ] else NULL)
}

# ---- the student's planned trade ---------------------------------------------------------------
# entry/stop/target in IG points; dir "B"/"S". Facts about where the stop and target sit relative to the levels.
tr_dec_stop_check <- function(entry, stop, dir, levels, atr15 = NA_real_) {
  if (!all(is.finite(c(entry, stop)))) return(NULL)
  sg <- if (identical(dir, "S")) -1 else 1; dist <- (entry - stop) * sg
  lv <- if (is.null(levels)) data.frame(name = character(0), level = numeric(0)) else levels
  between <- lv[(lv$level - stop) * sg > 0 & (entry - lv$level) * sg > 0, , drop = FALSE]
  side <- lv[(entry - lv$level) * sg > 0, , drop = FALSE]                       # supports (buy) / resistances (sell) on the stop side
  near <- if (nrow(side)) side[which.min(abs(entry - side$level)), ] else NULL
  beyond <- if (!is.null(near)) (near$level - stop) * sg else NA_real_          # >0: the stop is beyond that level by this many points
  needed <- if (!is.null(near) && is.finite(atr15)) abs(entry - near$level) + atr15 else NA_real_
  list(stop_pts = dist, between = between, nearest = near, beyond_nearest = beyond, stop_beyond_one_atr = needed,
       atr_multiple = if (is.finite(atr15) && atr15 > 0) dist / atr15 else NA_real_)
}
tr_dec_target_check <- function(entry, target, dir, levels, stop_pts = NA_real_) {
  if (!all(is.finite(c(entry, target)))) return(NULL)
  sg <- if (identical(dir, "S")) -1 else 1; rew <- (target - entry) * sg
  lv <- if (is.null(levels)) data.frame(name = character(0), level = numeric(0)) else levels
  must <- lv[(lv$level - entry) * sg > 0 & (target - lv$level) * sg > 0, , drop = FALSE]
  must <- must[order(abs(must$level - entry)), , drop = FALSE]
  list(reward_pts = rew, rrr = if (is.finite(stop_pts) && stop_pts > 0) rew / stop_pts else NA_real_, must_pass = must)
}
# How often a stop / target of these sizes was touched first from ANY 15-min close of the last `sessions` UK sessions,
# within `hold_bars` bars. A description of recent movement, not a forecast for this setup.
tr_dec_stop_stats <- function(b15, dir, stop_pts, target_pts, hold_bars = 16, sessions = 20) {
  if (is.null(b15) || nrow(b15) < hold_bars + 10 || !all(is.finite(c(stop_pts, target_pts))) || stop_pts <= 0) return(NULL)
  d <- tr_dec_uk_date(b15$time); keep <- utils::tail(sort(unique(d)), sessions); b <- b15[d %in% keep, , drop = FALSE]; n <- nrow(b)
  if (n <= hold_bars) return(NULL)
  sg <- if (identical(dir, "S")) -1 else 1; s_hit <- 0L; t_first <- 0L; m <- 0L
  for (i in seq_len(n - hold_bars)) { e <- b$close[i]; w <- (i + 1):(i + hold_bars)
    adv <- if (sg > 0) e - b$low[w] else b$high[w] - e; fav <- if (sg > 0) b$high[w] - e else e - b$low[w]
    is <- which(adv >= stop_pts)[1]; it <- which(fav >= target_pts)[1]; m <- m + 1L
    if (!is.na(is)) s_hit <- s_hit + 1L
    if (!is.na(it) && (is.na(is) || it < is)) t_first <- t_first + 1L }
  list(n = m, sessions = length(keep), stop_touched = s_hit / m, target_first = t_first / m, hold_hours = hold_bars / 4)
}
# risk at the available size, against the plan
tr_dec_risk <- function(stop_pts, target_pts, size, min_size, equity, plan_risk_pct = NA, cap_pct = NA, min_rrr = NA, open_risk_gbp = 0,
                        spread = NA_real_, costs = NA_real_, margin = NA_real_) {
  size_used <- if (is.finite(size)) size else min_size
  risk <- stop_pts * size_used; rew <- target_pts * size_used
  w <- character(0); cand <- character(0)
  if (is.finite(min_size) && is.finite(size) && size < min_size) w <- c(w, sprintf("Size %s is below IG's minimum of %s per point: the platform will not accept it.", format(size), format(min_size)))
  rp <- 100 * risk / equity; tot <- 100 * (risk + open_risk_gbp) / equity
  if (is.finite(plan_risk_pct) && rp > plan_risk_pct + 1e-9) { w <- c(w, sprintf("Risk %.2f%% is above your plan's %.2f%% per trade.", rp, plan_risk_pct)); cand <- c(cand, "Oversized / over risk cap") }
  if (is.finite(cap_pct) && tot > cap_pct + 1e-9) { w <- c(w, sprintf("Combined open risk %.2f%% would exceed your %.2f%% cap.", tot, cap_pct)); cand <- c(cand, "Oversized / over risk cap") }
  rrr <- if (stop_pts > 0) target_pts / stop_pts else NA_real_
  if (is.finite(min_rrr) && is.finite(rrr) && rrr < min_rrr - 1e-9) w <- c(w, sprintf("Planned RRR %.2f is below your plan's minimum of %.2f.", rrr, min_rrr))
  max_stop <- if (is.finite(plan_risk_pct) && is.finite(min_size) && min_size > 0) equity * plan_risk_pct / 100 / max(size_used, min_size) else NA_real_
  list(size = size_used, risk_gbp = risk, reward_gbp = rew, risk_pct = rp, combined_pct = tot, rrr = rrr, max_stop_at_plan = max_stop,
       spread_share_stop = if (is.finite(spread) && stop_pts > 0) spread / stop_pts else NA_real_, spread_share_target = if (is.finite(spread) && target_pts > 0) spread / target_pts else NA_real_,
       costs = costs, margin = margin, margin_pct = if (is.finite(margin)) 100 * margin / equity else NA_real_, warnings = w, deviation_candidates = unique(cand))
}

# ---- calendar and clock --------------------------------------------------------------------------
tr_dec_oil_pattern <- "EIA|API |API$|OPEC|Baker Hughes|[Cc]rude|[Oo]il|[Gg]asoline|[Dd]istillate"
# today: the Morning Sheet's "today" calendar text; yday: its "overnight" text. hold_from/hold_to: POSIXct.
tr_dec_calendar <- function(today_txt, yday_txt = NA, now = Sys.time(), hold_from = now, hold_to = now + 4 * 3600) {
  ev <- tr_calendar_parse_text(today_txt); yd <- tr_calendar_parse_text(yday_txt)
  if (nrow(ev)) {
    day <- format(now, "%Y-%m-%d", tz = "Europe/London")
    ev$at <- as.POSIXct(ifelse(grepl("^\\d{1,2}:\\d{2}$", ev$time), paste(day, ev$time), NA), tz = "Europe/London")
    attr(ev$at, "tzone") <- "UTC"; hold_from <- as.POSIXct(hold_from); hold_to <- as.POSIXct(hold_to); attr(hold_from, "tzone") <- "UTC"; attr(hold_to, "tzone") <- "UTC"
    ev$in_window <- !is.na(ev$at) & ev$at >= hold_from & ev$at <= hold_to & ev$importance %in% c("High", "Medium")
    ev$oil <- grepl(tr_dec_oil_pattern, ev$event); now <- tr_dec_utc(now)
    nxt <- ev[!is.na(ev$at) & ev$at > now & ev$importance == "High", , drop = FALSE]
    nxt <- if (nrow(nxt)) nxt[which.min(nxt$at), ] else NULL
  } else nxt <- NULL
  list(events = ev, yesterday = yd, next_high = nxt, minutes_to_next_high = if (!is.null(nxt)) as.numeric(difftime(nxt$at, now, units = "mins")) else NA_real_)
}
tr_ig_friday_close_uk <- "21:00"   # IG Brent weekend close (UK time): check IG's market information for the exact time
tr_dec_clock <- function(now = Sys.time(), hold_to = NA) {
  lt <- as.POSIXlt(now, tz = "Europe/London"); out <- character(0)
  fri <- as.Date(format(now, "%Y-%m-%d", tz = "Europe/London")) + ((5 - lt$wday) %% 7)
  close <- as.POSIXct(paste(format(fri), tr_ig_friday_close_uk), tz = "Europe/London")
  hrs <- as.numeric(difftime(close, now, units = "hours"))
  if (lt$wday == 5) out <- c(out, sprintf("Friday: IG Brent closes for the weekend at about %s UK (%.1f hours from now). A position held past it carries weekend gap risk.", tr_ig_friday_close_uk, max(hrs, 0)))
  if (inherits(hold_to, "POSIXct") && !is.na(hold_to) && hold_to > close && now < close) out <- c(out, sprintf("Your planned holding window ends after the Friday close (%s %s UK).", format(fri, "%a %d/%m"), tr_ig_friday_close_uk))
  d <- as.Date(format(now, "%Y-%m-%d", tz = "Europe/London"))
  if (d < as.Date("2026-10-25") && d >= as.Date("2026-10-19")) out <- c(out, "UK clocks go back on Sun 25 Oct 2026: from Monday UK time is GMT, and US releases come one hour earlier in UK time until 1 Nov (EIA 14:30 instead of 15:30).")
  if (d >= as.Date("2026-10-25") && d < as.Date("2026-11-01")) out <- c(out, "UK is on GMT, the US is still on summer time until Sun 1 Nov: US releases are one hour earlier in UK time this week (EIA Wednesday 14:30 UK, US data 12:30 UK).")
  if (d >= as.Date("2026-11-01") && d <= as.Date("2026-11-13")) out <- c(out, "Both UK and US are on winter time: US releases are back to their usual UK times (EIA 15:30 UK, US data 13:30 UK).")
  list(hours_to_friday_close = hrs, lines = out)
}

# ---- track record and follow-through ---------------------------------------------------------------
# where each past entry sat: points under the 24-hour high (buys) / above the 24-hour low (sells), from Yahoo bars
# anchored at the trade's own entry price.
tr_dec_entry_location <- function(trade, b15raw, k = 100) {
  if (is.null(b15raw) || is.na(trade$entry_ts)) return(NA_real_)
  trade$entry_ts <- tr_dec_utc(trade$entry_ts)
  b <- b15raw$bars; at <- b[b$time <= trade$entry_ts, , drop = FALSE]; if (!nrow(at)) return(NA_real_)
  off <- trade$entry_price - utils::tail(at$close, 1) * k
  w <- at[at$time >= trade$entry_ts - 24 * 3600, , drop = FALSE]; if (!nrow(w)) return(NA_real_)
  if (identical(trade$direction, "S")) trade$entry_price - (min(w$low) * k + off) else (max(w$high) * k + off) - trade$entry_price
}
tr_dec_track <- function(closed, b15raw = NULL, k = 100) {
  if (is.null(closed) || !nrow(closed)) return(NULL)
  pnl <- closed$net_pnl_gbp
  loc <- vapply(seq_len(nrow(closed)), function(i) tr_dec_entry_location(closed[i, ], b15raw, k), 0)
  bucket <- cut(loc, c(-Inf, 50, 150, Inf), labels = c("under 50 pts from the 24h extreme", "50-150 pts", "over 150 pts"))
  hr <- as.integer(format(closed$entry_ts, "%H", tz = "Europe/London")); hb <- cut(hr, c(-1, 7, 11, 15, 24), labels = c("before 08:00", "08:00-11:59", "12:00-15:59", "16:00 and later"))
  g <- function(v, lab) { v <- as.character(v); v[is.na(v)] <- "(not known)"
    do.call(rbind, lapply(split(seq_along(v), v), function(ix) data.frame(Group = lab, Value = v[ix[1]], Trades = length(ix), Wins = sum(pnl[ix] > 0), `Net P/L (GBP)` = sum(pnl[ix]), check.names = FALSE, stringsAsFactors = FALSE))) }
  list(n = nrow(closed), wins = sum(pnl > 0), net = sum(pnl), avg_win = if (any(pnl > 0)) mean(pnl[pnl > 0]) else NA_real_, avg_loss = if (any(pnl < 0)) mean(pnl[pnl < 0]) else NA_real_,
       location = loc, by = rbind(g(ifelse(closed$direction == "B", "Buy", "Sell"), "Direction"), g(bucket, "Entry distance from 24h high (buys) / low (sells)"),
                                  g(hb, "Entry time (UK)"), g(ifelse(is.na(closed$plan_followed), NA, ifelse(closed$plan_followed, "plan followed", "deviation")), "Plan")))
}
# After the exit: did price go on to the target (or the stop, for exits that were not at the stop)? MFE / MAE in the trade.
tr_dec_follow <- function(trade, b15raw, k = 100, hours_after = 24, now = Sys.time()) {
  if (is.null(b15raw) || is.na(trade$exit_ts) || is.na(trade$entry_ts)) return(NULL)
  trade$entry_ts <- tr_dec_utc(trade$entry_ts); trade$exit_ts <- tr_dec_utc(trade$exit_ts); now <- tr_dec_utc(now)
  b <- b15raw$bars; sg <- if (identical(trade$direction, "S")) -1 else 1
  at_e <- b[b$time <= trade$entry_ts, , drop = FALSE]; at_x <- b[b$time <= trade$exit_ts, , drop = FALSE]; if (!nrow(at_e) || !nrow(at_x)) return(NULL)
  off_e <- trade$entry_price - utils::tail(at_e$close, 1) * k; off_x <- trade$exit_price - utils::tail(at_x$close, 1) * k
  inn <- b[b$time > trade$entry_ts & b$time <= trade$exit_ts, , drop = FALSE]
  aft <- b[b$time > trade$exit_ts & b$time <= min(trade$exit_ts + hours_after * 3600, now), , drop = FALSE]
  mfe <- if (nrow(inn)) max(((if (sg > 0) inn$high else inn$low) * k + off_e - trade$entry_price) * sg) else NA_real_
  mae <- if (nrow(inn)) max((trade$entry_price - ((if (sg > 0) inn$low else inn$high) * k + off_e)) * sg) else NA_real_
  if (!nrow(aft)) return(list(mfe = mfe, mae = mae, after_hours = 0, reached_target = NA, reached_stop = NA, after_high = NA_real_, after_low = NA_real_))
  hi <- aft$high * k + off_x; lo <- aft$low * k + off_x
  rt <- if (sg > 0) any(hi >= trade$target) else any(lo <= trade$target)
  rs <- if (sg > 0) any(lo <= trade$stop1) else any(hi >= trade$stop1)
  t_rt <- if (rt) aft$time[which(if (sg > 0) hi >= trade$target else lo <= trade$target)[1]] else as.POSIXct(NA)
  list(mfe = mfe, mae = mae, after_hours = as.numeric(difftime(max(aft$time), trade$exit_ts, units = "hours")), after_high = max(hi), after_low = min(lo),
       reached_target = rt, reached_target_at = t_rt, reached_stop = if (identical(trade$exit_code, "S1")) NA else rs,
       stopped_then_target = identical(trade$exit_code, "S1") && rt)
}

# ---- a resting order (limit / stop entry): would it have filled before it expired? -----------------------------
# bars: aligned 15-min bars (IG Mid scale). half_spread: IG Buy = Mid + half spread, Sell = Mid - half spread.
# type "limit": a buy fills when Buy <= entry (a sell when Sell >= entry); "stop": a buy fills when Buy >= entry.
tr_dec_order_outcome <- function(bars, dir, type, entry, placed, expiry, half_spread = 0, now = Sys.time()) {
  if (is.null(bars) || !nrow(bars) || !is.finite(entry) || is.na(placed)) return(NULL)
  placed <- tr_dec_utc(placed); expiry <- tr_dec_utc(expiry); now <- tr_dec_utc(now)
  end <- if (is.na(expiry)) now else min(expiry, now)
  w <- bars[bars$time + 15 * 60 > placed & bars$time < end, , drop = FALSE]; if (!nrow(w)) return(list(status = "NO_DATA", lines = "No price bars cover the order window yet."))
  buy <- identical(dir, "B"); lo <- w$low + (if (buy) half_spread else -half_spread); hi <- w$high + (if (buy) half_spread else -half_spread)
  hit <- if (identical(type, "limit")) (if (buy) lo <= entry else hi >= entry) else (if (buy) hi >= entry else lo <= entry)
  side <- if (buy) "Buy" else "Sell"; ext <- if (xor(identical(type, "limit"), !buy)) min(lo) else max(hi)
  ext_lab <- if (xor(identical(type, "limit"), !buy)) "lowest" else "highest"
  f <- which(hit)[1]; fmt <- function(t) format(t, "%H:%M", tz = "Europe/London")
  done <- !is.na(expiry) && now >= expiry
  if (!is.na(f)) return(list(status = "FILLED_LIKELY", fill_time = w$time[f], extreme = ext,
    lines = sprintf("The %s price appears to reach %s in the 15-min bar starting %s UK (Yahoo bars aligned to IG: confirm with your IG History / Activity screenshot).", side, tr_ntrim(entry), fmt(w$time[f]))))
  list(status = if (done) "EXPIRED" else "WORKING", extreme = ext,
       lines = c(sprintf("Between %s and %s UK the %s %s price was about %s, so it did not reach %s.", fmt(placed), fmt(end), ext_lab, side, tr_ntrim(round(ext, 1)), tr_ntrim(entry)),
                 if (done) sprintf("The order expired at %s UK unfilled.", fmt(expiry)) else "The order is still working."))
}
tr_dec_after <- function(bars, from, to) {
  from <- tr_dec_utc(from); to <- tr_dec_utc(to)
  w <- bars[bars$time >= from & bars$time < to, , drop = FALSE]; if (!nrow(w)) return(character(0))
  il <- which.min(w$low); ih <- which.max(w$high); fmt <- function(t) format(t, "%H:%M", tz = "Europe/London")
  sprintf("After that, the low was about %s (%s UK) and the high about %s (%s UK), up to %s UK.", tr_ntrim(round(w$low[il])), fmt(w$time[il]), tr_ntrim(round(w$high[ih])), fmt(w$time[ih]), fmt(max(w$time) + 900))
}

# ---- consistency between the student's words and the numbers (neutral facts, never rewriting) -----------------
tr_dec_text_checks <- function(dir, stop, target, stop_reason, target_reason, levels = NULL) {
  out <- character(0); num <- function(x) suppressWarnings(as.numeric(gsub(",", "", x)))
  scan <- function(txt) { txt <- tr_or(txt, ""); if (!nzchar(txt)) return(data.frame(word = character(0), level = numeric(0)))
    m <- regmatches(txt, gregexpr("(?i)\\b(below|under|beneath|above|over|beyond)\\s+(?:the\\s+)?(?:[A-Za-z0-9 ]{0,20}?\\s)?(\\d{3,6}(?:[.,]\\d+)?)", txt, perl = TRUE))[[1]]
    if (!length(m)) return(data.frame(word = character(0), level = numeric(0)))
    data.frame(word = tolower(sub("^(\\w+).*$", "\\1", m)), level = num(sub("^.*?(\\d{3,6}(?:[.,]\\d+)?)$", "\\1", m, perl = TRUE)), stringsAsFactors = FALSE) }
  s <- scan(stop_reason)
  for (i in seq_len(nrow(s))) { below <- s$word[i] %in% c("below", "under", "beneath")
    if (is.finite(stop) && is.finite(s$level[i]) && below && stop >= s$level[i]) out <- c(out, sprintf("Reason for Stop says 'below %s', but the stop (%s) is not below it.", tr_ntrim(s$level[i]), tr_ntrim(stop)))
    if (is.finite(stop) && is.finite(s$level[i]) && !below && stop <= s$level[i]) out <- c(out, sprintf("Reason for Stop says '%s %s', but the stop (%s) is not above it.", s$word[i], tr_ntrim(s$level[i]), tr_ntrim(stop))) }
  t <- scan(target_reason)
  for (i in seq_len(nrow(t))) { below <- t$word[i] %in% c("below", "under", "beneath")
    if (is.finite(target) && is.finite(t$level[i]) && below && target >= t$level[i]) out <- c(out, sprintf("Reason for Target says 'below %s', but the target (%s) is not below it.", tr_ntrim(t$level[i]), tr_ntrim(target)))
    if (is.finite(target) && is.finite(t$level[i]) && !below && target <= t$level[i]) out <- c(out, sprintf("Reason for Target says '%s %s', but the target (%s) is not above it.", t$word[i], tr_ntrim(t$level[i]), tr_ntrim(target))) }
  if (identical(dir, "B") && is.finite(stop) && is.finite(target) && stop >= target) out <- c(out, "For a buy the stop must be below the target.")
  out
}

# ---- what is still missing in the decision -----------------------------------------------------------
tr_dec_gaps <- function(d) {
  out <- character(0); blank <- function(x) is.null(x) || !length(x) || is.na(x[1]) || !nzchar(trimws(as.character(x[1])))
  if (identical(d$direction, "N")) { if (blank(d$no_trade_reason)) out <- c(out, "Reason for not trading"); return(out) }
  for (p in list(c("setup_fundamental", "Set-up (fundamental)"), c("setup_technical", "Set-up (technical)"), c("trigger_text", "Trigger"), c("execution_text", "Execution"),
                 c("stop_reason", "Reason for Stop Loss placement"), c("target_reason", "Reason for Target Limit placement"))) if (blank(d[[p[1]]])) out <- c(out, p[2])
  if (blank(d$chart_period)) out <- c(out, "Chart period(s) used")
  if (!is.finite(suppressWarnings(as.numeric(d$expected_duration_hours)))) out <- c(out, "Expected trade duration")
  if (!is.finite(suppressWarnings(as.numeric(d$ig_price)))) out <- c(out, "IG price (levels are not aligned to IG without it)")
  out
}

# ---- an Individual Trade Sheet for an order that never filled -----------------------------------------
# d: the decision (list from confirmed_json); pics: data.frame(slot, caption, path); outcome: lines describing what happened
tr_no_fill_sheet_docx <- function(d, name, pics, file, outcome = character(0)) {
  num <- function(x) suppressWarnings(as.numeric(tr_or(x, NA)))
  et <- tryCatch(as.POSIXct(d$order_time %||% d$saved_at_uk, tz = "Europe/London"), error = function(e) as.POSIXct(NA))
  tr <- data.frame(trade_id = d$decision_id %||% "ORDER", asset = d$asset %||% "BRENT", direction = d$direction, chart_period = tr_or(d$chart_period, NA),
                   expected_duration_hours = num(d$expected_duration_hours), pip_size = 1, stake_per_pip_gbp = num(d$size), entry_ts = et,
                   entry_price = num(d$entry), stop1 = num(d$stop), target = num(d$target), initial_risk_pips = num(d$stop_pts), initial_reward_pips = num(d$target_pts),
                   initial_rrr = num(d$target_pts) / num(d$stop_pts), initial_risk_gbp = num(d$stop_pts) * num(d$size), status = "OPEN",
                   setup_fundamental = tr_or(d$setup_fundamental, NA), setup_technical = tr_or(d$setup_technical, NA), trigger_text = tr_or(d$trigger_text, NA),
                   execution_text = tr_or(d$execution_text, NA), stop_reason = tr_or(d$stop_reason, NA), target_reason = tr_or(d$target_reason, NA),
                   exit_code = NA, reason_for_exit = NA, lessons_learned = tr_or(d$lessons_learned, NA), stringsAsFactors = FALSE)
  tr_trade_sheet_docx(tr, tr[0, ], NULL, name, pics, file)
  tp <- tr_tpl_open(file); tb <- tr_tpl_tables(tp)
  tr_tpl_set(tr_tpl_cell(tb[[3]], 2, 2), paste0(if (is.na(et)) "" else tr_hhmm(et), " (order)"))
  tr_tpl_set(tr_tpl_cell(tb[[3]], 2, 6), sprintf("%s (%s)", tr_ntrim(num(d$entry)), tolower(tr_or(d$entry_type_label, "order"))))
  tr_tpl_fill_items(tp, tr_tpl_find_par(tp, "Not applicable: the stop", 1),
                    c(list(list(type = "caption", value = "ORDER NOT FILLED: no position was opened.")), lapply(outcome, function(x) list(type = "text", value = x))))
  tr_tpl_set(tr_tpl_cell(tb[[5]], 1, 2), "n/a: order not filled")
  tr_tpl_set(tr_tpl_cell(tb[[6]], 1, 2), trimws(paste("No exit: the order was not filled.", tr_or(d$reason_for_exit, ""))))
  tr_tpl_save(tp, file)
}

# ---- a chart of the order window for the no-fill sheet ------------------------------------------------
tr_dec_order_chart_png <- function(bars, d, placed, expiry, file = tempfile(fileext = ".png"), after_hours = 5) {
  num <- function(x) suppressWarnings(as.numeric(tr_or(x, NA)))
  if (is.null(bars) || !nrow(bars) || is.na(placed)) return(NULL)
  placed <- tr_dec_utc(placed); expiry <- tr_dec_utc(expiry)
  to <- (if (is.na(expiry)) placed + 8 * 3600 else expiry) + after_hours * 3600
  b <- bars[bars$time >= placed - 6 * 3600 & bars$time <= to, , drop = FALSE]; if (nrow(b) < 5) return(NULL)
  lv <- c(num(d$entry), num(d$stop), num(d$target)); yl <- range(c(b$low, b$high, lv), na.rm = TRUE); yl <- yl + c(-1, 1) * diff(yl) * 0.04
  grDevices::png(file, width = 1600, height = 900, res = 170); on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(4, 4.8, 4.2, 1), las = 1, cex = 0.8); x <- as.numeric(b$time); w <- 900 * 0.35
  graphics::plot(range(x), yl, type = "n", xaxt = "n", xlab = "UK time", ylab = "Price (IG points)")
  graphics::title(sprintf("%s, 15 minute bars (Yahoo, aligned to the IG price %s)", tr_asset_label(d$asset %||% "BRENT"), tr_ntrim(num(d$ig_price))), line = 2.6)
  tk <- pretty(b$time, n = 8); graphics::axis(1, at = as.numeric(tk), labels = format(tk, "%d/%m %H:%M", tz = "Europe/London"))
  up <- b$close >= b$open; graphics::segments(x, b$low, x, b$high, col = "grey35")
  graphics::rect(x - w, pmin(b$open, b$close), x + w, pmax(b$open, b$close), col = ifelse(up, "#15803d", "#b91c1c"), border = NA)
  graphics::abline(h = num(d$entry), col = "#1d4ed8", lwd = 2); graphics::abline(h = num(d$stop), col = "#b91c1c", lwd = 2, lty = 2); graphics::abline(h = num(d$target), col = "#15803d", lwd = 2, lty = 2)
  graphics::abline(v = as.numeric(placed), col = "#1d4ed8", lty = 3); if (!is.na(expiry)) graphics::abline(v = as.numeric(expiry), col = "#111827", lty = 3)
  graphics::legend("top", inset = c(0, -0.085), xpd = TRUE, horiz = TRUE, bty = "n", cex = 0.85, lwd = 2, lty = c(1, 2, 2, 3), col = c("#1d4ed8", "#b91c1c", "#15803d", "#111827"),
                   legend = c(sprintf("Order %s", tr_ntrim(num(d$entry))), sprintf("Stop %s", tr_ntrim(num(d$stop))), sprintf("Target %s", tr_ntrim(num(d$target))), "placed / expiry"))
  list(file = file, caption = sprintf("%s 15 Min chart around the %s order, %s (own work from Yahoo Finance data aligned to the IG price; IG's own chart may differ slightly)",
                                      tr_asset_label(d$asset %||% "BRENT"), tolower(tr_or(d$entry_type_label, "entry")), format(placed, "%d/%m/%Y", tz = "Europe/London")))
}

# ---- decisions kept in trading_evidence (kind decision_snapshot / no_trade; confirmed_json holds the decision) -----
tr_dec_kinds <- c("decision_snapshot", "no_trade")
tr_dec_from_evidence <- function(ev) {
  empty <- data.frame(decision_id = character(0), record_version = integer(0), saved_at = as.POSIXct(character(0)), status = character(0), trade_id = character(0),
                      asset = character(0), direction = character(0), order_type = character(0), entry = numeric(0), stop = numeric(0), target = numeric(0),
                      size = numeric(0), expiry = character(0), first_saved_uk = character(0), warnings = integer(0), stringsAsFactors = FALSE)
  if (is.null(ev) || !nrow(ev)) return(empty)
  e <- ev[!is.na(ev$kind) & ev$kind %in% tr_dec_kinds, , drop = FALSE]; if (!nrow(e)) return(empty)
  rows <- lapply(seq_len(nrow(e)), function(i) { d <- tr_dec_parse(e$confirmed_json[i]); n <- function(k) suppressWarnings(as.numeric(tr_or(d[[k]], NA)))
    data.frame(decision_id = e$evidence_id[i], record_version = as.integer(tr_or(e$record_version[i], 1L)), saved_at = e$saved_at[i], status = tr_or(e$status[i], NA_character_),
               trade_id = tr_or(e$trade_id[i], NA_character_), asset = tr_or(d$asset, NA_character_), direction = tr_or(d$direction, NA_character_),
               order_type = tr_or(d$order_type, NA_character_), entry = n("entry"), stop = n("stop"), target = n("target"), size = n("size"),
               expiry = tr_or(d$expiry_uk, NA_character_), first_saved_uk = tr_or(d$first_saved_uk, tr_or(d$saved_at_uk, NA_character_)),
               warnings = length(d$facts$warnings), stringsAsFactors = FALSE) })
  out <- do.call(rbind, rows); out[order(out$first_saved_uk, decreasing = TRUE), , drop = FALSE]
}
tr_dec_parse <- function(js) { if (is.null(js) || is.na(js) || !nzchar(js)) return(list()); tryCatch(jsonlite::fromJSON(js, simplifyVector = TRUE), error = function(e) list()) }
tr_dec_get <- function(ev, id) { r <- ev[ev$evidence_id == id, , drop = FALSE]; if (!nrow(r)) return(NULL); r <- r[which.max(r$record_version), , drop = FALSE]; d <- tr_dec_parse(r$confirmed_json); d$decision_id <- id; d$status <- r$status; d$record_version <- r$record_version; d }
# a new version of a decision row (append-only: the earlier versions stay in BigQuery)
tr_dec_ev_row <- function(id, version, status, d, trade_id = NA_character_, notes = NA_character_) {
  w <- d$facts$warnings; data.frame(evidence_id = id, record_version = as.integer(version), kind = if (identical(d$direction, "N")) "no_trade" else "decision_snapshot", status = status,
    trade_id = tr_or(trade_id, NA_character_), confirmed_json = as.character(jsonlite::toJSON(d, auto_unbox = TRUE, null = "null", na = "null", digits = NA, POSIXt = "ISO8601")),
    checks_json = if (length(w)) as.character(jsonlite::toJSON(w)) else NA_character_, user_notes = tr_or(notes, NA_character_), screen_type = "decision",
    asset_code = tr_or(d$asset, NA_character_), stringsAsFactors = FALSE)
}
# The PLANNED decision a newly saved trade most likely came from: same asset and direction, saved the same UK day before the
# entry (5 minutes' grace), entry within `tol` points (default: 0.5% of the price). Latest one wins.
tr_dec_match <- function(dec, asset, dir, entry, ts, tol = NA_real_) {
  if (is.null(dec) || !nrow(dec) || is.na(ts) || !is.finite(entry)) return(NULL)
  tol <- if (is.finite(tol)) tol else 0.005 * abs(entry)
  first <- as.POSIXct(dec$first_saved_uk, tz = "Europe/London", format = "%Y-%m-%d %H:%M")
  m <- dec$status %in% "PLANNED" & toupper(dec$asset) == toupper(asset) & dec$direction == dir & is.finite(dec$entry) & abs(dec$entry - entry) <= tol &
       !is.na(first) & as.Date(format(first, "%Y-%m-%d", tz = "Europe/London")) == as.Date(format(ts, "%Y-%m-%d", tz = "Europe/London")) & as.numeric(first) <= as.numeric(ts) + 300
  m <- dec[m, , drop = FALSE]; if (!nrow(m)) return(NULL); m[order(m$first_saved_uk, decreasing = TRUE), , drop = FALSE][1, ]
}
tr_dec_text_fields <- c("setup_fundamental", "setup_technical", "trigger_text", "execution_text", "stop_reason", "target_reason")
# copy the student's OWN pre-trade words into the trade's empty boxes (never over anything already typed)
tr_dec_fill_trade <- function(row, d) {
  for (f in tr_dec_text_fields) { v <- d[[f]]; if ((is.null(row[[f]]) || is.na(row[[f]]) || !nzchar(trimws(row[[f]]))) && !is.null(v) && !is.na(v) && nzchar(trimws(v))) row[[f]] <- v }
  if (is.na(tr_or(row$chart_period, NA)) && !is.null(d$chart_period)) row$chart_period <- d$chart_period
  if (!is.finite(suppressWarnings(as.numeric(row$expected_duration_hours))) && is.finite(suppressWarnings(as.numeric(tr_or(d$expected_duration_hours, NA))))) row$expected_duration_hours <- as.numeric(d$expected_duration_hours)
  row$notes <- trimws(paste(stats::na.omit(c(if (!is.na(tr_or(row$notes, NA))) row$notes, paste0("DECISION:", d$decision_id))), collapse = " "))
  row
}

# ---- neutral facts for each of the six boxes ------------------------------------------------------------
# ctx: list(price, aligned, levels, noise, regime15, regime60, cal, clock, sheet (Morning Sheet row), headlines)
tr_dec_box_facts <- function(ctx, d) {
  f <- function(x) tr_ntrim(round(x, 1)); px <- ctx$price; out <- list()
  sh <- ctx$sheet; num <- function(x) suppressWarnings(as.numeric(tr_or(x, NA)))
  ev <- ctx$cal$events
  out$setup_fundamental <- c(
    if (!is.null(ev) && nrow(ev)) sprintf("Today's calendar (Morning Sheet): %d event(s), %d high importance, %d oil-related.", nrow(ev), sum(ev$importance == "High"), sum(ev$oil)) else "No calendar for today on the Morning Sheet.",
    if (!is.null(ctx$cal$next_high)) sprintf("Next high-importance release: %s %s at %s UK (in %d min).", ctx$cal$next_high$country, ctx$cal$next_high$event, ctx$cal$next_high$time, round(ctx$cal$minutes_to_next_high)),
    if (!is.null(sh) && !is.na(tr_or(sh$overnight_news, NA))) sprintf("Overnight news on your Morning Sheet: %d line(s).", length(strsplit(sh$overnight_news, "\n")[[1]])),
    if (!is.null(sh) && is.finite(num(sh$dow_change_pct))) sprintf("Dow %+.2f%%, Nikkei %+.2f%% (Morning Sheet).", num(sh$dow_change_pct), tr_or(num(sh$nikkei_change_pct), NA)))
  nb <- if (is.finite(px)) tr_dec_nearest(ctx$levels, px) else list()
  out$setup_technical <- c(
    if (!is.null(ctx$regime15) && is.finite(ctx$regime15$adx)) sprintf("ADX(14) on 15-min bars: %.1f, %s; %s.", ctx$regime15$adx, ctx$regime15$label, ctx$regime15$direction),
    if (!is.null(ctx$regime60) && is.finite(ctx$regime60$adx)) sprintf("ADX(14) on 1-hour bars: %.1f, %s.", ctx$regime60$adx, ctx$regime60$label),
    if (!is.null(nb$above)) sprintf("Nearest level above %s: %s at %s (%s pts).", f(px), nb$above$name, f(nb$above$level), f(nb$above$level - px)),
    if (!is.null(nb$below)) sprintf("Nearest level below %s: %s at %s (%s pts).", f(px), nb$below$name, f(nb$below$level), f(px - nb$below$level)),
    if (!is.null(sh) && !is.na(tr_or(sh$planned_setups, NA))) "Your Morning Sheet has planned set-ups written for today.")
  out$trigger_text <- c(if (!is.null(ctx$noise) && is.finite(ctx$noise$atr15)) sprintf("Average 15-min bar range (ATR 14): %s pts.", f(ctx$noise$atr15)))
  out$execution_text <- c(
    if (is.finite(num(d$spread))) sprintf("IG spread: %s pts.", f(num(d$spread))),
    if (is.finite(num(d$min_size))) sprintf("IG minimum size: %s per point.", format(num(d$min_size))),
    if (!is.na(tr_or(d$order_type, NA))) sprintf("Order type chosen: %s%s.", d$order_type, if (!is.na(tr_or(d$expiry_uk, NA)) && nzchar(d$expiry_uk)) paste(", good till", d$expiry_uk) else ""),
    ctx$clock$lines)
  sc <- if (all(is.finite(c(num(d$entry), num(d$stop))))) tr_dec_stop_check(num(d$entry), num(d$stop), d$direction, ctx$levels, ctx$noise$atr15) else NULL
  out$stop_reason <- c(
    if (!is.null(sc)) sprintf("Stop is %s pts from the entry%s.", f(sc$stop_pts), if (is.finite(sc$atr_multiple)) sprintf(" (%.1f x the 15-min ATR)", sc$atr_multiple) else ""),
    if (!is.null(sc) && !is.null(sc$nearest)) sprintf("Nearest level on the stop side: %s at %s; the stop is %s pts %s it.", sc$nearest$name, f(sc$nearest$level), f(abs(sc$beyond_nearest)), if (sc$beyond_nearest > 0) "beyond" else "short of"),
    if (!is.null(sc) && nrow(sc$between)) sprintf("Levels between the entry and the stop: %s.", paste(sprintf("%s %s", sc$between$name, f(sc$between$level)), collapse = "; ")),
    if (!is.null(ctx$noise) && is.finite(ctx$noise$range3h)) sprintf("Typical 3-hour range (last %d sessions): %s pts.", ctx$noise$days, f(ctx$noise$range3h)))
  tc <- if (all(is.finite(c(num(d$entry), num(d$target))))) tr_dec_target_check(num(d$entry), num(d$target), d$direction, ctx$levels, if (!is.null(sc)) sc$stop_pts else NA) else NULL
  out$target_reason <- c(
    if (!is.null(tc)) sprintf("Target is %s pts from the entry (RRR %.2f).", f(tc$reward_pts), tc$rrr),
    if (!is.null(tc) && nrow(tc$must_pass)) sprintf("Levels price must pass to reach the target: %s.", paste(sprintf("%s %s", utils::head(tc$must_pass$name, 5), f(utils::head(tc$must_pass$level, 5))), collapse = "; ")),
    if (!is.null(ctx$noise) && is.finite(ctx$noise$day_range)) sprintf("Average day range (last %d sessions): %s pts.", ctx$noise$days, f(ctx$noise$day_range)))
  lapply(out, function(x) x[!is.na(x) & nzchar(x)])
}

# Levels the student wrote on the Morning Sheet (IG prices) replace the computed ones of the same group.
tr_dec_sheet_levels <- function(lv) {
  if (is.null(lv) || !nrow(lv)) return(NULL); r <- lv[1, ]; out <- list(); t0 <- as.POSIXct(NA)
  add <- function(nm, v, g) if (length(v) && is.finite(v)) out[[length(out) + 1]] <<- data.frame(name = nm, level = v, time = t0, group = g, stringsAsFactors = FALSE)
  add("Previous session high (Morning Sheet)", r$prior_high, "session"); add("Previous session low (Morning Sheet)", r$prior_low, "session"); add("Previous session close (Morning Sheet)", r$prior_close, "session")
  for (p in c("pp", "r1", "r2", "r3", "s1", "s2", "s3")) add(paste0(toupper(p), " (Morning Sheet)"), r[[paste0("pivot_", p)]], "pivot")
  add("Overnight high (Morning Sheet)", r$overnight_high, "overnight"); add("Overnight low (Morning Sheet)", r$overnight_low, "overnight")
  if (!length(out)) NULL else do.call(rbind, out)
}
tr_dec_merge_levels <- function(computed, sheet) {
  if (is.null(sheet) || !nrow(sheet)) return(computed)
  keep <- if (is.null(computed) || !nrow(computed)) NULL else computed[!(computed$group %in% unique(sheet$group)), , drop = FALSE]
  d <- rbind(keep, sheet); d <- d[order(-d$level), , drop = FALSE]
  cl <- cumsum(c(TRUE, abs(diff(d$level)) >= 0.5))
  m <- do.call(rbind, lapply(split(seq_len(nrow(d)), cl), function(ix) { r <- d[ix[1], , drop = FALSE]; r$name <- paste(unique(d$name[ix]), collapse = " = "); r }))
  rownames(m) <- NULL; m
}
tr_dec_nofill_filename <- function(asset, day, ext = "docx") sub(paste0("\\.", ext, "$"), paste0("_order_not_filled.", ext), tr_trade_filename(asset, day, ext))

# Link a decision to the trade it became: new LINKED version of the decision, its screenshots move to the trade,
# and (fill = TRUE) the trade's EMPTY text boxes get the student's own pre-trade words (new trade version).
tr_dec_link <- function(store, d, trade_id, fill = TRUE) {
  ev <- tr_read_current(store, "evidence")
  store$write("evidence", tr_dec_ev_row(d$decision_id, as.integer(tr_or(d$record_version, 1L)) + 1L, "LINKED", d[setdiff(names(d), c("status", "record_version"))], trade_id))
  p <- ev[!is.na(ev$kind) & ev$kind == "picture" & !is.na(ev$trade_id) & ev$trade_id == d$decision_id, , drop = FALSE]
  if (nrow(p)) { p$record_version <- as.integer(tr_or(p$record_version, 1L)) + 1L; p$trade_id <- trade_id; store$write("evidence", p) }
  if (fill) { t <- tr_read_current(store, "trades"); r <- t[t$trade_id == trade_id, , drop = FALSE]
    if (nrow(r) == 1) { r2 <- tr_dec_fill_trade(r, d); r2$record_version <- as.integer(tr_or(r$record_version, 1L)) + 1L; store$write("trades", r2) } }
  invisible(TRUE)
}

# When did a limit / stop order most likely fill? Yahoo 15-min bars aligned to the IG ticket's mid price at the time the
# ticket screenshot was taken. Returns list(time = "HH:MM", ts, note) or NULL. Always an ESTIMATE (the sheet marks it so).
tr_estimate_fill_time <- function(asset, dir, order_type, level, placed, mid, spread = NA_real_, until = Sys.time(), fetch = tr_yahoo_fetch) {
  sym <- unname(tr_yahoo_symbols[toupper(tr_or(asset, ""))]); if (is.na(sym) || !is.finite(level) || is.na(placed) || !(order_type %in% c("limit", "stop"))) return(NULL)
  p <- tryCatch(fetch(sym, "5d", "15m"), error = function(e) NULL); if (is.null(p) || !nrow(p$bars)) return(NULL)
  before <- p$bars[as.numeric(p$bars$time) <= as.numeric(placed), , drop = FALSE]; if (!nrow(before)) return(NULL)
  a <- tr_dec_align(list(bars = before, tz = p$tz), if (is.finite(mid)) mid else NA_real_, asset)
  b <- tr_dec_align_with(p, a$k, a$off)$bars
  o <- tr_dec_order_outcome(b, dir, order_type, level, placed, as.POSIXct(NA), if (is.finite(spread)) spread / 2 else 0, now = until)
  if (is.null(o) || !identical(o$status, "FILLED_LIKELY")) return(NULL)
  t <- o$fill_time + 0; list(time = format(t, "%H:%M", tz = "Europe/London"), ts = t,
       note = sprintf("Entry time estimated: the first 15-min bar after %s UK in which Yahoo prices (aligned to the IG ticket quote) reached %s. Confirm with IG History > Activity.",
                      format(placed, "%H:%M", tz = "Europe/London"), tr_ntrim(level)))
}
