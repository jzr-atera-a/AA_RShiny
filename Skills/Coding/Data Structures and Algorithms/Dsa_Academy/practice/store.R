# practice/store.R — all saved data lives in Google BigQuery.
#
# One BigQuery connection (service-account key), one dataset, one table per kind of record
# (prefix dsa_). Connecting creates the dataset and any missing table / column
# (CREATE TABLE IF NOT EXISTS, ALTER TABLE ADD COLUMN IF NOT EXISTS) and never drops or rewrites
# anything that is already there.
#
# How reads and writes work
#   * On connect, every table is read in ONE query and kept in memory, so pages never wait for BigQuery.
#   * Every change is applied in memory at once and queued. The queue is sent to BigQuery as one
#     multi-statement transaction (BEGIN … COMMIT) a few seconds later, when a session ends and when
#     the app stops. Repeated updates of the same row (draft autosave, time-on-task) are coalesced.
#   * Before a connection exists the app still works; changes wait in the queue and are written when
#     you connect (APIs › BigQuery, or automatically from a key file — see bq_find_key()).
#
# Credentials are found like the Business Operations Suite: C:/111_SecA/_q_api on Windows (or the folder
# in LAT_CRED_DIR), then DSA_BQ_KEY_FILE / ATERA_BQ_KEY_FILE / GOOGLE_APPLICATION_CREDENTIALS, then by hand.
# Keys are only read: never copied, written to BigQuery, or printed.

# Local folder for files that are not records (diagram exports, the optional Drive key). No database here.
DATA_DIR <- local({
  d <- Sys.getenv("DSA_DATA_DIR", file.path(getwd(), "data"))
  ok <- tryCatch({ dir.create(d, showWarnings = FALSE, recursive = TRUE); file.access(d, 2) == 0 }, error = function(e) FALSE)
  if (!isTRUE(ok)) { d <- file.path(tempdir(), "dsa_data"); dir.create(d, showWarnings = FALSE) }
  normalizePath(d)
})

now_ts <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")
today  <- function() format(Sys.Date(), "%Y-%m-%d")

# ── Table definitions ────────────────────────────────────────────────────────
S <- function(...) c(...)
BQ_SCHEMA <- list(
  submissions      = S(id = "INT64", problem_id = "STRING", ts = "STRING", day = "STRING", mode = "STRING", verdict = "STRING",
                       passed = "INT64", total = "INT64", runtime_ms = "FLOAT64", code = "STRING"),
  drafts           = S(problem_id = "STRING", code = "STRING", updated = "STRING"),
  time_log         = S(day = "STRING", problem_id = "STRING", seconds = "FLOAT64"),
  reviews          = S(problem_id = "STRING", stage = "INT64", next_due = "STRING", last_ts = "STRING", last_result = "STRING"),
  quiz_attempts    = S(id = "INT64", topic = "STRING", ts = "STRING", correct = "INT64", total = "INT64"),
  interviews       = S(id = "INT64", ts = "STRING", mode = "STRING", minutes = "INT64", seconds_used = "FLOAT64", problems = "STRING",
                       tests_score = "FLOAT64", self_score = "FLOAT64", total = "FLOAT64", details = "STRING"),
  settings         = S(key = "STRING", value = "STRING"),
  exports          = S(id = "INT64", ts = "STRING", export_id = "STRING", backend = "STRING", root = "STRING", group_name = "STRING",
                       topic = "STRING", section = "STRING", diagram = "STRING", step = "STRING", label = "STRING", format = "STRING",
                       file_name = "STRING", folder_path = "STRING", rel_path = "STRING", location = "STRING", link = "STRING",
                       bytes = "INT64", status = "STRING", error = "STRING"),
  drive_folders    = S(path = "STRING", id = "STRING", ts = "STRING"),
  project_attempts = S(id = "INT64", ts = "STRING", day = "STRING", project_id = "STRING", mode = "STRING", passed = "INT64", total = "INT64",
                       caught_ai = "INT64", mutants_caught = "INT64", mutants_total = "INT64", seconds = "FLOAT64", review = "STRING",
                       files = "STRING", tests = "STRING", self_score = "FLOAT64"),
  reading_attempts = S(id = "INT64", ts = "STRING", day = "STRING", ex_id = "STRING", correct = "INT64", seconds = "FLOAT64",
                       explanation = "STRING", self_score = "FLOAT64"),
  star_stories     = S(id = "INT64", created = "STRING", updated = "STRING", title = "STRING", competencies = "STRING", situation = "STRING",
                       task = "STRING", action = "STRING", result = "STRING", learning = "STRING", metrics = "STRING", strength = "INT64"),
  behav_attempts   = S(id = "INT64", ts = "STRING", day = "STRING", question_id = "STRING", question = "STRING", competency = "STRING",
                       story_id = "INT64", seconds = "FLOAT64", answer = "STRING", scores = "STRING", total = "FLOAT64"),
  design_attempts  = S(id = "INT64", ts = "STRING", day = "STRING", prompt_id = "STRING", seconds = "FLOAT64", notes = "STRING",
                       checklist = "STRING", coverage = "FLOAT64", self_score = "FLOAT64")
)
rm(S)
BQ_KEYS <- list(drafts = "problem_id", time_log = c("day", "problem_id"), reviews = "problem_id", settings = "key", drive_folders = "path")
BQ_DESCRIPTION <- c(
  submissions = "Every Run / Submit / interview submission from the judge", drafts = "Latest editor contents per problem or project",
  time_log = "Seconds on task per day and problem", reviews = "Spaced-repetition state per solved problem",
  quiz_attempts = "Topic quiz results", interviews = "Mock interview results", settings = "App settings (export / Drive)",
  exports = "Diagram export history", drive_folders = "Google Drive folder-id cache", project_attempts = "AI-assisted round attempts",
  reading_attempts = "Code-reading answers", star_stories = "STAR behavioural story bank", behav_attempts = "Behavioural practice answers",
  design_attempts = "System-design mock attempts")
