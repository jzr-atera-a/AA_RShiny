# FX Analysis Dashboard with MySQL Integration - Enhanced with Bid/Ask Filtering
# Database Connection Tab and Market Overview Tab

library(shiny)
library(shinydashboard)
library(plotly)
library(DT) 
library(dplyr)
library(lubridate)
library(shinycssloaders)
library(TTR)
library(DBI)
library(RMySQL)
library(tidyr)
library(quantmod)
library(zoo)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FOREX Analysis Dashboard - MySQL (Bid/Ask Filtered)"),
  
  dashboardSidebar(
    # Global currency pair selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        conditionalPanel(
          condition = "output.dataLoaded == true",
          selectInput("selectedPair", 
                      "Select Currency Pair:",
                      choices = NULL,
                      selected = NULL,
                      width = "100%")
        )
    ),
    
    sidebarMenu(
      menuItem("Database Connection", tabName = "connection", icon = icon("database")),
      menuItem("Market Overview", tabName = "overview", icon = icon("chart-line")),
      menuItem("Price Analysis", tabName = "price", icon = icon("chart-simple")),
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar")),
      menuItem("Volatility Analysis", tabName = "volatility", icon = icon("wave-square")),
      menuItem("Risk Metrics", tabName = "risk", icon = icon("exclamation-triangle"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Main body background with original teal gradient */
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
        
        .box-header.with-border {
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
        
        /* Info boxes styling */
        .info-box {
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.15) !important;
          border-left: 4px solid #008A82;
        }
        
        /* Status message styling */
        .connection-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .connection-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(231, 76, 60, 0.2);
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
        
        .error-message {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 25px;
          border-radius: 12px !important;
          border: none !important;
          border-left: 4px solid #e74c3c !important;
          margin: 20px;
          text-align: center;
          font-size: 16px;
          box-shadow: 0 6px 20px rgba(231, 76, 60, 0.2);
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
        
        .btn-success {
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
          border: none !important;
          border-radius: 8px !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border: none !important;
          border-radius: 8px !important;
        }
        
        /* DataTable styling */
        .dataTables_wrapper {
          background: transparent !important;
        }
        
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          color: white !important;
        }
        
        /* Query box and debug info */
        .query-box {
          background: rgba(248, 249, 250, 0.95) !important;
          padding: 12px;
          border-radius: 8px;
          margin: 10px 0;
          font-family: 'Courier New', monospace;
          font-size: 11px;
          border: 2px solid #008A82 !important;
          max-height: 300px;
          overflow-y: auto;
        }
        
        .debug-info {
          background: rgba(233, 236, 239, 0.95) !important;
          padding: 12px;
          border-radius: 8px;
          margin: 10px 0;
          font-family: 'Courier New', monospace;
          font-size: 11px;
          border: 2px solid #00A39A !important;
          max-height: 400px;
          overflow-y: auto;
        }
        
        /* Ensure all chart backgrounds remain white */
        .plotly, .plotly .plot-container, .plotly .plot-container .svg-container {
          background: white !important;
        }
        
        /* Spinner styling */
        .spinner-border {
          color: #008A82 !important;
        }
        
        /* Navigation and content width maintenance */
        .content-wrapper {
          margin-left: 230px !important;
        }
        
        .main-sidebar {
          width: 230px !important;
        }
        
        /* Global text improvements */
        body, .content-wrapper {
          font-family: 'Segoe UI', 'Arial', sans-serif;
        }
        
        h1, h2, h3, h4, h5, h6 {
          color: #002C3C;
          font-weight: 600;
        }
        
        /* Tab content styling */
        .tab-content {
          background: transparent;
        }
        
        /* Conditional panel backgrounds */
        .shiny-output-error {
          color: #721c24;
        }
        
        /* Custom scrollbar for boxes */
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
        
        .box-body::-webkit-scrollbar-thumb:hover {
          background: linear-gradient(135deg, #006b63, #007d75);
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          border-bottom: none !important;
          font-weight: 600;
        }
        
        .main-header .logo:hover {
          background: linear-gradient(135deg, #001f2a 0%, #006b63 50%, #007d75 100%) !important;
        }
        
        /* Dashboard header brand text */
        .main-header .logo .logo-lg,
        .main-header .logo .logo-mini {
          color: #ffffff !important;
          font-weight: 600;
        }
        
        /* Navbar toggle button */
        .main-header .navbar .sidebar-toggle {
          background: rgba(255, 255, 255, 0.1) !important;
          color: #ffffff !important;
          border: none !important;
        }
        
        .main-header .navbar .sidebar-toggle:hover {
          background: rgba(255, 255, 255, 0.2) !important;
        }
      "))
    ),
    
    tabItems(
      # Database Connection Tab
      # Volatility Analysis Tab
      tabItem(tabName = "volatility",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("No Data Available"),
                    p("Volatility analysis requires database connection and loaded data.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Volatility Analysis Controls", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    
                    div(style = "background-color: #e8f4fd; padding: 8px; border-radius: 4px; margin-bottom: 15px;",
                        p("Using recalculated Mid prices", style = "margin: 0; font-size: 11px; color: #2c3e50;"),
                        p("Mid = (Bid + Ask) / 2", style = "margin: 0; font-size: 11px; font-weight: bold;")
                    ),
                    
                    radioButtons("volatilityType", "Volatility Estimation Method:",
                                 choices = c("Realized Volatility (Close-to-Close)" = "realized",
                                             "Parkinson Estimator (High-Low)" = "parkinson",
                                             "Garman-Klass Estimator (OHLC)" = "garch"),
                                 selected = "realized"),
                    
                    br(),
                    numericInput("volWindow", "Rolling Window (periods):",
                                 value = 30, min = 10, max = 252, step = 1),
                    
                    br(),
                    sliderInput("volConfidence", "Confidence Level for Bands:",
                                min = 90, max = 99, value = 95, step = 1),
                    
                    br(),
                    checkboxInput("annualizeVol", "Annualize Volatility", value = TRUE),
                    
                    br(),
                    h5("Volatility Metrics:"),
                    verbatimTextOutput("volatilityMetrics")
                  ),
                  
                  box(
                    title = "Volatility Time Series Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("volatilityChart", height = "450px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Volatility Distribution & Statistics", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("volatilityDist", height = "350px"))
                  ),
                  box(
                    title = "Returns vs Volatility Clustering", 
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
              
              fluidRow(
                box(
                  title = "Volatility Analysis - Calculation Methods & Data Sources", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  
                  h5("Data Preparation:"),
                  p("• Returns Calculation: Log returns = diff(log(Mid)) where Mid = (Bid + Ask) / 2"),
                  p("• Time Series: Uses up to last 1000 records for main analysis, 500 for clustering"),
                  
                  h5("Volatility Estimation Methods:"),
                  p("• Realized Volatility: Rolling standard deviation of returns using rollapply(returns, window, sd)"),
                  p("• Parkinson Estimator: sqrt(mean(log(High/Low)^2) / (4*log(2))) for OHLC data"),
                  p("• Garman-Klass: Uses OHLC data for more efficient volatility estimation (when available)"),
                  p("• Annualization: Daily volatility * sqrt(252) for annualized figures"),
                  
                  h5("Rolling Volatility Analysis:"),
                  p("• Rolling Window: User-defined window size (typically 30 periods)"),
                  p("• Confidence Bands: Mean ± (confidence_multiplier * standard_deviation)"),
                  p("• Confidence Multiplier: qnorm((100 + confidence_level) / 200)"),
                  
                  h5("Distribution Analysis:"),
                  p("• Volatility Distribution: Histogram of rolling volatility values"),
                  p("• Statistical Lines: Mean and median volatility levels marked on distribution"),
                  p("• Clustering Analysis: Absolute returns |returns| * 100 to show volatility clustering patterns"),
                  
                  h5("Regime Classification:"),
                  p("• Low Volatility: Below 25th percentile of historical volatility"),
                  p("• Normal Volatility: Between 25th and 75th percentiles"),
                  p("• High Volatility: Above 75th percentile of historical volatility"),
                  p("• Regime Boundaries: Calculated using quantile(volatility, c(0.25, 0.75))")
                )
              )
      ),
      
      # Risk Metrics Tab
      tabItem(tabName = "risk",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("No Data Available"),
                    p("Risk analysis requires database connection and loaded data.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Risk Analysis Settings", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    
                    div(style = "background-color: #e8f4fd; padding: 8px; border-radius: 4px; margin-bottom: 15px;",
                        p("Risk calculations based on:", style = "margin: 0; font-size: 11px; color: #2c3e50;"),
                        p("Mid = (Bid + Ask) / 2 returns", style = "margin: 0; font-size: 11px; font-weight: bold;")
                    ),
                    
                    numericInput("portfolioValue", "Portfolio Value (USD):",
                                 value = 1000000, min = 10000, max = 100000000, step = 10000),
                    
                    br(),
                    sliderInput("confidenceLevel", "VaR Confidence Level (%):",
                                min = 90, max = 99.5, value = 95, step = 0.5),
                    
                    br(),
                    numericInput("timeHorizon", "Time Horizon (days):",
                                 value = 1, min = 1, max = 30, step = 1),
                    
                    br(),
                    radioButtons("varMethod", "VaR Calculation Method:",
                                 choices = c("Historical Simulation" = "historical",
                                             "Parametric (Normal)" = "parametric",
                                             "Modified Cornish-Fisher" = "modified"),
                                 selected = "historical"),
                    
                    br(),
                    numericInput("varWindow", "VaR Rolling Window:",
                                 value = 250, min = 100, max = 1000, step = 50),
                    
                    br(),
                    h5("Risk Metrics Summary:"),
                    verbatimTextOutput("riskMetrics")
                  ),
                  
                  box(
                    title = "Value at Risk (VaR) Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("varChart", height = "450px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Expected Shortfall (Conditional VaR)", 
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
                    title = "Risk Decomposition & Statistics", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(DT::dataTableOutput("riskStatsTable"))
                  ),
                  box(
                    title = "Stress Testing Scenarios", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(DT::dataTableOutput("stressTestResults"))
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk Metrics - Calculation Methods & Data Sources", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  
                  h5("Data Preparation:"),
                  p("• Returns Calculation: Log returns = diff(log(Mid)) where Mid = (Bid + Ask) / 2"),
                  p("• Time Horizon Adjustment: Adjusted returns = returns * sqrt(time_horizon_days)"),
                  p("• Portfolio Impact: Risk metrics converted to USD using portfolio value"),
                  
                  h5("Value at Risk (VaR) Methods:"),
                  p("• Historical Simulation: VaR = quantile(returns, (100-confidence)/100)"),
                  p("• Parametric Method: VaR = mean + qnorm(percentile) * standard_deviation"),
                  p("• Cornish-Fisher: Adjusts for skewness and kurtosis in return distribution"),
                  p("• Rolling VaR: Calculated using sliding window of specified size (typically 250 periods)"),
                  
                  h5("Expected Shortfall (Conditional VaR):"),
                  p("• Calculation: Mean of all returns below the VaR threshold"),
                  p("• Formula: ES = E[Return | Return ≤ VaR]"),
                  p("• Rolling ES: Applied to sliding windows for time series analysis"),
                  
                  h5("Drawdown Analysis:"),
                  p("• Cumulative Returns: cumprod(1 + returns) to build wealth index"),
                  p("• Running Maximum: cummax(cumulative_returns) for peak tracking"),
                  p("• Drawdown: (cumulative_returns - running_max) / running_max * 100"),
                  p("• Maximum Drawdown: Minimum value in drawdown series"),
                  
                  h5("Risk Statistics:"),
                  p("• Sharpe Ratio: (mean_return / volatility) * sqrt(252) for annualization"),
                  p("• Sortino Ratio: mean_return / downside_deviation * sqrt(252)"),
                  p("• Skewness: Third moment of return distribution"),
                  p("• Kurtosis: Fourth moment minus 3 (excess kurtosis)"),
                  
                  h5("Stress Testing:"),
                  p("• Scenario Analysis: Historical volatility * sigma multipliers (2σ, 3σ, 4σ, 5σ)"),
                  p("• Crisis Scenarios: Based on historical market events with corresponding probability estimates"),
                  p("• Recovery Time: Estimated based on historical precedent and volatility levels")
                )
              )
      ),
      
      tabItem(tabName = "connection",
              fluidRow(
                box(
                  title = "Database Connection Settings", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h4("MySQL Database Configuration"),
                  
                  textInput("host", "Database Host:", value = "127.0.0.1"),
                  numericInput("port", "Port:", value = 3306, min = 1, max = 65535),
                  textInput("dbname", "Database Name:", value = "fx_database"),
                  textInput("username", "Username:", value = "host1_new"),
                  passwordInput("password", "Password:", placeholder = "Enter database password"),
                  
                  br(),
                  
                  actionButton("testConnection", "Test Connection", 
                               class = "btn btn-primary", width = "48%"),
                  actionButton("closeConnections", "Close All Connections", 
                               class = "btn btn-warning", width = "48%"),
                  
                  br(), br(),
                  uiOutput("connectionStatus")
                ),
                
                box(
                  title = "Data Source Selection", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  conditionalPanel(
                    condition = "output.connectionValid == true",
                    
                    h4("Select Data Table"),
                    
                    selectInput("sourceTable", "Data Source:",
                                choices = list(
                                  "Daily Data (fx_spot_prices_daily)" = "fx_spot_prices_daily",
                                  "Intraday Data (fx_spot_prices)" = "fx_spot_prices"
                                ),
                                selected = "fx_spot_prices_daily"),
                    
                    # Conditional controls for fx_spot_prices
                    conditionalPanel(
                      condition = "input.sourceTable == 'fx_spot_prices'",
                      br(),
                      selectInput("intradayPair", "Select Currency Pair:",
                                  choices = list(
                                    "USDDKK" = "USDDKK",
                                    "USDILS" = "USDILS", 
                                    "USDRUB" = "USDRUB",
                                    "USDTHB" = "USDTHB"
                                  ),
                                  selected = "USDTHB"),
                      
                      br(),
                      
                      sliderInput("dayRange", "Number of Last Days to Load:",
                                  min = 1, max = 120, value = 7, step = 1,
                                  ticks = TRUE),
                      
                      br(),
                      
                      selectInput("aggregationLevel", "Data Aggregation Level:",
                                  choices = list(
                                    "Raw Data (No Aggregation)" = "raw",
                                    "5 Minute Average" = "5min",
                                    "15 Minute Average" = "15min",
                                    "1 Hour Average" = "hour",
                                    "4 Hour Average" = "4hour",
                                    "Daily Average" = "day"
                                  ),
                                  selected = "raw"),
                      
                      br(),
                      
                      div(style = "background-color: #e8f4fd; padding: 10px; border-radius: 5px; margin: 10px 0;",
                          h6("Data Quality Filter:"),
                          p("Only records with valid numeric Bid and Ask values will be loaded.", style = "margin-bottom: 0; font-size: 12px;"),
                          p("Mid prices will be recalculated as (Bid + Ask) / 2.", style = "margin-bottom: 0; font-size: 12px; font-weight: bold;")
                      )
                    ),
                    
                    br(),
                    
                    actionButton("loadData", "Load Data", 
                                 class = "btn btn-success", width = "100%"),
                    
                    br(), br(),
                    
                    uiOutput("dataStatus"),
                    
                    br(),
                    
                    h5("Database Statistics:"),
                    verbatimTextOutput("dbStats")
                  )
                )
              ),
              
              # Detailed Error Information Box
              conditionalPanel(
                condition = "output.showDetailedError == true",
                fluidRow(
                  box(
                    title = "Detailed Error Information", 
                    status = "danger", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(6,
                             h5("Error Details:"),
                             div(class = "debug-info",
                                 verbatimTextOutput("detailedErrorInfo"))
                      ),
                      column(6,
                             h5("Database Diagnostics:"),
                             div(class = "debug-info",
                                 verbatimTextOutput("databaseDiagnostics"))
                      )
                    ),
                    
                    h5("SQL Query Execution Log:"),
                    div(class = "query-box",
                        verbatimTextOutput("sqlExecutionLog"))
                  )
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Data Extraction Overview", 
                    status = "success", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(4,
                             h5("Raw Data Quality:"),
                             verbatimTextOutput("rawDataQuality")
                      ),
                      column(4,
                             h5("Bid/Ask Processing:"),
                             verbatimTextOutput("bidAskProcessing")
                      ),
                      column(4,
                             h5("Final Data Summary:"),
                             verbatimTextOutput("finalDataSummary")
                      )
                    )
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Data Preview (First 20 Records)", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    
                    withSpinner(DT::dataTableOutput("dataPreview"))
                  ),
                  
                  box(
                    title = "Price Statistics", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 4,
                    
                    h5("Price Range Analysis:"),
                    verbatimTextOutput("priceRangeStats"),
                    
                    br(),
                    
                    h5("Data Coverage:"),
                    verbatimTextOutput("dataCoverageStats")
                  )
                )
              )
      ),
      
      # Market Overview Tab
      tabItem(tabName = "overview",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("No Data Loaded"),
                    p("Please connect to the database and load data in the 'Database Connection' tab.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Chart Controls & Data Information",
                    status = "info",
                    solidHeader = TRUE,
                    width = 12,
                    
                    fluidRow(
                      column(3,
                             checkboxGroupInput("priceComponents", "Show Price Components:",
                                                choices = c("Mid Price (Calculated)" = "Mid",
                                                            "Bid Price" = "Bid", 
                                                            "Ask Price" = "Ask"),
                                                selected = c("Mid", "Bid", "Ask"),
                                                inline = TRUE)
                      ),
                      column(3,
                             checkboxInput("showSpread", "Show Bid-Ask Spread", value = TRUE),
                             checkboxInput("showMovingAvg", "Show Moving Averages", value = TRUE)
                      ),
                      column(6,
                             div(style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
                                 h6("Data Quality Information:"),
                                 p(textOutput("dataQualityInfo"), style = "margin-bottom: 0; font-size: 12px;"))
                      )
                    )
                  )
                ),
                
                fluidRow(
                  valueBoxOutput("currentPrice", width = 3),
                  valueBoxOutput("dailyChange", width = 3),
                  valueBoxOutput("bidAskSpread", width = 3),
                  valueBoxOutput("dataRange", width = 3)
                ),
                
                fluidRow(
                  box(
                    title = "Price Chart with Recalculated Mid Prices", 
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
                    title = "Bid-Ask Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(DT::dataTableOutput("bidAskStats"))
                  ),
                  box(
                    title = "Price Movement Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(DT::dataTableOutput("priceMovementStats"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Bid-Ask Spread Over Time", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("spreadChart", height = "300px"))
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
              fluidRow(
                box(
                  title = "Market Overview - Calculation Methods & Data Sources", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  
                  h5("Data Processing:"),
                  p("• Raw Data Filtering: Only records with valid numeric Bid > 0 and Ask > 0, where Ask > Bid"),
                  p("• Mid Price Calculation: Mid = (Bid + Ask) / 2 for all price analysis"),
                  p("• Spread Calculation: spread_pct = (Ask - Bid) / Mid * 100"),
                  p("• Returns Calculation: returns = diff(log(Mid)) for log returns"),
                  
                  h5("Value Box Calculations:"),
                  p("• Current Price: Last Mid value from filtered dataset"),
                  p("• Daily Change: ((Current_Mid - Previous_Mid) / Previous_Mid) * 100"),
                  p("• Bid-Ask Spread: Mean of all spread_pct values in the dataset"),
                  p("• Data Range: Count of records and date span (max_date - min_date + 1)"),
                  
                  h5("Chart Calculations:"),
                  p("• Main Price Chart: Uses recalculated Mid, Bid, Ask prices with optional moving averages SMA(n)"),
                  p("• Moving Averages: Simple Moving Average calculated using TTR::SMA() function"),
                  p("• Price Distribution: Histogram of Mid price values using plotly histogram"),
                  p("• Returns Distribution: Histogram of log returns * 100 for percentage display"),
                  
                  h5("Statistics Tables:"),
                  p("• Market Stats: Current, Mean, Min, Max, Range of Mid prices; Average spread in basis points"),
                  p("• Bid-Ask Analysis: Current/Mean/Max/Min spread statistics, volatility of spreads"),
                  p("• Price Movement: Valid returns count, volatility (SD of returns * sqrt(252) * 100), max gains/losses")
                )
              )
              
      ),
      
      # Technical Indicators Tab
      tabItem(tabName = "technical",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("No Data Available"),
                    p("Technical analysis requires database connection and loaded data.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Technical Analysis Settings", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 3,
                    
                    h5("Data Source Info:"),
                    div(style = "background-color: #e8f4fd; padding: 8px; border-radius: 4px; margin-bottom: 15px;",
                        p("Using recalculated Mid prices", style = "margin: 0; font-size: 11px; color: #2c3e50;"),
                        p("Mid = (Bid + Ask) / 2", style = "margin: 0; font-size: 11px; font-weight: bold;")
                    ),
                    
                    h5("Indicator Selection:"),
                    checkboxGroupInput("technicalIndicators", "Select Indicators:",
                                       choices = c("Simple Moving Average" = "sma",
                                                   "Exponential Moving Average" = "ema", 
                                                   "RSI" = "rsi",
                                                   "MACD" = "macd",
                                                   "Bollinger Bands" = "bb",
                                                   "Stochastic" = "stoch"),
                                       selected = c("sma", "rsi")),
                    
                    br(),
                    h5("Parameters:"),
                    numericInput("smaLength", "SMA Length:", value = 20, min = 5, max = 200, step = 1),
                    numericInput("emaLength", "EMA Length:", value = 20, min = 5, max = 200, step = 1),
                    numericInput("rsiLength", "RSI Length:", value = 14, min = 5, max = 50, step = 1),
                    numericInput("bbLength", "Bollinger Bands Length:", value = 20, min = 5, max = 100, step = 1),
                    numericInput("bbSd", "BB Standard Deviations:", value = 2, min = 1, max = 3, step = 0.1),
                    
                    br(),
                    h5("Data Quality Check:"),
                    verbatimTextOutput("technicalDataQuality"),
                    
                    br(),
                    h5("Current Signals:"),
                    verbatimTextOutput("technicalSignals")
                  ),
                  
                  box(
                    title = "Technical Chart with Recalculated Mid Prices", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 9,
                    withSpinner(plotlyOutput("technicalChart", height = "600px"))
                  )
                ),
                
                # RSI Oscillator - Full Width
                conditionalPanel(
                  condition = "input.technicalIndicators.includes('rsi')",
                  fluidRow(
                    box(
                      title = "RSI Oscillator - Relative Strength Index", 
                      status = "primary", 
                      solidHeader = TRUE, 
                      width = 12,
                      withSpinner(plotlyOutput("rsiChart", height = "400px"))
                    )
                  )
                ),
                
                # MACD Indicator - Full Width
                conditionalPanel(
                  condition = "input.technicalIndicators.includes('macd')",
                  fluidRow(
                    box(
                      title = "MACD Indicator - Moving Average Convergence Divergence", 
                      status = "primary", 
                      solidHeader = TRUE, 
                      width = 12,
                      withSpinner(plotlyOutput("macdChart", height = "400px"))
                    )
                  )
                ),
                
                # Stochastic Oscillator - Full Width
                conditionalPanel(
                  condition = "input.technicalIndicators.includes('stoch')",
                  fluidRow(
                    box(
                      title = "Stochastic Oscillator - %K and %D Lines", 
                      status = "primary", 
                      solidHeader = TRUE, 
                      width = 12,
                      withSpinner(plotlyOutput("stochChart", height = "400px"))
                    )
                  )
                ),
                
                # Technical Analysis Summary - Full Width
                fluidRow(
                  box(
                    title = "Technical Analysis Summary & Signals", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(4,
                             h5("Indicator Status:"),
                             verbatimTextOutput("indicatorStatus")
                      ),
                      column(4,
                             h5("Price Action Analysis:"),
                             verbatimTextOutput("priceActionAnalysis")
                      ),
                      column(4,
                             h5("Current Technical Signals:"),
                             DT::dataTableOutput("signalSummary")
                      )
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Technical Indicators - Calculation Methods & Data Sources", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  
                  h5("Data Source:"),
                  p("• Price Series: Uses recalculated Mid prices (Bid + Ask) / 2 for all indicator calculations"),
                  p("• Time Series: Limited to last 500 records for main chart, 200 for oscillators (performance optimization)"),
                  
                  h5("Moving Averages:"),
                  p("• Simple Moving Average (SMA): TTR::SMA(price, n) - arithmetic mean of last n periods"),
                  p("• Exponential Moving Average (EMA): TTR::EMA(price, n) - weighted average favoring recent prices"),
                  
                  h5("Oscillators:"),
                  p("• RSI Calculation: TTR::RSI(price, n) = 100 - (100 / (1 + RS)), where RS = Average Gain / Average Loss"),
                  p("• RSI Signals: Overbought (>70), Oversold (<30), Neutral (30-70)"),
                  p("• MACD Calculation: TTR::MACD(price, nFast=12, nSlow=26, nSig=9)"),
                  p("• MACD Components: MACD Line, Signal Line, Histogram (MACD - Signal)"),
                  
                  h5("Bollinger Bands:"),
                  p("• Calculation: TTR::BBands(price, n=20, sd=2)"),
                  p("• Upper Band: SMA(n) + (SD * multiplier), Lower Band: SMA(n) - (SD * multiplier)"),
                  p("• Middle Line: Simple moving average of the price series"),
                  
                  h5("Stochastic Oscillator:"),
                  p("• %K Calculation: ((Current Close - Lowest Low) / (Highest High - Lowest Low)) * 100"),
                  p("• %D Calculation: SMA of %K values over specified period (typically 3)"),
                  p("• Uses 14-period lookback for high/low, manual calculation using rollapply()"),
                  p("• Signals: Overbought (>80), Oversold (<20)"),
                  
                  h5("Signal Generation:"),
                  p("• Technical Signals: Combination of RSI levels, price vs SMA position, MACD crossovers"),
                  p("• Signal Summary Table: Current indicator values with bullish/bearish/neutral classifications"),
                  p("• Data Quality Checks: Validates sufficient data points and price variation for reliable indicators")
                )
              )
      ),
      
      # Price Analysis Tab (UI - replace existing)
      tabItem(tabName = "price",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("No Data Available"),
                    p("Price analysis requires database connection and data loading.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                
                # Price Analysis Controls
                fluidRow(
                  box(
                    title = "Price Analysis Controls & Data Information", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(3,
                             h5("Date Range Selection:"),
                             dateRangeInput("priceRange", "Analysis Period:",
                                            start = Sys.Date() - years(1),
                                            end = Sys.Date(),
                                            format = "yyyy-mm-dd",
                                            width = "100%")
                      ),
                      column(3,
                             h5("Price Components:"),
                             checkboxGroupInput("priceComponents", "Show Components:",
                                                choices = c("Mid Price (Calculated)" = "mid", 
                                                            "Bid Price" = "bid", 
                                                            "Ask Price" = "ask",
                                                            "Bid-Ask Spread" = "spread"),
                                                selected = c("mid", "spread"),
                                                inline = FALSE)
                      ),
                      column(3,
                             h5("Technical Settings:"),
                             numericInput("movingAvgDays", "Moving Average Periods:",
                                          value = 20, min = 5, max = 200, step = 5),
                             checkboxInput("showBollingerBands", "Show Bollinger Bands", value = FALSE),
                             numericInput("bbPeriods", "BB Periods:", value = 20, min = 5, max = 100)
                      ),
                      column(3,
                             h5("Data Quality Info:"),
                             div(style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px;",
                                 p(textOutput("priceAnalysisDataInfo"), style = "margin: 0; font-size: 12px;"))
                      )
                    ),
                    
                    hr(),
                    
                    fluidRow(
                      column(12,
                             h5("Period Statistics:"),
                             verbatimTextOutput("priceStats")
                      )
                    )
                  )
                ),
                
                # Detailed Price Chart
                fluidRow(
                  box(
                    title = "Detailed Price Chart with Technical Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    withSpinner(plotlyOutput("detailedPriceChart", height = "600px"))
                  )
                ),
                
                # OHLC Analysis (for aggregated data)
                conditionalPanel(
                  condition = "output.showOHLCAnalysis == true",
                  fluidRow(
                    box(
                      title = "OHLC Candlestick Analysis", 
                      status = "primary", 
                      solidHeader = TRUE, 
                      width = 12,
                      
                      fluidRow(
                        column(8,
                               withSpinner(plotlyOutput("ohlcCandlestickChart", height = "450px"))
                        ),
                        column(4,
                               h5("OHLC Statistics:"),
                               withSpinner(DT::dataTableOutput("ohlcStatsTable"))
                        )
                      )
                    )
                  )
                ),
                
                # Bid-Ask Spread Analysis
                fluidRow(
                  box(
                    title = "Comprehensive Bid-Ask Spread Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(6,
                             withSpinner(plotlyOutput("spreadAnalysis", height = "400px"))
                      ),
                      column(6,
                             withSpinner(plotlyOutput("spreadDistributionAnalysis", height = "400px"))
                      )
                    )
                  )
                ),
                
                # Price Distribution Analysis
                fluidRow(
                  box(
                    title = "Price Distribution and Statistical Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(4,
                             withSpinner(plotlyOutput("priceDistribution", height = "350px"))
                      ),
                      column(4,
                             withSpinner(plotlyOutput("priceQQPlot", height = "350px"))
                      ),
                      column(4,
                             withSpinner(plotlyOutput("priceBoxPlot", height = "350px"))
                      )
                    )
                  )
                ),
                
                # Returns Analysis
                fluidRow(
                  box(
                    title = "Returns Analysis and Performance Metrics", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(6,
                             withSpinner(plotlyOutput("returnsTimeSeriesChart", height = "400px"))
                      ),
                      column(6,
                             withSpinner(plotlyOutput("returnsDistributionChart", height = "400px"))
                      )
                    )
                  )
                ),
                
                # Advanced Price Analytics
                fluidRow(
                  box(
                    title = "Advanced Price Analytics", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(4,
                             h5("Price Level Analysis:"),
                             withSpinner(DT::dataTableOutput("priceLevelsTable"))
                      ),
                      column(4,
                             h5("Volatility Breakdown:"),
                             withSpinner(DT::dataTableOutput("volatilityBreakdownTable"))
                      ),
                      column(4,
                             h5("Trading Statistics:"),
                             withSpinner(DT::dataTableOutput("tradingStatsTable"))
                      )
                    )
                  )
                ),
                
                # Intraperiod Analysis (for intraday data)
                conditionalPanel(
                  condition = "output.showIntraperiodAnalysis == true",
                  fluidRow(
                    box(
                      title = "Intraperiod Pattern Analysis", 
                      status = "info", 
                      solidHeader = TRUE, 
                      width = 12,
                      
                      fluidRow(
                        column(6,
                               withSpinner(plotlyOutput("intraperiodPatternsChart", height = "350px"))
                        ),
                        column(6,
                               withSpinner(plotlyOutput("aggregationImpactChart", height = "350px"))
                        )
                      )
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Price Analysis - Calculation Methods & Data Sources", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  
                  h5("Data Processing:"),
                  p("• Date Filtering: Data filtered by user-selected date range (input$priceRange)"),
                  p("• Price Components: Mid = (Bid + Ask) / 2, Bid and Ask from database with validation"),
                  p("• Technical Indicators: Moving averages using TTR::SMA(price, n), Bollinger Bands using TTR::BBands()"),
                  
                  h5("OHLC Analysis (for aggregated data):"),
                  p("• Candlestick Chart: Uses Mid_Open, Mid_High, Mid_Low, Mid_Close from aggregated records"),
                  p("• OHLC Statistics: Average of OHLC values, range calculations (High - Low), body size |Close - Open|"),
                  p("• Bullish/Bearish: Percentage where Mid_Close > Mid_Open (bullish) vs Mid_Close < Mid_Open (bearish)"),
                  
                  h5("Spread Analysis:"),
                  p("• Time Series: spread_pct over time with rolling average SMA(spread_pct, 30)"),
                  p("• Distribution: Histogram of spread_pct values using specified number of bins"),
                  p("• Rolling Volatility: Rolling standard deviation of spread_pct values"),
                  
                  h5("Statistical Analysis:"),
                  p("• Price Distribution: Histogram of Mid prices with normal distribution overlay"),
                  p("• Q-Q Plot: Theoretical quantiles vs sample quantiles for normality testing using qnorm()"),
                  p("• Box Plot: Five-number summary (min, Q1, median, Q3, max) of price distribution"),
                  p("• Returns Analysis: Log returns calculation and distribution with statistical moments"),
                  
                  h5("Advanced Analytics:"),
                  p("• Support/Resistance Levels: Price percentiles at 5%, 25%, 50%, 75%, 95% using quantile()"),
                  p("• Volatility Breakdown: Daily, weekly, monthly, annual volatility (SD * sqrt(periods))"),
                  p("• Trading Statistics: Up/down period ratios, average moves, spread quality metrics")
                )
              )
      ),
      
      # Correlation Matrix Tab (UI - replace existing)
      tabItem(tabName = "correlation",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("No Data Available"),
                    p("Correlation analysis requires database connection and loaded data.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Correlation Analysis Settings", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    
                    div(style = "background-color: #e8f4fd; padding: 8px; border-radius: 4px; margin-bottom: 15px;",
                        p("Data source info:", style = "margin: 0; font-size: 11px; color: #2c3e50;"),
                        p(textOutput("correlationDataSource"), style = "margin: 0; font-size: 11px; font-weight: bold;")
                    ),
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == true",
                      
                      checkboxGroupInput("correlationPairs", "Select Currency Pairs:",
                                         choices = NULL,
                                         selected = NULL),
                      
                      br(),
                      radioButtons("correlationType", "Correlation Type:",
                                   choices = c("Pearson" = "pearson",
                                               "Spearman" = "spearman",
                                               "Kendall" = "kendall"),
                                   selected = "pearson"),
                      
                      br(),
                      numericInput("correlationWindow", "Rolling Window (periods):",
                                   value = 60, min = 30, max = 500, step = 10),
                      
                      br(),
                      radioButtons("returnType", "Return Type:",
                                   choices = c("Simple Returns" = "simple",
                                               "Log Returns" = "log"),
                                   selected = "log"),
                      
                      br(),
                      h5("Correlation Summary:"),
                      verbatimTextOutput("correlationSummary")
                    ),
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == false",
                      div(class = "data-warning",
                          h5("Multiple Currency Pairs Required"),
                          p("Correlation analysis requires data from multiple currency pairs."),
                          p("The current data source contains only single pair data from fx_spot_prices table."),
                          p("Please load data from fx_spot_prices_daily to access correlation analysis features."))
                    )
                  ),
                  
                  box(
                    title = "Correlation Heatmap", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == true",
                      withSpinner(plotOutput("correlationHeatmap", height = "450px"))
                    ),
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == false",
                      div(class = "error-message", style = "height: 400px; display: flex; align-items: center; justify-content: center;",
                          div(style = "text-align: center;",
                              h4("Correlation Heatmap Unavailable"),
                              p("Multiple currency pairs are required for correlation analysis."),
                              p("Current data source: fx_spot_prices (single pair data)"),
                              p("Switch to fx_spot_prices_daily for multi-pair correlation analysis.")))
                    )
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Rolling Correlations Time Series", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == true",
                      withSpinner(plotlyOutput("rollingCorrelations", height = "350px"))
                    ),
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == false",
                      div(class = "error-message", style = "height: 300px; display: flex; align-items: center; justify-content: center;",
                          div(style = "text-align: center;",
                              h5("Rolling Correlations Unavailable"),
                              p("Requires multiple currency pairs"),
                              p("Please use fx_spot_prices_daily table")))
                    )
                  ),
                  
                  box(
                    title = "Correlation Statistics & Network", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == true",
                      withSpinner(plotlyOutput("correlationNetwork", height = "350px"))
                    ),
                    
                    conditionalPanel(
                      condition = "output.showCorrelationControls == false",
                      div(class = "error-message", style = "height: 300px; display: flex; align-items: center; justify-content: center;",
                          div(style = "text-align: center;",
                              h5("Correlation Network Unavailable"),
                              p("Requires multiple currency pairs"),
                              p("Please use fx_spot_prices_daily table")))
                    )
                  )
                ),
                
                conditionalPanel(
                  condition = "output.showCorrelationControls == true",
                  fluidRow(
                    box(
                      title = "Correlation Matrix Statistics", 
                      status = "info", 
                      solidHeader = TRUE, 
                      width = 12,
                      withSpinner(DT::dataTableOutput("correlationStatsTable"))
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Correlation Analysis - Calculation Methods & Data Sources", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  collapsible = TRUE,
                  collapsed = TRUE,
                  
                  h5("Data Requirements:"),
                  p("• Multi-Pair Data: Requires data from fx_spot_prices_daily with multiple currency pairs"),
                  p("• Single-Pair Limitation: Shows warning message for fx_spot_prices (single pair) data"),
                  p("• Return Calculation: Log returns = diff(log(Mid)) or Simple returns = diff(Mid)/lag(Mid)"),
                  
                  h5("Correlation Methods:"),
                  p("• Pearson Correlation: cor(x, y, method='pearson') - measures linear relationship"),
                  p("• Spearman Correlation: cor(x, y, method='spearman') - measures monotonic relationship"),
                  p("• Kendall Correlation: cor(x, y, method='kendall') - measures rank-based correlation"),
                  
                  h5("Data Processing:"),
                  p("• Wide Format Conversion: tidyr::pivot_wider() to create matrix with pairs as columns"),
                  p("• Complete Cases: na.omit() to ensure only overlapping time periods are analyzed"),
                  p("• Minimum Observations: Requires at least 50 complete observations for reliable correlations"),
                  
                  h5("Rolling Correlations:"),
                  p("• Rolling Window: User-defined window size (typically 60-252 periods)"),
                  p("• Calculation: rollapply() with correlation function applied to sliding windows"),
                  p("• Pairs Selection: Uses first two selected currency pairs for rolling analysis"),
                  
                  h5("Correlation Matrix Visualization:"),
                  p("• Heatmap: corrplot() with hierarchical clustering reordering"),
                  p("• Color Scale: Blue (positive) to Red (negative) correlation gradient"),
                  p("• Significance Testing: cor.test() for statistical significance of correlations"),
                  
                  h5("Network Analysis:"),
                  p("• Correlation Threshold: |correlation| > 0.3 for edge inclusion"),
                  p("• Node Layout: Circular arrangement with equal angular spacing"),
                  p("• Edge Weights: Line thickness proportional to absolute correlation strength"),
                  
                  h5("Statistics Summary:"),
                  p("• Pairwise Analysis: All unique pair combinations with significance tests"),
                  p("• Strength Classification: Strong (|r| ≥ 0.7), Moderate (|r| ≥ 0.3), Weak (|r| < 0.3)"),
                  p("• P-value Testing: Statistical significance at α = 0.05 level")
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
    connection = NULL,
    connected = FALSE,
    fx_data = NULL,
    data_loaded = FALSE,
    source_table = NULL,
    last_error = NULL,
    detailed_error_info = NULL,
    sql_log = NULL,
    db_diagnostics = NULL,
    processing_log = NULL,
    show_detailed_error = FALSE,
    bid_ask_stats = NULL,
    original_vs_calculated_mid = NULL
  )
  
  # Store connection reference outside reactive values for cleanup
  connection_ref <- NULL
  
  # Enhanced error logging function
  log_error <- function(error_msg, context = "", query = "", additional_info = list()) {
    timestamp <- Sys.time()
    
    values$last_error <- error_msg
    values$show_detailed_error <- TRUE
    
    # Detailed error information
    error_details <- paste(
      paste("Timestamp:", timestamp),
      paste("Context:", context),
      paste("Error Message:", error_msg),
      "",
      "Additional Information:",
      paste(names(additional_info), additional_info, sep = ": ", collapse = "\n"),
      "",
      "R Session Info:",
      paste("R Version:", R.version.string),
      paste("Platform:", Sys.info()["sysname"]),
      sep = "\n"
    )
    
    values$detailed_error_info <- error_details
    
    # SQL execution log
    if (query != "") {
      sql_log_entry <- paste(
        paste("Timestamp:", timestamp),
        paste("Query:", query),
        paste("Status: FAILED"),
        paste("Error:", error_msg),
        "---",
        sep = "\n"
      )
      
      if (is.null(values$sql_log)) {
        values$sql_log <- sql_log_entry
      } else {
        values$sql_log <- paste(values$sql_log, sql_log_entry, sep = "\n\n")
      }
    }
  }
  
  # Enhanced database diagnostics function
  run_db_diagnostics <- function() {
    if (!values$connected || is.null(connection_ref)) {
      values$db_diagnostics <- "No active database connection"
      return()
    }
    
    tryCatch({
      diagnostics <- c()
      
      # Check connection status
      diagnostics <- c(diagnostics, "=== CONNECTION STATUS ===")
      diagnostics <- c(diagnostics, paste("Connection active:", !is.null(connection_ref)))
      
      # List all tables
      diagnostics <- c(diagnostics, "", "=== AVAILABLE TABLES ===")
      tables <- dbListTables(connection_ref)
      diagnostics <- c(diagnostics, paste("Tables found:", length(tables)))
      diagnostics <- c(diagnostics, paste("Table names:", paste(tables, collapse = ", ")))
      
      # Check specific tables
      for (table in c("fx_spot_prices", "fx_spot_prices_daily")) {
        if (table %in% tables) {
          diagnostics <- c(diagnostics, "", paste("=== TABLE:", table, "==="))
          
          # Count records
          count_query <- paste("SELECT COUNT(*) as count FROM", table)
          count_result <- dbGetQuery(connection_ref, count_query)
          diagnostics <- c(diagnostics, paste("Total records:", format(count_result$count, big.mark = ",")))
          
          # Count records with valid Bid/Ask (for fx_spot_prices)
          if (table == "fx_spot_prices") {
            valid_bidask_query <- paste("SELECT COUNT(*) as count FROM", table, 
                                        "WHERE Bid IS NOT NULL AND Ask IS NOT NULL AND Bid > 0 AND Ask > 0")
            valid_result <- dbGetQuery(connection_ref, valid_bidask_query)
            diagnostics <- c(diagnostics, paste("Valid Bid/Ask records:", format(valid_result$count, big.mark = ",")))
            diagnostics <- c(diagnostics, paste("Bid/Ask quality:", round(valid_result$count / count_result$count * 100, 1), "%"))
          }
          
          # Check structure
          structure_query <- paste("DESCRIBE", table)
          structure_result <- dbGetQuery(connection_ref, structure_query)
          diagnostics <- c(diagnostics, "Table structure:")
          diagnostics <- c(diagnostics, paste(structure_result$Field, structure_result$Type, sep = " (", collapse = ")\n"))
          
          # Check distinct pairs if applicable
          if ("pair" %in% structure_result$Field) {
            pairs_query <- paste("SELECT DISTINCT pair FROM", table)
            pairs_result <- dbGetQuery(connection_ref, pairs_query)
            diagnostics <- c(diagnostics, paste("Available pairs:", paste(pairs_result$pair, collapse = ", ")))
          }
          
          # Check date range
          if ("Timestamp" %in% structure_result$Field) {
            date_query <- paste("SELECT MIN(Timestamp) as min_date, MAX(Timestamp) as max_date FROM", table)
            date_result <- dbGetQuery(connection_ref, date_query)
            diagnostics <- c(diagnostics, paste("Date range:", date_result$min_date, "to", date_result$max_date))
          }
        } else {
          diagnostics <- c(diagnostics, "", paste("=== TABLE:", table, "==="))
          diagnostics <- c(diagnostics, "TABLE NOT FOUND")
        }
      }
      
      values$db_diagnostics <- paste(diagnostics, collapse = "\n")
      
    }, error = function(e) {
      values$db_diagnostics <- paste("Error running diagnostics:", e$message)
    })
  }
  
  # Enhanced data processing function with Bid/Ask filtering and Mid recalculation
  process_fx_data <- function(raw_data, level) {
    processing_steps <- c()
    
    processing_steps <- c(processing_steps, paste("Starting data processing at", Sys.time()))
    processing_steps <- c(processing_steps, paste("Input data shape:", nrow(raw_data), "rows x", ncol(raw_data), "cols"))
    processing_steps <- c(processing_steps, paste("Column names:", paste(names(raw_data), collapse = ", ")))
    
    # Step 1: Data type conversion
    tryCatch({
      data <- raw_data %>%
        mutate(
          Original_Mid = as.numeric(as.character(Mid)),
          Bid = as.numeric(as.character(Bid)), 
          Ask = as.numeric(as.character(Ask)),
          pair = as.character(pair),
          Timestamp = as.POSIXct(Timestamp)
        )
      
      processing_steps <- c(processing_steps, "✓ Data types converted successfully")
      processing_steps <- c(processing_steps, paste("Records after conversion:", nrow(data)))
      
    }, error = function(e) {
      processing_steps <- c(processing_steps, paste("✗ Data type conversion failed:", e$message))
      values$processing_log <- paste(processing_steps, collapse = "\n")
      stop("Data type conversion failed")
    })
    
    # Step 2: Filter for valid Bid/Ask data and recalculate Mid
    initial_count <- nrow(data)
    
    # Filter for valid numeric Bid and Ask values
    data <- data %>%
      filter(
        !is.na(Bid), !is.na(Ask), 
        !is.na(Timestamp),
        is.finite(Bid), is.finite(Ask),
        Bid > 0, Ask > 0,
        Ask > Bid  # Ensure Ask is higher than Bid (basic sanity check)
      ) %>%
      arrange(pair, Timestamp)
    
    valid_count <- nrow(data)
    filtered_count <- initial_count - valid_count
    
    processing_steps <- c(processing_steps, paste("✓ Filtered for valid Bid/Ask data:", initial_count, "->", valid_count, "records"))
    processing_steps <- c(processing_steps, paste("Records filtered out:", filtered_count, "(", round(filtered_count/initial_count*100, 1), "%)"))
    
    if (nrow(data) == 0) {
      processing_steps <- c(processing_steps, "✗ No valid records after Bid/Ask filtering")
      values$processing_log <- paste(processing_steps, collapse = "\n")
      stop("No valid records after Bid/Ask filtering")
    }
    
    # Step 3: Recalculate Mid as mean of Bid and Ask
    data <- data %>%
      mutate(
        Mid = (Bid + Ask) / 2,
        spread = Ask - Bid,
        spread_pct = (Ask - Bid) / Mid * 100,
        date = as.Date(Timestamp)
      )
    
    # Store comparison statistics
    if ("Original_Mid" %in% names(data)) {
      valid_original <- data %>% filter(!is.na(Original_Mid))
      if (nrow(valid_original) > 0) {
        mid_comparison <- valid_original %>%
          summarise(
            original_mean = mean(Original_Mid, na.rm = TRUE),
            calculated_mean = mean(Mid, na.rm = TRUE),
            max_difference = max(abs(Original_Mid - Mid), na.rm = TRUE),
            mean_difference = mean(abs(Original_Mid - Mid), na.rm = TRUE),
            correlation = cor(Original_Mid, Mid, use = "complete.obs")
          )
        values$original_vs_calculated_mid <- mid_comparison
      }
    }
    
    processing_steps <- c(processing_steps, "✓ Recalculated Mid prices as (Bid + Ask) / 2")
    processing_steps <- c(processing_steps, paste("Spread statistics: mean =", round(mean(data$spread_pct), 4), "%, max =", round(max(data$spread_pct), 4), "%"))
    
    # Store bid/ask statistics
    bid_ask_analysis <- data %>%
      summarise(
        records_with_valid_bidask = n(),
        mean_bid = mean(Bid, na.rm = TRUE),
        mean_ask = mean(Ask, na.rm = TRUE),
        mean_mid_calculated = mean(Mid, na.rm = TRUE),
        mean_spread_abs = mean(spread, na.rm = TRUE),
        mean_spread_pct = mean(spread_pct, na.rm = TRUE),
        max_spread_pct = max(spread_pct, na.rm = TRUE),
        min_spread_pct = min(spread_pct, na.rm = TRUE)
      )
    
    values$bid_ask_stats <- bid_ask_analysis
    
    # Step 4: Apply aggregation if requested
    if (level == "raw") {
      result <- data %>%
        group_by(pair) %>%
        mutate(
          returns = c(NA, diff(log(Mid))),
          returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
        ) %>%
        ungroup()
      
      processing_steps <- c(processing_steps, "✓ Calculated returns for raw data")
    } else {
      # Time-based aggregation for OHLC
      data <- data %>%
        mutate(
          year = year(Timestamp),
          month = month(Timestamp),
          day = day(Timestamp),
          hour = hour(Timestamp),
          minute = minute(Timestamp)
        )
      
      # Define grouping variables
      if (level == "5min") {
        data <- data %>% mutate(time_group = floor(minute / 5) * 5)
        group_vars <- c("pair", "year", "month", "day", "hour", "time_group")
      } else if (level == "15min") {
        data <- data %>% mutate(time_group = floor(minute / 15) * 15)
        group_vars <- c("pair", "year", "month", "day", "hour", "time_group")
      } else if (level == "hour") {
        group_vars <- c("pair", "year", "month", "day", "hour")
      } else if (level == "4hour") {
        data <- data %>% mutate(time_group = floor(hour / 4) * 4)
        group_vars <- c("pair", "year", "month", "day", "time_group")
      } else if (level == "day") {
        group_vars <- c("pair", "year", "month", "day")
      }
      
      # OHLC aggregation
      result <- data %>%
        group_by(across(all_of(group_vars))) %>%
        arrange(Timestamp, .by_group = TRUE) %>%
        summarise(
          Timestamp = first(Timestamp),
          date = as.Date(first(Timestamp)),
          Mid_Open = first(Mid),
          Mid_High = max(Mid, na.rm = TRUE),
          Mid_Low = min(Mid, na.rm = TRUE), 
          Mid_Close = last(Mid),
          Mid = last(Mid),
          Bid_Open = first(Bid),
          Bid_High = max(Bid, na.rm = TRUE),
          Bid_Low = min(Bid, na.rm = TRUE),
          Bid_Close = last(Bid),
          Bid = last(Bid),
          Ask_Open = first(Ask),
          Ask_High = max(Ask, na.rm = TRUE),
          Ask_Low = min(Ask, na.rm = TRUE),
          Ask_Close = last(Ask),
          Ask = last(Ask),
          spread = last(Ask) - last(Bid),
          spread_pct = (last(Ask) - last(Bid)) / last(Mid) * 100,
          avg_spread_pct = mean(spread_pct, na.rm = TRUE),
          record_count = n(),
          .groups = 'drop'
        ) %>%
        arrange(pair, Timestamp) %>%
        group_by(pair) %>%
        mutate(
          returns = c(NA, diff(log(Mid_Close))),
          returns_pct = c(NA, diff(Mid_Close) / head(Mid_Close, -1) * 100)
        ) %>%
        ungroup()
      
      processing_steps <- c(processing_steps, paste("✓ Applied", level, "aggregation:", nrow(data), "->", nrow(result), "records"))
    }
    
    processing_steps <- c(processing_steps, paste("Processing completed at", Sys.time()))
    processing_steps <- c(processing_steps, paste("Final data shape:", nrow(result), "rows x", ncol(result), "cols"))
    
    values$processing_log <- paste(processing_steps, collapse = "\n")
    return(result)
  }
  
  # Test database connection
  observeEvent(input$testConnection, {
    if (input$password == "") {
      log_error("Password is required", "Connection Test", "", 
                list(host = input$host, port = input$port, dbname = input$dbname, username = input$username))
      
      output$connectionStatus <- renderUI({
        div(class = "connection-error", h5("Connection Failed"), p("Password is required."))
      })
      return()
    }
    
    tryCatch({
      # Close existing connection
      if (!is.null(connection_ref)) {
        dbDisconnect(connection_ref)
      }
      
      # Establish new connection
      connection_ref <<- dbConnect(
        RMySQL::MySQL(),
        host = as.character(input$host),
        port = as.numeric(input$port),
        dbname = as.character(input$dbname),
        username = as.character(input$username),
        password = as.character(input$password)
      )
      
      values$connection <- connection_ref
      
      # Test connection
      test_query <- "SELECT 1 as test"
      test_result <- dbGetQuery(connection_ref, test_query)
      
      if (nrow(test_result) == 1) {
        values$connected <- TRUE
        values$show_detailed_error <- FALSE
        
        # Run diagnostics
        run_db_diagnostics()
        
        output$connectionStatus <- renderUI({
          div(class = "connection-success",
              h5("Connection Successful"),
              p(paste("Connected to", input$dbname, "on", input$host)))
        })
        showNotification("Database connection established!", type = "message")
      }
      
    }, error = function(e) {
      values$connected <- FALSE
      values$connection <- NULL
      connection_ref <<- NULL
      
      log_error(e$message, "Database Connection", "", 
                list(host = input$host, port = input$port, dbname = input$dbname, username = input$username))
      
      output$connectionStatus <- renderUI({
        div(class = "connection-error", h5("Connection Failed"), p("Error:", e$message))
      })
      showNotification(paste("Connection failed:", e$message), type = "error")
    })
  })
  
  # Close connections
  observeEvent(input$closeConnections, {
    tryCatch({
      if (!is.null(connection_ref)) {
        dbDisconnect(connection_ref)
        connection_ref <<- NULL
      }
      
      values$connected <- FALSE
      values$connection <- NULL
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      values$source_table <- NULL
      values$show_detailed_error <- FALSE
      
      output$connectionStatus <- renderUI({
        div(class = "connection-success", h5("Connections Closed"), 
            p("All database connections have been closed successfully."))
      })
      
      showNotification("All database connections closed successfully!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error closing connections:", e$message), type = "error")
    })
  })
  
  # Output connection status
  output$connectionValid <- reactive({
    values$connected
  })
  outputOptions(output, "connectionValid", suspendWhenHidden = FALSE)
  
  # Output detailed error status
  output$showDetailedError <- reactive({
    values$show_detailed_error
  })
  outputOptions(output, "showDetailedError", suspendWhenHidden = FALSE)
  
  # Database statistics
  output$dbStats <- renderText({
    if (!values$connected || is.null(connection_ref)) return("No connection established")
    
    tryCatch({
      tables <- dbListTables(connection_ref)
      stats_text <- paste("Available tables:", paste(tables, collapse = ", "), "\n")
      
      if ("fx_spot_prices" %in% tables) {
        row_count <- dbGetQuery(connection_ref, "SELECT COUNT(*) as count FROM fx_spot_prices")
        valid_bidask_count <- dbGetQuery(connection_ref, "SELECT COUNT(*) as count FROM fx_spot_prices WHERE Bid IS NOT NULL AND Ask IS NOT NULL AND Bid > 0 AND Ask > 0")
        stats_text <- paste(stats_text, paste("fx_spot_prices total records:", format(row_count$count, big.mark = ",")), "\n")
        stats_text <- paste(stats_text, paste("fx_spot_prices valid Bid/Ask:", format(valid_bidask_count$count, big.mark = ","), 
                                              "(", round(valid_bidask_count$count/row_count$count*100, 1), "%)"), "\n")
      }
      
      if ("fx_spot_prices_daily" %in% tables) {
        row_count_daily <- dbGetQuery(connection_ref, "SELECT COUNT(*) as count FROM fx_spot_prices_daily")
        stats_text <- paste(stats_text, paste("fx_spot_prices_daily records:", format(row_count_daily$count, big.mark = ",")), "\n")
      }
      
      return(stats_text)
      
    }, error = function(e) {
      return(paste("Error getting table info:", e$message))
    })
  })
  
  # Enhanced data loading with Bid/Ask filtering
  observeEvent(input$loadData, {
    
    # Reset error states
    values$show_detailed_error <- FALSE
    values$last_error <- NULL
    values$detailed_error_info <- NULL
    values$sql_log <- ""
    
    # Validate prerequisites
    if (!values$connected || is.null(connection_ref)) {
      log_error("No database connection established", "Data Loading Prerequisites", "", 
                list(connected = values$connected, connection_null = is.null(connection_ref)))
      
      output$dataStatus <- renderUI({
        div(class = "connection-error", h5("Connection Error"), 
            p("No database connection established."))
      })
      return()
    }
    
    if (is.null(input$sourceTable)) {
      log_error("No source table selected", "Data Loading Prerequisites", "", 
                list(sourceTable = input$sourceTable))
      
      output$dataStatus <- renderUI({
        div(class = "connection-error", h5("Source Table Error"), 
            p("No source table selected."))
      })
      return()
    }
    
    tryCatch({
      showNotification("Starting enhanced data load with Bid/Ask filtering...", type = "message")
      
      raw_data <- NULL
      
      if (input$sourceTable == "fx_spot_prices_daily") {
        
        showNotification("Loading daily data with Bid/Ask filtering...", type = "message")
        
        # Test table existence first
        table_check_query <- "SHOW TABLES LIKE 'fx_spot_prices_daily'"
        table_exists <- dbGetQuery(connection_ref, table_check_query)
        
        if (nrow(table_exists) == 0) {
          log_error("Table 'fx_spot_prices_daily' does not exist", "Daily Data Loading", table_check_query, 
                    list(available_tables = paste(dbListTables(connection_ref), collapse = ", ")))
          return()
        }
        
        # Main data query with Bid/Ask filtering
        main_query <- "SELECT * FROM fx_spot_prices_daily 
                      WHERE Bid IS NOT NULL AND Ask IS NOT NULL 
                      AND Bid > 0 AND Ask > 0 AND Ask > Bid
                      ORDER BY Timestamp DESC, pair 
                      LIMIT 10000"
        
        raw_data <- dbGetQuery(connection_ref, main_query)
        values$source_table <- "fx_spot_prices_daily"
        
        # Log successful data query
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", main_query),
                                paste("Status: SUCCESS"),
                                paste("Records retrieved:", nrow(raw_data)),
                                "---", 
                                sep = "\n")
        
      } else if (input$sourceTable == "fx_spot_prices") {
        
        # Validate intraday inputs
        if (is.null(input$intradayPair) || input$intradayPair == "" ||
            is.null(input$dayRange) || is.na(input$dayRange) ||
            is.null(input$aggregationLevel) || input$aggregationLevel == "") {
          log_error("Missing required parameters for intraday data", "Intraday Data Loading", "", 
                    list(intradayPair = input$intradayPair, dayRange = input$dayRange, aggregationLevel = input$aggregationLevel))
          
          output$dataStatus <- renderUI({
            div(class = "connection-error", h5("Missing Parameters"), 
                p("Please select currency pair, day range, and aggregation level."))
          })
          return()
        }
        
        showNotification(paste("Loading", input$intradayPair, "data for", input$dayRange, "days with Bid/Ask filtering..."), type = "message")
        
        # Test table existence
        table_check_query <- "SHOW TABLES LIKE 'fx_spot_prices'"
        table_exists <- dbGetQuery(connection_ref, table_check_query)
        
        if (nrow(table_exists) == 0) {
          log_error("Table 'fx_spot_prices' does not exist", "Intraday Data Loading", table_check_query, 
                    list(available_tables = paste(dbListTables(connection_ref), collapse = ", ")))
          return()
        }
        
        # Check if pair exists with valid Bid/Ask data
        pair_check_query <- paste0("SELECT COUNT(*) as count FROM fx_spot_prices 
                                   WHERE pair = '", input$intradayPair, "' 
                                   AND Bid IS NOT NULL AND Ask IS NOT NULL 
                                   AND Bid > 0 AND Ask > 0 AND Ask > Bid")
        pair_count <- dbGetQuery(connection_ref, pair_check_query)
        
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", pair_check_query),
                                paste("Status: SUCCESS"),
                                paste("Valid records found for pair:", pair_count$count),
                                "---", 
                                sep = "\n")
        
        if (pair_count$count == 0) {
          # Get available pairs with valid data
          available_pairs_query <- "SELECT DISTINCT pair, COUNT(*) as valid_records 
                                   FROM fx_spot_prices 
                                   WHERE Bid IS NOT NULL AND Ask IS NOT NULL 
                                   AND Bid > 0 AND Ask > 0 AND Ask > Bid
                                   GROUP BY pair 
                                   ORDER BY valid_records DESC 
                                   LIMIT 10"
          available_pairs <- dbGetQuery(connection_ref, available_pairs_query)
          
          log_error(paste("No valid Bid/Ask data found for pair:", input$intradayPair), "Intraday Data Loading", pair_check_query, 
                    list(available_pairs_with_data = paste(available_pairs$pair, " (", available_pairs$valid_records, " records)", collapse = ", ")))
          
          output$dataStatus <- renderUI({
            div(class = "connection-error", h5("No Valid Data Found"), 
                p(paste("No valid Bid/Ask data found for pair:", input$intradayPair)),
                p(paste("Pairs with valid data:", paste(available_pairs$pair, collapse = ", "))))
          })
          return()
        }
        
        # Get available dates for the pair with valid Bid/Ask data
        dates_query <- paste0("
          SELECT DISTINCT DATE(Timestamp) as date_only, COUNT(*) as records_per_day
          FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "'
          AND Bid IS NOT NULL AND Ask IS NOT NULL 
          AND Bid > 0 AND Ask > 0 AND Ask > Bid
          GROUP BY DATE(Timestamp)
          ORDER BY DATE(Timestamp) DESC 
          LIMIT ", input$dayRange)
        
        last_dates <- dbGetQuery(connection_ref, dates_query)
        
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", dates_query),
                                paste("Status: SUCCESS"),
                                paste("Valid dates found:", nrow(last_dates)),
                                paste("Total valid records:", sum(last_dates$records_per_day)),
                                "---", 
                                sep = "\n")
        
        if (nrow(last_dates) == 0) {
          log_error("No dates with valid Bid/Ask data found for the specified pair", "Intraday Data Loading", dates_query, 
                    list(pair = input$intradayPair, dayRange = input$dayRange))
          
          output$dataStatus <- renderUI({
            div(class = "connection-error", h5("No Valid Data Found"), 
                p(paste("No dates with valid Bid/Ask data found for pair:", input$intradayPair)))
          })
          return()
        }
        
        # Get raw data for the selected dates with Bid/Ask filtering
        date_list <- paste0("'", last_dates$date_only, "'", collapse = ", ")
        data_query <- paste0("
          SELECT * FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "' 
          AND DATE(Timestamp) IN (", date_list, ")
          AND Bid IS NOT NULL AND Ask IS NOT NULL 
          AND Bid > 0 AND Ask > 0 AND Ask > Bid
          ORDER BY Timestamp
          LIMIT 50000
        ")
        
        raw_data <- dbGetQuery(connection_ref, data_query)
        values$source_table <- "fx_spot_prices"
        
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", data_query),
                                paste("Status: SUCCESS"),
                                paste("Filtered records retrieved:", nrow(raw_data)),
                                paste("Date range:", min(last_dates$date_only), "to", max(last_dates$date_only)),
                                "---", 
                                sep = "\n")
      }
      
      # Validate raw data
      if (is.null(raw_data) || nrow(raw_data) == 0) {
        log_error("Query executed successfully but returned no valid Bid/Ask records", "Data Validation", "", 
                  list(source_table = input$sourceTable, query_result_rows = ifelse(is.null(raw_data), "NULL", nrow(raw_data))))
        
        output$dataStatus <- renderUI({
          div(class = "connection-error", h5("No Valid Data Returned"), 
              p("Query executed successfully but returned no records with valid Bid/Ask data."))
        })
        return()
      }
      
      # Check required columns
      required_cols <- c("Timestamp", "Mid", "Bid", "Ask", "pair")
      missing_cols <- setdiff(required_cols, names(raw_data))
      if (length(missing_cols) > 0) {
        log_error("Missing required columns in data", "Data Structure Validation", "", 
                  list(missing_columns = paste(missing_cols, collapse = ", "), 
                       available_columns = paste(names(raw_data), collapse = ", ")))
        
        output$dataStatus <- renderUI({
          div(class = "connection-error", h5("Data Structure Error"), 
              p(paste("Missing required columns:", paste(missing_cols, collapse = ", "))))
        })
        return()
      }
      
      showNotification(paste("Retrieved", nrow(raw_data), "records with valid Bid/Ask. Processing..."), type = "message")
      
      # Process data with enhanced Bid/Ask handling
      aggregation_level <- ifelse(values$source_table == "fx_spot_prices", input$aggregationLevel, "raw")
      processed_data <- process_fx_data(raw_data, aggregation_level)
      
      if (is.null(processed_data) || nrow(processed_data) == 0) {
        log_error("No valid data after processing", "Data Processing", "", 
                  list(raw_data_rows = nrow(raw_data), processed_data_rows = 0))
        
        output$dataStatus <- renderUI({
          div(class = "connection-error", h5("Data Processing Failed"), 
              p("No valid data after processing."))
        })
        return()
      }
      
      # Store processed data
      values$fx_data <- processed_data
      values$data_loaded <- TRUE
      values$show_detailed_error <- FALSE
      
      # Update currency pair choices
      available_pairs <- sort(unique(processed_data$pair))
      updateSelectInput(session, "selectedPair", 
                        choices = available_pairs,
                        selected = available_pairs[1])
      
      # Success status
      output$dataStatus <- renderUI({
        div(class = "connection-success",
            h5("Data Loaded with Bid/Ask Filtering"),
            p(paste("Source:", values$source_table)),
            p(paste("Valid Bid/Ask records retrieved:", nrow(raw_data))),
            p(paste("Final processed records:", nrow(processed_data))),
            if (values$source_table == "fx_spot_prices") {
              p(paste("Aggregation level:", input$aggregationLevel))
            } else {
              p("Daily data - no aggregation applied")
            },
            p(paste("Currency pairs:", paste(available_pairs, collapse = ", "))),
            p(paste("Date range:", min(processed_data$date, na.rm = TRUE), "to", max(processed_data$date, na.rm = TRUE))),
            p("✓ All Mid prices recalculated as (Bid + Ask) / 2", style = "color: #27ae60; font-weight: bold;"))
      })
      
      showNotification(paste("Successfully processed", nrow(processed_data), "records with recalculated Mid prices"), type = "message")
      
    }, error = function(e) {
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      
      log_error(e$message, "Data Loading Process", "", 
                list(source_table = input$sourceTable, 
                     stage = "Main processing loop"))
      
      output$dataStatus <- renderUI({
        div(class = "connection-error", h5("Data Loading Failed"), 
            p(paste("Error:", e$message)))
      })
      
      showNotification(paste("Data loading failed:", e$message), type = "error")
    })
  })
  
  # Output data loaded status
  output$dataLoaded <- reactive({
    values$data_loaded
  })
  outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  
  # Detailed error outputs
  output$detailedErrorInfo <- renderText({
    if (is.null(values$detailed_error_info)) {
      "No detailed error information available"
    } else {
      values$detailed_error_info
    }
  })
  
  output$databaseDiagnostics <- renderText({
    if (is.null(values$db_diagnostics)) {
      "Click 'Test Connection' to run database diagnostics"
    } else {
      values$db_diagnostics
    }
  })
  
  output$sqlExecutionLog <- renderText({
    if (is.null(values$sql_log) || values$sql_log == "") {
      "No SQL queries executed yet. Click 'Load Data' to see query execution details."
    } else {
      values$sql_log
    }
  })
  
  # Data extraction overview outputs
  output$rawDataQuality <- renderText({
    if (is.null(values$fx_data)) return("No data loaded")
    
    data <- values$fx_data
    paste(
      paste("Records loaded:", nrow(data)),
      paste("Memory usage:", format(object.size(data), units = "Mb")),
      paste("Source table:", values$source_table),
      "",
      "✓ All records have valid Bid/Ask data",
      "✓ Bid < Ask validation passed",
      "✓ No NULL or zero price values",
      sep = "\n"
    )
  })
  
  output$bidAskProcessing <- renderText({
    if (is.null(values$bid_ask_stats)) return("No Bid/Ask statistics available")
    
    stats <- values$bid_ask_stats
    comparison <- values$original_vs_calculated_mid
    
    result <- paste(
      paste("Valid Bid/Ask records:", stats$records_with_valid_bidask),
      paste("Mean Bid:", round(stats$mean_bid, 6)),
      paste("Mean Ask:", round(stats$mean_ask, 6)),
      paste("Mean spread:", round(stats$mean_spread_pct, 4), "%"),
      paste("Max spread:", round(stats$max_spread_pct, 4), "%"),
      "",
      "✓ Mid = (Bid + Ask) / 2 applied",
      sep = "\n"
    )
    
    if (!is.null(comparison)) {
      result <- paste(result, 
                      "",
                      "Original vs Calculated Mid:",
                      paste("Correlation:", round(comparison$correlation, 4)),
                      paste("Max difference:", round(comparison$max_difference, 6)),
                      sep = "\n")
    }
    
    result
  })
  
  output$finalDataSummary <- renderText({
    if (is.null(values$fx_data)) return("No data loaded")
    
    data <- values$fx_data
    
    paste(
      paste("Final records:", nrow(data)),
      paste("Currency pairs:", paste(unique(data$pair), collapse = ", ")),
      paste("Date range:", min(data$date, na.rm = TRUE), "to", max(data$date, na.rm = TRUE)),
      paste("Columns:", ncol(data)),
      "",
      "Data Quality:",
      paste("✓ Price range:", round(max(data$Mid, na.rm = TRUE) - min(data$Mid, na.rm = TRUE), 6)),
      paste("✓ Returns available:", sum(!is.na(data$returns))),
      ifelse("Mid_High" %in% names(data), paste("✓ OHLC data available"), "✓ Tick data format"),
      sep = "\n"
    )
  })
  
  # Filter data for selected pair
  pair_data <- reactive({
    req(values$fx_data, input$selectedPair)
    values$fx_data %>% filter(pair == input$selectedPair)
  })
  
  # Data preview
  output$dataPreview <- DT::renderDataTable({
    req(values$fx_data)
    
    preview_cols <- c("date", "Timestamp", "pair", "Bid", "Ask", "Mid", "spread_pct")
    if ("Mid_High" %in% names(values$fx_data)) {
      preview_cols <- c(preview_cols, "Mid_Open", "Mid_High", "Mid_Low", "Mid_Close")
    }
    if ("returns" %in% names(values$fx_data)) {
      preview_cols <- c(preview_cols, "returns", "returns_pct")
    }
    
    preview_data <- values$fx_data %>% 
      select(any_of(preview_cols)) %>%
      head(20)
    
    datatable(preview_data, options = list(scrollX = TRUE, pageLength = 15, dom = 'frtip')) %>%
      formatRound(columns = c("Mid", "Bid", "Ask", "Mid_Open", "Mid_High", "Mid_Low", "Mid_Close"), digits = 6) %>%
      formatRound(columns = c("spread_pct", "returns", "returns_pct"), digits = 4)
  })
  
  output$priceRangeStats <- renderText({
    req(values$fx_data)
    data <- values$fx_data
    
    price_stats <- data %>%
      summarise(
        mid_min = min(Mid, na.rm = TRUE),
        mid_max = max(Mid, na.rm = TRUE),
        bid_min = min(Bid, na.rm = TRUE),
        bid_max = max(Bid, na.rm = TRUE),
        ask_min = min(Ask, na.rm = TRUE),
        ask_max = max(Ask, na.rm = TRUE)
      )
    
    paste(
      "Mid Price Range:",
      paste("Min:", round(price_stats$mid_min, 6)),
      paste("Max:", round(price_stats$mid_max, 6)),
      paste("Range:", round(price_stats$mid_max - price_stats$mid_min, 6)),
      "",
      "Bid Price Range:",
      paste("Min:", round(price_stats$bid_min, 6)),
      paste("Max:", round(price_stats$bid_max, 6)),
      "",
      "Ask Price Range:",
      paste("Min:", round(price_stats$ask_min, 6)),
      paste("Max:", round(price_stats$ask_max, 6)),
      sep = "\n"
    )
  })
  
  output$dataCoverageStats <- renderText({
    req(values$fx_data)
    data <- values$fx_data
    
    coverage_stats <- data %>%
      group_by(pair) %>%
      summarise(
        records = n(),
        date_span = as.numeric(max(date, na.rm = TRUE) - min(date, na.rm = TRUE)) + 1,
        .groups = 'drop'
      )
    
    paste(
      "Coverage by Pair:",
      paste(coverage_stats$pair, ": ", coverage_stats$records, " records (", coverage_stats$date_span, " days)", sep = "", collapse = "\n"),
      "",
      paste("Total pairs:", nrow(coverage_stats)),
      paste("Total records:", sum(coverage_stats$records)),
      paste("Average records/pair:", round(mean(coverage_stats$records), 1)),
      sep = "\n"
    )
  })
  
  # MARKET OVERVIEW TAB OUTPUTS
  
  # Data quality info for market overview
  output$dataQualityInfo <- renderText({
    req(values$fx_data)
    paste("All prices filtered for valid Bid/Ask data | Mid = (Bid + Ask) / 2 | Records:", nrow(values$fx_data))
  })
  
  # Value boxes
  output$currentPrice <- renderValueBox({
    req(pair_data())
    current_data <- pair_data() %>% slice_tail(n = 1)
    valueBox(
      value = format(round(current_data$Mid, 6), nsmall = 6),
      subtitle = paste("Current", input$selectedPair, "(Calculated Mid)"),
      icon = icon("calculator"),
      color = "blue"
    )
  })
  
  output$dailyChange <- renderValueBox({
    req(pair_data())
    recent_data <- pair_data() %>% slice_tail(n = 2)
    if (nrow(recent_data) >= 2) {
      change <- (recent_data$Mid[2] - recent_data$Mid[1]) / recent_data$Mid[1] * 100
      color <- ifelse(change > 0, "green", "red")
      icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
    } else {
      change <- 0
      color <- "yellow"
      icon_name <- "minus"
    }
    
    valueBox(
      value = paste0(ifelse(change > 0, "+", ""), format(round(change, 4), nsmall = 4), "%"),
      subtitle = "Period Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  output$bidAskSpread <- renderValueBox({
    req(pair_data())
    data <- pair_data()
    avg_spread <- mean(data$spread_pct, na.rm = TRUE)
    
    valueBox(
      value = paste0(format(round(avg_spread, 3), nsmall = 3), "%"),
      subtitle = "Average Bid-Ask Spread",
      icon = icon("arrows-left-right"),
      color = "yellow"
    )
  })
  
  output$dataRange <- renderValueBox({
    req(pair_data())
    data_range <- pair_data() %>%
      summarise(
        days = as.numeric(max(date, na.rm = TRUE) - min(date, na.rm = TRUE)) + 1,
        records = n()
      )
    
    valueBox(
      value = paste(data_range$records, "records"),
      subtitle = paste(data_range$days, "days coverage"),
      icon = icon("calendar"),
      color = "purple"
    )
  })
  
  # Main price chart
  output$overviewChart <- renderPlotly({
    req(pair_data())
    
    data <- pair_data()
    main_price <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    bid_price <- if ("Bid_Close" %in% names(data)) data$Bid_Close else data$Bid
    ask_price <- if ("Ask_Close" %in% names(data)) data$Ask_Close else data$Ask
    
    price_range <- max(main_price, na.rm = TRUE) - min(main_price, na.rm = TRUE)
    
    p <- plot_ly(data, x = ~Timestamp) %>%
      layout(
        title = paste(input$selectedPair, "| Records:", nrow(data), "| Range:", format(price_range, digits = 6), "| Mid = (Bid + Ask) / 2"),
        xaxis = list(title = "Date/Time"),
        yaxis = list(title = "Exchange Rate", tickformat = ".6f"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    if ("Mid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = main_price, name = "Mid Price (Calculated)", 
                           line = list(color = "#2c3e50", width = 3),
                           hovertemplate = "Mid: %{y:.6f}<extra></extra>")
    }
    if ("Bid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = bid_price, name = "Bid Price", 
                           line = list(color = "#27ae60", width = 2),
                           hovertemplate = "Bid: %{y:.6f}<extra></extra>")
    }
    if ("Ask" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ask_price, name = "Ask Price", 
                           line = list(color = "#e74c3c", width = 2),
                           hovertemplate = "Ask: %{y:.6f}<extra></extra>")
    }
    if (input$showSpread) {
      p <- p %>% add_lines(y = ~spread_pct, name = "Spread %", yaxis = "y2",
                           line = list(color = "#f39c12", width = 2, dash = "dot"),
                           hovertemplate = "Spread: %{y:.4f}%<extra></extra>") %>%
        layout(yaxis2 = list(overlaying = "y", side = "right", title = "Spread %"))
    }
    if (input$showMovingAvg && "Mid" %in% input$priceComponents && nrow(data) > 20) {
      ma20 <- SMA(main_price, n = 20)
      p <- p %>% add_lines(y = ma20, name = "MA(20)", 
                           line = list(color = "#9b59b6", width = 2, dash = "dash"),
                           hovertemplate = "MA(20): %{y:.6f}<extra></extra>")
    }
    
    p
  })
  
  # Market statistics table 
  output$marketStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    stats <- data.frame(
      Metric = c("Current", "Mean", "Median", "Min", "Max", "Range", "Std Dev", "CV (%)"),
      Value = c(
        format(round(tail(price_series, 1), 6), nsmall = 6),
        format(round(mean(price_series, na.rm = TRUE), 6), nsmall = 6),
        format(round(median(price_series, na.rm = TRUE), 6), nsmall = 6),
        format(round(min(price_series, na.rm = TRUE), 6), nsmall = 6),
        format(round(max(price_series, na.rm = TRUE), 6), nsmall = 6),
        format(round(max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE), 6), nsmall = 6),
        format(round(sd(price_series, na.rm = TRUE), 6), nsmall = 6),
        paste0(round(sd(price_series, na.rm = TRUE) / mean(price_series, na.rm = TRUE) * 100, 3), "%")
      ),
      stringsAsFactors = FALSE
    )
    
    datatable(stats, 
              options = list(
                dom = 't', 
                pageLength = 10,
                scrollX = FALSE,
                scrollY = "300px",
                columnDefs = list(
                  list(className = 'dt-left', targets = 0),
                  list(className = 'dt-right', targets = 1),
                  list(width = '50%', targets = 0),
                  list(width = '50%', targets = 1)
                )
              ), 
              rownames = FALSE,
              class = 'cell-border compact') %>%
      formatStyle(columns = 1:2, fontSize = '12px') %>%
      formatStyle(columns = "Value", textAlign = "right")
  })
  
  # Bid-Ask statistics table 
  output$bidAskStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    # Create shorter metric names to fit better
    stats <- data.frame(
      Metric = c("Avg Spread ($)", "Avg Spread (%)", "Min Spread (%)", "Max Spread (%)", 
                 "Spread Std", "Spread CV (%)", "Tight (<0.01%)", "Wide (>0.1%)"),
      Value = c(
        format(round(mean(data$spread, na.rm = TRUE), 6), nsmall = 6),
        paste0(round(mean(data$spread_pct, na.rm = TRUE), 4), "%"),
        paste0(round(min(data$spread_pct, na.rm = TRUE), 4), "%"),
        paste0(round(max(data$spread_pct, na.rm = TRUE), 4), "%"),
        round(sd(data$spread_pct, na.rm = TRUE), 4),
        paste0(round(sd(data$spread_pct, na.rm = TRUE) / mean(data$spread_pct, na.rm = TRUE) * 100, 2), "%"),
        paste0(round(sum(data$spread_pct < 0.01, na.rm = TRUE) / nrow(data) * 100, 1), "%"),
        paste0(round(sum(data$spread_pct > 0.1, na.rm = TRUE) / nrow(data) * 100, 1), "%")
      ),
      stringsAsFactors = FALSE
    )
    
    datatable(stats, 
              options = list(
                dom = 't', 
                pageLength = 10,
                scrollX = FALSE,
                scrollY = "300px",
                columnDefs = list(
                  list(className = 'dt-left', targets = 0),
                  list(className = 'dt-right', targets = 1),
                  list(width = '50%', targets = 0),
                  list(width = '50%', targets = 1)
                )
              ), 
              rownames = FALSE,
              class = 'cell-border compact') %>%
      formatStyle(columns = 1:2, fontSize = '12px') %>%
      formatStyle(columns = "Value", textAlign = "right")
  })
  
  # Price movement statistics
  output$priceMovementStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    if ("returns" %in% names(data) && sum(!is.na(data$returns)) > 0) {
      movement_stats <- data %>%
        summarise(
          Valid_Returns = sum(!is.na(returns)),
          Mean_Return = round(mean(returns, na.rm = TRUE) * 100, 6),
          Return_Volatility = round(sd(returns, na.rm = TRUE) * 100, 6),
          Max_Positive_Return = round(max(returns, na.rm = TRUE) * 100, 6),
          Max_Negative_Return = round(min(returns, na.rm = TRUE) * 100, 6),
          Annualized_Vol = round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 3)
        ) %>%
        pivot_longer(everything(), names_to = "Metric", values_to = "Value")
    } else {
      movement_stats <- data.frame(
        Metric = c("Returns_Available", "Data_Type"),
        Value = c("No", "Static or single record")
      )
    }
    
    datatable(movement_stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  # Spread chart
  output$spreadChart <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < 2) {
      return(plot_ly() %>% layout(title = "Insufficient data for spread chart", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    plot_ly(data, x = ~Timestamp, y = ~spread_pct, type = "scatter", mode = "lines",
            line = list(color = "#f39c12", width = 2)) %>%
      layout(
        title = paste("Bid-Ask Spread Over Time -", input$selectedPair),
        xaxis = list(title = "Date/Time"),
        yaxis = list(title = "Spread (%)", tickformat = ".4f"),
        hovermode = "x",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        hovertemplate = "Spread: %{y:.4f}%<br>Date: %{x}<extra></extra>"
      )
  })
  
  # Price distribution
  output$priceDistribution <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < 2) {
      return(plot_ly() %>% layout(title = "Insufficient data for distribution", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    # Create histogram of Mid prices
    p1 <- plot_ly(x = ~data$Mid, type = "histogram", nbinsx = 30, 
                  name = "Mid Price", marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = paste("Price Distribution -", input$selectedPair),
        xaxis = list(title = "Mid Price", tickformat = ".6f"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = TRUE
      )
    
    # Add Bid and Ask distributions if there's variation
    bid_range <- max(data$Bid) - min(data$Bid)
    ask_range <- max(data$Ask) - min(data$Ask)
    
    if (bid_range > 0 && ask_range > 0) {
      p1 <- p1 %>%
        add_histogram(x = ~data$Bid, name = "Bid Price", 
                      marker = list(color = "#27ae60", opacity = 0.5), nbinsx = 30) %>%
        add_histogram(x = ~data$Ask, name = "Ask Price", 
                      marker = list(color = "#e74c3c", opacity = 0.5), nbinsx = 30)
    }
    
    p1
  })
  
  # Server Functions for Price Analysis Tab 
  
  # Price analysis data info
  output$priceAnalysisDataInfo <- renderText({
    if (!values$data_loaded) return("No data loaded")
    
    unique_pairs <- unique(values$fx_data$pair)
    total_records <- nrow(values$fx_data)
    
    paste(
      paste("Source:", values$source_table),
      paste("Pairs:", length(unique_pairs)),
      paste("Records:", format(total_records, big.mark = ",")),
      "✓ Mid = (Bid + Ask) / 2",
      sep = "\n"
    )
  })
  
  # Check for OHLC analysis availability
  output$showOHLCAnalysis <- reactive({
    if (!values$data_loaded) return(FALSE)
    
    # Check if OHLC columns are available (aggregated data)
    ohlc_cols <- c("Mid_Open", "Mid_High", "Mid_Low", "Mid_Close")
    return(all(ohlc_cols %in% names(values$fx_data)))
  })
  outputOptions(output, "showOHLCAnalysis", suspendWhenHidden = FALSE)
  
  # Check for intraperiod analysis
  output$showIntraperiodAnalysis <- reactive({
    if (!values$data_loaded) return(FALSE)
    
    # Show intraperiod analysis for fx_spot_prices with aggregation
    return(values$source_table == "fx_spot_prices" && "record_count" %in% names(values$fx_data))
  })
  outputOptions(output, "showIntraperiodAnalysis", suspendWhenHidden = FALSE)
  
  # Update date range when data loads
  observe({
    if (values$data_loaded && !is.null(values$fx_data)) {
      date_range <- range(values$fx_data$date, na.rm = TRUE)
      updateDateRangeInput(session, "priceRange",
                           start = max(date_range[1], date_range[2] - years(1)),
                           end = date_range[2],
                           min = date_range[1],
                           max = date_range[2])
    }
  })
  
  # Price statistics
  output$priceStats <- renderText({
    req(pair_data())
    
    # Filter data for selected date range
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) return("No data available for selected range")
    
    # Use appropriate price series
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    # Calculate comprehensive statistics
    current_price <- tail(price_series, 1)
    period_high <- max(price_series, na.rm = TRUE)
    period_low <- min(price_series, na.rm = TRUE)
    period_avg <- mean(price_series, na.rm = TRUE)
    price_range <- period_high - period_low
    
    # Volatility metrics
    if ("returns" %in% names(data) && sum(!is.na(data$returns)) > 10) {
      returns <- data$returns[!is.na(data$returns)]
      daily_vol <- sd(returns, na.rm = TRUE)
      annual_vol <- daily_vol * sqrt(252)
      max_gain <- max(returns, na.rm = TRUE) * 100
      max_loss <- min(returns, na.rm = TRUE) * 100
      
      vol_info <- paste(
        paste("Daily Volatility:", paste0(round(daily_vol * 100, 4), "%")),
        paste("Annualized Volatility:", paste0(round(annual_vol * 100, 2), "%")),
        paste("Max Daily Gain:", paste0(round(max_gain, 4), "%")),
        paste("Max Daily Loss:", paste0(round(max_loss, 4), "%")),
        sep = " | "
      )
    } else {
      vol_info <- "Volatility: N/A (insufficient return data)"
    }
    
    # Spread statistics
    avg_spread <- mean(data$spread_pct, na.rm = TRUE)
    spread_range <- max(data$spread_pct, na.rm = TRUE) - min(data$spread_pct, na.rm = TRUE)
    
    paste(
      paste("Analysis Period:", input$priceRange[1], "to", input$priceRange[2], "|", nrow(data), "observations"),
      paste("Current Price:", round(current_price, 6), "| Period High:", round(period_high, 6), 
            "| Period Low:", round(period_low, 6), "| Average:", round(period_avg, 6)),
      paste("Price Range:", round(price_range, 6), "| Range %:", paste0(round(price_range/period_avg*100, 3), "%")),
      paste("Avg Spread:", paste0(round(avg_spread, 4), "%"), "| Spread Range:", paste0(round(spread_range, 4), "%")),
      vol_info,
      sep = "\n"
    )
  })
  
  # Detailed price chart
  output$detailedPriceChart <- renderPlotly({
    req(pair_data())
    
    # Filter data for selected date range
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2]) %>%
      arrange(Timestamp)
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available for selected date range"))
    }
    
    # Calculate technical indicators
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    if (nrow(data) >= input$movingAvgDays) {
      data$ma <- SMA(price_series, n = input$movingAvgDays)
    }
    
    if (input$showBollingerBands && nrow(data) >= input$bbPeriods) {
      bb <- BBands(price_series, n = input$bbPeriods)
      data$bb_upper <- bb[, "up"]
      data$bb_lower <- bb[, "dn"]
      data$bb_mavg <- bb[, "mavg"]
    }
    
    # Create base plot
    p <- plot_ly(data, x = ~Timestamp) %>%
      layout(
        title = paste("Detailed Price Analysis -", input$selectedPair, "| Period:", 
                      input$priceRange[1], "to", input$priceRange[2], "| Records:", nrow(data)),
        xaxis = list(title = "Date/Time"),
        yaxis = list(title = "Exchange Rate", tickformat = ".6f"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add selected price components
    if ("mid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = price_series, name = "Mid Price (Calculated)", 
                           line = list(color = "#2c3e50", width = 3))
    }
    if ("bid" %in% input$priceComponents) {
      bid_price <- if ("Bid_Close" %in% names(data)) data$Bid_Close else data$Bid
      p <- p %>% add_lines(y = bid_price, name = "Bid Price", 
                           line = list(color = "#27ae60", width = 2))
    }
    if ("ask" %in% input$priceComponents) {
      ask_price <- if ("Ask_Close" %in% names(data)) data$Ask_Close else data$Ask
      p <- p %>% add_lines(y = ask_price, name = "Ask Price", 
                           line = list(color = "#e74c3c", width = 2))
    }
    
    # Add moving average
    if ("ma" %in% names(data)) {
      p <- p %>% add_lines(y = ~ma, name = paste("MA(", input$movingAvgDays, ")"), 
                           line = list(color = "#9b59b6", width = 2, dash = "dash"))
    }
    
    # Add Bollinger Bands
    if (input$showBollingerBands && "bb_upper" %in% names(data)) {
      p <- p %>% 
        add_lines(y = ~bb_upper, name = "BB Upper", line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = ~bb_lower, name = "BB Lower", line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = ~bb_mavg, name = "BB Middle", line = list(color = "#f39c12", width = 1))
    }
    
    # Add spread as secondary y-axis if selected
    if ("spread" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~spread_pct, name = "Spread (%)", 
                           yaxis = "y2", line = list(color = "#f39c12", width = 2, dash = "dot")) %>%
        layout(yaxis2 = list(overlaying = "y", side = "right", title = "Spread (%)"))
    }
    
    p
  })
  
  # OHLC Candlestick chart
  output$ohlcCandlestickChart <- renderPlotly({
    req(pair_data())
    
    # Check if OHLC data is available
    ohlc_cols <- c("Mid_Open", "Mid_High", "Mid_Low", "Mid_Close")
    if (!all(ohlc_cols %in% names(pair_data()))) {
      return(plot_ly() %>% layout(title = "OHLC data not available"))
    }
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2]) %>%
      slice_tail(n = 200)  # Show last 200 periods for performance
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No OHLC data for selected range"))
    }
    
    plot_ly(data, x = ~Timestamp, type = "candlestick",
            open = ~Mid_Open, high = ~Mid_High, low = ~Mid_Low, close = ~Mid_Close,
            name = "OHLC") %>%
      layout(
        title = paste("OHLC Candlestick Chart -", input$selectedPair, "| Periods:", nrow(data)),
        xaxis = list(title = "Date/Time", rangeslider = list(visible = FALSE)),
        yaxis = list(title = "Exchange Rate", tickformat = ".6f"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # OHLC statistics table
  output$ohlcStatsTable <- renderDT({
    req(pair_data())
    
    ohlc_cols <- c("Mid_Open", "Mid_High", "Mid_Low", "Mid_Close")
    if (!all(ohlc_cols %in% names(pair_data()))) {
      return(datatable(data.frame(Message = "OHLC data not available")))
    }
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(datatable(data.frame(Message = "No data for selected range")))
    }
    
    # Calculate OHLC statistics
    stats <- data.frame(
      Metric = c("Avg Open", "Avg High", "Avg Low", "Avg Close", "Avg Range (H-L)", 
                 "Max Range", "Min Range", "Avg Body Size", "Bullish Periods", "Bearish Periods"),
      Value = c(
        format(round(mean(data$Mid_Open, na.rm = TRUE), 6), nsmall = 6),
        format(round(mean(data$Mid_High, na.rm = TRUE), 6), nsmall = 6),
        format(round(mean(data$Mid_Low, na.rm = TRUE), 6), nsmall = 6),
        format(round(mean(data$Mid_Close, na.rm = TRUE), 6), nsmall = 6),
        format(round(mean(data$Mid_High - data$Mid_Low, na.rm = TRUE), 6), nsmall = 6),
        format(round(max(data$Mid_High - data$Mid_Low, na.rm = TRUE), 6), nsmall = 6),
        format(round(min(data$Mid_High - data$Mid_Low, na.rm = TRUE), 6), nsmall = 6),
        format(round(mean(abs(data$Mid_Close - data$Mid_Open), na.rm = TRUE), 6), nsmall = 6),
        paste0(round(sum(data$Mid_Close > data$Mid_Open, na.rm = TRUE) / nrow(data) * 100, 1), "%"),
        paste0(round(sum(data$Mid_Close < data$Mid_Open, na.rm = TRUE) / nrow(data) * 100, 1), "%")
      )
    )
    
    datatable(stats, options = list(dom = 't', pageLength = 12), rownames = FALSE)
  })
  
  # Spread analysis chart
  output$spreadAnalysis <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2]) %>%
      slice_tail(n = 1000)  # Last 1000 observations for performance
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data for spread analysis"))
    }
    
    # Calculate rolling spread statistics
    if (nrow(data) >= 30) {
      data$spread_ma <- SMA(data$spread_pct, n = min(30, nrow(data)))
      data$spread_volatility <- rollapply(data$spread_pct, width = min(30, nrow(data)), 
                                          FUN = sd, fill = NA, align = "right")
    }
    
    p <- plot_ly(data, x = ~Timestamp) %>%
      add_lines(y = ~spread_pct, name = "Bid-Ask Spread", 
                line = list(color = "#f39c12", width = 1.5)) %>%
      layout(
        title = "Bid-Ask Spread Time Series Analysis",
        xaxis = list(title = "Date/Time"),
        yaxis = list(title = "Spread (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    # Add rolling average if available
    if ("spread_ma" %in% names(data)) {
      p <- p %>% add_lines(y = ~spread_ma, name = "Spread MA(30)", 
                           line = list(color = "#e74c3c", width = 2, dash = "dash"))
    }
    
    # Add mean line
    mean_spread <- mean(data$spread_pct, na.rm = TRUE)
    p <- p %>% layout(
      shapes = list(
        list(type = "line", x0 = min(data$Timestamp), x1 = max(data$Timestamp),
             y0 = mean_spread, y1 = mean_spread, 
             line = list(color = "#95a5a6", dash = "dash", width = 1))
      ),
      annotations = list(
        list(x = min(data$Timestamp) + (max(data$Timestamp) - min(data$Timestamp)) * 0.02, 
             y = mean_spread * 1.1, text = paste("Mean:", round(mean_spread, 4), "%"), 
             showarrow = FALSE, font = list(size = 12))
      )
    )
    
    p
  })
  
  # Spread distribution analysis
  output$spreadDistributionAnalysis <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data for spread distribution"))
    }
    
    plot_ly(x = data$spread_pct, type = "histogram", nbinsx = 40,
            marker = list(color = "#f39c12", opacity = 0.7)) %>%
      layout(
        title = "Spread Distribution Analysis",
        xaxis = list(title = "Spread (%)"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # Price distribution
  output$priceDistribution <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    plot_ly(x = price_series, type = "histogram", nbinsx = 40,
            marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Price Distribution",
        xaxis = list(title = "Mid Price", tickformat = ".6f"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
  })
  
  # Price Q-Q plot
  output$priceQQPlot <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    # Calculate quantiles
    theoretical_quantiles <- qnorm(ppoints(length(price_series)))
    sample_quantiles <- sort(scale(price_series))
    
    plot_ly(x = theoretical_quantiles, y = sample_quantiles, type = "scatter", mode = "markers",
            marker = list(color = "#e74c3c")) %>%
      add_lines(x = theoretical_quantiles, y = theoretical_quantiles, 
                line = list(color = "#2c3e50", dash = "dash")) %>%
      layout(
        title = "Q-Q Plot (Normality Test)",
        xaxis = list(title = "Theoretical Quantiles"),
        yaxis = list(title = "Sample Quantiles"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = FALSE
      )
  })
  
  # Price box plot
  output$priceBoxPlot <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    plot_ly(y = price_series, type = "box", name = "Price Distribution",
            marker = list(color = "#27ae60")) %>%
      layout(
        title = "Price Box Plot",
        yaxis = list(title = "Mid Price", tickformat = ".6f"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        showlegend = FALSE
      )
  })
  
  # Returns time series chart
  output$returnsTimeSeriesChart <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0 || !"returns" %in% names(data)) {
      return(plot_ly() %>% layout(title = "Returns data not available"))
    }
    
    returns_data <- data %>% filter(!is.na(returns))
    
    if (nrow(returns_data) < 10) {
      return(plot_ly() %>% layout(title = "Insufficient returns data"))
    }
    
    plot_ly(returns_data, x = ~Timestamp, y = ~returns * 100, type = "scatter", mode = "lines",
            line = list(color = "#8e44ad", width = 1)) %>%
      layout(
        title = "Returns Time Series",
        xaxis = list(title = "Date/Time"),
        yaxis = list(title = "Returns (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      ) %>%
      layout(
        shapes = list(
          list(type = "line", x0 = min(returns_data$Timestamp), x1 = max(returns_data$Timestamp),
               y0 = 0, y1 = 0, line = list(color = "#95a5a6", dash = "dash"))
        )
      )
  })
  
  # Returns distribution chart
  output$returnsDistributionChart <- renderPlotly({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0 || !"returns" %in% names(data)) {
      return(plot_ly() %>% layout(title = "Returns data not available"))
    }
    
    returns <- data$returns[!is.na(data$returns)] * 100
    
    if (length(returns) < 10) {
      return(plot_ly() %>% layout(title = "Insufficient returns data"))
    }
    
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
  
  # Price levels table
  output$priceLevelsTable <- renderDT({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(datatable(data.frame(Message = "No data for selected range")))
    }
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    # Calculate support and resistance levels
    percentiles <- quantile(price_series, probs = c(0.05, 0.25, 0.5, 0.75, 0.95), na.rm = TRUE)
    
    stats <- data.frame(
      Level = c("Strong Support (5%)", "Support (25%)", "Median (50%)", "Resistance (75%)", "Strong Resistance (95%)"),
      Price = format(round(percentiles, 6), nsmall = 6),
      Distance_from_Current = paste0(round((percentiles - tail(price_series, 1)) / tail(price_series, 1) * 100, 3), "%")
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  # Volatility breakdown table
  output$volatilityBreakdownTable <- renderDT({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0 || !"returns" %in% names(data)) {
      return(datatable(data.frame(Message = "Returns data not available")))
    }
    
    returns <- data$returns[!is.na(data$returns)]
    
    if (length(returns) < 30) {
      return(datatable(data.frame(Message = "Insufficient returns data")))
    }
    
    # Calculate volatility breakdown
    daily_vol <- sd(returns, na.rm = TRUE)
    weekly_vol <- daily_vol * sqrt(7)
    monthly_vol <- daily_vol * sqrt(30)
    annual_vol <- daily_vol * sqrt(252)
    
    # Calculate rolling volatilities
    if (length(returns) >= 30) {
      vol_30d <- sd(tail(returns, 30), na.rm = TRUE) * sqrt(252)
    } else {
      vol_30d <- annual_vol
    }
    
    if (length(returns) >= 60) {
      vol_60d <- sd(tail(returns, 60), na.rm = TRUE) * sqrt(252)
    } else {
      vol_60d <- annual_vol
    }
    
    stats <- data.frame(
      Period = c("Daily", "Weekly", "Monthly", "Annual", "Last 30 Days (Ann.)", "Last 60 Days (Ann.)"),
      Volatility = paste0(round(c(daily_vol, weekly_vol, monthly_vol, annual_vol, vol_30d, vol_60d) * 100, 3), "%"),
      Risk_Level = c("Low", "Low", "Medium", "High", "Current", "Recent")
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  # Trading statistics table
  output$tradingStatsTable <- renderDT({
    req(pair_data())
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) {
      return(datatable(data.frame(Message = "No data for selected range")))
    }
    
    # Calculate trading statistics
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    # Basic trading metrics
    total_periods <- nrow(data)
    price_changes <- diff(price_series)
    up_periods <- sum(price_changes > 0, na.rm = TRUE)
    down_periods <- sum(price_changes < 0, na.rm = TRUE)
    flat_periods <- sum(price_changes == 0, na.rm = TRUE)
    
    # Calculate average moves
    avg_up_move <- mean(price_changes[price_changes > 0], na.rm = TRUE)
    avg_down_move <- mean(price_changes[price_changes < 0], na.rm = TRUE)
    
    # Spread statistics
    avg_spread <- mean(data$spread_pct, na.rm = TRUE)
    tight_spreads <- sum(data$spread_pct < 0.01, na.rm = TRUE)
    wide_spreads <- sum(data$spread_pct > 0.05, na.rm = TRUE)
    
    stats <- data.frame(
      Metric = c("Total Periods", "Up Periods", "Down Periods", "Flat Periods", 
                 "Avg Up Move", "Avg Down Move", "Up/Down Ratio", 
                 "Avg Spread (%)", "Tight Spreads (<0.01%)", "Wide Spreads (>0.05%)"),
      Value = c(
        total_periods,
        paste0(up_periods, " (", round(up_periods/total_periods*100, 1), "%)"),
        paste0(down_periods, " (", round(down_periods/total_periods*100, 1), "%)"),
        paste0(flat_periods, " (", round(flat_periods/total_periods*100, 1), "%)"),
        format(round(avg_up_move, 6), nsmall = 6),
        format(round(avg_down_move, 6), nsmall = 6),
        round(up_periods/down_periods, 2),
        paste0(round(avg_spread, 4), "%"),
        paste0(tight_spreads, " (", round(tight_spreads/total_periods*100, 1), "%)"),
        paste0(wide_spreads, " (", round(wide_spreads/total_periods*100, 1), "%)")
      )
    )
    
    datatable(stats, options = list(dom = 't', pageLength = 12), rownames = FALSE)
  })
  
  # Intraperiod patterns chart
  output$intraperiodPatternsChart <- renderPlotly({
    req(pair_data())
    
    # Only show for aggregated intraday data
    if (!"record_count" %in% names(pair_data())) {
      return(plot_ly() %>% layout(title = "Intraperiod analysis not available"))
    }
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2]) %>%
      filter(!is.na(record_count), record_count > 1)
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No intraperiod data available"))
    }
    
    # Check if OHLC data is available
    if (all(c("Mid_High", "Mid_Low", "Mid_Open", "Mid_Close") %in% names(data))) {
      # Calculate intraperiod range
      data$intraperiod_range <- (data$Mid_High - data$Mid_Low) / data$Mid_Open * 100
      
      plot_ly(data, x = ~Timestamp, y = ~intraperiod_range, type = "scatter", mode = "lines",
              line = list(color = "#e67e22", width = 2)) %>%
        layout(
          title = "Intraperiod Range Analysis",
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "Intraperiod Range (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    } else {
      # Show record count pattern
      plot_ly(data, x = ~Timestamp, y = ~record_count, type = "scatter", mode = "lines+markers",
              line = list(color = "#e67e22", width = 2)) %>%
        layout(
          title = "Records per Aggregation Period",
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "Record Count"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    }
  })
  
  # Aggregation impact chart
  output$aggregationImpactChart <- renderPlotly({
    req(pair_data())
    
    # Only show for aggregated intraday data
    if (!"record_count" %in% names(pair_data()) || !all(c("Mid_High", "Mid_Low") %in% names(pair_data()))) {
      return(plot_ly() %>% layout(title = "Aggregation impact analysis not available"))
    }
    
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2]) %>%
      filter(!is.na(record_count), record_count > 1)
    
    if (nrow(data) == 0) {
      return(plot_ly() %>% layout(title = "No aggregation data available"))
    }
    
    # Calculate aggregation impact metrics
    data$price_impact <- abs(data$Mid_Close - data$Mid_Open) / data$Mid_Open * 100
    data$volatility_impact <- (data$Mid_High - data$Mid_Low) / data$Mid_Open * 100
    
    plot_ly(data, x = ~record_count, y = ~volatility_impact, type = "scatter", mode = "markers",
            marker = list(color = ~price_impact, colorscale = "Viridis", size = 8),
            text = ~paste("Date:", date, "<br>Records:", record_count, 
                          "<br>Price Impact:", round(price_impact, 4), "%",
                          "<br>Vol Impact:", round(volatility_impact, 4), "%"),
            hovertemplate = "%{text}<extra></extra>") %>%
      layout(
        title = "Aggregation Impact: Records vs Volatility",
        xaxis = list(title = "Records in Period"),
        yaxis = list(title = "Volatility Impact (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      ) %>%
      colorbar(title = "Price Impact (%)")
  })
  
  # TECHNICAL INDICATORS TAB FUNCTIONS
  
  # Technical data quality check
  output$technicalDataQuality <- renderText({
    req(pair_data())
    data <- pair_data()
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    price_range <- max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE)
    unique_prices <- length(unique(price_series))
    
    paste(
      paste("Data points:", nrow(data)),
      paste("Unique prices:", unique_prices),
      paste("Price range:", format(price_range, scientific = TRUE, digits = 4)),
      paste("Data source:", values$source_table),
      "",
      ifelse(unique_prices > 20 && price_range > 1e-6, 
             "✓ Sufficient variation for analysis", 
             "⚠ Limited price variation"),
      ifelse(nrow(data) >= 50, 
             "✓ Adequate data points", 
             "⚠ Limited data points"),
      sep = "\n"
    )
  })
  
  # Technical signals
  output$technicalSignals <- renderText({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    if (nrow(data) < 20) return("Insufficient data for technical analysis")
    
    price_range <- max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE)
    if (price_range < 1e-10) return("No price variation - technical analysis not possible")
    
    tryCatch({
      signals <- c()
      
      # RSI signals
      if ("rsi" %in% input$technicalIndicators && length(price_series) >= input$rsiLength) {
        rsi_values <- RSI(price_series, n = input$rsiLength)
        rsi <- tail(rsi_values[!is.na(rsi_values)], 1)
        
        if (length(rsi) > 0 && !is.na(rsi)) {
          if (rsi > 70) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Overbought"))
          else if (rsi < 30) signals <- c(signals, paste("RSI:", round(rsi, 2), "- Oversold"))
          else signals <- c(signals, paste("RSI:", round(rsi, 2), "- Neutral"))
        }
      }
      
      # SMA signals
      if ("sma" %in% input$technicalIndicators && length(price_series) >= input$smaLength) {
        sma_values <- SMA(price_series, n = input$smaLength)
        sma <- tail(sma_values[!is.na(sma_values)], 1)
        current_price <- tail(price_series, 1)
        
        if (length(sma) > 0 && !is.na(sma)) {
          price_vs_sma <- (current_price - sma) / sma * 100
          if (current_price > sma) {
            signals <- c(signals, paste("Price vs SMA:", paste0("+", round(price_vs_sma, 4), "%"), "- Bullish"))
          } else {
            signals <- c(signals, paste("Price vs SMA:", paste0(round(price_vs_sma, 4), "%"), "- Bearish"))
          }
        }
      }
      
      # MACD signals
      if ("macd" %in% input$technicalIndicators && length(price_series) >= 50) {
        macd_result <- MACD(price_series, nFast = 12, nSlow = 26, nSig = 9)
        if (!is.null(macd_result)) {
          macd_line <- tail(macd_result[!is.na(macd_result[, "macd"]), "macd"], 1)
          signal_line <- tail(macd_result[!is.na(macd_result[, "signal"]), "signal"], 1)
          
          if (length(macd_line) > 0 && length(signal_line) > 0) {
            if (macd_line > signal_line) {
              signals <- c(signals, "MACD: Bullish crossover")
            } else {
              signals <- c(signals, "MACD: Bearish crossover")
            }
          }
        }
      }
      
      paste(if (length(signals) > 0) signals else "Calculating signals...", collapse = "\n")
    }, error = function(e) {
      paste("Error calculating signals:", e$message)
    })
  })
  
  # Technical Charts
  output$technicalChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    price_range <- max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE)
    
    if (price_range < 1e-10) {
      return(plot_ly() %>% layout(title = "Cannot perform technical analysis - no price variation", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    p <- plot_ly(data, x = ~Timestamp, y = price_series, type = "scatter", mode = "lines",
                 name = "Mid Price (Calc)", line = list(color = "#2c3e50", width = 2))
    
    # Add technical indicators
    if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
      sma_values <- SMA(price_series, n = input$smaLength)
      p <- p %>% add_lines(y = sma_values, name = paste("SMA(", input$smaLength, ")"),
                           line = list(color = "#e74c3c", width = 2))
    }
    
    if ("ema" %in% input$technicalIndicators && nrow(data) >= input$emaLength) {
      ema_values <- EMA(price_series, n = input$emaLength)
      p <- p %>% add_lines(y = ema_values, name = paste("EMA(", input$emaLength, ")"),
                           line = list(color = "#27ae60", width = 2))
    }
    
    if ("bb" %in% input$technicalIndicators && nrow(data) >= input$bbLength) {
      bb <- BBands(price_series, n = input$bbLength, sd = input$bbSd)
      if (!is.null(bb)) {
        p <- p %>% 
          add_lines(y = bb[, "up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dash", width = 1)) %>%
          add_lines(y = bb[, "dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dash", width = 1)) %>%
          add_lines(y = bb[, "mavg"], name = "BB Middle", line = list(color = "#f39c12", width = 1))
      }
    }
    
    p %>% layout(
      title = paste("Technical Analysis -", input$selectedPair, "| Mid = (Bid + Ask) / 2 | Records:", nrow(data)),
      xaxis = list(title = "Date/Time"),
      yaxis = list(title = "Exchange Rate", tickformat = ".6f"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
  })
  
  # RSI Chart
  output$rsiChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    if (nrow(data) < input$rsiLength + 10 || max(price_series) - min(price_series) < 1e-10) {
      return(plot_ly() %>% layout(title = "Insufficient data or variation for RSI", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    tryCatch({
      rsi_values <- RSI(price_series, n = input$rsiLength)
      plot_data <- data[!is.na(rsi_values), ]
      rsi_values <- rsi_values[!is.na(rsi_values)]
      
      if (length(rsi_values) == 0) {
        return(plot_ly() %>% layout(title = "No valid RSI data", plot_bgcolor = "white", paper_bgcolor = "white"))
      }
      
      plot_ly(plot_data, x = ~Timestamp, y = rsi_values, type = "scatter", mode = "lines",
              line = list(color = "#9b59b6", width = 2)) %>%
        layout(
          title = paste("RSI(", input$rsiLength, ") - Points:", length(rsi_values)),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "RSI", range = c(0, 100)),
          plot_bgcolor = "white", paper_bgcolor = "white",
          shapes = list(
            list(type = "line", x0 = min(plot_data$Timestamp), x1 = max(plot_data$Timestamp),
                 y0 = 70, y1 = 70, line = list(color = "#e74c3c", dash = "dash")),
            list(type = "line", x0 = min(plot_data$Timestamp), x1 = max(plot_data$Timestamp),
                 y0 = 30, y1 = 30, line = list(color = "#27ae60", dash = "dash"))
          )
        )
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("RSI error:", e$message), plot_bgcolor = "white", paper_bgcolor = "white")
    })
  })
  
  # MACD Chart
  output$macdChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    if (nrow(data) < 50 || max(price_series) - min(price_series) < 1e-10) {
      return(plot_ly() %>% layout(title = "Insufficient data or variation for MACD", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    tryCatch({
      macd_result <- MACD(price_series, nFast = 12, nSlow = 26, nSig = 9)
      
      if (is.null(macd_result)) {
        return(plot_ly() %>% layout(title = "MACD calculation failed", plot_bgcolor = "white", paper_bgcolor = "white"))
      }
      
      macd_data <- data.frame(
        Timestamp = data$Timestamp,
        macd = macd_result[, "macd"],
        signal = macd_result[, "signal"]
      )
      macd_data$histogram <- macd_data$macd - macd_data$signal
      plot_data <- macd_data[complete.cases(macd_data), ]
      
      if (nrow(plot_data) == 0) {
        return(plot_ly() %>% layout(title = "No valid MACD data", plot_bgcolor = "white", paper_bgcolor = "white"))
      }
      
      plot_ly(plot_data, x = ~Timestamp) %>%
        add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2)) %>%
        add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1)) %>%
        add_bars(y = ~histogram, name = "Histogram", 
                 marker = list(color = ifelse(plot_data$histogram > 0, "#27ae60", "#e74c3c"))) %>%
        layout(
          title = paste("MACD - Points:", nrow(plot_data)),
          xaxis = list(title = "Date/Time"), 
          yaxis = list(title = "MACD"),
          plot_bgcolor = "white", paper_bgcolor = "white",
          shapes = list(list(type = "line", x0 = min(plot_data$Timestamp), x1 = max(plot_data$Timestamp),
                             y0 = 0, y1 = 0, line = list(color = "#95a5a6", dash = "dot")))
        )
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("MACD error:", e$message), plot_bgcolor = "white", paper_bgcolor = "white")
    })
  })
  
  # Stochastic Chart
  output$stochChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    if (nrow(data) < 30) {
      return(plot_ly() %>% layout(title = "Need more data for Stochastic", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    # Use OHLC if available, otherwise use Mid prices for High/Low/Close
    if ("Mid_High" %in% names(data) && "Mid_Low" %in% names(data) && "Mid_Close" %in% names(data)) {
      high_series <- data$Mid_High
      low_series <- data$Mid_Low
      close_series <- data$Mid_Close
    } else {
      high_series <- low_series <- close_series <- data$Mid
    }
    
    price_range <- max(high_series) - min(low_series)
    if (price_range < 1e-10) {
      return(plot_ly() %>% layout(title = "Cannot calculate Stochastic - no price variation", 
                                  plot_bgcolor = "white", paper_bgcolor = "white"))
    }
    
    tryCatch({
      k_period <- 14
      d_period <- 3
      
      data <- data %>% arrange(Timestamp)
      rolling_low <- rollapply(low_series, width = k_period, FUN = min, align = "right", fill = NA)
      rolling_high <- rollapply(high_series, width = k_period, FUN = max, align = "right", fill = NA)
      
      stoch_k <- ifelse(rolling_high - rolling_low != 0, 
                        (close_series - rolling_low) / (rolling_high - rolling_low) * 100, 50)
      stoch_d <- SMA(stoch_k, n = d_period)
      
      stoch_data <- data.frame(Timestamp = data$Timestamp, stoch_k = stoch_k, stoch_d = stoch_d)
      plot_data <- stoch_data[complete.cases(stoch_data), ]
      
      if (nrow(plot_data) == 0) {
        return(plot_ly() %>% layout(title = "No valid Stochastic data", plot_bgcolor = "white", paper_bgcolor = "white"))
      }
      
      plot_ly(plot_data, x = ~Timestamp) %>%
        add_lines(y = ~stoch_k, name = "%K", line = list(color = "#3498db", width = 2)) %>%
        add_lines(y = ~stoch_d, name = "%D", line = list(color = "#e74c3c", width = 1)) %>%
        layout(
          title = paste("Stochastic - Points:", nrow(plot_data)),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "Stochastic (%)", range = c(0, 100)),
          plot_bgcolor = "white", paper_bgcolor = "white",
          shapes = list(
            list(type = "line", x0 = min(plot_data$Timestamp), x1 = max(plot_data$Timestamp),
                 y0 = 80, y1 = 80, line = list(color = "#e74c3c", dash = "dash")),
            list(type = "line", x0 = min(plot_data$Timestamp), x1 = max(plot_data$Timestamp),
                 y0 = 20, y1 = 20, line = list(color = "#27ae60", dash = "dash"))
          )
        )
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Stochastic error:", e$message), plot_bgcolor = "white", paper_bgcolor = "white")
    })
  })
  
  # Indicator status
  output$indicatorStatus <- renderText({
    req(pair_data())
    data <- pair_data()
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    price_range <- max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE)
    
    status <- c()
    
    if ("sma" %in% input$technicalIndicators) {
      sma_ok <- nrow(data) >= input$smaLength
      status <- c(status, paste("SMA(", input$smaLength, "):", ifelse(sma_ok, "✓ Ready", "✗ Need more data")))
    }
    
    if ("ema" %in% input$technicalIndicators) {
      ema_ok <- nrow(data) >= input$emaLength  
      status <- c(status, paste("EMA(", input$emaLength, "):", ifelse(ema_ok, "✓ Ready", "✗ Need more data")))
    }
    
    if ("rsi" %in% input$technicalIndicators) {
      rsi_ok <- nrow(data) >= input$rsiLength && price_range > 1e-8
      status <- c(status, paste("RSI(", input$rsiLength, "):", ifelse(rsi_ok, "✓ Ready", "✗ Need more data/variation")))
    }
    
    if ("macd" %in% input$technicalIndicators) {
      macd_ok <- nrow(data) >= 50 && price_range > 1e-8
      status <- c(status, paste("MACD:", ifelse(macd_ok, "✓ Ready", "✗ Need 50+ records")))
    }
    
    if ("bb" %in% input$technicalIndicators) {
      bb_ok <- nrow(data) >= input$bbLength && price_range > 1e-8
      status <- c(status, paste("Bollinger Bands:", ifelse(bb_ok, "✓ Ready", "✗ Need more data/variation")))
    }
    
    if ("stoch" %in% input$technicalIndicators) {
      stoch_ok <- nrow(data) >= 30 && price_range > 1e-8
      status <- c(status, paste("Stochastic:", ifelse(stoch_ok, "✓ Ready", "✗ Need 30+ records")))
    }
    
    paste(status, collapse = "\n")
  })
  
  # Price action analysis
  output$priceActionAnalysis <- renderText({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < 5) return("Insufficient data for price action analysis")
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    recent_prices <- tail(price_series, 10)
    
    # Calculate basic price action metrics
    current_price <- tail(recent_prices, 1)
    price_5_ago <- if(length(recent_prices) >= 5) recent_prices[length(recent_prices)-4] else recent_prices[1]
    
    trend_direction <- ifelse(current_price > price_5_ago, "Upward", "Downward")
    trend_strength <- abs((current_price - price_5_ago) / price_5_ago * 100)
    
    # Volatility analysis
    if ("returns" %in% names(data) && sum(!is.na(data$returns)) > 10) {
      recent_vol <- sd(tail(data$returns, 20), na.rm = TRUE) * 100
      vol_status <- ifelse(recent_vol > 0.01, "High", ifelse(recent_vol > 0.005, "Medium", "Low"))
    } else {
      vol_status <- "Unable to calculate"
      recent_vol <- NA
    }
    
    paste(
      paste("Recent trend:", trend_direction),
      paste("Trend strength:", round(trend_strength, 4), "%"),
      paste("Volatility:", vol_status),
      if (!is.na(recent_vol)) paste("Recent volatility:", round(recent_vol, 6), "%") else "",
      paste("Price levels analyzed:", length(recent_prices)),
      "",
      "Based on recalculated Mid prices",
      sep = "\n"
    )
  })
  
  # Signal summary table
  output$signalSummary <- renderDT({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 100)
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    if (nrow(data) < 20) {
      return(datatable(data.frame(Indicator = "No Data", Signal = "Insufficient data", Value = "N/A"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    signals_df <- data.frame(
      Indicator = character(0),
      Current_Value = character(0),
      Signal = character(0),
      stringsAsFactors = FALSE
    )
    
    tryCatch({
      # RSI
      if ("rsi" %in% input$technicalIndicators && nrow(data) >= input$rsiLength) {
        rsi_values <- RSI(price_series, n = input$rsiLength)
        rsi <- tail(rsi_values[!is.na(rsi_values)], 1)
        if (length(rsi) > 0) {
          signal <- if (rsi > 70) "Overbought" else if (rsi < 30) "Oversold" else "Neutral"
          signals_df <- rbind(signals_df, data.frame(
            Indicator = paste0("RSI(", input$rsiLength, ")"), 
            Current_Value = round(rsi, 2), 
            Signal = signal
          ))
        }
      }
      
      # SMA
      if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
        sma_values <- SMA(price_series, n = input$smaLength)
        sma <- tail(sma_values[!is.na(sma_values)], 1)
        current_price <- tail(price_series, 1)
        if (length(sma) > 0) {
          signal <- if (current_price > sma) "Bullish" else "Bearish"
          deviation <- round((current_price - sma) / sma * 100, 4)
          signals_df <- rbind(signals_df, data.frame(
            Indicator = paste0("SMA(", input$smaLength, ")"), 
            Current_Value = paste0(deviation, "%"), 
            Signal = signal
          ))
        }
      }
      
      # EMA
      if ("ema" %in% input$technicalIndicators && nrow(data) >= input$emaLength) {
        ema_values <- EMA(price_series, n = input$emaLength)
        ema <- tail(ema_values[!is.na(ema_values)], 1)
        current_price <- tail(price_series, 1)
        if (length(ema) > 0) {
          signal <- if (current_price > ema) "Bullish" else "Bearish"
          deviation <- round((current_price - ema) / ema * 100, 4)
          signals_df <- rbind(signals_df, data.frame(
            Indicator = paste0("EMA(", input$emaLength, ")"), 
            Current_Value = paste0(deviation, "%"), 
            Signal = signal
          ))
        }
      }
      
      # MACD
      if ("macd" %in% input$technicalIndicators && nrow(data) >= 50) {
        macd_result <- MACD(price_series, nFast = 12, nSlow = 26, nSig = 9)
        if (!is.null(macd_result)) {
          macd_line <- tail(macd_result[!is.na(macd_result[, "macd"]), "macd"], 1)
          signal_line <- tail(macd_result[!is.na(macd_result[, "signal"]), "signal"], 1)
          
          if (length(macd_line) > 0 && length(signal_line) > 0) {
            signal <- if (macd_line > signal_line) "Bullish Crossover" else "Bearish Crossover"
            signals_df <- rbind(signals_df, data.frame(
              Indicator = "MACD", 
              Current_Value = round(macd_line - signal_line, 6), 
              Signal = signal
            ))
          }
        }
      }
      
      # Bollinger Bands
      if ("bb" %in% input$technicalIndicators && nrow(data) >= input$bbLength) {
        bb <- BBands(price_series, n = input$bbLength, sd = input$bbSd)
        if (!is.null(bb)) {
          current_price <- tail(price_series, 1)
          bb_upper <- tail(bb[, "up"], 1)
          bb_lower <- tail(bb[, "dn"], 1)
          bb_middle <- tail(bb[, "mavg"], 1)
          
          if (current_price > bb_upper) {
            signal <- "Above Upper Band"
          } else if (current_price < bb_lower) {
            signal <- "Below Lower Band" 
          } else {
            signal <- "Within Bands"
          }
          
          position <- round((current_price - bb_middle) / (bb_upper - bb_middle) * 100, 1)
          signals_df <- rbind(signals_df, data.frame(
            Indicator = paste0("BB(", input$bbLength, ")"), 
            Current_Value = paste0(position, "%"), 
            Signal = signal
          ))
        }
      }
      
    }, error = function(e) {
      signals_df <- rbind(signals_df, data.frame(
        Indicator = "Error", 
        Current_Value = "N/A", 
        Signal = e$message
      ))
    })
    
    if (nrow(signals_df) == 0) {
      signals_df <- rbind(signals_df, data.frame(
        Indicator = "No Indicators", 
        Current_Value = "N/A", 
        Signal = "Select indicators above"
      ))
    }
    
    datatable(signals_df, options = list(dom = 't', pageLength = 10), rownames = FALSE) %>%
      formatStyle(columns = "Signal", 
                  backgroundColor = styleEqual(c("Bullish", "Bullish Crossover", "Oversold", "Below Lower Band"), 
                                               c("#d4edda", "#d4edda", "#d4edda", "#d4edda"))) %>%
      formatStyle(columns = "Signal",
                  backgroundColor = styleEqual(c("Bearish", "Bearish Crossover", "Overbought", "Above Upper Band"), 
                                               c("#f8d7da", "#f8d7da", "#f8d7da", "#f8d7da")))
  })
  
  # VOLATILITY ANALYSIS TAB FUNCTIONS
  
  # Volatility metrics
  output$volatilityMetrics <- renderText({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < input$volWindow) return("Insufficient data for volatility analysis")
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      if (length(returns) < input$volWindow) return("Insufficient return data")
      
      # Current volatility (last window)
      current_vol <- sd(tail(returns, input$volWindow), na.rm = TRUE)
      if (input$annualizeVol) current_vol <- current_vol * sqrt(252)
      
      # Overall statistics
      all_vol <- sd(returns, na.rm = TRUE)
      if (input$annualizeVol) all_vol <- all_vol * sqrt(252)
      
      # Rolling volatility stats
      if (length(returns) > input$volWindow) {
        rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
        if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
        
        min_vol <- min(rolling_vol, na.rm = TRUE)
        max_vol <- max(rolling_vol, na.rm = TRUE)
        vol_percentile <- quantile(rolling_vol, 0.75, na.rm = TRUE)
      } else {
        min_vol <- max_vol <- vol_percentile <- current_vol
      }
      
      vol_unit <- ifelse(input$annualizeVol, "% (ann.)", "% (daily)")
      
      paste(
        paste("Current Volatility:", round(current_vol * 100, 3), vol_unit),
        paste("Historical Average:", round(all_vol * 100, 3), vol_unit),
        paste("Min Volatility:", round(min_vol * 100, 3), vol_unit),
        paste("Max Volatility:", round(max_vol * 100, 3), vol_unit),
        paste("75th Percentile:", round(vol_percentile * 100, 3), vol_unit),
        "",
        paste("Volatility Regime:", ifelse(current_vol > vol_percentile, "High Vol", "Normal/Low Vol")),
        paste("Data Points:", length(returns)),
        sep = "\n"
      )
    }, error = function(e) {
      paste("Error calculating volatility metrics:", e$message)
    })
  })
  
  # Volatility time series chart
  output$volatilityChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < input$volWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data for volatility analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns
      
      # Calculate volatility based on selected method
      if (input$volatilityType == "realized") {
        # Standard realized volatility
        rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      } else if (input$volatilityType == "parkinson" && "Mid_High" %in% names(data) && "Mid_Low" %in% names(data)) {
        # Parkinson estimator using High-Low
        hl_ratio <- log(data$Mid_High / data$Mid_Low)
        rolling_vol <- rollapply(hl_ratio^2, input$volWindow, 
                                 function(x) sqrt(mean(x, na.rm = TRUE) / (4 * log(2))), 
                                 fill = NA, align = "right")
      } else {
        # Fallback to realized volatility
        rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      }
      
      # Annualize if requested
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      
      # Create confidence bands
      vol_mean <- mean(rolling_vol, na.rm = TRUE)
      vol_sd <- sd(rolling_vol, na.rm = TRUE)
      confidence_multiplier <- qnorm((100 + input$volConfidence) / 200)
      
      data$volatility <- rolling_vol
      data$vol_upper <- vol_mean + confidence_multiplier * vol_sd
      data$vol_lower <- pmax(0, vol_mean - confidence_multiplier * vol_sd)
      
      # Filter out NA values
      plot_data <- data[!is.na(data$volatility), ]
      
      if (nrow(plot_data) == 0) {
        return(plot_ly() %>% layout(title = "No valid volatility data"))
      }
      
      vol_unit <- ifelse(input$annualizeVol, "Annualized Volatility (%)", "Daily Volatility (%)")
      
      p <- plot_ly(plot_data, x = ~Timestamp) %>%
        add_lines(y = ~volatility * 100, name = "Rolling Volatility", 
                  line = list(color = "#2c3e50", width = 2)) %>%
        add_lines(y = ~vol_upper * 100, name = paste0(input$volConfidence, "% Upper Band"), 
                  line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
        add_lines(y = ~vol_lower * 100, name = paste0(input$volConfidence, "% Lower Band"), 
                  line = list(color = "#27ae60", width = 1, dash = "dash")) %>%
        layout(
          title = paste("Volatility Analysis -", input$selectedPair, 
                        "| Method:", input$volatilityType, "| Window:", input$volWindow),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = vol_unit, tickformat = ".3f"),
          hovermode = "x unified",
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Volatility distribution (FIXED VERSION)
  output$volatilityDist <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < input$volWindow * 2) {
      return(plot_ly() %>% layout(title = "Insufficient data for distribution analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      # Calculate rolling volatility
      rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      
      vol_data <- rolling_vol[!is.na(rolling_vol)]
      
      if (length(vol_data) < 20) {
        return(plot_ly() %>% layout(title = "Insufficient volatility data"))
      }
      
      vol_unit <- ifelse(input$annualizeVol, "Annualized Volatility (%)", "Daily Volatility (%)")
      
      p <- plot_ly(x = vol_data * 100, type = "histogram", nbinsx = 30,
                   marker = list(color = "#3498db", opacity = 0.7)) %>%
        layout(
          title = "Volatility Distribution",
          xaxis = list(title = vol_unit),
          yaxis = list(title = "Frequency"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      # Add statistics lines using shapes instead of add_vline
      vol_mean <- mean(vol_data, na.rm = TRUE) * 100
      vol_median <- median(vol_data, na.rm = TRUE) * 100
      
      # Get y-axis range for vertical lines
      y_max <- max(hist(vol_data * 100, breaks = 30, plot = FALSE)$counts)
      
      p <- p %>% layout(
        shapes = list(
          # Mean line
          list(type = "line", x0 = vol_mean, x1 = vol_mean, y0 = 0, y1 = y_max,
               line = list(color = "#e74c3c", dash = "dash", width = 2)),
          # Median line  
          list(type = "line", x0 = vol_median, x1 = vol_median, y0 = 0, y1 = y_max,
               line = list(color = "#27ae60", dash = "dot", width = 2))
        ),
        annotations = list(
          list(x = vol_mean, y = y_max * 0.8, text = paste("Mean:", round(vol_mean, 2)), 
               showarrow = FALSE, font = list(color = "#e74c3c", size = 12)),
          list(x = vol_median, y = y_max * 0.9, text = paste("Median:", round(vol_median, 2)), 
               showarrow = FALSE, font = list(color = "#27ae60", size = 12))
        )
      )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Volatility clustering (FIXED VERSION)
  output$volatilityClustering <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data for clustering analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      data$abs_returns <- abs(data$returns) * 100
      
      # Filter out NA values
      plot_data <- data[!is.na(data$abs_returns), ]
      
      if (nrow(plot_data) < 20) {
        return(plot_ly() %>% layout(title = "Insufficient return data"))
      }
      
      p <- plot_ly(plot_data, x = ~Timestamp, y = ~abs_returns, type = "scatter", mode = "lines",
                   line = list(color = "#e74c3c", width = 1.5)) %>%
        layout(
          title = "Volatility Clustering (Absolute Returns)",
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "Absolute Return (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      # Add mean line using shapes instead of add_hline
      mean_abs_return <- mean(plot_data$abs_returns, na.rm = TRUE)
      x_min <- min(plot_data$Timestamp)
      x_max <- max(plot_data$Timestamp)
      
      p <- p %>% layout(
        shapes = list(
          # Mean line
          list(type = "line", x0 = x_min, x1 = x_max, y0 = mean_abs_return, y1 = mean_abs_return,
               line = list(color = "#95a5a6", dash = "dash", width = 2))
        ),
        annotations = list(
          list(x = x_min + (x_max - x_min) * 0.02, y = mean_abs_return * 1.1, 
               text = paste("Mean:", round(mean_abs_return, 3), "%"), 
               showarrow = FALSE, font = list(color = "#95a5a6", size = 12))
        )
      )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Volatility regimes
  output$volatilityRegimes <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < input$volWindow * 3) {
      return(plot_ly() %>% layout(title = "Insufficient data for regime analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      # Calculate rolling volatility
      rolling_vol <- rollapply(returns, input$volWindow, sd, fill = NA, align = "right")
      if (input$annualizeVol) rolling_vol <- rolling_vol * sqrt(252)
      
      # Define regimes based on percentiles
      vol_25 <- quantile(rolling_vol, 0.25, na.rm = TRUE)
      vol_75 <- quantile(rolling_vol, 0.75, na.rm = TRUE)
      
      regime_data <- data.frame(
        Timestamp = tail(data$Timestamp, length(rolling_vol)),
        volatility = rolling_vol,
        regime = ifelse(rolling_vol <= vol_25, "Low Volatility",
                        ifelse(rolling_vol >= vol_75, "High Volatility", "Normal Volatility"))
      ) %>%
        filter(!is.na(volatility))
      
      if (nrow(regime_data) == 0) {
        return(plot_ly() %>% layout(title = "No valid regime data"))
      }
      
      colors <- c("Low Volatility" = "#27ae60", "Normal Volatility" = "#3498db", "High Volatility" = "#e74c3c")
      
      vol_unit <- ifelse(input$annualizeVol, "Annualized Volatility (%)", "Daily Volatility (%)")
      
      p <- plot_ly(regime_data, x = ~Timestamp, y = ~volatility * 100, 
                   color = ~regime, colors = colors,
                   type = "scatter", mode = "markers") %>%
        layout(
          title = "Volatility Regime Classification",
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = vol_unit),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # RISK METRICS TAB FUNCTIONS
  
  # Risk metrics summary
  output$riskMetrics <- renderText({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = input$varWindow)
    
    if (nrow(data) < 30) return("Insufficient data for risk analysis")
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      if (length(returns) < 30) return("Insufficient return data")
      
      # Adjust returns for time horizon
      adjusted_returns <- returns * sqrt(input$timeHorizon)
      
      # Calculate VaR based on method
      var_percentile <- (100 - input$confidenceLevel) / 100
      
      if (input$varMethod == "historical") {
        var_value <- quantile(adjusted_returns, var_percentile, na.rm = TRUE)
      } else if (input$varMethod == "parametric") {
        mean_return <- mean(adjusted_returns, na.rm = TRUE)
        sd_return <- sd(adjusted_returns, na.rm = TRUE)
        var_value <- mean_return + qnorm(var_percentile) * sd_return
      } else { # modified
        # Cornish-Fisher modification
        mean_return <- mean(adjusted_returns, na.rm = TRUE)
        sd_return <- sd(adjusted_returns, na.rm = TRUE)
        skew <- sum((adjusted_returns - mean_return)^3/sd_return^3) / length(adjusted_returns)
        kurt <- sum((adjusted_returns - mean_return)^4/sd_return^4) / length(adjusted_returns) - 3
        
        z_score <- qnorm(var_percentile)
        cf_adjustment <- z_score + (z_score^2 - 1) * skew / 6 + (z_score^3 - 3*z_score) * kurt / 24
        var_value <- mean_return + cf_adjustment * sd_return
      }
      
      # Expected Shortfall
      es_value <- mean(adjusted_returns[adjusted_returns <= var_value], na.rm = TRUE)
      if (is.na(es_value)) es_value <- var_value
      
      # Convert to portfolio values
      var_dollar <- abs(var_value) * input$portfolioValue
      es_dollar <- abs(es_value) * input$portfolioValue
      
      # Calculate additional metrics
      sharpe_ratio <- mean(returns, na.rm = TRUE) / sd(returns, na.rm = TRUE) * sqrt(252)
      max_return <- max(adjusted_returns, na.rm = TRUE)
      min_return <- min(adjusted_returns, na.rm = TRUE)
      
      paste(
        paste("Portfolio Value:", paste0("$", format(input$portfolioValue, big.mark = ","))),
        paste("Time Horizon:", input$timeHorizon, "day(s)"),
        "",
        paste("VaR (", input$confidenceLevel, "%):", paste0("$", format(round(var_dollar, 0), big.mark = ","))),
        paste("Expected Shortfall:", paste0("$", format(round(es_dollar, 0), big.mark = ","))),
        paste("VaR as % of Portfolio:", paste0(round(var_dollar / input$portfolioValue * 100, 3), "%")),
        "",
        paste("Max Gain (", input$timeHorizon, "d):", paste0("$", format(round(max_return * input$portfolioValue, 0), big.mark = ","))),
        paste("Max Loss (", input$timeHorizon, "d):", paste0("$", format(round(abs(min_return) * input$portfolioValue, 0), big.mark = ","))),
        "",
        paste("Sharpe Ratio:", round(sharpe_ratio, 3)),
        paste("Method:", input$varMethod),
        sep = "\n"
      )
    }, error = function(e) {
      paste("Error calculating risk metrics:", e$message)
    })
  })
  
  # VaR chart
  output$varChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = min(1000, nrow(pair_data())))
    
    if (nrow(data) < input$varWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data for VaR analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns
      
      # Calculate rolling VaR
      var_percentile <- (100 - input$confidenceLevel) / 100
      window_size <- min(input$varWindow, length(returns) - 50)
      
      if (input$varMethod == "historical") {
        rolling_var <- rollapply(returns, window_size, 
                                 function(x) quantile(x * sqrt(input$timeHorizon), var_percentile, na.rm = TRUE),
                                 fill = NA, align = "right")
      } else {
        rolling_var <- rollapply(returns, window_size, 
                                 function(x) {
                                   adj_ret <- x * sqrt(input$timeHorizon)
                                   mean(adj_ret, na.rm = TRUE) + qnorm(var_percentile) * sd(adj_ret, na.rm = TRUE)
                                 },
                                 fill = NA, align = "right")
      }
      
      # Prepare data
      plot_data <- data.frame(
        Timestamp = tail(data$Timestamp, length(rolling_var)),
        var_value = abs(rolling_var) * input$portfolioValue,
        daily_pnl = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) * input$portfolioValue,
        breaches = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) < rolling_var
      ) %>%
        filter(!is.na(var_value))
      
      if (nrow(plot_data) == 0) {
        return(plot_ly() %>% layout(title = "No valid VaR data"))
      }
      
      p <- plot_ly(plot_data, x = ~Timestamp) %>%
        add_lines(y = ~var_value, name = paste0("VaR (", input$confidenceLevel, "%)"),
                  line = list(color = "#e74c3c", width = 2)) %>%
        add_bars(y = ~daily_pnl, name = "Daily P&L",
                 marker = list(color = ifelse(plot_data$breaches, "#c0392b", "#3498db"))) %>%
        layout(
          title = paste("Value at Risk Analysis -", input$selectedPair),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "USD", tickformat = "$,.0f"),
          hovermode = "x unified",
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      # Add breach count annotation
      breach_count <- sum(plot_data$breaches, na.rm = TRUE)
      expected_breaches <- nrow(plot_data) * (100 - input$confidenceLevel) / 100
      
      p <- p %>% add_annotations(
        x = 0.02, y = 0.98, xref = "paper", yref = "paper",
        text = paste0("VaR Breaches: ", breach_count, " (Expected: ", round(expected_breaches, 1), ")"),
        showarrow = FALSE, font = list(size = 12)
      )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Expected Shortfall chart
  output$expectedShortfall <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = min(800, nrow(pair_data())))
    
    if (nrow(data) < input$varWindow) {
      return(plot_ly() %>% layout(title = "Insufficient data for ES analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns
      var_percentile <- (100 - input$confidenceLevel) / 100
      window_size <- min(input$varWindow, length(returns) - 50)
      
      # Calculate rolling Expected Shortfall
      rolling_es <- rollapply(returns, window_size, 
                              function(x) {
                                adj_ret <- x * sqrt(input$timeHorizon)
                                var_threshold <- quantile(adj_ret, var_percentile, na.rm = TRUE)
                                tail_losses <- adj_ret[adj_ret <= var_threshold]
                                if (length(tail_losses) > 0) mean(tail_losses) else var_threshold
                              },
                              fill = NA, align = "right")
      
      es_data <- data.frame(
        Timestamp = tail(data$Timestamp, length(rolling_es)),
        es_value = abs(rolling_es) * input$portfolioValue
      ) %>%
        filter(!is.na(es_value))
      
      if (nrow(es_data) == 0) {
        return(plot_ly() %>% layout(title = "No valid ES data"))
      }
      
      p <- plot_ly(es_data, x = ~Timestamp, y = ~es_value, type = "scatter", mode = "lines",
                   line = list(color = "#8e44ad", width = 2)) %>%
        layout(
          title = paste("Expected Shortfall -", input$selectedPair),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "USD", tickformat = "$,.0f"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Drawdown analysis
  output$drawdownAnalysis <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < 50) {
      return(plot_ly() %>% layout(title = "Insufficient data for drawdown analysis"))
    }
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      # Calculate cumulative returns and drawdown
      cumulative_returns <- cumprod(1 + returns)
      running_max <- cummax(cumulative_returns)
      drawdown <- (cumulative_returns - running_max) / running_max * 100
      
      # Calculate portfolio value impact
      portfolio_drawdown <- drawdown * input$portfolioValue / 100
      
      dd_data <- data.frame(
        Timestamp = tail(data$Timestamp, length(drawdown)),
        drawdown_pct = drawdown,
        drawdown_dollar = portfolio_drawdown
      )
      
      p <- plot_ly(dd_data, x = ~Timestamp, y = ~drawdown_pct, type = "scatter", mode = "lines",
                   fill = 'tonexty', fillcolor = 'rgba(214, 39, 40, 0.3)',
                   line = list(color = '#d62728', width = 2)) %>%
        layout(
          title = paste("Drawdown Analysis -", input$selectedPair),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "Drawdown (%)"),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      # Add max drawdown annotation
      max_dd <- min(drawdown, na.rm = TRUE)
      max_dd_date <- dd_data$Timestamp[which.min(drawdown)]
      
      p <- p %>% add_annotations(
        x = max_dd_date, y = max_dd,
        text = paste0("Max DD: ", round(max_dd, 2), "%"),
        showarrow = TRUE, arrowhead = 2,
        font = list(size = 12, color = "#d62728")
      )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Risk statistics table
  output$riskStatsTable <- renderDT({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = input$varWindow)
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      if (length(returns) < 30) {
        return(datatable(data.frame(Metric = "Error", Value = "Insufficient data")))
      }
      
      # Calculate comprehensive risk statistics
      adj_returns <- returns * sqrt(input$timeHorizon)
      
      # Basic statistics
      mean_return <- mean(adj_returns, na.rm = TRUE)
      vol <- sd(adj_returns, na.rm = TRUE)
      skewness <- sum((adj_returns - mean_return)^3/vol^3) / length(adj_returns)
      kurtosis <- sum((adj_returns - mean_return)^4/vol^4) / length(adj_returns) - 3
      
      # Risk metrics
      var_95 <- quantile(adj_returns, 0.05, na.rm = TRUE)
      var_99 <- quantile(adj_returns, 0.01, na.rm = TRUE)
      es_95 <- mean(adj_returns[adj_returns <= var_95], na.rm = TRUE)
      es_99 <- mean(adj_returns[adj_returns <= var_99], na.rm = TRUE)
      
      # Sharpe and Sortino ratios
      sharpe_ratio <- mean_return / vol * sqrt(252)
      downside_vol <- sqrt(mean(pmin(adj_returns - mean_return, 0)^2, na.rm = TRUE))
      sortino_ratio <- mean_return / downside_vol * sqrt(252)
      
      # Maximum loss/gain
      max_loss <- min(adj_returns, na.rm = TRUE)
      max_gain <- max(adj_returns, na.rm = TRUE)
      
      risk_stats <- data.frame(
        Metric = c("Mean Return (%)", "Volatility (%)", "Skewness", "Excess Kurtosis",
                   "VaR 95% ($)", "VaR 99% ($)", "ES 95% ($)", "ES 99% ($)",
                   "Sharpe Ratio", "Sortino Ratio", "Max Loss ($)", "Max Gain ($)"),
        Value = c(
          round(mean_return * 100, 4),
          round(vol * 100, 4),
          round(skewness, 3),
          round(kurtosis, 3),
          format(round(abs(var_95) * input$portfolioValue, 0), big.mark = ","),
          format(round(abs(var_99) * input$portfolioValue, 0), big.mark = ","),
          format(round(abs(es_95) * input$portfolioValue, 0), big.mark = ","),
          format(round(abs(es_99) * input$portfolioValue, 0), big.mark = ","),
          round(sharpe_ratio, 3),
          round(sortino_ratio, 3),
          format(round(abs(max_loss) * input$portfolioValue, 0), big.mark = ","),
          format(round(max_gain * input$portfolioValue, 0), big.mark = ",")
        ),
        stringsAsFactors = FALSE
      )
      
      datatable(risk_stats, options = list(dom = 't', pageLength = 12), rownames = FALSE) %>%
        formatStyle(columns = "Value", textAlign = "right")
      
    }, error = function(e) {
      datatable(data.frame(Metric = "Error", Value = e$message))
    })
  })
  
  # Stress test results
  output$stressTestResults <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    tryCatch({
      # Calculate returns if not available
      if (!"returns" %in% names(data)) {
        data <- data %>%
          arrange(Timestamp) %>%
          mutate(returns = c(NA, diff(log(Mid))))
      }
      
      returns <- data$returns[!is.na(data$returns)]
      
      if (length(returns) < 100) {
        return(datatable(data.frame(Scenario = "Error", Impact = "Insufficient data")))
      }
      
      # Historical volatility and mean for stress scenarios
      hist_vol <- sd(returns, na.rm = TRUE) * sqrt(input$timeHorizon)
      hist_mean <- mean(returns, na.rm = TRUE) * input$timeHorizon
      
      # Define stress scenarios
      stress_scenarios <- data.frame(
        Scenario = c(
          "1-Day 99.9% VaR",
          "2008 Crisis Level (-3 sigma)",
          "Flash Crash (-4 sigma)",
          "Brexit Shock (-2.5 sigma)",
          "COVID-19 Impact (-3.5 sigma)",
          "Moderate Stress (-2 sigma)",
          "Extreme Bull (+3 sigma)",
          "Currency Intervention (+/-5 sigma)"
        ),
        Probability = c("0.1%", "0.3%", "0.006%", "1.2%", "0.05%", "4.5%", "0.3%", "0.0006%"),
        Return_Impact = c(
          paste0(round((hist_mean - 3.09 * hist_vol) * 100, 2), "%"),
          paste0(round((hist_mean - 3.0 * hist_vol) * 100, 2), "%"),
          paste0(round((hist_mean - 4.0 * hist_vol) * 100, 2), "%"),
          paste0(round((hist_mean - 2.5 * hist_vol) * 100, 2), "%"),
          paste0(round((hist_mean - 3.5 * hist_vol) * 100, 2), "%"),
          paste0(round((hist_mean - 2.0 * hist_vol) * 100, 2), "%"),
          paste0("+", round((hist_mean + 3.0 * hist_vol) * 100, 2), "%"),
          paste0("±", round(5.0 * hist_vol * 100, 2), "%")
        ),
        Portfolio_Impact = c(
          paste0("-$", format(round(abs(hist_mean - 3.09 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("-$", format(round(abs(hist_mean - 3.0 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("-$", format(round(abs(hist_mean - 4.0 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("-$", format(round(abs(hist_mean - 2.5 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("-$", format(round(abs(hist_mean - 3.5 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("-$", format(round(abs(hist_mean - 2.0 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("+$", format(round((hist_mean + 3.0 * hist_vol) * input$portfolioValue, 0), big.mark = ",")),
          paste0("±$", format(round(5.0 * hist_vol * input$portfolioValue, 0), big.mark = ","))
        ),
        Recovery_Time = c(
          "1-3 months", "12-18 months", "3-6 months", "6-9 months", 
          "9-12 months", "2-4 weeks", "Immediate", "1-6 months"
        ),
        stringsAsFactors = FALSE
      )
      
      datatable(stress_scenarios, 
                options = list(dom = 't', pageLength = 8, scrollX = TRUE), 
                rownames = FALSE) %>%
        formatStyle(columns = "Portfolio_Impact", 
                    backgroundColor = styleInterval(c(0), c("#f8d7da", "#d4edda")))
      
    }, error = function(e) {
      datatable(data.frame(Scenario = "Error", Impact = e$message))
    })
  })
  
  # Check if correlation controls should be shown
  output$showCorrelationControls <- reactive({
    if (!values$data_loaded || is.null(values$fx_data)) return(FALSE)
    
    # Check if we have multiple pairs
    unique_pairs <- unique(values$fx_data$pair)
    return(length(unique_pairs) > 1)
  })
  outputOptions(output, "showCorrelationControls", suspendWhenHidden = FALSE)
  
  # Data source information
  output$correlationDataSource <- renderText({
    if (!values$data_loaded) return("No data loaded")
    
    unique_pairs <- unique(values$fx_data$pair)
    source_info <- paste("Source:", values$source_table)
    pair_info <- paste("Pairs available:", length(unique_pairs))
    
    if (length(unique_pairs) > 1) {
      return(paste(source_info, pair_info, "✓ Multi-pair analysis ready", sep = " | "))
    } else {
      return(paste(source_info, pair_info, "⚠ Single pair only", sep = " | "))
    }
  })
  
  # Update correlation pair choices when data loads
  observe({
    if (values$data_loaded && !is.null(values$fx_data)) {
      available_pairs <- sort(unique(values$fx_data$pair))
      
      if (length(available_pairs) > 1) {
        updateCheckboxGroupInput(session, "correlationPairs",
                                 choices = available_pairs,
                                 selected = available_pairs[1:min(6, length(available_pairs))])
      }
    }
  })
  
  # Correlation summary
  output$correlationSummary <- renderText({
    if (!values$data_loaded || is.null(values$fx_data)) return("No data available")
    
    if (is.null(input$correlationPairs) || length(input$correlationPairs) < 2) {
      return("Select at least 2 currency pairs for correlation analysis")
    }
    
    tryCatch({
      # Filter data for selected pairs
      corr_data <- values$fx_data %>%
        filter(pair %in% input$correlationPairs) %>%
        select(date, Timestamp, pair, Mid) %>%
        arrange(pair, Timestamp) %>%
        group_by(pair) %>%
        mutate(
          returns = if (input$returnType == "log") {
            c(NA, diff(log(Mid)))
          } else {
            c(NA, diff(Mid) / head(Mid, -1))
          }
        ) %>%
        ungroup() %>%
        filter(!is.na(returns)) %>%
        select(date, pair, returns) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-date) %>%
        na.omit()
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) {
        return("Insufficient overlapping data for correlation analysis")
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Summary statistics
      upper_tri <- corr_matrix[upper.tri(corr_matrix)]
      avg_corr <- mean(upper_tri, na.rm = TRUE)
      max_corr <- max(upper_tri, na.rm = TRUE)
      min_corr <- min(upper_tri, na.rm = TRUE)
      
      # Find most/least correlated pairs
      max_idx <- which(corr_matrix == max_corr & upper.tri(corr_matrix), arr.ind = TRUE)[1,]
      min_idx <- which(corr_matrix == min_corr & upper.tri(corr_matrix), arr.ind = TRUE)[1,]
      
      most_corr_pair <- paste(rownames(corr_matrix)[max_idx[1]], colnames(corr_matrix)[max_idx[2]], sep = " vs ")
      least_corr_pair <- paste(rownames(corr_matrix)[min_idx[1]], colnames(corr_matrix)[min_idx[2]], sep = " vs ")
      
      paste(
        paste("Pairs analyzed:", length(input$correlationPairs)),
        paste("Complete observations:", nrow(corr_data)),
        paste("Method:", input$correlationType),
        "",
        paste("Average correlation:", round(avg_corr, 3)),
        paste("Highest correlation:", round(max_corr, 3)),
        paste("Lowest correlation:", round(min_corr, 3)),
        "",
        paste("Most correlated:", most_corr_pair),
        paste("Least correlated:", least_corr_pair),
        sep = "\n"
      )
    }, error = function(e) {
      paste("Error calculating correlations:", e$message)
    })
  })
  
  # Correlation heatmap
  output$correlationHeatmap <- renderPlot({
    if (!values$data_loaded || is.null(input$correlationPairs) || length(input$correlationPairs) < 2) {
      plot.new()
      text(0.5, 0.5, "Select at least 2 currency pairs", cex = 1.5)
      return()
    }
    
    tryCatch({
      # Prepare data
      corr_data <- values$fx_data %>%
        filter(pair %in% input$correlationPairs) %>%
        select(date, Timestamp, pair, Mid) %>%
        arrange(pair, Timestamp) %>%
        group_by(pair) %>%
        mutate(
          returns = if (input$returnType == "log") {
            c(NA, diff(log(Mid)))
          } else {
            c(NA, diff(Mid) / head(Mid, -1))
          }
        ) %>%
        ungroup() %>%
        filter(!is.na(returns)) %>%
        select(date, pair, returns) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-date) %>%
        na.omit()
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) {
        plot.new()
        text(0.5, 0.5, "Insufficient overlapping data", cex = 1.2)
        return()
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Create heatmap using corrplot
      corrplot(corr_matrix, method = "color", type = "upper", 
               order = "hclust", tl.cex = 1.0, tl.col = "#2c3e50",
               cl.cex = 1.0, addCoef.col = "#2c3e50", number.cex = 1.0,
               col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200),
               title = paste("Correlation Matrix -", input$correlationType, "| Obs:", nrow(corr_data)),
               mar = c(0,0,2,0))
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, "Error creating correlation heatmap", cex = 1.2)
    })
  })
  
  # Rolling correlations
  output$rollingCorrelations <- renderPlotly({
    if (!values$data_loaded || is.null(input$correlationPairs) || length(input$correlationPairs) < 2) {
      return(plot_ly() %>% layout(title = "Select at least 2 currency pairs"))
    }
    
    tryCatch({
      # Use first two selected pairs for rolling correlation
      selected_pairs <- input$correlationPairs[1:2]
      
      corr_data <- values$fx_data %>%
        filter(pair %in% selected_pairs) %>%
        select(date, Timestamp, pair, Mid) %>%
        arrange(pair, Timestamp) %>%
        group_by(pair) %>%
        mutate(
          returns = if (input$returnType == "log") {
            c(NA, diff(log(Mid)))
          } else {
            c(NA, diff(Mid) / head(Mid, -1))
          }
        ) %>%
        ungroup() %>%
        filter(!is.na(returns)) %>%
        select(Timestamp, pair, returns) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns)
      
      # Remove rows with NA values
      corr_data <- corr_data[complete.cases(corr_data), ]
      
      if (ncol(corr_data) < 3 || nrow(corr_data) < input$correlationWindow) {
        return(plot_ly() %>% layout(title = "Insufficient data for rolling correlation"))
      }
      
      # Calculate rolling correlation
      rolling_corr <- rollapply(corr_data[, 2:3], width = input$correlationWindow,
                                FUN = function(x) cor(x[,1], x[,2], use = "complete.obs", method = input$correlationType),
                                fill = NA, align = "right", by.column = FALSE)
      
      corr_df <- data.frame(
        Timestamp = tail(corr_data$Timestamp, length(rolling_corr)),
        correlation = rolling_corr
      ) %>%
        filter(!is.na(correlation))
      
      if (nrow(corr_df) == 0) {
        return(plot_ly() %>% layout(title = "No valid rolling correlation data"))
      }
      
      p <- plot_ly(corr_df, x = ~Timestamp, y = ~correlation, type = "scatter", mode = "lines",
                   line = list(color = "#3498db", width = 2)) %>%
        layout(
          title = paste("Rolling Correlation:", paste(selected_pairs, collapse = " vs "), 
                        "| Window:", input$correlationWindow),
          xaxis = list(title = "Date/Time"),
          yaxis = list(title = "Correlation", range = c(-1, 1)),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          shapes = list(
            # Zero line
            list(type = "line", x0 = min(corr_df$Timestamp), x1 = max(corr_df$Timestamp),
                 y0 = 0, y1 = 0, line = list(color = "#95a5a6", dash = "dash", width = 1))
          )
        )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Correlation network visualization
  output$correlationNetwork <- renderPlotly({
    if (!values$data_loaded || is.null(input$correlationPairs) || length(input$correlationPairs) < 3) {
      return(plot_ly() %>% layout(title = "Select at least 3 currency pairs for network analysis"))
    }
    
    tryCatch({
      # Prepare correlation data
      corr_data <- values$fx_data %>%
        filter(pair %in% input$correlationPairs) %>%
        select(date, pair, Mid) %>%
        arrange(pair, date) %>%
        group_by(pair) %>%
        mutate(
          returns = if (input$returnType == "log") {
            c(NA, diff(log(Mid)))
          } else {
            c(NA, diff(Mid) / head(Mid, -1))
          }
        ) %>%
        ungroup() %>%
        filter(!is.na(returns)) %>%
        select(date, pair, returns) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-date) %>%
        na.omit()
      
      if (ncol(corr_data) < 3 || nrow(corr_data) < 50) {
        return(plot_ly() %>% layout(title = "Insufficient data for network analysis"))
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Create network layout (simple circular arrangement)
      n_pairs <- ncol(corr_data)
      angles <- seq(0, 2*pi, length.out = n_pairs + 1)[-1]
      radius <- 1
      
      node_x <- cos(angles) * radius
      node_y <- sin(angles) * radius
      node_names <- colnames(corr_data)
      
      # Create edges for strong correlations (>0.3 or <-0.3)
      edge_x <- c()
      edge_y <- c()
      edge_strength <- c()
      
      for (i in 1:(n_pairs-1)) {
        for (j in (i+1):n_pairs) {
          corr_val <- corr_matrix[i, j]
          if (abs(corr_val) > 0.3) {
            edge_x <- c(edge_x, node_x[i], node_x[j], NA)
            edge_y <- c(edge_y, node_y[i], node_y[j], NA)
            edge_strength <- c(edge_strength, abs(corr_val))
          }
        }
      }
      
      # Create plot
      p <- plot_ly() %>%
        # Add edges
        add_lines(x = edge_x, y = edge_y, 
                  line = list(color = "#95a5a6", width = 1),
                  hoverinfo = "none", showlegend = FALSE) %>%
        # Add nodes
        add_markers(x = node_x, y = node_y, 
                    text = node_names,
                    marker = list(size = 20, color = "#3498db"),
                    hovertemplate = "%{text}<extra></extra>",
                    showlegend = FALSE) %>%
        # Add node labels
        add_annotations(x = node_x * 1.15, y = node_y * 1.15, 
                        text = node_names,
                        showarrow = FALSE, font = list(size = 12)) %>%
        layout(
          title = "Correlation Network (|r| > 0.3)",
          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, range = c(-1.5, 1.5)),
          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, range = c(-1.5, 1.5)),
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
      
      p
    }, error = function(e) {
      plot_ly() %>% layout(title = paste("Error:", e$message))
    })
  })
  
  # Correlation statistics table
  output$correlationStatsTable <- renderDT({
    if (!values$data_loaded || is.null(input$correlationPairs) || length(input$correlationPairs) < 2) {
      return(datatable(data.frame(Message = "Select at least 2 currency pairs")))
    }
    
    tryCatch({
      # Prepare data
      corr_data <- values$fx_data %>%
        filter(pair %in% input$correlationPairs) %>%
        select(date, pair, Mid) %>%
        arrange(pair, date) %>%
        group_by(pair) %>%
        mutate(
          returns = if (input$returnType == "log") {
            c(NA, diff(log(Mid)))
          } else {
            c(NA, diff(Mid) / head(Mid, -1))
          }
        ) %>%
        ungroup() %>%
        filter(!is.na(returns)) %>%
        select(date, pair, returns) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-date) %>%
        na.omit()
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) {
        return(datatable(data.frame(Message = "Insufficient overlapping data")))
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Create pairwise correlation statistics
      stats_list <- list()
      pair_names <- colnames(corr_data)
      
      for (i in 1:(length(pair_names)-1)) {
        for (j in (i+1):length(pair_names)) {
          pair1 <- pair_names[i]
          pair2 <- pair_names[j]
          corr_val <- corr_matrix[i, j]
          
          # Additional statistics
          x <- corr_data[[pair1]]
          y <- corr_data[[pair2]]
          
          # Test correlation significance
          cor_test <- cor.test(x, y, method = input$correlationType)
          p_value <- cor_test$p.value
          
          stats_list[[length(stats_list) + 1]] <- data.frame(
            Pair1 = pair1,
            Pair2 = pair2,
            Correlation = round(corr_val, 4),
            P_Value = round(p_value, 4),
            Significant = ifelse(p_value < 0.05, "Yes", "No"),
            Strength = case_when(
              abs(corr_val) >= 0.7 ~ "Strong",
              abs(corr_val) >= 0.3 ~ "Moderate", 
              TRUE ~ "Weak"
            ),
            Direction = ifelse(corr_val > 0, "Positive", "Negative")
          )
        }
      }
      
      stats_df <- do.call(rbind, stats_list)
      
      datatable(stats_df, 
                options = list(pageLength = 10, scrollX = TRUE), 
                rownames = FALSE) %>%
        formatStyle(columns = "Correlation",
                    backgroundColor = styleInterval(c(-0.5, 0, 0.5), 
                                                    c("#f8d7da", "#fff3cd", "#d4edda", "#c3e6cb"))) %>%
        formatStyle(columns = "Significant",
                    backgroundColor = styleEqual("Yes", "#d4edda"))
      
    }, error = function(e) {
      datatable(data.frame(Error = paste("Error:", e$message)))
    })
  })
  
  # Session cleanup
  session$onSessionEnded(function() {
    tryCatch({
      if (!is.null(connection_ref)) {
        dbDisconnect(connection_ref)
        connection_ref <<- NULL
      }
    }, error = function(e) {
      # Silently handle disconnect errors
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)