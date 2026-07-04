# ArcGIS API for Python — Data Extraction Guidelines

## Critical: Read This First

**Environment:** Python 3.x with ArcGIS API 2.4+  
**Authentication:** Anonymous/public access via profile `josephzr`  
**Focus:** Data extraction, querying, and spatial operations (NOT visualization/publishing)

---

## Authentication Pattern (REQUIRED)

```python
from arcgis.gis import GIS

# Connect to your GIS - anonymous/public access
gis = GIS(profile="josephzr")
```

**Expected Behavior:**
- ✅ Keyring warning about missing password is **NORMAL and HARMLESS**
- ✅ Connection works for public/anonymous access
- ✅ `gis.users.me` works and returns anonymous user info
- ❌ `gis.properties.user` CRASHES with anonymous connection (use `gis.users.me` instead)

---

## Core Data Extraction Patterns

### 1. Feature Layer Query (Primary Data Extraction Method)

**This is your main tool for extracting GIS data from ArcGIS Online/Enterprise.**

```python
from arcgis.features import FeatureLayer

# Connect to a public feature layer by URL
layer_url = "https://services.arcgis.com/ORGID/arcgis/rest/services/LayerName/FeatureServer/0"
lyr = FeatureLayer(layer_url)

# Query all features (max 500-2000 depending on server config)
fset = lyr.query(
    where="1=1",                    # SQL where clause (1=1 = all records)
    out_fields="*",                 # All fields, or ["field1", "field2"]
    return_geometry=True,           # Include spatial geometry
    result_record_count=500,        # Limit results (max varies by server)
    return_all_records=False        # Set True to auto-paginate (can be slow)
)

# Extract to different formats
features_list = fset.features       # List of Feature objects
sdf = fset.sdf                      # Spatially Enabled DataFrame
geojson = fset.to_geojson          # GeoJSON dict
dict_list = [f.as_dict for f in fset.features]  # List of dicts
```

**SQL Filtering Examples:**
```python
# Single condition
fset = lyr.query(where="state='WA'")

# Multiple conditions
fset = lyr.query(where="state='WA' AND commodity='Gold'")

# Numeric range
fset = lyr.query(where="depth_m > 200 AND depth_m < 500")

# Text pattern matching
fset = lyr.query(where="mine_name LIKE '%Gold%'")

# NULL checks
fset = lyr.query(where="commodity IS NOT NULL")

# Date ranges (dates in 'YYYY-MM-DD' format)
fset = lyr.query(where="date_opened >= '2010-01-01'")
```

**CRITICAL RULES:**
- ✅ Always wrap in try/except - many public layers have rate limits or auth issues
- ✅ Start with small `result_record_count` (e.g., 50) to test before fetching thousands
- ✅ Use `return_all_records=True` ONLY if you need all data and can wait
- ❌ Never assume a layer has all fields populated - check with `lyr.properties.fields`
- ❌ Never blindly trust search results - always validate data geographically (see validation below)

---

### 2. Spatially Enabled DataFrame (SDF) - The Power Tool

**SDF extends Pandas DataFrame with spatial operations. This is the MOST UNDERUSED feature.**

```python
# Get SDF from query result
sdf = lyr.query(where="1=1", out_fields="*", return_geometry=True).sdf

# SDF has a SHAPE column (geometry) - always present when return_geometry=True
print(sdf.columns)  # [..., 'SHAPE']
print(sdf.spatial.sr)  # Spatial reference info

# Standard Pandas operations work
wa_mines = sdf[sdf['state'] == 'WA']
gold_mines = sdf[sdf['commodity'] == 'Gold']
deep_mines = sdf[sdf['depth_m'] > 300]

# Group by and aggregate
by_state = sdf.groupby('state')['OBJECTID'].count()
avg_depth = sdf.groupby('commodity')['depth_m'].mean()

# Access geometry
for idx, row in sdf.iterrows():
    geom = row['SHAPE']
    if geom.geometry_type == 'point':
        x, y = geom.coordinates()
        print(f"Point at {x}, {y}")
```

**SDF Spatial Operations:**
```python
# Reproject to different coordinate system
sdf_gda = sdf.spatial.project(32750)  # WGS84 → GDA94 MGA Zone 50

# Convert back to FeatureSet (for adding to maps or further processing)
fset = sdf.spatial.to_featureset()

# Get bounding box
bbox = sdf.spatial.full_extent

# Spatial filter (if you have a polygon)
subset = sdf[sdf.spatial.within(polygon_geometry)]
```

