# R/utils_gdrive.R
# Google Drive v3 over REST (httr + openssl + jsonlite - no extra packages): sign-in, a folder tree that is
# created as needed, uploads, and a shared manifest so other apps can find every saved diagram.
#
# Folder scheme (each level is created when missing and reused when it exists):
#   <root>/<app folder>/<Group>/<Section>/<Tab>/<YYYY>/<YYYY-MM>/[<format>/]<tab_id>_<diagram>_<YYYYMMDD_HHMMSS>.<ext>
#   <root>/<app folder>/_manifest.csv   one row per uploaded file (appended on every save)
#   <root>/<app folder>/_README.txt     describes the scheme
# Every file also carries appProperties: bos_group, bos_section, bos_tab, bos_tab_id, bos_diagram, bos_format,
# bos_created_utc - e.g. googledrive::drive_find(q = "appProperties has { key='bos_tab_id' and value='analytics' }")
#
# Settings are the "google_drive" section of bos_config.json in the keys folder (the same file and keys as the
# Android app), so one config works for both.

GD_FOLDER_MIME <- "application/vnd.google-apps.folder"
GD_SCOPE_FULL <- "https://www.googleapis.com/auth/drive"
GD_SCOPE_FILE <- "https://www.googleapis.com/auth/drive.file"
GD_MANIFEST <- "_manifest.csv"
GD_README <- "_README.txt"
GD_MANIFEST_COLS <- c("created_utc", "group", "section", "tab", "tab_id", "diagram", "format", "file_name", "folder_path",
                      "file_id", "web_view_link", "size_bytes", "mime_type", "device_note")

# endpoints (overridable for tests with options(bos.gdrive.api = ..., ...))
gd_api        <- function() getOption("bos.gdrive.api", "https://www.googleapis.com/drive/v3")
gd_upload_api <- function() getOption("bos.gdrive.upload", "https://www.googleapis.com/upload/drive/v3")
gd_token_url  <- function() getOption("bos.gdrive.token", "https://oauth2.googleapis.com/token")
gd_device_url <- function() getOption("bos.gdrive.device", "https://oauth2.googleapis.com/device/code")

