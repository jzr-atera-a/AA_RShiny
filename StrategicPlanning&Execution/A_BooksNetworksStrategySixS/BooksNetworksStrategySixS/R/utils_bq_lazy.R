# R/utils_bq_lazy.R
# ============================================================
# Lazy BigQuery loading. Starting the app (or pressing Connect) only signs in to BigQuery.
# The first time a tab of a suite is opened, that suite's table is checked (one metadata query,
# CREATE / ALTER only if something is missing) and its lists are loaded, with a small
# bottom-right message: "Loading ..." then "... ready (n items, x s)".
# ============================================================

# registry group id -> BigQuery group (see APIManager$bq_group_names())
APP_BQ_REGISTRY_MAP <- c(book_summary = "books", flex_table = "flex", mind_map = "mindmap", knowledge_graph = "kg",
                         sankey_graph = "sankey", strategic_analysis = "diagram", six_sigma_analysis = "sixsigma", technical_designs = "techdesign")
APP_BQ_LABELS <- c(books = "Book Summary", flex = "Flex Table", mindmap = "Mind Map", kg = "Knowledge Graph", sankey = "Sankey Graph",
                   diagram = "Strategic Analysis", sixsigma = "Six Sigma Analysis", techdesign = "Technical Designs")
APP_BQ_NOUNS <- c(books = "book rows", flex = "tables", mindmap = "map rows", kg = "graph rows", sankey = "Sankey graphs",
                  diagram = "diagrams", sixsigma = "diagrams", techdesign = "designs")
# tabs that read more than one suite
APP_BQ_EXTRA <- list(business_consulting = c("diagram", "sixsigma"))
# tabs that are static text: they never need BigQuery
APP_BQ_STATIC <- "(_about$|_guide$)"

# tab name -> the BigQuery groups it needs
app_bq_tab_groups <- function(module_loader) {
  out <- list()
  for (g in (module_loader$registry$groups %||% list())) {
    bq <- unname(APP_BQ_REGISTRY_MAP[as.character(g$id)]); if (length(bq) != 1 || is.na(bq)) next
    for (m in unlist(g$modules)) if (!grepl(APP_BQ_STATIC, m)) out[[m]] <- bq
  }
  for (nm in names(APP_BQ_EXTRA)) if (!is.null(out[[nm]])) out[[nm]] <- APP_BQ_EXTRA[[nm]]
  out
}

# toasts for the start-up connections (shown once the page is open)
app_cred_toasts <- function(api_manager) {
  st <- app_cred_status()
  if (isTRUE(api_manager$bq_connected))
    shiny::showNotification(sprintf("BigQuery connected (%s / %s). Each suite loads when you open its tab.", api_manager$bq_project_id, api_manager$bq_dataset_id), type = "message", duration = 8)
  else if (isTRUE(st$bq_failed))
    shiny::showNotification("BigQuery: a key was found but the connection failed. See the Debug Console.", type = "error", duration = 15)
  if (isTRUE(api_manager$claude_authenticated)) {
    if (isTRUE(api_manager$claude_tested)) shiny::showNotification("Claude API connected: key loaded and tested, it works.", type = "message", duration = 8)
    else shiny::showNotification(if (isFALSE(api_manager$claude_tested)) "Claude API: the key was refused. Check it in API Configuration > Claude API." else "Claude API: key loaded but the test call failed (network?). See API Configuration > Claude API.", type = "error", duration = 15)
  }
}

# tab group label (as shown in the sidebar) -> BigQuery groups
app_bq_group_label_map <- function(module_loader) {
  out <- list()
  for (g in (module_loader$registry$groups %||% list())) {
    bq <- unname(APP_BQ_REGISTRY_MAP[as.character(g$id)]); if (length(bq) == 1 && !is.na(bq)) out[[as.character(g$label)]] <- bq
  }
  out
}

# Sidebar section under the API status box: which suites are being checked / are ready.
app_bq_checks_ui <- function() tags$div(style = "padding:10px; background-color:#2c3e50; margin-top:6px; border-top:1px solid #34495e;",
  tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "TABLE CHECKS (ON DEMAND)"), uiOutput("bq_checks"))

app_bq_checks_render <- function(checks, api_manager) {
  st <- checks()
  line <- function(ico, col, txt) tags$div(style = sprintf("display:flex; gap:6px; margin:3px 0; font-size:11.5px; color:%s;", col), tags$span(ico), tags$span(txt))
  if (length(st) == 0) return(tags$div(style = "font-size:11.5px; color:#95a5a6;", "Tables load when you open a tab that needs them, once per session."))
  tagList(lapply(names(st), function(g) {
    x <- st[[g]]
    if (identical(x$status, "checking")) line(icon("spinner", class = "fa-spin"), "#fbbf24", sprintf("%s: %s", x$label, x$what %||% "checking tables ..."))
    else if (identical(x$status, "error")) line(icon("times-circle"), "#f87171", sprintf("%s: %s", x$label, x$msg))
    else line(icon("check-circle"), "#4ade80", x$msg)
  }))
}

