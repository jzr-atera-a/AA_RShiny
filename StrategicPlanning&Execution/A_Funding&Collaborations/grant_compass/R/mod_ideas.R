# ---- Ideas: suggestions from the team's interests + a votable board ----------------------

mod_ideas_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow", "Ideas"),
      h2("From interest to project ideas"),
      p(class = "lead", "We turn the grants people scored highest, plus their stated interests, into starting ideas. Add the good ones to the board, write your own, and vote.")),
    div(class = "spark",
      div(class = "section-h", span(class = "num mag", "1"), span(class = "lab mag", "Spark some ideas"), span(class = "dots mag")),
      layout_columns(col_widths = c(4, 4, 4),
        selectInput(ns("basis"), "Base them on", width = "100%",
                    choices = c("My top-scored grants" = "mine", "The team's top-scored grants" = "team", "Every open grant" = "all")),
        textInput(ns("kw"), "Extra keywords (optional)", placeholder = "e.g. drones, energy benchmarking", width = "100%"),
        div(class = "spark-actions",
            uiOutput(ns("ai_toggle")),
            actionButton(ns("gen"), "Generate ideas", class = "btn-brand w-100"))),
      uiOutput(ns("suggestions"))),
    div(class = "section-h mt", span(class = "num", "2"), span(class = "lab", "Idea board"), span(class = "dots")),
    div(class = "board-bar",
        selectInput(ns("sort"), NULL, c("Most votes" = "votes", "Newest" = "new"), width = "180px"),
        actionButton(ns("add_own"), "+ Add my own idea", class = "btn-ghost")),
    uiOutput(ns("board"))
  )
}

