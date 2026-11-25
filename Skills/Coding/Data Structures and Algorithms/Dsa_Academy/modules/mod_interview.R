# modules/mod_interview.R — timed mock interview simulator (Meta / Google / custom formats).

INTERVIEW_MODES <- list(
  meta = list(label = "Meta-style coding round", n = 2, minutes = 45, run = FALSE, plain = FALSE, followup = FALSE,
              levels = c("Medium"), company = "meta",
              blurb = "Two problems in 45 minutes (about 20 minutes each, including discussion). Shared editor with syntax highlighting, but you cannot run your code — trace it by hand."),
  google = list(label = "Google-style coding round", n = 1, minutes = 45, run = FALSE, plain = TRUE, followup = TRUE,
                levels = c("Medium", "Hard"), company = "google",
                blurb = "One harder problem plus a follow-up that changes a constraint, in 45 minutes. Plain document-style editor: no highlighting, no autocomplete, no running."),
  custom = list(label = "Custom drill", n = 1, minutes = 30, run = TRUE, plain = FALSE, followup = TRUE,
                levels = c("Easy", "Medium", "Hard"), company = "all",
                blurb = "Choose the number of problems, the time, the editor style and whether you may run the examples.")
)

SELF_CHECKS <- list(
  list(id = "clarify",  text = "Clarified the problem: restated it, asked about input size, duplicates, negatives, empty input"),
  list(id = "example",  text = "Worked through an example by hand before coding"),
  list(id = "brute",    text = "Stated a brute-force approach and its complexity"),
  list(id = "plan",     text = "Explained the optimal approach and got agreement before writing code"),
  list(id = "cplx",     text = "Stated the final time and space complexity correctly"),
  list(id = "clean",    text = "Code was clean: clear names, small helpers, no dead code"),
  list(id = "trace",    text = "Traced the finished code on a test case and fixed bugs without running it"),
  list(id = "edges",    text = "Handled edge cases (empty, single element, duplicates, overflow, bounds)"),
  list(id = "time",     text = "Finished within the time slot, leaving a few minutes for questions"),
  list(id = "followup", text = "Answered the follow-up with a concrete approach and its complexity", google = TRUE)
)

score_band <- function(x) {
  if (x >= 85) c("Strong performance", COL$ok) else if (x >= 70) c("Solid — a few gaps", COL$acc)
  else if (x >= 50) c("Mixed — work on the gaps below", COL$warn) else c("Needs more practice", COL$err)
}

interview_ui <- function(id) {
  ns <- NS(id)
  tagList(uiOutput(ns("pybanner")), uiOutput(ns("main")))
}

