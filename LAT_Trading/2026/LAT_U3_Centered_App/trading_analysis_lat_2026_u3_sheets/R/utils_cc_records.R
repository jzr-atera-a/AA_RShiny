# R/utils_cc_records.R
# Records, currency, budget, scenarios and sync for the "T Records C.C" tab (Capital.com demo).
# Separate BigQuery tables (prefix cc_) in the same dataset: the IG tables and the original Trading Records tab are
# not touched. Append-only like the original: an edit writes a new version, the latest row per key is current.

cc_tables <- list(
  settings = list(table = "cc_settings", key = "setting_key",
    cols = c(setting_key = "STRING", saved_at = "TIMESTAMP", setting_value = "STRING")),
  trades = list(table = "cc_trades", key = "trade_id",
    cols = c(trade_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", source = "STRING", environment = "STRING", account_id = "STRING",
             account_currency = "STRING", epic = "STRING", market_name = "STRING", instrument_currency = "STRING", direction = "STRING", size = "FLOAT64",
             lot_size = "FLOAT64", order_type = "STRING", order_level = "FLOAT64", good_till = "TIMESTAMP", deal_reference = "STRING", order_deal_id = "STRING",
             deal_id = "STRING", status = "STRING", placed_ts = "TIMESTAMP", entry_ts = "TIMESTAMP", entry_level = "FLOAT64", stop_initial = "FLOAT64",
             stop_level = "FLOAT64", target_level = "FLOAT64", exit_ts = "TIMESTAMP", exit_level = "FLOAT64", exit_code = "STRING",
             pnl_instrument = "FLOAT64", fx_rate = "FLOAT64", pnl_account_est = "FLOAT64", pnl_account_booked = "FLOAT64", balance_after = "FLOAT64",
             risk_account = "FLOAT64", reward_account = "FLOAT64", purpose = "STRING", strategy = "STRING", chart_period = "STRING", expected_hours = "FLOAT64",
             setup_fund = "STRING", setup_tech = "STRING", trigger_text = "STRING", execution_text = "STRING", stop_reason = "STRING", target_reason = "STRING",
             exit_reason = "STRING", lessons = "STRING", analysis = "STRING", plan_followed = "STRING", deviation_type = "STRING", deviation_note = "STRING",
             mood_entry = "INT64", mood_exit = "INT64", scan_id = "STRING", scenario_json = "STRING", warnings = "STRING", notes = "STRING")),
  events = list(table = "cc_events", key = "event_id",
    cols = c(event_id = "STRING", saved_at = "TIMESTAMP", trade_id = "STRING", event_type = "STRING", deal_reference = "STRING", deal_id = "STRING",
             deal_status = "STRING", level = "FLOAT64", stop_level = "FLOAT64", target_level = "FLOAT64", request_json = "STRING", response_json = "STRING", note = "STRING")),
  activity = list(table = "cc_activity", key = "row_id",
    cols = c(row_id = "STRING", saved_at = "TIMESTAMP", date_utc = "STRING", epic = "STRING", deal_id = "STRING", source = "STRING", type = "STRING",
             status = "STRING", level = "FLOAT64", size = "FLOAT64", direction = "STRING", json = "STRING")),
  transactions = list(table = "cc_transactions", key = "row_id",
    cols = c(row_id = "STRING", saved_at = "TIMESTAMP", date_utc = "STRING", instrument = "STRING", type = "STRING", reference = "STRING",
             amount = "FLOAT64", currency = "STRING", note = "STRING", json = "STRING")),
  account = list(table = "cc_account", key = "snap_id",
    cols = c(snap_id = "STRING", saved_at = "TIMESTAMP", account_id = "STRING", currency = "STRING", balance = "FLOAT64", deposit = "FLOAT64",
             profit_loss = "FLOAT64", available = "FLOAT64")),
  scans = list(table = "cc_scans", key = "scan_id",
    cols = c(scan_id = "STRING", saved_at = "TIMESTAMP", trade_id = "STRING", epic = "STRING", resolution = "STRING", n_candles = "INT64",
             last_candle_utc = "TIMESTAMP", regime = "STRING", adx = "FLOAT64", current_json = "STRING", bars_json = "STRING")),
  # ***** everything Claude generates is kept: second readings (with the course checks), suggested trades, and every scenario set shown
  claude_readings = list(table = "cc_claude_readings", key = "reading_id",
    cols = c(reading_id = "STRING", saved_at = "TIMESTAMP", source = "STRING", trade_id = "STRING", epic = "STRING", market_name = "STRING", resolution = "STRING",
             last_candle_utc = "TIMESTAMP", last_close = "FLOAT64", checks_ticked = "STRING", n_agree = "INT64", n_doubt = "INT64", n_disagree = "INT64",
             n_added = "INT64", n_refused = "INT64", n_course = "INT64", reply_text = "STRING", facts_json = "STRING", note = "STRING")),
  claude_reading_lines = list(table = "cc_claude_reading_lines", key = "line_id",
    cols = c(line_id = "STRING", saved_at = "TIMESTAMP", reading_id = "STRING", line_no = "INT64", section = "STRING", item_key = "STRING", item_label = "STRING",
             week = "STRING", topic = "STRING", r_values = "STRING", verdict = "STRING", note = "STRING", bias = "STRING", cancel_level = "FLOAT64", target_level = "FLOAT64")),
  claude_suggestions = list(table = "cc_claude_suggestions", key = "call_id",
    cols = c(call_id = "STRING", saved_at = "TIMESTAMP", epic = "STRING", morning_sheet_asked = "BOOL", morning_sheet_used = "BOOL", morning_sheet_note = "STRING",
             ok = "BOOL", seconds = "FLOAT64", n_suggested = "INT64", n_fit_plan = "INT64", summary = "STRING", stand_aside_reason = "STRING", error = "STRING",
             prompt_chars = "INT64", rows_json = "STRING", reply_text = "STRING")),
  scenarios = list(table = "cc_scenarios", key = "row_id",
    cols = c(row_id = "STRING", saved_at = "TIMESTAMP", build_id = "STRING", build_type = "STRING", epic = "STRING", source = "STRING", scenario_id = "STRING", side = "STRING",
             entry = "FLOAT64", stop = "FLOAT64", target = "FLOAT64", rrr = "FLOAT64", size = "FLOAT64", risk_account = "FLOAT64", reward_account = "FLOAT64",
             blocked = "BOOL", plan = "STRING", checks = "STRING", trend = "STRING", confluence = "STRING", news = "STRING", claude_p = "FLOAT64", meas_p = "FLOAT64", note = "STRING"))
)

