# R/utils_diagram_export.R
# "Save diagram" bar for every tab that shows a diagram: tick formats, then "Save to Google Drive" or
# "Download (zip)". The picture is taken in the browser (www/js/bos_diagram.js) and turned into the other
# formats here with magick. Drive placement: <app folder>/<Group>/<Section>/<Tab>/<YYYY>/<YYYY-MM>/... (R/utils_gdrive.R)
#
# Use in a module:
#   UI:     diagram_save_ui(ns("save_chart"), formats = c("html", "pdf", "png", "jpg", "gif", "tiff", "svg", "csv"))
#   server: diagram_save_server("save_chart", tab_id = "analytics", target = session$ns("wordPlot"), kind = "plotly",
#                               spec = function() list(title = "Word Count", plot = p, data = df))
# spec() returns: title, subtitle, plot (a plotly object: its HTML is the interactive chart), html (a ready page),
# data (data.frame: CSV + table in the image page), source = c(ext, text), vector_svg (real SVG text), bg (colour behind
# an HTML capture), ready (FALSE = nothing to save yet, with `why`).

DIAGRAM_FORMATS <- c(html = "HTML", pdf = "PDF", png = "PNG", jpg = "JPG", gif = "GIF", tiff = "TIFF", svg = "SVG", csv = "CSV data", source = "Source")
DIAGRAM_IMAGE_FORMATS <- c("pdf", "png", "jpg", "gif", "tiff", "svg")

