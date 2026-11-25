# modules/chart_export.R - the "Save" dialog and the Google Drive upload pipeline.
# The browser (www/export.js) renders each chart into the chosen formats and
# streams them here in chunks; each finished file is put into its folder
# (folders are created as needed), optionally copied to a fixed "latest" file,
# and listed in the shared catalogue _catalog/manifest.csv.

EXPORT_FORMATS <- c("Interactive HTML" = "html", "PNG" = "png", "SVG (vector)" = "svg", "PDF" = "pdf",
                    "GIF" = "gif", "JPEG" = "jpeg", "WebP" = "webp", "Plotly JSON" = "json",
                    "Chart data (CSV)" = "csv")
FORMAT_MIME <- c(html = "text/html", png = "image/png", svg = "image/svg+xml", pdf = "application/pdf",
                 gif = "image/gif", jpeg = "image/jpeg", webp = "image/webp", json = "application/json",
                 csv = "text/csv")
# TAB_LABELS / TAB_GROUPS (page id -> page label / main group label) are built
# from modules/_module_registry.yml in app.R, so saved files follow the sidebar.

lookup <- function(v, k, default) {
  x <- if (is.null(k) || !nzchar(k)) NA else v[k]
  if (length(x) == 0 || is.na(x)) default else unname(x)
}

# Everything a file name / folder needs to know about one chart.
export_meta <- function(chart, app, scheme, p) {
  tab <- chart$tab %||% ""
  live <- identical(app$mode, "live")
  rt <- identical(tab, "realtime")
  list(app = scheme$app_name,
       property = if (live) paste0("GA4-", app$property_id) else "Demo data",
       group = lookup(TAB_GROUPS, tab, "Website Analytics"),
       tab = lookup(TAB_LABELS, tab, if (nzchar(tab)) tab else "Other"),
       chart = chart$title, mode = if (live) "live" else "demo",
       start = if (rt) Sys.Date() else p$start, end = if (rt) Sys.Date() else p$end)
}

export_subtitle <- function(chart, app, p) {
  src <- if (identical(app$mode, "live")) paste("GA4 property", app$property_id) else "DEMO DATA - invented numbers"
  if (identical(chart$tab, "realtime")) return(paste0("Last 30 minutes at ", format(Sys.time(), "%H:%M %d %b %Y"), " · ", src))
  cmp <- if (p$compare == "none") "" else
    sprintf(" (compared with %s - %s)", format(p$cmp_start, "%d %b %Y"), format(p$cmp_end, "%d %b %Y"))
  sprintf("%s - %s%s · %s", format(p$start, "%d %b %Y"), format(p$end, "%d %b %Y"), cmp, src)
}

# Builds folder segments + file names for every chart x format.
plan_export <- function(charts, formats, app, scheme, p, now) {
  lapply(charts, function(ch) {
    meta <- export_meta(ch, app, scheme, p)
    files <- lapply(formats, function(fmt) {
      tk <- scheme_tokens(meta, fmt, now)
      segs <- resolve_folder(scheme$folder_template, tk)
      name <- resolve_file(scheme$file_template, tk, fmt)
      list(segs = segs, name = name, path = paste(c(segs, name), collapse = "/"),
           latest_segs = if (isTRUE(scheme$latest)) resolve_folder(scheme$latest_template, tk) else NULL,
           latest_name = latest_file_name(tk, fmt))
    })
    names(files) <- formats
    c(ch, list(meta = meta, subtitle = export_subtitle(ch, app, p), files = files))
  })
}

