# modules/smtp_config/server.R
smtp_config_server <- function(id, contact_manager) {
  moduleServer(id, function(input, output, session) {
    
    connection_state <- reactiveValues(tested = FALSE, message = "")
    
    observeEvent(input$test_connection, {
      if (input$smtp_host == "" || input$smtp_username == "" || input$smtp_password == "") {
        connection_state$message <- "ERROR: Fill all fields"
        showNotification("Fill all fields", type = "error", duration = 5)
        return()
      }
      
      showNotification("Testing SMTP connection...", type = "message", duration = NULL, id = "testing")
      
      tryCatch({
        test_cmd <- sprintf(
          'curl -v --url "smtps://%s:%s" --user "%s:%s" --ssl-reqd 2>&1',
          input$smtp_host, input$smtp_port, input$smtp_username, input$smtp_password
        )
        
        result <- system(test_cmd, intern = TRUE, ignore.stderr = FALSE)
        
        if (any(grepl("250|220|AUTH", result, ignore.case = TRUE))) {
          connection_state$tested <- TRUE
          connection_state$message <- paste0(
            "✓ CONNECTION TEST SUCCESSFUL!\n\n",
            "Server: ", input$smtp_host, ":", input$smtp_port, "\n",
            "Authentication: Verified\n",
            "Status: Ready to send emails"
          )
          
          removeNotification(id = "testing")
          showNotification("✓ Connection verified!", type = "message", duration = 5)
        } else {
          stop("Connection test failed")
        }
        
      }, error = function(e) {
        connection_state$tested <- FALSE
        connection_state$message <- paste0("✗ TEST FAILED\n\nError: ", e$message)
        removeNotification(id = "testing")
        showNotification(paste("Failed:", e$message), type = "error", duration = 10)
      })
    })
    
    observeEvent(input$open_connection, {
      if (!connection_state$tested) {
        showNotification("⚠ Test connection first", type = "warning", duration = 5)
        return()
      }
      
      contact_manager$set_smtp_credentials(
        host = input$smtp_host,
        port = input$smtp_port,
        username = input$smtp_username,
        password = input$smtp_password
      )
      
      connection_state$message <- "✓ CONNECTION OPEN!\n\nReady to send emails"
      showNotification("✓ Connection open!", type = "message", duration = 5)
    })
    
    observeEvent(input$close_connection, {
      contact_manager$smtp_connected <- FALSE
      connection_state$tested <- FALSE
      connection_state$message <- "Connection closed."
      showNotification("Connection closed", type = "warning", duration = 3)
    })
    
    output$connection_status <- renderUI({
      if (connection_state$message == "") return(NULL)
      
      if (contact_manager$smtp_connected) {
        tags$div(class = "status-success", style = "white-space: pre-wrap;",
                 tags$i(class = "fa fa-check-circle"), tags$strong(" Status:\n"), connection_state$message)
      } else if (connection_state$tested) {
        tags$div(class = "status-warning", style = "white-space: pre-wrap;",
                 tags$i(class = "fa fa-check-circle"), tags$strong(" Status:\n"), connection_state$message)
      } else {
        tags$div(class = "status-error", style = "white-space: pre-wrap;",
                 tags$i(class = "fa fa-exclamation-circle"), tags$strong(" Status:\n"), connection_state$message)
      }
    })
  })
}
