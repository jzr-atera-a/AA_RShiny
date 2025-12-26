# Architecture Documentation

## System Overview

The Business Canvas Manager is built on a modular architecture that prioritizes:
- **Scalability**: Easy to add new features
- **Maintainability**: Clear separation of concerns
- **Testability**: Independent module testing
- **Performance**: Conditional loading reduces overhead

## Core Components

### 1. Entry Point (`app.R`)

**Purpose**: Minimal bootstrap file  
**Size**: 15-20 lines  
**Responsibilities**:
- Source global configuration
- Initialize ModuleLoader
- Create and run Shiny app

```r
source("global.R")
module_loader <- ModuleLoader$new()
module_loader$load_packages()
module_loader$source_modules()
shinyApp(ui = create_ui(module_loader), server = create_server(...))
```

### 2. Global Configuration (`global.R`)

**Purpose**: Central configuration hub  
**Responsibilities**:
- Load core packages
- Source utilities
- Initialize APIManager
- Define UI/Server factories

**Key Functions**:
- `create_ui(module_loader)`: Generates dynamic UI
- `create_server(module_loader, api_manager)`: Initializes module servers

### 3. Module Loader (`R/module_loader.R`)

**Design Pattern**: R6 Class  
**Purpose**: Dynamic module management

**Key Methods**:
```r
ModuleLoader$new()              # Initialize, discover modules
$load_registry()                # Read _module_registry.yml
$discover_modules()             # Scan modules/ directory
$get_enabled_modules()          # Filter by enabled status
$load_packages()                # Conditional package loading
$source_modules()               # Source ui.R and server.R
$generate_menu_items()          # Create sidebar menu
$generate_tab_items()           # Create tab content
```

**Critical Feature**: Every method that processes modules FIRST calls `$get_enabled_modules()` to ensure disabled modules are completely ignored.

### 4. API Manager (`R/utils_api.R`)

**Design Pattern**: R6 Class  
**Purpose**: Centralized API management

**Claude API Methods**:
```r
$test_claude_connection(api_key)
$set_claude_credentials(api_key, model)
$call_claude(prompt, max_tokens)
$clear_claude_credentials()
```

**BigQuery Methods**:
```r
$test_bigquery_connection(project_id)
$set_bigquery_credentials_file(json_path, ...)
$set_bigquery_credentials_text(json_text, ...)
$query_bigquery(query)
$clear_bigquery_credentials()
```

**State Management**:
- `claude_connected`: Boolean connection status
- `bq_authenticated`: Boolean auth status
- Credentials stored in object properties
- Cleanup on destruction

### 5. Utilities

**`utils_common.R`**:
- Helper functions
- Text formatting
- Status HTML generation
- Section parsing

**`utils_bigquery.R`**:
- Table schemas (centralized)
- Create table functions
- Query builders
- Dropdown cascade logic

## Module Architecture

### Module Structure

Each module follows this pattern:

```
modules/module_name/
├── manifest.yml    # Metadata, dependencies
├── ui.R           # UI function (namespaced)
├── server.R       # Server logic (moduleServer)
├── utils.R        # Module-specific helpers (optional)
├── data/          # Module data files (optional)
└── README.md      # Documentation
```

### Module Manifest (`manifest.yml`)

```yaml
module:
  id: "module_name"
  name: "Display Name"
  description: "What it does"
  enabled: true              # Can be overridden by registry
  
  menu:
    label: "Menu Label"
    icon: "icon-name"
    tabname: "module_name"
  
  dependencies:
    packages:
      - required_package_1
      - required_package_2
```

### Module UI Function

**Pattern**:
```r
module_name_ui <- function(id) {
  ns <- NS(id)  # CRITICAL: Create namespace function
  
  tagList(
    fluidRow(
      box(
        title = "Module Title",
        # ALL IDs wrapped with ns()
        textInput(ns("input_id"), "Label"),
        actionButton(ns("button_id"), "Action"),
        plotOutput(ns("plot_id"))
      )
    )
  )
}
```

**Rules**:
- Function name: `{module_id}_ui`
- First line: `ns <- NS(id)`
- ALL input/output IDs: `ns("id_name")`
- Return: `tagList(...)`

### Module Server Function

**Pattern**:
```r
module_name_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive values
    data <- reactiveVal(NULL)
    
    # Observers
    observeEvent(input$button_id, {
      # Button logic
    })
    
    # Outputs - access inputs directly (no ns())
    output$plot_id <- renderPlot({
      req(input$input_id)
      plot(data())
    })
    
    # Cleanup
    session$onSessionEnded(function() {
      # Cleanup code
    })
  })
}
```

**Rules**:
- Function name: `{module_id}_server`
- Signature: `(id, api_manager, session)`
- Wrapper: `moduleServer(id, function(input, output, session) { })`
- Inside moduleServer: Access inputs/outputs directly (no `ns()`)

## Data Flow

### 1. App Startup

```
app.R
  ↓
source global.R
  ↓
Load core packages
  ↓
Source utilities (module_loader, utils_*)
  ↓
Initialize APIManager
  ↓
Create ModuleLoader
  ↓
ModuleLoader discovers modules
  ↓
ModuleLoader loads packages (conditional)
  ↓
ModuleLoader sources enabled modules
  ↓
create_ui() generates interface
  ↓
create_server() initializes modules
  ↓
shinyApp() runs
```

### 2. Module Enable/Disable

