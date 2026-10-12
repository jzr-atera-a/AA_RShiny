# modules/Events Scheduling/zoom_schedule/ui.R

zoom_schedule_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Zoom Schedule - read invite images", status = "primary", solidHeader = TRUE, width = 12,
          p("Upload one or more screenshots or photos of a Zoom invitation (for example one with the link and details and another with the invited people\'s emails; hold Ctrl/Cmd to pick several). Claude treats them all as the same meeting. Claude reads the ", tags$strong("subject"), ", ",
            tags$strong("date and time (in the zone shown in the image)"), ", the ", tags$strong("length"),
            " of the call, the ", tags$strong("Zoom link and joining details"), " and the ",
            tags$strong("email addresses"), " of the people invited. The details then open in ",
            tags$strong("Events to Calendar"), " ready to add to your Titan calendar, and from there into ",
            tags$strong("Contact Manager > Send Email"), " as a calendar invite."),
          uiOutput(ns("claude_note")),
          fluidRow(
            column(6, fileInput(ns("invite_image"), "Invite image(s) - one or several (PNG, JPG, GIF or WebP, up to 5 MB each)", multiple = TRUE,
                                accept = c("image/png", "image/jpeg", "image/gif", "image/webp", ".png", ".jpg", ".jpeg", ".gif", ".webp"),
                                buttonLabel = "Browse...", placeholder = "No images selected")),
            column(6, bos_tz_dropdown_ui(ns, label = "Time zone to use if the image shows none",
                                         help = "Claude uses the zone printed in the image when there is one."))
          ),
          textInput(ns("extra"), "Extra instructions for Claude (optional)", "", width = "100%",
                    placeholder = "e.g. The invitees are only the people on the To line"),
          actionButton(ns("read_invite"), "Read invite with Claude", icon = icon("magic"),
                       class = "btn-primary btn-lg"),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      column(5, box(title = "Image", status = "info", solidHeader = TRUE, width = 12, uiOutput(ns("preview")))),
      column(7, box(title = "What Claude found", status = "success", solidHeader = TRUE, width = 12,
                    htmlOutput(ns("result")),
                    uiOutput(ns("continue_ui"))))
    ),
    fluidRow(
      box(title = "Claude's raw answer", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(tags$small("For checking only. The calendar invite that is emailed is rebuilt by the app from the details you confirm ",
                       "in Events to Calendar and Send Email, so the time zone and the invite fields are always consistent.")),
          verbatimTextOutput(ns("raw_answer")),
          h5("Calendar text (.ics) returned by Claude"),
          verbatimTextOutput(ns("raw_ics"))
      )
    )
  )
}
