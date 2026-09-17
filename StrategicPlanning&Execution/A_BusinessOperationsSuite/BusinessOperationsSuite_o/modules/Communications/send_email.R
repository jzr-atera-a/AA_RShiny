# modules/Communications/send_email.R
# Subtab: Send Email (under the "Communications" main tab)
# Prefilled automatically when arriving from Customise Communication's
# "Send Email" button (reads to/subject/body off the shared api_manager).

send_email_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Compose Email", status = "info", solidHeader = TRUE, width = 12,
          textInput(ns("email_to"), "To:", placeholder = "recipient@example.com", width = "100%"),
          helpText("Separate multiple addresses with commas"),
          textInput(ns("email_subject"), "Subject:", placeholder = "Enter subject", width = "100%"),
          br(),
          textAreaInput(ns("email_body"), "Message:", placeholder = "Type message...", height = "300px", width = "100%"),
          br(),
          div(class = "file-upload-box",
              fileInput(ns("email_attachments"), "Attach Files:", multiple = TRUE, buttonLabel = "Browse...", placeholder = "No files selected")),
          br(),
          fluidRow(column(12, actionButton(ns("send_email_btn"), "Send Email", icon = icon("paper-plane"),
                                            class = "btn-primary", width = "100%", style = "font-size: 18px; padding: 15px;")))
      )
    )
  )
}

send_email_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # Prefill whenever this tab becomes visible with pending handoff data
    observeEvent(api_manager$generated_message(), {
      msg <- api_manager$generated_message()
      if (!is.null(msg) && nchar(msg) > 0) {
        updateTextAreaInput(session, "email_body", value = msg)
        if (!is.null(api_manager$selected_contact_email())) {
          updateTextInput(session, "email_to", value = api_manager$selected_contact_email())
        }
        if (nchar(api_manager$pending_email_subject()) > 0) {
          updateTextInput(session, "email_subject", value = api_manager$pending_email_subject())
        }
      }
    }, ignoreInit = TRUE)

    observeEvent(input$send_email_btn, {
      if (!api_manager$smtp_connected) {
        showNotification("⚠ Open connection first in SMTP Configuration tab", type = "error", duration = 5)
        return()
      }
      if (input$email_to == "" || input$email_subject == "" || input$email_body == "") {
        showNotification("Fill To, Subject, Message", type = "error", duration = 5)
        return()
      }

      showNotification("📧 Sending...", type = "message", duration = NULL, id = "sending")

      tryCatch({
        to_addresses <- trimws(unlist(strsplit(input$email_to, ",")))

        attachments <- NULL
        if (!is.null(input$email_attachments)) {
          attachments <- lapply(seq_len(nrow(input$email_attachments)), function(i) {
            list(path = input$email_attachments$datapath[i], name = input$email_attachments$name[i])
          })
        }

        api_manager$send_email(to = to_addresses, subject = input$email_subject, body = input$email_body, attachments = attachments)

        removeNotification(id = "sending")
        showNotification(paste0("✓ Sent to: ", paste(to_addresses, collapse = ", ")), type = "message", duration = 5)

        updateTextInput(session, "email_to", value = "")
        updateTextInput(session, "email_subject", value = "")
        updateTextAreaInput(session, "email_body", value = "")

      }, error = function(e) {
        removeNotification(id = "sending")
        showNotification(paste("✗ Failed:", e$message), type = "error", duration = 7)
      })
    })
  })
}
