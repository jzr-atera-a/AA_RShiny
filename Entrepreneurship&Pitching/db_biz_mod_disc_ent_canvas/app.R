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
library(htmltools)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Business Model Canvas Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("BigQuery Authentication", tabName = "auth", icon = icon("key")),
      menuItem("Bulk Import BM Canvas", tabName = "bulk_import", icon = icon("file-import")),
      menuItem("Bulk Import DE Canvas", tabName = "bulk_import_de", icon = icon("file-upload")),
      menuItem("Bulk Import DE Roadmap", tabName = "bulk_import_de_roadmap", icon = icon("route")),
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
    /* Top Row - 5 boxes (equal height with bottom row) */
    .de-box1 { 
      grid-column: 1; 
      grid-row: 1; 
      background: linear-gradient(135deg, #1E3A8A, #3B82F6); 
      border-color: #1E40AF; 
    }
    
    .de-box4 { 
      grid-column: 2; 
      grid-row: 1; 
      background: linear-gradient(135deg, #B91C1C, #DC2626); 
      border-color: #991B1B; 
    }
    
    .de-box5 { 
      grid-column: 3; 
      grid-row: 1; 
      background: linear-gradient(135deg, #BE185D, #EC4899); 
      border-color: #9F1239; 
    }
    
    .de-box8 { 
      grid-column: 4; 
      grid-row: 1; 
      background: linear-gradient(135deg, #D97706, #F59E0B); 
      border-color: #B45309; 
    }
    
    .de-box9 { 
      grid-column: 5; 
      grid-row: 1; 
      background: linear-gradient(135deg, #047857, #10B981); 
      border-color: #065F46; 
    }
    
    /* Bottom Row - 5 boxes (equal height with top row) */
    .de-box2 { 
      grid-column: 1; 
      grid-row: 2; 
      background: linear-gradient(135deg, #0E7490, #06B6D4); 
      border-color: #155E75; 
    }
    
    .de-box3 { 
      grid-column: 2; 
      grid-row: 2; 
      background: linear-gradient(135deg, #047857, #10B981); 
      border-color: #065F46; 
    }
    
    .de-box6 { 
      grid-column: 3; 
      grid-row: 2; 
      background: linear-gradient(135deg, #6D28D9, #8B5CF6); 
      border-color: #5B21B6; 
    }
    
    .de-box7 { 
      grid-column: 4; 
      grid-row: 2; 
      background: linear-gradient(135deg, #DC2626, #F87171); 
      border-color: #B91C1C; 
    }
    
    .de-box10 { 
      grid-column: 5; 
      grid-row: 2; 
      background: linear-gradient(135deg, #1E293B, #475569); 
      border-color: #334155; 
    }
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


/* Roadmap category colors - matching the image */
.roadmap-cat1 { 
  background: linear-gradient(135deg, #0EA5E9, #38BDF8); 
  border-color: #0284C7; 
  color: white; 
}
.roadmap-cat1 .de-roadmap-number { 
  background: #0EA5E9; 
  color: white; 
}

.roadmap-cat2 { 
  background: linear-gradient(135deg, #3B82F6, #60A5FA); 
  border-color: #2563EB; 
  color: white; 
}
.roadmap-cat2 .de-roadmap-number { 
  background: #3B82F6; 
  color: white; 
}

.roadmap-cat3 { 
  background: linear-gradient(135deg, #1E40AF, #3B82F6); 
  border-color: #1E3A8A; 
  color: white; 
}
.roadmap-cat3 .de-roadmap-number { 
  background: #1E40AF; 
  color: white; 
}

.roadmap-cat4 { 
  background: linear-gradient(135deg, #06B6D4, #22D3EE); 
  border-color: #0891B2; 
  color: white; 
}
.roadmap-cat4 .de-roadmap-number { 
  background: #06B6D4; 
  color: white; 
}

.roadmap-cat5 { 
  background: linear-gradient(135deg, #14B8A6, #2DD4BF); 
  border-color: #0D9488; 
  color: white; 
}
.roadmap-cat5 .de-roadmap-number { 
  background: #14B8A6; 
  color: white; 
}

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
      
      # Tab: Bulk Import Disciplined Entrepreneurship Canvas
      tabItem(tabName = "bulk_import_de",
              fluidRow(
                box(
                  title = "Disciplined Entrepreneurship Canvas - Bulk Import", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("Import Disciplined Entrepreneurship Canvas Data"),
                  p("Enter your business identification and paste the 10 sections of your Disciplined Entrepreneurship Canvas."),
                  
                  fluidRow(
                    column(4,
                           textInput("de_business_area", 
                                     "Business Area (max 32 chars):", 
                                     placeholder = "e.g., Technology, Healthcare",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("de_project", 
                                     "Project (max 32 chars):", 
                                     placeholder = "e.g., Mobile App Development",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("de_business_focus", 
                                     "Business Focus (max 32 chars):", 
                                     placeholder = "e.g., B2B SaaS",
                                     width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements for Bulk Import:"),
                      tags$ul(
                        tags$li("Start each section with its title in brackets: [Raison d'Être], [Initial Market], etc."),
                        tags$li("Content should follow immediately after each title"),
                        tags$li("Separate sections with blank lines"),
                        tags$li("Required sections: Raison d'Être, Initial Market, Value Creation, Competitive Advantage, Customer Acquisition, Product Unit Economics, Sales, Overall Economics, Design & Build, Scaling")
                      )
                  ),
                  
                  textAreaInput("de_bulk_text", 
                                "Paste Disciplined Entrepreneurship Canvas Content:",
                                height = "400px",
                                width = "100%",
                                placeholder = "[Raison d'Être]\nMission: ...\nPassion: ...\nValues: ...\n\n[Initial Market]\nBeachhead: ...\nEnd User Profile: ...\n\n[Value Creation]\nUse Case: ...\nProduct Description: ...\n\n[Competitive Advantage]\nMoats: ...\nCore: ...\n\n[Customer Acquisition]\nDMU: ...\nProcess to Acquire Customer: ...\n\n[Product Unit Economics]\nBusiness Model: ...\nEstimated Pricing: ...\n\n[Sales]\nPreferred Sales Channel: ...\nSales Funnel: ...\n\n[Overall Economics]\nEstimated R&D Expenses: ...\nEstimated G&A Expenses: ...\n\n[Design & Build]\nIdentify Key Assumptions: ...\nTest Key Assumptions: ...\n\n[Scaling]\nProduct Plan for Beachhead: ...\nNext Market: ..."),
                  
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
      
      # Tab: Bulk Import Disciplined Entrepreneurship Roadmap
      tabItem(tabName = "bulk_import_de_roadmap",
              fluidRow(
                box(
                  title = "Disciplined Entrepreneurship Roadmap - Bulk Import", 
                  status = "primary", 
                  solidHeader = TRUE, 
                  width = 12,
                  
                  h4("Import Disciplined Entrepreneurship Roadmap Data"),
                  p("Enter your business identification and paste the 24 steps of your Disciplined Entrepreneurship Roadmap."),
                  
                  fluidRow(
                    column(4,
                           textInput("roadmap_business_area", 
                                     "Business Area (max 32 chars):", 
                                     placeholder = "e.g., Technology, Healthcare",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("roadmap_project", 
                                     "Project (max 32 chars):", 
                                     placeholder = "e.g., Mobile App Development",
                                     width = "100%")
                    ),
                    column(4,
                           textInput("roadmap_business_focus", 
                                     "Business Focus (max 32 chars):", 
                                     placeholder = "e.g., B2B SaaS",
                                     width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  div(class = "alert alert-info",
                      tags$strong("Format Requirements for Bulk Import:"),
                      tags$ul(
                        tags$li("Start each step with its number and title in brackets: [Step 1: Market Segmentation], [Step 2: Select a Beachhead Market], etc."),
                        tags$li("Content should follow immediately after each step title"),
                        tags$li("Separate steps with blank lines"),
                        tags$li("All 24 steps are required in sequential order (Step 1 through Step 24)")
                      )
                  ),
                  
                  textAreaInput("roadmap_bulk_text", 
                                "Paste Disciplined Entrepreneurship Roadmap Content:",
                                height = "400px",
                                width = "100%",
                                placeholder = "[Step 1: Market Segmentation]\nYour market segmentation content here...\n\n[Step 2: Select a Beachhead Market]\nYour beachhead market selection here...\n\n[Step 3: Build an End User Profile]\nYour end user profile here...\n\n[Continue with all 24 steps...]"),
                  
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
      
      # Tab : Business Model Canvas View
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
      
      # Tab : Disciplined Entrepreneurship Canvas
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
                           # Box 1: Raison d'Être
                           div(class = "de-box de-box1",
                               div(class = "de-box-number", "1"),
                               div(class = "de-box-title", "Raison d'Être"),
                               div(class = "de-box-subtitle", "Why do you in business?"),
                               htmlOutput("de_box1_content")
                           ),
                           
                           # Box 2: Initial Market
                           div(class = "de-box de-box2",
                               div(class = "de-box-number", "2"),
                               div(class = "de-box-title", "Initial Market"),
                               div(class = "de-box-subtitle", "Who is your customer?"),
                               htmlOutput("de_box2_content")
                           ),
                           
                           # Box 3: Value Creation
                           div(class = "de-box de-box3",
                               div(class = "de-box-number", "3"),
                               div(class = "de-box-title", "Value Creation"),
                               div(class = "de-box-subtitle", "What can you do for your customer?"),
                               htmlOutput("de_box3_content")
                           ),
                           
                           # Box 4: Competitive Advantage
                           div(class = "de-box de-box4",
                               div(class = "de-box-number", "4"),
                               div(class = "de-box-title", "Competitive Advantage"),
                               div(class = "de-box-subtitle", "Why you?"),
                               htmlOutput("de_box4_content")
                           ),
                           
                           # Box 5: Customer Acquisition
                           div(class = "de-box de-box5",
                               div(class = "de-box-number", "5"),
                               div(class = "de-box-title", "Customer Acquisition"),
                               div(class = "de-box-subtitle", "How does your customer acquire your product?"),
                               htmlOutput("de_box5_content")
                           ),
                           
                           # Box 6: Product Unit Economics
                           div(class = "de-box de-box6",
                               div(class = "de-box-number", "6"),
                               div(class = "de-box-title", "Product Unit Economics"),
                               div(class = "de-box-subtitle", "Can you make money?"),
                               htmlOutput("de_box6_content")
                           ),
                           
                           # Box 7: Sales
                           div(class = "de-box de-box7",
                               div(class = "de-box-number", "7"),
                               div(class = "de-box-title", "Sales"),
                               div(class = "de-box-subtitle", "How do you sell your product?"),
                               htmlOutput("de_box7_content")
                           ),
                           
                           # Box 8: Overall Economics
                           div(class = "de-box de-box8",
                               div(class = "de-box-number", "8"),
                               div(class = "de-box-title", "Overall Economics"),
                               div(class = "de-box-subtitle", "Does your product make money?"),
                               htmlOutput("de_box8_content")
                           ),
                           
                           # Box 9: Design & Build
                           div(class = "de-box de-box9",
                               div(class = "de-box-number", "9"),
                               div(class = "de-box-title", "Design & Build"),
                               div(class = "de-box-subtitle", "How do you produce the product?"),
                               htmlOutput("de_box9_content")
                           ),
                           
                           # Box 10: Scaling
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
      
      # Tab : Disciplined Entrepreneurship Roadmap
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
                       div(class = "de-roadmap-container",
                           # Row 1
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "1"),
                                   div(class = "de-roadmap-title", "Market Segmentation"),
                                   div(class = "de-roadmap-description", "Identify broad market opportunities and segment into distinct groups")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "2"),
                                   div(class = "de-roadmap-title", "Select a Beachhead Market"),
                                   div(class = "de-roadmap-description", "Choose the best target market to focus initial resources")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "3"),
                                   div(class = "de-roadmap-title", "Build an End User Profile"),
                                   div(class = "de-roadmap-description", "Define the characteristics of your target end user")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "4"),
                                   div(class = "de-roadmap-title", "Calculate TAM Size for Beachhead Market"),
                                   div(class = "de-roadmap-description", "Quantify the Total Addressable Market revenue opportunity")
                               )
                           ),
                           
                           # Row 2
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "5"),
                                   div(class = "de-roadmap-title", "Profile the Persona for the Beachhead Market"),
                                   div(class = "de-roadmap-description", "Create detailed persona including demographics and behaviors")
                               ),
                               div(class = "de-roadmap-box roadmap-cat2",
                                   div(class = "de-roadmap-number", "6"),
                                   div(class = "de-roadmap-title", "Full Life Cycle Use Case"),
                                   div(class = "de-roadmap-description", "Map complete customer journey with your product")
                               ),
                               div(class = "de-roadmap-box roadmap-cat2",
                                   div(class = "de-roadmap-number", "7"),
                                   div(class = "de-roadmap-title", "High-Level Product Specification"),
                                   div(class = "de-roadmap-description", "Define key features and specifications of your product")
                               ),
                               div(class = "de-roadmap-box roadmap-cat2",
                                   div(class = "de-roadmap-number", "8"),
                                   div(class = "de-roadmap-title", "Quantify the Value Proposition"),
                                   div(class = "de-roadmap-description", "Calculate tangible value delivered to customers")
                               )
                           ),
                           
                           # Row 3
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "9"),
                                   div(class = "de-roadmap-title", "Identify Your Next 10 Customers"),
                                   div(class = "de-roadmap-description", "List specific target customers for initial sales")
                               ),
                               div(class = "de-roadmap-box roadmap-cat2",
                                   div(class = "de-roadmap-number", "10"),
                                   div(class = "de-roadmap-title", "Define Your Core"),
                                   div(class = "de-roadmap-description", "Identify unique capabilities that differentiate you")
                               ),
                               div(class = "de-roadmap-box roadmap-cat2",
                                   div(class = "de-roadmap-number", "11"),
                                   div(class = "de-roadmap-title", "Chart Your Competitive Position"),
                                   div(class = "de-roadmap-description", "Analyze competitive landscape and your positioning")
                               ),
                               div(class = "de-roadmap-box roadmap-cat1",
                                   div(class = "de-roadmap-number", "12"),
                                   div(class = "de-roadmap-title", "Determine the Customer's Decision-Making Unit"),
                                   div(class = "de-roadmap-description", "Identify all stakeholders involved in purchase decision")
                               )
                           ),
                           
                           # Row 4
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat3",
                                   div(class = "de-roadmap-number", "13"),
                                   div(class = "de-roadmap-title", "Map Process to Acquire Paying Customer"),
                                   div(class = "de-roadmap-description", "Document steps to convert prospect to paying customer")
                               ),
                               div(class = "de-roadmap-box roadmap-cat3",
                                   div(class = "de-roadmap-number", "14"),
                                   div(class = "de-roadmap-title", "Calculate TAM Size for Follow-on Markets"),
                                   div(class = "de-roadmap-description", "Quantify opportunities in adjacent market segments")
                               ),
                               div(class = "de-roadmap-box roadmap-cat4",
                                   div(class = "de-roadmap-number", "15"),
                                   div(class = "de-roadmap-title", "Design a Business Model"),
                                   div(class = "de-roadmap-description", "Define how you create, deliver, and capture value")
                               ),
                               div(class = "de-roadmap-box roadmap-cat4",
                                   div(class = "de-roadmap-number", "16"),
                                   div(class = "de-roadmap-title", "Set Your Pricing Framework"),
                                   div(class = "de-roadmap-description", "Establish pricing strategy aligned with value delivered")
                               )
                           ),
                           
                           # Row 5
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat4",
                                   div(class = "de-roadmap-number", "17"),
                                   div(class = "de-roadmap-title", "Calculate Lifetime Value of an Acquired Customer"),
                                   div(class = "de-roadmap-description", "Determine total revenue from average customer relationship")
                               ),
                               div(class = "de-roadmap-box roadmap-cat3",
                                   div(class = "de-roadmap-number", "18"),
                                   div(class = "de-roadmap-title", "Map Sales Process to Acquire a Customer"),
                                   div(class = "de-roadmap-description", "Document complete sales cycle and touchpoints")
                               ),
                               div(class = "de-roadmap-box roadmap-cat4",
                                   div(class = "de-roadmap-number", "19"),
                                   div(class = "de-roadmap-title", "Calculate the Cost of Customer Acquisition"),
                                   div(class = "de-roadmap-description", "Determine total cost to acquire one customer")
                               ),
                               div(class = "de-roadmap-box roadmap-cat4",
                                   div(class = "de-roadmap-number", "20"),
                                   div(class = "de-roadmap-title", "Identify Key Assumptions"),
                                   div(class = "de-roadmap-description", "List critical assumptions that must be validated")
                               )
                           ),
                           
                           # Row 6
                           div(class = "de-roadmap-grid",
                               div(class = "de-roadmap-box roadmap-cat5",
                                   div(class = "de-roadmap-number", "21"),
                                   div(class = "de-roadmap-title", "Test Key Assumptions"),
                                   div(class = "de-roadmap-description", "Run experiments to validate or invalidate assumptions")
                               ),
                               div(class = "de-roadmap-box roadmap-cat5",
                                   div(class = "de-roadmap-number", "22"),
                                   div(class = "de-roadmap-title", "Define the Minimum Viable Business Product (MVBP)"),
                                   div(class = "de-roadmap-description", "Create simplest product that delivers core value proposition")
                               ),
                               div(class = "de-roadmap-box roadmap-cat5",
                                   div(class = "de-roadmap-number", "23"),
                                   div(class = "de-roadmap-title", 'Show That "The Dogs Will Eat the Dog Food"'),
                                   div(class = "de-roadmap-description", "Prove customers will actually pay for your product")
                               ),
                               div(class = "de-roadmap-box roadmap-cat5",
                                   div(class = "de-roadmap-number", "24"),
                                   div(class = "de-roadmap-title", "Develop a Product Plan"),
                                   div(class = "de-roadmap-description", "Create roadmap for product development and scaling")
                               )
                           ),
                           
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
    parsed_de_canvas = NULL,
    parsed_roadmap = NULL, 
    current_canvas = NULL
  )
  
  # Display package information
  output$package_info <- renderText({
    paste0("bigrquery version: ", packageVersion("bigrquery"))
  })
  
  # Authentication (keeping original code)
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
    output$canvas_key_partners <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>Who are our Key Partners?</strong></p>
          <p><strong>Who are our key suppliers?</strong></p>
          <p><strong>Which Key Resources are we acquiring from partners?</strong></p>
          <p><strong>Which Key Activities do partners perform?</strong></p>
          <hr>
          <p><strong>Motivations for partnerships:</strong></p>
          <ul>
            <li>Optimization and economy of scale</li>
            <li>Reduction of risk and uncertainty</li>
            <li>Acquisition of particular resources and activities</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_key_activities <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>What Key Activities does our Value Proposition require?</strong></p>
          <p><strong>Our Distribution Channels?</strong></p>
          <p><strong>Customer Relationships?</strong></p>
          <p><strong>Revenue Streams?</strong></p>
          <hr>
          <p><strong>Categories:</strong></p>
          <ul>
            <li>Production</li>
            <li>Problem Solving</li>
            <li>Platform/Network</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_key_resources <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>What Key Resources does our Value Proposition require?</strong></p>
          <p><strong>Our Distribution Channels?</strong></p>
          <p><strong>Customer Relationships?</strong></p>
          <p><strong>Revenue Streams?</strong></p>
          <hr>
          <p><strong>Types of resources:</strong></p>
          <ul>
            <li>Physical</li>
            <li>Intellectual</li>
            <li>Human</li>
            <li>Financial</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_value_propositions <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>What value do we deliver to the customer?</strong></p>
          <p><strong>Which one of our customer\'s problems are we helping to solve?</strong></p>
          <p><strong>What bundles of products and services are we offering to each Customer Segment?</strong></p>
          <p><strong>Which customer needs are we satisfying?</strong></p>
          <hr>
          <p><strong>Characteristics:</strong></p>
          <ul>
            <li>Newness</li>
            <li>Performance</li>
            <li>Customization</li>
            <li>\'Getting the Job Done\'</li>
            <li>Design</li>
            <li>Brand/Status</li>
            <li>Price</li>
            <li>Cost Reduction</li>
            <li>Risk Reduction</li>
            <li>Accessibility</li>
            <li>Convenience/Usability</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_customer_relationships <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>What type of relationship does each Customer Segment expect?</strong></p>
          <p><strong>Which ones have we established?</strong></p>
          <p><strong>How are they integrated?</strong></p>
          <p><strong>How costly are they?</strong></p>
          <hr>
          <p><strong>Categories:</strong></p>
          <ul>
            <li>Personal assistance</li>
            <li>Dedicated assistance</li>
            <li>Self-service</li>
            <li>Automated services</li>
            <li>Communities</li>
            <li>Co-creation</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_channels <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>Through which Channels do our Customer Segments want to be reached?</strong></p>
          <p><strong>How are we reaching them now?</strong></p>
          <p><strong>How are our Channels integrated?</strong></p>
          <p><strong>Which ones work best?</strong></p>
          <p><strong>Which ones are most cost-efficient?</strong></p>
          <hr>
          <p><strong>Channel phases:</strong></p>
          <ul>
            <li>1. Awareness</li>
            <li>2. Evaluation</li>
            <li>3. Purchase</li>
            <li>4. Delivery</li>
            <li>5. After sales</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_customer_segments <- renderUI({
      HTML('
        <div class="section-content">
          <p><strong>For whom are we creating value?</strong></p>
          <p><strong>Who are our most important customers?</strong></p>
          <hr>
          <p><strong>Groups of people or organizations:</strong></p>
          <ul>
            <li>Mass market</li>
            <li>Niche market</li>
            <li>Segmented</li>
            <li>Diversified</li>
            <li>Multi-sided platforms</li>
          </ul>
          <hr>
          <p><strong>Customer characteristics:</strong></p>
          <ul>
            <li>Common needs</li>
            <li>Common behaviors</li>
            <li>Common attributes</li>
            <li>Profitability</li>
            <li>Distribution channels</li>
            <li>Relationship types</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_cost_structure <- renderUI({
      HTML('
        <div class="section-content two-column-content">
          <p><strong>What are the most important costs inherent in our business model?</strong></p>
          <p><strong>Which Key Resources are most expensive?</strong></p>
          <p><strong>Which Key Activities are most expensive?</strong></p>
          <hr>
          <p><strong>Is your business more:</strong></p>
          <ul>
            <li>Cost Driven (leanest cost structure, low price value proposition, maximum automation, extensive outsourcing)</li>
            <li>Value Driven (focused on value creation, premium value propositions)</li>
          </ul>
          <hr>
          <p><strong>Sample characteristics:</strong></p>
          <ul>
            <li>Fixed Costs</li>
            <li>Variable costs</li>
            <li>Economies of scale</li>
            <li>Economies of scope</li>
          </ul>
        </div>
      ')
    })
    
    output$canvas_revenue_streams <- renderUI({
      HTML('
        <div class="section-content two-column-content">
          <p><strong>What value are our customers really willing to pay for?</strong></p>
          <p><strong>For what do they currently pay?</strong></p>
          <p><strong>How are they currently paying?</strong></p>
          <p><strong>How would they prefer to pay?</strong></p>
          <p><strong>How much does each Revenue Stream contribute to overall revenues?</strong></p>
          <hr>
          <p><strong>Types:</strong></p>
          <ul>
            <li>Asset sale</li>
            <li>Usage fee</li>
            <li>Subscription fees</li>
            <li>Lending/Renting/Leasing</li>
            <li>Licensing</li>
            <li>Brokerage fees</li>
            <li>Advertising</li>
          </ul>
          <hr>
          <p><strong>Fixed Menu Pricing:</strong></p>
          <ul>
            <li>List price</li>
            <li>Product feature dependent</li>
            <li>Customer segment dependent</li>
            <li>Volume dependent</li>
          </ul>
          <hr>
          <p><strong>Dynamic Pricing:</strong></p>
          <ul>
            <li>Negotiation</li>
            <li>Yield management</li>
            <li>Real-time-market</li>
          </ul>
        </div>
      ')
    })
    
    # Initialize DE Canvas with placeholder content
    output$de_box1_content <- renderUI({
      HTML('<div class="de-box-content">Mission, Passion, Values, Initial Assets, Initial Idea</div>')
    })
    
    output$de_box2_content <- renderUI({
      HTML('<div class="de-box-content">Beachhead, End User Profile, TAM, Persona, First 10 Customers</div>')
    })
    
    output$de_box3_content <- renderUI({
      HTML('<div class="de-box-content">Use Case, Product Description, Problem Being Solved, Quantified Value Proposition</div>')
    })
    
    output$de_box4_content <- renderUI({
      HTML('<div class="de-box-content">Moats, Core, Competitive Positioning</div>')
    })
    
    output$de_box5_content <- renderUI({
      HTML('<div class="de-box-content">DMU, Process to Acquire Customer, Windows of Opportunity, Possible Triggers</div>')
    })
    
    output$de_box6_content <- renderUI({
      HTML('<div class="de-box-content">Business Model, Estimated Pricing, Short/Medium/Long Term LTV and COCA</div>')
    })
    
    output$de_box7_content <- renderUI({
      HTML('<div class="de-box-content">Preferred Sales Channel, Sales Funnel, Short/Medium/Long Term Mix</div>')
    })
    
    output$de_box8_content <- renderUI({
      HTML('<div class="de-box-content">Estimated R&D Expenses, Estimated G&A Expenses, LTV/COCA Ratio High Enough</div>')
    })
    
    output$de_box9_content <- renderUI({
      HTML('<div class="de-box-content">Identify Key Assumptions, Test Key Assumptions, MVBP, Tracking Metrics</div>')
    })
    
    output$de_box10_content <- renderUI({
      HTML('<div class="de-box-content">Product Plan for Beachhead, Next Market, Product Plan Beyond Beachhead, Follow-on TAM</div>')
    })
  }
  
  # Update canvas dropdowns
  updateCanvasDropdowns <- function() {
    if (!values$authenticated) return()
    
    tryCatch({
      query <- sprintf("SELECT DISTINCT business_area FROM `%s` WHERE business_area IS NOT NULL ORDER BY business_area", 
                       values$full_table_id)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "select_business_area", 
                          choices = c("Select..." = "", result$business_area))
        updateSelectInput(session, "de_select_business_area", 
                          choices = c("Select..." = "", result$business_area))
        updateSelectInput(session, "roadmap_select_business_area", 
                          choices = c("Select..." = "", result$business_area))
      }
    }, error = function(e) {
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
  
  # ===== DISCIPLINED ENTREPRENEURSHIP CANVAS BULK IMPORT LOGIC =====
  
  # Parse DE Canvas data
  observeEvent(input$parseDECanvas, {
    
    if (is.null(input$de_bulk_text) || trimws(input$de_bulk_text) == "") {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please paste canvas content to parse")
      })
      return()
    }
    
    if (is.null(input$de_business_area) || trimws(input$de_business_area) == "") {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Area")
      })
      return()
    }
    
    if (is.null(input$de_project) || trimws(input$de_project) == "") {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Project name")
      })
      return()
    }
    
    if (is.null(input$de_business_focus) || trimws(input$de_business_focus) == "") {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Focus")
      })
      return()
    }
    
    output$deBulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Parsing canvas data...")
    })
    
    tryCatch({
      text <- input$de_bulk_text
      
      # Parse the 10 sections
      raison_detre <- str_match(text, "(?i)\\[Raison d'Être\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      initial_market <- str_match(text, "(?i)\\[Initial Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      value_creation <- str_match(text, "(?i)\\[Value Creation\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      competitive_advantage <- str_match(text, "(?i)\\[Competitive Advantage\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      customer_acquisition <- str_match(text, "(?i)\\[Customer Acquisition\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      product_unit_economics <- str_match(text, "(?i)\\[Product Unit Economics\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      sales <- str_match(text, "(?i)\\[Sales\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      overall_economics <- str_match(text, "(?i)\\[Overall Economics\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      design_build <- str_match(text, "(?i)\\[Design & Build\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      scaling <- str_match(text, "(?i)\\[Scaling\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      
      # Check if all sections are found
      missing_sections <- c()
      if (is.na(raison_detre)) missing_sections <- c(missing_sections, "Raison d'Être")
      if (is.na(initial_market)) missing_sections <- c(missing_sections, "Initial Market")
      if (is.na(value_creation)) missing_sections <- c(missing_sections, "Value Creation")
      if (is.na(competitive_advantage)) missing_sections <- c(missing_sections, "Competitive Advantage")
      if (is.na(customer_acquisition)) missing_sections <- c(missing_sections, "Customer Acquisition")
      if (is.na(product_unit_economics)) missing_sections <- c(missing_sections, "Product Unit Economics")
      if (is.na(sales)) missing_sections <- c(missing_sections, "Sales")
      if (is.na(overall_economics)) missing_sections <- c(missing_sections, "Overall Economics")
      if (is.na(design_build)) missing_sections <- c(missing_sections, "Design & Build")
      if (is.na(scaling)) missing_sections <- c(missing_sections, "Scaling")
      
      if (length(missing_sections) > 0) {
        stop(paste("Missing sections:", paste(missing_sections, collapse = ", "), 
                   "\n\nPlease ensure all 10 sections are included with proper [Section Name] headers."))
      }
      
      # Store parsed data
      values$parsed_de_canvas <- list(
        business_area = substr(trimws(input$de_business_area), 1, 32),
        project = substr(trimws(input$de_project), 1, 32),
        business_focus = substr(trimws(input$de_business_focus), 1, 32),
        raison_detre = trimws(raison_detre),
        initial_market = trimws(initial_market),
        value_creation = trimws(value_creation),
        competitive_advantage = trimws(competitive_advantage),
        customer_acquisition = trimws(customer_acquisition),
        product_unit_economics = trimws(product_unit_economics),
        sales = trimws(sales),
        overall_economics = trimws(overall_economics),
        design_build = trimws(design_build),
        scaling = trimws(scaling)
      )
      
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully parsed Disciplined Entrepreneurship Canvas!",
                 br(),
                 tags$small("Business Area: ", values$parsed_de_canvas$business_area),
                 br(),
                 tags$small("Project: ", values$parsed_de_canvas$project),
                 br(),
                 tags$small("Business Focus: ", values$parsed_de_canvas$business_focus))
      })
      
      output$deParseInfo <- renderUI({
        tags$p(
          tags$strong("Parsed DE Canvas Summary:"),
          br(),
          paste("Business Area:", values$parsed_de_canvas$business_area),
          br(),
          paste("Project:", values$parsed_de_canvas$project),
          br(),
          paste("Business Focus:", values$parsed_de_canvas$business_focus),
          br(),
          "All 10 sections successfully parsed"
        )
      })
      
      output$deParsedPreview <- renderText({
        paste0(
          "Business Area: ", values$parsed_de_canvas$business_area, "\n",
          "Project: ", values$parsed_de_canvas$project, "\n",
          "Business Focus: ", values$parsed_de_canvas$business_focus, "\n\n",
          "Raison d'Être: ", substr(values$parsed_de_canvas$raison_detre, 1, 100), "...\n\n",
          "Initial Market: ", substr(values$parsed_de_canvas$initial_market, 1, 100), "...\n\n",
          "Value Creation: ", substr(values$parsed_de_canvas$value_creation, 1, 100), "...\n\n",
          "Competitive Advantage: ", substr(values$parsed_de_canvas$competitive_advantage, 1, 100), "...\n\n",
          "Customer Acquisition: ", substr(values$parsed_de_canvas$customer_acquisition, 1, 100), "...\n\n",
          "Product Unit Economics: ", substr(values$parsed_de_canvas$product_unit_economics, 1, 100), "...\n\n",
          "Sales: ", substr(values$parsed_de_canvas$sales, 1, 100), "...\n\n",
          "Overall Economics: ", substr(values$parsed_de_canvas$overall_economics, 1, 100), "...\n\n",
          "Design & Build: ", substr(values$parsed_de_canvas$design_build, 1, 100), "...\n\n",
          "Scaling: ", substr(values$parsed_de_canvas$scaling, 1, 100), "..."
        )
      })
      
      showNotification("✓ DE Canvas parsed successfully!", type = "message")
      
    }, error = function(e) {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Parsing failed: ",
                 br(),
                 tags$small(e$message))
      })
      values$parsed_de_canvas <- NULL
      output$deParseInfo <- renderUI(NULL)
      output$deParsedPreview <- renderText("")
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Submit DE Canvas to BigQuery
  observeEvent(input$submitDECanvas, {
    
    if (!values$authenticated) {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    if (is.null(values$parsed_de_canvas)) {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please parse the canvas first by clicking 'Parse Canvas Data'")
      })
      return()
    }
    
    output$deBulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Submitting to BigQuery... Please wait.")
    })
    
    tryCatch({
      # Generate unique canvas ID
      canvas_id <- paste0(
        gsub("[^A-Za-z0-9]", "_", values$parsed_de_canvas$business_area), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_de_canvas$project), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_de_canvas$business_focus), "_",
        format(Sys.time(), "%Y%m%d%H%M%S")
      )
      
      # Create DE Canvas table if it doesn't exist
      de_table_id <- paste0(values$project_id, ".", values$dataset_id, ".disciplined_entrepreneurship_canvas")
      
      create_de_table_query <- sprintf("
      CREATE TABLE IF NOT EXISTS `%s` (
        canvas_id STRING NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        business_area STRING,
        project STRING,
        business_focus STRING,
        raison_detre STRING,
        initial_market STRING,
        value_creation STRING,
        competitive_advantage STRING,
        customer_acquisition STRING,
        product_unit_economics STRING,
        sales STRING,
        overall_economics STRING,
        design_build STRING,
        scaling STRING
      )", de_table_id)
      
      tryCatch({
        bq_project_query(values$project_id, create_de_table_query)
      }, error = function(e) {
        # Table might already exist
      })
      
      # Escape single quotes in all fields
      canvas_id_clean <- gsub("'", "\\\\'", canvas_id)
      business_area_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$business_area)
      project_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$project)
      business_focus_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$business_focus)
      raison_detre_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$raison_detre)
      initial_market_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$initial_market)
      value_creation_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$value_creation)
      competitive_advantage_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$competitive_advantage)
      customer_acquisition_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$customer_acquisition)
      product_unit_economics_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$product_unit_economics)
      sales_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$sales)
      overall_economics_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$overall_economics)
      design_build_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$design_build)
      scaling_clean <- gsub("'", "\\\\'", values$parsed_de_canvas$scaling)
      
      insert_query <- sprintf("
      INSERT INTO `%s` 
      (canvas_id, created_at, updated_at, business_area, project, business_focus, 
       raison_detre, initial_market, value_creation, competitive_advantage, 
       customer_acquisition, product_unit_economics, sales, overall_economics, 
       design_build, scaling) 
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
        '%s',
        '%s'
      )",
                              de_table_id,
                              canvas_id_clean,
                              business_area_clean,
                              project_clean,
                              business_focus_clean,
                              raison_detre_clean,
                              initial_market_clean,
                              value_creation_clean,
                              competitive_advantage_clean,
                              customer_acquisition_clean,
                              product_unit_economics_clean,
                              sales_clean,
                              overall_economics_clean,
                              design_build_clean,
                              scaling_clean
      )
      
      bq_project_query(values$project_id, insert_query)
      
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully submitted Disciplined Entrepreneurship Canvas to BigQuery!",
                 br(),
                 tags$small("Canvas ID: ", canvas_id))
      })
      
      showNotification("✓ DE Canvas submitted successfully!", type = "message")
      
      # Update dropdowns
      updateCanvasDropdowns()
      
    }, error = function(e) {
      output$deBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Error submitting to BigQuery: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Clear DE Canvas bulk text
  observeEvent(input$clearDECanvas, {
    updateTextInput(session, "de_business_area", value = "")
    updateTextInput(session, "de_project", value = "")
    updateTextInput(session, "de_business_focus", value = "")
    updateTextAreaInput(session, "de_bulk_text", value = "")
    values$parsed_de_canvas <- NULL
    output$deBulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " All fields cleared. Ready for new input.")
    })
    output$deParseInfo <- renderUI(NULL)
    output$deParsedPreview <- renderText("")
  })
  
  # Similar observers for DE Canvas and Roadmap dropdowns
  observeEvent(input$de_select_business_area, {
    if (input$de_select_business_area == "" || !values$authenticated) return()
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$de_select_business_area)
      query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                       values$full_table_id, business_area_clean)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "de_select_project", 
                          choices = c("Select..." = "", result$project))
      } else {
        updateSelectInput(session, "de_select_project", choices = c("No projects available" = ""))
      }
    }, error = function(e) {
      showNotification(paste("Error loading projects:", e$message), type = "error")
    })
  })
  
  observeEvent(input$roadmap_select_business_area, {
    if (input$roadmap_select_business_area == "" || !values$authenticated) return()
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$roadmap_select_business_area)
      query <- sprintf("SELECT DISTINCT project FROM `%s` WHERE business_area = '%s' AND project IS NOT NULL ORDER BY project", 
                       values$full_table_id, business_area_clean)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "roadmap_select_project", 
                          choices = c("Select..." = "", result$project))
      } else {
        updateSelectInput(session, "roadmap_select_project", choices = c("No projects available" = ""))
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
  
  observeEvent(input$de_select_project, {
    if (input$de_select_project == "" || !values$authenticated) return()
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$de_select_business_area)
      project_clean <- gsub("'", "\\\\'", input$de_select_project)
      query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                       values$full_table_id, business_area_clean, project_clean)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "de_select_business_focus", 
                          choices = c("Select..." = "", result$business_focus))
      } else {
        updateSelectInput(session, "de_select_business_focus", choices = c("No business focus available" = ""))
      }
    }, error = function(e) {
      showNotification(paste("Error loading business focus:", e$message), type = "error")
    })
  })
  
  observeEvent(input$roadmap_select_project, {
    if (input$roadmap_select_project == "" || !values$authenticated) return()
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$roadmap_select_business_area)
      project_clean <- gsub("'", "\\\\'", input$roadmap_select_project)
      query <- sprintf("SELECT DISTINCT business_focus FROM `%s` WHERE business_area = '%s' AND project = '%s' AND business_focus IS NOT NULL ORDER BY business_focus", 
                       values$full_table_id, business_area_clean, project_clean)
      job <- bq_project_query(values$project_id, query)
      result <- bq_table_download(job)
      
      if (nrow(result) > 0) {
        updateSelectInput(session, "roadmap_select_business_focus", 
                          choices = c("Select..." = "", result$business_focus))
      } else {
        updateSelectInput(session, "roadmap_select_business_focus", choices = c("No business focus available" = ""))
      }
    }, error = function(e) {
      showNotification(paste("Error loading business focus:", e$message), type = "error")
    })
  })
  
  # Parse canvas data (keeping original code)
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
      
      key_partners <- str_match(text, "(?i)\\[Key Partners\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      key_activities <- str_match(text, "(?i)\\[Key Activities\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      key_resources <- str_match(text, "(?i)\\[Key Resources\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      value_propositions <- str_match(text, "(?i)\\[Value Propositions\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      customer_relationships <- str_match(text, "(?i)\\[Customer Relationships\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      channels <- str_match(text, "(?i)\\[Channels\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      customer_segments <- str_match(text, "(?i)\\[Customer Segments\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      cost_structure <- str_match(text, "(?i)\\[Cost Structure\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      revenue_streams <- str_match(text, "(?i)\\[Revenue Streams\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      
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
  
  # Submit canvas to BigQuery (UPDATED VERSION - APPEND MODE)
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
      
      # Create a data frame for upload
      canvas_data <- data.frame(
        canvas_id = canvas_id,
        created_at = Sys.time(),
        updated_at = Sys.time(),
        business_area = values$parsed_canvas$business_area,
        project = values$parsed_canvas$project,
        business_focus = values$parsed_canvas$business_focus,
        key_partners = values$parsed_canvas$key_partners,
        key_activities = values$parsed_canvas$key_activities,
        key_resources = values$parsed_canvas$key_resources,
        value_propositions = values$parsed_canvas$value_propositions,
        customer_relationships = values$parsed_canvas$customer_relationships,
        channels = values$parsed_canvas$channels,
        customer_segments = values$parsed_canvas$customer_segments,
        cost_structure = values$parsed_canvas$cost_structure,
        revenue_streams = values$parsed_canvas$revenue_streams,
        stringsAsFactors = FALSE
      )
      
      # Get table reference
      table_ref <- bq_table(values$project_id, values$dataset_id, values$table_id)
      
      # Upload data frame to BigQuery with APPEND mode
      bq_table_upload(table_ref, canvas_data, fields = NULL, write_disposition = "WRITE_APPEND")
      
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
  
  # Clear bulk text (keeping original code)
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
  
  # ===== DISCIPLINED ENTREPRENEURSHIP ROADMAP BULK IMPORT LOGIC =====
  
  # Parse Roadmap data
  observeEvent(input$parseRoadmap, {
    
    if (is.null(input$roadmap_bulk_text) || trimws(input$roadmap_bulk_text) == "") {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please paste roadmap content to parse")
      })
      return()
    }
    
    if (is.null(input$roadmap_business_area) || trimws(input$roadmap_business_area) == "") {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Area")
      })
      return()
    }
    
    if (is.null(input$roadmap_project) || trimws(input$roadmap_project) == "") {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Project name")
      })
      return()
    }
    
    if (is.null(input$roadmap_business_focus) || trimws(input$roadmap_business_focus) == "") {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Focus")
      })
      return()
    }
    
    output$roadmapBulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Parsing roadmap data...")
    })
    
    tryCatch({
      text <- input$roadmap_bulk_text
      
      # Parse all 24 steps
      step_01 <- str_match(text, "(?i)\\[Step 1:?\\s*Market Segmentation\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_02 <- str_match(text, "(?i)\\[Step 2:?\\s*Select a Beachhead Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_03 <- str_match(text, "(?i)\\[Step 3:?\\s*Build an End User Profile\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_04 <- str_match(text, "(?i)\\[Step 4:?\\s*Calculate TAM Size for Beachhead Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_05 <- str_match(text, "(?i)\\[Step 5:?\\s*Profile the Persona for the Beachhead Market\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_06 <- str_match(text, "(?i)\\[Step 6:?\\s*Full Life Cycle Use Case\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_07 <- str_match(text, "(?i)\\[Step 7:?\\s*High-Level Product Specification\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_08 <- str_match(text, "(?i)\\[Step 8:?\\s*Quantify the Value Proposition\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_09 <- str_match(text, "(?i)\\[Step 9:?\\s*Identify Your Next 10 Customers\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_10 <- str_match(text, "(?i)\\[Step 10:?\\s*Define Your Core\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_11 <- str_match(text, "(?i)\\[Step 11:?\\s*Chart Your Competitive Position\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_12 <- str_match(text, "(?i)\\[Step 12:?\\s*Determine the Customer'?s Decision-Making Unit\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_13 <- str_match(text, "(?i)\\[Step 13:?\\s*Map Process to Acquire Paying Customer\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_14 <- str_match(text, "(?i)\\[Step 14:?\\s*Calculate TAM Size for Follow-on Markets\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_15 <- str_match(text, "(?i)\\[Step 15:?\\s*Design a Business Model\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_16 <- str_match(text, "(?i)\\[Step 16:?\\s*Set Your Pricing Framework\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_17 <- str_match(text, "(?i)\\[Step 17:?\\s*Calculate Lifetime Value of an Acquired Customer\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_18 <- str_match(text, "(?i)\\[Step 18:?\\s*Map Sales Process to Acquire a Customer\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_19 <- str_match(text, "(?i)\\[Step 19:?\\s*Calculate the Cost of Customer Acquisition\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_20 <- str_match(text, "(?i)\\[Step 20:?\\s*Identify Key Assumptions\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_21 <- str_match(text, "(?i)\\[Step 21:?\\s*Test Key Assumptions\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_22 <- str_match(text, "(?i)\\[Step 22:?\\s*Define the Minimum Viable Business Product.*?MVBP.*?\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_23 <- str_match(text, "(?i)\\[Step 23:?\\s*Show That.*?The Dogs Will Eat the Dog Food.*?\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      step_24 <- str_match(text, "(?i)\\[Step 24:?\\s*Develop a Product Plan\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)")[,2]
      
      # Check if all steps are found
      missing_steps <- c()
      if (is.na(step_01)) missing_steps <- c(missing_steps, "Step 1: Market Segmentation")
      if (is.na(step_02)) missing_steps <- c(missing_steps, "Step 2: Select a Beachhead Market")
      if (is.na(step_03)) missing_steps <- c(missing_steps, "Step 3: Build an End User Profile")
      if (is.na(step_04)) missing_steps <- c(missing_steps, "Step 4: Calculate TAM Size for Beachhead Market")
      if (is.na(step_05)) missing_steps <- c(missing_steps, "Step 5: Profile the Persona for the Beachhead Market")
      if (is.na(step_06)) missing_steps <- c(missing_steps, "Step 6: Full Life Cycle Use Case")
      if (is.na(step_07)) missing_steps <- c(missing_steps, "Step 7: High-Level Product Specification")
      if (is.na(step_08)) missing_steps <- c(missing_steps, "Step 8: Quantify the Value Proposition")
      if (is.na(step_09)) missing_steps <- c(missing_steps, "Step 9: Identify Your Next 10 Customers")
      if (is.na(step_10)) missing_steps <- c(missing_steps, "Step 10: Define Your Core")
      if (is.na(step_11)) missing_steps <- c(missing_steps, "Step 11: Chart Your Competitive Position")
      if (is.na(step_12)) missing_steps <- c(missing_steps, "Step 12: Determine the Customer's Decision-Making Unit")
      if (is.na(step_13)) missing_steps <- c(missing_steps, "Step 13: Map Process to Acquire Paying Customer")
      if (is.na(step_14)) missing_steps <- c(missing_steps, "Step 14: Calculate TAM Size for Follow-on Markets")
      if (is.na(step_15)) missing_steps <- c(missing_steps, "Step 15: Design a Business Model")
      if (is.na(step_16)) missing_steps <- c(missing_steps, "Step 16: Set Your Pricing Framework")
      if (is.na(step_17)) missing_steps <- c(missing_steps, "Step 17: Calculate Lifetime Value of an Acquired Customer")
      if (is.na(step_18)) missing_steps <- c(missing_steps, "Step 18: Map Sales Process to Acquire a Customer")
      if (is.na(step_19)) missing_steps <- c(missing_steps, "Step 19: Calculate the Cost of Customer Acquisition")
      if (is.na(step_20)) missing_steps <- c(missing_steps, "Step 20: Identify Key Assumptions")
      if (is.na(step_21)) missing_steps <- c(missing_steps, "Step 21: Test Key Assumptions")
      if (is.na(step_22)) missing_steps <- c(missing_steps, "Step 22: Define the Minimum Viable Business Product (MVBP)")
      if (is.na(step_23)) missing_steps <- c(missing_steps, "Step 23: Show That 'The Dogs Will Eat the Dog Food'")
      if (is.na(step_24)) missing_steps <- c(missing_steps, "Step 24: Develop a Product Plan")
      
      if (length(missing_steps) > 0) {
        stop(paste("Missing steps:", paste(missing_steps, collapse = ", "), 
                   "\n\nPlease ensure all 24 steps are included with proper [Step X: Title] headers."))
      }
      
      # Store parsed data
      values$parsed_roadmap <- list(
        business_area = substr(trimws(input$roadmap_business_area), 1, 32),
        project = substr(trimws(input$roadmap_project), 1, 32),
        business_focus = substr(trimws(input$roadmap_business_focus), 1, 32),
        step_01 = trimws(step_01),
        step_02 = trimws(step_02),
        step_03 = trimws(step_03),
        step_04 = trimws(step_04),
        step_05 = trimws(step_05),
        step_06 = trimws(step_06),
        step_07 = trimws(step_07),
        step_08 = trimws(step_08),
        step_09 = trimws(step_09),
        step_10 = trimws(step_10),
        step_11 = trimws(step_11),
        step_12 = trimws(step_12),
        step_13 = trimws(step_13),
        step_14 = trimws(step_14),
        step_15 = trimws(step_15),
        step_16 = trimws(step_16),
        step_17 = trimws(step_17),
        step_18 = trimws(step_18),
        step_19 = trimws(step_19),
        step_20 = trimws(step_20),
        step_21 = trimws(step_21),
        step_22 = trimws(step_22),
        step_23 = trimws(step_23),
        step_24 = trimws(step_24)
      )
      
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully parsed Disciplined Entrepreneurship Roadmap!",
                 br(),
                 tags$small("Business Area: ", values$parsed_roadmap$business_area),
                 br(),
                 tags$small("Project: ", values$parsed_roadmap$project),
                 br(),
                 tags$small("Business Focus: ", values$parsed_roadmap$business_focus))
      })
      
      output$roadmapParseInfo <- renderUI({
        tags$p(
          tags$strong("Parsed Roadmap Summary:"),
          br(),
          paste("Business Area:", values$parsed_roadmap$business_area),
          br(),
          paste("Project:", values$parsed_roadmap$project),
          br(),
          paste("Business Focus:", values$parsed_roadmap$business_focus),
          br(),
          "All 24 steps successfully parsed"
        )
      })
      
      output$roadmapParsedPreview <- renderText({
        paste0(
          "Business Area: ", values$parsed_roadmap$business_area, "\n",
          "Project: ", values$parsed_roadmap$project, "\n",
          "Business Focus: ", values$parsed_roadmap$business_focus, "\n\n",
          "Step 1: ", substr(values$parsed_roadmap$step_01, 1, 80), "...\n",
          "Step 2: ", substr(values$parsed_roadmap$step_02, 1, 80), "...\n",
          "Step 3: ", substr(values$parsed_roadmap$step_03, 1, 80), "...\n",
          "Step 4: ", substr(values$parsed_roadmap$step_04, 1, 80), "...\n",
          "Step 5: ", substr(values$parsed_roadmap$step_05, 1, 80), "...\n",
          "...\n",
          "Step 24: ", substr(values$parsed_roadmap$step_24, 1, 80), "..."
        )
      })
      
      showNotification("✓ Roadmap parsed successfully!", type = "message")
      
    }, error = function(e) {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Parsing failed: ",
                 br(),
                 tags$small(e$message))
      })
      values$parsed_roadmap <- NULL
      output$roadmapParseInfo <- renderUI(NULL)
      output$roadmapParsedPreview <- renderText("")
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Submit Roadmap to BigQuery
  observeEvent(input$submitRoadmap, {
    
    if (!values$authenticated) {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    if (is.null(values$parsed_roadmap)) {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please parse the roadmap first by clicking 'Parse Roadmap Data'")
      })
      return()
    }
    
    output$roadmapBulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Submitting to BigQuery... Please wait.")
    })
    
    tryCatch({
      # Generate unique roadmap ID
      roadmap_id <- paste0(
        gsub("[^A-Za-z0-9]", "_", values$parsed_roadmap$business_area), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_roadmap$project), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_roadmap$business_focus), "_",
        format(Sys.time(), "%Y%m%d%H%M%S")
      )
      
      # Create Roadmap table if it doesn't exist
      roadmap_table_id <- paste0(values$project_id, ".", values$dataset_id, ".disciplined_entrepreneurship_roadmap")
      
      create_roadmap_table_query <- sprintf("
      CREATE TABLE IF NOT EXISTS `%s` (
        roadmap_id STRING NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
        business_area STRING,
        project STRING,
        business_focus STRING,
        step_01_market_segmentation STRING,
        step_02_select_beachhead_market STRING,
        step_03_build_end_user_profile STRING,
        step_04_calculate_tam_beachhead STRING,
        step_05_profile_persona STRING,
        step_06_full_life_cycle_use_case STRING,
        step_07_high_level_product_spec STRING,
        step_08_quantify_value_proposition STRING,
        step_09_identify_next_10_customers STRING,
        step_10_define_your_core STRING,
        step_11_chart_competitive_position STRING,
        step_12_determine_dmu STRING,
        step_13_map_process_acquire_customer STRING,
        step_14_calculate_tam_followon STRING,
        step_15_design_business_model STRING,
        step_16_set_pricing_framework STRING,
        step_17_calculate_ltv STRING,
        step_18_map_sales_process STRING,
        step_19_calculate_cac STRING,
        step_20_identify_key_assumptions STRING,
        step_21_test_key_assumptions STRING,
        step_22_define_mvbp STRING,
        step_23_dogs_eat_dog_food STRING,
        step_24_develop_product_plan STRING
      )", roadmap_table_id)
      
      tryCatch({
        bq_project_query(values$project_id, create_roadmap_table_query)
      }, error = function(e) {
        # Table might already exist
      })
      
      # Escape single quotes in all fields
      roadmap_id_clean <- gsub("'", "\\\\'", roadmap_id)
      business_area_clean <- gsub("'", "\\\\'", values$parsed_roadmap$business_area)
      project_clean <- gsub("'", "\\\\'", values$parsed_roadmap$project)
      business_focus_clean <- gsub("'", "\\\\'", values$parsed_roadmap$business_focus)
      step_01_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_01)
      step_02_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_02)
      step_03_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_03)
      step_04_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_04)
      step_05_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_05)
      step_06_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_06)
      step_07_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_07)
      step_08_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_08)
      step_09_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_09)
      step_10_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_10)
      step_11_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_11)
      step_12_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_12)
      step_13_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_13)
      step_14_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_14)
      step_15_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_15)
      step_16_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_16)
      step_17_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_17)
      step_18_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_18)
      step_19_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_19)
      step_20_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_20)
      step_21_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_21)
      step_22_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_22)
      step_23_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_23)
      step_24_clean <- gsub("'", "\\\\'", values$parsed_roadmap$step_24)
      
      insert_query <- sprintf("
      INSERT INTO `%s` 
      (roadmap_id, created_at, updated_at, business_area, project, business_focus, 
       step_01_market_segmentation, step_02_select_beachhead_market, step_03_build_end_user_profile,
       step_04_calculate_tam_beachhead, step_05_profile_persona, step_06_full_life_cycle_use_case,
       step_07_high_level_product_spec, step_08_quantify_value_proposition, step_09_identify_next_10_customers,
       step_10_define_your_core, step_11_chart_competitive_position, step_12_determine_dmu,
       step_13_map_process_acquire_customer, step_14_calculate_tam_followon, step_15_design_business_model,
       step_16_set_pricing_framework, step_17_calculate_ltv, step_18_map_sales_process,
       step_19_calculate_cac, step_20_identify_key_assumptions, step_21_test_key_assumptions,
       step_22_define_mvbp, step_23_dogs_eat_dog_food, step_24_develop_product_plan) 
      VALUES (
        '%s', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), '%s', '%s', '%s',
        '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s',
        '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'
      )",
                              roadmap_table_id,
                              roadmap_id_clean, business_area_clean, project_clean, business_focus_clean,
                              step_01_clean, step_02_clean, step_03_clean, step_04_clean, step_05_clean,
                              step_06_clean, step_07_clean, step_08_clean, step_09_clean, step_10_clean,
                              step_11_clean, step_12_clean, step_13_clean, step_14_clean, step_15_clean,
                              step_16_clean, step_17_clean, step_18_clean, step_19_clean, step_20_clean,
                              step_21_clean, step_22_clean, step_23_clean, step_24_clean
      )
      
      bq_project_query(values$project_id, insert_query)
      
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully submitted Disciplined Entrepreneurship Roadmap to BigQuery!",
                 br(),
                 tags$small("Roadmap ID: ", roadmap_id))
      })
      
      showNotification("✓ Roadmap submitted successfully!", type = "message")
      
      # Update dropdowns
      updateCanvasDropdowns()
      
    }, error = function(e) {
      output$roadmapBulkStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Error submitting to BigQuery: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Clear Roadmap bulk text
  observeEvent(input$clearRoadmap, {
    updateTextInput(session, "roadmap_business_area", value = "")
    updateTextInput(session, "roadmap_project", value = "")
    updateTextInput(session, "roadmap_business_focus", value = "")
    updateTextAreaInput(session, "roadmap_bulk_text", value = "")
    values$parsed_roadmap <- NULL
    output$roadmapBulkStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " All fields cleared. Ready for new input.")
    })
    output$roadmapParseInfo <- renderUI(NULL)
    output$roadmapParsedPreview <- renderText("")
  })
  
  
  # Load canvas from BigQuery (keeping original code)
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
        
        output$canvas_key_partners <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$key_partners), '</div>')))
        output$canvas_key_activities <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$key_activities), '</div>')))
        output$canvas_key_resources <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$key_resources), '</div>')))
        output$canvas_value_propositions <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$value_propositions), '</div>')))
        output$canvas_customer_relationships <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$customer_relationships), '</div>')))
        output$canvas_channels <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$channels), '</div>')))
        output$canvas_customer_segments <- renderUI(HTML(paste0('<div class="section-content">', gsub("\n", "<br>", result$customer_segments), '</div>')))
        output$canvas_cost_structure <- renderUI(HTML(paste0('<div class="section-content two-column-content">', gsub("\n", "<br>", result$cost_structure), '</div>')))
        output$canvas_revenue_streams <- renderUI(HTML(paste0('<div class="section-content two-column-content">', gsub("\n", "<br>", result$revenue_streams), '</div>')))
        
        showNotification("✓ Canvas loaded successfully!", type = "message")
      } else {
        showNotification("No canvas found for this selection. Showing default template.", type = "warning")
        loadDefaultCanvas()
      }
      
    }, error = function(e) {
      showNotification(paste("Error loading canvas:", e$message), type = "error")
      loadDefaultCanvas()
    })
  })
  
  # Load DE Canvas from BigQuery
  observeEvent(input$loadDECanvas, {
    
    if (!values$authenticated) {
      showNotification("Please authenticate first", type = "error")
      return()
    }
    
    if (input$de_select_business_area == "" || input$de_select_project == "" || input$de_select_business_focus == "") {
      showNotification("Please select Business Area, Project, and Business Focus", type = "warning")
      return()
    }
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$de_select_business_area)
      project_clean <- gsub("'", "\\\\'", input$de_select_project)
      business_focus_clean <- gsub("'", "\\\\'", input$de_select_business_focus)
      
      # Query for DE Canvas data - will be implemented once table structure is defined
      # For now, show placeholder message
      showNotification("Data loading functionality will be implemented after table structure is defined", type = "info")
      
    }, error = function(e) {
      showNotification(paste("Error loading DE Canvas:", e$message), type = "error")
    })
  })
  
  # Load Roadmap from BigQuery
  observeEvent(input$loadRoadmap, {
    
    if (!values$authenticated) {
      showNotification("Please authenticate first", type = "error")
      return()
    }
    
    if (input$roadmap_select_business_area == "" || input$roadmap_select_project == "" || input$roadmap_select_business_focus == "") {
      showNotification("Please select Business Area, Project, and Business Focus", type = "warning")
      return()
    }
    
    tryCatch({
      business_area_clean <- gsub("'", "\\\\'", input$roadmap_select_business_area)
      project_clean <- gsub("'", "\\\\'", input$roadmap_select_project)
      business_focus_clean <- gsub("'", "\\\\'", input$roadmap_select_business_focus)
      
      # Query for Roadmap data - will be implemented once table structure is defined
      # For now, show placeholder message
      showNotification("Data loading functionality will be implemented after table structure is defined", type = "info")
      
    }, error = function(e) {
      showNotification(paste("Error loading Roadmap:", e$message), type = "error")
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