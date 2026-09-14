# DriveSafe Suite - App Description for Flutter Integration

## Purpose of this document

This document describes a Shiny web application called the **DriveSafe Suite**, built in R. It is being shared with a separate Claude conversation that has access to a Flutter Android app containing a road risk heatmap. The goal is for that Flutter app's map rendering approach, data model, colour scheme, and UI patterns to be extracted and adapted into a new module for the DriveSafe Suite. This document gives that conversation everything it needs to understand what already exists so it can build the bridge correctly.

---

## What the DriveSafe Suite is

The DriveSafe Suite is an R Shiny dashboard application focused on monitoring the driving safety risk of professional commercial drivers who have been diagnosed with, or are being assessed for, **obstructive sleep apnoea (OSA)**. It is a research and operational tool built for a consortium including Human Experience Dynamics (HED, Cambridge), ATERA Analytics, and Royal Papworth Hospital.

The scientific premise is that OSA causes measurable behavioural changes in real-world driving — higher KSS alertness scores, longer reaction times, greater mind wandering, and more lane departure events — and that **CPAP treatment reduces these risk indicators toward control-group levels**. The app demonstrates this using simulated data modelled on a real dataset of 7,800+ journeys collected with Royal Papworth Hospital.

---

## Architecture

The app uses a **modular R Shiny architecture** with the following structure:

```
drivesafe_suite/
  app.R                          # Entry point
  global.R                       # UI/server builders, library loading
  R/
    module_loader.R              # R6 class: discovers modules via manifest.yml files
    utils_api.R                  # R6 APIManager: Claude API + BigQuery connections
    utils_common.R               # Shared parsing utilities
  www/css/global.css             # Full app theme (navy/teal/medical palette)
  modules/
    _module_registry.yml         # Defines sidebar groups and module order
    API Configuration/
      bigquery_auth/             # BigQuery connection to atera-2.business_strategy
      claude_api_config/         # Claude API credentials
    DriveSafe/
      driver_health_monitor/     # Main Tab 1: Driver Health
      driver_data_log/           # Main Tab 2: BigQuery data logging
      driver_ab_test/            # Main Tab 3: A/B treatment comparison
      driver_road_risk/          # Main Tab 4: Road Risk (partially built - needs Flutter input)
        driver_road_risk_map/
        driver_road_risk_corridors/
        driver_road_risk_interventions/
```

Each module has three files: `manifest.yml` (metadata and dependencies), `ui.R` (Shiny UI function named `<module_id>_ui`), and `server.R` (Shiny server function named `<module_id>_server`). They are discovered automatically by the `ModuleLoader` R6 class.

---

## Sidebar structure

The app has two collapsible sidebar groups:

**API Configuration**
- BigQuery Setup — connects to `atera-2.business_strategy.driver_health_log`
- Claude API Config — Claude Sonnet 4.6 with streaming SSE

**DriveSafe - Driver Health**
- Health Monitor
- Data Log
- A/B Test
- Road Risk Map ← **this is where the Flutter map module feeds in**
- High-Risk Corridors
- Risk Interventions

---

## Visual theme

The CSS theme is defined in `www/css/global.css` and uses the following palette:

| Variable | Hex | Use |
|---|---|---|
| `--ds-navy` | `#0A1628` | Sidebar, header, page banner backgrounds |
| `--ds-teal` | `#008A82` | Primary accent, box headers, buttons |
| `--ds-teal-lt` | `#00A39A` | Lighter teal highlights |
| `--ds-red` | `#e74c3c` | High-risk alerts, OSA untreated group |
| `--ds-amber` | `#f39c12` | Moderate risk, warnings |
| `--ds-green` | `#27ae60` | Low risk, CPAP treated group, success states |
| `--ds-blue` | `#2980b9` | Info states, rest area markers |

Risk score colour scale used across all visualisations:
- 0–25: `#1a6b35` (dark green — Low)
- 25–50: `#d4ac0d` (amber — Moderate)
- 50–75: `#e67e22` (orange — High)
- 75–100: `#c0392b` (dark red — Critical)

The map background uses **CartoDB DarkMatter** (dark tile layer) via Leaflet in R.

---

## The three driver groups used throughout the app

All simulated data and visualisations consistently use three named groups:

| R string | Label | Description |
|---|---|---|
| `"control"` | Control (No OSA) | Drivers with no sleep apnoea diagnosis. Teal colour. |
| `"osa_treated"` | OSA - CPAP Treated | OSA-diagnosed drivers receiving CPAP therapy. Green. |
| `"osa_untreated"` | OSA - Untreated | OSA-diagnosed drivers not yet on treatment. Red. |

