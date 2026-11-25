# R/utils_cc_advice.R - prices rounded to the market's decimals, order checks, Capital.com error codes in plain words,
# the measured chance that a target is reached before a stop, today's Morning Sheet (from BigQuery) as text, and
# Claude's suggested trades (prompt + checked parse). Used by modules/cc_trading_records.R (T Records C.C).

# ---- prices -----------------------------------------------------------------------------------------------------
# decimals of the market's quotes: Capital.com's decimalPlacesFactor, else the most decimals seen in bid / offer
cc_px_decimals <- function(f) {
  d <- suppressWarnings(as.integer(f$decimals %||% NA))
  if (length(d) == 1 && !is.na(d) && d >= 0 && d <= 6) return(d)
  v <- c(f$bid, f$offer); v <- v[is.finite(v)]; if (!length(v)) return(5L)
  max(vapply(v, function(x) { s <- sub("0+$", "", formatC(x, format = "f", digits = 6)); if (grepl("\\.", s)) nchar(sub("^[^.]*\\.", "", s)) else 0L }, 0L))
}
cc_round_px <- function(x, d) ifelse(is.finite(x), round(x, d), x)
cc_fmt_px <- function(x, d) ifelse(is.finite(x), formatC(x, format = "f", digits = d), "-")
# a level and its distance from the price now, e.g. "106.068" and "+0.659 (+0.62%)"
cc_vs_now <- function(x, now, d) ifelse(is.finite(x) & is.finite(now), sprintf("%s%s (%s%.2f%%)", ifelse(x - now >= 0, "+", "-"), formatC(abs(x - now), format = "f", digits = d),
                                                                                ifelse(x - now >= 0, "+", "-"), abs(100 * (x - now) / now)), "-")

# ---- order checks before sending --------------------------------------------------------------------------------
# side rules: BUY LIMIT and SELL STOP below the price; SELL LIMIT and BUY STOP above it. Returns character(0) if fine.
cc_order_problems <- function(direction, type, level, stop, target, bid, offer, min_dist = NA, atr = NA) {
  out <- character(0); d <- if (toupper(direction) == "BUY") 1 else -1; type <- toupper(type)
  px <- if (d > 0) offer else bid
  if (type %in% c("LIMIT", "STOP")) {
    if (!is.finite(level)) return("Type the entry level for a limit or stop order.")
    need_above <- (type == "LIMIT" && d < 0) || (type == "STOP" && d > 0)
    if (need_above && !(level > px)) out <- c(out, sprintf("A %s %s order must be ABOVE the price now (%s); %s is not.", toupper(direction), tolower(type), px, level))
    if (!need_above && !(level < px)) out <- c(out, sprintf("A %s %s order must be BELOW the price now (%s); %s is not.", toupper(direction), tolower(type), px, level))
    if (is.finite(min_dist) && abs(level - px) < min_dist) out <- c(out, sprintf("The entry is %s from the price; Capital.com's minimum is %s.", signif(abs(level - px), 4), min_dist))
  }
  e <- if (type == "MARKET") px else level
  if (is.finite(stop) && is.finite(e) && !(d * (e - stop) > 0)) out <- c(out, "The stop is on the wrong side of the entry.")
  if (is.finite(target) && is.finite(e) && !(d * (target - e) > 0)) out <- c(out, "The target is on the wrong side of the entry.")
  if (is.finite(min_dist) && is.finite(stop) && is.finite(e) && abs(e - stop) < min_dist) out <- c(out, sprintf("The stop is closer than Capital.com's minimum distance %s.", min_dist))
  out
}
# a market order is sent at the price of that moment: the stop and the target keep their DISTANCES from the entry
cc_shift_levels <- function(entry_planned, entry_now, stop, target, d) {
  dl <- if (is.finite(entry_planned) && is.finite(entry_now)) entry_now - entry_planned else 0
  list(shift = dl, stop = if (is.finite(stop)) round(stop + dl, d) else stop, target = if (is.finite(target)) round(target + dl, d) else target)
}
# Capital.com error codes in plain words
cc_explain_error <- function(msg) {
  m <- as.character(msg %||% ""); tips <- c(
    "error.validation.limit.price" = "Capital.com refused the order's entry price. Usual causes: more decimals than the market quotes, the wrong side of the price for this order type, or too close to the price.",
    "error.invalid.stoploss.minvalue" = "The stop is too close to the price (below Capital.com's minimum distance).",
    "error.invalid.stoploss.maxvalue" = "The stop is too far from the price.",
    "error.invalid.takeprofit.minvalue" = "The target is too close to the price.",
    "error.invalid.takeprofit.maxvalue" = "The target is too far from the price.",
    "error.invalid.size.minvalue" = "The size is below the market's minimum.",
    "error.not-enough.funds" = "Not enough available funds for the margin.",
    "error.invalid.daterange" = "Capital.com refused the dates asked for.",
    "error.too-many.requests" = "Too many requests: wait a few seconds and try again.")
  hit <- names(tips)[vapply(names(tips), function(k) grepl(k, m, fixed = TRUE), TRUE)]
  if (length(hit)) paste0(tips[[hit[1]]], " (", hit[1], ")") else m
}

