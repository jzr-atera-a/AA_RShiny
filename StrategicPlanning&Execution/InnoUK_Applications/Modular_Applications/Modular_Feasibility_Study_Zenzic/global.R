# global.R - Global Configuration
# Complete Application Setup
# ==========================

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyjs)
  library(R6)
  library(yaml)
  library(purrr)
  library(httr)
  library(jsonlite)
  library(openxlsx)
})

source("R/module_loader.R")
source("R/utils_api.R")

# Initialize API Manager
api_manager <- APIManager$new()

# UI Factory Function
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Create tabs from modules
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
  
  # Create menu items
  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(menu_info$label, tabName = menu_info$tabname, icon = icon(menu_info$icon))
  })
  
  # Build dashboard UI
  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "Project Application Assistant"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu", 
        do.call(tagList, all_menu_items)
      )
    ),
    dashboardBody(
      useShinyjs(),
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Store module returns for cross-module communication
  module_returns <- list()
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      
      # Call server function and store return value
      module_return <- server_function(module_id, api_manager)
      
      if (!is.null(module_return)) {
        module_returns[[module_id]] <- module_return
      }
    }
  }
  
  # Make module returns available globally for cross-module access
  assign("module_returns", module_returns, envir = .GlobalEnv)
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x
