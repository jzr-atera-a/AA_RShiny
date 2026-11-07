# modules/Maternal Health Monitor/maternal_health_monitor/server.R

maternal_health_monitor_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ────────────────────────────────────────────────────────────────────
    # Local plotly reference-line helpers (defined here so they are always
    # available even if helpers_enriched.R is an older version).
    # plotly has no add_hline/add_vline in R; we draw shapes instead.
    # ────────────────────────────────────────────────────────────────────
    add_hline_shape <- function(p, y, color = "#8fa3c8", width = 2, dash = "dash") {
      plotly::layout(p, shapes = list(list(
        type = "line", x0 = 0, x1 = 1, xref = "paper",
        y0 = y, y1 = y, yref = "y",
        line = list(color = color, width = width, dash = dash)
      )))
    }
    add_vline_shape <- function(p, x, color = "#8fa3c8", width = 2, dash = "dash", label = NULL) {
      p <- plotly::layout(p, shapes = list(list(
        type = "line", y0 = 0, y1 = 1, yref = "paper",
        x0 = x, x1 = x, xref = "x",
        line = list(color = color, width = width, dash = dash)
      )))
      if (!is.null(label)) {
        p <- plotly::add_annotations(p, x = x, y = 1, yref = "paper",
          text = label, showarrow = FALSE, font = list(color = color, size = 10),
          xanchor = "left", yanchor = "bottom")
      }
      p
    }

    # Local theme so the module never depends on an outdated helpers file.
    apply_plotly_theme <- function(p, x_title = "", y_title = "", title = "",
                                   barmode = "group", showlegend = TRUE,
                                   xaxis = NULL, yaxis = NULL, ...) {
      base_x <- list(
        showgrid = TRUE, gridwidth = 0.5, gridcolor = "rgba(255,255,255,0.08)",
        zeroline = FALSE, showticklabels = TRUE,
        tickfont = list(size = 10, color = "#e0e7ff"),
        title = list(text = x_title, font = list(size = 12, color = "#e0e7ff"))
      )
      base_y <- list(
        showgrid = TRUE, gridwidth = 0.5, gridcolor = "rgba(255,255,255,0.08)",
        zeroline = FALSE, showticklabels = TRUE,
        tickfont = list(size = 10, color = "#e0e7ff"),
        title = list(text = y_title, font = list(size = 12, color = "#e0e7ff"))
      )
      if (!is.null(xaxis)) base_x <- modifyList(base_x, xaxis)
      if (!is.null(yaxis)) base_y <- modifyList(base_y, yaxis)
      plotly::layout(p,
        plot_bgcolor = "rgba(10, 17, 40, 0)",
        paper_bgcolor = "rgba(10, 17, 40, 0)",
        font = list(family = "'Segoe UI', sans-serif", color = "#e0e7ff", size = 11),
        xaxis = base_x, yaxis = base_y,
        legend = list(x = 0.02, y = 0.98, bgcolor = "rgba(0,0,0,0.3)",
                      bordercolor = "rgba(102,126,234,0.3)", borderwidth = 1,
                      font = list(color = "#e0e7ff", size = 10)),
        title = list(text = title, font = list(size = 14, color = "#ffffff")),
        barmode = barmode, showlegend = showlegend, hovermode = "closest",
        margin = list(l = 60, r = 40, t = 60, b = 50))
    }

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

    # HELPER FUNCTIONS
    # ════════════════════════════════════════════════════════════════════
    
    # Generate simulated correlation data
    generate_correlation_data <- function(r = 0.5, n = 150) {
      set.seed(42)
      z <- rnorm(n)
      x <- z
      y <- r * z + sqrt(1 - r^2) * rnorm(n)
      data.frame(x = scale(x)[,1], y = scale(y)[,1])
    }
    
    # Calculate p-value for two-sample t-test
    calculate_ttest <- function(group1, group2) {
      t.test(group1, group2)
    }
    
    # Calculate Cohen's d
    cohens_d <- function(x, y) {
      n1 <- length(x)
      n2 <- length(y)
      var1 <- var(x)
      var2 <- var(y)
      pooled_sd <- sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1 + n2 - 2))
      (mean(x) - mean(y)) / pooled_sd
    }
    
    # Power curve calculation (for sample size)
    power_sample_size <- function(alpha = 0.05, power = 0.8, effect_size = 0.5, test_type = "means") {
      z_alpha <- qnorm(1 - alpha/2)
      z_beta <- qnorm(power)
      if (test_type == "means") {
        n <- 2 * ((z_alpha + z_beta) / effect_size)^2
      } else {
        p0 <- 0.5
        p1 <- p0 + effect_size
        n <- ((z_alpha * sqrt(2*p0*(1-p0)) + z_beta * sqrt(p0*(1-p0) + p1*(1-p1))) / (p0 - p1))^2
      }
      ceiling(n)
    }
    
    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 4 — STATISTICAL CONCEPTS (INTERACTIVE VISUALIZATIONS)
    # ════════════════════════════════════════════════════════════════════
    
    # CORRELATION DEMO: Interactive scatter plot
    output$corr_demo_scatter <- plotly::renderPlotly({
      r <- input$corr_demo_strength
      direction <- if (input$corr_demo_direction == "pos") 1 else -1
      r_adjusted <- r * direction
      
      data <- generate_correlation_data(r = r_adjusted, n = 150)
      
      title_text <- paste0("Correlation coefficient r = ", round(r_adjusted, 2))
      if (r_adjusted == 0) title_text <- paste0(title_text, " (no relationship)")
      else if (abs(r_adjusted) < 0.3) title_text <- paste0(title_text, " (weak)")
      else if (abs(r_adjusted) < 0.6) title_text <- paste0(title_text, " (moderate)")
      else title_text <- paste0(title_text, " (strong)")
      
      plotly::plot_ly(data, x = ~x, y = ~y, type = "scatter", mode = "markers",
                      marker = list(color = "#667eea", size = 6, opacity = 0.6),
                      hovertemplate = "<b>Variable 1:</b> %{x:.2f}<br><b>Variable 2:</b> %{y:.2f}<extra></extra>") %>%
        apply_plotly_theme(x_title = "Variable 1 (e.g., Sleep Duration)", 
                          y_title = "Variable 2 (e.g., Mood Score)",
                          title = title_text)
    })
    
    # CAUSALITY DEMO: DAG visualization with confounder
    output$causal_demo_dag <- plotly::renderPlotly({
      show_confounder <- input$causal_show_confounder
      
      if (!show_confounder) {
        # Simple causal chain: Sleep -> Depression
        plotly::plot_ly() %>%
          plotly::add_trace(x = c(0.2, 0.8), y = c(0.5, 0.5), 
                           mode = "markers+text", type = "scatter",
                           marker = list(size = 40, color = c("#667eea", "#e74c3c")),
                           text = c("Sleep", "Depression"),
                           textposition = "middle center",
                           hovertemplate = "<b>%{text}</b><extra></extra>") %>%
          plotly::add_trace(x = c(0.25, 0.75), y = c(0.5, 0.5), 
                           mode = "lines", type = "scatter",
                           line = list(color = "#667eea", width = 3),
                           hoverinfo = "none") %>%
          apply_plotly_theme(
            showlegend = FALSE,
            xaxis = list(zeroline = FALSE, showgrid = FALSE, showticklabels = FALSE, range = c(0, 1)),
            yaxis = list(zeroline = FALSE, showgrid = FALSE, showticklabels = FALSE, range = c(0, 1)),
            title = "Without Confounder: Sleep to Depression (appears causal)"
          )
      } else {
        # With confounder: Stress drives both
        plotly::plot_ly() %>%
          # Stress (confounder) at top
          plotly::add_trace(x = c(0.5), y = c(0.8), 
                           mode = "markers+text", type = "scatter",
                           marker = list(size = 40, color = "#f39c12"),
                           text = c("High Stress"),
                           textposition = "middle center",
                           hovertemplate = "<b>Stress (confounder)</b><extra></extra>") %>%
          # Sleep on left
          plotly::add_trace(x = c(0.2), y = c(0.3), 
                           mode = "markers+text", type = "scatter",
                           marker = list(size = 40, color = "#667eea"),
                           text = c("Sleep"),
                           textposition = "middle center",
                           hovertemplate = "<b>Sleep</b><extra></extra>") %>%
          # Depression on right
          plotly::add_trace(x = c(0.8), y = c(0.3), 
                           mode = "markers+text", type = "scatter",
                           marker = list(size = 40, color = "#e74c3c"),
                           text = c("Depression"),
                           textposition = "middle center",
                           hovertemplate = "<b>Depression</b><extra></extra>") %>%
          # Arrow: Stress -> Sleep
          plotly::add_trace(x = c(0.45, 0.25), y = c(0.75, 0.4), 
                           mode = "lines", type = "scatter",
                           line = list(color = "#f39c12", width = 2, dash = "dash"),
                           hoverinfo = "none") %>%
          # Arrow: Stress -> Depression
          plotly::add_trace(x = c(0.55, 0.75), y = c(0.75, 0.4), 
                           mode = "lines", type = "scatter",
                           line = list(color = "#f39c12", width = 2, dash = "dash"),
                           hoverinfo = "none") %>%
          # Spurious: Sleep ~~ Depression (dashed, indicating correlation not causation)
          plotly::add_trace(x = c(0.25, 0.75), y = c(0.3, 0.3), 
                           mode = "lines", type = "scatter",
                           line = list(color = "#95a5a6", width = 1, dash = "dot"),
                           hoverinfo = "none") %>%
          apply_plotly_theme(
            showlegend = FALSE,
            xaxis = list(zeroline = FALSE, showgrid = FALSE, showticklabels = FALSE, range = c(0, 1)),
            yaxis = list(zeroline = FALSE, showgrid = FALSE, showticklabels = FALSE, range = c(0, 1)),
            title = "With Confounder: Stress drives both (spurious correlation)"
          )
      }
    })
    
    # P-VALUE DEMO: Distribution curves
    output$pval_demo_curves <- plotly::renderPlotly({
      n <- input$pval_n
      effect <- input$pval_effect
      
      # Null distribution (centered at 0)
      null_se <- 1 / sqrt(n/2)
      null_x <- seq(-4*null_se, 4*null_se, length.out = 200)
      null_y <- dnorm(null_x, mean = 0, sd = null_se)
      
      # True effect distribution (centered at effect*sd)
      true_x <- seq(-4*null_se, 4*null_se + effect, length.out = 200)
      true_y <- dnorm(true_x, mean = effect, sd = null_se)
      
      # Critical value (two-tailed, α = 0.05)
      crit_val <- qnorm(0.975) * null_se
      
      plotly::plot_ly() %>%
        plotly::add_trace(x = null_x, y = null_y, fill = "tozeroy", 
                         name = "Null (no effect)", type = "scatter", mode = "lines",
                         fillcolor = "rgba(100, 150, 200, 0.3)",
                         line = list(color = "#3498db", width = 2)) %>%
        plotly::add_trace(x = true_x, y = true_y, fill = "tozeroy",
                         name = "True (effect present)", type = "scatter", mode = "lines",
                         fillcolor = "rgba(46, 204, 113, 0.3)",
                         line = list(color = "#27ae60", width = 2)) %>%
        apply_plotly_theme(x_title = "Test Statistic", y_title = "Probability Density",
                          title = paste0("P-value regions (n=", n, ", d=", round(effect, 2), ")")) %>%
        add_vline_shape(x = crit_val, color = "#e74c3c", width = 2, dash = "dash",
                        label = "α=0.05") %>%
        add_vline_shape(x = -crit_val, color = "#e74c3c", width = 2, dash = "dash")
    })
    
    # POWER CURVES: Sample size explorer
    output$power_demo_curves <- plotly::renderPlotly({
      alpha <- as.numeric(input$power_alpha)
      test_type <- input$power_test
      
      effect_sizes <- seq(0.1, 1.5, by = 0.1)
      sample_sizes <- sapply(effect_sizes, function(d) 
        power_sample_size(alpha = alpha, power = 0.8, effect_size = d, test_type = test_type))
      
      plotly::plot_ly() %>%
        plotly::add_trace(x = effect_sizes, y = sample_sizes,
                         type = "scatter", mode = "lines+markers",
                         name = "Power = 0.80",
                         line = list(color = "#667eea", width = 3),
                         marker = list(size = 8)) %>%
        # Also add 0.90 power curve
        plotly::add_trace(x = effect_sizes, 
                         y = sapply(effect_sizes, function(d)
                           power_sample_size(alpha = alpha, power = 0.9, effect_size = d, test_type = test_type)),
                         type = "scatter", mode = "lines+markers",
                         name = "Power = 0.90",
                         line = list(color = "#e74c3c", width = 3, dash = "dash"),
                         marker = list(size = 8)) %>%
        apply_plotly_theme(x_title = "Effect Size (Cohen's d)", 
                          y_title = "Sample Size (per group)",
                          title = paste0("Power curves (α=", alpha, ", ", test_type, ")"))
    })
    
    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 5 — CONCEPTS APPLIED (INTERACTIVE DATA VISUALIZATIONS)
    # ════════════════════════════════════════════════════════════════════
    
    # Correlation scatter plot (PPD data)
    output$corr_ppd_scatter <- plotly::renderPlotly({
      req(input$corr_ppd_signal)
      
      # Generate simulated PPD cohort data
      set.seed(42)
      n_mothers <- 200
      epds <- rnorm(n_mothers, mean = 8, sd = 5)
      
      signal_map <- list(
        sleep_fragmentation = 0.55,
        mood_variance_14d = 0.58,
        checkin_engagement_drop = 0.42,
        support_content_change = 0.38,
        resting_hrv_delta = 0.35
      )
      
      r <- signal_map[[input$corr_ppd_signal]]
      signal <- r * scale(epds)[,1] + sqrt(1-r^2) * rnorm(n_mothers)
      
      signal_names <- c(
        sleep_fragmentation = "Sleep Fragmentation",
        mood_variance_14d = "14-day Mood Variance",
        checkin_engagement_drop = "Check-in Engagement Drop",
        support_content_change = "Support Content Shift",
        resting_hrv_delta = "HRV Delta vs Baseline"
      )
      
      cor_coef <- cor(epds, signal)
      
      plotly::plot_ly(data.frame(epds = epds, signal = signal),
                     x = ~epds, y = ~signal,
                     type = "scatter", mode = "markers",
                     marker = list(color = "#667eea", size = 6, opacity = 0.6),
                     hovertemplate = "<b>EPDS:</b> %{x:.1f}<br><b>Signal:</b> %{y:.2f}<extra></extra>") %>%
        # Add trend line
        plotly::add_trace(x = range(epds), 
                         y = predict(lm(signal ~ epds), data.frame(epds = range(epds))),
                         mode = "lines", type = "scatter",
                         line = list(color = "#e74c3c", width = 2, dash = "dash"),
                         name = "Trend", hoverinfo = "none") %>%
        apply_plotly_theme(x_title = "EPDS Score (Depression severity)",
                          y_title = signal_names[[input$corr_ppd_signal]],
                          title = paste0("Correlation: r = ", round(cor_coef, 3)))
    })
    
    # Interpretation of correlation
    output$corr_ppd_interpretation <- renderUI({
      req(input$corr_ppd_signal)
      
      interpretations <- list(
        sleep_fragmentation = "Sleep fragmentation is the strongest behavioural predictor of postnatal depression severity. However, this correlation does not mean poor sleep CAUSES depression—rather, they move together, making fragmented sleep a useful early-warning marker.",
        mood_variance_14d = "Daily mood swings over a 2-week window correlate strongly with depressive severity. The app flags rapid mood changes as an early-detection signal, not a diagnosis.",
        checkin_engagement_drop = "Falling app participation often precedes clinical deterioration. This could mean depression makes engagement harder, or simply that withdrawal is part of the syndrome.",
        support_content_change = "Shifts in what support content a mother engages with correlate with mood changes. The correlation guides personalisation, not causation.",
        resting_hrv_delta = "Heart rate variability, a marker of autonomic strain, correlates with mood scores. Like the others, this is an association we exploit for early warning."
      )
      
      tags$div(
        tags$strong("What this correlation tells us:"),
        br(),
        interpretations[[input$corr_ppd_signal]]
      )
    })
    
    # Causality trajectory (risk quartiles)
    output$causal_ppd_trajectory <- plotly::renderPlotly({
      set.seed(42)
      n_mothers <- 150
      weeks <- 0:24
      
      # Simulate four groups by baseline risk quartile
      risk_q1 <- replicate(n_mothers/4, 
                          rnorm(length(weeks), mean = 20 + weeks*0.5, sd = 5))
      risk_q2 <- replicate(n_mothers/4, 
                          rnorm(length(weeks), mean = 35 + weeks*0.8, sd = 6))
      risk_q3 <- replicate(n_mothers/4, 
                          rnorm(length(weeks), mean = 50 + weeks*1.0, sd = 7))
      risk_q4 <- replicate(n_mothers/4, 
                          rnorm(length(weeks), mean = 65 + weeks*1.2, sd = 8))
      
      risk_q1_mean <- rowMeans(risk_q1)
      risk_q2_mean <- rowMeans(risk_q2)
      risk_q3_mean <- rowMeans(risk_q3)
      risk_q4_mean <- rowMeans(risk_q4)
      
      plotly::plot_ly() %>%
        plotly::add_trace(x = weeks, y = risk_q1_mean, name = "Q1 (Lowest risk)", 
                         mode = "lines", line = list(color = "#27ae60", width = 2)) %>%
        plotly::add_trace(x = weeks, y = risk_q2_mean, name = "Q2",
                         mode = "lines", line = list(color = "#f39c12", width = 2)) %>%
        plotly::add_trace(x = weeks, y = risk_q3_mean, name = "Q3",
                         mode = "lines", line = list(color = "#e67e22", width = 2)) %>%
        plotly::add_trace(x = weeks, y = risk_q4_mean, name = "Q4 (Highest risk)",
                         mode = "lines", line = list(color = "#e74c3c", width = 2)) %>%
        apply_plotly_theme(x_title = "Weeks postpartum", y_title = "Average risk score",
                          title = "Risk Trajectory by Baseline Risk Quartile",
                          showlegend = TRUE)
    })
    
    # Significance: P-value and effect size
    output$significance_ppd_distributions <- plotly::renderPlotly({
      set.seed(42)
      app_supported <- rnorm(100, mean = 35, sd = 12)
      no_support <- rnorm(100, mean = 45, sd = 14)
      
      x_range <- seq(10, 80, length.out = 200)
      
      plotly::plot_ly() %>%
        plotly::add_trace(x = x_range, 
                         y = dnorm(x_range, mean = mean(app_supported), sd = sd(app_supported)),
                         fill = "tozeroy", name = "App-Supported",
                         type = "scatter", mode = "lines",
                         fillcolor = "rgba(102, 126, 234, 0.3)",
                         line = list(color = "#667eea", width = 2)) %>%
        plotly::add_trace(x = x_range,
                         y = dnorm(x_range, mean = mean(no_support), sd = sd(no_support)),
                         fill = "tozeroy", name = "No-Support",
                         type = "scatter", mode = "lines",
                         fillcolor = "rgba(230, 126, 34, 0.3)",
                         line = list(color = "#e67e22", width = 2)) %>%
        apply_plotly_theme(x_title = "Risk score (week 24)", y_title = "Density",
                          title = "Distribution: App-Supported vs No-Support at Week 24")
    })
    
    # Statistical significance KPIs
    output$significance_ppd_kpis <- renderUI({
      set.seed(42)
      app_supported <- rnorm(100, mean = 35, sd = 12)
      no_support <- rnorm(100, mean = 45, sd = 14)
      
      t_result <- t.test(app_supported, no_support)
      d <- cohens_d(app_supported, no_support)
      
      tags$div(
        tags$strong("Two-sample t-test results:"),
        tags$table(class = "table table-condensed",
          tags$tr(tags$td("Mean (App-Supported)"), tags$td(sprintf("%.1f", mean(app_supported)))),
          tags$tr(tags$td("Mean (No-Support)"), tags$td(sprintf("%.1f", mean(no_support)))),
          tags$tr(tags$td("Difference"), tags$td(sprintf("%.1f", mean(app_supported) - mean(no_support)))),
          tags$tr(tags$td("p-value"), tags$td(sprintf("%.4f", t_result$p.value))),
          tags$tr(tags$td("Cohen's d"), tags$td(sprintf("%.3f", d))),
          tags$tr(tags$td("Interpretation"), 
                 tags$td(if (t_result$p.value < 0.05) "Statistically significant" else "Not significant"))
        )
      )
    })
    
    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 6 — A/B SIMULATION (ENHANCED with parameter controls)
    # ════════════════════════════════════════════════════════════════════
    
    # Re-simulate with parameter controls
    sim_data <- eventReactive(input$ab_resimulate, {
      set.seed(Sys.time())
      
      n <- input$ab_cohort_size
      weeks <- 0:24
      effect_mult <- input$ab_effect_multiplier
      
      # Generate three cohorts
      no_support <- lapply(1:n, function(i) {
        baseline <- rnorm(1, mean = 30, sd = 8)
        trend <- seq(baseline, baseline + 25 + rnorm(1, 0, 5), length.out = length(weeks))
        trend + rnorm(length(weeks), 0, 3)
      })
      
      standard_care <- lapply(1:n, function(i) {
        baseline <- rnorm(1, mean = 30, sd = 8)
        trend <- seq(baseline, baseline + 18 + rnorm(1, 0, 5), length.out = length(weeks))
        trend + rnorm(length(weeks), 0, 3)
      })
      
      app_supported <- lapply(1:n, function(i) {
        baseline <- rnorm(1, mean = 30, sd = 8)
        trend <- seq(baseline, baseline + 10 * effect_mult + rnorm(1, 0, 5), length.out = length(weeks))
        trend + rnorm(length(weeks), 0, 3)
      })
      
      list(
        no_support = do.call(rbind, lapply(no_support, function(x) pmin(100, pmax(0, x)))),
        standard_care = do.call(rbind, lapply(standard_care, function(x) pmin(100, pmax(0, x)))),
        app_supported = do.call(rbind, lapply(app_supported, function(x) pmin(100, pmax(0, x))))
      )
    }, ignoreNULL = FALSE)
    
    # KPI: EPDS delta
    output$kpi_epds_delta <- renderValueBox({
      data <- sim_data()
      epds_app <- mean(data$app_supported[, 25])
      epds_no <- mean(data$no_support[, 25])
      delta <- epds_app - epds_no
      
      shinydashboard::valueBox(
        value = sprintf("%.1f points", delta),
        subtitle = "EPDS delta: App vs No-Support",
        icon = icon("heart-pulse"),
        color = if (delta < 0) "green" else "red"
      )
    })
    
    # KPI: Risk delta
    output$kpi_risk_delta <- renderValueBox({
      data <- sim_data()
      risk_app <- mean(data$app_supported[, 25])
      risk_no <- mean(data$no_support[, 25])
      delta <- (risk_no - risk_app) / risk_no * 100
      
      shinydashboard::valueBox(
        value = sprintf("%.0f%%", delta),
        subtitle = "Risk reduction",
        icon = icon("arrow-down"),
        color = "blue"
      )
    })

    # KPI: Flag lead time (days earlier detection for App-Supported)
    output$kpi_flag_lead <- renderValueBox({
      data <- sim_data()
      # Illustrative: earlier threshold crossing for supported vs unsupported
      threshold <- 60
      first_cross <- function(mat) {
        crosses <- apply(mat, 1, function(r) {
          idx <- which(r >= threshold)
          if (length(idx) == 0) ncol(mat) else idx[1]
        })
        mean(crosses)
      }
      lead_weeks <- first_cross(data$no_support) - first_cross(data$app_supported)
      lead_days <- round(max(0, lead_weeks) * 7)

      shinydashboard::valueBox(
        value = sprintf("%d days", lead_days),
        subtitle = "Earlier detection (lead time)",
        icon = icon("clock"),
        color = "purple"
      )
    })

    # KPI: Self-harm flag rate difference (illustrative safety outcome)
    output$kpi_selfharm_rate <- renderValueBox({
      data <- sim_data()
      # Illustrative: proportion in critical band at week 24
      crit_rate <- function(mat) mean(mat[, 25] >= 75)
      reduction <- (crit_rate(data$no_support) - crit_rate(data$app_supported)) * 100

      shinydashboard::valueBox(
        value = sprintf("%.0f%%", max(0, reduction)),
        subtitle = "Fewer in critical band",
        icon = icon("shield-heart"),
        color = "green"
      )
    })

    # Box plots
    output$ab_box_plot <- plotly::renderPlotly({
      data <- sim_data()
      
      plotly::plot_ly() %>%
        plotly::add_boxplot(y = data$no_support[, 25], name = "No-Support", 
                           marker = list(color = "#95a5a6")) %>%
        plotly::add_boxplot(y = data$standard_care[, 25], name = "Standard Care",
                           marker = list(color = "#3498db")) %>%
        plotly::add_boxplot(y = data$app_supported[, 25], name = "App-Supported",
                           marker = list(color = "#27ae60")) %>%
        apply_plotly_theme(y_title = "Risk score (week 24)")
    })
    
    # Density plots
    output$ab_density_plot <- plotly::renderPlotly({
      data <- sim_data()
      
      plotly::plot_ly() %>%
        plotly::add_trace(x = density(data$no_support[, 25])$x,
                         y = density(data$no_support[, 25])$y,
                         fill = "tozeroy", name = "No-Support",
                         type = "scatter", mode = "lines",
                         fillcolor = "rgba(149, 165, 166, 0.2)",
                         line = list(color = "#95a5a6", width = 2)) %>%
        plotly::add_trace(x = density(data$app_supported[, 25])$x,
                         y = density(data$app_supported[, 25])$y,
                         fill = "tozeroy", name = "App-Supported",
                         type = "scatter", mode = "lines",
                         fillcolor = "rgba(39, 174, 96, 0.2)",
                         line = list(color = "#27ae60", width = 2)) %>%
        apply_plotly_theme(x_title = "Risk score", y_title = "Density",
                          title = "Kernel Density Estimate by Cohort")
    })
    
    # Evolution over weeks
    output$ab_evolution_plot <- plotly::renderPlotly({
      data <- sim_data()
      
      weeks <- 0:24
      no_support_mean <- colMeans(data$no_support)
      no_support_se <- apply(data$no_support, 2, function(x) sd(x) / sqrt(length(x)))
      
      app_supported_mean <- colMeans(data$app_supported)
      app_supported_se <- apply(data$app_supported, 2, function(x) sd(x) / sqrt(length(x)))
      
      show_ci <- input$ab_show_ci
      
      p <- plotly::plot_ly()

      # Confidence bands drawn first (lower bound invisible, upper fills down to it)
      if (show_ci) {
        p <- p %>%
          plotly::add_trace(x = weeks, y = no_support_mean - no_support_se,
                           type = "scatter", mode = "lines",
                           line = list(color = "transparent"),
                           showlegend = FALSE, hoverinfo = "none") %>%
          plotly::add_trace(x = weeks, y = no_support_mean + no_support_se,
                           type = "scatter", mode = "lines", fill = "tonexty",
                           fillcolor = "rgba(149, 165, 166, 0.2)",
                           line = list(color = "transparent"),
                           showlegend = FALSE, hoverinfo = "none") %>%
          plotly::add_trace(x = weeks, y = app_supported_mean - app_supported_se,
                           type = "scatter", mode = "lines",
                           line = list(color = "transparent"),
                           showlegend = FALSE, hoverinfo = "none") %>%
          plotly::add_trace(x = weeks, y = app_supported_mean + app_supported_se,
                           type = "scatter", mode = "lines", fill = "tonexty",
                           fillcolor = "rgba(39, 174, 96, 0.2)",
                           line = list(color = "transparent"),
                           showlegend = FALSE, hoverinfo = "none")
      }

      p <- p %>%
        plotly::add_trace(x = weeks, y = no_support_mean, name = "No-Support",
                         type = "scatter", mode = "lines",
                         line = list(color = "#95a5a6", width = 2),
                         hovertemplate = "<b>No-Support</b><br>Week %{x}: %{y:.1f}<extra></extra>") %>%
        plotly::add_trace(x = weeks, y = app_supported_mean, name = "App-Supported",
                         type = "scatter", mode = "lines",
                         line = list(color = "#27ae60", width = 2),
                         hovertemplate = "<b>App-Supported</b><br>Week %{x}: %{y:.1f}<extra></extra>")

      p %>% apply_plotly_theme(x_title = "Weeks postpartum", y_title = "Average risk score")
    })
    
    # Heatmap
    output$ab_heatmap_plot <- plotly::renderPlotly({
      data <- sim_data()
      
      signals <- c("Sleep fragmentation", "Mood variance", "Engagement drop", 
                  "Content shift", "HRV delta")
      
      # Simulate normalized signals
      no_support_signals <- matrix(rnorm(15, mean = 0.5, sd = 0.15), nrow = 5)
      standard_care_signals <- matrix(rnorm(15, mean = 0.4, sd = 0.15), nrow = 5)
      app_supported_signals <- matrix(rnorm(15, mean = 0.25, sd = 0.12), nrow = 5)
      
      z_data <- cbind(no_support_signals[, 1], standard_care_signals[, 1], app_supported_signals[, 1])
      
      plotly::plot_ly(z = z_data, x = c("No-Support", "Standard", "App-Supported"),
                     y = signals, type = "heatmap",
                     colorscale = "Viridis",
                     reversescale = TRUE,
                     hovertemplate = "%{y}<br>%{x}<br>%{z:.2f}<extra></extra>") %>%
        apply_plotly_theme(title = "Normalized Signal Heatmap (week 24)")
    })
    
    # Delta plot
    output$ab_delta_plot <- plotly::renderPlotly({
      data <- sim_data()
      
      no_support_avg <- mean(data$no_support[, 25])
      app_delta <- data$app_supported[, 25] - no_support_avg
      standard_delta <- data$standard_care[, 25] - no_support_avg
      
      all_delta <- c(app_delta, standard_delta)
      labels <- c(rep("App-Supported", length(app_delta)), rep("Standard Care", length(standard_delta)))
      
      plotly::plot_ly(y = all_delta, x = labels, type = "bar",
                     marker = list(color = ifelse(all_delta < 0, "#27ae60", "#e74c3c")),
                     hovertemplate = "%{x}<br>Delta: %{y:.1f}<extra></extra>") %>%
        apply_plotly_theme(y_title = "Risk delta vs No-Support",
                          title = "Per-Mother Risk Delta") %>%
        add_hline_shape(y = 0, color = "#34495e", width = 2, dash = "dash")
    })
    
    # Sample size table
    output$ss_table_rows <- renderUI({
      alpha <- as.numeric(input$ss_alpha)
      power <- as.numeric(input$ss_power)
      
      effect_map <- list(
        Small = 0.2, Medium = 0.5, Large = 0.8
      )
      d <- effect_map[[input$ss_effect_preset]]
      
      outcomes <- list(
        list(name = "Primary: Risk Score (continuous)", type = "Continuous", test = "t-test",
             effect = d, justification = "Based on simulated cohort variance"),
        list(name = "Secondary: EPDS at week 24", type = "Continuous", test = "t-test",
             effect = d, justification = "Standard postpartum depression measure"),
        list(name = "Tertiary: Self-harm flag rate", type = "Binary", test = "χ²",
             effect = d, justification = "Safety outcome, conservative assumption")
      )
      
      lapply(outcomes, function(o) {
        n <- power_sample_size(alpha = alpha, power = power, effect_size = o$effect, test_type = "means")
        tags$tr(
          tags$td(o$name),
          tags$td(o$type),
          tags$td(o$test),
          tags$td(sprintf("d = %.1f", o$effect)),
          tags$td(ceiling(n)),
          tags$td(ceiling(n * 3)),
          tags$td(style="font-size:10px;", o$justification)
        )
      })
    })

    # Recommendation badge summarising the primary-outcome sample size
    output$ss_recommendation_badge <- renderUI({
      alpha <- as.numeric(input$ss_alpha)
      power <- as.numeric(input$ss_power)
      effect_map <- list(Small = 0.2, Medium = 0.5, Large = 0.8)
      d <- effect_map[[input$ss_effect_preset]]
      n <- power_sample_size(alpha = alpha, power = power, effect_size = d, test_type = "means")
      div(style = "background:rgba(102,126,234,0.15); border:1px solid rgba(102,126,234,0.4); border-radius:8px; padding:10px; text-align:center;",
        div(style = "font-size:22px; font-weight:700; color:#8fa3c8;", ceiling(n * 3)),
        div(style = "font-size:11px; color:#a8b6d8;", "total mothers recommended"),
        div(style = "font-size:10px; color:#8fa3c8; margin-top:4px;",
            sprintf("%d per arm · d=%.1f · power=%.0f%%", ceiling(n), d, power * 100))
      )
    })

    # ════════════════════════════════════════════════════════════════════
    # SUBTAB 7 — INTERVENTION TIMELINE (SIGNIFICANTLY ENHANCED)
    # ════════════════════════════════════════════════════════════════════
    
    # Risk curves over full maternal journey
    output$intervention_plot <- plotly::renderPlotly({
      weeks_full <- seq(-8, 104, by = 1)  # -8 weeks to 104 weeks (2 years)
      
      # Control (no structured support)
      no_support_risk <- 40 + 
        5 * (weeks_full >= -8 & weeks_full < 0) +  # antenatal preparation
        10 * (weeks_full >= 0 & weeks_full < 4) +  # perinatal crisis
        15 * (weeks_full >= 4 & weeks_full < 12) + # sleep deprivation phase
        8 * (weeks_full >= 12 & weeks_full < 26) + # subsyndromal phase
        12 * (weeks_full >= 26 & weeks_full < 52) + # return-to-work transition
        5 * (weeks_full >= 52)                      # consolidation
      no_support_risk <- pmin(100, pmax(0, no_support_risk))
      
      # With support (structured, layered intervention)
      with_support_risk <- 40 +
        2 * (weeks_full >= -8 & weeks_full < 0) +  # antenatal education
        6 * (weeks_full >= 0 & weeks_full < 4) +   # perinatal safety net
        8 * (weeks_full >= 4 & weeks_full < 12) +  # peer + monitoring
        4 * (weeks_full >= 12 & weeks_full < 26) + # symptom-triggered intervention
        8 * (weeks_full >= 26 & weeks_full < 52) + # employer engagement
        2 * (weeks_full >= 52)                      # ongoing monitoring
      with_support_risk <- pmin(100, pmax(0, with_support_risk))
      
      # Intervention markers (approximate week positions)
      intervention_weeks <- c(-4, 1, 6, 14, 24, 30, 38, 52, 75, 100)
      intervention_labels <- c("Screening", "Safety plan", "Peer support", "Early flag", 
                              "Check-in", "Content shift", "Employer intro", "Return prep",
                              "Consolidation", "2-year review")
      
      p <- plotly::plot_ly() %>%
        plotly::add_trace(x = weeks_full, y = no_support_risk, name = "Standard care (no app)",
                         fill = "tozeroy", type = "scatter", mode = "lines",
                         fillcolor = "rgba(149, 165, 166, 0.2)",
                         line = list(color = "#95a5a6", width = 2, dash = "dash")) %>%
        plotly::add_trace(x = weeks_full, y = with_support_risk, name = "Structured support (with app)",
                         fill = "tozeroy", type = "scatter", mode = "lines",
                         fillcolor = "rgba(102, 126, 234, 0.2)",
                         line = list(color = "#667eea", width = 3)) %>%
        plotly::add_trace(x = intervention_weeks, y = with_support_risk[intervention_weeks + 9],
                         mode = "markers", type = "scatter",
                         marker = list(size = 10, color = "#e74c3c", symbol = "diamond"),
                         name = "Intervention touchpoint",
                         hovertext = intervention_labels,
                         hovertemplate = "<b>%{hovertext}</b><br>Week %{x}<extra></extra>")
      
      p %>%
        apply_plotly_theme(
          x_title = "Weeks (pregnancy to 2 years postpartum)",
          y_title = "Illustrative mental health risk index (0-100)",
          title = "Maternal mental health risk trajectory: With vs without structured support"
        ) %>%
        add_vline_shape(x = 0, color = "#8fa3c8", width = 1, dash = "dot", label = "Birth") %>%
        add_vline_shape(x = 52, color = "#8fa3c8", width = 1, dash = "dot", label = "Return to work")
    })
    
    # Intervention details (clickable)
    output$intervention_detail <- renderUI({
      interventions <- list(
        list(week = -4, title = "Antenatal screening & psychoeducation",
             evidence = "Bauer et al. (2014)",
             detail = "Structured screening identifies mothers at risk before birth. Psychoeducation normalises the transition and sets expectations."),
        list(week = 1, title = "Immediate postnatal safety planning",
             evidence = "Dennis & Dowswell (2013)",
             detail = "First contact post-delivery: clarify warning signs, establish 24/7 access to support, introduce continuous monitoring."),
        list(week = 6, title = "Peer support & group contact initiation",
             evidence = "Dennis & Dowswell (2013)",
             detail = "Peer support is a first-line intervention for postnatal mood. App enables asynchronous peer connection and group check-ins."),
        list(week = 14, title = "Early detection & clinical escalation if flagged",
             evidence = "Hurwitz et al. (2024)",
             detail = "First automated risk flag typically appears by week 4-6. This touchpoint: clinician review, symptom-triggered intervention."),
        list(week = 24, title = "Comprehensive 6-month review & adjustment",
             evidence = "Cox et al. (1987)",
             detail = "Standard 6-month check-in: formal EPDS, review of support needs, treatment adjustment if needed, planning for return-to-work."),
        list(week = 30, title = "Return-to-work planning & employer engagement",
             evidence = "Abdalrazaq et al. (2023)",
             detail = "Proactive engagement with employer (with consent): flexible return, lactation support, mental health accommodation."),
        list(week = 38, title = "Intensive employer support & continuity protocol",
             evidence = "Abdalrazaq et al. (2023)",
             detail = "Most mothers return to work around week 39 (9 months). Continuous monitoring and workplace adjustment critical."),
        list(week = 52, title = "Return-to-work transition checkpoint",
             evidence = "Bauer et al. (2014)",
             detail = "Highest-risk period: role strain, identity shift, support drop-off. Intensive touchpoints, carer support, workplace flexibility.")
      )
      
      lapply(interventions, function(i) {
        div(style="background:rgba(255,255,255,0.04); border-left:4px solid #667eea; padding:12px; margin-bottom:12px; border-radius:4px;",
          tags$strong(paste0("Week ", i$week, ": ", i$title)),
          br(),
          tags$em(i$evidence),
          br(),
          tags$p(style="font-size:12px; margin-top:6px; color:rgba(255,255,255,0.8);", i$detail)
        )
      })
    })
    
    # Continuation of other tabs (Tabs 1-3 largely unchanged, so code included but abbreviated)
    # [Include output statements for tabs 1-3 from original server if not shown above]
    
  })
}
