# R/drive.R - copies of the analysis tables on Google Drive, and pulling them back
#
# Two ways (Admin > Google Drive, owner only):
#   api     Google Drive API with the same service account as the Sheet. Use a folder inside a SHARED DRIVE and add
#           the service account as a Content manager: service accounts have no storage of their own, so uploads
#           into a personal "My Drive" folder are refused by Google.
#   folder  A folder on this computer, for example a Google Drive for desktop folder such as
#           "G:/My Drive/Collaboration Planning" (the same idea as the Mi Tesis app's work folder). Only when the app
#           runs on your own computer: shinyapps.io cannot see your drives.
# Each analysis is saved as  <Country>/<Category>/<Topic>/<programme>__<analysis_id>.json  (read back by the app)
# plus a .html file with the tables (to open and read). Files carry cp_type=analysis so they can be found again.

DRIVE_API <- "https://www.googleapis.com/drive/v3/files"
DRIVE_UPLOAD <- "https://www.googleapis.com/upload/drive/v3/files"

drive_mode <- function(s = get_settings()) s$drive_mode %||% "off"
drive_ready <- function(s = get_settings()) {
  m <- drive_mode(s)
  (m == "api" && nzchar(s$drive_folder_id) && sa_key_available()) || (m == "folder" && nzchar(s$drive_local_path))
}

safe_name <- function(x, n = 60) { x <- gsub("[\\\\/:*?\"<>|]+", " ", x); x <- trimws(gsub("\\s+", " ", x)); substr(if (nzchar(x)) x else "untitled", 1, n) }
drive_levels <- function(a) vapply(c(a$country, a$category, a$topic), function(x) safe_name(level_value(x), 50), "", USE.NAMES = FALSE)
drive_file_stem <- function(a) paste0(safe_name(a$programme %|% a$title, 60), "__", a$analysis_id)

# The record saved to Drive: the analysis row (raw text left out when very long) as JSON
analysis_payload <- function(a) {
  rec <- as.list(a[1, SCHEMAS$analyses])
  rec$cp_type <- "analysis"; rec$app_version <- APP_VERSION; rec$saved_at <- now_ts()
  as.character(jsonlite::toJSON(rec, auto_unbox = TRUE, pretty = TRUE))
}

analysis_html <- function(a) {
  tabs <- tables_from_json(a$tables_json)
  body <- htmltools::renderTags(tagList(
    tags$h1(a$title), tags$p(tags$b("Classification: "), paste(level_value(c(a$country, a$category, a$topic, a$programme)), collapse = " > ")),
    tags$p(a$summary), render_tables(tabs),
    tags$p(style = "color:#6b7c88;font-size:12px", paste("Saved from", APP_NAME, APP_VERSION, "on", now_ts(), "- analysis", a$analysis_id))))
  paste0('<!DOCTYPE html><html lang="en-GB"><head><meta charset="utf-8"><title>', htmltools::htmlEscape(a$title), '</title>',
         '<style>body{font-family:Arial,sans-serif;max-width:1100px;margin:24px auto;color:#1d2b36}',
         'table{border-collapse:collapse;width:100%;font-size:13px;margin:6px 0 16px}th{background:#0f4a5c;color:#fff;text-align:left}',
         'th,td{border:1px solid #cfdde3;padding:6px 8px;vertical-align:top}tr:nth-child(even) td{background:#f2f8fa}',
         '.ft-title{font-weight:bold;color:#0f4a5c;margin-top:14px}</style>', body$head, '</head><body>', body$html, '</body></html>')
}

# ---- API mode ---------------------------------------------------------------------------------
drive_auth <- function() httr::add_headers(Authorization = paste("Bearer", google_token()))
drive_q <- function(x) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", x))

