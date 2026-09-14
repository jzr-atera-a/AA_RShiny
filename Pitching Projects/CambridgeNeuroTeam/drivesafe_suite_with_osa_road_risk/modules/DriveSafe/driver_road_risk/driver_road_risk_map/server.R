# modules/DriveSafe/driver_road_risk/driver_road_risk_map/server.R
# OSA Road Risk Map Server
#
# Map rendering uses plotly::plot_ly(type = "scattermapbox") - the same
# proven, dependency-free pattern used by the working EnergyPlanningGeoApp
# reference (UK Renewable Energy Plants / Data Centres maps). This needs
# NOTHING beyond the {plotly} package that is already used everywhere else
# in DriveSafe: no {leaflet}, no {leaflet.extras}, and critically no
# {raster}/{terra} anywhere in the dependency tree (those get pulled in
# transitively by {leaflet} itself and break `renv::snapshot()` on
# shinyapps.io). The "open-street-map" mapbox style is free and needs no
# API token.
#
#   - risk heatmap: one scattermapbox trace of corridor sample points,
#     sized/coloured continuously by risk score (mirrors the reference
#     app's data-centre map colour-scale pattern)
#   - corridor markers: a second trace, click-to-detail side panel
#     (captured via plotly::event_data("plotly_click"))
#   - incident + rest-area/sleep-clinic marker traces, toggleable
#   - green -> amber -> orange -> red risk colour scale, matching the rest
#     of the DriveSafe Suite

