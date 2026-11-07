# R/utils_trading_records.R
# Durable record-keeping for the 4-week trading period (own records): schema, validation,
# trade maths, Blotter-style statistics, and a storage layer with BigQuery + a safe
# in-session "pending" queue when BigQuery is not connected.
#
# DESIGN: every table is APPEND-ONLY. Editing a record writes a new row with the same key and
# a higher record_version / later saved_at; readers take the latest row per key. This avoids
# UPDATE/DELETE statements (which some BigQuery tiers restrict), keeps a full audit history
# (useful for showing that records were made at the time), and makes writes safe to retry.
#
# Nothing here generates trades or results. All values come from what the user types.

# ---- Schema -------------------------------------------------------------------------------
tr_tables <- list(
  settings = list(table = "trading_settings", key = "setting_key",
    cols = c(setting_key = "STRING", setting_value = "STRING", saved_at = "TIMESTAMP")),

  morning_sheets = list(table = "trading_morning_sheets", key = "sheet_id",
    cols = c(sheet_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", sheet_date = "DATE",
             week_no = "INT64", dow_price = "FLOAT64", dow_change_pct = "FLOAT64", nikkei_price = "FLOAT64",
             nikkei_change_pct = "FLOAT64", overnight_news = "STRING", overnight_calendar = "STRING",
             todays_releases = "STRING", releases_in_window = "STRING", regime_summary = "STRING",
             planned_setups = "STRING", exposure_note = "STRING", combined_open_risk_pct = "FLOAT64",
             stand_aside = "BOOL", stand_aside_reason = "STRING",
             dow_change_pts = "FLOAT64", nikkei_change_pts = "FLOAT64", trader_name = "STRING")),

  morning_levels = list(table = "trading_morning_levels", key = "level_id",
    cols = c(level_id = "STRING", sheet_id = "STRING", saved_at = "TIMESTAMP", sheet_date = "DATE",
             instrument = "STRING", overnight_low = "FLOAT64", overnight_high = "FLOAT64",
             current_price = "FLOAT64", time_now_uk = "STRING", adx14 = "FLOAT64", regime_label = "STRING",
             prior_high = "FLOAT64", prior_low = "FLOAT64", prior_close = "FLOAT64",
             pivot_pp = "FLOAT64", pivot_r1 = "FLOAT64", pivot_s1 = "FLOAT64",
             pivot_r2 = "FLOAT64", pivot_s2 = "FLOAT64", pivot_r3 = "FLOAT64", pivot_s3 = "FLOAT64")),

  trades = list(table = "trading_trades", key = "trade_id",
    cols = c(trade_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", parent_trade_id = "STRING",
             status = "STRING", week_no = "INT64", asset = "STRING", strategy = "STRING", direction = "STRING",
             chart_period = "STRING", entry_ts = "TIMESTAMP", expected_duration_hours = "FLOAT64",
             pip_size = "FLOAT64", stake_per_pip_gbp = "FLOAT64", entry_price = "FLOAT64",
             stop1 = "FLOAT64", stop2 = "FLOAT64", stop3 = "FLOAT64", stop4 = "FLOAT64", target = "FLOAT64",
             initial_risk_pips = "FLOAT64", initial_reward_pips = "FLOAT64", initial_rrr = "FLOAT64",
             initial_risk_gbp = "FLOAT64", risk_pct_equity = "FLOAT64", regime_adx = "FLOAT64",
             regime_label = "STRING", correlated_open_risk_pct = "FLOAT64", mood_entry = "INT64",
             setup_fundamental = "STRING", setup_technical = "STRING", trigger_text = "STRING",
             execution_text = "STRING", stop_reason = "STRING", target_reason = "STRING",
             plan_followed = "BOOL", deviation_type = "STRING", deviation_note = "STRING",
             exit_ts = "TIMESTAMP", exit_price = "FLOAT64", exit_code = "STRING", pips_result = "FLOAT64",
             net_pnl_gbp = "FLOAT64", pnl_source = "STRING", real_r = "FLOAT64", duration_hours = "FLOAT64",
             mood_exit = "INT64", reason_for_exit = "STRING", lessons_learned = "STRING",
             trade_sheet_name = "STRING", notes = "STRING",
             entry_source = "STRING", evidence_ids = "STRING", verified_by_user = "BOOL",
             asset_class = "STRING", market = "STRING", market_name_raw = "STRING", contract_type = "STRING", account_type = "STRING",
             is_demo = "BOOL", source_device = "STRING", deal_reference = "STRING", size_unit = "STRING", price_basis = "STRING",
             spread_pts = "FLOAT64", margin_gbp = "FLOAT64", notional_gbp = "FLOAT64", costs_gbp = "FLOAT64",
             me_then_hit_stop = "BOOL", me_then_hit_target = "BOOL", trade_purpose = "STRING", charts_dropbox_path = "STRING",
             score_patterns = "INT64", score_sr = "INT64", score_candles = "INT64", score_rsi = "INT64", score_fibs = "INT64")),

  trade_events = list(table = "trading_trade_events", key = "event_id",
    cols = c(event_id = "STRING", trade_id = "STRING", saved_at = "TIMESTAMP", event_ts = "TIMESTAMP",
             event_type = "STRING", old_stop = "FLOAT64", new_stop = "FLOAT64", size_closed_per_pip = "FLOAT64",
             price = "FLOAT64", reason = "STRING", permitted_by_spec = "BOOL")),

  evidence = list(table = "trading_evidence", key = "evidence_id",
    cols = c(evidence_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", kind = "STRING", status = "STRING",
             trade_id = "STRING", file_name = "STRING", file_md5 = "STRING", mime = "STRING", size_bytes = "INT64",
             dropbox_path = "STRING", model = "STRING", extracted_json = "STRING", confirmed_json = "STRING",
             checks_json = "STRING", input_tokens = "INT64", output_tokens = "INT64", user_notes = "STRING",
             source_device = "STRING", screen_type = "STRING", asset_code = "STRING", asset_class = "STRING", market = "STRING",
             contract_type = "STRING"))
)

tr_bq_type <- function(t) c(STRING = "STRING", INT64 = "INT64", FLOAT64 = "FLOAT64", BOOL = "BOOL",
                            TIMESTAMP = "TIMESTAMP", DATE = "DATE")[[t]]

# CREATE TABLE IF NOT EXISTS, then ALTER TABLE ADD COLUMN IF NOT EXISTS for columns added after the
# first release (so an already-created table is upgraded in place), then the "_current" views
# (latest row per key). Views are created LAST so they pick up every column.
tr_ddl <- function(project, dataset) {
  creates <- character(0); alters <- character(0); views <- character(0)
  for (nm in names(tr_tables)) {
    tb <- tr_tables[[nm]]
    full <- sprintf("%s.%s.%s", project, dataset, tb$table)
    cols <- paste(sprintf("  %s %s", names(tb$cols), vapply(tb$cols, tr_bq_type, "")), collapse = ",\n")
    creates <- c(creates, sprintf("CREATE TABLE IF NOT EXISTS `%s` (\n%s\n)", full, cols))
    for (cn in tb$added) alters <- c(alters, sprintf("ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS %s %s", full, cn, tr_bq_type(tb$cols[[cn]])))
    order_by <- if ("record_version" %in% names(tb$cols)) "saved_at DESC, record_version DESC" else "saved_at DESC"
    views <- c(views, sprintf(
      "CREATE OR REPLACE VIEW `%s_current` AS\nSELECT * EXCEPT(rn) FROM (\n  SELECT *, ROW_NUMBER() OVER (PARTITION BY %s ORDER BY %s) AS rn\n  FROM `%s`\n) WHERE rn = 1",
      full, tb$key, order_by, full))
  }
  c(creates, alters, views)
}

