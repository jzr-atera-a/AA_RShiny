# Book Summary Complete Suite - Full Integration
# AI Generation + BigQuery Storage + Rich Visualization
# Updated with schema corrections and default values

library(shiny)
library(shinydashboard)
library(httr)
library(jsonlite)
library(shinyjs)
library(bigrquery)
library(DT)
library(plotly)
library(dplyr)
library(stringr)
library(tidyr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Book Summary Complete Suite"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("BigQuery Setup", tabName = "bq_auth", icon = icon("database")),
      menuItem("Claude API Config", tabName = "api_config", icon = icon("robot")),
      menuItem("Generate Summary", tabName = "generate", icon = icon("magic")),
      menuItem("Bulk Import", tabName = "bulk_import", icon = icon("file-import")),
      menuItem("Add Single Entry", tabName = "add_single", icon = icon("plus")),
      menuItem("Browse Data", tabName = "browse", icon = icon("table")),
      menuItem("Rich Visualizations", tabName = "visualize", icon = icon("chart-line")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    
    tags$head(
      tags$style(HTML("
        /* Main body background with teal gradient */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        
        /* Sidebar styling */
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
        }
        
        /* Header */
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
        }
        
        /* Box styling */
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
          margin-bottom: 20px;
          transition: transform 0.2s ease;
        }
        
        .box:hover {
          transform: translateY(-2px);
          box-shadow: 0 12px 35px rgba(0, 44, 60, 0.3) !important;
        }
        
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
        }
        
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
          font-size: 16px;
        }
        
        .box-body {
          background-color: #ffffff !important;
          padding: 20px;
        }
        
        /* Status messages */
        .status-success {
          background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
          color: #155724 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #00A39A !important;
          margin: 10px 0;
        }
        
        .status-error {
          background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
          color: #721c24 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #e74c3c !important;
          margin: 10px 0;
        }
        
        .status-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          color: #0c5460 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #17a2b8 !important;
          margin: 10px 0;
        }
        
        .status-warning {
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
          color: #856404 !important;
          padding: 15px;
          border-radius: 12px !important;
          border-left: 4px solid #f39c12 !important;
          margin: 10px 0;
        }
        
        /* Form controls */
        .form-control {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
        }
        
        /* Buttons */
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
          font-weight: 600;
          transition: transform 0.2s ease;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
          transform: translateY(-1px);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
          font-weight: 600;
        }
        
        .btn-info {
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
          border: none !important;
          border-radius: 8px !important;
          color: white !important;
          font-weight: 600;
        }
        
        .btn-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
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
        
        /* Value boxes */
        .small-box {
          border-radius: 12px !important;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15) !important;
          transition: transform 0.2s ease;
        }
        
        .small-box:hover {
          transform: translateY(-3px);
        }
        
        .small-box.bg-aqua { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        
        .small-box.bg-green { 
          background: linear-gradient(135deg, #27ae60 0%, #229954 100%) !important; 
        }
        
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        
        /* Text areas */
        textarea.form-control {
          min-height: 100px;
        }
        
        #summary_upload_text, #generated_summary {
          min-height: 500px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
        }
        
        /* Preview sections */
        .preview-section {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
          border-left: 4px solid #008A82;
          max-height: 400px;
          overflow-y: auto;
        }
        
        /* Rich visualization cards */
        .viz-card {
          background: white;
          border-radius: 12px;
          padding: 20px;
          margin: 15px 0;
          box-shadow: 0 4px 15px rgba(0, 44, 60, 0.15);
          border-left: 5px solid #008A82;
        }
        
        .viz-card h3 {
          color: #008A82;
          margin-top: 0;
          font-weight: 600;
        }
        
        .viz-card .chapter-title {
          font-size: 1.3em;
          color: #002C3C;
          font-weight: bold;
          margin-bottom: 10px;
        }
        
        .viz-card .section-tag {
          display: inline-block;
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%);
          color: white;
          padding: 5px 12px;
          border-radius: 15px;
          font-size: 0.85em;
          margin: 5px 5px 5px 0;
        }
        
        .viz-card .details-text {
          line-height: 1.8;
          color: #2c3e50;
          margin: 15px 0;
          text-align: justify;
        }
        
        .metric-box {
          display: inline-block;
          background: linear-gradient(135deg, #e8f5f4 0%, #d4edea 100%);
          padding: 10px 20px;
          border-radius: 8px;
          margin: 5px;
          border: 2px solid #00A39A;
        }
        
        .metric-label {
          font-size: 0.8em;
          color: #666;
          text-transform: uppercase;
        }
        
        .metric-value {
          font-size: 1.5em;
          font-weight: bold;
          color: #008A82;
        }
        
        .book-header {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 100%);
          color: white;
          padding: 25px;
          border-radius: 12px;
          margin-bottom: 20px;
          box-shadow: 0 6px 20px rgba(0, 44, 60, 0.3);
        }
        
        .book-header h2 {
          margin: 0 0 10px 0;
          font-size: 2em;
        }
        
        .book-header .author {
          font-size: 1.2em;
          opacity: 0.9;
        }
        
        /* Alert styling */
        .alert-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          border-left: 4px solid #17a2b8 !important;
          border-radius: 8px;
        }
        
        /* Loading spinner */
        #loading_spinner {
          color: #008A82;
        }
      "))
    ),
    
    tabItems(
      # BigQuery Setup Tab
      tabItem(
        tabName = "bq_auth",
        fluidRow(
          box(
            title = "Google Cloud Platform Authentication", 
            status = "primary", 
            solidHeader = TRUE,
            width = 12,
            
            h4("BigQuery Configuration"),
            p("Connect to your BigQuery dataset to store and retrieve book summaries."),
            div(class = "alert alert-info",
                tags$strong("Note:"), 
                " This app requires a valid Google Cloud service account with BigQuery permissions.",
                tags$br(),
                tags$strong("Default Configuration:"), " Project: atera-2, Dataset: Wonderfulp_March, Table: book_summaries_test2"),
            
            fluidRow(
              column(6,
                     h5("Upload Service Account JSON File:"),
                     fileInput("json_file", 
                               "Select JSON File:",
                               accept = ".json",
                               width = "100%"),
                     
                     h5("Or paste JSON content:"),
                     textAreaInput("json_text", 
                                   "JSON Content:",
                                   height = "150px",
                                   width = "100%",
                                   placeholder = "Paste your service account JSON here...")
              ),
              column(6,
                     h5("BigQuery Project Configuration"),
                     textInput("project_id", 
                               "Project ID:",
                               value = "atera-2",
                               width = "100%"),
                     
                     textInput("dataset_id", 
                               "Dataset ID:",
                               value = "Wonderfulp_March",
                               width = "100%"),
                     
                     textInput("table_id", 
                               "Table ID:",
                               value = "book_summaries_test2",
                               width = "100%"),
                     
                     p(style = "color: #7f8c8d; font-size: 12px;", 
                       "Table schema: id (INTEGER), book_name, author, chapter, section, main_details, numeric_data (all STRING), created_at (TIMESTAMP)")
              )
            ),
            
            br(),
            fluidRow(
              column(6,
                     actionButton("authenticate_bq", 
                                  "Connect to BigQuery", 
                                  class = "btn-primary btn-lg",
                                  icon = icon("plug"),
                                  style = "width: 100%;")
              ),
              column(6,
                     actionButton("test_bq_query", 
                                  "Test Query (Top 5 Rows)", 
                                  class = "btn-info btn-lg",
                                  icon = icon("table"),
                                  style = "width: 100%;")
              )
            ),
            
            hr(),
            h4("Connection Status"),
            htmlOutput("auth_status"),
            
            hr(),
            h4("Test Query Results"),
            htmlOutput("test_query_status"),
            DT::dataTableOutput("test_query_table")
          )
        )
      ),
      
      # Claude API Configuration Tab
      tabItem(
        tabName = "api_config",
        fluidRow(
          box(
            title = "Claude API Credentials",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            h4("Configure Claude API for Summary Generation"),
            p("Enter your Anthropic API credentials to enable AI-powered book summary generation."),
            
            fluidRow(
              column(6,
                     textInput(
                       "api_key",
                       "API Key:",
                       value = "",
                       placeholder = "sk-ant-api03-..."
                     ),
                     
                     selectInput(
                       "model",
                       "Model:",
                       choices = c(
                         "Claude Sonnet 4.5 (Recommended)" = "claude-sonnet-4-20250514",
                         "Claude Sonnet 3.5" = "claude-3-5-sonnet-20241022",
                         "Claude Opus 3" = "claude-3-opus-20240229"
                       ),
                       selected = "claude-sonnet-4-20250514"
                     ),
                     
                     numericInput(
                       "max_tokens",
                       "Max Tokens:",
                       value = 16000,
                       min = 1000,
                       max = 32000,
                       step = 1000
                     )
              ),
              column(6,
                     h5("Actions:"),
                     actionButton(
                       "test_connection",
                       "Test Connection",
                       icon = icon("plug"),
                       class = "btn-info",
                       style = "width: 100%; margin-bottom: 10px;"
                     ),
                     
                     actionButton(
                       "save_credentials",
                       "Save Credentials",
                       icon = icon("save"),
                       class = "btn-success",
                       style = "width: 100%;"
                     ),
                     
                     hr(),
                     h5("Connection Status:"),
                     htmlOutput("connection_status")
              )
            )
          )
        )
      ),
      
      # Generate Summary Tab
      tabItem(
        tabName = "generate",
        fluidRow(
          box(
            title = "Book Information",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            
            fluidRow(
              column(6,
                     textInput(
                       "book_title",
                       "Book Title:",
                       value = "",
                       placeholder = "e.g., Super Founders"
                     ),
                     
                     textInput(
                       "book_author",
                       "Author Name:",
                       value = "",
                       placeholder = "e.g., Ali Tamaseb"
                     ),
                     
                     textInput(
                       "book_genre",
                       "Genre/Category (Optional):",
                       value = "",
                       placeholder = "e.g., Business, Technology"
                     )
              ),
              column(6,
                     textAreaInput(
                       "book_topic",
                       "Topic/Description (Optional):",
                       value = "",
                       placeholder = "Brief description of what the book is about",
                       rows = 3
                     ),
                     
                     selectInput(
                       "summary_type",
                       "Summary Type:",
                       choices = c(
                         "Summary by Chapter" = "chapter",
                         "Summary by Chapter and Sections" = "chapter_sections"
                       ),
                       selected = "chapter"
                     )
              )
            ),
            
            hr(),
            
            fluidRow(
              column(3,
                     actionButton(
                       "generate_summary",
                       "Generate Summary",
                       icon = icon("magic"),
                       class = "btn-primary btn-lg",
                       style = "width: 100%;"
                     )
              ),
              column(3,
                     actionButton(
                       "copy_to_bulk",
                       "Copy to Bulk Import",
                       icon = icon("arrow-right"),
                       class = "btn-info btn-lg",
                       style = "width: 100%;"
                     )
              ),
              column(3,
                     actionButton(
                       "parse_and_upload",
                       "Parse & Upload Direct",
                       icon = icon("cloud-upload-alt"),
                       class = "btn-success btn-lg",
                       style = "width: 100%;"
                     )
              ),
              column(3,
                     downloadButton(
                       "download_summary",
                       "Download Text",
                       class = "btn-warning",
                       style = "width: 100%;"
                     )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Generated Summary",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            div(
              id = "loading_spinner",
              style = "display: none; text-align: center; padding: 20px;",
              icon("spinner", class = "fa-spin fa-3x"),
              h4("Generating summary... This may take a minute or two.")
            ),
            
            verbatimTextOutput("generated_summary"),
            
            htmlOutput("generation_status")
          )
        )
      ),
      
      # Bulk Import Tab
      tabItem(
        tabName = "bulk_import",
        fluidRow(
          box(
            title = "Bulk Import Book Summary to BigQuery", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            
            h4("Paste or Generate Book Summary"),
            p("Paste a complete book summary (or use the Generate Summary tab) to parse and upload to BigQuery."),
            
            div(class = "alert alert-info",
                tags$strong("Supported Format:"),
                tags$ul(
                  tags$li("Book title at top: [Book Title]"),
                  tags$li("Author on next line: [Author Name]"),
                  tags$li("Each entry: [chapter]: ..., [section]: ..., [main_details]: ..., [numeric_data]: ..."),
                  tags$li("Chapter format: Chapter 01: Title, Chapter 02: Title, etc. (zero-padded for 1-9)"),
                  tags$li("Handles both consolidated chapters and individual sections"),
                  tags$li("Separate entries with blank lines")
                )
            ),
            
            textAreaInput("summary_upload_text", 
                          "Paste Book Summary Here:",
                          height = "500px",
                          width = "100%",
                          placeholder = "[Book Title]\n[Author Name]\n\n[chapter]: Chapter 01: Title\n[section]: All Sections\n[main_details]: Summary...\n[numeric_data]: 10,20,30,40\n\n[chapter]: Chapter 02: Title\n..."),
            
            fluidRow(
              column(4,
                     actionButton("parse_summary", 
                                  "Parse Summary", 
                                  class = "btn btn-info btn-lg",
                                  icon = icon("cogs"),
                                  width = "100%")
              ),
              column(4,
                     actionButton("upload_to_bq", 
                                  "Upload to BigQuery", 
                                  class = "btn btn-success btn-lg",
                                  icon = icon("cloud-upload-alt"),
                                  width = "100%")
              ),
              column(4,
                     actionButton("clear_upload", 
                                  "Clear All", 
                                  class = "btn btn-danger",
                                  icon = icon("trash"),
                                  width = "100%")
              )
            ),
            
            br(),
            htmlOutput("upload_status")
          )
        ),
        
        fluidRow(
          box(
            title = "Parsed Data Preview", 
            status = "info", 
            solidHeader = TRUE, 
            width = 12,
            
            htmlOutput("parse_info"),
            br(),
            
            div(class = "preview-section",
                DT::dataTableOutput("parsed_preview_table"))
          )
        )
      ),
      
      # Add Single Entry Tab
      tabItem(
        tabName = "add_single",
        fluidRow(
          box(
            title = "Add Single Book Summary Entry", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 8,
            
            textInput("single_book_name", "Book Name:", 
                      placeholder = "Enter book title"),
            
            textInput("single_author", "Author:", 
                      placeholder = "Enter author name"),
            
            textInput("single_chapter", "Chapter:", 
                      placeholder = "e.g., Chapter 01: Introduction (use 01-09 for single digits)"),
            
            textInput("single_section", "Section:", 
                      placeholder = "e.g., Section 1.1 or All Sections"),
            
            textAreaInput("single_main_details", "Main Details:", 
                          placeholder = "Enter summary, key points, or main content...",
                          rows = 8),
            
            textInput("single_numeric_data", "Numeric Data (comma-separated):", 
                      placeholder = "e.g., 10,25,30,45,60,75"),
            
            p(style = "color: #7f8c8d; font-size: 12px;", 
              "Enter numeric values separated by commas for visualization."),
            
            br(),
            
            actionButton("submit_single", "Submit Entry", 
                         class = "btn btn-success btn-lg", 
                         icon = icon("save"),
                         width = "100%"),
            
            br(), br(),
            htmlOutput("single_submit_status")
          ),
          
          box(
            title = "Quick Statistics", 
            status = "info", 
            solidHeader = TRUE, 
            width = 4,
            
            valueBoxOutput("stat_total_books", width = 12),
            valueBoxOutput("stat_total_chapters", width = 12),
            valueBoxOutput("stat_total_entries", width = 12)
          )
        )
      ),
      
      # Browse Data Tab
      tabItem(
        tabName = "browse",
        fluidRow(
          box(
            title = "Browse All Book Summaries", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            
            fluidRow(
              column(3,
                     actionButton("refresh_table", "Refresh Data", 
                                  class = "btn btn-primary",
                                  icon = icon("sync"))
              ),
              column(3,
                     downloadButton("download_data", "Download CSV", 
                                    class = "btn btn-info")
              ),
              column(6,
                     numericInput("max_browse_rows", "Max Rows to Display:", 
                                  value = 100, min = 10, max = 1000, step = 10)
              )
            ),
            
            br(),
            htmlOutput("browse_status"),
            br(),
            
            DT::dataTableOutput("browse_table")
          )
        )
      ),
      
      # Rich Visualizations Tab
      tabItem(
        tabName = "visualize",
        fluidRow(
          box(
            title = "Rich Data Visualizations", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            
            h4("Select Book to Visualize"),
            p("Choose a book from your BigQuery database to see rich HTML visualizations with charts and insights."),
            
            fluidRow(
              column(4,
                     selectInput("viz_select_book", 
                                 "Select Book:", 
                                 choices = NULL,
                                 width = "100%")
              ),
              column(4,
                     selectInput("viz_filter_chapter", 
                                 "Filter by Chapter (Optional):", 
                                 choices = c("All Chapters" = "all"),
                                 width = "100%")
              ),
              column(4,
                     actionButton("load_visualizations", 
                                  "Load Visualizations", 
                                  class = "btn btn-success btn-lg",
                                  icon = icon("chart-bar"),
                                  width = "100%")
              )
            ),
            
            hr(),
            htmlOutput("viz_load_status")
          )
        ),
        
        fluidRow(
          box(
            title = "Book Overview", 
            status = "info", 
            solidHeader = TRUE, 
            width = 12,
            collapsible = TRUE,
            
            htmlOutput("viz_book_header"),
            
            fluidRow(
              column(3,
                     valueBoxOutput("viz_total_chapters", width = 12)
              ),
              column(3,
                     valueBoxOutput("viz_total_sections", width = 12)
              ),
              column(3,
                     valueBoxOutput("viz_avg_numeric", width = 12)
              ),
              column(3,
                     valueBoxOutput("viz_total_entries", width = 12)
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Chapter-by-Chapter Breakdown", 
            status = "success", 
            solidHeader = TRUE, 
            width = 12,
            collapsible = TRUE,
            
            htmlOutput("viz_chapters_html")
          )
        ),
        
        fluidRow(
          box(
            title = "Numeric Data Trends", 
            status = "warning", 
            solidHeader = TRUE, 
            width = 12,
            collapsible = TRUE,
            
            plotlyOutput("viz_numeric_chart", height = "500px")
          )
        ),
        
        fluidRow(
          box(
            title = "Chapter Comparison Matrix", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            collapsible = TRUE,
            
            plotlyOutput("viz_comparison_chart", height = "400px")
          )
        )
      ),
      
      # About Tab
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About This Application",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            
            h3("Book Summary Complete Suite"),
            p("An integrated platform combining AI-powered book summary generation with cloud database storage and rich data visualization."),
            
            hr(),
            
            h4("Features:"),
            tags$ul(
              tags$li(tags$strong("AI Summary Generation:"), " Use Claude AI to automatically generate structured book summaries with zero-padded chapter numbers"),
              tags$li(tags$strong("BigQuery Integration:"), " Store summaries in Google Cloud BigQuery (atera-2.Wonderfulp_March.book_summaries_test2)"),
              tags$li(tags$strong("Flexible Import:"), " Bulk import or add individual entries"),
              tags$li(tags$strong("Rich Visualizations:"), " Interactive HTML dashboards with charts powered by Plotly"),
              tags$li(tags$strong("Data Management:"), " Browse, search, filter, and export your book summary database")
            ),
            
            hr(),
            
            h4("Chapter Numbering Format:"),
            p("Chapters 1-9 are automatically formatted with leading zeros:"),
            tags$ul(
              tags$li("Chapter 01: Introduction"),
              tags$li("Chapter 02: Foundations"),
              tags$li("..."),
              tags$li("Chapter 09: Conclusions"),
              tags$li("Chapter 10: Epilogue (no leading zero for 10+)")
            ),
            
            hr(),
            
            h4("Data Schema (BigQuery):"),
            p("Table: atera-2.Wonderfulp_March.book_summaries_test2"),
            tags$pre(
              "Fields:
  - id: INTEGER (auto-generated)
  - book_name: STRING (book title)
  - author: STRING (author name)
  - chapter: STRING (chapter info)
  - section: STRING (section info)
  - main_details: STRING (summary text)
  - numeric_data: STRING (comma-separated numbers)
  - created_at: TIMESTAMP (auto-generated)"
            ),
            
            hr(),
            
            h4("Summary Format:"),
            tags$pre(
              "[Book Title]
[Author Name]

[chapter]: Chapter 01: Introduction
[section]: All Sections
[main_details]: Comprehensive summary...
[numeric_data]: 10,20,30,40,50,60

[chapter]: Chapter 02: Main Concepts
[section]: Section 2.1
[main_details]: Detailed summary...
[numeric_data]: 15,25,35,45,55,65"
            ),
            
            hr(),
            
            p("Built with ❤️ using R Shiny, Claude AI, and Google BigQuery", 
              style = "text-align: center; color: #777; font-size: 14px;"),
            p("Version 2.1.0 - Schema Corrected Edition", 
              style = "text-align: center; color: #999; font-size: 12px;")
          )
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # ========== REACTIVE VALUES ==========
  
  # Claude API credentials
  credentials <- reactiveValues(
    api_key = NULL,
    model = NULL,
    max_tokens = NULL,
    saved = FALSE
  )
  
  # Summary data
  summary_data <- reactiveValues(
    text = ""
  )
  
  # BigQuery values with defaults
  bq_values <- reactiveValues(
    authenticated = FALSE,
    project_id = "atera-2",
    dataset_id = "Wonderfulp_March",
    table_id = "book_summaries_test2",
    full_table_id = "atera-2.Wonderfulp_March.book_summaries_test2",
    temp_file_path = NULL,
    parsed_data = NULL,
    browse_data = NULL,
    viz_data = NULL
  )
  
  # ========== BIGQUERY AUTHENTICATION ==========
  
  observeEvent(input$authenticate_bq, {
    
    tryCatch({
      # Update values from inputs
      bq_values$project_id <- trimws(input$project_id)
      bq_values$dataset_id <- trimws(input$dataset_id)
      bq_values$table_id <- trimws(input$table_id)
      bq_values$full_table_id <- paste0(bq_values$project_id, ".", 
                                        bq_values$dataset_id, ".", 
                                        bq_values$table_id)
      
      # Validation
      if (bq_values$project_id == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Project ID")
        })
        return()
      }
      
      if (bq_values$dataset_id == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Dataset ID")
        })
        return()
      }
      
      if (bq_values$table_id == "") {
        output$auth_status <- renderUI({
          tags$div(class = "status-error", 
                   tags$i(class = "fa fa-times-circle"), 
                   " Error: Please provide a valid Table ID")
        })
        return()
      }
      
      auth_successful <- FALSE
      auth_method <- ""
      
      # Clear existing authentication
      tryCatch({
        bq_deauth()
      }, error = function(e) {})
      
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
      Sys.unsetenv("GCE_METADATA_HOST")
      
      # Method 1: JSON file upload
      if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
        
        json_content <- tryCatch({
          fromJSON(input$json_file$datapath)
        }, error = function(e) {
          stop("Invalid JSON file format: ", e$message)
        })
        
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        bq_auth(path = input$json_file$datapath, cache = FALSE)
        auth_successful <- TRUE
        auth_method <- "JSON file upload"
        
      } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
        
        json_content <- tryCatch({
          fromJSON(input$json_text)
        }, error = function(e) {
          stop("Invalid JSON format: ", e$message)
        })
        
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        temp_file <- tempfile(fileext = ".json")
        writeLines(input$json_text, temp_file)
        bq_values$temp_file_path <- temp_file
        
        bq_auth(path = temp_file, cache = FALSE)
        auth_successful <- TRUE
        auth_method <- "manual JSON input"
        
      } else {
        stop("Please provide authentication credentials")
      }
      
      if (auth_successful) {
        # Test connection
        test_result <- tryCatch({
          datasets <- bq_project_datasets(bq_values$project_id)
          TRUE
        }, error = function(e) {
          stop("Connection test failed: ", e$message)
        })
        
        if (test_result) {
          # Create table if it doesn't exist - CORRECTED SCHEMA
          create_table_query <- sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER,
              book_name STRING,
              author STRING,
              chapter STRING,
              section STRING,
              main_details STRING,
              numeric_data STRING,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
            )", bq_values$full_table_id)
          
          tryCatch({
            bq_project_query(bq_values$project_id, create_table_query)
          }, error = function(e) {
            # Table might exist already
          })
          
          bq_values$authenticated <- TRUE
          
          output$auth_status <- renderUI({
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"), 
                     paste(" Successfully authenticated via", auth_method),
                     tags$br(),
                     tags$small("Project: ", bq_values$project_id),
                     tags$br(),
                     tags$small("Dataset: ", bq_values$dataset_id),
                     tags$br(),
                     tags$small("Table: ", bq_values$table_id),
                     tags$br(),
                     tags$small("Full Path: ", bq_values$full_table_id))
          })
          
          showNotification("✓ BigQuery connection established!", type = "message")
          
          # Update dropdown choices for visualization
          update_viz_dropdowns()
        }
      }
      
    }, error = function(e) {
      bq_values$authenticated <- FALSE
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
  
  # ========== TEST BIGQUERY CONNECTION WITH QUERY ==========
  
  observeEvent(input$test_bq_query, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      output$test_query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Please authenticate first before testing queries")
      })
      return()
    }
    
    output$test_query_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Running test query...")
    })
    
    tryCatch({
      # Query top 5 rows from the table
      test_query <- sprintf("SELECT * FROM `%s` LIMIT 5", bq_values$full_table_id)
      
      result <- bq_project_query(bq_values$project_id, test_query)
      test_data <- bq_table_download(result)
      
      if (nrow(test_data) == 0) {
        output$test_query_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Query successful but table is empty (0 rows)")
        })
        
        output$test_query_table <- DT::renderDataTable({
          DT::datatable(
            data.frame(Message = "Table is empty - no data to display"),
            options = list(dom = 't'),
            rownames = FALSE
          )
        })
        
        showNotification("Table is empty", type = "warning", duration = 3)
      } else {
        output$test_query_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully retrieved %d rows from table", nrow(test_data)),
                   tags$br(),
                   tags$small("Table: ", bq_values$full_table_id))
        })
        
        output$test_query_table <- DT::renderDataTable({
          DT::datatable(
            test_data,
            options = list(
              pageLength = 5,
              scrollX = TRUE,
              dom = 'Bfrtip'
            ),
            rownames = FALSE
          )
        })
        
        showNotification(sprintf("✓ Retrieved %d rows successfully!", nrow(test_data)), 
                         type = "message", duration = 3)
      }
      
    }, error = function(e) {
      output$test_query_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Test query failed: ",
                 tags$br(),
                 tags$small(e$message))
      })
      
      output$test_query_table <- DT::renderDataTable({
        DT::datatable(
          data.frame(Error = e$message),
          options = list(dom = 't'),
          rownames = FALSE
        )
      })
      
      showNotification(paste("Query failed:", e$message), type = "error", duration = 5)
    })
  })
  
  # Initialize empty test query outputs
  output$test_query_status <- renderUI({ tags$div() })
  output$test_query_table <- DT::renderDataTable({ 
    DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE) 
  })
  
  # ========== CLAUDE API FUNCTIONS ==========
  
  # Test API Connection
  # Test API Connection
  observeEvent(input$test_connection, {
    req(input$api_key)
    
    output$connection_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Testing connection...")
    })
    
    tryCatch({
      response <- POST(
        url = "https://api.anthropic.com/v1/messages",
        add_headers(
          "x-api-key" = input$api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = toJSON(list(
          model = input$model,
          max_tokens = 100,
          messages = list(
            list(
              role = "user",
              content = "Hello, this is a test message. Please respond with 'Connection successful'."
            )
          )
        ), auto_unbox = TRUE),
        encode = "json",
        config = httr::config(timeout = 60)
      )
      
      if (status_code(response) == 200) {
        output$connection_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"), 
                   " Connection Successful!",
                   tags$br(),
                   tags$small("Model: ", input$model),
                   tags$br(),
                   tags$small("Status: Ready to generate summaries"))
        })
        showNotification("✓ Claude API connection successful!", type = "message")
      } else {
        error_content <- content(response, "text", encoding = "UTF-8")
        output$connection_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), 
                   " Connection Failed",
                   tags$br(),
                   tags$small("Status Code: ", status_code(response)),
                   tags$br(),
                   tags$small("Error: ", error_content))
        })
        showNotification("Connection failed. Check your API key.", type = "error")
      }
    }, error = function(e) {
      output$connection_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"), 
                 " Error: ", e$message)
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Save Credentials
  observeEvent(input$save_credentials, {
    req(input$api_key)
    
    credentials$api_key <- input$api_key
    credentials$model <- input$model
    credentials$max_tokens <- input$max_tokens
    credentials$saved <- TRUE
    
    showNotification("✓ Credentials saved successfully!", type = "message", duration = 3)
    
    output$connection_status <- renderUI({
      tags$div(class = "status-success",
               tags$i(class = "fa fa-check-circle"), 
               " Credentials Saved",
               tags$br(),
               tags$small("Model: ", input$model),
               tags$br(),
               tags$small("Max Tokens: ", input$max_tokens))
    })
  })
  
  # Generate Prompt Template with zero-padded chapter numbers
  generate_prompt <- function() {
    
    genre_text <- if (nchar(input$book_genre) > 0) {
      paste0("Genre: ", input$book_genre, "\n")
    } else {
      ""
    }
    
    topic_text <- if (nchar(input$book_topic) > 0) {
      paste0("Topic: ", input$book_topic, "\n")
    } else {
      ""
    }
    
    prompt <- paste0(
      'Generate a comprehensive summary of the book "', input$book_title, '" by ', input$book_author, ' following this EXACT format:

', genre_text, topic_text, '
Format Requirements:
1. Start with book title in brackets: [Book Title]
2. Next line, author in brackets: [Author Name]
3. Blank line
4. For each chapter entry use this EXACT pattern:
[chapter]: Chapter XX: Chapter Title
[section]: All Sections
[main_details]: Write 100-200 words summarizing the entire chapter
[numeric_data]: num1,num2,num3,num4,num5,num6

5. CRITICAL CHAPTER NUMBERING:
   - For chapters 1-9, use TWO digits with leading zero: Chapter 01, Chapter 02, ..., Chapter 09
   - For chapters 10+, use normal numbering: Chapter 10, Chapter 11, etc.
   - Examples: "Chapter 01: Introduction", "Chapter 02: Foundations", "Chapter 10: Advanced Topics"

6. Separate each chapter with ONE blank line
7. NO extra formatting, NO markdown, NO entry numbers
8. Generate realistic numeric data values (0-100 range) that could represent metrics like importance, difficulty, actionability, etc.

CRITICAL: Use the exact bracket format and chapter numbering shown above.

Example format:
[Book Title Here]
[Author Name Here]

[chapter]: Chapter 01: Introduction to the Topic
[section]: All Sections
[main_details]: This chapter introduces the fundamental concepts...
[numeric_data]: 75,82,68,90,85,78

[chapter]: Chapter 02: Building on Basics
[section]: All Sections
[main_details]: Building on the introduction, this chapter delves deeper...
[numeric_data]: 80,85,72,88,90,82

Now generate the complete summary for "', input$book_title, '" by ', input$book_author, ' with ALL chapters using the zero-padded numbering format.'
    )
    
    return(prompt)
  }
  
  # Generate Summary
  # Generate Summary
  observeEvent(input$generate_summary, {
    
    if (!credentials$saved) {
      showNotification("Please configure and save API credentials first!", type = "error", duration = 5)
      return()
    }
    
    if (nchar(input$book_title) == 0 || nchar(input$book_author) == 0) {
      showNotification("Please enter both book title and author name!", type = "error", duration = 5)
      return()
    }
    
    shinyjs::show("loading_spinner")
    output$generated_summary <- renderText({ "" })
    output$generation_status <- renderUI({ NULL })
    
    prompt <- generate_prompt()
    
    tryCatch({
      response <- POST(
        url = "https://api.anthropic.com/v1/messages",
        add_headers(
          "x-api-key" = credentials$api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = toJSON(list(
          model = credentials$model,
          max_tokens = credentials$max_tokens,
          messages = list(
            list(
              role = "user",
              content = prompt
            )
          )
        ), auto_unbox = TRUE),
        encode = "json",
        config = httr::config(timeout = 180)
      )
      
      shinyjs::hide("loading_spinner")
      
      if (status_code(response) == 200) {
        result <- content(response, "parsed")
        summary_text <- result$content[[1]]$text
        
        summary_data$text <- summary_text
        
        output$generated_summary <- renderText({
          summary_text
        })
        
        output$generation_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Summary generated successfully! Use the buttons above to copy, upload, or download.")
        })
        
        showNotification("✓ Summary generated successfully!", type = "message", duration = 3)
      } else {
        error_content <- content(response, "text", encoding = "UTF-8")
        output$generated_summary <- renderText({
          paste0("Error generating summary:\nStatus Code: ", status_code(response), 
                 "\nError Details: ", error_content)
        })
        
        output$generation_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Failed to generate summary. Check error details above.")
        })
        
        showNotification("Failed to generate summary.", type = "error", duration = 5)
      }
    }, error = function(e) {
      shinyjs::hide("loading_spinner")
      output$generated_summary <- renderText({
        paste0("Error: ", e$message)
      })
      
      output$generation_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Error: ", e$message)
      })
      
      showNotification(paste("Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Copy to Bulk Import Tab
  observeEvent(input$copy_to_bulk, {
    if (nchar(summary_data$text) > 0) {
      updateTextAreaInput(session, "summary_upload_text", value = summary_data$text)
      updateTabItems(session, "sidebarMenu", "bulk_import")
      showNotification("✓ Summary copied to Bulk Import tab!", type = "message", duration = 3)
    } else {
      showNotification("No summary to copy. Generate a summary first.", type = "warning", duration = 3)
    }
  })
  
  # Parse and Upload Direct
  observeEvent(input$parse_and_upload, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      return()
    }
    
    if (nchar(summary_data$text) == 0) {
      showNotification("No summary to upload. Generate a summary first.", type = "warning", duration = 3)
      return()
    }
    
    output$generation_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Parsing and uploading to BigQuery...")
    })
    
    tryCatch({
      # Parse the summary
      parsed_df <- parse_summary_text(summary_data$text)
      
      if (is.null(parsed_df) || nrow(parsed_df) == 0) {
        stop("Failed to parse summary")
      }
      
      # Upload to BigQuery using CORRECTED method
      upload_to_bigquery(parsed_df)
      
      output$generation_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Successfully uploaded %d entries to BigQuery!", nrow(parsed_df)))
      })
      
      showNotification(sprintf("✓ Uploaded %d entries to BigQuery!", nrow(parsed_df)), 
                       type = "message", duration = 5)
      
      # Update visualization dropdowns
      update_viz_dropdowns()
      
    }, error = function(e) {
      output$generation_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Upload failed: ", e$message)
      })
      showNotification(paste("Upload error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Download Summary
  output$download_summary <- downloadHandler(
    filename = function() {
      paste0(gsub(" ", "_", input$book_title), "_summary_", format(Sys.Date(), "%Y%m%d"), ".txt")
    },
    content = function(file) {
      writeLines(summary_data$text, file)
    }
  )
  
  # ========== PARSE SUMMARY HELPER FUNCTION ==========
  
  parse_summary_text <- function(text) {
    
    lines <- strsplit(text, "\n")[[1]]
    
    # Extract book name and author
    book_name <- NULL
    author <- NULL
    
    for (i in 1:min(10, length(lines))) {
      line <- trimws(lines[i])
      
      # Look for [Book Name] pattern
      if (grepl("^\\[.+\\]$", line) && is.null(book_name)) {
        book_name <- gsub("^\\[|\\]$", "", line)
        next
      }
      
      # Second bracketed line is author
      if (grepl("^\\[.+\\]$", line) && !is.null(book_name) && is.null(author)) {
        author <- gsub("^\\[|\\]$", "", line)
        break
      }
    }
    
    if (is.null(book_name) || is.null(author)) {
      stop("Could not find book name and author")
    }
    
    # Parse entries
    entries <- list()
    current_entry <- list()
    
    for (line in lines) {
      line <- trimws(line)
      
      # Skip empty lines, book/author lines
      if (line == "" || grepl("^\\[.+\\]$", line)) {
        # Save complete entry
        if (length(current_entry) == 4) {
          entries[[length(entries) + 1]] <- current_entry
          current_entry <- list()
        }
        next
      }
      
      # Parse chapter
      if (grepl("^\\[chapter\\]:", line, ignore.case = TRUE)) {
        chapter_text <- sub("^\\[chapter\\]:\\s*", "", line, ignore.case = TRUE)
        current_entry$chapter <- trimws(chapter_text)
      }
      
      # Parse section
      else if (grepl("^\\[section\\]:", line, ignore.case = TRUE)) {
        section_text <- sub("^\\[section\\]:\\s*", "", line, ignore.case = TRUE)
        current_entry$section <- trimws(section_text)
      }
      
      # Parse main_details
      else if (grepl("^\\[main_details\\]:", line, ignore.case = TRUE)) {
        details_text <- sub("^\\[main_details\\]:\\s*", "", line, ignore.case = TRUE)
        current_entry$main_details <- trimws(details_text)
      }
      
      # Parse numeric_data
      else if (grepl("^\\[numeric_data\\]:", line, ignore.case = TRUE)) {
        numeric_text <- sub("^\\[numeric_data\\]:\\s*", "", line, ignore.case = TRUE)
        current_entry$numeric_data <- trimws(numeric_text)
      }
    }
    
    # Add last entry if complete
    if (length(current_entry) == 4) {
      entries[[length(entries) + 1]] <- current_entry
    }
    
    if (length(entries) == 0) {
      stop("No valid entries found")
    }
    
    # Create data frame
    parsed_df <- data.frame(
      book_name = character(),
      author = character(),
      chapter = character(),
      section = character(),
      main_details = character(),
      numeric_data = character(),
      stringsAsFactors = FALSE
    )
    
    for (entry in entries) {
      parsed_df <- rbind(parsed_df, data.frame(
        book_name = book_name,
        author = author,
        chapter = entry$chapter,
        section = entry$section,
        main_details = entry$main_details,
        numeric_data = entry$numeric_data,
        stringsAsFactors = FALSE
      ))
    }
    
    return(parsed_df)
  }
  
  # ========== UPLOAD TO BIGQUERY HELPER FUNCTION (CORRECTED) ==========
  
  upload_to_bigquery <- function(df) {
    # Get max ID from table to continue sequence
    max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", 
                            bq_values$full_table_id)
    
    tryCatch({
      result <- bq_project_query(bq_values$project_id, max_id_query)
      max_id_data <- bq_table_download(result)
      start_id <- as.integer(max_id_data$max_id) + 1
    }, error = function(e) {
      # If table is empty or doesn't exist, start from 1
      start_id <- 1
    })
    
    # Add id as INTEGER and created_at as TIMESTAMP
    df$id <- seq(start_id, start_id + nrow(df) - 1)
    df$created_at <- Sys.time()
    
    # Reorder columns to match schema
    df <- df[, c("id", "book_name", "author", "chapter", "section", 
                 "main_details", "numeric_data", "created_at")]
    
    # Get table reference
    bq_table_ref <- bq_table(bq_values$project_id, bq_values$dataset_id, bq_values$table_id)
    
    # Upload WITHOUT specifying fields (let bigrquery infer from data frame)
    bq_table_upload(bq_table_ref, df, create_disposition = "CREATE_IF_NEEDED", 
                    write_disposition = "WRITE_APPEND")
  }
  
  # ========== BULK IMPORT TAB ==========
  
  # Parse Summary
  observeEvent(input$parse_summary, {
    
    if (is.null(input$summary_upload_text) || trimws(input$summary_upload_text) == "") {
      output$upload_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please paste a book summary to parse")
      })
      return()
    }
    
    output$upload_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Parsing summary text...")
    })
    
    tryCatch({
      parsed_df <- parse_summary_text(input$summary_upload_text)
      
      bq_values$parsed_data <- parsed_df
      
      output$parse_info <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Successfully parsed %d entries from '%s' by %s", 
                         nrow(parsed_df), parsed_df$book_name[1], parsed_df$author[1]))
      })
      
      output$parsed_preview_table <- DT::renderDataTable({
        DT::datatable(
          parsed_df,
          options = list(
            pageLength = 10,
            scrollX = TRUE,
            dom = 'Bfrtip'
          ),
          rownames = FALSE
        )
      })
      
      output$upload_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Parsed %d entries successfully. Ready to upload!", nrow(parsed_df)))
      })
      
      showNotification(sprintf("✓ Parsed %d entries successfully!", nrow(parsed_df)), 
                       type = "message", duration = 3)
      
    }, error = function(e) {
      output$upload_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Parsing failed: ",
                 tags$br(),
                 tags$small(e$message))
      })
      showNotification(paste("Parsing error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Upload to BigQuery
  observeEvent(input$upload_to_bq, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      return()
    }
    
    if (is.null(bq_values$parsed_data) || nrow(bq_values$parsed_data) == 0) {
      showNotification("Please parse the summary first!", type = "error", duration = 5)
      return()
    }
    
    output$upload_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Uploading to BigQuery...")
    })
    
    tryCatch({
      upload_to_bigquery(bq_values$parsed_data)
      
      output$upload_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Successfully uploaded %d rows to BigQuery!", nrow(bq_values$parsed_data)),
                 tags$br(),
                 tags$small("Table: ", bq_values$full_table_id))
      })
      
      showNotification(sprintf("✓ Uploaded %d rows to BigQuery!", nrow(bq_values$parsed_data)), 
                       type = "message", duration = 5)
      
      # Update visualization dropdowns
      update_viz_dropdowns()
      
    }, error = function(e) {
      output$upload_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Upload failed: ",
                 tags$br(),
                 tags$small(e$message))
      })
      showNotification(paste("Upload error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Clear Upload
  observeEvent(input$clear_upload, {
    updateTextAreaInput(session, "summary_upload_text", value = "")
    bq_values$parsed_data <- NULL
    output$parse_info <- renderUI({})
    output$parsed_preview_table <- DT::renderDataTable({})
    output$upload_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " Cleared. Ready for new summary.")
    })
    showNotification("Cleared successfully", type = "message", duration = 2)
  })
  
  # ========== ADD SINGLE ENTRY TAB ==========
  
  observeEvent(input$submit_single, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      return()
    }
    
    # Validate inputs
    if (trimws(input$single_book_name) == "" || trimws(input$single_author) == "" ||
        trimws(input$single_chapter) == "" || trimws(input$single_section) == "" ||
        trimws(input$single_main_details) == "") {
      output$single_submit_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please fill in all required fields (Book Name, Author, Chapter, Section, Main Details)")
      })
      return()
    }
    
    output$single_submit_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Submitting to BigQuery...")
    })
    
    tryCatch({
      # Create single row data frame
      df <- data.frame(
        book_name = trimws(input$single_book_name),
        author = trimws(input$single_author),
        chapter = trimws(input$single_chapter),
        section = trimws(input$single_section),
        main_details = trimws(input$single_main_details),
        numeric_data = trimws(input$single_numeric_data),
        stringsAsFactors = FALSE
      )
      
      # Upload using corrected method
      upload_to_bigquery(df)
      
      output$single_submit_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Entry submitted successfully to BigQuery!")
      })
      
      showNotification("✓ Entry submitted successfully!", type = "message", duration = 3)
      
      # Clear form
      updateTextInput(session, "single_book_name", value = "")
      updateTextInput(session, "single_author", value = "")
      updateTextInput(session, "single_chapter", value = "")
      updateTextInput(session, "single_section", value = "")
      updateTextAreaInput(session, "single_main_details", value = "")
      updateTextInput(session, "single_numeric_data", value = "")
      
      # Update stats
      update_single_entry_stats()
      
      # Update visualization dropdowns
      update_viz_dropdowns()
      
    }, error = function(e) {
      output$single_submit_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Submission failed: ", e$message)
      })
      showNotification(paste("Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Update single entry stats
  update_single_entry_stats <- function() {
    if (!bq_values$authenticated) return()
    
    tryCatch({
      query <- sprintf("SELECT COUNT(DISTINCT book_name) as books, 
                               COUNT(DISTINCT chapter) as chapters,
                               COUNT(*) as entries 
                        FROM `%s`", bq_values$full_table_id)
      
      result <- bq_project_query(bq_values$project_id, query)
      stats <- bq_table_download(result)
      
      output$stat_total_books <- renderValueBox({
        valueBox(
          stats$books,
          "Total Books",
          icon = icon("book"),
          color = "aqua"
        )
      })
      
      output$stat_total_chapters <- renderValueBox({
        valueBox(
          stats$chapters,
          "Total Chapters",
          icon = icon("bookmark"),
          color = "blue"
        )
      })
      
      output$stat_total_entries <- renderValueBox({
        valueBox(
          stats$entries,
          "Total Entries",
          icon = icon("database"),
          color = "green"
        )
      })
      
    }, error = function(e) {
      # Silently fail for stats
    })
  }
  
  # Initialize single entry stats
  output$stat_total_books <- renderValueBox({
    valueBox(0, "Total Books", icon = icon("book"), color = "aqua")
  })
  
  output$stat_total_chapters <- renderValueBox({
    valueBox(0, "Total Chapters", icon = icon("bookmark"), color = "blue")
  })
  
  output$stat_total_entries <- renderValueBox({
    valueBox(0, "Total Entries", icon = icon("database"), color = "green")
  })
  
  # ========== BROWSE DATA TAB ==========
  
  # Refresh Table
  observeEvent(input$refresh_table, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      return()
    }
    
    output$browse_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Loading data from BigQuery...")
    })
    
    tryCatch({
      query <- sprintf("SELECT * FROM `%s` ORDER BY created_at DESC LIMIT %d", 
                       bq_values$full_table_id, 
                       input$max_browse_rows)
      
      result <- bq_project_query(bq_values$project_id, query)
      data <- bq_table_download(result)
      
      bq_values$browse_data <- data
      
      output$browse_table <- DT::renderDataTable({
        DT::datatable(
          data,
          options = list(
            pageLength = 25,
            scrollX = TRUE,
            dom = 'Bfrtip'
          ),
          rownames = FALSE
        )
      })
      
      output$browse_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Loaded %d rows from BigQuery", nrow(data)))
      })
      
      showNotification(sprintf("✓ Loaded %d rows", nrow(data)), type = "message", duration = 3)
      
      # Update single entry stats
      update_single_entry_stats()
      
    }, error = function(e) {
      output$browse_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Failed to load data: ",
                 tags$br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Download Data
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("book_summaries_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      if (!is.null(bq_values$browse_data)) {
        write.csv(bq_values$browse_data, file, row.names = FALSE)
      }
    }
  )
  
  # ========== RICH VISUALIZATIONS TAB ==========
  
  # Update visualization dropdowns
  update_viz_dropdowns <- function() {
    if (!bq_values$authenticated) return()
    
    tryCatch({
      query <- sprintf("SELECT DISTINCT book_name FROM `%s` ORDER BY book_name", 
                       bq_values$full_table_id)
      
      result <- bq_project_query(bq_values$project_id, query)
      books <- bq_table_download(result)
      
      if (nrow(books) > 0) {
        book_choices <- setNames(books$book_name, books$book_name)
        updateSelectInput(session, "viz_select_book", choices = book_choices)
      }
      
    }, error = function(e) {
      # Silently fail
    })
  }
  
  # Update chapter filter when book is selected
  # ========== UPDATE CHAPTER FILTER WHEN BOOK IS SELECTED ==========
  
  observeEvent(input$viz_select_book, {
    if (!bq_values$authenticated || is.null(input$viz_select_book)) return()
    
    tryCatch({
      # FIXED: Direct string interpolation with SQL injection protection
      safe_book_name <- gsub("'", "''", input$viz_select_book)
      query <- sprintf("SELECT DISTINCT chapter FROM `%s` WHERE book_name = '%s' ORDER BY chapter", 
                       bq_values$full_table_id,
                       safe_book_name)
      
      result <- bq_project_query(bq_values$project_id, query)
      chapters <- bq_table_download(result)
      
      if (nrow(chapters) > 0) {
        chapter_choices <- c("All Chapters" = "all", setNames(chapters$chapter, chapters$chapter))
        updateSelectInput(session, "viz_filter_chapter", choices = chapter_choices)
      }
      
    }, error = function(e) {
      # Silently fail - don't disrupt user experience
    })
  })
  
  # Load Visualizations
  # ========== LOAD VISUALIZATIONS EVENT HANDLER ==========
  
  observeEvent(input$load_visualizations, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      return()
    }
    
    if (is.null(input$viz_select_book)) {
      showNotification("Please select a book to visualize!", type = "warning", duration = 3)
      return()
    }
    
    output$viz_load_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Loading visualization data...")
    })
    
    tryCatch({
      # Build query with optional chapter filter - FIXED: Using direct string interpolation
      if (input$viz_filter_chapter == "all") {
        # Escape single quotes in book name to prevent SQL injection
        safe_book_name <- gsub("'", "''", input$viz_select_book)
        query <- sprintf("SELECT * FROM `%s` WHERE book_name = '%s' ORDER BY chapter, section", 
                         bq_values$full_table_id,
                         safe_book_name)
        result <- bq_project_query(bq_values$project_id, query)
      } else {
        # Escape single quotes in both book name and chapter
        safe_book_name <- gsub("'", "''", input$viz_select_book)
        safe_chapter <- gsub("'", "''", input$viz_filter_chapter)
        query <- sprintf("SELECT * FROM `%s` WHERE book_name = '%s' AND chapter = '%s' ORDER BY section", 
                         bq_values$full_table_id,
                         safe_book_name,
                         safe_chapter)
        result <- bq_project_query(bq_values$project_id, query)
      }
      
      data <- bq_table_download(result)
      
      if (nrow(data) == 0) {
        output$viz_load_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " No data found for selected book/chapter")
        })
        return()
      }
      
      bq_values$viz_data <- data
      
      # Render Book Header
      output$viz_book_header <- renderUI({
        tags$div(class = "book-header",
                 tags$h2(data$book_name[1]),
                 tags$div(class = "author", 
                          tags$i(class = "fa fa-user"), 
                          " ", data$author[1]))
      })
      
      # Render Statistics
      output$viz_total_chapters <- renderValueBox({
        valueBox(
          length(unique(data$chapter)),
          "Chapters",
          icon = icon("book-open"),
          color = "aqua"
        )
      })
      
      output$viz_total_sections <- renderValueBox({
        valueBox(
          length(unique(data$section)),
          "Sections",
          icon = icon("list-ol"),
          color = "blue"
        )
      })
      
      # Calculate average of numeric data
      avg_numeric <- tryCatch({
        all_nums <- unlist(lapply(data$numeric_data, function(x) {
          if (is.na(x) || trimws(x) == "") return(NULL)
          as.numeric(unlist(strsplit(as.character(x), ",")))
        }))
        round(mean(all_nums, na.rm = TRUE), 1)
      }, error = function(e) { 0 })
      
      output$viz_avg_numeric <- renderValueBox({
        valueBox(
          avg_numeric,
          "Avg Metric",
          icon = icon("chart-line"),
          color = "yellow"
        )
      })
      
      output$viz_total_entries <- renderValueBox({
        valueBox(
          nrow(data),
          "Total Entries",
          icon = icon("database"),
          color = "green"
        )
      })
      
      # Render Chapter Cards
      output$viz_chapters_html <- renderUI({
        
        chapter_cards <- lapply(1:nrow(data), function(i) {
          row <- data[i, ]
          
          # Parse numeric data for metrics
          metrics_html <- ""
          if (!is.na(row$numeric_data) && trimws(row$numeric_data) != "") {
            nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
            if (length(nums) > 0) {
              metrics_html <- tags$div(
                style = "margin-top: 15px;",
                tags$h5("Metrics:"),
                lapply(1:min(6, length(nums)), function(j) {
                  tags$div(
                    class = "metric-box",
                    tags$div(class = "metric-label", paste("Metric", j)),
                    tags$div(class = "metric-value", nums[j])
                  )
                })
              )
            }
          }
          
          tags$div(
            class = "viz-card",
            tags$div(class = "chapter-title", 
                     tags$i(class = "fa fa-bookmark"), 
                     " ", row$chapter),
            tags$div(class = "section-tag", row$section),
            tags$div(class = "details-text", row$main_details),
            metrics_html
          )
        })
        
        do.call(tagList, chapter_cards)
      })
      
      # Render Numeric Chart
      output$viz_numeric_chart <- renderPlotly({
        
        # Prepare data for plotting
        chart_data <- data.frame(
          chapter = character(),
          metric_name = character(),
          value = numeric(),
          stringsAsFactors = FALSE
        )
        
        for (i in 1:nrow(data)) {
          row <- data[i, ]
          if (!is.na(row$numeric_data) && trimws(row$numeric_data) != "") {
            nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
            if (length(nums) > 0) {
              for (j in 1:length(nums)) {
                chart_data <- rbind(chart_data, data.frame(
                  chapter = paste("Ch", i),
                  metric_name = paste("Metric", j),
                  value = nums[j],
                  stringsAsFactors = FALSE
                ))
              }
            }
          }
        }
        
        if (nrow(chart_data) == 0) {
          return(plot_ly() %>% layout(title = "No numeric data available"))
        }
        
        # Create line chart
        plot_ly(chart_data, x = ~chapter, y = ~value, color = ~metric_name, 
                type = 'scatter', mode = 'lines+markers') %>%
          layout(
            title = "Numeric Data Trends Across Chapters",
            xaxis = list(title = "Chapter"),
            yaxis = list(title = "Value"),
            hovermode = "closest",
            plot_bgcolor = "#f8f9fa",
            paper_bgcolor = "#ffffff"
          )
      })
      
      # Render Comparison Chart
      output$viz_comparison_chart <- renderPlotly({
        
        # Calculate average per chapter
        comp_data <- data.frame(
          chapter = character(),
          avg_value = numeric(),
          stringsAsFactors = FALSE
        )
        
        for (i in 1:nrow(data)) {
          row <- data[i, ]
          if (!is.na(row$numeric_data) && trimws(row$numeric_data) != "") {
            nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
            if (length(nums) > 0) {
              comp_data <- rbind(comp_data, data.frame(
                chapter = paste("Chapter", i),
                avg_value = mean(nums, na.rm = TRUE),
                stringsAsFactors = FALSE
              ))
            }
          }
        }
        
        if (nrow(comp_data) == 0) {
          return(plot_ly() %>% layout(title = "No numeric data available"))
        }
        
        # Create bar chart
        plot_ly(comp_data, x = ~chapter, y = ~avg_value, type = 'bar',
                marker = list(color = '#008A82',
                              line = list(color = '#00A39A', width = 2))) %>%
          layout(
            title = "Average Metrics by Chapter",
            xaxis = list(title = "Chapter"),
            yaxis = list(title = "Average Value"),
            plot_bgcolor = "#f8f9fa",
            paper_bgcolor = "#ffffff"
          )
      })
      
      output$viz_load_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Loaded visualizations for '%s' (%d entries)", 
                         data$book_name[1], nrow(data)))
      })
      
      showNotification("✓ Visualizations loaded successfully!", type = "message", duration = 3)
      
    }, error = function(e) {
      output$viz_load_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Failed to load visualizations: ", e$message)
      })
      showNotification(paste("Error:", e$message), type = "error", duration = 5)
    })
  })
  
  # Initialize empty visualizations
  output$viz_book_header <- renderUI({ tags$div() })
  output$viz_chapters_html <- renderUI({ tags$div() })
  output$viz_numeric_chart <- renderPlotly({ plot_ly() })
  output$viz_comparison_chart <- renderPlotly({ plot_ly() })
  
  output$viz_total_chapters <- renderValueBox({
    valueBox(0, "Chapters", icon = icon("book-open"), color = "aqua")
  })
  
  output$viz_total_sections <- renderValueBox({
    valueBox(0, "Sections", icon = icon("list-ol"), color = "blue")
  })
  
  output$viz_avg_numeric <- renderValueBox({
    valueBox(0, "Avg Metric", icon = icon("chart-line"), color = "yellow")
  })
  
  output$viz_total_entries <- renderValueBox({
    valueBox(0, "Total Entries", icon = icon("database"), color = "green")
  })
}

# Run the application
shinyApp(ui = ui, server = server)