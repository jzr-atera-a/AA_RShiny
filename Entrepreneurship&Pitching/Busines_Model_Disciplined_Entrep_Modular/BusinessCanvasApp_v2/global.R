# global.R - Global Configuration
cat("\n╔═══════════════════════════════════════╗\n")
cat("║  BUSINESS CANVAS MANAGER - MODULAR    ║\n")
cat("║  Initializing...                      ║\n")
cat("╚═══════════════════════════════════════╝\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")
source("R/utils_bigquery.R")

cat("🔌 Initializing API Manager...\n")
api_manager <- APIManager$new()

create_ui <- function(module_loader) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tab items explicitly (THIS IS THE FIX!)
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$menu$tabname %||% module_id
    
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_function(module_id)
      )
    } else {
      # Placeholder tab
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
  
  dashboardPage(
    dashboardHeader(
      title = "Business Canvas Manager",
      tags$li(class = "dropdown",
              tags$span(style = "font-size:16px; color:white; font-weight:bold; padding:15px; display:inline-block;",
                        "Business Model Canvas & Disciplined Entrepreneurship Platform"))
    ),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        menuItem("Claude API Connection", tabName = "claude_auth", icon = icon("robot")),
        menuItem("BigQuery Authentication", tabName = "bigquery_auth", icon = icon("key")),
        menuItem("Generate DE Canvas", tabName = "generate_de_canvas", icon = icon("file-upload")),
        menuItem("Disciplined Ent. Canvas", tabName = "view_de_canvas", icon = icon("layer-group")),
        menuItem("Generate DE Roadmap", tabName = "generate_de_roadmap", icon = icon("route")),
        menuItem("Disciplined Ent. Roadmap", tabName = "view_de_roadmap", icon = icon("road")),
        menuItem("Generate BM Canvas", tabName = "generate_bm_canvas", icon = icon("file-import")),
        menuItem("Business Model Canvas", tabName = "view_bm_canvas", icon = icon("th"))
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),
      # CRITICAL FIX: Use do.call with the list of tabs
      do.call(tabItems, all_tabs)
    )
  )
}

create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  cat("\n🔧 Initializing module servers...\n")
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      cat(sprintf("   ✓ %s\n", module$module$name))
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager, session)
    }
  }
  cat("\n✅ All module servers initialized!\n\n")
}

`%||%` <- function(x, y) if (is.null(x)) y else x
cat("✔ Global configuration complete\n")