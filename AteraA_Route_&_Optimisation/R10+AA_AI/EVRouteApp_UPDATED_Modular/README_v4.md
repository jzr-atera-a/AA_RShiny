# EV/CAV Route Optimizer - v4.0 with CAV Risk Detection

**Modular Shiny app for EV route optimization + CAV risk detection**

## 🆕 What's New in v4.0

Added 5 new CAV (Connected Autonomous Vehicle) modules:
1. **Route Sampler** - Generate waypoints at fixed intervals
2. **Feature Detector** - Detect road hazards from OSM
3. **Street View Capture** - Download Google Street View images
4. **YOLO Detector** - ML-based feature detection
5. **Risk Map** - Interactive risk visualization

## 🚀 Quick Start

```r
install.packages(c("shiny", "shinydashboard", "R6", "yaml", "purrr",
                   "bigrquery", "osmdata", "sf", "dplyr", "dodgr", 
                   "tmaptools", "leaflet", "htmltools", "httr", "DT", "readr"))

shiny::runApp()
```

## 📊 Complete Workflow

1. **BigQuery** → Upload service account key
2. **Road Network** → Download OSM network
3. **Route Optimizer** → Calculate optimal route
4. **Route Sampler** → Generate waypoints (50m intervals)
5. **Feature Detector** → Detect road features
6. **Street View** → Download images (optional)
7. **YOLO Detector** → Upload detection CSV
8. **Risk Map** → View risk visualization

## 🔑 Required API Keys

- **Google Cloud Service Account** (BigQuery) - Free
- **Google Maps API Key** (Street View) - ~$3-14/route

## 💡 Key Features

- ✅ Modular architecture - enable/disable modules in `_module_registry.yml`
- ✅ All 9 modules included (4 original + 5 new CAV modules)
- ✅ Complete UI and server logic for each module
- ✅ Cross-module data flow via `api_manager`
- ✅ Risk classification (CRITICAL/MEDIUM/LOW)
- ✅ Interactive Leaflet maps
- ✅ Data export capabilities

## 📦 What's Included

```
EVRouteApp_UPDATED/
├── modules/
│   ├── bigquery_connection/    ✅ Original
│   ├── road_network/           ✅ Original
│   ├── route_optimizer/        ✅ Original
│   ├── route_map/              ✅ Original
│   ├── cav_route_sampler/      🆕 NEW
│   ├── feature_detector/       🆕 NEW
│   ├── streetview_capture/     🆕 NEW
│   ├── yolo_detector/          🆕 NEW
│   └── risk_map/               🆕 NEW
├── R/
│   ├── utils_cav.R             🆕 CAV utilities
│   └── [other utils]
├── app.R
├── global.R
└── README_v4.md
```

Each module contains:
- `manifest.yml` - Module configuration
- `ui.R` - User interface
- `server.R` - Server logic

## 🎯 Module Priorities

Modules load in priority order:
1. BigQuery (priority 1)
2. Road Network (priority 10)
3. Route Optimizer (priority 20)
4. Route Sampler (priority 25)
5. Feature Detector (priority 26)
6. Street View (priority 27)
7. YOLO Detector (priority 28)
8. Risk Map (priority 29)
9. Route Map (priority 30)

## 💾 Data Flow

```
api_manager object stores:
- network_data (from Road Network)
- cav_waypoints (from Route Sampler)
- cav_features (from Feature Detector)
- cav_images (from Street View)
- cav_detections (from YOLO Detector)
```

All modules access shared data via `api_manager`.

## 🔧 Configuration

Enable/disable modules in `modules/_module_registry.yml`:

```yaml
modules:
  risk_map:
    enabled: true  # Set to false to disable
    priority: 29
    description: "CAV risk visualization"
```

## 📝 Notes

- Street View module requires API key (enter in UI)
- YOLO module accepts CSV upload (Python integration planned for Phase 4)
- Risk Map combines all detection sources
- All modules have error handling and progress indicators

## 🐛 Troubleshooting

**Module not showing?**
- Check `enabled: true` in `_module_registry.yml`
- Restart app

**Street View fails?**
- Verify API key
- Check Google Cloud billing enabled

**No data in Risk Map?**
- Run modules in sequence (1→9)
- Check api_manager has data

## 📄 License

MIT License - Analytics Team 2024-2026

---

**v4.0.0 - Complete CAV Integration**
