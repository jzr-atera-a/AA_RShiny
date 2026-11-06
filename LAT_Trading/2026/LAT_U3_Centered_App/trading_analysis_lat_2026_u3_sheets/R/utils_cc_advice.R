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
  list(sheet_id = s$sheet_id, saved_at = s$saved_at, text = txt, releases = v("todays_releases"))
}

# ---- Claude's suggested trades ----------------------------------------------------------------------------------
cc_suggest_prompt <- function(scan, f, scen, plan, morning = NULL, now = Sys.time()) {
  ctx <- scan$ctx; n <- ctx$n; d <- cc_px_decimals(f); k <- max(1, n - 39):n
  bars <- paste(sprintf("%s %s %s %s %s", format(ctx$b$time[k], "%d/%m %H:%M", tz = "Europe/London"), cc_fmt_px(ctx$o[k], d), cc_fmt_px(ctx$h[k], d), cc_fmt_px(ctx$l[k], d), cc_fmt_px(ctx$c[k], d)), collapse = "\n")
  cd <- scan$current_df
  pats <- if (is.null(cd) || !nrow(cd)) "(none)" else paste(sprintf("- %s [%s%s]: cancels beyond %s, target %s; record %s", cd$label, ifelse(is.na(cd$dir), "context", ifelse(cd$dir > 0, "bullish", "bearish")),
    ifelse(cd$in_regime, "", ", outside regime"), cc_fmt_px(cd$invalid, d), cc_fmt_px(cd$target, d),
    ifelse(cd$hist_n >= 1, sprintf("target first %s%% n=%d", ifelse(is.finite(cd$hist_win), round(cd$hist_win), "-"), cd$hist_n), "none")), collapse = "\n")
  sc <- if (is.null(scen) || !nrow(scen)) "(none)" else paste(sprintf("%s: entry %s, stop %s, target %s, R:R %s", scen$id, cc_fmt_px(scen$entry, d), cc_fmt_px(scen$stop, d), cc_fmt_px(scen$target, d), round(scen$rrr, 2)), collapse = "\n")
  paste0(
    "You help a trading student on a DEMO account plan intraday trades on ", f$name %||% f$epic, " (Capital.com ", f$epic, ", quoted in ", f$currency %||% "", " with ", d, " decimals). ",
    "Time now ", format(now, "%d/%m/%Y %H:%M", tz = "Europe/London"), " UK. Price now: bid ", cc_fmt_px(f$bid, d), ", offer ", cc_fmt_px(f$offer, d), ". ",
    "Capital.com minimum stop distance ", f$min_stop_distance %||% "-", ".\n",
    "Chart: ", ctx$minutes, "-minute candles; ATR(14) ", cc_fmt_px(ctx$a[n], d), "; ADX(14) ", round(scan$adx %||% NA, 1), "; regime ", scan$regime, ".\n",
    "Student's plan: minimum reward:risk ", plan$min_rrr %||% "-", "; risk per trade ", plan$risk_pct %||% "-", "% of balance; holding up to ", plan$hold_h %||% "-", " hours.\n",
    if (length(plan$rules_text) && nzchar(plan$rules_text)) paste0("Student's trading plan rules and their state NOW (a trade that breaks one cannot be sent; do NOT propose it):\n", plan$rules_text, "\n") else "",
    "Patterns found now by rule (with their measured record on this market):\n", pats, "\n",
    "The app's rule-based scenarios (all are deals at the market):\n", sc, "\n",
    "Last 40 candles (UK time, open high low close):\n", bars, "\n",
    if (!is.null(morning)) paste0("\n", morning, "\n") else "\nNo Morning Sheet is included.\n",
    "\nTASK: propose up to 3 trades that make sense NOW, using the price action, the patterns",
    if (!is.null(morning)) " AND the Morning Sheet (news direction, releases inside the holding window, levels; respect STAND ASIDE)" else "", ". ",
    "RULES: every trade is a DEAL opened NOW at the market (BUY at the offer ", cc_fmt_px(f$offer, d), ", SELL at the bid ", cc_fmt_px(f$bid, d), "): no limit or stop entries, no waiting orders. ",
    "Reward:risk = |target - entry| / |entry - stop| MUST be at least ", plan$min_rrr %||% 1.5, " (the student's minimum): a trade below it cannot be placed, so do not propose it. ",
    "For each give: side BUY or SELL; type MARKET; entry = the offer for BUY, the bid for SELL; ",
    "stop and target as absolute prices with ", d, " decimals; the stop beyond a real level and at least about 1 ATR from the entry; ",
    "probability_pct = your estimate (0-100) that the target is reached before the stop; horizon_hours; why (max 2 short sentences, facts only); main_risk (1 short sentence, e.g. a release in the window). ",
    "Every trade must respect the plan rules above (direction with the major trend of the Rule of Five when it has one, the higher R:R when against the daily / 4-hour trend, the allowed set-ups). If a rule that applies to every trade fails now (session, news window, regime, losses in a row), return an empty list and put the reason in stand_aside_reason. ",
    "Also give probability_pct for each of the app's scenarios. If no trade makes sense, return an empty list and say why in summary. ",
    "Reply with ONE JSON object only: {\"summary\":\"1-2 sentences\",\"morning_sheet_used\":true|false,\"stand_aside_reason\":\"\",",
    "\"suggestions\":[{\"side\":\"SELL\",\"type\":\"MARKET\",\"entry\":0,\"stop\":0,\"target\":0,\"probability_pct\":0,\"horizon_hours\":0,\"why\":\"\",\"main_risk\":\"\"}],",
    "\"scenario_estimates\":[{\"id\":\"BUY MARKET\",\"probability_pct\":0}]}")
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
  list(ok = TRUE, rows = rows, estimates = est, summary = as.character(j$summary %||% ""), used_sheet = isTRUE(j$morning_sheet_used), stand_aside = as.character(j$stand_aside_reason %||% ""))
}

