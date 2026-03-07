# global.R
cat("\n╔═══════════════════════════════════════════════════════╗\n")
cat("║  ML SYSTEM DESIGN PREP (Kravchenko & Babushkin) v1.0 ║\n")
cat("╚═══════════════════════════════════════════════════════╝\n\n")

suppressPackageStartupMessages({
  library(shiny); library(shinydashboard); library(R6)
  library(yaml);  library(purrr);         library(magrittr)
  library(dplyr); library(DT);            library(plotly); library(jsonlite)
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_prep_manager.R")

`%||%` <- function(x, y) if (is.null(x)) y else x

create_ui <- function(module_loader) {
  enabled <- module_loader$get_enabled_modules()

  tab_items  <- lapply(enabled, function(m) {
    fn <- paste0(m$module$id, "_ui")
    if (exists(fn, envir=.GlobalEnv))
      tabItem(tabName=m$module$tabname, get(fn, envir=.GlobalEnv)(m$module$id))
  })
  menu_items <- lapply(enabled, function(m) {
    menuItem(m$module$name, tabName=m$module$tabname, icon=icon(m$module$icon))
  })

  dashboardPage(
    skin = "red",
    dashboardHeader(title="ML SysDesign Prep"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        div(class="sidebar-book-badge",
            div(class="book-chip", "📖 ML System Design"),
            div(class="book-authors", "Kravchenko · Babushkin"),
            div(class="book-pub", "Manning — Feb 2025")),
        do.call(tagList, menu_items)
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel="stylesheet", type="text/css", href="css/global.css"),
        tags$meta(charset="UTF-8")
      ),
      do.call(tabItems, tab_items[!sapply(tab_items, is.null)])
    )
  )
}

create_server <- function(module_loader, prep_mgr) {
  for (m in module_loader$get_enabled_modules()) {
    fn <- paste0(m$module$id, "_server")
    if (exists(fn, envir=.GlobalEnv)) get(fn, envir=.GlobalEnv)(m$module$id, prep_mgr)
  }
}

cat("✓ global.R ready\n\n")