cc_bq_type <- function(t) c(STRING = "STRING", INT64 = "INT64", FLOAT64 = "FLOAT64", BOOL = "BOOL", TIMESTAMP = "TIMESTAMP", DATE = "DATE")[[t]]
cc_ddl <- function(project, dataset) {
  out <- character(0)
  for (nm in names(cc_tables)) { tb <- cc_tables[[nm]]; full <- sprintf("%s.%s.%s", project, dataset, tb$table)
    out <- c(out, sprintf("CREATE TABLE IF NOT EXISTS `%s` (\n%s\n)", full, paste(sprintf("  %s %s", names(tb$cols), vapply(tb$cols, cc_bq_type, "")), collapse = ",\n"))) }
  for (nm in names(cc_tables)) { tb <- cc_tables[[nm]]; full <- sprintf("%s.%s.%s", project, dataset, tb$table)
    ob <- if ("record_version" %in% names(tb$cols)) "saved_at DESC, record_version DESC" else "saved_at DESC"
    out <- c(out, sprintf("CREATE OR REPLACE VIEW `%s_current` AS\nSELECT * EXCEPT(rn) FROM (\n  SELECT *, ROW_NUMBER() OVER (PARTITION BY %s ORDER BY %s) AS rn\n  FROM `%s`\n) WHERE rn = 1", full, tb$key, ob, full)) }
  out
}
cc_coerce <- function(name, df) {
  sch <- cc_tables[[name]]$cols; n <- if (is.null(df)) 0L else nrow(df)
  out <- vector("list", length(sch)); names(out) <- names(sch)
  for (cn in names(sch)) { v <- if (!is.null(df) && cn %in% names(df)) df[[cn]] else rep(NA, n)
    out[[cn]] <- switch(sch[[cn]], STRING = as.character(v), INT64 = suppressWarnings(as.integer(v)), FLOAT64 = suppressWarnings(as.numeric(v)), BOOL = as.logical(v),
      TIMESTAMP = if (inherits(v, "POSIXct")) { attr(v, "tzone") <- "UTC"; v } else as.POSIXct(v, tz = "UTC"), DATE = as.Date(v)) }
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
cc_latest <- function(name, df) {
  if (is.null(df) || !nrow(df)) return(df); key <- cc_tables[[name]]$key
  rv <- if ("record_version" %in% names(df)) df$record_version else rep(0L, nrow(df))
  df <- df[order(df$saved_at, rv, na.last = FALSE), , drop = FALSE]; df[!duplicated(df[[key]], fromLast = TRUE), , drop = FALSE]
}
cc_bq_backend <- function(api) list(
  connected = function() isTRUE(api$bq_authenticated),
  ensure = function() { for (s in cc_ddl(api$bq_project_id, api$bq_dataset_id)) { cat("[C.C] DDL:", substr(gsub("\\s+", " ", s), 1, 100), "...\n"); bigrquery::bq_project_query(api$bq_project_id, s) }; invisible(TRUE) },
  write = function(name, df) { tb <- cc_tables[[name]]; ref <- bigrquery::bq_table(api$bq_project_id, api$bq_dataset_id, tb$table)
    cat("[C.C] Uploading", nrow(df), "row(s) ->", tb$table, "\n")
    bigrquery::bq_table_upload(ref, df, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND"); invisible(nrow(df)) },
  read = function(name) { tb <- cc_tables[[name]]
    bigrquery::bq_table_download(bigrquery::bq_project_query(api$bq_project_id, sprintf("SELECT * FROM `%s.%s.%s`", api$bq_project_id, api$bq_dataset_id, tb$table))) })
cc_mem_backend <- function() { db <- new.env(parent = emptyenv())   # tests and "no BigQuery yet"
  list(connected = function() TRUE, ensure = function() invisible(TRUE),
       write = function(name, df) { assign(name, rbind(if (exists(name, envir = db)) get(name, envir = db) else NULL, df), envir = db); invisible(nrow(df)) },
       read = function(name) if (exists(name, envir = db)) get(name, envir = db) else cc_coerce(name, NULL)) }
# rows are cached after the first read; a write appends to the cache; not connected = kept in this session and queued
cc_make_store <- function(backend) {
  pend <- new.env(parent = emptyenv()); cache <- new.env(parent = emptyenv()); s <- list()
  s$connected <- function() isTRUE(backend$connected()); s$ensure <- function() backend$ensure()
  s$invalidate <- function(name = NULL) { nm <- if (is.null(name)) ls(cache) else intersect(name, ls(cache)); if (length(nm)) rm(list = nm, envir = cache) }
  s$write <- function(name, df) { stopifnot(name %in% names(cc_tables)); df <- cc_coerce(name, df); if (!nrow(df)) return(invisible("empty"))
    df$saved_at <- Sys.time() + seq_len(nrow(df)) * 1e-6; attr(df$saved_at, "tzone") <- "UTC"
    if (s$connected()) tryCatch({ backend$write(name, df); if (exists(name, envir = cache)) assign(name, rbind(get(name, envir = cache), df), envir = cache); invisible("bigquery") },
      error = function(e) { cat("[C.C] BigQuery write failed, queued:", conditionMessage(e), "\n"); assign(name, rbind(if (exists(name, envir = pend)) get(name, envir = pend) else NULL, df), envir = pend); invisible("queued") })
    else { assign(name, rbind(if (exists(name, envir = pend)) get(name, envir = pend) else NULL, df), envir = pend); invisible("pending") } }
  s$read <- function(name) { remote <- NULL
    if (s$connected()) { if (exists(name, envir = cache)) remote <- get(name, envir = cache) else {
        remote <- tryCatch(cc_coerce(name, backend$read(name)), error = function(e) { cat("[C.C] read failed for", name, ":", conditionMessage(e), "\n"); NULL })
        if (!is.null(remote)) assign(name, remote, envir = cache) } }
    rbind(if (is.null(remote)) cc_coerce(name, NULL) else remote, if (exists(name, envir = pend)) get(name, envir = pend) else cc_coerce(name, NULL)) }
  s$current <- function(name) cc_latest(name, s$read(name))
  s$pending_count <- function() sum(vapply(ls(pend), function(n) nrow(get(n, envir = pend)), 0L))
  s$sync <- function() { if (!s$connected()) stop("BigQuery is not connected."); k <- 0L
    for (n in ls(pend)) { d <- get(n, envir = pend); if (nrow(d)) { backend$write(n, d); k <- k + nrow(d) }; rm(list = n, envir = pend); s$invalidate(n) }; k }
  s
}
cc_id <- function(prefix) sprintf("%s_%s_%04x", prefix, format(Sys.time(), "%Y%m%d%H%M%OS3", tz = "UTC"), sample.int(65535, 1))
cc_json <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))

# ---- currency -------------------------------------------------------------------------------------------------
# Rate to turn an amount in `from` into `to`, from Capital.com's own FX market (mid of bid/offer), e.g. USD -> GBP
# uses GBPUSD and divides. Returns list(rate, epic, how, time) or rate NA when no FX market answers.
cc_fx_rate <- function(client, from, to) {
  if (is.na(from) || is.na(to) || identical(from, to)) return(list(rate = 1, epic = NA_character_, how = "same currency", time = Sys.time()))
  for (ep in c(paste0(from, to), paste0(to, from))) {
    m <- tryCatch(client$market(ep), error = function(e) NULL); if (is.null(m)) next
    f <- cc_market_facts(m); mid <- mean(c(f$bid, f$offer), na.rm = TRUE); if (!is.finite(mid) || mid <= 0) next
    inv <- ep == paste0(to, from)
    return(list(rate = if (inv) 1 / mid else mid, epic = ep, how = sprintf("%s mid %.5f%s", ep, mid, if (inv) " (divided)" else ""), time = Sys.time())) }
  list(rate = NA_real_, epic = NA_character_, how = sprintf("no %s/%s market answered", from, to), time = Sys.time())
}
# value of a 1-unit price move for this size (instrument currency). Capital.com: P/L = size x price change x lot size.
cc_value_per_point <- function(size, lot_size = NA) size * (if (is.finite(lot_size) && lot_size > 0) lot_size else 1)

# ---- budget for one planned trade --------------------------------------------------------------------------------
# balance / available in account currency; prices in instrument currency; fx = account units per instrument unit
cc_budget <- function(direction, entry, stop, target, size, lot_size, fx, balance, available, margin_factor = NA, margin_unit = NA,
                      spread = NA, open_risk_account = 0, risk_pct_plan = NA, cap_pct_plan = NA, min_rrr = NA, min_size = NA, min_stop_distance = NA) {
  d <- if (toupper(direction) %in% c("BUY", "B")) 1 else -1; vpp <- cc_value_per_point(size, lot_size)
  risk_pts <- d * (entry - stop); rew_pts <- d * (target - entry)
  risk_i <- risk_pts * vpp; rew_i <- rew_pts * vpp; fxv <- if (is.finite(fx)) fx else NA_real_
  risk_a <- risk_i * fxv; rew_a <- rew_i * fxv; spread_a <- if (is.finite(spread)) spread * vpp * fxv else NA_real_
  notional_i <- abs(entry) * vpp
  margin_a <- if (is.finite(margin_factor)) (if (identical(toupper(margin_unit %||% ""), "PERCENTAGE") || margin_factor > 1) notional_i * margin_factor / 100 else notional_i * margin_factor) * fxv else NA_real_
  warn <- character(0); err <- character(0)
  if (!is.finite(risk_pts) || risk_pts <= 0) err <- c(err, "The stop is on the wrong side of the entry.")
  if (!is.finite(rew_pts) || rew_pts <= 0) err <- c(err, "The target is on the wrong side of the entry.")
  if (!is.finite(size) || size <= 0) err <- c(err, "Size must be above 0.")
  if (is.finite(min_size) && is.finite(size) && size < min_size) err <- c(err, sprintf("Size %s is below Capital.com's minimum %s.", size, min_size))
  if (is.finite(min_stop_distance) && is.finite(risk_pts) && risk_pts < min_stop_distance) err <- c(err, sprintf("Stop distance %.4g is below the minimum %.4g.", risk_pts, min_stop_distance))
  if (!is.finite(fxv)) warn <- c(warn, "No exchange rate: amounts in your account currency cannot be worked out.")
  rpct <- if (is.finite(risk_a) && is.finite(balance) && balance > 0) 100 * risk_a / balance else NA_real_
  if (is.finite(risk_pct_plan) && is.finite(rpct) && rpct > risk_pct_plan + 1e-9) warn <- c(warn, sprintf("Risk %.2f%% is above your plan's %.2f%% per trade.", rpct, risk_pct_plan))
  tot <- if (is.finite(rpct)) rpct + 100 * open_risk_account / balance else NA_real_
  if (is.finite(cap_pct_plan) && is.finite(tot) && tot > cap_pct_plan + 1e-9) warn <- c(warn, sprintf("With your open trades, total risk %.2f%% is above your %.2f%% cap.", tot, cap_pct_plan))
  rrr <- if (is.finite(risk_pts) && risk_pts > 0) rew_pts / risk_pts else NA_real_
  if (is.finite(min_rrr) && is.finite(rrr) && rrr < min_rrr - 1e-9) warn <- c(warn, sprintf("Reward:risk %.2f is below your plan's %.2f.", rrr, min_rrr))
  if (is.finite(margin_a) && is.finite(available) && margin_a > available) err <- c(err, sprintf("Margin %.2f is more than the available %.2f.", margin_a, available))
  list(dir = d, value_per_point = vpp, risk_points = risk_pts, reward_points = rew_pts, rrr = rrr, risk_instrument = risk_i, reward_instrument = rew_i,
       risk_account = risk_a, reward_account = rew_a, spread_account = spread_a, risk_pct = rpct, total_risk_pct = tot, margin_account = margin_a,
       balance = balance, balance_if_stop = balance - risk_a, balance_if_target = balance + rew_a, available_after = available - (if (is.finite(margin_a)) margin_a else 0),
       size_for_plan = if (is.finite(risk_pct_plan) && is.finite(balance) && is.finite(risk_pts) && risk_pts > 0 && is.finite(fxv) && fxv > 0)
         balance * risk_pct_plan / 100 / (risk_pts * (if (is.finite(lot_size) && lot_size > 0) lot_size else 1) * fxv) else NA_real_,
       warnings = warn, errors = err)
}

# ---- scenarios: BUY and SELL, each as a market, a limit and a stop-entry order (6) --------------------------------
# Levels come from the patterns active now (the stop side of the strongest in-regime pattern for that side, and its
# target), else the ATR template. No probability is given: each scenario lists the patterns behind it with their
# MEASURED record on this market. Nothing here writes any of your reasoning boxes.
# Scenarios are DEALS (market entries at the price now), never working orders. Per side: the pattern / structure stop and
# an ATR stop. The stop is never closer than 0.5 ATR or the broker's minimum; the target is the pattern's measured target
# when that already gives at least the minimum Reward:Risk, otherwise it is moved out to exactly the minimum (said in How).
cc_scenarios <- function(scan, bid, offer, min_stop_distance = NA, min_rrr = 1.5, d = 5, filt = NULL) {
  ctx <- scan$ctx; n <- ctx$n; a <- ctx$a[n]; cd <- scan$current_df
  mr <- if (is.finite(min_rrr %||% NA) && min_rrr > 0) min_rrr else 1.5
  mid <- if (is.finite(bid) && is.finite(offer)) (bid + offer) / 2 else ctx$c[n]
  pick <- function(dir) { if (is.null(cd) || !nrow(cd)) return(NULL)
    x <- cd[!is.na(cd$dir) & cd$dir == dir & cd$in_regime & is.finite(cd$invalid) & is.finite(cd$target), , drop = FALSE]
    x <- x[dir * (mid - x$invalid) > 0 & dir * (x$target - mid) > 0, , drop = FALSE]; if (!nrow(x)) return(NULL)
    # #6 price / time filter (course Week 2): a pattern with a break level counts only if price closed beyond it by frac x ATR for n candles
    if (!is.null(filt) && "level" %in% names(x)) { fp <- vapply(seq_len(nrow(x)), function(i) cc_break_filter(ctx, x$level[i], dir, filt$frac, filt$n), NA)
      x <- x[is.na(fp) | fp, , drop = FALSE]; attr(x, "filtered") <- sum(!is.na(fp) & !fp); if (!nrow(x)) return(NULL) }
    x$w <- ifelse(x$hist_n >= 8 & is.finite(x$hist_win), x$hist_win, 50); x[order(-x$w, -x$conf), , drop = FALSE] }
  floor_risk <- function(r) { r <- max(r, 0.5 * a, na.rm = TRUE); if (is.finite(min_stop_distance)) r <- max(r, min_stop_distance * 1.05); r + 10^-d }
  out <- list()
  for (dir in c(1L, -1L)) { side <- if (dir > 0) "BUY" else "SELL"; P <- pick(dir); px <- if (dir > 0) offer else bid; if (!is.finite(px)) px <- mid
    basis <- if (is.null(P)) "No in-regime pattern on this side: ATR stop" else
      paste(sprintf("%s (%s)", P$label, ifelse(P$hist_n >= 8, sprintf("measured %0.f%% target-first, n=%d", P$hist_win, P$hist_n), sprintf("only %d measured cases", P$hist_n))), collapse = "; ")
    mk <- function(id, risk, tg_struct, how) { risk <- floor_risk(risk); stop_ <- px - dir * risk
      need <- px + dir * mr * risk; ok_struct <- is.finite(tg_struct) && dir * (tg_struct - need) >= 0
      tgt <- if (ok_struct) tg_struct else need
      data.frame(id = id, side = side, type = "MARKET", entry = px, stop = stop_, target = tgt,
                 note = paste0(how, if (ok_struct) "; target at the pattern's measured target" else sprintf("; target set to your minimum Reward:Risk %.2f", mr)),
                 basis = basis, keys = if (is.null(P)) "" else paste(P$key, collapse = ","), stringsAsFactors = FALSE) }
    if (!is.null(P)) out[[length(out) + 1]] <- mk(paste(side, "MARKET"), abs(px - P$invalid[1]) + 0.1 * a, P$target[1], sprintf("Deal at the %s now; stop just beyond the level that cancels %s", if (dir > 0) "offer" else "bid", P$label[1]))
    out[[length(out) + 1]] <- mk(if (is.null(P)) paste(side, "MARKET") else paste(side, "MARKET (ATR stop)"), 1.5 * a, if (is.null(P)) NA else P$target[1],
                                 sprintf("Deal at the %s now; stop 1.5 ATR away", if (dir > 0) "offer" else "bid")) }
  x <- do.call(rbind, out)
  # prices on the market's grid, rounded so that rounding can never take the Reward:Risk below the minimum
  up <- function(v) ceiling(v * 10^d - 1e-7) / 10^d; dn <- function(v) floor(v * 10^d + 1e-7) / 10^d; b <- x$side == "BUY"
  x$stop <- ifelse(b, up(x$stop), dn(x$stop)); x$target <- ifelse(b, up(x$target), dn(x$target))
  x[!duplicated(paste(x$side, x$stop, x$target)), , drop = FALSE]
}

# ---- exit code from the exit level, the stops and the target (allowing for the spread) ------------------------------
cc_exit_code <- function(direction, exit_level, stop_initial, stop_level, target, spread = 0) {
  d <- if (toupper(direction) %in% c("BUY", "B")) 1 else -1; tol <- max(spread %||% 0, 0, na.rm = TRUE) + 1e-9
  if (!is.finite(exit_level)) return(NA_character_)
  if (is.finite(target) && d * (exit_level - target) >= -tol) return("T")
  if (is.finite(stop_level) && abs(exit_level - stop_level) <= tol + abs(stop_level) * 1e-4) return(if (is.finite(stop_initial) && abs(stop_level - stop_initial) > tol) "S2+" else "S1")
  if (is.finite(stop_initial) && d * (exit_level - stop_initial) <= tol) return("S1")
  "ME"
}
cc_exit_codes <- c("Not set" = "", "T: target (limit) hit" = "T", "S1: initial stop hit" = "S1", "S2+: moved stop hit" = "S2+", "ME: manual exit" = "ME")

# ---- sync with Capital.com: positions, working orders, activity, transactions -> cc_ tables ----------------------------
# trades: data.frame of current cc_trades rows. Returns list(new_trades, events, activity, transactions, account, messages)
cc_reconcile <- function(trades, positions, orders, activity, transactions, account_currency = NA, fx_fun = function(ccy) NA_real_, now = Sys.time()) {
  msgs <- character(0); upd <- list(); ev <- list()
  bump <- function(r, ...) { ch <- list(...); for (k in names(ch)) r[[k]] <- ch[[k]]; rv <- suppressWarnings(as.integer(r$record_version)); r$record_version <- (if (length(rv) && !is.na(rv)) rv else 0L) + 1L; r }
  pos <- if (is.null(positions) || !nrow(positions)) data.frame(deal_id = character(0)) else positions
  ord <- if (is.null(orders) || !nrow(orders)) data.frame(deal_id = character(0)) else orders
  act <- if (is.null(activity) || !nrow(activity)) data.frame(deal_id = character(0)) else activity
  tx <- if (is.null(transactions) || !nrow(transactions)) data.frame(reference = character(0)) else transactions
  if (is.null(trades)) trades <- cc_coerce("trades", NULL)
  for (k in seq_len(nrow(trades))) { r <- as.list(trades[k, ])
    if (identical(r$status, "ORDER_WORKING")) {
      if (nrow(ord) && r$order_deal_id %in% ord$deal_id) next
      fil <- if (nrow(pos) && "working_order_id" %in% names(pos)) pos[!is.na(pos$working_order_id) & pos$working_order_id == r$order_deal_id, , drop = FALSE] else pos[0, , drop = FALSE]
      if (!nrow(fil) && nrow(pos)) fil <- pos[pos$epic == r$epic & toupper(pos$direction) == toupper(r$direction) & abs(pos$size - r$size) < 1e-9 & !(pos$deal_id %in% trades$deal_id), , drop = FALSE]
      if (nrow(fil)) { p <- fil[1, ]; upd[[length(upd) + 1]] <- bump(r, status = "OPEN", deal_id = p$deal_id, entry_level = p$level, entry_ts = cc_ts(p$created_utc),
                                                                        stop_level = p$stop_level, target_level = p$profit_level)
        ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "ORDER_FILLED", deal_id = p$deal_id, level = p$level, note = "Working order filled")
        msgs <- c(msgs, sprintf("%s: the %s order filled at %s.", r$trade_id, r$order_type, p$level)); next }
      # not open now: did it fill (and maybe close again) between two syncs? The history shows the position it opened.
      ff <- cc_find_fill(r, act, trades)
      if (!is.null(ff)) { r$status <- "OPEN"; r$deal_id <- ff$deal_id; r$entry_level <- ff$level; r$entry_ts <- ff$ts; r$filled_from_history <- TRUE
        ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "ORDER_FILLED", deal_id = ff$deal_id, level = ff$level, note = "Working order filled (found in the activity history)")
        msgs <- c(msgs, sprintf("%s: the %s order filled at %s (%s UTC).", r$trade_id, tolower(r$order_type %||% ""), ff$level, format(ff$ts, "%d/%m %H:%M"))) }
      a <- act[!is.na(act$deal_id) & act$deal_id == r$order_deal_id, , drop = FALSE]
      if (is.null(ff) && (!is.na(r$good_till) && now > r$good_till || nrow(a))) { st <- if (nrow(a) && any(grepl("DELETE|CANCEL", toupper(paste(a$type, a$status))))) "CANCELLED" else "EXPIRED"
        upd[[length(upd) + 1]] <- bump(r, status = st); ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = paste0("ORDER_", st), note = "Order no longer working")
        msgs <- c(msgs, sprintf("%s: the order is no longer working (%s).", r$trade_id, tolower(st))) }
      if (is.null(ff)) next }
    # repair: an order marked EXPIRED / CANCELLED by the earlier sync although it had filled (and closed) between syncs
    if (r$status %in% c("EXPIRED", "CANCELLED") && !is.na(r$order_deal_id %||% NA)) { ff <- cc_find_fill(r, act, trades)
      if (is.null(ff)) next
      r$status <- "OPEN"; r$deal_id <- ff$deal_id; r$entry_level <- ff$level; r$entry_ts <- ff$ts; r$filled_from_history <- TRUE
      ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "ORDER_FILLED", deal_id = ff$deal_id, level = ff$level, note = "Repaired: the order had filled, it was not expired")
      msgs <- c(msgs, sprintf("%s: repaired, the order had filled at %s (%s UTC), it was not %s.", r$trade_id, ff$level, format(ff$ts, "%d/%m %H:%M"), tolower(trades$status[k]))) }
    if (identical(r$status, "OPEN")) { filled_now <- isTRUE(r$filled_from_history); r$filled_from_history <- NULL
      ids <- stats::na.omit(c(r$deal_id, r$order_deal_id))
      hit <- if (nrow(pos)) which(pos$deal_id %in% ids | (!is.na(pos$working_order_id %||% NA) & pos$working_order_id %in% ids)) else integer(0)
      if (!length(hit) && nrow(pos)) hit <- cc_match_position(r, pos)       # same market, side, size and entry: the same position
      if (length(hit)) { p <- pos[hit[1], , drop = FALSE]; ch <- list()
        if (!identical(p$deal_id, r$deal_id)) ch$deal_id <- p$deal_id         # keep the id the positions list uses
        if ((is.finite(p$stop_level) && !isTRUE(all.equal(p$stop_level, r$stop_level))) || (is.finite(p$profit_level) && !isTRUE(all.equal(p$profit_level, r$target_level)))) {
          ch$stop_level <- p$stop_level; ch$target_level <- p$profit_level
          ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "LEVELS_CHANGED", deal_id = p$deal_id, stop_level = p$stop_level, target_level = p$profit_level, note = "Stop / target changed on the platform") }
        if (length(ch) || filled_now) upd[[length(upd) + 1]] <- do.call(bump, c(list(r), ch))
        next }
      # not among the open positions: closed ONLY if the activity history shows a close for it
      fc <- cc_find_close(r, act)
      if (is.null(fc)) { if (filled_now) upd[[length(upd) + 1]] <- bump(r)
        msgs <- c(msgs, sprintf("%s is not in the open positions, but no close is in the history yet: left OPEN (sync again later).", r$trade_id)); next }
      xl <- fc$level; xt <- fc$ts
      d <- if (toupper(r$direction) == "BUY") 1 else -1; pnl_i <- if (is.finite(xl)) d * (xl - r$entry_level) * cc_value_per_point(r$size, r$lot_size) else NA_real_
      fx <- fx_fun(r$instrument_currency); if (!is.finite(fx %||% NA)) fx <- r$fx_rate; booked <- cc_find_booked(r, tx, xt)
      upd[[length(upd) + 1]] <- bump(r, status = "CLOSED", exit_level = xl, exit_ts = xt, pnl_instrument = pnl_i, fx_rate = fx,
                                     pnl_account_est = if (is.finite(fx)) pnl_i * fx else NA_real_, pnl_account_booked = booked,
                                     exit_code = if (is.na(r$exit_code) || !nzchar(r$exit_code)) cc_exit_code(r$direction, xl, r$stop_initial, r$stop_level, r$target_level) else r$exit_code)
      ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "POSITION_CLOSED", deal_id = r$deal_id, level = xl, note = if (is.finite(xl)) "Closed (from the activity history)" else "Closed: exit level not in the history yet")
      msgs <- c(msgs, sprintf("%s closed at %s.", r$trade_id, if (is.finite(xl)) format(xl) else "an unknown level (sync again later)")) } }
  # merge: a copy added by the earlier faulty sync (source PLATFORM) that matches an app trade (same market, side, size,
  # entry, time). The app trade takes the copy's position id and, when the copy has a real exit, that exit; the copy
  # becomes DUPLICATE. Works whether the position is still open or already closed.
  copies <- trades[trades$source %in% "PLATFORM" & !(trades$status %in% "DUPLICATE"), , drop = FALSE]
  copies <- rbind(copies, if (length(upd)) { uu <- do.call(rbind, lapply(upd, function(u) cc_coerce("trades", as.data.frame(u, stringsAsFactors = FALSE)))); uu[uu$source %in% "PLATFORM" & uu$status %in% c("OPEN", "CLOSED"), , drop = FALSE] } else NULL)
  copies <- copies[!duplicated(copies$trade_id, fromLast = TRUE), , drop = FALSE]
  apps <- trades[!(trades$source %in% "PLATFORM") & trades$status %in% c("OPEN", "CLOSED"), , drop = FALSE]
  for (k in seq_len(nrow(copies))) { cp <- copies[k, , drop = FALSE]
    pseudo <- data.frame(deal_id = cp$deal_id, epic = cp$epic, direction = cp$direction, size = cp$size, level = cp$entry_level,
                         created_utc = format(cp$entry_ts, "%Y-%m-%dT%H:%M:%S", tz = "UTC"), stringsAsFactors = FALSE)
    m <- cc_match_position_rows(apps, pseudo); if (!length(m)) next
    r <- as.list(apps[m[1], , drop = FALSE]); real_exit <- is.finite(cp$exit_level) && cp$exit_level > 0
    ch <- list(deal_id = cp$deal_id, status = cp$status)
    if (identical(cp$status, "CLOSED") && real_exit) ch <- c(ch, list(exit_level = cp$exit_level, exit_ts = cp$exit_ts, exit_code = cp$exit_code, pnl_instrument = cp$pnl_instrument,
                                                                    fx_rate = cp$fx_rate, pnl_account_est = cp$pnl_account_est, pnl_account_booked = cp$pnl_account_booked, balance_after = cp$balance_after))
    else ch <- c(ch, list(status = "OPEN", exit_level = NA_real_, exit_ts = as.POSIXct(NA, tz = "UTC"), exit_code = NA_character_, pnl_instrument = NA_real_, pnl_account_est = NA_real_, pnl_account_booked = NA_real_, balance_after = NA_real_))
    upd <- Filter(function(u) !identical(u$trade_id, cp$trade_id) && !identical(u$trade_id, r$trade_id), upd)
    upd[[length(upd) + 1]] <- do.call(bump, c(list(r), ch))
    upd[[length(upd) + 1]] <- bump(as.list(cp), status = "DUPLICATE", notes = paste("Duplicate of", r$trade_id, "(added by an earlier sync); not counted"))
    ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "MERGED", deal_id = cp$deal_id, level = if (real_exit) cp$exit_level else NA_real_,
                                       note = sprintf("Repaired: took the position id%s from %s, which becomes DUPLICATE", if (real_exit) " and the real exit" else "", cp$trade_id))
    msgs <- c(msgs, sprintf("Repaired %s (%s%s); %s marked DUPLICATE (not counted).", r$trade_id, ch$status, if (real_exit) sprintf(", exit %s", format(cp$exit_level)) else "", cp$trade_id))
    apps <- apps[apps$trade_id != r$trade_id, , drop = FALSE]
    trades$status[trades$trade_id == cp$trade_id] <- "DUPLICATE"; trades$deal_id[trades$trade_id == r$trade_id] <- cp$deal_id; trades$status[trades$trade_id == r$trade_id] <- ch$status }
  # repair: an app trade wrongly marked CLOSED by the earlier sync while its position is still open, and the copy that
  # sync added (source PLATFORM). The app trade is reopened on the position's id; the copy becomes DUPLICATE.
  if (nrow(pos)) for (k in seq_len(nrow(pos))) { p <- pos[k, , drop = FALSE]
    wrong <- trades[trades$status %in% "CLOSED" & !(trades$source %in% "PLATFORM") & !is.na(trades$epic) & !(trades$trade_id %in% vapply(upd, `[[`, "", "trade_id")), , drop = FALSE]
    wrong <- wrong[cc_match_position_rows(wrong, p), , drop = FALSE]
    wrong <- wrong[vapply(seq_len(nrow(wrong)), function(z) !nrow(act[!is.na(act$deal_id) & act$deal_id %in% stats::na.omit(c(wrong$deal_id[z], wrong$order_deal_id[z], p$deal_id)) & cc_is_close(act), , drop = FALSE]), TRUE), , drop = FALSE]
    if (!nrow(wrong)) next
    r <- as.list(wrong[1, ])
    upd[[length(upd) + 1]] <- bump(r, status = "OPEN", deal_id = p$deal_id, exit_level = NA_real_, exit_ts = as.POSIXct(NA, tz = "UTC"), exit_code = NA_character_, pnl_instrument = NA_real_,
                                   pnl_account_est = NA_real_, pnl_account_booked = NA_real_, balance_after = NA_real_, stop_level = p$stop_level, target_level = p$profit_level)
    ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "REOPENED", deal_id = p$deal_id, note = "Repaired: the position is still open on Capital.com (an earlier sync closed it by mistake)")
    msgs <- c(msgs, sprintf("Repaired %s: reopened (its position %s is still open).", r$trade_id, p$deal_id))
    dup <- trades[trades$source %in% "PLATFORM" & trades$status %in% "OPEN" & trades$deal_id %in% p$deal_id, , drop = FALSE]
    for (z in seq_len(nrow(dup))) { upd[[length(upd) + 1]] <- bump(as.list(dup[z, ]), status = "DUPLICATE", notes = paste("Duplicate of", r$trade_id, "(added by an earlier sync); not counted"))
      ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = dup$trade_id[z], event_type = "MARKED_DUPLICATE", deal_id = p$deal_id, note = paste("Duplicate of", r$trade_id))
      msgs <- c(msgs, sprintf("%s marked DUPLICATE of %s (not counted).", dup$trade_id[z], r$trade_id)) }
    trades$deal_id[trades$trade_id == r$trade_id] <- p$deal_id; trades$status[trades$trade_id == r$trade_id] <- "OPEN" }
  # the same trade recorded twice (whatever the source or the saved times): same market, side, size and entry price, and
  # recorded within 15 minutes of each other (entry time, order time or the time in the trade id). The app's own trade is
  # kept (it holds your words); it takes the other's position id and real exit; the other becomes DUPLICATE.
  done <- vapply(upd, `[[`, "", "trade_id")
  pool <- trades[!(trades$status %in% c("DUPLICATE", "REJECTED", "CANCELLED", "EXPIRED", "ORDER_WORKING")) & !(trades$trade_id %in% done), , drop = FALSE]
  if (nrow(pool) > 1) { tid_t <- cc_id_time(pool$trade_id)
    tms <- cbind(as.numeric(pool$entry_ts), as.numeric(pool$placed_ts), as.numeric(tid_t)); used <- character(0)
    for (i in seq_len(nrow(pool) - 1)) for (j in (i + 1):nrow(pool)) { a <- pool[i, ]; b <- pool[j, ]
      if (a$trade_id %in% used || b$trade_id %in% used) next
      mk <- (!is.na(a$epic) && identical(a$epic, b$epic)) || (!is.na(a$market_name) && identical(a$market_name, b$market_name))
      same <- mk && identical(toupper(a$direction), toupper(b$direction)) && isTRUE(abs(a$size - b$size) < 1e-9) &&
              isTRUE(abs(a$entry_level - b$entry_level) <= 0.002 * abs(a$entry_level))
      near <- isTRUE(suppressWarnings(min(abs(outer(tms[i, ], tms[j, ], "-")), na.rm = TRUE)) <= 900)
      if (!same) { if (mk && near) cat(sprintf("[C.C] %s and %s: same market but side/size/entry differ (%s %s %s vs %s %s %s): not merged\n", a$trade_id, b$trade_id,
                                        a$direction, a$size, a$entry_level, b$direction, b$size, b$entry_level)); next }
      dt <- suppressWarnings(min(abs(outer(tms[i, ], tms[j, ], "-")), na.rm = TRUE))
      if (!is.finite(dt) || dt > 900) { cat(sprintf("[C.C] %s and %s look alike but were recorded %.0f s apart: not merged\n", a$trade_id, b$trade_id, dt)); next }
      words <- function(x) sum(nzchar(stats::na.omit(unlist(x[intersect(c("setup_fund", "setup_tech", "trigger_text", "execution_text", "stop_reason", "target_reason", "exit_reason", "lessons", "analysis"), names(x))]))))
      pa <- a$source %in% "PLATFORM"; pb <- b$source %in% "PLATFORM"
      keep_a <- if (pa != pb) !pa else words(a) >= words(b)        # the app's trade, else the one with more of your words
      k <- if (keep_a) a else b; o <- if (keep_a) b else a
      real <- function(x) is.finite(x$exit_level) && x$exit_level > 0
      ch <- list()
      if (!real(k) && real(o)) ch <- list(status = o$status, deal_id = o$deal_id, exit_level = o$exit_level, exit_ts = o$exit_ts, exit_code = o$exit_code, pnl_instrument = o$pnl_instrument,
                                          fx_rate = o$fx_rate, pnl_account_est = o$pnl_account_est, pnl_account_booked = o$pnl_account_booked, balance_after = o$balance_after)
      else if (identical(o$status, "OPEN") && !identical(k$status, "OPEN") && !real(k)) ch <- list(status = "OPEN", deal_id = o$deal_id, exit_level = NA_real_, exit_ts = as.POSIXct(NA, tz = "UTC"),
                                          exit_code = NA_character_, pnl_instrument = NA_real_, pnl_account_est = NA_real_, pnl_account_booked = NA_real_)
      if (length(ch)) upd[[length(upd) + 1]] <- do.call(bump, c(list(as.list(k)), ch))
      upd[[length(upd) + 1]] <- bump(as.list(o), status = "DUPLICATE", notes = paste("Duplicate of", k$trade_id, "(the same trade recorded twice); not counted"))
      ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = k$trade_id, event_type = "MERGED", deal_id = o$deal_id, level = if (real(o)) o$exit_level else NA_real_,
                                         note = sprintf("The same trade was recorded twice; %s becomes DUPLICATE", o$trade_id))
      kk <- utils::modifyList(as.list(k), ch)
      msgs <- c(msgs, sprintf("Repaired %s (%s%s); %s marked DUPLICATE (the same trade, recorded twice; not counted).", k$trade_id, kk$status,
                              if (is.finite(kk$exit_level %||% NA) && kk$exit_level > 0) sprintf(", exit %s", format(kk$exit_level)) else "", o$trade_id))
      used <- c(used, a$trade_id, b$trade_id); trades$status[trades$trade_id == o$trade_id] <- "DUPLICATE" } }
  # repair: closed trades with no real exit (an earlier sync wrote 0 or nothing), or with no booked amount yet
  done <- vapply(upd, `[[`, "", "trade_id")
  fix <- trades[trades$status %in% "CLOSED" & !(trades$trade_id %in% done), , drop = FALSE]
  for (k in seq_len(nrow(fix))) { r <- as.list(fix[k, ]); no_exit <- !is.finite(r$exit_level) || r$exit_level <= 0
    if (no_exit) { fc <- cc_find_close(r, act); if (is.null(fc) || !is.finite(fc$level)) next
      d <- if (toupper(r$direction) == "BUY") 1 else -1; pnl_i <- d * (fc$level - r$entry_level) * cc_value_per_point(r$size, r$lot_size); fx <- fx_fun(r$instrument_currency); if (!is.finite(fx %||% NA)) fx <- r$fx_rate
      bk <- cc_find_booked(r, tx, fc$ts)
      upd[[length(upd) + 1]] <- bump(r, exit_level = fc$level, exit_ts = fc$ts, pnl_instrument = pnl_i, fx_rate = fx, pnl_account_est = if (is.finite(fx)) pnl_i * fx else NA_real_,
                                     pnl_account_booked = bk, exit_code = cc_exit_code(r$direction, fc$level, r$stop_initial, r$stop_level, r$target_level))
      ev[[length(ev) + 1]] <- data.frame(event_id = cc_id("EV"), trade_id = r$trade_id, event_type = "EXIT_REPAIRED", deal_id = fc$deal_id, level = fc$level, note = "Exit level taken from the activity history (an earlier sync had none)")
      msgs <- c(msgs, sprintf("Repaired %s: closed at %s%s.", r$trade_id, format(fc$level), if (is.finite(bk)) sprintf(", booked %.2f", bk) else ""))
    } else if (!is.finite(r$pnl_account_booked)) { bk <- cc_find_booked(r, tx, r$exit_ts); if (!is.finite(bk)) next
      upd[[length(upd) + 1]] <- bump(r, pnl_account_booked = bk)
      msgs <- c(msgs, sprintf("%s: Capital.com booked %.2f.", r$trade_id, bk)) } }
  # positions opened on the platform, unknown here
  newt <- list()
  live_tr <- trades[!(trades$status %in% c("DUPLICATE", "CANCELLED", "REJECTED", "EXPIRED")), , drop = FALSE]
  if (nrow(pos)) for (k in seq_len(nrow(pos))) { p <- pos[k, ]; if (p$deal_id %in% c(live_tr$deal_id, live_tr$order_deal_id)) next
    if (any(vapply(upd, function(u) identical(u$deal_id, p$deal_id), TRUE))) next
    if (length(cc_match_position_rows(live_tr[live_tr$status %in% "OPEN", , drop = FALSE], p))) next   # already an app trade: linked above, not added again
    newt[[length(newt) + 1]] <- data.frame(trade_id = cc_id("CC"), record_version = 1L, source = "PLATFORM", account_currency = account_currency, epic = p$epic, market_name = p$name,
      instrument_currency = p$currency, direction = p$direction, size = p$size, lot_size = p$lot_size, order_type = "MARKET", deal_reference = p$deal_reference, deal_id = p$deal_id,
      status = "OPEN", entry_ts = cc_ts(p$created_utc), entry_level = p$level, stop_initial = p$stop_level, stop_level = p$stop_level, target_level = p$profit_level,
      purpose = "PRACTICE", notes = "Opened on the Capital.com platform; found by sync", stringsAsFactors = FALSE)
    msgs <- c(msgs, sprintf("New position found on the platform: %s %s %s.", p$direction, p$size, p$epic)) }
  list(updated = if (length(upd)) do.call(rbind, lapply(upd, function(u) as.data.frame(u, stringsAsFactors = FALSE))) else NULL,
       new = if (length(newt)) do.call(rbind, newt) else NULL, events = if (length(ev)) do.call(rbind, lapply(ev, function(e) cc_coerce("events", e))) else NULL, messages = msgs)
}

