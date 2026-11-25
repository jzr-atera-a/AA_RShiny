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
  stp0 <- if (is.finite(tr$stop_initial %||% NA)) tr$stop_initial else tr$stop_level %||% NA
  if (closed && !is.finite(sm$risk_points %||% NA)) { sm$risk_points <- abs(lv0 - stp0); sm$reward_points <- abs(tr$target_level - lv0) }   # ******************
  if (closed && !is.finite(sm$risk_account %||% NA)) sm$risk_account <- tr$risk_account
  if (!closed) sm <- list(value_per_point_account = NA_real_, risk_points = abs(lv0 - stp0), risk_account = tr$risk_account,
                          reward_points = abs(tr$target_level - lv0), planned_rrr = NA_real_, open_ts = if (!is.na(tr$entry_ts %||% NA)) tr$entry_ts else tr$placed_ts %||% NA)
  sm$planned_rrr <- sm$planned_rrr %||% NA_real_; nz <- function(x) if (is.null(x) || !length(x)) NA else x
  for (k in c("value_per_point_account", "risk_points", "risk_account", "reward_points", "open_ts")) sm[[k]] <- nz(sm[[k]])
  if (!is.finite(sm$planned_rrr) && is.finite(sm$risk_points) && sm$risk_points > 0) sm$planned_rrr <- sm$reward_points / sm$risk_points
  ent <- if (is.finite(tr$entry_level %||% NA)) tr$entry_level else tr$order_level %||% NA
  d <- if (toupper(tr$direction) %in% c("BUY", "B")) "B" else "S"; ppa <- sm$value_per_point_account
  trade <- data.frame(chart_period = tr$chart_period, expected_duration_hours = tr$expected_hours, initial_risk_pips = sm$risk_points, initial_risk_gbp = sm$risk_account,
                      initial_reward_pips = sm$reward_points, initial_reward_gbp = if (is.finite(ppa %||% NA) && is.finite(sm$reward_points)) sm$reward_points * ppa else suppressWarnings(as.numeric(tr$reward_account %||% NA)), stake_per_pip_gbp = ppa, lot_units = suppressWarnings(as.numeric(tr$size)), initial_rrr = sm$planned_rrr, entry_ts = sm$open_ts, direction = d,
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
  src <- cc_scen_val(s, "source"); who <- if (identical(src, "Claude")) "the platform's chart analysis (Capital.com data)" else if (identical(src, "Rules")) "the app's rules" else if (grepl("^Course", src %||% "")) "the app's course strategies" else "the app"
  c(sprintf("Scenario chosen: %s, suggested by %s: %s %s.", cc_no_ai_name(cc_scen_val(s, "id")), who, cc_scen_val(s, "side") %||% "", tolower(cc_scen_val(s, "type") %||% "")),
    sprintf("Entry %s, stop %s, target %s%s; R:R %s.", px("entry"), px("stop"), px("target"), if (is.finite(nm("now_px"))) sprintf(" (price when worked out %s)", px("now_px")) else "",
            if (is.finite(nm("rrr"))) formatC(nm("rrr"), format = "f", digits = 2) else "-"),
    sprintf("Baseline for these distances from any moment in this market (not a forecast of this trade): %s. Break-even for this R:R: %s. Platform estimate: %s.",
            if (is.finite(nm("meas_p"))) sprintf("%.0f%% (n=%d; %.0f%% reached neither within %s h)", nm("meas_p"), as.integer(nm("meas_n")), nm("meas_und"), format(round(as.numeric(sr$hold_h), 1))) else "not measured",
            if (is.finite(nm("rrr")) && nm("rrr") > 0) sprintf("%.0f%%", 100 / (1 + nm("rrr"))) else "-",
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
  prof <- if (exists("cc_market_profile", mode = "function")) tryCatch(cc_market_profile(tr$epic %||% "", tr$market_name %||% "", NA, tr$instrument_currency %||% NA), error = function(e) NULL) else NULL
  paste0(if (!is.null(prof)) sprintf("The market is %s (%s, %s); what usually moves it: %s.\n", prof$name, prof$class_label, prof$sub, paste(prof$drivers, collapse = "; ")) else "",
         "You are C, the analyst in a trading-education app (Capital.com DEMO account). Write the 'C analysis' for this trade's Individual Trade Sheet: ",
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

# ****************** the reasons box of the Trade Sheet, written from the facts saved with the deal ---------------------------
# Used for every box left empty: your own words always win. Sources: the chosen scenario (cc_trades.scenario_json), the
# patterns on the chart at entry (cc_scans), that day's Morning Sheet, the deal Capital.com filled, and the close.
# Plain facts in the first person; the AI model is never named.
cc_auto_reasons <- function(tr, sr = NULL, pats = NULL, scan = NULL, ms = NULL, sm = NULL, d = 3) {
  g <- function(k) { v <- tr[[k]]; if (is.null(v) || !length(v) || is.na(v[1]) || (is.character(v[1]) && !nzchar(v[1]))) NA else v[1] }
  gs <- function(k, d) { v <- g(k); if (is.na(v)) d else v }; n <- function(k) suppressWarnings(as.numeric(g(k))); px <- function(v) if (is.finite(v)) formatC(v, format = "f", digits = d) else "-"
  s <- if (is.null(sr)) NULL else sr$scenario; sv <- function(k) if (is.null(s)) NA else cc_scen_val(s, k)
  sd <- if (is.finite(suppressWarnings(as.numeric(sr$d %||% NA)))) as.numeric(sr$d) else d; d <- sd
  dir <- toupper(gs("direction", "")); buy <- dir %in% c("BUY", "B"); side <- if (buy) "buy" else "sell"
  ent <- if (is.finite(n("entry_level"))) n("entry_level") else n("order_level"); stp <- if (is.finite(n("stop_initial"))) n("stop_initial") else n("stop_level"); tgt <- n("target_level")
  rd <- abs(ent - stp); wd <- abs(tgt - ent); rr <- if (is.finite(rd) && rd > 0) wd / rd else NA_real_
  tm <- function(x) if (is.null(x) || is.na(x)) "-" else format(as.POSIXct(x, tz = "UTC"), "%H:%M", tz = "Europe/London")
  parts <- if (is.na(sv("note"))) character(0) else trimws(unlist(strsplit(cc_no_ai_name(as.character(sv("note"))), ";")))
  part <- function(re) { x <- parts[grepl(re, parts, ignore.case = TRUE)]; if (length(x)) x[1] else NA_character_ }
  basis <- if (is.na(sv("basis"))) NA_character_ else cc_no_ai_name(as.character(sv("basis")))
  strat <- g("strategy"); strat <- if (is.na(strat) || strat %in% c("", "NONE", "Other")) NA else strat
  src <- sv("source"); who <- if (identical(src, "Claude")) "the platform's chart analysis" else if (identical(src, "Rules")) "the app's pattern rules" else if (grepl("^Course", src %||% "")) "the course strategy scanner" else NA
  res <- if (!is.null(scan) && NROW(scan) && !is.na(scan$resolution[1])) cc_chart_label(scan$resolution[1]) else gs("chart_period", NA)
  # fundamental
  fund <- if (is.null(ms)) "No Morning Sheet was saved for this day, so I had no written fundamental view; the trade was taken on the technical set-up only." else {
    cut <- function(x, k = 420) { x <- gsub("\\s+", " ", x %||% ""); if (nchar(x) > k) paste0(substr(x, 1, k - 3), "...") else x }
    paste0("From my Morning Sheet: ", if (nzchar(ms$news %||% "")) paste0("overnight news: ", cut(ms$news), " ") else "no overnight news written. ",
      if (nzchar(ms$window %||% "")) paste0("Releases inside my trading window: ", cut(ms$window, 220), ". ") else "No high-impact release was listed inside my trading window. ",
      if (nzchar(ms$stand %||% "")) paste0("The sheet marked this market as stand aside (", cut(ms$stand, 150), "), so this trade went against that note. ") else "",
      if (nzchar(ms$regime %||% "")) paste0("Regime notes: ", cut(ms$regime, 160), ".") else "") }
  # technical
  pl <- if (!is.null(pats) && NROW(pats)) { p <- pats[!is.na(pats$Pattern), , drop = FALSE]; aligned <- p[grepl(if (buy) "Bull" else "Bear", p$Bias, ignore.case = TRUE), , drop = FALSE]
    p <- rbind(aligned, p[!(p$Pattern %in% aligned$Pattern), , drop = FALSE]); p <- utils::head(p, 4); paste(sprintf("%s (%s, record %s)", p$Pattern, tolower(p$Bias %||% "-"), p$`Measured record`), collapse = "; ") } else NA
  s4 <- tryCatch(cc_scen_setup4(as.data.frame(c(list(id = sv("id") %||% "", basis = basis %||% "", source = src %||% "", keys = if (is.na(sv("keys"))) "" else sv("keys")), list()), stringsAsFactors = FALSE)), error = function(e) NA_character_)
  tech <- paste0(if (!is.na(strat)) paste0("Set-up: ", strat, if (length(s4) && !is.na(s4) && !is.na(sv("id"))) paste0(" (one of the course's four set-ups: ", s4, ")") else "", ". ") else if (length(s4) && !is.na(s4) && !is.na(sv("id"))) paste0("Course set-up type: ", s4, ". ") else "",
    if (!is.null(scan) && NROW(scan) && !is.na(scan$regime[1])) sprintf("Market regime %s (ADX %s on the %s chart). ", scan$regime[1], if (is.finite(suppressWarnings(as.numeric(scan$adx[1])))) formatC(as.numeric(scan$adx[1]), format = "f", digits = 1) else "-", res %||% "-") else "",
    if (!is.na(pl)) paste0("Patterns on the chart when I entered: ", pl, ". ") else "",
    if (!is.na(sv("id"))) sprintf("I took the %s scenario%s, R:R %s.", cc_no_ai_name(as.character(sv("id"))), if (!is.na(who)) paste0(" from ", who) else "", if (is.finite(suppressWarnings(as.numeric(sv("rrr"))))) formatC(as.numeric(sv("rrr")), format = "f", digits = 2) else "-") else "")
  if (!nzchar(trimws(tech))) tech <- sprintf("A %s on %s at %s with the stop at %s and the target at %s (R:R %s); no scenario or chart scan was saved with this deal.", side, gs("market_name", gs("epic", "the market")), px(ent), px(stp), px(tgt), if (is.finite(rr)) formatC(rr, format = "f", digits = 2) else "-")
  # trigger
  brk <- part("break filter"); trig <- paste0(
    if (!is.na(basis)) paste0("The signal was ", sub("\\s*\\(measured.*$", "", strsplit(basis, ";")[[1]][1]), if (!is.null(res) && !is.na(res)) paste0(" on the ", res, " chart") else "", ". ") else sprintf("I %s when price was at %s. ", if (buy) "bought" else "sold", px(ent)),
    if (!is.na(brk)) paste0("Confirmation: ", sub("^break filter[ *]*:\\s*", "", brk, ignore.case = TRUE), ". ") else "",
    if (!is.null(ms) && nzchar(ms$window %||% "")) "I checked the releases in my trading window before entering." else "")
  # execution
  fill_at <- if (!is.na(g("entry_ts"))) tm(g("entry_ts")) else tm(g("placed_ts")); wo <- suppressWarnings(as.numeric(sv("now_px")))
  ot <- toupper(gs("order_type", "MARKET")); ol <- n("order_level")
  exe <- paste0(if (ot %in% c("MARKET", "") || !is.finite(ol)) sprintf("%s %s at the market on Capital.com (a deal, filled at once), at %s at %s UK, with the stop and the target attached to the deal. ", if (buy) "Bought" else "Sold", format(gs("size", "-")), px(ent), fill_at)
    else sprintf("I placed a %s %s order for %s at %s on Capital.com; it filled at %s at %s UK, with the stop and the target attached. ", side, tolower(ot), format(gs("size", "-")), px(ol), px(ent), fill_at),
    if (!(ot %in% c("MARKET", "")) && is.finite(ol) && is.finite(ent)) { sl <- if (buy) ent - ol else ol - ent; if (abs(sl) < 10^-d / 2) "No slippage against the order level." else sprintf("Slippage %s points %s the order level.", px(abs(sl)), if (sl > 0) "against me at" else "in my favour at") } else
    if (is.finite(wo) && is.finite(ent)) { dv <- if (buy) ent - wo else wo - ent; if (abs(dv) < 10^-d / 2) "The fill was at the price the scenario was worked out from." else sprintf("The scenario was worked out at %s, so I %s %s %s; the stop and target were moved with the price to keep their distances.", px(wo), if (buy) "bought" else "sold", px(abs(dv)), if (dv > 0) "worse" else "better") } else "")
  # stop / target
  sp <- part("^stop"); tp <- part("^target"); risk <- n("risk_account"); rew <- n("reward_account"); ccy <- gs("account_currency", "")
  money <- function(v) if (is.finite(v)) sprintf(" (%s %.2f)", ccy, v) else ""
  stopr <- paste0(if (!is.na(sp)) paste0(toupper(substr(sp, 1, 1)), substr(sp, 2, nchar(sp)), ". ") else "",
    sprintf("Stop at %s, %s points %s the entry%s.", px(stp), px(rd), if (buy) "below" else "above", money(risk)),
    if (!is.na(basis) && grepl("cancel", sp %||% "")) " Beyond that level the set-up is no longer valid." else "")
  tgtr <- paste0(if (!is.na(tp)) paste0(toupper(substr(tp, 1, 1)), substr(tp, 2, nchar(tp)), ". ") else "",
    sprintf("Target at %s, %s points from the entry%s, giving a reward to risk of %s", px(tgt), px(wd), money(rew), if (is.finite(rr)) formatC(rr, format = "f", digits = 2) else "-"),
    if (is.finite(rr) && rr > 0) sprintf(" (break-even win rate %.0f%%).", 100 / (1 + rr)) else ".")
  # exit
  code <- toupper(gs("exit_code", "")); xl <- n("exit_level"); xt <- g("exit_ts")
  exitr <- if (!identical(gs("status", ""), "CLOSED")) NA_character_ else if (startsWith(code, "T")) sprintf("The target at %s was reached at %s UK.", px(tgt), tm(xt)) else if (startsWith(code, "S"))
    sprintf("The stop at %s was hit at %s UK (closed at %s).", px(stp), tm(xt), px(xl)) else sprintf("I closed the trade at %s at %s UK before the stop or the target was reached.", px(xl), tm(xt))
  lapply(list(setup_fund = fund, setup_tech = tech, trigger_text = trig, execution_text = exe, stop_reason = stopr, target_reason = tgtr, exit_reason = exitr), function(x) if (is.na(x)) x else trimws(cc_no_ai_name(gsub("\\s+", " ", x)))) }
cc_blank <- function(x) is.null(x) || !length(x) || is.na(x[1]) || !nzchar(trimws(as.character(x[1])))

# ******************* suggestions for the six reason boxes of the Individual Trade Sheet ------------------------------------------
# The Claude API gives, per box: a suggested wording, the context behind it and a question for the trader to check. Shown in
# C. Review beside the boxes; the trader decides what to copy. Saved as a FIELD_SUGGESTIONS event; never printed on the sheet.
cc_field_names <- c(setup_fund = "Set-up (fundamental)", setup_tech = "Set-up (technical)", trigger_text = "Trigger", execution_text = "Execution",
                    stop_reason = "Reason for Stop Loss placement", target_reason = "Reason for Target Limit placement")
cc_field_prompt <- function(tr, sm, sr, pats, ms_text = NULL, auto = NULL, own = NULL) {
  g <- function(k) { v <- tr[[k]]; if (is.null(v) || !length(v) || is.na(v[1])) "-" else as.character(v[1]) }
  pl <- if (!is.null(pats) && NROW(pats)) paste(sprintf("- %s (%s, %s, record %s)", pats$Pattern, pats$Bias, pats$Status %||% "-", pats$`Measured record`), collapse = "\n") else "(no chart scan saved)"
  fx <- function(x) paste(sprintf("- %s: %s", cc_field_names[names(x)], vapply(x, function(v) if (cc_blank(v)) "(empty)" else as.character(v), "")), collapse = "\n")
  paste0("You help a trading student fill the six reason boxes of the LAT Individual Trade Sheet for one trade. The student decides what to write; you only suggest. ",
    "Use ONLY the facts below; never invent prices, times, news or patterns. If a fact is missing, say so in 'context'.\n\n",
    "TRADE: ", g("direction"), " ", g("size"), " ", g("market_name"), " (", g("epic"), "), order type ", g("order_type"), ", order level ", g("order_level"), ", filled at ", g("entry_level"), " at ", g("entry_ts"), " UTC; stop ", g("stop_initial"),
    ", target ", g("target_level"), "; risk ", g("risk_account"), " and reward ", g("reward_account"), " ", g("account_currency"), "; set-up chosen: ", g("strategy"), "; chart period ", g("chart_period"), "; status ", g("status"),
    if (!is.null(sm)) paste0("; result: ", paste(cc_summary_lines(sm), collapse = " ")) else "", ".\n",
    "SCENARIO CHOSEN WHEN THE ORDER WAS PLACED:\n", paste(cc_scenario_lines(sr), collapse = "\n"), "\n",
    "PATTERNS ON THE CHART AT ENTRY:\n", pl, "\n",
    if (!is.null(ms_text)) paste0("THE STUDENT'S MORNING SHEET FOR THAT DAY:\n", ms_text, "\n") else "MORNING SHEET: none saved for that day.\n",
    "WHAT THE APP WOULD WRITE FROM THE SAVED FACTS:\n", fx(auto %||% list()), "\n",
    "WHAT THE STUDENT HAS WRITTEN SO FAR:\n", fx(own %||% list()), "\n\n",
    "For EACH of the six boxes give: 'suggestion' = a wording the student could use, 1-3 sentences, first person, plain English, factual, as written by a trader (never mention AI, Claude, a model or an assistant); ",
    "'context' = 1-2 sentences of what the course expects in this box and which fact supports or weakens the suggestion (for example a record with few cases, a release inside the window, an entry far from the signal); ",
    "'check' = one short question the student should answer honestly before writing (for example whether they really saw the trigger before entering). ",
    "Set-up (fundamental) = the news / macro reason; Set-up (technical) = the pattern or strategy and the regime; Trigger = the exact event that made the entry; Execution = how and at what price the order was placed and filled; ",
    "Reason for Stop Loss placement = why the stop is at that level (the level that cancels the idea, ATR); Reason for Target Limit placement = why the target is there (measured target, level, R:R). ",
    "If the student already wrote a box, improve it only where the facts disagree, and say so in 'context'.\n",
    "Reply with ONE JSON object only: {\"fields\":{\"setup_fund\":{\"suggestion\":\"\",\"context\":\"\",\"check\":\"\"},\"setup_tech\":{...},\"trigger_text\":{...},\"execution_text\":{...},\"stop_reason\":{...},\"target_reason\":{...}}}") }
cc_field_parse <- function(txt) {
  j <- tryCatch(jsonlite::fromJSON(sub("(?s)^[^{]*", "", sub("(?s)[^}]*$", "", txt %||% "", perl = TRUE), perl = TRUE), simplifyVector = FALSE), error = function(e) NULL)
  f <- j$fields; if (is.null(f)) return(NULL)
  rows <- lapply(names(cc_field_names), function(k) { x <- f[[k]] %||% list(); v <- function(n) { y <- x[[n]]; if (is.null(y)) "" else trimws(as.character(y[[1]])) }
    data.frame(field = k, label = cc_field_names[[k]], suggestion = cc_no_ai_name(v("suggestion")), context = v("context"), check = v("check"), stringsAsFactors = FALSE) })
  out <- do.call(rbind, rows); if (!any(nzchar(out$suggestion))) NULL else out }
