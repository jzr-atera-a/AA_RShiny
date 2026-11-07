# DriveSafe Suite — Functionality Overview & Template Guide

**What this document is:** a complete description of what the DriveSafe Suite does today, how it's built, and a practical guide for reusing its architecture to build new apps — particularly ones combining **health monitoring, AI/LLM features, and external data sources**.

---

## 1. What the app is

The DriveSafe Suite is an R Shiny dashboard for monitoring driving-safety risk in commercial drivers with (or being assessed for) **obstructive sleep apnoea (OSA)**. It's built for a research/operational consortium (Human Experience Dynamics, ATERA Analytics, Royal Papworth Hospital) around one core premise: OSA measurably degrades driving safety (alertness, reaction time, lane control), and **CPAP treatment pulls those indicators back toward control-group levels**. Everything in the app — the health dashboards, the road-risk heatmap, the intervention scenario builder — exists to make that premise visible, explorable, and actionable.

All data in the app is **simulated**, seeded for reproducibility, and structured to mirror the shape of a real 7,800+ journey dataset the consortium collected with Royal Papworth Hospital.

---

## 2. Functional walkthrough

### 2.1 Sidebar structure

The app has three collapsible sidebar groups, each a "main tab" containing several "subtab" modules:

```
API Configuration
  ├─ BigQuery Setup
  └─ Claude API Config

DriveSafe - Driver Health
  ├─ Health Monitor
  ├─ Data Log
  └─ A/B Test

OSA Road Risk & Interventions
  ├─ Road Risk Map
  ├─ High-Risk Corridors
  └─ Risk Interventions
```

### 2.2 API Configuration group

**BigQuery Setup** — Upload a Google Cloud service-account JSON (file or pasted text), set project/dataset IDs (defaults to `atera-2` / `business_strategy`), authenticate, and the target table (`driver_health_log`) is created automatically if missing. Everything else in the app (Health Monitor, A/B Test, Road Risk group) works fully offline without this — only the Data Log module's *upload/browse* actions need a live connection.

**Claude API Config** — Store a Claude API key and pick a model; test the connection; this is what a future "AI insights" feature elsewhere in the app would call.

Both of these are thin UI wrappers around one shared object: **`APIManager`**, an R6 class in `R/utils_api.R` that centralizes all external-service calls (see §3.3).

### 2.3 DriveSafe — Driver Health group

**Health Monitor** — four sub-views in one module:
- *Live Overview*: KSS alertness timeline across journey hours, a journey-hour slider that simulates progression in real time, a 5-axis radar of current driver state (Alertness / Reaction / Focus / Consistency / OSA Safety), and a driving-behaviour chart (speed variance, hard braking, lane events vs journey duration).
- *Alertness & Fatigue*: metric selector (KSS / Mind Wandering / Perceived Effort / Reaction Time), fleet-mean KSS, high-fatigue event count, a scatter of the selected metric vs journey hour, a fatigue-severity stacked bar, and a day-of-week × hour-of-day alertness heatmap.
- *Sleep & OSA*: toggleable indicators (EDS/KSS, Speed Consistency, Lateral Variance, OSA Composite) plotted as **group-mean lines** (not raw points) binned into 0.5h windows, one line per OSA group per indicator — plus an OSA risk-classification pie and a sleep-quality-vs-reaction-time scatter.
- *Cognitive Performance*: PVT reaction-time histogram with an adjustable lapse threshold, a cognitive-load-vs-duration area chart, lapses-per-driver bars.

All data here is generated locally with `set.seed()` — no external dependency.

**Data Log** — *Generate & Upload*: pick drivers, journeys/driver, max duration, group composition, and a seed; generates a full journey-log data frame (driver/journey metadata + KSS, reaction time, mind-wandering, OSA risk, sleep quality, speed variance, hard-braking count, lane events, PVT lapses); preview table has conditional colour formatting; upload pushes to BigQuery. *Browse Records*: filter by driver/group, query BigQuery, view in a DT table, download CSV.

**A/B Test** — a single-page comparison of the three driver groups: four KPI boxes (KSS delta, RT improvement, OSA risk reduction, PVT lapse reduction), violin/box plots by group, a journey-evolution line chart with confidence-interval toggle and smoothing, a summary stats table, a normalised multi-metric heatmap, and a per-driver delta chart against the untreated baseline. A **Re-simulate** button reseeds the data so an analyst can explore variance.

### 2.4 OSA Road Risk & Interventions group

