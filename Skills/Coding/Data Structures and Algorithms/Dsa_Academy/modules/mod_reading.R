# modules/mod_reading.R — "Read this code and explain it": predict output, complexity, find the bug, explain.

reading_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔍", "Code Reading",
      "Google has piloted interview segments where you read unfamiliar code and explain it, and AI-assisted rounds reward the same skill: understanding code you did not write. Read first, commit to an answer, then run it.",
      c("Predict the output", "Complexity", "Find the bug", "Explain it", "Python gotchas")),
    python_banner(),
    fluidRow(
      column(3,
        box(title = "Exercises", status = "primary", solidHeader = TRUE, width = NULL,
          selectInput(ns("kind"), NULL, c("All kinds" = "all", "Predict the output" = "output", "Complexity" = "complexity",
                                          "Find the bug" = "bug", "Explain what it does" = "explain")),
          uiOutput(ns("list")),
          uiOutput(ns("stats")))
      ),
      column(9,
        box(title = uiOutput(ns("title"), inline = TRUE), status = "primary", solidHeader = TRUE, width = NULL,
          fluidRow(
            column(7, uiOutput(ns("code")),
                   tags$div(style = "display:flex; gap:6px; margin-top:6px;",
                     actionButton(ns("run"), "▶ Run it", class = "btn btn-dsa-outline btn-sm"),
                     actionButton(ns("next_ex"), "Next exercise →", class = "btn btn-dsa btn-sm")),
                   uiOutput(ns("run_out"))),
            column(5,
              textAreaInput(ns("explain"), "1 · In your own words: what does this code do?", "", rows = 4, width = "100%",
                            placeholder = "Say it as you would to an interviewer: purpose, key idea, complexity, edge cases."),
              tags$div(class = "code-title", "2 · Commit to an answer"),
              uiOutput(ns("question")),
              uiOutput(ns("feedback"))))
        )
      )
    )
  )
}

reading_server <- function(id, progress = NULL, bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    ids <- names(READING)
    st <- reactiveValues(cur = ids[1], pick = NULL, opened = Sys.time(), run = NULL, att_id = NULL, tick = 0)

    visible <- reactive({
      k <- input$kind %||% "all"
      ids[vapply(READING, function(e) k == "all" || e$kind == k, TRUE)]
    })
    done <- reactive({
      st$tick
      a <- db_table("reading_attempts")
      if (!nrow(a)) return(setNames(logical(0), character(0)))
      tapply(a$correct == 1, a$ex_id, any)
    })
    E <- reactive(READING[[st$cur]])

    select_ex <- function(id) {
      st$cur <- id; st$pick <- NULL; st$run <- NULL; st$opened <- Sys.time(); st$att_id <- NULL
      updateTextAreaInput(session, "explain", value = "")
    }
    observeEvent(input$pick_ex, select_ex(input$pick_ex))
    observeEvent(input$next_ex, {
      v <- visible(); i <- match(st$cur, v)
      select_ex(if (is.na(i) || i == length(v)) v[1] else v[i + 1])
    })

    kind_lab <- c(output = "output", complexity = "Big-O", bug = "bug", explain = "explain")
    output$list <- renderUI({
      d <- done()
      tagList(lapply(visible(), function(i) {
        e <- READING[[i]]
        tags$div(class = paste("rd-card", if (i == st$cur) "on"),
                 onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", ns("pick_ex"), i),
                 tags$span(class = "kind-pill", kind_lab[[e$kind]]), tags$span(e$title),
                 if (isTRUE(d[i])) tags$span(class = "done", "✓"))
      }))
    })
    output$stats <- renderUI({
      st$tick
      a <- db_table("reading_attempts")
      first <- a[!duplicated(a$ex_id, fromLast = TRUE), , drop = FALSE]
      kpi_row(kpi(sprintf("%d / %d", sum(done()), length(ids)), "solved", COL$ok),
              kpi(if (nrow(first)) sprintf("%.0f%%", 100 * mean(first$correct == 1)) else "—", "first-try accuracy", COL$pri))
    })

    output$title <- renderUI({ e <- E(); tagList(e$title, tags$span(class = "kind-pill", style = "margin-left:8px;", e$level)) })
    output$code <- renderUI({
      e <- E(); n <- length(strsplit(e$code, "\n")[[1]])
      ace_editor(ns(paste0("code_", e$id)), e$code, height = sprintf("%dpx", min(460, 26 + 19 * n)), readonly = TRUE)
    })
    output$question <- renderUI({
      e <- E(); pick <- st$pick
      tagList(tags$p(HTML(e$question)),
        lapply(seq_along(e$options), function(k) {
          cls <- "btn btn-default rd-opt"
          if (!is.null(pick)) cls <- paste(cls, if (k == e$answer) "right" else if (k == pick) "wrong" else "")
          tags$button(class = cls, disabled = if (!is.null(pick)) NA,
                      onclick = sprintf("Shiny.setInputValue('%s', %d, {priority: 'event'})", ns("answer"), k), e$options[[k]])
        }))
    })
    observeEvent(input$answer, {
      if (!is.null(st$pick)) return()
      e <- E(); st$pick <- input$answer
      secs <- as.numeric(difftime(Sys.time(), st$opened, units = "secs"))
      st$att_id <- db_insert("reading_attempts", list(ts = now_ts(), day = today(), ex_id = e$id, correct = as.integer(input$answer == e$answer),
                                                      seconds = secs, explanation = input$explain %||% "", self_score = NA))
      st$tick <- st$tick + 1; if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1
    })
    output$feedback <- renderUI({
      e <- E(); pick <- st$pick
      if (is.null(pick)) return(hint("Write your explanation first, then pick an answer. Running the code unlocks after you answer."))
      ok <- pick == e$answer
      tagList(
        callout(paste0("<b>", if (ok) "Correct." else "Not quite.", "</b> ", e$explanation), if (ok) "success" else "warn"),
        tags$div(class = "code-title", "A model one-line explanation"),
        tags$blockquote(style = "font-size:13px;", e$model),
        if (nzchar(input$explain %||% "")) tagList(
          tags$div(class = "code-title", "How close was your explanation?"),
          radioButtons(ns("self"), NULL, inline = TRUE, selected = character(0),
                       choices = c("Missed the point" = 1, "Partly" = 2, "Mostly" = 3, "Spot on, incl. complexity / edge cases" = 4))))
    })
    observeEvent(input$self, {
      if (!is.null(st$att_id)) db_update("reading_attempts", st$att_id, list(self_score = as.numeric(input$self), explanation = input$explain %||% ""))
    })
    observeEvent(input$run, {
      if (is.null(st$pick)) { showNotification("Commit to an answer first — then run it to check.", type = "warning"); return() }
      e <- E()
      code <- e$code
      if (e$kind %in% c("explain", "complexity", "bug")) code <- paste0(code, "\nprint('(defines functions only — call them yourself in the Problem Workspace to experiment)')\n")
      st$run <- run_project("exec", code = code, limit = 15)
    })
    output$run_out <- renderUI({
      r <- st$run; if (is.null(r)) return(NULL)
      tagList(tags$div(class = "code-title", style = "margin-top:8px;", "Output"),
              tags$pre(class = "res-error", style = "background:#0f172a; color:#e2e8f0;", paste0(r$stdout %||% "", if (nzchar(r$stderr %||% "")) paste0("\n", r$stderr) else "",
                                                                                           if (!is.null(r$msg)) r$msg else "")))
    })
  })
}
