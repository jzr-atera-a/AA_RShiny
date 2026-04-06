# global.R - CAV Route Optimizer
# Global initialization and UI/Server factories

# Suppress package startup messages
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
  library(jsonlite)
  library(DT)
  library(leaflet)
  library(htmltools)
})

# Try to load reticulate (Python integration)
python_available <- requireNamespace("reticulate", quietly = TRUE)

if (python_available) {
  library(reticulate)
  cat("✓ Reticulate loaded - Python integration available\n")
} else {
  cat("⚠ Reticulate not installed - Python features disabled\n")
  cat("  Install with: install.packages('reticulate')\n")
}

# Source R utilities
cat("→ Loading R utilities...\n")
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_cav.R")

# Source Python utilities only if reticulate is available
if (python_available) {
  source("R/utils_python.R")
  
  # Try to initialize Python environment
  tryCatch({
    init_python_env()
    cat("✓ Python environment initialized\n")
  }, error = function(e) {
    cat("⚠ Python initialization failed:", e$message, "\n")
    cat("  Python features may not work. See SETUP_GUIDE.md\n")
  })
}

# Create UI factory function
create_ui <- function(module_loader) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Create menu items
  menu_items <- lapply(enabled_modules, function(mod) {
    manifest <- mod$manifest
    menuItem(
      manifest$menu$label,
      tabName = manifest$menu$tabname,
      icon = icon(manifest$menu$icon)
    )
  })
  
  # Create tab items
  tab_items <- lapply(enabled_modules, function(mod) {
    manifest <- mod$manifest
    ui_func <- get(paste0(manifest$id, "_ui"))
    
    tabItem(
      tabName = manifest$menu$tabname,
      ui_func(manifest$id)
    )
  })
  
  # Build dashboard
  dashboardPage(
    dashboardHeader(title = "CAV Route Optimizer"),
    
    dashboardSidebar(
      sidebarMenu(
        menuItem("Home", tabName = "home", icon = icon("home")),
        do.call(tagList, menu_items)
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")
      ),
      
      do.call(tabItems, list(
        tabItem(
          tabName = "home",
          
          fluidRow(
            box(
              title = "Welcome to CAV Route Optimizer",
              status = "primary",
              solidHeader = TRUE,
              width = 12,
              
              h3("Computer Vision-Based Route Risk Assessment"),
              
              p("This application integrates Python backend for ML-powered 
                CAV (Connected Autonomous Vehicle) risk detection and analysis."),
              
              tags$hr(),
              
              h4("Complete Workflow:"),
              tags$ol(
                tags$li(strong("Route Sampler:"), 
                       "Extract route from Google Maps and generate waypoints"),
                tags$li(strong("Feature Detector:"), 
                       "Detect road features from OpenStreetMap data"),
                tags$li(strong("Street View Capture:"), 
                       "Download Google Street View images via Python backend"),
                tags$li(strong("YOLO Detector:"), 
                       "Run ML inference using YOLOv8 model"),
                tags$li(strong("Risk Map:"), 
                       "Visualize detected risks on interactive map")
              ),
              
              tags$hr(),
              
              h4("Technical Stack:"),
              fluidRow(
                column(6,
                  tags$ul(
                    tags$li(icon("r-project"), " R + Shiny (UI & Orchestration)"),
                    tags$li(icon("python"), " Python (ML & API Integration)"),
                    tags$li(icon("map"), " Google Maps API")
                  )
                ),
                column(6,
                  tags$ul(
                    tags$li(icon("brain"), " YOLOv8 Object Detection"),
                    tags$li(icon("map-marked-alt"), " OpenStreetMap Data"),
                    tags$li(icon("camera"), " Street View Static API")
                  )
                )
              )
            )
          ),
          
          fluidRow(
            box(
              title = "Quick Start",
              status = "success",
              solidHeader = TRUE,
              width = 6,
              
              tags$ol(
                tags$li("Ensure Python environment is set up (see SETUP_GUIDE.md)"),
                tags$li("Get Google Maps API key"),
                tags$li("Start with Route Sampler tab"),
                tags$li("Follow the workflow sequentially")
              )
            ),
            
            box(
              title = "System Status",
              status = "info",
              solidHeader = TRUE,
              width = 6,
              
              uiOutput("system_status_home")
            )
          )
        ),
        
        do.call(tabItems, tab_items)
      ))
    )
  )
}

# Create server factory function
create_server <- function(module_loader, api_manager, session) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Initialize all module servers
  lapply(enabled_modules, function(mod) {
    manifest <- mod$manifest
    server_func <- get(paste0(manifest$id, "_server"))
    server_func(manifest$id, api_manager = api_manager)
  })
  
  # Add system status output for home page
  output$system_status_home <- renderUI({
    
    status <- if (exists("check_python_status")) {
      tryCatch(check_python_status(), error = function(e) {
        list(python_available = FALSE)
      })
    } else {
      list(python_available = FALSE)
    }
    
    tagList(
      tags$div(
        tags$p(
          icon(if(status$python_available) "check-circle" else "times-circle"),
          strong(" Python:"),
          if(status$python_available) "Available" else "Not Available"
        ),
        if(status$python_available) {
          tagList(
            tags$p(icon("check"), " PyTorch:", 
                  if(status$torch_available) "Installed" else "Missing"),
            tags$p(icon("check"), " Ultralytics:", 
                  if(status$ultralytics_available) "Installed" else "Missing"),
            tags$p(icon("check"), " Google Maps:", 
                  if(status$googlemaps_available) "Installed" else "Missing")
          )
        } else {
          tags$p(class = "text-warning", 
                "Install Python dependencies for full functionality")
        }
      )
    )
  })
}

cat("✓ Global configuration loaded\n")
