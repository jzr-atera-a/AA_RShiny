# R/suite_cp.R
# =============================================================================
# CollaborationPlanning's TABLES (read and write) - the app other people use to explore funding and collaboration.
#
# That app keeps its data in BigQuery tables <project>.<dataset>.cp_<table> and, when it has one, in a Google Sheet
# (it then READS from the Sheet and writes to both). To read and write exactly as that app does, its own storage
# code is used here unchanged: R/collab_planning/*.R are its files (config, utils, google_sheets, bigquery, store,
# programmes, analysis, collab), loaded into CP_ENV so none of their names reach this app.
#
#   * BigQuery: this app's connection (API Settings > BigQuery) - same project; dataset/prefix as set in
#     API Settings > Google Drive > CollaborationPlanning. That app's code never logs in again with another key.
#   * Google Sheet: its own service-account token (the CollaborationPlanning key, or the keys-folder key).
#   * Writes go through its store_append() / add_programmes(): same columns, ids, change log and duplicate rules.
#
# The Drive exchange (analyses + backups) stays in R/utils_collab_sync.R.
# =============================================================================

CP_ENV <- new.env(parent = globalenv())
CP_FILES <- c("config.R", "utils.R", "google_sheets.R", "bigquery.R", "store.R", "programmes.R", "analysis.R", "collab.R")
for (f in CP_FILES) sys.source(file.path("R", "collab_planning", f), envir = CP_ENV, keep.source = FALSE)
CP_ENV$cfg$data_dir <- file.path(tempdir(), "cp_unused")    # never used: a write needs BigQuery here (see cp_connect)
cat(sprintf("✓ [CollaborationPlanning] storage code %s loaded (%d files)\n", CP_ENV$APP_VERSION, length(CP_FILES)))

CP_PROGRAMME_SOURCE <- "Business Operations Suite"   # 'source' of programmes this app adds to its list

# a Sheet link or a bare id -> the id
cp_sheet_id <- function(x) {
  x <- trimws(x %|g|% "")
  m <- regmatches(x, regexpr("/d/[A-Za-z0-9_-]+", x))
  if (length(m)) sub("^/d/", "", m) else x
}

# Points that app's storage code at the right places. Call before every read/write batch (cheap).
cp_connect <- function(api, s = collab_load_settings()) {
  if (!isTRUE(api$bq_authenticated)) stop("Connect to BigQuery first (API Settings > BigQuery): CollaborationPlanning's tables are read and written with that connection.", call. = FALSE)
  key <- if (nzchar(s$key_file %|g|% "")) s$key_file else (api$bq_credentials_path %|g|% tryCatch(cred_local()$json_path, error = function(e) ""))
  cfg <- CP_ENV$cfg
  changed <- !identical(c(cfg$bq_project, cfg$bq_dataset, cfg$bq_prefix, cfg$sheet_id, cfg$sa_key_path),
                        c(api$bq_project_id, s$bq_dataset, s$bq_prefix, s$sheet_id, key))
  cfg$bq_project <- api$bq_project_id
  cfg$bq_dataset <- if (nzchar(s$bq_dataset %|g|% "")) s$bq_dataset else "business_strategy"
  cfg$bq_prefix  <- s$bq_prefix %|g|% "cp_"
  cfg$sheet_id   <- cp_sheet_id(s$sheet_id)
  cfg$sa_key_path <- key %|g|% ""
  assign("cfg", cfg, envir = CP_ENV)
  st <- CP_ENV$.store; bq <- CP_ENV$.bq; gs <- CP_ENV$.gs
  if (changed) { bq$tables_ok <- character(0); gs$token <- NULL; gs$token_exp <- NULL; st$sheet_ok <- FALSE }
  bq$authed <- TRUE                       # this app's BigQuery login is used as it is
  st$bq_ok <- TRUE; st$bq_error <- ""
  if (nzchar(cfg$sheet_id)) {
    if (!isTRUE(st$sheet_ok)) {
      if (!nzchar(cfg$sa_key_path) || !file.exists(cfg$sa_key_path))
        stop("CollaborationPlanning uses a Google Sheet, but no service-account key was found to open it (API Settings > Google Drive > CollaborationPlanning).", call. = FALSE)
      ok <- tryCatch({ CP_ENV$gs_list_tabs(); TRUE }, error = function(e) { st$sheet_error <- conditionMessage(e); FALSE })
      if (!ok) stop("CollaborationPlanning's Google Sheet could not be opened: ", st$sheet_error,
                    " - share it with ", CP_ENV$sa_client_email(), " as Editor, or check the id.", call. = FALSE)
      st$sheet_ok <- TRUE
    }
  } else st$sheet_ok <- FALSE
  if (changed) CP_ENV$store_clear_cache()
  invisible(list(write_to = c(if (isTRUE(st$sheet_ok)) "Google Sheet", "BigQuery"), read_from = CP_ENV$store_read_from(),
                 dataset = paste0(cfg$bq_project, ".", cfg$bq_dataset), prefix = cfg$bq_prefix))
}

cp_read <- function(tab) CP_ENV$store_read(tab, fresh = TRUE)

# ---- READ ------------------------------------------------------------------------------------------------
# its programmes list -> funding_programmes rows (same mapping as its daily backup)
cp_programme_rows <- function() {
  p <- cp_read("programmes")
  if (!nrow(p)) return(collab_conform(NULL))
  p <- CP_ENV$latest_by(p, "programme_id")
  out <- collab_programmes_to_bos(p)
  if (nrow(out)) out$source <- COLLAB_SOURCE_TABLE
  out
}
# its analyses (latest version of each, not deleted, not the ones this app shared) -> funding_programmes rows
cp_analysis_rows <- function() {
  a <- CP_ENV$latest_analyses(cp_read("analyses"))
  files <- lapply(seq_len(nrow(a)), function(i) list(ref = a$analysis_id[i],
    text = as.character(jsonlite::toJSON(c(as.list(a[i, , drop = FALSE]), cp_type = "analysis"), auto_unbox = TRUE))))
  collab_read_analyses(files)
}
cp_people <- function() CP_ENV$latest_people(cp_read("people"))
cp_messages <- function() cp_read("messages")

# ---- WRITE -----------------------------------------------------------------------------------------------
# our funding rows -> its programmes list, through its own add_programmes() (skips funder + name already there)
cp_write_programmes <- function(d, user) {
  if (!nrow(d)) return(list(added = 0, skipped = 0))
  x <- CP_ENV$programmes_from_parsed(as.data.frame(d, stringsAsFactors = FALSE), source = CP_PROGRAMME_SOURCE)
  x$added_by <- tolower(user %|g|% "")
  CP_ENV$add_programmes(x, tolower(user %|g|% "business-operations-suite"))
}
# collab_export_record() results -> rows of its analyses table (newest version wins there, by analysis_id)
cp_write_analyses <- function(recs, user) {
  if (!length(recs)) return(0L)
  rows <- do.call(rbind, lapply(recs, function(e) {
    j <- jsonlite::fromJSON(e$json, simplifyVector = FALSE)
    as.data.frame(lapply(stats::setNames(COLLAB_ANALYSIS_COLS, COLLAB_ANALYSIS_COLS), function(k) collab_chr(j[[k]])[1]), stringsAsFactors = FALSE)
  }))
  ok <- CP_ENV$store_append("analyses", rows, user = tolower(user %|g|% "business-operations-suite"))
  if (!isTRUE(ok)) stop("CollaborationPlanning's analyses table did not accept the rows (see the R console).", call. = FALSE)
  nrow(rows)
}
