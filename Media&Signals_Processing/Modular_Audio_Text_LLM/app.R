# ============================================================================
# AUDIO PROCESSING DASHBOARD - MODULAR ARCHITECTURE
# Entry Point
# ============================================================================

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║    AUDIO PROCESSING DASHBOARD - STARTING APPLICATION     ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Load global configuration
source("global.R")

# Initialize module loader
cat("📦 Initializing Module Loader...\n")
module_loader <- ModuleLoader$new()
module_loader$print()

# Load packages for enabled modules
cat("📚 Loading packages...\n")
module_loader$load_packages()

# Source module files
cat("🔧 Loading module code...\n")
module_loader$source_modules()

# Initialize API manager
cat("🔑 Initializing API Manager...\n")
api_manager <- APIManager$new()

cat("\n✅ Initialization complete!\n")
cat("🚀 Launching Shiny application...\n\n")

# Run application
shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    # Initialize all enabled module servers
    create_server(module_loader, api_manager, session)
    
    # Memory cleanup on session end
    session$onSessionEnded(function() {
      cat("\n🧹 Cleaning up session resources...\n")
      gc(verbose = FALSE)
      cat("✅ Session cleanup complete\n")
    })
  }
)
