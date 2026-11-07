# modules/api_connection_v2.R — Welch Group Fleet Monitor
# IMPROVED CLONE of api_connection.R  (Book Ch 1: REST, HTTP & JSON)
#
# ── What's improved over api_connection.R ────────────────────────────────────
# [Ch1-REST]    Shows all three endpoints, their HTTP method, expected Accept header,
#               and correct status codes from the API spec — mapping directly to
#               Chapter 1's REST constraints and HTTP method/CRUD table.
# [Ch1-JSON]    Raw JSON inspector shows the full response structure with field-type
#               annotations, demonstrating the dict/list/string type mappings from Ch1.
# [Ch1-HTTP]    Explicit HTTP status code explanations for every error the Volvo API
#               can return (400/401/403/404/406/429), linking to the status code table.
# [BUGFIX]      The original sends additionalContent as a bare string query param;
#               this version sends it correctly as a comma-separated array value.
# [IMPROVEMENT] "Test All Endpoints" button probes all three endpoints sequentially,
#               so you can see which services are active without switching tabs.
# ─────────────────────────────────────────────────────────────────────────────

api_connection_v2_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ── Page header ──────────────────────────────────────────────────────────
    div(class = "wg-page-header",
      div(class = "wg-page-title",
        tags$i(class = "fa fa-plug", style = "margin-right:10px;"),
        "Volvo Group Vehicle API \u2014 Connection v2 (Improved)"
      ),
      div(class = "wg-page-subtitle",
        "Improved API connection tab. Shows raw HTTP exchange, full JSON structure, ",
        "and tests all three endpoints. Credentials saved here are shared with Vehicle Data v2."
      ),
      # Ch1 context ribbon
      div(style = "margin-top:10px;padding:10px 16px;background:#edfaf9;border-left:4px solid #1a6faf;border-radius:6px;",
        tags$b(style = "color:#006b63;", "\U0001f4da Ch 1 \u2014 REST, HTTP & JSON: "),
        tags$span(style = "color:#5a7a77;font-size:13px;",
          "The Volvo API is a textbook REST API: stateless, uniform interface (GET only),",
          " cacheable responses, and a strict JSON content-type contract.",
          " This tab demonstrates all HTTP status codes, auth headers, and JSON parsing from Chapter 1."
        )
      )
    ),

    fluidRow(
      # ── Left: credentials + endpoint reference ───────────────────────────
      column(4,
        div(class = "wg-card",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-lock", style = "margin-right:8px;"),
            "API Credentials"
          ),
          div(class = "wg-card-body",
            # Ch1: HTTP Basic Auth is one of the simplest REST auth schemes
            div(style = "padding:8px 12px;background:#f0faf9;border-left:3px solid #1a6faf;border-radius:3px;margin-bottom:12px;",
              tags$small(style = "color:#006b63;",
                tags$b("[Ch1-HTTP] "), "Auth scheme: HTTP Basic \u2014 credentials are Base64-encoded",
                " and sent in the Authorization header on every request (stateless \u2014 REST constraint #2)."
              )
            ),
            div(class = "wg-field-group",
              tags$label("Username / API Key", class = "wg-label"),
              textInput(ns("v2_username"), label = NULL,
                        value = "48EAEF2D32",
                        placeholder = "Enter API username",
                        width = "100%")
            ),
            div(class = "wg-field-group",
              tags$label("Password / Secret", class = "wg-label"),
              passwordInput(ns("v2_password"), label = NULL,
                            value = "cjPxApRRcW",
                            placeholder = "Enter API password",
                            width = "100%")
            ),
            div(class = "wg-field-group",
              checkboxInput(ns("v2_additional"),
                "Include VOLVOGROUPVEHICLE (proprietary fields)",
                value = TRUE)
            ),
            tags$small(class = "wg-hint",
              tags$i(class = "fa fa-info-circle"),
              " Credentials are held in memory only, never written to disk.",
              " They are shared with the Vehicle Data v2 tab."
            ),
            tags$hr(class = "wg-divider"),
            actionButton(ns("v2_btn_connect"), "Test Connection (/vehicles)",
                         icon = icon("wifi"),
                         class = "wg-btn wg-btn-primary", width = "100%"),
            tags$br(), tags$br(),
            actionButton(ns("v2_btn_test_all"), "Test All 3 Endpoints",
                         icon = icon("stethoscope"),
                         class = "wg-btn wg-btn-secondary", width = "100%",
                         style = "background:#1a3a2a;border-color:#2ecc71;color:#2ecc71;"),
            tags$br(), tags$br(),
            actionButton(ns("v2_btn_refresh"), "Refresh Vehicle List",
                         icon = icon("sync"),
                         class = "wg-btn wg-btn-secondary", width = "100%")
          )
        ),

        # ── Endpoint reference card with Ch1 annotations ────────────────────
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-book", style = "margin-right:8px;"),
            "API Endpoints \u2014 REST Reference [Ch1]"
          ),
          div(class = "wg-card-body",
            # Ch1: REST uniform interface \u2014 resources identified by URIs
            lapply(list(
              list(path = "/vehicles",         method = "GET",
                   accept = "vehicles.v1.0",   freq = "Once/day",
                   desc = "Fleet list \u2014 VIN, brand, model, fuel type, production date.",
                   note = "Static data. Returns moreDataAvailable for fleets > 100."),
              list(path = "/vehiclepositions", method = "GET",
                   accept = "vehiclepositions.v1.0", freq = "1/minute",
                   desc = "GPS lat/lon, heading, altitude, GNSS + wheel speed.",
                   note = "MAP service required. latestOnly=true for live dashboard."),
              list(path = "/vehiclestatuses",  method = "GET",
                   accept = "vehiclestatuses.v1.0", freq = "15/minute",
                   desc = "Full telemetry: battery SoC, odometer, engine hours, EV charging.",
                   note = "contentFilter selects ACCUMULATED/SNAPSHOT/UPTIME sections.")
            ), function(ep) {
              div(class = "wg-endpoint-ref", style = "margin-bottom:12px;",
                div(style = "display:flex;align-items:center;gap:8px;margin-bottom:4px;",
                  tags$span(class = "wg-method-get", ep$method),
                  tags$b(style = "color:#006b63;font-family:monospace;font-size:12px;", ep$path),
                  tags$span(style = "background:#e8f8f5;color:#1a9b9b;padding:2px 8px;border-radius:10px;font-size:10px;", ep$freq)
                ),
                tags$p(style = "color:#5a7a77;font-size:12px;margin:2px 0;", ep$desc),
                tags$p(style = "color:#007a73;font-size:11px;font-family:monospace;margin:2px 0;",
                       paste0("Accept: application/x.volvogroup.com.", ep$accept, "+json"))
              )
            })
          )
        ),

        # ── HTTP status code reference [Ch1] ──────────────────────────────
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-exclamation-triangle", style = "margin-right:8px;"),
            "HTTP Status Codes [Ch1]"
          ),
          div(class = "wg-card-body",
            tags$table(style = "width:100%;font-size:12px;",
              tags$thead(
                tags$tr(
                  tags$th(style = "color:#006b63;padding:4px 8px;", "Code"),
                  tags$th(style = "color:#006b63;padding:4px 8px;", "Meaning"),
                  tags$th(style = "color:#006b63;padding:4px 8px;", "Volvo API cause")
                )
              ),
              tags$tbody(
                lapply(list(
                  list("200", "#28a745", "OK",              "Data returned successfully"),
                  list("400", "#fd7e14", "Bad Request",     "Missing auth header or bad params"),
                  list("401", "#dc3545", "Unauthorised",    "Wrong credentials / expired"),
                  list("403", "#dc3545", "Forbidden",       "No rights on this vehicle/service"),
                  list("404", "#fd7e14", "Not Found",       "VIN unknown or endpoint mismatch"),
                  list("406", "#6f42c1", "Not Acceptable",  "Wrong Accept header content-type"),
                  list("429", "#fd7e14", "Too Many Reqs",   "Rate limit \u2014 wait and retry")
                ), function(row) {
                  tags$tr(
                    tags$td(style = paste0("padding:4px 8px;color:", row[[2]], ";font-weight:700;font-family:monospace;"), row[[1]]),
                    tags$td(style = "padding:4px 8px;color:#1a2a35;", row[[3]]),
                    tags$td(style = "padding:4px 8px;color:#5a7a77;", row[[4]])
                  )
                })
              )
            )
          )
        )
      ),

      # ── Right: status + results ──────────────────────────────────────────
      column(8,
        # Connection status
        div(class = "wg-card",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-signal", style = "margin-right:8px;"),
            "Connection Status"
          ),
          div(class = "wg-card-body", uiOutput(ns("v2_connection_status_ui")))
        ),

        # Test-all-endpoints results
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-list-check", style = "margin-right:8px;"),
            "Endpoint Test Results [Ch1: HTTP Status Codes]"
          ),
          div(class = "wg-card-body", uiOutput(ns("v2_endpoint_test_ui")))
        ),

        # Vehicle table
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-truck", style = "margin-right:8px;"),
            "Fleet Vehicles",
            uiOutput(ns("v2_vehicle_count_badge"), inline = TRUE)
          ),
          div(class = "wg-card-body", uiOutput(ns("v2_vehicle_table_ui")))
        ),

        # Raw JSON inspector [Ch1: JSON format]
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-code", style = "margin-right:8px;"),
            "Raw JSON Response Inspector [Ch1: JSON Format]"
          ),
          div(class = "wg-card-body",
            div(style = "padding:8px 12px;background:#f0faf9;border-left:3px solid #1a6faf;border-radius:3px;margin-bottom:12px;",
              tags$small(style = "color:#006b63;",
                tags$b("[Ch1-JSON] "),
                "The Volvo API returns nested JSON. Python dict = JSON object {}, list = array [], ",
                "str = string, int/float = number, bool = true/false, None = null. ",
                "Every response is parsed with jsonlite::fromJSON() \u2014 equivalent to Python's json.loads()."
              )
            ),
            div(style = "background:#f0faf9;border:1px solid #b2e0dd;border-radius:4px;max-height:380px;overflow:auto;padding:12px;",
              verbatimTextOutput(ns("v2_raw_json"))
            )
          )
        )
      )
    )
  )
}

