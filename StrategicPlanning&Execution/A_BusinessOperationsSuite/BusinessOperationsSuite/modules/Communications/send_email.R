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
          textInput(ns("email_cc"), "CC (optional, comma-separated):", placeholder = "colleague@example.com", width = "100%"),
          radioButtons(ns("mode"), NULL, inline = TRUE,
                       c("Regular email" = "regular", "Invite (calendar invitation)" = "invite")),
          textInput(ns("email_subject"), "Subject:", placeholder = "Enter subject", width = "100%"),
          br(),
          textAreaInput(ns("email_body"), "Message:", placeholder = "Type message...", height = "300px", width = "100%"),
          conditionalPanel(sprintf("input['%s'] == 'invite'", ns("mode")),
            hr(),
            h4(icon("calendar-check"), " Calendar invitation"),
            p("The email carries a calendar invitation (.ics): the recipient's email app shows ",
              tags$strong("Yes / No / Maybe"), " buttons and can add the meeting to their calendar. ",
              "Answers are emailed back to the sending mailbox (SMTP Settings). The same .ics is also attached as a file."),
            textInput(ns("inv_title"), "Meeting title (empty = the Subject)", value = "", width = "100%"),
            fluidRow(
              column(3, dateInput(ns("inv_date"), "Date", Sys.Date(), weekstart = 1)),
              column(2, textInput(ns("inv_start"), "Start (HH:MM)", "10:00")),
              column(2, numericInput(ns("inv_duration"), "Minutes", 60, min = 5, step = 5)),
              column(5, selectInput(ns("inv_tz"), "Time zone", BOS_TIMEZONES, selected = bos_tz_local_default()))
            ),
            textInput(ns("inv_location"), "Location / video-call link", value = "", width = "100%"),
            tags$details(tags$summary("Show the invitation (.ics) that will be sent"),
                         verbatimTextOutput(ns("ics_preview")))
          ),
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

    split_addr <- function(x) { a <- trimws(unlist(strsplit(x %||% "", "[,;]"))); a[nzchar(a)] }

    # the invitation, built from the form (NULL + message when something is missing)
    invite_text <- function() {
      title <- trimws(input$inv_title %||% ""); if (!nzchar(title)) title <- trimws(input$email_subject %||% "")
      if (!nzchar(title)) stop("Give the meeting a title (or a Subject).")
      if (is.null(input$inv_date) || is.na(input$inv_date)) stop("Pick the meeting date.")
      st <- trimws(input$inv_start %||% "")
      if (!grepl("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", st)) stop("Start time must be HH:MM, e.g. 10:00.")
      p <- as.integer(strsplit(st, ":")[[1]])
      dur <- suppressWarnings(as.integer(input$inv_duration)); if (is.na(dur) || dur < 5) dur <- 60L
      ics_invite_text(uid = paste0(uuid::UUIDgenerate(), "@business-operations-suite"), title = title,
                      date = as.Date(input$inv_date), start_min = p[1] * 60 + p[2], duration_min = dur,
                      tz = input$inv_tz, organizer_email = api_manager$smtp_username %||% "organizer@example.com",
                      to = split_addr(input$email_to), cc = split_addr(input$email_cc),
                      location = trimws(input$inv_location %||% ""), description = input$email_body %||% "")
    }
    output$ics_preview <- renderText({
      req(identical(input$mode, "invite"))
      tryCatch(invite_text(), error = function(e) paste("Not ready yet:", conditionMessage(e)))
    })

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
        to_addresses <- split_addr(input$email_to)
        cc_addresses <- split_addr(input$email_cc)
        calendar <- if (identical(input$mode, "invite")) list(text = invite_text(), method = "REQUEST", filename = "invite.ics") else NULL

        attachments <- NULL
        if (!is.null(input$email_attachments)) {
          attachments <- lapply(seq_len(nrow(input$email_attachments)), function(i) {
            list(path = input$email_attachments$datapath[i], name = input$email_attachments$name[i])
          })
        }

        api_manager$send_email(to = to_addresses, subject = input$email_subject, body = input$email_body,
                               attachments = attachments, cc = cc_addresses, calendar = calendar)

        removeNotification(id = "sending")
        showNotification(paste0(if (is.null(calendar)) "✓ Sent to: " else "✓ Invitation sent to: ",
                                paste(c(to_addresses, cc_addresses), collapse = ", ")), type = "message", duration = 5)

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
