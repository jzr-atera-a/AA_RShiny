# modules/Technical Designs/techdesign_algorithm.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_algorithm
# name:         Algorithm Selector
# icon:         project-diagram
# description:  Paste a LeetCode or Meta interview question; the Editing Tool recommends the pattern and draws it as an interactive network
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_algorithm_ui <- function(id) {
  techdesign_module_ui(id, "algorithms")
}

# ==== Server =======================================================================================

techdesign_algorithm_server <- function(id, api_manager) {
  techdesign_module_server(id, api_manager, "algorithms")
}