`%|g|%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

# ------------------------------------------------------------------ settings

gd_settings_default <- function() list(
  auth_mode = "oauth",            # "oauth" (a Google account) or "service_account"
  client_id = "", client_secret = "", refresh_token = "", account_email = "",
  key_file = "",                  # service-account key just for Drive; "" = the keys-folder BigQuery key
  impersonate = "",               # Workspace domain-wide delegation (optional)
  root_folder = "",               # folder id or link; "" = My Drive
  app_folder = "BusinessOpsSuite",
  by_date = TRUE, by_format = FALSE, manifest = TRUE,
  default_formats = c("html", "pdf", "png"),
  device_note = ""
)

# Where the settings live: <keys folder>/bos_config.json, else the user's config folder.
gd_config_path <- function() {
  d <- if (exists("cred_dir", mode = "function")) cred_dir() else ""
  if (!nzchar(d)) d <- tools::R_user_dir("BusinessOpsSuite", "config")
  file.path(d, "bos_config.json")
}

gd_read_config <- function(path = gd_config_path()) {
  if (!file.exists(path)) return(list())
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) list())
}

gd_load_settings <- function(path = gd_config_path()) {
  s <- gd_settings_default()
  j <- gd_read_config(path)$google_drive
  if (is.list(j)) for (k in intersect(names(j), names(s))) {
    v <- j[[k]]
    s[[k]] <- if (k == "default_formats") unlist(v) %|g|% character(0)
              else if (is.logical(s[[k]])) isTRUE(as.logical(v))
              else as.character(v %|g|% "")
  }
  s
}

# Writes the "google_drive" section, keeping everything else in bos_config.json.
gd_save_settings <- function(s, path = gd_config_path()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  cfg <- gd_read_config(path)
  s$default_formats <- I(as.character(s$default_formats))
  cfg$google_drive <- s
  writeLines(jsonlite::toJSON(cfg, auto_unbox = TRUE, pretty = TRUE, null = "null"), path, useBytes = TRUE)
  invisible(path)
}

gd_configured <- function(s, sa_path = NA) {
  if (identical(s$auth_mode, "oauth")) nzchar(s$client_id) && nzchar(s$refresh_token)
  else nzchar(s$key_file) || (!is.na(sa_path) && nzchar(sa_path))
}

# ------------------------------------------------------------------ names and placement

# Folder id from an id or any Drive folder link.
gd_folder_id <- function(x) {
  x <- trimws(x %|g|% "")
  if (!nzchar(x)) return("")
  m <- regmatches(x, regexec("/folders/([A-Za-z0-9_-]{10,})", x))[[1]]
  if (length(m) == 0) m <- regmatches(x, regexec("[?&]id=([A-Za-z0-9_-]{10,})", x))[[1]]
  if (length(m) == 2) return(m[2])
  if (grepl("^[A-Za-z0-9_-]+$", x)) x else ""
}

gd_safe_name <- function(x, max = 80) {
  x <- gsub("[\\\\/:*?\"<>|[:cntrl:]]", " ", x %|g|% "")
  x <- trimws(gsub("\\s+", " ", x))
  x <- trimws(sub("^\\.+", "", x))
  if (nchar(x) > max) x <- trimws(substr(x, 1, max))
  if (!nzchar(x)) "unnamed" else x
}

gd_slug <- function(x, max = 48) {
  x <- gsub("^_+|_+$", "", gsub("[^a-z0-9]+", "_", tolower(x %|g|% "")))
  if (nchar(x) > max) x <- sub("_+$", "", substr(x, 1, max))
  if (!nzchar(x)) "diagram" else x
}

gd_placement <- function(group, section, tab, tab_id, diagram, at = Sys.time())
  list(group = group, section = section %|g|% "", tab = tab, tab_id = tab_id, diagram = diagram, at = at)

gd_folders <- function(p, s, fmt) {
  c(if (nzchar(trimws(s$app_folder))) gd_safe_name(s$app_folder),
    gd_safe_name(p$group),
    if (nzchar(trimws(p$section)) && trimws(p$section) != trimws(p$group)) gd_safe_name(p$section),
    gd_safe_name(p$tab),
    if (isTRUE(s$by_date)) format(p$at, "%Y"),
    if (isTRUE(s$by_date)) format(p$at, "%Y-%m"),
    if (isTRUE(s$by_format)) tolower(fmt))
}

gd_file_name <- function(p, fmt)
  paste0(gd_slug(p$tab_id, 32), "_", gd_slug(p$diagram), "_", format(p$at, "%Y%m%d_%H%M%S"), ".", tolower(fmt))

gd_properties <- function(p, fmt) {
  v <- list(bos_group = p$group, bos_section = p$section, bos_tab = p$tab, bos_tab_id = p$tab_id, bos_diagram = p$diagram,
            bos_format = tolower(fmt), bos_created_utc = format(as.POSIXct(p$at), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  # Drive allows 124 bytes for key + value
  for (k in names(v)) { x <- enc2utf8(as.character(v[[k]])); while (nchar(k, "bytes") + nchar(x, "bytes") > 124) x <- substr(x, 1, nchar(x) - 1); v[[k]] <- x }
  v
}

GD_MIMES <- c(html = "text/html", htm = "text/html", pdf = "application/pdf", png = "image/png", jpg = "image/jpeg",
              jpeg = "image/jpeg", gif = "image/gif", tif = "image/tiff", tiff = "image/tiff", svg = "image/svg+xml",
              csv = "text/csv", json = "application/json", txt = "text/plain", mmd = "text/plain", webp = "image/webp")
gd_mime <- function(ext) unname(GD_MIMES[tolower(ext)] %|g|% "application/octet-stream") %|g|% "application/octet-stream"

gd_csv_line <- function(cells) {
  cells <- as.character(cells); cells[is.na(cells)] <- ""
  q <- grepl("[\",\r\n]", cells)
  cells[q] <- paste0("\"", gsub("\"", "\"\"", cells[q]), "\"")
  paste(cells, collapse = ",")
}

gd_manifest_row <- function(p, fmt, f, note = "")
  c(format(as.POSIXct(p$at), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), p$group, p$section, p$tab, p$tab_id, p$diagram, tolower(fmt),
    f$name, f$path, f$id, f$link %|g|% "", as.character(f$size %|g|% 0), f$mime %|g|% "", note)

gd_readme <- function(s) {
  app <- if (nzchar(trimws(s$app_folder))) paste0(gd_safe_name(s$app_folder), "/") else ""
  paste0(
    "Business Operations Suite - saved diagrams\n==========================================\n\n",
    "Written by the Business Operations Suite (R Shiny and Android). Files are never overwritten: every save adds\n",
    "new files with the time in the name.\n\nFolder scheme\n  ", app, "<Group>/<Section>/<Tab>/",
    if (isTRUE(s$by_date)) "<YYYY>/<YYYY-MM>/" else "", if (isTRUE(s$by_format)) "<format>/" else "",
    "<tab_id>_<diagram>_<YYYYMMDD_HHMMSS>.<ext>\n\n",
    "Formats\n  html  the diagram as a web page (interactive for charts and generated diagrams)\n",
    "  pdf, png, jpg, gif, tiff, svg  the diagram image\n  csv   the numbers behind a chart\n  mmd   Mermaid source\n\n",
    GD_MANIFEST, "\n  One row per file: ", paste(GD_MANIFEST_COLS, collapse = ", "), "\n",
    "  In R: library(googledrive); m <- read.csv(text = drive_read_string(drive_get(\"", app, GD_MANIFEST, "\")))\n\n",
    "Properties on every file\n  bos_group, bos_section, bos_tab, bos_tab_id, bos_diagram, bos_format, bos_created_utc\n",
    "  In R: drive_find(q = \"appProperties has { key='bos_tab_id' and value='analytics' }\")\n")
}

# ------------------------------------------------------------------ errors

gd_stop <- function(status, text, what) {
  msg <- substr(text %|g|% "", 1, 300); reason <- ""
  j <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(e) NULL)
  if (is.list(j$error)) {
    msg <- j$error$message %|g|% msg
    if (length(j$error$errors)) reason <- j$error$errors[[1]]$reason %|g|% ""
  } else if (is.character(j$error)) {
    reason <- j$error; msg <- j$error_description %|g|% j$error
  }
  hint <- switch(reason,
    storageQuotaExceeded = , teamDriveFileLimitExceeded =
      " - a service account has no Drive storage of its own: use a folder inside a Shared Drive (add the service account as a member), or sign in with a Google account instead.",
    notFound = " - check the folder id/link and that this account can open it.",
    insufficientFilePermissions = , forbidden = " - this account can see the folder but may not add files to it (needs Editor / Content manager).",
    accessNotConfigured = , SERVICE_DISABLED = " - enable the Google Drive API in the Google Cloud project of these credentials.",
    invalid_grant = " - the sign-in has expired or was revoked: sign in again in API Settings > Google Drive.",
    "")
  cond <- structure(class = c("gdrive_error", "error", "condition"),
    list(message = sprintf("%s failed (HTTP %s%s): %s%s", what, status, if (nzchar(reason)) paste0(", ", reason) else "", msg, hint),
         call = NULL, status = status, reason = reason))
  stop(cond)
}

gd_b64url <- function(x) gsub("=+$", "", chartr("+/", "-_", openssl::base64_encode(x)))

# ------------------------------------------------------------------ device sign-in (Google account)

# Starts Google's sign-in for devices: returns user_code + verification_url to show, and device_code to poll with.
# Needs an OAuth client of type "TVs and Limited Input devices". Scope: drive.file (files the app creates).
gd_device_start <- function(client_id) {
  r <- httr::POST(gd_device_url(), body = list(client_id = client_id, scope = paste(GD_SCOPE_FILE, "openid email")), encode = "form", httr::timeout(30))
  txt <- httr::content(r, "text", encoding = "UTF-8")
  if (httr::status_code(r) != 200) gd_stop(httr::status_code(r), txt, "Starting the Google sign-in")
  j <- jsonlite::fromJSON(txt)
  list(device_code = j$device_code, user_code = j$user_code, verification_url = j$verification_url %|g|% j$verification_uri %|g|% "https://www.google.com/device",
       interval = as.numeric(j$interval %|g|% 5), expires_at = Sys.time() + as.numeric(j$expires_in %|g|% 1800))
}

# One poll. Returns list(state = "pending" | "slow_down" | "ok", refresh_token, email); stops on decline / expiry.
gd_device_poll <- function(dev, client_id, client_secret) {
  if (Sys.time() > dev$expires_at) stop("The sign-in code expired before it was approved. Start again.")
  r <- httr::POST(gd_token_url(), encode = "form", httr::timeout(30), body = list(client_id = client_id, client_secret = client_secret,
                  device_code = dev$device_code, grant_type = "urn:ietf:params:oauth:grant-type:device_code"))
  txt <- httr::content(r, "text", encoding = "UTF-8")
  j <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) list())
  if (httr::status_code(r) == 200) {
    if (!nzchar(j$refresh_token %|g|% "")) stop("Google did not return a refresh token. Remove the app's access in your Google Account and sign in again.")
    email <- ""
    parts <- strsplit(j$id_token %|g|% "", ".", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      b <- chartr("-_", "+/", parts[2]); b <- paste0(b, strrep("=", (4 - nchar(b) %% 4) %% 4))
      email <- tryCatch(jsonlite::fromJSON(rawToChar(openssl::base64_decode(b)))$email %|g|% "", error = function(e) "")
    }
    return(list(state = "ok", refresh_token = j$refresh_token, email = email))
  }
  err <- j$error %|g|% ""
  if (identical(err, "authorization_pending")) return(list(state = "pending"))
  if (identical(err, "slow_down")) return(list(state = "slow_down"))
  if (identical(err, "access_denied")) stop("The sign-in was declined in the browser.")
  gd_stop(httr::status_code(r), txt, "Google sign-in")
}

# ------------------------------------------------------------------ client

GDrive <- R6::R6Class("GDrive",
  public = list(
    settings = NULL, sa = NULL, resumable_above = 5 * 1024^2,

    # settings: gd_load_settings(); sa_path: the keys-folder service-account key (used when key_file is "")
    initialize = function(settings, sa_path = NA) {
      private$folders <- new.env()
      self$settings <- settings
      if (!identical(settings$auth_mode, "oauth")) {
        p <- if (nzchar(settings$key_file)) settings$key_file else sa_path
        if (is.na(p) || !nzchar(p) || !file.exists(p)) stop("No service-account key for Google Drive: choose one in API Settings > Google Drive, or put it in the keys folder.")
        self$sa <- jsonlite::fromJSON(p)
        if (is.null(self$sa$private_key) || is.null(self$sa$client_email)) stop(basename(p), " is not a service-account key.")
      } else if (!nzchar(settings$client_id) || !nzchar(settings$refresh_token)) {
        stop("Google Drive is not set up: open API Settings > Google Drive and sign in.")
      }
    },

    describe = function() if (!is.null(self$sa)) paste("service account", self$sa$client_email) else (self$settings$account_email %|g|% "Google account"),

    token = function(force = FALSE) {
      if (!force && !is.null(private$tok) && Sys.time() < private$tok_exp) return(private$tok)
      if (!is.null(self$sa)) {
        now <- as.integer(Sys.time())
        claims <- list(iss = self$sa$client_email, scope = GD_SCOPE_FULL, aud = self$sa$token_uri %|g|% gd_token_url(), iat = now, exp = now + 3600)
        if (nzchar(self$settings$impersonate %|g|% "")) claims$sub <- self$settings$impersonate
        hdr <- list(alg = "RS256", typ = "JWT"); if (!is.null(self$sa$private_key_id)) hdr$kid <- self$sa$private_key_id
        input <- paste0(gd_b64url(charToRaw(jsonlite::toJSON(hdr, auto_unbox = TRUE))), ".", gd_b64url(charToRaw(jsonlite::toJSON(claims, auto_unbox = TRUE))))
        sig <- openssl::signature_create(charToRaw(input), hash = openssl::sha256, key = openssl::read_key(self$sa$private_key))
        url <- getOption("bos.gdrive.token", self$sa$token_uri %|g|% gd_token_url())
        r <- httr::POST(url, encode = "form", httr::timeout(30),
                        body = list(grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion = paste0(input, ".", gd_b64url(sig))))
        what <- "Google sign-in (service account)"
      } else {
        r <- httr::POST(gd_token_url(), encode = "form", httr::timeout(30),
                        body = list(grant_type = "refresh_token", client_id = self$settings$client_id,
                                    client_secret = self$settings$client_secret, refresh_token = self$settings$refresh_token))
        what <- "Google sign-in"
      }
      txt <- httr::content(r, "text", encoding = "UTF-8")
      if (httr::status_code(r) != 200) gd_stop(httr::status_code(r), txt, what)
      j <- jsonlite::fromJSON(txt)
      private$tok <- j$access_token
      private$tok_exp <- Sys.time() + as.numeric(j$expires_in %|g|% 3600) - 300
      private$tok
    },

    # One API call: refreshes the token once on 401, retries 429/5xx and network errors with backoff.
    call = function(method, url, query = list(), headers = character(0), body = NULL, what = "Google Drive", timeout = 120) {
      refreshed <- FALSE
      for (attempt in 0:3) {
        tok <- self$token(force = refreshed && attempt > 0)
        r <- tryCatch(httr::VERB(method, url, query = query, httr::add_headers(.headers = c(Authorization = paste("Bearer", tok), headers)),
                                 body = body, httr::timeout(timeout)),
                      error = function(e) e)
        if (inherits(r, "error")) {
          if (attempt < 3) { Sys.sleep(0.6 * 2^attempt); next }
          stop(sprintf("%s failed: %s", what, conditionMessage(r)))
        }
        st <- httr::status_code(r)
        if (st == 401 && !refreshed) { refreshed <- TRUE; next }
        if (st >= 200 && st < 300) return(r)
        txt <- httr::content(r, "text", encoding = "UTF-8")
        reason <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE)$error$errors[[1]]$reason %|g|% "", error = function(e) "")
        if ((st == 429 || st >= 500 || reason %in% c("rateLimitExceeded", "userRateLimitExceeded")) && attempt < 3) { Sys.sleep(0.8 * 2^attempt); next }
        gd_stop(st, txt, what)
      }
      stop(what, " failed after retries")
    },

    json = function(r) jsonlite::fromJSON(httr::content(r, "text", encoding = "UTF-8"), simplifyVector = FALSE),

    about = function() self$json(self$call("GET", paste0(gd_api(), "/about"),
      query = list(fields = "user(displayName,emailAddress),storageQuota(limit,usage)", supportsAllDrives = "true"), what = "Reading the Drive account")),

    file_info = function(id, fields = "id,name,mimeType,driveId,trashed,capabilities(canAddChildren),webViewLink")
      self$json(self$call("GET", paste0(gd_api(), "/files/", id), query = list(fields = fields, supportsAllDrives = "true"), what = paste("Opening folder", id))),

    # Checks the root folder (or My Drive) and remembers whether it lives in a Shared Drive.
    resolve_root = function(root_folder = self$settings$root_folder) {
      id <- gd_folder_id(root_folder)
      if (nzchar(trimws(root_folder %|g|% "")) && !nzchar(id)) stop(sprintf("The root folder is not a Drive folder id or link: \"%s\"", root_folder))
      if (!nzchar(id)) { private$root_id <- "root"; private$drive_id <- NULL; return("root") }
      j <- self$file_info(id)
      if (!identical(j$mimeType, GD_FOLDER_MIME)) stop(sprintf("\"%s\" is not a folder.", j$name))
      if (isTRUE(j$trashed)) stop(sprintf("The folder \"%s\" is in the bin.", j$name))
      if (identical(j$capabilities$canAddChildren, FALSE)) stop(sprintf("This account may open \"%s\" but not add files to it (needs Editor / Content manager).", j$name))
      private$drive_id <- j$driveId
      private$root_id <- id
      id
    },

    find = function(parent, name, folder = FALSE) {
      esc <- function(x) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", x))
      q <- sprintf("name = '%s' and '%s' in parents and trashed = false%s", esc(name), esc(parent), if (folder) sprintf(" and mimeType = '%s'", GD_FOLDER_MIME) else "")
      scope <- if (is.null(private$drive_id)) list(corpora = "user") else list(corpora = "drive", driveId = private$drive_id, includeItemsFromAllDrives = "true")
      j <- self$json(self$call("GET", paste0(gd_api(), "/files"), what = sprintf("Looking for \"%s\"", name),
        query = c(list(q = q, fields = "files(id,name,mimeType,webViewLink,size)", orderBy = "createdTime", pageSize = "10", supportsAllDrives = "true"), scope)))
      if (length(j$files)) j$files[[1]] else NULL
    },

    # The folder `name` in `parent`, created if missing (the oldest wins if duplicates already exist).
    ensure_folder = function(parent, name) {
      key <- paste0(parent, "/", name)
      if (!is.null(private$folders[[key]])) return(private$folders[[key]])
      f <- self$find(parent, name, folder = TRUE)
      if (is.null(f)) {
        r <- self$call("POST", paste0(gd_api(), "/files"), query = list(fields = "id", supportsAllDrives = "true"),
                       headers = c(`Content-Type` = "application/json; charset=UTF-8"),
                       body = jsonlite::toJSON(list(name = name, mimeType = GD_FOLDER_MIME, parents = list(parent)), auto_unbox = TRUE),
                       what = sprintf("Creating folder \"%s\"", name))
        f <- self$json(r)
        cat(sprintf("[Drive] folder created: %s (%s)\n", name, f$id))
      }
      private$folders[[key]] <- f$id
      f$id
    },

    ensure_path = function(root, parts) { id <- root; for (p in parts) id <- self$ensure_folder(id, p); id },
    forget_folders = function() private$folders <- new.env(),

    upload = function(parent, name, bytes, mime, properties = list(), description = "", path = "") {
      meta <- list(name = name, parents = list(parent), mimeType = mime)
      if (length(properties)) meta$appProperties <- properties
      if (nzchar(description)) meta$description <- description
      meta_json <- jsonlite::toJSON(meta, auto_unbox = TRUE)
      fields <- "id,name,webViewLink,size,mimeType"
      if (length(bytes) > self$resumable_above) {
        start <- self$call("POST", paste0(gd_upload_api(), "/files"), query = list(uploadType = "resumable", supportsAllDrives = "true", fields = fields),
                           headers = c(`Content-Type` = "application/json; charset=UTF-8", `X-Upload-Content-Type` = mime, `X-Upload-Content-Length` = as.character(length(bytes))),
                           body = meta_json, what = paste("Starting the upload of", name))
        loc <- httr::headers(start)$location
        if (is.null(loc) || !nzchar(loc)) stop("Drive did not return an upload address for ", name)
        r <- self$call("PUT", loc, headers = c(`Content-Type` = mime), body = bytes, what = paste("Uploading", name), timeout = 600)
      } else {
        b <- paste0("bos_drive_", format(Sys.time(), "%H%M%OS6"), "_", sample.int(1e9, 1))
        body <- c(charToRaw(paste0("--", b, "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n", meta_json, "\r\n--", b, "\r\nContent-Type: ", mime, "\r\n\r\n")),
                  bytes, charToRaw(paste0("\r\n--", b, "--\r\n")))
        r <- self$call("POST", paste0(gd_upload_api(), "/files"), query = list(uploadType = "multipart", supportsAllDrives = "true", fields = fields),
                       headers = c(`Content-Type` = paste0("multipart/related; boundary=", b)), body = body, what = paste("Uploading", name), timeout = 300)
      }
      j <- self$json(r)
      list(id = j$id, name = j$name %|g|% name, link = j$webViewLink %|g|% "", size = as.numeric(j$size %|g|% length(bytes)), mime = j$mimeType %|g|% mime, path = path)
    },

    download = function(id) httr::content(self$call("GET", paste0(gd_api(), "/files/", id), query = list(alt = "media", supportsAllDrives = "true"), what = paste("Downloading file", id)), "raw"),

    replace_content = function(id, bytes, mime)
      invisible(self$call("PATCH", paste0(gd_upload_api(), "/files/", id), query = list(uploadType = "media", supportsAllDrives = "true", fields = "id"),
                          headers = c(`Content-Type` = mime), body = bytes, what = paste("Updating file", id))),

    delete = function(id) invisible(self$call("DELETE", paste0(gd_api(), "/files/", id), query = list(supportsAllDrives = "true"), what = paste("Deleting file", id))),

    # Any Drive search (all pages). everywhere = TRUE searches every drive this account can see (like
    # CollaborationPlanning's drive_find); otherwise the root's own drive.
    query = function(q, fields = "files(id,name,mimeType,modifiedTime,size,webViewLink,appProperties,parents)", everywhere = FALSE) {
      scope <- if (everywhere) list(corpora = "allDrives", includeItemsFromAllDrives = "true")
               else if (is.null(private$drive_id)) list(corpora = "user") else list(corpora = "drive", driveId = private$drive_id, includeItemsFromAllDrives = "true")
      out <- list(); token <- NULL
      repeat {
        j <- self$json(self$call("GET", paste0(gd_api(), "/files"), what = "Searching Google Drive",
          query = c(list(q = q, fields = paste0("nextPageToken,", fields), pageSize = "1000", supportsAllDrives = "true"), scope,
                    if (!is.null(token)) list(pageToken = token))))
        out <- c(out, j$files)
        token <- j$nextPageToken
        if (is.null(token) || !nzchar(token)) break
      }
      out
    },

    # Files (and folders) directly inside a folder
    children = function(parent, folders_only = FALSE) {
      esc <- function(x) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", x))
      self$query(sprintf("'%s' in parents and trashed = false%s", esc(parent), if (folders_only) sprintf(" and mimeType = '%s'", GD_FOLDER_MIME) else ""))
    },

    # Create a file, or replace an existing one (name, content and appProperties) when file_id is given
    put_file = function(parent, name, bytes, mime, file_id = "", properties = list()) {
      meta <- list(name = name, mimeType = mime)
      if (length(properties)) meta$appProperties <- properties
      if (!nzchar(file_id)) meta$parents <- list(parent)
      b <- paste0("bos_drive_", sample.int(1e9, 1))
      body <- c(charToRaw(paste0("--", b, "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n", jsonlite::toJSON(meta, auto_unbox = TRUE),
                                 "\r\n--", b, "\r\nContent-Type: ", mime, "\r\n\r\n")), bytes, charToRaw(paste0("\r\n--", b, "--\r\n")))
      url <- paste0(gd_upload_api(), "/files", if (nzchar(file_id)) paste0("/", file_id) else "")
      r <- self$call(if (nzchar(file_id)) "PATCH" else "POST", url, query = list(uploadType = "multipart", supportsAllDrives = "true", fields = "id,name,webViewLink"),
                     headers = c(`Content-Type` = paste0("multipart/related; boundary=", b)), body = body, what = paste("Saving", name))
      self$json(r)
    },

    # root/<app folder> with its _README.txt; created on first use.
    app_folder = function() {
      root <- private$root_id %|g|% self$resolve_root()
      s <- self$settings
      if (!nzchar(trimws(s$app_folder))) return(root)
      id <- self$ensure_folder(root, gd_safe_name(s$app_folder))
      key <- paste0(id, "/", GD_README)
      if (is.null(private$folders[[key]])) {
        if (is.null(self$find(id, GD_README))) self$upload(id, GD_README, charToRaw(enc2utf8(gd_readme(s))), "text/plain")
        private$folders[[key]] <- "ok"
      }
      id
    },

    # Uploads one file into its place in the tree (retries once with fresh folder ids if a folder was deleted on Drive).
    save = function(p, fmt, bytes, mime = gd_mime(fmt)) {
      root <- private$root_id %|g|% self$resolve_root()
      parts <- gd_folders(p, self$settings, fmt)
      self$app_folder()
      name <- gd_file_name(p, fmt)
      attempt <- function() self$upload(self$ensure_path(root, parts), name, bytes, mime, properties = gd_properties(p, fmt),
                                        description = sprintf("%s > %s > %s: %s", p$group, p$section, p$tab, p$diagram), path = paste(parts, collapse = "/"))
      tryCatch(attempt(), gdrive_error = function(e) {
        if (!identical(e$status, 404L) && !identical(as.integer(e$status), 404L)) stop(e)
        self$forget_folders()
        attempt()
      })
    },

    # Appends rows to <app folder>/_manifest.csv (created with a header row the first time).
    append_manifest = function(rows) {
      if (!length(rows)) return(invisible())
      folder <- self$app_folder()
      lines <- paste(vapply(rows, gd_csv_line, ""), collapse = "\n")
      f <- self$find(folder, GD_MANIFEST)
      if (is.null(f)) {
        self$upload(folder, GD_MANIFEST, charToRaw(enc2utf8(paste0(gd_csv_line(GD_MANIFEST_COLS), "\n", lines, "\n"))), "text/csv")
      } else {
        old <- rawToChar(self$download(f$id)); Encoding(old) <- "UTF-8"
        if (nzchar(old) && !endsWith(old, "\n")) old <- paste0(old, "\n")
        self$replace_content(f$id, charToRaw(enc2utf8(paste0(old, lines, "\n"))), "text/csv")
      }
      invisible()
    }
  ),
  private = list(tok = NULL, tok_exp = 0, folders = NULL, root_id = NULL, drive_id = NULL)
)
