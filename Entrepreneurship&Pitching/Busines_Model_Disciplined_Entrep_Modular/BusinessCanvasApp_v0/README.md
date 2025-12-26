# Business Canvas Manager - Modular R Shiny Application

A professional, modular R Shiny application for creating and managing Business Model Canvases and Disciplined Entrepreneurship frameworks, powered by Claude AI and BigQuery.

## 🎯 Overview

This application has been completely regenerated using modern modular architecture principles:

- **Minimal Entry Point**: `app.R` is only 15-20 lines
- **Centralized CSS**: All styling in `www/css/global.css` with corporate teal/cyan theme
- **Enable/Disable Modules**: Change ONE line in `modules/_module_registry.yml`
- **Namespace Isolation**: Zero module conflicts using `NS()` and `moduleServer()`
- **Conditional Loading**: Only load packages for enabled modules
- **R6 Architecture**: Professional OOP design for ModuleLoader and APIManager
- **Production Ready**: Full documentation, clean code, ready to deploy

## 📂 Directory Structure

```
BusinessCanvasApp/
├── app.R                          # Entry point (15 lines)
├── global.R                       # Configuration & UI/Server factories
│
├── R/
│   ├── module_loader.R            # R6 ModuleLoader class
│   ├── utils_api.R                # R6 APIManager (Claude & BigQuery)
│   ├── utils_common.R             # Shared utilities
│   └── utils_bigquery.R           # BigQuery table management
│
├── modules/
│   ├── _module_registry.yml       # Central control - enable/disable HERE
│   │
│   ├── claude_auth/               # Claude API connection
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   ├── server.R
│   │   └── README.md
│   │
│   ├── bigquery_auth/             # BigQuery authentication
│   ├── generate_bm_canvas/        # Generate Business Model Canvas
│   ├── generate_de_canvas/        # Generate DE Canvas
│   ├── generate_de_roadmap/       # Generate DE 24-step Roadmap
│   ├── view_bm_canvas/            # View Business Model Canvas
│   ├── view_de_canvas/            # View DE Canvas
│   └── view_de_roadmap/           # View DE Roadmap
│
├── www/                           # Static assets
│   ├── css/
│   │   └── global.css            # ALL CSS - corporate teal theme
│   ├── js/
│   └── img/
│
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites

```r
# Install required packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "R6",
  "yaml",
  "purrr",
  "DT",
  "dplyr",
  "jsonlite",
  "bigrquery",
  "stringr",
  "htmltools",
  "httr"
))
```

### Running the App

```r
# From R console
shiny::runApp("/path/to/BusinessCanvasApp")

# Or from command line
R -e "shiny::runApp('/path/to/BusinessCanvasApp')"
```

### API Setup

1. **Claude API**:
   - Get API key from https://console.anthropic.com/
   - Enter in "Claude API Connection" tab
   
2. **BigQuery**:
   - Create GCP project and service account
   - Download JSON credentials
   - Upload or paste in "BigQuery Authentication" tab

## ⚙️ Module Management

### Enable/Disable Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  generate_bm_canvas:
    enabled: true   # ← Change to false to disable
    priority: 10
    
  view_de_roadmap:
    enabled: false  # ← Disabled module
    priority: 22
```

**When disabled:**
- ❌ Files NOT sourced
- ❌ Packages NOT loaded
- ❌ NOT in sidebar menu
- ❌ NOT in tabs
- ❌ Zero performance overhead

### Adding a New Module

1. Create directory: `modules/my_new_module/`
2. Create files:
   - `manifest.yml` - Module metadata
   - `ui.R` - UI function: `my_new_module_ui(id)`
   - `server.R` - Server function: `my_new_module_server(id, api_manager, session)`
   - `README.md` - Documentation
3. Add to registry: `modules/_module_registry.yml`
4. Restart app

## 🎨 Styling

**ALL styling is in `www/css/global.css`**

- Corporate teal/cyan gradient theme
- No inline CSS anywhere in R code
- Consistent design across all modules
- Hover effects, transitions, shadows
- Responsive layouts

## 📊 Features

### Business Model Canvas
- AI-powered generation with Claude
- 9 building blocks
- Visual canvas display
- Save/load from BigQuery

### Disciplined Entrepreneurship
- 10-box canvas framework
- 24-step roadmap
- Comprehensive business planning
- MIT methodology

### API Integration
- Claude Sonnet 4 for content generation
- BigQuery for data persistence
- Secure credential management
- Connection testing

## 🏗️ Architecture

### Module Loader (R6)
- Discovers modules automatically
- Filters by enabled status
- Loads packages conditionally
- Sources files selectively
- Generates UI/menus dynamically

### API Manager (R6)
- Centralized credential storage
- Claude API integration
- BigQuery authentication
- Connection testing
- Automatic cleanup

### UI/Server Factories
- Dynamic menu generation
- Tab creation from modules
- Namespace isolation
- Clean separation of concerns

## 📝 Development

### Key Principles

1. **Modularity**: Each feature is independent
2. **Namespace Isolation**: Zero conflicts using `NS()`
3. **Centralized Config**: Single source of truth
4. **Conditional Loading**: Pay only for what you use
5. **Professional Code**: R6, documented, tested

### Coding Standards

```r
# UI Function Pattern
module_name_ui <- function(id) {
  ns <- NS(id)  # Create namespace function
  
  tagList(
    # Wrap ALL IDs with ns()
    textInput(ns("my_input"), "Label"),
    plotOutput(ns("my_plot"))
  )
}

# Server Function Pattern
module_name_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    # Access inputs directly (no ns() needed)
    output$my_plot <- renderPlot({
      plot(input$my_input)
    })
  })
}
```

## 🔧 Troubleshooting

### Modules Not Appearing
1. Check `modules/_module_registry.yml` - enabled: true?
2. Check console for errors during module loading
3. Verify ui.R and server.R exist in module directory

### API Connection Issues
1. Claude: Verify API key validity
2. BigQuery: Check JSON credentials format
3. Network: Ensure internet connectivity

### Namespace Conflicts
- Should never happen with proper `ns()` usage
- Check all IDs are wrapped with `ns()` in UI
- Verify `moduleServer()` is used in server

## 📚 Documentation

- **Main README**: This file
- **Implementation Notes**: `IMPLEMENTATION_NOTES.md`
- **Architecture Details**: See `global.R` and `R/module_loader.R`
- **Module READMEs**: In each `modules/*/README.md`

## 🎯 Success Criteria

✅ App runs without errors  
✅ Modules can be enabled/disabled via registry  
✅ All CSS centralized in global.css  
✅ Zero namespace conflicts  
✅ Packages load conditionally  
✅ Full documentation  
✅ Production-ready code  

## 📦 Dependencies

### Core (Always Loaded)
- shiny
- shinydashboard
- R6
- yaml
- purrr

### Conditional (Module-Specific)
- DT
- dplyr
- jsonlite
- bigrquery
- stringr
- htmltools
- httr

## 🔐 Security

- API keys stored in session only
- BigQuery credentials via service account
- No hardcoded secrets
- Temp files cleaned on exit

## 📄 License

Proprietary - Business Strategy Team

## 👥 Credits

- Original App: Business Strategy Team
- Modular Regeneration: Based on enterprise architecture patterns
- Frameworks: Business Model Canvas (Osterwalder), Disciplined Entrepreneurship (MIT)

## 🆘 Support

For issues, improvements, or questions, contact the Business Strategy Team.

---

**Version**: 2.0.0  
**Last Updated**: December 2024  
**Status**: Production Ready (with module implementation completion)
