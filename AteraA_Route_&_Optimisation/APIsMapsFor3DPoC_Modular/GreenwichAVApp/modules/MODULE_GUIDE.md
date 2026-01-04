# 📦 MODULE SYSTEM DOCUMENTATION
## Greenwich AV Data Extractor

This document explains how to create, modify, and manage modules in this application.

---

## Module Architecture

Each module is a self-contained unit with:
- **UI Component** (`ui.R`) - User interface
- **Server Logic** (`server.R`) - Backend processing
- **Manifest** (`manifest.yml`) - Metadata & configuration
- **Optional:** README.md for documentation

---

## Creating a New Module

### Step 1: Create Module Directory

```bash
mkdir -p modules/my_new_module
```

### Step 2: Create manifest.yml

```yaml
module:
  id: "my_new_module"
  name: "My New Module"
  description: "What this module does"
  version: "1.0.0"
  enabled: true
  menu:
    label: "Display Name"
    icon: "map-marker"  # Font Awesome icon
    tabname: "my_new_module"
  dependencies:
    packages:
      - package1
      - package2
```

### Step 3: Create ui.R

```r
# modules/my_new_module/ui.R

my_new_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Module Title", 
        status = "primary", 
        solidHeader = TRUE, 
        width = 12,
        
        # Your UI elements here
        textInput(ns("input1"), "Label:"),
        actionButton(ns("button1"), "Click Me", class = "btn-success")
      )
    )
  )
}
```

**Important:** 
- Function name MUST be `{module_id}_ui`
- Use `ns <- NS(id)` for namespacing
- Wrap all input IDs with `ns()`

### Step 4: Create server.R

```r
# modules/my_new_module/server.R

my_new_module_server <- function(id, data_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    # Reactive values
    my_data <- reactiveVal(NULL)
    
    # Event handlers
    observeEvent(input$button1, {
      # Your logic here
      result <- process_data(input$input1)
      
      # Update data manager if needed
      if (!is.null(data_manager)) {
        data_manager$my_module_data <- result
      }
      
      # Show notification
      showNotification("Success!", type = "message")
    })
    
    # Outputs
    output$myOutput <- renderText({
      # Your output logic
    })
  })
}
```

**Important:**
- Function name MUST be `{module_id}_server`
- Use `moduleServer()` for proper namespacing
- Access data_manager to share data between modules

### Step 5: Register in _module_registry.yml

```yaml
modules:
  my_new_module:
    enabled: true
    priority: 70  # Higher number = loads later
    description: "Brief description"
```

### Step 6: Restart the App

```r
shiny::runApp()
```

Your module will appear in the sidebar!

---

## Module Communication

### Sharing Data Between Modules

Use the `data_manager` object:

```r
# In module A - store data
data_manager$my_data <- some_data

# In module B - read data
retrieved_data <- data_manager$my_data
```

### Available Data Manager Properties

- `bbox` - Current bounding box
- `location_name` - Selected location
- `osm_data` - OpenStreetMap data
- `arcgis_data` - ArcGIS data
- `terrain_data` - Terrain data
- `lidar_data` - LIDAR data
- `imagery_data` - Imagery data
- `export_ready` - Boolean flag

### Data Manager Methods

```r
# Update location
data_manager$update_bbox(new_bbox)
data_manager$update_location("New Location")

# Check export readiness
data_manager$check_export_ready()

# Get formatted bbox
bbox_string <- data_manager$get_bbox_string()
```

---

## UI Best Practices

### 1. Use Consistent Styling

```r
# Status messages
status_message("success", "✓ Title", "Message text")
status_message("error", "✗ Title", "Error text")
status_message("warning", "⚠ Title", "Warning text")
status_message("info", "ℹ Title", "Info text")
```

### 2. Value Boxes

```r
output$myValueBox <- renderValueBox({
  valueBox(
    value = "123",
    subtitle = "Items",
    icon = icon("database"),
    color = "blue"  # blue, green, red, yellow, aqua
  )
})
```

### 3. Progress Indicators

```r
withProgress(message = 'Processing...', value = 0, {
  incProgress(0.3, detail = "Step 1")
  # Do work
  incProgress(0.4, detail = "Step 2")
  # More work
  incProgress(0.3, detail = "Complete")
})
```

---

## Server Best Practices

### 1. Error Handling

```r
tryCatch({
  # Your code
  result <- risky_operation()
  
  # Success
  showNotification("Success!", type = "message")
  
}, error = function(e) {
  # Handle error
  showNotification(paste("Error:", e$message), 
                  type = "error", duration = 10)
})
```

### 2. Validation

