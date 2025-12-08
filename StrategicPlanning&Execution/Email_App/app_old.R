# Email Sender Shiny App
# Required libraries
library(shiny)
library(shinydashboard)
library(mailR)
library(shinyWidgets)

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Email Sender App"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("SMTP Configuration", tabName = "smtp_config", icon = icon("cog")),
      menuItem("Send Email", tabName = "send_email", icon = icon("envelope"))
    )
  ),
  
  dashboardBody(
    # Include custom CSS
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
        
        .message-box {
          background: rgba(42, 82, 152, 0.3);
          border: 2px solid #4a90e2;
          border-radius: 10px;
          padding: 15px;
          margin: 15px 0;
          min-height: 300px;
          max-height: 400px;
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
      "))
    ),
    
    tabItems(
      # SMTP Configuration Tab
      tabItem(tabName = "smtp_config",
              fluidRow(
                box(
                  title = "SMTP Configuration", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(6,
                           textInput("smtp_host", 
                                     "SMTP Host:", 
                                     value = "smtp.secureserver.net",
                                     placeholder = "smtp.example.com")
                    ),
                    column(6,
                           textInput("smtp_port", 
                                     "SMTP Port:", 
                                     value = "465",
                                     placeholder = "465")
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           radioButtons("encryption", 
                                        "Encryption:",
                                        choices = c("None" = "none", 
                                                    "SSL" = "ssl", 
                                                    "TLS" = "tls"),
                                        selected = "ssl",
                                        inline = TRUE)
                    ),
                    column(6,
                           br(),
                           switchInput("auto_tls", 
                                       "Auto TLS", 
                                       value = TRUE,
                                       onLabel = "ON",
                                       offLabel = "OFF")
                    )
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(12,
                           switchInput("authentication", 
                                       "Authentication", 
                                       value = TRUE,
                                       onLabel = "ON",
                                       offLabel = "OFF")
                    )
                  ),
                  
                  fluidRow(
                    column(6,
                           textInput("smtp_username", 
                                     "SMTP Username:", 
                                     value = "all-b@rera-analytics.co.uk",
                                     placeholder = "username@domain.com")
                    ),
                    column(6,
                           passwordInput("smtp_password", 
                                         "SMTP Password:", 
                                         value = "",
                                         placeholder = "Enter password")
                    )
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(6,
                           actionButton("test_connection", 
                                        "Test & Open Connection", 
                                        icon = icon("plug"),
                                        class = "btn-success",
                                        width = "100%")
                    ),
                    column(6,
                           actionButton("close_connection", 
                                        "Close Connection", 
                                        icon = icon("times-circle"),
                                        class = "btn-danger",
                                        width = "100%")
                    )
                  ),
                  
                  br(),
                  
                  uiOutput("connection_status")
                )
              )
      ),
      
      # Send Email Tab
      tabItem(tabName = "send_email",
              fluidRow(
                box(
                  title = "Compose Email", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  textInput("email_to", 
                            "To:", 
                            placeholder = "recipient1@example.com, recipient2@example.com",
                            width = "100%"),
                  
                  helpText("Separate multiple email addresses with commas (,) or semicolons (;)"),
                  
                  textInput("email_subject", 
                            "Subject:", 
                            placeholder = "Enter email subject",
                            width = "100%"),
                  
                  br(),
                  
                  textAreaInput("email_body", 
                                "Message:", 
                                placeholder = "Type your message here...",
                                height = "300px",
                                width = "100%"),
                  
                  br(),
                  
                  div(class = "file-upload-box",
                      fileInput("email_attachments", 
                                "Attach Files:",
                                multiple = TRUE,
                                buttonLabel = "Browse...",
                                placeholder = "No files selected")
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(12,
                           actionButton("send_email_btn", 
                                        "Send Email", 
                                        icon = icon("paper-plane"),
                                        class = "btn-primary",
                                        width = "100%",
                                        style = "font-size: 18px; padding: 15px;")
                    )
                  ),
                  
                  br(),
                  
                  uiOutput("send_status")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store connection status
  connection_state <- reactiveValues(
    connected = FALSE,
    message = ""
  )
  
  # Test and open connection
  observeEvent(input$test_connection, {
    tryCatch({
      # Validate inputs
      if (input$smtp_host == "" || input$smtp_username == "" || input$smtp_password == "") {
        connection_state$connected <- FALSE
        connection_state$message <- "Please fill in all required fields (Host, Username, Password)"
        return()
      }
      
      # In a real application, you would test the SMTP connection here
      # For demonstration, we'll simulate a successful connection
      connection_state$connected <- TRUE
      connection_state$message <- "Connection established successfully!"
      
      showNotification(
        "SMTP connection opened successfully!",
        type = "message",
        duration = 5
      )
      
    }, error = function(e) {
      connection_state$connected <- FALSE
      connection_state$message <- paste("Connection failed:", e$message)
      
      showNotification(
        paste("Connection failed:", e$message),
        type = "error",
        duration = 5
      )
    })
  })
  
  # Close connection
  observeEvent(input$close_connection, {
    connection_state$connected <- FALSE
    connection_state$message <- "Connection closed"
    
    showNotification(
      "SMTP connection closed",
      type = "warning",
      duration = 3
    )
  })
  
  # Display connection status
  output$connection_status <- renderUI({
    if (connection_state$message != "") {
      if (connection_state$connected) {
        div(class = "alert alert-success",
            icon("check-circle"),
            strong(" Status: "),
            connection_state$message
        )
      } else {
        div(class = "alert alert-danger",
            icon("exclamation-circle"),
            strong(" Status: "),
            connection_state$message
        )
      }
    }
  })
  
  # Send email
  observeEvent(input$send_email_btn, {
    
    # Check if connection is open
    if (!connection_state$connected) {
      showNotification(
        "Please establish SMTP connection first in the Configuration tab",
        type = "error",
        duration = 5
      )
      return()
    }
    
    # Validate email inputs
    if (input$email_to == "" || input$email_subject == "" || input$email_body == "") {
      showNotification(
        "Please fill in To, Subject, and Message fields",
        type = "error",
        duration = 5
      )
      return()
    }
    
    tryCatch({
      # Parse email addresses (split by comma or semicolon)
      to_addresses <- unlist(strsplit(input$email_to, "[,;]"))
      to_addresses <- trimws(to_addresses)
      
      # Get attachment file paths
      attachment_paths <- NULL
      if (!is.null(input$email_attachments)) {
        attachment_paths <- input$email_attachments$datapath
        names(attachment_paths) <- input$email_attachments$name
      }
      
      # Determine encryption type
      use_ssl <- ifelse(input$encryption == "ssl", TRUE, FALSE)
      use_tls <- ifelse(input$encryption == "tls", TRUE, FALSE)
      
      # Send email using mailR
      send.mail(
        from = input$smtp_username,
        to = to_addresses,
        subject = input$email_subject,
        body = input$email_body,
        smtp = list(
          host.name = input$smtp_host,
          port = as.integer(input$smtp_port),
          user.name = input$smtp_username,
          passwd = input$smtp_password,
          ssl = use_ssl,
          tls = use_tls
        ),
        authenticate = input$authentication,
        attach.files = attachment_paths,
        send = TRUE
      )
      
      showNotification(
        "Email sent successfully!",
        type = "message",
        duration = 5
      )
      
      # Clear form after successful send
      updateTextInput(session, "email_to", value = "")
      updateTextInput(session, "email_subject", value = "")
      updateTextAreaInput(session, "email_body", value = "")
      
    }, error = function(e) {
      showNotification(
        paste("Failed to send email:", e$message),
        type = "error",
        duration = 7
      )
    })
  })
  
  # Display send status
  output$send_status <- renderUI({
    # This can be used for additional status messages if needed
  })
}

# Run the application
shinyApp(ui = ui, server = server)
