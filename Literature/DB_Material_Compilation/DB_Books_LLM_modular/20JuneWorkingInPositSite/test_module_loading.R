# test_module_loading.R
# Quick test to verify module loading works

# Set working directory to app location
# setwd("path/to/BookSummaryApp")

# Source global.R
source("global.R")

# Create module loader
module_loader <- ModuleLoader$new()

# Print status
cat("\n=== MODULE LOADER TEST ===\n")
module_loader$print()

# Test module loading
cat("\n=== LOADING PACKAGES ===\n")
module_loader$load_packages()

cat("\n=== SOURCING MODULES ===\n")
module_loader$source_modules()

# Test menu generation
cat("\n=== TESTING MENU GENERATION ===\n")
menu_items <- module_loader$generate_menu_items()
cat("Generated", length(menu_items), "menu items\n")

# Test tab generation
cat("\n=== TESTING TAB GENERATION ===\n")
tab_items <- module_loader$generate_tab_items()
cat("Generated", length(tab_items), "tab items\n")

# Check each tab item
for (i in seq_along(tab_items)) {
  tab <- tab_items[[i]]
  if (!is.null(tab)) {
    cat("  Tab", i, ":", class(tab), "\n")
  } else {
    cat("  Tab", i, ": NULL (ERROR!)\n")
  }
}

# Test if UI functions exist
cat("\n=== CHECKING UI FUNCTIONS ===\n")
enabled <- module_loader$get_enabled_modules()
for (mod in enabled) {
  ui_fn_name <- paste0(mod$module$id, "_ui")
  server_fn_name <- paste0(mod$module$id, "_server")
  
  ui_exists <- exists(ui_fn_name, envir = .GlobalEnv)
  server_exists <- exists(server_fn_name, envir = .GlobalEnv)
  
  cat("Module:", mod$module$id, "\n")
  cat("  UI function:", ifelse(ui_exists, "✓", "✗"), ui_fn_name, "\n")
  cat("  Server function:", ifelse(server_exists, "✓", "✗"), server_fn_name, "\n")
}

cat("\n=== TEST COMPLETE ===\n")
cat("If all checks passed, the app should work!\n")
