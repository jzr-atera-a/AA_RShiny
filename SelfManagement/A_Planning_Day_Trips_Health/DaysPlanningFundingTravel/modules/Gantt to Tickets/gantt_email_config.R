# modules/Gantt to Tickets/gantt_email_config.R
# ---- module ----------------------------------------------
# id:           gantt_email_config
# name:         Email Config
# icon:         envelope-open-text
# description:  SMTP email configuration for task notifications, local to this suite
# packages:     shiny, shinydashboard
# -----------------------------------------------------------

# ---- UI ----
gantt_email_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "SMTP Email Configuration", status = "primary", solidHeader = TRUE, width = 12,
          p("Configure your email settings to send task notifications directly to team members."),
          hr(),
          selectInput(ns("email_provider"), "Email Provider:", choices = c("Gmail", "Outlook/Office365", "Custom SMTP")),
          textInput(ns("smtp_server"), "SMTP Server:", placeholder = "smtp.gmail.com"),
          numericInput(ns("smtp_port"), "SMTP Port:", value = 587, min = 1, max = 65535),
          textInput(ns("smtp_username"), "Email Address:", placeholder = "your.email@example.com"),
          passwordInput(ns("smtp_password"), "Password/App Password:", ""),
          actionButton(ns("test_email"), "Test Email Connection", class = "btn-success"),
          br(), br(),
          htmlOutput(ns("email_status"))
      )
    ),
    fluidRow(
      box(title = "Email Template Settings", status = "info", solidHeader = TRUE, width = 12,
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
      box(title = "Gmail & Outlook Instructions", status = "warning", width = 12,
          HTML("<h4>How to configure email:</h4>
               <p><strong>Gmail:</strong></p>
               <ul>
                 <li>SMTP Server: smtp.gmail.com</li>
                 <li>Port: 587 (TLS) or 465 (SSL)</li>
                 <li>Enable 2-factor authentication on your Google account</li>
                 <li>Generate an App Password: <a href='https://myaccount.google.com/apppasswords' target='_blank'>Google App Passwords</a></li>
               </ul>
               <p><strong>Outlook/Office365:</strong></p>
               <ul>
                 <li>SMTP Server: smtp-mail.outlook.com or smtp.office365.com</li>
                 <li>Port: 587</li>
               </ul>")
      )
    )
  )
}

# ---- Server ----
gantt_email_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_email, {
      req(input$smtp_server, input$smtp_username, input$smtp_password)
      tryCatch({
        api_manager$set_gantt_smtp_config(input$smtp_server, input$smtp_port, input$smtp_username, input$smtp_password)
        api_manager$test_gantt_smtp_connection()
        output$email_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " SMTP connection successful!")
        })
        showNotification("✓ SMTP connected!", type = "message")
      }, error = function(e) {
        output$email_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # Save template settings onto api_manager so gantt_email_send can read them
    observe({
      api_manager$gantt_email_subject_template <- input$email_subject_template
      api_manager$gantt_email_body_template <- input$email_body_template
    })

    output$email_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
