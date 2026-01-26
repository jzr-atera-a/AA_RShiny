# ============================================================================
# DALLE IMAGE GENERATOR - SYSTEM VERIFICATION
# Run this to check if your system is ready to run the app
# ============================================================================

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║    DALL-E IMAGE GENERATOR - SYSTEM VERIFICATION          ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

check_result <- list()

# Check R version
cat("1. Checking R version...\n")
r_version <- getRversion()
if (r_version >= "4.0.0") {
  cat("   ✓ R version:", as.character(r_version), "(OK)\n\n")
  check_result$r_version <- TRUE
} else {
  cat("   ✗ R version:", as.character(r_version), "(Needs >= 4.0.0)\n\n")
  check_result$r_version <- FALSE
}

# Check required packages
cat("2. Checking required packages...\n")
required_packages <- c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "httr", "jsonlite", "base64enc", "shinyFiles", "magick"
)

packages_ok <- TRUE
for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("   ✓", pkg, "\n")
  } else {
    cat("   ✗", pkg, "(NOT INSTALLED)\n")
    packages_ok <- FALSE
  }
}
check_result$packages <- packages_ok
cat("\n")

# Check ImageMagick (for magick package)
cat("3. Checking ImageMagick (for image processing)...\n")
if (requireNamespace("magick", quietly = TRUE)) {
  tryCatch({
    magick_config <- magick::magick_config()
    cat("   ✓ ImageMagick version:", magick_config$version, "\n")
    cat("   ✓ Supported formats:", length(magick_config$formats), "formats\n\n")
    check_result$imagemagick <- TRUE
  }, error = function(e) {
    cat("   ✗ ImageMagick not properly configured\n")
    cat("   Install from: https://imagemagick.org/script/download.php\n\n")
    check_result$imagemagick <- FALSE
  })
} else {
  cat("   ✗ magick package not installed\n\n")
  check_result$imagemagick <- FALSE
}

# Check file structure
cat("4. Checking file structure...\n")
required_files <- c(
  "app.R",
  "global.R",
  "R/module_loader.R",
  "R/utils_api.R",
  "R/utils_common.R",
  "modules/_module_registry.yml",
  "modules/dalle_settings/ui.R",
  "modules/dalle_settings/server.R",
  "modules/image_generation/ui.R",
  "modules/image_generation/server.R",
  "www/css/global.css"
)

files_ok <- TRUE
for (file in required_files) {
  if (file.exists(file)) {
    cat("   ✓", file, "\n")
  } else {
    cat("   ✗", file, "(MISSING)\n")
    files_ok <- FALSE
  }
}
check_result$files <- files_ok
cat("\n")

# Check internet connection
cat("5. Checking internet connection...\n")
internet_ok <- tryCatch({
  test <- httr::GET("https://api.openai.com/v1/models", httr::timeout(5))
  TRUE
}, error = function(e) {
  FALSE
})

if (internet_ok) {
  cat("   ✓ Internet connection available\n\n")
  check_result$internet <- TRUE
} else {
  cat("   ✗ Cannot reach OpenAI API\n")
  cat("   Check your internet connection\n\n")
  check_result$internet <- FALSE
}

# Summary
cat(rep("=", 60), "\n")
cat("VERIFICATION SUMMARY\n")
cat(rep("=", 60), "\n\n")

all_passed <- all(unlist(check_result))

if (all_passed) {
  cat("✅ ALL CHECKS PASSED!\n\n")
  cat("Your system is ready to run the DALL-E Image Generator.\n\n")
  cat("To start the app, run:\n")
  cat("   shiny::runApp()\n\n")
  cat("Don't forget to:\n")
  cat("1. Get your OpenAI API key from https://platform.openai.com/api-keys\n")
  cat("2. Configure it in the DALL-E API Settings tab\n\n")
} else {
  cat("⚠️  SOME CHECKS FAILED\n\n")
  
  if (!check_result$r_version) {
    cat("❌ Please update R to version 4.0.0 or higher\n")
  }
  
  if (!check_result$packages) {
    cat("❌ Please install missing packages by running:\n")
    cat("   source('install_packages.R')\n")
  }
  
  if (!check_result$imagemagick) {
    cat("❌ Please install ImageMagick:\n")
    cat("   Ubuntu/Debian: sudo apt-get install libmagick++-dev\n")
    cat("   macOS:         brew install imagemagick\n")
    cat("   Windows:       https://imagemagick.org/script/download.php\n")
  }
  
  if (!check_result$files) {
    cat("❌ Some application files are missing\n")
    cat("   Please ensure all files are properly extracted\n")
  }
  
  if (!check_result$internet) {
    cat("❌ Cannot connect to OpenAI API\n")
    cat("   Check your internet connection and firewall settings\n")
  }
  
  cat("\nPlease resolve the issues above and run this verification again.\n\n")
}

cat("For detailed setup instructions, see README.md\n")
cat("For quick start, see QUICKSTART.md\n\n")
