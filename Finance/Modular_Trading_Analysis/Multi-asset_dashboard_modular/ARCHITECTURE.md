# Multi-Asset Analysis Dashboard - Architecture Documentation

## Overview

This dashboard follows a **modern modular architecture** where each analysis feature is a self-contained, independently manageable module. This design ensures:

- ✅ **Zero namespace conflicts** - Proper use of `NS()` and `moduleServer()`
- ✅ **Clean separation** - Each feature is independent
- ✅ **Easy maintenance** - Modify one module without affecting others
- ✅ **Flexible deployment** - Enable only what you need
- ✅ **Scalability** - Add new features as modules

## Core Architecture Components

### 1. Entry Point (`app.R`)

**Minimal design** - Only loads configuration and runs the app:

```r
source("global.R")
module_loader <- ModuleLoader$new()
module_loader$load_packages()
module_loader$source_modules()

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    create_server(module_loader, data_manager, session)
  }
)
```

### 2. Global Configuration (`global.R`)

Handles:
- Core package loading
- Utility sourcing
- Data manager initialization
- UI factory function (`create_ui`)
- Server factory function (`create_server`)
- Global asset selection observers

### 3. Module Loader (`R/module_loader.R`)

**R6 class** that manages all modules:

```r
ModuleLoader <- R6::R6Class(
  "ModuleLoader",
  public = list(
    initialize = function() { ... },
    load_registry = function() { ... },
    discover_modules = function() { ... },
    get_enabled_modules = function() { ... },  # ⭐ CRITICAL
    load_packages = function() { ... },
    source_modules = function() { ... }
  )
)
```

**Key principle:** Every method that processes modules MUST call `self$get_enabled_modules()` first.

### 4. Data Manager (`R/utils_data.R`)

**R6 class** with **reactive triggers** for cross-module communication:

```r
DataManager <- R6::R6Class(
  "DataManager",
  public = list(
    # State
    current_asset = NULL,
    asset_data = NULL,
    data_loaded = FALSE,
    
    # ⭐ CRITICAL: Reactive trigger
    state_trigger = NULL,
    
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
    },
    
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)  # ⭐ FIRES ALL WATCHERS
    },
    
    # Data methods
    fetch_data = function(...) { ... },
    get_data = function() { ... },
    get_summary = function() { ... }
  )
)
```

## Module Structure

Each module follows this **exact structure**:

```
modules/my_module/
├── manifest.yml           # Metadata and dependencies
├── ui.R                   # Namespaced UI function
├── server.R               # moduleServer function
└── README.md              # Documentation
```

### manifest.yml

```yaml
module:
  id: "market_overview"              # lowercase_with_underscores
  name: "Market Overview"             # Display name
  description: "Real-time market data"
  version: "1.0.0"
  author: "Asset Dashboard Team"
  
  enabled: true                       # Can be overridden by registry
  
  menu:
    label: "Market Overview"          # Sidebar text
    icon: "chart-line"                # FontAwesome icon
    tabname: "market_overview"        # Must match ID
  
  dependencies:
    packages:
      - shiny
      - plotly
      - DT
  
  data:
    required: ["asset_data"]
```

### ui.R

```r
# ⭐ CRITICAL: Function name must be {module_id}_ui

market_overview_ui <- function(id) {
  # ⭐ CRITICAL: Create namespace function
  ns <- NS(id)
  
  # ⭐ CRITICAL: ALL IDs must be wrapped with ns()
  tagList(
    fluidRow(
      box(
        title = "Market Overview",
        valueBoxOutput(ns("currentPrice")),     # ← ns() wrapper
        plotlyOutput(ns("priceChart"))          # ← ns() wrapper
      )
    )
  )
}
```

### server.R

```r
# ⭐ CRITICAL: Function name must be {module_id}_server

market_overview_server <- function(id, data_manager) {
  # ⭐ CRITICAL: Use moduleServer for namespacing
  moduleServer(id, function(input, output, session) {
    
    # ⭐ Watch for data changes
    observe({
      data_manager$state_trigger()  # Makes observer reactive
      
      data <- data_manager$get_data()
      if (is.null(data)) return()
      
      # React to data changes
      update_charts(data)
    })
    
    # Outputs don't need ns() in server
    output$currentPrice <- renderValueBox({
      # Output code
    })
    
    session$onSessionEnded(function() {})
  })
}
```

## Module Registry

The **CONTROL CENTER** - change ONE line to enable/disable:

```yaml
# modules/_module_registry.yml

modules:
  market_overview:
    enabled: false  # ← CHANGE ONLY THIS LINE
    priority: 1     # Load order (lower = earlier)
    description: "Market overview module"
```

**When `enabled: false`:**
- Files NOT sourced (ui.R, server.R not loaded)
- Packages NOT loaded
- NOT in sidebar menu
- NOT in dashboard tabs
- Server function NOT called
- ZERO performance overhead

## Reactive State Sharing Pattern

**⚠️ CRITICAL:** Regular R6 fields are NOT reactive!

### ❌ WRONG (Does not work):

```r
# In DataManager
public = list(
  data_loaded = FALSE
)

# In module
observe({
  if (data_manager$data_loaded) {  # ← NOT REACTIVE
    load_charts()
  }
})
```

### ✅ CORRECT (Works):