# ---- measured chance: target before stop -----------------------------------------------------------------------
# From every candle close in the history (as if entering there), how often price moved the target distance in the
# trade's direction before it moved the stop distance against it, within `horizon` candles. Both in one candle counts
# as the stop (cautious). Returns list(p = % target first among decided, n = decided, undecided = % with neither).
cc_touch_prob <- function(h, l, c, dir, stop_d, tgt_d, horizon = 40L, last = length(c)) {
  if (!is.finite(stop_d) || !is.finite(tgt_d) || stop_d <= 0 || tgt_d <= 0) return(list(p = NA_real_, n = 0L, undecided = NA_real_))
  n <- min(last, length(c)); starts <- seq_len(max(0, n - 1L)); win <- 0L; loss <- 0L; none <- 0L
  for (i in starts) { j <- (i + 1L):min(n, i + horizon); if (j[1] > n) break
    fav <- if (dir > 0) h[j] - c[i] else c[i] - l[j]; adv <- if (dir > 0) c[i] - l[j] else h[j] - c[i]
    t_hit <- which(fav >= tgt_d)[1]; s_hit <- which(adv >= stop_d)[1]
    if (is.na(t_hit) && is.na(s_hit)) { if (i + horizon <= n) none <- none + 1L; next }
    if (!is.na(s_hit) && (is.na(t_hit) || s_hit <= t_hit)) loss <- loss + 1L else win <- win + 1L }
  dec <- win + loss
  list(p = if (dec) 100 * win / dec else NA_real_, n = dec, undecided = if (dec + none) 100 * none / (dec + none) else NA_real_)
}
cc_prob_text <- function(p, n, und, hours) ifelse(is.finite(p) & n > 0, sprintf("%.0f%% (n=%d; %.0f%% reached neither within %s h)", p, n, und, format(hours)), "not enough history")

# ---- today's Morning Sheet from BigQuery (Trading Records > 2. Morning Sheet) -----------------------------------
# sheets / levels: current rows of trading_morning_sheets / trading_morning_levels. Returns NULL when there is no
# sheet for `day`, else list(sheet_id, saved_at, text).
cc_morning_sheet <- function(sheets, levels, day) {
  if (is.null(sheets) || !nrow(sheets)) return(NULL)
  s <- sheets[!is.na(sheets$sheet_date) & as.Date(sheets$sheet_date) == as.Date(day), , drop = FALSE]; if (!nrow(s)) return(NULL)
  s <- s[order(s$saved_at), , drop = FALSE]; s <- s[nrow(s), , drop = FALSE]
  v <- function(k) { x <- s[[k]]; if (is.null(x) || !length(x) || is.na(x[1]) || !nzchar(trimws(as.character(x[1])))) "" else trimws(as.character(x[1])) }
  num <- function(x, k = 2) { x <- suppressWarnings(as.numeric(x)); out <- rep("-", length(x)); ok <- is.finite(x)   # works for one value or many (7 markets)
    out[ok] <- vapply(x[ok], function(v) format(round(v, k), big.mark = ",", scientific = FALSE), ""); out }
  lv <- if (!is.null(levels) && nrow(levels)) levels[levels$sheet_id %in% s$sheet_id, , drop = FALSE] else NULL
  lv_txt <- if (!is.null(lv) && nrow(lv)) { lv <- lv[order(lv$saved_at), , drop = FALSE]; lv <- lv[!duplicated(lv$instrument, fromLast = TRUE), , drop = FALSE]
    paste(sprintf("- %s: overnight low %s, high %s, now %s at %s%s%s", lv$instrument, num(lv$overnight_low, 4), num(lv$overnight_high, 4), num(lv$current_price, 4),
                  ifelse(is.na(lv$time_now_uk), "-", lv$time_now_uk), ifelse(is.finite(suppressWarnings(as.numeric(lv$adx14))), sprintf(", ADX %s", round(suppressWarnings(as.numeric(lv$adx14)), 1)), ""),
                  ifelse(!is.na(lv$regime_label) & nzchar(lv$regime_label), paste0(", ", lv$regime_label), "")), collapse = "\n") } else "(no levels saved)"
  txt <- paste0("MORNING SHEET ", format(as.Date(day), "%d/%m/%Y"), " (written by the student before trading; IG quotes oil in cents, e.g. Brent 10579 = 105.79 USD)\n",
    "Dow Jones: ", num(s$dow_price), " (", num(s$dow_change_pct), "%); Nikkei: ", num(s$nikkei_price), " (", num(s$nikkei_change_pct), "%)\n",
    "Overnight levels:\n", lv_txt, "\n",
    "Overnight news:\n", if (nzchar(v("overnight_news"))) v("overnight_news") else "(none written)", "\n",
    "Yesterday's / overnight releases:\n", if (nzchar(v("overnight_calendar"))) v("overnight_calendar") else "(none)", "\n",
    "Today's releases:\n", if (nzchar(v("todays_releases"))) v("todays_releases") else "(none)", "\n",
    "Releases inside the planned trading window:\n", if (nzchar(v("releases_in_window"))) v("releases_in_window") else "(none)", "\n",
    if (nzchar(v("regime_summary"))) paste0("Regime notes: ", v("regime_summary"), "\n") else "",
    if (nzchar(v("planned_setups"))) paste0("Planned set-ups: ", v("planned_setups"), "\n") else "",
    if (isTRUE(as.logical(s$stand_aside[1]))) paste0("STAND ASIDE today: ", v("stand_aside_reason"), "\n") else "")
  list(sheet_id = s$sheet_id, saved_at = s$saved_at, text = txt, releases = v("todays_releases"), news = v("overnight_news"), window = v("releases_in_window"), regime = v("regime_summary"),
       planned = v("planned_setups"), stand = if (isTRUE(as.logical(s$stand_aside[1]))) if (nzchar(v("stand_aside_reason"))) v("stand_aside_reason") else "yes" else "")
}

