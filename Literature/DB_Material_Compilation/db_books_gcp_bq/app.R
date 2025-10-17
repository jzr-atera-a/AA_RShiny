# Book Summary Management Dashboard with BigQuery Integration
# Enhanced with Bulk Import functionality

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(dplyr)
library(jsonlite)
library(bigrquery)
library(stringr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Book Summary Manager - BigQuery"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("BigQuery Authentication", tabName = "auth", icon = icon("key")),
      menuItem("Bulk Import Summary", tabName = "bulk_import", icon = icon("file-import")),
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
        .status-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(0, 163, 154, 0.2);
        }
        
        .status-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(231, 76, 60, 0.2);
        }
        
        .status-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          color: #0c5460 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #17a2b8 !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(23, 162, 184, 0.2);
        }
        
        .status-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #f39c12 !important;
          margin: 10px 0;
          box-shadow: 0 4px 15px rgba(243, 156, 18, 0.2);
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
          color: white !important;
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
          color: white !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        .btn-info {
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
        }
        
        .btn-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
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
        
        .small-box.bg-aqua { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-purple { 
          background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%) !important; 
        }
        
        /* Text areas */
        textarea.form-control {
          min-height: 100px;
        }
        
        #bulk_text {
          min-height: 500px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
        }
        
        /* DataTables */
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          color: white !important;
        }
        
        /* Alert styling */
        .alert-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          border-left: 4px solid #17a2b8 !important;
          border-radius: 8px;
        }
        
        /* File input styling */
        .btn-file {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
        }
        
        /* Preview section */
        .preview-section {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
          border-left: 4px solid #008A82;
          max-height: 400px;
          overflow-y: auto;
        }
        
        # ADD to the existing CSS in tags$head section (inside the HTML() function)

        /* Detail content styling */
        #detailMainContent {
          font-family: 'Century Gothic', 'Trebuchet MS', 'Arial', sans-serif !important;
          font-size: 16px !important;
          line-height: 1.8 !important;
          color: #2c3e50 !important;
          text-align: justify !important;
          white-space: pre-wrap !important;
          word-wrap: break-word !important;
        }
        
        #detailChapter, #detailSection {
          font-family: 'Century Gothic', 'Arial', sans-serif !important;
          font-size: 14px !important;
          color: #2c3e50 !important;
          background-color: transparent !important;
          border: none !important;
          padding: 5px !important;
          margin: 0 !important;
        }
        
        #selectionInfo {
          font-family: 'Courier New', monospace !important;
          font-size: 13px !important;
          background-color: #f8f9fa !important;
          padding: 10px !important;
          border-radius: 6px !important;
          border-left: 3px solid #008A82 !important;
        }
        
        /* Detail page headings */
        #detailBookName {
          font-family: 'Century Gothic', 'Arial', sans-serif !important;
          font-size: 28px !important;
          font-weight: bold !important;
          color: #002C3C !important;
          margin-bottom: 5px !important;
        }
        
        #detailAuthor {
          font-family: 'Century Gothic', 'Arial', sans-serif !important;
          font-size: 20px !important;
          color: #008A82 !important;
          font-style: italic !important;
        }
      "))
    ),
    
    tabItems(
      # Authentication Tab
      tabItem(tabName = "auth",
              fluidRow(
                box(
                  title = "Google Cloud Platform Authentication", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("BigQuery Authentication"),
                  p("Use your service account credentials to connect to BigQuery."),
                  div(class = "alert alert-info",
                      tags$strong("Note:"), 
                      " This app clears default VM credentials to use your JSON file."),
                  
                  fluidRow(
                    column(6,
                           # Service Account JSON File
                           h5("Upload Service Account JSON File:"),
                           fileInput("json_file", 
                                     "Select JSON File:",
                                     accept = ".json",
                                     width = "100%"),
                           
                           # Manual JSON Input (alternative)
                           h5("Or paste JSON content:"),
                           textAreaInput("json_text", 
                                         "JSON Content:",
                                         height = "150px",
                                         width = "100%",
                                         placeholder = "Paste your service account JSON here...")
                    ),
                    column(6,
                           # Project ID and Dataset
                           h5("BigQuery Project Configuration"),
                           textInput("project_id", 
                                     "Project ID:",
                                     placeholder = "your-gcp-project-id",
                                     width = "100%"),
                           
                           textInput("dataset_id", 
                                     "Dataset ID:",
                                     placeholder = "your_dataset_id",
                                     value = "Wonderfulp_March",
                                     width = "100%"),
                           
                           textInput("table_id", 
                                     "Table ID:",
                                     placeholder = "table_name",
                                     value = "book_summaries_test2",
                                     width = "100%"),
                           
                           p(style = "color: #7f8c8d; font-size: 12px;", 
                             "The table will be created automatically if it doesn't exist.")
                    )
                  ),
                  
                  # Authentication Button
                  br(),
                  actionButton("authenticate", 
                               "Connect to BigQuery", 
                               class = "btn-primary btn-lg",
                               icon = icon("plug")),
                  
                  # Status Display
                  hr(),
                  h4("Connection Status"),
                  htmlOutput("auth_status"),
                  
                  # Package Info
                  hr(),
                  h5("Package Information:"),
                  verbatimTextOutput("package_info")
                )
              )
      ),
      
      # Bulk Import Tab
      tabItem(tabName = "bulk_import",
              fluidRow(
                box(
                  title = "Bulk Import Book Summary", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("Import Complete Book Summary"),
                  p("Paste a complete book summary following the format: [book_name], [author], [chapter], [section], [main_details], [numeric_data]"),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements:"),
                      tags$ul(
                        tags$li("Book name and author should appear at the top in brackets: **[Book Title]** and **[Author Name]**"),
                        tags$li("Each chapter entry should have: **[chapter]**, **[section]**, **[main_details]**, **[numeric_data]**"),
                        tags$li("Separate entries with blank lines"),
                        tags$li("Use brackets [] around field markers"),
                        tags$li("Numeric data should be comma-separated numbers")
                      )
                  ),
                  
                  textAreaInput("bulk_text", 
                                "Paste Book Summary Here:",
                                height = "500px",
                                width = "100%",
                                placeholder = "**[Book Title]**\n**[Author Name]**\n\n**[chapter]**: Chapter 1: Title\n**[section]**: All Sections\n**[main_details]**: Summary text here...\n**[numeric_data]**: 10,20,30,40\n\n**[chapter]**: Chapter 2: Title\n..."),
                  
                  fluidRow(
                    column(4,
                           actionButton("parseSummary", 
                                        "Parse Summary", 
                                        class = "btn btn-info btn-lg",
                                        icon = icon("cogs"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("submitBulk", 
                                        "Submit to BigQuery", 
                                        class = "btn btn-success btn-lg",
                                        icon = icon("cloud-upload-alt"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("clearBulk", 
                                        "Clear All", 
                                        class = "btn btn-danger",
                                        icon = icon("trash"),
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  htmlOutput("bulkStatus")
                )
              ),
              
              fluidRow(
                box(
                  title = "Parsed Data Preview", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  htmlOutput("parseInfo"),
                  br(),
                  
                  div(class = "preview-section",
                      verbatimTextOutput("parsedPreview"))
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
                  
                  textInput("book_name", "Book Name:", 
                            placeholder = "Enter book title"),
                  
                  textInput("author", "Author:", 
                            placeholder = "Enter author name"),
                  
                  textInput("chapter", "Chapter:", 
                            placeholder = "e.g., Chapter 1 or Introduction"),
                  
                  textInput("section", "Section:", 
                            placeholder = "e.g., Section 1.1"),
                  
                  textAreaInput("main_details", "Main Details:", 
                                placeholder = "Enter summary, key points, or main content...",
                                rows = 8),
                  
                  textInput("numeric_data", "Numeric Data (comma-separated):", 
                            placeholder = "e.g., 10,25,30,45,60,75,80"),
                  
                  p(style = "color: #7f8c8d; font-size: 12px;", 
                    "Enter numeric values separated by commas. These will be used for visualization."),
                  
                  br(),
                  
                  actionButton("submitSummary", "Submit Summary", 
                               class = "btn btn-success btn-lg", 
                               icon = icon("save"),
                               width = "100%"),
                  
                  br(), br(),
                  htmlOutput("submitStatus")
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
                  
                  fluidRow(
                    column(3,
                           actionButton("refreshTable", "Refresh Table", 
                                        class = "btn btn-primary",
                                        icon = icon("sync"))
                    ),
                    column(3,
                           downloadButton("downloadSummaries", "Download CSV", 
                                          class = "btn btn-info")
                    ),
                    column(6,
                           numericInput("max_browse_rows", "Max Rows to Display:", 
                                        value = 100, min = 10, max = 1000, step = 10)
                    )
                  ),
                  
                  br(),
                  htmlOutput("browseStatus"),
                  br(),
                  
                  DT::dataTableOutput("summariesTable")
                )
              )
      ),
      
      # View Details Tab - REPLACE THIS SECTION
      tabItem(tabName = "details",
              fluidRow(
                box(
                  title = "Navigation Controls", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  fluidRow(
                    column(4,
                           selectInput("filterBook", "Select Book:", 
                                       choices = NULL,
                                       width = "100%")
                    ),
                    column(4,
                           selectInput("filterChapter", "Select Chapter:", 
                                       choices = NULL,
                                       width = "100%")
                    ),
                    column(4,
                           selectInput("filterSection", "Select Section:", 
                                       choices = NULL,
                                       width = "100%")
                    )
                  ),
                  
                  br(),
                  actionButton("loadDetails", "Load Details", 
                               class = "btn btn-success btn-lg",
                               icon = icon("eye"),
                               width = "100%"),
                  
                  br(), br(),
                  h5("Current Selection:"),
                  verbatimTextOutput("selectionInfo")
                )
              ),
              
              fluidRow(
                box(
                  title = "Summary Details", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h3(textOutput("detailBookName"), style = "color: #002C3C; font-weight: bold;"),
                  h4(textOutput("detailAuthor"), style = "color: #008A82;"),
                  hr(),
                  
                  fluidRow(
                    column(6,
                           h5("Chapter:", style = "color: #008A82; font-weight: bold;"),
                           div(style = "background-color: #f8f9fa; padding: 10px; border-radius: 8px; border-left: 4px solid #008A82;",
                               verbatimTextOutput("detailChapter"))
                    ),
                    column(6,
                           h5("Section:", style = "color: #008A82; font-weight: bold;"),
                           div(style = "background-color: #f8f9fa; padding: 10px; border-radius: 8px; border-left: 4px solid #00A39A;",
                               verbatimTextOutput("detailSection"))
                    )
                  ),
                  
                  br(),
                  h4("Main Content:", style = "color: #002C3C; font-weight: bold;"),
                  div(style = "background-color: #ffffff; padding: 20px; border-radius: 8px; border: 2px solid #008A82; min-height: 400px;",
                      div(style = "font-family: 'Century Gothic', 'Arial', sans-serif; font-size: 16px; line-height: 1.8; color: #2c3e50; text-align: justify;",
                          textOutput("detailMainContent")))
                )
              ),
              
              fluidRow(
                box(
                  title = "Numeric Data Visualization", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  plotlyOutput("numericChart", height = "500px")
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
    authenticated = FALSE,
    project_id = NULL,
    dataset_id = NULL,
    table_id = NULL,
    full_table_id = NULL,
    summaries_data = NULL,
    current_selection = NULL,
    temp_file_path = NULL,
    parsed_data = NULL
  )
  
  # Display package information
  output$package_info <- renderText({
    paste0("bigrquery version: ", packageVersion("bigrquery"))
  })
  
  # Authentication
  observeEvent(input$authenticate, {
    
    tryCatch({
      # Validation
      if (is.null(input$project_id) || trimws(input$project_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Project ID")
        })
        return()
      }
      
      if (is.null(input$dataset_id) || trimws(input$dataset_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Dataset ID")
        })
        return()
      }
      
      if (is.null(input$table_id) || trimws(input$table_id) == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Table ID")
        })
        return()
      }
      
      auth_successful <- FALSE
      auth_method <- ""
      
      # Clear any existing authentication
      tryCatch({
        bq_deauth()
      }, error = function(e) {
        # Ignore errors if no auth exists
      })
      
      # Clear environment variables
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
      Sys.unsetenv("GCE_METADATA_HOST")
      
      # Method 1: JSON file upload
      if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
        
        # Validate JSON file
        json_content <- tryCatch({
          fromJSON(input$json_file$datapath)
        }, error = function(e) {
          stop("Invalid JSON file format: ", e$message)
        })
        
        # Check required fields
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        # Force authentication with this specific JSON file
        bq_auth(path = input$json_file$datapath, cache = FALSE)
        
        auth_successful <- TRUE
        auth_method <- "JSON file upload"
        
      } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
        
        # Validate JSON format
        json_content <- tryCatch({
          fromJSON(input$json_text)
        }, error = function(e) {
          stop("Invalid JSON format in text input: ", e$message)
        })
        
        # Check required fields
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        # Create temporary file
        temp_file <- tempfile(fileext = ".json")
        writeLines(input$json_text, temp_file)
        values$temp_file_path <- temp_file
        
        # Force authentication
        bq_auth(path = temp_file, cache = FALSE)
        
        auth_successful <- TRUE
        auth_method <- "manual JSON input"
        
      } else {
        stop("Please provide authentication credentials using one of the available methods")
      }
      
      if (auth_successful) {
        values$project_id <- trimws(input$project_id)
        values$dataset_id <- trimws(input$dataset_id)
        values$table_id <- trimws(input$table_id)
        values$full_table_id <- paste0(values$project_id, ".", values$dataset_id, ".", values$table_id)
        
        # Test the connection
        test_result <- tryCatch({
          datasets <- bq_project_datasets(values$project_id)
          TRUE
        }, error = function(e) {
          stop("Connection test failed: ", e$message)
        })
        
        if (test_result) {
          # Create table if it doesn't exist
          create_table_query <- sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INT64,
              book_name STRING NOT NULL,
              author STRING,
              chapter STRING,
              section STRING,
              main_details STRING,
              numeric_data STRING,
              created_at TIMESTAMP
            )", values$full_table_id)
          
          tryCatch({
            bq_project_query(values$project_id, create_table_query)
          }, error = function(e) {
            # Table might already exist, that's okay
          })
          
          values$authenticated <- TRUE
          
          output$auth_status <- renderUI({
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"), 
                     paste(" Successfully authenticated via", auth_method),
                     br(),
                     tags$small("Project ID: ", values$project_id),
                     br(),
                     tags$small("Dataset ID: ", values$dataset_id),
                     br(),
                     tags$small("Table ID: ", values$table_id),
                     br(),
                     tags$small("Full Table Path: ", values$full_table_id),
                     br(),
                     tags$small("Using bigrquery v", as.character(packageVersion("bigrquery"))))
          })
          
          showNotification("✓ BigQuery connection established!", type = "message")
          
          # Update navigation choices
          updateNavigationChoices()
        }
      }
      
    }, error = function(e) {
      values$authenticated <- FALSE
      output$auth_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Authentication failed: ", 
                 tags$br(),
                 tags$small(e$message))
      })
      showNotification(paste("Authentication failed:", e$message), type = "error")
    })
  })
  
  # Parse bulk summary - ROBUST VERSION
  observeEvent(input$parseSummary, {
    
    if (is.null(input$bulk_text) || trimws(input$bulk_text) == "") {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please paste a book summary to parse")
      })
      return()
    }
    
    output$bulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Parsing summary text...")
    })
    
    tryCatch({
      text <- input$bulk_text
      lines <- strsplit(text, "\n")[[1]]
      
      # Extract book name and author from the top
      book_name <- NULL
      author <- NULL
      
      # Look for lines starting with [ ] brackets (book name and author)
      for (i in 1:min(15, length(lines))) {
        line <- trimws(lines[i])
        
        # Check for [Book Name] pattern
        if (grepl("^\\[.*\\]$", line) && is.null(book_name)) {
          book_name <- gsub("^\\[|\\]$", "", line)
          next
        }
        
        # Check for [Author] pattern (second bracketed line)
        if (grepl("^\\[.*\\]$", line) && !is.null(book_name) && is.null(author)) {
          author <- gsub("^\\[|\\]$", "", line)
          break
        }
      }
      
      if (is.null(book_name) || is.null(author)) {
        stop("Could not find book name and author. Please ensure they are at the top in format: [Book Name] and [Author Name]")
      }
      
      # Parse entries
      entries <- list()
      current_entry <- list()
      
      for (i in 1:length(lines)) {
        line <- trimws(lines[i])
        
        # Skip empty lines and book/author declaration lines
        if (line == "" || (grepl("^\\[.*\\]$", line) && i <= 15)) {
          next
        }
        
        # Check for chapter line
        if (grepl("^\\[chapter\\]:", line)) {
          # Save previous entry if complete
          if (length(current_entry) == 4) {
            entries[[length(entries) + 1]] <- current_entry
            current_entry <- list()
          }
          
          current_entry$chapter <- trimws(sub("^\\[chapter\\]:\\s*", "", line))
        }
        
        # Check for section line
        else if (grepl("^\\[section\\]:", line)) {
          current_entry$section <- trimws(sub("^\\[section\\]:\\s*", "", line))
        }
        
        # Check for main_details line
        else if (grepl("^\\[main_details\\]:", line)) {
          current_entry$main_details <- trimws(sub("^\\[main_details\\]:\\s*", "", line))
        }
        
        # Check for numeric_data line
        else if (grepl("^\\[numeric_data\\]:", line)) {
          current_entry$numeric_data <- trimws(sub("^\\[numeric_data\\]:\\s*", "", line))
        }
      }
      
      # Add last entry if complete
      if (length(current_entry) == 4) {
        entries[[length(entries) + 1]] <- current_entry
      }
      
      if (length(entries) == 0) {
        stop("No valid entries found. Please check the format. Expected format:\n[Book Name]\n[Author]\n\n[chapter]: Chapter 1\n[section]: All Sections\n[main_details]: Summary text\n[numeric_data]: 1,2,3")
      }
      
      # Create data frame
      parsed_df <- data.frame(
        book_name = rep(book_name, length(entries)),
        author = rep(author, length(entries)),
        chapter = sapply(entries, function(x) x$chapter),
        section = sapply(entries, function(x) x$section),
        main_details = sapply(entries, function(x) x$main_details),
        numeric_data = sapply(entries, function(x) x$numeric_data),
        stringsAsFactors = FALSE
      )
      
      values$parsed_data <- parsed_df
      
      output$bulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 paste(" Successfully parsed", nrow(parsed_df), "entries!"),
                 br(),
                 tags$small("Book: ", book_name, " by ", author))
      })
      
      output$parseInfo <- renderUI({
        tags$p(
          tags$strong("Parsed Data Summary:"),
          br(),
          paste("Book:", book_name),
          br(),
          paste("Author:", author),
          br(),
          paste("Total Entries:", nrow(parsed_df)),
          br(),
          paste("Chapters:", length(unique(parsed_df$chapter)))
        )
      })
      
      output$parsedPreview <- renderText({
        preview_text <- ""
        for (i in 1:min(3, nrow(parsed_df))) {
          preview_text <- paste0(preview_text,
                                 "Entry ", i, ":\n",
                                 "  Chapter: ", parsed_df$chapter[i], "\n",
                                 "  Section: ", parsed_df$section[i], "\n",
                                 "  Details: ", substr(parsed_df$main_details[i], 1, 100), "...\n",
                                 "  Numeric Data: ", parsed_df$numeric_data[i], "\n\n")
        }
        if (nrow(parsed_df) > 3) {
          preview_text <- paste0(preview_text, "... and ", nrow(parsed_df) - 3, " more entries")
        }
        preview_text
      })
      
      showNotification(paste("✓ Parsed", nrow(parsed_df), "entries successfully!"), type = "message")
      
    }, error = function(e) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Parsing failed: ",
                 br(),
                 tags$small(e$message))
      })
      values$parsed_data <- NULL
      output$parseInfo <- renderUI(NULL)
      output$parsedPreview <- renderText("")
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Submit bulk data to BigQuery
  observeEvent(input$submitBulk, {
    
    if (!values$authenticated) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    if (is.null(values$parsed_data)) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please parse the summary first by clicking 'Parse Summary'")
      })
      return()
    }
    
    output$bulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Submitting to BigQuery... Please wait.")
    })
    
    tryCatch({
      parsed_df <- values$parsed_data
      
      # Get starting ID
      id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", 
                          values$full_table_id)
      id_job <- bq_project_query(values$project_id, id_query)
      id_result <- bq_table_download(id_job)
      next_id <- id_result$max_id[1] + 1
      
      success_count <- 0
      error_count <- 0
      
      # Insert each entry
      for (i in 1:nrow(parsed_df)) {
        tryCatch({
          # Escape single quotes
          book_name_clean <- gsub("'", "\\\\'", parsed_df$book_name[i])
          author_clean <- gsub("'", "\\\\'", parsed_df$author[i])
          chapter_clean <- gsub("'", "\\\\'", parsed_df$chapter[i])
          section_clean <- gsub("'", "\\\\'", parsed_df$section[i])
          main_details_clean <- gsub("'", "\\\\'", parsed_df$main_details[i])
          numeric_data_clean <- gsub("'", "\\\\'", parsed_df$numeric_data[i])
          
          insert_query <- sprintf("
            INSERT INTO `%s` 
            (id, book_name, author, chapter, section, main_details, numeric_data, created_at) 
            VALUES (
              %d, 
              '%s', 
              '%s', 
              '%s', 
              '%s', 
              '%s', 
              '%s', 
              CURRENT_TIMESTAMP()
            )",
                                  values$full_table_id,
                                  next_id + i - 1,
                                  book_name_clean,
                                  author_clean,
                                  chapter_clean,
                                  section_clean,
                                  main_details_clean,
                                  numeric_data_clean
          )
          
          bq_project_query(values$project_id, insert_query)
          success_count <- success_count + 1
          
        }, error = function(e) {
          error_count <- error_count + 1
        })
      }
      
      if (success_count == nrow(parsed_df)) {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   paste(" Successfully submitted all", success_count, "entries to BigQuery!"),
                   br(),
                   tags$small("Book: ", parsed_df$book_name[1], " by ", parsed_df$author[1]))
        })
        showNotification(paste("✓ All", success_count, "entries submitted successfully!"), type = "message")
      } else {
        output$bulkStatus <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   paste(" Submitted", success_count, "entries.", error_count, "failed."))
        })
        showNotification(paste("Partial success:", success_count, "of", nrow(parsed_df), "submitted"), type = "warning")
      }
      
      # Update navigation choices
      updateNavigationChoices()
      
    }, error = function(e) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Error submitting to BigQuery: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Clear bulk text
  observeEvent(input$clearBulk, {
    updateTextAreaInput(session, "bulk_text", value = "")
    values$parsed_data <- NULL
    output$bulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " Text area cleared. Ready for new input.")
    })
    output$parseInfo <- renderUI(NULL)
    output$parsedPreview <- renderText("")
  })
  
  # Function to update navigation choices
  updateNavigationChoices <- function() {
    if (!values$authenticated) return()
    
    tryCatch({
      # Get unique books
      books_query <- sprintf("
        SELECT DISTINCT book_name 
        FROM `%s` 
        ORDER BY book_name", 
                             values$full_table_id)
      
      job <- bq_project_query(values$project_id, books_query)
      books <- bq_table_download(job)
      
      if (nrow(books) > 0) {
        updateSelectInput(session, "filterBook", 
                          choices = c("Select a book" = "", books$book_name))
      }
      
    }, error = function(e) {
      # Table might be empty, that's okay
    })
  }
  
  # Update chapters when book is selected
  observeEvent(input$filterBook, {
    if (input$filterBook == "" || !values$authenticated) return()
    
    tryCatch({
      chapters_query <- sprintf("
        SELECT DISTINCT chapter 
        FROM `%s` 
        WHERE book_name = '%s' 
        ORDER BY chapter", 
                                values$full_table_id,
                                input$filterBook)
      
      job <- bq_project_query(values$project_id, chapters_query)
      chapters <- bq_table_download(job)
      
      if (nrow(chapters) > 0) {
        updateSelectInput(session, "filterChapter", 
                          choices = c("Select a chapter" = "", chapters$chapter))
      } else {
        updateSelectInput(session, "filterChapter", 
                          choices = "No chapters available")
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading chapters:", e$message), type = "error")
    })
  })
  
  # Update sections when chapter is selected
  observeEvent(input$filterChapter, {
    if (input$filterChapter == "" || !values$authenticated) return()
    
    tryCatch({
      sections_query <- sprintf("
        SELECT DISTINCT section 
        FROM `%s` 
        WHERE book_name = '%s' AND chapter = '%s' 
        ORDER BY section", 
                                values$full_table_id,
                                input$filterBook,
                                input$filterChapter)
      
      job <- bq_project_query(values$project_id, sections_query)
      sections <- bq_table_download(job)
      
      if (nrow(sections) > 0) {
        updateSelectInput(session, "filterSection", 
                          choices = c("Select a section" = "", sections$section))
      } else {
        updateSelectInput(session, "filterSection", 
                          choices = "No sections available")
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading sections:", e$message), type = "error")
    })
  })
  
  # Submit new summary (single entry)
  observeEvent(input$submitSummary, {
    if (!values$authenticated) {
      output$submitStatus <- renderUI({
        tags$div(class = "status-error", 
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    # Validate inputs
    if (input$book_name == "" || input$author == "") {
      output$submitStatus <- renderUI({
        tags$div(class = "status-error", 
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Book Name and Author are required fields.")
      })
      return()
    }
    
    # Show processing status
    output$submitStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Submitting to BigQuery... Please wait.")
    })
    
    tryCatch({
      # Generate ID
      id_query <- sprintf("SELECT COALESCE(MAX(id), 0) + 1 as next_id FROM `%s`", 
                          values$full_table_id)
      id_job <- bq_project_query(values$project_id, id_query)
      id_result <- bq_table_download(id_job)
      next_id <- id_result$next_id[1]
      
      # Escape single quotes in text fields
      book_name_clean <- gsub("'", "\\\\'", input$book_name)
      author_clean <- gsub("'", "\\\\'", input$author)
      chapter_clean <- gsub("'", "\\\\'", input$chapter)
      section_clean <- gsub("'", "\\\\'", input$section)
      main_details_clean <- gsub("'", "\\\\'", input$main_details)
      numeric_data_clean <- gsub("'", "\\\\'", input$numeric_data)
      
      # Insert query
      insert_query <- sprintf("
        INSERT INTO `%s` 
        (id, book_name, author, chapter, section, main_details, numeric_data, created_at) 
        VALUES (
          %d, 
          '%s', 
          '%s', 
          '%s', 
          '%s', 
          '%s', 
          '%s', 
          CURRENT_TIMESTAMP()
        )",
                              values$full_table_id,
                              next_id,
                              book_name_clean,
                              author_clean,
                              chapter_clean,
                              section_clean,
                              main_details_clean,
                              numeric_data_clean
      )
      
      bq_project_query(values$project_id, insert_query)
      
      output$submitStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Success! Book summary has been added to BigQuery.")
      })
      
      showNotification("✓ Summary added successfully!", type = "message")
      
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
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Error: Failed to add summary",
                 tags$br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Value boxes for quick stats
  output$totalBooks <- renderValueBox({
    if (!values$authenticated) {
      valueBox(
        value = "N/A",
        subtitle = "Total Unique Books",
        icon = icon("book"),
        color = "blue"
      )
    } else {
      tryCatch({
        query <- sprintf("SELECT COUNT(DISTINCT book_name) as count FROM `%s`", 
                         values$full_table_id)
        job <- bq_project_query(values$project_id, query)
        result <- bq_table_download(job)
        
        valueBox(
          value = result$count,
          subtitle = "Total Unique Books",
          icon = icon("book"),
          color = "blue"
        )
      }, error = function(e) {
        valueBox(
          value = 0,
          subtitle = "Total Unique Books",
          icon = icon("book"),
          color = "blue"
        )
      })
    }
  })
  
  output$totalChapters <- renderValueBox({
    if (!values$authenticated) {
      valueBox(
        value = "N/A",
        subtitle = "Total Chapters",
        icon = icon("list"),
        color = "green"
      )
    } else {
      tryCatch({
        query <- sprintf("
          SELECT COUNT(DISTINCT CONCAT(book_name, '-', chapter)) as count 
          FROM `%s`", 
                         values$full_table_id)
        job <- bq_project_query(values$project_id, query)
        result <- bq_table_download(job)
        
        valueBox(
          value = result$count,
          subtitle = "Total Chapters",
          icon = icon("list"),
          color = "green"
        )
      }, error = function(e) {
        valueBox(
          value = 0,
          subtitle = "Total Chapters",
          icon = icon("list"),
          color = "green"
        )
      })
    }
  })
  
  output$totalSummaries <- renderValueBox({
    if (!values$authenticated) {
      valueBox(
        value = "N/A",
        subtitle = "Total Summaries",
        icon = icon("file-alt"),
        color = "yellow"
      )
    } else {
      tryCatch({
        query <- sprintf("SELECT COUNT(*) as count FROM `%s`", 
                         values$full_table_id)
        job <- bq_project_query(values$project_id, query)
        result <- bq_table_download(job)
        
        valueBox(
          value = result$count,
          subtitle = "Total Summaries",
          icon = icon("file-alt"),
          color = "yellow"
        )
      }, error = function(e) {
        valueBox(
          value = 0,
          subtitle = "Total Summaries",
          icon = icon("file-alt"),
          color = "yellow"
        )
      })
    }
  })
  
  # Browse summaries table
  observeEvent(input$refreshTable, {
    if (!values$authenticated) {
      output$browseStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"), 
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    output$browseStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Loading data from BigQuery...")
    })
    
    tryCatch({
      max_rows <- if(is.null(input$max_browse_rows)) 100 else input$max_browse_rows
      
      query <- sprintf("
        SELECT 
          id, 
          book_name, 
          author, 
          chapter, 
          section, 
          SUBSTR(main_details, 1, 100) as preview,
          numeric_data,
          created_at 
        FROM `%s` 
        ORDER BY created_at DESC
        LIMIT %d", 
                       values$full_table_id,
                       max_rows)
      
      job <- bq_project_query(values$project_id, query)
      values$summaries_data <- bq_table_download(job)
      
      output$browseStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"), 
                 paste(" Loaded", nrow(values$summaries_data), "records from BigQuery"))
      })
      
      showNotification("✓ Table refreshed successfully!", type = "message")
      
    }, error = function(e) {
      output$browseStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Error loading data: ",
                 tags$br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Render summaries table
  output$summariesTable <- renderDT({
    if (is.null(values$summaries_data)) {
      return(datatable(data.frame(Message = "Click 'Refresh Table' to load data")))
    }
    
    datatable(values$summaries_data,
              options = list(
                pageLength = 25,
                scrollX = TRUE,
                scrollY = "500px",
                searching = TRUE,
                ordering = TRUE,
                lengthMenu = c(10, 25, 50, 100),
                dom = 'Bfrtip'
              ),
              class = 'cell-border stripe hover compact',
              rownames = FALSE,
              filter = 'top')
  })
  
  # Auto-refresh table on authentication
  observe({
    if (values$authenticated && is.null(values$summaries_data)) {
      tryCatch({
        query <- sprintf("
          SELECT 
            id, 
            book_name, 
            author, 
            chapter, 
            section, 
            SUBSTR(main_details, 1, 100) as preview,
            numeric_data,
            created_at 
          FROM `%s` 
          ORDER BY created_at DESC
          LIMIT 100", 
                         values$full_table_id)
        
        job <- bq_project_query(values$project_id, query)
        values$summaries_data <- bq_table_download(job)
        
      }, error = function(e) {
        # Silently fail on initial load
      })
    }
  })
  
  # Download handler
  output$downloadSummaries <- downloadHandler(
    filename = function() {
      paste0("book_summaries_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      if (!is.null(values$summaries_data)) {
        write.csv(values$summaries_data, file, row.names = FALSE)
      }
    }
  )
  
  # Load details when button clicked
  observeEvent(input$loadDetails, {
    if (!values$authenticated) {
      showNotification("Please authenticate first", type = "error")
      return()
    }
    
    if (input$filterBook == "" || input$filterChapter == "" || input$filterSection == "") {
      showNotification("Please select Book, Chapter, and Section", type = "warning")
      return()
    }
    
    tryCatch({
      # Escape single quotes
      book_clean <- gsub("'", "\\\\'", input$filterBook)
      chapter_clean <- gsub("'", "\\\\'", input$filterChapter)
      section_clean <- gsub("'", "\\\\'", input$filterSection)
      
      detail_query <- sprintf("
        SELECT * FROM `%s` 
        WHERE book_name = '%s' 
        AND chapter = '%s' 
        AND section = '%s' 
        ORDER BY created_at DESC 
        LIMIT 1",
                              values$full_table_id,
                              book_clean,
                              chapter_clean,
                              section_clean
      )
      
      job <- bq_project_query(values$project_id, detail_query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        values$current_selection <- result
        showNotification("✓ Details loaded successfully!", type = "message")
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
      paste("ID:", values$current_selection$id),
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
    if (is.null(values$current_selection)) return("No content loaded. Please select a book, chapter, and section, then click 'Load Details'.")
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
                      paper_bgcolor = "white",
                      font = list(color = "#2c3e50")))
    }
    
    tryCatch({
      # Parse numeric data
      numeric_values <- as.numeric(unlist(strsplit(values$current_selection$numeric_data, ",")))
      
      if (length(numeric_values) == 0 || all(is.na(numeric_values))) {
        return(plot_ly() %>% 
                 layout(title = "Invalid numeric data format",
                        plot_bgcolor = "white",
                        paper_bgcolor = "white",
                        font = list(color = "#2c3e50")))
      }
      
      # Create data frame for plotting
      data_df <- data.frame(
        Index = 1:length(numeric_values),
        Value = numeric_values
      )
      
      # Create interactive plot with dual visualization
      p <- plot_ly(data_df) %>%
        # Add bar chart
        add_bars(x = ~Index, y = ~Value, 
                 name = "Values",
                 marker = list(color = "#3498db", opacity = 0.6),
                 hovertemplate = "Point %{x}<br>Value: %{y}<extra></extra>") %>%
        # Add line chart overlay
        add_lines(x = ~Index, y = ~Value, 
                  name = "Trend",
                  line = list(color = "#008A82", width = 3),
                  hovertemplate = "Point %{x}<br>Value: %{y}<extra></extra>") %>%
        # Add markers
        add_markers(x = ~Index, y = ~Value, 
                    name = "Data Points",
                    marker = list(color = "#00A39A", size = 10, 
                                  line = list(color = "#002C3C", width = 2)),
                    hovertemplate = "Point %{x}<br>Value: %{y}<extra></extra>") %>%
        layout(
          title = list(
            text = paste("<b>Numeric Data Visualization</b><br>", 
                         values$current_selection$book_name,
                         "-", values$current_selection$chapter),
            font = list(color = "#002C3C", size = 16)
          ),
          xaxis = list(
            title = "Data Point Index",
            titlefont = list(color = "#2c3e50"),
            gridcolor = "#ecf0f1",
            showgrid = TRUE
          ),
          yaxis = list(
            title = "Value",
            titlefont = list(color = "#2c3e50"),
            gridcolor = "#ecf0f1",
            showgrid = TRUE
          ),
          plot_bgcolor = "white",
          paper_bgcolor = "white",
          hovermode = "x unified",
          showlegend = TRUE,
          legend = list(
            x = 0.7,
            y = 1,
            bgcolor = "rgba(255, 255, 255, 0.8)",
            bordercolor = "#008A82",
            borderwidth = 2
          )
        )
      
      # Add statistical annotations
      mean_val <- mean(numeric_values, na.rm = TRUE)
      max_val <- max(numeric_values, na.rm = TRUE)
      min_val <- min(numeric_values, na.rm = TRUE)
      
      p <- p %>% 
        add_annotations(
          x = 0.02, y = 0.98, 
          xref = "paper", yref = "paper",
          text = paste0("<b>Statistics:</b><br>",
                        "Mean: ", round(mean_val, 2), "<br>",
                        "Max: ", round(max_val, 2), "<br>",
                        "Min: ", round(min_val, 2), "<br>",
                        "Points: ", length(numeric_values)),
          showarrow = FALSE,
          xanchor = "left",
          yanchor = "top",
          align = "left",
          bgcolor = "rgba(255, 255, 255, 0.9)",
          bordercolor = "#008A82",
          borderwidth = 2,
          borderpad = 10,
          font = list(size = 11, color = "#2c3e50")
        )
      
      p
      
    }, error = function(e) {
      plot_ly() %>% 
        layout(title = paste("Error creating chart:", e$message),
               plot_bgcolor = "white",
               paper_bgcolor = "white",
               font = list(color = "#e74c3c"))
    })
  })
  
  # Clean up temporary files when session ends
  session$onSessionEnded(function() {
    if (!is.null(values$temp_file_path) && file.exists(values$temp_file_path)) {
      unlink(values$temp_file_path)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)