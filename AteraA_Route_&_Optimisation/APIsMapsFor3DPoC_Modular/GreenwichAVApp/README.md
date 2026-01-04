# Greenwich AV Project - Data Extraction App

**Version 1.0.0**

A modular R Shiny application for extracting geographic data for VR autonomous vehicle simulation of Greenwich Peninsula (200m × 200m around O2 Arena) for Meta Quest 3 and Jetson Nano.

## 🎯 Project Overview

This application provides a user-friendly interface to download and prepare geographic data from multiple sources for import into Unity 3D environment:

- **Buildings** (footprints + heights)
- **Road network** (centerlines, types, lanes)
- **Terrain/elevation** (LIDAR preferred)
- **Satellite imagery** (for ground textures)
- **Points of interest**

## 📁 Project Structure

```
GreenwichAVApp/
├── app.R                          # Application entry point
├── global.R                       # Global configuration
├── R/
│   ├── module_loader.R           # R6 module loader class
│   ├── utils_common.R            # Common utility functions
│   └── utils_geo.R               # Geographic utility functions
├── modules/
│   ├── _module_registry.yml      # Module configuration
│   ├── osm_data/                 # OpenStreetMap module
│   ├── arcgis_data/              # ArcGIS Living Atlas module
│   ├── os_terrain/               # OS Terrain module
│   ├── lidar_data/               # LIDAR data module
│   ├── satellite_imagery/        # Satellite imagery module
│   └── preview_validation/       # Preview & Export module
└── www/
    └── css/
        └── global.css            # Application styling
```

## 🚀 Quick Start

### Prerequisites

```r
# Required R packages
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr", 
  "magrittr", "dplyr", "sf", "osmdata", "leaflet", 
  "htmltools", "httr", "jsonlite", "raster", "tmaptools"
))
```

### Running the App

1. **Clone or extract** the application folder

2. **Open R/RStudio** and set working directory:
   ```r
   setwd("path/to/GreenwichAVApp")
   ```

3. **Run the application**:
   ```r
   shiny::runApp()
   ```

4. **Access** the app in your browser (usually opens automatically)

## 📊 Data Sources & Modules

### 1. OpenStreetMap (OSM)
- **Data:** Buildings, roads, points of interest
- **Format:** GeoJSON
- **API:** Overpass API (free, no key required)
- **Coverage:** Global

### 2. ArcGIS Living Atlas
- **Data:** Buildings (3D), imagery, elevation
- **Format:** GeoJSON, SLPK, GeoTIFF
- **API:** ArcGIS REST API (requires free API key)
- **Get Key:** developers.arcgis.com

### 3. OS Terrain
- **Data:** UK Ordnance Survey terrain data
- **Format:** ASCII Grid, GeoTIFF
- **Access:** OS OpenData (free download)
- **Website:** ordnancesurvey.co.uk/opendatadownload

### 4. LIDAR Data
- **Data:** High-resolution elevation (1-2m)
- **Format:** GeoTIFF
- **Source:** Environment Agency
- **Website:** environment.data.gov.uk/survey

### 5. Satellite Imagery
- **Data:** High-resolution aerial imagery
- **Format:** PNG, GeoTIFF
- **Sources:** Google Maps, Bing Maps, Mapbox
- **Requires:** API key (free tier available)

### 6. Preview & Export
- **Features:** 
  - Interactive map preview
  - Data validation
  - Metadata generation
  - ZIP bundle export
  - Unity import instructions

## 🎮 Default Location

**Greenwich Peninsula, London (O2 Arena)**
- **Coordinates:** 51.5025°N to 51.5035°N, 0.0020°E to 0.0035°E
- **Size:** 200m × 200m
- **Coordinate System:** WGS84 (EPSG:4326)

You can customize the location by entering:
- Location name (e.g., "Cambridge, England")
- Bounding box coordinates (lat_min, lon_min, lat_max, lon_max)

## 🔧 Modular Architecture

### Module Structure

Each module is self-contained with:
```
module_name/
├── manifest.yml    # Module metadata & dependencies
├── ui.R           # User interface
└── server.R       # Server logic
```

### Enable/Disable Modules

Edit `modules/_module_registry.yml`:
```yaml
modules:
  osm_data:
    enabled: true    # Change to false to disable
    priority: 10
```

### Creating New Modules

1. Create a new folder in `modules/`
2. Add `manifest.yml`, `ui.R`, and `server.R`
3. Register in `_module_registry.yml`
4. Restart the app

## 📦 Export Format

The application creates a ZIP bundle containing:

```
Greenwich_Data_Export_YYYYMMDD_HHMMSS/
├── metadata.json          # Export metadata
├── buildings.geojson      # Building footprints
├── roads.geojson         # Road network
├── poi.geojson           # Points of interest
└── README.txt            # Import instructions
```

## 🎯 Unity 3D Import

### Recommended Unity Plugins
- **Mapbox SDK for Unity** - GeoJSON import
- **GIS Tools** - Coordinate conversion
- **Terrain Toolkit** - Heightmap import

### Import Steps
1. Extract the downloaded ZIP file
2. Import GeoJSON files using Mapbox SDK or similar
3. Load terrain/LIDAR as heightmap
4. Apply satellite imagery as ground texture
5. Convert building footprints to 3D meshes

## ⚙️ Configuration

### API Keys (Optional but Recommended)

Store API keys in module UI or environment variables:

```r
# For production deployment
Sys.setenv(
  GOOGLE_MAPS_API_KEY = "your_key_here",
  ARCGIS_API_KEY = "your_key_here"
)
```

### Module Priority

Modules load in priority order (set in `_module_registry.yml`):
- Lower numbers = higher priority
- Default: 10, 20, 30, etc.

## 🐛 Troubleshooting

### "Location not found"
- Check spelling of location name
- Try using bounding box coordinates instead
- Ensure location is covered by OpenStreetMap

### "No data returned"
- Verify bounding box coordinates are correct
- Check internet connection
- Ensure area is not too large (keep under 500m × 500m)

### "API key required"
- Some services require free API keys
- Follow links in the UI to get keys
- OSM data works without any keys

### Module not loading
- Check `modules/_module_registry.yml` for `enabled: true`
- Verify module manifest.yml is valid YAML
- Check R console for error messages

## 📝 License

This application is provided for educational and research purposes.

Data sources have their own licenses:
- **OpenStreetMap:** ODbL (Open Database License)
- **ArcGIS:** Terms of use apply
- **OS Data:** Open Government Licence
- **Environment Agency:** Open Government Licence

## 🤝 Contributing

To add new data sources or features:
1. Create a new module in `modules/`
2. Follow existing module structure
3. Update `_module_registry.yml`
4. Test thoroughly
5. Document in README

## 📧 Support

For issues or questions:
- Check the troubleshooting section
- Review module-specific README files
- Check R console for error messages

## 🎓 Credits

**Developed for:** Greenwich AV VR Simulation Project
**Platform:** Meta Quest 3 / Jetson Nano
**Engine:** Unity 3D
**Version:** 1.0.0
**Date:** 2025

---

**Success Criteria:**
- ✓ All 5 data layers downloadable
- ✓ Preview map shows data coverage
- ✓ Handles API timeouts gracefully
- ✓ Exports Unity-ready files
- ✓ Total time from launch to download: <5 minutes
