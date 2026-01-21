# global.R - Global Configuration
# Multi-Asset Analysis Dashboard - Modular Architecture
# ======================================================

# Startup message
cat("\n╔═══════════════════════════════════════╗\n")
cat("║   ASSET DASHBOARD - INITIALIZING     ║\n")
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
source("R/utils_data.R")

# Initialize Data manager (with reactive triggers)
data_manager <- DataManager$new()

# UI Factory Function
create_ui <- function(module_loader) {
  
  # Get enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Build tab items explicitly in a for loop
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
      title = module_loader$registry$app$name %||% "Multi-Asset Dashboard",
      tags$li(
        class = "dropdown",
        tags$a(
          href = "#",
          icon("refresh"),
          "Refresh Data",
          onclick = "Shiny.onInputChange('global_refresh', Math.random())"
        )
      )
    ),
    
    # Sidebar - Asset selector + menu
    dashboardSidebar(
      div(
        style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        selectInput("global_asset_class", 
                    "Asset Class:",
                    choices = c("Cryptocurrencies" = "crypto", 
                                "Private Equity" = "equity",
                                "Commodities" = "commodity"),
                    selected = "crypto",
                    width = "100%")
      ),
      
      div(
        style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        conditionalPanel(
          condition = "input.global_asset_class == 'crypto'",
          selectInput("global_crypto_asset", 
                      "Cryptocurrency:",
                      choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                  "Ethereum (ETH-USD)" = "ETH-USD",
                                  "Cardano (ADA-USD)" = "ADA-USD"),
                      selected = "BTC-USD",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.global_asset_class == 'equity'",
          selectInput("global_equity_asset", 
                      "Private Equity:",
                      choices = c("NVIDIA (NVDA)" = "NVDA",
                                  "Microsoft (MSFT)" = "MSFT",
                                  "Apple (AAPL)" = "AAPL"),
                      selected = "NVDA",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.global_asset_class == 'commodity'",
          selectInput("global_commodity_asset", 
                      "Commodity:",
                      choices = c("Gold (GC=F)" = "GC=F",
                                  "Crude Oil (CL=F)" = "CL=F",
                                  "Natural Gas (NG=F)" = "NG=F"),
                      selected = "GC=F",
                      width = "100%")
        )
      ),
      
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
        )
      ),
      
      # Tab items
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function  
create_server <- function(module_loader, data_manager, input, output, session) {
  # Get only enabled modules
  enabled_modules <- module_loader$get_enabled_modules()
  
  # Global asset selection observer
  observe({
    asset_class <- input$global_asset_class
    current_asset <- if (asset_class == "crypto") {
      input$global_crypto_asset
    } else if (asset_class == "equity") {
      input$global_equity_asset
    } else {
      input$global_commodity_asset
    }
    
    if (!is.null(current_asset) && current_asset != "") {
      data_manager$set_current_asset(current_asset, asset_class)
    }
  })
  
  # Global refresh observer
  observeEvent(input$global_refresh, {
    data_manager$trigger_refresh()
  })
  
  # Initialize each module's server
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, data_manager)
    }
  }
}

# Helper function
`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
