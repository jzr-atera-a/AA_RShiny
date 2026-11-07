# ============================================================================
# COMMON UTILITIES
# ============================================================================

# Photo file types picked up by the scan (case-insensitive)
PHOTO_EXTENSIONS <- c("jpg", "jpeg", "png", "gif", "bmp", "webp", "tif", "tiff", "heic", "heif")

# Label used for photos that sit directly inside a country folder (no sub-folder)
LOOSE_LABEL <- "(Fotos sueltas en la carpeta del país)"

# Special value for "all places in this country"
ALL_PLACES <- "__ALL__"

# Setup volume roots for directory browsing (used by shinyFiles)
get_volume_roots <- function() {
  if (.Platform$OS.type == "windows") {
    drives <- paste0(LETTERS, ":/")
    drives <- drives[vapply(drives, dir.exists, logical(1))]
    volumes <- c(setNames(drives, substr(drives, 1, 2)),
                 "Inicio" = path.expand("~"))
  } else {
    volumes <- c(
      "Inicio" = path.expand("~"),
      "Imágenes" = path.expand("~/Pictures"),
      "Escritorio" = path.expand("~/Desktop"),
      "Documentos" = path.expand("~/Documents"),
      "Descargas" = path.expand("~/Downloads"),
      "Discos" = "/Volumes",
      "Medios" = "/media",
      "Raíz" = "/"
    )
  }
  volumes[vapply(volumes, dir.exists, logical(1))]
}

# Proportional allocation of a limit across sub-folders (largest-remainder method).
# Example: counts = c(800, 200), limit = 50  ->  c(40, 10)
# Guarantees: sum(result) == min(limit, sum(counts)) and result <= counts.
suggest_allocation <- function(counts, limit) {
  counts <- as.integer(counts)
  total <- sum(counts)
  if (total == 0 || limit <= 0) return(integer(length(counts)))
  if (total <= limit) return(counts)

  quota <- counts * limit / total
  base <- floor(quota)
  left <- as.integer(limit - sum(base))
  if (left > 0) {
    ord <- order(quota - base, counts, decreasing = TRUE)
    take <- ord[seq_len(left)]
    base[take] <- base[take] + 1
  }
  as.integer(pmin(base, counts))
}

# Same idea, but some places have a maximum (cap). Places that would get more than their cap
# are fixed at the cap and the rest of the limit is shared among the others.
# Example: counts = c(600, 400), limit = 50, caps = c(NA, 8)  ->  c(42, 8)
suggest_allocation_capped <- function(counts, limit, caps = rep(NA_integer_, length(counts))) {
  counts <- as.integer(counts); n <- length(counts)
  res <- integer(n)
  if (n == 0 || limit <= 0) return(res)
  ub <- ifelse(is.na(caps), counts, pmin(counts, caps))          # most a place can get
  if (sum(ub) <= limit) return(as.integer(ub))
  fixed <- rep(FALSE, n)
  repeat {
    free <- which(!fixed)
    if (!length(free) || sum(counts[free]) == 0) break
    remaining <- limit - sum(res[fixed])
    q <- counts[free] * remaining / sum(counts[free])
    over <- free[q > ub[free]]
    if (!length(over)) break
    res[over] <- ub[over]; fixed[over] <- TRUE
  }
  free <- which(!fixed)
  if (length(free)) res[free] <- suggest_allocation(counts[free], limit - sum(res[fixed]))
  as.integer(pmin(res, ub))
}

# City/region/event folders whose name starts with Museo(s), Galería(s)/Galeria(s) or Vuelo(s)
SPECIAL_PLACE_REGEX <- "^\\s*(museos?|galer(i|\u00ed)as?|vuelos?)(?![[:alpha:]\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1])"
is_special_place <- function(x) grepl(SPECIAL_PLACE_REGEX, tolower(enc2utf8(x)), perl = TRUE)

fmt_int <- function(x) formatC(as.numeric(x), format = "d", big.mark = ",")

