# modules/mod_behavioural.R — Behavioural interview practice: STAR story bank, coverage matrix,
# timed questions with self-scoring, and history.

COMPETENCIES <- c(
  "Ownership & driving results", "Conflict & disagreement", "Ambiguity", "Failure & learning",
  "Collaboration (cross-functional)", "Leadership & influence", "Feedback & growth", "Prioritisation & trade-offs",
  "Customer / user focus", "Doing the right thing")

BEHAV_Q <- local({
  q <- function(id, text, comp, co, probes) list(id = id, text = text, comp = comp, co = co, probes = probes)
  list(
    q("b01", "Tell me about a project you are most proud of. What was your specific contribution?", c("Ownership & driving results"), "Meta · Google",
      c("What would have happened without you?", "How did you measure success?", "What would you do differently?")),
    q("b02", "Describe a time you disagreed with a teammate or manager about a technical decision.", c("Conflict & disagreement"), "Meta · Google",
      c("How did you make sure you understood their view?", "What was the final decision and how did you feel about it?", "Did it change the relationship?")),
    q("b03", "Tell me about a time you had to deliver with very unclear requirements.", c("Ambiguity"), "Meta · Google",
      c("What did you do first?", "Which assumptions did you make, and how did you validate them?", "What changed later?")),
    q("b04", "Tell me about a time you failed. What did you learn?", c("Failure & learning"), "Meta · Google",
      c("When did you realise it was failing?", "What did you change in how you work afterwards?", "Has that lesson been tested since?")),
    q("b05", "Give an example of working with another team whose priorities conflicted with yours.", c("Collaboration (cross-functional)", "Conflict & disagreement"), "Meta",
      c("How did you find common ground?", "Who escalated, if anyone?", "What was the outcome for both teams?")),
    q("b06", "Tell me about a time you influenced a decision without having authority.", c("Leadership & influence"), "Google",
      c("What data or argument changed minds?", "Who opposed it and why?", "What would you do if it had not worked?")),
    q("b07", "Describe the most critical feedback you have received. What did you do with it?", c("Feedback & growth"), "Meta · Google",
      c("How did you react in the moment?", "What concrete change did you make?", "How did you check it worked?")),
    q("b08", "Tell me about a time you had too many things to do. How did you decide what to drop?", c("Prioritisation & trade-offs"), "Meta",
      c("What framework did you use?", "Who did you tell about the trade-off?", "What was the cost of what you dropped?")),
    q("b09", "Tell me about a time you went beyond the stated requirements to help users.", c("Customer / user focus"), "Google",
      c("How did you know users needed it?", "What did it cost the team?", "How was it received?")),
    q("b10", "Describe a situation where you saw something wrong — ethically, or for quality — and acted.", c("Doing the right thing"), "Google",
      c("What was the risk of speaking up?", "Who did you involve?", "What changed as a result?")),
    q("b11", "Tell me about a time you mentored or grew someone else.", c("Leadership & influence", "Feedback & growth"), "Meta · Google",
      c("How did you tailor your approach?", "How did you measure their growth?", "What did you learn about mentoring?")),
    q("b12", "Tell me about a time you made a decision with incomplete data.", c("Ambiguity", "Prioritisation & trade-offs"), "Meta · Google",
      c("What was the cost of waiting?", "How reversible was it?", "Looking back, was it right?")),
    q("b13", "Describe a time you took ownership of a problem that was not yours.", c("Ownership & driving results"), "Meta",
      c("Why did nobody else pick it up?", "How did you avoid stepping on toes?", "What was the result?")),
    q("b14", "Tell me about a time a project you led slipped its deadline.", c("Failure & learning", "Ownership & driving results"), "Meta · Google",
      c("When did you raise the alarm?", "How did you reset expectations?", "What process change followed?")),
    q("b15", "Tell me about a time you had to push back on a product or business request.", c("Conflict & disagreement", "Customer / user focus"), "Meta",
      c("What alternative did you offer?", "How did you keep the relationship healthy?", "What happened next?")),
    q("b16", "Describe a time you simplified something complicated — a system, a process or an explanation.", c("Ownership & driving results", "Collaboration (cross-functional)"), "Google",
      c("Who benefited?", "What did you remove?", "How did you measure the improvement?")),
    q("b17", "Tell me about a time you worked with someone very different from you.", c("Collaboration (cross-functional)", "Doing the right thing"), "Google",
      c("What friction came up?", "What did you adapt?", "What did you learn from them?")),
    q("b18", "Why this company and this role? What do you want to be doing in three years?", c("Feedback & growth"), "Meta · Google",
      c("What would make you leave?", "Which team would you pick first and why?")),
    q("b19", "Tell me about the hardest bug or production incident you handled.", c("Ownership & driving results", "Failure & learning"), "Meta · Google",
      c("How did you narrow it down?", "How did you communicate during the incident?", "What prevents it recurring?")),
    q("b20", "Tell me about a time you changed your mind after hearing someone else's argument.", c("Feedback & growth", "Conflict & disagreement"), "Google",
      c("What convinced you?", "How did you acknowledge it?", "Did it affect how you argue now?"))
  )
})
BEHAV_Q_IDS <- vapply(BEHAV_Q, function(q) q$id, "")
STAR_RUBRIC <- c(structure = "Structure — clear S → T → A → R, most time on Actions",
                 ownership = "Ownership — 'I' not 'we'; your decisions are visible",
                 impact    = "Impact — a concrete, ideally measured, result",
                 depth     = "Depth — trade-offs, obstacles and why you chose what you did",
                 reflect   = "Reflection — what you learned or would do differently",
                 concise   = "Concise — about 2–3 minutes spoken, no tangents")

