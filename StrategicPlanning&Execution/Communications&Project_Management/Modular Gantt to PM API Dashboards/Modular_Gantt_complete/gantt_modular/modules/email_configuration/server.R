# modules/email_configuration/server.R
# Email Configuration Server Logic
# =================================

email_configuration_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
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
        api_manager$set_smtp_config(
          host = input$smtp_server,
          port = input$smtp_port,
          user = input$smtp_username,
          password = input$smtp_password,
          use_ssl = input$use_ssl
        )
        
        # Test connection
        api_manager$test_email_connection()
        
        output$email_status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Email configuration successful! Test email sent to your address.")
        })
        
        showNotification("Test email sent successfully!", type = "message")
        
      }, error = function(e) {
        output$email_status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Email configuration failed: ",
                   tags$br(),
                   tags$small(e$message))
        })
        showNotification(paste("Email test failed:", e$message), type = "error")
      })
    })
    
    # Default output
    output$email_status <- renderUI({ tags$div() })
  })
}
