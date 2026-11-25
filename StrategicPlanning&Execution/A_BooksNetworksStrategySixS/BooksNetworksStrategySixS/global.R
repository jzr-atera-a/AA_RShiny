# ── Debug console capture ───────────────────────────────────────────────
# Mirrors every cat()/print() this app writes into an in-memory buffer,
# read by the Debug Console tab (API Configuration group). This must run
# BEFORE anything else in this file, so every module's own startup
# cat() calls (module discovery, package loading, etc.) get captured
# too, not just output from requests made after the app finishes
# loading. Deliberately captures stdout only (cat()/print()), not R's
# message()/warning()/error stream - sinking that stream risks silently
# hiding real errors from the actual console, so it's left alone; check
# the real console for those.
.debug_log_max_lines <- 5000

# The buffer and its connection are named for THIS app and the connection is remembered in an R option
# (options survive the rm(list = ls()) in app.R). Every start of the app closes the previous capture of this
# app and opens a fresh, empty one, so the Debug Console only ever shows the current run: nothing left over
# from an earlier run, and nothing from any other app that was open in the same R session.
.sixs_log_var <- "sixs_debug_log_buffer"
.sixs_log_close <- function() {
  con <- getOption("sixs.debug_conn")
  if (!is.null(con)) {
    if (isTRUE(tryCatch(isOpen(con), error = function(e) FALSE))) {
      if (sink.number() > 0) try(sink(type = "output"), silent = TRUE)
      try(close(con), silent = TRUE)
    }
    options(sixs.debug_conn = NULL)
  }
}
.sixs_log_open <- function() {
  assign(.sixs_log_var, character(0), envir = .GlobalEnv)
  con <- textConnection(.sixs_log_var, open = "w", local = FALSE)
  options(sixs.debug_conn = con)
  sink(con, type = "output", split = TRUE)
  invisible(con)
}
.sixs_log_close(); .sixs_log_open()
cat("✓ [Debug Console] Log capture started for this run of the app\n")

get_debug_log_lines <- function() {
  raw <- tryCatch(get(.sixs_log_var, envir = .GlobalEnv), error = function(e) character(0))
  if (length(raw) > .debug_log_max_lines) raw <- tail(raw, .debug_log_max_lines)
  raw
}

clear_debug_log <- function() {
  .sixs_log_close(); .sixs_log_open()
  invisible(TRUE)
}

# global.R - packages, shared code and page assembly for BooksNetworksStrategySixS
# =============================================================
# One app, one shared BigQuery connection and one shared Claude API connection (sidebar: "API Configuration"), with one
# sidebar group per suite. See R/utils_api.R for the shared APIManager and R/module_loader.R for how sub-tabs are found
# (one file per sub-tab: modules/<Tab group>/<id>.R).

cat("\n╔══════════════════════════════════════════════╗\n")
cat("║  BooksNetworksStrategySixS - starting         ║\n")
cat("╚══════════════════════════════════════════════╝\n\n")

# ============================================================
# DEPLOYMENT DEPENDENCY DECLARATIONS - DO NOT REMOVE
# ============================================================
# rsconnect's dependency scanner only sees literal library()/pkg::fn() calls, not the packages named in the sub-tab
# headers, so every package any sub-tab needs is declared here. D3, Cytoscape.js and the export libraries are loaded in
# the browser from a CDN (see create_ui() below).
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(shinyjs)
  library(R6)
  library(yaml)
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

# Shared code, in dependency order (R/_disable_autoload.R stops Shiny from also loading these files by itself).
source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_decision_tree.R")
source("R/utils_dt_workbench.R")
source("R/utils_question_wheel.R")
source("R/utils_api.R")
source("R/utils_local_creds.R")
source("R/utils_gdrive.R")
source("R/utils_bq_lazy.R")
source("R/utils_techdesign_catalog.R")
source("R/utils_techdesign_catalog_zalgo.R")
source("R/utils_techdesign_catalog_zsocial.R")
source("R/utils_techdesign_parse.R")
source("R/utils_techdesign_render.R")
source("R/utils_techdesign_module.R")
source("R/utils_techdesign_actions.R")
source("R/utils_td_hubs.R")
source("R/utils_suite_tabs.R")
source("R/utils_techdesign_social_module.R")
source("R/utils_techdesign_social_handbook.R")
source("R/utils_techdesign_algo_handbook.R")
source("R/utils_claude_stream.R")
source("R/utils_techdesign_matrix.R")
source("R/utils_techdesign_matrix_render.R")
# NOTE: the infographic files are numbered (x1..x5) because Shiny also auto-loads every file in R/ in alphabetical order,
# and each of these needs the one before it (icons, themes and block tables are defined in x1).
source("R/utils_x1_infographic_render.R")
source("R/utils_x2_infographic_blocks.R")
source("R/utils_x3_infographic_dash.R")
source("R/utils_x4_infographic_flow.R")
source("R/utils_x5_infographic.R")

api_manager <- APIManager$new()

# exported files saved to Google Drive arrive as an ordinary upload: allow large PDFs / PPTX / GIFs
options(shiny.maxRequestSize = 200 * 1024^2)

# Icon used when a group in the registry has no `icon:` of its own.
DEFAULT_GROUP_ICON <- "folder"

# "file.css" -> "file.css?v=<time the file was last changed>", so a browser never keeps an old copy after an update.
asset_url <- function(path) {
  v <- tryCatch(format(file.mtime(file.path("www", path)), "%Y%m%d%H%M%S"), error = function(e) NA)
  if (is.na(v)) path else paste0(path, "?v=", v)
}

