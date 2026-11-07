# modules/vehicle_data.R - Welch Group Fleet Monitor
# Tab 2: Vehicle Data Queries – Positions, Statuses, Telemetry, Geographic Analysis

# ══════════════════════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════════════════════
vehicle_data_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "wg-page-header",
      div(class = "wg-page-title",
        tags$i(class = "fa fa-truck", style = "margin-right:10px;"),
        "EV Artic Fleet – Live Data & Analytics"
      ),
      div(class = "wg-page-subtitle",
        "Query vehicle positions, telemetry status and accumulated data for the Welch Group EV Artic fleet.",
        " Requires an active API connection (Tab 1)."
      )
    ),

    # ── Query controls ─────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "wg-card",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-sliders", style = "margin-right:8px;"),
            "Query Parameters"
          ),
          div(class = "wg-card-body",
            fluidRow(
              # Vehicle selector — rebuilt from cache in server
              column(3,
                div(class = "wg-field-group",
                  tags$label("Vehicle(s)", class = "wg-label"),
                  uiOutput(ns("vehicle_selector_ui")),
                  uiOutput(ns("resolved_vins_display"))
                )
              ),
              column(3,
                div(class = "wg-field-group",
                  tags$label("Query Type", class = "wg-label"),
                  radioButtons(
                    ns("query_type"), label = NULL,
                    choices  = c(
                      "Vehicle List (metadata)" = "vehicles",
                      "Positions (GPS)"         = "positions",
                      "Statuses (telemetry)"    = "statuses",
                      "Everything (full dump)"  = "everything"
                    ),
                    selected = "vehicles"
                  ),
                  conditionalPanel(
                    condition = sprintf("input['%s'] == 'everything'", ns("query_type")),
                    div(style = "margin-top:6px;padding:8px 10px;background:#edfaf9;border-left:3px solid #1a9b9b;border-radius:3px;",
                      tags$i(class = "fa fa-info-circle", style = "color:#1a9b9b;margin-right:6px;"),
                      tags$small(style = "color:#006b63;",
                        "Fires both Statuses and Positions with zero filters — all sections,",
                        " all triggers, all EV fields. Paginates automatically until the",
                        " API returns no more records. May take 10–30s for large fleets."
                      )
                    )
                  )
                ),
                conditionalPanel(
                  condition = sprintf("input['%s'] == 'statuses'", ns("query_type")),
                  div(class = "wg-field-group",
                    tags$label("Content Filter (statuses)", class = "wg-label"),
                    tags$small(style="color:#8899aa;display:block;margin-bottom:4px;",
                      "Omit = all sections returned"),
                    checkboxGroupInput(
                      ns("status_content"), label = NULL,
                      choices  = c("ACCUMULATED (lifetime totals)" = "ACCUMULATED",
                                   "SNAPSHOT (event-based)"       = "SNAPSHOT",
                                   "UPTIME (health/tell-tales)"   = "UPTIME"),
                      selected = c("ACCUMULATED", "SNAPSHOT")
                    )
                  ),
                  div(class = "wg-field-group",
                    tags$label("EV Additional Data", class = "wg-label"),
                    checkboxGroupInput(
                      ns("status_additional"), label = NULL,
                      choices  = c("EV Accumulated (energy/charging)" = "VOLVOGROUPACCUMULATED",
                                   "EV Snapshot (charging events)"    = "VOLVOGROUPSNAPSHOT"),
                      selected = c("VOLVOGROUPACCUMULATED", "VOLVOGROUPSNAPSHOT")
                    )
                  )
                )
              ),
              column(3,
                div(class = "wg-field-group",
                  tags$label("Start Time (UTC)", class = "wg-label"),
                  dateInput(ns("start_date"), label = NULL,
                            value = Sys.Date() - 13,
                            max   = Sys.Date(),
                            width = "100%")
                ),
                div(class = "wg-field-group",
                  tags$label("End Time (UTC)", class = "wg-label"),
                  dateInput(ns("end_date"), label = NULL,
                            value = Sys.Date(),
                            max   = Sys.Date(),
                            width = "100%")
                ),
                conditionalPanel(
                  condition = sprintf("input['%s'] != 'vehicles'", ns("query_type")),
                  checkboxInput(ns("latest_only"), "Latest record only (ignore time window)", FALSE)
                ),
                conditionalPanel(
                  condition = sprintf("input['%s'] != 'vehicles'", ns("query_type")),
                  div(style = "margin-top:6px;padding:7px 10px;background:#edfaf9;border-left:3px solid #fd7e14;border-radius:3px;",
                    tags$i(class = "fa fa-clock-o", style = "color:#fd7e14;margin-right:6px;"),
                    tags$small(style = "color:#c8a96e;",
                      "Positions & Statuses: API limit is last 14 days only."
                    )
                  )
                )
              ),
              column(3,
                div(class = "wg-field-group",
                  tags$label("Trigger Filter (positions/statuses)", class = "wg-label"),
                  selectInput(ns("trigger_filter"), label = NULL,
                    choices = c(
                      "── General ──"                              = "",
                      "No filter (all)"                            = "",
                      "TIMER (periodic)"                           = "TIMER",
                      "IGNITION_ON"                                = "IGNITION_ON",
                      "IGNITION_OFF"                               = "IGNITION_OFF",
                      "ENGINE_ON"                                  = "ENGINE_ON",
                      "ENGINE_OFF"                                 = "ENGINE_OFF",
                      "DRIVER_LOGIN"                               = "DRIVER_LOGIN",
                      "DRIVER_LOGOUT"                              = "DRIVER_LOGOUT",
                      "TELL_TALE (health alerts)"                  = "TELL_TALE",
                      "IDLING"                                     = "IDLING",
                      "DISTANCE_TRAVELLED"                         = "DISTANCE_TRAVELLED",
                      "FLEET_OVERSPEED"                            = "FLEET_OVERSPEED",
                      "── EV / Charging ──"                        = "",
                      "BATTERY_PACK_CHARGING_STATUS_CHANGE"        = "BATTERY_PACK_CHARGING_STATUS_CHANGE",
                      "BATTERY_PACK_CHARGING_CONNECTION_STATUS_CHANGE" = "BATTERY_PACK_CHARGING_CONNECTION_STATUS_CHANGE",
                      "BATTERY_PACK_ENERGY_USAGE"                  = "BATTERY_PACK_ENERGY_USAGE",
                      "BATTERY_PACK_HIGH_DISCHARGE"                = "BATTERY_PACK_HIGH_DISCHARGE",
                      "BATTERY_PRECONDITIONING"                    = "BATTERY_PRECONDITIONING",
                      "VEHICLE_COUPLER_UNLOCK_ALLOWED"             = "VEHICLE_COUPLER_UNLOCK_ALLOWED",
                      "VEHICLE_MODE"                               = "VEHICLE_MODE",
                      "CLIMATE_STATUS"                             = "CLIMATE_STATUS"
                    ),
                    width = "100%"
                  )
                ),
                tags$br(),
                actionButton(ns("btn_query"), "Run Query",
                             icon = icon("search"),
                             class = "wg-btn wg-btn-primary", width = "100%"),
                tags$br(), tags$br(),
                actionButton(ns("btn_probe"), "Probe API (latestOnly)",
                             icon = icon("stethoscope"),
                             title = "Fires latestOnly=true with no time window — the simplest possible query to test if ANY data exists",
                             class = "wg-btn wg-btn-secondary", width = "100%",
                             style = "background:#1a3a2a;border-color:#2ecc71;color:#2ecc71;"),
                tags$br(), tags$br(),
                actionButton(ns("btn_demo"), "Load Demo Data",
                             icon = icon("flask"),
                             class = "wg-btn wg-btn-secondary", width = "100%"),
                tags$br(),
                tags$small(class = "wg-hint",
                  tags$i(class = "fa fa-info-circle"),
                  " Demo data allows UI exploration without an active API connection."
                )
              )
            )
          )
        )
      )
    ),

    # ── Summary metrics ────────────────────────────────────────────
    fluidRow(column(12, uiOutput(ns("summary_metrics")))),

    # ── Results ────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "wg-card", style = "margin-top:6px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-database", style = "margin-right:8px;"),
            "Query Results",
            uiOutput(ns("result_meta_badge"), inline = TRUE)
          ),
          div(class = "wg-card-body",
            tabsetPanel(id = ns("result_tabs"),
              tabPanel("Data Table",
                tags$br(),
                div(style = "margin-bottom:8px;display:flex;align-items:center;gap:12px;",
                  tags$span(style = "color:#006b63;font-size:13px;",
                    tags$i(class="fa fa-table", style="margin-right:6px;"),
                    "Structured data frame — all parsed fields."
                  ),
                  downloadButton(ns("btn_download_csv"), "Download CSV",
                    style = "padding:3px 10px;font-size:12px;background:#e8f8f5;border-color:#1a9b9b;color:#006b63;")
                ),
                uiOutput(ns("data_table_ui"))
              ),
              tabPanel("Raw JSON",
                tags$br(),
                div(style = "margin-bottom:8px;display:flex;align-items:center;gap:12px;",
                  tags$span(style = "color:#006b63;font-size:13px;",
                    tags$i(class="fa fa-code", style="margin-right:6px;"),
                    "Verbatim API response — every field the server returned, unflattened."
                  ),
                  downloadButton(ns("btn_download_json"), "Download JSON",
                    style = "padding:3px 10px;font-size:12px;background:#e8f8f5;border-color:#1a9b9b;color:#006b63;")
                ),
                div(style = "background:#f0faf9;border:1px solid #b2e0dd;border-radius:4px;
                             max-height:600px;overflow:auto;padding:12px;",
                  verbatimTextOutput(ns("raw_json_display"))
                )
              ),
              tabPanel("Geographic Map",
                tags$br(),
                conditionalPanel(
                  condition = sprintf("input['%s'] == 'positions'", ns("query_type")),
                  div(class = "wg-map-controls",
                    div(style = "display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;",
                      div(
                        tags$small("Colour = vehicle. Circle size = speed. Toggle route polyline below."),
                        checkboxInput(ns("map_polyline"), "Draw route polyline", FALSE)
                      ),
                      downloadButton(ns("btn_download_geojson"), "Download GeoJSON (AR)",
                        style = "padding:4px 12px;font-size:12px;background:#1a3a2a;border-color:#28a745;color:#28a745;")
                    )
                  ),
                  leaflet::leafletOutput(ns("position_map"), height = "480px")
                ),
                conditionalPanel(
                  condition = sprintf("input['%s'] != 'positions'", ns("query_type")),
                  div(class = "wg-empty-state",
                    tags$i(class = "fa fa-map-marker", style = "font-size:32px;opacity:.3;"),
                    tags$p("Switch Query Type to 'Positions (GPS)' to see the map.")
                  )
                )
              ),
              tabPanel("Trends & Charts",
                tags$br(), uiOutput(ns("trends_ui"))
              ),
              tabPanel("Statistics & Metadata",
                tags$br(), uiOutput(ns("statistics_ui"))
              ),
              tabPanel("Debug & Diagnostics",
                tags$br(),
                # ── Query summary box ─────────────────────────────
                div(class = "wg-debug-section",
                  style = "margin-bottom:14px;",
                  tags$h5(style = "color:#008A82;margin-bottom:8px;",
                    tags$i(class="fa fa-send", style="margin-right:6px;"), "Last Request Sent"
                  ),
                  verbatimTextOutput(ns("debug_request"))
                ),
                # ── Response summary ──────────────────────────────
                div(class = "wg-debug-section",
                  style = "margin-bottom:14px;",
                  tags$h5(style = "color:#008A82;margin-bottom:8px;",
                    tags$i(class="fa fa-reply", style="margin-right:6px;"), "Response Summary"
                  ),
                  verbatimTextOutput(ns("debug_response"))
                ),
                # ── Connected services per vehicle ────────────────
                div(class = "wg-debug-section",
                  style = "margin-bottom:14px;",
                  tags$h5(style = "color:#008A82;margin-bottom:8px;",
                    tags$i(class="fa fa-plug", style="margin-right:6px;"),
                    "Connected Services (queried vehicles)"
                  ),
                  tags$small(style = "color:#8899aa;display:block;margin-bottom:6px;",
                    "MAP service drives ALL triggers for both positions and statuses (per API spec)."
                  ),
                  verbatimTextOutput(ns("debug_services"))
                ),
                # ── Raw JSON ──────────────────────────────────────
                div(class = "wg-debug-section",
                  tags$h5(style = "color:#008A82;margin-bottom:8px;",
                    tags$i(class="fa fa-code", style="margin-right:6px;"), "Raw API Response (first 50 records)"
                  ),
                  verbatimTextOutput(ns("raw_json"))
                )
              )
            )
          )
        )
      )
    )
  )
}

