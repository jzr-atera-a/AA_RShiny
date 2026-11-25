# R/utils_gdrive.R
# ==================================================================================================
# GOOGLE DRIVE: save the files exported from any visualisation tab (HTML, PDF, PNG, JPEG, GIF, PPTX,
# ZIP) into one Google Drive location, in a fixed folder hierarchy that other apps can read.
#
#   <root folder>/                                  the folder (or Shared Drive) chosen in API Configuration > Google Drive
#     BooksNetworksStrategySixS/                    the app folder (name configurable)
#       _README.txt                                 how the hierarchy and the manifest work (written once)
#       _manifest.csv                               one row per saved file: path, ids, link, metadata
#       <Main group>/                               e.g. Strategic Analysis, Mind Map, Technical Designs
#         <Category>/<Domain>/<Topic>/              from the diagram's own classification ("_General" when not set)
#           <Title>/
#             <Title>__<Sub-tab>__<YYYYMMDD-HHMMSS>.<ext>
#
# Every level is created when it does not exist yet (and found again, never duplicated, when it does). Each file also
# carries Drive "appProperties" (app, group, tab, category, domain, topic, title, format, source_id, saved_at), so
# another app can search Drive directly as well as read the manifest.
#
# Sign-in, two ways (no Google package needed: httr + openssl, the JWT is signed here):
#   * service_account : a service-account JSON key (by default the same key as BigQuery). Google gives service accounts
#                       no storage of their own, so the root folder must be in a Shared Drive the account is a member of.
#   * oauth           : a Google account, with an OAuth client ID + secret and a refresh token. The token can be pasted,
#                       or obtained in the app with "Sign in with Google" (device code; client type "TVs and Limited
#                       Input devices"; that flow is limited by Google to files the app creates itself).
# Settings are auto-loaded at start-up from google_drive.json in the local key folder (same folder as the BigQuery and
# Claude keys), or from this computer's private settings file written by "Save settings". Keys are never put in the
# source code; secrets are never printed (only masked).
# ==================================================================================================

GD_SCOPE_FULL <- "https://www.googleapis.com/auth/drive"
GD_SCOPE_FILE <- "https://www.googleapis.com/auth/drive.file"
GD_TOKEN_URL <- "https://oauth2.googleapis.com/token"
GD_DEVICE_URL <- "https://oauth2.googleapis.com/device/code"
GD_API <- "https://www.googleapis.com/drive/v3"
GD_UPLOAD_API <- "https://www.googleapis.com/upload/drive/v3"
# test hook only: GDRIVE_TEST_BASE=http://127.0.0.1:port sends every call to a local stand-in server
local({ b <- Sys.getenv("GDRIVE_TEST_BASE", ""); if (nzchar(b)) {
  GD_TOKEN_URL <<- paste0(b, "/token"); GD_DEVICE_URL <<- paste0(b, "/device/code")
  GD_API <<- paste0(b, "/drive/v3"); GD_UPLOAD_API <<- paste0(b, "/upload/drive/v3") } })
GD_FOLDER_MIME <- "application/vnd.google-apps.folder"
GD_KEYS_FILE <- "google_drive.json"
GD_GENERAL <- "_General"
GD_MANIFEST <- "_manifest.csv"
GD_README <- "_README.txt"
GD_MANIFEST_COLS <- c("saved_at", "app", "main_group", "sub_tab", "category", "domain", "topic", "title", "format",
                      "file_name", "folder_path", "file_id", "folder_id", "web_link", "size_bytes", "source_id", "saved_by")

.gd <- new.env()
gd_reset <- function() {
  .gd$cfg <- list(mode = "none", sa_path = "", sa_email = "", client_id = "", client_secret = "", refresh_token = "",
                  oauth_scope = GD_SCOPE_FULL, root_id = "", app_folder = "BooksNetworksStrategySixS", manifest = TRUE, source = "")
  .gd$token <- NULL; .gd$token_exp <- 0
  .gd$folders <- new.env()
  .gd$app_folder_id <- NULL; .gd$root_info <- NULL; .gd$account <- ""
  .gd$status <- list(state = "none", msg = "Google Drive is not set up yet: API Configuration > Google Drive.")
  .gd$tick <- 0
  .gd$recent <- list()
}
if (!exists("cfg", envir = .gd)) gd_reset()

gd_cfg <- function() .gd$cfg
gd_status <- function() .gd$status
gd_ready <- function() identical(.gd$status$state, "ok")
gd_configured <- function() !identical(.gd$cfg$mode, "none")
gd_set_status <- function(state, msg) { .gd$status <- list(state = state, msg = msg, at = format(Sys.time(), "%H:%M:%S")); .gd$tick <- .gd$tick + 1; invisible() }
gd_mask <- function(x) { x <- as.character(x %||% ""); if (nchar(x) < 10) (if (nzchar(x)) "****" else "") else paste0(substr(x, 1, 4), "...", substr(x, nchar(x) - 3, nchar(x))) }

