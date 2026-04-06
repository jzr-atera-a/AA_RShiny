# global.R - Meta ML Interview Prep Suite v3.0

cat("\n=== META ML INTERVIEW PREP SUITE v3.0 - LOADING ===\n\n")

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

prep_manager <- NULL

# Sidebar group definition - drives collapsible groups
# Each group has items list; supports any number of sub-items per group
SIDEBAR_GROUPS <- list(
  list(
    label = "Welcome & Overview", icon = "home",
    items = list(
      list(label="Prep Guide",        tabname="intro",          icon="book-open"),
      list(label="Your Candidacy",    tabname="intro_profile",  icon="user-circle"),
      list(label="Process Feedback",  tabname="intro_feedback", icon="comments")
    )
  ),
  list(
    label = "Engineer Qualities", icon = "star",
    items = list(
      list(label="Prep Guide",     tabname="qualities",         icon="book-open"),
      list(label="Your Qualities", tabname="qualities_profile", icon="user-circle")
    )
  ),
  list(
    label = "Coding Interview", icon = "code",
    items = list(
      list(label="Prep Guide",       tabname="coding_interview", icon="book-open"),
      list(label="Your Coding Angle",tabname="coding_profile",   icon="user-circle"),
      list(label="Coding Feedback",  tabname="coding_feedback",  icon="comment-dots"),
      list(label="Maze Solver",       tabname="maze_solver_tab",  icon="code-branch")
    )
  ),
  list(
    label = "ML Design Interview", icon = "brain",
    items = list(
      list(label="Prep Guide",        tabname="ml_design",              icon="book-open"),
      list(label="Your ML Systems",   tabname="ml_design_profile",      icon="user-circle"),
      list(label="Sketch Whiteboard", tabname="ml_design_excalidraw",   icon="pencil-alt"),
      list(label="CoderPad Board",    tabname="ml_design_coderpad_wb",  icon="chalkboard-teacher"),
      list(label="Design Feedback I", tabname="ml_design_feedback_1",   icon="check-circle"),
      list(label="Design Feedback II",tabname="ml_design_feedback_2",   icon="exclamation-circle")
    )
  ),
  list(
    label = "Technical Project", icon = "project-diagram",
    items = list(
      list(label="Prep Guide",    tabname="tech_project",          icon="book-open"),
      list(label="Your Projects", tabname="tech_project_profile",  icon="user-circle"),
      list(label="Retro Feedback",tabname="tech_project_feedback", icon="search")
    )
  ),
  list(
    label = "Cross-Functional", icon = "handshake",
    items = list(
      list(label="Prep Guide",      tabname="cross_functional",          icon="book-open"),
      list(label="Your XFN Stories",tabname="cross_functional_profile",  icon="user-circle"),
      list(label="XFN Feedback",    tabname="cross_functional_feedback", icon="comment-dots")
    )
  ),
  list(
    label = "Career Interview", icon = "user-tie",
    items = list(
      list(label="Prep Guide",           tabname="career_interview",  icon="book-open"),
      list(label="Your Career Story",    tabname="career_profile",    icon="user-circle"),
      list(label="Behavioural Feedback", tabname="career_feedback",   icon="comment-dots")
    )
  )
)

# UI Factory
create_ui <- function(module_loader) {
  enabled_modules <- module_loader$get_enabled_modules()

  all_tabs <- list()
  for (module in enabled_modules) {
    module_id        <- module$module$id
    ui_function_name <- paste0(module_id, "_ui")
    tabname          <- module$module$tabname
    if (exists(ui_function_name, envir = .GlobalEnv)) {
      ui_fn <- get(ui_function_name, envir = .GlobalEnv)
      all_tabs[[length(all_tabs) + 1]] <- tabItem(tabName = tabname, ui_fn(module_id))
    }
  }

  # Standalone tools
  standalone_items <- tagList(
    menuItem("Python Runner",    tabName="python_runner",       icon=icon("terminal")),
    menuItem("Design Whiteboard",tabName="ml_design_whiteboard",icon=icon("chalkboard")),
    tags$li(class="header",
      style="padding:10px 15px 4px;font-size:10px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;color:rgba(255,255,255,0.35);",
      "Interview Rounds")
  )

  # Grouped topic items
  group_items <- lapply(SIDEBAR_GROUPS, function(grp) {
    sub_items <- lapply(grp$items, function(it) {
      menuSubItem(it$label, tabName=it$tabname, icon=icon(it$icon))
    })
    do.call(menuItem, c(
      list(grp$label, icon=icon(grp$icon), startExpanded=FALSE),
      sub_items
    ))
  })

  dashboardPage(
    skin = "blue",
    dashboardHeader(title="Meta ML Prep"),
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        standalone_items,
        do.call(tagList, group_items)
      )
    ),
    dashboardBody(
      tags$head(
        tags$link(rel="stylesheet", type="text/css", href="css/global.css"),
        tags$script(src="js/app_helpers.js"),
        tags$meta(charset="UTF-8"),
        tags$meta(name="viewport", content="width=device-width, initial-scale=1.0")
      ),
      do.call(tabItems, all_tabs)
    )
  )
}

# Server Factory - NEVER pass session to module servers
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

cat("Global configuration complete\n\n")
