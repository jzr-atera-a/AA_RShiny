# app.R - Entry Point with Automatic Cleanup
# Unified Suite: Flex Table + Mind Map + Knowledge Graph

rm(list = ls(all.names = TRUE))
if (exists("ModuleLoader")) rm(ModuleLoader)
if (exists("APIManager")) rm(APIManager)
if (exists("module_loader")) rm(module_loader)
if (exists("api_manager")) rm(api_manager)

loaded_objects <- ls(envir = .GlobalEnv)
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

cat("\n🚀 Launching application...\n\n")

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    session$onSessionEnded(function() {
      if (!is.null(api_manager)) {
        tryCatch({}, error = function(e) {})
      }
    })

    # keys from the local folder (Windows: C:/111_SecA/_q_api), then environment variables; the API tabs stay available.
    # Connecting only signs in: each suite's table is checked and its lists loaded when its tab is first opened (bottom-right messages).
    # isolate(): connecting touches reactive values, which need a reactive context
    shiny::isolate({
      api_manager$bq_session_reset()   # a new browser session starts with nothing loaded
      tryCatch(app_cred_autoload(api_manager), error = function(e) cat("[Keys] auto-load failed:", conditionMessage(e), "\n"))
      tryCatch(app_cred_env_fallback(api_manager), error = function(e) NULL)
    })
    tryCatch(app_cred_toasts(api_manager), error = function(e) NULL)
    output$api_status <- renderUI(app_api_status_render(api_manager))
    app_bq_lazy_observer(input, module_loader, api_manager)

    create_server(module_loader, api_manager, session)
  }
)