# ---- Claude's suggested trades ----------------------------------------------------------------------------------
cc_suggest_prompt <- function(scan, f, scen, plan, morning = NULL, now = Sys.time(), history = NULL) {
  ctx <- scan$ctx; n <- ctx$n; d <- cc_px_decimals(f); k <- max(1, n - 39):n
  bars <- paste(sprintf("%s %s %s %s %s", format(ctx$b$time[k], "%d/%m %H:%M", tz = "Europe/London"), cc_fmt_px(ctx$o[k], d), cc_fmt_px(ctx$h[k], d), cc_fmt_px(ctx$l[k], d), cc_fmt_px(ctx$c[k], d)), collapse = "\n")
  cd <- scan$current_df
  pats <- if (is.null(cd) || !nrow(cd)) "(none)" else paste(sprintf("- %s [%s%s]: cancels beyond %s, target %s; record %s", cd$label, ifelse(is.na(cd$dir), "context", ifelse(cd$dir > 0, "bullish", "bearish")),
    ifelse(cd$in_regime, "", ", outside regime"), cc_fmt_px(cd$invalid, d), cc_fmt_px(cd$target, d),
    ifelse(cd$hist_n >= 1, sprintf("target first %s%% n=%d", ifelse(is.finite(cd$hist_win), round(cd$hist_win), "-"), cd$hist_n), "none")), collapse = "\n")
  sc <- if (is.null(scen) || !nrow(scen)) "(none)" else paste(sprintf("%s: entry %s, stop %s, target %s, R:R %s%s", scen$id, cc_fmt_px(scen$entry, d), cc_fmt_px(scen$stop, d), cc_fmt_px(scen$target, d), round(scen$rrr, 2),
    if (is.null(scen$score)) "" else sprintf("; app score %s/100 (%s); measured chance of target first %s%%", scen$score, scen$score_why, scen$chance), if (is.null(scen$setup4)) "" else paste0("; course set-up type: ", scen$setup4)), collapse = "\n")
  paste0(
    "You help a trading student on a DEMO account plan intraday trades on ", f$name %||% f$epic, " (Capital.com ", f$epic, ", quoted in ", f$currency %||% "", " with ", d, " decimals). ",
    "Time now ", format(now, "%d/%m/%Y %H:%M", tz = "Europe/London"), " UK. Price now: bid ", cc_fmt_px(f$bid, d), ", offer ", cc_fmt_px(f$offer, d), ". ",
    "Capital.com minimum stop distance ", f$min_stop_distance %||% "-", "; deal size minimum ", f$min_size %||% "-", ", step ", f$size_step %||% "-", ".\n",
    if (exists("cc_market_profile", mode = "function")) tryCatch(cc_profile_prompt(cc_market_profile(f$epic, f$name, f$type, f$currency), if (exists("cc_hours_text", mode = "function")) cc_hours_text(f$hours, now) else NULL), error = function(e) "") else "",
    "Chart: ", ctx$minutes, "-minute candles; ATR(14) ", cc_fmt_px(ctx$a[n], d), "; ADX(14) ", round(scan$adx %||% NA, 1), "; regime ", scan$regime, ".\n",
    "Student's plan: minimum reward:risk ", plan$min_rrr %||% "-", "; risk per trade ", plan$risk_pct %||% "-", "% of balance; holding up to ", plan$hold_h %||% "-", " hours.\n",
    if (length(plan$rules_text) && nzchar(plan$rules_text)) paste0("Student's trading plan rules and their state NOW (a trade that breaks a blocking rule cannot be sent, so prefer trades that pass them):\n", plan$rules_text, "\n") else "",
    "Patterns found now by rule (with their measured record on this market):\n", pats, "\n",
    "The app's rule-based scenarios (all are deals at the market; the score 0-100 combines the measured chance against break-even with trend, regime, news, confluence, stop width, spread and plan rules):\n", sc, "\n",
    if (length(scan$groups)) paste0("The student chose these course tools for this analysis: ", paste(scan$groups, collapse = ", "), ". Base your reasons on these tools only.\n") else "",
    "Last 40 candles (UK time, open high low close):\n", bars, "\n",
    if (!is.null(morning)) paste0("\n", morning, "\n") else "\nNo Morning Sheet is included.\n",
    if (!is.null(history) && nzchar(history)) paste0("\nTHE STUDENT'S OWN TRADES OF THE PREVIOUS 4 WORKING DAYS AND TODAY (from BigQuery):\n", history,
      "\nFIRST evaluate these trades: what repeated mistake made them lose (for example stops inside normal noise or below 1 ATR, a stop on an obvious level such as the overnight low, R:R below the plan, trading against the higher time-frame or the Morning Sheet bias, size), ",
      "and what would have turned them into winners (for example moving the stop to break-even at +1R, a wider stop with a smaller size). Then make sure every trade you suggest avoids those mistakes. Put the evaluation in past_trades_review (3-6 short sentences, facts from the list only).\n") else "",
    "\nTASK: you MUST recommend a trade. Return 1 to 3 trades, best first: the FIRST trade in suggestions is your recommendation and the list is NEVER empty. ",
    "Use the price action, the patterns", if (!is.null(morning)) " and the Morning Sheet (news direction, releases inside the holding window, levels)" else "", ". ",
    "If conditions are poor (regime unclear, a release in the window, the Morning Sheet says no trade, weak records), still recommend the best available trade and put every caution in cautions; standing aside is NOT an answer. ",
    "RULES: every trade is a DEAL opened NOW at the market (BUY at the offer ", cc_fmt_px(f$offer, d), ", SELL at the bid ", cc_fmt_px(f$bid, d), "): no limit or stop entries, no waiting orders, so never base a trade on a straddle and never cite a straddle record. ",
    "Reward:risk = |target - entry| / |entry - stop| MUST be at least ", plan$min_rrr %||% 1.5, " (the student's minimum). ",
    "For each give: side BUY or SELL; type MARKET; entry = the offer for BUY, the bid for SELL; ",
    "stop and target as absolute prices with ", d, " decimals; the stop beyond a real level and at least about 1 ATR from the entry; ",
    "probability_pct = your estimate (0-100) that the target is reached before the stop; horizon_hours; why (max 2 short sentences, facts only); main_risk (1 short sentence). ",
    "Prefer, in this order: a trade that passes every plan rule marked FAILS now (blocking) above; then one with the set-up record above break-even; then the higher R:R. If every direction breaks a blocking rule, still recommend the better one and name the rule in cautions. ",
    "EVIDENCE RULE: the 'baseline' figure of a scenario is how often ANY trade with those distances reached its target first in this market, whatever the set-up; it is not a forecast. ",
    "Break-even = 100 / (1 + R:R) percent (40% at 1.5, 33% at 2.0); state it in 'why' with the evidence you used. ",
    "WRITING RULES: give the number of cases (n) with every record or rate you cite, and call any record with n below 30 weak; never draw a firm lesson from fewer than 10 trades; ",
    "when you cite ADX or a trend, say which reading it is (live ", ctx$minutes, "-minute chart, Morning Sheet, daily or 4-hour) and, if two readings disagree, say so once; do not repeat a point. ",
    "Also give probability_pct for each of the app's scenarios. ",
    "Reply with ONE JSON object only: {\"summary\":\"1-2 sentences\",\"morning_sheet_used\":true|false,\"cautions\":\"\",",
    "\"suggestions\":[{\"side\":\"SELL\",\"type\":\"MARKET\",\"entry\":0,\"stop\":0,\"target\":0,\"probability_pct\":0,\"horizon_hours\":0,\"why\":\"\",\"main_risk\":\"\"}],",
    "\"scenario_estimates\":[{\"id\":\"BUY MARKET\",\"probability_pct\":0}]", if (!is.null(history) && nzchar(history)) ",\"past_trades_review\":\"\"" else "", "}")
}
# parse Claude's reply into rows like cc_scenarios(); levels rounded; problems listed (not removed: the student sees why)
cc_suggest_parse <- function(txt, f, min_rrr = NA) {
  d <- cc_px_decimals(f)
  j <- tryCatch(jsonlite::fromJSON(sub("[^}]*$", "", sub("^[^{]*", "", txt)), simplifyVector = TRUE), error = function(e) NULL)
  if (is.null(j)) return(list(ok = FALSE, error = "Claude's reply could not be read.", rows = NULL, estimates = NULL, summary = ""))
  sg <- j$suggestions; rows <- NULL
  if (is.data.frame(sg) && nrow(sg)) {
    num <- function(k) if (k %in% names(sg)) suppressWarnings(as.numeric(sg[[k]])) else rep(NA_real_, nrow(sg))
    chr <- function(k) if (k %in% names(sg)) as.character(sg[[k]]) else rep("", nrow(sg))
    side <- toupper(chr("side")); type <- rep("MARKET", nrow(sg)); ok <- side %in% c("BUY", "SELL")   # deals only: any limit / stop entry becomes a deal now
    rows <- data.frame(id = paste("CLAUDE", seq_len(nrow(sg))), side = side, type = type, entry = cc_round_px(num("entry"), d), stop = cc_round_px(num("stop"), d), target = cc_round_px(num("target"), d),
                       note = paste0("Claude: ", chr("why")), basis = paste0("Main risk: ", chr("main_risk")), keys = "", claude_p = num("probability_pct"), horizon_h = num("horizon_hours"),
                       source = "Claude", stringsAsFactors = FALSE)[ok, , drop = FALSE]
    rows$entry[rows$side == "BUY"] <- f$offer; rows$entry[rows$side == "SELL"] <- f$bid
    # the minimum Reward:Risk is a rule: keep Claude's stop, move the target out to the minimum if needed (said in How); drop a trade with the stop on the wrong side
    if (nrow(rows)) { dir <- ifelse(rows$side == "BUY", 1, -1); risk <- dir * (rows$entry - rows$stop); rows <- rows[is.finite(risk) & risk > 0, , drop = FALSE]
      if (nrow(rows) && is.finite(min_rrr)) { dir <- ifelse(rows$side == "BUY", 1, -1); risk <- dir * (rows$entry - rows$stop); rw <- dir * (rows$target - rows$entry)
        low <- !is.finite(rw) | rw < min_rrr * risk - 1e-9
        rows$target[low] <- cc_round_px(rows$entry[low] + dir[low] * (min_rrr * risk[low] + 10^-d), d)
        rows$note[low] <- paste0(rows$note[low], sprintf(" (Target moved out to your minimum Reward:Risk %.2f.)", min_rrr)) } }
  }
  est <- j$scenario_estimates; est <- if (is.data.frame(est) && nrow(est) && all(c("id", "probability_pct") %in% names(est))) data.frame(id = as.character(est$id), claude_p = suppressWarnings(as.numeric(est$probability_pct)), stringsAsFactors = FALSE) else NULL
  list(ok = TRUE, rows = rows, estimates = est, summary = as.character(j$summary %||% ""), used_sheet = isTRUE(j$morning_sheet_used), stand_aside = as.character(j$cautions %||% j$stand_aside_reason %||% ""), past_review = paste(as.character(unlist(j$past_trades_review %||% "")), collapse = " "))
}

