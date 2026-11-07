# COMPLETE INSTALLATION GUIDE
## Integrated AV Suite v2.0 - Dual Vehicle + Tab 9 Integration

---

## FILES TO UPDATE/ADD

### 📁 **ROOT DIRECTORY** (where app.R is located)

1. **app.R** ← Replace with new version
   - Location: `/mnt/user-data/outputs/app.R`
   - Changes: Added vehicle_config, sensor_config, physics_config to api_manager

2. **global.R** ← Replace with new version
   - Location: `/mnt/user-data/outputs/global.R`
   - Changes: Updated library loading, proper module initialization

3. **modules/_module_registry.yml** ← Replace with new version
   - Location: `/mnt/user-data/outputs/_module_registry.yml`
   - Changes: Added Tab 9 (metrics_statistics) entry

---

### 📁 **modules/** DIRECTORY

4. **omniverse_connection.R** ← Replace with updated version
   - OLD: Your existing omniverse_connection.R
   - NEW: `/mnt/user-data/outputs/omniverse_connection_UPDATED.R`
   - Rename to: `omniverse_connection.R`
   - Changes: 
     - Vehicle dropdown (Kia Niro EV / Renault E-Tech T)
     - 15 sensor checkboxes
     - 12 physics checkboxes
     - Fixed System Status errors

5. **scenario_manager.R** ← Replace with updated version
   - Location: `/mnt/user-data/outputs/scenario_manager.R`
   - Changes: Added vehicle info display panel

6. **metrics_statistics.R** ← ADD NEW FILE
   - Location: `/mnt/user-data/outputs/metrics_statistics.R`
   - This is the NEW Tab 9 module
   - Copy this file to your modules/ directory

---

## STEP-BY-STEP INSTALLATION

### Step 1: Backup Your Current App
```bash
# Create backup of your current app
cp -r YourIntegratedAVSuite YourIntegratedAVSuite_BACKUP
```

### Step 2: Update Root Files
```bash
# Replace main app files
cp /mnt/user-data/outputs/app.R ./app.R
cp /mnt/user-data/outputs/global.R ./global.R
cp /mnt/user-data/outputs/_module_registry.yml ./modules/_module_registry.yml
```

### Step 3: Update Module Files
```bash
# Replace existing modules
cp /mnt/user-data/outputs/omniverse_connection_UPDATED.R ./modules/omniverse_connection.R
cp /mnt/user-data/outputs/scenario_manager.R ./modules/scenario_manager.R

# Add NEW Tab 9 module
cp /mnt/user-data/outputs/metrics_statistics.R ./modules/metrics_statistics.R
```

### Step 4: Verify File Structure
Your directory should look like this:
```
YourIntegratedAVSuite/
├── app.R                        ← UPDATED
├── global.R                     ← UPDATED
├── R/
│   ├── module_loader.R
│   └── utils_omniverse.R
├── modules/
│   ├── _module_registry.yml     ← UPDATED (added Tab 9)
│   ├── bigquery_setup.R
│   ├── road_network.R
│   ├── route_optimizer.R
│   ├── route_map.R
│   ├── omniverse_connection.R   ← UPDATED (vehicle + features)
│   ├── scenario_manager.R       ← UPDATED (vehicle info)
│   ├── route_preview.R
│   ├── advanced_viz.R
│   └── metrics_statistics.R     ← NEW (Tab 9)
└── www/
    └── css/
        └── global.css
```

### Step 5: Start Python Flask API
```bash
# In a separate terminal
python isaac_sim_flask_api_DUAL_VEHICLE.py
```

Should see:
```
 * Running on http://0.0.0.0:5000
```

### Step 6: Run R Shiny App
```r
# In R or RStudio
shiny::runApp("path/to/YourIntegratedAVSuite", port = 3838)
```

Or if using command line:
```bash
R -e "shiny::runApp('YourIntegratedAVSuite', port=3838)"
```

---

## VERIFICATION CHECKLIST

### ✅ App Starts Successfully
- [ ] No errors when app loads
- [ ] Dashboard shows "Integrated AV Suite" title
- [ ] Sidebar shows 9 menu items

