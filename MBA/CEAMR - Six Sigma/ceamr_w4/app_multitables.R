# FX Database Loader Dashboard with SQL Query Interface
# Shiny app to load CSV files into MySQL database and run custom queries

library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(readr)
library(DBI)
library(RMySQL)
library(shinycssloaders)
library(shinyWidgets)

# Remove file upload size limits
options(shiny.maxRequestSize = -1)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "FX Database Loader"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Database Connection", tabName = "connection", icon = icon("database")),
      menuItem("Data Upload", tabName = "upload", icon = icon("upload")),
      menuItem("SQL Query Tool", tabName = "query", icon = icon("code"))
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
        .upload-success {
          background-color: #d1ecf1;
          color: #0c5460;
          padding: 15px;
          border-radius: 8px;
          border: 1px solid #bee5eb;
          margin: 10px 0;
        }
        .sidebar {
          background: linear-gradient(180deg, #2c3e50, #34495e);
        }
        .main-header .navbar {
          background: linear-gradient(135deg, #2c3e50, #34495e);
        }
        .sql-editor {
          font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
          font-size: 14px;
          line-height: 1.4;
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
                  title = "Connection Information", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h4("Database Tables"),
                  
                  h5("Table: fx_spot_prices (Intraday Data)"),
                  tags$ul(
                    tags$li("id (Primary Key)"),
                    tags$li("Timestamp (DATETIME)"),
                    tags$li("Mid, Bid, Ask (DECIMAL)"),
                    tags$li("date, time, pair (VARCHAR)")
                  ),
                  
                  h5("Table: fx_spot_prices_daily (Daily Data)"),
                  tags$ul(
                    tags$li("id (Primary Key)"),
                    tags$li("date (DATE)"),
                    tags$li("Mid, Bid, Ask (DECIMAL)"),
                    tags$li("pair (VARCHAR)"),
                    tags$li("time (VARCHAR) - Default 16:00:00"),
                    tags$li("Timestamp (DATETIME) - Generated")
                  ),
                  
                  br(),
                  
                  div(id = "tableInfo",
                      h5("Current Database Status"),
                      withSpinner(verbatimTextOutput("tableStats"))
                  )
                )
              )
      ),
      
      # Data Upload Tab
      tabItem(tabName = "upload",
              conditionalPanel(
                condition = "output.connectionValid == false",
                fluidRow(
                  box(
                    title = "Connection Required", 
                    status = "warning", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    div(class = "connection-error",
                        h4("Database Connection Required"),
                        p("Please establish a database connection in the 'Database Connection' tab before uploading data.")
                    )
                  )
                )
              ),
              
              conditionalPanel(
                condition = "output.connectionValid == true",
                fluidRow(
                  box(
                    title = "CSV File Upload", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    
                    h4("Select Target Table and CSV File"),
                    
                    selectInput("targetTable", "Target Table:",
                                choices = list(
                                  "Intraday Data (fx_spot_prices)" = "fx_spot_prices",
                                  "Daily Data (fx_spot_prices_daily)" = "fx_spot_prices_daily"
                                ),
                                selected = "fx_spot_prices"),
                    
                    div(style = "background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0;",
                        h5("File Format Requirements:"),
                        conditionalPanel(
                          condition = "input.targetTable == 'fx_spot_prices'",
                          p("Required columns: Timestamp, Mid, Bid, Ask, date, time, pair")
                        ),
                        conditionalPanel(
                          condition = "input.targetTable == 'fx_spot_prices_daily'", 
                          p("Required columns: date, Mid, Bid, Ask, pair"),
                          p("Note: time and Timestamp will be auto-generated as 16:00:00")
                        )
                    ),
                    
                    fileInput("csvFile", "Choose CSV File",
                              accept = c(".csv", ".txt"),
                              placeholder = "No file selected"),
                    
                    fluidRow(
                      column(6,
                             checkboxInput("hasHeader", "File has header row", value = TRUE)
                      ),
                      column(6,
                             radioButtons("separator", "Column Separator:",
                                          choices = c("Comma" = ",", "Semicolon" = ";", "Tab" = "\t"),
                                          selected = ",", inline = TRUE)
                      )
                    ),
                    
                    hr(),
                    
                    fluidRow(
                      column(4,
                             actionButton("previewData", "Preview Data", 
                                          class = "btn btn-info", width = "100%")
                      ),
                      column(4,
                             actionButton("uploadData", "Upload to Database", 
                                          class = "btn btn-success", width = "100%")
                      ),
                      column(4,
                             h5(textOutput("selectedTableDisplay"))
                      )
                    ),
                    
                    br(),
                    
                    uiOutput("uploadStatus")
                  ),
                  
                  box(
                    title = "Upload Settings", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 4,
                    
                    h4("Data Processing Options"),
                    
                    checkboxInput("validateData", "Validate data before upload", value = TRUE),
                    
                    checkboxInput("skipDuplicates", "Skip duplicate records", value = FALSE),
                    
                    br(),
                    
                    h5("Upload Statistics"),
                    verbatimTextOutput("uploadStats"),
                    
                    br(),
                    
                    h5("Last Upload Result"),
                    verbatimTextOutput("lastUploadResult")
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
      
      # SQL Query Tab
      tabItem(tabName = "query",
              conditionalPanel(
                condition = "output.connectionValid == false",
                fluidRow(
                  box(
                    title = "Connection Required", 
                    status = "warning", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    div(class = "connection-error",
                        h4("Database Connection Required"),
                        p("Please establish a database connection in the 'Database Connection' tab before running queries.")
                    )
                  )
                )
              ),
              
              conditionalPanel(
                condition = "output.connectionValid == true",
                fluidRow(
                  box(
                    title = "SQL Query Editor", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 12,
                    
                    h4("Execute Custom SQL Queries"),
                    
                    div(class = "sql-editor",
                        textAreaInput("sqlQuery", 
                                      label = "SQL Query:", 
                                      placeholder = "Enter your SQL query here...\n\nExample:\nSELECT * FROM fx_spot_prices WHERE pair = 'USDTHB' LIMIT 10;",
                                      width = "100%",
                                      height = "200px",
                                      value = "SELECT * FROM fx_spot_prices LIMIT 10;")),
                    
                    br(),
                    
                    fluidRow(
                      column(6,
                             actionButton("executeQuery", "Execute Query", 
                                          class = "btn btn-success", width = "100%")
                      ),
                      column(3,
                             actionButton("clearQuery", "Clear Query", 
                                          class = "btn btn-warning", width = "100%")
                      ),
                      column(3,
                             downloadButton("downloadResults", "Download Results", 
                                            class = "btn btn-info", width = "100%")
                      )
                    ),
                    
                    br(),
                    
                    uiOutput("queryStatus")
                  )
                ),
                
                fluidRow(
                  box(
                    title = "Quick Query Templates", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 4,
                    
                    h5("Common Queries"),
                    
                    actionButton("queryTemplate1", "Show All Data (fx_spot_prices)", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate2", "Show Daily Data", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate3", "Count by Currency Pair", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate4", "Latest Prices", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate5", "Compare Tables", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    br(), br(),
                    
                    h5("Query Information"),
                    verbatimTextOutput("queryInfo")
                  ),
                  
                  box(
                    title = "Query Results", 
                    status = "primary", 
                    solidHeader = TRUE, 
                    width = 8,
                    
                    withSpinner(DT::dataTableOutput("queryResults"))
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
    preview_data = NULL,
    query_results = NULL
  )
  
  # Display selected table
  output$selectedTableDisplay <- renderText({
    paste("Target:", input$targetTable)
  })
  
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
        
        # Check if tables exist and create if needed
        tryCatch({
          tables <- dbListTables(values$connection)
          
          # Create fx_spot_prices table if needed
          if (!"fx_spot_prices" %in% tables) {
            create_table_sql <- "
            CREATE TABLE fx_spot_prices (
              id INT AUTO_INCREMENT PRIMARY KEY,
              Timestamp DATETIME NOT NULL,
              Mid DECIMAL(10,6) NOT NULL,
              Bid DECIMAL(10,6) NOT NULL,
              Ask DECIMAL(10,6) NOT NULL,
              date VARCHAR(20),
              time VARCHAR(20),
              pair VARCHAR(10),
              INDEX idx_timestamp (Timestamp),
              INDEX idx_pair_timestamp (pair, Timestamp)
            )"
            dbExecute(values$connection, create_table_sql)
            showNotification("Table fx_spot_prices created successfully!", type = "message")
          }
          
          # Create fx_spot_prices_daily table if needed
          if (!"fx_spot_prices_daily" %in% tables) {
            create_daily_table_sql <- "
            CREATE TABLE fx_spot_prices_daily (
              id INT AUTO_INCREMENT PRIMARY KEY,
              date DATE NOT NULL,
              Mid DECIMAL(10,6) NOT NULL,
              Bid DECIMAL(10,6) NOT NULL,
              Ask DECIMAL(10,6) NOT NULL,
              pair VARCHAR(10) NOT NULL,
              time VARCHAR(8) DEFAULT '16:00:00',
              Timestamp DATETIME NOT NULL,
              INDEX idx_date (date),
              INDEX idx_pair_date (pair, date),
              INDEX idx_timestamp (Timestamp)
            )"
            dbExecute(values$connection, create_daily_table_sql)
            showNotification("Table fx_spot_prices_daily created successfully!", type = "message")
          }
        }, error = function(e) {
          showNotification(paste("Warning creating table:", e$message), type = "warning")
        })
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
  
  # Get table statistics
  output$tableStats <- renderText({
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
  
  # Preview uploaded data
  observeEvent(input$previewData, {
    req(input$csvFile)
    
    tryCatch({
      # Read the CSV file
      raw_data <- read_csv(input$csvFile$datapath,
                           col_names = input$hasHeader,
                           locale = locale(encoding = "UTF-8"))
      
      values$preview_data <- raw_data
      
      showNotification(paste("Preview loaded:", nrow(raw_data), "rows,", ncol(raw_data), "columns"), type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error reading CSV:", e$message), type = "error")
      values$preview_data <- NULL
    })
  })
  
  # Display data preview
  output$dataPreview <- DT::renderDataTable({
    if (is.null(values$preview_data)) {
      return(data.frame(Message = "No data to preview. Please select a CSV file and click 'Preview Data'."))
    }
    
    datatable(values$preview_data,
              options = list(
                scrollX = TRUE,
                pageLength = 10,
                dom = 'frtip'
              ),
              caption = paste("Preview of", nrow(values$preview_data), "rows"))
  })
  
  # COMPLETELY REWRITTEN UPLOAD LOGIC
  observeEvent(input$uploadData, {
    req(values$connected, input$csvFile, input$targetTable)
    
    # Store target table name immediately to avoid any reactive issues
    SELECTED_TABLE <- input$targetTable
    
    showNotification(paste("STARTING UPLOAD TO TABLE:", SELECTED_TABLE), type = "message")
    
    tryCatch({
      # Read the CSV file
      upload_data <- read_csv(input$csvFile$datapath,
                              col_names = input$hasHeader,
                              locale = locale(encoding = "UTF-8"))
      
      showNotification(paste("CSV loaded:", nrow(upload_data), "rows"), type = "message")
      
      # PROCESS DATA BASED ON SELECTED TABLE
      if (SELECTED_TABLE == "fx_spot_prices_daily") {
        
        # DAILY TABLE PROCESSING
        showNotification("Processing for DAILY table (fx_spot_prices_daily)", type = "message")
        
        # Check required columns for daily table
        required_cols <- c("date", "Mid", "Bid", "Ask", "pair")
        missing_cols <- setdiff(required_cols, names(upload_data))
        
        if (length(missing_cols) > 0) {
          showNotification(paste("Missing columns for daily table:", paste(missing_cols, collapse = ", ")), type = "error")
          return()
        }
        
        # Generate time and timestamp fields
        upload_data$time <- "16:00:00"
        upload_data$Timestamp <- as.POSIXct(paste(upload_data$date, "16:00:00"), format = "%Y-%m-%d %H:%M:%S")
        upload_data$date <- as.Date(upload_data$date)
        
        showNotification("Generated time=16:00:00 and Timestamp fields", type = "message")
        
      } else {
        
        # INTRADAY TABLE PROCESSING  
        showNotification("Processing for INTRADAY table (fx_spot_prices)", type = "message")
        
        # Check required columns for intraday table
        required_cols <- c("Timestamp", "Mid", "Bid", "Ask", "date", "time", "pair")
        missing_cols <- setdiff(required_cols, names(upload_data))
        
        if (length(missing_cols) > 0) {
          showNotification(paste("Missing columns for intraday table:", paste(missing_cols, collapse = ", ")), type = "error")
          return()
        }
        
        # Convert timestamp if needed
        if (is.character(upload_data$Timestamp)) {
          upload_data$Timestamp <- as.POSIXct(upload_data$Timestamp)
        }
      }
      
      # Remove rows with missing critical data
      initial_rows <- nrow(upload_data)
      upload_data <- upload_data[complete.cases(upload_data[c("Mid", "Bid", "Ask")]), ]
      
      if (nrow(upload_data) < initial_rows) {
        removed_rows <- initial_rows - nrow(upload_data)
        showNotification(paste("Removed", removed_rows, "rows with missing Mid/Bid/Ask values"), type = "warning")
      }
      
      if (nrow(upload_data) == 0) {
        showNotification("No valid rows to upload", type = "error")
        return()
      }
      
      # UPLOAD TO DATABASE WITH EXPLICIT TABLE SELECTION
      chunk_size <- 1000
      total_rows <- nrow(upload_data)
      
      showNotification(paste("UPLOADING", total_rows, "ROWS TO TABLE:", SELECTED_TABLE), type = "message")
      
      for (i in seq(1, total_rows, chunk_size)) {
        end_row <- min(i + chunk_size - 1, total_rows)
        chunk_data <- upload_data[i:end_row, ]
        
        # CREATE SQL INSERT STATEMENT BASED ON EXACT TABLE SELECTION
        if (SELECTED_TABLE == "fx_spot_prices_daily") {
          
          # DAILY TABLE INSERT
          values_list <- apply(chunk_data, 1, function(row) {
            date_val <- paste0("'", as.character(as.Date(row["date"])), "'")
            mid_val <- as.numeric(row["Mid"])
            bid_val <- as.numeric(row["Bid"]) 
            ask_val <- as.numeric(row["Ask"])
            pair_val <- paste0("'", row["pair"], "'")
            time_val <- "'16:00:00'"
            timestamp_val <- paste0("'", format(as.POSIXct(row["Timestamp"]), "%Y-%m-%d %H:%M:%S"), "'")
            
            paste0("(", paste(c(date_val, mid_val, bid_val, ask_val, pair_val, time_val, timestamp_val), collapse = ", "), ")")
          })
          
          sql_statement <- paste0("INSERT INTO fx_spot_prices_daily (date, Mid, Bid, Ask, pair, time, Timestamp) VALUES ", 
                                  paste(values_list, collapse = ", "))
          
        } else if (SELECTED_TABLE == "fx_spot_prices") {
          
          # INTRADAY TABLE INSERT
          values_list <- apply(chunk_data, 1, function(row) {
            # Handle timestamp with proper NA checking
            timestamp_raw <- row["Timestamp"]
            if (is.na(timestamp_raw) || timestamp_raw == "NA" || timestamp_raw == "" || is.null(timestamp_raw)) {
              timestamp_val <- "NULL"
            } else {
              tryCatch({
                timestamp_parsed <- as.POSIXct(timestamp_raw)
                if (is.na(timestamp_parsed)) {
                  timestamp_val <- "NULL"
                } else {
                  timestamp_val <- paste0("'", format(timestamp_parsed, "%Y-%m-%d %H:%M:%S"), "'")
                }
              }, error = function(e) {
                timestamp_val <- "NULL"
              })
            }
            
            # Handle other values with NA checking
            mid_val <- ifelse(is.na(row["Mid"]) || row["Mid"] == "NA", "NULL", as.numeric(row["Mid"]))
            bid_val <- ifelse(is.na(row["Bid"]) || row["Bid"] == "NA", "NULL", as.numeric(row["Bid"]))
            ask_val <- ifelse(is.na(row["Ask"]) || row["Ask"] == "NA", "NULL", as.numeric(row["Ask"]))
            date_val <- ifelse(is.na(row["date"]) || row["date"] == "NA", "NULL", paste0("'", row["date"], "'"))
            time_val <- ifelse(is.na(row["time"]) || row["time"] == "NA", "NULL", paste0("'", row["time"], "'"))
            pair_val <- ifelse(is.na(row["pair"]) || row["pair"] == "NA", "NULL", paste0("'", row["pair"], "'"))
            
            paste0("(", paste(c(timestamp_val, mid_val, bid_val, ask_val, date_val, time_val, pair_val), collapse = ", "), ")")
          })
          
          sql_statement <- paste0("INSERT INTO fx_spot_prices (Timestamp, Mid, Bid, Ask, date, time, pair) VALUES ", 
                                  paste(values_list, collapse = ", "))
          
        } else {
          showNotification("INVALID TABLE SELECTION!", type = "error")
          return()
        }
        
        # EXECUTE THE SQL STATEMENT
        showNotification(paste("Executing chunk", ceiling(i/chunk_size), "into", SELECTED_TABLE), type = "message")
        dbExecute(values$connection, sql_statement)
      }
      
      # SUCCESS MESSAGE
      output$uploadStatus <- renderUI({
        div(class = "upload-success",
            h5("Upload Successful"),
            p(paste("Successfully uploaded", nrow(upload_data), "records")),
            p(paste("Target table:", SELECTED_TABLE)))
      })
      
      output$lastUploadResult <- renderText({
        paste(
          paste("File:", input$csvFile$name),
          paste("Target table:", SELECTED_TABLE),
          paste("Rows uploaded:", nrow(upload_data)),
          paste("Upload time:", Sys.time()),
          paste("Status: SUCCESS"),
          sep = "\n"
        )
      })
      
      showNotification(paste("SUCCESS: Uploaded", nrow(upload_data), "rows to", SELECTED_TABLE), type = "message")
      
    }, error = function(e) {
      # ERROR HANDLING
      output$uploadStatus <- renderUI({
        div(class = "connection-error",
            h5("Upload Failed"),
            p("Error:", e$message),
            p("Target table:", SELECTED_TABLE))
      })
      
      output$lastUploadResult <- renderText({
        paste(
          paste("File:", input$csvFile$name),
          paste("Target table:", SELECTED_TABLE),
          paste("Upload time:", Sys.time()),
          paste("Status: FAILED"),
          paste("Error:", e$message),
          sep = "\n"
        )
      })
      
      showNotification(paste("Upload failed:", e$message), type = "error")
    })
  })
  
  # Upload statistics
  output$uploadStats <- renderText({
    if (!values$connected) return("No connection")
    
    if (!is.null(values$preview_data)) {
      paste(
        paste("Preview rows:", nrow(values$preview_data)),
        paste("Preview columns:", ncol(values$preview_data)),
        paste("Target table:", input$targetTable),
        sep = "\n"
      )
    } else if (!is.null(input$csvFile)) {
      paste("File selected:", input$csvFile$name)
    } else {
      "No file selected"
    }
  })
  
  # SQL Query Execution
  observeEvent(input$executeQuery, {
    req(values$connected, input$sqlQuery)
    
    if (trimws(input$sqlQuery) == "") {
      showNotification("Please enter a SQL query", type = "warning")
      return()
    }
    
    tryCatch({
      start_time <- Sys.time()
      values$query_results <- dbGetQuery(values$connection, input$sqlQuery)
      end_time <- Sys.time()
      
      execution_time <- round(as.numeric(end_time - start_time), 3)
      
      output$queryStatus <- renderUI({
        div(class = "upload-success",
            h5("Query Executed Successfully"),
            p(paste("Rows returned:", nrow(values$query_results))),
            p(paste("Execution time:", execution_time, "seconds")))
      })
      
      showNotification(paste("Query executed successfully! Returned", nrow(values$query_results), "rows"), type = "message")
      
    }, error = function(e) {
      values$query_results <- NULL
      
      output$queryStatus <- renderUI({
        div(class = "connection-error",
            h5("Query Failed"),
            p("Error:", e$message))
      })
      
      showNotification(paste("Query failed:", e$message), type = "error")
    })
  })
  
  # Clear query
  observeEvent(input$clearQuery, {
    updateTextAreaInput(session, "sqlQuery", value = "")
    values$query_results <- NULL
    output$queryStatus <- renderUI({})
  })
  
  # Query templates
  observeEvent(input$queryTemplate1, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT * FROM fx_spot_prices ORDER BY Timestamp DESC LIMIT 100;")
  })
  
  observeEvent(input$queryTemplate3, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT pair, COUNT(*) as count FROM fx_spot_prices GROUP BY pair UNION ALL SELECT pair, COUNT(*) as count FROM fx_spot_prices_daily GROUP BY pair ORDER BY count DESC;")
  })
  
  observeEvent(input$queryTemplate4, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT 'Intraday' as source, pair, Mid, Bid, Ask, Timestamp FROM fx_spot_prices WHERE Timestamp = (SELECT MAX(Timestamp) FROM fx_spot_prices) UNION ALL SELECT 'Daily' as source, pair, Mid, Bid, Ask, Timestamp FROM fx_spot_prices_daily WHERE date = (SELECT MAX(date) FROM fx_spot_prices_daily) ORDER BY pair;")
  })
  
  observeEvent(input$queryTemplate5, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT 'fx_spot_prices' as table_name, COUNT(*) as record_count, MIN(Timestamp) as earliest_date, MAX(Timestamp) as latest_date FROM fx_spot_prices UNION ALL SELECT 'fx_spot_prices_daily' as table_name, COUNT(*) as record_count, MIN(Timestamp) as earliest_date, MAX(Timestamp) as latest_date FROM fx_spot_prices_daily;")
  })
  
  # Display query results
  output$queryResults <- DT::renderDataTable({
    if (is.null(values$query_results)) {
      return(data.frame(Message = "No query results. Please execute a SQL query to see results here."))
    }
    
    datatable(values$query_results,
              options = list(
                scrollX = TRUE,
                pageLength = 15,
                dom = 'Bfrtip',
                buttons = c('copy', 'csv', 'excel')
              ),
              extensions = 'Buttons',
              caption = paste("Query Results:", nrow(values$query_results), "rows"))
  })
  
  # Query information
  output$queryInfo <- renderText({
    if (!values$connected) return("No connection")
    
    if (!is.null(values$query_results)) {
      paste(
        paste("Last query returned:", nrow(values$query_results), "rows"),
        paste("Columns:", ncol(values$query_results)),
        paste("Query executed at:", Sys.time()),
        sep = "\n"
      )
    } else {
      tryCatch({
        tables <- dbListTables(values$connection)
        paste(
          "Available tables:",
          paste(tables, collapse = ", "),
          "",
          "Click a template button to load a common query",
          sep = "\n"
        )
      }, error = function(e) {
        "Connection error"
      })
    }
  })
  
  # Download handler for query results
  output$downloadResults <- downloadHandler(
    filename = function() {
      paste("query_results_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      if (!is.null(values$query_results)) {
        write.csv(values$query_results, file, row.names = FALSE)
      }
    }
  )
  
  # Clean up database connection when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$connection)) {
      dbDisconnect(values$connection)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)