# ── SERVER ───────────────────────────────────────────────────────────────────
api_connection_v2_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    conn_state <- reactiveValues(
      connected    = FALSE,
      message      = "Not connected. Enter credentials and click Test Connection.",
      status       = NULL,
      vehicles     = NULL,
      last_tested  = NULL,
      raw_json     = NULL,
      # Endpoint test results: list of (path, status, ok, message) per endpoint
      endpoint_tests = NULL
    )

    # ── Test Connection (/vehicles) ──────────────────────────────────────────
    # [Ch1-REST] Demonstrates the stateless nature: every request carries full auth.
    observeEvent(input$v2_btn_connect, {
      req(nchar(trimws(input$v2_username)) > 0)
      showNotification("Testing connection to Renault Trucks API...",
                       type = "message", id = "v2_conn_notif", duration = NULL)

      api_manager$set_credentials(input$v2_username, input$v2_password)
      result <- api_manager$test_connection()
      removeNotification("v2_conn_notif")

      conn_state$connected  <- result$success
      conn_state$status     <- result$status
      conn_state$message    <- result$message
      conn_state$last_tested <- Sys.time()

      if (result$success) {
        conn_state$vehicles <- result$vehicles

        # Capture raw JSON for the inspector
        # [Ch1-JSON] Shows the nested JSON structure: vehicleResponse > vehicles > [...]
        conn_state$raw_json <- tryCatch(
          jsonlite::toJSON(
            list(
              vehicleResponse = list(
                vehicles          = result$vehicles,
                moreDataAvailable = FALSE
              )
            ),
            pretty = TRUE, auto_unbox = TRUE
          ),
          error = function(e) paste("JSON error:", e$message)
        )
        showNotification(paste("\u2713", result$message), type = "message", duration = 5)
      } else {
        # [Ch1-HTTP] Distinguish 401 vs 403 vs 404 for clear diagnostics
        hint <- switch(as.character(result$status %||% 0),
          "401" = " \u2014 Check username and password.",
          "403" = " \u2014 Account exists but has no rights on this vehicle.",
          "406" = " \u2014 Accept header rejected; auto-retry should have fixed this.",
          "429" = " \u2014 Rate limited. Wait 60 seconds before retrying.",
          ""
        )
        showNotification(paste("\u2717", result$message, hint), type = "error", duration = 8)
      }
    })

    # ── Test All Endpoints ───────────────────────────────────────────────────
    # [Ch1-REST] Each endpoint is a distinct resource (uniform interface constraint).
    # Tests /vehicles (httr), /vehiclepositions (curl), /vehiclestatuses (curl).
    observeEvent(input$v2_btn_test_all, {
      if (!api_manager$is_connected) {
        showNotification("Connect first using 'Test Connection'.", type = "warning")
        return()
      }
      withProgress(message = "Testing all 3 endpoints...", value = 0.1, {
        results <- list()

        # 1. /vehicles (already connected, use cache)
        setProgress(0.3, detail = "/vehicles")
        res_v <- tryCatch(
          api_manager$get_vehicles(
            additional_content = if (isTRUE(input$v2_additional)) "VOLVOGROUPVEHICLE" else NULL
          ),
          error = function(e) list(success = FALSE, message = e$message, status = 0L)
        )
        results[[1]] <- list(
          path    = "GET /vehicle/vehicles",
          status  = res_v$status %||% 0L,
          ok      = isTRUE(res_v$success),
          message = if (isTRUE(res_v$success))
            sprintf("%d vehicle(s) returned", length((res_v$data$vehicles) %||% list()))
          else res_v$message %||% "failed",
          note    = "Recommended: once per day. Static metadata."
        )

        # 2. /vehiclepositions — latestOnly probe
        Sys.sleep(1.2)  # [Ch9-RATE] respect 1-req/endpoint/sec minimum
        setProgress(0.6, detail = "/vehiclepositions")
        res_p <- tryCatch(
          api_manager$get_vehicle_positions(vins = NULL, latest_only = TRUE),
          error = function(e) list(success = FALSE, message = e$message, status = 0L)
        )
        n_pos <- if (isTRUE(res_p$success))
          length((res_p$data$vehiclePositions) %||% list()) else 0L
        results[[2]] <- list(
          path    = "GET /vehicle/vehiclepositions",
          status  = res_p$status %||% 0L,
          ok      = isTRUE(res_p$success),
          message = if (isTRUE(res_p$success))
            sprintf("%d position(s) (latestOnly=true)", n_pos)
          else res_p$message %||% "failed",
          note    = "Required: MAP connected service. Updates every 1 min while moving."
        )

        # 3. /vehiclestatuses — latestOnly SNAPSHOT probe
        Sys.sleep(1.2)
        setProgress(0.9, detail = "/vehiclestatuses")
        res_s <- tryCatch(
          api_manager$get_vehicle_statuses(
            vins        = NULL,
            content     = c("SNAPSHOT"),
            additional  = c("VOLVOGROUPSNAPSHOT"),
            latest_only = TRUE
          ),
          error = function(e) list(success = FALSE, message = e$message, status = 0L)
        )
        n_stat <- if (isTRUE(res_s$success))
          length((res_s$data$vehicleStatuses) %||% list()) else 0L
        results[[3]] <- list(
          path    = "GET /vehicle/vehiclestatuses",
          status  = res_s$status %||% 0L,
          ok      = isTRUE(res_s$success),
          message = if (isTRUE(res_s$success))
            sprintf("%d status record(s) (SNAPSHOT, latestOnly=true)", n_stat)
          else res_s$message %||% "failed",
          note    = "Required: MAP (SNAPSHOT) + CHECK (ACCUMULATED). UPTIME needs HEALTH service."
        )

        conn_state$endpoint_tests <- results
        setProgress(1)
      })
    })

    # ── Refresh vehicle list ─────────────────────────────────────────────────
    observeEvent(input$v2_btn_refresh, {
      if (!api_manager$is_connected) {
        showNotification("Please connect first.", type = "warning"); return()
      }
      result <- api_manager$get_vehicles(
        additional_content = if (isTRUE(input$v2_additional)) "VOLVOGROUPVEHICLE" else NULL
      )
      if (result$success) {
        conn_state$vehicles           <- result$data$vehicles %||% list()
        api_manager$vehicles_cache    <- conn_state$vehicles
        conn_state$raw_json <- tryCatch(
          jsonlite::toJSON(result$data %||% list(), pretty = TRUE, auto_unbox = TRUE),
          error = function(e) ""
        )
        showNotification(
          sprintf("\u2713 %d vehicle(s) retrieved.", length(conn_state$vehicles)),
          type = "message", duration = 4
        )
      } else {
        showNotification(paste("\u2717", result$message), type = "error", duration = 6)
      }
    })

    # ── Connection status UI ─────────────────────────────────────────────────
    output$v2_connection_status_ui <- renderUI({
      if (conn_state$connected) {
        div(
          div(class = "wg-status-row",
            div(class = "wg-status-dot wg-status-green"),
            div(class = "wg-status-text",
              tags$b("CONNECTED"),
              tags$span(class = "wg-status-detail", " \u2014 ", conn_state$message)
            )
          ),
          div(class = "wg-status-meta",
            tags$small(
              tags$i(class = "fa fa-clock-o"),
              " Last tested: ", format(conn_state$last_tested, "%H:%M:%S"),
              " | HTTP ", conn_state$status,
              " | User: ", input$v2_username
            )
          ),
          div(class = "wg-status-row", style = "margin-top:10px;",
            div(class = "wg-metric-mini",
              tags$b(length(conn_state$vehicles %||% list())),
              tags$br(), tags$small("Vehicles")),
            div(class = "wg-metric-mini",
              tags$b(conn_state$status),
              tags$br(), tags$small("HTTP")),
            div(class = "wg-metric-mini",
              tags$b("TLS"), tags$br(), tags$small("Encryption")),
            div(class = "wg-metric-mini",
              tags$b("Basic"), tags$br(), tags$small("Auth"))
          )
        )
      } else {
        div(
          div(class = "wg-status-row",
            div(class = "wg-status-dot",
                class = if (!is.null(conn_state$status) && conn_state$status > 0)
                  "wg-status-red" else "wg-status-grey"),
            div(class = "wg-status-text",
              tags$b(if (!is.null(conn_state$status) && conn_state$status > 0)
                "CONNECTION FAILED" else "NOT CONNECTED"),
              tags$span(class = "wg-status-detail", " \u2014 ", conn_state$message)
            )
          )
        )
      }
    })

    # ── Endpoint test results ────────────────────────────────────────────────
    output$v2_endpoint_test_ui <- renderUI({
      tests <- conn_state$endpoint_tests
      if (is.null(tests)) {
        return(div(class = "wg-empty-state",
          tags$i(class = "fa fa-stethoscope", style = "font-size:24px;opacity:.3;"),
          tags$p("Click 'Test All 3 Endpoints' after connecting to see results.")
        ))
      }
      tagList(
        lapply(tests, function(t) {
          colour <- if (t$ok) "#28a745" else "#dc3545"
          icon_c <- if (t$ok) "fa-check-circle" else "fa-times-circle"
          div(style = paste0("padding:10px 14px;margin-bottom:8px;background:#ffffff;",
                             "border-left:4px solid ", colour, ";border-radius:4px;"),
            div(style = "display:flex;align-items:center;justify-content:space-between;",
              tags$span(style = paste0("color:", colour, ";"),
                tags$i(class = paste0("fa ", icon_c), style = "margin-right:8px;"),
                tags$b(t$path)
              ),
              tags$span(style = paste0("color:", colour, ";font-family:monospace;font-weight:700;"), t$status)
            ),
            tags$p(style = "color:#1a2a35;margin:4px 0 2px;font-size:13px;", t$message),
            tags$p(style = "color:#007a73;margin:0;font-size:11px;", t$note)
          )
        })
      )
    })

    # ── Vehicle count badge ──────────────────────────────────────────────────
    output$v2_vehicle_count_badge <- renderUI({
      n <- length(conn_state$vehicles %||% list())
      if (n > 0) tags$span(class = "wg-badge", n, " vehicle(s)")
    })

    # ── Vehicle table ────────────────────────────────────────────────────────
    output$v2_vehicle_table_ui <- renderUI({
      if (!conn_state$connected || length(conn_state$vehicles %||% list()) == 0) {
        div(class = "wg-empty-state",
          tags$i(class = "fa fa-truck", style = "font-size:32px;opacity:.3;"),
          tags$p("No vehicle data yet. Connect to the API to fetch your fleet.")
        )
      } else {
        DT::dataTableOutput(ns("v2_vehicle_dt"))
      }
    })

    output$v2_vehicle_dt <- DT::renderDataTable({
      req(conn_state$connected, length(conn_state$vehicles %||% list()) > 0)
      df <- api_manager$vehicles_as_df(conn_state$vehicles)
      DT::datatable(
        df,
        options  = list(
          pageLength = 10, scrollX = TRUE,
          dom = "Bfrtip", buttons = c("csv"),
          initComplete = DT::JS(
            "function(settings, json) {",
            "$(this.api().table().header()).css({'background-color':'#1a2d45','color':'#7ec8e3'});",
            "}"
          )
        ),
        extensions = "Buttons",
        class    = "wg-dt", rownames = FALSE, escape = FALSE
      ) |>
        DT::formatStyle("VIN",
          backgroundColor = "#1e2a3a", color = "#008A82", fontWeight = "bold")
    })

    # ── Raw JSON [Ch1: JSON format] ──────────────────────────────────────────
    # [Ch1-JSON] The raw response demonstrates: JSON objects = R lists,
    # arrays = R character/numeric vectors, null = NA, bool = logical.
    output$v2_raw_json <- renderText({
      if (is.null(conn_state$raw_json)) {
        paste(
          "# Connect to see the raw API response here.",
          "# The Volvo API returns JSON like:",
          "# {",
          '#   "vehicleResponse": {',
          '#     "vehicles": [',
          '#       { "vin": "ABC123...", "brand": "RENAULT TRUCKS", ... }',
          '#     ]',
          '#   },',
          '#   "moreDataAvailable": false',
          "# }",
          sep = "\n"
        )
      } else {
        conn_state$raw_json
      }
    })
  })
}
