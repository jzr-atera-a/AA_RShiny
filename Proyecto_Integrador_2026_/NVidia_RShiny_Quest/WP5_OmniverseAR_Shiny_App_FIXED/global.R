# global.R - WP5 Omniverse AR Application
# Global configuration and initialization

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
  library(leaflet)
  library(DT)
  library(plotly)
  library(jsonlite)
  library(httr)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_omniverse.R")

# Initialize API manager with reactiveValues (will be created in server)
api_manager <- NULL

# Create UI
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname %||% module_id
    
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_function(module_id))
    }
  }
  
  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(menu_info$label, tabName = menu_info$tabname, icon = icon(menu_info$icon))
  })
  
  dashboardPage(
    dashboardHeader(title = "WP5 Omniverse AR"),
    dashboardSidebar(sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu_items))),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# Create Server
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")