# Persona Canvas Builder with Teal Gradient Theme
# Matching Business Model Canvas styling
# Author: Generated for Startup Persona Management
# Date: 2025

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(dplyr)          
library(jsonlite)       
library(bigrquery)       
library(stringr)       
library(htmltools)       

# Define UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "Persona Canvas Builder",
    titleWidth = 300
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("BigQuery Authentication", tabName = "auth", icon = icon("key")),
      menuItem("Bulk Import Persona", tabName = "bulk_import", icon = icon("file-import")),
      menuItem("Persona Profile", tabName = "persona", icon = icon("user")),
      menuItem("Export Canvas", tabName = "export", icon = icon("download")),
      menuItem("Instructions", tabName = "instructions", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* ============================================
           TEAL GRADIENT THEME - Matching Business Model Canvas
           ============================================ */
        
        /* Main body background with teal gradient */
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        /* ============================================
           SIDEBAR STYLING
           ============================================ */
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
        
        /* ============================================
           HEADER STYLING
           ============================================ */
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
        
        /* ============================================
           BOX STYLING - Matching reference colors
           ============================================ */
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
        
        .box-header.with-border {
          border-bottom: 1px solid rgba(255, 255, 255, 0.2) !important;
        }
        
        /* Color-coded box headers for different sections */
        .box.box-primary > .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
        }
        
        .box.box-info > .box-header {
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
        }
        
        .box.box-success > .box-header {
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
        }
        
        .box.box-warning > .box-header {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
        }
        
        .box.box-danger > .box-header {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
        }
        
        /* ============================================
           STATUS MESSAGE STYLING
           ============================================ */
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
        
        /* ============================================
           FORM INPUT STYLING
           ============================================ */
        .form-control, .selectize-input {
          border-radius: 8px !important;
          border: 2px solid #ddd !important;
          transition: border-color 0.3s ease, box-shadow 0.3s ease;
          padding: 10px 15px !important;
          font-size: 14px !important;
        }
        
        .form-control:focus, .selectize-input.focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
        }
        
        textarea.form-control {
          resize: vertical !important;
          min-height: 100px !important;
        }
        
        #bulk_persona_text {
          min-height: 400px !important;
          font-family: 'Courier New', monospace;
          font-size: 13px;
        }
        
        label {
          font-weight: 600 !important;
          color: #2c3e50 !important;
          font-size: 14px !important;
          margin-bottom: 8px !important;
        }
        
        /* ============================================
           BUTTON STYLING
           ============================================ */
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
          padding: 10px 20px;
          font-weight: 600;
          transition: transform 0.2s ease;
        }
        
        .btn-success:hover {
          background: linear-gradient(135deg, #007d75 0%, #006b63 100%) !important;
          transform: translateY(-1px);
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
        
        /* ============================================
           SLIDER STYLING
           ============================================ */
        .irs--shiny .irs-bar {
          background: linear-gradient(90deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
        }
        
        .irs--shiny .irs-handle {
          background: white !important;
          border: 3px solid #008A82 !important;
          box-shadow: 0 2px 6px rgba(0,0,0,0.2) !important;
        }
        
        .irs--shiny .irs-from, .irs--shiny .irs-to, .irs--shiny .irs-single {
          background: #008A82 !important;
          color: white !important;
          font-weight: 600 !important;
          border-radius: 6px !important;
        }
        
        /* ============================================
           ALERT STYLING
           ============================================ */
        .alert-info {
          background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
          border-left: 4px solid #17a2b8 !important;
          border-radius: 8px;
          color: #0c5460;
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
        
        /* ============================================
           PERSONA CANVAS DISPLAY STYLING
           ============================================ */
        .persona-card {
          background: rgba(255, 255, 255, 0.98);
          border-radius: 12px;
          padding: 30px;
          margin-bottom: 20px;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2);
        }
        
        /* Header section with photo */
        .persona-header {
          display: flex;
          align-items: flex-start;
          gap: 30px;
          margin-bottom: 30px;
          padding-bottom: 25px;
          border-bottom: 2px solid rgba(0, 138, 130, 0.2);
        }
        
        .persona-photo {
          width: 220px;
          height: 220px;
          border-radius: 15px;
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%);
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          font-size: 72px;
          font-weight: bold;
          flex-shrink: 0;
          box-shadow: 0 4px 12px rgba(0, 138, 130, 0.4);
        }
        
        .persona-name-section {
          flex-grow: 1;
        }
        
        .persona-name {
          font-size: 52px;
          font-weight: 700;
          color: #002C3C;
          margin: 0 0 12px 0;
          line-height: 1.2;
        }
        
        .persona-subtitle {
          font-size: 20px;
          color: #2c3e50;
          margin: 0 0 20px 0;
          font-weight: 400;
        }
        
        .persona-quote {
          font-style: italic;
          color: #555;
          font-size: 17px;
          padding: 18px 20px;
          background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
          border-left: 5px solid #008A82;
          margin-top: 15px;
          border-radius: 0 8px 8px 0;
          line-height: 1.6;
        }
        
        /* Demographics bar */
        .demographics-section {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 18px;
          margin: 25px 0;
        }
        
        .demo-item {
          background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
          padding: 18px;
          border-radius: 10px;
          border-left: 4px solid #008A82;
          box-shadow: 0 2px 4px rgba(0, 44, 60, 0.1);
        }
        
        .demo-label {
          font-size: 11px;
          color: #6c757d;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 6px;
          font-weight: 600;
        }
        
        .demo-value {
          font-size: 18px;
          font-weight: 700;
          color: #002C3C;
        }
        
        /* Grid layout for sections */
        .persona-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 20px;
          margin-top: 25px;
        }
        
        .persona-section {
          background: white;
          border: 2px solid #e0e0e0;
          border-radius: 15px;
          padding: 25px;
          box-shadow: 0 2px 6px rgba(0, 44, 60, 0.1);
          transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .persona-section:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0, 44, 60, 0.15);
        }
        
        /* Section colors - teal theme variations */
        .section-blue {
          border-color: #008A82;
          background: linear-gradient(135deg, #e6f7f5 0%, #d4f1ee 100%);
        }
        
        .section-red {
          border-color: #e74c3c;
          background: linear-gradient(135deg, #fff5f7 0%, #ffe8ed 100%);
        }
        
        .section-orange {
          border-color: #f39c12;
          background: linear-gradient(135deg, #fff9f0 0%, #fef5ed 100%);
        }
        
        .section-green {
          border-color: #00A39A;
          background: linear-gradient(135deg, #e6faf9 0%, #d4f5f3 100%);
        }
        
        .section-purple {
          border-color: #9b59b6;
          background: linear-gradient(135deg, #f9f7fc 0%, #f3eef9 100%);
        }
        
        .section-teal {
          border-color: #00A39A;
          background: linear-gradient(135deg, #d4f5f3 0%, #c2f0ed 100%);
        }
        
        .section-lightblue {
          border-color: #3498db;
          background: linear-gradient(135deg, #e8f4fd 0%, #d6ecfb 100%);
        }
        
        .section-title {
          font-size: 19px;
          font-weight: 700;
          color: #002C3C;
          margin: 0 0 18px 0;
          padding-bottom: 12px;
          border-bottom: 2px solid currentColor;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        
        .section-content {
          color: #555;
          line-height: 1.7;
          font-size: 15px;
        }
        
        .section-content ul {
          margin: 12px 0;
          padding-left: 22px;
        }
        
        .section-content li {
          margin-bottom: 10px;
          position: relative;
        }
        
        .section-content li::marker {
          color: #008A82;
          font-weight: bold;
        }
        
        .section-content p {
          margin: 10px 0;
          line-height: 1.7;
        }
        
        .section-content h4 {
          color: #002C3C;
          font-size: 16px;
          font-weight: 600;
          margin: 15px 0 10px 0;
        }
        
        /* Full width section */
        .full-width-section {
          grid-column: 1 / -1;
        }
        
        /* Personality traits */
        .personality-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 15px;
          margin-top: 12px;
        }
        
        .personality-item {
          padding: 12px;
          background: white;
          border-radius: 8px;
          box-shadow: 0 1px 3px rgba(0, 44, 60, 0.1);
        }
        
        .personality-label {
          font-size: 11px;
          color: #6c757d;
          margin-bottom: 8px;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.3px;
        }
        
        .personality-scale {
          width: 100%;
          height: 8px;
          background: #e9ecef;
          border-radius: 4px;
          margin: 8px 0;
          position: relative;
          overflow: hidden;
        }
        
        .personality-fill {
          height: 100%;
          background: linear-gradient(90deg, #008A82 0%, #00A39A 100%);
          border-radius: 4px;
          transition: width 0.3s ease;
        }
        
        .personality-value {
          font-size: 13px;
          font-weight: 700;
          color: #002C3C;
          text-align: center;
          margin-top: 4px;
        }
        
        /* ============================================
           ADDITIONAL REFINEMENTS
           ============================================ */
        .content {
          padding: 20px !important;
        }
        
        /* Notification styling */
        .shiny-notification {
          border-radius: 8px !important;
          box-shadow: 0 4px 12px rgba(0, 44, 60, 0.2) !important;
          border-left: 4px solid #008A82 !important;
        }
        
        /* Tab content */
        .tab-content {
          padding: 20px 0;
        }
        
        /* Responsive adjustments */
        @media (max-width: 768px) {
          .persona-grid {
            grid-template-columns: 1fr;
          }
          
          .demographics-section {
            grid-template-columns: 1fr;
          }
          
          .persona-header {
            flex-direction: column;
          }
          
          .persona-photo {
            width: 100%;
            max-width: 200px;
            margin: 0 auto;
          }
        }
      "))
    ),
    
    tabItems(
      # ============================================
      # Tab 1: BigQuery Authentication
      # ============================================
      tabItem(
        tabName = "auth",
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
                               value = "startup_personas",
                               width = "100%"),
                     
                     textInput("table_id", 
                               "Table ID:",
                               placeholder = "table_name",
                               value = "persona_canvas",
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
      
      # ============================================
      # Tab 2: Bulk Import Persona
      # ============================================
      tabItem(
        tabName = "bulk_import",
        fluidRow(
          box(
            title = "Persona Canvas - Bulk Import", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 12,
            
            h4("Import Persona Canvas Data"),
            p("Enter your business identification and paste the persona canvas fields in the required format."),
            
            fluidRow(
              column(4,
                     textInput("bulk_business_area", 
                               "Business Area (max 32 chars):", 
                               placeholder = "e.g., Technology, Healthcare",
                               width = "100%")
              ),
              column(4,
                     textInput("bulk_project", 
                               "Project (max 32 chars):", 
                               placeholder = "e.g., Mobile App Development",
                               width = "100%")
              ),
              column(4,
                     textInput("bulk_business_focus", 
                               "Business Focus (max 32 chars):", 
                               placeholder = "e.g., B2B SaaS",
                               width = "100%")
              )
            ),
            
            br(),
            
            div(class = "alert alert-info",
                tags$strong("Format Requirements for Bulk Import:"),
                tags$ul(
                  tags$li("Start each section with its title in brackets: [Persona Name], [Role], [Age], etc."),
                  tags$li("Content should follow immediately after each title"),
                  tags$li("Separate sections with blank lines"),
                  tags$li("Required fields: Persona Name, Role, Age, Location, Education, Quote, Profession, Experience, Company Size, Income, Explorer Trait, Introvert Trait, Optimist Trait, Calm Trait, Story, Values, Goals, Frustrations, Mobile Apps, Desktop Apps, Day in Life")
                )
            ),
            
            textAreaInput("bulk_persona_text", 
                          "Paste Persona Canvas Content:",
                          height = "400px",
                          width = "100%",
                          placeholder = "[Persona Name]
Chris

[Role]
Startup Founder

[Age]
29

[Location]
Berlin, DE

[Education]
Master's

[Quote]
These guys raised money but I had the idea long before, just haven't started developing it.

[Profession]
Founder & CEO at Bubble

[Experience]
5

[Company Size]
Startup (< 10 employees)

[Income]
$75K - $100K

[Explorer Trait]
75

[Introvert Trait]
60

[Optimist Trait]
70

[Calm Trait]
40

[Story]
Graduated Finance in Athens before getting a job with Alpha Bank. When he was 21 years old, he immediately worked in the fintech industry. Today Chris leads a small team of product designers, accountants, lawyers, and product managers.

[Values]
Family/personal
Good networker
Social Innovator
Experience

[Goals]
Bringing attention to his startup
Growing his team with co-founders
Launch and validate his product as a business

[Frustrations]
Lacks access to investors & networks
Insight of how some programs & products work
Increased competition that set a high bar
Scarcity of raising

[Mobile Apps]
Slack
Trello
Email
Facebook Messenger
Twitter

[Desktop Apps]
Slack
Kanban
Google Sheets
Mail

[Day in Life]
Wakes at 6am
Exercises
Morning meetings
Product development
Networking events
Planning & Strategy"),
            
            fluidRow(
              column(4,
                     actionButton("parsePersona", 
                                  "Parse Persona Data", 
                                  class = "btn btn-info btn-lg",
                                  icon = icon("cogs"),
                                  width = "100%")
              ),
              column(4,
                     actionButton("submitPersona", 
                                  "Submit to BigQuery", 
                                  class = "btn btn-success btn-lg",
                                  icon = icon("cloud-upload-alt"),
                                  width = "100%")
              ),
              column(4,
                     actionButton("clearPersona", 
                                  "Clear All", 
                                  class = "btn btn-danger",
                                  icon = icon("trash"),
                                  width = "100%")
              )
            ),
            
            br(),
            htmlOutput("bulkPersonaStatus")
          )
        ),
        
        fluidRow(
          box(
            title = "Parsed Persona Preview", 
            status = "info", 
            solidHeader = TRUE, 
            width = 12,
            
            htmlOutput("parsePersonaInfo"),
            br(),
            
            div(class = "preview-section",
                verbatimTextOutput("parsedPersonaPreview"))
          )
        )
      ),
      
      # ============================================
      # Tab 3: Persona Profile
      # ============================================
      tabItem(
        tabName = "persona",
        fluidRow(
          column(
            width = 12,
            box(
              title = "Basic Information",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              collapsible = TRUE,
              
              fluidRow(
                column(6, textInput("persona_name", "Persona Name", value = "Chris")),
                column(6, textInput("persona_role", "Role/Title", value = "Startup Founder"))
              ),
              fluidRow(
                column(4, numericInput("persona_age", "Age", value = 29, min = 18, max = 100)),
                column(4, textInput("persona_location", "Location", value = "Berlin, DE")),
                column(4, selectInput("persona_education", "Education", 
                                      choices = c("High School", "Some College", "Bachelor's", "Master's", "PhD", "Other"),
                                      selected = "Master's"))
              ),
              fluidRow(
                column(12, textAreaInput("persona_quote", "Key Quote", 
                                         value = "These guys raised money but I had the idea long before, just haven't started developing it.",
                                         rows = 2))
              )
            )
          )
        ),
        
        fluidRow(
          column(
            width = 6,
            box(
              title = "Demographics",
              status = "info",
              solidHeader = TRUE,
              width = NULL,
              
              textInput("persona_profession", "Profession", value = "Founder & CEO at Bubble"),
              numericInput("persona_experience", "Years of Experience", value = 5, min = 0, max = 50),
              textInput("persona_company_size", "Company Size", value = "Startup (< 10 employees)"),
              selectInput("persona_income", "Income Level",
                          choices = c("< $50K", "$50K - $75K", "$75K - $100K", "$100K - $150K", "> $150K"),
                          selected = "$75K - $100K")
            )
          ),
          
          column(
            width = 6,
            box(
              title = "Personality Traits",
              status = "warning",
              solidHeader = TRUE,
              width = NULL,
              
              sliderInput("trait_explorer", "Archetype: EXPLORER (vs KEEPER)", 
                          min = 0, max = 100, value = 75, post = "%"),
              sliderInput("trait_introvert", "INTROVERT (vs EXTROVERT)", 
                          min = 0, max = 100, value = 60, post = "%"),
              sliderInput("trait_optimist", "OPTIMIST (vs PESSIMIST)", 
                          min = 0, max = 100, value = 70, post = "%"),
              sliderInput("trait_calm", "CALM (vs ANXIOUS)", 
                          min = 0, max = 100, value = 40, post = "%")
            )
          )
        ),
        
        fluidRow(
          column(
            width = 6,
            box(
              title = "Story & Background",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              
              textAreaInput("persona_story", "Personal Story", 
                            value = "Graduated Finance in Athens before getting a job with Alpha Bank. When he was 21 years old, he immediately worked in the fintech industry. Today Chris leads a small team of product designers, accountants, lawyers, and product managers. He recently started raising his first round of funding.",
                            rows = 6)
            )
          ),
          
          column(
            width = 6,
            box(
              title = "Values & Motivations",
              status = "success",
              solidHeader = TRUE,
              width = NULL,
              
              textAreaInput("persona_values", "Core Values (one per line)", 
                            value = "Family/personal\nGood networker\nSocial Innovator\nExperience",
                            rows = 6)
            )
          )
        ),
        
        fluidRow(
          column(
            width = 6,
            box(
              title = "Goals & Aspirations",
              status = "success",
              solidHeader = TRUE,
              width = NULL,
              
              textAreaInput("persona_goals", "Primary Goals (one per line)", 
                            value = "Bringing attention to his startup\nGrowing his team with co-founders\nLaunch and validate his product as a business",
                            rows = 6)
            )
          ),
          
          column(
            width = 6,
            box(
              title = "Frustrations & Pain Points",
              status = "danger",
              solidHeader = TRUE,
              width = NULL,
              
              textAreaInput("persona_frustrations", "Key Frustrations (one per line)", 
                            value = "Lacks access to investors & networks\nInsight of how some programs & products work\nIncreased competition that set a high bar\nScarcity of raising",
                            rows = 6)
            )
          )
        ),
        
        fluidRow(
          column(
            width = 12,
            box(
              title = "Apps & Tools Used",
              status = "info",
              solidHeader = TRUE,
              width = NULL,
              
              fluidRow(
                column(6,
                       h4("Mobile Apps"),
                       textAreaInput("persona_mobile_apps", "Mobile Applications", 
                                     value = "Slack\nTrello\nEmail\nFacebook Messenger\nTwitter",
                                     rows = 5)
                ),
                column(6,
                       h4("Desktop Apps"),
                       textAreaInput("persona_desktop_apps", "Desktop Applications", 
                                     value = "Slack\nKanban\nGoogle Sheets\nMail",
                                     rows = 5)
                )
              )
            )
          )
        ),
        
        fluidRow(
          column(
            width = 12,
            box(
              title = "A Day in the Life",
              status = "warning",
              solidHeader = TRUE,
              width = NULL,
              
              textAreaInput("persona_day_in_life", "Describe a typical day", 
                            value = "Wakes at 6am\nExercises\nMorning meetings\nProduct development\nNetworking events\nPlanning & Strategy",
                            rows = 8)
            )
          )
        ),
        
        fluidRow(
          column(
            width = 12,
            actionButton("generate_canvas", "Generate Persona Canvas", 
                         class = "btn-primary btn-lg", 
                         icon = icon("magic"),
                         style = "width: 100%; margin-top: 20px;")
          )
        )
      ),
      
      # ============================================
      # Tab 4: Export Canvas
      # ============================================
      tabItem(
        tabName = "export",
        fluidRow(
          column(
            width = 12,
            box(
              title = "Generated Persona Canvas",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              
              uiOutput("persona_canvas_display"),
              
              br(),
              downloadButton("download_html", "Download as HTML", class = "btn-success"),
              downloadButton("download_pdf", "Download as PDF", class = "btn-info")
            )
          )
        )
      ),
      
      # ============================================
      # Tab 5: Instructions
      # ============================================
      tabItem(
        tabName = "instructions",
        fluidRow(
          column(
            width = 12,
            box(
              title = "How to Use This Persona Canvas Builder",
              status = "info",
              solidHeader = TRUE,
              width = NULL,
              
              h3("About the Disciplined Entrepreneurship Persona Canvas"),
              p("This tool is based on the Disciplined Entrepreneurship framework developed by Bill Aulet at MIT. 
                It helps you create detailed, actionable personas for your startup's target customers."),
              
              h3("Steps to Create Your Persona:"),
              tags$ol(
                tags$li(strong("Basic Information:"), " Start with demographic details - name, age, role, location, education."),
                tags$li(strong("Story & Background:"), " Write a narrative about their professional journey and current situation."),
                tags$li(strong("Values & Motivations:"), " Identify what drives them and what they care about most."),
                tags$li(strong("Goals:"), " Define what they're trying to accomplish professionally and personally."),
                tags$li(strong("Frustrations:"), " Document their pain points, challenges, and obstacles."),
                tags$li(strong("Personality:"), " Use the sliders to position them on key personality dimensions."),
                tags$li(strong("Tools & Apps:"), " List the technologies they use daily - this reveals behavior patterns."),
                tags$li(strong("Day in the Life:"), " Describe their typical day to understand context and opportunities.")
              ),
              
              h3("Best Practices:"),
              tags$ul(
                tags$li("Base personas on real customer research and interviews, not assumptions"),
                tags$li("Give your persona a real name and photo (or representative placeholder) to humanize them"),
                tags$li("Include a memorable quote that captures their mindset"),
                tags$li("Focus on behaviors and motivations, not just demographics"),
                tags$li("Update personas regularly as you learn more about your customers"),
                tags$li("Create multiple personas if you serve distinct customer segments")
              ),
              
              h3("Why This Matters for Startups:"),
              p("According to Disciplined Entrepreneurship methodology, understanding your end user deeply is critical 
                to building products people actually want. A detailed persona helps you:"),
              tags$ul(
                tags$li("Make better product decisions aligned with user needs"),
                tags$li("Craft more effective marketing messages"),
                tags$li("Prioritize features that solve real problems"),
                tags$li("Build empathy across your entire team"),
                tags$li("Identify your beachhead market more precisely")
              )
            )
          )
        )
      )
    )
  )
)

# Define server logic
# Define server logic
server <- function(input, output, session) {
  
  # ============================================
  # REACTIVE VALUES (UPDATED - includes new values)
  # ============================================
  values <- reactiveValues(
    authenticated = FALSE,
    project_id = NULL,
    dataset_id = NULL,
    table_id = NULL,
    full_table_id = NULL,
    temp_file_path = NULL,
    parsed_persona = NULL,
    current_persona = NULL,
    canvas_generated = FALSE  # Keep your existing reactive value
  )
  
  # ============================================
  # BIGQUERY AUTHENTICATION (NEW)
  # ============================================
  output$package_info <- renderText({
    paste0("bigrquery version: ", packageVersion("bigrquery"))
  })
  
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
              persona_id STRING NOT NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
              business_area STRING,
              project STRING,
              business_focus STRING,
              persona_name STRING,
              persona_role STRING,
              persona_age INT64,
              persona_location STRING,
              persona_education STRING,
              persona_quote STRING,
              persona_profession STRING,
              persona_experience INT64,
              persona_company_size STRING,
              persona_income STRING,
              trait_explorer INT64,
              trait_introvert INT64,
              trait_optimist INT64,
              trait_calm INT64,
              persona_story STRING,
              persona_values STRING,
              persona_goals STRING,
              persona_frustrations STRING,
              persona_mobile_apps STRING,
              persona_desktop_apps STRING,
              persona_day_in_life STRING
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
  
  # ============================================
  # PARSE PERSONA DATA (NEW)
  # ============================================
  observeEvent(input$parsePersona, {
    
    if (is.null(input$bulk_persona_text) || trimws(input$bulk_persona_text) == "") {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please paste persona content to parse")
      })
      return()
    }
    
    if (is.null(input$bulk_business_area) || trimws(input$bulk_business_area) == "") {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Area")
      })
      return()
    }
    
    if (is.null(input$bulk_project) || trimws(input$bulk_project) == "") {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Project name")
      })
      return()
    }
    
    if (is.null(input$bulk_business_focus) || trimws(input$bulk_business_focus) == "") {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please provide Business Focus")
      })
      return()
    }
    
    output$bulkPersonaStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Parsing persona data...")
    })
    
    tryCatch({
      text <- input$bulk_persona_text
      
      # Parse all fields
      persona_name <- str_match(text, "(?i)\\[Persona Name\\]\\s*\n([^\n]+)")[,2]
      persona_role <- str_match(text, "(?i)\\[Role\\]\\s*\n([^\n]+)")[,2]
      persona_age <- str_match(text, "(?i)\\[Age\\]\\s*\n([^\n]+)")[,2]
      persona_location <- str_match(text, "(?i)\\[Location\\]\\s*\n([^\n]+)")[,2]
      persona_education <- str_match(text, "(?i)\\[Education\\]\\s*\n([^\n]+)")[,2]
      persona_quote <- str_match(text, "(?i)\\[Quote\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_profession <- str_match(text, "(?i)\\[Profession\\]\\s*\n([^\n]+)")[,2]
      persona_experience <- str_match(text, "(?i)\\[Experience\\]\\s*\n([^\n]+)")[,2]
      persona_company_size <- str_match(text, "(?i)\\[Company Size\\]\\s*\n([^\n]+)")[,2]
      persona_income <- str_match(text, "(?i)\\[Income\\]\\s*\n([^\n]+)")[,2]
      
      # Personality traits
      trait_explorer <- str_match(text, "(?i)\\[Explorer Trait\\]\\s*\n([^\n]+)")[,2]
      trait_introvert <- str_match(text, "(?i)\\[Introvert Trait\\]\\s*\n([^\n]+)")[,2]
      trait_optimist <- str_match(text, "(?i)\\[Optimist Trait\\]\\s*\n([^\n]+)")[,2]
      trait_calm <- str_match(text, "(?i)\\[Calm Trait\\]\\s*\n([^\n]+)")[,2]
      
      # Long text fields
      persona_story <- str_match(text, "(?i)\\[Story\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_values <- str_match(text, "(?i)\\[Values\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_goals <- str_match(text, "(?i)\\[Goals\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_frustrations <- str_match(text, "(?i)\\[Frustrations\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_mobile_apps <- str_match(text, "(?i)\\[Mobile Apps\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_desktop_apps <- str_match(text, "(?i)\\[Desktop Apps\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      persona_day_in_life <- str_match(text, "(?i)\\[Day in Life\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)")[,2]
      
      # Check for missing required fields
      missing_fields <- c()
      if (is.na(persona_name)) missing_fields <- c(missing_fields, "Persona Name")
      if (is.na(persona_role)) missing_fields <- c(missing_fields, "Role")
      if (is.na(persona_age)) missing_fields <- c(missing_fields, "Age")
      if (is.na(persona_location)) missing_fields <- c(missing_fields, "Location")
      if (is.na(persona_education)) missing_fields <- c(missing_fields, "Education")
      if (is.na(persona_quote)) missing_fields <- c(missing_fields, "Quote")
      if (is.na(persona_profession)) missing_fields <- c(missing_fields, "Profession")
      if (is.na(persona_experience)) missing_fields <- c(missing_fields, "Experience")
      if (is.na(persona_company_size)) missing_fields <- c(missing_fields, "Company Size")
      if (is.na(persona_income)) missing_fields <- c(missing_fields, "Income")
      if (is.na(trait_explorer)) missing_fields <- c(missing_fields, "Explorer Trait")
      if (is.na(trait_introvert)) missing_fields <- c(missing_fields, "Introvert Trait")
      if (is.na(trait_optimist)) missing_fields <- c(missing_fields, "Optimist Trait")
      if (is.na(trait_calm)) missing_fields <- c(missing_fields, "Calm Trait")
      if (is.na(persona_story)) missing_fields <- c(missing_fields, "Story")
      if (is.na(persona_values)) missing_fields <- c(missing_fields, "Values")
      if (is.na(persona_goals)) missing_fields <- c(missing_fields, "Goals")
      if (is.na(persona_frustrations)) missing_fields <- c(missing_fields, "Frustrations")
      if (is.na(persona_mobile_apps)) missing_fields <- c(missing_fields, "Mobile Apps")
      if (is.na(persona_desktop_apps)) missing_fields <- c(missing_fields, "Desktop Apps")
      if (is.na(persona_day_in_life)) missing_fields <- c(missing_fields, "Day in Life")
      
      if (length(missing_fields) > 0) {
        stop(paste("Missing fields:", paste(missing_fields, collapse = ", "), 
                   "\n\nPlease ensure all required fields are included with proper [Field Name] headers."))
      }
      
      # Store parsed data
      values$parsed_persona <- list(
        business_area = substr(trimws(input$bulk_business_area), 1, 32),
        project = substr(trimws(input$bulk_project), 1, 32),
        business_focus = substr(trimws(input$bulk_business_focus), 1, 32),
        persona_name = trimws(persona_name),
        persona_role = trimws(persona_role),
        persona_age = as.integer(trimws(persona_age)),
        persona_location = trimws(persona_location),
        persona_education = trimws(persona_education),
        persona_quote = trimws(persona_quote),
        persona_profession = trimws(persona_profession),
        persona_experience = as.integer(trimws(persona_experience)),
        persona_company_size = trimws(persona_company_size),
        persona_income = trimws(persona_income),
        trait_explorer = as.integer(trimws(trait_explorer)),
        trait_introvert = as.integer(trimws(trait_introvert)),
        trait_optimist = as.integer(trimws(trait_optimist)),
        trait_calm = as.integer(trimws(trait_calm)),
        persona_story = trimws(persona_story),
        persona_values = trimws(persona_values),
        persona_goals = trimws(persona_goals),
        persona_frustrations = trimws(persona_frustrations),
        persona_mobile_apps = trimws(persona_mobile_apps),
        persona_desktop_apps = trimws(persona_desktop_apps),
        persona_day_in_life = trimws(persona_day_in_life)
      )
      
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully parsed Persona Canvas!",
                 br(),
                 tags$small("Business Area: ", values$parsed_persona$business_area),
                 br(),
                 tags$small("Project: ", values$parsed_persona$project),
                 br(),
                 tags$small("Business Focus: ", values$parsed_persona$business_focus),
                 br(),
                 tags$small("Persona Name: ", values$parsed_persona$persona_name))
      })
      
      output$parsePersonaInfo <- renderUI({
        tags$p(
          tags$strong("Parsed Persona Summary:"),
          br(),
          paste("Business Area:", values$parsed_persona$business_area),
          br(),
          paste("Project:", values$parsed_persona$project),
          br(),
          paste("Business Focus:", values$parsed_persona$business_focus),
          br(),
          paste("Persona Name:", values$parsed_persona$persona_name),
          br(),
          paste("Role:", values$parsed_persona$persona_role),
          br(),
          paste("Age:", values$parsed_persona$persona_age),
          br(),
          "All required fields successfully parsed"
        )
      })
      
      output$parsedPersonaPreview <- renderText({
        paste0(
          "Business Area: ", values$parsed_persona$business_area, "\n",
          "Project: ", values$parsed_persona$project, "\n",
          "Business Focus: ", values$parsed_persona$business_focus, "\n\n",
          "Persona Name: ", values$parsed_persona$persona_name, "\n",
          "Role: ", values$parsed_persona$persona_role, "\n",
          "Age: ", values$parsed_persona$persona_age, "\n",
          "Location: ", values$parsed_persona$persona_location, "\n",
          "Education: ", values$parsed_persona$persona_education, "\n\n",
          "Quote: ", substr(values$parsed_persona$persona_quote, 1, 100), "...\n\n",
          "Story: ", substr(values$parsed_persona$persona_story, 1, 150), "...\n\n",
          "Personality Traits:\n",
          "  Explorer: ", values$parsed_persona$trait_explorer, "%\n",
          "  Introvert: ", values$parsed_persona$trait_introvert, "%\n",
          "  Optimist: ", values$parsed_persona$trait_optimist, "%\n",
          "  Calm: ", values$parsed_persona$trait_calm, "%\n"
        )
      })
      
      showNotification("✓ Persona parsed successfully!", type = "message")
      
    }, error = function(e) {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Parsing failed: ",
                 br(),
                 tags$small(e$message))
      })
      values$parsed_persona <- NULL
      output$parsePersonaInfo <- renderUI(NULL)
      output$parsedPersonaPreview <- renderText("")
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # ============================================
  # SUBMIT PERSONA TO BIGQUERY (NEW)
  # ============================================
  observeEvent(input$submitPersona, {
    
    if (!values$authenticated) {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please authenticate first in the BigQuery Authentication tab")
      })
      return()
    }
    
    if (is.null(values$parsed_persona)) {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Please parse the persona first by clicking 'Parse Persona Data'")
      })
      return()
    }
    
    output$bulkPersonaStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-spinner fa-spin"), 
               " Submitting to BigQuery... Please wait.")
    })
    
    tryCatch({
      # Generate unique persona ID
      persona_id <- paste0(
        gsub("[^A-Za-z0-9]", "_", values$parsed_persona$business_area), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_persona$project), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_persona$business_focus), "_",
        gsub("[^A-Za-z0-9]", "_", values$parsed_persona$persona_name), "_",
        format(Sys.time(), "%Y%m%d%H%M%S")
      )
      
      # Escape single quotes in all string fields
      escape_sql <- function(x) {
        if (is.character(x)) {
          return(gsub("'", "\\\\'", x))
        }
        return(x)
      }
      
      p <- lapply(values$parsed_persona, escape_sql)
      persona_id_clean <- escape_sql(persona_id)
      
      insert_query <- sprintf("
        INSERT INTO `%s` 
        (persona_id, created_at, updated_at, business_area, project, business_focus,
         persona_name, persona_role, persona_age, persona_location, persona_education, persona_quote,
         persona_profession, persona_experience, persona_company_size, persona_income,
         trait_explorer, trait_introvert, trait_optimist, trait_calm,
         persona_story, persona_values, persona_goals, persona_frustrations,
         persona_mobile_apps, persona_desktop_apps, persona_day_in_life) 
        VALUES (
          '%s',
          CURRENT_TIMESTAMP(),
          CURRENT_TIMESTAMP(),
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          %d,
          '%s',
          '%s',
          '%s',
          '%s',
          %d,
          '%s',
          '%s',
          %d,
          %d,
          %d,
          %d,
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s',
          '%s'
        )",
                              values$full_table_id,
                              persona_id_clean,
                              p$business_area,
                              p$project,
                              p$business_focus,
                              p$persona_name,
                              p$persona_role,
                              p$persona_age,
                              p$persona_location,
                              p$persona_education,
                              p$persona_quote,
                              p$persona_profession,
                              p$persona_experience,
                              p$persona_company_size,
                              p$persona_income,
                              p$trait_explorer,
                              p$trait_introvert,
                              p$trait_optimist,
                              p$trait_calm,
                              p$persona_story,
                              p$persona_values,
                              p$persona_goals,
                              p$persona_frustrations,
                              p$persona_mobile_apps,
                              p$persona_desktop_apps,
                              p$persona_day_in_life
      )
      
      bq_project_query(values$project_id, insert_query)
      
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Successfully submitted Persona Canvas to BigQuery!",
                 br(),
                 tags$small("Persona ID: ", persona_id))
      })
      
      showNotification("✓ Persona submitted successfully!", type = "message")
      
    }, error = function(e) {
      output$bulkPersonaStatus <- renderUI({
        tags$div(class = "status-error",
                 tags$i(class = "fa fa-times-circle"),
                 " Error submitting to BigQuery: ",
                 br(),
                 tags$small(e$message))
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # ============================================
  # CLEAR PERSONA DATA (NEW)
  # ============================================
  observeEvent(input$clearPersona, {
    updateTextInput(session, "bulk_business_area", value = "")
    updateTextInput(session, "bulk_project", value = "")
    updateTextInput(session, "bulk_business_focus", value = "")
    updateTextAreaInput(session, "bulk_persona_text", value = "")
    values$parsed_persona <- NULL
    output$bulkPersonaStatus <- renderUI({
      tags$div(class = "status-info",
               tags$i(class = "fa fa-info-circle"),
               " All fields cleared. Ready for new input.")
    })
    output$parsePersonaInfo <- renderUI(NULL)
    output$parsedPersonaPreview <- renderText("")
  })
  
  # ============================================
  # YOUR EXISTING CODE BELOW - Keep everything from your original server
  # ============================================
  
  # Generate canvas when button is clicked (YOUR EXISTING CODE)
  observeEvent(input$generate_canvas, {
    values$canvas_generated <- TRUE
    showNotification("✓ Persona canvas generated successfully!", type = "message", duration = 3)
  })
  
  # Render the persona canvas (YOUR EXISTING CODE)
  output$persona_canvas_display <- renderUI({
    req(values$canvas_generated)
    
    # Parse values into lists
    values_list <- strsplit(input$persona_values, "\n")[[1]]
    goals_list <- strsplit(input$persona_goals, "\n")[[1]]
    frustrations_list <- strsplit(input$persona_frustrations, "\n")[[1]]
    mobile_apps <- strsplit(input$persona_mobile_apps, "\n")[[1]]
    desktop_apps <- strsplit(input$persona_desktop_apps, "\n")[[1]]
    day_activities <- strsplit(input$persona_day_in_life, "\n")[[1]]
    
    tagList(
      div(class = "persona-card",
          
          # Header with photo and name
          div(class = "persona-header",
              div(class = "persona-photo",
                  substr(input$persona_name, 1, 1)
              ),
              div(class = "persona-name-section",
                  h1(class = "persona-name", input$persona_name),
                  p(class = "persona-subtitle", 
                    paste(input$persona_role, ",", input$persona_age, ",", input$persona_location)),
                  div(class = "persona-quote",
                      paste0('"', input$persona_quote, '"')
                  )
              )
          ),
          
          # Demographics bar
          div(class = "demographics-section",
              div(class = "demo-item",
                  div(class = "demo-label", "Experience"),
                  div(class = "demo-value", paste(input$persona_experience, "years"))
              ),
              div(class = "demo-item",
                  div(class = "demo-label", "Education"),
                  div(class = "demo-value", input$persona_education)
              ),
              div(class = "demo-item",
                  div(class = "demo-label", "Income"),
                  div(class = "demo-value", input$persona_income)
              )
          ),
          
          # Main content grid
          div(class = "persona-grid",
              
              # Story section (full width)
              div(class = "persona-section section-blue full-width-section",
                  h3(class = "section-title", style = "color: #008A82;", "STORY"),
                  div(class = "section-content",
                      p(input$persona_story)
                  )
              ),
              
              # Values section
              div(class = "persona-section section-purple",
                  h3(class = "section-title", style = "color: #9b59b6;", "VALUES"),
                  div(class = "section-content",
                      tags$ul(
                        lapply(values_list, function(x) if(nchar(trimws(x)) > 0) tags$li(x))
                      )
                  )
              ),
              
              # Goals section
              div(class = "persona-section section-green",
                  h3(class = "section-title", style = "color: #00A39A;", "GOALS"),
                  div(class = "section-content",
                      tags$ul(
                        lapply(goals_list, function(x) if(nchar(trimws(x)) > 0) tags$li(x))
                      )
                  )
              ),
              
              # Frustrations section
              div(class = "persona-section section-red",
                  h3(class = "section-title", style = "color: #e74c3c;", "FRUSTRATIONS"),
                  div(class = "section-content",
                      tags$ul(
                        lapply(frustrations_list, function(x) if(nchar(trimws(x)) > 0) tags$li(x))
                      )
                  )
              ),
              
              # Personality section
              div(class = "persona-section section-orange",
                  h3(class = "section-title", style = "color: #f39c12;", "PERSONALITY"),
                  div(class = "section-content",
                      div(class = "personality-grid",
                          div(class = "personality-item",
                              div(class = "personality-label", "EXPLORER vs KEEPER"),
                              div(class = "personality-scale",
                                  div(class = "personality-fill", 
                                      style = paste0("width: ", input$trait_explorer, "%"))
                              ),
                              div(class = "personality-value", paste0(input$trait_explorer, "%"))
                          ),
                          div(class = "personality-item",
                              div(class = "personality-label", "INTROVERT vs EXTROVERT"),
                              div(class = "personality-scale",
                                  div(class = "personality-fill", 
                                      style = paste0("width: ", input$trait_introvert, "%"))
                              ),
                              div(class = "personality-value", paste0(input$trait_introvert, "%"))
                          ),
                          div(class = "personality-item",
                              div(class = "personality-label", "OPTIMIST vs PESSIMIST"),
                              div(class = "personality-scale",
                                  div(class = "personality-fill", 
                                      style = paste0("width: ", input$trait_optimist, "%"))
                              ),
                              div(class = "personality-value", paste0(input$trait_optimist, "%"))
                          ),
                          div(class = "personality-item",
                              div(class = "personality-label", "CALM vs ANXIOUS"),
                              div(class = "personality-scale",
                                  div(class = "personality-fill", 
                                      style = paste0("width: ", input$trait_calm, "%"))
                              ),
                              div(class = "personality-value", paste0(input$trait_calm, "%"))
                          )
                      )
                  )
              ),
              
              # Apps & Tools section (full width)
              div(class = "persona-section section-teal full-width-section",
                  h3(class = "section-title", style = "color: #00A39A;", "APPS & TOOLS"),
                  div(class = "section-content",
                      fluidRow(
                        column(6,
                               h4("Mobile"),
                               tags$ul(
                                 lapply(mobile_apps, function(x) if(nchar(trimws(x)) > 0) tags$li(x))
                               )
                        ),
                        column(6,
                               h4("Desktop"),
                               tags$ul(
                                 lapply(desktop_apps, function(x) if(nchar(trimws(x)) > 0) tags$li(x))
                               )
                        )
                      )
                  )
              ),
              
              # Day in the Life section (full width)
              div(class = "persona-section section-lightblue full-width-section",
                  h3(class = "section-title", style = "color: #3498db;", "A DAY IN THE LIFE"),
                  div(class = "section-content",
                      tags$ul(
                        lapply(day_activities, function(x) if(nchar(trimws(x)) > 0) tags$li(x))
                      )
                  )
              )
          )
      )
    )
  })
  
  # Download HTML (YOUR EXISTING CODE - keep as is)
  output$download_html <- downloadHandler(
    filename = function() {
      paste0("persona-", gsub(" ", "-", tolower(input$persona_name)), "-", Sys.Date(), ".html")
    },
    content = function(file) {
      # Your existing HTML generation code here
      html_content <- paste0("
<!DOCTYPE html>
<html>
<head>
  <meta charset='utf-8'>
  <title>Persona: ", input$persona_name, "</title>
  <style>
    body { 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 40px; 
      background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%);
      min-height: 100vh;
    }
    .persona-card { 
      background: rgba(255, 255, 255, 0.98); 
      padding: 40px; 
      border-radius: 12px; 
      max-width: 1200px; 
      margin: 0 auto;
      box-shadow: 0 8px 25px rgba(0, 44, 60, 0.3);
    }
    .persona-header { 
      display: flex; 
      gap: 30px; 
      margin-bottom: 30px; 
      padding-bottom: 25px; 
      border-bottom: 2px solid rgba(0, 138, 130, 0.2);
    }
    .persona-photo { 
      width: 220px; 
      height: 220px; 
      background: linear-gradient(135deg, #008A82 0%, #00A39A 100%); 
      border-radius: 15px; 
      display: flex; 
      align-items: center; 
      justify-content: center; 
      color: white; 
      font-size: 72px; 
      font-weight: bold;
      box-shadow: 0 4px 12px rgba(0, 138, 130, 0.4);
    }
    .persona-name { 
      font-size: 52px; 
      font-weight: 700; 
      color: #002C3C; 
      margin: 0; 
    }
    .persona-subtitle { 
      font-size: 20px; 
      color: #2c3e50; 
      margin: 10px 0; 
    }
    .persona-quote { 
      font-style: italic; 
      color: #555; 
      padding: 18px 20px; 
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); 
      border-left: 5px solid #008A82; 
      margin-top: 15px;
      border-radius: 0 8px 8px 0;
    }
    .demographics-section {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 18px;
      margin: 25px 0;
    }
    .demo-item {
      background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
      padding: 18px;
      border-radius: 10px;
      border-left: 4px solid #008A82;
    }
    .demo-label {
      font-size: 11px;
      color: #6c757d;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      font-weight: 600;
    }
    .demo-value {
      font-size: 18px;
      font-weight: 700;
      color: #002C3C;
      margin-top: 6px;
    }
    .persona-grid { 
      display: grid; 
      grid-template-columns: repeat(2, 1fr); 
      gap: 20px; 
      margin-top: 25px; 
    }
    .persona-section { 
      border: 2px solid #e0e0e0; 
      border-radius: 15px; 
      padding: 25px;
      box-shadow: 0 2px 6px rgba(0, 44, 60, 0.1);
    }
    .section-blue { border-color: #008A82; background: linear-gradient(135deg, #e6f7f5 0%, #d4f1ee 100%); }
    .section-purple { border-color: #9b59b6; background: linear-gradient(135deg, #f9f7fc 0%, #f3eef9 100%); }
    .section-green { border-color: #00A39A; background: linear-gradient(135deg, #e6faf9 0%, #d4f5f3 100%); }
    .section-red { border-color: #e74c3c; background: linear-gradient(135deg, #fff5f7 0%, #ffe8ed 100%); }
    .section-orange { border-color: #f39c12; background: linear-gradient(135deg, #fff9f0 0%, #fef5ed 100%); }
    .section-teal { border-color: #00A39A; background: linear-gradient(135deg, #d4f5f3 0%, #c2f0ed 100%); }
    .section-lightblue { border-color: #3498db; background: linear-gradient(135deg, #e8f4fd 0%, #d6ecfb 100%); }
    .section-title { 
      font-size: 19px; 
      font-weight: 700; 
      margin: 0 0 18px 0; 
      padding-bottom: 12px; 
      border-bottom: 2px solid currentColor;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .full-width-section { grid-column: 1 / -1; }
    ul { margin: 12px 0; padding-left: 22px; }
    li { margin-bottom: 10px; }
    .section-content { color: #555; line-height: 1.7; font-size: 15px; }
    h4 { color: #002C3C; font-size: 16px; font-weight: 600; margin: 15px 0 10px 0; }
  </style>
</head>
<body>
  <div class='persona-card'>
    <div class='persona-header'>
      <div class='persona-photo'>", substr(input$persona_name, 1, 1), "</div>
      <div>
        <h1 class='persona-name'>", input$persona_name, "</h1>
        <p class='persona-subtitle'>", input$persona_role, ", ", input$persona_age, ", ", input$persona_location, "</p>
        <div class='persona-quote'>\"", input$persona_quote, "\"</div>
      </div>
    </div>
    <div class='demographics-section'>
      <div class='demo-item'>
        <div class='demo-label'>Experience</div>
        <div class='demo-value'>", input$persona_experience, " years</div>
      </div>
      <div class='demo-item'>
        <div class='demo-label'>Education</div>
        <div class='demo-value'>", input$persona_education, "</div>
      </div>
      <div class='demo-item'>
        <div class='demo-label'>Income</div>
        <div class='demo-value'>", input$persona_income, "</div>
      </div>
    </div>
    <div class='persona-grid'>
      <div class='persona-section section-blue full-width-section'>
        <h3 class='section-title' style='color: #008A82;'>STORY</h3>
        <div class='section-content'><p>", input$persona_story, "</p></div>
      </div>
      <div class='persona-section section-purple'>
        <h3 class='section-title' style='color: #9b59b6;'>VALUES</h3>
        <div class='section-content'><ul>", paste(sapply(strsplit(input$persona_values, "\n")[[1]], function(x) if(nchar(trimws(x))>0) paste0("<li>", x, "</li>") else ""), collapse=""), "</ul></div>
      </div>
      <div class='persona-section section-green'>
        <h3 class='section-title' style='color: #00A39A;'>GOALS</h3>
        <div class='section-content'><ul>", paste(sapply(strsplit(input$persona_goals, "\n")[[1]], function(x) if(nchar(trimws(x))>0) paste0("<li>", x, "</li>") else ""), collapse=""), "</ul></div>
      </div>
      <div class='persona-section section-red'>
        <h3 class='section-title' style='color: #e74c3c;'>FRUSTRATIONS</h3>
        <div class='section-content'><ul>", paste(sapply(strsplit(input$persona_frustrations, "\n")[[1]], function(x) if(nchar(trimws(x))>0) paste0("<li>", x, "</li>") else ""), collapse=""), "</ul></div>
      </div>
      <div class='persona-section section-orange'>
        <h3 class='section-title' style='color: #f39c12;'>PERSONALITY</h3>
        <div class='section-content'>
          <p><strong>Explorer:</strong> ", input$trait_explorer, "%<br>
          <strong>Introvert:</strong> ", input$trait_introvert, "%<br>
          <strong>Optimist:</strong> ", input$trait_optimist, "%<br>
          <strong>Calm:</strong> ", input$trait_calm, "%</p>
        </div>
      </div>
      <div class='persona-section section-teal full-width-section'>
        <h3 class='section-title' style='color: #00A39A;'>APPS & TOOLS</h3>
        <div class='section-content' style='display:grid; grid-template-columns: 1fr 1fr; gap: 20px;'>
          <div><h4>Mobile</h4><ul>", paste(sapply(strsplit(input$persona_mobile_apps, "\n")[[1]], function(x) if(nchar(trimws(x))>0) paste0("<li>", x, "</li>") else ""), collapse=""), "</ul></div>
          <div><h4>Desktop</h4><ul>", paste(sapply(strsplit(input$persona_desktop_apps, "\n")[[1]], function(x) if(nchar(trimws(x))>0) paste0("<li>", x, "</li>") else ""), collapse=""), "</ul></div>
        </div>
      </div>
      <div class='persona-section section-lightblue full-width-section'>
        <h3 class='section-title' style='color: #3498db;'>A DAY IN THE LIFE</h3>
        <div class='section-content'><ul>", paste(sapply(strsplit(input$persona_day_in_life, "\n")[[1]], function(x) if(nchar(trimws(x))>0) paste0("<li>", x, "</li>") else ""), collapse=""), "</ul></div>
      </div>
    </div>
  </div>
</body>
</html>
      ")
      
      writeLines(html_content, file)
    }
  )
  
  # Download PDF placeholder (YOUR EXISTING CODE)
  output$download_pdf <- downloadHandler(
    filename = function() {
      paste0("persona-", gsub(" ", "-", tolower(input$persona_name)), "-", Sys.Date(), ".pdf")
    },
    content = function(file) {
      showNotification("PDF export requires additional setup (webshot/pagedown packages). Please use HTML export for now.", 
                       type = "warning", duration = 5)
    }
  )
  
  # ============================================
  # CLEAN UP TEMP FILES ON SESSION END
  # ============================================
  session$onSessionEnded(function() {
    if (!is.null(values$temp_file_path) && file.exists(values$temp_file_path)) {
      unlink(values$temp_file_path)
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)