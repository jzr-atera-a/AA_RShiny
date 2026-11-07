# global.R — ML System Design Prep v1.2 (Kravchenko & Babushkin, Manning 2025)
cat("\n╔═══════════════════════════════════════════════════════╗\n")
cat("║  ML SYSTEM DESIGN PREP (Kravchenko & Babushkin) v1.2 ║\n")
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
  registry <- module_loader$registry

  # Build tab items for all enabled modules
  tab_items_list <- lapply(enabled, function(m) {
    fn <- paste0(m$module$id, "_ui")
    if (exists(fn, envir=.GlobalEnv))
      tabItem(tabName=m$module$tabname, get(fn, envir=.GlobalEnv)(m$module$id))
  })
  tab_items_list <- tab_items_list[!sapply(tab_items_list, is.null)]

  # Build sidebar: grouped or flat
  groups <- registry$groups
  enabled_ids <- sapply(enabled, function(m) m$module$id)

  if (!is.null(groups)) {
    menu_items <- lapply(groups, function(g) {
      group_mods <- g$modules[g$modules %in% enabled_ids]
      if (length(group_mods) == 0) return(NULL)
      sub_items <- lapply(group_mods, function(mid) {
        m <- enabled[[which(enabled_ids == mid)]]
        menuSubItem(m$module$name, tabName=m$module$tabname, icon=icon(m$module$icon))
      })
      do.call(menuItem, c(
        list(text=g$label, icon=icon(g$icon %||% "folder"),
             startExpanded=(isTRUE(g$expanded))),
        sub_items
      ))
    })
    menu_items <- menu_items[!sapply(menu_items, is.null)]
  } else {
    menu_items <- lapply(enabled, function(m) {
      menuItem(m$module$name, tabName=m$module$tabname, icon=icon(m$module$icon))
    })
  }

  dashboardPage(
    skin = "red",
    dashboardHeader(title="ML SysDesign Prep"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        div(class="sidebar-book-badge",
            div(class="book-chip", "\U0001F4D6 ML System Design"),
            div(class="book-authors", "Kravchenko \u00B7 Babushkin"),
            div(class="book-pub", "Manning \u2014 Feb 2025")),
        do.call(tagList, menu_items)
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel="stylesheet", type="text/css", href="css/global.css"),
        tags$meta(charset="UTF-8")
      ),
      do.call(tabItems, tab_items_list)
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
