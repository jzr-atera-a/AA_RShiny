# R/utils_trading_exports.R
# Exports that put the numbers you recorded into the layouts of the LAT documents:
#   - Trade Blotter (Excel, same columns A-AK as the Blotter's "Trade Blotter" sheet)
#   - Individual Trade Sheet (Word, one trade, your own text and chart pictures)
#   - Morning Sheet (Word, one day)
#   - Statistics workbook (Excel)
# Nothing is invented: every cell comes from a record you saved. Reasoning fields (set-up, trigger,
# reasons, lessons) are your own text exactly as you saved it; empty stays empty.

tr_need <- function(pkg) if (!requireNamespace(pkg, quietly = TRUE)) stop("The package '", pkg, "' is needed for this export. Install it with install.packages('", pkg, "').", call. = FALSE)

tr_local_naive <- function(ts) {   # POSIXct -> same wall-clock time in London, stored as naive UTC for Excel
  ok <- !is.na(ts); out <- as.POSIXct(rep(NA_real_, length(ts)), origin = "1970-01-01", tz = "UTC")
  if (any(ok)) out[ok] <- as.POSIXct(format(ts[ok], "%Y-%m-%d %H:%M:%S", tz = "Europe/London"), tz = "UTC")
  out
}
tr_hhmm <- function(ts) ifelse(is.na(ts), "", format(ts, "%H%M", tz = "Europe/London"))
tr_ddmmyyyy <- function(ts) ifelse(is.na(ts), "", format(ts, "%d/%m/%Y", tz = "Europe/London"))
tr_hours_text <- function(h) { if (!is.finite(h)) return(""); m <- round(h * 60); sprintf("%dHr %02dMin", m %/% 60, m %% 60) }
tr_pips_at <- function(entry, stop, dir, pip) ifelse(is.finite(stop) & is.finite(entry) & is.finite(pip) & pip > 0, (entry - stop) * tr_dir(dir) / pip, NA_real_)

# Which trades to include: "ASSESSED" (default; blank purpose counts as assessed), "PRACTICE" or "ALL".
tr_scope_filter <- function(t, scope = "ASSESSED") {
  if (is.null(t) || !nrow(t) || identical(scope, "ALL")) return(t)
  p <- ifelse(is.na(t$trade_purpose) | !nzchar(t$trade_purpose), "ASSESSED", toupper(t$trade_purpose))
  t[p == scope, , drop = FALSE]
}

# ---- Trade Blotter -------------------------------------------------------------------------
tr_blotter_cols <- c("Asset", "Date", "Mood (1-5)", "B/S", "£/pip", "Open @", "Stop 1", "Pip Risk", "Stop 2", "Pip Risk", "Stop 3", "Pip Risk",
                     "Stop 3", "Pip Risk", "Target", "Pip Risk", "Initial Risk", "Initial Reward", "INITIAL RRR", "ACTUAL RRR", "Closed @", "Date/Time",
                     "Exit", "ME + Hit Stop", "ME + Hit Target", "P/L  gained or lost", "Duration (Hours)", "Net P/L (£)", "P/L (Pips)", "Running P/L",
                     "Trade Sheet Name", "Patterns (10)", "S/R (10)", "Candles (3)", "RSI (3)", "Fibs (3)", "TOTAL")

