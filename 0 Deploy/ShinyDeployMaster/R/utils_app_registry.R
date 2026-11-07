# R/utils_app_registry.R
# ─────────────────────────────────────────────────────────────────────
# App registry: every shinyapps.io app this tool manages.
#
#   BigQuery  atera-2.business_strategy.deploy_apps  (source of truth when connected)
#   Local     data/deploy_apps.txt                    (tab-separated mirror, offline view)
#
# Columns: title_of_app | active_url | Updated_Date | status
#   active_url   = https://atera-analytics.shinyapps.io/<title_of_app>/
#   Updated_Date = date of the last deployment (seeded with the creation date)
#   status       = "Active" | "Archived"
#
# Rules
#   * Reads: BigQuery when connected, otherwise the text file.
#   * Writes: BigQuery first. Each write is read back and checked. Only after
#     that is the full table mirrored to the text file, so the file always
#     equals the latest BigQuery state.
#   * First connect with an empty deploy_apps table: the current default list
#     (the text file, or the built-in list if there is no file) is loaded into it.
# ─────────────────────────────────────────────────────────────────────

SDM_APPS_TABLE    <- "deploy_apps"
SDM_APPS_TXT      <- normalizePath(file.path("data", "deploy_apps.txt"), mustWork = FALSE)
SDM_APPS_TXT_NAME <- file.path("data", "deploy_apps.txt")
SDM_APPS_URL_BASE <- "https://atera-analytics.shinyapps.io/"
SDM_APPS_COLS     <- c("title_of_app", "active_url", "Updated_Date", "status")
SDM_APPS_SEED     <- c(
  "booksnetworksstrategysixs",
  "businessoperationssuite",
  "daysplanningfundingtravel",
  "trading_analysis_f1",
  "ventureanalysis",
  "mat_health_intelligence_poc",
  "drivesafe_suite_with_osa_road_risk",
  "david_cleevely_serendipity",
  "simon_hall_cc",
  "trading_analysis_lat_2026_u3"
)

app_url_for <- function(title) paste0(SDM_APPS_URL_BASE, title, "/")

# ── Shape helpers ───────────────────────────────────────────────────
normalize_apps_df <- function(d) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  miss <- setdiff(SDM_APPS_COLS, names(d))
  if (length(miss)) stop("registry is missing column(s): ", paste(miss, collapse = ", "))
  d <- d[, SDM_APPS_COLS, drop = FALSE]
  for (cl in SDM_APPS_COLS)
    d[[cl]] <- trimws(ifelse(is.na(d[[cl]]), "", as.character(d[[cl]])))
  d <- d[nzchar(d$title_of_app), , drop = FALSE]
  d <- d[!duplicated(d$title_of_app), , drop = FALSE]
  d <- d[order(tolower(d$title_of_app)), , drop = FALSE]
  rownames(d) <- NULL
  d
}

seed_apps_df <- function() {
  normalize_apps_df(data.frame(
    title_of_app     = SDM_APPS_SEED,
    active_url       = app_url_for(SDM_APPS_SEED),
    Updated_Date     = as.character(Sys.Date()),
    status           = "Active",
    stringsAsFactors = FALSE
  ))
}

# ── Local text file ─────────────────────────────────────────────────
read_apps_txt <- function() {
  if (!file.exists(SDM_APPS_TXT)) return(NULL)
  d <- tryCatch(
    utils::read.delim(SDM_APPS_TXT, colClasses = "character", quote = "", comment.char = "",
                      na.strings = character(0), stringsAsFactors = FALSE, fileEncoding = "UTF-8"),
    error = function(e) NULL
  )
  if (is.null(d) || !all(SDM_APPS_COLS %in% names(d))) return(NULL)
  normalize_apps_df(d)
}

write_apps_txt <- function(d) {
  d   <- normalize_apps_df(d)
  dir.create(dirname(SDM_APPS_TXT), showWarnings = FALSE, recursive = TRUE)
  tmp <- paste0(SDM_APPS_TXT, ".tmp")
  utils::write.table(d, tmp, sep = "\t", quote = FALSE, row.names = FALSE, fileEncoding = "UTF-8")
  ok  <- file.copy(tmp, SDM_APPS_TXT, overwrite = TRUE)
  unlink(tmp)
  if (!isTRUE(ok)) stop("could not write ", SDM_APPS_TXT)
  invisible(SDM_APPS_TXT)
}

# ── BigQuery helpers ────────────────────────────────────────────────
bq_apps_table_id <- function(api) paste0(api$bq_project_id, ".", api$bq_dataset_id, ".", SDM_APPS_TABLE)

# Single-quoted BigQuery string literal (escapes embedded quotes)
bq_sql_str <- function(x) paste0("'", gsub("'", "\\\\'", x), "'")

# DATE literal, or NULL for an empty date
bq_date_lit <- function(x) ifelse(nzchar(x), paste0("DATE('", x, "')"), "NULL")