**Export SDF:**
```python
# To CSV (drop SHAPE column first - it's not CSV-serializable)
sdf.drop(columns=['SHAPE']).to_csv('output.csv', index=False)

# To GeoJSON
sdf.spatial.to_featureset().to_geojson

# To Shapefile
sdf.spatial.to_featureset().save(save_location='/path/to/output.shp')
```

**CRITICAL SDF RULES:**
- ✅ Geometry column is ALWAYS named `SHAPE` in SDF
- ✅ Drop `SHAPE` before CSV export or JSON serialization
- ✅ Use `sdf.spatial.project()` for coordinate transformations
- ✅ Use `sdf.spatial.to_featureset()` to convert back to ArcGIS objects
- ❌ Never try to pickle or serialize SDF with SHAPE column intact
- ❌ Never assume SDF has same methods as regular DataFrame for all operations

---

### 3. Searching for Public Data

```python
# Search ArcGIS Online for public data
results = gis.content.search(
    query="Australia mines",
    item_type="Feature Layer",  # or "Feature Service"
    max_items=20,
    outside_org=True,           # CRITICAL: searches all of AGOL, not just your org
    sort_field="relevance",
    sort_order="desc"
)

# Examine results
for item in results:
    print(f"Title: {item.title}")
    print(f"Owner: {item.owner}")
    print(f"ID: {item.id}")
    print(f"URL: {item.url}")
    print("---")

# Get a specific item by ID
item = gis.content.get("ITEM_ID_STRING_HERE")

# Access layers from item
if item.layers:
    first_layer = item.layers[0]
    # Now query as normal
    fset = first_layer.query(where="1=1", out_fields="*")
```

**CRITICAL SEARCH RULES:**
- ✅ ALWAYS include `outside_org=True` for public AGOL searches
- ✅ ALWAYS validate results geographically before trusting (see validation section)
- ✅ Search results are ranked by relevance, not accuracy
- ❌ NEVER assume first result is correct - we've gotten hydrogen ports as "mines", Brazilian forest as "oil/gas"
- ❌ NEVER assume layer name matches content - validate with sample data
- ❌ Search terms like "mine" return mining, undermining, determination, etc.

---

### 4. Geographic Validation (CRITICAL FOR AUSTRALIAN DATA)

**Always validate that search results actually contain Australian data.**

```python
# Australia bounding box (WGS84 / EPSG:4326)
AU_BOX = {
    "lat": (-45, -10),    # South to North
    "lon": (113, 154)     # West to East
}

def is_australian(lyr, sample_size=30, threshold=0.6):
    """
    Test if a FeatureLayer contains Australian geographic data.
    
    Args:
        lyr: FeatureLayer object
        sample_size: Number of features to sample
        threshold: Minimum fraction that must be in Australia (0.6 = 60%)
    
    Returns:
        True if layer contains Australian data, False otherwise
    """
    try:
        # Query sample features
        fs = lyr.query(
            where="1=1",
            result_record_count=sample_size,
            out_fields="OBJECTID",
            return_geometry=True
        )
        
        # Extract coordinates
        points = []
        for f in fs.features:
            if f.geometry and 'x' in f.geometry:
                points.append((f.geometry['x'], f.geometry['y']))
        
        if not points:
            return False
        
        # Count points in Australia
        in_australia = sum(
            1 for x, y in points
            if AU_BOX["lon"][0] <= x <= AU_BOX["lon"][1]
            and AU_BOX["lat"][0] <= y <= AU_BOX["lat"][1]
        )
        
        # Return True if threshold met
        return (in_australia / len(points)) >= threshold
        
    except Exception as e:
        print(f"Validation failed: {e}")
        return False

# Usage
search_results = gis.content.search("Australian mines", item_type="Feature Layer", 
                                     max_items=10, outside_org=True)
for item in search_results:
    if item.layers:
        layer = item.layers[0]
        if is_australian(layer):
            print(f"✅ VALID: {item.title}")
            # Safe to use this layer
        else:
            print(f"❌ INVALID: {item.title} (not Australian data)")
```

