# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================

cat("\n═══ AUDIO PROCESSING DASHBOARD - INITIALIZING ═══\n\n")

# Increase file upload limit to 100MB
options(shiny.maxRequestSize = 100*1024^2)

# Core packages (always required)
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
})

# Source utility files
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")

# UI Factory Function
create_ui <- function(module_loader) {
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tab items
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname
    
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_function(module_id)
      )
    }
  }
  
  # Build menu items
  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(
      menu_info$label,
      tabName = menu_info$tabname,
      icon = icon(menu_info$icon)
    )
  })
  
  dashboardPage(
    skin = "purple",
    
    dashboardHeader(
      title = "Audio Processing Dashboard",
      titleWidth = 300
    ),
    
    dashboardSidebar(
      width = 300,
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$style(HTML("
          .main-header .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
          .main-sidebar { background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; }
          .sidebar-menu > li.active > a { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
          .content-wrapper { background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; }
          .box { border-radius: 12px !important; box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important; }
          .box-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; color: white !important; }
          .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
          .btn-success { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%) !important; }
        "))
      ),
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),
    
    dashboardBody(
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  cat("Initializing", length(enabled_modules), "module server(s)...\n")
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager, session)
    }
  }
  
  cat("✓ All module servers initialized\n")
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
