# ============================================================================
# GLOBAL CONFIGURATION  —  Notebook Builder Dashboard
# ============================================================================

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║      NOTEBOOK BUILDER DASHBOARD - INITIALISING      ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

options(shiny.maxRequestSize = 50 * 1024^2)

# ── Core packages ─────────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyjs)
  library(R6)
  library(yaml)
  library(purrr)
  library(httr)
  library(jsonlite)
  library(processx)
})

# ── Utility files ─────────────────────────────────────────────────────────
source("R/module_loader.R")
source("R/utils_session.R")
source("R/utils_python.R")

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ── UI factory ────────────────────────────────────────────────────────────
create_ui <- function(module_loader) {
  enabled <- module_loader$get_enabled_modules()

  all_tabs <- lapply(enabled, function(module) {
    mid   <- module$module$id
    tabfn <- paste0(mid, "_ui")
    tabItem(
      tabName = module$module$menu$tabname,
      if (exists(tabfn, envir = .GlobalEnv)) get(tabfn, envir = .GlobalEnv)(mid)
    )
  })

  all_menu <- lapply(enabled, function(module) {
    m <- module$module$menu
    menuItem(m$label, tabName = m$tabname, icon = icon(m$icon))
  })

  dashboardPage(
    skin = "purple",

    dashboardHeader(
      title     = tags$span(icon("book"), " Notebook Builder"),
      titleWidth = 300
    ),

    dashboardSidebar(
      width = 280,
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        useShinyjs()
      ),
      sidebarMenu(id = "sidebar_menu", do.call(tagList, all_menu))
    ),

    dashboardBody(
      useShinyjs(),
      tags$head(
        tags$style(HTML("
          .sidebar-toggle { display: none !important; }
          details > summary { user-select: none; }
          details > summary::-webkit-details-marker { color: #667eea; }
        "))
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# ── Server factory ────────────────────────────────────────────────────────
create_server <- function(module_loader, session_mgr, python_bridge, session) {
  enabled <- module_loader$get_enabled_modules()

  # Shared reactive app state (passed to all modules)
  app_state <- reactiveValues(
    run_dir  = session_mgr$get("last_run_dir", ""),
    running  = FALSE,
    resuming = FALSE,
    plan     = NULL
  )

  cat("Initialising", length(enabled), "module server(s)...\n")

  for (module in enabled) {
    mid    <- module$module$id
    servfn <- paste0(mid, "_server")
    if (!exists(servfn, envir = .GlobalEnv)) next

    fn <- get(servfn, envir = .GlobalEnv)

    # Pass appropriate singletons to each module
    if (mid == "settings") {
      fn(mid, session_mgr, python_bridge, session)
    } else if (mid == "task") {
      fn(mid, session_mgr, python_bridge, app_state, session)
    } else if (mid == "monitor") {
      fn(mid, session_mgr, python_bridge, app_state, session)
    } else if (mid == "outputs") {
      fn(mid, session_mgr, app_state, session)
    } else {
      fn(mid, session_mgr, session)
    }
  }

  cat("✓ All module servers initialised\n")
}

cat("✓ global.R complete\n\n")
