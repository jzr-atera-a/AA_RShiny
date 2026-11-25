# practice/exporter.R — save diagrams to Google Drive or a (synced) folder in a hierarchical layout.
#
# Every export is a set of files (png / svg / pdf / html / gif / json) that share one name stem and land in
#   <root>/<template folders>/<file>
# The default template is
#   {app}/{group}/{topic}/{diagram}/{yyyy}-{mm}/{stamp}_{diagram_slug}{label}.{ext}
# e.g. DSA-Academy/Linear Structures/Arrays & Strings/Binary Search/2026-11/20261122-101500_binary-search.png
# Missing folders are created on the fly. A manifest (manifest.csv + manifest.json) in <root>/<app>/_index/
# lists every exported file so that other Shiny apps can discover and read them.

EXPORT_FORMATS <- c("PNG image" = "png", "SVG vector" = "svg", "PDF document" = "pdf",
                    "HTML page (snapshot + frames + interactive chart)" = "html",
                    "GIF animation of every step" = "gif", "JSON chart data" = "json")
EXPORT_MIME <- c(png = "image/png", svg = "image/svg+xml", pdf = "application/pdf", html = "text/html",
                 gif = "image/gif", json = "application/json", csv = "text/csv", txt = "text/plain")
EXPORT_TEMPLATE_DEFAULT <- "{app}/{group}/{topic}/{diagram}/{yyyy}-{mm}/{stamp}_{diagram_slug}{label}.{ext}"
EXPORT_TOKENS <- c(app = "app folder name", group = "sidebar group (e.g. Linear Structures)", topic = "page (e.g. Arrays & Strings)",
                   section = "tab inside the page (e.g. Visualise)", diagram = "box title", diagram_slug = "box title as a short slug",
                   topic_slug = "page as a slug", yyyy = "year", mm = "month", dd = "day", date = "YYYY-MM-DD",
                   stamp = "YYYYMMDD-HHMMSS", label = "your optional label, prefixed with _", ext = "file extension", format = "same as ext")

EXPORT_DEFAULTS <- list(
  export_backend = "local", export_formats = "png,pdf,html", gif_delay = "900", gif_max = "60", manifest = "1",
  path_template = EXPORT_TEMPLATE_DEFAULT, app_folder = "DSA-Academy", local_root = "",
  drive_auth = "service", drive_key_path = "", drive_oauth_email = "", drive_oauth_client = "",
  drive_root_id = "", drive_root_name = "DSA-Academy-Exports", drive_shared_drive = "")

export_settings <- function() {
  s <- lapply(setNames(names(EXPORT_DEFAULTS), names(EXPORT_DEFAULTS)), function(k) setting_get(k, EXPORT_DEFAULTS[[k]]))
  env <- c(drive_key_path = "DSA_DRIVE_KEY", drive_root_id = "DSA_DRIVE_ROOT_ID", local_root = "DSA_EXPORT_DIR")
  for (k in names(env)) if (!nzchar(s[[k]]) && nzchar(Sys.getenv(env[[k]]))) s[[k]] <- Sys.getenv(env[[k]])
  if (!nzchar(s$local_root)) s$local_root <- file.path(DATA_DIR, "exports")
  s$local_root <- path.expand(s$local_root)
  s$drive_token_cache <- file.path(DATA_DIR, ".gargle")
  s
}

# ── Names and paths ──────────────────────────────────────────────────────────
clean_folder <- function(x) {
  x <- gsub("[^\\p{L}\\p{N} &+,.()'_\\-]", " ", x, perl = TRUE)
  x <- gsub("\\s+", " ", trimws(x))
  x <- gsub("^[. ]+|[. ]+$", "", x)
  x <- substr(x, 1, 80)
  if (!nzchar(x)) "untitled" else x
}
slugify <- function(x, n = 48) {
  x <- tolower(iconv(x, to = "ASCII//TRANSLIT", sub = ""))
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("^-+|-+$", "", x)
  x <- sub("-+$", "", substr(x, 1, n))
  if (!nzchar(x)) "diagram" else x
}
strip_symbols <- function(x) trimws(gsub("\\s+", " ", gsub("[^\\p{L}\\p{N}\\p{P}\\p{Zs}+<>=|~^$]", "", x %||% "", perl = TRUE)))
short_title <- function(x) {
  x <- trimws(sub("\\s+[—–-]\\s+.*$", "", x))        # "Binary Search — halve …" -> "Binary Search"
  if (!nzchar(x)) "Diagram" else x
}

