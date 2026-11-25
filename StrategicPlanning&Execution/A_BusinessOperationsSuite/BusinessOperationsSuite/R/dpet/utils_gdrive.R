# R/utils_gdrive.R
# =============================================================================
# Google Drive for saved diagrams (Google Drive API v3, service account).
#
# The app writes ONLY inside one shared root folder that the user chooses
# (Settings: API Settings > Google Drive). Files are kept in a folder
# hierarchy that other R Shiny apps can read by path:
#
#   <root folder>/<Tab group>/<Tab>/<Subject>/<diagram>.<ext>
#   e.g. Business Suite/Day Planner/Visualizations/2026-11-22/time_allocation.png
#
# - Folders are created the first time they are needed and reused afterwards.
# - A file with the same name in the same folder is UPDATED in place, so the
#   path stays the same for readers (its link and id do not change either).
# - The root folder must be shared with the service-account e-mail as Editor.
#
# The service-account key is the same one BigQuery uses unless another key is
# loaded in the Google Drive settings. Keys are read only: never copied,
# written to a file, logged or shown. Only the root folder id/name and the
# "use the BigQuery key" choice are saved (bos_gdrive_settings.json, in the
# local key folder when that exists). No secrets are saved.
# =============================================================================

GDRIVE_SCOPE <- "https://www.googleapis.com/auth/drive"
GDRIVE_FOLDER_MIME <- "application/vnd.google-apps.folder"
.gdrive_cache <- new.env(parent = emptyenv())   # access token and folder ids for this R session only

# Base URL of the Google APIs. Overridable with options(bos.gdrive_base = ...) so the
# calls can be tested against a local stand-in server.
gdrive_base <- function() getOption("bos.gdrive_base", "https://www.googleapis.com")

# The key used for Drive: the BigQuery service account (default) or the Drive key loaded in settings.
gdrive_key_for <- function(api) {
  k <- if (isTRUE(api$gdrive_use_bq_key)) api$bq_key_path else api$gdrive_key_path
  if (is.null(k) || !nzchar(k %||% "")) NULL else k
}

gdrive_key_email <- function(key_path) {
  info <- jsonlite::fromJSON(key_path, simplifyVector = TRUE)
  if (!identical(info$type, "service_account") || !nzchar(info$client_email %||% "")) {
    stop("That file is not a service-account key (Google Drive needs one).", call. = FALSE)
  }
  info$client_email
}

# Access token for Drive, cached for 50 minutes per key file.
gdrive_access_token <- function(key_path) {
  fixed <- getOption("bos.gdrive_token")          # test stand-in only
  if (!is.null(fixed)) return(fixed)
  now <- as.numeric(Sys.time())
  cached <- .gdrive_cache$token
  if (!is.null(cached) && identical(cached$key, key_path) && now < cached$expires) return(cached$value)
  tok <- gargle::credentials_service_account(scopes = GDRIVE_SCOPE, path = key_path)
  if (is.null(tok)) stop("Google did not accept the service-account key for Drive.", call. = FALSE)
  val <- tok$credentials$access_token
  if (!nzchar(val %||% "")) stop("Google did not return an access token for Drive.", call. = FALSE)
  .gdrive_cache$token <- list(key = key_path, value = val, expires = now + 50 * 60)
  val
}

# One HTTP call. Every Drive call here returns JSON. Errors carry Google's own message.
gdrive_request <- function(key_path, method, url, query = list(), body = NULL, body_type = NULL) {
  token <- gdrive_access_token(key_path)
  req <- httr2::request(url)
  req <- httr2::req_method(req, method)
  req <- httr2::req_headers(req, Authorization = paste("Bearer", token), Accept = "application/json")
  req <- httr2::req_user_agent(req, "BusinessOperationsSuite-R")
  req <- httr2::req_timeout(req, 120)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  if (length(query)) req <- do.call(httr2::req_url_query, c(list(req), query))
  if (!is.null(body)) req <- httr2::req_body_raw(req, body, type = body_type)
  resp <- httr2::req_perform(req)
  status <- httr2::resp_status(resp)
  if (status >= 400) {
    msg <- tryCatch(httr2::resp_body_json(resp)$error$message, error = function(e) NULL)
    stop(sprintf("Google Drive returned HTTP %d%s", status, if (!is.null(msg)) paste0(": ", msg) else ""), call. = FALSE)
  }
  httr2::resp_body_json(resp)
}

gdrive_quote <- function(x) gsub("'", "\\\\'", as.character(x), fixed = FALSE)

# Folder and file names: no path separators or characters Drive or Windows dislike
gdrive_safe_name <- function(x, max = 120L) {
  x <- gsub("[/\\\\:*?\"<>|]", "-", as.character(x %||% ""))
  x <- trimws(gsub("\\s+", " ", x))
  if (!nzchar(x)) x <- "untitled"
  substr(x, 1L, max)
}