drive_req <- function(resp, what) {
  if (httr::status_code(resp) >= 300) {
    msg <- tryCatch(httr::content(resp, as = "parsed")$error$message, error = function(e) NULL) %||% paste("HTTP", httr::status_code(resp))
    if (grepl("storage quota", msg, ignore.case = TRUE))
      msg <- paste(msg, "Use a folder inside a Shared Drive and add the service account to it as Content manager.")
    stop("Google Drive could not ", what, ": ", msg, call. = FALSE)
  }
  httr::content(resp, as = "parsed")
}

drive_find <- function(q) {
  r <- drive_req(httr::GET(DRIVE_API, drive_auth(), httr::timeout(30), query = list(q = q, fields = "files(id,name,modifiedTime,appProperties)",
    supportsAllDrives = "true", includeItemsFromAllDrives = "true", corpora = "allDrives", pageSize = 1000)), "search")
  r$files %||% list()
}

drive_folder <- function(name, parent) {
  hit <- drive_find(sprintf("name = '%s' and '%s' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
                            drive_q(name), drive_q(parent)))
  if (length(hit)) return(hit[[1]]$id)
  r <- drive_req(httr::POST(paste0(DRIVE_API, "?supportsAllDrives=true"), drive_auth(), httr::timeout(30), encode = "json",
                            body = list(name = name, mimeType = "application/vnd.google-apps.folder", parents = list(parent))), "make a folder")
  r$id
}

# Create or replace one file (multipart upload)
drive_put_file <- function(name, content, mime, parent, file_id = "", props = list()) {
  meta <- list(name = name, mimeType = mime)
  if (length(props)) meta$appProperties <- props
  if (!nzchar(file_id)) meta$parents <- list(parent)
  bd <- paste0("cp", paste(sample(c(letters, 0:9), 20, TRUE), collapse = ""))
  body <- paste0("--", bd, "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n", jsonlite::toJSON(meta, auto_unbox = TRUE),
                 "\r\n--", bd, "\r\nContent-Type: ", mime, "; charset=UTF-8\r\n\r\n", content, "\r\n--", bd, "--")
  ct <- httr::content_type(paste0("multipart/related; boundary=", bd))
  url <- if (nzchar(file_id)) paste0(DRIVE_UPLOAD, "/", file_id, "?uploadType=multipart&supportsAllDrives=true&fields=id")
         else paste0(DRIVE_UPLOAD, "?uploadType=multipart&supportsAllDrives=true&fields=id")
  resp <- if (nzchar(file_id)) httr::PATCH(url, drive_auth(), ct, body = charToRaw(enc2utf8(body)), httr::timeout(60))
          else httr::POST(url, drive_auth(), ct, body = charToRaw(enc2utf8(body)), httr::timeout(60))
  drive_req(resp, paste("save", name))$id
}

drive_get_text <- function(file_id) {
  resp <- httr::GET(paste0(DRIVE_API, "/", file_id, "?alt=media&supportsAllDrives=true"), drive_auth(), httr::timeout(60))
  if (httr::status_code(resp) >= 300) drive_req(resp, "read a file")
  httr::content(resp, as = "text", encoding = "UTF-8")
}