# Opens the suites behind a clicked tab group or tab. The heavy work runs in a SECOND step: the first step only marks the
# suite as "checking" (sidebar updates at once), a short client-side delay lets the browser paint it, then bq_go_run does the check.
app_bq_lazy_observer <- function(input, session, module_loader, api_manager, checks, lazy) {
  map <- app_bq_tab_groups(module_loader); gmap <- app_bq_group_label_map(module_loader)
  set_state <- function(g, status, msg = "", label = APP_BQ_LABELS[[g]], what = "checking tables ...") { cur <- shiny::isolate(checks()); cur[[g]] <- list(status = status, msg = msg, label = label, what = what); checks(cur) }
  drop_state <- function(g) { cur <- shiny::isolate(checks()); cur[[g]] <- NULL; checks(cur) }

  request <- function(groups) {
    if (!isTRUE(shiny::isolate(api_manager$bq_connected))) return()
    cur <- shiny::isolate(checks())
    busy <- names(cur)[vapply(cur, function(x) identical(x$status, "checking"), TRUE)]
    need <- setdiff(groups, c(shiny::isolate(api_manager$bq_groups_loaded), busy))
    if (!length(need)) return()
    for (g in need) set_state(g, "checking")
    session$sendCustomMessage("bq_go", list(groups = as.list(need)))
  }

  # leaf tab -> BigQuery groups: a hub's sub-tab needs its suite's table unless it is static text (guide / about)
  leaf_map <- list(); hub_ids <- intersect(names(TD_HUBS), names(map))
  for (h in hub_ids) for (ch in vapply(TD_HUBS[[h]]$children, function(x) x$id, "")) if (!grepl(APP_BQ_STATIC, ch)) leaf_map[[ch]] <- map[[h]]
  for (nm in names(APP_BQ_EXTRA)) if (!is.null(leaf_map[[nm]])) leaf_map[[nm]] <- APP_BQ_EXTRA[[nm]]

  # Tables are loaded ONLY when a tab that needs them is shown (not when a tab group is clicked), and once per session:
  # api_manager$bq_groups_loaded remembers the suites that are done, so later visits never query again.
  shiny::observeEvent(c(list(input$sidebar_menu, api_manager$bq_conn_tick()), lapply(hub_ids, function(h) input[[paste0(h, "_tabs")]])), {
    tab <- input$sidebar_menu; if (is.null(tab)) return()
    lazy$build(tab)            # its server is built the first time the tab is opened (a group click has usually built it already)
    if (tab %in% hub_ids) {
      leaf <- input[[paste0(tab, "_tabs")]] %||% TD_HUBS[[tab]]$children[[1]]$id
      request(leaf_map[[leaf]])
    } else request(map[[tab]])
  }, ignoreNULL = FALSE)

  shiny::observeEvent(input$bq_group_click, {
    lab <- input$bq_group_click$label %||% ""
    # 1) the module servers of the clicked group are built first (about a second): the tabs become usable at once
    glab <- lazy$group_labels[vapply(lazy$group_labels, function(l) grepl(l, lab, fixed = TRUE), TRUE)]
    glab <- glab[!vapply(glab, function(l) isTRUE(lazy$group_built(l)), TRUE)]
    if (length(glab)) {
      for (l in glab) set_state(paste0("ui:", l), "checking", label = l, what = "preparing tabs ...")
      session$sendCustomMessage("bq_go", list(groups = list(), build = as.list(glab)))
    }
    # 2) then the suite's BigQuery tables are checked and its lists loaded
    # (no BigQuery request here any more: the tables load when a tab that needs them opens)
  })

  shiny::observeEvent(input$bq_go_run, {
    for (gl in unlist(input$bq_go_run$build)) { lazy$build_group(gl); drop_state(paste0("ui:", gl)) }
    for (g in unlist(input$bq_go_run$groups)) {
      lab <- APP_BQ_LABELS[[g]]; id <- paste0("bq_open_", g)
      if (g %in% api_manager$bq_groups_loaded) { set_state(g, "ready", sprintf("%s: ready", lab)); next }
      shiny::showNotification(sprintf("Checking %s tables in BigQuery ...", lab), id = id, duration = NULL, type = "message")
      res <- tryCatch(api_manager$bq_open_group(g), error = function(e) e)
      if (inherits(res, "error")) {
        cat("[BigQuery]", lab, "failed to load:", conditionMessage(res), "\n")
        msg <- substr(conditionMessage(res), 1, 150)
        set_state(g, "error", msg)
        shiny::showNotification(sprintf("%s could not be loaded from BigQuery: %s", lab, conditionMessage(res)), id = id, duration = NULL, type = "error")
      } else {
        txt <- sprintf("%s ready%s (%.1f s)", lab, if (is.na(res$rows)) "" else sprintf(": %d %s", res$rows, APP_BQ_NOUNS[[g]]), res$seconds)
        set_state(g, "ready", txt)
        shiny::showNotification(paste0(txt, "."), id = id, duration = 5, type = "message")
      }
    }
  })
}
