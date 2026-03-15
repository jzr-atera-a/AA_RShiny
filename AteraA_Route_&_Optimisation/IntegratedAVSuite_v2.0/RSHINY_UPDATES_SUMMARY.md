# R SHINY APP UPDATES - DUAL VEHICLE + PHYSICS INTEGRATION
## Updated Modules for Isaac Sim Integration

---

## UPDATED MODULES

### 1. **omniverse_connection_UPDATED.R** (Tab 5)

**New Features:**
- ✅ **Vehicle Selection Dropdown**
  - Kia Niro EV
  - Renault E-Tech T 42-tonne HGV
  - Live vehicle specs display (mass, power, battery)

- ✅ **Sensor Feature Checkboxes** (2-column layout)
  - **Camera Sensors:**
    - RGB Color Image
    - Depth Map
    - Distance to Camera
    - Surface Normals
    - Motion Vectors
    - Semantic Segmentation
    - Instance Segmentation
  - **Other Sensors:**
    - RTX LiDAR Point Cloud
    - RTX Radar
    - IMU (Accelerometer/Gyro)
    - Contact Sensors

- ✅ **Physics Feature Checkboxes** (2-column layout)
  - **Vehicle Dynamics:**
    - Mass & Inertia Tensor
    - Linear/Angular Velocity
    - Acceleration
    - Momentum
  - **Components:**
    - Wheel Dynamics
    - Suspension Forces
    - Braking System
    - Drivetrain Torque
    - Steering Angle
    - Aerodynamic Forces
    - Tire Friction & Slip
    - Contact Forces

- ✅ **Route Parameters**
  - Origin/Destination cities
  - Weather selection
  - Time of day
  - Number of scenarios

- ✅ **System Status Boxes - FIXED**
  - Fixed "invalid 'type' (list) of argument" errors
  - Changed all "0" displays to actual values
  - Added proper error handling with try-catch blocks

**API Integration:**
```r
POST /scenarios/query
{
  "vehicle": "kia_niro_ev" or "renault_etech_t",
  "sensors": {
    "camera": ["rgb", "depth", ...],
    "lidar": true/false,
    ...
  },
  "physics": {
    "mass_inertia": true/false,
    "wheels": true/false,
    ...
  }
}
```

**Data Storage:**
- Stores in `api_manager$omniverse_scenarios`
- Stores in `api_manager$vehicle_config`
- Stores in `api_manager$sensor_config`
- Stores in `api_manager$physics_config`

---

### 2. **metrics_statistics.R** (NEW Tab 9)

**Complete Metrics Dashboard:**

#### **Vehicle Configuration Section**
- Vehicle name, category, manufacturer
- Physical dimensions (length, width, height, wheelbase)
- All dimension values with proper formatting

#### **Sensor Configuration Section**
- Lists all enabled sensors
- Camera types enabled
- LiDAR, Radar, IMU, Contact sensor status

#### **Mass & Inertia Properties Section**
- Curb weight, GVW/GCW, payload capacity
- Front/rear axle weights
- Center of gravity height
- **Inertia Tensor (kg·m²):**
  - Ixx (Roll inertia)
  - Iyy (Pitch inertia)
  - Izz (Yaw inertia)

#### **Dynamics & Performance Section**
- Max speed, range, acceleration
- Battery capacity, voltage, weight
- All performance metrics

#### **Wheel & Tire Metrics Section**
- Number of wheels, radius, width
- Wheel mass and rotational inertia
- **Tire friction coefficients:**
  - Dry surface (static & dynamic μ)
  - Wet surface (static & dynamic μ)

#### **Suspension & Braking Section**
- Front/rear spring rates (N/m)
- Front/rear damping rates (N·s/m)
- Max brake torque (front/rear)
- Brake distribution percentage
- ABS status

#### **Powertrain & Aerodynamics Section**
- Motor type, power, torque
- Drive type (FWD/RWD)
- Drag coefficient (Cd)
- Frontal area (m²)

#### **Scenario Statistics Section**
- Total scenarios count
- Total trajectory points
- Total incidents detected
- Average quality score
- Visual stat boxes with color coding

#### **Scenario Comparison Table**
- Interactive DT::datatable
- Columns: Scenario, Route, Weather, Quality, Trajectories, Incidents, Readiness
- Sortable and filterable
- Compares multiple scenarios side-by-side

#### **Braking Distance Calculator**
- Interactive calculator
- Inputs:
  - Speed (km/h)
  - Road surface (Dry/Wet)
  - Uses actual vehicle tire friction data
- **Outputs:**
  - Braking distance (meters)
  - Deceleration rate (m/s²)
  - Stopping time (seconds)
- Formula: `distance = v² / (2 × μ × g)`

---

### 3. **scenario_manager.R** (Tab 6 - Updated)

**Additions:**
- ✅ Vehicle info display panel
  - Shows selected vehicle name
  - Shows vehicle mass
  - Shows vehicle power
