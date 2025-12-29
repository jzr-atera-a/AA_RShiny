# Architecture Documentation

## System Overview

The Audio Processing Dashboard uses a **modular architecture** where each feature is an independent, self-contained module that can be enabled or disabled without affecting others.

## Core Design Principles

###  1. Modularity
Each feature is a separate module with its own:
- UI function (namespaced)
- Server function (isolated)
- Dependencies (conditionally loaded)
- Documentation

### 2. Namespace Isolation
Every module uses Shiny's namespace system (`NS()` and `moduleServer()`) to prevent ID conflicts.

### 3. Dynamic Loading
Modules are discovered and loaded at runtime based on registry settings.

### 4. Single Source of Truth
The `modules/_module_registry.yml` file controls which modules are active.

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        app.R                            │
│                   (Entry Point)                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                      global.R                           │
│   - Loads core packages                                 │
│   - Sources R6 classes                                  │
│   - Defines UI/Server factories                         │
└───────────────────────┬─────────────────────────────────┘
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
┌──────────────────────┐  ┌──────────────────────┐
│   ModuleLoader       │  │    APIManager        │
│   (R6 Class)         │  │    (R6 Class)        │
│                      │  │                      │
│ - Discovers modules  │  │ - Manages API keys   │
│ - Loads packages     │  │ - API calls          │
│ - Sources files      │  │ - Connection testing │
│ - Generates UI       │  │                      │
└──────────┬───────────┘  └──────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│            modules/_module_registry.yml                 │
│          (Enable/Disable Control Center)                │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Module 1    │ │  Module 2    │ │  Module 3    │
│              │ │              │ │              │
│ manifest.yml │ │ manifest.yml │ │ manifest.yml │
│ ui.R         │ │ ui.R         │ │ ui.R         │
│ server.R     │ │ server.R     │ │ server.R     │
└──────────────┘ └──────────────┘ └──────────────┘
```

## Module Lifecycle

### 1. Discovery Phase
```r
ModuleLoader$discover_modules()
├── Scans modules/ directory
├── Reads each manifest.yml
├── Checks registry for override
└── Stores module metadata
```

### 2. Loading Phase
```r
ModuleLoader$load_packages()
├── Gets enabled modules
├── Collects unique dependencies
└── Loads packages conditionally

ModuleLoader$source_modules()
├── Gets enabled modules
├── Sources ui.R for each
└── Sources server.R for each
```

### 3. Initialization Phase
```r
create_ui(module_loader)
├── generate_menu_items()  → Sidebar
└── generate_tab_items()   → Dashboard body

create_server(module_loader, api_manager)
└── Calls each module's _server() function
```

## Namespace System

### In UI (ui.R):
```r
my_module_ui <- function(id) {
  ns <- NS(id)  # Create namespace function
  
  textInput(ns("input_name"), ...)   # Wrap all IDs
  plotOutput(ns("plot_name"), ...)   # Wrap all IDs
}
```

### In Server (server.R):
```r
my_module_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    # Access inputs directly (no ns() needed)
    value <- input$input_name
    
    output$plot_name <- renderPlot({...})
  })
}
```

### Why This Works:
- `NS(id)` creates a namespacing function
- In UI: `ns("input")` becomes `"module_id-input"`
- In server: `moduleServer()` handles the mapping automatically
- Result: No ID conflicts between modules

## Data Flow

```
User Action
    │
    ▼
Input (namespaced ID)
    │
    ▼
Module Server Function
    │
    ├──→ Reactive Values
    ├──→ API Calls (via APIManager)
    └──→ Data Processing
         │
         ▼
    Render Output
         │
         ▼
    UI Update
```

## R6 Class: ModuleLoader

### Properties:
- `modules` - List of all discovered modules
- `registry` - Registry file contents
- `loaded_packages` - Track loaded packages

### Methods:
- `load_registry()` - Read _module_registry.yml
- `discover_modules()` - Find all modules
- `get_enabled_modules()` - Filter to enabled only
- `load_packages()` - Load dependencies
- `source_modules()` - Source R files
- `generate_menu_items()` - Create sidebar
- `generate_tab_items()` - Create tabs
- `print()` - Show status

### Key Pattern:
```r
# Every method that processes modules uses this:
enabled_modules <- self$get_enabled_modules()

# Never process all modules - only enabled ones
```

## R6 Class: APIManager

### Properties:
- `api_key` - OpenAI API key
- `model` - Whisper model name
- `language` - Language code

### Methods:
- `set_credentials()` - Store API settings
- `test_connection()` - Verify API access
- `transcribe_audio()` - Call Whisper API
- `analyze_text()` - Call ChatGPT API

### Usage in Modules:
```r
module_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    # Use API manager
    result <- api_manager$transcribe_audio(file_path)
  })
}
```

## Enable/Disable Mechanism

### Registry File:
```yaml
modules:
  my_module:
    enabled: false  # ← Change this
    priority: 10
