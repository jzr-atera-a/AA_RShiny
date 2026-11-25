# R/utils_diagram.R
# =============================================================================
# Diagram engine: every visualisation tab describes its view as a small
# "diagram spec" (a plain list), and this file draws that spec with base R
# graphics or grid and writes it as PNG, PDF, SVG, HTML or animated GIF.
#
# Used by the Save-to-Google-Drive boxes (R/utils_drive_export.R) and can be
# used for any local export. Only base R packages are needed (grDevices,
# grid, jsonlite, htmltools), so nothing extra has to be installed for the
# formats to work. The in-app charts stay plotly; these files are the same
# data drawn as a static image.
#
# Spec kinds
#   bar     : vertical or horizontal bars, grouped or stacked  (dg_bar)
#   line    : one or more lines over labelled positions        (dg_line)
#   points  : labelled points, optional route between them     (dg_points)
#   figure  : the muscle body diagram, fills per muscle        (dg_figure)
# =============================================================================

DG_W <- 960L          # default export size in pixels (96 dpi)
DG_H <- 560L
DG_GIF_W <- 720L      # GIF frames are smaller to keep the file and the build time modest
DG_GIF_H <- 420L
DG_INK <- "#1b2a36"
DG_MUTED <- "#5f6f7a"
DG_GRID <- "#e3eaed"
DG_PALETTE <- c("#008A82", "#E67E22", "#2E86C1", "#8E44AD", "#C0392B",
                "#27AE60", "#F1C40F", "#16A085", "#7F8C8D", "#D35400")

# ---- spec constructors -------------------------------------------------------
dg_bar <- function(title, labels, series, subtitle = "", stacked = FALSE, horizontal = FALSE,
                   x_title = "", y_title = "", table = NULL) {
  structure(list(kind = "bar", title = title, subtitle = subtitle, labels = as.character(labels),
                 series = series, stacked = isTRUE(stacked), horizontal = isTRUE(horizontal),
                 x_title = x_title, y_title = y_title, table = table), class = "dg_spec")
}
dg_line <- function(title, labels, series, subtitle = "", x_title = "", y_title = "", table = NULL) {
  structure(list(kind = "line", title = title, subtitle = subtitle, labels = as.character(labels),
                 series = series, x_title = x_title, y_title = y_title, table = table), class = "dg_spec")
}
dg_points <- function(title, x, y, labels = NULL, groups = NULL, route = FALSE, subtitle = "",
                      x_title = "", y_title = "", geo = FALSE, table = NULL) {
  structure(list(kind = "points", title = title, subtitle = subtitle, x = as.numeric(x), y = as.numeric(y),
                 labels = if (is.null(labels)) NULL else as.character(labels),
                 groups = if (is.null(groups)) NULL else as.character(groups),
                 route = isTRUE(route), x_title = x_title, y_title = y_title, geo = isTRUE(geo),
                 table = table), class = "dg_spec")
}
dg_figure <- function(title, fills = list(), view = "both", subtitle = "", table = NULL, svg = NULL) {
  structure(list(kind = "figure", title = title, subtitle = subtitle, fills = fills,
                 view = if (view %in% c("front", "back")) view else "both", table = table, svg = svg),
            class = "dg_spec")
}

# ---- shared drawing helpers --------------------------------------------------
dg_series_colors <- function(series) {
  cols <- vapply(seq_along(series), function(i) series[[i]]$color %||% DG_PALETTE[(i - 1L) %% length(DG_PALETTE) + 1L], "")
  cols
}
dg_matrix <- function(series, n) {
  if (!length(series)) return(matrix(0, 0, n))
  do.call(rbind, lapply(series, function(s) {
    v <- suppressWarnings(as.numeric(s$values))
    v <- rep_len(v, n)
    v[!is.finite(v)] <- 0
    v
  }))
}
dg_titles <- function(spec) {
  mtext(spec$title %||% "", side = 3, line = 3, adj = 0, cex = 1.25, font = 2, col = DG_INK)
  if (nzchar(spec$subtitle %||% "")) mtext(spec$subtitle, side = 3, line = 1.8, adj = 0, cex = 0.85, col = DG_MUTED)
}
dg_legend <- function(names, cols) {
  if (length(names) < 2) return(invisible(NULL))
  usr <- par("usr")
  legend(x = usr[1], y = usr[4], xjust = 0, yjust = 0, horiz = TRUE, xpd = NA, bty = "n",
         legend = names, fill = cols, border = NA, cex = 0.85, text.col = DG_INK)
}
dg_empty <- function(spec, msg = "No data to chart yet.") {
  par(mar = c(1, 1, 5.2, 1))
  plot.new()
  dg_titles(spec)
  text(0.5, 0.5, msg, cex = 1.1, col = DG_MUTED)
  invisible(FALSE)
}
# Largest margin (in lines) that still leaves at least half the device for the plot, so long labels never break a small device
dg_max_margin <- function(axis) {
  din <- par("din")
  lines_avail <- (if (axis == "x") din[1] else din[2]) / 0.19
  max(3, floor(lines_avail * 0.45))
}
dg_label_inches <- function(labels, cex = 0.8) if (length(labels)) max(strwidth(labels, units = "inches", cex = cex)) else 0

