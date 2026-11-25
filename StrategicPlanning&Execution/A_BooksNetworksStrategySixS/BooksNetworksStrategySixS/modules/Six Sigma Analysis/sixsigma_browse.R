# modules/Six Sigma Analysis/sixsigma_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           sixsigma_browse
# name:         Browse Six Sigma Diagrams
# label:        Browse Diagrams
# icon:         table
# description:  Browse saved Six Sigma diagrams and download the raw component rows
# packages:     shiny, shinydashboard, DT
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see catalog_browse_ui / catalog_browse_server in R/utils_suite_tabs.R.

SIXSIGMA_BROWSE_CFG <- list(
  catalog_title = "Saved Six Sigma Diagrams (one row per diagram)",
  rows_title = "Raw Component Rows (six_sigma_diagrams table)",
  id_noun = "Diagram ID",
  rows_download = "Download Components CSV",
  filter_input = "filter_diagram_id",
  table = "bq_full_table_sixsigma", cache = "sixsigma_taxonomy_cache", taxonomy = "bq_get_sixsigma_taxonomy",
  id_col = "diagram_id", order_by = "diagram_id, grid_row, grid_col, sequence_order",
  loaded = " Loaded %d diagram(s), %d component row(s)",
  file_catalog = "sixsigma_catalog", file_rows = "sixsigma_components"
)

sixsigma_browse_ui <- function(id) catalog_browse_ui(id, SIXSIGMA_BROWSE_CFG)
sixsigma_browse_server <- function(id, api_manager) catalog_browse_server(id, api_manager, SIXSIGMA_BROWSE_CFG)
