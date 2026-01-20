# global.R - Global Configuration
# Business Contact Manager - Modular Architecture
# ================================================

# Startup message
cat("\n╔═══════════════════════════════════════════╗\n")
cat("║  BUSINESS CONTACT MANAGER - INITIALIZING ║\n")
cat("╚═══════════════════════════════════════════╝\n\n")

# Core packages (always required)
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyjs)
  library(R6)
  library(yaml)
  library(purrr)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_contact_manager.R")

# Initialize Contact Manager (with reactive triggers)
contact_manager <- ContactManager$new()

# UI Factory Function
create_ui <- function(module_loader) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tab items explicitly
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
    skin = "blue",
    
    # Header
    dashboardHeader(
      title = module_loader$registry$app$name %||% "Business Contact Manager"
    ),
    
    # Sidebar
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),
    
    # Body
    dashboardBody(
      useShinyjs(),
      
      # Load CSS
      tags$head(
        tags$link(
          rel = "stylesheet",
          type = "text/css",
          href = "css/global.css"
        )
      ),
      
      # Tab items
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, contact_manager, session) {
  # Get only enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Initialize each module's server
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, contact_manager, session)
    }
  }
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
