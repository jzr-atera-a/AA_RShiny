# FX Analysis Dashboard with MySQL Integration - Proper Aggregation Version
# Fixed aggregation logic to properly aggregate data at user-selected levels

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

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FX Analysis Dashboard - MySQL (Fixed Aggregation)"),
  
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
      menuItem("Market Overview", tabName = "overview", icon = icon("chart-line"))
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
          font-size: 12px;
          border: 1px solid #dee2e6;
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
                                  selected = "USDDKK"),
                      
                      br(),
                      
                      sliderInput("dayRange", "Number of Last Days to Load:",
                                  min = 3, max = 120, value = 30, step = 1,
                                  ticks = TRUE),
                      
                      br(),
                      
                      selectInput("aggregationLevel", "Data Aggregation Level:",
                                  choices = list(
                                    "Raw Data (No Aggregation)" = "raw",
                                    "5 Minute Average" = "5min",
                                    "15 Minute Average" = "15min",
                                    "1 Hour Average" = "hour",
                                    "Daily Average" = "day"
                                  ),
                                  selected = "hour"),
                      
                      div(style = "background-color: #f8f9fa; padding: 10px; border-radius: 5px; margin: 10px 0;",
                          h6("Intraday Data Info:"),
                          p(textOutput("dayRangeInfo"), style = "margin-bottom: 0; font-size: 12px;")
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
                    title = "SQL Query Information", 
                    status = "warning", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    h5("Executed SQL Queries:"),
                    div(class = "query-box",
                        verbatimTextOutput("executedQueries"))
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Data Preview & Analysis", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(6,
                             h5("Top 20 Aggregated Records:"),
                             withSpinner(DT::dataTableOutput("dataPreview"))
                      ),
                      column(6,
                             h5("Aggregation Analysis:"),
                             verbatimTextOutput("aggregationAnalysis"),
                             br(),
                             h5("Data Summary:"),
                             verbatimTextOutput("dataSummary")
                      )
                    )
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
                    title = "Price Chart with Multiple Components", 
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
    executed_queries = NULL
  )
  
  # Dynamic info text for day range
  output$dayRangeInfo <- renderText({
    if (!is.null(input$dayRange) && !is.null(input$aggregationLevel)) {
      agg_text <- switch(input$aggregationLevel,
                         "raw" = "raw tick data",
                         "5min" = "5-minute OHLC averages", 
                         "15min" = "15-minute OHLC averages",
                         "hour" = "hourly OHLC averages",
                         "day" = "daily OHLC averages")
      paste("Will load last", input$dayRange, "days and aggregate as", agg_text)
    } else {
      "Will load last 30 days of data"
    }
  })
  
  # Proper data aggregation function
  aggregate_fx_data <- function(data, level) {
    if (level == "raw") {
      # For raw data, just calculate returns
      result <- data %>%
        arrange(pair, Timestamp) %>%
        group_by(pair) %>%
        mutate(
          returns = c(NA, diff(log(Mid))),
          returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
        ) %>%
        ungroup()
      return(result)
    }
    
    # Convert data types to ensure numeric precision
    data <- data %>%
      mutate(
        Mid = as.numeric(Mid),
        Bid = as.numeric(Bid),
        Ask = as.numeric(Ask),
        Timestamp = as.POSIXct(Timestamp)
      )
    
    # Create time grouping based on aggregation level
    data <- data %>%
      mutate(
        year = year(Timestamp),
        month = month(Timestamp),
        day = day(Timestamp),
        hour = hour(Timestamp),
        minute = minute(Timestamp)
      )
    
    # Define time groupings for aggregation
    if (level == "5min") {
      data <- data %>% mutate(time_group = floor(minute / 5) * 5)
      group_vars <- c("pair", "year", "month", "day", "hour", "time_group")
    } else if (level == "15min") {
      data <- data %>% mutate(time_group = floor(minute / 15) * 15)
      group_vars <- c("pair", "year", "month", "day", "hour", "time_group")
    } else if (level == "hour") {
      group_vars <- c("pair", "year", "month", "day", "hour")
    } else if (level == "day") {
      group_vars <- c("pair", "year", "month", "day")
    }
    
    # Perform OHLC aggregation with proper price calculations
    aggregated <- data %>%
      group_by(across(all_of(group_vars))) %>%
      arrange(Timestamp, .by_group = TRUE) %>%
      summarise(
        Timestamp = first(Timestamp),
        date = as.Date(first(Timestamp)),
        # OHLC for Mid prices
        Mid = mean(Mid, na.rm = TRUE),
        Mid_Open = first(Mid),
        Mid_High = max(Mid, na.rm = TRUE),
        Mid_Low = min(Mid, na.rm = TRUE), 
        Mid_Close = last(Mid),
        # OHLC for Bid prices  
        Bid = mean(Bid, na.rm = TRUE),
        Bid_Open = first(Bid),
        Bid_High = max(Bid, na.rm = TRUE),
        Bid_Low = min(Bid, na.rm = TRUE),
        Bid_Close = last(Bid),
        # OHLC for Ask prices
        Ask = mean(Ask, na.rm = TRUE), 
        Ask_Open = first(Ask),
        Ask_High = max(Ask, na.rm = TRUE),
        Ask_Low = min(Ask, na.rm = TRUE),
        Ask_Close = last(Ask),
        # Calculate spreads
        spread = mean(Ask, na.rm = TRUE) - mean(Bid, na.rm = TRUE),
        spread_pct = (mean(Ask, na.rm = TRUE) - mean(Bid, na.rm = TRUE)) / mean(Mid, na.rm = TRUE) * 100,
        # Record count and time span
        record_count = n(),
        time_span_minutes = as.numeric(difftime(last(Timestamp), first(Timestamp), units = "mins")),
        .groups = 'drop'
      ) %>%
      arrange(pair, Timestamp) %>%
      group_by(pair) %>%
      mutate(
        returns = c(NA, diff(log(Mid))),
        returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
      ) %>%
      ungroup()
    
    return(aggregated)
  }
  
  # Test database connection
  observeEvent(input$testConnection, {
    if (input$password == "") {
      output$connectionStatus <- renderUI({
        div(class = "connection-error", h5("Connection Failed"), p("Password is required."))
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
        showNotification("Database connection established!", type = "message")
      }
      
    }, error = function(e) {
      values$connected <- FALSE
      values$connection <- NULL
      output$connectionStatus <- renderUI({
        div(class = "connection-error", h5("Connection Failed"), p("Error:", e$message))
      })
      showNotification(paste("Connection failed:", e$message), type = "error")
    })
  })
  
  # Close connections
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
      values$source_table <- NULL
      values$executed_queries <- NULL
      
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
  
  # Load data from database
  observeEvent(input$loadData, {
    req(values$connected, input$sourceTable)
    
    tryCatch({
      showNotification("Loading and processing data...", type = "message")
      
      queries_executed <- c()
      
      if (input$sourceTable == "fx_spot_prices_daily") {
        main_query <- "SELECT * FROM fx_spot_prices_daily ORDER BY Timestamp, pair"
        raw_data <- dbGetQuery(values$connection, main_query)
        values$source_table <- "fx_spot_prices_daily"
        queries_executed <- c(queries_executed, paste("Main Query:", main_query))
        
      } else if (input$sourceTable == "fx_spot_prices") {
        req(input$intradayPair, input$dayRange, input$aggregationLevel)
        
        # Get last N dates for the pair
        dates_query <- paste0("
          SELECT DISTINCT DATE(Timestamp) as date_only 
          FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "'
          ORDER BY DATE(Timestamp) DESC 
          LIMIT ", input$dayRange)
        
        last_dates <- dbGetQuery(values$connection, dates_query)
        queries_executed <- c(queries_executed, "Step 1 - Get available dates:", dates_query)
        
        if (nrow(last_dates) == 0) {
          output$dataStatus <- renderUI({
            div(class = "connection-error", h5("No Data Found"), 
                p(paste("No data found for pair:", input$intradayPair)))
          })
          values$data_loaded <- FALSE
          return()
        }
        
        # Get all data for those dates
        date_list <- paste0("'", last_dates$date_only, "'", collapse = ", ")
        
        data_query <- paste0("
          SELECT * FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "' 
          AND DATE(Timestamp) IN (", date_list, ")
          ORDER BY Timestamp
        ")
        
        raw_data <- dbGetQuery(values$connection, data_query)
        values$source_table <- "fx_spot_prices"
        
        queries_executed <- c(queries_executed, 
                              "Step 2 - Get raw data:", data_query,
                              paste("Dates found:", paste(last_dates$date_only, collapse = ", ")),
                              paste("Records retrieved:", nrow(raw_data)),
                              paste("Aggregation level:", input$aggregationLevel))
      }
      
      values$executed_queries <- paste(queries_executed, collapse = "\n\n")
      
      if (nrow(raw_data) == 0) {
        output$dataStatus <- renderUI({
          div(class = "connection-error", h5("No Data Found"), p("No data returned from query."))
        })
        values$data_loaded <- FALSE
        return()
      }
      
      # Process raw data
      processed_data <- raw_data %>%
        mutate(
          date = as.Date(Timestamp),
          Mid = as.numeric(Mid),
          Bid = as.numeric(Bid), 
          Ask = as.numeric(Ask),
          pair = as.character(pair),
          spread = as.numeric(Ask) - as.numeric(Bid),
          spread_pct = (as.numeric(Ask) - as.numeric(Bid)) / as.numeric(Mid) * 100
        ) %>%
        filter(!is.na(Mid), !is.na(Bid), !is.na(Ask), !is.na(Timestamp)) %>%
        arrange(pair, Timestamp)
      
      # Apply aggregation
      if (values$source_table == "fx_spot_prices") {
        showNotification(paste("Aggregating", nrow(processed_data), "records to", input$aggregationLevel, "level..."), type = "message")
        aggregated_data <- aggregate_fx_data(processed_data, input$aggregationLevel)
      } else {
        aggregated_data <- processed_data %>%
          group_by(pair) %>%
          mutate(
            returns = c(NA, diff(log(Mid))),
            returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
          ) %>%
          ungroup()
      }
      
      values$fx_data <- aggregated_data
      values$data_loaded <- TRUE
      
      # Update currency pair choices
      available_pairs <- sort(unique(aggregated_data$pair))
      updateSelectInput(session, "selectedPair", 
                        choices = available_pairs,
                        selected = available_pairs[1])
      
      output$dataStatus <- renderUI({
        div(class = "connection-success",
            h5("Data Loaded & Aggregated Successfully"),
            p(paste("Source:", values$source_table)),
            if (values$source_table == "fx_spot_prices") {
              div(
                p(paste("Raw records:", nrow(processed_data))),
                p(paste("Aggregated records:", nrow(aggregated_data))),
                p(paste("Aggregation level:", input$aggregationLevel)),
                p(paste("Compression ratio:", round(nrow(processed_data) / nrow(aggregated_data), 1), ":1"))
              )
            } else {
              p(paste("Records:", nrow(aggregated_data)))
            },
            p(paste("Date range:", min(aggregated_data$date, na.rm = TRUE), "to", max(aggregated_data$date, na.rm = TRUE))))
      })
      
      showNotification(paste("Successfully processed", nrow(aggregated_data), "aggregated records"), type = "message")
      
    }, error = function(e) {
      values$data_loaded <- FALSE
      values$fx_data <- NULL
      
      output$dataStatus <- renderUI({
        div(class = "connection-error", h5("Data Loading Failed"), p("Error:", e$message))
      })
      
      showNotification(paste("Data loading failed:", e$message), type = "error")
    })
  })
  
  # Re-aggregate when aggregation level changes
  observeEvent(input$aggregationLevel, {
    if (values$data_loaded && values$source_table == "fx_spot_prices") {
      # Re-run the data loading with new aggregation level
      isolate(input$loadData)
      # Trigger reload
      observeEvent(input$loadData, {}, once = TRUE)
    }
  })
  
  # Display executed queries
  output$executedQueries <- renderText({
    if (is.null(values$executed_queries)) {
      "No queries executed yet. Click 'Load Data' to see the SQL queries and processing steps."
    } else {
      values$executed_queries
    }
  })
  
  # Output data loaded status
  output$dataLoaded <- reactive({
    values$data_loaded
  })
  outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  
  # Filter data for selected pair
  pair_data <- reactive({
    req(values$fx_data, input$selectedPair)
    values$fx_data %>% filter(pair == input$selectedPair)
  })
  
  # Data preview
  output$dataPreview <- DT::renderDataTable({
    req(values$fx_data)
    
    preview_cols <- c("date", "Timestamp", "pair", "Mid", "Bid", "Ask", "spread_pct")
    
    # Add OHLC columns if they exist (from aggregation)
    if ("Mid_High" %in% names(values$fx_data)) {
      preview_cols <- c(preview_cols, "Mid_High", "Mid_Low", "record_count")
    }
    
    preview_data <- values$fx_data %>% 
      select(any_of(preview_cols)) %>%
      head(20)
    
    datatable(preview_data,
              options = list(scrollX = TRUE, pageLength = 20, dom = 'frtip')) %>%
      formatRound(columns = c("Mid", "Bid", "Ask"), digits = 6) %>%
      formatRound(columns = "spread_pct", digits = 4)
  })
  
  # Aggregation analysis
  output$aggregationAnalysis <- renderText({
    req(values$fx_data)
    
    if (values$source_table == "fx_spot_prices") {
      selected_data <- values$fx_data %>% filter(pair == input$selectedPair)
      
      if ("Mid_High" %in% names(selected_data)) {
        # Show OHLC statistics
        price_stats <- selected_data %>%
          summarise(
            Mid_Range = max(Mid_High, na.rm = TRUE) - min(Mid_Low, na.rm = TRUE),
            Bid_Range = max(Bid_High, na.rm = TRUE) - min(Bid_Low, na.rm = TRUE),
            Ask_Range = max(Ask_High, na.rm = TRUE) - min(Ask_Low, na.rm = TRUE),
            Avg_Records_Per_Period = mean(record_count, na.rm = TRUE),
            Total_Periods = n()
          )
        
        paste(
          paste("Aggregation Level:", input$aggregationLevel),
          paste("Total Periods:", price_stats$Total_Periods),
          paste("Avg Records/Period:", round(price_stats$Avg_Records_Per_Period, 1)),
          paste("Mid Price Range:", round(price_stats$Mid_Range, 6)),
          paste("Bid Price Range:", round(price_stats$Bid_Range, 6)),
          paste("Ask Price Range:", round(price_stats$Ask_Range, 6)),
          sep = "\n"
        )
      } else {
        # Raw data statistics
        price_stats <- selected_data %>%
          summarise(
            Mid_Range = max(Mid, na.rm = TRUE) - min(Mid, na.rm = TRUE),
            Bid_Range = max(Bid, na.rm = TRUE) - min(Bid, na.rm = TRUE),
            Ask_Range = max(Ask, na.rm = TRUE) - min(Ask, na.rm = TRUE),
            Records = n()
          )
        
        paste(
          "Raw Data (No Aggregation)",
          paste("Total Records:", price_stats$Records),
          paste("Mid Price Range:", round(price_stats$Mid_Range, 6)),
          paste("Bid Price Range:", round(price_stats$Bid_Range, 6)),
          paste("Ask Price Range:", round(price_stats$Ask_Range, 6)),
          sep = "\n"
        )
      }
    } else {
      "Daily data source - no intraday aggregation applied"
    }
  })
  
  # Data summary
  output$dataSummary <- renderText({
    req(values$fx_data)
    
    paste(
      paste("Total records:", nrow(values$fx_data)),
      paste("Currency pairs:", paste(unique(values$fx_data$pair), collapse = ", ")),
      paste("Date range:", paste(range(values$fx_data$date, na.rm = TRUE), collapse = " to ")),
      paste("Time range:", paste(range(values$fx_data$Timestamp, na.rm = TRUE), collapse = " to ")),
      sep = "\n"
    )
  })
  
  # Value boxes
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
    if (nrow(data) > 1) {
      vol <- sd(data$returns, na.rm = TRUE) * sqrt(252) * 100
    } else {
      vol <- 0
    }
    
    valueBox(
      value = paste0(format(round(vol, 3), nsmall = 3), "%"),
      subtitle = "Annualized Volatility",
      icon = icon("wave-square"),
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
  
  # Main price chart with multiple components
  output$overviewChart <- renderPlotly({
    req(pair_data())
    
    data <- pair_data()
    
    # Calculate price ranges for each component
    mid_range <- max(data$Mid, na.rm = TRUE) - min(data$Mid, na.rm = TRUE)
    bid_range <- max(data$Bid, na.rm = TRUE) - min(data$Bid, na.rm = TRUE)  
    ask_range <- max(data$Ask, na.rm = TRUE) - min(data$Ask, na.rm = TRUE)
    
    # Determine which prices to show
    selected_prices <- c()
    if ("Mid" %in% input$priceComponents) selected_prices <- c(selected_prices, data$Mid)
    if ("Bid" %in% input$priceComponents) selected_prices <- c(selected_prices, data$Bid)
    if ("Ask" %in% input$priceComponents) selected_prices <- c(selected_prices, data$Ask)
    
    # Set appropriate y-axis range
    if (length(selected_prices) > 0) {
      y_min <- min(selected_prices, na.rm = TRUE)
      y_max <- max(selected_prices, na.rm = TRUE)
      y_range <- y_max - y_min
      
      # Add buffer for better visualization
      buffer <- max(0.00001, y_range * 0.05)
      y_min <- y_min - buffer
      y_max <- y_max + buffer
    } else {
      y_min <- NULL
      y_max <- NULL
    }
    
    # Create base plot
    p <- plot_ly(data, x = ~Timestamp) %>%
      layout(
        title = paste(
          input$selectedPair, "-", 
          ifelse(values$source_table == "fx_spot_prices", paste("Aggregated:", input$aggregationLevel), "Daily"),
          "<br>Records:", nrow(data),
          "| Mid Range:", format(mid_range, scientific = FALSE, digits = 6),
          "| Bid Range:", format(bid_range, scientific = FALSE, digits = 6), 
          "| Ask Range:", format(ask_range, scientific = FALSE, digits = 6)
        ),
        xaxis = list(title = "Date/Time"),
        yaxis = list(
          title = "Exchange Rate",
          range = if (!is.null(y_min)) c(y_min, y_max) else NULL,
          tickformat = ".6f"
        ),
        hovermode = "x unified",
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        legend = list(x = 0, y = 1)
      )
    
    # Add selected price components
    if ("Mid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Mid, name = "Mid Price", 
                           line = list(color = "#2c3e50", width = 2),
                           hovertemplate = "Mid: %{y:.6f}<extra></extra>")
    }
    
    if ("Bid" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Bid, name = "Bid Price",
                           line = list(color = "#27ae60", width = 2),
                           hovertemplate = "Bid: %{y:.6f}<extra></extra>")
    }
    
    if ("Ask" %in% input$priceComponents) {
      p <- p %>% add_lines(y = ~Ask, name = "Ask Price", 
                           line = list(color = "#e74c3c", width = 2),
                           hovertemplate = "Ask: %{y:.6f}<extra></extra>")
    }
    
    # Add bid-ask spread on secondary axis if requested
    if (input$showSpread) {
      p <- p %>% 
        add_lines(y = ~spread_pct, name = "Spread %", yaxis = "y2",
                  line = list(color = "#f39c12", width = 1, dash = "dot"),
                  hovertemplate = "Spread: %{y:.4f}%<extra></extra>") %>%
        layout(yaxis2 = list(overlaying = "y", side = "right", title = "Spread %"))
    }
    
    # Add moving averages if requested and Mid is selected
    if (input$showMovingAvg && "Mid" %in% input$priceComponents) {
      if (nrow(data) > 20) {
        ma20_values <- SMA(data$Mid, n = min(20, nrow(data)-1))
        if (!all(is.na(ma20_values))) {
          p <- p %>% add_lines(y = ma20_values, name = "MA(20)", 
                               line = list(color = "#9b59b6", width = 1, dash = "dash"),
                               hovertemplate = "MA(20): %{y:.6f}<extra></extra>")
        }
      }
      
      if (nrow(data) > 50) {
        ma50_values <- SMA(data$Mid, n = min(50, nrow(data)-1))
        if (!all(is.na(ma50_values))) {
          p <- p %>% add_lines(y = ma50_values, name = "MA(50)",
                               line = list(color = "#f39c12", width = 1, dash = "dashdot"),
                               hovertemplate = "MA(50): %{y:.6f}<extra></extra>")
        }
      }
    }
    
    p
  })
  
  # Market statistics table
  output$marketStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    stats <- data %>%
      summarise(
        Current_Mid = format(round(tail(Mid, 1), 6), nsmall = 6),
        Current_Bid = format(round(tail(Bid, 1), 6), nsmall = 6),
        Current_Ask = format(round(tail(Ask, 1), 6), nsmall = 6),
        Min_Mid = format(round(min(Mid, na.rm = TRUE), 6), nsmall = 6),
        Max_Mid = format(round(max(Mid, na.rm = TRUE), 6), nsmall = 6),
        Avg_Mid = format(round(mean(Mid, na.rm = TRUE), 6), nsmall = 6),
        Price_Range = format(round(max(Mid, na.rm = TRUE) - min(Mid, na.rm = TRUE), 6), nsmall = 6),
        Avg_Spread_bps = round(mean(spread_pct, na.rm = TRUE) * 100, 2),
        Observations = n()
      ) %>%
      pivot_longer(everything(), names_to = "Metric", values_to = "Value")
    
    datatable(stats, 
              options = list(dom = 't', pageLength = 15),
              rownames = FALSE) %>%
      formatStyle(columns = "Value", textAlign = "right")
  })
  
  # Price variation analysis table
  output$variationStats <- renderDT({
    req(pair_data())
    data <- pair_data()
    
    if ("Mid_High" %in% names(data)) {
      # OHLC statistics for aggregated data
      variation_stats <- data %>%
        summarise(
          Mid_OHLC_Range = max(Mid_High, na.rm = TRUE) - min(Mid_Low, na.rm = TRUE),
          Bid_OHLC_Range = max(Bid_High, na.rm = TRUE) - min(Bid_Low, na.rm = TRUE),
          Ask_OHLC_Range = max(Ask_High, na.rm = TRUE) - min(Ask_Low, na.rm = TRUE),
          Avg_Intraperiod_Range = mean(Mid_High - Mid_Low, na.rm = TRUE),
          Max_Intraperiod_Range = max(Mid_High - Mid_Low, na.rm = TRUE),
          Total_Periods = n(),
          Avg_Records_Per_Period = mean(record_count, na.rm = TRUE)
        ) %>%
        pivot_longer(everything(), names_to = "OHLC_Metric", values_to = "Value") %>%
        mutate(Value = ifelse(grepl("Records|Periods", OHLC_Metric), 
                              format(round(Value, 0)), 
                              format(round(Value, 6), nsmall = 6)))
    } else {
      # Basic variation statistics for raw data
      variation_stats <- data %>%
        arrange(Timestamp) %>%
        mutate(
          price_change = c(0, diff(Mid)),
          abs_change = abs(price_change)
        ) %>%
        summarise(
          Total_Records = n(),
          Price_Volatility = sd(Mid, na.rm = TRUE),
          Max_Price_Jump = max(abs_change, na.rm = TRUE),
          Avg_Price_Change = mean(abs_change, na.rm = TRUE),
          Price_Trend = ifelse(tail(Mid, 1) > head(Mid, 1), "Upward", "Downward"),
          Total_Price_Movement = sum(abs_change, na.rm = TRUE)
        ) %>%
        pivot_longer(everything(), names_to = "OHLC_Metric", values_to = "Value") %>%
        mutate(Value = ifelse(grepl("Records|Trend", OHLC_Metric), 
                              as.character(Value), 
                              format(round(as.numeric(Value), 6), nsmall = 6)))
    }
    
    datatable(variation_stats, 
              options = list(dom = 't', pageLength = 15),
              rownames = FALSE) %>%
      formatStyle(columns = "Value", textAlign = "right")
  })
  
  # Clean up on session end
  session$onSessionEnded(function() {
    if (!is.null(values$connection)) {
      dbDisconnect(values$connection)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)