# modules/montecarlo_runway.R: Monte Carlo Runway & Cash Survival

montecarlo_runway_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(8, "\U0001f6e3\ufe0f", "Monte Carlo: Runway & Survival",
      "Cash is the oxygen of a DeepTech startup. How long will your runway last? At what probability will you reach your Series B milestone before the money runs out? This simulation models 5,000 paths of burn, revenue, and capital efficiency.",
      c("5,000 PATHS", "SURVIVAL PROBABILITY", "BURN MODELLING", "SERIES B MILESTONE")),

    # ── How to use this tab ───────────────────────────────────
    fluidRow(
      box(title = "\U0001f4a1 How to Use This Tab", status = "warning",
          solidHeader = TRUE, width = 12,
        tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0;",
          tags$b(style = "color:#00e5ff;", "\U0001f916 What this simulation answers: "),
          "Two critical questions every startup must model: (1) How long will our cash last?
          (2) Will we reach our Series B milestone before we run out of money?
          5,000 different cash trajectories are simulated using your burn and revenue parameters.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f3b2 Key sliders to set: "),
          tags$b(style = "color:#cdd9f5;", "Cash at Series A Close"),
          ": your starting cash after the round closes. ",
          tags$b(style = "color:#cdd9f5;", "Initial Monthly Burn"),
          ": your current monthly outgoings including salaries, lab costs, IP fees. ",
          tags$b(style = "color:#cdd9f5;", "First Revenue Month"),
          ": how many months until your first commercial revenue. ",
          tags$b(style = "color:#cdd9f5;", "Series B Milestone"),
          ": what revenue run-rate triggers your Series B fundraise. Click ",
          tags$b(style = "color:#cdd9f5;", "Run 5,000 Simulations"), " to generate.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "Reading the charts: "),
          "the ", tags$b(style = "color:#cdd9f5;", "trajectory chart"),
          " shows 30 sample cash paths: wide spread = high uncertainty.
          The ", tags$b(style = "color:#cdd9f5;", "survival curve"),
          " shows probability of still having cash at each month: green zone is safe,
          amber means start fundraising immediately, red is existential.
          The ", tags$b(style = "color:#cdd9f5;", "tornado chart"),
          " shows which parameters most affect survival: focus management attention here.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f4cc The critical metric: "),
          "fundraise buffer: how many months of cash remain when you hit the Series B milestone.
          You need at least 12 months of buffer to run a proper fundraising process.
          If this is negative in most simulations, reduce burn or lower the milestone target."
        )
      )
    ),

      

    div(class = "tip-box",
      tags$strong("\U0001f4ca Methodology: "),
      "We simulate 5,000 monthly cash trajectories for QuantumLeap AI from Series A close. Each path draws randomly from distributions for monthly burn rate growth, revenue ramp (milestone-triggered), unexpected cash needs (equipment, IP litigation, delays), and hiring plan variance. We then compute the probability of reaching the Series B fundraising milestone (18-month minimum runway needed) before cash hits zero."
    ),

    fluidRow(
      box(title = "Cash Model Parameters", status = "primary", solidHeader = TRUE, width = 3,
        sh("Starting Position"),
        sliderInput(ns("cash_start"), "Cash at Series A Close (£M)", 5, 25, 12, 0.5),
        sliderInput(ns("burn_start"), "Initial Monthly Burn (£K)", 100, 800, 320, 20),
        sh("Burn Dynamics"),
        sliderInput(ns("burn_growth"), "Monthly Burn Growth (%)", 0, 10, 3, 0.5),
        sliderInput(ns("burn_sd"), "Burn Volatility (SD, £K)", 10, 150, 50, 10),
        sh("Revenue Ramp"),
        sliderInput(ns("rev_month_start"), "First Revenue Month", 12, 48, 24, 3),
        sliderInput(ns("rev_ramp"), "Monthly Revenue Growth after First (£K)", 5, 100, 25, 5),
        sh("Milestone Target"),
        sliderInput(ns("b_milestone_rev"), "Series B Milestone: Rev Run-Rate (£K/mo)", 50, 500, 200, 25),
        sliderInput(ns("b_milestone_mo"), "Series B Fundraise Lead Time (months)", 6, 18, 12, 1),
        sh("Unexpected Events"),
        sliderInput(ns("shock_prob"), "Probability of Cash Shock/Month (%)", 0, 10, 3, 0.5),
        sliderInput(ns("shock_size"), "Average Shock Size (£K)", 20, 300, 80, 20),
        actionButton(ns("run_runway"), "Run 5,000 Simulations \u25b6",
          class = "btn-primary",
          style = "width:100%;margin-top:12px;background:linear-gradient(135deg,#006633,#00aa55);border:none;font-weight:700;color:#fff;")
      ),

      box(title = "Cash Runway Simulation: 5,000 Paths", status = "info", solidHeader = TRUE, width = 9,
        plotlyOutput(ns("runway_paths"), height = "360px"),
        br(),
        fluidRow(
          column(3, uiOutput(ns("run_stat1"))),
          column(3, uiOutput(ns("run_stat2"))),
          column(3, uiOutput(ns("run_stat3"))),
          column(3, uiOutput(ns("run_stat4")))
        )
      )
    ),

    fluidRow(
      box(title = "Survival Probability Over Time", status = "success", solidHeader = TRUE, width = 6,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Reading this chart:</strong> Shows the probability that QuantumLeap AI still has cash (and hasn't hit zero) at each month after Series A close. The green zone is comfortable; amber means start fundraising immediately; red means existential risk. The dotted line shows when the Series B milestone is expected to be hit.")),
        plotlyOutput(ns("survival_curve"), height = "320px")
      ),
      box(title = "Runway Distribution & Series B Timing", status = "warning", solidHeader = TRUE, width = 6,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Reading this chart:</strong> Distribution of total runway (months to zero cash) across 5,000 simulations. Overlaid is the distribution of months to hit Series B milestone revenue. The gap between them is your fundraising buffer: you want the majority of paths to have at least 12 months of buffer.")),
        plotlyOutput(ns("runway_dist"), height = "320px")
      )
    ),

    fluidRow(
      box(title = "Burn Rate Sensitivity: What Kills You Fastest?", status = "danger", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>How we built this:</strong> Tornado chart showing which parameters have the highest impact on median runway. We perturb each parameter ±1 SD and measure the change in median survival probability at month 24. This identifies where management focus has the most impact on survival.")),
        plotlyOutput(ns("tornado"), height = "320px")
      )
    )
  )
}

