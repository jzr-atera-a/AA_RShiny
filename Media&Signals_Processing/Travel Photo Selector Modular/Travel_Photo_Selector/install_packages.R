# ============================================================================
# TRAVEL PHOTO SELECTOR - PACKAGE INSTALLER
# Run this script once to install all required packages
# ============================================================================

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║   TRAVEL PHOTO SELECTOR - PACKAGE INSTALLATION SCRIPT     ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

required_packages <- c(
  # Core Shiny packages
  "shiny", "shinydashboard",
  # Utilities
  "R6", "yaml", "jsonlite", "digest", "fs",
  # Folder browsing
  "shinyFiles",
  # Image previews (thumbnails, EXIF rotation, HEIC/TIFF support)
  "magick",
  # Watermark ("sello de agua") with bundled easy-to-read fonts
  "ragg", "systemfonts"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing:", pkg, "...\n")
    install.packages(pkg, dependencies = TRUE)
  } else {
    cat("✓", pkg, "already installed\n")
  }
}

cat("\n✅ Done. Start the app with:  shiny::runApp(launch.browser = TRUE)\n\n")
