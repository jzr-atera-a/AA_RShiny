# R/utils_nav.R
# SECTION NAVIGATION: sidebar = tab group > topic section; the modules of a section are horizontal tabs in the page.
# (Pattern taken from the DaysPlanningFundingTravel reference app.)
#
# Registry (modules/_module_registry.yml). Each group keeps its flat `modules:` list and may add `sections:`:
#   - id: funding_programmes
#     modules: [generate_programme, funding_bulk_import, ...]          # membership
#     sections:
#       - id: sec_fund_find                  # becomes the sidebar tabName (must start with sec_)
#         label: "Find & Add"
#         icon: "hand-holding-usd"
#         modules: [generate_programme, funding_bulk_import]          # shown as horizontal tabs, in this order
#         tab_labels: {generate_programme: "Find Programmes"}         # optional shorter tab titles
# Rules (so nothing is ever lost):
#   * a section with ONE module is shown without tabs and keeps that module's own id as its tab name;
#   * a group with ONE section becomes a plain top-level sidebar item (no expand arrow);
#   * an enabled module of a group that no section lists gets its own sidebar item;
#   * a group without `sections:` behaves as before (every module is its own sidebar item).
# Module ids never change, so nav_goto(session, "<module id>") finds the right section + inner tab.

.nav_env <- new.env(parent = emptyenv())
.nav_env$map <- list()

nav_layout <- function(registry, enabled_ids) {
  meta <- registry$modules
  groups <- list(); map <- list()
  for (g in registry$groups) {
    gm <- intersect(unlist(g$modules), enabled_ids)
    if (!length(gm)) next
    secs <- list(); placed <- character()
    for (s in g$sections) {
      mods <- intersect(unlist(s$modules), gm); if (!length(mods)) next
      secs[[length(secs) + 1]] <- list(id = s$id, label = s$label, icon = s$icon %||% g$icon, modules = mods,
                                       tab_labels = s$tab_labels %||% list())
      placed <- c(placed, mods)
    }
    for (mid in setdiff(gm, placed))        # modules no section lists (or a group with no sections): own sidebar item
      secs[[length(secs) + 1]] <- list(id = mid, label = meta[[mid]]$label, icon = meta[[mid]]$icon,
                                       modules = mid, tab_labels = list())
    secs <- lapply(secs, function(s) { if (length(s$modules) == 1) s$id <- s$modules; s })
    for (s in secs) for (mid in s$modules)
      map[[mid]] <- list(section = s$id, inner = if (length(s$modules) > 1) mid else NULL)
    groups[[length(groups) + 1]] <- list(id = g$id, label = g$label, icon = g$icon %||% "folder",
                                         expanded = isTRUE(g$expanded), sections = secs)
  }
  list(groups = groups, map = map)
}

nav_register <- function(layout) { .nav_env$map <- layout$map; invisible(layout) }

# Sidebar: one entry per group (single-section groups are plain items), one sub-item per section.
nav_sidebar_items <- function(layout) {
  lapply(layout$groups, function(g) {
    if (length(g$sections) == 1) {
      s <- g$sections[[1]]
      return(shinydashboard::menuItem(g$label, tabName = s$id, icon = shiny::icon(g$icon)))
    }
    subs <- lapply(g$sections, function(s) shinydashboard::menuSubItem(s$label, tabName = s$id, icon = shiny::icon(s$icon)))
    do.call(shinydashboard::menuItem, c(list(text = g$label, icon = shiny::icon(g$icon),
                                             startExpanded = g$expanded, expandedName = g$id), subs))
  })
}

# Page bodies: a plain tabItem for one-module sections, a tabItem with horizontal tabs otherwise.
nav_tab_items <- function(layout, registry, ui_fn_of) {
  meta <- registry$modules
  out <- list()
  for (g in layout$groups) for (s in g$sections) {
    if (length(s$modules) == 1) {
      mid <- s$modules
      out[[length(out) + 1]] <- shinydashboard::tabItem(tabName = s$id, ui_fn_of(mid)(mid))
      next
    }
    panels <- lapply(s$modules, function(mid) {
      ttl <- s$tab_labels[[mid]] %||% meta[[mid]]$label
      shiny::tabPanel(title = shiny::tagList(shiny::icon(meta[[mid]]$icon %||% "circle"), ttl),
                      value = mid, ui_fn_of(mid)(mid))
    })
    out[[length(out) + 1]] <- shinydashboard::tabItem(tabName = s$id,
      shiny::div(class = "section-tabs",
                 do.call(shiny::tabsetPanel, c(list(id = paste0("tabs_", s$id), type = "tabs"), panels))))
  }
  out
}

# Go to a module's tab from server code (replaces updateTabItems(..., "sidebar_menu", selected = <module id>)).
nav_goto <- function(session, tab) {
  root <- tryCatch(session$rootScope(), error = function(e) session)
  m <- .nav_env$map[[tab]]
  sec <- if (is.null(m)) tab else m$section
  shinydashboard::updateTabItems(root, "sidebar_menu", selected = sec)
  if (!is.null(m$inner)) shiny::updateTabsetPanel(root, paste0("tabs_", sec), selected = m$inner)
  invisible(TRUE)
}
