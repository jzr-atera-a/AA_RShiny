# modules/Technical Designs/techdesign_soc_investors.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_investors
# name:         Social: Investors
# icon:         chart-line
# description:  Social dynamics algorithms for investors
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_investors_ui <- function(id) social_tab_ui(id, "V")

# ==== Server =======================================================================================

techdesign_soc_investors_server <- function(id, api_manager) social_tab_server(id, api_manager, "V")
