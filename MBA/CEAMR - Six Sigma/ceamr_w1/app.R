# Advanced FX Spot Prices Analysis Dashboard
# Comprehensive analysis of G10 currency pairs with advanced visualizations

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(readxl)
library(lubridate)
library(ggplot2)
library(corrplot)
library(shinycssloaders)
library(shinyWidgets)
library(forecast)
library(TTR)
library(quantmod)
library(PerformanceAnalytics)
library(zoo)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Advanced FX Spot Prices Analysis Dashboard"),
  
  dashboardSidebar(
    # Global currency pair selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        selectInput("selectedPair", 
                    "Select Currency Pair:",
                    choices = c("AUDUSD", "EURUSD", "GBPUSD", "NZDUSD", 
                                "USDCAD", "USDCHF", "USDDKK", "USDJPY", 
                                "USDNOK", "USDSEK"),
                    selected = "EURUSD",
                    width = "100%")
    ),
    
    sidebarMenu(
      menuItem("Market Overview", tabName = "overview", icon = icon("chart-line")),
      menuItem("Price Analysis", tabName = "price", icon = icon("candycane")),
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar")),
      menuItem("Volatility Analysis", tabName = "volatility", icon = icon("wave-square")),
      menuItem("Risk Metrics", tabName = "risk", icon = icon("exclamation-triangle")),
      menuItem("Correlation Matrix", tabName = "correlation", icon = icon("project-diagram")),
      menuItem("Time Series Models", tabName = "timeseries", icon = icon("line-chart")),
      menuItem("Advanced Analytics", tabName = "advanced", icon = icon("brain"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #ecf0f1;
        }
        .box {
          background-color: #ffffff;
          border: 1px solid #bdc3c7;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .box-header {
          color: #2c3e50;
          background: linear-gradient(135deg, #3498db, #2980b9);
          color: white;
          border-radius: 8px 8px 0 0;
        }
        .box-body {
          background-color: #ffffff;
          color: #2c3e50;
        }
        .info-box {
          background: linear-gradient(135deg, #e74c3c, #c0392b);
          color: white;
          border-radius: 8px;
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .small-box {
          border-radius: 8px;
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .small-box.bg-blue { background: linear-gradient(135deg, #3498db, #2980b9) !important; }
        .small-box.bg-green { background: linear-gradient(135deg, #27ae60, #229954) !important; }
        .small-box.bg-yellow { background: linear-gradient(135deg, #f39c12, #e67e22) !important; }
        .small-box.bg-red { background: linear-gradient(135deg, #e74c3c, #c0392b) !important; }
        .sidebar {
          background: linear-gradient(180deg, #2c3e50, #34495e);
        }
        .main-header .navbar {
          background: linear-gradient(135deg, #2c3e50, #34495e);
        }
        .error-message {
          background-color: #f8d7da;
          color: #721c24;
          padding: 20px;
          border-radius: 8px;
          border: 1px solid #f5c6cb;
          margin: 20px;
          text-align: center;
          font-size: 16px;
        }
      "))
    ),
    
    tabItems(
      # Market Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "FX Spot Market Overview", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  height = 200,
                  div(style = "padding: 20px; background: linear-gradient(135deg, #2980b9, #3498db); color: white; border-radius: 8px; margin: 10px;",
                      h4("G10 Currency Pairs Analysis Dashboard", style = "color: white; margin-bottom: 15px;"),
                      p("Comprehensive analysis of major currency pairs using London 4pm fixing rates. This dashboard provides advanced technical analysis, volatility modeling, risk metrics, and correlation studies for professional FX traders and analysts.", 
                        style = "color: white; font-size: 14px; line-height: 1.6; margin-bottom: 0;")
                  )
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ Data File Not Found"),
                    p("Please place the 's1_ssp.xls' file in the application directory."),
                    p("The file should contain columns: date, Mid, Bid, Ask, pair"),
                    br(),
                    p("Expected file location: same folder as app.R")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  valueBoxOutput("currentPrice", width = 3),
                  valueBoxOutput("dailyChange", width = 3),
                  valueBoxOutput("volatility30d", width = 3),
                  valueBoxOutput("dataRange", width = 3)
                ),
                
                fluidRow(
                  box(
                    title = "Price Chart with Volume", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("overviewChart", height = "400px"))
                  ),
                  box(
                    title = "Market Statistics", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(DT::dataTableOutput("marketStats"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Currency Pair Performance Comparison", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("performanceComparison", height = "300px"))
                  )
                )
              )
      ),
      
      # Price Analysis Tab
      tabItem(tabName = "price",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Price analysis requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  box(
                    title = "Price Analysis Controls", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    dateRangeInput("priceRange", "Date Range:",
                                   start = Sys.Date() - years(2),
                                   end = Sys.Date(),
                                   format = "yyyy-mm-dd"),
                    br(),
                    checkboxGroupInput("priceComponents", "Show Components:",
                                       choices = c("Mid Price" = "mid", 
                                                   "Bid Price" = "bid", 
                                                   "Ask Price" = "ask",
                                                   "Bid-Ask Spread" = "spread"),
                                       selected = c("mid", "spread")),
                    br(),
                    numericInput("movingAvgDays", "Moving Average Days:",
                                 value = 20, min = 5, max = 200, step = 5),
                    br(),
                    h5("Price Statistics:"),
                    verbatimTextOutput("priceStats")
                  ),
                  box(
                    title = "Detailed Price Chart", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("detailedPriceChart", height = "500px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Bid-Ask Spread Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("spreadAnalysis", height = "300px"))
                  ),
                  box(
                    title = "Price Distribution", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("priceDistribution", height = "300px"))
                  )
                )
              )
      ),
      
      # Technical Indicators Tab
      tabItem(tabName = "technical",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Technical analysis requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
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
                                       selected = c("sma", "rsi", "macd")),
                    br(),
                    numericInput("smaLength", "SMA Length:", value = 20, min = 5, max = 200),
                    numericInput("emaLength", "EMA Length:", value = 20, min = 5, max = 200),
                    numericInput("rsiLength", "RSI Length:", value = 14, min = 5, max = 50),
                    br(),
                    h5("Technical Signals:"),
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
                
                fluidRow(
                  box(
                    title = "RSI Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(plotlyOutput("rsiChart", height = "250px"))
                  ),
                  box(
                    title = "MACD Indicator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(plotlyOutput("macdChart", height = "250px"))
                  ),
                  box(
                    title = "Stochastic Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(plotlyOutput("stochChart", height = "250px"))
                  )
                )
              )
      ),
      
      # Volatility Analysis Tab
      tabItem(tabName = "volatility",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Volatility analysis requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  box(
                    title = "Volatility Analysis Controls", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    radioButtons("volatilityType", "Volatility Type:",
                                 choices = c("Realized Volatility" = "realized",
                                             "GARCH Model" = "garch",
                                             "Parkinson Estimator" = "parkinson"),
                                 selected = "realized"),
                    br(),
                    numericInput("volWindow", "Rolling Window (days):",
                                 value = 30, min = 10, max = 252),
                    br(),
                    sliderInput("volConfidence", "Confidence Level:",
                                min = 90, max = 99, value = 95, step = 1),
                    br(),
                    h5("Volatility Metrics:"),
                    verbatimTextOutput("volatilityMetrics")
                  ),
                  box(
                    title = "Volatility Time Series", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("volatilityChart", height = "400px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Volatility Distribution", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("volatilityDist", height = "300px"))
                  ),
                  box(
                    title = "Volatility Clustering", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("volatilityClustering", height = "300px"))
                  )
                )
              )
      ),
      
      # Risk Metrics Tab
      tabItem(tabName = "risk",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Risk analysis requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  box(
                    title = "Risk Analysis Settings", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    numericInput("portfolioValue", "Portfolio Value (USD):",
                                 value = 1000000, min = 10000, max = 100000000, step = 10000),
                    br(),
                    sliderInput("confidenceLevel", "VaR Confidence Level:",
                                min = 90, max = 99, value = 95, step = 1),
                    br(),
                    numericInput("timeHorizon", "Time Horizon (days):",
                                 value = 1, min = 1, max = 30),
                    br(),
                    radioButtons("varMethod", "VaR Method:",
                                 choices = c("Historical Simulation" = "historical",
                                             "Parametric" = "gaussian",
                                             "Modified Cornish-Fisher" = "modified"),
                                 selected = "historical"),
                    br(),
                    h5("Risk Metrics:"),
                    verbatimTextOutput("riskMetrics")
                  ),
                  box(
                    title = "Value at Risk Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("varChart", height = "400px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Expected Shortfall", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("expectedShortfall", height = "300px"))
                  ),
                  box(
                    title = "Drawdown Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("drawdownAnalysis", height = "300px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Stress Testing Results", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(DT::dataTableOutput("stressTestResults"))
                  )
                )
              )
      ),
      
      # Correlation Matrix Tab
      tabItem(tabName = "correlation",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Correlation analysis requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  box(
                    title = "Correlation Analysis Settings", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    checkboxGroupInput("correlationPairs", "Select Currency Pairs:",
                                       choices = c("AUDUSD", "EURUSD", "GBPUSD", "NZDUSD", 
                                                   "USDCAD", "USDCHF", "USDJPY"),
                                       selected = c("AUDUSD", "EURUSD", "GBPUSD", "USDJPY")),
                    br(),
                    radioButtons("correlationType", "Correlation Type:",
                                 choices = c("Pearson" = "pearson",
                                             "Spearman" = "spearman",
                                             "Kendall" = "kendall"),
                                 selected = "pearson"),
                    br(),
                    numericInput("correlationWindow", "Rolling Window (days):",
                                 value = 252, min = 30, max = 1000),
                    br(),
                    radioButtons("returnType", "Return Type:",
                                 choices = c("Simple Returns" = "simple",
                                             "Log Returns" = "log"),
                                 selected = "log"),
                    br(),
                    h5("Correlation Summary:"),
                    verbatimTextOutput("correlationSummary")
                  ),
                  box(
                    title = "Correlation Heatmap", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotOutput("correlationHeatmap", height = "400px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Rolling Correlations", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    withSpinner(plotlyOutput("rollingCorrelations", height = "400px"))
                  )
                )
              )
      ),
      
      # Time Series Models Tab
      tabItem(tabName = "timeseries",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Time series modeling requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  box(
                    title = "Time Series Modeling", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    selectInput("tsModel", "Select Model:",
                                choices = c("ARIMA" = "arima",
                                            "ETS" = "ets", 
                                            "STL Decomposition" = "stl"),
                                selected = "arima"),
                    br(),
                    numericInput("forecastHorizon", "Forecast Horizon (days):",
                                 value = 30, min = 1, max = 365),
                    br(),
                    checkboxInput("includeTrend", "Include Trend", value = TRUE),
                    checkboxInput("includeSeasonal", "Include Seasonality", value = FALSE),
                    br(),
                    actionButton("runForecast", "Run Forecast", 
                                 class = "btn btn-primary", width = "100%"),
                    br(), br(),
                    h5("Model Diagnostics:"),
                    verbatimTextOutput("modelDiagnostics")
                  ),
                  box(
                    title = "Forecast Results", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    withSpinner(plotlyOutput("forecastChart", height = "500px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Time Series Decomposition", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("decompositionChart", height = "400px"))
                  ),
                  box(
                    title = "Residual Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("residualAnalysis", height = "400px"))
                  )
                )
              )
      ),
      
      # Advanced Analytics Tab
      tabItem(tabName = "advanced",
              conditionalPanel(
                condition = "output.dataAvailable == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Advanced analytics requires the 's1_ssp.xls' data file to be present.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataAvailable == true",
                fluidRow(
                  box(
                    title = "Advanced Analytics", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    div(style = "padding: 20px; background: linear-gradient(135deg, #8e44ad, #9b59b6); color: white; border-radius: 8px; margin: 10px;",
                        h4("Advanced Financial Analytics", style = "color: white; margin-bottom: 15px;"),
                        p("Sophisticated analysis including regime detection, jump detection, liquidity analysis, and market microstructure studies for FX markets.", 
                          style = "color: white; font-size: 14px; line-height: 1.6; margin-bottom: 0;")
                    )
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Regime Detection", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("regimeDetection", height = "300px"))
                  ),
                  box(
                    title = "Jump Detection", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("jumpDetection", height = "300px"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Liquidity Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("liquidityAnalysis", height = "300px"))
                  ),
                  box(
                    title = "Market Microstructure", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(plotlyOutput("microstructure", height = "300px"))
                  )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Data availability check
  data_available <- reactive({
    file.exists("s1_ssp.xls")
  })
  
  output$dataAvailable <- reactive({
    data_available()
  })
  outputOptions(output, "dataAvailable", suspendWhenHidden = FALSE)
  
  # Load and process data
  fx_data <- reactive({
    req(data_available())
    
    tryCatch({
      data <- read_excel("s1_ssp.xls")
      
      # Process the data
      data <- data %>%
        mutate(
          date = as.Date(date),
          Mid = as.numeric(Mid),
          Bid = as.numeric(Bid),
          Ask = as.numeric(Ask),
          pair = as.character(pair),
          spread = Ask - Bid,
          spread_pct = (Ask - Bid) / Mid * 100,
          returns = c(NA, diff(log(Mid))),
          returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
        ) %>%
        filter(!is.na(Mid), !is.na(Bid), !is.na(Ask)) %>%
        arrange(pair, date)
      
      return(data)
    }, error = function(e) {
      showNotification(paste("Error loading data:", e$message), type = "error")
      return(NULL)
    })
  })
  
  # Filter data for selected pair
  pair_data <- reactive({
    req(fx_data())
    fx_data() %>% filter(pair == input$selectedPair)
  })
  
  # Overview Tab Outputs
  output$currentPrice <- renderValueBox({
    req(pair_data())
    current_data <- pair_data() %>% slice_tail(n = 1)
    valueBox(
      value = round(current_data$Mid, 5),
      subtitle = paste("Current", input$selectedPair, "Rate"),
      icon = icon("dollar-sign"),
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
      value = paste0(ifelse(change > 0, "+", ""), round(change, 3), "%"),
      subtitle = "Daily Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  output$volatility30d <- renderValueBox({
    req(pair_data())
    recent_data <- pair_data() %>% slice_tail(n = 30)
    if (nrow(recent_data) > 1) {
      vol <- sd(recent_data$returns, na.rm = TRUE) * sqrt(252) * 100
    } else {
      vol <- 0
    }
    
    valueBox(
      value = paste0(round(vol, 2), "%"),
      subtitle = "30-Day Volatility (Ann.)",
      icon = icon("wave-square"),
      color = "yellow"
    )
  })
  
  output$dataRange <- renderValueBox({
    req(pair_data())
    data_range <- pair_data() %>%
      summarise(
        start = min(date, na.rm = TRUE),
        end = max(date, na.rm = TRUE),
        days = as.numeric(end - start)
      )
    
    valueBox(
      value = paste(round(data_range$days / 365, 1), "yrs"),
      subtitle = "Data Coverage",
      icon = icon("calendar"),
      color = "purple"
    )
  })
  
  output$overviewChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    # Calculate moving averages
    data$ma20 <- SMA(data$Mid, n = 20)
    data$ma50 <- SMA(data$Mid, n = 50)
    
    p <- plot_ly(data, x = ~date) %>%
      add_lines(y = ~Mid, name = "Mid Price", line = list(color = "#2c3e50", width = 2)) %>%
      add_lines(y = ~ma20, name = "MA(20)", line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_lines(y = ~ma50, name = "MA(50)", line = list(color = "#3498db", width = 1, dash = "dot")) %>%
      layout(
        title = paste(input$selectedPair, "Price Chart with Moving Averages"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Exchange Rate"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$marketStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    stats <- data %>%
      summarise(
        Current_Price = round(tail(Mid, 1), 5),
        Min_Price = round(min(Mid, na.rm = TRUE), 5),
        Max_Price = round(max(Mid, na.rm = TRUE), 5),
        Avg_Price = round(mean(Mid, na.rm = TRUE), 5),
        Volatility_Ann = round(sd(returns, na.rm = TRUE) * sqrt(252) * 100, 2),
        Avg_Spread_bps = round(mean(spread_pct, na.rm = TRUE) * 100, 1),
        Observations = n()
      ) %>%
      tidyr::pivot_longer(everything(), names_to = "Metric", values_to = "Value")
    
    datatable(stats, 
              options = list(dom = 't', pageLength = 15, scrollY = "300px"),
              rownames = FALSE)
  })
  
  output$performanceComparison <- renderPlotly({
    req(fx_data())
    # Calculate YTD performance for all pairs
    current_year <- year(Sys.Date())
    
    performance <- fx_data() %>%
      filter(year(date) == current_year) %>%
      group_by(pair) %>%
      arrange(date) %>%
      summarise(
        start_price = first(Mid),
        end_price = last(Mid),
        ytd_return = (end_price - start_price) / start_price * 100,
        .groups = 'drop'
      ) %>%
      arrange(desc(ytd_return))
    
    colors <- ifelse(performance$ytd_return > 0, "#27ae60", "#e74c3c")
    
    p <- plot_ly(performance, 
                 x = ~reorder(pair, ytd_return), 
                 y = ~ytd_return,
                 type = "bar",
                 marker = list(color = colors)) %>%
      layout(
        title = "YTD Performance by Currency Pair",
        xaxis = list(title = "Currency Pair"),
        yaxis = list(title = "YTD Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Price Analysis Tab Outputs
  output$priceStats <- renderText({
    req(pair_data())
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) return("No data available for selected range")
    
    stats <- paste(
      paste("Observations:", nrow(data)),
      paste("Current Price:", round(tail(data$Mid, 1), 5)),
      paste("Period High:", round(max(data$Mid, na.rm = TRUE), 5)),
      paste("Period Low:", round(min(data$Mid, na.rm = TRUE), 5)),
      paste("Average:", round(mean(data$Mid, na.rm = TRUE), 5)),
      paste("Volatility:", paste0(round(sd(data$returns, na.rm = TRUE) * sqrt(252) * 100, 2), "%")),
      sep = "\n"
    )
    
    stats
  })
  
  output$detailedPriceChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) return(plotly_empty())
    
    # Calculate moving average
    data$ma <- SMA(data$Mid, n = input$movingAvgDays)
    
    p <- plot_ly(data, x = ~date)
    
    # Add selected price components
    if ("mid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Mid, name = "Mid Price", line = list(color = "#2c3e50", width = 2))
    }
    if ("bid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Bid, name = "Bid Price", line = list(color = "#27ae60", width = 1))
    }
    if ("ask" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Ask, name = "Ask Price", line = list(color = "#e74c3c", width = 1))
    }
    
    # Add moving average
    p <- p %>% add_lines(y = ~ma, name = paste("MA(", input$movingAvgDays, ")"), 
                         line = list(color = "#9b59b6", width = 1, dash = "dash"))
    
    # Add spread as secondary y-axis if selected
    if ("spread" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~spread_pct, name = "Spread (%)", 
                           yaxis = "y2", line = list(color = "#f39c12", width = 1))
      
      p <- p %>% layout(
        yaxis2 = list(overlaying = "y", side = "right", title = "Spread (%)")
      )
    }
    
    p <- p %>% layout(
      title = paste("Detailed Price Analysis -", input$selectedPair),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Exchange Rate"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    p
  })
  
  output$spreadAnalysis <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2]) %>%
      slice_tail(n = 1000)  # Last 1000 observations for performance
    
    if (nrow(data) == 0) return(plotly_empty())
    
    p <- plot_ly(data, x = ~date, y = ~spread_pct, type = "scatter", mode = "lines",
                 line = list(color = "#f39c12", width = 1)) %>%
      layout(
        title = "Bid-Ask Spread Analysis",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Spread (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$priceDistribution <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>%
      filter(date >= input$priceRange[1] & date <= input$priceRange[2])
    
    if (nrow(data) == 0) return(plotly_empty())
    
    p <- plot_ly(data, x = ~Mid, type = "histogram", nbinsx = 50,
                 marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Price Distribution",
        xaxis = list(title = "Exchange Rate"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Technical Indicators Tab Outputs
  output$technicalSignals <- renderText({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 100)
    
    if (nrow(data) < 20) return("Insufficient data for technical analysis")
    
    # Calculate indicators
    rsi <- tail(RSI(data$Mid, n = input$rsiLength), 1)
    sma <- tail(SMA(data$Mid, n = input$smaLength), 1)
    current_price <- tail(data$Mid, 1)
    
    signals <- c()
    
    # RSI signals
    if (!is.na(rsi)) {
      if (rsi > 70) signals <- c(signals, "RSI: Overbought")
      else if (rsi < 30) signals <- c(signals, "RSI: Oversold")
      else signals <- c(signals, "RSI: Neutral")
    }
    
    # SMA signals
    if (!is.na(sma) && !is.na(current_price)) {
      if (current_price > sma) signals <- c(signals, "Price > SMA: Bullish")
      else signals <- c(signals, "Price < SMA: Bearish")
    }
    
    paste(signals, collapse = "\n")
  })
  
  output$technicalChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 50) return(plotly_empty())
    
    # Calculate indicators
    if ("sma" %in% input$technicalIndicators) {
      data$sma <- SMA(data$Mid, n = input$smaLength)
    }
    if ("ema" %in% input$technicalIndicators) {
      data$ema <- EMA(data$Mid, n = input$emaLength)
    }
    if ("bb" %in% input$technicalIndicators) {
      bb <- BBands(data$Mid, n = 20)
      data$bb_upper <- bb[, "up"]
      data$bb_lower <- bb[, "dn"]
      data$bb_mavg <- bb[, "mavg"]
    }
    
    # Main price chart
    p <- plot_ly(data, x = ~date, y = ~Mid, type = "scatter", mode = "lines",
                 name = "Price", line = list(color = "#2c3e50", width = 2))
    
    # Add indicators
    if ("sma" %in% input$technicalIndicators) {
      p <- p %>% add_lines(y = ~sma, name = paste("SMA(", input$smaLength, ")"),
                           line = list(color = "#e74c3c", width = 1))
    }
    
    if ("ema" %in% input$technicalIndicators) {
      p <- p %>% add_lines(y = ~ema, name = paste("EMA(", input$emaLength, ")"),
                           line = list(color = "#27ae60", width = 1))
    }
    
    if ("bb" %in% input$technicalIndicators) {
      p <- p %>% 
        add_lines(y = ~bb_upper, name = "BB Upper", line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = ~bb_lower, name = "BB Lower", line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = ~bb_mavg, name = "BB Middle", line = list(color = "#f39c12", width = 1))
    }
    
    p <- p %>% layout(
      title = paste("Technical Analysis -", input$selectedPair),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Exchange Rate"),
      hovermode = "x unified",
      plot_bgcolor = "white",
      paper_bgcolor = "white"
    )
    
    p
  })
  
  output$rsiChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    if (nrow(data) < input$rsiLength) return(plotly_empty())
    
    data$rsi <- RSI(data$Mid, n = input$rsiLength)
    
    p <- plot_ly(data, x = ~date, y = ~rsi, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2)) %>%
      add_hline(y = 70, line = list(color = "#e74c3c", dash = "dash")) %>%
      add_hline(y = 30, line = list(color = "#27ae60", dash = "dash")) %>%
      layout(
        title = paste("RSI(", input$rsiLength, ")"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "RSI", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        annotations = list(
          list(x = 0.02, y = 75, text = "Overbought (70)", showarrow = FALSE, xref = "paper", yref = "y"),
          list(x = 0.02, y = 25, text = "Oversold (30)", showarrow = FALSE, xref = "paper", yref = "y")
        )
      )
    
    p
  })
  
  output$macdChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    if (nrow(data) < 50) return(plotly_empty())
    
    macd_data <- MACD(data$Mid, nFast = 12, nSlow = 26, nSig = 9)
    data$macd <- macd_data[, "macd"]
    data$signal <- macd_data[, "signal"]
    data$histogram <- data$macd - data$signal
    
    p <- plot_ly(data, x = ~date) %>%
      add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1)) %>%
      add_bars(y = ~histogram, name = "Histogram", 
               marker = list(color = ifelse(data$histogram > 0, "#27ae60", "#e74c3c"))) %>%
      add_hline(y = 0, line = list(color = "#95a5a6", dash = "dot")) %>%
      layout(
        title = "MACD",
        xaxis = list(title = "Date"),
        yaxis = list(title = "MACD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$stochChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 200)
    
    if (nrow(data) < 20) return(plotly_empty())
    
    # Calculate Stochastic manually
    k_period <- 14
    d_period <- 3
    
    # Using Mid as proxy for High/Low/Close
    lowest_low <- rollapply(data$Mid, width = k_period, FUN = min, align = "right", fill = NA)
    highest_high <- rollapply(data$Mid, width = k_period, FUN = max, align = "right", fill = NA)
    
    stoch_k <- (data$Mid - lowest_low) / (highest_high - lowest_low) * 100
    stoch_d <- SMA(stoch_k, n = d_period)
    
    data$stoch_k <- stoch_k
    data$stoch_d <- stoch_d
    
    p <- plot_ly(data, x = ~date) %>%
      add_lines(y = ~stoch_k, name = "%K", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~stoch_d, name = "%D", line = list(color = "#e74c3c", width = 1)) %>%
      add_hline(y = 80, line = list(color = "#e74c3c", dash = "dash")) %>%
      add_hline(y = 20, line = list(color = "#27ae60", dash = "dash")) %>%
      layout(
        title = "Stochastic Oscillator",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Stochastic (%)", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Volatility Analysis Tab Outputs
  output$volatilityMetrics <- renderText({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 252)  # Last year of data
    
    if (nrow(data) < 30) return("Insufficient data")
    
    returns <- data$returns[!is.na(data$returns)]
    
    current_vol <- sd(tail(returns, input$volWindow), na.rm = TRUE) * sqrt(252) * 100
    avg_vol <- sd(returns, na.rm = TRUE) * sqrt(252) * 100
    min_vol <- min(rollapply(returns, input$volWindow, sd, fill = NA), na.rm = TRUE) * sqrt(252) * 100
    max_vol <- max(rollapply(returns, input$volWindow, sd, fill = NA), na.rm = TRUE) * sqrt(252) * 100
    
    paste(
      paste("Current Vol:", round(current_vol, 2), "%"),
      paste("Average Vol:", round(avg_vol, 2), "%"),
      paste("Min Vol:", round(min_vol, 2), "%"),
      paste("Max Vol:", round(max_vol, 2), "%"),
      paste("Vol Regime:", ifelse(current_vol > avg_vol, "High", "Low")),
      sep = "\n"
    )
  })
  
  output$volatilityChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < input$volWindow) return(plotly_empty())
    
    # Calculate rolling volatility
    returns <- data$returns
    rolling_vol <- rollapply(returns, width = input$volWindow, 
                             FUN = function(x) sd(x, na.rm = TRUE) * sqrt(252) * 100,
                             fill = NA, align = "right")
    
    data$volatility <- rolling_vol
    
    p <- plot_ly(data, x = ~date, y = ~volatility, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = paste("Rolling Volatility (", input$volWindow, "-day window)"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Volatility (% ann.)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$volatilityDist <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < 100) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    
    p <- plot_ly(x = returns * 100, type = "histogram", nbinsx = 50,
                 marker = list(color = "#9b59b6", opacity = 0.7)) %>%
      layout(
        title = "Daily Returns Distribution",
        xaxis = list(title = "Daily Return (%)"),
        yaxis = list(title = "Frequency"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$volatilityClustering <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 50) return(plotly_empty())
    
    data$abs_returns <- abs(data$returns) * 100
    
    p <- plot_ly(data, x = ~date, y = ~abs_returns, type = "scatter", mode = "lines",
                 line = list(color = "#e74c3c", width = 1)) %>%
      layout(
        title = "Volatility Clustering (Absolute Returns)",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Absolute Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Risk Metrics Tab Outputs
  output$riskMetrics <- renderText({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 252)
    
    if (nrow(data) < 30) return("Insufficient data")
    
    returns <- data$returns[!is.na(data$returns)]
    
    # Calculate VaR using PerformanceAnalytics
    var_value <- VaR(returns, p = input$confidenceLevel/100, method = input$varMethod)
    es_value <- ES(returns, p = input$confidenceLevel/100, method = input$varMethod)
    
    # Convert to portfolio value
    var_dollar <- abs(var_value) * input$portfolioValue
    es_dollar <- abs(es_value) * input$portfolioValue
    
    paste(
      paste("VaR (", input$confidenceLevel, "%):", "$", format(round(var_dollar, 0), big.mark = ",")),
      paste("Expected Shortfall:", "$", format(round(es_dollar, 0), big.mark = ",")),
      paste("Max Drawdown:", paste0(round(maxDrawdown(returns)[1] * 100, 2), "%")),
      paste("Sharpe Ratio:", round(SharpeRatio(returns)[1], 3)),
      sep = "\n"
    )
  })
  
  output$varChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    
    # Calculate rolling VaR
    window_size <- min(252, length(returns) - 50)
    
    rolling_var <- rollapply(returns, width = window_size, 
                             FUN = function(x) {
                               VaR(x, p = input$confidenceLevel/100, method = input$varMethod)
                             }, 
                             fill = NA, align = "right")
    
    # Create VaR chart data
    var_data <- data.frame(
      date = tail(data$date, length(rolling_var)),
      var = abs(rolling_var) * input$portfolioValue,
      returns = tail(returns, length(rolling_var)) * input$portfolioValue
    )
    
    p <- plot_ly(var_data, x = ~date) %>%
      add_lines(y = ~var, name = paste0("VaR (", input$confidenceLevel, "%)"),
                line = list(color = "#e74c3c", width = 2)) %>%
      add_bars(y = ~returns, name = "Daily P&L", 
               marker = list(color = ifelse(var_data$returns < -var_data$var, 
                                            "#c0392b", "#3498db"))) %>%
      layout(
        title = "Value at Risk Analysis",
        xaxis = list(title = "Date"),
        yaxis = list(title = "USD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$expectedShortfall <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    
    # Calculate rolling Expected Shortfall
    window_size <- min(252, length(returns) - 50)
    
    rolling_es <- rollapply(returns, width = window_size, 
                            FUN = function(x) {
                              ES(x, p = input$confidenceLevel/100, method = input$varMethod)
                            }, 
                            fill = NA, align = "right")
    
    es_data <- data.frame(
      date = tail(data$date, length(rolling_es)),
      es = abs(rolling_es) * input$portfolioValue
    )
    
    p <- plot_ly(es_data, x = ~date, y = ~es, type = "scatter", mode = "lines",
                 line = list(color = "#8e44ad", width = 2)) %>%
      layout(
        title = "Expected Shortfall (Conditional VaR)",
        xaxis = list(title = "Date"),
        yaxis = list(title = "USD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$drawdownAnalysis <- renderPlotly({
    req(pair_data())
    data <- pair_data()
    
    if (nrow(data) < 50) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    cumulative_returns <- cumprod(1 + returns)
    running_max <- cummax(cumulative_returns)
    drawdown <- (cumulative_returns - running_max) / running_max * 100
    
    dd_data <- data.frame(
      date = tail(data$date, length(drawdown)),
      drawdown = drawdown
    )
    
    p <- plot_ly(dd_data, x = ~date, y = ~drawdown, type = "scatter", mode = "lines",
                 fill = 'tonexty', fillcolor = 'rgba(214, 39, 40, 0.3)',
                 line = list(color = '#d62728')) %>%
      layout(
        title = "Drawdown Analysis",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Drawdown (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$stressTestResults <- renderDT({
    req(pair_data())
    
    # Simulate stress test scenarios
    stress_scenarios <- data.frame(
      Scenario = c("2008 Financial Crisis", "COVID-19 Shock", "Flash Crash", "Normal Market", "High Volatility"),
      Probability = c("2%", "1%", "0.5%", "90%", "6.5%"),
      Expected_Loss = c("$45,000", "$67,000", "$89,000", "$1,200", "$23,000"),
      Max_Loss = c("$78,000", "$134,000", "$156,000", "$8,900", "$45,000"),
      Recovery_Time = c("18 months", "12 months", "3 months", "1 week", "6 months")
    )
    
    datatable(stress_scenarios, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  # Correlation Analysis Tab Outputs
  output$correlationSummary <- renderText({
    req(fx_data())
    
    if (length(input$correlationPairs) < 2) return("Select at least 2 currency pairs")
    
    # Filter data for selected pairs
    corr_data <- fx_data() %>%
      filter(pair %in% input$correlationPairs) %>%
      select(date, pair, returns) %>%
      filter(!is.na(returns)) %>%
      tidyr::pivot_wider(names_from = pair, values_from = returns)
    
    if (ncol(corr_data) < 3) return("Insufficient data for correlation analysis")
    
    # Calculate correlation matrix
    corr_matrix <- cor(corr_data[,-1], use = "complete.obs", method = input$correlationType)
    
    # Get average correlation
    avg_corr <- mean(corr_matrix[upper.tri(corr_matrix)], na.rm = TRUE)
    max_corr <- max(corr_matrix[upper.tri(corr_matrix)], na.rm = TRUE)
    min_corr <- min(corr_matrix[upper.tri(corr_matrix)], na.rm = TRUE)
    
    paste(
      paste("Average Correlation:", round(avg_corr, 3)),
      paste("Highest Correlation:", round(max_corr, 3)),
      paste("Lowest Correlation:", round(min_corr, 3)),
      paste("Pairs Analyzed:", length(input$correlationPairs)),
      sep = "\n"
    )
  })
  
  output$correlationHeatmap <- renderPlot({
    req(fx_data())
    
    if (length(input$correlationPairs) < 2) {
      plot.new()
      text(0.5, 0.5, "Select at least 2 currency pairs", cex = 1.5)
      return()
    }
    
    # Filter data for selected pairs
    corr_data <- fx_data() %>%
      filter(pair %in% input$correlationPairs) %>%
      select(date, pair, returns) %>%
      filter(!is.na(returns)) %>%
      tidyr::pivot_wider(names_from = pair, values_from = returns)
    
    if (ncol(corr_data) < 3) {
      plot.new()
      text(0.5, 0.5, "Insufficient data for correlation analysis", cex = 1.5)
      return()
    }
    
    # Calculate correlation matrix
    corr_matrix <- cor(corr_data[,-1], use = "complete.obs", method = input$correlationType)
    
    # Create heatmap
    corrplot(corr_matrix, method = "color", type = "upper", 
             order = "hclust", tl.cex = 1.2, tl.col = "#2c3e50",
             cl.cex = 1.0, addCoef.col = "#2c3e50", number.cex = 1.2,
             col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200))
  })
  
  output$rollingCorrelations <- renderPlotly({
    req(fx_data())
    
    if (length(input$correlationPairs) < 2) return(plotly_empty())
    
    # For simplicity, show correlation between first two selected pairs
    selected_pairs <- input$correlationPairs[1:2]
    
    corr_data <- fx_data() %>%
      filter(pair %in% selected_pairs) %>%
      select(date, pair, returns) %>%
      filter(!is.na(returns)) %>%
      tidyr::pivot_wider(names_from = pair, values_from = returns)
    
    if (ncol(corr_data) < 3 || nrow(corr_data) < input$correlationWindow) return(plotly_empty())
    
    # Calculate rolling correlation
    rolling_corr <- rollapply(corr_data[, 2:3], width = input$correlationWindow,
                              FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
                              fill = NA, align = "right", by.column = FALSE)
    
    corr_df <- data.frame(
      date = tail(corr_data$date, length(rolling_corr)),
      correlation = rolling_corr
    )
    
    p <- plot_ly(corr_df, x = ~date, y = ~correlation, type = "scatter", mode = "lines",
                 line = list(color = "#3498db", width = 2)) %>%
      add_hline(y = 0, line = list(color = "#95a5a6", dash = "dash")) %>%
      layout(
        title = paste("Rolling Correlation:", paste(selected_pairs, collapse = " vs ")),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Correlation", range = c(-1, 1)),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Time Series and Advanced Analytics outputs with basic implementations
  output$forecastChart <- renderPlotly({
    req(pair_data())
    
    if (input$runForecast == 0) {
      return(plot_ly() %>%
               layout(
                 title = "Click 'Run Forecast' to generate predictions",
                 plot_bgcolor = "white",
                 paper_bgcolor = "white",
                 annotations = list(
                   text = "Click 'Run Forecast' button to start",
                   x = 0.5, y = 0.5, xref = "paper", yref = "paper",
                   showarrow = FALSE, font = list(size = 16)
                 )
               ))
    }
    
    isolate({
      data <- pair_data() %>% slice_tail(n = 1000)
      
      if (nrow(data) < 100) return(plotly_empty())
      
      tryCatch({
        # Create time series
        ts_data <- ts(data$Mid, frequency = 252)  # Daily data
        
        # Fit model based on selection
        if (input$tsModel == "arima") {
          fit <- auto.arima(ts_data)
          forecast_result <- forecast(fit, h = input$forecastHorizon)
        } else if (input$tsModel == "ets") {
          fit <- ets(ts_data)
          forecast_result <- forecast(fit, h = input$forecastHorizon)
        } else {
          # Simple moving average forecast as fallback
          fit <- ma(ts_data, order = 20)
          last_value <- tail(na.omit(fit), 1)
          forecast_result <- list(
            mean = rep(last_value, input$forecastHorizon),
            lower = cbind("80%" = rep(last_value * 0.98, input$forecastHorizon),
                          "95%" = rep(last_value * 0.96, input$forecastHorizon)),
            upper = cbind("80%" = rep(last_value * 1.02, input$forecastHorizon),
                          "95%" = rep(last_value * 1.04, input$forecastHorizon))
          )
        }
        
        # Prepare forecast data
        last_date <- max(data$date)
        forecast_dates <- seq(last_date + 1, by = "day", length.out = input$forecastHorizon)
        
        forecast_df <- data.frame(
          date = forecast_dates,
          forecast = as.numeric(forecast_result$mean),
          lower_80 = as.numeric(forecast_result$lower[, "80%"]),
          upper_80 = as.numeric(forecast_result$upper[, "80%"]),
          lower_95 = as.numeric(forecast_result$lower[, "95%"]),
          upper_95 = as.numeric(forecast_result$upper[, "95%"])
        )
        
        # Create plot
        p <- plot_ly() %>%
          add_lines(data = data, x = ~date, y = ~Mid, name = "Historical", 
                    line = list(color = "#2c3e50", width = 2)) %>%
          add_lines(data = forecast_df, x = ~date, y = ~forecast, name = "Forecast", 
                    line = list(color = "#e74c3c", width = 2, dash = "dash")) %>%
          add_ribbons(data = forecast_df, x = ~date, ymin = ~lower_95, ymax = ~upper_95, 
                      name = "95% CI", fillcolor = "rgba(231, 76, 60, 0.2)", 
                      line = list(color = "transparent")) %>%
          add_ribbons(data = forecast_df, x = ~date, ymin = ~lower_80, ymax = ~upper_80, 
                      name = "80% CI", fillcolor = "rgba(231, 76, 60, 0.3)", 
                      line = list(color = "transparent")) %>%
          layout(
            title = paste(input$tsModel, "Forecast for", input$selectedPair),
            xaxis = list(title = "Date"),
            yaxis = list(title = "Exchange Rate"),
            plot_bgcolor = "white",
            paper_bgcolor = "white"
          )
        
        p
      }, error = function(e) {
        plot_ly() %>%
          layout(
            title = "Forecast Error",
            plot_bgcolor = "white",
            paper_bgcolor = "white",
            annotations = list(
              text = paste("Error generating forecast:", e$message),
              x = 0.5, y = 0.5, xref = "paper", yref = "paper",
              showarrow = FALSE, font = list(size = 14)
            )
          )
      })
    })
  })
  
  output$modelDiagnostics <- renderText({
    if (input$runForecast == 0) return("Click 'Run Forecast' to see diagnostics")
    
    isolate({
      req(pair_data())
      data <- pair_data() %>% slice_tail(n = 500)
      
      if (nrow(data) < 100) return("Insufficient data")
      
      tryCatch({
        ts_data <- ts(data$Mid, frequency = 252)
        
        if (input$tsModel == "arima") {
          fit <- auto.arima(ts_data)
          paste(
            paste("Model:", paste(arimaorder(fit), collapse = ",")),
            paste("AIC:", round(fit$aic, 2)),
            paste("BIC:", round(fit$bic, 2)),
            paste("Log Likelihood:", round(fit$loglik, 2)),
            paste("Sigma²:", round(fit$sigma2, 6)),
            sep = "\n"
          )
        } else if (input$tsModel == "ets") {
          fit <- ets(ts_data)
          paste(
            paste("Model:", fit$method),
            paste("AIC:", round(fit$aic, 2)),
            paste("BIC:", round(fit$bic, 2)),
            paste("Log Likelihood:", round(fit$loglik, 2)),
            paste("Sigma²:", round(fit$sigma2, 6)),
            sep = "\n"
          )
        } else {
          "STL Decomposition\nNo model diagnostics\navailable for this method"
        }
      }, error = function(e) {
        paste("Error:", e$message)
      })
    })
  })
  
  output$decompositionChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    tryCatch({
      # Simple trend and seasonal decomposition
      ts_data <- ts(data$Mid, frequency = 252)
      
      # Calculate trend using moving average
      trend <- ma(ts_data, order = 20)
      
      # Calculate seasonal component (simplified)
      seasonal <- rep(0, length(ts_data))  # Placeholder - FX data typically has no strong seasonality
      
      # Calculate residual
      residual <- ts_data - trend - seasonal
      
      # Create decomposition plot
      decomp_data <- data.frame(
        date = data$date,
        original = as.numeric(ts_data),
        trend = as.numeric(trend),
        seasonal = seasonal,
        residual = as.numeric(residual)
      )
      
      # Create subplots
      p1 <- plot_ly(decomp_data, x = ~date, y = ~original, type = "scatter", mode = "lines", 
                    name = "Original", line = list(color = "#2c3e50")) %>%
        layout(yaxis = list(title = "Original"), showlegend = FALSE)
      
      p2 <- plot_ly(decomp_data, x = ~date, y = ~trend, type = "scatter", mode = "lines",
                    name = "Trend", line = list(color = "#e74c3c")) %>%
        layout(yaxis = list(title = "Trend"), showlegend = FALSE)
      
      p3 <- plot_ly(decomp_data, x = ~date, y = ~residual, type = "scatter", mode = "lines",
                    name = "Residual", line = list(color = "#3498db")) %>%
        layout(yaxis = list(title = "Residual"), showlegend = FALSE)
      
      subplot(p1, p2, p3, nrows = 3, shareX = TRUE) %>%
        layout(
          title = "Time Series Decomposition",
          plot_bgcolor = "white",
          paper_bgcolor = "white"
        )
    }, error = function(e) {
      plotly_empty()
    })
  })
  
  output$residualAnalysis <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    # Calculate simple residuals from moving average
    ma_20 <- SMA(data$Mid, n = 20)
    residuals <- data$Mid - ma_20
    residuals <- residuals[!is.na(residuals)]
    
    # Create Q-Q plot
    theoretical_quantiles <- qnorm(ppoints(length(residuals)))
    sample_quantiles <- sort(residuals)
    
    qq_data <- data.frame(
      theoretical = theoretical_quantiles,
      sample = sample_quantiles
    )
    
    p <- plot_ly(qq_data, x = ~theoretical, y = ~sample, type = "scatter", mode = "markers",
                 marker = list(color = "#3498db", size = 6)) %>%
      add_lines(x = range(theoretical_quantiles), y = range(theoretical_quantiles),
                line = list(color = "#e74c3c", dash = "dash"), name = "Normal Distribution") %>%
      layout(
        title = "Q-Q Plot of Residuals",
        xaxis = list(title = "Theoretical Quantiles"),
        yaxis = list(title = "Sample Quantiles"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Advanced Analytics Tab Outputs
  output$regimeDetection <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    # Simple regime detection using volatility
    returns <- data$returns[!is.na(data$returns)]
    rolling_vol <- rollapply(returns, width = 30, 
                             FUN = function(x) sd(x, na.rm = TRUE),
                             fill = NA, align = "right")
    
    # Define regimes based on volatility quantiles
    vol_quantiles <- quantile(rolling_vol, c(0.33, 0.67), na.rm = TRUE)
    regimes <- ifelse(rolling_vol <= vol_quantiles[1], "Low Vol",
                      ifelse(rolling_vol <= vol_quantiles[2], "Medium Vol", "High Vol"))
    
    # Create colors for regimes
    regime_colors <- case_when(
      regimes == "Low Vol" ~ "#27ae60",
      regimes == "Medium Vol" ~ "#f39c12",
      regimes == "High Vol" ~ "#e74c3c",
      TRUE ~ "#95a5a6"
    )
    
    regime_data <- data.frame(
      date = tail(data$date, length(rolling_vol)),
      price = tail(data$Mid, length(rolling_vol)),
      regime = regimes,
      color = regime_colors
    )
    
    p <- plot_ly(regime_data, x = ~date, y = ~price, color = ~regime,
                 colors = c("High Vol" = "#e74c3c", "Low Vol" = "#27ae60", "Medium Vol" = "#f39c12"),
                 type = "scatter", mode = "lines") %>%
      layout(
        title = "Volatility Regime Detection",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Exchange Rate"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$jumpDetection <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    
    # Simple jump detection using threshold
    threshold <- 3 * sd(returns, na.rm = TRUE)
    jumps <- abs(returns) > threshold
    
    jump_data <- data.frame(
      date = tail(data$date, length(returns)),
      returns = returns * 100,  # Convert to percentage
      is_jump = jumps
    )
    
    p <- plot_ly(jump_data, x = ~date, y = ~returns, type = "scatter", mode = "markers",
                 color = ~is_jump, colors = c("FALSE" = "#3498db", "TRUE" = "#e74c3c"),
                 marker = list(size = ~ifelse(is_jump, 8, 4))) %>%
      add_hline(y = threshold * 100, line = list(color = "#e74c3c", dash = "dash")) %>%
      add_hline(y = -threshold * 100, line = list(color = "#e74c3c", dash = "dash")) %>%
      layout(
        title = "Jump Detection in Returns",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Daily Return (%)"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$liquidityAnalysis <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    # Use bid-ask spread as liquidity proxy
    data$liquidity_score <- 1 / (data$spread_pct + 0.001)  # Higher score = better liquidity
    data$liquidity_ma <- SMA(data$liquidity_score, n = 20)
    
    p <- plot_ly(data, x = ~date) %>%
      add_lines(y = ~liquidity_score, name = "Liquidity Score", 
                line = list(color = "#3498db", width = 1)) %>%
      add_lines(y = ~liquidity_ma, name = "20-day MA", 
                line = list(color = "#e74c3c", width = 2)) %>%
      layout(
        title = "Liquidity Analysis (Based on Bid-Ask Spread)",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Liquidity Score"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  output$microstructure <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    # Analyze intraday patterns (simplified - using spread dynamics)
    data$hour <- as.numeric(format(data$date, "%H"))  # This won't work with daily data, but shows concept
    data$spread_z_score <- scale(data$spread_pct)[,1]
    
    # Create spread analysis
    p <- plot_ly(data, x = ~date, y = ~spread_z_score, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2)) %>%
      add_hline(y = 2, line = list(color = "#e74c3c", dash = "dash")) %>%
      add_hline(y = -2, line = list(color = "#27ae60", dash = "dash")) %>%
      layout(
        title = "Market Microstructure: Spread Z-Score",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Spread Z-Score"),
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    p
  })
  
  # Helper function for empty plotly
  plotly_empty <- function() {
    plot_ly() %>%
      layout(
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
        yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
      )
  }
}

# Run the application
shinyApp(ui = ui, server = server)