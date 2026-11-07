# modules/chapter01.R — Machine Learning for Trading: From Idea to Execution

CH01_FILES <- list(
  list(
    name = "ml4t_workflow.py",
    description = "<strong>ml4t_workflow.py</strong> — Basic workflow structure for an ML trading strategy showing the key stages from data acquisition to backtesting.",
    code = '# ML4T Workflow Example\nimport pandas as pd\nimport numpy as np\n\nclass ML4TWorkflow:\n    """Framework for ML trading strategy development"""\n    \n    def __init__(self, strategy_name):\n        self.strategy_name = strategy_name\n        self.stages = [\n            "1. Data Sourcing",\n            "2. Alpha Factor Research", \n            "3. ML Model Training",\n            "4. Portfolio Construction",\n            "5. Strategy Backtesting",\n            "6. Performance Evaluation"\n        ]\n    \n    def display_workflow(self):\n        print(f"Strategy: {self.strategy_name}")\n        print("=" * 50)\n        for stage in self.stages:\n            print(f"  {stage}")\n        print("=" * 50)\n        return self\n\n# Example usage\nworkflow = ML4TWorkflow("Momentum + ML Strategy")\nworkflow.display_workflow()',
    demo = 'workflow = ML4TWorkflow("Mean Reversion Strategy")\nworkflow.display_workflow()'
  ),
  list(
    name = "alpha_factor_example.py",
    description = "<strong>alpha_factor_example.py</strong> — Simple alpha factor calculation demonstrating momentum-based signal generation.",
    code = '# Alpha Factor Example: Simple Momentum\nimport pandas as pd\nimport numpy as np\n\ndef calculate_momentum_alpha(prices, lookback=20):\n    """\n    Calculate momentum alpha factor\n    \n    Args:\n        prices: Series of prices\n        lookback: Number of periods for momentum calculation\n    \n    Returns:\n        Momentum signal (1 = buy, -1 = sell, 0 = neutral)\n    """\n    returns = prices.pct_change(lookback)\n    # Simple signal: positive momentum = buy, negative = sell\n    signal = np.where(returns > 0.02, 1, \n                     np.where(returns < -0.02, -1, 0))\n    return signal\n\n# Example with sample data\nnp.random.seed(42)\nprices = pd.Series(100 * (1 + np.random.randn(50).cumsum() * 0.02))\nmomentum_signal = calculate_momentum_alpha(prices, lookback=10)\n\nprint("Last 10 momentum signals:")\nprint(momentum_signal[-10:])\nprint(f"\\nBuy signals: {sum(momentum_signal == 1)}")\nprint(f"Sell signals: {sum(momentum_signal == -1)}")\nprint(f"Neutral: {sum(momentum_signal == 0)}")',
    demo = 'np.random.seed(42)\nprices = pd.Series(100 * (1 + np.random.randn(50).cumsum() * 0.02))\nmomentum_signal = calculate_momentum_alpha(prices, lookback=10)\nprint("Last 10 momentum signals:")\nprint(momentum_signal[-10:])\nprint(f"\\nBuy signals: {sum(momentum_signal == 1)}")\nprint(f"Sell signals: {sum(momentum_signal == -1)}")\nprint(f"Neutral: {sum(momentum_signal == 0)}")'
  )
)

chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1, "🚀", "Machine Learning for Trading: From Idea to Execution",
      "Overview of ML in the investment industry, from electronic trading to algorithmic strategies. Learn how to design and execute ML-driven trading strategies from start to finish.",
      c("ML Overview", "Strategy Design", "Alpha Factors", "Backtesting")),

    stats_row(
      list("6", "Workflow Stages"),
      list("HFT", "High-Frequency"),
      list("Smart β", "Factor Investing"),
      list("ML+Data", "Alpha Edge")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("maintabs"),
        
        tabPanel(title = tagList(icon("book"), " Concepts"),
          tabBox(width = 12, id = ns("concepttabs"),
            
            tabPanel(title = "📈 Rise of ML in Finance",
              fluidRow(
                box(title = "The Evolution of Trading", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("From Manual to Algorithmic"),
                        tags$p("Trading has evolved from open outcry on trading floors to fully electronic markets where algorithms execute millions of trades per second."),
                        tags$ul(
                          tags$li(tags$strong("1970s-1980s:"), " Electronic trading begins"),
                          tags$li(tags$strong("1990s-2000s:"), " Algorithmic trading emerges"),
                          tags$li(tags$strong("2010s:"), " Machine learning integration"),
                          tags$li(tags$strong("2020s:"), " AI-driven strategies dominate")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Key Insight:</strong> Today, algorithmic trading accounts for 60-75% of total US equity trading volume.")
                    )
                ),
                box(title = "High-Frequency Trading (HFT)", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Characteristics of HFT"),
                        tags$ul(
                          tags$li(tags$strong("Speed:"), " Microsecond to millisecond execution"),
                          tags$li(tags$strong("Volume:"), " Thousands of trades per second"),
                          tags$li(tags$strong("Holding Period:"), " Seconds to minutes"),
                          tags$li(tags$strong("Infrastructure:"), " Co-location, dedicated fiber")
                        )
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>Impact:</strong> HFT firms capture profits from tiny price discrepancies and provide market liquidity.")
                    )
                )
              ),
              fluidRow(
                box(title = "Factor Investing & Smart Beta", status = "success", solidHeader = TRUE, width = 12,
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(
                        tags$th("Factor"), 
                        tags$th("Description"), 
                        tags$th("Academic Basis"),
                        tags$th("Implementation")
                      )),
                      tags$tbody(
                        tags$tr(
                          tags$td("Momentum"), 
                          tags$td("Stocks with strong past performance"), 
                          tags$td("Jegadeesh & Titman (1993)"),
                          tags$td("12-month returns, skip last month")
                        ),
                        tags$tr(
                          tags$td("Value"), 
                          tags$td("Low price relative to fundamentals"), 
                          tags$td("Fama & French (1993)"),
                          tags$td("Book-to-market, P/E ratios")
                        ),
                        tags$tr(
                          tags$td("Size"), 
                          tags$td("Small-cap premium"), 
                          tags$td("Banz (1981)"),
                          tags$td("Market capitalization")
                        ),
                        tags$tr(
                          tags$td("Quality"), 
                          tags$td("Profitable, stable firms"), 
                          tags$td("Novy-Marx (2013)"),
                          tags$td("ROE, earnings stability")
                        )
                      )
                    )
                )
              )
            ),

            tabPanel(title = "🎯 ML-Driven Strategy Design",
              fluidRow(
                box(title = "The ML4T Workflow", status = "warning", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("Stage 1: Data Sourcing and Management"),
                        tags$p("Collect, clean, and store market data, fundamental data, and alternative data sources."),
                        tags$ul(
                          tags$li("Market data: OHLCV, order book, tick data"),
                          tags$li("Fundamental: Financial statements, earnings calls"),
                          tags$li("Alternative: Satellite imagery, web scraping, social media")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Stage 2: Alpha Factor Research"),
                        tags$p("Generate predictive signals (alpha factors) based on historical patterns and economic intuition."),
                        tags$ul(
                          tags$li("Technical indicators: RSI, MACD, Bollinger Bands"),
                          tags$li("Fundamental factors: P/E, ROE, earnings growth"),
                          tags$li("Alternative factors: Sentiment scores, satellite-derived metrics")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Stage 3: ML Model Development"),
                        tags$p("Train predictive models to forecast returns or classify market regimes."),
                        tags$ul(
                          tags$li("Linear models: Ridge, Lasso regression"),
                          tags$li("Tree-based: Random Forest, Gradient Boosting"),
                          tags$li("Deep learning: RNN, LSTM, Transformer models")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Stage 4: Portfolio Construction & Risk Management"),
                        tags$p("Convert ML predictions into portfolio weights while managing risk."),
                        tags$ul(
                          tags$li("Mean-variance optimization"),
                          tags$li("Risk parity approaches"),
                          tags$li("Position sizing and leverage")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Stage 5: Strategy Backtesting"),
                        tags$p("Simulate historical performance accounting for transaction costs and realistic constraints."),
                        tags$ul(
                          tags$li("Walk-forward analysis"),
                          tags$li("Out-of-sample testing"),
                          tags$li("Transaction cost modeling")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Stage 6: Performance Evaluation"),
                        tags$p("Assess risk-adjusted returns and diagnose potential issues."),
                        tags$ul(
                          tags$li("Sharpe ratio, Information ratio"),
                          tags$li("Maximum drawdown analysis"),
                          tags$li("Overfitting detection")
                        )
                    )
                )
              )
            ),

            tabPanel(title = "📊 Use Cases & Applications",
              fluidRow(
                box(title = "ML for Trading: Primary Use Cases", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Return Prediction"),
                        tags$p("Forecast future asset returns using supervised learning."),
                        tags$ul(
                          tags$li("Target: Next-day, next-week, or next-month returns"),
                          tags$li("Features: Price patterns, fundamentals, sentiment"),
                          tags$li("Models: Linear regression, gradient boosting, neural nets")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Risk Modeling"),
                        tags$p("Predict volatility and tail risk events."),
                        tags$ul(
                          tags$li("GARCH models for volatility"),
                          tags$li("Extreme value theory for tail events"),
                          tags$li("Copulas for dependency modeling")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Asset Allocation"),
                        tags$p("Optimize portfolio weights across assets."),
                        tags$ul(
                          tags$li("Hierarchical risk parity"),
                          tags$li("Black-Litterman with ML views"),
                          tags$li("Reinforcement learning for dynamic allocation")
                        )
                    )
                ),
                box(title = "Alternative Data Integration", status = "success", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Satellite Imagery"),
                        tags$p("Monitor economic activity from space:"),
                        tags$ul(
                          tags$li("Parking lot car counts → retail sales"),
                          tags$li("Oil storage tank levels → crude prices"),
                          tags$li("Agricultural yield estimation")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Web & Social Media"),
                        tags$p("Extract signals from online behavior:"),
                        tags$ul(
                          tags$li("News sentiment analysis"),
                          tags$li("Twitter/Reddit discussion volume"),
                          tags$li("App store rankings and reviews")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Credit Card & Point-of-Sale"),
                        tags$p("Real-time consumer spending patterns:"),
                        tags$ul(
                          tags$li("Anonymized transaction volumes"),
                          tags$li("Category-level spending trends"),
                          tags$li("Predict earnings before official release")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Algorithmic Strategy Evolution", status = "primary", solidHeader = TRUE, width = 12,
                    div(class = "success-box",
                        HTML("<strong>✅ Modern Advantage:</strong> ML enables strategies to adapt to changing market conditions, discover complex non-linear patterns, and process vast alternative datasets that humans cannot analyze manually.")
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Key Consideration:</strong> Successful ML strategies balance complexity with interpretability. Overly complex models may overfit historical data and fail in live trading.")
                    )
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header("Chapter 1 Code Examples", 
                         "Foundational Python examples for ML4T workflow and alpha factor generation."),
          file_pills_ui(ns, CH01_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter1_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH01_FILES)
  })
}
