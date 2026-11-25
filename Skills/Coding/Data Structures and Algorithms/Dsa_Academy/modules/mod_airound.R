# modules/mod_airound.R — AI-assisted coding round: a small multi-file project, a flawed AI suggestion
# to review, tests the candidate must write, and hidden tests.

airound_ui <- function(id) {
  ns <- NS(id)
  choices <- setNames(names(PROJECTS), vapply(PROJECTS, function(p) sprintf("%s  ·  %s  ·  %s min", p$title, p$difficulty, p$minutes), ""))
  tagList(
    topic_hero("🤖", "AI-Assisted Round",
      "Meta now runs a coding round in which an AI assistant is available, and Google has piloted similar formats. What gets assessed is your judgement: reading a codebase quickly, checking what the assistant suggests, writing the tests that would catch its mistakes, and finishing a correct change.",
      c("Multi-file project", "Review the AI diff", "Write the tests", "Hidden tests", "Mutation audit", "Debrief")),
    python_banner(),
    fluidRow(
      box(title = "Project", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(5, selectInput(ns("pid"), NULL, choices, width = "100%")),
          column(3, uiOutput(ns("clock"))),
          column(4, tags$div(style = "display:flex; gap:6px; flex-wrap:wrap; justify-content:flex-end;",
            actionButton(ns("start"), "⏱ Start timer", class = "btn btn-dsa btn-sm"),
            actionButton(ns("reset"), "↺ Reset files", class = "btn btn-dsa-outline btn-sm"),
            actionButton(ns("show_debrief"), "Debrief", class = "btn btn-dsa-outline btn-sm"))))
      )
    ),
    fluidRow(
      column(4,
        box(title = "Brief & task", status = "info", solidHeader = TRUE, width = NULL, uiOutput(ns("brief"))),
        box(title = "AI assistant", status = "warning", solidHeader = TRUE, width = NULL,
          uiOutput(ns("chat")),
          tags$div(style = "display:flex; gap:6px; margin:8px 0;",
            actionButton(ns("apply_ai"), "Apply suggestion to my files", class = "btn btn-dsa btn-sm"),
            actionButton(ns("toggle_diff"), "Show / hide diff", class = "btn btn-dsa-outline btn-sm")),
          uiOutput(ns("diff")),
          textAreaInput(ns("review"), "Your review of the suggestion — what is wrong or risky?", "", rows = 5, width = "100%",
                        placeholder = "e.g. the pre-check ignores repeated SKUs; '> 10' should be '>= 10' …"),
          hint("Interviewers listen for this. Name concrete inputs that break the suggestion, then prove it with a test."))
      ),
      column(8,
        box(title = "Files", status = "primary", solidHeader = TRUE, width = NULL,
          uiOutput(ns("editors")),
          tags$div(class = "ws-actions", style = "display:flex; gap:6px; flex-wrap:wrap; margin-top:8px;",
            uiOutput(ns("buttons"), inline = TRUE)),
          hint("<b>Run my tests</b> runs <code>test_solution.py</code> against your files. <b>Audit my tests</b> runs your tests against the reference solution (they must pass), the AI's version and three hidden mutants (they should fail). <b>Submit</b> runs the hidden tests.")),
        box(title = "Results", status = "success", solidHeader = TRUE, width = NULL,
          tags$div(style = "position:relative; min-height:60px;",
            tags$div(id = ns("res-running"), class = "ws-running", tags$div(class = "spinner"), tags$span("Running…")),
            uiOutput(ns("results"))))
      )
    ),
    fluidRow(
      box(title = "Debrief — what the AI got wrong, the model tests and a reference fix", status = "info", solidHeader = TRUE, width = 12,
          collapsible = TRUE, uiOutput(ns("debrief")))
    ),
    fluidRow(
      box(title = "Your attempts", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          DT::DTOutput(ns("history")))
    )
  )
}

