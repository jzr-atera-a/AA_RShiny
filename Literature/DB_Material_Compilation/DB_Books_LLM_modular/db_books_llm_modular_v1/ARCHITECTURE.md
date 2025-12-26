# Book Summary Suite - Architecture Documentation

## Overview

This application uses a **modern modular architecture** where each feature is a self-contained, independently enable/disable-able module. This design ensures:

- ✅ **Zero namespace conflicts** - Proper use of `NS()` and `moduleServer()`
- ✅ **Clean separation** - Each feature is independent
- ✅ **Easy maintenance** - Modify one module without affecting others
- ✅ **Flexible deployment** - Enable only what you need
- ✅ **Scalability** - Add new features as modules

## Core Architecture Components

### 1. Entry Point (`app.R`)

**15 lines maximum** - Only loads configuration and runs the app:

```r
source("global.R")
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    create_server(module_loader, api_manager)
  }
)
```

### 2. Global Configuration (`global.R`)

Handles:
- Core package loading
- Utility sourcing
- API manager initialization
- UI factory function (`create_ui`)
- Server factory function (`create_server`)

### 3. Module Loader (`R/module_loader.R`)

**R6 class** that manages all modules:

```r
ModuleLoader <- R6::R6Class(
  "ModuleLoader",
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    initialize = function() { ... },
    load_registry = function() { ... },
    discover_modules = function() { ... },
    get_enabled_modules = function() { ... },  # ⭐ CRITICAL
    load_packages = function() { ... },
    source_modules = function() { ... },
    generate_menu_items = function() { ... },
    generate_tab_items = function() { ... }
  )
)
```

**Key principle:** Every method that processes modules MUST call `self$get_enabled_modules()` first.

### 4. API Manager (`R/utils_api.R`)

**R6 class** with **reactive triggers** for cross-module communication:

```r
APIManager <- R6::R6Class(
  "APIManager",
  public = list(
    # State
    claude_api_key = NULL,
    claude_authenticated = FALSE,
    bq_authenticated = FALSE,
    
    # ⭐ CRITICAL: Reactive trigger
    state_trigger = NULL,
    
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
    },
    
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)  # ⭐ FIRES ALL WATCHERS
    },
    
    # API methods
    authenticate_bigquery = function(...) { ... },
    call_claude = function(...) { ... },
    bq_query = function(...) { ... },
    bq_insert = function(...) { ... }
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
  id: "my_module"                    # lowercase_with_underscores
  name: "My Module"                  # Display name
  description: "What this does"
  version: "1.0.0"
  author: "Your Name"
  
  enabled: true                      # Can be overridden by registry
  
  menu:
    label: "My Module"               # Sidebar text
    icon: "chart-line"               # FontAwesome icon
    tabname: "my_module"             # Must match ID
    badge:
      label: null
      color: null
  
  dependencies:
    packages:
      - shiny
      - shinydashboard
    package_versions: {}
  
  api:
    required: []                     # e.g., ["claude", "bigquery"]
    optional: []
  
  data:
    required: []
    optional: []
```

### ui.R

```r
# ⭐ CRITICAL: Function name must be {module_id}_ui

my_module_ui <- function(id) {
  # ⭐ CRITICAL: Create namespace function
  ns <- NS(id)
  
  # ⭐ CRITICAL: ALL IDs must be wrapped with ns()
  tagList(
    fluidRow(
      box(
        title = "My Module",
        textInput(ns("my_input"), "Label:"),      # ← ns() wrapper
        actionButton(ns("my_button"), "Click"),   # ← ns() wrapper
        htmlOutput(ns("my_output"))               # ← ns() wrapper
      )
    )
  )
}
```

### server.R

```r
# ⭐ CRITICAL: Function name must be {module_id}_server

my_module_server <- function(id, api_manager) {
  # ⭐ CRITICAL: Use moduleServer for namespacing
  moduleServer(id, function(input, output, session) {
    
    # ⭐ Watch for API authentication changes
    observe({
      api_manager$state_trigger()  # Makes observer reactive
      
      if (api_manager$bq_authenticated) {
        # React to authentication
        load_data()
      }
    })
    
    # Event handlers
    observeEvent(input$my_button, {
      # Access inputs directly (no ns() needed in server)
      data <- get_data(input$my_input)
      
      output$my_output <- renderUI({
        tags$div(class = "status-success", "Done!")
      })
    })
    
    # Cleanup
    session$onSessionEnded(function() {
      # Cleanup code here
    })
  })
}
```

## Module Registry

The **CONTROL CENTER** - change ONE line to enable/disable:

