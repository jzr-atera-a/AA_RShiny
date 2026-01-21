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
      menuItem("Project Details", tabName = "project_details", icon = icon("file-text"))
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
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values to store API key and status messages
  values <- reactiveValues(
    api_key = NULL,
    api_key_saved = FALSE
  )
  
  # Save API Key
  observeEvent(input$save_api, {
    if (nchar(trimws(input$api_key)) > 0) {
      values$api_key <- trimws(input$api_key)
      values$api_key_saved <- TRUE
      
      output$api_status_ui <- renderUI({
        div(class = "api-status-success",
            icon("check-circle"), " API Key saved successfully! You can now use the Project Details tab.")
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
      # Set explicit timeout and use verbose for debugging
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
      
      # More detailed error message
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
  
  # Function to call ChatGPT API with improved error handling
  call_chatgpt <- function(prompt, word_limit, section_name) {
    if (!values$api_key_saved || is.null(values$api_key)) {
      showNotification("Please configure and save your API key in the API Configuration tab first!", 
                       type = "error", 
                       duration = 5)
      return(NULL)
    }
    
    tryCatch({
      # Increased timeout and better configuration
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
        httr::timeout(120),  # Increased timeout to 120 seconds
        httr::config(ssl_verifypeer = TRUE)
      )
      
      if (httr::status_code(response) == 200) {
        content_response <- httr::content(response, "parsed")
        generated_text <- content_response$choices[[1]]$message$content
        
        # Clean up the generated text
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
      
      # Detailed error handling
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
  
  # Generate Project Summary
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
    
    showNotification("Generating project summary with ChatGPT... This may take 10-60 seconds.", 
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
  
  # Generate Public Description
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
    
    showNotification("Generating public description with ChatGPT... This may take 10-60 seconds.", 
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
  
  # Generate Scope
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
    
    showNotification("Generating scope description with ChatGPT... This may take 10-60 seconds.", 
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
  
  # Word counters
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
  
  # Save to Excel
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
      # Calculate word counts
      word_count_1 <- if (nchar(trimws(input$project_summary)) == 0) 0 else 
        length(strsplit(trimws(input$project_summary), "\\s+")[[1]])
      word_count_2 <- if (nchar(trimws(input$public_description)) == 0) 0 else 
        length(strsplit(trimws(input$public_description), "\\s+")[[1]])
      word_count_3 <- if (nchar(trimws(input$scope)) == 0) 0 else 
        length(strsplit(trimws(input$scope), "\\s+")[[1]])
      
      # Create data frame with CORRECT structure
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
      
      # Normalize the file path
      file_path <- normalizePath(input$file_path, mustWork = FALSE)
      
      # Check if file exists
      if (file.exists(file_path)) {
        # Load existing workbook
        wb <- loadWorkbook(file_path)
        
        # Check if sheet exists and remove it to overwrite
        if (input$sheet_name %in% names(wb)) {
          removeWorksheet(wb, input$sheet_name)
          showNotification(paste("Overwriting existing sheet:", input$sheet_name), 
                           type = "warning", 
                           duration = 2)
        }
        
        # Add new worksheet
        addWorksheet(wb, input$sheet_name)
        writeData(wb, input$sheet_name, data, startRow = 1, startCol = 1)
        
        # Format the worksheet
        setColWidths(wb, input$sheet_name, cols = 1:ncol(data), widths = "auto")
        
        # Add header styling
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
        # Create new workbook
        wb <- createWorkbook()
        addWorksheet(wb, input$sheet_name)
        writeData(wb, input$sheet_name, data, startRow = 1, startCol = 1)
        
        # Format the worksheet
        setColWidths(wb, input$sheet_name, cols = 1:ncol(data), widths = "auto")
        
        # Add header styling
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
}

# Run the app
shinyApp(ui = ui, server = server)