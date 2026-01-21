# app.R - Application Entry Point
# Greenwich AV Project Data Extraction - Modular Architecture v1.0

cat("\n╔════════════════════════════════════════════════╗\n")
cat("║  GREENWICH AV PROJECT v1.0 - STARTING         ║\n")
cat("║  VR Autonomous Vehicle Simulation Data        ║\n")
cat("╚════════════════════════════════════════════════╝\n\n")

# Source configuration
source("global.R")

# Initialize module loader
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

# ═══════════════════════════════════════════════════════
# CLEANUP FUNCTION - CRITICAL FOR PRODUCTION
# ═══════════════════════════════════════════════════════
cleanup_session <- function() {
  cat("\n🧹 Cleaning up session...\n")
  
  # Clean up temporary files
  temp_files <- list.files(pattern = "^temp_.*\\.(geojson|tif|png|csv|rds|tmp)$")
  if (length(temp_files) > 0) {
    file.remove(temp_files)
    cat("  ✓ Temporary files removed:", length(temp_files), "\n")
  }
  
  # Clean up downloaded data in temp directory
  if (dir.exists("temp_downloads")) {
    unlink("temp_downloads", recursive = TRUE)
    cat("  ✓ Temporary download directory removed\n")
  }
  
  # Garbage collection
  gc(verbose = FALSE)
  cat("  ✓ Memory freed\n")
  cat("✓ Cleanup complete\n\n")
}

# ═══════════════════════════════════════════════════════
# ERROR HANDLER - LOG FAILURES
# ═══════════════════════════════════════════════════════
log_error <- function(error_msg) {
  error_log <- file.path(getwd(), "app_error.log")
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0(timestamp, " - ERROR: ", error_msg, "\n")
  
  tryCatch({
    write(log_entry, file = error_log, append = TRUE)
    cat("❌ Error logged to:", error_log, "\n")
  }, error = function(e) {
    cat("⚠ Could not write to log file\n")
  })
}

# ═══════════════════════════════════════════════════════
# RUN APPLICATION - MUST RETURN shinyApp OBJECT
# ═══════════════════════════════════════════════════════

app <- shinyApp(
  ui = create_ui(module_loader),
  
  server = function(input, output, session) {
    
    # Initialize server with all enabled modules
    tryCatch({
      create_server(module_loader, session)
      cat("✓ Server initialized successfully\n")
    }, error = function(e) {
      cat("❌ Error initializing server:", e$message, "\n")
      log_error(paste("Server initialization failed:", e$message))
    })
    
    # Register cleanup on session end
    session$onSessionEnded(function() {
      cleanup_session()
    })
    
    # Log session start
    cat("✓ Session started:", session$token, "\n")
  },
  
  # Application options
  options = list(
    port = getOption("shiny.port", 3838),
    host = getOption("shiny.host", "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  ),
  
  # Enable bookmarking (optional)
  enableBookmarking = "url"
)

# Return the app object (CRITICAL!)
app
