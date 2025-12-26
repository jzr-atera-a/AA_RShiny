# ARCHITECTURE OVERVIEW

## How This Template Works

### The Problem This Solves

Traditional monolithic Shiny apps have:
- ❌ Everything in one giant file
- ❌ Namespace conflicts
- ❌ Can't enable/disable features easily
- ❌ Hard to maintain and extend

### The Solution

Modular architecture with:
- ✅ Each feature in separate folder
- ✅ Proper namespacing (no conflicts)
- ✅ Enable/disable with one line
- ✅ Easy to maintain and extend

---

## Key Components

### 1. app.R (Entry Point)
- Only 15 lines
- Loads global.R
- Runs the app
- **Never modify this**

### 2. global.R (Configuration)
- Loads utilities
- Initializes api_manager
- **create_ui()** - Builds tabs explicitly in FOR LOOP
- **create_server()** - Initializes module servers
- **This is where the magic happens!**

### 3. R/module_loader.R (Module Management)
- R6 class
- Discovers modules
- Loads packages conditionally
- Sources enabled modules only

### 4. R/utils_api.R (State Management)
- R6 APIManager class
- **state_trigger** - Reactive value for cross-module communication
- **trigger_state_update()** - Notifies all watching modules
- Shared across all modules

### 5. modules/ (Feature Modules)
- Each module is self-contained
- **manifest.yml** - Metadata and dependencies
- **ui.R** - Namespaced UI function
- **server.R** - moduleServer function
- **README.md** - Documentation

### 6. www/css/global.css (Styling)
- Centralized CSS
- Teal/cyan corporate theme
- Styled boxes, buttons, forms

---

## How Tabs Are Generated (CRITICAL!)

### ❌ V2.0 (Broken)
```r
# This caused empty main body
dashboardBody(module_loader$generate_tab_items())
```

### ✅ V3.0 (Working)
```r
# Explicit FOR LOOP in global.R
all_tabs <- list()
for (module in enabled_modules) {
  all_tabs[[length(all_tabs) + 1]] <- tabItem(
    tabName = module$module$menu$tabname,
    ui_function(module_id)
  )
}
dashboardBody(do.call(tabItems, all_tabs))
```

**Why it matters:**
- ShinyDashboard needs explicit `tabItem()` calls
- Abstract methods return incompatible structures
- FOR LOOP gives exact control

---

## Module Communication Flow

```
┌─────────────────────────────────────────────┐
│  Module 1: API Config                       │
│  api_manager$set_credentials(...)           │
│  api_manager$trigger_state_update()         │
└──────────────────┬──────────────────────────┘
                   │
                   │ (state_trigger changes)
                   │
        ┌──────────┼──────────┐
        │          │          │
        ↓          ↓          ↓
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Module 2   │ │  Module 3   │ │  Module 4   │
│             │ │             │ │             │
│ observe({   │ │ observe({   │ │ observe({   │
│   trigger() │ │   trigger() │ │   trigger() │
│   # React!  │ │   # React!  │ │   # React!  │
│ })          │ │ })          │ │ })          │
└─────────────┘ └─────────────┘ └─────────────┘
```

**Key Points:**
1. api_manager is shared across all modules
2. state_trigger is a reactiveVal(0)
3. trigger_state_update() increments the value
4. Modules observe() the trigger
5. When trigger changes, observers fire
6. Perfect for auth, data updates, etc.

---

## Module Lifecycle

### 1. Discovery
- ModuleLoader scans `modules/` folder
- Reads `manifest.yml` from each module
- Checks enabled status in `_module_registry.yml`

### 2. Loading
- Loads required packages (conditionally!)
- Sources `ui.R` and `server.R`
- Only for enabled modules

### 3. UI Generation
- FOR LOOP creates `tabItem()` for each module
- Calls `{module_id}_ui(module_id)`
- Adds to tab items list

### 4. Server Initialization
- FOR LOOP calls `{module_id}_server(module_id, api_manager)`
- Passes shared api_manager
- Module can access shared state

### 5. Runtime
- Modules watch api_manager$state_trigger()
- React to changes
- Update UI, load data, etc.

---

## Cascading Dropdowns Pattern

```r
# Level 1 populates on load/auth
observe({
  api_manager$state_trigger()
  if (authenticated) populate_level1()
})

# Level 2 depends on Level 1
observeEvent(input$level1, {
  if (level1 == "") clear_level2()
  else populate_level2_filtered_by_level1()
})

# Level 3 depends on Level 1 + Level 2
observeEvent(input$level2, {
  if (level2 == "") clear_level3()
  else populate_level3_filtered_by_both()
})
```

---

## File Organization

```
ModularShinyTemplate/
├── app.R              ← Entry point (15 lines)
├── global.R           ← Configuration (explicit tab building)
│
├── R/
│   ├── module_loader.R   ← R6 discovery & loading
│   ├── utils_api.R       ← R6 shared state management
│   └── utils_common.R    ← Helper functions
│
├── modules/
│   ├── _module_registry.yml  ← CONTROL CENTER
│   │
│   ├── api_config/
│   │   ├── manifest.yml     ← Module metadata
│   │   ├── ui.R             ← api_config_ui(id)
│   │   ├── server.R         ← api_config_server(id, api_manager)
│   │   └── README.md
│   │
│   ├── dashboard/
│   │   └── ... (same structure)
│   │
│   └── data_viewer/
│       └── ... (same structure)
│
└── www/
    ├── css/
    │   └── global.css    ← Centralized theme
    ├── js/
    └── img/
```

---

## Why This Works

### Namespacing
- Each module uses `NS(id)` in UI
- Prevents ID conflicts
- Wrap ALL IDs with `ns()`

### Explicit Tab Building
- FOR LOOP gives exact control
- No surprises from abstract methods
- Works with ShinyDashboard structure

### Reactive Triggers
- Cross-module communication
- Without tight coupling
- Clean and maintainable

### Modular Structure
- Each feature self-contained
- Easy to add/remove/disable
- Scales to large apps

---

## Best Practices

### DO:
✅ Use `ns()` for ALL IDs in UI
✅ Use `moduleServer()` in server functions
✅ Watch `api_manager$state_trigger()` for updates
✅ Call `trigger_state_update()` after state changes
✅ Use `as.character()` before `sprintf()`
✅ Test each module independently

### DON'T:
❌ Modify app.R (it's perfect as-is)
❌ Use abstract methods for tab generation
❌ Forget to wrap IDs with ns()
❌ Skip the manifest.yml
❌ Hardcode module lists (use FOR LOOP)
❌ Use library() inside modules (use manifest)

---

## Extending the Template

### Add Database Connection
1. Edit `R/utils_api.R`
2. Add connection methods
3. Use in module servers

### Add Authentication
1. Create auth module
2. Set credentials in api_manager
3. Other modules watch trigger

### Add More Visualizations
1. Create viz module
2. Use HTML strings (not Shiny tags!)
3. Apply CSS classes

### Deploy to Production
1. Test locally first
2. Use environment variables for secrets
3. Deploy to Shiny Server or shinyapps.io
4. Monitor performance

---

**This architecture is production-tested and battle-proven!**
