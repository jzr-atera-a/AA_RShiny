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

  plan_spec = list(table = "trading_plan_spec", key = "spec_id",
    cols = c(spec_id = "STRING", spec_version = "INT64", saved_at = "TIMESTAMP", effective_date = "DATE",
             strategy = "STRING", entry_rule = "STRING", stop_rule = "STRING", target_rule = "STRING",
             management_rule = "STRING", adx_trend_min = "FLOAT64", adx_range_max = "FLOAT64",
             risk_pct = "FLOAT64", combined_cap_pct = "FLOAT64", correlated_rule = "STRING",
             max_open_positions = "INT64", daily_loss_limit_pct = "FLOAT64", weekly_loss_limit_pct = "FLOAT64",
             change_reason = "STRING",
             setup_rule = "STRING", trigger_rule = "STRING", execution_rule = "STRING", monthly_loss_limit_pct = "FLOAT64",
             min_rrr = "FLOAT64", tf_minor = "STRING", tf_base = "STRING", tf_major = "STRING", data_sources = "STRING",
             objectives = "STRING", indicators = "STRING"),
    added = c("setup_rule", "trigger_rule", "execution_rule", "monthly_loss_limit_pct", "min_rrr", "tf_minor", "tf_base",
              "tf_major", "data_sources", "objectives", "indicators")),

  morning_sheets = list(table = "trading_morning_sheets", key = "sheet_id",
    cols = c(sheet_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", sheet_date = "DATE",
             week_no = "INT64", dow_price = "FLOAT64", dow_change_pct = "FLOAT64", nikkei_price = "FLOAT64",
             nikkei_change_pct = "FLOAT64", overnight_news = "STRING", overnight_calendar = "STRING",
             todays_releases = "STRING", releases_in_window = "STRING", regime_summary = "STRING",
             planned_setups = "STRING", exposure_note = "STRING", combined_open_risk_pct = "FLOAT64",
             stand_aside = "BOOL", stand_aside_reason = "STRING")),

  morning_levels = list(table = "trading_morning_levels", key = "level_id",
    cols = c(level_id = "STRING", sheet_id = "STRING", saved_at = "TIMESTAMP", sheet_date = "DATE",
             instrument = "STRING", overnight_low = "FLOAT64", overnight_high = "FLOAT64",
             current_price = "FLOAT64", time_now_uk = "STRING", adx14 = "FLOAT64", regime_label = "STRING",
             prior_high = "FLOAT64", prior_low = "FLOAT64", prior_close = "FLOAT64",
             pivot_pp = "FLOAT64", pivot_r1 = "FLOAT64", pivot_s1 = "FLOAT64",
             pivot_r2 = "FLOAT64", pivot_s2 = "FLOAT64", pivot_r3 = "FLOAT64", pivot_s3 = "FLOAT64"),
    added = c("pivot_r2", "pivot_s2", "pivot_r3", "pivot_s3")),

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
             execution_text = "STRING", stop_reason = "STRING", target_reason = "STRING", spec_version = "INT64",
             plan_followed = "BOOL", deviation_type = "STRING", deviation_note = "STRING",
             exit_ts = "TIMESTAMP", exit_price = "FLOAT64", exit_code = "STRING", pips_result = "FLOAT64",
             net_pnl_gbp = "FLOAT64", pnl_source = "STRING", real_r = "FLOAT64", duration_hours = "FLOAT64",
             mood_exit = "INT64", reason_for_exit = "STRING", lessons_learned = "STRING",
             trade_sheet_name = "STRING", notes = "STRING",
             entry_source = "STRING", evidence_ids = "STRING", verified_by_user = "BOOL", statement_fill_id = "STRING"),
    added = c("entry_source", "evidence_ids", "verified_by_user", "statement_fill_id")),

  trade_events = list(table = "trading_trade_events", key = "event_id",
    cols = c(event_id = "STRING", trade_id = "STRING", saved_at = "TIMESTAMP", event_ts = "TIMESTAMP",
             event_type = "STRING", old_stop = "FLOAT64", new_stop = "FLOAT64", size_closed_per_pip = "FLOAT64",
             price = "FLOAT64", reason = "STRING", permitted_by_spec = "BOOL")),

  evidence = list(table = "trading_evidence", key = "evidence_id",
    cols = c(evidence_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", kind = "STRING", status = "STRING",
             trade_id = "STRING", file_name = "STRING", file_md5 = "STRING", mime = "STRING", size_bytes = "INT64",
             dropbox_path = "STRING", model = "STRING", extracted_json = "STRING", confirmed_json = "STRING",
             checks_json = "STRING", input_tokens = "INT64", output_tokens = "INT64", user_notes = "STRING")),

  platform_fills = list(table = "trading_platform_fills", key = "fill_id",
    cols = c(fill_id = "STRING", saved_at = "TIMESTAMP", source_file = "STRING", platform = "STRING", deal_ref = "STRING",
             open_ts = "TIMESTAMP", close_ts = "TIMESTAMP", asset = "STRING", direction = "STRING", size = "FLOAT64",
             open_price = "FLOAT64", close_price = "FLOAT64", pnl_gbp = "FLOAT64", currency = "STRING", raw_json = "STRING")),

  reviews = list(table = "trading_reviews", key = "review_id",
    cols = c(review_id = "STRING", record_version = "INT64", saved_at = "TIMESTAMP", review_date = "DATE",
             review_type = "STRING", week_no = "INT64", trades_taken = "INT64", what_worked = "STRING",
             what_did_not = "STRING", deviations_summary = "STRING", changes_for_next_period = "STRING",
             change_effective_date = "DATE", loss_limit_breached = "BOOL", exposure_cap_breached = "BOOL",
             overall_mood = "INT64"))
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
  list(pips = pips, pnl_calc = calc, net = net, source = if (use_stmt) "STATEMENT" else "CALCULATED",
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

tr_vision_kinds <- c(
  "Order / deal ticket (entry)" = "open",
  "Closed position / deal confirmation (exit)" = "close",
  "Account history or statement screen" = "history")

tr_vision_prompt <- function(kind) {
  common <- paste(
    "Return JSON with these keys (use null when not visible):",
    '{"platform": string|null, "deal_reference": string|null, "asset": string|null (instrument name exactly as shown),',
    '"direction": "BUY"|"SELL"|null, "size": number|null, "size_unit": string|null (e.g. "per point", "lots", "contracts"),',
    '"order_type": string|null, "date_text": string|null (as shown), "time_text": string|null (as shown), "timezone_text": string|null,',
    '"entry_price": number|null, "stop_price": number|null, "limit_price": number|null,',
    '"exit_price": number|null, "pnl": number|null, "currency": string|null,',
    '"confidence": {"<key>": "high"|"medium"|"low"} for each key you filled, "not_visible": [keys you could not read], "notes": string|null (only about legibility)}.')
  switch(kind,
    open = paste("This screenshot shows an order or deal ticket for opening a position. Transcribe the entry details.", common),
    close = paste("This screenshot shows a closed position or deal confirmation. Transcribe the exit details, and the entry details if shown.", common),
    paste("This screenshot shows an account history or statement. Transcribe the single most prominent deal row only.", common))
}

# Request body for the Messages API with one or more images (base64) and a text instruction.
tr_build_vision_body <- function(model, system, text, images, max_tokens = 1500) {
  content <- lapply(images, function(im) list(type = "image",
    source = list(type = "base64", media_type = im$media_type, data = im$data)))
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
  n <- file.info(path)$size
  if (is.na(n) || n == 0) stop("The file is empty.")
  if (n > max_bytes) stop(sprintf("The image is %.1f MB; the limit is about 5 MB. Crop it or save it at a smaller size.", n / 1024^2))
  raw <- readBin(path, "raw", n)
  list(media_type = mt, data = jsonlite::base64_enc(raw), bytes = n, md5 = unname(tools::md5sum(path)), name = name)
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

# Instrument names on platforms vary ("US Crude", "Natural Gas", "EUR/USD") -> app asset codes.
tr_norm_asset <- function(x) {
  u <- toupper(gsub("[^A-Za-z0-9]", "", as.character(x)))
  out <- u
  out[grepl("WTI|USCRUDE|CRUDEOIL|^OIL|LIGHTSWEET|^CL$|^CLF", u) & !grepl("BRENT", u)] <- "WTI"
  out[grepl("NATURALGAS|NATGAS|HENRYHUB|^NG$|^NGF", u)] <- "NATGAS"
  out[grepl("^EUR.?USD", u)] <- "EURUSD"; out[grepl("^USD.?JPY", u)] <- "USDJPY"
  out[grepl("^GBP.?USD", u)] <- "GBPUSD"; out[grepl("^AUD.?USD", u)] <- "AUDUSD"
  out[grepl("^GOLD|XAUUSD", u)] <- "GOLD"; out[grepl("BRENT", u)] <- "BRENT"
  out[is.na(x) | !nzchar(u)] <- NA_character_
  out
}

# Normalise a parsed extraction into app-ready fields (numbers, B/S, asset code, date + HH:MM).
tr_normalise_extraction <- function(x) {
  g <- function(k) { v <- x[[k]]; if (is.null(v) || length(v) == 0 || is.na(v)) NA else v }
  d <- NA; tm <- NA_character_
  dt <- as.character(g("date_text")); tt <- as.character(g("time_text"))
  if (!is.na(dt)) for (f in c("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y", "%d %b %Y", "%d %B %Y", "%d/%m/%y", "%d-%b-%y", "%b %d, %Y")) {
    p <- suppressWarnings(as.Date(dt, format = f)); if (!is.na(p)) { d <- p; break } }
  if (!is.na(tt)) { m <- regmatches(tt, regexec("([0-2]?[0-9])[:.]([0-5][0-9])", tt))[[1]]; if (length(m) == 3) tm <- sprintf("%02d:%s", as.integer(m[2]), m[3]) }
  list(platform = as.character(g("platform")), deal_ref = as.character(g("deal_reference")),
       asset_raw = as.character(g("asset")), asset = tr_norm_asset(g("asset")), direction = tr_norm_dir(g("direction")),
       size = tr_parse_num(g("size")), size_unit = as.character(g("size_unit")), order_type = as.character(g("order_type")),
       date = d, time = tm, entry = tr_parse_num(g("entry_price")), stop = tr_parse_num(g("stop_price")),
       limit = tr_parse_num(g("limit_price")), exit = tr_parse_num(g("exit_price")), pnl = tr_parse_num(g("pnl")),
       currency = as.character(g("currency")),
       confidence = if (is.list(x$confidence)) unlist(x$confidence) else character(0),
       not_visible = unlist(x$not_visible), notes = as.character(g("notes")))
}

# Deterministic checks on an extraction. Returns data.frame(level, message).
tr_check_extraction <- function(e, kind = "open", levels = NULL) {
  out <- list(); add <- function(l, m) out[[length(out) + 1]] <<- data.frame(level = l, message = m, stringsAsFactors = FALSE)
  if (is.na(e$asset)) add("error", "Instrument not recognised or not visible.")
  if (is.na(e$direction)) add(if (kind == "open") "error" else "warn", "Direction (buy/sell) not recognised or not visible.")
  if (kind %in% c("open", "close") && is.na(e$date)) add("warn", "Date not read; enter it yourself.")
  if (kind %in% c("open", "close") && is.na(e$time)) add("warn", "Time not read; enter it yourself (UK time).")
  if (kind == "open") {
    if (!is.finite(e$entry)) add("error", "Entry price not read.")
    if (!is.finite(e$stop)) add("warn", "No stop visible. Your plan needs a stop on every trade.")
    if (is.finite(e$entry) && is.finite(e$stop) && !is.na(e$direction)) {
      d <- tr_dir(e$direction); if ((e$entry - e$stop) * d <= 0) add("error", "Stop is on the wrong side of the entry for this direction. Re-check the image.")
    }
    if (is.finite(e$entry) && is.finite(e$limit) && !is.na(e$direction)) {
      d <- tr_dir(e$direction); if ((e$limit - e$entry) * d <= 0) add("error", "Limit/target is on the wrong side of the entry for this direction. Re-check the image.")
    }
  }
  if (kind == "close" && !is.finite(e$exit)) add("error", "Exit price not read.")
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
  if (!length(out)) add("ok", "No problems found by the automatic checks. Still compare with the image.")
  do.call(rbind, out)
}

# ---- Platform statement (CSV) --------------------------------------------------------------
tr_stmt_fields <- c(deal_ref = "Deal / reference", open_ts = "Open date/time", close_ts = "Close date/time", asset = "Instrument / market",
                    direction = "Direction", size = "Size", open_price = "Open price", close_price = "Close price", pnl = "Profit / loss", currency = "Currency")

tr_stmt_read <- function(path) {
  for (enc in c("UTF-8-BOM", "UTF-8", "latin1")) {
    d <- tryCatch(utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE, fileEncoding = enc, na.strings = c("", "NA", "-")),
                  error = function(e) NULL)
    if (!is.null(d) && ncol(d) > 1) return(d)
  }
  d <- tryCatch(utils::read.csv2(path, check.names = FALSE, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(d) || ncol(d) < 2) stop("Could not read the file as CSV.")
  d
}

# Best guess of which column holds each field, from header names. Returns named character (NA if none).
tr_stmt_guess_map <- function(cols) {
  pats <- list(
    deal_ref = "deal.?(id|ref)|reference|ticket|order.?id|^id$|trade.?id",
    open_ts = "open.*(date|time)|date.*open|opened|entry.*(date|time)",
    close_ts = "close.*(date|time)|date.*clos|closed|exit.*(date|time)|settle|^date$|date.?/?.?time|^time$",
    asset = "instrument|market|epic|symbol|product|asset",
    direction = "direction|side|buy.?/?sell|b/s|^type$",
    size = "^size|stake|quantity|qty|lots|volume|contracts",
    open_price = "open.*(level|price)|entry.*(level|price)|^open$|opening",
    close_price = "close.*(level|price)|exit.*(level|price)|^close$|closing",
    pnl = "p.?/?.?l|profit|^result|net.*(profit|gbp|p)|realised",
    currency = "curr")
  used <- character(0); out <- setNames(rep(NA_character_, length(pats)), names(pats))
  for (f in names(pats)) {
    hit <- grep(pats[[f]], cols, ignore.case = TRUE, value = TRUE); hit <- setdiff(hit, used)
    if (length(hit)) { out[[f]] <- hit[1]; used <- c(used, hit[1]) }
  }
  out
}

tr_parse_datetime <- function(x, tz = "Europe/London") {
  x <- trimws(as.character(x)); fmts <- c("%d/%m/%Y %H:%M:%S", "%d/%m/%Y %H:%M", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%d-%m-%Y %H:%M:%S",
    "%d-%m-%Y %H:%M", "%d/%m/%y %H:%M:%S", "%d/%m/%y %H:%M", "%d-%b-%y %H:%M:%S", "%d-%b-%y %H:%M", "%d %b %Y %H:%M:%S", "%d %b %Y %H:%M",
    "%d/%m/%Y", "%Y-%m-%d", "%d-%b-%y", "%d %b %Y")
  best <- NULL; bn <- -1
  for (f in fmts) { p <- suppressWarnings(as.POSIXct(x, format = f, tz = tz)); n <- sum(!is.na(p)); if (n > bn) { best <- p; bn <- n } }
  attr(best, "tzone") <- "UTC"; best
}

# Map a raw statement + column mapping to fill rows (schema of trading_platform_fills).
tr_stmt_normalise <- function(df, map, source_file = "", platform = NA_character_, tz = "Europe/London") {
  col <- function(f) if (!is.na(map[[f]]) && map[[f]] %in% names(df)) df[[map[[f]]]] else rep(NA, nrow(df))
  n <- nrow(df)
  close_ts <- tr_parse_datetime(col("close_ts"), tz); open_ts <- tr_parse_datetime(col("open_ts"), tz)
  asset <- tr_norm_asset(col("asset")); dir <- tr_norm_dir(col("direction"))
  size <- tr_parse_num(col("size")); op <- tr_parse_num(col("open_price")); cp <- tr_parse_num(col("close_price")); pnl <- tr_parse_num(col("pnl"))
  ref <- as.character(col("deal_ref")); cur <- as.character(col("currency"))
  key_ts <- ifelse(is.na(close_ts), "NA", format(close_ts, "%Y%m%d%H%M%S", tz = "UTC"))
  fid <- paste0("F_", gsub("[^A-Za-z0-9._-]", "", ifelse(is.na(ref), "", ref)), "_", key_ts, "_", ifelse(is.na(asset), "NA", asset), "_",
                ifelse(is.na(cp), "NA", sprintf("%.5f", cp)), "_", ifelse(is.na(size), "NA", sprintf("%g", size)))
  raw <- vapply(seq_len(n), function(i) as.character(jsonlite::toJSON(as.list(df[i, , drop = FALSE]), auto_unbox = TRUE, na = "null")), "")
  data.frame(fill_id = fid, source_file = source_file, platform = platform, deal_ref = ref, open_ts = open_ts, close_ts = close_ts, asset = asset,
             direction = dir, size = size, open_price = op, close_price = cp, pnl_gbp = pnl, currency = cur, raw_json = raw, stringsAsFactors = FALSE)
}

# Match statement rows to closed trades. A fill matches a trade when asset (and direction, if both
# known) agree and the close times are within tol_minutes; each trade is used once, nearest first.
tr_reconcile <- function(fills, trades, tol_minutes = 15, pnl_tol_gbp = 0.5) {
  cl <- trades[trades$status %in% "CLOSED" & !is.na(trades$exit_ts), , drop = FALSE]
  fills <- fills[!is.na(fills$close_ts), , drop = FALSE]
  fills$matched_trade_id <- NA_character_; fills$status <- "UNRECORDED"; fills$pnl_diff <- NA_real_
  used <- character(0)
  if (nrow(fills) && nrow(cl)) {
    cand <- do.call(rbind, lapply(seq_len(nrow(fills)), function(i) {
      f <- fills[i, ]
      ok <- cl$asset == f$asset & (is.na(f$direction) | is.na(cl$direction) | cl$direction == f$direction)
      ok[is.na(ok)] <- FALSE
      if (!any(ok)) return(NULL)
      dt <- abs(as.numeric(difftime(cl$exit_ts[ok], f$close_ts, units = "mins")))
      data.frame(i = i, trade = cl$trade_id[ok], dt = dt, stringsAsFactors = FALSE)
    }))
    if (!is.null(cand)) {
      cand <- cand[cand$dt <= tol_minutes, , drop = FALSE]; cand <- cand[order(cand$dt), , drop = FALSE]
      done_i <- integer(0)
      for (k in seq_len(nrow(cand))) {
        if (cand$i[k] %in% done_i || cand$trade[k] %in% used) next
        fills$matched_trade_id[cand$i[k]] <- cand$trade[k]; done_i <- c(done_i, cand$i[k]); used <- c(used, cand$trade[k])
      }
    }
  }
  m <- !is.na(fills$matched_trade_id)
  if (any(m)) {
    tp <- cl$net_pnl_gbp[match(fills$matched_trade_id[m], cl$trade_id)]
    fills$pnl_diff[m] <- ifelse(is.na(tp) | is.na(fills$pnl_gbp[m]), NA_real_, tp - fills$pnl_gbp[m])
    fills$status[m] <- ifelse(is.na(fills$pnl_diff[m]), "MATCHED_NO_PNL", ifelse(abs(fills$pnl_diff[m]) <= pnl_tol_gbp, "MATCHED", "PNL_DIFFERS"))
  }
  rng <- if (nrow(fills)) range(fills$close_ts) else c(NA, NA)
  inrange <- if (is.na(rng[1])) rep(FALSE, nrow(cl)) else cl$exit_ts >= rng[1] - tol_minutes * 60 & cl$exit_ts <= rng[2] + tol_minutes * 60
  trades_out <- cl[, c("trade_id", "trade_sheet_name", "asset", "direction", "exit_ts", "net_pnl_gbp", "pnl_source"), drop = FALSE]
  trades_out$status <- ifelse(trades_out$trade_id %in% used, "IN_STATEMENT", ifelse(inrange, "NOT_IN_STATEMENT", "OUTSIDE_STATEMENT_RANGE"))
  list(fills = fills, trades = trades_out)
}
