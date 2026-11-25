# modules/Technical Designs/techdesign_soc_collab.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_collab
# name:         Social: Collaborators
# icon:         users
# description:  Social dynamics algorithms for collaborators
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_collab_ui <- function(id) social_tab_ui(id, "C")

# ==== Server =======================================================================================

techdesign_soc_collab_server <- function(id, api_manager) social_tab_server(id, api_manager, "C")