gdrive_list <- function(key_path, q, fields = "files(id,name,mimeType,webViewLink)", page_size = 100L) {
  r <- gdrive_request(key_path, "GET", paste0(gdrive_base(), "/drive/v3/files"),
                      query = list(q = q, fields = fields, pageSize = page_size,
                                   supportsAllDrives = "true", includeItemsFromAllDrives = "true"))
  r$files %||% list()
}

gdrive_find_child <- function(key_path, parent, name, folder = TRUE) {
  mime_cond <- if (folder) sprintf("mimeType = '%s'", GDRIVE_FOLDER_MIME) else sprintf("mimeType != '%s'", GDRIVE_FOLDER_MIME)
  q <- sprintf("name = '%s' and '%s' in parents and %s and trashed = false", gdrive_quote(name), parent, mime_cond)
  hits <- gdrive_list(key_path, q, page_size = 10L)
  if (length(hits)) hits[[1]] else NULL
}

# Id of the folder `name` under `parent`, created if it does not exist yet (cached for this session).
gdrive_folder <- function(key_path, parent, name) {
  name <- gdrive_safe_name(name)
  ck <- paste0("folder:", parent, "|", name)
  id <- .gdrive_cache[[ck]]
  if (!is.null(id)) return(id)
  hit <- gdrive_find_child(key_path, parent, name, folder = TRUE)
  if (!is.null(hit)) {
    id <- hit$id
  } else {
    meta <- as.character(jsonlite::toJSON(list(name = name, mimeType = GDRIVE_FOLDER_MIME, parents = list(parent)), auto_unbox = TRUE))
    r <- gdrive_request(key_path, "POST", paste0(gdrive_base(), "/drive/v3/files"),
                        query = list(fields = "id,name,webViewLink", supportsAllDrives = "true"),
                        body = charToRaw(meta), body_type = "application/json; charset=UTF-8")
    id <- r$id
    cat(sprintf("[Drive] created folder '%s'\n", name))
  }
  assign(ck, id, envir = .gdrive_cache)
  id
}

# Walks (and creates as needed) the folder hierarchy below the root. Returns the last folder's id.
gdrive_folder_path <- function(key_path, root_id, parts) {
  parent <- root_id
  for (p in parts) parent <- gdrive_folder(key_path, parent, p)
  parent
}

gdrive_clear_cache <- function() {
  rm(list = ls(envir = .gdrive_cache, all.names = TRUE), envir = .gdrive_cache)
  invisible(TRUE)
}

# Creates or updates one file in a folder. Returns list(id, name, link, action).
gdrive_save_file <- function(key_path, parent, filename, path, mime) {
  filename <- gdrive_safe_name(filename)
  bytes <- readBin(path, "raw", file.info(path)$size)
  hit <- gdrive_find_child(key_path, parent, filename, folder = FALSE)
  if (!is.null(hit)) {
    r <- gdrive_request(key_path, "PATCH", paste0(gdrive_base(), "/upload/drive/v3/files/", hit$id),
                        query = list(uploadType = "media", fields = "id,name,webViewLink", supportsAllDrives = "true"),
                        body = bytes, body_type = mime)
    return(list(id = r$id, name = r$name, link = r$webViewLink %||% hit$webViewLink %||% "", action = "updated"))
  }
  boundary <- paste0("bosboundary", paste(sample(c(letters, 0:9), 24, replace = TRUE), collapse = ""))
  meta <- as.character(jsonlite::toJSON(list(name = filename, parents = list(parent)), auto_unbox = TRUE))
  body <- c(charToRaw(paste0("--", boundary, "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n", meta,
                             "\r\n--", boundary, "\r\nContent-Type: ", mime, "\r\n\r\n")),
            bytes, charToRaw(paste0("\r\n--", boundary, "--")))
  r <- gdrive_request(key_path, "POST", paste0(gdrive_base(), "/upload/drive/v3/files"),
                      query = list(uploadType = "multipart", fields = "id,name,webViewLink", supportsAllDrives = "true"),
                      body = body, body_type = paste0("multipart/related; boundary=", boundary))
  list(id = r$id, name = r$name, link = r$webViewLink %||% "", action = "created")
}

# The root must exist, be a folder, and let this service account add files.
gdrive_check_root <- function(key_path, root_id) {
  r <- tryCatch(gdrive_request(key_path, "GET", paste0(gdrive_base(), "/drive/v3/files/", root_id),
                               query = list(fields = "id,name,mimeType,webViewLink,capabilities(canAddChildren)",
                                            supportsAllDrives = "true")),
                error = function(e) stop("The folder was not found, or it is not shared with the service account (",
                                         gdrive_key_email(key_path), "). Share it as Editor and try again. (",
                                         conditionMessage(e), ")", call. = FALSE))
  if (!identical(r$mimeType, GDRIVE_FOLDER_MIME)) stop("That id is a file, not a folder.", call. = FALSE)
  if (!isTRUE(r$capabilities$canAddChildren)) {
    stop("The service account can see the folder but cannot add files to it. Share it with ",
         gdrive_key_email(key_path), " as Editor.", call. = FALSE)
  }
  list(id = r$id, name = r$name, link = r$webViewLink %||% "")
}