build_export_path <- function(meta, ext, template = EXPORT_TEMPLATE_DEFAULT, when = Sys.time(), app = "DSA-Academy") {
  lab <- trimws(meta$label %||% "")
  tok <- list(app = app, group = meta$group %||% "Other", topic = meta$topic_label %||% meta$topic %||% "Topic",
              section = meta$section %||% "", diagram = short_title(meta$title %||% "Diagram"),
              diagram_slug = slugify(short_title(meta$title %||% "diagram")), topic_slug = slugify(meta$topic_label %||% meta$topic %||% "topic"),
              yyyy = format(when, "%Y"), mm = format(when, "%m"), dd = format(when, "%d"), date = format(when, "%Y-%m-%d"),
              stamp = format(when, "%Y%m%d-%H%M%S"), label = if (nzchar(lab)) paste0("_", slugify(lab, 30)) else "",
              ext = ext, format = ext)
  fill <- function(s) { for (k in names(tok)) s <- gsub(paste0("{", k, "}"), tok[[k]], s, fixed = TRUE); s }
  parts <- strsplit(template, "/", fixed = TRUE)[[1]]
  parts <- parts[nzchar(trimws(parts))]
  if (!length(parts)) parts <- strsplit(EXPORT_TEMPLATE_DEFAULT, "/", fixed = TRUE)[[1]]
  dirs <- vapply(parts[-length(parts)], function(p) clean_folder(fill(p)), "")
  dirs <- unname(dirs[nzchar(dirs)])
  file <- fill(parts[length(parts)])
  if (!endsWith(file, paste0(".", ext))) file <- paste0(file, ".", ext)
  file <- gsub("[^A-Za-z0-9._+-]+", "-", iconv(file, to = "ASCII//TRANSLIT", sub = ""))
  list(dirs = dirs, file = file, stem = sub("\\.[^.]+$", "", file), rel = paste(c(dirs, file), collapse = "/"))
}

validate_template <- function(t) {
  if (!nzchar(trimws(t))) return("The template is empty.")
  unknown <- setdiff(regmatches(t, gregexpr("(?<=\\{)[a-z_]+(?=\\})", t, perl = TRUE))[[1]], names(EXPORT_TOKENS))
  if (length(unknown)) return(paste("Unknown token(s):", paste0("{", unknown, "}", collapse = ", ")))
  last <- tail(strsplit(t, "/", fixed = TRUE)[[1]], 1)
  if (!grepl("{stamp}", last, fixed = TRUE)) return("The file name part (after the last /) should contain {stamp} so files never overwrite each other.")
  if (!grepl("{ext}", last, fixed = TRUE)) return("The file name part should end with .{ext}.")
  NULL
}

# ── Local / synced-folder backend ────────────────────────────────────────────
local_save <- function(s, rel_dirs, file, src) {
  dir <- do.call(file.path, as.list(c(s$local_root, rel_dirs)))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(dir)) stop("Could not create the folder ", dir)
  dest <- file.path(dir, file); k <- 1
  while (file.exists(dest)) { k <- k + 1; dest <- file.path(dir, sub("(\\.[^.]+)$", paste0("-", k, "\\1"), file)) }
  if (!file.copy(src, dest, overwrite = FALSE)) stop("Could not write ", dest)
  list(location = normalizePath(dest), link = paste0("file:///", sub("^/", "", gsub("\\\\", "/", normalizePath(dest)))))
}

# ── Google Drive backend (googledrive package) ───────────────────────────────
.drv <- new.env()
drive_available <- function() !is.null(.drv$mock) || requireNamespace("googledrive", quietly = TRUE)
# All googledrive calls go through G(), so a fake Drive can be plugged in for testing (.drv$mock).
G <- function(name) if (!is.null(.drv$mock[[name]])) .drv$mock[[name]] else getExportedValue("googledrive", name)
quiet <- function() if (is.null(.drv$mock)) options(googledrive_quiet = TRUE)