# "https://drive.google.com/drive/folders/<id>?usp=..." or a bare id -> id
gd_folder_id_from <- function(x) {
  x <- trimws(as.character(x %||% ""))
  if (!nzchar(x)) return("")
  m <- regmatches(x, regexpr("(folders/|id=)[A-Za-z0-9_-]{4,}", x))
  if (length(m)) return(sub("^(folders/|id=)", "", m))
  if (grepl("^[A-Za-z0-9_-]{4,}$", x)) x else ""
}

# Folder / file name safe for Drive AND for any app that maps the tree to a file system.
gd_safe_name <- function(x, max = 90, empty = GD_GENERAL) {
  x <- as.character(x %||% ""); if (length(x) == 0 || is.na(x[1])) x <- ""
  x <- x[1]
  if (toupper(trimws(x)) %in% c("N/A", "NA", "NULL", "NONE")) x <- ""
  x <- gsub("[[:cntrl:]]", " ", x)
  x <- gsub("\\s*[/\\\\]+\\s*", " - ", x)      # a slash would read as a sub-folder: "A/B" -> "A - B"
  x <- gsub("[:*?\"<>|]+", "", x)                  # not allowed in Windows names
  x <- gsub("\\s+", " ", trimws(x))
  x <- sub("^[. -]+", "", x); x <- sub("[. -]+$", "", x)
  if (nchar(x) > max) x <- trimws(substr(x, 1, max))
  if (!nzchar(x)) empty else x
}

# ---- configuration -------------------------------------------------------------------------------------
gd_configure <- function(mode, sa_path = NULL, client_id = NULL, client_secret = NULL, refresh_token = NULL,
                         root_id = NULL, app_folder = NULL, manifest = NULL, oauth_scope = NULL, source = "typed") {
  c0 <- .gd$cfg
  if (!mode %in% c("none", "service_account", "oauth")) stop("Unknown sign-in method: ", mode)
  c0$mode <- mode
  if (!is.null(sa_path)) c0$sa_path <- trimws(sa_path)
  if (!is.null(client_id)) c0$client_id <- trimws(client_id)
  if (!is.null(client_secret)) c0$client_secret <- trimws(client_secret)
  if (!is.null(refresh_token)) c0$refresh_token <- trimws(refresh_token)
  if (!is.null(root_id)) c0$root_id <- gd_folder_id_from(root_id)
  if (!is.null(app_folder)) c0$app_folder <- gd_safe_name(app_folder, empty = "BooksNetworksStrategySixS")
  if (!is.null(manifest)) c0$manifest <- isTRUE(manifest)
  if (!is.null(oauth_scope)) c0$oauth_scope <- oauth_scope
  c0$source <- source
  c0$sa_email <- ""
  if (identical(mode, "service_account")) {
    if (!nzchar(c0$sa_path) || !file.exists(c0$sa_path)) stop("Service-account key file not found: ", c0$sa_path)
    j <- tryCatch(jsonlite::fromJSON(c0$sa_path), error = function(e) stop("The key file is not valid JSON: ", conditionMessage(e)))
    if (!identical(j$type, "service_account") || is.null(j$private_key) || is.null(j$client_email)) stop("The key file is not a service-account key (type, private_key and client_email are needed).")
    c0$sa_email <- j$client_email
  }
  if (identical(mode, "oauth") && (!nzchar(c0$client_id) || !nzchar(c0$client_secret))) stop("An OAuth client ID and client secret are needed.")
  .gd$cfg <- c0
  .gd$token <- NULL; .gd$token_exp <- 0; .gd$folders <- new.env(); .gd$app_folder_id <- NULL; .gd$root_info <- NULL
  gd_set_status(if (identical(mode, "none")) "none" else "pending", if (identical(mode, "none")) "Google Drive is switched off." else "Settings loaded, not tested yet.")
  invisible(c0)
}

# private settings file on this computer (outside the app folder, readable only by this user)
gd_private_path <- function() file.path(tools::R_user_dir("BooksNetworksStrategySixS", "config"), GD_KEYS_FILE)

gd_settings_list <- function(c0 = .gd$cfg) {
  list(mode = c0$mode, service_account_key = c0$sa_path, client_id = c0$client_id, client_secret = c0$client_secret,
       refresh_token = c0$refresh_token, oauth_scope = c0$oauth_scope, root_folder_id = c0$root_id,
       app_folder = c0$app_folder, manifest = isTRUE(c0$manifest))
}

gd_save_private <- function(path = gd_private_path()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(jsonlite::toJSON(gd_settings_list(), auto_unbox = TRUE, pretty = TRUE), path)
  try(Sys.chmod(path, "600"), silent = TRUE)
  cat("[Google Drive] settings saved to", path, "\n")
  invisible(path)
}