# Values for the input columns (what you type into the Blotter); the formula columns are added when written.
tr_blotter_frame <- function(trades) {
  t <- trades[trades$status == "CLOSED" & !is.na(trades$exit_ts), , drop = FALSE]
  t <- t[order(t$entry_ts), , drop = FALSE]; n <- nrow(t)
  g <- function(col) if (col %in% names(t)) t[[col]] else rep(NA, n)
  flag <- function(x) ifelse(isTRUE_vec(x), "Y", NA_character_)
  isTRUE_vec <- function(x) !is.na(x) & x
  pip <- g("pip_size"); dir <- g("direction"); e <- g("entry_price")
  data.frame(asset = g("asset"), date = tr_local_naive(g("entry_ts")), mood = g("mood_entry"), bs = dir, per_pip = g("stake_per_pip_gbp"),
    open = e, stop1 = g("stop1"), risk1 = g("initial_risk_pips"), stop2 = g("stop2"), risk2 = tr_pips_at(e, g("stop2"), dir, pip),
    stop3 = g("stop3"), risk3 = tr_pips_at(e, g("stop3"), dir, pip), stop4 = g("stop4"), risk4 = tr_pips_at(e, g("stop4"), dir, pip),
    target = g("target"), reward_pips = g("initial_reward_pips"), closed = g("exit_price"), exit_dt = tr_local_naive(g("exit_ts")),
    exit_code = g("exit_code"), me_stop = flag(g("me_then_hit_stop")), me_target = flag(g("me_then_hit_target")),
    net = g("net_pnl_gbp"), pips = g("pips_result"),
    patterns = g("score_patterns"), sr = g("score_sr"), candles = g("score_candles"), rsi = g("score_rsi"), fibs = g("score_fibs"),
    trade_sheet = g("trade_sheet_name"), stringsAsFactors = FALSE)
}

tr_write_blotter <- function(trades, file, name = "") {
  tr_need("openxlsx")
  f <- tr_blotter_frame(trades); n <- nrow(f); first <- 4L; last <- first + max(n, 1L) - 1L
  wb <- openxlsx::createWorkbook(); sh <- "Trade Blotter"; openxlsx::addWorksheet(wb, sh)
  hs <- openxlsx::createStyle(textDecoration = "bold", fgFill = "#002C3C", fontColour = "#FFFFFF", wrapText = TRUE, halign = "center")
  openxlsx::writeData(wb, sh, "TRADE BLOTTER", startCol = 4, startRow = 1)
  openxlsx::writeData(wb, sh, paste0("Exported from your records", if (nzchar(name)) paste0(" - ", name) else "", ". Values only come from trades you saved."), startCol = 12, startRow = 1)
  openxlsx::writeData(wb, sh, as.data.frame(t(tr_blotter_cols), stringsAsFactors = FALSE), startRow = 3, colNames = FALSE)
  openxlsx::addStyle(wb, sh, hs, rows = 3, cols = 1:37, gridExpand = TRUE)
  if (n) {
    colmap <- c(A = "asset", B = "date", C = "mood", D = "bs", E = "per_pip", F = "open", G = "stop1", H = "risk1", I = "stop2", J = "risk2", K = "stop3",
                L = "risk3", M = "stop4", N = "risk4", O = "target", P = "reward_pips", U = "closed", V = "exit_dt", W = "exit_code", X = "me_stop",
                Y = "me_target", AB = "net", AC = "pips", AF = "patterns", AG = "sr", AH = "candles", AI = "rsi", AJ = "fibs")
    for (cl in names(colmap)) {
      ci <- openxlsx::convertFromExcelRef(cl)
      openxlsx::writeData(wb, sh, f[[colmap[[cl]]]], startCol = ci, startRow = first, colNames = FALSE)
    }
    rows <- first:last
    fm <- function(tmpl) sprintf(tmpl, rows, rows, rows, rows, rows)
    openxlsx::writeFormula(wb, sh, sprintf("-(E%d*H%d)", rows, rows), startCol = 17, startRow = first)                     # Q initial risk
    openxlsx::writeFormula(wb, sh, sprintf("E%d*P%d", rows, rows), startCol = 18, startRow = first)                        # R initial reward
    openxlsx::writeFormula(wb, sh, sprintf("IF(Q%d=0,\"\",ABS(R%d/Q%d))", rows, rows, rows), startCol = 19, startRow = first) # S initial RRR
    openxlsx::writeFormula(wb, sh, sprintf("IF(AB%d>0,AB%d/ABS(Q%d),\"\")", rows, rows, rows), startCol = 20, startRow = first) # T actual RRR
    openxlsx::writeFormula(wb, sh, sprintf("IF(Y%d=\"Y\",AB%d-R%d,IF(X%d=\"Y\",AB%d-Q%d,\"\"))", rows, rows, rows, rows, rows, rows), startCol = 26, startRow = first) # Z
    openxlsx::writeFormula(wb, sh, sprintf("(V%d-B%d)*24", rows, rows), startCol = 27, startRow = first)                   # AA duration
    openxlsx::writeFormula(wb, sh, sprintf("SUM($AB$%d:AB%d)", first, rows), startCol = 30, startRow = first)              # AD running P/L
    openxlsx::writeFormula(wb, sh, sprintf("IF(A%d<>\"\",A%d&\" - \"&TEXT(B%d,\"dd/mm/yyyy hh:mm\"),\"\")", rows, rows, rows), startCol = 31, startRow = first) # AE
    openxlsx::writeFormula(wb, sh, sprintf("SUM(AF%d:AJ%d)", rows, rows), startCol = 37, startRow = first)                 # AK
    openxlsx::addStyle(wb, sh, openxlsx::createStyle(numFmt = "dd/mm/yyyy hh:mm"), rows = rows, cols = c(2, 22), gridExpand = TRUE)
  }
  openxlsx::setColWidths(wb, sh, cols = 1:37, widths = 12); openxlsx::setColWidths(wb, sh, cols = 31, widths = 28)
  openxlsx::freezePane(wb, sh, firstActiveRow = 4, firstActiveCol = 2)
  openxlsx::addWorksheet(wb, "Read me")
  notes <- c("This sheet has the same columns (A to AK) as the Trade Blotter sheet in the LAT workbook.",
    "Columns you type in the LAT Blotter are filled from your records: A-P, U-Y, AB, AC and AF-AJ. The formula columns (Q-T, Z, AA, AD, AE, AK) are included with the same logic so you can compare.",
    "Pip Risk (H, J, L, N, P) are written as numbers in pips: for IG spread-bet prices one pip is one point. The LAT workbook's own Pip Risk formula multiplies by 10,000 for currency pairs; for commodities, indices and IG points use the numbers from this file rather than that formula.",
    "ME + Hit Stop / ME + Hit Target: filled only where you recorded, for a manual exit, that the market then reached your stop or your target.",
    "Pattern / S/R / Candles / RSI / Fibs scores are yours: they are filled only if you entered them.",
    "The Equity Curve, PnL, RRR, Asset Based and Other Stats sheets of the LAT workbook recalculate from the Trade Blotter sheet; copy the input columns into your LAT workbook to use them.",
    "Practice trades are excluded unless you chose 'All trades'.")
  openxlsx::writeData(wb, "Read me", data.frame(Notes = notes)); openxlsx::setColWidths(wb, "Read me", cols = 1, widths = 120)
  openxlsx::saveWorkbook(wb, file, overwrite = TRUE); invisible(file)
}

