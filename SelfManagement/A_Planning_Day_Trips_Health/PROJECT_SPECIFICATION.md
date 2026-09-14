# Travel Itinerary Planner - Project Specification

**Status:** BROKEN - Multiple implementation failures. Handing off to another developer/LLM.

---

## PROJECT GOAL

Build a Shiny R application module called "Travel Itinerary Planner" that:
1. Allows users to discover attractions in any destination via Claude AI
2. Generates a day-by-day travel itinerary
3. Displays the itinerary on an interactive map
4. **SAVES the rendered map image temporarily**
5. Exports itinerary in 6 formats: HTML, PDF, ICS, KML, GPX, Google Maps Link

---

## CURRENT STATE

### ✅ WORKING
- Discovery of places via Claude API
- Generation of itineraries with GPS coordinates
- Map display using Plotly scattermapbox
- ICS Calendar export
- KML (Google Maps) export
- GPX (GPS) export
- Google Maps Link export

### ❌ BROKEN / INCOMPLETE
1. **Map Save Button** - Was supposed to be added but is missing/non-functional
2. **HTML Export** - Map image NOT showing in exported HTML
3. **PDF Export** - Map NOT embedding in PDF
4. **Map Image Storage** - Code claims to save PNG but creates empty files

---

## REQUIREMENTS (WHAT USER WANTS)

### Step 1: Discover Places
- User enters destination (e.g., "Tokyo, Japan")
- User sets number of places (20-50)
- Click "🔍 Discover Places"
- Claude API finds top attractions
- Display as clickable checkboxes

### Step 2: Generate Itinerary
- User selects attractions (checkboxes)
- User sets start date and number of days
- Click "Generate Itinerary"
- System creates day-by-day schedule with times
- **Map appears showing all attractions with Plotly**

### Step 3: **SAVE MAP IMAGE** ⭐ CRITICAL
- **A button must appear below the map** labeled "💾 Save Map Image"
- When clicked, the rendered Plotly map is captured and stored temporarily
- Show notification: "✅ Map image saved! Ready for export."
- Console shows: "📸 MAP SAVE: User clicked 'Save Map Image'"
- Store path: `C:\Users\...\AppData\Local\Temp\RtmpXXXX\travel_maps\map_TIMESTAMP.png`

### Step 4: Export in All Formats
- **HTML Export** - Must include the saved map image
- **PDF Export** - Must include the saved map image  
- **ICS Calendar** - Events with GPS coordinates
- **KML** - Google Maps format with placemarks
- **GPX** - GPS waypoints
- **Google Maps Link** - Navigation URL with all waypoints

---

## FILE STRUCTURE

```
business_ops_updated_export/
├── modules/
│   └── Travel Planning/
│       └── travel_itinerary_planner/
│           ├── manifest.yml
│           ├── ui.R              ← NEEDS FIX
│           └── server.R          ← NEEDS FIX
```

---

## CRITICAL ISSUES TO SOLVE

### Issue 1: Map Save Button Missing
**Problem:** 
- Button should appear below Plotly map after itinerary generation
- Currently NOT showing or NON-FUNCTIONAL
- Original plan: Click button → Capture map image → Save to temp folder

**Solution Needed:**
- Add `output$save_map_button <- renderUI({...})` to server.R
- Show button ONLY when itinerary is generated
- `observeEvent(input$save_map_image, {...})`
- Actually capture the Plotly map using `webshot::export()` or similar
- Store file path in `rv$map_image_path`
- Show success notification

**Location in UI:** After `plotly::plotlyOutput(ns("trip_map"), height = "500px")`

**Example code structure:**
```r
output$save_map_button <- renderUI({
  if (!is.null(rv$itinerary_data) && length(rv$itinerary_data) > 0) {
    actionButton(ns("save_map_image"), "💾 Save Map Image", class = "btn-info", style = "width: 100%;")
  }
})

observeEvent(input$save_map_image, {
  cat("\n📸 MAP SAVE: User clicked 'Save Map Image'\n")
  # CAPTURE THE MAP HERE
  # Use webshot or plotly export to create PNG
  # Save to temp directory
  # Store path in rv$map_image_path
  # Show notification
})
```

### Issue 2: Map Not Showing in HTML Export
**Problem:**
- HTML exports generated but NO map image appears
- Code was trying to create PNG files that never got created
- Temp folder shows empty directory

**Solution Needed:**
- Option A: Use saved PNG file from `rv$map_image_path` if available
- Option B (BETTER): Generate Google Static Maps URL from coordinates
  - Build URL: `https://maps.googleapis.com/maps/api/staticmap?center=LAT,LON&markers=LAT1,LON1|LAT2,LON2...`
  - Embed as `<img src="...">` in HTML

