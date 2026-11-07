# R/utils_tables.R
# PER-TAB, ON-DEMAND TABLE LOADING
# Start-up only connects (one quick round trip). Nothing else happens when you click a sidebar group or section.
# The first time a SPECIFIC TAB is shown (a section's first tab, or any horizontal tab you switch to), the app
#   1. verifies just the BigQuery tables that tab uses (one scoped metadata query, creating only what is missing),
#   2. then lets that tab's own data loaders run (they wait behind api_manager$tab_gate("<tab>")).
# Each table is verified once per connection and each tab loads once per browser session; coming back to a tab, or
# opening another tab that shares a table, costs nothing. A tab reloads only when its own refresh trigger fires
# (after an insert/update). Tabs that use no BigQuery table (settings, About, Zoom, Slack, Travel) check nothing.

TABLE_MODULE_KEYS <- list(
  generate_schedule = "schedule", schedule_bulk_import = "schedule", schedule_add_single = "schedule",
  schedule_browse = "schedule", schedule_visualizations = "schedule",
  schedule_generate_prep = c("schedule", "prep"), schedule_prep_checklist = "prep",
  schedule_add_commitment = "commitments", schedule_commitments_browse = "commitments",
  generate_diet = "diet", diet_bulk_import = "diet", diet_add_single = "diet", diet_browse = "diet", diet_visualizations = "diet",
  generate_workout = "exercise", exercise_bulk_import = "exercise", exercise_add_single = "exercise",
  exercise_browse = "exercise", exercise_visualizations = "exercise",
  muscle_programme = "muscle", muscle_log = "muscle", muscle_map = "muscle", muscle_progress = "muscle",
  scan_events = "events", bulk_import_events = "events", browse_events = "events", visualizations_events = "events",
  generate_programme = "funding", funding_bulk_import = "funding", funding_add_single = "funding",
  funding_browse = "funding", funding_visualizations = "funding",
  gantt_upload = "gantt_tasks", gantt_review_edit = "gantt_tasks", gantt_submit_boards = "gantt_tasks",
  gantt_manage_contacts = "gantt_contacts", gantt_email_send = "gantt_contacts", gantt_email_contacts = "gantt_contacts",
  contacts_process = "contacts", contacts_explore = "contacts",
  contacts_customise_communication = c("contacts", "communications"), contacts_send_email = c("contacts", "communications"))

# tab (module tab name) -> table keys, label for the sidebar, and which tab a single-module section shows
tables_tab_info <- function(layout) {
  keys <- list(); label <- list(); single <- list()
  for (g in layout$groups) for (s in g$sections) {
    if (length(s$modules) == 1) single[[s$id]] <- unname(layout$tabname_of[[s$modules]])
    for (mid in s$modules) {
      tn <- unname(layout$tabname_of[[mid]])
      k <- TABLE_MODULE_KEYS[[mid]]; if (length(k)) keys[[tn]] <- k
      ttl <- s$tab_labels[[mid]] %||% layout$menu_of[[mid]]$label
      label[[tn]] <- if (length(s$modules) > 1) paste0(g$label, " \u00b7 ", ttl) else g$label
    }
  }
  list(keys = keys, label = label, single = single)
}

