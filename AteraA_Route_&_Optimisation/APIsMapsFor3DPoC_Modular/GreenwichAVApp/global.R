# global.R - Greenwich AV Project Configuration
# Version 1.0

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
  library(sf)
  library(osmdata)
  library(leaflet)
  library(htmltools)
  library(httr)
  library(jsonlite)
  library(raster)
  library(tmaptools)
})

# Source utility functions
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_geo.R")

# Create data manager for sharing data between modules
data_manager <- R6Class(
  "DataManager",
  public = list(
    bbox = NULL,
    location_name = NULL,
    osm_data = NULL,
    arcgis_data = NULL,
    terrain_data = NULL,
    lidar_data = NULL,
    imagery_data = NULL,
    export_ready = FALSE,
    
    initialize = function() {
      # Set default location (Greenwich O2 Arena)
      self$location_name <- "Greenwich Peninsula, London"
      self$bbox <- c(
        xmin = 0.0020,  # West
        ymin = 51.5025,  # South
        xmax = 0.0035,   # East
        ymax = 51.5035   # North
      )
    },
    
    update_bbox = function(bbox) {
      self$bbox <- bbox
    },
    
    update_location = function(location) {
      self$location_name <- location
    },
    
    get_bbox_string = function() {
      if (is.null(self$bbox)) return("")
      paste(self$bbox[2], self$bbox[1], self$bbox[4], self$bbox[3], sep = ",")
    },
    
    check_export_ready = function() {
      layers_count <- sum(
        !is.null(self$osm_data),
        !is.null(self$terrain_data),
        !is.null(self$imagery_data)
      )
      self$export_ready <- layers_count >= 2
      return(self$export_ready)
    }
  )
)

# Initialize data manager
data_mgr <- data_manager$new()

# Create UI function
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
    dashboardHeader(title = module_loader$registry$app$name %||% "Greenwich AV Data Extractor"),
    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", 
        do.call(tagList, all_menu_items)
      )
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

# Create server function
create_server <- function(module_loader, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, data_mgr)
    }
  }
}

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
