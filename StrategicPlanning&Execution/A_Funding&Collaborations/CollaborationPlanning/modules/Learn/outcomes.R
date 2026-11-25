# ---- module ----------------------------------------------
# id:           outcomes
# name:         Outcomes and lessons
# icon:         trophy
# description:  Result of each finished bid, the funder's score and feedback, and the lessons for next time
# packages:     shiny, DT
# -----------------------------------------------------------
# Saved to outcomes (latest per programme wins). Won bids move to Deliver (the project starts);
# lost, withdrawn and not pursued bids move to Learn.

outcomes_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("form")),
    card("Lessons so far",
      textInput(ns("q"), "Search", width = "100%", placeholder = "e.g. budget, letters of support, Innovate UK"),
      DTOutput(ns("table"))))
}

outcomes_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    oc <- reactive(latest_by(ctx$table("outcomes")(), "programme_id", "recorded_at"))
    output$form <- renderUI({
      req(!ctx$is_partner())
      p <- ctx$programmes(); pr <- ctx$data$projects()
      cand <- p[p$stage %in% c("Decide", "Plan", "Write", "Deliver", "Learn") | p$programme_id %in% pr$programme_id, , drop = FALSE]
      card("Record a result",
        layout_columns(col_widths = c(6, 3, 3),
          selectInput(ns("pid"), "Bid", programme_choices(cand), width = "100%"),
          selectInput(ns("result"), "Result", OUTCOME_RESULTS),
          textInput(ns("score"), "Score from the funder (if given)")),
        textAreaInput(ns("feedback"), "Reviewer feedback", rows = 4, width = "100%"),
        textAreaInput(ns("lessons"), "Lessons for next time", rows = 3, width = "100%"),
        actionButton(ns("save"), "Save result", class = "btn-brand"))
    })
    observeEvent(input$pid, { o <- oc(); o <- o[o$programme_id == input$pid, , drop = FALSE]
      if (nrow(o)) { updateSelectInput(session, "result", selected = o$result); updateTextInput(session, "score", value = o$score)
        updateTextAreaInput(session, "feedback", value = o$feedback); updateTextAreaInput(session, "lessons", value = o$lessons) } })
    observeEvent(input$save, {
      req(input$pid, !ctx$is_partner())
      store_append("outcomes", data.frame(programme_id = input$pid, result = input$result, score = input$score %||% "", feedback = input$feedback %||% "",
        lessons = input$lessons %||% "", recorded_by = ctx$user(), recorded_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      pr <- ctx$data$projects(); proj <- pr$project_id[pr$programme_id == input$pid][1]
      if (identical(input$result, "won")) {
        m <- move_programme_stage(input$pid, "Deliver", ctx$user())
        if (!is.na(proj %||% NA)) update_project(proj, list(status = "running"), ctx$user())
      } else {
        m <- move_programme_stage(input$pid, "Learn", ctx$user())
        if (!is.na(proj %||% NA)) update_project(proj, list(status = input$result), ctx$user())
      }
      ctx$bump(); showNotification(paste("Saved.", m$msg), type = "message")
    })
    output$table <- renderDT({
      o <- oc(); p <- ctx$programmes(); o <- o[o$programme_id %in% p$programme_id, , drop = FALSE]
      q <- tolower(trimws(input$q %||% ""))
      d <- data.frame(Recorded = substr(o$recorded_at, 1, 10), Bid = p$programme_name[match(o$programme_id, p$programme_id)],
                      Funder = p$funder[match(o$programme_id, p$programme_id)], Result = o$result, Score = o$score,
                      Feedback = o$feedback, Lessons = o$lessons)
      if (nzchar(q)) d <- d[grepl(q, tolower(do.call(paste, d)), fixed = TRUE), , drop = FALSE]
      datatable(d[order(d$Recorded, decreasing = TRUE), , drop = FALSE], rownames = FALSE, options = list(dom = "tip", pageLength = 10, scrollX = TRUE)) |>
        formatStyle("Result", color = styleEqual(c("won", "lost"), c("#2f9e6e", "#d6336c")), fontWeight = "bold")
    })
  })
}