**VALIDATION RULES:**
- ✅ ALWAYS validate before using search results for Australian projects
- ✅ Check at least 30 features (sample_size=30)
- ✅ Require 60% threshold minimum (0.6)
- ✅ Increase threshold to 0.8 or 0.9 for critical applications
- ❌ Never skip validation even if layer name looks correct

---

### 5. Geometry Operations

```python
from arcgis.geometry import Point, Polygon, Envelope
from arcgis.geometry.functions import project, distance, buffer

# Create geometries
pt1 = Point({
    "x": 121.5082,
    "y": -30.7701,
    "spatialReference": {"wkid": 4326}  # WGS84
})

pt2 = Point({
    "x": 116.4658,
    "y": -32.7917,
    "spatialReference": {"wkid": 4326}
})

# Project coordinates between spatial references
pts_gda = project(
    geometries=[pt1, pt2],
    in_sr=4326,   # WGS84
    out_sr=32750  # GDA94 MGA Zone 50
)

# Calculate distance between points (returns list of distances)
dist = distance(
    spatial_ref=4326,
    geometry1=pt1,
    geometry2=pt2,
    distance_unit="kilometers"
)
print(f"Distance: {dist[0]:.2f} km")

# Create buffer around point
buffered = buffer(
    geometries=[pt1],
    in_sr=4326,
    distances=[10],
    unit="kilometers",
    out_sr=4326
)

# Create bounding box
bbox = Envelope({
    "xmin": 113,
    "ymin": -45,
    "xmax": 154,
    "ymax": -10,
    "spatialReference": {"wkid": 4326}
})

# Use bbox in query
fset = lyr.query(
    where="1=1",
    geometry=bbox,
    geometry_type="esriGeometryEnvelope",
    spatial_rel="esriSpatialRelIntersects"
)
```

**Spatial Reference IDs (Common Australian SRs):**
- 4326: WGS84 (lat/lon decimal degrees)
- 3857: Web Mercator (used by most web maps)
- 28350: GDA94 MGA Zone 50 (Western Australia)
- 28351: GDA94 MGA Zone 51
- 28352: GDA94 MGA Zone 52
- 28353: GDA94 MGA Zone 53
- 28354: GDA94 MGA Zone 54 (Eastern Australia)
- 28355: GDA94 MGA Zone 55
- 28356: GDA94 MGA Zone 56

**GEOMETRY RULES:**
- ✅ Always specify `spatialReference` when creating geometries
- ✅ Use `wkid` (Well-Known ID) for standard coordinate systems
- ✅ Project to local CRS (e.g., MGA zones) for accurate distance/area calculations
- ❌ Never do distance calculations in lat/lon (EPSG:4326) - results are inaccurate
- ❌ Never mix spatial references without explicit projection

---

### 6. Field Information Extraction

```python
# Get layer properties
layer_url = "https://services.arcgis.com/.../FeatureServer/0"
lyr = FeatureLayer(layer_url)

# Examine all fields
for field in lyr.properties.fields:
    print(f"Name: {field['name']}")
    print(f"Type: {field['type']}")
    print(f"Alias: {field.get('alias', 'N/A')}")
    print(f"Editable: {field.get('editable', False)}")
    print(f"Nullable: {field.get('nullable', True)}")
    print("---")

# Get field names only
field_names = [f['name'] for f in lyr.properties.fields]

# Check if specific field exists
has_commodity = 'commodity' in field_names

# Get field types
field_types = {f['name']: f['type'] for f in lyr.properties.fields}

# Layer metadata
print(f"Layer Name: {lyr.properties.name}")
print(f"Geometry Type: {lyr.properties.geometryType}")
print(f"Spatial Reference: {lyr.properties.spatialReference}")
print(f"Max Record Count: {lyr.properties.maxRecordCount}")
print(f"Supports Pagination: {lyr.properties.get('supportsPagination', False)}")

# Get extent (bounding box)
extent = lyr.properties.extent
print(f"Extent: {extent}")
```

**Field Type Reference:**
- `esriFieldTypeString`: Text
- `esriFieldTypeInteger`: Whole numbers
- `esriFieldTypeDouble`: Decimal numbers
- `esriFieldTypeDate`: Date/time
- `esriFieldTypeOID`: Object ID (unique identifier)
- `esriFieldTypeGeometry`: Spatial geometry
- `esriFieldTypeGlobalID`: Global unique ID (UUID)