# a close in the activity history (Capital.com: the position deleted / closed, by stop, target, hand or close-out)
cc_is_close <- function(a) { if (is.null(a) || !nrow(a)) return(logical(0))
  for (k in c("source", "type", "status", "json")) if (!k %in% names(a)) a[[k]] <- NA_character_
  txt <- toupper(paste(a$type %||% "", a$status %||% "", a$source %||% ""))
  js <- toupper(ifelse(is.na(a$json), "", a$json))
  # closed by stop / target / close-out, or by hand: the detailed history lists the action POSITION_CLOSED
  grepl("DELETED|CLOSED|CLOSE_OUT|CLOSEOUT", txt) | (grepl("^(SL|TP)$", toupper(a$source %||% "")) & grepl("POSITION", toupper(a$type %||% ""))) |
    grepl("\"ACTIONTYPE\":\"(POSITION_CLOSED|POSITION_PARTIALLY_CLOSED|POSITION_DELETED)\"", gsub("\\s", "", js)) }
# activity rows that belong to any of these deal ids (the row's own id, or an id named inside its details)
cc_act_for <- function(act, ids) { ids <- ids[!is.na(ids) & nzchar(ids)]; if (!nrow(act) || !length(ids)) return(act[0, , drop = FALSE])
  js <- if ("json" %in% names(act)) ifelse(is.na(act$json), "", act$json) else rep("", nrow(act))
  hit <- (!is.na(act$deal_id) & act$deal_id %in% ids) | Reduce(`|`, lapply(ids, function(i) grepl(i, js, fixed = TRUE)), FALSE)
  act[hit, , drop = FALSE] }
