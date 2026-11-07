# ---- Decisions: one page per decision, input before discussion, one approver, a deadline ----------
# Built from: DACI roles (Driver/Approver/Contributors/Informed), nominal-group "think alone first"
# (inputs stay hidden until you add yours), and lazy consensus (no objection by the deadline = the
# recommendation stands). Records are append-only: the latest row per decision / person wins.

mod_dec_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow mag-t", "Decisions"),
      h2("One page per decision"),
      p(class = "lead", "Pick a decision to read the context and options, add your view in your own time, and see where the team lands. Nobody has to be online at the same moment.")),
    div(class = "dec-toolbar",
      textInput(ns("q"), NULL, placeholder = "Search decisions", width = "100%"),
      selectInput(ns("status"), NULL, c("Needs input" = "open", "Ready to decide" = "ready", "Decided" = "decided", "All active" = "all"), width = "100%"),
      selectInput(ns("cat"), NULL, c("All types" = "", CATEGORIES), width = "100%"),
      actionButton(ns("new"), HTML("+ New decision"), class = "btn-collab")),
    layout_columns(col_widths = c(4, 8),
      div(uiOutput(ns("list"))),
      div(uiOutput(ns("head")), uiOutput(ns("form")), uiOutput(ns("voices")), uiOutput(ns("decide"))))
  )
}