# ---- Word helpers ---------------------------------------------------------------------------
tr_img_dim <- function(path, width_in = 6) {
  h <- 0.56 * width_in
  d <- tryCatch({
    ext <- tolower(tools::file_ext(path))
    if (ext == "png" && requireNamespace("png", quietly = TRUE)) dim(png::readPNG(path))[1:2]
    else if (ext %in% c("jpg", "jpeg") && requireNamespace("jpeg", quietly = TRUE)) dim(jpeg::readJPEG(path))[1:2]
    else NULL }, error = function(e) NULL)
  if (!is.null(d) && all(d > 0)) h <- width_in * d[1] / d[2]
  c(width_in, min(h, 8))
}
tr_doc_chart <- function(doc, label, path = NULL) {
  doc <- tr_doc_h(doc, label, 3)
  if (!is.null(path) && length(path) == 1 && !is.na(path) && file.exists(path)) {
    d <- tr_img_dim(path); officer::body_add_img(doc, src = path, width = d[1], height = d[2])
  } else officer::body_add_par(doc, "[Insert chart picture here]")
}
tr_doc_table <- function(doc, df) officer::body_add_table(doc, df, header = TRUE, style = "Table Professional", alignment = rep("l", ncol(df)))
tr_doc_h <- function(doc, text, level = 2) { if (level <= 2) doc <- officer::body_add_par(doc, ""); officer::body_add_fpar(doc, officer::fpar(officer::ftext(text, officer::fp_text(bold = TRUE, color = "#002C3C", font.size = c(18, 14, 12)[level]))))}
tr_txt <- function(x) { x <- as.character(x); ifelse(is.na(x), "", x) }
tr_numtxt <- function(x, d = 2) ifelse(is.finite(x), formatC(x, format = "f", digits = d), "")
tr_trim0 <- function(z) ifelse(grepl("\\.", z), sub("\\.$", "", sub("0+$", "", z)), z)   # 10375.50000 -> 10375.5 ; 3.00 -> 3 ; 1130 stays
tr_ntrim <- function(x, d = 5) tr_trim0(tr_numtxt(x, d))

