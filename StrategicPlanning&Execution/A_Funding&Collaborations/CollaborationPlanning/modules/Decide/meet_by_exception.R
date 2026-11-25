# ---- module ----------------------------------------------
# id:           meet_by_exception
# name:         Meet by exception
# icon:         people-arrows
# description:  Only meet when something needs it: objections, split views, missed deadlines, blockers, missed milestones
# packages:     shiny
# -----------------------------------------------------------
# Built to the Grant Compass mod_meet.R design. Builds an agenda and can email a meeting invitation.

meet_by_exception_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Most things are decided in writing. This page lists only what needs a conversation. If it is empty, no meeting is needed."),
    uiOutput(ns("agenda")),
    uiOutput(ns("invite_box")))
}

meet_by_exception_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    items <- reactive({
      s <- ctx$settings(); vis <- ctx$programmes()
      d <- ctx$data$decisions(); d <- d[d$status == "open" & (d$programme_id %in% vis$programme_id | (!nzchar(d$programme_id) & !ctx$is_partner())), , drop = FALSE]
      ins <- latest_by(ctx$table("decision_inputs")(), c("decision_id", "email"))
      out <- list()
      for (i in seq_len(nrow(d))) {
        x <- ins[ins$decision_id == d$decision_id[i], , drop = FALSE]
        past <- isTRUE(as.Date(d$deadline[i]) < Sys.Date())
        obj <- sum(x$stance == "object"); split <- length(unique(x$option_id[x$stance == "support"])) > 1
        why <- c(if (obj) sprintf("%d objection(s)", obj), if (split) "support is split between options",
                 if (past && !(is_true(s$silence_agrees) && nzchar(d$recommended_option) && !obj)) "deadline passed without an outcome")
        if (length(why)) out[[length(out) + 1]] <- list(kind = "Decision", title = d$title[i], why = paste(why, collapse = "; "),
                                                        who = unique(c(d$driver[i], d$approver[i], x$email)))
      }
      w <- latest_by(ctx$table("weekly")(), c("email", "project_id", "week"))
      w <- w[nzchar(trimws(w$blockers)) & suppressWarnings(as.Date(w$week)) >= Sys.Date() - 13, , drop = FALSE]
      pr <- ctx$data$projects(); w <- w[w$project_id %in% pr$project_id[pr$programme_id %in% vis$programme_id], , drop = FALSE]
      for (i in seq_len(nrow(w))) out[[length(out) + 1]] <- list(kind = "Blocker", title = pr$title[pr$project_id == w$project_id[i]][1],
                                                                 why = paste0(w$email[i], ": ", w$blockers[i]), who = w$email[i])
      m <- latest_by(ctx$table("milestones")(), "milestone_id")
      m <- m[m$project_id %in% pr$project_id[pr$programme_id %in% vis$programme_id] & m$status == "missed", , drop = FALSE]
      for (i in seq_len(nrow(m))) out[[length(out) + 1]] <- list(kind = "Missed milestone", title = m$title[i],
                                                                 why = paste("was due", m$due_date[i]), who = m$owner_email[i])
      out
    })
    agenda_text <- reactive({
      it <- items(); if (!length(it)) return("")
      paste0("Agenda\n\n", paste(sprintf("%d. %s: %s (%s)", seq_along(it), vapply(it, `[[`, "", "kind"),
                                         vapply(it, `[[`, "", "title"), vapply(it, `[[`, "", "why")), collapse = "\n"))
    })
    output$agenda <- renderUI({
      it <- items()
      if (!length(it)) return(card("Nothing needs a meeting", p("No objections, split views, missed deadlines, blockers or missed milestones.")))
      card(sprintf("%d item(s) need a conversation", length(it)),
        tags$table(class = "qs-table", tags$thead(tags$tr(tags$th("What"), tags$th("Item"), tags$th("Why"))),
          tags$tbody(lapply(it, function(x) tags$tr(tags$td(x$kind), tags$td(tags$b(x$title)), tags$td(x$why))))),
        downloadButton(ns("dl"), "Download agenda (.md)", class = "btn-ghost sm"))
    })
    output$dl <- downloadHandler(filename = function() paste0("agenda_", format(Sys.Date(), "%Y%m%d"), ".md"),
                                 content = function(file) writeLines(agenda_text(), file, useBytes = TRUE))
    output$invite_box <- renderUI({
      it <- items(); req(length(it) > 0, !ctx$is_partner())
      who <- unique(tolower(unlist(lapply(it, `[[`, "who")))); who <- who[valid_email(who)]
      card("Invite the people involved",
        textInput(ns("to"), "To", paste(who, collapse = ", "), width = "100%"),
        layout_columns(col_widths = c(4, 3, 2, 3),
          dateInput(ns("date"), "Date", Sys.Date() + 2, weekstart = 1), textInput(ns("time"), "Start (HH:MM, UK time)", "10:00"),
          numericInput(ns("min"), "Minutes", 30, min = 10, step = 5), textInput(ns("loc"), "Where or link")),
        actionButton(ns("send"), "Email the invitation", class = "btn-brand", icon = icon("calendar-plus")),
        uiOutput(ns("sent")))
    })
    observeEvent(input$send, {
      r <- tryCatch({
        conf <- smtp_config(ctx$settings())
        ics <- meeting_ics("Team meeting: items that need a decision", paste(format(input$date), trimws(input$time)), num(input$min),
                           conf$user, split_emails(input$to), input$loc %||% "", agenda_text())
        send_mail(input$to, "Meeting: items that need a decision", paste0(agenda_text(), "\n\nSent from ", APP_NAME, "."),
                  calendar = list(text = ics, method = "REQUEST", filename = "meeting.ics"), conf = conf)
        note("ok", "Invitation sent.")
      }, error = function(e) note("bad", safe_error_text(e)))
      output$sent <- renderUI(r)
    })
  })
}