# read a settings file (keys folder or private). A relative service_account_key is relative to the file's folder.
gd_load_file <- function(path, source) {
  j <- jsonlite::fromJSON(path)
  sa <- as.character(j$service_account_key %||% "")
  if (nzchar(sa) && !file.exists(sa) && file.exists(file.path(dirname(path), sa))) sa <- file.path(dirname(path), sa)
  mode <- as.character(j$mode %||% (if (nzchar(sa)) "service_account" else if (nzchar(j$refresh_token %||% "")) "oauth" else "none"))
  gd_configure(mode, sa_path = sa, client_id = j$client_id %||% "", client_secret = j$client_secret %||% "",
               refresh_token = j$refresh_token %||% "", root_id = j$root_folder_id %||% "", app_folder = j$app_folder %||% NULL,
               manifest = if (is.null(j$manifest)) TRUE else isTRUE(j$manifest), oauth_scope = j$oauth_scope %||% GD_SCOPE_FULL,
               source = source)
}

# Start-up: keys folder first, then the private settings file, then environment variables
# (GDRIVE_ROOT_FOLDER_ID + the BigQuery key). Then one quick test so the sidebar light is right.
gd_autoload <- function(api_manager = NULL, dir = app_cred_dir(), test = TRUE) {
  tried <- character(0)
  ok <- FALSE
  kf <- if (nzchar(dir)) file.path(dir, GD_KEYS_FILE) else ""
  if (nzchar(kf) && file.exists(kf)) {
    ok <- tryCatch({ gd_load_file(kf, paste("key folder", dir)); TRUE }, error = function(e) { cat("[Google Drive]", kf, "could not be used:", conditionMessage(e), "\n"); FALSE })
    tried <- c(tried, kf)
  }
  if (!ok && file.exists(gd_private_path())) {
    ok <- tryCatch({ gd_load_file(gd_private_path(), "saved settings on this computer"); TRUE }, error = function(e) { cat("[Google Drive] saved settings could not be used:", conditionMessage(e), "\n"); FALSE })
  }
  if (!ok && nzchar(Sys.getenv("GDRIVE_ROOT_FOLDER_ID"))) {
    key <- api_manager$bq_key_path %||% Sys.getenv("ATERA_BQ_KEY_FILE", Sys.getenv("GOOGLE_APPLICATION_CREDENTIALS", ""))
    if (nzchar(key) && file.exists(key)) ok <- tryCatch({ gd_configure("service_account", sa_path = key, root_id = Sys.getenv("GDRIVE_ROOT_FOLDER_ID"), source = "environment"); TRUE }, error = function(e) FALSE)
  }
  if (!ok) { cat("[Google Drive] not set up (no", GD_KEYS_FILE, "in the key folder, no saved settings)\n"); return(invisible(FALSE)) }
  cat("[Google Drive] settings loaded from", .gd$cfg$source, "- method:", .gd$cfg$mode, "\n")
  if (isTRUE(test)) tryCatch(gd_test(), error = function(e) NULL)
  invisible(TRUE)
}

# ---- tokens --------------------------------------------------------------------------------------------
gd_b64url <- function(x) {
  if (is.character(x)) x <- charToRaw(enc2utf8(x))
  s <- openssl::base64_encode(x)
  chartr("+/", "-_", gsub("=+$", "", s))
}

gd_token_post <- function(body) {
  r <- httr::POST(GD_TOKEN_URL, body = body, encode = "form", httr::timeout(30))
  j <- tryCatch(jsonlite::fromJSON(httr::content(r, as = "text", encoding = "UTF-8")), error = function(e) list())
  if (httr::status_code(r) >= 400) stop("Google sign-in refused (", httr::status_code(r), "): ", j$error_description %||% j$error %||% "no detail")
  j
}

gd_fetch_token <- function() {
  c0 <- .gd$cfg
  if (identical(c0$mode, "service_account")) {
    j <- jsonlite::fromJSON(c0$sa_path)
    now <- as.integer(Sys.time())
    claims <- jsonlite::toJSON(list(iss = j$client_email, scope = GD_SCOPE_FULL, aud = GD_TOKEN_URL, iat = now - 30, exp = now + 3300), auto_unbox = TRUE)
    unsigned <- paste0(gd_b64url('{"alg":"RS256","typ":"JWT"}'), ".", gd_b64url(as.character(claims)))
    key <- openssl::read_key(j$private_key)
    sig <- openssl::signature_create(charToRaw(unsigned), hash = openssl::sha256, key = key)
    t <- gd_token_post(list(grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion = paste0(unsigned, ".", gd_b64url(sig))))
    .gd$account <- j$client_email
  } else if (identical(c0$mode, "oauth")) {
    if (!nzchar(c0$refresh_token)) stop("No refresh token yet: use 'Sign in with Google' or paste a refresh token.")
    t <- gd_token_post(list(grant_type = "refresh_token", refresh_token = c0$refresh_token, client_id = c0$client_id, client_secret = c0$client_secret))
  } else stop("Google Drive is not set up: API Configuration > Google Drive.")
  .gd$token <- t$access_token
  .gd$token_exp <- as.numeric(Sys.time()) + as.numeric(t$expires_in %||% 3600) - 120
  invisible(.gd$token)
}
gd_token <- function() {
  if (is.null(.gd$token) || as.numeric(Sys.time()) > .gd$token_exp) gd_fetch_token()
  .gd$token
}

