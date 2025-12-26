# EV Route Optimizer - Quick Start Guide

## ⚡ 5-Minute Setup

### 1. Install Packages (One-time)

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "bigrquery", "osmdata", "sf", "dplyr", "dodgr", 
  "tmaptools", "leaflet", "htmltools"
))
```

### 2. Run App

```r
setwd("path/to/EVRouteApp")
shiny::runApp()
```

### 3. Use App

**Step 1: BigQuery Setup Tab**
- Upload JSON key file
- Keep default values:
  - Project: `atera-2`
  - Dataset: `EVs_Infrastructure`
  - Table: `Charge_Points_UK_EVs`
- Click "Test Connection"
- Wait for "Connection Successful"

**Step 2: Road Network Tab**
- Location: "Cambridge, England" (default)
- Click "Download Road Network"
- Wait 30-60 seconds

**Step 3: Route Optimizer Tab**
- Select origin/destination
- Click "Calculate Optimal Route"
- Click "View Route Map"

**Step 4: Route Map Tab**
- View interactive map
- Click markers for details

## 🎯 First Run Expected Results

- **Charging points loaded:** ~50,000+ (UK wide)
- **Network nodes:** ~10,000-50,000 (depends on location)
- **Route calculation:** 5-10 seconds
- **Total distance:** Varies (typically 5-20 km)

## ⚙️ Customize

To disable a module, edit `modules/_module_registry.yml`:

```yaml
route_map:
  enabled: false
```

## 🆘 Common Issues

**"Connection Failed"**
→ Check JSON key file and internet connection

**"Location not found"**
→ Try "Cambridge, UK" or "London, UK"

**"No charging points"**
→ BigQuery connection required first

## 📖 Full Documentation

See `README.md` and `ARCHITECTURE.md`
