# global.R - WORKING VERSION
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)  # LOAD PIPE HERE
  library(dplyr)
  library(sf)
  library(osmdata)
  library(tmaptools)  # For getbb() function
  library(dodgr)
  library(bigrquery)
  library(leaflet)
  library(htmltools)
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_bigquery.R")
source("R/utils_cav.R")

api_manager <- BigQueryManager$new()

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
    } else {
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(box(title = paste("Module:", module$module$name), status = "warning", width = 12,
                     h4("Module enabled but not implemented")))
      )
    }
  }
  
  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(menu_info$label, tabName = menu_info$tabname, icon = icon(menu_info$icon))
  })
  
  dashboardPage(
    dashboardHeader(title = module_loader$registry$app$name %||% "EV Route Optimizer"),
    dashboardSidebar(sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu_items))),
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