drive_connect <- function(s, force = FALSE) {
  if (!drive_available()) stop("The googledrive package is not installed: install.packages(\"googledrive\")")
  sig <- paste(s$drive_auth, s$drive_key_path, .bq$key_path %||% "", s$drive_oauth_email, s$drive_oauth_client, sep = "|")
  if (!force && isTRUE(.drv$ok) && identical(.drv$sig, sig)) return(invisible(TRUE))
  .drv$ok <- FALSE
  if (nzchar(s$drive_oauth_client)) {
    if (!file.exists(s$drive_oauth_client)) stop("OAuth client file not found: ", s$drive_oauth_client)
    G("drive_auth_configure")(path = s$drive_oauth_client)
  }
  if (identical(s$drive_auth, "service")) {
    if (!nzchar(s$drive_key_path) && nzchar(.bq$key_path %||% "") && file.exists(.bq$key_path)) s$drive_key_path <- .bq$key_path   # same service account as BigQuery
    if (!nzchar(s$drive_key_path) || !file.exists(s$drive_key_path)) stop("Service-account key file not found. Upload it in APIs › Google Drive, or connect BigQuery with a key file to reuse that key.")
    G("drive_auth")(path = s$drive_key_path)
  } else {
    dir.create(s$drive_token_cache, showWarnings = FALSE, recursive = TRUE)
    G("drive_auth")(email = if (nzchar(s$drive_oauth_email)) s$drive_oauth_email else TRUE, cache = s$drive_token_cache)
  }
  who <- tryCatch(G("drive_user")(), error = function(e) NULL)
  .drv$who <- who$emailAddress %||% "(unknown account)"
  .drv$ok <- TRUE; .drv$sig <- sig
  invisible(TRUE)
}

drive_q_escape <- function(x) gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", x))

drive_shared <- function(s) if (nzchar(s$drive_shared_drive)) G("as_id")(s$drive_shared_drive) else NULL

drive_find_child_folder <- function(s, parent, name) {
  res <- G("drive_find")(
    q = c(sprintf("'%s' in parents", parent), sprintf("name = '%s'", drive_q_escape(name)),
          "mimeType = 'application/vnd.google-apps.folder'"),
    trashed = FALSE, n_max = 1, shared_drive = drive_shared(s))
  if (nrow(res)) res$id[1] else NULL
}

drive_cache_get <- function(key) {
  r <- mem_tbl("drive_folders"); v <- r$id[r$path == key]
  if (length(v) && !is.na(v[1])) v[1] else NULL
}
drive_cache_set <- function(key, id) mem_upsert("drive_folders", list(path = key, id = id, ts = now_ts()))
drive_cache_clear <- function() mem_delete("drive_folders")

# Root folder id: an explicit folder id, or a folder with the configured name in My Drive (or a shared drive)
drive_root <- function(s) {
  if (nzchar(s$drive_root_id)) return(s$drive_root_id)
  base <- if (nzchar(s$drive_shared_drive)) s$drive_shared_drive else "root"
  key <- paste0("root:", base, ":", s$drive_root_name)
  id <- drive_cache_get(key)
  if (is.null(id)) {
    id <- drive_find_child_folder(s, base, s$drive_root_name)
    if (is.null(id)) id <- G("drive_mkdir")(s$drive_root_name, path = G("as_id")(base), overwrite = FALSE)$id
    drive_cache_set(key, id)
  }
  id
}

# Ensure every folder of rel_dirs exists below the root; returns the deepest folder id. Ids are cached.
drive_ensure <- function(s, rel_dirs) {
  parent <- drive_root(s)
  for (i in seq_along(rel_dirs)) {
    key <- paste0(parent, "/", rel_dirs[i])
    id <- drive_cache_get(key)
    if (is.null(id)) {
      id <- drive_find_child_folder(s, parent, rel_dirs[i])
      if (is.null(id)) id <- G("drive_mkdir")(rel_dirs[i], path = G("as_id")(parent), overwrite = FALSE)$id
      drive_cache_set(key, id)
    }
    parent <- id
  }
  parent
}

drive_save <- function(s, rel_dirs, file, src) {
  quiet()
  drive_connect(s)
  attempt <- function() {
    folder <- drive_ensure(s, rel_dirs)
    up <- G("drive_upload")(media = src, path = G("as_id")(folder), name = file, overwrite = NA)
    list(location = up$id[1], link = sprintf("https://drive.google.com/file/d/%s/view", up$id[1]))
  }
  tryCatch(attempt(), error = function(e) {
    if (grepl("not found|404|notFound", conditionMessage(e), ignore.case = TRUE)) { drive_cache_clear(); attempt() } else stop(e)
  })
}

# ── Manifest (readable by other apps) ────────────────────────────────────────
MANIFEST_COLS <- c("export_id", "created", "backend", "group", "topic", "section", "diagram", "step", "label", "format",
                   "mime", "file_name", "folder_path", "rel_path", "location", "link", "bytes")

