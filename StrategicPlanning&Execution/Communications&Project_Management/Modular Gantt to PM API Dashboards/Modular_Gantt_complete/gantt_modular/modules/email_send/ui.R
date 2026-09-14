# modules/email_send/ui.R
email_send_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Email Assignment Notifications",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p("Send personalized email notifications to assignees for their tasks."),
        p(strong("Note:"), "This will send individual emails to each assignee with their assigned tasks.")
      )
    ),
    fluidRow(
      box(
        title = "Preview Emails",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        DT::dataTableOutput(ns("email_preview_table")),
        br(),
        p(strong("Summary:")),
        verbatimTextOutput(ns("email_summary"))
      )
    ),
    fluidRow(
      box(
        title = "Email Options",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        checkboxInput(ns("group_by_assignee"), 
                      "Group tasks by assignee (one email per person)", 
                      value = TRUE),
        checkboxInput(ns("include_attachments"), 
                      "Include task list as CSV attachment", 
                      value = FALSE),
        textInput(ns("cc_emails"), "CC (comma-separated):", 
                  placeholder = "manager@example.com, pm@example.com")
      ),
      box(
        title = "Send Emails",
        status = "success",
        solidHeader = TRUE,
        width = 6,
        actionButton(ns("send_emails"), "Send All Emails", 
                     class = "btn-success btn-lg btn-block",
                     icon = icon("paper-plane")),
        br(),
        actionButton(ns("send_test_email"), "Send Test Email to Myself", 
                     class = "btn-info btn-block"),
        br(),
        verbatimTextOutput(ns("email_send_result"))
      )
    )
  )
}
