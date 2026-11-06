# ---- Playbook & invites: the working agreement, and a one-click way to invite people ------------

PRINCIPLES <- list(
  list(n = "1", t = "Write it down first", d = "A written page lets people contribute at any time, and the record outlives the conversation. Meetings are a last resort, not the default.",
       src = "GitLab handbook-first; Basecamp guide", url = "https://basecamp.com/guides/how-we-communicate"),
  list(n = "2", t = "Think alone, then pool", d = "People brainstorming alone produce more ideas than people in live groups, mainly because waiting your turn blocks thinking. That is why views stay hidden until you add yours.",
       src = "Diehl & Stroebe (1987); nominal group technique", url = "https://www.uni-muenster.de/imperia/md/content/psyifp/aeechterhoff/wintersemester2011-12/seminarthemenfelderdersozialpsychologie/08_diehl_stoebe_productivityloss-brainstorming_jpsp1987.pdf"),
  list(n = "3", t = "One owner, one approver", d = "Name a Driver who runs it, exactly one Approver who decides, Contributors who advise, and people to keep informed.",
       src = "DACI framework (Atlassian)", url = "https://www.atlassian.com/team-playbook/plays/daci"),
  list(n = "4", t = "Silence is agreement; objections are welcome early", d = "Propose, set a window (72 hours is typical, longer over weekends), and proceed if nobody objects. Be ready to roll back if a valid objection lands.",
       src = "Apache lazy consensus", url = "https://openoffice.apache.org/docs/governance/lazyConsensus.html"),
  list(n = "5", t = "Log the why, not just the what", d = "A decision record keeps context, options and reasoning, so settled choices are not re-argued by whoever speaks loudest next month.",
       src = "Decision records (endjin)", url = "https://endjin.com/blog/architecture-decision-records"),
  list(n = "6", t = "Meet by exception", d = "Go live for urgent issues, hard-to-write technical points, first conversations with new people, or when you are stuck after a written round. Write the outcome back.",
       src = "GitLab async guide", url = "https://handbook.gitlab.com/handbook/company/culture/all-remote/asynchronous/"))

mod_play_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow mag-t", "Playbook & invites"),
      h2("How we work together"),
      p(class = "lead", "A short working agreement built from documented practice, plus a ready-made invite so new collaborators know exactly what to do and how long it takes.")),
    div(class = "section-h", span(class = "num mag", "1"), span(class = "lab mag", "Six working principles"), span(class = "dots mag")),
    div(class = "principles", lapply(PRINCIPLES, function(p) div(class = "pr",
      div(class = "pr-n", p$n), div(h3(p$t), p(p$d), tags$a(href = p$url, target = "_blank", rel = "noopener", class = "pr-src", HTML(paste0(esc(p$src), " &#8599;"))))))),
    div(class = "note ok mt", strong("Honest caveat: "), "this is mostly practitioner-documented practice plus one classic lab finding, not proof that writing always beats talking. Live time still helps for relationships and genuinely tangled topics, which is why the Meet tab exists."),
    div(class = "section-h mt", span(class = "num teal", "2"), span(class = "lab teal", "Invite someone"), span(class = "dots teal")),
    layout_columns(col_widths = c(5, 7),
      div(class = "input-card",
        selectInput(ns("ask"), "What are you asking them to do?",
          c("Weigh in on a decision" = "decision", "Score the grants that fit them" = "grants", "Share ideas and vote" = "ideas", "Post a weekly update" = "weekly", "Something else" = "custom"), width = "100%"),
        uiOutput(ns("ask_detail")),
        selectizeInput(ns("who"), "Who? (pick teammates or type an email)", choices = NULL, multiple = TRUE, width = "100%",
          options = list(create = TRUE, placeholder = "Start typing...")),
        layout_columns(col_widths = c(6, 6),
          numericInput(ns("mins"), "Minutes it takes", 2, min = 1, max = 60, width = "100%"),
          dateInput(ns("by"), "Reply by", value = Sys.Date() + 3, min = Sys.Date(), width = "100%")),
        textInput(ns("url"), "App link to include", placeholder = "Paste your app's web address", width = "100%"),
        textAreaInput(ns("note"), "A personal line (optional)", rows = 2, width = "100%")),
      div(uiOutput(ns("preview")))),
    div(class = "section-h mt", span(class = "num amber", "3"), span(class = "lab amber", "Templates"), span(class = "dots amber")),
    layout_columns(col_widths = c(6, 6),
      div(class = "tpl", div(class = "tpl-h", "Decision page"), tags$ol(
        tags$li("The question, phrased as a question."), tags$li("Context a smart newcomer would need."),
        tags$li("2 to 4 options, each with a line on pros and cons."), tags$li("Your recommendation."),
        tags$li("Driver, one Approver, Contributors, who is Informed."), tags$li("A deadline (default 3 days)."))),
      div(class = "tpl", div(class = "tpl-h", "Weekly update"), tags$ol(
        tags$li("Done: what moved."), tags$li("Next: what you will do."), tags$li("Blocked: where you need someone."),
        tags$li("Thanks: who helped and how."))))
  )
}

