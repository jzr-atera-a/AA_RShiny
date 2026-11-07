# R/utils_cc_sheet.R
# For a CLOSED Capital.com trade: the full trade summary (times, duration, slippage, result in points / USD / GBP / R,
# planned and real R:R, best and worst price while open), static chart pictures, and the LAT Individual Trade Sheet
# (the same Word template and Dropbox folder as the original Trading Records tab, via tr_trade_sheet_template()).
# Your own words are copied as you wrote them; empty boxes stay empty. The app never writes them.

# bars = Capital.com candles covering the trade (any resolution); activity = cc_activity rows of this trade's ids
cc_trade_summary <- function(tr, bars = NULL, activity = NULL) {
  d <- if (toupper(tr$direction) %in% c("BUY", "B")) 1 else -1; vpp <- cc_value_per_point(tr$size, tr$lot_size)
  ids <- stats::na.omit(c(tr$deal_id, tr$order_deal_id)); a <- if (is.null(activity) || !nrow(activity)) NULL else activity[activity$deal_id %in% ids, , drop = FALSE]
  op <- if (!is.null(a) && nrow(a)) { o <- a[!cc_is_close(a), , drop = FALSE]; if (nrow(o)) min(cc_ts(o$date_utc)) else NA } else NA
  cl <- if (!is.null(a) && nrow(a)) { o <- a[cc_is_close(a), , drop = FALSE]; if (nrow(o)) max(cc_ts(o$date_utc)) else NA } else NA
  t_open <- if (!is.na(op)) as.POSIXct(op, origin = "1970-01-01", tz = "UTC") else tr$entry_ts
  t_close <- if (!is.na(cl)) as.POSIXct(cl, origin = "1970-01-01", tz = "UTC") else tr$exit_ts
  risk_pts <- d * (tr$entry_level - tr$stop_initial); rew_pts <- d * (tr$target_level - tr$entry_level)
  res_pts <- if (is.finite(tr$exit_level)) d * (tr$exit_level - tr$entry_level) else NA_real_
  ref <- switch(tr$exit_code %||% "", S1 = tr$stop_initial, `S2+` = tr$stop_level, T = tr$target_level, NA_real_)
  slip <- if (is.finite(ref) && is.finite(tr$exit_level)) d * (tr$exit_level - ref) else NA_real_   # negative = worse than the level
  best <- worst <- NA_real_; best_ts <- worst_ts <- as.POSIXct(NA, tz = "UTC")
  if (!is.null(bars) && nrow(bars) && !is.na(t_open)) { w <- bars[bars$time >= t_open - 60 & bars$time <= (if (is.na(t_close)) max(bars$time) else t_close), , drop = FALSE]
    if (nrow(w)) { if (d > 0) { best <- max(w$high); worst <- min(w$low); best_ts <- w$time[which.max(w$high)]; worst_ts <- w$time[which.min(w$low)] }
                   else { best <- min(w$low); worst <- max(w$high); best_ts <- w$time[which.min(w$low)]; worst_ts <- w$time[which.max(w$high)] } } }
  fx <- if (is.finite(tr$fx_rate)) tr$fx_rate else NA_real_
  gbp <- if (is.finite(tr$pnl_account_booked)) tr$pnl_account_booked else tr$pnl_account_est
  list(open_ts = t_open, close_ts = t_close, duration_h = if (!is.na(t_open) && !is.na(t_close)) as.numeric(difftime(t_close, t_open, units = "hours")) else NA_real_,
       risk_points = risk_pts, reward_points = rew_pts, planned_rrr = if (is.finite(risk_pts) && risk_pts > 0) rew_pts / risk_pts else NA_real_,
       result_points = res_pts, result_r = if (is.finite(res_pts) && is.finite(risk_pts) && risk_pts > 0) res_pts / risk_pts else NA_real_,
       result_instrument = if (is.finite(res_pts)) res_pts * vpp else NA_real_, instrument_currency = tr$instrument_currency,
       result_account_booked = tr$pnl_account_booked, result_account_est = tr$pnl_account_est, result_account = gbp, account_currency = tr$account_currency, fx_rate = fx,
       risk_account = if (is.finite(risk_pts) && is.finite(fx)) risk_pts * vpp * fx else tr$risk_account, value_per_point_account = if (is.finite(fx)) vpp * fx else NA_real_,
       slippage_points = slip, exit_code = tr$exit_code, exit_level = tr$exit_level,
       best_price = best, best_ts = best_ts, worst_price = worst, worst_ts = worst_ts,
       mfe_points = if (is.finite(best)) d * (best - tr$entry_level) else NA_real_, mae_points = if (is.finite(worst)) d * (worst - tr$entry_level) else NA_real_,
       reached_target = if (is.finite(best) && is.finite(tr$target_level)) d * (best - tr$target_level) >= 0 else NA)
}
cc_summary_lines <- function(sm) {
  f <- function(x, k = 3) if (is.finite(x %||% NA)) formatC(x, format = "f", digits = k) else "-"
  tt <- function(x) if (is.na(x %||% NA)) "-" else format(x, "%d/%m/%Y %H:%M:%S UK", tz = "Europe/London")
  c(sprintf("Opened %s, closed %s (%s).", tt(sm$open_ts), tt(sm$close_ts), if (is.finite(sm$duration_h)) tr_duration_text(sm$duration_h) else "duration unknown"),
    sprintf("Planned: risk %s points, reward %s points, R:R %s.", f(sm$risk_points), f(sm$reward_points), f(sm$planned_rrr, 2)),
    sprintf("Result: %s points = %s %s = %s %s%s, %s R.", f(sm$result_points), f(sm$result_instrument, 2), sm$instrument_currency %||% "", f(sm$result_account, 2), sm$account_currency %||% "",
            if (is.finite(sm$result_account_booked %||% NA)) " (booked by Capital.com)" else " (estimated)", f(sm$result_r, 2)),
    sprintf("Exit %s at %s; slippage %s points against the level.", sm$exit_code %||% "-", f(sm$exit_level), f(sm$slippage_points)),
    sprintf("While open: best %s (%s points in favour), worst %s (%s points against)%s.", f(sm$best_price), f(sm$mfe_points), f(sm$worst_price), f(sm$mae_points),
            if (isTRUE(sm$reached_target)) "; price reached the target level" else if (identical(sm$reached_target, FALSE)) "; price never reached the target" else ""))
}

