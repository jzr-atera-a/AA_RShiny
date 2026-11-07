# NB Builder — Agent Guidelines
## ArcGIS-First Australian Mining Notebooks

---

## 0. How the Shiny App Orchestrates Both Agents

```
R Shiny (nb_builder)
  Tab 2 Task  → user types spec → [Plan Task] → calls planner.py (Agent 1, sync, ~5s)
                                → plan JSON shown in table
               → [Run Build] → launches notebook_builder.py as subprocess
                                → Agent 1 (Writer) writes one cell
                                → Kernel executes it
                                → Agent 2 (Verifier) reviews output + code
                                → if risk=high OR review_every=true → human checkpoint panel
                                → approved → saved to notebook.ipynb + session.json
                                → loop to next cell
  Tab 3 Monitor → polls progress.json every 2s → shows live log, stats, pause/stop
  Tab 4 Outputs → polls session.json every 5s → shows approved cells, download button
```

**Key files the app reads/writes:**

| File | Who writes | Who reads |
|---|---|---|
| `launch_config.json` | R | Python |
| `progress.json` | Python | R (every 2s) |
| `control.json` | R | Python (between cells) |
| `session.json` | Python | R (outputs tab) + Python (resume) |
| `run.log` | Python | R (monitor tab) |
| `notebook.ipynb` | Python | R (download button) |
| `context/` files | User drops files here | Python reads once at start |

**Output location** is set in Tab 1 Settings → `runs_dir`. The app creates:
`{runs_dir}/{YYYY-MM-DD_HHMMSS}_{spec-slug}/notebook.ipynb`

For the R Shiny managing app, the notebook lands wherever `cfg$runs_dir` points. Agent 1 must write the output path cell using exactly the `run_dir` value passed in `launch_config.json` — do NOT hardcode paths.

---

## 1. Spec Format (what Tab 2 receives)

The spec is free text. The planner turns it into a JSON plan with this shape:
```json
{
  "total_cells_estimate": 6,
  "outline": [
    {"cell": 1, "title": "Imports & environment", "packages": ["arcgis","pandas"], "complexity": "low"},
    {"cell": 2, "title": "GIS connection & data", "packages": ["arcgis"], "complexity": "medium"},
    ...
  ],
  "context_notes": "..."
}
```

When writing specs for Australian mining notebooks, include:
- Task type (extract / analyse / visualise / all three)
- Aggregation level (national / by state / by commodity / site-level)
- Output format (CSV / SDF / map widget / Plotly 3D)
- Any specific mines or states to focus on

---

## 2. Cell Structure Rules (CRITICAL)

**One cell = one complete functional module. Never split a module across cells.**

### Required cell sequence for any ArcGIS mining notebook:

| Cell # | Title | Must contain |
|---|---|---|
| 1 | Imports | ALL imports for the entire notebook — arcgis + pandas + plotly + json + urllib |
| 2 | Environment & Auth | GIS connect + output path setup + curated data constants |
| 3 | ArcGIS Data Pull | FeatureLayer query + geographic validation + SDF creation |
| 4 | ArcGIS Spatial Analysis | geometry ops + SDF filtering + field stats — ALL in one cell |
| 5 | ArcGIS Map (2D) | Map() + FeatureSet + content.add() + display |
| 6 | Plotly 3D | elevation query + 3D chart — only after ArcGIS cells are complete |
| 7 | Export | CSV + notebook.ipynb path — uses run_dir from Cell 2 |

Agent 1 must never write a cell that does half a thing. If an import is needed, it goes in Cell 1. If a spatial filter is needed, it goes in Cell 4 alongside the rest of spatial analysis.

---

## 3. Cell 1 — Imports (exact template)

```python
# ── All imports ───────────────────────────────────────────────────────────────
from arcgis.gis import GIS
from arcgis.map import Map, Scene
from arcgis.features import FeatureLayer, FeatureSet, Feature, FeatureCollection
from arcgis.features.layer import FeatureLayerCollection
from arcgis.geometry import Point, Polygon, Polyline, Envelope, Geometry
from arcgis.geometry.functions import project, distance, buffer
from arcgis.geocoding import geocode, reverse_geocode
import pandas as pd
import json
import os
import urllib.request
import urllib.parse
import plotly.graph_objects as go
import plotly.express as px
print("✅ Imports complete")
```

---

## 4. Cell 2 — Environment & Auth (exact template)

