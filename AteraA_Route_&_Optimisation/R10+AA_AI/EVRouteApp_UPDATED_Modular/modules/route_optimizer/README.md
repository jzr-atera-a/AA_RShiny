# Route Optimizer Module

Calculates optimal routes through EV charging stations using shortest path algorithms.

## Features
- Address geocoding
- Nearest charging station search
- Multi-point route optimization
- Distance calculations

## Usage
1. Select origin and destination addresses
2. Choose number of charging points to consider
3. Click "Calculate Optimal Route"
4. View route summary and charging point details
5. Click "View Route Map" to see visualization

## Dependencies
- tmaptools (geocoding)
- dodgr (routing)
- sf (spatial data)
- dplyr

## Requirements
- BigQuery connection must be active
- Road network must be downloaded

## To Disable
In `modules/_module_registry.yml`:
```yaml
route_optimizer:
  enabled: false
```
