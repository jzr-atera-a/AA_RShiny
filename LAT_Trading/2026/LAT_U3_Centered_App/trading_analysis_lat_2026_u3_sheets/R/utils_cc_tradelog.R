# R/utils_cc_tradelog.R - Trade Log ********: every deal and order saved in BigQuery (cc_trades), laid out like the
# non-OCO tracking sheet (overnight range, buy / sell details, size and risk, exit by stop or target, durations,
# slippage, totals). The overnight range (22:00-06:00 UK) of each day is read once from Capital.com and kept in
# cc_ranges, so the log opens from BigQuery without calling the broker again.

cc_tables$ranges <- list(table = "cc_ranges", key = "range_id",
  cols = c(range_id = "STRING", saved_at = "TIMESTAMP", epic = "STRING", range_date = "DATE", from_uk = "STRING", to_uk = "STRING",
           low = "FLOAT64", high = "FLOAT64", range_pts = "FLOAT64", n_candles = "INT64", source = "STRING"))

# low / high of the candles from (day before) from_h:00 to to_h:00 UK of `day`
cc_overnight_range <- function(bars, day, from_h = 22, to_h = 6) {
  if (is.null(bars) || !NROW(bars)) return(NULL); day <- as.Date(day)
  a <- as.POSIXct(sprintf("%s %02d:00:00", format(day - 1), from_h), tz = "Europe/London"); b <- as.POSIXct(sprintf("%s %02d:00:00", format(day), to_h), tz = "Europe/London")
  t <- as.POSIXct(bars$time, tz = "UTC"); i <- which(t >= a & t < b); if (!length(i)) return(NULL)
  lo <- min(bars$low[i], na.rm = TRUE); hi <- max(bars$high[i], na.rm = TRUE)
  data.frame(range_date = day, low = lo, high = hi, range_pts = hi - lo, n_candles = length(i), stringsAsFactors = FALSE)
}

cc_tl_kind <- function(order_type, status) ifelse(toupper(order_type %||% "") %in% c("STOP", "LIMIT") | toupper(status %||% "") %in% c("WORKING", "EXPIRED", "CANCELLED", "REJECTED"), "ORDER", "DEAL")