This is the newest group, built to answer: *where and when is OSA-related driving risk highest across a UK road network, and what interventions actually reduce it?*

**Road Risk Map** — an interactive `plotly` `scattermapbox` map (see §3.4 for why plotly and not leaflet) of 17 simulated UK corridors (M1, M6, M25, M4, M62, M8, M74, A1, A30, A14, A55, A57, A406, B-roads West Midlands, Urban Leeds/Manchester/Birmingham), each following real intermediate waypoints rather than straight lines. Four toggleable layers: a continuous risk heatmap (colour **and size** scaled by score), clickable corridor markers (open a side panel with a full calculation breakdown), 8 near-miss incident markers, and rest-area/sleep-clinic markers. Filters: OSA group, time-of-day window, road types, journey duration, heatmap radius/opacity. KPI boxes (% high-risk corridors, mean risk, critical-corridor count, CPAP risk reduction) and two supporting charts (risk by time-of-day, risk by road type) sit below the map.

**High-Risk Corridors** — ranks all 17 corridors, a top-10 bar chart toggleable by group, a treatment-effect lollipop chart by road type, a corridor × time-of-day heatmap, a duration-based risk-profile chart, and a full sortable/downloadable DT table.

**Risk Interventions** — a scenario builder: treatment status (none / CPAP new / CPAP established / mandibular device), rest-break frequency & duration, route-optimisation checkboxes (avoid night driving, cap journey length, prefer motorways), clinical-monitoring checkboxes (monthly review, CPAP telemetry). Outputs: before/after risk gauges, a waterfall showing each intervention's contribution to the reduction, a 52-week CPAP-adherence trajectory for four OSA drivers, tiered action-plan cards (Critical/High/Moderate/Low), and a fleet-level projection (fleet size × OSA prevalence × CPAP uptake sliders → mean fleet risk before/after, estimated high-risk journeys avoided/month).

---

## 3. How it's built — the architecture worth reusing

This is the part to actually copy when building the next app.

### 3.1 Manifest-driven, auto-discovered modules

```
drivesafe_suite/
  app.R                 # entry point
  global.R              # library() calls, source()s, builds ui/server via ModuleLoader
  R/
    module_loader.R      # R6 class: discovers modules, builds sidebar + tabItems
    utils_api.R           # R6 APIManager: all external-service calls
    utils_road_risk.R     # example of a shared *domain* data/logic file
  www/css/global.css      # one theme for the whole app
  modules/
    _module_registry.yml  # groups (main tabs) + per-module enabled/priority/description
    <Group Folder>/
      <module_id>/
        manifest.yml       # id, menu label/icon/badge, package dependencies
        ui.R                # `<module_id>_ui(id)` — a `tagList(...)`
        server.R            # `<module_id>_server(id, api_manager)` — a `moduleServer(...)`
```

**Why this matters for a template:** adding a whole new feature area is *additive*, not invasive. To add a new main tab with subtabs you:
1. Create `modules/<NewGroup>/<new_module>/{manifest.yml, ui.R, server.R}` for each subtab.
2. Add one `groups:` entry and N `modules:` entries to `_module_registry.yml`.
3. Nothing else changes. `ModuleLoader` recursively scans for `manifest.yml` files (ignoring `_`-prefixed folders), reads each module's declared package list, and calls `module_loader$load_packages()` once at startup (in `app.R`) — so **a module's dependencies live with the module**, not in a central file you have to remember to edit.

### 3.2 One shared theme, everywhere

`www/css/global.css` defines the whole visual language as CSS variables (`--ds-navy`, `--ds-teal`, `--ds-red`, `--ds-amber`, `--ds-green`, `--ds-blue`) plus a risk-score colour scale (green/amber/orange/red at 25/50/75 breakpoints) used consistently across every chart, badge, and table in the app. New modules inherit this for free just by using `shinydashboard::box()`, the existing risk-badge/legend-card/tier-card CSS classes, and the same colour constants from whatever shared utils file they source.

### 3.3 One `APIManager` R6 class for all external calls

