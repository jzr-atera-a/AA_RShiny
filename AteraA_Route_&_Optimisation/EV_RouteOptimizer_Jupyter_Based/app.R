# app.R - CAV Route Optimizer Entry Point

cat("\n╔═══════════════════════════════════════════════════╗\n")
cat("║  CAV ROUTE OPTIMIZER v5.0 - STARTING              ║\n")
cat("║  Python-Integrated Computer Vision Analysis       ║\n")
cat("╚═══════════════════════════════════════════════════╝\n\n")

# Source global configuration
cat("→ Loading global configuration...\n")
source("global.R")

# Initialize module loader
cat("\n→ Initializing module system...\n")
module_loader <- ModuleLoader$new("modules/_module_registry.yml")

# Display loaded modules
cat("\n╔═══════════════════════════════════════════════════╗\n")
cat("║  LOADED MODULES                                   ║\n")
cat("╚═══════════════════════════════════════════════════╝\n\n")

enabled_modules <- module_loader$get_enabled_modules()

for (mod in enabled_modules) {
  manifest <- mod$manifest
  cat(sprintf("  ✓ [%02d] %s\n", 
              manifest$priority, 
              manifest$name))
  cat(sprintf("      └─ %s\n", manifest$description))
}

cat(sprintf("\n→ Total modules loaded: %d\n", length(enabled_modules)))

# Check Python environment
cat("\n→ Checking Python environment...\n")
python_status <- tryCatch({
  check_python_status()
}, error = function(e) {
  list(python_available = FALSE)
})

if (python_status$python_available) {
  cat("  ✓ Python available:", python_status$python_version, "\n")
  cat("  ✓ PyTorch:", if(python_status$torch_available) "YES" else "NO", "\n")
  cat("  ✓ Ultralytics:", if(python_status$ultralytics_available) "YES" else "NO", "\n")
  cat("  ✓ Google Maps:", if(python_status$googlemaps_available) "YES" else "NO", "\n")
} else {
  cat("  ⚠ Python not available - install dependencies for full functionality\n")
  cat("    See SETUP_GUIDE.md for instructions\n")
}

cat("\n╔═══════════════════════════════════════════════════╗\n")
cat("║  STARTING SHINY SERVER                            ║\n")
cat("╚═══════════════════════════════════════════════════╝\n\n")

# Run application
app <- shinyApp(
  ui = create_ui(module_loader),
  
  server = function(input, output, session) {
    
    # Create reactive API manager
    api_manager <- reactiveValues(
      cav_waypoints = NULL,
      cav_route_info = NULL,
      cav_features = NULL,
      cav_images = NULL,
      cav_detections = NULL,
      network_data = NULL
    )
    
    # Initialize all module servers
    create_server(module_loader, api_manager, session)
    
    # Log session start
    cat("\n✓ New session started:", session$token, "\n")
    cat("  User connected at:", as.character(Sys.time()), "\n\n")
  },
  
  # Application options
  options = list(
    port = getOption("shiny.port", 3838),
    host = getOption("shiny.host", "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  )
)

cat("→ Server ready. Opening browser...\n\n")

# Return the app object
app
