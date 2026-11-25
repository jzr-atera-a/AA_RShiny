# core/nav.R - builds the sidebar (main groups) and the page tabs from
# modules/_module_registry.yml, loads each page's file, and starts its server.
# Same model as the reference suite: sidebar = main group, page = horizontal tabs.

nav_load <- function(path = file.path("modules", "_module_registry.yml")) {
  reg <- yaml::read_yaml(path)
  pages <- reg$pages %||% list()
  seen <- character(0)
  groups <- list()
  for (g in reg$groups) {
    mods <- unlist(g$modules)
    mods <- mods[vapply(mods, function(m) !identical(pages[[m]]$enabled, FALSE), logical(1))]
    if (!length(mods)) next
    dup <- intersect(mods, seen)
    if (length(dup)) stop("Registry: page(s) listed in more than one group: ", paste(dup, collapse = ", "), call. = FALSE)
    seen <- c(seen, mods)
    for (m in mods) {
      f <- file.path("modules", g$folder, paste0(m, ".R"))
      if (!file.exists(f)) stop("Registry: group '", g$label, "' lists page '", m, "' but ", f, " does not exist.", call. = FALSE)
    }
    g$modules <- mods
    groups[[length(groups) + 1]] <- g
  }
  for (m in setdiff(names(pages), seen)) cat("[NAV] Note: page '", m, "' is described but not in any group - not shown\n", sep = "")
  info <- do.call(rbind, lapply(groups, function(g) data.frame(
    id = g$modules, group_id = g$id, group = g$label, folder = g$folder,
    label = vapply(g$modules, function(m) pages[[m]]$label %||% m, character(1)),
    icon = vapply(g$modules, function(m) pages[[m]]$icon %||% "circle", character(1)),
    period = vapply(g$modules, function(m) !identical(pages[[m]]$period, FALSE), logical(1)),
    charts = isTRUE(g$charts), stringsAsFactors = FALSE)))
  rownames(info) <- info$id
  list(groups = groups, pages = info)
}

# Source every page file into `env` (the app environment).
nav_source <- function(nav, env) {
  for (i in seq_len(nrow(nav$pages))) {
    p <- nav$pages[i, ]
    sys.source(file.path("modules", p$folder, paste0(p$id, ".R")), envir = env, keep.source = FALSE)
    for (fn in paste0(p$id, c("_ui", "_server"))) {
      if (!exists(fn, envir = env, inherits = FALSE)) {
        stop("modules/", p$folder, "/", p$id, ".R must define ", fn, "().", call. = FALSE)
      }
    }
  }
  invisible(nav)
}

nav_sidebar <- function(nav) {
  items <- list()
  for (g in nav$groups) {
    if (!is.null(g$sidebar_header)) items[[length(items) + 1]] <- tags$li(class = "header", g$sidebar_header)
    items[[length(items) + 1]] <- shinydashboard::menuItem(g$label, tabName = g$id, icon = icon(g$icon))
  }
  do.call(shinydashboard::sidebarMenu, c(list(id = "tabs"), items))
}

nav_page_head <- function(g) {
  div(class = "page-head",
      div(class = "page-head-title", icon(g$icon), span(g$label)),
      if (!is.null(g$description)) div(class = "page-head-desc", g$description))
}

nav_body <- function(nav, env) {
  items <- lapply(nav$groups, function(g) {
    ui_of <- function(m) get(paste0(m, "_ui"), envir = env)(m)
    body <- if (length(g$modules) == 1) ui_of(g$modules) else {
      panels <- lapply(g$modules, function(m) {
        p <- nav$pages[m, ]
        tabPanel(title = tagList(icon(p$icon), p$label), value = m, ui_of(m))
      })
      div(class = "section-tabs", do.call(tabsetPanel, c(list(id = paste0("tabs_", g$id), type = "tabs"), panels)))
    }
    item <- shinydashboard::tabItem(tabName = g$id, nav_page_head(g), body)
    # one-page groups: tell the chart-saving script which page this is
    if (length(g$modules) == 1) item <- tagAppendAttributes(item, `data-page` = g$modules)
    item
  })
  do.call(shinydashboard::tabItems, items)
}

# JavaScript condition: TRUE when the page on screen uses the Period / Compare bar.
nav_period_condition <- function(nav) {
  off <- character(0)
  for (g in nav$groups) {
    no <- g$modules[!nav$pages[g$modules, "period"]]
    if (!length(no)) next
    if (length(g$modules) == 1 || length(no) == length(g$modules)) {
      off <- c(off, sprintf("input.tabs == '%s'", g$id))
    } else {
      off <- c(off, sprintf("(input.tabs == '%s' && [%s].indexOf(input['tabs_%s']) >= 0)", g$id,
                            paste0("'", no, "'", collapse = ", "), g$id))
    }
  }
  if (!length(off)) return("true")
  sprintf("!(%s)", paste(off, collapse = " || "))
}

# Start every page's server, giving it only the arguments it asks for.
nav_start_servers <- function(nav, env, deps) {
  for (m in nav$pages$id) {
    fn <- get(paste0(m, "_server"), envir = env)
    args <- list(m)
    for (a in setdiff(names(formals(fn)), "id")) {
      if (!a %in% names(deps)) stop(m, "_server() asks for '", a, "', which the app does not provide.", call. = FALSE)
      args[[a]] <- deps[[a]]
    }
    do.call(fn, args)
  }
}

# Jump to a page (sidebar group + its tab) from server code.
nav_goto <- function(session, nav, page) {
  if (!page %in% nav$pages$id) return(invisible(FALSE))
  g <- nav$pages[page, "group_id"]
  shinydashboard::updateTabItems(session, "tabs", selected = g)
  if (sum(nav$pages$group_id == g) > 1) updateTabsetPanel(session, paste0("tabs_", g), selected = page)
  invisible(TRUE)
}