# Device-code sign-in (OAuth client type "TVs and Limited Input devices"). Step 1: get a code to show the user.
gd_device_start <- function(client_id, scope = GD_SCOPE_FILE) {
  r <- httr::POST(GD_DEVICE_URL, body = list(client_id = client_id, scope = scope), encode = "form", httr::timeout(30))
  j <- tryCatch(jsonlite::fromJSON(httr::content(r, as = "text", encoding = "UTF-8")), error = function(e) list())
  if (httr::status_code(r) >= 400) stop("Google refused the sign-in request (", httr::status_code(r), "): ", j$error_description %||% j$error %||% "no detail",
                                         ". The OAuth client must be of type 'TVs and Limited Input devices'.")
  j$started <- as.numeric(Sys.time()); j$scope <- scope
  j
}
# Step 2 (repeated every `interval` seconds): has the user approved it yet?
gd_device_poll <- function(client_id, client_secret, device_code) {
  r <- httr::POST(GD_TOKEN_URL, body = list(client_id = client_id, client_secret = client_secret, device_code = device_code,
                                            grant_type = "urn:ietf:params:oauth:grant-type:device_code"), encode = "form", httr::timeout(30))
  j <- tryCatch(jsonlite::fromJSON(httr::content(r, as = "text", encoding = "UTF-8")), error = function(e) list())
  if (httr::status_code(r) < 400 && !is.null(j$refresh_token)) return(list(status = "ok", token = j))
  e <- j$error %||% "error"
  if (e %in% c("authorization_pending", "slow_down")) return(list(status = "pending", slow = identical(e, "slow_down")))
  list(status = "error", msg = j$error_description %||% e)
}

# ---- REST calls ----------------------------------------------------------------------------------------
gd_err_text <- function(r) {
  txt <- httr::content(r, as = "text", encoding = "UTF-8")
  j <- tryCatch(jsonlite::fromJSON(txt), error = function(e) NULL)
  msg <- if (is.list(j) && is.list(j$error)) j$error$message %||% "" else substr(txt %||% "", 1, 300)
  reason <- tryCatch(j$error$errors$reason[1], error = function(e) NULL) %||% ""
  hint <- if (grepl("storageQuotaExceeded|do not have storage quota", paste(msg, reason), ignore.case = TRUE))
    " Service accounts have no Drive storage of their own: put the root folder in a Shared Drive (add the service account as a member with the Content manager role), or sign in with a Google account instead." else
    if (httr::status_code(r) == 404) " The folder or file was not found, or this account cannot see it: share the root folder with the account shown in API Configuration > Google Drive." else
    if (httr::status_code(r) == 403 && grepl("insufficient|scope", msg, ignore.case = TRUE)) " The sign-in does not allow this: a device-code sign-in only reaches files and folders the app created itself; leave the root folder empty to let the app create one, or use a refresh token with full Drive access." else ""
  sprintf("Google Drive error %d: %s%s", httr::status_code(r), msg, hint)
}

gd_call <- function(method, url, query = list(), json = NULL, raw = NULL, content_type = NULL, headers = character(0), parse = TRUE, retry = TRUE) {
  hdr <- c(Authorization = paste("Bearer", gd_token()), headers)
  if (!is.null(content_type)) hdr <- c(hdr, `Content-Type` = content_type)
  body <- if (!is.null(json)) jsonlite::toJSON(json, auto_unbox = TRUE, null = "null") else raw
  if (!is.null(json) && is.null(content_type)) hdr <- c(hdr, `Content-Type` = "application/json; charset=UTF-8")
  r <- httr::VERB(method, url, query = query, body = body, httr::add_headers(.headers = hdr), httr::timeout(120))
  if (httr::status_code(r) == 401 && retry) { .gd$token <- NULL; return(gd_call(method, url, query, json, raw, content_type, headers, parse, retry = FALSE)) }
  if (httr::status_code(r) >= 400) stop(gd_err_text(r))
  if (!parse) return(r)
  txt <- httr::content(r, as = "text", encoding = "UTF-8")
  if (!nzchar(txt %||% "")) list() else jsonlite::fromJSON(txt, simplifyVector = TRUE)
}

gd_q <- function(x) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", x))
GD_ALL <- list(supportsAllDrives = "true")

gd_get_meta <- function(id, fields = "id,name,mimeType,driveId,webViewLink,parents,trashed,capabilities(canAddChildren)") {
  gd_call("GET", paste0(GD_API, "/files/", id), query = c(GD_ALL, fields = fields))
}

