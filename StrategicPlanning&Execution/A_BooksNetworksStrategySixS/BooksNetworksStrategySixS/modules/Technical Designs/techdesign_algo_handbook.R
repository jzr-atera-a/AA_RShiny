# modules/Technical Designs/techdesign_algo_handbook.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_algo_handbook
# name:         Algorithm Handbook
# icon:         book-open
# description:  Handbook of the 23 LeetCode pattern groups
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_algo_handbook_ui <- function(id) algo_handbook_ui(id)

# ==== Server =======================================================================================

techdesign_algo_handbook_server <- function(id, api_manager) algo_handbook_server(id, api_manager)
