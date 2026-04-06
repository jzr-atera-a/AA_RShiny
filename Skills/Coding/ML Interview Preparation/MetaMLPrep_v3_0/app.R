# app.R - Meta ML Interview Prep Suite v3.0
cat("\n=== META ML INTERVIEW PREP SUITE v3.0 ===\n\n")

source("global.R")
module_loader <- ModuleLoader$new()
module_loader$load_packages()
module_loader$source_modules()

log_error <- function(msg) {
  write(paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," - ERROR: ",msg,"\n"),
        file="app_error.log", append=TRUE)
}

shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    prep_mgr <- PrepManager$new()
    tryCatch(
      create_server(module_loader, prep_mgr),
      error = function(e) { cat("Server error:", e$message, "\n"); log_error(e$message) }
    )
    session$onSessionEnded(function() { gc(verbose=FALSE) })
    cat("Session started:", session$token, "\n")
  },
  options = list(port=getOption("shiny.port",3839), host="0.0.0.0",
                 launch.browser=getOption("shiny.launch.browser",TRUE)),
  enableBookmarking = "url"
)
