# ---- module ----------------------------------------------
# id:           weekly_updates
# name:         Weekly updates
# icon:         calendar-week
# description:  Each person writes what they did, what is next and what blocks them; blockers raise a flag on Home
# packages:     shiny
# -----------------------------------------------------------
# Built to the Grant Compass mod_weekly.R design, with project_id. Saved to weekly (latest per email + project + week).

weekly_updates_ui <- function(id) {
  ns <- NS(id)
  layout_columns(col_widths = c(5, 7),
    card("Your update",
      selectInput(ns("proj"), "Project", NULL, width = "100%"),
      dateInput(ns("week"), "Week starting (Monday)", value = Sys.Date() - (as.integer(format(Sys.Date(), "%u")) - 1), weekstart = 1),
      textAreaInput(ns("done"), "Done this week", rows = 3, width = "100%"),
      textAreaInput(ns("next_"), "Next week", rows = 3, width = "100%"),
      textAreaInput(ns("block"), "Blocked by (leave empty if nothing)", rows = 2, width = "100%"),
      textInput(ns("shout"), "Shout-out (optional)", width = "100%"),
      actionButton(ns("save"), "Save update", class = "btn-brand")),
    card("Team updates", uiOutput(ns("team"))))
}

weekly_updates_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    monday <- reactive({ d <- as.Date(input$week %||% Sys.Date()); format(d - (as.integer(format(d, "%u")) - 1)) })
    wk <- reactive({ w <- latest_by(ctx$table("weekly")(), c("email", "project_id", "week")); w[w$project_id == (input$proj %||% ""), , drop = FALSE] })
    observeEvent(list(input$proj, monday()), {
      w <- wk(); m <- w[w$week == monday() & tolower(w$email) == tolower(ctx$user()), , drop = FALSE]
      updateTextAreaInput(session, "done", value = m$done[1] %||% ""); updateTextAreaInput(session, "next_", value = m$`next`[1] %||% "")
      updateTextAreaInput(session, "block", value = m$blockers[1] %||% ""); updateTextInput(session, "shout", value = m$shoutout[1] %||% "")
    })
    observeEvent(input$save, {
      req(input$proj)
      if (!nzchar(trimws(paste(input$done, input$next_, input$block)))) return(showNotification("Write at least one line.", type = "warning"))
      store_append("weekly", data.frame(email = tolower(ctx$user()), project_id = input$proj, week = monday(), done = input$done %||% "",
        `next` = input$next_ %||% "", blockers = trimws(input$block %||% ""), shoutout = input$shout %||% "", updated_at = now_ts(),
        check.names = FALSE, stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification(if (nzchar(trimws(input$block %||% ""))) "Saved. The blocker is flagged on Home and in Meet by exception." else "Saved.",
                                   type = "message")
    })
    output$team <- renderUI({
      w <- wk(); if (!length(project_picker_choices(ctx))) return(project_empty_note())
      w <- w[order(w$week, decreasing = TRUE), , drop = FALSE]
      if (!nrow(w)) return(p(class = "small muted", "No updates for this project yet."))
      weeks <- utils::head(unique(w$week), 4)
      tagList(lapply(weeks, function(k) { x <- w[w$week == k, , drop = FALSE]; tagList(h5("Week of ", k),
        lapply(seq_len(nrow(x)), function(i) div(class = "res-card",
          tags$b(x$email[i]), if (nzchar(x$blockers[i])) span(class = "pill pill-flag", icon("flag"), " Blocked"),
          tags$table(class = "kv", if (nzchar(x$done[i])) tags$tr(tags$th("Done"), tags$td(x$done[i])),
                     if (nzchar(x$`next`[i])) tags$tr(tags$th("Next"), tags$td(x$`next`[i])),
                     if (nzchar(x$blockers[i])) tags$tr(tags$th("Blocked by"), tags$td(x$blockers[i])),
                     if (nzchar(x$shoutout[i])) tags$tr(tags$th("Shout-out"), tags$td(x$shoutout[i])))))) }))
    })
  })
}