# Thin long label sets so the axis stays readable (keeps about 14 labels)
dg_thin_index <- function(n, keep = 14L) if (n <= keep) seq_len(n) else unique(round(seq(1, n, length.out = keep)))

# ---- kinds: bar ----------------------------------------------------------------
dg_draw_bar <- function(spec, progress) {
  labs <- spec$labels
  n <- length(labs)
  M <- dg_matrix(spec$series, n)
  if (n == 0 || nrow(M) == 0) return(dg_empty(spec))
  totals <- if (spec$stacked) colSums(M) else as.vector(M)
  top <- max(totals, na.rm = TRUE)
  if (!is.finite(top) || top <= 0) return(dg_empty(spec, "All values are zero, so there is nothing to chart."))
  cols <- dg_series_colors(spec$series)
  vis <- M * progress
  if (spec$horizontal) {
    lab_lines <- ceiling(dg_label_inches(labs) / 0.19) + 1
    par(mar = c(4.2, min(lab_lines, dg_max_margin("x")), 5.2, 1.5), mgp = c(2.6, 0.7, 0), family = "sans")
    plot.new()
    bp <- barplot(vis, beside = !spec$stacked, horiz = TRUE, names.arg = labs, las = 1, cex.names = 0.8,
                  col = cols, border = NA, xlim = c(0, top * 1.12), axes = FALSE, space = 0.25,
                  xlab = spec$y_title, add = FALSE)
    axis(1, col = DG_GRID, col.ticks = DG_GRID, col.axis = DG_MUTED, cex.axis = 0.8)
  } else {
    lab_lines <- ceiling(dg_label_inches(labs) / 0.19) + 1
    par(mar = c(max(4, min(lab_lines, dg_max_margin("y")) + 2), 4.6, 5.2, 1.2), mgp = c(2.8, 0.7, 0), family = "sans")
    plot.new()
    bp <- barplot(vis, beside = !spec$stacked, names.arg = labs, las = 2, cex.names = 0.8,
                  col = cols, border = NA, ylim = c(0, top * 1.16), axes = FALSE, space = 0.25,
                  ylab = spec$y_title, xlab = spec$x_title)
    axis(2, las = 1, col = DG_GRID, col.axis = DG_MUTED, cex.axis = 0.8)
  }
  dg_titles(spec)
  dg_legend(vapply(spec$series, function(s) as.character(s$name %||% ""), ""), cols)
  invisible(TRUE)
}

# ---- kinds: line ---------------------------------------------------------------
dg_draw_line <- function(spec, progress) {
  labs <- spec$labels
  n <- length(labs)
  if (n == 0 || !length(spec$series)) return(dg_empty(spec))
  vals <- lapply(spec$series, function(s) rep_len(suppressWarnings(as.numeric(s$values)), n))
  allv <- unlist(vals)
  allv <- allv[is.finite(allv)]
  if (!length(allv)) return(dg_empty(spec, "No numeric values to chart."))
  yr <- range(allv)
  if (diff(yr) == 0) yr <- yr + c(-1, 1) * max(1, abs(yr[1]) * 0.1)
  pad <- diff(yr) * 0.08
  cols <- dg_series_colors(spec$series)
  idx_lab <- dg_thin_index(n)
  lab_lines <- ceiling(dg_label_inches(labs[idx_lab]) / 0.19) + 1
  par(mar = c(max(4, min(lab_lines, dg_max_margin("y")) + 2), 4.6, 5.2, 1.2), mgp = c(2.8, 0.7, 0), family = "sans")
  plot.new()
  plot.window(xlim = c(1, max(n, 2)), ylim = c(yr[1] - pad, yr[2] + pad))
  axis(1, at = idx_lab, labels = labs[idx_lab], las = 2, cex.axis = 0.8, col = DG_GRID, col.axis = DG_MUTED)
  axis(2, las = 1, col = DG_GRID, col.axis = DG_MUTED, cex.axis = 0.8)
  title(xlab = spec$x_title, ylab = spec$y_title, col.lab = DG_INK)
  dg_titles(spec)
  shown <- seq_len(max(1L, floor(progress * (n - 1L)) + 1L))
  for (i in seq_along(vals)) {
    v <- vals[[i]]
    lines(shown, v[shown], col = cols[i], lwd = 2.4)
    points(shown, v[shown], pch = 19, col = cols[i], cex = 0.85)
  }
  dg_legend(vapply(spec$series, function(s) as.character(s$name %||% ""), ""), cols)
  invisible(TRUE)
}