```r
observeEvent(input$myButton, {
  # Validate inputs
  req(input$myInput)  # Ensure not NULL
  
  if (input$myInput == "") {
    showNotification("Input required", type = "warning")
    return()
  }
  
  # Proceed with logic
})
```

### 3. Conditional Outputs

```r
# In UI
conditionalPanel(
  condition = paste0("output['", ns("dataLoaded"), "']"),
  downloadButton(ns("download"), "Download")
)

# In Server
output$dataLoaded <- reactive({ 
  !is.null(my_data()) 
})
outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
```

---

## Module Manifest Reference

### Complete Example

```yaml
module:
  id: "example_module"           # Unique identifier (no spaces)
  name: "Example Module"         # Display name
  description: "Full description of what this module does"
  version: "1.0.0"              # Semantic versioning
  enabled: true                 # true/false
  author: "Your Name"           # Optional
  
  menu:
    label: "Example"            # Sidebar menu text
    icon: "chart-line"          # Font Awesome icon (without fa- prefix)
    tabname: "example_module"   # Must match module id
  
  dependencies:
    packages:                   # R packages required
      - dplyr
      - ggplot2
      - leaflet
    
    r_version: ">=4.0.0"       # Optional: minimum R version
    
  settings:                     # Optional: module-specific settings
    cache_enabled: true
    timeout: 60
```

---

## Font Awesome Icons

Common icons for modules:
- `map` - Map/geographic data
- `globe` - Global/world data
- `mountain` - Terrain/elevation
- `layer-group` - Multiple layers
- `satellite` - Satellite imagery
- `eye` - Preview/view
- `download` - Download
- `upload` - Upload
- `database` - Data storage
- `chart-line` - Analytics

Full list: https://fontawesome.com/icons

---

## Module Priority

Modules load in priority order (lower = earlier):

```yaml
modules:
  module_a:
    priority: 10   # Loads first
  module_b:
    priority: 20   # Loads second
  module_c:
    priority: 30   # Loads third
```

**Why it matters:**
- Modules that others depend on should load early
- UI tabs appear in priority order

---

## Disabling Modules

### Temporarily Disable

In `_module_registry.yml`:
```yaml
modules:
  my_module:
    enabled: false  # Module won't load
```

### Completely Remove

1. Set `enabled: false` in registry
2. Delete module folder (optional)
3. Restart app

---

## Testing Your Module

### 1. Test Locally

```r
# Run app
shiny::runApp()

# Check R console for errors
```

### 2. Test Module in Isolation

```r
# Create test script
library(shiny)

ui <- fluidPage(
  my_new_module_ui("test")
)

server <- function(input, output, session) {
  my_new_module_server("test", data_manager = NULL)
}

shinyApp(ui, server)
```

### 3. Check for Common Issues

- ✓ Module ID matches in all files
- ✓ UI function name: `{id}_ui`
- ✓ Server function name: `{id}_server`
- ✓ All inputs wrapped with `ns()`
- ✓ Module registered in `_module_registry.yml`

---

## Example Modules

Study these existing modules:
- **osm_data** - API calls, GeoJSON export
- **preview_validation** - Data aggregation, map display
- **satellite_imagery** - External APIs, configuration

---

## Advanced: Module Hooks

### Initialization Hook

```r
# In server.R
.onModuleLoad <- function(data_manager) {
  # Runs when module loads
  message("Module initialized")
}
```

### Cleanup Hook

```r
# In server.R
.onModuleUnload <- function() {
  # Cleanup when session ends
  message("Module cleanup")
}
```

---

## Troubleshooting

### Module Not Appearing

1. Check `enabled: true` in registry
2. Verify manifest.yml syntax (use YAML validator)
3. Check R console for errors
4. Ensure module ID is unique

### UI Not Displaying

1. Check function name: `{module_id}_ui`
2. Verify `NS(id)` is used
3. Check for syntax errors in ui.R

### Server Not Working

1. Check function name: `{module_id}_server`
2. Verify `moduleServer()` is used
3. Check all reactive expressions are valid

### Data Not Shared

1. Verify data_manager is passed to server function
2. Check data_manager property names
3. Ensure data is stored correctly

---

## Best Practices Summary

✅ **DO:**
- Use semantic versioning
- Document your module (README.md)
- Handle errors gracefully
- Validate user inputs
- Use consistent styling
- Share data via data_manager
- Test thoroughly

❌ **DON'T:**
- Use spaces in module IDs
- Hardcode paths or URLs
- Ignore error handling
- Create global variables
- Modify other modules directly

---

## Getting Help

- Check existing modules for examples
- Review main README.md
- Test in isolation first
- Check R console for errors
- Use browser() for debugging

---

**Happy Module Building! 🎉**