mod_ideas_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    suggestions <- reactiveVal(NULL)

    ai_ready <- reactive(identical(ctx$settings()$llm_enabled, "true") && nzchar(.store$api_key))
    output$ai_toggle <- renderUI({
      if (ai_ready()) checkboxInput(ns("use_ai"), "Use AI for richer ideas", value = TRUE)
      else div(class = "small muted", "AI ideas are off (enable in Admin > Integrations). Using built-in templates.")
    })

    chosen_grants <- reactive({
      g <- ctx$data$grants(); g <- g[g$status %in% c("open", "upcoming", ""), , drop = FALSE]
      p <- latest_by(ctx$data$prio(), c("email", "grant_id"))
      w <- c(num(ctx$settings()$w_alignment, 1.5), num(ctx$settings()$w_interest, 1), num(ctx$settings()$w_capability, 1.5))
      if (input$basis == "all") return(head(g, 6))
      if (input$basis == "mine") p <- p[p$email == ctx$user$email, , drop = FALSE]
      if (nrow(p) == 0) return(g[0, ])
      p$score <- calc_score(p$alignment, p$interest, p$capability, w)
      p <- p[p$stance != "pass", , drop = FALSE]
      s <- tapply(p$score, p$grant_id, mean)
      top <- names(sort(s, decreasing = TRUE))[seq_len(min(4, length(s)))]
      g[match(top, g$grant_id), , drop = FALSE] |> stats::na.omit()
    })

    interests <- function() {
      u <- ctx$data$users()
      if (input$basis == "team") unique(unlist(lapply(u$interests, split_tags)))
      else split_tags(u$interests[tolower(u$email) == ctx$user$email])
    }

    observeEvent(input$gen, {
      req(ctx$user$authed)
      g <- chosen_grants()
      if (nrow(g) == 0) {
        showNotification("Score at least one grant first (or choose 'Every open grant').", type = "warning"); return()
      }
      extra <- split_tags(input$kw)
      res <- NULL
      if (isTRUE(input$use_ai) && ai_ready()) {
        res <- tryCatch(gen_ideas_ai(g, interests(), extra, .store$api_key, ctx$settings()$llm_model),
                        error = function(e) { showNotification(paste("AI call failed, using templates:", conditionMessage(e)), type = "warning", duration = 8); NULL })
      }
      if (is.null(res) || nrow(res) == 0) res <- gen_ideas_rule(g, interests(), extra)
      suggestions(res)
      log_change(ctx$user$email, "generate_ideas", paste(g$grant_id, collapse = ";"), paste(nrow(res), "ideas"))
    })

    output$suggestions <- renderUI({
      s <- suggestions()
      if (is.null(s) || nrow(s) == 0) return(div(class = "empty slim", "Suggestions will appear here."))
      tagList(
        div(class = "sug-head", span(class = "small muted", paste(nrow(s), "suggestions")),
            actionButton(ns("add_all"), "Add all to board", class = "btn-ghost sm")),
        div(class = "card-grid", lapply(seq_len(nrow(s)), function(k) {
          div(class = "icard sug",
            div(class = "itop", chip(if (s$origin[k] == "ai") "AI suggestion" else "Template", if (s$origin[k] == "ai") "mag" else "teal")),
            h3(s$title[k]), p(s$pitch[k]), div(class = "chips", chips(s$themes[k])),
            tags$button(class = "btn-brand sm", onclick = onclick_input(ns("add_sug"), k), "Add to board"))
        })))
    })

    add_ideas <- function(df) {
      if (is.null(df) || nrow(df) == 0) return()
      df <- df[!(tolower(df$title) %in% tolower(ctx$data$ideas()$title)), , drop = FALSE]  # skip duplicates
      if (nrow(df) == 0) { showNotification("Those ideas are already on the board.", type = "warning"); return() }
      rows <- data.frame(idea_id = paste0(new_id("i"), sprintf("%02d", seq_len(nrow(df)))),
                         title = df$title, pitch = df$pitch, linked_grants = df$linked_grants, themes = df$themes,
                         origin = df$origin, author = ctx$user$email, created_at = now_ts(), status = "open")
      store_append("Ideas", rows)
      log_change(ctx$user$email, "add_idea", paste(rows$idea_id, collapse = ";"), paste(rows$title, collapse = " | "))
      ctx$bump()
    }
    observeEvent(input$add_sug, {
      s <- suggestions(); k <- as.integer(input$add_sug); req(k <= nrow(s))
      add_ideas(s[k, ]); suggestions(s[-k, , drop = FALSE])
      showNotification("Added to the board. +15 points", type = "message", duration = 3)
    })
    observeEvent(input$add_all, {
      add_ideas(suggestions()); suggestions(NULL)
      showNotification("All added to the board.", type = "message", duration = 3)
    })

    observeEvent(input$add_own, {
      showModal(modalDialog(title = "Share an idea", easyClose = TRUE, footer = tagList(modalButton("Cancel"), actionButton(ns("save_own"), "Add to board", class = "btn-brand")),
        textInput(ns("o_title"), "Title", width = "100%"),
        textAreaInput(ns("o_pitch"), "The pitch in a few lines", rows = 3, width = "100%"),
        textInput(ns("o_themes"), "Themes (separate with ;)", placeholder = "batteries; drones", width = "100%")))
    })
    observeEvent(input$save_own, {
      req(nzchar(trimws(input$o_title)))
      add_ideas(data.frame(title = input$o_title, pitch = input$o_pitch, linked_grants = "", themes = input$o_themes, origin = "user"))
      removeModal()
      showNotification("Thanks for sharing! +15 points", type = "message", duration = 3)
    })

    observeEvent(input$promote, {
      i <- ctx$data$ideas(); r <- i[i$idea_id == input$promote, , drop = FALSE]; req(nrow(r) == 1)
      lg <- split_tags(r$linked_grants)[1]
      ctx$draft(list(
        title = paste0("How should we approach: ", r$title, "?"), category = "Project approach",
        context = paste0(r$pitch, "\n\n(Promoted from the idea board.)"), linked_grant = if (is.na(lg)) "" else lg, linked_idea = r$idea_id,
        o1 = "Lead it ourselves", d1 = "We own the bid and bring partners in.",
        o2 = "Partner-led, we contribute", d2 = "Another organisation leads; we supply a defined capability.",
        o3 = "Park it for now", d3 = "Revisit when scope, partners or timing are clearer."))
      ctx$nav("Decisions")
    })

    votes_latest <- reactive(latest_by(ctx$data$votes(), c("idea_id", "voter")))

    observeEvent(input$vote, {
      req(ctx$user$authed)
      v <- votes_latest(); had <- any(v$idea_id == input$vote & v$voter == ctx$user$email & v$vote == "1")
      store_append("IdeaVotes", data.frame(idea_id = input$vote, voter = ctx$user$email, vote = if (had) "0" else "1", updated_at = now_ts()))
      log_change(ctx$user$email, if (had) "unvote" else "vote", input$vote, "")
      ctx$bump()
    })

    output$board <- renderUI({
      req(ctx$user$authed)
      i <- ctx$data$ideas(); i <- i[i$status != "archived", , drop = FALSE]
      if (nrow(i) == 0) return(div(class = "empty", "The board is empty. Generate suggestions above or add your own."))
      v <- votes_latest(); v <- v[v$vote == "1", , drop = FALSE]
      i$votes <- vapply(i$idea_id, function(x) sum(v$idea_id == x), 1)
      i$mine  <- i$idea_id %in% v$idea_id[v$voter == ctx$user$email]
      i <- if (input$sort == "new") i[order(i$created_at, decreasing = TRUE), ] else i[order(-i$votes, i$created_at), ]
      users <- ctx$data$users(); g <- ctx$data$grants()
      div(class = "card-grid", lapply(seq_len(nrow(i)), function(k) {
        r <- i[k, ]
        linked <- split_tags(r$linked_grants)
        lt <- short_title(g$title[match(linked[1], g$grant_id)] %||% "")
        div(class = "icard",
          tags$button(class = paste("votebtn", if (r$mine) "on"), onclick = onclick_input(ns("vote"), r$idea_id),
                      span(class = "arr", HTML("&#9650;")), span(class = "cnt", r$votes)),
          div(class = "ibody",
            h3(r$title), p(r$pitch),
            div(class = "chips", chips(r$themes), if (nzchar(lt)) chip(paste("for:", lt), "grey")),
            div(class = "ifoot", span(class = "small muted", paste("by", display_name(r$author, users), "-", time_ago(r$created_at))),
                tags$button(class = "btn-collab sm", onclick = onclick_input(ns("promote"), r$idea_id), "Decide how to approach"))))
      }))
    })
  })
}