# ---- Yahoo as an alternative source of candles (futures / FX quotes; shifted onto Capital.com's price) -------------
cc_yahoo_symbol <- function(epic, name = "") {
  map <- c(OIL_BRENT = "BZ=F", OIL_CRUDE = "CL=F", GOLD = "GC=F", SILVER = "SI=F", NATURALGAS = "NG=F", COPPER = "HG=F", EURUSD = "EURUSD=X", GBPUSD = "GBPUSD=X",
           USDJPY = "JPY=X", AUDUSD = "AUDUSD=X", USDCAD = "CAD=X", USDCHF = "CHF=X", NZDUSD = "NZDUSD=X", EURGBP = "EURGBP=X", US30 = "^DJI", US500 = "^GSPC", US100 = "^NDX",
           UK100 = "^FTSE", DE40 = "^GDAXI", J225 = "^N225")
  e <- toupper(epic %||% ""); if (e %in% names(map)) return(unname(map[[e]]))
  n <- toupper(name %||% ""); if (grepl("BRENT", n)) "BZ=F" else if (grepl("CRUDE|WTI", n)) "CL=F" else if (grepl("GOLD", n)) "GC=F" else NA_character_ }
cc_yahoo_bars <- function(fetch, symbol, res, hist_days = 20) {
  iv <- c(MINUTE_5 = "5m", MINUTE_15 = "15m", MINUTE_30 = "30m", HOUR = "60m")[res]
  if (is.na(iv)) stop("Yahoo has no ", res, " candles: choose 5, 15 or 30 minutes or 1 hour.")
  rg <- if (iv == "5m") "1mo" else "60d"
  r <- fetch(symbol, rg, unname(iv)); b <- if (is.data.frame(r)) r else r$bars
  if (is.null(b) || !nrow(b)) stop("Yahoo returned no candles for ", symbol, ".")
  b <- b[is.finite(b$open) & is.finite(b$high) & is.finite(b$low) & is.finite(b$close), , drop = FALSE]
  b <- b[b$time >= max(b$time) - max(3, hist_days) * 86400, , drop = FALSE]; b[order(b$time), c("time", "open", "high", "low", "close")] }
