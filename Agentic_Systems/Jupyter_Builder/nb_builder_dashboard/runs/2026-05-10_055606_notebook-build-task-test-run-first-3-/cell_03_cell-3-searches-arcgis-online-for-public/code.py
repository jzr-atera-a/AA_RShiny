# ── Cell 3: ArcGIS Data Pull ──────────────────────────────────────────────────
# Search for public Australian mining layers, validate geographically,
# and query valid layer to SDF

# Australia bounding box for geographic validation
AUS_LAT_MIN, AUS_LAT_MAX = -45, -10
AUS_LON_MIN, AUS_LON_MAX = 113, 154

def is_in_australia(lat, lon):
    """Check if coordinates fall within Australia bounding box."""
    return (AUS_LAT_MIN <= lat <= AUS_LAT_MAX and 
            AUS_LON_MIN <= lon <= AUS_LON_MAX)

def validate_layer_geography(layer, sample_size=20, threshold=0.6):
    """
    Validate a layer by sampling points and checking if >= threshold
    fall within Australia bounding box.
    """
    try:
        # Query a sample of features
        result = layer.query(where="1=1", result_record_count=sample_size, out_sr=4326)
        features = result.features
        
        if not features:
            return False, 0, 0
        
        in_aus_count = 0
        total_valid = 0
        
        for feature in features:
            geom = feature.geometry
            if geom is None:
                continue
            
            # Handle different geometry types - extract centroid/point
            if 'x' in geom and 'y' in geom:
                lon, lat = geom['x'], geom['y']
            elif 'rings' in geom:  # Polygon - use centroid approximation
                ring = geom['rings'][0]
                lon = sum(p[0] for p in ring) / len(ring)
                lat = sum(p[1] for p in ring) / len(ring)
            elif 'paths' in geom:  # Polyline - use midpoint
                path = geom['paths'][0]
                mid_idx = len(path) // 2
                lon, lat = path[mid_idx][0], path[mid_idx][1]
            else:
                continue
            
            total_valid += 1
            if is_in_australia(lat, lon):
                in_aus_count += 1
        
        if total_valid == 0:
            return False, 0, 0
        
        ratio = in_aus_count / total_valid
        return ratio >= threshold, in_aus_count, total_valid
        
    except Exception as e:
        print(f"    Validation error: {e}")
        return False, 0, 0

# Search for public Australian mining layers
print("Searching ArcGIS Online for public Australian mining layers...")
search_results = gis.content.search(
    query="australia mining mines",
    item_type="Feature Layer",
    outside_org=True,
    max_items=15
)

print(f"Found {len(search_results)} candidate items")

# Validate each result geographically
valid_layer = None
valid_item = None

for item in search_results:
    print(f"\nChecking: {item.title}")
    print(f"  Owner: {item.owner}, Views: {item.numViews}")
    
    try:
        # Get the feature layer(s) from the item
        layers = item.layers if hasattr(item, 'layers') else []
        
        if not layers:
            print("  No layers found, skipping...")
            continue
        
        for idx, layer in enumerate(layers):
            print(f"  Layer {idx}: {layer.properties.name if hasattr(layer.properties, 'name') else 'unnamed'}")
            
            is_valid, in_aus, total = validate_layer_geography(layer)
            
            if total > 0:
                print(f"    Geographic validation: {in_aus}/{total} points in Australia ({in_aus/total*100:.1f}%)")
            
            if is_valid:
                print("    ✓ VALID - meets 60% threshold")
                valid_layer = layer
                valid_item = item
                break
            else:
                print("    ✗ Does not meet geographic threshold")
        
        if valid_layer:
            break
            
    except Exception as e:
        print(f"  Error accessing item: {e}")
        continue

# Query valid layer to SDF
if valid_layer is not None:
    print(f"\n{'='*60}")
    print(f"Querying valid layer: {valid_item.title}")
    
    # Query all features to Spatially-enabled DataFrame
    mining_sdf = valid_layer.query(where="1=1", out_sr=4326).sdf
    
    print(f"Retrieved {len(mining_sdf)} features")
    print(f"Columns: {list(mining_sdf.columns)}")
    print(f"\nFirst 5 rows preview:")
    print(mining_sdf.head())
else:
    print("\nNo valid Australian mining layer found in search results")
    mining_sdf = pd.DataFrame()

print("\nArcGIS Data Pull OK")