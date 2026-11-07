# app.R - Entry Point: Events Scheduling DB
# Modular R Shiny + BigQuery + Claude Architecture

# Clear environment
rm(list = ls(all.names = TRUE))
if (exists("ModuleLoader")) rm(ModuleLoader)
if (exists("APIManager"))   rm(APIManager)
if (exists("module_loader")) rm(module_loader)
if (exists("api_manager"))   rm(api_manager)

loaded_objects   <- ls(envir = .GlobalEnv)
module_functions <- grep("_(ui|server)$", loaded_objects, value = TRUE)
if (length(module_functions) > 0) {
  rm(list = module_functions, envir = .GlobalEnv)
}

source("global.R", local = FALSE)

cat("\n⚙️  Initializing Module Loader...\n")
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

cat("\n🚀 Launching Events Scheduling DB...\n\n")

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    session$onSessionEnded(function() {
      tryCatch({}, error = function(e) {})
    })
    create_server(module_loader, api_manager, session)
  }
)
