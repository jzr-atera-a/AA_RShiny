# WP5 Omniverse AR Visualization - R Shiny App
**Modular Architecture - 4 Tabs, 4 Single-File Modules**

---

## ✅ COMPLETE STRUCTURE

```
WP5_OmniverseAR_App/
├── app.R                           # Application entry point
├── global.R                        # Global configuration
├── modules/
│   ├── _module_registry.yml        # Module configuration
│   ├── omniverse_connection.R      # Tab 1: Isaac Sim connection (UI + Server in ONE file)
│   ├── scenario_manager.R          # Tab 2: Browse scenarios (UI + Server in ONE file)
│   ├── route_visualization.R       # Tab 3: Leaflet maps (UI + Server in ONE file)
│   └── quest3_ar_viewer.R          # Tab 4: Quest 3 AR setup (UI + Server in ONE file)
├── R/
│   ├── module_loader.R             # **COPY FROM EVRouteApp**
│   └── utils_omniverse.R           # Omniverse utilities
└── www/
    └── css/
        └── global.css              # Corporate teal theme
```

---

## 🎯 4 MODULES (Each is ONE .R file containing both UI and Server)

### **Module 1: omniverse_connection.R**
- **Tab Name:** "Omniverse"
- **Icon:** cube
- **Function:** Load Isaac Sim JSON scenarios (file/live/demo modes)
- **UI:** File upload, path configuration, connection testing
- **Server:** JSON parsing, scenario validation, data storage

### **Module 2: scenario_manager.R**
- **Tab Name:** "Scenarios"
- **Icon:** road
- **Function:** Browse and select scenarios
- **UI:** DataTable with scenarios, detail panel, charts
- **Server:** Table rendering, Plotly trajectory/quality plots

### **Module 3: route_visualization.R**
- **Tab Name:** "Route Preview"
- **Icon:** map
- **Function:** Interactive Leaflet maps with route quality
- **UI:** Map controls, base map selection, toggles
- **Server:** Leaflet rendering with color-coded routes (Green/Amber/Red)

### **Module 4: quest3_ar_viewer.R**
- **Tab Name:** "Quest 3 AR"
- **Icon:** vr-cardboard
- **Function:** Generate QR code and Plumber API configuration
- **UI:** Server IP config, QR code display, API controls
- **Server:** Plumber API file generation, endpoint testing

---

## 🚀 INSTALLATION STEPS

### **Step 1: Copy Missing File**

You need to copy ONE file from your EVRouteApp:

```r
# Copy module_loader.R from EVRouteApp to WP5 app
file.copy(
  from = "path/to/EVRouteApp_WORKING/R/module_loader.R",
  to = "path/to/WP5_OmniverseAR_App/R/module_loader.R"
)
```

This file contains the `ModuleLoader` R6 class that automatically loads modules.

---

