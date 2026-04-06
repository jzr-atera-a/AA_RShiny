# modules/chapter05.R — Portfolio Optimization and Performance Evaluation

CH05_FILES <- list(
  list(
    name = "sharpe_ratio.py",
    description = "<strong>sharpe_ratio.py</strong> — Calculate Sharpe ratio to measure risk-adjusted returns.",
    code = '# Sharpe Ratio Calculation\nimport pandas as pd\nimport numpy as np\n\ndef sharpe_ratio(returns, risk_free_rate=0.02, periods_per_year=252):\n    """\n    Calculate annualized Sharpe ratio\n    \n    Args:\n        returns: Series of daily returns\n        risk_free_rate: Annual risk-free rate (default 2%)\n        periods_per_year: Trading days per year (252 for daily)\n    \n    Returns:\n        Annualized Sharpe ratio\n    """\n    excess_returns = returns - (risk_free_rate / periods_per_year)\n    mean_excess = excess_returns.mean()\n    std_excess = excess_returns.std()\n    \n    sharpe = (mean_excess / std_excess) * np.sqrt(periods_per_year)\n    return sharpe\n\n# Example: Compare two strategies\nnp.random.seed(42)\nstrategy_a = pd.Series(np.random.randn(252) * 0.01 + 0.0003)  # Higher return, higher vol\nstrategy_b = pd.Series(np.random.randn(252) * 0.008 + 0.0002) # Lower return, lower vol\n\nsharpe_a = sharpe_ratio(strategy_a)\nsharpe_b = sharpe_ratio(strategy_b)\n\nprint("Sharpe Ratio Comparison:")\nprint("=" * 50)\nprint(f"Strategy A Sharpe: {sharpe_a:.3f}")\nprint(f"Strategy B Sharpe: {sharpe_b:.3f}")\nprint(f"\\nAnnualized Return A: {strategy_a.mean() * 252:.2%}")\nprint(f"Annualized Volatility A: {strategy_a.std() * np.sqrt(252):.2%}")\nprint(f"\\nAnnualized Return B: {strategy_b.mean() * 252:.2%}")\nprint(f"Annualized Volatility B: {strategy_b.std() * np.sqrt(252):.2%}")',
    demo = 'np.random.seed(42)\nstrategy_a = pd.Series(np.random.randn(252) * 0.01 + 0.0003)\nstrategy_b = pd.Series(np.random.randn(252) * 0.008 + 0.0002)\nsharpe_a = sharpe_ratio(strategy_a)\nsharpe_b = sharpe_ratio(strategy_b)\nprint("Sharpe Ratio Comparison:")\nprint("=" * 50)\nprint(f"Strategy A Sharpe: {sharpe_a:.3f}")\nprint(f"Strategy B Sharpe: {sharpe_b:.3f}")\nprint(f"\\nAnnualized Return A: {strategy_a.mean() * 252:.2%}")\nprint(f"Annualized Volatility A: {strategy_a.std() * np.sqrt(252):.2%}")'
  ),
  list(
    name = "mean_variance.py",
    description = "<strong>mean_variance.py</strong> — Mean-variance portfolio optimization using Markowitz framework.",
    code = '# Mean-Variance Portfolio Optimization\nimport pandas as pd\nimport numpy as np\n\ndef simple_mv_optimization(returns, target_return=None):\n    """\n    Simplified mean-variance optimization\n    In practice, use cvxpy or scipy.optimize\n    \n    Args:\n        returns: DataFrame of asset returns (columns = assets)\n        target_return: Desired portfolio return (None = max Sharpe)\n    \n    Returns:\n        Optimal weights\n    """\n    mean_returns = returns.mean()\n    cov_matrix = returns.cov()\n    \n    # Equal-weight as baseline\n    n_assets = len(mean_returns)\n    equal_weights = np.ones(n_assets) / n_assets\n    \n    # Calculate equal-weight portfolio metrics\n    port_return = np.dot(equal_weights, mean_returns)\n    port_vol = np.sqrt(np.dot(equal_weights, np.dot(cov_matrix, equal_weights)))\n    \n    return {\n        \'weights\': equal_weights,\n        \'expected_return\': port_return * 252,\n        \'volatility\': port_vol * np.sqrt(252),\n        \'sharpe\': (port_return / port_vol) * np.sqrt(252)\n    }\n\n# Example with 3 assets\nnp.random.seed(42)\ndates = pd.date_range(\'2023-01-01\', periods=252, freq=\'D\')\nreturns = pd.DataFrame(\n    np.random.randn(252, 3) * 0.01 + [0.0003, 0.0002, 0.0004],\n    columns=[\'Stock_A\', \'Stock_B\', \'Stock_C\'],\n    index=dates\n)\n\nresult = simple_mv_optimization(returns)\n\nprint("Mean-Variance Optimization Results:")\nprint("=" * 50)\nprint("Optimal Weights:")\nfor i, stock in enumerate(returns.columns):\n    print(f"  {stock}: {result[\'weights\'][i]:.2%}")\nprint(f"\\nExpected Return: {result[\'expected_return\']:.2%}")\nprint(f"Volatility: {result[\'volatility\']:.2%}")\nprint(f"Sharpe Ratio: {result[\'sharpe\']:.3f}")',
    demo = 'np.random.seed(42)\ndates = pd.date_range(\'2023-01-01\', periods=252, freq=\'D\')\nreturns = pd.DataFrame(\n    np.random.randn(252, 3) * 0.01 + [0.0003, 0.0002, 0.0004],\n    columns=[\'Stock_A\', \'Stock_B\', \'Stock_C\'],\n    index=dates\n)\nresult = simple_mv_optimization(returns)\nprint("Mean-Variance Optimization Results:")\nprint("=" * 50)\nprint("Optimal Weights:")\nfor i, stock in enumerate(returns.columns):\n    print(f"  {stock}: {result[\'weights\'][i]:.2%}")\nprint(f"\\nExpected Return: {result[\'expected_return\']:.2%}")\nprint(f"Volatility: {result[\'volatility\']:.2%}")\nprint(f"Sharpe Ratio: {result[\'sharpe\']:.3f}")'
  )
)

chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5, "📊", "Portfolio Optimization and Performance Evaluation",
      "Master portfolio construction techniques from mean-variance optimization to risk parity. Learn to measure and evaluate strategy performance with Sharpe ratio, drawdown analysis, and backtesting.",
      c("Portfolio Optimization", "Sharpe Ratio", "Mean-Variance", "Risk Parity", "Backtesting")),

    stats_row(
      list("Sharpe", "Risk-Adjusted Returns"),
      list("MVO", "Mean-Variance"),
      list("Kelly", "Position Sizing"),
      list("HRP", "Hierarchical Risk Parity")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("maintabs"),
        
        tabPanel(title = tagList(icon("book"), " Concepts"),
          tabBox(width = 12, id = ns("concepttabs"),
            
            tabPanel(title = "📏 Performance Metrics",
              fluidRow(
                box(title = "Sharpe Ratio", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Formula"),
                        tags$p(tags$code("Sharpe = (R_p - R_f) / σ_p")),
                        tags$p("Where:"),
                        tags$ul(
                          tags$li("R_p = Portfolio return"),
                          tags$li("R_f = Risk-free rate"),
                          tags$li("σ_p = Portfolio volatility (std dev)")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Interpretation"),
                        tags$ul(
                          tags$li(tags$strong("< 1.0:"), " Poor risk-adjusted performance"),
                          tags$li(tags$strong("1.0 - 2.0:"), " Good"),
                          tags$li(tags$strong("> 2.0:"), " Excellent (rare in practice)"),
                          tags$li(tags$strong("> 3.0:"), " Exceptional (very rare, check for overfitting)")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Key Insight:</strong> Sharpe ratio normalizes returns by risk, allowing fair comparison between strategies with different volatility profiles.")
                    )
                ),
                box(title = "Information Ratio", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Formula"),
                        tags$p(tags$code("IR = (R_p - R_b) / TE")),
                        tags$p("Where:"),
                        tags$ul(
                          tags$li("R_p = Portfolio return"),
                          tags$li("R_b = Benchmark return"),
                          tags$li("TE = Tracking error (std dev of excess returns)")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Use Case"),
                        tags$p("Measures skill of active manager relative to benchmark."),
                        tags$ul(
                          tags$li(tags$strong("IR > 0.5:"), " Good active management"),
                          tags$li(tags$strong("IR > 1.0:"), " Excellent (top quartile)")
                        )
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>Difference from Sharpe:</strong> IR measures excess return over benchmark, while Sharpe measures absolute risk-adjusted return.")
                    )
                )
              ),
              fluidRow(
                box(title = "Additional Performance Metrics", status = "success", solidHeader = TRUE, width = 12,
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(
                        tags$th("Metric"), 
                        tags$th("Formula / Description"), 
                        tags$th("Interpretation")
                      )),
                      tags$tbody(
                        tags$tr(
                          tags$td(tags$strong("Maximum Drawdown")),
                          tags$td("Peak-to-trough decline in portfolio value"),
                          tags$td("< -20% = moderate risk, < -50% = high risk")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Calmar Ratio")),
                          tags$td("Annualized Return / |Max Drawdown|"),
                          tags$td("> 1.0 = good downside-adjusted returns")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Sortino Ratio")),
                          tags$td("Like Sharpe, but uses downside deviation only"),
                          tags$td("Penalizes volatility on downside only")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Win Rate")),
                          tags$td("% of profitable trades/periods"),
                          tags$td("> 50% needed for profitability (depends on win/loss size)")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Profit Factor")),
                          tags$td("Gross profits / Gross losses"),
                          tags$td("> 1.5 = sustainable strategy")
                        )
                      )
                    )
                )
              )
            ),

            tabPanel(title = "⚖️ Portfolio Optimization Methods",
              fluidRow(
                box(title = "Mean-Variance Optimization (Markowitz)", status = "warning", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("Objective"),
                        tags$p("Maximize expected return for a given level of risk (or minimize risk for a given return)."),
                        tags$p(tags$code("min w' Σ w  subject to  w' μ ≥ R_target, Σw = 1")),
                        tags$p("Where: w = weights, Σ = covariance matrix, μ = expected returns")
                    ),
                    div(class = "framework-card",
                        tags$h5("Strengths"),
                        tags$ul(
                          tags$li("Theoretically optimal under mean-variance preferences"),
                          tags$li("Foundation of modern portfolio theory"),
                          tags$li("Widely understood and accepted")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Weaknesses"),
                        tags$ul(
                          tags$li(tags$strong("Estimation Error:"), " Extremely sensitive to return estimates"),
                          tags$li(tags$strong("Concentration:"), " Often produces extreme weights"),
                          tags$li(tags$strong("Turnover:"), " Frequent rebalancing required"),
                          tags$li(tags$strong("Non-Normal Returns:"), " Assumes Gaussian distribution")
                        )
                    ),
                    div(class = "success-box",
                        HTML("<strong>✅ Practical Tip:</strong> Apply constraints: long-only, max weight per asset (e.g., 10%), turnover penalty.")
                    )
                )
              ),
              fluidRow(
                box(title = "Alternative Approaches", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("1/N (Equal Weight)"),
                        tags$p("Naively allocate equal weight to all assets."),
                        tags$ul(
                          tags$li(tags$strong("Pros:"), " Simple, robust, low turnover"),
                          tags$li(tags$strong("Cons:"), " Ignores risk differences"),
                          tags$li(tags$strong("Research:"), " Surprisingly hard to beat out-of-sample (DeMiguel et al., 2009)")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Minimum Variance"),
                        tags$p("Minimize portfolio variance without targeting return."),
                        tags$ul(
                          tags$li(tags$strong("Pros:"), " More stable than MVO (only uses covariance)"),
                          tags$li(tags$strong("Cons:"), " Ignores expected returns entirely"),
                          tags$li(tags$strong("Result:"), " Often tilts to low-volatility stocks")
                        )
                    )
                ),
                box(title = "Black-Litterman Model", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Concept"),
                        tags$p("Bayesian approach combining market equilibrium with investor views."),
                        tags$ul(
                          tags$li(tags$strong("Prior:"), " Market cap-weighted equilibrium"),
                          tags$li(tags$strong("Views:"), " Investor beliefs (e.g., 'Tech will outperform by 5%')"),
                          tags$li(tags$strong("Posterior:"), " Blended expected returns")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Advantages"),
                        tags$ul(
                          tags$li("Less extreme weights than pure MVO"),
                          tags$li("Incorporates qualitative views systematically"),
                          tags$li("More stable over time")
                        )
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>ML Integration:</strong> Use ML predictions as 'views' in Black-Litterman framework with confidence levels.")
                    )
                )
              )
            ),

            tabPanel(title = "🎲 Kelly Criterion & Risk Parity",
              fluidRow(
                box(title = "Kelly Criterion", status = "success", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Formula (Simplified)"),
                        tags$p(tags$code("f* = (p*b - q) / b")),
                        tags$p("Where:"),
                        tags$ul(
                          tags$li("f* = Fraction of capital to bet"),
                          tags$li("p = Win probability"),
                          tags$li("q = Loss probability (1-p)"),
                          tags$li("b = Win/loss ratio")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Application to Trading"),
                        tags$p("Determines optimal position size to maximize long-run growth."),
                        tags$ul(
                          tags$li(tags$strong("Full Kelly:"), " Aggressive, high volatility"),
                          tags$li(tags$strong("Half Kelly:"), " More conservative, widely used"),
                          tags$li(tags$strong("Quarter Kelly:"), " Very conservative")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>⚠️ Caution:</strong> Full Kelly can lead to extreme drawdowns. Most practitioners use fractional Kelly (0.25-0.5).")
                    )
                ),
                box(title = "Risk Parity", status = "warning", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Principle"),
                        tags$p("Allocate capital so each asset contributes equally to portfolio risk."),
                        tags$p("Traditional 60/40 portfolio: Equities contribute ~90% of risk despite 60% of capital. Risk parity rebalances to equalize.")
                    ),
                    div(class = "framework-card",
                        tags$h5("Implementation"),
                        tags$ul(
                          tags$li("Weight inversely proportional to volatility"),
                          tags$li("Higher weight to bonds (low vol), lower to equities (high vol)"),
                          tags$li("Often uses leverage to achieve target return")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Hierarchical Risk Parity (HRP)"),
                        tags$p("Advanced variant using machine learning clustering:"),
                        tags$ul(
                          tags$li("Cluster assets by correlation"),
                          tags$li("Allocate hierarchically within clusters"),
                          tags$li("More robust to estimation error than MVO")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Backtesting & Evaluation", status = "primary", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("Key Backtesting Tools"),
                        tags$ul(
                          tags$li(tags$strong("Zipline:"), " Event-driven backtester by Quantopian"),
                          tags$li(tags$strong("backtrader:"), " Flexible Python framework"),
                          tags$li(tags$strong("pyfolio:"), " Performance analysis and tear sheets"),
                          tags$li(tags$strong("PyPortfolioOpt:"), " Portfolio optimization library")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Common Backtesting Pitfalls"),
                        tags$ul(
                          tags$li(tags$strong("Look-Ahead Bias:"), " Using future information"),
                          tags$li(tags$strong("Survivorship Bias:"), " Only backtesting on current index constituents"),
                          tags$li(tags$strong("Overfitting:"), " Too many parameters, fits noise"),
                          tags$li(tags$strong("Transaction Costs:"), " Ignoring slippage and commissions"),
                          tags$li(tags$strong("Data Snooping:"), " Testing too many strategies on same data")
                        )
                    ),
                    div(class = "success-box",
                        HTML("<strong>✅ Best Practice:</strong> Walk-forward analysis with out-of-sample testing. Reserve final test set until very end.")
                    )
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header("Chapter 5 Code Examples", 
                         "Portfolio optimization and performance evaluation with Python."),
          file_pills_ui(ns, CH05_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter5_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH05_FILES)
  })
}
