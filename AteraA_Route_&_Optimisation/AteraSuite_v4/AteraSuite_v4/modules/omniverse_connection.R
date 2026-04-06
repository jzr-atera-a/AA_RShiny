# modules/omniverse_connection.R
# Isaac Sim HTTP Connection — Non-blocking with live progress polling
# Atera Analytics - Innovate UK 10153306
#
# Architecture:
#   1. POST /scenarios/query  → returns job_id instantly (does not block)
#   2. reactiveTimer polls GET /progress/<job_id> every 1 second
#   3. Progress bar + log update in real time while Isaac Sim runs
#   4. When status == "complete", fetches GET /result/<job_id>
#   5. Result stored in api_manager for downstream tabs

# ============================================================================
# UI
# ============================================================================

omniverse_connection_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # CSS for the live log
    tags$style(HTML("
      .isaac-log {
        font-family: 'Courier New', monospace;
        font-size: 11px;
        background: #0d1117;
        color: #c9d1d9;
        padding: 10px 14px;
        border-radius: 4px;
        max-height: 320px;
        overflow-y: auto;
        line-height: 1.6;
      }
      .isaac-log .ok    { color: #3fb950; }
      .isaac-log .err   { color: #f85149; }
      .isaac-log .info  { color: #58a6ff; }
      .isaac-log .warn  { color: #d29922; }
      .isaac-log .ts    { color: #484f58; }
      .progress-wrap { margin-top: 8px; }
    ")),

    # ---- Row 1: Connection + Vehicle + Route ----
    fluidRow(

      box(title = "Isaac Sim Connection", status = "primary",
          solidHeader = TRUE, width = 4,

          p(class="text-muted small", "HTTP to Flask → persistent Isaac Sim"),

          textInput(ns("serverURL"), "Server URL:",
                    value = "http://localhost:5000"),

          fluidRow(
            column(6, actionButton(ns("testConnection"), "Test Connection",
                                   class="btn-primary btn-block btn-sm", icon=icon("plug"))),
            column(6, actionButton(ns("queryCapabilities"), "Capabilities",
                                   class="btn-info btn-block btn-sm", icon=icon("list")))
          ),
          br(),
          uiOutput(ns("connectionStatus")),
          uiOutput(ns("capabilitiesStatus"))
      ),

      box(title = "Vehicle", status = "warning", solidHeader = TRUE, width = 4,

          selectInput(ns("vehicleType"), "Vehicle:",
                      choices = c("Renault E-Tech T 42-tonne HGV" = "renault_etech_t",
                                  "Kia Niro EV (1.7t)"            = "kia_niro_ev"),
                      selected = "renault_etech_t"),

          checkboxInput(ns("truckLoaded"), "Fully Loaded (42t GCW)", value = TRUE),
          hr(),
          uiOutput(ns("vehicleSpecs"))
      ),

      box(title = "Route", status = "info", solidHeader = TRUE, width = 4,

          textInput(ns("queryOrigin"), "Origin:",
                    value = "Milton Keynes, Buckinghamshire, England"),
          textInput(ns("queryDestination"), "Destination:",
                    value = "Bletchley, Buckinghamshire, England"),

          selectInput(ns("querySamplingInterval"), "Sampling Interval:",
                      choices  = c("100m"="0.1","200m"="0.2","500m"="0.5",
                                   "1 km"="1.0","2 km"="2.0","5 km"="5.0"),
                      selected = "1.0"),

          fluidRow(
            column(6, selectInput(ns("queryWeather"), "Weather:",
                                  choices = c("Clear"="clear","Light Rain"="light_rain",
                                              "Heavy Rain"="heavy_rain","Fog"="fog"))),
            column(6, selectInput(ns("queryTimeOfDay"), "Time:",
                                  choices = c("Day"="day","Dusk"="dusk","Night"="night")))
          )
      )
    ),

    # ---- Row 2: Sensors + Physics ----
    fluidRow(
      box(title = "Sensor Features", status = "success", solidHeader = TRUE, width = 6,
          tags$div(style = "column-count:2;",
            tags$div(h5(tags$b("Camera:")),
              checkboxInput(ns("sensor_camera_rgb"),      "RGB",               value=TRUE),
              checkboxInput(ns("sensor_camera_depth"),    "Depth",             value=FALSE),
              checkboxInput(ns("sensor_camera_semantic"), "Semantic",          value=FALSE)
            ),
            tags$div(h5(tags$b("Other:")),
              checkboxInput(ns("sensor_lidar"),   "LiDAR", value=TRUE),
              checkboxInput(ns("sensor_imu"),     "IMU",   value=FALSE),
              checkboxInput(ns("sensor_contact"), "Contact", value=FALSE)
            )
          )
      ),
      box(title = "Physics Features", status = "danger", solidHeader = TRUE, width = 6,
          tags$div(style = "column-count:2;",
            tags$div(h5(tags$b("Kinematics:")),
              checkboxInput(ns("physics_velocity"),     "Velocity",     value=TRUE),
              checkboxInput(ns("physics_acceleration"), "Acceleration", value=TRUE),
              checkboxInput(ns("physics_momentum"),     "Momentum",     value=FALSE),
              checkboxInput(ns("physics_position"),     "Position",     value=TRUE),
              checkboxInput(ns("physics_mass_inertia"), "Mass/Inertia", value=FALSE)
            ),
            tags$div(h5(tags$b("Vehicle:")),
              checkboxInput(ns("physics_wheels"),         "Wheels",       value=TRUE),
              checkboxInput(ns("physics_suspension"),     "Suspension",   value=TRUE),
              checkboxInput(ns("physics_braking"),        "Braking",      value=FALSE),
              checkboxInput(ns("physics_drivetrain"),     "Drivetrain",   value=TRUE),
              checkboxInput(ns("physics_steering"),       "Steering",     value=FALSE),
              checkboxInput(ns("physics_aerodynamics"),   "Aerodynamics", value=TRUE),
              checkboxInput(ns("physics_tire_friction"),  "Tire Friction",value=FALSE),
              checkboxInput(ns("physics_contact_forces"), "Contact F.",   value=FALSE)
            )
          )
      )
    ),

    # ---- Row 3: Generate button + live progress ----
    fluidRow(
      box(width = 12, status = "primary",

          actionButton(ns("generateScenarios"),
                       "Generate Scenarios with Isaac Sim PhysX",
                       class = "btn-success btn-lg btn-block",
                       icon  = icon("rocket"),
                       style = "height:58px; font-size:17px;"),

          br(), br(),

          # Live progress bar
          uiOutput(ns("progressBar")),

          # Live log window
          uiOutput(ns("liveLog"))
      )
    ),

    # ---- Row 4: Map + Summary ----
    fluidRow(
      box(title = "Route Trajectory (Real GPS)", status = "info",
          solidHeader = TRUE, width = 8,
          leafletOutput(ns("trajectoryMap"), height = "480px")),

      box(title = "Simulation Summary", status = "success",
          solidHeader = TRUE, width = 4,
          uiOutput(ns("resultsDisplay")))
    )
  )
}

# ============================================================================
# SERVER
# ============================================================================

omniverse_connection_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    rv <- reactiveValues(
      connected    = FALSE,
      server_url   = "http://localhost:5000",
      capabilities = NULL,
      # Job tracking
      job_id       = NULL,
      job_status   = "idle",   # idle | queued | running | complete | error
      job_pct      = 0,
      job_msg      = "",
      job_log      = character(0),
      # Final result
      scenarios    = list(),
      vehicle_cfg  = NULL
    )

    # Polling timer — fires every 1 second, only active when a job is running
    poll_timer <- reactiveTimer(1000)

    # ------------------------------------------------------------------
    # HELPERS
    # ------------------------------------------------------------------

    base_url <- reactive({ trimws(input$serverURL) })

    safe_get <- function(url, timeout_s = 5) {
      tryCatch({
        r <- httr::GET(url, httr::timeout(timeout_s))
        list(ok=TRUE, code=httr::status_code(r),
             data=httr::content(r,"parsed",encoding="UTF-8"))
      }, error=function(e) list(ok=FALSE, msg=conditionMessage(e)))
    }

    safe_post <- function(url, body, timeout_s = 15) {
      tryCatch({
        r <- httr::POST(url,
                        body   = jsonlite::toJSON(body, auto_unbox=TRUE),
                        encode = "raw",
                        httr::content_type("application/json"),
                        httr::timeout(timeout_s))
        list(ok=TRUE, code=httr::status_code(r),
             data=httr::content(r,"parsed",encoding="UTF-8"))
      }, error=function(e) list(ok=FALSE, msg=conditionMessage(e)))
    }

    # ------------------------------------------------------------------
    # POLLING — runs every 1s, only does work when a job is in flight
    # ------------------------------------------------------------------

    observe({
      poll_timer()  # take dependency on timer

      if (is.null(rv$job_id)) return()
      if (rv$job_status %in% c("complete","error","idle")) return()

      url <- paste0(base_url(), "/progress/", rv$job_id)
      res <- safe_get(url, timeout_s=3)
      if (!res$ok) return()
      if (res$code != 200) return()

      d <- res$data
      rv$job_status <- d$status   %||% rv$job_status
      rv$job_pct    <- d$percent  %||% rv$job_pct
      rv$job_msg    <- d$message  %||% rv$job_msg
      rv$job_log    <- unlist(d$log %||% list())

      # When Isaac Sim signals complete, fetch the result
      if (identical(d$status, "complete")) {
        result_url <- paste0(base_url(), "/result/", rv$job_id)
        rres <- safe_get(result_url, timeout_s=10)

        if (rres$ok && rres$code == 200) {
          rd            <- rres$data
          rv$scenarios  <- rd$scenarios
          rv$vehicle_cfg<- rd$vehicle_config

          if (!is.null(api_manager)) {
            api_manager$omniverse_scenarios <- rd$scenarios
            api_manager$vehicle_config      <- rd$vehicle_config
          }

          n   <- length(rd$scenarios[[1]]$trajectories)
          av  <- rd$scenarios[[1]]$av_readiness %||% "?"
          km  <- rd$scenarios[[1]]$metadata$distance_km %||% "?"
          showNotification(
            paste0("\u2713 Simulation complete! ", n, " waypoints | ", km, " km | AV: ", av),
            type="message", duration=6
          )
        } else {
          rv$job_status <- "error"
          rv$job_msg    <- paste("Failed to fetch result:", rres$msg %||% paste("HTTP", rres$code))
        }
      }

      if (identical(d$status, "error")) {
        showNotification(paste("Isaac Sim error:", d$message), type="error", duration=10)
      }
    })

    # ------------------------------------------------------------------
    # TEST CONNECTION
    # ------------------------------------------------------------------

    observeEvent(input$testConnection, {
      rv$connected <- FALSE
      res <- safe_get(paste0(base_url(), "/status"))

      if (!res$ok) {
        showNotification(paste("Connection failed:", res$msg), type="error", duration=6)
        return()
      }
      if (res$code != 200) {
        showNotification(paste("HTTP", res$code), type="error", duration=6)
        return()
      }

      d             <- res$data
      rv$connected  <- TRUE
      rv$server_url <- base_url()
      isaac_up      <- isTRUE(d$isaac_sim_ready)

      if (isaac_up) {
        showNotification(paste0("\u2713 Flask online | Isaac Sim ready since ", d$isaac_sim_ready_since),
                         type="message", duration=5)
      } else {
        showNotification(
          "\u26a0 Flask online but Isaac Sim not started. Run isaac_sim_persistent_server.py first.",
          type="warning", duration=10
        )
      }
    })

    # ------------------------------------------------------------------
    # CAPABILITIES
    # ------------------------------------------------------------------

    observeEvent(input$queryCapabilities, {
      req(rv$connected)
      res <- safe_get(paste0(base_url(), "/capabilities"), timeout_s=8)
      if (!res$ok || res$code != 200) {
        showNotification("Capabilities query failed", type="error")
        return()
      }
      rv$capabilities <- res$data$capabilities
      caps <- res$data$capabilities
      showNotification(
        paste0("\u2713 ", sum(unlist(caps$sensors)), " sensors | ",
               sum(unlist(caps$physics)), " physics features | ",
               caps$hardware$gpu_name),
        type="message", duration=5
      )
    })

    # ------------------------------------------------------------------
    # GENERATE — POST job, get job_id back IMMEDIATELY, polling takes over
    # ------------------------------------------------------------------

    observeEvent(input$generateScenarios, {
      if (!rv$connected) {
        showNotification("Not connected. Click Test Connection first.", type="error")
        return()
      }
      if (trimws(input$queryOrigin)=="" || trimws(input$queryDestination)=="") {
        showNotification("Enter origin and destination.", type="error")
        return()
      }

      # Reset job state
      rv$job_id     <- NULL
      rv$job_status <- "queued"
      rv$job_pct    <- 0
      rv$job_msg    <- "Submitting job to Isaac Sim..."
      rv$job_log    <- character(0)
      rv$scenarios  <- list()

      sensor_cfg <- list(
        camera  = list(rgb      = isTRUE(input$sensor_camera_rgb),
                       depth    = isTRUE(input$sensor_camera_depth),
                       semantic = isTRUE(input$sensor_camera_semantic)),
        lidar   = isTRUE(input$sensor_lidar),
        imu     = isTRUE(input$sensor_imu),
        contact = isTRUE(input$sensor_contact)
      )
      physics_cfg <- list(
        velocity       = isTRUE(input$physics_velocity),
        acceleration   = isTRUE(input$physics_acceleration),
        momentum       = isTRUE(input$physics_momentum),
        position       = isTRUE(input$physics_position),
        mass_inertia   = isTRUE(input$physics_mass_inertia),
        wheels         = isTRUE(input$physics_wheels),
        suspension     = isTRUE(input$physics_suspension),
        braking        = isTRUE(input$physics_braking),
        drivetrain     = isTRUE(input$physics_drivetrain),
        steering       = isTRUE(input$physics_steering),
        aerodynamics   = isTRUE(input$physics_aerodynamics),
        tire_friction  = isTRUE(input$physics_tire_friction),
        contact_forces = isTRUE(input$physics_contact_forces)
      )

      if (!is.null(api_manager)) {
        api_manager$sensor_config  <- sensor_cfg
        api_manager$physics_config <- physics_cfg
      }

      body <- list(
        vehicle              = input$vehicleType,
        loaded               = isTRUE(input$truckLoaded),
        origin               = input$queryOrigin,
        destination          = input$queryDestination,
        sampling_interval_km = as.numeric(input$querySamplingInterval),
        weather              = input$queryWeather,
        time_of_day          = input$queryTimeOfDay,
        limit                = 1L,
        sensors              = sensor_cfg,
        physics              = physics_cfg
      )

      # This POST returns INSTANTLY with a job_id — no waiting
      res <- safe_post(paste0(base_url(), "/scenarios/query"), body, timeout_s=10)

      if (!res$ok || res$code != 200) {
        rv$job_status <- "error"
        rv$job_msg    <- paste("Failed to submit job:",
                               if (!res$ok) res$msg else paste("HTTP", res$code, "-",
                                                                res$data$error %||% ""))
        showNotification(rv$job_msg, type="error", duration=8)
        return()
      }

      rv$job_id     <- res$data$job_id
      rv$job_status <- "running"
      rv$job_pct    <- 1
      rv$job_msg    <- paste0("Job ", res$data$job_id, " submitted — Isaac Sim processing...")

      showNotification(
        paste0("Job submitted: ", res$data$job_id, ". Live updates below."),
        type="message", duration=4
      )
    })

    # ------------------------------------------------------------------
    # OUTPUT: CONNECTION STATUS
    # ------------------------------------------------------------------

    output$connectionStatus <- renderUI({
      if (rv$connected) {
        res <- tryCatch(
          httr::content(httr::GET(paste0(rv$server_url,"/status"),httr::timeout(2)),"parsed"),
          error=function(e) NULL
        )
        isaac_up <- isTRUE(res$isaac_sim_ready)
        tags$div(
          tags$div(class="alert alert-success" , style="margin-bottom:4px; padding:6px 10px;",
                   icon("check-circle"), " Flask server online"),
          if (isaac_up)
            tags$div(class="alert alert-success", style="margin-bottom:0; padding:6px 10px;",
                     icon("microchip"), " Isaac Sim persistent server ready")
          else
            tags$div(class="alert alert-warning", style="margin-bottom:0; padding:6px 10px;",
                     icon("exclamation-triangle"),
                     " Isaac Sim not started — run isaac_sim_persistent_server.py")
        )
      } else {
        tags$div(class="alert alert-warning", style="padding:6px 10px;",
                 icon("exclamation-triangle"), " Not connected")
      }
    })

    # ------------------------------------------------------------------
    # OUTPUT: CAPABILITIES
    # ------------------------------------------------------------------

    output$capabilitiesStatus <- renderUI({
      caps <- rv$capabilities
      if (is.null(caps)) return(NULL)
      tags$div(class="alert alert-info", style="padding:6px 10px; font-size:11px; margin-top:4px;",
               tags$b("Confirmed: "),
               paste(sum(unlist(caps$sensors)), "sensors |",
                     sum(unlist(caps$physics)), "physics |",
                     caps$hardware$gpu_name, "|",
                     "Isaac Sim", caps$software$isaac_sim_version,
                     "(", caps$software$server_mode, ")"))
    })

    # ------------------------------------------------------------------
    # OUTPUT: VEHICLE SPECS
    # ------------------------------------------------------------------

    output$vehicleSpecs <- renderUI({
      if (input$vehicleType == "kia_niro_ev") {
        tags$ul(class="small", style="padding-left:18px; margin-bottom:0;",
          tags$li("Mass: 1,739 kg | Power: 150 kW"),
          tags$li("Battery: 64.8 kWh | Max: 167 km/h"),
          tags$li("Cd: 0.29 | Frontal: 2.58 m²"),
          tags$li("Wheelbase: 2.72 m")
        )
      } else {
        mass <- if (isTRUE(input$truckLoaded)) "42,000 kg (GCW)" else "8,500 kg (tare)"
        tags$ul(class="small", style="padding-left:18px; margin-bottom:0;",
          tags$li(paste("Mass:", mass)),
          tags$li("Power: 490 kW | Battery: 540 kWh"),
          tags$li("Max: 90 km/h | Cd: 0.42"),
          tags$li("Frontal: 8.5 m² | WB: 6.0 m")
        )
      }
    })

    # ------------------------------------------------------------------
    # OUTPUT: LIVE PROGRESS BAR
    # ------------------------------------------------------------------

    output$progressBar <- renderUI({
      status <- rv$job_status
      if (status == "idle") return(NULL)

      pct   <- rv$job_pct
      msg   <- rv$job_msg
      color <- switch(status,
                      "complete" = "success",
                      "error"    = "danger",
                      "warning")

      tags$div(
        class = "progress-wrap",
        tags$p(class="small", style="margin-bottom:4px; color:#666;", msg),
        tags$div(
          class = "progress",
          style = "height:22px; margin-bottom:6px;",
          tags$div(
            class = paste0("progress-bar progress-bar-striped",
                           if (status=="running") " active" else "",
                           " progress-bar-", color),
            style = paste0("width:", pct, "%; font-size:12px; line-height:22px;"),
            paste0(pct, "%")
          )
        )
      )
    })

    # ------------------------------------------------------------------
    # OUTPUT: LIVE LOG WINDOW — updates every poll cycle
    # ------------------------------------------------------------------

    output$liveLog <- renderUI({
      status  <- rv$job_status
      log_lines <- rv$job_log

      if (status == "idle" || length(log_lines) == 0) return(NULL)

      # Colour-code lines based on content
      formatted <- lapply(log_lines, function(line) {
        cls <- if      (grepl("\\[OK\\]|COMPLETE|✓|GREEN",  line, ignore.case=TRUE)) "ok"
               else if (grepl("ERROR|FATAL|FAIL|✗",         line, ignore.case=TRUE)) "err"
               else if (grepl("AMBER|WARN",                 line, ignore.case=TRUE)) "warn"
               else                                                                   "info"

        # Split timestamp from message
        if (grepl("^\\[\\d{2}:\\d{2}:\\d{2}\\]", line)) {
          ts  <- substr(line, 1, 10)
          msg <- substr(line, 11, nchar(line))
          tags$div(tags$span(class="ts", ts), tags$span(class=cls, msg))
        } else {
          tags$div(class=cls, line)
        }
      })

      tags$div(
        tags$div(
          class = "isaac-log",
          id    = ns("logScroll"),
          do.call(tagList, formatted),
          # Auto-scroll to bottom via JS
          tags$script(HTML(sprintf(
            "var el = document.getElementById('%s'); if(el) el.scrollTop = el.scrollHeight;",
            ns("logScroll")
          )))
        )
      )
    })

    # ------------------------------------------------------------------
    # OUTPUT: LEAFLET MAP with real GPS + physics popups
    # ------------------------------------------------------------------

    output$trajectoryMap <- renderLeaflet({
      if (length(rv$scenarios) == 0) {
        return(leaflet() %>%
                 addProviderTiles(providers$CartoDB.Positron) %>%
                 setView(lng=-0.7594, lat=52.0406, zoom=11) %>%
                 addControl(
                   html = paste0("<div style='background:rgba(255,255,255,0.9);padding:10px;",
                                 "border-radius:6px;font-size:12px;'>",
                                 "<b>No data yet.</b><br>Generate a scenario to see real GPS route.</div>"),
                   position = "topright"
                 ))
      }

      scenario <- rv$scenarios[[1]]
      trajs    <- scenario$trajectories
      if (length(trajs) == 0) return(leaflet() %>% addTiles())

      lats   <- sapply(trajs, function(t) as.numeric(t$lat))
      lons   <- sapply(trajs, function(t) as.numeric(t$lon))
      speeds <- sapply(trajs, function(t) as.numeric(t$speed_kmh %||% 0))
      rtypes <- sapply(trajs, function(t) as.character(t$road_type %||% ""))
      avs    <- sapply(trajs, function(t) as.character(t$av_readiness_status %||% "?"))
      av_sc  <- sapply(trajs, function(t) as.numeric(t$av_readiness_score %||% 5))

      pal <- colorNumeric(c("#2ecc71","#f39c12","#e74c3c"), domain=range(speeds, na.rm=TRUE))
      av_col <- ifelse(avs=="GREEN","#2ecc71", ifelse(avs=="AMBER","#f39c12","#e74c3c"))

      # Build popup per waypoint
      popups <- lapply(seq_along(trajs), function(i) {
        t   <- trajs[[i]]
        phy <- t$physics %||% list()
        cam <- t$camera  %||% list()
        lid <- t$lidar   %||% list()

        rows <- function(...) paste0(...)
        tr   <- function(lbl, val, bg="") {
          bg_style <- if (nchar(bg)>0) paste0("background:",bg,";") else ""
          paste0("<tr style='",bg_style,"'><td style='padding:1px 6px;'><b>",lbl,"</b></td>",
                 "<td style='padding:1px 6px;'>",val,"</td></tr>")
        }

        html <- paste0(
          "<div style='font-family:monospace;font-size:11px;min-width:230px;'>",
          "<b style='font-size:12px;'>Waypoint ", i, " / ", length(trajs), "</b>",
          "<hr style='margin:3px 0;'>",
          "<table style='width:100%;border-collapse:collapse;'>",
          tr("Lat/Lon",    paste0(round(lats[i],5), ", ", round(lons[i],5))),
          tr("Speed",      paste0(round(speeds[i],1), " km/h"), "#f8f9fa"),
          tr("Road",       rtypes[i]),
          tr("AV",         paste0(round(av_sc[i],1), "/10 — ", avs[i]), "#f8f9fa")
        )

        if (length(phy) > 0) {
          html <- paste0(html, "<tr><td colspan=2 style='color:#0d6efd;padding-top:5px;'><b>— Physics —</b></td></tr>")
          if (!is.null(phy$speed_ms))
            html <- paste0(html, tr("Speed",    paste0(round(as.numeric(phy$speed_ms),2)," m/s")))
          if (!is.null(phy$acceleration_g))
            html <- paste0(html, tr("Accel",    paste0(round(as.numeric(phy$acceleration_g),4)," g"), "#f8f9fa"))
          if (!is.null(phy$aerodynamic_drag_N))
            html <- paste0(html, tr("Aero drag",paste0(round(as.numeric(phy$aerodynamic_drag_N),0)," N")))
          if (!is.null(phy$suspension_static_deflection_m))
            html <- paste0(html, tr("Susp.",    paste0(round(as.numeric(phy$suspension_static_deflection_m)*1000,1)," mm"), "#f8f9fa"))
          if (!is.null(phy$wheel_speed_rpm))
            html <- paste0(html, tr("Wheel RPM",round(as.numeric(phy$wheel_speed_rpm),0)))
          if (!is.null(phy$tractive_force_N))
            html <- paste0(html, tr("Traction", paste0(round(as.numeric(phy$tractive_force_N),0)," N"), "#f8f9fa"))
          if (!is.null(phy$steering_angle_deg))
            html <- paste0(html, tr("Steer",    paste0(round(as.numeric(phy$steering_angle_deg),2),"°")))
          if (!is.null(phy$tire_friction_coeff))
            html <- paste0(html, tr("Tire μ",   round(as.numeric(phy$tire_friction_coeff),3), "#f8f9fa"))
        }

        if (!is.null(cam$lane_visibility)) {
          html <- paste0(html, "<tr><td colspan=2 style='color:#198754;padding-top:5px;'><b>— Camera —</b></td></tr>",
            tr("Lane vis", paste0(round(as.numeric(cam$lane_visibility),1),"/10")),
            tr("Sign conf",round(as.numeric(cam$sign_confidence),3),"#f8f9fa"))
        }
        if (!is.null(lid$point_density)) {
          html <- paste0(html, "<tr><td colspan=2 style='color:#6f42c1;padding-top:5px;'><b>— LiDAR —</b></td></tr>",
            tr("Density",  paste0(round(as.numeric(lid$point_density),0)," pts/m³")),
            tr("Det conf", round(as.numeric(lid$detection_confidence),3),"#f8f9fa"),
            tr("Range",    paste0(round(as.numeric(lid$effective_range_m %||% 0),0)," m")))
        }

        paste0(html, "</table></div>")
      })

      leaflet() %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
        addPolylines(lng=lons, lat=lats, color="#1a6eb5", weight=4, opacity=0.8) %>%
        addCircleMarkers(
          lng=lons, lat=lats,
          radius=7, weight=2,
          color=av_col,
          fillColor=~pal(speeds), fillOpacity=0.9,
          popup=unlist(popups),
          label=paste0(round(speeds,0)," km/h")
        ) %>%
        addMarkers(
          lng=lons[1], lat=lats[1],
          popup=paste0("<b>START</b><br>", input$queryOrigin,
                       "<br>", round(lats[1],5), ", ", round(lons[1],5))
        ) %>%
        addMarkers(
          lng=lons[length(lons)], lat=lats[length(lats)],
          popup=paste0("<b>END</b><br>", input$queryDestination,
                       "<br>", round(lats[length(lats)],5), ", ", round(lons[length(lons)],5))
        ) %>%
        addLegend(pal=pal, values=speeds, title="Speed (km/h)", position="bottomright") %>%
        fitBounds(lng1=min(lons),lat1=min(lats),lng2=max(lons),lat2=max(lats))
    })

    # ------------------------------------------------------------------
    # OUTPUT: RESULTS SUMMARY
    # ------------------------------------------------------------------

    output$resultsDisplay <- renderUI({
      if (length(rv$scenarios)==0) {
        status <- rv$job_status
        if (status %in% c("running","queued")) {
          return(tags$div(
            class="text-center", style="padding:20px;",
            tags$i(class="fa fa-spinner fa-spin fa-2x", style="color:#3498db;"),
            tags$br(), tags$br(),
            tags$p(class="text-info", paste0("Isaac Sim running... ", rv$job_pct, "%"))
          ))
        }
        return(tags$p(class="text-muted small",
                      "No data yet. Connect and generate a scenario."))
      }

      s  <- rv$scenarios[[1]]
      vc <- s$vehicle_config %||% list()
      md <- s$metadata %||% list()
      av <- s$av_readiness %||% "?"
      av_cls <- switch(av,"GREEN"="success","AMBER"="warning","danger")

      tags$div(
        tags$table(
          class="table table-condensed table-hover",
          style="font-size:12px;",
          tags$tbody(
            tags$tr(tags$td(tags$b("Vehicle")),
                    tags$td(vc$name %||% "?")),
            tags$tr(tags$td(tags$b("Mass")),
                    tags$td(paste(format(vc$mass_used_kg %||% vc$mass_kg %||% 0, big.mark=","), "kg"))),
            tags$tr(tags$td(tags$b("Power")),
                    tags$td(paste(vc$power_kw %||% "?", "kW"))),
            tags$tr(tags$td(tags$b("Route")),
                    tags$td(s$route %||% "?")),
            tags$tr(tags$td(tags$b("Distance")),
                    tags$td(paste(md$distance_km %||% "?", "km"))),
            tags$tr(tags$td(tags$b("Duration")),
                    tags$td(paste(md$duration_min %||% "?", "min"))),
            tags$tr(tags$td(tags$b("Waypoints")),
                    tags$td(length(s$trajectories))),
            tags$tr(tags$td(tags$b("GPS Source")),
                    tags$td(md$coordinate_source %||% "OSRM")),
            tags$tr(tags$td(tags$b("Weather")),
                    tags$td(s$weather_condition %||% "?")),
            tags$tr(tags$td(tags$b("AV Status")),
                    tags$td(tags$span(
                      class=paste0("label label-", av_cls),
                      paste(av, "—", s$av_score_mean %||% "?", "/ 10")
                    )))
          )
        )
      )
    })

  }) # moduleServer
}