BQ_SKIP_ON_LOAD <- list(submissions = "code")      # large columns fetched on demand

# ── Connection state ─────────────────────────────────────────────────────────
.bq <- new.env()
.mem <- new.env()
local({
  .bq$project  <- Sys.getenv("DSA_BQ_PROJECT", "atera-2")
  .bq$dataset  <- Sys.getenv("DSA_BQ_DATASET", "business_strategy")
  .bq$prefix   <- Sys.getenv("DSA_BQ_PREFIX", "dsa_")
  .bq$location <- Sys.getenv("DSA_BQ_LOCATION", "")
  .bq$authenticated <- FALSE; .bq$ready <- FALSE; .bq$loaded <- FALSE
  .bq$queue <- list(); .bq$ctr <- 0; .bq$fail_count <- 0; .bq$dropped <- list()
  .bq$status <- "not connected"; .bq$source <- ""; .bq$client_email <- ""; .bq$last_error <- ""; .bq$last_sync <- NA; .bq$created <- character(0)
  .bq$log <- character(0)
  .mem$tables <- list()
})

options(bigrquery.quiet = TRUE)   # no "Job complete / Billed" lines in the console for every sync

# All bigrquery calls go through BQ() so tests can plug in a fake engine (.bq$mock).
BQ <- function(name) if (!is.null(.bq$mock[[name]])) .bq$mock[[name]] else getExportedValue("bigrquery", name)
bq_available <- function() !is.null(.bq$mock) || requireNamespace("bigrquery", quietly = TRUE)
bq_note <- function(...) { m <- paste0(format(Sys.time(), "%H:%M:%S"), "  ", paste0(...)); .bq$log <- tail(c(.bq$log, m), 200); cat("[BigQuery]", paste0(...), "\n") }

# Run a SELECT and return a data.frame (quietly: no "Job complete / Billed" console lines)
bq_get <- function(sql) as.data.frame(BQ("bq_table_download")(BQ("bq_project_query")(.bq$project, sql, quiet = TRUE), bigint = "numeric", quiet = TRUE),
                                      stringsAsFactors = FALSE)

bq_table_name <- function(t) paste0(.bq$prefix, t)
bq_full <- function(t) sprintf("`%s.%s.%s`", .bq$project, .bq$dataset, bq_table_name(t))
bq_id <- function(x) paste0("`", x, "`")

# ── SQL literals ─────────────────────────────────────────────────────────────
sql_str <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("'", "\\'", x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE); x <- gsub("\n", "\\n", x, fixed = TRUE); x <- gsub("\t", "\\t", x, fixed = TRUE)
  x <- gsub("[\001-\010\013\014\016-\037\177]", "", x, perl = TRUE)
  paste0("'", x, "'")
}
sql_lit <- function(v, type) {
  if (is.null(v) || length(v) == 0 || is.na(v)) return("NULL")
  switch(type,
    STRING  = sql_str(v),
    INT64   = { n <- suppressWarnings(as.numeric(v)); if (is.na(n) || !is.finite(n)) "NULL" else sprintf("%.0f", round(n)) },
    FLOAT64 = { n <- suppressWarnings(as.numeric(v)); if (is.na(n) || !is.finite(n)) "NULL" else sprintf("CAST('%s' AS FLOAT64)", formatC(n, digits = 15, format = "g")) },
    sql_str(v))
}
sql_where <- function(t, where) {
  if (is.null(where) || !length(where)) return("TRUE")
  sch <- BQ_SCHEMA[[t]]
  paste(vapply(names(where), function(k) {
    v <- where[[k]]
    if (length(v) == 1 && is.na(v)) sprintf("%s IS NULL", bq_id(k)) else sprintf("%s = %s", bq_id(k), sql_lit(v, sch[[k]]))
  }, ""), collapse = " AND ")
}

# ── In-memory tables ─────────────────────────────────────────────────────────
bq_empty <- function(t) {
  sch <- BQ_SCHEMA[[t]]
  df <- as.data.frame(lapply(sch, function(ty) if (ty == "STRING") character(0) else numeric(0)), stringsAsFactors = FALSE)
  names(df) <- names(sch); df
}
bq_coerce <- function(t, df) {
  sch <- BQ_SCHEMA[[t]]; out <- bq_empty(t)
  if (is.null(df) || !nrow(df)) return(out)
  res <- lapply(names(sch), function(k) {
    v <- if (k %in% names(df)) df[[k]] else rep(NA, nrow(df))
    if (is.list(v)) v <- vapply(v, function(z) if (is.null(z) || !length(z)) NA_character_ else as.character(z[[1]]), "")
    if (sch[[k]] == "STRING") as.character(v) else suppressWarnings(as.numeric(v))
  })
  names(res) <- names(sch)
  as.data.frame(res, stringsAsFactors = FALSE)
}
bq_new_id <- function() { .bq$ctr <- (.bq$ctr + 1) %% 1000; floor(as.numeric(Sys.time()) * 1000) * 1000 + .bq$ctr }