### **Step 2: Install Required Packages**

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "R6",
  "yaml",
  "purrr",
  "magrittr",
  "dplyr",
  "leaflet",
  "DT",
  "plotly",
  "jsonlite",
  "httr",
  "plumber",
  "qrcode"  # Optional: for QR code generation
))
```

---

### **Step 3: Run the App**

```r
setwd("path/to/WP5_OmniverseAR_App")
shiny::runApp()
```

---

## 📊 USAGE WORKFLOW

### **1. Load Omniverse Data (Tab 1: Omniverse)**

**Option A: Upload JSON File**
1. Select "Local File" as data source
2. Click "Browse" and select `omniverse_av_scenarios.json`
3. Click "Test Connection"
4. Click "Load Scenarios"

**Option B: Live Isaac Sim Connection**
1. Select "Isaac Sim Live"
2. Enter Isaac Sim path: `C:/Users/USERNAME/AppData/Local/ov/pkg/isaac-sim-5.1.0`
3. Enter shared folder: `C:/shared/omniverse_outputs`
4. Click "Load Scenarios"

**Option C: Demo Data**
1. Select "Demo Data"
2. Click "Load Scenarios"
3. Instantly loads 2 sample scenarios (A10 Amber, M11 Green)

---

### **2. Browse Scenarios (Tab 2: Scenarios)**

- View table of all loaded scenarios
- Click a row to select scenario
- See trajectory plot (lat/lon with speed colors)
- See quality score bar chart (Green/Amber/Red)
- View incident summary

---

### **3. Preview Routes (Tab 3: Route Preview)**

- Interactive Leaflet map shows selected scenario
- **Green markers** = Quality score 8-10 (AV Ready)
- **Orange markers** = Quality score 5-7 (Caution)
- **Red markers** = Quality score 1-4 (Manual Override)
- **Red incident markers** = Safety incidents
- Toggle trajectory line, quality scores, incidents
- Switch base maps (OSM, CartoDB, Satellite)

---

### **4. Quest 3 AR Setup (Tab 4: Quest 3 AR)**

**Configure API:**
1. Enter your PC's local IP (e.g., 192.168.100.14)
2. Set API port (default: 8001)
3. Select scenario to display
4. Click "Start Plumber API"

**Start API Server:**
The app generates a Plumber API file. To start it:

```r
# Open a NEW R console (separate from Shiny app)
library(plumber)
pr <- plumb('path/shown/in/notification')
pr$run(host='0.0.0.0', port=8001)
```

**Connect Quest 3:**
1. Put on Quest 3
2. Open browser
3. Navigate to URL shown (or scan QR code if qrcode package installed)
4. Accept HTTPS certificate
5. Click "Enter AR"
6. Floor map appears with colored routes!

---

## 🔌 API ENDPOINTS (for Quest 3)

When Plumber API is running:

### **GET /omniverse/scenarios**
Returns list of all scenarios
```json
{
  "scenarios": [
    {
      "scenario_id": "a10_amber_readiness",
      "route": "A10 Cambridge to London",
      "av_readiness": "AMBER",
      "quality_score": 6.2
    }
  ]
}
```

### **GET /omniverse/trajectories/{id}**
Returns full scenario details with trajectories and incidents
```json
{
  "scenario_id": "a10_amber_readiness",
  "trajectories": [...],
  "incidents": [...]
}
```

### **GET /omniverse/floor_map**
Returns PNG image (2048×2048) for floor projection

---

## 📁 DATA FORMAT

Omniverse Isaac Sim must export JSON in this format:

```json
{
  "scenario_id": "a10_amber_readiness",
  "route": "A10 Cambridge to London",
  "av_readiness": "GREEN" | "AMBER" | "RED",
  "quality_score": 6.2,
  "trajectories": [
    {
      "lat": 52.2053,
      "lon": 0.1218,
      "speed": 55,
      "quality_score": 6
    }
  ],
  "incidents": [
    {
      "lat": 52.210,
      "lon": 0.125,
      "type": "hard_braking",
      "severity": "low" | "medium" | "high"
    }
  ]
}
```

**Multiple scenarios:** Wrap in array `[{...}, {...}]`

---

## 🎨 STYLING

Uses identical corporate teal theme from EVRouteApp:
- Gradient backgrounds: `#002C3C → #008A82 → #00A39A`
- Box hover effects
- Status indicators (success/error/warning)
- AV Readiness badges (Green/Amber/Red)
- Rounded corners, shadows, smooth transitions

---

## 🔧 TROUBLESHOOTING

### **"ModuleLoader not found"**
➜ Copy `module_loader.R` from EVRouteApp to `R/module_loader.R`

### **Scenarios not loading**
➜ Check JSON format matches expected structure
➜ Verify file path is correct
➜ Try "Demo Data" first to test app

### **Leaflet map not showing**
➜ Select a scenario in "Scenarios" tab first
➜ Check that scenario has trajectories with lat/lon

### **Plumber API not accessible from Quest 3**
➜ Ensure PC and Quest 3 on same WiFi
➜ Check firewall allows port 8001
➜ Verify IP address is correct
➜ Start API in separate R session (not in Shiny app)

---

## 📦 PACKAGE REQUIREMENTS

| Package | Purpose |
|---------|---------|
| shiny | Core framework |
| shinydashboard | Dashboard layout |
| R6 | Class system |
| yaml | Module registry |
| DT | Interactive tables |
| plotly | Charts |
| leaflet | Maps |
| jsonlite | JSON parsing |
| httr | HTTP requests |
| plumber | REST API |
| qrcode | QR code (optional) |

---

## ✅ COMPLETE CHECKLIST

- [x] **4 modules created** (each ONE file with UI + Server)
- [x] **Module registry** configured
- [x] **Global.R** with UI/Server creation
- [x] **App.R** entry point
- [x] **CSS theme** (corporate teal)
- [x] **Omniverse data loading** (file/live/demo)
- [x] **Scenario browsing** (DataTable + Plotly)
- [x] **Route visualization** (Leaflet + color coding)
- [x] **Quest 3 AR setup** (Plumber API + QR)
- [ ] **Copy module_loader.R** from EVRouteApp (user action required)

---

## 🚗 DATA FLOW SUMMARY

```
Isaac Sim → JSON Export
     ↓
Tab 1: Load into R Shiny
     ↓
Tab 2: Browse scenarios
     ↓
Tab 3: Preview on map
     ↓
Tab 4: Start Plumber API
     ↓
Quest 3: Scan QR → Enter AR → Floor map appears!
```

---

## 📞 SUPPORT

This app follows the exact modular structure of EVRouteApp:
- **ONE .R file per module** (not separate ui.R/server.R)
- **Module registry YAML** for configuration
- **Automatic module loading** via ModuleLoader
- **Same CSS theme** for consistent branding

**Ready to use once you copy `module_loader.R` from EVRouteApp!**
