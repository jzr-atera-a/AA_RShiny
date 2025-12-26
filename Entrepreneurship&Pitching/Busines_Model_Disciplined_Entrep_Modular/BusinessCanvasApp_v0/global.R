# global.R - Global Configuration
# ================================

# Startup message
cat("\n╔═══════════════════════════════════════╗\n")
cat("║  BUSINESS CANVAS MANAGER - MODULAR    ║\n")
cat("║  Initializing...                      ║\n")
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
cat("📦 Loading utilities...\n")
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")
source("R/utils_bigquery.R")

# Initialize API manager
cat("🔌 Initializing API Manager...\n")
api_manager <- APIManager$new()

# UI Factory Function
create_ui <- function(module_loader) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tab items
  all_tabs <- list()
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$menu$tabname %||% module_id
    
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      # UI function exists - use it
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_function(module_id)
      )
    } else {
      # Create placeholder
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(
          box(
            title = paste("Module:", module$module$name),
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            h3(module$module$name),
            p("This module needs implementation."),
            p(paste("Expected UI function:", ui_function_name)),
            hr(),
            p("To implement:"),
            tags$ol(
              tags$li("Edit modules/", module_id, "/ui.R"),
              tags$li("See modules/claude_auth/ui.R for example"),
              tags$li("Follow pattern in TODO.md")
            )
          )
        )
      )
    }
  }
  
  dashboardPage(
    # Header
    dashboardHeader(
      title = "Business Canvas Manager",
      tags$li(
        class = "dropdown",
        tags$span(
          style = "font-size:16px; color:white; font-weight:bold; padding:15px; display:inline-block;",
          "Business Model Canvas & Disciplined Entrepreneurship Platform"
        )
      )
    ),
    
    # Sidebar
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        menuItem("Claude API Connection", tabName = "claude_auth", icon = icon("robot")),
        menuItem("BigQuery Authentication", tabName = "bigquery_auth", icon = icon("key")),
        menuItem("Generate BM Canvas", tabName = "generate_bm_canvas", icon = icon("file-import")),
        menuItem("Generate DE Canvas", tabName = "generate_de_canvas", icon = icon("file-upload")),
        menuItem("Generate DE Roadmap", tabName = "generate_de_roadmap", icon = icon("route")),
        menuItem("Business Model Canvas", tabName = "view_bm_canvas", icon = icon("th")),
        menuItem("Disciplined Ent. Canvas", tabName = "view_de_canvas", icon = icon("layer-group")),
        menuItem("Disciplined Ent. Roadmap", tabName = "view_de_roadmap", icon = icon("road"))
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
        )
      ),
      
      # Tabs - explicitly call tabItems with list
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, api_manager, session) {
  # Get only enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  cat("\n🔧 Initializing module servers...\n")
  
  # Initialize each module's server
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      cat(sprintf("   ✓ %s\n", module$module$name))
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager, session)
    }
  }
  
  cat("\n✅ All module servers initialized successfully!\n\n")
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✔ Global configuration complete\n")