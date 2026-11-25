# R/utils_gdrive.R
# Google Drive: every chart, diagram, picture and table on screen can be saved as PNG / JPEG / SVG / PDF / GIF / HTML /
# JSON / CSV into one Google Drive folder that other R Shiny apps can read.
#
# Folder scheme (each folder is made the first time a file needs it):
#   <parent folder or Shared Drive> / <root, "LAT U3 Trading Desk"> / <menu group> / <tab> / <sub-tab ...> / <YYYY> / <YYYY-MM-DD> /
#       HHMMSS_<title>.<ext>
#   <root> / _index / lat_u3_drive_index.csv   one row per saved file (path, title, format, file id, link)  <- other apps read this
#   <root> / _index / README.md                the scheme and how to read the files from another app
#
# Three ways to connect: a service-account key (server or PC; the folder must be in a Shared Drive, or a folder shared with the
# key's email inside a Shared Drive, because service accounts have no storage of their own), signing in with a Google account
# (on the PC only), or a Google Drive for desktop folder (files sync on their own). Keys stay in memory: never saved or printed.

gd_scope <- "https://www.googleapis.com/auth/drive"
gd_folder_mime <- "application/vnd.google-apps.folder"
gd_index_name <- "lat_u3_drive_index.csv"
gd_plotly_cdn <- "https://cdn.plot.ly/plotly-2.11.1.min.js"
gd_formats <- c("PNG picture" = "png", "JPEG picture" = "jpg", "SVG drawing" = "svg", "PDF" = "pdf", "Animated GIF" = "gif",
                "Interactive HTML" = "html", "Chart data (JSON)" = "json", "Data (CSV)" = "csv")
gd_kind_formats <- list(plotly = c("png", "jpg", "svg", "pdf", "gif", "html", "json", "csv"),
                        svg = c("png", "jpg", "svg", "pdf", "gif", "html"),
                        img = c("png", "jpg", "pdf", "gif", "html"),
                        table = c("html", "csv", "json"))
gd_kind_names <- c(plotly = "Charts", svg = "Diagrams", img = "Pictures", table = "Tables")
gd_mime <- c(png = "image/png", jpg = "image/jpeg", svg = "image/svg+xml", pdf = "application/pdf", gif = "image/gif", html = "text/html",
             json = "application/json", csv = "text/csv", md = "text/markdown", txt = "text/plain")
gd_or <- function(x, y) if (is.null(x) || !length(x) || (length(x) == 1 && (is.na(x) || identical(x, "")))) y else x

gd_clean <- function(x, n = 60) {
  x <- gsub("[/\\\\:*?\"<>|\r\n\t]+", " ", as.character(x)); x <- trimws(gsub("\\s+", " ", x)); x <- trimws(substr(x, 1, n))
  ifelse(nzchar(x), x, "untitled")
}
# a folder link, an "id=" link, a bare id, or "root" (My Drive)
gd_parse_id <- function(x) {
  x <- trimws(gd_or(x, "")); if (!nzchar(x)) return("")
  if (tolower(x) %in% c("root", "my drive")) return("root")
  m <- regmatches(x, regexpr("(folders/|id=|drive/u/[0-9]+/folders/)[A-Za-z0-9_-]{10,}", x))
  if (length(m)) return(sub("^.*(folders/|id=)", "", m))
  if (grepl("^[A-Za-z0-9_-]{10,}$", x)) x else ""
}
# the folders below the root for one saved item
gd_folder_parts <- function(path, when = Sys.time(), dates = "year_date") {
  p <- unlist(path); p <- p[!is.na(p) & nzchar(trimws(p))]; p <- gd_clean(p)
  if (length(p) > 1) p <- p[c(TRUE, p[-1] != p[-length(p)])]   # "Start here / Start here" -> one level
  d <- switch(gd_or(dates, "year_date"), year_date = c(format(when, "%Y"), format(when, "%Y-%m-%d")),
              month_date = c(format(when, "%Y-%m"), format(when, "%Y-%m-%d")), date = format(when, "%Y-%m-%d"), none = character(0),
              c(format(when, "%Y"), format(when, "%Y-%m-%d")))
  c(if (length(p)) p else "General", d)
}
gd_file_base <- function(title, when = Sys.time()) paste0(format(when, "%H%M%S"), "_", gsub(" ", "_", gd_clean(title, 50)))

