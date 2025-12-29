# app.R - Entry Point
# Multi-Asset Analysis Dashboard - Modular Architecture
# =====================================================

# Clear everything
rm(list = ls(all.names = TRUE))
if (exists("ModuleLoader")) rm(ModuleLoader)
if (exists("DataManager")) rm(DataManager)
if (exists("module_loader")) rm(module_loader)
if (exists("data_manager")) rm(data_manager)

# Clear old module functions
loaded_objects <- ls(envir = .GlobalEnv)
module_functions <- grep("_(ui|server)$", loaded_objects, value = TRUE)
if (length(module_functions) > 0) {
  rm(list = module_functions, envir = .GlobalEnv)
}

# Load global configuration
source("global.R", local = FALSE)

cat("\n⚙️  Initializing Module Loader...\n")
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

cat("\n🚀 Launching application...\n\n")

# Launch app
shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    # Cleanup on session end
    session$onSessionEnded(function() {
      if (!is.null(data_manager)) {
        tryCatch({
          # Cleanup code here
        }, error = function(e) {})
      }
    })
    
    # Initialize server - pass input, output, session
    create_server(module_loader, data_manager, input, output, session)
  }
)