# ---- kinds: points (labelled points, optional route) --------------------------
dg_draw_points <- function(spec, progress) {
  x <- spec$x; y <- spec$y
  ok <- is.finite(x) & is.finite(y)
  if (!any(ok)) return(dg_empty(spec, "No coordinates to plot."))
  x <- x[ok]; y <- y[ok]
  labs <- if (is.null(spec$labels)) NULL else spec$labels[ok]
  grp <- if (is.null(spec$groups)) rep("1", length(x)) else spec$groups[ok]
  ug <- unique(grp)
  gcol <- DG_PALETTE[(seq_along(ug) - 1L) %% length(DG_PALETTE) + 1L]
  pcol <- gcol[match(grp, ug)]
  asp <- if (spec$geo) 1 / max(cos(mean(y) * pi / 180), 0.2) else 1
  xr <- range(x); yr <- range(y)
  padx <- max(diff(xr) * 0.1, 0.01); pady <- max(diff(yr) * 0.1, 0.01)
  par(mar = c(4.6, 4.6, 5.2, 1.2), mgp = c(2.8, 0.7, 0), family = "sans")
  plot.new()
  plot.window(xlim = xr + c(-padx, padx), ylim = yr + c(-pady, pady), asp = asp)
  axis(1, col = DG_GRID, col.axis = DG_MUTED, cex.axis = 0.8)
  axis(2, las = 1, col = DG_GRID, col.axis = DG_MUTED, cex.axis = 0.8)
  box(col = DG_GRID)
  title(xlab = spec$x_title, ylab = spec$y_title, col.lab = DG_INK)
  dg_titles(spec)
  nshow <- max(1L, floor(progress * length(x)))
  if (spec$route && length(x) > 1) {
    ord <- seq_len(min(nshow, length(x)))
    lines(x[ord], y[ord], col = "#90a4ae", lty = 2, lwd = 1.5)
  }
  show <- seq_len(min(nshow, length(x)))
  points(x[show], y[show], pch = 19, col = pcol[show], cex = 1.8)
  if (!is.null(labs)) text(x[show], y[show], labs[show], pos = 4, cex = 0.75, col = DG_INK, xpd = TRUE)
  dg_legend(ug, gcol)
  invisible(TRUE)
}

# ---- kinds: figure (muscle body diagram, drawn with grid) ---------------------
# Parses the absolute M / L / C / Z path data used by the body artwork and
# returns one list(x, y) per sub-path, with cubic curves flattened to lines.
dg_parse_path <- function(d, steps = 10L) {
  tok <- regmatches(d, gregexpr("[MLCZ]|-?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?", d, perl = TRUE))[[1]]
  subs <- list(); cx <- numeric(0); cy <- numeric(0)
  flush <- function() {
    if (length(cx) > 1) subs[[length(subs) + 1L]] <<- list(x = cx, y = cy)
    cx <<- numeric(0); cy <<- numeric(0)
  }
  px <- 0; py <- 0; sx <- 0; sy <- 0; cmd <- ""; i <- 1L; n <- length(tok)
  while (i <= n) {
    t <- tok[i]
    if (t %in% c("M", "L", "C", "Z")) {
      cmd <- t; i <- i + 1L
      if (t == "Z") { if (length(cx)) { cx <- c(cx, sx); cy <- c(cy, sy) }; flush(); px <- sx; py <- sy }
      next
    }
    if (cmd == "M") {
      flush()
      px <- as.numeric(tok[i]); py <- as.numeric(tok[i + 1L]); i <- i + 2L
      sx <- px; sy <- py; cx <- px; cy <- py; cmd <- "L"
    } else if (cmd == "L") {
      if (!length(cx)) { cx <- px; cy <- py }
      px <- as.numeric(tok[i]); py <- as.numeric(tok[i + 1L]); i <- i + 2L
      cx <- c(cx, px); cy <- c(cy, py)
    } else if (cmd == "C") {
      if (!length(cx)) { cx <- px; cy <- py }
      a <- as.numeric(tok[i:(i + 5L)]); i <- i + 6L
      tt <- seq(1 / steps, 1, length.out = steps)
      mt <- 1 - tt
      bx <- mt^3 * px + 3 * mt^2 * tt * a[1] + 3 * mt * tt^2 * a[3] + tt^3 * a[5]
      by <- mt^3 * py + 3 * mt^2 * tt * a[2] + 3 * mt * tt^2 * a[4] + tt^3 * a[6]
      cx <- c(cx, bx); cy <- c(cy, by)
      px <- a[5]; py <- a[6]
    } else {
      stop("Unsupported path data near: ", substr(d, 1, 40))
    }
  }
  flush()
  subs
}

