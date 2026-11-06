# ── Debug console capture ───────────────────────────────────────────────
# Mirrors stdout (every cat()/print() call) into an in-memory buffer, while
# still printing to the real console (split = TRUE). Backs the Debug
# Console tab (API Configuration group) so long log output can be
# copied from a mobile browser. Must run before any other code in this
# file so it captures startup logging too (module discovery, package
# loading messages, etc).
#
# IMPORTANT: textConnection()'s `local` argument must be TRUE/FALSE, never
# an environment - some R installations' implementation does
# `if (local) parent.frame() else .GlobalEnv` internally, which throws on
# an environment value. Using local = FALSE and .GlobalEnv explicitly
# avoids this across R versions.
#
# Reentrancy: app.R runs rm(list = ls(all.names = TRUE)) on every restart,
# but deliberately preserves .debug_log_conn / debug_log_buffer /
# .debug_log_max_lines from that wipe (see app.R) - rm()-ing the R-level
# binding would not close the underlying connection or un-sink() it, so
# without that exclusion this guard would stack a new sink on the still-open
# old one every time runApp() re-runs in the same R session. Verified with
# a 3-run simulation before wiring this in: sink.number() stayed at 1 across
# all three, with no duplicated or lost output.
.debug_log_max_lines <- 5000

if (!exists(".debug_log_conn", envir = .GlobalEnv) ||
    !isTRUE(tryCatch(isOpen(get(".debug_log_conn", envir = .GlobalEnv)), error = function(e) FALSE))) {

  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  .debug_log_conn <- textConnection("debug_log_buffer", open = "w", local = FALSE)
  sink(.debug_log_conn, type = "output", split = TRUE)
  assign(".debug_log_conn", .debug_log_conn, envir = .GlobalEnv)
  cat("\u2713 [Debug Console] Log capture initialized\n")
} else {
  cat("\u2713 [Debug Console] Reusing existing log capture (already active this R session)\n")
}

get_debug_log_lines <- function() {
  raw <- tryCatch(get("debug_log_buffer", envir = .GlobalEnv), error = function(e) character(0))
  if (length(raw) > .debug_log_max_lines) raw <- tail(raw, .debug_log_max_lines)
  raw
}

clear_debug_log <- function() {
  # The bound variable can't be reset in place without closing and
  # reopening the connection, so swap in a fresh one.
  sink(type = "output")
  close(get(".debug_log_conn", envir = .GlobalEnv))
  assign("debug_log_buffer", character(0), envir = .GlobalEnv)
  new_conn <- textConnection("debug_log_buffer", open = "w", local = FALSE)
  sink(new_conn, type = "output", split = TRUE)
  assign(".debug_log_conn", new_conn, envir = .GlobalEnv)
  invisible(TRUE)
}

# Note on scope: only type = "output" (stdout) is captured - i.e.
# cat()/print(). R's message()/warning()/errors go through a separate
# stream (type = "message") whose sink does not reliably support
# split = TRUE across R versions; sinking it risks silently hiding real
# errors from the normal console, so it's deliberately left alone.


# global.R - Global Configuration
# BUSINESS OPERATIONS SUITE: Travel Planning + Day Planner + Diet + Exercise +
# Events Scheduling + Funding Programmes + Gantt to Tickets + Contact Manager
# =================================================================================
# One app, one shared BigQuery connection and one shared Claude API connection
# (grouped under "API Configuration" in the sidebar), with each suite's tabs
# grouped under their own named section. See R/utils_api.R for how one
# shared APIManager class serves every suite's BigQuery table(s), and
# R/module_loader.R for the recursive module-discovery that lets modules
# live inside these grouped subfolders
# (modules/"Day Planner"/generate_schedule/manifest.yml etc) instead of a
# flat modules/<id>/ layout.
#
# NOTE: this is a SEPARATE unified app from the Book Summary / Flex Table /
# Mind Map / Knowledge Graph unified suite - same architectural pattern,
# different deployment, intentionally not merged together.

