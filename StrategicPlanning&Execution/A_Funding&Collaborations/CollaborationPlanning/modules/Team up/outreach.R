# ---- module ----------------------------------------------
# id:           outreach
# name:         Outreach
# icon:         envelope
# description:  Claude drafts a message for a person and a bid by channel and purpose; send it by email, with an optional meeting invite
# packages:     shiny, DT
# -----------------------------------------------------------
# Ported from BOS customise_communication.R + send_email.R and DaysPlanning contacts_send_email.R (SMTP over curl,
# calendar invites with Yes / No / Maybe). Every message is saved to the messages table with its programme.

outreach_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("mail_note")),
    layout_columns(col_widths = c(5, 7),
      tagList(
        card("Who and why",
          selectizeInput(ns("person"), "Person", NULL, options = list(placeholder = "Choose a person from Collaborators...")),
          selectInput(ns("pid"), "About this bid (optional)", NULL, width = "100%"),
          layout_columns(col_widths = c(6, 6),
            selectInput(ns("channel"), "Channel", c("Email", "LinkedIn", "WhatsApp", "General message")),
            selectInput(ns("purpose"), "Purpose", c("Introduction", "Invite to join a bid", "Follow up", "Ask for a document",
                                                    "Thank you", "Met at a recent event", "Other"))),
          layout_columns(col_widths = c(6, 6),
            selectInput(ns("language"), "Language", c("English UK", "English US", "Spanish (Latin America)", "French", "German")),
            selectInput(ns("length"), "Length (words)", c("50", "100", "180", "240", "400"), "180")),
          textAreaInput(ns("guide"), "Points to include", rows = 3, width = "100%",
                        placeholder = "e.g. mention the CAM Pathfinder call closes on 14 Jan; ask for a letter of support by 5 Jan"),
          actionButton(ns("draft"), "Draft with Claude", class = "btn-brand", icon = icon("robot"))),
        card("Earlier messages to this person", uiOutput(ns("history")))),
      card("Message",
        textInput(ns("to"), "To", width = "100%"),
        textInput(ns("cc"), "Cc (separated by commas)", width = "100%"),
        textInput(ns("subject"), "Subject", width = "100%"),
        textAreaInput(ns("body"), NULL, rows = 14, width = "100%"),
        checkboxInput(ns("invite"), "Add a meeting invitation (they can answer Yes / No / Maybe)", FALSE),
        conditionalPanel(sprintf("input['%s']", ns("invite")),
          layout_columns(col_widths = c(4, 3, 2, 3),
            dateInput(ns("m_date"), "Date", Sys.Date() + 7, weekstart = 1),
            textInput(ns("m_time"), "Start (HH:MM, UK time)", "10:00"),
            numericInput(ns("m_min"), "Minutes", 30, min = 5, step = 5),
            textInput(ns("m_loc"), "Where or link", ""))),
        fileInput(ns("att"), "Attachments (optional)", multiple = TRUE),
        div(class = "btn-row",
            actionButton(ns("save"), "Save as draft", class = "btn-ghost", icon = icon("floppy-disk")),
            actionButton(ns("send"), "Send email", class = "btn-brand", icon = icon("paper-plane"))),
        uiOutput(ns("status")))))
}

