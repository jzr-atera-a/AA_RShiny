# global.R - Welch Group Fleet Monitor
# Volvo Group vehicle API v1.0.6 (Renault Trucks Developer Portal)
# Architecture mirrors IntegratedAVSuite: modular, one file per tab

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  WELCH GROUP FLEET MONITOR v1.0 - LOADING           ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

# ── Packages ──────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
  library(magrittr)
  library(dplyr)
  library(httr)
  library(curl)
  library(jsonlite)
  library(leaflet)
  library(htmltools)
  library(plotly)
  library(DT)
})

cat("✓ Packages loaded\n")

# ── Source utilities ──────────────────────────────────────────────
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_api_manager.R")

cat("✓ Utilities sourced\n")

# ── Shared API Manager (R6 object, lives for app lifetime) ────────
api_manager <- VehicleAPIManager$new()

# ── UI Factory ────────────────────────────────────────────────────
# CRITICAL: tabs built with FOR LOOP (see README / IntegratedAVSuite pattern)
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  # Build tabItems
  all_tabs <- list()
  for (module in enabled_modules) {
    module_id       <- module$module$id
    ui_fn_name      <- paste0(module_id, "_ui")
    tabname         <- module$module$tabname

    if (exists(ui_fn_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_fn_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        ui_fn(module_id)
      )
    } else {
      warning("UI function not found: ", ui_fn_name)
    }
  }

  # Build sidebar menu items
  all_menu_items <- lapply(enabled_modules, function(module) {
    menuItem(
      text    = module$module$name,
      tabName = module$module$tabname,
      icon    = icon(module$module$icon)
    )
  })

  # ── Complete dashboard ────────────────────────────────────────
  dashboardPage(

    dashboardHeader(
      title = tags$span(
        tags$img(src = "css/truck_icon.svg",
                 height = "22px", style = "margin-right:6px;"),
        "Welch Group Fleet"
      ),
      titleWidth = 240
    ),

    dashboardSidebar(
      width = 240,
      sidebarMenu(
        id = "sidebar_menu",
        tags$li(class = "wg-sidebar-brand",
          tags$div(
            tags$b("EV ARTIC FLEET MONITOR"),
            tags$br(),
            tags$small("Powered by Volvo Group API v1.0.6")
          )
        ),
        tags$hr(style = "border-color:#1a9b9b;margin:6px 15px;"),
        do.call(tagList, all_menu_items),
        tags$hr(style = "border-color:#1a3a3a;margin:6px 15px;"),
        tags$li(class = "wg-sidebar-footer",
          tags$small("api.renault-trucks.com"),
          tags$br(),
          tags$small("TA70WTL · N88GNW")
        )
      )
    ),

    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/theme.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
        # Inline DT Buttons CSS
        tags$link(rel = "stylesheet",
          href = "https://cdn.datatables.net/buttons/2.3.6/css/buttons.dataTables.min.css")
      ),
      do.call(tabItems, all_tabs),
    )
  )
}

# ── Server Factory ────────────────────────────────────────────────
# CRITICAL: Do NOT pass session to module server functions.
# moduleServer() handles session internally.
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()

  for (module in enabled_modules) {
    module_id      <- module$module$id
    server_fn_name <- paste0(module_id, "_server")

    if (exists(server_fn_name, envir = .GlobalEnv)) {
      server_fn <- get(server_fn_name, envir = .GlobalEnv)
      # Pass only id + shared api_manager — NOT session
      server_fn(module_id, api_manager)
    } else {
      warning("Server function not found: ", server_fn_name)
    }
  }
}

# ── Misc helpers ──────────────────────────────────────────────────
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

cat("✓ global.R complete\n\n")
