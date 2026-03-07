# app.R - Application Entry Point
# WP5 Omniverse AR Visualization - COMPLETE WITH FLASK & QUEST 3

cat("\n╔════════════════════════════════════════╗\n")
  cat("║  WP5 OMNIVERSE AR v2.0 - STARTING      ║\n")
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
    
    # Create reactive API manager here (in server context)
    api_manager <- reactiveValues(
      omniverse_scenarios = NULL,
      selected_scenario = NULL
    )
    
    # Initialize server with reactive api_manager
    create_server(module_loader, api_manager, session)
    
    # Log session start
    cat("✓ Session started:", session$token, "\n")
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