fmt_money <- function(x, currency = "MXN") {
  paste0("$", formatC(as.numeric(x), format = "f", digits = 2, big.mark = ","), " ", currency)
}

# URL-encode each segment of a relative path ("México/Cancún/IMG 1.jpg")
encode_rel_path <- function(rel) {
  parts <- strsplit(rel, "/", fixed = TRUE)[[1]]
  paste(vapply(parts, utils::URLencode, character(1), reserved = TRUE), collapse = "/")
}

hash_str <- function(x) digest::digest(x, algo = "md5", serialize = FALSE)

# Write a file safely: write to a temp file, then move into place
safe_write <- function(path, writer) {
  tmp <- paste0(path, ".tmp")
  writer(tmp)
  if (!suppressWarnings(file.rename(tmp, path))) {
    file.copy(tmp, path, overwrite = TRUE)
    unlink(tmp)
  }
  invisible(path)
}

# Append a line to the app log (data/app.log)
log_event <- function(log_file, ...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  ", paste0(..., collapse = ""))
  cat(msg, "\n")
  tryCatch(cat(msg, "\n", file = log_file, append = TRUE), error = function(e) NULL)
}

# ----------------------------------------------------------------------------
# Photo tile / grid helpers (shared by Explorer and My Selection)
# ----------------------------------------------------------------------------

photo_tile <- function(photo_id, src, caption, selected, sub_caption = NULL) {
  div(
    class = paste("photo-tile", if (isTRUE(selected)) "selected"),
    `data-id` = photo_id,
    div(
      class = "photo-frame photo-toggle",
      title = "Haga clic para elegir o quitar esta foto",
      tags$img(src = src, alt = caption, loading = "lazy"),
      div(class = "photo-check", HTML("&#10004;"))
    ),
    div(
      class = "photo-actions",
      tags$button(
        type = "button", class = "btn photo-toggle photo-toggle-btn",
        span(class = "lbl-off", HTML("&#9744; Elegir")),
        span(class = "lbl-on", HTML("&#9745; Elegida"))
      ),
      tags$button(type = "button", class = "btn photo-zoom", title = "Ver esta foto más grande",
                  HTML("&#128269;"), span(class = "zoom-text", "Ver grande"))
    ),
    div(class = "photo-caption", caption,
        if (!is.null(sub_caption)) div(class = "photo-subcaption", sub_caption))
  )
}

photo_grid <- function(tiles, layout = "2x2", toggle_input, zoom_input) {
  div(
    class = paste0("photo-grid grid-", substr(layout, 1, 1), " layout-", layout),
    `data-toggle-input` = toggle_input,
    `data-zoom-input` = zoom_input,
    tiles
  )
}

# Toggle a photo, enforce the country limit, and update every tile in the browser
handle_photo_toggle <- function(pm, photo_id, session) {
  ph <- pm$photo_by_id(photo_id)
  if (is.null(ph)) return(invisible(NULL))

  before <- pm$subfolder_chosen(ph$country, ph$subfolder)
  res <- pm$toggle(ph$rel_path)

  if (!isTRUE(res$ok)) {
    if (identical(res$reason, "limit")) {
      showModal(modalDialog(
        title = "Ya llegó al límite",
        div(class = "big-message",
            p(HTML(sprintf("Usted ya eligió <b>%s fotos</b> de <b>%s</b>. Ese es el máximo permitido.",
                           res$limit, htmltools::htmlEscape(ph$country)))),
            p("Si quiere esta foto, primero quite otra foto de este país.")),
        footer = modalButton("Entendido"),
        easyClose = TRUE
      ))
    }
    return(invisible(res))
  }

  session$sendCustomMessage("photo-selected", list(id = photo_id, selected = res$selected))

  # Gentle nudge when the user goes past the suggested amount for a place
  if (isTRUE(res$selected)) {
    sug <- pm$subfolder_suggested(ph$country, ph$subfolder)
    if (before < sug && (before + 1) >= sug) {
      showNotification(
        sprintf("¡Muy bien! Ya llegó a las %s fotos sugeridas para %s.", sug, ph$subfolder),
        type = "message", duration = 6
      )
    } else if (before == sug && sug > 0) {
      showNotification(
        sprintf("Ya pasó de las %s fotos sugeridas para %s. No hay problema, pero recuerde el límite para %s.",
                sug, ph$subfolder, ph$country),
        type = "warning", duration = 8
      )
    }
  }
  invisible(res)
}