# ---- Yahoo as an alternative source of candles (futures / FX quotes; shifted onto Capital.com's price) -------------
# cc_yahoo_symbol(): R/utils_cc_markets.R (every asset class)
cc_yahoo_bars <- function(fetch, symbol, res, hist_days = 20) {
  iv <- c(MINUTE_5 = "5m", MINUTE_15 = "15m", MINUTE_30 = "30m", HOUR = "60m")[res]
  if (is.na(iv)) stop("Yahoo has no ", res, " candles: choose 5, 15 or 30 minutes or 1 hour.")
  rg <- if (iv == "5m") "1mo" else "60d"
  r <- fetch(symbol, rg, unname(iv)); b <- if (is.data.frame(r)) r else r$bars
  if (is.null(b) || !nrow(b)) stop("Yahoo returned no candles for ", symbol, ".")
  b <- b[is.finite(b$open) & is.finite(b$high) & is.finite(b$low) & is.finite(b$close), , drop = FALSE]
  b <- b[b$time >= max(b$time) - max(3, hist_days) * 86400, , drop = FALSE]; b[order(b$time), c("time", "open", "high", "low", "close")] }

# ---- ****** the trades of the previous working days (from BigQuery), for the AI to evaluate before suggesting ----------
cc_prev_workdays <- function(now, n = 4) { d <- as.Date(format(now, "%Y-%m-%d", tz = "Europe/London")); out <- as.Date(character(0)); k <- d
  while (length(out) < n) { k <- k - 1; if (!format(k, "%u") %in% c("6", "7")) out <- c(out, k) }; out }
