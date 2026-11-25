# core/gdrive.R - Google Drive API v3 client: folder tree, uploads, shared catalogue.
#
# A "drive session" `d` is an environment holding:
#   conn      list(token, email, client_id, subject)
#   root_id   folder or shared-drive ID everything is saved under
#   drive_id  shared drive ID (NULL when the root is in someone's My Drive)
#   folders   cache: "<parent>/<name>" -> folder ID, so each folder is looked up once

DRIVE_SCOPE  <- "https://www.googleapis.com/auth/drive"
DRIVE_API    <- "https://www.googleapis.com/drive/v3"
DRIVE_UPLOAD <- "https://www.googleapis.com/upload/drive/v3"
FOLDER_MIME  <- "application/vnd.google-apps.folder"
FILE_FIELDS  <- "id,name,mimeType,size,webViewLink,parents,modifiedTime"
MULTIPART_MAX <- 4 * 1024^2          # bigger files use a resumable upload

DEFAULT_SCHEME <- list(
  app_name        = "Atera Analytics",
  folder_template = "{app}/{property}/{group}/{tab}/{chart}/{year}-{month}",
  file_template   = "{chart_slug}__{start}_to_{end}__{stamp}",
  latest          = TRUE,
  latest_template = "{app}/{property}/{group}/{tab}/{chart}/latest",
  default_formats = c("html", "png", "pdf", "csv")
)
TEMPLATE_TOKENS <- c("app", "property", "group", "tab", "chart", "chart_slug", "format",
                     "year", "month", "day", "date", "time", "stamp", "start", "end", "period", "mode")

MANIFEST_COLS <- c("saved_at", "app", "data_mode", "property", "group", "tab", "chart", "chart_id",
                   "format", "file_name", "folder_path", "file_id", "web_view_link", "mime_type",
                   "size_bytes", "period_start", "period_end", "comparison", "latest_file_id", "request_id")

# ---- Connection -------------------------------------------------------------
drive_session <- function(json_path, root_input, subject = NULL) {
  info <- ga_read_key(json_path)
  subject <- trimws(subject %||% "")
  if (!nzchar(subject)) subject <- NULL
  d <- new.env(parent = emptyenv())
  d$conn <- list(token = sa_token(json_path, DRIVE_SCOPE, subject), email = info$client_email,
                 client_id = info$client_id %||% "", subject = subject, key_path = json_path)
  d$root_id  <- parse_drive_id(root_input)
  d$drive_id <- NULL
  d$folders  <- new.env(parent = emptyenv())
  d
}

parse_drive_id <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) stop("Paste the ID or link of the Google Drive folder (or shared drive) to save into.", call. = FALSE)
  for (pat in c("/folders/([A-Za-z0-9_-]{10,})", "[?&]id=([A-Za-z0-9_-]{10,})", "/d/([A-Za-z0-9_-]{10,})")) {
    m <- regmatches(x, regexec(pat, x))[[1]]
    if (length(m) == 2) return(m[2])
  }
  if (grepl("^[A-Za-z0-9_-]{10,}$", x)) return(x)
  stop("That does not look like a Google Drive folder link or ID. Open the folder in Drive and copy ",
       "the address bar (https://drive.google.com/drive/folders/...).", call. = FALSE)
}

who_drive <- function(d) {
  if (!is.null(d$conn$subject)) paste0(d$conn$subject, " (via ", d$conn$email, ")") else d$conn$email
}

# ---- Errors -----------------------------------------------------------------
drive_error <- function(status, reason, message) {
  structure(class = c("drive_error", "error", "condition"),
            list(message = message, call = NULL, status = status, reason = reason))
}

