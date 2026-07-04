# debug_tabs.R
# Debug script to see what tabs are being generated

source("global.R")

module_loader <- ModuleLoader$new()
module_loader$load_packages()
module_loader$source_modules()

cat("\n=== MENU ITEMS ===\n")
menu_items <- module_loader$generate_menu_items()
cat("Number of menu items:", length(menu_items), "\n")
for (i in seq_along(menu_items)) {
  item <- menu_items[[i]]
  cat("Menu", i, "class:", class(item), "\n")
  if ("attribs" %in% names(item)) {
    cat("  tabName:", item$attribs$`data-value`, "\n")
  }
}

cat("\n=== TAB ITEMS ===\n")
tab_items <- module_loader$generate_tab_items()
cat("Number of tab items:", length(tab_items), "\n")
for (i in seq_along(tab_items)) {
  item <- tab_items[[i]]
  cat("Tab", i, "class:", class(item), "\n")
  if ("attribs" %in% names(item)) {
    cat("  tabName:", item$attribs$`data-value`, "\n")
    cat("  role:", item$attribs$role, "\n")
  }
}

cat("\n=== TESTING UI STRUCTURE ===\n")
ui <- create_ui(module_loader)
cat("UI class:", class(ui), "\n")
cat("UI has body:", !is.null(ui$children[[3]]), "\n")

# Try to print the structure
cat("\n=== Attempting to render ===\n")
cat("If this produces HTML, tabs should work\n")
