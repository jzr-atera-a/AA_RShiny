# app.R - Entry Point
# Project Application Assistant - Complete Modular Architecture
# =============================================================

rm(list = ls(all.names = TRUE))

source("global.R", local = FALSE)

cat("\n⚙️  Initializing Module Loader...\n")
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

cat("\n🚀 Launching Complete Application...\n\n")

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    create_server(module_loader, api_manager, session)
  }
)
