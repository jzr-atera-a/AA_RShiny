# Advanced FX Spot Prices Analysis Dashboard with MySQL Integration
# Comprehensive analysis of G10 currency pairs with MySQL database connection
# Enhanced to handle both daily and intraday data

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

# Helper Functions for Time-Aware Calculations
get_trading_periods_per_year <- function(data_frequency) {
  switch(data_frequency,
         "daily" = 252,
         "hourly" = 252 * 24,
         "minute" = 252 * 24 * 60,
         "raw" = 252 * 24 * 60,  # Conservative estimate for intraday
         252  # Default to daily
  )
}

detect_data_frequency <- function(data) {
  if (nrow(data) < 2) return("unknown")
  
  # Calculate time differences
  time_diffs <- as.numeric(diff(data$datetime))
  median_diff <- median(time_diffs, na.rm = TRUE)
  
  # Classify based on median time difference (in minutes)
  if (median_diff >= 1440 - 120) {  # Around 1 day (with 2-hour tolerance)
    return("daily")
  } else if (median_diff >= 60 - 10 && median_diff <= 60 + 10) {  # Around 1 hour
    return("hourly")
  } else if (median_diff >= 1 && median_diff <= 60) {
    return("minute")
  } else {
    return("raw")
  }
}

aggregate_intraday_data <- function(data, aggregation_level = "day") {
  if (aggregation_level == "raw") return(data)
  
  grouping_vars <- switch(aggregation_level,
                          "day" = list(date = as.Date(data$datetime), pair = data$pair),
                          "hour" = list(
                            datetime = floor_date(data$datetime, "hour"),
                            pair = data$pair
                          )
  )
  
  aggregated <- data %>%
    group_by(!!!grouping_vars) %>%
    summarise(
      datetime = if (aggregation_level == "day") as.POSIXct(first(date)) else first(datetime),
      date = if (aggregation_level == "day") first(date) else as.Date(first(datetime)),
      Mid = mean(Mid, na.rm = TRUE),
      Bid = mean(Bid, na.rm = TRUE),
      Ask = mean(Ask, na.rm = TRUE),
      High = max(Mid, na.rm = TRUE),
      Low = min(Mid, na.rm = TRUE),
      Open = first(Mid),
      Close = last(Mid),
      Volume = n(),  # Number of observations
      .groups = 'drop'
    ) %>%
    mutate(
      spread = Ask - Bid,
      spread_pct = (Ask - Bid) / Mid * 100
    ) %>%
    arrange(pair, datetime)
  
  return(aggregated)
}

