# Integrated AV Development Suite v1.0

**Complete platform for autonomous vehicle route planning and simulation testing**

## Overview

This integrated application combines two powerful tools:
1. **EV Route Optimizer** - Real-world route planning with charging infrastructure
2. **Omniverse AR Simulation** - Virtual scenario generation and testing

## Features

### Route Planning (Tabs 1-4)
- **Tab 1: BigQuery Setup** - Connect to EV charging infrastructure database
- **Tab 2: Road Network** - Download OpenStreetMap road networks
- **Tab 3: Route Optimizer** - Calculate optimal routes through charging points
- **Tab 4: Route Map** - Interactive visualization of calculated routes

### Simulation Testing (Tabs 5-8)
- **Tab 5: Omniverse Connection** - Generate AV scenarios with traffic/weather conditions
- **Tab 6: Scenarios** - Browse and analyze simulation scenarios  
- **Tab 7: Route Preview** - Quality-scored trajectories with incident visualization
- **Tab 8: Advanced Visualization** - Advanced AR/VR capabilities

## Integration Feature

**Send to Simulator Button** in Route Optimizer (Tab 3):
- Automatically converts calculated routes to simulation scenarios
- Populates Omniverse with real route coordinates
- Enables virtual testing of real-world planned routes

## Installation

### Required Packages

```r
install.packages(c(
  # Core
  "shiny", "shinydashboard", "R6", "yaml", "purrr", "magrittr", "dplyr",
  
  # Route Optimizer
  "sf", "osmdata", "dodgr", "bigrquery", "leaflet", "htmltools",
  
  # Simulation
  "DT", "plotly", "jsonlite", "httr"
))
```

### Run Application

```r
setwd("path/to/IntegratedAVSuite")
shiny::runApp()
```

## Quick Start Workflow

### 1. Plan a Real Route
1. **BigQuery Setup:** Upload JSON key, connect to charging infrastructure
2. **Road Network:** Download network for your area (e.g., "Cambridge, UK")
3. **Route Optimizer:** Select origin/destination, calculate route
4. **Route Map:** View on interactive map

### 2. Test in Simulation
5. **Click "Send to Simulator"** in Route Optimizer
6. **Omniverse Connection:** Route auto-populated - select traffic/weather conditions
7. **Generate Scenarios:** Create multiple test variations
8. **Scenarios:** Analyze AV readiness and quality scores
9. **Route Preview:** View quality-coded trajectory with incidents

## Data Flow

```
Real World Planning          Virtual Testing
─────────────────            ───────────────
BigQuery (Tab 1)  ──┐
Road Network (Tab 2)│        
Route Calc (Tab 3) ─┼──> Send to Simulator ──> Omniverse (Tab 5)
Route Map (Tab 4)  ─┘                           Scenarios (Tab 6)
                                                 Preview (Tab 7)
                                                 Advanced (Tab 8)
```

## Configuration

### BigQuery (Pre-configured)
- Project: `atera-2`
- Dataset: `EVs_Infrastructure`
- Table: `Charge_Points_UK_EVs`

### Module Control
Edit `modules/_module_registry.yml` to enable/disable modules:

```yaml
route_optimizer:
  enabled: true  # Change to false to disable
```

## Architecture

- **Shared Manager:** Single `IntegratedAVManager` handles both BigQuery and Omniverse data
- **Reactive Triggers:** Cross-module communication via reactive values
- **Single-File Modules:** Each module in one .R file (UI + Server combined)
- **Unified CSS:** Corporate teal/cyan theme across all tabs

## File Structure

```
IntegratedAVSuite/
├── app.R                           # Entry point
├── global.R                        # Configuration
├── R/
│   ├── module_loader.R             # R6 ModuleLoader
│   ├── utils_integrated_manager.R  # Shared manager
│   └── utils_common.R              # Utilities
├── modules/
│   ├── _module_registry.yml        # Control center
│   ├── bigquery_connection.R       # Tab 1
│   ├── road_network.R              # Tab 2
│   ├── route_optimizer.R           # Tab 3 (with integration)
│   ├── route_map.R                 # Tab 4
│   ├── omniverse_connection.R      # Tab 5
│   ├── scenario_manager.R          # Tab 6
│   ├── route_preview.R             # Tab 7
│   └── advanced_visualization.R    # Tab 8
└── www/css/global.css              # Styling
```

## Integration Details

### Route to Simulation Conversion

When "Send to Simulator" is clicked:

1. **Extract Route Data:**
   - Origin/destination coordinates
   - GPS waypoints
   - Distance metrics

2. **Create Scenario:**
   ```json
   {
     "scenario_id": "route_20240209_1530",
     "origin": {"city": "Cambridge", "lat": 52.2053, "lon": 0.1218},
     "destination": {"city": "London", "lat": 51.5074, "lon": -0.1278},
     "road_type": "auto",
     "traffic": "moderate_congestion",
     "weather": "clear"
   }
   ```

3. **Populate Omniverse:**
   - Scenario added to scenario list
   - Auto-switch to Omniverse tab
   - Ready for traffic/weather variation generation

### Simulation Conditions

Generate scenarios with:
- **Traffic:** Free flow, light, moderate, heavy, rush hour
- **Weather:** Clear, rain, fog, night, dusk
- **Quality Scoring:** AV readiness classification (GREEN/AMBER/RED)
- **Incident Detection:** Hard braking, lane departure, sensor failures

## Use Cases

1. **Route Validation:** Plan EV route → Test under adverse conditions virtually
2. **Fleet Optimization:** Identify AV-ready routes before deployment  
3. **Safety Analysis:** Find high-risk zones via simulation before real testing
4. **Training Data:** Generate synthetic datasets for ML model training

## Troubleshooting

**Empty main body:** Check `global.R` - tabs must be built in FOR LOOP

**Road network fails:** Ensure all packages loaded in `global.R`, use valid location names

**Send to Simulator doesn't work:** Calculate a complete route first

**Scenarios not loading:** Check JSON format, try Demo Data first

## Support

- Each module has internal documentation
- Check console for error messages
- Review `app_error.log` for detailed errors

## Version History

- **v1.0.0** - Initial integrated release
  - Combined EV Route Optimizer + Omniverse Simulation
  - Added "Send to Simulator" integration
  - Unified BigQuery and scenario management
  - 8 fully functional modules

---

**Ready for autonomous vehicle development and testing!**