# static chart picture (base graphics) for the Word sheet: candles, EMA20/50, the patterns drawn at entry (lines),
# entry / stop / target / exit levels, the trade window shaded
cc_chart_png <- function(bars, file, title = "", entry = NA, stop = NA, target = NA, exit = NA, t_open = NA, t_close = NA, patterns = NULL, caption = "") {
  grDevices::png(file, width = 1500, height = 780, res = 135); on.exit(grDevices::dev.off())
  n <- nrow(bars); x <- seq_len(n); graphics::par(mar = c(5.6, 4.2, 3, 7.5), cex = 0.85)
  yl <- range(c(bars$low, bars$high, entry, stop, target, exit), na.rm = TRUE); yl <- yl + c(-1, 1) * diff(yl) * 0.04
  graphics::plot(NA, xlim = c(1, n + 2), ylim = yl, xaxt = "n", xlab = "UK time", ylab = "Price", main = title)
  tk <- unique(round(seq(1, n, length.out = min(8, n)))); graphics::axis(1, at = tk, labels = format(bars$time[tk], "%d/%m %H:%M", tz = "Europe/London"))
  ti <- function(t) if (is.na(t)) NA else which.min(abs(as.numeric(bars$time) - as.numeric(t)))
  i0 <- ti(t_open); i1 <- if (is.na(t_close)) n else ti(t_close)
  if (!is.na(i0)) graphics::rect(i0 - 0.5, yl[1], i1 + 0.5, yl[2], col = grDevices::adjustcolor("#0ea5e9", 0.08), border = NA)
  col <- ifelse(bars$close >= bars$open, "#16a34a", "#dc2626")
  graphics::segments(x, bars$low, x, bars$high, col = col); graphics::rect(x - 0.35, pmin(bars$open, bars$close), x + 0.35, pmax(bars$open, bars$close), col = col, border = col)
  if (n > 25) { e20 <- as.numeric(TTR::EMA(bars$close, min(20, n - 1))); graphics::lines(x, e20, col = "#2563eb") }
  if (n > 55) { e50 <- as.numeric(TTR::EMA(bars$close, 50)); graphics::lines(x, e50, col = "#f59e0b") }
  if (!is.null(patterns)) for (o in patterns) if (!is.null(o$lines)) for (k in seq_len(nrow(o$lines))) { z <- o$lines[k, ]
    graphics::segments(z$x0, z$y0, z$x1, z$y1, col = cc_bias_col(cc_cat_row(o$key)$bias), lwd = 2, lty = if (z$dash == "solid") 1 else 2) }
  lv <- list(list(entry, "#1d4ed8", "Entry"), list(stop, "#dc2626", "Stop"), list(target, "#16a34a", "Target"), list(exit, "#111827", "Exit"))
  for (l in lv) if (is.finite(l[[1]])) { graphics::abline(h = l[[1]], col = l[[2]], lty = 2); graphics::mtext(sprintf("%s %s", l[[3]], format(signif(l[[1]], 7))), side = 4, at = l[[1]], las = 1, cex = 0.75, col = l[[2]], line = 0.3) }
  if (nzchar(caption)) graphics::mtext(caption, side = 1, line = 4.4, cex = 0.7, col = "#475569", adj = 0)
  invisible(file)
}

