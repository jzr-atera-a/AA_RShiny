# ============================================================================
# MI TESIS - CIENCIAS POLÍTICAS Y ADMINISTRACIÓN PÚBLICA (IBERO)
# Modular architecture - Entry point
# ============================================================================

cat("\n╔═══════════════════════════════════════════════════════════╗\n")
cat("║        MI TESIS (CPyAP IBERO) - STARTING APPLICATION       ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Load global configuration
source("global.R", encoding = "UTF-8")

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

# Shared state + persistence (like PhotoManager / APIManager in the templates)
cat("🗂  Initializing Thesis Manager...\n")
thesis_manager <- ThesisManager$new(data_dir = "data")
thesis_manager$print()

cat("\n✅ Initialization complete!\n")
cat("🚀 Launching Shiny application...\n\n")

shinyApp(
  ui = create_ui(module_loader, thesis_manager),
  server = function(input, output, session) {
    create_server(module_loader, thesis_manager, session, input, output)

    session$onSessionEnded(function() {
      cat("\n🧹 Cleaning up session resources...\n")
      gc(verbose = FALSE)
      cat("✅ Session cleanup complete\n")
    })
  }
)