behavioural_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🗣️", "Behavioural Interviews",
      "Meta's behavioural round and Google's 'Googleyness & Leadership' interview probe the same signals: ownership, conflict, ambiguity, growth and impact. Build a bank of 6–10 strong STAR stories, check they cover every competency, then practise answering against the clock.",
      c("STAR story bank", "Coverage matrix", "Timed practice", "Follow-up probes", "Self-scoring", "Export")),
    tags$div(class = "topic-tabs",
      tabsetPanel(id = ns("tabs"), type = "pills",
        tabPanel("📚 Story bank",
          fluidRow(
            box(title = "Write or edit a story (STAR)", status = "primary", solidHeader = TRUE, width = 7,
              fluidRow(column(8, textInput(ns("s_title"), "Short title", "", width = "100%", placeholder = "e.g. Cut checkout latency by 40%")),
                       column(4, sliderInput(ns("s_strength"), "How strong is it? (1–5)", 1, 5, 3, step = 1, width = "100%"))),
              selectizeInput(ns("s_comp"), "Competencies it demonstrates", COMPETENCIES, multiple = TRUE, width = "100%"),
              textAreaInput(ns("s_sit"), "S — Situation (1–2 sentences of context)", "", rows = 2, width = "100%"),
              textAreaInput(ns("s_task"), "T — Task (your goal / responsibility)", "", rows = 2, width = "100%"),
              textAreaInput(ns("s_act"), "A — Actions (what YOU did — the longest part)", "", rows = 5, width = "100%"),
              textAreaInput(ns("s_res"), "R — Result (numbers if you can)", "", rows = 2, width = "100%"),
              fluidRow(column(6, textAreaInput(ns("s_learn"), "Learning / what you'd do differently", "", rows = 2, width = "100%")),
                       column(6, textInput(ns("s_metrics"), "Key metrics (comma separated)", "", width = "100%", placeholder = "−40% p95 latency, +3% conversion"))),
              uiOutput(ns("s_meter")),
              tags$div(style = "display:flex; gap:6px;",
                actionButton(ns("s_save"), "💾 Save story", class = "btn btn-dsa"),
                actionButton(ns("s_new"), "New story", class = "btn btn-dsa-outline"),
                actionButton(ns("s_del"), "Delete", class = "btn btn-dsa-outline")),
              uiOutput(ns("s_editing"))),
            box(title = "Your stories", status = "info", solidHeader = TRUE, width = 5,
              hint("Click a row to load it for editing."),
              DT::DTOutput(ns("s_table")),
              tags$div(style = "margin-top:8px; display:flex; gap:6px;",
                downloadButton(ns("s_export_md"), "Export (Markdown)", class = "btn btn-dsa-outline btn-sm"),
                downloadButton(ns("s_export_csv"), "Export (CSV)", class = "btn btn-dsa-outline btn-sm")),
              tags$hr(),
              callout("<b>Good stories</b> are recent (last 2–3 years), at your target level, and have a twist — a conflict, a mistake, a hard trade-off. One story can cover several competencies, but you need at least two for the big ones (conflict, failure, ownership).", "tip"))
          )
        ),
        tabPanel("🧭 Coverage",
          fluidRow(
            box(title = "Which competencies do your stories cover?", status = "primary", solidHeader = TRUE, width = 8,
                plotlyOutput(ns("cov_plot"), height = "420px")),
            box(title = "Gaps and suggestions", status = "info", solidHeader = TRUE, width = 4, uiOutput(ns("cov_gaps"))))
        ),
        tabPanel("⏱ Practise",
          fluidRow(
            box(title = "Question", status = "primary", solidHeader = TRUE, width = 7,
              fluidRow(column(6, selectInput(ns("p_comp"), "Competency", c("Any" = "any", setNames(COMPETENCIES, COMPETENCIES)))),
                       column(3, numericInput(ns("p_min"), "Minutes", 3, min = 1, max = 10)),
                       column(3, tags$div(style = "margin-top:25px;", actionButton(ns("p_draw"), "🎲 New question", class = "btn btn-dsa btn-sm")))),
              uiOutput(ns("p_question")),
              uiOutput(ns("p_story_pick")),
              textAreaInput(ns("p_answer"), "Your answer (type it as you would say it — or jot bullet points and speak aloud)", "", rows = 9, width = "100%"),
              uiOutput(ns("p_meter")),
              uiOutput(ns("p_probes"))),
            box(title = "Score yourself", status = "warning", solidHeader = TRUE, width = 5,
              lapply(names(STAR_RUBRIC), function(k) sliderInput(ns(paste0("r_", k)), STAR_RUBRIC[[k]], 1, 4, 2, step = 1, width = "100%", ticks = FALSE)),
              hint("1 = missing · 2 = weak · 3 = solid · 4 = excellent. Interviewers mostly downgrade for vague 'we' answers and missing results."),
              actionButton(ns("p_save"), "Save this attempt", class = "btn btn-dsa"),
              uiOutput(ns("p_saved")))
          )
        ),
        tabPanel("📈 History",
          fluidRow(
            box(title = "Scores over time", status = "primary", solidHeader = TRUE, width = 7, plotlyOutput(ns("h_plot"), height = "320px")),
            box(title = "Weakest rubric areas", status = "info", solidHeader = TRUE, width = 5, plotlyOutput(ns("h_rub"), height = "320px"))),
          fluidRow(box(title = "Attempts", status = "info", solidHeader = TRUE, width = 12, DT::DTOutput(ns("h_table"))))
        ),
        tabPanel("💡 Guide",
          insight_cards(
            when = c("Meta: a dedicated behavioural round (often 45 min) — conflict, ambiguity, growth, impact, plus 'why Meta'.",
                     "Google: 'Googleyness & Leadership' — collaboration, navigating ambiguity, bias to action, valuing feedback, inclusion.",
                     "Every round: the first 5 minutes ('tell me about yourself') and the last 5 ('questions for me?')."),
            pitfalls = c("'We decided…' — the interviewer cannot see your contribution.",
                         "Spending 2 minutes on context and 30 seconds on what you did.",
                         "A failure story where the failure was really someone else's.",
                         "No numbers in the result, or no result at all."),
            tips = c("Aim for ~2–3 minutes per story, then let them dig in with follow-ups.",
                     "Prepare the follow-ups: 'what would you do differently?', 'how did the other person react?'.",
                     "Reuse stories, but re-angle them to the competency being asked about.")),
          fluidRow(
            box(title = "The STAR shape", status = "info", solidHeader = TRUE, width = 6,
              cplx_table(data.frame(Part = c("Situation", "Task", "Action", "Result", "+ Learning"),
                                    Share = c("~10%", "~10%", "~60%", "~15%", "~5%"),
                                    Contains = c("Team, product, stakes — only what is needed", "Your goal and why it was hard",
                                                 "Your decisions, alternatives considered, how you persuaded or unblocked others", "Measured outcome, for users and the business", "What you changed afterwards"),
                                    stringsAsFactors = FALSE))),
            box(title = "Signals interviewers write down", status = "info", solidHeader = TRUE, width = 6,
              cplx_table(data.frame(Signal = c("Scope", "Ownership", "Conflict handling", "Growth", "Communication"),
                                    Strong = c("Impact beyond your own tasks", "Acted without being asked; owned the outcome", "Understood the other side; disagree-and-commit", "Sought feedback; concrete change afterwards", "Crisp, structured, adapts to questions"),
                                    Weak = c("Only assigned tickets", "'The team did…'", "Escalated immediately or 'won'", "'I have no weaknesses'", "Rambling, no structure"),
                                    stringsAsFactors = FALSE))))
        )
      )
    )
  )
}

