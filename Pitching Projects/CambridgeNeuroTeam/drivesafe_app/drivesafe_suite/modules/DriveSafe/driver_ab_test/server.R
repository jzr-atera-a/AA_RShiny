# modules/DriveSafe/driver_ab_test/server.R
# DriveSafe - A/B Test Server
# Comparison: OSA Treated vs OSA Untreated vs Control

driver_ab_test_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    col_control     <- "#008A82"   # teal  - control
    col_treated     <- "#27ae60"   # green - CPAP treated
    col_untreated   <- "#e74c3c"   # red   - untreated
    col_bg          <- "#ffffff"
    amber           <- "#f39c12"

    group_colours <- c(
      control       = col_control,
      osa_treated   = col_treated,
      osa_untreated = col_untreated
    )
    group_labels <- c(
      control       = "Control (No OSA)",
      osa_treated   = "OSA - CPAP Treated",
      osa_untreated = "OSA - Untreated"
    )

    driver_meta <- data.frame(
      driver_id   = paste0("D00", 1:8),
      driver_name = c("Adams, J","Patel, R","Okafor, C","Williams, S",
                      "Hassan, M","Chen, L","Thompson, K","Singh, P"),
      osa_group   = c("control","osa_treated","control","osa_untreated",
                      "control","control","osa_treated","osa_untreated"),
      stringsAsFactors = FALSE
    )

    # ── Simulate A/B dataset ─────────────────────────────────────────────────
    sim_counter <- reactiveVal(0)
    observeEvent(input$btn_resim, { sim_counter(sim_counter() + 1) })

    ab_data <- reactive({
      sim_counter()
      seed_val <- as.integer(Sys.time()) %% 10000
      set.seed(seed_val)
      n <- 600
      groups_full <- rep(c("control","osa_treated","osa_untreated"), each = n / 3)
      driver_pool <- list(
        control       = c("D001","D003","D005","D006"),
        osa_treated   = c("D002","D007"),
        osa_untreated = c("D004","D008")
      )
      drivers <- unlist(lapply(groups_full, function(g) {
        sample(driver_pool[[g]], 1)
      }))

      journey_hours <- runif(n, 0, 8)

      kss <- pmax(1, pmin(9,
        ifelse(groups_full == "control",       3.2 + journey_hours * 0.5  + rnorm(n, 0, 0.6),
        ifelse(groups_full == "osa_treated",   3.8 + journey_hours * 0.55 + rnorm(n, 0, 0.7),
                                               5.1 + journey_hours * 0.75 + rnorm(n, 0, 0.8)))
      ))

      rt <- pmax(180,
        ifelse(groups_full == "control",       310 + journey_hours * 15 + rnorm(n, 0, 28),
        ifelse(groups_full == "osa_treated",   340 + journey_hours * 17 + rnorm(n, 0, 30),
                                               420 + journey_hours * 22 + rnorm(n, 0, 38)))
      )

      mw <- pmax(0, pmin(100,
        ifelse(groups_full == "control",       18 + journey_hours * 5.5 + rnorm(n, 0, 7),
        ifelse(groups_full == "osa_treated",   22 + journey_hours * 6   + rnorm(n, 0, 8),
                                               35 + journey_hours * 9   + rnorm(n, 0, 9)))
      ))

      osa_comp <- pmax(0, pmin(100,
        ifelse(groups_full == "control",       15 + rnorm(n, 0, 8),
        ifelse(groups_full == "osa_treated",   28 + rnorm(n, 0, 10),
                                               58 + rnorm(n, 0, 12)))
      ))

      sleep_q <- pmax(1, pmin(10,
        ifelse(groups_full == "control",       7.8 + rnorm(n, 0, 0.7),
        ifelse(groups_full == "osa_treated",   6.9 + rnorm(n, 0, 0.8),
                                               4.8 + rnorm(n, 0, 1.0)))
      ))

      speed_var <- pmax(0,
        ifelse(groups_full == "control",       7   + journey_hours * 0.9 + rnorm(n, 0, 1.5),
        ifelse(groups_full == "osa_treated",   9   + journey_hours * 1.0 + rnorm(n, 0, 1.8),
                                               13  + journey_hours * 1.5 + rnorm(n, 0, 2.2)))
      )

      hard_braking <- pmax(0, round(
        ifelse(groups_full == "control",       0.3 + journey_hours * 0.3 + rnorm(n, 0, 0.3),
        ifelse(groups_full == "osa_treated",   0.5 + journey_hours * 0.35+ rnorm(n, 0, 0.35),
                                               1.1 + journey_hours * 0.55+ rnorm(n, 0, 0.4)))
      ))

      pvt_lapses <- pmax(0, round(
        ifelse(groups_full == "control",       0.1 + journey_hours * 0.3 + rnorm(n, 0, 0.2),
        ifelse(groups_full == "osa_treated",   0.3 + journey_hours * 0.4 + rnorm(n, 0, 0.3),
                                               1.2 + journey_hours * 0.8 + rnorm(n, 0, 0.5)))
      ))

      data.frame(
        driver_id     = drivers,
        osa_group     = groups_full,
        journey_hour  = round(journey_hours, 2),
        kss           = round(kss, 2),
        reaction_time = round(rt),
        mind_wander   = round(mw, 1),
        osa_composite = round(osa_comp, 1),
        sleep_quality = round(sleep_q, 2),
        speed_variance = round(speed_var, 2),
        hard_braking  = hard_braking,
        pvt_lapses    = pvt_lapses,
        kss_score         = round(kss, 2),
        reaction_time_ms  = round(rt),
        mind_wander_idx   = round(mw, 1),
        osa_risk_score    = round(osa_comp, 1),
        pvt_lapses_n      = pvt_lapses,
        stringsAsFactors = FALSE
      )
    })

    filtered_ab <- reactive({
      d <- ab_data()
      sel <- input$ab_groups
      if (is.null(sel) || length(sel) == 0) return(d)
      d[d$osa_group %in% sel, ]
    })

    # ── Group mean helper ────────────────────────────────────────────────────
    grp_mean <- function(col) {
      d <- ab_data()
      tapply(d[[col]], d$osa_group, mean, na.rm = TRUE)
    }

    # ── KPI Effect Size Boxes ─────────────────────────────────────────────────
    output$ab_kss_delta <- renderValueBox({
      m  <- grp_mean("kss")
      delta <- round(m["osa_untreated"] - m["osa_treated"], 2)
      valueBox(
        paste0(ifelse(delta > 0, "+", ""), delta, " KSS pts"),
        "Treatment Improvement (KSS)",
        icon  = icon("eye"),
        color = if (delta > 0.8) "green" else if (delta > 0) "yellow" else "red"
      )
    })

    output$ab_rt_delta <- renderValueBox({
      m     <- grp_mean("reaction_time")
      delta <- round(m["osa_untreated"] - m["osa_treated"])
      valueBox(
        paste0(ifelse(delta > 0, "-", "+"), abs(delta), " ms"),
        "RT Improvement (CPAP vs Untreated)",
        icon  = icon("bolt"),
        color = if (delta > 40) "green" else if (delta > 0) "yellow" else "red"
      )
    })

    output$ab_osa_delta <- renderValueBox({
      m     <- grp_mean("osa_composite")
      delta <- round(m["osa_untreated"] - m["osa_treated"], 1)
      valueBox(
        paste0(ifelse(delta > 0, "-", "+"), abs(delta), " pts"),
        "OSA Risk Reduction",
        icon  = icon("bed"),
        color = if (delta > 15) "green" else if (delta > 5) "yellow" else "red"
      )
    })

    output$ab_lapse_delta <- renderValueBox({
      m     <- grp_mean("pvt_lapses")
      delta <- round(m["osa_untreated"] - m["osa_treated"], 2)
      valueBox(
        paste0(ifelse(delta > 0, "-", "+"), abs(delta), " lapses"),
        "PVT Lapse Reduction",
        icon  = icon("brain"),
        color = if (delta > 0.5) "green" else if (delta > 0) "yellow" else "red"
      )
    })

    # ── Violin: KSS ──────────────────────────────────────────────────────────
    output$ab_kss_violin <- plotly::renderPlotly({
      d   <- filtered_ab()
      sel <- input$ab_groups %||% c("control","osa_treated","osa_untreated")
      p   <- plotly::plot_ly()
      for (g in sel) {
        sub <- d[d$osa_group == g, ]
        p <- plotly::add_trace(p,
          type = "violin", y = sub$kss,
          name = group_labels[g],
          box = list(visible = TRUE),
          meanline = list(visible = TRUE),
          line  = list(color = group_colours[g]),
          fillcolor = paste0(group_colours[g], "44"),
          points = "outliers"
        )
      }
      p |> plotly::layout(
        yaxis   = list(title = "KSS Score (1=Alert, 9=Very Sleepy)", gridcolor = "#eee"),
        xaxis   = list(title = "Group"),
        legend  = list(orientation = "h", y = -0.25),
        violinmode  = "group",
        plot_bgcolor  = col_bg, paper_bgcolor = col_bg
      )
    })

    # ── Violin: Reaction Time ─────────────────────────────────────────────────
    output$ab_rt_violin <- plotly::renderPlotly({
      d   <- filtered_ab()
      sel <- input$ab_groups %||% c("control","osa_treated","osa_untreated")
      p   <- plotly::plot_ly()
      for (g in sel) {
        sub <- d[d$osa_group == g, ]
        p <- plotly::add_trace(p,
          type = "violin", y = sub$reaction_time,
          name = group_labels[g],
          box  = list(visible = TRUE),
          meanline = list(visible = TRUE),
          line  = list(color = group_colours[g]),
          fillcolor = paste0(group_colours[g], "44"),
          points = "outliers"
        )
      }
      p |> plotly::layout(
        yaxis  = list(title = "Reaction Time (ms)", gridcolor = "#eee"),
        xaxis  = list(title = "Group"),
        legend = list(orientation = "h", y = -0.25),
        violinmode   = "group",
        plot_bgcolor = col_bg, paper_bgcolor = col_bg
      )
    })

    # ── Box: OSA Composite ────────────────────────────────────────────────────
    output$ab_osa_box <- plotly::renderPlotly({
      d   <- filtered_ab()
      sel <- input$ab_groups %||% c("control","osa_treated","osa_untreated")
      p   <- plotly::plot_ly()
      for (g in sel) {
        sub <- d[d$osa_group == g, ]
        p <- plotly::add_trace(p,
          type = "box", y = sub$osa_composite,
          name = group_labels[g],
          marker = list(color = group_colours[g], outliercolor = group_colours[g]),
          line   = list(color = group_colours[g]),
          fillcolor = paste0(group_colours[g], "55"),
          boxmean = TRUE
        )
      }
      p |> plotly::layout(
        yaxis  = list(title = "OSA Composite Risk Score (0-100)", gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.25),
        plot_bgcolor = col_bg, paper_bgcolor = col_bg
      )
    })

    # ── Box: Mind Wandering ───────────────────────────────────────────────────
    output$ab_mw_box <- plotly::renderPlotly({
      d   <- filtered_ab()
      sel <- input$ab_groups %||% c("control","osa_treated","osa_untreated")
      p   <- plotly::plot_ly()
      for (g in sel) {
        sub <- d[d$osa_group == g, ]
        p <- plotly::add_trace(p,
          type = "box", y = sub$mind_wander,
          name = group_labels[g],
          marker = list(color = group_colours[g]),
          line   = list(color = group_colours[g]),
          fillcolor = paste0(group_colours[g], "55"),
          boxmean = TRUE
        )
      }
      p |> plotly::layout(
        yaxis  = list(title = "Mind Wandering Index (0-100)", gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.25),
        plot_bgcolor = col_bg, paper_bgcolor = col_bg
      )
    })

    # ── Journey Evolution Plot ────────────────────────────────────────────────
    output$ab_journey_plot <- plotly::renderPlotly({
      d      <- filtered_ab()
      metric <- input$ab_journey_metric %||% "kss"
      show_ci <- isTRUE(input$ab_show_ci)
      smooth_w <- input$ab_smooth %||% 1
      sel    <- input$ab_groups %||% c("control","osa_treated","osa_untreated")

      label_map <- c(
        kss           = "KSS Alertness Score",
        reaction_time = "Reaction Time (ms)",
        mind_wander   = "Mind Wandering Index",
        osa_composite = "OSA Composite Risk Score",
        speed_variance = "Speed Variance (km/h)",
        hard_braking  = "Hard Braking Events",
        pvt_lapses    = "PVT Lapse Count"
      )

      hr_breaks <- seq(0, 8, by = 0.5)
      p <- plotly::plot_ly()

      for (g in sel) {
        sub <- d[d$osa_group == g, ]
        if (nrow(sub) == 0) next
        sub$hr_bin <- cut(sub$journey_hour, breaks = hr_breaks, labels = hr_breaks[-1],
                          include.lowest = TRUE)
        sub$hr_bin <- as.numeric(as.character(sub$hr_bin))
        agg <- aggregate(sub[[metric]] ~ hr_bin, data = sub, FUN = mean, na.rm = TRUE)
        names(agg) <- c("hr", "mean_val")
        agg_sd <- aggregate(sub[[metric]] ~ hr_bin, data = sub, FUN = sd, na.rm = TRUE)
        names(agg_sd) <- c("hr", "sd_val")
        agg$sd_val <- agg_sd$sd_val[match(agg$hr, agg_sd$hr)]
        agg <- agg[!is.na(agg$hr), ]
        agg <- agg[order(agg$hr), ]

        p <- plotly::add_trace(p,
          x = agg$hr, y = agg$mean_val,
          type = "scatter", mode = "lines+markers",
          name = group_labels[g],
          line   = list(color = group_colours[g], width = 2.5),
          marker = list(color = group_colours[g], size = 6)
        )

        if (show_ci && !all(is.na(agg$sd_val))) {
          p <- plotly::add_trace(p,
            x = c(agg$hr, rev(agg$hr)),
            y = c(agg$mean_val + agg$sd_val, rev(agg$mean_val - agg$sd_val)),
            type = "scatter", mode = "none",
            fill = "toself",
            fillcolor = paste0(group_colours[g], "22"),
            name = paste0(group_labels[g], " CI"),
            showlegend = FALSE,
            hoverinfo = "skip"
          )
        }
      }

      p |> plotly::layout(
        xaxis  = list(title = "Journey Hour", gridcolor = "#eee"),
        yaxis  = list(title = label_map[metric], gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.25),
        hovermode    = "x unified",
        plot_bgcolor = col_bg, paper_bgcolor = col_bg
      )
    })

    # ── Summary Stats Table ───────────────────────────────────────────────────
    output$effect_size_note <- renderUI({
      m <- grp_mean(input$ab_summary_metric %||% "kss_score")
      ctrl <- m["control"]
      trt  <- m["osa_treated"]
      unt  <- m["osa_untreated"]
      pct_improvement <- if (!is.na(trt) && !is.na(unt) && unt != 0)
        round((unt - trt) / abs(unt) * 100, 1) else NA

      div(class = "status-success",
        icon("chart-line"),
        tags$strong(" Treatment Effect: "),
        if (!is.na(pct_improvement))
          paste0("CPAP-treated drivers show a ",
                 abs(pct_improvement), "% ",
                 ifelse(pct_improvement > 0, "improvement", "change"),
                 " vs untreated OSA on this metric. ",
                 "Control group mean: ", round(ctrl, 2), ".")
        else "Select a metric to see treatment effect summary."
      )
    })

    output$ab_summary_table <- DT::renderDataTable({
      metric <- input$ab_summary_metric %||% "kss_score"
      d <- ab_data()
      grps <- c("control","osa_treated","osa_untreated")

      rows <- lapply(grps, function(g) {
        sub <- d[d$osa_group == g, metric]
        data.frame(
          Group        = group_labels[g],
          N            = length(sub),
          Mean         = round(mean(sub,   na.rm = TRUE), 3),
          Median       = round(median(sub, na.rm = TRUE), 3),
          SD           = round(sd(sub,     na.rm = TRUE), 3),
          Min          = round(min(sub,    na.rm = TRUE), 3),
          Max          = round(max(sub,    na.rm = TRUE), 3),
          Q25          = round(quantile(sub, 0.25, na.rm = TRUE), 3),
          Q75          = round(quantile(sub, 0.75, na.rm = TRUE), 3),
          stringsAsFactors = FALSE
        )
      })
      tab <- do.call(rbind, rows)

      DT::datatable(tab,
        options  = list(dom = "t", ordering = FALSE),
        rownames = FALSE,
        class    = "table table-bordered table-hover"
      ) |>
        DT::formatStyle("Group",
          backgroundColor = DT::styleEqual(
            c("Control (No OSA)","OSA - CPAP Treated","OSA - Untreated"),
            c("#d4f7f5","#d4edda","#f8d7da")
          ),
          fontWeight = "bold"
        )
    })

    # ── Multi-metric Heatmap ─────────────────────────────────────────────────
    output$ab_heatmap <- plotly::renderPlotly({
      d <- ab_data()
      metrics  <- c("kss","reaction_time","mind_wander","osa_composite",
                    "speed_variance","pvt_lapses","sleep_quality")
      m_labels <- c("KSS","RT","Mind Wander","OSA Risk",
                    "Speed Var","PVT Lapses","Sleep Qual")

      grps <- c("control","osa_treated","osa_untreated")
      # Normalise each metric to 0-100 where 100 = best performance
      norm_score <- function(vals, higher_is_worse) {
        rng <- range(vals, na.rm = TRUE)
        if (rng[1] == rng[2]) return(rep(50, length(vals)))
        s <- (vals - rng[1]) / (rng[2] - rng[1]) * 100
        if (higher_is_worse) 100 - s else s
    }
      higher_is_worse <- c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE)

      mat <- matrix(NA, nrow = length(grps), ncol = length(metrics))
      for (j in seq_along(metrics)) {
        all_vals <- d[[metrics[j]]]
        for (i in seq_along(grps)) {
          sub_vals <- d[[metrics[j]]][d$osa_group == grps[i]]
          normed   <- norm_score(all_vals, higher_is_worse[j])
          mat[i,j] <- mean(normed[d$osa_group == grps[i]], na.rm = TRUE)
        }
      }

      plotly::plot_ly(
        x = m_labels,
        y = group_labels[grps],
        z = mat,
        type = "heatmap",
        colorscale = list(
          list(0,   "#e74c3c"),
          list(0.5, "#f39c12"),
          list(1,   "#27ae60")
        ),
        colorbar = list(title = "Performance\nScore (0-100)"),
        text = round(mat, 1),
        texttemplate = "%{text}",
        hovertemplate = "Group: %{y}<br>Metric: %{x}<br>Score: %{z:.1f}<extra></extra>"
      ) |>
        plotly::layout(
          xaxis = list(title = ""),
          yaxis = list(title = ""),
          paper_bgcolor = col_bg
        )
    })

    # ── Per-driver delta chart ────────────────────────────────────────────────
    output$ab_driver_delta <- plotly::renderPlotly({
      d <- ab_data()
      unt_baseline <- mean(d$kss[d$osa_group == "osa_untreated"], na.rm = TRUE)

      per_driver <- aggregate(kss ~ driver_id, data = d, FUN = mean, na.rm = TRUE)
      per_driver <- merge(per_driver, driver_meta, by = "driver_id")
      per_driver$delta <- round(unt_baseline - per_driver$kss, 2)
      per_driver <- per_driver[order(per_driver$delta, decreasing = TRUE), ]

      bar_cols <- ifelse(per_driver$osa_group == "osa_untreated", col_untreated,
                  ifelse(per_driver$osa_group == "osa_treated",   col_treated,
                                                                   col_control))

      plotly::plot_ly(
        x = per_driver$driver_name,
        y = per_driver$delta,
        type = "bar",
        marker = list(color = bar_cols, line = list(color = "#fff", width = 0.5)),
        text   = paste0(per_driver$osa_group),
        hovertemplate = "Driver: %{x}<br>Delta vs Untreated Baseline: %{y:.2f}<br>Group: %{text}<extra></extra>"
      ) |>
        plotly::add_segments(
          x = -0.5, xend = nrow(per_driver) - 0.5, y = 0, yend = 0,
          line = list(color = "#999", dash = "dash", width = 1),
          showlegend = FALSE
        ) |>
        plotly::layout(
          xaxis  = list(title = "Driver", categoryorder = "array",
                        categoryarray = per_driver$driver_name),
          yaxis  = list(title = "KSS Delta vs Untreated OSA Baseline",
                        gridcolor = "#eee", zeroline = FALSE),
          annotations = list(
            list(x = 0.02, y = 0.98, text = "Above line = better than untreated OSA",
                 showarrow = FALSE, xref = "paper", yref = "paper",
                 font = list(color = "#666", size = 10), xanchor = "left")
          ),
          plot_bgcolor = col_bg, paper_bgcolor = col_bg,
          showlegend = FALSE
        )
    })

  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