outreach_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    msgs <- ctx$table("messages")
    output$mail_note <- renderUI(if (!smtp_ready(ctx$settings()))
      note("info", "Email sending is not set up yet, so you can draft and save, then copy the text. An admin can set it up in Admin > Email."))
    observe({
      ppl <- ctx$data$people(); ppl <- ppl[order(ppl$name), , drop = FALSE]
      ch <- if (nrow(ppl)) setNames(ppl$person_id, paste0(ppl$name %|% ppl$email, " - ", ppl$organisation)) else character(0)
      updateSelectizeInput(session, "person", choices = ch,
                           selected = pick_sel(isolate(input$person), ch, ctx$handoff$person))
      pc <- programme_choices(ctx$programmes(), STAGES[-length(STAGES)], none = "(no specific bid)")
      updateSelectInput(session, "pid", choices = pc, selected = pick_sel(isolate(input$pid), pc, ctx$handoff$programme))
    })
    observeEvent(ctx$handoff$person, updateSelectizeInput(session, "person", selected = ctx$handoff$person), ignoreNULL = TRUE)
    observeEvent(ctx$handoff$programme, updateSelectInput(session, "pid", selected = ctx$handoff$programme), ignoreNULL = TRUE)
    person <- reactive({ ppl <- ctx$data$people(); ppl[ppl$person_id == (input$person %||% ""), , drop = FALSE] })
    observeEvent(input$person, { r <- person(); if (nrow(r)) updateTextInput(session, "to", value = r$email) })

    output$history <- renderUI({
      r <- person(); req(nrow(r) > 0)
      m <- msgs(); m <- m[tolower(m$email) == r$email & nzchar(r$email), , drop = FALSE]
      if (!nrow(m)) return(p(class = "small muted", "No messages yet."))
      m <- utils::head(m[order(m$created_at, decreasing = TRUE), , drop = FALSE], 3)
      tagList(lapply(seq_len(nrow(m)), function(i) div(class = "res-card",
        div(class = "small muted", m$created_at[i], " - ", m$channel[i], " - ", m$direction[i] %|% "out", " - ", m$status[i] %|% "draft"),
        tags$b(m$subject[i]), div(class = "small", substr(m$content[i], 1, 400)))))
    })

    observeEvent(input$draft, {
      r <- person(); if (!nrow(r)) return(showNotification("Choose a person first.", type = "warning"))
      if (!claude_ready()) return(output$status <- renderUI(note("bad", "No Claude API key is set (Admin > Claude API).")))
      p <- ctx$programmes(); pr <- p[p$programme_id == (input$pid %||% ""), , drop = FALSE]
      m <- msgs(); m <- m[tolower(m$email) == r$email & nzchar(r$email), , drop = FALSE]
      m <- utils::head(m[order(m$created_at, decreasing = TRUE), , drop = FALSE], 3)
      prompt <- paste0("Write a ", input$channel, " message to ", r$name %|% "this person", " (", r$role_title, " at ", r$organisation, ").\n",
        "Purpose: ", input$purpose, ". Language: ", input$language, ". About ", input$length, " words.\n",
        "Their interests: ", r$interests, ". Their past projects: ", r$past_projects, ".\n",
        if (nrow(pr)) paste0("The bid: ", pr$programme_name, " from ", pr$funder, ". ", pr$summary, " Closes: ", pr$closes_date %|% pr$deadline_text, ".\n"),
        "About us: ", ctx$settings()$company_profile %|% "(not given)", "\n",
        "Sender: ", ctx$auth$name(), ".\n",
        if (nrow(m)) paste0("Earlier messages (latest first):\n", paste(substr(m$content, 1, 500), collapse = "\n---\n"), "\n"),
        "Points to include: ", input$guide %|% "none", "\n\n",
        if (input$channel == "Email") "Reply with the subject on the first line as 'Subject: ...', then a blank line, then the message.\n" else "",
        "Plain, friendly and specific. No preamble, no placeholders in square brackets.")
      res <- withProgress(message = "Drafting...", tryCatch(claude_call(prompt, max_tokens = 1500)$text, error = function(e) structure(safe_error_text(e), class = "err")))
      if (inherits(res, "err")) return(output$status <- renderUI(note("bad", res)))
      subj <- ""; body <- res
      if (grepl("^\\s*Subject:", res)) { subj <- trimws(sub("^\\s*Subject:\\s*", "", strsplit(res, "\n")[[1]][1])); body <- trimws(sub("^[^\n]*\n", "", res)) }
      if (!nzchar(subj)) subj <- paste0(input$purpose, if (nrow(pr)) paste(" -", pr$programme_name))
      updateTextInput(session, "subject", value = subj); updateTextAreaInput(session, "body", value = body)
      output$status <- renderUI(note("ok", "Draft ready. Edit it, then save or send."))
    })

    save_msg <- function(status, detail = "") {
      r <- person()
      store_append("messages", data.frame(message_id = new_id("msg"), email = tolower(trimws(input$to %|% (r$email[1] %||% ""))),
        programme_id = input$pid %||% "", channel = input$channel, purpose = input$purpose, content = input$body %||% "",
        created_by = ctx$user(), created_at = now_ts(), subject = input$subject %||% "", direction = "out", status = status,
        detail = detail, stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump()
    }
    observeEvent(input$save, {
      if (!nzchar(trimws(input$body %||% ""))) return(showNotification("Write or draft the message first.", type = "warning"))
      save_msg("draft"); output$status <- renderUI(note("ok", "Saved as a draft."))
    })
    observeEvent(input$send, {
      if (!nzchar(trimws(input$body %||% ""))) return(showNotification("Write or draft the message first.", type = "warning"))
      if (input$channel != "Email") return(showNotification(paste0("Only email can be sent from here. Save it and send it yourself on ", input$channel, "."), type = "warning"))
      cal <- NULL
      res <- tryCatch({
        conf <- smtp_config(ctx$settings())
        if (isTRUE(input$invite)) cal <- list(method = "REQUEST", filename = "invite.ics",
          text = meeting_ics(input$subject %|% "Meeting", paste(format(input$m_date), trimws(input$m_time)), num(input$m_min),
                             conf$user, split_emails(c(input$to, input$cc)), input$m_loc %||% "", input$body))
        atts <- if (!is.null(input$att)) lapply(seq_len(nrow(input$att)), function(i) list(path = input$att$datapath[i], name = input$att$name[i]))
        withProgress(message = "Sending...", send_mail(input$to, input$subject, input$body, cc = input$cc, attachments = atts, calendar = cal, conf = conf))
        NULL
      }, error = function(e) safe_error_text(e))
      if (is.null(res)) {
        save_msg("sent", if (!is.null(cal)) "with meeting invite" else "")
        output$status <- renderUI(note("ok", "Sent", if (!is.null(cal)) " with a meeting invitation", ". Saved to the message history."))
      } else {
        save_msg("failed", res); output$status <- renderUI(note("bad", res))
      }
    })
  })
}
