# modules/Gantt to Tickets/gantt_email_config/server.R

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
