# modules/chapter04.R — Financial Feature Engineering: How to Research Alpha Factors

CH04_FILES <- list(
  list(
    name = "momentum_factor.py",
    description = "<strong>momentum_factor.py</strong> — Calculate momentum alpha factor based on historical price trends.",
    code = '# Momentum Alpha Factor\nimport pandas as pd\nimport numpy as np\n\ndef calculate_momentum(prices, lookback=252, skip=21):\n    """\n    Calculate momentum factor (12-month return, skip last month)\n    \n    Args:\n        prices: Series of daily prices\n        lookback: Lookback period in days (252 = 1 year)\n        skip: Skip recent days to avoid reversal (21 = 1 month)\n    \n    Returns:\n        Momentum factor values\n    """\n    # Calculate returns over lookback period, skipping recent period\n    momentum = prices.pct_change(lookback).shift(skip)\n    return momentum\n\ndef rank_normalize(series):\n    """Convert to cross-sectional ranks (0 to 1)"""\n    return series.rank(pct=True)\n\n# Example with simulated price data\nnp.random.seed(42)\ndates = pd.date_range(\'2023-01-01\', periods=300, freq=\'D\')\nprices = pd.Series(\n    100 * (1 + np.random.randn(300).cumsum() * 0.01),\n    index=dates\n)\n\nmomentum = calculate_momentum(prices, lookback=60, skip=5)\n\nprint("Momentum Factor Analysis:")\nprint("=" * 50)\nprint(f"Latest momentum value: {momentum.iloc[-1]:.4f}")\nprint(f"\\nTop 5 dates by momentum:")\nprint(momentum.nlargest(5))',
    demo = 'np.random.seed(42)\ndates = pd.date_range(\'2023-01-01\', periods=300, freq=\'D\')\nprices = pd.Series(\n    100 * (1 + np.random.randn(300).cumsum() * 0.01),\n    index=dates\n)\nmomentum = calculate_momentum(prices, lookback=60, skip=5)\nprint("Momentum Factor Analysis:")\nprint("=" * 50)\nprint(f"Latest momentum value: {momentum.iloc[-1]:.4f}")\nprint(f"\\nTop 5 dates by momentum:")\nprint(momentum.nlargest(5))'
  ),
  list(
    name = "value_factor.py",
    description = "<strong>value_factor.py</strong> — Calculate value alpha factor using book-to-market ratio.",
    code = '# Value Alpha Factor: Book-to-Market Ratio\nimport pandas as pd\nimport numpy as np\n\ndef calculate_book_to_market(price, book_value):\n    """\n    Calculate book-to-market ratio (value factor)\n    Higher values indicate undervaluation\n    \n    Args:\n        price: Market price per share\n        book_value: Book value per share\n    \n    Returns:\n        Book-to-market ratio\n    """\n    return book_value / price\n\n# Example portfolio of stocks\nstocks = pd.DataFrame({\n    \'ticker\': [\'AAPL\', \'MSFT\', \'GOOGL\', \'AMZN\', \'META\'],\n    \'price\': [180, 380, 140, 170, 480],\n    \'book_value\': [22, 42, 85, 18, 48]\n})\n\nstocks[\'btm_ratio\'] = calculate_book_to_market(\n    stocks[\'price\'], \n    stocks[\'book_value\']\n)\n\n# Rank from most value (highest B/M) to least\nstocks = stocks.sort_values(\'btm_ratio\', ascending=False)\n\nprint("Value Factor Ranking (Book-to-Market):")\nprint("=" * 50)\nprint(stocks.to_string(index=False))\nprint(f"\\nMost undervalued (value stock): {stocks.iloc[0][\'ticker\']}")\nprint(f"Least undervalued (growth stock): {stocks.iloc[-1][\'ticker\']}")',
    demo = 'stocks = pd.DataFrame({\n    \'ticker\': [\'AAPL\', \'MSFT\', \'GOOGL\', \'AMZN\', \'META\'],\n    \'price\': [180, 380, 140, 170, 480],\n    \'book_value\': [22, 42, 85, 18, 48]\n})\nstocks[\'btm_ratio\'] = calculate_book_to_market(stocks[\'price\'], stocks[\'book_value\'])\nstocks = stocks.sort_values(\'btm_ratio\', ascending=False)\nprint("Value Factor Ranking (Book-to-Market):")\nprint("=" * 50)\nprint(stocks.to_string(index=False))\nprint(f"\\nMost undervalued: {stocks.iloc[0][\'ticker\']}")\nprint(f"Least undervalued: {stocks.iloc[-1][\'ticker\']}")'
  )
)

chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4, "⚡", "Financial Feature Engineering: How to Research Alpha Factors",
      "Build on decades of factor research to engineer predictive alpha signals. Explore momentum, value, volatility, size, and quality factors with pandas, NumPy, and TA-Lib.",
      c("Alpha Factors", "Feature Engineering", "TA-Lib", "Alphalens", "Factor Research")),

    stats_row(
      list("6", "Factor Categories"),
      list("300+", "TA-Lib Indicators"),
      list("IC", "Information Coefficient"),
      list("Alphalens", "Validation Tool")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("maintabs"),
        
        tabPanel(title = tagList(icon("book"), " Concepts"),
          tabBox(width = 12, id = ns("concepttabs"),
            
            tabPanel(title = "🧩 Alpha Factors Overview",
              fluidRow(
                box(title = "What Are Alpha Factors?", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Definition"),
                        tags$p("Quantitative signals (features) that predict future asset returns. Alpha factors combine historical data with economic intuition to generate tradeable insights."),
                        tags$ul(
                          tags$li(tags$strong("Input:"), " Price, volume, fundamentals, alternative data"),
                          tags$li(tags$strong("Output:"), " Cross-sectional rank or z-score"),
                          tags$li(tags$strong("Goal:"), " Separate winners from losers")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Key Principle:</strong> Effective factors are grounded in economic theory, persist out-of-sample, and work across different market regimes.")
                    )
                ),
                box(title = "Factor Research Process", status = "primary", solidHeader = TRUE, width = 6,
                    tags$ol(
                      tags$li(tags$strong("Hypothesis:"), " Economic intuition or literature"),
                      tags$li(tags$strong("Construction:"), " Engineer factor from raw data"),
                      tags$li(tags$strong("Backtesting:"), " Historical performance analysis"),
                      tags$li(tags$strong("Validation:"), " Out-of-sample and cross-sectional tests"),
                      tags$li(tags$strong("Combination:"), " Integrate with other factors"),
                      tags$li(tags$strong("Monitoring:"), " Track live performance decay")
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>Tools:</strong> Use Alphalens to evaluate factor IC, turnover, and return spreads across quantiles.")
                    )
                )
              ),
              fluidRow(
                box(title = "Six Major Factor Categories", status = "success", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("1. Momentum & Trend"),
                        tags$p("Assets with strong recent performance tend to continue."),
                        tags$ul(
                          tags$li(tags$strong("Classic:"), " 12-month return (skip last month)"),
                          tags$li(tags$strong("Short-term:"), " 1-week reversal"),
                          tags$li(tags$strong("Trend:"), " Moving average crossovers")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("2. Value"),
                        tags$p("Low price relative to fundamentals signals undervaluation."),
                        tags$ul(
                          tags$li(tags$strong("Book-to-Market:"), " Book value / Market cap"),
                          tags$li(tags$strong("Earnings Yield:"), " Earnings / Price"),
                          tags$li(tags$strong("Cash Flow Yield:"), " Free cash flow / Enterprise value")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("3. Volatility & Risk"),
                        tags$p("Low-volatility stocks often outperform (anomaly)."),
                        tags$ul(
                          tags$li(tags$strong("Realized Volatility:"), " Std dev of returns"),
                          tags$li(tags$strong("Idiosyncratic Vol:"), " Risk not explained by market"),
                          tags$li(tags$strong("Beta:"), " Market sensitivity")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("4. Size"),
                        tags$p("Small-cap stocks historically outperform large-caps."),
                        tags$ul(
                          tags$li(tags$strong("Market Cap:"), " Total equity value"),
                          tags$li(tags$strong("Float-Adjusted:"), " Tradeable shares only"),
                          tags$li(tags$strong("Caveat:"), " Liquidity constraints")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("5. Quality"),
                        tags$p("Profitable, stable companies with strong balance sheets."),
                        tags$ul(
                          tags$li(tags$strong("ROE:"), " Return on equity"),
                          tags$li(tags$strong("Earnings Stability:"), " Low earnings volatility"),
                          tags$li(tags$strong("Low Leverage:"), " Debt-to-equity ratio")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("6. Sentiment"),
                        tags$p("Market psychology and investor behavior."),
                        tags$ul(
                          tags$li(tags$strong("Analyst Revisions:"), " Earnings estimate changes"),
                          tags$li(tags$strong("Short Interest:"), " Shares sold short"),
                          tags$li(tags$strong("News Sentiment:"), " NLP on headlines/transcripts")
                        )
                    )
                )
              )
            ),

            tabPanel(title = "🛠 Engineering Techniques",
              fluidRow(
                box(title = "Technical Indicators (TA-Lib)", status = "warning", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Moving Averages"),
                        tags$ul(
                          tags$li("SMA, EMA, WMA, DEMA, TEMA"),
                          tags$li("KAMA (Kaufman Adaptive)"),
                          tags$li("Crossover signals: Fast MA > Slow MA")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Momentum Oscillators"),
                        tags$ul(
                          tags$li("RSI (Relative Strength Index)"),
                          tags$li("MACD (Moving Average Convergence Divergence)"),
                          tags$li("Stochastic Oscillator"),
                          tags$li("CCI (Commodity Channel Index)")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Volatility Indicators"),
                        tags$ul(
                          tags$li("Bollinger Bands"),
                          tags$li("ATR (Average True Range)"),
                          tags$li("Historical Volatility")
                        )
                    )
                ),
                box(title = "Advanced Feature Engineering", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Denoising with Kalman Filters"),
                        tags$p("Smooth noisy price series to extract true signal."),
                        tags$ul(
                          tags$li("Filter out measurement noise"),
                          tags$li("Estimate latent price trends"),
                          tags$li("Improve signal-to-noise ratio")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Wavelet Decomposition"),
                        tags$p("Decompose time series into different frequency components."),
                        tags$ul(
                          tags$li("Separate high-frequency noise from low-frequency trend"),
                          tags$li("Multi-resolution analysis"),
                          tags$li("Useful for regime detection")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Rolling Window Statistics"),
                        tags$ul(
                          tags$li("Rolling mean, median, std dev"),
                          tags$li("Expanding windows for cumulative metrics"),
                          tags$li("Exponentially-weighted moving averages (EWMA)")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Factor Validation with Alphalens", status = "success", solidHeader = TRUE, width = 12,
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(
                        tags$th("Metric"), 
                        tags$th("Description"), 
                        tags$th("Good Value")
                      )),
                      tags$tbody(
                        tags$tr(
                          tags$td(tags$strong("IC (Information Coefficient)")),
                          tags$td("Rank correlation between factor and forward returns"),
                          tags$td("|IC| > 0.05, significant")
                        ),
                        tags$tr(
                          tags$td(tags$strong("IC Consistency")),
                          tags$td("% of periods with positive IC"),
                          tags$td("> 55-60%")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Return Spread")),
                          tags$td("Top quintile return - Bottom quintile return"),
                          tags$td("> 2-3% annualized")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Turnover")),
                          tags$td("How often holdings change"),
                          tags$td("Lower = better (reduces costs)")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Sharpe Ratio")),
                          tags$td("Risk-adjusted returns of factor portfolio"),
                          tags$td("> 1.0")
                        )
                      )
                    )
                )
              )
            ),

            tabPanel(title = "📐 WorldQuant Alphas",
              fluidRow(
                box(title = "Formulaic Alpha Examples", status = "primary", solidHeader = TRUE, width = 12,
                    div(class = "info-box-plain",
                        HTML("<strong>WorldQuant:</strong> Pioneer in systematic alpha research. Published 101 formulaic alphas demonstrating factor engineering creativity.")
                    ),
                    div(class = "framework-card",
                        tags$h5("Alpha #001"),
                        tags$p(tags$code("rank(Ts_ArgMax(SignedPower(returns, 2), 5)) - 0.5")),
                        tags$p("Ranks stocks by which had the maximum squared return in the past 5 days. Captures short-term momentum bursts.")
                    ),
                    div(class = "framework-card",
                        tags$h5("Alpha #054"),
                        tags$p(tags$code("(-1 * correlation(rank(close), rank(volume), 10))")),
                        tags$p("Negative correlation between price rank and volume rank over 10 days. Identifies divergence patterns.")
                    ),
                    div(class = "framework-card",
                        tags$h5("Key Operations"),
                        tags$ul(
                          tags$li(tags$strong("rank():"), " Cross-sectional ranking"),
                          tags$li(tags$strong("Ts_*:"), " Time-series operations (Ts_Sum, Ts_Std, Ts_ArgMax)"),
                          tags$li(tags$strong("correlation():"), " Rolling correlation"),
                          tags$li(tags$strong("delta():"), " Differencing"),
                          tags$li(tags$strong("SignedPower():"), " Preserves sign while applying power")
                        )
                    ),
                    div(class = "success-box",
                        HTML("<strong>✅ Lesson:</strong> Effective alphas often combine simple operations in creative ways. Start simple, then layer complexity only if validated.")
                    )
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header("Chapter 4 Code Examples", 
                         "Alpha factor calculation and engineering with pandas and NumPy."),
          file_pills_ui(ns, CH04_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH04_FILES)
  })
}
