# app.R - Entry Point with Automatic Cleanup
# Business Operations Suite 2.0: Travel Planning + Day Planner + Diet + Exercise + Events + Funding + Gantt + Contacts
# Features: AI itinerary planning, schedule management, calendar export (Outlook/Android), Claude API integration, BigQuery backend

# NOTE: the debug console's log-capture objects are deliberately excluded
# from this wipe. They back a live sink() on stdout (see the top of
# global.R) - rm()-ing the R-level binding does NOT close the underlying
# connection or un-sink() it, so if these were wiped here, the very next
# runApp() in this same R session would stack a second sink on top of the
# still-open first one every time, rather than safely detecting and
# reusing it. Preserving them here is what makes global.R's guard work.
rm(list = setdiff(ls(all.names = TRUE), c(".debug_log_conn", "debug_log_buffer", ".debug_log_max_lines")))
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

    create_server(module_loader, api_manager, session)
  }
)
