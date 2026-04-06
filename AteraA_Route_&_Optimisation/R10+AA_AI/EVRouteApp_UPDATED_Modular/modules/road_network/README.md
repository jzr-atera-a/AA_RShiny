# Road Network Module

Downloads and processes road networks from OpenStreetMap for EV route optimization.

## Features
- Location-based network download
- Automatic road type filtering
- Routing graph creation with dodgr
- Network statistics and validation

## Usage
1. Enter location name (e.g., "Cambridge, England")
2. Click "Download Road Network"
3. Wait for processing (10-60 seconds)
4. View network statistics

## Dependencies
- osmdata
- sf
- dplyr
- tmaptools
- dodgr

## To Disable
In `modules/_module_registry.yml`:
```yaml
road_network:
  enabled: false
```
