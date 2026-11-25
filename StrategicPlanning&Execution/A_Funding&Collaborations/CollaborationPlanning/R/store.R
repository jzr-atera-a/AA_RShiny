# R/store.R - one storage interface over Google Sheets, BigQuery and local CSV
#
# Decision (23 Nov 2026): store in BOTH BigQuery and a Google Sheet.
#   * Writes go to every service that is set up (Sheet and BigQuery).
#   * Reads come from the Sheet when it is set up (quick, and what the team sees),
#     otherwise from BigQuery, otherwise from local CSV files in data/ (testing mode).
#   * A failed write to one service is logged and does not stop the other.
# Reads are cached for cfg$cache_secs across all sessions to stay inside Google's quotas.

.store <- new.env(parent = emptyenv())
.store$cache <- list()
.store$version <- 0
.store$sheet_ok <- FALSE
.store$bq_ok <- FALSE
.store$sheet_error <- ""
.store$bq_error <- ""

store_status <- function() list(
  sheet_configured = nzchar(cfg$sheet_id) && sa_key_available(),
  bq_configured    = nzchar(cfg$bq_project) && sa_key_available() && bq_available(),
  sheet_ok = .store$sheet_ok, bq_ok = .store$bq_ok,
  sheet_error = .store$sheet_error, bq_error = .store$bq_error,
  read_from = store_read_from(),
  sa_email = sa_client_email()
)

store_read_from <- function() {
  if (isTRUE(.store$sheet_ok)) "Google Sheet" else if (isTRUE(.store$bq_ok)) "BigQuery" else "Local CSV (testing)"
}

store_mode_csv <- function() !isTRUE(.store$sheet_ok) && !isTRUE(.store$bq_ok)

csv_path <- function(tab) file.path(cfg$data_dir, paste0(tab, ".csv"))

csv_read <- function(tab) {
  p <- csv_path(tab)
  if (!file.exists(p)) return(empty_table(tab))
  conform(utils::read.csv(p, stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE,
                          na.strings = character(0), encoding = "UTF-8"), tab)
}

csv_write <- function(tab, df) {
  dir.create(cfg$data_dir, showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, csv_path(tab), row.names = FALSE, fileEncoding = "UTF-8")
}

# Connect to whatever is set up; create the core tables if they are missing.
store_init <- function() {
  .store$sheet_ok <- FALSE; .store$bq_ok <- FALSE
  .store$sheet_error <- ""; .store$bq_error <- ""
  st <- store_status()
  if (st$sheet_configured) {
    tryCatch({
      tabs <- gs_list_tabs()
      for (t in CORE_TABLES) gs_ensure_tab(t, tabs)
      .store$sheet_ok <- TRUE
      log_debug("[Store] Google Sheet connected")
    }, error = function(e) { .store$sheet_error <- safe_error_text(e); log_debug("[Store] Sheet not available: ", .store$sheet_error) })
  } else log_debug("[Store] Google Sheet not set up (GOOGLE_SHEETS_ID or key missing)")
  if (st$bq_configured) {
    tryCatch({
      for (t in CORE_TABLES) bq_ensure_table(t)
      .store$bq_ok <- TRUE
      log_debug("[Store] BigQuery connected: ", cfg$bq_project, ".", cfg$bq_dataset)
    }, error = function(e) { .store$bq_error <- safe_error_text(e); log_debug("[Store] BigQuery not available: ", .store$bq_error) })
  } else log_debug("[Store] BigQuery not set up (CP_BQ_PROJECT, key or bigrquery missing)")
  log_debug("[Store] reading from: ", store_read_from())
  store_clear_cache()
  seed_defaults()
  invisible(store_status())
}

store_clear_cache <- function(tab = NULL) {
  if (is.null(tab)) .store$cache <- list() else .store$cache[[tab]] <- NULL
  .store$version <- .store$version + 1
}

store_read <- function(tab, fresh = FALSE) {
  hit <- .store$cache[[tab]]
  if (!fresh && !is.null(hit) && difftime(Sys.time(), hit$at, units = "secs") < cfg$cache_secs) return(hit$df)
  df <- tryCatch({
    if (isTRUE(.store$sheet_ok)) {
      # one batched request refreshes every table the Sheet has; a tab that does not exist yet reads as empty
      if (fresh) { gs_tabs_cached(); if (tab %in% .gs$tabs) gs_read(tab) else empty_table(tab) }
      else {
        all <- gs_batch_read(names(SCHEMAS)); now <- Sys.time()
        for (t in names(all)) .store$cache[[t]] <- list(df = all[[t]], at = now)
        all[[tab]] %||% empty_table(tab)
      }
    }
    else if (isTRUE(.store$bq_ok)) bq_read(tab)
    else csv_read(tab)
  }, error = function(e) {
    log_debug("[Store] read ", tab, " failed: ", safe_error_text(e))
    if (!is.null(hit)) hit$df else empty_table(tab)
  })
  .store$cache[[tab]] <- list(df = df, at = Sys.time())
  df
}

