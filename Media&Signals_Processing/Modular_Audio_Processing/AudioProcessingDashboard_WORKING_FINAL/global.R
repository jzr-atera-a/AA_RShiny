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
  
  # Build tab items explicitly in a for loop (WORKING PATTERN!)
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
    } else {
      # Placeholder tab if UI function doesn't exist
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(
          box(
            title = paste("Module:", module$module$name),
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            h4("This module is enabled but not yet implemented"),
            p("Module ID:", module_id),
            p("Expected UI function:", ui_function_name)
          )
        )
      )
    }
  }
  
  # Build menu items list
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
    
    # Header
    dashboardHeader(
      title = "Audio Processing Dashboard",
      titleWidth = 300
    ),
    
    # Sidebar
    dashboardSidebar(
      width = 300,
      tags$head(
        tags$link(
          rel = "stylesheet",
          type = "text/css",
          href = "css/global.css"
        ),
        tags$meta(charset = "UTF-8"),
        tags$meta(
          name = "viewport",
          content = "width=device-width, initial-scale=1.0"
        )
      ),
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),
    
    # Body
    dashboardBody(
      # CRITICAL FIX: Use do.call with explicit list of tabs
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, api_manager, session) {
  # Get only enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  cat("Initializing", length(enabled_modules), "module server(s)...\n")
  
  # Initialize each module's server
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager, session)
    } else {
      warning("Server function not found: ", server_function_name)
    }
  }
  
  cat("✓ All module servers initialized\n")
}

# Helper operators
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
