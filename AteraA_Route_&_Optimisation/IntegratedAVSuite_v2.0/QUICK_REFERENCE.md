# QUICK REFERENCE - FILES TO UPDATE
## Tab 9 Integration - Checklist

---

## ✅ MANDATORY FILES (6 files total)

### 1. **app.R**
- Source: `/mnt/user-data/outputs/app.R`
- Destination: `YourApp/app.R`
- Action: REPLACE existing file
- Why: Adds vehicle_config, sensor_config, physics_config to api_manager

### 2. **global.R**
- Source: `/mnt/user-data/outputs/global.R`
- Destination: `YourApp/global.R`
- Action: REPLACE existing file
- Why: Updates library loading and module initialization

### 3. **modules/_module_registry.yml**
- Source: `/mnt/user-data/outputs/_module_registry.yml`
- Destination: `YourApp/modules/_module_registry.yml`
- Action: REPLACE existing file
- Why: Registers Tab 9 in the module system

### 4. **modules/omniverse_connection.R**
- Source: `/mnt/user-data/outputs/omniverse_connection_UPDATED.R`
- Destination: `YourApp/modules/omniverse_connection.R`
- Action: REPLACE existing file
- Why: Adds vehicle selection, sensor checkboxes, physics checkboxes

### 5. **modules/scenario_manager.R**
- Source: `/mnt/user-data/outputs/scenario_manager.R`
- Destination: `YourApp/modules/scenario_manager.R`
- Action: REPLACE existing file
- Why: Adds vehicle info display panel

### 6. **modules/metrics_statistics.R**
- Source: `/mnt/user-data/outputs/metrics_statistics.R`
- Destination: `YourApp/modules/metrics_statistics.R`
- Action: ADD NEW FILE (doesn't exist yet)
- Why: This IS Tab 9 - the complete metrics dashboard

---

## 🔧 ONE-LINE COPY COMMANDS

```bash
# From the directory containing your app:
cp /mnt/user-data/outputs/app.R ./app.R
cp /mnt/user-data/outputs/global.R ./global.R
cp /mnt/user-data/outputs/_module_registry.yml ./modules/_module_registry.yml
cp /mnt/user-data/outputs/omniverse_connection_UPDATED.R ./modules/omniverse_connection.R
cp /mnt/user-data/outputs/scenario_manager.R ./modules/scenario_manager.R
cp /mnt/user-data/outputs/metrics_statistics.R ./modules/metrics_statistics.R
```

---

## 🐍 PYTHON API (No changes needed)

Use existing file:
- **isaac_sim_flask_api_DUAL_VEHICLE.py**
- Already supports both vehicles
- Already has all sensor/physics configs
- Just run it: `python isaac_sim_flask_api_DUAL_VEHICLE.py`

---

## 🎯 WHAT EACH FILE DOES

| File | What Changed | Impact |
|------|--------------|--------|
| app.R | Added 3 new fields to api_manager | Enables data sharing between tabs |
| global.R | Updated library list | Ensures all dependencies load |
| _module_registry.yml | Added Tab 9 entry | Makes Tab 9 visible in sidebar |
| omniverse_connection.R | Added UI controls + API calls | Vehicle selection + feature checkboxes |
| scenario_manager.R | Added vehicle info panel | Shows selected vehicle in Tab 6 |
| metrics_statistics.R | NEW FILE | Complete Tab 9 metrics dashboard |

---

## 📊 BEFORE vs AFTER

### BEFORE (your current app):
- 8 tabs total
- Tab 5: Basic Omniverse connection
- No vehicle selection
- No sensor/physics selection
- System Status shows errors or "N/A"

### AFTER (with these updates):
- **9 tabs total**
- Tab 5: Vehicle dropdown + 15 sensor checkboxes + 12 physics checkboxes
- Tab 6: Shows vehicle info (name, mass, power)
- **Tab 9: NEW - Complete metrics dashboard**
- System Status shows actual values (no errors)

---

## ⚡ QUICK TEST AFTER INSTALLATION

1. Start Flask API:
   ```bash
   python isaac_sim_flask_api_DUAL_VEHICLE.py
   ```

2. Start R Shiny:
   ```r
   shiny::runApp()
   ```

3. Check sidebar - should see 9 items:
   - BigQuery Setup
   - Road Network
   - Route Optimizer
   - Route Map
   - Omniverse Connection
   - Scenarios
   - Route Preview
   - Advanced Viz
   - **Metrics & Statistics** ← NEW

4. Go to Tab 5, should see:
   - Vehicle dropdown
   - Two columns of checkboxes (Sensors | Physics)
   - All checkboxes working

5. Generate a scenario, then go to Tab 9:
   - Should see full vehicle specs
   - Should see scenario comparison table
   - Braking calculator should work

---

## 🚨 COMMON MISTAKES TO AVOID

❌ Don't forget to rename `omniverse_connection_UPDATED.R` to `omniverse_connection.R`

❌ Don't skip updating `app.R` - the new api_manager fields are critical

❌ Don't forget to copy `_module_registry.yml` to the `modules/` folder

❌ Don't run the app before starting the Python Flask API

✅ Do verify all 6 files are copied correctly

✅ Do restart RStudio/R session after updating files

✅ Do check that Tab 9 appears in the sidebar

---

## 📋 FILE COUNT VERIFICATION

After installation, you should have:

**In root directory:**
- ✅ app.R (updated)
- ✅ global.R (updated)

**In modules/ directory:**
- ✅ _module_registry.yml (updated)
- ✅ bigquery_setup.R (unchanged)
- ✅ road_network.R (unchanged)
- ✅ route_optimizer.R (unchanged)
- ✅ route_map.R (unchanged)
- ✅ omniverse_connection.R (updated)
- ✅ scenario_manager.R (updated)
- ✅ route_preview.R (unchanged)
- ✅ advanced_viz.R (unchanged)
- ✅ **metrics_statistics.R (NEW)**

**Total: 9 modules = 9 tabs**

---

## 💾 BACKUP REMINDER

Before updating, create a backup:
```bash
cp -r YourIntegratedAVSuite YourIntegratedAVSuite_BACKUP_$(date +%Y%m%d)
```

This creates a timestamped backup you can restore if needed.

---

**Quick Reference Version**: 1.0  
**Last Updated**: March 10, 2026