# ---- Individual Trade Sheet (Word) ----------------------------------------------------------
# `trade` = the trade row (the opening record); `legs` = closed rows to list in the exit table
# (the trade itself, or its partial-exit legs); `events` = stop moves / partial exits; `charts` =
# named list of image paths: tf4h, tf1h, tf15m, tf5m, trade, exit, post.
tr_trade_sheet_basic <- function(trade, legs, events, name, charts = list(), file) {
  tr_need("officer")
  stopifnot(nrow(trade) == 1)
  doc <- officer::read_docx()
  doc <- tr_doc_h(doc, "Individual Trade Sheet", 1)
  doc <- tr_doc_table(doc, data.frame(`Name:` = name, check.names = FALSE, stringsAsFactors = FALSE))
  doc <- tr_doc_h(doc, "Trade Entry", 2)
  info <- data.frame(Item = c("Chart Period", "Expected Trade Duration", "Initial Risk (pips)", "Initial Reward (pips)", "Initial RRR"),
    Value = c(tr_txt(trade$chart_period), tr_hours_text(trade$expected_duration_hours), tr_numtxt(trade$initial_risk_pips, 1), tr_numtxt(trade$initial_reward_pips, 1), tr_numtxt(trade$initial_rrr, 2)), stringsAsFactors = FALSE)
  doc <- tr_doc_table(doc, info)
  doc <- officer::body_add_par(doc, "")
  ent <- data.frame(Date = tr_ddmmyyyy(trade$entry_ts), Time = tr_hhmm(trade$entry_ts), `B/S` = trade$direction, Asset = trade$asset,
                    `Lot Size` = tr_ntrim(trade$stake_per_pip_gbp, 2), Price = tr_ntrim(trade$entry_price), `Stop Loss` = tr_ntrim(trade$stop1),
                    Target = tr_ntrim(trade$target), check.names = FALSE, stringsAsFactors = FALSE)
  doc <- tr_doc_table(doc, ent)
  doc <- officer::body_add_par(doc, "")
  stem <- data.frame(Item = c("Set-up (fundamental)", "Set-up (technical)", "Trigger", "Execution", "Reason for Stop Loss placement", "Reason for Target Limit placement"),
    `Your text` = c(tr_txt(trade$setup_fundamental), tr_txt(trade$setup_technical), tr_txt(trade$trigger_text), tr_txt(trade$execution_text), tr_txt(trade$stop_reason), tr_txt(trade$target_reason)),
    check.names = FALSE, stringsAsFactors = FALSE)
  doc <- tr_doc_table(doc, stem)
  doc <- tr_doc_chart(doc, "4 Hour", charts$tf4h); doc <- tr_doc_chart(doc, "1 Hour", charts$tf1h)
  doc <- tr_doc_chart(doc, "15 Min", charts$tf15m); doc <- tr_doc_chart(doc, "5 Min", charts$tf5m)
  doc <- tr_doc_h(doc, "In Trade Management", 2)
  if (!is.null(events) && nrow(events)) {
    events <- events[order(events$event_ts), , drop = FALSE]
    for (i in seq_len(nrow(events))) {
      ev <- events[i, ]
      line <- if (identical(ev$event_type, "STOP_MOVE")) {
        pr <- tr_pips_at(trade$entry_price, ev$new_stop, trade$direction, trade$pip_size)
        sprintf("%s %s: stop moved from %s to %s (%s)%s", tr_ddmmyyyy(ev$event_ts), tr_hhmm(ev$event_ts), tr_ntrim(ev$old_stop), tr_ntrim(ev$new_stop),
                if (is.finite(pr)) (if (pr > 0) sprintf("%.1f pips of risk", pr) else sprintf("%.1f pips of profit locked", -pr)) else "",
                if (!is.na(ev$reason) && nzchar(ev$reason)) paste0(". Your reason: ", ev$reason) else "")
      } else sprintf("%s %s: part of the position closed (%s per pip) at %s%s", tr_ddmmyyyy(ev$event_ts), tr_hhmm(ev$event_ts), tr_ntrim(ev$size_closed_per_pip, 2), tr_ntrim(ev$price),
                     if (!is.na(ev$reason) && nzchar(ev$reason)) paste0(". Your reason: ", ev$reason) else "")
      doc <- officer::body_add_par(doc, line)
    }
  } else doc <- officer::body_add_par(doc, "No stop moves or partial exits were recorded for this trade.")
  doc <- tr_doc_chart(doc, "In-trade chart (if applicable)", charts$trade)
  doc <- tr_doc_h(doc, "Trade Exit", 2)
  dur <- if (nrow(legs)) max(legs$duration_hours, na.rm = TRUE) else NA_real_
  doc <- officer::body_add_par(doc, paste("Actual Trade Duration:", if (is.finite(dur)) tr_hours_text(dur) else ""))
  if (nrow(legs)) {
    opp <- ifelse(legs$direction == "B", "S", "B")
    ex <- data.frame(Date = tr_ddmmyyyy(legs$exit_ts), Time = tr_hhmm(legs$exit_ts), `B/S` = opp, Asset = legs$asset, `Lot Size` = tr_ntrim(legs$stake_per_pip_gbp, 2),
                     `Entry Price` = tr_ntrim(legs$entry_price), `Exit Price` = tr_ntrim(legs$exit_price), Pips = tr_numtxt(legs$pips_result, 1),
                     `Profit / (Loss) £` = tr_numtxt(legs$net_pnl_gbp, 2), check.names = FALSE, stringsAsFactors = FALSE)
    doc <- tr_doc_table(doc, ex)
  } else doc <- officer::body_add_par(doc, "The trade is not closed yet.")
  last <- if (nrow(legs)) legs[which.max(legs$exit_ts), ] else trade
  fin <- data.frame(Item = c("Reason for Exit", "Lessons learned"), `Your text` = c(tr_txt(last$reason_for_exit), tr_txt(last$lessons_learned)), check.names = FALSE, stringsAsFactors = FALSE)
  doc <- tr_doc_table(doc, fin)
  doc <- tr_doc_chart(doc, "Exit chart", charts$exit); doc <- tr_doc_chart(doc, "Post Exit", charts$post)
  print(doc, target = file); invisible(file)
}