chart_export_server <- function(input, output, session, app, drive, period) {

  requests <- new.env(parent = emptyenv())
  opened <- reactiveVal(NULL)

  drive_ready <- function() identical(drive$status, "connected") && !is.null(drive$d)

  # ---- 1. Dialog ------------------------------------------------------------
  observeEvent(input$atera_save_open, {
    msg <- tryCatch(jsonlite::fromJSON(input$atera_save_open, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(msg) || length(msg$charts) == 0) return()
    opened(msg)
    n <- length(msg$charts)
    titles <- vapply(msg$charts, function(c) c$title %||% c$id, character(1))
    sch <- drive$scheme
    showModal(modalDialog(
      title = if (n == 1) paste("Save chart:", titles[1]) else sprintf("Save %d charts from this page", n),
      size = "m", easyClose = TRUE,
      if (n > 1) tags$p(class = "ga-card-sub", paste(titles, collapse = " · ")),
      if (isTRUE(msg$skipped > 0)) note_box(kind = "warn", icon("exclamation-triangle"),
        sprintf(" %d chart(s) on this page have no data drawn and will be skipped.", msg$skipped)),
      checkboxGroupInput("exp_formats", "Formats", choices = EXPORT_FORMATS,
                         selected = sch$default_formats, inline = TRUE),
      radioButtons("exp_dest", "Save to", inline = TRUE,
                   choices = c("Google Drive" = "drive", "My computer" = "local", "Both" = "both"),
                   selected = if (drive_ready()) "drive" else "local"),
      if (!drive_ready()) note_box(kind = "warn", icon("info-circle"),
        " Google Drive is not connected, so only 'My computer' will work. Set it up in ",
        tags$b("API Configuration > Google Drive"), "."),
      fluidRow(
        column(6, checkboxInput("exp_animate", "Animate GIFs of time charts", value = TRUE)),
        column(6, checkboxInput("exp_dark", "Dark background (for slides)", value = FALSE))
      ),
      uiOutput("exp_preview"),
      footer = tagList(modalButton("Cancel"),
                       actionButton("exp_go", "Save", icon = icon("upload"), class = "btn-primary"))
    ))
  })

  output$exp_preview <- renderUI({
    msg <- opened(); req(msg)
    fmts <- input$exp_formats %||% character(0)
    if (length(fmts) == 0) return(note_box(kind = "warn", "Tick at least one format."))
    plan <- plan_export(msg$charts[1], fmts[1], app, drive$scheme, period(), Sys.time())[[1]]$files[[1]]
    dest <- input$exp_dest %||% "local"
    tagList(
      tags$div(class = "ga-card-sub", if (dest == "local") "Inside the download (same layout as Google Drive):"
                                      else "Google Drive location (folders are created if missing):"),
      tags$div(class = "path-preview", paste0(if (dest == "local") "" else paste0(drive$root_name %||% "root", "/"),
                                              plan$path)),
      if (isTRUE(drive$scheme$latest) && dest != "local")
        tags$div(class = "ga-card-sub", "Latest copy: ",
                 tags$code(paste(c(plan$latest_segs, plan$latest_name), collapse = "/")))
    )
  })

  # ---- 2. Start ---------------------------------------------------------------
  observeEvent(input$exp_go, {
    msg <- opened(); req(msg)
    fmts <- input$exp_formats %||% character(0)
    dest <- input$exp_dest %||% "local"
    if (length(fmts) == 0) { showNotification("Tick at least one format.", type = "warning"); return() }
    if (dest != "local" && !drive_ready()) {
      showNotification("Google Drive is not connected - choose 'My computer' or connect Drive first.", type = "error")
      return()
    }
    removeModal()
    now <- Sys.time(); p <- period()
    plan <- plan_export(msg$charts, fmts, app, drive$scheme, p, now)
    req_id <- paste0(format(now, "%Y%m%d%H%M%S"), "-", paste(sample(c(letters, 0:9), 6, TRUE), collapse = ""))
    src_label <- if (identical(app$mode, "live")) paste("Atera Analytics · GA4 property", app$property_id)
                 else "Atera Analytics · DEMO DATA"

    if (dest != "local") {
      r <- new.env(parent = emptyenv())
      r$plan <- stats::setNames(plan, vapply(plan, function(x) x$id, character(1)))
      r$total <- length(plan) * length(fmts); r$done <- 0; r$ok <- 0; r$fail <- 0
      r$errors <- character(0); r$rows <- list(); r$folders <- character(0)
      r$chunks <- new.env(parent = emptyenv()); r$now <- now; r$p <- p
      r$notif <- paste0("exp-", req_id)
      assign(req_id, r, envir = requests)
      showNotification(sprintf("Saving %d file(s) to Google Drive...", r$total), id = r$notif,
                       duration = NULL, closeButton = FALSE, type = "message")
    }
    cat(sprintf("[EXPORT] %s: %d chart(s) x %s -> %s\n", req_id, length(plan),
                paste(fmts, collapse = ","), dest))

    session$sendCustomMessage("atera-export", list(
      req = req_id, dest = dest, formats = as.list(fmts),
      animate = isTRUE(input$exp_animate), light = !isTRUE(input$exp_dark),
      source = src_label, saved_at = format(now, "%d %b %Y %H:%M"),
      zip_name = sprintf("atera_%s_%s.zip", slugify(plan[[1]]$meta$tab), format(now, "%Y%m%d-%H%M%S")),
      charts = lapply(plan, function(x) list(
        id = x$id, title = x$title, tab = x$tab, tab_label = x$meta$tab, subtitle = x$subtitle,
        paths = lapply(x$files, function(f) f$path)))
    ))
  })

  # ---- 3. Receive + upload ------------------------------------------------------
  upload_one <- function(r, chart_id, ext, bytes) {
    ch <- r$plan[[chart_id]]; f <- ch$files[[ext]]
    d <- drive$d
    mime <- lookup(FORMAT_MIME, ext, "application/octet-stream")
    res <- with_folder_retry(d, function() {
      folder <- drive_ensure_path(d, f$segs)
      up <- drive_upload_bytes(d, bytes, f$name, mime, parent = folder$id)
      latest_id <- ""
      if (!is.null(f$latest_segs)) {
        lf <- drive_ensure_path(d, f$latest_segs)
        latest_id <- drive_upsert(d, bytes, f$latest_name, mime, lf$id)$id %||% ""
      }
      list(up = up, folder = folder, latest_id = latest_id)
    })
    r$folders <- unique(c(r$folders, res$folder$link))
    m <- ch$meta
    r$rows[[length(r$rows) + 1]] <- data.frame(
      saved_at = format(r$now, "%Y-%m-%d %H:%M:%S"), app = m$app, data_mode = m$mode, property = m$property,
      group = m$group, tab = m$tab, chart = m$chart, chart_id = chart_id, format = ext,
      file_name = f$name, folder_path = res$folder$path, file_id = res$up$id %||% "",
      web_view_link = res$up$webViewLink %||% "", mime_type = mime,
      size_bytes = as.character(length(bytes)), period_start = format(as.Date(m$start)),
      period_end = format(as.Date(m$end)), comparison = r$p$compare, latest_file_id = res$latest_id,
      request_id = "", stringsAsFactors = FALSE)
    cat(sprintf("[EXPORT] Uploaded %s/%s (%s bytes)\n", res$folder$path, f$name, format(length(bytes), big.mark = ",")))
  }

  progress <- function(r) {
    showNotification(sprintf("Saving to Google Drive: %d of %d files done%s", r$done, r$total,
                             if (r$fail) sprintf(" (%d failed)", r$fail) else ""),
                     id = r$notif, duration = NULL, closeButton = FALSE, type = "message")
  }

  finish <- function(req_id, r) {
    removeNotification(r$notif)
    rows <- if (length(r$rows)) do.call(rbind, r$rows) else NULL
    if (!is.null(rows)) {
      rows$request_id <- req_id
      ok <- tryCatch({ drive_append_manifest(drive$d, drive$scheme$app_name, rows); TRUE },
        error = function(e) {
          cat("[EXPORT] Could not update manifest.csv:", conditionMessage(e), "\n")
          r$errors <- c(r$errors, paste("Catalogue not updated:", conditionMessage(e))); FALSE
        })
      drive$history <- rbind(rows, drive$history)
      drive$tick <- isolate(drive$tick) + 1
    }
    msg <- if (r$ok > 0) {
      tagList(sprintf("Saved %d file(s) to Google Drive%s. ", r$ok,
                      if (r$fail) sprintf(", %d failed", r$fail) else ""),
              if (length(r$folders)) tags$a(href = r$folders[1], target = "_blank", "Open folder"))
    } else "Nothing was saved to Google Drive."
    showNotification(tagList(msg, if (length(r$errors))
      tags$div(class = "notif-errors", paste(utils::head(unique(r$errors), 3), collapse = "\n"))),
      type = if (r$fail || r$ok == 0) "warning" else "message", duration = if (r$fail) NULL else 10)
    cat(sprintf("[EXPORT] %s finished: %d ok, %d failed\n", req_id, r$ok, r$fail))
    if (length(r$errors)) cat("[EXPORT] Errors:\n", paste(" -", unique(r$errors), collapse = "\n"), "\n")
    rm(list = req_id, envir = requests)
  }

  observeEvent(input$atera_export_msg, {
    m <- tryCatch(jsonlite::fromJSON(input$atera_export_msg, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(m) || is.null(m$req) || !exists(m$req, envir = requests, inherits = FALSE)) return()
    r <- get(m$req, envir = requests)

    if (identical(m$type, "file")) {
      key <- paste(m$chart_id, m$ext)
      buf <- r$chunks[[key]] %||% character(m$n_chunks)
      buf[m$chunk + 1] <- m$data
      if (any(!nzchar(buf))) { r$chunks[[key]] <- buf; return() }
      if (exists(key, envir = r$chunks, inherits = FALSE)) rm(list = key, envir = r$chunks)
      bytes <- jsonlite::base64_dec(paste(buf, collapse = ""))
      ok <- tryCatch({ upload_one(r, m$chart_id, m$ext, bytes); TRUE }, error = function(e) {
        r$errors <- c(r$errors, conditionMessage(e))
        cat("[EXPORT ERROR]", m$chart_id, m$ext, ":", conditionMessage(e), "\n"); FALSE
      })
      r$done <- r$done + 1
      if (ok) r$ok <- r$ok + 1 else r$fail <- r$fail + 1
      progress(r)
    } else if (identical(m$type, "skip")) {
      n <- if (is.null(m$ext)) length(r$plan[[m$chart_id]]$files) else 1
      r$done <- r$done + n; r$fail <- r$fail + n
      r$errors <- c(r$errors, sprintf("%s%s: %s", r$plan[[m$chart_id]]$title %||% m$chart_id,
                                      if (is.null(m$ext)) "" else paste0(" (", m$ext, ")"), m$reason %||% "failed"))
      progress(r)
    } else if (identical(m$type, "done")) {
      if (!is.null(m$error)) r$errors <- c(r$errors, paste("Browser:", m$error))
      finish(m$req, r)
    }
  })
}
