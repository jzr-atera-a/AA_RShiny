# app.R - Welch Group Fleet Monitor
# Entry point – matches IntegratedAVSuite architecture

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  WELCH GROUP FLEET MONITOR v1.0 - STARTING          ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

# ── Source configuration + utilities ──────────────────────────────
source("global.R")

# ── Initialise module loader ───────────────────────────────────────
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

# ── Session cleanup ────────────────────────────────────────────────
cleanup_session <- function() {
  cat("\n🧹 Cleaning up session...\n")
  gc(verbose = FALSE)
  cat("  ✓ Memory freed\n✓ Cleanup complete\n\n")
}

# ── Error logger ───────────────────────────────────────────────────
log_error <- function(error_msg) {
  error_log <- file.path(getwd(), "app_error.log")
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  tryCatch(
    write(paste0(timestamp, " - ERROR: ", error_msg, "\n"),
          file = error_log, append = TRUE),
    error = function(e) cat("⚠ Could not write to log file\n")
  )
}

# ── Application ────────────────────────────────────────────────────
app <- shinyApp(
  ui = create_ui(module_loader),

  server = function(input, output, session) {
    tryCatch({
      # CRITICAL: create_server does NOT forward session to module servers
      # Module servers call moduleServer() internally which manages session scope
      create_server(module_loader, api_manager, session)
      cat("✓ Server initialised\n")
    }, error = function(e) {
      cat("❌ Server init error:", e$message, "\n")
      log_error(paste("Server initialization failed:", e$message))
    })

    session$onSessionEnded(cleanup_session)
    cat("✓ Session started:", session$token, "\n")
  },

  options = list(
    port           = getOption("shiny.port",          3839),
    host           = getOption("shiny.host",          "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  ),

  enableBookmarking = "url"
)

app