# ---- Morning Sheet (Word) -------------------------------------------------------------------
tr_morning_rows <- function(levels) {
  tmpl <- c(EURUSD = "EUR-USD", USDJPY = "USD-JPY", GBPUSD = "GBP-USD", AUDUSD = "AUD-USD", WTI = "WTI Crude", GOLD = "Gold")
  fx <- c("EURUSD", "USDJPY", "GBPUSD", "AUDUSD"); cm <- c("WTI", "GOLD")
  row <- function(code) {
    r <- if (!is.null(levels) && nrow(levels)) levels[levels$instrument == code, , drop = FALSE] else NULL
    lab <- if (code %in% names(tmpl)) tmpl[[code]] else tr_asset_label(code)
    if (is.null(r) || !nrow(r)) return(data.frame(Overnight = lab, Low = "", High = "", `Current Price` = "", `Time Now` = "", check.names = FALSE, stringsAsFactors = FALSE))
    r <- r[1, ]; data.frame(Overnight = lab, Low = tr_ntrim(r$overnight_low), High = tr_ntrim(r$overnight_high), `Current Price` = tr_ntrim(r$current_price),
                            `Time Now` = tr_txt(r$time_now_uk), check.names = FALSE, stringsAsFactors = FALSE)
  }
  trim <- function(d) d
  extra <- if (!is.null(levels) && nrow(levels)) setdiff(levels$instrument, c(fx, cm)) else character(0)
  list(fx = trim(do.call(rbind, lapply(fx, row))),
       cm = trim(do.call(rbind, lapply(c(cm, extra), row))))
}
tr_morning_basic <- function(sheet, levels, name, file) {
  tr_need("officer"); stopifnot(nrow(sheet) == 1)
  doc <- officer::read_docx()
  doc <- tr_doc_h(doc, "Morning Sheet - Overnight Markets & Today's Macro Data", 1)
  doc <- tr_doc_table(doc, data.frame(Item = c("Name:", "Date:"), Value = c(name, format(sheet$sheet_date, "%d/%m/%Y")), stringsAsFactors = FALSE))
  chg <- function(p, pts) { a <- c(if (is.finite(p)) sprintf("%+.2f%%", p), if (is.finite(pts)) sprintf("%+.2f", pts)); paste(a, collapse = "  /  ") }
  doc <- officer::body_add_par(doc, "")
  doc <- tr_doc_table(doc, data.frame(Overnight = c("Dow Jones", "Nikkei"), Price = c(tr_numtxt(sheet$dow_price, 2), tr_numtxt(sheet$nikkei_price, 2)),
                                      Change = c(chg(sheet$dow_change_pct, sheet$dow_change_pts), chg(sheet$nikkei_change_pct, sheet$nikkei_change_pts)), stringsAsFactors = FALSE))
  rows <- tr_morning_rows(levels)
  doc <- officer::body_add_par(doc, ""); doc <- tr_doc_table(doc, rows$fx)
  doc <- officer::body_add_par(doc, ""); doc <- tr_doc_table(doc, rows$cm)
  doc <- tr_doc_h(doc, "Fundamental News", 2)
  doc <- tr_doc_table(doc, data.frame(`Overnight news` = tr_txt(sheet$overnight_news), check.names = FALSE, stringsAsFactors = FALSE))
  doc <- tr_doc_h(doc, "Economic Calendar from overnight", 3)
  doc <- officer::body_add_par(doc, tr_txt(sheet$overnight_calendar))
  doc <- tr_doc_table(doc, data.frame(`Today's Data Releases` = tr_txt(sheet$todays_releases), check.names = FALSE, stringsAsFactors = FALSE))
  doc <- tr_doc_h(doc, "Economic Calendar for today", 3)
  doc <- officer::body_add_par(doc, "(paste the calendar above, or keep the text saved here)")
  print(doc, target = file); invisible(file)
}

