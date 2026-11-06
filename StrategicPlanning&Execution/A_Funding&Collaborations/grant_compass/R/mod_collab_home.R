# ---- Collaboration Lab home: what needs you, team pulse, your week, badges ----------------------

mod_chome_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("hero")),
    uiOutput(ns("rhythm")),
    layout_columns(col_widths = c(7, 5),
      div(
        div(class = "section-h", span(class = "num mag", "1"), span(class = "lab mag", "Needs you now"), span(class = "dots mag")),
        uiOutput(ns("needs")),
        div(class = "section-h mt", span(class = "num teal", "3"), span(class = "lab teal", "Recently decided"), span(class = "dots teal")),
        uiOutput(ns("recent"))),
      div(
        div(class = "section-h", span(class = "num", "2"), span(class = "lab", "Team pulse"), span(class = "dots")),
        uiOutput(ns("pulse")),
        div(class = "section-h mt", span(class = "num amber", "4"), span(class = "lab amber", "Your badges"), span(class = "dots amber")),
        uiOutput(ns("badges")),
        div(class = "section-h mt", span(class = "num mag", "5"), span(class = "lab mag", "Top contributors"), span(class = "dots mag")),
        uiOutput(ns("board"))))
  )
}

mod_chome_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    me <- reactive(ctx$user$email)
    days <- reactive(as.integer(num(ctx$settings()$decision_days, 3)))
    alld <- reactive(list(prio = ctx$data$prio(), ideas = ctx$data$ideas(), votes = ctx$data$votes(), decisions = ctx$data$decisions(),
                          dinputs = ctx$data$dinputs(), weekly = ctx$data$weekly(), syncs = ctx$data$syncs()))

    output$hero <- renderUI({
      req(ctx$user$authed)
      ny <- nrow(needs_you(ctx$data$decisions(), ctx$data$dinputs(), me()))
      div(class = "hero collab",
        div(class = "hero-text",
          div(class = "eyebrow", "Collaboration Lab"),
          h1("Decide together, in writing, in your own time"),
          p("No standing meetings and nothing to forget. One page per decision, a few days to weigh in, one clear call, and a log that remembers the why."),
          div(class = "hero-actions",
              actionButton(ns("new"), "Start a decision", class = "btn-light-solid"),
              actionButton(ns("weekly"), "Write this week's update", class = "btn-ghost-light"),
              actionButton(ns("playbook"), "How it works", class = "btn-ghost-light"))),
        div(class = "hero-side",
          div(class = "big-n", ny),
          div(class = "big-l", if (ny == 1) "decision needs you" else "decisions need you"),
          p(class = "small", if (ny == 0) "You're all caught up. Nice." else "Each takes about a minute.")))
    })
    observeEvent(input$new, { ctx$draft(list(title = "")); ctx$nav("Decisions") })
    observeEvent(input$weekly, ctx$nav("Weekly"))
    observeEvent(input$playbook, ctx$nav("Playbook"))

    output$rhythm <- renderUI({
      n <- days()
      step <- function(i, d, t, x) div(class = "rh", div(class = "rh-n", i), div(div(class = "rh-d", d), div(class = "rh-t", t), div(class = "rh-x", x)))
      div(class = "rhythm",
        step(1, "Day 0", "Post the page", "Question, context, 2-4 options, one recommendation."),
        div(class = "rh-arrow", HTML("&rarr;")),
        step(2, paste0("Days 1-", n), "Weigh in alone", "Add your view in your own time. Others' views stay hidden until you do."),
        div(class = "rh-arrow", HTML("&rarr;")),
        step(3, paste("Day", n), "One person decides", "No objection by the deadline? The recommendation stands."),
        div(class = "rh-arrow", HTML("&rarr;")),
        step(4, "Forever", "It's in the log", "The why and the 'revisit if' are recorded."))
    })

    output$needs <- renderUI({
      req(ctx$user$authed)
      d <- needs_you(ctx$data$decisions(), ctx$data$dinputs(), me())
      if (nrow(d) == 0) return(div(class = "empty", "Nothing waiting on you. Start a decision or read the log."))
      d <- d[order(d$deadline), ]
      div(class = "need-list", lapply(seq_len(nrow(d)), function(k) {
        r <- d[k, ]; di <- deadline_info(r$deadline); es <- eff_status(r$status, r$deadline)
        div(class = "need", onclick = onclick_input(ns("open"), r$decision_id),
          div(class = "nd-main", div(class = "nd-t", r$title), div(class = "small muted", paste(r$category, "-", if (es == "ready") "you're the Approver and input has closed" else "add your view"))),
          chip(di$label, di$cls), span(class = "arrow", HTML("&rarr;")))
      }))
    })
    observeEvent(input$open, { ctx$dec_pick(input$open); ctx$nav("Decisions") })

    output$recent <- renderUI({
      d <- dec_latest(ctx$data$decisions()); d <- d[d$status == "decided", , drop = FALSE]
      if (nrow(d) == 0) return(div(class = "empty slim", "Decisions will appear here."))
      d <- head(d[order(d$decided_at, decreasing = TRUE), ], 4); o <- ctx$data$dopts()
      div(class = "mini-log", lapply(seq_len(nrow(d)), function(k) {
        r <- d[k, ]
        div(class = "ml", span(class = "ml-d", substr(r$decided_at, 6, 10)), span(class = "ml-q", r$title),
            span(class = "ml-a", HTML("&rarr; "), o$label[match(r$outcome_option, o$option_id)]))
      }))
    })

    output$pulse <- renderUI({
      d <- dec_latest(ctx$data$decisions()); i <- in_latest(ctx$data$dinputs())
      open_n <- sum(mapply(eff_status, d$status, d$deadline) %in% c("open", "ready"))
      dd <- d[d$status == "decided", , drop = FALSE]
      recent <- sum(as.Date(substr(dd$decided_at, 1, 10)) >= Sys.Date() - 30, na.rm = TRUE)
      per <- if (nrow(d)) sprintf("%.1f", nrow(i) / max(1, sum(d$status != "withdrawn"))) else "-"
      w <- weekly_latest(ctx$data$weekly()); wk <- sum(w$week == format(week_start()))
      stat <- function(n, l, cls = "") div(class = paste("stat", cls), div(class = "n", n), div(class = "l", l))
      div(class = "stat-grid",
        stat(open_n, "open decisions", "mag"), stat(recent, "decided in 30 days", "teal"),
        stat(per, "views per decision"), stat(wk, "updates this week", "mag"))
    })

    output$badges <- renderUI({
      req(ctx$user$authed)
      b <- badges_for(alld(), me()); st <- streak_weeks(alld()$weekly, me())
      div(class = "badges", lapply(b, function(x) div(class = paste("badge-i", if (x$on) "on"), title = x$desc,
        span(class = "bi", ico(x$icon, 20)), span(class = "bn", x$name), span(class = "bd", if (x$on) "Earned" else x$desc))))
    })

    output$board <- renderUI({
      pts <- team_points(alld()); users <- ctx$data$users()
      if (!length(pts)) return(div(class = "empty slim", "Points appear as people contribute."))
      pts <- head(pts, 5); mx <- max(pts)
      div(class = "leaders", lapply(seq_along(pts), function(k) div(class = "leader",
        span(class = "rank", k), span(class = "avatar", toupper(substr(display_name(names(pts)[k], users), 1, 1))),
        div(class = "lname", display_name(names(pts)[k], users), div(class = "lbar", div(style = paste0("width:", round(100 * pts[k] / mx), "%")))),
        span(class = "pts", paste0(pts[k], " pts")))))
    })
  })
}