# the sheet: maps the cc_ trade onto the fields tr_trade_sheet_template() expects (the IG trade layout)
cc_trade_sheet <- function(tr, sm, name, pics, file, context = list()) {
  closed <- !is.null(sm)
  lv0 <- if (is.finite(tr$entry_level %||% NA)) tr$entry_level else tr$order_level %||% NA
  if (!closed) sm <- list(value_per_point_account = NA_real_, risk_points = abs(lv0 - tr$stop_initial), risk_account = tr$risk_account,
                          reward_points = abs(tr$target_level - lv0), planned_rrr = NA_real_, open_ts = if (!is.na(tr$entry_ts %||% NA)) tr$entry_ts else tr$placed_ts %||% NA)
  sm$planned_rrr <- sm$planned_rrr %||% NA_real_; nz <- function(x) if (is.null(x) || !length(x)) NA else x
  for (k in c("value_per_point_account", "risk_points", "risk_account", "reward_points", "open_ts")) sm[[k]] <- nz(sm[[k]])
  if (!is.finite(sm$planned_rrr) && is.finite(sm$risk_points) && sm$risk_points > 0) sm$planned_rrr <- sm$reward_points / sm$risk_points
  ent <- if (is.finite(tr$entry_level %||% NA)) tr$entry_level else tr$order_level %||% NA
  d <- if (toupper(tr$direction) %in% c("BUY", "B")) "B" else "S"; ppa <- sm$value_per_point_account
  trade <- data.frame(chart_period = tr$chart_period, expected_duration_hours = tr$expected_hours, initial_risk_pips = sm$risk_points, initial_risk_gbp = sm$risk_account,
                      initial_reward_pips = sm$reward_points, stake_per_pip_gbp = ppa, lot_units = suppressWarnings(as.numeric(tr$size)), initial_rrr = sm$planned_rrr, entry_ts = sm$open_ts, direction = d,
                      asset = tr$market_name %||% tr$epic, entry_price = ent, stop1 = tr$stop_initial, target = tr$target_level,
                      setup_fundamental = tr$setup_fund, setup_technical = tr$setup_tech, trigger_text = tr$trigger_text, execution_text = tr$execution_text,
                      stop_reason = tr$stop_reason, target_reason = tr$target_reason,
                      overall_analysis = paste(c(tr$analysis[!is.na(tr$analysis) & nzchar(tr$analysis %||% "")], if (closed) paste("Trade data (from Capital.com):", paste(cc_summary_lines(sm), collapse = " "))), collapse = "\n"),
                      exit_code = if (closed) NA else tr$exit_code %||% NA, exit_price = NA, exit_ts = NA, reason_for_exit = tr$exit_reason %||% NA, lessons_learned = tr$lessons %||% NA,
                      stringsAsFactors = FALSE)
  if (!closed) { tr_trade_sheet_template(trade, data.frame(), NULL, name, charts = pics, file = file, context = context); return(file) }
  legs <- data.frame(exit_ts = sm$close_ts, direction = d, asset = trade$asset, stake_per_pip_gbp = ppa, lot_units = suppressWarnings(as.numeric(tr$size)), entry_price = tr$entry_level, exit_price = tr$exit_level,
                     pips_result = sm$result_points, net_pnl_gbp = sm$result_account, duration_hours = sm$duration_h, exit_code = tr$exit_code,
                     reason_for_exit = tr$exit_reason, lessons_learned = tr$lessons, stringsAsFactors = FALSE)
  tr_trade_sheet_template(trade, legs, NULL, name, charts = pics, file = file, context = context)
  file
}