### ✅ Tab 5 (Omniverse Connection) Works
- [ ] Vehicle dropdown shows: Kia Niro EV, Renault E-Tech T
- [ ] Vehicle specs update when you change selection
- [ ] 7 Camera sensor checkboxes visible
- [ ] 4 Other sensor checkboxes visible
- [ ] 4 Vehicle Dynamics checkboxes visible
- [ ] 8 Component checkboxes visible
- [ ] "Test Connection" connects to Flask API
- [ ] "Generate Scenarios" creates scenarios
- [ ] System Status boxes show "0" or actual values (NO errors)

### ✅ Tab 6 (Scenarios) Works
- [ ] Scenario table displays
- [ ] Vehicle info panel shows at top (yellow box)
- [ ] Shows vehicle name, mass, power

### ✅ Tab 9 (Metrics & Statistics) Works
- [ ] Tab appears in sidebar menu
- [ ] Tab loads without errors
- [ ] All metric boxes display
- [ ] Scenario comparison table shows
- [ ] Braking distance calculator works

### ✅ Data Flow Works
- [ ] Generate scenarios in Tab 5
- [ ] Vehicle info appears in Tab 6
- [ ] Full metrics appear in Tab 9
- [ ] All tabs can access api_manager data

---

## TROUBLESHOOTING

### Error: "could not find function metrics_statistics_ui"
**Solution**: Make sure `metrics_statistics.R` is in the `modules/` folder and the file is named exactly `metrics_statistics.R`

### Error: "object 'vehicle_config' not found"
**Solution**: 
1. Make sure you updated `app.R` with the new version
2. The new app.R includes these lines in api_manager:
   ```r
   vehicle_config = NULL,
   sensor_config = NULL,
   physics_config = NULL,
   ```

### Error: "Invalid 'type' (list) of argument"
**Solution**: This was fixed in `omniverse_connection_UPDATED.R`. Make sure you replaced the old file.

### Tab 9 doesn't appear in sidebar
**Solution**: 
1. Check `_module_registry.yml` has the metrics_statistics entry
2. Restart the Shiny app
3. Check R console for module loading messages

### Flask API connection fails
**Solution**:
1. Make sure Python API is running: `python isaac_sim_flask_api_DUAL_VEHICLE.py`
2. Check URL in Tab 5 is `http://localhost:5000`
3. Try clicking "Test Connection" button

---

## FILE MAPPING SUMMARY

| File in /mnt/user-data/outputs/ | Copy to | Purpose |
|--------------------------------|---------|---------|
| app.R | ./app.R | Main app with expanded api_manager |
| global.R | ./global.R | Global config with proper libraries |
| _module_registry.yml | ./modules/_module_registry.yml | Registry with Tab 9 entry |
| omniverse_connection_UPDATED.R | ./modules/omniverse_connection.R | Tab 5 with vehicle/sensors/physics |
| scenario_manager.R | ./modules/scenario_manager.R | Tab 6 with vehicle info |
| metrics_statistics.R | ./modules/metrics_statistics.R | NEW Tab 9 |

---

## EXPECTED BEHAVIOR AFTER INSTALLATION

### When you generate scenarios:
1. Select vehicle (Kia Niro EV or Renault E-Tech T)
2. Check desired sensors and physics features
3. Enter origin/destination
4. Click "Generate Scenarios"

### What happens:
1. Tab 5 stores data in api_manager:
   - `omniverse_scenarios` (array of scenarios)
   - `vehicle_config` (full vehicle physics)
   - `sensor_config` (enabled sensors)
   - `physics_config` (enabled physics)

2. Tab 6 immediately shows:
   - Vehicle name
   - Vehicle mass
   - Vehicle power

3. Tab 9 immediately shows:
   - All vehicle specifications
   - All sensor configurations
   - Complete physics properties
   - Scenario statistics
   - Comparison table
   - Working braking calculator

---

## DEPENDENCIES REQUIRED

Make sure these R packages are installed:
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
  "sf",
  "dodgr",
  "osmdata",
  "bigrquery"
))
```

Python dependencies (for Flask API):
```bash
pip install flask flask-cors
```

---

## CONTACT & SUPPORT

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all files are in correct locations
3. Check R console for error messages
4. Verify Flask API is running

**Success indicators:**
- ✅ App loads with 9 tabs in sidebar
- ✅ Tab 5 shows vehicle dropdown and checkboxes
- ✅ Tab 9 displays comprehensive metrics
- ✅ No console errors

---

**Installation Guide Version**: 1.0  
**Date**: March 10, 2026  
**Project**: Integrated AV Suite v2.0