```python
# ── Authentication ────────────────────────────────────────────────────────────
# Profile josephzr: keyring warning about missing password is NORMAL and HARMLESS.
# Connection works for public/anonymous access.
from arcgis.gis import GIS
gis = GIS(profile="josephzr")

me = gis.users.me   # NEVER use gis.properties.user — crashes on anonymous
print(f"Connected as: {me.username if me else 'anonymous/public'}")
print(f"Portal: {gis.url}")

# ── Output path ───────────────────────────────────────────────────────────────
# run_dir is injected by launch_config.json from the R Shiny app.
# Fallback to current directory when running standalone.
import os
RUN_DIR = os.environ.get("NB_RUN_DIR", os.getcwd())
OUTPUT_CSV = os.path.join(RUN_DIR, "australia_mines_3d.csv")
print(f"Outputs → {RUN_DIR}")

# ── Curated baseline data (always available, no network required) ─────────────
MINES = [
    # name                      state  commodity   lat        lon        pit_depth_m
    ("Kalgoorlie Super Pit",    "WA",  "Gold",    -30.7701,  121.5082,  570),
    ("Boddington Gold Mine",    "WA",  "Gold",    -32.7917,  116.4658,  250),
    ("Mount Tom Price",         "WA",  "Iron Ore",-22.6942,  117.7931,  300),
    ("Newman / Whaleback",      "WA",  "Iron Ore",-23.3523,  119.7317,  450),
    ("Olympic Dam",             "SA",  "Copper",  -30.4418,  136.8795,  350),
    ("Goonyella / Moranbah",    "QLD", "Coal",    -21.9833,  148.0167,  None),
    ("Prominent Hill",          "SA",  "Copper",  -29.7333,  135.5333,  280),
    ("Cannington Mine",         "QLD", "Silver",  -22.4833,  140.7667,  None),
]
ELEV_FALLBACK = {  # REST returns 0 for Boddington — use these instead
    "Kalgoorlie Super Pit": 380, "Boddington Gold Mine": 270,
    "Mount Tom Price": 420,      "Newman / Whaleback": 640,
    "Olympic Dam": 60,           "Goonyella / Moranbah": 250,
    "Prominent Hill": 180,       "Cannington Mine": 275,
}
MINES_DF = pd.DataFrame(MINES, columns=["name","state","commodity","lat","lon","pit_depth_m"])
AU_BBOX = {"lat": (-45.0, -10.0), "lon": (113.0, 154.0)}
print(f"Baseline: {len(MINES_DF)} curated mines loaded ✅")
```

**Why `os.environ.get("NB_RUN_DIR")`:** The R app passes run context via environment or config. This makes the same notebook work standalone AND inside the Shiny-managed run.

---

## 5. Cell 3 — ArcGIS Data Pull (full module)

This cell must contain ALL of: layer search, geographic validation, query, SDF creation. Do not split.

