# ---- Welcome: orientation, progress, leaderboard, live activity ------------------------

mod_welcome_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("hero")),
    uiOutput(ns("stats")),
    uiOutput(ns("nudge")),
    layout_columns(col_widths = c(7, 5),
      div(
        div(class = "section-h", span(class = "num", "1"), span(class = "lab", "Your three steps"), span(class = "dots")),
        uiOutput(ns("steps")),
        div(class = "section-h mt", span(class = "num teal", "3"), span(class = "lab teal", "Live activity"), span(class = "dots teal")),
        uiOutput(ns("feed"))
      ),
      div(
        div(class = "section-h", span(class = "num mag", "2"), span(class = "lab mag", "Contributors"), span(class = "dots mag")),
        uiOutput(ns("board"))
      )
    )
  )
}

mod_welcome_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    my_prio <- reactive({
      p <- latest_by(ctx$data$prio(), c("email", "grant_id"))
      p[p$email == ctx$user$email, , drop = FALSE]
    })
    open_grants <- reactive({
      g <- ctx$data$grants(); g[g$status %in% c("open", "upcoming"), , drop = FALSE]
    })

    output$hero <- renderUI({
      req(ctx$user$authed)
      guest <- !ctx$auth_required()
      div(class = "hero",
        div(class = "hero-text",
          div(class = "eyebrow", "You're invited"),
          h1(paste0("Hello ", isolate(ctx$user$name) %||% "there", " - help us pick the grants worth chasing")),
          p("Two minutes of scoring today saves weeks of writing the wrong bid. See what's out there, say where we're strongest, and add ideas the team can vote on."),
          div(class = "hero-actions",
              actionButton(ns("go_prio"), "Start scoring", class = "btn-brand"),
              actionButton(ns("go_grants"), "Browse grants", class = "btn-ghost-light"))
        ),
        if (guest) div(class = "hero-side",
          div(class = "test-pill", "Test mode - sign-in is off"),
          textInput(ns("guest_name"), "Contribute as", value = isolate(ctx$user$name) %||% "Guest", width = "100%"),
          p(class = "small", "Your name is used to attribute scores and ideas.")
        )
      )
    })
    observeEvent(input$guest_name, {
      if (!ctx$auth_required()) {
        nm <- trimws(input$guest_name)
        if (nzchar(nm)) {
          ctx$user$name  <- nm
          ctx$user$email <- paste0(tolower(gsub("[^A-Za-z0-9]+", ".", nm)), "@test.local")
          session$sendCustomMessage("gc_save_name", nm)
        }
      }
    }, ignoreInit = TRUE)
    observeEvent(input$go_prio,   ctx$nav("Prioritise"))
    observeEvent(input$go_grants, ctx$nav("Grants"))

    output$stats <- renderUI({
      req(ctx$user$authed)
      p <- latest_by(ctx$data$prio(), c("email", "grant_id"))
      n_open <- nrow(open_grants())
      mine   <- nrow(my_prio())
      stat <- function(num, lab, cls = "") div(class = paste("stat", cls), div(class = "n", num), div(class = "l", lab))
      pct <- if (n_open > 0) round(100 * min(mine, n_open) / n_open) else 0
      div(class = "stat-row",
        stat(n_open, "grants on the radar"),
        stat(length(unique(p$email)), "people scoring", "teal"),
        stat(nrow(ctx$data$ideas()), "ideas on the board", "mag"),
        div(class = "stat wide",
          div(class = "l", paste0("Your progress: ", min(mine, n_open), " of ", n_open, " scored")),
          div(class = "meter", div(class = "fillbar", style = paste0("width:", pct, "%"))),
          div(class = "small muted", if (pct >= 100) "All scored - now add or vote on ideas." else "Each score takes about 30 seconds."))
      )
    })

    output$nudge <- renderUI({
      req(ctx$user$authed)
      n <- nrow(needs_you(ctx$data$decisions(), ctx$data$dinputs(), ctx$user$email))
      div(class = "nudge", onclick = onclick_input(ns("jump"), "Workspace"),
        span(class = "nudge-ico", ico("compass", 22)),
        div(div(class = "nudge-t", if (n > 0) paste(n, if (n == 1) "decision is" else "decisions are", "waiting for your view") else "Collaboration Lab: decide how we work, without the meetings"),
            div(class = "small", "Weigh in on decisions, post a weekly update, and read the decision log.")),
        span(class = "arrow", HTML("&rarr;")))
    })

    output$steps <- renderUI({
      step <- function(n, t, d, tab) div(class = "step-card", onclick = onclick_input(ns("jump"), tab),
        div(class = "step-n", n), div(div(class = "step-t", t), div(class = "step-d", d)), span(class = "arrow", HTML("&rarr;")))
      tagList(
        step("1", "Skim the grants", "A card for each opportunity: funder, value, deadline, themes.", "Grants"),
        step("2", "Score what fits us", "Alignment, interest and capability (1-5) plus a stance: lead, partner, watch or pass.", "Prioritise"),
        step("3", "Spark and vote on ideas", "Get suggestions from the team's interests, add your own, upvote the best.", "Ideas"))
    })
    observeEvent(input$jump, ctx$nav(input$jump))

    activity <- reactive({
      users <- ctx$data$users(); grants <- ctx$data$grants()
      p <- ctx$data$prio(); i <- ctx$data$ideas(); v <- ctx$data$votes()
      rows <- list()
      if (nrow(p)) rows[[1]] <- data.frame(t = p$updated_at, who = display_name(p$email, users),
        txt = paste0("scored ", short_title(grants$title[match(p$grant_id, grants$grant_id)])), kind = "score")
      if (nrow(i)) rows[[2]] <- data.frame(t = i$created_at, who = display_name(i$author, users),
        txt = paste0("shared an idea: ", i$title), kind = "idea")
      v <- v[v$vote == "1", , drop = FALSE]
      if (nrow(v)) rows[[3]] <- data.frame(t = v$updated_at, who = display_name(v$voter, users),
        txt = paste0("voted for ", short_title(i$title[match(v$idea_id, i$idea_id)])), kind = "vote")
      dd <- dec_latest(ctx$data$decisions())
      if (nrow(dd)) rows[[4]] <- data.frame(t = dd$created_at, who = display_name(dd$created_by, users),
        txt = paste0("posted a decision: ", dd$title), kind = "decision")
      di <- dd[dd$status == "decided", , drop = FALSE]
      if (nrow(di)) rows[[5]] <- data.frame(t = di$decided_at, who = display_name(di$decided_by, users),
        txt = paste0("decided: ", di$title), kind = "decided")
      if (!length(rows)) return(NULL)
      a <- do.call(rbind, rows); a <- a[order(a$t, decreasing = TRUE), ]; head(a, 8)
    })

    output$feed <- renderUI({
      a <- activity()
      if (is.null(a)) return(div(class = "empty", "Nothing yet - be the first to score a grant."))
      div(class = "feed", lapply(seq_len(nrow(a)), function(k)
        div(class = paste("feed-item", a$kind[k]),
            span(class = "dot"), span(class = "ftxt", span(class = "who", a$who[k]), " ", a$txt[k]),
            span(class = "when", time_ago(a$t[k])))))
    })

    output$board <- renderUI({
      users <- ctx$data$users()
      tot <- team_points(list(prio = ctx$data$prio(), ideas = ctx$data$ideas(), votes = ctx$data$votes(), decisions = ctx$data$decisions(),
                              dinputs = ctx$data$dinputs(), weekly = ctx$data$weekly(), syncs = ctx$data$syncs()))
      if (!length(tot)) return(div(class = "empty", "Points appear here as people contribute: 10 per grant scored, 15 per idea or decision, 8 per view, 10 per weekly update."))
      tot <- head(tot, 6); mx <- max(tot)
      div(class = "leaders", lapply(seq_along(tot), function(k) {
        em <- names(tot)[k]
        div(class = "leader",
          span(class = "rank", k), span(class = "avatar", toupper(substr(display_name(em, users), 1, 1))),
          div(class = "lname", display_name(em, users),
              div(class = "lbar", div(style = paste0("width:", round(100 * tot[k] / mx), "%")))),
          span(class = "pts", paste0(tot[k], " pts")))
      }))
    })
  })
}