calculate_adaptive_returns <- function(data, frequency) {
  periods_per_year <- get_trading_periods_per_year(frequency)
  
  data %>%
    group_by(pair) %>%
    arrange(datetime) %>%
    mutate(
      returns = c(NA, diff(log(Mid))),
      returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100),
      vol_annualized = rollapply(returns, width = min(30, n()-1), 
                                 FUN = function(x) sd(x, na.rm = TRUE) * sqrt(periods_per_year) * 100,
                                 fill = NA, align = "right", partial = TRUE)
    ) %>%
    ungroup()
}

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Enhanced FX Analysis Dashboard"),
  
  dashboardSidebar(
    # Global currency pair selector
    div(style = "padding: 10px; background-color: #2c3e50; margin-bottom: 10px;",
        conditionalPanel(
          condition = "output.dataLoaded == true",
          selectInput("selectedPair", 
                      "Select Currency Pair:",
                      choices = NULL,
                      selected = NULL,
                      width = "100%"),
          
          # Time aggregation selector for intraday data
          conditionalPanel(
            condition = "output.isIntradayData == true",
            selectInput("timeAggregation",
                        "Time Aggregation:",
                        choices = list(
                          "Raw (as-is)" = "raw",
                          "Hourly" = "hour", 
                          "Daily" = "day"
                        ),
                        selected = "day",
                        width = "100%")
          )
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
        .data-info {
          background-color: #d1ecf1;
          color: #0c5460;
          padding: 10px;
          border-radius: 8px;
          border: 1px solid #bee5eb;
          margin: 10px 0;
          font-size: 12px;
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
                    
                    uiOutput("dataInfo"),
                    br(),
                    h5("Sample Data from Selected Table:"),
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
                    title = "Enhanced FX Spot Market Overview", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    height = 200,
                    div(style = "padding: 20px; background: linear-gradient(135deg, #2980b9, #3498db); color: white; border-radius: 8px; margin: 10px;",
                        h4("Enhanced G10 Currency Pairs Analysis Dashboard", style = "color: white; margin-bottom: 15px;"),
                        p("Comprehensive analysis with adaptive time-frequency calculations for both daily and intraday data.", 
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
                                   end = Sys.Date()),
                    br(),
                    checkboxGroupInput("priceComponents", "Show Components:",
                                       choices = c("Mid Price" = "mid", 
                                                   "Bid Price" = "bid", 
                                                   "Ask Price" = "ask",
                                                   "Bid-Ask Spread" = "spread"),
                                       selected = c("mid", "spread")),
                    br(),
                    uiOutput("movingAvgControl"),
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
                                                   "Bollinger Bands" = "bb"),
                                       selected = c("sma", "rsi", "macd")),
                    br(),
                    uiOutput("technicalControls"),
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
                    title = "Bollinger Bands", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    withSpinner(plotlyOutput("bollingerChart", height = "250px"))
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
                    uiOutput("volatilityControls"),
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
                    sliderInput("confidenceLevel", "VaR Confidence Level:",
                                min = 90, max = 99, value = 95, step = 1),
                    uiOutput("riskControls"),
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
                    uiOutput("correlationControls"),
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
    processed_data = NULL,
    data_loaded = FALSE,
    is_intraday = FALSE,
    data_frequency = "daily"
  )
  
  # Database connection handlers (same as original)
  observeEvent(input$closeConnections, {
    tryCatch({
      if (!is.null(values$connection)) {
        dbDisconnect(values$connection)
        values$connection <- NULL
      }
      
      all_connections <- dbListConnections(RMySQL::MySQL())
      for (con in all_connections) {
        dbDisconnect(con)
      }
      
      values$connected <- FALSE
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      values$processed_data <- NULL
      
      output$connectionStatus <- renderUI({
        div(class = "connection-success",
            h5("Connections Closed"),
            p("All database connections have been closed successfully."))
      })
      
    }, error = function(e) {
      showNotification(paste("Error closing connections:", e$message), type = "error")
    })
  })
  
  observeEvent(input$testConnection, {
    if (input$password == "") {
      output$connectionStatus <- renderUI({
        div(class = "connection-error",
            h5("Connection Failed"),
            p("Password is required."))
      })
      return()
    }
    
    tryCatch({
      if (!is.null(values$connection)) {
        dbDisconnect(values$connection)
      }
      
      values$connection <- dbConnect(
        RMySQL::MySQL(),
        host = as.character(input$host),
        port = as.numeric(input$port),
        dbname = as.character(input$dbname),
        username = as.character(input$username),
        password = as.character(input$password)
      )
      
      test_query <- dbGetQuery(values$connection, "SELECT 1 as test")
      
      if (nrow(test_query) == 1) {
        values$connected <- TRUE
        
        output$connectionStatus <- renderUI({
          div(class = "connection-success",
              h5("Connection Successful"),
              p(paste("Connected to", input$dbname, "on", input$host)))
        })
      }
      
    }, error = function(e) {
      values$connected <- FALSE
      values$connection <- NULL
      
      output$connectionStatus <- renderUI({
        div(class = "connection-error",
            h5("Connection Failed"),
            p("Error:", e$message))
      })
    })
  })
  
  # Enhanced data loading with dual-table support
  observeEvent(input$loadData, {
    req(values$connected, input$sourceTable)
    
    tryCatch({
      showNotification("Loading data from database...", type = "message")
      
      # Load data based on selected table
      if (input$sourceTable == "fx_spot_prices_daily") {
        raw_data <- dbGetQuery(values$connection, 
                               "SELECT * FROM fx_spot_prices_daily ORDER BY date, pair")
        
        if (nrow(raw_data) == 0) {
          output$dataStatus <- renderUI({
            div(class = "connection-error",
                h5("No Data Found"),
                p("The selected table contains no data."))
          })
          return()
        }
        
        # Process daily data
        processed_data <- raw_data %>%
          mutate(
            date = as.Date(date),
            datetime = as.POSIXct(date),
            Mid = as.numeric(Mid),
            Bid = as.numeric(Bid),
            Ask = as.numeric(Ask),
            pair = as.character(pair),
            spread = Ask - Bid,
            spread_pct = (Ask - Bid) / Mid * 100
          ) %>%
          filter(!is.na(Mid), !is.na(Bid), !is.na(Ask)) %>%
          arrange(pair, datetime)
        
        values$is_intraday <- FALSE
        values$data_frequency <- "daily"
        
      } else {
        # Load intraday data
        raw_data <- dbGetQuery(values$connection, 
                               "SELECT * FROM fx_spot_prices ORDER BY timestamp, pair LIMIT 100000")
        
        if (nrow(raw_data) == 0) {
          output$dataStatus <- renderUI({
            div(class = "connection-error",
                h5("No Data Found"),
                p("The selected table contains no data."))
          })
          return()
        }
        
        # Process intraday data
        processed_data <- raw_data %>%
          mutate(
            datetime = as.POSIXct(timestamp),
            date = as.Date(datetime),
            Mid = as.numeric(Mid),
            Bid = as.numeric(Bid),
            Ask = as.numeric(Ask),
            pair = as.character(pair),
            spread = Ask - Bid,
            spread_pct = (Ask - Bid) / Mid * 100
          ) %>%
          filter(!is.na(Mid), !is.na(Bid), !is.na(Ask)) %>%
          arrange(pair, datetime)
        
        values$is_intraday <- TRUE
        values$data_frequency <- detect_data_frequency(processed_data)
      }
      
      # Calculate returns with appropriate frequency adjustment
      processed_data <- calculate_adaptive_returns(processed_data, values$data_frequency)
      
      values$fx_data <- processed_data
      values$processed_data <- processed_data
      values$data_loaded <- TRUE
      
      # Update currency pair choices
      available_pairs <- sort(unique(processed_data$pair))
      updateSelectInput(session, "selectedPair", 
                        choices = available_pairs,
                        selected = available_pairs[1])
      
      updateCheckboxGroupInput(session, "correlationPairs",
                               choices = available_pairs,
                               selected = available_pairs[1:min(4, length(available_pairs))])
      
      output$dataStatus <- renderUI({
        div(class = "connection-success",
            h5("Data Loaded Successfully"),
            p(paste("Loaded", format(nrow(processed_data), big.mark = ","), "records")),
            p(paste("Currency pairs:", length(available_pairs))),
            p(paste("Frequency detected:", values$data_frequency)),
            p(paste("Date range:", min(processed_data$date), "to", max(processed_data$date))))
      })
      
    }, error = function(e) {
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      values$processed_data <- NULL
      
      output$dataStatus <- renderUI({
        div(class = "connection-error",
            h5("Data Loading Failed"),
            p("Error:", e$message))
      })
    })
  })
  
  # Reactive data processing based on aggregation selection
  aggregated_data <- reactive({
    req(values$fx_data)
    
    if (values$is_intraday && !is.null(input$timeAggregation)) {
      aggregate_intraday_data(values$fx_data, input$timeAggregation)
    } else {
      values$fx_data
    }
  })
  
  # Filter data for selected pair
  pair_data <- reactive({
    req(aggregated_data(), input$selectedPair)
    aggregated_data() %>% filter(pair == input$selectedPair)
  })
  
  # Output reactive values for conditional panels
  output$connectionValid <- reactive({ values$connected })
  outputOptions(output, "connectionValid", suspendWhenHidden = FALSE)
  
  output$dataLoaded <- reactive({ values$data_loaded })
  outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  
  output$isIntradayData <- reactive({ values$is_intraday })
  outputOptions(output, "isIntradayData", suspendWhenHidden = FALSE)
  
  # Database statistics
  output$dbStats <- renderText({
    if (!values$connected) return("No connection established")
    
    tryCatch({
      tables <- dbListTables(values$connection)
      stats_text <- paste("Available tables:", paste(tables, collapse = ", "), "\n")
      
      if ("fx_spot_prices" %in% tables) {
        row_count <- dbGetQuery(values$connection, "SELECT COUNT(*) as count FROM fx_spot_prices")
        stats_text <- paste(stats_text, paste("fx_spot_prices records:", format(row_count$count, big.mark = ",")), "\n")
      }
      
      if ("fx_spot_prices_daily" %in% tables) {
        row_count_daily <- dbGetQuery(values$connection, "SELECT COUNT(*) as count FROM fx_spot_prices_daily")
        stats_text <- paste(stats_text, paste("fx_spot_prices_daily records:", format(row_count_daily$count, big.mark = ",")), "\n")
      }
      
      return(stats_text)
      
    }, error = function(e) {
      return(paste("Error getting table info:", e$message))
    })
  })
  
  # Data info display
  output$dataInfo <- renderUI({
    req(values$fx_data)
    
    current_freq <- if (values$is_intraday && !is.null(input$timeAggregation)) {
      paste("Aggregated to:", input$timeAggregation)
    } else {
      paste("Native frequency:", values$data_frequency)
    }
    
    div(class = "data-info",
        p(paste("Data Source:", input$sourceTable)),
        p(paste("Records:", format(nrow(aggregated_data()), big.mark = ","))),
        p(current_freq))
  })
  
  # Data preview
  output$dataPreview <- DT::renderDataTable({
    req(aggregated_data())
    
    preview_data <- aggregated_data() %>% 
      select(datetime, date, pair, Mid, Bid, Ask, spread_pct) %>%
      head(20)
    
    datatable(preview_data,
              options = list(scrollX = TRUE, pageLength = 20, dom = 'frtip'))
  })
  
  # Dynamic UI controls based on data frequency
  output$movingAvgControl <- renderUI({
    req(values$data_loaded)
    
    # Adjust default values based on frequency
    default_periods <- switch(values$data_frequency,
                              "daily" = 20,
                              "hourly" = 24 * 5,  # 5 days worth
                              "minute" = 60 * 4,  # 4 hours worth
                              20
    )
    
    label_suffix <- switch(values$data_frequency,
                           "daily" = "days",
                           "hourly" = "hours", 
                           "minute" = "minutes",
                           "periods"
    )
    
    numericInput("movingAvgPeriods", 
                 paste("Moving Average (", label_suffix, "):"),
                 value = default_periods, 
                 min = 5, 
                 max = default_periods * 10, 
                 step = if(values$data_frequency == "daily") 5 else default_periods/4)
  })
  
  output$technicalControls <- renderUI({
    req(values$data_loaded)
    
    # Adjust technical indicator periods based on frequency
    base_multiplier <- switch(values$data_frequency,
                              "daily" = 1,
                              "hourly" = 24,
                              "minute" = 60,
                              1
    )
    
    tagList(
      numericInput("smaLength", "SMA Length:", 
                   value = 20 * base_multiplier, 
                   min = 5 * base_multiplier, 
                   max = 200 * base_multiplier),
      numericInput("emaLength", "EMA Length:", 
                   value = 20 * base_multiplier, 
                   min = 5 * base_multiplier, 
                   max = 200 * base_multiplier),
      numericInput("rsiLength", "RSI Length:", 
                   value = 14 * base_multiplier, 
                   min = 5 * base_multiplier, 
                   max = 50 * base_multiplier)
    )
  })
  
  output$volatilityControls <- renderUI({
    req(values$data_loaded)
    
    # Adjust volatility window based on frequency
    default_window <- switch(values$data_frequency,
                             "daily" = 30,
                             "hourly" = 24 * 30,  # 30 days worth
                             "minute" = 60 * 24,  # 1 day worth
                             30
    )
    
    tagList(
      radioButtons("volatilityType", "Volatility Type:",
                   choices = c("Realized Volatility" = "realized",
                               "Parkinson Estimator" = "parkinson"),
                   selected = "realized"),
      numericInput("volWindow", paste("Rolling Window (", values$data_frequency, "):"),
                   value = default_window, 
                   min = 10, 
                   max = default_window * 10)
    )
  })
  
  output$riskControls <- renderUI({
    req(values$data_loaded)
    
    # Adjust time horizon based on frequency
    max_horizon <- switch(values$data_frequency,
                          "daily" = 30,
                          "hourly" = 24 * 7,  # 1 week max
                          "minute" = 60 * 24,  # 1 day max
                          30
    )
    
    tagList(
      numericInput("timeHorizon", paste("Time Horizon (", values$data_frequency, "):"),
                   value = ifelse(values$data_frequency == "daily", 1, 
                                  ifelse(values$data_frequency == "hourly", 24, 60)),
                   min = 1, max = max_horizon),
      radioButtons("varMethod", "VaR Method:",
                   choices = c("Historical Simulation" = "historical",
                               "Parametric" = "gaussian"),
                   selected = "historical")
    )
  })
  
  output$correlationControls <- renderUI({
    req(values$data_loaded)
    
    # Adjust correlation window based on frequency
    default_window <- switch(values$data_frequency,
                             "daily" = 252,
                             "hourly" = 252 * 24,
                             "minute" = 252 * 24,
                             252
    )
    
    tagList(
      radioButtons("correlationType", "Correlation Type:",
                   choices = c("Pearson" = "pearson",
                               "Spearman" = "spearman"),
                   selected = "pearson"),
      numericInput("correlationWindow", paste("Rolling Window (", values$data_frequency, "):"),
                   value = default_window, 
                   min = 30, 
                   max = default_window * 2),
      radioButtons("returnType", "Return Type:",
                   choices = c("Log Returns" = "log"),
                   selected = "log")
    )
  })
  
  # Market Overview Tab Outputs - Enhanced for dual frequency
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
    data <- pair_data()
    
    if (values$data_frequency == "daily") {
      recent_data <- data %>% slice_tail(n = 2)
      if (nrow(recent_data) >= 2) {
        change <- (recent_data$Mid[2] - recent_data$Mid[1]) / recent_data$Mid[1] * 100
      } else {
        change <- 0
      }
    } else {
      # For intraday data, calculate change from previous day's last value
      today_start <- floor_date(max(data$datetime), "day")
      yesterday_data <- data %>% filter(date < as.Date(today_start))
      today_data <- data %>% filter(date >= as.Date(today_start))
      
      if (nrow(yesterday_data) > 0 && nrow(today_data) > 0) {
        last_yesterday <- tail(yesterday_data$Mid, 1)
        last_today <- tail(today_data$Mid, 1)
        change <- (last_today - last_yesterday) / last_yesterday * 100
      } else {
        change <- 0
      }
    }
    
    color <- ifelse(change > 0, "green", "red")
    icon_name <- ifelse(change > 0, "arrow-up", "arrow-down")
    
    valueBox(
      value = paste0(ifelse(change > 0, "+", ""), round(change, 3), "%"),
      subtitle = "Daily Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  output$volatility30d <- renderValueBox({
    req(pair_data())
    
    # Adaptive window size based on frequency
    window_size <- switch(values$data_frequency,
                          "daily" = 30,
                          "hourly" = 30 * 24,
                          "minute" = 30 * 24 * 60,
                          30
    )
    
    recent_data <- pair_data() %>% slice_tail(n = window_size)
    
    if (nrow(recent_data) > 1) {
      periods_per_year <- get_trading_periods_per_year(values$data_frequency)
      vol <- sd(recent_data$returns, na.rm = TRUE) * sqrt(periods_per_year) * 100
    } else {
      vol <- 0
    }
    
    valueBox(
      value = paste0(round(vol, 2), "%"),
      subtitle = "30-Period Volatility (Ann.)",
      icon = icon("wave-square"),
      color = "yellow"
    )
  })
  
  output$dataRange <- renderValueBox({
    req(pair_data())
    data_range <- pair_data() %>%
      summarise(
        start = min(datetime, na.rm = TRUE),
        end = max(datetime, na.rm = TRUE),
        duration = as.numeric(end - start, units = "days")
      )
    
    valueBox(
      value = paste(round(data_range$duration / 365, 1), "yrs"),
      subtitle = "Data Coverage",
      icon = icon("calendar"),
      color = "purple"
    )
  })
  
  # Enhanced overview chart with frequency-aware moving averages
  output$overviewChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 1000)
    
    # Calculate frequency-appropriate moving averages
    ma_short <- switch(values$data_frequency,
                       "daily" = 20,
                       "hourly" = 24 * 5,
                       "minute" = 60 * 4,
                       20
    )
    
    ma_long <- switch(values$data_frequency,
                      "daily" = 50,
                      "hourly" = 24 * 10,
                      "minute" = 60 * 8,
                      50
    )
    
    data$ma_short <- SMA(data$Mid, n = ma_short)
    data$ma_long <- SMA(data$Mid, n = ma_long)
    
    p <- plot_ly(data, x = ~datetime) %>%
      add_lines(y = ~Mid, name = "Mid Price", line = list(color = "#2c3e50", width = 2)) %>%
      add_lines(y = ~ma_short, name = paste0("MA(", ma_short, ")"), 
                line = list(color = "#e74c3c", width = 1, dash = "dash")) %>%
      add_lines(y = ~ma_long, name = paste0("MA(", ma_long, ")"), 
                line = list(color = "#3498db", width = 1, dash = "dot")) %>%
      layout(
        title = paste(input$selectedPair, "Price Chart with Moving Averages"),
        xaxis = list(title = "Time"),
        yaxis = list(title = "Exchange Rate"),
        hovermode = "x unified"
      )
    
    p
  })
  
  # Enhanced market statistics
  output$marketStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    periods_per_year <- get_trading_periods_per_year(values$data_frequency)
    
    stats <- data %>%
      summarise(
        Current_Price = round(tail(Mid, 1), 5),
        Min_Price = round(min(Mid, na.rm = TRUE), 5),
        Max_Price = round(max(Mid, na.rm = TRUE), 5),
        Avg_Price = round(mean(Mid, na.rm = TRUE), 5),
        Volatility_Ann = round(sd(returns, na.rm = TRUE) * sqrt(periods_per_year) * 100, 2),
        Avg_Spread_bps = round(mean(spread_pct, na.rm = TRUE) * 100, 1),
        Observations = format(n(), big.mark = ","),
        Frequency = values$data_frequency
      ) %>%
      tidyr::pivot_longer(everything(), names_to = "Metric", values_to = "Value")
    
    datatable(stats, options = list(dom = 't', pageLength = 15), rownames = FALSE)
  })
  
  # Enhanced performance comparison with frequency-aware calculations
  output$performanceComparison <- renderPlotly({
    req(aggregated_data())
    
    # For intraday data, aggregate to daily for fair comparison
    comparison_data <- if (values$data_frequency != "daily") {
      aggregated_data() %>%
        group_by(pair, date = as.Date(datetime)) %>%
        summarise(
          Mid = last(Mid),
          .groups = 'drop'
        )
    } else {
      aggregated_data() %>% select(pair, date, Mid)
    }
    
    current_year <- year(Sys.Date())
    
    performance <- comparison_data %>%
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
        yaxis = list(title = "YTD Return (%)")
      )
    
    p
  })
  
  # Price Analysis Tab - Enhanced with frequency awareness
  output$priceStats <- renderText({
    req(pair_data(), input$movingAvgPeriods)
    data <- pair_data() %>%
      filter(datetime >= as.POSIXct(input$priceRange[1]) & 
               datetime <= as.POSIXct(input$priceRange[2]))
    
    if (nrow(data) == 0) return("No data available for selected range")
    
    periods_per_year <- get_trading_periods_per_year(values$data_frequency)
    
    stats <- paste(
      paste("Observations:", format(nrow(data), big.mark = ",")),
      paste("Current Price:", round(tail(data$Mid, 1), 5)),
      paste("Period High:", round(max(data$Mid, na.rm = TRUE), 5)),
      paste("Period Low:", round(min(data$Mid, na.rm = TRUE), 5)),
      paste("Average:", round(mean(data$Mid, na.rm = TRUE), 5)),
      paste("Volatility (Ann.):", paste0(round(sd(data$returns, na.rm = TRUE) * sqrt(periods_per_year) * 100, 2), "%")),
      paste("Data Frequency:", values$data_frequency),
      sep = "\n"
    )
    
    stats
  })
  
  output$detailedPriceChart <- renderPlotly({
    req(pair_data(), input$movingAvgPeriods)
    data <- pair_data() %>%
      filter(datetime >= as.POSIXct(input$priceRange[1]) & 
               datetime <= as.POSIXct(input$priceRange[2]))
    
    if (nrow(data) == 0) return(plotly_empty())
    
    # Calculate moving average with user-defined period
    data$ma <- SMA(data$Mid, n = input$movingAvgPeriods)
    
    p <- plot_ly(data, x = ~datetime)
    
    # Add selected price components
    if ("mid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Mid, name = "Mid Price", 
                           line = list(color = "#2c3e50", width = 2))
    }
    if ("bid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Bid, name = "Bid Price", 
                           line = list(color = "#27ae60", width = 1))
    }
    if ("ask" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Ask, name = "Ask Price", 
                           line = list(color = "#e74c3c", width = 1))
    }
    
    # Add moving average
    p <- p %>% add_lines(y = ~ma, name = paste("MA(", input$movingAvgPeriods, ")"), 
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
      xaxis = list(title = "Time"),
      yaxis = list(title = "Exchange Rate"),
      hovermode = "x unified"
    )
    
    p
  })
  
  output$spreadAnalysis <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>%
      filter(datetime >= as.POSIXct(input$priceRange[1]) & 
               datetime <= as.POSIXct(input$priceRange[2])) %>%
      slice_tail(n = 2000)  # Performance limit
    
    if (nrow(data) == 0) return(plotly_empty())
    
    p <- plot_ly(data, x = ~datetime, y = ~spread_pct, type = "scatter", mode = "lines",
                 line = list(color = "#f39c12", width = 1)) %>%
      layout(
        title = "Bid-Ask Spread Analysis",
        xaxis = list(title = "Time"),
        yaxis = list(title = "Spread (%)")
      )
    
    p
  })
  
  output$priceDistribution <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>%
      filter(datetime >= as.POSIXct(input$priceRange[1]) & 
               datetime <= as.POSIXct(input$priceRange[2]))
    
    if (nrow(data) == 0) return(plotly_empty())
    
    p <- plot_ly(data, x = ~Mid, type = "histogram", nbinsx = 50,
                 marker = list(color = "#3498db", opacity = 0.7)) %>%
      layout(
        title = "Price Distribution",
        xaxis = list(title = "Exchange Rate"),
        yaxis = list(title = "Frequency")
      )
    
    p
  })
  
  # Technical Analysis Tab - Enhanced with frequency-adaptive indicators
  output$technicalSignals <- renderText({
    req(pair_data(), input$rsiLength, input$smaLength)
    data <- pair_data() %>% slice_tail(n = max(200, input$smaLength * 2))
    
    if (nrow(data) < max(input$rsiLength, input$smaLength)) {
      return("Insufficient data for technical analysis")
    }
    
    # Calculate indicators with frequency-adjusted parameters
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
    req(pair_data(), input$smaLength, input$emaLength)
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < max(input$smaLength, input$emaLength)) return(plotly_empty())
    
    # Calculate indicators with user-defined parameters
    if ("sma" %in% input$technicalIndicators) {
      data$sma <- SMA(data$Mid, n = input$smaLength)
    }
    if ("ema" %in% input$technicalIndicators) {
      data$ema <- EMA(data$Mid, n = input$emaLength)
    }
    if ("bb" %in% input$technicalIndicators) {
      bb_period <- max(20, floor(input$smaLength * 0.8))
      bb <- BBands(data$Mid, n = bb_period)
      data$bb_upper <- bb[, "up"]
      data$bb_lower <- bb[, "dn"]
      data$bb_mavg <- bb[, "mavg"]
    }
    
    # Main price chart
    p <- plot_ly(data, x = ~datetime, y = ~Mid, type = "scatter", mode = "lines",
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
        add_lines(y = ~bb_upper, name = "BB Upper", 
                  line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = ~bb_lower, name = "BB Lower", 
                  line = list(color = "#95a5a6", dash = "dash")) %>%
        add_lines(y = ~bb_mavg, name = "BB Middle", 
                  line = list(color = "#f39c12", width = 1))
    }
    
    p <- p %>% layout(
      title = paste("Technical Analysis -", input$selectedPair),
      xaxis = list(title = "Time"),
      yaxis = list(title = "Exchange Rate"),
      hovermode = "x unified"
    )
    
    p
  })
  
  # Individual technical indicator charts
  output$rsiChart <- renderPlotly({
    req(pair_data(), input$rsiLength)
    data <- pair_data() %>% slice_tail(n = max(500, input$rsiLength * 3))
    
    if (nrow(data) < input$rsiLength) return(plotly_empty())
    
    data$rsi <- RSI(data$Mid, n = input$rsiLength)
    
    p <- plot_ly(data, x = ~datetime, y = ~rsi, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = paste("RSI(", input$rsiLength, ")"),
        xaxis = list(title = "Time"),
        yaxis = list(title = "RSI", range = c(0, 100)),
        shapes = list(
          list(type = "line", x0 = min(data$datetime), x1 = max(data$datetime),
               y0 = 70, y1 = 70, line = list(color = "#e74c3c", dash = "dash")),
          list(type = "line", x0 = min(data$datetime), x1 = max(data$datetime),
               y0 = 30, y1 = 30, line = list(color = "#27ae60", dash = "dash"))
        )
      )
    
    p
  })
  
  output$macdChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 50) return(plotly_empty())
    
    # Adjust MACD parameters based on frequency
    fast <- switch(values$data_frequency,
                   "daily" = 12,
                   "hourly" = 12 * 24,
                   "minute" = 12 * 60,
                   12
    )
    
    slow <- switch(values$data_frequency,
                   "daily" = 26,
                   "hourly" = 26 * 24,
                   "minute" = 26 * 60,
                   26
    )
    
    signal_period <- switch(values$data_frequency,
                            "daily" = 9,
                            "hourly" = 9 * 24,
                            "minute" = 9 * 60,
                            9
    )
    
    macd_data <- MACD(data$Mid, nFast = fast, nSlow = slow, nSig = signal_period)
    data$macd <- macd_data[, "macd"]
    data$signal <- macd_data[, "signal"]
    data$histogram <- data$macd - data$signal
    
    p <- plot_ly(data, x = ~datetime) %>%
      add_lines(y = ~macd, name = "MACD", line = list(color = "#3498db", width = 2)) %>%
      add_lines(y = ~signal, name = "Signal", line = list(color = "#e74c3c", width = 1)) %>%
      add_bars(y = ~histogram, name = "Histogram", 
               marker = list(color = ifelse(data$histogram > 0, "#27ae60", "#e74c3c"))) %>%
      layout(
        title = "MACD",
        xaxis = list(title = "Time"),
        yaxis = list(title = "MACD"),
        shapes = list(
          list(type = "line", x0 = min(data$datetime), x1 = max(data$datetime),
               y0 = 0, y1 = 0, line = list(color = "#95a5a6", dash = "dot"))
        )
      )
    
    p
  })
  
  output$bollingerChart <- renderPlotly({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 500)
    
    if (nrow(data) < 20) return(plotly_empty())
    
    # Calculate Bollinger Bands
    bb_period <- switch(values$data_frequency,
                        "daily" = 20,
                        "hourly" = 20 * 24,
                        "minute" = 20 * 60,
                        20
    )
    
    bb <- BBands(data$Mid, n = bb_period)
    data$bb_upper <- bb[, "up"]
    data$bb_lower <- bb[, "dn"]
    data$bb_mavg <- bb[, "mavg"]
    data$bb_pctb <- bb[, "pctB"]
    
    p <- plot_ly(data, x = ~datetime, y = ~bb_pctb, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = "Bollinger %B",
        xaxis = list(title = "Time"),
        yaxis = list(title = "%B"),
        shapes = list(
          list(type = "line", x0 = min(data$datetime), x1 = max(data$datetime),
               y0 = 1, y1 = 1, line = list(color = "#e74c3c", dash = "dash")),
          list(type = "line", x0 = min(data$datetime), x1 = max(data$datetime),
               y0 = 0, y1 = 0, line = list(color = "#27ae60", dash = "dash"))
        )
      )
    
    p
  })
  
  # Volatility Analysis - Enhanced with frequency-adaptive calculations
  output$volatilityMetrics <- renderText({
    req(pair_data(), input$volWindow)
    data <- pair_data() %>% slice_tail(n = max(1000, input$volWindow * 2))
    
    if (nrow(data) < input$volWindow) return("Insufficient data")
    
    returns <- data$returns[!is.na(data$returns)]
    periods_per_year <- get_trading_periods_per_year(values$data_frequency)
    
    current_vol <- sd(tail(returns, input$volWindow), na.rm = TRUE) * sqrt(periods_per_year) * 100
    avg_vol <- sd(returns, na.rm = TRUE) * sqrt(periods_per_year) * 100
    
    rolling_vol <- rollapply(returns, input$volWindow, 
                             function(x) sd(x, na.rm = TRUE) * sqrt(periods_per_year) * 100,
                             fill = NA, align = "right")
    
    min_vol <- min(rolling_vol, na.rm = TRUE)
    max_vol <- max(rolling_vol, na.rm = TRUE)
    
    paste(
      paste("Current Vol:", round(current_vol, 2), "%"),
      paste("Average Vol:", round(avg_vol, 2), "%"),
      paste("Min Vol:", round(min_vol, 2), "%"),
      paste("Max Vol:", round(max_vol, 2), "%"),
      paste("Vol Regime:", ifelse(current_vol > avg_vol, "High", "Low")),
      paste("Data Frequency:", values$data_frequency),
      sep = "\n"
    )
  })
  
  output$volatilityChart <- renderPlotly({
    req(pair_data(), input$volWindow)
    data <- pair_data() %>% slice_tail(n = 2000)
    
    if (nrow(data) < input$volWindow) return(plotly_empty())
    
    returns <- data$returns
    periods_per_year <- get_trading_periods_per_year(values$data_frequency)
    
    rolling_vol <- rollapply(returns, width = input$volWindow, 
                             FUN = function(x) sd(x, na.rm = TRUE) * sqrt(periods_per_year) * 100,
                             fill = NA, align = "right")
    
    data$volatility <- rolling_vol
    
    p <- plot_ly(data, x = ~datetime, y = ~volatility, type = "scatter", mode = "lines",
                 line = list(color = "#9b59b6", width = 2)) %>%
      layout(
        title = paste("Rolling Volatility (", input$volWindow, "-period window)"),
        xaxis = list(title = "Time"),
        yaxis = list(title = "Volatility (% ann.)")
      )
    
    p
  })
  
  # Risk Metrics - Enhanced with frequency-adaptive VaR
  output$riskMetrics <- renderText({
    req(pair_data(), input$timeHorizon, input$portfolioValue, input$confidenceLevel)
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < 100) return("Insufficient data")
    
    returns <- data$returns[!is.na(data$returns)]
    periods_per_year <- get_trading_periods_per_year(values$data_frequency)
    
    tryCatch({
      # Scale returns to time horizon
      scaled_returns <- returns * sqrt(input$timeHorizon)
      
      # Calculate VaR
      var_percentile <- (100 - input$confidenceLevel) / 100
      var_value <- quantile(scaled_returns, var_percentile, na.rm = TRUE)
      
      # Expected Shortfall
      es_value <- mean(scaled_returns[scaled_returns <= var_value], na.rm = TRUE)
      
      # Convert to portfolio value
      var_dollar <- abs(var_value) * input$portfolioValue
      es_dollar <- abs(es_value) * input$portfolioValue
      
      # Sharpe ratio
      sharpe_ratio <- mean(returns, na.rm = TRUE) / sd(returns, na.rm = TRUE) * sqrt(periods_per_year)
      # Simple drawdown calculation
      cumulative_returns <- cumprod(1 + returns)
      running_max <- cummax(cumulative_returns)
      drawdown <- (cumulative_returns - running_max) / running_max
      max_drawdown <- min(drawdown, na.rm = TRUE) * 100
      
      paste(
        paste("VaR (", input$confidenceLevel, "%):", "$", format(round(var_dollar, 0), big.mark = ",")),
        paste("Expected Shortfall:", "$", format(round(es_dollar, 0), big.mark = ",")),
        paste("Max Drawdown:", paste0(round(max_drawdown, 2), "%")),
        paste("Sharpe Ratio:", round(sharpe_ratio, 3)),
        paste("Time Horizon:", input$timeHorizon, values$data_frequency),
        sep = "\n"
      )
    }, error = function(e) {
      "Error calculating risk metrics"
    })
  })
  
  output$varChart <- renderPlotly({
    req(pair_data(), input$timeHorizon, input$portfolioValue, input$confidenceLevel)
    data <- pair_data() %>% slice_tail(n = 1000)
    
    if (nrow(data) < 200) return(plotly_empty())
    
    returns <- data$returns[!is.na(data$returns)]
    
    # Calculate rolling VaR with frequency-adjusted time horizon
    window_size <- min(200, length(returns) - 50)
    var_percentile <- (100 - input$confidenceLevel) / 100
    
    rolling_var <- rollapply(returns, width = window_size, 
                             FUN = function(x) {
                               scaled_returns <- x * sqrt(input$timeHorizon)
                               quantile(scaled_returns, var_percentile, na.rm = TRUE)
                             }, 
                             fill = NA, align = "right")
    
    # Prepare data for plotting
    var_data <- data.frame(
      datetime = tail(data$datetime, length(rolling_var)),
      var = abs(rolling_var) * input$portfolioValue,
      returns = tail(returns, length(rolling_var)) * sqrt(input$timeHorizon) * input$portfolioValue
    )
    
    var_data <- var_data[complete.cases(var_data), ]
    
    if (nrow(var_data) == 0) return(plotly_empty())
    
    p <- plot_ly(var_data, x = ~datetime) %>%
      add_lines(y = ~var, name = paste0("VaR (", input$confidenceLevel, "%)"),
                line = list(color = "#e74c3c", width = 2)) %>%
      add_bars(y = ~returns, name = "Scaled P&L", 
               marker = list(color = ifelse(var_data$returns < -var_data$var, 
                                            "#c0392b", "#3498db"))) %>%
      layout(
        title = paste("Value at Risk Analysis -", input$timeHorizon, "period horizon"),
        xaxis = list(title = "Time"),
        yaxis = list(title = "USD")
      )
    
    p
  })
  
  # Correlation Analysis - Enhanced for dual frequency
  output$correlationSummary <- renderText({
    req(aggregated_data(), input$correlationWindow)
    
    if (length(input$correlationPairs) < 2) return("Select at least 2 currency pairs")
    
    tryCatch({
      # Filter data for selected pairs
      corr_data <- aggregated_data() %>%
        filter(pair %in% input$correlationPairs) %>%
        select(datetime, pair, returns) %>%
        filter(!is.na(returns)) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-datetime) %>%
        na.omit()
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) {
        return("Insufficient complete data for correlation analysis")
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Summary statistics
      upper_tri <- corr_matrix[upper.tri(corr_matrix)]
      avg_corr <- mean(upper_tri, na.rm = TRUE)
      max_corr <- max(upper_tri, na.rm = TRUE)
      min_corr <- min(upper_tri, na.rm = TRUE)
      
      paste(
        paste("Average Correlation:", round(avg_corr, 3)),
        paste("Highest Correlation:", round(max_corr, 3)),
        paste("Lowest Correlation:", round(min_corr, 3)),
        paste("Pairs Analyzed:", length(input$correlationPairs)),
        paste("Complete Observations:", format(nrow(corr_data), big.mark = ",")),
        paste("Data Frequency:", values$data_frequency),
        sep = "\n"
      )
    }, error = function(e) {
      "Error calculating correlations. Try selecting different pairs or check data availability."
    })
  })
  
  output$correlationHeatmap <- renderPlot({
    req(aggregated_data())
    
    if (length(input$correlationPairs) < 2) {
      plot.new()
      text(0.5, 0.5, "Select at least 2 currency pairs", cex = 1.5)
      return()
    }
    
    tryCatch({
      # Filter data for selected pairs
      corr_data <- aggregated_data() %>%
        filter(pair %in% input$correlationPairs) %>%
        select(datetime, pair, returns) %>%
        filter(!is.na(returns)) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns) %>%
        select(-datetime) %>%
        na.omit()
      
      if (ncol(corr_data) < 2 || nrow(corr_data) < 50) {
        plot.new()
        text(0.5, 0.5, "Insufficient complete data", cex = 1.2)
        return()
      }
      
      # Calculate correlation matrix
      corr_matrix <- cor(corr_data, use = "complete.obs", method = input$correlationType)
      
      # Create enhanced heatmap
      corrplot(corr_matrix, method = "color", type = "upper", 
               order = "hclust", tl.cex = 1.2, tl.col = "#2c3e50",
               cl.cex = 1.0, addCoef.col = "#2c3e50", number.cex = 1.0,
               col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200),
               title = paste("Correlation Matrix (", input$correlationType, ")", sep = ""))
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, "Error creating correlation heatmap", cex = 1.2)
    })
  })
  
  # Rolling correlations with frequency awareness
  output$rollingCorrelations <- renderPlotly({
    req(aggregated_data(), input$correlationWindow)
    
    if (length(input$correlationPairs) < 2) return(plotly_empty())
    
    tryCatch({
      # Select first two pairs for rolling correlation
      selected_pairs <- input$correlationPairs[1:2]
      
      corr_data <- aggregated_data() %>%
        filter(pair %in% selected_pairs) %>%
        select(datetime, pair, returns) %>%
        filter(!is.na(returns)) %>%
        tidyr::pivot_wider(names_from = pair, values_from = returns)
      
      if (ncol(corr_data) < 3 || nrow(corr_data) < input$correlationWindow) {
        return(plotly_empty())
      }
      
      # Remove rows with NA values
      corr_data <- corr_data[complete.cases(corr_data), ]
      
      if (nrow(corr_data) < input$correlationWindow) return(plotly_empty())
      
      # Calculate rolling correlation
      rolling_corr <- rollapply(corr_data[, 2:3], width = input$correlationWindow,
                                FUN = function(x) cor(x[,1], x[,2], 
                                                      use = "complete.obs", 
                                                      method = input$correlationType),
                                fill = NA, align = "right", by.column = FALSE)
      
      corr_df <- data.frame(
        datetime = tail(corr_data$datetime, length(rolling_corr)),
        correlation = rolling_corr
      ) %>%
        filter(!is.na(correlation))
      
      if (nrow(corr_df) == 0) return(plotly_empty())
      
      p <- plot_ly(corr_df, x = ~datetime, y = ~correlation, type = "scatter", mode = "lines",
                   line = list(color = "#3498db", width = 2)) %>%
        layout(
          title = paste("Rolling", input$correlationType, "Correlation:", 
                        paste(selected_pairs, collapse = " vs "),
                        "(", input$correlationWindow, "periods)"),
          xaxis = list(title = "Time"),
          yaxis = list(title = "Correlation", range = c(-1, 1)),
          shapes = list(
            list(type = "line", x0 = min(corr_df$datetime), x1 = max(corr_df$datetime),
                 y0 = 0, y1 = 0, line = list(color = "#95a5a6", dash = "dash"))
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
        xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
        yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
        annotations = list(
          x = 0.5, y = 0.5, text = "No data available", showarrow = FALSE,
          xref = "paper", yref = "paper", font = list(size = 16)
        )
      )
  }
  
  # Clean up database connection when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$connection)) {
      tryCatch({
        dbDisconnect(values$connection)
      }, error = function(e) {
        # Connection may already be closed
      })
    }
    
    # Close any remaining MySQL connections
    tryCatch({
      all_connections <- dbListConnections(RMySQL::MySQL())
      for (con in all_connections) {
        dbDisconnect(con)
      }
    }, error = function(e) {
      # Connections may already be closed
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)