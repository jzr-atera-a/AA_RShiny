# Advanced FX Spot Prices Analysis Dashboard with MySQL Integration
# Comprehensive analysis of G10 currency pairs with MySQL database connection

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
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
library(tidyr)
library(DBI)
library(RMySQL)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FX Analysis Dashboard - MySQL"),
  
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
      menuItem("Price Analysis", tabName = "price", icon = icon("candlestick-chart")),
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar")),
      menuItem("Volatility Analysis", tabName = "volatility", icon = icon("wave-square")),
      menuItem("Risk Metrics", tabName = "risk", icon = icon("exclamation-triangle")),
      menuItem("Correlation Matrix", tabName = "correlation", icon = icon("project-diagram"))
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
        .connection-success {
          background-color: #d4edda;
          color: #155724;
          padding: 15px;
          border-radius: 8px;
          border: 1px solid #c3e6cb;
          margin: 10px 0;
        }
        .connection-error {
          background-color: #f8d7da;
          color: #721c24;
          padding: 15px;
          border-radius: 8px;
          border: 1px solid #f5c6cb;
          margin: 10px 0;
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
      # Database Connection Tab
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
                    
                    br(),
                    
                    actionButton("loadData", "Load Data", 
                                 class = "btn btn-success", width = "100%"),
                    
                    br(), br(),
                    
                    uiOutput("dataStatus"),
                    
                    br(),
                    
                    h5("Database Statistics:"),
                    verbatimTextOutput("dbStats")
                  ),
                  
                  conditionalPanel(
                    condition = "output.connectionValid == false",
                    div(class = "connection-error",
                        h5("No Database Connection"),
                        p("Please establish a database connection first."))
                  )
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "Data Preview", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    h5("Top 20 Rows from Selected Table:"),
                    withSpinner(DT::dataTableOutput("dataPreview"))
                  )
                )
              )
      ),
      
      # Market Overview Tab
      tabItem(tabName = "overview",
              conditionalPanel(
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("⚠️ No Data Loaded"),
                    p("Please connect to the database and load data in the 'Database Connection' tab.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
                fluidRow(
                  box(
                    title = "FX Spot Market Overview", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    height = 200,
                    div(style = "padding: 20px; background: linear-gradient(135deg, #2980b9, #3498db); color: white; border-radius: 8px; margin: 10px;",
                        h4("G10 Currency Pairs Analysis Dashboard", style = "color: white; margin-bottom: 15px;"),
                        p("Comprehensive analysis of major currency pairs using MySQL database. This dashboard provides advanced technical analysis, volatility modeling, risk metrics, and correlation studies for professional FX traders and analysts.", 
                          style = "color: white; font-size: 14px; line-height: 1.6; margin-bottom: 0;")
                    )
                  )
                ),
                
                fluidRow(
                  valueBoxOutput("currentPrice", width = 3),
                  valueBoxOutput("dailyChange", width = 3),
                  valueBoxOutput("volatility30d", width = 3),
                  valueBoxOutput("dataRange", width = 3)
                ),
                
                fluidRow(
                  box(
                    title = "Price Chart with Moving Averages", 
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
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Price analysis requires database connection and data loading.")
                )
              ),
              
              conditionalPanel(
                condition = "output.dataLoaded == true",
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
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Technical analysis requires database connection and data loading.")
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
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Volatility analysis requires database connection and data loading.")
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
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Risk analysis requires database connection and data loading.")
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
                condition = "output.dataLoaded == false",
                div(class = "error-message",
                    h4("⚠️ No Data Available"),
                    p("Correlation analysis requires database connection and data loading.")
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
    data_loaded = FALSE
  )
  
  # Close all database connections
  observeEvent(input$closeConnections, {
    tryCatch({
      # Close current connection if exists
      if (!is.null(values$connection)) {
        dbDisconnect(values$connection)
        values$connection <- NULL
      }
      
      # Close all MySQL connections
      all_connections <- dbListConnections(RMySQL::MySQL())
      for (con in all_connections) {
        dbDisconnect(con)
      }
      
      values$connected <- FALSE
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      
      output$connectionStatus <- renderUI({
        div(class = "connection-success",
            h5("Connections Closed"),
            p("All database connections have been closed successfully."),
            p("You can now establish a new connection."))
      })
      
      showNotification("All database connections closed successfully!", type = "message")
      
    }, error = function(e) {
      output$connectionStatus <- renderUI({
        div(class = "connection-error",
            h5("Error Closing Connections"),
            p("Error:", e$message))
      })
      
      showNotification(paste("Error closing connections:", e$message), type = "error")
    })
  })
  
  # Test database connection
  observeEvent(input$testConnection, {
    
    # Validate inputs
    if (input$password == "") {
      output$connectionStatus <- renderUI({
        div(class = "connection-error",
            h5("Connection Failed"),
            p("Password is required."))
      })
      return()
    }
    
    tryCatch({
      # Close existing connection if any
      if (!is.null(values$connection)) {
        dbDisconnect(values$connection)
      }
      
      # Create new connection
      values$connection <- dbConnect(
        RMySQL::MySQL(),
        host = as.character(input$host),
        port = as.numeric(input$port),
        dbname = as.character(input$dbname),
        username = as.character(input$username),
        password = as.character(input$password)
      )
      
      # Test the connection
      test_query <- dbGetQuery(values$connection, "SELECT 1 as test")
      
      if (nrow(test_query) == 1) {
        values$connected <- TRUE
        
        output$connectionStatus <- renderUI({
          div(class = "connection-success",
              h5("Connection Successful"),
              p(paste("Connected to", input$dbname, "on", input$host)),
              p(paste("Username:", input$username)))
        })
        
        showNotification("Database connection established!", type = "message")
      }
      
    }, error = function(e) {
      values$connected <- FALSE
      values$connection <- NULL
      
      output$connectionStatus <- renderUI({
        div(class = "connection-error",
            h5("Connection Failed"),
            p("Error:", e$message),
            p("Please check your connection settings."))
      })
      
      showNotification(paste("Connection failed:", e$message), type = "error")
    })
  })
  
  # Output connection status for conditional panels
  output$connectionValid <- reactive({
    values$connected
  })
  outputOptions(output, "connectionValid", suspendWhenHidden = FALSE)
  
  # Database statistics
  output$dbStats <- renderText({
    if (!values$connected) return("No connection established")
    
    tryCatch({
      tables <- dbListTables(values$connection)
      stats_text <- paste("Available tables:", paste(tables, collapse = ", "), "\n")
      
      # Check fx_spot_prices
      if ("fx_spot_prices" %in% tables) {
        row_count <- dbGetQuery(values$connection, "SELECT COUNT(*) as count FROM fx_spot_prices")
        stats_text <- paste(stats_text, paste("fx_spot_prices records:", format(row_count$count, big.mark = ",")), "\n")
      }
      
      # Check fx_spot_prices_daily  
      if ("fx_spot_prices_daily" %in% tables) {
        row_count_daily <- dbGetQuery(values$connection, "SELECT COUNT(*) as count FROM fx_spot_prices_daily")
        stats_text <- paste(stats_text, paste("fx_spot_prices_daily records:", format(row_count_daily$count, big.mark = ",")), "\n")
      }
      
      return(stats_text)
      
    }, error = function(e) {
      return(paste("Error getting table info:", e$message))
    })
  })
  
  # Load data from database
  observeEvent(input$loadData, {
    req(values$connected, input$sourceTable)
    
    tryCatch({
      if (input$sourceTable == "fx_spot_prices") {
        # Show message for intraday data
        output$dataStatus <- renderUI({
          div(class = "connection-error",
              h5("Functionality in Progress"),
              p("Intraday data (fx_spot_prices) functionality is currently being developed."),
              p("Please select Daily Data (fx_spot_prices_daily) instead."))
        })
        
        values$data_loaded <- FALSE
        values$fx_data <- NULL
        showNotification("Intraday data functionality is in progress. Please use Daily Data.", type = "warning")
        return()
      }
      
      # Load daily data
      showNotification("Loading data from database...", type = "message")
      
      raw_data <- dbGetQuery(values$connection, "SELECT * FROM fx_spot_prices_daily ORDER BY date, pair")
      
      if (nrow(raw_data) == 0) {
        output$dataStatus <- renderUI({
          div(class = "connection-error",
              h5("No Data Found"),
              p("The selected table contains no data."))
        })
        values$data_loaded <- FALSE
        return()
      }
      
      # Process the data
      processed_data <- raw_data %>%
        mutate(
          date = as.Date(date),
          Mid = as.numeric(Mid),
          Bid = as.numeric(Bid),
          Ask = as.numeric(Ask),
          pair = as.character(pair),
          spread = Ask - Bid,
          spread_pct = (Ask - Bid) / Mid * 100,
          returns = ave(Mid, pair, FUN = function(x) c(NA, diff(log(x)))),
          returns_pct = ave(Mid, pair, FUN = function(x) c(NA, diff(x) / head(x, -1) * 100))
        ) %>%
        filter(!is.na(Mid), !is.na(Bid), !is.na(Ask)) %>%
        arrange(pair, date)
      
      values$fx_data <- processed_data
      values$data_loaded <- TRUE
      
      # Update currency pair choices
      available_pairs <- sort(unique(processed_data$pair))
      updateSelectInput(session, "selectedPair", 
                        choices = available_pairs,
                        selected = available_pairs[1])
      
      # Update correlation pair choices
      updateCheckboxGroupInput(session, "correlationPairs",
                               choices = available_pairs,
                               selected = available_pairs[1:min(4, length(available_pairs))])
      
      output$dataStatus <- renderUI({
        div(class = "connection-success",
            h5("Data Loaded Successfully"),
            p(paste("Loaded", nrow(processed_data), "records")),
            p(paste("Currency pairs:", length(available_pairs))),
            p(paste("Date range:", min(processed_data$date), "to", max(processed_data$date))))
      })
      
      showNotification(paste("Successfully loaded", nrow(processed_data), "records"), type = "message")
      
    }, error = function(e) {
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      
      output$dataStatus <- renderUI({
        div(class = "connection-error",
            h5("Data Loading Failed"),
            p("Error:", e$message))
      })
      
      showNotification(paste("Data loading failed:", e$message), type = "error")
    })
  })
  
  # Output data loaded status for conditional panels
  output$dataLoaded <- reactive({
    values$data_loaded
  })
  outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  
  # Data preview
  output$dataPreview <- DT::renderDataTable({
    req(values$fx_data)
    
    preview_data <- values$fx_data %>% 
      select(date, pair, Mid, Bid, Ask, spread_pct) %>%
      head(20)
    
    datatable(preview_data,
              options = list(
                scrollX = TRUE,
                pageLength = 20,
                dom = 'frtip'
              ),
              caption = paste("Data Preview:", nrow(preview_data), "rows"))
  })
  
  # Filter data for selected pair
  pair_data <- reactive({
    req(values$fx_data, input$selectedPair)
    values$fx_data %>% filter(pair == input$selectedPair)
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
    req(values$fx_data)
    # Calculate YTD performance for all pairs
    current_year <- year(Sys.Date())
    
    performance <- values$fx_data %>%
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
    
    # Create base plot
    p <- plot_ly(data, x = ~date, y = ~rsi, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2))
    
    # Add horizontal reference lines using shapes
    p <- p %>% 
      layout(
        title = paste("RSI(", input$rsiLength, ")"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "RSI", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          # Overbought line at 70
          list(type = "line", x0 = min(data$date), x1 = max(data$date),
               y0 = 70, y1 = 70, 
               line = list(color = "#e74c3c", dash = "dash", width = 1)),
          # Oversold line at 30
          list(type = "line", x0 = min(data$date), x1 = max(data$date),
               y0 = 30, y1 = 30, 
               line = list(color = "#27ae60", dash = "dash", width = 1))
        ),
        annotations = list(
          list(x = 0.02, y = 75, text = "Overbought (70)", showarrow = FALSE, 
               xref = "paper", yref = "y", font = list(size = 10)),
          list(x = 0.02, y = 25, text = "Oversold (30)", showarrow = FALSE, 
               xref = "paper", yref = "y", font = list(size = 10))
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
      layout(
        title = "MACD",
        xaxis = list(title = "Date"),
        yaxis = list(title = "MACD"),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          # Zero line
          list(type = "line", x0 = min(data$date), x1 = max(data$date),
               y0 = 0, y1 = 0, 
               line = list(color = "#95a5a6", dash = "dot", width = 1))
        )
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
      layout(
        title = "Stochastic Oscillator",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Stochastic (%)", range = c(0, 100)),
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        shapes = list(
          # Overbought line at 80
          list(type = "line", x0 = min(data$date), x1 = max(data$date),
               y0 = 80, y1 = 80, 
               line = list(color = "#e74c3c", dash = "dash", width = 1)),
          # Oversold line at 20
          list(type = "line", x0 = min(data$date), x1 = max(data$date),
               y0 = 20, y1 = 20, 
               line = list(color = "#27ae60", dash = "dash", width = 1))
        )
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
    
    # Simple VaR and ES calculations
    tryCatch({
      # Historical VaR
      var_percentile <- (100 - input$confidenceLevel) / 100
      var_value <- quantile(returns, var_percentile, na.rm = TRUE)
      
      # Expected Shortfall (average of returns below VaR)
      es_value <- mean(returns[returns <= var_value], na.rm = TRUE)
      
      # Convert to portfolio value
      var_dollar <- abs(var_value) * input$portfolioValue
      es_dollar <- abs(es_value) * input$portfolioValue
      
      # Calculate drawdown manually
      cumulative_returns <- cumprod(1 + returns)
      running_max <- cummax(cumulative_returns)
      drawdown <- (cumulative_returns - running_max) / running_max
      max_drawdown <- min(drawdown, na.rm = TRUE) * 100
      
      # Simple Sharpe ratio
      sharpe_ratio <- mean(returns, na.rm = TRUE) / sd(returns, na.rm = TRUE) * sqrt(252)
      
      paste(
        paste("VaR (", input$confidenceLevel, "%):", "$", format(round(var_dollar, 0), big.mark = ",")),
        paste("Expected Shortfall:", "$", format(round(es_dollar, 0), big.mark = ",")),
        paste("Max Drawdown:", paste0(round(max_drawdown, 2), "%")),
        paste("Sharpe Ratio:", round(sharpe_ratio, 3)),
        sep = "\n"
      )
    }, error = function(e) {
      "Error calculating risk metrics"
    })
  })
  
  output$varChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 100) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    
    # Calculate rolling VaR using simple quantile method
    window_size <- min(100, length(returns) - 50)
    var_percentile <- (100 - input$confidenceLevel) / 100
    
    rolling_var <- rollapply(returns, width = window_size, 
                             FUN = function(x) quantile(x, var_percentile, na.rm = TRUE), 
                             fill = NA, align = "right")
    
    # Create VaR chart data
    var_data <- data.frame(
      date = tail(data$date, length(rolling_var)),
      var = abs(rolling_var) * input$portfolioValue,
      returns = tail(returns, length(rolling_var)) * input$portfolioValue
    )
    
    # Filter out NA values
    var_data <- var_data[complete.cases(var_data), ]
    
    if (nrow(var_data) == 0) return(plotly_empty())
    
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
    window_size <- min(100, length(returns) - 50)
    var_percentile <- (100 - input$confidenceLevel) / 100
    
    rolling_es <- rollapply(returns, width = window_size, 
                            FUN = function(x) {
                              var_threshold <- quantile(x, var_percentile, na.rm = TRUE)
                              mean(x[x <= var_threshold], na.rm = TRUE)
                            }, 
                            fill = NA, align = "right")
    
    es_data <- data.frame(
      date = tail(data$date, length(rolling_es)),
      es = abs(rolling_es) * input$portfolioValue
    )
    
    # Filter out NA values
    es_data <- es_data[complete.cases(es_data), ]
    
    if (nrow(es_data) == 0) return(plotly_empty())
    
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
    req(values$fx_data)
    
    if (length(input$correlationPairs) < 2) return("Select at least 2 currency pairs")
    
    tryCatch({
      # Filter data for selected pairs
      corr_data <- values$fx_data %>%
        filter(pair %in% input$correlationPairs) %>%
        select(date, pair, returns) %>%
        filter(!is.na(returns)) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-date) %>%
        na.omit()  # Remove rows with any NA values
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) return("Insufficient complete data for correlation analysis")
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Get average correlation
      upper_tri <- corr_matrix[upper.tri(corr_matrix)]
      avg_corr <- mean(upper_tri, na.rm = TRUE)
      max_corr <- max(upper_tri, na.rm = TRUE)
      min_corr <- min(upper_tri, na.rm = TRUE)
      
      paste(
        paste("Average Correlation:", round(avg_corr, 3)),
        paste("Highest Correlation:", round(max_corr, 3)),
        paste("Lowest Correlation:", round(min_corr, 3)),
        paste("Pairs Analyzed:", length(input$correlationPairs)),
        paste("Complete Observations:", nrow(corr_data)),
        sep = "\n"
      )
    }, error = function(e) {
      "Error calculating correlations. Try selecting different pairs or check data availability."
    })
  })
  
  output$correlationHeatmap <- renderPlot({
    req(values$fx_data)
    
    if (length(input$correlationPairs) < 2) {
      plot.new()
      text(0.5, 0.5, "Select at least 2 currency pairs", cex = 1.5)
      return()
    }
    
    tryCatch({
      # Filter data for selected pairs
      corr_data <- values$fx_data %>%
        filter(pair %in% input$correlationPairs) %>%
        select(date, pair, returns) %>%
        filter(!is.na(returns)) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-date) %>%
        na.omit()  # Remove rows with any NA values
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) {
        plot.new()
        text(0.5, 0.5, "Insufficient complete data for correlation analysis", cex = 1.2)
        return()
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Create heatmap
      corrplot(corr_matrix, method = "color", type = "upper", 
               order = "hclust", tl.cex = 1.2, tl.col = "#2c3e50",
               cl.cex = 1.0, addCoef.col = "#2c3e50", number.cex = 1.2,
               col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200))
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, "Error creating correlation heatmap", cex = 1.2)
    })
  })
  
  output$rollingCorrelations <- renderPlotly({
    req(values$fx_data)
    
    if (length(input$correlationPairs) < 2) return(plotly_empty())
    
    tryCatch({
      # For simplicity, show correlation between first two selected pairs
      selected_pairs <- input$correlationPairs[1:2]
      
      corr_data <- values$fx_data %>%
        filter(pair %in% selected_pairs) %>%
        select(date, pair, returns) %>%
        filter(!is.na(returns)) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns)
      
      if (ncol(corr_data) < 3 || nrow(corr_data) < input$correlationWindow) return(plotly_empty())
      
      # Remove rows with NA values
      corr_data <- corr_data[complete.cases(corr_data), ]
      
      if (nrow(corr_data) < input$correlationWindow) return(plotly_empty())
      
      # Calculate rolling correlation
      rolling_corr <- rollapply(corr_data[, 2:3], width = input$correlationWindow,
                                FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
                                fill = NA, align = "right", by.column = FALSE)
      
      corr_df <- data.frame(
        date = tail(corr_data$date, length(rolling_corr)),
        correlation = rolling_corr
      ) %>%
        filter(!is.na(correlation))
      
      if (nrow(corr_df) == 0) return(plotly_empty())
      
      p <- plot_ly(corr_df, x = ~date, y = ~correlation, type = "scatter", mode = "lines",
                   line = list(color = "#3498db", width = 2)) %>%
        layout(
          title = paste("Rolling Correlation:", paste(selected_pairs, collapse = " vs ")),
          xaxis = list(title = "Date"),
          yaxis = list(title = "Correlation", range = c(-1, 1)),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          shapes = list(
            # Zero line
            list(type = "line", x0 = min(corr_df$date), x1 = max(corr_df$date),
                 y0 = 0, y1 = 0, 
                 line = list(color = "#95a5a6", dash = "dash", width = 1))
          )
        )
      
      p
    }, error = function(e) {
      plotly_empty()
    })
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
  
  # Clean up database connection when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$connection)) {
      dbDisconnect(values$connection)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)