# Append rows to every service that is set up. Returns TRUE if at least one write worked.
store_append <- function(tab, df, user = "system", log = TRUE) {
  df <- conform(df, tab)
  if (!nrow(df)) return(TRUE)
  ok <- c()
  if (isTRUE(.store$sheet_ok)) ok["sheet"] <- tryCatch({ gs_ensure_tab(tab); gs_append(tab, df); TRUE },
    error = function(e) { log_debug("[Sheets] append ", tab, " failed: ", safe_error_text(e)); FALSE })
  if (isTRUE(.store$bq_ok)) ok["bq"] <- tryCatch({ bq_append(tab, df); TRUE },
    error = function(e) { log_debug("[BigQuery] append ", tab, " failed: ", safe_error_text(e)); FALSE })
  if (store_mode_csv()) ok["csv"] <- tryCatch({ csv_write(tab, rbind(csv_read(tab), df)); TRUE },
    error = function(e) { log_debug("[CSV] append ", tab, " failed: ", safe_error_text(e)); FALSE })
  store_clear_cache(tab)
  if (log && tab != "changelog") log_change(user, "add", tab, sprintf("%d row(s)", nrow(df)))
  any(ok)
}

# Replace a whole table (used for edits such as moving a programme to another stage)
store_replace <- function(tab, df, user = "system", detail = "") {
  df <- conform(df, tab)
  ok <- c()
  if (isTRUE(.store$sheet_ok)) ok["sheet"] <- tryCatch({ gs_ensure_tab(tab); gs_write_all(tab, df); TRUE },
    error = function(e) { log_debug("[Sheets] write ", tab, " failed: ", safe_error_text(e)); FALSE })
  if (isTRUE(.store$bq_ok)) ok["bq"] <- tryCatch({ bq_write_all(tab, df); TRUE },
    error = function(e) { log_debug("[BigQuery] write ", tab, " failed: ", safe_error_text(e)); FALSE })
  if (store_mode_csv()) ok["csv"] <- tryCatch({ csv_write(tab, df); TRUE },
    error = function(e) { log_debug("[CSV] write ", tab, " failed: ", safe_error_text(e)); FALSE })
  store_clear_cache(tab)
  log_change(user, "update", tab, detail)
  any(ok)
}

# Copy a table from the Sheet into BigQuery (when they have drifted apart)
store_sync_sheet_to_bq <- function(tab, user) {
  if (!isTRUE(.store$sheet_ok) || !isTRUE(.store$bq_ok)) stop("Both the Google Sheet and BigQuery must be connected")
  df <- gs_read(tab)
  bq_write_all(tab, df)
  log_change(user, "sync", tab, sprintf("Sheet to BigQuery, %d rows", nrow(df)))
  nrow(df)
}

log_change <- function(user, action, entity, detail = "") {
  store_append("changelog", data.frame(timestamp = now_ts(), user = user, action = action,
                                       entity = entity, detail = detail, stringsAsFactors = FALSE),
               user = user, log = FALSE)
}

# ---- settings (key/value, latest row wins) ----------------------------------------------
get_settings <- function() {
  s <- SETTING_DEFAULTS
  df <- latest_by(store_read("settings"), "key")
  for (i in seq_len(nrow(df))) s[[df$key[i]]] <- df$value[i]
  s
}

set_setting <- function(key, value, user) {
  store_append("settings", data.frame(key = key, value = as.character(value), updated_by = user,
                                      updated_at = now_ts(), stringsAsFactors = FALSE), user = user, log = FALSE)
  log_change(user, "setting", key, as.character(value))
}

# ---- users --------------------------------------------------------------------------------
get_users <- function() {
  u <- store_read("allowed_emails")
  u$email <- tolower(trimws(u$email))
  u$role <- tolower(trimws(u$role))
  u[nzchar(u$email) & !grepl("^removed_", u$email), , drop = FALSE]
}

user_record <- function(email) {
  email <- tolower(trimws(email %||% ""))
  u <- get_users()
  r <- u[u$email == email & !(toupper(u$active) %in% c("FALSE", "PENDING")), , drop = FALSE]
  if (nrow(r)) r[nrow(r), , drop = FALSE] else NULL
}

is_admin_email <- function(email) {
  email <- tolower(trimws(email %||% ""))
  if (email %in% cfg$admin_emails) return(TRUE)
  r <- user_record(email)
  !is.null(r) && identical(r$role, "admin")
}
