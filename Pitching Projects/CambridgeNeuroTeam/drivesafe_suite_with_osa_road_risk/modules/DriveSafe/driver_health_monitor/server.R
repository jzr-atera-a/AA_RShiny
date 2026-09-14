# modules/DriveSafe/driver_health_monitor/server.R
# DriveSafe - Driver Health Monitor Server

driver_health_monitor_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Colour palette consistent with teal theme ───────────────────────────
    teal_dark  <- "#002C3C"
    teal_mid   <- "#008A82"
    teal_light <- "#00A39A"
    amber      <- "#f39c12"
    red_alert  <- "#e74c3c"
    green_ok   <- "#27ae60"
    blue_info  <- "#3498db"

    driver_names <- c(
      "all"  = "All Drivers",
      "D001" = "Adams, J",  "D002" = "Patel, R",
      "D003" = "Okafor, C", "D004" = "Williams, S",
      "D005" = "Hassan, M", "D006" = "Chen, L",
      "D007" = "Thompson, K","D008" = "Singh, P"
    )

    # ── Simulate rich driver data ────────────────────────────────────────────
    sim_data <- reactive({
      input$refresh_all
      set.seed(42)
      n <- 200
      drivers  <- paste0("D00", rep(1:8, each = ceiling(n / 8)))[1:n]
      hours    <- round(runif(n, 0, 8), 1)
      osa_flag <- drivers %in% c("D002", "D004", "D007")   # OSA group
      treated  <- drivers %in% c("D002", "D007")            # receiving CPAP

      kss   <- pmax(1, pmin(9, 3 + hours * 0.6 +
                              ifelse(osa_flag & !treated, 1.8, 0) +
                              rnorm(n, 0, 0.7)))
      rt    <- pmax(200, 320 + hours * 18 +
                          ifelse(osa_flag & !treated, 65, 0) + rnorm(n, 0, 30))
      mw    <- pmax(0, pmin(100, 20 + hours * 7 +
                              ifelse(osa_flag & !treated, 20, 0) + rnorm(n, 0, 8)))
      effort<- pmax(0, pmin(100, 30 + hours * 5 + rnorm(n, 0, 10)))
      speed_var  <- pmax(0, 8  + hours * 1.2 +
                              ifelse(osa_flag & !treated, 4, 0) + rnorm(n, 0, 2))
      hard_brake <- pmax(0, round(0.5 + hours * 0.4 +
                              ifelse(osa_flag & !treated, 0.8, 0) + rnorm(n, 0, 0.5)))
      lane_event <- pmax(0, round(0.2 + hours * 0.3 +
                              ifelse(osa_flag & !treated, 0.6, 0) + rnorm(n, 0, 0.3)))
      lateral_var<- pmax(0, 0.4 + hours * 0.05 +
                              ifelse(osa_flag & !treated, 0.3, 0) + rnorm(n, 0, 0.1))
      osa_composite <- pmax(0, pmin(100,
                            (kss / 9) * 30 + (rt - 200) / 800 * 30 +
                            lateral_var / 1.5 * 20 + speed_var / 20 * 20 +
                            rnorm(n, 0, 3)))
      sleep_q <- pmax(1, pmin(10, 7 - ifelse(osa_flag & !treated, 2.5, 0) + rnorm(n, 0, 1)))
      day_of_week <- sample(c("Mon","Tue","Wed","Thu","Fri","Sat","Sun"), n, replace = TRUE)
      hour_of_day <- sample(0:23, n, replace = TRUE)

      # Derive string group labels used by all downstream plots
      osa_group_str <- ifelse(!osa_flag, "control",
                       ifelse(treated,   "osa_treated",
                                         "osa_untreated"))

      data.frame(
        driver_id = drivers, journey_hour = hours, kss = kss,
        reaction_time = rt, mind_wander = mw, effort = effort,
        speed_variance = speed_var, hard_braking = hard_brake,
        lane_events = lane_event, lateral_variance = lateral_var,
        osa_composite = osa_composite, sleep_quality = sleep_q,
        osa_group = osa_group_str, treated = treated,
        day_of_week = day_of_week, hour_of_day = hour_of_day,
        stringsAsFactors = FALSE
      )
    })

    filtered_data <- reactive({
      d <- sim_data()
      if (!is.null(input$selected_driver) && input$selected_driver != "all")
        d <- d[d$driver_id == input$selected_driver, ]
      d
    })

    # ── KPI Value Boxes ──────────────────────────────────────────────────────
    output$kpi_alertness <- renderValueBox({
      d <- filtered_data()
      val <- round(mean(d$kss, na.rm = TRUE), 1)
      col <- if (val <= 4) "green" else if (val <= 6) "yellow" else "red"
      valueBox(val, "Mean KSS Alertness", icon = icon("eye"), color = col)
    })

    output$kpi_fatigue <- renderValueBox({
      d <- filtered_data()
      pct <- round(mean(d$kss >= 7, na.rm = TRUE) * 100)
      col <- if (pct < 15) "green" else if (pct < 30) "yellow" else "red"
      valueBox(paste0(pct, "%"), "High Fatigue Events", icon = icon("battery-quarter"), color = col)
    })

    output$kpi_osa_risk <- renderValueBox({
      d <- filtered_data()
      val <- round(mean(d$osa_composite, na.rm = TRUE), 1)
      col <- if (val < 30) "green" else if (val < 55) "yellow" else "red"
      valueBox(val, "OSA Risk Score (0-100)", icon = icon("bed"), color = col)
    })

    output$kpi_reaction <- renderValueBox({
      d <- filtered_data()
      val <- round(mean(d$reaction_time, na.rm = TRUE))
      col <- if (val < 380) "green" else if (val < 470) "yellow" else "red"
      valueBox(paste0(val, " ms"), "Mean Reaction Time", icon = icon("bolt"), color = col)
    })

    # ── Alert Banner ─────────────────────────────────────────────────────────
    output$alert_banner <- renderUI({
      d <- filtered_data()
      high_kss <- sum(d$kss >= 7, na.rm = TRUE)
      if (high_kss >= 10) {
        div(class = "status-error",
          icon("exclamation-triangle"),
          tags$strong(" Attention: "),
          paste0(high_kss, " high-fatigue events detected in current selection. ",
                 "Consider scheduling rest breaks or reviewing roster patterns.")
        )
      } else if (high_kss >= 3) {
        div(class = "status-warning",
          icon("exclamation-circle"),
          tags$strong(" Advisory: "),
          paste0(high_kss, " elevated fatigue events noted. ",
                 "Monitor affected drivers over the next shift window.")
        )
      } else {
        div(class = "status-success",
          icon("check-circle"),
          tags$strong(" Fleet Status: "),
          "No critical fatigue alerts in the current driver selection."
        )
      }
    })

    # ── SUBTAB 1: Live Overview ───────────────────────────────────────────────
    output$alertness_timeline <- plotly::renderPlotly({
      d <- sim_data()
      hour_val <- input$journey_hour %||% 2

      drivers_to_show <- c("D001","D002","D003","D004")
      cols <- c(teal_mid, red_alert, green_ok, amber)
      hrs  <- seq(0, 8, by = 0.25)

      set.seed(99)
      p <- plotly::plot_ly()
      for (i in seq_along(drivers_to_show)) {
        did   <- drivers_to_show[i]
        osa   <- did %in% c("D002","D004","D007")
        treated <- did == "D002"
        kss_vals <- pmax(1, pmin(9,
          3 + hrs * 0.6 +
          ifelse(osa & !treated, 1.8, 0) +
          cumsum(rnorm(length(hrs), 0, 0.18))
        ))
        p <- plotly::add_trace(p, x = hrs, y = kss_vals,
          type = "scatter", mode = "lines+markers",
          name = driver_names[did],
          line = list(color = cols[i], width = 2),
          marker = list(size = 4, color = cols[i])
        )
      }
      p <- plotly::add_segments(p,
        x = hour_val, xend = hour_val, y = 1, yend = 9,
        line = list(color = teal_dark, dash = "dash", width = 1.5),
        name = "Current Hour", showlegend = FALSE
      )
      p <- plotly::layout(p,
        xaxis = list(title = "Journey Hour", gridcolor = "#eee"),
        yaxis = list(title = "KSS Score (1=Alert, 9=Very Sleepy)", range = c(1, 9),
                     gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.25),
        plot_bgcolor  = "#fff", paper_bgcolor = "#fff",
        hovermode = "x unified"
      )
      p
    })

    output$risk_summary_cards <- renderUI({
      d  <- filtered_data()
      jh <- input$journey_hour %||% 2
      near <- d[abs(d$journey_hour - jh) < 0.75, ]
      if (nrow(near) == 0) near <- d

      mk <- function(label, val, status) {
        col <- switch(status,
          ok      = "#d4edda", warn = "#fff3cd", danger = "#f8d7da")
        border <- switch(status,
          ok = green_ok, warn = amber, danger = red_alert)
        div(style = paste0("background:", col, "; border-left: 4px solid ", border,
                           "; border-radius:8px; padding:10px; margin-bottom:8px;"),
          tags$strong(label), br(),
          tags$span(style = "font-size:1.3em; font-weight:bold;", val)
        )
      }

      kss_v  <- round(mean(near$kss,           na.rm = TRUE), 1)
      rt_v   <- round(mean(near$reaction_time, na.rm = TRUE))
      mw_v   <- round(mean(near$mind_wander,   na.rm = TRUE))
      osa_v  <- round(mean(near$osa_composite, na.rm = TRUE), 1)

      tagList(
        mk("KSS Alertness",      kss_v, if (kss_v <= 4) "ok" else if (kss_v <= 6) "warn" else "danger"),
        mk("Reaction Time (ms)", rt_v,  if (rt_v  < 380) "ok" else if (rt_v  < 470) "warn" else "danger"),
        mk("Mind Wandering",     paste0(mw_v, "%"), if (mw_v < 35) "ok" else if (mw_v < 60) "warn" else "danger"),
        mk("OSA Risk Score",     osa_v, if (osa_v < 30) "ok" else if (osa_v < 55) "warn" else "danger")
      )
    })

    output$radar_chart <- plotly::renderPlotly({
      d <- filtered_data()
      jh <- input$journey_hour %||% 2
      near <- d[abs(d$journey_hour - jh) < 1, ]
      if (nrow(near) == 0) near <- d

      norm <- function(x, lo, hi) pmax(0, pmin(100, (x - lo) / (hi - lo) * 100))

      cats <- c("Alertness","Reaction","Focus","Consistency","OSA Safety","Alertness")
      vals <- c(
        100 - norm(mean(near$kss,             na.rm = TRUE), 1, 9),
        100 - norm(mean(near$reaction_time,   na.rm = TRUE), 200, 700),
        100 - norm(mean(near$mind_wander,     na.rm = TRUE), 0, 100),
        100 - norm(mean(near$speed_variance,  na.rm = TRUE), 0, 25),
        100 - norm(mean(near$osa_composite,   na.rm = TRUE), 0, 100),
        100 - norm(mean(near$kss,             na.rm = TRUE), 1, 9)
      )

      plotly::plot_ly(type = "scatterpolar", mode = "lines+markers",
        r = vals, theta = cats, fill = "toself",
        fillcolor = paste0(teal_light, "40"),
        line = list(color = teal_mid, width = 2),
        marker = list(color = teal_mid, size = 6)
      ) |>
        plotly::layout(
          polar = list(
            radialaxis = list(visible = TRUE, range = c(0, 100), gridcolor = "#ddd"),
            angularaxis = list(gridcolor = "#ddd")
          ),
          paper_bgcolor = "#fff",
          showlegend = FALSE,
          margin = list(t = 10, b = 10, l = 30, r = 30)
        )
    })

    output$behaviour_chart <- plotly::renderPlotly({
      d <- filtered_data()
      jh_seq  <- seq(0, 8, by = 0.5)
      set.seed(7)
      speed_v <- pmax(0, 8 + jh_seq * 1.2 + rnorm(length(jh_seq), 0, 1.5))
      brake_v <- pmax(0, 0.5 + jh_seq * 0.4 + rnorm(length(jh_seq), 0, 0.3))
      lane_v  <- pmax(0, 0.2 + jh_seq * 0.3 + rnorm(length(jh_seq), 0, 0.2))

      plotly::plot_ly() |>
        plotly::add_trace(x = jh_seq, y = speed_v, name = "Speed Variance (km/h)",
          type = "scatter", mode = "lines+markers",
          line = list(color = teal_mid, width = 2), yaxis = "y") |>
        plotly::add_trace(x = jh_seq, y = brake_v, name = "Hard Braking Events",
          type = "bar", marker = list(color = paste0(amber, "bb")), yaxis = "y2") |>
        plotly::add_trace(x = jh_seq, y = lane_v, name = "Lane Departure Events",
          type = "bar", marker = list(color = paste0(red_alert, "99")), yaxis = "y2") |>
        plotly::layout(
          xaxis  = list(title = "Journey Hour", gridcolor = "#eee"),
          yaxis  = list(title = "Speed Variance", gridcolor = "#eee", side = "left"),
          yaxis2 = list(title = "Event Count", overlaying = "y", side = "right",
                        gridcolor = "#eee"),
          barmode = "group",
          legend = list(orientation = "h", y = -0.3),
          plot_bgcolor = "#fff", paper_bgcolor = "#fff",
          hovermode = "x unified"
        )
    })

    # ── SUBTAB 2: Alertness and Fatigue ──────────────────────────────────────
    output$fleet_mean_kss <- renderText({
      round(mean(filtered_data()$kss, na.rm = TRUE), 2)
    })

    output$high_fatigue_count <- renderText({
      sum(filtered_data()$kss >= 7, na.rm = TRUE)
    })

    output$fatigue_trend <- plotly::renderPlotly({
      metric <- input$fatigue_metric %||% "kss"
      d <- filtered_data()

      label_map <- c(
        kss      = "KSS Alertness Score (1-9)",
        mind_wander = "Mind Wandering Index (0-100)",
        effort   = "Perceived Effort Score (0-100)",
        reaction = "Reaction Time Deviation (ms)"
      )
      col_map <- c(kss = teal_mid, mind_wander = amber,
                   effort = blue_info, reaction = red_alert)
      y_col <- switch(metric,
        kss = "kss", mind_wander = "mind_wander",
        effort = "effort", reaction = "reaction_time"
      )

      plotly::plot_ly(d, x = ~journey_hour, y = as.formula(paste0("~", y_col)),
        color = ~driver_id, type = "scatter", mode = "markers",
        marker = list(size = 6, opacity = 0.7)
      ) |>
        plotly::layout(
          xaxis = list(title = "Journey Hour", gridcolor = "#eee"),
          yaxis = list(title = label_map[metric], gridcolor = "#eee"),
          legend = list(orientation = "h", y = -0.25),
          plot_bgcolor = "#fff", paper_bgcolor = "#fff",
          hovermode = "closest"
        )
    })

    output$fatigue_distribution <- plotly::renderPlotly({
      d <- sim_data()
      d$fatigue_cat <- cut(d$kss,
        breaks = c(0, 3, 5, 7, 9),
        labels = c("Alert (1-3)", "Moderate (4-5)", "Tired (6-7)", "High Risk (8-9)"),
        include.lowest = TRUE)
      tab <- as.data.frame(table(d$driver_id, d$fatigue_cat))
      names(tab) <- c("driver", "category", "count")

      cols_cat <- c("#27ae60","#f39c12","#e67e22","#e74c3c")

      plotly::plot_ly(tab, x = ~driver, y = ~count, color = ~category,
        colors = cols_cat, type = "bar"
      ) |>
        plotly::layout(
          barmode = "stack",
          xaxis = list(title = "Driver"),
          yaxis = list(title = "Event Count"),
          legend = list(orientation = "h", y = -0.35),
          plot_bgcolor = "#fff", paper_bgcolor = "#fff"
        )
    })

    output$alertness_heatmap <- plotly::renderPlotly({
      d <- sim_data()
      dow_order <- c("Mon","Tue","Wed","Thu","Fri","Sat","Sun")
      d$day_of_week <- factor(d$day_of_week, levels = dow_order)
      agg <- aggregate(kss ~ hour_of_day + day_of_week, data = d, FUN = mean)

      pivot_mat <- reshape(agg, idvar = "hour_of_day",
        timevar = "day_of_week", direction = "wide")
      mat_cols <- paste0("kss.", dow_order)
      mat_cols <- mat_cols[mat_cols %in% names(pivot_mat)]
      mat <- as.matrix(pivot_mat[, mat_cols])

      plotly::plot_ly(
        x = dow_order, y = pivot_mat$hour_of_day,
        z = mat, type = "heatmap",
        colorscale = list(
          list(0, "#27ae60"), list(0.4, "#f39c12"),
          list(0.7, "#e67e22"), list(1, "#e74c3c")
        ),
        colorbar = list(title = "KSS")
      ) |>
        plotly::layout(
          xaxis = list(title = "Day of Week"),
          yaxis = list(title = "Hour of Day"),
          paper_bgcolor = "#fff"
        )
    })

    # ── SUBTAB 3: Sleep and OSA ───────────────────────────────────────────────
    output$osa_indicators_plot <- plotly::renderPlotly({
      d        <- sim_data()
      selected <- input$osa_indicators
      if (is.null(selected) || length(selected) == 0)
        selected <- c("eds", "osa_composite")

      metric_map <- list(
        eds               = list(col = "kss",             label = "EDS (KSS Score)"),
        speed_consistency = list(col = "speed_variance",  label = "Speed Consistency Index"),
        lateral           = list(col = "lateral_variance",label = "Lateral Position Variance"),
        osa_composite     = list(col = "osa_composite",   label = "OSA Risk Score (Composite)")
      )

      # Group styling: one palette per OSA group so multiple metrics stay readable
      group_labels <- c(
        osa_untreated = "OSA - Untreated",
        osa_treated   = "OSA - Treated (CPAP)",
        control       = "Control"
      )
      group_cols <- c(
        osa_untreated = red_alert,
        osa_treated   = green_ok,
        control       = teal_mid
      )
      group_dash <- c(
        osa_untreated = "solid",
        osa_treated   = "dash",
        control       = "dot"
      )

      # Metric line styles (width + symbol) so groups within same metric are distinct
      metric_widths  <- c(2.5, 2, 1.5, 2)
      metric_symbols <- c("circle", "square", "diamond", "triangle-up")

      # Bin journey hours into 0.5-h windows and compute group mean per bin
      # Clamp to [0, 8] first so no value falls outside the breaks
      hr_breaks <- seq(0, 8, by = 0.5)
      hr_mids   <- hr_breaks[-length(hr_breaks)] + 0.25
      jh_clamped  <- pmin(pmax(d$journey_hour, 0), 7.99)
      bin_idx     <- findInterval(jh_clamped, hr_breaks, rightmost.closed = TRUE)
      bin_idx[bin_idx < 1]                <- 1L
      bin_idx[bin_idx > length(hr_mids)]  <- length(hr_mids)
      d$hr_bin <- hr_mids[bin_idx]

      osa_groups <- c("osa_untreated", "osa_treated", "control")
      p <- plotly::plot_ly()

      for (mi in seq_along(selected)) {
        key  <- selected[mi]
        meta <- metric_map[[key]]
        if (is.null(meta)) next

        for (grp in osa_groups) {
          sub <- d[d$osa_group == grp, ]
          if (nrow(sub) == 0) next

          agg <- aggregate(sub[[meta$col]] ~ sub$hr_bin, FUN = mean, na.rm = TRUE)
          names(agg) <- c("hr", "val")
          agg <- agg[order(agg$hr), ]

          # Unique name per metric+group combination for legend
          trace_name <- if (length(selected) == 1)
            group_labels[grp]
          else
            paste0(meta$label, " - ", group_labels[grp])

          p <- plotly::add_trace(p,
            x    = agg$hr,
            y    = round(agg$val, 2),
            type = "scatter",
            mode = "lines+markers",
            name = trace_name,
            line = list(
              color = group_cols[grp],
              width = metric_widths[mi],
              dash  = group_dash[grp]
            ),
            marker = list(
              color  = group_cols[grp],
              size   = 7,
              symbol = metric_symbols[mi],
              line   = list(color = "#ffffff", width = 1)
            ),
            hovertemplate = paste0(
              "<b>", trace_name, "</b><br>",
              "Journey Hour: %{x:.1f}h<br>",
              "Value: %{y:.2f}<extra></extra>"
            )
          )
        }
      }

      p |> plotly::layout(
        xaxis  = list(title = "Journey Hour", gridcolor = "#eee",
                      range = c(0, 8.2), dtick = 1),
        yaxis  = list(title = "Indicator Value", gridcolor = "#eee", rangemode = "tozero"),
        legend = list(orientation = "h", y = -0.35, font = list(size = 11)),
        plot_bgcolor  = "#fff",
        paper_bgcolor = "#fff",
        hovermode     = "x unified",
        margin        = list(b = 90)
      )
    })

    output$osa_risk_pie <- plotly::renderPlotly({
      d <- sim_data()
      d$risk_cat <- ifelse(d$osa_composite < 30, "Low Risk",
                    ifelse(d$osa_composite < 55, "Moderate Risk", "High Risk"))
      tab <- as.data.frame(table(d$risk_cat))

      plotly::plot_ly(tab, labels = ~Var1, values = ~Freq, type = "pie",
        marker = list(colors = c("#27ae60","#f39c12","#e74c3c")),
        textinfo = "label+percent",
        hovertemplate = "%{label}: %{value} drivers<extra></extra>"
      ) |>
        plotly::layout(
          paper_bgcolor = "#fff",
          showlegend = TRUE,
          legend = list(orientation = "h", y = -0.2)
        )
    })

    output$sleep_vs_performance <- plotly::renderPlotly({
      d <- sim_data()
      # Named colour vector keyed to the three string group labels
      grp_cols <- c(
        control       = teal_mid,
        osa_treated   = green_ok,
        osa_untreated = red_alert
      )
      plotly::plot_ly(d, x = ~sleep_quality, y = ~reaction_time,
        color  = ~osa_group,
        colors = grp_cols,
        type   = "scatter", mode = "markers",
        marker = list(size = 7, opacity = 0.65),
        text   = ~paste0("Driver: ", driver_id,
                         "<br>Group: ", osa_group,
                         "<br>Sleep Quality: ", round(sleep_quality, 1),
                         "<br>Reaction Time: ", round(reaction_time), " ms"),
        hovertemplate = "%{text}<extra></extra>"
      ) |>
        plotly::layout(
          xaxis  = list(title = "Sleep Quality Score (1-10)", gridcolor = "#eee"),
          yaxis  = list(title = "Reaction Time (ms)", gridcolor = "#eee"),
          legend = list(title = list(text = "OSA Group"), orientation = "h", y = -0.3),
          plot_bgcolor = "#fff", paper_bgcolor = "#fff"
        )
    })

    # ── SUBTAB 4: Cognitive Performance ──────────────────────────────────────
    cog_data <- reactive({
      d <- sim_data()
      flt <- input$cog_driver_filter %||% "all"
      if (flt != "all") d <- d[d$driver_id == flt, ]
      d
    })

    output$mean_rt <- renderText({
      paste0(round(mean(cog_data()$reaction_time, na.rm = TRUE)), " ms")
    })

    output$pvt_lapses <- renderText({
      thresh <- input$pvt_threshold %||% 500
      sum(cog_data()$reaction_time > thresh, na.rm = TRUE)
    })

    output$pvt_distribution <- plotly::renderPlotly({
      d     <- cog_data()
      thresh <- input$pvt_threshold %||% 500

      plotly::plot_ly(d, x = ~reaction_time, type = "histogram",
        marker = list(
          color = ifelse(d$reaction_time > thresh,
                         paste0(red_alert, "cc"),
                         paste0(teal_mid, "cc")),
          line  = list(color = "#fff", width = 0.5)
        ),
        nbinsx = 40
      ) |>
        plotly::add_segments(
          x = thresh, xend = thresh, y = 0, yend = 30,
          line = list(color = red_alert, dash = "dash", width = 2),
          name = paste0("Lapse Threshold (", thresh, " ms)")
        ) |>
        plotly::layout(
          xaxis = list(title = "Reaction Time (ms)", gridcolor = "#eee"),
          yaxis = list(title = "Frequency",           gridcolor = "#eee"),
          showlegend = FALSE,
          plot_bgcolor = "#fff", paper_bgcolor = "#fff",
          annotations = list(list(
            x = thresh + 20, y = 25, text = paste0("Lapse > ", thresh, " ms"),
            showarrow = FALSE, font = list(color = red_alert, size = 11),
            xanchor = "left"
          ))
        )
    })

    output$cog_load_journey <- plotly::renderPlotly({
      d <- cog_data()
      hrs <- seq(0, 8, by = 0.5)
      set.seed(55)
      cog_load <- pmax(0, pmin(100,
        25 + hrs * 6 + cumsum(rnorm(length(hrs), 0, 2))
      ))
      plotly::plot_ly(x = hrs, y = cog_load,
        type = "scatter", mode = "lines",
        fill = "tozeroy",
        fillcolor = paste0(teal_light, "33"),
        line = list(color = teal_mid, width = 2.5)
      ) |>
        plotly::layout(
          xaxis = list(title = "Journey Hour", gridcolor = "#eee"),
          yaxis = list(title = "Cognitive Load Index (0-100)", gridcolor = "#eee",
                       range = c(0, 100)),
          plot_bgcolor = "#fff", paper_bgcolor = "#fff",
          showlegend = FALSE
        )
    })

    output$lapse_by_driver <- plotly::renderPlotly({
      d     <- sim_data()
      thresh <- input$pvt_threshold %||% 500
      d$lapse <- d$reaction_time > thresh
      agg <- aggregate(lapse ~ driver_id, data = d, FUN = sum)
      agg <- agg[order(-agg$lapse), ]

      cols_bar <- ifelse(agg$lapse > 15, red_alert,
                   ifelse(agg$lapse > 8, amber, teal_mid))

      plotly::plot_ly(agg, x = ~driver_id, y = ~lapse,
        type = "bar",
        marker = list(color = cols_bar,
                      line = list(color = "#fff", width = 0.5))
      ) |>
        plotly::layout(
          xaxis = list(title = "Driver", categoryorder = "array",
                       categoryarray = agg$driver_id),
          yaxis = list(title = "Lapse Events (30 days)", gridcolor = "#eee"),
          plot_bgcolor = "#fff", paper_bgcolor = "#fff",
          showlegend = FALSE
        )
    })

  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
