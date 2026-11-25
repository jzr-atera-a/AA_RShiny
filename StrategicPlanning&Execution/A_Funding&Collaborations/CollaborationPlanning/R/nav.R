# R/nav.R - builds the sidebar and the group pages from the registry and the owner's tab setup
#
# Sidebar: each group is a heading that opens to show its tabs (tab groups). The burger button in the top bar
# hides or shows the whole sidebar. Inside a group page the same tabs show as horizontal pills.
#
# Who sees what (in this order):
#   registry `enabled: false`               nobody (the module is not loaded)
#   tab setup `enabled = FALSE`             nobody (Admin > Tabs and groups, owner only)
#   registry `owner: true`                  only the owner (emails in ADMIN_EMAILS)
#   registry `partner: false` or setup      partners do not see it
#   tab setup `members = FALSE`             members and non-owner admins do not see it
#   Admin group                             only the owner

group_band <- function(g, label = g$label) {
  div(class = "group-band",
      span(class = "gb-ico", icon(g$icon %||% "circle")),
      div(div(class = "gb-t", label), div(class = "gb-b", g$blurb %||% "")))
}

# ---- tab setup (settings key tab_config, JSON) -----------------------------------------------
tab_config <- function(s = get_settings()) {
  txt <- s$tab_config %||% ""
  if (!nzchar(txt)) return(list(modules = list(), groups = list()))
  cfgl <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) list())
  list(modules = cfgl$modules %||% list(), groups = cfgl$groups %||% list())
}

module_label <- function(loader, id, tc = NULL) {
  l <- tc$modules[[id]]$label %||% ""
  if (nzchar(l)) l else loader$modules[[id]]$name %||% id
}
module_icon  <- function(loader, id) loader$modules[[id]]$icon %||% "circle"
group_label <- function(g, tc = NULL) { l <- tc$groups[[g$id]]$label %||% ""; if (nzchar(l)) l else g$label }

module_visible <- function(id, loader, role = "member", is_owner = FALSE, tc = NULL) {
  reg <- loader$registry$modules[[id]] %||% list(); m <- tc$modules[[id]] %||% list()
  if (identical(m$enabled, FALSE) && id != "admin_tabs") return(FALSE)
  if (isTRUE(reg$owner) && !is_owner) return(FALSE)
  if (is_owner) return(TRUE)
  if (identical(role, "partner")) return(!identical(reg$partner, FALSE) && !identical(m$partners, FALSE))
  !identical(m$members, FALSE)
}

visible_modules <- function(g, loader, role = "member", is_owner = FALSE, tc = NULL) {
  ids <- loader$group_modules(g)
  ids[vapply(ids, module_visible, TRUE, loader = loader, role = role, is_owner = is_owner, tc = tc)]
}

group_hidden <- function(g, loader, is_owner, role, tc = NULL) {
  if (isTRUE(g$admin)) return(!is_owner)
  if (identical(tc$groups[[g$id]]$enabled, FALSE)) return(TRUE)
  length(g$modules) > 0 && !length(visible_modules(g, loader, role, is_owner, tc))
}

group_tabs <- function(g, loader, role = "member", is_owner = FALSE, tc = NULL) {
  ids <- visible_modules(g, loader, role, is_owner, tc)
  if (!length(ids)) return(NULL)
  panels <- lapply(ids, function(id) {
    ui_fn <- get(paste0(id, "_ui"), envir = .GlobalEnv)
    nav_panel(title = tagList(icon(module_icon(loader, id)), span(module_label(loader, id, tc))), value = id,
              div(class = "tab-body", ui_fn(id)))
  })
  div(class = "tabs-wrap", do.call(navset_pill, c(list(id = paste0("sub_", g$id)), panels)))
}

group_page <- function(g, loader, role = "member", is_owner = FALSE, tc = NULL) {
  div(class = "grp",
      group_band(g, group_label(g, tc)),
      if (isTRUE(g$admin)) uiOutput("admin_area") else group_tabs(g, loader, role, is_owner, tc))
}

# Sidebar: group heading (opens the group and shows its tabs) + one link per tab
sidebar_links <- function(groups, loader, role = "member", is_owner = FALSE, tc = NULL) {
  tagList(lapply(groups, function(g) {
    if (group_hidden(g, loader, is_owner, role, tc)) return(NULL)
    ids <- if (isTRUE(g$admin)) loader$group_modules(g)[vapply(loader$group_modules(g), module_visible, TRUE, loader = loader,
                                                              role = role, is_owner = is_owner, tc = tc)]
           else visible_modules(g, loader, role, is_owner, tc)
    div(class = paste("side-group", if (isTRUE(g$admin)) "side-admin"), `data-group` = g$id,
        div(class = "side-head",
            actionLink(paste0("go_", g$id), class = "side-link", tagList(icon(g$icon %||% "circle"), span(group_label(g, tc)))),
            if (length(ids) > 1) tags$button(type = "button", class = "side-caret", `aria-label` = "Show or hide the tabs of this group",
                                             onclick = "cpToggleGroup(this)", icon("chevron-down"))),
        if (length(ids)) div(class = "side-subs", lapply(ids, function(id)
          tags$a(class = "side-sub", href = "#", `data-sub` = id,
                 onclick = sprintf("cpGo('%s','%s'); return false;", g$id, id),
                 icon(module_icon(loader, id)), span(module_label(loader, id, tc))))))
  }))
}

app_shell <- function(loader, is_owner, role = "member", tc = NULL) {
  groups <- loader$registry$groups
  pages <- lapply(groups, function(g) {
    if (group_hidden(g, loader, is_owner, role, tc)) return(NULL)
    nav_panel_hidden(value = g$id, group_page(g, loader, role, is_owner, tc))
  })
  pages <- Filter(Negate(is.null), pages)
  div(class = "shell",
      tags$aside(class = "side", id = "cp-side", sidebar_links(groups, loader, role, is_owner, tc),
                 if (identical(role, "partner")) div(class = "side-note", "Partner view: you see the bids you are part of."),
                 div(class = "side-foot", paste("Version", APP_VERSION))),
      tags$main(class = "main", do.call(navset_hidden, c(list(id = "grp"), pages))),
      tags$script(HTML("cpRestoreSide(); cpMarkActive('home', null);")))
}
