# FX Analysis Dashboard with MySQL Integration - Data-Based Days Version
# Modified to select last N days based on actual data availability

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

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FX Analysis Dashboard - MySQL (Data-Based)"),
  
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
          border-radius: 8px 8px 8px 0 0;
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
                    title = "Data Preview & Debugging", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    fluidRow(
                      column(6,
                             h5("Top 20 Rows from Selected Table:"),
                             withSpinner(DT::dataTableOutput("dataPreview"))
                      ),
                      column(6,
                             h5("Date Processing Info:"),
                             verbatimTextOutput("dateDebugging"),
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
    if (!is.null(input$dayRange)) {
      paste("Will load last", input$dayRange, "days available in data for selected pair")
    } else {
      "Will load last 30 days available in data for selected pair"
    }
  })
  
  # Close all database connections
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
        div(class = "connection-success",
            h5("Connections Closed"),
            p("All database connections have been closed successfully."))
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
            p("Error:", e$message))
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
  
  # Load data from database with different logic for each table
  observeEvent(input$loadData, {
    req(values$connected, input$sourceTable)
    
    tryCatch({
      showNotification("Loading data from database...", type = "message")
      
      queries_executed <- c()
      
      if (input$sourceTable == "fx_spot_prices_daily") {
        # Original functionality for daily data - load all data
        main_query <- "SELECT * FROM fx_spot_prices_daily ORDER BY Timestamp, pair"
        raw_data <- dbGetQuery(values$connection, main_query)
        values$source_table <- "fx_spot_prices_daily"
        queries_executed <- c(queries_executed, paste("Main Query:", main_query))
        
      } else if (input$sourceTable == "fx_spot_prices") {
        # New functionality for intraday data - find last N days in actual data
        req(input$intradayPair, input$dayRange)
        
        # Step 1: Get the last N distinct dates available in the data for this pair
        dates_query <- paste0("
          SELECT DISTINCT DATE(Timestamp) as date_only 
          FROM fx_spot_prices 
          WHERE pair = '", input$intradayPair, "'
          ORDER BY DATE(Timestamp) DESC 
          LIMIT ", input$dayRange)
        
        last_dates <- dbGetQuery(values$connection, dates_query)
        queries_executed <- c(queries_executed, paste("Step 1 - Get Last", input$dayRange, "Dates:"), dates_query)
        
        if (nrow(last_dates) == 0) {
          output$dataStatus <- renderUI({
            div(class = "connection-error",
                h5("No Data Found"),
                p(paste("No data found for pair:", input$intradayPair)))
          })
          values$data_loaded <- FALSE
          values$executed_queries <- paste(queries_executed, collapse = "\n\n")
          return()
        }
        
        # Step 2: Get all data for those dates and the selected pair
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
                              paste("\nStep 2 - Get Data for Selected Dates:"), 
                              data_query,
                              paste("\nFound Dates:", paste(last_dates$date_only, collapse = ", ")))
        
        showNotification(paste("Loaded", nrow(raw_data), "records for", input$intradayPair, 
                               "from", nrow(last_dates), "available dates:", 
                               paste(head(last_dates$date_only, 3), collapse = ", "), 
                               if(nrow(last_dates) > 3) "..." else ""), type = "message")
      }
      
      values$executed_queries <- paste(queries_executed, collapse = "\n\n")
      
      if (nrow(raw_data) == 0) {
        output$dataStatus <- renderUI({
          div(class = "connection-error",
              h5("No Data Found"),
              p("The selected table/filter contains no data."))
        })
        values$data_loaded <- FALSE
        return()
      }
      
      # Process data using Timestamp field to extract date
      processed_data <- raw_data %>%
        mutate(
          # Extract date from Timestamp field
          date = as.Date(Timestamp),
          # Ensure numeric fields
          Mid = as.numeric(Mid),
          Bid = as.numeric(Bid),
          Ask = as.numeric(Ask),
          pair = as.character(pair),
          # Calculate derived fields
          spread = Ask - Bid,
          spread_pct = (Ask - Bid) / Mid * 100
        ) %>%
        # Remove invalid data
        filter(!is.na(Mid), !is.na(Bid), !is.na(Ask), !is.na(date), !is.na(Timestamp)) %>%
        arrange(pair, Timestamp) %>%  # Use Timestamp for proper chronological order
        # Calculate returns within each pair group
        group_by(pair) %>%
        mutate(
          returns = c(NA, diff(log(Mid))),
          returns_pct = c(NA, diff(Mid) / head(Mid, -1) * 100)
        ) %>%
        ungroup()
      
      values$fx_data <- processed_data
      values$data_loaded <- TRUE
      
      # Update currency pair choices
      available_pairs <- sort(unique(processed_data$pair))
      updateSelectInput(session, "selectedPair", 
                        choices = available_pairs,
                        selected = available_pairs[1])
      
      output$dataStatus <- renderUI({
        div(class = "connection-success",
            h5("Data Loaded Successfully"),
            p(paste("Source:", values$source_table)),
            if (values$source_table == "fx_spot_prices") {
              p(paste("Requested days:", input$dayRange, "| Available days:", 
                      length(unique(processed_data$date))))
            } else {
              NULL
            },
            p(paste("Loaded", nrow(processed_data), "records")),
            p(paste("Currency pairs:", length(available_pairs))),
            p(paste("Date range:", min(processed_data$date, na.rm = TRUE), "to", max(processed_data$date, na.rm = TRUE))))
      })
      
      showNotification(paste("Successfully loaded", nrow(processed_data), "records from", values$source_table), type = "message")
      
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
  
  # Display executed queries
  output$executedQueries <- renderText({
    if (is.null(values$executed_queries)) {
      "No queries executed yet. Click 'Load Data' to see the SQL queries."
    } else {
      values$executed_queries
    }
  })
  
  # Output data loaded status
  output$dataLoaded <- reactive({
    values$data_loaded
  })
  outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  
  # Data preview
   output$dataPreview <- DT::renderDataTable({
    req(values$fx_data)
    
    preview_data <- values$fx_data %>% 
      select(date, Timestamp, pair, Mid, Bid, Ask, spread_pct) %>%
      head(20)
    
    datatable(preview_data,
              options = list(
                scrollX = TRUE,
                pageLength = 20,
                dom = 'frtip'
              ))
  })
  
  # Date debugging information
  output$dateDebugging <- renderText({
    req(values$fx_data)
    
    sample_timestamps <- head(values$fx_data$Timestamp, 5)
    sample_dates <- head(values$fx_data$date, 5)
    timestamp_class <- class(values$fx_data$Timestamp)
    date_class <- class(values$fx_data$date)
    min_date <- min(values$fx_data$date, na.rm = TRUE)
    max_date <- max(values$fx_data$date, na.rm = TRUE)
    unique_dates <- length(unique(values$fx_data$date))
    
    paste(
      paste("Source Table:", values$source_table),
      paste("Unique dates in data:", unique_dates),
      "Timestamp column class:", paste(timestamp_class, collapse = ", "),
      "Date column class:", paste(date_class, collapse = ", "),
      paste("Sample timestamps:", paste(sample_timestamps, collapse = ", ")),
      paste("Sample dates:", paste(sample_dates, collapse = ", ")),
      paste("Min date:", min_date),
      paste("Max date:", max_date),
      paste("Any NA dates:", sum(is.na(values$fx_data$date))),
      paste("Any NA timestamps:", sum(is.na(values$fx_data$Timestamp))),
      sep = "\n"
    )
  })
  
  # Data summary
  output$dataSummary <- renderText({
    req(values$fx_data)
    
    paste(
      paste("Total rows:", nrow(values$fx_data)),
      paste("Currency pairs:", length(unique(values$fx_data$pair))),
      paste("Pairs:", paste(unique(values$fx_data$pair), collapse = ", ")),
      paste("Date range:", paste(range(values$fx_data$date, na.rm = TRUE), collapse = " to ")),
      paste("Timestamp range:", paste(range(values$fx_data$Timestamp, na.rm = TRUE), collapse = " to ")),
      sep = "\n"
    )
  })
  
  # Filter data for selected pair
  pair_data <- reactive({
    req(values$fx_data, input$selectedPair)
    values$fx_data %>% filter(pair == input$selectedPair)
  })
  
  # Value boxes
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
  
  # Alternative: Sample data by time intervals for large datasets
  output$overviewChart <- renderPlotly({
    req(pair_data())
    
    if (values$source_table == "fx_spot_prices") {
      # For intraday data, sample every nth record if dataset is large
      total_records <- nrow(pair_data())
      if (total_records > 1000) {
        sample_every <- ceiling(total_records / 1000)
        data <- pair_data()[seq(1, total_records, by = sample_every), ]
      } else {
        data <- pair_data()
      }
    } else {
      data <- pair_data() %>% slice_tail(n = 500)
    }
    
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
  
  # Market statistics
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
  
  # Clean up on session end
  session$onSessionEnded(function() {
    if (!is.null(values$connection)) {
      dbDisconnect(values$connection)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)