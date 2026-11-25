# modules/Technical Designs/techdesign_patterns.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_patterns
# name:         Software Design Patterns
# icon:         puzzle-piece
# description:  UML class diagrams of software design patterns (Factory, Strategy, Observer, Adapter/Facade)
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_required: claude
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_patterns_ui <- function(id) {
  techdesign_module_ui(id, "software_patterns")
}

# ==== Server =======================================================================================

techdesign_patterns_server <- function(id, api_manager) {
  techdesign_module_server(id, api_manager, "software_patterns")
}
