# global.R - Global Configuration
# Events Scheduling DB v1.0 - Modular Architecture
# =================================================

cat("\n╔══════════════════════════════════════════╗\n")
cat("║   EVENTS SCHEDULING DB - INITIALIZING   ║\n")
cat("╚══════════════════════════════════════════╝\n\n")

# Core packages (always required)
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
})

# ============================================================
# DEPLOYMENT DEPENDENCY DECLARATIONS - DO NOT REMOVE
# rsconnect's static scanner can only detect packages that
# appear as literal library() calls. Every package any module
# uses must be listed here so shinyapps.io installs it.
# ============================================================
suppressPackageStartupMessages({
  library(shinyjs)
  library(httr)
  library(jsonlite)
  library(bigrquery)
  library(DBI)
  library(DT)
  library(plotly)
  library(leaflet)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(lubridate)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")

# Initialize API manager
api_manager <- APIManager$new()

# ============================================================
# UI FACTORY
# ============================================================
create_ui <- function(module_loader) {

  enabled_modules <- module_loader$get_enabled_modules()

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id      <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname        <- module$module$menu$tabname %||% module_id

    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_fn(module_id)
      )
    } else {
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(box(
          title  = paste("Module:", module$module$name),
          status = "warning", solidHeader = TRUE, width = 12,
          h4("Module enabled but not yet implemented"),
          p("Module ID:", module_id)
        ))
      )
    }
  }

  all_menu_items <- lapply(enabled_modules, function(module) {
    mi <- module$module$menu
    menuItem(mi$label, tabName = mi$tabname, icon = icon(mi$icon))
  })

  dashboardPage(
    dashboardHeader(
      title = module_loader$registry$app$name %||% "Events Scheduling DB"
    ),

    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),

    dashboardBody(
      shinyjs::useShinyjs(),

      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
        # Leaflet CSS (map)
        tags$link(
          rel  = "stylesheet",
          href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        )
      ),

      do.call(tabItems, all_tabs)
    )
  )
}

# ============================================================
# SERVER FACTORY
# ============================================================
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_fn <- get(server_function_name, envir = .GlobalEnv)
      server_fn(module_id, api_manager)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
