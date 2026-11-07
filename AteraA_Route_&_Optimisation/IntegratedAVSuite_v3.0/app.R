# app.R - Application Entry Point
# Integrated AV Development Suite - COMPLETE WITH DUAL VEHICLE SUPPORT

cat("\n╔════════════════════════════════════════╗\n")
cat("║  INTEGRATED AV SUITE v3.0 - STARTING   ║\n")
cat("║  Dual Vehicle + Physics Integration    ║\n")
cat("╚════════════════════════════════════════╝\n\n")

# Source configuration
source("global.R")

# Initialize module loader
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

# Run application
app <- shinyApp(
  ui = create_ui(module_loader),
  
  server = function(input, output, session) {
    
    # Create reactive API manager with ALL required fields
    api_manager <- reactiveValues(
      # BigQuery data
      bq_project_id = NULL,
      bq_dataset_id = NULL,
      bq_table_id = NULL,
      charging_points = NULL,
      
      # Road network data
      osm_data = NULL,
      graph = NULL,
      vertices = NULL,
      edges = NULL,
      
      # Route optimization
      origin = NULL,
      destination = NULL,
      optimized_route = NULL,
      route_stats = NULL,
      
      # Omniverse Isaac Sim data
      omniverse_scenarios = NULL,
      selected_scenario = NULL,
      
      # NEW: Vehicle configuration
      vehicle_config = NULL,
      sensor_config = NULL,
      physics_config = NULL
    )
    
    # Initialize server with reactive api_manager
    create_server(module_loader, api_manager, session)
    
    # Log session start
    cat("✓ Session started:", session$token, "\n")
    cat("✓ API Manager initialized with vehicle config support\n")
  },
  
  # Application options
  options = list(
    port = getOption("shiny.port", 3838),
    host = getOption("shiny.host", "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  )
)

# Return the app object
app