gd_find_child <- function(parent, name, folder = TRUE) {
  q <- sprintf("name = '%s' and '%s' in parents and trashed = false%s", gd_q(name), parent,
               if (folder) sprintf(" and mimeType = '%s'", GD_FOLDER_MIME) else sprintf(" and mimeType != '%s'", GD_FOLDER_MIME))
  r <- gd_call("GET", paste0(GD_API, "/files"), query = c(GD_ALL, includeItemsFromAllDrives = "true", corpora = "allDrives",
                                                         q = q, fields = "files(id,name,webViewLink,createdTime)", orderBy = "createdTime", pageSize = 10))
  f <- r$files
  if (is.null(f) || length(f) == 0 || NROW(f) == 0) NULL else list(id = f$id[1], name = f$name[1], webViewLink = f$webViewLink[1])
}

gd_create_folder <- function(parent, name) {
  r <- gd_call("POST", paste0(GD_API, "/files"), query = c(GD_ALL, fields = "id,name,webViewLink"),
               json = list(name = name, mimeType = GD_FOLDER_MIME, parents = list(parent),
                           appProperties = list(app = "BooksNetworksStrategySixS", kind = "folder")))
  cat("[Google Drive] created folder", name, "\n")
  list(id = r$id, name = r$name, webViewLink = r$webViewLink)
}

# find-or-create, cached per parent + name (cleared when the settings change)
gd_folder <- function(parent, name) {
  key <- paste(parent, name, sep = "\u001f")
  hit <- get0(key, envir = .gd$folders, inherits = FALSE)
  if (!is.null(hit)) return(hit)
  f <- gd_find_child(parent, name, folder = TRUE)
  if (is.null(f)) f <- gd_create_folder(parent, name)
  assign(key, f$id, envir = .gd$folders)
  f$id
}
gd_ensure_path <- function(parent, segments) { for (s in segments) parent <- gd_folder(parent, s); parent }

# the app folder inside the root folder (or in My Drive when no root is set and the sign-in is a Google account)
gd_app_folder <- function() {
  if (!is.null(.gd$app_folder_id)) return(.gd$app_folder_id)
  c0 <- .gd$cfg
  parent <- if (nzchar(c0$root_id)) c0$root_id else if (identical(c0$mode, "oauth")) "root" else
    stop("A service account needs a root folder: paste the ID or link of a folder in a Shared Drive in API Configuration > Google Drive.")
  existed <- !is.null(gd_find_child(parent, c0$app_folder, folder = TRUE))
  id <- gd_folder(parent, c0$app_folder)
  .gd$app_folder_id <- id
  if (!existed || is.null(gd_find_child(id, GD_README, folder = FALSE))) tryCatch(gd_upload(id, GD_README, charToRaw(enc2utf8(gd_readme_text())), "text/plain"), error = function(e) cat("[Google Drive] README not written:", conditionMessage(e), "\n"))
  id
}

# resumable upload (works for any size); returns id, name, webViewLink, size
gd_upload <- function(parent, name, bytes, mime, app_properties = NULL, description = NULL) {
  meta <- list(name = name, parents = list(parent), mimeType = mime)
  if (!is.null(app_properties)) meta$appProperties <- lapply(app_properties, function(v) substr(as.character(v %||% ""), 1, 100))
  if (!is.null(description)) meta$description <- description
  r <- gd_call("POST", paste0(GD_UPLOAD_API, "/files"), query = c(GD_ALL, uploadType = "resumable", fields = "id,name,webViewLink,size"),
               json = meta, headers = c(`X-Upload-Content-Type` = mime, `X-Upload-Content-Length` = as.character(length(bytes))), parse = FALSE)
  loc <- httr::headers(r)$location
  if (is.null(loc)) stop("Google Drive did not start the upload (no upload address returned).")
  r2 <- httr::PUT(loc, body = bytes, httr::add_headers(`Content-Type` = mime), httr::timeout(300))
  if (httr::status_code(r2) >= 400) stop(gd_err_text(r2))
  jsonlite::fromJSON(httr::content(r2, as = "text", encoding = "UTF-8"))
}

gd_update_content <- function(id, bytes, mime) {
  gd_call("PATCH", paste0(GD_UPLOAD_API, "/files/", id), query = c(GD_ALL, uploadType = "media", fields = "id"), raw = bytes, content_type = mime)
}
gd_download <- function(id) {
  r <- gd_call("GET", paste0(GD_API, "/files/", id), query = c(GD_ALL, alt = "media"), parse = FALSE)
  httr::content(r, as = "raw")
}

