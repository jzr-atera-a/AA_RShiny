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

    # START-UP IS INSTANT: the page is sent first. A moment later the browser sends `app_boot`, and only then are the keys read from the
    # local folder (Windows: C:/111_SecA/_q_api) or the environment, BigQuery signed in and Claude tested (the sidebar shows "connecting ...").
    # Connecting only signs in: each suite's tables are checked ON DEMAND when its tab group (or tab) is clicked, with a sidebar section + toasts.
    isolate(api_manager$bq_session_reset())   # a new browser session starts with nothing loaded
    booting <- reactiveVal(TRUE)
    checks <- reactiveVal(list())
    observeEvent(input$app_boot, {
      shiny::isolate({
        tryCatch(app_cred_autoload(api_manager), error = function(e) cat("[Keys] auto-load failed:", conditionMessage(e), "\n"))
        tryCatch(app_cred_env_fallback(api_manager), error = function(e) NULL)
      })
      booting(FALSE)
      tryCatch(app_cred_toasts(api_manager), error = function(e) NULL)
    }, once = TRUE)
    output$api_status <- renderUI(app_api_status_render(api_manager, booting, checks))
    output$bq_checks <- renderUI(app_bq_checks_render(checks, api_manager))
    lazy <- create_server(module_loader, api_manager, session)
    app_bq_lazy_observer(input, session, module_loader, api_manager, checks, lazy)
  }
)