# ══════════════════════════════════════════════════════════════════
#  SERVER
# ══════════════════════════════════════════════════════════════════
vehicle_data_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- reactiveValues(
      raw_result    = NULL,
      df            = NULL,        # primary df (statuses for "everything", or single-endpoint)
      df_positions  = NULL,        # positions df when query_type == "everything"
      df_statuses   = NULL,        # statuses df when query_type == "everything"
      raw_json_text = NULL,        # full serialised JSON string for Raw JSON subtab
      query_type    = NULL,
      query_time    = NULL,
      is_demo       = FALSE
    )

    # ── Dynamic vehicle selector ─────────────────────────────────
    # Values are always real VINs once connected.
    # Labels show VIN in small text so the user can verify which VIN maps to which name.
    output$vehicle_selector_ui <- renderUI({
      cache <- api_manager$vehicles_cache %||% list()

      if (length(cache) == 0) {
        # Before connection: placeholder text — VINs not yet known
        choices <- c(
          "All vehicles"        = "ALL",
          "N88GNW (EV Artic)"   = "NAME:N88GNW",
          "TA70 WTL (EV Artic)" = "NAME:TA70 WTL"
        )
        sel <- "ALL"
      } else {
        # Build choices with VIN visible in the label so user can verify
        # Use HTML labels: vehicle name on line 1, VIN in small dim text on line 2
        make_label <- function(v) {
          name   <- v$customerVehicleName %||% (v$vin %||% "?")
          model  <- v$model %||% ""
          fuel   <- paste(v$possibleFuelType %||% list(), collapse = "")
          ev_tag <- if (grepl("08", fuel)) " [EV]" else ""
          vin    <- v$vin %||% "?"
          as.character(tags$span(
            tags$span(paste0(name, " - ", model, ev_tag)),
            tags$br(),
            tags$small(style = "color:#007a73;font-family:monospace;font-size:10px;",
              vin)
          ))
        }

        labels <- sapply(cache, make_label)
        values <- sapply(cache, function(v) v$vin %||% "")
        keep   <- nchar(values) > 0
        vehicle_choices <- setNames(values[keep], labels[keep])
        choices <- c("All vehicles" = "ALL", vehicle_choices)

        # Pre-select the two known EV trucks by VIN (fuel type 08 = BEV)
        ev_vins <- sapply(cache, function(v) {
          fuel <- paste(v$possibleFuelType %||% list(), collapse = "")
          if (grepl("08", fuel)) v$vin %||% "" else ""
        })
        ev_vins <- unique(ev_vins[nchar(ev_vins) > 0])
        sel <- if (length(ev_vins) > 0) ev_vins else "ALL"
        cat("[TAB2] vehicle_selector_ui rebuilt — EV trucks pre-selected:",
            paste(ev_vins, collapse = ", "), "\n")
      }

      checkboxGroupInput(
        ns("selected_vehicles"), label = NULL,
        choices  = choices,
        selected = sel
      )
    })

    # ── Live VIN resolution readout ───────────────────────────────
    # Shows exactly which VIN strings will be sent to the API for the current selection
    output$resolved_vins_display <- renderUI({
      sel <- input$selected_vehicles
      if (is.null(sel)) return(NULL)

      if ("ALL" %in% sel) {
        n_total <- length(api_manager$vehicles_cache %||% list())
        txt <- if (n_total > 0)
          paste0("→ ALL vehicles (", n_total, ") — no vin= param sent")
        else
          "→ All vehicles (connect first to see count)"
        div(style = "margin-top:6px;padding:5px 8px;background:#f0faf9;
                     border-left:2px solid #1a9b9b;border-radius:2px;",
          tags$small(style = "color:#007a73;font-family:monospace;font-size:10px;", txt))
      } else {
        vins <- resolve_vins()
        if (is.null(vins) || length(vins) == 0) {
          div(style = "margin-top:6px;padding:5px 8px;background:#fff5f5;border-left:2px solid #e05c5c;border-radius:2px;",
            tags$small(style = "color:#e05c5c;font-size:10px;", "⚠ No VINs resolved — check selection"))
        } else {
          # Resolve each VIN back to its display name for cross-check
          cache <- api_manager$vehicles_cache %||% list()
          rows <- lapply(vins, function(vin) {
            nm <- vin
            for (v in cache) { if (identical(v$vin %||% "", vin)) { nm <- v$customerVehicleName %||% vin; break } }
            tags$div(
              tags$span(style = "color:#006b63;font-size:10px;font-family:monospace;", vin),
              tags$span(style = "color:#8899aa;font-size:10px;", paste0(" (", nm, ")"))
            )
          })
          div(style = "margin-top:6px;padding:5px 8px;background:#f0faf9;
                       border-left:2px solid #1a9b9b;border-radius:2px;",
            tags$small(style = "color:#007a73;font-size:10px;display:block;margin-bottom:3px;",
              paste0("→ Sending ", length(vins), " VIN(s) to API:")),
            do.call(tagList, rows)
          )
        }
      }
    })

    # ── Resolve VINs from selector values ────────────────────────
    # Values are either "ALL", a real VIN, or "NAME:xxx" (pre-connection placeholder)
    resolve_vins <- function() {
      sel <- input$selected_vehicles
      if (is.null(sel) || "ALL" %in% sel) return(NULL)

      vins  <- c()
      cache <- api_manager$vehicles_cache %||% list()

      for (val in sel) {
        if (startsWith(val, "NAME:")) {
          # Pre-connection placeholder — match by customerVehicleName
          target <- sub("^NAME:", "", val)
          for (v in cache) {
            if (identical(v$customerVehicleName, target)) {
              vins <- c(vins, v$vin %||% "")
              break
            }
          }
        } else {
          # Already a VIN
          vins <- c(vins, val)
        }
      }
      if (length(vins) == 0) NULL else unique(vins[nchar(vins) > 0])
    }

    # ── Run Query ─────────────────────────────────────────────────
    observeEvent(input$btn_query, {
      if (!api_manager$is_connected) {
        cat("[TAB2] Query blocked: not connected\n")
        showNotification("Not connected. Go to Tab 1 and test the API connection first.",
                         type = "warning", duration = 5)
        return()
      }

      vins     <- resolve_vins()
      qtype    <- input$query_type
      start_dt <- as.POSIXct(paste(input$start_date, "00:00:00"), tz = "UTC")
      end_dt   <- as.POSIXct(paste(input$end_date,   "23:59:59"), tz = "UTC")
      tfilter  <- if (nchar(input$trigger_filter) == 0) NULL else input$trigger_filter
      latest   <- isTRUE(input$latest_only)

      # Advisory: positions & statuses have a 14-day data retention on the server.
      # We do NOT clamp the date — the user can send any range they like.
      # If data comes back empty for dates > 14 days ago, that is the API's
      # retention limit in action, not a client-side error.
      if (qtype != "vehicles") {
        limit_dt <- as.POSIXct(paste(Sys.Date() - 13, "00:00:00"), tz = "UTC")
        if (start_dt < limit_dt) {
          days_back <- as.integer(difftime(Sys.time(), start_dt, units = "days"))
          cat("[TAB2] Note: start_dt is", days_back, "days ago — beyond 14-day retention\n")
          showNotification(
            paste0("Note: start date is ", days_back, " days ago. The API retains positions/",
                   "statuses for only 14 days — data before that may be empty."),
            type = "warning", duration = 7
          )
        }
      }

      cat("[TAB2] ── Run Query ──────────────────────────\n")
      cat("[TAB2] Query type:", qtype, "\n")
      cat("[TAB2] VINs:", if (is.null(vins)) "ALL" else paste(vins, collapse=", "), "\n")
      cat("[TAB2] Time window:", format(start_dt), "to", format(end_dt), "\n")
      cat("[TAB2] Trigger filter:", tfilter %||% "none", "\n")
      cat("[TAB2] Latest only:", latest, "\n")

      # Populate debug request panel
      n_vins_lbl <- if (is.null(vins)) {
        paste0("ALL (", length(api_manager$vehicles_cache %||% list()), " vehicles — no vin param sent)")
      } else {
        paste0(length(vins), " VIN(s):\n  ", paste(vins, collapse="\n  "))
      }
      rv$debug_request <- paste(c(
        paste0("Endpoint    : /vehicle", switch(qtype,
          vehicles  = "/vehicles",
          positions = "/vehiclepositions",
          statuses  = "/vehiclestatuses",
          everything = "/vehiclepositions + /vehiclestatuses (paginated)", "?")),
        paste0("VIN(s)      : ", n_vins_lbl),
        paste0("Start time  : ", if (latest) "(omitted — latestOnly=true)" else format(start_dt, "%Y-%m-%dT%H:%M:%SZ")),
        paste0("Stop time   : ", if (latest) "(omitted — latestOnly=true)" else format(end_dt,   "%Y-%m-%dT%H:%M:%SZ")),
        paste0("latestOnly  : ", if (latest) "true" else "false"),
        paste0("triggerFilter: ", if (qtype == "everything") "(none — all triggers)" else tfilter %||% "(none)"),
        paste0("contentFilter: ", if (qtype == "everything") "(none — all sections)" else "(as selected)"),
        paste0("additionalContent: ", if (qtype %in% c("everything","statuses")) "VOLVOGROUPACCUMULATED,VOLVOGROUPSNAPSHOT" else "(n/a)"),
        paste0("Sent at     : ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      ), collapse = "\n")

      progress_msg <- if (qtype == "everything")
        "Fetching everything — statuses + positions, paginating… (may take 10–30s)"
      else "Querying Volvo Group API..."

      withProgress(message = progress_msg, value = 0.2, {
        result <- tryCatch({
          if (qtype == "vehicles") {
            api_manager$get_vehicles()
          } else if (qtype == "positions") {
            api_manager$get_vehicle_positions(
              vins = vins, start_time = start_dt, stop_time = end_dt,
              trigger_filter = tfilter, latest_only = latest
            )
          } else if (qtype == "statuses") {
            api_manager$get_vehicle_statuses(
              vins           = vins,
              start_time     = start_dt,
              stop_time      = end_dt,
              trigger_filter = tfilter,
              content        = if (length(input$status_content) > 0) input$status_content else NULL,
              additional     = if (length(input$status_additional) > 0) input$status_additional else NULL,
              latest_only    = latest
            )
          } else {
            # "everything" — both endpoints, no filters, all fields, paginated
            api_manager$get_everything(
              vins       = vins,
              start_time = start_dt,
              stop_time  = end_dt
            )
          }
        }, error = function(e) {
          cat("[TAB2] Exception during query:", e$message, "\n")
          list(success = FALSE, message = e$message, data = NULL)
        })

        setProgress(0.8)
        rv$raw_result <- result
        rv$query_type <- qtype
        rv$query_time <- Sys.time()
        rv$is_demo    <- FALSE

        cat("[TAB2] Query result success:", result$success, "| HTTP:", result$status %||% "?", "\n")

        if (result$success) {

          if (qtype == "everything") {
            # Store both dfs and the raw JSON string
            rv$df_statuses  <- result$statuses_df  %||% data.frame()
            rv$df_positions <- result$positions_df %||% data.frame()
            rv$df           <- result$statuses_df  %||% data.frame()  # primary = statuses
            rv$raw_json_text <- result$raw_json_text %||% ""

            n_s <- nrow(rv$df_statuses  %||% data.frame())
            n_p <- nrow(rv$df_positions %||% data.frame())
            cat("[TAB2] Everything: statuses rows:", n_s, "| positions rows:", n_p, "\n")
            showNotification(
              sprintf("Full dump complete — %d status record(s), %d position record(s).", n_s, n_p),
              type = "message", duration = 6
            )

          } else {
            # Standard single-endpoint result
            rv$df_statuses  <- NULL
            rv$df_positions <- NULL

            # Serialise raw result to JSON for the Raw JSON subtab
            rv$raw_json_text <- tryCatch(
              jsonlite::toJSON(result$data %||% list(), pretty = TRUE, auto_unbox = TRUE),
              error = function(e) paste("Could not serialise:", e$message)
            )

            data_keys <- names(result$data)
            cat("[TAB2] Data keys:", paste(data_keys, collapse=", "), "\n")

            rv$df <- switch(qtype,
              vehicles  = api_manager$vehicles_as_df(result$data$vehicles         %||% list()),
              positions = api_manager$positions_as_df(result$data$vehiclePositions %||% list()),
              statuses  = api_manager$statuses_as_df(result$data$vehicleStatuses  %||% list())
            )
            n_rows <- nrow(rv$df %||% data.frame())
            cat("[TAB2] Data frame rows:", n_rows, "\n")
            if (!is.null(rv$df) && nrow(rv$df) > 0)
              cat("[TAB2] Columns:", paste(names(rv$df), collapse=", "), "\n")

          # ── Connected-services diagnostic for empty results ──────
          # Per the API trigger-to-service mapping table in the docs:
          # MAP drives ALL triggers for BOTH vehiclepositions and vehiclestatuses.
          # LINK is NOT in the spec table — MAP is the only required service.
          if (n_rows == 0 && qtype != "vehicles") {
            cache  <- api_manager$vehicles_cache %||% list()
            vins_q <- if (is.null(vins)) sapply(cache, function(v) v$vin %||% "") else vins

            has_map     <- c()
            missing_map <- c()
            for (v in cache) {
              if (!(v$vin %||% "") %in% vins_q) next
              svcs <- paste(v$volvoGroupVehicle$connectedServices %||% list(), collapse = ", ")
              cat("[TAB2] VIN", v$vin %||% "?", "services:", svcs, "\n")
              nm <- v$customerVehicleName %||% v$vin %||% "?"
              if (grepl("MAP", svcs, ignore.case = TRUE)) has_map <- c(has_map, nm)
              else missing_map <- c(missing_map, nm)
            }
            cat("[TAB2] MAP enabled:", paste(has_map, collapse=", "), "\n")
            cat("[TAB2] MAP missing:", paste(missing_map, collapse=", "), "\n")

            if (length(missing_map) > 0 && length(has_map) == 0) {
              showNotification(paste0(
                "MAP service not found on any queried vehicle: ", paste(missing_map, collapse=", "),
                ". MAP is required for both positions and statuses. Contact Renault Trucks."
              ), type = "error", duration = 14)
            } else if (length(missing_map) > 0) {
              showNotification(paste0(
                "MAP enabled on: ", paste(has_map, collapse=", "),
                " — but missing on: ", paste(missing_map, collapse=", ")
              ), type = "warning", duration = 12)
            } else {
              showNotification(paste0(
                "0 records — all vehicles have MAP listed. Possible causes: ",
                "(1) vehicles not driven in this time window, ",
                "(2) try 'Probe API (latestOnly)' to check if ANY data exists at all, ",
                "(3) MAP may be listed in metadata but not actively transmitting."
              ), type = "warning", duration = 15)
            }
          } else {
            showNotification(
              sprintf("%d record(s) retrieved.", n_rows),
              type = "message", duration = 4
            )
          }
          }  # end else (single-endpoint)

        } else {
          cat("[TAB2] Query FAILED:", result$message, "\n")
          showNotification(paste("Error:", result$message), type = "error", duration = 8)
        }
        setProgress(1)
      })
    })

    # ── Probe API — latestOnly=true, no time window ──────────────
    # Simplest possible query: asks for the most recent record for every
    # vehicle with no time constraint. If this returns empty it means the
    # account has zero stored data — not a time window or parameter issue.
    observeEvent(input$btn_probe, {
      if (!api_manager$is_connected) {
        showNotification("Connect first via Tab 1.", type = "warning", duration = 4)
        return()
      }
      qtype <- input$query_type
      if (qtype == "vehicles") {
        showNotification("Probe runs on positions or statuses only — switch query type first.", type = "warning", duration = 5)
        return()
      }

      cat("[TAB2] ── PROBE (latestOnly=true, no time window) ────────\n")
      cat("[TAB2] No starttime/stoptime, no VIN filter — returns latest record per vehicle\n")

      rv$debug_request <- paste(c(
        "PROBE — latestOnly=true (no starttime/stoptime sent)",
        paste0("Endpoint    : /vehicle/", if (qtype == "positions") "vehiclepositions" else "vehiclestatuses"),
        "VIN(s)      : ALL (no vin param — API returns all vehicles it has data for)",
        "latestOnly  : true",
        paste0("Sent at     : ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      ), collapse = "\n")

      withProgress(message = "Probing API (latestOnly)...", value = 0.3, {
        result <- tryCatch({
          if (qtype == "positions") {
            api_manager$get_vehicle_positions(vins = NULL, latest_only = TRUE)
          } else {
            api_manager$get_vehicle_statuses(
              vins       = NULL,
              content    = c("ACCUMULATED", "SNAPSHOT"),
              additional = c("VOLVOGROUPACCUMULATED", "VOLVOGROUPSNAPSHOT"),
              latest_only = TRUE
            )
          }
        }, error = function(e) {
          list(success = FALSE, message = e$message, data = NULL, status = 0L)
        })
        setProgress(0.8)
        rv$raw_result <- result
        rv$query_type <- qtype
        rv$query_time <- Sys.time()
        rv$is_demo    <- FALSE

        cat("[TAB2] PROBE result:", result$success, "| HTTP:", result$status %||% "?", "\n")

        if (isTRUE(result$success)) {
          rv$df <- switch(qtype,
            positions = api_manager$positions_as_df(result$data$vehiclePositions %||% list()),
            statuses  = api_manager$statuses_as_df(result$data$vehicleStatuses   %||% list())
          )
          n_rows <- nrow(rv$df %||% data.frame())
          cat("[TAB2] PROBE rows:", n_rows, "\n")
          if (n_rows == 0) {
            showNotification(paste0(
              "PROBE returned 0 records for ALL vehicles. ",
              "This means the API account has NO stored ", qtype, " data whatsoever. ",
              "The vehicles have either never transmitted, or connected services ",
              "are not actively collecting data. Check the Debug tab."
            ), type = "error", duration = 15)
          } else {
            showNotification(paste0(
              "\u2713 PROBE found ", n_rows, " record(s)! Data exists — use Run Query with a time window to retrieve full history."
            ), type = "message", duration = 8)
          }
        } else {
          showNotification(paste0("PROBE failed: ", result$message %||% "unknown error"),
                           type = "error", duration = 10)
        }
        setProgress(1)
      })
    })

    # ── Demo data ─────────────────────────────────────────────────
    observeEvent(input$btn_demo, {
      qtype          <- input$query_type
      rv$query_type  <- qtype
      rv$query_time  <- Sys.time()
      rv$is_demo     <- TRUE

      # Use real VINs / names from the JSON we know about
      vin1  <- "VF611AEA3SD000216"; name1 <- "N88GNW"
      vin2  <- "VF611AEA4SD000273"; name2 <- "TA70 WTL"

      if (qtype == "vehicles") {
        rv$df <- data.frame(
          VIN              = c(vin1, vin2),
          Name             = c(name1, name2),
          Registration     = c("N88GNW", "TA70 WTL"),
          Brand            = c("RENAULT TRUCKS", "RENAULT TRUCKS"),
          Type             = c("TRUCK", "TRUCK"),
          Model            = c("T BEV", "T BEV"),
          EmissionLevel    = c("-", "-"),
          FuelTypes        = c("08", "08"),
          ProductionYear   = c(2024L, 2024L),
          ProductionMonth  = c(7L, 10L),
          DeliveryDate     = c("2024-10-07", "2025-04-01"),
          Country          = c("GBR", "GBR"),
          TransportCycle   = c("LONG_DISTANCE", "LONG_DISTANCE"),
          RoadCondition    = c("SMOOTH", "SMOOTH"),
          SpeedLimit_kmh   = c(96, 96),
          ConnectedServices = c(
            "Optifleet Drive, Optifleet Check, Optifleet MAP, Optifleet Safety Service, Optifleet Vehicle Status, Optifleet MISSION",
            "Optifleet Drive, Optifleet Check, Optifleet MAP, Optifleet Safety Service, Optifleet Vehicle Status, Optifleet MISSION"
          ),
          stringsAsFactors = FALSE
        )
      } else if (qtype == "positions") {
        set.seed(42)
        n        <- 40
        base_lat <- c(51.5074, 52.2053)
        base_lon <- c(-0.1278,  0.1218)
        vins_d   <- c(vin1, vin2)
        rows <- lapply(seq_len(n), function(i) {
          vi <- ((i - 1) %% 2) + 1
          data.frame(
            VIN            = vins_d[vi],
            ReceivedAt     = format(Sys.time() - (n - i) * 900, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
            CreatedAt      = format(Sys.time() - (n - i) * 930, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
            Latitude       = base_lat[vi] + cumsum(rnorm(1, 0, 0.008)),
            Longitude      = base_lon[vi] + cumsum(rnorm(1, 0, 0.010)),
            Heading_deg    = round(runif(1, 0, 359), 1),
            Altitude_m     = round(rnorm(1, 25, 10), 1),
            GNSS_Speed_kmh = round(pmax(0, rnorm(1, 62, 18)), 1),
            GNSSStatus     = "GNSS_FIX",
            WheelSpeed_kmh = round(pmax(0, rnorm(1, 60, 18)), 1),
            TachoSpeed_kmh = round(pmax(0, rnorm(1, 61, 18)), 1),
            TriggerType    = sample(c("TIMER", "IGNITION_ON", "IGNITION_OFF"), 1),
            stringsAsFactors = FALSE
          )
        })
        rv$df <- do.call(rbind, rows)
      } else {
        set.seed(99)
        n      <- 30
        vins_d <- c(vin1, vin2)
        rows <- lapply(seq_len(n), function(i) {
          vi <- ((i - 1) %% 2) + 1
          data.frame(
            VIN                   = vins_d[vi],
            ReceivedAt            = format(Sys.time() - (n - i) * 1800, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
            CreatedAt             = format(Sys.time() - (n - i) * 1830, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
            TotalDistance_km      = round(125000 + i * 42, 0),
            EngineHours_h         = round(3200 + i * 1.2, 1),
            TriggerType           = sample(c("TIMER", "IGNITION_OFF"), 1),
            FuelConsumption_l     = round(runif(1, 0, 5), 2),
            HRFuelConsumption_ml  = round(runif(1, 0, 5000), 0),
            Distance_km           = round(runif(1, 0, 250), 1),
            FuelLevel_pct         = round(pmax(5, pmin(100, 80 - i * 1.5 + rnorm(1, 0, 5))), 1),
            CatalystFuelLevel_pct = NA_real_,
            GrossWeight_kg        = round(rnorm(1, 28500, 2000), 0),
            DriverID              = sample(c("DRV001", "DRV002", "-"), 1),
            stringsAsFactors      = FALSE
          )
        })
        rv$df <- do.call(rbind, rows)
      }

      rv$raw_result <- list(success = TRUE, data = list(demo = TRUE),
                            size = as.numeric(object.size(rv$df)))
      showNotification("Demo data loaded.", type = "message", duration = 3)
    })

    # ── Summary metrics ───────────────────────────────────────────
    output$summary_metrics <- renderUI({
      req(!is.null(rv$df))
      df    <- rv$df
      qtype <- rv$query_type

      cards <- if (qtype == "vehicles") {
        ev_count <- sum(grepl("08", df$FuelTypes %||% ""), na.rm = TRUE)
        list(
          metric_card("Total Vehicles", nrow(df)),
          metric_card("EV (fuel 08)",   ev_count,              colour = "#28a745"),
          metric_card("Diesel (04)",    nrow(df) - ev_count,   colour = "#fd7e14"),
          metric_card("Models",         length(unique(df$Model))),
          metric_card("Oldest Year",    min(df$ProductionYear[df$ProductionYear != "-"], na.rm = TRUE))
        )
      } else if (qtype == "positions") {
        valid   <- df[!is.na(df$Latitude) & !is.na(df$Longitude), ]
        avg_spd <- if (nrow(valid) > 0) round(mean(valid$GNSS_Speed_kmh, na.rm = TRUE), 1) else "-"
        fix_pct <- if (nrow(valid) > 0)
          paste0(round(sum(valid$GNSSStatus == "GNSS_FIX", na.rm = TRUE) / nrow(valid) * 100, 0), "%") else "-"
        list(
          metric_card("Position Records", nrow(df)),
          metric_card("Unique VINs",      length(unique(df$VIN))),
          metric_card("Avg Speed km/h",   avg_spd, colour = "#fd7e14"),
          metric_card("GNSS Fix Rate",    fix_pct, colour = "#28a745"),
          metric_card("Records w/ GPS",   nrow(valid))
        )
      } else {
        avg_fuel <- if ("FuelLevel_pct" %in% names(df)) {
          v <- suppressWarnings(as.numeric(df$FuelLevel_pct))
          if (all(is.na(v))) "-" else paste0(round(mean(v, na.rm = TRUE), 1), "%")
        } else "-"
        max_dist <- if ("TotalDistance_km" %in% names(df)) {
          v <- suppressWarnings(as.numeric(df$TotalDistance_km))
          if (all(is.na(v))) "-" else format(max(v, na.rm = TRUE), big.mark = ",")
        } else "-"
        list(
          metric_card("Status Records",    nrow(df)),
          metric_card("Unique VINs",       length(unique(df$VIN))),
          metric_card("Avg Fuel/Charge",   avg_fuel, colour = "#28a745"),
          metric_card("Max Odometer (km)", max_dist, colour = "#fd7e14"),
          metric_card("Avg Engine Hours",  {
            eh <- suppressWarnings(as.numeric(df$EngineHours_h))
            if (all(is.na(eh))) "-" else round(mean(eh, na.rm = TRUE), 0)
          }, colour = "#dc3545")
        )
      }

      demo_tag <- if (isTRUE(rv$is_demo))
        tags$span(class = "wg-demo-badge", "DEMO DATA") else NULL

      div(style = "display:flex;flex-wrap:wrap;gap:10px;padding:6px 0 10px;align-items:center;",
        demo_tag,
        lapply(cards, function(c) div(style = "flex:1;min-width:150px;", HTML(c)))
      )
    })

    output$result_meta_badge <- renderUI({
      req(!is.null(rv$df))
      n  <- nrow(rv$df)
      sz <- format(object.size(rv$df), units = "KB")
      ts <- if (!is.null(rv$query_time)) format(rv$query_time, "%H:%M:%S") else "-"
      tags$span(class = "wg-badge",
        sprintf("%d rows · %s · queried %s", n, sz, ts))
    })

    # ── Data table ─────────────────────────────────────────────────
    output$data_table_ui <- renderUI({
      if (is.null(rv$df) || nrow(rv$df) == 0) {
        # For "everything", also check df_positions
        if (rv$query_type == "everything" &&
            !is.null(rv$df_positions) && nrow(rv$df_positions) > 0) {
          # statuses empty but positions has data — show positions only
          tagList(
            div(style = "padding:6px 0 4px;",
              tags$span(style = "color:#fd7e14;font-weight:600;font-size:13px;",
                tags$i(class="fa fa-map-marker", style="margin-right:6px;"),
                sprintf("Positions — %d records", nrow(rv$df_positions))
              )
            ),
            DT::dataTableOutput(ns("positions_dt"))
          )
        } else {
          div(class = "wg-empty-state",
            tags$i(class = "fa fa-table", style = "font-size:32px;opacity:.3;"),
            tags$p("No data yet. Run a query or load demo data."))
        }
      } else if (rv$query_type == "everything") {
        # Show statuses + positions as two labelled tables
        n_s <- nrow(rv$df_statuses  %||% data.frame())
        n_p <- nrow(rv$df_positions %||% data.frame())
        tagList(
          # Statuses section
          div(style = "padding:8px 0 4px;",
            tags$span(style = "color:#1a9b9b;font-weight:600;font-size:13px;",
              tags$i(class="fa fa-tachometer", style="margin-right:6px;"),
              sprintf("Statuses (telemetry) — %d records · %d columns", n_s,
                      ncol(rv$df_statuses %||% data.frame()))
            )
          ),
          DT::dataTableOutput(ns("statuses_dt")),
          tags$hr(style = "border-color:#b2e0dd;margin:18px 0;"),
          # Positions section
          div(style = "padding:8px 0 4px;",
            tags$span(style = "color:#fd7e14;font-weight:600;font-size:13px;",
              tags$i(class="fa fa-map-marker", style="margin-right:6px;"),
              sprintf("Positions (GPS) — %d records · %d columns", n_p,
                      ncol(rv$df_positions %||% data.frame()))
            )
          ),
          if (n_p > 0) DT::dataTableOutput(ns("positions_dt"))
          else div(style="color:#8899aa;padding:8px;font-size:13px;",
            tags$i(class="fa fa-info-circle", style="margin-right:6px;"),
            "No position records returned for this time window.")
        )
      } else {
        DT::dataTableOutput(ns("main_dt"))
      }
    })

    output$main_dt <- DT::renderDataTable({
      req(!is.null(rv$df), nrow(rv$df) > 0, rv$query_type != "everything")
      .make_dt(rv$df)
    })

    # "Everything" mode — statuses table
    output$statuses_dt <- DT::renderDataTable({
      req(rv$query_type == "everything", !is.null(rv$df_statuses), nrow(rv$df_statuses) > 0)
      .make_dt(rv$df_statuses)
    })

    # "Everything" mode — positions table
    output$positions_dt <- DT::renderDataTable({
      req(!is.null(rv$df_positions), nrow(rv$df_positions) > 0)
      .make_dt(rv$df_positions)
    })

    # Shared DT builder — all columns, export buttons, colour bars
    .make_dt <- function(df) {
      dt <- DT::datatable(
        df,
        options  = list(pageLength = 15, scrollX = TRUE,
                        dom = "Blfrtip", buttons = c("csv", "excel"),
                        columnDefs = list(list(className = "dt-center", targets = "_all"))),
        extensions = "Buttons",
        class    = "wg-dt", rownames = FALSE, escape = FALSE
      )
      # Colour bar on battery / fuel level columns
      for (col in c("BatterySoC_pct", "BatteryPack_pct", "FuelLevel_pct")) {
        if (col %in% names(df))
          dt <- dt |> DT::formatStyle(col,
            background = DT::styleColorBar(c(0, 100), "#00A39A"),
            backgroundSize = "100% 80%", backgroundRepeat = "no-repeat",
            backgroundPosition = "center")
      }
      # Speed colour coding
      if ("GNSS_Speed_kmh" %in% names(df))
        dt <- dt |> DT::formatStyle("GNSS_Speed_kmh",
          color = DT::styleInterval(c(0, 90), c("#888888", "#008A82", "#e74c3c")))
      if ("Speed_kmh" %in% names(df))
        dt <- dt |> DT::formatStyle("Speed_kmh",
          color = DT::styleInterval(c(0, 90), c("#888888", "#008A82", "#e74c3c")))
      # Distance formatting
      if ("TotalDistance_km" %in% names(df))
        dt <- dt |> DT::formatRound("TotalDistance_km", digits = 1)
      dt
    }

    # ── Raw JSON display ──────────────────────────────────────────
    output$raw_json_display <- renderText({
      req(!is.null(rv$raw_json_text))
      rv$raw_json_text
    })

    # ── Download handlers ──────────────────────────────────────────
    # File naming: {date}_{suffix}.{ext}
    # suffix: _metadata | _positions | _statuses | _full_dump
    .dl_suffix <- function(qtype) {
      switch(qtype %||% "data",
        vehicles  = "_metadata",
        positions = "_positions",
        statuses  = "_statuses",
        everything = "_full_dump",
        "_data"
      )
    }
    .dl_date <- function() format(rv$query_time %||% Sys.time(), "%Y-%m-%d")

    # CSV — data table
    output$btn_download_csv <- downloadHandler(
      filename = function() {
        paste0(.dl_date(), .dl_suffix(rv$query_type), ".csv")
      },
      content = function(file) {
        df_out <- if (rv$query_type == "everything") {
          # Full dump: bind statuses + positions side-by-side labelled sections
          s_df <- rv$df_statuses  %||% data.frame()
          p_df <- rv$df_positions %||% data.frame()
          # Write two sections separated by a blank row
          tmp <- tempfile(fileext = ".csv")
          write.csv(s_df, tmp, row.names = FALSE, na = "")
          lines <- readLines(tmp)
          write(c(lines, "", "# POSITIONS", paste(names(p_df), collapse = ",")), file)
          write.table(p_df, file, sep = ",", col.names = FALSE, row.names = FALSE,
                      append = TRUE, na = "", qmethod = "double")
          return(invisible(NULL))
        } else {
          rv$df %||% data.frame()
        }
        write.csv(df_out, file, row.names = FALSE, na = "")
      }
    )

    # JSON — raw API response
    output$btn_download_json <- downloadHandler(
      filename = function() {
        paste0(.dl_date(), .dl_suffix(rv$query_type), ".json")
      },
      content = function(file) {
        writeLines(rv$raw_json_text %||% "{}", file)
      }
    )

    # GeoJSON — AR-compatible FeatureCollection for Quest 3
    output$btn_download_geojson <- downloadHandler(
      filename = function() {
        paste0(.dl_date(), "_positions.geojson")
      },
      content = function(file) {
        df <- rv$df %||% data.frame()
        valid <- df[!is.na(df$Latitude) & !is.na(df$Longitude), ]

        # Derive bounding box / centre from actual data
        if (nrow(valid) == 0) {
          writeLines('{"type":"FeatureCollection","features":[]}', file)
          return(invisible(NULL))
        }
        clat  <- mean(valid$Latitude)
        clon  <- mean(valid$Longitude)
        minlat <- min(valid$Latitude);  maxlat <- max(valid$Latitude)
        minlon <- min(valid$Longitude); maxlon <- max(valid$Longitude)
        pad   <- 0.008  # ~600 m padding around bbox

        # ── Helper: interpolate n points between two coords ────────
        interp_pts <- function(lat1, lon1, lat2, lon2, n = 10) {
          lats <- seq(lat1, lat2, length.out = n)
          lons <- seq(lon1, lon2, length.out = n)
          lapply(seq_len(n), function(i) c(lons[i], lats[i]))
        }

        # ── 1. Primary route — closed loop ~perimeter of bbox, 120 pts
        # Approximates a ring road / main route around the depot area
        corners <- list(
          c(minlon - pad, minlat - pad),
          c(clon,         minlat - pad * 1.5),
          c(maxlon + pad, minlat - pad),
          c(maxlon + pad * 1.5, clat),
          c(maxlon + pad, maxlat + pad),
          c(clon,         maxlat + pad * 1.5),
          c(minlon - pad, maxlat + pad),
          c(minlon - pad * 1.5, clat),
          c(minlon - pad, minlat - pad)   # close the loop
        )
        route_pts <- list()
        for (i in seq_len(length(corners) - 1)) {
          seg <- interp_pts(corners[[i]][2], corners[[i]][1],
                            corners[[i+1]][2], corners[[i+1]][1], n = 16)
          route_pts <- c(route_pts, seg)
        }
        primary_route <- list(
          type = "Feature",
          properties = list(heatmap = TRUE, name = "Primary Depot Loop"),
          geometry   = list(type = "LineString", coordinates = route_pts)
        )

        # ── 2. Buildings — two rectangles representing depot structures
        make_building_poly <- function(lat, lon, dlat = 0.0004, dlon = 0.0006) {
          list(
            type = "Feature",
            properties = list(type = "building"),
            geometry   = list(
              type = "Polygon",
              coordinates = list(list(
                c(lon,       lat),
                c(lon+dlon,  lat),
                c(lon+dlon,  lat+dlat),
                c(lon,       lat+dlat),
                c(lon,       lat)
              ))
            )
          )
        }
        buildings <- list(
          make_building_poly(clat - 0.001, clon - 0.002),
          make_building_poly(clat + 0.0005, clon + 0.001, dlat = 0.0003, dlon = 0.0005)
        )

        # ── 3. Secondary roads — cross-street grid (4 roads)
        make_road <- function(lat1, lon1, lat2, lon2, name) {
          pts <- interp_pts(lat1, lon1, lat2, lon2, n = 20)
          list(
            type = "Feature",
            properties = list(type = "road", name = name),
            geometry   = list(type = "LineString", coordinates = pts)
          )
        }
        roads <- list(
          make_road(clat, minlon - pad, clat, maxlon + pad, "East-West Route"),
          make_road(minlat - pad, clon, maxlat + pad, clon, "North-South Route"),
          make_road(clat - 0.003, clon - 0.003, clat + 0.003, clon + 0.003, "Diagonal Access Road"),
          make_road(clat - 0.003, clon + 0.003, clat + 0.003, clon - 0.003, "Service Road")
        )

        # ── 4. POIs — actual truck position records
        cache <- api_manager$vehicles_cache %||% list()
        get_name <- function(vin) {
          for (v in cache) { if (identical(v$vin, vin)) return(v$customerVehicleName %||% vin) }
          vin
        }

        pois <- lapply(seq_len(nrow(valid)), function(i) {
          row <- valid[i, ]
          spd <- suppressWarnings(as.numeric(row$GNSS_Speed_kmh))
          spd <- if (is.na(spd)) 0 else spd
          list(
            type = "Feature",
            properties = list(
              type        = "poi",
              vin         = row$VIN,
              name        = get_name(row$VIN),
              speed_kmh   = round(spd, 1),
              heading_deg = suppressWarnings(as.numeric(row$Heading_deg)),
              altitude_m  = suppressWarnings(as.numeric(row$Altitude_m)),
              trigger     = row$TriggerType %||% "",
              timestamp   = row$ReceivedAt %||% ""
            ),
            geometry = list(
              type        = "Point",
              coordinates = c(row$Longitude, row$Latitude)
            )
          )
        })

        # ── Assemble FeatureCollection
        fc <- list(
          type     = "FeatureCollection",
          metadata = list(
            generated   = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
            center      = list(latitude = round(clat, 6), longitude = round(clon, 6)),
            vehicle_count = length(unique(valid$VIN)),
            point_count   = nrow(valid),
            canvas      = "4096x2048",
            description = paste0("Welch Group EV fleet positions — ",
                                 format(rv$query_time %||% Sys.time(), "%Y-%m-%d"))
          ),
          features = c(list(primary_route), buildings, roads, pois)
        )

        writeLines(jsonlite::toJSON(fc, pretty = TRUE, auto_unbox = TRUE), file)
      }
    )

    # ── Map ────────────────────────────────────────────────────────
    output$position_map <- leaflet::renderLeaflet({
      req(rv$query_type == "positions", !is.null(rv$df), nrow(rv$df) > 0)
      df  <- rv$df[!is.na(rv$df$Latitude) & !is.na(rv$df$Longitude), ]
      req(nrow(df) > 0)

      vins   <- unique(df$VIN)
      colors <- c("#1a9b9b", "#fd7e14", "#6f42c1", "#28a745")
      vin_col <- setNames(colors[seq_along(vins)], vins)

      # Resolve friendly name from cache for legend
      cache <- api_manager$vehicles_cache %||% list()
      vin_label <- sapply(vins, function(vin) {
        for (v in cache) { if (identical(v$vin, vin)) return(v$customerVehicleName %||% vin) }
        vin
      })

      map <- leaflet::leaflet(df) |>
        leaflet::addProviderTiles("CartoDB.DarkMatter",
          options = leaflet::providerTileOptions(opacity = 0.9)) |>
        leaflet::addProviderTiles("CartoDB.DarkMatterOnlyLabels")

      if (isTRUE(input$map_polyline)) {
        for (vin in vins) {
          sub <- df[df$VIN == vin, ][order(df[df$VIN == vin, ]$ReceivedAt), ]
          if (nrow(sub) >= 2)
            map <- map |> leaflet::addPolylines(
              lng = sub$Longitude, lat = sub$Latitude,
              color = vin_col[[vin]], weight = 2, opacity = 0.7, label = vin_label[[vin]])
        }
      }

      for (vin in vins) {
        sub <- df[df$VIN == vin, ]
        sub$GNSS_Speed_kmh <- suppressWarnings(as.numeric(sub$GNSS_Speed_kmh))
        r   <- pmax(5, pmin(15, ifelse(is.na(sub$GNSS_Speed_kmh), 0, sub$GNSS_Speed_kmh) / 8))
        pop <- sprintf(
          "<b>%s</b> (%s)<br>Speed: %s km/h | Heading: %s°<br>Alt: %s m | %s<br>Time: %s",
          vin_label[[vin]], vin,
          sub$GNSS_Speed_kmh, sub$Heading_deg,
          sub$Altitude_m, sub$GNSSStatus, sub$ReceivedAt
        )
        map <- map |> leaflet::addCircleMarkers(
          lng = sub$Longitude, lat = sub$Latitude,
          radius = r, color = vin_col[[vin]],
          fillColor = vin_col[[vin]], fillOpacity = 0.75, weight = 1,
          popup = lapply(pop, htmltools::HTML),
          label  = vin_label[[vin]], group = vin_label[[vin]]
        )
      }

      map |>
        leaflet::addLegend("bottomright",
          colors = unname(vin_col), labels = unname(vin_label),
          title = "Vehicle", opacity = 0.85) |>
        leaflet::addLayersControl(
          overlayGroups = unname(vin_label),
          options = leaflet::layersControlOptions(collapsed = FALSE))
    })

    # ── Trends ─────────────────────────────────────────────────────
    output$trends_ui <- renderUI({
      req(!is.null(rv$df), nrow(rv$df) > 0)
      if (rv$query_type == "positions") {
        tagList(
          fluidRow(
            column(6, plotly::plotlyOutput(ns("speed_over_time"),  height = "280px")),
            column(6, plotly::plotlyOutput(ns("heading_rose"),     height = "280px"))
          ),
          fluidRow(
            column(12, plotly::plotlyOutput(ns("speed_histogram"), height = "260px"))
          )
        )
      } else if (rv$query_type == "statuses") {
        tagList(
          fluidRow(
            column(6, plotly::plotlyOutput(ns("fuel_trend"),   height = "280px")),
            column(6, plotly::plotlyOutput(ns("dist_trend"),   height = "280px"))
          ),
          fluidRow(
            column(6, plotly::plotlyOutput(ns("engine_trend"), height = "260px")),
            column(6, plotly::plotlyOutput(ns("weight_dist"),  height = "260px"))
          )
        )
      } else {
        tagList(
          fluidRow(
            column(6, plotly::plotlyOutput(ns("fleet_model"),    height = "280px")),
            column(6, plotly::plotlyOutput(ns("fleet_emission"), height = "280px"))
          ),
          fluidRow(
            column(6, plotly::plotlyOutput(ns("fleet_fuel"),     height = "260px")),
            column(6, plotly::plotlyOutput(ns("fleet_delivery"), height = "260px"))
          )
        )
      }
    })

    # helpers
    dark_layout <- function(title) {
      list(
        title = list(text = title, font = list(color = "#008A82")),
        paper_bgcolor = "#ffffff", plot_bgcolor = "#f0faf9",
        legend = list(font = list(color = "#1a2a35")),
        font   = list(color = "#1a2a35")
      )
    }
    dark_axes <- function(xt, yt) {
      list(
        xaxis = list(title = xt, color = "#1a2a35", gridcolor = "#b2e0dd"),
        yaxis = list(title = yt, color = "#1a2a35", gridcolor = "#b2e0dd")
      )
    }

    output$speed_over_time <- plotly::renderPlotly({
      req(rv$query_type == "positions", !is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df; df$ts <- as.POSIXct(df$ReceivedAt, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      df <- df[!is.na(df$ts), ]
      plotly::plot_ly(df, x = ~ts, y = ~GNSS_Speed_kmh, color = ~VIN,
                      type = "scatter", mode = "lines+markers",
                      marker = list(size = 5)) |>
        plotly::layout(!!!dark_layout("Speed Over Time (km/h)"),
                       !!!dark_axes("Time (UTC)", "Speed km/h"))
    })

    output$heading_rose <- plotly::renderPlotly({
      req(rv$query_type == "positions", !is.null(rv$df), nrow(rv$df) > 0)
      df  <- rv$df[!is.na(rv$df$Heading_deg), ]
      bins <- cut(df$Heading_deg, breaks = seq(0, 360, by = 22.5), include.lowest = TRUE)
      tbl  <- as.data.frame(table(bins))
      plotly::plot_ly(tbl, r = ~Freq, theta = ~bins, type = "barpolar",
                      marker = list(color = "#008A82")) |>
        plotly::layout(!!!dark_layout("Heading Distribution (degrees)"),
                       polar = list(bgcolor = "#f0faf9",
                                    radialaxis  = list(color = "#1a2a35"),
                                    angularaxis = list(color = "#1a2a35")))
    })

    output$speed_histogram <- plotly::renderPlotly({
      req(rv$query_type == "positions", !is.null(rv$df), nrow(rv$df) > 0)
      plotly::plot_ly(rv$df, x = ~GNSS_Speed_kmh, color = ~VIN,
                      type = "histogram", nbinsx = 20, opacity = 0.75) |>
        plotly::layout(!!!dark_layout("Speed Distribution"), barmode = "overlay",
                       !!!dark_axes("Speed km/h", "Count"))
    })

    output$fuel_trend <- plotly::renderPlotly({
      req(rv$query_type == "statuses", !is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df
      df$FuelLevel_pct <- suppressWarnings(as.numeric(df$FuelLevel_pct))
      df$ts <- as.POSIXct(df$ReceivedAt, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      df <- df[!is.na(df$ts) & !is.na(df$FuelLevel_pct), ]
      plotly::plot_ly(df, x = ~ts, y = ~FuelLevel_pct, color = ~VIN,
                      type = "scatter", mode = "lines+markers",
                      fill = "tozeroy", alpha = 0.35) |>
        plotly::layout(!!!dark_layout("Battery / Fuel Level (%)"),
                       !!!dark_axes("Time (UTC)", "Level (%)"),
                       yaxis = list(range = c(0, 105), color = "#1a2a35", gridcolor = "#b2e0dd"))
    })

    output$dist_trend <- plotly::renderPlotly({
      req(rv$query_type == "statuses", !is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df
      df$TotalDistance_km <- suppressWarnings(as.numeric(df$TotalDistance_km))
      df$ts <- as.POSIXct(df$ReceivedAt, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      df <- df[!is.na(df$ts) & !is.na(df$TotalDistance_km), ]
      plotly::plot_ly(df, x = ~ts, y = ~TotalDistance_km, color = ~VIN,
                      type = "scatter", mode = "lines") |>
        plotly::layout(!!!dark_layout("Odometer (Total km)"),
                       !!!dark_axes("Time (UTC)", "km"))
    })

    output$engine_trend <- plotly::renderPlotly({
      req(rv$query_type == "statuses", !is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df
      df$EngineHours_h <- suppressWarnings(as.numeric(df$EngineHours_h))
      df$ts <- as.POSIXct(df$ReceivedAt, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      df <- df[!is.na(df$ts) & !is.na(df$EngineHours_h), ]
      plotly::plot_ly(df, x = ~ts, y = ~EngineHours_h, color = ~VIN, type = "bar") |>
        plotly::layout(!!!dark_layout("Engine / Drive Hours"), barmode = "group",
                       !!!dark_axes("Time (UTC)", "Hours"))
    })

    output$weight_dist <- plotly::renderPlotly({
      req(rv$query_type == "statuses", !is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df[!is.na(rv$df$GrossWeight_kg), ]
      plotly::plot_ly(df, x = ~GrossWeight_kg, color = ~VIN,
                      type = "histogram", nbinsx = 15, opacity = 0.8) |>
        plotly::layout(!!!dark_layout("Gross Combined Weight (kg)"), barmode = "overlay",
                       !!!dark_axes("Weight (kg)", "Frequency"))
    })

    # Vehicle-list charts
    output$fleet_model <- plotly::renderPlotly({
      req(rv$query_type == "vehicles", !is.null(rv$df), nrow(rv$df) > 0)
      tbl <- as.data.frame(table(rv$df$Model))
      tbl <- tbl[order(-tbl$Freq), ]
      plotly::plot_ly(tbl, x = ~reorder(Var1, -Freq), y = ~Freq, type = "bar",
                      marker = list(color = "#008A82")) |>
        plotly::layout(!!!dark_layout("Fleet by Model"), !!!dark_axes("Model", "Count"))
    })

    output$fleet_emission <- plotly::renderPlotly({
      req(rv$query_type == "vehicles", !is.null(rv$df), nrow(rv$df) > 0)
      tbl <- as.data.frame(table(rv$df$EmissionLevel))
      plotly::plot_ly(tbl, labels = ~Var1, values = ~Freq, type = "pie",
                      textinfo = "label+percent",
                      marker = list(colors = c("#1a9b9b", "#fd7e14", "#6f42c1", "#28a745"))) |>
        plotly::layout(!!!dark_layout("Emission Level"), paper_bgcolor = "#ffffff",
                       legend = list(font = list(color = "#1a2a35")),
                       font   = list(color = "#1a2a35"))
    })

    output$fleet_fuel <- plotly::renderPlotly({
      req(rv$query_type == "vehicles", !is.null(rv$df), nrow(rv$df) > 0)
      tbl <- as.data.frame(table(rv$df$FuelTypes))
      names(tbl) <- c("FuelType", "Count")
      tbl$Label <- ifelse(tbl$FuelType == "08", "08 – Electric",
                   ifelse(tbl$FuelType == "04", "04 – Diesel", tbl$FuelType))
      plotly::plot_ly(tbl, x = ~Label, y = ~Count, type = "bar",
                      marker = list(color = c("#28a745", "#fd7e14")[seq_len(nrow(tbl))])) |>
        plotly::layout(!!!dark_layout("Fleet by Fuel Type"), !!!dark_axes("Fuel Type", "Count"))
    })

    output$fleet_delivery <- plotly::renderPlotly({
      req(rv$query_type == "vehicles", !is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df[rv$df$DeliveryDate != "-", ]
      df$Year <- as.integer(substr(df$DeliveryDate, 1, 4))
      df <- df[!is.na(df$Year), ]
      tbl <- as.data.frame(table(df$Year))
      plotly::plot_ly(tbl, x = ~Var1, y = ~Freq, type = "bar",
                      marker = list(color = "#008A82")) |>
        plotly::layout(!!!dark_layout("Deliveries by Year"), !!!dark_axes("Year", "Vehicles"))
    })

    # ── Statistics & Metadata ──────────────────────────────────────
    output$statistics_ui <- renderUI({
      req(!is.null(rv$df), nrow(rv$df) > 0)
      df    <- rv$df
      qtype <- rv$query_type
      n     <- nrow(df)
      sz    <- format(object.size(df), units = "KB")

      num_cols <- names(df)[sapply(df, is.numeric)]
      smry <- if (length(num_cols) > 0) {
        do.call(rbind, lapply(num_cols, function(col) {
          x <- df[[col]][!is.na(df[[col]])]
          if (length(x) == 0) return(NULL)
          data.frame(Field = col, N = length(x), Missing = sum(is.na(df[[col]])),
                     Min = round(min(x), 3), Mean = round(mean(x), 3),
                     Median = round(median(x), 3), Max = round(max(x), 3),
                     SD = round(sd(x), 3), stringsAsFactors = FALSE)
        }))
      } else data.frame(Message = "No numeric columns.")

      geo_panel <- if (qtype == "positions") {
        valid <- df[!is.na(df$Latitude) & !is.na(df$Longitude), ]
        if (nrow(valid) > 0) {
          dlat   <- (max(valid$Latitude)  - min(valid$Latitude))  * pi / 180
          dlon   <- (max(valid$Longitude) - min(valid$Longitude)) * pi / 180
          mlat   <- mean(valid$Latitude) * pi / 180
          a      <- sin(dlat/2)^2 + cos(mlat)^2 * sin(dlon/2)^2
          diag_km <- 6371 * 2 * atan2(sqrt(a), sqrt(1 - a))
          div(class = "wg-geo-box",
            tags$h5("Geographic Extent", style = "color:#006b63;margin-bottom:10px;"),
            fluidRow(
              column(4, HTML(metric_card("Lat Range",      sprintf("%.4f to %.4f", min(valid$Latitude),  max(valid$Latitude)),  "#6f42c1"))),
              column(4, HTML(metric_card("Lon Range",      sprintf("%.4f to %.4f", min(valid$Longitude), max(valid$Longitude)), "#6f42c1"))),
              column(4, HTML(metric_card("Bbox Diagonal",  sprintf("~%.1f km", diag_km), "#1a9b9b")))
            ),
            fluidRow(
              column(4, HTML(metric_card("GPS Records",    nrow(valid)))),
              column(4, HTML(metric_card("GNSS Fix Rate",
                paste0(round(sum(valid$GNSSStatus == "GNSS_FIX", na.rm = TRUE) / nrow(valid) * 100, 0), "%")))),
              column(4, HTML(metric_card("Unique VINs",    length(unique(valid$VIN)))))
            )
          )
        }
      } else NULL

      tagList(
        div(class = "wg-stat-section",
          tags$h5("Dataset Metadata", style = "color:#006b63;margin-bottom:10px;"),
          fluidRow(
            column(3, HTML(metric_card("Total Records", n))),
            column(3, HTML(metric_card("Columns",       ncol(df)))),
            column(3, HTML(metric_card("Memory Size",   sz))),
            column(3, HTML(metric_card("Query Type",    toupper(qtype), colour = "#fd7e14")))
          ),
          if (isTRUE(rv$is_demo))
            div(class = "wg-demo-notice",
              tags$i(class = "fa fa-flask"), " Demo data – connect to API for live data.")
        ),
        if (!is.null(geo_panel)) div(class = "wg-stat-section", geo_panel),
        div(class = "wg-stat-section",
          tags$h5("Numeric Field Statistics", style = "color:#006b63;margin-bottom:10px;"),
          if (!is.null(smry) && nrow(smry) > 0 && "Field" %in% names(smry))
            DT::dataTableOutput(ns("stats_dt"))
          else tags$p("No numeric fields.", style = "color:#5a7a77;")
        ),
        div(class = "wg-stat-section",
          tags$h5("Column Types", style = "color:#006b63;margin-bottom:10px;"),
          div(style = "display:flex;flex-wrap:wrap;gap:8px;",
            lapply(names(df), function(col) {
              dtype  <- class(df[[col]])[1]
              colour <- switch(dtype, "numeric" = "#1a9b9b", "integer" = "#17a2b8",
                               "character" = "#fd7e14", "logical" = "#6f42c1", "#6c8a87")
              HTML(sprintf(
                '<div style="background:#ffffff;border:1px solid %s;padding:4px 10px;
                 border-radius:4px;font-size:12px;">
                 <span style="color:%s;font-weight:600;">%s</span>
                 <span style="color:#5a7a77;"> %s</span></div>',
                colour, colour, col, dtype))
            })
          )
        )
      )
    })

    output$stats_dt <- DT::renderDataTable({
      req(!is.null(rv$df), nrow(rv$df) > 0)
      num_cols <- names(rv$df)[sapply(rv$df, is.numeric)]
      if (length(num_cols) == 0) return(data.frame())
      smry <- do.call(rbind, lapply(num_cols, function(col) {
        x <- rv$df[[col]][!is.na(rv$df[[col]])]
        if (length(x) == 0) return(NULL)
        data.frame(Field = col, N = length(x), Missing = sum(is.na(rv$df[[col]])),
                   Min = round(min(x), 3), Mean = round(mean(x), 3),
                   Median = round(median(x), 3), Max = round(max(x), 3),
                   SD = round(sd(x), 3), stringsAsFactors = FALSE)
      }))
      DT::datatable(smry, options = list(pageLength = 20, dom = "t"),
                    class = "wg-dt", rownames = FALSE)
    })

    # ── Debug: last request sent ─────────────────────────────────
    output$debug_request <- renderText({
      req(!is.null(rv$debug_request))
      rv$debug_request
    })

    # ── Debug: response summary ───────────────────────────────────
    output$debug_response <- renderText({
      req(!is.null(rv$raw_result))
      res    <- rv$raw_result
      qtype  <- rv$query_type %||% "?"
      status <- res$status %||% "?"
      ok     <- isTRUE(res$success)

      # Count records in the response
      n_recs <- tryCatch({
        dat <- res$data
        key <- switch(qtype,
          vehicles  = "vehicles",
          positions = "vehiclePositions",
          statuses  = "vehicleStatuses",
          NULL
        )
        if (!is.null(key) && !is.null(dat[[key]])) length(dat[[key]]) else 0L
      }, error = function(e) 0L)

      lines <- c(
        paste0("Status      : ", status, if (ok) " ✓ OK" else " ✗ FAILED"),
        paste0("Query type  : ", qtype),
        paste0("Records ret.: ", n_recs),
        paste0("Rows in df  : ", nrow(rv$df %||% data.frame())),
        paste0("Query time  : ", format(rv$query_time %||% Sys.time(), "%Y-%m-%d %H:%M:%S")),
        paste0("Is demo     : ", isTRUE(rv$is_demo))
      )
      if (!ok && !is.null(res$message)) {
        lines <- c(lines, "", paste0("Error msg   : ", res$message))
      }
      if (!is.null(res$data) && !is.null(res$data$moreDataAvailable)) {
        lines <- c(lines, paste0("More data?  : ", res$data$moreDataAvailable))
      }
      paste(lines, collapse = "\n")
    })

    # ── Debug: connected services per queried vehicle ─────────────
    output$debug_services <- renderText({
      cache  <- api_manager$vehicles_cache %||% list()
      if (length(cache) == 0) return("No vehicle cache — connect first via Tab 1.")

      qtype    <- rv$query_type %||% input$query_type
      vins_sel <- isolate(resolve_vins())  # NULL = ALL

      # Determine which vehicles to show
      show_vins <- if (is.null(vins_sel)) {
        sapply(cache, function(v) v$vin %||% "")
      } else {
        vins_sel
      }

      required_svc <- switch(qtype %||% "positions",
        positions = "MAP",
        statuses  = "MAP",  # LINK is NOT in the spec table — MAP covers all triggers
        NULL   # vehicles — no service requirement
      )

      lines <- c()
      for (v in cache) {
        vin <- v$vin %||% ""
        if (!vin %in% show_vins) next

        name  <- v$customerVehicleName %||% vin
        vgv   <- v$volvoGroupVehicle %||% list()
        svcs  <- paste(vgv$connectedServices %||% list(), collapse = ", ")
        if (nchar(svcs) == 0) svcs <- "(none)"

        # Check if required service present
        status_flag <- ""
        if (!is.null(required_svc)) {
          has_svc <- grepl(required_svc, svcs, ignore.case = TRUE)
          status_flag <- if (has_svc) "  ✓" else paste0("  ✗ MISSING ", required_svc, " — NO DATA EXPECTED")
        }

        lines <- c(lines, paste0(name, " [", vin, "]"))
        lines <- c(lines, paste0("  Services: ", svcs, status_flag))
        lines <- c(lines, "")
      }

      if (length(lines) == 0) return("No matching vehicles in cache.")

      header <- if (!is.null(required_svc)) {
        paste0("Required for ", qtype, ": ", required_svc, " service\n",
               paste(rep("-", 60), collapse=""), "\n")
      } else {
        paste0(paste(rep("-", 60), collapse=""), "\n")
      }
      paste0(header, paste(lines, collapse = "\n"))
    })

    # ── Debug: raw JSON ───────────────────────────────────────────
    output$raw_json <- renderText({
      req(!is.null(rv$raw_result))
      trunc <- rv$raw_result$data
      if (is.list(trunc)) {
        for (nm in names(trunc)) {
          if (is.list(trunc[[nm]]) && length(trunc[[nm]]) > 50)
            trunc[[nm]] <- trunc[[nm]][1:50]
        }
      }
      jsonlite::toJSON(trunc, pretty = TRUE, auto_unbox = TRUE)
    })
  })
}
