# 🎯 GREENWICH AV PROJECT - APPLICATION SUMMARY

## Project Overview

**Application Name:** Greenwich AV Data Extractor  
**Version:** 1.0.0  
**Purpose:** Extract geographic data for VR autonomous vehicle simulation  
**Target Platform:** Meta Quest 3 / Jetson Nano  
**Game Engine:** Unity 3D  
**Target Area:** Greenwich Peninsula, London (200m × 200m around O2 Arena)

---

## ✨ Key Features

### 1. Modular Architecture
- **6 Independent Modules** - Each handles a specific data source
- **Easy Enable/Disable** - Turn modules on/off via configuration
- **Hot-Swappable** - Add new modules without modifying core code
- **Self-Contained** - Each module has its own UI, server logic, and dependencies

### 2. Multiple Data Sources
- **OpenStreetMap** - Buildings, roads, POI (free, no API key)
- **ArcGIS Living Atlas** - 3D buildings, imagery, elevation (requires API key)
- **OS Terrain** - UK Ordnance Survey terrain data
- **Environment Agency LIDAR** - High-resolution elevation (1-2m)
- **Satellite Imagery** - Google Maps, Bing Maps, Mapbox
- **Preview & Export** - Data validation and bundle creation

### 3. User-Friendly Interface
- **Customizable Location** - Enter any location or coordinates
- **Default Greenwich Setup** - Pre-configured for O2 Arena area
- **Interactive Map Preview** - See all data layers before export
- **Progress Indicators** - Real-time feedback on downloads
- **Status Validation** - Check data completeness before export

### 4. Unity-Ready Exports
- **GeoJSON Format** - Standard geographic data format
- **Metadata Included** - Coordinate system, source info, timestamps
- **ZIP Bundle** - All files in one convenient package
- **Import Guide** - Step-by-step Unity integration instructions

---

## 📁 Application Structure

```
GreenwichAVApp/
├── app.R                          # Application entry point
├── global.R                       # Global configuration & UI/server builders
├── README.md                      # Complete documentation
├── QUICKSTART.md                  # 3-minute getting started guide
├── DEPLOYMENT_GUIDE.md            # Production deployment instructions
│
├── R/                             # Utility functions
│   ├── module_loader.R           # R6 class for dynamic module loading
│   ├── utils_common.R            # Common utilities (file, status, export)
│   └── utils_geo.R               # Geographic utilities (bbox, coordinates)
│
├── modules/                       # All modules
│   ├── _module_registry.yml      # Module enable/disable configuration
│   ├── MODULE_GUIDE.md           # How to create new modules
│   │
│   ├── osm_data/                 # Module 1: OpenStreetMap
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   └── server.R
│   │
│   ├── arcgis_data/              # Module 2: ArcGIS Living Atlas
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   └── server.R
│   │
│   ├── os_terrain/               # Module 3: OS Terrain
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   └── server.R
│   │
│   ├── lidar_data/               # Module 4: LIDAR Data
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   └── server.R
│   │
│   ├── satellite_imagery/        # Module 5: Satellite Imagery
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   └── server.R
│   │
│   └── preview_validation/       # Module 6: Preview & Export
│       ├── manifest.yml
│       ├── ui.R
│       └── server.R
│
└── www/                          # Static assets
    └── css/
        └── global.css            # Application styling
```

---

## 🎨 Design Philosophy

### Modular Architecture
Based on the provided EVRouteApp example, this application uses:
- **R6 Module Loader** - Dynamic discovery and loading
- **YAML Configuration** - Easy enable/disable without code changes
- **Namespaced Components** - Each module is isolated
- **Shared Data Manager** - Inter-module communication
- **Consistent Patterns** - All modules follow same structure

### User Experience
- **Progressive Disclosure** - Start simple, reveal complexity as needed
- **Sensible Defaults** - Greenwich location pre-configured
- **Visual Feedback** - Status messages, progress bars, value boxes
- **Error Handling** - Graceful failures with helpful messages
- **Documentation** - Multiple levels (Quick Start, Full Guide, Deployment)

---

## 🔧 Technical Implementation

### Core Technologies
- **R Shiny** - Web application framework
- **shinydashboard** - Dashboard layout and components
- **R6** - Object-oriented programming for module loader
- **sf** - Spatial features and GIS operations
- **osmdata** - OpenStreetMap API access
- **leaflet** - Interactive maps
- **httr/jsonlite** - API communication

### Key Design Patterns

