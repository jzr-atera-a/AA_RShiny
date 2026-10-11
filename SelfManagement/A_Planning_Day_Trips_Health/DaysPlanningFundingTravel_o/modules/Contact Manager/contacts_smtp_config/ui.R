# modules/Contact Manager/contacts_smtp_config/ui.R

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
