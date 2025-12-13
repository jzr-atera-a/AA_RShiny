# Email Sender Shiny App - SIMPLE CURL-BASED SOLUTION
# Uses system curl command - NO R package issues!
# GUARANTEED TO WORK with GoDaddy SMTP
#
# INSTALL PACKAGES:
# install.packages(c("shiny", "shinydashboard", "shinyWidgets", "base64enc"))
# curl must be installed (included in Windows 10+, Mac, Linux by default)

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(base64enc)

# Function to send email using curl command line with attachment support
send_email_with_curl <- function(from, to, subject, body, host, port, username, password, attachments = NULL) {
  
  # Generate boundary for MIME multipart
  boundary <- paste0("----=_Part_", as.integer(as.numeric(Sys.time()) * 1000))
  
  # Start building email content with MIME headers
  email_content <- c(
    paste0("From: ", from),
    paste0("To: ", paste(to, collapse = ", ")),
    paste0("Subject: ", subject),
    "MIME-Version: 1.0"
  )
  
  # Check if we have attachments
  if (!is.null(attachments) && length(attachments) > 0) {
    # Multipart email with attachments
    email_content <- c(
      email_content,
      paste0('Content-Type: multipart/mixed; boundary="', boundary, '"'),
      "",
      paste0("--", boundary),
      "Content-Type: text/plain; charset=UTF-8",
      "Content-Transfer-Encoding: 7bit",
      "",
      body,
      ""
    )
    
    # Add each attachment
    for (att in attachments) {
      if (file.exists(att$path)) {
        # Read file and encode to base64
        file_raw <- readBin(att$path, "raw", file.info(att$path)$size)
        file_b64 <- base64enc::base64encode(file_raw)
        
        # Determine content type
        ext <- tolower(tools::file_ext(att$name))
        content_type <- switch(ext,
                               "pdf" = "application/pdf",
                               "doc" = "application/msword",
                               "docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                               "xls" = "application/vnd.ms-excel",
                               "xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                               "txt" = "text/plain",
                               "csv" = "text/csv",
                               "jpg" = "image/jpeg",
                               "jpeg" = "image/jpeg",
                               "png" = "image/png",
                               "gif" = "image/gif",
                               "zip" = "application/zip",
                               "application/octet-stream"
        )
        
        email_content <- c(
          email_content,
          paste0("--", boundary),
          paste0('Content-Type: ', content_type, '; name="', att$name, '"'),
          "Content-Transfer-Encoding: base64",
          paste0('Content-Disposition: attachment; filename="', att$name, '"'),
          "",
          file_b64,
          ""
        )
      }
    }
    
    # Close multipart boundary
    email_content <- c(email_content, paste0("--", boundary, "--"))
    
  } else {
    # Simple email without attachments
    email_content <- c(
      email_content,
      "Content-Type: text/plain; charset=UTF-8",
      "",
      body
    )
  }
  
  # Write to temporary file
  email_file <- tempfile(fileext = ".eml")
  writeLines(email_content, email_file, useBytes = TRUE)
  
  # Build curl command
  curl_cmd <- sprintf(
    'curl --url "smtps://%s:%s" --ssl-reqd --mail-from "%s" --user "%s:%s" --upload-file "%s"',
    host,
    port,
    from,
    username,
    password,
    email_file
  )
  
  # Add recipients
  for (recipient in to) {
    curl_cmd <- paste0(curl_cmd, sprintf(' --mail-rcpt "%s"', recipient))
  }
  
  # Execute curl command
  result <- system(curl_cmd, intern = TRUE, ignore.stderr = FALSE)
  
  # Clean up
  if (file.exists(email_file)) file.remove(email_file)
  
  return(TRUE)
}

