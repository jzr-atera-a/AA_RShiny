# modules/Events Scheduling/titan_auth/ui.R

titan_auth_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Titan Calendar Authentication", status = "primary", solidHeader = TRUE, width = 12,
          p("Sign in to your Titan calendar by loading a small text file named ",
            tags$code("authenticateT.R"), ". The file is read as plain text (it is never run) and ",
            "must contain two separate lines, the prefix first and then the value:"),
          tags$pre(style = "background: #f8f9fa; border-left: 4px solid #008A82; padding: 10px;",
                   "e:your.name@yourdomain.com\np:your-mailbox-password"),
          p(tags$small("Use the full email address and the mailbox password (the one used for webmail and the ",
                       "Titan app, not the GoDaddy account password). The password is kept in this app's ",
                       "server memory only: it is not written to disk, not shown, and not logged. The uploaded ",
                       "copy is deleted as soon as it has been read.")),
          fileInput(ns("auth_file"), "Load authenticateT.R", accept = c(".R", ".r", ".txt", "text/plain"),
                    buttonLabel = "Browse...", placeholder = "No file selected"),
          htmlOutput(ns("file_status"))
      )
    ),
    fluidRow(
      box(title = "Calendar Server", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(
            column(6, selectInput(ns("server"), "Calendar server", TITAN_SERVERS)),
            column(6, conditionalPanel(sprintf("input['%s'] == 'custom'", ns("server")),
                      textInput(ns("custom_server"), "Server URL", placeholder = "https://caldav.example.com")))
          ),
          p(tags$small("Leave on Auto-detect: it tries dav.myprofessionalmail.com (GoDaddy / 123 Reg Professional ",
                       "Email), then dav.titan.email and dav-eu.titan.email, and stops at the first that returns calendars.")),
          fluidRow(
            column(4, actionButton(ns("authenticate"), "Authenticate with Titan",
                                   icon = icon("sign-in-alt"), class = "btn-primary", style = "width: 100%;")),
            column(4, actionButton(ns("sign_out"), "Sign out",
                                   icon = icon("sign-out-alt"), class = "btn-danger", style = "width: 100%;"))
          ),
          htmlOutput(ns("auth_status"))
      )
    ),
    fluidRow(
      box(title = "Email Sending (SMTP)", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p("The same Titan mailbox also sends email (",
            tags$strong("Contact Manager > Send Email"), "). It uses the email address and password from the file above, ",
            "so there is nothing else to enter. Only change the server if the default does not work."),
          fluidRow(
            column(5, selectInput(ns("smtp_server"), "Outgoing mail (SMTP) server", TITAN_SMTP_SERVERS)),
            column(4, conditionalPanel(sprintf("input['%s'] == 'custom'", ns("smtp_server")),
                      textInput(ns("smtp_custom_host"), "SMTP host", placeholder = "smtp.example.com"))),
            column(3, selectInput(ns("smtp_port"), "Port", c("465 (SSL)" = "465", "587 (STARTTLS)" = "587")))
          ),
          htmlOutput(ns("smtp_effective")),
          actionButton(ns("smtp_test"), "Test email login", icon = icon("vial"), class = "btn-info"),
          p(class = "text-muted", style = "font-size: 0.85em; margin-top: 8px;",
            "The test logs in to the mail server only; no message is sent."),
          htmlOutput(ns("smtp_status"))
      )
    ),
    fluidRow(
      box(title = "Connected Calendars", status = "success", solidHeader = TRUE, width = 12,
          htmlOutput(ns("calendars_info")),
          DT::DTOutput(ns("calendars_tbl")),
          hr(),
          p(tags$small("Time zone: choose it on Events to Calendar > New events > Events to save. It applies to ",
                       "events you type in, to events sent from the Visualisation tabs, and (in the Import tab) to ",
                       "imported times that carry no zone.")),
          tags$details(
            tags$summary("Calendar URL manually (if no calendar is found automatically)"),
            textInput(ns("manual_url"), NULL,
                      placeholder = "https://dav.titan.email/principals/you@domain/calendar/ID/"),
            actionButton(ns("use_manual"), "Use this URL", class = "btn-info")
          )
      )
    )
  )
}
