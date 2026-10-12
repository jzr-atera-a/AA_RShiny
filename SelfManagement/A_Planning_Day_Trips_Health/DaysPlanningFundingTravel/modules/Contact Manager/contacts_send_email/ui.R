# modules/Contact Manager/contacts_send_email/ui.R

contacts_send_email_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Compose Email", status = "primary", solidHeader = TRUE, width = 12,
          p("Pre-populated automatically when you click 'Send Email' from Customise Communication, or when an event ",
            "from a Zoom invite is saved in Events to Calendar."),
          htmlOutput(ns("sender_info")),
          radioButtons(ns("mode"), "Type of email",
                       c("Regular email" = "regular", "Invite (calendar invitation)" = "invite"),
                       selected = "regular", inline = TRUE),
          uiOutput(ns("draft_picker")),
          textInput(ns("email_to"), "To:", value = "", width = "100%"),
          textInput(ns("email_cc"), "CC (comma-separated):", value = BOS_ALWAYS_CC, width = "100%"),
          p(class = "text-muted", style = "margin-top: -8px; font-size: 0.85em;",
            icon("info-circle"), " ", BOS_ALWAYS_CC, " is always copied."),
          textInput(ns("email_subject"), "Subject:", value = "", width = "100%"),
          textAreaInput(ns("email_body"), "Body:", value = "", rows = 12, width = "100%"),

          conditionalPanel(sprintf("input['%s'] == 'invite'", ns("mode")),
            hr(),
            h4(icon("calendar-check"), " Calendar invitation"),
            p("The email carries a calendar invitation (.ics): the recipient's email app shows ",
              tags$strong("Yes / No / Maybe"), " buttons, the meeting can be added to their calendar, and their answer is ",
              "emailed back to the sending Titan mailbox. The same .ics is also attached as a file."),
            textInput(ns("inv_title"), "Meeting title", value = "", width = "100%"),
            fluidRow(
              column(3, dateInput(ns("inv_date"), "Date", Sys.Date(), weekstart = 1)),
              column(2, textInput(ns("inv_start"), "Start (HH:MM)", "10:00")),
              column(2, numericInput(ns("inv_duration"), "Minutes", 60, min = 5, step = 5)),
              column(5, selectInput(ns("inv_tz"), "Time zone", TITAN_TIMEZONES, selected = TITAN_DEFAULT_TZ))
            ),
            textInput(ns("inv_location"), "Location / Zoom link", value = "", width = "100%"),
            textAreaInput(ns("inv_join"), "Joining details (also written into the .ics)", value = "", rows = 6, width = "100%"),
            tags$details(
              tags$summary("Show the invitation (.ics) that will be sent"),
              verbatimTextOutput(ns("ics_preview"))
            )
          ),

          fileInput(ns("email_attachments"), "Attachments (optional):", multiple = TRUE),
          actionButton(ns("send_email"), "Send Email", class = "btn-success btn-lg", icon = icon("paper-plane")),
          br(), br(),
          htmlOutput(ns("send_status"))
      )
    )
  )
}
