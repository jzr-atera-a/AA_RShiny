# global.R - Global Configuration
# Knowledge Graph Suite v1.0 - Modular Architecture
# =============================================================
# Same modular architecture, CSS design system, and API-manager
# reactive-trigger pattern as the Flexible Comparison Table Suite and
# Mind Map Suite, adapted to store and render a CLAUDE-GENERATED
# KNOWLEDGE GRAPH: typed entities connected by typed, directed
# relationships (subject-predicate-object triples) - no root, no
# hierarchy, cycles and many-to-many connections are all normal.

cat("\n╔══════════════════════════════════════════════╗\n")
cat("║  KNOWLEDGE GRAPH SUITE - INIT                 ║\n")
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
# See sibling apps for the full explanation: rsconnect's static
# dependency scanner can only see literal library()/pkg::fn() calls,
# not packages named inside YAML manifests, so every package any
# module might need is declared here explicitly. Note: NO graph
# visualization R package is needed - D3 and Cytoscape.js are both
# loaded client-side via CDN (see create_ui() below) and driven by
# raw HTML/JS embedded from R, the same pattern used successfully for
# the Mind Map Suite's D3 visualizer.
suppressPackageStartupMessages({
  library(shinyjs)
  library(httr)
  library(curl)
  library(jsonlite)
  library(bigrquery)
  library(DT)
  library(dplyr)
  library(stringr)
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api.R")

api_manager <- APIManager$new()

create_ui <- function(module_loader) {

  enabled_modules <- module_loader$get_enabled_modules()

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname <- module$module$menu$tabname %||% module_id

    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_function <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_function(module_id)
      )
    } else {
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(
          box(
            title = paste("Module:", module$module$name),
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            h4("This module is enabled but not yet implemented"),
            p("Module ID:", module_id),
            p("Expected UI function:", ui_function_name)
          )
        )
      )
    }
  }

  all_menu_items <- lapply(enabled_modules, function(module) {
    menu_info <- module$module$menu
    menuItem(
      menu_info$label,
      tabName = menu_info$tabname,
      icon = icon(menu_info$icon)
    )
  })

  dashboardPage(
    dashboardHeader(
      title = module_loader$registry$app$name %||% "Knowledge Graph Suite"
    ),

    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, all_menu_items)
      )
    ),

    dashboardBody(
      shinyjs::useShinyjs(),

      tags$head(
        tags$link(
          rel = "stylesheet",
          type = "text/css",
          href = "css/global.css"
        ),
        tags$meta(charset = "UTF-8"),
        tags$meta(
          name = "viewport",
          content = "width=device-width, initial-scale=1.0"
        ),
        # D3.js - powers the "D3 Visualization" tab (force-directed graph)
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/d3/7.8.5/d3.min.js"),
        # Cytoscape.js - powers the "Cytoscape Visualization" tab. Uses
        # only Cytoscape core (built-in 'cose' force-directed layout) -
        # deliberately not pulling in extra layout extensions (fcose,
        # cose-bilkent) since their inter-package version compatibility
        # can't be verified without a live browser to test against here.
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.28.1/cytoscape.min.js"),
        # MathJax for LaTeX formula rendering inside entity/relationship descriptions
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
