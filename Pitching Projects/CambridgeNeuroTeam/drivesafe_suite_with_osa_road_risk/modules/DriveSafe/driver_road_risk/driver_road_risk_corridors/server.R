# modules/DriveSafe/driver_road_risk/driver_road_risk_corridors/server.R
# High-Risk Corridors Server

driver_road_risk_corridors_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Full corridor x group x time-window risk table at the selected duration,
    # averaged across time windows per corridor/group for ranking purposes.
    corridor_group_means <- reactive({
      req(input$c_duration)
      s <- build_corridor_risk_summary(duration_hours = input$c_duration)
      agg <- aggregate(risk_score ~ corridor_id + corridor_name + road_type + osa_group,
                        data = s, FUN = mean)
      agg$risk_score <- round(agg$risk_score, 1)
      agg
    })

    # Wide table: one row per corridor, one column per group
    corridor_wide <- reactive({
      agg <- corridor_group_means()
      wide <- reshape(agg, idvar = c("corridor_id","corridor_name","road_type"),
                       timevar = "osa_group", direction = "wide")
      names(wide) <- gsub("^risk_score\\.", "", names(wide))
      wide$cpap_benefit <- round(wide$osa_untreated - wide$osa_treated, 1)
      wide
    })

    # ── Top 10 highest-risk corridors (ranked by untreated risk) ────────────
    output$top10_chart <- plotly::renderPlotly({
      agg <- corridor_group_means()
      sel <- input$c_groups %||% names(OSA_GROUP_UPLIFT)

      rank_order <- aggregate(risk_score ~ corridor_name, agg[agg$osa_group == "osa_untreated", ], mean)
      rank_order <- rank_order[order(-rank_order$risk_score), ]
      top_names  <- head(rank_order$corridor_name, 10)

      p <- plotly::plot_ly()
      for (g in intersect(names(OSA_GROUP_UPLIFT), sel)) {
        sub <- agg[agg$osa_group == g & agg$corridor_name %in% top_names, ]
        sub <- sub[match(rev(top_names), sub$corridor_name), ]
        p <- plotly::add_trace(p, x = sub$risk_score, y = sub$corridor_name,
          type = "bar", orientation = "h", name = OSA_GROUP_LABELS[g],
          marker = list(color = OSA_GROUP_COLOURS[g]))
      }
      p |> plotly::layout(
        barmode = "group",
        xaxis = list(title = "Mean Risk Score", range = c(0, 100)),
        yaxis = list(title = "", categoryorder = "array", categoryarray = rev(top_names)),
        legend = list(orientation = "h", y = -0.15)
      )
    })

    # ── Treatment effect lollipop by road type ──────────────────────────────
    output$lollipop_chart <- plotly::renderPlotly({
      agg <- corridor_group_means()
      rtypes <- names(ROAD_TYPE_LABELS)

      by_road <- lapply(rtypes, function(rt) {
        sub <- agg[agg$road_type == rt, ]
        c(untreated = mean(sub$risk_score[sub$osa_group == "osa_untreated"]),
          treated   = mean(sub$risk_score[sub$osa_group == "osa_treated"]),
          control   = mean(sub$risk_score[sub$osa_group == "control"]))
      })
      m <- do.call(rbind, by_road)
      rownames(m) <- ROAD_TYPE_LABELS[rtypes]

      p <- plotly::plot_ly()
      for (i in seq_len(nrow(m))) {
        p <- plotly::add_segments(p,
          x = m[i, "treated"], xend = m[i, "untreated"],
          y = rownames(m)[i], yend = rownames(m)[i],
          line = list(color = "#bbb", width = 2), showlegend = FALSE)
      }
      p <- plotly::add_trace(p, x = m[, "untreated"], y = rownames(m), type = "scatter",
        mode = "markers", marker = list(color = OSA_GROUP_COLOURS["osa_untreated"], size = 14),
        name = "OSA - Untreated")
      p <- plotly::add_trace(p, x = m[, "treated"], y = rownames(m), type = "scatter",
        mode = "markers", marker = list(color = OSA_GROUP_COLOURS["osa_treated"], size = 14),
        name = "OSA - CPAP Treated")

      p |> plotly::layout(
        xaxis = list(title = "Mean Risk Score", range = c(0, 100)),
        yaxis = list(title = ""),
        legend = list(orientation = "h", y = -0.2)
      )
    })

    # ── Corridor x time-of-day heatmap ───────────────────────────────────────
    output$corridor_time_heatmap <- plotly::renderPlotly({
      req(input$c_heatmap_group, input$c_duration)
      s <- build_corridor_risk_summary(duration_hours = input$c_duration)
      s <- s[s$osa_group == input$c_heatmap_group, ]

      corridor_order <- uk_osa_corridors$corridor_name
      mat <- matrix(NA, nrow = length(corridor_order), ncol = length(TIME_WINDOWS),
                     dimnames = list(corridor_order, TIME_WINDOWS))
      for (i in seq_len(nrow(s))) {
        mat[s$corridor_name[i], s$time_window[i]] <- s$risk_score[i]
      }

      plotly::plot_ly(
        x = TIME_WINDOW_LABELS[TIME_WINDOWS], y = corridor_order, z = mat,
        type = "heatmap",
        colorscale = list(list(0, "#1a6b35"), list(0.33, "#d4ac0d"),
                           list(0.66, "#e67e22"), list(1, "#c0392b")),
        zmin = 0, zmax = 100,
        colorbar = list(title = "Risk Score"),
        hovertemplate = "Corridor: %{y}<br>Window: %{x}<br>Risk: %{z:.1f}<extra></extra>"
      ) |>
        plotly::layout(
          xaxis = list(title = ""),
          yaxis = list(title = "", autorange = "reversed")
        )
    })

    # ── Journey duration risk profile ────────────────────────────────────────
    output$duration_profile_chart <- plotly::renderPlotly({
      sel <- input$c_groups %||% names(OSA_GROUP_UPLIFT)
      durations <- c("Short (<2h)" = 1, "Medium (2-4h)" = 3, "Long (>4h)" = 6)

      p <- plotly::plot_ly()
      for (g in intersect(names(OSA_GROUP_UPLIFT), sel)) {
        vals <- sapply(durations, function(d) {
          s <- build_corridor_risk_summary(duration_hours = d)
          mean(s$risk_score[s$osa_group == g])
        })
        p <- plotly::add_trace(p, x = names(durations), y = round(vals, 1),
          type = "scatter", mode = "lines+markers", name = OSA_GROUP_LABELS[g],
          line = list(color = OSA_GROUP_COLOURS[g], width = 3),
          marker = list(color = OSA_GROUP_COLOURS[g], size = 10))
      }
      p |> plotly::layout(
        xaxis = list(title = "Journey Duration"),
        yaxis = list(title = "Mean Risk Score (all corridors)", range = c(0, 100), gridcolor = "#eee"),
        legend = list(orientation = "h", y = -0.25)
      )
    })

    # ── Full corridor table ──────────────────────────────────────────────────
    output$corridor_table <- DT::renderDataTable({
      w <- corridor_wide()
      tab <- data.frame(
        Corridor       = w$corridor_name,
        `Road Type`    = ROAD_TYPE_LABELS[w$road_type],
        `Control`      = w$control,
        `CPAP Treated` = w$osa_treated,
        `Untreated`    = w$osa_untreated,
        `CPAP Benefit` = w$cpap_benefit,
        check.names = FALSE, stringsAsFactors = FALSE
      )
      tab <- tab[order(-tab$Untreated), ]

      DT::datatable(tab,
        options  = list(pageLength = 8, order = list(list(4, "desc"))),
        rownames = FALSE,
        class    = "table table-bordered table-hover"
      ) |>
        DT::formatStyle("Untreated",
          backgroundColor = DT::styleInterval(c(25, 50, 75), RISK_SCALE_COLOURS),
          color = "white", fontWeight = "bold"
        ) |>
        DT::formatStyle("CPAP Benefit",
          backgroundColor = DT::styleInterval(c(5, 15), c("#f8d7da", "#fff3cd", "#d4edda"))
        )
    })

    output$dl_corridor_csv <- downloadHandler(
      filename = function() paste0("osa_corridor_risk_", Sys.Date(), ".csv"),
      content = function(file) {
        w <- corridor_wide()
        tab <- data.frame(
          corridor       = w$corridor_name,
          road_type      = ROAD_TYPE_LABELS[w$road_type],
          control_risk   = w$control,
          cpap_treated_risk = w$osa_treated,
          untreated_risk = w$osa_untreated,
          cpap_benefit   = w$cpap_benefit
        )
        write.csv(tab, file, row.names = FALSE)
      }
    )

  })
}
