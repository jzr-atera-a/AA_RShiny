# modules/Technical Designs/techdesign_ml.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_ml
# name:         ML / GenAI Architectures
# icon:         brain
# description:  Machine Learning and GenAI architecture diagrams (RAG, agents, real-time and batch ML pipelines)
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_required: claude
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_ml_ui <- function(id) {
  techdesign_module_ui(id, "ml_genai")
}

# ==== Server =======================================================================================

techdesign_ml_server <- function(id, api_manager) {
  techdesign_module_server(id, api_manager, "ml_genai")
}
