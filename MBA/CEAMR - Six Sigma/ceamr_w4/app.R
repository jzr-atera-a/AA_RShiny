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
options(shiny.maxRequestSize = -1)  # Remove all size limits

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
                               class = "btn btn-primary", width = "100%"),
                  
                  br(), br(),
                  
                  uiOutput("connectionStatus")
                ),
                
                box(
                  title = "Connection Information", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h4("Database Details"),
                  p("This application connects to a MySQL database with the following structure:"),
                  
                  h5("Table: fx_spot_prices"),
                  tags$ul(
                    tags$li("id (Primary Key)"),
                    tags$li("Timestamp (DATETIME)"),
                    tags$li("Mid (DECIMAL)"),
                    tags$li("Bid (DECIMAL)"),
                    tags$li("Ask (DECIMAL)"),
                    tags$li("date (VARCHAR)"),
                    tags$li("time (VARCHAR)"),
                    tags$li("pair (VARCHAR)")
                  ),
                  
                  br(),
                  
                  h5("CSV File Requirements"),
                  p("Your CSV file must contain these columns:"),
                  tags$ul(
                    tags$li("Timestamp"),
                    tags$li("Mid"),
                    tags$li("Bid"),
                    tags$li("Ask"),
                    tags$li("date"),
                    tags$li("time"),
                    tags$li("pair")
                  ),
                  
                  br(),
                  
                  div(id = "tableInfo",
                      h5("Current Table Status"),
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
                    width = 6,
                    
                    h4("Select CSV File"),
                    
                    fileInput("csvFile", "Choose CSV File",
                              accept = c(".csv", ".txt"),
                              placeholder = "No file selected"),
                    
                    br(),
                    
                    checkboxInput("hasHeader", "File has header row", value = TRUE),
                    
                    radioButtons("separator", "Column Separator:",
                                 choices = c("Comma" = ",", "Semicolon" = ";", "Tab" = "\t"),
                                 selected = ","),
                    
                    br(),
                    
                    actionButton("previewData", "Preview Data", 
                                 class = "btn btn-info", width = "48%"),
                    
                    actionButton("uploadData", "Append to Database", 
                                 class = "btn btn-success", width = "48%"),
                    
                    br(), br(),
                    
                    uiOutput("uploadStatus")
                  ),
                  
                  box(
                    title = "Upload Settings", 
                    status = "info", 
                    solidHeader = TRUE, 
                    width = 6,
                    
                    h4("Data Validation"),
                    
                    checkboxInput("validateData", "Validate data before upload", value = TRUE),
                    
                    checkboxInput("skipDuplicates", "Skip duplicate timestamps", value = FALSE),
                    
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
                    
                    actionButton("queryTemplate1", "Show All Data", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate2", "Count by Currency Pair", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate3", "Latest Prices", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate4", "Date Range Query", 
                                 class = "btn btn-outline-primary", width = "100%", style = "margin-bottom: 5px;"),
                    
                    actionButton("queryTemplate5", "Average Prices", 
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
        
        # Check if table exists and create if needed
        tryCatch({
          tables <- dbListTables(values$connection)
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
      # Check if table exists
      tables <- dbListTables(values$connection)
      if (!"fx_spot_prices" %in% tables) {
        return("Table 'fx_spot_prices' does not exist")
      }
      
      # Get table info
      row_count <- dbGetQuery(values$connection, "SELECT COUNT(*) as count FROM fx_spot_prices")
      
      if (row_count$count > 0) {
        # Get date range
        date_range <- dbGetQuery(values$connection, 
                                 "SELECT MIN(Timestamp) as min_date, MAX(Timestamp) as max_date FROM fx_spot_prices")
        
        # Get unique pairs
        pairs <- dbGetQuery(values$connection, "SELECT DISTINCT pair FROM fx_spot_prices WHERE pair IS NOT NULL")
        
        stats_text <- paste(
          paste("Total records:", format(row_count$count, big.mark = ",")),
          paste("Date range:", date_range$min_date, "to", date_range$max_date),
          paste("Currency pairs:", nrow(pairs)),
          if(nrow(pairs) > 0) paste("Pairs:", paste(pairs$pair, collapse = ", ")) else "Pairs: None",
          sep = "\n"
        )
      } else {
        stats_text <- "Table exists but no data records found"
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
      values$preview_data <- read_csv(input$csvFile$datapath,
                                      col_names = input$hasHeader,
                                      locale = locale(encoding = "UTF-8"))
      
      # Check if required columns exist
      required_cols <- c("Timestamp", "Mid", "Bid", "Ask", "date", "time", "pair")
      existing_cols <- names(values$preview_data)
      missing_cols <- setdiff(required_cols, existing_cols)
      
      if (length(missing_cols) > 0) {
        showNotification(paste("Warning: Missing columns:", paste(missing_cols, collapse = ", ")), 
                         type = "warning")
      } else {
        showNotification("Data preview loaded successfully!", type = "message")
      }
      
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
  
  # Upload data to database
  observeEvent(input$uploadData, {
    req(values$connected, input$csvFile)
    
    tryCatch({
      # Read the CSV file
      upload_data <- read_csv(input$csvFile$datapath,
                              col_names = input$hasHeader,
                              locale = locale(encoding = "UTF-8"))
      
      # Validate required columns
      required_cols <- c("Timestamp", "Mid", "Bid", "Ask", "date", "time", "pair")
      missing_cols <- setdiff(required_cols, names(upload_data))
      
      if (length(missing_cols) > 0) {
        showNotification(paste("Missing required columns:", paste(missing_cols, collapse = ", ")), 
                         type = "error")
        return()
      }
      
      # Data validation if enabled
      if (input$validateData) {
        # Check for NA values in critical columns
        critical_cols <- c("Timestamp", "Mid", "Bid", "Ask")
        na_counts <- sapply(upload_data[critical_cols], function(x) sum(is.na(x)))
        
        if (any(na_counts > 0)) {
          na_summary <- paste(names(na_counts)[na_counts > 0], ":", na_counts[na_counts > 0], collapse = ", ")
          showNotification(paste("Warning: NA values found in:", na_summary), type = "warning")
        }
        
        # Convert timestamp if needed
        if (is.character(upload_data$Timestamp)) {
          upload_data$Timestamp <- as.POSIXct(upload_data$Timestamp)
        }
      }
      
      # Remove rows with NULL values in required columns (Mid, Bid, Ask cannot be NULL)
      initial_rows <- nrow(upload_data)
      upload_data <- upload_data[!is.na(upload_data$Mid) & !is.na(upload_data$Bid) & !is.na(upload_data$Ask), ]
      
      if (nrow(upload_data) < initial_rows) {
        rows_removed <- initial_rows - nrow(upload_data)
        showNotification(paste("Removed", rows_removed, "rows with missing Mid/Bid/Ask values"), type = "warning")
      }
      
      if (nrow(upload_data) == 0) {
        showNotification("No valid rows to upload after removing rows with missing values", type = "error")
        return()
      }
      
      # Skip duplicates if enabled
      if (input$skipDuplicates) {
        existing_timestamps <- dbGetQuery(values$connection, 
                                          "SELECT DISTINCT Timestamp FROM fx_spot_prices")
        
        if (nrow(existing_timestamps) > 0) {
          existing_ts <- as.POSIXct(existing_timestamps$Timestamp)
          upload_ts <- as.POSIXct(upload_data$Timestamp)
          upload_data <- upload_data[!upload_ts %in% existing_ts, ]
          
          if (nrow(upload_data) == 0) {
            showNotification("No new records to upload (all timestamps already exist)", type = "warning")
            return()
          }
        }
      }
      
      # Upload to database using INSERT statements instead of LOAD DATA
      # Process in chunks to handle large files efficiently
      chunk_size <- 1000
      total_rows <- nrow(upload_data)
      
      for (i in seq(1, total_rows, chunk_size)) {
        end_row <- min(i + chunk_size - 1, total_rows)
        chunk_data <- upload_data[i:end_row, ]
        
        # Create INSERT statement with proper NULL handling
        values_list <- apply(chunk_data, 1, function(row) {
          # Handle NULL/NA values properly
          timestamp_val <- if(is.na(row["Timestamp"]) || row["Timestamp"] == "NA") "NULL" else paste0("'", format(as.POSIXct(row["Timestamp"]), "%Y-%m-%d %H:%M:%S"), "'")
          mid_val <- if(is.na(row["Mid"]) || row["Mid"] == "NA") "NULL" else as.numeric(row["Mid"])
          bid_val <- if(is.na(row["Bid"]) || row["Bid"] == "NA") "NULL" else as.numeric(row["Bid"])
          ask_val <- if(is.na(row["Ask"]) || row["Ask"] == "NA") "NULL" else as.numeric(row["Ask"])
          date_val <- if(is.na(row["date"]) || row["date"] == "NA") "NULL" else paste0("'", row["date"], "'")
          time_val <- if(is.na(row["time"]) || row["time"] == "NA") "NULL" else paste0("'", row["time"], "'")
          pair_val <- if(is.na(row["pair"]) || row["pair"] == "NA") "NULL" else paste0("'", row["pair"], "'")
          
          paste0("(", timestamp_val, ", ", mid_val, ", ", bid_val, ", ", ask_val, ", ", date_val, ", ", time_val, ", ", pair_val, ")")
        })
        
        insert_sql <- paste0("INSERT INTO fx_spot_prices (Timestamp, Mid, Bid, Ask, date, time, pair) VALUES ",
                             paste(values_list, collapse = ", "))
        
        dbExecute(values$connection, insert_sql)
      }
      
      # Update upload statistics
      output$lastUploadResult <- renderText({
        paste(
          paste("File:", input$csvFile$name),
          paste("Rows uploaded:", nrow(upload_data)),
          paste("Upload time:", Sys.time()),
          paste("Status: Success"),
          sep = "\n"
        )
      })
      
      output$uploadStatus <- renderUI({
        div(class = "upload-success",
            h5("Upload Successful"),
            p(paste("Successfully uploaded", nrow(upload_data), "records to the database.")))
      })
      
      showNotification(paste("Successfully uploaded", nrow(upload_data), "records!"), type = "message")
      
    }, error = function(e) {
      output$uploadStatus <- renderUI({
        div(class = "connection-error",
            h5("Upload Failed"),
            p("Error:", e$message))
      })
      
      output$lastUploadResult <- renderText({
        paste(
          paste("File:", input$csvFile$name),
          paste("Upload time:", Sys.time()),
          paste("Status: Failed"),
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
        paste("File size:", file.size(input$csvFile$datapath), "bytes"),
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
      # Execute the query
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
      
      showNotification(paste("Query executed successfully! Returned", nrow(values$query_results), "rows"), 
                       type = "message")
      
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
  
  observeEvent(input$queryTemplate2, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT pair, COUNT(*) as count FROM fx_spot_prices GROUP BY pair ORDER BY count DESC;")
  })
  
  observeEvent(input$queryTemplate3, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT pair, Mid, Bid, Ask, Timestamp FROM fx_spot_prices WHERE Timestamp = (SELECT MAX(Timestamp) FROM fx_spot_prices) ORDER BY pair;")
  })
  
  observeEvent(input$queryTemplate4, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT * FROM fx_spot_prices WHERE Timestamp >= '2024-01-01' AND Timestamp <= '2024-12-31' ORDER BY Timestamp DESC LIMIT 50;")
  })
  
  observeEvent(input$queryTemplate5, {
    updateTextAreaInput(session, "sqlQuery", 
                        value = "SELECT pair, AVG(Mid) as avg_mid, AVG(Bid) as avg_bid, AVG(Ask) as avg_ask, COUNT(*) as records FROM fx_spot_prices GROUP BY pair ORDER BY pair;")
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
      paste(
        "Available tables:",
        paste(dbListTables(values$connection), collapse = ", "),
        "",
        "Click a template button to load a common query",
        sep = "\n"
      )
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