# global.R - Integrated AV Development Suite
# Version 1.0 - FIXED: Don't pass session to module servers

cat("\n╔══════════════════════════════════════════════════╗\n")
cat("║  INTEGRATED AV DEVELOPMENT SUITE v1.0 - LOADING  ║\n")
cat("╚══════════════════════════════════════════════════╝\n\n")

# Load ALL required packages upfront
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
  
  # EV Route Optimizer packages
  library(sf)
  library(osmdata)
  library(tmaptools)
  library(dodgr)
  library(bigrquery)
  library(leaflet)
  library(htmltools)
  
  # Omniverse Simulation packages
  library(DT)
  library(plotly)
  library(jsonlite)
  library(httr)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_integrated_manager.R")

# Initialize SHARED API Manager
api_manager <- IntegratedAVManager$new()

# UI Factory Function - CRITICAL: FOR LOOP tab generation
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tabs explicitly in FOR LOOP
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$tabname
    
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
    menuItem(
      module$module$name,
      tabName = module$module$tabname,
      icon = icon(module$module$icon)
    )
  })
  
  # Return complete dashboard
  dashboardPage(
    dashboardHeader(title = "Integrated AV Suite"),
    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu_items))
    ),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function - FIXED: Don't pass session
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      # CRITICAL: Only pass id and api_manager, NOT session
      server_function(module_id, api_manager)
    }
  }
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