# ---- manifest ----------------------------------------------------------------------------------------------
gd_manifest_append <- function(app_id, row) {
  row <- as.data.frame(lapply(row[GD_MANIFEST_COLS], function(v) as.character(v %||% "")), stringsAsFactors = FALSE)
  names(row) <- GD_MANIFEST_COLS
  f <- gd_find_child(app_id, GD_MANIFEST, folder = FALSE)
  old <- NULL
  if (!is.null(f)) old <- tryCatch(utils::read.csv(text = rawToChar(gd_download(f$id)), stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE),
                                   error = function(e) { cat("[Google Drive] manifest unreadable, starting a new one:", conditionMessage(e), "\n"); NULL })
  if (!is.null(old)) { for (cc in setdiff(GD_MANIFEST_COLS, names(old))) old[[cc]] <- ""; old <- old[, GD_MANIFEST_COLS, drop = FALSE] }
  all <- rbind(old, row)
  con <- textConnection("csv_out", "w", local = TRUE); utils::write.csv(all, con, row.names = FALSE, fileEncoding = "UTF-8"); close(con)
  bytes <- charToRaw(enc2utf8(paste(csv_out, collapse = "\n")))
  if (is.null(f)) gd_upload(app_id, GD_MANIFEST, bytes, "text/csv") else gd_update_content(f$id, bytes, "text/csv")
  invisible(nrow(all))
}
gd_manifest_read <- function() {
  app_id <- gd_app_folder()
  f <- gd_find_child(app_id, GD_MANIFEST, folder = FALSE)
  if (is.null(f)) return(data.frame())
  utils::read.csv(text = rawToChar(gd_download(f$id)), stringsAsFactors = FALSE, colClasses = "character", check.names = FALSE)
}

gd_readme_text <- function() paste(c(
  "Files saved by the BooksNetworksStrategySixS app (Save to Google Drive on any visualisation tab).",
  "",
  "Folder hierarchy (every level is created automatically):",
  sprintf("  %s/", .gd$cfg$app_folder),
  "    _manifest.csv            one row per saved file (see the columns below)",
  "    <Main group>/            Book Summary, Flex Table, Mind Map, Knowledge Graph, Sankey Graph, Strategic Analysis, Six Sigma Analysis, Technical Designs",
  "      <Category>/<Domain>/<Topic>/   the diagram's classification; '_General' when a level is not set",
  "        <Title>/",
  "          <Title>__<Sub-tab>__<YYYYMMDD-HHMMSS>.<ext>   ext = html, pdf, png, jpg, gif, pptx or zip",
  "",
  paste0("Manifest columns: ", paste(GD_MANIFEST_COLS, collapse = ", ")),
  "Each file also has Drive appProperties: app, group, tab, category, domain, topic, title, format, source_id, saved_at.",
  "Example query for another app: appProperties has { key='group' and value='Strategic Analysis' }",
  "Names are cleaned so they are valid folder names on Windows, macOS and Linux: / \\ : * ? \" < > | become '-'."
), collapse = "\n")

# ---- save one exported file ------------------------------------------------------------------------------
GD_MIME <- c(html = "text/html", pdf = "application/pdf", png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg", gif = "image/gif",
             pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation", zip = "application/zip",
             svg = "image/svg+xml", csv = "text/csv", txt = "text/plain", json = "application/json")

# meta: group, tab, category, domain, topic, title, source_id, file_name (original name with extension)
gd_save_export <- function(bytes, meta, saved_by = "") {
  if (!gd_configured()) stop("Google Drive is not set up: API Configuration > Google Drive.")
  ext <- tolower(sub("^.*\\.", "", meta$file_name %||% "file.bin"))
  if (identical(ext, "jpeg")) ext <- "jpg"
  mime <- unname(GD_MIME[ext]); if (is.na(mime)) mime <- "application/octet-stream"
  group <- gd_safe_name(meta$group, empty = "Other")
  seg <- c(group, gd_safe_name(meta$category), gd_safe_name(meta$domain), gd_safe_name(meta$topic), gd_safe_name(meta$title, empty = "Untitled"))
  stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
  fname <- sprintf("%s__%s__%s.%s", gd_safe_name(meta$title, 60, "Untitled"), gd_safe_name(meta$tab, 60, "Export"), stamp, ext)
  app_id <- gd_app_folder()
  folder_id <- gd_ensure_path(app_id, seg)
  props <- list(app = "BooksNetworksStrategySixS", group = group, tab = meta$tab %||% "", category = seg[2], domain = seg[3], topic = seg[4],
                title = meta$title %||% "", format = ext, source_id = meta$source_id %||% "", saved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"))
  f <- gd_upload(folder_id, fname, bytes, mime, app_properties = props,
                 description = sprintf("%s > %s. Saved from the %s tab on %s.", group, paste(seg[-1], collapse = " > "), meta$tab %||% "", format(Sys.time(), "%Y-%m-%d %H:%M")))
  folder_path <- paste(c(.gd$cfg$app_folder, seg), collapse = "/")
  if (isTRUE(.gd$cfg$manifest)) tryCatch(gd_manifest_append(app_id, list(
    saved_at = props$saved_at, app = props$app, main_group = group, sub_tab = meta$tab %||% "", category = seg[2], domain = seg[3], topic = seg[4],
    title = meta$title %||% "", format = ext, file_name = fname, folder_path = folder_path, file_id = f$id, folder_id = folder_id,
    web_link = f$webViewLink %||% "", size_bytes = length(bytes), source_id = meta$source_id %||% "", saved_by = saved_by)),
    error = function(e) cat("[Google Drive] file saved but the manifest was not updated:", conditionMessage(e), "\n"))
  out <- list(id = f$id, name = fname, link = f$webViewLink %||% "", path = paste0(folder_path, "/", fname), size = length(bytes))
  .gd$recent <- c(list(c(out, list(at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), group = group, format = ext))), head(.gd$recent, 19))
  gd_set_status("ok", sprintf("Connected. Last saved: %s", out$path))
  cat(sprintf("[Google Drive] saved %s (%s bytes)\n", out$path, format(length(bytes), big.mark = ",")))
  out
}

