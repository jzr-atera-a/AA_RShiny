# ============================================================================
# Creates a small demo folder structure with coloured placeholder photos,
# so the app can be tried before pointing it at the real travel photos.
#
#   Rscript tools/make_demo_photos.R  [destination]   (default: ~/Demo_Travel_Photos)
# ============================================================================

suppressPackageStartupMessages(library(magick))

args <- commandArgs(trailingOnly = TRUE)
dest <- if (length(args)) args[1] else file.path(path.expand("~"), "Demo_Travel_Photos")

structure <- list(
  "México"  = c("Cancún" = 80, "Ciudad de México" = 20),
  "España"  = c("Barcelona" = 30, "Madrid" = 18, "Boda de Lucía" = 12),
  "Italia"  = c("Roma" = 25, "Toscana" = 15)
)

cols <- c("#667eea", "#764ba2", "#11998e", "#38ef7d", "#f39c12", "#e74c3c", "#2c3e50", "#3498db")
for (country in names(structure)) {
  for (place in names(structure[[country]])) {
    d <- file.path(dest, country, place)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    for (i in seq_len(structure[[country]][[place]])) {
      w <- if (i %% 3 == 0) 600 else 900
      h <- if (i %% 3 == 0) 900 else 600
      img <- image_blank(w, h, cols[(i %% length(cols)) + 1])
      img <- image_annotate(img, sprintf("%s\n%s\n#%d", country, place, i),
                            size = 54, color = "white", gravity = "center", weight = 700)
      image_write(img, file.path(d, sprintf("IMG_%04d.jpg", i)), format = "jpeg", quality = 80)
    }
  }
}
cat("Demo photos created in:", normalizePath(dest), "\n")