---

### 7. Pagination for Large Datasets

**When you need more than the default record limit (usually 500-2000 records):**

```python
def query_all_features(layer, where="1=1", out_fields="*", batch_size=500):
    """
    Query all features from a layer using pagination.
    
    Args:
        layer: FeatureLayer object
        where: SQL where clause
        out_fields: Fields to return
        batch_size: Records per request
    
    Returns:
        Combined FeatureSet with all records
    """
    all_features = []
    offset = 0
    
    while True:
        # Query batch
        fset = layer.query(
            where=where,
            out_fields=out_fields,
            return_geometry=True,
            result_offset=offset,
            result_record_count=batch_size
        )
        
        features = fset.features
        if not features:
            break
        
        all_features.extend(features)
        offset += batch_size
        
        print(f"Retrieved {len(all_features)} features so far...")
        
        # Safety limit
        if offset > 50000:
            print("WARNING: Reached safety limit of 50k records")
            break
    
    # Create combined FeatureSet
    from arcgis.features import FeatureSet
    combined = FeatureSet(all_features)
    
    return combined

# Usage
all_data = query_all_features(lyr, where="state='WA'", batch_size=1000)
sdf = all_data.sdf
```

**Alternative: Use return_all_records**
```python
# Automatic pagination (simpler but blocks until complete)
fset = lyr.query(
    where="1=1",
    out_fields="*",
    return_geometry=True,
    return_all_records=True  # Handles pagination automatically
)
```

**PAGINATION RULES:**
- ✅ Use manual pagination when you need progress feedback
- ✅ Use `return_all_records=True` for simple queries where you can wait
- ✅ Always implement safety limits (e.g., max 50k records)
- ✅ Test with small batches first (batch_size=50) to check data quality
- ❌ Never run pagination without a safety limit - some layers have millions of records
- ❌ Never assume pagination will complete - network errors happen

---

### 8. Working with Different Geometry Types

```python
# Query features
fset = lyr.query(where="1=1", out_fields="*", return_geometry=True)

for feature in fset.features:
    geom = feature.geometry
    
    # Point geometry
    if 'x' in geom and 'y' in geom:
        x, y = geom['x'], geom['y']
        print(f"Point: ({x}, {y})")
        if 'z' in geom:
            print(f"Elevation: {geom['z']}")
    
    # Polyline geometry
    elif 'paths' in geom:
        for path in geom['paths']:
            print(f"Line has {len(path)} vertices")
            for vertex in path:
                x, y = vertex[0], vertex[1]
    
    # Polygon geometry
    elif 'rings' in geom:
        for ring in geom['rings']:
            print(f"Polygon ring has {len(ring)} vertices")
            # First ring is outer boundary
            # Subsequent rings are holes
    
    # Multipoint geometry
    elif 'points' in geom:
        print(f"Multipoint has {len(geom['points'])} points")

# Convert to Well-Known Text (WKT)
from arcgis.geometry import Geometry
geom_obj = Geometry(feature.geometry)
wkt = geom_obj.WKT

# Convert to GeoJSON
geojson = geom_obj.__geo_interface__
```

---

### 9. Geocoding (Address to Coordinates)

```python
from arcgis.geocoding import geocode

# Geocode single address
results = geocode("Kalgoorlie, Western Australia")
if results:
    first_result = results[0]
    location = first_result['location']
    x, y = location['x'], location['y']
    print(f"Coordinates: {y}, {x}")  # lat, lon
    print(f"Address: {first_result['address']}")
    print(f"Score: {first_result['score']}")

# Batch geocode
addresses = [
    "Perth, WA",
    "Sydney, NSW",
    "Melbourne, VIC"
]

for addr in addresses:
    results = geocode(addr, max_locations=1)
    if results:
        loc = results[0]['location']
        print(f"{addr}: ({loc['y']}, {loc['x']})")
```

**GEOCODING RULES:**
- ✅ Always check if results list is not empty
- ✅ Check the `score` field (0-100) - 80+ is good, <70 is questionable
- ✅ Geocode returns `x, y` (lon, lat) - reverse for display as lat, lon
- ❌ Free tier has daily limits - don't geocode thousands without credits
- ❌ Never assume first result is correct - validate with score

---

