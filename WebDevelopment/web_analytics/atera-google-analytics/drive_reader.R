# drive_reader.R - read charts that the Atera Analytics dashboard saved to Google Drive.
# Copy this one file into any other R / Shiny project. Needs: httr, jsonlite
# (plus plotly for atera_plotly). The other app's service account needs at
# least Viewer access to the same shared drive / folder.
#
#   source("drive_reader.R")
#   d   <- atera_drive("service-account.json", root = "https://drive.google.com/drive/folders/XXXX")
#   cat <- atera_catalog(d)                                   # all saved files, newest first
#   f   <- atera_latest(d, tab = "Overview", chart = "Traffic over time", format = "png")
#   img <- atera_download(d, f$file_id)                       # local file path
#
#   # In a Shiny app:
#   output$traffic <- renderImage(list(src = img, contentType = "image/png"), deleteFile = FALSE)
#   output$fig     <- plotly::renderPlotly(atera_plotly(d, atera_latest(d, chart = "Traffic over time", format = "json")$file_id))

atera_drive <- function(key_json, root, subject = NULL) {
  scope <- "https://www.googleapis.com/auth/drive.readonly"
  secrets <- jsonlite::fromJSON(key_json)
  token <- if (requireNamespace("gargle", quietly = TRUE)) {
    gargle::credentials_service_account(scopes = scope, path = key_json, subject = subject)
  } else {
    httr::oauth_service_token(httr::oauth_endpoints("google"), secrets, scope = scope, sub = subject)
  }
  m <- regmatches(root, regexec("/folders/([A-Za-z0-9_-]{10,})", root))[[1]]
  list(token = token, root = if (length(m) == 2) m[2] else trimws(root))
}

.atera_get <- function(d, path, query = list(), raw = FALSE) {
  resp <- httr::GET(paste0("https://www.googleapis.com/drive/v3/", path),
                    httr::config(token = d$token), httr::timeout(120),
                    query = c(list(supportsAllDrives = "true"), query))
  if (httr::status_code(resp) >= 400) {
    stop("Google Drive error ", httr::status_code(resp), ": ",
         httr::content(resp, as = "text", encoding = "UTF-8"), call. = FALSE)
  }
  if (raw) httr::content(resp, as = "raw")
  else jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
}

.atera_child <- function(d, parent, name, folder = TRUE) {
  q <- sprintf("name = '%s' and '%s' in parents and trashed = false and mimeType %s 'application/vnd.google-apps.folder'",
               gsub("'", "\\\\'", name), parent, if (folder) "=" else "!=")
  res <- .atera_get(d, "files", list(q = q, fields = "files(id,name)", orderBy = "createdTime",
                                     includeItemsFromAllDrives = "true", corpora = "allDrives"))
  if (length(res$files)) res$files[[1]]$id else NULL
}

# Every file the dashboard has saved, newest first.
atera_catalog <- function(d, app = "Atera Analytics") {
  app_id <- .atera_child(d, d$root, app)
  cat_id <- if (!is.null(app_id)) .atera_child(d, app_id, "_catalog")
  man_id <- if (!is.null(cat_id)) .atera_child(d, cat_id, "manifest.csv", folder = FALSE)
  if (is.null(man_id)) stop("No catalogue found under '", app, "/_catalog'. Has the dashboard saved anything yet?", call. = FALSE)
  txt <- rawToChar(.atera_get(d, paste0("files/", man_id), list(alt = "media"), raw = TRUE))
  Encoding(txt) <- "UTF-8"
  df <- utils::read.csv(text = txt, colClasses = "character", check.names = FALSE, stringsAsFactors = FALSE)
  df[order(df$saved_at, decreasing = TRUE), , drop = FALSE]
}

# Newest saved file for a chart. `latest_file_id` is a fixed file that is
# overwritten on every save, so it is the best ID to keep for links.
atera_latest <- function(d, chart = NULL, format = NULL, tab = NULL, mode = "live", catalog = NULL) {
  df <- catalog %||% atera_catalog(d)
  if (!is.null(chart))  df <- df[df$chart == chart, , drop = FALSE]
  if (!is.null(format)) df <- df[df$format == format, , drop = FALSE]
  if (!is.null(tab))    df <- df[df$tab == tab, , drop = FALSE]
  if (!is.null(mode) && any(df$data_mode == mode)) df <- df[df$data_mode == mode, , drop = FALSE]
  if (nrow(df) == 0) stop("Nothing saved yet for that chart/format.", call. = FALSE)
  df[1, , drop = FALSE]
}

atera_download <- function(d, file_id, dest = NULL) {
  bytes <- .atera_get(d, paste0("files/", file_id), list(alt = "media"), raw = TRUE)
  if (is.null(dest)) {
    meta <- .atera_get(d, paste0("files/", file_id), list(fields = "name"))
    dest <- file.path(tempdir(), meta$name)
  }
  writeBin(bytes, dest)
  dest
}

atera_read_csv <- function(d, file_id) {
  utils::read.csv(atera_download(d, file_id), check.names = FALSE, fileEncoding = "UTF-8-BOM")
}

# Rebuilds the interactive chart from a saved Plotly JSON file.
atera_plotly <- function(d, file_id) {
  fig <- jsonlite::fromJSON(atera_download(d, file_id), simplifyVector = FALSE)
  plotly::as_widget(list(data = fig$data, layout = fig$layout, config = list(displaylogo = FALSE)))
}

if (!exists("%||%")) `%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