```python
# ── ArcGIS Data Pull ──────────────────────────────────────────────────────────

def is_australian(lyr, n=30, threshold=0.6):
    """Returns True only if ≥60% of sampled points fall within Australia's bbox."""
    try:
        fs = lyr.query(where="1=1", result_record_count=n,
                       out_fields="OBJECTID", return_geometry=True)
        pts = [(f.geometry["x"], f.geometry["y"]) for f in fs.features
               if f.geometry and "x" in f.geometry]
        if not pts:
            return False
        ok = sum(1 for x, y in pts
                 if AU_BBOX["lon"][0] <= x <= AU_BBOX["lon"][1]
                 and AU_BBOX["lat"][0] <= y <= AU_BBOX["lat"][1])
        return ok / len(pts) >= threshold
    except Exception:
        return False

# Search ArcGIS Online for Australian mining layers (validated before use)
MINE_SEARCH_TERMS = [
    "operating mines Australia commodity",
    "mineral deposits Australia FeatureServer",
    "OZMIN Geoscience Australia",
]
live_layer = None
for term in MINE_SEARCH_TERMS:
    try:
        results = gis.content.search(term, item_type="Feature Layer",
                                     max_items=10, outside_org=True)
        for item in results:
            if item.access != "public" or not item.layers:
                continue
            lyr = item.layers[0]
            if is_australian(lyr):
                live_layer = lyr
                print(f"✅ Live layer: '{item.title}' ({item.owner})")
                break
    except Exception as e:
        print(f"Search '{term}' failed: {e}")
    if live_layer:
        break

if live_layer is None:
    print("ℹ️  No validated live layer — using curated data only")

# Query live layer if found
live_sdf = None
if live_layer:
    try:
        # Check field names before querying
        fields = [f["name"] for f in live_layer.properties.fields]
        print(f"Fields: {fields}")
        fset = live_layer.query(where="1=1", out_fields="*",
                                return_geometry=True, result_record_count=500)
        live_sdf = fset.sdf
        print(f"Live SDF: {len(live_sdf)} records, columns: {live_sdf.columns.tolist()}")
    except Exception as e:
        print(f"⚠️  Live layer query failed: {e}")

# Surface elevation from Esri WorldElevation3D (public, no auth)
ELEV_URL = ("https://elevation3d.arcgis.com/arcgis/rest/services/"
            "WorldElevation3D/Terrain3D/ImageServer/identify")

def query_elevation(lat, lon, name, timeout=10):
    try:
        params = urllib.parse.urlencode({
            "geometry": json.dumps({"x": lon, "y": lat,
                                    "spatialReference": {"wkid": 4326}}),
            "geometryType": "esriGeometryPoint",
            "returnGeometry": "false", "f": "json"
        })
        with urllib.request.urlopen(f"{ELEV_URL}?{params}", timeout=timeout) as r:
            val = json.loads(r.read()).get("value")
        elev = round(float(val), 1) if val else None
    except Exception:
        elev = None
    if not elev:
        elev = float(ELEV_FALLBACK.get(name, 0))
    return elev

print("Querying elevations...")
MINES_DF["elevation_m"] = [query_elevation(r.lat, r.lon, r["name"])
                            for _, r in MINES_DF.iterrows()]
MINES_DF["pit_floor_m"] = MINES_DF.apply(
    lambda r: round(r.elevation_m - r.pit_depth_m, 1)
              if pd.notna(r.pit_depth_m) else None, axis=1)
print("Data pull complete:")
display(MINES_DF)
```

---

## 6. Cell 4 — ArcGIS Spatial Analysis (full module)

Contains geometry operations, SDF ops, field stats, coordinate projection. All in one cell.

```python
# ── ArcGIS Spatial Analysis ───────────────────────────────────────────────────
from arcgis.geometry import Point, Envelope
from arcgis.geometry.functions import project, distance

# Build FeatureSet from curated data (for MapContent.add())
from arcgis.features import FeatureSet, Feature
mine_features = []
for _, row in MINES_DF.iterrows():
    pt = Point({"x": row.lon, "y": row.lat, "spatialReference": {"wkid": 4326}})
    mine_features.append(Feature(geometry=pt, attributes={
        "name": row["name"], "state": row.state,
        "commodity": row.commodity,
        "elevation_m": str(row.elevation_m),
        "pit_depth_m": str(row.pit_depth_m) if pd.notna(row.pit_depth_m) else "unknown"
    }))
mine_fset = FeatureSet(features=mine_features)
print(f"FeatureSet: {len(mine_fset.features)} features ✅")

# Project to GDA94 MGA Zone 50 (WKID 32750) for metric distance calculations
# Note: project() operates on geometry objects, not the whole SDF
mine_points_wgs = [Point({"x": r.lon, "y": r.lat,
                           "spatialReference": {"wkid": 4326}})
                   for _, r in MINES_DF.iterrows()]
try:
    mine_points_gda = project(mine_points_wgs, in_sr=4326, out_sr=32750)
    print("Projected to GDA94 MGA Zone 50 ✅")
    # Distance from Kalgoorlie to each mine (in metres)
    kalgoorlie_gda = mine_points_gda[0]
    distances_km = [round(distance(kalgoorlie_gda, pt, units="9036") / 1000, 1)
                    for pt in mine_points_gda]
    MINES_DF["dist_from_kalgoorlie_km"] = distances_km
    print(MINES_DF[["name", "dist_from_kalgoorlie_km"]])
except Exception as e:
    print(f"Projection skipped: {e}")

# SDF statistics from live layer (if available)
if live_sdf is not None:
    # Adapt field names to whatever the live layer returned
    by_state = live_sdf.groupby("STATE")["OBJECTID"].count() if "STATE" in live_sdf.columns else None
    if by_state is not None:
        print("\nMines by state (live layer):")
        print(by_state.sort_values(ascending=False))

    # Spatial extent of live layer data
    extent_info = live_layer.properties.extent
    print(f"\nLive layer extent: {extent_info}")

    # Reproject SDF
    try:
        live_sdf_gda = live_sdf.spatial.project(32750)
        print(f"Live SDF reprojected: {len(live_sdf_gda)} records ✅")
    except Exception as e:
        print(f"SDF reproject skipped: {e}")

# Curated stats
print("\nCurated mine statistics:")
print(MINES_DF.groupby("commodity")[["pit_depth_m","elevation_m"]].mean().round(1))
print(f"\nDeepest mine: {MINES_DF.loc[MINES_DF.pit_depth_m.idxmax(), 'name']}")
print(f"Highest elevation: {MINES_DF.loc[MINES_DF.elevation_m.idxmax(), 'name']}")

# Geocode a mine address (demonstrates arcgis.geocoding)
try:
    from arcgis.geocoding import geocode
    result = geocode("Kalgoorlie-Boulder, Western Australia", max_locations=1)
    if result:
        loc = result[0]
        print(f"\nGeocode test: {loc['attributes']['Match_addr']} → {loc['location']}")
except Exception as e:
    print(f"Geocoding skipped: {e}")
```

