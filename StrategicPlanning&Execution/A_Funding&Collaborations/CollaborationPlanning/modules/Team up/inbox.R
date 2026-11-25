# ---- module ----------------------------------------------
# id:           inbox
# name:         Process emails
# icon:         inbox
# description:  Drop in partner emails: Claude finds the sender, the bid, their answer, documents sent and actions, and you apply the updates
# packages:     shiny
# -----------------------------------------------------------
# Builds on the email and contact processing in BOS (process_contact.R) and DaysPlanning (contacts_process.R),
# applied to bids: one email can update the person, the consortium status, documents received, tasks and the message log.

inbox_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Save an email from your mail app (.eml), or copy and paste it with its From and Subject lines. ",
         "Claude suggests what to update; nothing changes until you press Apply."),
    card("Email",
      layout_columns(col_widths = c(5, 7),
        fileInput(ns("file"), NULL, accept = c(".eml", ".txt", ".pdf", ".docx", ".msg"), buttonLabel = "Choose email file"),
        textAreaInput(ns("paste"), NULL, rows = 6, width = "100%",
                      placeholder = "From: Dr Ana Ruiz <ana.ruiz@uni.example>\nSubject: Re: CAM Pathfinder bid\n\nHappy to join as a partner. Our letter of support is attached...")),
      actionButton(ns("read"), "Read the email", class = "btn-brand", icon = icon("wand-magic-sparkles")),
      uiOutput(ns("read_status"))),
    uiOutput(ns("proposal")))
}

