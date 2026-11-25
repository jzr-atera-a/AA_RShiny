# modules/Funding Programmes/funding_bulk_import.R
# ---- module ----------------------------------------------
# id:           funding_bulk_import
# name:         Bulk Import
# icon:         file-import
# description:  Parse and upload programmes in bulk
# packages:     shiny, shinydashboard, DT
# -----------------------------------------------------------

# Shared implementation: R/utils_suite_tabs.R (suite_bulk_import_ui / suite_bulk_import_server); this suite's texts and table are in SUITE_BULK_IMPORT$funding.
funding_bulk_import_ui <- function(id) suite_bulk_import_ui(id, SUITE_BULK_IMPORT$funding)
funding_bulk_import_server <- function(id, api_manager) suite_bulk_import_server(id, api_manager, SUITE_BULK_IMPORT$funding)
