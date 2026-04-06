# modules/chapter3.R
# Chapter 3: Monitoring the System
# Theory + Code Lab: A/B Test Significance Calculator, Sample Size Planner, CTR Monitor

chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 3: Monitoring the System"),
        tags$h2("Analytics, A/B Testing, and Measuring Recommender Performance"),
        div(
          span(class = "hero-badge", "A/B Testing"),
          span(class = "hero-badge", "Monitoring"),
          span(class = "hero-badge", "Statistical Significance"),
          span(class = "hero-badge", "CTR Tracking")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "p<0.05"),
                          span(class = "metric-label", "Significance Threshold"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "CTR"),
                          span(class = "metric-label", "Primary Metric"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "2"),
                          span(class = "metric-label", "Test Groups"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "80%"),
                          span(class = "metric-label", "Min Statistical Power")))
          )
      )
    ),

    fluidRow(
      tabBox(
        width = 12, id = ns("ch3_tabs"),

        # ─────────────────────────────────────────────────────
        # THEORY TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "📊 Why Monitoring Matters", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "success-box",
                    HTML("<strong>✅ Core Principle:</strong> You can't improve what you don't measure.
                    Recommender systems need continuous monitoring to detect degradation and validate improvements.")),
                br(),
                div(class = "framework-card",
                    tags$h5("What to Monitor"),
                    tags$ul(
                      tags$li(HTML("<strong>Click-Through Rate (CTR):</strong> % of recommendations clicked")),
                      tags$li(HTML("<strong>Conversion Rate:</strong> % of recommendations leading to purchase")),
                      tags$li(HTML("<strong>Coverage:</strong> % of catalogue recommended")),
                      tags$li(HTML("<strong>Diversity:</strong> Variety in recommendations")),
                      tags$li(HTML("<strong>Latency:</strong> How fast recommendations are served"))
                    )
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("The MovieGEEK Analytics Dashboard"),
                    tags$p("The analytics app provides two views:"),
                    tags$p(HTML("<strong>Content view:</strong> Item performance, similarity graphs")),
                    tags$p(HTML("<strong>User view:</strong> User behaviour, taste profiles")),
                    tags$p(HTML("<strong>URL:</strong> <code>/analytics/</code>"))
                )
            ),

            box(title = "🔬 A/B Testing Recommenders", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "The Gold Standard for RecSys Validation"),
                div(class = "framework-card",
                    tags$h5("How A/B Testing Works"),
                    tags$p(HTML("<strong>Group A (Control):</strong> Existing recommendation algorithm")),
                    tags$p(HTML("<strong>Group B (Treatment):</strong> New algorithm being tested")),
                    tags$p(HTML("<strong>Random split:</strong> Users randomly assigned to groups")),
                    tags$p(HTML("<strong>Measure:</strong> CTR, conversion, engagement per group")),
                    tags$p(HTML("<strong>Decide:</strong> Is difference statistically significant?"))
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 Key Insight from Kim Falk:</strong> Offline metrics (RMSE, Precision@K)
                    often don't predict online success. A/B testing is the only way to truly validate
                    a recommender system.")),
                br(),
                div(class = "warn-box",
                    HTML("<strong>⚠️ Common Mistakes:</strong>
                    <ul>
                      <li>Stopping the test too early (peeking problem)</li>
                      <li>Not accounting for seasonality</li>
                      <li>Using the wrong metric (CTR ≠ revenue)</li>
                      <li>Insufficient sample size</li>
                    </ul>"))
            )
          ),

          fluidRow(
            box(title = "📈 Key Monitoring Metrics", status = "success",
                solidHeader = TRUE, width = 12,
                fluidRow(
                  column(4, div(class = "framework-card",
                                tags$h5("Click-Through Rate (CTR)"),
                                tags$p(HTML("<strong>Formula:</strong> Clicks / Impressions")),
                                tags$p(HTML("<strong>Typical values:</strong> 0.5–5% in RecSys")),
                                tags$p("Higher CTR = recommendations more relevant to users")
                  )),
                  column(4, div(class = "framework-card",
                                tags$h5("Conversion Rate"),
                                tags$p(HTML("<strong>Formula:</strong> Purchases / Clicks")),
                                tags$p(HTML("<strong>Business impact:</strong> Direct revenue link")),
                                tags$p("Filters out casual browsers from genuine buyers")
                  )),
                  column(4, div(class = "framework-card",
                                tags$h5("Coverage"),
                                tags$p(HTML("<strong>Formula:</strong> Recommended items / Total items")),
                                tags$p(HTML("<strong>Problem:</strong> Poor coverage = popularity bias")),
                                tags$p("Good RecSys surfaces the long tail, not just hits")
                  ))
                )
            )
          )
        ), # end Theory

        # ─────────────────────────────────────────────────────
        # CODE LAB TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "A/B Test Calculator & CTR Monitor",
            subtitle = "Run a Z-test for proportions, calculate required sample sizes, and simulate CTR monitoring dashboards.",
            badges   = c("R", "stats", "plotly")
          ),

          # ── Section 1: A/B Test Significance ──────────────
          fluidRow(
            box(title = "🔬 A/B Test Significance Calculator", status = "primary",
                solidHeader = TRUE, width = 7,
                div(class = "section-heading-dark",
                    "Two-Proportion Z-Test — the standard test for RecSys experiments"),
                div(class = "control-panel",
                    fluidRow(
                      column(6,
                             tags$div(class = "section-heading-dark", "Control Group (A)"),
                             numericInput(ns("ctrl_impressions"), "Impressions", value = 10000, min = 100),
                             numericInput(ns("ctrl_clicks"),      "Clicks",      value = 230,   min = 0)
                      ),
                      column(6,
                             tags$div(class = "section-heading-dark", "Treatment Group (B)"),
                             numericInput(ns("trt_impressions"),  "Impressions", value = 10000, min = 100),
                             numericInput(ns("trt_clicks"),       "Clicks",      value = 285,   min = 0)
                      )
                    ),
                    sliderInput(ns("alpha_level"), "Significance level (α)",
                                min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                    run_button(ns("run_abtest"), "▶  Run A/B Test")
                ),
                uiOutput(ns("abtest_result")),
                br(),
                r_code_block(
'# Two-proportion Z-test for A/B testing
# (standard in RecSys monitoring)

ab_test <- function(n_ctrl, x_ctrl, n_trt, x_trt, alpha = 0.05) {
  p_ctrl <- x_ctrl / n_ctrl
  p_trt  <- x_trt  / n_trt
  p_pool <- (x_ctrl + x_trt) / (n_ctrl + n_trt)

  se     <- sqrt(p_pool * (1 - p_pool) * (1/n_ctrl + 1/n_trt))
  z      <- (p_trt - p_ctrl) / se
  p_val  <- 2 * pnorm(-abs(z))        # two-tailed

  lift   <- (p_trt - p_ctrl) / p_ctrl * 100

  list(z = z, p_value = p_val,
       significant = p_val < alpha,
       lift_pct = round(lift, 2))
}'
                )
            ),

            box(title = "📐 Sample Size Calculator", status = "success",
                solidHeader = TRUE, width = 5,
                div(class = "section-heading-dark",
                    "How long must I run the test?"),
                div(class = "control-panel",
                    numericInput(ns("baseline_ctr"),    "Baseline CTR (%)",     value = 2.3,  step = 0.1),
                    numericInput(ns("min_detectable"),  "Min. Detectable Effect (%)", value = 10, step = 1),
                    sliderInput(ns("power"),            "Statistical Power (1-β)",
                                min = 0.70, max = 0.95, value = 0.80, step = 0.05),
                    sliderInput(ns("alpha_ss"),         "Significance level (α)",
                                min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                    run_button(ns("run_samplesize"), "▶  Calculate Sample Size")
                ),
                uiOutput(ns("sample_size_result")),
                br(),
                r_code_block(
'# Sample size formula for two-proportion test
sample_size_ab <- function(p1, mde, power = 0.80, alpha = 0.05) {
  p2   <- p1 * (1 + mde / 100)  # treatment CTR
  z_a  <- qnorm(1 - alpha / 2)  # z for significance
  z_b  <- qnorm(power)          # z for power

  n <- (z_a * sqrt(2 * p1 * (1-p1)) +
        z_b * sqrt(p1*(1-p1) + p2*(1-p2)))^2 /
       (p1 - p2)^2
  ceiling(n)  # per group
}'
                )
            )
          ),

          # ── Section 2: CTR Monitoring Dashboard ───────────
          fluidRow(
            box(title = "📈 CTR Monitoring Dashboard", status = "warning",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark",
                    "Simulated live CTR tracking — as you'd see in a production RecSys dashboard"),
                div(class = "control-panel",
                    fluidRow(
                      column(4, numericInput(ns("n_days"),     "Days to Simulate",   value = 30, min = 7, max = 90)),
                      column(4, numericInput(ns("base_ctr_d"), "Baseline CTR (%)",   value = 2.5, step = 0.1)),
                      column(4, numericInput(ns("deploy_day"), "New Algo Deploy Day", value = 15, min = 2, max = 29))
                    ),
                    run_button(ns("run_ctr_sim"), "▶  Simulate CTR History")
                ),
                plotlyOutput(ns("ctr_monitor_plot")),
                br(),
                r_code_block(
'# Simulate CTR monitoring over time
# Before deploy day: Control algorithm
# After deploy day:  New algorithm (different CTR + noise)

simulate_ctr <- function(n_days, base_ctr, deploy_day, lift = 0.12) {
  days <- 1:n_days
  noise_ctrl <- rnorm(n_days, 0, base_ctr * 0.08)
  noise_trt  <- rnorm(n_days, 0, base_ctr * 0.08)

  ctr_ctrl   <- base_ctr + noise_ctrl

  # Treatment: higher CTR after deployment
  new_ctr    <- base_ctr * (1 + lift)
  ctr_both   <- ifelse(days < deploy_day,
                       ctr_ctrl,
                       new_ctr + noise_trt)
  data.frame(day = days, ctr = round(ctr_both, 3))
}'
                )
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter3_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── A/B Test calculator ──────────────────────────────────
    ab_result <- eventReactive(input$run_abtest, {
      n1 <- input$ctrl_impressions;  x1 <- input$ctrl_clicks
      n2 <- input$trt_impressions;   x2 <- input$trt_clicks
      al <- input$alpha_level

      p1     <- x1 / n1;  p2 <- x2 / n2
      p_pool <- (x1 + x2) / (n1 + n2)
      se     <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
      z_stat <- (p2 - p1) / se
      p_val  <- 2 * pnorm(-abs(z_stat))
      lift   <- (p2 - p1) / p1 * 100
      ci_lo  <- (p2 - p1) - qnorm(1 - al/2) * se
      ci_hi  <- (p2 - p1) + qnorm(1 - al/2) * se

      list(
        p1 = p1, p2 = p2, z = z_stat, p_val = p_val,
        significant = p_val < al,
        lift = lift, ci_lo = ci_lo, ci_hi = ci_hi, alpha = al
      )
    }, ignoreNULL = FALSE)

    output$abtest_result <- renderUI({
      r      <- ab_result()
      sig    <- r$significant
      colour <- if (sig) "#008A82" else "#e67e22"
      icon_s <- if (sig) "✅" else "⚠️"
      verdict <- if (sig)
        paste0("Significant! Reject H₀ (p = ", round(r$p_val, 4), " < α = ", r$alpha, ")")
      else
        paste0("Not Significant (p = ", round(r$p_val, 4), " ≥ α = ", r$alpha, ")")

      div(class = "result-card",
          tags$h5(paste(icon_s, "A/B Test Result")),
          fluidRow(
            column(3, div(class = "metric-card", style = paste0("background:", colour),
                          span(class = "metric-value", paste0(round(r$lift, 1), "%")),
                          span(class = "metric-label", "CTR Lift"))),
            column(3, div(class = "metric-card",
                          span(class = "metric-value", paste0(round(r$p1*100, 2), "%")),
                          span(class = "metric-label", "CTR Control"))),
            column(3, div(class = "metric-card",
                          span(class = "metric-value", paste0(round(r$p2*100, 2), "%")),
                          span(class = "metric-label", "CTR Treatment"))),
            column(3, div(class = "metric-card",
                          span(class = "metric-value", round(r$z, 3)),
                          span(class = "metric-label", "Z-Statistic")))
          ),
          br(),
          div(class = if (sig) "success-box" else "warn-box",
              HTML(paste0("<strong>", verdict, "</strong>"))),
          tags$p(style = "font-size:11.5px; color:#546e7a; margin-top:8px;",
                 paste0("95% CI for difference: [",
                        round(r$ci_lo*100,3), "%, ", round(r$ci_hi*100,3), "%]"))
      )
    })

    # ── Sample size calculator ───────────────────────────────
    ss_result <- eventReactive(input$run_samplesize, {
      p1    <- input$baseline_ctr / 100
      mde   <- input$min_detectable
      pw    <- input$power
      al    <- input$alpha_ss
      p2    <- p1 * (1 + mde / 100)
      z_a   <- qnorm(1 - al / 2)
      z_b   <- qnorm(pw)

      n <- (z_a * sqrt(2 * p1 * (1-p1)) +
              z_b * sqrt(p1*(1-p1) + p2*(1-p2)))^2 / (p1 - p2)^2
      n_per_group <- ceiling(n)
      list(n = n_per_group, p1 = p1, p2 = p2, pw = pw, al = al)
    }, ignoreNULL = FALSE)

    output$sample_size_result <- renderUI({
      r <- ss_result()
      div(class = "result-card",
          tags$h5("Sample Size Requirement"),
          fluidRow(
            column(6, div(class = "metric-card",
                          span(class = "metric-value",
                               format(r$n, big.mark = ",")),
                          span(class = "metric-label", "Per Group"))),
            column(6, div(class = "metric-card",
                          span(class = "metric-value",
                               format(r$n * 2, big.mark = ",")),
                          span(class = "metric-label", "Total Users")))
          ),
          br(),
          div(class = "info-box-plain",
              HTML(paste0(
                "<strong>Setup:</strong> Baseline CTR = ", round(r$p1*100,2), "% → ",
                "Target CTR = ", round(r$p2*100,2), "%<br>",
                "Power = ", r$pw*100, "%, α = ", r$al
              )))
      )
    })

    # ── CTR Monitoring simulation ────────────────────────────
    ctr_data <- eventReactive(input$run_ctr_sim, {
      set.seed(42)
      n    <- input$n_days
      base <- input$base_ctr_d / 100
      dep  <- input$deploy_day
      lift <- 0.12

      days     <- 1:n
      new_ctr  <- base * (1 + lift)
      ctrl_ctr <- base    + rnorm(n, 0, base * 0.08)
      trt_ctr  <- new_ctr + rnorm(n, 0, base * 0.08)

      data.frame(
        day        = days,
        ctr        = ifelse(days < dep, ctrl_ctr * 100, trt_ctr * 100),
        algo       = ifelse(days < dep, "Control", "New Algorithm"),
        deploy_day = dep
      )
    }, ignoreNULL = FALSE)

    output$ctr_monitor_plot <- renderPlotly({
      df  <- ctr_data()
      dep <- unique(df$deploy_day)

      ctrl_df <- df[df$algo == "Control", ]
      trt_df  <- df[df$algo == "New Algorithm", ]

      plot_ly() %>%
        add_trace(data = ctrl_df, x = ~day, y = ~ctr, type = "scatter", mode = "lines+markers",
                  name = "Control Algorithm",
                  line   = list(color = "#8a9bb0", width = 2),
                  marker = list(size = 5, color = "#8a9bb0"),
                  hovertemplate = "Day %{x}: %{y:.2f}%<extra>Control</extra>") %>%
        add_trace(data = trt_df, x = ~day, y = ~ctr, type = "scatter", mode = "lines+markers",
                  name = "New Algorithm",
                  line   = list(color = "#00A39A", width = 2.5),
                  marker = list(size = 6, color = "#00A39A"),
                  hovertemplate = "Day %{x}: %{y:.2f}%<extra>New Algo</extra>") %>%
        layout(
          title = list(text = "CTR Over Time — Deployment Impact",
                       font = list(color = "#d0f0ed", size = 13)),
          xaxis = list(title = "Day", color = "#8a9bb0",
                       gridcolor = "rgba(255,255,255,0.08)"),
          yaxis = list(title = "CTR (%)", color = "#8a9bb0",
                       gridcolor = "rgba(255,255,255,0.08)"),
          shapes = list(list(
            type = "line", x0 = dep, x1 = dep, y0 = 0, y1 = 1,
            yref = "paper",
            line = list(color = "#fbbf24", width = 2, dash = "dash")
          )),
          annotations = list(list(
            x = dep + 0.3, y = max(df$ctr) * 0.95, yref = "y",
            text = "🚀 Deploy", showarrow = FALSE,
            font = list(color = "#fbbf24", size = 11)
          )),
          legend = list(font = list(color = "#8a9bb0"))
        ) %>%
        plotly_dark_theme()
    })

  })
}
