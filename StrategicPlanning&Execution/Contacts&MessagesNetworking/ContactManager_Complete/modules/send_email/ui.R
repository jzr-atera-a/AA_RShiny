# modules/send_email/ui.R
send_email_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Compose Email", 
        status = "info", 
        solidHeader = TRUE,
        width = 12,
        
        textInput(ns("email_to"), "To:", placeholder = "recipient@example.com", width = "100%"),
        helpText("Separate multiple addresses with commas"),
        textInput(ns("email_subject"), "Subject:", placeholder = "Enter subject", width = "100%"),
        br(),
        textAreaInput(ns("email_body"), "Message:", placeholder = "Type message...", 
                      height = "300px", width = "100%"),
        br(),
        div(class = "file-upload-box", 
            fileInput(ns("email_attachments"), "Attach Files:", 
                      multiple = TRUE, 
                      buttonLabel = "Browse...", 
                      placeholder = "No files selected")),
        br(),
        fluidRow(
          column(12, 
                 actionButton(ns("send_email_btn"), "Send Email", 
                             icon = icon("paper-plane"), 
                             class = "btn-primary", 
                             width = "100%", 
                             style = "font-size: 18px; padding: 15px;"))
        )
      )
    )
  )
}
