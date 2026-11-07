# app.R - ML Interviews Prep Suite
# Based on: Machine Learning Interviews — Susan Shu Chang (O'Reilly)

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  ML INTERVIEWS PREP SUITE v1.0 - STARTING         ║\n")
cat("╚════════════════════════════════════════════════════╝\n\n")

source("global.R")

module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

app <- shinyApp(
  ui = create_ui(module_loader),

  server = function(input, output, session) {

    prep_mgr <- PrepManager$new()

    tryCatch({
      create_server(module_loader, prep_mgr)
      cat("✓ Server initialized successfully\n")
    }, error = function(e) {
      cat("❌ Error initializing server:", e$message, "\n")
    })

    session$onSessionEnded(function() {
      gc(verbose = FALSE)
      cat("✓ Session ended:", format(Sys.time()), "\n")
    })
    cat("✓ Session started:", session$token, "\n")
  }
)

app
