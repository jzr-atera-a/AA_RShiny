# global.R - Global Configuration

cat("\n╔═══════════════════════════════════════╗\n")
cat("║  BUSINESS CANVAS MANAGER - STARTING  ║\n")
cat("╚═══════════════════════════════════════╝\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
})

source("R/module_loader.R")
source("R/utils_common.R")
if (file.exists("R/utils_api.R")) {
  source("R/utils_api.R")
}

api_manager <- if (exists("APIManager")) {
  APIManager$new()
} else {
  NULL
}

create_ui <- function(module_loader) {
  dashboardPage(
    dashboardHeader(
      title = module_loader$registry$app$name %||% "Business Canvas Manager"
    ),
    
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, module_loader$generate_menu_items())
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),
      
      do.call(tabItems, module_loader$generate_tab_items())
    )
  )
}

create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  cat("\n🔧 Initializing module servers...\n")
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      
      tryCatch({
        server_function(module_id, api_manager, session)
        cat(sprintf("   ✓ %s server initialized\n", module$module$name))
      }, error = function(e) {
        cat(sprintf("   ⚠ %s server failed: %s\n", module$module$name, e$message))
      })
    } else {
      cat(sprintf("   ⚠ %s server function not found\n", module$module$name))
    }
  }
  
  cat("\n✅ Server initialization complete!\n\n")
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration loaded\n\n")