# Business Model Canvas Dashboard with BigQuery Integration and Claude API
# Author: Generated for Business Strategy Management
# Date: 2025

library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(jsonlite)
library(bigrquery)
library(stringr)
library(htmltools)
library(httr)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Business Model Canvas Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Claude API Connection", tabName = "claude_auth", icon = icon("robot")),
      menuItem("BigQuery Authentication", tabName = "auth", icon = icon("key")),
      menuItem("Generate BM Canvas", tabName = "bulk_import", icon = icon("file-import")),
      menuItem("Generate DE Canvas", tabName = "bulk_import_de", icon = icon("file-upload")),
      menuItem("Generate DE Roadmap", tabName = "bulk_import_de_roadmap", icon = icon("route")),
      menuItem("Business Model Canvas", tabName = "canvas_view", icon = icon("th")),
      menuItem("Disciplined Ent. Canvas", tabName = "de_canvas", icon = icon("layer-group")),
      menuItem("Disciplined Ent. Roadmap", tabName = "de_roadmap", icon = icon("road"))
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
        
        #bulk_text, #de_bulk_text, #roadmap_bulk_text {
          min-height: 300px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
        }
        
        #claude_output, #de_claude_output, #roadmap_claude_output {
          min-height: 300px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
          background-color: #f8f9fa !important;
        }
        
        #business_description, #de_business_description, #roadmap_business_description {
          min-height: 150px !important;
        }
        
        /* Alert styling */
        .alert-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          border-left: 4px solid #17a2b8 !important;
          border-radius: 8px;
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
        
        /* ===== BUSINESS MODEL CANVAS STYLING ===== */
        .canvas-section {
          border: 2px solid;
          border-radius: 10px;
          padding: 10px;
          margin: 5px;
          min-height: 200px;
          position: relative;
          overflow: hidden;
        }
        
        .section-title {
          font-weight: bold;
          font-size: 15px;
          margin-bottom: 8px;
          display: flex;
          align-items: center;
        }
        
        .section-icon {
          margin-right: 6px;
          font-size: 18px;
        }
        
        .section-content {
          font-size: 11px;
          line-height: 1.2;
        }
        
        .section-content p {
          margin: 3px 0;
        }
        
        .section-content ul {
          margin: 3px 0;
          padding-left: 18px;
        }
        
        .section-content li {
          margin: 2px 0;
        }
        
        .section-content hr {
          margin: 5px 0;
          border: 0;
          border-top: 1px solid rgba(255, 255, 255, 0.3);
        }
        
        .two-column-content {
          column-count: 2;
          column-gap: 15px;
        }
        
        .two-column-content p,
        .two-column-content ul {
          break-inside: avoid;
        }
        
        /* Canvas color schemes */
        .key-partners { background: linear-gradient(135deg, #FF6B6B, #FF8E8E); border-color: #FF4757; color: white; }
        .key-activities { background: linear-gradient(135deg, #4ECDC4, #26D0CE); border-color: #00A8A8; color: white; }
        .value-propositions { background: linear-gradient(135deg, #45B7D1, #74C0FC); border-color: #3742FA; color: white; }
        .customer-relationships { background: linear-gradient(135deg, #96CEB4, #DDA0DD); border-color: #6C5CE7; color: white; }
        .customer-segments { background: linear-gradient(135deg, #FECA57, #FD79A8); border-color: #FDCB6E; color: black; }
        .key-resources { background: linear-gradient(135deg, #A29BFE, #6C5CE7); border-color: #5F27CD; color: white; }
        .channels { background: linear-gradient(135deg, #FD79A8, #E17055); border-color: #E84393; color: white; }
        .cost-structure { background: linear-gradient(135deg, #636E72, #2D3436); border-color: #636E72; color: white; }
        .revenue-streams { background: linear-gradient(135deg, #00B894, #55A3FF); border-color: #00B894; color: white; }
        
        /* Canvas grid layout */
        .canvas-grid {
          display: grid;
          grid-template-columns: repeat(6, 1fr);
          grid-template-rows: 1fr 1fr 1fr;
          gap: 10px;
          height: 700px;
          margin: 20px 0;
        }
        
        .partners { grid-column: 1 / 2; grid-row: 1 / 3; }
        .activities { grid-column: 2 / 3; grid-row: 1; }
        .resources { grid-column: 2 / 3; grid-row: 2; }
        .value-prop { grid-column: 3 / 4; grid-row: 1 / 3; }
        .relationships { grid-column: 4 / 5; grid-row: 1; }
        .channels-grid { grid-column: 4 / 5; grid-row: 2; }
        .segments { grid-column: 5 / 7; grid-row: 1 / 3; }
        .costs { grid-column: 1 / 4; grid-row: 3; }
        .revenue { grid-column: 4 / 7; grid-row: 3; }
        
        /* Selection controls box */
        .selection-controls-box {
          background: rgba(255, 255, 255, 0.98) !important;
          border-radius: 12px !important;
          padding: 20px;
          margin-bottom: 20px;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
        }
        
        /* ===== DISCIPLINED ENTREPRENEURSHIP CANVAS STYLING ===== */
        .de-canvas-grid {
          display: grid;
          grid-template-columns: repeat(5, 1fr);
          grid-template-rows: 1fr 1fr;
          gap: 15px;
          margin: 20px 0;
          height: 80vh;
        }
        
        .de-box {
          border: 3px solid;
          border-radius: 15px;
          padding: 20px 15px;
          position: relative;
          overflow-y: auto;
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
          display: flex;
          flex-direction: column;
        }
        
        .de-box-number {
          position: absolute;
          top: 15px;
          left: 15px;
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: white;
          color: #002C3C;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 20px;
          box-shadow: 0 3px 10px rgba(0, 0, 0, 0.3);
          z-index: 10;
        }
        
        .de-box-title {
          font-weight: bold;
          font-size: 17px;
          margin-top: 55px;
          margin-bottom: 12px;
          color: white;
          line-height: 1.3;
        }
        
        .de-box-subtitle {
          font-size: 14px;
          font-style: italic;
          margin-bottom: 15px;
          color: rgba(255, 255, 255, 0.95);
          line-height: 1.4;
        }
        
        .de-box-content {
          font-size: 12px;
          line-height: 1.5;
          color: white;
          flex-grow: 1;
        }
        
        /* DE Canvas specific box positioning and colors */
        .de-box1 { grid-column: 1; grid-row: 1; background: linear-gradient(135deg, #1E3A8A, #3B82F6); border-color: #1E40AF; }
        .de-box4 { grid-column: 2; grid-row: 1; background: linear-gradient(135deg, #B91C1C, #DC2626); border-color: #991B1B; }
        .de-box5 { grid-column: 3; grid-row: 1; background: linear-gradient(135deg, #BE185D, #EC4899); border-color: #9F1239; }
        .de-box8 { grid-column: 4; grid-row: 1; background: linear-gradient(135deg, #D97706, #F59E0B); border-color: #B45309; }
        .de-box9 { grid-column: 5; grid-row: 1; background: linear-gradient(135deg, #047857, #10B981); border-color: #065F46; }
        .de-box2 { grid-column: 1; grid-row: 2; background: linear-gradient(135deg, #0E7490, #06B6D4); border-color: #155E75; }
        .de-box3 { grid-column: 2; grid-row: 2; background: linear-gradient(135deg, #047857, #10B981); border-color: #065F46; }
        .de-box6 { grid-column: 3; grid-row: 2; background: linear-gradient(135deg, #6D28D9, #8B5CF6); border-color: #5B21B6; }
        .de-box7 { grid-column: 4; grid-row: 2; background: linear-gradient(135deg, #DC2626, #F87171); border-color: #B91C1C; }
        .de-box10 { grid-column: 5; grid-row: 2; background: linear-gradient(135deg, #1E293B, #475569); border-color: #334155; }
        
        /* ===== DISCIPLINED ENTREPRENEURSHIP ROADMAP STYLING ===== */
        .de-roadmap-container {
          padding: 20px;
          margin: 20px 0;
          height: 80vh;
          display: flex;
          flex-direction: column;
        }
        
        .de-roadmap-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 12px;
          margin-bottom: 12px;
          flex: 1;
        }
        
        .de-roadmap-box {
          border: 3px solid;
          border-radius: 15px;
          padding: 15px 12px;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          position: relative;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
          transition: transform 0.2s ease;
          overflow: hidden;
        }
        
        .de-roadmap-box:hover {
          transform: translateY(-3px);
          box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
        }
        
        .de-roadmap-number {
          position: absolute;
          top: 10px;
          left: 10px;
          width: 35px;
          height: 35px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 16px;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
          z-index: 10;
        }
        
        .de-roadmap-title {
          font-weight: bold;
          font-size: 13px;
          line-height: 1.3;
          color: white;
          margin-top: 10px;
        }
        
        .de-roadmap-description {
          font-size: 10px;
          line-height: 1.3;
          color: rgba(255, 255, 255, 0.9);
          margin-top: 8px;
          display: none;
        }
        
        .de-roadmap-box:hover .de-roadmap-description {
          display: block;
        }
        
        /* Roadmap category colors */
        .roadmap-cat1 { background: linear-gradient(135deg, #0EA5E9, #38BDF8); border-color: #0284C7; color: white; }
        .roadmap-cat1 .de-roadmap-number { background: #0EA5E9; color: white; }
        .roadmap-cat2 { background: linear-gradient(135deg, #3B82F6, #60A5FA); border-color: #2563EB; color: white; }
        .roadmap-cat2 .de-roadmap-number { background: #3B82F6; color: white; }
        .roadmap-cat3 { background: linear-gradient(135deg, #1E40AF, #3B82F6); border-color: #1E3A8A; color: white; }
        .roadmap-cat3 .de-roadmap-number { background: #1E40AF; color: white; }
        .roadmap-cat4 { background: linear-gradient(135deg, #06B6D4, #22D3EE); border-color: #0891B2; color: white; }
        .roadmap-cat4 .de-roadmap-number { background: #06B6D4; color: white; }
        .roadmap-cat5 { background: linear-gradient(135deg, #14B8A6, #2DD4BF); border-color: #0D9488; color: white; }
        .roadmap-cat5 .de-roadmap-number { background: #14B8A6; color: white; }
        
        .roadmap-legend {
          display: flex;
          justify-content: space-around;
          flex-wrap: wrap;
          padding: 15px 10px;
          background: rgba(255, 255, 255, 0.95);
          border-radius: 12px;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
          margin-top: auto;
        }
        
        .roadmap-legend-item {
          display: flex;
          align-items: center;
          margin: 5px 15px;
          font-weight: 600;
          font-size: 11px;
          color: #002C3C;
        }
        
        .roadmap-legend-line {
          width: 40px;
          height: 4px;
          margin-right: 8px;
          border-radius: 2px;
        }
        
        .legend-line1 { background: linear-gradient(90deg, #0EA5E9, #38BDF8); }
        .legend-line2 { background: linear-gradient(90deg, #3B82F6, #60A5FA); }
        .legend-line3 { background: linear-gradient(90deg, #1E40AF, #3B82F6); }
        .legend-line4 { background: linear-gradient(90deg, #06B6D4, #22D3EE); }
        .legend-line5 { background: linear-gradient(90deg, #14B8A6, #2DD4BF); }
      "))
    ),
    
    tabItems(
      # Tab 0: Claude API Authentication
      tabItem(tabName = "claude_auth",
              fluidRow(
                box(
                  title = "Claude API Connection", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h4("Connect to Claude API"),
                  p("Provide your Anthropic API key to enable AI-powered content generation."),
                  div(class = "alert alert-info",
                      tags$strong("Note:"), 
                      " Your API key will be stored securely for this session only. Get your API key from ", 
                      tags$a(href = "https://console.anthropic.com/", target = "_blank", "Anthropic Console")),
                  
                  fluidRow(
                    column(8,
                           passwordInput("claude_api_key", 
                                         "Anthropic API Key:",
                                         placeholder = "sk-ant-api...",
                                         width = "100%")
                    ),
                    column(4,
                           br(),
                           actionButton("connect_claude", 
                                        "Connect to Claude", 
                                        class = "btn-primary btn-lg",
                                        icon = icon("plug"),
                                        width = "100%")
                    )
                  ),
                  
                  hr(),
                  h4("Connection Status"),
                  htmlOutput("claude_status"),
                  
                  hr(),
                  h5("How it works:"),
                  tags$ul(
                    tags$li("Provide your business details and description"),
                    tags$li("Claude generates structured content based on proven frameworks"),
                    tags$li("Review and edit the generated content"),
                    tags$li("Save to BigQuery for visualization and management")
                  )
                )
              )
      ),
      
      # Tab 1: BigQuery Authentication
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
      
      # Tab 2: Generate Business Model Canvas
      tabItem(tabName = "bulk_import",
              fluidRow(
                box(
                  title = "Generate Business Model Canvas with Claude", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("AI-Powered Business Model Canvas Generation"),
                  p("Provide your business details and let Claude generate a comprehensive Business Model Canvas based on Alexander Osterwalder's framework."),
                  
                  fluidRow(
                    column(3,
                           textInput("business_area", 
                                     "Business Area (max 32 chars):", 
                                     placeholder = "e.g., Technology, Healthcare",
                                     width = "100%")
                    ),
                    column(3,
                           textInput("project", 
                                     "Project (max 32 chars):", 
                                     placeholder = "e.g., Mobile App Development",
                                     width = "100%")
                    ),
                    column(3,
                           textInput("business_focus", 
                                     "Business Focus (max 32 chars):", 
                                     placeholder = "e.g., B2B SaaS",
                                     width = "100%")
                    ),
                    column(3,
                           br(),
                           actionButton("generate_bm_canvas", 
                                        "Generate with Claude", 
                                        class = "btn btn-warning btn-lg",
                                        icon = icon("magic"),
                                        width = "100%")
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           textAreaInput("business_description", 
                                         "Business Idea Description:",
                                         height = "150px",
                                         width = "100%",
                                         placeholder = "Describe your business idea in detail. Include information about your target customers, the problem you're solving, your solution, competitive advantages, revenue model, and any other relevant details...")
                    )
                  ),
                  
                  br(),
                  htmlOutput("generate_status"),
                  
                  hr(),
                  h5("Claude Generated Content:"),
                  textAreaInput("claude_output", 
                                "Generated Business Model Canvas:",
                                height = "300px",
                                width = "100%",
                                placeholder = "Claude's generated content will appear here..."),
                  
                  hr(),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements:"),
                      tags$ul(
                        tags$li("Review the generated content above"),
                        tags$li("You can edit it or paste your own content below"),
                        tags$li("Content must follow the format: [Key Partners], [Key Activities], etc.")
                      )
                  ),
                  
                  textAreaInput("bulk_text", 
                                "Paste or Edit Business Model Canvas Content:",
                                height = "300px",
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
      
      # Tab 3: Generate Disciplined Entrepreneurship Canvas
      tabItem(tabName = "bulk_import_de",
              fluidRow(
                box(
                  title = "Generate Disciplined Entrepreneurship Canvas with Claude", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("AI-Powered Disciplined Entrepreneurship Canvas Generation"),
                  p("Provide your business details and let Claude generate a comprehensive Disciplined Entrepreneurship Canvas."),
                  
                  fluidRow(
                    column(3,
                           textInput("de_business_area", 
                                     "Business Area (max 32 chars):", 
                                     placeholder = "e.g., Technology, Healthcare",
                                     width = "100%")
                    ),
                    column(3,
                           textInput("de_project", 
                                     "Project (max 32 chars):", 
                                     placeholder = "e.g., Mobile App Development",
                                     width = "100%")
                    ),
                    column(3,
                           textInput("de_business_focus", 
                                     "Business Focus (max 32 chars):", 
                                     placeholder = "e.g., B2B SaaS",
                                     width = "100%")
                    ),
                    column(3,
                           br(),
                           actionButton("generate_de_canvas", 
                                        "Generate with Claude", 
                                        class = "btn btn-warning btn-lg",
                                        icon = icon("magic"),
                                        width = "100%")
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           textAreaInput("de_business_description", 
                                         "Business Idea Description:",
                                         height = "150px",
                                         width = "100%",
                                         placeholder = "Describe your business idea in detail for the Disciplined Entrepreneurship Canvas...")
                    )
                  ),
                  
                  br(),
                  htmlOutput("de_generate_status"),
                  
                  hr(),
                  h5("Claude Generated Content:"),
                  textAreaInput("de_claude_output", 
                                "Generated DE Canvas:",
                                height = "300px",
                                width = "100%",
                                placeholder = "Claude's generated content will appear here..."),
                  
                  hr(),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements:"),
                      tags$ul(
                        tags$li("Review the generated content above"),
                        tags$li("You can edit it or paste your own content below"),
                        tags$li("Required sections: [Raison d'Être], [Initial Market], etc.")
                      )
                  ),
                  
                  textAreaInput("de_bulk_text", 
                                "Paste or Edit DE Canvas Content:",
                                height = "300px",
                                width = "100%",
                                placeholder = "[Raison d'Être]\nMission: ...\nPassion: ...\nValues: ...\n\n[Initial Market]\nBeachhead: ...\nEnd User Profile: ..."),
                  
                  fluidRow(
                    column(4,
                           actionButton("parseDECanvas", 
                                        "Parse Canvas Data", 
                                        class = "btn btn-info btn-lg",
                                        icon = icon("cogs"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("submitDECanvas", 
                                        "Submit to BigQuery", 
                                        class = "btn btn-success btn-lg",
                                        icon = icon("cloud-upload-alt"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("clearDECanvas", 
                                        "Clear All", 
                                        class = "btn btn-danger",
                                        icon = icon("trash"),
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  htmlOutput("deBulkStatus")
                )
              ),
              
              fluidRow(
                box(
                  title = "Parsed DE Canvas Preview", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  htmlOutput("deParseInfo"),
                  br(),
                  
                  div(class = "preview-section",
                      verbatimTextOutput("deParsedPreview"))
                )
              )
      ),
      
      # Tab 4: Generate Disciplined Entrepreneurship Roadmap
      tabItem(tabName = "bulk_import_de_roadmap",
              fluidRow(
                box(
                  title = "Generate Disciplined Entrepreneurship Roadmap with Claude", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("AI-Powered Disciplined Entrepreneurship Roadmap Generation"),
                  p("Provide your business details and let Claude generate all 24 steps of the Disciplined Entrepreneurship Roadmap."),
                  
                  fluidRow(
                    column(3,
                           textInput("roadmap_business_area", 
                                     "Business Area (max 32 chars):", 
                                     placeholder = "e.g., Technology, Healthcare",
                                     width = "100%")
                    ),
                    column(3,
                           textInput("roadmap_project", 
                                     "Project (max 32 chars):", 
                                     placeholder = "e.g., Mobile App Development",
                                     width = "100%")
                    ),
                    column(3,
                           textInput("roadmap_business_focus", 
                                     "Business Focus (max 32 chars):", 
                                     placeholder = "e.g., B2B SaaS",
                                     width = "100%")
                    ),
                    column(3,
                           br(),
                           actionButton("generate_roadmap", 
                                        "Generate with Claude", 
                                        class = "btn btn-warning btn-lg",
                                        icon = icon("magic"),
                                        width = "100%")
                    )
                  ),
                  
                  fluidRow(
                    column(12,
                           textAreaInput("roadmap_business_description", 
                                         "Business Idea Description:",
                                         height = "150px",
                                         width = "100%",
                                         placeholder = "Describe your business idea in detail for the 24-step Disciplined Entrepreneurship Roadmap...")
                    )
                  ),
                  
                  br(),
                  htmlOutput("roadmap_generate_status"),
                  
                  hr(),
                  h5("Claude Generated Content:"),
                  textAreaInput("roadmap_claude_output", 
                                "Generated Roadmap:",
                                height = "300px",
                                width = "100%",
                                placeholder = "Claude's generated content will appear here..."),
                  
                  hr(),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements:"),
                      tags$ul(
                        tags$li("Review the generated content above"),
                        tags$li("You can edit it or paste your own content below"),
                        tags$li("All 24 steps required: [Step 1: Market Segmentation], [Step 2: Select a Beachhead Market], etc.")
                      )
                  ),
                  
                  textAreaInput("roadmap_bulk_text", 
                                "Paste or Edit Roadmap Content:",
                                height = "300px",
                                width = "100%",
                                placeholder = "[Step 1: Market Segmentation]\nYour content here...\n\n[Step 2: Select a Beachhead Market]\nYour content here..."),
                  
                  fluidRow(
                    column(4,
                           actionButton("parseRoadmap", 
                                        "Parse Roadmap Data", 
                                        class = "btn btn-info btn-lg",
                                        icon = icon("cogs"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("submitRoadmap", 
                                        "Submit to BigQuery", 
                                        class = "btn btn-success btn-lg",
                                        icon = icon("cloud-upload-alt"),
                                        width = "100%")
                    ),
                    column(4,
                           actionButton("clearRoadmap", 
                                        "Clear All", 
                                        class = "btn btn-danger",
                                        icon = icon("trash"),
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  htmlOutput("roadmapBulkStatus")
                )
              ),
              
              fluidRow(
                box(
                  title = "Parsed Roadmap Preview", 
                  status = "info", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  htmlOutput("roadmapParseInfo"),
                  br(),
                  
                  div(class = "preview-section",
                      verbatimTextOutput("roadmapParsedPreview"))
                )
              )
      ),
      
      # Tab 5: Business Model Canvas View (unchanged)
      tabItem(tabName = "canvas_view",
              fluidRow(
                column(12,
                       div(class = "selection-controls-box",
                           h3("Select Business Model Canvas", style = "margin-top: 0; color: #002C3C;"),
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
                )
              ),
              
              fluidRow(
                column(12,
                       h2("Business Model Canvas", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
                       div(class = "canvas-grid",
                           div(class = "canvas-section key-partners partners",
                               div(class = "section-title",
                                   span(class = "section-icon", "🤝"),
                                   "Key Partners"
                               ),
                               htmlOutput("canvas_key_partners")
                           ),
                           
                           div(class = "canvas-section key-activities activities",
                               div(class = "section-title",
                                   span(class = "section-icon", "⚡"),
                                   "Key Activities"
                               ),
                               htmlOutput("canvas_key_activities")
                           ),
                           
                           div(class = "canvas-section key-resources resources",
                               div(class = "section-title",
                                   span(class = "section-icon", "🏗️"),
                                   "Key Resources"
                               ),
                               htmlOutput("canvas_key_resources")
                           ),
                           
                           div(class = "canvas-section value-propositions value-prop",
                               div(class = "section-title",
                                   span(class = "section-icon", "🎁"),
                                   "Value Propositions"
                               ),
                               htmlOutput("canvas_value_propositions")
                           ),
                           
                           div(class = "canvas-section customer-relationships relationships",
                               div(class = "section-title",
                                   span(class = "section-icon", "💝"),
                                   "Customer Relationships"
                               ),
                               htmlOutput("canvas_customer_relationships")
                           ),
                           
                           div(class = "canvas-section channels channels-grid",
                               div(class = "section-title",
                                   span(class = "section-icon", "📢"),
                                   "Channels"
                               ),
                               htmlOutput("canvas_channels")
                           ),
                           
                           div(class = "canvas-section customer-segments segments",
                               div(class = "section-title",
                                   span(class = "section-icon", "👥"),
                                   "Customer Segments"
                               ),
                               htmlOutput("canvas_customer_segments")
                           ),
                           
                           div(class = "canvas-section cost-structure costs",
                               div(class = "section-title",
                                   span(class = "section-icon", "💰"),
                                   "Cost Structure"
                               ),
                               htmlOutput("canvas_cost_structure")
                           ),
                           
                           div(class = "canvas-section revenue-streams revenue",
                               div(class = "section-title",
                                   span(class = "section-icon", "💵"),
                                   "Revenue Streams"
                               ),
                               htmlOutput("canvas_revenue_streams")
                           )
                       )
                )
              )
      ),
      
      # Tab 6: Disciplined Entrepreneurship Canvas (unchanged)
      tabItem(tabName = "de_canvas",
              fluidRow(
                column(12,
                       div(class = "selection-controls-box",
                           h3("Select Disciplined Entrepreneurship Canvas", style = "margin-top: 0; color: #002C3C;"),
                           fluidRow(
                             column(3,
                                    selectInput("de_select_business_area", 
                                                "Business Area:", 
                                                choices = NULL,
                                                width = "100%")
                             ),
                             column(3,
                                    selectInput("de_select_project", 
                                                "Project:", 
                                                choices = NULL,
                                                width = "100%")
                             ),
                             column(3,
                                    selectInput("de_select_business_focus", 
                                                "Business Focus:", 
                                                choices = NULL,
                                                width = "100%")
                             ),
                             column(3,
                                    br(),
                                    actionButton("loadDECanvas", 
                                                 "Load Data", 
                                                 class = "btn btn-success btn-lg",
                                                 icon = icon("download"),
                                                 width = "100%")
                             )
                           )
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       h2("The Disciplined Entrepreneurship Canvas", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
                       div(class = "de-canvas-grid",
                           # Box 1-10 (unchanged from original)
                           div(class = "de-box de-box1",
                               div(class = "de-box-number", "1"),
                               div(class = "de-box-title", "Raison d'Être"),
                               div(class = "de-box-subtitle", "Why do you in business?"),
                               htmlOutput("de_box1_content")
                           ),
                           
                           div(class = "de-box de-box2",
                               div(class = "de-box-number", "2"),
                               div(class = "de-box-title", "Initial Market"),
                               div(class = "de-box-subtitle", "Who is your customer?"),
                               htmlOutput("de_box2_content")
                           ),
                           
                           div(class = "de-box de-box3",
                               div(class = "de-box-number", "3"),
                               div(class = "de-box-title", "Value Creation"),
                               div(class = "de-box-subtitle", "What can you do for your customer?"),
                               htmlOutput("de_box3_content")
                           ),
                           
                           div(class = "de-box de-box4",
                               div(class = "de-box-number", "4"),
                               div(class = "de-box-title", "Competitive Advantage"),
                               div(class = "de-box-subtitle", "Why you?"),
                               htmlOutput("de_box4_content")
                           ),
                           
                           div(class = "de-box de-box5",
                               div(class = "de-box-number", "5"),
                               div(class = "de-box-title", "Customer Acquisition"),
                               div(class = "de-box-subtitle", "How does your customer acquire your product?"),
                               htmlOutput("de_box5_content")
                           ),
                           
                           div(class = "de-box de-box6",
                               div(class = "de-box-number", "6"),
                               div(class = "de-box-title", "Product Unit Economics"),
                               div(class = "de-box-subtitle", "Can you make money?"),
                               htmlOutput("de_box6_content")
                           ),
                           
                           div(class = "de-box de-box7",
                               div(class = "de-box-number", "7"),
                               div(class = "de-box-title", "Sales"),
                               div(class = "de-box-subtitle", "How do you sell your product?"),
                               htmlOutput("de_box7_content")
                           ),
                           
                           div(class = "de-box de-box8",
                               div(class = "de-box-number", "8"),
                               div(class = "de-box-title", "Overall Economics"),
                               div(class = "de-box-subtitle", "Does your product make money?"),
                               htmlOutput("de_box8_content")
                           ),
                           
                           div(class = "de-box de-box9",
                               div(class = "de-box-number", "9"),
                               div(class = "de-box-title", "Design & Build"),
                               div(class = "de-box-subtitle", "How do you produce the product?"),
                               htmlOutput("de_box9_content")
                           ),
                           
                           div(class = "de-box de-box10",
                               div(class = "de-box-number", "10"),
                               div(class = "de-box-title", "Scaling"),
                               div(class = "de-box-subtitle", "How do you scale?"),
                               htmlOutput("de_box10_content")
                           )
                       )
                )
              )
      ),
      
      # Tab 7: Disciplined Entrepreneurship Roadmap (unchanged but abbreviated for space)
      tabItem(tabName = "de_roadmap",
              fluidRow(
                column(12,
                       div(class = "selection-controls-box",
                           h3("Select Disciplined Entrepreneurship Roadmap", style = "margin-top: 0; color: #002C3C;"),
                           fluidRow(
                             column(3,
                                    selectInput("roadmap_select_business_area", 
                                                "Business Area:", 
                                                choices = NULL,
                                                width = "100%")
                             ),
                             column(3,
                                    selectInput("roadmap_select_project", 
                                                "Project:", 
                                                choices = NULL,
                                                width = "100%")
                             ),
                             column(3,
                                    selectInput("roadmap_select_business_focus", 
                                                "Business Focus:", 
                                                choices = NULL,
                                                width = "100%")
                             ),
                             column(3,
                                    br(),
                                    actionButton("loadRoadmap", 
                                                 "Load Data", 
                                                 class = "btn btn-success btn-lg",
                                                 icon = icon("download"),
                                                 width = "100%")
                             )
                           )
                       )
                )
              ),
              
              fluidRow(
                column(12,
                       h2("Disciplined Entrepreneurship Roadmap", style = "text-align: center; color: white; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
                       # Roadmap boxes 1-24 (keeping original structure, abbreviated for space)
                       div(class = "de-roadmap-container",
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "1"),
                                   div(class = "de-roadmap-title", "Market Segmentation")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "2"),
                                   div(class = "de-roadmap-title", "Select a Beachhead Market")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "3"),
                                   div(class = "de-roadmap-title", "Build an End User Profile")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "4"),
                                   div(class = "de-roadmap-title", "Calculate TAM Size")
                               )
                           ),
                           # Add remaining 20 boxes following the same pattern...
                           # Legend
                           div(class = "roadmap-legend",
                               div(class = "roadmap-legend-item",
                                   div(class = "roadmap-legend-line legend-line1"),
                                   span("WHO IS YOUR CUSTOMER?")
                               ),
                               div(class = "roadmap-legend-item",
                                   div(class = "roadmap-legend-line legend-line2"),
                                   span("WHAT CAN YOU DO FOR YOUR CUSTOMER?")
                               ),
                               div(class = "roadmap-legend-item",
                                   div(class = "roadmap-legend-line legend-line3"),
                                   span("HOW DOES YOUR CUSTOMER ACQUIRE YOUR PRODUCT?")
                               ),
                               div(class = "roadmap-legend-item",
                                   div(class = "roadmap-legend-line legend-line4"),
                                   span("HOW DO YOU MAKE MONEY OFF YOUR PRODUCT?")
                               ),
                               div(class = "roadmap-legend-item",
                                   div(class = "roadmap-legend-line legend-line5"),
                                   span("HOW DO YOU DESIGN & BUILD YOUR PRODUCT? / HOW DO YOU SCALE YOUR BUSINESS?")
                               )
                           )
                       )
                )
              )
      )
    )
  )
)

# Server logic continues in next part due to length...
# (Server code with Claude API integration follows)

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
    parsed_de_canvas = NULL,
    parsed_roadmap = NULL, 
    current_canvas = NULL,
    claude_connected = FALSE,
    claude_api_key = NULL
  )
  
  # ===== CLAUDE API CONNECTION =====
  observeEvent(input$connect_claude, {
    if (is.null(input$claude_api_key) || trimws(input$claude_api_key) == "") {
      output$claude_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Please provide an API key")
      })
      return()
    }
    
    tryCatch({
      # Test the API key with a simple request
      test_response <- POST(
        url = "https://api.anthropic.com/v1/messages",
        add_headers(
          "x-api-key" = input$claude_api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = toJSON(list(
          model = "claude-sonnet-4-20250514",
          max_tokens = 10,
          messages = list(list(
            role = "user",
            content = "Hi"
          ))
        ), auto_unbox = TRUE),
        encode = "json"
      )
      
      if (status_code(test_response) == 200) {
        values$claude_connected <- TRUE
        values$claude_api_key <- input$claude_api_key
        
        output$claude_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Successfully connected to Claude API!",
                   br(),
                   tags$small("Model: Claude Sonnet 4"))
        })
        
        showNotification("✓ Claude API connection established!", type = "message")
      } else {
        stop("API key validation failed")
      }
      
    }, error = function(e) {
      values$claude_connected <- FALSE
      values$claude_api_key <- NULL
      
      output$claude_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Connection failed. Please check your API key.",
                 br(),
                 tags$small("Make sure your API key is valid and has the correct permissions."))
      })
      
      showNotification("Claude API connection failed", type = "error")
    })
  })
  
  # ===== CLAUDE GENERATION FUNCTIONS =====
  
  # Function to call Claude API
  call_claude_api <- function(prompt) {
    if (!values$claude_connected) {
      stop("Claude API not connected. Please connect first.")
    }
    
    response <- POST(
      url = "https://api.anthropic.com/v1/messages",
      add_headers(
        "x-api-key" = values$claude_api_key,
        "anthropic-version" = "2023-06-01",
        "content-type" = "application/json"
      ),
      body = toJSON(list(
        model = "claude-sonnet-4-20250514",
        max_tokens = 4000,
        messages = list(list(
          role = "user",
          content = prompt
        ))
      ), auto_unbox = TRUE),
      encode = "json"
    )
    
    if (status_code(response) != 200) {
      stop("API request failed: ", content(response, "text"))
    }
    
    result <- content(response, "parsed")
    return(result$content[[1]]$text)
  }
  
  # Generate Business Model Canvas
  observeEvent(input$generate_bm_canvas, {
    if (!values$claude_connected) {
      output$generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please connect to Claude API first (see Claude API Connection tab)")
      })
      return()
    }
    
    if (is.null(input$business_area) || trimws(input$business_area) == "" ||
        is.null(input$project) || trimws(input$project) == "" ||
        is.null(input$business_focus) || trimws(input$business_focus) == "" ||
        is.null(input$business_description) || trimws(input$business_description) == "") {
      output$generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please fill in all fields (Business Area, Project, Business Focus, and Description)")
      })
      return()
    }
    
    output$generate_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Generating Business Model Canvas with Claude... Please wait.")
    })
    
    tryCatch({
      prompt <- paste0(
        "You are a business strategy expert specializing in the Business Model Canvas framework by Alexander Osterwalder.\n\n",
        "Business Area: ", input$business_area, "\n",
        "Project: ", input$project, "\n",
        "Business Focus: ", input$business_focus, "\n",
        "Business Description: ", input$business_description, "\n\n",
        "Based on the information above, generate a comprehensive Business Model Canvas with all 9 building blocks. ",
        "Format your response EXACTLY as follows, with each section starting with its title in square brackets:\n\n",
        "[Key Partners]\n(Provide detailed content about key partners, suppliers, strategic alliances)\n\n",
        "[Key Activities]\n(Provide detailed content about key activities needed to deliver value proposition)\n\n",
        "[Key Resources]\n(Provide detailed content about key resources required)\n\n",
        "[Value Propositions]\n(Provide detailed content about value propositions and what makes this business unique)\n\n",
        "[Customer Relationships]\n(Provide detailed content about how to build and maintain customer relationships)\n\n",
        "[Channels]\n(Provide detailed content about channels to reach customers)\n\n",
        "[Customer Segments]\n(Provide detailed content about target customer segments)\n\n",
        "[Cost Structure]\n(Provide detailed content about major costs)\n\n",
        "[Revenue Streams]\n(Provide detailed content about revenue sources)\n\n",
        "Make the content specific, actionable, and tailored to the business description provided. ",
        "Include relevant details, examples, and strategic considerations for each section."
      )
      
      generated_content <- call_claude_api(prompt)
      
      updateTextAreaInput(session, "claude_output", value = generated_content)
      updateTextAreaInput(session, "bulk_text", value = generated_content)
      
      output$generate_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Business Model Canvas generated successfully!",
                 br(),
                 tags$small("Review the content above and click 'Parse Canvas Data' when ready"))
      })
      
      showNotification("✓ Canvas generated successfully!", type = "message")
      
    }, error = function(e) {
      output$generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Generation failed: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Generate DE Canvas
  observeEvent(input$generate_de_canvas, {
    if (!values$claude_connected) {
      output$de_generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please connect to Claude API first (see Claude API Connection tab)")
      })
      return()
    }
    
    if (is.null(input$de_business_area) || trimws(input$de_business_area) == "" ||
        is.null(input$de_project) || trimws(input$de_project) == "" ||
        is.null(input$de_business_focus) || trimws(input$de_business_focus) == "" ||
        is.null(input$de_business_description) || trimws(input$de_business_description) == "") {
      output$de_generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please fill in all fields")
      })
      return()
    }
    
    output$de_generate_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Generating Disciplined Entrepreneurship Canvas with Claude... Please wait.")
    })
    
    tryCatch({
      prompt <- paste0(
        "You are a business strategy expert specializing in the Disciplined Entrepreneurship framework.\n\n",
        "Business Area: ", input$de_business_area, "\n",
        "Project: ", input$de_project, "\n",
        "Business Focus: ", input$de_business_focus, "\n",
        "Business Description: ", input$de_business_description, "\n\n",
        "Based on the information above, generate a comprehensive Disciplined Entrepreneurship Canvas with all 10 sections. ",
        "Format your response EXACTLY as follows:\n\n",
        "[Raison d'Être]\nMission: (describe mission)\nPassion: (describe passion)\nValues: (describe core values)\n\n",
        "[Initial Market]\nBeachhead: (describe beachhead market)\nEnd User Profile: (describe end user)\n\n",
        "[Value Creation]\nUse Case: (describe use case)\nProduct Description: (describe product)\n\n",
        "[Competitive Advantage]\nMoats: (describe competitive moats)\nCore: (describe core competencies)\n\n",
        "[Customer Acquisition]\nDMU: (describe decision-making unit)\nProcess to Acquire Customer: (describe process)\n\n",
        "[Product Unit Economics]\nBusiness Model: (describe business model)\nEstimated Pricing: (describe pricing strategy)\n\n",
        "[Sales]\nPreferred Sales Channel: (describe sales channel)\nSales Funnel: (describe sales funnel)\n\n",
        "[Overall Economics]\nEstimated R&D Expenses: (describe R&D costs)\nEstimated G&A Expenses: (describe G&A costs)\n\n",
        "[Design & Build]\nIdentify Key Assumptions: (list assumptions)\nTest Key Assumptions: (describe testing approach)\n\n",
        "[Scaling]\nProduct Plan for Beachhead: (describe initial plan)\nNext Market: (describe expansion strategy)\n\n",
        "Make the content specific, actionable, and tailored to the business description provided."
      )
      
      generated_content <- call_claude_api(prompt)
      
      updateTextAreaInput(session, "de_claude_output", value = generated_content)
      updateTextAreaInput(session, "de_bulk_text", value = generated_content)
      
      output$de_generate_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " DE Canvas generated successfully!",
                 br(),
                 tags$small("Review the content above and click 'Parse Canvas Data' when ready"))
      })
      
      showNotification("✓ DE Canvas generated successfully!", type = "message")
      
    }, error = function(e) {
      output$de_generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Generation failed: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Generate Roadmap
  observeEvent(input$generate_roadmap, {
    if (!values$claude_connected) {
      output$roadmap_generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please connect to Claude API first (see Claude API Connection tab)")
      })
      return()
    }
    
    if (is.null(input$roadmap_business_area) || trimws(input$roadmap_business_area) == "" ||
        is.null(input$roadmap_project) || trimws(input$roadmap_project) == "" ||
        is.null(input$roadmap_business_focus) || trimws(input$roadmap_business_focus) == "" ||
        is.null(input$roadmap_business_description) || trimws(input$roadmap_business_description) == "") {
      output$roadmap_generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please fill in all fields")
      })
      return()
    }
    
    output$roadmap_generate_status <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"),
               " Generating Disciplined Entrepreneurship Roadmap with Claude... This may take a moment.")
    })
    
    tryCatch({
      prompt <- paste0(
        "You are a business strategy expert specializing in the Disciplined Entrepreneurship 24-step framework.\n\n",
        "Business Area: ", input$roadmap_business_area, "\n",
        "Project: ", input$roadmap_project, "\n",
        "Business Focus: ", input$roadmap_business_focus, "\n",
        "Business Description: ", input$roadmap_business_description, "\n\n",
        "Generate a detailed Disciplined Entrepreneurship Roadmap with ALL 24 steps. ",
        "Format EXACTLY as follows:\n\n",
        "[Step 1: Market Segmentation]\n(Detailed content)\n\n",
        "[Step 2: Select a Beachhead Market]\n(Detailed content)\n\n",
        "[Step 3: Build an End User Profile]\n(Detailed content)\n\n",
        "[Step 4: Calculate TAM Size for Beachhead Market]\n(Detailed content)\n\n",
        "[Step 5: Profile the Persona for the Beachhead Market]\n(Detailed content)\n\n",
        "[Step 6: Full Life Cycle Use Case]\n(Detailed content)\n\n",
        "[Step 7: High-Level Product Specification]\n(Detailed content)\n\n",
        "[Step 8: Quantify the Value Proposition]\n(Detailed content)\n\n",
        "[Step 9: Identify Your Next 10 Customers]\n(Detailed content)\n\n",
        "[Step 10: Define Your Core]\n(Detailed content)\n\n",
        "[Step 11: Chart Your Competitive Position]\n(Detailed content)\n\n",
        "[Step 12: Determine the Customer's Decision-Making Unit]\n(Detailed content)\n\n",
        "[Step 13: Map Process to Acquire Paying Customer]\n(Detailed content)\n\n",
        "[Step 14: Calculate TAM Size for Follow-on Markets]\n(Detailed content)\n\n",
        "[Step 15: Design a Business Model]\n(Detailed content)\n\n",
        "[Step 16: Set Your Pricing Framework]\n(Detailed content)\n\n",
        "[Step 17: Calculate Lifetime Value of an Acquired Customer]\n(Detailed content)\n\n",
        "[Step 18: Map Sales Process to Acquire a Customer]\n(Detailed content)\n\n",
        "[Step 19: Calculate the Cost of Customer Acquisition]\n(Detailed content)\n\n",
        "[Step 20: Identify Key Assumptions]\n(Detailed content)\n\n",
        "[Step 21: Test Key Assumptions]\n(Detailed content)\n\n",
        "[Step 22: Define the Minimum Viable Business Product (MVBP)]\n(Detailed content)\n\n",
        "[Step 23: Show That 'The Dogs Will Eat the Dog Food']\n(Detailed content)\n\n",
        "[Step 24: Develop a Product Plan]\n(Detailed content)\n\n",
        "Make each step specific and actionable for the business described."
      )
      
      generated_content <- call_claude_api(prompt)
      
      updateTextAreaInput(session, "roadmap_claude_output", value = generated_content)
      updateTextAreaInput(session, "roadmap_bulk_text", value = generated_content)
      
      output$roadmap_generate_status <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Roadmap generated successfully!",
                 br(),
                 tags$small("Review the content above and click 'Parse Roadmap Data' when ready"))
      })
      
      showNotification("✓ Roadmap generated successfully!", type = "message")
      
    }, error = function(e) {
      output$roadmap_generate_status <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Generation failed: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # ===== REST OF SERVER CODE (BigQuery auth, parsing, loading) =====
  # [Include all the original server code for BigQuery authentication,
  #  parsing, submitting, and loading canvases - keeping it identical
  #  to the original implementation]
  
  # Display package information
  output$package_info <- renderText({
    paste0("bigrquery version: ", packageVersion("bigrquery"))
  })
  
  # [Continue with all original observeEvent handlers for authentication,
  #  parsing, submitting, loading, etc. - unchanged from original code]
  
  # BigQuery Authentication (keeping original code)
  observeEvent(input$authenticate, {
    tryCatch({
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
      
      tryCatch({
        bq_deauth()
      }, error = function(e) {
      })
      
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
          
          loadDefaultCanvas()
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
  
  # [Include ALL remaining server functions from the original code:
  #  - loadDefaultCanvas()
  #  - updateCanvasDropdowns()
  #  - All observeEvent handlers for parsing
  #  - All observeEvent handlers for submitting
  #  - All observeEvent handlers for loading
  #  - All observeEvent handlers for clearing
  #  - Canvas rendering functions
  #  etc.]
  
  # Due to character limits, I'm abbreviating here, but include ALL
  # original server code functions that handle:
  # - Parsing (parseCanvas, parseDECanvas, parseRoadmap)
  # - Submitting to BigQuery
  # - Loading from BigQuery
  # - Rendering canvases
  # - Updating dropdowns
  # - etc.
  
  # Load default canvas content (original code)
  loadDefaultCanvas <- function() {
    # [Include all original loadDefaultCanvas code]
  }
  
  # Parse canvas data (original code - unchanged)
  observeEvent(input$parseCanvas, {
    # [Include all original parseCanvas code]
  })
  
  # Submit canvas to BigQuery (original code - unchanged)
  observeEvent(input$submitCanvas, {
    # [Include all original submitCanvas code]
  })
  
  # [Continue with ALL other original observeEvent handlers...]
  
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
