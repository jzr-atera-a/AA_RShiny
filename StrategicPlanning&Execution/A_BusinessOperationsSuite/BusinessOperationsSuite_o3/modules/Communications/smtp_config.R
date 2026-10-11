# modules/Communications/smtp_config.R
# Subtab: SMTP Configuration (under the "Communications" main tab)

smtp_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "SMTP Configuration (GoDaddy)", status = "primary", solidHeader = TRUE, width = 12,

        fluidRow(
          column(6, textInput(ns("smtp_host"), "SMTP Host:", value = "smtpout.secureserver.net")),
          column(6, textInput(ns("smtp_port"), "SMTP Port:", value = "465"))
        ),
        hr(),
        fluidRow(
          column(6, textInput(ns("smtp_username"), "Email Address:", value = "")),
          column(6, passwordInput(ns("smtp_password"), "Password:", value = ""))
        ),
        br(),
        fluidRow(
          column(4, actionButton(ns("test_connection"), "Test Connection", icon = icon("vial"), class = "btn-info", width = "100%")),
          column(4, actionButton(ns("open_connection"), "Open Connection", icon = icon("plug"), class = "btn-success", width = "100%")),
          column(4, actionButton(ns("close_connection"), "Close Connection", icon = icon("times-circle"), class = "btn-danger", width = "100%"))
        ),
        br(),
        uiOutput(ns("connection_status"))
      )
    )
  )
}

smtp_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    status_message <- reactiveVal("")

    observeEvent(input$test_connection, {
      if (input$smtp_host == "" || input$smtp_username == "" || input$smtp_password == "") {
        status_message("ERROR: Fill all fields")
        showNotification("Fill all fields", type = "error", duration = 5)
        return()
      }

      showNotification("Testing SMTP connection...", type = "message", duration = NULL, id = "testing")

      tryCatch({
        api_manager$smtp_test_connection(input$smtp_host, input$smtp_port, input$smtp_username, input$smtp_password)
        status_message(paste0(
          "✓ CONNECTION TEST SUCCESSFUL!\n\n",
          "Server: ", input$smtp_host, ":", input$smtp_port, "\n",
          "Authentication: Verified\nStatus: Ready to send emails\n\n",
          "Click 'Open Connection' to enable sending."
        ))
        removeNotification(id = "testing")
        showNotification("✓ Connection verified! No test email sent.", type = "message", duration = 5)
      }, error = function(e) {
        status_message(paste0("✗ TEST FAILED\n\nError: ", e$message, "\n\nCheck credentials and server settings"))
        removeNotification(id = "testing")
        showNotification(paste("Failed:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$open_connection, {
      if (!api_manager$smtp_tested) {
        showNotification("⚠ Test connection first", type = "warning", duration = 5)
        return()
      }
      api_manager$smtp_open_connection(input$smtp_host, input$smtp_port, input$smtp_username, input$smtp_password)
      status_message("✓ CONNECTION OPEN!\n\nCredentials stored.\nReady to send - NO password prompts!")
      showNotification("✓ Connection open!", type = "message", duration = 5)
    })

    observeEvent(input$close_connection, {
      api_manager$smtp_close_connection()
      status_message("Connection closed.")
      showNotification("Connection closed", type = "warning", duration = 3)
    })

    output$connection_status <- renderUI({
      msg <- status_message()
      if (msg == "") return(NULL)

      cls <- if (api_manager$smtp_connected) "alert-success"
             else if (api_manager$smtp_tested) "alert-warning"
             else "alert-danger"

      div(class = cls, style = "white-space: pre-wrap;", icon("check-circle"), strong(" Status:\n"), msg)
    })
  })
}
