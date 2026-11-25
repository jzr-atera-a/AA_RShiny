# ---- module ----------------------------------------------
# id:           question_sets
# name:         Question sets
# icon:         list-ol
# description:  Application questions and word limits per programme; three examples are loaded at first start
# packages:     shiny, DT
# -----------------------------------------------------------

question_sets_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Each set lists a programme's application questions and word limits. Phase 4 will draft answers ",
         "against them. The three sets loaded at first start are ", tags$b("examples"),
         ": check every question and limit against the current competition brief."),
    layout_columns(col_widths = c(4, 8),
      card("Sets", uiOutput(ns("set_list"))),
      card(NULL, uiOutput(ns("set_view")))),
    uiOutput(ns("add_box")))
}

question_sets_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    sets <- reactive({
      q <- ctx$data$question_sets()
      q[order(q$set_id, suppressWarnings(as.numeric(q$question_no))), , drop = FALSE]
    })
    chosen <- reactiveVal(NULL)

    output$set_list <- renderUI({
      q <- sets()
      if (!nrow(q)) return(p(class = "muted", "No sets yet."))
      ids <- unique(q$set_id)
      sel <- chosen() %||% ids[1]
      radioButtons(ns("pick"), NULL, selected = sel,
                   choiceNames = lapply(ids, function(i) {
                     r <- q[q$set_id == i, ][1, ]
                     span(r$set_name, if (is_true(r$is_example)) example_badge(),
                          span(class = "small muted", sprintf(" %d questions", sum(q$set_id == i))))
                   }),
                   choiceValues = ids)
    })
    observeEvent(input$pick, chosen(input$pick))

    output$set_view <- renderUI({
      q <- sets(); req(nrow(q) > 0)
      sid <- chosen() %||% q$set_id[1]
      s <- q[q$set_id == sid, , drop = FALSE]; req(nrow(s) > 0)
      total <- sum(suppressWarnings(as.numeric(s$word_limit)), na.rm = TRUE)
      tagList(
        h4(s$set_name[1], if (is_true(s$is_example[1])) example_badge()),
        p(class = "muted small", s$funder[1], " - ", nrow(s), " questions, ", format(total, big.mark = ","), " words in total"),
        if (is_true(s$is_example[1])) note("warn", s$source_note[1]),
        tags$table(class = "qs-table",
          tags$thead(tags$tr(tags$th("#"), tags$th("Question"), tags$th("Words"))),
          tags$tbody(lapply(seq_len(nrow(s)), function(i) tags$tr(
            tags$td(s$question_no[i]),
            tags$td(tags$b(s$question[i]), if (nzchar(s$guidance[i])) div(class = "small muted", s$guidance[i])),
            tags$td(s$word_limit[i]))))),
        downloadButton(ns("dl"), "Download this set (CSV)", class = "btn-ghost sm"))
    })

    output$dl <- downloadHandler(
      filename = function() paste0(chosen() %||% "question_set", ".csv"),
      content = function(file) { q <- sets(); utils::write.csv(q[q$set_id == (chosen() %||% q$set_id[1]), ], file, row.names = FALSE) })

    # adding a set is for admins (unlocked), so the examples can't be changed by accident
    output$add_box <- renderUI({
      req(ctx$admin_ok())
      card("Add a question set (admins)",
        p(class = "small muted", "One question per line, as: question | word limit | guidance (guidance optional)."),
        layout_columns(col_widths = c(6, 6),
          textInput(ns("new_name"), "Set name", placeholder = "e.g. Innovate UK Smart, round 3"),
          textInput(ns("new_funder"), "Funder", placeholder = "e.g. Innovate UK")),
        textAreaInput(ns("new_lines"), NULL, rows = 6, width = "100%",
                      placeholder = "Project summary | 400 | What the project does\nNeed or challenge | 400"),
        actionButton(ns("add"), "Save set", class = "btn-brand"))
    })

    observeEvent(input$add, {
      req(ctx$admin_ok())
      lines <- trimws(strsplit(input$new_lines %||% "", "\n")[[1]])
      lines <- lines[nzchar(lines)]
      if (blank(input$new_name) || !length(lines)) return(showNotification("Add a name and at least one question.", type = "warning"))
      parts <- lapply(strsplit(lines, "|", fixed = TRUE), trimws)
      sid <- new_id("qs")
      df <- data.frame(set_id = sid, set_name = input$new_name, funder = input$new_funder %||% "",
                       question_no = as.character(seq_along(parts)),
                       question = vapply(parts, `[`, "", 1),
                       guidance = vapply(parts, function(p) if (length(p) >= 3) p[3] else "", ""),
                       word_limit = vapply(parts, function(p) if (length(p) >= 2) p[2] else "", ""),
                       is_example = "FALSE", source_note = "", added_by = ctx$user(), added_at = now_ts(),
                       stringsAsFactors = FALSE)
      store_append("question_sets", df, user = ctx$user())
      chosen(sid); ctx$bump()
      updateTextAreaInput(session, "new_lines", value = "")
      showNotification("Question set saved.", type = "message")
    })
  })
}
