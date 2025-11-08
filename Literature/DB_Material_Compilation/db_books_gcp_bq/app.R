# Business Model Canvas Dashboard with BigQuery Integration
# Author: Generated for Business Strategy Management
# Date: 2025

library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(jsonlite)
library(bigrquery)
library(stringr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Business Model Canvas Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("BigQuery Authentication", tabName = "auth", icon = icon("key")),
      menuItem("Bulk Import Canvas", tabName = "bulk_import", icon = icon("file-import")),
      menuItem("Business Model Canvas", tabName = "canvas_view", icon = icon("th"))
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
        
        /* Text areas */
        textarea.form-control {
          min-height: 100px;
        }
        
        #bulk_text {
          min-height: 400px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
        }
        
        /* Alert styling */
        .alert-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          border-left: 4px solid #17a2b8 !important;
          border-radius: 8px;
        }
        
        /* Canvas box styling */
        .canvas-box {
          background: #ffffff;
          border: 2px solid #008A82;
          border-radius: 8px;
          padding: 15px;
          min-height: 200px;
          margin-bottom: 15px;
          box-shadow: 0 2px 8px rgba(0, 138, 130, 0.15);
        }
        
        .canvas-box h4 {
          color: #002C3C;
          font-weight: bold;
          margin-top: 0;
          padding-bottom: 10px;
          border-bottom: 2px solid #00A39A;
        }
        
        .canvas-box p {
          font-size: 14px;
          line-height: 1.6;
          color: #2c3e50;
          margin-top: 10px;
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
      "))
    ),
    
    tabItems(
      # Tab 1: Authentication
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
                                     placeholder = "your-gcp-project-id",
                                     width = "100%"),
                           
                           textInput("dataset_id", 
                                     "Dataset ID:",
                                     placeholder = "your_dataset_id",
                                     value = "business_strategy",
                                     width = "100%"),
                           
                           textInput("table_id", 
                                     "Table ID:",
                                     placeholder = "table_name",
                                     value = "business_model_canvas",
                                     width = "100%"),
                           
                           p(style = "color: #7f8c8d; font-size: 12px;", 
                             "The table will be created automatically if it doesn't exist.")
                    )
                  ),
                  
                  br(),
                  actionButton("authenticate", 
                               "Connect to BigQuery", 
                               class = "btn-primary btn-lg",
                               icon = icon("plug")),
                  
                  hr(),
                  h4("Connection Status"),
                  htmlOutput("auth_status"),
                  
                  hr(),
                  h5("Package Information:"),
                  verbatimTextOutput("package_info")
                )
              )
      ),
      
      # Tab 2: Bulk Import
      tabItem(tabName = "bulk_import",
              fluidRow(
                box(
                  title = "Business Model Canvas - Bulk Import", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("Import Business Model Canvas Data"),
                  p("Enter your business identification and paste the 9 building blocks of your Business Model Canvas."),
                  
                  fluidRow(
                    column(4,
                           textInput("business_area", 
                                     "Business Area (max 32 chars):", 
                                     placeholder = "e.g., Technology, Healthcare",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("project", 
                                     "Project (max 32 chars):", 
                                     placeholder = "e.g., Mobile App Development",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("business_focus", 
                                     "Business Focus (max 32 chars):", 
                                     placeholder = "e.g., B2B SaaS",
                                     width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements for Bulk Import:"),
                      tags$ul(
                        tags$li("Start each section with its title in brackets: [Key Partners], [Key Activities], etc."),
                        tags$li("Content should follow immediately after each title"),
                        tags$li("Separate sections with blank lines"),
                        tags$li("Required sections: Key Partners, Key Activities, Key Resources, Value Propositions, Customer Relationships, Channels, Customer Segments, Cost Structure, Revenue Streams")
                      )
                  ),
                  
                  textAreaInput("bulk_text", 
                                "Paste Business Model Canvas Content:",
                                height = "400px",
                                width = "100%",
                                placeholder = "[Key Partners]\nYour key partners content here...\n\n[Key Activities]\nYour key activities content here...\n\n[Key Resources]\nYour key resources content here...\n\n[Value Propositions]\nYour value propositions content here...\n\n[Customer Relationships]\nYour customer relationships content here...\n\n[Channels]\nYour channels content here...\n\n[Customer Segments]\nYour customer segments content here...\n\n[Cost Structure]\nYour cost structure content here...\n\n[Revenue Streams]\nYour revenue streams content here..."),
                  
                  fluidRow(
                    column(4,
                           actionButton("parseCanvas", 
                                        "Parse Canvas Data", 
                                        class = "btn btn-info btn-lg",
                                        icon = icon("cogs"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("submitCanvas", 
                                        "Submit to BigQuery", 
                                        class = "btn btn-success btn-lg",
                                        icon = icon("cloud-upload-alt"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("clearCanvas", 
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
                  title = "Parsed Canvas Preview", 
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
      
      # Tab 3: Business Model Canvas View
      tabItem(tabName = "canvas_view",
              fluidRow(
                box(
                  title = "Select Business Model Canvas", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           selectInput("select_business_area", 
                                       "Business Area:", 
                                       choices = NULL,
                                       width = "100%")
                    ),
                    column(3,
                           selectInput("select_project", 
                                       "Project:", 
                                       choices = NULL,
                                       width = "100%")
                    ),
                    column(3,
                           selectInput("select_business_focus", 
                                       "Business Focus:", 
                                       choices = NULL,
                                       width = "100%")
                    ),
                    column(3,
                           br(),
                           actionButton("loadCanvas", 
                                        "Load Canvas", 
                                        class = "btn btn-success btn-lg",
                                        icon = icon("download"),
                                        width = "100%")
                    )
                  )
                )
              ),
              
              # Business Model Canvas Layout
              fluidRow(
                # Left Column
                column(3,
                       div(class = "canvas-box",
                           h4("Key Partners"),
                           htmlOutput("canvas_key_partners")
                       ),
                       div(class = "canvas-box",
                           h4("Key Activities"),
                           htmlOutput("canvas_key_activities")
                       ),
                       div(class = "canvas-box",
                           h4("Key Resources"),
                           htmlOutput("canvas_key_resources")
                       )
                ),
                
                # Middle Column
                column(3,
                       div(class = "canvas-box",
                           h4("Value Propositions"),
                           htmlOutput("canvas_value_propositions")
                       )
                ),
                
                column(3,
                       div(class = "canvas-box",
                           h4("Customer Relationships"),
                           htmlOutput("canvas_customer_relationships")
                       ),
                       div(class = "canvas-box",
                           h4("Channels"),
                           htmlOutput("canvas_channels")
                       )
                ),
                
                # Right Column
                column(3,
                       div(class = "canvas-box",
                           h4("Customer Segments"),
                           htmlOutput("canvas_customer_segments")
                       )
                )
              ),
              
              fluidRow(
                column(6,
                       div(class = "canvas-box",
                           h4("Cost Structure"),
                           htmlOutput("canvas_cost_structure")
                       )
                ),
                column(6,
                       div(class = "canvas-box",
                           h4("Revenue Streams"),
                           htmlOutput("canvas_revenue_streams")
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
    authenticated = FALSE,
    project_id = NULL,
    dataset_id = NULL,
    table_id = NULL,
    full_table_id = NULL,
    temp_file_path = NULL,
    parsed_canvas = NULL,
    current_canvas = NULL
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
          stop("Invalid JSON format in text input: ", e$message)
        })
        
        required_fields <- c("type", "project_id", "private_key", "client_email")
        missing_fields <- setdiff(required_fields, names(json_content))
        if (length(missing_fields) > 0) {
          stop("Missing required fields in JSON: ", paste(missing_fields, collapse = ", "))
        }
        
        temp_file <- tempfile(fileext = ".json")
        writeLines(input$json_text, temp_file)
        values$temp_file_path <- temp_file
        
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
              canvas_id STRING NOT NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              business_area STRING,
              project STRING,
              business_focus STRING,
              key_partners STRING,
              key_activities STRING,
              key_resources STRING,
              value_propositions STRING,
              customer_relationships STRING,
              channels STRING,
              customer_segments STRING,
              cost_structure STRING,
              revenue_streams STRING
            )", values$full_table_id)
          
          tryCatch({
            bq_project_query(values$project_id, create_table_query)
          }, error = function(e) {
            # Table might already exist
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
                     tags$small("Full Table Path: ", values$full_table_id))
          })
          
          showNotification("✓ BigQuery connection established!", type = "message")
          
          # Load default canvas and update dropdowns
          loadDefaultCanvas()
          updateCanvasDropdowns()
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
  
  # Load default canvas content
  loadDefaultCanvas <- function() {
    default_canvas <- list(
      key_partners = "<p><strong>Strategic Alliances:</strong> Technology partners providing infrastructure and platforms</p><p><strong>Suppliers:</strong> Cloud service providers (AWS, Google Cloud, Azure)</p><p><strong>Key Partners:</strong> Software development agencies, API providers, and integration partners</p>",
      
      key_activities = "<p><strong>Platform Development:</strong> Building and maintaining the core technology platform</p><p><strong>Customer Support:</strong> Providing technical assistance and account management</p><p><strong>Marketing & Sales:</strong> Lead generation, customer acquisition, and retention activities</p>",
      
      key_resources = "<p><strong>Human Resources:</strong> Skilled development team, sales staff, and customer support</p><p><strong>Technology:</strong> Proprietary software, cloud infrastructure, and development tools</p><p><strong>Financial:</strong> Operating capital and investment funding</p>",
      
      value_propositions = "<p><strong>Core Value:</strong> Streamlined business operations through integrated software solutions</p><p><strong>Benefits:</strong> Increased efficiency, cost reduction, and scalability</p><p><strong>Differentiation:</strong> User-friendly interface, customizable features, and excellent customer support</p>",
      
      customer_relationships = "<p><strong>Personal Assistance:</strong> Dedicated account managers for enterprise clients</p><p><strong>Self-Service:</strong> Comprehensive knowledge base and documentation</p><p><strong>Automated Services:</strong> AI-powered chatbots and automated onboarding</p>",
      
      channels = "<p><strong>Direct Sales:</strong> Inside sales team and field representatives</p><p><strong>Online:</strong> Company website, mobile app, and online marketplace</p><p><strong>Partnerships:</strong> Reseller network and integration partners</p>",
      
      customer_segments = "<p><strong>Primary Segment:</strong> Small to medium-sized businesses (SMBs)</p><p><strong>Secondary Segment:</strong> Enterprise organizations</p><p><strong>Niche Markets:</strong> Industry-specific solutions for healthcare, retail, and manufacturing</p>",
      
      cost_structure = "<p><strong>Fixed Costs:</strong> Salaries, office space, and infrastructure maintenance</p><p><strong>Variable Costs:</strong> Cloud hosting fees, marketing expenses, and customer acquisition costs</p><p><strong>Major Investments:</strong> Product development, R&D, and market expansion</p>",
      
      revenue_streams = "<p><strong>Subscription Revenue:</strong> Monthly and annual SaaS subscriptions</p><p><strong>Professional Services:</strong> Implementation, training, and consulting fees</p><p><strong>Additional Revenue:</strong> Premium features, add-ons, and marketplace commissions</p>"
    )
    
    output$canvas_key_partners <- renderUI(HTML(default_canvas$key_partners))
    output$canvas_key_activities <- renderUI(HTML(default_canvas$key_activities))
    output$canvas_key_resources <- renderUI(HTML(default_canvas$key_resources))
    output$canvas_value_propositions <- renderUI(HTML(default_canvas$value_propositions))
    output$canvas_customer_relationships <- renderUI(HTML(default_canvas$customer_relationships))
    output$canvas_channels <- renderUI(HTML(default_canvas$channels))
    output$canvas_customer_segments <- renderUI(HTML(default_canvas$customer_segments))
    output$canvas_cost_structure <- renderUI(HTML(default_canvas$cost_structure))
    output$canvas_revenue_streams <- renderUI(HTML(default_canvas$revenue_streams))
  }
  
  # Update canvas dropdowns
  updateCanvasDropdowns <- function() {
    if (!values$authenticated) return()
    
    tryCatch({
      # Get unique business areas
      query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", 
                       values$full_table_id)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "select_business_area", 
                          choices = c("Select..." = "", result$business_area))
      }
    }, error = function(e) {
      # Table might be empty
    })
  }
  
  # Update project dropdown when business area is selected
  observeEvent(input$select_business_area, {
    if (input$select_business_area == "" || !values$authenticated) return()
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
      query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                       values$full_table_id, business_area_clean)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "select_project", 
                          choices = c("Select..." = "", result$project))
      } else {
        updateSelectInput(session, "select_project", choices = c("No projects available" = ""))
      }
    }, error = function(e) {
      showNotification(paste("Error loading projects:", e$message), type = "error")
    })
  })
  
  # Update business focus dropdown when project is selected
  observeEvent(input$select_project, {
    if (input$select_project == "" || !values$authenticated) return()
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
      project_clean <- gsub("'", "\\\\'", input$select_project)
      query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                       values$full_table_id, business_area_clean, project_clean)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "select_business_focus", 
                          choices = c("Select..." = "", result$business_focus))
      } else {
        updateSelectInput(session, "select_business_focus", choices = c("No business focus available" = ""))
      }
    }, error = function(e) {
      showNotification(paste("Error loading business focus:", e$message), type = "error")
    })
  })
  
  # Parse canvas data
  observeEvent(input$parseCanvas, {
    
    if (is.null(input$bulk_text) || trimws(input$bulk_text) == "") {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please paste canvas content to parse")
      })
      return()
    }
    
    if (is.null(input$business_area) || trimws(input$business_area) == "") {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Area")
      })
      return()
    }
    
    if (is.null(input$project) || trimws(input$project) == "") {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Project name")
      })
      return()
    }
    
    if (is.null(input$business_focus) || trimws(input$business_focus) == "") {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Focus")
      })
      return()
    }
    
    output$bulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Parsing canvas data...")
    })
    
    tryCatch({
      text <- input$bulk_text
      
      # Parse the 9 sections
      key_partners <- str_match(text, "(?i)\\[Key Partners\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      key_activities <- str_match(text, "(?i)\\[Key Activities\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      key_resources <- str_match(text, "(?i)\\[Key Resources\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      value_propositions <- str_match(text, "(?i)\\[Value Propositions\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      customer_relationships <- str_match(text, "(?i)\\[Customer Relationships\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      channels <- str_match(text, "(?i)\\[Channels\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      customer_segments <- str_match(text, "(?i)\\[Customer Segments\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      cost_structure <- str_match(text, "(?i)\\[Cost Structure\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      revenue_streams <- str_match(text, "(?i)\\[Revenue Streams\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      
      # Check if all sections are found
      missing_sections <- c()
      if (is.na(key_partners)) missing_sections <- c(missing_sections, "Key Partners")
      if (is.na(key_activities)) missing_sections <- c(missing_sections, "Key Activities")
      if (is.na(key_resources)) missing_sections <- c(missing_sections, "Key Resources")
      if (is.na(value_propositions)) missing_sections <- c(missing_sections, "Value Propositions")
      if (is.na(customer_relationships)) missing_sections <- c(missing_sections, "Customer Relationships")
      if (is.na(channels)) missing_sections <- c(missing_sections, "Channels")
      if (is.na(customer_segments)) missing_sections <- c(missing_sections, "Customer Segments")
      if (is.na(cost_structure)) missing_sections <- c(missing_sections, "Cost Structure")
      if (is.na(revenue_streams)) missing_sections <- c(missing_sections, "Revenue Streams")
      
      if (length(missing_sections) > 0) {
        stop(paste("Missing sections:", paste(missing_sections, collapse = ", "), 
                   "\n\nPlease ensure all 9 sections are included with proper [Section Name] headers."))
      }
      
      # Store parsed data
      values$parsed_canvas <- list(
        business_area = substr(trimws(input$business_area), 1, 32),
        project = substr(trimws(input$project), 1, 32),
        business_focus = substr(trimws(input$business_focus), 1, 32),
        key_partners = trimws(key_partners),
        key_activities = trimws(key_activities),
        key_resources = trimws(key_resources),
        value_propositions = trimws(value_propositions),
        customer_relationships = trimws(customer_relationships),
        channels = trimws(channels),
        customer_segments = trimws(customer_segments),
        cost_structure = trimws(cost_structure),
        revenue_streams = trimws(revenue_streams)
      )
      
      output$bulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully parsed Business Model Canvas!",
                 br(),
                 tags$small("Business Area: ", values$parsed_canvas$business_area),
                 br(),
                 tags$small("Project: ", values$parsed_canvas$project),
                 br(),
                 tags$small("Business Focus: ", values$parsed_canvas$business_focus))
      })
      
      output$parseInfo <- renderUI({
        tags$p(
          tags$strong("Parsed Canvas Summary:"),
          br(),
          paste("Business Area:", values$parsed_canvas$business_area),
          br(),
          paste("Project:", values$parsed_canvas$project),
          br(),
          paste("Business Focus:", values$parsed_canvas$business_focus),
          br(),
          "All 9 building blocks successfully parsed"
        )
      })
      
      output$parsedPreview <- renderText({
        paste0(
          "Business Area: ", values$parsed_canvas$business_area, "\n",
          "Project: ", values$parsed_canvas$project, "\n",
          "Business Focus: ", values$parsed_canvas$business_focus, "\n\n",
          "Key Partners: ", substr(values$parsed_canvas$key_partners, 1, 100), "...\n\n",
          "Key Activities: ", substr(values$parsed_canvas$key_activities, 1, 100), "...\n\n",
          "Key Resources: ", substr(values$parsed_canvas$key_resources, 1, 100), "...\n\n",
          "Value Propositions: ", substr(values$parsed_canvas$value_propositions, 1, 100), "...\n\n",
          "Customer Relationships: ", substr(values$parsed_canvas$customer_relationships, 1, 100), "...\n\n",
          "Channels: ", substr(values$parsed_canvas$channels, 1, 100), "...\n\n",
          "Customer Segments: ", substr(values$parsed_canvas$customer_segments, 1, 100), "...\n\n",
          "Cost Structure: ", substr(values$parsed_canvas$cost_structure, 1, 100), "...\n\n",
          "Revenue Streams: ", substr(values$parsed_canvas$revenue_streams, 1, 100), "..."
        )
      })
      
      showNotification("✓ Canvas parsed successfully!", type = "message")
      
    }, error = function(e) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Parsing failed: ",
                 br(),
                 tags$small(e$message))
      })
      values$parsed_canvas <- NULL
      output$parseInfo <- renderUI(NULL)
      output$parsedPreview <- renderText("")
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Submit canvas to BigQuery
  observeEvent(input$submitCanvas, {
    
    if (!values$authenticated) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    if (is.null(values$parsed_canvas)) {
      output$bulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please parse the canvas first by clicking 'Parse Canvas Data'")
      })
      return()
    }
    
    output$bulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Submitting to BigQuery... Please wait.")
    })
    
    tryCatch({
      # Generate unique canvas ID
      canvas_id <- paste0(
        gsub("[^A-Za-z0-9]", "_", values$parsed_canvas$business_area), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_canvas$project), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_canvas$business_focus), "_",
        format(Sys.time(), "%Y%m%d%H%M%S")
      )
      
      # Escape single quotes in all fields
      canvas_id_clean <- gsub("'", "\\\\'", canvas_id)
      business_area_clean <- gsub("'", "\\\\'", values$parsed_canvas$business_area)
      project_clean <- gsub("'", "\\\\'", values$parsed_canvas$project)
      business_focus_clean <- gsub("'", "\\\\'", values$parsed_canvas$business_focus)
      key_partners_clean <- gsub("'", "\\\\'", values$parsed_canvas$key_partners)
      key_activities_clean <- gsub("'", "\\\\'", values$parsed_canvas$key_activities)
      key_resources_clean <- gsub("'", "\\\\'", values$parsed_canvas$key_resources)
      value_propositions_clean <- gsub("'", "\\\\'", values$parsed_canvas$value_propositions)
      customer_relationships_clean <- gsub("'", "\\\\'", values$parsed_canvas$customer_relationships)
      channels_clean <- gsub("'", "\\\\'", values$parsed_canvas$channels)
      customer_segments_clean <- gsub("'", "\\\\'", values$parsed_canvas$customer_segments)
      cost_structure_clean <- gsub("'", "\\\\'", values$parsed_canvas$cost_structure)
      revenue_streams_clean <- gsub("'", "\\\\'", values$parsed_canvas$revenue_streams)
      
      insert_query <- sprintf("
        INSERT INTO `%s` 
        (canvas_id, created_at, updated_at, business_area, project, business_focus, 
         key_partners, key_activities, key_resources, value_propositions, 
         customer_relationships, channels, customer_segments, cost_structure, revenue_streams) 
        VALUES (
          '%s',
          CURRENT_TIMESTAMP(),
          CURRENT_TIMESTAMP(),
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s'
        )",
                              values$full_table_id,
                              canvas_id_clean,
                              business_area_clean,
                              project_clean,
                              business_focus_clean,
                              key_partners_clean,
                              key_activities_clean,
                              key_resources_clean,
                              value_propositions_clean,
                              customer_relationships_clean,
                              channels_clean,
                              customer_segments_clean,
                              cost_structure_clean,
                              revenue_streams_clean
      )
      
      bq_project_query(values$project_id, insert_query)
      
      output$bulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully submitted Business Model Canvas to BigQuery!",
                 br(),
                 tags$small("Canvas ID: ", canvas_id))
      })
      
      showNotification("✓ Canvas submitted successfully!", type = "message")
      
      # Update dropdowns
      updateCanvasDropdowns()
      
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
  observeEvent(input$clearCanvas, {
    updateTextInput(session, "business_area", value = "")
    updateTextInput(session, "project", value = "")
    updateTextInput(session, "business_focus", value = "")
    updateTextAreaInput(session, "bulk_text", value = "")
    values$parsed_canvas <- NULL
    output$bulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " All fields cleared. Ready for new input.")
    })
    output$parseInfo <- renderUI(NULL)
    output$parsedPreview <- renderText("")
  })
  
  # Load canvas from BigQuery
  observeEvent(input$loadCanvas, {
    
    if (!values$authenticated) {
      showNotification("Please authenticate first", type = "error")
      return()
    }
    
    if (input$select_business_area == "" || input$select_project == "" || input$select_business_focus == "") {
      showNotification("Please select Business Area, Project, and Business Focus", type = "warning")
      return()
    }
    
    tryCatch({
      # Escape single quotes
      business_area_clean <- gsub("'", "\\\\'", input$select_business_area)
      project_clean <- gsub("'", "\\\\'", input$select_project)
      business_focus_clean <- gsub("'", "\\\\'", input$select_business_focus)
      
      query <- sprintf("
        SELECT * FROM `%s` 
        WHERE business_area = '%s' 
        AND project = '%s' 
        AND business_focus = '%s' 
        ORDER BY updated_at DESC 
        LIMIT 1",
                       values$full_table_id,
                       business_area_clean,
                       project_clean,
                       business_focus_clean
      )
      
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        values$current_canvas <- result
        
        # Update canvas displays
        output$canvas_key_partners <- renderUI(HTML(gsub("\n", "<br>", result$key_partners)))
        output$canvas_key_activities <- renderUI(HTML(gsub("\n", "<br>", result$key_activities)))
        output$canvas_key_resources <- renderUI(HTML(gsub("\n", "<br>", result$key_resources)))
        output$canvas_value_propositions <- renderUI(HTML(gsub("\n", "<br>", result$value_propositions)))
        output$canvas_customer_relationships <- renderUI(HTML(gsub("\n", "<br>", result$customer_relationships)))
        output$canvas_channels <- renderUI(HTML(gsub("\n", "<br>", result$channels)))
        output$canvas_customer_segments <- renderUI(HTML(gsub("\n", "<br>", result$customer_segments)))
        output$canvas_cost_structure <- renderUI(HTML(gsub("\n", "<br>", result$cost_structure)))
        output$canvas_revenue_streams <- renderUI(HTML(gsub("\n", "<br>", result$revenue_streams)))
        
        showNotification("✓ Canvas loaded successfully!", type = "message")
      } else {
        showNotification("No canvas found for this selection", type = "warning")
        loadDefaultCanvas()
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading canvas:", e$message), type = "error")
      loadDefaultCanvas()
    })
  })
  
  # Initialize with default canvas on startup
  observe({
    loadDefaultCanvas()
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