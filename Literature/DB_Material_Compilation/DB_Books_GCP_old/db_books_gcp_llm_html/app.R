# Book Summary Complete Suite - Version 3.0.0
# Enhanced Schema with Formulas & References
# Table: book_summaries_test3

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
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
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
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        .main-header .logo {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
        }
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
        .form-control {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease;
        }
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
        }
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
        textarea.form-control {
          min-height: 100px;
        }
        #summary_upload_text, #generated_summary {
          min-height: 500px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
        }
        .preview-section {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
          border-left: 4px solid #008A82;
          max-height: 400px;
          overflow-y: auto;
        }
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
        .alert-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          border-left: 4px solid #17a2b8 !important;
          border-radius: 8px;
        }
        #loading_spinner {
          color: #008A82;
        }
        .formula-box {
          margin-top: 15px;
          padding: 15px;
          background: linear-gradient(135deg, #e8f5f4 0%, #d4edea 100%);
          border-left: 4px solid #008A82;
          border-radius: 8px;
        }
        .formula-box h5 {
          color: #008A82;
          margin-top: 0;
          font-weight: 600;
        }
        .reference-box {
          margin-top: 15px;
          padding: 15px;
          background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
          border-left: 4px solid #f39c12;
          border-radius: 8px;
        }
        .reference-box h5 {
          color: #f39c12;
          margin-top: 0;
          font-weight: 600;
        }
        .reference-box a {
          color: #008A82;
          font-weight: bold;
          text-decoration: none;
          transition: color 0.3s ease;
        }
        .reference-box a:hover {
          color: #00A39A;
          text-decoration: underline;
        }
      ")),
      
      tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS-MML_HTMLorMML"),
      tags$script(HTML("
        if (typeof MathJax !== 'undefined') {
          MathJax.Hub.Config({
            tex2jax: {
              inlineMath: [['$','$'], ['\\\\(','\\\\)']],
              displayMath: [['$$','$$'], ['\\\\[','\\\\]']],
              processEscapes: true
            },
            'HTML-CSS': { linebreaks: { automatic: true } },
            SVG: { linebreaks: { automatic: true } }
          });
        }
      "))
    ),
    
    tabItems(
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
                tags$strong("Default Configuration:"), " Project: atera-2, Dataset: Wonderfulp_March, Table: book_summaries_test3"),
            
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
                               value = "book_summaries_test3",
                               width = "100%"),
                     
                     p(style = "color: #7f8c8d; font-size: 12px;", 
                       "Enhanced table schema with formulas, references, and detailed metrics")
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
                tags$strong("Enhanced Format with New Fields:"),
                tags$ul(
                  tags$li("Book metadata: [Title], [Author], [Genre], [Topic]"),
                  tags$li("Each chapter: [chapter], [section], [main_details]"),
                  tags$li("NEW: [formula] - LaTeX mathematical expressions"),
                  tags$li("NEW: [formula_explanation] - What the formula means"),
                  tags$li("NEW: [reference_url] - Relevant resource links"),
                  tags$li("NEW: [reference_description] - What the URL contains"),
                  tags$li("[numeric_data] - Comma-separated values"),
                  tags$li("NEW: [numeric_data_description] - Explanation of metrics"),
                  tags$li("Chapter format: Chapter 01-09 (zero-padded), Chapter 10+ (normal)")
                )
            ),
            
            textAreaInput("summary_upload_text", 
                          "Paste Book Summary Here:",
                          height = "500px",
                          width = "100%",
                          placeholder = "[Book Title]\n[Author Name]\n[Genre]\n[Topic]\n\n[chapter]: Chapter 01: Title\n[section]: All Sections\n[main_details]: Summary...\n[formula]: $$E = mc^2$$\n[formula_explanation]: Mass-energy equivalence...\n[reference_url]: https://example.com\n[reference_description]: Tutorial on topic\n[numeric_data]: 10,20,30,40\n[numeric_data_description]: Difficulty, Importance, etc."),
            
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
      
      tabItem(
        tabName = "visualize",
        fluidRow(
          box(
            title = "Rich Data Visualizations", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            
            h4("Select Book to Visualize"),
            p("Choose a book from your BigQuery database to see rich HTML visualizations with charts, formulas, and reference links."),
            
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
      
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About This Application",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            
            h3("Book Summary Complete Suite - Enhanced Edition"),
            p("An integrated platform combining AI-powered book summary generation with cloud database storage and rich data visualization including mathematical formulas and reference resources."),
            
            hr(),
            
            h4("Features:"),
            tags$ul(
              tags$li(tags$strong("AI Summary Generation:"), " Use Claude AI to automatically generate structured book summaries"),
              tags$li(tags$strong("BigQuery Integration:"), " Store summaries in Google Cloud (atera-2.Wonderfulp_March.book_summaries_test3)"),
              tags$li(tags$strong("Mathematical Formulas:"), " Include LaTeX/MathJax expressions with explanations"),
              tags$li(tags$strong("Reference Resources:"), " Add URLs with descriptions for additional learning"),
              tags$li(tags$strong("Enhanced Metrics:"), " Detailed numeric data with full descriptions"),
              tags$li(tags$strong("Rich Visualizations:"), " Interactive HTML dashboards with charts powered by Plotly")
            ),
            
            hr(),
            
            h4("Data Schema (BigQuery):"),
            p("Table: atera-2.Wonderfulp_March.book_summaries_test3"),
            tags$pre(
              "Fields:
  - id: INTEGER
  - created_at: TIMESTAMP
  - book_name: STRING
  - author: STRING
  - genre: STRING
  - topic: STRING
  - chapter: STRING
  - section: STRING
  - main_details: STRING
  - formula: STRING
  - formula_explanation: STRING
  - reference_url: STRING
  - reference_description: STRING
  - numeric_data: STRING
  - numeric_data_description: STRING"
            ),
            
            hr(),
            
            p("Version 3.0.0 - Enhanced Schema with Formulas & References", 
              style = "text-align: center; color: #999; font-size: 12px;")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  credentials <- reactiveValues(
    api_key = NULL,
    model = NULL,
    max_tokens = NULL,
    saved = FALSE
  )
  
  summary_data <- reactiveValues(
    text = ""
  )
  
  bq_values <- reactiveValues(
    authenticated = FALSE,
    project_id = "atera-2",
    dataset_id = "Wonderfulp_March",
    table_id = "book_summaries_test3",
    full_table_id = "atera-2.Wonderfulp_March.book_summaries_test3",
    temp_file_path = NULL,
    parsed_data = NULL,
    browse_data = NULL,
    viz_data = NULL
  )
  
  observeEvent(input$authenticate_bq, {
    
    tryCatch({
      bq_values$project_id <- trimws(input$project_id)
      bq_values$dataset_id <- trimws(input$dataset_id)
      bq_values$table_id <- trimws(input$table_id)
      bq_values$full_table_id <- paste0(bq_values$project_id, ".", 
                                        bq_values$dataset_id, ".", 
                                        bq_values$table_id)
      
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
      
      tryCatch({
        bq_deauth()
      }, error = function(e) {})
      
      Sys.unsetenv("GOOGLE_APPLICATION_CREDENTIALS")
      Sys.unsetenv("GCE_METADATA_HOST")
      
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
        test_result <- tryCatch({
          datasets <- bq_project_datasets(bq_values$project_id)
          TRUE
        }, error = function(e) {
          stop("Connection test failed: ", e$message)
        })
        
        if (test_result) {
          create_table_query <- sprintf("
            CREATE TABLE IF NOT EXISTS `%s` (
              id INTEGER,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              book_name STRING,
              author STRING,
              genre STRING,
              topic STRING,
              chapter STRING,
              section STRING,
              main_details STRING,
              formula STRING,
              formula_explanation STRING,
              reference_url STRING,
              reference_description STRING,
              numeric_data STRING,
              numeric_data_description STRING
            )", bq_values$full_table_id)
          
          tryCatch({
            bq_project_query(bq_values$project_id, create_table_query)
          }, error = function(e) {
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
  
  output$test_query_status <- renderUI({ tags$div() })
  output$test_query_table <- DT::renderDataTable({ 
    DT::datatable(data.frame(), options = list(dom = 't'), rownames = FALSE) 
  })
  
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
  
  generate_prompt <- function() {
    
    genre_text <- if (nchar(input$book_genre) > 0) {
      paste0("[", input$book_genre, "]\n")
    } else {
      "[General]\n"
    }
    
    topic_text <- if (nchar(input$book_topic) > 0) {
      paste0("[", input$book_topic, "]\n")
    } else {
      "[General Topic]\n"
    }
    
    prompt <- paste0(
      'Generate a comprehensive summary of the book "', input$book_title, '" by ', input$book_author, ' following this EXACT format:

Format Requirements:
1. Start with book metadata in brackets (4 lines):
[Book Title]
[Author Name]
', genre_text, topic_text, '

2. For each chapter/section entry use this EXACT pattern with ALL fields:
[chapter]: Chapter XX: Chapter Title
[section]: All Sections (or specific section like "Section X.X")
[main_details]: Write 100-200 words summarizing the chapter/section content
[formula]: $$LaTeX mathematical expression$$ (use $...$ for inline, $$...$$ for display math)
[formula_explanation]: Clear explanation of what the formula represents and its significance in 1-2 sentences
[reference_url]: https://example.com/relevant-resource
[reference_description]: Brief description of what the URL contains
[numeric_data]: num1,num2,num3,num4,num5,num6
[numeric_data_description]: Explanation of what each number represents

3. CRITICAL CHAPTER NUMBERING:
   - For chapters 1-9: Use TWO digits with leading zero (Chapter 01, Chapter 02, ..., Chapter 09)
   - For chapters 10+: Use normal numbering (Chapter 10, Chapter 11, etc.)

4. MATHEMATICAL FORMULAS (LaTeX/MathJax format):
   - Use proper LaTeX syntax: $inline$ or $$display$$
   - Include formulas when relevant to chapter content
   - If no formula is relevant, use: [formula]: N/A and [formula_explanation]: No mathematical formula applicable to this chapter

5. REFERENCE URLS:
   - Provide actual, helpful URLs when possible
   - Use reputable sources: Khan Academy, Coursera, academic institutions, official docs
   - If you cannot provide a specific URL, suggest search terms

6. NUMERIC DATA (always 6 values, 0-100 range):
   - Suggested metrics: Difficulty, Importance, Prerequisites, Practical Application, Engagement, Success Rate
   - Always include the description field explaining what each value represents

7. FORMATTING RULES:
   - Separate each chapter entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use exact bracket format shown above

Now generate the complete summary for "', input$book_title, '" by ', input$book_author, ' with ALL required fields for each chapter/section.'
    )
    
    return(prompt)
  }
  
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
  
  observeEvent(input$copy_to_bulk, {
    if (nchar(summary_data$text) > 0) {
      updateTextAreaInput(session, "summary_upload_text", value = summary_data$text)
      updateTabItems(session, "sidebarMenu", "bulk_import")
      showNotification("✓ Summary copied to Bulk Import tab!", type = "message", duration = 3)
    } else {
      showNotification("No summary to copy. Generate a summary first.", type = "warning", duration = 3)
    }
  })
  
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
      parsed_df <- parse_summary_text(summary_data$text)
      
      if (is.null(parsed_df) || nrow(parsed_df) == 0) {
        stop("Failed to parse summary")
      }
      
      upload_to_bigquery(parsed_df)
      
      output$generation_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 sprintf(" Successfully uploaded %d entries to BigQuery!", nrow(parsed_df)))
      })
      
      showNotification(sprintf("✓ Uploaded %d entries to BigQuery!", nrow(parsed_df)), 
                       type = "message", duration = 5)
      
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
  
  output$download_summary <- downloadHandler(
    filename = function() {
      paste0(gsub(" ", "_", input$book_title), "_summary_", format(Sys.Date(), "%Y%m%d"), ".txt")
    },
    content = function(file) {
      writeLines(summary_data$text, file)
    }
  )
  
  parse_summary_text <- function(text) {
    
    lines <- strsplit(text, "\n")[[1]]
    
    book_name <- NULL
    author <- NULL
    genre <- NULL
    topic <- NULL
    
    metadata_count <- 0
    for (i in seq_len(min(15, length(lines)))) {
      line <- trimws(lines[i])
      
      if (grepl("^\\[.+\\]$", line)) {
        metadata_count <- metadata_count + 1
        value <- gsub("^\\[|\\]$", "", line)
        
        if (metadata_count == 1) book_name <- value
        else if (metadata_count == 2) author <- value
        else if (metadata_count == 3) genre <- value
        else if (metadata_count == 4) topic <- value
        else break
      }
    }
    
    if (is.null(book_name) || is.null(author)) {
      stop("Could not find book name and author")
    }
    
    if (is.null(genre)) genre <- ""
    if (is.null(topic)) topic <- ""
    
    entries <- list()
    current_entry <- list()
    
    for (line in lines) {
      line <- trimws(line)
      
      if (line == "" || grepl("^\\[.+\\]$", line)) {
        if (length(current_entry) >= 4 && !is.null(current_entry$chapter)) {
          entries[[length(entries) + 1]] <- current_entry
          current_entry <- list()
        }
        next
      }
      
      if (grepl("^\\[chapter\\]:", line, ignore.case = TRUE)) {
        current_entry$chapter <- trimws(sub("^\\[chapter\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[section\\]:", line, ignore.case = TRUE)) {
        current_entry$section <- trimws(sub("^\\[section\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[main_details\\]:", line, ignore.case = TRUE)) {
        current_entry$main_details <- trimws(sub("^\\[main_details\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[formula\\]:", line, ignore.case = TRUE)) {
        current_entry$formula <- trimws(sub("^\\[formula\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[formula_explanation\\]:", line, ignore.case = TRUE)) {
        current_entry$formula_explanation <- trimws(sub("^\\[formula_explanation\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[reference_url\\]:", line, ignore.case = TRUE)) {
        current_entry$reference_url <- trimws(sub("^\\[reference_url\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[reference_description\\]:", line, ignore.case = TRUE)) {
        current_entry$reference_description <- trimws(sub("^\\[reference_description\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[numeric_data\\]:", line, ignore.case = TRUE)) {
        current_entry$numeric_data <- trimws(sub("^\\[numeric_data\\]:\\s*", "", line, ignore.case = TRUE))
      }
      else if (grepl("^\\[numeric_data_description\\]:", line, ignore.case = TRUE)) {
        current_entry$numeric_data_description <- trimws(sub("^\\[numeric_data_description\\]:\\s*", "", line, ignore.case = TRUE))
      }
    }
    
    if (length(current_entry) >= 4 && !is.null(current_entry$chapter)) {
      entries[[length(entries) + 1]] <- current_entry
    }
    
    if (length(entries) == 0) {
      stop("No valid entries found")
    }
    
    parsed_df <- data.frame(
      book_name = character(),
      author = character(),
      genre = character(),
      topic = character(),
      chapter = character(),
      section = character(),
      main_details = character(),
      formula = character(),
      formula_explanation = character(),
      reference_url = character(),
      reference_description = character(),
      numeric_data = character(),
      numeric_data_description = character(),
      stringsAsFactors = FALSE
    )
    
    for (entry in entries) {
      parsed_df <- rbind(parsed_df, data.frame(
        book_name = book_name,
        author = author,
        genre = genre,
        topic = topic,
        chapter = entry$chapter,
        section = entry$section,
        main_details = entry$main_details,
        formula = ifelse(is.null(entry$formula), "", entry$formula),
        formula_explanation = ifelse(is.null(entry$formula_explanation), "", entry$formula_explanation),
        reference_url = ifelse(is.null(entry$reference_url), "", entry$reference_url),
        reference_description = ifelse(is.null(entry$reference_description), "", entry$reference_description),
        numeric_data = ifelse(is.null(entry$numeric_data), "", entry$numeric_data),
        numeric_data_description = ifelse(is.null(entry$numeric_data_description), "", entry$numeric_data_description),
        stringsAsFactors = FALSE
      ))
    }
    
    return(parsed_df)
  }
  
  upload_to_bigquery <- function(df) {
    max_id_query <- sprintf("SELECT COALESCE(MAX(id), 0) as max_id FROM `%s`", 
                            bq_values$full_table_id)
    
    start_id <- tryCatch({
      result <- bq_project_query(bq_values$project_id, max_id_query)
      max_id_data <- bq_table_download(result)
      as.integer(max_id_data$max_id) + 1
    }, error = function(e) {
      1
    })
    
    df$id <- seq(start_id, start_id + nrow(df) - 1)
    df$created_at <- Sys.time()
    
    if (!"genre" %in% names(df)) df$genre <- ""
    if (!"topic" %in% names(df)) df$topic <- ""
    if (!"formula" %in% names(df)) df$formula <- ""
    if (!"formula_explanation" %in% names(df)) df$formula_explanation <- ""
    if (!"reference_url" %in% names(df)) df$reference_url <- ""
    if (!"reference_description" %in% names(df)) df$reference_description <- ""
    if (!"numeric_data_description" %in% names(df)) df$numeric_data_description <- ""
    
    df <- df[, c("id", "created_at", "book_name", "author", "genre", "topic",
                 "chapter", "section", "main_details", 
                 "formula", "formula_explanation",
                 "reference_url", "reference_description",
                 "numeric_data", "numeric_data_description")]
    
    bq_table_ref <- bq_table(bq_values$project_id, bq_values$dataset_id, bq_values$table_id)
    bq_table_upload(bq_table_ref, df, 
                    create_disposition = "CREATE_IF_NEEDED", 
                    write_disposition = "WRITE_APPEND")
  }
  
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
  
  observeEvent(input$submit_single, {
    
    if (!bq_values$authenticated) {
      showNotification("Please authenticate with BigQuery first!", type = "error", duration = 5)
      return()
    }
    
    if (trimws(input$single_book_name) == "" || trimws(input$single_author) == "" ||
        trimws(input$single_chapter) == "" || trimws(input$single_section) == "" ||
        trimws(input$single_main_details) == "") {
      output$single_submit_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please fill in all required fields")
      })
      return()
    }
    
    output$single_submit_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Submitting to BigQuery...")
    })
    
    tryCatch({
      df <- data.frame(
        book_name = trimws(input$single_book_name),
        author = trimws(input$single_author),
        genre = "",
        topic = "",
        chapter = trimws(input$single_chapter),
        section = trimws(input$single_section),
        main_details = trimws(input$single_main_details),
        formula = "",
        formula_explanation = "",
        reference_url = "",
        reference_description = "",
        numeric_data = trimws(input$single_numeric_data),
        numeric_data_description = "",
        stringsAsFactors = FALSE
      )
      
      upload_to_bigquery(df)
      
      output$single_submit_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Entry submitted successfully to BigQuery!")
      })
      
      showNotification("✓ Entry submitted successfully!", type = "message", duration = 3)
      
      updateTextInput(session, "single_book_name", value = "")
      updateTextInput(session, "single_author", value = "")
      updateTextInput(session, "single_chapter", value = "")
      updateTextInput(session, "single_section", value = "")
      updateTextAreaInput(session, "single_main_details", value = "")
      updateTextInput(session, "single_numeric_data", value = "")
      
      update_single_entry_stats()
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
    })
  }
  
  output$stat_total_books <- renderValueBox({
    valueBox(0, "Total Books", icon = icon("book"), color = "aqua")
  })
  
  output$stat_total_chapters <- renderValueBox({
    valueBox(0, "Total Chapters", icon = icon("bookmark"), color = "blue")
  })
  
  output$stat_total_entries <- renderValueBox({
    valueBox(0, "Total Entries", icon = icon("database"), color = "green")
  })
  
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
    })
  }
  
  observeEvent(input$viz_select_book, {
    if (!bq_values$authenticated || is.null(input$viz_select_book)) return()
    
    tryCatch({
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
    })
  })
  
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
      safe_book_name <- gsub("'", "''", input$viz_select_book)
      
      if (input$viz_filter_chapter == "all") {
        query <- sprintf("SELECT * FROM `%s` WHERE book_name = '%s' ORDER BY chapter, section", 
                         bq_values$full_table_id,
                         safe_book_name)
      } else {
        safe_chapter <- gsub("'", "''", input$viz_filter_chapter)
        query <- sprintf("SELECT * FROM `%s` WHERE book_name = '%s' AND chapter = '%s' ORDER BY section", 
                         bq_values$full_table_id,
                         safe_book_name,
                         safe_chapter)
      }
      
      result <- bq_project_query(bq_values$project_id, query)
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
      
      output$viz_book_header <- renderUI({
        tags$div(class = "book-header",
                 tags$h2(data$book_name[1]),
                 tags$div(class = "author", 
                          tags$i(class = "fa fa-user"), 
                          " ", data$author[1]))
      })
      
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
      
      output$viz_chapters_html <- renderUI({
        
        chapter_cards <- lapply(seq_len(nrow(data)), function(i) {
          row <- data[i, ]
          
          formula_html <- ""
          if (!is.na(row$formula) && trimws(row$formula) != "" && 
              trimws(row$formula) != "N/A" && trimws(row$formula) != "n/a") {
            formula_html <- tags$div(
              class = "formula-box",
              tags$h5(tags$i(class = "fa fa-calculator"), " Mathematical Formula:"),
              tags$div(style = "font-size: 1.2em; margin: 10px 0; padding: 10px; background: white; border-radius: 5px;", 
                       HTML(row$formula)),
              if (!is.na(row$formula_explanation) && trimws(row$formula_explanation) != "") {
                tags$p(style = "color: #555; font-style: italic; margin-top: 10px;", 
                       row$formula_explanation)
              }
            )
          }
          
          reference_html <- ""
          if (!is.na(row$reference_url) && trimws(row$reference_url) != "") {
            reference_html <- tags$div(
              class = "reference-box",
              tags$h5(tags$i(class = "fa fa-link"), " Reference Resource:"),
              tags$a(
                href = row$reference_url, 
                target = "_blank",
                row$reference_url,
                tags$i(class = "fa fa-external-link-alt", 
                       style = "margin-left: 5px; font-size: 0.8em;")
              ),
              if (!is.na(row$reference_description) && trimws(row$reference_description) != "") {
                tags$p(style = "margin-top: 8px; color: #555;", 
                       row$reference_description)
              }
            )
          }
          
          metrics_html <- ""
          if (!is.na(row$numeric_data) && trimws(row$numeric_data) != "") {
            nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
            if (length(nums) > 0) {
              metrics_html <- tags$div(
                style = "margin-top: 15px;",
                tags$h5(tags$i(class = "fa fa-chart-bar"), " Metrics:"),
                if (!is.na(row$numeric_data_description) && trimws(row$numeric_data_description) != "") {
                  tags$p(style = "color: #666; font-size: 0.9em; font-style: italic; margin-bottom: 10px; background: #f8f9fa; padding: 8px; border-radius: 5px;", 
                         tags$i(class = "fa fa-info-circle"), " ",
                         row$numeric_data_description)
                },
                lapply(seq_along(nums), function(j) {
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
            tags$div(class = "details-text", HTML(row$main_details)),
            formula_html,
            reference_html,
            metrics_html
          )
        })
        
        tags$div(
          do.call(tagList, chapter_cards),
          tags$script(HTML("
            if (typeof MathJax !== 'undefined') {
              MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
            }
          "))
        )
      })
      
      output$viz_numeric_chart <- renderPlotly({
        
        chart_data <- data.frame(
          chapter = character(),
          metric_name = character(),
          value = numeric(),
          stringsAsFactors = FALSE
        )
        
        for (i in seq_len(nrow(data))) {
          row <- data[i, ]
          if (!is.na(row$numeric_data) && trimws(row$numeric_data) != "") {
            nums <- as.numeric(unlist(strsplit(as.character(row$numeric_data), ",")))
            if (length(nums) > 0) {
              for (j in seq_along(nums)) {
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
      
      output$viz_comparison_chart <- renderPlotly({
        
        comp_data <- data.frame(
          chapter = character(),
          avg_value = numeric(),
          stringsAsFactors = FALSE
        )
        
        for (i in seq_len(nrow(data))) {
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

shinyApp(ui = ui, server = server)