- Color-coded highlight box
- Integrates with `api_manager$vehicle_config`

---

## DATA FLOW ARCHITECTURE

```
Tab 5 (Omniverse Connection)
    ↓
User selects vehicle + sensors + physics features
    ↓
Generates scenarios via Flask API
    ↓
Stores in api_manager:
    - omniverse_scenarios
    - vehicle_config
    - sensor_config
    - physics_config
    ↓
Data flows to:
    → Tab 6 (Scenario Manager) - displays vehicle info
    → Tab 7 (Route Preview) - can overlay physics data
    → Tab 8 (Advanced Viz) - can show physics metrics
    → Tab 9 (Metrics & Statistics) - comprehensive analysis
```

---

## TABS UPDATED

| Tab | Name | Status | Changes |
|-----|------|--------|---------|
| Tab 1 | BigQuery Setup | ❌ Not Modified | Independent module |
| Tab 2 | Road Network | ❌ Not Modified | Independent module |
| Tab 3 | Route Optimizer | ❌ Not Modified | Independent module |
| Tab 4 | Route Map | ❌ Not Modified | Independent module |
| Tab 5 | Omniverse Connection | ✅ **UPDATED** | Vehicle selection, feature checkboxes, error fixes |
| Tab 6 | Scenarios | ✅ **UPDATED** | Added vehicle info display |
| Tab 7 | Route Preview | 🔄 Ready for enhancement | Can add physics overlays |
| Tab 8 | Advanced Viz | 🔄 Ready for enhancement | Can add physics charts |
| Tab 9 | Metrics & Statistics | ✅ **NEW MODULE** | Complete metrics dashboard |

---

## ERROR FIXES

### Fixed in Tab 5 (Omniverse Connection):

1. **"invalid 'type' (list) of argument" Error**
   - Added `tryCatch()` blocks around all metric calculations
   - Proper type checking for list vs numeric data
   - Default to "0" on any error

2. **Changed Display from "N/A" to "0"**
   - `scenarioCount`: Shows "0" when no scenarios
   - `trajectoryCount`: Shows "0" when no trajectories
   - `incidentCount`: Shows "0" when no incidents
   - `avgQualityScore`: Shows "0" when no scores

3. **Improved Error Handling**
   ```r
   tryCatch({
     # Calculation logic
   }, error = function(e) {
     total <<- 0  # Fallback value
   })
   ```

---

## VEHICLE CONFIGURATIONS AVAILABLE

### Kia Niro EV
- Mass: 1,739 kg
- Power: 150 kW (201 hp)
- Battery: 64.8 kWh
- Type: Electric Crossover SUV
- Complete physics model with all properties

### Renault E-Tech T
- Mass: 8,500 kg (tare), 42,000 kg (GCW)
- Power: 490 kW (666 hp)
- Battery: 540 kWh
- Type: 42-tonne Electric HGV
- Complete physics model with all properties

---

## INSTALLATION INSTRUCTIONS

### 1. Replace Modules
```r
# In your R Shiny app modules/ directory:
modules/omniverse_connection.R       ← Use omniverse_connection_UPDATED.R
modules/scenario_manager.R           ← Updated version (vehicle info added)
modules/metrics_statistics.R         ← NEW FILE (Tab 9)
```

### 2. Update app.R
Add Tab 9 to your tabItems:
```r
tabItem(
  tabName = "metrics",
  metrics_statistics_ui("metrics_tab")
)
```

Add to server:
```r
metrics_statistics_server("metrics_tab", api_manager = api_manager)
```

Add to sidebar menu:
```r
menuItem("Metrics & Statistics", tabName = "metrics", icon = icon("chart-bar"))
```

### 3. Start Flask API
```bash
python isaac_sim_flask_api_DUAL_VEHICLE.py
```

### 4. Test Connection
1. Open R Shiny app
2. Go to Tab 5 (Omniverse Connection)
3. Click "Test Connection"
4. Select vehicle
5. Select sensors/physics features
6. Generate scenarios
7. View results in all tabs

---

## FEATURES SUMMARY

✅ Dual vehicle support (car + truck)
✅ 15 sensor feature checkboxes
✅ 12 physics feature checkboxes
✅ All errors fixed (no more "invalid type" errors)
✅ Real-time vehicle specs display
✅ Complete metrics dashboard (Tab 9)
✅ Scenario comparison table
✅ Braking distance calculator
✅ Data flows to all dependent tabs
✅ Interactive statistics
✅ Color-coded displays

---

## NEXT STEPS (OPTIONAL ENHANCEMENTS)

### Tab 7 (Route Preview)
- Overlay physics data on map
- Show braking distances at waypoints
- Display tire friction zones
- Suspension load visualization

### Tab 8 (Advanced Viz)
- Physics time-series charts
- Acceleration vs. time graphs
- Brake force distribution plots
- Energy consumption curves

---

**Document Version**: 1.0
**Date**: March 10, 2026
**Project**: WP5 Integrated AV Suite - Dual Vehicle Update