---

## 7. Cell 5 — ArcGIS 2D Map (full module)

```python
# ── ArcGIS 2D Map ─────────────────────────────────────────────────────────────
from arcgis.map import Map

map_2d = Map()
map_2d.basemap.basemap = "satellite"
map_2d.zoom   = 4
map_2d.center = [-25.0, 133.0]   # [lat, lon] — geographic centre of Australia

# MapContent.add() with FeatureSet — CONFIRMED WORKING
try:
    map_2d.content.add(mine_fset, options={"title": "Australian Open Pit Mines"})
    print(f"✅ {len(mine_fset.features)} mine pins added")
except Exception as e:
    print(f"⚠️  FeatureSet add failed: {e}")

# Add validated live layer if it loaded
if live_layer is not None:
    try:
        map_2d.content.add(live_layer, options={"title": "Live Mining Data"})
        print("✅ Live layer added to map")
    except Exception as e:
        print(f"⚠️  Live layer on map skipped: {e}")

# Demonstrate SDF direct plot onto map widget
if live_sdf is not None:
    try:
        live_sdf.spatial.plot(map_widget=map_2d, renderer_type="s",
                              symbol_type="simple", symbol_style="circle",
                              col="OBJECTID")
        print("✅ SDF plotted directly on map widget")
    except Exception as e:
        print(f"⚠️  SDF plot skipped: {e}")

print("Layers in map:")
for i, lyr in enumerate(map_2d.content.layers):
    print(f"  {i}: {lyr}")

map_2d  # display widget
```

**ArcGIS Scene note for Agent 1:** Do NOT include `Scene()` unless a validated URL-backed `FeatureLayer` is available. `SceneContent.add(FeatureSet)` crashes with `no attribute 'properties'`. `SceneContent.add(FeatureCollection)` crashes with `no attribute '_url'`. Only FeatureLayer objects backed by a live REST URL work. If the live layer validated in Cell 3, attempt the Scene; otherwise skip it.

---

## 8. Cell 6 — Plotly 3D (comes AFTER all ArcGIS cells)