# js + css for the bar; added once to the page head (global.R)
diagram_export_head <- function() tagList(
  tags$script(src = "js/bos_diagram.js"),
  tags$style(HTML("
    .bos-diagram-save { margin-top: 10px; padding: 10px 12px; border: 1px solid #b2dfdb; border-left: 4px solid #008A82; border-radius: 8px; background: #f8fafa; }
    .bos-diagram-save .bos-ds-title { font-weight: 600; margin-bottom: 4px; display: block; color: #002C3C; }
    .bos-diagram-save .bos-ds-link { margin-top: 4px; }
    .bos-gd-example pre { white-space: pre-wrap; word-break: break-all; }
    .bos-diagram-save .checkbox-inline { margin-right: 10px; }
    .bos-diagram-save .btn { margin: 4px 6px 4px 0; }
    .bos-diagram-save .bos-ds-status { margin-top: 6px; white-space: pre-wrap; font-size: 12.5px; }
    .bos-ds-ok { color: #00796b; } .bos-ds-err { color: #c0392b; } .bos-ds-busy { color: #b9770e; }
  ")))

diagram_save_ui <- function(id, formats = c("html", DIAGRAM_IMAGE_FORMATS), title = "Save diagram") {
  ns <- NS(id)
  defaults <- tryCatch(gd_load_settings()$default_formats, error = function(e) c("html", "pdf", "png"))
  selected <- intersect(c(defaults, "csv", "source"), formats)
  tags$div(class = "bos-diagram-save",
    tags$span(class = "bos-ds-title", icon("save"), " ", title),
    checkboxGroupInput(ns("formats"), NULL, choices = setNames(formats, DIAGRAM_FORMATS[formats]), selected = selected, inline = TRUE),
    actionButton(ns("to_drive"), "Save to Google Drive", icon = icon("google-drive"), class = "btn-primary"),
    actionButton(ns("to_zip"), "Download (zip)", icon = icon("download"), class = "btn-info"),
    tags$div(style = "display:none", downloadButton(ns("dl"), "download")),
    uiOutput(ns("status")))
}

# Group / Section / Tab names of a module, from the registry (they become the folder names).
diagram_placement <- function(tab_id, diagram, at = Sys.time()) {
  reg <- if (exists("loader")) loader$registry else NULL
  group <- "Other"; section <- ""; tab <- tab_id
  if (!is.null(reg)) for (g in reg$groups) if (tab_id %in% unlist(g$modules)) {
    group <- g$label; section <- g$label
    tab <- reg$modules[[tab_id]]$label %|g|% tab_id
    for (sc in g$sections) if (tab_id %in% unlist(sc$modules)) {
      section <- sc$label
      tab <- sc$tab_labels[[tab_id]] %|g|% tab
    }
  }
  gd_placement(group, section, tab, tab_id, diagram, at)
}

# Drive client for this browser session (rebuilt when the settings file changes).
gd_session_client <- function(session) {
  s <- gd_load_settings()
  sa <- tryCatch(cred_local()$json_path, error = function(e) NA)
  key <- paste(unlist(s[c("auth_mode", "client_id", "refresh_token", "key_file", "impersonate", "root_folder", "app_folder", "by_date", "by_format")]), sa, collapse = "|")
  ud <- session$userData
  if (is.null(ud$gdrive) || !identical(ud$gdrive_key, key)) {
    ud$gdrive <- GDrive$new(s, sa_path = sa)
    ud$gdrive_key <- key
  } else ud$gdrive$settings <- s
  ud$gdrive
}

# list of uploads made in this session (shown in API Settings > Google Drive)
gd_session_uploads <- function(session) {
  if (is.null(session$userData$gdrive_uploads)) session$userData$gdrive_uploads <- reactiveVal(data.frame(
    time = character(0), tab = character(0), file = character(0), folder = character(0), link = character(0), stringsAsFactors = FALSE))
  session$userData$gdrive_uploads
}

# ------------------------------------------------------------------ formats

diagram_png_raw <- function(data_url) openssl::base64_decode(sub("^data:image/png;base64,", "", data_url))

plotly_page_html <- function(p, title) {
  b <- plotly::plotly_build(p)$x
  fig <- list(data = b$data, layout = b$layout, config = list(responsive = TRUE, displaylogo = FALSE))
  json <- tryCatch(getFromNamespace("to_JSON", "plotly")(fig),
                   error = function(e) jsonlite::toJSON(fig, auto_unbox = TRUE, force = TRUE, null = "null", na = "null", digits = NA))
  paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
         '<title>', htmltools::htmlEscape(title), '</title><script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script>',
         '<style>body{font-family:system-ui,Segoe UI,Roboto,sans-serif;margin:20px}#p{width:100%;height:80vh}</style></head><body>',
         '<h2>', htmltools::htmlEscape(title), '</h2><div id="p"></div><script>var fig=', json,
         ';Plotly.newPlot("p",fig.data,fig.layout||{},fig.config||{});</script></body></html>')
}

diagram_image_page <- function(title, subtitle, png, data = NULL) {
  tbl <- ""
  if (is.data.frame(data) && nrow(data)) {
    esc <- htmltools::htmlEscape
    tbl <- paste0("<table><thead><tr>", paste0("<th>", esc(names(data)), "</th>", collapse = ""), "</tr></thead><tbody>",
                  paste0(apply(data, 1, function(r) paste0("<tr>", paste0("<td>", esc(ifelse(is.na(r), "", as.character(r))), "</td>", collapse = ""), "</tr>")), collapse = ""),
                  "</tbody></table>")
  }
  paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>',
         htmltools::htmlEscape(title), '</title><style>body{font-family:system-ui,Segoe UI,Roboto,sans-serif;margin:24px;color:#1d2433}',
         'img{max-width:100%;height:auto;border:1px solid #dde2ea;border-radius:8px}table{border-collapse:collapse;margin-top:20px;font-size:13px}',
         'th,td{border:1px solid #dde2ea;padding:5px 9px;text-align:left;vertical-align:top}th{background:#f2f4f8}footer{margin-top:20px;color:#8a93a5;font-size:12px}</style></head><body>',
         '<h1>', htmltools::htmlEscape(title), '</h1>', if (nzchar(subtitle %|g|% "")) paste0('<p>', htmltools::htmlEscape(subtitle), '</p>') else "",
         '<img alt="', htmltools::htmlEscape(title), '" src="data:image/png;base64,', openssl::base64_encode(png), '">', tbl,
         '<footer>Business Operations Suite - ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</footer></body></html>')
}

diagram_pdf <- function(img) {
  info <- magick::image_info(img)
  landscape <- info$width > info$height
  pw <- if (landscape) 1754 else 1240; ph <- if (landscape) 1240 else 1754   # A4 at 150 dpi
  m <- 60
  fit <- magick::image_resize(img, sprintf("%dx%d", pw - 2 * m, ph - 2 * m))
  page <- magick::image_composite(magick::image_blank(pw, ph, "white"), fit, gravity = "center")
  out <- tryCatch(magick::image_write(page, format = "pdf", density = "150x150", compression = "Zip"), error = function(e) NULL)   # lossless, ~10x smaller
  if (is.null(out)) {   # fall back to R's own pdf device
    f <- tempfile(fileext = ".pdf")
    grDevices::pdf(f, width = pw / 150, height = ph / 150); graphics::par(mar = c(0, 0, 0, 0))
    graphics::plot.new(); graphics::rasterImage(as.raster(page), 0, 0, 1, 1); grDevices::dev.off()
    out <- readBin(f, "raw", file.size(f)); unlink(f)
  }
  out
}

# Builds list(list(format, ext, bytes), ...) for the chosen formats.
diagram_build_files <- function(spec, formats, png = NULL) {
  out <- list()
  img <- NULL
  if (!is.null(png)) img <- magick::image_flatten(magick::image_background(magick::image_read(png), spec$bg %|g|% "white"))
  enc <- function(x) charToRaw(enc2utf8(x))
  for (f in intersect(names(DIAGRAM_FORMATS), formats)) {
    bytes <- switch(f,
      html = enc(if (!is.null(spec$html)) spec$html
                 else if (!is.null(spec$plot)) plotly_page_html(spec$plot, spec$title)
                 else diagram_image_page(spec$title, spec$subtitle, png, spec$data)),
      pdf = diagram_pdf(img),
      png = png,
      jpg = magick::image_write(img, format = "jpeg", quality = 92),
      gif = magick::image_write(img, format = "gif"),
      tiff = magick::image_write(img, format = "tiff", compression = "LZW"),
      svg = enc(if (!is.null(spec$vector_svg)) spec$vector_svg else {
        i <- magick::image_info(img)
        sprintf('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d" viewBox="0 0 %d %d"><image width="%d" height="%d" xlink:href="data:image/png;base64,%s"/></svg>',
                i$width, i$height, i$width, i$height, i$width, i$height, openssl::base64_encode(png))
      }),
      csv = enc(paste0(paste(utils::capture.output(utils::write.csv(spec$data, row.names = FALSE)), collapse = "\n"), "\n")),
      source = enc(spec$source[2]))
    ext <- if (f == "source") spec$source[1] else f
    out[[length(out) + 1]] <- list(format = if (f == "source") spec$source[1] else f, ext = ext, bytes = bytes)
  }
  out
}

# Which formats this diagram can give right now.
diagram_available <- function(spec) {
  has_pixels <- !isFALSE(spec$pixels)
  c(if (has_pixels) c("html", DIAGRAM_IMAGE_FORMATS) else if (!is.null(spec$html) || !is.null(spec$plot)) "html",
    if (is.data.frame(spec$data) && nrow(spec$data)) "csv",
    if (length(spec$source) == 2) "source")
}

# ------------------------------------------------------------------ server

# also: optional function(files) run after a successful "Save to Google Drive"; returns a note line (or NULL).
#       Funding Programmes uses it to put the same files in CollaborationPlanning's Country/Category/Topic folders.
diagram_save_server <- function(id, tab_id, target, kind = c("plotly", "html"), spec, also = NULL) {
  kind <- match.arg(kind)
  moduleServer(id, function(input, output, session) {
    pending <- reactiveVal(NULL)   # list(action, nonce, formats, spec)
    zip_file <- reactiveVal(NULL)
    status <- function(cls, ...) output$status <- renderUI(tags$div(class = paste("bos-ds-status", cls), paste0(...)))

    start <- function(action) {
      sp <- tryCatch(spec(), error = function(e) list(ready = FALSE, why = conditionMessage(e)))
      if (isFALSE(sp$ready)) return(status("bos-ds-err", sp$why %|g|% "Nothing to save yet."))
      fm <- intersect(input$formats %|g|% character(0), diagram_available(sp))
      if (!length(fm)) return(status("bos-ds-err", "Choose at least one format."))
      if (action == "drive" && !gd_configured(gd_load_settings(), tryCatch(cred_local()$json_path, error = function(e) NA)))
        return(status("bos-ds-err", "Google Drive is not set up yet: open API Settings > Google Drive, sign in and choose the folder."))
      need_png <- any(fm %in% DIAGRAM_IMAGE_FORMATS) || ("html" %in% fm && is.null(sp$html) && is.null(sp$plot))
      job <- list(action = action, nonce = paste0(as.numeric(Sys.time()), sample.int(1e6, 1)), formats = fm, spec = sp)
      if (need_png) {
        pending(job)
        status("bos-ds-busy", "Taking the picture of the diagram...")
        session$sendCustomMessage("bos-capture", list(target = target, kind = kind, input = session$ns("captured"), nonce = job$nonce, bg = sp$bg %|g|% "#ffffff"))
      } else finish(job, NULL)
    }

    finish <- function(job, png) {
      files <- tryCatch(diagram_build_files(job$spec, job$formats, png), error = function(e) e)
      if (inherits(files, "error")) return(status("bos-ds-err", "The files could not be made: ", conditionMessage(files)))
      where <- diagram_placement(tab_id, job$spec$title)
      if (job$action == "zip") {
        dir <- tempfile("diagram_"); dir.create(dir)
        s <- gd_load_settings()
        for (f in files) {
          sub <- do.call(file.path, as.list(c(dir, gd_folders(where, s, f$ext))))
          dir.create(sub, recursive = TRUE, showWarnings = FALSE)
          writeBin(f$bytes, file.path(sub, gd_file_name(where, f$ext)))
        }
        z <- file.path(tempdir(), paste0(gd_slug(tab_id, 32), "_", gd_slug(job$spec$title), "_", format(where$at, "%Y%m%d_%H%M%S"), ".zip"))
        zip::zipr(z, list.files(dir, full.names = TRUE), recurse = TRUE)
        zip_file(z)
        status("bos-ds-ok", sprintf("✓ %d file(s) ready - the download starts now.", length(files)))
        session$sendCustomMessage("bos-download", list(id = session$ns("dl")))
        return()
      }
      res <- tryCatch({
        g <- gd_session_client(session)
        up <- lapply(files, function(f) g$save(where, f$ext, f$bytes))
        note <- ""
        if (isTRUE(g$settings$manifest)) note <- tryCatch({
          g$append_manifest(Map(function(f, u) gd_manifest_row(where, f$format, u, g$settings$device_note), files, up)); paste0("\n", GD_MANIFEST, " updated.")
        }, error = function(e) paste0("\n⚠ Files uploaded, but ", GD_MANIFEST, " was not updated: ", conditionMessage(e)))
        if (is.function(also)) note <- paste0(note, tryCatch({ x <- also(files); if (length(x)) paste0("\n", x) else "" },
                                                            error = function(e) paste0("\n⚠ Not copied to CollaborationPlanning's folder: ", conditionMessage(e))))
        list(up = up, note = note)
      }, error = function(e) e)
      if (inherits(res, "error")) return(status("bos-ds-err", "Not uploaded: ", conditionMessage(res)))
      ul <- gd_session_uploads(session)
      ul(rbind(ul(), data.frame(time = format(Sys.time(), "%H:%M:%S"), tab = where$tab, file = vapply(res$up, `[[`, "", "name"),
                                  folder = vapply(res$up, `[[`, "", "path"), link = vapply(res$up, `[[`, "", "link"), stringsAsFactors = FALSE)))
      for (u in res$up) cat(sprintf("[Drive] uploaded %s/%s (%s)\n", u$path, u$name, u$id))
      first <- res$up[[1]]
      output$status <- renderUI(tagList(
        tags$div(class = "bos-ds-status bos-ds-ok",
          sprintf("✓ Uploaded %d file(s) to Google Drive\nFolder: %s\n%s%s", length(res$up), first$path,
                  paste0("• ", vapply(res$up, `[[`, "", "name"), collapse = "\n"), res$note)),
        if (nzchar(first$link)) tags$div(class = "bos-ds-link", tags$a(href = first$link, target = "_blank", icon("external-link-alt"), " Open in Drive"))))
    }

    observeEvent(input$to_drive, start("drive"))
    observeEvent(input$to_zip, start("zip"))
    observeEvent(input$captured, {
      job <- pending(); m <- input$captured
      if (is.null(job) || !identical(m$nonce, job$nonce)) return()
      pending(NULL)
      if (!is.null(m$error)) return(status("bos-ds-err", "The picture could not be taken: ", m$error))
      status("bos-ds-busy", if (job$action == "drive") "Uploading to Google Drive..." else "Preparing the files...")
      finish(job, diagram_png_raw(m$png))
    })
    output$dl <- downloadHandler(
      filename = function() basename(zip_file() %|g|% "diagram.zip"),
      content = function(file) file.copy(zip_file(), file, overwrite = TRUE),
      contentType = "application/zip")
    outputOptions(output, "dl", suspendWhenHidden = FALSE)   # the link sits in a hidden div
  })
}

# ------------------------------------------------------------------ generated diagrams (Diagram Generator, Claude Diagrams)

# Mermaid preview: white panel, labels as plain SVG text (so the picture can be taken), rendered once mermaid.js is there.
diagram_mermaid_ui <- function(code) tags$div(
  style = "border: 2px solid #00A39A; padding: 20px; background: white; border-radius: 8px;",
  tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"),
  tags$div(class = "mermaid", code),
  tags$script(HTML("(function run(n){ if (window.mermaid) { mermaid.initialize({startOnLoad:false, securityLevel:'loose', flowchart:{htmlLabels:false}});
                     mermaid.run({querySelector: '.mermaid:not([data-processed])'}); } else if (n < 100) setTimeout(function(){ run(n + 1); }, 100); })(0);")))

# A stand-alone page for generated code (the .html file saved to Drive).
diagram_code_page <- function(code, type, title) {
  if (type == "html") return(code)
  head <- paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><title>', htmltools::htmlEscape(title),
                 '</title><style>body{font-family:system-ui,Segoe UI,Roboto,sans-serif;margin:24px;background:#fff}</style>')
  if (type == "mermaid")
    return(paste0(head, '<script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"></script></head><body><h2>', htmltools::htmlEscape(title),
                  '</h2><pre class="mermaid">', htmltools::htmlEscape(code), '</pre><script>mermaid.initialize({startOnLoad:true});</script></body></html>'))
  paste0(head, '</head><body><h2>', htmltools::htmlEscape(title), '</h2>', code, '</body></html>')
}

# spec() for a generated diagram: code + its type ("svg", "html", "mermaid")
diagram_code_spec <- function(code, type, kind_label, instructions, who) {
  if (is.null(code) || !nzchar(code)) return(list(ready = FALSE, why = "Generate a diagram first."))
  words <- paste(head(strsplit(trimws(instructions %|g|% ""), "\\s+")[[1]], 6), collapse = " ")
  title <- paste0(kind_label %|g|% "Diagram", if (nzchar(words)) paste0(" - ", words) else "")
  list(title = title, subtitle = sprintf("Generated by %s as %s", who, type), html = diagram_code_page(code, type, title),
       vector_svg = if (type == "svg" && grepl("<svg", code, fixed = TRUE)) regmatches(code, regexpr("(?s)<svg.*</svg>", code, perl = TRUE)) else NULL,
       source = if (type == "mermaid") c("mmd", code) else NULL, bg = "#ffffff")
}

# HTML fragment -> plain text (canvas boxes in the CSV / table)
diagram_plain <- function(x) {
  x <- gsub("(?i)<br\\s*/?>|</p>|</li>|<hr\\s*/?>", "\n", x %|g|% "", perl = TRUE)
  x <- gsub("<[^>]+>", "", x)
  x <- gsub("&nbsp;", " ", gsub("&amp;", "&", gsub("&lt;", "<", gsub("&gt;", ">", gsub("&quot;", "\"", gsub("&#39;", "'", x))))))
  trimws(gsub("\n{2,}", "\n", gsub("[ \t]+", " ", x)))
}