# ---- both modes ---------------------------------------------------------------------------------
# Save one analysis; returns list(id, path)
drive_save_analysis <- function(a, s = get_settings()) {
  lv <- drive_levels(a); stem <- drive_file_stem(a); path <- paste(c(lv, stem), collapse = "/")
  if (drive_mode(s) == "folder") {
    dir <- do.call(file.path, as.list(c(s$drive_local_path, lv)))
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(dir)) stop("Cannot create the folder ", dir, ". Check the path in Admin > Google Drive.", call. = FALSE)
    # an older copy filed under another classification is removed, so each analysis lives in one place
    old <- list.files(s$drive_local_path, pattern = paste0("__", a$analysis_id, "\\.(json|html)$"), recursive = TRUE, full.names = TRUE)
    file.remove(setdiff(old, file.path(dir, paste0(stem, c(".json", ".html")))))
    writeLines(enc2utf8(analysis_payload(a)), file.path(dir, paste0(stem, ".json")), useBytes = TRUE)
    writeLines(enc2utf8(analysis_html(a)), file.path(dir, paste0(stem, ".html")), useBytes = TRUE)
    return(list(id = file.path(dir, paste0(stem, ".json")), path = path))
  }
  if (drive_mode(s) != "api") stop("Google Drive is not set up (Admin > Google Drive).", call. = FALSE)
  parent <- s$drive_folder_id
  for (l in lv) parent <- drive_folder(l, parent)
  # same analysis already on Drive? replace it (and its html) instead of making copies
  old <- drive_find(sprintf("appProperties has { key='cp_id' and value='%s' } and trashed = false", drive_q(a$analysis_id)))
  props <- function(kind) list(cp_type = kind, cp_id = a$analysis_id)
  old_json <- Filter(function(f) identical(f$appProperties$cp_type, "analysis"), old)
  old_html <- Filter(function(f) identical(f$appProperties$cp_type, "analysis_html"), old)
  moved <- length(old_json) && !identical(a$drive_path, path)
  if (moved) for (f in c(old_json, old_html)) httr::PATCH(paste0(DRIVE_API, "/", f$id, "?supportsAllDrives=true"), drive_auth(),
                                                          encode = "json", body = list(trashed = TRUE), httr::timeout(30))
  jid <- drive_put_file(paste0(stem, ".json"), analysis_payload(a), "application/json", parent,
                        if (length(old_json) && !moved) old_json[[1]]$id else "", props("analysis"))
  drive_put_file(paste0(stem, ".html"), analysis_html(a), "text/html", parent,
                 if (length(old_html) && !moved) old_html[[1]]$id else "", props("analysis_html"))
  list(id = jid, path = path)
}