### 10. Elevation Data Extraction (Public REST API)

**Note: This uses direct REST API calls, NOT the ArcGIS Python SDK**

```python
import urllib.request
import json

def get_elevation(lat, lon):
    """
    Get elevation for a point using ArcGIS World Elevation service.
    
    Args:
        lat: Latitude (WGS84)
        lon: Longitude (WGS84)
    
    Returns:
        Elevation in meters (float) or None if failed
    """
    url = "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer/identify"
    
    params = {
        "geometry": json.dumps({
            "x": lon,
            "y": lat,
            "spatialReference": {"wkid": 4326}
        }),
        "geometryType": "esriGeometryPoint",
        "f": "json"
    }
    
    query_string = "&".join(f"{k}={v}" for k, v in params.items())
    full_url = f"{url}?{query_string}"
    
    try:
        with urllib.request.urlopen(full_url) as response:
            data = json.loads(response.read())
            if 'value' in data:
                # Returns string, convert to float
                return float(data['value'])
    except Exception as e:
        print(f"Elevation query failed: {e}")
    
    return None

# Usage
elev = get_elevation(-30.7701, 121.5082)  # Kalgoorlie
if elev is not None:
    print(f"Elevation: {elev:.2f} meters")
```

**ELEVATION RULES:**
- ✅ This is a public REST endpoint, no authentication needed
- ✅ Returns elevation in meters
- ⚠️ Some locations return 0.0 (e.g., Boddington mine) - use fallback values
- ❌ Not part of ArcGIS Python SDK - use urllib or requests
- ❌ No batch endpoint - query one point at a time

---

## What WORKS ✅

### Data Query & Extraction
- ✅ `FeatureLayer.query()` with all parameters
- ✅ SQL WHERE clauses (all standard operators)
- ✅ `FeatureSet.sdf` → Spatially Enabled DataFrame
- ✅ `sdf.spatial.project()` - coordinate transformation
- ✅ `sdf.spatial.to_featureset()` - convert back to ArcGIS objects
- ✅ Pagination with `result_offset` and `result_record_count`
- ✅ `return_all_records=True` for automatic pagination
- ✅ Field filtering with `out_fields=["field1", "field2"]`
- ✅ Geometry filtering with bounding boxes
- ✅ Spatial relationship queries (intersects, contains, within)

### Search & Discovery
- ✅ `gis.content.search()` with `outside_org=True`
- ✅ `gis.content.get(item_id)`
- ✅ `item.layers[0]` to access feature layers from items
- ✅ Layer property inspection (`lyr.properties.fields`, `lyr.properties.extent`)

### Geometry Operations
- ✅ `project()` - coordinate system transformation
- ✅ `distance()` - calculate distances between geometries
- ✅ `buffer()` - create buffer polygons
- ✅ Point, Polygon, Envelope creation
- ✅ Geometry conversion to WKT, GeoJSON

### DataFrame Operations
- ✅ All standard Pandas operations on SDF
- ✅ `sdf.spatial.full_extent` - get bounding box
- ✅ `sdf.drop(columns=['SHAPE']).to_csv()` - export to CSV
- ✅ Filtering, groupby, aggregation on SDF

---

## What FAILS ❌

### Authentication Issues
- ❌ `gis.properties.user.username` - crashes with anonymous connection
- ❌ `gis.save()`, `item.save()` - requires Publisher role
- ❌ Publishing hosted feature layers - requires authentication
- ❌ Editing features - requires edit permissions

### Search Issues
- ❌ Search results without geographic validation - returns wrong regions
- ❌ Assuming first search result is accurate
- ❌ Trusting layer names without sampling data
- ❌ Using search terms that are too generic ("mine" matches many non-mining layers)

### Query Issues
- ❌ Querying without checking `maxRecordCount`
- ❌ Assuming all fields are populated (many are NULL)
- ❌ Using pagination without safety limits
- ❌ Querying layers without testing sample first

### Data Issues
- ❌ Some public layers have incorrect metadata
- ❌ Some layers return 404 even though they appear in search
- ❌ Coordinate systems not always specified correctly
- ❌ Field names inconsistent across similar layers

---

## Critical Gotchas & Edge Cases

### 1. Anonymous Connection Warnings
```python
gis = GIS(profile="josephzr")
# WARNING: Keyring password not found - THIS IS NORMAL
# Connection still works for public access
```

