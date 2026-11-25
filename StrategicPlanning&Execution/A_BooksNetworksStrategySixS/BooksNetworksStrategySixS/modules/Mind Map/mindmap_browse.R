# modules/Mind Map/mindmap_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           mindmap_browse
# name:         Browse Data
# icon:         table
# description:  Browse and download all stored node version rows (raw append-only backup)
# packages:     shiny, shinydashboard, DT
# api_required: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see raw_browse_ui / raw_browse_server in R/utils_suite_tabs.R.

MINDMAP_BROWSE_CFG <- list(
  title = "Browse All Stored Rows (raw append-only backup)",
  note = p("This shows every versioned row exactly as stored, including full edit history - ",
           "each edit is a NEW row (change_type = 'create'/'update'/'delete'), never an overwrite. ",
           "For the current, deduplicated state of a specific map, use Visualize Mind Map or Edit Mind Map instead."),
  max_rows = c(200, 5000),          # shown at first, most allowed
  table = "bq_full_table_mindmap",
  file_prefix = "mindmap_nodes"
)

mindmap_browse_ui <- function(id) raw_browse_ui(id, MINDMAP_BROWSE_CFG)
mindmap_browse_server <- function(id, api_manager) raw_browse_server(id, api_manager, MINDMAP_BROWSE_CFG)