mem_tbl <- function(t) {
  if (isTRUE(.bq$ready) && !isTRUE(.bq$loaded)) bq_load_all(throttle = TRUE)
  .mem$tables[[t]] %||% bq_empty(t)
}
mem_put <- function(t, df) .mem$tables[[t]] <- df
row_match <- function(df, where) {
  if (!nrow(df)) return(logical(0))
  m <- rep(TRUE, nrow(df))
  for (k in names(where)) { v <- where[[k]]; m <- m & if (length(v) == 1 && is.na(v)) is.na(df[[k]]) else (!is.na(df[[k]]) & df[[k]] == v) }
  m
}
# Frequent background writes (autosaved drafts, time on task) wait a minute; everything else is sent within seconds.
queue_add <- function(item) {
  .bq$queue[[length(.bq$queue) + 1]] <- item
  bq_schedule_flush(if (item$table %in% c("time_log", "drafts")) 60 else 5)
}

mem_insert <- function(t, row) {
  sch <- BQ_SCHEMA[[t]]
  row <- lapply(row, function(v) if (is.null(v) || length(v) == 0) NA else v[[1]])
  if ("id" %in% names(sch) && (is.null(row$id) || is.na(row$id))) row$id <- bq_new_id()
  r <- bq_coerce(t, as.data.frame(row[intersect(names(row), names(sch))], stringsAsFactors = FALSE))
  mem_put(t, rbind(mem_tbl(t), r))
  queue_add(list(kind = "insert", table = t, row = r))
  invisible(if ("id" %in% names(sch)) r$id else NULL)
}
mem_upsert <- function(t, row) {
  keys <- BQ_KEYS[[t]]; df <- mem_tbl(t)
  r <- bq_coerce(t, as.data.frame(lapply(row, function(v) if (is.null(v) || !length(v)) NA else v[[1]]), stringsAsFactors = FALSE))
  hit <- row_match(df, as.list(r[1, keys, drop = FALSE]))
  df <- if (any(hit)) { df[which(hit)[1], ] <- r; df[!(hit & seq_along(hit) != which(hit)[1]), , drop = FALSE] } else rbind(df, r)
  mem_put(t, df)
  kv <- paste(t, paste(unlist(r[1, keys]), collapse = "\r"), sep = "\r")
  .bq$queue <- Filter(function(it) !(identical(it$kind, "upsert") && identical(it$kv, kv)), .bq$queue)   # only the latest value matters
  queue_add(list(kind = "upsert", table = t, kv = kv, row = r))
  invisible(TRUE)
}
mem_update <- function(t, where, set) {
  df <- mem_tbl(t); m <- row_match(df, where)
  for (k in names(set)) if (any(m)) df[[k]][m] <- if (BQ_SCHEMA[[t]][[k]] == "STRING") as.character(set[[k]] %||% NA) else suppressWarnings(as.numeric(set[[k]] %||% NA))
  mem_put(t, df)
  # a row still waiting in the queue is simply updated there
  pend <- FALSE
  for (i in seq_along(.bq$queue)) {
    it <- .bq$queue[[i]]
    if (it$kind %in% c("insert", "upsert") && identical(it$table, t) && isTRUE(row_match(it$row, where)[1])) {
      for (k in names(set)) it$row[[k]] <- df[[k]][m][1]
      .bq$queue[[i]] <- it; pend <- TRUE
    }
  }
  sets <- paste(vapply(names(set), function(k) sprintf("%s = %s", bq_id(k), sql_lit(set[[k]], BQ_SCHEMA[[t]][[k]])), ""), collapse = ", ")
  queue_add(list(kind = "sql", table = t, sql = sprintf("UPDATE %%T%% SET %s WHERE %s", sets, sql_where(t, where))))
  invisible(sum(m))
}
mem_delete <- function(t, where = NULL) {
  df <- mem_tbl(t)
  mem_put(t, if (is.null(where)) bq_empty(t) else df[!row_match(df, where), , drop = FALSE])
  queue_add(list(kind = "sql", table = t, sql = sprintf("DELETE FROM %%T%% WHERE %s", sql_where(t, where))))
  invisible(TRUE)
}

