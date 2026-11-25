# modules/Technical Designs/techdesign_soc_influence.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_influence
# name:         Social: Influencing
# icon:         bullhorn
# description:  Social dynamics algorithms for influencing people
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_influence_ui <- function(id) social_tab_ui(id, "I")

# ==== Server =======================================================================================

techdesign_soc_influence_server <- function(id, api_manager) social_tab_server(id, api_manager, "I")