manifest_merge <- function(old, new) {
  old <- if (is.null(old) || !nrow(old)) new[0, ] else old[, intersect(MANIFEST_COLS, names(old)), drop = FALSE]
  for (c in setdiff(MANIFEST_COLS, names(old))) old[[c]] <- if (nrow(old)) NA else character(0)
  all <- rbind(old[, MANIFEST_COLS], new[, MANIFEST_COLS])
  all <- all[!duplicated(paste(all$export_id, all$format), fromLast = TRUE), ]
  all[order(all$created, decreasing = TRUE), ]
}

manifest_write_files <- function(df, dir) {
  csv <- file.path(dir, "manifest.csv"); js <- file.path(dir, "manifest.json")
  utils::write.csv(df, csv, row.names = FALSE, na = "")
  jsonlite::write_json(list(app = "DSA Academy", updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), files = df),
                       js, auto_unbox = TRUE, pretty = TRUE, na = "null")
  c(csv = csv, json = js)
}

manifest_update <- function(s, backend, rows) {
  if (!identical(s$manifest, "1") || !nrow(rows)) return(invisible(NULL))
  idx_dirs <- c(clean_folder(s$app_folder), "_index")
  if (backend == "local") {
    dir <- do.call(file.path, as.list(c(s$local_root, idx_dirs)))
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    old <- if (file.exists(file.path(dir, "manifest.csv"))) tryCatch(utils::read.csv(file.path(dir, "manifest.csv"), stringsAsFactors = FALSE, colClasses = "character"), error = function(e) NULL)
    manifest_write_files(manifest_merge(old, rows), dir)
  } else if (backend == "drive") {
    quiet()
    folder <- drive_ensure(s, idx_dirs)
    tmp <- tempfile("manifest"); dir.create(tmp)
    ids <- list()
    for (nm in c("manifest.csv", "manifest.json")) {
      key <- paste0("file:", folder, "/", nm)
      ids[[nm]] <- drive_cache_get(key)
      if (is.null(ids[[nm]])) {
        f <- G("drive_find")(q = c(sprintf("'%s' in parents", folder), sprintf("name = '%s'", nm)), trashed = FALSE, n_max = 1, shared_drive = drive_shared(s))
        if (nrow(f)) { ids[[nm]] <- f$id[1]; drive_cache_set(key, f$id[1]) }
      }
    }
    old <- NULL
    if (!is.null(ids[["manifest.csv"]])) {
      p <- file.path(tmp, "old.csv")
      ok <- tryCatch({ G("drive_download")(G("as_id")(ids[["manifest.csv"]]), path = p, overwrite = TRUE); TRUE }, error = function(e) FALSE)
      if (ok) old <- tryCatch(utils::read.csv(p, stringsAsFactors = FALSE, colClasses = "character"), error = function(e) NULL)
    }
    files <- manifest_write_files(manifest_merge(old, rows), tmp)
    for (nm in c("manifest.csv", "manifest.json")) {
      src <- files[[sub("manifest\\.", "", nm)]]
      if (!is.null(ids[[nm]])) G("drive_update")(G("as_id")(ids[[nm]]), media = src)
      else { up <- G("drive_upload")(src, path = G("as_id")(folder), name = nm); drive_cache_set(paste0("file:", folder, "/", nm), up$id[1]) }
    }
  }
  invisible(NULL)
}

