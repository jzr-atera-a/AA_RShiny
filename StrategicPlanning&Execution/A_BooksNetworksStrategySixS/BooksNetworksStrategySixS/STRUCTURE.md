# BooksNetworksStrategySixS - how the code is organised

```
app.R                     entry point
global.R                  packages, shared code (sourced once, in order), page assembly
R/                        shared code
  module_loader.R           finds and loads the sub-tabs
  utils_api.R               APIManager: the one Claude connection and the one BigQuery connection
  utils_td_hubs.R           hubs: the sidebar entries that hold horizontal sub-tabs
  utils_suite_tabs.R        sub-tabs that several suites share (browse, bulk import, recommender)
  utils_common.R            parsers, prompts, cascading dropdowns, renderers
  utils_*.R                 Technical Designs, decision trees, infographics, credentials, lazy loading
  utils_gdrive.R            Google Drive: sign-in, folder hierarchy, uploads and the manifest for "Save to Google Drive"
  _disable_autoload.R       stops Shiny loading R/ a second time by itself
modules/
  _module_registry.yml      sidebar groups; per sub-tab: enabled + sort priority
  <Tab group>/<id>.R        ONE file per sub-tab: header, <id>_ui(), <id>_server()
www/                      css and js
seed/                     starter content for Technical Designs
```

## A sub-tab file

```r
# ---- module ------------------------------------------------
# id:           generate_diagram          (must equal the file name)
# name:         Generate Diagram
# label:        optional: tab text when it differs from the name
# icon:         magic
# description:  one line
# packages:     shiny, shinydashboard, DT
# api_required: claude
# api_optional: bigquery
# -------------------------------------------------------------

generate_diagram_ui <- function(id) { ... }
generate_diagram_server <- function(id, api_manager) { ... }
```

## Adding a sub-tab

1. Create `modules/<Tab group>/<id>.R` with the header and the two functions.
2. Show it: add `list(id = "<id>", label = "...", icon = "...")` to a hub's `children` in `R/utils_td_hubs.R`,
   or add the id to a group's `modules:` in `modules/_module_registry.yml` (a sidebar entry of its own).
3. Optional: add `<id>: { enabled: true, priority: N }` to the registry to set its order or switch it off.

The start-up log warns when a file is not placed anywhere, or when a hub or group names an id that has no file.

## Sub-tabs that share one implementation

Some files are only a few lines: they pass a small configuration to code that several suites share.

| Shared code (R/) | Used by |
|---|---|
| `raw_browse_*` in utils_suite_tabs.R | Browse and Download of Book Summary, Flex Table, Mind Map, Knowledge Graph |
| `catalog_browse_*` | Browse and Download of Strategic Analysis, Six Sigma, Sankey |
| `component_import_*` | Bulk Import of Strategic Analysis, Six Sigma |
| `tool_recommender_*` | Recommender of Strategic Analysis, Six Sigma |
| `techdesign_module_*`, `techdesign_social_*` | the Technical Designs generate tabs |
| `td_hub_ui` in utils_td_hubs.R | every hub |