# the position a working order opened (activity history): list(deal_id, level, ts) or NULL. Rows naming the order id
# first; else the same market, side and size within 7 days, near the order level, not another trade's position.
cc_find_fill <- function(r, act, trades = NULL) { if (is.null(act) || !nrow(act)) return(NULL)
  for (k in c("json", "type", "status", "source", "date_utc")) if (!k %in% names(act)) act[[k]] <- NA_character_
  ts <- cc_ts(act$date_utc); js <- toupper(gsub("\\s", "", ifelse(is.na(act$json), "", act$json))); cl <- cc_is_close(act)
  # the fill is the POSITION row naming the order as workingOrderId (not the order's own EXECUTED row)
  opening <- !cl & is.finite(act$level) & !grepl("WORKING_ORDER", toupper(act$type %||% "")) & (grepl("POSITION_OPENED", js) | grepl("POSITION", toupper(act$type %||% "")))
  opening <- opening & !grepl("REJECT|CANCEL|DELETE", toupper(paste(act$status, act$type)))
  t0 <- as.numeric(if (!is.na(r$placed_ts %||% NA)) r$placed_ts else as.POSIXct("1970-01-01", tz = "UTC"))
  same <- act$epic %in% r$epic & toupper(act$direction %||% "") == toupper(r$direction) & is.finite(act$size) & abs(act$size - r$size) < 1e-9 & as.numeric(ts) >= t0 - 60 & as.numeric(ts) <= t0 + 7 * 86400
  own <- cc_act_for(act, r$order_deal_id)$json; named <- !is.na(act$json) & act$json %in% own
  lv <- if (is.finite(r$order_level %||% NA)) r$order_level else NA_real_
  near <- !is.finite(lv) | abs(act$level - lv) <= max(0.005 * abs(lv), 1e-9)
  taken <- if (is.null(trades)) character(0) else stats::na.omit(trades$deal_id[trades$trade_id != r$trade_id & !(trades$status %in% "DUPLICATE")])
  cand <- which(opening & same & (named | near))
  if (!length(cand)) return(NULL)
  pid <- vapply(cand, function(i) { m <- regmatches(act$json[i], regexpr('"actionType"\\s*:\\s*"POSITION_OPENED"\\s*,\\s*"affectedDealId"\\s*:\\s*"[^"]+"', act$json[i]))
    if (length(m)) sub('.*"([^"]+)"$', "\\1", m) else act$deal_id[i] }, "")
  ok <- !(pid %in% taken); cand <- cand[ok]; pid <- pid[ok]; if (!length(cand)) return(NULL)
  o <- order(-named[cand], as.numeric(ts[cand])); i <- cand[o[1]]
  list(deal_id = pid[o[1]], level = act$level[i], ts = ts[i])
}
# a close found in the history for this trade: list(level, ts) or NULL. Ids first; otherwise the opening row of the same
# market, side, size and price (within 15 min) gives the position id, and that id's close is used.
cc_find_close <- function(r, act) { if (!nrow(act)) return(NULL)
  ids <- c(r$deal_id, r$order_deal_id); a <- cc_act_for(act, ids); cl <- a[cc_is_close(a), , drop = FALSE]
  if (!nrow(cl)) { op <- act[!cc_is_close(act) & act$epic %in% r$epic & toupper(act$direction %||% "") == toupper(r$direction) & is.finite(act$size) & abs(act$size - r$size) < 1e-9 &
                             is.finite(act$level) & is.finite(r$entry_level) & abs(act$level - r$entry_level) <= 0.002 * abs(r$entry_level), , drop = FALSE]
    t_r <- as.numeric(if (!is.na(r$entry_ts)) r$entry_ts else r$placed_ts)
    if (nrow(op) && is.finite(t_r)) op <- op[abs(as.numeric(cc_ts(op$date_utc)) - t_r) <= 900, , drop = FALSE]
    if (nrow(op)) { a <- cc_act_for(act, unique(op$deal_id)); cl <- a[cc_is_close(a), , drop = FALSE] } }
  if (!nrow(cl)) return(NULL)
  cl <- cl[order(cl$date_utc), , drop = FALSE]; xl <- utils::tail(cl$level[is.finite(cl$level) & cl$level > 0], 1)
  list(level = if (length(xl)) xl else NA_real_, ts = cc_ts(utils::tail(cl$date_utc, 1)), deal_id = utils::tail(cl$deal_id, 1)) }
