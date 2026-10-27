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
  if (isTRUE(api_manager$claude_authenticated))
    shiny::showNotification("Claude API key loaded (checked by the first request).", type = "message", duration = 6)
}

# opens the suites behind the selected tab (and re-opens them after a new connection)
app_bq_lazy_observer <- function(input, module_loader, api_manager) {
  map <- app_bq_tab_groups(module_loader)
  shiny::observeEvent(list(input$sidebar_menu, api_manager$bq_conn_tick()), {
    tab <- input$sidebar_menu
    if (is.null(tab) || !isTRUE(api_manager$bq_connected)) return()
    need <- setdiff(map[[tab]], api_manager$bq_groups_loaded)
    for (g in need) {
      id <- paste0("bq_open_", g); lab <- APP_BQ_LABELS[[g]]
      shiny::showNotification(sprintf("Loading %s from BigQuery ...", lab), id = id, duration = NULL, type = "message")
      res <- tryCatch(api_manager$bq_open_group(g), error = function(e) e)
      if (inherits(res, "error")) {
        cat("[BigQuery]", lab, "failed to load:", conditionMessage(res), "\n")
        shiny::showNotification(sprintf("%s could not be loaded from BigQuery: %s", lab, conditionMessage(res)), id = id, duration = NULL, type = "error")
      } else {
        shiny::showNotification(sprintf("%s ready%s (%.1f s).", lab, if (is.na(res$rows)) "" else sprintf(": %d %s", res$rows, APP_BQ_NOUNS[[g]]), res$seconds), id = id, duration = 5, type = "message")
      }
    }
  }, ignoreNULL = FALSE)
}
