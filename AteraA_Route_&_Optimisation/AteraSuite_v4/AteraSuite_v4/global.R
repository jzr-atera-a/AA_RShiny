# global.R - Integrated AV Development Suite
# Atera Analytics - Isaac Sim PhysX Dual Vehicle Integration

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
  library(sf)
  library(dodgr)
  library(osmdata)
  library(bigrquery)
})

# Source utilities - FIXED: correct paths in R/ subdirectory
source("R/utils_omniverse.R")
source("R/module_loader.R")

# Null coalescing operator (also defined in utils but kept here for safety)
`%||%` <- function(x, y) if (is.null(x)) y else x

# Initialize API manager - created in server() as reactiveValues
api_manager <- NULL

# ============================================================================
# UI FACTORY
# ============================================================================

create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id  <- module$module$id
    tabname    <- module$module$menu$tabname %||% module_id
    ui_fn_name <- paste0(module_id, "_ui")

    if (exists(ui_fn_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_fn_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_fn(module_id))
    }
  }

  all_menu_items <- lapply(enabled_modules, function(module) {
    m <- module$module$menu
    menuItem(m$label, tabName = m$tabname, icon = icon(m$icon))
  })

  dashboardPage(
    dashboardHeader(title = "Atera AV Suite"),
    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu_items))
    ),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/theme.css")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# ============================================================================
# SERVER FACTORY
# ============================================================================

create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id     <- module$module$id
    server_fn_name <- paste0(module_id, "_server")
    if (exists(server_fn_name, envir = .GlobalEnv)) {
      server_fn <- get(server_fn_name, envir = .GlobalEnv)
      server_fn(module_id, api_manager)
    }
  }
}

cat("✓ Global configuration loaded\n")
cat("✓ Libraries: shiny, shinydashboard, leaflet, DT, plotly, httr, jsonlite, sf, dodgr, bigrquery\n\n")