# ── Rendering the queue into one transaction ─────────────────────────────────
bq_render <- function(items) {
  out <- character(0); i <- 1
  ins_sql <- function(t, rows) {
    sch <- BQ_SCHEMA[[t]]; cols <- names(sch)
    vals <- vapply(seq_len(nrow(rows)), function(j) paste0("(", paste(vapply(cols, function(k) sql_lit(rows[[k]][j], sch[[k]]), ""), collapse = ", "), ")"), "")
    sprintf("INSERT INTO %s (%s) VALUES\n  %s", bq_full(t), paste(bq_id(cols), collapse = ", "), paste(vals, collapse = ",\n  "))
  }
  while (i <= length(items)) {
    it <- items[[i]]
    if (it$kind == "insert") {
      rows <- it$row; j <- i + 1
      while (j <= length(items) && items[[j]]$kind == "insert" && identical(items[[j]]$table, it$table) && nrow(rows) < 200) { rows <- rbind(rows, items[[j]]$row); j <- j + 1 }
      out <- c(out, ins_sql(it$table, rows)); i <- j; next
    }
    if (it$kind == "upsert") {
      keys <- BQ_KEYS[[it$table]]
      out <- c(out, sprintf("DELETE FROM %s WHERE %s", bq_full(it$table), sql_where(it$table, as.list(it$row[1, keys, drop = FALSE]))),
               ins_sql(it$table, it$row))
    } else out <- c(out, gsub("%T%", bq_full(it$table), it$sql, fixed = TRUE))
    i <- i + 1
  }
  out
}
bq_run_script <- function(stmts, transaction = TRUE) {
  sql <- paste0(if (transaction) "BEGIN TRANSACTION;\n" else "", paste(stmts, collapse = ";\n"), ";", if (transaction) "\nCOMMIT TRANSACTION;" else "")
  job <- BQ("bq_perform_query")(sql, billing = .bq$project)
  BQ("bq_job_wait")(job, quiet = TRUE)
  invisible(TRUE)
}

# Send queued changes. Chunks of ~800 KB of SQL, each one transaction. Never raises.
bq_flush <- function(reason = "") {
  if (!isTRUE(.bq$ready) || !length(.bq$queue)) return(invisible(TRUE))
  t0 <- Sys.time(); sent <- 0
  repeat {
    if (!length(.bq$queue)) break
    # take items until the rendered SQL reaches ~800 KB
    n <- 0; size <- 0; stmts <- character(0)
    while (n < length(.bq$queue)) {
      s <- bq_render(.bq$queue[n + 1]); sz <- sum(nchar(s, type = "bytes"))
      if (n > 0 && size + sz > 800000) break
      n <- n + 1; size <- size + sz
    }
    stmts <- bq_render(.bq$queue[seq_len(n)])
    ok <- tryCatch({ bq_run_script(stmts); TRUE }, error = function(e) { .bq$last_error <- conditionMessage(e); FALSE })
    if (ok) { .bq$queue <- .bq$queue[-seq_len(n)]; sent <- sent + n; .bq$fail_count <- 0; next }
    .bq$fail_count <- .bq$fail_count + 1
    bq_note("sync failed (attempt ", .bq$fail_count, "): ", .bq$last_error)
    if (.bq$fail_count >= 3) {
      # isolate a change BigQuery keeps rejecting so it cannot block everything else
      it <- .bq$queue[[1]]
      ok1 <- tryCatch({ bq_run_script(bq_render(list(it))); TRUE }, error = function(e) { .bq$last_error <- conditionMessage(e); FALSE })
      transient <- grepl("serializ|concurrent|rate ?limit|quota|timed? ?out|timeout|connect|resolve|network|backendError|internalError|HTTP (401|403|429|5\\d\\d)|Unauthori|Forbidden|Access Denied|permission|SSL|curl",
                         .bq$last_error, ignore.case = TRUE)
      if (!ok1 && transient) { .bq$fail_count <- 0; break }     # BigQuery or the network is the problem, not the change: keep everything
      if (!ok1) { .bq$dropped[[length(.bq$dropped) + 1]] <- list(item = it, error = .bq$last_error, ts = now_ts()); bq_note("dropped one change to ", it$table, ": ", .bq$last_error) }
      .bq$queue <- .bq$queue[-1]; .bq$fail_count <- 0; next
    }
    break
  }
  if (sent) { .bq$last_sync <- Sys.time(); .bq$last_error <- ""; bq_note(sprintf("synced %d change(s) in %.1f s%s", sent, as.numeric(difftime(Sys.time(), t0, units = "secs")), if (nzchar(reason)) paste0(" (", reason, ")") else "")) }
  invisible(!length(.bq$queue))
}
bq_schedule_flush <- function(delay = 5) {
  if (!isTRUE(.bq$ready) || !requireNamespace("later", quietly = TRUE)) return(invisible())
  due <- as.numeric(Sys.time()) + delay
  if (!is.null(.bq$flush_due) && .bq$flush_due <= due + 0.5) return(invisible())   # an earlier sync is already planned
  .bq$flush_due <- due
  later::later(function() {
    if (is.null(.bq$flush_due) || as.numeric(Sys.time()) + 0.5 < .bq$flush_due) return()   # superseded by an earlier one
    .bq$flush_due <- NULL
    bq_flush("auto")
    if (length(.bq$queue)) bq_schedule_flush(30)
  }, delay)
}