bq_short_sql <- function(sql) substr(gsub("\\s+", " ", trimws(sql)), 1, 400)

# Runs a statement (DDL/DML). bigrquery waits for the job itself.
bq_run_sql <- function(api, label, sql) {
  sdm_log("BQ", sprintf("%s: running", label), "cmd")
  t0  <- Sys.time()
  err <- tryCatch({ bigrquery::bq_project_query(api$bq_project_id, sql); NULL },
                  error = function(e) e)
  if (!is.null(err)) {
    sdm_log("BQ", sprintf("%s: FAILED: %s", label, conditionMessage(err)), "error")
    sdm_log("BQ", paste("   SQL:", bq_short_sql(sql)), "error")
    stop(sprintf("%s failed: %s", label, conditionMessage(err)), call. = FALSE)
  }
  sdm_log("BQ", sprintf("%s: OK (%.1f s)", label, as.numeric(difftime(Sys.time(), t0, units = "secs"))), "success")
  invisible(TRUE)
}

# Runs a SELECT and returns a plain data.frame
bq_select <- function(api, label, sql) {
  res <- tryCatch(api$bq_query(sql), error = function(e) e)
  if (inherits(res, "error")) {
    sdm_log("BQ", sprintf("%s: FAILED: %s", label, conditionMessage(res)), "error")
    sdm_log("BQ", paste("   SQL:", bq_short_sql(sql)), "error")
    stop(sprintf("%s failed: %s", label, conditionMessage(res)), call. = FALSE)
  }
  as.data.frame(res, stringsAsFactors = FALSE)
}