Eight fictional drivers are used for filtering: D001 Adams J (control), D002 Patel R (OSA treated), D003 Okafor C (control), D004 Williams S (OSA untreated), D005 Hassan M (control), D006 Chen L (control), D007 Thompson K (OSA treated), D008 Singh P (OSA untreated).

---

## Module 1: Driver Health Monitor (fully built)

**File:** `modules/DriveSafe/driver_health_monitor/`

Four subtabs inside a single sidebar item:

**Live Overview** — KSS alertness timeline across journey hours for four drivers, journey-hour slider that simulates progression in real time, a radar chart of current driver state across five dimensions (Alertness, Reaction, Focus, Consistency, OSA Safety), and a driving behaviour chart showing speed variance, hard braking and lane events over journey duration.

**Alertness and Fatigue** — Metric selector (KSS / Mind Wandering / Perceived Effort / Reaction Time), fleet mean KSS readout, high-fatigue event count, scatter plot of selected metric vs journey hour coloured by driver, a stacked bar chart of fatigue severity distribution across all drivers, and a day-of-week vs hour-of-day alertness heatmap.

**Sleep and OSA** — Checkbox group to toggle four indicators (EDS/KSS, Speed Consistency, Lateral Variance, OSA Composite). The plot draws **group-mean lines** (not raw scatter) binned into 0.5-hour journey windows, with one line per OSA group per selected indicator, distinguished by colour, dash style, and marker symbol. Also includes an OSA risk classification pie chart and a sleep quality vs reaction time scatter coloured by group.

**Cognitive Performance** — PVT reaction time histogram with configurable lapse threshold slider (coloured red above threshold), cognitive load vs journey duration area chart, and lapses-per-driver bar chart.

All data in this module is **simulated locally** using `set.seed()` — no BigQuery connection required.

---

## Module 2: Driver Data Log (fully built)

**File:** `modules/DriveSafe/driver_data_log/`

Two subtabs:

**Generate and Upload** — Controls to select drivers, set journeys per driver, max journey duration, group composition (OSA untreated / OSA treated / control), and a random seed for reproducibility. Generates a data frame with columns: `driver_id`, `driver_name`, `osa_group`, `cpap_treated`, `journey_id`, `journey_date`, `journey_hour`, `journey_duration_h`, `kss_score`, `reaction_time_ms`, `mind_wander_idx`, `osa_risk_score`, `sleep_quality`, `speed_variance`, `hard_braking_n`, `lane_events_n`, `pvt_lapses_n`, `recorded_at`. Preview table uses conditional colour formatting on KSS and OSA risk columns. Upload button pushes to BigQuery table `atera-2.business_strategy.driver_health_log`.

**Browse Records** — Filters by driver and OSA group, queries BigQuery, displays in DT table, downloadable as CSV.

---

## Module 3: Driver A/B Test (fully built)

**File:** `modules/DriveSafe/driver_ab_test/`

Single full-page panel. No subtabs. Content:

- Four KPI value boxes: KSS delta between treated and untreated, RT improvement in ms, OSA risk reduction in points, PVT lapse reduction
- Hypothesis banner explaining the CPAP treatment comparison
- Violin plots for KSS and reaction time by group
- Box plots for OSA composite and mind wandering by group
- Journey evolution line chart with metric selector, confidence interval toggle, and smoothing window slider
- Summary statistics DT table with treatment effect annotation
- Normalised multi-metric performance heatmap (three groups × seven metrics, 0–100 scale, green=better)
- Per-driver delta bar chart against the untreated OSA baseline

A **Re-simulate** button re-seeds the random data generator so the analyst can explore variance.

---

## Module 4: Road Risk Map (partially built — needs Flutter input)

**File:** `modules/DriveSafe/driver_road_risk/driver_road_risk_map/`

**What exists:** A full Shiny Leaflet map with:
- CartoDB DarkMatter base tile layer
- Simulated UK road network data covering 17 corridors (M1, M6, M25, M4, M62, M8, M74, A1, A30, A14, A55, A57, A406 North Circular, B-roads West Midlands, Urban Leeds, Urban Manchester, Urban Birmingham)
- Risk scoring formula: `base_risk[road_type] + osa_group_uplift + journey_hour_component × time_of_day_multiplier + noise`
- Circle markers sized by road type, coloured by risk score using the green/amber/orange/red scale
- Filters for OSA group, road type, time window, journey duration
- Incident markers (8 historic near-miss records with lat/lon)
- Rest area markers (12 UK motorway services)
- Click-to-detail side panel showing corridor name, road type, observations, and a mini bar chart of risk by group
- KPI boxes for high-risk percentage, mean risk score, critical corridors, and CPAP treatment lift
- Time-of-day line chart and road-type grouped bar chart below the map
- Risk distribution donut chart in the side panel