# ---- the scenario chosen when the order was placed (saved in cc_trades.scenario_json) -------------------------
# Snapshot of the chosen scenario row with its chances, R:R, Claude's reasoning and main risk, plus whether the C analysis
# goes into the trade sheet. Old orders saved only id / entry / stop / target / basis: cc_scenario_read() reads both.
cc_scenario_snapshot <- function(sc, pick, include_c = TRUE, ci = NULL, hold_h = NA_real_) {
  row <- NULL
  if (!is.null(sc) && length(pick) && nzchar(pick %||% "")) { k <- match(pick, sc$id)
    if (!is.na(k)) { keep <- intersect(c("id", "source", "side", "type", "entry", "stop", "target", "now_px", "rrr", "meas_p", "meas_n", "meas_und", "claude_p", "risk_acc", "reward_acc", "note", "basis"), names(sc))
      row <- as.list(sc[k, keep, drop = FALSE]) } }
  cc_json(list(version = 2L, scenario = row, include_c = isTRUE(include_c), hold_h = hold_h, ccy = attr(sc, "ccy") %||% NA, d = attr(sc, "d") %||% NA,
               worked_out = if (!is.null(attr(sc, "at"))) format(attr(sc, "at"), "%Y-%m-%d %H:%M:%S", tz = "UTC") else NA,
               c_summary = if (isTRUE(ci$ok)) ci$text %||% NA else NA))
}
cc_scenario_read <- function(js) {
  out <- list(scenario = NULL, include_c = TRUE, hold_h = NA_real_, ccy = NA, d = NA, c_summary = NA)
  if (is.null(js) || length(js) != 1 || is.na(js) || !nzchar(js)) return(out)
  x <- tryCatch(jsonlite::fromJSON(js, simplifyVector = TRUE), error = function(e) NULL); if (is.null(x)) return(out)
  if (is.data.frame(x)) { if (nrow(x)) out$scenario <- as.list(x[1, , drop = FALSE]); return(out) }   # old format: the row only
  for (k in intersect(names(out), names(x))) if (!is.null(x[[k]])) out[[k]] <- x[[k]]
  if (is.data.frame(out$scenario)) out$scenario <- as.list(out$scenario[1, , drop = FALSE])
  out
}
cc_scen_val <- function(s, k) { v <- s[[k]]; if (is.null(v) || !length(v) || is.na(v[1])) NA else v[1] }
# ****** the worksheet never names the AI model: only the platform (Capital.com data, the app's analysis)
cc_no_ai_name <- function(x) { if (is.null(x) || !length(x) || is.na(x[1])) return(x)
  x <- gsub("\\bC \\(Claude\\)|\\bClaude's\\b", "the platform's", x, perl = TRUE); x <- gsub("^(Claude|C): ", "", x, perl = TRUE)
  x <- gsub("\\bCLAUDE\\b", "PLATFORM", x, perl = TRUE); x <- gsub("\\bClaude\\b", "the platform", x, perl = TRUE); gsub("\\bC (estimate|analysis|view)\\b", "platform \\1", x, perl = TRUE) }
