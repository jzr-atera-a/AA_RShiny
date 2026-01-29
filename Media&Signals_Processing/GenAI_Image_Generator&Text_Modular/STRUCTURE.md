# Application Structure - DALL-E Image Generator

## 📁 Directory Structure

```
DALLE_Image_Generator/
│
├── app.R                          # Main entry point
├── global.R                       # Global configuration & UI/Server factories
├── install_packages.R             # Package installation script
├── verify_system.R                # System verification script
├── README.md                      # Complete documentation
├── QUICKSTART.md                  # Quick start guide
├── STRUCTURE.md                   # This file
│
├── R/                             # Utility files
│   ├── module_loader.R           # R6 ModuleLoader class
│   ├── utils_api.R               # R6 APIManager class with DALL-E support
│   └── utils_common.R            # Common utility functions
│
├── modules/                       # Application modules
│   ├── _module_registry.yml      # Module configuration
│   │
│   ├── dalle_settings/           # DALL-E API Settings module
│   │   ├── ui.R                  # UI definition
│   │   └── server.R              # Server logic
│   │
│   └── image_generation/         # Image Generation module
│       ├── ui.R                  # UI definition
│       └── server.R              # Server logic
│
└── www/                          # Static web resources
    └── css/
        └── global.css            # Application styling

```

## 🏗️ Architecture Overview

### 1. Main Entry Point (app.R)
- Loads global configuration
- Initializes ModuleLoader
- Loads and sources all modules
- Initializes APIManager
- Launches the Shiny application

### 2. Global Configuration (global.R)
- Loads core packages
- Sources utility files
- Defines `create_ui()` factory function
- Defines `create_server()` factory function
- Sets up application-wide settings

### 3. Module System

#### Module Registry (modules/_module_registry.yml)
```yaml
modules:
  - id: dalle_settings
    name: "DALL-E API Settings"
    enabled: true
    packages: [httr, jsonlite]
    menu:
      label: "DALL-E API Settings"
      tabname: "dalle_settings"
      icon: "cog"
```

#### Module Structure
Each module has:
- **ui.R**: UI function `{module_id}_ui()`
- **server.R**: Server function `{module_id}_server()`

### 4. R6 Classes

#### ModuleLoader (R/module_loader.R)
```r
ModuleLoader$new()
  ├── initialize()           # Load module registry
  ├── get_enabled_modules()  # Get enabled modules
  ├── load_packages()        # Load module packages
  ├── source_modules()       # Source module files
  └── print()               # Print module info
```

#### APIManager (R/utils_api.R)
```r
APIManager$new()
  ├── initialize()                          # Setup API manager
  ├── set_dalle_key()                       # Set API key
  ├── set_dalle_config()                    # Configure model/quality/style
  ├── test_connection()                     # Test API connection
  ├── generate_image()                      # Generate image with DALL-E
  └── save_image_with_format()              # Save with format conversion
```

### 5. Utility Functions (R/utils_common.R)

```r
get_volume_roots()           # Get file system roots
cm_to_inches()              # Convert cm to inches
inches_to_cm()              # Convert inches to cm
calculate_width()           # Calculate width from height & ratio
get_dalle_size()            # Map aspect ratio to DALL-E size
enhance_prompt()            # Enhance prompt based on style
```

## 🔄 Application Flow

### Startup Sequence:
1. **app.R** runs
2. **global.R** sources utility files
3. **ModuleLoader** reads module registry
4. **ModuleLoader** loads required packages
5. **ModuleLoader** sources module UI and server files
6. **APIManager** initialized
7. **create_ui()** builds dashboard from modules
8. **create_server()** initializes module servers
9. Application launches

### User Interaction Flow:

#### Configuration Flow:
```
User → DALL-E Settings Tab
  → Enter API Key
  → Select Model (DALL-E 2/3)
  → Configure Quality/Style
  → Click "Save Settings"
  → APIManager stores configuration
  → Click "Test Connection"
  → APIManager validates key
```

#### Image Generation Flow:
```
User → Image Generation Tab
  → Enter description
  → Select style (Art/Photo)
  → Select aspect ratio
  → Set height dimension
  → Auto-calculate width
  → Click "Generate Image"
  → enhance_prompt() adds style elements
  → get_dalle_size() determines image size
  → APIManager$generate_image() calls OpenAI
  → Image returned as base64
  → Displayed in preview box
  → Revised prompt shown
```

#### Download Flow:
```
User → Generated Image displayed
  → Select download format
  → Enter filename
  → Choose download folder
  → Click "Download Image"
  → APIManager$save_image_with_format()
  → magick package converts format
  → File saved at 300 DPI
  → Success notification
```

## 🎨 CSS Architecture

### Color Scheme:
- **Primary Gradient**: #667eea → #764ba2 (Purple)
- **Success Gradient**: #11998e → #38ef7d (Green)
- **Sidebar**: #2c3e50 → #34495e (Dark Blue)
- **Background**: #f5f7fa → #c3cfe2 (Light Blue-Gray)

### Custom Classes:
- `.info-box` - Information display
- `.reference-box` - Reference documentation
- `.image-preview-box` - Image display container
- `.dimension-display` - Dimension calculations
- `.prompt-box` - Prompt display

## 🔐 Security Considerations

### API Key Handling:
- Stored in memory only (not in files)
- Uses `passwordInput()` for secure entry
- Trimmed to prevent whitespace issues
- Never logged or displayed

### File Operations:
- Uses `shinyFiles` for secure folder selection
- Validates file paths
- Checks for file existence before overwrite
- Proper error handling

## 📊 Data Flow

### Reactive Values:
```r
values <- reactiveValues(
  generated_image = NULL,      # Generated image data
  image_path = NULL,           # Temporary file path
  revised_prompt = NULL,       # OpenAI revised prompt
  download_dir = NULL          # Selected download folder
)
```

### State Management:
- API configuration stored in APIManager
- Generated images tracked in data frame
- Reactive values for UI state
- Session-based storage

## 🧩 Module Communication

### Inter-Module Data Sharing:
- **APIManager** is shared across all modules
- Modules access via: `api_manager$dalle_api_key`
- Configuration persists within session
- No direct module-to-module communication

### Module Independence:
- Each module is self-contained
- UI and server functions namespaced
- Can be enabled/disabled independently
- No hard dependencies between modules

## 🚀 Extension Points

### Adding New Modules:
1. Create folder in `modules/`
2. Add `ui.R` and `server.R`
3. Register in `_module_registry.yml`
4. Define required packages
5. Create menu configuration

### Adding New Features:
1. Add methods to APIManager
2. Create utility functions
3. Update module UI/server
4. Add CSS styling if needed

### Customizing Appearance:
1. Modify `www/css/global.css`
2. Update color gradients in `global.R`
3. Add custom classes
4. Adjust box styles

## 📈 Performance Considerations

### Optimization Strategies:
- Lazy loading of modules
- On-demand package loading
- Base64 encoding for image transfer
- Efficient file operations
- Session cleanup on exit

### Memory Management:
- Temporary files cleaned up
- `gc()` called on session end
- Large objects stored reactively
- Efficient image processing

## 🔧 Maintenance

### Regular Tasks:
- Update package versions
- Check OpenAI API changes
- Update model options
- Review security practices
- Test on different platforms

### Monitoring:
- Console logging enabled
- Error handling throughout
- User notifications for failures
- Detailed error messages

---

This modular architecture allows for:
✅ Easy maintenance and updates
✅ Independent module development
✅ Scalable design
✅ Clear separation of concerns
✅ Reusable components