# Check sign-in, the root folder and the app folder. Returns a short text; sets the status.
gd_test <- function() {
  tryCatch({
    c0 <- .gd$cfg
    if (!gd_configured()) stop("Google Drive is not set up.")
    .gd$token <- NULL
    gd_token()
    who <- tryCatch(gd_call("GET", paste0(GD_API, "/about"), query = list(fields = "user(emailAddress,displayName)"))$user$emailAddress, error = function(e) NULL)
    if (!is.null(who)) .gd$account <- who
    root_txt <- ""
    if (nzchar(c0$root_id)) {
      m <- gd_get_meta(c0$root_id)
      if (!identical(m$mimeType, GD_FOLDER_MIME)) stop("The root ID is not a folder.")
      .gd$root_info <- m
      root_txt <- sprintf("root folder '%s'%s", m$name, if (!is.null(m$driveId)) " (in a Shared Drive)" else " (in My Drive)")
      if (identical(c0$mode, "service_account") && is.null(m$driveId))
        root_txt <- paste0(root_txt, ". Warning: a service account cannot store files in My Drive - uploads will be refused unless this folder is in a Shared Drive")
    } else root_txt <- "no root folder set: the app folder is created in My Drive"
    gd_app_folder()
    msg <- sprintf("Connected as %s; %s; app folder '%s' ready.", .gd$account %||% "?", root_txt, c0$app_folder)
    gd_set_status(if (grepl("Warning", root_txt)) "warn" else "ok", msg)
    msg
  }, error = function(e) { gd_set_status("error", conditionMessage(e)); stop(e) })
}

gd_app_folder_link <- function() {
  if (is.null(.gd$app_folder_id)) return("")
  paste0("https://drive.google.com/drive/folders/", .gd$app_folder_id)
}

# ---- where a visualisation tab sits in the app: main group label and sub-tab label ------------------------
.gd$tab_ctx <- NULL
gd_tab_context <- function(tab_id) {
  if (is.null(.gd$tab_ctx)) {
    reg <- tryCatch(yaml::read_yaml("modules/_module_registry.yml"), error = function(e) list())
    grp_of <- list()
    for (g in reg$groups %||% list()) for (m in unlist(g$modules)) grp_of[[m]] <- g$label
    lab_of <- list()
    if (exists("TD_HUBS")) for (h in names(TD_HUBS)) for (ch in TD_HUBS[[h]]$children) lab_of[[ch$id]] <- ch$label
    .gd$tab_ctx <- list(grp_of = grp_of, lab_of = lab_of)
  }
  ctx <- .gd$tab_ctx
  hub <- if (exists("TD_HUB_OF") && tab_id %in% names(TD_HUB_OF)) unname(TD_HUB_OF[tab_id]) else tab_id
  group <- ctx$grp_of[[hub]] %||% ctx$grp_of[[tab_id]] %||% "Other"
  hub_title <- if (exists("TD_HUBS") && !is.null(TD_HUBS[[hub]])) TD_HUBS[[hub]]$label else NULL
  tab <- ctx$lab_of[[tab_id]] %||% gsub("_", " ", tab_id)
  list(group = group, tab = if (!is.null(hub_title) && !identical(hub, tab_id) && !identical(hub_title, group)) paste(hub_title, "-", tab) else tab)
}