# one row per deal / order; adverse slippage is positive (points against you)
cc_trade_log <- function(trades, ranges = NULL, tz = "Europe/London") {
  if (is.null(trades) || !NROW(trades)) return(NULL)
  t <- trades[!(trades$status %in% "DUPLICATE"), , drop = FALSE]; if (!nrow(t)) return(NULL)
  num <- function(k) if (k %in% names(t)) suppressWarnings(as.numeric(t[[k]])) else rep(NA_real_, nrow(t))
  chr <- function(k) if (k %in% names(t)) ifelse(is.na(t[[k]]), "", as.character(t[[k]])) else rep("", nrow(t))
  tm <- function(k) if (k %in% names(t)) as.POSIXct(t[[k]], tz = "UTC") else as.POSIXct(rep(NA_real_, nrow(t)), origin = "1970-01-01", tz = "UTC")
  placed <- tm("placed_ts"); ent <- tm("entry_ts"); ex <- tm("exit_ts"); sv <- tm("saved_at")
  when <- ifelse(is.na(ent), ifelse(is.na(placed), sv, placed), ent); when <- as.POSIXct(when, origin = "1970-01-01", tz = "UTC")
  day <- as.Date(format(when, "%Y-%m-%d", tz = tz))
  dir <- toupper(chr("direction")); sg <- ifelse(dir == "BUY", 1, -1)
  planned <- num("order_level"); entry <- num("entry_level"); stop0 <- num("stop_initial"); stop0 <- ifelse(is.na(stop0), num("stop_level"), stop0)
  tgt <- num("target_level"); exl <- num("exit_level"); code <- toupper(chr("exit_code")); st <- toupper(chr("status"))
  dur <- function(a, b) { m <- as.numeric(difftime(b, a, units = "mins")); ifelse(is.na(m), "", sprintf("%02d:%02d", as.integer(m %/% 60), as.integer(round(m %% 60)))) }
  stop_hit <- st == "CLOSED" & startsWith(code, "S"); tgt_hit <- st == "CLOSED" & code == "T"
  pnl <- num("pnl_account_booked"); pnl <- ifelse(is.na(pnl), num("pnl_account_est"), pnl); risk <- num("risk_account")
  rg <- if (!is.null(ranges) && NROW(ranges)) { r <- ranges[order(ranges$saved_at, decreasing = TRUE), , drop = FALSE]; r[!duplicated(paste(r$epic, r$range_date)), , drop = FALSE] } else NULL
  k <- if (is.null(rg)) rep(NA_integer_, nrow(t)) else match(paste(chr("epic"), format(day)), paste(rg$epic, format(as.Date(rg$range_date))))
  g <- function(col) if (is.null(rg)) rep(NA_real_, nrow(t)) else rg[[col]][k]
  out <- data.frame(
    trade_id = chr("trade_id"), date = day, market = ifelse(nzchar(chr("market_name")), chr("market_name"), chr("epic")),
    range_low = g("low"), range_high = g("high"), range_pts = g("range_pts"),
    kind = cc_tl_kind(chr("order_type"), st), type = ifelse(nzchar(chr("order_type")), chr("order_type"), "MARKET"), status = st,
    purpose = chr("purpose"), setup = chr("strategy"),
    buy = as.integer(dir == "BUY"), sell = as.integer(dir == "SELL"),
    planned = planned, entry = entry, stop = stop0, target = tgt,
    entry_time = ifelse(is.na(ent), "", format(ent, "%H:%M", tz = tz)),
    risk = risk, stop_pts = abs(entry - stop0), size = num("size"),
    stop_hit = as.integer(stop_hit), stop_time = ifelse(stop_hit, format(ex, "%H:%M", tz = tz), ""), stop_dur = ifelse(stop_hit, dur(ent, ex), ""),
    tgt_hit = as.integer(tgt_hit), tgt_time = ifelse(tgt_hit, format(ex, "%H:%M", tz = tz), ""), tgt_dur = ifelse(tgt_hit, dur(ent, ex), ""),
    other_exit = ifelse(st == "CLOSED" & !stop_hit & !tgt_hit, paste(code, format(ex, "%H:%M", tz = tz), dur(ent, ex)), ""),
    slip_entry = ifelse(is.finite(planned) & is.finite(entry), sg * (entry - planned), NA_real_),
    slip_exit = ifelse(stop_hit & is.finite(exl), sg * (stop0 - exl), ifelse(tgt_hit & is.finite(exl), sg * (tgt - exl), NA_real_)),
    deviation = as.integer(grepl("Plan deviation", chr("warnings"), fixed = TRUE)), hour = suppressWarnings(as.integer(format(when, "%H", tz = tz))),
    pnl = ifelse(st == "CLOSED", pnl, NA_real_), r_mult = ifelse(st == "CLOSED" & is.finite(risk) & risk > 0, pnl / risk, NA_real_),
    stringsAsFactors = FALSE)
  out[order(out$date, out$entry_time, decreasing = c(TRUE, TRUE), method = "radix"), , drop = FALSE]
}