# ── Tables: create what is missing, never drop or alter types ────────────────
bq_ddl <- function(t) {
  sch <- BQ_SCHEMA[[t]]
  sprintf("CREATE TABLE IF NOT EXISTS %s (\n  %s\n) OPTIONS (description = %s)", bq_full(t),
          paste(sprintf("%s %s", bq_id(names(sch)), unname(sch)), collapse = ",\n  "), sql_str(paste("DSA Academy:", BQ_DESCRIPTION[[t]])))
}
bq_ensure_tables <- function() {
  ds <- BQ("bq_dataset")(.bq$project, .bq$dataset)
  if (!isTRUE(BQ("bq_dataset_exists")(ds))) {
    bq_note("dataset ", .bq$project, ".", .bq$dataset, " not found - creating it")
    if (nzchar(.bq$location)) BQ("bq_dataset_create")(ds, location = .bq$location) else BQ("bq_dataset_create")(ds)
  }
  cols <- bq_get(sprintf(
    "SELECT table_name, column_name FROM `%s.%s.INFORMATION_SCHEMA.COLUMNS` WHERE STARTS_WITH(table_name, %s)",
    .bq$project, .bq$dataset, sql_str(.bq$prefix)))
  stmts <- character(0); created <- character(0); added <- character(0)
  for (t in names(BQ_SCHEMA)) {
    tn <- bq_table_name(t)
    if (!tn %in% cols$table_name) { stmts <- c(stmts, bq_ddl(t)); created <- c(created, tn); next }
    miss <- setdiff(names(BQ_SCHEMA[[t]]), cols$column_name[cols$table_name == tn])
    for (k in miss) { stmts <- c(stmts, sprintf("ALTER TABLE %s ADD COLUMN IF NOT EXISTS %s %s", bq_full(t), bq_id(k), BQ_SCHEMA[[t]][[k]])); added <- c(added, paste0(tn, ".", k)) }
  }
  if (length(stmts)) bq_run_script(stmts, transaction = FALSE)
  .bq$created <- created
  if (length(created)) bq_note("created ", length(created), " table(s): ", paste(created, collapse = ", "))
  if (length(added)) bq_note("added column(s): ", paste(added, collapse = ", "))
  list(created = created, added = added)
}

