# global.R - Global Configuration
# UNIFIED SUITE: Flex Table + Mind Map + Knowledge Graph v1.0
# =============================================================
# One app, one shared BigQuery connection and one shared Claude API
# connection (grouped under "API Configuration" in the sidebar), with
# each of the three original apps' tabs grouped under their own named
# section ("Flex Table", "Mind Map", "Knowledge Graph"). See
# R/utils_api.R for how one shared APIManager class serves three
# separate BigQuery tables, and R/module_loader.R for the recursive
# module-discovery fix that lets modules live inside these grouped
# subfolders (modules/"Flex Table"/generate_table/manifest.yml etc)
# instead of assuming a flat modules/<id>/ layout.

cat("\n╔══════════════════════════════════════════════╗\n")
cat("║  UNIFIED SUITE - INIT                         ║\n")
cat("║  Flex Table + Mind Map + Knowledge Graph      ║\n")
cat("╚══════════════════════════════════════════════╝\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
})

# ============================================================
# DEPLOYMENT DEPENDENCY DECLARATIONS - DO NOT REMOVE
# ============================================================
# rsconnect's static dependency scanner can only see literal
# library()/pkg::fn() calls, not packages named inside YAML manifests,
# so every package any module needs (across all three sub-suites) is
# declared here explicitly. No graph/table visualization R package is
# needed anywhere - D3, Cytoscape.js are all loaded client-side via
# CDN (see create_ui() below) and driven by raw HTML/JS embedded from
# R; the Flex Table's comparison grid is plain HTML/CSS.
suppressPackageStartupMessages({
  library(shinyjs)
  library(httr)
  library(curl)
  library(jsonlite)
  library(bigrquery)
  library(DT)
  library(plotly)
  library(dplyr)
  library(stringr)
  library(tidyr)
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")

api_manager <- APIManager$new()

# Icon fallback only used if a group in the registry's `groups:` list
# is missing its own `icon:` field.
DEFAULT_GROUP_ICON <- "folder"

create_ui <- function(module_loader) {

  enabled_modules <- module_loader$get_enabled_modules()
  registry <- module_loader$registry

  # ---- Build tab items (flat, unaffected by grouping) ----
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname %||% module_id

    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_function(module_id))
    } else {
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(box(title = paste("Module:", module$module$name), status = "warning", solidHeader = TRUE, width = 12,
                    h4("This module is enabled but not yet implemented"),
                    p("Module ID:", module_id), p("Expected UI function:", ui_function_name)))
      )
    }
  }

  # ---- Build GROUPED, COLLAPSIBLE sidebar menu ----
  # Mirrors the proven-working ML System Design Prep reference app
  # exactly: groups are defined as a top-level `groups:` list in the
  # registry (each with an explicit `modules: [id, id, ...]` member
  # list), NOT as a per-module field. For each group, filter its
  # declared member ids against the currently-enabled modules, build
  # one menuSubItem() per surviving member, then build the group's
  # menuItem() via do.call() splicing those sub-items in as `...` -
  # the exact same construction (including startExpanded) as the
  # confirmed-working reference.
  groups <- registry$groups
  enabled_ids <- sapply(enabled_modules, function(m) m$module$id)

  if (!is.null(groups)) {
    menu_items <- lapply(groups, function(g) {
      group_mods <- g$modules[g$modules %in% enabled_ids]
      if (length(group_mods) == 0) return(NULL)

      sub_items <- lapply(group_mods, function(mid) {
        m <- enabled_modules[[which(enabled_ids == mid)]]
        menuSubItem(m$module$menu$label, tabName = m$module$menu$tabname, icon = icon(m$module$menu$icon))
      })

      do.call(menuItem, c(
        list(text = g$label, icon = icon(g$icon %||% DEFAULT_GROUP_ICON),
             startExpanded = isTRUE(g$expanded)),
        sub_items
      ))
    })
    menu_items <- menu_items[!sapply(menu_items, is.null)]
  } else {
    # Fallback: no groups defined in the registry - flat menu, same as
    # every one of the three original standalone apps.
    menu_items <- lapply(enabled_modules, function(m) {
      menuItem(m$module$menu$label, tabName = m$module$menu$tabname, icon = icon(m$module$menu$icon))
    })
  }

  dashboardPage(
    dashboardHeader(title = module_loader$registry$app$name %||% "Unified Suite"),

    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, menu_items))
    ),

    dashboardBody(
      shinyjs::useShinyjs(),

      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),

        # D3.js - Mind Map's tidy-tree visualizer + Knowledge Graph's force-directed visualizer
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/d3/7.8.5/d3.min.js"),
        # d3-sankey - Sankey Graph's flow-diagram layout plugin (computes node y-positions/
        # heights and link curve widths from link values; does not ship with core d3)
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/d3-sankey/0.12.3/d3-sankey.min.js"),
        # Cytoscape.js - Knowledge Graph's second visualization tab
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.28.1/cytoscape.min.js"),
        # MathJax - LaTeX rendering shared by all three suites
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS-MML_HTMLorMML"),
        tags$script(HTML("
          if (typeof MathJax !== 'undefined') {
            MathJax.Hub.Config({
              tex2jax: {
                inlineMath: [['$','$'], ['\\\\(','\\\\)']],
                displayMath: [['$$','$$'], ['\\\\[','\\\\]']],
                processEscapes: true
              },
              'HTML-CSS': { linebreaks: { automatic: true } },
              SVG: { linebreaks: { automatic: true } }
            });
          }
        "))
      ),

      do.call(tabItems, all_tabs)
    )
  )
}

create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()

  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")

    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