`R/utils_api.R` centralizes every external-service interaction behind one object (constructed once, passed into every module's server function as `api_manager`):

- **Claude / LLM**: `set_claude_credentials()`, `test_claude_connection()`, `call_claude()` (streaming-capable), `diagnose_network()`.
- **BigQuery**: `set_bigquery_credentials()`, `authenticate_bigquery()`, `bq_query()`, plus domain-specific helpers like `bq_insert_driver_log()`.

**Why this matters for a template:** any new module that needs to call an LLM or a database doesn't reinvent auth/error-handling — it just calls `api_manager$call_claude(prompt)` or `api_manager$bq_query(sql)`. The **API Configuration** group's two modules (`bigquery_auth`, `claude_api_config`) are just thin UI shells that call `set_*_credentials()`/`authenticate_*()` on this shared object. Add a third external service (e.g. a weather API, a clinical-trials registry, a different LLM provider) by adding one more method to `APIManager` and one more config module — every other module in the app can then use it immediately.

### 3.4 Domain logic lives in one shared file per feature area

`R/utils_road_risk.R` is the pattern: a single source of truth for a feature area's **data generation, scoring formulas, colour scales, and label lookups**, sourced once in `global.R` and imported by every module in that group. All three Road Risk modules read from the same `uk_osa_corridors`, `osa_risk_score()`, `OSA_GROUP_LABELS`, etc. — so a number never drifts between the map, the corridor table, and the intervention gauges. When you extend the formula or recalibrate constants, you edit one file and every module picks it up.

This module group also has an `osa_risk_breakdown()` helper that returns a score's components (base risk, uplift, duration effect, time multiplier, noise, total) as a list — used to build human-readable "why is this score X?" text in hovers and side panels. **This pattern — a scoring function plus a paired breakdown function — is worth reusing anywhere a computed metric needs to be explainable**, which matters a lot in a health/clinical context.

### 3.5 Lesson learned: keep mapping/geospatial dependency-free

The Road Risk Map went through three iterations that are worth knowing about before you build a new map-based module:

1. `{leaflet}` + `{leaflet.extras}` for a JS heatmap plugin — broke because `leaflet.extras` wasn't installed in the deployment environment.
2. Plain `{leaflet}` with `addTiles()` — worked locally, but **`renv::snapshot()` on shinyapps.io failed** because `{leaflet}` itself has a hard `Imports:` dependency on `{raster}`, which in turn requires `{terra}` (a compiled, GDAL-linked package that's fragile to install in hosted environments) — regardless of whether your code ever calls a raster function.
3. `plotly::plot_ly(type = "scattermapbox", ...)` — the fix. `{plotly}` is already a dependency everywhere in this app, has zero geospatial/compiled dependencies, supports several free basemap styles with no API token (`open-street-map`, `carto-positron`, `carto-darkmatter`, `stamen-*`, `white-bg`), and supports click events (`plotly::event_data("plotly_click", source=...)`) and imperative view control (`plotlyProxy()` + `plotlyProxyInvoke("relayout", ...)`) — enough to replicate everything `leaflet` was doing (clickable markers, toggleable layers, a live-updating view) without the dependency risk.

**Template rule of thumb:** for any new app that needs a map, default to `plotly` scattermapbox/choropleth unless there's a specific reason (e.g. true vector tile rendering, drawing tools) that only `leaflet` provides — and if you do reach for `leaflet`, pin/verify its transitive dependency tree before deploying.

### 3.6 Calibrating a "risk score" so it's actually informative

A worth-recording lesson from tuning the road-risk formula: a scoring model can be *logically correct* and still be *useless as a visualization* if its parameters push every realistic input into one category. The fix wasn't more code, it was recalibrating constants and re-testing the **output distribution** under representative default inputs — not just testing that the formula ran without error. When you build a new risk/severity score for a future app: simulate it across your default UI state, check the category distribution (you want visible presence across your full colour scale, not 95% in one bucket), and only then wire it into the UI.

---

## 4. Using this as a template — a practical playbook

### 4.1 Starting a related app from scratch

The fastest path to a new app in this family is: **copy the whole `drivesafe_suite/` folder, gut the domain-specific modules, keep everything in §3.** Concretely:

1. Keep unchanged: `app.R`, `global.R`, `R/module_loader.R`, `R/utils_api.R`, `www/css/global.css` (recolour the CSS variables for a new brand if needed), `modules/_module_registry.yml` structure (clear out the module lists).
2. Keep the **API Configuration** group as-is if the new app also needs BigQuery + Claude — it's fully generic.
3. Write a new `R/utils_<domain>.R` following the `utils_road_risk.R` pattern: data generation + scoring formula(s) + colour scale + label lookups + a breakdown helper.
4. Write one module folder per subtab, following the `driver_ab_test` or `driver_road_risk_map` pattern (`manifest.yml` + `ui.R` + `server.R`), each declaring only the packages it actually needs.
5. Register the new group + modules in `_module_registry.yml`.

### 4.2 Building the *health* dimension of a new app

Reuse the **Health Monitor / Data Log / A/B Test** trio as a template for any "monitor a population against a condition, log data, compare treatment groups" problem:
- `driver_health_monitor` → any multi-view real-time/simulated monitoring dashboard (radar chart for current state, time-series for trend, heatmap for temporal patterns).
- `driver_data_log` → the generate/simulate + upload-to-BigQuery + browse/download pattern is domain-agnostic; swap the column schema.
- `driver_ab_test` → the violin/box + journey-evolution + normalised-heatmap + per-subject-delta combination is a reusable "compare N cohorts" template for any health-outcomes comparison, not just OSA.

### 4.3 Building the *AI* dimension

The `APIManager$call_claude()` method (streaming-capable) plus the `claude_api_config` module is the seed for adding real LLM-backed features to any of these apps — e.g. a "explain this driver's risk profile in plain language" button that pipes a driver's current metrics into a prompt, or a "summarise this week's fleet trends" panel. Pattern to follow: keep the LLM call in `APIManager`, keep the UI for it in a normal module, and pass `api_manager` into that module's server function exactly like every existing module does. For anything long-running or streaming, follow the `call_claude()` implementation's SSE-handling approach as the template.

### 4.4 Building the *external sources* dimension

The `bigquery_auth` module is the template for **any** "authenticate once, use everywhere" external connector: same pattern applies to a REST API, a different cloud data warehouse, a clinical registry, or a public dataset API. Steps: (1) add credential-storage + connection-test methods to `APIManager`, (2) add a thin config module that calls them, (3) any module that needs the data calls `api_manager$<your_method>()`. This keeps credential handling in exactly one place regardless of how many modules eventually consume that source.

### 4.5 Checklist for a new module group

- [ ] New folder under `modules/`, one subfolder per subtab
- [ ] Each subtab has `manifest.yml` (id, menu label/icon, **only the packages it needs**), `ui.R` (`<id>_ui(id)`), `server.R` (`<id>_server(id, api_manager)`)
- [ ] Shared domain logic in one `R/utils_<domain>.R`, sourced from `global.R`
- [ ] New group + modules registered in `modules/_module_registry.yml`
- [ ] Any score/metric has a paired "breakdown" function for explainability
- [ ] Any map uses `plotly` scattermapbox, not `leaflet`, unless there's a specific reason not to
- [ ] Any new external service goes through `APIManager`, not ad-hoc `httr`/`curl` calls scattered through module code
- [ ] Default UI filter/input values tested against the actual output distribution before shipping
- [ ] Reused CSS classes/colour variables from `www/css/global.css` rather than inventing a new palette per module

---

## 5. Quick reference — file-by-file

| Path | Role |
|---|---|
| `app.R` | Entry point; loads module packages, builds and runs the Shiny app |
| `global.R` | Library/source calls; builds UI and server via `ModuleLoader` |
| `R/module_loader.R` | R6 class: discovers `manifest.yml`s, builds sidebar groups + tab items |
| `R/utils_api.R` | R6 `APIManager`: Claude API + BigQuery, single source of truth for external calls |
| `R/utils_road_risk.R` | Shared corridor data, OSA risk formula, colour scale, breakdown helper |
| `R/utils_common.R` | Misc shared helpers (legacy/general-purpose, not OSA-specific) |
| `www/css/global.css` | App-wide theme: colour variables, risk scale, badges, cards |
| `modules/_module_registry.yml` | Declares sidebar groups and which modules belong to each, enabled/priority/description per module |
| `modules/API Configuration/*` | BigQuery + Claude credential/config modules |
| `modules/DriveSafe/driver_health_monitor` | Multi-view health monitoring dashboard |
| `modules/DriveSafe/driver_data_log` | Simulate/upload/browse BigQuery data |
| `modules/DriveSafe/driver_ab_test` | Cohort comparison (control / CPAP-treated / untreated) |
| `modules/DriveSafe/driver_road_risk/driver_road_risk_map` | Interactive UK risk heatmap (plotly scattermapbox) |
| `modules/DriveSafe/driver_road_risk/driver_road_risk_corridors` | Corridor ranking and treatment-effect analysis |
| `modules/DriveSafe/driver_road_risk/driver_road_risk_interventions` | Scenario builder + fleet projection |