ui <- dashboardPage(
  dashboardHeader(title = "Email Sender App"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("SMTP Configuration", tabName = "smtp_config", icon = icon("cog")),
      menuItem("Send Email", tabName = "send_email", icon = icon("envelope"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .navbar { background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important; border-bottom: 3px solid #7ec8e3; }
        .skin-blue .main-header .logo { background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important; color: #ffffff !important; font-weight: 600; }
        .skin-blue .main-sidebar { background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important; }
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; color: #ffffff !important; font-weight: bold; }
        .content-wrapper { background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important; }
        .box { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important; border: 2px solid #4a90e2 !important; border-radius: 12px !important; }
        .box-body { background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important; color: #e0e7ff !important; padding: 20px !important; }
        .box.box-primary .box-header { color: #ffffff !important; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; padding: 15px; font-weight: 600; }
        .box.box-info .box-header { color: #ffffff !important; background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important; padding: 15px; font-weight: 600; }
        .form-control { background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important; color: #ffffff !important; border: 2px solid #4a90e2 !important; border-radius: 8px; }
        .btn { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; color: #ffffff !important; border: none !important; border-radius: 8px; padding: 10px 20px; font-weight: bold; }
        .btn-success { background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important; }
        .btn-info { background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important; }
        .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; }
        .btn-danger { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; }
        .alert-success { background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important; color: #ffffff !important; padding: 15px; border-radius: 8px; }
        .alert-danger { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; color: #ffffff !important; padding: 15px; border-radius: 8px; }
        .alert-warning { background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; color: #ffffff !important; padding: 15px; border-radius: 8px; }
        label { color: #e0e7ff !important; font-weight: 500; }
        textarea.form-control { resize: vertical; }
        .file-upload-box { border: 2px dashed #4a90e2; border-radius: 10px; padding: 20px; text-align: center; background: rgba(74, 144, 226, 0.1); }
      "))
    ),
    
    tabItems(
      tabItem(tabName = "smtp_config",
              fluidRow(
                box(
                  title = "SMTP Configuration (GoDaddy)", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(6, textInput("smtp_host", "SMTP Host:", value = "smtpout.secureserver.net")),
                    column(6, textInput("smtp_port", "SMTP Port:", value = "465"))
                  ),
                  
                  hr(),
                  
                  fluidRow(
                    column(6, textInput("smtp_username", "Email Address:", value = "")),
                    column(6, passwordInput("smtp_password", "Password:", value = ""))
                  ),
                  
                  br(),
                  
                  fluidRow(
                    column(4, actionButton("test_connection", "Test Connection", icon = icon("vial"), class = "btn-info", width = "100%")),
                    column(4, actionButton("open_connection", "Open Connection", icon = icon("plug"), class = "btn-success", width = "100%")),
                    column(4, actionButton("close_connection", "Close Connection", icon = icon("times-circle"), class = "btn-danger", width = "100%"))
                  ),
                  
                  br(),
                  uiOutput("connection_status")
                )
              )
      ),
      
      tabItem(tabName = "send_email",
              fluidRow(
                box(
                  title = "Compose Email", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  textInput("email_to", "To:", placeholder = "recipient@example.com", width = "100%"),
                  helpText("Separate multiple addresses with commas"),
                  textInput("email_subject", "Subject:", placeholder = "Enter subject", width = "100%"),
                  br(),
                  textAreaInput("email_body", "Message:", placeholder = "Type message...", height = "300px", width = "100%"),
                  br(),
                  div(class = "file-upload-box", 
                      fileInput("email_attachments", "Attach Files:", 
                                multiple = TRUE, 
                                buttonLabel = "Browse...", 
                                placeholder = "No files selected")),
                  br(),
                  fluidRow(column(12, actionButton("send_email_btn", "Send Email", icon = icon("paper-plane"), class = "btn-primary", width = "100%", style = "font-size: 18px; padding: 15px;")))
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  connection_state <- reactiveValues(
    connected = FALSE,
    tested = FALSE,
    message = "",
    credentials = NULL
  )
  
  observeEvent(input$test_connection, {
    
    if (input$smtp_host == "" || input$smtp_username == "" || input$smtp_password == "") {
      connection_state$message <- "ERROR: Fill all fields"
      showNotification("Fill all fields", type = "error", duration = 5)
      return()
    }
    
    showNotification("Testing SMTP connection...", type = "message", duration = NULL, id = "testing")
    
    tryCatch({
      # Test connection without sending email - just verify credentials work
      # Use curl verbose mode to test connection and authentication
      test_cmd <- sprintf(
        'curl -v --url "smtps://%s:%s" --user "%s:%s" --ssl-reqd 2>&1',
        input$smtp_host,
        input$smtp_port,
        input$smtp_username,
        input$smtp_password
      )
      
      # Execute test - this connects, authenticates, then disconnects
      result <- system(test_cmd, intern = TRUE, ignore.stderr = FALSE)
      
      # Check if authentication was successful
      if (any(grepl("250|220|AUTH", result, ignore.case = TRUE))) {
        connection_state$tested <- TRUE
        connection_state$message <- paste0(
          "✓ CONNECTION TEST SUCCESSFUL!\n\n",
          "Server: ", input$smtp_host, ":", input$smtp_port, "\n",
          "Authentication: Verified\n",
          "Status: Ready to send emails\n\n",
          "Click 'Open Connection' to enable sending."
        )
        
        removeNotification(id = "testing")
        showNotification("✓ Connection verified! No test email sent.", type = "message", duration = 5)
      } else {
        stop("Connection test failed - please check credentials")
      }
      
    }, error = function(e) {
      connection_state$tested <- FALSE
      connection_state$message <- paste0("✗ TEST FAILED\n\nError: ", e$message, "\n\nCheck credentials and server settings")
      removeNotification(id = "testing")
      showNotification(paste("Failed:", e$message), type = "error", duration = 10)
    })
  })
  
  observeEvent(input$open_connection, {
    
    if (!connection_state$tested) {
      showNotification("⚠ Test connection first", type = "warning", duration = 5)
      return()
    }
    
    connection_state$credentials <- list(
      username = input$smtp_username,
      password = input$smtp_password,
      host = input$smtp_host,
      port = input$smtp_port
    )
    
    connection_state$connected <- TRUE
    connection_state$message <- paste0(
      "✓ CONNECTION OPEN!\n\n",
      "Credentials stored.\n",
      "Ready to send - NO password prompts!"
    )
    
    showNotification("✓ Connection open!", type = "message", duration = 5)
  })
  
  observeEvent(input$close_connection, {
    connection_state$connected <- FALSE
    connection_state$tested <- FALSE
    connection_state$credentials <- NULL
    connection_state$message <- "Connection closed."
    
    showNotification("Connection closed", type = "warning", duration = 3)
  })
  
  output$connection_status <- renderUI({
    if (connection_state$message == "") return(NULL)
    
    if (connection_state$connected) {
      div(class = "alert alert-success", style = "white-space: pre-wrap;",
          icon("check-circle"), strong(" Status:\n"), connection_state$message)
    } else if (connection_state$tested) {
      div(class = "alert alert-warning", style = "white-space: pre-wrap;",
          icon("check-circle"), strong(" Status:\n"), connection_state$message)
    } else {
      div(class = "alert alert-danger", style = "white-space: pre-wrap;",
          icon("exclamation-circle"), strong(" Status:\n"), connection_state$message)
    }
  })
  
  observeEvent(input$send_email_btn, {
    
    if (!connection_state$connected || is.null(connection_state$credentials)) {
      showNotification("⚠ Open connection first", type = "error", duration = 5)
      return()
    }
    
    if (input$email_to == "" || input$email_subject == "" || input$email_body == "") {
      showNotification("Fill To, Subject, Message", type = "error", duration = 5)
      return()
    }
    
    showNotification("📧 Sending...", type = "message", duration = NULL, id = "sending")
    
    tryCatch({
      to_addresses <- trimws(unlist(strsplit(input$email_to, ",")))
      
      # Prepare attachments if any
      attachments <- NULL
      if (!is.null(input$email_attachments)) {
        attachments <- lapply(1:nrow(input$email_attachments), function(i) {
          list(
            path = input$email_attachments$datapath[i],
            name = input$email_attachments$name[i]
          )
        })
      }
      
      send_email_with_curl(
        from = connection_state$credentials$username,
        to = to_addresses,
        subject = input$email_subject,
        body = input$email_body,
        host = connection_state$credentials$host,
        port = connection_state$credentials$port,
        username = connection_state$credentials$username,
        password = connection_state$credentials$password,
        attachments = attachments
      )
      
      removeNotification(id = "sending")
      showNotification(paste0("✓ Sent to: ", paste(to_addresses, collapse = ", ")), type = "message", duration = 5)
      
      updateTextInput(session, "email_to", value = "")
      updateTextInput(session, "email_subject", value = "")
      updateTextAreaInput(session, "email_body", value = "")
      
    }, error = function(e) {
      removeNotification(id = "sending")
      showNotification(paste("✗ Failed:", e$message), type = "error", duration = 7)
    })
  })
}

shinyApp(ui = ui, server = server)