# Large-view modal with Previous / Next / Choose. `ids_fun` returns the ordered photo ids.
setup_zoom <- function(input, output, session, pm) {
  ns <- session$ns
  zoom <- reactiveValues(ids = integer(), pos = 1)

  open_zoom <- function(photo_id, ids) {
    zoom$ids <- as.integer(ids)
    zoom$pos <- max(1, match(as.integer(photo_id), zoom$ids, nomatch = 1))
    showModal(modalDialog(
      size = "l", easyClose = TRUE, title = NULL,
      uiOutput(ns("zoom_body")),
      footer = div(
        class = "zoom-footer",
        actionButton(ns("zoom_prev"), HTML("&#9664; Anterior"), class = "btn-lg btn-default"),
        uiOutput(ns("zoom_toggle_ui"), inline = TRUE),
        actionButton(ns("zoom_next"), HTML("Siguiente &#9654;"), class = "btn-lg btn-default"),
        modalButton("Cerrar")
      )
    ))
  }

  current_id <- reactive({
    req(length(zoom$ids) > 0)
    zoom$ids[min(zoom$pos, length(zoom$ids))]
  })

  output$zoom_body <- renderUI({
    id <- current_id()
    ph <- pm$photo_by_id(id)
    req(ph)
    div(
      class = "zoom-body",
      div(class = "zoom-title",
          sprintf("%s  ›  %s   —   foto %s de %s", ph$country, ph$subfolder, zoom$pos, length(zoom$ids))),
      tags$img(src = pm$image_url(ph$rel_path, "large"), class = "zoom-img"),
      div(class = "photo-subcaption", ph$file_name)
    )
  })

  output$zoom_toggle_ui <- renderUI({
    pm$sel_trigger()
    id <- current_id()
    ph <- pm$photo_by_id(id)
    req(ph)
    if (pm$is_selected(ph$rel_path)) {
      actionButton(ns("zoom_toggle"), HTML("&#9745; Elegida — clic para quitarla"), class = "btn-lg btn-success")
    } else {
      actionButton(ns("zoom_toggle"), HTML("&#9744; Elegir esta foto"), class = "btn-lg btn-primary")
    }
  })

  observeEvent(input$zoom_prev, { if (zoom$pos > 1) zoom$pos <- zoom$pos - 1 })
  observeEvent(input$zoom_next, { if (zoom$pos < length(zoom$ids)) zoom$pos <- zoom$pos + 1 })
  observeEvent(input$zoom_toggle, {
    res <- handle_photo_toggle(pm, current_id(), session)
    # the limit message replaces the zoom modal; re-open the photo afterwards is not needed
    invisible(res)
  })

  list(open = open_zoom)
}

# CSV writer that is UTF-8 regardless of the computer's locale (with BOM so Excel shows accents)
write_csv_utf8 <- function(df, path) {
  q <- function(x) paste0('"', gsub('"', '""', enc2utf8(as.character(x)), fixed = TRUE), '"')
  lines <- c(paste(q(names(df)), collapse = ","),
             if (nrow(df)) do.call(paste, c(lapply(df, q), sep = ",")))
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)), charToRaw(enc2utf8(paste0(paste(lines, collapse = "\r\n"), "\r\n")))), con)
  invisible(path)
}

# Date in Spanish regardless of the computer's language, e.g. "24 oct 2026, 05:46"
fmt_fecha <- function(x) {
  meses <- c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")
  lt <- as.POSIXlt(x)
  sprintf("%d %s %d, %s", lt$mday, meses[lt$mon + 1], lt$year + 1900, format(x, "%H:%M"))
}