# Classification of what is drawn, from whatever the tab has: a data frame of rows (category/domain/topic or
# genre/author/topic columns), a Technical Design / matrix / infographic object (d$meta), or a list.
gd_meta_of <- function(x) {
  pick <- function(v) { v <- as.character(v %||% ""); v <- v[!is.na(v) & nzchar(trimws(v)) & !toupper(trimws(v)) %in% c("N/A", "NA")]; if (length(v)) trimws(v[1]) else "" }
  if (is.null(x)) return(list())
  if (is.data.frame(x)) {
    if (nrow(x) == 0) return(list())
    has <- function(n) n %in% names(x)
    if (has("book_name")) return(list(category = pick(x$genre), domain = pick(x$author), topic = pick(x$topic), source_id = pick(x$book_name)))
    return(list(category = if (has("category")) pick(x$category) else "", domain = if (has("domain")) pick(x$domain) else "",
                topic = if (has("topic")) pick(x$topic) else "",
                source_id = pick(c(if (has("diagram_id")) x$diagram_id, if (has("sankey_id")) x$sankey_id, if (has("map_id")) x$map_id,
                                   if (has("graph_id")) x$graph_id, if (has("table_id")) x$table_id))))
  }
  if (is.list(x) && is.list(x$meta)) {
    m <- x$meta
    grp <- pick(m$design_group)
    cat_lab <- if (nzchar(grp) && exists("TD_GROUP_LABELS") && grp %in% names(TD_GROUP_LABELS)) TD_GROUP_LABELS[[grp]] else grp
    if (!nzchar(cat_lab) && !is.null(m$format)) cat_lab <- "Infographics"
    if (!nzchar(cat_lab) && (!is.null(m$row_title) || !is.null(m$col_title))) cat_lab <- "Market Matrix"
    typ <- pick(m$design_type)
    if (nzchar(grp) && nzchar(typ) && exists("TD_CATALOG")) typ <- TD_CATALOG[[grp]][[typ]]$label %||% typ
    return(list(category = cat_lab, domain = pick(c(typ, m$topic, m$format)), topic = pick(m$variant),
                source_id = pick(c(m$design_id, m$id))))
  }
  if (is.list(x)) return(list(category = pick(x$category), domain = pick(x$domain), topic = pick(x$topic), source_id = pick(x$source_id)))
  list()
}

# data-* attributes added to every export target (read by www/js/gdrive_export.js)
gd_target_attrs <- function(ns, meta = NULL) {
  tab_id <- sub("-.*$", "", ns(""))
  ctx <- gd_tab_context(tab_id)
  m <- gd_meta_of(meta)
  list(`data-drive-group` = ctx$group, `data-drive-tab` = ctx$tab, `data-drive-category` = m$category %||% "",
       `data-drive-domain` = m$domain %||% "", `data-drive-topic` = m$topic %||% "", `data-drive-source` = m$source_id %||% "")
}

# "Save to Google Drive" button next to each Download button (kind = "diagram" or "infographic")
gd_save_button <- function(kind, target_id, format_select_id, default_filename) {
  tags$button(type = "button", class = "btn btn-primary gdrive-save-btn gdrive-off",
              title = "Save this file into the Google Drive folder hierarchy (set up in API Configuration > Google Drive)",
              onclick = sprintf("window.saveToDrive('%s', '%s', '%s', '%s')", kind, target_id, format_select_id, default_filename),
              icon("google-drive"), " Save to Google Drive")
}

# ---- the hidden upload input + server hooks (app.R) --------------------------------------------------------
gd_page_ui <- function() {
  tags$div(id = "gdrive_upload_dock", style = "position:absolute; left:-10000px; width:1px; height:1px; overflow:hidden;",
           fileInput("gdrive_upload", NULL, multiple = FALSE))
}

gd_server_hooks <- function(input, output, session, api_manager) {
  pending <- new.env()
  observeEvent(input$gdrive_meta, { m <- input$gdrive_meta; if (!is.null(m$nonce)) assign(m$nonce, m, envir = pending) })
  # tell the page whether Drive is ready, so the Save button can warn before building a large file
  last <- reactiveVal(-1)
  observe({
    invalidateLater(3000)
    if (!identical(last(), .gd$tick)) {
      last(.gd$tick)
      session$sendCustomMessage("gdrive_status", list(configured = gd_configured(), state = .gd$status$state, msg = .gd$status$msg))
    }
  })
  observeEvent(input$gdrive_upload, {
    f <- input$gdrive_upload
    for (i in seq_len(nrow(f))) {
      nm <- f$name[i]
      nonce <- if (grepl("^[A-Za-z0-9]+__", nm)) sub("__.*$", "", nm) else ""
      orig <- sub("^[A-Za-z0-9]+__", "", nm)
      meta <- get0(nonce, envir = pending, inherits = FALSE) %||% list()
      if (nzchar(nonce) && exists(nonce, envir = pending, inherits = FALSE)) rm(list = nonce, envir = pending)
      meta$file_name <- orig
      bytes <- readBin(f$datapath[i], "raw", n = file.info(f$datapath[i])$size)
      unlink(f$datapath[i])
      id <- showNotification(sprintf("Saving %s to Google Drive ...", orig), duration = NULL, type = "message")
      res <- tryCatch(gd_save_export(bytes, meta, saved_by = .gd$account %||% ""), error = function(e) e)
      removeNotification(id)
      if (inherits(res, "error")) {
        gd_set_status("error", conditionMessage(res))
        cat("[Google Drive] save failed:", conditionMessage(res), "\n")
        showNotification(paste("Not saved to Google Drive:", conditionMessage(res)), type = "error", duration = 20)
      } else {
        showNotification(tagList(tags$b("Saved to Google Drive: "), res$path, " ",
                                 if (nzchar(res$link)) tags$a(href = res$link, target = "_blank", rel = "noopener", "open")),
                         type = "message", duration = 12)
      }
    }
  })
}
