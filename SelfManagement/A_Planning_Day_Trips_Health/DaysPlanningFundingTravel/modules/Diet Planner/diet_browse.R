# modules/Diet Planner/diet_browse.R
# ---- module ----------------------------------------------
# id:           diet_browse
# name:         Browse Data
# icon:         table
# description:  Browse and download all logged diet days
# packages:     shiny, shinydashboard, DT
# -----------------------------------------------------------

# Shared implementation: R/utils_suite_tabs.R (suite_browse_ui / suite_browse_server); this suite's texts and table are in SUITE_BROWSE$diet.
diet_browse_ui <- function(id) suite_browse_ui(id, SUITE_BROWSE$diet)
diet_browse_server <- function(id, api_manager) suite_browse_server(id, api_manager, SUITE_BROWSE$diet)