inbox_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    got <- reactiveVal(NULL)

    observeEvent(input$read, {
      txt <- trimws(paste(upload_text(input$file), input$paste %||% "", sep = "\n"))
      if (!nzchar(txt)) return(output$read_status <- renderUI(note("warn", "Choose a file or paste an email first.")))
      head <- eml_parse(txt)
      from_email <- tolower(regmatches(head$from, regexpr("[^<> \"]+@[^<> \"]+", head$from)) %||% "")
      from_name <- trimws(gsub('"', "", sub("<.*$", "", head$from)))
      p <- ctx$programmes(); p <- p[p$stage %in% STAGES[2:7], , drop = FALSE]
      cons <- ctx$data$consortium()
      base <- list(text = txt, sender = list(name = from_name, email = from_email), programme_id = "", intent = "other",
                   documents_received = character(0), action_items = data.frame(), summary = "", subject = head$subject)
      # a sender already in one bid points to that bid
      inb <- unique(cons$programme_id[cons$email == from_email & nzchar(from_email)])
      if (length(inb) == 1) base$programme_id <- inb
      if (!claude_ready()) {
        got(base)
        return(output$read_status <- renderUI(note("warn", "No Claude API key is set, so only the sender was read. Fill in the rest below.")))
      }
      prog_list <- paste(sprintf("- %s: %s (%s)", p$programme_id, p$programme_name, p$funder), collapse = "\n")
      owed <- paste(unique(unlist(lapply(cons$documents_owed[cons$email == from_email], split_list))), collapse = "; ")
      prompt <- paste0("You help a small team manage funding bids with partners. Read this email and reply with JSON only:\n",
        '{"sender": {"name": "", "email": "", "organisation": "", "role_title": "", "phone": "", "linkedin": "", "country": ""},\n',
        ' "programme_id": "id from the list below, or empty if none fits",\n',
        ' "intent": "interested" or "committed" or "declined" or "question" or "document" or "other",\n',
        ' "documents_received": ["names of documents attached or promised as sent, e.g. Letter of support"],\n',
        ' "action_items": [{"task": "short task for our team", "due": "YYYY-MM-DD or empty"}],\n',
        ' "summary": "two plain sentences", "reply_needed": true or false}\n\n',
        "Bids we are working on:\n", if (nzchar(prog_list)) prog_list else "(none)", "\n",
        if (nzchar(owed)) paste0("Documents this sender owes us: ", owed, "\n"),
        "Use only what the email says. 'committed' means they clearly agree to be in the bid; 'interested' means positive but not final.\n\nEMAIL:\n",
        substr(txt, 1, 25000))
      res <- withProgress(message = "Reading the email...", tryCatch(claude_json(prompt, max_tokens = 2000, simplify = TRUE),
                          error = function(e) list(error = safe_error_text(e))))
      if (!is.null(res$error)) { got(base); return(output$read_status <- renderUI(note("bad", res$error, " Fill in the details below by hand."))) }
      s <- res$sender %||% list()
      if (!nzchar(s$email %||% "")) s$email <- from_email
      if (!nzchar(s$name %||% "")) s$name <- from_name
      out <- base
      out$sender <- s; out$intent <- res$intent %||% "other"; out$summary <- res$summary %||% ""
      out$programme_id <- if ((res$programme_id %||% "") %in% p$programme_id) res$programme_id else base$programme_id
      out$documents_received <- as.character(unlist(res$documents_received %||% character(0)))
      out$action_items <- if (is.data.frame(res$action_items)) res$action_items else data.frame()
      out$reply_needed <- isTRUE(res$reply_needed)
      got(out)
      output$read_status <- renderUI(note("ok", "Read. Check the suggestions below and untick anything you do not want."))
    })

    output$proposal <- renderUI({
      g <- got(); req(g)
      s <- g$sender; p <- ctx$programmes()
      cons <- ctx$data$consortium()
      mem <- cons[cons$programme_id == g$programme_id & cons$email == tolower(s$email %||% ""), , drop = FALSE]
      owed <- if (nrow(mem)) split_list(mem$documents_owed) else character(0)
      docs <- unique(c(owed, g$documents_received))
      known <- tolower(s$email %||% "") %in% ctx$data$people()$email
      new_status <- switch(g$intent, committed = "committed", interested = "interested", declined = "declined", if (nrow(mem)) mem$status else "asked")
      ai <- g$action_items
      tagList(
        if (nzchar(g$summary)) card("Summary", p(g$summary), if (isTRUE(g$reply_needed)) span(class = "pill pill-warn", "Reply needed")),
        card("1. The sender",
          checkboxInput(ns("do_person"), if (known) "Update this person in Collaborators" else "Add this person to Collaborators", TRUE),
          layout_columns(col_widths = c(4, 4, 4),
            textInput(ns("s_name"), "Name", s$name %||% "", width = "100%"),
            textInput(ns("s_email"), "Email", s$email %||% "", width = "100%"),
            textInput(ns("s_org"), "Organisation", s$organisation %||% "", width = "100%")),
          layout_columns(col_widths = c(4, 4, 4),
            textInput(ns("s_role"), "Job title", s$role_title %||% "", width = "100%"),
            textInput(ns("s_phone"), "Phone", s$phone %||% "", width = "100%"),
            textInput(ns("s_linkedin"), "LinkedIn", s$linkedin %||% "", width = "100%"))),
        card("2. The bid",
          selectInput(ns("pid"), "Which bid is this about?", programme_choices(p, STAGES[2:7], none = "(none: just log the email)"),
                      selected = g$programme_id, width = "100%"),
          checkboxInput(ns("do_log"), "Save the email to the message history", TRUE),
          checkboxInput(ns("do_cons"), "Update their place in the consortium", g$intent %in% c("committed", "interested", "declined") || nrow(mem) > 0),
          layout_columns(col_widths = c(4, 4, 4),
            selectInput(ns("c_status"), "Status", CONSORTIUM_STATUS, new_status),
            selectInput(ns("c_role"), "Role", CONSORTIUM_ROLES, if (nrow(mem)) mem$role else "partner"),
            div()),
          if (length(docs)) checkboxGroupInput(ns("c_docs"), "Documents received", docs,
                                                selected = unique(c(g$documents_received, if (nrow(mem)) split_list(mem$documents_received))), inline = TRUE)),
        if (nrow(ai)) card("3. Actions for us",
          p(class = "small muted", "Added as tasks to the bid's project (when it has one), under \"Actions from emails\"."),
          checkboxGroupInput(ns("do_tasks"), NULL, choiceNames = sprintf("%s%s", ai$task, ifelse(nzchar(ai$due %||% ""), paste0(" (by ", ai$due, ")"), "")),
                             choiceValues = as.character(seq_len(nrow(ai))), selected = as.character(seq_len(nrow(ai))))),
        div(class = "btn-row",
            actionButton(ns("apply"), "Apply", class = "btn-brand", icon = icon("check")),
            actionButton(ns("reply"), "Write a reply in Outreach", class = "btn-ghost", icon = icon("reply"))))
    })

    observeEvent(input$apply, {
      g <- got(); req(g); u <- ctx$user(); done <- character(0)
      email <- tolower(trimws(input$s_email %||% ""))
      pid <- input$pid %||% ""
      person_id <- ""
      if (isTRUE(input$do_person) && (nzchar(email) || nzchar(input$s_name %||% ""))) {
        r <- upsert_person(list(name = input$s_name, email = email, organisation = input$s_org, role_title = input$s_role,
                                phone = input$s_phone, linkedin = input$s_linkedin, type = "partner", source = "Email"), u)
        person_id <- r$person_id; done <- c(done, if (r$new) "person added" else "person updated")
      }
      if (isTRUE(input$do_log)) {
        store_append("messages", data.frame(message_id = new_id("msg"), email = email, programme_id = pid, channel = "Email",
          purpose = g$intent, content = substr(g$text, 1, 40000), created_by = u, created_at = now_ts(), subject = g$subject %||% "",
          direction = "in", status = "received", detail = g$summary %||% "", stringsAsFactors = FALSE), user = u)
        done <- c(done, "email logged")
      }
      if (isTRUE(input$do_cons) && nzchar(pid) && nzchar(email)) {
        cons <- latest_consortium(store_read("consortium", fresh = TRUE))
        mem <- cons[cons$programme_id == pid & cons$email == email, , drop = FALSE]
        row <- if (nrow(mem)) mem[1, , drop = FALSE] else conform(data.frame(programme_id = pid, email = email, budget_share_pct = "",
                                                                             documents_owed = "Letter of support", stringsAsFactors = FALSE), "consortium")
        row$status <- input$c_status; row$role <- input$c_role
        row$documents_received <- paste(unique(c(split_list(row$documents_received), input$c_docs)), collapse = "; ")
        row$documents_owed <- paste(unique(c(split_list(row$documents_owed), input$c_docs)), collapse = "; ")
        row$name <- input$s_name %|% row$name; row$organisation <- input$s_org %|% row$organisation
        row$updated_at <- now_ts(); row$updated_by <- u
        store_append("consortium", row, user = u); done <- c(done, paste("consortium:", input$c_status))
        p <- ctx$programmes(); if (p$stage[p$programme_id == pid][1] %in% c("Discover", "Qualify")) move_programme_stage(pid, "Team up", u)
      }
      if (length(input$do_tasks) && nzchar(pid)) {
        pr <- ctx$data$projects(); proj <- pr$project_id[pr$programme_id == pid][1]
        if (!is.na(proj %||% NA)) {
          ai <- g$action_items[as.integer(input$do_tasks), , drop = FALSE]
          store_append("tasks", data.frame(task_id = vapply(seq_len(nrow(ai)), function(i) new_id("task"), ""), project_id = proj,
            work_package = "Actions from emails", task = ai$task, start_date = format(Sys.Date()),
            end_date = ifelse(grepl("^\\d{4}-\\d{2}-\\d{2}$", ai$due %||% ""), ai$due, format(Sys.Date() + 7)), owner_email = u,
            partner = input$s_org %||% "", status = "to do", trello_card_id = "", updated_at = now_ts(),
            description = paste("From email:", g$subject %||% ""), trello_url = "", deleted = "FALSE", updated_by = u,
            stringsAsFactors = FALSE), user = u)
          done <- c(done, sprintf("%d task(s) added", nrow(ai)))
        } else done <- c(done, "tasks skipped (this bid has no project yet)")
      }
      ctx$bump()
      output$read_status <- renderUI(note("ok", "Done: ", paste(done, collapse = "; "), "."))
      if (nzchar(person_id)) ctx$handoff$person <- person_id
      got(NULL); updateTextAreaInput(session, "paste", value = "")
    })
    observeEvent(input$reply, {
      ppl <- ctx$data$people(); hit <- ppl$person_id[ppl$email == tolower(input$s_email %||% "")]
      if (!length(hit)) return(showNotification("Apply first so the sender is saved, then write the reply.", type = "warning"))
      ctx$handoff$person <- hit[1]; ctx$handoff$programme <- input$pid; ctx$nav("teamup", "outreach")
    })
  })
}
