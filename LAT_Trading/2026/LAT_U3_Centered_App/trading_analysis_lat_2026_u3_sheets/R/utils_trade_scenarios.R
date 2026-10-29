# Claude trade scenarios (Trades tab, above "A. Open a trade"): the saved Morning Sheet + a fresh IG chart screenshot
# -> one BUY and one SELL scenario with entry, stop, limit and an estimated success rate. The user picks one; only
# direction, entry, size, stop, target and the stop/target reasons go into the form (editable).

tr_scn_morning_text <- function(hdr, lv) {
  f <- function(x) if (is.null(x) || !length(x) || is.na(x[1]) || !nzchar(as.character(x[1]))) "-" else as.character(x[1])
  out <- c(sprintf("Date: %s", f(hdr$sheet_date)),
           sprintf("Dow: %s (%s%%), Nikkei: %s (%s%%)", f(hdr$dow_price), f(hdr$dow_change_pct), f(hdr$nikkei_price), f(hdr$nikkei_change_pct)),
           paste("Overnight news:", f(hdr$overnight_news)), paste("Overnight calendar:", f(hdr$overnight_calendar)),
           paste("Today's releases:", f(hdr$todays_releases)), paste("Releases in the trading window:", f(hdr$releases_in_window)),
           paste("Regime summary:", f(hdr$regime_summary)), paste("Planned set-ups:", f(hdr$planned_setups)),
           paste("Exposure:", f(hdr$exposure_note)), paste("Combined open risk %:", f(hdr$combined_open_risk_pct)))
  if (!is.null(lv) && nrow(lv)) {
    out <- c(out, "Levels (instrument | overnight low | overnight high | current | ADX14 | regime | prior H/L/C | PP R1 S1 R2 S2):")
    for (i in seq_len(nrow(lv))) { r <- lv[i, ]
      out <- c(out, sprintf("%s | %s | %s | %s | %s | %s | %s/%s/%s | %s %s %s %s %s", r$instrument, f(r$overnight_low), f(r$overnight_high), f(r$current_price),
                            f(r$adx14), f(r$regime_label), f(r$prior_high), f(r$prior_low), f(r$prior_close),
                            f(round(r$pivot_pp, 1)), f(round(r$pivot_r1, 1)), f(round(r$pivot_s1, 1)), f(round(r$pivot_r2, 1)), f(round(r$pivot_s2, 1)))) }
  }
  paste(out, collapse = "\n")
}

tr_scn_prompt <- function(asset, price, size, morning_txt, duration_h = NA, notes = "", chart = NULL, has_image = TRUE, risk = NULL) {
  rg <- if (!is.null(risk) && is.finite(risk$pct %||% NA) && is.finite(risk$equity %||% NA)) risk$equity * risk$pct / 100 else NA
  paste0(
    "You are helping a trading student on an IG DEMO spread-bet account prepare two alternative trade scenarios. ",
    if (has_image) paste0("The image is the student's current IG candle chart of ", asset, ". ") else "", "Prices are IG points.\n\n",
    if (!is.null(chart)) paste0("Recent price candles of ", asset, " (", chart$what, "), oldest first:\n", chart$bars, "\n\n",
                                "Chart patterns found by the app's rules: only multi-candle structures that run up to the last candle (trend by Dow Theory, support/resistance ",
                                "and role reversals, trend lines, channels, Fibonacci, triangles, wedges, flags, double tops/bottoms, head & shoulders), judged with the course rules, ",
                                "Bulkowski and TrendSpider guidelines; each with its bias, the level whose close beyond it cancels it, and its measured target:\n",
                                chart$patterns, "\n", if (!is.null(chart$decision)) paste0("App's chart bias (score-weighted vote of the patterns): ", chart$decision, "\n"), "\n") else "",
    "Current price (given by the student): ", price, "\n",
    if (is.finite(size)) paste0("Size: GBP ", size, " per point\n") else if (is.finite(rg)) paste0("Size: not fixed; the student risks GBP ", round(rg, 2), " per trade (", risk$pct, "% of equity GBP ", round(risk$equity), "). Give risk_gbp and reward_gbp at the size that risks that amount (size = GBP risk / stop distance in points).\n") else "",
    if (is.finite(duration_h)) paste0("Planned holding time: about ", duration_h, " hours\n") else "",
    if (nzchar(notes)) paste0("Student notes: ", notes, "\n") else "",
    "\nThe student's Morning Sheet for today:\n", morning_txt, "\n\n",
    "Read the chart (", if (has_image) "the image" else "", if (has_image && !is.null(chart)) " and " else "", if (!is.null(chart)) "the candles above" else "", ": recent swing highs/lows, trend, support and resistance), weigh the patterns listed ",
    "(the side they agree on, and where they conflict), put each stop beyond the cancelling level of the pattern(s) the scenario follows and each limit at or before their target or the next level, and use the Morning Sheet levels ",
    "(pivots, prior high/low/close, overnight range, ADX regime, releases in the window).\n",
    "Return ONE BUY scenario and ONE SELL scenario, both entered at the current price. For each give a stop and a limit at ",
    "real chart or sheet levels (a stop is beyond a level, not at it), the reward:risk, the GBP risk and reward at the given size, and an ",
    "estimated probability (0-100) that the limit is hit before the stop. Be honest: the two probabilities may both be low, and say ",
    "which levels you used. Do not invent figures you cannot see.\n",
    "Reply with JSON only, no other text:\n",
    '{"chart_read":"<what you see on the chart, 1-2 sentences>","scenarios":[',
    '{"side":"BUY","entry":0,"stop":0,"limit":0,"reward_risk":0,"risk_gbp":0,"reward_gbp":0,"success_pct":0,"basis":"<levels used and why, 2-3 sentences>","stop_reason":"<why the stop sits at that level: the chart/sheet level it is beyond and the buffer, 1-2 sentences>","target_reason":"<why the limit sits at that level: the chart/sheet level it targets, 1-2 sentences>","risks":"<main risk, e.g. a release in the window>"},',
    '{"side":"SELL","entry":0,"stop":0,"limit":0,"reward_risk":0,"risk_gbp":0,"reward_gbp":0,"success_pct":0,"basis":"...","stop_reason":"...","target_reason":"...","risks":"..."}]}')
}