# ---- Drive API (REST v3, works with Shared Drives) ------------------------------------------------------------
gd_explain <- function(status, msg) {
  m <- gd_or(msg, "")
  if (grepl("storage quota|storageQuotaExceeded", m, ignore.case = TRUE))
    return("Google refused: a service account has no storage of its own. Use a folder in a Shared Drive and add the key's email to the Shared Drive as Content manager (or connect with your Google account on your PC).")
  if (grepl("has not been used in project|is disabled|accessNotConfigured", m, ignore.case = TRUE))
    return(paste0("The Google Drive API is not turned on for the key's Google Cloud project: open console.cloud.google.com > APIs & Services > Library > Google Drive API > Enable, wait a minute and connect again. (", substr(m, 1, 160), ")"))
  if (status == 404) return("Folder not found: check the link, and share the folder (or its Shared Drive) with the email shown on this tab.")
  if (status == 403) return(paste("Google refused (403): the folder is not shared with this account, or it can only read.", substr(m, 1, 200)))
  if (status == 401) return("Google did not accept the sign-in (401): load the key again, or sign in again.")
  sprintf("Google Drive error %s: %s", status, substr(m, 1, 300))
}
gd_req <- function(tok, url, method = "GET", query = list(), json = NULL, raw = NULL, ctype = NULL) {
  go <- function(t) {
    r <- httr2::request(url); r <- httr2::req_method(r, method); r <- httr2::req_auth_bearer_token(r, t)
    if (length(query)) r <- do.call(httr2::req_url_query, c(list(r), query))
    if (!is.null(json)) r <- httr2::req_body_json(r, json, auto_unbox = TRUE)
    if (!is.null(raw)) r <- httr2::req_body_raw(r, raw, type = ctype)
    r <- httr2::req_error(r, is_error = function(resp) FALSE); r <- httr2::req_timeout(r, 90)
    httr2::req_perform(r)
  }
  resp <- go(tok(FALSE)); if (httr2::resp_status(resp) == 401) resp <- go(tok(TRUE))
  st <- httr2::resp_status(resp)
  if (st >= 300) { m <- tryCatch(httr2::resp_body_json(resp)$error$message, error = function(e) NULL); stop(gd_explain(st, gd_or(m, httr2::resp_status_desc(resp))), call. = FALSE) }
  resp
}
gd_api_backend <- function(tok) {
  B <- "https://www.googleapis.com/drive/v3/files"; U <- "https://www.googleapis.com/upload/drive/v3/files"
  q1 <- function(s) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", s))
  all <- list(supportsAllDrives = "true")
  j <- function(resp) httr2::resp_body_json(resp)
  list(kind = "api",
    info = function(id) j(gd_req(tok, paste0(B, "/", id), query = c(all, fields = "id,name,mimeType,driveId,webViewLink,capabilities(canAddChildren)"))),
    find = function(parent, name, folder = FALSE) {
      q <- sprintf("name = '%s' and '%s' in parents and trashed = false%s", q1(name), parent, if (folder) sprintf(" and mimeType = '%s'", gd_folder_mime) else "")
      f <- j(gd_req(tok, B, query = c(all, q = q, fields = "files(id,name,webViewLink)", includeItemsFromAllDrives = "true", corpora = "allDrives", pageSize = 5)))$files
      if (length(f)) f[[1]] else NULL },
    mkdir = function(parent, name) j(gd_req(tok, B, "POST", query = c(all, fields = "id,name,webViewLink"), json = list(name = name, mimeType = gd_folder_mime, parents = list(parent)))),
    upload = function(parent, name, file, mime) {
      b <- paste0("gdx", paste(sample(c(0:9, letters), 24, TRUE), collapse = ""))
      meta <- as.character(jsonlite::toJSON(list(name = name, parents = list(parent)), auto_unbox = TRUE))
      body <- c(charToRaw(sprintf("--%s\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n%s\r\n--%s\r\nContent-Type: %s\r\n\r\n", b, meta, b, mime)),
                readBin(file, "raw", file.size(file)), charToRaw(sprintf("\r\n--%s--", b)))
      j(gd_req(tok, U, "POST", query = c(all, uploadType = "multipart", fields = "id,name,webViewLink"), raw = body, ctype = paste0("multipart/related; boundary=", b))) },
    update = function(id, file, mime) j(gd_req(tok, paste0(U, "/", id), "PATCH", query = c(all, uploadType = "media", fields = "id,name,webViewLink"), raw = readBin(file, "raw", file.size(file)), ctype = mime)),
    read_text = function(id) httr2::resp_body_string(gd_req(tok, paste0(B, "/", id), query = c(all, alt = "media"))))
}
# Google Drive for desktop (or any local folder): the same calls on the file system
gd_local_backend <- function() {
  it <- function(p) list(id = p, name = basename(p), webViewLink = normalizePath(p, winslash = "/", mustWork = FALSE))
  list(kind = "local",
    info = function(id) { if (!dir.exists(id)) stop("Folder not found on this computer: ", id, call. = FALSE); it(id) },
    find = function(parent, name, folder = FALSE) { p <- file.path(parent, name); if ((folder && dir.exists(p)) || (!folder && file.exists(p) && !dir.exists(p))) it(p) else NULL },
    mkdir = function(parent, name) { p <- file.path(parent, name); dir.create(p, recursive = TRUE, showWarnings = FALSE); if (!dir.exists(p)) stop("Could not make the folder ", p, call. = FALSE); it(p) },
    upload = function(parent, name, file, mime) { p <- file.path(parent, name); if (!file.copy(file, p, overwrite = TRUE)) stop("Could not write ", p, call. = FALSE); it(p) },
    update = function(id, file, mime) { file.copy(file, id, overwrite = TRUE); it(id) },
    read_text = function(id) paste(readLines(id, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
}

# ---- sign-in ------------------------------------------------------------------------------------------------
gd_sa_token <- function(json_path = NULL, json_text = NULL) {
  if (!is.null(json_text) && nzchar(trimws(json_text))) { f <- tempfile(fileext = ".json"); on.exit(unlink(f), add = TRUE); writeLines(json_text, f); json_path <- f }
  if (is.null(json_path) || !file.exists(json_path)) stop("Load the service-account key (.json) or paste it.", call. = FALSE)
  info <- tryCatch(jsonlite::fromJSON(json_path), error = function(e) stop("The key is not valid JSON.", call. = FALSE))
  if (!identical(info$type, "service_account")) stop("This is not a service-account key (\"type\" must be \"service_account\").", call. = FALSE)
  tk <- tryCatch(gargle::credentials_service_account(scopes = gd_scope, path = json_path), error = function(e) stop("Google did not accept the key: ", conditionMessage(e), call. = FALSE))
  if (is.null(tk)) stop("Google did not accept the key.", call. = FALSE)
  t0 <- Sys.time()
  list(who = gd_or(info$client_email, ""), project = gd_or(info$project_id, ""),
       token = function(refresh = FALSE) { if (refresh || difftime(Sys.time(), t0, units = "mins") > 45) { tk$refresh(); t0 <<- Sys.time() }; tk$credentials$access_token })
}
gd_oauth_token <- function(email = "") {
  if (!interactive() && nzchar(Sys.getenv("CONNECT_SERVER", Sys.getenv("RSTUDIO_PRODUCT", ""))))
    stop("Signing in with a Google account only works when the app runs on your own PC. On the server use a service-account key.", call. = FALSE)
  googledrive::drive_auth(email = if (nzchar(gd_or(email, ""))) email else gargle::gargle_oauth_email(), scopes = gd_scope)
  who <- tryCatch(googledrive::drive_user()$emailAddress, error = function(e) "")
  list(who = gd_or(who, ""), project = "",
       token = function(refresh = FALSE) { tk <- googledrive::drive_token()$auth_token; if (refresh) tk$refresh(); tk$credentials$access_token })
}

# ---- the client: one per app (shared by every browser session) ----------------------------------------------
gd_index_cols <- c("saved_at_utc", "group", "tab", "sub_tabs", "title", "kind", "format", "file_name", "folder_path", "file_id", "link", "size_bytes", "export_id")
gd_readme <- function(root_name, dates) paste0(
  "# ", root_name, ": saved charts, diagrams, pictures and tables\n\n",
  "Written by the LAT U3 Trading Desk app. Folders are made the first time a file needs them.\n\n",
  "## Folder scheme\n\n    ", root_name, " / <menu group> / <tab> / <sub-tab ...> / ",
  switch(dates, none = "", month_date = "<YYYY-MM> / <YYYY-MM-DD> / ", date = "<YYYY-MM-DD> / ", "<YYYY> / <YYYY-MM-DD> / "),
  "HHMMSS_<title>.<png|jpg|svg|pdf|gif|html|json|csv>\n\n",
  "Example: ", root_name, " / Trade Journal / Trading Desk / B. Analyse & Place / 2026 / 2026-11-22 / 143205_Price_chart.png\n\n",
  "## Index\n\n`_index/", gd_index_name, "` has one row per file: ", paste(gd_index_cols, collapse = ", "), ".\n",
  "The .json files hold the chart itself (Plotly data and layout), so another app can draw it again; the .csv files hold its numbers.\n\n",
  "## Reading from another R Shiny app\n\n```r\nlibrary(googledrive)\ndrive_auth(path = \"service-account.json\")   # a key that can read this folder\n",
  "idx <- drive_find(\"", gd_index_name, "\", shared_drive = NULL)  # or drive_get(as_id(\"<index file id>\"))\n",
  "tab <- read.csv(text = drive_read_string(idx$id[1]))\n",
  "f <- tail(tab[tab$format == \"json\", ], 1)\nfig <- jsonlite::fromJSON(drive_read_string(googledrive::as_id(f$file_id)), simplifyVector = FALSE)\n",
  "plotly::plotly_build(list(x = list(data = fig$data, layout = fig$layout)))   # or plotly::as_widget(fig)\n```\n")

gd_make_client <- function() {
  e <- new.env()
  e$backend <- NULL; e$mode <- "none"; e$who <- ""; e$project <- ""; e$parent <- ""; e$root <- NULL; e$idx_folder <- NULL
  e$root_name <- "LAT U3 Trading Desk"; e$dates <- "year_date"; e$formats <- c("png", "pdf", "html", "json"); e$kinds <- names(gd_kind_names)
  e$offline_html <- FALSE; e$cache <- new.env(); e$index <- NULL; e$index_id <- NULL; e$saved <- 0L; e$folders_made <- 0L; e$tick <- 0L; e$msg <- ""
  e$connected <- function() !is.null(e$root)
  e$bump <- function() e$tick <- e$tick + 1L
  e$disconnect <- function() { e$backend <- NULL; e$root <- NULL; e$idx_folder <- NULL; e$mode <- "none"; e$who <- ""; e$cache <- new.env(); e$index <- NULL; e$index_id <- NULL; e$bump(); invisible(TRUE) }
  e$connect <- function(backend, parent, mode, who = "", project = "", root_name = e$root_name) {
    parent <- gd_or(parent, if (identical(backend$kind, "api")) "" else NA)
    if (!nzchar(parent) && identical(backend$kind, "api")) {
      if (identical(mode, "oauth")) parent <- "root" else stop("Paste the link of the Drive folder to save into (in a Shared Drive, shared with ", who, ").", call. = FALSE) }
    p <- backend$info(parent)
    if (!is.null(p$mimeType) && !identical(p$mimeType, gd_folder_mime)) stop("That link is a file, not a folder.", call. = FALSE)
    if (identical(p$capabilities$canAddChildren, FALSE)) stop("This account can only read that folder: give it Editor (or Content manager) access.", call. = FALSE)
    rn <- gd_clean(gd_or(root_name, "LAT U3 Trading Desk"), 80)
    root <- backend$find(parent, rn, TRUE); made <- 0L
    if (is.null(root)) { root <- backend$mkdir(parent, rn); made <- made + 1L }
    ix <- backend$find(root$id, "_index", TRUE); if (is.null(ix)) { ix <- backend$mkdir(root$id, "_index"); made <- made + 1L }
    e$backend <- backend; e$mode <- mode; e$who <- who; e$project <- project; e$parent <- parent; e$root <- root; e$root_name <- rn; e$idx_folder <- ix
    e$cache <- new.env(); e$folders_made <- e$folders_made + made
    f <- backend$find(ix$id, gd_index_name, FALSE)
    e$index_id <- if (is.null(f)) NULL else f$id
    e$index <- if (is.null(f)) NULL else tryCatch(utils::read.csv(text = backend$read_text(f$id), stringsAsFactors = FALSE, colClasses = "character"), error = function(err) NULL)
    rd <- tempfile(fileext = ".md"); writeLines(gd_readme(rn, e$dates), rd, useBytes = TRUE); on.exit(unlink(rd), add = TRUE)
    r <- backend$find(ix$id, "README.md", FALSE)
    tryCatch(if (is.null(r)) backend$upload(ix$id, "README.md", rd, gd_mime[["md"]]) else backend$update(r$id, rd, gd_mime[["md"]]), error = function(err) NULL)
    e$msg <- sprintf("Connected: saving into \"%s\"%s.", rn, if (made) sprintf(" (%d folder(s) made)", made) else ""); e$bump()
    invisible(root)
  }
  # make (or find) every folder of the path, from the root down; cached so each folder is looked up once
  e$ensure_path <- function(parts) {
    if (!e$connected()) stop("Google Drive is not connected: API Configuration > Google Drive.", call. = FALSE)
    id <- e$root$id; key <- ""; links <- character(0)
    for (p in parts) {
      key <- paste0(key, "/", p); hit <- get0(key, envir = e$cache, inherits = FALSE)
      if (is.null(hit)) {
        f <- e$backend$find(id, p, TRUE)
        if (is.null(f)) { f <- e$backend$mkdir(id, p); e$folders_made <- e$folders_made + 1L }
        hit <- list(id = f$id, link = gd_or(f$webViewLink, "")); assign(key, hit, envir = e$cache)
      }
      id <- hit$id; links <- hit$link
    }
    list(id = id, link = links, path = paste(c(e$root_name, parts), collapse = " / "))
  }
  # files: named character vector, names = file names, values = local paths
  e$save <- function(files, parts, meta = list()) {
    fo <- e$ensure_path(parts); out <- list()
    for (nm in names(files)) {
      ext <- tolower(tools::file_ext(nm)); r <- e$backend$upload(fo$id, nm, files[[nm]], gd_or(unname(gd_mime[ext]), "application/octet-stream"))
      out[[nm]] <- list(id = r$id, link = gd_or(r$webViewLink, ""), format = ext, size = file.size(files[[nm]]))
    }
    e$saved <- e$saved + length(out)
    e$add_index(out, fo, meta); e$bump()
    list(folder = fo, files = out)
  }
  e$add_index <- function(out, fo, meta) {
    if (!length(out)) return(invisible())
    pth <- unlist(gd_or(meta$path, list())); pth <- pth[nzchar(pth)]
    rows <- data.frame(saved_at_utc = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC"), group = gd_or(pth[1], ""), tab = gd_or(pth[2], ""),
      sub_tabs = paste(pth[-(1:2)], collapse = " / "), title = gd_or(meta$title, ""), kind = gd_or(meta$kind, ""),
      format = vapply(out, `[[`, "", "format"), file_name = names(out), folder_path = fo$path, file_id = vapply(out, function(x) as.character(x$id), ""),
      link = vapply(out, function(x) as.character(x$link), ""), size_bytes = vapply(out, function(x) as.character(x$size), ""), export_id = gd_or(meta$export_id, ""),
      stringsAsFactors = FALSE, row.names = NULL)
    old <- e$index; if (!is.null(old)) { for (k in setdiff(gd_index_cols, names(old))) old[[k]] <- ""; old <- old[, gd_index_cols, drop = FALSE] }
    e$index <- if (is.null(old) || !nrow(old)) rows else rbind(old, rows)
    f <- tempfile(fileext = ".csv"); on.exit(unlink(f), add = TRUE); utils::write.csv(e$index, f, row.names = FALSE, fileEncoding = "UTF-8")
    tryCatch({ r <- if (is.null(e$index_id)) e$backend$upload(e$idx_folder$id, gd_index_name, f, gd_mime[["csv"]]) else e$backend$update(e$index_id, f, gd_mime[["csv"]]); e$index_id <- r$id },
             error = function(err) e$msg <- paste("The index could not be updated:", conditionMessage(err)))
    invisible()
  }
  e
}

# ---- turning what the browser sent into files -----------------------------------------------------------------
gd_b64_file <- function(x, file) { x <- sub("^data:[^,]*,", "", x); writeBin(base64enc::base64decode(x), file); file }
gd_html_page <- function(title, meta_line, body, head = "") paste0(
  "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>", htmltools::htmlEscape(title), "</title>", head,
  "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:18px;color:#0f172a}h2{margin:0 0 4px;color:#002C3C}.m{color:#64748b;font-size:12px;margin-bottom:12px}",
  "table{border-collapse:collapse;font-size:12.5px}td,th{border:1px solid #cbd5e1;padding:4px 8px;text-align:left}th{background:#eef6f5}</style></head><body>",
  "<h2>", htmltools::htmlEscape(title), "</h2><div class=\"m\">", htmltools::htmlEscape(meta_line), "</div>", body, "</body></html>")
gd_fig_csv <- function(fig) {   # long table of every trace: trace, x, y (+ open/high/low/close)
  d <- fig$data; if (!length(d)) return(NULL)
  one <- function(t, i) {
    v <- function(k) { z <- t[[k]]; if (is.null(z) || !length(z) || is.list(z) && !length(unlist(z))) NULL else vapply(z, function(q) if (is.null(q)) NA_character_ else as.character(q)[1], "") }
    cols <- Filter(Negate(is.null), list(x = v("x"), y = v("y"), open = v("open"), high = v("high"), low = v("low"), close = v("close"), text = v("text")))
    if (!length(cols)) return(NULL); n <- max(lengths(cols)); cols <- lapply(cols, function(z) if (length(z) == n) z else rep_len(c(z, rep(NA, n)), n))
    data.frame(trace = gd_or(t$name, paste("trace", i)), type = gd_or(t$type, "scatter"), cols, stringsAsFactors = FALSE, check.names = FALSE) }
  rs <- Filter(Negate(is.null), Map(one, d, seq_along(d))); if (!length(rs)) return(NULL)
  all <- unique(unlist(lapply(rs, names))); do.call(rbind, lapply(rs, function(r) { for (k in setdiff(all, names(r))) r[[k]] <- NA; r[, all, drop = FALSE] }))
}
gd_gif <- function(png, file, frames = 10) {   # the picture drawn from left to right, then held
  im <- magick::image_flatten(magick::image_background(magick::image_read(png), "white"))
  if (magick::image_info(im)$width > 900) im <- magick::image_scale(im, "900")
  w <- magick::image_info(im)$width; h <- magick::image_info(im)$height
  fr <- lapply(seq_len(frames), function(k) magick::image_extent(magick::image_crop(im, magick::geometry_area(max(1, round(w * k / frames)), h, 0, 0)),
                                                                   magick::geometry_area(w, h), gravity = "west", color = "white"))
  fr <- c(fr, rep(list(im), 8))
  a <- magick::image_animate(magick::image_join(fr), fps = 5, optimize = TRUE)
  magick::image_write(a, file, format = "gif"); file
}
# p: list(kind, title, path, png (data URL), svg (text), fig (JSON text), html, csv, w, h); returns list(files = c(name = path), skipped = text)
gd_build_files <- function(p, formats, dir = tempfile("gdx"), base = gd_file_base(p$title), offline_html = FALSE) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  kind <- gd_or(p$kind, "plotly"); formats <- intersect(formats, gd_kind_formats[[kind]]); out <- character(0); skip <- character(0)
  title <- gd_or(p$title, "untitled"); pth <- unlist(gd_or(p$path, list()))
  meta_line <- sprintf("%s | saved %s | LAT U3 Trading Desk", paste(pth, collapse = " > "), format(Sys.time(), "%d %b %Y %H:%M"))
  f <- function(ext) file.path(dir, paste0(base, ".", ext))
  has_svg <- nzchar(gd_or(p$svg, "")); has_png <- nzchar(gd_or(p$png, "")); rsvg_ok <- requireNamespace("rsvg", quietly = TRUE)
  png <- NULL
  get_png <- function() {
    if (!is.null(png)) return(png)
    if (has_png) png <<- gd_b64_file(p$png, tempfile(fileext = ".png"))
    else if (has_svg && rsvg_ok) { png <<- tempfile(fileext = ".png"); rsvg::rsvg_png(charToRaw(enc2utf8(p$svg)), png, width = 2 * as.numeric(gd_or(p$w, 900))) }
    png }
  fig <- if (nzchar(gd_or(p$fig, ""))) tryCatch(jsonlite::fromJSON(p$fig, simplifyVector = FALSE), error = function(e) NULL) else NULL
  for (fm in formats) {
    r <- tryCatch({
      switch(fm,
        png = { s <- get_png(); if (is.null(s)) stop("no picture"); file.copy(s, f("png"), overwrite = TRUE); f("png") },
        jpg = { s <- get_png(); if (is.null(s)) stop("no picture"); im <- magick::image_flatten(magick::image_background(magick::image_read(s), "white"))
                magick::image_write(im, f("jpg"), format = "jpeg", quality = 92); f("jpg") },
        svg = { if (has_svg) writeLines(enc2utf8(p$svg), f("svg"), useBytes = TRUE) else { s <- get_png(); if (is.null(s)) stop("no picture"); i <- magick::image_info(magick::image_read(s))
                  writeLines(sprintf("<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"%d\" height=\"%d\"><image width=\"%d\" height=\"%d\" xlink:href=\"data:image/png;base64,%s\"/></svg>",
                    i$width, i$height, i$width, i$height, base64enc::base64encode(s)), f("svg")) }; f("svg") },
        pdf = { done <- FALSE
                if (has_svg && rsvg_ok) done <- isTRUE(tryCatch({ rsvg::rsvg_pdf(charToRaw(enc2utf8(p$svg)), f("pdf")); file.exists(f("pdf")) && file.size(f("pdf")) > 0 }, error = function(e) FALSE))
                if (!done) { s <- get_png(); if (is.null(s)) stop("no picture")
                  done <- isTRUE(tryCatch({ magick::image_write(magick::image_flatten(magick::image_background(magick::image_read(s), "white")), f("pdf"), format = "pdf"); TRUE }, error = function(e) FALSE))
                  if (!done) { im <- png::readPNG(s); grDevices::pdf(f("pdf"), width = 11, height = 11 * dim(im)[1] / dim(im)[2]); graphics::par(mar = c(0, 0, 0, 0))
                    graphics::plot.new(); graphics::rasterImage(im, 0, 0, 1, 1); grDevices::dev.off() } }
                f("pdf") },
        gif = { s <- get_png(); if (is.null(s)) stop("no picture"); gd_gif(s, f("gif")) },
        html = { body <- switch(kind,
                   plotly = { if (is.null(fig)) stop("no chart data")
                     js <- if (isTRUE(offline_html)) paste0("<script>", paste(readLines(system.file("htmlwidgets/lib/plotlyjs/plotly-latest.min.js", package = "plotly"), warn = FALSE), collapse = "\n"), "</script>")
                           else sprintf("<script src=\"%s\"></script>", gd_plotly_cdn)
                     paste0(js, "<div id=\"g\" style=\"width:100%;height:", max(420, as.numeric(gd_or(p$h, 520))), "px\"></div><script>var f=", p$fig,
                            ";Plotly.newPlot('g',f.data,f.layout,{responsive:true,displaylogo:false});</script>") },
                   svg = p$svg,
                   img = sprintf("<img style=\"max-width:100%%\" src=\"data:image/png;base64,%s\"/>", base64enc::base64encode(get_png())),
                   table = paste0(gd_or(p$note, ""), gd_or(p$html, "")))
                 writeLines(enc2utf8(gd_html_page(title, meta_line, body)), f("html"), useBytes = TRUE); f("html") },
        json = { if (kind == "plotly") { if (is.null(fig)) stop("no chart data")
                   x <- list(title = title, path = pth, saved_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), app = "LAT U3 Trading Desk", data = fig$data, layout = fig$layout)
                   writeLines(as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA)), f("json"), useBytes = TRUE)
                 } else { d <- utils::read.csv(text = gd_or(p$csv, ""), stringsAsFactors = FALSE, check.names = FALSE)
                   writeLines(as.character(jsonlite::toJSON(list(title = title, path = pth, rows = d), dataframe = "rows", auto_unbox = TRUE, na = "null")), f("json"), useBytes = TRUE) }
                 f("json") },
        csv = { if (kind == "plotly") { d <- if (is.null(fig)) NULL else gd_fig_csv(fig); if (is.null(d)) stop("no chart data"); utils::write.csv(d, f("csv"), row.names = FALSE, fileEncoding = "UTF-8") }
                else writeLines(enc2utf8(gd_or(p$csv, "")), f("csv"), useBytes = TRUE)
                f("csv") })
    }, error = function(e) { skip <<- c(skip, sprintf("%s (%s)", toupper(fm), conditionMessage(e))); NULL })
    if (!is.null(r) && file.exists(r)) out[basename(r)] <- r
  }
  list(files = out, skipped = skip)
}
