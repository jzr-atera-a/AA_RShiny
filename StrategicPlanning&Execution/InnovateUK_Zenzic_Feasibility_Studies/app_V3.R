library(shiny)
library(shinydashboard)
library(shinyjs)
library(httr)
library(jsonlite)
library(openxlsx)

# UI
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(title = "Project Application Assistant"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("API Configuration", tabName = "api_config", icon = icon("key")),
      menuItem("Project Details", tabName = "project_details", icon = icon("file-text")),
      menuItem("Business Case", tabName = "business_case", icon = icon("briefcase")),
      menuItem("Team & Impact", tabName = "team_impact", icon = icon("users"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    
    tags$head(
      tags$style(HTML("
        /* Paleta de colores */
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
        
        .question-label {
          font-weight: bold;
          color: #ffffff !important;
          margin-bottom: 10px;
          font-size: 16px;
        }
        
        .question-help {
          color: #c7d2fe !important;
          font-size: 13px;
          margin-bottom: 15px;
          font-style: italic;
        }
        
        .word-counter {
          color: #7ec8e3 !important;
          font-size: 12px;
          margin-top: 5px;
          font-weight: bold;
        }
        
        .main-ideas-input {
          margin-bottom: 10px;
        }
        
        .generate-container {
          display: flex;
          align-items: center;
          margin-bottom: 10px;
        }
        
        .generate-btn {
          background: linear-gradient(135deg, #00a65a 0%, #008d4c 100%) !important;
          color: white !important;
          border: none !important;
          padding: 8px 15px;
          border-radius: 8px;
          cursor: pointer;
          margin-left: 10px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(0, 166, 90, 0.3);
        }
        
        .generate-btn:hover {
          background: linear-gradient(135deg, #008d4c 0%, #00a65a 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(0, 166, 90, 0.4);
        }
        
        .save-btn {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important;
          color: white !important;
          border: none !important;
          padding: 12px 25px;
          border-radius: 8px;
          cursor: pointer;
          font-size: 16px;
          margin-top: 20px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(46, 204, 113, 0.3);
        }
        
        .save-btn:hover {
          background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(46, 204, 113, 0.4);
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
        
        .save-status-success {
          color: #2ecc71 !important;
          font-weight: bold;
          font-size: 14px;
        }
        
        .save-status-error {
          color: #e74c3c !important;
          font-weight: bold;
          font-size: 14px;
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
      "))
    ),
    
    tabItems(
      # API Configuration Tab
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
                     target = "_blank", "https://platform.openai.com/api-keys")),
            br(),
            passwordInput("api_key", "OpenAI API Key:", 
                          placeholder = "sk-...",
                          width = "100%"),
            actionButton("save_api", "Save API Key", class = "btn-success", icon = icon("save")),
            actionButton("test_api", "Test API Connection", class = "btn-info", icon = icon("plug")),
            br(), br(),
            uiOutput("api_status_ui"),
            br(),
            h4("Instructions:"),
            tags$ol(
              tags$li("Paste your OpenAI API key in the field above"),
              tags$li("Click 'Save API Key' to store it for this session"),
              tags$li("Optionally click 'Test API Connection' to verify it works"),
              tags$li("Navigate to 'Project Details' tab to start creating your application")
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
      
      # Project Details Tab
      tabItem(
        tabName = "project_details",
        fluidRow(
          box(
            title = "Word Limits Configuration",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            p("Set the word limit for each section. The AI will generate content according to these limits."),
            column(4, 
                   numericInput("word_limit_1", 
                                "Project Summary Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(4, 
                   numericInput("word_limit_2", 
                                "Public Description Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(4, 
                   numericInput("word_limit_3", 
                                "Scope Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50))
          )
        ),
        
        fluidRow(
          box(
            title = "1. Project Summary",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Project Summary"
            ),
            div(class = "question-help",
                "What should I include in the project summary? Describe your project briefly and be clear about what makes it innovative. We use this section to assign the right experts to assess your application."
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_1", 
                              "Main Ideas / Key Points for Project Summary:", 
                              placeholder = "Enter the key points, main concepts, and innovative aspects you want to include in your project summary...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_1", 
                             "Generate with ChatGPT", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("project_summary", 
                          "Generated Project Summary:", 
                          placeholder = "Your AI-generated project summary will appear here after clicking the Generate button...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_1"))
          )
        ),
        
        fluidRow(
          box(
            title = "2. Public Description",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Public Description"
            ),
            div(class = "question-help",
                "What should I include in the project public description? Describe your project in detail and in a way that you are happy to see published. Do not include any commercially sensitive information. If we award your project funding, we will publish this description. This can happen before you start your project."
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_2", 
                              "Main Ideas / Key Points for Public Description:", 
                              placeholder = "Enter the detailed information you want to include in your public description. Remember: this will be published publicly...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_2", 
                             "Generate with ChatGPT", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("public_description", 
                          "Generated Public Description:", 
                          placeholder = "Your AI-generated public description will appear here after clicking the Generate button...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_2"))
          )
        ),
        
        fluidRow(
          box(
            title = "3. Scope",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Scope"
            ),
            div(class = "question-help",
                "What should I include in the project scope? Describe how your project fits the scope of the competition. If your project is not in scope, it will not be sent for assessment. We will tell you the reason why."
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_3", 
                              "Main Ideas / Key Points for Scope:", 
                              placeholder = "Enter how your project aligns with the competition scope, eligibility criteria, and requirements...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_3", 
                             "Generate with ChatGPT", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("scope", 
                          "Generated Scope Description:", 
                          placeholder = "Your AI-generated scope description will appear here after clicking the Generate button...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_3"))
          )
        ),
        
        fluidRow(
          box(
            title = "Save to Excel",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("Save your application data to an Excel file. You can create a new file or append to an existing one."),
            fluidRow(
              column(6,
                     textInput("version_name", 
                               "Version Name:", 
                               value = "AVs+AIAgentsV1", 
                               placeholder = "e.g., AVs+AIAgentsV1")),
              column(6,
                     textInput("sheet_name", 
                               "Sheet Name:", 
                               value = "Project_V1", 
                               placeholder = "Name for the Excel sheet"))
            ),
            fluidRow(
              column(12,
                     textInput("file_path", 
                               "Excel File Path:", 
                               value = "project_application.xlsx",
                               placeholder = "e.g., /path/to/your/file.xlsx or C:/Users/YourName/Documents/project.xlsx"))
            ),
            p(tags$small("Tip: Use absolute paths. On Windows: C:/Users/YourName/Documents/file.xlsx. On Mac/Linux: /home/username/file.xlsx")),
            br(),
            actionButton("save_excel", 
                         "Save to Excel", 
                         class = "save-btn", 
                         icon = icon("file-excel")),
            br(), br(),
            uiOutput("save_status_ui")
          )
        )
      ),
      
      # Business Case Tab
      tabItem(
        tabName = "business_case",
        fluidRow(
          box(
            title = "Word Limits Configuration - Business Case",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            p("Set the word limit for each business case section."),
            column(3, 
                   numericInput("word_limit_bc1", 
                                "Problem & Market Word Limit:", 
                                value = 500, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(3, 
                   numericInput("word_limit_bc2", 
                                "CAM Service Word Limit:", 
                                value = 500, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(3, 
                   numericInput("word_limit_bc3", 
                                "Readiness Word Limit:", 
                                value = 500, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(3, 
                   numericInput("word_limit_bc4", 
                                "Feasibility Word Limit:", 
                                value = 500, 
                                min = 50, 
                                max = 2000,
                                step = 50))
          )
        ),
        
        fluidRow(
          box(
            title = "Additional Word Limit",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            column(4, 
                   numericInput("word_limit_bc5", 
                                "Commercialisation Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50))
          )
        ),
        
        fluidRow(
          box(
            title = "9. Problem, Opportunity and Market Potential",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Problem, Opportunity and Market Potential"
            ),
            div(class = "question-help",
                "What mobility challenge or gap are you addressing, and what is the size and timing of the opportunity which this business case can unlock?"
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_bc1", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter the key points about the problem, opportunity, and market potential...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_bc1", 
                             "Generate with ChatGPT (with context)", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("problem_opportunity", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_bc1"))
          )
        ),
        
        fluidRow(
          box(
            title = "10. Proposed CAM Service, Value Proposition and Location Context",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Proposed CAM Service, Value Proposition and Location Context"
            ),
            div(class = "question-help",
                "What CAM service or solution are you proposing, and why is this the right service in the right location?"
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_bc2", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter the key points about your CAM service, value proposition, and location...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_bc2", 
                             "Generate with ChatGPT (with context)", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("cam_service", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_bc2"))
          )
        ),
        
        fluidRow(
          box(
            title = "11. Readiness, Stakeholders and Regulatory Compliance",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Readiness, Stakeholders and Regulatory Compliance"
            ),
            div(class = "question-help",
                "How ready is your current business case? Identify areas where you have complete knowledge and what gaps your feasibility study will address to get to an investment ready decision point?"
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_bc3", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter the key points about readiness, stakeholders, and regulatory compliance...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_bc3", 
                             "Generate with ChatGPT (with context)", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("readiness", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_bc3"))
          )
        ),
        
        fluidRow(
          box(
            title = "12. Feasibility Study Plan, Business Case Development and Gateway",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Feasibility Study Plan, Business Case Development and Gateway"
            ),
            div(class = "question-help",
                "What will your feasibility study deliver, and how will you know if it is successful?"
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_bc4", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter the key points about your feasibility study plan...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_bc4", 
                             "Generate with ChatGPT (with context)", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("feasibility", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_bc4"))
          )
        ),
        
        fluidRow(
          box(
            title = "13. Commercialisation Roadmap and Key Performance Indicators (KPIs)",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Commercialisation Roadmap and Key Performance Indicators (KPIs)"
            ),
            div(class = "question-help",
                "What happens after the feasibility study, and how will you measure progress?"
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_bc5", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter the key points about your commercialisation roadmap and KPIs...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_bc5", 
                             "Generate with ChatGPT (with context)", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("commercialisation", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_bc5"))
          )
        ),
        
        fluidRow(
          box(
            title = "Save Business Case to Excel",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("This will save the business case data to the same Excel file configured in the Project Details tab."),
            p(tags$strong("Note: "), "Make sure you have configured the file path in the Project Details tab first."),
            br(),
            actionButton("save_business_case", 
                         "Save Business Case to Excel", 
                         class = "save-btn", 
                         icon = icon("file-excel")),
            br(), br(),
            uiOutput("save_bc_status_ui")
          )
        )
      ),
      
      # NEW Team & Impact Tab
      tabItem(
        tabName = "team_impact",
        fluidRow(
          box(
            title = "Word Limits Configuration - Team & Impact",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            p("Set the word limit for each Team & Impact section."),
            column(4, 
                   numericInput("word_limit_ti1", 
                                "Team & Capability Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(4, 
                   numericInput("word_limit_ti2", 
                                "Finance & Risks Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50)),
            column(4, 
                   numericInput("word_limit_ti3", 
                                "Impact Word Limit:", 
                                value = 500, 
                                min = 50, 
                                max = 2000,
                                step = 50))
          )
        ),
        
        fluidRow(
          box(
            title = "Additional Word Limit",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            column(4, 
                   numericInput("word_limit_ti4", 
                                "Costs & Value Word Limit:", 
                                value = 400, 
                                min = 50, 
                                max = 2000,
                                step = 50))
          )
        ),
        
        fluidRow(
          box(
            title = "14. Team and Capability",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Team and Capability"
            ),
            div(class = "question-help",
                "Who is in your team and how will you fill any gaps? Describe:",
                tags$ul(
                  tags$li("The level of senior buy-in for the project and your authority to proceed"),
                  tags$li("The skills and experience of your team relevant to this project"),
                  tags$li("How you will address any capability gaps during or after the study"),
                  tags$li("Evidence why the team has the resource capacity to undertake this study")
                )
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_ti1", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter the key points about your team, capabilities, senior buy-in, and resource capacity...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_ti1", 
                             "Generate with Full Context", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("team_capability", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_ti1"))
          )
        ),
        
        fluidRow(
          box(
            title = "15. Finance and Risk Management",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Finance and Risk Management"
            ),
            div(class = "question-help",
                "How will you manage finances and risks during the study? Explain:",
                tags$ul(
                  tags$li("How you will ensure financial resilience within your organisation or consortia"),
                  tags$li("Key risks to delivering an investment-ready business case"),
                  tags$li("How you will manage and mitigate risks (technical, commercial, legal, environmental)")
                ),
                tags$strong("Note: "), "You must submit a risk register as an appendix (PDF, max 10MB, up to 2 A4 pages)."
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_ti2", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter key points about financial management, cashflow, major spend items, and risk mitigation strategies...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_ti2", 
                             "Generate with Full Context", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("finance_risk", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_ti2"))
          )
        ),
        
        fluidRow(
          box(
            title = "16. Impact on UK Economy and Society",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Impact on UK Economy and Society"
            ),
            div(class = "question-help",
                "What impact will your proposal have on the UK economy and society? Explain and quantify:",
                tags$ul(
                  tags$li("Potential for UK jobs (direct and indirect operational roles)"),
                  tags$li("Anchoring innovation centres of excellence or manufacturing"),
                  tags$li("Wider benefits such as CO₂ reduction and economic growth"),
                  tags$li("UK capability building opportunities and any overseas aspects")
                ),
                tags$strong("Note: "), "You can submit one appendix (PDF, max 10MB, up to 2 A4 pages)."
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_ti3", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter key points about UK jobs, economic impact, CO₂ reduction, and capability building...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_ti3", 
                             "Generate with Full Context", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("impact", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_ti3"))
          )
        ),
        
        fluidRow(
          box(
            title = "17. Costs and Value for Money",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "question-label",
                "Costs and Value for Money"
            ),
            div(class = "question-help",
                "How do your costs represent value for money? Justify and explain:",
                tags$ul(
                  tags$li("The overall costs of your feasibility study including subcontractor costs and overseas spend"),
                  tags$li("Why you need the funding"),
                  tags$li("What would happen to this project in the absence of funding")
                )
            ),
            div(class = "main-ideas-input",
                textAreaInput("main_ideas_ti4", 
                              "Main Ideas / Key Points:", 
                              placeholder = "Enter key points about costs, budget breakdown, value for money justification, and funding necessity...",
                              height = "120px", 
                              width = "100%")
            ),
            div(class = "generate-container",
                actionButton("generate_ti4", 
                             "Generate with Full Context", 
                             class = "generate-btn",
                             icon = icon("wand-magic-sparkles"))
            ),
            textAreaInput("costs_value", 
                          "Generated Response:", 
                          placeholder = "Your AI-generated response will appear here...",
                          height = "250px", 
                          width = "100%"),
            div(class = "word-counter", 
                textOutput("word_count_ti4"))
          )
        ),
        
        fluidRow(
          box(
            title = "Save Team & Impact to Excel",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            p("This will save the Team & Impact data to the same Excel file configured in the Project Details tab."),
            p(tags$strong("Note: "), "Make sure you have configured the file path in the Project Details tab first."),
            br(),
            actionButton("save_team_impact", 
                         "Save Team & Impact to Excel", 
                         class = "save-btn", 
                         icon = icon("file-excel")),
            br(), br(),
            uiOutput("save_ti_status_ui")
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values to store API key and cumulative conversation context
  values <- reactiveValues(
    api_key = NULL,
    api_key_saved = FALSE,
    conversation_history = list()  # Store full conversation for context continuity
  )
  
  # Save API Key
  observeEvent(input$save_api, {
    if (nchar(trimws(input$api_key)) > 0) {
      values$api_key <- trimws(input$api_key)
      values$api_key_saved <- TRUE
      
      output$api_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("check-circle"), " API Key saved successfully! You can now use all tabs.")
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
    
    test_result <- tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", values$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = "gpt-3.5-turbo",
          messages = list(
            list(
              role = "user",
              content = "Say 'API test successful' if you receive this message."
            )
          ),
          max_tokens = 50
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(60),
        httr::config(ssl_verifypeer = TRUE)
      )
      
      removeNotification(id = "test_api")
      
      if (httr::status_code(response) == 200) {
        output$api_status_ui <- renderUI({
          div(class = "api-status-success",
              icon("check-circle"), " API connection successful! Your key is working correctly.")
        })
        showNotification("API connection successful!", 
                         type = "message", 
                         duration = 5)
        return(TRUE)
      } else {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        output$api_status_ui <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), 
              " API connection failed. Status: ", httr::status_code(response),
              tags$br(),
              tags$small("Error: ", substr(error_content, 1, 200)))
        })
        showNotification(paste("API Error:", httr::status_code(response)), 
                         type = "error", 
                         duration = 5)
        return(FALSE)
      }
    }, error = function(e) {
      removeNotification(id = "test_api")
      error_msg <- conditionMessage(e)
      
      if (grepl("Could not resolve host", error_msg, ignore.case = TRUE)) {
        output$api_status_ui <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), 
              " DNS Resolution Error: Cannot reach api.openai.com",
              tags$br(),
              tags$small("Possible causes:"),
              tags$ul(
                tags$li("No internet connection"),
                tags$li("Firewall blocking the connection"),
                tags$li("VPN or proxy issues"),
                tags$li("Network restrictions from your organization")
              ),
              tags$small("Try: Check internet connection, disable VPN temporarily, or contact IT support"))
        })
      } else {
        output$api_status_ui <- renderUI({
          div(class = "api-status-error",
              icon("exclamation-circle"), " Connection error: ", error_msg)
        })
      }
      
      showNotification(paste("Error:", error_msg), 
                       type = "error", 
                       duration = 10)
      return(FALSE)
    })
  })
  
  # Function to get FULL context from ALL tabs
  get_full_context <- function() {
    context <- "\n\n=== FULL APPLICATION CONTEXT ===\n"
    
    # Tab 2: Project Details
    if (!is.null(input$project_summary) && nchar(trimws(input$project_summary)) > 0) {
      context <- paste0(context, "\n[PROJECT SUMMARY]\n", input$project_summary)
    }
    
    if (!is.null(input$public_description) && nchar(trimws(input$public_description)) > 0) {
      context <- paste0(context, "\n\n[PUBLIC DESCRIPTION]\n", input$public_description)
    }
    
    if (!is.null(input$scope) && nchar(trimws(input$scope)) > 0) {
      context <- paste0(context, "\n\n[SCOPE]\n", input$scope)
    }
    
    # Tab 3: Business Case
    if (!is.null(input$problem_opportunity) && nchar(trimws(input$problem_opportunity)) > 0) {
      context <- paste0(context, "\n\n[PROBLEM & MARKET POTENTIAL]\n", input$problem_opportunity)
    }
    
    if (!is.null(input$cam_service) && nchar(trimws(input$cam_service)) > 0) {
      context <- paste0(context, "\n\n[CAM SERVICE & VALUE PROPOSITION]\n", input$cam_service)
    }
    
    if (!is.null(input$readiness) && nchar(trimws(input$readiness)) > 0) {
      context <- paste0(context, "\n\n[READINESS & REGULATORY COMPLIANCE]\n", input$readiness)
    }
    
    if (!is.null(input$feasibility) && nchar(trimws(input$feasibility)) > 0) {
      context <- paste0(context, "\n\n[FEASIBILITY STUDY PLAN]\n", input$feasibility)
    }
    
    if (!is.null(input$commercialisation) && nchar(trimws(input$commercialisation)) > 0) {
      context <- paste0(context, "\n\n[COMMERCIALISATION ROADMAP]\n", input$commercialisation)
    }
    
    # Tab 4: Team & Impact (include if any exists)
    if (!is.null(input$team_capability) && nchar(trimws(input$team_capability)) > 0) {
      context <- paste0(context, "\n\n[TEAM & CAPABILITY]\n", input$team_capability)
    }
    
    if (!is.null(input$finance_risk) && nchar(trimws(input$finance_risk)) > 0) {
      context <- paste0(context, "\n\n[FINANCE & RISK MANAGEMENT]\n", input$finance_risk)
    }
    
    if (!is.null(input$impact) && nchar(trimws(input$impact)) > 0) {
      context <- paste0(context, "\n\n[IMPACT ON UK ECONOMY]\n", input$impact)
    }
    
    context <- paste0(context, "\n\n=== END OF CONTEXT ===\n")
    
    return(context)
  }
  
  # Function to call ChatGPT API with full context
  call_chatgpt_with_context <- function(prompt, word_limit, section_name) {
    if (!values$api_key_saved || is.null(values$api_key)) {
      showNotification("Please configure and save your API key in the API Configuration tab first!", 
                       type = "error", 
                       duration = 5)
      return(NULL)
    }
    
    # Get full application context
    full_context <- get_full_context()
    
    # Build complete prompt with context
    complete_prompt <- paste0(
      full_context,
      "\n\nBased on ALL the above context from the entire application, ",
      "please respond to the following question while maintaining consistency with all previous sections:\n\n",
      prompt
    )
    
    tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", values$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = "gpt-4",
          messages = list(
            list(
              role = "system",
              content = "You are a professional grant proposal writer with expertise in creating compelling, innovative project descriptions. Write clear, concise, and persuasive content that highlights innovation and aligns with funding requirements. IMPORTANT: Maintain consistency with ALL previously provided sections and ensure your responses build upon the established narrative."
            ),
            list(
              role = "user",
              content = complete_prompt
            )
          ),
          max_tokens = as.integer(word_limit * 2.5),
          temperature = 0.7
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(120),
        httr::config(ssl_verifypeer = TRUE)
      )
      
      if (httr::status_code(response) == 200) {
        content_response <- httr::content(response, "parsed")
        generated_text <- content_response$choices[[1]]$message$content
        generated_text <- trimws(generated_text)
        return(generated_text)
      } else {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        error_message <- paste("API Error (Status", httr::status_code(response), "):", 
                               substr(error_content, 1, 200))
        showNotification(error_message, 
                         type = "error", 
                         duration = 10)
        return(NULL)
      }
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      
      if (grepl("Could not resolve host|Could not resolve hostname", error_msg, ignore.case = TRUE)) {
        showNotification(
          "DNS Error: Cannot reach OpenAI servers. Check your internet connection or network settings.", 
          type = "error", 
          duration = 15
        )
      } else if (grepl("timeout", error_msg, ignore.case = TRUE)) {
        showNotification(
          "Request timeout: The API is taking too long to respond. Try again or reduce word limit.", 
          type = "error", 
          duration = 10
        )
      } else {
        showNotification(
          paste("Error calling ChatGPT:", error_msg), 
          type = "error", 
          duration = 10
        )
      }
      return(NULL)
    })
  }
  
  # Simple version for Tab 2 (no context needed)
  call_chatgpt <- function(prompt, word_limit, section_name) {
    if (!values$api_key_saved || is.null(values$api_key)) {
      showNotification("Please configure and save your API key in the API Configuration tab first!", 
                       type = "error", 
                       duration = 5)
      return(NULL)
    }
    
    tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", values$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = "gpt-4",
          messages = list(
            list(
              role = "system",
              content = "You are a professional grant proposal writer with expertise in creating compelling, innovative project descriptions. Write clear, concise, and persuasive content that highlights innovation and aligns with funding requirements."
            ),
            list(
              role = "user",
              content = prompt
            )
          ),
          max_tokens = as.integer(word_limit * 2),
          temperature = 0.7
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(120),
        httr::config(ssl_verifypeer = TRUE)
      )
      
      if (httr::status_code(response) == 200) {
        content_response <- httr::content(response, "parsed")
        generated_text <- content_response$choices[[1]]$message$content
        generated_text <- trimws(generated_text)
        return(generated_text)
      } else {
        error_content <- httr::content(response, "text", encoding = "UTF-8")
        error_message <- paste("API Error (Status", httr::status_code(response), "):", 
                               substr(error_content, 1, 200))
        showNotification(error_message, 
                         type = "error", 
                         duration = 10)
        return(NULL)
      }
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      
      if (grepl("Could not resolve host|Could not resolve hostname", error_msg, ignore.case = TRUE)) {
        showNotification(
          "DNS Error: Cannot reach OpenAI servers. Check your internet connection or network settings.", 
          type = "error", 
          duration = 15
        )
      } else if (grepl("timeout", error_msg, ignore.case = TRUE)) {
        showNotification(
          "Request timeout: The API is taking too long to respond. Try again or reduce word limit.", 
          type = "error", 
          duration = 10
        )
      } else {
        showNotification(
          paste("Error calling ChatGPT:", error_msg), 
          type = "error", 
          duration = 10
        )
      }
      return(NULL)
    })
  }
  
  # TAB 2 GENERATORS (Project Details - No context)
  
  observeEvent(input$generate_1, {
    req(input$main_ideas_1)
    
    if (nchar(trimws(input$main_ideas_1)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Based on the following main ideas and key points, write a compelling project summary that:\n",
      "1. Describes the project briefly and clearly\n",
      "2. Highlights what makes it innovative and unique\n",
      "3. Is suitable for expert reviewers to assess the application\n",
      "4. Is approximately ", input$word_limit_1, " words long (strict limit)\n",
      "5. Is professional, clear, and persuasive\n\n",
      "Main Ideas and Key Points:\n", input$main_ideas_1, "\n\n",
      "Write ONLY the project summary text, without any additional commentary or labels. ",
      "Make it exactly around ", input$word_limit_1, " words."
    )
    
    showNotification("Generating project summary with ChatGPT...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen1")
    
    result <- call_chatgpt(prompt, input$word_limit_1, "Project Summary")
    
    removeNotification(id = "gen1")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "project_summary", value = result)
      showNotification("Project summary generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_2, {
    req(input$main_ideas_2)
    
    if (nchar(trimws(input$main_ideas_2)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Based on the following main ideas and key points, write a detailed public project description that:\n",
      "1. Describes the project comprehensively and in detail\n",
      "2. Is suitable for public publication (no commercially sensitive information)\n",
      "3. Is clear, professional, and engaging for a general audience\n",
      "4. Is approximately ", input$word_limit_2, " words long (strict limit)\n",
      "5. Explains the project's objectives, approach, and expected outcomes\n\n",
      "Main Ideas and Key Points:\n", input$main_ideas_2, "\n\n",
      "Write ONLY the public description text, without any additional commentary or labels. ",
      "Make it exactly around ", input$word_limit_2, " words."
    )
    
    showNotification("Generating public description with ChatGPT...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen2")
    
    result <- call_chatgpt(prompt, input$word_limit_2, "Public Description")
    
    removeNotification(id = "gen2")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "public_description", value = result)
      showNotification("Public description generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_3, {
    req(input$main_ideas_3)
    
    if (nchar(trimws(input$main_ideas_3)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Based on the following main ideas and key points, write a project scope description that:\n",
      "1. Clearly explains how the project fits the competition scope\n",
      "2. Demonstrates alignment with competition requirements and eligibility\n",
      "3. Is approximately ", input$word_limit_3, " words long (strict limit)\n",
      "4. Is convincing and shows clear understanding of the competition criteria\n",
      "5. Addresses any specific scope requirements mentioned\n\n",
      "Main Ideas and Key Points:\n", input$main_ideas_3, "\n\n",
      "Write ONLY the scope description text, without any additional commentary or labels. ",
      "Make it exactly around ", input$word_limit_3, " words."
    )
    
    showNotification("Generating scope description with ChatGPT...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen3")
    
    result <- call_chatgpt(prompt, input$word_limit_3, "Scope")
    
    removeNotification(id = "gen3")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "scope", value = result)
      showNotification("Scope description generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  # TAB 3 GENERATORS (Business Case - with Tab 2 context)
  
  observeEvent(input$generate_bc1, {
    req(input$main_ideas_bc1)
    
    if (nchar(trimws(input$main_ideas_bc1)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: What mobility challenge or gap are you addressing, and what is the size and timing of the opportunity which this business case can unlock?\n\n",
      "Main Ideas:\n", input$main_ideas_bc1, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_bc1, " words. ",
      "Be specific, data-driven, and maintain consistency with the project context provided above."
    )
    
    showNotification("Generating response with full context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_bc1")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_bc1, "Problem & Market")
    
    removeNotification(id = "gen_bc1")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "problem_opportunity", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_bc2, {
    req(input$main_ideas_bc2)
    
    if (nchar(trimws(input$main_ideas_bc2)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: What CAM service or solution are you proposing, and why is this the right service in the right location?\n\n",
      "Main Ideas:\n", input$main_ideas_bc2, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_bc2, " words. ",
      "Be specific about the CAM service, value proposition, and location context."
    )
    
    showNotification("Generating response with full context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_bc2")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_bc2, "CAM Service")
    
    removeNotification(id = "gen_bc2")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "cam_service", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_bc3, {
    req(input$main_ideas_bc3)
    
    if (nchar(trimws(input$main_ideas_bc3)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: How ready is your current business case? Identify areas where you have complete knowledge and what gaps your feasibility study will address to get to an investment ready decision point?\n\n",
      "Main Ideas:\n", input$main_ideas_bc3, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_bc3, " words. ",
      "Address readiness, stakeholders, and regulatory compliance."
    )
    
    showNotification("Generating response with full context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_bc3")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_bc3, "Readiness")
    
    removeNotification(id = "gen_bc3")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "readiness", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_bc4, {
    req(input$main_ideas_bc4)
    
    if (nchar(trimws(input$main_ideas_bc4)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: What will your feasibility study deliver, and how will you know if it is successful?\n\n",
      "Main Ideas:\n", input$main_ideas_bc4, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_bc4, " words. ",
      "Include feasibility study plan, business case development, and gateway criteria."
    )
    
    showNotification("Generating response with full context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_bc4")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_bc4, "Feasibility")
    
    removeNotification(id = "gen_bc4")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "feasibility", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_bc5, {
    req(input$main_ideas_bc5)
    
    if (nchar(trimws(input$main_ideas_bc5)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: What happens after the feasibility study, and how will you measure progress?\n\n",
      "Main Ideas:\n", input$main_ideas_bc5, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_bc5, " words. ",
      "Include commercialisation roadmap and key performance indicators (KPIs)."
    )
    
    showNotification("Generating response with full context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_bc5")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_bc5, "Commercialisation")
    
    removeNotification(id = "gen_bc5")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "commercialisation", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  # TAB 4 GENERATORS (Team & Impact - with FULL context from all previous tabs)
  
  observeEvent(input$generate_ti1, {
    req(input$main_ideas_ti1)
    
    if (nchar(trimws(input$main_ideas_ti1)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: Who is in your team and how will you fill any gaps?\n\n",
      "Address the following points:\n",
      "- The level of senior buy-in for the project and your authority to proceed\n",
      "- The skills and experience of your team relevant to this project\n",
      "- How you will address any capability gaps during or after the study\n",
      "- Evidence why the team has the resource capacity to undertake this study\n\n",
      "Main Ideas:\n", input$main_ideas_ti1, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_ti1, " words. ",
      "Maintain consistency with all previously provided information about the project."
    )
    
    showNotification("Generating response with FULL application context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_ti1")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_ti1, "Team & Capability")
    
    removeNotification(id = "gen_ti1")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "team_capability", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_ti2, {
    req(input$main_ideas_ti2)
    
    if (nchar(trimws(input$main_ideas_ti2)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: How will you manage finances and risks during the study?\n\n",
      "Address the following points:\n",
      "- How you will ensure financial resilience within your organisation or consortia\n",
      "- Address cashflow restrictions and major spend items\n",
      "- Identify key risks to delivering an investment-ready business case\n",
      "- How you will manage and mitigate risks (technical, commercial, legal, environmental)\n\n",
      "Main Ideas:\n", input$main_ideas_ti2, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_ti2, " words. ",
      "Maintain consistency with all previously provided information about the project and budget."
    )
    
    showNotification("Generating response with FULL application context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_ti2")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_ti2, "Finance & Risk")
    
    removeNotification(id = "gen_ti2")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "finance_risk", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_ti3, {
    req(input$main_ideas_ti3)
    
    if (nchar(trimws(input$main_ideas_ti3)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: What impact will your proposal have on the UK economy and society?\n\n",
      "Address and quantify the following points:\n",
      "- Potential for UK jobs (direct and indirect operational roles)\n",
      "- Anchoring innovation centres of excellence or manufacturing\n",
      "- Wider benefits such as CO₂ reduction and economic growth\n",
      "- UK capability building opportunities and any overseas aspects\n\n",
      "Main Ideas:\n", input$main_ideas_ti3, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_ti3, " words. ",
      "Include quantifiable metrics where possible and maintain consistency with all previous sections."
    )
    
    showNotification("Generating response with FULL application context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_ti3")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_ti3, "Impact")
    
    removeNotification(id = "gen_ti3")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "impact", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  observeEvent(input$generate_ti4, {
    req(input$main_ideas_ti4)
    
    if (nchar(trimws(input$main_ideas_ti4)) < 10) {
      showNotification("Please enter more detailed main ideas (at least 10 characters)", 
                       type = "warning", 
                       duration = 3)
      return()
    }
    
    prompt <- paste0(
      "Question: How do your costs represent value for money?\n\n",
      "Justify and explain:\n",
      "- The overall costs of your feasibility study including subcontractor costs and overseas spend\n",
      "- Why you need the funding\n",
      "- What would happen to this project in the absence of funding\n\n",
      "Main Ideas:\n", input$main_ideas_ti4, "\n\n",
      "Write a comprehensive response of approximately ", input$word_limit_ti4, " words. ",
      "Provide clear justification and maintain consistency with the project scope and objectives."
    )
    
    showNotification("Generating response with FULL application context...", 
                     type = "message", 
                     duration = NULL, 
                     id = "gen_ti4")
    
    result <- call_chatgpt_with_context(prompt, input$word_limit_ti4, "Costs & Value")
    
    removeNotification(id = "gen_ti4")
    
    if (!is.null(result)) {
      updateTextAreaInput(session, "costs_value", value = result)
      showNotification("Response generated successfully!", 
                       type = "message", 
                       duration = 3)
    }
  })
  
  # Word counters for Tab 2
  output$word_count_1 <- renderText({
    if (nchar(trimws(input$project_summary)) == 0) {
      paste("Words: 0 /", input$word_limit_1, "| Words remaining:", input$word_limit_1)
    } else {
      words <- strsplit(trimws(input$project_summary), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_1 - word_count
      paste("Words:", word_count, "/", input$word_limit_1, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_2 <- renderText({
    if (nchar(trimws(input$public_description)) == 0) {
      paste("Words: 0 /", input$word_limit_2, "| Words remaining:", input$word_limit_2)
    } else {
      words <- strsplit(trimws(input$public_description), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_2 - word_count
      paste("Words:", word_count, "/", input$word_limit_2, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_3 <- renderText({
    if (nchar(trimws(input$scope)) == 0) {
      paste("Words: 0 /", input$word_limit_3, "| Words remaining:", input$word_limit_3)
    } else {
      words <- strsplit(trimws(input$scope), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_3 - word_count
      paste("Words:", word_count, "/", input$word_limit_3, "| Words remaining:", remaining)
    }
  })
  
  # Word counters for Business Case tab
  output$word_count_bc1 <- renderText({
    if (nchar(trimws(input$problem_opportunity)) == 0) {
      paste("Words: 0 /", input$word_limit_bc1, "| Words remaining:", input$word_limit_bc1)
    } else {
      words <- strsplit(trimws(input$problem_opportunity), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_bc1 - word_count
      paste("Words:", word_count, "/", input$word_limit_bc1, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_bc2 <- renderText({
    if (nchar(trimws(input$cam_service)) == 0) {
      paste("Words: 0 /", input$word_limit_bc2, "| Words remaining:", input$word_limit_bc2)
    } else {
      words <- strsplit(trimws(input$cam_service), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_bc2 - word_count
      paste("Words:", word_count, "/", input$word_limit_bc2, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_bc3 <- renderText({
    if (nchar(trimws(input$readiness)) == 0) {
      paste("Words: 0 /", input$word_limit_bc3, "| Words remaining:", input$word_limit_bc3)
    } else {
      words <- strsplit(trimws(input$readiness), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_bc3 - word_count
      paste("Words:", word_count, "/", input$word_limit_bc3, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_bc4 <- renderText({
    if (nchar(trimws(input$feasibility)) == 0) {
      paste("Words: 0 /", input$word_limit_bc4, "| Words remaining:", input$word_limit_bc4)
    } else {
      words <- strsplit(trimws(input$feasibility), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_bc4 - word_count
      paste("Words:", word_count, "/", input$word_limit_bc4, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_bc5 <- renderText({
    if (nchar(trimws(input$commercialisation)) == 0) {
      paste("Words: 0 /", input$word_limit_bc5, "| Words remaining:", input$word_limit_bc5)
    } else {
      words <- strsplit(trimws(input$commercialisation), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_bc5 - word_count
      paste("Words:", word_count, "/", input$word_limit_bc5, "| Words remaining:", remaining)
    }
  })
  
  # Word counters for Team & Impact tab
  output$word_count_ti1 <- renderText({
    if (nchar(trimws(input$team_capability)) == 0) {
      paste("Words: 0 /", input$word_limit_ti1, "| Words remaining:", input$word_limit_ti1)
    } else {
      words <- strsplit(trimws(input$team_capability), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_ti1 - word_count
      paste("Words:", word_count, "/", input$word_limit_ti1, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_ti2 <- renderText({
    if (nchar(trimws(input$finance_risk)) == 0) {
      paste("Words: 0 /", input$word_limit_ti2, "| Words remaining:", input$word_limit_ti2)
    } else {
      words <- strsplit(trimws(input$finance_risk), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_ti2 - word_count
      paste("Words:", word_count, "/", input$word_limit_ti2, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_ti3 <- renderText({
    if (nchar(trimws(input$impact)) == 0) {
      paste("Words: 0 /", input$word_limit_ti3, "| Words remaining:", input$word_limit_ti3)
    } else {
      words <- strsplit(trimws(input$impact), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_ti3 - word_count
      paste("Words:", word_count, "/", input$word_limit_ti3, "| Words remaining:", remaining)
    }
  })
  
  output$word_count_ti4 <- renderText({
    if (nchar(trimws(input$costs_value)) == 0) {
      paste("Words: 0 /", input$word_limit_ti4, "| Words remaining:", input$word_limit_ti4)
    } else {
      words <- strsplit(trimws(input$costs_value), "\\s+")[[1]]
      word_count <- length(words)
      remaining <- input$word_limit_ti4 - word_count
      paste("Words:", word_count, "/", input$word_limit_ti4, "| Words remaining:", remaining)
    }
  })
  
  # Save to Excel (Tab 2)
  observeEvent(input$save_excel, {
    req(input$version_name, input$sheet_name, input$file_path)
    
    if (nchar(trimws(input$version_name)) == 0 || 
        nchar(trimws(input$sheet_name)) == 0 || 
        nchar(trimws(input$file_path)) == 0) {
      output$save_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Please fill in all fields: Version Name, Sheet Name, and File Path.")
      })
      showNotification("Please fill in all required fields", 
                       type = "error", 
                       duration = 3)
      return()
    }
    
    tryCatch({
      word_count_1 <- if (nchar(trimws(input$project_summary)) == 0) 0 else 
        length(strsplit(trimws(input$project_summary), "\\s+")[[1]])
      word_count_2 <- if (nchar(trimws(input$public_description)) == 0) 0 else 
        length(strsplit(trimws(input$public_description), "\\s+")[[1]])
      word_count_3 <- if (nchar(trimws(input$scope)) == 0) 0 else 
        length(strsplit(trimws(input$scope), "\\s+")[[1]])
      
      data <- data.frame(
        Version = rep(input$version_name, 3),
        Section = c("Project Summary", "Public Description", "Scope"),
        Question = c(
          "What should I include in the project summary? Describe your project briefly and be clear about what makes it innovative.",
          "What should I include in the project public description? Describe your project in detail and in a way that you are happy to see published.",
          "What should I include in the project scope? Describe how your project fits the scope of the competition."
        ),
        MainIdeas = c(
          ifelse(is.null(input$main_ideas_1) || input$main_ideas_1 == "", "", input$main_ideas_1), 
          ifelse(is.null(input$main_ideas_2) || input$main_ideas_2 == "", "", input$main_ideas_2), 
          ifelse(is.null(input$main_ideas_3) || input$main_ideas_3 == "", "", input$main_ideas_3)
        ),
        GeneratedContent = c(
          ifelse(is.null(input$project_summary) || input$project_summary == "", "", input$project_summary), 
          ifelse(is.null(input$public_description) || input$public_description == "", "", input$public_description), 
          ifelse(is.null(input$scope) || input$scope == "", "", input$scope)
        ),
        WordLimit = c(
          input$word_limit_1, 
          input$word_limit_2, 
          input$word_limit_3
        ),
        WordCount = c(
          word_count_1,
          word_count_2,
          word_count_3
        ),
        WordsRemaining = c(
          input$word_limit_1 - word_count_1,
          input$word_limit_2 - word_count_2,
          input$word_limit_3 - word_count_3
        ),
        Timestamp = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 3),
        stringsAsFactors = FALSE
      )
      
      file_path <- normalizePath(input$file_path, mustWork = FALSE)
      
      if (file.exists(file_path)) {
        wb <- loadWorkbook(file_path)
        
        if (input$sheet_name %in% names(wb)) {
          removeWorksheet(wb, input$sheet_name)
          showNotification(paste("Overwriting existing sheet:", input$sheet_name), 
                           type = "warning", 
                           duration = 2)
        }
        
        addWorksheet(wb, input$sheet_name)
        writeData(wb, input$sheet_name, data, startRow = 1, startCol = 1)
        setColWidths(wb, input$sheet_name, cols = 1:ncol(data), widths = "auto")
        addStyle(wb, input$sheet_name, 
                 style = createStyle(fgFill = "#4a90e2", fontColour = "#ffffff", textDecoration = "bold"),
                 rows = 1, cols = 1:ncol(data), gridExpand = TRUE)
        
        saveWorkbook(wb, file_path, overwrite = TRUE)
        
        output$save_status_ui <- renderUI({
          div(class = "save-status-success",
              icon("check-circle"), 
              " Data saved successfully to: ", tags$br(),
              tags$strong(file_path), tags$br(),
              "Sheet: ", tags$strong(input$sheet_name))
        })
        
        showNotification(paste("Data saved to sheet:", input$sheet_name), 
                         type = "message", 
                         duration = 5)
        
      } else {
        wb <- createWorkbook()
        addWorksheet(wb, input$sheet_name)
        writeData(wb, input$sheet_name, data, startRow = 1, startCol = 1)
        setColWidths(wb, input$sheet_name, cols = 1:ncol(data), widths = "auto")
        addStyle(wb, input$sheet_name, 
                 style = createStyle(fgFill = "#4a90e2", fontColour = "#ffffff", textDecoration = "bold"),
                 rows = 1, cols = 1:ncol(data), gridExpand = TRUE)
        
        saveWorkbook(wb, file_path)
        
        output$save_status_ui <- renderUI({
          div(class = "save-status-success",
              icon("check-circle"), 
              " New file created and data saved to: ", tags$br(),
              tags$strong(file_path), tags$br(),
              "Sheet: ", tags$strong(input$sheet_name))
        })
        
        showNotification(paste("New file created with sheet:", input$sheet_name), 
                         type = "message", 
                         duration = 5)
      }
      
    }, error = function(e) {
      output$save_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Error saving file: ", tags$br(),
            tags$small(e$message))
      })
      showNotification(paste("Error saving Excel file:", e$message), 
                       type = "error", 
                       duration = 10)
    })
  })
  
  # Save Business Case to Excel
  observeEvent(input$save_business_case, {
    
    if (is.null(input$file_path) || nchar(trimws(input$file_path)) == 0) {
      output$save_bc_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Please configure the file path in the Project Details tab first!")
      })
      showNotification("Please configure the file path in the Project Details tab first!", 
                       type = "error", 
                       duration = 5)
      return()
    }
    
    if (is.null(input$sheet_name) || nchar(trimws(input$sheet_name)) == 0) {
      output$save_bc_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Please configure the sheet name in the Project Details tab first!")
      })
      showNotification("Please configure the sheet name in the Project Details tab first!", 
                       type = "error", 
                       duration = 5)
      return()
    }
    
    tryCatch({
      word_count_bc1 <- if (nchar(trimws(input$problem_opportunity)) == 0) 0 else 
        length(strsplit(trimws(input$problem_opportunity), "\\s+")[[1]])
      word_count_bc2 <- if (nchar(trimws(input$cam_service)) == 0) 0 else 
        length(strsplit(trimws(input$cam_service), "\\s+")[[1]])
      word_count_bc3 <- if (nchar(trimws(input$readiness)) == 0) 0 else 
        length(strsplit(trimws(input$readiness), "\\s+")[[1]])
      word_count_bc4 <- if (nchar(trimws(input$feasibility)) == 0) 0 else 
        length(strsplit(trimws(input$feasibility), "\\s+")[[1]])
      word_count_bc5 <- if (nchar(trimws(input$commercialisation)) == 0) 0 else 
        length(strsplit(trimws(input$commercialisation), "\\s+")[[1]])
      
      data_bc <- data.frame(
        Version = rep(input$version_name, 5),
        Section = c("Problem & Market", "CAM Service", "Readiness", "Feasibility", "Commercialisation"),
        Question = c(
          "What mobility challenge or gap are you addressing, and what is the size and timing of the opportunity which this business case can unlock?",
          "What CAM service or solution are you proposing, and why is this the right service in the right location?",
          "How ready is your current business case? Identify areas where you have complete knowledge and what gaps your feasibility study will address to get to an investment ready decision point?",
          "What will your feasibility study deliver, and how will you know if it is successful?",
          "What happens after the feasibility study, and how will you measure progress?"
        ),
        MainIdeas = c(
          ifelse(is.null(input$main_ideas_bc1) || input$main_ideas_bc1 == "", "", input$main_ideas_bc1), 
          ifelse(is.null(input$main_ideas_bc2) || input$main_ideas_bc2 == "", "", input$main_ideas_bc2), 
          ifelse(is.null(input$main_ideas_bc3) || input$main_ideas_bc3 == "", "", input$main_ideas_bc3),
          ifelse(is.null(input$main_ideas_bc4) || input$main_ideas_bc4 == "", "", input$main_ideas_bc4),
          ifelse(is.null(input$main_ideas_bc5) || input$main_ideas_bc5 == "", "", input$main_ideas_bc5)
        ),
        GeneratedContent = c(
          ifelse(is.null(input$problem_opportunity) || input$problem_opportunity == "", "", input$problem_opportunity), 
          ifelse(is.null(input$cam_service) || input$cam_service == "", "", input$cam_service), 
          ifelse(is.null(input$readiness) || input$readiness == "", "", input$readiness),
          ifelse(is.null(input$feasibility) || input$feasibility == "", "", input$feasibility),
          ifelse(is.null(input$commercialisation) || input$commercialisation == "", "", input$commercialisation)
        ),
        WordLimit = c(
          input$word_limit_bc1, 
          input$word_limit_bc2, 
          input$word_limit_bc3,
          input$word_limit_bc4,
          input$word_limit_bc5
        ),
        WordCount = c(
          word_count_bc1,
          word_count_bc2,
          word_count_bc3,
          word_count_bc4,
          word_count_bc5
        ),
        WordsRemaining = c(
          input$word_limit_bc1 - word_count_bc1,
          input$word_limit_bc2 - word_count_bc2,
          input$word_limit_bc3 - word_count_bc3,
          input$word_limit_bc4 - word_count_bc4,
          input$word_limit_bc5 - word_count_bc5
        ),
        Timestamp = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 5),
        stringsAsFactors = FALSE
      )
      
      file_path <- normalizePath(input$file_path, mustWork = FALSE)
      
      if (file.exists(file_path)) {
        wb <- loadWorkbook(file_path)
        
        if (input$sheet_name %in% names(wb)) {
          existing_data <- readWorkbook(wb, input$sheet_name)
          combined_data <- rbind(existing_data, data_bc)
          
          removeWorksheet(wb, input$sheet_name)
          addWorksheet(wb, input$sheet_name)
          writeData(wb, input$sheet_name, combined_data, startRow = 1, startCol = 1)
          
        } else {
          addWorksheet(wb, input$sheet_name)
          writeData(wb, input$sheet_name, data_bc, startRow = 1, startCol = 1)
        }
        
        setColWidths(wb, input$sheet_name, cols = 1:ncol(data_bc), widths = "auto")
        addStyle(wb, input$sheet_name, 
                 style = createStyle(fgFill = "#4a90e2", fontColour = "#ffffff", textDecoration = "bold"),
                 rows = 1, cols = 1:ncol(data_bc), gridExpand = TRUE)
        
        saveWorkbook(wb, file_path, overwrite = TRUE)
        
        output$save_bc_status_ui <- renderUI({
          div(class = "save-status-success",
              icon("check-circle"), 
              " Business case data appended successfully to: ", tags$br(),
              tags$strong(file_path), tags$br(),
              "Sheet: ", tags$strong(input$sheet_name))
        })
        
        showNotification("Business case data saved successfully!", 
                         type = "message", 
                         duration = 5)
        
      } else {
        showNotification("File does not exist. Please save Project Details first!", 
                         type = "error", 
                         duration = 5)
      }
      
    }, error = function(e) {
      output$save_bc_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Error saving business case: ", tags$br(),
            tags$small(e$message))
      })
      showNotification(paste("Error saving business case:", e$message), 
                       type = "error", 
                       duration = 10)
    })
  })
  
  # Save Team & Impact to Excel
  observeEvent(input$save_team_impact, {
    
    if (is.null(input$file_path) || nchar(trimws(input$file_path)) == 0) {
      output$save_ti_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Please configure the file path in the Project Details tab first!")
      })
      showNotification("Please configure the file path in the Project Details tab first!", 
                       type = "error", 
                       duration = 5)
      return()
    }
    
    if (is.null(input$sheet_name) || nchar(trimws(input$sheet_name)) == 0) {
      output$save_ti_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Please configure the sheet name in the Project Details tab first!")
      })
      showNotification("Please configure the sheet name in the Project Details tab first!", 
                       type = "error", 
                       duration = 5)
      return()
    }
    
    tryCatch({
      word_count_ti1 <- if (nchar(trimws(input$team_capability)) == 0) 0 else 
        length(strsplit(trimws(input$team_capability), "\\s+")[[1]])
      word_count_ti2 <- if (nchar(trimws(input$finance_risk)) == 0) 0 else 
        length(strsplit(trimws(input$finance_risk), "\\s+")[[1]])
      word_count_ti3 <- if (nchar(trimws(input$impact)) == 0) 0 else 
        length(strsplit(trimws(input$impact), "\\s+")[[1]])
      word_count_ti4 <- if (nchar(trimws(input$costs_value)) == 0) 0 else 
        length(strsplit(trimws(input$costs_value), "\\s+")[[1]])
      
      data_ti <- data.frame(
        Version = rep(input$version_name, 4),
        Section = c("Team & Capability", "Finance & Risk", "Impact", "Costs & Value"),
        Question = c(
          "Who is in your team and how will you fill any gaps? Describe the level of senior buy-in, team skills and experience, how you will address capability gaps, and evidence of resource capacity.",
          "How will you manage finances and risks during the study? Explain financial resilience, cashflow management, key risks (technical, commercial, legal, environmental), and mitigation strategies.",
          "What impact will your proposal have on the UK economy and society? Quantify UK jobs (direct and indirect), innovation centres, wider benefits (CO₂ reduction, economic growth), and UK capability building.",
          "How do your costs represent value for money? Justify overall costs, subcontractor and overseas spend, why you need funding, and what would happen without it."
        ),
        MainIdeas = c(
          ifelse(is.null(input$main_ideas_ti1) || input$main_ideas_ti1 == "", "", input$main_ideas_ti1), 
          ifelse(is.null(input$main_ideas_ti2) || input$main_ideas_ti2 == "", "", input$main_ideas_ti2), 
          ifelse(is.null(input$main_ideas_ti3) || input$main_ideas_ti3 == "", "", input$main_ideas_ti3),
          ifelse(is.null(input$main_ideas_ti4) || input$main_ideas_ti4 == "", "", input$main_ideas_ti4)
        ),
        GeneratedContent = c(
          ifelse(is.null(input$team_capability) || input$team_capability == "", "", input$team_capability), 
          ifelse(is.null(input$finance_risk) || input$finance_risk == "", "", input$finance_risk), 
          ifelse(is.null(input$impact) || input$impact == "", "", input$impact),
          ifelse(is.null(input$costs_value) || input$costs_value == "", "", input$costs_value)
        ),
        WordLimit = c(
          input$word_limit_ti1, 
          input$word_limit_ti2, 
          input$word_limit_ti3,
          input$word_limit_ti4
        ),
        WordCount = c(
          word_count_ti1,
          word_count_ti2,
          word_count_ti3,
          word_count_ti4
        ),
        WordsRemaining = c(
          input$word_limit_ti1 - word_count_ti1,
          input$word_limit_ti2 - word_count_ti2,
          input$word_limit_ti3 - word_count_ti3,
          input$word_limit_ti4 - word_count_ti4
        ),
        Timestamp = rep(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), 4),
        stringsAsFactors = FALSE
      )
      
      file_path <- normalizePath(input$file_path, mustWork = FALSE)
      
      if (file.exists(file_path)) {
        wb <- loadWorkbook(file_path)
        
        if (input$sheet_name %in% names(wb)) {
          existing_data <- readWorkbook(wb, input$sheet_name)
          combined_data <- rbind(existing_data, data_ti)
          
          removeWorksheet(wb, input$sheet_name)
          addWorksheet(wb, input$sheet_name)
          writeData(wb, input$sheet_name, combined_data, startRow = 1, startCol = 1)
          
        } else {
          addWorksheet(wb, input$sheet_name)
          writeData(wb, input$sheet_name, data_ti, startRow = 1, startCol = 1)
        }
        
        setColWidths(wb, input$sheet_name, cols = 1:ncol(data_ti), widths = "auto")
        addStyle(wb, input$sheet_name, 
                 style = createStyle(fgFill = "#4a90e2", fontColour = "#ffffff", textDecoration = "bold"),
                 rows = 1, cols = 1:ncol(data_ti), gridExpand = TRUE)
        
        saveWorkbook(wb, file_path, overwrite = TRUE)
        
        output$save_ti_status_ui <- renderUI({
          div(class = "save-status-success",
              icon("check-circle"), 
              " Team & Impact data appended successfully to: ", tags$br(),
              tags$strong(file_path), tags$br(),
              "Sheet: ", tags$strong(input$sheet_name))
        })
        
        showNotification("Team & Impact data saved successfully!", 
                         type = "message", 
                         duration = 5)
        
      } else {
        showNotification("File does not exist. Please save Project Details first!", 
                         type = "error", 
                         duration = 5)
      }
      
    }, error = function(e) {
      output$save_ti_status_ui <- renderUI({
        div(class = "save-status-error",
            icon("exclamation-circle"), 
            " Error saving Team & Impact: ", tags$br(),
            tags$small(e$message))
      })
      showNotification(paste("Error saving Team & Impact:", e$message), 
                       type = "error", 
                       duration = 10)
    })
  })
}

# Run the app
shinyApp(ui = ui, server = server)