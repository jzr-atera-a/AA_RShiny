# ---- Weekly updates: a written recap instead of a status call --------------------------------

mod_weekly_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow mag-t", "Weekly updates"),
      h2("Say it once, in writing"),
      p(class = "lead", "Five minutes, any day this week. Done, next, blockers, and a shout-out for someone who helped. The team recap builds itself from everyone's updates and the week's activity.")),
    layout_columns(col_widths = c(5, 7),
      div(uiOutput(ns("streak")), uiOutput(ns("form"))),
      div(
        div(class = "board-bar", uiOutput(ns("week_pick")), downloadButton(ns("dl"), "Download recap (.md)", class = "btn-ghost")),
        uiOutput(ns("recap"))))
  )
}

mod_weekly_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    me <- reactive(ctx$user$email)
    nonce <- reactiveVal(0)
    this_week <- format(week_start())
    wk <- reactive(ctx$data$weekly())
    weeks <- reactive({
      w <- format(week_start() - 7 * (0:7)); w
    })

    output$streak <- renderUI({
      req(ctx$user$authed)
      n <- streak_weeks(wk(), me()); posted <- any(wk()$email == me() & wk()$week == this_week)
      div(class = paste("streak-card", if (posted) "ok"),
        span(class = "flame", ico("flame", 26)), div(
          div(class = "sn", paste0(n, if (n == 1) " week" else " weeks"), " in a row"),
          div(class = "small muted", if (posted) "This week's update is in. Thank you." else "Not posted yet this week - it takes five minutes.")))
    })

    output$form <- renderUI({
      req(ctx$user$authed); nonce()
      isolate({
        cur <- wk(); cur <- cur[cur$email == me() & cur$week == this_week, , drop = FALSE]
        v <- function(col) if (nrow(cur)) cur[[col]][nrow(cur)] else ""
        div(class = "input-card",
          div(class = "section-h sm", span(class = "num mag", "1"), span(class = "lab mag", paste("Week of", format(week_start(), "%d %b"))), span(class = "dots mag")),
          textAreaInput(ns("done"), "What got done?", value = v("done"), rows = 3, width = "100%", placeholder = "Scored 4 grants, drafted the interface profile..."),
          textAreaInput(ns("nxt"), "What's next?", value = v("next"), rows = 2, width = "100%"),
          textAreaInput(ns("blockers"), "Anything blocking you? (the team will see this)", value = v("blockers"), rows = 2, width = "100%"),
          textInput(ns("shout"), "Shout-out: who helped, and how?", value = v("shoutout"), width = "100%", placeholder = "Thanks to Haijun for the cell data"),
          actionButton(ns("save"), if (nrow(cur)) "Update my week" else "Post my update", class = "btn-collab"))
      })
    })

    observeEvent(input$save, {
      req(ctx$user$authed)
      if (!nzchar(trimws(paste(input$done, input$nxt)))) { showNotification("Write at least what got done or what's next.", type = "warning"); return() }
      store_append("WeeklyUpdates", data.frame(email = me(), week = this_week, done = input$done %||% "", `next` = input$nxt %||% "",
        blockers = input$blockers %||% "", shoutout = input$shout %||% "", updated_at = now_ts(), check.names = FALSE))
      log_change(me(), "weekly_update", this_week, ""); ctx$bump(); nonce(nonce() + 1)
      showNotification("Update posted. +10 points", type = "message", duration = 4)
    })

    output$week_pick <- renderUI(selectInput(ns("week"), NULL, stats::setNames(weeks(), paste("Week of", format(as.Date(weeks()), "%d %b"))), width = "220px"))
    chosen <- reactive(input$week %||% this_week)

    digest <- reactive({
      w0 <- as.Date(chosen()); w1 <- w0 + 7
      inr <- function(ts) { t <- suppressWarnings(as.Date(substr(ts, 1, 10))); !is.na(t) & t >= w0 & t < w1 }
      d <- dec_latest(ctx$data$decisions())
      list(scored = sum(inr(ctx$data$prio()$updated_at)),
           ideas = sum(inr(ctx$data$ideas()$created_at)),
           views = sum(inr(ctx$data$dinputs()$updated_at)),
           posted = sum(inr(d$created_at)),
           decided = sum(d$status == "decided" & inr(d$decided_at)))
    })

    recap_df <- reactive({
      w <- weekly_latest(wk()); w <- w[w$week == chosen(), , drop = FALSE]
      w[order(w$updated_at, decreasing = TRUE), , drop = FALSE]
    })

    output$recap <- renderUI({
      req(ctx$user$authed)
      w <- recap_df(); g <- digest(); users <- ctx$data$users()
      act <- users[toupper(users$active) == "TRUE", , drop = FALSE]
      waiting <- setdiff(tolower(act$email), w$email)
      pill <- function(n, l) div(class = "dg", span(class = "n", n), span(class = "l", l))
      tagList(
        div(class = "digest", pill(g$scored, "grants scored"), pill(g$ideas, "ideas shared"), pill(g$posted, "decisions posted"),
            pill(g$views, "views added"), pill(g$decided, "decisions made")),
        if (nrow(w) == 0) div(class = "empty", "No updates for this week yet.") else
          div(class = "recap-list", lapply(seq_len(nrow(w)), function(k) {
            r <- w[k, ]
            div(class = "recap",
              div(class = "rc-h", span(class = "avatar", toupper(substr(display_name(r$email, users), 1, 1))), strong(display_name(r$email, users)), span(class = "when", time_ago(r$updated_at))),
              if (nzchar(r$done)) div(class = "rc-s", span(class = "rc-l done", "Done"), HTML(gsub("\n", "<br>", esc(r$done)))),
              if (nzchar(r[["next"]])) div(class = "rc-s", span(class = "rc-l next", "Next"), HTML(gsub("\n", "<br>", esc(r[["next"]])))),
              if (nzchar(r$blockers)) div(class = "rc-s block", span(class = "rc-l blk", "Blocked"), HTML(gsub("\n", "<br>", esc(r$blockers)))),
              if (nzchar(r$shoutout)) div(class = "rc-s", span(class = "rc-l shout", ico("star", 11), "Thanks"), esc(r$shoutout)))
          })),
        if (length(waiting)) div(class = "small muted mt-s", paste("Still to post:", paste(display_name(waiting, users), collapse = ", ")))
      )
    })

    output$dl <- downloadHandler(
      filename = function() paste0("weekly-recap-", chosen(), ".md"),
      content = function(file) {
        w <- recap_df(); g <- digest(); users <- ctx$data$users()
        L <- c(paste0("# Team recap - week of ", chosen()), "",
               sprintf("*%d grants scored, %d ideas shared, %d decisions posted, %d views added, %d decisions made.*", g$scored, g$ideas, g$posted, g$views, g$decided), "")
        for (k in seq_len(nrow(w))) {
          r <- w[k, ]
          L <- c(L, paste0("## ", display_name(r$email, users)), paste0("- **Done:** ", md_escape(r$done)), paste0("- **Next:** ", md_escape(r[["next"]])))
          if (nzchar(r$blockers)) L <- c(L, paste0("- **Blocked:** ", md_escape(r$blockers)))
          if (nzchar(r$shoutout)) L <- c(L, paste0("- **Thanks:** ", md_escape(r$shoutout)))
          L <- c(L, "")
        }
        writeLines(L, file)
      })
  })
}
