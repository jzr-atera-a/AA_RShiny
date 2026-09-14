# modules/Maternal Health Monitor/maternal_health_monitor/server.R

maternal_health_monitor_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 1 — CONTINUITY GAP TIMELINE
    # ════════════════════════════════════════════════════════════════════

    output$journey_track <- renderUI({
      stages <- c("Pregnancy", "Birth", "Postnatal", "Return to Work")
      # Deep-blue -> bright-blue progression, matching the app palette
      stage_colours <- c("#0a1128", "#1e3c72", "#2a5298", "#4a90e2")

      dot <- function(active, label = NULL) {
        col <- if (active) "#27ae60" else "rgba(255,255,255,0.18)"
        title_attr <- if (!is.null(label)) label else ""
        tags$span(title = title_attr, style = paste0(
          "display:inline-block; width:14px; height:14px; border-radius:50%; ",
          "background:", col, "; margin:2px; box-shadow:", if (active) "0 0 4px rgba(39,174,96,0.6);" else "none;"))
      }

      baby_dots <- list(rep(TRUE, 3), TRUE, rep(TRUE, 5), rep(TRUE, 4))
      mother_dots <- list(
        rep(TRUE, 3),                               # antenatal appointments
        TRUE,                                        # delivery care
        c(TRUE, FALSE, FALSE, FALSE, FALSE),          # ONE check at 6-8 weeks, then silence
        c(FALSE, FALSE, FALSE, FALSE)                 # silence through return to work
      )

      rows <- lapply(seq_along(stages), function(i) {
        column(3,
          div(style = paste0("background:", stage_colours[i], "; border-radius:6px; padding:8px; text-align:center; margin-bottom:6px; box-shadow:0 2px 8px rgba(0,0,0,0.25);"),
            tags$strong(style="color:#fff; font-size:12px;", stages[i])),
          div(style="text-align:center; margin-bottom:4px;",
            tags$small(style="color:rgba(255,255,255,0.55);", "Baby"), tags$br(),
            lapply(baby_dots[[i]], dot)),
          div(style="text-align:center;",
            tags$small(style="color:rgba(255,255,255,0.55);", "Mother"), tags$br(),
            lapply(mother_dots[[i]], dot))
        )
      })

      fluidRow(rows)
    })

    output$touchpoint_density_plot <- plotly::renderPlotly({
      stages <- c("Pregnancy", "Birth", "Postnatal", "Return to Work")
      baby_counts   <- c(3, 1, 5, 4)
      mother_counts <- c(3, 1, 1, 0)

      plotly::plot_ly() %>%
        plotly::add_trace(x = stages, y = baby_counts, type = "bar", name = "Baby touchpoints",
                           marker = list(color = "#4a90e2", line = list(color = "#2a5298", width = 1)),
                           text = baby_counts, textposition = "outside",
                           hovertemplate = "<b>%{x}</b><br>Baby touchpoints: %{y}<extra></extra>") %>%
        plotly::add_trace(x = stages, y = mother_counts, type = "bar", name = "Mother touchpoints",
                           marker = list(color = "#667eea", line = list(color = "#764ba2", width = 1)),
                           text = mother_counts, textposition = "outside",
                           hovertemplate = "<b>%{x}</b><br>Mother touchpoints: %{y}<extra></extra>") %>%
        apply_plotly_theme(x_title = "", y_title = "Structured touchpoints", barmode = "group") %>%
        plotly::layout(bargap = 0.35)
    })

    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 2 — INTELLIGENCE LAYER & INTERVENTIONS
    # ════════════════════════════════════════════════════════════════════

    signal_info <- list(
      mood = list(desc = "Daily/weekly mood check-ins feed 14-day mood-variance tracking - the second-largest weighted contributor to the early-warning composite score.",
                  outputs = c("Early detection", "Clinical screening")),
      bp = list(desc = "Blood pressure readings support physical postnatal-recovery monitoring alongside mental-health context, feeding clinical screening.",
                outputs = c("Clinical screening", "Personalised guidance")),
      sleep = list(desc = "Sleep tracking (fragmentation, duration) is the single largest weighted signal in the composite risk score.",
                   outputs = c("Early detection")),
      symptoms = list(desc = "Free-text and structured symptom logs are safeguarding-filtered before any AI summarisation, then feed clinical screening.",
                       outputs = c("Clinical screening", "Early detection")),
      care_history = list(desc = "Clinical and obstetric history contextualises risk thresholds so the model compares each mother to her own baseline, not a population average.",
                           outputs = c("Personalised guidance", "Clinical screening")),
      work_context = list(desc = "Return-to-work timing and workplace support context feed the anonymised, aggregate employer-insights layer - never raw individual data.",
                           outputs = c("Anonymised employer insights"))
    )

    output$signal_detail <- renderUI({
      req(input$signal_select)
      info <- signal_info[[input$signal_select]]
      div(class = "mint-card",
        p(style="font-size:12.5px; margin-bottom:8px;", info$desc),
        tags$strong(style="font-size:11px; color:#ffffff;", "Feeds: "),
        lapply(info$outputs, function(o) tags$span(class="risk-badge", style="background:linear-gradient(135deg,#667eea 0%,#764ba2 100%); margin-right:4px;", o))
      )
    })

    output$digital_twin_diagram <- renderUI({
      inputs <- c("Mood", "Blood pressure", "Sleep", "Symptoms", "Care history", "Work & support context")
      input_icons <- c("smile", "heartbeat", "moon", "notes-medical", "file-medical-alt", "briefcase")
      outputs <- c("Early detection", "Personalised guidance", "Clinical screening", "Anonymised employer insights")
      output_icons <- c("search", "user-md", "stethoscope", "chart-bar")

      fluidRow(
        column(4,
          lapply(seq_along(inputs), function(i)
            div(style="background:rgba(255,255,255,0.08); border-left:3px solid #4a90e2; border-radius:6px; padding:7px 10px; margin-bottom:6px; color:#e0e7ff; font-size:12px;",
                icon(input_icons[i]), " ", inputs[i]))
        ),
        column(4, style="text-align:center;",
          div(style="background:radial-gradient(circle, #667eea 0%, #0a1128 100%); border-radius:50%; width:160px; height:160px; margin:0 auto; display:flex; align-items:center; justify-content:center; color:#fff; font-weight:700; font-size:13px; padding:14px; box-shadow:0 6px 24px rgba(102,126,234,0.5); border:2px solid rgba(255,255,255,0.25);",
              "MATERNAL DIGITAL TWIN")
        ),
        column(4,
          lapply(seq_along(outputs), function(i)
            div(style="background:rgba(255,255,255,0.08); border-right:3px solid #7ec8e3; border-radius:6px; padding:7px 10px; margin-bottom:6px; color:#e0e7ff; font-size:12px; text-align:right;",
                outputs[i], " ", icon(output_icons[i])))
        )
      )
    })

    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 3 — RISK TRAJECTORY & EARLY DETECTION
    # ════════════════════════════════════════════════════════════════════

    CLINICAL_THRESHOLD <- 65
    rt_seed <- reactiveVal(101)
    observeEvent(input$rt_resample, { rt_seed(sample(1:100000, 1)) })

    rt_cohort_data <- reactive({
      generate_ppd_cohort_data(n_per_cohort = 15, weeks = 24, seed = rt_seed())
    })

    rt_filtered <- reactive({
      df <- rt_cohort_data()
      if (!is.null(input$rt_cohort_filter) && input$rt_cohort_filter != "all") {
        df <- df[df$cohort == input$rt_cohort_filter, ]
      }
      df
    })

    output$rt_mother_selector <- renderUI({
      df <- rt_filtered()
      diverging <- unique(df$mother_id[df$diverges])
      choices <- if (length(diverging) > 0) diverging else unique(df$mother_id)
      selectInput(ns("rt_mother_id"), "Mother (simulated ID):", choices = choices, selected = choices[1])
    })

    rt_mother_data <- reactive({
      req(input$rt_mother_id)
      df <- rt_filtered()
      df[df$mother_id == input$rt_mother_id, ] %>% dplyr::arrange(weeks_postpartum)
    })

    rt_flag_info <- reactive({
      df <- rt_mother_data()
      above <- df[df$composite_risk_score >= 40, ]
      threshold_cross <- df[df$composite_risk_score >= CLINICAL_THRESHOLD, ]
      flag_week <- if (nrow(above) > 0) min(above$weeks_postpartum) else NA
      threshold_week <- if (nrow(threshold_cross) > 0) min(threshold_cross$weeks_postpartum) else NA
      lead_time_days <- if (!is.na(flag_week) && !is.na(threshold_week)) (threshold_week - flag_week) * 7 else NA
      list(flag_week = flag_week, threshold_week = threshold_week, lead_time_days = lead_time_days)
    })

    output$trajectory_plot <- plotly::renderPlotly({
      df <- rt_mother_data()
      fi <- rt_flag_info()

      p <- plotly::plot_ly(df, x = ~weeks_postpartum, y = ~composite_risk_score,
                            type = "scatter", mode = "lines+markers",
                            fill = "tozeroy", fillcolor = "rgba(74,144,226,0.12)",
                            line = list(color = "#4a90e2", width = 3, shape = "spline"),
                            marker = list(color = ~risk_colour(composite_risk_score), size = 7,
                                          line = list(color = "#0a1128", width = 0.5)),
                            name = "Composite risk score",
                            hovertemplate = "Week %{x}<br>Risk score: %{y:.1f}<extra></extra>")

      p <- p %>% plotly::add_trace(
        x = df$weeks_postpartum, y = rep(CLINICAL_THRESHOLD, nrow(df)),
        type = "scatter", mode = "lines",
        line = list(color = "#e74c3c", width = 1.5, dash = "dash"),
        name = "Clinical threshold zone", hoverinfo = "skip"
      )

      if (!is.na(fi$flag_week)) {
        flag_score <- df$composite_risk_score[df$weeks_postpartum == fi$flag_week][1]
        p <- p %>% plotly::add_annotations(
          x = fi$flag_week, y = flag_score,
          text = paste0("<b>Model flag: Wk ", fi$flag_week, "</b>"),
          showarrow = TRUE, arrowhead = 3, arrowcolor = "#ffffff", ax = 0, ay = -45,
          bgcolor = "#667eea", bordercolor = "#ffffff", borderwidth = 1, borderpad = 4,
          font = list(color = "#ffffff", size = 12)
        )
      }

      p %>% apply_plotly_theme(x_title = "Weeks postpartum",
                                y_title = "Risk score (0-100, vs own baseline)",
                                hovermode = "x unified", y_range = c(0, 100))
    })

    output$flag_kpis <- renderUI({
      fi <- rt_flag_info()
      fluidRow(
        column(6, div(style = "text-align:center; padding:6px;",
                      tags$div(style = "font-size:22px; font-weight:700; color:#e74c3c;",
                               ifelse(is.na(fi$flag_week), "-", paste0("Wk ", fi$flag_week))),
                      tags$div(style = "font-size:11px; color:#c7d2fe;", "Flagged"))),
        column(6, div(style = "text-align:center; padding:6px;",
                      tags$div(style = "font-size:22px; font-weight:700; color:#27ae60;",
                               ifelse(is.na(fi$lead_time_days), "-", paste0(fi$lead_time_days, " days"))),
                      tags$div(style = "font-size:11px; color:#c7d2fe;", "Lead time")))
      )
    })

    output$breakdown_plot <- plotly::renderPlotly({
      df <- rt_mother_data()
      fi <- rt_flag_info()
      wk <- if (!is.na(fi$flag_week)) fi$flag_week else max(df$weeks_postpartum)
      row <- df[df$weeks_postpartum == wk, ][1, ]

      bd <- ppd_risk_breakdown(row$sleep_fragmentation, row$mood_variance_14d,
                                row$checkin_engagement_drop, row$support_content_change,
                                row$resting_hrv_delta)
      contrib <- bd$contributions
      # Darkest bar = biggest contributor, on a purple-to-blue brand ramp
      bar_colours <- grDevices::colorRampPalette(c("#764ba2", "#4a90e2"))(length(contrib))

      plotly::plot_ly(x = as.numeric(contrib), y = factor(names(contrib), levels = rev(names(contrib))),
                       type = "bar", orientation = "h",
                       marker = list(color = bar_colours, line = list(color = "#0a1128", width = 0.5)),
                       text = round(as.numeric(contrib), 2), textposition = "outside",
                       textfont = list(color = "#e0e7ff"),
                       hovertemplate = "%{y}<br>Contribution: %{x:.2f}<extra></extra>") %>%
        apply_plotly_theme(x_title = "Weighted contribution", legend = FALSE) %>%
        plotly::layout(yaxis = list(title = "", automargin = TRUE, gridcolor = "rgba(0,0,0,0)",
                                     tickfont = list(color = "#e0e7ff")),
                        margin = list(l = 10, t = 10, b = 30))
    })

    output$action_panel <- renderUI({
      fi <- rt_flag_info()
      if (is.na(fi$flag_week)) {
        return(div(style = "font-size:12.5px; color:#c7d2fe;", "No flag raised for this mother in the simulated window."))
      }
      div(style = "background:linear-gradient(135deg, rgba(74,144,226,0.2) 0%, rgba(102,126,234,0.2) 100%); border:1px solid #4a90e2; border-radius:8px; padding:10px; font-size:12px; color:#e0e7ff;",
        tags$strong("Action triggered at the flag:"), tags$br(),
        "Mother receives targeted in-app support. The flag is carried into the next ",
        "periodic (EPDS) check as a RAG escalation. GP notified only where consent is given.",
        tags$br(), tags$em("This is decision support, not a diagnosis.")
      )
    })

    output$distribution_plot <- plotly::renderPlotly({
      df <- rt_cohort_data()
      latest <- df %>% dplyr::group_by(mother_id, cohort) %>%
        dplyr::filter(weeks_postpartum == max(weeks_postpartum)) %>% dplyr::ungroup()
      latest$band <- factor(risk_category(latest$composite_risk_score),
                             levels = c("Low", "Moderate", "High", "Critical"))
      counts <- latest %>% dplyr::count(cohort, band, .drop = FALSE)
      counts$cohort_label <- COHORT_LABELS[counts$cohort]

      plotly::plot_ly(counts, x = ~cohort_label, y = ~n, color = ~band,
                       colors = setNames(RISK_SCALE_COLOURS, c("Low", "Moderate", "High", "Critical")),
                       type = "bar",
                       marker = list(line = list(color = "#ffffff", width = 1)),
                       hovertemplate = "%{x}<br>%{fullData.name}: %{y} mothers<extra></extra>") %>%
        apply_plotly_theme(x_title = "", y_title = "Mothers (latest week)", barmode = "stack")
    })

    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 4 — COHORT A/B SIMULATION
    # ════════════════════════════════════════════════════════════════════

    ab_seed <- reactiveVal(2026)
    observeEvent(input$ab_resimulate, { ab_seed(sample(1:100000, 1)) })

    ab_data <- reactive({
      generate_ppd_cohort_data(n_per_cohort = 50, weeks = 24, seed = ab_seed())
    })

    ab_latest <- reactive({
      ab_data() %>% dplyr::filter(weeks_postpartum == 24)
    })

    ab_summary <- reactive({
      ab_latest() %>% dplyr::group_by(cohort) %>%
        dplyr::summarise(
          mean_epds = mean(epds_total, na.rm = TRUE),
          mean_risk = mean(composite_risk_score, na.rm = TRUE),
          selfharm_rate = mean(self_harm_flag, na.rm = TRUE),
          .groups = "drop"
        )
    })

    output$kpi_epds_delta <- renderValueBox({
      s <- ab_summary()
      app_v <- s$mean_epds[s$cohort == "app_supported"]
      no_v  <- s$mean_epds[s$cohort == "no_support"]
      delta <- round(no_v - app_v, 1)
      valueBox(paste0(delta), "EPDS reduction (App-Supported vs No Support)",
                icon = icon("arrow-down"), color = "green")
    })

    output$kpi_risk_delta <- renderValueBox({
      s <- ab_summary()
      app_v <- s$mean_risk[s$cohort == "app_supported"]
      no_v  <- s$mean_risk[s$cohort == "no_support"]
      delta <- round(no_v - app_v, 1)
      valueBox(paste0(delta), "Composite risk score reduction",
                icon = icon("chart-line"), color = "yellow")
    })

    output$kpi_flag_lead <- renderValueBox({
      df <- ab_data()
      div_mothers <- df %>% dplyr::filter(diverges) %>% dplyr::distinct(mother_id, cohort, onset_week)
      mean_onset <- div_mothers %>% dplyr::group_by(cohort) %>%
        dplyr::summarise(m = mean(onset_week, na.rm = TRUE), .groups = "drop")
      app_v <- mean_onset$m[mean_onset$cohort == "app_supported"]
      no_v  <- mean_onset$m[mean_onset$cohort == "no_support"]
      delta <- round((app_v - no_v) * 7, 0)
      valueBox(paste0(ifelse(is.na(delta), "-", delta), " days"),
                "Later mean onset, App-Supported vs No Support",
                icon = icon("clock"), color = "orange")
    })

    output$kpi_selfharm_rate <- renderValueBox({
      s <- ab_summary()
      app_v <- round(100 * s$selfharm_rate[s$cohort == "app_supported"], 1)
      no_v  <- round(100 * s$selfharm_rate[s$cohort == "no_support"], 1)
      valueBox(paste0(app_v, "% vs ", no_v, "%"),
                "Self-harm item flagged, App-Supported vs No Support",
                icon = icon("exclamation-triangle"), color = "red")
    })

    output$ab_box_plot <- plotly::renderPlotly({
      df <- ab_latest()
      df$cohort_label <- factor(COHORT_LABELS_SHORT[df$cohort],
                                 levels = COHORT_LABELS_SHORT[c("app_supported", "standard_care", "no_support")])
      colours_short <- setNames(COHORT_COLOURS, COHORT_LABELS_SHORT[names(COHORT_COLOURS)])

      # Two-sample t-test, App-Supported vs No-Support - the significance
      # check that actually establishes an A/B contrast (not just eyeballing
      # box overlap), same role as the treatment-effect test in the
      # reference driver-safety app's cohort comparison.
      app_scores <- df$composite_risk_score[df$cohort == "app_supported"]
      no_scores  <- df$composite_risk_score[df$cohort == "no_support"]
      tt <- tryCatch(stats::t.test(no_scores, app_scores), error = function(e) NULL)
      p_val <- if (!is.null(tt)) tt$p.value else NA
      p_label <- if (is.na(p_val)) "n/a" else if (p_val < 0.001) "p < 0.001" else paste0("p = ", round(p_val, 3))
      y_top <- max(df$composite_risk_score, na.rm = TRUE) * 1.15

      p <- plotly::plot_ly(df, x = ~cohort_label, y = ~composite_risk_score, type = "violin",
                            color = ~cohort_label, colors = colours_short,
                            box = list(visible = TRUE, width = 0.25),
                            meanline = list(visible = TRUE, color = "#ffffff"),
                            points = "all", pointpos = 0, jitter = 0.35,
                            marker = list(size = 4, opacity = 0.55),
                            line = list(width = 1.5),
                            spanmode = "hard")

      p <- p %>% plotly::add_segments(
        x = "App-Supported", xend = "No Support", y = y_top, yend = y_top,
        line = list(color = "#ffffff", width = 1.5), showlegend = FALSE, hoverinfo = "skip"
      ) %>% plotly::add_annotations(
        x = "Standard Care", y = y_top * 1.04,
        text = paste0("<b>", p_label, "</b> (App-Supported vs No Support)"),
        showarrow = FALSE, font = list(color = "#ffffff", size = 11)
      )

      p %>% apply_plotly_theme(x_title = "", y_title = "Composite risk score (week 24)", legend = FALSE,
                                y_range = c(0, y_top * 1.15))
    })

    output$ab_density_plot <- plotly::renderPlotly({
      df <- ab_latest()
      p <- plotly::plot_ly()

      for (coh in names(COHORT_LABELS)) {
        vals <- df$composite_risk_score[df$cohort == coh]
        if (length(vals) < 2 || stats::sd(vals) == 0) next
        dens <- stats::density(vals, from = 0, to = 100, n = 256)
        p <- p %>% plotly::add_trace(
          x = dens$x, y = dens$y, type = "scatter", mode = "lines",
          fill = "tozeroy", line = list(color = COHORT_COLOURS[[coh]], width = 2.5, shape = "spline"),
          fillcolor = paste0(COHORT_COLOURS[[coh]], "40"),
          name = COHORT_LABELS_SHORT[[coh]],
          hovertemplate = paste0(COHORT_LABELS_SHORT[[coh]], "<br>Score %{x:.0f}<extra></extra>")
        )
        p <- p %>% plotly::add_segments(
          x = mean(vals), xend = mean(vals), y = 0, yend = max(dens$y) * 1.05,
          line = list(color = COHORT_COLOURS[[coh]], width = 1.5, dash = "dash"),
          showlegend = FALSE, hoverinfo = "skip"
        )
      }

      p %>% apply_plotly_theme(x_title = "Composite risk score (week 24)",
                                y_title = "Density", hovermode = "closest",
                                x_range = c(0, 100))
    })

    output$ab_evolution_plot <- plotly::renderPlotly({
      df <- ab_data()
      summ <- df %>% dplyr::group_by(cohort, weeks_postpartum) %>%
        dplyr::summarise(mean_score = mean(composite_risk_score),
                          se = sd(composite_risk_score) / sqrt(dplyr::n()), .groups = "drop")

      p <- plotly::plot_ly()
      for (coh in names(COHORT_LABELS)) {
        sub <- summ[summ$cohort == coh, ]
        if (isTRUE(input$ab_show_ci)) {
          p <- p %>% plotly::add_ribbons(
            x = sub$weeks_postpartum, ymin = sub$mean_score - sub$se, ymax = sub$mean_score + sub$se,
            line = list(color = "transparent"),
            fillcolor = paste0(COHORT_COLOURS[[coh]], "2E"),
            showlegend = FALSE, hoverinfo = "skip"
          )
        }
        p <- p %>% plotly::add_trace(
          x = sub$weeks_postpartum, y = sub$mean_score, type = "scatter", mode = "lines",
          line = list(color = COHORT_COLOURS[[coh]], width = 3, shape = "spline"),
          name = COHORT_LABELS[[coh]],
          hovertemplate = paste0(COHORT_LABELS[[coh]], "<br>Week %{x}: %{y:.1f}<extra></extra>")
        )
      }
      p %>% apply_plotly_theme(x_title = "Weeks postpartum", y_title = "Mean composite risk score",
                                hovermode = "x unified")
    })

    output$ab_heatmap_plot <- plotly::renderPlotly({
      df <- ab_latest()
      metrics <- c("sleep_fragmentation", "mood_variance_14d", "checkin_engagement_drop",
                   "support_content_change", "resting_hrv_delta")
      metric_labels <- c("Sleep fragmentation", "Mood variance", "Engagement drop",
                          "Support content change", "HRV delta")

      mat <- sapply(names(COHORT_LABELS), function(coh) {
        sub <- df[df$cohort == coh, ]
        sapply(metrics, function(m) mean(sub[[m]], na.rm = TRUE))
      })
      colnames(mat) <- COHORT_LABELS[names(COHORT_LABELS)]
      rownames(mat) <- metric_labels

      plotly::plot_ly(z = mat, x = colnames(mat), y = rownames(mat), type = "heatmap",
                       colors = grDevices::colorRampPalette(c("#0f1f3f", "#4a90e2", "#667eea"))(30),
                       hovertemplate = "%{y}<br>%{x}<br>Mean: %{z:.2f}<extra></extra>",
                       colorbar = list(title = "Mean\n(0-1)", titlefont = list(size = 10, color = "#e0e7ff"),
                                        tickfont = list(color = "#e0e7ff"))) %>%
        apply_plotly_theme(x_title = "", y_title = "", legend = FALSE)
    })

    output$ab_delta_plot <- plotly::renderPlotly({
      df <- ab_latest()
      baseline <- mean(df$composite_risk_score[df$cohort == "no_support"], na.rm = TRUE)
      df <- df %>% dplyr::filter(cohort != "no_support") %>%
        dplyr::mutate(delta = composite_risk_score - baseline) %>%
        dplyr::arrange(delta)
      df$cohort_label <- COHORT_LABELS[df$cohort]

      plotly::plot_ly(df, x = ~seq_len(nrow(df)), y = ~delta, type = "bar",
                       color = ~cohort_label,
                       colors = setNames(COHORT_COLOURS[c("app_supported", "standard_care")],
                                          COHORT_LABELS[c("app_supported", "standard_care")]),
                       hovertemplate = "%{fullData.name}<br>Delta: %{y:.1f}<extra></extra>") %>%
        apply_plotly_theme(x_title = "Mothers (sorted by delta)", y_title = "Risk score delta vs No-Support mean") %>%
        plotly::layout(xaxis = list(title = "Mothers (sorted by delta)", showticklabels = FALSE,
                                     gridcolor = "rgba(255,255,255,0.12)", zerolinecolor = "#ffffff", zerolinewidth = 2))
    })

    # ── Recommended sample size / power table ─────────────────────────────
    ss_results <- reactive({
      d <- COHEN_D_BENCHMARKS[[input$ss_effect_preset]]
      alpha <- input$ss_alpha
      power <- input$ss_power

      n_risk  <- sample_size_two_means(d = d, alpha = alpha, power = power)
      n_epds  <- sample_size_two_means(d = d, alpha = alpha, power = power)
      n_onset <- sample_size_two_means(d = d, alpha = alpha, power = power)
      # Binary safety outcome kept at fixed, literature-informed rates
      # (baseline ~15% self-harm ideation item flagged with no support,
      # vs ~6% with structured support) regardless of the d preset above,
      # because a proportion isn't expressed on Cohen's d scale.
      n_selfharm <- sample_size_two_proportions(p1 = 0.15, p2 = 0.06, alpha = alpha, power = power)

      list(d = d, alpha = alpha, power = power,
           n_risk = n_risk, n_epds = n_epds, n_onset = n_onset, n_selfharm = n_selfharm)
    })

    output$ss_table_rows <- renderUI({
      r <- ss_results()
      d_txt <- paste0("d = ", r$d)

      row <- function(outcome, type, test, effect, n_group, justification) {
        tags$tr(
          tags$td(outcome), tags$td(type), tags$td(test), tags$td(effect),
          tags$td(tags$strong(n_group)), tags$td(n_group * 3),
          tags$td(style = "font-size:11px;", justification)
        )
      }

      tagList(
        row("Composite risk score (0-100)", "Continuous", "Two-sample t-test", d_txt, r$n_risk,
            paste0(
              "Smallest sample of the four options because it is a continuous, high-resolution measure - ",
              "every mother contributes graded information, not just a yes/no. A medium effect (d = 0.5) is ",
              "a realistic, clinically meaningful target given the moderate pooled effects reported for ",
              "psychosocial PPD-prevention interventions (Dennis and Dowswell, 2013).")),
        row("EPDS total score (0-30)", "Continuous", "Two-sample t-test", d_txt, r$n_epds,
            paste0(
              "Same efficiency advantage as the composite score, using the validated clinical instrument ",
              "directly - the outcome a real trial would most likely register as primary.")),
        row("Mean onset week (timing)", "Continuous", "Two-sample t-test", d_txt, r$n_onset,
            paste0(
              "Continuous timing outcome; requires the same n as the two rows above under an equivalent ",
              "effect-size assumption, but is more sensitive to the fact that only diverging mothers ",
              "contribute a value.")),
        row("Self-harm item flagged (EPDS item 10)", "Binary (proportion)", "Two-proportion z-test",
            "15% \u2192 6%", r$n_selfharm,
            paste0(
              "Binary/rare-event outcomes are always the least statistically efficient - this needs roughly ",
              "3-6\u00D7 the sample of a continuous outcome for a comparable real-world difference. This is why ",
              "the app treats the self-harm flag as a deterministic safety trigger for every individual mother, ",
              "rather than the primary metric a small pilot cohort would be powered to compare."))
      )
    })

    output$ss_recommendation_badge <- renderUI({
      r <- ss_results()
      div(style = "text-align:center; padding-top:22px;",
        tags$span(class = "risk-badge", style = "background:linear-gradient(135deg,#667eea 0%,#764ba2 100%); font-size:12px; padding:6px 12px;",
          icon("check-circle"), " Recommended: ", r$n_risk, " per group")
      )
    })
  })
}
