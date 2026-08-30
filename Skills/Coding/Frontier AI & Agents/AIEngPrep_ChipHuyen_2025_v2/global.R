# global.R - AI Engineering Interview Prep Suite
# Based on: AI Engineering: Building Applications with Foundation Models — Chip Huyen (O'Reilly, 2025)

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  AI ENGINEERING PREP SUITE v1.0 - LOADING         ║\n")
cat("╚════════════════════════════════════════════════════╝\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
  library(DT)
  library(plotly)
  library(jsonlite)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_prep_manager.R")

# Prep manager initialised inside server (reactive context)
prep_manager <- NULL

# ── UI Factory ──────────────────────────────────────────
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id        <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname          <- module$module$tabname

    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_function(module_id)
      )
    }
  }

  all_menu_items <- lapply(enabled_modules, function(module) {
    menuItem(
      module$module$name,
      tabName = module$module$tabname,
      icon    = icon(module$module$icon)
    )
  })

  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "AI Engineering Prep"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        div(class = "sidebar-book-badge",
            HTML("<div class='book-chip'>📖 Chip Huyen</div><div class='book-sub'>AI Engineering (2025)</div>")
        ),
        div(class = "sidebar-role-badge",
            HTML("<div class='role-chip'>🎯 VP Research, ML — A1</div>")
        ),
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

# ── Server Factory ──────────────────────────────────────
create_server <- function(module_loader, prep_mgr) {
  enabled_modules <- module_loader$get_enabled_modules()

  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")

    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, prep_mgr)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
