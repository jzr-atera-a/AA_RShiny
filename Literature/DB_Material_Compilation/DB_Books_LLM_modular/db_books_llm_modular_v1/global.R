# global.R - Global Configuration
# Book Summary Complete Suite v3.0 - Modular Architecture
# ================================

# Startup message
cat("\n╔═══════════════════════════════════════╗\n")
cat("║  BOOK SUMMARY SUITE - INITIALIZING   ║\n")
cat("╚═══════════════════════════════════════╝\n\n")

# Core packages (always required)
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
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
      title = module_loader$registry$app$name %||% "Book Summary Suite"
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
        ),
        # MathJax for formula rendering
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS-MML_HTMLorMML"),
        tags$script(HTML("
          if (typeof MathJax !== 'undefined') {
            MathJax.Hub.Config({
              tex2jax: {
                inlineMath: [['$','$'], ['\\\\(','\\\\)']],
                displayMath: [['$$','$$'], ['\\\\[','\\\\]']],
                processEscapes: true
              },
              'HTML-CSS': { linebreaks: { automatic: true } },
              SVG: { linebreaks: { automatic: true } }
            });
          }
        "))
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