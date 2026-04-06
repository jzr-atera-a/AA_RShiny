# modules/chapter05.R — Portfolio Optimization and Performance Evaluation

chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5, "📊", "Portfolio Optimization",
      "Performance Evaluation - Measuring risk-return trade-offs and optimizing portfolio weights using modern and classical techniques.",
      c("Sharpe Ratio", "Mean-Variance", "Kelly Criterion", "Risk Parity", "pyfolio")),

    stats_row(
      list("1952", "Modern Portfolio Theory"),
      list("4+", "Optimization Methods"), 
      list("Sharpe", "Key Metric"),
      list("pyfolio", "Performance Tool")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "📈 Measuring Portfolio Performance", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Risk-Return Trade-offs",
                  "Performance evaluation condenses complex portfolio behavior into single metrics that capture risk-adjusted returns. Key challenge: balancing higher returns against acceptable volatility and drawdown risk."
                ),
                framework_card("The Sharpe Ratio",
                  tagList(
                    tags$p(tags$strong("Formula:"), " (Portfolio Return - Risk-Free Rate) / Portfolio Volatility"),
                    tags$p("Measures excess return per unit of risk. Higher Sharpe indicates better risk-adjusted performance."),
                    tags$ul(
                      tags$li(tags$strong("< 1:"), " Poor risk-adjusted returns"),
                      tags$li(tags$strong("1-2:"), " Good performance"),
                      tags$li(tags$strong("> 2:"), " Excellent (rare in practice)")
                    )
                  )
                ),
                framework_card("Information Ratio",
                  "IR = (Portfolio Return - Benchmark Return) / Tracking Error. Measures active return per unit of active risk. Critical for evaluating alpha generation."
                )
            ),
            
            box(title = "🎯 Fundamental Law of Active Management", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Grinold's Framework",
                  tagList(
                    tags$p(tags$strong("IR = IC × √BR")),
                    tags$ul(
                      tags$li(tags$strong("IR:"), " Information Ratio (skill)"),
                      tags$li(tags$strong("IC:"), " Information Coefficient (forecast accuracy)"),
                      tags$li(tags$strong("BR:"), " Breadth (number of independent bets)")
                    ),
                    tags$p("Key insight: You can achieve high IR either through:"),
                    tags$ul(
                      tags$li("Very accurate predictions (high IC) with fewer bets"),
                      tags$li("Moderate accuracy with many independent bets")
                    )
                  )
                ),
                plotlyOutput(ns("ir_surface"), height = "280px")
            )
          ),
          
          fluidRow(
            box(title = "⚖️ Portfolio Optimization Methods", status = "success", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Method"), 
                    tags$th("Objective"), 
                    tags$th("Pros"),
                    tags$th("Cons")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Mean-Variance (Markowitz)")),
                      tags$td("Maximize return for given risk"),
                      tags$td("Mathematically optimal, widely understood"),
                      tags$td("Sensitive to input estimates, concentrated portfolios")
                    ),
                    tags$tr(
                      tags$td(tags$strong("1/N Equal Weight")),
                      tags$td("Equal allocation to all assets"),
                      tags$td("Simple, robust, low turnover"),
                      tags$td("Ignores expected returns and correlations")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Minimum Variance")),
                      tags$td("Minimize portfolio volatility"),
                      tags$td("Defensive, less sensitive to return estimates"),
                      tags$td("May underperform in bull markets")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Risk Parity")),
                      tags$td("Equal risk contribution from each asset"),
                      tags$td("Diversifies risk sources"),
                      tags$td("Requires leverage for target returns")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Black-Litterman")),
                      tags$td("Blend market equilibrium with views"),
                      tags$td("Incorporates prior beliefs, stable weights"),
                      tags$td("Complex, requires specifying confidence")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Kelly Criterion")),
                      tags$td("Maximize log wealth growth"),
                      tags$td("Optimal long-term growth"),
                      tags$td("Aggressive, assumes perfect knowledge")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📐 Mean-Variance Optimization", status = "info", solidHeader = TRUE, width = 6,
                framework_card("How It Works",
                  tagList(
                    tags$p("Solves: min (w'Σw) subject to w'μ = target return and Σw = 1"),
                    tags$ul(
                      tags$li(tags$strong("w:"), " Portfolio weights"),
                      tags$li(tags$strong("Σ:"), " Covariance matrix"),
                      tags$li(tags$strong("μ:"), " Expected returns vector")
                    )
                  )
                ),
                framework_card("Challenges",
                  tagList(
                    tags$ul(
                      tags$li("Estimation error in μ and Σ dominates"),
                      tags$li("Small input changes → large weight shifts"),
                      tags$li("Concentrated positions in few assets"),
                      tags$li("High turnover and transaction costs"),
                      tags$li("No constraints on short positions")
                    )
                  )
                ),
                tip_box("Regularization", "Add constraints (max weight, sector limits) or use shrinkage estimators to stabilize solutions.")
            ),
            
            box(title = "📊 Efficient Frontier", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("efficient_frontier"), height = "350px")
            )
          ),
          
          fluidRow(
            box(title = "🎲 Kelly Criterion for Position Sizing", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Single Asset Formula",
                  tagList(
                    tags$p(tags$strong("f* = (p × b - q) / b")),
                    tags$ul(
                      tags$li(tags$strong("f*:"), " Fraction of capital to allocate"),
                      tags$li(tags$strong("p:"), " Probability of winning"),
                      tags$li(tags$strong("q:"), " Probability of losing (1 - p)"),
                      tags$li(tags$strong("b:"), " Odds received (payoff ratio)")
                    ),
                    tags$p(tags$strong("Example:"), " If p=0.6, b=2 (win 2x bet), then f* = (0.6×2 - 0.4)/2 = 0.4 (bet 40% of capital)")
                  )
                ),
                framework_card("Multiple Assets",
                  "Kelly criterion extends to portfolio allocation: f* = Σ⁻¹μ where μ is excess returns and Σ is covariance. Provides maximum geometric growth rate but often too aggressive for practice (use fractional Kelly)."
                )
            ),
            
            box(title = "⚖️ Risk Parity Approach", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Equal Risk Contribution",
                  tagList(
                    tags$p("Instead of equal weights, allocate so each asset contributes equally to portfolio risk:"),
                    tags$p(tags$strong("RC_i = w_i × (Σw)_i")),
                    tags$p("Where RC_i is risk contribution of asset i. Goal: RC_1 = RC_2 = ... = RC_N")
                  )
                ),
                framework_card("Implementation",
                  tagList(
                    tags$ul(
                      tags$li("Typically over-weights bonds/low-vol assets"),
                      tags$li("Under-weights high-vol equities"),
                      tags$li("Often requires leverage to achieve target returns"),
                      tags$li("Popular in All-Weather and similar strategies")
                    )
                  )
                ),
                plotlyOutput(ns("risk_contribution"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "📈 Performance Evaluation with pyfolio", status = "success", solidHeader = TRUE, width = 12,
                framework_card("pyfolio Capabilities",
                  tagList(
                    tags$p("Comprehensive backtest analysis library from Quantopian. Integrates with Zipline and Alphalens."),
                    tags$h5("Key Outputs:"),
                    tags$ul(
                      tags$li(tags$strong("Summary Stats:"), " Sharpe, Sortino, Calmar, max drawdown"),
                      tags$li(tags$strong("Returns Analysis:"), " Daily/monthly/annual returns distribution"),
                      tags$li(tags$strong("Drawdown Periods:"), " Underwater plot, recovery analysis"),
                      tags$li(tags$strong("Risk Exposure:"), " Beta, factor loadings over time"),
                      tags$li(tags$strong("Event Risk:"), " Performance during market stress periods"),
                      tags$li(tags$strong("Rolling Metrics:"), " Time-varying Sharpe, volatility"),
                      tags$li(tags$strong("Turnover:"), " Position changes and implied costs")
                    )
                  )
                )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

chapter5_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$ir_surface <- renderPlotly({
      ic <- seq(0.01, 0.15, length.out = 20)
      br <- seq(10, 1000, length.out = 20)
      ir_matrix <- outer(ic, sqrt(br), "*")
      
      plot_ly(x = ~ic, y = ~br, z = ~ir_matrix, type = "contour",
              colorscale = list(c(0, ml_colors$danger), c(0.5, ml_colors$warning), c(1, ml_colors$success)),
              contours = list(showlabels = TRUE)) %>%
        layout(
          title = list(text = "Information Ratio = IC × √Breadth", font = list(color = "#E6EDF3")),
          xaxis = list(title = "IC (Forecast Accuracy)", color = "#8B949E"),
          yaxis = list(title = "Breadth (Number of Bets)", color = "#8B949E"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$efficient_frontier <- renderPlotly({
      set.seed(42)
      n_portfolios <- 100
      returns <- runif(n_portfolios, 0.03, 0.15)
      volatility <- 0.05 + returns * 0.8 + rnorm(n_portfolios, 0, 0.02)
      sharpe <- (returns - 0.02) / volatility
      
      plot_ly(x = volatility, y = returns, type = "scatter", mode = "markers",
              marker = list(size = 10, color = sharpe, colorscale = "Viridis",
                            colorbar = list(title = "Sharpe", titlefont = list(color = "#E6EDF3"),
                                          tickfont = list(color = "#E6EDF3")),
                            line = list(color = "white", width = 1)),
              text = ~paste("Return:", round(returns*100, 1), "%<br>Vol:", round(volatility*100, 1), "%<br>Sharpe:", round(sharpe, 2)),
              hovertemplate = "%{text}<extra></extra>") %>%
        layout(
          title = list(text = "Efficient Frontier", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Volatility (Risk)", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Expected Return", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$risk_contribution <- renderPlotly({
      assets <- c("Stocks", "Bonds", "Commodities", "REITs")
      equal_weight_rc <- c(65, 20, 10, 5)
      risk_parity_rc <- c(25, 25, 25, 25)
      
      data <- data.frame(
        Asset = rep(assets, 2),
        Approach = rep(c("Equal Weight", "Risk Parity"), each = 4),
        Risk_Contribution = c(equal_weight_rc, risk_parity_rc)
      )
      
      plot_ly(data, x = ~Asset, y = ~Risk_Contribution, color = ~Approach,
              colors = c(ml_colors$accent1, ml_colors$primary),
              type = "bar", text = ~paste0(Risk_Contribution, "%"),
              textposition = "outside") %>%
        layout(
          title = list(text = "Risk Contribution Comparison", font = list(color = "#E6EDF3")),
          xaxis = list(title = "", color = "#8B949E"),
          yaxis = list(title = "Risk Contribution (%)", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          barmode = "group",
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