# the amount Capital.com booked for a close: the trade transaction within 5 minutes of the exit
cc_find_booked <- function(r, tx, xt) { if (!nrow(tx) || is.na(xt)) return(NA_real_)
  tt <- tx[grepl("TRADE|PNL|PROFIT|LOSS|CLOSE", toupper(tx$type)) & (is.na(r$market_name) | tx$instrument == r$market_name), , drop = FALSE]
  if (!nrow(tt)) return(NA_real_); dtt <- abs(as.numeric(difftime(cc_ts(tt$date_utc), xt, units = "secs"))); j <- which.min(dtt)
  if (length(j) && is.finite(dtt[j]) && dtt[j] <= 300) tt$amount[j] else NA_real_ }
# the same position: same market, side and size, entry within 0.2% and opened within 15 minutes of the app trade
cc_match_position_rows <- function(tr, p) { if (is.null(tr) || !nrow(tr)) return(integer(0))
  t_open <- cc_ts(p$created_utc); when <- ifelse(is.na(tr$entry_ts), as.numeric(tr$placed_ts), as.numeric(tr$entry_ts))
  ok <- tr$epic %in% p$epic & toupper(tr$direction) == toupper(p$direction) & abs(tr$size - p$size) < 1e-9 &
        is.finite(tr$entry_level) & abs(tr$entry_level - p$level) <= 0.002 * abs(p$level) &
        (is.na(t_open) | is.na(when) | abs(when - as.numeric(t_open)) <= 900)
  which(ok %in% TRUE) }