cc_trade_log_totals <- function(lg) {
  if (is.null(lg) || !nrow(lg)) return(NULL); d <- lg[lg$kind == "DEAL", , drop = FALSE]; cl <- d[d$status == "CLOSED", , drop = FALSE]
  mins <- function(x) { x <- x[nzchar(x)]; if (!length(x)) return(""); m <- vapply(strsplit(x, ":"), function(p) as.numeric(p[1]) * 60 + as.numeric(p[2]), 0); m <- mean(m); sprintf("%02d:%02d", as.integer(m %/% 60), as.integer(round(m %% 60))) }
  win <- cl$pnl > 0 & is.finite(cl$pnl); loss <- cl$pnl <= 0 & is.finite(cl$pnl)
  list(deals = nrow(d), orders = sum(lg$kind == "ORDER"), open = sum(d$status == "OPEN"), closed = nrow(cl), buys = sum(d$buy), sells = sum(d$sell),
       avg_range = mean(lg$range_pts, na.rm = TRUE), avg_entry_time = mins(d$entry_time), avg_risk = mean(d$risk, na.rm = TRUE), avg_stop_pts = mean(d$stop_pts, na.rm = TRUE), avg_size = mean(d$size, na.rm = TRUE),
       stops = sum(cl$stop_hit), stop_dur = mins(cl$stop_dur), targets = sum(cl$tgt_hit), tgt_dur = mins(cl$tgt_dur), other = sum(nzchar(cl$other_exit)),
       total_loss = sum(cl$pnl[loss]), total_profit = sum(cl$pnl[win]), final = sum(cl$pnl, na.rm = TRUE), hit_rate = if (nrow(cl)) sum(win) / nrow(cl) else NA_real_,
       avg_r = mean(cl$r_mult, na.rm = TRUE), slip_entry = mean(d$slip_entry, na.rm = TRUE), slip_exit = mean(cl$slip_exit, na.rm = TRUE))
}

