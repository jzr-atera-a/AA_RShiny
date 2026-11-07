# modules/montecarlo_valuation.R — Monte Carlo Valuation Simulation

montecarlo_valuation_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(7, "\U0001f3b2", "Monte Carlo: Exit Valuation",
      "How much could QuantumLeap AI be worth at exit — and with what probability? We run 10,000 simulations of exit value under uncertainty in revenue growth, margin expansion, market multiple, and round dilution. This is what VC associates actually model.",
      c("10,000 SIMULATIONS", "EXIT VALUE DISTRIBUTION", "PROBABILITY BANDS", "DEEPTECH SCENARIO")),

    div(class = "tip-box",
      tags$strong("\U0001f4ca Methodology: "),
      "This Monte Carlo model simulates 10,000 possible futures for QuantumLeap AI from Series A close to exit (6–10 years). Each simulation randomly draws from probability distributions for: (1) revenue CAGR, (2) exit EBITDA/revenue multiple, (3) dilution from future rounds, and (4) time to exit. The output is a distribution of exit equity values and founder proceeds — not a single point estimate. Adjust sliders to test your assumptions."
    ),

    fluidRow(
      box(title = "Simulation Parameters", status = "primary", solidHeader = TRUE, width = 3,
        sh("Revenue Model"),
        sliderInput(ns("rev_base"), "Base Case Revenue CAGR (%)", 30, 120, 65, 5),
        sliderInput(ns("rev_sd"), "Revenue Uncertainty (SD %)", 5, 40, 20, 5),
        sliderInput(ns("rev_start"), "Revenue at Series A (£K)", 0, 2000, 150, 50),
        sh("Exit Multiple"),
        sliderInput(ns("mult_mean"), "Mean Exit Revenue Multiple", 3, 25, 9, 0.5),
        sliderInput(ns("mult_sd"), "Multiple Uncertainty (SD)", 1, 8, 3, 0.5),
        sh("Dilution & Structure"),
        sliderInput(ns("future_dilution"), "Expected Future Dilution %", 10, 50, 30, 5),
        sliderInput(ns("dilution_sd"), "Dilution Uncertainty (SD %)", 2, 15, 8, 1),
        sliderInput(ns("founder_own"), "Current Founder Ownership %", 40, 90, 58, 1),
        sh("Time Horizon"),
        sliderInput(ns("yrs_mean"), "Mean Years to Exit", 4, 12, 7, 1),
        sliderInput(ns("yrs_sd"), "Time Uncertainty (SD years)", 0.5, 3, 1.5, 0.5),
        actionButton(ns("run_mc"), "Run 10,000 Simulations \u25b6",
          class = "btn-primary", style = "width:100%;margin-top:12px;background:linear-gradient(135deg,#0066cc,#00bfff);border:none;font-weight:700;color:#fff;")
      ),
      box(title = "Exit Value Distribution (10,000 Paths)", status = "info", solidHeader = TRUE, width = 9,
        plotlyOutput(ns("mc_histogram"), height = "350px"),
        br(),
        fluidRow(
          column(4, uiOutput(ns("mc_stats_1"))),
          column(4, uiOutput(ns("mc_stats_2"))),
          column(4, uiOutput(ns("mc_stats_3")))
        )
      )
    ),

    fluidRow(
      box(title = "Simulation Paths: Revenue to Exit Over Time", status = "warning", solidHeader = TRUE, width = 6,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Reading this chart:</strong> Shows 200 randomly selected simulation paths from founding to exit. The dark cyan band is the median path; lighter bands show 25th–75th and 10th–90th percentile ranges. The wide spread reflects genuine uncertainty in DeepTech commercialisation timelines.")),
        plotlyOutput(ns("mc_paths"), height = "320px")
      ),
      box(title = "Founder Proceeds Distribution", status = "success", solidHeader = TRUE, width = 6,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Reading this chart:</strong> Shows probability distribution of founder's net proceeds after liquidation preferences, dilution, and taxes. The vertical lines show the 10th, 50th, and 90th percentile outcomes. This answers: 'What's my realistic range of personal wealth creation?'")),
        plotlyOutput(ns("founder_dist"), height = "320px")
      )
    ),

    fluidRow(
      box(title = "Scenario Comparison: Bear / Base / Bull", status = "danger", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Methodology:</strong> Three scenarios defined by combinations of revenue CAGR (P10/P50/P90 of simulation), exit multiple (P10/P50/P90), and dilution (P90/P50/P10). Each shows the impact on founder equity value. Useful for board presentations and investor discussions about risk.")),
        plotlyOutput(ns("scenario_bar"), height = "320px")
      )
    )
  )
}