```yaml
# modules/_module_registry.yml

modules:
  my_module:
    enabled: false  # ← CHANGE ONLY THIS LINE
    priority: 10    # Load order (lower = earlier)
    description: "My awesome module"
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
# In APIManager
public = list(
  authenticated = FALSE
)

# In module
observe({
  if (api_manager$authenticated) {  # ← NOT REACTIVE
    load_data()
  }
})
```

### ✅ CORRECT (Works):

```r
# In APIManager
public = list(
  authenticated = FALSE,
  state_trigger = NULL,  # ← Reactive trigger
  
  initialize = function() {
    self$state_trigger <- shiny::reactiveVal(0)
  },
  
  authenticate = function(...) {
    # ... auth logic ...
    self$authenticated <- TRUE
    self$trigger_state_update()  # ← TRIGGER ALL MODULES
  },
  
  trigger_state_update = function() {
    current <- self$state_trigger()
    self$state_trigger(current + 1)
  }
)

# In module
observe({
  api_manager$state_trigger()  # ← WATCH THIS
  
  if (api_manager$authenticated) {  # Now this works!
    load_data()
  }
})
```

## Cascading Dropdowns Pattern

Example: Authentication → Level 1 → Level 2 → Level 3

```r
my_module_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # ⭐ STEP 1: Populate first dropdown after authentication
    observe({
      api_manager$state_trigger()  # Watch for auth
      
      if (api_manager$bq_authenticated) {
        update_level1()
      }
    })
    
    update_level1 <- function() {
      if (!api_manager$bq_authenticated) return()
      
      query <- "SELECT DISTINCT category FROM table ORDER BY category"
      result <- api_manager$bq_query(query)
      
      updateSelectInput(session, "level1",
                       choices = c("Select..." = "", result$category))
    }
    
    # ⭐ STEP 2: Cascade to level 2
    observeEvent(input$level1, {
      if (input$level1 == "") {
        updateSelectInput(session, "level2", choices = c("Select..." = ""))
        return()
      }
      
      # ⭐ SQL INJECTION PREVENTION
      safe_input <- gsub("'", "''", input$level1)
      
      query <- sprintf("SELECT DISTINCT subcategory FROM table WHERE category = '%s'",
                      safe_input)
      result <- api_manager$bq_query(query)
      
      updateSelectInput(session, "level2",
                       choices = c("Select..." = "", result$subcategory))
    })
  })
}
```

## BigQuery Integration Pattern

### Authentication

```r
# In APIManager
authenticate_bigquery = function(json_path = NULL, json_text = NULL) {
  # Clear existing auth
  tryCatch({ bq_deauth() }, error = function(e) {})
  
  if (!is.null(json_path)) {
    bq_auth(path = json_path, cache = FALSE)
  } else if (!is.null(json_text)) {
    temp_file <- tempfile(fileext = ".json")
    writeLines(json_text, temp_file)
    bq_auth(path = temp_file, cache = FALSE)
  }
  
  # Test connection
  datasets <- bq_project_datasets(self$bq_project_id)
  
  self$bq_authenticated <- TRUE
  self$trigger_state_update()  # ⭐ NOTIFY ALL MODULES
}
```

### Query

```r
# In APIManager
bq_query = function(query) {
  if (!self$bq_authenticated) stop("Not authenticated")
  
  job <- bq_project_query(self$bq_project_id, query)
  return(bq_table_download(job))
}
```

### Insert

