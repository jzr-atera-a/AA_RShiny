# modules/Strategic Analysis/diagram_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           diagram_browse
# name:         Browse Diagrams
# icon:         table
# description:  Browse saved diagrams and download the raw component rows
# packages:     shiny, shinydashboard, DT
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see catalog_browse_ui / catalog_browse_server in R/utils_suite_tabs.R.

DIAGRAM_BROWSE_CFG <- list(
  catalog_title = "Saved Diagrams (one row per diagram)",
  rows_title = "Raw Component Rows (strategy_diagrams table)",
  id_noun = "Diagram ID",
  rows_download = "Download Components CSV",
  filter_input = "filter_diagram_id",
  table = "bq_full_table_diagram", cache = "diagram_taxonomy_cache", taxonomy = "bq_get_diagram_taxonomy",
  id_col = "diagram_id", order_by = "diagram_id, grid_row, grid_col, sequence_order",
  loaded = " Loaded %d diagram(s), %d component row(s)",
  file_catalog = "diagram_catalog", file_rows = "diagram_components"
)

diagram_browse_ui <- function(id) catalog_browse_ui(id, DIAGRAM_BROWSE_CFG)
diagram_browse_server <- function(id, api_manager) catalog_browse_server(id, api_manager, DIAGRAM_BROWSE_CFG)