drive_explain <- function(status, parsed, raw, d) {
  msg <- reason <- NULL
  if (is.list(parsed) && is.list(parsed$error)) {
    msg <- parsed$error$message
    errs <- parsed$error$errors
    if (length(errs)) reason <- errs[[1]]$reason
    if (is.null(reason)) reason <- parsed$error$status
  }
  msg <- msg %||% substr(raw %||% "", 1, 300)
  reason <- reason %||% ""
  who <- who_drive(d)
  hint <- if (grepl("storageQuotaExceeded|quota", reason, ignore.case = TRUE) ||
              grepl("Service Accounts do not have storage quota", msg, fixed = TRUE)) {
    paste0("Service accounts have no Drive storage of their own, so they cannot own files in a normal ",
           "'My Drive' folder. Either (a) use a Shared Drive and add ", d$conn$email, " to it as Content manager, ",
           "or (b) on Google Workspace, set up domain-wide delegation and fill in 'Act as this Workspace user'.")
  } else if (grepl("accessNotConfigured|SERVICE_DISABLED|has not been used in project", paste(reason, msg))) {
    "The Google Drive API is switched off for this Cloud project. Enable it at console.cloud.google.com > APIs & Services > Library > Google Drive API, wait a minute, then retry."
  } else if (status == 404) {
    paste0("Drive cannot find that folder, or it is not shared with ", who,
           ". Share the folder (or add the account to the shared drive) and check the link.")
  } else if (grepl("insufficientFilePermissions|cannotAddChildren|insufficientPermissions", reason) || status == 403) {
    paste0(who, " can see the folder but cannot add to it. Give it Editor access (folder) or Content manager (shared drive).")
  } else if (status == 401) {
    "Google rejected the sign-in. The key may have been deleted - create a new JSON key."
  } else if (status == 429 || grepl("rateLimit", reason)) {
    "Drive is rate-limiting requests. Wait a minute and save again."
  } else ""
  drive_error(status, reason, paste0("Google Drive error ", status,
    if (nzchar(reason)) paste0(" (", reason, ")") else "", ": ", msg,
    if (nzchar(hint)) paste0("\nFix: ", hint) else ""))
}

# ---- Low-level request ------------------------------------------------------
drive_http <- function(d, method, url, query = list(), json = NULL, body = NULL, type = NULL,
                       headers = NULL, as = c("parsed", "raw", "response")) {
  as <- match.arg(as)
  query <- c(list(supportsAllDrives = "true"), query)
  cfg <- list(httr::config(token = d$conn$token), httr::timeout(180))
  if (!is.null(headers)) cfg <- c(cfg, list(do.call(httr::add_headers, as.list(headers))))
  if (!is.null(json)) {
    body <- as.character(jsonlite::toJSON(json, auto_unbox = TRUE, null = "null"))
    type <- "application/json; charset=UTF-8"
  }
  if (!is.null(type)) cfg <- c(cfg, list(httr::content_type(type)))
  resp <- tryCatch(
    do.call(httr::VERB, c(list(verb = method, url = url, query = query, body = body), cfg)),
    error = function(e) stop("Could not reach Google Drive (", conditionMessage(e), ").", call. = FALSE))
  status <- httr::status_code(resp)
  if (status >= 400) {
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- tryCatch(jsonlite::fromJSON(raw, simplifyVector = FALSE), error = function(e) NULL)
    stop(drive_explain(status, parsed, raw, d))
  }
  switch(as,
    response = resp,
    raw      = httr::content(resp, as = "raw"),
    parsed   = {
      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      if (!nzchar(txt %||% "")) list() else jsonlite::fromJSON(txt, simplifyVector = FALSE)
    })
}

q_escape <- function(x) gsub("'", "\\\\'", gsub("\\", "\\\\", x, fixed = TRUE), fixed = TRUE)

search_scope <- function(d) {
  if (!is.null(d$drive_id)) list(corpora = "drive", driveId = d$drive_id, includeItemsFromAllDrives = "true")
  else list(corpora = "allDrives", includeItemsFromAllDrives = "true")
}

# ---- Basic operations --------------------------------------------------------
drive_about <- function(d) {
  drive_http(d, "GET", paste0(DRIVE_API, "/about"),
             query = list(fields = "user(emailAddress,displayName),storageQuota(limit,usage)"))
}

