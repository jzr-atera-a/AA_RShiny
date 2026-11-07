# SETUP GUIDE - CAV Route Optimizer

## ⚡ 15-Minute Setup

### Step 1: R Packages
```r
install.packages(c("shiny", "shinydashboard", "R6", "yaml", "reticulate",
                   "jsonlite", "dplyr", "DT", "leaflet", "httr"))
```

### Step 2: Python Environment
```bash
cd CAV_RouteOptimizer_FINAL
python3 -m venv python_backend/venv
source python_backend/venv/bin/activate  # Mac/Linux
# OR
python_backend\venv\Scripts\activate     # Windows

pip install -r python_backend/requirements.txt
```

### Step 3: YOLO Model
```python
from ultralytics import YOLO
YOLO('yolov8n.pt')  # Downloads automatically
# Move yolov8n.pt to models/ directory
```

### Step 4: Google API Key
1. Go to https://console.cloud.google.com
2. Create/select project
3. Enable APIs:
   - Directions API
   - Street View Static API
4. Create API key
5. Enable billing (has free tier)

### Step 5: Run App
```r
shiny::runApp()
```

## ✅ Test It

In the app:
1. Go to "Route Sampler" tab
2. Enter API key
3. Origin: "London, UK"
4. Destination: "Cambridge, UK"
5. Click "Get Route"
6. Should see ~2000 waypoints!

## 📂 What You Get

- ✅ Google Maps routing (like Jupyter)
- ✅ Automated waypoint generation
- ✅ Batch Street View download
- ✅ Real YOLO inference
- ✅ Interactive risk visualization
- ✅ Single file per module (clean structure)

## 💰 Cost Control

Adjust sample_rate in Street View tab:
- sample_rate=1: All waypoints (expensive)
- sample_rate=5: Every 5th waypoint (recommended, ~$3/100km)
- sample_rate=10: Every 10th waypoint (cheapest, ~$1.40/100km)

## 🐛 Common Issues

### "Python not found"
```r
library(reticulate)
use_virtualenv("python_backend/venv")
```

### "Module not installed"
```bash
source python_backend/venv/bin/activate
pip install googlemaps ultralytics torch
```

### "YOLO model not found"
Check models/yolov8n.pt exists. If not, download it.

---

**READY TO USE - Just follow steps above!**
