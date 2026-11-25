# ---- module ----------------------------------------------
# id:           admin_tabs
# name:         Tabs and groups
# icon:         table-columns
# description:  The owner chooses which tabs and groups are shown, what they are called, and who sees them
# packages:     shiny
# -----------------------------------------------------------
# Saved as JSON in the settings key tab_config; read by R/nav.R. The page reloads after saving so the
# app is redrawn in place. Other people see the change the next time they sign in or reload.

admin_tabs_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Only the owner sees this tab. Untick ", tags$b("Shown"), " to hide a tab from everyone; untick ",
         tags$b("Members"), " or ", tags$b("Partners"), " to hide it from them only. Leave a label empty to keep the standard name. ",
         "Tabs marked owner-only are always hidden from others."),
    uiOutput(ns("grid")),
    div(class = "btn-row",
        actionButton(ns("save"), "Save and apply", class = "btn-brand", icon = icon("floppy-disk")),
        actionButton(ns("reset"), "Back to the standard setup", class = "btn-ghost", icon = icon("rotate-left"))))
}

admin_tabs_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    key <- function(...) gsub("[^A-Za-z0-9_]", "_", paste(..., sep = "__"))
    output$grid <- renderUI({
      req(ctx$is_owner()); tc <- tab_config(ctx$settings()); reg <- loader$registry
      tagList(lapply(reg$groups, function(g) {
        gc <- tc$groups[[g$id]] %||% list(); ids <- loader$group_modules(g)
        card(NULL,
          layout_columns(col_widths = c(5, 4, 3),
            h5(icon(g$icon %||% "circle"), " ", g$label),
            textInput(ns(key("gl", g$id)), NULL, gc$label %||% "", placeholder = "Group label (optional)"),
            if (!isTRUE(g$admin)) checkboxInput(ns(key("ge", g$id)), "Group shown", !identical(gc$enabled, FALSE)) else span(class = "small muted", "Owner only")),
          tags$table(class = "qs-table",
            tags$thead(tags$tr(tags$th("Tab"), tags$th("Label"), tags$th("Shown"), tags$th("Members"), tags$th("Partners"))),
            tags$tbody(lapply(ids, function(m) {
              mc <- tc$modules[[m]] %||% list(); rm <- reg$modules[[m]] %||% list()
              owner_only <- isTRUE(rm$owner) || isTRUE(g$admin)
              tags$tr(
                tags$td(icon(module_icon(loader, m)), " ", loader$modules[[m]]$name %||% m, if (owner_only) span(class = "pill pill-off", "owner only")),
                tags$td(textInput(ns(key("ml", m)), NULL, mc$label %||% "", width = "100%")),
                tags$td(if (m == "admin_tabs") span(class = "small muted", "always") else checkboxInput(ns(key("me", m)), NULL, !identical(mc$enabled, FALSE))),
                tags$td(if (owner_only) "" else checkboxInput(ns(key("mm", m)), NULL, !identical(mc$members, FALSE))),
                tags$td(if (owner_only || identical(rm$partner, FALSE)) span(class = "small muted", "no") else checkboxInput(ns(key("mp", m)), NULL, !identical(mc$partners, FALSE))))
            }))))
      }))
    })
    observeEvent(input$save, {
      req(ctx$is_owner()); reg <- loader$registry; out <- list(groups = list(), modules = list())
      for (g in reg$groups) {
        gl <- trimws(input[[key("gl", g$id)]] %||% ""); ge <- input[[key("ge", g$id)]]
        e <- list(); if (nzchar(gl)) e$label <- gl; if (identical(ge, FALSE)) e$enabled <- FALSE
        if (length(e)) out$groups[[g$id]] <- e
        for (m in loader$group_modules(g)) {
          e <- list(); ml <- trimws(input[[key("ml", m)]] %||% "")
          if (nzchar(ml)) e$label <- ml
          if (identical(input[[key("me", m)]], FALSE)) e$enabled <- FALSE
          if (identical(input[[key("mm", m)]], FALSE)) e$members <- FALSE
          if (identical(input[[key("mp", m)]], FALSE)) e$partners <- FALSE
          if (length(e)) out$modules[[m]] <- e
        }
      }
      txt <- if (!length(out$groups) && !length(out$modules)) "" else as.character(jsonlite::toJSON(out, auto_unbox = TRUE))
      set_setting("tab_config", txt, ctx$user()); ctx$bump()
      store_clear_cache("settings"); ctx$rebuild_shell("admin", "admin_tabs")
      showNotification("Saved. The menu has been updated; others see it the next time they sign in.", type = "message")
    })
    observeEvent(input$reset, {
      req(ctx$is_owner()); set_setting("tab_config", "", ctx$user()); ctx$bump(); store_clear_cache("settings")
      ctx$rebuild_shell("admin", "admin_tabs"); showNotification("Back to the standard setup.", type = "message")
    })
  })
}