```

### What Happens When Disabled:
1. `discover_modules()` sets `enabled = FALSE`
2. `get_enabled_modules()` excludes it
3. `load_packages()` skips its dependencies
4. `source_modules()` doesn't source files
5. `generate_menu_items()` doesn't create menu item
6. `generate_tab_items()` doesn't create tab

Result: **Module completely absent from app**

## CSS Architecture

### Centralized Styling:
- **All CSS** in `www/css/global.css`
- **No inline styles** in R files
- **Shiny automatically** serves www/ directory

### Theme Structure:
```css
/* Layout */
.main-header .navbar {...}
.main-sidebar {...}
.content-wrapper {...}

/* Components */
.box {...}
.box-header {...}
.btn-primary {...}

/* Custom Classes */
.info-box {...}
.reference-box {...}
```

### Usage in Modules:
```r
# Just use the classes - CSS is already loaded
div(class = "info-box",
  h5("Information"),
  p("Content here")
)
```

## Memory Management

### Session Cleanup:
```r
session$onSessionEnded(function() {
  # Clear reactive values
  if (exists("values")) rm(values)
  
  # Force garbage collection
  gc(verbose = FALSE)
  
  # Clean temp files
  unlink(temp_files)
})
```

### Best Practices:
- Use `reactiveVal()` and `reactiveValues()` for state
- Clear large objects when done
- Call `gc()` on session end
- Remove temporary files explicitly

## Error Handling

### At Module Level:
```r
tryCatch({
  # Risky operation
}, error = function(e) {
  showNotification(paste("Error:", e$message), type = "error")
  return(NULL)
})
```

### At App Level:
- Missing modules → Warning in console
- Missing packages → Error message
- Invalid registry → App fails to start (intentional)

## Performance Optimization

### Conditional Loading:
- Only load packages for **enabled** modules
- Don't source **disabled** modules
- Lazy evaluation of reactive expressions

### Efficient Reactivity:
```r
# Good: Reactive expression (cached)
filtered_data <- reactive({
  expensive_operation(input$value)
})

# Bad: Repeating expensive operation
output$plot <- renderPlot({
  expensive_operation(input$value)  # Runs every render!
})
```

## Testing Strategy

### Unit Testing (Modules):
```r
testServer(my_module_server, {
  # Set inputs
  session$setInputs(my_input = "test")
  
  # Test outputs
  expect_equal(output$my_output, expected_value)
})
```

### Integration Testing:
- Enable one module at a time
- Test interactions between modules
- Verify namespace isolation

## Deployment Considerations

### File Upload Limits:
```r
# In global.R
options(shiny.maxRequestSize = 100*1024^2)  # 100MB
```

### API Rate Limits:
- OpenAI has rate limits
- Implement retry logic
- Show progress indicators

### Server Resources:
- Audio processing is CPU-intensive
- Text analysis requires API calls
- Consider worker processes for heavy tasks

## Extension Points

### Adding New Module Types:
1. Create module structure
2. Follow naming conventions
3. Add to registry
4. Document in module README

### Adding New API Providers:
1. Extend `APIManager` class
2. Add new methods
3. Update Settings module
4. Document API requirements

### Adding New Features:
- Add to existing module, or
- Create new module if independent

## Security Notes

### API Keys:
- Stored in memory only
- Not persisted to disk
- Cleared on session end

### File Uploads:
- Size limits enforced
- File type validation
- Temporary storage only

### User Data:
- No cross-session data sharing
- Each session isolated
- Automatic cleanup

## Version Control

### What to Commit:
- All R code
- Module structure
- Configuration files
- Documentation

### What to Ignore:
- API keys
- User data
- Temporary files
- Generated outputs

### `.gitignore`:
```
.Rproj.user
.Rhistory
.RData
*.Rproj
rsconnect/
```

## Future Enhancements

### Potential Features:
- User authentication
- Database integration
- Job queue for long tasks
- Real-time collaboration
- Enhanced analytics
- Custom module templates
- Module marketplace

### Scalability:
- Add caching layer
- Implement background jobs
- Use async processing
- Add database backend
- Containerize with Docker

---

## Quick Reference

### File Locations:
- **App entry**: `app.R`
- **Configuration**: `global.R`
- **Module loader**: `R/module_loader.R`
- **API manager**: `R/utils_api.R`
- **Enable/disable**: `modules/_module_registry.yml`
- **Styles**: `www/css/global.css`

### Module Template:
```
modules/my_module/
├── manifest.yml    # Metadata & dependencies
├── ui.R           # UI function with NS()
├── server.R       # Server with moduleServer()
└── README.md      # Documentation
```

### Function Naming:
- UI: `{module_id}_ui`
- Server: `{module_id}_server`
- Module ID: `lowercase_with_underscores`

### Common Tasks:
- **Disable module**: Edit `_module_registry.yml`
- **Change colors**: Edit `www/css/global.css`
- **Add module**: Create folder + 4 files + registry entry
- **Debug**: Check console for module status
