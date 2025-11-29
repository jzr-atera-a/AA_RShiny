library(shiny)
library(shinydashboard)
library(readxl)
library(DT)
library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)
library(blastula)
library(writexl)

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Gantt to Tickets Converter"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("API Configuration", tabName = "config", icon = icon("key")),
      menuItem("Email Configuration", tabName = "email_config", icon = icon("envelope")),
      menuItem("Upload Gantt Chart", tabName = "upload", icon = icon("upload")),
      menuItem("Review & Edit Tasks", tabName = "review", icon = icon("tasks")),
      menuItem("Submit to Boards", tabName = "submit", icon = icon("paper-plane")),
      menuItem("Send Email Notifications", tabName = "email_send", icon = icon("mail-bulk")),
      menuItem("Manage Contacts", tabName = "contacts", icon = icon("address-book")),
      menuItem("Email Contacts", tabName = "email_contacts", icon = icon("paper-plane"))
    )
  ),
  
  dashboardBody(
    tabItems(
      # Tab 1: API Configuration
      tabItem(tabName = "config",
              fluidRow(
                box(
                  title = "Trello API Credentials", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 6,
                  textInput("trello_key", "API Key:", ""),
                  textInput("trello_token", "API Token:", ""),
                  textInput("trello_board_id", "Board ID (optional):", ""),
                  actionButton("test_trello", "Test Connection", class = "btn-success"),
                  br(), br(),
                  textOutput("trello_status")
                ),
                box(
                  title = "Jira API Credentials", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 6,
                  textInput("jira_url", "Jira URL:", placeholder = "https://your-domain.atlassian.net"),
                  textInput("jira_email", "Email:", ""),
                  passwordInput("jira_token", "API Token:", ""),
                  textInput("jira_project_key", "Project Key:", placeholder = "PROJ"),
                  actionButton("test_jira", "Test Connection", class = "btn-success"),
                  br(), br(),
                  textOutput("jira_status")
                )
              ),
              fluidRow(
                box(
                  title = "Instructions",
                  status = "warning",
                  width = 12,
                  HTML("<h4>How to get your API credentials:</h4>
                       <p><strong>Trello:</strong></p>
                       <ul>
                         <li>API Key: Visit <a href='https://trello.com/app-key' target='_blank'>https://trello.com/app-key</a></li>
                         <li>Token: Click on 'Token' link on the same page and authorize</li>
                         <li>Board ID: Open your board, it's in the URL: trello.com/b/<strong>BOARD_ID</strong>/board-name</li>
                       </ul>
                       <p><strong>Jira:</strong></p>
                       <ul>
                         <li>URL: Your Jira instance URL (e.g., https://yourcompany.atlassian.net)</li>
                         <li>Email: Your Jira account email</li>
                         <li>API Token: Go to <a href='https://id.atlassian.com/manage-profile/security/api-tokens' target='_blank'>Atlassian Account Settings</a> > Security > Create API token</li>
                         <li>Project Key: The short code for your project (visible in project settings)</li>
                       </ul>")
                )
              )
      ),
      
      # Tab 2: Email Configuration
      tabItem(tabName = "email_config",
              fluidRow(
                box(
                  title = "SMTP Email Configuration", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  p("Configure your email settings to send task notifications directly to team members."),
                  hr(),
                  selectInput("email_provider", "Email Provider:",
                              choices = c("Gmail", "Outlook/Office365", "Custom SMTP")),
                  textInput("smtp_server", "SMTP Server:", 
                            placeholder = "smtp.gmail.com"),
                  numericInput("smtp_port", "SMTP Port:", 
                               value = 587, min = 1, max = 65535),
                  textInput("smtp_username", "Email Address:", 
                            placeholder = "your.email@example.com"),
                  passwordInput("smtp_password", "Password/App Password:", ""),
                  checkboxInput("use_ssl", "Use SSL/TLS", value = TRUE),
                  actionButton("test_email", "Test Email Connection", 
                               class = "btn-success"),
                  br(), br(),
                  textOutput("email_status")
                )
              ),
              fluidRow(
                box(
                  title = "Email Template Settings",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  textInput("email_subject_template", "Email Subject Template:",
                            value = "New Task Assignment: {Task_Name}",
                            placeholder = "Use {Task_Name} for dynamic content"),
                  textAreaInput("email_body_template", "Email Body Template:",
                                value = "Hello {Assignee},\n\nYou have been assigned a new task:\n\nTask: {Task_Name}\nDescription: {Description}\nStart Date: {Start_Date}\nEnd Date: {End_Date}\nPriority: {Priority}\n\nPlease review and confirm.\n\nBest regards",
                                rows = 10),
                  p("Available placeholders: {Task_Name}, {Description}, {Start_Date}, {End_Date}, {Duration_Days}, {Assignee}, {Priority}, {Status}, {Labels}")
                )
              ),
              fluidRow(
                box(
                  title = "Gmail & Outlook Instructions",
                  status = "warning",
                  width = 12,
                  HTML("<h4>How to configure email:</h4>
                       <p><strong>Gmail:</strong></p>
                       <ul>
                         <li>SMTP Server: smtp.gmail.com</li>
                         <li>Port: 587 (TLS) or 465 (SSL)</li>
                         <li>Enable 2-factor authentication on your Google account</li>
                         <li>Generate an App Password: <a href='https://myaccount.google.com/apppasswords' target='_blank'>Google App Passwords</a></li>
                         <li>Use the App Password (not your regular password)</li>
                       </ul>
                       <p><strong>Outlook/Office365:</strong></p>
                       <ul>
                         <li>SMTP Server: smtp-mail.outlook.com or smtp.office365.com</li>
                         <li>Port: 587</li>
                         <li>Use your regular Outlook password</li>
                         <li>May require app-specific password if using 2FA</li>
                       </ul>
                       <p><strong>Custom SMTP:</strong></p>
                       <ul>
                         <li>Contact your email provider for SMTP settings</li>
                         <li>Common ports: 25, 465 (SSL), 587 (TLS), 2525</li>
                       </ul>")
                )
              )
      ),
      
      # Tab 3: Upload Gantt Chart
      tabItem(tabName = "upload",
              fluidRow(
                box(
                  title = "Upload Excel File",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  fileInput("gantt_file", "Choose Excel File (.xlsx or .xls)",
                            accept = c(".xlsx", ".xls")),
                  hr(),
                  h4("Expected Excel Format:"),
                  p("Your Excel file should contain the following columns:"),
                  tags$ul(
                    tags$li(tags$strong("Task_Name"), " - Name of the task (required)"),
                    tags$li(tags$strong("Description"), " - Detailed description of the task (optional)"),
                    tags$li(tags$strong("Start_Date"), " - Start date (format: YYYY-MM-DD or MM/DD/YYYY)"),
                    tags$li(tags$strong("End_Date"), " - End date (format: YYYY-MM-DD or MM/DD/YYYY)"),
                    tags$li(tags$strong("Duration_Days"), " - Duration in days (optional if dates provided)"),
                    tags$li(tags$strong("Assignee"), " - Person assigned to task (optional)"),
                    tags$li(tags$strong("Priority"), " - High/Medium/Low (optional)"),
                    tags$li(tags$strong("Status"), " - To Do/In Progress/Done (optional)"),
                    tags$li(tags$strong("Labels"), " - Comma-separated tags (optional)")
                  ),
                  downloadButton("download_template", "Download Excel Template")
                )
              ),
              fluidRow(
                box(
                  title = "Preview Uploaded Data",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("preview_table")
                )
              )
      ),
      
      # Tab 4: Review & Edit Tasks
      tabItem(tabName = "review",
              fluidRow(
                box(
                  title = "Task List - Edit as Needed",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("editable_table"),
                  br(),
                  actionButton("refresh_table", "Refresh Table", icon = icon("refresh"))
                )
              ),
              fluidRow(
                box(
                  title = "Add Additional Information",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  selectInput("select_task", "Select Task:", choices = NULL),
                  textAreaInput("additional_notes", "Additional Notes:", rows = 3),
                  textInput("additional_labels", "Add Labels (comma-separated):", ""),
                  actionButton("update_task", "Update Task", class = "btn-primary")
                )
              )
      ),
      
      # Tab 5: Submit to Boards
      tabItem(tabName = "submit",
              fluidRow(
                box(
                  title = "Submit to Trello",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  selectInput("trello_list", "Select Trello List:", choices = NULL),
                  actionButton("load_trello_lists", "Load Lists from Board", class = "btn-info"),
                  br(), br(),
                  actionButton("submit_trello", "Submit to Trello", 
                               class = "btn-success btn-lg", 
                               icon = icon("trello")),
                  br(), br(),
                  verbatimTextOutput("trello_result")
                ),
                box(
                  title = "Submit to Jira",
                  status = "info",
                  solidHeader = TRUE,
                  width = 6,
                  selectInput("jira_issue_type", "Issue Type:", 
                              choices = c("Task", "Story", "Bug", "Epic")),
                  actionButton("submit_jira", "Submit to Jira", 
                               class = "btn-success btn-lg",
                               icon = icon("jira")),
                  br(), br(),
                  verbatimTextOutput("jira_result")
                )
              ),
              fluidRow(
                box(
                  title = "Submission Summary",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  verbatimTextOutput("submission_summary")
                )
              )
      ),
      
      # Tab 6: Send Email Notifications
      tabItem(tabName = "email_send",
              fluidRow(
                box(
                  title = "Email Assignment Notifications",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  p("Send personalized email notifications to assignees for their tasks."),
                  p(strong("Note:"), "This will send individual emails to each assignee with their assigned tasks.")
                )
              ),
              fluidRow(
                box(
                  title = "Preview Emails",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("email_preview_table"),
                  br(),
                  p(strong("Summary:")),
                  verbatimTextOutput("email_summary")
                )
              ),
              fluidRow(
                box(
                  title = "Email Options",
                  status = "warning",
                  solidHeader = TRUE,
                  width = 6,
                  checkboxInput("group_by_assignee", 
                                "Group tasks by assignee (one email per person)", 
                                value = TRUE),
                  checkboxInput("include_attachments", 
                                "Include task list as CSV attachment", 
                                value = FALSE),
                  textInput("cc_emails", "CC (comma-separated):", 
                            placeholder = "manager@example.com, pm@example.com")
                ),
                box(
                  title = "Send Emails",
                  status = "success",
                  solidHeader = TRUE,
                  width = 6,
                  actionButton("send_emails", "Send All Emails", 
                               class = "btn-success btn-lg btn-block",
                               icon = icon("paper-plane")),
                  br(),
                  actionButton("send_test_email", "Send Test Email to Myself", 
                               class = "btn-info btn-block"),
                  br(),
                  verbatimTextOutput("email_send_result")
                )
              )
      ),
      
      # Tab 7: Manage Contacts
      tabItem(tabName = "contacts",
              fluidRow(
                box(
                  title = "Add New Contact",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  fluidRow(
                    column(4,
                           textInput("contact_country", "Country:", placeholder = "USA"),
                           textInput("contact_city", "City:", placeholder = "New York"),
                           textInput("contact_org", "Organization:", placeholder = "Acme Corp")
                    ),
                    column(4,
                           textInput("contact_name", "Full Name:", placeholder = "John Doe"),
                           textInput("contact_email", "Email:", placeholder = "john@example.com"),
                           textInput("contact_phone", "Phone Number:", placeholder = "+1-555-0123")
                    ),
                    column(4,
                           textInput("contact_linkedin", "LinkedIn Profile:", 
                                     placeholder = "https://linkedin.com/in/johndoe"),
                           br(),
                           actionButton("add_contact", "Add Contact", 
                                        class = "btn-success btn-lg btn-block",
                                        icon = icon("plus")),
                           br(),
                           actionButton("clear_contact_form", "Clear Form", 
                                        class = "btn-warning btn-block")
                    )
                  ),
                  hr(),
                  textOutput("contact_add_status")
                )
              ),
              fluidRow(
                box(
                  title = "Contacts Database",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  fluidRow(
                    column(3,
                           actionButton("refresh_contacts", "Refresh List", 
                                        icon = icon("sync"),
                                        class = "btn-info btn-block")
                    ),
                    column(3,
                           downloadButton("download_contacts", "Download Excel", 
                                          class = "btn-success btn-block")
                    ),
                    column(3,
                           fileInput("upload_contacts", "Upload Contacts File",
                                     accept = c(".xlsx", ".xls"))
                    ),
                    column(3,
                           actionButton("clear_all_contacts", "Clear All", 
                                        class = "btn-danger btn-block",
                                        icon = icon("trash"))
                    )
                  ),
                  hr(),
                  DTOutput("contacts_table"),
                  br(),
                  textOutput("contacts_count")
                )
              )
      ),
      
      # Tab 8: Email Contacts
      tabItem(tabName = "email_contacts",
              fluidRow(
                box(
                  title = "Filter Contacts",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  fluidRow(
                    column(3,
                           selectInput("filter_country", "Filter by Country:",
                                       choices = c("All" = ""), multiple = FALSE)
                    ),
                    column(3,
                           selectInput("filter_city", "Filter by City:",
                                       choices = c("All" = ""), multiple = FALSE)
                    ),
                    column(3,
                           selectInput("filter_org", "Filter by Organization:",
                                       choices = c("All" = ""), multiple = FALSE)
                    ),
                    column(3,
                           br(),
                           actionButton("apply_filters", "Apply Filters", 
                                        class = "btn-primary btn-block",
                                        icon = icon("filter"))
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Select Recipients",
                  status = "info",
                  solidHeader = TRUE,
                  width = 12,
                  DTOutput("filtered_contacts_table"),
                  br(),
                  fluidRow(
                    column(6,
                           actionButton("select_all_contacts", "Select All", 
                                        class = "btn-info")
                    ),
                    column(6,
                           actionButton("deselect_all_contacts", "Deselect All", 
                                        class = "btn-warning")
                    )
                  ),
                  br(),
                  textOutput("selected_contacts_count")
                )
              ),
              fluidRow(
                box(
                  title = "Compose Email",
                  status = "success",
                  solidHeader = TRUE,
                  width = 12,
                  textInput("contact_email_subject", "Email Subject:", 
                            placeholder = "Subject line here",
                            width = "100%"),
                  textAreaInput("contact_email_body", "Email Body:", 
                                placeholder = "Type your message here...",
                                rows = 10,
                                width = "100%"),
                  hr(),
                  fluidRow(
                    column(6,
                           checkboxInput("include_contact_name", "Personalize with name (use {NAME} in body)", 
                                         value = TRUE)
                    ),
                    column(6,
                           checkboxInput("include_org_name", "Include organization (use {ORG} in body)", 
                                         value = FALSE)
                    )
                  ),
                  hr(),
                  actionButton("send_contact_emails", "Send Emails to Selected Contacts", 
                               class = "btn-success btn-lg btn-block",
                               icon = icon("paper-plane")),
                  br(),
                  verbatimTextOutput("contact_email_results")
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store data
  values <- reactiveValues(
    gantt_data = NULL,
    trello_connected = FALSE,
    jira_connected = FALSE,
    email_connected = FALSE,
    smtp_config = list(),
    contacts_data = NULL,
    contacts_file = "contacts_database.xlsx",
    filtered_contacts = NULL,
    selected_contact_rows = c()
  )
  
  # Update SMTP settings based on provider selection
  observeEvent(input$email_provider, {
    if (input$email_provider == "Gmail") {
      updateTextInput(session, "smtp_server", value = "smtp.gmail.com")
      updateNumericInput(session, "smtp_port", value = 587)
      updateCheckboxInput(session, "use_ssl", value = TRUE)
    } else if (input$email_provider == "Outlook/Office365") {
      updateTextInput(session, "smtp_server", value = "smtp-mail.outlook.com")
      updateNumericInput(session, "smtp_port", value = 587)
      updateCheckboxInput(session, "use_ssl", value = TRUE)
    }
  })
  
  # Test Email Connection
  observeEvent(input$test_email, {
    req(input$smtp_server, input$smtp_port, input$smtp_username, input$smtp_password)
    
    tryCatch({
      # Store SMTP config
      values$smtp_config <- list(
        host = input$smtp_server,
        port = input$smtp_port,
        user = input$smtp_username,
        password = input$smtp_password,
        ssl = input$use_ssl
      )
      
      # Create SMTP credentials
      smtp_creds <- creds(
        user = input$smtp_username,
        password = input$smtp_password,
        host = input$smtp_server,
        port = input$smtp_port,
        use_ssl = input$use_ssl
      )
      
      # Send test email
      test_email <- compose_email(
        body = md("
# Test Email

This is a test email from the **Gantt to Tickets Converter** app.

Your email configuration is working correctly!

**Configuration Details:**
- Server: {input$smtp_server}
- Port: {input$smtp_port}
- SSL: {input$use_ssl}
        ")
      )
      
      test_email %>%
        smtp_send(
          to = input$smtp_username,
          from = input$smtp_username,
          subject = "Test Email - Gantt to Tickets App",
          credentials = smtp_creds
        )
      
      values$email_connected <- TRUE
      output$email_status <- renderText({
        "✓ Email configuration successful! Test email sent to your address."
      })
      
      showNotification("Test email sent successfully!", type = "message")
      
    }, error = function(e) {
      values$email_connected <- FALSE
      output$email_status <- renderText({
        paste("✗ Email configuration failed:", e$message)
      })
      showNotification(paste("Email test failed:", e$message), type = "error")
    })
  })
  
  # Test Trello Connection
  observeEvent(input$test_trello, {
    tryCatch({
      response <- GET(
        url = "https://api.trello.com/1/members/me",
        query = list(
          key = input$trello_key,
          token = input$trello_token
        )
      )
      
      if (status_code(response) == 200) {
        user_data <- content(response)
        values$trello_connected <- TRUE
        output$trello_status <- renderText({
          paste("✓ Connected as:", user_data$fullName)
        })
      } else {
        output$trello_status <- renderText({
          paste("✗ Connection failed:", status_code(response))
        })
      }
    }, error = function(e) {
      output$trello_status <- renderText({
        paste("✗ Error:", e$message)
      })
    })
  })
  
  # Test Jira Connection
  observeEvent(input$test_jira, {
    tryCatch({
      auth_string <- paste0(input$jira_email, ":", input$jira_token)
      auth_encoded <- openssl::base64_encode(charToRaw(auth_string))
      
      response <- GET(
        url = paste0(input$jira_url, "/rest/api/3/myself"),
        add_headers(
          Authorization = paste("Basic", auth_encoded),
          "Content-Type" = "application/json"
        )
      )
      
      if (status_code(response) == 200) {
        user_data <- content(response)
        values$jira_connected <- TRUE
        output$jira_status <- renderText({
          paste("✓ Connected as:", user_data$displayName)
        })
      } else {
        output$jira_status <- renderText({
          paste("✗ Connection failed:", status_code(response))
        })
      }
    }, error = function(e) {
      output$jira_status <- renderText({
        paste("✗ Error:", e$message)
      })
    })
  })
  
  # Download Excel Template
  output$download_template <- downloadHandler(
    filename = function() {
      paste("gantt_template_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      # Create sample template
      template_data <- data.frame(
        Task_Name = c("Project Setup", "Research Phase", "Development Sprint 1", "Testing", "Deployment"),
        Description = c(
          "Initial project configuration and setup",
          "Market research and requirements gathering",
          "Core feature development",
          "QA testing and bug fixes",
          "Production deployment"
        ),
        Start_Date = c("2025-01-15", "2025-01-20", "2025-02-01", "2025-02-20", "2025-03-01"),
        End_Date = c("2025-01-19", "2025-01-31", "2025-02-19", "2025-02-28", "2025-03-05"),
        Duration_Days = c(5, 12, 19, 9, 5),
        Assignee = c("John Doe", "Jane Smith", "Dev Team", "QA Team", "DevOps"),
        Priority = c("High", "High", "Medium", "High", "High"),
        Status = c("To Do", "To Do", "To Do", "To Do", "To Do"),
        Labels = c("setup,planning", "research", "development,sprint", "testing,qa", "deployment,production"),
        stringsAsFactors = FALSE
      )
      writexl::write_xlsx(template_data, file)
    }
  )
  
  # Load and preview Gantt data
  observeEvent(input$gantt_file, {
    req(input$gantt_file)
    
    tryCatch({
      values$gantt_data <- read_excel(input$gantt_file$datapath)
      
      # Standardize column names
      names(values$gantt_data) <- gsub(" ", "_", names(values$gantt_data))
      
      output$preview_table <- renderDT({
        datatable(values$gantt_data, 
                  options = list(scrollX = TRUE, pageLength = 10))
      })
      
      # Update task selector
      updateSelectInput(session, "select_task", 
                        choices = values$gantt_data$Task_Name)
      
    }, error = function(e) {
      showNotification(paste("Error reading file:", e$message), type = "error")
    })
  })
  
  # Render editable table
  output$editable_table <- renderDT({
    req(values$gantt_data)
    datatable(
      values$gantt_data,
      editable = TRUE,
      options = list(scrollX = TRUE, pageLength = 15)
    )
  })
  
  # Handle table edits
  observeEvent(input$editable_table_cell_edit, {
    info <- input$editable_table_cell_edit
    values$gantt_data[info$row, info$col] <- info$value
  })
  
  # Update selected task with additional info
  observeEvent(input$update_task, {
    req(values$gantt_data, input$select_task)
    
    row_idx <- which(values$gantt_data$Task_Name == input$select_task)
    
    if (length(row_idx) > 0) {
      # Add or update additional notes
      if (!"Additional_Notes" %in% names(values$gantt_data)) {
        values$gantt_data$Additional_Notes <- NA
      }
      values$gantt_data$Additional_Notes[row_idx] <- input$additional_notes
      
      # Append labels
      if (input$additional_labels != "") {
        current_labels <- values$gantt_data$Labels[row_idx]
        if (is.na(current_labels) || current_labels == "") {
          values$gantt_data$Labels[row_idx] <- input$additional_labels
        } else {
          values$gantt_data$Labels[row_idx] <- paste(current_labels, 
                                                     input$additional_labels, 
                                                     sep = ",")
        }
      }
      
      showNotification("Task updated successfully!", type = "message")
    }
  })
  
  # Load Trello Lists
  # Load Trello Lists
  observeEvent(input$load_trello_lists, {
    req(input$trello_key, input$trello_token, input$trello_board_id)
    
    tryCatch({
      url <- paste0("https://api.trello.com/1/boards/", input$trello_board_id, "/lists")
      
      response <- GET(
        url = url,
        query = list(
          key = input$trello_key,
          token = input$trello_token
        )
      )
      
      print(paste("URL:", url))
      print(paste("Status:", status_code(response)))
      
      if (status_code(response) == 200) {
        lists <- content(response)
        
        # Debug: Print raw response
        print("Raw lists response:")
        print(str(lists))
        
        if (length(lists) == 0) {
          showNotification("Board has no lists. Create lists in Trello first.", type = "warning")
          return()
        }
        
        # Create choices
        list_choices <- setNames(
          sapply(lists, function(x) as.character(x$id)),
          sapply(lists, function(x) as.character(x$name))
        )
        
        print("List choices:")
        print(list_choices)
        
        # Update dropdown
        updateSelectInput(session, "trello_list", 
                          choices = list_choices)
        
        showNotification(paste("Loaded", length(list_choices), "lists"), type = "message")
        
      } else {
        error_content <- content(response, as = "text")
        print(paste("Error response:", error_content))
        showNotification(paste("API Error:", status_code(response)), type = "error")
      }
      
    }, error = function(e) {
      print(paste("Exception:", e$message))
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Submit to Trello
  observeEvent(input$submit_trello, {
    req(values$gantt_data, input$trello_key, input$trello_token, input$trello_list)
    
    results <- c()
    
    withProgress(message = 'Submitting to Trello...', value = 0, {
      for (i in 1:nrow(values$gantt_data)) {
        task <- values$gantt_data[i, ]
        
        # Build description
        desc_parts <- c()
        if (!is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
        if (!is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start:", task$Start_Date))
        if (!is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End:", task$End_Date))
        if (!is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
        if ("Additional_Notes" %in% names(task) && !is.na(task$Additional_Notes)) {
          desc_parts <- c(desc_parts, paste("\nNotes:", task$Additional_Notes))
        }
        
        description <- paste(desc_parts, collapse = "\n")
        
        # Create card
        response <- POST(
          url = "https://api.trello.com/1/cards",
          query = list(
            key = input$trello_key,
            token = input$trello_token,
            idList = input$trello_list,
            name = task$Task_Name,
            desc = description
          )
        )
        
        if (status_code(response) == 200) {
          results <- c(results, paste("✓", task$Task_Name))
        } else {
          results <- c(results, paste("✗", task$Task_Name, "-", status_code(response)))
        }
        
        incProgress(1/nrow(values$gantt_data))
      }
    })
    
    output$trello_result <- renderText({
      paste(results, collapse = "\n")
    })
    
    showNotification("Submission to Trello complete!", type = "message")
  })
  
  # Submit to Jira
  observeEvent(input$submit_jira, {
    req(values$gantt_data, input$jira_url, input$jira_email, 
        input$jira_token, input$jira_project_key)
    
    results <- c()
    auth_string <- paste0(input$jira_email, ":", input$jira_token)
    auth_encoded <- openssl::base64_encode(charToRaw(auth_string))
    
    withProgress(message = 'Submitting to Jira...', value = 0, {
      for (i in 1:nrow(values$gantt_data)) {
        task <- values$gantt_data[i, ]
        
        # Build description
        desc_parts <- c()
        if (!is.na(task$Description)) desc_parts <- c(desc_parts, task$Description)
        if (!is.na(task$Start_Date)) desc_parts <- c(desc_parts, paste("Start Date:", task$Start_Date))
        if (!is.na(task$End_Date)) desc_parts <- c(desc_parts, paste("End Date:", task$End_Date))
        if (!is.na(task$Duration_Days)) desc_parts <- c(desc_parts, paste("Duration:", task$Duration_Days, "days"))
        if (!is.na(task$Assignee)) desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
        if ("Additional_Notes" %in% names(task) && !is.na(task$Additional_Notes)) {
          desc_parts <- c(desc_parts, paste("\nAdditional Notes:", task$Additional_Notes))
        }
        
        description <- paste(desc_parts, collapse = "\n\n")
        
        # Prepare labels
        labels <- c()
        if (!is.na(task$Labels)) {
          labels <- trimws(strsplit(as.character(task$Labels), ",")[[1]])
        }
        
        # Create issue payload
        issue_data <- list(
          fields = list(
            project = list(key = input$jira_project_key),
            summary = task$Task_Name,
            description = description,
            issuetype = list(name = input$jira_issue_type)
          )
        )
        
        # Add priority if available
        if (!is.na(task$Priority)) {
          issue_data$fields$priority <- list(name = task$Priority)
        }
        
        # Add labels if available
        if (length(labels) > 0) {
          issue_data$fields$labels <- labels
        }
        
        response <- POST(
          url = paste0(input$jira_url, "/rest/api/3/issue"),
          add_headers(
            Authorization = paste("Basic", auth_encoded),
            "Content-Type" = "application/json"
          ),
          body = toJSON(issue_data, auto_unbox = TRUE),
          encode = "json"
        )
        
        if (status_code(response) == 201) {
          issue_key <- content(response)$key
          results <- c(results, paste("✓", task$Task_Name, "-", issue_key))
        } else {
          error_msg <- tryCatch({
            content(response)$errorMessages[[1]]
          }, error = function(e) status_code(response))
          results <- c(results, paste("✗", task$Task_Name, "-", error_msg))
        }
        
        incProgress(1/nrow(values$gantt_data))
      }
    })
    
    output$jira_result <- renderText({
      paste(results, collapse = "\n")
    })
    
    showNotification("Submission to Jira complete!", type = "message")
  })
  
  # Load Trello Lists
  observeEvent(input$load_trello_lists, {
    req(input$trello_key, input$trello_token, input$trello_board_id)
    
    tryCatch({
      response <- GET(
        url = paste0("https://api.trello.com/1/boards/", input$trello_board_id, "/lists"),
        query = list(
          key = input$trello_key,
          token = input$trello_token
        )
      )
      
      if (status_code(response) == 200) {
        lists <- content(response)
        list_names <- sapply(lists, function(x) x$name)
        list_ids <- sapply(lists, function(x) x$id)
        names(list_ids) <- list_names
        
        updateSelectInput(session, "trello_list", choices = list_ids)
        showNotification("Trello lists loaded successfully!", type = "message")
      } else {
        showNotification(paste("Failed to load Trello lists. Status:", status_code(response)), type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error loading lists:", e$message), type = "error")
    })
  })
  
  # Submit to Trello
  observeEvent(input$submit_trello, {
    req(values$gantt_data, input$trello_key, input$trello_token, input$trello_list)
    
    if (is.null(values$gantt_data) || nrow(values$gantt_data) == 0) {
      showNotification("No tasks to submit", type = "warning")
      return()
    }
    
    results <- c()
    
    withProgress(message = 'Submitting to Trello...', value = 0, {
      for (i in 1:nrow(values$gantt_data)) {
        task <- values$gantt_data[i, ]
        
        # Build description
        desc_parts <- c()
        if ("Description" %in% names(task) && !is.na(task$Description)) {
          desc_parts <- c(desc_parts, task$Description)
        }
        if ("Start_Date" %in% names(task) && !is.na(task$Start_Date)) {
          desc_parts <- c(desc_parts, paste("Start:", task$Start_Date))
        }
        if ("End_Date" %in% names(task) && !is.na(task$End_Date)) {
          desc_parts <- c(desc_parts, paste("End:", task$End_Date))
        }
        if ("Assignee" %in% names(task) && !is.na(task$Assignee)) {
          desc_parts <- c(desc_parts, paste("Assignee:", task$Assignee))
        }
        if ("Priority" %in% names(task) && !is.na(task$Priority)) {
          desc_parts <- c(desc_parts, paste("Priority:", task$Priority))
        }
        
        description <- paste(desc_parts, collapse = "\n")
        
        # Create card
        tryCatch({
          response <- POST(
            url = "https://api.trello.com/1/cards",
            query = list(
              key = input$trello_key,
              token = input$trello_token,
              idList = input$trello_list,
              name = task$Task_Name,
              desc = description
            )
          )
          
          if (status_code(response) == 200) {
            results <- c(results, paste("✓", task$Task_Name))
          } else {
            results <- c(results, paste("✗", task$Task_Name, "-", status_code(response)))
          }
        }, error = function(e) {
          results <<- c(results, paste("✗", task$Task_Name, "- Error:", e$message))
        })
        
        incProgress(1/nrow(values$gantt_data))
      }
    })
    
    output$trello_result <- renderText({
      paste(results, collapse = "\n")
    })
    
    showNotification(
      paste("Submitted", sum(grepl("✓", results)), "of", nrow(values$gantt_data), "tasks"), 
      type = "message"
    )
  })
  
  # Email Preview Table
  output$email_preview_table <- renderDT({
    req(values$gantt_data)
    
    # Create preview of who will receive emails
    if ("Assignee" %in% names(values$gantt_data)) {
      email_preview <- values$gantt_data %>%
        filter(!is.na(Assignee) & Assignee != "") %>%
        select(Task_Name, Assignee, Priority, Start_Date, End_Date)
      
      datatable(email_preview, 
                options = list(scrollX = TRUE, pageLength = 10))
    }
  })
  
  # Email Summary
  output$email_summary <- renderText({
    req(values$gantt_data)
    
    if ("Assignee" %in% names(values$gantt_data)) {
      tasks_with_assignees <- values$gantt_data %>%
        filter(!is.na(Assignee) & Assignee != "")
      
      unique_assignees <- unique(tasks_with_assignees$Assignee)
      
      if (input$group_by_assignee) {
        paste0(
          "Total tasks to notify: ", nrow(tasks_with_assignees), "\n",
          "Unique assignees: ", length(unique_assignees), "\n",
          "Emails to send: ", length(unique_assignees), "\n\n",
          "Assignees: ", paste(unique_assignees, collapse = ", ")
        )
      } else {
        paste0(
          "Total tasks to notify: ", nrow(tasks_with_assignees), "\n",
          "Unique assignees: ", length(unique_assignees), "\n",
          "Emails to send: ", nrow(tasks_with_assignees), " (one per task)\n\n",
          "Assignees: ", paste(unique_assignees, collapse = ", ")
        )
      }
    } else {
      "No assignees found in the data. Please add an 'Assignee' column."
    }
  })
  
  # Send Test Email
  observeEvent(input$send_test_email, {
    req(values$gantt_data, values$email_connected)
    
    if (nrow(values$gantt_data) == 0) {
      showNotification("No tasks to preview", type = "warning")
      return()
    }
    
    # Get first task as sample
    sample_task <- values$gantt_data[1, ]
    
    # Replace placeholders in template
    subject <- input$email_subject_template
    body <- input$email_body_template
    
    for (col in names(sample_task)) {
      placeholder <- paste0("{", col, "}")
      value <- ifelse(is.na(sample_task[[col]]), "", as.character(sample_task[[col]]))
      subject <- gsub(placeholder, value, subject, fixed = TRUE)
      body <- gsub(placeholder, value, body, fixed = TRUE)
    }
    
    tryCatch({
      # Create SMTP credentials
      smtp_creds <- creds(
        user = values$smtp_config$user,
        password = values$smtp_config$password,
        host = values$smtp_config$host,
        port = values$smtp_config$port,
        use_ssl = values$smtp_config$ssl
      )
      
      # Create and send test email
      test_email <- compose_email(
        body = md(paste0("**THIS IS A TEST EMAIL**\n\n", body, "\n\n---\n*This is how your task notifications will look.*"))
      )
      
      test_email %>%
        smtp_send(
          to = values$smtp_config$user,
          from = values$smtp_config$user,
          subject = paste("[TEST]", subject),
          credentials = smtp_creds
        )
      
      showNotification("Test email sent to your address!", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Failed to send test email:", e$message), type = "error")
    })
  })
  
  # Send All Emails
  observeEvent(input$send_emails, {
    req(values$gantt_data, values$email_connected)
    
    if (!"Assignee" %in% names(values$gantt_data)) {
      showNotification("No 'Assignee' column found in data", type = "error")
      return()
    }
    
    tasks_with_assignees <- values$gantt_data %>%
      filter(!is.na(Assignee) & Assignee != "")
    
    if (nrow(tasks_with_assignees) == 0) {
      showNotification("No tasks with assignees found", type = "warning")
      return()
    }
    
    results <- c()
    cc_list <- NULL
    
    if (input$cc_emails != "") {
      cc_list <- trimws(strsplit(input$cc_emails, ",")[[1]])
    }
    
    tryCatch({
      if (input$group_by_assignee) {
        # Group tasks by assignee and send one email per person
        unique_assignees <- unique(tasks_with_assignees$Assignee)
        
        withProgress(message = 'Sending emails...', value = 0, {
          for (assignee in unique_assignees) {
            assignee_tasks <- tasks_with_assignees %>%
              filter(Assignee == assignee)
            
            # Build email body with all tasks for this assignee
            task_list <- ""
            for (i in 1:nrow(assignee_tasks)) {
              task <- assignee_tasks[i, ]
              task_list <- paste0(
                task_list,
                "\n\n--- Task ", i, " ---\n",
                "Task: ", task$Task_Name, "\n",
                ifelse(!is.na(task$Description), paste0("Description: ", task$Description, "\n"), ""),
                ifelse(!is.na(task$Start_Date), paste0("Start Date: ", task$Start_Date, "\n"), ""),
                ifelse(!is.na(task$End_Date), paste0("End Date: ", task$End_Date, "\n"), ""),
                ifelse(!is.na(task$Priority), paste0("Priority: ", task$Priority, "\n"), ""),
                ifelse(!is.na(task$Labels), paste0("Labels: ", task$Labels, "\n"), "")
              )
            }
            
            subject <- gsub("{Assignee}", assignee, input$email_subject_template, fixed = TRUE)
            subject <- gsub("{Task_Name}", paste(nrow(assignee_tasks), "tasks assigned"), subject, fixed = TRUE)
            
            body <- paste0(
              "Hello ", assignee, ",\n\n",
              "You have been assigned ", nrow(assignee_tasks), " task(s):\n",
              task_list,
              "\n\nPlease review and confirm.\n\nBest regards"
            )
            
            # Try to parse email from assignee name (if format is "Name <email@domain.com>")
            to_email <- assignee
            if (grepl("<.*@.*>", assignee)) {
              to_email <- gsub(".*<(.*)>.*", "\\1", assignee)
            }
            
            # Create SMTP credentials
            smtp_creds <- creds(
              user = values$smtp_config$user,
              password = values$smtp_config$password,
              host = values$smtp_config$host,
              port = values$smtp_config$port,
              use_ssl = values$smtp_config$ssl
            )
            
            # Create and send email
            email <- compose_email(body = md(body))
            
            email %>%
              smtp_send(
                to = to_email,
                from = values$smtp_config$user,
                subject = subject,
                credentials = smtp_creds
              )
            
            results <- c(results, paste("✓ Sent to", assignee, "-", nrow(assignee_tasks), "tasks"))
            incProgress(1/length(unique_assignees))
          }
        })
        
      } else {
        # Send one email per task
        withProgress(message = 'Sending emails...', value = 0, {
          for (i in 1:nrow(tasks_with_assignees)) {
            task <- tasks_with_assignees[i, ]
            
            # Replace placeholders
            subject <- input$email_subject_template
            body <- input$email_body_template
            
            for (col in names(task)) {
              placeholder <- paste0("{", col, "}")
              value <- ifelse(is.na(task[[col]]), "", as.character(task[[col]]))
              subject <- gsub(placeholder, value, subject, fixed = TRUE)
              body <- gsub(placeholder, value, body, fixed = TRUE)
            }
            
            # Try to parse email from assignee name
            to_email <- task$Assignee
            if (grepl("<.*@.*>", task$Assignee)) {
              to_email <- gsub(".*<(.*)>.*", "\\1", task$Assignee)
            }
            
            # Create SMTP credentials
            smtp_creds <- creds(
              user = values$smtp_config$user,
              password = values$smtp_config$password,
              host = values$smtp_config$host,
              port = values$smtp_config$port,
              use_ssl = values$smtp_config$ssl
            )
            
            # Create and send email
            email <- compose_email(body = md(body))
            
            email %>%
              smtp_send(
                to = to_email,
                from = values$smtp_config$user,
                subject = subject,
                credentials = smtp_creds
              )
            
            results <- c(results, paste("✓", task$Task_Name, "->", task$Assignee))
            incProgress(1/nrow(tasks_with_assignees))
          }
        })
      }
      
      output$email_send_result <- renderText({
        paste(results, collapse = "\n")
      })
      
      showNotification(
        paste("Successfully sent", length(results), "email(s)!"), 
        type = "message", 
        duration = 10
      )
      
    }, error = function(e) {
      showNotification(paste("Error sending emails:", e$message), type = "error")
      output$email_send_result <- renderText({
        paste("Error:", e$message, "\n\nResults so far:\n", paste(results, collapse = "\n"))
      })
    })
  })
  
  # ============ CONTACTS MANAGEMENT LOGIC ============
  
  # Load contacts on startup
  observe({
    if (file.exists(values$contacts_file)) {
      tryCatch({
        values$contacts_data <- read_excel(values$contacts_file)
      }, error = function(e) {
        # Create empty dataframe if file doesn't exist or is corrupt
        values$contacts_data <- data.frame(
          Country = character(),
          City = character(),
          Organization = character(),
          Full_Name = character(),
          LinkedIn = character(),
          Email = character(),
          Phone = character(),
          Date_Added = character(),
          stringsAsFactors = FALSE
        )
      })
    } else {
      values$contacts_data <- data.frame(
        Country = character(),
        City = character(),
        Organization = character(),
        Full_Name = character(),
        LinkedIn = character(),
        Email = character(),
        Phone = character(),
        Date_Added = character(),
        stringsAsFactors = FALSE
      )
    }
  })
  
  # Add new contact
  observeEvent(input$add_contact, {
    req(input$contact_name, input$contact_email)
    
    # Validate email format
    if (!grepl("@", input$contact_email)) {
      showNotification("Please enter a valid email address", type = "error")
      return()
    }
    
    # Create new contact row
    new_contact <- data.frame(
      Country = input$contact_country,
      City = input$contact_city,
      Organization = input$contact_org,
      Full_Name = input$contact_name,
      LinkedIn = input$contact_linkedin,
      Email = input$contact_email,
      Phone = input$contact_phone,
      Date_Added = as.character(Sys.Date()),
      stringsAsFactors = FALSE
    )
    
    # Append to existing data
    if (is.null(values$contacts_data) || nrow(values$contacts_data) == 0) {
      values$contacts_data <- new_contact
    } else {
      values$contacts_data <- rbind(values$contacts_data, new_contact)
    }
    
    # Save to Excel
    tryCatch({
      writexl::write_xlsx(values$contacts_data, values$contacts_file)
      output$contact_add_status <- renderText({
        paste("✓ Contact added successfully:", input$contact_name)
      })
      showNotification("Contact added and saved!", type = "message")
      
      # Clear form
      updateTextInput(session, "contact_country", value = "")
      updateTextInput(session, "contact_city", value = "")
      updateTextInput(session, "contact_org", value = "")
      updateTextInput(session, "contact_name", value = "")
      updateTextInput(session, "contact_linkedin", value = "")
      updateTextInput(session, "contact_email", value = "")
      updateTextInput(session, "contact_phone", value = "")
      
    }, error = function(e) {
      output$contact_add_status <- renderText({
        paste("✗ Error saving contact:", e$message)
      })
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Clear contact form
  observeEvent(input$clear_contact_form, {
    updateTextInput(session, "contact_country", value = "")
    updateTextInput(session, "contact_city", value = "")
    updateTextInput(session, "contact_org", value = "")
    updateTextInput(session, "contact_name", value = "")
    updateTextInput(session, "contact_linkedin", value = "")
    updateTextInput(session, "contact_email", value = "")
    updateTextInput(session, "contact_phone", value = "")
  })
  
  # Display contacts table
  output$contacts_table <- renderDT({
    req(values$contacts_data)
    datatable(
      values$contacts_data,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        order = list(list(7, 'desc'))  # Sort by Date_Added descending
      ),
      rownames = FALSE
    )
  })
  
  # Contacts count
  output$contacts_count <- renderText({
    if (is.null(values$contacts_data) || nrow(values$contacts_data) == 0) {
      "No contacts in database"
    } else {
      paste("Total contacts:", nrow(values$contacts_data))
    }
  })
  
  # Refresh contacts
  observeEvent(input$refresh_contacts, {
    if (file.exists(values$contacts_file)) {
      tryCatch({
        values$contacts_data <- read_excel(values$contacts_file)
        showNotification("Contacts refreshed!", type = "message")
      }, error = function(e) {
        showNotification(paste("Error refreshing:", e$message), type = "error")
      })
    }
  })
  
  # Download contacts
  output$download_contacts <- downloadHandler(
    filename = function() {
      paste0("contacts_export_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      writexl::write_xlsx(values$contacts_data, file)
    }
  )
  
  # Upload contacts
  observeEvent(input$upload_contacts, {
    req(input$upload_contacts)
    
    tryCatch({
      uploaded_data <- read_excel(input$upload_contacts$datapath)
      
      # Validate columns
      required_cols <- c("Country", "City", "Organization", "Full_Name", "Email")
      if (!all(required_cols %in% names(uploaded_data))) {
        showNotification("Invalid file format. Missing required columns.", type = "error")
        return()
      }
      
      # Merge with existing data
      if (is.null(values$contacts_data) || nrow(values$contacts_data) == 0) {
        values$contacts_data <- uploaded_data
      } else {
        values$contacts_data <- rbind(values$contacts_data, uploaded_data)
      }
      
      # Remove duplicates based on email
      values$contacts_data <- values$contacts_data %>%
        distinct(Email, .keep_all = TRUE)
      
      # Save to file
      writexl::write_xlsx(values$contacts_data, values$contacts_file)
      
      showNotification(
        paste("Uploaded", nrow(uploaded_data), "contacts (duplicates removed)"), 
        type = "message"
      )
      
    }, error = function(e) {
      showNotification(paste("Upload error:", e$message), type = "error")
    })
  })
  
  # Clear all contacts
  observeEvent(input$clear_all_contacts, {
    showModal(modalDialog(
      title = "Confirm Delete",
      "Are you sure you want to delete ALL contacts? This cannot be undone.",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_clear_contacts", "Delete All", class = "btn-danger")
      )
    ))
  })
  
  observeEvent(input$confirm_clear_contacts, {
    values$contacts_data <- data.frame(
      Country = character(),
      City = character(),
      Organization = character(),
      Full_Name = character(),
      LinkedIn = character(),
      Email = character(),
      Phone = character(),
      Date_Added = character(),
      stringsAsFactors = FALSE
    )
    
    if (file.exists(values$contacts_file)) {
      file.remove(values$contacts_file)
    }
    
    removeModal()
    showNotification("All contacts deleted", type = "warning")
  })
  
  # ============ EMAIL CONTACTS LOGIC ============
  
  # Update filter dropdowns when contacts change
  observe({
    req(values$contacts_data)
    
    if (nrow(values$contacts_data) > 0) {
      countries <- unique(values$contacts_data$Country)
      countries <- countries[countries != ""]
      updateSelectInput(session, "filter_country", 
                        choices = c("All" = "", countries))
      
      cities <- unique(values$contacts_data$City)
      cities <- cities[cities != ""]
      updateSelectInput(session, "filter_city", 
                        choices = c("All" = "", cities))
      
      orgs <- unique(values$contacts_data$Organization)
      orgs <- orgs[orgs != ""]
      updateSelectInput(session, "filter_org", 
                        choices = c("All" = "", orgs))
    }
  })
  
  # Apply filters
  observeEvent(input$apply_filters, {
    req(values$contacts_data)
    
    filtered <- values$contacts_data
    
    if (input$filter_country != "") {
      filtered <- filtered %>% filter(Country == input$filter_country)
    }
    
    if (input$filter_city != "") {
      filtered <- filtered %>% filter(City == input$filter_city)
    }
    
    if (input$filter_org != "") {
      filtered <- filtered %>% filter(Organization == input$filter_org)
    }
    
    values$filtered_contacts <- filtered
    
    showNotification(
      paste("Filtered to", nrow(filtered), "contacts"), 
      type = "message"
    )
  })
  
  # Display filtered contacts table
  output$filtered_contacts_table <- renderDT({
    data_to_show <- if (!is.null(values$filtered_contacts)) {
      values$filtered_contacts
    } else if (!is.null(values$contacts_data)) {
      values$contacts_data
    } else {
      data.frame()
    }
    
    datatable(
      data_to_show,
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      selection = 'multiple',
      rownames = FALSE
    )
  })
  
  # Track selected rows
  observeEvent(input$filtered_contacts_table_rows_selected, {
    values$selected_contact_rows <- input$filtered_contacts_table_rows_selected
  })
  
  # Select all
  observeEvent(input$select_all_contacts, {
    data_to_show <- if (!is.null(values$filtered_contacts)) {
      values$filtered_contacts
    } else {
      values$contacts_data
    }
    
    if (!is.null(data_to_show) && nrow(data_to_show) > 0) {
      proxy <- dataTableProxy('filtered_contacts_table')
      selectRows(proxy, 1:nrow(data_to_show))
    }
  })
  
  # Deselect all
  observeEvent(input$deselect_all_contacts, {
    proxy <- dataTableProxy('filtered_contacts_table')
    selectRows(proxy, NULL)
  })
  
  # Selected contacts count
  output$selected_contacts_count <- renderText({
    count <- length(values$selected_contact_rows)
    if (count == 0) {
      "No contacts selected. Click on rows to select recipients."
    } else {
      paste("Selected:", count, "contact(s)")
    }
  })
  
  # Send emails to selected contacts
  observeEvent(input$send_contact_emails, {
    req(values$selected_contact_rows, input$contact_email_subject, input$contact_email_body)
    
    if (!values$email_connected || length(values$smtp_config) == 0) {
      showNotification("Please configure email settings first (Email Configuration tab)", 
                       type = "error")
      return()
    }
    
    # Get selected contacts
    data_to_use <- if (!is.null(values$filtered_contacts)) {
      values$filtered_contacts
    } else {
      values$contacts_data
    }
    
    selected_contacts <- data_to_use[values$selected_contact_rows, ]
    
    if (nrow(selected_contacts) == 0) {
      showNotification("No contacts selected", type = "warning")
      return()
    }
    
    results <- c()
    
    withProgress(message = 'Sending emails to contacts...', value = 0, {
      for (i in 1:nrow(selected_contacts)) {
        contact <- selected_contacts[i, ]
        
        tryCatch({
          # Personalize email body
          email_body <- input$contact_email_body
          
          if (input$include_contact_name) {
            email_body <- gsub("\\{NAME\\}", contact$Full_Name, email_body)
          }
          
          if (input$include_org_name) {
            email_body <- gsub("\\{ORG\\}", contact$Organization, email_body)
          }
          
          # Create SMTP credentials
          smtp_creds <- creds(
            user = values$smtp_config$user,
            password = values$smtp_config$password,
            host = values$smtp_config$host,
            port = values$smtp_config$port,
            use_ssl = values$smtp_config$ssl
          )
          
          # Create and send email
          email <- compose_email(body = md(email_body))
          
          email %>%
            smtp_send(
              to = contact$Email,
              from = values$smtp_config$user,
              subject = input$contact_email_subject,
              credentials = smtp_creds
            )
          
          results <- c(results, paste("✓", contact$Full_Name, "-", contact$Email))
          
        }, error = function(e) {
          results <<- c(results, paste("✗", contact$Full_Name, "-", e$message))
        })
        
        incProgress(1/nrow(selected_contacts))
      }
    })
    
    output$contact_email_results <- renderText({
      paste(results, collapse = "\n")
    })
    
    showNotification(
      paste("Sent", sum(grepl("✓", results)), "of", nrow(selected_contacts), "emails"), 
      type = "message",
      duration = 10
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)