```python
# ── Plotly 3D Visualisation ───────────────────────────────────────────────────
import plotly.graph_objects as go

COLORS = {"Gold":"#FFD700","Iron Ore":"#E05C5C","Copper":"#D4873A",
          "Coal":"#888","Silver":"#D0D0D0"}
has_depth = MINES_DF.dropna(subset=["pit_floor_m"])
no_depth  = MINES_DF[MINES_DF.pit_floor_m.isna()]
fig = go.Figure()
added = set()

for _, row in has_depth.iterrows():
    c, col = row.commodity, COLORS.get(row.commodity, "#fff")
    show = c not in added; added.add(c)
    # Vertical bar surface→floor
    fig.add_trace(go.Scatter3d(x=[row.lon,row.lon], y=[row.lat,row.lat],
        z=[row.elevation_m, row.pit_floor_m], mode="lines",
        line=dict(color=col, width=6), showlegend=False, hoverinfo="skip"))
    # Surface marker
    fig.add_trace(go.Scatter3d(x=[row.lon], y=[row.lat], z=[row.elevation_m],
        mode="markers+text", text=[row["name"]], textposition="top center",
        textfont=dict(size=9, color="white"),
        marker=dict(size=10, color=col, line=dict(color="white",width=2)),
        name=c, legendgroup=c, showlegend=show,
        hovertemplate=f"<b>{row['name']}</b><br>Surface: {row.elevation_m:.0f}m<br>"
                      f"Pit depth: {int(row.pit_depth_m)}m<extra></extra>"))
    # Pit floor
    fig.add_trace(go.Scatter3d(x=[row.lon], y=[row.lat], z=[row.pit_floor_m],
        mode="markers", marker=dict(size=7, color=col, symbol="diamond",
        line=dict(color="white",width=1)), showlegend=False, legendgroup=c,
        hovertemplate=f"Pit floor: {row.pit_floor_m:.0f}m ASL<extra></extra>"))

for _, row in no_depth.iterrows():
    c, col = row.commodity, COLORS.get(row.commodity, "#fff")
    show = c not in added; added.add(c)
    fig.add_trace(go.Scatter3d(x=[row.lon], y=[row.lat], z=[row.elevation_m],
        mode="markers+text", text=[row["name"]], textposition="top center",
        textfont=dict(size=9, color="white"),
        marker=dict(size=9, color=col, symbol="circle-open",
                    line=dict(color=col,width=2)),
        name=c+" (no depth)", showlegend=show,
        hovertemplate=f"<b>{row['name']}</b><br>Surface: {row.elevation_m:.0f}m<br>Pit depth: unknown<extra></extra>"))

z_min = int(MINES_DF.pit_floor_m.dropna().min()) - 80
z_max = int(MINES_DF.elevation_m.max()) + 80
fig.update_layout(
    title=dict(text="<b>Australian Open Pit Mines — Elevation & Pit Depth</b>",
               font=dict(size=15, color="white"), x=0.5),
    scene=dict(
        xaxis=dict(title="Longitude", gridcolor="#333", backgroundcolor="#111"),
        yaxis=dict(title="Latitude",  gridcolor="#333", backgroundcolor="#111"),
        zaxis=dict(title="Elevation (m ASL)", gridcolor="#333",
                   backgroundcolor="#111", range=[z_min, z_max]),
        bgcolor="#111111",
        camera=dict(eye=dict(x=0.0, y=-2.2, z=1.0)),
        aspectmode="manual", aspectratio=dict(x=1.5, y=1.0, z=1.8)
    ),
    paper_bgcolor="#1a1a1a", font=dict(color="white"), height=680,
    legend=dict(bgcolor="#2a2a2a", bordercolor="#555", font=dict(color="white"))
)
fig.show()
print("✅ 3D chart rendered")
```

---

## 9. Cell 7 — Export

```python
# ── Export ────────────────────────────────────────────────────────────────────
import os
export_cols = ["name","state","commodity","lat","lon",
               "elevation_m","pit_depth_m","pit_floor_m"]
out_path = OUTPUT_CSV   # set in Cell 2 from RUN_DIR
MINES_DF[export_cols].to_csv(out_path, index=False)
print(f"✅ Exported {len(MINES_DF)} rows → {out_path}")

# Also save live layer if available
if live_sdf is not None:
    live_path = os.path.join(RUN_DIR, "live_mines.csv")
    live_sdf.drop(columns=["SHAPE"], errors="ignore").to_csv(live_path, index=False)
    print(f"✅ Live layer → {live_path}")

display(MINES_DF[export_cols])
```

---

## 10. Agent 1 (Writer) — Rules

1. **Always follow the cell sequence** in Section 2. Planner should map the spec to these cells.
2. **One cell = one complete module.** Never write half a function and finish it next cell.
3. **Authentication is always exactly:**
   ```python
   from arcgis.gis import GIS
   gis = GIS(profile="josephzr")
   ```
   No other auth pattern. No username/password. No URL argument.
4. **Output path always from `RUN_DIR`** — never hardcode paths.
5. **Every cell must end with a print statement** confirming success — the Verifier uses stdout.
6. **Wrap all network calls in try/except.** The notebook must run end-to-end even if ArcGIS Online is unreachable.
7. **Never use `Scene()` with in-memory data.** Only add `FeatureLayer(url)` to SceneContent.
8. **Never use `gis.properties.user`** — use `gis.users.me`.
9. **ArcGIS before Plotly.** Cells 1–5 must be fully ArcGIS. Plotly comes only after.
10. When fixing a rejected cell, fix ONLY what the Verifier flagged. Do not refactor unrelated code.

---

## 11. Agent 2 (Verifier) — Rules

Respond only with: `{"approved": bool, "feedback": "...", "risk": "low|medium|high"}`