### 2. The SHAPE Column
```python
sdf = lyr.query(...).sdf
# sdf has SHAPE column - cannot be serialized to CSV/JSON
sdf.drop(columns=['SHAPE']).to_csv('output.csv')  # Required
```

### 3. Coordinate Order Confusion
```python
# ArcGIS geometry: {"x": lon, "y": lat}
# Display format: (lat, lon)
point = {"x": 121.5, "y": -30.7}  # Stored as x=lon, y=lat
print(f"Location: {point['y']}, {point['x']}")  # Display as lat, lon
```

### 4. maxRecordCount Varies
```python
# Some servers: 500, some: 1000, some: 2000
# Always check first:
print(lyr.properties.maxRecordCount)
```

### 5. Elevation Service Returns Zeros
```python
# Boddington mine (-32.79, 116.47) returns 0.0
# Always have fallback elevation values
FALLBACK_ELEVATIONS = {
    "Boddington": 270,
    "Kalgoorlie": 380,
    # etc.
}
```

### 6. Search Returns Non-Geographic Results
```python
# "Australian mines" can return:
# - Hydrogen production facilities
# - Port facilities
# - Brazilian forest data (wrong continent!)
# ALWAYS validate with is_australian() function
```

### 7. Layer Properties Can Be Incomplete
```python
# Some layers missing:
# - Extent information
# - Spatial reference
# - Field aliases
# Always check with hasattr() or .get()
```

### 8. SDF Spatial Reference
```python
# SDF inherits SR from query
# If layer is in 4326, SDF is in 4326
# Use sdf.spatial.project() to change
sdf_projected = sdf.spatial.project(32750)
```

---

## Recommended Data Extraction Workflow

```python
# Step 1: Connect
from arcgis.gis import GIS
gis = GIS(profile="josephzr")

# Step 2: Search for data
results = gis.content.search(
    query="Australian mineral deposits",
    item_type="Feature Layer",
    max_items=15,
    outside_org=True
)

# Step 3: Validate results
AU_BOX = {"lat": (-45, -10), "lon": (113, 154)}

def is_australian(lyr, sample_size=30):
    try:
        fs = lyr.query(where="1=1", result_record_count=sample_size,
                       out_fields="OBJECTID", return_geometry=True)
        pts = [(f.geometry['x'], f.geometry['y']) for f in fs.features
               if f.geometry and 'x' in f.geometry]
        if not pts:
            return False
        ok = sum(1 for x, y in pts
                 if AU_BOX["lon"][0] <= x <= AU_BOX["lon"][1]
                 and AU_BOX["lat"][0] <= y <= AU_BOX["lat"][1])
        return ok / len(pts) >= 0.6
    except:
        return False

valid_layers = []
for item in results:
    if item.layers:
        lyr = item.layers[0]
        if is_australian(lyr):
            valid_layers.append((item, lyr))
            print(f"✅ {item.title}")

# Step 4: Extract data from validated layer
if valid_layers:
    item, lyr = valid_layers[0]
    
    # Check field structure
    print("Fields:", [f['name'] for f in lyr.properties.fields])
    
    # Query with appropriate filters
    fset = lyr.query(
        where="1=1",  # Or specific filter
        out_fields="*",
        return_geometry=True,
        return_all_records=True  # Get all data
    )
    
    # Convert to SDF
    sdf = fset.sdf
    
    # Data quality checks
    print(f"Records: {len(sdf)}")
    print(f"Columns: {sdf.columns.tolist()}")
    print(f"Null counts:\n{sdf.isnull().sum()}")
    
    # Export
    sdf.drop(columns=['SHAPE']).to_csv('extracted_data.csv', index=False)
    print("✅ Data extracted successfully")

# Step 5: Spatial operations (if needed)
from arcgis.geometry.functions import project

# Project to local coordinate system for accurate measurements
sdf_gda = sdf.spatial.project(32750)  # GDA94 MGA Zone 50

# Calculate distances, buffers, etc.
# ...
```

---

## Testing & Debugging Checklist

Before running production queries:

1. **Test layer accessibility:**
   ```python
   try:
       test = lyr.query(where="1=1", result_record_count=1)
       print("✅ Layer accessible")
   except Exception as e:
       print(f"❌ Layer failed: {e}")
   ```

