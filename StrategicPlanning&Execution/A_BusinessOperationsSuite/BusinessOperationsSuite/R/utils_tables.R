# R/utils_tables.R
# ON-DEMAND TABLE LOADING + SIDEBAR "TABLES" INDICATOR
#
# Start-up only authenticates BigQuery (one quick round trip). The BigQuery tables a tab reads are verified and loaded
# the first time THAT TAB is shown (not when its group or section is clicked) and never again in the session. The sidebar
# shows what is happening - right under the API CONNECTIONS lights:
#
#   waiting   BigQuery is still connecting (the check runs as soon as it is)
#   checking  verifying / creating the group's tables
#   loading   pulling the group's data (dropdown values, contacts ...)
#   ready     done ("2 table(s) ready, data loaded in 1.4 s")
#   failed    something went wrong (message shown)
#   offline   BigQuery is not connected (connect it in API Settings)
#
# Which tabs read which tables is declared in modules/_module_registry.yml (`bq_unit:` on a module):
#   explore_contacts, customise_communication              -> contacts   business_contacts, contact_communications
#   generate_programme, funding_add_single, funding_visualizations -> funding    funding_programmes
#   bm_canvas_view, de_canvas_view, de_roadmap_view         -> canvases   the 3 canvas/roadmap tables
# Other tabs check nothing until they write (insert methods call bq_need on first use).
# Safety net: every data method in APIManager also calls bq_need(), so a table is never used unverified.

tables_status_box <- function() tagList(
  tags$div(class = "bo-side-card",
           tags$div(class = "bo-side-title", "TABLES"),
           tags$div(id = "bo_tables_status", class = "bo-tables",
                    tags$div(class = "bo-hint", "Tables are loaded the first time you open a tab group."))),
  tags$script(HTML("
    $(function () {
      var items = [], timer = null;
      var HINT = 'Tables are loaded the first time you open a tab group.';
      function esc(s) { return String(s == null ? '' : s).replace(/[&<>\"]/g, function (c) { return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]; }); }
      function render() {
        var el = document.getElementById('bo_tables_status'); if (!el) return;
        if (!items.length) { el.innerHTML = '<div class=\"bo-hint\">' + HINT + '</div>'; return; }
        var now = Date.now(), busy = false, html = '';
        items.forEach(function (x) {
          var live = (x.state === 'checking' || x.state === 'loading' || x.state === 'waiting');
          if (live) busy = true;
          var secs = live ? Math.floor(x.age + (now - x.rcv) / 1000) : 0;
          var txt = esc(x.detail) + (live && secs >= 2 ? ' (' + secs + ' s)' : '');
          var lead = live ? '<i class=\"fa fa-spinner fa-spin bo-spin\"></i>'
                          : '<span class=\"bo-dot\" style=\"background:' + (x.state === 'ready' ? '#22c55e' : x.state === 'offline' ? '#94a3b8' : '#ef4444') + '\"></span>';
          html += '<div class=\"bo-light bo-unit-' + esc(x.state) + '\">' + lead + '<span><b>' + esc(x.label) + ': </b>' + txt + '</span></div>';
        });
        el.innerHTML = html;
        if (busy && !timer) timer = setInterval(render, 1000);
        if (!busy && timer) { clearInterval(timer); timer = null; }
      }
      Shiny.addCustomMessageHandler('bo-tables-status', function (m) {
        var now = Date.now();
        items = [].concat(m.units || []).map(function (x) { x.rcv = now; return x; });
        render();
      });
    });
  "))
)

# Wires the TABLES box to the tab the user is actually looking at. `session` is the ROOT session.
# The active module = the single module of the open sidebar section, or the selected horizontal tab inside it.
# Clicking a group or a section header loads nothing by itself.
tables_wire <- function(api, session, layout, registry) {
  mod_unit <- list()
  for (mid in names(registry$modules)) { u <- registry$modules[[mid]]$bq_unit; if (!is.null(u)) mod_unit[[mid]] <- u }
  sec_mods <- list()
  for (g in layout$groups) for (s in g$sections) sec_mods[[s$id]] <- s$modules

  push <- function() {
    stt <- api$bq_unit_status
    if (!length(stt)) { session$sendCustomMessage("bo-tables-status", list(units = list())); return(invisible()) }
    stt <- stt[order(vapply(stt, function(x) as.numeric(x$at), 0), decreasing = TRUE)]
    units <- lapply(utils::head(stt, 4), function(x)
      list(label = x$label, state = x$state, detail = x$detail,
           age = as.numeric(difftime(Sys.time(), if (is.null(x$since)) x$at else x$since, units = "secs"))))
    session$sendCustomMessage("bo-tables-status", list(units = unname(units)))
    invisible()
  }
  # every bq_note_status() (checking / loading / ready ...) is pushed to the browser at once, even while R is busy querying
  api$status_hook <- push

  run_unit <- function(unit) {
    # once per session: a unit that is verified AND loaded is never touched again
    if (isTRUE(api$bq_units_ready[[unit]]) && isTRUE(api$bq_units_opened[[unit]])) return(invisible())
    if (!isTRUE(api$bq_authenticated)) {            # not connected (yet): remember the tab, the load runs after connecting
      api$bq_units_opened[[unit]] <- TRUE
      if (isTRUE(api$cred_status$done)) api$bq_note_status(unit, "offline", "BigQuery not connected: open API Settings")
      else api$bq_note_status(unit, "waiting", "waiting for the BigQuery connection")
      return(invisible())
    }
    api$bq_note_status(unit, "checking", "checking tables...")
    # the "checking" note is already on its way to the browser; the page is flushed first, THEN the blocking load runs
    session$onFlushed(function() {
      shiny::withReactiveDomain(session, shiny::isolate({
        tryCatch(api$bq_open_unit(unit), error = function(e) api$bq_note_status(unit, "failed", conditionMessage(e)))
      }))
    }, once = TRUE)
  }

  active_module <- shiny::reactive({
    sec <- session$input$sidebar_menu; if (is.null(sec)) return(NULL)
    mods <- sec_mods[[sec]]; if (is.null(mods)) return(NULL)
    if (length(mods) == 1) mods else session$input[[paste0("tabs_", sec)]]
  })
  shiny::observeEvent(active_module(), {            # a tab was shown (sidebar click, horizontal tab, or a link between tabs)
    u <- mod_unit[[active_module()]]; if (!is.null(u)) run_unit(u)
  }, ignoreNULL = TRUE, ignoreInit = FALSE)
  # safety net: if the connection arrives later (manual key) any tab still waiting is run
  shiny::observe({
    shiny::invalidateLater(2000)
    if (isTRUE(api$bq_authenticated)) for (u in names(api$bq_unit_status))
      if (api$bq_unit_status[[u]]$state %in% c("waiting", "offline")) run_unit(u)
  })
  invisible(NULL)
}
