# 🚀 QUICKSTART GUIDE
## Greenwich AV Data Extractor

### Get started in 3 minutes!

---

## Step 1: Install Dependencies (First Time Only)

Open R or RStudio and run:

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr", 
  "magrittr", "dplyr", "sf", "osmdata", "leaflet", 
  "htmltools", "httr", "jsonlite", "raster", "tmaptools"
))
```

**Time:** ~5 minutes (depending on internet speed)

---

## Step 2: Launch the App

```r
# Navigate to app directory
setwd("path/to/GreenwichAVApp")

# Run the app
shiny::runApp()
```

The app will open automatically in your default web browser!

---

## Step 3: Download Data (The Easy Way)

### Option A: Use Default Greenwich Location (Recommended)

1. **Go to Tab 1: OpenStreetMap**
   - Click "Download OSM Data" (default location is already set!)
   - Wait ~30 seconds
   - ✓ Done!

2. **Go to Tab 6: Preview & Export**
   - Click "Export All Data"
   - Click "Download ZIP Bundle"
   - ✓ You have your Unity-ready data!

**Total time: ~2 minutes**

### Option B: Custom Location

1. **Go to Tab 1: OpenStreetMap**
   - Enter your location (e.g., "Cambridge, England")
   - Click "Use Location Name"
   - Click "Download OSM Data"

2. **Continue to other tabs as needed**

3. **Go to Tab 6: Preview & Export**
   - Export and download

---

## What You Get

A ZIP file containing:
- `buildings.geojson` - Building footprints
- `roads.geojson` - Road network
- `poi.geojson` - Points of interest
- `metadata.json` - Data information
- `README.txt` - Unity import guide

---

## Quick Tips

✅ **For best results:** Download data from tabs 1, 4, and 5
✅ **Free data:** OpenStreetMap requires no API key
✅ **Map preview:** Tab 6 shows all your data on a map
✅ **Stuck?** Check the main README.md for troubleshooting

---

## Next Steps

1. Extract the ZIP file
2. Open Unity 3D
3. Import using Mapbox SDK or GIS Tools
4. Build your VR simulation!

**Need help?** See full README.md for detailed instructions.

---

**That's it! Happy mapping! 🗺️**
