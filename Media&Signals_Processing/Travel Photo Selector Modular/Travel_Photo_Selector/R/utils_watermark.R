# ============================================================================
# WATERMARK ("SELLO DE AGUA") UTILITIES
# Draws "País – Ciudad/Región/Evento" in the bottom-right corner of a photo.
#
# The label is drawn with ragg + systemfonts (they can load a font straight
# from a .ttf file, on Windows, Mac and Linux alike) and then pasted onto the
# photo with magick.
# ============================================================================

# Easy-to-read fonts. Bundled ones (www/fonts, SIL Open Font License) always work;
# "system" ones are only offered if the computer has them installed.
WM_FONTS <- list(
  list(id = "atkinson", label = "Atkinson Hyperlegible – hecha para baja visión (recomendada)",
       family = "TPS Atkinson Hyperlegible", css = "TPS Atkinson Hyperlegible",
       regular = "www/fonts/AtkinsonHyperlegible-Regular.ttf", bold = "www/fonts/AtkinsonHyperlegible-Bold.ttf"),
  list(id = "andika", label = "Andika – letras claras y redondas",
       family = "TPS Andika", css = "TPS Andika",
       regular = "www/fonts/Andika-Regular.ttf", bold = "www/fonts/Andika-Bold.ttf"),
  list(id = "lexend", label = "Lexend – letras amplias, fácil de leer",
       family = "TPS Lexend", css = "TPS Lexend",
       regular = "www/fonts/Lexend-Regular.ttf", bold = "www/fonts/Lexend-Bold.ttf"),
  list(id = "verdana", label = "Verdana (de la computadora)", system = "Verdana", css = "Verdana"),
  list(id = "tahoma", label = "Tahoma (de la computadora)", system = "Tahoma", css = "Tahoma"),
  list(id = "arial", label = "Arial (de la computadora)", system = "Arial", css = "Arial"),
  list(id = "dejavu", label = "DejaVu Sans (de la computadora)", system = "DejaVu Sans", css = "DejaVu Sans")
)

WM_STYLES <- c(
  "Letras blancas sobre franja oscura (la más legible)" = "dark_box",
  "Letras blancas con contorno negro" = "outline",
  "Letras negras sobre franja blanca" = "light_box"
)

# Register bundled fonts and work out which fonts are available on this computer
init_watermark_fonts <- function(app_dir = ".") {
  ok <- requireNamespace("systemfonts", quietly = TRUE) && requireNamespace("ragg", quietly = TRUE)
  if (!ok) return(list())
  sys_families <- tryCatch(unique(systemfonts::system_fonts()$family), error = function(e) character())
  avail <- list()
  for (f in WM_FONTS) {
    if (!is.null(f$regular)) {
      reg <- file.path(app_dir, f$regular); bld <- file.path(app_dir, f$bold)
      if (!file.exists(reg)) next
      if (!file.exists(bld)) bld <- reg
      res <- tryCatch({
        systemfonts::register_font(f$family, plain = normalizePath(reg), bold = normalizePath(bld),
                                   italic = normalizePath(reg), bolditalic = normalizePath(bld))
        TRUE
      }, error = function(e) grepl("already", conditionMessage(e)))
      if (isTRUE(res)) avail[[f$id]] <- f
    } else if (f$system %in% sys_families) {
      f$family <- f$system
      avail[[f$id]] <- f
    }
  }
  avail
}

watermark_text <- function(country, subfolder) {
  if (is.null(subfolder) || !nzchar(subfolder) || identical(subfolder, LOOSE_LABEL)) country
  else paste(country, "–", subfolder)
}

# Render the label as a transparent PNG (magick image) of a given font size in pixels
render_watermark_label <- function(text, family, size_px, bold = TRUE, style = "dark_box") {
  size_px <- max(8, round(size_px))
  text_w <- tryCatch(
    systemfonts::string_width(text, family = family, bold = bold, size = size_px, res = 72),
    error = function(e) nchar(text) * size_px * 0.6)
  pad_x <- round(size_px * 0.5)
  w <- ceiling(text_w + 2 * pad_x + size_px * 0.1)
  h <- ceiling(size_px * 1.55)

  tmp <- tempfile(fileext = ".png")
  ragg::agg_png(tmp, width = w, height = h, units = "px", res = 72, background = "transparent")
  grid::grid.newpage()
  face <- if (isTRUE(bold)) "bold" else "plain"
  if (style %in% c("dark_box", "light_box")) {
    fill <- if (style == "dark_box") "#000000A6" else "#FFFFFFD9"
    grid::grid.roundrect(gp = grid::gpar(fill = fill, col = NA), r = grid::unit(0.18, "snpc"))
  }
  fg <- if (style == "light_box") "#111111" else "#FFFFFF"
  if (style == "outline") {
    d <- max(1, round(size_px * 0.06))
    for (a in seq(0, 2 * pi, length.out = 17)[-17]) {
      grid::grid.text(text, x = grid::unit(0.5, "npc") + grid::unit(d * cos(a), "points"),
                      y = grid::unit(0.5, "npc") + grid::unit(d * sin(a), "points"),
                      gp = grid::gpar(fontfamily = family, fontface = face, fontsize = size_px, col = "#000000"))
    }
  }
  grid::grid.text(text, x = 0.5, y = 0.5,
                  gp = grid::gpar(fontfamily = family, fontface = face, fontsize = size_px, col = fg))
  grDevices::dev.off()
  lbl <- magick::image_read(tmp)
  unlink(tmp)
  lbl
}

# Add the watermark to a magick image. size_pct = letter size as % of the photo's short side.
add_watermark <- function(img, text, family, size_pct = 5, bold = TRUE, style = "dark_box") {
  info <- magick::image_info(img)
  short <- min(info$width, info$height)
  size_px <- short * size_pct / 100
  lbl <- render_watermark_label(text, family, size_px, bold, style)
  # never wider than 92% of the photo
  li <- magick::image_info(lbl)
  if (li$width > 0.92 * info$width) {
    lbl <- magick::image_scale(lbl, as.character(floor(0.92 * info$width)))
  }
  m <- round(short * 0.025)
  magick::image_composite(img, lbl, operator = "over", gravity = "southeast",
                          offset = sprintf("+%d+%d", m, m))
}

# Approximate letter height in mm when printed at 10 x 15 cm (short side = 100 mm)
wm_letter_mm <- function(size_pct) round(100 * size_pct / 100 * 0.70, 1)
