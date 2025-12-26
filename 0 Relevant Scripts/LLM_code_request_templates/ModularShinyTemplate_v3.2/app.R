# app.R - Application Entry Point
# Version 3.0.1 - Production Ready with Cleanup

cat("\n╔════════════════════════════════════════╗\n")
cat("║  STARTING MODULAR SHINY APP v3.0      ║\n")
cat("╚════════════════════════════════════════╝\n\n")

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
  
  # Close API connections
  if (exists("api_manager") && !is.null(api_manager)) {
    if (!is.null(api_manager$bq_authenticated) && api_manager$bq_authenticated) {
      tryCatch({
        # Deauthenticate BigQuery
        bigrquery::bq_deauth()
        cat("  ✓ BigQuery connection closed\n")
      }, error = function(e) {
        cat("  ⚠ Warning closing BigQuery:", e$message, "\n")
      })
    }
    
    # Close other API connections
    if (!is.null(api_manager$api_key)) {
      cat("  ✓ API session cleared\n")
    }
  }
  
  # Close database connections (add your specific DBs here)
  # Example:
  # if (exists("db_conn")) {
  #   DBI::dbDisconnect(db_conn)
  # }
  
  # Clean up temporary files
  temp_files <- list.files(pattern = "^temp_.*\\.(csv|rds|tmp)$")
  if (length(temp_files) > 0) {
    file.remove(temp_files)
    cat("  ✓ Temporary files removed:", length(temp_files), "\n")
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

# Wrap shinyApp call to add cleanup and error handling
app <- shinyApp(
  ui = create_ui(module_loader),
  
  server = function(input, output, session) {
    
    # Initialize server with all enabled modules
    tryCatch({
      create_server(module_loader, api_manager, session)
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
