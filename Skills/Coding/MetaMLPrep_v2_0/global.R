# global.R - Meta ML Interview Prep Suite
# v3.0 — Grouped sidebar: Python Runner · Whiteboard · 7 paired topic groups

cat("\n╔════════════════════════════════════════════════════╗\n")
cat("║  META ML INTERVIEW PREP SUITE v3.0 - LOADING      ║\n")
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
  library(httr)
})

source("R/module_loader.R")
source("R/utils_common.R")
source("R/utils_prep_manager.R")

prep_manager <- NULL  # initialised inside server

# ── Sidebar group definition ──────────────────────────────────────────────────
# Standalone tools appear first (Python Runner, then Whiteboard).
# Each group entry drives one collapsible menuItem with two menuSubItems:
#   intro   → "Prep Guide"  (the general prep module)
#   profile → "Your <X>"    (the profile-linked mirror module)

SIDEBAR_GROUPS <- list(
  list(
    label   = "Welcome & Overview",
    icon    = "home",
    intro   = list(label = "Prep Guide",        tabname = "intro"),
    profile = list(label = "Your Candidacy",    tabname = "intro_profile")
  ),
  list(
    label   = "Engineer Qualities",
    icon    = "star",
    intro   = list(label = "Prep Guide",        tabname = "qualities"),
    profile = list(label = "Your Qualities",    tabname = "qualities_profile")
  ),
  list(
    label   = "Coding Interview",
    icon    = "code",
    intro   = list(label = "Prep Guide",        tabname = "coding_interview"),
    profile = list(label = "Your Coding Angle", tabname = "coding_profile")
  ),
  list(
    label   = "ML Design Interview",
    icon    = "brain",
    intro   = list(label = "Prep Guide",        tabname = "ml_design"),
    profile = list(label = "Your ML Systems",   tabname = "ml_design_profile")
  ),
  list(
    label   = "Technical Project",
    icon    = "project-diagram",
    intro   = list(label = "Prep Guide",        tabname = "tech_project"),
    profile = list(label = "Your Projects",     tabname = "tech_project_profile")
  ),
  list(
    label   = "Cross-Functional",
    icon    = "handshake",
    intro   = list(label = "Prep Guide",        tabname = "cross_functional"),
    profile = list(label = "Your XFN Stories",  tabname = "cross_functional_profile")
  ),
  list(
    label   = "Career Interview",
    icon    = "user-tie",
    intro   = list(label = "Prep Guide",        tabname = "career_interview"),
    profile = list(label = "Your Career Story", tabname = "career_profile")
  )
)

# ── UI Factory ─────────────────────────────────────────────────────────────────
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  # Build all tab body items dynamically from loaded modules
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

  # ── Sidebar: standalone tools ─────────────────────────────────────────────
  standalone_items <- tagList(
    menuItem(
      "Python Runner",
      tabName = "python_runner",
      icon    = icon("terminal")
    ),
    menuItem(
      "Design Whiteboard",
      tabName = "ml_design_whiteboard",
      icon    = icon("chalkboard")
    ),
    # Section divider label
    tags$li(
      class = "header",
      style = paste0(
        "padding:10px 15px 4px;",
        "font-size:10px;font-weight:700;",
        "letter-spacing:0.12em;text-transform:uppercase;",
        "color:rgba(255,255,255,0.35);"
      ),
      "Interview Rounds"
    )
  )

  # ── Sidebar: grouped topic items ──────────────────────────────────────────
  group_items <- lapply(SIDEBAR_GROUPS, function(grp) {
    menuItem(
      grp$label,
      icon          = icon(grp$icon),
      startExpanded = FALSE,
      menuSubItem(
        grp$intro$label,
        tabName = grp$intro$tabname,
        icon    = icon("book-open")
      ),
      menuSubItem(
        grp$profile$label,
        tabName = grp$profile$tabname,
        icon    = icon("user-circle")
      )
    )
  })

  # ── Assemble dashboard ────────────────────────────────────────────────────
  dashboardPage(
    skin = "blue",
    dashboardHeader(title = "Meta ML Prep"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        standalone_items,
        do.call(tagList, group_items)
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$script(src = "js/app_helpers.js"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# ── Server Factory ─────────────────────────────────────────────────────────────
# CRITICAL: do NOT pass session to module servers
create_server <- function(module_loader, prep_mgr) {
  enabled_modules <- module_loader$get_enabled_modules()

  for (module in enabled_modules) {
    module_id            <- module$module$id
    server_function_name <- paste0(module_id, "_server")

    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_fn <- get(server_function_name, envir = .GlobalEnv)
      server_fn(module_id, prep_mgr)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
