# ============================================================================
# DALLE IMAGE GENERATOR - PACKAGE INSTALLER
# Run this script first to install all required packages
# ============================================================================

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║  DALL-E IMAGE GENERATOR - PACKAGE INSTALLATION SCRIPT    ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# List of required packages
required_packages <- c(
  # Core Shiny packages
  "shiny",
  "shinydashboard",
  
  # Utilities
  "R6",
  "yaml",
  "purrr",
  
  # API and JSON handling
  "httr",
  "jsonlite",
  "base64enc",
  
  # File handling
  "shinyFiles",
  
  # Image processing
  "magick"
)

cat("📦 Checking for required packages...\n\n")

# Function to install a single package
install_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing:", pkg, "...\n")
    install.packages(pkg, dependencies = TRUE)
    cat("✓", pkg, "installed\n\n")
  } else {
    cat("✓", pkg, "already installed\n")
  }
}

# Install all packages
for (pkg in required_packages) {
  tryCatch({
    install_package(pkg)
  }, error = function(e) {
    cat("✗ Failed to install", pkg, "\n")
    cat("  Error:", e$message, "\n\n")
    
    if (pkg == "magick") {
      cat("\n⚠️  IMPORTANT: The 'magick' package requires ImageMagick system library\n")
      cat("   Please install ImageMagick first:\n\n")
      cat("   Ubuntu/Debian: sudo apt-get install libmagick++-dev\n")
      cat("   macOS:         brew install imagemagick\n")
      cat("   Windows:       Download from https://imagemagick.org/script/download.php\n\n")
      cat("   Then run this script again.\n\n")
    }
  })
}

cat("\n" , rep("=", 60), "\n")
cat("📊 Installation Summary\n")
cat(rep("=", 60), "\n\n")

# Check which packages are now available
installed_count <- 0
failed_packages <- c()

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✓", pkg, "\n")
    installed_count <- installed_count + 1
  } else {
    cat("✗", pkg, "(FAILED)\n")
    failed_packages <- c(failed_packages, pkg)
  }
}

cat("\n" , rep("=", 60), "\n")
cat("Results:", installed_count, "/", length(required_packages), "packages installed\n")
cat(rep("=", 60), "\n\n")

if (length(failed_packages) > 0) {
  cat("⚠️  The following packages failed to install:\n")
  for (pkg in failed_packages) {
    cat("   -", pkg, "\n")
  }
  cat("\nPlease install these manually before running the app.\n\n")
} else {
  cat("✅ All packages installed successfully!\n\n")
  cat("You can now run the app with:\n")
  cat("   shiny::runApp()\n\n")
}

cat("For more information, see README.md\n\n")
