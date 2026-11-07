# modules/Contact Manager/contacts_smtp_config/server.R

contacts_smtp_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_connection, {
      req(input$smtp_host, input$smtp_username, input$smtp_password)
      tryCatch({
        api_manager$set_contacts_smtp_config(input$smtp_host, input$smtp_port, input$smtp_username, input$smtp_password)
        api_manager$test_contacts_smtp_connection()
        output$connection_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " SMTP connection successful!")
        })
        showNotification("✓ SMTP connected!", type = "message")
      }, error = function(e) {
        output$connection_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$connection_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
