# global.R - Global Configuration
# Daily Scheduler Suite v1.0 - Modular Architecture
# ================================

# Startup message
cat("\n╔═══════════════════════════════════════╗\n")
cat("║  FUNDING PROGRAMMES SUITE - INIT  ║\n")
cat("╚═══════════════════════════════════════╝\n\n")

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
# ============================================================
# The module loader below installs/attaches packages dynamically
# based on what each module's manifest.yml declares (a YAML value,
# not literal R code). rsconnect's static dependency scanner used
# when publishing to shinyapps.io can ONLY detect packages that
# appear as a literal library()/require() call or a literal
# pkg::function() reference somewhere in the bundled .R files.
# It cannot see inside YAML files and cannot resolve
# library(pkg, character.only = TRUE) when `pkg` is a variable.
#
# Without this block, shinyapps.io installs only the packages it
# can prove are needed (e.g. via explicit pkg:: calls), silently
# skips the rest, and the app crashes at runtime with errors like
# "could not find function 'plotlyOutput'" - even though the same
# app runs fine locally because those packages already happen to
# be installed on your machine.
#
# Every package any module currently declares as a dependency is
# listed here explicitly so shinyapps.io always installs it,
# regardless of which modules are enabled/disabled in
# modules/_module_registry.yml. This keeps the enable/disable
# feature working purely as a runtime behavior (controlled by
# ModuleLoader$load_packages()) while guaranteeing every package
# is available on the server if a module is ever re-enabled later
# without a fresh deployment.
suppressPackageStartupMessages({
  library(shinyjs)
  library(httr)
  library(jsonlite)
  library(bigrquery)
  library(DT)
  library(plotly)
  library(dplyr)
  library(stringr)
  library(tidyr)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")

# Initialize API manager (with reactive triggers)
api_manager <- APIManager$new()

# UI Factory Function
create_ui <- function(module_loader) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tab items explicitly in a for loop (WORKING PATTERN!)
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname %||% module_id
    
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
    # Header
    dashboardHeader(
      title = module_loader$registry$app$name %||% "Daily Scheduler Suite"
    ),
    
    # Sidebar - Use pre-built menu items
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),
    
    # Body
    dashboardBody(
      # Enable shinyjs - REQUIRED for shinyjs::show()/hide() calls used by
      # the generate_schedule module (loading spinner). Without this call,
      # shinyjs's client-side message handler is never registered, so
      # shinyjs::show()/hide() calls are silently dropped (no error, no
      # effect) anywhere in the app.
      shinyjs::useShinyjs(),
      
      # Load CSS
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
      
      # CRITICAL FIX: Use do.call with explicit list of tabs
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, api_manager, session) {
  # Get only enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Initialize each module's server
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager)
    }
  }
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
