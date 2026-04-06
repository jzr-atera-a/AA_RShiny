# global.R - ML Interviews Prep Suite
# Based on: Machine Learning Interviews — Susan Shu Chang (O'Reilly)

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  ML INTERVIEWS PREP SUITE v1.0 - LOADING          ║\n")
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

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_prep_manager.R")

# ── UI Factory ──────────────────────────────────────────────────────────────
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  registry        <- module_loader$registry

  # ── Build tab bodies (same regardless of sidebar structure) ────────────────
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id        <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname          <- module$module$tabname
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_fn(module_id)
      )
    }
  }

  # ── Build sidebar menu items ───────────────────────────────────────────────
  # Strategy:
  #   • Modules with NO group field  → flat menuItem (direct tab link)
  #   • Modules WITH a group field   → collected into a collapsible menuItem
  #                                    parent with menuSubItem children
  #
  # Groups are ordered by their priority value in registry$groups.
  # The collapsible group is inserted at the position of the lowest-priority
  # module belonging to that group (i.e. where the first grouped module
  # would have appeared in the flat list).

  groups_cfg <- registry$groups %||% list()

  # Separate modules into ungrouped and grouped
  ungrouped <- Filter(function(m) is.null(m$module$group), enabled_modules)
  grouped   <- Filter(function(m) !is.null(m$module$group), enabled_modules)

  # Build a lookup: group_id -> list of modules (sorted by priority)
  group_modules <- list()
  for (m in grouped) {
    gid <- m$module$group
    if (is.null(group_modules[[gid]])) group_modules[[gid]] <- list()
    group_modules[[gid]] <- c(group_modules[[gid]], list(m))
  }

  # Sort each group's modules by priority
  for (gid in names(group_modules)) {
    mods <- group_modules[[gid]]
    group_modules[[gid]] <- mods[order(sapply(mods, function(m) m$module$priority))]
  }

  # Build group menu items
  group_menu_items <- list()
  for (gid in names(groups_cfg)) {
    grp  <- groups_cfg[[gid]]
    mods <- group_modules[[gid]]
    if (is.null(mods) || length(mods) == 0) next

    sub_items <- lapply(mods, function(m) {
      menuSubItem(
        m$module$name,
        tabName = m$module$tabname,
        icon    = icon(m$module$icon)
      )
    })

    group_menu_items[[gid]] <- list(
      priority  = grp$priority %||% 999,
      menu_item = do.call(menuItem, c(
        list(grp$label, icon = icon(grp$icon), startExpanded = FALSE),
        sub_items
      ))
    )
  }

  # Merge ungrouped flat items + group items, sorted by effective priority
  # Each ungrouped module gets its own priority; each group gets the group priority
  all_sidebar_entries <- list()

  for (m in ungrouped) {
    all_sidebar_entries <- c(all_sidebar_entries, list(list(
      priority  = m$module$priority,
      menu_item = menuItem(
        m$module$name,
        tabName = m$module$tabname,
        icon    = icon(m$module$icon)
      )
    )))
  }

  for (gid in names(group_menu_items)) {
    all_sidebar_entries <- c(all_sidebar_entries, list(group_menu_items[[gid]]))
  }

  # Sort by priority
  all_sidebar_entries <- all_sidebar_entries[
    order(sapply(all_sidebar_entries, function(e) e$priority))
  ]

  final_menu_items <- lapply(all_sidebar_entries, function(e) e$menu_item)

  # ── Assemble dashboard ─────────────────────────────────────────────────────
  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "ML Interviews Prep"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        div(class = "sidebar-book-badge",
          HTML("<div class='book-chip'>📖 Susan Shu Chang</div>
                <div class='book-sub'>Machine Learning Interviews</div>")
        ),
        do.call(tagList, final_menu_items)
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
