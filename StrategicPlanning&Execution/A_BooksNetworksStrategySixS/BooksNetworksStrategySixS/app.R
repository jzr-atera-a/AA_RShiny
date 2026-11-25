# app.R - entry point of BooksNetworksStrategySixS
# global.R loads the packages, the shared code in R/ and builds the API manager; the module loader then reads the sub-tab
# files (modules/<Tab group>/<id>.R) and the page is assembled from them.

# A fresh start every time: when the app is run again in the same R session, definitions left by the previous run are
# removed first, so a sub-tab that was deleted or renamed cannot linger.
local({
  old <- ls(envir = .GlobalEnv)
  stale <- old[old %in% c("ModuleLoader", "APIManager", "module_loader", "api_manager") | grepl("_(ui|server)$", old)]
  if (length(stale)) rm(list = stale, envir = .GlobalEnv)
})

source("global.R", local = FALSE)

cat("\n\u2699\ufe0f  Initializing Module Loader...\n")
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

cat("\n\U0001F680 Launching application...\n\n")

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    # START-UP IS INSTANT: the page is sent first. A moment later the browser sends `app_boot`, and only then are the keys read from the
    # local folder (Windows: C:/111_SecA/_q_api) or the environment, BigQuery signed in and Claude tested (the sidebar shows "connecting ...").
    # Connecting only signs in: each suite's tables are checked ON DEMAND when a tab that needs them is opened, with a sidebar section + toasts.
    isolate(api_manager$bq_session_reset())   # a new browser session starts with nothing loaded
    booting <- reactiveVal(TRUE)
    checks <- reactiveVal(list())
    observeEvent(input$app_boot, {
      isolate({
        tryCatch(app_cred_autoload(api_manager), error = function(e) cat("[Keys] auto-load failed:", conditionMessage(e), "\n"))
        tryCatch(app_cred_env_fallback(api_manager), error = function(e) cat("[Keys] environment fallback failed:", conditionMessage(e), "\n"))
        if (!gd_configured()) tryCatch(gd_autoload(api_manager), error = function(e) cat("[Google Drive] auto-load failed:", conditionMessage(e), "\n"))
      })
      booting(FALSE)
      tryCatch(app_cred_toasts(api_manager), error = function(e) NULL)
    }, once = TRUE)
    output$api_status <- renderUI(app_api_status_render(api_manager, booting, checks))
    output$bq_checks <- renderUI(app_bq_checks_render(checks, api_manager))
    gd_server_hooks(input, output, session, api_manager)   # "Save to Google Drive" on every visualisation tab
    lazy <- create_server(module_loader, api_manager, session)
    app_bq_lazy_observer(input, session, module_loader, api_manager, checks, lazy)
  }
)
