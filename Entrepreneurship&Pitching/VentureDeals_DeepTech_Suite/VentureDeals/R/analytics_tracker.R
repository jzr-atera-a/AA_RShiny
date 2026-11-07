# R/analytics_tracker.R — User Interaction Tracker v2.1
# FIXED: JS inputs passed from parent server to bypass moduleServer namespacing
#
# Tracks:
#   - Tab navigation (which tab, how long spent)
#   - Slider / input changes (element name, new value) — debounced 1.5s
#   - Button clicks (which button)
#   - Box interactions (via JS click detection on .box elements)
#   - Plotly interactions (zoom, select)
#   - Session start / end
#
# All events queued in memory, flushed to Google Sheets every 10 seconds

library(shiny)

# ── JS injection ─────────────────────────────────────────────
analytics_js <- function() {
  tags$script(HTML("
    // ── Box click tracking ─────────────────────────────
    $(document).on('click', '.box', function(e) {
      var title = $(this).find('.box-title').first().text().trim();
      if (!title) title = $(this).find('h3,h4,h5').first().text().trim();
      if (!title) title = 'unnamed_box';
      Shiny.setInputValue('__tracker_box_click',
        { title: title, tab: $('.tab-pane.active').attr('id') || '', t: Date.now() },
        { priority: 'event' });
    });

    // ── Tab navigation tracking via JS ─────────────────
    $(document).on('shown.bs.tab', 'a[data-toggle=tab]', function(e) {
      var tabName = $(e.target).attr('data-value') ||
                    $(e.target).attr('href') || '';
      Shiny.setInputValue('__tracker_tab_change',
        { tab: tabName.replace('#',''), t: Date.now() },
        { priority: 'event' });
    });

    // Also watch sidebar menu clicks (shinydashboard)
    $(document).on('click', '.sidebar-menu a[data-toggle=tab]', function() {
      var tab = $(this).attr('data-value') || $(this).text().trim();
      Shiny.setInputValue('__tracker_tab_change',
        { tab: tab, t: Date.now() }, { priority: 'event' });
    });

    // ── Button click tracking ──────────────────────────
    $(document).on('click', '.action-button:not(#login_submit)', function() {
      var lbl = $(this).text().trim().substring(0, 60);
      var id  = $(this).attr('id') || 'unknown_btn';
      Shiny.setInputValue('__tracker_btn_click',
        { id: id, label: lbl, t: Date.now() }, { priority: 'event' });
    });

    // ── Plotly interaction tracking ────────────────────
    $(document).on('plotly_relayout plotly_selected', function(e, data) {
      var plotId = $(e.target).attr('id') || 'unknown_plot';
      Shiny.setInputValue('__tracker_plot_interact',
        { plot: plotId, t: Date.now() }, { priority: 'event' });
    });

    // ── Session timing ─────────────────────────────────
    var _sessionStart = Date.now();
    window.addEventListener('beforeunload', function() {
      var secs = Math.round((Date.now() - _sessionStart) / 1000);
      Shiny.setInputValue('__tracker_session_end',
        { secs: secs, t: Date.now() }, { priority: 'event' });
    });
  "))
}

# ── Tracker module ───────────────────────────────────────────
# All JS input reactives passed from parent server to bypass
# moduleServer namespace — input$__tracker_X becomes tracker-__tracker_X
# inside a moduleServer which breaks the JS->R binding

tracker_server <- function(id, email_reactive, session_id,
                           tab_reactive,
                           box_click_reactive,
                           btn_click_reactive,
                           tab_change_reactive,
                           plot_interact_reactive,
                           session_end_reactive,
                           flush_secs = 10) {
  cat("🔧 tracker_server called with id:", id, "\n")
  
  moduleServer(id, function(input, output, session) {
    cat("🔧 tracker moduleServer body executing\n")
    
    queue     <- reactiveVal(list())
    tab_state <- reactiveValues(current = "unknown", entered = Sys.time())
    
    # ── Push event ────────────────────────────────────────
    push_event <- function(event_type, tab = "", element = "",
                           detail = "", duration = NA) {
      em <- isolate(email_reactive())
      cat(sprintf("📊 push_event: type=%s email='%s' tab='%s'\n",
                  event_type, em %||% "NULL", tab))
      if (is.null(em) || !nzchar(trimws(em))) {
        cat("⚠ push_event: email empty — skipping\n")
        return(invisible())
      }
      ev <- list(
        email         = em,
        session_id    = session_id,
        event_type    = event_type,
        tab           = tab,
        element       = element,
        detail        = substr(as.character(detail), 1, 200),
        duration_secs = duration
      )
      queue(c(queue(), list(ev)))
      cat(sprintf("✓ Queued: %s | tab:'%s' | queue size:%d\n",
                  event_type, tab, length(queue())))
    }
    
    # ── Flush function ────────────────────────────────────
    flush_queue <- function(events) {
      if (length(events) == 0) return(invisible())
      cat(sprintf("📤 Flushing %d events...\n", length(events)))
      success_count <- 0
      for (ev in events) {
        tryCatch({
          sheets_log_event(
            email         = ev$email,
            session_id    = ev$session_id,
            event_type    = ev$event_type,
            tab           = ev$tab,
            element       = ev$element,
            detail        = ev$detail,
            duration_secs = ev$duration_secs
          )
          success_count <- success_count + 1
        }, error = function(e) {
          cat(sprintf("❌ Write failed: %s\n", e$message))
        })
      }
      cat(sprintf("✓ Flushed %d/%d events for %s\n",
                  success_count, length(events), isolate(email_reactive())))
    }
    
    # ── Session start when email becomes available ────────
    observeEvent(email_reactive(), {
      em <- email_reactive()
      cat(sprintf("👤 email_reactive -> '%s'\n", em %||% "NULL"))
      if (!is.null(em) && nzchar(trimws(em))) {
        push_event("session_start",
                   detail = paste0("host:", session$clientData$url_hostname))
      }
    }, ignoreNULL = FALSE, ignoreInit = FALSE)
    
    # ── Tab changes via parent input$tabs reactive ────────
    observeEvent(tab_reactive(), {
      new_tab <- tab_reactive()
      cat(sprintf("🗂 tab_reactive -> '%s' (was:'%s')\n",
                  new_tab %||% "NULL", tab_state$current))
      if (!is.null(new_tab) && nzchar(new_tab) && tab_state$current != new_tab) {
        duration <- as.numeric(Sys.time() - tab_state$entered, units = "secs")
        if (tab_state$current != "unknown")
          push_event("tab_exit", tab = tab_state$current,
                     duration = round(duration, 1))
        push_event("tab_view", tab = new_tab)
        tab_state$current <- new_tab
        tab_state$entered <- Sys.time()
      }
    }, ignoreNULL = TRUE, ignoreInit = TRUE)
    
    # ── JS tab change events (from parent reactive) ───────
    observeEvent(tab_change_reactive(), {
      tc <- tab_change_reactive()
      if (is.null(tc)) return()
      new_tab <- tc$tab
      cat(sprintf("🗂 JS tab_change -> '%s'\n", new_tab %||% "NULL"))
      if (!is.null(new_tab) && nzchar(new_tab) && tab_state$current != new_tab) {
        duration <- as.numeric(Sys.time() - tab_state$entered, units = "secs")
        if (tab_state$current != "unknown")
          push_event("tab_exit", tab = tab_state$current,
                     duration = round(duration, 1))
        push_event("tab_view", tab = new_tab)
        tab_state$current <- new_tab
        tab_state$entered <- Sys.time()
      }
    }, ignoreNULL = TRUE)
    
    # ── Box clicks (from parent reactive) ─────────────────
    observeEvent(box_click_reactive(), {
      bc <- box_click_reactive()
      if (is.null(bc)) return()
      cat(sprintf("📦 Box click: '%s'\n", bc$title))
      push_event("box_click", tab = tab_state$current,
                 element = "box", detail = bc$title)
    }, ignoreNULL = TRUE)
    
    # ── Button clicks (from parent reactive) ──────────────
    observeEvent(btn_click_reactive(), {
      bc <- btn_click_reactive()
      if (is.null(bc)) return()
      cat(sprintf("🔘 Button: id='%s'\n", bc$id))
      push_event("button_click", tab = tab_state$current,
                 element = bc$id, detail = bc$label)
    }, ignoreNULL = TRUE)
    
    # ── Plot interactions (from parent reactive) ───────────
    observeEvent(plot_interact_reactive(), {
      pi <- plot_interact_reactive()
      if (is.null(pi)) return()
      cat(sprintf("📈 Plot: '%s'\n", pi$plot))
      push_event("plot_interact", tab = tab_state$current,
                 element = pi$plot)
    }, ignoreNULL = TRUE)
    
    # ── Session end (from parent reactive) ────────────────
    observeEvent(session_end_reactive(), {
      se <- session_end_reactive()
      if (is.null(se)) return()
      cat(sprintf("🔚 Session end: %d secs\n", se$secs))
      push_event("session_end", duration = se$secs)
      flush_queue(queue())
      queue(list())
    }, ignoreNULL = TRUE)
    
    # ── Slider / input changes (debounced 1.5s) ───────────
    # These use input$ directly — they ARE namespaced correctly
    # because they come from child modules (montecarlo_valuation-rev_base etc)
    tracked_inputs <- c(
      "montecarlo_valuation-exit_val",
      "montecarlo_valuation-rev_base",
      "montecarlo_valuation-rev_sd",
      "montecarlo_valuation-mult_mean",
      "montecarlo_valuation-mult_sd",
      "montecarlo_valuation-future_dilution",
      "montecarlo_valuation-founder_own",
      "montecarlo_valuation-yrs_mean",
      "montecarlo_valuation-run_mc",
      "montecarlo_runway-cash_start",
      "montecarlo_runway-burn_start",
      "montecarlo_runway-burn_growth",
      "montecarlo_runway-rev_month_start",
      "montecarlo_runway-b_milestone_rev",
      "montecarlo_runway-shock_prob",
      "montecarlo_runway-shock_size",
      "montecarlo_runway-run_runway",
      "cap_table-serA_raised",
      "cap_table-serA_premoney",
      "cap_table-option_pool",
      "cap_table-seed_raised",
      "cap_table-seed_premoney",
      "cap_table-serB_raised",
      "cap_table-serB_premoney",
      "economic_terms-exit_val",
      "convertible-note_size",
      "convertible-cap",
      "convertible-discount",
      "convertible-serA_pre"
    )
    
    lapply(tracked_inputs, function(inp_id) {
      deb <- debounce(reactive({ input[[inp_id]] }), 1500)
      observe({
        val <- deb()
        if (!is.null(val)) {
          cat(sprintf("🎚 Input: %s = %s\n", inp_id, val))
          push_event("input_change", tab = tab_state$current,
                     element = inp_id,
                     detail  = paste0(val, collapse = ","))
        }
      })
    })
    
    # ── Periodic flush every N seconds ────────────────────
    observe({
      invalidateLater(flush_secs * 1000, session)
      isolate({
        evs <- queue()
        cat(sprintf("⏱ Flush check: %d events\n", length(evs)))
        if (length(evs) > 0) {
          flush_queue(evs)
          queue(list())
        }
      })
    })
    
    # ── Flush on session end ──────────────────────────────
    session$onSessionEnded(function() {
      isolate({
        evs <- queue()
        cat(sprintf("🔚 Session ended — flushing %d events\n", length(evs)))
        if (length(evs) > 0) flush_queue(evs)
      })
    })
    
    cat("✓ Tracker module fully initialised\n")
  })
}