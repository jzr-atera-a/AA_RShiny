# global.R - ML System Design Interview Prep Suite
# Based on: Designing Machine Learning Systems — Chip Huyen (O'Reilly)

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  ML DESIGN INTERVIEW PREP SUITE v1.0 - LOADING    ║\n")
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

prep_manager <- NULL

# ── UI Factory ──────────────────────────────────────────────────────────────
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  registry        <- module_loader$registry

  # ── Build tab body items ─────────────────────────────────────────────────
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

  # ── Build grouped sidebar menu ───────────────────────────────────────────
  groups_def <- registry$groups  # ordered group definitions
  if (is.null(groups_def)) {
    # Fallback: flat list (backwards compatible)
    all_menu_items <- lapply(enabled_modules, function(module) {
      menuItem(
        module$module$name,
        tabName = module$module$tabname,
        icon    = icon(module$module$icon)
      )
    })
  } else {
    # Sort groups by priority
    group_ids <- names(groups_def)
    group_priorities <- sapply(group_ids, function(g) groups_def[[g]]$priority %||% 999)
    group_ids <- group_ids[order(group_priorities)]

    all_menu_items <- lapply(group_ids, function(gid) {
      gdef <- groups_def[[gid]]

      # Get modules in this group, sorted by priority
      group_mods <- Filter(function(m) {
        isTRUE(m$module$group == gid)
      }, enabled_modules)

      if (length(group_mods) == 0) return(NULL)

      # Build sub-items
      sub_items <- lapply(group_mods, function(module) {
        menuSubItem(
          module$module$name,
          tabName = module$module$tabname,
          icon    = icon(module$module$icon)
        )
      })

      # Build parent menuItem with children
      do.call(menuItem,
        c(
          list(
            text      = gdef$label,
            icon      = icon(gdef$icon %||% "folder"),
            startExpanded = (gid == "intro")
          ),
          sub_items
        )
      )
    })

    # Remove NULLs (empty groups)
    all_menu_items <- Filter(Negate(is.null), all_menu_items)
  }

  # ── Sidebar CSS additions ─────────────────────────────────────────────────
  sidebar_css <- "
  /* Group header items */
  .sidebar-menu .treeview > a {
    font-weight: 700 !important;
    font-size: 12px !important;
    letter-spacing: 0.3px;
    color: rgba(255,255,255,0.90) !important;
    border-left: 3px solid transparent;
    padding-top: 9px !important;
    padding-bottom: 9px !important;
  }
  .sidebar-menu .treeview > a:hover,
  .sidebar-menu .treeview.active > a {
    background: rgba(255,255,255,0.12) !important;
    border-left: 3px solid rgba(255,255,255,0.6) !important;
  }
  /* Sub-item indentation and style */
  .sidebar-menu .treeview-menu {
    background: rgba(0,0,0,0.18) !important;
    padding: 2px 0 4px !important;
  }
  .sidebar-menu .treeview-menu > li > a {
    font-size: 11px !important;
    font-weight: 500 !important;
    color: rgba(255,255,255,0.75) !important;
    padding: 5px 5px 5px 26px !important;
    border-left: 3px solid transparent;
  }
  .sidebar-menu .treeview-menu > li > a:hover,
  .sidebar-menu .treeview-menu > li.active > a {
    background: rgba(255,255,255,0.10) !important;
    border-left: 3px solid #00A39A !important;
    color: #fff !important;
  }
  .sidebar-menu .treeview-menu > li.active > a {
    color: #fff !important;
    font-weight: 700 !important;
  }
  /* Arrow indicator */
  .sidebar-menu .treeview > a > .pull-right-container > .fa-angle-left {
    color: rgba(255,255,255,0.5) !important;
  }
  /* Chapter label pill */
  .ch-pill {
    display: inline-block;
    background: rgba(255,255,255,0.15);
    border-radius: 4px;
    padding: 1px 6px;
    font-size: 9px;
    font-weight: 800;
    letter-spacing: 0.5px;
    margin-right: 4px;
    vertical-align: middle;
    color: rgba(255,255,255,0.9);
  }
  "

  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "ML Design Prep"),
    dashboardSidebar(
      tags$head(tags$style(HTML(sidebar_css))),
      sidebarMenu(
        id = "sidebar_menu",
        div(class = "sidebar-book-badge",
            HTML("<div class='book-chip'>📖 Chip Huyen</div><div class='book-sub'>Designing ML Systems</div>")
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

# ── Server Factory ───────────────────────────────────────────────────────────
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