behavioural_server <- function(id, progress = NULL, bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    st <- reactiveValues(edit = NULL, tick = 0, q = NULL, started = NULL, saved = NULL)

    stories <- reactive({ st$tick; db_table("star_stories", "updated DESC") })
    words <- function(x) length(strsplit(trimws(x %||% ""), "\\s+")[[1]][nzchar(strsplit(trimws(x %||% ""), "\\s+")[[1]])])

    # ── Story bank ───────────────────────────────────────────────────────────
    fill_form <- function(r) {
      updateTextInput(session, "s_title", value = r$title %||% ""); updateSliderInput(session, "s_strength", value = r$strength %||% 3)
      updateSelectizeInput(session, "s_comp", selected = if (is.null(r$competencies) || is.na(r$competencies)) character(0) else strsplit(r$competencies, " \\| ")[[1]])
      updateTextAreaInput(session, "s_sit", value = r$situation %||% ""); updateTextAreaInput(session, "s_task", value = r$task %||% "")
      updateTextAreaInput(session, "s_act", value = r$action %||% ""); updateTextAreaInput(session, "s_res", value = r$result %||% "")
      updateTextAreaInput(session, "s_learn", value = r$learning %||% ""); updateTextInput(session, "s_metrics", value = r$metrics %||% "")
    }
    observeEvent(input$s_new, { st$edit <- NULL; fill_form(list()) })
    observeEvent(input$s_save, {
      if (!nzchar(trimws(input$s_title))) { showNotification("Give the story a short title first.", type = "warning"); return() }
      row <- list(title = input$s_title, competencies = paste(input$s_comp, collapse = " | "), situation = input$s_sit, task = input$s_task,
                  action = input$s_act, result = input$s_res, learning = input$s_learn, metrics = input$s_metrics, strength = as.integer(input$s_strength))
      st$edit <- db_story_save(row, st$edit); st$tick <- st$tick + 1; if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1
      showNotification("Story saved.", type = "message", duration = 2)
    })
    observeEvent(input$s_del, {
      if (is.null(st$edit)) return()
      db_story_delete(st$edit); st$edit <- NULL; fill_form(list()); st$tick <- st$tick + 1
    })
    output$s_editing <- renderUI(if (!is.null(st$edit)) hint(sprintf("Editing story #%s — saving updates it.", st$edit)) else hint("New story — saving creates it."))
    output$s_meter <- renderUI({
      w <- c(S = words(input$s_sit), T = words(input$s_task), A = words(input$s_act), R = words(input$s_res), L = words(input$s_learn))
      tot <- sum(w); if (!tot) return(NULL)
      we <- lengths(regmatches(tolower(input$s_act %||% ""), gregexpr("\\bwe\\b", tolower(input$s_act %||% ""))))
      i_ <- lengths(regmatches(tolower(input$s_act %||% ""), gregexpr("\\bi\\b", tolower(input$s_act %||% ""))))
      has_num <- grepl("[0-9]", paste(input$s_res, input$s_metrics))
      tagList(
        tags$div(style = "display:flex; height:14px; border-radius:7px; overflow:hidden; margin:4px 0 6px;",
          lapply(names(w), function(k) if (w[[k]] > 0) tags$div(title = paste(k, w[[k]], "words"),
            style = sprintf("width:%.1f%%; background:%s;", 100 * w[[k]] / tot, c(S = COL$idle, T = COL$mute, A = COL$pri, R = COL$ok, L = COL$sec)[[k]])))),
        tags$div(class = "hint", sprintf("%d words ≈ %.1f min spoken · Actions %.0f%% (aim ≥ 50%%) · 'I' %d vs 'we' %d · %s",
                                         tot, tot / 140, 100 * w[["A"]] / tot, i_, we, if (has_num) "result has numbers ✓" else "no numbers in the result yet")))
    })
    output$s_table <- DT::renderDT({
      s <- stories()
      if (!nrow(s)) return(DT::datatable(data.frame(Message = "No stories yet — write your first one on the left."), rownames = FALSE, options = list(dom = "t")))
      DT::datatable(data.frame(Title = s$title, Competencies = gsub(" \\| ", ", ", s$competencies), Strength = strrep("★", s$strength), stringsAsFactors = FALSE),
                    rownames = FALSE, selection = "single", options = list(dom = "tp", pageLength = 8))
    })
    observeEvent(input$s_table_rows_selected, {
      s <- stories(); i <- input$s_table_rows_selected; if (!length(i) || i > nrow(s)) return()
      st$edit <- s$id[i]; fill_form(as.list(s[i, ]))
    })
    md_export <- function() {
      s <- stories()
      paste(c("# STAR story bank", sprintf("_Exported %s_", now_ts()), "",
              unlist(lapply(seq_len(nrow(s)), function(i) c(sprintf("## %s  (%s)", s$title[i], strrep("★", s$strength[i])),
                sprintf("*Competencies:* %s", gsub(" \\| ", ", ", s$competencies[i])), "",
                sprintf("**Situation.** %s", s$situation[i]), "", sprintf("**Task.** %s", s$task[i]), "", sprintf("**Action.** %s", s$action[i]), "",
                sprintf("**Result.** %s", s$result[i]), "", sprintf("**Learning.** %s", s$learning[i]), "", sprintf("*Metrics:* %s", s$metrics[i]), "")))), collapse = "\n")
    }
    output$s_export_md <- downloadHandler(filename = function() sprintf("star-stories-%s.md", Sys.Date()), content = function(f) writeLines(md_export(), f, useBytes = TRUE))
    output$s_export_csv <- downloadHandler(filename = function() sprintf("star-stories-%s.csv", Sys.Date()), content = function(f) utils::write.csv(stories(), f, row.names = FALSE))

    # ── Coverage ─────────────────────────────────────────────────────────────
    cov <- reactive({
      s <- stories()
      m <- matrix(0, max(1, nrow(s)), length(COMPETENCIES), dimnames = list(if (nrow(s)) s$title else "(no stories yet)", COMPETENCIES))
      for (i in seq_len(nrow(s))) { cs <- strsplit(s$competencies[i] %||% "", " \\| ")[[1]]; m[i, COMPETENCIES %in% cs] <- s$strength[i] }
      m
    })
    output$cov_plot <- renderPlotly({
      m <- cov()
      plot_ly(x = colnames(m), y = rownames(m), z = m, type = "heatmap", height = 420, xgap = 3, ygap = 3,
              colorscale = list(c(0, "#f1f5f9"), c(0.2, "#e0e7ff"), c(1, COL$pri)), zmin = 0, zmax = 5,
              hovertemplate = "%{y}<br>%{x}<br>strength %{z}<extra></extra>", showscale = FALSE) %>%
        dsa_layout() %>% layout(xaxis = list(tickangle = -35, title = ""), yaxis = list(title = "", autorange = "reversed"), margin = list(b = 140, l = 180))
    })
    output$cov_gaps <- renderUI({
      m <- cov(); s <- stories()
      n <- colSums(m > 0); strong <- colSums(m >= 4)
      gaps <- names(n)[n == 0]; thin <- names(n)[n == 1]
      qs <- function(c) { m <- Filter(function(q) c %in% q$comp, BEHAV_Q); if (length(m)) m[[1]]$text else "" }
      tagList(
        kpi_row(kpi(nrow(s), "stories"), kpi(sum(n > 0), sprintf("of %d competencies covered", length(COMPETENCIES)), if (all(n > 0)) COL$ok else COL$warn),
                kpi(sum(strong > 0), "with a ★★★★ story", COL$sec)),
        if (length(gaps)) callout(paste0("<b>No story yet for:</b><br>", paste(sprintf("• %s — e.g. <i>%s</i>", gaps, vapply(gaps, qs, "")), collapse = "<br>")), "warn"),
        if (length(thin)) callout(paste0("<b>Only one story for:</b> ", paste(thin, collapse = ", "), ". Interviewers often ask two questions on the same theme; have a backup."), "info"),
        if (!length(gaps) && !length(thin) && nrow(s)) callout("Every competency has at least two stories. Now practise telling them under time pressure.", "success"))
    })

    # ── Practice ─────────────────────────────────────────────────────────────
    draw <- function() {
      pool <- if (input$p_comp == "any") BEHAV_Q else Filter(function(q) input$p_comp %in% q$comp, BEHAV_Q)
      st$q <- pool[[sample.int(length(pool), 1)]]; st$started <- Sys.time(); st$saved <- NULL
      updateTextAreaInput(session, "p_answer", value = "")
    }
    observeEvent(input$p_draw, draw())
    output$p_question <- renderUI({
      q <- st$q
      if (is.null(q)) return(hint("Press <b>New question</b>. The timer starts immediately — take ~20 seconds to pick a story, then answer."))
      end <- as.numeric(st$started) * 1000 + (input$p_min %||% 3) * 60000
      tagList(
        tags$div(style = "display:flex; align-items:center; gap:12px;",
          tags$div(style = "flex:1; font-size:17px; font-weight:600; color:#1e293b;", q$text),
          tags$div(class = "dsa-countdown", style = "font-size:22px;", `data-end` = sprintf("%.0f", end), `data-total` = (input$p_min %||% 3) * 60, "--:--")),
        tags$div(style = "margin:6px 0;", lapply(q$comp, function(c) tags$span(class = "kind-pill", style = "margin-right:4px;", c)),
                 tags$span(class = "hint", style = "margin-left:6px;", paste("Asked at:", q$co))))
    })
    output$p_story_pick <- renderUI({
      s <- stories(); q <- st$q; if (is.null(q)) return(NULL)
      if (!nrow(s)) return(hint("Tip: write stories in the Story bank first; they will be suggested here."))
      score <- vapply(seq_len(nrow(s)), function(i) sum(q$comp %in% strsplit(s$competencies[i] %||% "", " \\| ")[[1]]) * 10 + s$strength[i], 0)
      o <- order(-score)
      selectInput(ns("p_story"), "Story you are using", c("(none)" = "", setNames(s$id[o], sprintf("%s%s", s$title[o], ifelse(score[o] >= 10, "  ✓ matches", "")))), width = "100%")
    })
    output$p_meter <- renderUI({
      a <- input$p_answer %||% ""; w <- words(a); if (!w) return(NULL)
      we <- lengths(regmatches(tolower(a), gregexpr("\\bwe\\b", tolower(a)))); i_ <- lengths(regmatches(tolower(a), gregexpr("\\bi\\b", tolower(a))))
      hint(sprintf("%d words ≈ %.1f min spoken · 'I' %d vs 'we' %d %s · %s", w, w / 140, i_, we, if (we > i_) "⚠ make your role explicit" else "",
                   if (grepl("[0-9]", a)) "numbers ✓" else "add a measurable result"))
    })
    output$p_probes <- renderUI({
      q <- st$q; if (is.null(q)) return(NULL)
      tags$details(tags$summary("Likely follow-up questions (open after answering)"), tags$ul(lapply(q$probes, tags$li)))
    })
    observeEvent(input$p_save, {
      q <- st$q; if (is.null(q)) { showNotification("Draw a question first.", type = "warning"); return() }
      sc <- vapply(names(STAR_RUBRIC), function(k) as.numeric(input[[paste0("r_", k)]]), 0)
      secs <- as.numeric(difftime(Sys.time(), st$started, units = "secs"))
      db_insert("behav_attempts", list(ts = now_ts(), day = today(), question_id = q$id, question = q$text, competency = paste(q$comp, collapse = " | "),
        story_id = suppressWarnings(as.integer(input$p_story)), seconds = secs, answer = input$p_answer,
        scores = as.character(jsonlite::toJSON(as.list(sc), auto_unbox = TRUE)), total = round(100 * sum(sc) / (4 * length(sc)))))
      st$saved <- round(100 * sum(sc) / (4 * length(sc))); st$tick <- st$tick + 1; if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1
    })
    output$p_saved <- renderUI(if (!is.null(st$saved)) callout(sprintf("Saved — score %d%%. Draw another question or review History.", st$saved), "success"))

    # ── History ──────────────────────────────────────────────────────────────
    hist_df <- reactive({ st$tick; db_table("behav_attempts", "id ASC") })
    output$h_plot <- renderPlotly({
      h <- hist_df()
      if (!nrow(h)) return(plotly_empty(height = 320) %>% layout(title = list(text = "No attempts yet", font = list(size = 13))))
      plot_ly(x = seq_len(nrow(h)), y = h$total, type = "scatter", mode = "lines+markers", height = 320, line = list(color = COL$pri),
              text = h$question, hoverinfo = "text+y") %>% dsa_layout(xt = "attempt", yt = "score %") %>% layout(yaxis = list(range = c(0, 100)))
    })
    output$h_rub <- renderPlotly({
      h <- hist_df()
      if (!nrow(h)) return(plotly_empty(height = 320))
      sc <- do.call(rbind, lapply(h$scores, function(x) unlist(jsonlite::fromJSON(x))))
      m <- colMeans(sc[, names(STAR_RUBRIC), drop = FALSE])
      plot_ly(x = m, y = names(m), type = "bar", orientation = "h", height = 320, marker = list(color = ifelse(m == min(m), COL$err, COL$sec))) %>%
        dsa_layout(xt = "average (1–4)") %>% layout(xaxis = list(range = c(0, 4)), yaxis = list(categoryorder = "total ascending"))
    })
    output$h_table <- DT::renderDT({
      h <- hist_df()
      if (!nrow(h)) return(DT::datatable(data.frame(Message = "No attempts yet."), rownames = FALSE, options = list(dom = "t")))
      h <- h[order(-h$id), ]
      DT::datatable(data.frame(When = h$ts, Question = h$question, Score = paste0(h$total, "%"), Minutes = round(h$seconds / 60, 1),
                               Answer = substr(h$answer %||% "", 1, 160), stringsAsFactors = FALSE), rownames = FALSE, options = list(pageLength = 8, dom = "tp"))
    })
  })
}
