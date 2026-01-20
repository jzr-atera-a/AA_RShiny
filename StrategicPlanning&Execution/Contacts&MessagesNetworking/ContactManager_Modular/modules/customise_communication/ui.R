# modules/customise_communication/ui.R
customise_communication_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Communication Settings", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(3, selectInput(ns("comm_channel"), "Channel Type:",
                               choices = c("LinkedIn", "Email", "WhatsApp", "General Message"),
                               selected = "LinkedIn")),
          column(3, selectInput(ns("comm_purpose"), "Communication Purpose:",
                               choices = c("Introduction", "Follow Up", "Partnership Enquiry",
                                         "Met at recent event", "Having something in common", "Other"),
                               selected = "Introduction")),
          column(3, selectInput(ns("comm_language"), "Language:",
                               choices = c("English UK", "English US", "Spanish LatinAmerica"),
                               selected = "English UK")),
          column(3, selectInput(ns("comm_length"), "Message Length:",
                               choices = c("50", "100", "180", "240", "500"), selected = "100"))
        )
      )
    ),
    fluidRow(
      box(title = "Selected Contact Profile", status = "info", solidHeader = TRUE, width = 12,
        div(class = "profile-summary-box", htmlOutput(ns("contact_profile")))
      )
    ),
    fluidRow(
      box(title = "Recent Communication History", status = "success", solidHeader = TRUE, width = 12,
        actionButton(ns("load_recent_messages"), "Load Last 3 Messages", 
                     class = "btn-info", icon = icon("history"), style = "margin-bottom: 15px;"),
        br(),
        div(class = "message-box", htmlOutput(ns("recent_messages")))
      )
    ),
    fluidRow(
      box(title = "Communication Summary (LLM Analysis)", status = "warning", solidHeader = TRUE, width = 12,
        div(class = "message-box", htmlOutput(ns("communication_summary")))
      )
    ),
    fluidRow(
      box(title = "Message Customisation Guidelines", status = "primary", solidHeader = TRUE, width = 12,
        p("Provide specific guidelines and key points to include in the new message:"),
        textAreaInput(ns("message_guidelines"), NULL,
                      placeholder = "E.g., 'Mention our mutual interest in renewable energy'...",
                      height = "150px", width = "100%"),
        br(),
        actionButton(ns("generate_message"), "Generate Message with LLM", 
                     class = "btn-success", icon = icon("magic"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("generate_status"))
      )
    ),
    fluidRow(
      box(title = "Generated Message", status = "success", solidHeader = TRUE, width = 12,
        div(class = "message-box", htmlOutput(ns("generated_message"))),
        br(),
        fluidRow(
          column(6, actionButton(ns("save_message"), "Save Message to BigQuery", 
                                class = "btn-primary", icon = icon("save"), style = "width: 100%;")),
          column(6, actionButton(ns("copy_message"), "Copy to Clipboard", 
                                class = "btn-info", icon = icon("copy"), style = "width: 100%;"))
        ),
        br(),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'Email'", ns("comm_channel")),
          actionButton(ns("send_to_email_tab"), "Send Email", 
                       class = "btn-success", icon = icon("envelope"),
                       style = "width: 100%; margin-top: 10px;")
        ),
        br(),
        htmlOutput(ns("save_message_status"))
      )
    )
  )
}