# Draws one filled path (all of its sub-paths, winding rule) with an x offset and optional mirror.
dg_grid_path <- function(subs, ox, mirror, fill, col = NA, lwd = 0.6, alpha = 1) {
  if (!length(subs)) return(invisible(NULL))
  x <- unlist(lapply(subs, function(s) if (mirror) 220 - s$x + ox else s$x + ox))
  y <- unlist(lapply(subs, `[[`, "y"))
  id <- rep(seq_along(subs), vapply(subs, function(s) length(s$x), 0L))
  grid::grid.draw(grid::pathGrob(grid::unit(x, "native"), grid::unit(y, "native"), id = id, rule = "winding",
                                 gp = grid::gpar(fill = grDevices::adjustcolor(fill, alpha.f = alpha),
                                                 col = col, lwd = lwd)))
}

dg_draw_figure <- function(spec, progress) {
  views <- if (spec$view %in% c("front", "back")) spec$view else c("front", "back")
  step <- 230; fig_w <- 220; fig_h <- 478
  total_w <- step * length(views)
  W <- DG_W; H <- DG_H; title_px <- 64
  s <- min((W - 24) / total_w, (H - title_px - 8) / fig_h)
  grid::grid.newpage()
  yc <- (H - title_px - fig_h * s / 2) / H
  vp <- grid::viewport(x = 0.5, y = yc, width = total_w * s / W, height = fig_h * s / H,
                       xscale = c(0, total_w), yscale = c(fig_h, 0))
  fills <- spec$fills
  nf <- length(fills)
  shown <- if (nf) names(fills)[seq_len(max(0L, min(nf, round(progress * nf))))] else character(0)
  fills <- fills[shown]
  base_col <- function(id) { c <- MUSCLE_CAT$color[match(id, MUSCLE_CAT$id)]; if (is.na(c)) "#cccccc" else c }
  col_of <- function(id) { c <- fills[[id]]; if (!is.null(c)) c else if (nf) "#eadfd6" else base_col(id) }

  grid::pushViewport(vp)
  for (vi in seq_along(views)) {
    v <- views[vi]; ox <- (vi - 1) * step
    sil <- dg_parse_path(MUSCLE_BODY_SILHOUETTE)
    dg_grid_path(sil, ox, FALSE, "#fbe7d8", col = "#e8c9b4", lwd = 0.8)
    dg_grid_path(sil, ox, TRUE, "#fbe7d8", col = "#e8c9b4", lwd = 0.8)
    tt <- seq(0, 2 * pi, length.out = 73)
    head <- list(list(x = 110 + 17 * cos(tt), y = 34 + 22 * sin(tt)))
    dg_grid_path(head, ox, FALSE, "#fbe7d8", col = "#e8c9b4", lwd = 0.8)

    parts <- MUSCLE_BODY_PARTS[MUSCLE_BODY_PARTS$view == v, , drop = FALSE]
    for (id in MUSCLE_IDS) {
      p <- parts[parts$muscle == id, , drop = FALSE]
      if (!nrow(p)) next
      c <- col_of(id)
      for (r in seq_len(nrow(p))) {
        subs <- dg_parse_path(p$d[r])
        alpha <- if (p$shade[r] == 1) 0.82 else 0.95
        dg_grid_path(subs, ox, FALSE, c, col = grDevices::adjustcolor("#ffffff", alpha.f = 0.75), lwd = 0.5, alpha = alpha)
        if (isTRUE(p$mirror[r])) dg_grid_path(subs, ox, TRUE, c, col = grDevices::adjustcolor("#ffffff", alpha.f = 0.75), lwd = 0.5, alpha = alpha)
      }
    }
    det <- MUSCLE_BODY_DETAIL[MUSCLE_BODY_DETAIL$view == v, , drop = FALSE]
    for (i in seq_len(nrow(det))) {
      subs <- dg_parse_path(det$d[i])
      dg_grid_path(subs, ox, FALSE, NA, col = grDevices::adjustcolor("#ffffff", alpha.f = 0.5), lwd = 0.6)
      dg_grid_path(subs, ox, TRUE, NA, col = grDevices::adjustcolor("#ffffff", alpha.f = 0.5), lwd = 0.6)
    }
  }
  grid::popViewport()

  # title and subtitle sit above the figure
  top <- grid::viewport(x = 0.5, y = 1, width = 1, height = grid::unit(title_px, "points"), just = c(0.5, 1))
  grid::pushViewport(top)
  grid::grid.text(spec$title %||% "", x = 0.02, y = 0.72, just = "left", gp = grid::gpar(fontsize = 15, fontface = "bold", col = DG_INK))
  if (nzchar(spec$subtitle %||% "")) grid::grid.text(spec$subtitle, x = 0.02, y = 0.25, just = "left", gp = grid::gpar(fontsize = 10, col = DG_MUTED))
  grid::popViewport()
  invisible(TRUE)
}