driver_road_risk_map_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    map_source <- "risk_map_plot"

    selected_corridor <- reactiveVal(uk_osa_corridors$corridor_id[1])

    # ── Filtered corridor point data (drives the heatmap) ───────────────────
    filtered_points <- reactive({
      req(input$f_road_type, input$f_osa_group, input$f_time_window)

      pts <- uk_osa_corridor_points[uk_osa_corridor_points$road_type %in% input$f_road_type, ]
      if (nrow(pts) == 0) return(pts[0, ])

      pts$risk_score <- osa_risk_score(
        road_type      = pts$road_type,
        osa_group      = input$f_osa_group,
        time_window    = input$f_time_window,
        duration_hours = input$f_duration,
        point_noise    = pts$point_noise
      )
      pts$risk_colour   <- risk_colour(pts$risk_score)
      pts$risk_category <- risk_category(pts$risk_score)
      pts
    })

    # Corridor-level mean risk (for markers, KPIs, ranking)
    corridor_summary <- reactive({
      pts <- filtered_points()
      if (nrow(pts) == 0) return(pts[0, ])

      agg <- aggregate(risk_score ~ corridor_id, data = pts, FUN = mean)
      agg <- merge(agg, uk_osa_corridor_midpoints, by = "corridor_id")
      agg$risk_colour   <- risk_colour(agg$risk_score)
      agg$risk_category <- risk_category(agg$risk_score)
      agg
    })

    # ── KPI boxes ─────────────────────────────────────────────────────────────
    output$kpi_pct_high_risk <- renderValueBox({
      cs <- corridor_summary()
      pct <- if (nrow(cs) == 0) 0 else round(mean(cs$risk_score >= 50) * 100)
      valueBox(paste0(pct, "%"), "Corridors at High/Critical Risk",
                icon = icon("triangle-exclamation"),
                color = if (pct >= 50) "red" else if (pct >= 25) "yellow" else "green")
    })

    output$kpi_mean_risk <- renderValueBox({
      cs <- corridor_summary()
      m <- if (nrow(cs) == 0) 0 else round(mean(cs$risk_score), 1)
      valueBox(m, "Mean Corridor Risk Score (0-100)",
                icon = icon("gauge-high"),
                color = if (m >= 50) "red" else if (m >= 25) "yellow" else "aqua")
    })

    output$kpi_critical_count <- renderValueBox({
      cs <- corridor_summary()
      n <- if (nrow(cs) == 0) 0 else sum(cs$risk_score >= 75)
      valueBox(n, "Critical-Risk Corridors", icon = icon("skull-crossbones"),
                color = if (n > 0) "red" else "green")
    })

    output$kpi_cpap_benefit <- renderValueBox({
      pts <- uk_osa_corridor_points[uk_osa_corridor_points$road_type %in% (input$f_road_type %||% names(ROAD_TYPE_LABELS)), ]
      req(input$f_time_window)
      unt <- mean(osa_risk_score(pts$road_type, "osa_untreated", input$f_time_window, input$f_duration %||% 2, pts$point_noise))
      trt <- mean(osa_risk_score(pts$road_type, "osa_treated",   input$f_time_window, input$f_duration %||% 2, pts$point_noise))
      delta <- round(unt - trt, 1)
      valueBox(paste0("-", delta, " pts"), "CPAP Treatment Risk Reduction",
                icon = icon("kit-medical"),
                color = if (delta >= 15) "green" else if (delta >= 5) "yellow" else "red")
    })

    # ── Map (single scattermapbox figure, rebuilt whenever a filter or the
    #        visible-layers checkbox group changes) ─────────────────────────
    output$risk_map <- plotly::renderPlotly({
      layers <- input$f_layers %||% character(0)
      p <- plotly::plot_ly(source = map_source)

      # Layer 1: risk heatmap points - continuous colour scale AND size by
      # risk score, so hotspots visually read as bigger/denser blobs and
      # quiet stretches shrink to small dots - a proper heatmap distribution
      # rather than one uniform colour.
      if ("heatmap" %in% layers) {
        pts <- filtered_points()
        if (nrow(pts) > 0) {
          # Per-point calculation breakdown, in plain language, tied directly
          # back to the driver's OSA/CPAP status and the app's own metrics -
          # this answers "why is this point scored the way it is".
          base_v   <- ROAD_TYPE_BASE_RISK[pts$road_type]
          up_v     <- OSA_GROUP_UPLIFT[[input$f_osa_group]]
          mult_v   <- TIME_WINDOW_MULT[[input$f_time_window]]
          dur_v    <- pmin(pmax(input$f_duration %||% 2, 0), 8) * 2.4
          fatigue_v <- round((up_v + dur_v) * mult_v, 1)

          pts$hover_detail <- paste0(
            "<b>", pts$corridor_name, "</b> (", ROAD_TYPE_LABELS[pts$road_type], ")<br>",
            OSA_GROUP_LABELS[input$f_osa_group], " \u2013 ", TIME_WINDOW_LABELS[input$f_time_window], "<br>",
            "Road base risk: ", round(base_v, 1), "<br>",
            "+ OSA/CPAP status (", round(up_v, 1), ") & ", input$f_duration %||% 2, "h drive (",
            round(dur_v, 1), ") \u00d7 time-of-day \u00d7", mult_v, " = ", fatigue_v, "<br>",
            "+ local variation: ", round(pts$point_noise, 1), "<br>",
            "<b>Total: ", round(pts$risk_score, 1), "/100 (", pts$risk_category, ")</b>"
          )

          marker_size <- 7 + (pts$risk_score / 100) * (input$f_heat_radius %||% 24)

          p <- plotly::add_trace(p,
            data = pts, type = "scattermapbox", lon = ~lng, lat = ~lat,
            mode = "markers", name = "Risk Heatmap",
            marker = list(
              size = marker_size,
              color = ~risk_score,
              colorscale = list(list(0, "#1a6b35"), list(0.25, "#d4ac0d"),
                                 list(0.5, "#e67e22"), list(1, "#c0392b")),
              cmin = 0, cmax = 100,
              opacity = (input$f_heat_opacity %||% 35) / 100,
              colorbar = list(title = "Risk Score", titleside = "right", x = 1.02)
            ),
            text = ~hover_detail,
            hovertemplate = "%{text}<extra></extra>",
            customdata = ~corridor_id
          )
        }
      }

      # Layer 2: corridor markers (click target for the side panel)
      if ("corridors" %in% layers) {
        cs <- corridor_summary()
        if (nrow(cs) > 0) {
          sizes <- ifelse(cs$road_type == "motorway", 16, ifelse(cs$road_type == "a_road", 13, 11))

          up_v   <- OSA_GROUP_UPLIFT[[input$f_osa_group %||% "osa_untreated"]]
          mult_v <- TIME_WINDOW_MULT[[input$f_time_window %||% "10-14"]]
          dur_v  <- pmin(pmax(input$f_duration %||% 2, 0), 8) * 2.4
          fatigue_v <- round((up_v + dur_v) * mult_v, 1)

          cs$hover_detail <- paste0(
            "<b>", cs$corridor_name, "</b> (", ROAD_TYPE_LABELS[cs$road_type], ")<br>",
            "Corridor mean risk: ", round(cs$risk_score, 1), "/100 (", cs$risk_category, ")<br>",
            "Road base risk ", round(ROAD_TYPE_BASE_RISK[cs$road_type], 1),
            " + OSA/duration/time-of-day effect ", fatigue_v, "<br>",
            "<i>Click for full breakdown \u2192</i>"
          )

          p <- plotly::add_trace(p,
            data = cs, type = "scattermapbox", lon = ~lng, lat = ~lat,
            mode = "markers", name = "Corridors",
            marker = list(size = sizes, color = ~risk_colour, opacity = 0.95),
            customdata = ~corridor_id,
            text = ~hover_detail,
            hovertemplate = "%{text}<extra></extra>"
          )
        }
      }

      # Layer 3: near-miss incidents
      if ("incidents" %in% layers) {
        p <- plotly::add_trace(p,
          data = osa_incident_points, type = "scattermapbox", lon = ~lng, lat = ~lat,
          mode = "markers", name = "Near-Miss Incidents",
          marker = list(size = 11, color = "#8e44ad", opacity = 0.95),
          customdata = ~incident_id,
          text = ~paste0(incident_id, " (", severity, ") - ", corridor_name),
          hovertemplate = "%{text}<extra></extra>"
        )
      }

      # Layer 4: rest areas + OSA / CPAP sleep clinics
      if ("services" %in% layers) {
        rest <- osa_service_points[osa_service_points$type == "rest_area", ]
        clin <- osa_service_points[osa_service_points$type == "sleep_clinic", ]

        p <- plotly::add_trace(p,
          data = rest, type = "scattermapbox", lon = ~lng, lat = ~lat,
          mode = "markers", name = "Rest Areas",
          marker = list(size = 9, color = "#2980b9", opacity = 0.9),
          customdata = ~name, text = ~paste0(name, " (Rest Area)"),
          hovertemplate = "%{text}<extra></extra>"
        )
        p <- plotly::add_trace(p,
          data = clin, type = "scattermapbox", lon = ~lng, lat = ~lat,
          mode = "markers", name = "Sleep Clinics",
          marker = list(size = 12, color = "#00A39A", opacity = 0.95),
          customdata = ~name, text = ~paste0(name, " (OSA / CPAP Sleep Clinic)"),
          hovertemplate = "%{text}<extra></extra>"
        )
      }

      p |> plotly::layout(
        mapbox = list(
          style  = "open-street-map",
          center = list(lon = -2.5, lat = 54.0),
          zoom   = 5.4
        ),
        showlegend = TRUE,
        legend = list(orientation = "h", y = -0.02, bgcolor = "rgba(255,255,255,0.85)"),
        margin = list(l = 0, r = 0, t = 0, b = 0)
      ) |>
        plotly::config(displaylogo = FALSE)
    })

    observeEvent(input$btn_reset_view, {
      plotly::plotlyProxy("risk_map", session) |>
        plotly::plotlyProxyInvoke("relayout", list(
          "mapbox.center" = list(lon = -2.5, lat = 54.0),
          "mapbox.zoom"   = 5.4
        ))
    })

    # ── Corridor click -> selection ─────────────────────────────────────────
    observeEvent(plotly::event_data("plotly_click", source = map_source), {
      click <- plotly::event_data("plotly_click", source = map_source)
      cid <- click$customdata[1]
      if (!is.null(cid) && cid %in% uk_osa_corridors$corridor_id) {
        selected_corridor(cid)
      }
    })

    # ── Side panel: corridor detail ─────────────────────────────────────────
    output$corridor_detail_header <- renderUI({
      cid <- selected_corridor()
      row <- uk_osa_corridors[uk_osa_corridors$corridor_id == cid, ]
      req(nrow(row) == 1)
      req(input$f_osa_group, input$f_time_window)

      bd <- osa_risk_breakdown(row$road_type, input$f_osa_group, input$f_time_window,
                                input$f_duration %||% 2, point_noise = 0)
      score_now <- bd$total

      tagList(
        tags$h4(row$corridor_name, style = "margin-top:0;"),
        tags$p(tags$strong("Road type: "), ROAD_TYPE_LABELS[row$road_type]),
        div(class = paste0("ds-alert-", ifelse(score_now >= 75, "red",
                                          ifelse(score_now >= 50, "amber",
                                          ifelse(score_now >= 25, "amber", "teal")))),
          tags$strong("Current filtered risk: "), score_now, "/100 (",
          risk_category(score_now), ") for ", OSA_GROUP_LABELS[input$f_osa_group],
          " during ", TIME_WINDOW_LABELS[input$f_time_window]
        ),
        tags$div(style = "font-size:11.5px; color:#444; background:#f7f9fa; border-radius:6px; padding:8px 10px; margin-top:8px; line-height:1.55;",
          tags$strong("How this is calculated:"),
          tags$br(),
          "Road base risk (", ROAD_TYPE_LABELS[row$road_type], "): ", bd$base_risk,
          tags$br(),
          "+ OSA/CPAP status uplift (", OSA_GROUP_LABELS[input$f_osa_group], "): ", bd$osa_uplift,
          tags$br(),
          "+ Journey duration effect (", input$f_duration %||% 2, "h \u00d7 2.4 pts/h): ", bd$duration_component,
          tags$br(),
          "\u2192 fatigue subtotal \u00d7 time-of-day factor (", TIME_WINDOW_LABELS[input$f_time_window],
          ", \u00d7", bd$time_multiplier, "): ", bd$fatigue_scaled,
          tags$br(),
          tags$strong("= Total: ", bd$total, "/100 (", bd$category, ")")
        )
      )
    })

    output$corridor_group_bar <- plotly::renderPlotly({
      cid <- selected_corridor()
      pts <- uk_osa_corridor_points[uk_osa_corridor_points$corridor_id == cid, ]
      req(nrow(pts) > 0, input$f_time_window)

      groups <- names(OSA_GROUP_UPLIFT)
      vals <- sapply(groups, function(g) {
        mean(osa_risk_score(pts$road_type, g, input$f_time_window,
                             input$f_duration %||% 2, pts$point_noise))
      })

      plotly::plot_ly(
        x = OSA_GROUP_LABELS[groups], y = round(vals, 1), type = "bar",
        marker = list(color = OSA_GROUP_COLOURS[groups])
      ) |>
        plotly::layout(
          title = list(text = "Risk by Driver Group", font = list(size = 12)),
          yaxis = list(title = "Risk Score", range = c(0, 100)),
          xaxis = list(title = ""),
          margin = list(t = 30, b = 60)
        )
    })

    output$corridor_risk_donut <- plotly::renderPlotly({
      cid <- selected_corridor()
      pts <- filtered_points()
      pts <- pts[pts$corridor_id == cid, ]
      req(nrow(pts) > 0)

      tab <- table(factor(pts$risk_category, levels = c("Low","Moderate","High","Critical")))

      plotly::plot_ly(
        labels = names(tab), values = as.numeric(tab), type = "pie", hole = 0.55,
        marker = list(colors = RISK_SCALE_COLOURS),
        textinfo = "label+percent"
      ) |>
        plotly::layout(
          title = list(text = "Point Risk Distribution", font = list(size = 12)),
          showlegend = FALSE,
          margin = list(t = 30, b = 10)
        )
    })

    # ── Time of day chart ────────────────────────────────────────────────────
    output$time_of_day_chart <- plotly::renderPlotly({
      req(input$f_road_type)
      pts <- uk_osa_corridor_points[uk_osa_corridor_points$road_type %in% input$f_road_type, ]

      p <- plotly::plot_ly()
      for (g in names(OSA_GROUP_UPLIFT)) {
        vals <- sapply(TIME_WINDOWS, function(tw) {
          mean(osa_risk_score(pts$road_type, g, tw, input$f_duration %||% 2, pts$point_noise))
        })
        p <- plotly::add_trace(p, x = TIME_WINDOWS, y = round(vals, 1),
          type = "scatter", mode = "lines+markers", name = OSA_GROUP_LABELS[g],
          line = list(color = OSA_GROUP_COLOURS[g], width = 2.5),
          marker = list(color = OSA_GROUP_COLOURS[g]))
      }
      p |> plotly::layout(
        xaxis = list(title = "Time Window"),
        yaxis = list(title = "Mean Risk Score", range = c(0, 100), gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.3)
      )
    })

    # ── Road type chart ──────────────────────────────────────────────────────
    output$road_type_chart <- plotly::renderPlotly({
      req(input$f_time_window)
      rtypes <- names(ROAD_TYPE_LABELS)

      mat <- sapply(names(OSA_GROUP_UPLIFT), function(g) {
        sapply(rtypes, function(rt) {
          pts <- uk_osa_corridor_points[uk_osa_corridor_points$road_type == rt, ]
          mean(osa_risk_score(pts$road_type, g, input$f_time_window,
                               input$f_duration %||% 2, pts$point_noise))
        })
      })

      p <- plotly::plot_ly()
      for (g in names(OSA_GROUP_UPLIFT)) {
        p <- plotly::add_trace(p, x = ROAD_TYPE_LABELS[rtypes], y = round(mat[, g], 1),
          type = "bar", name = OSA_GROUP_LABELS[g], marker = list(color = OSA_GROUP_COLOURS[g]))
      }
      p |> plotly::layout(
        barmode = "group",
        xaxis = list(title = ""),
        yaxis = list(title = "Mean Risk Score", range = c(0, 100), gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.3)
      )
    })

  })
}
