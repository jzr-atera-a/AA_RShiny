# ---- Prioritise: score each grant, see your ranking and the team's -------------------------

mod_prio_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow", "Your call"),
      h2("Which grants fit us best?"),
      p(class = "lead", "Pick a grant, rate it 1-5 on three questions, and choose your stance. You can change your mind any time; the team ranking updates for everyone.")),
    layout_columns(col_widths = c(5, 7),
      div(uiOutput(ns("picker"))),
      div(uiOutput(ns("editor")))),
    div(class = "section-h mt", span(class = "num", "A"), span(class = "lab", "Rankings"), span(class = "dots")),
    navset_pill(id = ns("rank_tabs"),
      nav_panel("My ranking", uiOutput(ns("mine"))),
      nav_panel("Team ranking", uiOutput(ns("team"))))
  )
}

mod_prio_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    sel <- reactiveVal(NULL)

    observeEvent(ctx$pick(), sel(ctx$pick()), ignoreNULL = TRUE)
    observeEvent(input$pick, sel(input$pick))

    weights <- reactive({
      s <- ctx$settings()
      c(num(s$w_alignment, 1.5), num(s$w_interest, 1), num(s$w_capability, 1.5))
    })
    scoreable <- reactive({
      g <- ctx$data$grants(); g[g$status %in% c("open", "upcoming", ""), , drop = FALSE]
    })
    latest <- reactive(latest_by(ctx$data$prio(), c("email", "grant_id")))
    mine <- reactive({ p <- latest(); p[p$email == ctx$user$email, , drop = FALSE] })

    output$picker <- renderUI({
      req(ctx$user$authed)
      g <- scoreable(); m <- mine()
      if (nrow(g) == 0) return(div(class = "empty", "No open grants yet."))
      div(class = "picker", lapply(seq_len(nrow(g)), function(k) {
        r <- g[k, ]; done <- r$grant_id %in% m$grant_id
        div(class = paste("pick", if (identical(sel(), r$grant_id)) "active", if (done) "done"),
            onclick = onclick_input(ns("pick"), r$grant_id),
            span(class = "tick", if (done) HTML("&#10003;") else ""),
            div(div(class = "pt", short_title(r$title)), div(class = "ps", paste(r$funder, "-", fmt_gbp(r$min_gbp, r$max_gbp)))))
      }))
    })

    output$editor <- renderUI({
      req(ctx$user$authed)
      if (is.null(sel())) return(div(class = "editor placeholder", div(class = "big-arrow", HTML("&larr;")), p("Choose a grant on the left to start scoring.")))
      g <- scoreable(); r <- g[g$grant_id == sel(), , drop = FALSE]
      req(nrow(r) == 1)
      cur <- isolate(mine()); cur <- cur[cur$grant_id == sel(), , drop = FALSE]
      v <- function(col, d) if (nrow(cur) == 1) num(cur[[col]], d) else d
      sl <- function(idn, label, hint, d) sliderInput(ns(idn), label, min = 1, max = 5, value = v(idn, d), step = 1, ticks = TRUE, width = "100%") |>
        tagAppendChild(div(class = "hint", hint))
      div(class = "editor",
        div(class = "eyebrow", r$funder),
        h3(r$title),
        p(class = "gsum", r$summary),
        sl("alignment", "How well does it align with what we already do?", "1 = a stretch, 5 = squarely our work", 3),
        sl("interest", "How excited are you to work on it?", "1 = low, 5 = can't wait", 3),
        sl("capability", "How ready are we (people, evidence, partners)?", "1 = start from scratch, 5 = ready now", 3),
        radioButtons(ns("stance"), "My stance", choices = STANCES,
                     selected = if (nrow(cur) == 1) cur$stance else "partner", inline = TRUE),
        textAreaInput(ns("note"), "Why? (optional - helps the team)", value = if (nrow(cur) == 1) cur$note else "", rows = 2, width = "100%"),
        uiOutput(ns("live_score")),
        actionButton(ns("save"), if (nrow(cur) == 1) "Update my score" else "Save my score", class = "btn-brand")
      )
    })

    output$live_score <- renderUI({
      req(input$alignment)
      sc <- calc_score(input$alignment, input$interest, input$capability, weights())
      div(class = "live-score", span(class = "n", sc), span(class = "l", "fit score (0-100)"),
          div(class = "meter", div(class = "fillbar", style = paste0("width:", sc, "%"))))
    })

    observeEvent(input$save, {
      req(ctx$user$authed, sel())
      store_append("Priorities", data.frame(
        email = ctx$user$email, grant_id = sel(), alignment = input$alignment, interest = input$interest,
        capability = input$capability, stance = input$stance, note = input$note %||% "", updated_at = now_ts()))
      log_change(ctx$user$email, "score", sel(), paste(input$alignment, input$interest, input$capability, input$stance))
      ctx$bump()
      showNotification("Saved - thanks! +10 points", type = "message", duration = 4)
    })

    rank_df <- function(p, g) {
      if (nrow(p) == 0) return(NULL)
      p$score <- calc_score(p$alignment, p$interest, p$capability, weights())
      p$title <- g$title[match(p$grant_id, g$grant_id)]
      p$funder <- g$funder[match(p$grant_id, g$grant_id)]
      p[!is.na(p$title), , drop = FALSE]
    }

    output$mine <- renderUI({
      req(ctx$user$authed)
      d <- rank_df(mine(), ctx$data$grants())
      if (is.null(d) || nrow(d) == 0) return(div(class = "empty", "You haven't scored anything yet."))
      d <- d[order(-d$score), ]
      div(class = "rank-list", lapply(seq_len(nrow(d)), function(k) {
        div(class = "rank-row", onclick = onclick_input(ns("pick"), d$grant_id[k]),
          span(class = "rk", k),
          div(class = "rt", d$title[k], div(class = "bar", div(style = paste0("width:", d$score[k], "%")))),
          chip(names(STANCES)[match(d$stance[k], STANCES)], paste0("stance-", d$stance[k])),
          span(class = "sc", d$score[k]))
      }))
    })

    output$team <- renderUI({
      req(ctx$user$authed)
      d <- rank_df(latest(), ctx$data$grants())
      if (is.null(d) || nrow(d) == 0) return(div(class = "empty", "No scores yet - yours could be the first."))
      agg <- do.call(rbind, lapply(split(d, d$grant_id), function(x) data.frame(
        grant_id = x$grant_id[1], title = x$title[1], score = round(mean(x$score)), raters = nrow(x),
        leads = sum(x$stance == "lead"), partners = sum(x$stance == "partner"), passes = sum(x$stance == "pass"))))
      agg <- agg[order(-agg$score, -agg$raters), ]
      div(class = "rank-list", lapply(seq_len(nrow(agg)), function(k) {
        a <- agg[k, ]
        div(class = "rank-row static",
          span(class = "rk", k),
          div(class = "rt", a$title, div(class = "bar teal", div(style = paste0("width:", a$score, "%")))),
          div(class = "tm", span(sprintf("%d rater%s", a$raters, ifelse(a$raters == 1, "", "s"))),
              span(class = "small muted", paste0(a$leads, " lead / ", a$partners, " partner / ", a$passes, " pass"))),
          span(class = "sc", a$score))
      }))
    })
  })
}
