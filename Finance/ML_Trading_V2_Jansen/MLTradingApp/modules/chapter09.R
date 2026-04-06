# modules/chapter09.R — Time-Series Models for Volatility Forecasts and Statistical Arbitrage

chapter9_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(9, "📉", "Time-Series Models",
      "Volatility Forecasts and Statistical Arbitrage - ARIMA, GARCH, and cointegration for volatility prediction and pairs trading strategies.",
      c("ARIMA", "GARCH", "Cointegration", "Pairs Trading", "VAR")),

    stats_row(
      list("ARIMA", "Univariate Model"),
      list("GARCH", "Volatility Model"), 
      list("Cointegration", "Pairs Selection"),
      list("statsmodels", "Python Library")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "📊 Stationarity: The Foundation", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Why Stationarity Matters",
                  tagList(
                    tags$p("Most time-series models assume stationarity: statistical properties (mean, variance) constant over time."),
                    tags$p(tags$strong("Tests:")),
                    tags$ul(
                      tags$li(tags$strong("ADF:"), " Augmented Dickey-Fuller test for unit roots"),
                      tags$li(tags$strong("KPSS:"), " Tests null of stationarity"),
                      tags$li(tags$strong("PP:"), " Phillips-Perron test")
                    )
                  )
                ),
                framework_card("Achieving Stationarity",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Differencing:"), " Δy_t = y_t - y_{t-1}"),
                      tags$li(tags$strong("Log Returns:"), " log(P_t / P_{t-1})"),
                      tags$li(tags$strong("Detrending:"), " Remove linear/polynomial trends"),
                      tags$li(tags$strong("Seasonal Adj:"), " Remove periodic patterns")
                    )
                  )
                )
            ),
            
            box(title = "📈 ARIMA Models", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Model Components",
                  tagList(
                    tags$p(tags$strong("AR(p):"), " Autoregressive - depends on p past values"),
                    tags$p("y_t = c + φ₁y_{t-1} + ... + φₚy_{t-p} + ε_t"),
                    tags$p(tags$strong("I(d):"), " Integrated - differencing order"),
                    tags$p(tags$strong("MA(q):"), " Moving Average - depends on q past errors"),
                    tags$p("y_t = μ + ε_t + θ₁ε_{t-1} + ... + θ_qε_{t-q}")
                  )
                ),
                framework_card("Model Selection",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("ACF/PACF:"), " Identify p and q orders"),
                      tags$li(tags$strong("AIC/BIC:"), " Compare model fit"),
                      tags$li(tags$strong("Residual Diagnostics:"), " Check white noise"),
                      tags$li(tags$strong("SARIMAX:"), " Add seasonal components and exogenous variables")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📊 ARIMA Illustration", status = "success", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("arima_forecast"), height = "350px")
            )
          ),
          
          fluidRow(
            box(title = "💨 GARCH Models for Volatility", status = "info", solidHeader = TRUE, width = 6,
                framework_card("The ARCH Model",
                  tagList(
                    tags$p("Autoregressive Conditional Heteroskedasticity:"),
                    tags$p("σ²_t = α₀ + α₁ε²_{t-1} + ... + α_qε²_{t-q}"),
                    tags$p("Variance depends on past squared residuals. Captures volatility clustering.")
                  )
                ),
                framework_card("GARCH(p,q) Extension",
                  tagList(
                    tags$p("Generalized ARCH adds autoregressive variance terms:"),
                    tags$p("σ²_t = α₀ + Σα_iε²_{t-i} + Σβ_jσ²_{t-j}"),
                    tags$p(tags$strong("GARCH(1,1):"), " Most common - balances fit and parsimony"),
                    tags$p(tags$strong("Applications:"), " Option pricing, risk management, volatility targeting")
                  )
                )
            ),
            
            box(title = "📈 Volatility Forecast Example", status = "warning", solidHeader = TRUE, width = 6,
                plotlyOutput(ns("garch_vol"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "🔗 Cointegration for Pairs Trading", status = "success", solidHeader = TRUE, width = 12,
                framework_card("What is Cointegration?",
                  tagList(
                    tags$p("Two non-stationary time series that share a common stochastic trend. Their linear combination is stationary."),
                    tags$p(tags$strong("Example:"), " Stock A and Stock B drift randomly but maintain stable spread → mean-reverting spread"),
                    tags$p(tags$strong("Trading Logic:"), " Spread deviates → trade on mean reversion")
                  )
                ),
                framework_card("Testing for Cointegration",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Engle-Granger:"), " Two-step: (1) Regress A~B, (2) Test residuals for stationarity"),
                      tags$li(tags$strong("Johansen:"), " Likelihood ratio test, handles multiple series"),
                      tags$li(tags$strong("ADF on Spread:"), " p-value < 0.05 suggests cointegration")
                    )
                  )
                ),
                plotlyOutput(ns("cointegration"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "💼 Pairs Trading Strategy", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Strategy Steps",
                  tagList(
                    tags$ol(
                      tags$li(tags$strong("Find Pairs:"), " Test all combinations for cointegration"),
                      tags$li(tags$strong("Hedge Ratio:"), " β from regression A = α + βB"),
                      tags$li(tags$strong("Compute Spread:"), " S_t = A_t - βB_t"),
                      tags$li(tags$strong("Z-Score:"), " (S_t - μ) / σ"),
                      tags$li(tags$strong("Entry:"), " |Z| > 2 (spread deviated)"),
                      tags$li(tags$strong("Exit:"), " Z crosses zero (mean reversion)"),
                      tags$li(tags$strong("Stop-Loss:"), " |Z| > 3 (divergence accelerates)")
                    )
                  )
                )
            ),
            
            box(title = "🎯 Pair Selection Methods", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Distance-Based Heuristics",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Same Sector:"), " Industry peers more likely cointegrated"),
                      tags$li(tags$strong("Price Correlation:"), " Screen for ρ > 0.7"),
                      tags$li(tags$strong("Distance Metric:"), " Sum of squared differences"),
                      tags$li(tags$strong("Statistical Test:"), " Verify with Engle-Granger/Johansen")
                    ),
                    tags$p(tags$strong("Caution:"), " Correlation ≠ Cointegration! Must test formally.")
                  )
                ),
                framework_card("Implementation Tips",
                  tagList(
                    tags$ul(
                      tags$li("Rolling window for hedge ratio recalibration"),
                      tags$li("Transaction costs critical (frequent rebalancing)"),
                      tags$li("Monitor cointegration stability"),
                      tags$li("Diversify across multiple pairs"),
                      tags$li("Half-life of mean reversion guides holding period")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📊 VAR Models for Multivariate Analysis", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Vector Autoregression",
                  tagList(
                    tags$p("Extends AR to multiple time series. Each variable regressed on lagged values of all variables:"),
                    tags$p("y_t = c + A₁y_{t-1} + ... + Aₚy_{t-p} + ε_t"),
                    tags$p(tags$strong("Use Cases:")),
                    tags$ul(
                      tags$li("Macro forecasting (GDP, inflation, rates)"),
                      tags$li("Multi-asset return modeling"),
                      tags$li("Impulse response analysis"),
                      tags$li("Granger causality tests")
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

chapter9_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$arima_forecast <- renderPlotly({
      set.seed(42)
      dates <- seq(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
      historical <- cumsum(rnorm(length(dates), 0.0002, 0.015)) + 100
      
      forecast_dates <- seq(as.Date("2025-01-01"), as.Date("2025-06-30"), by = "day")
      forecast_mean <- tail(historical, 1) + cumsum(rnorm(length(forecast_dates), 0.0002, 0.01))
      forecast_upper <- forecast_mean + 2 * seq(0.5, 3, length.out = length(forecast_dates))
      forecast_lower <- forecast_mean - 2 * seq(0.5, 3, length.out = length(forecast_dates))
      
      plot_ly() %>%
        add_trace(x = dates, y = historical, name = "Historical", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        add_trace(x = forecast_dates, y = forecast_mean, name = "Forecast", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2, dash = "dash")) %>%
        add_trace(x = forecast_dates, y = forecast_upper, name = "Upper CI", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 1, dash = "dot"),
                  showlegend = FALSE, hoverinfo = "none") %>%
        add_trace(x = forecast_dates, y = forecast_lower, name = "Lower CI", type = "scatter", mode = "lines",
                  fill = "tonexty", fillcolor = "rgba(247, 147, 30, 0.2)",
                  line = list(color = ml_colors$accent1, width = 1, dash = "dot"),
                  showlegend = FALSE, hoverinfo = "none") %>%
        layout(
          title = list(text = "ARIMA Forecast with Confidence Intervals", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Price", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$garch_vol <- renderPlotly({
      set.seed(123)
      dates <- seq(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
      volatility <- abs(cumsum(rnorm(length(dates), 0, 0.002))) + 0.15
      volatility <- volatility + 0.05 * sin(seq(0, 10*pi, length.out = length(dates)))
      
      plot_ly(x = dates, y = volatility * 100, type = "scatter", mode = "lines",
              fill = "tozeroy", fillcolor = "rgba(0, 138, 130, 0.3)",
              line = list(color = ml_colors$primary, width = 2)) %>%
        layout(
          title = list(text = "GARCH(1,1) Volatility Forecast", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Annualized Volatility (%)", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
    })
    
    output$cointegration <- renderPlotly({
      set.seed(456)
      dates <- seq(as.Date("2020-01-01"), as.Date("2024-12-31"), by = "day")
      common_trend <- cumsum(rnorm(length(dates), 0.001, 0.02))
      
      stock_a <- 100 + common_trend + rnorm(length(dates), 0, 2)
      stock_b <- 80 + 0.8 * common_trend + rnorm(length(dates), 0, 1.5)
      spread <- stock_a - 1.25 * stock_b
      
      plot_ly() %>%
        add_trace(x = dates, y = stock_a, name = "Stock A", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2), yaxis = "y") %>%
        add_trace(x = dates, y = stock_b, name = "Stock B", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2), yaxis = "y") %>%
        add_trace(x = dates, y = spread, name = "Spread", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$accent1, width = 2), yaxis = "y2") %>%
        layout(
          title = list(text = "Cointegrated Pair: Stocks and Their Spread", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Price", color = "#8B949E", gridcolor = "#30363D"),
          yaxis2 = list(title = "Spread", overlaying = "y", side = "right", color = ml_colors$accent1),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
  })
}