cc_match_position <- function(r, pos) { k <- integer(0); for (i in seq_len(nrow(pos))) if (length(cc_match_position_rows(as.data.frame(r, stringsAsFactors = FALSE), pos[i, , drop = FALSE]))) k <- c(k, i); k }

# the time written in a trade id (CC_YYYYmmddHHMMSS.sss_xxxx, UTC)
cc_id_time <- function(id) { x <- sub("^[A-Z]+_(\\d{14}(\\.\\d+)?)_.*$", "\\1", id); x[x == id] <- NA
  as.POSIXct(x, format = "%Y%m%d%H%M%OS", tz = "UTC") }
# records check without Capital.com: the saved trades, activity and transactions only. Merges a trade recorded twice,
# repairs exits written as 0, fills booked amounts. Working orders are left alone (that needs the live order list).
cc_repair_records <- function(trades, activity, transactions) {
  if (is.null(trades) || !nrow(trades)) return(list(updated = NULL, events = NULL, messages = character(0)))
  tr <- trades[!(trades$status %in% "ORDER_WORKING"), , drop = FALSE]
  rc <- cc_reconcile(tr, NULL, NULL, activity, transactions, fx_fun = function(ccy) NA_real_)
  rc$messages <- rc$messages[!grepl("left OPEN", rc$messages)]; rc }
