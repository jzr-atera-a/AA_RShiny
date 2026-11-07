# app.R - Integrated AV Development Suite
# Version 1.0 - Complete Integration

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  INTEGRATED AV DEVELOPMENT SUITE v1.0 - STARTING  ║\n")
cat("╚════════════════════════════════════════════════════╝\n\n")

# Source configuration
source("global.R")

# Initialize module loader
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

# Cleanup function
cleanup_session <- function() {
  cat("\n🧹 Cleaning up session...\n")
  
  if (exists("api_manager") && !is.null(api_manager)) {
    if (!is.null(api_manager$bq_authenticated) && api_manager$bq_authenticated) {
      tryCatch({
        bigrquery::bq_deauth()
        cat("  ✓ BigQuery connection closed\n")
      }, error = function(e) {
        cat("  ⚠ Warning closing BigQuery:", e$message, "\n")
      })
    }
  }
  
  temp_files <- list.files(pattern = "^temp_.*\\.(csv|rds|tmp)$")
  if (length(temp_files) > 0) {
    file.remove(temp_files)
    cat("  ✓ Temporary files removed:", length(temp_files), "\n")
  }
  
  gc(verbose = FALSE)
  cat("  ✓ Memory freed\n")
  cat("✓ Cleanup complete\n\n")
}

# Error logger
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

# Run application
app <- shinyApp(
  ui = create_ui(module_loader),
  
  server = function(input, output, session) {
    
    tryCatch({
      create_server(module_loader, api_manager, session)
      cat("✓ Server initialized successfully\n")
    }, error = function(e) {
      cat("❌ Error initializing server:", e$message, "\n")
      log_error(paste("Server initialization failed:", e$message))
    })
    
    session$onSessionEnded(function() {
      cleanup_session()
    })
    
    cat("✓ Session started:", session$token, "\n")
  },
  
  options = list(
    port = getOption("shiny.port", 3839),
    host = getOption("shiny.host", "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  ),
  
  enableBookmarking = "url"
)

app
