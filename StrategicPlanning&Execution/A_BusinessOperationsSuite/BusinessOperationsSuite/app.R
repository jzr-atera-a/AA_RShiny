# app.R
# Business Operations Suite - unified modular app
# Groups: API Settings | Communications | Funding Programmes
# See modules/_module_registry.yml for the full sidebar structure.

source("global.R")

shinyApp(ui = create_ui(), server = create_server())