# ---- Coercion / helpers -------------------------------------------------------------------
tr_blank_na <- function(x) { if (is.null(x) || length(x) == 0) return(NA_character_); x <- as.character(x); x[is.na(x) | !nzchar(trimws(x))] <- NA_character_; x }
tr_num <- function(x) suppressWarnings(as.numeric(if (is.null(x) || length(x) == 0) NA else x))
tr_now <- function() Sys.time()
# Today's date on the London clock (the app's default date whenever a screenshot shows none)
tr_london_today <- function() as.Date(format(Sys.time(), "%Y-%m-%d", tz = "Europe/London"))
tr_id <- function(prefix) sprintf("%s_%s_%04x", prefix, format(Sys.time(), "%Y%m%d%H%M%OS3", tz = "UTC"), sample.int(65535, 1))

tr_coerce <- function(name, df) {
  sch <- tr_tables[[name]]$cols
  n <- if (is.null(df)) 0L else nrow(df)
  out <- vector("list", length(sch)); names(out) <- names(sch)
  for (cn in names(sch)) {
    v <- if (!is.null(df) && cn %in% names(df)) df[[cn]] else rep(NA, n)
    out[[cn]] <- switch(sch[[cn]],
      STRING = as.character(v), INT64 = suppressWarnings(as.integer(v)), FLOAT64 = suppressWarnings(as.numeric(v)),
      BOOL = as.logical(v),
      TIMESTAMP = if (inherits(v, "POSIXct")) { attr(v, "tzone") <- "UTC"; v } else as.POSIXct(v, tz = "UTC"),
      DATE = as.Date(v))
  }
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

# Latest row per key (append-only tables).
tr_latest <- function(name, df) {
  if (is.null(df) || nrow(df) == 0) return(df)
  key <- tr_tables[[name]]$key
  rv <- if ("record_version" %in% names(df)) df$record_version else rep(0L, nrow(df))
  o <- order(df$saved_at, rv, na.last = FALSE)
  df <- df[o, , drop = FALSE]
  df[!duplicated(df[[key]], fromLast = TRUE), , drop = FALSE]
}

# Date + "HH:MM" entered in UK time -> UTC POSIXct (NA if unparseable).
tr_parse_ts <- function(date, hhmm, tz = "Europe/London") {
  if (is.null(date) || length(date) == 0 || is.na(date)) return(as.POSIXct(NA, tz = "UTC"))
  m <- regmatches(hhmm, regexec("^\\s*([0-2]?[0-9])[:.]?([0-5][0-9])\\s*$", hhmm))[[1]]
  if (length(m) != 3) return(as.POSIXct(NA, tz = "UTC"))
  h <- as.integer(m[2]); mi <- as.integer(m[3])
  if (h > 23) return(as.POSIXct(NA, tz = "UTC"))
  p <- as.POSIXct(sprintf("%s %02d:%02d:00", format(as.Date(date)), h, mi), tz = tz)
  attr(p, "tzone") <- "UTC"; p
}

tr_week_no <- function(date, start) {
  if (is.na(date) || is.na(start)) return(NA_integer_)
  w <- floor(as.numeric(as.Date(date) - as.Date(start)) / 7) + 1
  if (w < 1 || w > 4) NA_integer_ else as.integer(w)
}

tr_dir <- function(bs) ifelse(toupper(substr(bs, 1, 1)) == "B", 1, -1)

tr_pivots <- function(h, l, c) {
  if (any(!is.finite(c(h, l, c)))) return(list(pp = NA_real_, r1 = NA_real_, s1 = NA_real_, r2 = NA_real_, s2 = NA_real_, r3 = NA_real_, s3 = NA_real_))
  pp <- (h + l + c) / 3; s1 <- pp - (h - pp); r1 <- pp - (l - pp)     # LAT course formulas (seven levels)
  list(pp = pp, r1 = r1, s1 = s1, r2 = pp + (r1 - s1), s2 = pp - (r1 - s1), r3 = h + 2 * (pp - l), s3 = l - 2 * (h - pp))
}

tr_regime <- function(adx, trend_min = 30, range_max = 20) {
  if (!is.finite(adx)) return(NA_character_)
  if (adx > trend_min) "TREND" else if (adx < range_max) "RANGE" else "UNCLEAR_NO_TRADE"
}

# ---- Trade maths --------------------------------------------------------------------------
tr_entry_calc <- function(direction, entry, stop1, target, pip_size, stake) {
  d <- tr_dir(direction)
  risk_pips <- (entry - stop1) * d / pip_size
  reward_pips <- (target - entry) * d / pip_size
  list(risk_pips = risk_pips, reward_pips = reward_pips,
       rrr = if (is.finite(risk_pips) && risk_pips > 0) reward_pips / risk_pips else NA_real_,
       risk_gbp = risk_pips * stake)
}

# Returns character(0) when valid, otherwise a vector of problems.
tr_validate_entry <- function(direction, entry, stop1, target, pip_size, stake, mood = NA, entry_ts = NA) {
  e <- character(0)
  if (!all(is.finite(c(entry, stop1, target, pip_size, stake)))) return("Entry, stop, target, pip size and stake per pip must all be numbers.")
  if (pip_size <= 0 || stake <= 0) e <- c(e, "Pip size and stake per pip must be above zero.")
  d <- tr_dir(direction)
  if ((entry - stop1) * d <= 0) e <- c(e, "The stop must be on the losing side of the entry (below for a buy, above for a sell).")
  if ((target - entry) * d <= 0) e <- c(e, "The target must be on the winning side of the entry (above for a buy, below for a sell).")
  if (is.finite(mood) && !(mood %in% 1:5)) e <- c(e, "Mood must be 1 to 5.")
  if (is.na(entry_ts)) e <- c(e, "Entry date/time is not valid (use HH:MM, UK time).")
  e
}

tr_close_calc <- function(direction, entry, exit_price, pip_size, stake, risk_gbp, pnl_override = NA) {
  d <- tr_dir(direction)
  pips <- (exit_price - entry) * d / pip_size
  calc <- pips * stake
  use_stmt <- is.finite(pnl_override)
  net <- if (use_stmt) pnl_override else calc
  list(pips = pips, pnl_calc = calc, net = net, source = if (use_stmt) "PLATFORM" else "CALCULATED",
       real_r = if (is.finite(risk_gbp) && risk_gbp > 0) net / risk_gbp else NA_real_)
}

# ---- Blotter-style statistics -------------------------------------------------------------
tr_stats <- function(closed, opening_balance = 10000) {
  closed <- closed[!is.na(closed$net_pnl_gbp), , drop = FALSE]
  if (nrow(closed) == 0) return(NULL)
  closed <- closed[order(closed$exit_ts, closed$entry_ts), , drop = FALSE]
  n <- nrow(closed); pnl <- closed$net_pnl_gbp
  wins <- sum(pnl > 0); losses <- sum(pnl < 0); be <- sum(pnl == 0)
  equity <- opening_balance + cumsum(pnl)
  eq_all <- c(opening_balance, equity)
  peak <- cummax(eq_all)
  dd_pct <- eq_all / peak - 1
  dd_gbp <- eq_all - peak
  before <- eq_all[-length(eq_all)]
  ret <- pnl / before
  sharpe <- if (n >= 2 && isTRUE(sd(ret) > 0)) mean(ret) / sd(ret) else NA_real_
  dsd <- sqrt(mean(pmin(ret, 0)^2))
  sortino <- if (n >= 2 && dsd > 0) mean(ret) / dsd else NA_real_
  pf <- if (losses > 0) sum(pnl[pnl > 0]) / abs(sum(pnl[pnl < 0])) else NA_real_
  foll <- closed$plan_followed[!is.na(closed$plan_followed)]
  summary <- list(
    trades = n, wins = wins, losses = losses, breakeven = be, win_rate = wins / n,
    avg_win_gbp = if (wins) mean(pnl[pnl > 0]) else NA_real_,
    avg_loss_gbp = if (losses) mean(pnl[pnl < 0]) else NA_real_,
    profit_factor = pf,
    avg_initial_rrr = mean(closed$initial_rrr, na.rm = TRUE),
    avg_real_r = mean(closed$real_r, na.rm = TRUE),
    avg_win_r = if (wins) mean(closed$real_r[pnl > 0], na.rm = TRUE) else NA_real_,
    avg_loss_r = if (losses) mean(closed$real_r[pnl < 0], na.rm = TRUE) else NA_real_,
    total_pnl_gbp = sum(pnl), return_pct = sum(pnl) / opening_balance,
    max_drawdown_gbp = min(dd_gbp), max_drawdown_pct = min(dd_pct),
    adherence_rate = if (length(foll)) mean(foll) else NA_real_,
    followed = sum(foll), deviations = sum(!foll), adherence_recorded = length(foll),
    avg_duration_hours = mean(closed$duration_hours, na.rm = TRUE),
    sharpe_per_trade = sharpe, sortino_per_trade = sortino)
  eq <- data.frame(trade_no = 0:n, exit_ts = c(as.POSIXct(NA, tz = "UTC"), closed$exit_ts),
                   equity = eq_all, drawdown_pct = dd_pct, stringsAsFactors = FALSE)
  grp <- function(col) {
    v <- closed[[col]]; v[is.na(v) | !nzchar(v)] <- "(none)"
    do.call(rbind, lapply(split(seq_len(n), v), function(ix) data.frame(
      Group = v[ix[1]], Trades = length(ix), Wins = sum(pnl[ix] > 0),
      `Win rate` = mean(pnl[ix] > 0), `Net P/L (GBP)` = sum(pnl[ix]),
      `Avg Real R` = mean(closed$real_r[ix], na.rm = TRUE), check.names = FALSE, stringsAsFactors = FALSE)))
  }
  lt <- as.POSIXlt(closed$entry_ts, tz = "Europe/London")
  wd <- factor(c("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")[lt$wday + 1], levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday"))
  bucket <- cut(lt$hour, breaks = seq(0, 24, 2), right = FALSE,
                labels = sprintf("%02d:00-%02d:00", seq(0, 22, 2), seq(2, 24, 2)))
  list(summary = summary, equity = eq,
       by_asset = grp("asset"), by_strategy = grp("strategy"), by_exit = grp("exit_code"),
       by_weekday = as.data.frame(table(Day = wd), responseName = "Trades"),
       by_hour = as.data.frame(table(`Entry time (UK)` = bucket), responseName = "Trades"),
       by_mood = { m <- closed$mood_entry; ok <- !is.na(m)
                   if (any(ok)) do.call(rbind, lapply(split(which(ok), m[ok]), function(ix) data.frame(
                     Mood = m[ix[1]], Trades = length(ix), `Avg Real R` = mean(closed$real_r[ix], na.rm = TRUE),
                     check.names = FALSE))) else NULL },
       trades = closed)
}

# ---- Storage layer ------------------------------------------------------------------------
# backend: list(connected(), ensure(), write(name, df), read(name))
tr_bq_backend <- function(api) {
  list(
    connected = function() isTRUE(api$bq_authenticated),
    ensure = function() {
      for (stmt in tr_ddl(api$bq_project_id, api$bq_dataset_id)) {
        cat("[Records] DDL:", substr(gsub("\\s+", " ", stmt), 1, 110), "...\n")
        bigrquery::bq_project_query(api$bq_project_id, stmt)
      }
      invisible(TRUE)
    },
    write = function(name, df) {
      tb <- tr_tables[[name]]
      ref <- bigrquery::bq_table(api$bq_project_id, api$bq_dataset_id, tb$table)
      existing <- tryCatch(bigrquery::bq_table_fields(ref), error = function(e) NULL)
      if (!is.null(existing)) {
        en <- vapply(existing, function(f) f$name, character(1))
        if (!setequal(en, names(tb$cols)))
          stop("Table ", tb$table, " exists with different columns. Table: ", paste(en, collapse = ", "),
               " | App: ", paste(names(tb$cols), collapse = ", "), ". Run 'Create / verify tables' or fix the table.")
      }
      cat("[Records] Uploading", nrow(df), "row(s) ->", tb$table, "\n")
      bigrquery::bq_table_upload(ref, df, create_disposition = "CREATE_IF_NEEDED", write_disposition = "WRITE_APPEND")
      invisible(nrow(df))
    },
    read = function(name) {
      tb <- tr_tables[[name]]
      q <- sprintf("SELECT * FROM `%s.%s.%s`", api$bq_project_id, api$bq_dataset_id, tb$table)
      bigrquery::bq_table_download(bigrquery::bq_project_query(api$bq_project_id, q))
    })
}

tr_make_store <- function(backend) {
  pending <- new.env(parent = emptyenv()); pending$data <- list()
  add_pending <- function(name, df) pending$data[[name]] <- rbind(pending$data[[name]], df)
  store <- list()
  store$connected <- function() isTRUE(backend$connected())
  store$ensure <- function() backend$ensure()
  store$write <- function(name, df) {
    stopifnot(name %in% names(tr_tables))
    df <- tr_coerce(name, df)
    if (nrow(df) == 0) return(invisible("empty"))
    df$saved_at <- rep(tr_now(), nrow(df)) + seq_len(nrow(df)) * 1e-6
    attr(df$saved_at, "tzone") <- "UTC"
    if (store$connected()) {
      tryCatch({ backend$write(name, df); invisible("bigquery") },
               error = function(e) { cat("[Records] BigQuery write failed, queued locally:", conditionMessage(e), "\n")
                                    add_pending(name, df); invisible(paste("queued:", conditionMessage(e))) })
    } else { add_pending(name, df); invisible("pending") }
  }
  store$read <- function(name) {
    remote <- NULL
    if (store$connected()) remote <- tryCatch(tr_coerce(name, backend$read(name)), error = function(e) {
      cat("[Records] BigQuery read failed for", name, ":", conditionMessage(e), "\n"); NULL })
    out <- rbind(if (is.null(remote)) tr_coerce(name, NULL) else remote,
                 if (is.null(pending$data[[name]])) tr_coerce(name, NULL) else pending$data[[name]])
    out
  }
  store$pending_count <- function() sum(vapply(pending$data, function(d) if (is.null(d)) 0L else nrow(d), 0L))
  store$pending_data <- function() pending$data
  store$sync <- function() {
    if (!store$connected()) stop("BigQuery is not connected.")
    n <- 0L
    for (name in names(pending$data)) {
      d <- pending$data[[name]]
      if (!is.null(d) && nrow(d) > 0) { backend$write(name, d); n <- n + nrow(d); pending$data[[name]] <- NULL }
    }
    n
  }
  store
}

# Latest-row convenience: read + dedupe.
tr_read_current <- function(store, name) tr_latest(name, store$read(name))

# =============================================================================================
# Order evidence: screenshot -> fields with Claude (vision), and platform statement import
# =============================================================================================
# Claude is used ONLY to transcribe what is visible on a platform screen into fields. It is told
# not to analyse, advise or infer. Every extraction is shown to the user next to the image,
# can be edited, and is checked by deterministic rules before it is used. The reasoning fields
# of a trade (set-up, trigger, reasons, lessons) are never filled by Claude.

tr_vision_system <- function() paste(
  "You are a transcription tool for trading-platform screenshots.",
  "Copy values exactly as they appear on the screen. Never estimate, calculate, infer or correct a value.",
  "If a value is not clearly visible, use null. Do not give analysis, opinions or advice.",
  "Reply with ONE JSON object only, no markdown fences and no commentary.")

# Fallback value helper (the Trading Records module defines the same function).
if (!exists("tr_or", inherits = TRUE)) tr_or <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

tr_vision_kinds <- c(
  "Auto-detect the screen" = "auto",
  "Open position / deal confirmation (entry)" = "open",
  "Order / deal ticket (before placing)" = "ticket",
  "Closed position / deal confirmation (exit)" = "close",
  "Market screen (price snapshot)" = "market",
  "Account history or statement screen" = "history")

# Where the screenshot came from. The layout differs, so the instruction sent to Claude differs.
tr_vision_sources <- c("Mobile app" = "mobile", "Desktop website" = "desktop")

tr_vision_source_notes <- function(source = "mobile") {
  if (identical(source, "desktop")) paste(
    "SOURCE: the IG website trading platform in a computer browser (spread bet or CFD, possibly a DEMO account).",
    "Typical screens: (1) DEAL TICKET (a panel beside the chart): the market name at the top, Sell and Buy prices, Size with its unit (for example 'GBP(£) per point'),",
    "a Stop row and a Limit row that each show a distance ('pts away'), a price LEVEL and a money amount (the £ at risk for the stop, the £ reward for the limit),",
    "a contract toggle ('Undated' means a daily funded bet, 'Futures' means a dated contract), Margin, Notional or exposure value, 'Resulting position', 'Indicative opening costs',",
    "and a label such as 'Risk/reward ratio 1.5:1'. A ticket is not a placed trade: the prices on it are indicative quotes.",
    "(2) POSITIONS table (open trades), one row per position, columns MARKET, SIZE (signed: + is long, - is short), OPENING, LATEST, STOP, LIMIT, PROFIT/LOSS and often a date.",
    "(3) ORDERS table (working orders not yet filled). (4) HISTORY page or closed-positions table (for example 'Closed in the last 24 hours' with columns DATE / TIME, MARKET, SIZE, OPENING, CLOSING, PROFIT / LOSS): screen_type closed_trades. One row per closed deal; DATE / TIME is the CLOSING date and time, so put the date in close_date_text and the clock (HH:MM) in time_text.",
    "(5) the chart, with the market name and a price. A table can show several rows: transcribe only the row that is selected or most prominent.",
    "(6) HISTORY > ACTIVITY: a list of actions with DATE, TIME, an activity or type column (for example 'Position opened', 'Position closed', 'Stop amended'), MARKET, DIRECTION, SIZE, LEVEL, STOP, LIMIT and a reference: screen_type activity.",
    "For the selected or most prominent row put the date in date_text, the clock (HH:MM) in time_text, copy the activity words into activity_text, and put LEVEL into entry_price when the row opens a position or into exit_price when it closes one. This is the screen that shows the time a position was opened.",
    "In the Positions table OPENING is the entry price and LATEST is the current price. The table usually shows no time of day: do not invent one.")
  else paste(
    "SOURCE: the IG mobile app (a phone screenshot), spread bet or CFD, possibly a DEMO account (a 'Spread bet' and 'DEMO' badge may appear in the header).",
    "Typical screens: (1) Position Detail of an OPEN trade: Open, Current, Size with a sign (for example +3 or -3), Stop, Limit and an unrealised P&L; the chart may show a pill such as '-£16.20 | +3 / pt';",
    "(2) New trade ticket: Sell/Buy quotes, Size, Currency, Stop Loss Type, Stop Distance and Limit Distance in points, costs and Margin; it has no fill price because the trade is not placed yet;",
    "(3) Market Detail: Change, High, Low, an Updated clock and live Sell/Buy quotes: a price snapshot, not a trade;",
    "(4) Trades > Closed list: market name, P&L, a signed size, 'Opening: dd/mm/yyyy @price', 'Closing: dd/mm/yyyy @price' and a Ref, usually with no time of day.",
    "The dates and times on the chart axis are not trade times: never use them as an opening or closing time.")
}

tr_vision_prompt <- function(kind = "auto", source = "mobile") {
  keys <- paste(
    "Return ONE JSON object with these keys (use null when a value is not visible):",
    '{"screen_type": "position_detail"|"new_trade_ticket"|"deal_ticket"|"positions_table"|"orders_table"|"market_detail"|"closed_trades"|"activity"|"history"|"chart"|"other",',
    '"activity_text": string|null (Activity screen only: the activity words of the row, for example "Position opened"),',
    '"platform": string|null, "account_mode_text": string|null (the account badge exactly as shown, for example "Spread bet DEMO"),',
    '"deal_reference": string|null, "asset": string|null (the market name exactly as shown, including any suffix such as DFB or a contract month),',
    '"contract_type_text": string|null (the contract toggle or label exactly as shown, for example "Undated", "Futures", "DFB" or a month such as "Dec-26"),',
    '"direction": "BUY"|"SELL"|null (ONLY if the words Buy, Sell, Long or Short are shown for this trade),',
    '"size": number|null, "size_text": string|null (exactly as shown, including any + or - sign), "size_unit": string|null (for example "per point" when the screen shows "/ pt" or "per point"; or "lots", "contracts"),',
    '"min_size": number|null (the minimum deal size the ticket shows, for example "Min 1" or "Minimum size 1"),',
    '"order_type": string|null, "open_date_text": string|null, "close_date_text": string|null, "date_text": string|null, "time_text": string|null (a clock labelled as the trade time),',
    '"quote_time_text": string|null (the "Updated" or "U:" clock on a market or ticket screen), "timezone_text": string|null,',
    '"entry_price": number|null (the price the position OPENED at, labelled Open, Opening or Open level), "exit_price": number|null (the price it CLOSED at, labelled Closing or Close level),',
    '"current_price": number|null (labelled Current or Latest), "stop_price": number|null (a price LEVEL), "limit_price": number|null (a price LEVEL),',
    '"stop_distance": number|null, "limit_distance": number|null (distances in points, labelled Stop Distance, Limit Distance or pts away),',
    '"sell_price": number|null, "buy_price": number|null (the live Sell and Buy quotes shown on the screen),',
    '"margin": number|null (the Margin amount), "notional": number|null (Notional or exposure value), "costs": number|null (Indicative opening costs or the cost figure shown),',
    '"risk_amount": number|null (the money amount shown for the stop, as a positive number), "reward_amount": number|null (the money amount shown for the limit),',
    '"risk_reward_text": string|null (the platform\'s own ratio label exactly as shown, for example "1.5:1"), "resulting_position": number|null (signed, as shown),',
    '"pnl": number|null (the realised profit or loss of one CLOSED trade row), "unrealised_pnl": number|null (the profit or loss shown for a position that is still OPEN), "currency": string|null,',
    '"confidence": {"<key>": "high"|"medium"|"low"} for each key you filled, "not_visible": [keys you could not read], "notes": string|null (only about legibility)}.')
  rules <- paste(
    "Rules: copy values exactly as shown; do not calculate, convert, round or infer anything.",
    "Never put a live Sell/Buy quote into entry_price: quotes go in sell_price and buy_price.",
    "Never put the P&L of an open position into pnl: it goes in unrealised_pnl. Never use a list total (for example 'Total P&L') as the pnl of a row.",
    "If a Stop or Limit shows both a distance and a level, fill both the distance key and the price key. If it shows only a distance, leave the price key null.",
    "If direction is shown only as a signed size such as +3 or -3, copy that into size_text and leave direction null.",
    "Copy the platform's risk/reward ratio label into risk_reward_text exactly as shown: do not turn it into any other ratio.",
    "Money amounts (margin, notional, costs, risk_amount, reward_amount, pnl) are numbers without currency symbols or thousands separators.",
    "Dates: copy as shown (for example 15/10/2026) into open_date_text and close_date_text; do not invent a time when none is shown.",
    paste0("Today's date in London is ", format(tr_london_today(), "%d/%m/%Y"), ". Use it only to resolve words such as Today or Yesterday that are printed on the screen; if no date is shown, leave the date keys null."),
    "Read EVERY value that is visible: every column of a table row, including the profit/loss column and any total shown for the row. A value that fits no key goes in notes, with its label.")
  lead <- switch(kind,
    auto   = "First decide which screen this is and put it in screen_type, then transcribe everything that is visible.",
    open   = "This screenshot shows an open position or a deal confirmation. Transcribe the entry details (screen_type is normally position_detail or positions_table).",
    ticket = "This screenshot shows an order or deal ticket before the trade is placed. Transcribe the planned size, stop and limit, the quotes, margin, notional and costs (screen_type is normally new_trade_ticket or deal_ticket).",
    close  = "This screenshot shows a closed position, a closed-trades list or a deal confirmation. Transcribe the exit details, and the entry details if shown.",
    market = "This screenshot shows a market price screen. Transcribe the quotes and the labelled values only (screen_type is normally market_detail or chart).",
    "This screenshot shows an account history or statement. Transcribe the single most prominent deal row only.")
  paste(lead, tr_vision_source_notes(source), keys, rules)
}

# Which form the screen belongs to, from the screen type Claude read.
tr_screen_to_kind <- function(screen_type, activity_text = NULL) {
  s <- tolower(trimws(as.character(screen_type)))
  if (!length(s) || is.na(s)) return("history")
  if (identical(s, "activity")) { a <- tolower(paste(unlist(activity_text), collapse = " "))
    return(if (grepl("open", a)) "open" else if (grepl("clos", a)) "close" else "history") }
  switch(s, position_detail = "open", positions_table = "open", new_trade_ticket = "ticket", order_ticket = "ticket", deal_ticket = "ticket",
         market_detail = "market", chart = "market", closed_trades = "close", history = "history", orders_table = "history", "history")
}

# Request body for the Messages API with one or more images (base64) and a text instruction.
tr_build_vision_body <- function(model, system, text, images, max_tokens = 1500) {
  content <- lapply(images, function(im) list(type = "image",
    source = list(type = "base64", media_type = im$media_type, data = gsub("[[:space:]]", "", im$data))))
  content[[length(content) + 1]] <- list(type = "text", text = text)
  list(model = model, max_tokens = max_tokens, temperature = 0, system = system,
       messages = list(list(role = "user", content = content)))
}

tr_media_type <- function(path_or_name) {
  ext <- tolower(tools::file_ext(path_or_name))
  switch(ext, png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg", webp = "image/webp", gif = "image/gif", NA_character_)
}

# Read an image file -> list(media_type, data (base64), bytes, md5). Errors with a clear message.
tr_read_image <- function(path, name = basename(path), max_bytes = 5 * 1024 * 1024) {
  mt <- tr_media_type(name)
  if (is.na(mt)) stop("Unsupported image type. Use PNG, JPEG, WebP or GIF.")
  n0 <- file.info(path)$size
  if (is.na(n0) || n0 == 0) stop("The file is empty.")
  md5 <- unname(tools::md5sum(path))   # of the original file, so the same screenshot is recognised again
  send <- if (exists("tr_downscale_image", mode = "function")) tr_downscale_image(path) else path   # big phone screenshots are shrunk first (magick)
  n <- file.info(send)$size
  if (n > max_bytes) stop(sprintf("The image is %.1f MB; the limit is about 5 MB. Crop it or save it at a smaller size.", n / 1024^2))
  raw <- readBin(send, "raw", n)
  list(media_type = mt, data = gsub("[[:space:]]", "", jsonlite::base64_enc(raw)), bytes = n0, md5 = md5, name = name)
}

# Pull the JSON object out of a model reply (tolerates code fences / stray text).
tr_parse_vision_json <- function(txt) {
  if (is.null(txt) || !nzchar(txt)) return(NULL)
  a <- regexpr("\\{", txt); b <- max(gregexpr("\\}", txt)[[1]])
  if (a < 0 || b < a) return(NULL)
  tryCatch(jsonlite::fromJSON(substr(txt, a, b), simplifyVector = FALSE), error = function(e) NULL)
}

tr_parse_num <- function(x) {
  x <- as.character(x); neg <- grepl("^\\s*\\(.*\\)\\s*$", x)
  x <- gsub("[^0-9.,+-]", "", gsub("\\(|\\)", "", x))
  x <- ifelse(grepl(",", x) & grepl("\\.", x), gsub(",", "", x), ifelse(grepl(",", x) & !grepl("\\.", x) & grepl(",[0-9]{1,2}$", x), sub(",", ".", x), gsub(",", "", x)))
  v <- suppressWarnings(as.numeric(x)); ifelse(neg & is.finite(v), -abs(v), v)
}

tr_norm_dir <- function(x) {
  x <- toupper(trimws(as.character(x)))
  ifelse(grepl("^(B|BUY|LONG)", x), "B", ifelse(grepl("^(S|SELL|SHORT)", x), "S", NA_character_))
}

# ---- Instrument catalogue ------------------------------------------------------------------
# One list drives the asset pickers, the Morning Sheet, the pip defaults and the asset class / market
# saved with every trade and screenshot. It is flexible: any name not listed is kept as typed (the
# class and market can then be chosen by hand). Matching is done on the name with everything except
# letters and digits removed, FIRST MATCH WINS (so Brent and UK gas come before WTI and US gas).
# std_pip is the conventional pip for a normal decimal quote (e.g. EUR/USD 1.1643 -> 0.0001). On IG
# spread-bet screens prices are shown in points and one point is one pip, so the pip size is 1.
tr_catalogue <- data.frame(stringsAsFactors = FALSE,
  code = c("BRENT", "WTI", "NATGAS_UK", "NATGAS", "HEATOIL", "GASOLINE",
           "GOLD", "SILVER", "COPPER", "PLATINUM",
           "COCOA", "COFFEE", "SUGAR", "WHEAT", "CORN", "SOYBEANS",
           "EURUSD", "USDJPY", "GBPUSD", "AUDUSD", "USDCAD", "USDCHF", "NZDUSD", "EURGBP", "EURJPY", "GBPJPY",
           "DOW", "SP500", "NASDAQ", "FTSE100", "GER40", "JP225"),
  label = c("Brent Crude", "WTI Crude (US Crude)", "Natural Gas (UK)", "Natural Gas (US, Henry Hub)", "Heating Oil", "Gasoline",
            "Gold", "Silver", "Copper", "Platinum",
            "Cocoa", "Coffee", "Sugar", "Wheat", "Corn", "Soybeans",
            "EUR/USD", "USD/JPY", "GBP/USD", "AUD/USD", "USD/CAD", "USD/CHF", "NZD/USD", "EUR/GBP", "EUR/JPY", "GBP/JPY",
            "Wall Street (Dow Jones)", "US 500 (S&P 500)", "US Tech 100 (Nasdaq)", "FTSE 100", "Germany 40 (DAX)", "Japan 225 (Nikkei)"),
  asset_class = c(rep("Commodity", 16), rep("Forex", 10), rep("Equity index", 6)),
  market = c(rep("Energy", 6), rep("Precious metals", 2), "Industrial metals", "Precious metals",
             rep("Agricultural (softs and grains)", 6), rep("FX majors", 7), rep("FX crosses", 3),
             "US indices", "US indices", "US indices", "UK indices", "European indices", "Asian indices"),
  std_pip = c(0.01, 0.01, 0.01, 0.001, 0.0001, 0.0001, 0.1, 0.01, 0.0005, 0.1,
              1, 1, 0.01, 0.25, 0.25, 0.25,
              0.0001, 0.01, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.01, 0.01,
              1, 0.1, 1, 1, 1, 1),
  pattern = c("BRENT", "WTI|USCRUDE|CRUDEOIL|^OIL|LIGHTSWEET|^CL$|^CLF", "(NATURALGAS|NATGAS).*(UK|NBP)|UK(NATURALGAS|NATGAS)|^NBP",
              "NATURALGAS|NATGAS|HENRYHUB|^NG$|^NGF", "HEATINGOIL|HEATOIL", "GASOLINE|RBOB|UNLEADED",
              "^GOLD|SPOTGOLD|XAUUSD", "^SILVER|SPOTSILVER|XAGUSD", "COPPER", "PLATINUM",
              "COCOA", "COFFEE", "SUGAR", "WHEAT", "^CORN", "SOYBEAN",
              "^EUR.?USD", "^USD.?JPY", "^GBP.?USD", "^AUD.?USD", "^USD.?CAD", "^USD.?CHF", "^NZD.?USD", "^EUR.?GBP", "^EUR.?JPY", "^GBP.?JPY",
              "WALLSTREET|^DOW|^US30", "US500|SP500|^SANDP", "USTECH100|NASDAQ|^US100", "FTSE100", "GERMANY40|^DAX|^GER40", "JAPAN225|NIKKEI|^JP225"))
tr_assets <- tr_catalogue$code
tr_pip_defaults <- setNames(tr_catalogue$std_pip, tr_catalogue$code)

tr_instrument <- function(code) {
  code <- toupper(trimws(as.character(code))); if (!length(code) || is.na(code[1])) return(NULL)
  r <- tr_catalogue[tr_catalogue$code == code[1], , drop = FALSE]; if (nrow(r)) as.list(r[1, ]) else NULL
}
tr_asset_class <- function(code) { i <- tr_instrument(code); if (is.null(i)) NA_character_ else i$asset_class }
tr_market_of <- function(code) { i <- tr_instrument(code); if (is.null(i)) NA_character_ else i$market }
tr_asset_label <- function(code) { i <- tr_instrument(code); if (is.null(i)) as.character(code) else i$label }
tr_asset_classes <- c("Commodity", "Forex", "Equity index", "Other")
# Grouped choices for selectize: group = asset class - market, label shown, code returned.
tr_asset_choices <- function(extra = character(0)) {
  g <- paste(tr_catalogue$asset_class, tr_catalogue$market, sep = " - ")
  out <- lapply(unique(g), function(k) { r <- tr_catalogue[g == k, ]; setNames(r$code, r$label) })
  names(out) <- unique(g)
  extra <- setdiff(toupper(extra[!is.na(extra) & nzchar(extra)]), tr_catalogue$code)
  if (length(extra)) out <- c(list(Other = setNames(extra, extra)), out)
  out
}
# Price basis: "ig" = IG spread-bet points (1 point = 1 pip); "standard" = conventional decimal quote.
tr_price_bases <- c("IG spread bet points (1 point = 1 pip)" = "ig", "Conventional decimal quote (pip as per instrument)" = "standard")
tr_pip_for <- function(code, basis = "ig") {
  if (identical(basis, "ig")) return(1)
  p <- unname(tr_pip_defaults[toupper(trimws(as.character(code)))]); if (length(p) && is.finite(p)) p else NA_real_
}

# Instrument names on platforms vary ("Oil - US Crude", "Natural Gas - UK", "EUR/USD") -> app asset codes.
tr_norm_asset <- function(x) {
  x <- as.character(x); u <- toupper(gsub("[^A-Za-z0-9&]", "", x)); u <- gsub("&", "AND", u)
  out <- u
  for (i in seq_len(nrow(tr_catalogue))) {
    hit <- grepl(tr_catalogue$pattern[i], u) & out == u & !(u %in% tr_catalogue$code[seq_len(i - 1)])
    out[hit] <- tr_catalogue$code[i]
  }
  # a code typed as-is (WTI, GER40...) stays; everything is matched on the first rule that fits
  out[is.na(x) | !nzchar(u)] <- NA_character_
  out
}
# Contract type from the toggle text or the market name: DFB (daily funded bet, 'Undated') or FUTURES.
tr_contract_type <- function(...) {
  t <- toupper(paste(unlist(list(...)), collapse = " "))
  if (!nzchar(trimws(t)) || is.na(t)) return(NA_character_)
  if (grepl("UNDATED|DFB|DAILY FUNDED|DAILYFUNDED", t)) return("DFB")
  if (grepl("FUTURE|EXPIR|\\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[ -]?[0-9]{2}\\b", t)) return("FUTURES")
  NA_character_
}
tr_account_type <- function(mode_text) {
  t <- toupper(as.character(mode_text)); if (!length(t) || is.na(t)) return(NA_character_)
  if (grepl("SPREAD", t)) "SPREAD_BET" else if (grepl("CFD", t)) "CFD" else NA_character_
}

# Normalise a parsed extraction into app-ready fields (numbers, B/S, asset code, date + HH:MM).
# `kind` (open / ticket / close / market / history) decides which date is used when a screen shows two.
tr_normalise_extraction <- function(x, kind = NULL) {
  g <- function(k) { v <- x[[k]]; if (is.null(v) || length(v) == 0 || is.na(v)) NA else v }
  fmts <- c("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y", "%d %b %Y", "%d %B %Y", "%d/%m/%y", "%d-%b-%y", "%b %d, %Y")
  pdate <- function(dt) { dt <- as.character(dt); if (is.na(dt)) return(as.Date(NA))
    for (f in fmts) { p <- suppressWarnings(as.Date(dt, format = f)); if (!is.na(p)) return(p) }; as.Date(NA) }
  phm <- function(tt) { tt <- as.character(tt); if (is.na(tt)) return(NA_character_)
    m <- regmatches(tt, regexec("([0-2]?[0-9])[:.]([0-5][0-9])", tt))[[1]]; if (length(m) == 3) sprintf("%02d:%s", as.integer(m[2]), m[3]) else NA_character_ }
  d_gen <- pdate(g("date_text")); d_open <- pdate(g("open_date_text")); d_close <- pdate(g("close_date_text"))
  first_date <- function(...) { for (v in list(...)) if (!is.na(v)) return(v); as.Date(NA) }
  first_clock <- function(...) { for (v in list(...)) if (!is.na(v)) return(v); NA_character_ }
  d <- switch(tr_or(kind, "other"), close = first_date(d_close, d_gen, d_open), open = first_date(d_open, d_gen),
              first_date(d_gen, d_open, d_close))
  clock_in <- function(k) { v <- as.character(g(k)); if (is.na(v)) return(NA_character_); m <- regmatches(v, regexec("([0-2]?[0-9]):([0-5][0-9])", v))[[1]]; if (length(m) == 3) sprintf("%02d:%s", as.integer(m[2]), m[3]) else NA_character_ }
  tm <- phm(g("time_text")); qt <- phm(g("quote_time_text"))
  if (is.na(tm)) tm <- switch(tr_or(kind, "other"), close = first_clock(clock_in("close_date_text"), clock_in("date_text"), clock_in("open_date_text")), open = first_clock(clock_in("open_date_text"), clock_in("date_text")),
                              first_clock(clock_in("date_text"), clock_in("open_date_text"), clock_in("close_date_text")))
  # size: the number is always positive; a leading + / - on the text decides the side when no word is shown
  size_txt <- as.character(g("size_text")); szn <- tr_parse_num(g("size")); sg <- NA_real_
  if (!is.na(size_txt)) { sg <- if (grepl("^\\s*\\+", size_txt)) 1 else if (grepl("^\\s*[-−–]", size_txt)) -1 else NA_real_
    if (!is.finite(szn)) szn <- tr_parse_num(gsub("[−–]", "-", size_txt)) }
  if (is.na(sg) && is.finite(szn) && szn < 0 && !is.na(size_txt)) sg <- -1
  size <- if (is.finite(szn)) abs(szn) else NA_real_
  dir <- tr_norm_dir(g("direction")); derived <- character(0)
  if (is.na(dir) && !is.na(sg)) { dir <- if (sg > 0) "B" else "S"; derived <- c(derived, "direction (taken from the sign of the size: + is a buy, - is a sell)") }
  mode_txt <- as.character(g("account_mode_text")); unit <- as.character(g("size_unit"))
  per_point <- isTRUE(grepl("spread", mode_txt, ignore.case = TRUE)) || isTRUE(grepl("point|/ ?pt|pts", unit, ignore.case = TRUE))
  asset_code <- tr_norm_asset(g("asset"))
  sellp <- tr_parse_num(g("sell_price")); buyp <- tr_parse_num(g("buy_price"))
  list(platform = as.character(g("platform")), deal_ref = as.character(g("deal_reference")),
       asset_raw = as.character(g("asset")), asset = asset_code, asset_class = tr_asset_class(asset_code), market = tr_market_of(asset_code),
       contract = tr_contract_type(g("contract_type_text"), g("asset")), contract_text = as.character(g("contract_type_text")),
       account_type = tr_account_type(mode_txt),
       margin = tr_parse_num(g("margin")), notional = tr_parse_num(g("notional")), costs = tr_parse_num(g("costs")),
       risk_amount = abs(tr_parse_num(g("risk_amount"))), reward_amount = abs(tr_parse_num(g("reward_amount"))),
       rr_text = as.character(g("risk_reward_text")), resulting_position = tr_parse_num(g("resulting_position")),
       spread = if (is.finite(sellp) && is.finite(buyp)) buyp - sellp else NA_real_,
       direction = dir,
       size = size, min_size = tr_parse_num(g("min_size")), size_unit = unit, order_type = as.character(g("order_type")),
       date = d, time = tm, entry = tr_parse_num(g("entry_price")), stop = tr_parse_num(g("stop_price")),
       limit = tr_parse_num(g("limit_price")), exit = tr_parse_num(g("exit_price")), pnl = tr_parse_num(g("pnl")),
       currency = as.character(g("currency")),
       screen_type = as.character(g("screen_type")), account_mode = mode_txt,
       demo = if (is.na(mode_txt)) NA else grepl("demo", mode_txt, ignore.case = TRUE), per_point = per_point,
       stop_dist = tr_parse_num(g("stop_distance")), limit_dist = tr_parse_num(g("limit_distance")),
       sell = tr_parse_num(g("sell_price")), buy = tr_parse_num(g("buy_price")), current = tr_parse_num(g("current_price")),
       unrealised = tr_parse_num(g("unrealised_pnl")), quote_time = qt, open_date = d_open, close_date = d_close,
       derived = derived,
       confidence = if (is.list(x$confidence)) unlist(x$confidence) else character(0),
       not_visible = unlist(x$not_visible), notes = as.character(g("notes")))
}

# Deterministic checks on an extraction. Returns data.frame(level, message).
tr_check_extraction <- function(e, kind = "open", levels = NULL) {
  out <- list(); add <- function(l, m) out[[length(out) + 1]] <<- data.frame(level = l, message = m, stringsAsFactors = FALSE)
  nv <- function(k) { v <- e[[k]]; if (is.null(v) || !length(v)) NA_real_ else suppressWarnings(as.numeric(v[1])) }
  rec_only <- kind %in% c("ticket", "market")
  pp <- isTRUE(e$per_point)
  fm <- function(v) format(round(v, 2), nsmall = 2, trim = TRUE)
  if (is.na(e$asset)) add(if (rec_only) "warn" else "error", "Instrument not recognised or not visible.")
  if (is.na(e$direction) && !rec_only) add(if (kind == "open") "error" else "warn", "Direction (buy/sell) not recognised or not visible.")
  if (kind %in% c("open", "close") && isTRUE(e$date_assumed)) add("info", "No date is shown on the screen, so today's date in London was filled in. Change it if the trade happened on another day.")
  else if (kind %in% c("open", "close") && is.na(e$date)) add("warn", "Date not read; enter it yourself.")
  if (kind %in% c("open", "close") && is.na(e$time)) add("warn", "Time of day not shown or not read. Some screens (for example the mobile Closed list) show dates only: enter the time yourself (UK time) from your notes or the trade's detail screen.")
  for (dm in e$derived) add("info", paste("Taken from the screen by a rule, not read as a word:", dm))
  if (isFALSE(e$demo)) add("warn", "The account badge does not say DEMO. Check you are using your demo account.")
  if (kind == "open") {
    if (!is.finite(e$entry)) add("error", "Entry price not read.")
    if (!is.finite(e$stop)) add("warn", if (is.finite(nv("stop_dist"))) "The stop is shown as a distance, not a level. Use the open-position screen for the stop level, or enter it yourself." else "No stop visible. Your plan needs a stop on every trade.")
    if (is.finite(e$entry) && is.finite(e$stop) && !is.na(e$direction)) {
      d <- tr_dir(e$direction); if ((e$entry - e$stop) * d <= 0) add("error", "Stop is on the wrong side of the entry for this direction. Re-check the image.")
    }
    if (is.finite(e$entry) && is.finite(e$limit) && !is.na(e$direction)) {
      d <- tr_dir(e$direction); if ((e$limit - e$entry) * d <= 0) add("error", "Limit/target is on the wrong side of the entry for this direction. Re-check the image.")
    }
    if (is.finite(e$entry) && is.finite(e$stop)) {
      rp <- abs(e$entry - e$stop); sz <- nv("size")
      txt <- sprintf("Stop is %s points from the entry", fm(rp))
      if (is.finite(e$limit)) { wp <- abs(e$limit - e$entry); txt <- sprintf("%s and the limit %s points (reward:risk %s : 1)", txt, fm(wp), fm(wp / rp)) }
      if (pp && is.finite(sz)) txt <- sprintf("%s. Risk if the stop is hit: %s points x £%s per point = £%s.", txt, fm(rp), format(sz), fm(rp * sz))
      else txt <- paste0(txt, ". Size unit not confirmed as per point, so no money amount is calculated.")
      add("info", txt)
    }
    cu <- nv("current"); un <- nv("unrealised"); szo <- nv("size")
    if (pp && all(is.finite(c(e$entry, cu, un, szo))) && !is.na(e$direction)) {
      calc <- (cu - e$entry) * tr_dir(e$direction) * szo
      if (abs(calc - un) <= 0.06) add("info", sprintf("Unrealised profit/loss agrees with the prices: %s points x £%s per point = £%s.", fm((cu - e$entry) * tr_dir(e$direction)), format(szo), fm(calc)))
      else add("warn", sprintf("Unrealised profit/loss %s does not equal points x size (%s). Re-check the latest price, opening price, size and direction against the image.", fm(un), fm(calc)))
    }
  }
  if (!is.null(e$rr_text) && !is.na(e$rr_text) && nzchar(e$rr_text))
    add("info", sprintf("The platform shows its own ratio '%s'. IG states risk:reward (risk divided by reward), the opposite of LAT's RRR (reward divided by risk). The app works out the LAT RRR itself from your stop and target and never saves the platform's figure.", e$rr_text))
  if (!is.null(e$contract) && !is.na(e$contract) && identical(e$contract, "FUTURES")) add("info", "Contract type is Futures (a dated contract): it has an expiry and a different price from the daily funded bet (DFB / Undated). Keep to one type for the whole period.")
  if (kind == "ticket") {
    add("info", "A ticket shows indicative quotes, not your fill price. Take the entry level from the open-position screen after the trade is placed.")
    sd <- nv("stop_dist"); ld <- nv("limit_dist"); sz <- nv("size")
    if (is.finite(sd) && is.finite(sz) && is.finite(nv("risk_amount")) && abs(sd * sz - nv("risk_amount")) > 0.05)
      add("warn", sprintf("The ticket's money risk (%s) does not equal stop points x size (%s). Re-check the stop distance, size and amount against the image.", fm(nv("risk_amount")), fm(sd * sz)))
    if (is.finite(ld) && is.finite(sz) && is.finite(nv("reward_amount")) && abs(ld * sz - nv("reward_amount")) > 0.05)
      add("warn", sprintf("The ticket's money reward (%s) does not equal limit points x size (%s). Re-check the limit distance, size and amount against the image.", fm(nv("reward_amount")), fm(ld * sz)))
    if (!is.finite(sd) && !is.finite(e$stop)) add("warn", "No stop distance visible on the ticket.")
    if (is.finite(sd)) {
      txt <- sprintf("Planned stop %s points", fm(sd))
      if (is.finite(ld)) txt <- sprintf("%s, planned limit %s points (reward:risk %s : 1)", txt, fm(ld), fm(ld / sd))
      if (pp && is.finite(sz)) txt <- sprintf("%s. Risk if the stop is hit: %s points x £%s per point = £%s.", txt, fm(sd), format(sz), fm(sd * sz))
      add("info", txt)
    }
  }
  if (rec_only && is.finite(nv("sell")) && is.finite(nv("buy"))) add("info", sprintf("Quotes shown: sell %s, buy %s (spread %s points).", format(nv("sell")), format(nv("buy")), fm(nv("buy") - nv("sell"))))
  if (kind == "market") add("info", "A market screen is a price snapshot. Save it as evidence only; it does not fill a trade form.")
  if (kind == "close") {
    if (!is.finite(e$exit)) add("error", "Exit price not read.")
    sz <- nv("size"); pn <- nv("pnl")
    if (pp && all(is.finite(c(e$entry, e$exit, sz, pn))) && !is.na(e$direction)) {
      calc <- (e$exit - e$entry) * tr_dir(e$direction) * sz
      if (abs(calc - pn) <= 0.05) add("info", sprintf("Profit/loss agrees with the prices: %s points x £%s per point = £%s.", fm((e$exit - e$entry) * tr_dir(e$direction)), format(sz), fm(calc)))
      else add("warn", sprintf("Profit/loss %s does not equal points x size (%s). Re-check the prices, size and direction against the image, or the bet may use a different unit or currency.", fm(pn), fm(calc)))
    }
  }
  low <- e$confidence[e$confidence == "low"]
  if (length(low)) add("warn", paste("Low confidence:", paste(names(low), collapse = ", "), "- verify against the image."))
  if (!is.null(levels) && nrow(levels) && !is.na(e$asset)) {
    lv <- levels[levels$instrument == e$asset, ]
    px <- if (kind == "close") e$exit else e$entry
    if (nrow(lv) && is.finite(px)) {
      lo <- suppressWarnings(min(lv$overnight_low, na.rm = TRUE)); hi <- suppressWarnings(max(lv$overnight_high, na.rm = TRUE))
      if (is.finite(lo) && is.finite(hi) && (px < lo - 0.1 * (hi - lo) - 1e-12 || px > hi + 0.1 * (hi - lo) + 1e-12))
        add("info", sprintf("Price %s is outside the overnight range on your morning sheet (%s to %s). That can be normal; check you read it correctly.", px, lo, hi))
    }
  }
  if (!any(vapply(out, function(z) z$level %in% c("error", "warn"), TRUE))) out <- c(list(data.frame(level = "ok", message = "No errors or warnings from the automatic checks. Still compare every value with the image.", stringsAsFactors = FALSE)), out)
  do.call(rbind, out)
}


# ---- Morning Sheet: levels read from IG screenshots ----------------------------------------
tr_morning_vision_prompt <- function() paste(
  "You are transcribing screenshots of the IG trading platform (website or mobile app) used for a morning market check: a watchlist, a market page, or a price chart (with an OHLC box when the crosshair is on a candle).",
  "Return ONE JSON object: {\"markets\": [ ... ], \"notes\": string|null (only about legibility)}. Make one entry in markets for every market whose price is visible (a watchlist shows several).",
  "Each entry has these keys (null when not visible):",
  '{"name": string (the market name exactly as shown), "sell_price": number|null, "buy_price": number|null,',
  '"last_price": number|null (a single current, last or mid price when that is the only price shown, for example the price tag on a chart or the Close in an OHLC box of the latest candle),',
  '"day_low": number|null (labelled L, Low, Lowest or Day low), "day_high": number|null (labelled H, High, Highest or Day high),',
  '"range_basis": "day"|"candle"|null ("day" when the high and low are the market\'s range for the day or session, as in a header such as H 10820.4 L 10517.9; "candle" when they come from the OHLC box of one candle),',
  '"change_pts": number|null (signed), "change_pct": number|null (signed, without the % sign),',
  '"time_text": string|null (a clock shown with the price, for example Updated 07:02, or the time of the candle), "period_text": string|null (the chart timeframe, for example Daily or 1 Hour)}.',
  "Rules: copy values exactly as shown; do not calculate, convert, round or infer anything. Numbers have no thousands separators or currency symbols.",
  "Do not use a price from the chart axis labels. If the same market appears twice, use the more complete entry.")

# Turn the parsed reply into sheet values. Dow and Nikkei go to the overnight table; everything else to instrument rows.
tr_morning_assign <- function(parsed) {
  m <- parsed$markets; if (is.null(m) || !length(m)) return(data.frame())
  if (!is.null(names(m))) m <- list(m)   # a single object instead of a list
  rows <- lapply(m, function(x) {
    nz <- function(k) { v <- x[[k]]; if (is.null(v) || !length(v) || is.na(v)) NA_real_ else tr_parse_num(v) }
    sell <- nz("sell_price"); buy <- nz("buy_price"); last <- nz("last_price")
    cur <- if (is.finite(last)) last else if (is.finite(sell) && is.finite(buy)) round((sell + buy) / 2, 4) else if (is.finite(sell)) sell else buy
    tm <- { t <- x[["time_text"]]; if (is.null(t) || is.na(t)) NA_character_ else { mm <- regmatches(t, regexec("([0-2]?[0-9]):([0-5][0-9])", t))[[1]]; if (length(mm) == 3) sprintf("%02d:%s", as.integer(mm[2]), mm[3]) else NA_character_ } }
    nm <- as.character(tr_or(x[["name"]], NA))
    data.frame(code = tr_norm_asset(nm), name = nm, low = nz("day_low"), high = nz("day_high"), cur = cur, chg_pct = nz("change_pct"), chg_pts = nz("change_pts"),
               time = tm, basis = as.character(tr_or(x[["range_basis"]], NA)), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows); out <- out[!is.na(out$name) & nzchar(out$name), , drop = FALSE]
  out[!duplicated(out$code, fromLast = TRUE), , drop = FALSE]   # a later screenshot replaces an earlier one for the same market
}