mod_dec_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    sel <- reactiveVal(NULL)
    form_nonce <- reactiveVal(0)
    st <- reactiveVal(NULL)    # only changes when the selected decision's effective status changes

    me      <- reactive(ctx$user$email)
    admin   <- reactive(identical(ctx$user$role, "admin"))
    decs    <- reactive({ req(ctx$user$authed); dec_latest(ctx$data$decisions()) })
    cur     <- reactive({ req(sel()); d <- decs(); d[d$decision_id == sel(), , drop = FALSE] })
    opts    <- reactive({ req(sel()); o <- ctx$data$dopts(); o <- o[o$decision_id == sel(), , drop = FALSE]; o[order(as.integer(o$position)), , drop = FALSE] })
    ins     <- reactive({ req(sel()); i <- in_latest(ctx$data$dinputs()); i[i$decision_id == sel(), , drop = FALSE] })
    users   <- reactive(ctx$data$users())
    uname   <- function(em) display_name(em, users())
    blind   <- reactive(identical(ctx$settings()$blind_input, "true"))
    silent_ok <- reactive(identical(ctx$settings()$silence_agrees, "true"))
    default_days <- reactive(as.integer(num(ctx$settings()$decision_days, 3)))

    observe({
      d <- cur()
      st(if (nrow(d)) paste(d$decision_id, eff_status(d$status, d$deadline), d$reopen_count) else NULL)
    })

    observeEvent(input$pick, sel(input$pick))
    observeEvent(ctx$dec_pick(), { sel(ctx$dec_pick()) }, ignoreNULL = TRUE)

    revealed <- reactive({
      d <- cur(); if (nrow(d) == 0) return(FALSE)
      !blind() || d$status %in% c("decided", "withdrawn") || any(ins()$email == me())
    })

    write_dec <- function(row) {
      row$updated_at <- now_ts(); store_append("Decisions", row)
    }

    # ---------------------------------------------------------------- list
    output$list <- renderUI({
      req(ctx$user$authed)
      d <- decs(); d <- d[d$status != "withdrawn", , drop = FALSE]
      if (nrow(d) == 0) return(div(class = "empty", "No decisions yet. Start one with + New decision, or promote an idea from the Grants Hub."))
      d$es <- mapply(eff_status, d$status, d$deadline)
      f <- input$status %||% "open"
      d <- switch(f, open = d[d$es == "open", ], ready = d[d$es == "ready", ], decided = d[d$es == "decided", ], d[d$es != "decided", ])
      if (nzchar(input$cat %||% "")) d <- d[d$category == input$cat, ]
      q <- tolower(trimws(input$q %||% ""))
      if (nzchar(q)) d <- d[grepl(q, tolower(paste(d$title, d$context)), fixed = TRUE), ]
      if (nrow(d) == 0) return(div(class = "empty", "Nothing here. Try another filter."))
      d <- d[order(d$deadline), ]
      all_in <- in_latest(ctx$data$dinputs()); ny <- needs_you(ctx$data$decisions(), ctx$data$dinputs(), me())$decision_id
      div(class = "dec-list", lapply(seq_len(nrow(d)), function(k) {
        r <- d[k, ]; di <- deadline_info(r$deadline)
        n_in <- sum(all_in$decision_id == r$decision_id)
        exp_n <- max(length(people_in(r)), n_in)
        div(class = paste("dec-card", if (identical(sel(), r$decision_id)) "active", if (r$decision_id %in% ny) "needs"),
            onclick = onclick_input(ns("pick"), r$decision_id),
            div(class = "dc-top", chip(r$category, "grey"), if (r$es == "decided") chip("Decided", "green") else chip(di$label, di$cls)),
            div(class = "dc-title", r$title),
            div(class = "dc-meta",
              span(class = "mini-meter", div(style = paste0("width:", if (exp_n) round(100 * n_in / exp_n) else 0, "%"))),
              span(class = "small muted", if (open_to_all(r)) paste(n_in, "weighed in") else paste(n_in, "of", exp_n, "weighed in")),
              if (r$decision_id %in% ny) span(class = "needs-pill", "needs you")))
      }))
    })

    # ---------------------------------------------------------------- header + options
    output$head <- renderUI({
      req(ctx$user$authed)
      if (is.null(sel())) return(div(class = "editor placeholder", div(class = "big-arrow", HTML("&larr;")),
                                      p("Choose a decision on the left, or start a new one.")))
      d <- cur(); req(nrow(d) == 1)
      o <- opts(); i <- ins(); es <- eff_status(d$status, d$deadline); di <- deadline_info(d$deadline)
      show <- revealed()
      tally <- table(factor(i$option_id, levels = o$option_id))
      steps <- c("Posted", "Input open", "Decided")
      cur_step <- switch(es, open = 2, ready = 2.5, decided = 3, withdrawn = 0)
      stepper <- div(class = "stepper", lapply(seq_along(steps), function(k) {
        cls <- if (k < cur_step) "done" else if (k == floor(cur_step) || (k == 3 && es == "decided")) "now" else ""
        div(class = paste("st", cls), span(class = "stn", if (k < cur_step) HTML("&#10003;") else k), span(class = "stl", steps[k]))
      }))
      who <- function(label, em) if (length(em) && any(nzchar(em)))
        div(class = "role", span(class = "r-l", label), lapply(em[nzchar(em)], function(e) span(class = "r-p", span(class = "avatar sm", toupper(substr(uname(e), 1, 1))), uname(e))))
      lg <- if (nzchar(d$linked_grant)) ctx$data$grants()$title[match(d$linked_grant, ctx$data$grants()$grant_id)] else NULL
      objections <- sum(i$stance == "object")
      div(class = "dec-head",
        div(class = "dh-top", chip(d$category, "mag"), status_chip(es),
            if (es %in% c("open", "ready")) chip(di$label, di$cls),
            if (as.integer(d$reopen_count %||% 0) > 0) chip(paste0("Reopened x", d$reopen_count), "grey")),
        h2(d$title), stepper,
        if (nzchar(d$context)) div(class = "dh-ctx", HTML(gsub("\n", "<br>", esc(d$context)))),
        div(class = "roles",
            who("Driver", d$driver), who("Approver", d$approver),
            if (nzchar(d$contributors)) who("Contributors", split_tags(d$contributors)) else div(class = "role", span(class = "r-l", "Contributors"), span(class = "r-p muted", "Open to everyone")),
            if (nzchar(d$informed)) div(class = "role", span(class = "r-l", "Informed"), span(class = "r-p", d$informed))),
        if (!is.null(lg) && !is.na(lg)) div(class = "chips", chip(paste("Grant:", short_title(lg)), "teal")),
        if (es %in% c("open", "ready") && objections > 0 && show)
          div(class = "note bad", strong(paste0(objections, if (objections == 1) " objection" else " objections")), " raised. The Driver should respond in writing before the decision is recorded."),
        if (es %in% c("open", "ready") && silent_ok() && show && objections == 0 && nrow(i) > 0)
          div(class = "note ok", "No objections so far. If it stays that way by the deadline, the recommended option stands."),
        div(class = "section-h sm", span(class = "num mag", "1"), span(class = "lab mag", "Options"), span(class = "dots mag")),
        div(class = "opt-grid", lapply(seq_len(nrow(o)), function(k) {
          r <- o[k, ]; isrec <- identical(r$option_id, d$recommended_option); isout <- identical(r$option_id, d$outcome_option) && es == "decided"
          n <- as.integer(tally[r$option_id]); tot <- max(1, nrow(i))
          div(class = paste("opt", if (isrec) "rec", if (isout) "won"),
            div(class = "opt-top", span(class = "opt-l", LETTERS[k]), span(class = "opt-name", r$label),
                if (isout) chip("Chosen", "green") else if (isrec) chip("Recommended", "mag")),
            if (nzchar(r$details)) p(class = "opt-d", HTML(gsub("\n", "<br>", esc(r$details)))),
            if (show) div(class = "opt-tally", div(class = "bar teal", div(style = paste0("width:", round(100 * n / tot), "%"))), span(class = "small", paste(n, if (n == 1) "preference" else "preferences")))
            else div(class = "opt-tally hidden", ico("lock", 12), span(class = "small muted", "Votes hidden until you add your view")))
        })),
        if (es == "decided") div(class = "outcome",
          div(class = "eyebrow", "Decision recorded"),
          div(class = "oc-title", o$label[match(d$outcome_option, o$option_id)]),
          p(d$outcome_rationale),
          if (nzchar(d$revisit_if)) div(class = "small", strong("Revisit if: "), d$revisit_if),
          div(class = "small muted", paste("Decided by", uname(d$decided_by), "-", time_ago(d$decided_at))),
          actionButton(ns("reopen"), "Reopen with new information", class = "btn-ghost sm")),
        if (es %in% c("open", "ready")) div(class = "dh-foot",
          actionButton(ns("to_meet"), HTML("Need a live chat? Request one"), class = "btn-link"),
          if (admin() || identical(me(), d$created_by) || identical(me(), tolower(d$driver)))
            actionButton(ns("withdraw"), "Withdraw", class = "btn-link danger"))
      )
    })

    # ---------------------------------------------------------------- my input (re-rendered only on selection / status / save)
    output$form <- renderUI({
      req(ctx$user$authed, sel()); st(); form_nonce()
      isolate({
        d <- cur(); req(nrow(d) == 1)
        es <- eff_status(d$status, d$deadline)
        if (es %in% c("decided", "withdrawn")) return(NULL)
        o <- opts(); mine <- ins(); mine <- mine[mine$email == me(), , drop = FALSE]
        ch <- stats::setNames(o$option_id, paste0(LETTERS[seq_len(nrow(o))], ". ", o$label))
        div(class = "input-card",
          div(class = "section-h sm", span(class = "num", "2"), span(class = "lab", "Your view"), span(class = "dots")),
          p(class = "small muted", if (blind()) "Write your view first. Everyone's views unlock for you once you save yours, so nobody anchors on someone else's."
                                    else "Add your view. Everyone can see everyone's input."),
          radioButtons(ns("in_opt"), "Which option do you prefer?", choices = ch,
                       selected = if (nrow(mine)) mine$option_id else d$recommended_option, width = "100%"),
          radioButtons(ns("in_stance"), "How do you feel about the recommendation?", choices = STANCE_IN,
                       selected = if (nrow(mine)) mine$stance else "support", inline = TRUE),
          textAreaInput(ns("in_comment"), "Why? (a sentence or two is plenty)", value = if (nrow(mine)) mine$comment else "", rows = 3, width = "100%"),
          div(class = "btn-row",
              actionButton(ns("in_save"), if (nrow(mine)) "Update my view" else "Add my view", class = "btn-collab"),
              span(class = "small muted", "Takes about a minute.")))
      })
    })

    observeEvent(input$in_save, {
      req(ctx$user$authed, sel(), input$in_opt)
      d <- cur(); req(nrow(d) == 1)
      if (input$in_stance %in% c("concern", "object") && !nzchar(trimws(input$in_comment %||% ""))) {
        showNotification("Please add a sentence on your concern so we can address it in writing.", type = "warning"); return()
      }
      store_append("DecisionInputs", data.frame(decision_id = sel(), email = me(), option_id = input$in_opt,
        stance = input$in_stance, comment = input$in_comment %||% "", updated_at = now_ts()))
      log_change(me(), "decision_input", sel(), paste(input$in_opt, input$in_stance))
      ctx$bump(); form_nonce(form_nonce() + 1)
      showNotification("Thanks - your view is in, and the team's views are now unlocked for you. +8 points", type = "message", duration = 5)
    })

    # ---------------------------------------------------------------- everyone's views
    output$voices <- renderUI({
      req(ctx$user$authed, sel())
      d <- cur(); req(nrow(d) == 1); i <- ins(); o <- opts()
      if (nrow(i) == 0) return(div(class = "voices", div(class = "empty slim", "No views yet. Be the first voice.")))
      if (!revealed()) return(div(class = "voices locked", ico("lock", 18), div(
        strong(paste(nrow(i), if (nrow(i) == 1) "person has" else "people have"), " weighed in."),
        div(class = "small muted", "Add your own view above to see what they said."))))
      i <- i[order(match(i$stance, c("object", "concern", "support")), i$updated_at), ]
      div(class = "voices",
        div(class = "section-h sm", span(class = "num teal", "3"), span(class = "lab teal", paste0("What the team said (", nrow(i), ")")), span(class = "dots teal")),
        lapply(seq_len(nrow(i)), function(k) {
          r <- i[k, ]; lab <- LETTERS[match(r$option_id, o$option_id)]
          div(class = paste("voice", r$stance),
            span(class = "avatar", toupper(substr(uname(r$email), 1, 1))),
            div(class = "vb", div(class = "vh", strong(uname(r$email)), chip(paste("Prefers", lab), "teal"),
                                  chip(names(STANCE_IN)[match(r$stance, STANCE_IN)], paste0("st-", r$stance)), span(class = "when", time_ago(r$updated_at))),
                if (nzchar(r$comment)) p(r$comment)))
        }))
    })

    # ---------------------------------------------------------------- approver decides
    output$decide <- renderUI({
      req(ctx$user$authed, sel()); st()
      isolate({
        d <- cur(); req(nrow(d) == 1); es <- eff_status(d$status, d$deadline)
        if (!(es %in% c("open", "ready"))) return(NULL)
        can <- admin() || identical(me(), tolower(d$approver))
        if (!can) return(div(class = "approver-note", ico("shield", 14), span(paste("Only the Approver,", uname(d$approver), "records the final decision."))))
        o <- opts(); ch <- stats::setNames(o$option_id, paste0(LETTERS[seq_len(nrow(o))], ". ", o$label))
        div(class = "decide-card",
          div(class = "section-h sm", span(class = "num amber", "4"), span(class = "lab amber", "Record the decision"), span(class = "dots amber")),
          p(class = "small muted", if (es == "ready") "The input window has closed. Close it out." else "You can decide early if the picture is clear."),
          selectInput(ns("d_opt"), "Chosen option", ch, selected = d$recommended_option, width = "100%"),
          textAreaInput(ns("d_why"), "Why (this is what future us will read)", rows = 3, width = "100%"),
          textInput(ns("d_revisit"), "Revisit if... (what would change our mind?)", placeholder = "e.g. a partner drops out, or the call scope changes", width = "100%"),
          actionButton(ns("d_save"), "Record decision", class = "btn-collab"))
      })
    })

    observeEvent(input$d_save, {
      d <- cur(); req(nrow(d) == 1)
      if (!nzchar(trimws(input$d_why %||% ""))) { showNotification("Add the reasoning: it is the part people forget.", type = "warning"); return() }
      row <- d; row$status <- "decided"; row$outcome_option <- input$d_opt; row$outcome_rationale <- input$d_why
      row$revisit_if <- input$d_revisit %||% ""; row$decided_by <- me(); row$decided_at <- now_ts()
      write_dec(row); log_change(me(), "decide", d$decision_id, input$d_opt); ctx$bump()
      showNotification("Decision recorded and added to the log. +10 points", type = "message", duration = 5)
    })

    observeEvent(input$reopen, {
      showModal(modalDialog(title = "Reopen this decision", easyClose = TRUE,
        p("Decisions are reopened only when something has changed. Say what, so the log stays honest."),
        textAreaInput(ns("r_why"), "What is new?", rows = 3, width = "100%"),
        dateInput(ns("r_deadline"), "New deadline for input", value = Sys.Date() + default_days(), min = Sys.Date(), width = "100%"),
        footer = tagList(modalButton("Cancel"), actionButton(ns("r_save"), "Reopen", class = "btn-collab"))))
    })
    observeEvent(input$r_save, {
      req(nzchar(trimws(input$r_why %||% "")))
      d <- cur(); row <- d; row$status <- "open"; row$deadline <- as.character(input$r_deadline)
      row$reopen_count <- as.character(as.integer(num(d$reopen_count, 0)) + 1)
      row$context <- paste0(d$context, "\n\nREOPENED (", format(Sys.Date()), "): ", input$r_why,
                            "\nPrevious outcome: ", d$outcome_rationale)
      row$outcome_option <- ""; row$outcome_rationale <- ""; row$revisit_if <- ""; row$decided_by <- ""; row$decided_at <- ""
      write_dec(row); log_change(me(), "reopen", d$decision_id, input$r_why); ctx$bump(); removeModal()
      showNotification("Reopened. Everyone can add fresh input.", type = "message")
    })

    observeEvent(input$withdraw, {
      d <- cur(); row <- d; row$status <- "withdrawn"; write_dec(row)
      log_change(me(), "withdraw", d$decision_id, ""); ctx$bump(); sel(NULL)
    })
    observeEvent(input$to_meet, { ctx$sync_pick(sel()); ctx$nav("Meet") })

    # ---------------------------------------------------------------- create
    draft_idea <- reactiveVal("")
    show_new <- function(draft = NULL) {
      draft_idea(draft$linked_idea %||% "")
      u <- users(); act <- u[toupper(u$active) %in% c("TRUE", "YES", "1", ""), , drop = FALSE]
      ppl <- stats::setNames(act$email, ifelse(act$name == "", act$email, act$name))
      if (!(me() %in% ppl)) ppl <- c(stats::setNames(me(), paste0(ctx$user$name, " (me)")), ppl)
      g <- ctx$data$grants(); gch <- c("None" = "", stats::setNames(g$grant_id, short_title(g$title)))
      opt_row <- function(k, d_lab = "", d_det = "") layout_columns(col_widths = c(4, 8),
        textInput(ns(paste0("n_o", k)), paste("Option", LETTERS[k], if (k > 2) "(optional)"), value = d_lab, width = "100%"),
        textInput(ns(paste0("n_d", k)), "In a line: what it means, pros and cons", value = d_det, width = "100%"))
      dr <- draft %||% list()
      showModal(modalDialog(title = "New decision", size = "l", easyClose = FALSE,
        textInput(ns("n_title"), "The question we need to answer", value = dr$title %||% "", placeholder = "e.g. Do we lead or join the battery standards bid?", width = "100%"),
        layout_columns(col_widths = c(4, 4, 4),
          selectInput(ns("n_cat"), "Type", CATEGORIES, selected = dr$category %||% "Project approach", width = "100%"),
          selectInput(ns("n_grant"), "Linked grant", gch, selected = dr$linked_grant %||% "", width = "100%"),
          dateInput(ns("n_deadline"), "Input closes", value = Sys.Date() + default_days(), min = Sys.Date(), width = "100%")),
        textAreaInput(ns("n_ctx"), "Context: what a smart newcomer needs to know", value = dr$context %||% "", rows = 3, width = "100%"),
        div(class = "section-h sm", span(class = "num mag", "1"), span(class = "lab mag", "Options (2 to 4)"), span(class = "dots mag")),
        opt_row(1, dr$o1 %||% "", dr$d1 %||% ""), opt_row(2, dr$o2 %||% "", dr$d2 %||% ""), opt_row(3, dr$o3 %||% "", dr$d3 %||% ""), opt_row(4),
        radioButtons(ns("n_rec"), "Your recommendation", choices = c("Option A" = "1", "Option B" = "2", "Option C" = "3", "Option D" = "4"), selected = "1", inline = TRUE),
        div(class = "section-h sm", span(class = "num teal", "2"), span(class = "lab teal", "Roles"), span(class = "dots teal")),
        layout_columns(col_widths = c(4, 4, 4),
          selectInput(ns("n_driver"), "Driver (runs it)", ppl, selected = me(), width = "100%"),
          selectInput(ns("n_approver"), "Approver (one person)", ppl, selected = me(), width = "100%"),
          selectizeInput(ns("n_contrib"), "Contributors (empty = open to all)", ppl, multiple = TRUE, width = "100%")),
        textInput(ns("n_informed"), "Informed (people told the outcome, optional)", width = "100%"),
        footer = tagList(modalButton("Cancel"), actionButton(ns("n_save"), "Post decision", class = "btn-collab"))))
    }
    observeEvent(input$new, show_new())
    observeEvent(ctx$draft(), { show_new(ctx$draft()); ctx$draft(NULL) }, ignoreNULL = TRUE)

    observeEvent(input$n_save, {
      req(ctx$user$authed)
      labs <- vapply(1:4, function(k) trimws(input[[paste0("n_o", k)]] %||% ""), "")
      if (!nzchar(trimws(input$n_title %||% ""))) { showNotification("Write the question first.", type = "warning"); return() }
      keep <- which(nzchar(labs))
      if (length(keep) < 2) { showNotification("Give at least two options.", type = "warning"); return() }
      rec_idx <- as.integer(input$n_rec)
      if (!(rec_idx %in% keep)) { showNotification("Your recommendation must be one of the options you filled in.", type = "warning"); return() }
      did <- new_id("d")
      oids <- paste0(did, "-", LETTERS[keep])
      store_append("DecisionOptions", data.frame(option_id = oids, decision_id = did, label = labs[keep],
        details = vapply(keep, function(k) trimws(input[[paste0("n_d", k)]] %||% ""), ""), position = seq_along(keep)))
      write_dec(data.frame(decision_id = did, title = trimws(input$n_title), category = input$n_cat, context = input$n_ctx %||% "",
        recommended_option = oids[match(rec_idx, keep)], driver = input$n_driver, approver = input$n_approver,
        contributors = paste(input$n_contrib, collapse = "; "), informed = input$n_informed %||% "",
        deadline = as.character(input$n_deadline), status = "open", linked_grant = input$n_grant %||% "", linked_idea = draft_idea(),
        created_by = me(), created_at = now_ts(), outcome_option = "", outcome_rationale = "", revisit_if = "",
        decided_by = "", decided_at = "", reopen_count = "0"))
      log_change(me(), "new_decision", did, input$n_title); ctx$bump(); removeModal(); sel(did)
      showNotification("Posted. Share the invite from Playbook & invites. +15 points", type = "message", duration = 6)
    })
  })
}
