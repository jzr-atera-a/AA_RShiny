# FX Analysis Dashboard with MySQL Integration - Enhanced Error Reporting Version
# Fixed database connection tab and technical indicators tab with detailed error reporting

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
  dashboardHeader(title = "FX Analysis Dashboard - MySQL (Enhanced Error Reporting)"),
  
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
      menuItem("Technical Indicators", tabName = "technical", icon = icon("chart-bar"))
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
        .data-warning {
          background-color: #fff3cd;
          color: #856404;
          padding: 15px;
          border-radius: 8px;
          border: 1px solid #ffeaa7;
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
        .query-box {
          background-color: #f8f9fa;
          padding: 10px;
          border-radius: 5px;
          margin: 10px 0;
          font-family: 'Courier New', monospace;
          font-size: 11px;
          border: 1px solid #dee2e6;
          max-height: 300px;
          overflow-y: auto;
        }
        .debug-info {
          background-color: #e9ecef;
          padding: 10px;
          border-radius: 5px;
          margin: 10px 0;
          font-family: 'Courier New', monospace;
          font-size: 11px;
          border: 1px solid #ced4da;
          max-height: 400px;
          overflow-y: auto;
        }
        .small-box {
          border-radius: 8px;
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
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
                      
                      checkboxInput("enableDebugMode", "Enable Debug Mode", value = TRUE)
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
                    title = "Data Processing Summary", 
                    status = "success", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(4,
                             h5("Raw Data Analysis:"),
                             verbatimTextOutput("rawDataAnalysis")
                      ),
                      column(4,
                             h5("Processing Steps:"),
                             verbatimTextOutput("processingSteps")
                      ),
                      column(4,
                             h5("Final Data Quality:"),
                             verbatimTextOutput("finalDataQuality")
                      )
                    )
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Data Preview", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    withSpinner(DT::dataTableOutput("dataPreview"))
                  )
                )
              )
      ),
      
      # Market Overview Tab (keeping existing structure)
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
                    title = "Chart Controls",
                    status = "info",
                    solidHeader = TRUE,
                    width = 12,
                    
                    fluidRow(
                      column(4,
                             checkboxGroupInput("priceComponents", "Show Price Components:",
                                                choices = c("Mid Price" = "Mid",
                                                            "Bid Price" = "Bid", 
                                                            "Ask Price" = "Ask"),
                                                selected = c("Mid", "Bid", "Ask"),
                                                inline = TRUE)
                      ),
                      column(4,
                             checkboxInput("showSpread", "Show Bid-Ask Spread", value = FALSE)
                      ),
                      column(4,
                             checkboxInput("showMovingAvg", "Show Moving Averages", value = TRUE)
                      )
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
                    title = "Price Chart", 
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
                    width = 6,
                    withSpinner(DT::dataTableOutput("marketStats"))
                  ),
                  box(
                    title = "Price Variation Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 6,
                    withSpinner(DT::dataTableOutput("variationStats"))
                  )
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
                    h5("Data Requirements Check:"),
                    verbatimTextOutput("technicalDataRequirements"),
                    
                    br(),
                    h5("Current Signals:"),
                    verbatimTextOutput("technicalSignals")
                  ),
                  
                  box(
                    title = "Technical Chart with Price and Indicators", 
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
                    conditionalPanel(
                      condition = "input.technicalIndicators.includes('rsi')",
                      withSpinner(plotlyOutput("rsiChart", height = "250px"))
                    ),
                    conditionalPanel(
                      condition = "!input.technicalIndicators.includes('rsi')",
                      div(class = "error-message", style = "margin: 20px; padding: 20px;",
                          p("RSI indicator not selected"))
                    )
                  ),
                  
                  box(
                    title = "MACD Indicator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    conditionalPanel(
                      condition = "input.technicalIndicators.includes('macd')",
                      withSpinner(plotlyOutput("macdChart", height = "250px"))
                    ),
                    conditionalPanel(
                      condition = "!input.technicalIndicators.includes('macd')",
                      div(class = "error-message", style = "margin: 20px; padding: 20px;",
                          p("MACD indicator not selected"))
                    )
                  ),
                  
                  box(
                    title = "Stochastic Oscillator", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 4,
                    conditionalPanel(
                      condition = "input.technicalIndicators.includes('stoch')",
                      withSpinner(plotlyOutput("stochChart", height = "250px"))
                    ),
                    conditionalPanel(
                      condition = "!input.technicalIndicators.includes('stoch')",
                      div(class = "error-message", style = "margin: 20px; padding: 20px;",
                          p("Stochastic indicator not selected"))
                    )
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Technical Analysis Summary", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(6,
                             h5("Indicator Calculations Status:"),
                             verbatimTextOutput("indicatorStatus")
                      ),
                      column(6,
                             h5("Signal Summary:"),
                             DT::dataTableOutput("signalSummary")
                      )
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
    show_detailed_error = FALSE
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
          
          # Check structure
          structure_query <- paste("DESCRIBE", table)
          structure_result <- dbGetQuery(connection_ref, structure_query)
          diagnostics <- c(diagnostics, "Table structure:")
          diagnostics <- c(diagnostics, paste(structure_result$Field, structure_result$Type, sep = " (", collapse = ")\n"))
          
          # Check for data
          sample_query <- paste("SELECT * FROM", table, "LIMIT 1")
          sample_result <- dbGetQuery(connection_ref, sample_query)
          diagnostics <- c(diagnostics, paste("Sample record available:", nrow(sample_result) > 0))
          
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
  
  # Enhanced data processing function
  process_fx_data <- function(raw_data, level, enable_debug = TRUE) {
    processing_steps <- c()
    
    if (enable_debug) {
      processing_steps <- c(processing_steps, paste("Starting data processing at", Sys.time()))
      processing_steps <- c(processing_steps, paste("Input data shape:", nrow(raw_data), "rows x", ncol(raw_data), "cols"))
      processing_steps <- c(processing_steps, paste("Column names:", paste(names(raw_data), collapse = ", ")))
    }
    
    # Step 1: Data type conversion and cleaning
    tryCatch({
      data <- raw_data %>%
        mutate(
          Mid = as.numeric(as.character(Mid)),
          Bid = as.numeric(as.character(Bid)), 
          Ask = as.numeric(as.character(Ask)),
          pair = as.character(pair),
          Timestamp = as.POSIXct(Timestamp)
        )
      
      if (enable_debug) {
        processing_steps <- c(processing_steps, "✓ Data types converted successfully")
        processing_steps <- c(processing_steps, paste("Records after conversion:", nrow(data)))
      }
      
    }, error = function(e) {
      processing_steps <- c(processing_steps, paste("✗ Data type conversion failed:", e$message))
      values$processing_log <- paste(processing_steps, collapse = "\n")
      stop("Data type conversion failed")
    })
    
    # Step 2: Remove invalid records
    initial_count <- nrow(data)
    data <- data %>%
      filter(!is.na(Mid), !is.na(Timestamp)) %>%
      arrange(pair, Timestamp)
    
    if (enable_debug) {
      processing_steps <- c(processing_steps, paste("✓ Filtered invalid records:", initial_count, "->", nrow(data)))
    }
    
    if (nrow(data) == 0) {
      processing_steps <- c(processing_steps, "✗ No valid records after filtering")
      values$processing_log <- paste(processing_steps, collapse = "\n")
      stop("No valid records after filtering")
    }
    
    # Step 3: Handle missing Bid/Ask data
    missing_bid <- sum(is.na(data$Bid))
    missing_ask <- sum(is.na(data$Ask))
    
    if (missing_bid > 0 || missing_ask > 0) {
      typical_spread_pct <- 0.002
      data <- data %>%
        mutate(
          Bid = ifelse(is.na(Bid), Mid * (1 - typical_spread_pct/2), Bid),
          Ask = ifelse(is.na(Ask), Mid * (1 + typical_spread_pct/2), Ask)
        )
      
      if (enable_debug) {
        processing_steps <- c(processing_steps, paste("✓ Reconstructed missing Bid/Ask:", missing_bid, "bid,", missing_ask, "ask"))
      }
    }
    
    # Step 4: Calculate spreads and basic metrics
    data <- data %>%
      mutate(
        spread = Ask - Bid,
        spread_pct = (Ask - Bid) / Mid * 100,
        date = as.Date(Timestamp)
      )
    
    if (enable_debug) {
      processing_steps <- c(processing_steps, "✓ Calculated spreads and date fields")
    }
    
    # Step 5: Apply aggregation if requested
    if (level == "raw") {
      result <- data %>%
        group_by(pair) %>%
        mutate(
          returns = c(NA, diff(log(Mid))),
          returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
        ) %>%
        ungroup()
      
      if (enable_debug) {
        processing_steps <- c(processing_steps, "✓ Calculated returns for raw data")
      }
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
      
      if (enable_debug) {
        processing_steps <- c(processing_steps, paste("✓ Applied", level, "aggregation:", nrow(data), "->", nrow(result), "records"))
      }
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
        stats_text <- paste(stats_text, paste("fx_spot_prices records:", format(row_count$count, big.mark = ",")), "\n")
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
  
  # Enhanced data loading with comprehensive error handling
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
      showNotification("Starting enhanced data load process...", type = "message")
      
      raw_data <- NULL
      debug_mode <- ifelse(is.null(input$enableDebugMode), TRUE, input$enableDebugMode)
      
      if (input$sourceTable == "fx_spot_prices_daily") {
        
        showNotification("Loading daily data...", type = "message")
        
        # Test table existence first
        table_check_query <- "SHOW TABLES LIKE 'fx_spot_prices_daily'"
        table_exists <- dbGetQuery(connection_ref, table_check_query)
        
        if (nrow(table_exists) == 0) {
          log_error("Table 'fx_spot_prices_daily' does not exist", "Daily Data Loading", table_check_query, 
                    list(available_tables = paste(dbListTables(connection_ref), collapse = ", ")))
          return()
        }
        
        # Get table structure
        structure_query <- "DESCRIBE fx_spot_prices_daily"
        table_structure <- dbGetQuery(connection_ref, structure_query)
        
        # Log successful structure query
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", structure_query),
                                paste("Status: SUCCESS"),
                                paste("Columns found:", paste(table_structure$Field, collapse = ", ")),
                                "---", 
                                sep = "\n")
        
        # Main data query with limit for safety
        main_query <- "SELECT * FROM fx_spot_prices_daily ORDER BY Timestamp DESC, pair LIMIT 10000"
        
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
        
        showNotification(paste("Loading", input$intradayPair, "data for", input$dayRange, "days..."), type = "message")
        
        # Test table existence
        table_check_query <- "SHOW TABLES LIKE 'fx_spot_prices'"
        table_exists <- dbGetQuery(connection_ref, table_check_query)
        
        if (nrow(table_exists) == 0) {
          log_error("Table 'fx_spot_prices' does not exist", "Intraday Data Loading", table_check_query, 
                    list(available_tables = paste(dbListTables(connection_ref), collapse = ", ")))
          return()
        }
        
        # Check if pair exists in database
        pair_check_query <- paste0("SELECT COUNT(*) as count FROM fx_spot_prices WHERE pair = '", input$intradayPair, "'")
        pair_count <- dbGetQuery(connection_ref, pair_check_query)
        
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", pair_check_query),
                                paste("Status: SUCCESS"),
                                paste("Records found for pair:", pair_count$count),
                                "---", 
                                sep = "\n")
        
        if (pair_count$count == 0) {
          # Get available pairs
          available_pairs_query <- "SELECT DISTINCT pair FROM fx_spot_prices LIMIT 10"
          available_pairs <- dbGetQuery(connection_ref, available_pairs_query)
          
          log_error(paste("No data found for pair:", input$intradayPair), "Intraday Data Loading", pair_check_query, 
                    list(available_pairs = paste(available_pairs$pair, collapse = ", ")))
          
          output$dataStatus <- renderUI({
            div(class = "connection-error", h5("No Data Found"), 
                p(paste("No data found for pair:", input$intradayPair)),
                p(paste("Available pairs:", paste(available_pairs$pair, collapse = ", "))))
          })
          return()
        }
        
        # Get available dates for the pair
        dates_query <- paste0("
          SELECT DISTINCT DATE(Timestamp) as date_only 
          FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "'
          ORDER BY DATE(Timestamp) DESC 
          LIMIT ", input$dayRange)
        
        last_dates <- dbGetQuery(connection_ref, dates_query)
        
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", dates_query),
                                paste("Status: SUCCESS"),
                                paste("Dates found:", nrow(last_dates)),
                                "---", 
                                sep = "\n")
        
        if (nrow(last_dates) == 0) {
          log_error("No dates found for the specified pair", "Intraday Data Loading", dates_query, 
                    list(pair = input$intradayPair, dayRange = input$dayRange))
          
          output$dataStatus <- renderUI({
            div(class = "connection-error", h5("No Data Found"), 
                p(paste("No data found for pair:", input$intradayPair)))
          })
          return()
        }
        
        # Get raw data for the selected dates
        date_list <- paste0("'", last_dates$date_only, "'", collapse = ", ")
        data_query <- paste0("
          SELECT * FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "' 
          AND DATE(Timestamp) IN (", date_list, ")
          ORDER BY Timestamp
          LIMIT 50000
        ")
        
        raw_data <- dbGetQuery(connection_ref, data_query)
        values$source_table <- "fx_spot_prices"
        
        values$sql_log <- paste(values$sql_log, 
                                paste("Timestamp:", Sys.time()),
                                paste("Query:", data_query),
                                paste("Status: SUCCESS"),
                                paste("Records retrieved:", nrow(raw_data)),
                                paste("Date range:", min(last_dates$date_only), "to", max(last_dates$date_only)),
                                "---", 
                                sep = "\n")
      }
      
      # Validate raw data
      if (is.null(raw_data) || nrow(raw_data) == 0) {
        log_error("Query executed successfully but returned no records", "Data Validation", "", 
                  list(source_table = input$sourceTable, query_result_rows = ifelse(is.null(raw_data), "NULL", nrow(raw_data))))
        
        output$dataStatus <- renderUI({
          div(class = "connection-error", h5("No Data Returned"), 
              p("Query executed successfully but returned no records."))
        })
        return()
      }
      
      # Check required columns
      required_cols <- c("Timestamp", "Mid", "pair")
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
      
      showNotification(paste("Retrieved", nrow(raw_data), "records. Processing..."), type = "message")
      
      # Process data with enhanced error handling
      aggregation_level <- ifelse(values$source_table == "fx_spot_prices", input$aggregationLevel, "raw")
      processed_data <- process_fx_data(raw_data, aggregation_level, debug_mode)
      
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
            h5("Data Loaded Successfully"),
            p(paste("Source:", values$source_table)),
            p(paste("Raw records retrieved:", nrow(raw_data))),
            p(paste("Final processed records:", nrow(processed_data))),
            if (values$source_table == "fx_spot_prices") {
              p(paste("Aggregation level:", input$aggregationLevel))
            } else {
              p("Daily data - no aggregation applied")
            },
            p(paste("Currency pairs:", paste(available_pairs, collapse = ", "))),
            p(paste("Date range:", min(processed_data$date, na.rm = TRUE), "to", max(processed_data$date, na.rm = TRUE))))
      })
      
      showNotification(paste("Successfully processed", nrow(processed_data), "records"), type = "message")
      
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
  
  # Processing information outputs
  output$rawDataAnalysis <- renderText({
    if (is.null(values$fx_data)) return("No data loaded")
    
    data <- values$fx_data
    paste(
      paste("Records loaded:", nrow(data)),
      paste("Columns:", ncol(data)),
      paste("Memory usage:", format(object.size(data), units = "Mb")),
      paste("Date range:", range(data$date, na.rm = TRUE)[1], "to", range(data$date, na.rm = TRUE)[2]),
      paste("Pairs:", paste(unique(data$pair), collapse = ", ")),
      sep = "\n"
    )
  })
  
  output$processingSteps <- renderText({
    if (is.null(values$processing_log)) {
      "No processing log available"
    } else {
      values$processing_log
    }
  })
  
  output$finalDataQuality <- renderText({
    if (is.null(values$fx_data)) return("No data loaded")
    
    data <- values$fx_data
    
    # Quality checks
    missing_mid <- sum(is.na(data$Mid))
    missing_bid <- sum(is.na(data$Bid))
    missing_ask <- sum(is.na(data$Ask))
    unique_prices <- length(unique(data$Mid))
    price_range <- max(data$Mid, na.rm = TRUE) - min(data$Mid, na.rm = TRUE)
    
    paste(
      paste("Quality Assessment:"),
      paste("Missing Mid prices:", missing_mid, "(", round(missing_mid/nrow(data)*100, 2), "%)"),
      paste("Missing Bid prices:", missing_bid, "(", round(missing_bid/nrow(data)*100, 2), "%)"),
      paste("Missing Ask prices:", missing_ask, "(", round(missing_ask/nrow(data)*100, 2), "%)"),
      paste("Unique price levels:", unique_prices),
      paste("Price range:", format(price_range, scientific = FALSE, digits = 6)),
      "",
      ifelse(missing_mid == 0 && missing_bid == 0 && missing_ask == 0, "✓ No missing price data", "⚠ Some missing price data"),
      ifelse(unique_prices > 10, "✓ Good price variation", "⚠ Limited price variation"),
      ifelse(price_range > 0.001, "✓ Adequate price range", "⚠ Very small price range"),
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
    
    preview_cols <- c("date", "Timestamp", "pair", "Mid", "Bid", "Ask", "spread_pct")
    if ("Mid_High" %in% names(values$fx_data)) {
      preview_cols <- c(preview_cols, "Mid_Open", "Mid_High", "Mid_Low", "Mid_Close")
    }
    if ("returns" %in% names(values$fx_data)) {
      preview_cols <- c(preview_cols, "returns", "returns_pct")
    }
    
    preview_data <- values$fx_data %>% 
      select(any_of(preview_cols)) %>%
      head(30)
    
    datatable(preview_data, options = list(scrollX = TRUE, pageLength = 15, dom = 'frtip')) %>%
      formatRound(columns = c("Mid", "Bid", "Ask", "Mid_Open", "Mid_High", "Mid_Low", "Mid_Close"), digits = 6) %>%
      formatRound(columns = c("spread_pct", "returns", "returns_pct"), digits = 4)
  })
  
  # Value boxes (keeping from original)
  output$currentPrice <- renderValueBox({
    req(pair_data())
    current_data <- pair_data() %>% slice_tail(n = 1)
    valueBox(
      value = format(round(current_data$Mid, 6), nsmall = 6),
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
      value = paste0(ifelse(change > 0, "+", ""), format(round(change, 4), nsmall = 4), "%"),
      subtitle = "Period Change",
      icon = icon(icon_name),
      color = color
    )
  })
  
  output$volatility30d <- renderValueBox({
    req(pair_data())
    data <- pair_data()
    if (nrow(data) > 1 && "returns" %in% names(data)) {
      vol <- sd(data$returns, na.rm = TRUE) * sqrt(252) * 100
      vol_text <- ifelse(is.na(vol) || vol == 0, "0.000%", paste0(format(round(vol, 3), nsmall = 3), "%"))
      color <- ifelse(is.na(vol) || vol == 0, "red", "yellow")
    } else {
      vol_text <- "N/A"
      color <- "red"
    }
    
    valueBox(
      value = vol_text,
      subtitle = "Annualized Volatility",
      icon = icon("wave-square"),
      color = color
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
  
  # Main price chart (keeping from original)
  output$overviewChart <- renderPlotly({
    req(pair_data())
    
    data <- pair_data()
    main_price <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    bid_price <- if ("Bid_Close" %in% names(data)) data$Bid_Close else data$Bid
    ask_price <- if ("Ask_Close" %in% names(data)) data$Ask_Close else data$Ask
    
    price_range <- max(main_price, na.rm = TRUE) - min(main_price, na.rm = TRUE)
    
    p <- plot_ly(data, x = ~Timestamp) %>%
      layout(
        title = paste(input$selectedPair, "| Records:", nrow(data), "| Range:", format(price_range, digits = 6)),
        xaxis = list(title = "Date/Time"),
        yaxis = list(title = "Exchange Rate", tickformat = ".6f"),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white"
      )
    
    if ("Mid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = main_price, name = "Mid Price", line = list(color = "#2c3e50", width = 2))
    }
    if ("Bid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = bid_price, name = "Bid Price", line = list(color = "#27ae60", width = 1))
    }
    if ("Ask" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ask_price, name = "Ask Price", line = list(color = "#e74c3c", width = 1))
    }
    if (input$showSpread) {
      p <- p %>% add_lines(y = ~spread_pct, name = "Spread %", yaxis = "y2",
                           line = list(color = "#f39c12", width = 1, dash = "dot")) %>%
        layout(yaxis2 = list(overlaying = "y", side = "right", title = "Spread %"))
    }
    if (input$showMovingAvg && "Mid" %in% input$priceComponents && nrow(data) > 20) {
      ma20 <- SMA(main_price, n = 20)
      p <- p %>% add_lines(y = ma20, name = "MA(20)", line = list(color = "#9b59b6", width = 1, dash = "dash"))
    }
    
    p
  })
  
  # Market statistics and variation stats (keeping from original)
  output$marketStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    stats <- data.frame(
      Metric = c("Current_Price", "Min_Price", "Max_Price", "Price_Range", "Avg_Spread_bps", "Observations"),
      Value = as.character(c(
        round(tail(price_series, 1), 6),
        round(min(price_series, na.rm = TRUE), 6),
        round(max(price_series, na.rm = TRUE), 6),
        round(max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE), 6),
        round(mean(data$spread_pct, na.rm = TRUE) * 100, 2),
        nrow(data)
      ))
    )
    
    datatable(stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  output$variationStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    variation_stats <- data.frame(
      Metric = c("Records", "Returns_Available", "Non_Zero_Returns", "Max_Return", "Volatility_Ann"),
      Value = as.character(c(
        nrow(data),
        sum(!is.na(data$returns)),
        sum(!is.na(data$returns) & abs(data$returns) > 1e-10),
        ifelse(sum(!is.na(data$returns)) > 0, round(max(abs(data$returns), na.rm = TRUE), 6), 0),
        ifelse(sum(!is.na(data$returns)) > 1, round(sd(data$returns, na.rm = TRUE) * sqrt(252) * 100, 3), 0)
      ))
    )
    
    datatable(variation_stats, options = list(dom = 't'), rownames = FALSE)
  })
  
  # TECHNICAL INDICATORS TAB FUNCTIONS
  
  # Technical data requirements check
  output$technicalDataRequirements <- renderText({
    req(pair_data())
    data <- pair_data()
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    price_range <- max(price_series, na.rm = TRUE) - min(price_series, na.rm = TRUE)
    unique_prices <- length(unique(price_series))
    
    requirements <- c()
    requirements <- c(requirements, paste("Data points:", nrow(data)))
    requirements <- c(requirements, paste("Unique prices:", unique_prices))
    requirements <- c(requirements, paste("Price range:", format(price_range, scientific = TRUE, digits = 4)))
    requirements <- c(requirements, "")
    
    # Check requirements for each indicator
    if ("sma" %in% input$technicalIndicators) {
      sma_ok <- nrow(data) >= input$smaLength
      requirements <- c(requirements, paste("SMA:", ifelse(sma_ok, "✓ OK", "✗ Need more data")))
    }
    
    if ("ema" %in% input$technicalIndicators) {
      ema_ok <- nrow(data) >= input$emaLength
      requirements <- c(requirements, paste("EMA:", ifelse(ema_ok, "✓ OK", "✗ Need more data")))
    }
    
    if ("rsi" %in% input$technicalIndicators) {
      rsi_ok <- nrow(data) >= input$rsiLength && price_range > 1e-8
      requirements <- c(requirements, paste("RSI:", ifelse(rsi_ok, "✓ OK", "✗ Need more data or variation")))
    }
    
    if ("macd" %in% input$technicalIndicators) {
      macd_ok <- nrow(data) >= 50 && price_range > 1e-8
      requirements <- c(requirements, paste("MACD:", ifelse(macd_ok, "✓ OK", "✗ Need more data or variation")))
    }
    
    if ("bb" %in% input$technicalIndicators) {
      bb_ok <- nrow(data) >= input$bbLength && price_range > 1e-8
      requirements <- c(requirements, paste("Bollinger Bands:", ifelse(bb_ok, "✓ OK", "✗ Need more data or variation")))
    }
    
    if ("stoch" %in% input$technicalIndicators) {
      stoch_ok <- nrow(data) >= 30 && price_range > 1e-8
      requirements <- c(requirements, paste("Stochastic:", ifelse(stoch_ok, "✓ OK", "✗ Need more data or variation")))
    }
    
    paste(requirements, collapse = "\n")
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
                 name = "Price", line = list(color = "#2c3e50", width = 2))
    
    # Add technical indicators
    if ("sma" %in% input$technicalIndicators && nrow(data) >= input$smaLength) {
      sma_values <- SMA(price_series, n = input$smaLength)
      p <- p %>% add_lines(y = sma_values, name = paste("SMA(", input$smaLength, ")"),
                           line = list(color = "#e74c3c", width = 1))
    }
    
    if ("ema" %in% input$technicalIndicators && nrow(data) >= input$emaLength) {
      ema_values <- EMA(price_series, n = input$emaLength)
      p <- p %>% add_lines(y = ema_values, name = paste("EMA(", input$emaLength, ")"),
                           line = list(color = "#27ae60", width = 1))
    }
    
    if ("bb" %in% input$technicalIndicators && nrow(data) >= input$bbLength) {
      bb <- BBands(price_series, n = input$bbLength, sd = input$bbSd)
      if (!is.null(bb)) {
        p <- p %>% 
          add_lines(y = bb[, "up"], name = "BB Upper", line = list(color = "#95a5a6", dash = "dash")) %>%
          add_lines(y = bb[, "dn"], name = "BB Lower", line = list(color = "#95a5a6", dash = "dash")) %>%
          add_lines(y = bb[, "mavg"], name = "BB Middle", line = list(color = "#f39c12", width = 1))
      }
    }
    
    p %>% layout(
      title = paste("Technical Analysis -", input$selectedPair),
      xaxis = list(title = "Date"),
      yaxis = list(title = "Exchange Rate"),
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
          xaxis = list(title = "Date"),
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
          xaxis = list(title = "Date"), yaxis = list(title = "MACD"),
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
    
    # Use OHLC if available
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
          xaxis = list(title = "Date"),
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
      status <- c(status, paste("SMA:", ifelse(sma_ok, "✓", "✗")))
    }
    
    if ("ema" %in% input$technicalIndicators) {
      ema_ok <- nrow(data) >= input$emaLength  
      status <- c(status, paste("EMA:", ifelse(ema_ok, "✓", "✗")))
    }
    
    if ("rsi" %in% input$technicalIndicators) {
      rsi_ok <- nrow(data) >= input$rsiLength && price_range > 1e-8
      status <- c(status, paste("RSI:", ifelse(rsi_ok, "✓", "✗")))
    }
    
    if ("macd" %in% input$technicalIndicators) {
      macd_ok <- nrow(data) >= 50 && price_range > 1e-8
      status <- c(status, paste("MACD:", ifelse(macd_ok, "✓", "✗")))
    }
    
    if ("bb" %in% input$technicalIndicators) {
      bb_ok <- nrow(data) >= input$bbLength && price_range > 1e-8
      status <- c(status, paste("Bollinger Bands:", ifelse(bb_ok, "✓", "✗")))
    }
    
    if ("stoch" %in% input$technicalIndicators) {
      stoch_ok <- nrow(data) >= 30 && price_range > 1e-8
      status <- c(status, paste("Stochastic:", ifelse(stoch_ok, "✓", "✗")))
    }
    
    paste(status, collapse = "\n")
  })
  
  # Signal summary table
  output$signalSummary <- renderDT({
    req(pair_data())
    data <- pair_data() %>% slice_tail(n = 100)
    
    price_series <- if ("Mid_Close" %in% names(data)) data$Mid_Close else data$Mid
    
    if (nrow(data) < 20) {
      return(datatable(data.frame(Indicator = "No Data", Signal = "Insufficient data"), 
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
            Indicator = "RSI", 
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
            Indicator = "SMA", 
            Current_Value = paste0(deviation, "%"), 
            Signal = signal
          ))
        }
      }
      
      # Add more indicators as needed...
      
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
        Signal = "Select indicators to see signals"
      ))
    }
    
    datatable(signals_df, options = list(dom = 't', pageLength = 10), rownames = FALSE)
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