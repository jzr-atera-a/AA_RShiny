# modules/Technical Designs/techdesign_soc_business.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_soc_business
# name:         Social: Business
# icon:         handshake
# description:  Social dynamics algorithms for business partners
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_soc_business_ui <- function(id) social_tab_ui(id, "B")

# ==== Server =======================================================================================

techdesign_soc_business_server <- function(id, api_manager) social_tab_server(id, api_manager, "B")
