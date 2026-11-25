# ---- module ----------------------------------------------
# id:           ideas
# name:         Ideas
# icon:         lightbulb
# description:  Anyone can add an idea for a bid; everyone votes; the best become decisions
# packages:     shiny
# -----------------------------------------------------------
# Built to the Grant Compass mod_ideas.R design, with programme_id added.

ideas_ui <- function(id) {
  ns <- NS(id)
  layout_columns(col_widths = c(4, 8),
    card("Add an idea",
      selectInput(ns("pid"), "Bid", NULL, width = "100%"),
      textInput(ns("title"), "Idea", width = "100%"),
      textAreaInput(ns("detail"), "Detail", rows = 3, width = "100%"),
      actionButton(ns("add"), "Add idea", class = "btn-brand")),
    card("Ideas",
      layout_columns(col_widths = c(6, 6),
        selectInput(ns("f_pid"), "Show", NULL, width = "100%"),
        selectInput(ns("f_status"), "Status", c("Open" = "open", "Adopted" = "adopted", "Parked" = "parked", "All" = "all"))),
      uiOutput(ns("list"))))
}

ideas_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    ideas <- reactive(latest_by(ctx$table("ideas")(), "idea_id"))
    votes <- reactive(latest_by(ctx$table("idea_votes")(), c("idea_id", "email")))
    observe({
      p <- ctx$programmes()
      ch <- programme_choices(p, if (!ctx$is_partner()) NULL else STAGES, none = if (!ctx$is_partner()) "(general)")
      updateSelectInput(session, "pid", choices = ch, selected = pick_sel(isolate(input$pid), ch))
      updateSelectInput(session, "f_pid", choices = c("All bids" = "*", programme_choices(p)), selected = pick_sel(isolate(input$f_pid), c("*", programme_choices(p))))
    })
    observeEvent(input$add, {
      if (blank(input$title)) return(showNotification("Write the idea first.", type = "warning"))
      store_append("ideas", data.frame(idea_id = new_id("idea"), programme_id = input$pid %||% "", title = input$title,
        detail = input$detail %||% "", status = "open", created_by = ctx$user(), created_at = now_ts(), updated_at = now_ts(),
        stringsAsFactors = FALSE), user = ctx$user())
      updateTextInput(session, "title", value = ""); updateTextAreaInput(session, "detail", value = "")
      ctx$bump(); showNotification("Idea added.", type = "message")
    })
    shown <- reactive({
      d <- ideas(); vis <- ctx$programmes()$programme_id
      d <- if (ctx$is_partner()) d[d$programme_id %in% vis, , drop = FALSE] else d[!nzchar(d$programme_id) | d$programme_id %in% vis, , drop = FALSE]
      if (!identical(input$f_pid %||% "*", "*")) d <- d[d$programme_id == input$f_pid, , drop = FALSE]
      if (!identical(input$f_status, "all")) d <- d[d$status == input$f_status, , drop = FALSE]
      v <- votes()
      d$score <- vapply(d$idea_id, function(i) sum(num(v$vote[v$idea_id == i])), 1)
      d$mine <- vapply(d$idea_id, function(i) { x <- v$vote[v$idea_id == i & tolower(v$email) == tolower(ctx$user())]; if (length(x)) num(x) else 0 }, 1)
      d[order(-d$score, d$created_at), , drop = FALSE]
    })
    output$list <- renderUI({
      d <- shown(); if (!nrow(d)) return(p(class = "small muted", "No ideas here yet."))
      p <- ctx$programmes()
      tagList(lapply(seq_len(nrow(d)), function(i) div(class = "res-card",
        div(style = "display:flex; justify-content:space-between; gap:10px",
          div(h5(d$title[i]), div(class = "small muted", p$programme_name[match(d$programme_id[i], p$programme_id)] %|% "General", " - ",
                                  d$created_by[i], " - ", d$status[i])),
          div(style = "white-space:nowrap",
            tags$button(class = paste("btn btn-ghost sm", if (d$mine[i] > 0) "active"), onclick = js_click(ns("vote"), list(id = d$idea_id[i], v = 1)), icon("thumbs-up")),
            span(class = "big-n", style = "font-size:1.1rem; margin:0 6px", d$score[i]),
            tags$button(class = "btn btn-ghost sm", onclick = js_click(ns("vote"), list(id = d$idea_id[i], v = -1)), icon("thumbs-down")))),
        if (nzchar(d$detail[i])) p(class = "small", d$detail[i]),
        if (!ctx$is_partner()) div(class = "pc-act",
          tags$a(onclick = js_click(ns("status"), list(id = d$idea_id[i], s = "adopted")), "Adopt"), " | ",
          tags$a(onclick = js_click(ns("status"), list(id = d$idea_id[i], s = "parked")), "Park"), " | ",
          tags$a(onclick = js_click(ns("to_dec"), d$idea_id[i]), "Turn into a decision")))))
    })
    observeEvent(input$vote, {
      v <- input$vote; cur <- shown(); mine <- cur$mine[cur$idea_id == v$id]
      new <- if (length(mine) && mine == v$v) 0 else v$v   # clicking the same vote again takes it back
      store_append("idea_votes", data.frame(idea_id = v$id, email = tolower(ctx$user()), vote = new, updated_at = now_ts(),
                                            stringsAsFactors = FALSE), user = ctx$user(), log = FALSE)
      ctx$bump()
    })
    observeEvent(input$status, {
      req(!ctx$is_partner()); d <- ideas(); r <- d[d$idea_id == input$status$id, , drop = FALSE]; req(nrow(r) > 0)
      r$status <- input$status$s; r$updated_at <- now_ts(); store_append("ideas", r, user = ctx$user()); ctx$bump()
    })
    observeEvent(input$to_dec, {
      req(!ctx$is_partner()); d <- ideas(); r <- d[d$idea_id == input$to_dec, , drop = FALSE]; req(nrow(r) > 0)
      create_decision(paste("Adopt the idea:", r$title, "?"), r$detail, c("Adopt", "Park"), ctx$user(), programme_id = r$programme_id)
      ctx$bump(); showNotification("Decision opened.", type = "message"); ctx$nav("decide", "decisions")
    })
  })
}
