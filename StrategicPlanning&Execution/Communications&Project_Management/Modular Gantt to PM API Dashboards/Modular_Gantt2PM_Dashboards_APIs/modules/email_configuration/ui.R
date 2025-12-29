# modules/email_configuration/ui.R
# Email Configuration UI
# ======================

email_configuration_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "SMTP Email Configuration", 
        status = "primary", 
        solidHeader = TRUE,
        width = 12,
        p("Configure your email settings to send task notifications directly to team members."),
        hr(),
        selectInput(ns("email_provider"), "Email Provider:",
                    choices = c("Gmail", "Outlook/Office365", "Custom SMTP")),
        textInput(ns("smtp_server"), "SMTP Server:", 
                  placeholder = "smtp.gmail.com"),
        numericInput(ns("smtp_port"), "SMTP Port:", 
                     value = 587, min = 1, max = 65535),
        textInput(ns("smtp_username"), "Email Address:", 
                  placeholder = "your.email@example.com"),
        passwordInput(ns("smtp_password"), "Password/App Password:", ""),
        checkboxInput(ns("use_ssl"), "Use SSL/TLS", value = TRUE),
        actionButton(ns("test_email"), "Test Email Connection", 
                     class = "btn-success"),
        br(), br(),
        htmlOutput(ns("email_status"))
      )
    ),
    fluidRow(
      box(
        title = "Email Template Settings",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        textInput(ns("email_subject_template"), "Email Subject Template:",
                  value = "New Task Assignment: {Task_Name}",
                  placeholder = "Use {Task_Name} for dynamic content"),
        textAreaInput(ns("email_body_template"), "Email Body Template:",
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
  )
}
