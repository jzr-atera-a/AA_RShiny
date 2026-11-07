# ---- Meet by exception: live time is for the few things writing handles badly ------------------
# Reasons come from GitLab's guidance on when synchronous is better. Every held session must log
# its outcome back into the written record, so the meeting does not become the only copy of what was said.

mod_meet_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow mag-t", "Meet by exception"),
      h2("A live chat, when writing isn't enough"),
      p(class = "lead", "Short, purposeful, and always written back up. Tick the checks, say why, and propose a couple of times.")),
    layout_columns(col_widths = c(5, 7),
      div(uiOutput(ns("form"))),
      div(uiOutput(ns("stats")), uiOutput(ns("list"))))
  )
}

mod_meet_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    me <- reactive(ctx$user$email)
    nonce <- reactiveVal(0)
    syncs <- reactive({ req(ctx$user$authed); s <- sync_latest(ctx$data$syncs()); s[order(s$created_at, decreasing = TRUE), , drop = FALSE] })

    output$form <- renderUI({
      req(ctx$user$authed); nonce(); ctx$sync_pick()
      isolate({
        d <- dec_latest(ctx$data$decisions()); d <- d[d$status %in% c("open", "decided"), , drop = FALSE]
        ch <- c("Not tied to a decision" = "", stats::setNames(d$decision_id, short_title(d$title)))
        div(class = "input-card",
          div(class = "section-h sm", span(class = "num mag", "1"), span(class = "lab mag", "Before you ask"), span(class = "dots mag")),
          checkboxInput(ns("c1"), "I have written the question down (a decision page or a message)", FALSE),
          checkboxInput(ns("c2"), "People have had at least a day to reply in writing", FALSE),
          checkboxInput(ns("c3"), "I know the single outcome I need from the call", FALSE),
          uiOutput(ns("gate_msg")),
          div(class = "section-h sm", span(class = "num teal", "2"), span(class = "lab teal", "The request"), span(class = "dots teal")),
          selectInput(ns("dec"), "About which decision?", ch, selected = ctx$sync_pick() %||% "", width = "100%"),
          selectInput(ns("reason"), "Why live?", SYNC_REASONS, width = "100%"),
          textInput(ns("topic"), "The one thing to settle", placeholder = "e.g. agree the scope split with the university partner", width = "100%"),
          layout_columns(col_widths = c(8, 4),
            textInput(ns("times"), "Two or three times that work (with time zone)", placeholder = "Tue 10:00 or Wed 16:00 UK time", width = "100%"),
            selectInput(ns("mins"), "Length", c("15" = 15, "25" = 25, "45" = 45), selected = 25, width = "100%")),
          uiOutput(ns("send_btn")))
      })
    })

    ok <- reactive(isTRUE(input$c1) && isTRUE(input$c2) && isTRUE(input$c3))
    output$gate_msg <- renderUI(if (!ok()) div(class = "small muted", "Tick all three to unlock the request. It usually turns out one more written round is enough."))
    output$send_btn <- renderUI({
      if (ok()) actionButton(ns("send"), "Request the session", class = "btn-collab")
      else tags$button(class = "btn-collab disabled", disabled = NA, "Request the session")
    })

    observeEvent(input$send, {
      req(ok(), nzchar(trimws(input$topic %||% "")))
      store_append("SyncRequests", data.frame(req_id = new_id("s"), decision_id = input$dec %||% "", topic = input$topic,
        reason = input$reason, requested_by = me(), proposed_times = input$times %||% "", duration_min = input$mins,
        status = "requested", outcome = "", created_at = now_ts(), updated_at = now_ts()))
      log_change(me(), "sync_request", input$dec %||% "", input$topic); ctx$bump(); nonce(nonce() + 1); ctx$sync_pick(NULL)
      showNotification("Requested. Attendees can reply here with a time.", type = "message")
    })

    output$stats <- renderUI({
      s <- syncs(); d <- dec_latest(ctx$data$decisions()); dd <- d[d$status == "decided", , drop = FALSE]
      live <- unique(s$decision_id[s$status %in% c("scheduled", "held")])
      stat <- function(n, l, cls = "") div(class = paste("stat", cls), div(class = "n", n), div(class = "l", l))
      div(class = "stat-row three",
        stat(sum(s$status %in% c("requested", "scheduled")), "live sessions pending", "mag"),
        stat(sum(s$status == "held"), "sessions held", "teal"),
        stat(sum(!(dd$decision_id %in% live)), "decisions made in writing alone"))
    })

    output$list <- renderUI({
      s <- syncs(); users <- ctx$data$users(); d <- dec_latest(ctx$data$decisions())
      if (nrow(s) == 0) return(div(class = "empty", "No live sessions requested. That's usually a good sign."))
      div(class = "sync-list", lapply(seq_len(nrow(s)), function(k) {
        r <- s[k, ]; dt <- d$title[match(r$decision_id, d$decision_id)]
        overdue <- r$status == "held" && !nzchar(r$outcome)
        div(class = paste("sync", r$status, if (overdue) "overdue"),
          div(class = "sy-top", chip(names(SYNC_REASONS)[match(r$reason, SYNC_REASONS)], "grey"),
              chip(switch(r$status, requested = "Requested", scheduled = "Scheduled", held = "Held", cancelled = "Cancelled", r$status),
                   switch(r$status, requested = "amber", scheduled = "teal", held = "green", "grey")),
              span(class = "small muted", paste(r$duration_min, "min"))),
          div(class = "sy-topic", r$topic),
          div(class = "small muted", paste0("Asked by ", display_name(r$requested_by, users), if (nzchar(r$proposed_times)) paste0(" - ", r$proposed_times) else "",
                                              if (!is.na(dt)) paste0(" - on: ", short_title(dt)))),
          if (nzchar(r$outcome)) div(class = "sy-out", strong("Outcome: "), r$outcome),
          if (r$status %in% c("requested", "scheduled")) div(class = "sy-act",
            if (r$status == "requested") tags$button(class = "btn-ghost sm", onclick = onclick_input(ns("sched"), r$req_id), "Mark scheduled"),
            tags$button(class = "btn-ghost sm", onclick = onclick_input(ns("held"), r$req_id), "Mark held + log outcome"),
            tags$button(class = "btn-link danger", onclick = onclick_input(ns("cancel"), r$req_id), "Cancel")),
          if (overdue) div(class = "sy-act", tags$button(class = "btn-brand sm", onclick = onclick_input(ns("held"), r$req_id), "Log the outcome now")))
      }))
    })

    set_status <- function(id, status, outcome = NULL) {
      r <- syncs(); r <- r[r$req_id == id, , drop = FALSE]; req(nrow(r) == 1)
      r$status <- status; if (!is.null(outcome)) r$outcome <- outcome; r$updated_at <- now_ts()
      store_append("SyncRequests", r); log_change(me(), paste0("sync_", status), id, outcome %||% ""); ctx$bump()
    }
    observeEvent(input$sched,  set_status(input$sched, "scheduled"))
    observeEvent(input$cancel, set_status(input$cancel, "cancelled"))
    observeEvent(input$held, {
      showModal(modalDialog(title = "Log what was decided", easyClose = TRUE,
        p("A session isn't finished until the outcome is written down. Two lines is plenty."),
        textAreaInput(ns("outcome"), "Outcome, decisions and who does what", rows = 4, width = "100%"),
        footer = tagList(modalButton("Later"), actionButton(ns("save_outcome"), "Save to the record", class = "btn-collab"))))
    })
    observeEvent(input$save_outcome, {
      req(nzchar(trimws(input$outcome %||% "")))
      set_status(input$held, "held", input$outcome); removeModal()
      showNotification("Outcome logged. +5 points", type = "message")
    })
  })
}
