# modules/DriveSafe/driver_road_risk/driver_road_risk_interventions/server.R
# Risk Interventions Server

driver_road_risk_interventions_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    all_roads <- names(ROAD_TYPE_LABELS)
    all_times <- TIME_WINDOWS

    treatment_uplift <- c(
      none             = 22,
      cpap_new         = 15,
      cpap_established = 6,
      mandibular       = 13
    )
    treatment_labels <- c(
      none             = "No Treatment",
      cpap_new         = "CPAP (Newly Started)",
      cpap_established = "CPAP (Established)",
      mandibular       = "Mandibular Device"
    )

    # Mean risk score across a set of road types / time windows for a given
    # uplift and duration - same underlying formula as osa_risk_score(),
    # generalised to accept an arbitrary uplift value.
    # Mean risk score across a set of road types / time windows for a given
    # uplift and duration - mirrors osa_risk_score() in utils_road_risk.R:
    # time-of-day only scales the fatigue-related component (uplift +
    # duration), not the static road-type risk.
    compute_score <- function(uplift, duration, road_types = all_roads,
                               time_windows = all_times,
                               break_reduction = 0, monitor_reduction = 0) {
      grid  <- expand.grid(road_type = road_types, time_window = time_windows,
                            stringsAsFactors = FALSE)
      base  <- ROAD_TYPE_BASE_RISK[grid$road_type]
      mult  <- TIME_WINDOW_MULT[grid$time_window]
      dur   <- pmin(pmax(duration, 0), 8) * 2.4
      score <- base + (uplift + dur) * mult
      score <- pmin(pmax(score, 2), 99)
      mean(score) - break_reduction - monitor_reduction
    }

    BASELINE_DURATION <- 5  # representative uncapped commercial driving stint

    # ── Reactive scenario computation ────────────────────────────────────────
    scenario <- reactive({
      uplift_sel <- treatment_uplift[[input$sc_treatment %||% "none"]]

      break_red   <- (input$sc_break_freq %||% 0) *
                      (3 + ((input$sc_break_dur %||% 15) / 30) * 5)
      monitor_red <- (isTRUE(input$sc_monthly_review)) * 3 +
                      (isTRUE(input$sc_telemetry)) * 4

      duration_sel <- if (isTRUE(input$sc_cap_journey)) 4 else BASELINE_DURATION
      roads_sel    <- if (isTRUE(input$sc_prefer_motorway)) "motorway" else all_roads
      times_sel    <- if (isTRUE(input$sc_avoid_night)) setdiff(all_times, c("00-06","18-24")) else all_times

      baseline_score <- compute_score(treatment_uplift[["none"]], BASELINE_DURATION)
      control_floor  <- compute_score(0, 4)

      treat_only_score <- compute_score(uplift_sel, BASELINE_DURATION)
      route_only_score <- compute_score(uplift_sel, duration_sel, roads_sel, times_sel)

      scenario_raw <- compute_score(uplift_sel, duration_sel, roads_sel, times_sel,
                                     break_red, monitor_red)
      scenario_score <- max(scenario_raw, control_floor)

      list(
        baseline        = round(baseline_score, 1),
        scenario        = round(scenario_score, 1),
        treat_delta     = treat_only_score - baseline_score,
        route_delta     = route_only_score - treat_only_score,
        break_delta     = -break_red,
        monitor_delta   = -monitor_red,
        control_floor   = round(control_floor, 1)
      )
    })

    # ── Gauges ────────────────────────────────────────────────────────────────
    make_gauge <- function(value, bar_colour) {
      plotly::plot_ly(
        type = "indicator", mode = "gauge+number", value = value,
        gauge = list(
          axis  = list(range = list(0, 100)),
          bar   = list(color = bar_colour),
          steps = list(
            list(range = c(0, 25),  color = "#1a6b35"),
            list(range = c(25, 50), color = "#d4ac0d"),
            list(range = c(50, 75), color = "#e67e22"),
            list(range = c(75, 100), color = "#c0392b")
          ),
          threshold = list(line = list(color = "black", width = 3),
                            thickness = 0.8, value = value)
        )
      ) |> plotly::layout(margin = list(t = 20, b = 10))
    }

    output$gauge_baseline <- plotly::renderPlotly({
      make_gauge(scenario()$baseline, "#e74c3c")
    })

    output$gauge_scenario <- plotly::renderPlotly({
      make_gauge(scenario()$scenario, "#27ae60")
    })

    # ── Waterfall ────────────────────────────────────────────────────────────
    output$waterfall_chart <- plotly::renderPlotly({
      s <- scenario()

      raw_deltas <- c(s$treat_delta, s$break_delta, s$route_delta, s$monitor_delta)
      target     <- s$scenario - s$baseline
      raw_sum    <- sum(raw_deltas)
      scaled <- if (raw_sum != 0) raw_deltas * (target / raw_sum) else raw_deltas

      plotly::plot_ly(
        type = "waterfall",
        x = c("Baseline", "Treatment", "Rest Breaks", "Route Optimisation",
              "Clinical Monitoring", "Scenario Total"),
        measure = c("absolute", "relative", "relative", "relative", "relative", "total"),
        y = c(s$baseline, scaled[1], scaled[2], scaled[3], scaled[4], 0),
        decreasing = list(marker = list(color = "#27ae60")),
        increasing = list(marker = list(color = "#e74c3c")),
        totals     = list(marker = list(color = "#008A82")),
        connector  = list(line = list(color = "#bbb"))
      ) |>
        plotly::layout(
          yaxis = list(title = "Risk Score (0-100)"),
          showlegend = FALSE
        )
    })

    # ── CPAP adherence trajectory ────────────────────────────────────────────
    traj_drivers <- data.frame(
      driver_id   = c("D002","D007","D004","D008"),
      driver_name = c("Patel, R (High Adherence)", "Thompson, K (High Adherence)",
                       "Williams, S (Moderate Adherence)", "Singh, P (Low Adherence)"),
      start       = c(68, 65, 72, 70),
      asymptote   = c(22, 24, 25, 42),
      k           = c(0.09, 0.075, 0.045, 0.03),
      stringsAsFactors = FALSE
    )

    trajectory_data <- reactive({
      weeks <- 1:52
      out <- lapply(seq_len(nrow(traj_drivers)), function(i) {
        d <- traj_drivers[i, ]
        set.seed(2000 + i)
        risk <- d$asymptote + (d$start - d$asymptote) * exp(-d$k * weeks) +
                rnorm(length(weeks), 0, 1.4)
        risk <- pmin(pmax(risk, 5), 95)
        data.frame(driver_id = d$driver_id, driver_name = d$driver_name,
                   week = weeks, risk = round(risk, 1), stringsAsFactors = FALSE)
      })
      do.call(rbind, out)
    })

    output$adherence_trajectory <- plotly::renderPlotly({
      td <- trajectory_data()
      wk <- input$traj_week %||% 12
      control_level <- round(compute_score(0, 4), 1)

      p <- plotly::plot_ly()
      driver_cols <- c("#008A82", "#3498db", "#f39c12", "#e74c3c")
      for (i in seq_along(traj_drivers$driver_id)) {
        did <- traj_drivers$driver_id[i]
        sub <- td[td$driver_id == did, ]
        p <- plotly::add_trace(p, x = sub$week, y = sub$risk, type = "scatter",
          mode = "lines", name = sub$driver_name[1],
          line = list(color = driver_cols[i], width = 2.5))
      }
      p <- plotly::add_segments(p, x = 1, xend = 52, y = control_level, yend = control_level,
        line = list(color = "#999", dash = "dash", width = 1.5),
        name = "Control Group Level", showlegend = TRUE)
      p <- plotly::add_segments(p, x = wk, xend = wk, y = 0, yend = 100,
        line = list(color = "#333", dash = "dot", width = 1.5),
        name = paste("Week", wk), showlegend = FALSE)

      p |> plotly::layout(
        xaxis  = list(title = "Week of CPAP Therapy", range = c(1, 52)),
        yaxis  = list(title = "Simulated Risk Score", range = c(0, 100), gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.3)
      )
    })

    output$traj_week_note <- renderUI({
      td <- trajectory_data()
      wk <- input$traj_week %||% 12
      snap <- td[td$week == wk, ]
      snap <- snap[order(snap$risk), ]

      div(class = "status-info",
        tags$strong(paste0("Week ", wk, " snapshot: ")),
        paste(sprintf("%s = %.0f (%s)", snap$driver_name, snap$risk, risk_category(snap$risk)),
              collapse = "  \u2022  ")
      )
    })

    # ── Action plan cards ────────────────────────────────────────────────────
    # Restricted to the OSA-flagged drivers (treated + untreated). Control
    # drivers are excluded here deliberately: this panel is specifically about
    # OSA risk management, and a non-OSA driver should never be able to land
    # in a tier recommending CPAP referral.
    driver_roster <- data.frame(
      driver_id   = c("D002","D004","D007","D008"),
      driver_name = c("Patel, R","Williams, S","Thompson, K","Singh, P"),
      osa_group   = c("osa_treated","osa_untreated","osa_treated","osa_untreated"),
      stringsAsFactors = FALSE
    )

    action_tiers <- list(
      list(name = "Critical", range = c(75, 100), colour = "#c0392b",
           action = "Immediate clinical referral for sleep study / CPAP titration. Temporarily reassign to non-safety-critical routes. Daily fatigue check-in until treatment is confirmed."),
      list(name = "High", range = c(50, 75), colour = "#e67e22",
           action = "Expedite CPAP titration and follow-up. Mandatory rest break every 2 hours. Avoid scheduling on night-window (00:00-06:00) routes."),
      list(name = "Moderate", range = c(25, 50), colour = "#d4ac0d",
           action = "Monitor CPAP adherence via telemetry. Monthly clinical review. Continue current route allocation with standard breaks."),
      list(name = "Low", range = c(0, 25), colour = "#1a6b35",
           action = "Routine annual review. No route restriction required. Maintain current treatment plan.")
    )

    output$action_plan_cards <- renderUI({
      set.seed(3001)
      roster <- driver_roster
      roster$current_risk <- round(
        sapply(roster$osa_group, function(g) compute_score(OSA_GROUP_UPLIFT[[g]], 4)) +
        rnorm(nrow(roster), 0, 4), 1)
      roster$current_risk <- pmin(pmax(roster$current_risk, 5), 95)

      cards <- lapply(action_tiers, function(tier) {
        in_tier <- roster[roster$current_risk >= tier$range[1] & roster$current_risk < tier$range[2] + ifelse(tier$range[2]==100,1,0), ]
        names_txt <- if (nrow(in_tier) == 0) "No drivers currently in this tier"
                     else paste(in_tier$driver_name, collapse = ", ")

        column(3,
          div(style = paste0("border-left:5px solid ", tier$colour,
                              "; background:#fff; border-radius:8px; padding:12px 14px; ",
                              "margin-bottom:10px; box-shadow:0 2px 6px rgba(0,0,0,0.08); min-height:230px;"),
            tags$h5(tags$span(style = paste0("color:", tier$colour, "; font-weight:800;"), tier$name),
                    style = "margin-top:0;"),
            tags$p(style = "font-size:11px; color:#888; margin-bottom:6px;",
                   paste0("Score ", tier$range[1], "-", tier$range[2])),
            tags$p(style = "font-size:12px;", tags$strong("Drivers: "), names_txt),
            tags$p(style = "font-size:12px;", tier$action)
          )
        )
      })
      fluidRow(cards)
    })

    # ── Fleet-level projection ───────────────────────────────────────────────
    fleet_calc <- reactive({
      fleet_size <- input$fleet_size %||% 150
      prevalence <- (input$fleet_prevalence %||% 15) / 100
      uptake     <- (input$fleet_uptake %||% 60) / 100

      n_osa       <- round(fleet_size * prevalence)
      n_treated   <- round(n_osa * uptake)
      n_untreated <- n_osa - n_treated
      n_control   <- fleet_size - n_osa

      control_score   <- compute_score(OSA_GROUP_UPLIFT[["control"]], 4)
      treated_score   <- compute_score(OSA_GROUP_UPLIFT[["osa_treated"]], 4)
      untreated_score <- compute_score(OSA_GROUP_UPLIFT[["osa_untreated"]], 4)

      risk_before <- (n_control * control_score + n_osa * untreated_score) / fleet_size
      risk_after  <- (n_control * control_score + n_treated * treated_score +
                       n_untreated * untreated_score) / fleet_size

      p_high <- function(score) 1 - pnorm(50, mean = score, sd = 12)
      journeys_before <- n_osa * 20 * p_high(untreated_score)
      journeys_after  <- n_treated * 20 * p_high(treated_score) +
                          n_untreated * 20 * p_high(untreated_score)

      list(
        fleet_size = fleet_size, n_osa = n_osa, n_treated = n_treated,
        n_untreated = n_untreated, n_control = n_control,
        risk_before = round(risk_before, 1), risk_after = round(risk_after, 1),
        journeys_before = round(journeys_before), journeys_after = round(journeys_after)
      )
    })

    output$fleet_osa_drivers <- renderValueBox({
      f <- fleet_calc()
      valueBox(f$n_osa, paste0("OSA Drivers in Fleet (of ", f$fleet_size, ")"),
                icon = icon("users"), color = "aqua")
    })

    output$fleet_risk_reduction <- renderValueBox({
      f <- fleet_calc()
      delta <- round(f$risk_before - f$risk_after, 1)
      valueBox(paste0("-", delta, " pts"), "Fleet Mean Risk Reduction",
                icon = icon("chart-line"),
                color = if (delta >= 8) "green" else if (delta >= 3) "yellow" else "red")
    })

    output$fleet_journeys_saved <- renderValueBox({
      f <- fleet_calc()
      saved <- max(0, f$journeys_before - f$journeys_after)
      valueBox(round(saved), "Est. High-Risk Journeys Avoided / Month",
                icon = icon("shield-halved"), color = "green")
    })

    output$fleet_projection_chart <- plotly::renderPlotly({
      f <- fleet_calc()
      plotly::plot_ly(
        x = c("Before CPAP Uptake", paste0("After ", input$fleet_uptake %||% 60, "% Uptake")),
        y = c(f$risk_before, f$risk_after),
        type = "bar",
        marker = list(color = c("#e74c3c", "#27ae60")),
        text = c(f$risk_before, f$risk_after), textposition = "outside"
      ) |>
        plotly::layout(
          yaxis = list(title = "Mean Fleet Risk Score (0-100)", range = c(0, 100)),
          xaxis = list(title = ""),
          showlegend = FALSE
        )
    })

  })
}
