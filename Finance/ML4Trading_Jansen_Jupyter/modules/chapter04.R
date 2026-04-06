# modules/chapter04.R — Financial Feature Engineering: How to Research Alpha Factors

chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4, "🔬", "Financial Feature Engineering",
      "How to Research Alpha Factors - Building predictive signals from market data using momentum, value, quality, and volatility factors.",
      c("Alpha Factors", "Momentum", "Value", "Quality", "Zipline", "Alphalens")),

    stats_row(
      list("5", "Factor Categories"),
      list("100+", "Common Factors"), 
      list("IC", "Performance Metric"),
      list("Zipline", "Backtesting Tool")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "📊 Alpha Factors in Practice", status = "info", solidHeader = TRUE, width = 6,
                framework_card("From Data to Signals",
                  "Alpha factors transform raw market, fundamental, and alternative data into predictive signals for expected returns. The process involves feature engineering, validation, and combination into robust trading strategies."
                ),
                framework_card("Building on Decades of Research",
                  tagList(
                    tags$p("Factor investing leverages academic research spanning 50+ years:"),
                    tags$ul(
                      tags$li(tags$strong("1960s:"), " CAPM and market beta"),
                      tags$li(tags$strong("1990s:"), " Fama-French three-factor model"),
                      tags$li(tags$strong("2000s:"), " Momentum, quality, low volatility"),
                      tags$li(tags$strong("2010s:"), " Alternative data and ML-driven factors")
                    )
                  )
                )
            ),
            
            box(title = "💹 Factor Categories", status = "warning", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Factor"), 
                    tags$th("Hypothesis"), 
                    tags$th("Examples")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Momentum")),
                      tags$td("Past winners continue winning"),
                      tags$td("12-1 month returns, RSI")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Value")),
                      tags$td("Cheap assets outperform"),
                      tags$td("P/E, P/B, EV/EBITDA")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Quality")),
                      tags$td("High-quality firms earn premiums"),
                      tags$td("ROE, profit margins, accruals")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Volatility")),
                      tags$td("Low-vol stocks outperform"),
                      tags$td("Beta, realized volatility")
                    ),
                    tags$tr(
                      tags$td(tags$strong("Size")),
                      tags$td("Small caps earn premium"),
                      tags$td("Market cap, liquidity")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Factor Performance Simulation", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("factor_returns"), height = "400px")
            )
          ),
          
          fluidRow(
            box(title = "🔧 Engineering Alpha Factors with pandas", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Data Preparation Steps",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Loading:"), " Import price, fundamental, and alternative data"),
                      tags$li(tags$strong("Slicing:"), " Filter by date range and universe"),
                      tags$li(tags$strong("Reshaping:"), " Pivot to wide format (stocks as columns)"),
                      tags$li(tags$strong("Resampling:"), " Convert daily → weekly/monthly frequency"),
                      tags$li(tags$strong("Computing Returns:"), " Multiple holding periods (1d, 5d, 21d, 63d)"),
                      tags$li(tags$strong("Lagging:"), " Shift features to avoid lookahead bias"),
                      tags$li(tags$strong("Forward Returns:"), " Create prediction targets")
                    )
                  )
                ),
                tip_box("Lookahead Bias", "Always lag features by at least 1 period. Use only information that was available at the time of signal generation.")
            ),
            
            box(title = "📐 Technical Indicators with TA-Lib", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Popular TA-Lib Functions",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Momentum:"), " RSI, MACD, Stochastic, ROC"),
                      tags$li(tags$strong("Volatility:"), " ATR, Bollinger Bands, ADX"),
                      tags$li(tags$strong("Trend:"), " SMA, EMA, TRIX"),
                      tags$li(tags$strong("Volume:"), " OBV, MFI, AD"),
                      tags$li(tags$strong("Pattern:"), " CDL patterns (100+ candlestick patterns)")
                    )
                  )
                ),
                framework_card("Denoising with Kalman Filter",
                  "Kalman filters smooth noisy price signals by modeling the data as a state-space process. Useful for extracting true signal from high-frequency data with measurement noise."
                )
            )
          ),
          
          fluidRow(
            box(title = "🎯 Backtesting with Zipline", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Zipline Workflow",
                  tagList(
                    tags$p("Zipline is Quantopian's open-source backtesting library supporting event-driven simulation with realistic market mechanics."),
                    tags$h5("Key Components:"),
                    tags$ul(
                      tags$li(tags$strong("initialize():"), " Set up initial conditions, schedule functions"),
                      tags$li(tags$strong("handle_data():"), " Called every bar with current market data"),
                      tags$li(tags$strong("before_trading_start():"), " Pre-market data processing"),
                      tags$li(tags$strong("Pipeline:"), " Define factor computations declaratively"),
                      tags$li(tags$strong("order():"), " Execute trades with fill simulation"),
                      tags$li(tags$strong("record():"), " Track custom metrics")
                    )
                  )
                ),
                plotlyOutput(ns("backtest_example"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Evaluating Factors with Alphalens", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Alpha lens Analysis Framework",
                  tagList(
                    tags$p("Alphalens evaluates predictive power of alpha factors before deploying in live strategies."),
                    tags$h5("Key Metrics:"),
                    tags$ul(
                      tags$li(tags$strong("Information Coefficient (IC):"), " Rank correlation between factor and forward returns"),
                      tags$li(tags$strong("Factor Quintile Returns:"), " Performance by factor ranking"),
                      tags$li(tags$strong("Turnover:"), " How often positions change (impacts transaction costs)"),
                      tags$li(tags$strong("Factor Autocorrelation:"), " Persistence of factor values"),
                      tags$li(tags$strong("Risk-Adjusted Returns:"), " Sharpe ratio by quintile")
                    )
                  )
                ),
                plotlyOutput(ns("ic_analysis"), height = "300px")
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

chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$factor_returns <- renderPlotly({
      set.seed(123)
      dates <- seq(as.Date("2015-01-01"), as.Date("2024-12-31"), by = "month")
      
      data <- data.frame(
        Date = rep(dates, 5),
        Factor = rep(c("Momentum", "Value", "Quality", "Low Vol", "Size"), each = length(dates)),
        Cumulative_Return = c(
          cumprod(1 + rnorm(length(dates), 0.008, 0.04)),
          cumprod(1 + rnorm(length(dates), 0.006, 0.035)),
          cumprod(1 + rnorm(length(dates), 0.007, 0.03)),
          cumprod(1 + rnorm(length(dates), 0.005, 0.025)),
          cumprod(1 + rnorm(length(dates), 0.004, 0.038))
        )
      )
      
      plot_ly(data, x = ~Date, y = ~Cumulative_Return, color = ~Factor,
              colors = generate_palette(5), type = "scatter", mode = "lines",
              line = list(width = 2)) %>%
        layout(
          title = list(text = "Factor Performance: Cumulative Returns", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Cumulative Return", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$backtest_example <- renderPlotly({
      dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "day")
      portfolio_value <- cumprod(1 + rnorm(length(dates), 0.0003, 0.015))
      benchmark_value <- cumprod(1 + rnorm(length(dates), 0.0002, 0.012))
      
      data <- data.frame(
        Date = dates,
        Portfolio = portfolio_value,
        Benchmark = benchmark_value
      )
      
      plot_ly(data) %>%
        add_trace(x = ~Date, y = ~Portfolio, name = "Alpha Strategy", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = ~Date, y = ~Benchmark, name = "Market Benchmark", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2)) %>%
        layout(
          title = list(text = "Zipline Backtest: Strategy vs Benchmark", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Portfolio Value", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$ic_analysis <- renderPlotly({
      dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "month")
      ic_values <- rnorm(length(dates), 0.05, 0.15)
      
      plot_ly(x = dates, y = ic_values, type = "bar",
              marker = list(color = ifelse(ic_values > 0, ml_colors$success, ml_colors$danger))) %>%
        add_trace(x = dates, y = rep(0, length(dates)), type = "scatter", mode = "lines",
                  line = list(color = "#8B949E", width = 1, dash = "dash"),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "Information Coefficient Over Time", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "IC", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = FALSE
        )
    })
    
  })
}
