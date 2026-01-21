# EV Route Optimizer - Modular Architecture v3.0

**Production-ready modular Shiny application for EV/AV route optimization with charging station integration**

## 🚗⚡ Features

- **BigQuery Integration** - Load EV charging point data from Google Cloud
- **Road Network Download** - OpenStreetMap integration via osmdata
- **Route Optimization** - Calculate shortest paths through charging stations
- **Interactive Mapping** - Leaflet-based visualization

## 📁 Project Structure

```
EVRouteApp/
├── app.R                  # Entry point (~100 lines)
├── global.R               # UI/Server factories
├── R/
│   ├── module_loader.R    # R6 ModuleLoader class
│   ├── utils_bigquery.R   # R6 BigQueryManager
│   └── utils_common.R     # Utilities
├── modules/
│   ├── _module_registry.yml     # ⭐ CONTROL CENTER
│   ├── bigquery_connection/     # BigQuery auth
│   ├── road_network/            # OSM network download
│   ├── route_optimizer/         # Route calculation
│   └── route_map/               # Map visualization
└── www/css/global.css     # Centralized styling

```

## 🚀 Quick Start

### 1. Install Dependencies

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "bigrquery", "osmdata", "sf", "dplyr", "dodgr", 
  "tmaptools", "leaflet", "htmltools"
))
```

### 2. Run Application

```r
setwd("path/to/EVRouteApp")
shiny::runApp()
```

## ⚙️ BigQuery Configuration

**IMPORTANT:** This app uses the following BigQuery configuration:

- **Project ID:** `atera-2`
- **Dataset ID:** `EVs_Infrastructure`
- **Table ID:** `Charge_Points_UK_EVs`

These values are **pre-configured** in the BigQuery Connection module.

## 🎯 Usage Workflow

1. **BigQuery Setup Tab**
   - Upload service account JSON key
   - Verify project/dataset/table IDs
   - Click "Test Connection"

2. **Road Network Tab**
   - Enter location (e.g., "Cambridge, England")
   - Click "Download Road Network"
   - Wait for processing

3. **Route Optimizer Tab**
   - Select origin and destination
   - Choose number of charging points
   - Click "Calculate Optimal Route"

4. **Route Map Tab**
   - View interactive map
   - Explore route and charging points

## 🔧 Enable/Disable Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  road_network:
    enabled: false  # ← Change this line
```

Restart app. Disabled modules:
- Don't load dependencies
- Don't appear in sidebar
- Have zero performance impact

## 🎨 Customization

### Styling
All CSS in `www/css/global.css` - corporate teal/cyan theme

### Adding Modules
1. Create folder in `modules/`
2. Add `manifest.yml`, `ui.R`, `server.R`
3. Register in `_module_registry.yml`

## 📦 Dependencies

### Core (Always Required)
- shiny, shinydashboard, R6, yaml, purrr

### Module-Specific (Conditional)
- bigrquery, sf, dplyr
- osmdata, tmaptools, dodgr
- leaflet, htmltools

## 🏗️ Architecture

- **Modular Design:** Each feature is self-contained
- **Namespace Isolation:** Zero ID conflicts via NS()
- **Conditional Loading:** Disabled modules not loaded
- **R6 Classes:** ModuleLoader, BigQueryManager
- **Reactive Triggers:** Cross-module state updates

## 📝 Documentation

- `ARCHITECTURE.md` - Detailed technical docs
- `modules/*/README.md` - Module-specific documentation

## ✅ Testing Checklist

- [ ] App starts without errors
- [ ] Sidebar shows all menu items
- [ ] Main body shows tab content (not empty!)
- [ ] BigQuery authentication works
- [ ] Road network downloads successfully
- [ ] Route calculation completes
- [ ] Map displays correctly

## 🐛 Troubleshooting

### Empty Main Body
Check `global.R` - tabs must be built in FOR LOOP

### BigQuery Connection Fails
- Verify JSON key file is valid
- Check project/dataset/table IDs
- Ensure service account has permissions

### Network Download Fails
- Try different location formats
- Check internet connection
- Use major cities

## 📄 License

MIT License

## 👥 Author

Analytics Team - 2024

---

**Built with Shiny Modular Architecture v3.0**
