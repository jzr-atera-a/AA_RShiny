# app.R - Entry Point with Automatic Cleanup
# Business Model Canvas Manager - Modular Architecture

# ===== AUTOMATIC CLEANUP =====
# Clear all objects to ensure fresh load every time
rm(list = ls(all.names = TRUE))

# Clear loaded functions and classes
if (exists("ModuleLoader")) rm(ModuleLoader)
if (exists("APIManager")) rm(APIManager)
if (exists("module_loader")) rm(module_loader)
if (exists("api_manager")) rm(api_manager)

# Detach any previously loaded module functions
loaded_objects <- ls(envir = .GlobalEnv)
module_functions <- grep("_(ui|server)$", loaded_objects, value = TRUE)
if (length(module_functions) > 0) {
  rm(list = module_functions, envir = .GlobalEnv)
}

# ===== LOAD FRESH =====
# Force reload of global configuration
source("global.R", local = FALSE)

# Initialize module loader (fresh instance)
cat("\n⚙️  Initializing Module Loader...\n")
module_loader <- ModuleLoader$new()
module_loader$print()              # Show what's loading
module_loader$load_packages()      # Conditional package loading
module_loader$source_modules()     # Source enabled modules

cat("\n🚀 Launching application...\n\n")

# Run application with fresh instances
shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    
    # Cleanup on session end
    session$onSessionEnded(function() {
      if (!is.null(api_manager)) {
        api_manager$clear_all_credentials()
      }
    })
    
    # Initialize server with fresh instances
    create_server(module_loader, api_manager, session)
  }
)