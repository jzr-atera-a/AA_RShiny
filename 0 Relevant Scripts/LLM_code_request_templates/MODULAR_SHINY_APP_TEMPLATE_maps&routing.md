# Modular Shiny App Development Template
## For Maps, Routing, and GCP Integration

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Module Development Guide](#module-development-guide)
5. [Critical Dependencies](#critical-dependencies)
6. [GCP Integration](#gcp-integration)
7. [Routing & Mapping](#routing--mapping)
8. [Common Pitfalls & Solutions](#common-pitfalls--solutions)
9. [Deployment Checklist](#deployment-checklist)

---

## Architecture Overview

### Design Principles
- **Modular Architecture**: Each feature is a self-contained module
- **Centralized State Management**: R6 class for shared state across modules
- **Dynamic Loading**: Modules loaded based on registry configuration
- **Reactive Communication**: Modules communicate through shared R6 manager

### Key Benefits
- Easy to add/remove features
- Independent module testing
- Clear separation of concerns
- Scalable codebase

---

## Project Structure

```
your-app/
├── app.R                          # Application entry point
├── global.R                       # Global configuration & utilities
├── R/
│   ├── module_loader.R           # R6 class for dynamic module loading
│   ├── utils_common.R            # Shared utility functions
│   └── utils_bigquery.R          # GCP BigQuery manager (R6 class)
├── modules/
│   ├── _module_registry.yml      # Central module configuration
│   ├── module_name/
│   │   ├── manifest.yml          # Module metadata & dependencies
│   │   ├── ui.R                  # Module UI function
│   │   ├── server.R              # Module server function
│   │   └── README.md             # Module documentation
│   └── another_module/
│       └── ...
└── www/
    └── css/
        └── global.css            # Application styling
```

---

## Core Components

### 1. app.R - Application Entry Point

```r
# app.R - Application Entry Point

cat("\n╔════════════════════════════════════════╗\n")
cat("║  YOUR APP NAME - STARTING              ║\n")
cat("╚════════════════════════════════════════╝\n\n")

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
  
  # Close GCP connections
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
  
  # Clean temporary files
  temp_files <- list.files(pattern = "^temp_.*\\.(csv|rds|tmp)$")
  if (length(temp_files) > 0) {
    file.remove(temp_files)
    cat("  ✓ Temporary files removed:", length(temp_files), "\n")
  }
  
  gc(verbose = FALSE)
  cat("  ✓ Memory freed\n")
  cat("✓ Cleanup complete\n\n")
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
    })
    
    session$onSessionEnded(function() {
      cleanup_session()
    })
    
    cat("✓ Session started:", session$token, "\n")
  },
  
  options = list(
    port = getOption("shiny.port", 3838),
    host = getOption("shiny.host", "0.0.0.0"),
    launch.browser = getOption("shiny.launch.browser", TRUE)
  ),
  
  enableBookmarking = "url"
)

app
```

### 2. global.R - Global Configuration

```r
# global.R - Global Configuration

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)     # CRITICAL: Load pipe operator
  library(dplyr)
  library(sf)
  library(osmdata)
  library(tmaptools)    # CRITICAL: For geocoding
  library(dodgr)        # CRITICAL: For routing
  library(bigrquery)    # For GCP BigQuery
  library(leaflet)      # For maps
  library(htmltools)
  library(jsonlite)     # For API calls
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_bigquery.R")

# Initialize shared state manager
api_manager <- BigQueryManager$new()

# UI creation function
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname %||% module_id
    
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_function(module_id))
    } else {
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(box(title = paste("Module:", module$module$name), status = "warning", width = 12,
                     h4("Module enabled but not implemented")))
      )
    }
  }
  
  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(menu_info$label, tabName = menu_info$tabname, icon = icon(menu_info$icon))
  })
  
  dashboardPage(
    dashboardHeader(title = module_loader$registry$app$name %||% "Your App Name"),
    dashboardSidebar(sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu_items))),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# Server creation function
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x
cat("✓ Global configuration complete\n\n")
```

### 3. R/module_loader.R - Module Loader R6 Class

```r
# R/module_loader.R - Module Loader R6 Class

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6Class(
  "ModuleLoader",
  
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    initialize = function() {
      self$load_registry()
      self$discover_modules()
    },
    
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found: ", registry_path)
      }
      self$registry <- yaml::read_yaml(registry_path)
    },
    
    discover_modules = function() {
      module_dirs <- list.dirs("modules", recursive = FALSE)
      module_dirs <- module_dirs[!grepl("^_", basename(module_dirs))]
      
      for (dir in module_dirs) {
        manifest_path <- file.path(dir, "manifest.yml")
        if (!file.exists(manifest_path)) next
        
        manifest <- yaml::read_yaml(manifest_path)
        module_id <- manifest$module$id
        
        # Check enabled status (registry overrides manifest)
        enabled <- if (!is.null(self$registry$modules[[module_id]]$enabled)) {
          self$registry$modules[[module_id]]$enabled
        } else {
          manifest$module$enabled %||% TRUE
        }
        
        manifest$module$enabled <- enabled
        manifest$module$path <- dir
        
        self$modules[[module_id]] <- manifest
      }
      
      # Sort by priority
      self$modules <- self$modules[order(sapply(self$modules, function(m) {
        self$registry$modules[[m$module$id]]$priority %||% 99
      }))]
    },
    
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },
    
    load_packages = function() {
      enabled_modules <- self$get_enabled_modules()
      
      all_packages <- unique(unlist(lapply(enabled_modules, function(m) {
        m$module$dependencies$packages
      })))
      
      for (pkg in all_packages) {
        if (!pkg %in% self$loaded_packages) {
          if (!requireNamespace(pkg, quietly = TRUE)) {
            warning("Package not installed: ", pkg)
          } else {
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
            self$loaded_packages <- c(self$loaded_packages, pkg)
          }
        }
      }
      
      if (length(self$loaded_packages) > 0) {
        cat("✓ Loaded packages:", paste(self$loaded_packages, collapse = ", "), "\n")
      }
    },
    
    source_modules = function() {
      enabled_modules <- self$get_enabled_modules()
      
      for (module in enabled_modules) {
        ui_path <- file.path(module$module$path, "ui.R")
        server_path <- file.path(module$module$path, "server.R")
        
        if (file.exists(ui_path)) source(ui_path, local = .GlobalEnv)
        if (file.exists(server_path)) source(server_path, local = .GlobalEnv)
        
        cat("✓ Loaded module:", module$module$id, "\n")
      }
    },
    
    print = function() {
      cat("\n📦 Module Loader Status:\n")
      cat("   Total modules:", length(self$modules), "\n")
      
      enabled <- self$get_enabled_modules()
      cat("   Enabled:", length(enabled), "\n")
      
      if (length(enabled) > 0) {
        cat("\n   Enabled modules:\n")
        for (m in enabled) {
          cat("   ✓", m$module$name, "\n")
        }
      }
      
      disabled <- purrr::keep(self$modules, ~ !.x$module$enabled)
      if (length(disabled) > 0) {
        cat("\n   Disabled modules:\n")
        for (m in disabled) {
          cat("   ✗", m$module$name, "\n")
        }
      }
      cat("\n")
    }
  )
)
```

---

## Module Development Guide

### Module Structure

Each module consists of 4 files:

#### 1. manifest.yml - Module Metadata

```yaml
module:
  id: "your_module_name"              # Unique identifier (snake_case)
  name: "Your Module Name"             # Display name
  description: "What this module does"
  version: "1.0.0"
  enabled: true                        # Can be overridden in registry
  
  menu:
    label: "Menu Label"                # Sidebar menu text
    icon: "icon-name"                  # Font Awesome icon name
    tabname: "your_module_name"        # Must match module ID
  
  dependencies:
    packages:
      - shiny
      - dplyr
      # Add all required packages here
```

#### 2. ui.R - Module UI Function

```r
# modules/your_module_name/ui.R

your_module_name_ui <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    box(
      title = "Your Module Title",
      status = "primary",
      solidHeader = TRUE,
      width = 12,
      
      # Your UI elements here
      textInput(ns("input_field"), "Label:"),
      actionButton(ns("action_button"), "Do Something", class = "btn-primary"),
      
      br(), br(),
      uiOutput(ns("status_message"))
    ),
    
    box(
      title = "Results",
      status = "info",
      solidHeader = TRUE,
      width = 12,
      
      verbatimTextOutput(ns("results"))
    )
  )
}
```

#### 3. server.R - Module Server Function

```r
# modules/your_module_name/server.R

your_module_name_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    # Reactive values
    module_data <- reactiveVal(NULL)
    
    # Event handler
    observeEvent(input$action_button, {
      
      # Validation
      if (is.null(input$input_field) || input$input_field == "") {
        output$status_message <- renderUI({
          div(class = "status-error", 
              h5("❌ Error"), 
              p("Please provide input"))
        })
        return()
      }
      
      withProgress(message = 'Processing...', value = 0, {
        
        tryCatch({
          
          incProgress(0.3, detail = "Step 1")
          # Your processing logic
          
          incProgress(0.6, detail = "Step 2")
          # More processing
          
          incProgress(0.9, detail = "Finalizing")
          
          # Store results
          module_data(your_results)
          
          # Update shared state if needed
          if (!is.null(api_manager)) {
            api_manager$your_data_field <- your_results
          }
          
          output$status_message <- renderUI({
            div(class = "status-success",
                h5("✓ Success"),
                p("Operation completed"))
          })
          
          showNotification("Success!", type = "message", duration = 3)
          
        }, error = function(e) {
          output$status_message <- renderUI({
            div(class = "status-error",
                h5("✗ Failed"),
                p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type = "error", duration = 10)
        })
      })
    })
    
    # Outputs
    output$results <- renderText({
      if (is.null(module_data())) return("No data")
      # Format your results
      paste("Results:", module_data())
    })
  })
}
```

#### 4. README.md - Module Documentation

```markdown
# Your Module Name

## Description
What this module does and why it's useful.

## Dependencies
- Package 1: What it's used for
- Package 2: What it's used for

## Usage
1. Step 1
2. Step 2
3. Step 3

## Inputs
- `input_field`: Description

## Outputs
- Result 1: Description
- Result 2: Description

## Integration
This module integrates with:
- Other Module 1: How they interact
- API Manager: What data is shared

## Notes
Any special considerations or known issues.
```

### Module Registry Configuration

```yaml
# modules/_module_registry.yml

app:
  name: "Your Application Name"
  version: "1.0.0"
  description: "Application description"

modules:
  your_module_name:
    enabled: true
    priority: 10      # Lower = loads first
    
  another_module:
    enabled: true
    priority: 20
    
  disabled_module:
    enabled: false
    priority: 30
```

---

## Critical Dependencies

### Routing & Mapping Packages

```r
# CRITICAL: These must be loaded in this order in global.R

library(magrittr)     # Pipe operator (%>%)
library(dplyr)        # Data manipulation
library(sf)           # Spatial data structures
library(osmdata)      # OpenStreetMap data
library(tmaptools)    # Geocoding (provides getbb, geocode_OSM)
library(dodgr)        # Routing on directed graphs
library(leaflet)      # Interactive maps
library(htmltools)    # HTML generation
library(jsonlite)     # JSON parsing (for API fallbacks)
```

### Common Module Dependencies Template

```yaml
# For basic data modules
dependencies:
  packages:
    - shiny
    - dplyr
    - magrittr

# For GCP integration modules
dependencies:
  packages:
    - bigrquery
    - sf
    - dplyr
    - magrittr

# For mapping modules
dependencies:
  packages:
    - leaflet
    - sf
    - htmltools
    - dodgr

# For routing modules
dependencies:
  packages:
    - osmdata
    - dodgr
    - sf
    - dplyr
    - magrittr
    - tmaptools
    - jsonlite
```

---

## GCP Integration

### BigQuery Manager R6 Class

```r
# R/utils_bigquery.R

library(R6)
library(bigrquery)
library(sf)
library(dplyr)

BigQueryManager <- R6Class(
  "BigQueryManager",
  
  public = list(
    # Core fields - MUST be declared here
    bq_authenticated = FALSE,
    project_id = NULL,
    dataset_id = NULL,
    table_id = NULL,
    charging_points = NULL,
    
    # Module data fields - add as needed
    network_data = NULL,      # For road network module
    route_info = NULL,        # For route optimizer module
    
    state_trigger = NULL,     # Reactive trigger
    
    # Constructor
    initialize = function() {
      self$state_trigger <- reactiveVal(0)
      cat("BigQueryManager initialized\n")
    },
    
    # Authenticate with service account key
    authenticate = function(json_key_path, project_id, dataset_id, table_id) {
      tryCatch({
        # Set authentication
        bq_auth(path = json_key_path)
        
        # Test connection
        sql <- sprintf("SELECT * FROM `%s.%s.%s` LIMIT 10",
                       project_id, dataset_id, table_id)
        
        test_query <- bq_project_query(project_id, sql)
        test_data <- bq_table_download(test_query)
        
        self$bq_authenticated <- TRUE
        self$project_id <- project_id
        self$dataset_id <- dataset_id
        self$table_id <- table_id
        
        # Load full data
        result <- self$load_data()
        
        # Trigger state update
        self$trigger_state_update()
        
        list(success = TRUE, message = result$message)
        
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        list(success = FALSE, message = as.character(e$message))
      })
    },
    
    # Load data from BigQuery
    load_data = function() {
      if (!self$bq_authenticated) {
        stop("Not authenticated with BigQuery")
      }
      
      tryCatch({
        sql <- sprintf("SELECT * FROM `%s.%s.%s`",
                       self$project_id,
                       self$dataset_id,
                       self$table_id)
        
        query <- bq_project_query(self$project_id, sql)
        df_data <- bq_table_download(query)
        
        # Clean and validate data
        df_data <- df_data %>%
          filter(!is.na(latitude) & !is.na(longitude)) %>%
          mutate(
            latitude = as.numeric(latitude),
            longitude = as.numeric(longitude)
          )
        
        # Convert to sf object
        self$charging_points <- st_as_sf(
          df_data,
          coords = c("longitude", "latitude"),
          crs = 4326
        )
        
        list(
          success = TRUE,
          count = nrow(self$charging_points),
          message = paste("Loaded", nrow(self$charging_points), "points")
        )
        
      }, error = function(e) {
        list(success = FALSE, message = as.character(e$message))
      })
    },
    
    # Get data
    get_charging_points = function() {
      self$charging_points
    },
    
    # Clear authentication
    clear_auth = function() {
      self$bq_authenticated <- FALSE
      self$project_id <- NULL
      self$dataset_id <- NULL
      self$table_id <- NULL
      self$charging_points <- NULL
      
      self$trigger_state_update()
      
      list(success = TRUE, message = "Authentication cleared")
    },
    
    # Get connection status
    get_status = function() {
      list(
        authenticated = self$bq_authenticated,
        project_id = self$project_id,
        dataset_id = self$dataset_id,
        table_id = self$table_id,
        data_count = if (!is.null(self$charging_points)) nrow(self$charging_points) else 0
      )
    },
    
    # Trigger state update (for reactive cross-module updates)
    trigger_state_update = function() {
      if (!is.null(self$state_trigger)) {
        current <- isolate(self$state_trigger())
        self$state_trigger(current + 1)
      }
    }
  )
)
```

### GCP Connection Module Example

```r
# modules/bigquery_connection/server.R

bigquery_connection_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$testConnection, {
      
      if (is.null(input$jsonKey)) {
        output$connectionStatus <- renderUI({
          div(class = "status-error", 
              h5("Authentication Failed"), 
              p("Please upload a JSON key file."))
        })
        return()
      }
      
      tryCatch({
        result <- api_manager$authenticate(
          json_key_path = input$jsonKey$datapath,
          project_id = input$projectId,
          dataset_id = input$datasetId,
          table_id = input$tableId
        )
        
        if (result$success) {
          output$connectionStatus <- renderUI({
            div(class = "status-success",
                h5("✓ Connection Successful"),
                p(result$message))
          })
          showNotification("BigQuery connected!", type = "message")
        } else {
          output$connectionStatus <- renderUI({
            div(class = "status-error",
                h5("✗ Connection Failed"),
                p(result$message))
          })
        }
        
      }, error = function(e) {
        output$connectionStatus <- renderUI({
          div(class = "status-error",
              h5("✗ Connection Failed"),
              p(e$message))
        })
      })
    })
  })
}
```

---

## Routing & Mapping

### Geocoding - Robust Implementation

```r
# CRITICAL: Always use fallback geocoding to handle missing polygons

geocode_address <- function(address) {
  tryCatch({
    # Try tmaptools first
    tmaptools::geocode_OSM(address, as.sf = TRUE, return.first.only = TRUE)
  }, error = function(e) {
    # Fallback: Direct Nominatim API
    query_url <- paste0("https://nominatim.openstreetmap.org/search?q=",
                       URLencode(address),
                       "&format=json&limit=1")
    result <- jsonlite::fromJSON(query_url)
    if (length(result) == 0) return(NULL)
    
    st_sf(geometry = st_sfc(
      st_point(c(as.numeric(result$lon[1]), as.numeric(result$lat[1]))), 
      crs = 4326
    ))
  })
}
```

### Road Network Download

```r
# Download and process OpenStreetMap road network

download_road_network <- function(place_name) {
  
  # Get bounding box
  bbox <- tmaptools::getbb(place_name)
  if (is.null(bbox)) stop("Location not found")
  
  # Download road data
  highway_query <- osmdata::opq(bbox, timeout = 60) %>%
    osmdata::add_osm_feature(
      key = "highway", 
      value = c("motorway", "trunk", "primary", "secondary", 
                "tertiary", "residential", "unclassified", "service")
    ) %>%
    osmdata::osmdata_sf()
  
  if (is.null(highway_query$osm_lines)) stop("No road data found")
  
  # Clean geometries - CRITICAL: Keep only LINESTRING
  edges <- highway_query$osm_lines
  edges <- edges[st_geometry_type(edges$geometry) == "LINESTRING", ]
  if (nrow(edges) == 0) stop("No valid road linestrings")
  
  # Ensure WGS84 projection
  edges <- st_transform(edges, 4326)
  
  # Create routing graph
  graph <- tryCatch({
    dodgr::weight_streetnet(
      edges, 
      wt_profile = "motorcar",
      type_col = "highway",
      id_col = "osm_id"
    )
  }, error = function(e) {
    # Fallback: Manual graph creation
    create_simple_graph(edges)
  })
  
  list(
    graph = graph,
    edges = edges,
    nodes = highway_query$osm_points,
    bbox = bbox
  )
}

# Fallback graph creation
create_simple_graph <- function(edges) {
  edge_list <- data.frame()
  
  for (i in 1:min(nrow(edges), 500)) {
    coords <- st_coordinates(edges[i,])
    if (nrow(coords) < 2) next
    
    for (j in 1:(nrow(coords)-1)) {
      edge_list <- rbind(edge_list, data.frame(
        from_lon = coords[j, "X"],
        from_lat = coords[j, "Y"],
        to_lon = coords[j+1, "X"],
        to_lat = coords[j+1, "Y"],
        d = sqrt((coords[j+1, "X"] - coords[j, "X"])^2 + 
                 (coords[j+1, "Y"] - coords[j, "Y"])^2) * 111320
      ))
    }
  }
  
  edge_list$d_weighted <- edge_list$d
  return(edge_list)
}
```

### Route Calculation

```r
# Calculate optimal route through waypoints

calculate_route <- function(start_coords, end_coords, waypoints, graph) {
  
  shortest_length <- Inf
  best_waypoint <- NULL
  
  for (i in 1:nrow(waypoints)) {
    waypoint_coords <- st_coordinates(st_geometry(waypoints[i,]))
    
    # Distance to waypoint
    dist_to <- tryCatch({
      dodgr::dodgr_dists(
        graph, 
        from = start_coords, 
        to = waypoint_coords
      )[1]
    }, error = function(e) Inf)
    
    # Distance from waypoint
    dist_from <- tryCatch({
      dodgr::dodgr_dists(
        graph, 
        from = waypoint_coords, 
        to = end_coords
      )[1]
    }, error = function(e) Inf)
    
    total <- dist_to + dist_from
    
    if (!is.na(total) && !is.infinite(total) && total < shortest_length) {
      shortest_length <- total
      best_waypoint <- i
    }
  }
  
  if (is.null(best_waypoint)) stop("No valid route found")
  
  list(
    total_distance = shortest_length,
    best_waypoint_index = best_waypoint
  )
}
```

### Route Visualization on Map

```r
# Draw actual road-based route on Leaflet map

draw_route_on_map <- function(map, start_coords, end_coords, waypoint_coords, graph) {
  
  # Use dodgr_flows_aggregate to get actual route geometry
  
  # Segment 1: Start to waypoint
  flows_1 <- data.frame(
    from_x = start_coords[1],
    from_y = start_coords[2],
    to_x = waypoint_coords[1],
    to_y = waypoint_coords[2],
    flow = 1
  )
  
  graph_flow_1 <- dodgr::dodgr_flows_aggregate(
    graph = graph,
    from = flows_1[, c("from_x", "from_y")],
    to = flows_1[, c("to_x", "to_y")],
    flows = flows_1$flow
  )
  
  route_edges_1 <- graph_flow_1[graph_flow_1$flow > 0, ]
  
  # Draw first segment
  if (nrow(route_edges_1) > 0) {
    for (i in 1:nrow(route_edges_1)) {
      edge <- route_edges_1[i, ]
      map <- map %>%
        addPolylines(
          lng = c(edge$from_lon, edge$to_lon),
          lat = c(edge$from_lat, edge$to_lat),
          color = "#3498db",
          weight = 6,
          opacity = 0.9
        )
    }
  }
  
  # Segment 2: Waypoint to end
  flows_2 <- data.frame(
    from_x = waypoint_coords[1],
    from_y = waypoint_coords[2],
    to_x = end_coords[1],
    to_y = end_coords[2],
    flow = 1
  )
  
  graph_flow_2 <- dodgr::dodgr_flows_aggregate(
    graph = graph,
    from = flows_2[, c("from_x", "from_y")],
    to = flows_2[, c("to_x", "to_y")],
    flows = flows_2$flow
  )
  
  route_edges_2 <- graph_flow_2[graph_flow_2$flow > 0, ]
  
  # Draw second segment
  if (nrow(route_edges_2) > 0) {
    for (i in 1:nrow(route_edges_2)) {
      edge <- route_edges_2[i, ]
      map <- map %>%
        addPolylines(
          lng = c(edge$from_lon, edge$to_lon),
          lat = c(edge$from_lat, edge$to_lat),
          color = "#2980b9",
          weight = 6,
          opacity = 0.9
        )
    }
  }
  
  return(map)
}
```

---

## Common Pitfalls & Solutions

### 1. "Cannot add bindings to a locked environment"

**Problem**: Trying to assign new fields to R6 objects dynamically

**Solution**: Declare ALL fields in the R6 class definition

```r
# ❌ WRONG
api_manager$new_field <- data  # This fails!

# ✅ CORRECT
BigQueryManager <- R6Class(
  "BigQueryManager",
  public = list(
    existing_field = NULL,
    new_field = NULL,      # Declare it here!
    # ... rest of class
  )
)
```

### 2. "No polygonal boundary for location"

**Problem**: `getbb()` with `format_out = "sf_polygon"` fails for some locations

**Solution**: Use point-based geocoding with fallback

```r
# ❌ WRONG
coords <- getbb(address, format_out = "sf_polygon")

# ✅ CORRECT
coords <- geocode_address(address)  # Use fallback function from above
```

### 3. Pipe operator not working

**Problem**: `%>%` not recognized

**Solution**: Load `magrittr` BEFORE other packages in global.R

```r
# ✅ CORRECT ORDER
library(magrittr)  # FIRST!
library(dplyr)
library(osmdata)
```

### 4. Invalid geometries in road network

**Problem**: Mixed geometry types cause routing to fail

**Solution**: Filter to LINESTRING only

```r
# ✅ CORRECT
edges <- edges[st_geometry_type(edges$geometry) == "LINESTRING", ]
```

### 5. Module dependencies not loading

**Problem**: Package not available when module loads

**Solution**: 
- Add to module's `manifest.yml`
- Also add to `global.R` for critical packages

```yaml
# manifest.yml
dependencies:
  packages:
    - your_package
```

### 6. Modules not communicating

**Problem**: Data not shared between modules

**Solution**: Use the shared `api_manager` R6 object

```r
# In module 1: Store data
api_manager$shared_data <- my_data

# In module 2: Access data
data <- api_manager$shared_data
```

### 7. Route drawing fails with "invalid subscript type 'list'"

**Problem**: Using `dodgr_paths()` incorrectly

**Solution**: Use `dodgr_flows_aggregate()` instead

```r
# ❌ WRONG
path <- dodgr_paths(graph, from, to)
edges <- graph[path[[1]], ]  # Fails!

# ✅ CORRECT
flows <- dodgr_flows_aggregate(graph, from, to, flows = 1)
route_edges <- flows[flows$flow > 0, ]
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All module manifests have correct dependencies
- [ ] All required packages listed in global.R
- [ ] R6 class has all needed fields declared
- [ ] Module registry configured correctly
- [ ] CSS file exists in www/css/global.css
- [ ] All source() paths are relative
- [ ] No hardcoded file paths
- [ ] Environment variables for sensitive data (not hardcoded)

### Testing

- [ ] Test each module independently
- [ ] Test module communication (shared state)
- [ ] Test error handling (wrong inputs)
- [ ] Test with missing data
- [ ] Test network failures (GCP, OSM)
- [ ] Test cleanup function

### GCP Specific

- [ ] Service account has correct permissions
- [ ] BigQuery table schema matches code
- [ ] Connection timeout handling
- [ ] Authentication error handling
- [ ] Data validation after loading

### Routing Specific

- [ ] Test with different locations
- [ ] Test geocoding fallback
- [ ] Test with no route available
- [ ] Test with disconnected graph
- [ ] Verify routes follow actual roads

### Performance

- [ ] Progress indicators for long operations
- [ ] Proper use of withProgress()
- [ ] Efficient data structures
- [ ] Cleanup on session end
- [ ] No memory leaks

---

## Quick Start Template

```bash
# Create new modular app structure
mkdir my-app
cd my-app

# Create directories
mkdir -p R modules www/css

# Create files
touch app.R global.R
touch R/module_loader.R R/utils_common.R R/utils_bigquery.R
touch modules/_module_registry.yml
touch www/css/global.css

# Create first module
mkdir -p modules/my_module
touch modules/my_module/manifest.yml
touch modules/my_module/ui.R
touch modules/my_module/server.R
touch modules/my_module/README.md
```

Then populate files with templates from this guide!

---

## Summary of Critical Patterns

1. **Always declare R6 fields upfront** - Never assign dynamically
2. **Load packages in correct order** - magrittr first, then others
3. **Use robust geocoding** - Always have fallback to Nominatim
4. **Filter geometries** - Keep only LINESTRING for routing
5. **Use dodgr_flows_aggregate** - Not dodgr_paths for route visualization
6. **Share state via R6** - Use api_manager for inter-module communication
7. **Handle errors gracefully** - tryCatch with user-friendly messages
8. **Progress indicators** - Use withProgress for long operations
9. **Clean up resources** - Implement session cleanup function
10. **Module isolation** - Each module should be independently testable

---

## Additional Resources

- [Shiny Modules Documentation](https://shiny.rstudio.com/articles/modules.html)
- [R6 Documentation](https://r6.r-lib.org/)
- [dodgr Package](https://github.com/ATFutures/dodgr)
- [osmdata Package](https://docs.ropensci.org/osmdata/)
- [bigrquery Documentation](https://bigrquery.r-dbi.org/)
- [Leaflet for R](https://rstudio.github.io/leaflet/)

---

**End of Template - Happy Coding! 🚀**
