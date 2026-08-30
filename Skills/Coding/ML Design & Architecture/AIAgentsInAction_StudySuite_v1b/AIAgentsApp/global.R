# global.R — AI Agents in Action Study Suite

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  AI AGENTS IN ACTION — STUDY SUITE v1.0 — LOADING  ║\n")
cat("║  Based on: Michael Lanham (Manning Publications)    ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

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

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_study_manager.R")

`%||%` <- function(x, y) if (is.null(x)) y else x

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
    skin = "purple",
    dashboardHeader(title = "AI Agents in Action"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        div(class = "sidebar-book-badge",
            HTML("<div class='book-chip'>🤖 Michael Lanham</div>
                  <div class='book-sub'>AI Agents in Action — Manning</div>")
        ),
        do.call(tagList, all_menu_items)
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel="stylesheet", type="text/css", href="css/global.css"),
        tags$meta(charset="UTF-8"),
        tags$meta(name="viewport", content="width=device-width, initial-scale=1.0")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

create_server <- function(module_loader, study_mgr) {
  enabled_modules <- module_loader$get_enabled_modules()

  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")

    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, study_mgr)
    }
  }
}

cat("✓ Global configuration complete\n\n")
