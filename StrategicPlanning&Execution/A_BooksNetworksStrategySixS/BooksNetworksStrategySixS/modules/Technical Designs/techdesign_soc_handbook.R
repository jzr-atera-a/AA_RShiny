# modules/Technical Designs/techdesign_soc_handbook.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_handbook
# name:         Social: Handbook
# icon:         book-open
# description:  Handbook of the 36 social dynamics algorithms with scenarios and Harvard references
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_handbook_ui <- function(id) social_handbook_ui(id)

# ==== Server =======================================================================================

techdesign_soc_handbook_server <- function(id, api_manager) social_handbook_server(id, api_manager)
