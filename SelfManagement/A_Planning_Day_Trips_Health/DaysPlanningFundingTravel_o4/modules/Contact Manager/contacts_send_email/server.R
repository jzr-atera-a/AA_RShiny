# modules/Contact Manager/contacts_send_email/server.R

contacts_send_email_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # Pre-populate from Customise Communication, but only into currently-empty
    # fields so we never clobber something the user is already editing.
    observe({
      api_manager$state_trigger_contacts()
      isolate({
        if (!is.null(api_manager$contacts_selected_contact_email) && input$email_to == "") {
          updateTextInput(session, "email_to", value = api_manager$contacts_selected_contact_email)
        }
        if (!is.null(api_manager$contacts_generated_message) && input$email_body == "") {
          updateTextAreaInput(session, "email_body", value = api_manager$contacts_generated_message)
        }
        if (input$email_subject == "" && !is.null(api_manager$contacts_selected_contact)) {
          subject <- paste("Following up -", api_manager$contacts_selected_contact$full_name %||% "")
          updateTextInput(session, "email_subject", value = subject)
        }
      })
    })

    observeEvent(input$send_email, {
      if (!api_manager$contacts_smtp_authenticated) {
        showNotification("Please configure and test SMTP in SMTP Config first!", type = "error"); return()
      }
      if (nchar(trimws(input$email_to)) == 0) { showNotification("Please enter a recipient.", type = "error"); return() }

      output$send_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Sending...") })

      tryCatch({
        to_list <- trimws(strsplit(input$email_to, ",")[[1]])
        cc_list <- if (nchar(trimws(input$email_cc)) > 0) trimws(strsplit(input$email_cc, ",")[[1]]) else NULL

        attachments <- NULL
        if (!is.null(input$email_attachments)) {
          attachments <- lapply(seq_len(nrow(input$email_attachments)), function(i) {
            list(path = input$email_attachments$datapath[i], name = input$email_attachments$name[i])
          })
        }

        api_manager$send_email_via_curl(
          host = api_manager$contacts_smtp_host, port = api_manager$contacts_smtp_port,
          user = api_manager$contacts_smtp_user, password = api_manager$contacts_smtp_password,
          from = api_manager$contacts_smtp_user, to = to_list, subject = input$email_subject,
          body = input$email_body, cc = cc_list, attachments = attachments
        )

        output$send_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Email sent successfully!")
        })
        showNotification("✓ Email sent!", type = "message")

      }, error = function(e) {
        output$send_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$send_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
