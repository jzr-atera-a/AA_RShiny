# global.R
# ── Debug console capture ───────────────────────────────────────────────
# Mirrors stdout (every cat()/print() call) into an in-memory buffer, while
# still printing to the real console (split = TRUE). Backs the Debug
# Console tab (API Settings group) so long log output can be
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
# Reentrancy: re-running the app in the same R session reuses the existing
# capture (the guard below) instead of stacking a second sink on top of it.
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

# Loads packages, sources shared R/ code, discovers modules via the registry,
# and builds the grouped-sidebar UI + server.

# Audio Transcription and Visual Media (PDF Manager tools) need large uploads
# (raw MP4/audio files, big PDFs); Visual Media's source app removed the cap
# entirely, which is a superset of Audio Transcription's 500MB - so this app
# now has no upload size limit at all (Shiny's default is 5MB).
options(shiny.maxRequestSize = -1)

library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinyWidgets)
library(httr)
library(curl)
library(jsonlite)
library(DT)
library(plotly)
library(pdftools)
library(readtext)
library(uuid)
library(bigrquery)
library(DBI)
library(glue)
library(base64enc)
library(R6)
library(yaml)
library(openxlsx)
library(stringr)
library(readxl)
library(writexl)
library(blastula)
library(openssl)
library(dplyr)
library(av)
library(fs)
library(shinyFiles)
library(magick)
library(qpdf)

# Async processing (Video Audio Extractor uses this to avoid blocking the
# UI/other tabs during long MP4 -> MP3 extraction jobs).
if (requireNamespace("future", quietly = TRUE) && requireNamespace("promises", quietly = TRUE)) {
  library(future)
  library(promises)
  future::plan(future::multisession, workers = 2)
} else {
  message("Package not installed: future and/or promises - Video Audio Extractor will run synchronously and may block the UI during extraction")
}

source("R/live_log.R")      # live progress logs + step-by-step job runner (audio tabs)
source("R/api_manager.R")
source("R/utils_export.R")            # generic HTML/PDF export (Funding Programmes > Visualizations)
source("R/utils_calendar_export.R")   # .ics calendar export (Funding Programmes > Browse)
source("R/module_loader.R")

# Source utility modules that don't appear in the sidebar but are used by other modules
source("modules/API Settings/openai_base.R")

loader <- ModuleLoader$new(modules_dir = "modules", registry_file = "modules/_module_registry.yml")
loader$load_all()

app_css <- paste(readLines("www/css/global.css", warn = FALSE), collapse = "\n")

# -----------------------------------------------------------------------
# UI factory - builds a grouped sidebar (main tab = group, subtab = module)
# -----------------------------------------------------------------------

create_ui <- function() {
  groups <- loader$get_groups()

  menu_items <- lapply(groups, function(g) {
    subitems <- lapply(g$modules, function(mod_id) {
      meta <- loader$get_module_meta(mod_id)
      if (is.null(meta) || !isTRUE(meta$enabled)) return(NULL)
      menuSubItem(meta$label, tabName = mod_id, icon = icon(meta$icon))
    })
    subitems <- Filter(Negate(is.null), subitems)
    do.call(menuItem, c(
      list(text = g$label, icon = icon(g$icon), startExpanded = isTRUE(g$expanded)),
      subitems
    ))
  })

  all_ids <- loader$get_all_module_ids()
  tab_item_list <- lapply(all_ids, function(mod_id) {
    ui_fn <- loader$get_ui_function(mod_id)
    tabItem(tabName = mod_id, ui_fn(mod_id))
  })

  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "Business Operations Suite"),
    dashboardSidebar(
      sidebarMenu(id = "sidebar_menu", do.call(tagList, menu_items))
    ),
    dashboardBody(
      useShinyjs(),
      tags$head(tags$style(HTML(app_css))),
      do.call(tabItems, tab_item_list)
    )
  )
}

# -----------------------------------------------------------------------
# Server factory - one shared APIManager instance per session, passed into
# every module's server function.
# -----------------------------------------------------------------------

create_server <- function() {
  function(input, output, session) {
    api_manager <- APIManager$new()

    all_ids <- loader$get_all_module_ids()
    for (mod_id in all_ids) {
      server_fn <- loader$get_server_function(mod_id)
      server_fn(mod_id, api_manager)
    }
  }
}
