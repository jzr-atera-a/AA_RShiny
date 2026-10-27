# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================

cat("\n═══ TRAVEL PHOTO SELECTOR - INITIALIZING ═══\n\n")

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# Core packages (always required)
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(jsonlite)
})

# Source utility files
source("R/module_loader.R", encoding = "UTF-8")
source("R/utils_common.R", encoding = "UTF-8")
source("R/utils_photos.R", encoding = "UTF-8")
source("R/utils_watermark.R", encoding = "UTF-8")

# UI Factory Function
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  # Build tab items
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname

    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_function(module_id)
      )
    }
  }

  # Build menu items
  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(
      menu_info$label,
      tabName = menu_info$tabname,
      icon = icon(menu_info$icon)
    )
  })

  dashboardPage(
    skin = "purple",
    title = "Mis Fotos de Viaje",

    dashboardHeader(
      title = "📷 Mis Fotos de Viaje",
      titleWidth = 300
    ),

    dashboardSidebar(
      width = 300,
      tags$head(
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
        tags$script(HTML("document.documentElement.lang = 'es-MX';")),
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$script(src = "js/app.js"),
        tags$style(HTML("
          .main-header .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
          .main-header .logo { background: linear-gradient(135deg, #5a67d8 0%, #6b46a1 100%) !important; font-size: 22px !important; }
          .main-sidebar { background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; }
          .sidebar-menu > li.active > a { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
          .content-wrapper { background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; }
          .box { border-radius: 12px !important; box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important; }
          .box-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; color: white !important; }
          .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
          .btn-success { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%) !important; }
        "))
      ),
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),

    dashboardBody(
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, photo_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()

  cat("Initializing", length(enabled_modules), "module server(s)...\n")

  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")

    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, photo_manager, session)
    }
  }

  cat("✓ All module servers initialized\n")
}

cat("✓ Global configuration complete\n\n")