**Approve if:**
- Cell executed without Python errors
- Print statements confirm the expected outcome
- ArcGIS API is used (not replaced by a workaround that avoids it)
- Cell is self-contained (doesn't rely on a variable not yet defined)

**Reject if:**
- Any unhandled exception in output
- Cell uses `gis.properties.user` (crashes anonymous)
- Cell uses `SceneContent.add(FeatureSet)` or `SceneContent.add(FeatureCollection)`
- Cell hardcodes output paths instead of using `RUN_DIR`/`OUTPUT_CSV`
- Plotly/non-ArcGIS code appears before Cell 6
- Cell imports something not in Cell 1 (breaks standalone re-run)
- Cell splits functionality that belongs together (half of spatial analysis in one cell, half in next)

**risk = high if:**
- Makes external network requests (flag, don't block — these are expected)
- Writes files to disk
- Could modify ArcGIS Online content

**Feedback format:** Be specific. "Line 14: `gis.properties.user` → use `gis.users.me`" not "fix the auth".

---

## 12. Confirmed Working / Broken API Reference

### ✅ Works (anonymous/public connection)

```python
gis.users.me                                    # safe anonymous check
gis.content.search("query", outside_org=True)   # public content search
gis.content.get("ITEM_ID")                      # get public item by ID
FeatureLayer("https://...FeatureServer/0")      # direct URL layer
lyr.query(where="1=1", out_fields="*")          # feature query
lyr.properties.fields                           # field metadata
lyr.properties.extent                           # spatial extent
fset.sdf                                        # SDF from query result
sdf.spatial.project(32750)                      # coordinate transform
sdf.spatial.plot(map_widget=m)                  # SDF → map widget
sdf.spatial.to_featureset()                     # SDF → FeatureSet
map_2d = Map()                                  # 2D map
map_2d.basemap.basemap = "satellite"            # set basemap
map_2d.zoom = 4                                 # set zoom
map_2d.center = [-25.0, 133.0]                 # set centre [lat, lon]
map_2d.content.add(fset, options={"title":…})  # FeatureSet on map ✅
map_2d.content.add(feature_layer)              # URL layer on map ✅
map_2d.content.layers                           # list layers
map_2d.content.remove(index)                    # remove layer
project([pt1, pt2], in_sr=4326, out_sr=32750) # reproject points
distance(pt1, pt2, units="9036")               # metric distance
geocode("address", max_locations=1)            # geocoding
```

### ❌ Broken / Do Not Use

```python
gis.properties.user.username        # AttributeError — crashes anonymous
SceneContent.add(FeatureSet)        # AttributeError: no attribute 'properties'
SceneContent.add(FeatureCollection) # AttributeError: no attribute '_url'
SceneContent.add(obj, options={…}) # TypeError: unexpected keyword 'options'
gis.map(mode="3D")                  # old API — use Scene()
from arcgis.mapping import WebMap   # old API — use Map()
```

### ⚠️ Works but requires caution

```python
Scene()                             # works but centers on North America by default
                                    # always set .center and .zoom before displaying
                                    # only add FeatureLayer(url) to SceneContent
gis.content.search(...)             # keyword match only — ALWAYS validate geographically
                                    # first result is often wrong category/country
FeatureLayer(hard_coded_url)        # URL may 404 or return non-Australian data
                                    # always run is_australian() validator first
```

---

## 13. Context Files to Drop in `context/` Folder

Before starting a run, drop these into the Shiny app's context folder:
- `ARCGIS_DATA_EXTRACTION_GUIDELINES.md` (already exists)
- `ARCGIS_MINING_HANDOFF.md` (previous session notes)
- This file (`NB_BUILDER_AGENT_GUIDELINES.md`)
- Any sample output CSVs from previous runs

The planner reads all of these and embeds them in `session.json` at run start. They are available to both agents for the entire session without re-uploading.

---

## 14. Aggregation Levels (for Task spec)

The R Shiny app spec should specify one of:

| Level | What it means | Cell 3 WHERE clause |
|---|---|---|
| National | All Australian mines | `"1=1"` |
| By state | Filter to one state | `"STATE = 'WA'"` |
| By commodity | Filter by resource type | `"COMMODITY LIKE '%Gold%'"` |
| Site-level | Specific named mines | `"NAME IN ('Kalgoorlie','Boddington')"` |
| Bounding box | Geographic region | Use `geometry=Envelope(...)` param |

For the curated baseline (when no live layer loads), aggregation is applied via pandas:
```python
MINES_DF[MINES_DF.state == "WA"]               # by state
MINES_DF[MINES_DF.commodity == "Gold"]         # by commodity
MINES_DF[MINES_DF.pit_depth_m > 300]          # by depth threshold
```
