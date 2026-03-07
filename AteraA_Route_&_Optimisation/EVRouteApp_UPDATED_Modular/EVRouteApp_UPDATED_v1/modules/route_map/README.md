# Route Map Module

Interactive Leaflet map visualization showing calculated routes and charging stations.

## Features
- Interactive map with zoom/pan
- Marker visualization (start, end, charging points)
- Route line display
- Legend and summary box

## Usage
1. Calculate a route in Route Optimizer module
2. Navigate to Route Map tab
3. Interact with map (zoom, click markers)

## Map Elements
- **Green marker:** Start point
- **Orange/Teal markers:** Charging points (teal = selected)
- **Red marker:** End point
- **Blue dashed lines:** Route segments

## Dependencies
- leaflet
- sf
- htmltools

## To Disable
In `modules/_module_registry.yml`:
```yaml
route_map:
  enabled: false
```
