# R/bigquery.R - BigQuery through bigrquery, using the same service account key
# Every column is stored as STRING so the Sheet and BigQuery copies hold identical rows;
# typed views (dates, numbers) can be added in BigQuery later without changing the app.

bq_available <- function() requireNamespace("bigrquery", quietly = TRUE)

.bq <- new.env(parent = emptyenv())
.bq$authed <- FALSE
.bq$tables_ok <- character(0)

bq_table_id <- function(tab) sprintf("%s.%s.%s%s", cfg$bq_project, cfg$bq_dataset, cfg$bq_prefix, tab)

bq_auth_once <- function() {
  if (isTRUE(.bq$authed)) return(TRUE)
  if (!bq_available()) stop("The bigrquery package is not installed")
  if (!sa_key_available()) stop("Service account key not found at ", cfg$sa_key_path)
  bigrquery::bq_auth(path = cfg$sa_key_path)
  .bq$authed <- TRUE
  TRUE
}

bq_tbl <- function(tab) {
  bigrquery::bq_table(cfg$bq_project, cfg$bq_dataset, paste0(cfg$bq_prefix, tab))
}

bq_ensure_table <- function(tab) {
  if (tab %in% .bq$tables_ok) return(invisible(FALSE))
  bq_auth_once()
  t <- bq_tbl(tab)
  if (!bigrquery::bq_table_exists(t)) {
    fields <- bigrquery::as_bq_fields(lapply(SCHEMAS[[tab]], function(c) bigrquery::bq_field(c, "STRING")))
    bigrquery::bq_table_create(t, fields = fields)
    log_debug("[BigQuery] created table ", bq_table_id(tab))
  } else {
    # same as ALTER TABLE ... ADD COLUMN x STRING for columns added to SCHEMAS later
    have <- vapply(bigrquery::bq_table_fields(t), function(f) f$name, "")
    miss <- setdiff(SCHEMAS[[tab]], have)
    if (length(miss)) {
      fields <- bigrquery::as_bq_fields(c(bigrquery::bq_table_fields(t),
                                          lapply(miss, function(c) bigrquery::bq_field(c, "STRING"))))
      bigrquery::bq_table_patch(t, fields)
      log_debug("[BigQuery] added columns to ", bq_table_id(tab), ": ", paste(miss, collapse = ", "))
    }
  }
  .bq$tables_ok <- unique(c(.bq$tables_ok, tab))
  invisible(TRUE)
}

bq_read <- function(tab) {
  bq_ensure_table(tab)
  q <- sprintf("SELECT * FROM `%s`", bq_table_id(tab))
  df <- bigrquery::bq_table_download(bigrquery::bq_project_query(cfg$bq_project, q))
  conform(as.data.frame(df), tab)
}

bq_append <- function(tab, df) {
  if (!nrow(df)) return(invisible(0))
  bq_ensure_table(tab)
  bigrquery::bq_table_upload(bq_tbl(tab), values = df, write_disposition = "WRITE_APPEND",
                             create_disposition = "CREATE_NEVER")
  invisible(nrow(df))
}

bq_write_all <- function(tab, df) {
  bq_ensure_table(tab)
  bigrquery::bq_table_upload(bq_tbl(tab), values = df, write_disposition = "WRITE_TRUNCATE",
                             create_disposition = "CREATE_NEVER")
  invisible(nrow(df))
}

# Read any BigQuery table by its full id (used to import the old funding_programmes table)
bq_read_external <- function(full_id, limit = 5000) {
  bq_auth_once()
  q <- sprintf("SELECT * FROM `%s` LIMIT %d", safe_sql_escape(full_id), as.integer(limit))
  as.data.frame(bigrquery::bq_table_download(bigrquery::bq_project_query(cfg$bq_project, q)))
}
