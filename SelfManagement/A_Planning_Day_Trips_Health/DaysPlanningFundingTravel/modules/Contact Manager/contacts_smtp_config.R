# modules/Contact Manager/contacts_smtp_config.R
# ---- module ----------------------------------------------
# id:           contacts_smtp_config
# name:         SMTP Config
# icon:         envelope-open-text
# description:  SMTP email configuration, local to this suite
# packages:     shiny, shinydashboard
# -----------------------------------------------------------

# ---- UI ----
contacts_smtp_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "SMTP Configuration", status = "primary", solidHeader = TRUE, width = 12,
          p("Kept separate from the Gantt to Tickets suite's own SMTP config, since each suite's email ",
            "identity is typically different."),
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
          actionButton(ns("test_connection"), "Test Connection", icon = icon("vial"), class = "btn-info"),
          br(), br(),
          htmlOutput(ns("connection_status"))
      )
    )
  )
}

# ---- Server ----
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
