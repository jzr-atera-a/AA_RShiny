# Modular Shiny App Template v3.0

**Production-Ready, Simplified Template for Building Modular R Shiny Applications**

---

## 🎯 What Is This?

This is a **lightweight, battle-tested template** for building modular Shiny apps. It solves all the common issues that plague monolithic Shiny applications:

- ✅ **Tab content displays properly** (no empty main body!)
- ✅ **Sidebar shows all menu items**
- ✅ **Easy enable/disable** of modules (one line change)
- ✅ **No namespace conflicts** between modules
- ✅ **Reactive state sharing** across modules
- ✅ **Centralized styling** with beautiful teal/cyan theme
- ✅ **API configuration management**
- ✅ **Ready for production**

---

## 📦 What's Included?

### Core Files
- `app.R` - Entry point (15 lines)
- `global.R` - Configuration with WORKING tab/menu generation
- `R/module_loader.R` - R6 class for module management
- `R/utils_api.R` - API manager with reactive triggers
- `R/utils_common.R` - Common utility functions

### Example Modules
1. **API Config** - Configure API credentials and timeout
2. **Dashboard** - Main dashboard with metrics and charts
3. **Data Viewer** - Data filtering with cascading dropdowns

### Styling
- `www/css/global.css` - Complete teal/cyan theme
- Styled boxes, buttons, forms, and status messages
- Responsive and professional design

---

## 🚀 Quick Start

### 1. Install Dependencies

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "R6",
  "yaml",
  "purrr",
  "ggplot2",
  "DT"
))
```

### 2. Run the App

```r
shiny::runApp()
```

### 3. Explore

- **Dashboard tab** - See the overview and example chart
- **API Config tab** - Configure your API settings
- **Data Viewer tab** - Try the cascading dropdowns

---

## 🔧 How to Use This Template

### Enable/Disable Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  api_config:
    enabled: true     # ← Change to false to disable
    priority: 1
  
  dashboard:
    enabled: true     # ← Change to false to disable
    priority: 10
```

### Add a New Module

1. **Create module folder:**
```bash
mkdir -p modules/my_module
```

2. **Create files:**
```
modules/my_module/
├── manifest.yml    # Module metadata
├── ui.R           # UI function
├── server.R       # Server function
└── README.md      # Documentation
```

3. **manifest.yml:**
```yaml
module:
  id: "my_module"
  name: "My Feature"
  description: "What this does"
  enabled: true
  
  menu:
    label: "My Feature"
    icon: "star"
    tabname: "my_module"
  
  dependencies:
    packages:
      - shiny
      - shinydashboard
```

4. **ui.R:**
```r
my_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "My Module",
        status = "primary",
        width = 12,
        
        # Wrap ALL IDs with ns()
        textInput(ns("my_input"), "Enter text:"),
        actionButton(ns("my_button"), "Click Me"),
        
        htmlOutput(ns("my_output"))
      )
    )
  )
}
```

5. **server.R:**
```r
my_module_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$my_button, {
      output$my_output <- renderUI({
        tags$div(class = "status-success",
                 "You entered: ", input$my_input)
      })
    })
  })
}
```

6. **Register in `_module_registry.yml`:**
```yaml
modules:
  my_module:
    enabled: true
    priority: 30
```

7. **Restart app** - Your module appears automatically!

---

## 🎨 Customization

### Change App Title

In `modules/_module_registry.yml`:

```yaml
app:
  name: "Your App Name"
  version: "1.0.0"
```

### Modify Colors

Edit `www/css/global.css`:

```css
/* Change primary color */
.btn-primary {
  background: linear-gradient(135deg, #YOUR_COLOR_1 0%, #YOUR_COLOR_2 100%) !important;
}
```

### Add Custom CSS

Create `www/css/modules/my_module.css` and it will be automatically available.

---

## 📚 Key Concepts

### 1. Namespacing

**CRITICAL:** Wrap ALL input/output IDs with `ns()` in UI:

```r
# ✓ CORRECT
textInput(ns("my_input"), ...)
plotOutput(ns("my_plot"), ...)

# ✗ WRONG
textInput("my_input", ...)  # Missing ns()!
```