# ---- drawing dispatch ---------------------------------------------------------
dg_draw <- function(spec, progress = 1) {
  progress <- min(1, max(0, as.numeric(progress)))
  switch(spec$kind,
         bar = dg_draw_bar(spec, progress),
         line = dg_draw_line(spec, progress),
         points = dg_draw_points(spec, progress),
         figure = dg_draw_figure(spec, progress),
         stop("Unknown diagram kind: ", spec$kind))
}

# ---- file outputs -------------------------------------------------------------
dg_png_type <- function() if (capabilities("cairo")) "cairo" else getOption("bitmapType", "Xlib")

# Opens the device for a format, draws, closes the device. Returns the file path.
dg_device_write <- function(spec, format, file, progress = 1, width = DG_W, height = DG_H, antialias = TRUE) {
  format <- tolower(format)
  if (width < 480 || height < 300) stop("Diagram size too small (minimum 480 x 300 pixels)")
  if (format == "png") {
    if (capabilities("cairo")) grDevices::png(file, width = width, height = height, units = "px", res = 96, bg = "white",
                                              type = "cairo", antialias = if (antialias) "default" else "none")
    else grDevices::png(file, width = width, height = height, units = "px", res = 96, bg = "white")
  } else if (format == "pdf") {
    grDevices::pdf(file, width = width / 96, height = height / 96, onefile = TRUE, title = spec$title %||% "Diagram")
  } else if (format == "svg") {
    if (!capabilities("cairo")) stop("SVG export needs R built with cairo; use PNG or PDF instead.")
    grDevices::svg(file, width = width / 96, height = height / 96, bg = "white")
  } else stop("Unknown device format: ", format)
  on.exit(grDevices::dev.off(), add = TRUE)
  dg_draw(spec, progress)
  invisible(file)
}

dg_table_html <- function(df) {
  if (!is.data.frame(df) || !nrow(df)) return("")
  esc <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; htmltools::htmlEscape(x) }
  head <- paste0("<th>", esc(names(df)), "</th>", collapse = "")
  rows <- vapply(seq_len(nrow(df)), function(i) paste0("<tr>", paste0("<td>", esc(df[i, , drop = TRUE]), "</td>", collapse = ""), "</tr>"), "")
  paste0("<table><thead><tr>", head, "</tr></thead><tbody>", paste(rows, collapse = ""), "</tbody></table>")
}

