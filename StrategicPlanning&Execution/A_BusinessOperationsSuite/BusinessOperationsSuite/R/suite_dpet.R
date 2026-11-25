# R/suite_dpet.R
# =============================================================================
# DaysPlanningExerciseTravel (DPET) inside this app - Events Scheduling, Day Planner, Travel Planning,
# Exercise Tracker, Diet Planner and API Settings > Titan Calendar.
#
# The DPET tabs run UNCHANGED, with DPET's own tested helpers and its own APIManager class:
#   * R/dpet/*.R are DPET's R files as shipped. They are sourced into DPET_ENV (not the global environment), so
#     where both apps have a helper with the same name (nav_layout, generic_export_box_ui, parse_programme_text ...)
#     DPET tabs keep using DPET's version and this app's tabs keep using this app's version.
#   * The DPET tab files (registry entries with `suite: dpet`) are sourced into DPET_ENV too; only their
#     <id>_ui / <id>_server entry points are put in the global environment, where the module loader finds them.
#   * Each browser session has ONE DPET APIManager (api_manager$dpet). DPET tabs get that one.
#   * dpet_bridge_wire() keeps it connected through THIS app's API Settings: the same BigQuery key, project and
#     dataset (atera-2.business_strategy), the same Claude key and model, and Google Drive (see below). There are
#     no second BigQuery / Claude / Drive tabs.
#   * Tables: a DPET tab's BigQuery tables are checked the first time that tab is opened (as in DPET), and the
#     result appears in the sidebar TABLES box next to this app's units.
# =============================================================================

DPET_ENV <- new.env(parent = globalenv())

# same order as DPET's global.R
DPET_FILES <- c("utils_timezone.R", "utils_common.R", "utils_api.R", "utils_export.R", "utils_ics.R",
                "utils_calendar_export.R", "utils_titan.R", "utils_slack.R", "utils_zoom.R", "utils_muscle_body.R",
                "utils_muscle.R", "utils_local_creds.R", "utils_gdrive.R", "utils_diagram.R", "utils_drive_export.R",
                "utils_nav.R", "utils_tables.R", "utils_suite_tabs.R")
for (f in DPET_FILES) sys.source(file.path("R", "dpet", f), envir = DPET_ENV, keep.source = FALSE)
cat(sprintf("✓ [DPET] %d helper files loaded (Events, Day Planner, Travel, Exercise, Diet)\n", length(DPET_FILES)))

# Sources one DPET tab file into DPET_ENV and exposes its entry points. The server entry point is handed the
# session's DPET manager instead of this app's manager.
dpet_source_module <- function(path, mod_id) {
  sys.source(path, envir = DPET_ENV, keep.source = FALSE)
  ui_fn <- paste0(mod_id, "_ui"); server_fn <- paste0(mod_id, "_server")
  if (!exists(ui_fn, envir = DPET_ENV, inherits = FALSE) || !exists(server_fn, envir = DPET_ENV, inherits = FALSE)) return(FALSE)
  assign(ui_fn, get(ui_fn, envir = DPET_ENV), envir = globalenv())
  srv <- get(server_fn, envir = DPET_ENV)
  assign(server_fn, function(id, api_manager) srv(id, dpet_manager(api_manager)), envir = globalenv())
  TRUE
}

dpet_manager <- function(api_manager) {
  if (is.null(api_manager$dpet)) api_manager$dpet <- DPET_ENV$APIManager$new()
  api_manager$dpet
}