airound_server <- function(id, progress = NULL, bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    grp <- ns("grp")
    st <- reactiveValues(gen = 0, started = NULL, end = NULL, show_diff = FALSE, results = NULL, debrief = FALSE,
                         audit = NULL, hidden = NULL, tests = NULL, saved_id = NULL, opened = Sys.time())

    P <- reactive({ req(input$pid %in% names(PROJECTS)); PROJECTS[[input$pid]] })
    fnames <- reactive(c(unlist(P()$files), "test_solution.py"))
    ed_ids <- reactive(ns(sprintf("pf_%s_%d_%d", P()$id, st$gen, seq_along(fnames()))))
    originals <- reactive({ p <- P(); c(lapply(unlist(p$files), function(f) p$src[[f]]), list(p$tests_starter)) })

    observeEvent(input$pid, {
      st$results <- NULL; st$debrief <- FALSE; st$audit <- NULL; st$hidden <- NULL; st$started <- NULL; st$end <- NULL
      st$saved_id <- NULL; st$opened <- Sys.time()
      updateTextAreaInput(session, "review", value = "")
    })

    output$brief <- renderUI({
      p <- P()
      tagList(
        tags$div(style = "margin-bottom:6px;", tags$span(class = "kind-pill", p$style), " ", tags$span(class = "kind-pill", style = "background:#fef3c7;color:#92400e;", p$difficulty)),
        tags$p(HTML(p$brief)),
        tags$div(class = "code-title", "Your task"),
        tags$ol(class = "proj-task", lapply(p$tasks, function(t) tags$li(HTML(t)))),
        tags$div(class = "code-title", "Files"),
        tags$ul(lapply(c(unlist(p$files), "test_solution.py"), function(f) tags$li(tags$code(f), if (f == "test_solution.py") " — your tests (unittest)"))))
    })

    output$chat <- renderUI({
      p <- P()
      tags$div(class = "ai-chat",
        tags$div(class = "ai-msg you", tags$div(class = "ai-who", "You"), tags$div(class = "ai-text", p$ai_prompt)),
        tags$div(class = "ai-msg bot", tags$div(class = "ai-who", "Assistant"), tags$div(class = "ai-text", p$ai_reply),
          tags$div(class = "hint", style = "margin-top:6px;", sprintf("Changes %s.", paste(names(p$ai_files), collapse = ", ")))))
    })
    observeEvent(input$toggle_diff, st$show_diff <- !st$show_diff)
    output$diff <- renderUI(if (st$show_diff) diff_view(P()$ai_diff))

    output$editors <- renderUI({
      p <- P(); ids <- ed_ids(); fn <- fnames()
      draft <- tryCatch(jsonlite::fromJSON(db_get_draft(paste0("proj:", p$id)) %||% "", simplifyVector = FALSE), error = function(e) NULL)
      init <- originals()
      if (is.list(draft)) for (i in seq_along(fn)) if (!is.null(draft[[fn[i]]])) init[[i]] <- draft[[fn[i]]]
      tagList(
        if (is.list(draft) && st$gen == 0) callout("Restored your saved draft of this project. Use <b>Reset files</b> to start again from the original code.", "info"),
        tags$div(class = "file-tabs",
          do.call(tabsetPanel, c(list(id = ns("ftab"), type = "tabs"), lapply(seq_along(fn), function(i)
            tabPanel(fn[i], ace_editor(ids[i], init[[i]], height = "440px", group = grp)))))))
    })
    output$buttons <- renderUI({
      js <- function(type) sprintf("Shiny.setInputValue('%s', {type: '%s', codes: DSA.collect('%s'), nonce: Date.now()}, {priority: 'event'}); var r=document.getElementById('%s'); if (r) r.style.display='flex';",
                                   ns("act"), type, grp, ns("res-running"))
      tagList(
        tags$button(class = "btn btn-dsa-outline btn-sm", onclick = js("tests"), "▶ Run my tests"),
        tags$button(class = "btn btn-dsa-outline btn-sm", onclick = js("audit"), "🧪 Audit my tests"),
        tags$button(class = "btn btn-dsa btn-sm", onclick = js("hidden"), "✔ Submit (hidden tests)"),
        tags$button(class = "btn btn-dsa-outline btn-sm", onclick = js("save"), "💾 Save draft"))
    })

    collect <- function(codes) {
      ids <- ed_ids(); fn <- fnames(); out <- list()
      for (i in seq_along(ids)) out[[fn[i]]] <- codes[[ids[i]]] %||% originals()[[i]]
      out
    }

    observeEvent(input$act, {
      a <- input$act; p <- P()
      on.exit(session$sendCustomMessage("dsa-running", list(id = ns("res"), on = FALSE)), add = TRUE)
      all <- collect(a$codes); tests <- all[["test_solution.py"]]; files <- all[names(all) != "test_solution.py"]
      if (is.null(st$started)) st$started <- Sys.time()
      db_save_draft(paste0("proj:", p$id), as.character(jsonlite::toJSON(all, auto_unbox = TRUE)))
      secs <- as.numeric(difftime(Sys.time(), st$opened, units = "secs"))
      if (a$type == "save") { showNotification("Draft saved.", type = "message", duration = 2); return() }
      res <- run_project(a$type, p$id, files = files, tests = tests)
      st$results <- list(type = a$type, res = res)
      if (a$type == "audit" && !is.null(res$rows)) {
        st$audit <- res$rows
        if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1
        rows <- res$rows; mut <- Filter(function(r) startsWith(r$key, "mutant:"), rows)
        aiok <- any(vapply(rows, function(r) r$key == "ai" && isTRUE(r$ok), TRUE))
        db_insert("project_attempts", list(ts = now_ts(), day = today(), project_id = p$id, mode = "audit",
          passed = NA, total = NA, caught_ai = as.integer(aiok), mutants_caught = sum(vapply(mut, function(r) isTRUE(r$ok), TRUE)),
          mutants_total = length(mut), seconds = secs, review = input$review, files = NA, tests = tests))
      }
      if (a$type == "hidden" && !is.null(res$suite)) {
        st$hidden <- res$suite; st$debrief <- TRUE
        db_insert("project_attempts", list(ts = now_ts(), day = today(), project_id = p$id, mode = "submit",
          passed = res$suite$passed, total = res$suite$total, caught_ai = NA, mutants_caught = NA, mutants_total = NA,
          seconds = secs, review = input$review, files = as.character(jsonlite::toJSON(files, auto_unbox = TRUE)), tests = tests))
        if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1
      }
      st$tests <- tests
    })

    output$results <- renderUI({
      r <- st$results
      if (is.null(r)) return(tags$div(class = "res-empty", "Run your tests, audit them, or submit to see results here."))
      res <- r$res
      if (identical(res$status, "setup_error")) return(callout(paste0("<b>Could not run.</b><pre>", htmltools::htmlEscape(res$msg %||% ""), "</pre>"), "warn"))
      switch(r$type,
        tests = suite_view(res$suite, NULL),
        hidden = tagList(suite_view(res$suite, if (isTRUE(res$suite$all_pass)) "Accepted — all hidden tests pass" else "Hidden tests: not yet", hide_msgs = TRUE),
                         if (!isTRUE(res$suite$all_pass)) hint("Only the name and the last line of each failure are shown. The debrief below explains the traps.")),
        audit = {
          rows <- res$rows
          ref <- Filter(function(x) x$key == "reference", rows)[[1]]
          caught <- sum(vapply(rows, function(x) !x$should_pass && isTRUE(x$ok), TRUE)); n_bad <- sum(vapply(rows, function(x) !x$should_pass, TRUE))
          tagList(
            kpi_row(kpi(if (isTRUE(ref$ok)) "yes" else "no", "tests pass on the reference", if (isTRUE(ref$ok)) COL$ok else COL$err),
                    kpi(sprintf("%d / %d", caught, n_bad), "faulty versions caught", if (caught == n_bad) COL$ok else COL$warn),
                    kpi(sprintf("%d", ref$total), "tests in your suite", COL$pri)),
            if (!isTRUE(ref$ok)) callout("Some of your tests <b>fail on the reference solution</b> — they encode a wrong expectation (or the suite does not load). Fix those first; a test that fails on correct code tells the interviewer you misread the spec.", "warn"),
            lapply(rows, function(x) tags$div(class = paste("audit-row", if (isTRUE(x$ok)) "ok" else "bad"),
              tags$b(if (isTRUE(x$ok)) "✓" else "✗"), tags$span(x$label),
              tags$span(class = "tag", if (x$should_pass) sprintf("should pass · %d/%d passed", x$passed, x$total)
                                       else if (isTRUE(x$ok)) sprintf("caught by: %s", paste(head(unlist(x$failing), 3), collapse = ", "))
                                       else "not caught — every test passed"))),
            hint("A strong suite passes on correct code and fails on each faulty version. Mutants are small, realistic bugs, not the AI's exact code."))
        })
    })

    # Apply the AI's suggestion to the matching editors
    observeEvent(input$apply_ai, {
      p <- P(); ids <- ed_ids(); fn <- fnames()
      for (f in names(p$ai_files)) {
        i <- match(f, fn); if (is.na(i)) next
        session$sendCustomMessage("dsa-set-code", list(id = ids[i], code = p$ai_files[[f]]))
      }
      showNotification(sprintf("Applied the assistant's changes to %s. Review them before you trust them!", paste(names(p$ai_files), collapse = ", ")), type = "warning", duration = 5)
    })
    observeEvent(input$reset, {
      db_delete_draft(paste0("proj:", P()$id)); st$gen <- st$gen + 1; st$results <- NULL
    })

    # Timer
    observeEvent(input$start, {
      st$started <- Sys.time(); st$end <- as.numeric(Sys.time()) * 1000 + P()$minutes * 60000
    })
    output$clock <- renderUI({
      if (is.null(st$end)) return(tags$div(class = "hint", style = "margin-top:6px;", sprintf("Suggested time: %d minutes.", P()$minutes)))
      tags$div(class = "dsa-countdown", style = "font-size:22px;", `data-end` = sprintf("%.0f", st$end), `data-total` = P()$minutes * 60,
               `data-input` = ns("timeup"), `data-group` = grp, "--:--")
    })
    observeEvent(input$timeup, {
      showModal(modalDialog(title = "Time is up", "Submit your work now to see how the hidden tests score it, then read the debrief.", easyClose = TRUE))
    })

    observeEvent(input$show_debrief, st$debrief <- TRUE)
    output$debrief <- renderUI({
      p <- P()
      if (!st$debrief) return(tags$div(class = "res-empty", "Submit (or press Debrief) to reveal the AI's mistakes, the model tests and a reference fix. Try first!"))
      fn <- unlist(p$files)
      tagList(
        fluidRow(
          column(6,
            tags$div(class = "code-title", "What was wrong with the suggestion"),
            tags$ol(lapply(p$flaws, function(f) tags$li(HTML(f)))),
            tags$div(class = "code-title", "Your review"),
            if (nzchar(input$review %||% "")) tags$blockquote(style = "white-space:pre-wrap; font-size:13px;", input$review) else hint("(you did not write a review)"),
            tags$div(class = "code-title", "Self-assessment"),
            checkboxGroupInput(ns("rubric"), NULL, choices = unlist(p$rubric), width = "100%"),
            tags$div(style = "display:flex; gap:8px; align-items:center;",
              actionButton(ns("save_rubric"), "Save self-assessment", class = "btn btn-dsa btn-sm"), uiOutput(ns("rubric_score"), inline = TRUE))),
          column(6,
            tags$div(class = "code-title", "Hidden test names"),
            tags$div(style = "font-size:12px; font-family:'JetBrains Mono', monospace;", lapply(unlist(p$hidden_names), tags$div)),
            hint(sprintf("Starting code passed %d / %d; the AI's version passed %d / %d.", p$src_hidden_passed, p$hidden_total, p$ai_hidden_passed, p$hidden_total)),
            tags$div(class = "code-title", "Mutants used by the audit"),
            tags$ul(lapply(names(p$mutants), function(m) tags$li(p$mutants[[m]]))))
        ),
        tabsetPanel(type = "pills",
          tabPanel("Model tests", dsa_code(p$model_tests, "test_solution.py — a suite that catches the AI and every mutant")),
          do.call(tabPanel, c(list("Reference fix"), lapply(fn, function(f) if (!identical(p$reference[[f]], p$src[[f]])) dsa_code(p$reference[[f]], f)))))
      )
    })
    output$rubric_score <- renderUI({
      n <- length(input$rubric); tot <- length(P()$rubric)
      tags$b(sprintf("%d / %d", n, tot))
    })
    observeEvent(input$save_rubric, {
      p <- P(); sc <- length(input$rubric) / length(p$rubric) * 100
      db_insert("project_attempts", list(ts = now_ts(), day = today(), project_id = p$id, mode = "self", passed = length(input$rubric),
        total = length(p$rubric), caught_ai = NA, mutants_caught = NA, mutants_total = NA,
        seconds = as.numeric(difftime(Sys.time(), st$opened, units = "secs")), review = input$review, files = NA,
        tests = paste(input$rubric, collapse = " | "), self_score = sc))
      showNotification(sprintf("Saved: %.0f%% of the rubric.", sc), type = "message")
    })

    output$history <- DT::renderDT({
      input$act; input$save_rubric
      h <- db_table("project_attempts")
      if (!nrow(h)) return(DT::datatable(data.frame(Message = "No attempts yet."), rownames = FALSE, options = list(dom = "t")))
      h$Project <- vapply(h$project_id, function(x) PROJECTS[[x]]$title %||% x, "")
      h$Result <- ifelse(h$mode == "submit", sprintf("%s/%s hidden tests", h$passed, h$total),
                  ifelse(h$mode == "audit", sprintf("AI %s · mutants %s/%s", ifelse(h$caught_ai == 1, "caught", "missed"), h$mutants_caught, h$mutants_total),
                         sprintf("self-score %.0f%%", h$self_score)))
      h$Minutes <- round(h$seconds / 60, 1)
      DT::datatable(h[, c("ts", "Project", "mode", "Result", "Minutes")], rownames = FALSE,
                    colnames = c("When", "Project", "Kind", "Result", "Minutes in"), options = list(pageLength = 8, dom = "tp"))
    })
  })
}