```
User edits _module_registry.yml
  ↓
Sets enabled: false
  ↓
Restart app
  ↓
ModuleLoader reads registry
  ↓
get_enabled_modules() filters out disabled
  ↓
Disabled module:
  - NOT sourced
  - Packages NOT loaded
  - NOT in menu
  - NOT in tabs
  - Zero overhead
```

### 3. API Call Flow

```
User action in module
  ↓
Module server calls api_manager method
  ↓
APIManager checks authentication
  ↓
Makes API request
  ↓
Returns result to module
  ↓
Module updates UI
```

## CSS Architecture

### Centralization

**ALL styling in `www/css/global.css`**

- No inline CSS in any R file
- Corporate teal/cyan theme
- Consistent across modules
- Easy to maintain/update

### Theme Structure

```css
/* Main backgrounds - teal gradient */
.content-wrapper, .right-side { ... }

/* Sidebar - teal gradient */
.sidebar, .main-sidebar { ... }

/* Boxes - white with shadows */
.box { ... }

/* Status messages - color-coded */
.status-success { ... }
.status-error { ... }
.status-warning { ... }
.status-info { ... }

/* Buttons - gradient effects */
.btn-primary { ... }
.btn-success { ... }

/* Canvas-specific */
.canvas-grid { ... }
.de-canvas-grid { ... }
.de-roadmap-grid { ... }
```

## State Management

### Module-Level State

Each module manages its own state using reactive values:

```r
moduleServer(id, function(input, output, session) {
  # Module-specific reactive values
  local_data <- reactiveVal(NULL)
  parsed_content <- reactiveVal(NULL)
  
  # Module state isolated from others
})
```

### Global State

**APIManager** holds global state:
- API connections
- Authentication status
- Credentials

**Passed to modules** via `api_manager` parameter.

## Error Handling

### Module Isolation

If one module fails:
- Other modules continue working
- Error displayed in failing module only
- App remains stable

### API Error Handling

```r
tryCatch({
  result <- api_manager$call_claude(prompt)
  # Success handling
}, error = function(e) {
  # Error handling
  output$status <- renderUI({
    create_status_html("error", e$message)
  })
})
```

## Performance Optimization

### Conditional Package Loading

Only load packages for enabled modules:

```r
# If module disabled, its packages are NEVER loaded
# Reduces startup time
# Reduces memory footprint
```

### Lazy Module Sourcing

Modules sourced only if enabled:

```r
for (module in get_enabled_modules()) {
  source(module$ui_file)
  source(module$server_file)
}
```

### Dynamic UI Generation

UI generated once at startup based on enabled modules:

```r
do.call(tagList, module_loader$generate_tab_items())
```

## Security Considerations

### API Credentials

- Never hardcoded
- Stored in session-scoped R6 object
- Cleared on session end
- Not persisted to disk

### BigQuery Credentials

- Service account JSON
- Temp files cleaned up
- Session-scoped authentication

### Input Validation

All user inputs validated before processing:
```r
if (is.null(input$field) || trimws(input$field) == "") {
  # Error handling
  return()
}
```

## Testing Strategy

### Module Independence

Each module can be tested independently:

```r
# Test single module
test_module <- function() {
  testServer(module_name_server, {
    session$setInputs(input_id = "test_value")
    expect_equal(output$output_id, expected_result)
  })
}
```

### Integration Testing

Full app testing:
```r
shinytest2::test_app("/path/to/BusinessCanvasApp")
```

## Deployment

### Requirements

1. R >= 4.0
2. All packages installed
3. API credentials configured
4. Network access to APIs

### Deployment Options

**Shiny Server**:
```bash
# Deploy to /srv/shiny-server/BusinessCanvasApp/
sudo systemctl restart shiny-server
```

**ShinyApps.io**:
```r
rsconnect::deployApp("/path/to/BusinessCanvasApp")
```

**Docker**:
```dockerfile
FROM rocker/shiny:latest
COPY BusinessCanvasApp /srv/shiny-server/BusinessCanvasApp
```

## Scalability

### Adding Modules

1. Create module directory
2. Add manifest.yml
3. Create ui.R and server.R
4. Add to registry
5. Restart app

**No changes to core required**.

### Adding Features to Modules

1. Update module's ui.R and server.R
2. Update manifest.yml if new dependencies
3. Restart app

**Other modules unaffected**.

## Maintenance

### Updating Dependencies

Update `dependencies` in manifest.yml:

```yaml
dependencies:
  packages:
    - new_package
  package_versions:
    existing_package: ">= 2.0.0"
```

### Updating Styling

Edit `www/css/global.css` - changes apply globally immediately.

### Debugging

1. Check console for module loading messages
2. Review `module_loader$print()` output
3. Test individual modules in isolation
4. Use `browser()` in server functions

## Best Practices

### DO

✅ Always use `ns()` for IDs in UI functions  
✅ Use `moduleServer()` for server functions  
✅ Centralize styles in global.css  
✅ Document modules with README  
✅ Validate all inputs  
✅ Handle errors gracefully  
✅ Use meaningful variable names  
✅ Add comments for complex logic  

### DON'T

❌ Use inline CSS  
❌ Hardcode credentials  
❌ Access other modules' state  
❌ Use library() in modules  
❌ Forget to use ns() in UI  
❌ Skip input validation  
❌ Leave debug code in production  

## Conclusion

This architecture provides:
- **Modularity**: Features are independent
- **Scalability**: Easy to extend
- **Maintainability**: Clear structure
- **Performance**: Conditional loading
- **Quality**: Professional design patterns

The system is production-ready and follows enterprise-grade Shiny application architecture principles.