# Read every table in one query: each row arrives as JSON tagged with its table.
bq_load_all <- function(throttle = FALSE) {
  if (throttle && !is.null(.bq$last_load_try) && difftime(Sys.time(), .bq$last_load_try, units = "secs") < 60) return(invisible(FALSE))
  .bq$last_load_try <- Sys.time()
  parts <- vapply(names(BQ_SCHEMA), function(t) {
    skip <- BQ_SKIP_ON_LOAD[[t]]
    src <- if (length(skip)) sprintf("(SELECT * EXCEPT(%s) FROM %s)", paste(bq_id(skip), collapse = ", "), bq_full(t)) else bq_full(t)
    sprintf("SELECT %s AS t, TO_JSON_STRING(x) AS j FROM %s AS x", sql_str(t), src)
  }, "")
  t0 <- Sys.time()
  ok <- tryCatch({
    d <- bq_get(paste(parts, collapse = "\nUNION ALL\n"))
    for (t in names(BQ_SCHEMA)) {
      js <- d$j[d$t == t]
      loaded <- if (length(js)) bq_coerce(t, jsonlite::fromJSON(paste0("[", paste(js, collapse = ","), "]"), simplifyDataFrame = TRUE)) else bq_empty(t)
      # keep local rows that have not reached BigQuery yet
      pend <- Filter(function(it) it$kind %in% c("insert", "upsert") && identical(it$table, t), .bq$queue)
      if (length(pend)) {
        pr <- do.call(rbind, lapply(pend, function(it) it$row))
        idc <- if ("id" %in% names(BQ_SCHEMA[[t]])) "id" else BQ_KEYS[[t]]
        k_l <- do.call(paste, c(lapply(idc, function(k) loaded[[k]]), sep = "\r")); k_p <- do.call(paste, c(lapply(idc, function(k) pr[[k]]), sep = "\r"))
        loaded <- rbind(loaded[!k_l %in% k_p, , drop = FALSE], pr)
      }
      .mem$tables[[t]] <- loaded
    }
    .bq$loaded <- TRUE
    bq_note(sprintf("loaded %d row(s) from %d tables in %.1f s", nrow(d), length(BQ_SCHEMA), as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    TRUE
  }, error = function(e) { .bq$last_error <- conditionMessage(e); bq_note("load failed: ", conditionMessage(e)); FALSE })
  invisible(ok)
}

# ── Connect ──────────────────────────────────────────────────────────────────
bq_check_key <- function(path) {
  j <- tryCatch(jsonlite::fromJSON(path), error = function(e) stop("The key file is not valid JSON."))
  miss <- setdiff(c("type", "project_id", "private_key", "client_email"), names(j))
  if (length(miss)) stop("Missing fields in the service-account key: ", paste(miss, collapse = ", "))
  if (!identical(j$type, "service_account")) stop("This JSON is not a service-account key (type = ", j$type, ").")
  j
}

# Connect with a key file (path) or pasted key text; create missing tables; send pending changes; load everything.
bq_connect <- function(json_path = NULL, json_text = NULL, project = .bq$project, dataset = .bq$dataset, prefix = .bq$prefix,
                       location = .bq$location, source = "by hand") {
  if (!bq_available()) stop("The bigrquery package is not installed: install.packages(\"bigrquery\")")
  from_text <- !is.null(json_text) && nzchar(trimws(json_text))
  if (from_text) {
    json_path <- tempfile(fileext = ".json"); writeLines(json_text, json_path); on.exit(unlink(json_path), add = TRUE)
  }
  if (is.null(json_path) || !nzchar(json_path) || !file.exists(json_path)) stop("Provide a service-account key file or paste its JSON.")
  j <- bq_check_key(json_path)
  if (!grepl("^[A-Za-z0-9_]+$", dataset)) stop("Dataset IDs may contain only letters, digits and underscores.")
  if (!grepl("^[a-z][a-z0-9_-]*$", project) && !grepl(":", project)) stop("That does not look like a Google Cloud project ID.")
  if (!grepl("^[A-Za-z0-9_]*$", prefix)) stop("The table prefix may contain only letters, digits and underscores.")
  t0 <- Sys.time()
  was_ready <- isTRUE(.bq$ready)
  if (was_ready) bq_flush("before reconnecting")
  .bq$ready <- FALSE; .bq$authenticated <- FALSE; .bq$loaded <- FALSE
  .bq$project <- project; .bq$dataset <- dataset; .bq$prefix <- prefix; .bq$location <- location
  tryCatch({
    tryCatch(BQ("bq_deauth")(), error = function(e) NULL)
    BQ("bq_auth")(path = json_path, cache = FALSE)
    .bq$authenticated <- TRUE; .bq$client_email <- j$client_email; .bq$source <- source
    .bq$key_path <- if (from_text) "" else normalizePath(json_path)      # Google Drive can reuse a key file (never a pasted one)
    res <- bq_ensure_tables()
    .bq$ready <- TRUE; .bq$status <- "connected"
    bq_flush("pending changes from before connecting")
    bq_load_all()
    bq_note(sprintf("connected as %s to %s.%s in %.1f s", j$client_email, project, dataset, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    res
  }, error = function(e) {
    .bq$ready <- FALSE; .bq$authenticated <- FALSE; .bq$status <- "failed"; .bq$last_error <- conditionMessage(e)
    stop("BigQuery connection failed: ", conditionMessage(e), call. = FALSE)
  })
}
bq_disconnect <- function() {
  bq_flush("disconnect")
  tryCatch(BQ("bq_deauth")(), error = function(e) NULL)
  .bq$ready <- FALSE; .bq$authenticated <- FALSE; .bq$status <- "not connected"; .bq$source <- ""
  bq_note("disconnected")
}

# Where a key can be found without asking (same order as the Business Operations Suite)
bq_cred_dir <- function() {
  d <- Sys.getenv("LAT_CRED_DIR", "")
  if (nzchar(d)) d else if (.Platform$OS.type == "windows") "C:/111_SecA/_q_api" else ""
}
bq_find_key <- function() {
  d <- bq_cred_dir()
  if (nzchar(d) && dir.exists(d)) {
    js <- list.files(d, pattern = "\\.json$", full.names = TRUE, ignore.case = TRUE)
    info <- do.call(rbind, lapply(js, function(f) {
      j <- tryCatch(jsonlite::fromJSON(f, simplifyVector = TRUE), error = function(e) NULL)
      if (is.list(j) && identical(j$type, "service_account") && !is.null(j$private_key))
        data.frame(path = f, project = j$project_id %||% "", mtime = as.numeric(file.mtime(f)), stringsAsFactors = FALSE)
    }))
    if (!is.null(info) && nrow(info)) {
      info <- info[order(info$project != .bq$project, -info$mtime), , drop = FALSE]
      return(list(path = info$path[1], source = sprintf("%s (found in %s)", basename(info$path[1]), d)))
    }
  }
  for (v in c("DSA_BQ_KEY_FILE", "ATERA_BQ_KEY_FILE", "GOOGLE_APPLICATION_CREDENTIALS")) {
    k <- Sys.getenv(v, "")
    if (nzchar(k) && file.exists(k)) return(list(path = k, source = sprintf("%s (from %s)", basename(k), v)))
  }
  NULL
}
# Called once per R process after the first page has been sent.
bq_startup <- function() {
  if (isTRUE(.bq$startup_done)) return(invisible(.bq$ready))
  .bq$startup_done <- TRUE
  if (!bq_available()) { .bq$status <- "bigrquery missing"; bq_note("the bigrquery package is not installed"); return(invisible(FALSE)) }
  k <- bq_find_key()
  if (is.null(k)) { .bq$status <- "no key"; bq_note("no service-account key found automatically - connect in APIs > BigQuery"); return(invisible(FALSE)) }
  bq_note("key found: ", k$source, " - connecting")
  ok <- tryCatch({ bq_connect(json_path = k$path, source = paste("automatically with", k$source)); TRUE },
                 error = function(e) { bq_note(conditionMessage(e)); FALSE })
  invisible(ok)
}

bq_where <- function() sprintf("%s.%s (tables %s*)", .bq$project, .bq$dataset, .bq$prefix)
bq_state <- function() list(ready = isTRUE(.bq$ready), status = .bq$status, pending = length(.bq$queue), last_sync = .bq$last_sync,
                            last_error = .bq$last_error, where = bq_where(), email = .bq$client_email, source = .bq$source,
                            dropped = length(.bq$dropped))

# Sidebar light
bq_status_box <- function() tags$div(style = "padding:10px; margin:6px 10px; background:rgba(0,0,0,.18); border-radius:8px;",
  tags$div(style = "color:#c7d2fe; font-size:11px; font-weight:700; margin-bottom:4px; letter-spacing:.05em;", "BIGQUERY"), uiOutput("bq_light"))
bq_status_light <- function() {
  s <- bq_state()
  col <- if (s$ready && !s$pending) "#22c55e" else if (s$ready) "#fbbf24" else "#ef4444"
  txt <- if (s$ready && !s$pending) "connected, all saved" else if (s$ready && nzchar(s$last_error)) sprintf("%d change(s) waiting — last sync failed", s$pending)
         else if (s$ready) sprintf("%d change(s) syncing…", s$pending)
         else if (identical(s$status, "bigrquery missing")) "install.packages(\"bigrquery\")"
         else sprintf("not connected — %d change(s) kept in memory only. APIs › BigQuery", s$pending)
  tags$div(style = "display:flex; gap:6px; font-size:11.5px; color:#e2e8f0; line-height:1.35;",
    tags$span(style = sprintf("display:inline-block; width:10px; height:10px; border-radius:50%%; background:%s; margin-top:3px; flex:none;", col)),
    tags$span(txt))
}

# ── Spaced repetition and the record-keeping API used by the modules ────────
REVIEW_GAPS <- c(3, 7, 21)

db_review_update <- function(pid, accepted) {
  r <- mem_tbl("reviews"); r <- r[r$problem_id == pid, , drop = FALSE]
  due_now <- nrow(r) == 1 && !is.na(r$next_due) && r$next_due <= today()
  if (accepted) {
    if (nrow(r) == 0) {
      mem_upsert("reviews", list(problem_id = pid, stage = 1, next_due = format(Sys.Date() + REVIEW_GAPS[1]), last_ts = now_ts(), last_result = "solved"))
    } else if (due_now) {
      stage <- r$stage + 1
      nd <- if (stage <= length(REVIEW_GAPS)) format(Sys.Date() + REVIEW_GAPS[stage]) else NA_character_
      mem_upsert("reviews", list(problem_id = pid, stage = stage, next_due = nd, last_ts = now_ts(), last_result = "reviewed"))
    } else {
      mem_upsert("reviews", list(problem_id = pid, stage = r$stage, next_due = r$next_due, last_ts = now_ts(), last_result = "solved again"))
    }
  } else if (due_now) {
    mem_upsert("reviews", list(problem_id = pid, stage = r$stage, next_due = format(Sys.Date() + 1), last_ts = now_ts(), last_result = "review failed"))
  }
}

db_add_submission <- function(pid, mode, res, code) {
  verdict <- res$verdict %||% "Internal Error"
  mem_insert("submissions", list(problem_id = pid, ts = now_ts(), day = today(), mode = mode, verdict = verdict,
                                 passed = res$passed %||% NA, total = if (is.null(res$total) || is.na(res$total)) NA else res$total,
                                 runtime_ms = res$user_ms %||% NA, code = code))
  if (mode %in% c("submit", "interview") && !(verdict %in% c("Internal Error", "Python not found")))
    db_review_update(pid, verdict == "Accepted")
}
db_log_event <- function(pid, mode, verdict) mem_insert("submissions", list(problem_id = pid, ts = now_ts(), day = today(), mode = mode, verdict = verdict))

db_save_draft <- function(pid, code) mem_upsert("drafts", list(problem_id = pid, code = code, updated = now_ts()))
db_get_draft <- function(pid) { d <- mem_tbl("drafts"); x <- d$code[d$problem_id == pid]; if (length(x) && !is.na(x[1])) x[1] else NULL }
db_delete_draft <- function(pid) mem_delete("drafts", list(problem_id = pid))

db_add_time <- function(pid, seconds) {
  t <- mem_tbl("time_log"); cur <- t$seconds[t$day == today() & t$problem_id == pid]
  mem_upsert("time_log", list(day = today(), problem_id = pid, seconds = (if (length(cur)) cur[1] else 0) + seconds))
}
db_quiz_attempt <- function(topic, correct, total) mem_insert("quiz_attempts", list(topic = topic, ts = now_ts(), correct = correct, total = total))
db_save_interview <- function(mode, minutes, seconds_used, problems, tests_score, self_score, total, details) {
  mem_insert("interviews", list(ts = now_ts(), mode = mode, minutes = minutes, seconds_used = seconds_used, problems = paste(problems, collapse = ","),
                                tests_score = tests_score, self_score = self_score, total = total, details = details))
}

# ── Queries (served from memory) ─────────────────────────────────────────────
ord <- function(df, col, desc = TRUE) if (nrow(df)) df[order(df[[col]], decreasing = desc), , drop = FALSE] else df

db_submissions <- function(pid = NULL) {
  s <- mem_tbl("submissions"); if (!is.null(pid)) s <- s[s$problem_id == pid, , drop = FALSE]
  s <- ord(s, "id"); rownames(s) <- NULL
  s[, c("id", "problem_id", "ts", "day", "mode", "verdict", "passed", "total", "runtime_ms")]
}
db_submission_code <- function(id) {
  s <- mem_tbl("submissions"); x <- s$code[!is.na(s$id) & s$id == id]
  if (length(x) && !is.na(x[1])) return(x[1])
  if (!isTRUE(.bq$ready)) return(NA_character_)
  code <- tryCatch({
    d <- bq_get(sprintf("SELECT code FROM %s WHERE id = %s LIMIT 1", bq_full("submissions"), sql_lit(id, "INT64")))
    if (nrow(d)) as.character(d$code[1]) else NA_character_
  }, error = function(e) NA_character_)
  if (!is.na(code)) { s$code[!is.na(s$id) & s$id == id] <- code; mem_put("submissions", s) }
  code
}
# Full history including code, for the CSV export
db_submissions_full <- function() {
  if (isTRUE(.bq$ready)) {
    bq_flush("export")
    d <- tryCatch(bq_get(sprintf("SELECT * FROM %s ORDER BY id", bq_full("submissions"))),
                  error = function(e) NULL)
    if (!is.null(d)) return(bq_coerce("submissions", as.data.frame(d)))
  }
  ord(mem_tbl("submissions"), "id", FALSE)
}

db_problem_status <- function() {
  s <- mem_tbl("submissions"); s <- s[s$mode %in% c("submit", "interview"), , drop = FALSE]; s <- ord(s, "id", FALSE)
  r <- mem_tbl("reviews"); tl <- mem_tbl("time_log")
  tsum <- if (nrow(tl)) tapply(tl$seconds, tl$problem_id, sum, na.rm = TRUE) else numeric(0)
  out <- PRACTICE_DF[, c("id", "num", "title", "difficulty", "topic", "meta", "google")]
  out$attempts <- as.integer(table(factor(s$problem_id, levels = out$id)))
  out$solved   <- out$id %in% s$problem_id[s$verdict == "Accepted"]
  first <- s[!duplicated(s$problem_id), , drop = FALSE]
  out$first_try <- out$id %in% first$problem_id[first$verdict == "Accepted"]
  out$last_ts  <- vapply(out$id, function(i) { x <- s$ts[s$problem_id == i]; if (length(x)) max(x) else NA_character_ }, "")
  out$stage    <- r$stage[match(out$id, r$problem_id)]
  out$next_due <- r$next_due[match(out$id, r$problem_id)]
  out$seconds  <- as.numeric(tsum[out$id]); out$seconds[is.na(out$seconds)] <- 0
  out$status <- ifelse(out$solved, "solved", ifelse(out$attempts > 0, "attempted", "new"))
  out$due <- !is.na(out$next_due) & out$next_due <= today()
  out
}

db_activity <- function() {
  s <- mem_tbl("submissions"); s <- s[s$mode %in% c("run", "submit", "interview"), , drop = FALSE]
  a <- if (nrow(s)) data.frame(day = names(table(s$day)), n = as.numeric(table(s$day)),
                               ac = as.numeric(tapply(s$verdict == "Accepted", s$day, sum, na.rm = TRUE)[names(table(s$day))]), stringsAsFactors = FALSE)
       else data.frame(day = character(0), n = numeric(0), ac = numeric(0))
  tl <- mem_tbl("time_log")
  t <- if (nrow(tl)) data.frame(day = names(tapply(tl$seconds, tl$day, sum)), seconds = as.numeric(tapply(tl$seconds, tl$day, sum, na.rm = TRUE)), stringsAsFactors = FALSE)
       else data.frame(day = character(0), seconds = numeric(0))
  m <- merge(a, t, by = "day", all = TRUE)
  m$n[is.na(m$n)] <- 0; m$ac[is.na(m$ac)] <- 0; m$seconds[is.na(m$seconds)] <- 0
  m
}

db_quiz_best <- function() {
  q <- mem_tbl("quiz_attempts")
  if (!nrow(q)) return(data.frame(topic = character(0), best = numeric(0), attempts = numeric(0), last_ts = character(0), total = numeric(0)))
  q$ratio <- q$correct / q$total
  do.call(rbind, lapply(split(q, q$topic), function(d) data.frame(topic = d$topic[1], best = max(d$ratio, na.rm = TRUE), attempts = nrow(d),
                                                                   last_ts = max(d$ts), total = max(d$total), stringsAsFactors = FALSE)))
}

db_interviews <- function() { d <- ord(mem_tbl("interviews"), "id"); rownames(d) <- NULL; d }

db_streak <- function() {
  days <- as.Date(unique(c(mem_tbl("submissions")$day, mem_tbl("time_log")$day)))
  days <- days[!is.na(days)]
  if (!length(days)) return(0L)
  d <- Sys.Date(); if (!(d %in% days)) d <- d - 1
  k <- 0L
  while (d %in% days) { k <- k + 1L; d <- d - 1 }
  k
}

db_reset <- function() {
  for (t in c("submissions", "drafts", "time_log", "reviews", "quiz_attempts", "interviews",
              "project_attempts", "reading_attempts", "behav_attempts", "design_attempts")) mem_delete(t)
  # settings, export history, the Drive folder cache and the STAR story bank are kept on purpose
  bq_flush("reset")
}

# ── Settings (key / value) ───────────────────────────────────────────────────
setting_get <- function(key, default = "") {
  s <- mem_tbl("settings"); v <- s$value[s$key == key]
  if (length(v) && !is.na(v[1])) v[1] else default
}
setting_set <- function(key, value) invisible(mem_upsert("settings", list(key = key, value = as.character(value %||% ""))))

# ── Generic helpers used by the practice-round modules ──────────────────────
db_insert <- function(table, row) mem_insert(table, row)
db_update <- function(table, id, set) mem_update(table, list(id = id), set)
db_table <- function(table, order = "id DESC") {
  d <- mem_tbl(table); p <- strsplit(trimws(order), "\\s+")[[1]]
  d <- ord(d, p[1], !identical(toupper(p[2] %||% "ASC"), "ASC")); rownames(d) <- NULL; d
}
db_story_save <- function(st, id = NULL) {
  if (is.null(id) || is.na(id)) return(mem_insert("star_stories", c(list(created = now_ts(), updated = now_ts()), st)))
  mem_update("star_stories", list(id = id), c(list(updated = now_ts()), st))
  id
}
db_story_delete <- function(id) mem_delete("star_stories", list(id = id))
