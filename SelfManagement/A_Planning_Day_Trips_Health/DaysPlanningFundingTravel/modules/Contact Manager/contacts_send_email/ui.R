# modules/Contact Manager/contacts_send_email/ui.R

contacts_send_email_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Compose Email", status = "primary", solidHeader = TRUE, width = 12,
          p("Pre-populated automatically when you click 'Send Email' from Customise Communication."),
          textInput(ns("email_to"), "To:", value = "", width = "100%"),
          textInput(ns("email_cc"), "CC (comma-separated, optional):", value = "", width = "100%"),
          textInput(ns("email_subject"), "Subject:", value = "", width = "100%"),
          textAreaInput(ns("email_body"), "Body:", value = "", rows = 12, width = "100%"),
          fileInput(ns("email_attachments"), "Attachments (optional):", multiple = TRUE),
          actionButton(ns("send_email"), "Send Email", class = "btn-success btn-lg", icon = icon("paper-plane")),
          br(), br(),
          htmlOutput(ns("send_status"))
      )
    )
  )
}