# Works for folder IDs and for shared-drive IDs.
drive_get_root <- function(d) {
  f <- tryCatch(
    drive_http(d, "GET", paste0(DRIVE_API, "/files/", d$root_id),
               query = list(fields = "id,name,mimeType,driveId,webViewLink,capabilities(canAddChildren)")),
    drive_error = function(e) if (isTRUE(e$status == 404)) NULL else stop(e))
  if (!is.null(f)) {
    if (!identical(f$mimeType, FOLDER_MIME)) {
      stop("That ID is a file ('", f$name, "'), not a folder. Use the folder's link instead.", call. = FALSE)
    }
    d$drive_id <- f$driveId
    return(list(name = f$name, shared_drive = !is.null(f$driveId),
                can_add = isTRUE(f$capabilities$canAddChildren) || is.null(f$capabilities$canAddChildren),
                link = f$webViewLink %||% folder_link(d$root_id)))
  }
  sd <- drive_http(d, "GET", paste0(DRIVE_API, "/drives/", d$root_id),
                   query = list(fields = "id,name,capabilities(canAddChildren)"))
  d$drive_id <- sd$id
  list(name = sd$name, shared_drive = TRUE,
       can_add = isTRUE(sd$capabilities$canAddChildren) || is.null(sd$capabilities$canAddChildren),
       link = folder_link(sd$id))
}

folder_link <- function(id) paste0("https://drive.google.com/drive/folders/", id)

drive_find <- function(d, name, parent, folder = TRUE) {
  q <- sprintf("name = '%s' and '%s' in parents and trashed = false and mimeType %s '%s'",
               q_escape(name), parent, if (folder) "=" else "!=", FOLDER_MIME)
  res <- drive_http(d, "GET", paste0(DRIVE_API, "/files"),
                    query = c(list(q = q, orderBy = "createdTime", pageSize = "10",
                                   fields = paste0("files(", FILE_FIELDS, ")")), search_scope(d)))
  files <- res$files %||% list()
  if (length(files)) files[[1]] else NULL
}

drive_list <- function(d, parent, max = 1000) {
  out <- list(); token <- NULL
  repeat {
    res <- drive_http(d, "GET", paste0(DRIVE_API, "/files"),
      query = c(list(q = sprintf("'%s' in parents and trashed = false", parent), pageSize = "200",
                     fields = paste0("nextPageToken,files(", FILE_FIELDS, ")"), pageToken = token),
                search_scope(d)))
    out <- c(out, res$files %||% list())
    token <- res$nextPageToken
    if (is.null(token) || length(out) >= max) break
  }
  out
}

drive_create_folder <- function(d, name, parent) {
  drive_http(d, "POST", paste0(DRIVE_API, "/files"), query = list(fields = FILE_FIELDS),
             json = list(name = name, mimeType = FOLDER_MIME, parents = list(parent)))
}

drive_delete <- function(d, id) invisible(drive_http(d, "DELETE", paste0(DRIVE_API, "/files/", id)))

drive_download <- function(d, id) {
  drive_http(d, "GET", paste0(DRIVE_API, "/files/", id), query = list(alt = "media"), as = "raw")
}

# ---- Folder tree ------------------------------------------------------------
drive_ensure_folder <- function(d, name, parent) {
  key <- paste0(parent, "/", name)
  hit <- d$folders[[key]]
  if (!is.null(hit)) return(hit)
  f <- drive_find(d, name, parent, folder = TRUE)
  created <- FALSE
  if (is.null(f)) {
    f <- drive_create_folder(d, name, parent)
    created <- TRUE
    cat(sprintf("[DRIVE] Created folder '%s'\n", name))
  }
  if (created) d$created_count <- (d$created_count %||% 0) + 1
  d$folders[[key]] <- f$id
  f$id
}

# segments: c("Atera Analytics", "GA4-515710306", ...). Missing folders are created.
drive_ensure_path <- function(d, segments) {
  parent <- d$root_id
  for (s in segments) parent <- drive_ensure_folder(d, s, parent)
  list(id = parent, path = paste(segments, collapse = "/"), link = folder_link(parent))
}

drive_forget_folders <- function(d) rm(list = ls(d$folders), envir = d$folders)

# Retry once with a fresh folder lookup if a cached folder was deleted meanwhile.
with_folder_retry <- function(d, expr_fn) {
  tryCatch(expr_fn(), drive_error = function(e) {
    if (!isTRUE(e$status == 404)) stop(e)
    cat("[DRIVE] A cached folder has gone - looking the tree up again\n")
    drive_forget_folders(d)
    expr_fn()
  })
}

