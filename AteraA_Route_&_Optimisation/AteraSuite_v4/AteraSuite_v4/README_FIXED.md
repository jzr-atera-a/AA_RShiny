# Atera Analytics Integrated AV Suite — FIXED
**Innovate UK Project 10153306 — CAM Pathfinder One**

---

## What Was Fixed

| Problem | Fix |
|---------|-----|
| WebSocket server R Shiny couldn't connect to | Replaced with Flask HTTP on port 5000 |
| Fake `omniverse_data$connected <- TRUE` on regex | Real `httr::GET("/status")` with actual HTTP response |
| Mock simulation with hardcoded `52.0 + i*0.01` coordinates | Real OSRM + Nominatim GPS coordinates |
| Fake `Sys.sleep()` delays masquerading as simulation | Real `httr::POST("/scenarios/query")` to Isaac Sim |
| `global.R` referenced missing `R/module_loader.R` | Fixed paths, files present in `R/` folder |
| `_module_registry.yml` had 4 old modules | Updated to all 9 correct modules matching filenames |
| No map of real trajectory | Leaflet map with real GPS polyline + physics popups per waypoint |
| Physics features not computed per selection | All 13 physics features computed conditionally by Isaac Sim |

---

## Directory Structure

```
AteraSuite_FIXED/
├── app.R                                  Main entry point (unchanged)
├── global.R                               FIXED: correct R/ paths
├── START_SERVER.bat                       NEW: starts Flask API
├── START_SHINY.bat                        NEW: starts R Shiny
├── isaac_sim_flask_api_DUAL_VEHICLE.py    Flask HTTP server (port 5000)
├── isaac_sim_physx_vehicle.py             Isaac Sim PhysX subprocess
├── test_physx_vehicle.py                  PhysX diagnostic (unchanged)
├── R/
│   ├── module_loader.R
│   └── utils_omniverse.R
└── modules/
    ├── _module_registry.yml               FIXED: all 9 modules
    ├── omniverse_connection.R             REWRITTEN: real HTTP + map
    ├── bigquery_connection.R
    ├── road_network.R
    ├── route_optimizer.R
    ├── route_map.R
    ├── scenario_manager.R
    ├── route_preview.R
    ├── advanced_viz.R
    └── metrics_statistics.R
```

---

## How to Run

### 1. Start the Flask server (standard Python — NOT isaac-sim python)
```
START_SERVER.bat
```
Or manually:
```
pip install flask flask-cors requests
python isaac_sim_flask_api_DUAL_VEHICLE.py
```

### 2. Start R Shiny
```
START_SHINY.bat
```
Or in RStudio:
```r
shiny::runApp(".", port = 3838)
```

### 3. In the R Shiny app (Tab: Isaac Sim)
1. Click **Test Connection** → should show "Connected" with Isaac Sim status
2. Click **Query Capabilities** → shows confirmed sensors + physics
3. Select vehicle, route, sensors, physics features
4. Click **Generate Scenarios** → Isaac Sim runs as subprocess
5. Map shows **real OSRM GPS route** with per-waypoint physics popups
6. All downstream tabs (Scenarios, Route Preview, Analytics, Metrics) receive real data

---

## Connection URL
- Flask server: `http://localhost:5000` (HTTP, NOT ws://)
- R Shiny uses `httr::GET` and `httr::POST` — no WebSocket package needed

---

## Isaac Sim Path
Flask server default:
```python
ISAAC_SIM_PYTHON = "C:/isaac-sim/python.bat"
```
Edit `isaac_sim_flask_api_DUAL_VEHICLE.py` line 25 if your path differs.

---

## Vehicles
| Vehicle | Mass | Power | Battery |
|---------|------|-------|---------|
| Kia Niro EV (2023-2025) | 1,739 kg | 150 kW | 64.8 kWh |
| Renault E-Tech T (loaded) | 42,000 kg | 490 kW | 540 kWh |

## Physics Features (all computed from real PhysX)
Linear/angular velocity, acceleration (m/s², g), momentum, mass/inertia tensor,
aerodynamic drag force + power, tire friction μ, suspension deflection (static + dynamic),
braking force, drivetrain tractive force + wheel RPM, steering angle + yaw rate, contact forces.

## Sensors
Camera RGB (lane visibility, sign confidence, object detection), LiDAR (point density,
detection confidence, effective range), IMU (accelerometer + gyroscope with noise).

All sensor values degrade realistically with weather (rain/fog) and time of day.
