# ---- module ----------------------------------------------
# id:           collaborators
# name:         Collaborators
# icon:         address-book
# description:  Add people from a CV, signature or pasted text (Claude reads them), browse and filter, invite partners to sign in
# packages:     shiny, DT
# -----------------------------------------------------------
# Ported from BOS modules/Communications/process_contact.R and explore_contacts.R
# (and DaysPlanning Contact Manager contacts_process.R / contacts_explore.R). Saves to the people table.

collaborators_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card("Add a person",
      p(class = "small muted", "Upload a CV, email signature or saved email (PDF, Word, .eml, .txt), or paste text. ",
        "Claude fills in the fields; check them before saving. You can also type them in directly."),
      layout_columns(col_widths = c(5, 7),
        fileInput(ns("file"), NULL, accept = c(".pdf", ".docx", ".txt", ".eml", ".md"), buttonLabel = "Choose file"),
        textAreaInput(ns("paste"), NULL, rows = 3, width = "100%", placeholder = "Or paste a bio, signature or LinkedIn text...")),
      actionButton(ns("extract"), "Read with Claude", class = "btn-ghost", icon = icon("robot")),
      uiOutput(ns("extract_status")),
      tags$hr(),
      uiOutput(ns("form")),
      div(class = "btn-row",
          selectInput(ns("type"), "Type", c("Partner" = "partner", "Contact" = "contact", "Team" = "team"), width = "160px"),
          actionButton(ns("save"), "Save person", class = "btn-brand", icon = icon("floppy-disk")),
          actionButton(ns("clear"), "Clear", class = "btn-ghost"))),
    card("People",
      layout_columns(col_widths = c(3, 9),
        selectInput(ns("f_type"), "Type", c("All", "partner", "contact", "team")),
        textInput(ns("f_text"), "Search name, organisation, interests or projects", width = "100%")),
      DTOutput(ns("table")),
      uiOutput(ns("row_actions"))))
}

