# modules/Sankey Graph/sankey_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           sankey_browse
# name:         Browse Sankey Graphs
# label:        Browse Sankeys
# icon:         table
# description:  Browse saved Sankey graphs and download the raw node/link rows
# packages:     shiny, shinydashboard, DT
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see catalog_browse_ui / catalog_browse_server in R/utils_suite_tabs.R.

SANKEY_BROWSE_CFG <- list(
  catalog_title = "Saved Sankey Graphs (one row per diagram)",
  rows_title = "Raw Node/Link Rows (sankey_graphs table)",
  id_noun = "Sankey ID",
  rows_download = "Download Rows CSV",
  filter_input = "filter_sankey_id",
  table = "bq_full_table_sankey", cache = "sankey_taxonomy_cache", taxonomy = "bq_get_sankey_taxonomy",
  id_col = "sankey_id", order_by = "row_kind DESC, column_index, sequence_order",
  loaded = " Loaded %d Sankey(s), %d row(s)",
  file_catalog = "sankey_catalog", file_rows = "sankey_rows"
)

sankey_browse_ui <- function(id) catalog_browse_ui(id, SANKEY_BROWSE_CFG)
sankey_browse_server <- function(id, api_manager) catalog_browse_server(id, api_manager, SANKEY_BROWSE_CFG)