```r
# In DataManager
public = list(
  data_loaded = FALSE,
  state_trigger = NULL,  # ← Reactive trigger
  
  initialize = function() {
    self$state_trigger <- shiny::reactiveVal(0)
  },
  
  fetch_data = function(...) {
    # ... fetch logic ...
    self$data_loaded <- TRUE
    self$trigger_state_update()  # ← TRIGGER ALL MODULES
  },
  
  trigger_state_update = function() {
    current <- self$state_trigger()
    self$state_trigger(current + 1)
  }
)

# In module
observe({
  data_manager$state_trigger()  # ← WATCH THIS
  
  if (data_manager$data_loaded) {  # Now this works!
    load_charts()
  }
})
```

## Global Asset Selection

Asset selection is handled globally in `global.R`:

```r
# In create_server function
observe({
  asset_class <- input$global_asset_class
  current_asset <- if (asset_class == "crypto") {
    input$global_crypto_asset
  } else if (asset_class == "equity") {
    input$global_equity_asset
  } else {
    input$global_commodity_asset
  }
  
  if (!is.null(current_asset) && current_asset != "") {
    data_manager$set_current_asset(current_asset, asset_class)
  }
})
```

This propagates to all modules through the reactive trigger.

## Data Fetching Pattern

### Fetch on Asset Change

```r
# In DataManager
set_current_asset = function(asset, asset_class) {
  if (!identical(self$current_asset, asset)) {
    self$current_asset <- asset
    self$current_asset_class <- asset_class
    self$fetch_data()
  }
}

fetch_data = function(months_back = 24) {
  data <- getSymbols(self$current_asset, 
                    src = "yahoo", 
                    from = start_date, 
                    to = end_date, 
                    auto.assign = FALSE)
  
  # Convert and process
  self$asset_data <- process_data(data)
  self$data_loaded <- TRUE
  
  # Notify all modules
  self$trigger_state_update()
}
```

### Use in Modules

```r
observe({
  data_manager$state_trigger()
  
  data <- data_manager$get_data()
  
  if (is.null(data)) {
    # Show "no data" message
    return()
  }
  
  # Use data for analysis
  output$chart <- renderPlotly({
    plot_ly(data, x = ~Date, y = ~Close)
  })
})
```

## CSS Architecture

**ALL styling** is centralized in `www/css/global.css`:

- ✅ NO inline CSS in any R files
- ✅ Corporate teal/cyan theme
- ✅ Modern gradients and shadows
- ✅ Hover effects
- ✅ Status boxes (success, error, info, warning)
- ✅ Value boxes with color coding
- ✅ Responsive design

Key color scheme:
- Primary: `#008A82` (teal)
- Secondary: `#00A39A` (cyan)
- Background: Gradient `#002C3C` → `#008A82` → `#00A39A`

## Error Handling Pattern

```r
# Standardized error handling
tryCatch({
  result <- data_manager$fetch_data()
  
  showNotification("✓ Data loaded successfully!", type = "message")
  
  output$status <- renderUI({
    tags$div(class = "status-success", "✓ Success!")
  })
  
}, error = function(e) {
  showNotification(paste("Error:", e$message), type = "error")
  
  output$status <- renderUI({
    tags$div(class = "status-error", "Error: ", e$message)
  })
})
```

## Adding a New Module - Step by Step

### 1. Create Directory

```bash
mkdir -p modules/new_module
```

### 2. Create manifest.yml

See any existing module for template.

### 3. Create ui.R

```r
new_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "New Module",
        plotlyOutput(ns("chart"))
      )
    )
  )
}
```

### 4. Create server.R

```r
new_module_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      data_manager$state_trigger()
      # Module logic
    })
    
    session$onSessionEnded(function() {})
  })
}
```

### 5. Register in `_module_registry.yml`

```yaml
modules:
  new_module:
    enabled: true
    priority: 10
    description: "New analysis module"
```

### 6. Test

```r
shiny::runApp()
```

## Validation Checklist

- [ ] app.R under 50 lines
- [ ] All CSS in www/css/global.css
- [ ] Zero inline CSS in R files
- [ ] All modules in separate folders
- [ ] Each module has manifest.yml, ui.R, server.R, README.md
- [ ] All UI IDs wrapped with ns()
- [ ] All server logic uses moduleServer()
- [ ] Module registry controls enable/disable
- [ ] No library() calls in module files
- [ ] All dependencies in manifest.yml
- [ ] ModuleLoader uses R6 class
- [ ] DataManager uses R6 class
- [ ] get_enabled_modules() used everywhere
- [ ] state_trigger() for reactive updates

## Performance Considerations

- **Disabled modules** = zero overhead (not loaded at all)
- **Reactive triggers** = minimal performance impact
- **Data caching** = fetched once per asset change
- **Conditional rendering** = only active tab rendered

## Deployment Best Practices

### Package Requirements

Ensure all required packages are installed:
```r
install.packages(c(
  "shiny", "shinydashboard", "plotly", "DT", 
  "dplyr", "lubridate", "quantmod", "TTR", 
  "tidyr", "zoo", "corrplot", "shinycssloaders",
  "R6", "yaml", "purrr"
))
```

### Production Settings

In `modules/_module_registry.yml`:
```yaml
settings:
  verbose: false        # Disable loading messages
  dev_mode: false       # Production mode
```

### Module Selection

Enable only needed modules for faster startup:
```yaml
modules:
  market_overview:
    enabled: true
  advanced_metrics:
    enabled: false  # Disable if not needed
```

---

**This architecture ensures production-ready, maintainable, and scalable financial analysis applications.**