cc_recent_trades <- function(trades, now, n_days = 4) {
  if (is.null(trades) || !nrow(trades)) return(trades[0, , drop = FALSE])
  t <- trades[!(trades$status %in% c("DUPLICATE", "CANCELLED", "REJECTED")) & !is.na(trades$status), , drop = FALSE]
  t0 <- ifelse(!is.na(t$entry_ts), as.numeric(t$entry_ts), as.numeric(t$placed_ts)); day <- as.Date(format(as.POSIXct(t0, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d", tz = "Europe/London"))
  keep <- !is.na(day) & (day %in% cc_prev_workdays(now, n_days) | day == as.Date(format(now, "%Y-%m-%d", tz = "Europe/London")))
  t <- t[keep, , drop = FALSE]; t[order(t0[keep]), , drop = FALSE]
}
cc_recent_trades_text <- function(t, atr = NA_real_) {
  if (is.null(t) || !nrow(t)) return("")
  num <- function(x) suppressWarnings(as.numeric(x)); g <- function(k) if (k %in% names(t)) t[[k]] else rep(NA, nrow(t))
  d <- ifelse(toupper(g("direction")) %in% c("BUY", "B"), 1, -1); en <- num(g("entry_level")); st <- num(g("stop_initial")); tg <- num(g("target_level")); ex <- num(g("exit_level"))
  risk <- d * (en - st); rew <- d * (tg - en); res <- d * (ex - en); r <- ifelse(is.finite(res) & risk > 0, res / risk, NA)
  pl <- ifelse(is.finite(num(g("pnl_account_booked"))), num(g("pnl_account_booked")), num(g("pnl_account_est")))
  t0 <- ifelse(!is.na(g("entry_ts")), as.numeric(g("entry_ts")), as.numeric(g("placed_ts"))); tt <- format(as.POSIXct(t0, origin = "1970-01-01", tz = "UTC"), "%a %d/%m %H:%M", tz = "Europe/London")
  dur <- ifelse(!is.na(g("exit_ts")) & is.finite(t0), round((as.numeric(g("exit_ts")) - t0) / 60), NA)
  cut <- function(x, n = 160) { x <- gsub("\\s+", " ", as.character(x)); ifelse(is.na(x) | !nzchar(x), "-", ifelse(nchar(x) > n, paste0(substr(x, 1, n), "..."), x)) }
  lines <- sprintf("- %s UK %s %s size %s: entry %s, stop %s (%.3f pts%s), target %s (R:R %s); %s%s; result %s R, %s acc; held %s min. Exit reason: %s. Lessons: %s",
    tt, ifelse(is.na(g("market_name")), g("epic"), g("market_name")), g("direction"), g("size"), en, st, risk, if (is.finite(atr) && atr > 0) sprintf(" = %.2f ATR now", risk / atr) else "", tg,
    ifelse(risk > 0, sprintf("%.2f", rew / risk), "-"), g("status"), ifelse(is.na(g("exit_code")), "", paste0(", exit ", g("exit_code"), " at ", ex)),
    ifelse(is.finite(r), sprintf("%.2f", r), "-"), ifelse(is.finite(pl), sprintf("%.2f", pl), "-"), ifelse(is.na(dur), "-", dur), cut(g("exit_reason")), cut(g("lessons")))
  cl <- is.finite(r); w <- sum(r[cl] > 0)
  paste0(sprintf("Totals: %d trade(s), %d closed, %d won, %d lost; total %.2f R; stops hit %d times.", nrow(t), sum(cl), w, sum(r[cl] <= 0), sum(r[cl]), sum(g("exit_code") %in% c("S1", "S2+"), na.rm = TRUE)),
         "\n", paste(lines, collapse = "\n"))
}

# ---- ********** evidence, not "chance of success" ---------------------------------------------------------------
# The baseline (cc_touch_prob) is measured from EVERY candle, whatever the set-up: it is what any trade with these
# distances does in this market, not a forecast. The set-up's own record is the evidence; with few cases it proves
# nothing, so its likely range (Wilson, 95%) is shown and compared with the break-even rate 1 / (1 + R:R).
cc_wilson <- function(p_pct, n, z = 1.96) { p <- p_pct / 100; ok <- is.finite(p) & is.finite(n) & n > 0; n <- ifelse(ok, n, 1); p <- ifelse(ok, p, 0)
  den <- 1 + z^2 / n; mid <- (p + z^2 / (2 * n)) / den; hw <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  list(lo = ifelse(ok, 100 * pmax(0, mid - hw), NA_real_), hi = ifelse(ok, 100 * pmin(1, mid + hw), NA_real_)) }
cc_breakeven <- function(rrr) ifelse(is.finite(rrr) & rrr > 0, 100 / (1 + rrr), NA_real_)
cc_evidence <- function(rrr, setup_p, setup_n, min_n = 30L) {
  be <- cc_breakeven(rrr); w <- cc_wilson(setup_p, setup_n); has <- is.finite(setup_p) & is.finite(setup_n) & setup_n > 0
  verdict <- ifelse(!has, "NO RECORD for this set-up (baseline only)", ifelse(w$lo > be, "PROVEN: record above break-even",
             ifelse(w$hi < be, "AGAINST: record below break-even", ifelse(setup_n < min_n, "NOT PROVEN: too few cases", "NOT PROVEN: record near break-even"))))
  list(be = be, lo = w$lo, hi = w$hi, verdict = verdict, proven = has & w$lo > be, against = has & w$hi < be,
       exp_r = ifelse(has, setup_p / 100 * rrr - (1 - setup_p / 100), NA_real_),
       record = ifelse(has, sprintf("%.0f%% of %d cases (likely %.0f-%.0f%%)", setup_p, as.integer(setup_n), w$lo, w$hi), "none"))
}
# *********** one recommended trade, always: Claude's first trade if the plan allows it, otherwise the scenario that fits the plan
# with the best evidence (PROVEN first, then expected R, then R:R); if nothing fits the plan, the best one anyway, flagged
cc_pick_recommended <- function(sc, claude_first = NA_character_) {
  if (is.null(sc) || !NROW(sc)) return(NULL)
  bl <- if ("blocked" %in% names(sc)) as.logical(sc$blocked) else rep(FALSE, nrow(sc)); bl[is.na(bl)] <- FALSE
  scv <- if ("score" %in% names(sc)) suppressWarnings(as.numeric(sc$score)) else rep(NA_real_, nrow(sc)); has_sc <- any(is.finite(scv))
  best <- if (has_sc && any(!bl)) max(scv[!bl], na.rm = TRUE) else NA
  if (!is.na(claude_first) && claude_first %in% sc$id) { k <- match(claude_first, sc$id)   # ************* Claude's first choice wins only when its score is within 5 points of the best
    if (!bl[k] && (!has_sc || !is.finite(scv[k]) || scv[k] >= best - 5)) return(list(k = k, id = sc$id[k], fits = TRUE, why = if (has_sc && is.finite(scv[k])) sprintf("Claude's first choice, it fits your plan and its score (%d) is the best or within 5 points of it.", as.integer(scv[k])) else "Claude's first choice, and it fits your plan.")) }
  num <- function(x) { v <- suppressWarnings(as.numeric(if (is.null(x)) rep(NA, nrow(sc)) else x)); v[!is.finite(v)] <- -Inf; v }
  pv <- if ("ev_proven" %in% names(sc)) as.logical(sc$ev_proven) else rep(FALSE, nrow(sc)); pv[is.na(pv)] <- FALSE
  ag <- grepl("^AGAINST", as.character(sc$evidence %||% rep("", nrow(sc))))
  o <- if ("score" %in% names(sc) && any(is.finite(suppressWarnings(as.numeric(sc$score))))) order(bl, -num(sc$score), -num(sc$rrr)) else order(bl, ag, !pv, -num(sc$ev_exp_r), -num(sc$rrr)); k <- o[1]
  list(k = k, id = sc$id[k], fits = !bl[k],
       why = if (!bl[k] && has_sc) sprintf("Highest score among the scenarios that fit your plan (%d of 100)%s.", as.integer(scv[k]), if (!is.na(claude_first) && claude_first %in% sc$id && claude_first != sc$id[k]) sprintf("; Claude's first choice %s scored %s", claude_first, ifelse(is.finite(scv[match(claude_first, sc$id)]), as.integer(scv[match(claude_first, sc$id)]), "-")) else "")
             else if (!bl[k]) sprintf("Best evidence among the scenarios that fit your plan (%s).", sc$evidence[k] %||% "no record")
             else sprintf("No scenario fits your plan now; this is the best of the rest and it CANNOT be sent while a blocking rule fails: %s", sc$checks[k] %||% sc$plan[k] %||% "")) }
# regime label written for a market in today's Morning Sheet text ("- Brent Crude: ..., UNCLEAR_NO_TRADE"); "" when not found
cc_ms_regime <- function(ms_text, market_name) { if (is.null(ms_text) || !nzchar(ms_text %||% "") || !nzchar(market_name %||% "")) return("")
  w <- strsplit(tolower(market_name), "[^a-z]+")[[1]]; w <- w[nchar(w) >= 4 & !w %in% c("spot", "crude", "cash", "index")]; if (!length(w)) return("")
  ln <- grep("^- ", strsplit(ms_text, "\n")[[1]], value = TRUE); ln <- ln[grepl(w[1], tolower(ln), fixed = TRUE)]; if (!length(ln)) return("")
  m <- regmatches(ln[1], regexpr("UNCLEAR_NO_TRADE|TREND|RANGE", ln[1])); if (length(m)) m else "" }

# ************* two figures per scenario, first columns of the scenario table ------------------------------------------
# chance (0-100): how often the target is likely to be reached before the stop. Measured only: the set-up's own record
#   pulled towards the baseline of this market when it has few cases (as if 30 baseline cases were added to it).
# score (0-100): the chance against the break-even of the R:R (expected R: 0 R = 50, +1 R = 100, -1 R = 0), then points
#   for every other critical factor: evidence, higher time-frame trend, regime, news, confluence, stop width, spread,
#   Morning Sheet and the other plan rules. A scenario blocked by a check or the plan is capped at 25.
cc_success <- function(sc, regime = NA_character_, atr = NA_real_, spread = 0, prior_n = 30) {
  if (is.null(sc) || !NROW(sc)) return(sc)
  n <- nrow(sc); g <- function(k, d = NA) if (k %in% names(sc)) sc[[k]] else rep(d, n); num <- function(k) suppressWarnings(as.numeric(g(k)))
  rrr <- num("rrr"); be <- cc_breakeven(rrr); base <- num("meas_p"); sp <- num("setup_p"); sn <- num("setup_n"); has <- is.finite(sp) & is.finite(sn) & sn > 0
  b0 <- ifelse(is.finite(base), base, be)                                   # no baseline: break-even is the neutral start
  chance <- ifelse(has, (sp * sn + b0 * prior_n) / (sn + prior_n), b0)
  exp_r <- chance / 100 * (1 + rrr) - 1
  pts <- list(); add <- function(name, v) pts[[name]] <<- ifelse(is.finite(v), v, 0)
  add("edge", 50 + 50 * pmax(-1, pmin(1, exp_r)) - 50)                      # shown as + / - around 50
  ev <- as.character(g("evidence", ""))
  add("evidence", ifelse(grepl("^PROVEN", ev), 8, ifelse(grepl("^AGAINST", ev), -12, ifelse(grepl("^NO RECORD", ev), -5, ifelse(grepl("too few", ev), -3, 0)))))
  fit <- as.character(g("fit", "")); add("trend", ifelse(fit %in% "with", 6, ifelse(fit %in% "against", -10, 0)))
  inr <- as.logical(g("in_regime")); add("regime", ifelse(identical(regime, "MIXED"), -6, 0) + ifelse(inr %in% TRUE, 4, ifelse(inr %in% FALSE, -4, 0)))
  nw <- as.character(g("news", "")); add("news", ifelse(is.na(nw) | nw %in% c("", "-", "none", "Morning Sheet not loaded"), 0, -8))
  cf <- as.character(g("confl", "")); cs <- suppressWarnings(as.numeric(sub("^([0-9]+)/([0-9]+).*$", "\\1", cf))); co <- suppressWarnings(as.numeric(sub("^([0-9]+)/([0-9]+).*$", "\\2", cf)))
  add("confluence", ifelse(is.finite(cs) & is.finite(co) & co > 0, round((cs / co - 0.5) * 10), 0))
  sd <- abs(num("entry") - num("stop")); add("stop width", if (is.finite(atr) && atr > 0) ifelse(sd / atr < 1, -6, 0) else 0)
  add("spread", if (is.finite(spread) && spread > 0) ifelse(spread / sd > 0.2, -8, ifelse(spread / sd > 0.1, -4, 0)) else 0)
  pl <- as.character(g("plan", "")); fails <- lapply(strsplit(sub("^[^:|]*[:|]\\s*", "", ifelse(grepl("BREAKS|WARN", pl), pl, "")), ";|\\|"), trimws)
  covered <- "High-impact news|Higher time-frame|Rule of Five|Market regime|^$|^OK$|^half size|WARN \\(allowed"
  add("Morning Sheet", ifelse(grepl("Morning Sheet allows this market", pl), -6, 0))
  add("other plan rules", vapply(fails, function(x) { x <- sub("^WARN \\(allowed, Setup\\):\\s*", "", x); x <- x[!grepl(covered, x) & !grepl("Morning Sheet allows", x)]; -min(9, 3 * length(x)) }, 0))
  m <- do.call(cbind, pts); raw <- 50 + rowSums(m); bl <- as.logical(g("blocked", FALSE)) %in% TRUE
  score <- pmax(0, pmin(100, round(raw))); score[bl] <- pmin(score[bl], 25)
  sc$chance <- round(chance); sc$score <- as.integer(score); sc$exp_r_chance <- round(exp_r, 2)
  sc$score_why <- vapply(seq_len(n), function(i) { v <- m[i, ]; v <- v[v != 0 | names(v) == "edge"]
    paste0(sprintf("50 %+d edge (chance %.0f%% vs break-even %.0f%% = %+.2f R)", as.integer(round(v[["edge"]])), chance[i], be[i], exp_r[i]),
           if (length(v) > 1) paste0(" ", paste(sprintf("%+d %s", as.integer(v[names(v) != "edge"]), names(v)[names(v) != "edge"]), collapse = " ")) else "",
           if (bl[i]) "; capped at 25: blocked by a check or the plan" else "") }, "")
  sc$chance_why <- ifelse(has, sprintf("set-up record %.0f%% of %d cases, pulled towards the baseline %.0f%%", sp, as.integer(sn), b0),
                          ifelse(is.finite(base), sprintf("baseline only %.0f%% (no record for this set-up)", base), "break-even only (no record, no baseline)"))
  sc }
cc_score_band <- function(score) ifelse(!is.finite(score), "-", ifelse(score >= 65, "STRONG", ifelse(score >= 50, "FAIR", "WEAK")))

# ******************** one click: the best scenario across markets and the 5 reasons shown to the trader ------------------------
cc_oneclick_pick <- function(all) {
  if (is.null(all) || !NROW(all)) return(NULL); sc <- suppressWarnings(as.numeric(all$score)); sc[!is.finite(sc)] <- -1; bl <- as.logical(all$blocked) %in% TRUE
  rr <- suppressWarnings(as.numeric(all$rrr)); rr[!is.finite(rr)] <- 0; o <- order(bl, -sc, -rr); list(k = o[1], fits = !bl[o[1]], order = o) }
cc_oneclick_reasons <- function(all, k, n_markets, size = NA, ccy = "", ms_used = FALSE) {
  r <- all[k, , drop = FALSE]; g <- function(x) { v <- r[[x]]; if (is.null(v) || !length(v) || is.na(v[1])) "" else as.character(v[1]) }; num <- function(x) suppressWarnings(as.numeric(g(x)))
  be <- num("be_pct"); if (!is.finite(be)) be <- 100 / (1 + num("rrr")); others <- all[-k, , drop = FALSE]; others <- others[!(as.logical(others$blocked) %in% TRUE), , drop = FALSE]
  nxt <- if (nrow(others)) others[order(-suppressWarnings(as.numeric(others$score))), , drop = FALSE][1, ] else NULL
  c(sprintf("Highest score of %d scenario(s) worked out across %d market(s): %s on %s scores %s/100 (%s), with a measured %s%% chance of reaching the target first against the %.0f%% its R:R of %.2f needs.",
            nrow(all), n_markets, g("id"), g("market"), g("score"), cc_score_band(num("score")), g("chance"), be, num("rrr")),
    sprintf("Evidence: %s. %s", if (nzchar(g("evidence"))) g("evidence") else "no record", if (nzchar(g("setup_rec")) && !g("setup_rec") %in% c("none", "-")) paste0("Set-up record: ", g("setup_rec"), ".") else "The chance comes from this market's baseline for these stop and target distances."),
    sprintf("Trend and regime: %s the daily / 4-hour trend (%s); market regime %s.", if (g("fit") == "with") "with" else if (g("fit") == "against") "AGAINST" else "neutral to", if (nzchar(g("htf"))) g("htf") else "-", if (nzchar(g("regime"))) g("regime") else "-"),
    sprintf("Morning Sheet and news: %s %s", if (isTRUE(ms_used)) "today's Morning Sheet was used by the Claude API." else "no Morning Sheet was found for today.",
            if (nzchar(g("news")) && !g("news") %in% c("-", "none")) paste("High-impact news inside the holding time:", substr(g("news"), 1, 160)) else "No high-impact release inside the holding time."),
    sprintf("Risk %s to make %s at size %s (stop %s, target %s)%s. %s", g("risk_txt"), g("reward_txt"), if (is.finite(size)) format(size) else "-", g("stop"), g("target"),
            if (!is.null(nxt)) sprintf("; next best was %s on %s at %s/100", nxt$id, nxt$market, nxt$score) else "", if (nzchar(g("score_why"))) paste("Score detail:", g("score_why")) else "")) }