# Self-contained HTML page: the diagram (embedded PNG, or the SVG for the body figure) plus its data table.
dg_write_html <- function(spec, file) {
  tmp <- tempfile(fileext = ".png"); on.exit(unlink(tmp), add = TRUE)
  dg_device_write(spec, "png", tmp, width = DG_W, height = DG_H)
  img <- if (!is.null(spec$svg)) spec$svg else sprintf('<img alt="%s" src="data:image/png;base64,%s">',
                                                       htmltools::htmlEscape(spec$title %||% ""),
                                                       jsonlite::base64_enc(readBin(tmp, "raw", file.info(tmp)$size)))
  page <- c(
    "<!DOCTYPE html>", "<html lang=\"en\"><head><meta charset=\"UTF-8\">",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
    sprintf("<title>%s</title>", htmltools::htmlEscape(spec$title %||% "Diagram")),
    "<style>body{font-family:'Segoe UI',Tahoma,Arial,sans-serif;background:#f4f6f7;color:#1b2a36;margin:0;padding:20px}",
    ".card{max-width:1000px;margin:0 auto;background:#fff;border-radius:8px;padding:28px;box-shadow:0 2px 10px rgba(0,0,0,.08)}",
    "h1{margin:0 0 4px;font-size:1.6em;color:#002C3C}.sub{color:#5f6f7a;margin-bottom:16px}",
    "img,svg{max-width:100%;height:auto;display:block;margin:0 auto}",
    "table{width:100%;border-collapse:collapse;margin-top:18px;font-size:.9em}",
    "th{background:#008A82;color:#fff;text-align:left;padding:8px 10px}td{padding:8px 10px;border-bottom:1px solid #e6ebee}",
    "tr:nth-child(even){background:#f8fafb}.foot{margin-top:24px;color:#8a98a2;font-size:.85em;text-align:center}",
    "</style></head><body><div class=\"card\">",
    sprintf("<h1>%s</h1>", htmltools::htmlEscape(spec$title %||% "")),
    if (nzchar(spec$subtitle %||% "")) sprintf("<div class=\"sub\">%s</div>", htmltools::htmlEscape(spec$subtitle)) else "",
    img,
    dg_table_html(spec$table),
    sprintf("<div class=\"foot\">Business Operations Suite - saved %s</div>", format(Sys.time(), "%Y-%m-%d %H:%M")),
    "</div></body></html>")
  writeLines(enc2utf8(page), file, useBytes = TRUE)
  invisible(file)
}

# ---- animated GIF ---------------------------------------------------------------
# Frames are drawn with the PNG device, decoded here (zlib via memDecompress), and
# written as a GIF89a with a shared palette and LZW compression. Nothing else needed.

dg_be32 <- function(x) sum(as.numeric(as.integer(x)) * c(16777216, 65536, 256, 1))
dg_le16 <- function(v) as.raw(c(v %% 256, v %/% 256))

# PNG unfiltering. Sub and Up are vectorised; Average and Paeth must run pixel by pixel.
dg_png_unfilter <- function(x, stride, bpp, h) {
  out <- integer(h * stride)
  prev <- integer(stride)
  for (r in seq_len(h)) {
    base <- (r - 1L) * (stride + 1L)
    ft <- x[base + 1L]
    line <- x[base + 1L + seq_len(stride)]
    cur <- line
    if (ft == 1L) {
      for (c in seq_len(bpp)) {
        idx <- seq(c, stride, by = bpp)
        cur[idx] <- cumsum(line[idx]) %% 256L
      }
    } else if (ft == 2L) {
      cur <- (line + prev) %% 256L
    } else if (ft == 3L) {
      for (i in seq_len(stride)) {
        left <- if (i > bpp) cur[i - bpp] else 0L
        cur[i] <- (line[i] + (left + prev[i]) %/% 2L) %% 256L
      }
    } else if (ft == 4L) {
      for (i in seq_len(stride)) {
        a <- if (i > bpp) cur[i - bpp] else 0L
        b <- prev[i]
        cc <- if (i > bpp) prev[i - bpp] else 0L
        p <- a + b - cc
        pa <- abs(p - a); pb <- abs(p - b); pc <- abs(p - cc)
        pr <- if (pa <= pb && pa <= pc) a else if (pb <= pc) b else cc
        cur[i] <- (line[i] + pr) %% 256L
      }
    } else if (ft != 0L) stop("Unknown PNG filter type ", ft)
    out[((r - 1L) * stride + 1L):(r * stride)] <- cur
    prev <- cur
  }
  out
}