# ---- Uploads ----------------------------------------------------------------
multipart_body <- function(meta, bytes, mime) {
  boundary <- paste0("atera_", paste(sample(c(letters, 0:9), 24, TRUE), collapse = ""))
  head <- paste0("--", boundary, "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n",
                 jsonlite::toJSON(meta, auto_unbox = TRUE), "\r\n--", boundary,
                 "\r\nContent-Type: ", mime, "\r\n\r\n")
  list(body = c(charToRaw(enc2utf8(head)), bytes, charToRaw(paste0("\r\n--", boundary, "--"))),
       type = paste0("multipart/related; boundary=", boundary))
}

# Creates a new file in `parent`, or replaces the content of `file_id`.
drive_upload_bytes <- function(d, bytes, name, mime, parent = NULL, file_id = NULL) {
  update <- !is.null(file_id)
  url  <- if (update) paste0(DRIVE_UPLOAD, "/files/", file_id) else paste0(DRIVE_UPLOAD, "/files")
  verb <- if (update) "PATCH" else "POST"
  meta <- if (update) list(mimeType = mime) else list(name = name, mimeType = mime, parents = list(parent))
  if (length(bytes) <= MULTIPART_MAX) {
    mp <- multipart_body(meta, bytes, mime)
    return(drive_http(d, verb, url, query = list(uploadType = "multipart", fields = FILE_FIELDS),
                      body = mp$body, type = mp$type))
  }
  resp <- drive_http(d, verb, url, query = list(uploadType = "resumable"), json = meta,
                     headers = c("X-Upload-Content-Type" = mime,
                                 "X-Upload-Content-Length" = as.character(length(bytes))),
                     as = "response")
  loc <- httr::headers(resp)$location
  if (is.null(loc)) stop("Google Drive did not return an upload address.", call. = FALSE)
  drive_http(d, "PUT", loc, query = list(fields = FILE_FIELDS), body = bytes, type = mime)
}

# Overwrite `name` in `parent` if it exists, otherwise create it. Keeps the file ID stable.
drive_upsert <- function(d, bytes, name, mime, parent) {
  existing <- drive_find(d, name, parent, folder = FALSE)
  drive_upload_bytes(d, bytes, name, mime, parent = parent, file_id = existing$id)
}

# ---- Naming scheme ------------------------------------------------------------
sanitize_name <- function(x, max = 120) {
  x <- gsub("[/\\\\:*?\"<>|[:cntrl:]]", "-", as.character(x))
  x <- gsub("\\s+", " ", trimws(x))
  x <- sub("^[. ]+", "", x)
  substr(x, 1, max)
}
slugify <- function(x) {
  x <- tolower(gsub("[^A-Za-z0-9]+", "-", x))
  x <- gsub("^-+|-+$", "", x)
  if (!nzchar(x)) "chart" else substr(x, 1, 60)
}

# meta: list(app, property, group, tab, chart, mode, start, end); now: POSIXct
scheme_tokens <- function(meta, ext = "", now = Sys.time()) {
  tk <- list(app = meta$app, property = meta$property, group = meta$group, tab = meta$tab,
             chart = meta$chart, chart_slug = slugify(meta$chart), format = ext, mode = meta$mode,
             year = format(now, "%Y"), month = format(now, "%m"), day = format(now, "%d"),
             date = format(now, "%Y-%m-%d"), time = format(now, "%H%M%S"),
             stamp = format(now, "%Y%m%d-%H%M%S"),
             start = format(as.Date(meta$start)), end = format(as.Date(meta$end)),
             period = paste0(format(as.Date(meta$start)), "_to_", format(as.Date(meta$end))))
  lapply(tk, function(v) sanitize_name(v %||% ""))
}

fill_template <- function(tpl, tokens) {
  for (k in names(tokens)) tpl <- gsub(paste0("{", k, "}"), tokens[[k]], tpl, fixed = TRUE)
  tpl
}
unknown_tokens <- function(tpl) {
  found <- regmatches(tpl, gregexpr("\\{[^}]*\\}", tpl))[[1]]
  setdiff(gsub("[{}]", "", found), TEMPLATE_TOKENS)
}
resolve_folder <- function(tpl, tokens) {
  segs <- strsplit(fill_template(tpl, tokens), "/", fixed = TRUE)[[1]]
  segs <- vapply(segs, sanitize_name, character(1), USE.NAMES = FALSE)
  segs[nzchar(segs)]
}
resolve_file <- function(tpl, tokens, ext) {
  base <- sanitize_name(fill_template(tpl, tokens), 150)
  if (!nzchar(base)) base <- tokens$chart_slug
  paste0(base, ".", ext)
}
latest_file_name <- function(tokens, ext) paste0(tokens$chart_slug, ".", ext)