create_ui <- function(module_loader) {
  mods <- module_loader$get_enabled_modules()
  ids <- names(mods)

  # ---- one page per sidebar entry (sub-tabs that live inside a hub are drawn by the hub: R/utils_td_hubs.R) ----
  all_tabs <- lapply(Filter(function(m) !(m$id %in% TD_HUB_CHILD_IDS), mods), function(m) {
    ui_fn <- module_loader$ui_function(m$id)
    if (is.null(ui_fn)) return(tabItem(tabName = m$id, fluidRow(box(title = paste("Module:", m$name), status = "warning", solidHeader = TRUE, width = 12,
      h4("This module is enabled but not yet implemented"), p("Module ID:", m$id), p("Expected UI function:", paste0(m$id, "_ui"))))))
    tabItem(tabName = m$id, ui_fn(m$id))
  })

  # ---- sidebar: one collapsible entry per group of the registry; a group that holds a single hub is a plain entry ----
  groups <- module_loader$registry$groups
  menu_items <- if (!is.null(groups)) {
    Filter(Negate(is.null), lapply(groups, function(g) {
      members <- intersect(unlist(g$modules), ids)
      g_icon <- icon(g$icon %||% DEFAULT_GROUP_ICON)
      if (length(members) == 0) return(NULL)
      if (length(members) == 1 && isTRUE(mods[[members]]$hub)) return(menuItem(g$label, tabName = members, icon = g_icon))
      do.call(menuItem, c(list(text = g$label, icon = g_icon, startExpanded = isTRUE(g$expanded)),
                          unname(lapply(mods[members], function(m) menuSubItem(m$label, tabName = m$id, icon = icon(m$icon))))))
    }))
  } else lapply(unname(mods), function(m) menuItem(m$label, tabName = m$id, icon = icon(m$icon)))   # no groups in the registry: flat menu

  cdn <- function(url) tags$script(src = url)

  dashboardPage(
    dashboardHeader(title = module_loader$registry$app$name %||% "BooksNetworksStrategySixS"),

    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, unname(menu_items))),
      tags$div(id = "sidebar_status_dock", app_api_status_ui(), app_bq_checks_ui())
    ),

    dashboardBody(
      shinyjs::useShinyjs(),

      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = asset_url("css/global.css")),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),

        cdn("https://cdnjs.cloudflare.com/ajax/libs/d3/7.8.5/d3.min.js"),                    # Mind Map tree, Knowledge Graph force layout
        cdn("https://cdnjs.cloudflare.com/ajax/libs/d3-sankey/0.12.3/d3-sankey.min.js"),     # Sankey layout (not part of core d3)
        cdn("https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.28.1/cytoscape.min.js"),     # Knowledge Graph, second view
        cdn("https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS-MML_HTMLorMML"),

        # Export of diagrams and tables: captures what is drawn in the browser (HTML grid, SVG or Plotly alike),
        # so the exported file matches the screen whichever technology drew it.
        cdn("https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"),
        cdn("https://cdnjs.cloudflare.com/ajax/libs/jspdf/4.2.1/jspdf.umd.min.js"),
        cdn("https://cdn.jsdelivr.net/gh/gitbrent/pptxgenjs@3.12.0/dist/pptxgen.bundle.js"),  # not on cdnjs: jsDelivr is its official CDN
        cdn(asset_url("js/app_boot.js")),
        cdn(asset_url("js/gdrive_export.js")),
        cdn(asset_url("js/diagram_export.js")),
        cdn(asset_url("js/question_wheel.js")),
        cdn(asset_url("js/infographic_export.js")),

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

      gd_page_ui(),   # hidden upload input used by "Save to Google Drive" (R/utils_gdrive.R)
      do.call(tabItems, unname(all_tabs))
    )
  )
}

# Module servers are built ON DEMAND: only the API tabs and the Debug Console at start-up; every other sub-tab's server is built the first
# time its tab is opened (or when its tab group is clicked, which builds the whole group). Building all of them at start cost several seconds.
APP_EAGER_MODULES <- c("bigquery_auth", "claude_api_config", "google_drive_config", "debug_console")

create_server <- function(module_loader, api_manager, session) {
  ids <- module_loader$enabled_ids()
  built <- new.env()
  groups <- list()   # group label -> module ids (registry order)
  for (g in (module_loader$registry$groups %||% list())) groups[[as.character(g$label)]] <- intersect(unlist(g$modules), ids)
  is_built <- function(id) exists(id, envir = built, inherits = FALSE)

  build <- function(id) {
    if (is.null(id) || !nzchar(id) || !(id %in% ids) || is_built(id)) return(invisible(FALSE))
    assign(id, TRUE, envir = built)
    fn <- module_loader$server_function(id)
    if (!is.null(fn)) {
      t0 <- Sys.time()
      tryCatch(fn(id, api_manager), error = function(e) cat("[Startup] module", id, "failed to start:", conditionMessage(e), "\n"))
      dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      if (dt > 0.5) cat(sprintf("[Startup] module %s built in %.1f s\n", id, dt))
    }
    for (kid in td_hub_child_ids(id)) build(kid)   # a hub builds its sub-tabs too
    invisible(TRUE)
  }

  t_all <- Sys.time()
  eager <- intersect(APP_EAGER_MODULES, ids)
  for (id in eager) build(id)
  cat(sprintf("[Startup] %d of %d module servers built at start-up (%.2f s); the rest are built when their tab group or tab is opened\n",
              length(eager), length(ids), as.numeric(difftime(Sys.time(), t_all, units = "secs"))))

  list(build = build,
       group_built = function(label) all(vapply(groups[[label]] %||% character(0), is_built, TRUE)),
       build_group = function(label) sum(vapply(groups[[label]] %||% character(0), function(id) isTRUE(build(id)), TRUE)),
       group_labels = names(groups))
}

cat("✓ Global configuration complete\n\n")