2. **Check field structure:**
   ```python
   fields = [f['name'] for f in lyr.properties.fields]
   print(f"Available fields: {fields}")
   ```

3. **Validate geographic extent:**
   ```python
   extent = lyr.properties.extent
   print(f"Extent: {extent}")
   # Check if extent covers Australia
   ```

4. **Test with small sample:**
   ```python
   sample = lyr.query(where="1=1", result_record_count=10)
   print(f"Sample size: {len(sample.features)}")
   # Inspect sample data before querying all
   ```

5. **Check for nulls:**
   ```python
   sdf = sample.sdf
   print(sdf.isnull().sum())
   ```

---

## Common Error Messages & Solutions

### "Token Required"
- **Cause:** Trying to access private layer
- **Solution:** Find public alternative or get authentication

### "Max record count exceeded"
- **Cause:** Requesting too many records at once
- **Solution:** Use pagination or `return_all_records=True`

### "Invalid SQL syntax"
- **Cause:** WHERE clause syntax error
- **Solution:** Test with `where="1=1"` first, then add filters

### "'FeatureSet' object has no attribute 'sdf'"
- **Cause:** Old ArcGIS API version
- **Solution:** Update to 2.0+

### "Geometry type not supported"
- **Cause:** Trying to use geometry operation on wrong type
- **Solution:** Check `geometryType` in layer properties

### "Spatial reference not defined"
- **Cause:** Layer missing SR information
- **Solution:** Explicitly define when creating geometries

---

## Performance Optimization Tips

### 1. Limit Fields
```python
# Don't request all fields if you don't need them
fset = lyr.query(
    where="1=1",
    out_fields=["OBJECTID", "name", "state"],  # Not "*"
    return_geometry=False  # If you don't need geometry
)
```

### 2. Use Spatial Filters
```python
# Don't query entire layer if you only need a region
from arcgis.geometry import Envelope

wa_bbox = Envelope({
    "xmin": 113, "ymin": -35,
    "xmax": 129, "ymax": -15,
    "spatialReference": {"wkid": 4326}
})

fset = lyr.query(
    where="1=1",
    geometry=wa_bbox,
    spatial_rel="esriSpatialRelIntersects"
)
```

### 3. Batch Intelligently
```python
# Use appropriate batch size
# Too small = many requests
# Too large = timeout risk
# Sweet spot usually 500-1000
```

### 4. Cache Results
```python
# Don't re-query if you already have the data
if not os.path.exists('cached_data.pkl'):
    fset = lyr.query(...)
    sdf = fset.sdf
    sdf.to_pickle('cached_data.pkl')
else:
    sdf = pd.read_pickle('cached_data.pkl')
```

---

## ArcGIS API Features NOT Covered (Require Authentication)

These require authenticated connection with appropriate permissions:

- ❌ Publishing hosted feature layers
- ❌ Creating/editing features
- ❌ Version management
- ❌ Branch versioning
- ❌ Parcel fabric operations
- ❌ Network analysis (routing)
- ❌ GeoEnrichment (requires credits)
- ❌ Raster analysis
- ❌ Saving web maps/scenes to AGOL
- ❌ Sharing items
- ❌ User/group management

For these features, you need:
```python
gis = GIS("https://www.arcgis.com", "username", "password")
# Or OAuth, API key, etc.
```

---

## Quick Reference: Essential Imports

```python
# Core
from arcgis.gis import GIS

# Features
from arcgis.features import FeatureLayer, FeatureSet, Feature, FeatureCollection

# Geometry
from arcgis.geometry import Point, Polygon, Polyline, Envelope, Geometry
from arcgis.geometry.functions import project, distance, buffer

# Geocoding
from arcgis.geocoding import geocode, reverse_geocode

# Standard Python
import pandas as pd
import json
import urllib.request
```

---

## End Notes

This guide focuses on **data extraction and querying** with anonymous/public access. For visualization, map creation, and publishing, refer to separate visualization guidelines.

**Remember:**
1. Always validate search results geographically
2. Test with small samples before large queries
3. Handle errors gracefully (many public layers have issues)
4. Drop SHAPE column before CSV export
5. Check maxRecordCount before pagination
6. Use appropriate spatial reference for calculations

**Last Updated:** Based on ArcGIS API for Python 2.4+