# Sidebar TABLES section. Besides the per-group check notes it shows a live "Loading data..." line (and a thin moving bar)
# whenever the app is busy for more than ~0.4 s, and puts a small spinner next to the tab group the user just opened,
# so a few seconds of table checks and data loading never look like a frozen app.
tables_status_box <- function(data_tabs = character()) tagList(
  tags$style(HTML("
    #tables_busy { display: none; align-items: center; gap: 6px; font-size: 11.5px; color: #fde68a; margin: 2px 0 4px; }
    #sidebar_status_dock.bq-busy #tables_busy { display: flex; }
    #tables_bar { display: none; height: 3px; margin: -4px -10px 6px; border-radius: 3px; overflow: hidden; background: rgba(255,255,255,.12); }
    #sidebar_status_dock.bq-busy #tables_bar { display: block; }
    #tables_bar::before { content: ''; display: block; height: 100%; width: 35%; background: #fbbf24; border-radius: 3px; animation: bqslide 1.1s ease-in-out infinite; }
    @keyframes bqslide { 0% { margin-left: -35%; } 100% { margin-left: 100%; } }
    .sidebar-menu li.treeview.bq-loading > a::after, .sidebar-menu > li.bq-loading > a::after {
      content: ''; position: absolute; right: 34px; top: 50%; width: 12px; height: 12px; margin-top: -6px; border-radius: 50%;
      border: 2px solid rgba(251,191,36,.35); border-top-color: #fbbf24; animation: bqspin .8s linear infinite; }
    .sidebar-menu li.bq-loading > a { position: relative; }
    @keyframes bqspin { to { transform: rotate(360deg); } }")),
  tags$script(HTML(sprintf("
    (function() {
      var dataTabs = %s, seen = {};     // tabs that read BigQuery; 'seen' = tabs already shown once in this browser session
      var dock = function() { return document.getElementById('sidebar_status_dock'); };
      var clientBusy = false, serverWorking = false, busyTimer = null, pendingTimer = null, quietTimer = null, marked = null;
      var working = function() { return clientBusy || serverWorking; };
      var update = function() {
        var d = dock();
        if (working()) {
          if (quietTimer) { clearTimeout(quietTimer); quietTimer = null; }
          if (d) d.classList.add('bq-busy');
        } else if (!quietTimer && !pendingTimer) {
          // hysteresis: the table check and the data loading that follows are separate busy periods, so wait a moment
          quietTimer = setTimeout(function() {
            quietTimer = null;
            if (!working() && !pendingTimer) { var d2 = dock(); if (d2) d2.classList.remove('bq-busy'); if (marked) { marked.classList.remove('bq-loading'); marked = null; } }
          }, 1200);
        }
      };
      var mark = function(li) {
        if (!li) return; if (marked) marked.classList.remove('bq-loading');
        marked = li; li.classList.add('bq-loading');
        if (pendingTimer) clearTimeout(pendingTimer);
        pendingTimer = setTimeout(function() { pendingTimer = null; update(); }, 2200);   // grace period for the server to start
      };
      // the tab now showing: the section's active horizontal tab, or the single-module section itself
      var currentTab = function() {
        var pane = document.querySelector('.tab-content > .tab-pane.active[id^=\"shiny-tab-\"]'); if (!pane) return null;
        var a = pane.querySelector('.section-tabs > .tabbable > ul.nav-tabs > li.active > a');
        return a ? a.getAttribute('data-value') : pane.id.replace('shiny-tab-', '');
      };
      var onTabChange = function() {
        var key = currentTab(); if (!key || seen[key]) return; seen[key] = true;
        if (dataTabs.indexOf(key) < 0) return;                      // nothing to load for this tab: no spinner
        mark(document.querySelector('.sidebar-menu li.treeview.active') || document.querySelector('.sidebar-menu > li.active'));
      };
      $(document).on('shown.bs.tab', function() { setTimeout(onTabChange, 60); });
      $(document).on('shiny:connected', function() { setTimeout(onTabChange, 300); });
      $(document).on('shiny:busy', function() { if (!busyTimer) busyTimer = setTimeout(function() { clientBusy = true; update(); }, 400); });
      $(document).on('shiny:idle', function() { if (busyTimer) { clearTimeout(busyTimer); busyTimer = null; } clientBusy = false; update(); });
      // the server marks the status list while it is checking tables (that blocking work is invisible to the browser)
      var watch = function() {
        var el = document.getElementById('tables_status'); if (!el) return setTimeout(watch, 300);
        new MutationObserver(function() { serverWorking = !!el.querySelector('[data-working]'); update(); }).observe(el, { childList: true, subtree: true });
      };
      watch();
    })();", jsonlite::toJSON(unname(data_tabs), auto_unbox = FALSE)))),
  tags$div(style = "padding:10px; margin:6px 10px; background:rgba(0,0,0,.18); border-radius:8px;",
           tags$div(id = "tables_bar"),
           tags$div(style = "color:#b2e0db; font-size:11px; font-weight:700; margin-bottom:4px;", "TABLES"),
           tags$div(id = "tables_busy", icon("spinner", class = "fa-spin"), "Loading data for the tab you opened..."),
           uiOutput("tables_status")))

# Wires the tab the user is looking at to the table checks. `session` is the ROOT session; create_server puts a per-session
# reactiveVal of opened tabs in session$userData$tabs_opened, which the modules' tab_gate() calls read.
tables_wire <- function(api, session, layout) {
  info <- tables_tab_info(layout)
  opened <- session$userData$tabs_opened
  rv <- shiny::reactiveVal(0)
  bump <- function() rv(shiny::isolate(rv()) + 1)
  pending <- new.env()
  keys_opened <- session$userData$keys_opened
  mark_open <- function(tab) {
    if (!is.null(keys_opened)) keys_opened(unique(c(shiny::isolate(keys_opened()), info$keys[[tab]])))   # first: releases the shared loaders
    opened(unique(c(shiny::isolate(opened()), tab)))
  }

  open_tab <- function(tab) {
    if (tab %in% shiny::isolate(opened())) return(invisible())
    keys <- info$keys[[tab]]
    if (!length(keys)) return(mark_open(tab))                       # settings, About, Zoom, Slack, Travel: no tables
    lab <- info$label[[tab]] %||% tab
    if (!isTRUE(api$bq_authenticated)) {                            # not connected yet: remember it, run once connected
      pending[[tab]] <- TRUE; api$bq_note_status(lab, "waiting", "waiting for the BigQuery connection"); bump(); return(invisible())
    }
    if (all(vapply(keys, function(k) isTRUE(api$bq_keys_ready[[k]]), TRUE))) return(mark_open(tab))   # verified earlier: instant
    api$bq_note_status(lab, "checking", "checking tables...")
    bump()
    # the "checking" note reaches the browser FIRST (flush), then the blocking check runs, then the tab's loaders are released
    session$onFlushed(function() {
      shiny::withReactiveDomain(session, shiny::isolate({
        tryCatch(api$bq_ensure_keys(keys, lab), error = function(e) api$bq_note_status(lab, "failed", conditionMessage(e)))
        mark_open(tab)       # even after a failed check the tab loads, so it shows its own error instead of staying empty
        bump()
      }))
    }, once = TRUE)
    invisible()
  }

  shiny::observe({                                                  # the tab on screen: section + its active horizontal tab
    sec <- session$input$sidebar_menu; shiny::req(sec)
    inner <- session$input[[paste0("tabs_", sec)]]
    tab <- inner %||% info$single[[sec]]; shiny::req(tab)
    open_tab(tab)
  })
  shiny::observe({                                                  # a connection that arrives later runs the waiting tabs
    shiny::invalidateLater(1500)
    if (isTRUE(api$bq_authenticated)) for (tab in ls(pending)) { rm(list = tab, envir = pending); open_tab(tab) }
  })

  session$output$tables_status <- shiny::renderUI({
    rv(); shiny::invalidateLater(3000)
    stt <- api$bq_unit_status
    if (!length(stt)) return(tags$div(style = "font-size:11px; color:#b2e0db;",
                                      "Tables are checked the first time you open a tab group."))
    stt <- stt[order(vapply(stt, function(x) as.numeric(x$at), 0), decreasing = TRUE)]
    working <- any(vapply(stt, function(x) x$state == "checking", TRUE))
    tagList(if (working) tags$span(`data-working` = "1", style = "display:none;"), lapply(utils::head(stt, 3), function(x) {
      col <- switch(x$state, ready = "#22c55e", checking = "#fbbf24", waiting = "#fbbf24", "#ef4444")
      txt <- switch(x$state, checking = "checking tables...", waiting = "waiting for BigQuery", ready = x$detail,
                    paste0("check failed: ", substr(x$detail, 1, 80)))
      tags$div(style = "display:flex; gap:6px; margin:3px 0; font-size:11.5px; color:#ecf0f1;",
               if (x$state == "checking") icon("spinner", class = "fa-spin", style = "color:#fbbf24; margin-top:2px; flex:none;")
               else tags$span(style = sprintf("display:inline-block; width:10px; height:10px; border-radius:50%%; background:%s; margin-top:3px; flex:none;", col)),
               tags$span(tags$b(x$label, ": "), txt))
    }))
  })
  invisible(rv)
}