# Reads a non-interlaced 8-bit or palette PNG and returns one colour key per pixel
# (row by row, key = r * 65536 + g * 256 + b).
dg_png_keys <- function(path) {
  b <- readBin(path, "raw", file.info(path)$size)
  if (!identical(b[1:8], as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)))) stop("Not a PNG file: ", path)
  pos <- 9L; w <- h <- depth <- ctype <- interlace <- NA_integer_; plte <- NULL; idat <- list()
  while (pos + 7L <= length(b)) {
    len <- dg_be32(b[pos:(pos + 3L)])
    type <- rawToChar(b[(pos + 4L):(pos + 7L)])
    body <- if (len > 0) b[(pos + 8L):(pos + 7L + len)] else raw(0)
    if (type == "IHDR") {
      w <- dg_be32(body[1:4]); h <- dg_be32(body[5:8])
      depth <- as.integer(body[9]); ctype <- as.integer(body[10]); interlace <- as.integer(body[13])
    } else if (type == "PLTE") plte <- as.integer(body)
    else if (type == "IDAT") idat[[length(idat) + 1L]] <- body
    else if (type == "IEND") break
    pos <- pos + 12L + len
  }
  if (interlace != 0L) stop("Interlaced PNG files are not supported")
  channels <- switch(as.character(ctype), "0" = 1L, "2" = 3L, "3" = 1L, "4" = 2L, "6" = 4L, stop("Unsupported PNG colour type ", ctype))
  if (!(depth == 8L || (ctype == 3L && depth %in% c(1L, 2L, 4L)))) stop("Unsupported PNG bit depth ", depth)
  bits_pp <- channels * depth
  bpp <- max(1L, bits_pp %/% 8L)
  stride <- ceiling(w * bits_pp / 8)
  raw_px <- memDecompress(do.call(c, idat), type = "gzip")
  if (length(raw_px) != h * (stride + 1L)) stop("PNG data size does not match its header")
  bytes <- dg_png_unfilter(as.integer(raw_px), stride, bpp, h)

  if (ctype == 3L) {
    pal <- matrix(plte, ncol = 3, byrow = TRUE)
    pal_key <- pal[, 1] * 65536 + pal[, 2] * 256 + pal[, 3]
    if (depth == 8L) {
      idx <- bytes[seq_len(h * stride)]
      idx_mat <- matrix(idx, nrow = stride)[seq_len(w), , drop = FALSE]
    } else {
      per <- 8L %/% depth
      vals <- matrix(0L, nrow = per, ncol = h * stride)
      for (s in seq_len(per)) vals[s, ] <- (bytes %/% 2L^((per - s) * depth)) %% 2L^depth
      all_px <- matrix(as.vector(vals), nrow = stride * per)
      idx_mat <- all_px[seq_len(w), , drop = FALSE]
    }
    keys <- pal_key[as.vector(idx_mat) + 1L]
    return(as.vector(matrix(keys, nrow = w)))
  }
  rowmat <- matrix(bytes, nrow = stride)
  r <- rowmat[seq(1, by = channels, length.out = w), , drop = FALSE]
  g <- rowmat[seq(2, by = channels, length.out = w), , drop = FALSE]
  bl <- rowmat[seq(3, by = channels, length.out = w), , drop = FALSE]
  keys <- r * 65536 + g * 256 + bl            # w x h, column = image row
  as.vector(keys)                             # column-major = row by row
}

# LZW for GIF: codes are collected, then packed LSB-first into bytes.
dg_lzw <- function(px, m) {
  clear <- 2L^m; eoi <- clear + 1
  px <- as.integer(px)
  dict <- integer(4096L * 256L)
  used <- integer(4096L); nused <- 0L
  codes <- integer(length(px) + 8L); widths <- integer(length(px) + 8L)
  nc <- 1L; codes[1] <- as.integer(clear); widths[1] <- m + 1L
  cs <- m + 1L; nxt <- as.integer(eoi) + 1L
  w <- px[1]
  for (i in 2:length(px)) {
    k <- px[i]
    key <- w * 256L + k + 1L
    hit <- dict[key]
    if (hit > 0L) { w <- hit; next }
    nc <- nc + 1L; codes[nc] <- w; widths[nc] <- cs
    dict[key] <- nxt; nused <- nused + 1L; used[nused] <- key
    nxt <- nxt + 1L
    if (nxt > 2L^cs && cs < 12L) cs <- cs + 1L
    if (nxt == 4096L) {
      nc <- nc + 1L; codes[nc] <- as.integer(clear); widths[nc] <- cs
      dict[used[seq_len(nused)]] <- 0L; nused <- 0L
      nxt <- as.integer(eoi) + 1L; cs <- m + 1L
    }
    w <- k
  }
  nc <- nc + 1L; codes[nc] <- w; widths[nc] <- cs
  nc <- nc + 1L; codes[nc] <- as.integer(eoi); widths[nc] <- cs
  codes <- codes[seq_len(nc)]; widths <- widths[seq_len(nc)]
  bitm <- t(outer(codes, 0:11, function(cd, j) (cd %/% 2^j) %% 2))
  keep <- t(outer(widths, 0:11, ">"))
  bits <- as.integer(bitm[keep])
  if (length(bits) %% 8L) bits <- c(bits, integer(8L - length(bits) %% 8L))
  as.raw(colSums(matrix(bits, nrow = 8L) * 2^(0:7)))
}

dg_gif_blocks <- function(data) {
  if (!length(data)) return(as.raw(0))
  starts <- seq(1L, length(data), by = 255L)
  out <- raw(0)
  for (s in starts) {
    chunk <- data[s:min(length(data), s + 254L)]
    out <- c(out, as.raw(length(chunk)), chunk)
  }
  c(out, as.raw(0))
}

