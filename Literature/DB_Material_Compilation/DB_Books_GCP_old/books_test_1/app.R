# Book Summary Management Dashboard with MySQL Integration

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(DBI)
library(RMySQL)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Book Summary Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Database Connection", tabName = "connection", icon = icon("database")),
      menuItem("Add Book Summary", tabName = "add_summary", icon = icon("book")),
      menuItem("Browse Summaries", tabName = "browse", icon = icon("search")),
      menuItem("View Details", tabName = "details", icon = icon("eye"))
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
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
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
        
        .box-body {
          background-color: #ffffff !important;
          color: #2c3e50 !important;
          padding: 20px;
          border-radius: 0 0 12px 12px;
        }
        
        /* Status message styling */
        .connection-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .connection-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(231, 76, 60, 0.2);
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
        
        /* Value boxes */
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
        
        /* Text areas */
        textarea.form-control {
          min-height: 100px;
        }
        
        /* DataTables */
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          color: white !important;
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
                  title = "Database Information", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 6,
                  
                  h5("Table Structure:"),
                  p("The 'book_summaries_test' table will store:"),
                  tags$ul(
                    tags$li("Book Name"),
                    tags$li("Author"),
                    tags$li("Chapter"),
                    tags$li("Section"),
                    tags$li("Main Details (text content)"),
                    tags$li("Numeric Data (for visualization)")
                  ),
                  
                  br(),
                  h5("Database Statistics:"),
                  verbatimTextOutput("dbStats")
                )
              )
      ),
      
      # Add Book Summary Tab
      tabItem(tabName = "add_summary",
              fluidRow(
                box(
                  title = "Add New Book Summary", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  
                  textInput("book_name", "Book Name:", placeholder = "Enter book title"),
                  textInput("author", "Author:", placeholder = "Enter author name"),
                  textInput("chapter", "Chapter:", placeholder = "e.g., Chapter 1 or Introduction"),
                  textInput("section", "Section:", placeholder = "e.g., Section 1.1"),
                  
                  textAreaInput("main_details", "Main Details:", 
                                placeholder = "Enter summary, key points, or main content...",
                                rows = 8),
                  
                  textInput("numeric_data", "Numeric Data (comma-separated):", 
                            placeholder = "e.g., 10,25,30,45,60,75,80"),
                  
                  p(style = "color: #7f8c8d; font-size: 12px;", 
                    "Enter numeric values separated by commas. These will be used for visualization."),
                  
                  br(),
                  
                  actionButton("submitSummary", "Submit Summary", 
                               class = "btn btn-success", width = "100%"),
                  
                  br(), br(),
                  uiOutput("submitStatus")
                ),
                
                box(
                  title = "Quick Stats", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  valueBoxOutput("totalBooks", width = 12),
                  valueBoxOutput("totalChapters", width = 12),
                  valueBoxOutput("totalSummaries", width = 12)
                )
              )
      ),
      
      # Browse Summaries Tab
      tabItem(tabName = "browse",
              fluidRow(
                box(
                  title = "All Book Summaries", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  actionButton("refreshTable", "Refresh Table", 
                               class = "btn btn-primary"),
                  
                  br(), br(),
                  
                  DT::dataTableOutput("summariesTable")
                )
              )
      ),
      
      # View Details Tab
      tabItem(tabName = "details",
              fluidRow(
                box(
                  title = "Navigation Controls", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 4,
                  
                  selectInput("filterBook", "Select Book:", choices = NULL),
                  selectInput("filterChapter", "Select Chapter:", choices = NULL),
                  selectInput("filterSection", "Select Section:", choices = NULL),
                  
                  br(),
                  actionButton("loadDetails", "Load Details", 
                               class = "btn btn-success", width = "100%"),
                  
                  br(), br(),
                  h5("Current Selection:"),
                  verbatimTextOutput("selectionInfo")
                ),
                
                box(
                  title = "Summary Details", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 8,
                  
                  h4(textOutput("detailBookName")),
                  h5(textOutput("detailAuthor")),
                  hr(),
                  
                  fluidRow(
                    column(6,
                           h5("Chapter:"),
                           verbatimTextOutput("detailChapter")
                    ),
                    column(6,
                           h5("Section:"),
                           verbatimTextOutput("detailSection")
                    )
                  ),
                  
                  hr(),
                  h5("Main Content:"),
                  div(style = "background-color: #f8f9fa; padding: 15px; border-radius: 8px; min-height: 150px;",
                      verbatimTextOutput("detailMainContent"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Numeric Data Visualization", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  plotlyOutput("numericChart", height = "400px")
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
    summaries_data = NULL,
    current_selection = NULL
  )
  
  connection_ref <- NULL
  
  # Test database connection
  observeEvent(input$testConnection, {
    if (input$password == "") {
      output$connectionStatus <- renderUI({
        div(class = "connection-error", h5("Connection Failed"), 
            p("Password is required."))
      })
      return()
    }
    
    tryCatch({
      if (!is.null(connection_ref)) {
        dbDisconnect(connection_ref)
      }
      
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
      test_result <- dbGetQuery(connection_ref, "SELECT 1 as test")
      
      if (nrow(test_result) == 1) {
        values$connected <- TRUE
        
        # Create table if it doesn't exist
        create_table_query <- "
        CREATE TABLE IF NOT EXISTS book_summaries_test (
          id INT AUTO_INCREMENT PRIMARY KEY,
          book_name VARCHAR(255) NOT NULL,
          author VARCHAR(255),
          chapter VARCHAR(100),
          section VARCHAR(100),
          main_details TEXT,
          numeric_data TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )"
        
        dbExecute(connection_ref, create_table_query)
        
        output$connectionStatus <- renderUI({
          div(class = "connection-success",
              h5("Connection Successful"),
              p(paste("Connected to", input$dbname, "on", input$host)),
              p("Table 'book_summaries_test' is ready."))
        })
        
        showNotification("Database connection established!", type = "message")
        
        # Update navigation dropdowns
        updateNavigationChoices()
      }
      
    }, error = function(e) {
      values$connected <- FALSE
      values$connection <- NULL
      connection_ref <<- NULL
      
      output$connectionStatus <- renderUI({
        div(class = "connection-error", h5("Connection Failed"), 
            p("Error:", e$message))
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
      
      output$connectionStatus <- renderUI({
        div(class = "connection-success", h5("Connections Closed"), 
            p("All database connections have been closed successfully."))
      })
      
      showNotification("All database connections closed!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error closing connections:", e$message), type = "error")
    })
  })
  
  # Database statistics
  output$dbStats <- renderText({
    if (!values$connected || is.null(connection_ref)) {
      return("No connection established")
    }
    
    tryCatch({
      count_query <- "SELECT COUNT(*) as count FROM book_summaries_test"
      result <- dbGetQuery(connection_ref, count_query)
      
      books_query <- "SELECT COUNT(DISTINCT book_name) as count FROM book_summaries_test"
      books_result <- dbGetQuery(connection_ref, books_query)
      
      paste(
        paste("Total Summaries:", result$count),
        paste("Unique Books:", books_result$count),
        paste("Table: book_summaries_test"),
        sep = "\n"
      )
      
    }, error = function(e) {
      paste("Error getting statistics:", e$message)
    })
  })
  
  # Function to update navigation choices
  updateNavigationChoices <- function() {
    if (!values$connected || is.null(connection_ref)) return()
    
    tryCatch({
      # Get unique books
      books_query <- "SELECT DISTINCT book_name FROM book_summaries_test ORDER BY book_name"
      books <- dbGetQuery(connection_ref, books_query)
      
      if (nrow(books) > 0) {
        updateSelectInput(session, "filterBook", 
                          choices = c("Select a book" = "", books$book_name))
      }
      
    }, error = function(e) {
      showNotification(paste("Error updating navigation:", e$message), type = "error")
    })
  }
  
  # Update chapters when book is selected
  observeEvent(input$filterBook, {
    if (input$filterBook == "" || !values$connected) return()
    
    tryCatch({
      chapters_query <- sprintf("
        SELECT DISTINCT chapter FROM book_summaries_test 
        WHERE book_name = '%s' 
        ORDER BY chapter", 
                                dbQuoteString(connection_ref, input$filterBook))
      
      chapters <- dbGetQuery(connection_ref, chapters_query)
      
      if (nrow(chapters) > 0) {
        updateSelectInput(session, "filterChapter", 
                          choices = c("Select a chapter" = "", chapters$chapter))
      } else {
        updateSelectInput(session, "filterChapter", choices = "No chapters available")
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading chapters:", e$message), type = "error")
    })
  })
  
  # Update sections when chapter is selected
  observeEvent(input$filterChapter, {
    if (input$filterChapter == "" || !values$connected) return()
    
    tryCatch({
      sections_query <- sprintf("
        SELECT DISTINCT section FROM book_summaries_test 
        WHERE book_name = '%s' AND chapter = '%s' 
        ORDER BY section", 
                                dbQuoteString(connection_ref, input$filterBook),
                                dbQuoteString(connection_ref, input$filterChapter))
      
      sections <- dbGetQuery(connection_ref, sections_query)
      
      if (nrow(sections) > 0) {
        updateSelectInput(session, "filterSection", 
                          choices = c("Select a section" = "", sections$section))
      } else {
        updateSelectInput(session, "filterSection", choices = "No sections available")
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading sections:", e$message), type = "error")
    })
  })
  
  # Submit new summary
  observeEvent(input$submitSummary, {
    if (!values$connected) {
      output$submitStatus <- renderUI({
        div(class = "connection-error", 
            p("Please connect to database first."))
      })
      return()
    }
    
    # Validate inputs
    if (input$book_name == "" || input$author == "") {
      output$submitStatus <- renderUI({
        div(class = "connection-error", 
            p("Book Name and Author are required fields."))
      })
      return()
    }
    
    tryCatch({
      insert_query <- sprintf("
        INSERT INTO book_summaries_test 
        (book_name, author, chapter, section, main_details, numeric_data) 
        VALUES ('%s', '%s', '%s', '%s', '%s', '%s')",
                              dbQuoteString(connection_ref, input$book_name),
                              dbQuoteString(connection_ref, input$author),
                              dbQuoteString(connection_ref, input$chapter),
                              dbQuoteString(connection_ref, input$section),
                              dbQuoteString(connection_ref, input$main_details),
                              dbQuoteString(connection_ref, input$numeric_data)
      )
      
      dbExecute(connection_ref, insert_query)
      
      output$submitStatus <- renderUI({
        div(class = "connection-success",
            h5("Success!"),
            p("Book summary has been added to the database."))
      })
      
      showNotification("Summary added successfully!", type = "message")
      
      # Clear inputs
      updateTextInput(session, "book_name", value = "")
      updateTextInput(session, "author", value = "")
      updateTextInput(session, "chapter", value = "")
      updateTextInput(session, "section", value = "")
      updateTextInput(session, "main_details", value = "")
      updateTextInput(session, "numeric_data", value = "")
      
      # Update navigation choices
      updateNavigationChoices()
      
    }, error = function(e) {
      output$submitStatus <- renderUI({
        div(class = "connection-error",
            h5("Error"),
            p(paste("Failed to add summary:", e$message)))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Value boxes for quick stats
  output$totalBooks <- renderValueBox({
    if (!values$connected || is.null(connection_ref)) {
      valueBox(
        value = "N/A",
        subtitle = "Total Unique Books",
        icon = icon("book"),
        color = "blue"
      )
    } else {
      tryCatch({
        query <- "SELECT COUNT(DISTINCT book_name) as count FROM book_summaries_test"
        result <- dbGetQuery(connection_ref, query)
        
        valueBox(
          value = result$count,
          subtitle = "Total Unique Books",
          icon = icon("book"),
          color = "blue"
        )
      }, error = function(e) {
        valueBox(
          value = "Error",
          subtitle = "Total Unique Books",
          icon = icon("exclamation-triangle"),
          color = "red"
        )
      })
    }
  })
  
  output$totalChapters <- renderValueBox({
    if (!values$connected || is.null(connection_ref)) {
      valueBox(
        value = "N/A",
        subtitle = "Total Chapters",
        icon = icon("list"),
        color = "green"
      )
    } else {
      tryCatch({
        query <- "SELECT COUNT(DISTINCT CONCAT(book_name, '-', chapter)) as count FROM book_summaries_test"
        result <- dbGetQuery(connection_ref, query)
        
        valueBox(
          value = result$count,
          subtitle = "Total Chapters",
          icon = icon("list"),
          color = "green"
        )
      }, error = function(e) {
        valueBox(
          value = "Error",
          subtitle = "Total Chapters",
          icon = icon("exclamation-triangle"),
          color = "red"
        )
      })
    }
  })
  
  output$totalSummaries <- renderValueBox({
    if (!values$connected || is.null(connection_ref)) {
      valueBox(
        value = "N/A",
        subtitle = "Total Summaries",
        icon = icon("file-alt"),
        color = "yellow"
      )
    } else {
      tryCatch({
        query <- "SELECT COUNT(*) as count FROM book_summaries_test"
        result <- dbGetQuery(connection_ref, query)
        
        valueBox(
          value = result$count,
          subtitle = "Total Summaries",
          icon = icon("file-alt"),
          color = "yellow"
        )
      }, error = function(e) {
        valueBox(
          value = "Error",
          subtitle = "Total Summaries",
          icon = icon("exclamation-triangle"),
          color = "red"
        )
      })
    }
  })
  
  # Browse summaries table
  observeEvent(input$refreshTable, {
    if (!values$connected || is.null(connection_ref)) {
      showNotification("Please connect to database first", type = "error")
      return()
    }
    
    tryCatch({
      query <- "SELECT id, book_name, author, chapter, section, 
                LEFT(main_details, 100) as preview, 
                created_at 
                FROM book_summaries_test 
                ORDER BY created_at DESC"
      
      values$summaries_data <- dbGetQuery(connection_ref, query)
      
      showNotification("Table refreshed successfully!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error loading data:", e$message), type = "error")
    })
  })
  
  # Render summaries table
  output$summariesTable <- renderDT({
    if (is.null(values$summaries_data)) {
      return(datatable(data.frame(Message = "Click 'Refresh Table' to load data")))
    }
    
    datatable(values$summaries_data,
              options = list(
                pageLength = 15,
                scrollX = TRUE,
                dom = 'Bfrtip'
              ),
              rownames = FALSE) %>%
      formatDate(columns = "created_at", method = "toLocaleString")
  })
  
  # Auto-refresh table on page load
  observe({
    if (values$connected && is.null(values$summaries_data)) {
      tryCatch({
        query <- "SELECT id, book_name, author, chapter, section, 
                  LEFT(main_details, 100) as preview, 
                  created_at 
                  FROM book_summaries_test 
                  ORDER BY created_at DESC"
        
        values$summaries_data <- dbGetQuery(connection_ref, query)
        
      }, error = function(e) {
        # Silently fail on initial load
      })
    }
  })
  
  # Load details when button clicked
  observeEvent(input$loadDetails, {
    if (!values$connected || input$filterBook == "" || 
        input$filterChapter == "" || input$filterSection == "") {
      showNotification("Please select Book, Chapter, and Section", type = "warning")
      return()
    }
    
    tryCatch({
      detail_query <- sprintf("
        SELECT * FROM book_summaries_test 
        WHERE book_name = '%s' 
        AND chapter = '%s' 
        AND section = '%s' 
        ORDER BY created_at DESC 
        LIMIT 1",
                              dbQuoteString(connection_ref, input$filterBook),
                              dbQuoteString(connection_ref, input$filterChapter),
                              dbQuoteString(connection_ref, input$filterSection)
      )
      
      result <- dbGetQuery(connection_ref, detail_query)
      
      if (nrow(result) > 0) {
        values$current_selection <- result
        showNotification("Details loaded successfully!", type = "message")
      } else {
        showNotification("No matching record found", type = "warning")
        values$current_selection <- NULL
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading details:", e$message), type = "error")
      values$current_selection <- NULL
    })
  })
  
  # Display current selection info
  output$selectionInfo <- renderText({
    if (is.null(values$current_selection)) {
      return("No selection loaded")
    }
    
    paste(
      paste("Book:", values$current_selection$book_name),
      paste("Chapter:", values$current_selection$chapter),
      paste("Section:", values$current_selection$section),
      sep = "\n"
    )
  })
  
  # Detail outputs
  output$detailBookName <- renderText({
    if (is.null(values$current_selection)) return("No book selected")
    values$current_selection$book_name
  })
  
  output$detailAuthor <- renderText({
    if (is.null(values$current_selection)) return("")
    paste("by", values$current_selection$author)
  })
  
  output$detailChapter <- renderText({
    if (is.null(values$current_selection)) return("No data")
    values$current_selection$chapter
  })
  
  output$detailSection <- renderText({
    if (is.null(values$current_selection)) return("No data")
    values$current_selection$section
  })
  
  output$detailMainContent <- renderText({
    if (is.null(values$current_selection)) return("No content loaded")
    values$current_selection$main_details
  })
  
  # Numeric chart
  output$numericChart <- renderPlotly({
    if (is.null(values$current_selection) || 
        is.na(values$current_selection$numeric_data) ||
        values$current_selection$numeric_data == "") {
      return(plot_ly() %>% 
               layout(title = "No numeric data available for visualization",
                      plot_bgcolor = "white",
                      paper_bgcolor = "white"))
    }
    
    tryCatch({
      # Parse numeric data
      numeric_values <- as.numeric(unlist(strsplit(values$current_selection$numeric_data, ",")))
      
      if (length(numeric_values) == 0 || all(is.na(numeric_values))) {
        return(plot_ly() %>% 
                 layout(title = "Invalid numeric data format",
                        plot_bgcolor = "white",
                        paper_bgcolor = "white"))
      }
      
      # Create data frame for plotting
      data_df <- data.frame(
        Index = 1:length(numeric_values),
        Value = numeric_values
      )
      
      # Create interactive plot
      p <- plot_ly(data_df, x = ~Index, y = ~Value, type = "scatter", mode = "lines+markers",
                   line = list(color = "#008A82", width = 3),
                   marker = list(color = "#00A39A", size = 10)) %>%
        layout(
          title = paste("Numeric Data Visualization -", 
                        values$current_selection$book_name,
                        "-", values$current_selection$chapter),
          xaxis = list(title = "Data Point Index"),
          yaxis = list(title = "Value"),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          hovermode = "x unified"
        )
      
      # Add bar chart overlay
      p <- p %>% add_bars(x = ~Index, y = ~Value, 
                          marker = list(color = "#3498db", opacity = 0.3),
                          name = "Values",
                          showlegend = FALSE)
      
      p
      
    }, error = function(e) {
      plot_ly() %>% 
        layout(title = paste("Error creating chart:", e$message),
               plot_bgcolor = "white",
               paper_bgcolor = "white")
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