# ---- Statistics workbook --------------------------------------------------------------------
tr_stats_xlsx <- function(trades, opening, file, name = "") {
  tr_need("openxlsx")
  cl <- trades[trades$status == "CLOSED" & !is.na(trades$net_pnl_gbp), , drop = FALSE]
  s <- tr_stats(cl, opening); wb <- openxlsx::createWorkbook()
  put <- function(sheet, df) { openxlsx::addWorksheet(wb, sheet); openxlsx::writeData(wb, sheet, df); openxlsx::setColWidths(wb, sheet, cols = seq_len(max(1, ncol(df))), widths = "auto") }
  if (is.null(s)) put("Summary", data.frame(Message = "No closed trades yet.")) else {
    sm <- s$summary; put("Summary", data.frame(Measure = names(sm), Value = vapply(sm, function(v) as.character(round(v, 4)), ""), stringsAsFactors = FALSE))
    put("By asset", s$by_asset); put("By strategy", s$by_strategy); put("By exit code", s$by_exit); put("By weekday", s$by_weekday)
    put("By entry time", s$by_hour); if (!is.null(s$by_mood)) put("By mood", s$by_mood)
    e <- s$equity; e$exit_ts <- format(e$exit_ts, "%d/%m/%Y %H:%M", tz = "Europe/London"); put("Equity", e)
    cols <- intersect(c("trade_sheet_name", "trade_purpose", "asset", "asset_class", "market", "contract_type", "strategy", "direction", "entry_price", "stop1", "target", "initial_risk_pips", "initial_reward_pips",
                        "initial_rrr", "exit_price", "exit_code", "pips_result", "net_pnl_gbp", "real_r", "duration_hours", "plan_followed", "deviation_type", "week_no"), names(s$trades))
    put("Trades", s$trades[, cols, drop = FALSE])
    dv <- cl[cl$plan_followed %in% FALSE, intersect(c("trade_sheet_name", "deviation_type", "deviation_note", "reason_for_exit"), names(cl)), drop = FALSE]
    put("Deviations (your text)", if (nrow(dv)) dv else data.frame(Message = "No deviations recorded."))
  }
  openxlsx::saveWorkbook(wb, file, overwrite = TRUE); invisible(file)
}

