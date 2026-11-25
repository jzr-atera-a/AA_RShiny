# ---- module ----------------------------------------------
# id:           submit_checklist
# name:         Submit checklist
# icon:         square-check
# description:  Before submitting: answers within limits, budget adds up, partner documents in, eligibility met, deadline
# packages:     shiny
# -----------------------------------------------------------

submit_checklist_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, layout_columns(col_widths = c(6, 6),
      selectInput(ns("proj"), "Project", NULL, width = "100%"),
      selectInput(ns("set"), "Question set used", NULL, width = "100%"))),
    uiOutput(ns("checks")),
    uiOutput(ns("submit_box")))
}

submit_checklist_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    observe({
      a <- ctx$table("answers")(); a <- a[a$project_id == (input$proj %||% ""), , drop = FALSE]
      q <- ctx$data$question_sets(); ids <- unique(c(a$set_id, q$set_id))
      ch <- named(ids, q$set_name[match(ids, q$set_id)]); updateSelectInput(session, "set", choices = ch, selected = pick_sel(isolate(input$set), ch, a$set_id[1]))
    })
    checks <- reactive({
      r <- proj(); req(nrow(r) > 0); p <- ctx$programmes(); pr <- p[p$programme_id == r$programme_id, , drop = FALSE]
      q <- ctx$data$question_sets(); q <- q[q$set_id == (input$set %||% ""), , drop = FALSE]
      a <- ctx$table("answers")(); a <- a[a$project_id == r$project_id & a$set_id == (input$set %||% ""), , drop = FALSE]
      a <- a[order(num(a$version)), , drop = FALSE]; a <- a[!duplicated(a$question_no, fromLast = TRUE), , drop = FALSE]
      w <- vapply(q$question_no, function(n) num(a$words[a$question_no == n][1] %||% 0), 1)
      lim <- num(q$word_limit)
      b <- latest_by(ctx$table("budget")(), c("project_id", "partner", "category")); b <- b[b$project_id == r$project_id & num(b$amount_gbp) > 0, , drop = FALSE]
      grant <- sum(num(b$amount_gbp) * num(b$funded_pct) / 100)
      c <- ctx$data$consortium(); c <- c[c$programme_id == r$programme_id & c$status != "declined", , drop = FALSE]
      owed <- unlist(lapply(seq_len(nrow(c)), function(i) { m <- setdiff(split_list(c$documents_owed[i]), split_list(c$documents_received[i]))
                                                            if (length(m)) paste0(c$name[i] %|% c$email[i], ": ", m) }))
      el <- elig_status_of(r$programme_id, ctx$status()$elig)
      d <- suppressWarnings(as.Date(pr$closes_date[1] %||% ""))
      shares <- sum(num(c$budget_share_pct))
      list(
        list(ok = nrow(q) > 0 && all(w > 0), label = sprintf("Every question answered (%d of %d)", sum(w > 0), nrow(q))),
        list(ok = !any(lim > 0 & w > lim), label = if (any(lim > 0 & w > lim)) paste("Over the word limit:", paste(q$question_no[lim > 0 & w > lim], collapse = ", ")) else "Every answer within its word limit"),
        list(ok = nrow(b) > 0 && (num(pr$max_gbp[1] %||% 0) == 0 || grant <= num(pr$max_gbp[1])),
             label = if (!nrow(b)) "Budget not filled in" else sprintf("Budget: grant %s%s", fmt_gbp(grant), if (num(pr$max_gbp[1] %||% 0) > 0) paste0(" against a maximum of ", fmt_gbp(pr$max_gbp[1])) else "")),
        list(ok = !nrow(c) || abs(shares - 100) < 0.01, label = if (nrow(c)) sprintf("Consortium shares add up to %s%%", round(shares, 1)) else "No partners (single applicant)"),
        list(ok = !length(owed) && all(c$status %in% c("committed")), label = if (length(owed)) paste("Documents still to come:", paste(owed, collapse = "; "))
             else if (nrow(c) && !all(c$status == "committed")) "Not every partner has committed" else "All partner documents received"),
        list(ok = el == "eligible", wait = el %in% c("unclear", "unchecked"), label = paste("Eligibility:", el)),
        list(ok = !is.na(d) && d >= Sys.Date(), wait = is.na(d), label = if (is.na(d)) "No closing date recorded" else if (d < Sys.Date()) paste("Closed on", d) else sprintf("Closes %s (%d days left)", d, as.integer(d - Sys.Date()))))
    })
    output$checks <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      ch <- checks(); n_ok <- sum(vapply(ch, function(x) isTRUE(x$ok), TRUE))
      card(sprintf("%d of %d checks pass", n_ok, length(ch)),
        tags$ul(class = "check-list", lapply(ch, function(x) {
          cls <- if (isTRUE(x$ok)) "ok" else if (isTRUE(x$wait)) "wait" else "no"
          tags$li(class = cls, icon(switch(cls, ok = "circle-check", wait = "circle-question", "circle-xmark")), " ", x$label) })))
    })
    output$submit_box <- renderUI({
      r <- proj(); req(nrow(r) > 0, !ctx$is_partner())
      if (r$status == "submitted") return(note("ok", "Marked as submitted. Record the result in 8 Learn > Outcomes when the funder replies."))
      ch <- checks(); all_ok <- all(vapply(ch, function(x) isTRUE(x$ok), TRUE))
      card("Submit",
        if (!all_ok) note("warn", "Some checks do not pass. You can still mark it submitted if you have dealt with them outside the app."),
        actionButton(ns("submit"), "Mark as submitted", class = "btn-brand", icon = icon("paper-plane")))
    })
    observeEvent(input$submit, {
      r <- proj(); req(nrow(r) > 0, !ctx$is_partner())
      update_project(r$project_id, list(status = "submitted"), ctx$user())
      p <- ctx$programmes(); if (p$stage[p$programme_id == r$programme_id][1] %in% c("Plan", "Decide")) move_programme_stage(r$programme_id, "Write", ctx$user())
      log_change(ctx$user(), "submitted", "projects", r$title); ctx$bump(); showNotification("Marked as submitted.", type = "message")
    })
  })
}