# Folder id from a pasted link (https://drive.google.com/drive/folders/<id>) or a bare id.
gdrive_parse_root <- function(x) {
  x <- trimws(x %||% "")
  m <- regmatches(x, regexpr("folders/[A-Za-z0-9_-]+", x))
  id <- if (length(m)) sub("^folders/", "", m) else x
  if (!grepl("^[A-Za-z0-9_-]{10,}$", id)) {
    stop("Paste the folder's link or ID (open the folder in Google Drive and copy its link).", call. = FALSE)
  }
  id
}

# Connects: checks the key and the root folder, then records the connection on the API object.
gdrive_connect <- function(api, key_path, root_input) {
  if (is.null(key_path)) stop("No service-account key yet. Connect BigQuery first, or load a Drive key here.", call. = FALSE)
  root_id <- gdrive_parse_root(root_input)
  account <- gdrive_key_email(key_path)
  info <- gdrive_check_root(key_path, root_id)
  api$gdrive_root_id <- info$id
  api$gdrive_root_name <- info$name
  api$gdrive_account <- account
  api$gdrive_authenticated <- TRUE
  api$gdrive_status <- sprintf("Connected: saving to “%s”", info$name)
  gdrive_clear_cache()
  invisible(info)
}

gdrive_disconnect <- function(api) {
  api$gdrive_authenticated <- FALSE
  api$gdrive_root_id <- NULL; api$gdrive_root_name <- NULL
  api$gdrive_status <- "Not connected."
  gdrive_clear_cache()
  invisible(TRUE)
}

# The folders and files already saved under the root, for checking the layout (depth-limited, max 400 rows).
gdrive_tree <- function(key_path, root_id, depth = 3L, max_rows = 400L) {
  rows <- list(); n <- 0L
  walk <- function(parent, path, d) {
    if (d > depth || n >= max_rows) return(invisible(NULL))
    kids <- gdrive_list(key_path, sprintf("'%s' in parents and trashed = false", parent), page_size = 200L)
    for (k in kids) {
      if (n >= max_rows) break
      is_folder <- identical(k$mimeType, GDRIVE_FOLDER_MIME)
      p <- paste0(path, "/", k$name)
      n <<- n + 1L
      rows[[n]] <<- data.frame(Path = p, Type = if (is_folder) "folder" else "file",
                               Link = k$webViewLink %||% "", stringsAsFactors = FALSE)
      if (is_folder) walk(k$id, p, d + 1L)
    }
    invisible(NULL)
  }
  walk(root_id, "", 1L)
  if (!length(rows)) return(data.frame(Path = character(), Type = character(), Link = character(), stringsAsFactors = FALSE))
  do.call(rbind, rows)
}

# ---- saved settings (no secrets) ----------------------------------------------
gdrive_settings_file <- function() {
  d <- tryCatch(cred_dir(), error = function(e) "")
  if (!nzchar(d) || !dir.exists(d)) return(NULL)
  file.path(d, "bos_gdrive_settings.json")
}

gdrive_settings_save <- function(api) {
  f <- gdrive_settings_file()
  if (is.null(f)) return(invisible(FALSE))
  s <- list(root_id = api$gdrive_root_id %||% "", root_name = api$gdrive_root_name %||% "",
            use_bq_key = isTRUE(api$gdrive_use_bq_key))
  tryCatch({ writeLines(jsonlite::toJSON(s, auto_unbox = TRUE, pretty = TRUE), f, useBytes = TRUE); invisible(TRUE) },
           error = function(e) { cat("[Drive] could not save settings:", conditionMessage(e), "\n"); invisible(FALSE) })
}

gdrive_settings_read <- function() {
  f <- gdrive_settings_file()
  if (is.null(f) || !file.exists(f)) return(NULL)
  tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE), error = function(e) NULL)
}

# Start-up: reconnects with the saved root folder when a key is available (called from cred_startup).
gdrive_restore <- function(api) {
  if (isTRUE(api$gdrive_authenticated)) return(invisible(TRUE))
  s <- gdrive_settings_read()
  if (is.null(s) || !nzchar(s$root_id %||% "")) return(invisible(FALSE))
  api$gdrive_use_bq_key <- !isFALSE(s$use_bq_key)
  key <- gdrive_key_for(api)
  if (is.null(key)) return(invisible(FALSE))
  ok <- tryCatch({ gdrive_connect(api, key, s$root_id); TRUE }, error = function(e) {
    cat("[Drive] could not reconnect to the saved folder:", conditionMessage(e), "\n")
    api$gdrive_status <- "Saved folder could not be reached. Test the connection in API Settings > Google Drive."
    FALSE
  })
  if (ok) cat("[Drive] reconnected to", api$gdrive_root_name, "\n")
  invisible(ok)
}