bq_read_apps <- function(api) {
  d <- bq_select(api, "read deploy_apps", sprintf(
    "SELECT title_of_app, active_url, CAST(Updated_Date AS STRING) AS Updated_Date, status
       FROM `%s` ORDER BY title_of_app", bq_apps_table_id(api)))
  normalize_apps_df(d)
}

bq_count <- function(api, tbl = bq_apps_table_id(api)) {
  d <- bq_select(api, "count deploy_apps", sprintf(
    "SELECT CAST(COUNT(*) AS STRING) AS n FROM `%s`", tbl))
  suppressWarnings(as.numeric(d$n[1]))
}

# Reads the table again until check() is TRUE (BigQuery can lag a moment behind a write)
bq_verify <- function(label, check, tries = 5) {
  for (i in seq_len(tries)) {
    ok <- tryCatch(isTRUE(check()), error = function(e) FALSE)
    if (ok) {
      sdm_log("BQ", sprintf("%s: verified by reading the table back", label), "success")
      return(invisible(TRUE))
    }
    if (i < tries) Sys.sleep(2)
  }
  msg <- sprintf("%s: BigQuery does not show the change after %d reads", label, tries)
  sdm_log("BQ", msg, "error")
  stop(msg, call. = FALSE)
}

# Creates deploy_apps if missing (never alters anything else). If the table is
# empty, loads the current default list into it.
bq_ensure_apps_table <- function(api) {
  tbl <- bq_apps_table_id(api)
  sdm_log("REGISTRY", sprintf("Checking table %s", tbl))

  bq_run_sql(api, "create deploy_apps if missing", sprintf("
    CREATE TABLE IF NOT EXISTS `%s` (
      title_of_app STRING NOT NULL,
      active_url   STRING,
      Updated_Date DATE,
      status       STRING)", tbl))

  n <- bq_count(api, tbl)
  sdm_log("REGISTRY", sprintf("Rows in deploy_apps: %d", n))
  if (!is.na(n) && n == 0) {
    src <- read_apps_txt()
    from <- SDM_APPS_TXT_NAME
    if (is.null(src)) { src <- seed_apps_df(); from <- "the built-in default list" }
    sdm_log("REGISTRY", sprintf("Table is empty: loading %d apps from %s", nrow(src), from))

    vals <- sprintf("(%s, %s, %s, %s)",
                    bq_sql_str(src$title_of_app),
                    bq_sql_str(app_url_for(src$title_of_app)),
                    bq_date_lit(src$Updated_Date),
                    bq_sql_str(ifelse(src$status == "Archived", "Archived", "Active")))
    bq_run_sql(api, "load default apps", sprintf(
      "INSERT INTO `%s` (title_of_app, active_url, Updated_Date, status) VALUES %s",
      tbl, paste(vals, collapse = ",\n")))
    bq_verify("load default apps", function() bq_count(api, tbl) == nrow(src))
  }
  invisible(TRUE)
}

bq_update_status <- function(api, titles, statuses) {
  if (!length(titles)) return(invisible(TRUE))
  structs <- sprintf("STRUCT(%s AS title_of_app, %s AS status)",
                     bq_sql_str(titles), bq_sql_str(statuses))
  bq_run_sql(api, "save status changes", sprintf("
    MERGE `%s` AS t
    USING (SELECT * FROM UNNEST([%s])) AS s
    ON t.title_of_app = s.title_of_app
    WHEN MATCHED THEN UPDATE SET t.status = s.status",
    bq_apps_table_id(api), paste(structs, collapse = ",\n")))
  bq_verify("save status changes", function() {
    d <- bq_read_apps(api)
    identical(unname(d$status[match(titles, d$title_of_app)]), statuses)
  })
}

# New app -> inserted as Active. Existing app -> only Updated_Date changes
# (its status is left as the user set it).
bq_upsert_deploy <- function(api, title, url, date) {
  bq_run_sql(api, sprintf("register deployment of %s", title), sprintf("
    MERGE `%s` AS t
    USING (SELECT * FROM UNNEST([STRUCT(%s AS title_of_app, %s AS active_url,
                                        DATE('%s') AS Updated_Date, 'Active' AS status)])) AS s
    ON t.title_of_app = s.title_of_app
    WHEN MATCHED THEN UPDATE SET t.Updated_Date = s.Updated_Date
    WHEN NOT MATCHED THEN INSERT (title_of_app, active_url, Updated_Date, status)
      VALUES (s.title_of_app, s.active_url, s.Updated_Date, s.status)",
    bq_apps_table_id(api), bq_sql_str(title), bq_sql_str(url), date))
  bq_verify(sprintf("register deployment of %s", title), function() {
    d <- bq_read_apps(api)
    identical(unname(d$Updated_Date[match(title, d$title_of_app)]), date)
  })
}

# ── Public API used by the Explore and Deploy tabs ──────────────────

# Table to show: BigQuery when connected, otherwise the text file.
load_apps <- function(api) {
  if (isTRUE(api$bq_authenticated)) {
    d <- tryCatch(bq_read_apps(api), error = function(e) e)
    if (!inherits(d, "error")) {
      sdm_log("REGISTRY", sprintf("Showing %d apps from BigQuery", nrow(d)), "success")
      tryCatch({
        write_apps_txt(d)
        sdm_log("REGISTRY", sprintf("Mirrored to %s", SDM_APPS_TXT_NAME))
      }, error = function(e) sdm_log("REGISTRY", paste("Could not write local file:", conditionMessage(e)), "error"))
      return(list(data = d, source = "BigQuery table deploy_apps", note = NULL))
    }
    note <- paste("BigQuery read failed, so the local file is shown:", conditionMessage(d))
    sdm_log("REGISTRY", note, "error")
  } else {
    note <- "BigQuery is not connected, so the local file is shown. Connect under APIs -> BigQuery to load the live table."
  }
  d <- read_apps_txt()
  if (is.null(d)) {
    d <- seed_apps_df()
    tryCatch(write_apps_txt(d), error = function(e) NULL)
  }
  sdm_log("REGISTRY", sprintf("Showing %d apps from %s", nrow(d), SDM_APPS_TXT_NAME))
  list(data = d, source = SDM_APPS_TXT_NAME, note = note)
}

# Writes status changes to BigQuery (verified), then mirrors the table to the text file.
registry_save_status <- function(api, titles, statuses) {
  sdm_log("REGISTRY", sprintf("Saving %d status change(s)", length(titles)), "cmd")
  tryCatch({
    bq_update_status(api, titles, statuses)
    write_apps_txt(bq_read_apps(api))
    sdm_log("REGISTRY", sprintf("Status saved; mirrored to %s", SDM_APPS_TXT_NAME), "success")
    list(ok = TRUE,
         msg = sprintf("Saved %d change(s) to BigQuery and %s", length(titles), SDM_APPS_TXT_NAME))
  }, error = function(e) {
    sdm_log("REGISTRY", paste("Save FAILED:", conditionMessage(e)), "error")
    list(ok = FALSE, msg = conditionMessage(e))
  })
}

# Called after a successful deployment: sets Updated_Date to today, or adds the row.
registry_record_deploy <- function(api, title) {
  if (!isTRUE(api$bq_authenticated)) {
    sdm_log("REGISTRY", "Deployment not recorded: BigQuery is not connected", "error")
    return(list(ok = FALSE, msg = "BigQuery is not connected"))
  }
  date <- as.character(Sys.Date())
  sdm_log("REGISTRY", sprintf("Recording deployment of %s (Updated_Date %s)", title, date), "cmd")
  tryCatch({
    bq_upsert_deploy(api, title, app_url_for(title), date)
    write_apps_txt(bq_read_apps(api))
    sdm_log("REGISTRY", sprintf("Deployment recorded; mirrored to %s", SDM_APPS_TXT_NAME), "success")
    list(ok = TRUE,
         msg = sprintf("Registry updated: %s, Updated_Date %s (BigQuery + %s)", title, date, SDM_APPS_TXT_NAME))
  }, error = function(e) {
    sdm_log("REGISTRY", paste("Recording deployment FAILED:", conditionMessage(e)), "error")
    list(ok = FALSE, msg = conditionMessage(e))
  })
}