# ── Save one export (several formats) ────────────────────────────────────────
# files: list of list(ext, mime, path); meta: list(group, topic, topic_label, section, title, step, steps, label)
export_save <- function(files, meta, backend = NULL, s = export_settings()) {
  backend <- backend %||% s$export_backend
  meta$section <- strip_symbols(meta$section); meta$title <- strip_symbols(meta$title)
  when <- Sys.time()
  eid <- paste0(format(when, "%Y%m%d-%H%M%S"), "-", paste(sample(c(0:9, letters[1:6]), 4, TRUE), collapse = ""))
  root_desc <- if (backend == "drive") paste0("drive:", if (nzchar(s$drive_root_id)) s$drive_root_id else s$drive_root_name) else s$local_root
  rows <- list()
  for (f in files) {
    p <- build_export_path(meta, f$ext, s$path_template, when, app = clean_folder(s$app_folder))
    res <- tryCatch(if (backend == "drive") drive_save(s, p$dirs, p$file, f$path) else local_save(s, p$dirs, p$file, f$path),
                    error = function(e) list(error = conditionMessage(e)))
    row <- data.frame(export_id = eid, created = format(when, "%Y-%m-%d %H:%M:%S"), backend = backend,
                      group = meta$group %||% "", topic = meta$topic_label %||% "", section = meta$section %||% "",
                      diagram = short_title(meta$title %||% ""), step = if (isTRUE(meta$steps > 0)) sprintf("%s/%s", meta$step, meta$steps) else "",
                      label = meta$label %||% "", format = f$ext, mime = EXPORT_MIME[[f$ext]] %||% "application/octet-stream",
                      file_name = p$file, folder_path = paste(p$dirs, collapse = "/"), rel_path = p$rel,
                      location = res$location %||% "", link = res$link %||% "", bytes = as.character(file.size(f$path)),
                      stringsAsFactors = FALSE)
    mem_insert("exports", list(ts = row$created, export_id = eid, backend = backend, root = root_desc, group_name = row$group, topic = row$topic,
      section = row$section, diagram = row$diagram, step = row$step, label = row$label, format = row$format, file_name = row$file_name,
      folder_path = row$folder_path, rel_path = row$rel_path, location = row$location, link = row$link, bytes = as.numeric(row$bytes),
      status = if (is.null(res$error)) "saved" else "failed", error = res$error %||% NA))
    row$error <- res$error %||% NA
    rows[[length(rows) + 1]] <- row
  }
  df <- do.call(rbind, rows)
  ok <- df[is.na(df$error), , drop = FALSE]
  mres <- tryCatch({ manifest_update(s, backend, ok); NULL }, error = function(e) conditionMessage(e))
  list(rows = df, manifest_error = mres, export_id = eid)
}

db_exports <- function(n = 500) head(db_table("exports", "id DESC"), n)