# one line after every sync: where the trades stand
cc_trades_state <- function(t) { if (is.null(t) || !nrow(t)) return(NULL); t <- t[!(t$status %in% c("DUPLICATE")), , drop = FALSE]
  op <- sum(t$status %in% "OPEN"); wk <- sum(t$status %in% "ORDER_WORKING"); cl <- t[t$status %in% "CLOSED", , drop = FALSE]
  last <- if (nrow(cl)) { x <- cl[order(cl$exit_ts, decreasing = TRUE), , drop = FALSE][1, ]; pnl <- if (is.finite(x$pnl_account_booked)) x$pnl_account_booked else x$pnl_account_est
    sprintf(" Last closed: %s %s %s %s, exit %s, %s.", x$trade_id, x$direction, x$size, x$market_name %||% x$epic,
            if (is.finite(x$exit_level) && x$exit_level > 0) format(x$exit_level) else "not known yet", if (is.finite(pnl)) sprintf("%.2f %s", pnl, x$account_currency %||% "") else "result not known yet") } else ""
  sprintf("Your trades: %d open, %d working order(s), %d closed.%s", op, wk, nrow(cl), last) }

# ---- statistics of closed trades ----------------------------------------------------------------------------------------
cc_trade_stats <- function(trades, opening_balance = NA) {
  cl <- trades[trades$status %in% "CLOSED" & is.finite(trades$exit_level) & trades$exit_level > 0, , drop = FALSE]; if (!nrow(cl)) return(NULL)   # no real exit price: not counted
  pnl <- ifelse(is.finite(cl$pnl_account_booked), cl$pnl_account_booked, cl$pnl_account_est)
  d <- ifelse(toupper(cl$direction) == "BUY", 1, -1)
  r <- ifelse(is.finite(cl$stop_initial) & is.finite(cl$entry_level) & abs(cl$entry_level - cl$stop_initial) > 0,
              d * (cl$exit_level - cl$entry_level) / abs(cl$entry_level - cl$stop_initial), NA_real_)
  cl$pnl <- pnl; cl$real_r <- r; cl <- cl[order(cl$exit_ts), , drop = FALSE]
  list(trades = cl, n = nrow(cl), wins = sum(cl$pnl > 0, na.rm = TRUE), losses = sum(cl$pnl < 0, na.rm = TRUE), net = sum(cl$pnl, na.rm = TRUE),
       avg_win = mean(cl$pnl[cl$pnl > 0], na.rm = TRUE), avg_loss = mean(cl$pnl[cl$pnl < 0], na.rm = TRUE), avg_r = mean(cl$real_r, na.rm = TRUE),
       equity = if (is.finite(opening_balance)) opening_balance + cumsum(ifelse(is.finite(cl$pnl), cl$pnl, 0)) else cumsum(ifelse(is.finite(cl$pnl), cl$pnl, 0)))
}

# ---- the Trading Desk (one sidebar item): a module's tabs either drawn as its own tab box, or handed back as parts
desk_tabbox <- function(parts, ...) {
  a <- list(...)
  if (!isTRUE(parts)) return(do.call(shinydashboard::tabBox, a))
  nm <- names(a); structure(a[if (is.null(nm)) seq_along(a) else !nzchar(nm)], class = "desk_parts")
}
desk_parts <- function(ui) { for (x in ui) if (inherits(x, "desk_parts")) return(unclass(x)); stop("no tabs found in this UI") }