# Folder levels that do not depend on the chart, for pre-building the tree.
template_prefix <- function(tpl) {
  segs <- strsplit(tpl, "/", fixed = TRUE)[[1]]
  stop_at <- which(grepl("\\{(chart|chart_slug|format)\\}", segs))
  if (length(stop_at)) segs <- segs[seq_len(stop_at[1] - 1)]
  paste(segs, collapse = "/")
}

# ---- Shared catalogue (manifest.csv) ------------------------------------------
catalog_folder <- function(d, app_name) drive_ensure_path(d, c(sanitize_name(app_name), "_catalog"))

CATALOG_README <- paste(
  "Atera Analytics - saved charts",
  "",
  "manifest.csv lists every chart file the dashboard has saved here, newest last.",
  "Other apps should read manifest.csv rather than walking folders.",
  "",
  "Columns:",
  "  saved_at        when it was saved (local time, YYYY-mm-dd HH:MM:SS)",
  "  data_mode       live = real GA4 data, demo = invented demo data",
  "  property/group/tab/chart  where the chart lives in the dashboard",
  "  format          html, png, svg, pdf, gif, jpeg, webp, json (Plotly figure), csv (chart data)",
  "  file_id         Google Drive file ID - download with files.get?alt=media",
  "  folder_path     folder path below the root folder",
  "  latest_file_id  ID of the fixed 'latest' copy of this chart+format (same ID every save)",
  "  period_start/period_end/comparison  the date range shown in the chart",
  "",
  "In R: source('drive_reader.R') from the dashboard folder, then atera_catalog() / atera_latest().",
  sep = "\n")

drive_read_manifest <- function(d, app_name) {
  folder <- catalog_folder(d, app_name)
  f <- drive_find(d, "manifest.csv", folder$id, folder = FALSE)
  empty <- as.data.frame(stats::setNames(replicate(length(MANIFEST_COLS), character(0), simplify = FALSE),
                                         MANIFEST_COLS), stringsAsFactors = FALSE)
  if (is.null(f)) return(list(df = empty, file_id = NULL, folder = folder))
  txt <- rawToChar(drive_download(d, f$id))
  Encoding(txt) <- "UTF-8"
  df <- tryCatch(utils::read.csv(text = txt, colClasses = "character", check.names = FALSE,
                                 stringsAsFactors = FALSE), error = function(e) empty)
  for (c in setdiff(MANIFEST_COLS, names(df))) df[[c]] <- rep("", nrow(df))
  list(df = df, file_id = f$id, folder = folder)
}

csv_bytes <- function(df) {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  utils::write.csv(df, tmp, row.names = FALSE, fileEncoding = "UTF-8")
  readBin(tmp, "raw", file.info(tmp)$size)
}

# Creates _catalog, README.txt and an empty manifest.csv if they are missing.
drive_init_catalog <- function(d, app_name) {
  m <- drive_read_manifest(d, app_name)
  if (is.null(m$file_id)) {
    drive_upload_bytes(d, csv_bytes(m$df), "manifest.csv", "text/csv", parent = m$folder$id)
  }
  if (is.null(drive_find(d, "README.txt", m$folder$id, folder = FALSE))) {
    drive_upload_bytes(d, charToRaw(enc2utf8(CATALOG_README)), "README.txt", "text/plain", parent = m$folder$id)
  }
  m$folder
}

drive_append_manifest <- function(d, app_name, rows) {
  if (is.null(rows) || nrow(rows) == 0) return(invisible(NULL))
  m <- drive_read_manifest(d, app_name)
  for (c in setdiff(MANIFEST_COLS, names(rows))) rows[[c]] <- rep("", nrow(rows))
  rows <- rows[MANIFEST_COLS]
  rows[] <- lapply(rows, as.character)
  all <- rbind(m$df[MANIFEST_COLS], rows)
  drive_upload_bytes(d, csv_bytes(all), "manifest.csv", "text/csv",
                     parent = m$folder$id, file_id = m$file_id)
  invisible(all)
}