# the sheet layout: grouped headers like the tracking sheet; numbers formatted for reading
cc_trade_log_html <- function(lg, tot, d = 3, ccy = "GBP") {
  f <- function(x, k = d) ifelse(is.finite(x), formatC(x, format = "f", digits = k, big.mark = ","), "")
  m <- function(x) ifelse(is.finite(x), sprintf("%s%s %s", ifelse(x < 0, "-", ""), ccy, formatC(abs(x), format = "f", digits = 2, big.mark = ",")), "")
  yn <- function(x) ifelse(x == 1, "1", "0")
  th <- function(x, cs = 1, bg = "#fef9c3") htmltools::tags$th(colspan = cs, style = sprintf("background:%s; border:1px solid #94a3b8; padding:3px 6px; text-align:center;", bg), x)
  td <- function(x, bg = NULL) htmltools::tags$td(style = paste0("border:1px solid #cbd5e1; padding:2px 6px; text-align:center; white-space:nowrap;", if (!is.null(bg)) paste0("background:", bg, ";")), x)
  if (is.null(lg) || !nrow(lg)) return(htmltools::tags$div(style = "color:#64748b;", "No deals or orders saved in BigQuery yet."))
  rows <- lapply(seq_len(nrow(lg)), function(i) { r <- lg[i, ]; b <- r$buy == 1; bg <- if (r$kind == "ORDER") "#f1f5f9" else if (isTRUE(r$stop_hit == 1)) "#fee2e2" else if (isTRUE(r$tgt_hit == 1)) "#dcfce7" else NULL
    htmltools::tags$tr(td(format(r$date, "%d-%b-%y"), bg), td(r$market), td(f(r$range_low)), td(f(r$range_high)), td(f(r$range_pts)),
      td(paste(r$kind, if (r$kind == "ORDER") r$type else "", r$status)), td(r$setup), td(if (r$purpose == "ASSESSED") "Assessed" else if (nzchar(r$purpose)) "Practice" else ""),
      td(yn(r$buy), if (b) "#dcfce7"), td(if (b) f(r$entry) else ""), td(if (b) f(r$stop) else ""), td(if (b) f(r$target) else ""),
      td(r$entry_time),
      td(yn(r$sell), if (!b) "#ffedd5"), td(if (!b) f(r$entry) else ""), td(if (!b) f(r$stop) else ""), td(if (!b) f(r$target) else ""),
      td(m(r$risk)), td(f(r$stop_pts)), td(f(r$size, 2)),
      td(yn(r$stop_hit)), td(r$stop_time), td(r$stop_dur), td(yn(r$tgt_hit)), td(r$tgt_time), td(r$tgt_dur), td(r$other_exit),
      td(f(r$slip_entry)), td(f(r$slip_exit)), td(m(r$pnl)), td(f(r$r_mult, 2))) })
  tb <- htmltools::tags$table(style = "border-collapse:collapse; font-size:12px; width:100%;",
    htmltools::tags$thead(
      htmltools::tags$tr(th("", 2, "#fff"), th("OVERNIGHT RANGE (22:00-06:00 UK)", 3), th("TRADE", 3, "#e0f2fe"), th("BUY DETAILS", 4, "#dcfce7"), th("", 1), th("SELL DETAILS", 4, "#ffedd5"),
                         th("TRADE SIZE", 3, "#e0f2fe"), th("LOSS", 3, "#fee2e2"), th("PROFIT", 3, "#dcfce7"), th("OTHER EXIT", 1), th("SLIPPAGE (points)", 2), th("RESULT", 2, "#e0f2fe")),
      htmltools::tags$tr(lapply(c("Date", "Market", "Low", "High", "Range", "Deal / order", "Set-up", "Assessed?", "BUY", "Entry", "Stop", "Target", "Entry time", "SELL", "Entry", "Stop", "Target",
                                  "Risk", "Stop distance", "Size", "Stop hit?", "Exit time", "Duration", "Target hit?", "Exit time", "Duration", "Code, time, duration", "On entry", "On exit", "P/L", "R"), function(x) th(x)))),
    htmltools::tags$tbody(rows),
    if (!is.null(tot)) htmltools::tags$tfoot(htmltools::tags$tr(style = "font-weight:700;", td("AVERAGES & TOTALS"), td(""), td(""), td(""), td(f(tot$avg_range)), td(sprintf("%d deals, %d orders", tot$deals, tot$orders)), td(""), td(""),
      td(tot$buys, "#dcfce7"), td(""), td(""), td(""), td(tot$avg_entry_time), td(tot$sells, "#ffedd5"), td(""), td(""), td(""), td(m(tot$avg_risk)), td(f(tot$avg_stop_pts)), td(f(tot$avg_size, 2)),
      td(tot$stops, "#fee2e2"), td(""), td(tot$stop_dur), td(tot$targets, "#dcfce7"), td(""), td(tot$tgt_dur), td(tot$other), td(f(tot$slip_entry)), td(f(tot$slip_exit)), td(m(tot$final)), td(f(tot$avg_r, 2)))))
  sm <- if (!is.null(tot)) htmltools::tags$div(style = "display:flex; gap:10px; margin:10px 0; flex-wrap:wrap;", lapply(list(
      c("Total loss", m(tot$total_loss), "#fee2e2"), c("Total profit", m(tot$total_profit), "#dcfce7"), c("Final P/L", m(tot$final), "#e0f2fe"),
      c("Hit rate", if (is.finite(tot$hit_rate)) sprintf("%.1f%% of %d closed", 100 * tot$hit_rate, tot$closed) else "-", "#fef9c3"), c("Average R", f(tot$avg_r, 2), "#f1f5f9"), c("Open deals", tot$open, "#f1f5f9")),
    function(x) htmltools::tags$div(style = sprintf("background:%s; border:1px solid #cbd5e1; border-radius:8px; padding:6px 12px;", x[3]), htmltools::tags$div(style = "font-size:11px; color:#475569;", x[1]), htmltools::tags$div(style = "font-weight:800; font-size:15px;", x[2]))))
  htmltools::tagList(sm, htmltools::tags$div(style = "overflow-x:auto;", tb))
}