interview_server <- function(id, progress = NULL, bus) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    grp <- ns("grp")
    iv <- reactiveValues(phase = "setup", mode = NULL, cfg = NULL, pids = NULL, start = NULL, end = NULL,
                         tab_since = NULL, tab_cur = NULL, tab_secs = NULL, results = NULL, codes = NULL,
                         followup = list(), run_res = list(), saved = FALSE, used = NULL, notes = list())

    output$pybanner <- renderUI(python_banner())

    pick_problems <- function(cfg, prefer_new, include_hard, manual) {
      if (length(manual)) return(head(manual, 3))
      s <- db_problem_status()
      pool <- s
      if (cfg$company == "meta") pool <- pool[pool$meta, ]
      if (cfg$company == "google") pool <- pool[pool$google, ]
      lv <- cfg$levels
      if (include_hard) lv <- union(lv, "Hard") else if (length(lv) > 1) lv <- setdiff(lv, "Hard")
      pool <- pool[pool$difficulty %in% lv, ]
      if (prefer_new && sum(!pool$solved) >= cfg$n) pool <- pool[!pool$solved, ]
      if (nrow(pool) < cfg$n) pool <- s
      sample(pool$id, cfg$n)
    }

    # ── Main view ────────────────────────────────────────────────────────────
    output$main <- renderUI({
      switch(iv$phase, setup = setup_view(), live = isolate(live_view()), grading = grading_view(), review = isolate(review_view()))
    })

    setup_view <- function() {
      tagList(
        topic_hero("⏱️", "Mock Interview",
          "Rehearse under real conditions: a countdown, no hints, no solution, and — as in most live rounds — no running your code. At the end your code is judged on the hidden tests and you score yourself against the rubric interviewers use.",
          c("Meta format", "Google format", "Hidden-test grading", "Self-assessment rubric", "History & trend")),
        fluidRow(
          box(title = "1 · Choose a format", status = "primary", solidHeader = TRUE, width = 7,
            radioButtons(ns("mode"), NULL, width = "100%",
              choiceNames = lapply(names(INTERVIEW_MODES), function(k) tags$span(tags$b(INTERVIEW_MODES[[k]]$label), tags$br(),
                                    tags$span(class = "hint", INTERVIEW_MODES[[k]]$blurb))),
              choiceValues = names(INTERVIEW_MODES), selected = isolate(input$mode) %||% "meta"),
            conditionalPanel(sprintf("input['%s'] == 'custom'", ns("mode")),
              fluidRow(
                column(3, numericInput(ns("c_n"), "Problems", 1, min = 1, max = 3)),
                column(3, numericInput(ns("c_min"), "Minutes", 30, min = 5, max = 120, step = 5)),
                column(3, radioButtons(ns("c_plain"), "Editor", c("Code editor" = "no", "Plain doc" = "yes"))),
                column(3, checkboxInput(ns("c_run"), "Allow running the examples", TRUE))))
          ),
          box(title = "2 · Choose problems", status = "primary", solidHeader = TRUE, width = 5,
            checkboxInput(ns("prefer_new"), "Prefer problems I have not solved yet", TRUE),
            checkboxInput(ns("hard"), "Include Hard problems", FALSE),
            selectizeInput(ns("manual"), "…or pick them yourself (optional):", multiple = TRUE, width = "100%",
              choices = setNames(PRACTICE_DF$id, sprintf("%d. %s (%s)", PRACTICE_DF$num, PRACTICE_DF$title, PRACTICE_DF$difficulty)),
              options = list(maxItems = 3, placeholder = "Random selection")),
            actionButton(ns("start"), "▶ Start the interview", class = "btn btn-dsa", width = "100%"),
            hint("The difficulty and pattern are hidden during the interview, as they would be in a real one."))
        ),
        fluidRow(
          box(title = "How to use the 45 minutes", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Minutes = c("0–5", "5–10", "10–30", "30–38", "38–45"),
              Do = c("Restate the problem, ask clarifying questions, agree on input / output", "Examples by hand; brute force and its cost; optimal idea and its cost",
                     "Write the code, narrating as you go", "Trace an example line by line; fix bugs; check edge cases", "Complexity, trade-offs, follow-up questions"),
              stringsAsFactors = FALSE)),
            hint("For the Meta format, halve these: about 20 minutes per problem.")),
          box(title = "Format notes", status = "info", solidHeader = TRUE, width = 7,
            callout("<b>Meta</b> — recent candidate reports describe two LeetCode-medium problems in a 45-minute CoderPad round, plus (in the onsite) a separate 60-minute <b>AI-assisted</b> round on a small multi-file project. This simulator covers the classic round; the AI-assisted round is not simulated.", "info"),
            callout("<b>Google</b> — reports describe a shared doc or Google's own editor that <b>does not run code</b>, one main problem per 45 minutes, and frequent follow-ups that change a constraint. AI tools are reportedly not allowed.", "info"),
            hint("Formats vary by team, level and country and change over time; confirm the details with your recruiter."))
        ),
        history_box()
      )
    }

    history_box <- function() {
      fluidRow(
        box(title = "Your mock interview history", status = "success", solidHeader = TRUE, width = 12,
          uiOutput(ns("hist_kpi")),
          fluidRow(column(5, plotlyOutput(ns("hist_plot"), height = "260px")), column(7, DTOutput(ns("hist_tbl")))))
      )
    }

    live_view <- function() {
      cfg <- iv$cfg; pids <- iv$pids
      tagList(
        tags$div(class = "iv-bar",
          tags$div(tags$div(class = "iv-mode", cfg$label), tags$div(class = "hint", style = "margin:0;",
                   sprintf("%d problem(s) · %d minutes · %s", length(pids), cfg$minutes, if (cfg$run) "running examples allowed" else "no code execution"))),
          tags$span(class = "ws-spacer"),
          tags$div(class = "dsa-countdown", `data-end` = sprintf("%.0f", iv$end), `data-total` = cfg$minutes * 60,
                   `data-input` = ns("finish"), `data-group` = grp, "--:--"),
          tags$button(class = "btn btn-dsa", onclick = sprintf("if (confirm('Finish the interview and grade your code now?')) DSA.finish('%s','%s','manual')", ns("finish"), grp), "Finish & grade")),
        callout("Think out loud — type your clarifying questions, plan and complexity in the notes box as you would say them. Restate → example → brute force → optimal → code → trace → complexity.", "tip"),
        do.call(tabsetPanel, c(list(id = ns("ptab")), lapply(seq_along(pids), function(i) {
          p <- PRACTICE[[pids[i]]]
          tabPanel(sprintf("Problem %d", i), value = pids[i],
            fluidRow(
              column(5, box(width = 12, tags$div(class = "ws-scroll", problem_statement(p, show_meta = FALSE)),
                            if (cfg$followup) uiOutput(ns(paste0("fu_", pids[i]))))),
              column(7, box(width = 12,
                ace_editor(ns(paste0("ed_", pids[i])), p$starter, height = "400px", group = grp, plain = cfg$plain, autocomplete = !cfg$plain),
                if (cfg$run) tags$div(class = "ws-actions",
                  tags$span(class = "ws-spacer"),
                  actionButton(ns(paste0("run_", pids[i])), "▶ Run examples", class = "btn btn-dsa-outline btn-sm")),
                if (cfg$run) uiOutput(ns(paste0("runres_", pids[i]))),
                textAreaInput(ns(paste0("notes_", pids[i])), "Notes — clarifying questions, approach, complexity:", "", width = "100%", height = "110px", resize = "vertical")))
            ))
        })))
      )
    }

    grading_view <- function() {
      tags$div(class = "iv-grading", tags$div(class = "spinner"), tags$h4("Time's up — grading your code against the hidden tests…"))
    }

    # ── Start ────────────────────────────────────────────────────────────────
    observeEvent(input$start, {
      cfg <- INTERVIEW_MODES[[input$mode]]
      if (input$mode == "custom") {
        cfg$n <- max(1, min(3, as.integer(input$c_n %||% 1))); cfg$minutes <- max(5, as.integer(input$c_min %||% 30))
        cfg$run <- isTRUE(input$c_run); cfg$plain <- identical(input$c_plain, "yes")
      }
      pids <- pick_problems(cfg, isTRUE(input$prefer_new), isTRUE(input$hard), input$manual)
      cfg$n <- length(pids)
      iv$mode <- input$mode; iv$cfg <- cfg; iv$pids <- pids
      iv$start <- as.numeric(Sys.time()) * 1000; iv$end <- iv$start + cfg$minutes * 60000
      iv$tab_secs <- setNames(rep(0, length(pids)), pids); iv$tab_cur <- pids[1]; iv$tab_since <- Sys.time()
      iv$followup <- list(); iv$run_res <- list(); iv$results <- NULL; iv$saved <- FALSE
      iv$phase <- "live"
    })

    observeEvent(input$ptab, {
      req(iv$phase == "live", !is.null(iv$tab_cur))
      iv$tab_secs[iv$tab_cur] <- iv$tab_secs[iv$tab_cur] + as.numeric(difftime(Sys.time(), iv$tab_since, units = "secs"))
      iv$tab_cur <- input$ptab; iv$tab_since <- Sys.time()
    })

    # follow-ups (Google style): revealed on request
    observe({
      req(iv$phase == "live", iv$cfg$followup)
      lapply(iv$pids, function(pid) {
        output[[paste0("fu_", pid)]] <- renderUI({
          f <- unlist(PRACTICE[[pid]]$followups)
          if (!isTRUE(iv$followup[[pid]]))
            return(tags$div(class = "fu-box", hint("When your main solution is done and explained, ask for the follow-up — as the interviewer would give it."),
                            actionButton(ns(paste0("fubtn_", pid)), "I'm done — give me the follow-up", class = "btn btn-dsa-outline btn-sm")))
          tags$div(class = "fu-box", callout(paste0("<b>Follow-up.</b> ", f[1]), "warn"),
                   textAreaInput(ns(paste0("fuans_", pid)), "Your answer (approach, data structures, new complexity):", "", width = "100%", height = "90px"))
        })
      })
    })
    registered <- new.env()        # one set of observers per problem id, however many interviews are run
    observe({
      req(iv$phase == "live")
      for (pid in iv$pids) local({
        pid <- pid
        if (exists(pid, envir = registered, inherits = FALSE)) return()
        assign(pid, TRUE, envir = registered)
        observeEvent(input[[paste0("fubtn_", pid)]], { f <- iv$followup; f[[pid]] <- TRUE; iv$followup <- f }, ignoreInit = TRUE)
        observeEvent(input[[paste0("run_", pid)]], {
          code <- input[[paste0("ed_", pid, "_code")]]$code %||% PRACTICE[[pid]]$starter
          res <- run_solution(pid, code, "run")
          r <- iv$run_res; r[[pid]] <- res; iv$run_res <- r
        }, ignoreInit = TRUE)
        output[[paste0("runres_", pid)]] <- renderUI(if (!is.null(iv$run_res[[pid]])) result_panel(iv$run_res[[pid]], "run"))
      })
    })

    # ── Finish and grade ─────────────────────────────────────────────────────
    observeEvent(input$finish, {
      req(iv$phase == "live")
      f <- input$finish
      if (!is.null(iv$tab_cur)) iv$tab_secs[iv$tab_cur] <- iv$tab_secs[iv$tab_cur] + as.numeric(difftime(Sys.time(), iv$tab_since, units = "secs"))
      iv$used <- min(iv$cfg$minutes * 60, (as.numeric(Sys.time()) * 1000 - iv$start) / 1000)
      codes <- lapply(iv$pids, function(pid) f$codes[[ns(paste0("ed_", pid))]] %||% PRACTICE[[pid]]$starter)
      names(codes) <- iv$pids
      iv$codes <- codes
      iv$notes <- setNames(lapply(iv$pids, function(pid) list(notes = input[[paste0("notes_", pid)]] %||% "",
                                                            followup = input[[paste0("fuans_", pid)]] %||% "")), iv$pids)
      iv$finish_reason <- f$reason
      iv$phase <- "grading"
    })
    gstate <- new.env()
    observe({
      req(iv$phase == "grading")
      # let the "grading…" screen reach the browser before the (blocking) judging starts
      if (!isTRUE(gstate$armed)) { gstate$armed <- TRUE; invalidateLater(150); return() }
      gstate$armed <- FALSE
      isolate({
        res <- lapply(iv$pids, function(pid) {
          r <- run_solution(pid, iv$codes[[pid]], "submit")
          if (!(r$verdict %in% c("Internal Error", "Python not found"))) db_add_submission(pid, "interview", r, iv$codes[[pid]])
          r
        })
        names(res) <- iv$pids
        iv$results <- res
        bus$db_tick <- bus$db_tick + 1
        iv$phase <- "review"
      })
    })

    # ── Review ───────────────────────────────────────────────────────────────
    tests_score <- reactive({
      req(iv$results)
      100 * mean(vapply(iv$results, function(r) if (isTRUE(r$total > 0)) (r$passed %||% 0) / r$total else 0, numeric(1)))
    })
    checks <- reactive({ Filter(function(x) !isTRUE(x$google) || isTRUE(iv$cfg$followup), SELF_CHECKS) })
    self_score <- reactive({
      ch <- checks()
      v <- vapply(ch, function(x) as.numeric(input[[paste0("chk_", x$id)]] %||% 0), numeric(1))
      100 * sum(v) / (2 * length(ch))
    })

    review_view <- function() {
      pids <- iv$pids; res <- iv$results
      tagList(
        tags$div(class = "iv-bar",
          tags$div(tags$div(class = "iv-mode", paste(iv$cfg$label, "— review")),
                   tags$div(class = "hint", style = "margin:0;", if (identical(iv$finish_reason, "time")) "Time ran out; your code was graded as it stood." else "You finished early.")),
          tags$span(class = "ws-spacer"),
          actionButton(ns("again"), "Start another interview", class = "btn btn-dsa-outline")),
        kpi_row(
          kpi(sprintf("%d:%02d", floor(iv$used / 60), round(iv$used %% 60)), sprintf("time used of %d:00", iv$cfg$minutes), COL$pri),
          kpi(sprintf("%d / %d", sum(vapply(res, function(r) identical(r$verdict, "Accepted"), logical(1))), length(res)), "problems fully passing", COL$ok),
          kpi(sprintf("%.0f%%", tests_score()), "hidden tests passed", COL$acc)),
        lapply(seq_along(pids), function(i) {
          pid <- pids[i]; p <- PRACTICE[[pid]]; r <- res[[pid]]
          box(title = sprintf("Problem %d — %d. %s (%s)", i, p$num, p$title, p$difficulty), status = if (identical(r$verdict, "Accepted")) "success" else "danger",
              solidHeader = TRUE, width = 12,
            fluidRow(
              column(6, tags$div(class = "code-title", sprintf("Your code · about %d min on this tab", round(iv$tab_secs[[pid]] / 60))),
                     dsa_code(iv$codes[[pid]]),
                     if (nzchar(iv$notes[[pid]]$notes)) tagList(tags$div(class = "code-title", "Your notes"), tags$pre(class = "iv-notes", iv$notes[[pid]]$notes)),
                     if (nzchar(iv$notes[[pid]]$followup)) tagList(tags$div(class = "code-title", "Your follow-up answer"), tags$pre(class = "iv-notes", iv$notes[[pid]]$followup))),
              column(6, result_panel(r, "submit"),
                     tags$details(class = "iv-details", tags$summary("Show the reference approach and solution"),
                       kpi_row(kpi(p$pattern, "pattern", COL$pri), kpi(p$complexity, "complexity", COL$ok)),
                       tags$div(class = "ps-body", HTML(as.character(shiny::markdown(p$approach)))),
                       dsa_code(strip_checker(p$reference)),
                       if (iv$cfg$followup) callout(paste0("<b>Follow-up asked:</b> ", unlist(p$followups)[1]), "info")))
            ))
        }),
        fluidRow(
          box(title = "Score yourself honestly — this is what interviewers write down", status = "warning", solidHeader = TRUE, width = 8,
            lapply(checks(), function(x) tags$div(class = "chk-row",
              tags$div(class = "chk-text", x$text),
              radioButtons(ns(paste0("chk_", x$id)), NULL, choices = c("No" = 0, "Partly" = 1, "Yes" = 2), selected = 0, inline = TRUE))),
            textAreaInput(ns("reflect"), "What would you do differently next time?", "", width = "100%", height = "80px")),
          box(title = "Result", status = "success", solidHeader = TRUE, width = 4,
            uiOutput(ns("score")),
            actionButton(ns("save"), "💾 Save to history", class = "btn btn-dsa", width = "100%"),
            uiOutput(ns("saved_msg")),
            hint("A practice rubric: half from hidden tests, half from your self-assessment. It is not an official hiring signal."))
        )
      )
    }

    output$score <- renderUI({
      req(iv$phase == "review")
      t <- tests_score(); s <- self_score(); tot <- 0.5 * t + 0.5 * s; b <- score_band(tot)
      ch <- checks(); v <- vapply(ch, function(x) as.numeric(input[[paste0("chk_", x$id)]] %||% 0), numeric(1))
      weak <- vapply(ch[v < 2], function(x) x$text, "")
      tagList(
        tags$div(class = "iv-score", style = paste0("color:", b[2], ";"), sprintf("%.0f", tot), tags$span("/ 100")),
        tags$div(class = "iv-band", style = paste0("color:", b[2], ";"), b[1]),
        kpi_row(kpi(sprintf("%.0f", t), "tests (of 100)", COL$acc), kpi(sprintf("%.0f", s), "self-assessment (of 100)", COL$sec)),
        if (length(weak)) tags$div(class = "hint", tags$b("Focus next time on:"), tags$ul(lapply(head(weak, 4), tags$li))))
    })

    observeEvent(input$save, {
      req(iv$phase == "review", !iv$saved)
      ch <- checks()
      det <- list(checklist = setNames(lapply(ch, function(x) as.numeric(input[[paste0("chk_", x$id)]] %||% 0)), vapply(ch, function(x) x$id, "")),
                  reflection = input$reflect %||% "", reason = iv$finish_reason,
                  results = lapply(iv$results, function(r) list(verdict = r$verdict, passed = r$passed, total = r$total)),
                  tab_minutes = as.list(round(iv$tab_secs / 60, 1)))
      t <- tests_score(); s <- self_score()
      db_save_interview(iv$cfg$label, iv$cfg$minutes, iv$used, iv$pids, t, s, 0.5 * t + 0.5 * s, json_str(det))
      iv$saved <- TRUE
      bus$db_tick <- bus$db_tick + 1
    })
    output$saved_msg <- renderUI(if (iv$saved) callout("Saved. It now appears in your history and on My Progress.", "success"))
    observeEvent(input$again, { iv$phase <- "setup" })

    # ── History ──────────────────────────────────────────────────────────────
    hist <- reactive({ bus$db_tick; db_interviews() })
    output$hist_kpi <- renderUI({
      h <- hist()
      if (!nrow(h)) return(hint("No mock interviews saved yet. Finish one and press “Save to history”."))
      kpi_row(kpi(nrow(h), "mock interviews", COL$pri), kpi(sprintf("%.0f", mean(h$total)), "average score", COL$acc),
              kpi(sprintf("%.0f", max(h$total)), "best score", COL$ok), kpi(sprintf("%.0f", h$total[1]), "most recent", COL$sec))
    })
    output$hist_plot <- renderPlotly({
      h <- hist(); req(nrow(h) > 0); h <- h[rev(seq_len(nrow(h))), ]
      plot_ly(x = seq_len(nrow(h)), height = 260) %>%
        add_trace(y = h$total, type = "scatter", mode = "lines+markers", name = "total", line = list(color = COL$pri, width = 3), marker = list(color = COL$pri, size = 8),
                  hovertext = paste0(h$ts, "<br>", h$mode, "<br>score ", round(h$total)), hoverinfo = "text") %>%
        add_trace(y = h$tests_score, type = "scatter", mode = "lines", name = "tests", line = list(color = COL$acc, dash = "dot")) %>%
        add_trace(y = h$self_score, type = "scatter", mode = "lines", name = "self-assessment", line = list(color = COL$sec, dash = "dot")) %>%
        dsa_layout(xt = "interview #", yt = "score", legend = TRUE) %>% layout(yaxis = list(range = c(0, 105)), xaxis = list(dtick = 1))
    })
    output$hist_tbl <- renderDT({
      h <- hist(); req(nrow(h) > 0)
      titles <- vapply(strsplit(h$problems, ","), function(ids) paste(vapply(ids, function(x) if (x %in% PRACTICE_IDS) PRACTICE[[x]]$title else x, ""), collapse = " + "), "")
      datatable(data.frame(When = h$ts, Format = h$mode, Problems = titles, Minutes = sprintf("%.0f / %d", h$seconds_used / 60, h$minutes),
                           Tests = round(h$tests_score), Self = round(h$self_score), Total = round(h$total)),
                rownames = FALSE, selection = "none", options = list(dom = "tp", pageLength = 6, ordering = FALSE))
    })
  })
}