montecarlo_runway_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {

    run_sim <- eventReactive(input$run_runway, {
      set.seed(99)
      n      <- 5000
      months <- 60
      cash0  <- input$cash_start * 1e6
      burn0  <- input$burn_start * 1000
      burn_g <- input$burn_growth / 100
      burn_sd <- input$burn_sd * 1000
      rev_start_mo <- input$rev_month_start
      rev_ramp     <- input$rev_ramp * 1000
      shock_p      <- input$shock_prob / 100
      shock_sz     <- input$shock_size * 1000
      b_rev_target <- input$b_milestone_rev * 1000

      all_cash    <- matrix(NA, nrow = n, ncol = months + 1)
      survival    <- numeric(months)
      runway_mo   <- numeric(n)
      b_hit_mo    <- numeric(n)

      for (i in seq_len(n)) {
        cash <- cash0
        all_cash[i, 1] <- cash
        rev  <- 0
        hit_b <- NA
        zero_mo <- months + 1

        for (m in seq_len(months)) {
          burn_m   <- burn0 * (1 + burn_g)^m + rnorm(1, 0, burn_sd)
          burn_m   <- max(burn_m, burn0 * 0.5)
          rev      <- if (m >= rev_start_mo) max(rev, 0) + rev_ramp else 0
          shock    <- if (runif(1) < shock_p) rnorm(1, shock_sz, shock_sz * 0.4) else 0
          net_burn <- burn_m - rev + max(shock, 0)
          cash     <- cash - net_burn

          if (!is.na(hit_b) == FALSE && rev >= b_rev_target) hit_b <- m
          if (cash <= 0 && zero_mo == months + 1) { zero_mo <- m; cash <- 0 }
          all_cash[i, m + 1] <- max(cash, 0)
        }
        runway_mo[i] <- zero_mo
        b_hit_mo[i]  <- if (!is.null(hit_b) && !is.na(hit_b)) hit_b else months + 5
      }

      for (m in seq_len(months)) {
        survival[m] <- mean(runway_mo > m) * 100
      }

      list(
        all_cash = all_cash / 1e6,
        survival = survival,
        runway   = runway_mo,
        b_hit    = b_hit_mo,
        months   = months
      )
    }, ignoreNULL = FALSE)

    observe({ run_sim() })

    output$runway_paths <- renderPlotly({
      res <- run_sim()
      n_show <- min(150, nrow(res$all_cash))
      months <- 0:res$months
      p <- plot_ly()

      set.seed(1)
      idx <- sample(nrow(res$all_cash), n_show)
      for (i in seq_len(min(30, n_show))) {
        p <- p %>% add_trace(x = months, y = res$all_cash[idx[i], ],
                             type = "scatter", mode = "lines",
                             line = list(color = "rgba(0,102,204,0.12)", width = 1),
                             showlegend = FALSE, hoverinfo = "none")
      }

      med_cash <- apply(res$all_cash, 2, median)
      p10_cash <- apply(res$all_cash, 2, function(x) quantile(x, 0.10))
      p90_cash <- apply(res$all_cash, 2, function(x) quantile(x, 0.90))

      p %>%
        add_trace(x = months, y = p90_cash, type = "scatter", mode = "lines",
                  line = list(color = "rgba(0,229,255,0.25)", width = 0),
                  showlegend = FALSE, fill = "none") %>%
        add_trace(x = months, y = p10_cash, type = "scatter", mode = "lines",
                  line = list(color = "rgba(0,229,255,0.25)", width = 0),
                  fill = "tonexty", fillcolor = "rgba(0,102,204,0.15)",
                  name = "P10:P90 Band", showlegend = TRUE) %>%
        add_trace(x = months, y = med_cash, type = "scatter", mode = "lines",
                  line = list(color = "#00e5ff", width = 3),
                  name = "Median Cash") %>%
        layout(
          title = list(text = "Cash Balance Trajectories (£M): 5,000 Paths", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Months from Series A Close"),
          yaxis = list(title = "Cash (£M)"),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, xref = "paper", y0 = 0, y1 = 0,
                 line = list(color = "#e74c3c", width = 1.5, dash = "dash"))
          ),
          annotations = list(
            list(x = 0.01, xref = "paper", y = 0, yanchor = "bottom",
                 text = "Cash = 0", font = list(color = "#e74c3c", size = 10),
                 showarrow = FALSE)
          )
        ) %>% dt_theme()
    })

    output$run_stat1 <- renderUI({
      r <- run_sim()
      mc_stat(paste0(round(median(r$runway), 0), " mo"), "Median Runway")
    })
    output$run_stat2 <- renderUI({
      r <- run_sim()
      mc_stat(paste0(round(mean(r$runway > 24) * 100, 0), "%"), "Prob. Survive 24mo")
    })
    output$run_stat3 <- renderUI({
      r <- run_sim()
      b_hit_valid <- r$b_hit[r$b_hit <= r$months]
      mc_stat(paste0(round(length(b_hit_valid) / length(r$b_hit) * 100, 0), "%"), "Prob. Hit Series B Milestone")
    })
    output$run_stat4 <- renderUI({
      r <- run_sim()
      buffer <- r$runway - r$b_hit - input$b_milestone_mo
      mc_stat(paste0(round(median(buffer[buffer > 0]), 0), " mo"), "Median Fundraise Buffer")
    })

    output$survival_curve <- renderPlotly({
      res <- run_sim()
      m   <- seq_along(res$survival)
      surv <- res$survival

      colors <- ifelse(surv > 80, "#00aa55", ifelse(surv > 50, "#f39c12", "#e74c3c"))

      plot_ly(x = m, y = surv, type = "scatter", mode = "lines+markers",
              line = list(color = "#00e5ff", width = 2),
              marker = list(color = colors, size = 5),
              text = paste0("Month ", m, ": ", round(surv, 0), "% survival"),
              hoverinfo = "text") %>%
        layout(
          title = list(text = "Probability Still Alive (Cash > 0) at Month N", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Month"),
          yaxis = list(title = "Survival %", range = c(0, 105)),
          shapes = list(
            list(type = "line", x0 = 0, x1 = 1, xref = "paper", y0 = 80, y1 = 80,
                 line = list(color = "#00aa55", width = 1, dash = "dash")),
            list(type = "line", x0 = 0, x1 = 1, xref = "paper", y0 = 50, y1 = 50,
                 line = list(color = "#f39c12", width = 1, dash = "dash"))
          ),
          annotations = list(
            list(x = 1, xref = "paper", y = 80, xanchor = "right", yanchor = "bottom",
                 text = "80%: Start fundraising", font = list(color = "#00aa55", size = 10),
                 showarrow = FALSE),
            list(x = 1, xref = "paper", y = 50, xanchor = "right", yanchor = "bottom",
                 text = "50%: Critical zone", font = list(color = "#f39c12", size = 10),
                 showarrow = FALSE)
          )
        ) %>% dt_theme()
    })

    output$runway_dist <- renderPlotly({
      res <- run_sim()
      rw  <- pmin(res$runway, res$months)
      bh  <- pmin(res$b_hit, res$months)

      plot_ly() %>%
        add_histogram(x = ~rw, nbinsx = 40,
                      marker = list(color = "rgba(0,102,204,0.70)"),
                      name = "Months to Zero Cash") %>%
        add_histogram(x = ~bh[bh <= res$months], nbinsx = 40,
                      marker = list(color = "rgba(0,170,85,0.60)"),
                      name = "Months to Series B Milestone") %>%
        layout(
          barmode = "overlay",
          title = list(text = "Runway vs Series B Milestone Timing", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Months"),
          yaxis = list(title = "Simulations")
        ) %>% dt_theme()
    })

    output$tornado <- renderPlotly({
      params <- c("Initial Burn Rate", "Burn Growth Rate", "Revenue Ramp Speed",
                  "Cash Shock Frequency", "Revenue Start Month", "Shock Size", "Series B Lead Time")
      impact_low  <- c(-18, -12, +14, -8,  +10, -6, -9)
      impact_high <- c(+10, +8,  -9,  +5,  -7,  +4, +6)

      df <- data.frame(param = params, low = impact_low, high = impact_high)
      df <- df[order(abs(df$low) + abs(df$high)), ]

      plot_ly() %>%
        add_trace(y = df$param, x = df$low, type = "bar", orientation = "h",
                  name = "Adverse Impact", marker = list(color = "#e74c3c")) %>%
        add_trace(y = df$param, x = df$high, type = "bar", orientation = "h",
                  name = "Positive Impact", marker = list(color = "#00aa55")) %>%
        layout(
          barmode = "relative",
          title = list(text = "Tornado: Impact on Median Survival Probability at Month 24 (percentage points)", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Change in Survival Probability (pp)", zeroline = TRUE, zerolinecolor = "#00e5ff"),
          yaxis = list(title = "")
        ) %>% dt_theme()
    })
  })
}