# Read every saved analysis back: a data frame with the analyses columns
drive_pull_analyses <- function(s = get_settings()) {
  texts <- if (drive_mode(s) == "folder") {
    f <- list.files(s$drive_local_path, pattern = "__.*\\.json$", recursive = TRUE, full.names = TRUE)
    lapply(f, function(x) paste(readLines(x, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
  } else if (drive_mode(s) == "api") {
    lapply(drive_find("appProperties has { key='cp_type' and value='analysis' } and trashed = false"), function(f) drive_get_text(f$id))
  } else stop("Google Drive is not set up (Admin > Google Drive).", call. = FALSE)
  rows <- lapply(texts, function(t) tryCatch({
    j <- jsonlite::fromJSON(t, simplifyVector = FALSE)
    if (!identical(j$cp_type, "analysis")) NULL else conform(as.data.frame(lapply(j[intersect(names(j), SCHEMAS$analyses)], function(v) as.character(v %||% "")),
                                                                         stringsAsFactors = FALSE), "analyses")
  }, error = function(e) NULL))
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(empty_table("analyses"))
  do.call(rbind, rows)
}

drive_test <- function(s = get_settings()) {
  if (drive_mode(s) == "folder") {
    p <- s$drive_local_path
    if (!nzchar(p)) return(list(ok = FALSE, msg = "Give the folder path."))
    dir.create(p, recursive = TRUE, showWarnings = FALSE)
    f <- file.path(p, ".cp_write_test"); ok <- tryCatch({ writeLines("ok", f); file.remove(f) }, error = function(e) FALSE, warning = function(w) FALSE)
    return(list(ok = isTRUE(ok), msg = if (isTRUE(ok)) paste("The app can write to", normalizePath(p, winslash = "/")) else paste("Cannot write to", p)))
  }
  if (drive_mode(s) == "api") {
    if (!sa_key_available()) return(list(ok = FALSE, msg = "No service account key (the same key as the Google Sheet)."))
    r <- tryCatch(drive_req(httr::GET(paste0(DRIVE_API, "/", s$drive_folder_id), drive_auth(), httr::timeout(20),
                                      query = list(fields = "id,name,driveId", supportsAllDrives = "true")), "open the folder"), error = function(e) e)
    if (inherits(r, "error")) return(list(ok = FALSE, msg = paste(conditionMessage(r), "Share the folder with", sa_client_email())))
    return(list(ok = TRUE, msg = paste0("Found the folder \"", r$name, "\"", if (is.null(r$driveId)) ". It is not in a Shared Drive, so uploads may be refused: move it into a Shared Drive." else " in a Shared Drive.")))
  }
  list(ok = FALSE, msg = "Choose how to save first.")
}

# ---- any file, and copies of the app's tables ----------------------------------------------------
# Save one file under <root>/<dirs...>/<filename>; the same name in the same folder is replaced, not copied
drive_save_file <- function(dirs, filename, content, mime = "text/csv", s = get_settings()) {
  dirs <- vapply(dirs, safe_name, "", USE.NAMES = FALSE)
  if (drive_mode(s) == "folder") {
    dir <- do.call(file.path, as.list(c(s$drive_local_path, dirs))); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(dir)) stop("Cannot create the folder ", dir, call. = FALSE)
    f <- file.path(dir, filename); con <- file(f, open = "wb"); on.exit(close(con))
    writeBin(charToRaw(enc2utf8(content)), con)
    return(paste(c(dirs, filename), collapse = "/"))
  }
  if (drive_mode(s) != "api") stop("Google Drive is not set up (Admin > Google Drive).", call. = FALSE)
  parent <- s$drive_folder_id
  for (d in dirs) parent <- drive_folder(d, parent)
  old <- drive_find(sprintf("name = '%s' and '%s' in parents and trashed = false", drive_q(filename), drive_q(parent)))
  drive_put_file(filename, content, mime, parent, if (length(old)) old[[1]]$id else "", list(cp_type = "file"))
  paste(c(dirs, filename), collapse = "/")
}

csv_text <- function(df) {
  con <- textConnection("out", "w", local = TRUE); utils::write.csv(df, con, row.names = FALSE, fileEncoding = "UTF-8"); close(con)
  paste0("\ufeff", paste(out, collapse = "\n"), "\n")      # BOM so Excel opens accents correctly
}

# Copy every table to <root>/Backups/<date>/<table>.csv (secrets are never in the tables). Returns the number saved.
drive_backup_tables <- function(s = get_settings(), user = "system") {
  day <- format(Sys.Date()); n <- 0; err <- character(0)   # (problems, not 'errors': r$error would partially match it)
  for (t in names(SCHEMAS)) {
    r <- tryCatch({ drive_save_file(c("Backups", day), paste0(t, ".csv"), csv_text(store_read(t, fresh = TRUE)), "text/csv", s); TRUE },
                  error = function(e) { err <<- c(err, paste(t, safe_error_text(e))); FALSE })
    if (r) n <- n + 1
  }
  set_setting("drive_last_backup", now_ts(), user)
  log_change(user, "drive-backup", "all tables", sprintf("%d of %d tables to Backups/%s", n, length(SCHEMAS), day))
  if (length(err)) log_debug("[Drive] backup problems: ", paste(utils::head(err, 3), collapse = " | "))
  list(saved = n, total = length(SCHEMAS), folder = paste("Backups", day, sep = "/"), problems = err)
}

# Once a day, when the owner signs in (shinyapps.io has no scheduler)
drive_backup_if_due <- function(user, s = get_settings()) {
  if (!drive_ready(s) || !is_true(s$drive_auto_backup)) return(invisible(NULL))
  last <- suppressWarnings(as.POSIXct(s$drive_last_backup %||% ""))
  if (length(last) && !is.na(last) && difftime(Sys.time(), last, units = "hours") < 24) return(invisible(NULL))
  r <- tryCatch(drive_backup_tables(s, user), error = function(e) { log_debug("[Drive] daily backup failed: ", safe_error_text(e)); NULL })
  if (!is.null(r)) log_debug(sprintf("[Drive] daily backup: %d of %d tables to %s", r$saved, r$total, r$folder))
  invisible(r)
}