collaborators_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    form_vals <- reactiveVal(setNames(as.list(rep("", length(CONTACT_FIELDS))), names(CONTACT_FIELDS)))
    editing <- reactiveVal("")

    output$form <- renderUI({
      v <- form_vals()
      tagList(
        if (nzchar(editing())) note("info", "Editing an existing person. Saving updates them."),
        do.call(layout_columns, c(list(col_widths = c(4, 4, 4)),
          lapply(c("name", "email", "organisation"), function(k) textInput(ns(paste0("f_", k)), CONTACT_FIELDS[[k]], v[[k]], width = "100%")))),
        do.call(layout_columns, c(list(col_widths = c(3, 3, 3, 3)),
          lapply(c("role_title", "country", "phone", "linkedin"), function(k) textInput(ns(paste0("f_", k)), CONTACT_FIELDS[[k]], v[[k]], width = "100%")))),
        lapply(c("interests", "past_projects", "notes"), function(k)
          textAreaInput(ns(paste0("f_", k)), CONTACT_FIELDS[[k]], v[[k]], rows = 2, width = "100%")))
    })

    observeEvent(input$extract, {
      txt <- paste(upload_text(input$file), input$paste %||% "")
      if (!nzchar(trimws(txt))) return(output$extract_status <- renderUI(note("warn", "Choose a file or paste some text first.")))
      if (!claude_ready()) return(output$extract_status <- renderUI(note("bad", "No Claude API key is set. Type the details in below instead.")))
      res <- withProgress(message = "Reading the text...", tryCatch(extract_contact(txt), error = function(e) list(error = safe_error_text(e))))
      if (!is.null(res$error)) return(output$extract_status <- renderUI(note("bad", res$error)))
      editing(""); form_vals(res)
      ppl <- ctx$data$people()
      dup <- nzchar(res$email) && tolower(res$email) %in% ppl$email
      output$extract_status <- renderUI(note(if (dup) "warn" else "ok", "Read. Check the fields, then save.",
                                             if (dup) " Someone with this email is already saved: saving will update them."))
    })

    current_form <- function() setNames(lapply(names(CONTACT_FIELDS), function(k) input[[paste0("f_", k)]] %||% ""), names(CONTACT_FIELDS))

    observeEvent(input$save, {
      f <- current_form()
      if (!nzchar(trimws(f$name)) && !nzchar(trimws(f$email))) return(showNotification("Add at least a name or an email.", type = "warning"))
      if (nzchar(f$email) && !valid_email(trimws(f$email))) return(showNotification("That email does not look right.", type = "warning"))
      f$type <- input$type; f$source <- if (!is.null(input$file)) paste("File:", input$file$name) else if (nzchar(input$paste %||% "")) "Pasted text" else "Typed in"
      if (nzchar(editing())) { f$person_id <- editing(); f$source <- NULL }
      r <- if (nzchar(editing())) {
        row <- ctx$data$people(); row <- row[row$person_id == editing(), , drop = FALSE]
        for (k in names(f)) row[[k]] <- f[[k]]; row$email <- tolower(row$email); row$updated_at <- now_ts()
        store_append("people", row, user = ctx$user()); list(new = FALSE)
      } else upsert_person(f, ctx$user())
      ctx$bump(); editing("")
      form_vals(setNames(as.list(rep("", length(CONTACT_FIELDS))), names(CONTACT_FIELDS)))
      updateTextAreaInput(session, "paste", value = "")
      showNotification(if (r$new) "Person saved." else "Person updated.", type = "message")
    })
    observeEvent(input$clear, { editing(""); form_vals(setNames(as.list(rep("", length(CONTACT_FIELDS))), names(CONTACT_FIELDS))) })

    shown <- reactive({
      d <- ctx$data$people()
      if (!identical(input$f_type, "All")) d <- d[d$type == input$f_type, , drop = FALSE]
      q <- tolower(trimws(input$f_text %||% ""))
      if (nzchar(q)) d <- d[grepl(q, tolower(paste(d$name, d$organisation, d$interests, d$past_projects, d$role_title)), fixed = TRUE), , drop = FALSE]
      d[order(d$name), , drop = FALSE]
    })
    output$table <- renderDT({
      d <- shown(); u <- get_users()
      d$can_sign_in <- ifelse(d$email %in% u$email[!(toupper(u$active) %in% c("FALSE", "PENDING"))], "yes", "")
      out <- d[, c("name", "organisation", "role_title", "email", "type", "interests", "can_sign_in")]
      names(out) <- c("Name", "Organisation", "Role", "Email", "Type", "Interests", "Can sign in")
      datatable(out, rownames = FALSE, selection = "single", options = list(dom = "tip", pageLength = 10, scrollX = TRUE))
    })
    sel <- reactive({ i <- input$table_rows_selected; if (length(i)) shown()[i, , drop = FALSE] else NULL })
    output$row_actions <- renderUI({
      r <- sel(); req(r)
      div(class = "btn-row",
          actionButton(ns("edit"), "Edit", class = "btn-ghost", icon = icon("pen")),
          actionButton(ns("outreach"), "Write to them", class = "btn-ghost", icon = icon("envelope")),
          if (ctx$admin_ok()) actionButton(ns("invite"), "Invite to sign in (partner)", class = "btn-brand", icon = icon("user-plus"))
          else span(class = "small muted", "An admin (with Admin unlocked) can invite this person to sign in."),
          actionButton(ns("remove"), "Remove", class = "btn-ghost", icon = icon("trash")))
    })
    observeEvent(input$edit, { r <- sel(); req(r); editing(r$person_id); form_vals(as.list(r[names(CONTACT_FIELDS)]))
      updateSelectInput(session, "type", selected = r$type) })
    observeEvent(input$outreach, { r <- sel(); req(r); ctx$handoff$person <- r$person_id; ctx$nav("teamup", "outreach") })
    observeEvent(input$remove, {
      r <- sel(); req(r); r$deleted <- "TRUE"; r$updated_at <- now_ts()
      store_append("people", r, user = ctx$user()); ctx$bump(); showNotification("Removed.", type = "message")
    })
    observeEvent(input$invite, {
      req(ctx$admin_ok()); r <- sel(); req(r)
      if (!valid_email(r$email)) return(showNotification("This person has no valid email.", type = "warning"))
      all <- store_read("allowed_emails", fresh = TRUE)
      if (r$email %in% tolower(all$email)) return(showNotification("Already on the sign-in list.", type = "message"))
      store_append("allowed_emails", data.frame(email = r$email, role = "partner", name = r$name, organisation = r$organisation,
        interests = r$interests, active = "TRUE", added_by = ctx$user(), added_date = format(Sys.Date()),
        notes = "Invited from Collaborators", stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification(paste(r$email, "can now sign in as a partner. They see only bids where they are in the consortium."), type = "message")
    })
  })
}
