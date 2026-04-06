# Welch Group Fleet Monitor v1.0

**Live fleet telemetry dashboard for EV Artic trucks via Volvo Group vehicle API**

## Target Fleet

| Registration | Label         | Type              |
|--------------|---------------|-------------------|
| TA70 WTL     | EV Artic 1    | Electric Artic    |
| N88 GNW      | EV Artic 2    | Electric Artic    |

---

## Architecture

Modular R Shiny app, one file per tab, mirroring the IntegratedAVSuite pattern:

```
WelchGroupFleet/
├── app.R                          # Entry point
├── global.R                       # Packages, factories, shared manager
├── R/
│   ├── module_loader.R            # R6 ModuleLoader
│   ├── utils_common.R             # Helpers
│   └── utils_api_manager.R        # VehicleAPIManager R6 (Volvo Group API)
├── modules/
│   ├── _module_registry.yml       # Enable/disable tabs
│   ├── api_connection.R           # Tab 1: Auth + vehicle discovery
│   └── vehicle_data.R             # Tab 2: Queries + analytics
└── www/css/global.css             # Dark teal/navy theme
```

---

## Quick Start

### 1. Install packages

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr", "magrittr", "dplyr",
  "httr", "jsonlite", "leaflet", "htmltools", "plotly", "DT"
))
```

### 2. Run

```r
setwd("path/to/WelchGroupFleet")
shiny::runApp()
```

---

## Tab 1 – API Connection

- Enter **Username / API Key** and **Password / Secret** from the Renault Trucks Developer Portal
- Click **Test Connection** — authenticates against `api.renault-trucks.com/vehicle/vehicles`
- Connection status shown (green = connected, HTTP 200)
- Vehicle list returned by API displayed in a table
- **Refresh Vehicle List** re-fetches without re-entering credentials
- Credentials are held in memory only (never written to disk)

### Authentication

The API uses **HTTPS Basic Authentication** (Base64-encoded `username:password`).  
Header: `Authorization: Basic <base64>`  
Content-Type: `application/x.volvogroup.com.vehicles.v1.0+json; UTF-8`

---

## Tab 2 – Vehicle Data

### Query controls

| Control          | Description |
|------------------|-------------|
| Vehicle selector | All, TA70WTL, N88GNW |
| Query type       | Vehicles / Positions / Statuses |
| Start / End date | Time window for positions and statuses |
| Latest only      | Return most recent record only |
| Trigger filter   | TIMER, IGNITION_ON, IGNITION_OFF, DRIVER_ID, TELL_TALE |

### Result panels

| Panel               | Contents |
|---------------------|---------|
| Data Table          | All returned fields, sortable/exportable (CSV, Excel) |
| Geographic Map      | Leaflet dark map, markers sized by speed, colour per VIN, optional route polyline |
| Trends & Charts     | Speed over time, heading rose, speed histogram (positions); fuel/battery level, odometer, engine hours, weight distribution (statuses) |
| Statistics & Metadata | Row/column counts, memory size, numeric summary stats (min/mean/median/max/SD), geographic bounding box, GNSS fix rate |
| Raw API Response    | Pretty-printed JSON |

### API Endpoints used

| Endpoint              | Purpose |
|-----------------------|---------|
| `GET /vehicles`       | Vehicle metadata: VIN, brand, model, emission level, fuel type |
| `GET /vehiclepositions` | GPS lat/lon, heading, altitude, GNSS speed, wheel speed, tacho speed |
| `GET /vehiclestatuses`  | Fuel level, odometer, engine hours, accumulated fuel, gross weight, driver ID |

---

## Demo Data

Click **Load Demo Data** in Tab 2 to explore the UI without an active API connection.  
Demo data simulates two EV Artic vehicles with synthetic GPS tracks and status records.

---

## Configuration

Edit `modules/_module_registry.yml` to enable/disable tabs:

```yaml
modules:
  - module:
      id: api_connection
      enabled: true   # set false to hide tab
```

---

## API Reference

- Base URL: `https://api.renault-trucks.com/vehicle`
- Spec: Volvo Group vehicle APIs v1.0.6
- Portal: [developer.renault-trucks.com](https://developer.renault-trucks.com)

### HTTP status codes

| Code | Meaning |
|------|---------|
| 200  | OK |
| 400  | Bad request (malformed params) |
| 401  | Unauthorised (wrong/expired credentials) |
| 403  | Forbidden (insufficient rights, response too large) |
| 404  | Not found (vehicle unknown, API version unsupported) |
| 406  | Not acceptable (unsupported Accept header) |
| 429  | Too many requests (rate limited) |