# frames: list of integer colour-key vectors (all the same length, row-major)
dg_write_gif_frames <- function(frames, width, height, delays, file) {
  all_keys <- unique(unlist(frames))
  if (length(all_keys) <= 256L) {
    pal <- all_keys
    idx_frames <- lapply(frames, function(f) match(f, pal) - 1L)
  } else {
    # more colours than a GIF palette holds (antialiased edges): keep the 256 most used colours,
    # and give every other colour the nearest palette colour
    counts <- table(unlist(frames))
    pal <- as.numeric(names(sort(counts, decreasing = TRUE))[seq_len(256L)])
    rgb_of <- function(k) cbind(k %/% 65536, (k %/% 256) %% 256, k %% 256)
    pal_rgb <- rgb_of(pal)
    uniq <- all_keys
    u_rgb <- rgb_of(uniq)
    near <- vapply(seq_along(uniq), function(i) {
      d <- (pal_rgb[, 1] - u_rgb[i, 1])^2 + (pal_rgb[, 2] - u_rgb[i, 2])^2 + (pal_rgb[, 3] - u_rgb[i, 3])^2
      which.min(d) - 1L
    }, 0L)
    idx_frames <- lapply(frames, function(f) near[match(f, uniq)])
  }
  ncol_ <- length(pal)
  k <- max(1L, ceiling(log2(max(ncol_, 2L))))
  table_n <- 2L^k
  rgb <- cbind(pal %/% 65536, (pal %/% 256) %% 256, pal %% 256)
  if (nrow(rgb) < table_n) rgb <- rbind(rgb, matrix(0, table_n - nrow(rgb), 3))
  m <- max(2L, k)
  out <- c(charToRaw("GIF89a"), dg_le16(width), dg_le16(height),
           as.raw(c(0xF0 + (k - 1L), 0, 0)), as.raw(t(rgb)))
  out <- c(out, as.raw(c(0x21, 0xFF, 0x0B)), charToRaw("NETSCAPE2.0"), as.raw(c(0x03, 0x01, 0x00, 0x00, 0x00)))
  for (f in seq_along(idx_frames)) {
    out <- c(out, as.raw(c(0x21, 0xF9, 0x04, 0x04)), dg_le16(delays[f]), as.raw(c(0x00, 0x00)))
    out <- c(out, as.raw(0x2C), dg_le16(0), dg_le16(0), dg_le16(width), dg_le16(height), as.raw(0x00))
    out <- c(out, as.raw(m), dg_gif_blocks(dg_lzw(idx_frames[[f]], m)))
  }
  out <- c(out, as.raw(0x3B))
  writeBin(out, file)
  invisible(file)
}

# Renders the spec as a GIF: the picture builds up over `frames` steps, then holds.
dg_write_gif <- function(spec, file, frames = 16L, delay_cs = 10L, hold_cs = 200L,
                         width = DG_GIF_W, height = DG_GIF_H) {
  keys <- vector("list", frames)
  for (f in seq_len(frames)) {
    tmp <- tempfile(fileext = ".png")
    on.exit(unlink(tmp), add = TRUE)
    dg_device_write(spec, "png", tmp, progress = f / frames, width = width, height = height, antialias = FALSE)
    keys[[f]] <- dg_png_keys(tmp)
    unlink(tmp)
  }
  delays <- c(rep(as.integer(delay_cs), frames - 1L), as.integer(hold_cs))
  dg_write_gif_frames(keys, width, height, delays, file)
}

# ---- single entry point ------------------------------------------------------------
# format: png | pdf | svg | html | gif. Returns the file path. Errors are raised, not hidden.
dg_render <- function(spec, format, file) {
  format <- tolower(format)
  switch(format,
         png = dg_device_write(spec, "png", file),
         pdf = dg_device_write(spec, "pdf", file),
         svg = dg_device_write(spec, "svg", file),
         html = dg_write_html(spec, file),
         gif = dg_write_gif(spec, file),
         stop("Unknown diagram format: ", format))
  if (!file.exists(file) || file.info(file)$size == 0) stop("The ", toupper(format), " file was not written")
  invisible(file)
}

DG_FORMATS <- c(png = "PNG image", pdf = "PDF document", svg = "SVG (vector)", html = "HTML page", gif = "Animated GIF")
DG_MIME <- c(png = "image/png", pdf = "application/pdf", svg = "image/svg+xml", html = "text/html", gif = "image/gif")