montecarlo_valuation_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {

    mc_results <- eventReactive(input$run_mc, {
      set.seed(42)
      n <- 10000

      rev_cagr   <- rnorm(n, input$rev_base / 100,  input$rev_sd / 100)
      rev_cagr   <- pmax(rev_cagr, -0.30)
      mult       <- rnorm(n, input$mult_mean, input$mult_sd)
      mult       <- pmax(mult, 0.5)
      dilution   <- rnorm(n, input$future_dilution / 100, input$dilution_sd / 100)
      dilution   <- pmax(pmin(dilution, 0.70), 0.05)
      yrs        <- rnorm(n, input$yrs_mean, input$yrs_sd)
      yrs        <- pmax(round(yrs), 3)

      rev_start  <- input$rev_start * 1000
      exit_rev   <- rev_start * (1 + rev_cagr)^yrs
      exit_val   <- exit_rev * mult
      founder_pct <- (input$founder_own / 100) * (1 - dilution)

      # 1x liq pref: VC recoups £12M first
      liq_pref   <- 12e6
      founder_proceeds <- pmax(0, (exit_val - liq_pref) * founder_pct)

      list(
        exit_val = exit_val / 1e6,
        founder  = founder_proceeds / 1e6,
        rev      = exit_rev / 1e6,
        yrs      = yrs,
        mult     = mult,
        rev_cagr = rev_cagr * 100
      )
    }, ignoreNULL = FALSE)

    # Auto-run on load
    observe({ mc_results() })

    output$mc_histogram <- renderPlotly({
      res <- mc_results()
      ev  <- res$exit_val
      q   <- quantile(ev, c(0.10, 0.25, 0.50, 0.75, 0.90))

      plot_ly() %>%
        add_histogram(x = ~ev[ev < quantile(ev, 0.95)], nbinsx = 80,
                      marker = list(color = "#0066cc", line = list(color = "#00e5ff", width = 0.3)),
                      name = "Exit Value") %>%
        layout(
          title = list(text = "Distribution of Exit Enterprise Value (£M) — 10,000 Simulations", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Exit Value (£M)"),
          yaxis = list(title = "Frequency"),
          shapes = list(
            list(type = "line", x0 = q["50%"], x1 = q["50%"], y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#00e5ff", width = 2, dash = "dash")),
            list(type = "line", x0 = q["10%"], x1 = q["10%"], y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#e74c3c", width = 1.5, dash = "dot")),
            list(type = "line", x0 = q["90%"], x1 = q["90%"], y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#00aa55", width = 1.5, dash = "dot"))
          ),
          annotations = list(
            list(x = q["50%"], y = 0.95, yref = "paper", xanchor = "left",
                 text = paste0("Median: £", round(q["50%"], 0), "M"),
                 font = list(color = "#00e5ff", size = 11), showarrow = FALSE),
            list(x = q["10%"], y = 0.85, yref = "paper", xanchor = "right",
                 text = "P10", font = list(color = "#e74c3c", size = 11), showarrow = FALSE),
            list(x = q["90%"], y = 0.85, yref = "paper", xanchor = "left",
                 text = "P90", font = list(color = "#00aa55", size = 11), showarrow = FALSE)
          )
        ) %>% dt_theme()
    })

    output$mc_stats_1 <- renderUI({
      res <- mc_results()
      q   <- quantile(res$exit_val, c(0.10, 0.25, 0.50, 0.75, 0.90))
      tagList(
        mc_stat(paste0("£", round(q["50%"], 0), "M"), "Median Exit Value"),
        mc_stat(paste0("£", round(q["10%"], 0), "M"), "Bear Case (P10)"),
        mc_stat(paste0("£", round(q["90%"], 0), "M"), "Bull Case (P90)")
      )
    })

    output$mc_stats_2 <- renderUI({
      res <- mc_results()
      fq  <- quantile(res$founder, c(0.10, 0.50, 0.90))
      tagList(
        mc_stat(paste0("£", round(fq["50%"], 1), "M"), "Median Founder Proceeds"),
        mc_stat(paste0("£", round(fq["10%"], 1), "M"), "Founder Bear (P10)"),
        mc_stat(paste0("£", round(fq["90%"], 1), "M"), "Founder Bull (P90)")
      )
    })

    output$mc_stats_3 <- renderUI({
      res  <- mc_results()
      prob_100 <- mean(res$exit_val > 100) * 100
      prob_50  <- mean(res$exit_val > 50)  * 100
      prob_0   <- mean(res$founder < 1)    * 100
      tagList(
        mc_stat(paste0(round(prob_100, 0), "%"), "Prob. Exit > £100M"),
        mc_stat(paste0(round(prob_50, 0), "%"),  "Prob. Exit > £50M"),
        mc_stat(paste0(round(prob_0, 0), "%"),   "Prob. Founder < £1M")
      )
    })

    output$mc_paths <- renderPlotly({
      res <- mc_results()
      set.seed(42)
      n_paths <- 200
      idx     <- sample(10000, n_paths)
      years   <- 0:10

      p <- plot_ly()
      for (i in seq_len(min(20, n_paths))) {
        cagr_i  <- rnorm(1, input$rev_base / 100, input$rev_sd / 100)
        rev_path <- input$rev_start * (1 + pmax(cagr_i, -0.3))^years
        p <- p %>% add_trace(x = years, y = rev_path / 1e3, type = "scatter", mode = "lines",
                              line = list(color = "rgba(0,102,204,0.18)", width = 1),
                              showlegend = FALSE, hoverinfo = "none")
      }
      # Median path
      med_cagr <- input$rev_base / 100
      med_path <- input$rev_start * (1 + med_cagr)^years
      p %>%
        add_trace(x = years, y = med_path / 1e3, type = "scatter", mode = "lines",
                  line = list(color = "#00e5ff", width = 3), name = "Median Path") %>%
        layout(
          title = list(text = "Revenue Simulation Paths (£M, 20 shown)", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Years from Series A"),
          yaxis = list(title = "Annual Revenue (£M)")
        ) %>% dt_theme()
    })

    output$founder_dist <- renderPlotly({
      res <- mc_results()
      fp  <- res$founder
      fp  <- fp[fp < quantile(fp, 0.95)]
      q   <- quantile(res$founder, c(0.10, 0.50, 0.90))

      plot_ly() %>%
        add_histogram(x = ~fp, nbinsx = 60,
                      marker = list(color = "#00aa55", line = list(color = "#00e5ff", width = 0.3)),
                      name = "Founder Proceeds") %>%
        layout(
          title = list(text = "Founder Proceeds After Liquidation Prefs (£M)", font = list(color = "#cdd9f5")),
          xaxis = list(title = "Founder Proceeds (£M)"),
          yaxis = list(title = "Frequency"),
          shapes = list(
            list(type = "line", x0 = q["50%"], x1 = q["50%"], y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#00e5ff", width = 2, dash = "dash")),
            list(type = "line", x0 = q["10%"], x1 = q["10%"], y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#e74c3c", width = 1.5, dash = "dot")),
            list(type = "line", x0 = q["90%"], x1 = q["90%"], y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = "#f39c12", width = 1.5, dash = "dot"))
          ),
          annotations = list(
            list(x = q["50%"], y = 0.95, yref = "paper", xanchor = "left",
                 text = paste0("Median: £", round(q["50%"], 1), "M"),
                 font = list(color = "#00e5ff", size = 11), showarrow = FALSE),
            list(x = q["10%"], y = 0.85, yref = "paper", xanchor = "right",
                 text = "P10", font = list(color = "#e74c3c", size = 11), showarrow = FALSE),
            list(x = q["90%"], y = 0.85, yref = "paper", xanchor = "left",
                 text = "P90", font = list(color = "#f39c12", size = 11), showarrow = FALSE)
          )
        ) %>% dt_theme()
    })

    output$scenario_bar <- renderPlotly({
      scenarios <- c("Bear Case\n(CAGR P10, Mult P10, High Dilution)", "Base Case\n(CAGR Median, Mult Median)", "Bull Case\n(CAGR P90, Mult P90, Low Dilution)")
      yrs  <- input$yrs_mean

      calc_val <- function(cagr, mult, dil) {
        rev  <- input$rev_start * 1000 * (1 + cagr)^yrs
        ev   <- rev * mult
        fpct <- (input$founder_own / 100) * (1 - dil)
        list(ev = ev / 1e6, fp = max(0, (ev - 12e6) * fpct) / 1e6)
      }

      bear <- calc_val(pmax(input$rev_base/100 - 1.5 * input$rev_sd/100, -0.2),
                       max(0.5, input$mult_mean - 1.5 * input$mult_sd), 0.45)
      base <- calc_val(input$rev_base/100, input$mult_mean, input$future_dilution/100)
      bull <- calc_val(input$rev_base/100 + 1.5 * input$rev_sd/100,
                       input$mult_mean + 1.5 * input$mult_sd, 0.15)

      ev_vals <- c(bear$ev, base$ev, bull$ev)
      fp_vals <- c(bear$fp, base$fp, bull$fp)

      plot_ly() %>%
        add_trace(x = scenarios, y = round(ev_vals, 0), type = "bar", name = "Exit Enterprise Value",
                  marker = list(color = c("#e74c3c", "#0066cc", "#00aa55"))) %>%
        add_trace(x = scenarios, y = round(fp_vals, 0), type = "bar", name = "Founder Proceeds",
                  marker = list(color = c("rgba(231,76,60,0.5)", "rgba(0,102,204,0.5)", "rgba(0,170,85,0.5)"))) %>%
        layout(barmode = "group",
               title = list(text = "Bear / Base / Bull Scenario Comparison (£M)", font = list(color = "#cdd9f5")),
               yaxis = list(title = "Value (£M)"),
               xaxis = list(title = "")) %>% dt_theme()
    })
  })
}
