# Business Operations Suite: structure

## Layout

```
app.R                      entry point: loads global.R, builds the UI and the server
global.R                   packages, sourcing order, create_ui(), create_server()
R/                         shared helpers, sourced once by global.R
  _disable_autoload.R      stops Shiny loading R/ a second time
  module_loader.R          finds, orders and loads the sub-tab files
  utils_nav.R              sidebar sections and horizontal tabs, nav_goto()
  utils_tables.R           per-tab table checks and the TABLES box in the sidebar
  utils_suite_tabs.R       shared Bulk Import and Browse implementations
  utils_api.R              APIManager (BigQuery + Claude)
  utils_common.R           parsers, dropdown cascades, safe_sql_escape()
  utils_*.R                calendar, Titan, Slack, Zoom, muscle, time zones, exports, local keys
modules/
  _module_registry.yml     sidebar groups and sections, enabled flags, priority
  <Tab group>/             one folder per main sidebar group
    <sub_tab_id>.R         one file per sub-tab: header + <id>_ui + <id>_server
www/css/global.css
```

Rules:

- One folder per main tab group. Never a folder per sub-tab.
- File name = module id = tab name = function prefix (`<id>_ui`, `<id>_server`).
- Files and folders starting with `_` are ignored by the loader.

## Sub-tab file header

Every sub-tab file starts with this header. It replaces the old `manifest.yml`.

```r
# ---- module ----------------------------------------------
# id:           diet_add_single
# name:         Add Single Entry
# label:        (optional: menu text if it differs from name)
# icon:         plus-circle
# description:  one line
# packages:     shiny, shinydashboard, DT
# api_required: claude          (optional)
# api_optional: bigquery        (optional)
# -----------------------------------------------------------
```

## Add a sub-tab

1. Create `modules/<Tab group>/<id>.R` with the header, `<id>_ui <- function(id)` and `<id>_server <- function(id, api_manager)`.
2. In `modules/_module_registry.yml`, add the id to the group's `modules:` list and to one of its `sections:` (or leave it out of the sections to give it its own sidebar entry). Optionally add `<id>: {enabled: true, priority: N}` under `modules:`.
3. If the tab reads a BigQuery table, add it to `TABLE_MODULE_KEYS` in `R/utils_tables.R` and start its data loaders with `api_manager$tab_gate("<id>")`, so the table is checked and loaded only when the tab is first opened.
4. Any package that is not already in `global.R` must be added to the `library()` block there (deployment scanners only see those).

To disable a tab, set `enabled: false` in the registry. To park a file, prefix its name with `_`.

## What the loader checks at start-up

- Stops with a clear message: duplicate ids, or a header `id` that differs from the file name.
- Warns: an enabled file that no sidebar group lists (it would not be shown), a group or section that lists an id with no file, a registry entry with no file, a file that does not define `<id>_ui` or `<id>_server`.

## Shared tabs

Tabs that several suites repeat with different constants have one implementation in `R/utils_suite_tabs.R`:

| Shared code | Used by | Constants |
|---|---|---|
| `suite_bulk_import_ui/_server` | Day Planner, Diet Planner, Exercise Tracker, Funding Programmes | `SUITE_BULK_IMPORT$<suite>` |
| `suite_browse_ui/_server` | Diet Planner, Exercise Tracker, Funding Programmes | `SUITE_BROWSE$<suite>` |

The sub-tab files for these are three lines each. To change a text or a table, edit the suite's entry in the config list.

## Saved diagrams in Google Drive

- `R/utils_diagram.R` draws each diagram once in base R (grid for the muscle figure) and writes PNG, PDF, SVG (needs cairo), HTML (embedded image plus data table) or an animated GIF. Nothing extra is installed.
- `R/utils_gdrive.R` is the Drive client (httr2 with a gargle service-account token). Its settings live in the credentials folder only and are never written to the app's data.
- `R/utils_drive_export.R` gives every diagram tab the "Save Diagrams to Google Drive" box: `drive_export_ui(ns)` in the UI and `drive_export_server(..., group, tab, specs, subject)` in the server. `specs` is a reactive named list of diagram specs.
- Folder scheme: `<root>/<tab group>/<tab>/<subject>/<name>.<format>`. Folders are created as needed. Saving a file with an existing name updates it in place.
- Setup: API Configuration > Google Drive (`modules/API Configuration/gdrive_api_config.R`).

Diagram tabs: Day Planner (time allocation), Diet Planner (macros), Exercise Tracker (calories, Muscle Progress, Muscle Map, Muscle Log, Muscle Programme), Events Scheduling (by category, by week), Funding Programmes (by category), Travel Planning (trip plan, plan view).

## SQL values

Always pass values through `safe_sql_escape()` before putting them in a BigQuery string literal. Do not escape quotes by hand.