# ---- ********** your real results, in R and in money, by what you can control ------------------------------------
# R removes the size: if the total in R is positive but the money is negative, the sizes were inconsistent.
cc_trade_log_report <- function(lg) {
  if (is.null(lg) || !nrow(lg)) return(NULL); cl <- lg[lg$kind == "DEAL" & lg$status == "CLOSED" & is.finite(lg$pnl), , drop = FALSE]; if (!nrow(cl)) return(NULL)
  grp <- function(f, name) { do.call(rbind, lapply(split(cl, f, drop = TRUE), function(d) data.frame(by = name, group = as.character(d$g[1]), trades = nrow(d), wins = sum(d$pnl > 0),
    win_pct = 100 * mean(d$pnl > 0), total_r = sum(d$r_mult, na.rm = TRUE), avg_r = mean(d$r_mult, na.rm = TRUE), money = sum(d$pnl), stringsAsFactors = FALSE))) }
  mk <- function(g, name) { cl$g <<- g; grp(g, name) }
  ses <- ifelse(is.na(cl$hour), "unknown", ifelse(cl$hour < 7, "00-07 (before your session)", ifelse(cl$hour < 12, "07-12 London morning", ifelse(cl$hour < 17, "12-17 London / US", "17-24 evening"))))
  tab <- rbind(mk(ifelse(nzchar(cl$setup), cl$setup, "(not set)"), "Set-up"), mk(ses, "Entry time (UK)"), mk(ifelse(cl$deviation == 1, "Plan deviation (rule on Warn)", "Within the plan"), "Plan"),
               mk(ifelse(cl$buy == 1, "BUY", "SELL"), "Direction"), mk(ifelse(cl$purpose == "ASSESSED", "Assessed", "Practice"), "Purpose"))
  rownames(tab) <- NULL; tr <- sum(cl$r_mult, na.rm = TRUE); tm <- sum(cl$pnl); rk <- cl$risk[is.finite(cl$risk) & cl$risk > 0]
  spread <- if (length(rk) >= 2) max(rk) / min(rk) else NA_real_
  msg <- c(sprintf("%d closed deals: %d wins (%.0f%%). Total %+.2f R; in money %+.2f.", nrow(cl), sum(cl$pnl > 0), 100 * mean(cl$pnl > 0), tr, tm),
    if (is.finite(tr) && tr > 0 && tm < 0) "Your decisions made money in R but the account lost: the losing trades were much bigger than the winning ones. Fix the SIZE, not the set-ups." else NULL,
    if (is.finite(spread) && spread >= 3) sprintf("Risk per trade varied %.0f times between your smallest and largest trade (%.2f to %.2f). Use one risk amount for every trade so results are comparable.", spread, min(rk), max(rk)) else NULL,
    if (nrow(cl) < 20) sprintf("With %d trades no set-up or hour is proven good or bad yet: read these as notes, not conclusions (about 20-30 trades per group are needed).", nrow(cl)) else NULL)
  list(table = tab, messages = msg, total_r = tr, total_money = tm, risk_spread = spread)
}
cc_trade_log_report_html <- function(rp, ccy = "GBP") {
  if (is.null(rp)) return(NULL); t <- rp$table; td <- function(x, st = "") htmltools::tags$td(style = paste0("border:1px solid #cbd5e1; padding:2px 8px; text-align:center;", st), x)
  htmltools::tags$div(style = "background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:10px 14px; margin:10px 0;",
    htmltools::tags$div(style = "font-weight:800; color:#0b3b3a; font-size:14.5px;", "Your results so far: what the record shows **********"),
    lapply(rp$messages, function(m) htmltools::tags$div(style = "font-size:13px; margin:3px 0; font-weight:600;", m)),
    htmltools::tags$table(style = "border-collapse:collapse; font-size:12px; margin-top:6px;",
      htmltools::tags$tr(lapply(c("By", "Group", "Trades", "Wins", "Win %", "Total R", "Average R", paste("Money", ccy)), function(h) htmltools::tags$th(style = "background:#e0f2fe; border:1px solid #94a3b8; padding:3px 8px;", h))),
      lapply(seq_len(nrow(t)), function(i) htmltools::tags$tr(td(t$by[i]), td(t$group[i]), td(t$trades[i]), td(t$wins[i]), td(sprintf("%.0f%%", t$win_pct[i])),
        td(sprintf("%+.2f", t$total_r[i]), if (isTRUE(t$total_r[i] < 0)) "color:#b91c1c;" else "color:#166534;"), td(sprintf("%+.2f", t$avg_r[i])), td(sprintf("%+.2f", t$money[i]), if (t$money[i] < 0) "color:#b91c1c;" else "color:#166534;")))))
}
