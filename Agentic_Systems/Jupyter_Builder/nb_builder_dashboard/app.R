# ============================================================================
# NOTEBOOK BUILDER DASHBOARD  —  Entry Point
# ============================================================================

cat("\n📦 Initialising Module Loader...\n")
source("global.R")

module_loader <- ModuleLoader$new()
module_loader$print()

cat("\n📚 Loading packages...\n")
module_loader$load_packages()

cat("\n🔧 Sourcing module code...\n")
module_loader$source_modules()

cat("\n🔑 Initialising Session Manager...\n")
session_mgr <- SessionManager$new()

cat("\n🐍 Initialising Python Bridge...\n")
python_bridge <- PythonBridge$new(
  python_path = session_mgr$get("python_env_path", NULL)
)

cat("\n✅ Initialisation complete!\n")
cat("🚀 Launching Shiny application...\n\n")

shinyApp(
  ui = create_ui(module_loader),

  server = function(input, output, session) {
    create_server(module_loader, session_mgr, python_bridge, session)

    session$onSessionEnded(function() {
      cat("\n🧹 Session ended — cleaning up...\n")
      if (python_bridge$is_running()) {
        cat("  ℹ Python process left running (cleanup = FALSE)\n")
      }
      gc(verbose = FALSE)
    })
  }
)
