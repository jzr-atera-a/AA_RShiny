# ============================================================================
# COMMON UTILITIES
# ============================================================================

# Volume roots for the folder browser (shinyFiles)
get_volume_roots <- function() {
  if (.Platform$OS.type == "windows") {
    drives <- paste0(LETTERS, ":/")
    drives <- drives[vapply(drives, dir.exists, logical(1))]
    volumes <- c(setNames(drives, substr(drives, 1, 2)), "Inicio" = path.expand("~"))
  } else {
    volumes <- c(
      "Inicio" = path.expand("~"),
      "Documentos" = path.expand("~/Documents"),
      "Escritorio" = path.expand("~/Desktop"),
      "Descargas" = path.expand("~/Downloads"),
      "Discos" = "/Volumes",
      "Medios" = "/media",
      "Raíz" = "/"
    )
  }
  volumes[vapply(volumes, dir.exists, logical(1))]
}

# Increase a reactiveVal counter (works inside or outside a reactive context)
bump <- function(rv) rv(shiny::isolate(rv()) + 1)

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

write_utf8 <- function(text, path) {
  safe_write(path, function(p) {
    con <- file(p, open = "wb"); on.exit(close(con))
    writeBin(charToRaw(enc2utf8(paste(text, collapse = "\n"))), con)
  })
}

read_utf8 <- function(path) {
  if (!file.exists(path)) return("")
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# Append a line to the app log
log_event <- function(log_file, ...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  ", paste0(..., collapse = ""))
  cat(msg, "\n")
  tryCatch(cat(msg, "\n", file = log_file, append = TRUE), error = function(e) NULL)
}

# Date in Spanish regardless of the computer's language, e.g. "24 oct 2026, 05:46"
fmt_fecha <- function(x) {
  if (is.null(x) || length(x) == 0 || (is.character(x) && !nzchar(x))) return("—")
  if (is.character(x)) x <- as.POSIXct(x, format = "%Y-%m-%d %H:%M:%S")
  if (is.na(x)) return("—")
  meses <- c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")
  lt <- as.POSIXlt(x)
  sprintf("%d %s %d, %s", lt$mday, meses[lt$mon + 1], lt$year + 1900, format(x, "%H:%M"))
}
now_str <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

fmt_int <- function(x) formatC(as.numeric(x), format = "d", big.mark = ",")

new_id <- function(prefix = "") paste0(prefix, format(Sys.time(), "%Y%m%d%H%M%S"), sprintf("%03d", sample.int(999, 1)))

word_count <- function(x) {
  x <- paste(x %||% "", collapse = " ")
  if (!nzchar(trimws(x))) return(0L)
  length(strsplit(trimws(x), "[[:space:]]+")[[1]])
}

# Markdown (as written by Claude) -> HTML
md_html <- function(text) {
  text <- paste(text %||% "", collapse = "\n")
  HTML(tryCatch(as.character(shiny::markdown(text)),
                error = function(e) paste0("<pre>", htmltools::htmlEscape(text), "</pre>")))
}

# Pull the first {...} JSON object (or [...] array) out of a model reply
extract_json <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("```(json)?", "", text)
  s <- regexpr("[\\{\\[]", text)
  if (s < 0) return(NULL)
  open_ch <- substr(text, s, s)
  close_ch <- if (open_ch == "{") "}" else "]"
  ends <- gregexpr(close_ch, text, fixed = TRUE)[[1]]
  ends <- rev(ends[ends > s])
  for (e in ends) {
    out <- tryCatch(jsonlite::fromJSON(substr(text, s, e), simplifyVector = FALSE), error = function(err) NULL)
    if (!is.null(out)) return(out)
  }
  NULL
}

# Text between <tag> ... </tag>
extract_tag <- function(text, tag) {
  m <- regmatches(text, regexec(sprintf("(?s)<%s>\\s*(.*?)\\s*</%s>", tag, tag), text, perl = TRUE))[[1]]
  if (length(m) >= 2) m[2] else NULL
}

# Trim a long text for a prompt (keep the start and the end)
clip_text <- function(x, max_chars = 24000) {
  x <- paste(x %||% "", collapse = "\n")
  if (nchar(x) <= max_chars) return(x)
  half <- floor(max_chars / 2)
  paste0(substr(x, 1, half), "\n\n[… texto recortado …]\n\n", substr(x, nchar(x) - half, nchar(x)))
}

# A small coloured progress bar (re-uses the .stat-bar CSS)
progress_bar <- function(pct, cls = "") {
  pct <- max(0, min(100, round(pct)))
  div(class = paste("stat-bar", cls), div(style = sprintf("width: %s%%;", pct)))
}

# Stat tile (same look as the photo app)
stat_tile <- function(label, value, note = NULL, color = "", pct = NULL) {
  div(class = paste("stat-tile", color),
      div(class = "stat-label", label),
      div(class = "stat-value", value),
      if (!is.null(pct)) progress_bar(pct),
      if (!is.null(note)) div(class = "stat-note", note))
}
