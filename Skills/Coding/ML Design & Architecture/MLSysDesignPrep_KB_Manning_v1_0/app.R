# app.R — ML System Design Prep (Kravchenko & Babushkin, Manning 2025)
source("global.R")

module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    prep_mgr <- PrepManager$new()
    tryCatch(create_server(module_loader, prep_mgr),
             error = function(e) cat("❌ Server error:", e$message, "\n"))
    session$onSessionEnded(function() { gc(verbose=FALSE); cat("Session ended\n") })
  },
  options = list(port=getOption("shiny.port",3839),
                 host=getOption("shiny.host","0.0.0.0"),
                 launch.browser=getOption("shiny.launch.browser",TRUE)),
  enableBookmarking = "url"
)
