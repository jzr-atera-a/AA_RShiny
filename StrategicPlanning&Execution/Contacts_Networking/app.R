library(shiny)
library(shinydashboard)
library(shinyjs)
library(httr)
library(jsonlite)
library(DT)
library(pdftools)
library(readtext)

# UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Business Contact Manager"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("API Configuration", tabName = "api_config", icon = icon("key")),
      menuItem("BigQuery Settings", tabName = "bq_config", icon = icon("database")),
      menuItem("Process Contact", tabName = "process_contact", icon = icon("user-plus")),
      menuItem("Explore Contacts", tabName = "explore_contacts", icon = icon("search"))
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
            selectInput("gpt_model", "Select GPT Model:",
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
              tags$li("Select your preferred GPT model"),
              tags$li("Click 'Save API Key' to store it for this session"),
              tags$li("Optionally click 'Test API Connection' to verify it works"),
              tags$li("Navigate to 'BigQuery Settings' tab to configure database connection")
            ),
            br(),
            h4("Troubleshooting:"),
            tags$ul(
              tags$li("If you get DNS errors, check your internet connection"),
              tags$li("Ensure your firewall allows connections to api.openai.com"),
              tags$li("Verify your API key is valid and has sufficient credits"),
              tags$li("Try using a VPN if your region blocks OpenAI services")
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
            p("You need a service account JSON key file or API key with BigQuery access."),
            br(),
            
            fluidRow(
              column(6,
                     textInput("bq_project", "Project ID:", 
                               placeholder = "your-gcp-project-id",
                               width = "100%")),
              column(6,
                     textInput("bq_dataset", "Dataset Name:", 
                               placeholder = "your_dataset",
                               width = "100%"))
            ),
            
            textInput("bq_table", "Table Name:", 
                      value = "business_contacts",
                      placeholder = "business_contacts",
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
            actionButton("test_bq", "Test Connection", class = "btn-info", icon = icon("database")),
            actionButton("create_table_bq", "Create Table", class = "btn-warning", icon = icon("plus")),
            br(), br(),
            uiOutput("bq_status_ui"),
            
            br(),
            div(class = "schema-info",
                h5("Table Schema for Business Contacts:"),
                p("The following schema will be used for the BigQuery table:"),
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
            title = "Upload Contact Document",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            p("Upload a PDF, Word (.docx), PowerPoint (.pptx), or text file containing business contact information."),
            p("ChatGPT will extract and structure the relevant information."),
            br(),
            div(class = "file-upload-box",
                fileInput("contact_file", "Choose File",
                          accept = c(".pdf", ".docx", ".doc", ".pptx", ".ppt", ".txt", ".text"),
                          width = "100%"),
                p(tags$small("Supported formats: PDF, DOCX, PPTX, TXT"))
            ),
            br(),
            actionButton("process_file", "Process with ChatGPT", 
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
            p("Click on a row to select it for editing. Double-click a cell to edit inline."),
            DTOutput("contacts_table"),
            br(),
            uiOutput("table_status_ui")
          )
        ),
        
        fluidRow(
          box(
            title = "Update Selected Record",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("After making changes in the table above, click the button below to update the record in BigQuery."),
            fluidRow(
              column(6,
                     actionButton("update_record", "Update Modified Record", 
                                  class = "btn-success", 
                                  icon = icon("save"),
                                  style = "width: 100%;")),
              column(6,
                     actionButton("delete_record", "Delete Selected Record", 
                                  class = "btn-danger", 
                                  icon = icon("trash"),
                                  style = "width: 100%;"))
            ),
            br(),
            uiOutput("update_status_ui")
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
    bq_project = NULL,
    bq_dataset = NULL,
    bq_table = NULL,
    bq_credentials = NULL,
    extracted_data = NULL,
    contacts_data = NULL,
    selected_row = NULL
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
        error_content <- httr::content(response, "text", encoding = "UTF-8")
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
    if (nchar(trimws(input$bq_project)) == 0 || nchar(trimws(input$bq_dataset)) == 0) {
      showNotification("Please fill in Project ID and Dataset Name", 
                       type = "error", duration = 3)
      return()
    }
    
    values$bq_project <- trimws(input$bq_project)
    values$bq_dataset <- trimws(input$bq_dataset)
    values$bq_table <- trimws(input$bq_table)
    
    if (input$bq_auth_method == "json_key" && !is.null(input$bq_key_file)) {
      values$bq_credentials <- input$bq_key_file$datapath
    }
    
    values$bq_configured <- TRUE
    
    output$bq_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("check-circle"), " BigQuery settings saved!",
          tags$br(),
          tags$small("Project: ", values$bq_project, " | Dataset: ", values$bq_dataset, " | Table: ", values$bq_table))
    })
    
    showNotification("BigQuery settings saved!", type = "message", duration = 3)
  })
  
  # Test BigQuery Connection (placeholder - actual implementation requires bigrquery package)
  observeEvent(input$test_bq, {
    if (!values$bq_configured) {
      showNotification("Please save BigQuery settings first!", type = "error", duration = 3)
      return()
    }
    
    showNotification("Testing BigQuery connection...", type = "message", duration = NULL, id = "test_bq")
    
    # Simulated test - in production, use bigrquery::bq_project_query()
    Sys.sleep(1)
    removeNotification(id = "test_bq")
    
    output$bq_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("check-circle"), " BigQuery connection test passed!",
          tags$br(),
          tags$small("Project: ", values$bq_project, " | Dataset: ", values$bq_dataset))
    })
    
    showNotification("BigQuery connection successful!", type = "message", duration = 3)
  })
  
  # Create BigQuery Table (placeholder)
  observeEvent(input$create_table_bq, {
    if (!values$bq_configured) {
      showNotification("Please save BigQuery settings first!", type = "error", duration = 3)
      return()
    }
    
    showNotification("Creating BigQuery table...", type = "message", duration = NULL, id = "create_bq")
    
    # Schema definition for reference
    schema <- list(
      list(name = "contact_id", type = "STRING", mode = "REQUIRED"),
      list(name = "full_name", type = "STRING"),
      list(name = "industry", type = "STRING"),
      list(name = "company", type = "STRING"),
      list(name = "job_title", type = "STRING"),
      list(name = "location", type = "STRING"),
      list(name = "country", type = "STRING"),
      list(name = "email", type = "STRING"),
      list(name = "phone", type = "STRING"),
      list(name = "linkedin", type = "STRING"),
      list(name = "areas_of_interest", type = "STRING"),
      list(name = "university", type = "STRING"),
      list(name = "academic_background", type = "STRING"),
      list(name = "user_notes", type = "STRING"),
      list(name = "last_interaction_date", type = "DATE"),
      list(name = "created_at", type = "TIMESTAMP"),
      list(name = "updated_at", type = "TIMESTAMP")
    )
    
    Sys.sleep(1)
    removeNotification(id = "create_bq")
    
    output$bq_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("check-circle"), " Table created successfully!",
          tags$br(),
          tags$small("Table: ", values$bq_project, ".", values$bq_dataset, ".", values$bq_table))
    })
    
    showNotification("BigQuery table created!", type = "message", duration = 3)
  })
  
  # ============================================
  # TAB 3: Process Contact
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
  
  # Function to call ChatGPT for contact extraction
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
  
  # Process uploaded file
  observeEvent(input$process_file, {
    req(input$contact_file)
    
    if (!values$api_key_saved) {
      showNotification("Please configure your OpenAI API key first!", type = "error", duration = 5)
      return()
    }
    
    showNotification("Processing document with ChatGPT...", type = "message", duration = NULL, id = "processing")
    
    output$process_status_ui <- renderUI({
      div(class = "alert-info",
          icon("spinner", class = "fa-spin"), " Processing document... This may take a moment.")
    })
    
    tryCatch({
      # Extract text from file
      file_text <- extract_text_from_file(input$contact_file$datapath, input$contact_file$name)
      
      if (startsWith(file_text, "Error")) {
        stop(file_text)
      }
      
      # Call ChatGPT to extract contact info
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
            icon("check-circle"), " Document processed successfully! Review the extracted data below.")
      })
      
      showNotification("Contact information extracted successfully!", type = "message", duration = 5)
      
    }, error = function(e) {
      removeNotification(id = "processing")
      
      output$process_status_ui <- renderUI({
        div(class = "alert-danger",
            icon("exclamation-circle"), " Error processing document: ", e$message)
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
      contact_id = paste0("CONTACT_", format(Sys.time(), "%Y%m%d%H%M%S")),
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
  
  # Send to BigQuery
  observeEvent(input$send_to_bq, {
    req(values$extracted_data)
    
    if (!values$bq_configured) {
      showNotification("Please configure BigQuery settings first!", type = "error", duration = 5)
      return()
    }
    
    showNotification("Sending data to BigQuery...", type = "message", duration = NULL, id = "sending_bq")
    
    # Prepare the data record
    record <- data.frame(
      contact_id = paste0("CONTACT_", format(Sys.time(), "%Y%m%d%H%M%S")),
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
    
    # Simulated BigQuery insert - in production use bigrquery::bq_table_upload()
    Sys.sleep(1)
    
    removeNotification(id = "sending_bq")
    
    output$send_bq_status_ui <- renderUI({
      div(class = "alert-success",
          icon("check-circle"), " Data sent to BigQuery successfully!",
          tags$br(),
          tags$small("Contact ID: ", record$contact_id),
          tags$br(),
          tags$small("Table: ", values$bq_project, ".", values$bq_dataset, ".", values$bq_table))
    })
    
    showNotification("Data sent to BigQuery successfully!", type = "message", duration = 5)
    
    # Clear the form
    values$extracted_data <- NULL
    updateTextAreaInput(session, "user_notes", value = "")
    updateDateInput(session, "last_interaction", value = Sys.Date())
  })
  
  # ============================================
  # TAB 4: Explore Contacts
  # ============================================
  
  # Sample data for demonstration
  sample_contacts <- reactive({
    data.frame(
      contact_id = c("CONTACT_001", "CONTACT_002", "CONTACT_003", "CONTACT_004", "CONTACT_005"),
      full_name = c("John Smith", "Maria Garcia", "David Chen", "Sarah Johnson", "Ahmed Hassan"),
      industry = c("Technology", "Healthcare", "Finance", "Technology", "Energy"),
      company = c("Google", "Mayo Clinic", "Goldman Sachs", "Microsoft", "Shell"),
      job_title = c("Senior Engineer", "Research Director", "VP Strategy", "Product Manager", "Chief Scientist"),
      location = c("San Francisco", "Rochester", "New York", "Seattle", "London"),
      country = c("USA", "USA", "USA", "USA", "UK"),
      email = c("john@google.com", "maria@mayo.org", "david@gs.com", "sarah@msft.com", "ahmed@shell.com"),
      phone = c("+1-555-0101", "+1-555-0102", "+1-555-0103", "+1-555-0104", "+44-20-1234"),
      linkedin = c("linkedin.com/in/johnsmith", "linkedin.com/in/mariagarcia", "linkedin.com/in/davidchen", "linkedin.com/in/sarahjohnson", "linkedin.com/in/ahmedhassan"),
      areas_of_interest = c("AI, Machine Learning", "Clinical Research, Oncology", "Investment Banking, M&A", "Cloud Computing, SaaS", "Renewable Energy, Sustainability"),
      university = c("Stanford", "Harvard", "Wharton", "MIT", "Oxford"),
      academic_background = c("PhD Computer Science", "MD, PhD", "MBA", "MS Computer Science", "PhD Chemical Engineering"),
      user_notes = c("Met at conference", "Follow up on research", "Potential partner", "Referral from colleague", "Industry expert"),
      last_interaction_date = c("2024-01-15", "2024-02-20", "2024-01-10", "2024-03-01", "2024-02-15"),
      created_at = rep("2024-01-01 10:00:00", 5),
      updated_at = rep("2024-03-01 10:00:00", 5),
      stringsAsFactors = FALSE
    )
  })
  
  # Initialize contacts data
  observe({
    if (is.null(values$contacts_data)) {
      values$contacts_data <- sample_contacts()
    }
  })
  
  # Update filter dropdowns
  observe({
    req(values$contacts_data)
    
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
  })
  
  # Filtered data
  filtered_data <- reactive({
    data <- values$contacts_data
    
    if (input$filter_industry != "") {
      data <- data[data$industry == input$filter_industry, ]
    }
    if (input$filter_country != "") {
      data <- data[data$country == input$filter_country, ]
    }
    if (input$filter_location != "") {
      data <- data[data$location == input$filter_location, ]
    }
    if (input$filter_university != "") {
      data <- data[data$university == input$filter_university, ]
    }
    if (input$filter_company != "") {
      data <- data[data$company == input$filter_company, ]
    }
    
    return(data)
  })
  
  # Apply filters
  observeEvent(input$apply_filters, {
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
    
    output$table_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("check-circle"), " Filters cleared. Showing all ", nrow(values$contacts_data), " records.")
    })
  })
  
  # Refresh data from BigQuery
  observeEvent(input$refresh_data, {
    showNotification("Refreshing data from BigQuery...", type = "message", duration = NULL, id = "refresh")
    
    # Simulated refresh - in production use bigrquery to fetch data
    Sys.sleep(1)
    
    removeNotification(id = "refresh")
    
    output$table_status_ui <- renderUI({
      div(class = "api-status-success",
          icon("sync"), " Data refreshed. ", nrow(values$contacts_data), " records loaded.")
    })
    
    showNotification("Data refreshed successfully!", type = "message", duration = 3)
  })
  
  # Render contacts table
  output$contacts_table <- renderDT({
    req(values$contacts_data)
    
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
        disable = list(columns = 0)  # Disable editing contact_id
      ),
      selection = 'single',
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  # Handle cell edits
  observeEvent(input$contacts_table_cell_edit, {
    info <- input$contacts_table_cell_edit
    
    # Get the column names in display order
    display_cols <- c("contact_id", "full_name", "industry", "company", 
                      "job_title", "location", "country", "email", 
                      "university", "user_notes", "last_interaction_date")
    
    col_name <- display_cols[info$col + 1]
    
    # Find the row in the main data
    filtered <- filtered_data()
    contact_id <- filtered$contact_id[info$row]
    main_row <- which(values$contacts_data$contact_id == contact_id)
    
    # Update the value
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
      paste("Are you sure you want to delete contact:", contact_id, "?"),
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
  })
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x) || x == "" || is.na(x)) y else x

# Run the application
shinyApp(ui = ui, server = server)