cat("\n╔══════════════════════════════════════════════╗\n")
cat("║  BUSINESS OPERATIONS SUITE - INIT             ║\n")
cat("║  Travel + Day Planner + Diet + Exercise +     ║\n")
cat("║  Events + Funding + Gantt + Contacts          ║\n")
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
# library()/pkg::fn() calls, not packages named inside YAML manifests, so
# every package any module needs (across all three suites) is declared here
# explicitly. `curl` is required for the streaming Claude API implementation
# (curl::curl_fetch_stream) shared by every suite's Generate/Scan tab.
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
  library(httr2)    # Titan calendar (CalDAV) - Events Scheduling
  library(xml2)
  library(uuid)
})

source("R/module_loader.R")
source("R/utils_timezone.R")
source("R/utils_common.R")
source("R/utils_api.R")
source("R/utils_export.R")
source("R/utils_ics.R")
source("R/utils_titan.R")
source("R/utils_slack.R")
source("R/utils_zoom.R")
source("R/utils_muscle_body.R")
source("R/utils_muscle.R")
source("R/utils_local_creds.R")
source("R/utils_nav.R")
source("R/utils_tables.R")

api_manager <- APIManager$new()

DEFAULT_GROUP_ICON <- "folder"

create_ui <- function(module_loader) {

  enabled_modules <- module_loader$get_enabled_modules()
  registry <- module_loader$registry

  # ---- Navigation: sidebar = tab group > topic section; the modules of a section are horizontal tabs in the page ----
  # (see R/utils_nav.R and the `sections:` lists in modules/_module_registry.yml)
  layout <- nav_register(nav_layout(registry, enabled_modules))
  all_tabs <- nav_tab_items(layout, enabled_modules)
  menu_items <- nav_sidebar_items(layout)

  dashboardPage(
    dashboardHeader(title = module_loader$registry$app$name %||% "Business Operations Suite"),

    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, menu_items)),
      # docked at the bottom of the sidebar so the connection lights and the table checks stay visible while the menu scrolls
      tags$style(HTML("
        #sidebar_status_dock { position: fixed; bottom: 0; left: 0; width: 230px; z-index: 1040; padding-top: 4px;
                               background: linear-gradient(rgba(0,95,100,.94), rgb(0,110,108)); box-shadow: 0 -4px 10px rgba(0,0,0,.25); }
        .main-sidebar .sidebar-menu { padding-bottom: 250px; }
        @media (min-width: 768px) { .sidebar-collapse #sidebar_status_dock { display: none; } }
        @media (max-width: 767px) { body:not(.sidebar-open) #sidebar_status_dock { display: none; } }")),
      tags$div(id = "sidebar_status_dock", keys_status_box("keys_status"), tables_status_box(unname(layout$tabname_of[names(layout$tabname_of) %in% names(TABLE_MODULE_KEYS)])))
    ),

    dashboardBody(
      shinyjs::useShinyjs(),

      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),

      do.call(tabItems, all_tabs)
    )
  )
}

create_server <- function(module_loader, api_manager, session) {
  enabled_modules <- module_loader$get_enabled_modules()

  # Per-session record of the tabs the user has opened. Each module's data loaders wait behind api_manager$tab_gate("<tab>"),
  # so a page reload (or a second browser tab) loads nothing until its own tabs are opened.
  session$userData$tabs_opened <- shiny::reactiveVal(character())
  session$userData$keys_opened <- shiny::reactiveVal(character())   # table keys used by the opened tabs (for the shared taxonomy loaders)

  # sidebar: connection lights + on-demand table checks (one tab group at a time, when it is opened)
  keys_status_wire("keys_status", api_manager)
  layout <- nav_register(nav_layout(module_loader$registry, enabled_modules))
  tables_wire(api_manager, session, layout)

  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")

    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager)
    }
  }

  # LAST, and after the page has been sent: connect Claude + BigQuery from the local key folder / environment
  # (skipped when already connected; otherwise the user configures them by hand in API Configuration).
  # Connecting only authenticates; tables are checked later, per tab group, when it is opened.
  session$onFlushed(function() {
    shiny::withReactiveDomain(session, shiny::isolate(
      tryCatch(cred_startup(api_manager), error = function(e) cat("[Keys] start-up check failed:", conditionMessage(e), "\n"))))
  }, once = TRUE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
