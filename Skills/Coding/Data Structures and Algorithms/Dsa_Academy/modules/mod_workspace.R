# modules/mod_workspace.R — LeetCode-style problem workspace: statement, editor, run & submit, history.

strip_checker <- function(code) sub("\n+def check\\(.*$", "\n", code)

workspace_ui <- function(id) {
  ns <- NS(id)
  ed <- ns("editor")
  tagList(
    uiOutput(ns("pybanner")),
    tags$div(class = "ws-bar",
      tags$div(class = "ws-pick", selectizeInput(ns("pid"), NULL, choices = NULL, width = "100%",
                                                 options = list(placeholder = "Choose a problem…", maxOptions = 200))),
      tags$div(class = "ws-filter", selectInput(ns("f_company"), NULL, c("All companies" = "all", "Meta-reported" = "meta", "Google-reported" = "google"), width = "100%")),
      tags$div(class = "ws-filter", selectInput(ns("f_status"), NULL, c("All problems" = "all", "Not solved yet" = "unsolved", "Due for review" = "due", "Solved" = "solved"), width = "100%")),
      tags$div(class = "ws-nav",
        actionButton(ns("prev"), "◀", class = "btn btn-dsa-outline btn-sm", title = "Previous problem"),
        actionButton(ns("nxt"), "▶", class = "btn btn-dsa-outline btn-sm", title = "Next problem"),
        actionButton(ns("rand"), "🎲 Random unsolved", class = "btn btn-dsa btn-sm"))
    ),
    fluidRow(
      column(5,
        box(width = 12, status = "primary", solidHeader = FALSE, class = "ws-left",
          tabsetPanel(id = ns("ltab"),
            tabPanel("📄 Description", value = "desc", tags$div(class = "ws-scroll", uiOutput(ns("desc")))),
            tabPanel("💡 Hints", value = "hints", tags$div(class = "ws-scroll", uiOutput(ns("hints")))),
            tabPanel("✅ Solution", value = "sol", tags$div(class = "ws-scroll", uiOutput(ns("solution")))),
            tabPanel("🕘 Submissions", value = "subs", tags$div(class = "ws-scroll", uiOutput(ns("subs_head")), DTOutput(ns("subs")))),
            tabPanel("🔁 Follow-ups", value = "fu", tags$div(class = "ws-scroll", uiOutput(ns("followups"))))
          ))
      ),
      column(7,
        box(width = 12, status = "primary", solidHeader = FALSE, class = "ws-right",
          tags$div(class = "ws-toolbar",
            tags$span(class = "ws-lang", "Python 3"),
            uiOutput(ns("watch"), inline = TRUE),
            tags$span(class = "ws-spacer"),
            tags$select(class = "ws-sel", title = "Font size", onchange = "DSA.setFont(this.value)",
                        lapply(c(12, 13, 14, 15, 16, 18), function(s) tags$option(value = s, selected = if (s == 14) NA, paste0(s, "px")))),
            tags$select(class = "ws-sel", title = "Key bindings", onchange = "DSA.setKeys(this.value)",
                        tags$option(value = "default", "Standard keys"), tags$option(value = "vscode", "VS Code"), tags$option(value = "vim", "Vim")),
            actionButton(ns("reset"), "↺ Reset", class = "btn btn-dsa-outline btn-sm", title = "Restore the starter code")
          ),
          tags$div(class = "ws-editor-wrap",
            ace_editor(ed, "", height = "430px", action_input = ns("action")),
            tags$div(id = paste0(ed, "-running"), class = "ws-running", tags$div(class = "spinner"), tags$span("Judging…"))),
          tags$div(class = "ws-actions",
            tags$span(class = "hint", style = "margin:0;", "Tab inserts 4 spaces · Ctrl/⌘+Enter = Run · Ctrl/⌘+Shift+Enter = Submit"),
            tags$span(class = "ws-spacer"),
            tags$button(class = "btn btn-dsa-outline", onclick = sprintf("DSA.action('%s','%s','run')", ed, ns("action")), "▶ Run"),
            tags$button(class = "btn btn-dsa", onclick = sprintf("DSA.action('%s','%s','submit')", ed, ns("action")), "⬆ Submit")),
          tabsetPanel(id = ns("rtab"),
            tabPanel("🧪 Testcase", value = "test",
              uiOutput(ns("custom_help")),
              textAreaInput(ns("custom"), NULL, "", width = "100%", height = "110px", resize = "vertical")),
            tabPanel("📊 Result", value = "result", uiOutput(ns("result"))))
        )
      )
    )
  )
}

