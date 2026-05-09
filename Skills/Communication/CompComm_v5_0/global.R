# global.R - Compelling Communication @ Atera Analytics

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
  library(httr)
})

source("R/module_loader.R")
source("R/utils_common.R")

# Sidebar book badge widget
sidebar_book_badge <- div(class = "sidebar-book-badge",
  div(class = "book-chip", "COMPELLING COMMUNICATION"),
  div(class = "book-authors", "Simon Hall"),
  div(class = "book-pub", "Cambridge University Press")
)

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

  all_menu_items <- lapply(enabled_modules, function(module) {
    menuItem(module$module$name, tabName = module$module$tabname,
             icon = icon(module$module$icon))
  })

  dashboardPage(
    skin = "black",
    dashboardHeader(title = span(
      style = "font-family:'Playfair Display',serif; font-size:13px; color:#F5C842;",
      "Compelling Comm. S. Hall"
    )),
    dashboardSidebar(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css",
                  href = "https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;800&family=Nunito:wght@400;600;700&family=JetBrains+Mono:wght@400;500&display=swap")
      ),
      sidebar_book_badge,
      sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu_items))
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

create_server <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      get(server_function_name, envir = .GlobalEnv)(module_id)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x
cat("✓ Global configuration complete\n\n")