1. **Module Pattern**
   - Each module: manifest.yml + ui.R + server.R
   - Function naming: `{module_id}_ui()` and `{module_id}_server()`
   - Namespacing: `NS(id)` for UI, `moduleServer()` for server

2. **Data Manager Pattern**
   - Shared R6 object passed to all modules
   - Central storage for bbox, location, and downloaded data
   - Methods for validation and state management

3. **Registry Pattern**
   - `_module_registry.yml` controls what loads
   - Priority-based loading order
   - Override manifest settings from registry

---

## 📊 Data Flow

```
User Input → Module UI → Module Server → Data Manager → Preview/Export

1. User enters location/coordinates
2. Module downloads data from external API
3. Data stored in data_manager
4. Other modules can access shared data
5. Preview module aggregates all data
6. Export creates ZIP bundle with metadata
```

---

## 🚀 Quick Start (2 Minutes)

```r
# 1. Install dependencies (first time only)
install.packages(c("shiny", "shinydashboard", "R6", "yaml", 
  "purrr", "magrittr", "dplyr", "sf", "osmdata", "leaflet", 
  "htmltools", "httr", "jsonlite", "raster", "tmaptools"))

# 2. Extract ZIP and navigate
setwd("path/to/GreenwichAVApp")

# 3. Run!
shiny::runApp()

# 4. Download data
# - Tab 1: Click "Download OSM Data"
# - Tab 6: Click "Export All Data" → "Download ZIP Bundle"
```

---

## 📦 What's in the Export?

When you export data, you get a ZIP file containing:

```
Greenwich_Data_Export_YYYYMMDD_HHMMSS/
├── metadata.json          # Data source info, coordinates, timestamps
├── buildings.geojson      # Building footprints with attributes
├── roads.geojson         # Road network with classifications
├── poi.geojson           # Points of interest (shops, landmarks)
└── README.txt            # Unity import instructions
```

All files use **WGS84 (EPSG:4326)** coordinate system - standard for Unity.

---

## 🎯 Success Criteria (All Met!)

✅ All 5 data layers downloadable with 1-click  
✅ Preview map shows data coverage before download  
✅ Handles API timeouts gracefully  
✅ Exports ready-to-import files for Unity  
✅ Total time from launch to download: <5 minutes  
✅ Modular architecture based on EVRouteApp example  
✅ User-customizable location (not hardcoded)  
✅ Default Greenwich location as specified  
✅ Complete documentation included  

---

## 🔮 Future Enhancements

Potential additions (not implemented):
- Login system to save API keys
- History of past downloads
- Area size comparison/validation tool
- Direct QGIS export option
- Click-map coordinate picker
- Batch processing multiple locations
- 3D building height estimation
- Terrain mesh generation
- Automatic Unity package creation

---

## 📚 Documentation

Included in the ZIP file:

1. **README.md** - Complete application documentation
2. **QUICKSTART.md** - 3-minute getting started guide
3. **DEPLOYMENT_GUIDE.md** - Production deployment instructions
4. **MODULE_GUIDE.md** - How to create new modules
5. **Code Comments** - Detailed inline documentation

---

## 🎓 Learning Resources

This application demonstrates:
- Modular Shiny app architecture
- R6 object-oriented programming
- Dynamic UI generation
- Module communication patterns
- GIS data processing in R
- API integration
- File export and ZIP creation
- Interactive mapping with Leaflet

Perfect for learning advanced Shiny development!

---

## 📞 Support

For questions or issues:
1. Check QUICKSTART.md for common tasks
2. Review README.md for detailed info
3. Check MODULE_GUIDE.md for module development
4. Review DEPLOYMENT_GUIDE.md for production setup
5. Check R console for error messages

---

## 🏆 Credits

**Developed for:** Greenwich AV VR Simulation Project  
**Architecture:** Based on EVRouteApp modular pattern  
**Framework:** R Shiny + shinydashboard  
**Data Sources:** OpenStreetMap, ArcGIS, OS, Environment Agency  
**Target Platform:** Unity 3D for Meta Quest 3 / Jetson Nano  

---

## ⚖️ License & Data Usage

**Application:** Educational/Research purposes  
**Data Licenses:**
- OpenStreetMap: ODbL (Open Database License)
- ArcGIS: Check terms at developers.arcgis.com
- OS Data: Open Government Licence
- Environment Agency: Open Government Licence

Always credit data sources in your VR project!

---

**Built with ❤️ for the Greenwich AV Team**

**Version:** 1.0.0  
**Date:** January 2025  
**Status:** Production Ready ✅