# ---- public entry points: use the real LAT templates when they are in www/templates, else the plain layout
tr_chart_list <- function(charts) {   # accepts entry/trade/exit vectors, or the older single slots
  v <- function(...) { x <- unlist(list(...), use.names = FALSE); x[!is.na(x) & nzchar(x)] }
  list(entry = v(charts$entry, charts$tf4h, charts$tf1h, charts$tf15m, charts$tf5m), trade = v(charts$trade), exit = v(charts$exit, charts$post))
}
# Pictures as a frame (slot, event_id, caption, path). Accepts that frame, or the older list(entry =, trade =, exit =).
tr_chart_frame <- function(charts) {
  empty <- data.frame(slot = character(0), event_id = character(0), caption = character(0), path = character(0), stringsAsFactors = FALSE)
  if (is.data.frame(charts)) {
    if (!nrow(charts)) return(empty)
    d <- data.frame(slot = charts$slot, event_id = if ("event_id" %in% names(charts)) charts$event_id else NA_character_,
                    caption = if ("caption" %in% names(charts)) charts$caption else NA_character_, path = charts$path, stringsAsFactors = FALSE)
    return(d[!is.na(d$path) & file.exists(d$path), , drop = FALSE])
  }
  ch <- tr_chart_list(charts); mk <- function(p, s) if (length(p)) data.frame(slot = s, event_id = NA_character_, caption = NA_character_, path = p, stringsAsFactors = FALSE) else NULL
  d <- rbind(mk(ch$entry, "entry"), mk(ch$trade, "intrade"), mk(ch$exit, "exit")); if (is.null(d)) empty else d[file.exists(d$path), , drop = FALSE]
}
tr_trade_sheet_docx <- function(trade, legs, events, name, charts = list(), file) {
  pf <- tr_chart_frame(charts)
  if (tr_tpl_available("Trade_Sheet_Template.docx")) {
    ok <- tryCatch({ tr_trade_sheet_template(trade, legs, events, name, pf, file); TRUE }, error = function(e) { message("[Records] template export failed, using the plain layout: ", conditionMessage(e)); FALSE })
    if (ok) return(invisible(file))
  }
  en <- pf$path[pf$slot %in% c("entry", "entry_platform")]
  tr_trade_sheet_basic(trade, legs, events, name, list(tf4h = en[1], tf1h = en[2], tf15m = en[3], tf5m = en[4], trade = pf$path[pf$slot == "intrade"][1],
                                                       exit = pf$path[pf$slot == "exit"][1], post = pf$path[pf$slot == "post_exit"][1]), file)
}
tr_morning_docx <- function(sheet, levels, name, file, cal_o = character(0), cal_t = character(0)) {
  if (tr_tpl_available("Morning_Sheet_Template.docx")) {
    ok <- tryCatch({ tr_morning_template(sheet, levels, name, file, cal_o, cal_t); TRUE }, error = function(e) { message("[Records] template export failed, using the plain layout: ", conditionMessage(e)); FALSE })
    if (ok) return(invisible(file))
  }
  tr_morning_basic(sheet, levels, name, file)
}
