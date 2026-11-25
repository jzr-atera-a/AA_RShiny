# modules/Technical Designs/techdesign_data.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_data
# name:         Data Processing Architectures
# icon:         database
# description:  Data processing architecture diagrams (Lambda, Kappa, Medallion lakehouse, CDC/event-driven)
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_required: claude
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_data_ui <- function(id) {
  techdesign_module_ui(id, "data_processing")
}

# ==== Server =======================================================================================

techdesign_data_server <- function(id, api_manager) {
  techdesign_module_server(id, api_manager, "data_processing")
}
