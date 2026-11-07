# modules/api_connection.R - Welch Group Fleet Monitor
# Tab 1: API Connection Settings & Vehicle Discovery
# Volvo Group vehicle API v1.0.6 – Renault Trucks Developer Portal

# ══════════════════════════════════════════════════════════════════
#  UI
# ══════════════════════════════════════════════════════════════════
api_connection_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ── Page header ──────────────────────────────────────────────
    div(class = "wg-page-header",
      div(class = "wg-page-title",
        tags$i(class = "fa fa-plug", style = "margin-right:10px;"),
        "Volvo Group Vehicle API – Connection Setup"
      ),
      div(class = "wg-page-subtitle",
        "Authenticate against the Renault Trucks Developer Portal (api.renault-trucks.com)",
        " to access live data for the Welch Group EV Artic fleet."
      )
    ),

    fluidRow(
      # ── Credentials panel ───────────────────────────────────────
      column(4,
        div(class = "wg-card",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-lock", style = "margin-right:8px;"),
            "API Credentials"
          ),
          div(class = "wg-card-body",
            div(class = "wg-field-group",
              tags$label("Username / API Key", class = "wg-label"),
              textInput(ns("username"), label = NULL,
                        placeholder = "Enter API username or client ID",
                        width = "100%")
            ),
            div(class = "wg-field-group",
              tags$label("Password / Secret", class = "wg-label"),
              passwordInput(ns("password"), label = NULL,
                            placeholder = "Enter API password or secret",
                            width = "100%")
            ),
            div(class = "wg-field-group",
              tags$label("Request ID (optional)", class = "wg-label"),
              textInput(ns("request_id"), label = NULL,
                        placeholder = "Auto-generated if blank",
                        width = "100%")
            ),
            tags$small(class = "wg-hint",
              tags$i(class = "fa fa-info-circle"),
              " Credentials are sent via HTTPS Basic Authentication and are never stored on disk."
            ),
            tags$hr(class = "wg-divider"),
            actionButton(ns("btn_connect"), "Test Connection",
                         icon = icon("wifi"),
                         class = "wg-btn wg-btn-primary",
                         width = "100%"),
            tags$br(), tags$br(),
            actionButton(ns("btn_refresh"), "Refresh Vehicle List",
                         icon = icon("sync"),
                         class = "wg-btn wg-btn-secondary",
                         width = "100%")
          )
        ),

        # ── Endpoint info card ──────────────────────────────────
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-server", style = "margin-right:8px;"),
            "API Endpoint"
          ),
          div(class = "wg-card-body wg-endpoint-box",
            tags$p(tags$b("Base URL"), tags$br(),
                   tags$code("api.renault-trucks.com/vehicle")),
            tags$p(tags$b("Scheme"), tags$br(), tags$code("HTTPS")),
            tags$p(tags$b("Auth"), tags$br(), tags$code("Basic (Base64)")),
            tags$p(tags$b("Accept"), tags$br(),
                   tags$code("application/x.volvogroup.com", tags$br(),
                             ".vehicles.v1.0+json; UTF-8")),
            tags$p(tags$b("API Version"), tags$br(), tags$code("1.0.6"))
          )
        )
      ),

      # ── Status + vehicle list ────────────────────────────────
      column(8,
        # Connection status
        div(class = "wg-card",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-signal", style = "margin-right:8px;"),
            "Connection Status"
          ),
          div(class = "wg-card-body",
            uiOutput(ns("connection_status_ui"))
          )
        ),

        # Known fleet reference
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-truck", style = "margin-right:8px;"),
            "Welch Group EV Artic Fleet – Target Vehicles"
          ),
          div(class = "wg-card-body",
            div(class = "wg-fleet-ref",
              div(class = "wg-fleet-vehicle",
                tags$span(class = "wg-reg-plate", "TA70 WTL"),
                div(class = "wg-vehicle-detail",
                  tags$b("EV Artic 1"), tags$br(),
                  tags$small("Electric articulated truck · Welch Group fleet")
                )
              ),
              div(class = "wg-fleet-vehicle",
                tags$span(class = "wg-reg-plate", "N88 GNW"),
                div(class = "wg-vehicle-detail",
                  tags$b("EV Artic 2"), tags$br(),
                  tags$small("Electric articulated truck · Welch Group fleet")
                )
              )
            ),
            tags$small(class = "wg-hint",
              tags$i(class = "fa fa-info-circle"),
              " After connecting, the API returns VINs. Use the Vehicle Data tab to query live data.",
              " VINs will be matched to the above registrations where possible."
            )
          )
        ),

        # API vehicle list result
        div(class = "wg-card", style = "margin-top:16px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-list", style = "margin-right:8px;"),
            "Vehicles Returned by API",
            uiOutput(ns("vehicle_count_badge"), inline = TRUE)
          ),
          div(class = "wg-card-body",
            uiOutput(ns("vehicle_table_ui"))
          )
        )
      )
    ),

    # ── API Documentation reference ──────────────────────────────
    fluidRow(
      column(12,
        div(class = "wg-card", style = "margin-top:8px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-book", style = "margin-right:8px;"),
            "Available API Endpoints"
          ),
          div(class = "wg-card-body",
            fluidRow(
              column(4,
                div(class = "wg-endpoint-ref",
                  tags$span(class = "wg-method-get", "GET"),
                  tags$b(" /vehicles"),
                  tags$p("List all vehicles the credentials have access to.",
                         "Returns VIN, brand, model, emission level, fuel type, production date."),
                  tags$small(class = "wg-param", "?additionalContent=VOLVOGROUPVEHICLE")
                )
              ),
              column(4,
                div(class = "wg-endpoint-ref",
                  tags$span(class = "wg-method-get", "GET"),
                  tags$b(" /vehiclepositions"),
                  tags$p("GPS positions, heading, altitude, speed (GNSS + wheel-based + tacho)."),
                  tags$small(class = "wg-param", "?vin=&startTime=&stopTime=&latestOnly=")
                )
              ),
              column(4,
                div(class = "wg-endpoint-ref",
                  tags$span(class = "wg-method-get", "GET"),
                  tags$b(" /vehiclestatuses"),
                  tags$p("Full telemetry: fuel, odometer, engine hours, driver ID, accumulated & snapshot data."),
                  tags$small(class = "wg-param", "?vin=&startTime=&stopTime=&content=")
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
api_connection_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Reactive state ────────────────────────────────────────
    conn_state <- reactiveValues(
      connected  = FALSE,
      message    = "Not connected. Enter credentials and click Test Connection.",
      status     = NULL,
      vehicles   = NULL,
      last_tested = NULL
    )

    # ── Test Connection ───────────────────────────────────────
    observeEvent(input$btn_connect, {
      req(nchar(trimws(input$username)) > 0)

      showNotification("Testing connection to Renault Trucks API...",
                       type = "message", id = "conn_notif", duration = NULL)

      api_manager$set_credentials(input$username, input$password)

      result <- api_manager$test_connection()

      removeNotification("conn_notif")

      conn_state$connected   <- result$success
      conn_state$status      <- result$status
      conn_state$message     <- result$message
      conn_state$last_tested <- Sys.time()

      if (result$success) {
        conn_state$vehicles <- result$vehicles
        showNotification(
          paste("✓", result$message),
          type = "message", duration = 5
        )
      } else {
        showNotification(
          paste("✗", result$message),
          type = "error", duration = 8
        )
      }
    })

    # ── Refresh vehicle list ──────────────────────────────────
    observeEvent(input$btn_refresh, {
      if (!api_manager$is_connected) {
        showNotification("Please connect first.", type = "warning")
        return()
      }
      result <- api_manager$get_vehicles()
      if (result$success) {
        conn_state$vehicles <- result$data$vehicles %||% list()
        api_manager$vehicles_cache <- conn_state$vehicles
        showNotification(
          sprintf("✓ %d vehicle(s) retrieved.", length(conn_state$vehicles)),
          type = "message", duration = 4
        )
      } else {
        showNotification(paste("✗", result$message), type = "error", duration = 6)
      }
    })

    # ── Connection status UI ──────────────────────────────────
    output$connection_status_ui <- renderUI({
      if (conn_state$connected) {
        div(
          div(class = "wg-status-row",
            div(class = "wg-status-dot wg-status-green"),
            div(class = "wg-status-text",
              tags$b("CONNECTED"),
              tags$span(class = "wg-status-detail",
                        " – ", conn_state$message)
            )
          ),
          div(class = "wg-status-meta",
            tags$small(
              tags$i(class = "fa fa-clock-o"),
              " Last tested: ", format(conn_state$last_tested, "%H:%M:%S"),
              " | HTTP ", conn_state$status,
              " | User: ", input$username
            )
          ),
          div(class = "wg-status-row", style = "margin-top:10px;",
            div(class = "wg-metric-mini",
              tags$b(length(conn_state$vehicles %||% list())),
              tags$br(), tags$small("Vehicles")
            ),
            div(class = "wg-metric-mini",
              tags$b(conn_state$status),
              tags$br(), tags$small("HTTP Status")
            ),
            div(class = "wg-metric-mini",
              tags$b("TLS"),
              tags$br(), tags$small("Encryption")
            ),
            div(class = "wg-metric-mini",
              tags$b("Basic"),
              tags$br(), tags$small("Auth Scheme")
            )
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
              tags$span(class = "wg-status-detail",
                        " – ", conn_state$message)
            )
          ),
          if (!is.null(conn_state$status) && conn_state$status > 0)
            div(class = "wg-error-hint",
              tags$i(class = "fa fa-exclamation-triangle"),
              " HTTP ", conn_state$status,
              ": Check credentials and network access to api.renault-trucks.com"
            )
        )
      }
    })

    # ── Vehicle count badge ───────────────────────────────────
    output$vehicle_count_badge <- renderUI({
      n <- length(conn_state$vehicles %||% list())
      if (n > 0)
        tags$span(class = "wg-badge", n, " vehicle(s)")
    })

    # ── Vehicle table UI ──────────────────────────────────────
    output$vehicle_table_ui <- renderUI({
      if (!conn_state$connected || length(conn_state$vehicles %||% list()) == 0) {
        div(class = "wg-empty-state",
          tags$i(class = "fa fa-truck", style = "font-size:32px;opacity:.3;"),
          tags$p("No vehicle data yet. Connect to the API to fetch your fleet.")
        )
      } else {
        DT::dataTableOutput(ns("vehicle_dt"))
      }
    })

    output$vehicle_dt <- DT::renderDataTable({
      req(conn_state$connected, length(conn_state$vehicles %||% list()) > 0)
      df <- api_manager$vehicles_as_df(conn_state$vehicles)
      DT::datatable(
        df,
        options  = list(pageLength = 10, scrollX = TRUE,
                        dom = "Bfrtip",
                        initComplete = JS(
                          "function(settings, json) {",
                          "$(this.api().table().header()).css({'background-color':'#1a2d45','color':'#7ec8e3'});",
                          "}"
                        )),
        class    = "wg-dt",
        rownames = FALSE,
        escape   = FALSE
      ) |>
        DT::formatStyle(
          "VIN",
          backgroundColor = "#1e2a3a",
          color = "#7ec8e3",
          fontWeight = "bold"
        )
    })
  })
}