### 2. Module Communication

Use the `api_manager` shared object:

```r
# In API config module
api_manager$set_api_credentials(key, timeout)
api_manager$trigger_state_update()  # Notify other modules

# In other modules
observe({
  api_manager$state_trigger()  # Watch for changes
  
  if (api_manager$authenticated) {
    # React to authentication
  }
})
```

### 3. Cascading Dropdowns

```r
observeEvent(input$level1, {
  # Clear downstream
  if (input$level1 == "") {
    updateSelectInput(session, "level2", choices = c("Select..." = ""))
    return()
  }
  
  # Populate level 2 based on level 1
  choices <- query_based_on_level1(input$level1)
  updateSelectInput(session, "level2", choices = choices)
})
```

---

## ⚠️ Common Mistakes to Avoid

### 1. ❌ Not Using ns() in UI
```r
# WRONG!
textInput("my_input", ...)

# RIGHT!
textInput(ns("my_input"), ...)
```

### 2. ❌ Trying to Build Tabs with Methods
```r
# WRONG! (V2.0 mistake)
dashboardBody(module_loader$generate_tab_items())

# RIGHT! (V3.0 pattern)
# Use FOR LOOP in global.R (already done for you)
```

### 3. ❌ Not Converting Types in HTML
```r
# WRONG!
sprintf('<div>%s</div>', data$column)

# RIGHT!
sprintf('<div>%s</div>', as.character(data$column))
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│                    app.R                        │
│              (15 lines - entry point)           │
└──────────────────┬──────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────┐
│                  global.R                       │
│  • Load utilities                               │
│  • Initialize api_manager                       │
│  • create_ui() - Build tabs in FOR LOOP ✓      │
│  • create_server() - Initialize modules         │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ↓          ↓          ↓
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Module 1    │ │ Module 2    │ │ Module 3    │
├─────────────┤ ├─────────────┤ ├─────────────┤
│ ui.R        │ │ ui.R        │ │ ui.R        │
│ server.R    │ │ server.R    │ │ server.R    │
│ manifest    │ │ manifest    │ │ manifest    │
└─────────────┘ └─────────────┘ └─────────────┘
        │          │          │
        └──────────┴──────────┘
                   │
                   ↓
        ┌─────────────────────┐
        │    api_manager      │
        │  (shared across     │
        │   all modules)      │
        └─────────────────────┘
```

---

## 🧪 Testing Checklist

- [ ] App starts without errors
- [ ] Sidebar shows 3 menu items
- [ ] Main body shows content for each tab
- [ ] API Config tab displays form
- [ ] Dashboard tab shows value boxes and chart
- [ ] Data Viewer tab has cascading dropdowns
- [ ] Dropdowns populate when selections made
- [ ] All boxes have rounded corners and shadows
- [ ] Status messages show in colored boxes
- [ ] Buttons have gradient backgrounds

---

## 📖 Further Reading

See the included template documentation for:
- Complete file templates
- Advanced patterns
- Troubleshooting guide
- Migration from monolithic apps

---

## 🎉 Success!

If you can see:
- ✅ Sidebar with 3 menu items
- ✅ Dashboard tab with value boxes
- ✅ API Config tab with form
- ✅ Data Viewer tab with dropdowns
- ✅ Beautiful teal/cyan theme

**Congratulations! Your template is working perfectly!**

---

## 📝 Version History

### v3.0 (Current)
- ✅ Fixed tab/menu generation (explicit FOR LOOP)
- ✅ Fixed HTML rendering patterns
- ✅ Added reactive state sharing
- ✅ Added cascading dropdowns example
- ✅ Complete CSS theme
- ✅ Production-ready

### v2.0 (Previous)
- ❌ Had empty main body issue
- ❌ Abstract methods broke tabs
- ⚠️ Not recommended

---

## 🆘 Support

If you encounter issues:

1. Check that all dependencies are installed
2. Verify `modules/_module_registry.yml` has modules enabled
3. Look for errors in R console
4. Review the troubleshooting section in the template docs

---

**Made with ❤️ using R Shiny**

**Version 3.0 - December 2025**