# -----------------------------------------------------------------------------
# Per-session wiring. Called from create_server() BEFORE the module servers run.
# -----------------------------------------------------------------------------
dpet_bridge_wire <- function(api, session, layout) {
  dp <- dpet_manager(api)

  # DPET tabs load their data only once the tab has been opened (their tab_gate / keys_gate read these two)
  session$userData$tabs_opened <- shiny::reactiveVal(character())
  session$userData$keys_opened <- shiny::reactiveVal(character())
  keys_of <- DPET_ENV$TABLE_MODULE_KEYS

  # labels for the TABLES box: "Group · Tab"
  label_of <- list(); sec_mods <- list()
  for (g in layout$groups) for (s in g$sections) {
    sec_mods[[s$id]] <- s$modules
    for (mid in s$modules) label_of[[mid]] <- if (length(s$modules) > 1) paste0(g$label, " · ", s$tab_labels[[mid]] %||% mid) else g$label
  }

  pending <- new.env()
  mark_open <- function(tab) {
    kr <- session$userData$keys_opened; kr(unique(c(shiny::isolate(kr()), keys_of[[tab]])))
    tr <- session$userData$tabs_opened; tr(unique(c(shiny::isolate(tr()), tab)))
  }
  open_tab <- function(tab) {                                   # DPET's tables_wire()$open_tab, on this app's sidebar
    if (tab %in% shiny::isolate(session$userData$tabs_opened())) return(invisible())
    keys <- keys_of[[tab]]
    if (!length(keys)) return(mark_open(tab))
    lab <- label_of[[tab]] %||% tab
    if (!isTRUE(dp$bq_authenticated)) {
      pending[[tab]] <- TRUE
      dp$bq_note_status(lab, if (isTRUE(api$cred_status$done) && !isTRUE(api$bq_authenticated)) "offline" else "waiting",
                        if (isTRUE(api$cred_status$done) && !isTRUE(api$bq_authenticated)) "BigQuery not connected: open API Settings"
                        else "waiting for the BigQuery connection")
      return(invisible())
    }
    if (all(vapply(keys, function(k) isTRUE(dp$bq_keys_ready[[k]]), TRUE))) return(mark_open(tab))
    dp$bq_note_status(lab, "checking", "checking tables...")
    session$onFlushed(function() {
      shiny::withReactiveDomain(session, shiny::isolate({
        tryCatch(dp$bq_ensure_keys(keys, lab), error = function(e) dp$bq_note_status(lab, "failed", conditionMessage(e)))
        mark_open(tab)
      }))
    }, once = TRUE)
    invisible()
  }
  shiny::observe({                                              # the tab on screen
    sec <- session$input$sidebar_menu; shiny::req(sec)
    mods <- sec_mods[[sec]]; shiny::req(mods)
    tab <- if (length(mods) == 1) mods else session$input[[paste0("tabs_", sec)]]; shiny::req(tab)
    open_tab(tab)
  })

  # ---- credentials: this app's API Settings -> the DPET manager --------------------------------------------
  last <- new.env()
  sync <- function() {
    # BigQuery: same service-account key, project and dataset
    if (isTRUE(api$bq_authenticated) && !is.null(api$bq_credentials_path)) {
      want <- paste(api$bq_credentials_path, api$bq_project_id, api$bq_dataset_id)
      if (!isTRUE(dp$bq_authenticated) || !identical(last$bq, want)) {
        last$bq <- want
        ok <- tryCatch({
          dp$set_bigquery_credentials(api$bq_project_id, api$bq_dataset_id)
          dp$authenticate_bigquery(json_path = api$bq_credentials_path)
        }, error = function(e) { cat("[DPET] BigQuery hand-over failed:", conditionMessage(e), "\n"); FALSE })
        if (isTRUE(ok)) {
          cat("✓ [DPET] BigQuery connected through API Settings\n")
          for (tab in ls(pending)) { rm(list = tab, envir = pending); open_tab(tab) }
        }
      }
    } else if (isTRUE(dp$bq_authenticated) && !isTRUE(api$bq_authenticated)) {
      dp$bq_authenticated <- FALSE; last$bq <- NULL
    }
    # Claude: same key and model
    key <- api$claude_api_key %||% ""
    if (nzchar(key) && (!identical(dp$claude_api_key, key) || !identical(dp$claude_model, api$claude_model))) {
      dp$set_claude_credentials(key, model = api$claude_model)
      dp$claude_authenticated <- TRUE
      dp$claude_tested <- if (isTRUE(api$claude_authenticated)) NA else FALSE
    } else if (!nzchar(key) && isTRUE(dp$claude_authenticated)) {
      dp$claude_authenticated <- FALSE; dp$claude_api_key <- NULL
    }
    # Google Drive ("Save Diagrams to Google Drive" boxes on the DPET tabs: service account + shared folder)
    if (!isTRUE(dp$gdrive_authenticated) && isTRUE(dp$bq_authenticated)) {
      st <- tryCatch(gd_load_settings(), error = function(e) NULL)
      want <- paste(st$auth_mode, st$key_file, st$root_folder, dp$bq_key_path)
      if (!identical(last$drive, want)) {
        last$drive <- want
        tryCatch(DPET_ENV$gdrive_restore(dp), error = function(e) NULL)        # DPET's own saved folder, if any
        if (!isTRUE(dp$gdrive_authenticated) && identical(st$auth_mode, "service_account") && nzchar(st$root_folder %||% "")) {
          k <- if (nzchar(st$key_file %||% "")) st$key_file else dp$bq_key_path
          dp$gdrive_use_bq_key <- !nzchar(st$key_file %||% ""); dp$gdrive_key_path <- if (nzchar(st$key_file %||% "")) st$key_file
          tryCatch({ DPET_ENV$gdrive_connect(dp, k, st$root_folder); cat("✓ [DPET] Google Drive boxes use the API Settings folder\n") },
                   error = function(e) cat("[DPET] Google Drive folder not reachable with the service account:", conditionMessage(e), "\n"))
        }
      }
    }
  }
  shiny::observe({ shiny::invalidateLater(1500); shiny::isolate(tryCatch(sync(), error = function(e) cat("[DPET] sync:", conditionMessage(e), "\n"))) })
  invisible(dp)
}

# Statuses of the DPET table checks, for the sidebar TABLES box (merged with this app's units in R/utils_tables.R)
dpet_unit_status <- function(api) if (is.null(api$dpet)) list() else api$dpet$bq_unit_status
