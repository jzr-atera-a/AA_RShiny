# ============================================================================
# MI TESIS - PACKAGE INSTALLER
# Run this script once (from the app folder) to install all required packages
#   source("install_packages.R", encoding = "UTF-8")
# ============================================================================

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║          MI TESIS - PACKAGE INSTALLATION SCRIPT           ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

required_packages <- c(
  # Core Shiny packages
  "shiny", "shinydashboard",
  # Utilities
  "R6", "yaml", "jsonlite", "fs",
  # Claude API (HTTP requests)
  "httr",
  # Folder browsing (Administrador → carpeta de trabajo)
  "shinyFiles",
  # Optional: export the full thesis to Word (.docx)
  "officer"
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
