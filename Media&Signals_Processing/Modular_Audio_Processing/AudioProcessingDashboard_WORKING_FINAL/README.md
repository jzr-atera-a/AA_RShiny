# Audio Processing Dashboard - Modular Architecture v2.0

## Overview
A modern, production-ready R Shiny application for audio processing, transcription, and text analysis using OpenAI's Whisper and ChatGPT APIs.

**FULLY MODULAR ARCHITECTURE** - Enable/disable any module by editing ONE line in the registry file.

## Features

### Core Modules (All Enabled by Default)
1. **Settings** - OpenAI API configuration and testing
2. **Audio Converter** - M4A to MP3 conversion with auto-splitting
3. **File Splitter** - Split audio files by size or segments
4. **Transcription** - Audio-to-text using Whisper API
5. **Bulk Analysis** - Analyze multiple text files with ChatGPT
6. **Analytics** - Processing history and statistics dashboard

### Architecture Benefits
- ✅ **Modular Design** - Each feature is an independent module
- ✅ **Namespace Isolation** - Zero conflicts between modules
- ✅ **Enable/Disable Control** - Change ONE line to enable/disable modules
- ✅ **Centralized Styling** - All CSS in `www/css/global.css`
- ✅ **R6 Classes** - ModuleLoader and APIManager for clean architecture
- ✅ **Memory Management** - Automatic cleanup on session end
- ✅ **Conditional Package Loading** - Only load packages for enabled modules

## Quick Start

### 1. Install Required Packages
```r
install.packages(c(
  # Core packages
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  
  # UI packages
  "DT", "plotly", "shinycssloaders", "shinyFiles",
  
  # API packages
  "httr", "jsonlite",
  
  # Audio processing packages
  "av", "tuneR", "seewave",
  
  # Utility packages
  "stringr", "fs"
))
```

### 2. Run the Application
```r
# Navigate to the app directory
setwd("/path/to/AudioApp")

# Run the app
shiny::runApp()
```

### 3. Configure API
1. Go to the **Settings** tab
2. Enter your OpenAI API key
3. Select Whisper model and language (optional)
4. Click "Save Settings"
5. Test the connection

## Directory Structure

```
AudioApp/
├── app.R                          # Entry point (minimal)
├── global.R                       # Global configuration & UI/Server factories
│
├── R/                             # Core R6 classes and utilities
│   ├── module_loader.R            # R6 ModuleLoader class
│   ├── utils_common.R             # Shared utility functions
│   └── utils_api.R                # R6 APIManager class
│
├── modules/                       # All feature modules
│   ├── _module_registry.yml       # ⭐ ENABLE/DISABLE MODULES HERE ⭐
│   │
│   ├── settings/                  # API configuration module
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   ├── server.R
│   │   └── README.md
│   │
│   ├── converter/                 # M4A to MP3 converter
│   ├── splitter/                  # Audio file splitter
│   ├── transcription/             # Whisper transcription
│   ├── bulk_analysis/             # ChatGPT analysis
│   └── analytics/                 # Analytics dashboard
│
├── www/                           # Static assets
│   ├── css/
│   │   └── global.css             # ⭐ ALL CSS HERE ⭐
│   ├── js/
│   └── img/
│
└── data/                          # Data files
```

## Enable/Disable Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  settings:
    enabled: true      # ⭐ Change to false to disable
    priority: 1
  
  converter:
    enabled: true      # ⭐ Change to false to disable
    priority: 10
  
  # ... etc
```

**When a module is disabled:**
- ❌ NOT loaded (no source())
- ❌ Packages NOT loaded
- ❌ NOT in sidebar menu
- ❌ NOT in dashboard
- ❌ ZERO performance overhead

## Module Structure

Each module follows this pattern:

### manifest.yml
```yaml
module:
  id: "module_name"
  name: "Display Name"
  description: "Module description"
  enabled: true
  
  menu:
    label: "Menu Label"
    icon: "icon-name"
    tabname: "module_name"
  
  dependencies:
    packages:
      - shiny
      - package1
      - package2
```

### ui.R
```r
module_name_ui <- function(id) {
  ns <- NS(id)  # CRITICAL: Create namespace
  
  tagList(
    # All IDs must be wrapped with ns()
    textInput(ns("my_input"), "Label"),
    plotOutput(ns("my_plot"))
  )
}
```

### server.R
```r
module_name_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    # Access inputs directly (no ns() in server)
    output$my_plot <- renderPlot({
      # Use input$my_input
    })
  })
}
```

## Adding a New Module

1. **Create module directory:**
   ```
   modules/my_new_module/
   ```

2. **Create files:**
   - `manifest.yml` - Module metadata
   - `ui.R` - UI function with NS()
   - `server.R` - Server function with moduleServer()
   - `README.md` - Documentation

3. **Add to registry:**
   ```yaml
   modules:
     my_new_module:
       enabled: true
       priority: 60
   ```

4. **Restart app** - Module will auto-load!

## Customizing Styles

All CSS is in `www/css/global.css`. The current theme uses purple gradients.

To change colors:
1. Edit `www/css/global.css`
2. Find color codes (e.g., `#667eea`, `#764ba2`)
3. Replace with your brand colors
4. Save and refresh

## Memory Management

The app includes automatic cleanup:

```r
session$onSessionEnded(function() {
  # Clears all reactive values
  # Forces garbage collection
  # Removes temporary files
})
```

## API Usage

### OpenAI Whisper (Transcription)
- Model: whisper-1
- Max file size: 25MB
- Supported formats: MP3, WAV, M4A, FLAC, OGG
- Languages: Auto-detect or specify

### OpenAI ChatGPT (Text Analysis)
- Model: gpt-4o-mini
- Use: Text summarization and analysis
- Configurable max output length

## Troubleshooting

### Module not loading
- Check `modules/_module_registry.yml` - is it enabled?
- Check file names: `ui.R`, `server.R`, `manifest.yml`
- Check function names match module ID

### Packages not found
- Install missing packages
- Check `manifest.yml` dependencies section

### CSS not applying
- Check `www/css/global.css` exists
- Verify path in `global.R`
- Clear browser cache

## Production Deployment

### Shiny Server
```r
# In /etc/shiny-server/shiny-server.conf
server {
  listen 3838;
  location /audio-app {
    app_dir /path/to/AudioApp;
    log_dir /var/log/shiny-server;
  }
}
```

### shinyapps.io
```r
library(rsconnect)
rsconnect::deployApp(appDir = "/path/to/AudioApp")
```

## License
MIT License - Free to use and modify

## Support
For issues or questions, refer to module README files or contact the development team.

## Version History
- **v2.0.0** - Complete modular rewrite
- **v1.0.0** - Original monolithic version