**In download_html handler:**
```r
# Get all coordinates
lats <- c()
lons <- c()
# ... extract from rv$itinerary_data ...

# Generate map URL
if (length(lats) > 0) {
  lat_center <- mean(lats)
  lon_center <- mean(lons)
  markers <- paste(sapply(1:length(lats), function(i) paste0(lats[i], ",", lons[i])), collapse = "|")
  map_url <- paste0("https://maps.googleapis.com/maps/api/staticmap?center=", lat_center, ",", lon_center, "&zoom=12&size=900x400&markers=", markers, "&format=png")
  
  # Embed in HTML
  html <- c(html, paste0("<img src='", map_url, "' style='width:100%; margin:20px 0;'>"))
}
```

### Issue 3: PDF Export Not Including Map
**Problem:**
- PDF exports don't include the map image
- rmarkdown rendering may be failing

**Solution Needed:**
- Use same Google Static Maps URL approach
- Embed markdown: `![Map](https://maps.googleapis.com/maps/api/staticmap?...)`
- Or use saved PNG if available: `![Map](/path/to/map.png)`

**In download_pdf handler:**
```r
if (!is.null(rv$map_image_path) && rv$map_image_path != "") {
  md_content <- c(md_content, "## Map", paste0("![](", rv$map_image_path, ")"), "")
} else if (length(lats) > 0) {
  # Fallback to URL-based map
  map_url <- # ... generate URL ...
  md_content <- c(md_content, "## Map", paste0("![](", map_url, ")"), "")
}
```

---

## FILES THAT NEED CHANGES

### 1. `server.R` (715+ lines)
- Add map save button handler (after line 315 - map rendering)
- Fix download_html handler to include map
- Fix download_pdf handler to include map
- Keep all discovery/generation code intact

### 2. `ui.R` (275+ lines)
- Add `uiOutput(ns("save_map_button"))` below map display
- Keep everything else

---

## DEBUG OUTPUT REQUIREMENTS

When exporting files, console should show:

**HTML Export:**
```
📄 EXPORTING: HTML
  Destination: San Francisco, USA
  📍 Found 3 attractions
  🗺️ Map embedded
  ✅ HTML WITH MAP generated
  📊 File size: 12,456 bytes
```

**PDF Export:**
```
📕 EXPORTING: PDF
  Destination: San Francisco, USA
  📍 Found 3 attractions
  🗺️ Map embedded
  ⏳ Rendering to PDF...
  ✅ PDF generated
  📊 File size: 156,789 bytes
```

**Map Save:**
```
📸 MAP SAVE: User clicked 'Save Map Image'
  ✅ Map stored for export
  📁 Path: C:\Users\...\travel_maps\map_20260914_160800.png
  ✅ Ready to use in HTML, PDF, KML, GPX, Google Maps exports
```

---

## WHAT WENT WRONG IN PREVIOUS ATTEMPTS

1. ❌ Tried to use sed to insert debug code → Broke syntax
2. ❌ Created incomplete server files → Missing discovery code
3. ❌ Tried to capture Plotly map without webshot → Files never created
4. ❌ Didn't actually implement map save button → Just talked about it
5. ❌ Generated HTML without map image → User sees blank space
6. ❌ Went in circles instead of fixing core issues

---

## WHAT ACTUALLY NEEDS TO HAPPEN

1. **Add map save button to UI** - Shows after itinerary generation
2. **Implement map capture in server** - Actually saves PNG to disk
3. **Embed map in HTML export** - Use saved PNG or URL
4. **Embed map in PDF export** - Use saved PNG or URL
5. **Test all 6 export formats** - HTML, PDF, ICS, KML, GPX, Google Maps Link
6. **Add proper error handling** - Show errors in console if map fails

---

## ORIGINAL ZIP REFERENCE

File: `DaysPlanningFundingTravel.zip` (252 KB)
- Contains complete app with all modules
- Travel Planner module is in: `modules/Travel Planning/travel_itinerary_planner/`
- All discovery/generation code works correctly
- Only needs: map save button + map in exports

---

## SUCCESS CRITERIA

✅ User can discover places
✅ User can generate itinerary
✅ Map displays on screen
✅ **Button "💾 Save Map Image" appears and works**
✅ **Clicking button saves map to temp folder**
✅ **HTML export includes map image**
✅ **PDF export includes map image**
✅ Console shows debug info for all operations
✅ All 6 download formats work without errors

---

## NOTES

- **This is NOT a design problem** - The structure is correct
- **This is an IMPLEMENTATION problem** - Features aren't actually built
- **Map capture is the core blocker** - Everything else depends on it
- **Don't reinvent, fix** - Keep working code, add missing pieces only
- **Test as you go** - Don't combine multiple changes

---

**Previous LLM:** Claude (failed multiple times, going in circles)
**Root Cause:** Over-engineering, incomplete implementations, sed disasters
**Solution:** Simple, focused implementation of ONE feature at a time

