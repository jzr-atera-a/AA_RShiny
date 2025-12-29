# modules/smtp_config/ui.R
smtp_config_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "SMTP Configuration (GoDaddy)", 
        status = "primary", 
        solidHeader = TRUE,
        width = 12,
        
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
        htmlOutput(ns("connection_status"))
      )
    )
  )
}