```r
# In APIManager
bq_insert = function(data_frame) {
  if (!self$bq_authenticated) stop("Not authenticated")
  
  # Get next ID
  max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`",
                         self$bq_full_table_id)
  result <- bq_project_query(self$bq_project_id, max_id_query)
  max_id_data <- bq_table_download(result)
  start_id <- as.integer(max_id_data$max_id) + 1
  
  # Add ID and timestamp
  data_frame$id <- seq(start_id, start_id + nrow(data_frame) - 1)
  data_frame$created_at <- Sys.time()
  
  # Upload
  table_ref <- bq_table(self$bq_project_id, self$bq_dataset_id, self$bq_table_id)
  bq_table_upload(table_ref, data_frame,
                 write_disposition = "WRITE_APPEND")
  
  return(nrow(data_frame))
}
```

## Claude API Integration Pattern

### Authentication

```r
# In APIManager
test_claude_connection = function() {
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = self$claude_api_key,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(list(
      model = self$claude_model,
      max_tokens = 100,
      messages = list(list(role = "user", content = "Test"))
    ), auto_unbox = TRUE),
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    self$claude_authenticated <- TRUE
    self$trigger_state_update()
    return(TRUE)
  }
}
```

### Call API

```r
# In APIManager
call_claude = function(prompt, max_tokens = NULL) {
  if (!self$claude_authenticated) stop("Not authenticated")
  
  tokens <- max_tokens %||% self$claude_max_tokens
  
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = self$claude_api_key,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(list(
      model = self$claude_model,
      max_tokens = tokens,
      messages = list(list(role = "user", content = prompt))
    ), auto_unbox = TRUE),
    encode = "json",
    config = httr::config(timeout = 180)
  )
  
  if (status_code(response) != 200) {
    stop("API request failed")
  }
  
  result <- content(response, "parsed")
  return(result$content[[1]]$text)
}
```

## CSS Architecture

**ALL styling** is centralized in `www/css/global.css`:

- ✅ NO inline CSS in any R files
- ✅ Corporate teal/cyan theme
- ✅ Modern gradients and shadows
- ✅ Hover effects
- ✅ Status boxes (success, error, info, warning)
- ✅ Formula and reference boxes
- ✅ Responsive design

## Security Best Practices

### SQL Injection Prevention

```r
# ❌ WRONG (Vulnerable)
query <- sprintf("SELECT * FROM table WHERE name = '%s'", input$name)

# ✅ CORRECT (Safe)
safe_name <- gsub("'", "''", input$name)
query <- sprintf("SELECT * FROM table WHERE name = '%s'", safe_name)

# ✅ BETTER (Use parameterized data frames for INSERT/UPDATE)
data_frame <- data.frame(
  name = input$name,  # No escaping needed
  value = input$value,
  stringsAsFactors = FALSE
)
api_manager$bq_insert(data_frame)
```

### API Key Storage

- ✅ Stored in memory only (not persisted)
- ✅ Not in version control
- ✅ Not in logs
- ✅ Cleared on session end

## Error Handling Pattern

```r
# Standardized error handling
tryCatch({
  result <- api_manager$bq_query(query)
  
  output$status <- renderUI({
    tags$div(class = "status-success", "✓ Success!")
  })
  
  showNotification("✓ Operation successful!", type = "message")
  
}, error = function(e) {
  output$status <- renderUI({
    tags$div(class = "status-error", "Error: ", e$message)
  })
  
  showNotification(paste("Error:", e$message), type = "error")
})
```

## Adding a New Module - Step by Step

### 1. Create Directory Structure

```bash
mkdir -p modules/my_module
touch modules/my_module/{manifest.yml,ui.R,server.R,README.md}
```

### 2. Create manifest.yml

```yaml
module:
  id: "my_module"
  name: "My Module"
  description: "What this module does"
  version: "1.0.0"
  author: "Your Name"
  enabled: true
  menu:
    label: "My Module"
    icon: "chart-line"
    tabname: "my_module"
    badge: {label: null, color: null}
  dependencies:
    packages: [shiny, shinydashboard]
    package_versions: {}
  api: {required: [], optional: []}
  data: {required: [], optional: []}
```

### 3. Create ui.R

```r
my_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "My Module",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        textInput(ns("input1"), "Label:"),
        actionButton(ns("button1"), "Click", class = "btn-primary"),
        htmlOutput(ns("output1"))
      )
    )
  )
}
```

### 4. Create server.R

```r
my_module_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$button1, {
      output$output1 <- renderUI({
        tags$div(class = "status-success", "✓ Done!")
      })
    })
    
    session$onSessionEnded(function() {})
  })
}
```

### 5. Register in `_module_registry.yml`

```yaml
modules:
  my_module:
    enabled: true
    priority: 10
    description: "My awesome module"
```

### 6. Test

```r
shiny::runApp()
```

## Validation Checklist

- [ ] app.R under 20 lines
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
- [ ] APIManager uses R6 class
- [ ] get_enabled_modules() used everywhere
- [ ] Menu items auto-generated
- [ ] Tab items auto-generated

## Performance Considerations

- **Disabled modules** = zero overhead (not loaded at all)
- **Reactive triggers** = minimal performance impact
- **BigQuery** = efficient for large datasets
- **Conditional package loading** = faster startup

## Deployment

### Local

```r
shiny::runApp()
```

### Shiny Server

```bash
# Copy to shiny-apps directory
cp -r BookSummaryApp /srv/shiny-server/

# Restart shiny-server
sudo systemctl restart shiny-server
```

### shinyapps.io

```r
library(rsconnect)
deployApp()
```

---

**This architecture ensures production-ready, maintainable, and scalable Shiny applications.**
