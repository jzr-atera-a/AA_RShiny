# global.R - MTS Frontier AI Interview Prep Suite v1.0

cat("\n=== MTS FRONTIER AI INTERVIEW PREP - LOADING ===\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
})

source("R/module_loader.R")
source("R/utils_common.R")

# UI Factory - flat sidebar driven entirely by the module registry,
# in the same order they're prioritised in _module_registry.yml
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id        <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname          <- module$module$tabname
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_fn(module_id))
    }
  }

  menu_items <- lapply(enabled_modules, function(module) {
    menuItem(
      module$module$name,
      tabName = module$module$tabname,
      icon    = icon(module$module$icon)
    )
  })

  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "MTS Frontier AI Prep"),
    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, menu_items))
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

# Server Factory - never pass session to module servers
create_server <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_fn <- get(server_function_name, envir = .GlobalEnv)
      server_fn(module_id)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("Global configuration complete\n\n")
