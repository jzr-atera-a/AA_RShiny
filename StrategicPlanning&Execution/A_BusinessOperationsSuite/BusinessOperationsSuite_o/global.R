# global.R
# Loads packages, sources shared R/ code, discovers modules via the registry,
# and builds the grouped-sidebar UI + server.

# Audio Transcription suite needs large uploads (raw MP4/audio files); this
# raises the app-wide limit (Shiny's default is 5MB).
options(shiny.maxRequestSize = 500 * 1024^2)

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

# Async processing (Video Audio Extractor uses this to avoid blocking the
# UI/other tabs during long MP4 -> MP3 extraction jobs).
if (requireNamespace("future", quietly = TRUE) && requireNamespace("promises", quietly = TRUE)) {
  library(future)
  library(promises)
  future::plan(future::multisession, workers = 2)
} else {
  message("Package not installed: future and/or promises - Video Audio Extractor will run synchronously and may block the UI during extraction")
}

source("R/api_manager.R")
source("R/module_loader.R")

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
