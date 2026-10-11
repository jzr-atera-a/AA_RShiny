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

    output$sender_info <- renderUI({
      st <- api_manager$titan_state()
      sm <- api_manager$titan_smtp()
      if (!isTRUE(st$ok)) {
        return(div(class = "status-warning", icon("lock"), " Not signed in. Open ",
                   tags$strong("API Configuration > Titan Authentication"), " and load authenticateT.R: the same Titan account sends the email."))
      }
      div(class = "status-info", icon("envelope"), " Sending as ", tags$strong(st$email), " through Titan (",
          sm$host, ":", sm$port, ").",
          if (!isTRUE(api_manager$titan_smtp_ok())) tags$small(" Not tested yet - use Test email login in Titan Authentication if sending fails."))
    })

    observeEvent(input$send_email, {
      st <- api_manager$titan_state()
      if (!isTRUE(st$ok) || is.null(api_manager$titan_pass)) {
        showNotification("Sign in to Titan first (API Configuration > Titan Authentication).", type = "error"); return()
      }
      if (nchar(trimws(input$email_to)) == 0) { showNotification("Please enter a recipient.", type = "error"); return() }
      sm <- api_manager$titan_smtp()
      if (!nzchar(sm$host)) { showNotification("No SMTP server set (Titan Authentication > Email Sending).", type = "error"); return() }

      output$send_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Sending...") })

      tryCatch({
        to_list <- trimws(strsplit(input$email_to, "[,;]")[[1]])
        cc_list <- if (nchar(trimws(input$email_cc)) > 0) trimws(strsplit(input$email_cc, "[,;]")[[1]]) else NULL

        attachments <- NULL
        if (!is.null(input$email_attachments)) {
          attachments <- lapply(seq_len(nrow(input$email_attachments)), function(i) {
            list(path = input$email_attachments$datapath[i], name = input$email_attachments$name[i])
          })
        }

        titan_send_mail(user = st$email, pass = api_manager$titan_pass, host = sm$host, port = sm$port,
                        to = to_list, subject = input$email_subject, body = input$email_body,
                        cc = cc_list, attachments = attachments)
        api_manager$titan_log_add(sprintf("Email sent to %d recipient(s) via %s", length(c(to_list, cc_list)), sm$host))

        output$send_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Email sent successfully!")
        })
        showNotification("Email sent.", type = "message")

      }, error = function(e) {
        api_manager$titan_log_add(paste0("Email failed: ", conditionMessage(e)))
        output$send_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " ", conditionMessage(e)) })
        showNotification(conditionMessage(e), type = "error", duration = 10)
      })
    })

    output$send_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
