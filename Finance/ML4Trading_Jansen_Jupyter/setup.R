# setup.R
# Quick setup script for ML Trading Interactive Learning Platform

cat("========================================\n")
cat("ML Trading App - Setup\n")
cat("========================================\n\n")

# Check if we're in the right directory
if (!file.exists("app.R")) {
  stop("Error: Please run this script from the MLTradingApp directory")
}

# Required packages
required_packages <- c(
  "shiny",
  "shinydashboard",
  "plotly",
  "DT",
  "dplyr",
  "ggplot2"
)

cat("Installing required packages...\n")
cat("-------------------------------\n")

new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if(length(new_packages) > 0) {
  cat(sprintf("Installing %d package(s): %s\n", 
              length(new_packages),
              paste(new_packages, collapse = ", ")))
  install.packages(new_packages, dependencies = TRUE)
} else {
  cat("✓ All required packages already installed!\n")
}

cat("\nVerifying installation...\n")
cat("-------------------------\n")

all_installed <- TRUE
for (pkg in required_packages) {
  if (pkg %in% installed.packages()[,"Package"]) {
    cat(sprintf("✓ %s\n", pkg))
  } else {
    cat(sprintf("✗ %s - MISSING\n", pkg))
    all_installed <- FALSE
  }
}

cat("\n")

if (all_installed) {
  cat("========================================\n")
  cat("✓ Setup Complete!\n")
  cat("========================================\n\n")
  cat("To run the app:\n")
  cat("  shiny::runApp()\n\n")
} else {
  cat("========================================\n")
  cat("⚠ Setup Incomplete\n")
  cat("========================================\n\n")
  cat("Some packages failed to install.\n")
  cat("Try installing manually:\n")
  cat("  install.packages(c('", paste(required_packages, collapse = "', '"), "'))\n\n", sep = "")
}