workspace_server <- function(id, progress = NULL, bus) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    ed <- ns("editor")
    st <- reactiveValues(pid = NULL, result = NULL, mode = "run", hints = 0, reveal = FALSE, opened = NULL, pending = NULL)

    output$pybanner <- renderUI(python_banner())

    status <- reactive({ bus$db_tick; db_problem_status() })

    filtered <- reactive({
      s <- status()
      if (input$f_company == "meta") s <- s[s$meta, ]
      if (input$f_company == "google") s <- s[s$google, ]
      s <- switch(input$f_status, unsolved = s[!s$solved, ], due = s[s$due, ], solved = s[s$solved, ], s)
      s
    })

    observe({
      s <- filtered()
      icon <- ifelse(s$due, "🔁", ifelse(s$status == "solved", "✅", ifelse(s$status == "attempted", "🟡", "⬜")))
      lab <- sprintf("%s  %d. %s", icon, s$num, s$title)
      ch <- lapply(c("Easy", "Medium", "Hard"), function(d) { k <- s$difficulty == d; setNames(as.list(s$id[k]), lab[k]) })
      names(ch) <- c("Easy", "Medium", "Hard")
      ch <- ch[vapply(ch, length, 1L) > 0]
      sel <- isolate(st$pid)
      if (is.null(sel)) { all <- isolate(status()); sel <- all$id[!all$solved][1]; if (is.na(sel)) sel <- all$id[1] }
      if (!(sel %in% s$id)) sel <- character(0)
      updateSelectizeInput(session, "pid", choices = ch, selected = sel, server = FALSE)
    })

    open_problem <- function(pid) {
      if (is.null(pid) || !(pid %in% PRACTICE_IDS)) return()
      if (identical(st$pid, pid)) return()
      p <- PRACTICE[[pid]]
      st$pid <- pid
      bus$ws_problem <- pid
      st$result <- NULL; st$hints <- 0; st$reveal <- FALSE
      st$opened <- as.numeric(Sys.time()) * 1000
      code <- db_get_draft(pid) %||% p$starter
      session$sendCustomMessage("dsa-set-code", list(id = ed, code = code, token = pid))
      updateTextAreaInput(session, "custom", value = "",
        placeholder = paste0(example_lines(p, p$examples[[1]]), "\n(one JSON value per line — the examples always run as well)"))
      updateTabsetPanel(session, "ltab", "desc")
      updateTabsetPanel(session, "rtab", "test")
      if (!identical(isolate(input$pid), pid)) updateSelectizeInput(session, "pid", selected = pid)
    }

    observeEvent(input$pid, if (nzchar(input$pid %||% "")) open_problem(input$pid), ignoreInit = FALSE)
    observeEvent(bus$open_problem, {
      pid <- bus$open_problem$id
      if (!is.null(pid) && !(pid %in% filtered()$id)) {
        updateSelectInput(session, "f_company", selected = "all"); updateSelectInput(session, "f_status", selected = "all")
      }
      open_problem(pid)
    })

    step <- function(delta) {
      ids <- filtered()$id; if (!length(ids)) return()
      i <- match(st$pid, ids); i <- if (is.na(i)) 1 else ((i - 1 + delta) %% length(ids)) + 1
      open_problem(ids[i])
    }
    observeEvent(input$prev, step(-1))
    observeEvent(input$nxt, step(1))
    observeEvent(input$rand, {
      s <- status(); pool <- s$id[!s$solved & s$id != (st$pid %||% "")]
      if (input$f_company == "meta") pool <- intersect(pool, s$id[s$meta])
      if (input$f_company == "google") pool <- intersect(pool, s$id[s$google])
      if (!length(pool)) { showNotification("Every problem in this filter is solved — nice work.", type = "message"); return() }
      open_problem(sample(pool, 1))
    })

    # ── Drafts ───────────────────────────────────────────────────────────────
    code_in <- debounce(reactive(input$editor_code), 1500)
    observeEvent(code_in(), {
      x <- code_in()
      if (is.null(x$token) || !identical(x$token, st$pid)) return()
      p <- PRACTICE[[st$pid]]
      if (!identical(x$code, p$starter)) db_save_draft(st$pid, x$code)
    })
    observeEvent(input$reset, {
      showModal(modalDialog(title = "Reset to the starter code?", "Your current code for this problem will be discarded.",
        footer = tagList(modalButton("Cancel"), actionButton(ns("reset_ok"), "Reset", class = "btn btn-dsa"))))
    })
    observeEvent(input$reset_ok, {
      removeModal(); req(st$pid)
      db_delete_draft(st$pid)
      session$sendCustomMessage("dsa-set-code", list(id = ed, code = PRACTICE[[st$pid]]$starter, token = st$pid))
    })

    # ── Run / Submit ─────────────────────────────────────────────────────────
    observeEvent(input$action, {
      a <- input$action
      on.exit(session$sendCustomMessage("dsa-running", list(id = ed, on = FALSE)), add = TRUE)
      if (is.null(st$pid) || !identical(a$token, st$pid)) return()
      pid <- st$pid
      db_save_draft(pid, a$code)
      res <- run_solution(pid, a$code, a$type, custom = if (a$type == "run") input$custom %||% "" else "")
      if (!(res$verdict %in% c("Internal Error", "Python not found"))) db_add_submission(pid, a$type, res, a$code)
      st$result <- res; st$mode <- a$type
      if (identical(res$verdict, "Accepted") && a$type == "submit") st$reveal <- TRUE
      ln <- result_error_line(res)
      session$sendCustomMessage("dsa-annotate", list(id = ed, line = ln$line, text = ln$text))
      updateTabsetPanel(session, "rtab", "result")
      bus$db_tick <- bus$db_tick + 1
    })

    output$result <- renderUI(result_panel(st$result, st$mode))

    output$custom_help <- renderUI({
      req(st$pid); p <- PRACTICE[[st$pid]]
      what <- if (p$kind == "design") "two lines per test: the operations list, then the arguments list"
              else paste0(length(p$params), " line(s) per test, in this order: ", paste(vapply(p$params, function(x) paste0("<code>", x$name, "</code>"), ""), collapse = ", "))
      hint(paste0("<b>Run</b> executes the examples plus any extra tests typed here — ", what,
                  ", each as JSON (double-quoted strings, <code>null</code>, <code>true</code>/<code>false</code>). Expected output comes from a reference solution. ",
                  "<b>Submit</b> runs everything, including hidden edge cases and large inputs that catch slow algorithms."))
    })

    output$watch <- renderUI({
      req(st$opened)
      tags$span(class = "dsa-stopwatch ws-watch", `data-start` = sprintf("%.0f", st$opened), "⏱ 0:00")
    })

    # ── Left panel ───────────────────────────────────────────────────────────
    output$desc <- renderUI({
      req(st$pid); p <- PRACTICE[[st$pid]]
      s <- status(); r <- s[s$id == st$pid, ]
      state <- if (r$due) callout(sprintf("🔁 <b>Due for review.</b> You solved this before; solving it again now moves it to the next interval (%s days).",
                                          paste(REVIEW_GAPS, collapse = " → ")), "tip")
               else if (r$solved) callout(sprintf("✅ Solved. Next review: %s.", if (is.na(r$next_due)) "none — mastered" else r$next_due), "success")
      tagList(state, problem_statement(p))
    })

    output$hints <- renderUI({
      req(st$pid); h <- unlist(PRACTICE[[st$pid]]$hints)
      tagList(
        hint("Hints are ordered from a gentle nudge to nearly the whole idea. Try to stop as early as you can."),
        lapply(seq_len(min(st$hints, length(h))), function(i) callout(sprintf("<b>Hint %d.</b> %s", i, h[i]), "info")),
        if (st$hints < length(h)) actionButton(ns("more_hint"), sprintf("Show hint %d of %d", st$hints + 1, length(h)), class = "btn btn-dsa-outline btn-sm")
        else tags$p(class = "hint", "No more hints — check the Solution tab if you are stuck."))
    })
    observeEvent(input$more_hint, st$hints <- st$hints + 1)

    output$solution <- renderUI({
      req(st$pid); p <- PRACTICE[[st$pid]]
      solved <- isTRUE(status()$solved[status()$id == st$pid])
      if (!(solved || st$reveal)) {
        return(tagList(
          callout("The editorial unlocks once you get <b>Accepted</b>. Struggling productively for 20–30 minutes is the practice — but if you are stuck, reading the solution and re-solving it from scratch tomorrow is better than giving up.", "info"),
          actionButton(ns("reveal"), "Reveal the solution anyway", class = "btn btn-dsa-outline btn-sm")))
      }
      tagList(
        kpi_row(kpi(p$pattern, "pattern", COL$pri), kpi(p$complexity, "complexity", COL$ok)),
        tags$div(class = "ps-body", HTML(as.character(shiny::markdown(p$approach)))),
        dsa_code(strip_checker(p$reference), "Reference solution"),
        hint("Your own accepted code is in the Submissions tab. Compare the two: naming, edge cases, and whether yours does unnecessary work."))
    })
    observeEvent(input$reveal, {
      st$reveal <- TRUE
      db_log_event(st$pid, "view", "Viewed solution")
      bus$db_tick <- bus$db_tick + 1
    })

    subs <- reactive({ bus$db_tick; req(st$pid); s <- db_submissions(st$pid); s[s$mode %in% c("run", "submit", "interview"), ] })
    output$subs_head <- renderUI({
      s <- subs()
      if (!nrow(s)) return(hint("No runs or submissions yet for this problem."))
      sub <- s[s$mode %in% c("submit", "interview"), ]
      tagList(kpi_row(kpi(nrow(sub), "submissions", COL$pri), kpi(sum(sub$verdict == "Accepted"), "accepted", COL$ok), kpi(nrow(s) - nrow(sub), "runs", COL$acc)),
              hint("Click a row to view the code you sent."))
    })
    output$subs <- renderDT({
      s <- subs(); req(nrow(s) > 0)
      d <- data.frame(When = s$ts, Type = s$mode,
                      Verdict = sprintf("<span style='color:%s;font-weight:700;'>%s</span>", ifelse(s$verdict == "Accepted", "#059669", "#dc2626"), s$verdict),
                      Tests = ifelse(is.na(s$total), "", paste0(s$passed, " / ", s$total)),
                      `Large-test time` = ifelse(is.na(s$runtime_ms) | s$runtime_ms == 0, "", paste0(round(s$runtime_ms), " ms")), check.names = FALSE)
      datatable(d, escape = FALSE, rownames = FALSE, selection = "single", options = list(dom = "tp", pageLength = 8, ordering = FALSE))
    })
    observeEvent(input$subs_rows_selected, {
      s <- subs(); i <- input$subs_rows_selected; req(length(i) == 1)
      showModal(modalDialog(title = sprintf("%s — %s (%s)", s$ts[i], s$verdict[i], s$mode[i]), size = "l", easyClose = TRUE,
        dsa_code(db_submission_code(s$id[i]) %||% "(no code stored)"),
        footer = tagList(actionButton(ns("load_sub"), "Load into editor", class = "btn btn-dsa-outline"), modalButton("Close"))))
      st$pending <- s$id[i]
    })
    observeEvent(input$load_sub, {
      removeModal(); code <- db_submission_code(st$pending)
      if (!is.null(code)) session$sendCustomMessage("dsa-set-code", list(id = ed, code = code, token = st$pid))
    })

    output$followups <- renderUI({
      req(st$pid); f <- unlist(PRACTICE[[st$pid]]$followups)
      tagList(
        callout("Interviewers — Google's especially — often change a constraint once your first solution works. Practise answering these out loud: name the new bottleneck, the structure that fixes it, and the new complexity.", "info"),
        tags$ol(class = "fu-list", lapply(f, tags$li)))
    })
  })
}
