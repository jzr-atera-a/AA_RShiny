# modules/Flex Table/flex_table_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           flex_table_browse
# name:         Browse Data
# icon:         table
# description:  Browse and download all stored rows (raw delimited backup)
# packages:     shiny, shinydashboard, DT
# api_required: bigquery
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see raw_browse_ui / raw_browse_server in R/utils_suite_tabs.R.

FLEX_TABLE_BROWSE_CFG <- list(
  title = "Browse All Stored Rows (raw backup view)",
  note = p("This shows the raw BigQuery rows, including the delimited ", tags$code("columns_data"),
           " text column, exactly as stored - useful as a personal backup export. ",
           "For a human-readable rendered table, use the Table Viewer tab."),
  max_rows = c(200, 5000),          # shown at first, most allowed
  table = "bq_full_table_flex",
  file_prefix = "flex_comparison_tables"
)

flex_table_browse_ui <- function(id) raw_browse_ui(id, FLEX_TABLE_BROWSE_CFG)
flex_table_browse_server <- function(id, api_manager) raw_browse_server(id, api_manager, FLEX_TABLE_BROWSE_CFG)
