# CAV Route Optimizer - Full Python Integration

## Overview

Complete CAV (Connected Autonomous Vehicle) risk detection system with Python backend integration.

**100% functionality parity with Jupyter notebook!**

## File Structure

```
CAV_RouteOptimizer_FINAL/
├── modules/                        Each module = 1 file
│   ├── cav_route_sampler.R        Google Maps routing
│   ├── feature_detector.R         OSM feature detection
│   ├── streetview_capture.R       Image download
│   ├── yolo_detector.R            ML inference
│   ├── risk_map.R                 Visualization
│   └── _module_registry.yml       Module configuration
│
├── python_backend/
│   ├── google_maps_routing.py     Route extraction
│   ├── streetview_downloader.py   Batch image download
│   ├── yolo_inference.py          YOLO model inference
│   └── requirements.txt           Python dependencies
│
├── R/
│   ├── module_loader.R            Module system
│   ├── utils_python.R             Python bridge
│   ├── utils_cav.R                CAV utilities
│   └── utils_common.R             Common functions
│
├── app.R                          Entry point
├── global.R                       Initialization
└── www/css/global.css             Styles
```

## Quick Start

### 1. Install R Packages (5 min)

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml",
  "reticulate", "jsonlite", "dplyr", "DT", "leaflet"
))
```

### 2. Setup Python (5 min)

```bash
cd CAV_RouteOptimizer_FINAL
python3 -m venv python_backend/venv
source python_backend/venv/bin/activate
pip install -r python_backend/requirements.txt
```

### 3. Download YOLO Model (2 min)

```python
from ultralytics import YOLO
model = YOLO('yolov8n.pt')
# Move to models/ directory
```

### 4. Get Google Maps API Key (3 min)

1. https://console.cloud.google.com
2. Enable: Directions API + Street View Static API
3. Create API key
4. Enable billing

### 5. Run App

```r
shiny::runApp()
```

## Workflow

1. **Route Sampler** → Enter origin/dest, API key → Get route from Google Maps
2. **Feature Detector** → Detect road features from OSM
3. **Street View** → Download images via Python (sample every 5th = lower cost)
4. **YOLO Detector** → Run ML model on images
5. **Risk Map** → See interactive visualization

## Key Features

✅ Single file per module (not ui.R + server.R)
✅ Python backend for ML/API operations
✅ Seamless R-Python bridge via reticulate
✅ Same algorithms as Jupyter notebook
✅ Google Maps routing (not OSM)
✅ Real YOLO inference (not CSV upload)
✅ Modular architecture

## Cost Per Route

- 20km: ~$0.57
- 100km: ~$2.81 (with sample_rate=5)
- 500km: ~$14.01

## Module Structure

Each module is ONE .R file with:
- UI function (e.g., `cav_route_sampler_ui`)
- Server function (e.g., `cav_route_sampler_server`)
- Everything self-contained

Example:
```r
# modules/cav_route_sampler.R

cav_route_sampler_ui <- function(id) {
  # UI code here
}

cav_route_sampler_server <- function(id, api_manager) {
  # Server code here
}
```

## Python Integration

R calls Python via `reticulate`:

```r
# R code
result <- get_route_python(origin, dest, api_key, spacing)

# Calls Python:
# python3 google_maps_routing.py "London" "Cambridge" "KEY" "50"

# Python outputs JSON, R parses it
```

## Troubleshooting

**Python not found:**
```r
library(reticulate)
use_virtualenv("python_backend/venv")
py_config()
```

**Module not found:**
```bash
source python_backend/venv/bin/activate
pip install -r python_backend/requirements.txt
```

**YOLO model missing:**
```bash
python3 -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"
mkdir models
mv yolov8n.pt models/
```

## Support

See `PYTHON_INTEGRATION_GUIDE.md` for detailed documentation.

---

**v5.0.0 - Single-File Modules with Full Python Integration**
