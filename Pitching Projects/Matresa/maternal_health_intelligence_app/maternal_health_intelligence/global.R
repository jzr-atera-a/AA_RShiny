# global.R - Maternal Health Intelligence App
# Independent app: API Configuration group (reused, generic) +
# Maternal Health Monitor group (new, 4-subtab module).
# =========================================================

cat("\n+--------------------------------------------------+\n")
cat("|  MATERNAL HEALTH INTELLIGENCE APP - INITIALISING  |\n")
cat("|  API Configuration + Maternal Health Monitor      |\n")
cat("+--------------------------------------------------+\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
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
source("R/utils_ppd_risk.R")

api_manager <- APIManager$new()

DEFAULT_GROUP_ICON <- "folder"

`%||%` <- function(x, y) if (is.null(x)) y else x

# ── UI ────────────────────────────────────────────────────────────────────────
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()
  registry        <- module_loader$registry

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id        <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname          <- module$module$menu$tabname %||% module_id

    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_fn(module_id))
    } else {
      all_tabs[[length(all_tabs) + 1]] <- tabItem(
        tabName = tabname,
        fluidRow(box(title = paste("Module:", module$module$name), status = "warning",
                     solidHeader = TRUE, width = 12,
                     h4("Module enabled but UI not yet implemented"),
                     p("Module ID:", module_id)))
      )
    }
  }

  groups      <- registry$groups
  enabled_ids <- sapply(enabled_modules, function(m) m$module$id)

  if (!is.null(groups)) {
    menu_items <- lapply(groups, function(g) {
      group_mods <- g$modules[g$modules %in% enabled_ids]
      if (length(group_mods) == 0) return(NULL)

      sub_items <- lapply(group_mods, function(mid) {
        m <- enabled_modules[[which(enabled_ids == mid)]]
        menuSubItem(m$module$menu$label,
                    tabName = m$module$menu$tabname,
                    icon    = icon(m$module$menu$icon))
      })

      do.call(menuItem, c(
        list(text          = g$label,
             icon          = icon(g$icon %||% DEFAULT_GROUP_ICON),
             startExpanded = isTRUE(g$expanded)),
        sub_items
      ))
    })
    menu_items <- menu_items[!sapply(menu_items, is.null)]
  } else {
    menu_items <- lapply(enabled_modules, function(m) {
      menuItem(m$module$menu$label,
               tabName = m$module$menu$tabname,
               icon    = icon(m$module$menu$icon))
    })
  }

  dashboardPage(
    skin = "black",

    dashboardHeader(
      title = tags$span("Maternal Health Intelligence"),
      titleWidth = 320
    ),

    dashboardSidebar(
      width = 280,
      sidebarMenu(id = "sidebar_menu", do.call(tagList, menu_items)),
      tags$div(
        style = "position:absolute; bottom:0; left:0; right:0; padding:14px 18px;
                 border-top:1px solid rgba(255,255,255,0.1); font-size:10px;
                 color:rgba(255,255,255,0.5);",
        tags$strong("Maternal Health Intelligence App"), tags$br(),
        "Simulated data - screening & monitoring prototype", tags$br(),
        paste0("v", registry$app$version %||% "1.0.0")
      )
    ),

    dashboardBody(
      shinyjs::useShinyjs(),

      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
        tags$title("Maternal Health Intelligence App")
      ),

      div(class = "disclaimer-banner",
        icon("info-circle"),
        " This is a screening and monitoring prototype using simulated data. ",
        "It does not diagnose postnatal depression. A flagged score means a ",
        "conversation with a clinician is recommended, not that a diagnosis has been made."
      ),

      do.call(tabItems, all_tabs)
    )
  )
}

# ── Server ────────────────────────────────────────────────────────────────────
create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()
  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_fn <- get(server_function_name, envir = .GlobalEnv)
      server_fn(module_id, api_manager)
    }
  }
}

cat("Global configuration complete\n\n")
