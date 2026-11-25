# modules/Knowledge Graph/kg_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           kg_browse
# name:         Browse Data
# icon:         table
# description:  Browse and download all stored entity/relationship version rows (raw append-only backup)
# packages:     shiny, shinydashboard, DT
# api_required: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see raw_browse_ui / raw_browse_server in R/utils_suite_tabs.R.

KG_BROWSE_CFG <- list(
  title = "Browse All Stored Rows (raw append-only backup)",
  note = p("This shows every versioned row exactly as stored, including full edit history - ",
           "each edit is a NEW row (change_type = 'create'/'update'/'delete'), never an overwrite. ",
           "For the current, deduplicated state of a specific graph, use one of the Visualize tabs or Edit Graph instead."),
  max_rows = c(200, 5000),          # shown at first, most allowed
  table = "bq_full_table_kg",
  file_prefix = "knowledge_graph"
)

kg_browse_ui <- function(id) raw_browse_ui(id, KG_BROWSE_CFG)
kg_browse_server <- function(id, api_manager) raw_browse_server(id, api_manager, KG_BROWSE_CFG)
