# Multi-Asset Analysis Dashboard - Cryptocurrencies, Private Equity & Commodities
# Real-time data fetching with quantmod for stocks and crypto data sources
# Enhanced with Sharpe Ratio, Sortino Ratio, and Hedging Strategy Indicators

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(TTR)
library(tidyr)
library(quantmod)
library(zoo)
library(corrplot)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Multi-Asset Analysis Dashboard"),
  
  dashboardSidebar(
    # Asset class selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        selectInput("assetClass", 
                    "Select Asset Class:",
                    choices = c("Cryptocurrencies" = "crypto", 
                                "Private Equity" = "equity",
                                "Commodities" = "commodity"),
                    selected = "crypto",
                    width = "100%")
    ),
    
    # Asset instance selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        conditionalPanel(
          condition = "input.assetClass == 'crypto'",
          selectInput("cryptoAsset", 
                      "Select Cryptocurrency:",
                      choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                  "Ethereum (ETH-USD)" = "ETH-USD",
                                  "Cardano (ADA-USD)" = "ADA-USD"),
                      selected = "BTC-USD",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.assetClass == 'equity'",
          selectInput("equityAsset", 
                      "Select Private Equity Stock:",
                      choices = c("NVIDIA (NVDA)" = "NVDA",
                                  "Microsoft (MSFT)" = "MSFT",
                                  "Apple (AAPL)" = "AAPL"),
                      selected = "NVDA",
                      width = "100%")
        ),
        conditionalPanel(
          condition = "input.assetClass == 'commodity'",
          selectInput("commodityAsset", 
                      "Select Commodity:",
                      choices = c("Gold (GC=F)" = "GC=F",
                                  "Crude Oil (CL=F)" = "CL=F",
                                  "Natural Gas (NG=F)" = "NG=F"),
                      selected = "GC=F",
                      width = "100%")
        )
    ),
    
    sidebarMenu(
      menuItem("Market Overview", tabName = "overview", icon = icon("chart-line")),
      menuItem("Price Analysis", tabName = "price", icon = icon("chart-simple")),
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar")),
      menuItem("Volatility Analysis", tabName = "volatility", icon = icon("wave-square")),
      menuItem("Risk Metrics", tabName = "risk", icon = icon("exclamation-triangle")),
      menuItem("Advanced Metrics", tabName = "advanced", icon = icon("star")),
      menuItem("Hedging Strategies", tabName = "hedging", icon = icon("shield-alt")),
      menuItem("Composite Analysis", tabName = "composite", icon = icon("layer-group"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Main body background with teal gradient */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        
        /* Sidebar styling with teal gradient */
        .sidebar, .main-sidebar {
          background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        
        .sidebar .sidebar-menu > li > a {
          color: #ffffff !important;
          border-left: 3px solid transparent;
          transition: all 0.3s ease;
        }
        
        .sidebar .sidebar-menu > li.active > a,
        .sidebar .sidebar-menu > li:hover > a {
          background: rgba(255, 255, 255, 0.15) !important;
          border-left: 3px solid #00A39A !important;
          color: #ffffff !important;
        }
        
        /* Header/navbar with matching gradient */
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          border-bottom: none;
        }
        
        .main-header .navbar-nav > li > a {
          color: #ffffff !important;
        }
        
        /* Box styling with enhanced gradients */
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
          margin-bottom: 20px;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .box:hover {
          transform: translateY(-2px);
          box-shadow: 0 12px 35px rgba(0, 44, 60, 0.3) !important;
        }
        
        /* Box headers with gradients */
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
          border-bottom: none !important;
        }
        
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
          font-size: 16px;
        }
        
        /* Box body styling */
        .box-body {
          background-color: #ffffff !important;
          color: #2c3e50 !important;
          padding: 20px;
          border-radius: 0 0 12px 12px;
        }
        
        /* Value boxes with enhanced gradients */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
          transition: transform 0.2s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
        }
        
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        
        .small-box.bg-green { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        
        .small-box.bg-red { 
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
        }
        
        .small-box.bg-purple { 
          background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%) !important; 
        }
        
        .small-box.bg-teal { 
          background: linear-gradient(135deg, #1abc9c 0%, #16a085 100%) !important; 
        }
        
        .small-box.bg-orange { 
          background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%) !important; 
        }
        
        /* Info boxes styling */
        .info-box {
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.15) !important;
          border-left: 4px solid #008A82;
        }
        
        /* Status message styling */
        .data-info {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .data-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #f39c12 !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(243, 156, 18, 0.2);
        }
        
        /* Input and form styling */
        .form-control {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease, box-shadow 0.3s ease;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
        }
        
        /* Button styling with gradients */
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          padding: 10px 20px;
          font-weight: 600;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(0, 138, 130, 0.3);
        }
        
        /* DataTable styling */
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          color: white !important;
        }
        
        /* Spinner styling */
        .spinner-border {
          color: #008A82 !important;
        }
        
        /* Logo styling */
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          border-bottom: none !important;
          font-weight: 600;
        }
        
        /* Scrollbar styling */
        .box-body::-webkit-scrollbar {
          width: 6px;
        }
        
        .box-body::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 3px;
        }
        
        .box-body::-webkit-scrollbar-thumb {
          background: linear-gradient(135deg, #008A82, #00A39A);
          border-radius: 3px;
        }
      "))
    ),
    
    tabItems(
      # Market Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Data Information & Chart Controls",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           div(class = "data-info",
                               uiOutput("dataSourceInfo"))
                    ),
                    column(3,
                           checkboxGroupInput("overviewComponents", "Show Components:",
                                              choices = c("Close Price" = "close",
                                                          "Volume" = "volume",
                                                          "Moving Averages" = "ma"),
                                              selected = c("close", "volume"),
                                              inline = FALSE)
                    ),
                    column(3,
                           numericInput("overviewMA", "Moving Average Period:",
                                        value = 20, min = 5, max = 200, step = 5)
                    ),
                    column(3,
                           actionButton("refreshData", "Refresh Data", 
                                        class = "btn-primary", width = "100%")
                    )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("currentPrice", width = 3),
                valueBoxOutput("dailyChange", width = 3),
                valueBoxOutput("volumeInfo", width = 3),
                valueBoxOutput("dataRange", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Price Chart with Volume", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("overviewChart", height = "500px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Market Statistics", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("marketStats"))
                ),
                box(
                  title = "Price Movement Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("priceMovementStats"))
                ),
                box(
                  title = "Volume Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("volumeStats"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Returns Distribution", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("returnsDistribution", height = "300px"))
                ),
                box(
                  title = "Price Distribution", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("priceDistribution", height = "300px"))
                )
              )
      ),
      
      # Price Analysis Tab
      tabItem(tabName = "price",
              fluidRow(
                box(
                  title = "Price Analysis Controls", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           dateRangeInput("priceRange", "Analysis Period:",
                                          start = Sys.Date() - months(6),
                                          end = Sys.Date(),
                                          format = "yyyy-mm-dd")
                    ),
                    column(3,
                           checkboxGroupInput("priceComponents", "Show Components:",
                                              choices = c("Close" = "close",
                                                          "High/Low" = "highlow",
                                                          "Open" = "open"),
                                              selected = c("close", "highlow"))
                    ),
                    column(3,
                           numericInput("priceMAPeriod", "MA Periods:",
                                        value = 20, min = 5, max = 200),
                           checkboxInput("showBollingerBands", "Bollinger Bands", FALSE)
                    ),
                    column(3,
                           verbatimTextOutput("priceStats")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Detailed Price Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("detailedPriceChart", height = "600px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "OHLC Candlestick Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  withSpinner(plotlyOutput("ohlcChart", height = "450px"))
                ),
                box(
                  title = "OHLC Statistics", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 4,
                  withSpinner(DT::dataTableOutput("ohlcStats"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Returns Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("returnsTimeSeries", height = "350px"))
                ),
                box(
                  title = "Cumulative Returns", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("cumulativeReturns", height = "350px"))
                )
              )
      ),
      
      # Technical Indicators Tab
      tabItem(tabName = "technical",
              fluidRow(
                box(
                  title = "Technical Analysis Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 3,
                  
                  checkboxGroupInput("technicalIndicators", "Select Indicators:",
                                     choices = c("Simple Moving Average" = "sma",
                                                 "Exponential Moving Average" = "ema",
                                                 "RSI" = "rsi",
                                                 "MACD" = "macd",
                                                 "Bollinger Bands" = "bb",
                                                 "Stochastic" = "stoch"),
                                     selected = c("sma", "rsi")),
                  
                  numericInput("smaLength", "SMA Length:", value = 20, min = 5, max = 200),
                  numericInput("emaLength", "EMA Length:", value = 20, min = 5, max = 200),
                  numericInput("rsiLength", "RSI Length:", value = 14, min = 5, max = 50),
                  numericInput("bbLength", "BB Length:", value = 20, min = 5, max = 100),
                  numericInput("bbSd", "BB Std Dev:", value = 2, min = 1, max = 3, step = 0.1),
                  
                  br(),
                  h5("Current Signals:"),
                  verbatimTextOutput("technicalSignals")
                ),
                
                box(
                  title = "Technical Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 9,
                  withSpinner(plotlyOutput("technicalChart", height = "600px"))
                )
              ),
              
              conditionalPanel(
                condition = "input.technicalIndicators.includes('rsi')",
                fluidRow(
                  box(
                    title = "RSI Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("rsiChart", height = "300px"))
                  )
                )
              ),
              
              conditionalPanel(
                condition = "input.technicalIndicators.includes('macd')",
                fluidRow(
                  box(
                    title = "MACD Indicator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("macdChart", height = "300px"))
                  )
                )
              ),
              
              conditionalPanel(
                condition = "input.technicalIndicators.includes('stoch')",
                fluidRow(
                  box(
                    title = "Stochastic Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("stochChart", height = "300px"))
                  )
                )
              )
      ),
      
      # Volatility Analysis Tab
      tabItem(tabName = "volatility",
              fluidRow(
                box(
                  title = "Volatility Analysis Controls", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  radioButtons("volatilityType", "Volatility Method:",
                               choices = c("Realized (Close-to-Close)" = "realized",
                                           "Parkinson (High-Low)" = "parkinson",
                                           "Garman-Klass (OHLC)" = "gk"),
                               selected = "realized"),
                  
                  numericInput("volWindow", "Rolling Window:",
                               value = 30, min = 10, max = 252),
                  
                  sliderInput("volConfidence", "Confidence Level:",
                              min = 90, max = 99, value = 95),
                  
                  checkboxInput("annualizeVol", "Annualize Volatility", TRUE),
                  
                  br(),
                  h5("Volatility Metrics:"),
                  verbatimTextOutput("volatilityMetrics")
                ),
                
                box(
                  title = "Volatility Time Series", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  withSpinner(plotlyOutput("volatilityChart", height = "450px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Volatility Distribution", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("volatilityDist", height = "350px"))
                ),
                box(
                  title = "Volatility Clustering", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("volatilityClustering", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Volatility Regime Analysis", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("volatilityRegimes", height = "300px"))
                )
              )
      ),
      
      # Risk Metrics Tab
      tabItem(tabName = "risk",
              fluidRow(
                box(
                  title = "Risk Analysis Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  numericInput("portfolioValue", "Portfolio Value (USD):",
                               value = 1000000, min = 10000, max = 100000000, step = 10000),
                  
                  sliderInput("confidenceLevel", "VaR Confidence (%):",
                              min = 90, max = 99.5, value = 95, step = 0.5),
                  
                  numericInput("timeHorizon", "Time Horizon (days):",
                               value = 1, min = 1, max = 30),
                  
                  radioButtons("varMethod", "VaR Method:",
                               choices = c("Historical" = "historical",
                                           "Parametric" = "parametric",
                                           "Cornish-Fisher" = "modified"),
                               selected = "historical"),
                  
                  numericInput("varWindow", "VaR Window:",
                               value = 250, min = 100, max = 1000),
                  
                  br(),
                  h5("Risk Summary:"),
                  verbatimTextOutput("riskMetrics")
                ),
                
                box(
                  title = "Value at Risk Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  withSpinner(plotlyOutput("varChart", height = "450px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Expected Shortfall", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("expectedShortfall", height = "350px"))
                ),
                box(
                  title = "Drawdown Analysis", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("drawdownAnalysis", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk Statistics", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(DT::dataTableOutput("riskStatsTable"))
                ),
                box(
                  title = "Stress Testing", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(DT::dataTableOutput("stressTestResults"))
                )
              )
      ),
      
      # Advanced Metrics Tab (NEW)
      tabItem(tabName = "advanced",
              fluidRow(
                valueBoxOutput("sharpeRatioBox", width = 3),
                valueBoxOutput("sortinoRatioBox", width = 3),
                valueBoxOutput("calmarRatioBox", width = 3),
                valueBoxOutput("omegaRatioBox", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Advanced Metrics Configuration",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           numericInput("riskFreeRate", "Risk-Free Rate (%):",
                                        value = 4.5, min = 0, max = 10, step = 0.1)
                    ),
                    column(3,
                           numericInput("targetReturn", "Target Return (%):",
                                        value = 0, min = -10, max = 20, step = 0.5)
                    ),
                    column(3,
                           numericInput("rollingWindow", "Rolling Window (days):",
                                        value = 252, min = 30, max = 500, step = 10)
                    ),
                    column(3,
                           checkboxInput("annualizeMetrics", "Annualize Metrics", TRUE)
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk-Adjusted Performance Metrics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(DT::dataTableOutput("advancedMetricsTable"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Rolling Sharpe Ratio",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("rollingSharpeChart", height = "400px"))
                ),
                box(
                  title = "Rolling Sortino Ratio",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("rollingSortinoChart", height = "400px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Downside Risk Analysis",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("downsideRiskChart", height = "350px"))
                ),
                box(
                  title = "Upside vs Downside Capture",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("upsideDownsideChart", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Maximum Drawdown Details",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("maxDrawdownDetailChart", height = "350px"))
                ),
                box(
                  title = "Recovery Period Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("recoveryPeriodTable"))
                )
              )
      ),
      
      # Hedging Strategies Tab (NEW)
      tabItem(tabName = "hedging",
              fluidRow(
                box(
                  title = "Hedging Strategy Configuration",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  
                  selectInput("hedgeAsset", "Hedge Against:",
                              choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                          "Ethereum (ETH-USD)" = "ETH-USD",
                                          "Gold (GC=F)" = "GC=F",
                                          "Crude Oil (CL=F)" = "CL=F",
                                          "S&P 500 (^GSPC)" = "^GSPC"),
                              selected = "^GSPC"),
                  
                  numericInput("hedgeRatio", "Initial Hedge Ratio:",
                               value = 1.0, min = 0.1, max = 2.0, step = 0.1),
                  
                  numericInput("rebalanceFreq", "Rebalance Frequency (days):",
                               value = 30, min = 1, max = 90, step = 1),
                  
                  radioButtons("hedgeMethod", "Hedge Method:",
                               choices = c("Static Hedge" = "static",
                                           "Dynamic (Correlation-based)" = "dynamic",
                                           "Beta-Adjusted" = "beta",
                                           "Minimum Variance" = "minvar"),
                               selected = "dynamic"),
                  
                  numericInput("hedgeLookback", "Lookback Period (days):",
                               value = 60, min = 20, max = 250, step = 10),
                  
                  actionButton("runHedgeAnalysis", "Run Hedge Analysis", 
                               class = "btn-primary", width = "100%")
                ),
                
                box(
                  title = "Hedging Effectiveness Summary",
                  status = "info",
                  solidHeader = TRUE,
                  width = 8,
                  
                  fluidRow(
                    column(6,
                           h5("Without Hedge:"),
                           verbatimTextOutput("unhedgedStats")
                    ),
                    column(6,
                           h5("With Hedge:"),
                           verbatimTextOutput("hedgedStats")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Portfolio Performance: Hedged vs Unhedged",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(plotlyOutput("hedgePerformanceChart", height = "500px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Rolling Hedge Ratio",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("hedgeRatioChart", height = "350px"))
                ),
                box(
                  title = "Rolling Correlation",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("hedgeCorrelationChart", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Hedge Effectiveness Metrics",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(DT::dataTableOutput("hedgeEffectivenessTable"))
                ),
                box(
                  title = "Beta Analysis",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("betaAnalysisChart", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Cost-Benefit Analysis",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  withSpinner(DT::dataTableOutput("hedgeCostBenefitTable"))
                )
              )
      ),
      
      # Composite Analysis Tab
      tabItem(tabName = "composite",
              fluidRow(
                box(
                  title = "Composite Analysis Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           h5("Compare Multiple Assets:"),
                           checkboxGroupInput("compositeAssets", "Select Assets to Compare:",
                                              choices = c("Bitcoin (BTC-USD)" = "BTC-USD",
                                                          "Ethereum (ETH-USD)" = "ETH-USD",
                                                          "Cardano (ADA-USD)" = "ADA-USD",
                                                          "NVIDIA (NVDA)" = "NVDA",
                                                          "Microsoft (MSFT)" = "MSFT",
                                                          "Apple (AAPL)" = "AAPL",
                                                          "Gold (GC=F)" = "GC=F",
                                                          "Crude Oil (CL=F)" = "CL=F",
                                                          "Natural Gas (NG=F)" = "NG=F"),
                                              selected = c("BTC-USD", "NVDA", "GC=F"))
                    ),
                    column(4,
                           h5("Analysis Period:"),
                           dateRangeInput("compositeRange", NULL,
                                          start = Sys.Date() - months(12),
                                          end = Sys.Date())
                    ),
                    column(4,
                           h5("Normalization:"),
                           radioButtons("normalizeMethod", NULL,
                                        choices = c("Index (Base 100)" = "index",
                                                    "Percentage Returns" = "returns",
                                                    "Raw Prices" = "raw"),
                                        selected = "index"),
                           actionButton("runComposite", "Run Analysis", 
                                        class = "btn-primary", width = "100%")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Comparative Performance Chart", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  withSpinner(plotlyOutput("compositePerformance", height = "500px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Correlation Heatmap", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotOutput("compositeCorrelation", height = "400px"))
                ),
                box(
                  title = "Risk-Return Scatter", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("riskReturnScatter", height = "400px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Performance Metrics Comparison", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(DT::dataTableOutput("compositeMetrics"))
                ),
                box(
                  title = "Rolling Correlations", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  withSpinner(plotlyOutput("rollingCorrelations", height = "350px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Asset Class Comparison", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           h5("Crypto Average Performance:"),
                           verbatimTextOutput("cryptoSummary")
                    ),
                    column(3,
                           h5("Equity Average Performance:"),
                           verbatimTextOutput("equitySummary")
                    ),
                    column(3,
                           h5("Commodity Average Performance:"),
                           verbatimTextOutput("commoditySummary")
                    ),
                    column(3,
                           h5("Class Comparison:"),
                           verbatimTextOutput("classComparison")
                    )
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    asset_data = NULL,
    data_loaded = FALSE,
    last_update = NULL,
    composite_data = NULL,
    hedge_data = NULL,
    hedge_results = NULL
  )
  
  # Function to fetch data from Yahoo Finance
  fetch_asset_data <- function(symbol, months_back = 24) {
    tryCatch({
      start_date <- Sys.Date() - months(months_back)
      end_date <- Sys.Date()
      
      # Fetch data using quantmod
      data <- getSymbols(symbol, src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE)
      
      # Convert to data frame
      df <- data.frame(
        Date = index(data),
        Open = as.numeric(Op(data)),
        High = as.numeric(Hi(data)),
        Low = as.numeric(Lo(data)),
        Close = as.numeric(Cl(data)),
        Volume = as.numeric(Vo(data)),
        Adjusted = as.numeric(Ad(data))
      )
      
      # Calculate returns
      df <- df %>%
        arrange(Date) %>%
        mutate(
          returns = c(NA, diff(log(Close))),
          returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
        )
      
      return(df)
    }, error = function(e) {
      showNotification(paste("Error fetching data for", symbol, ":", e$message), type = "error")
      return(NULL)
    })
  }
  
  # Get current asset symbol
  current_asset <- reactive({
    if (input$assetClass == "crypto") {
      return(input$cryptoAsset)
    } else if (input$assetClass == "equity") {
      return(input$equityAsset)
    } else {
      return(input$commodityAsset)
    }
  })
  
  # Load data when asset selection changes or refresh is clicked
  observeEvent(c(current_asset(), input$refreshData), {
    showNotification("Fetching data...", type = "message", duration = 2)
    
    symbol <- current_asset()
    data <- fetch_asset_data(symbol)
    
    if (!is.null(data) && nrow(data) > 0) {
      values$asset_data <- data
      values$data_loaded <- TRUE
      values$last_update <- Sys.time()
      
      showNotification(paste("Successfully loaded", nrow(data), "records for", symbol), 
                       type = "message", duration = 3)
    } else {
      values$data_loaded <- FALSE
      showNotification("Failed to load data", type = "error")
    }
  }, ignoreNULL = FALSE)
  
  # Data source info
  output$dataSourceInfo <- renderUI({
    if (!values$data_loaded) {
      return(div("No data loaded. Select an asset to begin."))
    }
    
    asset_name <- if (input$assetClass == "crypto") {
      paste("Cryptocurrency:", current_asset())
    } else if (input$assetClass == "equity") {
      paste("Private Equity:", current_asset())
    } else {
      paste("Commodity:", current_asset())
    }
    
    div(
      h6(asset_name),
      p(paste("Records:", nrow(values$asset_data)), style = "margin: 0; font-size: 12px;"),
      p(paste("Last Updated:", format(values$last_update, "%Y-%m-%d %H:%M")), 
        style = "margin: 0; font-size: 12px;"),
      p(paste("Date Range:", min(values$asset_data$Date), "to", max(values$asset_data$Date)), 
        style = "margin: 0; font-size: 12px;")
    )
  })
  
  # MARKET OVERVIEW OUTPUTS
  
  output$currentPrice <- renderValueBox({
    req(values$asset_data)
    current_price <- tail(values$asset_data$Close, 1)
    
    valueBox(
      value = paste0("$", format(round(current_price, 2), big.mark = ",", nsmall = 2)),
      subtitle = paste("Current Price -", current_asset()),
      icon = icon("dollar-sign"),
      color = "blue"
    )
  })
  
  output$dailyChange <- renderValueBox({
    req(values$asset_data)
    data <- values$asset_data
    
    if (nrow(data) >= 2) {
      recent <- tail(data, 2)
      change <- (recent$Close[2] - recent$Close[1]) / recent$Close[1] * 100
      color <- ifelse(change > 0, "green", "red")
      icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
    } else {
      change <- 0
      color <- "yellow"
      icon_name <- "minus"
    }
    
    valueBox(
      value = paste0(ifelse(change > 0, "+", ""), format(round(change, 2), nsmall = 2), "%"),
      subtitle = "Daily Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  output$volumeInfo <- renderValueBox({
    req(values$asset_data)
    avg_volume <- mean(values$asset_data$Volume, na.rm = TRUE)
    
    valueBox(
      value = format(round(avg_volume, 0), big.mark = ","),
      subtitle = "Average Daily Volume",
      icon = icon("chart-bar"),
      color = "yellow"
    )
  })
  
  output$dataRange <- renderValueBox({
    req(values$asset_data)
    data <- values$asset_data
    days <- as.numeric(max(data$Date) - min(data$Date))
    
    valueBox(
      value = paste(nrow(data), "days"),
      subtitle = paste(days, "days of data"),
      icon = icon("calendar"),
      color = "purple"
    )
  })
  
  output$overviewChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    p <- plot_ly()
    
    # Add close price
    if ("close" %in% input$overviewComponents) {
      p <- p %>% add_lines(data = data, x = ~Date, y = ~Close, name = "Close Price",
                           line = list(color = "#2c3e50", width = 2))
    }
    
    # Add moving average
    if ("ma" %in% input$overviewComponents && nrow(data) >= input$overviewMA) {
      ma <- SMA(data$Close, n = input$overviewMA)
      p <- p %>% add_lines(data = data, x = ~Date, y = ma, 
                           name = paste("MA(", input$overviewMA, ")"),
                           line = list(color = "#e74c3c", width = 2, dash = "dash"))
    }
    
    # Add volume
    if ("volume" %in% input$overviewComponents) {
      p <- p %>% add_bars(data = data, x = ~Date, y = ~Volume, name = "Volume",
                          yaxis = "y2", marker = list(color = "#95a5a6", opacity = 0.3))
    }
    
    p <- p %>% layout(
      title = paste(current_asset(), "- Price & Volume"),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price (USD)", side = "left"),
      yaxis2 = list(title = "Volume", overlaying = "y", side = "right"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    p
  })
  
  output$marketStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data
    
    stats <- data.frame(
      Metric = c("Current", "Mean", "Median", "Min", "Max", "Range", "Std Dev"),
      Value = c(
        format(round(tail(data$Close, 1), 2), big.mark = ","),
        format(round(mean(data$Close), 2), big.mark = ","),
        format(round(median(data$Close), 2), big.mark = ","),
        format(round(min(data$Close), 2), big.mark = ","),
        format(round(max(data$Close), 2), big.mark = ","),
        format(round(max(data$Close) - min(data$Close), 2), big.mark = ","),
        format(round(sd(data$Close), 2), big.mark = ",")
      )
    )
    
    datatable(stats, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  output$priceMovementStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    
    stats <- data.frame(
      Metric = c("Valid Returns", "Mean Return (%)", "Volatility (%)", 
                 "Max Gain (%)", "Max Loss (%)", "Annualized Vol (%)"),
      Value = c(
        length(returns),
        round(mean(returns) * 100, 4),
        round(sd(returns) * 100, 4),
        round(max(returns) * 100, 4),
        round(min(returns) * 100, 4),
        round(sd(returns) * sqrt(252) * 100, 2)
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$volumeStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data
    
    stats <- data.frame(
      Metric = c("Mean Volume", "Median Volume", "Max Volume", "Min Volume", "Std Dev"),
      Value = c(
        format(round(mean(data$Volume)), big.mark = ","),
        format(round(median(data$Volume)), big.mark = ","),
        format(round(max(data$Volume)), big.mark = ","),
        format(round(min(data$Volume)), big.mark = ","),
        format(round(sd(data$Volume)), big.mark = ",")
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$returnsDistribution <- renderPlotly({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)] * 100
    
    plot_ly(x = returns, type = "histogram", nbinsx = 40,
            marker = list(color = "#8e44ad", opacity = 0.7)) %>%
      layout(
        title = "Returns Distribution",
        xaxis = list(title = "Returns (%)"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$priceDistribution <- renderPlotly({
    req(values$asset_data)
    
    plot_ly(x = values$asset_data$Close, type = "histogram", nbinsx = 40,
            marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Price Distribution",
        xaxis = list(title = "Price (USD)"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # PRICE ANALYSIS OUTPUTS
  
  output$priceStats <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
    
    if (nrow(data) == 0) return("No data in range")
    
    paste(
      paste("Period:", input$priceRange[1], "to", input$priceRange[2]),
      paste("Records:", nrow(data)),
      paste("Current:", round(tail(data$Close, 1), 2)),
      paste("High:", round(max(data$High), 2)),
      paste("Low:", round(min(data$Low), 2)),
      sep = "\n"
    )
  })
  
  output$detailedPriceChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data in selected range"))
    }
    
    p <- plot_ly(data, x = ~Date)
    
    if ("close" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Close, name = "Close", line = list(color = "#2c3e50", width = 2))
    }
    
    if ("highlow" %in% input$priceComponents) {
      p <- p %>% 
        add_lines(y = ~High, name = "High", line = list(color = "#27ae60", width = 1)) %>%
        add_lines(y = ~Low, name = "Low", line = list(color = "#e74c3c", width = 1))
    }
    
    if ("open" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Open, name = "Open", line = list(color = "#95a5a6", width = 1))
    }
    
    # Add MA
    if (nrow(data) >= input$priceMAPeriod) {
      ma <- SMA(data$Close, n = input$priceMAPeriod)
      p <- p %>% add_lines(y = ma, name = paste("MA(", input$priceMAPeriod, ")"),
                           line = list(color = "#9b59b6", width = 2, dash = "dash"))
    }
    
    # Add Bollinger Bands
    if (input$showBollingerBands && nrow(data) >= 20) {
      bb <- BBands(data$Close, n = 20)
      p <- p %>%
        add_lines(y = bb[,"up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dot")) %>%
        add_lines(y = bb[,"dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dot"))
    }
    
    p %>% layout(
      title = paste("Detailed Price Analysis -", current_asset()),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price (USD)"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  output$ohlcChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2]) %>%
      tail(200)
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data in selected range"))
    }
    
    plot_ly(data, x = ~Date, type = "candlestick",
            open = ~Open, high = ~High, low = ~Low, close = ~Close) %>%
      layout(
        title = paste("Candlestick Chart -", current_asset()),
        xaxis = list(title = "Date", rangeslider = list(visible = FALSE)),
        yaxis = list(title = "Price (USD)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$ohlcStats <- renderDT({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(datatable(data.frame(Message = "No data")))
    }
    
    stats <- data.frame(
      Metric = c("Avg Open", "Avg High", "Avg Low", "Avg Close", 
                 "Avg Range", "Max Range", "Bullish Days", "Bearish Days"),
      Value = c(
        round(mean(data$Open), 2),
        round(mean(data$High), 2),
        round(mean(data$Low), 2),
        round(mean(data$Close), 2),
        round(mean(data$High - data$Low), 2),
        round(max(data$High - data$Low), 2),
        paste0(round(sum(data$Close > data$Open) / nrow(data) * 100, 1), "%"),
        paste0(round(sum(data$Close < data$Open) / nrow(data) * 100, 1), "%")
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$returnsTimeSeries <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    plot_ly(data, x = ~Date, y = ~returns * 100, type = "scatter", mode = "lines",
            line = list(color = "#8e44ad", width = 1)) %>%
      layout(
        title = "Returns Time Series",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Returns (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$cumulativeReturns <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>%
      filter(Date >= input$priceRange[1] & Date <= input$priceRange[2], !is.na(returns))
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    data$cumulative_returns <- cumprod(1 + data$returns) - 1
    
    plot_ly(data, x = ~Date, y = ~cumulative_returns * 100, type = "scatter", mode = "lines",
            line = list(color = "#27ae60", width = 2)) %>%
      layout(
        title = "Cumulative Returns",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # TECHNICAL INDICATORS OUTPUTS
  
  output$technicalSignals <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    signals <- c()
    
    # RSI
    if ("rsi" %in% input$technicalIndicators && nrow(data) >= input$rsiLength) {
      rsi_values <- RSI(data$Close, n = input$rsiLength)
      rsi <- tail(rsi_values[!is.na(rsi_values)], 1)
      if (length(rsi) > 0) {
        if (rsi > 70) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Overbought"))
        else if (rsi < 30) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Oversold"))
        else signals <- c(signals, paste("RSI:", round(rsi, 2), "- Neutral"))
      }
    }
    
    # Price vs SMA
    if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
      sma <- tail(SMA(data$Close, n = input$smaLength), 1)
      current <- tail(data$Close, 1)
      if (!is.na(sma)) {
        pct <- (current - sma) / sma * 100
        signals <- c(signals, paste("Price vs SMA:", ifelse(current > sma, "Above", "Below"), 
                                    paste0("(", round(pct, 2), "%)")))
      }
    }
    
    paste(if (length(signals) > 0) signals else "Select indicators to see signals", collapse = "\n")
  })
  
  output$technicalChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500)
    
    p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                 name = "Close", line = list(color = "#2c3e50", width = 2))
    
    if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
      p <- p %>% add_lines(y = SMA(data$Close, n = input$smaLength),
                           name = paste("SMA(", input$smaLength, ")"),
                           line = list(color = "#e74c3c", width = 2))
    }
    
    if ("ema" %in% input$technicalIndicators && nrow(data) >= input$emaLength) {
      p <- p %>% add_lines(y = EMA(data$Close, n = input$emaLength),
                           name = paste("EMA(", input$emaLength, ")"),
                           line = list(color = "#27ae60", width = 2))
    }
    
    if ("bb" %in% input$technicalIndicators && nrow(data) >= input$bbLength) {
      bb <- BBands(data$Close, n = input$bbLength, sd = input$bbSd)
      p <- p %>%
        add_lines(y = bb[,"up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = bb[,"dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dash"))
    }
    
    p %>% layout(
      title = paste("Technical Analysis -", current_asset()),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Price (USD)"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  output$rsiChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    if (nrow(data) < input$rsiLength) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rsi_values <- RSI(data$Close, n = input$rsiLength)
    plot_data <- data[!is.na(rsi_values),]
    rsi_values <- rsi_values[!is.na(rsi_values)]
    
    plot_ly(plot_data, x = ~Date, y = rsi_values, type = "scatter", mode = "lines",
            line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = paste("RSI(", input$rsiLength, ")"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "RSI", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 70, y1 = 70, line = list(color = "#e74c3c", dash = "dash")),
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 30, y1 = 30, line = list(color = "#27ae60", dash = "dash"))
        )
      )
  })
  
  output$macdChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    if (nrow(data) < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    macd <- MACD(data$Close, nFast = 12, nSlow = 26, nSig = 9)
    plot_data <- data.frame(
      Date = data$Date,
      macd = macd[,"macd"],
      signal = macd[,"signal"]
    ) %>% filter(complete.cases(.))
    
    plot_data$histogram <- plot_data$macd - plot_data$signal
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1)) %>%
      add_bars(y = ~histogram, name = "Histogram",
               marker = list(color = ifelse(plot_data$histogram > 0, "#27ae60", "#e74c3c"))) %>%
      layout(
        title = "MACD",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Value"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$stochChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(200)
    
    if (nrow(data) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    k_period <- 14
    d_period <- 3
    
    rolling_low <- rollapply(data$Low, width = k_period, FUN = min, align = "right", fill = NA)
    rolling_high <- rollapply(data$High, width = k_period, FUN = max, align = "right", fill = NA)
    
    stoch_k <- ifelse(rolling_high - rolling_low != 0,
                      (data$Close - rolling_low) / (rolling_high - rolling_low) * 100, 50)
    stoch_d <- SMA(stoch_k, n = d_period)
    
    plot_data <- data.frame(Date = data$Date, stoch_k = stoch_k, stoch_d = stoch_d) %>%
      filter(complete.cases(.))
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~stoch_k, name = "%K", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~stoch_d, name = "%D", line = list(color = "#e74c3c", width = 1)) %>%
      layout(
        title = "Stochastic Oscillator",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Stochastic (%)", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 80, y1 = 80, line = list(color = "#e74c3c", dash = "dash")),
          list(type = "line", x0 = min(plot_data$Date), x1 = max(plot_data$Date),
               y0 = 20, y1 = 20, line = list(color = "#27ae60", dash = "dash"))
        )
      )
  })
  
  # VOLATILITY ANALYSIS OUTPUTS
  
  output$volatilityMetrics <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500)
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < input$volWindow) return("Insufficient data")
    
    current_vol <- sd(tail(returns, input$volWindow))
    if (input$annualizeVol) current_vol <- current_vol * sqrt(252)
    
    all_vol <- sd(returns)
    if (input$annualizeVol) all_vol <- all_vol * sqrt(252)
    
    vol_unit <- ifelse(input$annualizeVol, "% (ann.)", "% (daily)")
    
    paste(
      paste("Current Volatility:", round(current_vol * 100, 3), vol_unit),
      paste("Historical Avg:", round(all_vol * 100, 3), vol_unit),
      paste("Data Points:", length(returns)),
      sep = "\n"
    )
  })
  
  output$volatilityChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(1000)
    
    returns <- data$returns
    
    if (sum(!is.na(returns)) < input$volWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
    if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
    
    vol_mean <- mean(rolling_vol, na.rm = TRUE)
    vol_sd <- sd(rolling_vol, na.rm = TRUE)
    confidence_mult <- qnorm((100 + input$volConfidence) / 200)
    
    plot_data <- data.frame(
      Date = data$Date,
      vol = rolling_vol,
      upper = vol_mean + confidence_mult * vol_sd,
      lower = pmax(0, vol_mean - confidence_mult * vol_sd)
    ) %>% filter(!is.na(vol))
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~vol * 100, name = "Volatility", line = list(color = "#2c3e50", width = 2)) %>%
      add_lines(y = ~upper * 100, name = "Upper Band", line = list(color = "#e74c3c", dash = "dash")) %>%
      add_lines(y = ~lower * 100, name = "Lower Band", line = list(color = "#27ae60", dash = "dash")) %>%
      layout(
        title = paste("Volatility Analysis -", current_asset()),
        xaxis = list(title = "Date"),
        yaxis = list(title = ifelse(input$annualizeVol, "Ann. Volatility (%)", "Daily Vol (%)")),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$volatilityDist <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
    if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
    
    vol_data <- rolling_vol[!is.na(rolling_vol)]
    
    if (length(vol_data) < 20) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    plot_ly(x = vol_data * 100, type = "histogram", nbinsx = 30,
            marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Volatility Distribution",
        xaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$volatilityClustering <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500) %>% filter(!is.na(returns))
    
    if (nrow(data) < 20) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    data$abs_returns <- abs(data$returns) * 100
    
    plot_ly(data, x = ~Date, y = ~abs_returns, type = "scatter", mode = "lines",
            line = list(color = "#e74c3c", width = 1.5)) %>%
      layout(
        title = "Volatility Clustering",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Absolute Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$volatilityRegimes <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
    if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
    
    vol_25 <- quantile(rolling_vol, 0.25, na.rm = TRUE)
    vol_75 <- quantile(rolling_vol, 0.75, na.rm = TRUE)
    
    regime_data <- data.frame(
      Date = tail(data$Date, length(rolling_vol)),
      vol = rolling_vol,
      regime = ifelse(rolling_vol <= vol_25, "Low",
                      ifelse(rolling_vol >= vol_75, "High", "Normal"))
    ) %>% filter(!is.na(vol))
    
    colors <- c("Low" = "#27ae60", "Normal" = "#3498db", "High" = "#e74c3c")
    
    plot_ly(regime_data, x = ~Date, y = ~vol * 100, color = ~regime, colors = colors,
            type = "scatter", mode = "markers") %>%
      layout(
        title = "Volatility Regimes",
        xaxis = list(title = "Date"),
        yaxis = list(title = ifelse(input$annualizeVol, "Ann. Vol (%)", "Daily Vol (%)")),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # RISK METRICS OUTPUTS
  
  output$riskMetrics <- renderText({
    req(values$asset_data)
    data <- values$asset_data %>% tail(input$varWindow)
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) return("Insufficient data")
    
    adjusted_returns <- returns * sqrt(input$timeHorizon)
    var_percentile <- (100 - input$confidenceLevel) / 100
    
    if (input$varMethod == "historical") {
      var_value <- quantile(adjusted_returns, var_percentile)
    } else {
      mean_ret <- mean(adjusted_returns)
      sd_ret <- sd(adjusted_returns)
      var_value <- mean_ret + qnorm(var_percentile) * sd_ret
    }
    
    var_dollar <- abs(var_value) * input$portfolioValue
    
    sharpe <- mean(returns) / sd(returns) * sqrt(252)
    
    paste(
      paste("Portfolio:", paste0("$", format(input$portfolioValue, big.mark = ","))),
      paste("Time Horizon:", input$timeHorizon, "day(s)"),
      "",
      paste("VaR:", paste0("$", format(round(var_dollar, 0), big.mark = ","))),
      paste("VaR %:", paste0(round(var_dollar / input$portfolioValue * 100, 3), "%")),
      paste("Sharpe Ratio:", round(sharpe, 3)),
      sep = "\n"
    )
  })
  
  output$varChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(min(1000, nrow(values$asset_data)))
    
    returns <- data$returns
    var_percentile <- (100 - input$confidenceLevel) / 100
    window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
    
    if (window_size < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_var <- rollapply(returns, window_size,
                             function(x) quantile(x * sqrt(input$timeHorizon), var_percentile, na.rm = TRUE),
                             fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_var)),
      var_value = abs(rolling_var) * input$portfolioValue,
      daily_pnl = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) * input$portfolioValue
    ) %>% filter(!is.na(var_value))
    
    plot_ly(plot_data, x = ~Date) %>%
      add_lines(y = ~var_value, name = "VaR", line = list(color = "#e74c3c", width = 2)) %>%
      add_bars(y = ~daily_pnl, name = "Daily P&L", marker = list(color = "#3498db")) %>%
      layout(
        title = "Value at Risk",
        xaxis = list(title = "Date"),
        yaxis = list(title = "USD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$expectedShortfall <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(800)
    
    returns <- data$returns
    var_percentile <- (100 - input$confidenceLevel) / 100
    window_size <- min(input$varWindow, sum(!is.na(returns)) - 50)
    
    if (window_size < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_es <- rollapply(returns, window_size,
                            function(x) {
                              adj_ret <- x * sqrt(input$timeHorizon)
                              var_threshold <- quantile(adj_ret, var_percentile, na.rm = TRUE)
                              mean(adj_ret[adj_ret <= var_threshold], na.rm = TRUE)
                            },
                            fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_es)),
      es_value = abs(rolling_es) * input$portfolioValue
    ) %>% filter(!is.na(es_value))
    
    plot_ly(plot_data, x = ~Date, y = ~es_value, type = "scatter", mode = "lines",
            line = list(color = "#8e44ad", width = 2)) %>%
      layout(
        title = "Expected Shortfall",
        xaxis = list(title = "Date"),
        yaxis = list(title = "USD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$drawdownAnalysis <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data
    
    returns <- data$returns[!is.na(data$returns)]
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max * 100
    
    dd_data <- data.frame(
      Date = tail(data$Date, length(drawdown)),
      drawdown = drawdown
    )
    
    plot_ly(dd_data, x = ~Date, y = ~drawdown, type = "scatter", mode = "lines",
            fill = "tonexty", fillcolor = "rgba(214, 39, 40, 0.3)",
            line = list(color = "#d62728", width = 2)) %>%
      layout(
        title = "Drawdown Analysis",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Drawdown (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$riskStatsTable <- renderDT({
    req(values$asset_data)
    data <- values$asset_data %>% tail(input$varWindow)
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
    }
    
    adj_returns <- returns * sqrt(input$timeHorizon)
    downside_returns <- returns[returns < 0]
    
    stats <- data.frame(
      Metric = c("Mean Return (%)", "Volatility (%)", "Sharpe Ratio", "Sortino Ratio",
                 "Max Loss (%)", "Max Gain (%)"),
      Value = c(
        round(mean(adj_returns) * 100, 4),
        round(sd(adj_returns) * 100, 4),
        round(mean(returns) / sd(returns) * sqrt(252), 3),
        round(mean(returns) / sqrt(mean(pmin(returns, 0)^2)) * sqrt(252), 3),
        round(min(adj_returns) * 100, 4),
        round(max(adj_returns) * 100, 4)
      )
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$stressTestResults <- renderDT({
    req(values$asset_data)
    
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    hist_vol <- sd(returns) * sqrt(input$timeHorizon)
    
    scenarios <- data.frame(
      Scenario = c("2 Sigma Event", "3 Sigma Event", "4 Sigma Event", 
                   "Flash Crash", "Market Crisis"),
      Probability = c("4.5%", "0.3%", "0.006%", "0.01%", "0.1%"),
      Impact_Pct = paste0(round(c(-2, -3, -4, -5, -3.5) * hist_vol * 100, 2), "%"),
      Portfolio_Impact = paste0("-$", format(round(abs(c(-2, -3, -4, -5, -3.5) * hist_vol * input$portfolioValue), 0), big.mark = ","))
    )
    
    datatable(scenarios, options = list(dom = 't'), rownames = FALSE)
  })
  
  # ADVANCED METRICS OUTPUTS (NEW)
  
  # Helper function to calculate Sharpe Ratio
  calculate_sharpe <- function(returns, rf_rate, annualize = TRUE) {
    rf_daily <- rf_rate / 100 / 252
    excess_returns <- returns - rf_daily
    sharpe <- mean(excess_returns, na.rm = TRUE) / sd(excess_returns, na.rm = TRUE)
    if (annualize) sharpe <- sharpe * sqrt(252)
    return(sharpe)
  }
  
  # Helper function to calculate Sortino Ratio
  calculate_sortino <- function(returns, target_return, annualize = TRUE) {
    target_daily <- target_return / 100 / 252
    excess_returns <- returns - target_daily
    downside_returns <- pmin(excess_returns, 0)
    downside_dev <- sqrt(mean(downside_returns^2, na.rm = TRUE))
    if (downside_dev == 0) return(NA)
    sortino <- mean(excess_returns, na.rm = TRUE) / downside_dev
    if (annualize) sortino <- sortino * sqrt(252)
    return(sortino)
  }
  
  # Helper function to calculate Calmar Ratio
  calculate_calmar <- function(returns, annualize = TRUE) {
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max
    max_dd <- min(drawdown, na.rm = TRUE)
    if (max_dd == 0) return(NA)
    
    ann_return <- mean(returns, na.rm = TRUE) * 252
    calmar <- ann_return / abs(max_dd)
    return(calmar)
  }
  
  # Helper function to calculate Omega Ratio
  calculate_omega <- function(returns, threshold = 0) {
    threshold_daily <- threshold / 252
    gains <- sum(pmax(returns - threshold_daily, 0), na.rm = TRUE)
    losses <- sum(abs(pmin(returns - threshold_daily, 0)), na.rm = TRUE)
    if (losses == 0) return(Inf)
    return(gains / losses)
  }
  
  output$sharpeRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      sharpe <- NA
    } else {
      sharpe <- calculate_sharpe(returns, input$riskFreeRate, input$annualizeMetrics)
    }
    
    valueBox(
      value = ifelse(is.na(sharpe), "N/A", round(sharpe, 3)),
      subtitle = "Sharpe Ratio",
      icon = icon("chart-line"),
      color = "blue"
    )
  })
  
  output$sortinoRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      sortino <- NA
    } else {
      sortino <- calculate_sortino(returns, input$targetReturn, input$annualizeMetrics)
    }
    
    valueBox(
      value = ifelse(is.na(sortino), "N/A", round(sortino, 3)),
      subtitle = "Sortino Ratio",
      icon = icon("arrow-trend-down"),
      color = "green"
    )
  })
  
  output$calmarRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      calmar <- NA
    } else {
      calmar <- calculate_calmar(returns, input$annualizeMetrics)
    }
    
    valueBox(
      value = ifelse(is.na(calmar), "N/A", round(calmar, 3)),
      subtitle = "Calmar Ratio",
      icon = icon("shield-halved"),
      color = "teal"
    )
  })
  
  output$omegaRatioBox <- renderValueBox({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      omega <- NA
    } else {
      omega <- calculate_omega(returns, input$targetReturn)
    }
    
    valueBox(
      value = ifelse(is.na(omega) || is.infinite(omega), "N/A", round(omega, 3)),
      subtitle = "Omega Ratio",
      icon = icon("circle-notch"),
      color = "orange"
    )
  })
  
  output$advancedMetricsTable <- renderDT({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
    }
    
    # Calculate all metrics
    sharpe <- calculate_sharpe(returns, input$riskFreeRate, input$annualizeMetrics)
    sortino <- calculate_sortino(returns, input$targetReturn, input$annualizeMetrics)
    calmar <- calculate_calmar(returns)
    omega <- calculate_omega(returns, input$targetReturn)
    
    # Downside deviation
    downside_returns <- pmin(returns - input$targetReturn/100/252, 0)
    downside_dev <- sqrt(mean(downside_returns^2, na.rm = TRUE)) * sqrt(252) * 100
    
    # Upside potential ratio
    upside_returns <- pmax(returns - input$targetReturn/100/252, 0)
    upside_pot <- mean(upside_returns, na.rm = TRUE) / sqrt(mean(downside_returns^2, na.rm = TRUE))
    
    # Max drawdown
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max
    max_dd <- min(drawdown, na.rm = TRUE) * 100
    
    metrics <- data.frame(
      Metric = c("Sharpe Ratio", "Sortino Ratio", "Calmar Ratio", "Omega Ratio",
                 "Downside Deviation (%)", "Upside Potential Ratio", "Max Drawdown (%)",
                 "Annualized Return (%)", "Annualized Volatility (%)"),
      Value = c(
        ifelse(is.na(sharpe), "N/A", round(sharpe, 3)),
        ifelse(is.na(sortino), "N/A", round(sortino, 3)),
        ifelse(is.na(calmar), "N/A", round(calmar, 3)),
        ifelse(is.na(omega) || is.infinite(omega), "N/A", round(omega, 3)),
        round(downside_dev, 2),
        ifelse(is.na(upside_pot) || is.infinite(upside_pot), "N/A", round(upside_pot, 3)),
        round(max_dd, 2),
        round(mean(returns, na.rm = TRUE) * 252 * 100, 2),
        round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 2)
      )
    )
    
    datatable(metrics, options = list(dom = 't', pageLength = 20), rownames = FALSE)
  })
  
  output$rollingSharpeChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(1000)
    returns <- data$returns
    
    if (sum(!is.na(returns)) < input$rollingWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rf_daily <- input$riskFreeRate / 100 / 252
    rolling_sharpe <- rollapply(returns, input$rollingWindow,
                                function(x) {
                                  excess <- x - rf_daily
                                  sharpe <- mean(excess, na.rm = TRUE) / sd(excess, na.rm = TRUE)
                                  if (input$annualizeMetrics) sharpe <- sharpe * sqrt(252)
                                  return(sharpe)
                                },
                                fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_sharpe)),
      sharpe = rolling_sharpe
    ) %>% filter(!is.na(sharpe))
    
    plot_ly(plot_data, x = ~Date, y = ~sharpe, type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        title = paste("Rolling Sharpe Ratio (", input$rollingWindow, " days)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Sharpe Ratio"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$rollingSortinoChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(1000)
    returns <- data$returns
    
    if (sum(!is.na(returns)) < input$rollingWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    target_daily <- input$targetReturn / 100 / 252
    rolling_sortino <- rollapply(returns, input$rollingWindow,
                                 function(x) {
                                   excess <- x - target_daily
                                   downside <- pmin(excess, 0)
                                   downside_dev <- sqrt(mean(downside^2, na.rm = TRUE))
                                   if (downside_dev == 0) return(NA)
                                   sortino <- mean(excess, na.rm = TRUE) / downside_dev
                                   if (input$annualizeMetrics) sortino <- sortino * sqrt(252)
                                   return(sortino)
                                 },
                                 fill = NA, align = "right")
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(rolling_sortino)),
      sortino = rolling_sortino
    ) %>% filter(!is.na(sortino))
    
    plot_ly(plot_data, x = ~Date, y = ~sortino, type = "scatter", mode = "lines",
            line = list(color = "#27ae60", width = 2)) %>%
      layout(
        title = paste("Rolling Sortino Ratio (", input$rollingWindow, " days)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Sortino Ratio"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$downsideRiskChart <- renderPlotly({
    req(values$asset_data)
    data <- values$asset_data %>% tail(500)
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    target_daily <- input$targetReturn / 100 / 252
    downside_returns <- pmin(returns - target_daily, 0) * 100
    
    plot_data <- data.frame(
      Date = tail(data$Date, length(downside_returns)),
      downside = downside_returns
    )
    
    plot_ly(plot_data, x = ~Date, y = ~downside, type = "scatter", mode = "lines",
            fill = "tozeroy", fillcolor = "rgba(231, 76, 60, 0.3)",
            line = list(color = "#e74c3c", width = 1.5)) %>%
      layout(
        title = "Downside Risk (Below Target)",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Downside Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$upsideDownsideChart <- renderPlotly({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    target_daily <- input$targetReturn / 100 / 252
    upside <- mean(pmax(returns - target_daily, 0), na.rm = TRUE) * 252 * 100
    downside <- abs(mean(pmin(returns - target_daily, 0), na.rm = TRUE)) * 252 * 100
    
    plot_data <- data.frame(
      Type = c("Upside Capture", "Downside Capture"),
      Value = c(upside, downside),
      Color = c("#27ae60", "#e74c3c")
    )
    
    plot_ly(plot_data, x = ~Type, y = ~Value, type = "bar",
            marker = list(color = ~Color)) %>%
      layout(
        title = "Upside vs Downside Capture",
        xaxis = list(title = ""),
        yaxis = list(title = "Annualized (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = FALSE
      )
  })
  
  output$maxDrawdownDetailChart <- renderPlotly({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    
    if (length(returns) < 30) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max * 100
    
    dd_data <- data.frame(
      Date = tail(values$asset_data$Date, length(drawdown)),
      drawdown = drawdown,
      cumulative = (cumulative - 1) * 100
    )
    
    plot_ly(dd_data, x = ~Date) %>%
      add_lines(y = ~cumulative, name = "Cumulative Return", 
                line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~drawdown, name = "Drawdown", 
                line = list(color = "#e74c3c", width = 2)) %>%
      layout(
        title = "Drawdown from Peak",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Percentage (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$recoveryPeriodTable <- renderDT({
    req(values$asset_data)
    returns <- values$asset_data$returns[!is.na(values$asset_data$returns)]
    dates <- tail(values$asset_data$Date, length(returns))
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
    }
    
    cumulative <- cumprod(1 + returns)
    running_max <- cummax(cumulative)
    drawdown <- (cumulative - running_max) / running_max
    
    # Find max drawdown
    max_dd_idx <- which.min(drawdown)
    max_dd_value <- drawdown[max_dd_idx] * 100
    max_dd_date <- dates[max_dd_idx]
    
    # Find recovery
    if (max_dd_idx < length(drawdown)) {
      recovery_idx <- which(drawdown[(max_dd_idx + 1):length(drawdown)] >= 0)[1]
      if (!is.na(recovery_idx)) {
        recovery_date <- dates[max_dd_idx + recovery_idx]
        recovery_days <- as.numeric(recovery_date - max_dd_date)
      } else {
        recovery_date <- "Not recovered"
        recovery_days <- NA
      }
    } else {
      recovery_date <- "Not recovered"
      recovery_days <- NA
    }
    
    recovery_data <- data.frame(
      Metric = c("Max Drawdown (%)", "Drawdown Date", "Recovery Date", "Recovery Period (days)",
                 "Current Drawdown (%)", "Days Since Peak"),
      Value = c(
        round(max_dd_value, 2),
        as.character(max_dd_date),
        as.character(recovery_date),
        ifelse(is.na(recovery_days), "N/A", recovery_days),
        round(tail(drawdown, 1) * 100, 2),
        as.numeric(tail(dates, 1) - dates[which.max(cumulative)])
      )
    )
    
    datatable(recovery_data, options = list(dom = 't'), rownames = FALSE)
  })
  
  # HEDGING STRATEGIES OUTPUTS (NEW)
  
  observeEvent(input$runHedgeAnalysis, {
    showNotification("Running hedge analysis...", type = "message", duration = 3)
    
    # Fetch hedge asset data
    hedge_data <- fetch_asset_data(input$hedgeAsset)
    
    if (is.null(hedge_data) || is.null(values$asset_data)) {
      showNotification("Failed to load hedge or asset data", type = "error")
      return()
    }
    
    # Align dates
    asset_data <- values$asset_data %>%
      filter(Date >= min(hedge_data$Date) & Date <= max(hedge_data$Date)) %>%
      select(Date, Close, returns) %>%
      filter(!is.na(returns))
    
    hedge_data <- hedge_data %>%
      filter(Date %in% asset_data$Date) %>%
      select(Date, Close, returns) %>%
      filter(!is.na(returns))
    
    # Merge data
    combined <- inner_join(
      asset_data %>% rename(asset_close = Close, asset_return = returns),
      hedge_data %>% rename(hedge_close = Close, hedge_return = returns),
      by = "Date"
    )
    
    if (nrow(combined) < 60) {
      showNotification("Insufficient overlapping data", type = "warning")
      return()
    }
    
    # Calculate hedge ratios based on method
    if (input$hedgeMethod == "static") {
      combined$hedge_ratio <- input$hedgeRatio
      
    } else if (input$hedgeMethod == "dynamic") {
      # Rolling correlation-based hedge
      combined$hedge_ratio <- rollapply(
        combined[, c("asset_return", "hedge_return")],
        width = input$hedgeLookback,
        FUN = function(x) {
          cor_val <- cor(x[,1], x[,2], use = "complete.obs")
          vol_ratio <- sd(x[,1], na.rm = TRUE) / sd(x[,2], na.rm = TRUE)
          return(cor_val * vol_ratio * input$hedgeRatio)
        },
        fill = NA,
        align = "right",
        by.column = FALSE
      )
      
    } else if (input$hedgeMethod == "beta") {
      # Beta-adjusted hedge
      combined$hedge_ratio <- rollapply(
        combined[, c("asset_return", "hedge_return")],
        width = input$hedgeLookback,
        FUN = function(x) {
          if (var(x[,2], na.rm = TRUE) == 0) return(input$hedgeRatio)
          beta <- cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE)
          return(beta * input$hedgeRatio)
        },
        fill = NA,
        align = "right",
        by.column = FALSE
      )
      
    } else if (input$hedgeMethod == "minvar") {
      # Minimum variance hedge
      combined$hedge_ratio <- rollapply(
        combined[, c("asset_return", "hedge_return")],
        width = input$hedgeLookback,
        FUN = function(x) {
          if (var(x[,2], na.rm = TRUE) == 0) return(input$hedgeRatio)
          h <- cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE)
          return(h * input$hedgeRatio)
        },
        fill = NA,
        align = "right",
        by.column = FALSE
      )
    }
    
    # Calculate hedged returns
    combined <- combined %>%
      filter(!is.na(hedge_ratio)) %>%
      mutate(
        hedged_return = asset_return - hedge_ratio * hedge_return,
        unhedged_cumulative = cumprod(1 + asset_return) - 1,
        hedged_cumulative = cumprod(1 + hedged_return) - 1
      )
    
    values$hedge_data <- combined
    
    # Calculate statistics
    unhedged_vol <- sd(combined$asset_return, na.rm = TRUE) * sqrt(252) * 100
    hedged_vol <- sd(combined$hedged_return, na.rm = TRUE) * sqrt(252) * 100
    vol_reduction <- (unhedged_vol - hedged_vol) / unhedged_vol * 100
    
    unhedged_sharpe <- calculate_sharpe(combined$asset_return, input$riskFreeRate, TRUE)
    hedged_sharpe <- calculate_sharpe(combined$hedged_return, input$riskFreeRate, TRUE)
    
    values$hedge_results <- list(
      unhedged_vol = unhedged_vol,
      hedged_vol = hedged_vol,
      vol_reduction = vol_reduction,
      unhedged_sharpe = unhedged_sharpe,
      hedged_sharpe = hedged_sharpe
    )
    
    showNotification("Hedge analysis complete", type = "message", duration = 3)
  })
  
  output$unhedgedStats <- renderText({
    req(values$hedge_results)
    
    paste(
      paste("Volatility:", round(values$hedge_results$unhedged_vol, 2), "%"),
      paste("Sharpe Ratio:", round(values$hedge_results$unhedged_sharpe, 3)),
      paste("Strategy: No hedge"),
      sep = "\n"
    )
  })
  
  output$hedgedStats <- renderText({
    req(values$hedge_results)
    
    paste(
      paste("Volatility:", round(values$hedge_results$hedged_vol, 2), "%"),
      paste("Sharpe Ratio:", round(values$hedge_results$hedged_sharpe, 3)),
      paste("Vol Reduction:", round(values$hedge_results$vol_reduction, 1), "%"),
      paste("Method:", input$hedgeMethod),
      sep = "\n"
    )
  })
  
  output$hedgePerformanceChart <- renderPlotly({
    req(values$hedge_data)
    
    plot_ly(values$hedge_data, x = ~Date) %>%
      add_lines(y = ~unhedged_cumulative * 100, name = "Unhedged",
                line = list(color = "#e74c3c", width = 2)) %>%
      add_lines(y = ~hedged_cumulative * 100, name = "Hedged",
                line = list(color = "#27ae60", width = 2)) %>%
      layout(
        title = "Hedged vs Unhedged Performance",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Cumulative Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeRatioChart <- renderPlotly({
    req(values$hedge_data)
    
    plot_ly(values$hedge_data, x = ~Date, y = ~hedge_ratio, 
            type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        title = "Rolling Hedge Ratio",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Hedge Ratio"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeCorrelationChart <- renderPlotly({
    req(values$hedge_data)
    
    rolling_corr <- rollapply(
      values$hedge_data[, c("asset_return", "hedge_return")],
      width = input$hedgeLookback,
      FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
      fill = NA,
      align = "right",
      by.column = FALSE
    )
    
    plot_data <- data.frame(
      Date = values$hedge_data$Date,
      correlation = rolling_corr
    ) %>% filter(!is.na(correlation))
    
    plot_ly(plot_data, x = ~Date, y = ~correlation,
            type = "scatter", mode = "lines",
            line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = "Rolling Correlation",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Correlation", range = c(-1, 1)),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeEffectivenessTable <- renderDT({
    req(values$hedge_data, values$hedge_results)
    
    data <- values$hedge_data
    
    # Calculate effectiveness metrics
    unhedged_ret <- mean(data$asset_return, na.rm = TRUE) * 252 * 100
    hedged_ret <- mean(data$hedged_return, na.rm = TRUE) * 252 * 100
    
    # Max drawdown
    unhedged_cum <- cumprod(1 + data$asset_return)
    unhedged_dd <- min((unhedged_cum - cummax(unhedged_cum)) / cummax(unhedged_cum), na.rm = TRUE) * 100
    
    hedged_cum <- cumprod(1 + data$hedged_return)
    hedged_dd <- min((hedged_cum - cummax(hedged_cum)) / cummax(hedged_cum), na.rm = TRUE) * 100
    
    # Hedge effectiveness ratio
    hedge_eff <- (values$hedge_results$unhedged_vol - values$hedge_results$hedged_vol) / 
      values$hedge_results$unhedged_vol * 100
    
    metrics <- data.frame(
      Metric = c("Annualized Return (%)", "Volatility (%)", "Sharpe Ratio", 
                 "Max Drawdown (%)", "Hedge Effectiveness (%)"),
      Unhedged = c(
        round(unhedged_ret, 2),
        round(values$hedge_results$unhedged_vol, 2),
        round(values$hedge_results$unhedged_sharpe, 3),
        round(unhedged_dd, 2),
        "Baseline"
      ),
      Hedged = c(
        round(hedged_ret, 2),
        round(values$hedge_results$hedged_vol, 2),
        round(values$hedge_results$hedged_sharpe, 3),
        round(hedged_dd, 2),
        paste0(round(hedge_eff, 1), "%")
      )
    )
    
    datatable(metrics, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$betaAnalysisChart <- renderPlotly({
    req(values$hedge_data)
    
    rolling_beta <- rollapply(
      values$hedge_data[, c("asset_return", "hedge_return")],
      width = input$hedgeLookback,
      FUN = function(x) {
        if (var(x[,2], na.rm = TRUE) == 0) return(NA)
        cov(x[,1], x[,2], use = "complete.obs") / var(x[,2], na.rm = TRUE)
      },
      fill = NA,
      align = "right",
      by.column = FALSE
    )
    
    plot_data <- data.frame(
      Date = values$hedge_data$Date,
      beta = rolling_beta
    ) %>% filter(!is.na(beta))
    
    plot_ly(plot_data, x = ~Date, y = ~beta,
            type = "scatter", mode = "lines",
            line = list(color = "#e67e22", width = 2)) %>%
      add_lines(y = 1, name = "Beta = 1", 
                line = list(color = "#95a5a6", dash = "dash", width = 1)) %>%
      layout(
        title = "Rolling Beta",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Beta"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$hedgeCostBenefitTable <- renderDT({
    req(values$hedge_data, values$hedge_results)
    
    # Estimate hedging costs (simplified)
    avg_hedge_ratio <- mean(abs(values$hedge_data$hedge_ratio), na.rm = TRUE)
    transaction_cost <- 0.001  # 0.1% per transaction
    rebalance_freq <- input$rebalanceFreq
    
    num_periods <- nrow(values$hedge_data)
    num_rebalances <- floor(num_periods / rebalance_freq)
    total_transaction_cost <- num_rebalances * avg_hedge_ratio * transaction_cost * 100
    
    # Benefits
    vol_reduction_benefit <- values$hedge_results$vol_reduction
    sharpe_improvement <- values$hedge_results$hedged_sharpe - values$hedge_results$unhedged_sharpe
    
    cost_benefit <- data.frame(
      Category = c("Cost", "Cost", "Benefit", "Benefit", "Net"),
      Item = c("Transaction Costs (%)", "Number of Rebalances", 
               "Volatility Reduction (%)", "Sharpe Improvement",
               "Net Benefit Score"),
      Value = c(
        round(total_transaction_cost, 3),
        num_rebalances,
        round(vol_reduction_benefit, 2),
        round(sharpe_improvement, 3),
        round(vol_reduction_benefit - total_transaction_cost, 2)
      )
    )
    
    datatable(cost_benefit, options = list(dom = 't'), rownames = FALSE)
  })
  
  # COMPOSITE ANALYSIS OUTPUTS
  
  observeEvent(input$runComposite, {
    showNotification("Loading composite data...", type = "message", duration = 3)
    
    selected_assets <- input$compositeAssets
    
    if (length(selected_assets) < 2) {
      showNotification("Please select at least 2 assets", type = "warning")
      return()
    }
    
    composite_list <- list()
    
    for (symbol in selected_assets) {
      data <- fetch_asset_data(symbol)
      if (!is.null(data)) {
        data <- data %>%
          filter(Date >= input$compositeRange[1] & Date <= input$compositeRange[2]) %>%
          select(Date, Close, returns) %>%
          mutate(asset = symbol)
        composite_list[[symbol]] <- data
      }
    }
    
    if (length(composite_list) > 0) {
      values$composite_data <- bind_rows(composite_list)
      showNotification(paste("Loaded", length(composite_list), "assets"), type = "message")
    } else {
      showNotification("Failed to load composite data", type = "error")
    }
  })
  
  output$compositePerformance <- renderPlotly({
    req(values$composite_data)
    
    data <- values$composite_data
    
    if (input$normalizeMethod == "index") {
      # Normalize to base 100
      data <- data %>%
        group_by(asset) %>%
        arrange(Date) %>%
        mutate(indexed = Close / first(Close) * 100) %>%
        ungroup()
      
      p <- plot_ly(data, x = ~Date, y = ~indexed, color = ~asset, type = "scatter", mode = "lines")
      y_title <- "Indexed Value (Base 100)"
    } else if (input$normalizeMethod == "returns") {
      # Cumulative returns
      data <- data %>%
        group_by(asset) %>%
        arrange(Date) %>%
        mutate(cum_return = cumprod(1 + ifelse(is.na(returns), 0, returns)) - 1) %>%
        ungroup()
      
      p <- plot_ly(data, x = ~Date, y = ~cum_return * 100, color = ~asset, type = "scatter", mode = "lines")
      y_title <- "Cumulative Return (%)"
    } else {
      # Raw prices
      p <- plot_ly(data, x = ~Date, y = ~Close, color = ~asset, type = "scatter", mode = "lines")
      y_title <- "Price (USD)"
    }
    
    p %>% layout(
      title = "Comparative Performance",
      xaxis = list(title = "Date"),
      yaxis = list(title = y_title),
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  output$compositeCorrelation <- renderPlot({
    req(values$composite_data)
    
    corr_data <- values$composite_data %>%
      filter(!is.na(returns)) %>%
      select(Date, asset, returns) %>%
      pivot_wider(names_from = asset, values_from = returns) %>%
      select(-Date) %>%
      na.omit()
    
    if (ncol(corr_data) < 2) {
      plot.new()
      text(0.5, 0.5, "Insufficient data", cex = 1.5)
      return()
    }
    
    corr_matrix <- cor(corr_data, use = "complete.obs")
    
    corrplot(corr_matrix, method = "color", type = "upper",
             tl.cex = 1.0, tl.col = "#2c3e50",
             addCoef.col = "#2c3e50", number.cex = 1.0,
             col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200),
             title = "Correlation Matrix")
  })
  
  output$riskReturnScatter <- renderPlotly({
    req(values$composite_data)
    
    risk_return <- values$composite_data %>%
      filter(!is.na(returns)) %>%
      group_by(asset) %>%
      summarise(
        mean_return = mean(returns, na.rm = TRUE) * 252 * 100,
        volatility = sd(returns, na.rm = TRUE) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    plot_ly(risk_return, x = ~volatility, y = ~mean_return, text = ~asset,
            type = "scatter", mode = "markers+text",
            marker = list(size = 15, color = "#3498db"),
            textposition = "top center") %>%
      layout(
        title = "Risk-Return Profile",
        xaxis = list(title = "Annualized Volatility (%)"),
        yaxis = list(title = "Annualized Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$compositeMetrics <- renderDT({
    req(values$composite_data)
    
    metrics <- values$composite_data %>%
      filter(!is.na(returns)) %>%
      group_by(asset) %>%
      summarise(
        Total_Return = round((last(Close) / first(Close) - 1) * 100, 2),
        Ann_Return = round(mean(returns) * 252 * 100, 2),
        Ann_Vol = round(sd(returns) * sqrt(252) * 100, 2),
        Sharpe = round(mean(returns) / sd(returns) * sqrt(252), 3),
        Max_DD = round(min((Close / cummax(Close) - 1)) * 100, 2),
        .groups = 'drop'
      )
    
    datatable(metrics, options = list(dom = 't', scrollX = TRUE), rownames = FALSE) %>%
      formatStyle(columns = "Total_Return", 
                  backgroundColor = styleInterval(0, c("#f8d7da", "#d4edda")))
  })
  
  output$rollingCorrelations <- renderPlotly({
    req(values$composite_data)
    
    selected <- input$compositeAssets[1:min(2, length(input$compositeAssets))]
    
    if (length(selected) < 2) {
      return(plot_ly() %>% layout(title = "Select at least 2 assets"))
    }
    
    corr_data <- values$composite_data %>%
      filter(asset %in% selected, !is.na(returns)) %>%
      select(Date, asset, returns) %>%
      pivot_wider(names_from = asset, values_from = returns) %>%
      arrange(Date)
    
    if (nrow(corr_data) < 60) {
      return(plot_ly() %>% layout(title = "Insufficient data"))
    }
    
    rolling_corr <- rollapply(corr_data[, 2:3], width = 60,
                              FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
                              fill = NA, align = "right", by.column = FALSE)
    
    corr_df <- data.frame(
      Date = tail(corr_data$Date, length(rolling_corr)),
      correlation = rolling_corr
    ) %>% filter(!is.na(correlation))
    
    plot_ly(corr_df, x = ~Date, y = ~correlation, type = "scatter", mode = "lines",
            line = list(color = "#3498db", width = 2)) %>%
      layout(
        title = paste("Rolling Correlation:", paste(selected, collapse = " vs ")),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Correlation", range = c(-1, 1)),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  output$cryptoSummary <- renderText({
    req(values$composite_data)
    
    crypto_assets <- c("BTC-USD", "ETH-USD", "ADA-USD")
    crypto_data <- values$composite_data %>%
      filter(asset %in% crypto_assets, !is.na(returns))
    
    if (nrow(crypto_data) == 0) return("No crypto data")
    
    summary <- crypto_data %>%
      group_by(asset) %>%
      summarise(
        ret = mean(returns) * 252 * 100,
        vol = sd(returns) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    paste(
      "Cryptocurrency Class:",
      paste("Avg Return:", round(mean(summary$ret), 2), "%"),
      paste("Avg Volatility:", round(mean(summary$vol), 2), "%"),
      paste("Assets:", nrow(summary)),
      sep = "\n"
    )
  })
  
  output$equitySummary <- renderText({
    req(values$composite_data)
    
    equity_assets <- c("NVDA", "MSFT", "AAPL")
    equity_data <- values$composite_data %>%
      filter(asset %in% equity_assets, !is.na(returns))
    
    if (nrow(equity_data) == 0) return("No equity data")
    
    summary <- equity_data %>%
      group_by(asset) %>%
      summarise(
        ret = mean(returns) * 252 * 100,
        vol = sd(returns) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    paste(
      "Private Equity Class:",
      paste("Avg Return:", round(mean(summary$ret), 2), "%"),
      paste("Avg Volatility:", round(mean(summary$vol), 2), "%"),
      paste("Assets:", nrow(summary)),
      sep = "\n"
    )
  })
  
  output$commoditySummary <- renderText({
    req(values$composite_data)
    
    commodity_assets <- c("GC=F", "CL=F", "NG=F")
    commodity_data <- values$composite_data %>%
      filter(asset %in% commodity_assets, !is.na(returns))
    
    if (nrow(commodity_data) == 0) return("No commodity data")
    
    summary <- commodity_data %>%
      group_by(asset) %>%
      summarise(
        ret = mean(returns) * 252 * 100,
        vol = sd(returns) * sqrt(252) * 100,
        .groups = 'drop'
      )
    
    paste(
      "Commodity Class:",
      paste("Avg Return:", round(mean(summary$ret), 2), "%"),
      paste("Avg Volatility:", round(mean(summary$vol), 2), "%"),
      paste("Assets:", nrow(summary)),
      sep = "\n"
    )
  })
  
  output$classComparison <- renderText({
    req(values$composite_data)
    
    crypto_assets <- c("BTC-USD", "ETH-USD", "ADA-USD")
    equity_assets <- c("NVDA", "MSFT", "AAPL")
    commodity_assets <- c("GC=F", "CL=F", "NG=F")
    
    crypto_data <- values$composite_data %>%
      filter(asset %in% crypto_assets, !is.na(returns))
    
    equity_data <- values$composite_data %>%
      filter(asset %in% equity_assets, !is.na(returns))
    
    commodity_data <- values$composite_data %>%
      filter(asset %in% commodity_assets, !is.na(returns))
    
    if (nrow(crypto_data) == 0 && nrow(equity_data) == 0 && nrow(commodity_data) == 0) {
      return("Insufficient data for comparison")
    }
    
    crypto_ret <- if(nrow(crypto_data) > 0) mean(crypto_data$returns) * 252 * 100 else NA
    equity_ret <- if(nrow(equity_data) > 0) mean(equity_data$returns) * 252 * 100 else NA
    commodity_ret <- if(nrow(commodity_data) > 0) mean(commodity_data$returns) * 252 * 100 else NA
    
    crypto_vol <- if(nrow(crypto_data) > 0) sd(crypto_data$returns) * sqrt(252) * 100 else NA
    equity_vol <- if(nrow(equity_data) > 0) sd(equity_data$returns) * sqrt(252) * 100 else NA
    commodity_vol <- if(nrow(commodity_data) > 0) sd(commodity_data$returns) * sqrt(252) * 100 else NA
    
    # Find best performer
    returns <- c(Crypto = crypto_ret, Equity = equity_ret, Commodity = commodity_ret)
    returns <- returns[!is.na(returns)]
    best_return <- if(length(returns) > 0) names(which.max(returns)) else "N/A"
    
    # Find most volatile
    vols <- c(Crypto = crypto_vol, Equity = equity_vol, Commodity = commodity_vol)
    vols <- vols[!is.na(vols)]
    most_volatile <- if(length(vols) > 0) names(which.max(vols)) else "N/A"
    
    paste(
      "Class Comparison:",
      paste("Best Performer:", best_return),
      paste("Most Volatile:", most_volatile),
      "",
      if(!is.na(crypto_ret)) paste("Crypto Return:", round(crypto_ret, 2), "%") else NULL,
      if(!is.na(equity_ret)) paste("Equity Return:", round(equity_ret, 2), "%") else NULL,
      if(!is.na(commodity_ret)) paste("Commodity Return:", round(commodity_ret, 2), "%") else NULL,
      sep = "\n"
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)