# one line per fact, for the sheet and for the AI prompt
cc_scenario_lines <- function(sr, d = 4) {
  s <- sr$scenario; if (is.null(s)) return(character(0)); d <- if (is.finite(suppressWarnings(as.numeric(sr$d)))) as.numeric(sr$d) else d
  px <- function(k) { v <- suppressWarnings(as.numeric(cc_scen_val(s, k))); if (is.finite(v)) formatC(v, format = "f", digits = d) else "-" }
  nm <- function(k) suppressWarnings(as.numeric(cc_scen_val(s, k)))
  src <- cc_scen_val(s, "source"); who <- if (identical(src, "Claude")) "the platform's chart analysis (Capital.com data)" else if (identical(src, "Rules")) "the app's rules" else "-"
  c(sprintf("Scenario chosen: %s, suggested by %s: %s %s.", cc_no_ai_name(cc_scen_val(s, "id")), who, cc_scen_val(s, "side") %||% "", tolower(cc_scen_val(s, "type") %||% "")),
    sprintf("Entry %s, stop %s, target %s%s; R:R %s.", px("entry"), px("stop"), px("target"), if (is.finite(nm("now_px"))) sprintf(" (price when worked out %s)", px("now_px")) else "",
            if (is.finite(nm("rrr"))) formatC(nm("rrr"), format = "f", digits = 2) else "-"),
    sprintf("Chance of success (target before stop), measured: %s. Platform estimate: %s.",
            if (is.finite(nm("meas_p"))) sprintf("%.0f%% (n=%d; %.0f%% reached neither within %s h)", nm("meas_p"), as.integer(nm("meas_n")), nm("meas_und"), format(round(as.numeric(sr$hold_h), 1))) else "not measured",
            if (is.finite(nm("claude_p"))) sprintf("%.0f%% (estimate, not measured)", nm("claude_p")) else "-"),
    if (!is.na(cc_scen_val(s, "note")) && nzchar(cc_scen_val(s, "note"))) paste("How / why:", cc_no_ai_name(cc_scen_val(s, "note"))) else NULL,
    if (!is.na(cc_scen_val(s, "basis")) && nzchar(cc_scen_val(s, "basis"))) paste("Patterns / reasons:", cc_no_ai_name(cc_scen_val(s, "basis"))) else NULL)
}
# patterns found on the chart at order (scan saved with the order: cc_scans.current_json)
cc_scan_patterns <- function(current_json) {
  x <- tryCatch(jsonlite::fromJSON(current_json %||% "[]"), error = function(e) NULL)
  if (!is.data.frame(x) || !nrow(x)) return(NULL)
  g <- function(k) if (k %in% names(x)) x[[k]] else rep(NA, nrow(x))
  rec <- ifelse(is.finite(suppressWarnings(as.numeric(g("hist_n")))) & as.numeric(g("hist_n")) > 0,
                sprintf("%s%% target first, n=%s", ifelse(is.finite(as.numeric(g("hist_win"))), round(as.numeric(g("hist_win"))), "-"), g("hist_n")), "not measured")
  data.frame(Pattern = g("label"), Step = g("step"), Bias = g("bias"), Status = g("status"), `Candles ago` = g("candles_ago"), `Measured record` = rec, check.names = FALSE, stringsAsFactors = FALSE)
}
# What C (Claude) is asked after the trade: compare what was recommended with what happened.
cc_c_prompt <- function(tr, sm, sr, pats, ms_text = NULL) {
  st <- tr$status %||% "-"
  paste0("You are C, the analyst in a trading-education app (Capital.com DEMO account). Write the 'C analysis' for this trade's Individual Trade Sheet: ",
         "a short, plain-English analysis (120-220 words, no headings, no bullet symbols) of (1) what was recommended and why, (2) what actually happened, ",
         "(3) whether the reasoning held or failed and why, (4) one or two concrete lessons. Be factual; do not invent prices or times that are not given. ",
         "If the order was never filled or was cancelled, say so and analyse that instead. ",
         "This text goes into a course worksheet: never mention C, Claude, AI or a model; write in the first person as the trader, and when a source is needed name only the platform (Capital.com) or 'the app'.\n\n",
         sprintf("Market: %s. Direction %s, size %s, order type %s. Status now: %s.\n", tr$market_name %||% tr$epic, tr$direction, tr$size, tr$order_type, st),
         sprintf("Order levels: entry %s, stop %s, target %s; exit %s; exit code %s.\n", tr$order_level %||% tr$entry_level, tr$stop_initial, tr$target_level, tr$exit_level %||% "-", tr$exit_code %||% "-"),
         if (!is.null(sm)) paste0("Trade data from Capital.com: ", paste(cc_summary_lines(sm), collapse = " "), "\n") else "",
         "Recommendation chosen when the order was placed:\n", paste(cc_scenario_lines(sr), collapse = "\n"), "\n",
         if (!is.na(sr$c_summary %||% NA) && nzchar(sr$c_summary)) paste0("C's view of the market at the time: ", sr$c_summary, "\n") else "",
         if (!is.null(pats)) paste0("Patterns found on the chart at the order: ", paste(sprintf("%s (%s, %s; %s)", pats$Pattern, pats$Bias, pats$Status, pats$`Measured record`), collapse = "; "), "\n") else "",
         if (!is.null(ms_text) && nzchar(ms_text)) paste0("The trader's MORNING SHEET of that day (written before the trade; use it: say whether the trade agreed with its bias, levels and news, and whether the news or levels explain what happened):\n", ms_text, "\n") else "No Morning Sheet is included for that day.\n",
         "Trader's own notes: set-up ", tr$setup_tech %||% "-", "; trigger ", tr$trigger_text %||% "-", "; exit reason ", tr$exit_reason %||% "-", ".\n")
}
# The 'Context' block put at the bottom of the sheet
cc_context_items <- function(sr, pats, c_text = "", include_c = TRUE, chart = NA_character_, status = "") {
  it <- function(type, v) list(type = type, value = v)
  items <- list(it("caption", "Context (from the app; not part of the LAT fields above)"))
  if (nzchar(status)) items <- c(items, list(it("text", status)))
  if (!is.na(chart) && file.exists(chart)) items <- c(items, list(it("caption", "Chart and patterns at the order (Market & Patterns)"), it("pic", chart)))
  if (!is.null(pats) && nrow(pats)) items <- c(items, list(it("caption", "Patterns found by the app's rules at the order"), it("table", structure(pats, grid = TRUE))))
  sl <- cc_scenario_lines(sr)
  items <- c(items, list(it("caption", "The recommended trade that was placed")),
             if (length(sl)) lapply(sl, function(x) it("text", x)) else list(it("text", "No scenario was chosen in the app for this order.")))
  if (isTRUE(include_c) && nzchar(trimws(c_text %||% ""))) items <- c(items, list(it("caption", "Analysis")), lapply(strsplit(cc_no_ai_name(trimws(c_text)), "\n+")[[1]], function(x) it("text", x)))
  items
}
