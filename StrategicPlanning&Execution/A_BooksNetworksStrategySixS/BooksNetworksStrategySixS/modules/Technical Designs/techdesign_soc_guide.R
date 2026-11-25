# modules/Technical Designs/techdesign_soc_guide.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_guide
# name:         Social: Top 36 Guide
# icon:         book
# description:  Top 32 social dynamics algorithms: sources, audiences, research download
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_guide_ui <- function(id) social_guide_ui(id)

# ==== Server =======================================================================================

techdesign_soc_guide_server <- function(id, api_manager) social_guide_server(id, api_manager)
