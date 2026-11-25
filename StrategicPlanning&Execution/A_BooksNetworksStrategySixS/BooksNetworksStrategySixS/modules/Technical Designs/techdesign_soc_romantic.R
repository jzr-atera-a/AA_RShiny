# modules/Technical Designs/techdesign_soc_romantic.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_romantic
# name:         Social: Romantic
# icon:         heart
# description:  Social dynamics algorithms for romantic partners
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_romantic_ui <- function(id) social_tab_ui(id, "R")

# ==== Server =======================================================================================

techdesign_soc_romantic_server <- function(id, api_manager) social_tab_server(id, api_manager, "R")