**What is missing / needs replacing with Flutter patterns:**
- The heatmap layer rendering — the Flutter app uses a proper continuous heatmap (not circle markers). The Flutter approach needs to be translated into `leaflet.extras::addHeatmap()` or a custom tile overlay in R.
- The exact colour gradient, intensity scaling, and radius parameters from the Flutter implementation
- Any animated or time-slider behaviour the Flutter app has
- The specific data structure the Flutter app uses for road segments (whether it is point-based, polyline-based, or grid-based)
- Any legend or overlay UI patterns from the Flutter app worth replicating

---

## Module 5: High-Risk Corridors (fully built)

**File:** `modules/DriveSafe/driver_road_risk/driver_road_risk_corridors/`

- Top-10 corridor horizontal bar chart (untreated vs treated vs control, toggle by group)
- Treatment effect lollipop chart by road type (shows delta between red untreated dot and green treated dot per road type)
- Corridor × time-of-day heatmap (17 corridors × 5 time windows, green-to-red scale)
- Journey duration risk profile line chart (short/medium/long × three groups)
- Full DT corridor risk table with conditional formatting, sortable by untreated risk, CPAP benefit delta, or control risk
- CSV download

---

## Module 6: Risk Interventions (UI built, server partially built)

**File:** `modules/DriveSafe/driver_road_risk/driver_road_risk_interventions/`

- Scenario builder panel: treatment status radio (none / CPAP new / CPAP established / mandibular device), rest break frequency slider, break duration slider, route optimisation checkboxes (avoid night driving, cap journey at 4h, prefer motorways), clinical monitoring checkboxes (monthly review, CPAP telemetry)
- Two risk gauges side by side: baseline (untreated OSA) and scenario (after interventions applied)
- Waterfall chart showing contribution of each intervention to risk reduction
- CPAP adherence trajectory: per-driver risk convergence toward control over 52 weeks, with a week slider
- Action plan cards by driver risk profile (four tiers: critical / high / moderate / low)
- Fleet-level projection: sliders for fleet size, OSA prevalence, and CPAP uptake — projects total risk reduction across the fleet with a before/after chart

The server for this module needs completing — the gauge outputs, waterfall, and fleet projection charts need their render functions written.

---

## BigQuery connection

- Project: `atera-2`
- Dataset: `business_strategy`
- Table: `driver_health_log`
- Schema: `id, created_at, driver_id, driver_name, osa_group, cpap_treated, journey_id, journey_date, journey_hour, journey_duration_h, kss_score, reaction_time_ms, mind_wander_idx, osa_risk_score, sleep_quality, speed_variance, hard_braking_n, lane_events_n, pvt_lapses_n, recorded_at`
- Authentication: Google Cloud service account JSON (uploaded via UI in BigQuery Setup tab)
- The `APIManager` R6 class in `R/utils_api.R` handles all BigQuery operations via `bigrquery` package

---

## What the Flutter conversation needs to produce

Given the Flutter app's road risk heatmap code, the target output for the DriveSafe Suite is:

1. **A replacement or enhancement of the `driver_road_risk_map` server.R** that uses the same heatmap rendering approach (translated to R Leaflet / leaflet.extras), the same colour gradient and intensity logic, and the same data structure where applicable

2. **A complete server.R for `driver_road_risk_interventions`** with all render functions for the gauge charts, waterfall, CPAP trajectory, action plan cards, and fleet projection

3. **Any CSS additions** to `www/css/global.css` needed to match visual elements from the Flutter UI that are worth replicating in the Shiny context (panel styling, legend cards, risk badge treatments)

The output should follow the exact module pattern: one `server.R` per module, functions named `<module_id>_server`, with `moduleServer(id, function(input, output, session) { ... })` wrapping all logic.

---

## Key R packages in use

`shiny`, `shinydashboard`, `R6`, `yaml`, `purrr`, `shinyjs`, `httr`, `curl`, `jsonlite`, `bigrquery`, `DT`, `plotly`, `dplyr`, `stringr`, `tidyr`, `leaflet`, `leaflet.extras`

All packages are declared in `global.R` and in individual module `manifest.yml` dependency lists.
