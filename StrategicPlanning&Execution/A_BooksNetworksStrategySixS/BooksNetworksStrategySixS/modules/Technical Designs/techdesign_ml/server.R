# modules/Technical Designs/techdesign_ml/server.R

techdesign_ml_server <- function(id, api_manager) {
  techdesign_module_server(id, api_manager, "ml_genai")
}