mod_play_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({
      u <- ctx$data$users(); u <- u[toupper(u$active) == "TRUE" & nzchar(u$email), , drop = FALSE]
      updateSelectizeInput(session, "who", choices = stats::setNames(u$email, ifelse(u$name == "", u$email, u$name)), server = FALSE)
    })
    open_decs <- reactive({
      d <- dec_latest(ctx$data$decisions()); d[mapply(eff_status, d$status, d$deadline) == "open", , drop = FALSE]
    })
    output$ask_detail <- renderUI({
      if (input$ask == "decision") {
        d <- open_decs()
        if (nrow(d) == 0) return(div(class = "small muted", "No open decisions yet. Post one first, then pick it here."))
        selectInput(ns("dec"), "Which decision?", stats::setNames(d$decision_id, short_title(d$title)), width = "100%")
      } else if (input$ask == "custom") textInput(ns("custom"), "What should they do?", width = "100%")
    })

    msg <- reactive({
      u <- ctx$data$users(); names_ <- display_name(input$who %||% character(), u)
      greet <- if (length(names_)) paste0("Hi ", paste(names_, collapse = ", "), ",") else "Hi,"
      by <- format(input$by %||% Sys.Date(), "%A %d %B")
      topic <- switch(input$ask,
        decision = { d <- open_decs(); t <- d$title[match(input$dec %||% "", d$decision_id)]; if (is.na(t)) "a decision" else paste0("a decision: ", t) },
        grants = "which grants we should chase and who should lead them",
        ideas = "which project ideas are worth pursuing",
        weekly = "a short written weekly update",
        custom = input$custom %||% "a few things")
      ask <- switch(input$ask,
        decision = "Read the short page, then add your view (a preference, plus a sentence on why).",
        grants = "Rate each grant 1-5 on alignment, interest and readiness.",
        ideas = "Add any ideas you have and upvote the ones you like.",
        weekly = "Post what got done, what's next and anything blocking you.",
        custom = input$custom %||% "")
      paste0(greet, "\n\nWe're working out ", topic, " and your view would really help. It takes about ", input$mins %||% 2,
        " minutes and you can do it whenever suits you, any time before ", by, ".\n\nWhat I'm asking: ", ask,
        if (nzchar(input$url %||% "")) paste0("\nWhere: ", input$url) else "",
        "\n\nNo meeting needed. Add your input on the page, and if you're happy with the recommendation just say so. If nobody objects by ", by,
        ", we'll go ahead with it.\n",
        if (nzchar(input$note %||% "")) paste0("\n", input$note, "\n") else "",
        "\nThank you,\n", ctx$user$name)
    })

    output$preview <- renderUI({
      body <- msg(); to <- paste(input$who %||% character(), collapse = ",")
      href <- paste0("mailto:", utils::URLencode(to), "?subject=", utils::URLencode("Quick input needed (no meeting)", reserved = TRUE),
                     "&body=", utils::URLencode(body, reserved = TRUE))
      div(class = "invite-preview",
        div(class = "eyebrow", "Preview"),
        tags$pre(id = ns("body"), body),
        div(class = "btn-row",
          tags$button(class = "btn-collab", onclick = sprintf("navigator.clipboard.writeText(document.getElementById('%s').innerText); this.innerText='Copied!'", ns("body")), "Copy message"),
          tags$a(class = "btn-ghost", href = href, "Open in email app")),
        div(class = "small muted", "Short, specific, with a time estimate and a deadline: that's what makes people reply."))
    })
  })
}