# ── App-level server: export dialog and payload handling ─────────────────────
# topic_info(tab) must return list(label =, group =)
export_server <- function(input, output, session, topic_info, bus) {
  ex <- reactiveValues(req = NULL)

  observeEvent(input$dsa_export_req, {
    r <- input$dsa_export_req
    ex$req <- r
    s <- export_settings()
    ti <- topic_info(r$topic)
    fmts <- EXPORT_FORMATS
    if (!(length(r$stepper) && nzchar(r$stepper %||% "") && isTRUE(r$steps > 1))) fmts <- fmts[fmts != "gif"]
    if (!isTRUE(r$plots > 0)) fmts <- fmts[fmts != "json"]
    sel <- intersect(strsplit(s$export_formats, ",")[[1]], fmts)
    dest_lab <- c("Google Drive (API)" = "drive", "Folder — e.g. a Google Drive for desktop folder" = "local", "Download to this computer" = "download")
    showModal(modalDialog(title = "⤓ Save diagram", size = "m", easyClose = TRUE,
      tags$div(class = "exp-meta", tags$b(r$title), tags$br(),
               tags$span(class = "hint", sprintf("%s › %s%s%s", ti$group, ti$label, if (nzchar(r$section %||% "")) paste0(" › ", r$section) else "",
                                                 if (isTRUE(r$steps > 0)) sprintf(" · step %s of %s", r$step, r$steps) else ""))),
      checkboxGroupInput("exp_formats", "Formats", choices = fmts, selected = if (length(sel)) sel else "png"),
      if ("gif" %in% fmts) fluidRow(
        column(6, numericInput("exp_gif_delay", "GIF frame delay (ms)", as.numeric(s$gif_delay), min = 150, max = 5000, step = 50)),
        column(6, numericInput("exp_gif_max", "Max frames", as.numeric(s$gif_max), min = 2, max = 120))),
      if ("gif" %in% fmts) hint("GIF and HTML step through every frame of this diagram's step player, then return it to the current step."),
      radioButtons("exp_dest", "Save to", choices = dest_lab, selected = s$export_backend),
      textInput("exp_label", "Label (optional, added to the file name)", "", placeholder = "e.g. worst-case input"),
      uiOutput("exp_preview"),
      footer = tagList(modalButton("Cancel"), actionButton("exp_go", "Save", class = "btn btn-dsa"))))
  })

  output$exp_preview <- renderUI({
    r <- ex$req; req(r)
    s <- export_settings(); ti <- topic_info(r$topic)
    dest <- input$exp_dest %||% s$export_backend
    meta <- list(group = ti$group, topic_label = ti$label, section = r$section, title = r$title, label = input$exp_label)
    p <- build_export_path(meta, "png", s$path_template, app = clean_folder(s$app_folder))
    root <- switch(dest, drive = paste0("Google Drive › ", if (nzchar(s$drive_root_id)) paste0("folder ", s$drive_root_id) else s$drive_root_name),
                   local = s$local_root, download = "Your browser's download folder")
    warn <- if (dest == "drive" && !isTRUE(.drv$ok) && !nzchar(s$drive_key_path) && s$drive_auth == "service")
      callout("Google Drive is not configured yet — open <b>APIs › Google Drive</b> first.", "warn")
    tagList(tags$div(class = "code-title", "Destination"),
            tags$pre(class = "exp-path", if (dest == "download") paste0(root, "\n", p$file) else paste0(root, "/\n", p$rel)),
            hint("Every format you tick is saved with the same name and its own extension (.png, .pdf, .gif …). Missing folders are created automatically."), warn)
  })

  observeEvent(input$exp_go, {
    r <- ex$req; req(r)
    fm <- input$exp_formats
    if (!length(fm)) { showNotification("Choose at least one format.", type = "warning"); return() }
    s <- export_settings(); ti <- topic_info(r$topic)
    setting_set("export_formats", paste(fm, collapse = ","))
    setting_set("export_backend", input$exp_dest)
    if (!is.null(input$exp_gif_delay)) setting_set("gif_delay", input$exp_gif_delay)
    if (!is.null(input$exp_gif_max)) setting_set("gif_max", input$exp_gif_max)
    ex$label <- input$exp_label; ex$dest <- input$exp_dest
    p <- build_export_path(list(group = ti$group, topic_label = ti$label, section = r$section, title = r$title, label = input$exp_label),
                           "x", s$path_template, app = clean_folder(s$app_folder))
    removeModal()
    ex$nonce <- as.numeric(Sys.time()) * 1000
    session$sendCustomMessage("dsa-export-run", list(box = r$box, formats = as.list(fm), destination = input$exp_dest, stem = p$stem,
      gif_delay = as.numeric(input$exp_gif_delay %||% s$gif_delay), gif_max = as.numeric(input$exp_gif_max %||% s$gif_max),
      nonce = ex$nonce, topic_label = ti$label))
  })

  observeEvent(input$dsa_export_payload, {
    pl <- input$dsa_export_payload
    r <- ex$req
    if (!is.null(pl$error)) { showNotification(paste("Export failed:", pl$error), type = "error", duration = 10); return() }
    ti <- topic_info(r$topic)
    meta <- list(group = ti$group, topic = r$topic, topic_label = ti$label, section = r$section, title = r$title,
                 step = r$step, steps = r$steps, label = ex$label)
    if (isTRUE(pl$downloaded)) {
      showNotification(sprintf("Downloaded %d file(s) to this computer.", length(pl$files)), type = "message")
      return()
    }
    tmpdir <- tempfile("export"); dir.create(tmpdir)
    files <- lapply(pl$files, function(f) {
      path <- file.path(tmpdir, paste0("f.", f$ext))
      writeBin(base64enc::base64decode(f$data), path)
      list(ext = f$ext, mime = f$mime, path = path)
    })
    session$sendCustomMessage("dsa-export-status", list(text = sprintf("Saving %d file(s) to %s…", length(files), if (ex$dest == "drive") "Google Drive" else "the folder")))
    res <- export_save(files, meta, backend = ex$dest)
    session$sendCustomMessage("dsa-export-status", list(text = ""))
    unlink(tmpdir, recursive = TRUE)
    d <- res$rows; ok <- is.na(d$error)
    bus$export_tick <- (bus$export_tick %||% 0) + 1
    msg <- if (all(ok)) {
      tagList(tags$b(sprintf("Saved %d file(s).", sum(ok))), tags$br(), tags$code(d$folder_path[1]), tags$br(),
              lapply(seq_len(nrow(d)), function(i) tags$a(href = d$link[i], target = "_blank", style = "margin-right:8px;", toupper(d$format[i]))),
              if (!is.null(res$manifest_error)) tags$div(style = "color:#b45309;", paste("Manifest not updated:", res$manifest_error)))
    } else tagList(tags$b(sprintf("%d of %d file(s) failed.", sum(!ok), nrow(d))), tags$br(), d$error[!ok][1])
    showNotification(msg, type = if (all(ok)) "message" else "error", duration = 12)
  })
}
