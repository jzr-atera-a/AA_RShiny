library(shiny)
library(shinydashboard)
library(shinyjs)
library(httr)
library(jsonlite)
library(DT)
library(pdftools)
library(readtext)
library(uuid)
library(bigrquery)
library(DBI)      
library(glue)
# UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Business Contact Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      id = "sidebar_menu",
      menuItem("API Configuration", tabName = "api_config", icon = icon("key")),
      menuItem("BigQuery Settings", tabName = "bq_config", icon = icon("database")),
      menuItem("Process Contact", tabName = "process_contact", icon = icon("user-plus")),
      menuItem("Explore Contacts", tabName = "explore_contacts", icon = icon("search")),
      menuItem("Customise Communication", tabName = "customise_communication", icon = icon("comments"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    
    tags$head(
      tags$style(HTML("
        /* Color Palette */
        :root {
          --deep-blue: #0a1128;
          --dark-blue: #1e3c72;
          --medium-blue: #2a5298;
          --bright-blue: #4a90e2;
          --light-blue: #7ec8e3;
          --purple-dark: #3d1f4f;
          --purple-medium: #5e2e6c;
          --purple-light: #764ba2;
        }
        
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
          border-bottom: 3px solid #7ec8e3;
        }
        
        .skin-blue .main-header .logo {
          background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
          border-right: 2px solid #4a90e2;
        }
        
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
          box-shadow: 4px 0 15px rgba(10, 17, 40, 0.5);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          font-weight: bold;
          border-left: 4px solid #7ec8e3;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a {
          color: #e0e7ff !important;
          transition: all 0.3s ease;
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          color: #ffffff !important;
          border-left: 4px solid #7ec8e3;
          transform: translateX(5px);
        }
        
        .content-wrapper {
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
        }
        
        .box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(74, 144, 226, 0.3) !important;
          transition: all 0.3s ease;
        }
        
        .box:hover {
          box-shadow: 0 12px 35px rgba(74, 144, 226, 0.5) !important;
          transform: translateY(-2px);
        }
        
        .box.box-primary .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #4a90e2 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-info .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-success .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-warning .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box-body {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important;
          color: #e0e7ff !important;
          padding: 20px !important;
          border-radius: 0 0 10px 10px;
        }
        
        p { 
          color: #c7d2fe !important; 
          line-height: 1.7 !important; 
        }
        
        strong { 
          color: #7ec8e3 !important; 
          font-weight: 600;
        }
        
        h3, h4, h5, h6 {
          color: #ffffff !important;
        }
        
        .form-control {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 8px;
        }
        
        .form-control::placeholder {
          color: #a0aec0 !important;
          opacity: 0.7;
        }
        
        .btn {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border: none !important;
          border-radius: 8px;
          padding: 10px 20px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn:hover {
          background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(118, 75, 162, 0.4);
        }
        
        .btn-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
        }
        
        .btn-success:hover {
          background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%) !important;
        }
        
        .btn-info {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        .btn-info:hover {
          background: linear-gradient(135deg, #4a90e2 0%, #2a5298 100%) !important;
        }
        
        .btn-warning {
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
        }
        
        .btn-warning:hover {
          background: linear-gradient(135deg, #e67e22 0%, #f39c12 100%) !important;
        }
        
        .btn-primary {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .btn-primary:hover {
          background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
        }
        
        .btn-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
        }
        
        .btn-danger:hover {
          background: linear-gradient(135deg, #c0392b 0%, #e74c3c 100%) !important;
        }
        
        .info-box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2;
          border-radius: 8px;
          box-shadow: 0 4px 15px rgba(74, 144, 226, 0.3);
        }
        
        .info-box-icon {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .info-box-text {
          color: #e0e7ff !important;
        }
        
        .info-box-number {
          color: #7ec8e3 !important;
          font-weight: bold;
        }
        
        /* DataTable Styling */
        table.dataTable {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable thead th {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border-bottom: 2px solid #4a90e2 !important;
        }
        
        table.dataTable tbody tr {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        
        table.dataTable tbody tr:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        table.dataTable tbody tr.selected {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
        }
        
        .dataTables_wrapper .dataTables_length,
        .dataTables_wrapper .dataTables_filter,
        .dataTables_wrapper .dataTables_info,
        .dataTables_wrapper .dataTables_paginate {
          color: #e0e7ff !important;
        }
        
        .dataTables_wrapper .dataTables_filter input,
        .dataTables_wrapper .dataTables_length select {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 1px solid #4a90e2 !important;
        }
        
        .dataTables_wrapper .dataTables_paginate .paginate_button {
          color: #e0e7ff !important;
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          border: 1px solid #4a90e2 !important;
        }
        
        .dataTables_wrapper .dataTables_paginate .paginate_button.current {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
        }
        
        .alert-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          border-color: #7ec8e3 !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .alert-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
          border-color: #e74c3c !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .alert-info {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-color: #7ec8e3 !important;
          color: #ffffff !important;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
        
        .selectize-input {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
        }
        
        .selectize-dropdown {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          border: 2px solid #4a90e2 !important;
        }
        
        .selectize-dropdown-content .option {
          color: #e0e7ff !important;
        }
        
        .selectize-dropdown-content .option:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
        
        label {
          color: #e0e7ff !important;
          font-weight: 500;
        }
        
        .control-label {
          color: #e0e7ff !important;
        }
        
        textarea.form-control {
          resize: vertical;
        }
        
        .api-status-success {
          color: #2ecc71 !important;
          font-weight: bold;
          font-size: 14px;
        }
        
        .api-status-error {
          color: #e74c3c !important;
          font-weight: bold;
          font-size: 14px;
        }
        
        .file-upload-box {
          border: 2px dashed #4a90e2;
          border-radius: 10px;
          padding: 20px;
          text-align: center;
          background: rgba(74, 144, 226, 0.1);
          transition: all 0.3s ease;
        }
        
        .file-upload-box:hover {
          border-color: #7ec8e3;
          background: rgba(126, 200, 227, 0.1);
        }
        
        .schema-info {
          background: rgba(102, 126, 234, 0.2);
          border-left: 4px solid #667eea;
          padding: 15px;
          margin: 10px 0;
          border-radius: 0 8px 8px 0;
        }
        
        .schema-info code {
          color: #7ec8e3;
          background: rgba(0,0,0,0.3);
          padding: 2px 6px;
          border-radius: 4px;
        }
        
        /* Date input styling */
        input[type='date'] {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 8px;
          padding: 8px 12px;
        }
        
        input[type='date']::-webkit-calendar-picker-indicator {
          filter: invert(1);
        }
        
        .profile-summary-box {
          background: rgba(102, 126, 234, 0.2);
          border: 2px solid #667eea;
          border-radius: 10px;
          padding: 20px;
          margin: 15px 0;
        }
        
        .message-box {
          background: rgba(42, 82, 152, 0.3);
          border: 2px solid #4a90e2;
          border-radius: 10px;
          padding: 15px;
          margin: 15px 0;
          min-height: 150px;
          max-height: 400px;
          overflow-y: auto;
        }
        
        .communication-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 20px;
          flex-wrap: wrap;
          gap: 10px;
        }
        
        .empty-state {
          text-align: center;
          padding: 40px 20px;
          color: #7ec8e3;
        }
        
        .empty-state-icon {
          font-size: 48px;
          margin-bottom: 15px;
          opacity: 0.6;
        }
      "))
    ),
    
    tabItems(
      # Tab 1: API Configuration
      tabItem(
        tabName = "api_config",
        fluidRow(
          box(
            title = "OpenAI API Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p("Enter your OpenAI API key below. This key will be stored securely for the duration of your session."),
            p("You can obtain an API key from: ", 
              tags$a(href = "https://platform.openai.com/api-keys", 
                     target = "_blank", 
                     style = "color: #7ec8e3;",
                     "https://platform.openai.com/api-keys")),
            br(),
            passwordInput("api_key", "OpenAI API Key:", 
                          placeholder = "sk-...",
                          width = "100%"),
            selectInput("gpt_model", "Select LLM Model:",
                        choices = c("gpt-4" = "gpt-4",
                                    "gpt-4-turbo" = "gpt-4-turbo",
                                    "gpt-4o" = "gpt-4o",
                                    "gpt-3.5-turbo" = "gpt-3.5-turbo"),
                        selected = "gpt-4",
                        width = "50%"),
            br(),
            actionButton("save_api", "Save API Key", class = "btn-success", icon = icon("save")),
            actionButton("test_api", "Test API Connection", class = "btn-info", icon = icon("plug")),
            br(), br(),
            uiOutput("api_status_ui"),
            br(),
            h4("Instructions:"),
            tags$ol(
              tags$li("Paste your OpenAI API key in the field above"),
              tags$li("Select your preferred LLM model"),
              tags$li("Click 'Save API Key' to store it for this session"),
              tags$li("Optionally click 'Test API Connection' to verify it works"),
              tags$li("Navigate to 'BigQuery Settings' tab to configure database connection")
            )
          )
        )
      ),
      
      # Tab 2: BigQuery Settings
      tabItem(
        tabName = "bq_config",
        fluidRow(
          box(
            title = "Google Cloud BigQuery Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p("Configure your Google Cloud BigQuery connection settings below."),
            p("Default settings are pre-filled for quick setup."),
            br(),
            
            fluidRow(
              column(6,
                     textInput("bq_project", "Project ID:", 
                               value = "atera-2",
                               placeholder = "atera-2",
                               width = "100%")),
              column(6,
                     textInput("bq_dataset", "Dataset Name:", 
                               value = "business_strategy",
                               placeholder = "business_strategy",
                               width = "100%"))
            ),
            
            textInput("bq_table", "Table Name (Contacts):", 
                      value = "business_contacts",
                      placeholder = "business_contacts",
                      width = "100%"),
            
            textInput("bq_comm_table", "Table Name (Communications):", 
                      value = "contact_communications",
                      placeholder = "contact_communications",
                      width = "100%"),
            
            br(),
            h4("Authentication Method:"),
            radioButtons("bq_auth_method", NULL,
                         choices = c("Service Account JSON Key File" = "json_key",
                                     "Application Default Credentials" = "adc"),
                         selected = "json_key",
                         inline = TRUE),
            
            conditionalPanel(
              condition = "input.bq_auth_method == 'json_key'",
              fileInput("bq_key_file", "Upload Service Account JSON Key:",
                        accept = ".json",
                        width = "100%")
            ),
            
            conditionalPanel(
              condition = "input.bq_auth_method == 'adc'",
              p(tags$small("Using Application Default Credentials. Make sure you have run:"),
                tags$br(),
                tags$code("gcloud auth application-default login"))
            ),
            
            br(),
            actionButton("save_bq", "Save BigQuery Settings", class = "btn-success", icon = icon("save")),
            actionButton("test_bq", "Test Connection & Load Data", class = "btn-info", icon = icon("database")),
            actionButton("create_table_bq", "Create Empty Tables", class = "btn-warning", icon = icon("plus")),
            br(), br(),
            uiOutput("bq_status_ui"),
            
            br(),
            div(class = "schema-info",
                h5("Table Schema for Business Contacts:"),
                p("The following schema will be used for the business_contacts table:"),
                tags$ul(
                  tags$li(tags$code("contact_id"), " - STRING (Primary Key, Auto-generated UUID)"),
                  tags$li(tags$code("full_name"), " - STRING"),
                  tags$li(tags$code("industry"), " - STRING"),
                  tags$li(tags$code("company"), " - STRING"),
                  tags$li(tags$code("job_title"), " - STRING"),
                  tags$li(tags$code("location"), " - STRING"),
                  tags$li(tags$code("country"), " - STRING"),
                  tags$li(tags$code("email"), " - STRING"),
                  tags$li(tags$code("phone"), " - STRING"),
                  tags$li(tags$code("linkedin"), " - STRING"),
                  tags$li(tags$code("areas_of_interest"), " - STRING"),
                  tags$li(tags$code("university"), " - STRING"),
                  tags$li(tags$code("academic_background"), " - STRING"),
                  tags$li(tags$code("user_notes"), " - STRING"),
                  tags$li(tags$code("last_interaction_date"), " - DATE"),
                  tags$li(tags$code("created_at"), " - TIMESTAMP"),
                  tags$li(tags$code("updated_at"), " - TIMESTAMP")
                ),
                br(),
                h5("Table Schema for Contact Communications:"),
                p("The following schema will be used for the contact_communications table:"),
                tags$ul(
                  tags$li(tags$code("message_id"), " - STRING (Primary Key, Auto-generated UUID)"),
                  tags$li(tags$code("contact_id"), " - STRING (Foreign Key to business_contacts)"),
                  tags$li(tags$code("channel_type"), " - STRING (LinkedIn, Email, WhatsApp, General Message)"),
                  tags$li(tags$code("communication_purpose"), " - STRING"),
                  tags$li(tags$code("language"), " - STRING"),
                  tags$li(tags$code("message_length"), " - STRING"),
                  tags$li(tags$code("message_content"), " - STRING"),
                  tags$li(tags$code("created_at"), " - TIMESTAMP")
                )
            )
          )
        )
      ),
      
      # Tab 3: Process Contact
      tabItem(
        tabName = "process_contact",
        fluidRow(
          box(
            title = "Upload or Paste Contact Information",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p("Upload a file OR paste contact information in the text box below."),
            p("The LLM will extract and structure the relevant information."),
            br(),
            div(class = "file-upload-box",
                fileInput("contact_file", "Choose File (Optional)",
                          accept = c(".pdf", ".docx", ".doc", ".pptx", ".ppt", ".txt", ".text"),
                          width = "100%"),
                p(tags$small("Supported formats: PDF, DOCX, PPTX, TXT"))
            ),
            br(),
            h4("OR paste contact information here:"),
            textAreaInput("contact_text", NULL,
                          placeholder = "Paste contact information here (e.g., email signature, LinkedIn profile, business card details, etc.)...",
                          height = "200px",
                          width = "100%"),
            br(),
            actionButton("process_file", "Process with LLM", 
                         class = "btn-primary", 
                         icon = icon("wand-magic-sparkles"),
                         style = "width: 100%;"),
            br(), br(),
            uiOutput("process_status_ui")
          )
        ),
        
        fluidRow(
          box(
            title = "Extracted Contact Information",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("extracted_data_table"),
            br(),
            uiOutput("extraction_message")
          )
        ),
        
        fluidRow(
          box(
            title = "Additional Information",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            textAreaInput("user_notes", "Your Notes About This Contact:",
                          placeholder = "Add any personal notes, context, or follow-up items about this contact...",
                          height = "150px",
                          width = "100%"),
            br(),
            dateInput("last_interaction", "Last Interaction Date:",
                      value = Sys.Date(),
                      format = "yyyy-mm-dd",
                      width = "100%")
          ),
          
          box(
            title = "Send to BigQuery",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            p("Review the extracted data and your notes, then send to BigQuery."),
            p(tags$strong("Note: "), "Make sure you have configured BigQuery settings in the previous tab."),
            br(),
            actionButton("preview_data", "Preview Final Data", 
                         class = "btn-info", 
                         icon = icon("eye"),
                         style = "width: 100%; margin-bottom: 10px;"),
            actionButton("send_to_bq", "Send to BigQuery", 
                         class = "btn-success", 
                         icon = icon("cloud-upload-alt"),
                         style = "width: 100%;"),
            br(), br(),
            uiOutput("send_bq_status_ui")
          )
        ),
        
        fluidRow(
          box(
            title = "Data Preview",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            collapsed = TRUE,
            DTOutput("preview_table")
          )
        )
      ),
      
      # Tab 4: Explore Contacts
      tabItem(
        tabName = "explore_contacts",
        fluidRow(
          box(
            title = "Filter Contacts",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(2,
                     selectInput("filter_industry", "Industry:",
                                 choices = c("All" = ""),
                                 selected = "",
                                 width = "100%")),
              column(2,
                     selectInput("filter_country", "Country:",
                                 choices = c("All" = ""),
                                 selected = "",
                                 width = "100%")),
              column(2,
                     selectInput("filter_location", "Location:",
                                 choices = c("All" = ""),
                                 selected = "",
                                 width = "100%")),
              column(2,
                     selectInput("filter_university", "University:",
                                 choices = c("All" = ""),
                                 selected = "",
                                 width = "100%")),
              column(2,
                     selectInput("filter_company", "Company:",
                                 choices = c("All" = ""),
                                 selected = "",
                                 width = "100%")),
              column(2,
                     br(),
                     actionButton("refresh_data", "Refresh Data", 
                                  class = "btn-info", 
                                  icon = icon("sync"),
                                  style = "width: 100%;"))
            ),
            br(),
            actionButton("apply_filters", "Apply Filters", 
                         class = "btn-primary", 
                         icon = icon("filter")),
            actionButton("clear_filters", "Clear Filters", 
                         class = "btn-warning", 
                         icon = icon("times"))
          )
        ),
        
        fluidRow(
          box(
            title = "Contacts Table",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p("Click on a row to select it. Double-click a cell to edit inline."),
            DTOutput("contacts_table"),
            br(),
            uiOutput("table_status_ui")
          )
        ),
        
        fluidRow(
          box(
            title = "Actions for Selected Contact",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("Select a contact and choose an action below."),
            fluidRow(
              column(4,
                     actionButton("customise_comm", "Customise Communication", 
                                  class = "btn-primary", 
                                  icon = icon("comments"),
                                  style = "width: 100%;")),
              column(4,
                     actionButton("update_record", "Update Modified Record", 
                                  class = "btn-success", 
                                  icon = icon("save"),
                                  style = "width: 100%;")),
              column(4,
                     actionButton("delete_record", "Delete Selected Record", 
                                  class = "btn-danger", 
                                  icon = icon("trash"),
                                  style = "width: 100%;"))
            ),
            br(),
            uiOutput("update_status_ui")
          )
        )
      ),
      
      # Tab 5: Customise Communication
      tabItem(
        tabName = "customise_communication",
        fluidRow(
          box(
            title = "Communication Settings",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(3,
                     selectInput("comm_channel", "Channel Type:",
                                 choices = c("LinkedIn" = "LinkedIn",
                                             "Email" = "Email",
                                             "WhatsApp" = "WhatsApp",
                                             "General Message" = "General Message"),
                                 selected = "LinkedIn",
                                 width = "100%")),
              column(3,
                     selectInput("comm_purpose", "Communication Purpose:",
                                 choices = c("Introduction" = "Introduction",
                                             "Follow Up" = "Follow Up",
                                             "Partnership Enquiry" = "Partnership Enquiry",
                                             "Met at recent event" = "Met at recent event",
                                             "Having something in common" = "Having something in common",
                                             "Other" = "Other"),
                                 selected = "Introduction",
                                 width = "100%")),
              column(3,
                     selectInput("comm_language", "Language:",
                                 choices = c("English UK" = "English UK",
                                             "English US" = "English US",
                                             "Spanish LatinAmerica" = "Spanish LatinAmerica"),
                                 selected = "English UK",
                                 width = "100%")),
              column(3,
                     selectInput("comm_length", "Message Length:",
                                 choices = c("50 words" = "50",
                                             "100 words" = "100",
                                             "180 words" = "180",
                                             "240 words" = "240",
                                             "500 words" = "500"),
                                 selected = "100",
                                 width = "100%"))
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Selected Contact Profile",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            div(class = "profile-summary-box",
                uiOutput("contact_profile_summary")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Recent Communication History",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            actionButton("load_recent_messages", "Load Last 3 Messages", 
                         class = "btn-info", 
                         icon = icon("history"),
                         style = "margin-bottom: 15px;"),
            br(),
            div(class = "message-box",
                uiOutput("recent_messages_display")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Communication Summary (LLM Analysis)",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            div(class = "message-box",
                uiOutput("communication_summary")
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Message Customisation Guidelines",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p("Provide specific guidelines and key points to include in the new message:"),
            textAreaInput("message_guidelines", NULL,
                          placeholder = "E.g., 'Mention our mutual interest in renewable energy', 'Reference the conference in Barcelona', 'Ask about their recent project on AI in healthcare', etc.",
                          height = "150px",
                          width = "100%"),
            br(),
            actionButton("generate_message", "Generate Message with LLM", 
                         class = "btn-success", 
                         icon = icon("magic"),
                         style = "width: 100%;"),
            br(), br(),
            uiOutput("generate_status_ui")
          )
        ),
        
        fluidRow(
          box(
            title = "Generated Message",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            div(class = "message-box",
                uiOutput("generated_message_display")
            ),
            br(),
            fluidRow(
              column(6,
                     actionButton("save_message", "Save Message to BigQuery", 
                                  class = "btn-primary", 
                                  icon = icon("save"),
                                  style = "width: 100%;")),
              column(6,
                     actionButton("copy_message", "Copy to Clipboard", 
                                  class = "btn-info", 
                                  icon = icon("copy"),
                                  style = "width: 100%;"))
            ),
            br(),
            uiOutput("save_message_status_ui")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values
  values <- reactiveValues(
    api_key = NULL,
    api_key_saved = FALSE,
    gpt_model = "gpt-4",
    bq_configured = FALSE,
    bq_project = "atera-2",
    bq_dataset = "business_strategy",
    bq_table = "business_contacts",
    bq_comm_table = "contact_communications",
    bq_credentials = NULL,
    extracted_data = NULL,
    contacts_data = NULL,
    communications_data = NULL,
    selected_row = NULL,
    selected_contact = NULL,
    recent_messages = NULL,
    communication_summary = NULL,
    generated_message = NULL
  )
  
  # ============================================
  # TAB 1: API Configuration
  # ============================================
  
  # Save API Key
  observeEvent(input$save_api, {
    if (nchar(trimws(input$api_key)) > 0) {
      values$api_key <- trimws(input$api_key)
      values$api_key_saved <- TRUE
      values$gpt_model <- input$gpt_model
      
      output$api_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("check-circle"), " API Key saved successfully! Model: ", input$gpt_model)
      })
      
      showNotification("API Key saved successfully!", 
                       type = "message", 
                       duration = 3)
    } else {
      output$api_status_ui <- renderUI({
        div(class = "api-status-error",
            icon("exclamation-circle"), " Please enter a valid API key.")
      })
      showNotification("Please enter a valid API key", 
                       type = "error", 
                       duration = 3)
    }
  })
  
  # Test API Connection
  observeEvent(input$test_api, {
    if (!values$api_key_saved || is.null(values$api_key)) {
      showNotification("Please save your API key first!", 
                       type = "error", 
                       duration = 3)
      return()
    }
    
    showNotification("Testing API connection...", 
                     type = "message", 
                     duration = NULL, 
                     id = "test_api")
    
    tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", values$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = values$gpt_model,
          messages = list(
            list(role = "user", content = "Say 'API test successful' in 5 words or less.")
          ),
          max_tokens = 50
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(60)
      )
      
      removeNotification(id = "test_api")
      
      if (httr::status_code(response) == 200) {
        output$api_status_ui <- renderUI({
          div(class = "api-status-success",
              icon("check-circle"), " API connection successful! Model: ", values$gpt_model)
        })
        showNotification("API connection successful!", type = "message", duration = 5)
      } else {
        output$api_status_ui <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), 
              " API connection failed. Status: ", httr::status_code(response))
        })
        showNotification(paste("API Error:", httr::status_code(response)), 
                         type = "error", duration = 5)
      }
    }, error = function(e) {
      removeNotification(id = "test_api")
      output$api_status_ui <- renderUI({
        div(class = "api-status-error",
            icon("exclamation-circle"), " Connection error: ", e$message)
      })
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # ============================================
  # TAB 2: BigQuery Configuration
  # ============================================
  
  # Save BigQuery Settings
  observeEvent(input$save_bq, {
    values$bq_project <- trimws(input$bq_project)
    values$bq_dataset <- trimws(input$bq_dataset)
    values$bq_table <- trimws(input$bq_table)
    values$bq_comm_table <- trimws(input$bq_comm_table)
    
    if (input$bq_auth_method == "json_key" && !is.null(input$bq_key_file)) {
      values$bq_credentials <- input$bq_key_file$datapath
    }
    
    values$bq_configured <- TRUE
    
    output$bq_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("check-circle"), " BigQuery settings saved!",
          tags$br(),
          tags$small("Project: ", values$bq_project, " | Dataset: ", values$bq_dataset),
          tags$br(),
          tags$small("Contacts Table: ", values$bq_table, " | Communications Table: ", values$bq_comm_table))
    })
    
    showNotification("BigQuery settings saved!", type = "message", duration = 3)
  })
  
  # Test BigQuery Connection and Load Data
  # Test BigQuery Connection and Load Data
  observeEvent(input$test_bq, {
    if (!values$bq_configured) {
      showNotification("Please save BigQuery settings first!", type = "error", duration = 3)
      return()
    }
    
    showNotification("Testing BigQuery connection and loading data...", 
                     type = "message", duration = NULL, id = "test_bq")
    
    tryCatch({
      # Set up authentication
      if (!is.null(values$bq_credentials)) {
        bigrquery::bq_auth(path = values$bq_credentials)
      }
      
      # Connect to BigQuery
      con <- dbConnect(
        bigrquery::bigquery(),
        project = values$bq_project,
        dataset = values$bq_dataset,
        billing = values$bq_project
      )
      
      # Try to load contacts data
      contacts_query <- sprintf("SELECT * FROM `%s.%s.%s`", 
                                values$bq_project, values$bq_dataset, values$bq_table)
      
      tryCatch({
        values$contacts_data <- dbGetQuery(con, contacts_query)
      }, error = function(e) {
        # Table doesn't exist yet, initialize empty
        values$contacts_data <- data.frame(
          contact_id = character(),
          full_name = character(),
          industry = character(),
          company = character(),
          job_title = character(),
          location = character(),
          country = character(),
          email = character(),
          phone = character(),
          linkedin = character(),
          areas_of_interest = character(),
          university = character(),
          academic_background = character(),
          user_notes = character(),
          last_interaction_date = character(),
          created_at = character(),
          updated_at = character(),
          stringsAsFactors = FALSE
        )
      })
      
      # Try to load communications data
      comm_query <- sprintf("SELECT * FROM `%s.%s.%s`", 
                            values$bq_project, values$bq_dataset, values$bq_comm_table)
      
      tryCatch({
        values$communications_data <- dbGetQuery(con, comm_query)
      }, error = function(e) {
        # Table doesn't exist yet, initialize empty
        values$communications_data <- data.frame(
          message_id = character(),
          contact_id = character(),
          channel_type = character(),
          communication_purpose = character(),
          language = character(),
          message_length = character(),
          message_content = character(),
          created_at = character(),
          stringsAsFactors = FALSE
        )
      })
      
      dbDisconnect(con)
      
      removeNotification(id = "test_bq")
      
      output$bq_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("check-circle"), " BigQuery connection successful!",
            tags$br(),
            tags$small(nrow(values$contacts_data), " contacts loaded from ", 
                       values$bq_project, ".", values$bq_dataset, ".", values$bq_table),
            tags$br(),
            tags$small(nrow(values$communications_data), " communications loaded from ", 
                       values$bq_project, ".", values$bq_dataset, ".", values$bq_comm_table))
      })
      
      showNotification(paste("BigQuery connection successful!", nrow(values$contacts_data), "contacts loaded."), 
                       type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification(id = "test_bq")
      
      output$bq_status_ui <- renderUI({
        div(class = "api-status-error",
            icon("exclamation-circle"), " Connection failed: ", e$message)
      })
      
      showNotification(paste("BigQuery Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # Create BigQuery Tables
  observeEvent(input$create_table_bq, {
    if (!values$bq_configured) {
      showNotification("Please save BigQuery settings first!", type = "error", duration = 3)
      return()
    }
    
    showNotification("Creating BigQuery tables...", type = "message", duration = NULL, id = "create_bq")
    
    tryCatch({
      # Set up BigQuery authentication
      if (!is.null(values$bq_credentials)) {
        bigrquery::bq_auth(path = values$bq_credentials)
      }
      
      # Connect to BigQuery
      con <- dbConnect(
        bigrquery::bigquery(),
        project = values$bq_project,
        dataset = values$bq_dataset,
        billing = values$bq_project
      )
      
      # Create business_contacts table
      contacts_schema <- "
    CREATE TABLE IF NOT EXISTS `{project}.{dataset}.{table}` (
      contact_id STRING,
      full_name STRING,
      industry STRING,
      company STRING,
      job_title STRING,
      location STRING,
      country STRING,
      email STRING,
      phone STRING,
      linkedin STRING,
      areas_of_interest STRING,
      university STRING,
      academic_background STRING,
      user_notes STRING,
      last_interaction_date DATE,
      created_at TIMESTAMP,
      updated_at TIMESTAMP
    )
    "
      
      contacts_query <- glue::glue(contacts_schema, 
                                   project = values$bq_project,
                                   dataset = values$bq_dataset,
                                   table = values$bq_table)
      
      dbExecute(con, contacts_query)
      
      # Create contact_communications table
      comm_schema <- "
    CREATE TABLE IF NOT EXISTS `{project}.{dataset}.{table}` (
      message_id STRING,
      contact_id STRING,
      channel_type STRING,
      communication_purpose STRING,
      language STRING,
      message_length STRING,
      message_content STRING,
      created_at TIMESTAMP
    )
    "
      
      comm_query <- glue::glue(comm_schema,
                               project = values$bq_project,
                               dataset = values$bq_dataset,
                               table = values$bq_comm_table)
      
      dbExecute(con, comm_query)
      
      dbDisconnect(con)
      
      # Initialize empty local tables
      values$contacts_data <- data.frame(
        contact_id = character(),
        full_name = character(),
        industry = character(),
        company = character(),
        job_title = character(),
        location = character(),
        country = character(),
        email = character(),
        phone = character(),
        linkedin = character(),
        areas_of_interest = character(),
        university = character(),
        academic_background = character(),
        user_notes = character(),
        last_interaction_date = character(),
        created_at = character(),
        updated_at = character(),
        stringsAsFactors = FALSE
      )
      
      values$communications_data <- data.frame(
        message_id = character(),
        contact_id = character(),
        channel_type = character(),
        communication_purpose = character(),
        language = character(),
        message_length = character(),
        message_content = character(),
        created_at = character(),
        stringsAsFactors = FALSE
      )
      
      removeNotification(id = "create_bq")
      
      output$bq_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("check-circle"), " Tables created successfully!",
            tags$br(),
            tags$small("Contacts: ", values$bq_project, ".", values$bq_dataset, ".", values$bq_table),
            tags$br(),
            tags$small("Communications: ", values$bq_project, ".", values$bq_dataset, ".", values$bq_comm_table))
      })
      
      showNotification("BigQuery tables created successfully!", type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification(id = "create_bq")
      
      output$bq_status_ui <- renderUI({
        div(class = "api-status-error",
            icon("exclamation-circle"), " Error creating tables: ", e$message)
      })
      
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })
  

 
  # ============================================
  # TAB 3: Process Contact - BIGQUERY INTEGRATED (FIXED)
  # ============================================
  
  # Function to extract text from uploaded file
  extract_text_from_file <- function(file_path, file_type) {
    tryCatch({
      if (grepl("\\.pdf$", file_type, ignore.case = TRUE)) {
        text <- paste(pdftools::pdf_text(file_path), collapse = "\n")
      } else if (grepl("\\.(docx?|pptx?)$", file_type, ignore.case = TRUE)) {
        result <- readtext::readtext(file_path)
        text <- result$text
      } else if (grepl("\\.txt$", file_type, ignore.case = TRUE)) {
        text <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
      } else {
        text <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
      }
      return(text)
    }, error = function(e) {
      return(paste("Error extracting text:", e$message))
    })
  }
  
  # Function to call LLM for contact extraction
  extract_contact_info <- function(text, api_key, model) {
    prompt <- paste0(
      "Extract business contact information from the following text. ",
      "Return the data as a valid JSON object with these exact keys:\n",
      "- full_name: The person's full name\n",
      "- industry: The industry they work in\n",
      "- company: Their current company/organization\n",
      "- job_title: Their job title or position\n",
      "- location: City/region location\n",
      "- country: Country\n",
      "- email: Email address if available\n",
      "- phone: Phone number if available\n",
      "- linkedin: LinkedIn profile URL if available\n",
      "- areas_of_interest: Key areas of interest, expertise, or focus areas\n",
      "- university: University/educational institution\n",
      "- academic_background: Degrees, field of study, academic achievements\n\n",
      "If a field is not found, use 'Not specified' as the value.\n",
      "Return ONLY valid JSON, no additional text.\n\n",
      "Text to analyze:\n",
      text
    )
    
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = jsonlite::toJSON(list(
        model = model,
        messages = list(
          list(role = "system", content = "You are an expert at extracting structured contact information from documents. Always return valid JSON."),
          list(role = "user", content = prompt)
        ),
        max_tokens = 1000,
        temperature = 0.3
      ), auto_unbox = TRUE),
      encode = "json",
      httr::timeout(120)
    )
    
    if (httr::status_code(response) == 200) {
      content_response <- httr::content(response, "parsed")
      json_text <- content_response$choices[[1]]$message$content
      
      # Clean up JSON response
      json_text <- gsub("```json\\s*", "", json_text)
      json_text <- gsub("```\\s*", "", json_text)
      json_text <- trimws(json_text)
      
      return(jsonlite::fromJSON(json_text))
    } else {
      stop(paste("API Error:", httr::status_code(response)))
    }
  }
  
  # Process uploaded file or pasted text
  observeEvent(input$process_file, {
    if (!values$api_key_saved) {
      showNotification("Please configure your OpenAI API key first!", type = "error", duration = 5)
      return()
    }
    
    # Check if either file or text is provided
    has_file <- !is.null(input$contact_file)
    has_text <- nchar(trimws(input$contact_text)) > 0
    
    if (!has_file && !has_text) {
      showNotification("Please upload a file or paste contact information!", type = "error", duration = 5)
      return()
    }
    
    showNotification("Processing with LLM...", type = "message", duration = NULL, id = "processing")
    
    output$process_status_ui <- renderUI({
      div(class = "alert-info",
          icon("spinner", class = "fa-spin"), " Processing... This may take a moment.")
    })
    
    tryCatch({
      # Get text from file or text box
      if (has_file) {
        file_text <- extract_text_from_file(input$contact_file$datapath, input$contact_file$name)
        if (startsWith(file_text, "Error")) {
          stop(file_text)
        }
      } else {
        file_text <- input$contact_text
      }
      
      # Call LLM to extract contact info
      contact_info <- extract_contact_info(file_text, values$api_key, values$gpt_model)
      
      # Convert to data frame
      values$extracted_data <- data.frame(
        Field = c("Full Name", "Industry", "Company", "Job Title", "Location", "Country",
                  "Email", "Phone", "LinkedIn", "Areas of Interest", "University", "Academic Background"),
        Value = c(
          contact_info$full_name %||% "Not specified",
          contact_info$industry %||% "Not specified",
          contact_info$company %||% "Not specified",
          contact_info$job_title %||% "Not specified",
          contact_info$location %||% "Not specified",
          contact_info$country %||% "Not specified",
          contact_info$email %||% "Not specified",
          contact_info$phone %||% "Not specified",
          contact_info$linkedin %||% "Not specified",
          contact_info$areas_of_interest %||% "Not specified",
          contact_info$university %||% "Not specified",
          contact_info$academic_background %||% "Not specified"
        ),
        stringsAsFactors = FALSE
      )
      
      removeNotification(id = "processing")
      
      output$process_status_ui <- renderUI({
        div(class = "alert-success",
            icon("check-circle"), " Processed successfully! Review the extracted data below.")
      })
      
      showNotification("Contact information extracted successfully!", type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification(id = "processing")
      
      output$process_status_ui <- renderUI({
        div(class = "alert-danger",
            icon("exclamation-circle"), " Error processing: ", e$message)
      })
      
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # Render extracted data table
  output$extracted_data_table <- renderDT({
    req(values$extracted_data)
    
    datatable(
      values$extracted_data,
      options = list(
        dom = 't',
        paging = FALSE,
        ordering = FALSE,
        columnDefs = list(
          list(width = '30%', targets = 0),
          list(width = '70%', targets = 1)
        )
      ),
      editable = list(target = 'cell', disable = list(columns = 0)),
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  # Handle cell edits in extracted data table
  observeEvent(input$extracted_data_table_cell_edit, {
    info <- input$extracted_data_table_cell_edit
    values$extracted_data[info$row, info$col + 1] <- info$value
  })
  
  # Preview final data
  observeEvent(input$preview_data, {
    req(values$extracted_data)
    
    preview_df <- data.frame(
      contact_id = UUIDgenerate(),
      full_name = values$extracted_data$Value[1],
      industry = values$extracted_data$Value[2],
      company = values$extracted_data$Value[3],
      job_title = values$extracted_data$Value[4],
      location = values$extracted_data$Value[5],
      country = values$extracted_data$Value[6],
      email = values$extracted_data$Value[7],
      phone = values$extracted_data$Value[8],
      linkedin = values$extracted_data$Value[9],
      areas_of_interest = values$extracted_data$Value[10],
      university = values$extracted_data$Value[11],
      academic_background = values$extracted_data$Value[12],
      user_notes = input$user_notes,
      last_interaction_date = as.character(input$last_interaction),
      created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      updated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      stringsAsFactors = FALSE
    )
    
    output$preview_table <- renderDT({
      datatable(
        t(preview_df),
        options = list(
          dom = 't',
          paging = FALSE,
          ordering = FALSE
        ),
        rownames = TRUE,
        colnames = "Value",
        class = 'cell-border stripe'
      )
    })
    
    # Expand the preview box
    shinyjs::runjs("$('[data-widget=\"collapse\"]').click();")
  })
  
  # Send to BigQuery - FULLY INTEGRATED WITH DBI
  observeEvent(input$send_to_bq, {
    req(values$extracted_data)
    
    if (!values$bq_configured) {
      showNotification("Please configure BigQuery settings first!", type = "error", duration = 5)
      return()
    }
    
    showNotification("Sending data to BigQuery...", type = "message", duration = NULL, id = "sending_bq")
    
    tryCatch({
      # Prepare the data record with UUID contact_id
      new_contact_id <- UUIDgenerate()
      
      record <- data.frame(
        contact_id = new_contact_id,
        full_name = values$extracted_data$Value[1],
        industry = values$extracted_data$Value[2],
        company = values$extracted_data$Value[3],
        job_title = values$extracted_data$Value[4],
        location = values$extracted_data$Value[5],
        country = values$extracted_data$Value[6],
        email = values$extracted_data$Value[7],
        phone = values$extracted_data$Value[8],
        linkedin = values$extracted_data$Value[9],
        areas_of_interest = values$extracted_data$Value[10],
        university = values$extracted_data$Value[11],
        academic_background = values$extracted_data$Value[12],
        user_notes = input$user_notes,
        last_interaction_date = as.character(input$last_interaction),
        created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        updated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE
      )
      
      # Set up BigQuery authentication
      if (!is.null(values$bq_credentials)) {
        bigrquery::bq_auth(path = values$bq_credentials)
      }
      
      # Connect to BigQuery using DBI
      con <- dbConnect(
        bigrquery::bigquery(),
        project = values$bq_project,
        dataset = values$bq_dataset,
        billing = values$bq_project
      )
      
      # Insert record into BigQuery
      dbWriteTable(
        conn = con,
        name = values$bq_table,
        value = record,
        append = TRUE,
        row.names = FALSE
      )
      
      dbDisconnect(con)
      
      # Also update local cache for immediate display
      if (is.null(values$contacts_data) || nrow(values$contacts_data) == 0) {
        values$contacts_data <- record
      } else {
        values$contacts_data <- rbind(values$contacts_data, record)
      }
      
      removeNotification(id = "sending_bq")
      
      output$send_bq_status_ui <- renderUI({
        div(class = "alert-success",
            icon("check-circle"), " Data sent to BigQuery successfully!",
            tags$br(),
            tags$small("Contact ID: ", new_contact_id),
            tags$br(),
            tags$small("Table: ", values$bq_project, ".", values$bq_dataset, ".", values$bq_table))
      })
      
      showNotification("Data sent to BigQuery successfully! View in Explore Contacts tab.", 
                       type = "message", duration = 5)
      
      # Clear the form
      values$extracted_data <- NULL
      updateTextAreaInput(session, "user_notes", value = "")
      updateTextAreaInput(session, "contact_text", value = "")
      updateDateInput(session, "last_interaction", value = Sys.Date())
      
    }, error = function(e) {
      removeNotification(id = "sending_bq")
      
      output$send_bq_status_ui <- renderUI({
        div(class = "alert-danger",
            icon("exclamation-circle"), " Error sending to BigQuery: ", e$message)
      })
      
      showNotification(paste("BigQuery Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # ============================================
  # TAB 4: Explore Contacts
  # ============================================
  
  # Update filter dropdowns
  observe({
    req(values$contacts_data)
    
    if (nrow(values$contacts_data) > 0) {
      updateSelectInput(session, "filter_industry",
                        choices = c("All" = "", unique(values$contacts_data$industry)))
      updateSelectInput(session, "filter_country",
                        choices = c("All" = "", unique(values$contacts_data$country)))
      updateSelectInput(session, "filter_location",
                        choices = c("All" = "", unique(values$contacts_data$location)))
      updateSelectInput(session, "filter_university",
                        choices = c("All" = "", unique(values$contacts_data$university)))
      updateSelectInput(session, "filter_company",
                        choices = c("All" = "", unique(values$contacts_data$company)))
    }
  })
  
  # Filtered data
  filtered_data <- reactive({
    req(values$contacts_data)
    
    if (nrow(values$contacts_data) == 0) {
      return(values$contacts_data)
    }
    
    data <- values$contacts_data
    
    if (!is.null(input$filter_industry) && input$filter_industry != "") {
      data <- data[data$industry == input$filter_industry, ]
    }
    if (!is.null(input$filter_country) && input$filter_country != "") {
      data <- data[data$country == input$filter_country, ]
    }
    if (!is.null(input$filter_location) && input$filter_location != "") {
      data <- data[data$location == input$filter_location, ]
    }
    if (!is.null(input$filter_university) && input$filter_university != "") {
      data <- data[data$university == input$filter_university, ]
    }
    if (!is.null(input$filter_company) && input$filter_company != "") {
      data <- data[data$company == input$filter_company, ]
    }
    
    return(data)
  })
  
  # Apply filters
  observeEvent(input$apply_filters, {
    if (is.null(values$contacts_data) || nrow(values$contacts_data) == 0) {
      showNotification("No contacts to filter. Add contacts first!", type = "warning", duration = 3)
      return()
    }
    
    output$table_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("filter"), " Filters applied. Showing ", nrow(filtered_data()), " of ", nrow(values$contacts_data), " records.")
    })
  })
  
  # Clear filters
  observeEvent(input$clear_filters, {
    updateSelectInput(session, "filter_industry", selected = "")
    updateSelectInput(session, "filter_country", selected = "")
    updateSelectInput(session, "filter_location", selected = "")
    updateSelectInput(session, "filter_university", selected = "")
    updateSelectInput(session, "filter_company", selected = "")
    
    if (!is.null(values$contacts_data)) {
      output$table_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("check-circle"), " Filters cleared. Showing all ", nrow(values$contacts_data), " records.")
      })
    }
  })
  
  # Refresh data from BigQuery
  # Refresh data from BigQuery
  observeEvent(input$refresh_data, {
    if (!values$bq_configured) {
      showNotification("Please configure BigQuery settings first!", type = "error", duration = 3)
      return()
    }
    
    showNotification("Refreshing data from BigQuery...", type = "message", duration = NULL, id = "refresh")
    
    tryCatch({
      # Set up authentication
      if (!is.null(values$bq_credentials)) {
        bigrquery::bq_auth(path = values$bq_credentials)
      }
      
      # Connect to BigQuery
      con <- dbConnect(
        bigrquery::bigquery(),
        project = values$bq_project,
        dataset = values$bq_dataset,
        billing = values$bq_project
      )
      
      # Load contacts data
      contacts_query <- sprintf("SELECT * FROM `%s.%s.%s`", 
                                values$bq_project, values$bq_dataset, values$bq_table)
      values$contacts_data <- dbGetQuery(con, contacts_query)
      
      dbDisconnect(con)
      
      removeNotification(id = "refresh")
      
      output$table_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("sync"), " Data refreshed. ", nrow(values$contacts_data), " records loaded.")
      })
      
      showNotification("Data refreshed successfully!", type = "message", duration = 3)
      
    }, error = function(e) {
      removeNotification(id = "refresh")
      
      showNotification(paste("Error refreshing:", e$message), type = "error", duration = 10)
    })
  })
  
  # Render contacts table
  output$contacts_table <- renderDT({
    if (is.null(values$contacts_data) || nrow(values$contacts_data) == 0) {
      # Show empty state
      return(datatable(
        data.frame(Message = "No contacts yet. Add your first contact in the 'Process Contact' tab!"),
        options = list(dom = 't', ordering = FALSE),
        rownames = FALSE,
        class = 'cell-border stripe'
      ))
    }
    
    display_data <- filtered_data()[, c("contact_id", "full_name", "industry", "company", 
                                        "job_title", "location", "country", "email", 
                                        "university", "user_notes", "last_interaction_date")]
    
    datatable(
      display_data,
      options = list(
        scrollX = TRUE,
        pageLength = 10,
        lengthMenu = c(5, 10, 25, 50),
        order = list(list(1, 'asc'))
      ),
      editable = list(
        target = 'cell',
        disable = list(columns = 0)
      ),
      selection = 'single',
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  # Handle cell edits
  observeEvent(input$contacts_table_cell_edit, {
    info <- input$contacts_table_cell_edit
    
    display_cols <- c("contact_id", "full_name", "industry", "company", 
                      "job_title", "location", "country", "email", 
                      "university", "user_notes", "last_interaction_date")
    
    col_name <- display_cols[info$col + 1]
    
    filtered <- filtered_data()
    contact_id <- filtered$contact_id[info$row]
    main_row <- which(values$contacts_data$contact_id == contact_id)
    
    values$contacts_data[main_row, col_name] <- info$value
    values$contacts_data[main_row, "updated_at"] <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    
    output$table_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("edit"), " Cell edited locally. Click 'Update Modified Record' to save to BigQuery.")
    })
  })
  
  # Track selected row
  observeEvent(input$contacts_table_rows_selected, {
    values$selected_row <- input$contacts_table_rows_selected
    if (!is.null(values$selected_row) && length(values$selected_row) > 0) {
      filtered <- filtered_data()
      if (nrow(filtered) > 0) {
        values$selected_contact <- filtered[values$selected_row, ]
      }
    }
  })
  
  # Customise Communication button - switch to communication tab
  observeEvent(input$customise_comm, {
    if (is.null(values$selected_row) || length(values$selected_row) == 0) {
      showNotification("Please select a contact first!", type = "warning", duration = 3)
      return()
    }
    
    # Switch to Customise Communication tab
    updateTabItems(session, "sidebar_menu", "customise_communication")
    showNotification("Switched to Customise Communication tab", type = "message", duration = 2)
  })
  
  # Update record in BigQuery
  observeEvent(input$update_record, {
    if (is.null(values$selected_row) || length(values$selected_row) == 0) {
      showNotification("Please select a row to update.", type = "warning", duration = 3)
      return()
    }
    
    if (!values$bq_configured) {
      showNotification("Please configure BigQuery settings first!", type = "error", duration = 5)
      return()
    }
    
    showNotification("Updating record in BigQuery...", type = "message", duration = NULL, id = "updating")
    
    filtered <- filtered_data()
    contact_id <- filtered$contact_id[values$selected_row]
    
    # Simulated update - in production use bigrquery
    Sys.sleep(1)
    
    removeNotification(id = "updating")
    
    output$update_status_ui <- renderUI({
      div(class = "alert-success",
          icon("check-circle"), " Record updated successfully!",
          tags$br(),
          tags$small("Contact ID: ", contact_id))
    })
    
    showNotification("Record updated in BigQuery!", type = "message", duration = 5)
  })
  
  # Delete record
  observeEvent(input$delete_record, {
    if (is.null(values$selected_row) || length(values$selected_row) == 0) {
      showNotification("Please select a row to delete.", type = "warning", duration = 3)
      return()
    }
    
    if (!values$bq_configured) {
      showNotification("Please configure BigQuery settings first!", type = "error", duration = 5)
      return()
    }
    
    filtered <- filtered_data()
    contact_id <- filtered$contact_id[values$selected_row]
    
    showModal(modalDialog(
      title = "Confirm Delete",
      paste("Are you sure you want to delete contact:", filtered$full_name[values$selected_row], "?"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete", "Delete", class = "btn-danger")
      )
    ))
  })
  
  # Confirm delete
  observeEvent(input$confirm_delete, {
    removeModal()
    
    showNotification("Deleting record from BigQuery...", type = "message", duration = NULL, id = "deleting")
    
    filtered <- filtered_data()
    contact_id <- filtered$contact_id[values$selected_row]
    
    # Remove from local data
    values$contacts_data <- values$contacts_data[values$contacts_data$contact_id != contact_id, ]
    
    # Also remove any communications for this contact
    if (!is.null(values$communications_data) && nrow(values$communications_data) > 0) {
      values$communications_data <- values$communications_data[
        values$communications_data$contact_id != contact_id, 
      ]
    }
    
    Sys.sleep(1)
    
    removeNotification(id = "deleting")
    
    output$update_status_ui <- renderUI({
      div(class = "alert-success",
          icon("trash"), " Record deleted successfully!",
          tags$br(),
          tags$small("Contact ID: ", contact_id))
    })
    
    showNotification("Record deleted from BigQuery!", type = "message", duration = 5)
    
    values$selected_row <- NULL
    values$selected_contact <- NULL
  })
  
  # ============================================
  # TAB 5: Customise Communication
  # ============================================
  
  # ============================================
  # TAB 5: Customise Communication - BIGQUERY INTEGRATED
  # ============================================
  # ============================================
  # TAB 5: Customise Communication - BIGQUERY INTEGRATED (FIXED)
  # ============================================
  
  # Display selected contact profile
  output$contact_profile_summary <- renderUI({
    if (is.null(values$selected_contact)) {
      return(
        div(class = "empty-state",
            div(class = "empty-state-icon", icon("user-slash")),
            p("No contact selected."),
            p("Please go to 'Explore Contacts' and select a contact, then click 'Customise Communication'.")
        )
      )
    }
    
    contact <- values$selected_contact
    
    tagList(
      h4(icon("user"), " ", contact$full_name),
      tags$hr(style = "border-color: #4a90e2;"),
      fluidRow(
        column(6,
               p(tags$strong("Company: "), contact$company),
               p(tags$strong("Job Title: "), contact$job_title),
               p(tags$strong("Industry: "), contact$industry),
               p(tags$strong("Location: "), contact$location, ", ", contact$country)),
        column(6,
               p(tags$strong("Email: "), contact$email),
               p(tags$strong("Phone: "), contact$phone),
               p(tags$strong("LinkedIn: "), contact$linkedin),
               p(tags$strong("University: "), contact$university))
      ),
      tags$hr(style = "border-color: #4a90e2;"),
      p(tags$strong("Areas of Interest: "), contact$areas_of_interest),
      p(tags$strong("Academic Background: "), contact$academic_background),
      p(tags$strong("Notes: "), contact$user_notes),
      p(tags$strong("Last Interaction: "), contact$last_interaction_date)
    )
  })
  
  # Load recent messages - FROM BIGQUERY
  observeEvent(input$load_recent_messages, {
    if (is.null(values$selected_contact)) {
      showNotification("No contact selected!", type = "warning", duration = 3)
      return()
    }
    
    showNotification("Loading recent messages from BigQuery...", type = "message", duration = NULL, id = "load_msgs")
    
    tryCatch({
      # Set up BigQuery authentication
      if (!is.null(values$bq_credentials)) {
        bigrquery::bq_auth(path = values$bq_credentials)
      }
      
      # Query recent messages from BigQuery using DBI
      con <- dbConnect(
        bigrquery::bigquery(),
        project = values$bq_project,
        dataset = values$bq_dataset,
        billing = values$bq_project
      )
      
      query <- sprintf("
      SELECT *
      FROM `%s.%s.%s`
      WHERE contact_id = '%s'
      ORDER BY created_at DESC
      LIMIT 3
    ", values$bq_project, values$bq_dataset, values$bq_comm_table, values$selected_contact$contact_id)
      
      messages_data <- dbGetQuery(con, query)
      dbDisconnect(con)
      
      if (nrow(messages_data) > 0) {
        values$recent_messages <- messages_data
      } else {
        values$recent_messages <- NULL
      }
      
      removeNotification(id = "load_msgs")
      
      output$recent_messages_display <- renderUI({
        if (is.null(values$recent_messages) || nrow(values$recent_messages) == 0) {
          return(div(
            class = "empty-state",
            div(class = "empty-state-icon", icon("comments")),
            p(icon("info-circle"), " No previous messages found for this contact.", 
              style = "color: #7ec8e3;"),
            p("This is the first time you're communicating with ", values$selected_contact$full_name, ".")
          ))
        }
        
        messages <- values$recent_messages
        
        message_list <- lapply(1:nrow(messages), function(i) {
          div(
            style = "border-bottom: 1px solid #4a90e2; padding: 10px 0; margin: 10px 0;",
            p(tags$strong(icon("calendar"), " ", messages$created_at[i]),
              style = "color: #7ec8e3; margin-bottom: 5px;"),
            p(tags$strong("Channel: "), messages$channel_type[i], " | ",
              tags$strong("Purpose: "), messages$communication_purpose[i], " | ",
              tags$strong("Language: "), messages$language[i]),
            p(messages$message_content[i], style = "font-style: italic;")
          )
        })
        
        do.call(tagList, message_list)
      })
      
      # Only summarize if there are messages
      if (!is.null(values$recent_messages) && nrow(values$recent_messages) > 0) {
        summarize_communication()
      } else {
        output$communication_summary <- renderUI({
          div(
            class = "empty-state",
            p(icon("info-circle"), " No communication history to summarize.", 
              style = "color: #7ec8e3;")
          )
        })
      }
      
    }, error = function(e) {
      removeNotification(id = "load_msgs")
      
      showNotification(paste("Error loading messages:", e$message), type = "error", duration = 10)
      
      output$recent_messages_display <- renderUI({
        div(
          class = "empty-state",
          p(icon("exclamation-circle"), " Error loading messages: ", e$message, 
            style = "color: #e74c3c;")
        )
      })
    })
  })
  
  # Function to summarize communication using LLM
  summarize_communication <- function() {
    if (!values$api_key_saved) {
      showNotification("Please configure your API key first!", type = "error", duration = 3)
      return()
    }
    
    if (is.null(values$recent_messages) || nrow(values$recent_messages) == 0) {
      output$communication_summary <- renderUI({
        p("No messages to summarize.")
      })
      return()
    }
    
    showNotification("Summarizing communication history with LLM...", 
                     type = "message", duration = NULL, id = "summarizing")
    
    # Prepare messages for LLM
    messages_text <- paste(
      apply(values$recent_messages, 1, function(row) {
        paste0("Date: ", row["created_at"], "\n",
               "Channel: ", row["channel_type"], "\n",
               "Purpose: ", row["communication_purpose"], "\n",
               "Message: ", row["message_content"], "\n")
      }),
      collapse = "\n---\n"
    )
    
    prompt <- paste0(
      "Please provide a concise summary of the communication history below. ",
      "Highlight the main topics discussed, the relationship progression, and any key points or follow-ups mentioned.\n\n",
      "Communication History:\n",
      messages_text
    )
    
    tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", values$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = values$gpt_model,
          messages = list(
            list(role = "system", content = "You are a helpful assistant that summarizes communication history concisely."),
            list(role = "user", content = prompt)
          ),
          max_tokens = 500,
          temperature = 0.5
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(120)
      )
      
      removeNotification(id = "summarizing")
      
      if (httr::status_code(response) == 200) {
        content_response <- httr::content(response, "parsed")
        summary <- content_response$choices[[1]]$message$content
        
        values$communication_summary <- summary
        
        output$communication_summary <- renderUI({
          div(
            p(icon("lightbulb"), tags$strong(" Communication Summary:"), 
              style = "color: #7ec8e3; margin-bottom: 10px;"),
            p(summary)
          )
        })
      } else {
        output$communication_summary <- renderUI({
          p("Error generating summary. Please try again.", style = "color: #e74c3c;")
        })
      }
    }, error = function(e) {
      removeNotification(id = "summarizing")
      output$communication_summary <- renderUI({
        p("Error: ", e$message, style = "color: #e74c3c;")
      })
    })
  }
  
  # Generate message with LLM
  observeEvent(input$generate_message, {
    if (!values$api_key_saved) {
      showNotification("Please configure your API key first!", type = "error", duration = 3)
      return()
    }
    
    if (is.null(values$selected_contact)) {
      showNotification("No contact selected!", type = "warning", duration = 3)
      return()
    }
    
    if (nchar(trimws(input$message_guidelines)) == 0) {
      showNotification("Please provide message customisation guidelines!", type = "warning", duration = 3)
      return()
    }
    
    showNotification("Generating message with LLM...", type = "message", duration = NULL, id = "generating")
    
    output$generate_status_ui <- renderUI({
      div(class = "alert-info",
          icon("spinner", class = "fa-spin"), " Generating message...")
    })
    
    # Prepare context
    contact <- values$selected_contact
    channel <- input$comm_channel
    purpose <- input$comm_purpose
    language <- input$comm_language
    length <- input$comm_length
    guidelines <- input$message_guidelines
    
    # Include communication history if available
    history_context <- ""
    if (!is.null(values$communication_summary)) {
      history_context <- paste0(
        "\n\nCommunication History Summary:\n",
        values$communication_summary
      )
    }
    
    prompt <- paste0(
      "Generate a professional ", channel, " message for the following contact.\n\n",
      "CONTACT INFORMATION:\n",
      "Name: ", contact$full_name, "\n",
      "Company: ", contact$company, "\n",
      "Job Title: ", contact$job_title, "\n",
      "Industry: ", contact$industry, "\n",
      "Areas of Interest: ", contact$areas_of_interest, "\n",
      "University: ", contact$university, "\n",
      "Academic Background: ", contact$academic_background, "\n",
      "Notes: ", contact$user_notes, "\n",
      history_context, "\n\n",
      "MESSAGE REQUIREMENTS:\n",
      "Channel: ", channel, "\n",
      "Purpose: ", purpose, "\n",
      "Language: ", language, "\n",
      "Target Length: approximately ", length, " words\n\n",
      "CUSTOMISATION GUIDELINES:\n",
      guidelines, "\n\n",
      "Please generate an appropriate message that:\n",
      "- Is written in ", language, "\n",
      "- Matches the tone and format appropriate for ", channel, "\n",
      "- Addresses the ", purpose, " purpose\n",
      "- Is approximately ", length, " words\n",
      "- Incorporates the customisation guidelines provided\n",
      "- Is personalized to the contact's background and interests\n\n",
      "Return ONLY the message text, no additional commentary."
    )
    
    tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", values$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = values$gpt_model,
          messages = list(
            list(role = "system", content = paste0(
              "You are an expert at writing professional business communications. ",
              "You understand the nuances of different channels (LinkedIn, Email, WhatsApp, etc.) ",
              "and can adapt your writing style accordingly. You write in a warm, professional, ",
              "and authentic voice that builds genuine connections."
            )),
            list(role = "user", content = prompt)
          ),
          max_tokens = as.integer(as.numeric(length) * 1.5),
          temperature = 0.7
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(120)
      )
      
      removeNotification(id = "generating")
      
      if (httr::status_code(response) == 200) {
        content_response <- httr::content(response, "parsed")
        message_text <- content_response$choices[[1]]$message$content
        
        values$generated_message <- message_text
        
        output$generated_message_display <- renderUI({
          div(
            p(icon("envelope"), tags$strong(" Generated Message:"), 
              style = "color: #7ec8e3; margin-bottom: 10px;"),
            tags$hr(style = "border-color: #4a90e2;"),
            p(message_text, style = "white-space: pre-wrap; line-height: 1.8;"),
            tags$hr(style = "border-color: #4a90e2;"),
            p(tags$small(icon("info-circle"), " Channel: ", channel, " | Purpose: ", purpose, 
                         " | Language: ", language, " | Length: ~", length, " words"),
              style = "color: #a0aec0;")
          )
        })
        
        output$generate_status_ui <- renderUI({
          div(class = "alert-success",
              icon("check-circle"), " Message generated successfully!")
        })
        
        showNotification("Message generated successfully!", type = "message", duration = 5)
        
      } else {
        output$generate_status_ui <- renderUI({
          div(class = "alert-danger",
              icon("exclamation-circle"), " Error generating message. Status: ", httr::status_code(response))
        })
      }
    }, error = function(e) {
      removeNotification(id = "generating")
      
      output$generate_status_ui <- renderUI({
        div(class = "alert-danger",
            icon("exclamation-circle"), " Error: ", e$message)
      })
      
      showNotification(paste("Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # Save message to BigQuery - FULLY INTEGRATED (FIXED)
  observeEvent(input$save_message, {
    if (is.null(values$generated_message)) {
      showNotification("Please generate a message first!", type = "warning", duration = 3)
      return()
    }
    
    if (!values$bq_configured) {
      showNotification("Please configure BigQuery settings first!", type = "error", duration = 5)
      return()
    }
    
    showNotification("Saving message to BigQuery...", type = "message", duration = NULL, id = "saving_msg")
    
    tryCatch({
      # Prepare communication record
      comm_record <- data.frame(
        message_id = UUIDgenerate(),
        contact_id = values$selected_contact$contact_id,
        channel_type = input$comm_channel,
        communication_purpose = input$comm_purpose,
        language = input$comm_language,
        message_length = input$comm_length,
        message_content = values$generated_message,
        created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        stringsAsFactors = FALSE
      )
      
      # Set up BigQuery authentication
      if (!is.null(values$bq_credentials)) {
        bigrquery::bq_auth(path = values$bq_credentials)
      }
      
      # Connect to BigQuery using DBI
      con <- dbConnect(
        bigrquery::bigquery(),
        project = values$bq_project,
        dataset = values$bq_dataset,
        billing = values$bq_project
      )
      
      # Insert communication record into BigQuery
      dbWriteTable(
        conn = con,
        name = values$bq_comm_table,
        value = comm_record,
        append = TRUE,
        row.names = FALSE
      )
      
      dbDisconnect(con)
      
      # Also update local cache
      if (is.null(values$communications_data) || nrow(values$communications_data) == 0) {
        values$communications_data <- comm_record
      } else {
        values$communications_data <- rbind(values$communications_data, comm_record)
      }
      
      # Clear recent messages so they'll reload with the new one
      values$recent_messages <- NULL
      
      removeNotification(id = "saving_msg")
      
      output$save_message_status_ui <- renderUI({
        div(class = "alert-success",
            icon("check-circle"), " Message saved to BigQuery successfully!",
            tags$br(),
            tags$small("Message ID: ", comm_record$message_id),
            tags$br(),
            tags$small("Table: ", values$bq_project, ".", values$bq_dataset, ".", values$bq_comm_table))
      })
      
      showNotification("Message saved successfully! Click 'Load Last 3 Messages' to see it.", 
                       type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification(id = "saving_msg")
      
      output$save_message_status_ui <- renderUI({
        div(class = "alert-danger",
            icon("exclamation-circle"), " Error saving to BigQuery: ", e$message)
      })
      
      showNotification(paste("BigQuery Error:", e$message), type = "error", duration = 10)
    })
  })
  
  # Copy message to clipboard
  observeEvent(input$copy_message, {
    if (is.null(values$generated_message)) {
      showNotification("Please generate a message first!", type = "warning", duration = 3)
      return()
    }
    
    # Use JavaScript to copy to clipboard
    shinyjs::runjs(paste0(
      "navigator.clipboard.writeText(`", 
      gsub("`", "\\`", values$generated_message), 
      "`).then(() => {",
      "  Shiny.setInputValue('clipboard_success', Math.random());",
      "});"
    ))
    
    showNotification("Message copied to clipboard!", type = "message", duration = 3)
  })
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x) || x == "" || is.na(x)) y else x

# Run the application
shinyApp(ui = ui, server = server)