# reply text -> data.frame(side, entry, stop, limit, reward_risk, risk_gbp, reward_gbp, success_pct, basis, risks) + attr chart_read
tr_scn_parse <- function(txt, price = NA, size = NA, risk_gbp = NA) {
  j <- tr_parse_vision_json(txt); if (is.null(j) || !length(j$scenarios)) return(NULL)
  n <- function(x) suppressWarnings(as.numeric(if (is.null(x)) NA else x))
  s <- function(x) if (is.null(x)) "" else as.character(x)
  rows <- lapply(j$scenarios, function(z) {
    side <- toupper(s(z$side)); side <- if (grepl("^B", side)) "BUY" else if (grepl("^S", side)) "SELL" else NA
    en <- n(z$entry); if (!is.finite(en) || en == 0) en <- n(price)
    st <- n(z$stop); lm <- n(z$limit)
    risk <- abs(en - st); rew <- abs(lm - en)
    sp <- if (is.finite(risk_gbp) && is.finite(risk) && risk > 0) floor(risk_gbp / risk * 10) / 10 else NA_real_   # size that risks the plan's GBP (rounded down to 0.1)
    sz <- if (is.finite(size)) size else sp
    data.frame(side = side, entry = en, stop = st, limit = lm, size = sz, size_plan = sp,
               reward_risk = if (is.finite(risk) && risk > 0) round(rew / risk, 2) else n(z$reward_risk),
               risk_gbp = if (is.finite(sz)) round(risk * sz, 2) else n(z$risk_gbp),
               reward_gbp = if (is.finite(sz)) round(rew * sz, 2) else n(z$reward_gbp),
               success_pct = n(z$success_pct), basis = s(z$basis), stop_reason = s(z$stop_reason), target_reason = s(z$target_reason), risks = s(z$risks), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows); out <- out[!is.na(out$side), , drop = FALSE]
  # a scenario whose stop/limit are on the wrong side of the entry is flagged
  ok <- ifelse(out$side == "BUY", out$stop < out$entry & out$limit > out$entry, out$stop > out$entry & out$limit < out$entry)
  out$valid <- !is.na(ok) & ok
  attr(out, "chart_read") <- s(j$chart_read)
  if (!nrow(out)) NULL else out
}

# ---- LLM analysis of a finished (or running) trade: Morning Sheet + full trade record + tagged pictures
tr_exit_code_meanings <- c("T" = "T: the target (limit) was hit", "S1" = "S1: the initial stop loss was hit",
                           "S2+" = "S2+: a moved (trailing) stop was hit", "ME" = "ME: manual exit (closed by hand before stop or target)")
tr_exit_code_choices <- c("(not set)" = "", setNames(names(tr_exit_code_meanings), unname(tr_exit_code_meanings)))

tr_trade_record_text <- function(r, legs = NULL, events = NULL) {
  f <- function(x) if (is.null(x) || !length(x) || is.na(x[1]) || !nzchar(as.character(x[1]))) "-" else as.character(x[1])
  tm <- function(x) if (is.null(x) || !length(x) || is.na(x[1])) "-" else format(x[1], "%Y-%m-%d %H:%M", tz = "Europe/London")
  out <- c(sprintf("Trade %s | %s | %s | status %s | %s", f(r$trade_id), f(r$asset), if (identical(r$direction, "B")) "BUY" else "SELL", f(r$status), f(r$trade_purpose)),
           sprintf("Entry %s UK at %s | stop %s | target %s | GBP %s per point | chart %s", tm(r$entry_ts), f(r$entry_price), f(r$stop1), f(r$target), f(r$stake_per_pip_gbp), f(r$chart_period)),
           sprintf("Initial risk %s pips (GBP %s), reward %s pips, R:R %s", f(r$initial_risk_pips), f(r$initial_risk_gbp), f(r$initial_reward_pips), f(r$initial_rrr)),
           paste("Set-up (fundamental):", f(r$setup_fundamental)), paste("Set-up (technical):", f(r$setup_technical)),
           paste("Trigger:", f(r$trigger_text)), paste("Execution:", f(r$execution_text)),
           paste("Stop reason:", f(r$stop_reason)), paste("Target reason:", f(r$target_reason)))
  if (!is.null(events) && nrow(events)) out <- c(out, "In-trade actions:", sprintf("- %s %s new stop %s price %s", tm(events$event_ts), events$event_type, events$new_stop, events$price))
  if (!is.null(legs) && nrow(legs)) out <- c(out, "Closed legs:", sprintf("- exit %s UK at %s | pips %s | P/L GBP %s | exit code %s", vapply(seq_len(nrow(legs)), function(i) tm(legs$exit_ts[i]), ""),
                                                                legs$exit_price, legs$pips_result, legs$net_pnl_gbp, legs$exit_code))
  else if (is.finite(suppressWarnings(as.numeric(r$exit_price)))) out <- c(out, sprintf("Exit %s UK at %s | P/L GBP %s | exit code %s", tm(r$exit_ts), f(r$exit_price), f(r$net_pnl_gbp), f(r$exit_code)))
  paste(out, collapse = "\n")
}

tr_trade_analysis_prompt <- function(trade_txt, morning_txt, pic_list) {
  paste0(
    "You are reviewing a trade by a trading student on an IG DEMO spread-bet account (prices in IG points). ",
    "The images are the student's screenshots, in this order:\n", paste(sprintf("Image %d: %s", seq_along(pic_list), pic_list), collapse = "\n"), "\n\n",
    "The trade record:\n", trade_txt, "\n\nThe Morning Sheet of the day:\n", morning_txt, "\n\n",
    "Use only what is in the record, the Morning Sheet and the images (the 'Outcome of Trade' image is the IG history row: its closing price and amount are the facts of the result).\n",
    "Exit date and time: take them only from an image or the record (IG history shows the date; an Activity or chart tooltip may show the time). If the time is not visible, return \"\" for exit_time_uk; never guess. Unknown numbers: null.\n",
    "1. exit_code: T if the limit/target was hit, S1 if the initial stop was hit, S2+ if a moved stop was hit, ME if closed by hand before either. ",
    "Compare the closing price with the stop and target (allow the spread). If the trade is not closed, return \"\".\n",
    "2. reason_for_exit: 1-3 factual sentences: what closed the trade (limit, stop or other condition), at what price and time, and what the chart shows at that moment.\n",
    "3. overall_analysis: 5-8 sentences: was the set-up valid against the Morning Sheet (regime, levels, releases in the window), how price moved after entry, ",
    "whether the stop and target placement worked, what the result was in pips and GBP, and the main factor behind the outcome. Neutral and factual; do not invent figures.\n",
    "Reply with JSON only:\n",
    '{"exit_code":"T|S1|S2+|ME|","exit_price":0,"exit_date_uk":"YYYY-MM-DD","exit_time_uk":"HH:MM","pnl_gbp":0,"reason_for_exit":"...","overall_analysis":"..."}')
}

tr_trade_analysis_parse <- function(txt) {
  j <- tr_parse_vision_json(txt); if (is.null(j)) return(NULL)
  s <- function(x) if (is.null(x)) "" else trimws(as.character(x))
  code <- toupper(s(j$exit_code)); if (!code %in% names(tr_exit_code_meanings)) code <- ""
  nz <- function(x) { v <- suppressWarnings(as.numeric(s(x))); if (length(v) != 1 || !is.finite(v) || v == 0) NA_real_ else v }
  list(exit_code = code, exit_price = nz(j$exit_price), exit_time_uk = s(j$exit_time_uk), exit_date = tryCatch(as.Date(s(j$exit_date_uk)), error = function(e) as.Date(NA)),
       pnl_gbp = { v <- suppressWarnings(as.numeric(s(j$pnl_gbp))); if (length(v) == 1) v else NA_real_ }, reason_for_exit = s(j$reason_for_exit), overall_analysis = s(j$overall_analysis))
}

# latest saved overall analysis of a trade (trading_evidence, kind trade_analysis)
tr_trade_analysis_of <- function(evidence, trade_id) {
  if (is.null(evidence) || !nrow(evidence) || !"kind" %in% names(evidence)) return(NULL)
  e <- evidence[!is.na(evidence$kind) & evidence$kind == "trade_analysis" & !is.na(evidence$trade_id) & evidence$trade_id == trade_id & !(evidence$status %in% "DISCARDED"), , drop = FALSE]
  if (!nrow(e)) return(NULL)
  if ("saved_at" %in% names(e)) e <- e[order(e$saved_at, decreasing = TRUE), , drop = FALSE]
  tryCatch(jsonlite::fromJSON(e$extracted_json[1]), error = function(err) NULL)
}
