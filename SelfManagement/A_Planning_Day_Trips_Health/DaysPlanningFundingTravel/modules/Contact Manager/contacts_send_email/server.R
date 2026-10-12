# modules/Contact Manager/contacts_send_email/server.R
# Sends through the Titan mailbox loaded in API Configuration > Titan Authentication.

contacts_send_email_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current_uid <- reactiveVal(NULL)          # UID of the invite draft being edited (same UID as the Titan event)
    extra_zone <- reactiveVal(NULL)

    split_addr <- function(x) {
      v <- trimws(strsplit(as.character(x %||% ""), "[,;]")[[1]])
      v[nzchar(v)]
    }
    # the always-copied address is added when missing (case-insensitive), never duplicated
    cc_with_always <- function(cc) {
      cc <- split_addr(paste(cc, collapse = ","))
      if (!tolower(BOS_ALWAYS_CC) %in% tolower(cc)) cc <- c(cc, BOS_ALWAYS_CC)
      unique(cc)
    }

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

    # ---- invite drafts (from Events to Calendar) ----
    load_draft <- function(d) {
      current_uid(d$uid)
      z <- bos_tz_value(d$tz)
      extra_zone(if (z %in% TITAN_TIMEZONES) NULL else z)
      ch <- if (z %in% TITAN_TIMEZONES) TITAN_TIMEZONES else c(TITAN_TIMEZONES, setNames(z, paste0(z, " (from invite)")))
      updateRadioButtons(session, "mode", selected = "invite")
      updateTextInput(session, "email_to", value = paste(d$to, collapse = ", "))
      updateTextInput(session, "email_cc", value = paste(cc_with_always(d$cc), collapse = ", "))
      updateTextInput(session, "email_subject", value = d$subject)
      updateTextAreaInput(session, "email_body", value = d$body)
      updateTextInput(session, "inv_title", value = d$title)
      updateDateInput(session, "inv_date", value = d$date)
      updateTextInput(session, "inv_start", value = d$start)
      updateNumericInput(session, "inv_duration", value = d$duration)
      updateSelectInput(session, "inv_tz", choices = ch, selected = z)
      updateTextInput(session, "inv_location", value = d$location)
      updateTextAreaInput(session, "inv_join", value = d$join)
    }

    observeEvent(api_manager$mail_drafts(), {
      dr <- api_manager$mail_drafts()
      if (length(dr)) load_draft(dr[[length(dr)]])
    }, ignoreInit = TRUE)

    output$draft_picker <- renderUI({
      dr <- api_manager$mail_drafts()
      if (length(dr) < 2) return(NULL)
      selectInput(session$ns("draft_pick"), "Invites waiting to be sent",
                  setNames(vapply(dr, function(d) d$uid, ""), vapply(dr, function(d) d$title, "")),
                  selected = current_uid())
    })
    observeEvent(input$draft_pick, {
      for (d in api_manager$mail_drafts()) if (identical(d$uid, input$draft_pick)) { load_draft(d); break }
    }, ignoreInit = TRUE)

    # ---- the invitation .ics from the fields on screen ----
    build_ics <- function(organizer, to, cc) {
      title <- trimws(input$inv_title %||% "")
      if (!nzchar(title)) stop("Give the meeting a title.")
      if (is.null(input$inv_date) || is.na(input$inv_date)) stop("Pick the meeting date.")
      st <- trimws(input$inv_start %||% "")
      m <- regmatches(st, regexec("^([01]?[0-9]|2[0-3]):([0-5][0-9])$", st))[[1]]
      if (length(m) < 3) stop("Start time must be HH:MM, e.g. 17:45.")
      dur <- input$inv_duration
      if (is.null(dur) || is.na(dur) || dur <= 0) stop("Duration must be more than 0 minutes.")
      loc <- trimws(input$inv_location %||% ""); join <- input$inv_join %||% ""
      url <- if (grepl("^https://", loc)) loc else regmatches(join, regexpr("https://[^[:space:]]+", join))
      if (!length(url)) url <- ""
      zoom_invite_ics(uid = current_uid() %||% titan_new_uid(), title = title, date = as.Date(input$inv_date),
                      start_min = as.integer(m[2]) * 60L + as.integer(m[3]), duration_min = as.integer(dur),
                      tz = input$inv_tz, organizer_email = organizer, to = to, cc = cc,
                      location = loc, description = join, url = url)
    }

    output$ics_preview <- renderText({
      st <- api_manager$titan_state()
      org <- if (isTRUE(st$ok)) st$email else "(your Titan address)"
      r <- tryCatch(build_ics(org, split_addr(input$email_to), cc_with_always(input$email_cc)),
                    error = function(e) paste0("(not ready: ", conditionMessage(e), ")"))
      gsub("\r\n", "\n", r)
    })

    output$sender_info <- renderUI({
      st <- api_manager$titan_state()
      sm <- api_manager$titan_smtp()
      if (!isTRUE(st$ok)) {
        return(div(class = "status-warning", icon("lock"), " Not signed in. Open ",
                   tags$strong("API Configuration > Titan Authentication"), " and load authenticateT.R: the same Titan account sends the email."))
      }
      div(class = "status-info", icon("envelope"), " Sending as ", tags$strong(st$email), " through Titan (",
          sm$host, ":", sm$port, "). Answers to invitations arrive in this mailbox.",
          if (!isTRUE(api_manager$titan_smtp_ok())) tags$small(" Not tested yet - use Test email login in Titan Authentication if sending fails."))
    })

    observeEvent(input$send_email, {
      st <- api_manager$titan_state()
      if (!isTRUE(st$ok) || is.null(api_manager$titan_pass)) {
        showNotification("Sign in to Titan first (API Configuration > Titan Authentication).", type = "error"); return()
      }
      to_list <- split_addr(input$email_to)
      if (!length(to_list)) { showNotification("Please enter a recipient.", type = "error"); return() }
      sm <- api_manager$titan_smtp()
      if (!nzchar(sm$host)) { showNotification("No SMTP server set (Titan Authentication > Email Sending).", type = "error"); return() }
      cc_list <- cc_with_always(input$email_cc)
      invite <- identical(input$mode, "invite")

      calendar <- NULL
      if (invite) {
        txt <- tryCatch(build_ics(st$email, to_list, cc_list), error = function(e) e)
        if (inherits(txt, "error")) { showNotification(conditionMessage(txt), type = "error", duration = 8); return() }
        calendar <- list(text = txt, method = "REQUEST", filename = "invite.ics")
      }

      output$send_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Sending...") })

      tryCatch({
        attachments <- NULL
        if (!is.null(input$email_attachments)) {
          attachments <- lapply(seq_len(nrow(input$email_attachments)), function(i) {
            list(path = input$email_attachments$datapath[i], name = input$email_attachments$name[i])
          })
        }

        titan_send_mail(user = st$email, pass = api_manager$titan_pass, host = sm$host, port = sm$port,
                        to = to_list, subject = input$email_subject, body = input$email_body,
                        cc = cc_list, attachments = attachments, calendar = calendar)
        api_manager$titan_log_add(sprintf("%s sent to %d recipient(s) via %s",
                                          if (invite) "Calendar invite" else "Email", length(c(to_list, cc_list)), sm$host))
        if (invite && !is.null(current_uid())) {          # this invite is done
          api_manager$mail_drafts(Filter(function(d) !identical(d$uid, current_uid()), api_manager$mail_drafts()))
          current_uid(NULL)
        }

        output$send_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   if (invite) " Invitation sent. Recipients can answer Yes or No from their email app; answers arrive in your Titan mailbox."
                   else " Email sent successfully!")
        })
        showNotification(if (invite) "Invitation sent." else "Email sent.", type = "message")

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
